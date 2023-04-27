# SAML. Deployment automatically secured with SAML and automatic registration of SAML client on Openshift

In this example we are provisioning a WildFly server and deploying an application secured with SAML.
The SAML authentication provider is implemented with an RH-SSO/Keycloak server;

The following features of the WildFly s2i process, are used to make the setup easier:

* Automatic SAML client registration: in this example, the SAML configuration is automatically generated and the SAML client automatically registered to the RH-SSO/Keycloak server.
* Routes discovery: when registering the SAML client, the URL of the SAML client is required; this is basically the ULR
of the application secured with SAML which is deployed on WildFly;

# WildFly Maven plugin configuration
High level view of the WildFly Maven plugin configuration

## Galleon feature-packs

* `org.wildfly:wildfly-galleon-pack`
* `org.wildfly.cloud:wildfly-cloud-galleon-pack`
* `org.wildfly.keycloak:keycloak-saml-galleon-pack`

## Galleon layers

* `cloud-server`
* `keycloak-saml`

## CLI scripts
WildFly CLI scripts executed at packaging time

* None

## Extra content
Extra content packaged inside the provisioned server

* None

# Openshift build and deployment
Technologies required to build and deploy this example

* Helm chart for WildFly `wildfly/wildfly`. Minimal version `2.0.0`.

# WildFly image API
Environment variables from the [WildFly image API](https://github.com/wildfly/wildfly-cekit-modules/blob/main/jboss/container/wildfly/run/api/module.yaml) that must be set in the OpenShift deployment environment

* None

# WildFly cloud feature-pack API
Environment variables defined by the cloud feature-pack used to configure the server:

* SSO_REALM: Keycloak realm name.
* SSO_USERNAME=User name used to create and register the SAML client in the keycloak server.
* SSO_PASSWORD=User password used to create and register the SAML client in the keycloak server.
* SSO_SAML_CERTIFICATE_NAME=Alias of the private key in the SAML client keystore.
* SSO_SAML_KEYSTORE=Client keystore file name.
* SSO_SAML_KEYSTORE_PASSWORD=Client keystore password.
* SSO_SAML_KEYSTORE_DIR=Directory in which the keystore is mounted.
* SSO_SAML_LOGOUT_PAGE=URL context where to redirect when logout occurs. 
* SSO_DISABLE_SSL_CERTIFICATE_VALIDATION=Disable keycloak server certificate check. Needed when the keycloak server generates a self signed certuficate.
* SSO_HOSTNAME_HTTPS=Route to the deployed application.
* SSO_URL=URL of the keycloak server.

# Pre-requisites

* You are logged into an OpenShift cluster and have `oc` command in your path

* You have installed Helm. Please refer to [Installing Helm page](https://helm.sh/docs/intro/install/) to install Helm in your environment

* You have installed the repository for the Helm charts for WildFly

* You have chosen and created an OpenShift namespace where to install RH-SSO/Keycloak server and WildFly

 ```bash
helm repo add wildfly https://docs.wildfly.org/wildfly-charts/
```
----
**NOTE**

If you have already installed the Helm Charts for WildFly, make sure to update your repository to the latest version.

```bash
helm repo update
```
----

# Example steps

1. Deploy an SSO server. Use the Sandbox Developer Catalog, search for sso and instantiate RH SSO 7.6 template. You can keep the default values 
when instantiating the template. Set the admin user name `admin` and password `admin`.

2. Create the SSO realm, users, role and export keystore.

  * Log into the SSO admin console (`https://<SSO route>/auth/`). Use `admin` and `admin` to log-in. 
  * Create a Realm named `WildFly`
  * Create a Role named `user`
  * Create a User named `demo`, password `demo`, make the password not temporary.
  * Assign the role `user` to the user `demo`. This user will be used to log in the application.
  * Create a User named `client-admin`, password `client-admin`, make the password not temporary. This user will be used to create 
    the SAML client in the keycloak server. It requires more privileges to interact with the keycloak server and to be able to create the client.
  * In the `Client Roles` Select the Client `realm-management`, assign the role `create-client`, `manage-clients` and `manage-realm`. For latest keycloak console, select the `user` role, Click Action/Add associated roles. Then `Filter by clients`. 
  * Create a temporary SAML client named `tmp-client` to generate the client keystore containing the client private key.
  * Once created, click on `Keys` tab, then `Export` button. Set the Key Alias to be `saml-app`, set the `Key password` and `Store password` 
    to be `password`.
  * Delete the `tmp-client`.   
  * As an alternative to using the temporary SAML client `tmp-client` to create the keystore, you can generate it with manually
    the following commands:

    ```bash
    # Private Key and Self signed certificate
    keytool -genkeypair -alias saml-app \
    -storetype PKCS12 \
    -keyalg RSA -keysize 2048 \
    -keystore keystore.p12 -storepass password \
    -dname "CN=saml-basic-auth,OU=EAP SAML Client,O=Red Hat EAP,L=MB,S=Milan,C=IT" \
    -ext ku:c=dig,keyEncipherment \
    -validity 365
    # Import the PKCS12 file into a new java keystore
    keytool -importkeystore \
    -deststorepass password -destkeystore keystore.jks \
    -srckeystore keystore.p12 -srcstoretype PKCS12 -srcstorepass password
    ```

3. As an alternative to points [1] and [2], you can perform the RH-SSO server setup using an Operator; instead of RH-SSO,
you can use Keycloak which is the community version of RH-SSO; choose the one that better suits your needs and then 
follow the instructions in one of the following:

   - [HOW-TO setup RH-SSO using the RH-SSO Operator](RH-SSO.md)
   - [HOW-TO setup Keycloak using the Keycloak Operator](KEYCLOAK.md)

4. Create a secret that contains the saml configuration; this secret is referenced in the HELM configuration file and 
provides the environment variables used when deploying WildFly:

```bash
oc apply -f saml-secret.yaml
```

5. Create a secret for the keystore; this secret is referenced in the HELM configuration file and is mounted inside the 
WildFly POD:

```
oc create secret saml-app-secret <path to the downloaded/"manually created" keystore.jks file>
```

6. Edit the `saml-secret.yaml` to add the env variable to configure the Keycloak server URL.

```yaml
stringData:
  ...
  SSO_URL: https://<host of the keycloak server>/auth
```

The  value of `SSO_URL` corresponds to the output of

```bash
echo https://$(oc get route sso --template='{{ .spec.host }}')/auth
```

7. Deploy the example application using WildFly Helm charts

```bash
helm install saml-app -f helm.yaml wildfly/wildfly
```

8. Edit the `saml-secret.yaml` to add the env variable to configure the secured application route.

```yaml
stringData:
  ...
  SSO_HOSTNAME_HTTPS: <saml-app application route>/saml-app
```

The value of `SSO_HOSTNAME_HTTPS` corresponds to the output of

```
echo $(oc get route saml-app --template='{{ .spec.host }}/saml-app')
```

Then update the secret with `oc apply -f saml-secret.yaml`.

Let's redeploy the application to make sure it uses the new environment variables:

```
oc rollout restart deploy saml-app
```

As an alternative you can use the "Routes discovery" feature offered by the WildFly s2i process, and you don't need to 
add the `SSO_HOSTNAME_HTTPS` env variable to `saml-secret.yaml`;
If you use "Routes discovery", the WildFly POD needs permissions to list routes; you add these permissions to the 
service account used when deploying the WildFly POD:

```bash
oc create role routeview --verb=list --resource=route -n $NAMESPACE
oc policy add-role-to-user routeview system:serviceaccount:$NAMESPACE:default --role-namespace=$NAMESPACE -n $NAMESPACE
```

9. Access the application: `https://<saml-app route>/saml-app`

10. Access the secured servlet.

11. Log-in using the `demo` user, `demo` password (that you created in the initial steps)

12. You should see a page containing the Principal ID

13. You can click on `logout` to log the user out.

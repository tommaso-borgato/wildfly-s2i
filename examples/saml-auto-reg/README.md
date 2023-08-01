# SAML. Deployment automatically secured with SAML and automatic registration of SAML client on Openshift

In this example we are provisioning a WildFly server and deploying an application secured 
with SAML .

In this example, the SAML configuration is automatically generated and the SAML client automatically registered to the server.

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

 ```
helm repo add wildfly https://docs.wildfly.org/wildfly-charts/
```
----
**NOTE**

If you have already installed the Helm Charts for WildFly, make sure to update your repository to the latest version.

```
helm repo update
```
----

# Example steps

1. Deploy an SSO server. Use the Sandbox Developer Catalog, search for sso and instantiate RH SSO 7.6 template. You can keep the default values 
when instantiating the template. Set the admin user name `admin` and password `admin`.

1. Create the SSO realm, users, role and export keystore.

  * Log into the SSO admin console (`https://<SSO route>/auth/`). Use `admin` and `admin` to log-in. 
  * Create a Realm named `WildFly`
  * Create a Role named `user`
  * Create a User named `demo`, password `demo`, make the password not temporary.
  * Assign the role `user` to the user `demo`. This user will be used to log in the application.
  * Create a User named `client-admin`, password `client-admin`, make the password not temporary. This user will be used to create 
    the SAML client in the keycloak server. It requires more proviledges to interact with the keycloak server and to be able to create the client.
  * In the `Client Roles` Select the Client `realm-management`, assign the role `create-client`, `manage-clients` and `manage-realm`. For latest keycloak console, select the `user` role, Click Action/Add associated roles. Then `Filter by clients`. 
  * Create a temporary SAML client named `tmp-client` to generate the client keystore containing the client private key.
  * Once created, click on `Keys` tab, then `Export` button. Set the Key Alias to be `saml-app`, set the `Key password` and `Store password` 
    to be `password`.
  * Delete the `tmp-client`.

2. Create a secret that contains the saml configuration

```
oc apply -f saml-secret.yaml
```

3. Create a secret for the keystore.

```
oc create secret generic saml-app-secret --from-file=keystore.jks=./keystore.jks --type=opaque
```

4. Deploy the example application using WildFly Helm charts

```
helm install saml-app -f helm.yaml wildfly/wildfly
```

5. Edit the `saml-secret.yaml` to add the env variables to configure the Keycloak server URL and application route.

```yaml
stringData:
  ...
  SSO_HOSTNAME_HTTPS: https://saml-app-saml-test.apps.operator3-c11f.eapqe.psi.redhat.com/saml-app
  SSO_URL: https://keycloak-saml-test.apps.operator3-c11f.eapqe.psi.redhat.com/auth
```

The value of `SSO_HOSTNAME_HTTPS` corresponds to the output of

```
echo $(oc get route saml-app --template='{{ .spec.host }}/saml-app')
```

The  value of `SSO_URL` corresponds to the output of

```
echo https://$(oc get route keycloak --template='{{ .spec.host }}')/auth
```

Got 
```log
WARN HOSTNAME_HTTP and HOSTNAME_HTTPS are not set, trying to discover secure route by querying internal APIs[0m
```
solved using "Route Discovery":
```shell
oc create role routeview --verb=list --resource=route
oc policy add-role-to-user routeview system:serviceaccount:saml-test:default --role-namespace=saml-test -n saml-test
```

Got
```log
WARN ERROR: SSO_SECRET not set. Make sure to generate a secret in the SSO/Keycloak client 'saml-app' configuration and then set the SSO_SECRET variable.
WARN ERROR: Unable to register saml client for module saml-app in realm WildFly on "https://saml-app-saml-test.apps.operator3-c11f.eapqe.psi.redhat.com/saml-app/*","https://saml-app-saml-test.apps.operator3-c11f.eapqe.psi.redhat.com:443/saml-app/*": {"errorMessage":"Client saml-app already exists"}
```
But that's OK, client already exists;


Then update the secret with `oc apply -f saml-secret.yaml`.

Let's redeploy the application to make sure it uses the new environment variables:

```
oc rollout restart deploy saml-app
```

6. Access the application: `https://<saml-app route>/saml-app`

7. Access the secured servlet.

8. Log-in using the `demo` user, `demo` password (that you created in the initial steps)

9. You should see a page containing the Principal ID

10. You can click on `logout` to log the user out.


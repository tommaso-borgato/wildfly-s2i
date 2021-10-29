WARNING Dockerfile MUST BE REMOVED.
WARNING helm.yaml must be updated to use S2I instead of public image (done for binary build).

# Automatic client registration for OpenID Connect (OIDC) secured deployment example

In this example we are provisioning a WildFly server and deploying an application secured 
with OIDC (OpenID Connect).

In this example the elytron-oidc-client subsystem configuration is automatically generated from a set of env variables. 
The keycloak client is also automatically registered inside the keycloak server.

# WildFly Maven plugin configuration
High level view of the WildFly Maven plugin configuration

## Galleon feature-packs

* `org.wildfly:wildfly-galleon-pack`
* `org.wildfly.cloud:wildfly-cloud-galleon-pack`

## Galleon layers

* `cloud-server`
* `elytron-oidc-client`

## CLI scripts
WildFly CLI scripts executed at packaging time

* None

## Extra content
Extra content packaged inside the provisioned server

* None

# Openshift build and deployment
Technologies required to build and deploy this example

* WildFly Helm charts `wildfly_v2/wildfly`

# WildFly image API
Environment variables from the [WildFly image API](https://github.com/wildfly/wildfly-cekit-modules/blob/v2/jboss/container/wildfly/run/api/module.yaml) that must be set in the OpenShift deployment environment

* None

# WildFly cloud feature-pack API
Environment variables defined by the cloud feature-pack used to configure the server

* `HOSTNAME_HTTP`. The deployed application hostname. Used to automatically compute redirect URL.
* `OIDC_DISABLE_SSL_CERTIFICATE_VALIDATION`. Keycloak server generates a self signed certificate that we are not validating. 
* `OIDC_PROVIDER_NAME`. The name of the provider, `keycloak` in this example.
* `OIDC_PROVIDER_URL`. URL To the OIDC provider. For keycloak this is the URL to the realm.
* `OIDC_SECURE_DEPLOYMENT_SECRET`. A secret used by the keycloak server to authenticate the client.
* `OIDC_USER_NAME`. Admin keycloak user name allowing to register client to the keycloak server.
* `OIDC_USER_PASSWORD`. Admin keycloak user password.

# Pre-requisites

* You are logged into an OpenShift cluster and have `oc` command in your path

* You have installed Helm. Please refer to [Installing Helm page](https://helm.sh/docs/intro/install/) to install Helm in your environment

* You have installed WildFly Helm charts for WildFly s2i V2

 ```
helm repo add wildfly_v2 https://jmesnil.github.io/wildfly-charts/
```

# Example steps

1. Deploy a keycloak server. The Keycloak [Openshift documentation](https://www.keycloak.org/getting-started/getting-started-openshift) contains
the steps required to deploy a Keycloak server inside Openshift. The following command is all what you need to call:

```
oc process -f https://raw.githubusercontent.com/keycloak/keycloak-quickstarts/latest/openshift-examples/keycloak.yaml \
    -p KEYCLOAK_USER=admin \
    -p KEYCLOAK_PASSWORD=admin \
    -p NAMESPACE=keycloak \
| oc create -f -
```

2. Create the `Users` role

  * Log into the keycloak admin console (`https://<keycloak host>/auth/`)
  * Create a Role named `Users`
  * Assigne the role `Users` to the user `admin`

3. Deploy the example application using WildFly Helm charts

```
helm install oidc-app -f helm.yaml wildfly_v2/wildfly
```

4. Finally add the env variable to the `oidc-app` deployment to convey the Keycloak URL and application hostname

`oc set env deployment/oidc-app OIDC_PROVIDER_URL="https://<keycloak server hostname>/auth/realms/master" HOSTNAME_HTTP="<oidc-app hostname>" `

Then do an upgrade of the Helm charts to reflect your changes done to the deployment

`helm upgrade oidc-app wildfly_v2/wildfly`

5. Access the application: `https://<oidc-app host>/simple-webapp`

6. Access the secured servlet.

7. Log-in using the `admin` user, `admin` password

8. You should see a page containing the Principal ID


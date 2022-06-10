# Elytron OpenID Connect (OIDC) client with automatic registration example on kubernetes

In this example we are provisioning a WildFly server and deploying an application secured 
with OIDC (OpenID Connect).

In this example, the OIDC configuration is automatically generated and Realm client added to the server.

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

# Kubernetes build and deployment
Technologies required to build and deploy this example

* kubectl, minikube

# WildFly image API
Environment variables from the [WildFly image API](https://github.com/wildfly/wildfly-cekit-modules/blob/main/jboss/container/wildfly/run/api/module.yaml) that must be set in the OpenShift deployment environment

* None

# WildFly cloud feature-pack API
Environment variables defined by the cloud feature-pack used to configure the server:

* `OIDC_PROVIDER_NAME`. Value `keycloak`, required
* `OIDC_USER_NAME`. User name to retrieve token used to create Clients.
* `OIDC_USER_PASSWORD`. User password to retrieve token used to create Client.
* `OIDC_SECURE_DEPLOYMENT_SECRET`. Secret known by the Client.
* `OIDC_PROVIDER_URL`. Keycloak server URL.
* `OIDC_HOSTNAME_HTTP`. Web application host name.

# Pre-requisites

* minikube is running with the registry addons enabled. You have `kubectl` command in your path

# Example steps

1. Build the application

`mvn clean package`

2. Build the application image

`docker build -t elytron-oidc-client:latest .`

3. Tag and push the image to the kubernetes registry

* Retrieve the registry CLUSTER IP address: `kubectl get services --all-namespaces`
* TODO To document with port forwarding...

4. Access the cluster IP external (CLUSTER_IP), needed to update application deployment, access the keycloak server and example application.

```
kubectl cluster-info
```

5. Deploy a Keycloak server (Service using NodePort 30079)

```
kubectl create -f keycloak-deployment.yaml
kubectl create -f keycloak-service.yaml
```

6. Create the Keycloak realm, user and role in the keycloak admin console

  * Keycloak console is at : `https://CLUSTER_IP:30079`
  * Add the `Wildfly` realm
  * Add the role `Users`
  * Add the user `demo`, password `demo` , add the role `Users` to it.
  * In the role Users add the role `create-client` to the Client Roles `realm-management`.

7. Create the application deployment and service nodePort (Service using NodePort 30078)

  * Update the `app-deployment.yaml` file with the correct CLUSTER_IP address and DOCKER_REGISTRY_IP.
  * Create the deployment and service

```
kubectl create -f app-deployment.yaml
kubectl create -f app-service.yaml
```

8. Access the application: ` http://CLUSTER_IP:30078/simple-webapp`

9. Access the secured servlet.

10. Log-in using the `demo` user, `demo` password (that you created in the initial steps)

11. You should see a page containing the Principal ID


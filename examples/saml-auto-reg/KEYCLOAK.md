=== HOW-TO setup Keycloak using the Keycloak Operator

Store the name of the OpenShift namespace you wish to use, in a shell variable:

```bash
export NAMESPACE=<MY_NAMESPACE>
```
==== keycloak setup

Deploy Keycloak using the Keycloak Operator (note we are using the productized version of Keycloak here);

First we need to create a Database for persisting realm data across PODs restart:

```bash
oc create serviceaccount postgresql-serviceaccount
oc adm policy add-scc-to-user anyuid -z postgresql-serviceaccount

cat <<EOF > /tmp/Postgresql.yaml
apiVersion: v1
kind: Secret
metadata:
  name: keycloak-db-secret
  namespace: $NAMESPACE
data:
  username: cG9zdGdyZXM= # postgres
  password: dGVzdHBhc3N3b3Jk # testpassword
type: Opaque
---
# PostgreSQL StatefulSet
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgresql-db
  namespace: $NAMESPACE
spec:
  serviceName: postgresql-db-service
  selector:
    matchLabels:
      app: postgresql-db
  replicas: 1
  template:
    metadata:
      labels:
        app: postgresql-db
    spec:
      serviceAccountName: postgresql-serviceaccount
      containers:
        - name: postgresql-db
          image: quay.io/tborgato/postgres
          env:
            - name: POSTGRES_PASSWORD
              value: testpassword
            - name: PGDATA
              value: /data/pgdata
            - name: POSTGRES_DB
              value: keycloak
---
# PostgreSQL StatefulSet Service
apiVersion: v1
kind: Service
metadata:
  name: postgres-db
  namespace: $NAMESPACE
spec:
  selector:
    app: postgresql-db
  type: LoadBalancer
  ports:
  - port: 5432
    targetPort: 5432
EOF
oc apply -f /tmp/Postgresql.yaml  
```

Create an `OperatorGroup`:

```bash
cat <<EOF > /tmp/OperatorGroup.yaml
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  annotations:
  name: $NAMESPACE-operators
  namespace: $NAMESPACE
spec:
  targetNamespaces:
    - $NAMESPACE
  upgradeStrategy: Default
EOF
oc apply -f /tmp/OperatorGroup.yaml
```
Create a `Subscription` to the Keycloak Operator:

```bash
cat << EOF > /tmp/Subscription.yaml
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: keycloak-operator
  namespace: $NAMESPACE
spec:
  channel: fast
  installPlanApproval: Automatic
  name: keycloak-operator
  source: community-operators
  sourceNamespace: openshift-marketplace
EOF
oc apply -f /tmp/Subscription.yaml
```

Create the key and certificate to be sed by the `Keycloak` instance for HTTPS:

```bash
openssl req -newkey rsa:2048 -keyout key.pem -x509 -days 365 -out certificate.pem -nodes -subj '/CN=keycloak.example.com'

oc create secret tls keycloak-basic-tls-secret --cert=certificate.pem --key=key.pem --namespace $NAMESPACE
```

Deploy a `Keycloak` instance:

```bash
export OC_CONSOLE_HOSTNAME=$(oc get routes/console -n openshift-console --template='{{.spec.host}}')
export KEYCLOAK_HOSTNAME="keycloak-basic.${OC_CONSOLE_HOSTNAME#*\.}"

cat << EOF > /tmp/Keycloak.yaml
apiVersion: k8s.keycloak.org/v2alpha1
kind: Keycloak
metadata:
  name: keycloak-basic
  labels:
    app: sso
  namespace: $NAMESPACE
spec:
  hostname: 
    hostname: $KEYCLOAK_HOSTNAME
  ingress:
    enabled: true
  instances: 1
  http:
    tlsSecret: keycloak-basic-tls-secret
  db:
    vendor: postgres
    host: postgres-db
    usernameSecret:
      name: keycloak-db-secret
      key: username
    passwordSecret:
      name: keycloak-db-secret
      key: password    
EOF
oc apply -f /tmp/Keycloak.yaml
```

After the Operator's POD as been deployed you might want to retrieve the credentials to access the Keycloak console as in the following:

```bash
oc get secrets/keycloak-basic-initial-admin -o jsonpath='{.data.username}' -n $NAMESPACE | base64 --decode
oc get secrets/keycloak-basic-initial-admin -o jsonpath='{.data.password}' -n $NAMESPACE | base64 --decode
```

Define a `KeycloakRealmImport`:

```bash
cat << EOF > /tmp/KeycloakRealmImport.yaml
apiVersion: k8s.keycloak.org/v2alpha1
kind: KeycloakRealmImport
metadata:
  name: saml-basic-auth
  labels:
    app: sso
  namespace: $NAMESPACE
spec:
  realm:
    realm: saml-basic-auth
    id: saml-basic-auth
    enabled: true
    users:
      - username: admin
        credentials:
          - type: password
            value: password
        enabled: true
        realmRoles:
          - admin
          - user
      - username: demo
        credentials:
          - type: password
            value: demo
        enabled: true
        realmRoles:
          - user
      - username: client-admin
        credentials:
          - type: password
            value: client-admin
        enabled: true
        clientRoles:
          account:
            - "manage-account"
          realm-management:
            - "create-client"
            - "manage-realm"
            - "manage-clients"    
  keycloakCRName: keycloak-basic
EOF
oc apply -f /tmp/KeycloakRealmImport.yaml
```

in the `KeycloakRealmImport` definitions please note we define a user `client` which is required for EAP being able to register
a new SAML client into Keycloak;
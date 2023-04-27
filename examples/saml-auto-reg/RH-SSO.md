=== HOW-TO setup RH-SSO using the RH-SSO Operator

Store the name of the OpenShift namespace you wish to use, in a shell variable:

```bash
export NAMESPACE=<MY_NAMESPACE>
```

==== RH-SSO setup

Deploy RH-SSO using the RH-SSO Operator (Red Hat version of Keycloak):

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

Create a `Subscription` to the RH-SSO Operator:

```bash
cat <<EOF > /tmp/Subscription.yaml
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: rhsso-operator
spec:
  channel: stable
  config:
    env:
      - name: RELATED_IMAGE_RHSSO
        value: registry.redhat.io/rh-sso-7/sso76-openshift-rhel8:latest
      - name: PROFILE
        value: RHSSO
  name: rhsso-operator
  source: redhat-operators
  sourceNamespace: openshift-marketplace
EOF
oc apply -f /tmp/Subscription.yaml
```

Deploy a `Keycloak` instance which is actually the RH-SSO instance:

```bash
cat <<EOF > /tmp/Keycloak.yaml
apiVersion: keycloak.org/v1alpha1
kind: Keycloak
metadata:
  labels:
    app: sso
  name: rhsso-basic
spec:
  externalAccess:
    enabled: true
  instances: 1
EOF
oc apply -f /tmp/Keycloak.yaml
```

After the Operator's POD as been deployed you might want to retrieve the credentials to access the RH-SSO console as in the following:

```bash
oc get secrets/credential-rhsso-basic -o jsonpath='{.data.ADMIN_USERNAME}' -n $NAMESPACE | base64 --decode
oc get secrets/credential-rhsso-basic -o jsonpath='{.data.ADMIN_PASSWORD}' -n $NAMESPACE | base64 --decode
```

Define a `KeycloakRealm`:

```bash
apiVersion: keycloak.org/v1alpha1
kind: KeycloakRealm
metadata:
  name: saml-basic-auth
  labels:
    app: sso
spec:
  instanceSelector:
    matchLabels:
      app: sso
  realm:
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
          - type: demo
            value: user
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
    displayName: saml-basic-auth
    realm: saml-basic-auth
    id: saml-basic-auth
EOF
oc apply -f /tmp/KeycloakRealm.yaml
```

in the `KeycloakRealm` definitions please note we define a user `client` which is required for EAP being able to register
a new SAML client into RH-SSO;
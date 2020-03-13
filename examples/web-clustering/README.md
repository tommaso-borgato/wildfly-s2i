Simple example to highlight Web session sharing between pod instances

Setup openshift
===============

* oc import-image wildfly --from=quay.io/wildfly/wildfly:latest --confirm
* oc import-image wildfly-runtime --from=quay.io/wildfly/wildfly-runtime:latest --confirm
* Chained build template: _oc create -f templates/wildfly-s2i-chained-build-template.yml_
* Allow to view all pods in the project: _oc policy add-role-to-user view system:serviceaccount:$(oc project -q):default_

Build and run the application
=============================

We are provisioning a web server with support for web session sharing.

* Build application image: _oc new-app wildfly-s2i-chained-build-template -p APPLICATION_NAME=web-clustering \
      -p GIT_REPO=https://github.com/wildfly/wildfly-s2i \
      -p GIT_CONTEXT_DIR=examples/web-clustering \
      -p GALLEON_PROVISION_LAYERS=web-server,web-clustering \
      -p IMAGE_STREAM_NAMESPACE=myproject_

* Create application from application image: _oc new-app myproject/web-clustering -e KUBERNETES_NAMESPACE=myproject -e JGROUPS_CLUSTER_PASSWORD=mypassword_

NB: The KUBERNETES_NAMESPACE is required to see other pods in the project, otherwise the server attempts to retrieve pods from the 'default' namespace that is not the one our peoject is using.
JGROUPS_CLUSTER_PASSWORD is used to authenticate server in the cluster.

* _oc expose svc/web-clustering_

* Access the application route, note the user created time and session ID.

* Scale the application to 2 pods: _oc scale --replicas=2 dc web-clustering_

* List pods: _oc get pods_

* Kill the oldest POD (that answered the first application request): _oc delete pod web-clustering-1-r4cx8 -n myproject_

* Access the application again, you will notice that the displayed values are the same, web session has been shared between the 2 pods.
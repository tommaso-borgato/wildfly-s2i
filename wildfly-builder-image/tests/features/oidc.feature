
@wildfly/wildfly-s2i-jdk11
Feature: OIDC tests

   Scenario: deploys an examples, then checks if it's deployed.
     Given XML namespaces
       | prefix | url                          |
       | ns     | urn:wildfly:elytron-oidc-client:1.0 |
     Given s2i build git://github.com/jfdenise/wildfly-s2i from test/test-app-elytron-oidc-client with env and True using v2
       | variable               | value                                            |
       | OIDC_PROVIDER_NAME | keycloak |
       | OIDC_PROVIDER_URL           | http://localhost:8080/auth/realms/demo    |
       | MAVEN_REPO_ID         | staging |
       | MAVEN_REPO_URL      | https://repository.jboss.org/nexus/content/repositories/snapshots |
    Then container log should contain WFLYSRV0010: Deployed "oidc-webapp.war"
    Then XML file /opt/server/standalone/configuration/standalone.xml should contain value keycloak on XPath //ns:provider/@name
@wip
   Scenario: deploys the keycloak examples, then checks if it's deployed.
     Given XML namespaces
       | prefix | url                          |
       | ns     | urn:wildfly:elytron-oidc-client:1.0 |
     Given s2i build https://github.com/jfdenise/redhat-sso-quickstarts using oidc-support
       | variable               | value                                            |
       | ARTIFACT_DIR           | app-jee-jsp/target,app-profile-jee-jsp/target |
       | OIDC_PROVIDER_NAME | keycloak |
       | OIDC_PROVIDER_URL           | http://localhost:8080/auth/realms/demo    |
       | MAVEN_ARGS_APPEND | -Dmaven.compiler.source=1.6 -Dmaven.compiler.target=1.6 |
       | GALLEON_PROVISION_LAYERS | web-server,elytron-oidc-client |
       | GALLEON_PROVISION_FEATURE_PACKS | org.wildfly:wildfly-galleon-pack:25.0.0.Final,org.wildfly:wildfly-cloud-galleon-pack:1.0.0.Final-SNAPSHOT |
       | MAVEN_REPO_ID         | snapshot |
       | MAVEN_REPO_URL      | https://repository.jboss.org/nexus/content/repositories/snapshots |
    Then container log should contain WFLYSRV0010: Deployed "app-profile-jsp.war"
    Then container log should contain WFLYSRV0010: Deployed "app-jsp.war"
    Then XML file /opt/server/standalone/configuration/standalone.xml should contain value keycloak on XPath //ns:provider/@name

  Scenario: deploys the keycloak examples, then checks if it's deployed in cloud-server,elytron-oidc-client layers.
     Given XML namespaces
       | prefix | url                          |
       | ns     | urn:wildfly:elytron-oidc-client:1.0 |
     Given s2i build https://github.com/jfdenise/redhat-sso-quickstarts from . with env and true using oidc-support
       | variable               | value                                            |
       | ARTIFACT_DIR           | app-jee-jsp/target,app-profile-jee-jsp/target |
       | OIDC_PROVIDER_NAME | keycloak |
       | OIDC_PROVIDER_URL           | http://localhost:8080/auth/realms/demo    |
       | MAVEN_ARGS_APPEND | -Dmaven.compiler.source=1.6 -Dmaven.compiler.target=1.6 |
       | GALLEON_PROVISION_LAYERS | web-server,elytron-oidc-client |
       | GALLEON_PROVISION_FEATURE_PACKS | org.wildfly:wildfly-cloud-galleon-pack:25.0.0.Final |
        | MAVEN_REPO_ID         | staging |
       | MAVEN_REPO_URL      | https://repository.jboss.org/nexus/content/repositories/jboss_releases_staging_profile-18431 |
    Then container log should contain WFLYSRV0010: Deployed "app-profile-jsp.war"
    Then container log should contain WFLYSRV0010: Deployed "app-jsp.war"
    Then XML file /opt/server/standalone/configuration/standalone.xml should contain value keycloak on XPath //ns:provider/@name

Scenario: Check custom keycloak config in cloud-server,oidc-elytron-layer layers.
     Given s2i build https://github.com/jfdenise/redhat-sso-quickstarts from . with env and true using oidc-support
       | variable               | value                                                                     |
       | ARTIFACT_DIR           | app-jee-jsp/target,service-jee-jaxrs/target,app-profile-jee-jsp/target    |
       | OIDC_PROVIDER_NAME | keycloak |
       | OIDC_PROVIDER_URL                | http://localhost:8080/auth/realms/demo    |
       | OIDC_SECURE_DEPLOYMENT_ENABLE_CORS        | true                          |
       | OIDC_SECURE_DEPLOYMENT_BEARER_ONLY        | true                          |
       | MAVEN_ARGS_APPEND      | -Dmaven.compiler.source=1.6 -Dmaven.compiler.target=1.6 |
       | GALLEON_PROVISION_LAYERS | web-server,elytron-oidc-client |
       | GALLEON_PROVISION_FEATURE_PACKS | org.wildfly:wildfly-cloud-galleon-pack:25.0.0.Final |
        | MAVEN_REPO_ID         | staging |
       | MAVEN_REPO_URL      | https://repository.jboss.org/nexus/content/repositories/jboss_releases_staging_profile-18431 |
    Then container log should contain Deployed "service.war"
    And container log should contain Deployed "app-profile-jsp.war"
    And container log should contain Deployed "app-jsp.war"
    And XML file /opt/server/standalone/configuration/standalone.xml should contain value keycloak on XPath //*[local-name()='provider']/@name
    And XML file /opt/server/standalone/configuration/standalone.xml should contain value app-jsp.war on XPath //*[local-name()='secure-deployment']/@name
    And XML file /opt/server/standalone/configuration/standalone.xml should contain value true on XPath //*[local-name()='provider']/*[local-name()='enable-cors']
    And XML file /opt/server/standalone/configuration/standalone.xml should contain value true on XPath //*[local-name()='secure-deployment'][@name="app-jsp.war"]/*[local-name()='bearer-only']
    And XML file /opt/server/standalone/configuration/standalone.xml should contain value true on XPath //*[local-name()='secure-deployment'][@name="app-jsp.war"]/*[local-name()='enable-basic-auth'] 
    And XML file /opt/server/standalone/configuration/standalone.xml should contain value http://localhost:8080/auth/realms/demo on XPath //*[local-name()='provider']/*[local-name()='provider-url']
    And XML file /opt/server/standalone/configuration/standalone.xml should contain value app-profile-jsp.war on XPath //*[local-name()='secure-deployment']/@name
    And XML file /opt/server/standalone/configuration/standalone.xml should contain value service.war on XPath //*[local-name()='secure-deployment']/@name
 
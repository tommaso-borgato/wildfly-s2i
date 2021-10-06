@wildfly/wildfly-s2i-jdk11
Feature: Keycloak tests

   Scenario: deploys the keycloak examples, then checks if it's deployed.
     Given XML namespaces
       | prefix | url                          |
       | ns     | urn:jboss:domain:keycloak:1.2 |
     Given s2i build git://github.com/jfdenise/wildfly-s2i from test/test-app-keycloak with env and true using v2
       | variable               | value                                            |
       | ARTIFACT_DIR           | all-apps/target |
       | SSO_USE_LEGACY | true|
       | SSO_REALM         | demo    |
       | SSO_PUBLIC_KEY    | MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAiLezsNQtZSaJvNZXTmjhlpIJnnwgGL5R1vkPLdt7odMgDzLHQ1h4DlfJPuPI4aI8uo8VkSGYQXWaOGUh3YJXtdO1vcym1SuP8ep6YnDy9vbUibA/o8RW6Wnj3Y4tqShIfuWf3MEsiH+KizoIJm6Av7DTGZSGFQnZWxBEZ2WUyFt297aLWuVM0k9vHMWSraXQo78XuU3pxrYzkI+A4QpeShg8xE7mNrs8g3uTmc53KR45+wW1icclzdix/JcT6YaSgLEVrIR9WkkYfEGj3vSrOzYA46pQe6WQoenLKtIDFmFDPjhcPoi989px9f+1HCIYP0txBS/hnJZaPdn5/lEUKQIDAQAB  |
       | SSO_URL           | http://localhost:8080/auth    |
       | MAVEN_REPO_ID         | staging |
       | MAVEN_REPO_URL      | https://repository.jboss.org/nexus/content/repositories/jboss_releases_staging_profile-18431 |
    Then container log should contain WFLYSRV0010: Deployed "app-profile-jee.war"
    Then container log should contain WFLYSRV0010: Deployed "app-profile-jee-saml.war"
    Then XML file /opt/server/standalone/configuration/standalone.xml should contain value demo on XPath //ns:realm/@name

   Scenario: deploys the keycloak oidc example using secure-deployments CLI then checks if it's deployed.
     Given XML namespaces
       | prefix | url                          |
       | ns     | urn:jboss:domain:keycloak:1.2 |
     Given s2i build git://github.com/jfdenise/wildfly-s2i from test/test-app-keycloak with env and true using v2
       | variable                   | value                                            |
       | SSO_USE_LEGACY | true|
       | ARTIFACT_DIR               | app-profile-jee/target |
       | MAVEN_REPO_ID         | staging |
       | MAVEN_REPO_URL      | https://repository.jboss.org/nexus/content/repositories/jboss_releases_staging_profile-18431 |
    Then container log should contain Existing other application-security-domain is extended with support for keycloak
    Then container log should contain WFLYSRV0025
    Then container log should contain WFLYSRV0010: Deployed "app-profile-jee.war"
    And XML file /opt/server/standalone/configuration/standalone.xml should contain value demo on XPath //*[local-name()='realm']/@name
    And XML file /opt/server/standalone/configuration/standalone.xml should contain value app-profile-jee.war on XPath //*[local-name()='secure-deployment']/@name
    And XML file /opt/server/standalone/configuration/standalone.xml should contain value false on XPath //*[local-name()='secure-deployment'][@name="app-profile-jee.war"]/*[local-name()='enable-cors']
    And XML file /opt/server/standalone/configuration/standalone.xml should contain value https://secure-sso-demo.cloudapps.example.com/auth on XPath //*[local-name()='secure-deployment'][@name="app-profile-jee.war"]/*[local-name()='auth-server-url']

Scenario: deploys the keycloak saml example using secure-deployments CLI then checks if it's deployed.
     Given XML namespaces
       | prefix | url                          |
       | ns     | urn:jboss:domain:keycloak:1.2 |
     Given s2i build git://github.com/jfdenise/wildfly-s2i from test/test-app-keycloak with env and true using v2
       | variable                   | value                                            |
       | SSO_USE_LEGACY | true|
       | ARTIFACT_DIR               | app-profile-jee-saml/target |
       | MAVEN_REPO_ID         | staging |
       | MAVEN_REPO_URL      | https://repository.jboss.org/nexus/content/repositories/jboss_releases_staging_profile-18431 |
    Then container log should contain Existing other application-security-domain is extended with support for keycloak
    Then container log should contain WFLYSRV0025
    Then container log should contain WFLYSRV0010: Deployed "app-profile-jee-saml.war"
    And XML file /opt/server/standalone/configuration/standalone.xml should contain value app-profile-jee-saml.war on XPath //*[local-name()='secure-deployment']/@name
    And XML file /opt/server/standalone/configuration/standalone.xml should contain value app-profile-jee-saml on XPath //*[local-name()='secure-deployment'][@name="app-profile-jee-saml.war"]/*[local-name()='SP']/@entityID
    And XML file /opt/server/standalone/configuration/standalone.xml should contain value EXTERNAL on XPath //*[local-name()='secure-deployment'][@name="app-profile-jee-saml.war"]/*[local-name()='SP']/@sslPolicy
    And XML file /opt/server/standalone/configuration/standalone.xml should contain value true on XPath //*[local-name()='secure-deployment'][@name="app-profile-jee-saml.war"]/*[local-name()='SP']/*[local-name()='Keys']/*[local-name()='Key']/@signing 
    And XML file /opt/server/standalone/configuration/standalone.xml should contain value idp on XPath //*[local-name()='secure-deployment'][@name="app-profile-jee-saml.war"]/*[local-name()='SP']/*[local-name()='IDP']/@entityID 

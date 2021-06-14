@wildfly/wildfly-ubi8

Feature: Wildfly configured with env vars tests
  Scenario:  Test addition of datasource
    Given s2i build git://github.com/jfdenise/wildfly-s2i from test/test-app-postgresql-mysql with env and true using wildfly-s2i-v2
      | variable                     | value                                         |
      | DB_SERVICE_PREFIX_MAPPING    | TEST-postgresql=test                          |
      | TEST_POSTGRESQL_SERVICE_HOST | localhost                                     |
      | TEST_POSTGRESQL_SERVICE_PORT | 5432                                          |
      | test_DATABASE                | demo                                          |
      | test_JNDI                    | java:jboss/datasources/test-postgresql        |
      | test_JTA                     | false                                         |
      | test_NONXA                   | true                                          |
      | test_PASSWORD                | demo                                          |
      | test_URL                     | jdbc:postgresql://localhost:5432/postgresdb   |
      | test_USERNAME                | demo                                          |
    Then container log should contain WFLYSRV0025
    Then XML file /opt/wildfly/standalone/configuration/standalone.xml should contain value test_postgresql-test on XPath //*[local-name()='datasource']/@pool-name
    Then XML file /opt/wildfly/standalone/configuration/standalone.xml should contain value MySQLDS on XPath //*[local-name()='datasource']/@pool-name
    Then XML file /opt/wildfly/standalone/configuration/standalone.xml should contain value PostgreSQLDS on XPath //*[local-name()='datasource']/@pool-name
    And check that page is served
      | property | value |
      | path     | /     |
      | port     | 8080  |

  Scenario:  Test execution of builder image and addition of json logging
    Given s2i build git://github.com/jfdenise/wildfly-s2i from test/test-app with env and true using wildfly-s2i-v2
      | variable               | value |
      | ENABLE_JSON_LOGGING    | true  |
    Then container log should contain WFLYSRV0025
    Then container log should not contain Configuring the server using embedded server
    Then file /opt/wildfly/standalone/configuration/logging.properties should contain handler.CONSOLE.formatter=OPENSHIFT
    Then XML file /opt/wildfly/standalone/configuration/standalone.xml should contain value OPENSHIFT on XPath //*[local-name()='named-formatter']/@name
    Then XML file /opt/wildfly/standalone/configuration/standalone.xml should contain value OPENSHIFT on XPath //*[local-name()='formatter']/@name
    And check that page is served
      | property | value |
      | path     | /     |
      | port     | 8080  |

  Scenario: Test fallback to CLI process launched for configuration
    Given s2i build git://github.com/jfdenise/wildfly-s2i from test/test-app with env and true using wildfly-s2i-v2
      | variable               | value |
      | ENABLE_JSON_LOGGING    | true  |
      | DISABLE_BOOT_SCRIPT_INVOKER | true |
    Then container log should contain WFLYSRV0025
    Then container log should contain Configuring the server using embedded server
    Then file /opt/wildfly/standalone/configuration/logging.properties should contain handler.CONSOLE.formatter=OPENSHIFT
    Then XML file /opt/wildfly/standalone/configuration/standalone.xml should contain value OPENSHIFT on XPath //*[local-name()='named-formatter']/@name
    Then XML file /opt/wildfly/standalone/configuration/standalone.xml should contain value OPENSHIFT on XPath //*[local-name()='formatter']/@name
    And check that page is served
      | property | value |
      | path     | /     |
      | port     | 8080  |

  Scenario: No tracing
    Given s2i build git://github.com/jfdenise/wildfly-s2i from test/test-app with env and true using wildfly-s2i-v2
       | variable                    | value             |
       | WILDFLY_TRACING_ENABLED     | false              |
    Then container log should contain WFLYSRV0025
    Then XML file /opt/wildfly/standalone/configuration/standalone.xml should have 0 elements on XPath  //*[local-name()='extension'][@module="org.wildfly.extension.microprofile.opentracing-smallrye"]
    Then XML file /opt/wildfly/standalone/configuration/standalone.xml should have 0 elements on XPath  //*[local-name()='subsystem' and starts-with(namespace-uri(), 'urn:wildfly:microprofile-opentracing-smallrye:')]

  Scenario: Enable tracing
    Given s2i build git://github.com/jfdenise/wildfly-s2i from test/test-app with env and true using wildfly-s2i-v2
       | variable                    | value             |
       | WILDFLY_TRACING_ENABLED     | true              |
    Then container log should contain WFLYSRV0025
    Then XML file /opt/wildfly/standalone/configuration/standalone.xml should have 1 elements on XPath  //*[local-name()='extension'][@module="org.wildfly.extension.microprofile.opentracing-smallrye"]
    Then XML file /opt/wildfly/standalone/configuration/standalone.xml should have 1 elements on XPath  //*[local-name()='subsystem' and starts-with(namespace-uri(), 'urn:wildfly:microprofile-opentracing-smallrye:')]


  #JSON logging should have no effect on the configuration, server should start properly
  # although logging subsystem is not present in cloud-profile.
  # Disable opentracing present in cloud-profile observability

  Scenario: Test deployment in cloud-server server.
    Given s2i build git://github.com/jfdenise/wildfly-s2i from test/test-app with env and true using wildfly-s2i-v2
      | variable                             | value          |
      | WILDFLY_TRACING_ENABLED              | false          |
      | ENABLE_JSON_LOGGING                  | true           |
    Then container log should contain WFLYSRV0025
    And check that page is served
      | property | value |
      | path     | /     |
      | port     | 8080  |
    Then XML file /opt/wildfly/standalone/configuration/standalone.xml should have 0 elements on XPath  //*[local-name()='extension'][@module="org.wildfly.extension.microprofile.opentracing-smallrye"]
    Then XML file /opt/wildfly/standalone/configuration/standalone.xml should have 0 elements on XPath  //*[local-name()='subsystem' and starts-with(namespace-uri(), 'urn:wildfly:microprofile-opentracing-smallrye:')]
    Then XML file /opt/wildfly/.galleon/provisioning.xml should contain value cloud-server on XPath //*[local-name()='installation']/*[local-name()='config']/*[local-name()='layers']/*[local-name()='include']/@name

  Scenario: Test dirver added during provisioning.
    Given s2i build https://github.com/jfdenise/wildfly-s2i from test/test-app-postgresql-mysql with env and true using wildfly-s2i-v2
      | variable                     | value                                                       |
      | ENV_FILES                    | /opt/wildfly/standalone/configuration/datasources.env |
      | POSTGRESQL_ENABLED | false |
      | MYSQL_ENABLED            | false |
    Then container log should contain WFLYSRV0025
    And check that page is served
      | property | value |
      | path     | /     |
      | port     | 8080  |
    Then XML file /opt/wildfly/standalone/configuration/standalone.xml should have 1 elements on XPath  //*[local-name()='extension'][@module="org.wildfly.extension.microprofile.opentracing-smallrye"]
    Then XML file /opt/wildfly/standalone/configuration/standalone.xml should have 1 elements on XPath  //*[local-name()='subsystem' and starts-with(namespace-uri(), 'urn:wildfly:microprofile-opentracing-smallrye:')]
    Then XML file /opt/wildfly/standalone/configuration/standalone.xml should contain value test-TEST on XPath //*[local-name()='datasource']/@pool-name
    Then XML file /opt/wildfly/standalone/configuration/standalone.xml should contain value postgresql on XPath //*[local-name()='driver']/@name

  Scenario: Test external driver created during s2i.
    Given s2i build https://github.com/jfdenise/wildfly-s2i from test/test-app-postgresql-mysql with env and true using wildfly-s2i-v2
      | variable                     | value                                                       |
      | ENV_FILES                    | /opt/wildfly/standalone/configuration/datasources.env |
      | POSTGRESQL_ENABLED | false |
      | MYSQL_ENABLED            | false |
      | DISABLE_BOOT_SCRIPT_INVOKER  | true |
    Then container log should contain Configuring the server using embedded server
    Then container log should contain WFLYSRV0025
    And check that page is served
      | property | value |
      | path     | /     |
      | port     | 8080  |
    Then XML file /opt/wildfly/standalone/configuration/standalone.xml should have 1 elements on XPath  //*[local-name()='extension'][@module="org.wildfly.extension.microprofile.opentracing-smallrye"]
    Then XML file /opt/wildfly/standalone/configuration/standalone.xml should have 1 elements on XPath  //*[local-name()='subsystem' and starts-with(namespace-uri(), 'urn:wildfly:microprofile-opentracing-smallrye:')]
    Then XML file /opt/wildfly/standalone/configuration/standalone.xml should contain value test-TEST on XPath //*[local-name()='datasource']/@pool-name
    Then XML file /opt/wildfly/standalone/configuration/standalone.xml should contain value postgresql on XPath //*[local-name()='driver']/@name
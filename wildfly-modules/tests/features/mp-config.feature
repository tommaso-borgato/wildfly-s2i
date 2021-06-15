@wildfly/wildfly-ubi8
Feature: Openshift mp-config tests

  Scenario: Micro-profile config configuration, galleon s2i
    Given s2i build https://github.com/jfdenise/wildfly-s2i from test/test-app with env and True using wildfly-s2i-v2
       | variable                                | value           |
       | MICROPROFILE_CONFIG_DIR                 | /home/jboss     |
       | MICROPROFILE_CONFIG_DIR_ORDINAL         | 88              |
    Then XML file /opt/wildfly/standalone/configuration/standalone.xml should contain value /home/jboss on XPath //*[local-name()='config-source' and @name='config-map']/*[local-name()='dir']/@path
    Then XML file /opt/wildfly/standalone/configuration/standalone.xml should contain value 88 on XPath //*[local-name()='config-source' and @name='config-map']/@ordinal

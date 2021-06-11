Feature: Openshift WildFly shutdown tests

  Scenario: Check if image shuts down with TERM signal
    Given s2i build git://github.com/jfdenise/wildfly-s2i from test/vanilla-wildfly/test-app with env and true using wildfly-s2i-v2
    Then container log should contain WFLYSRV0025
    And run kill -TERM 1 in container once
    And container log should contain received TERM signal
    And exactly 1 times container log should contain WFLYSRV0050

  Scenario: Check if image does not shutdown with TERM signal when CLI_GRACEFUL_SHUTDOWN is set
    Given s2i build git://github.com/jfdenise/wildfly-s2i from test/vanilla-wildfly/test-app with env and true using wildfly-s2i-v2
       | variable                  | value           |
       | CLI_GRACEFUL_SHUTDOWN     | true            |
    Then container log should contain WFLYSRV0025
    And run kill -TERM 1 in container once
    And container log should not contain received TERM signal
    And container log should not contain WFLYSRV0050

  Scenario: Check if image shuts down with cli when CLI_GRACEFUL_SHUTDOWN is set
    Given s2i build git://github.com/jfdenise/wildfly-s2i from test/vanilla-wildfly/test-app with env and true using wildfly-s2i-v2
       | variable                  | value           |
       | CLI_GRACEFUL_SHUTDOWN     | true            |
    Then container log should contain WFLYSRV0025
    And run /opt/wildfly/bin/jboss-cli.sh -c "shutdown --timeout=60" in container once
    And container log should not contain received TERM signal
    And exactly 1 times container log should contain WFLYSRV0050

  Scenario: Check if image shuts down cleanly with TERM signal
    Given s2i build git://github.com/jfdenise/wildfly-s2i from test/vanilla-wildfly/test-app with env and true using wildfly-s2i-v2
    Then container log should contain WFLYSRV0025
    And run kill -TERM 1 in container once
    And container log should contain received TERM signal
    And container log should contain WFLYSRV0241
    And exactly 1 times container log should contain WFLYSRV0050
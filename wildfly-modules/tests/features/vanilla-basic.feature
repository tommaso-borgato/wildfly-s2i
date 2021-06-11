Feature: Vanilla Wildfly basic tests

 Scenario: Check if image version and release is printed on boot
   Given s2i build git://github.com/jfdenise/wildfly-s2i from test/vanilla-wildfly/test-app with env and true using wildfly-s2i-v2
   Then container log should contain Running wildfly/wildfly-ubi8 image, version

Scenario:  Test basic deployment vanilla WildFly
    Given s2i build git://github.com/jfdenise/wildfly-s2i from test/vanilla-wildfly/test-app with env and true using wildfly-s2i-v2
    Then container log should contain WFLYSRV0025
    And check that page is served
      | property | value |
      | path     | /     |
      | port     | 8080  |

Scenario: Zero port offset in galleon provisioned configuration with vanilla wildfly
    Given s2i build git://github.com/jfdenise/wildfly-s2i from test/vanilla-wildfly/test-app with env and true using wildfly-s2i-v2
       | variable                    | value           |
       | PORT_OFFSET                 | 1000            |
    Then container log should contain WFLYSRV0025
    And container log should contain -Djboss.socket.binding.port-offset=1000

# CLOUD-427: we need to ensure jboss.node.name doesn't go beyond 23 chars
  Scenario: Check that long node names are truncated to 23 characters
    Given s2i build git://github.com/jfdenise/wildfly-s2i from test/vanilla-wildfly/test-app with env and true using wildfly-s2i-v2
       | variable  | value                      |
       | NODE_NAME | abcdefghijklmnopqrstuvwxyz |
    Then container log should contain -Djboss.node.name=defghijklmnopqrstuvwxyz

  Scenario: Check that node name is used
    Given s2i build git://github.com/jfdenise/wildfly-s2i from test/vanilla-wildfly/test-app with env and true using wildfly-s2i-v2
       | variable  | value                      |
       | NODE_NAME | abcdefghijk                |
    Then container log should contain -Djboss.node.name=abcdefghijk

Scenario: Test to ensure that maven is run with -Djava.net.preferIPv4Stack=true and user-supplied arguments, even when MAVEN_ARGS is overridden, and doesn't clear the local repository after the build
    Given s2i build git://github.com/jfdenise/wildfly-s2i from test/vanilla-wildfly/test-app with env and true using wildfly-s2i-v2
       | variable          | value                                                                                  |
       | MAVEN_ARGS        | -e -Dcom.redhat.xpaas.repo.jbossorg -DskipTests package -Popenshift |
       | MAVEN_ARGS_APPEND | -Dfoo=bar                                                                              |
    Then container log should contain WFLYSRV0025
    And run sh -c 'test -d /tmp/artifacts/m2/org && echo all good' in container and immediately check its output for all good
    And s2i build log should contain -Djava.net.preferIPv4Stack=true
    And s2i build log should contain -Dfoo=bar
    And s2i build log should contain -XX:+UseParallelOldGC -XX:MinHeapFreeRatio=10 -XX:MaxHeapFreeRatio=20 -XX:GCTimeRatio=4 -XX:AdaptiveSizePolicyWeight=90 -XX:+ExitOnOutOfMemoryError

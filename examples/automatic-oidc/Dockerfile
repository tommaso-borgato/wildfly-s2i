FROM wildfly/wildfly-runtime-jdk11:dev
COPY --chown=jboss:root target/server $JBOSS_HOME
RUN chmod -R ug+rwX $JBOSS_HOME

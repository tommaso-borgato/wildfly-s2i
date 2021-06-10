#!/bin/bash

source "${JBOSS_HOME}/bin/launch/logging.sh"
imgName=${JBOSS_IMAGE_NAME:-$IMAGE_NAME}
imgVersion=${JBOSS_IMAGE_VERSION:-$IMAGE_VERSION}
log_info "Running $imgName image, version $imgVersion"

# Logic to allow for CLI shutdown with a 60secs delay that helps transaction to terminate 
function clean_shutdown() {
  local management_port=""
  if [ -n "${PORT_OFFSET}" ]; then
    management_port=$((9990 + PORT_OFFSET))
  fi
  log_error "*** WildFly wrapper process ($$) received TERM signal ***"
  if [ -z ${management_port} ]; then
    $JBOSS_HOME/bin/jboss-cli.sh -c "shutdown --timeout=60"
  else
    $JBOSS_HOME/bin/jboss-cli.sh --commands="connect remote+http://localhost:${management_port},shutdown --timeout=60"
  fi
  wait $!
}

function setupShutdownHook() {
  trap "clean_shutdown" TERM
  trap "clean_shutdown" INT

  if [ -n "$CLI_GRACEFUL_SHUTDOWN" ] ; then
    trap "" TERM
    log_info "Using CLI Graceful Shutdown instead of TERM signal"
  fi
}
# END SHUTDOWN LOGIC

function init_node_name() {
  if [ -z "${JBOSS_NODE_NAME}" ] ; then
    if [ -n "${NODE_NAME}" ]; then
      JBOSS_NODE_NAME="${NODE_NAME}"
    elif [ -n "${container_uuid}" ]; then
      JBOSS_NODE_NAME="${container_uuid}"
    elif [ -n "${HOSTNAME}" ]; then
      JBOSS_NODE_NAME="${HOSTNAME}"
    else
       JBOSS_NODE_NAME="$(hostname)"
    fi

    # CLOUD-427: truncate to 23 characters max (from the end backwards)
    if [ ${#JBOSS_NODE_NAME} -gt 23 ]; then
      JBOSS_NODE_NAME=${JBOSS_NODE_NAME: -23}
    fi
  fi
}

# HANDLE JAVA OPTIONS
source /usr/local/dynamic-resources/dynamic_resources.sh > /dev/null
GC_METASPACE_SIZE=${GC_METASPACE_SIZE:-96}

JAVA_OPTS="$(adjust_java_options ${JAVA_OPTS})"

# If JAVA_DIAGNOSTICS and there is jvm_specific_diagnostics, move the settings to PREPEND_JAVA_OPTS
# to bypass the specific EAP checks done on JAVA_OPTS in standalone.sh that could remove the GC EAP specific log configurations
JVM_SPECIFIC_DIAGNOSTICS=$(jvm_specific_diagnostics)
if [ "x$JAVA_DIAGNOSTICS" != "x" ] && [ "x{JVM_SPECIFIC_DIAGNOSTICS}" != "x" ]; then
  JAVA_OPTS=${JAVA_OPTS/${JVM_SPECIFIC_DIAGNOSTICS} /}
  PREPEND_JAVA_OPTS="${JVM_SPECIFIC_DIAGNOSTICS} ${PREPEND_JAVA_OPTS}"
fi

# Make sure that we use /dev/urandom (CLOUD-422)
JAVA_OPTS="${JAVA_OPTS} -Djava.security.egd=file:/dev/./urandom"

# DO WE KEEP?
# White list packages for use in ObjectMessages: CLOUD-703
if [ -n "$MQ_SERIALIZABLE_PACKAGES" ]; then
  JAVA_OPTS="${JAVA_OPTS} -Dorg.apache.activemq.SERIALIZABLE_PACKAGES=${MQ_SERIALIZABLE_PACKAGES}"
fi

# Append to JAVA_OPTS. Necessary to prevent some values being omitted if JAVA_OPTS is defined directly
JAVA_OPTS="$JAVA_OPTS $JAVA_OPTS_APPEND"

#Handle proxy options
source /opt/run-java/proxy-options
eval preConfigure
eval configure

# Handle port offset
if [ -n "${PORT_OFFSET}" ]; then
  PORT_OFFSET_PROPERTY="-Djboss.socket.binding.port-offset=${PORT_OFFSET}"
fi

PUBLIC_IP_ADDRESS=${SERVER_PUBLIC_BIND_ADDRESS:-$(hostname -i)}
MANAGEMENT_IP_ADDRESS=${SERVER_MANAGEMENT_BIND_ADDRESS:-0.0.0.0}
ENABLE_STATISTICS=${SERVER_ENABLE_STATISTICS:-true}

#Ensure node name (FOR NOW NEEDED PERHAPS REVISIT FOR EAP8)
init_node_name

SERVER_ARGS="${JAVA_PROXY_OPTIONS} -Djboss.node.name=${JBOSS_NODE_NAME} ${PORT_OFFSET_PROPERTY} -b ${PUBLIC_IP_ADDRESS} -bmanagement ${MANAGEMENT_IP_ADDRESS} -Dwildfly.statistics-enabled=${ENABLE_STATISTICS} ${SERVER_ARGS}"

log_info Starting server with arguments: ${SERVER_ARGS}

setupShutdownHook

export JAVA_OPTS

# The script must be launched in background for the server to not receive directly signals and allowing for CLI shutdown processed from this script.
$JBOSS_HOME/bin/server-launch.sh ${SERVER_ARGS} &
pid=$!
wait $pid 2>/dev/null


#!/bin/bash
SCRIPT_DIR=$(dirname $0)
cid_file=$(mktemp -u --suffix=.cid)
file="$SCRIPT_DIR/wildfly-s2i-galleon-pack.zip"
version=
if [ -z $1 ]; then
  image=quay.io/wildfly/wildfly-centos7
else
  image=$1
fi

copy_fp() {
  id=$(docker create $image)
  version="$(docker run --rm $image printenv WILDFLY_VERSION)"
  oldLocation=$(docker run --rm $image bash -c 'test -d /home/jboss/galleon-m2-repository && echo exists')
  if [ "$oldLocation" == "exists" ]; then
    docker cp $id:"/home/jboss/galleon-m2-repository/org/wildfly/galleon/s2i/wildfly-s2i-galleon-pack/${version}/wildfly-s2i-galleon-pack-${version}.zip" $file
  else
    docker cp $id:"/opt/jboss/container/wildfly/s2i/galleon/galleon-m2-repository/org/wildfly/galleon/s2i/wildfly-s2i-galleon-pack/${version}/wildfly-s2i-galleon-pack-${version}.zip" $file
  fi
}

image_exists() {
  docker inspect $image &>/dev/null
}

if ! image_exists; then
  docker pull $image
  if $? != 0; then
   echo  "Error, WildFly image doesn't exist."
   exit 1
  fi
fi

copy_fp

mvn install:install-file -Dfile=$file -DgroupId=org.wildfly.galleon.s2i -DartifactId=wildfly-s2i-galleon-pack -Dversion=$version -Dpackaging=zip
rm -rf $file

echo WildFly galleon s2i feature-pack installed in local repository.
echo "To provision a WildFly server from it call: 'galleon.sh install org.wildfly.galleon.s2i:wildfly-s2i-galleon-pack:18.0.0.Final --dir=<your dir> --default-configs=standalone/standalone.xml'"


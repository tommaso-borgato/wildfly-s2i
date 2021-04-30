docker tag quay.io/jfdenise/wildfly-centos7:test-dep-1.0 quay.io/jfdenise/wildfly-centos7:test-dep-1.0-foo
docker tag quay.io/jfdenise/wildfly-centos7:test-dep-1.0 quay.io/jfdenise/wildfly-centos7:latest-foo
docker tag quay.io/jfdenise/wildfly-runtime-centos7:test-dep-1.0 quay.io/jfdenise/wildfly-runtime-centos7:test-dep-1.0-foo
docker tag quay.io/jfdenise/wildfly-runtime-centos7:test-dep-1.0 quay.io/jfdenise/wildfly-runtime-centos7:latest-foo
docker push quay.io/jfdenise/wildfly-centos7:test-dep-1.0-foo
docker push quay.io/jfdenise/wildfly-centos7:latest-foo
docker push 
docker push quay.io/jfdenise/wildfly-runtime-centos7:latest-foo
docker tag quay.io/jfdenise/taskrs-app:latest quay.io/jfdenise/taskrs-app:latest-foo
docker push quay.io/jfdenise/taskrs-app:latest-foo
docker tag quay.io/jfdenise/clusterbench:latest quay.io/jfdenise/clusterbench:latest-foo
docker push quay.io/jfdenise/clusterbench:latest-foo

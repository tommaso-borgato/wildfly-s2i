#!/bin/bash

if [ -z "${WILDFLYS2I_FORK_NAME}" ];
then
  WILDFLYS2I_FORK_NAME="wildfly"
fi

currentBranch=$(git branch | sed -n '/\* /s///p')

# this is the path to the repo the build should run from. It should not begin with a leading /.
WILDFLY_REPO="${WILDFLYS2I_FORK_NAME}/wildfly-s2i/dispatches"

if [ -z "${WILDFLYS2I_GITHUB_PAT}" ];
then
    echo
    echo "Using this script requires the creation of a personal access token here: https://github.com/settings/tokens"
    echo "The token should have the following permissions: repo:status, repo_deployment, public_repo, read:packages, read:discussion, workflow"
    echo "Then export the token in your current shell: export WILDFLYS2I_GITHUB_PAT=... and re-run this script."
    echo
else
    curl \
    -X POST \
    -H "Authorization: token $WILDFLYS2I_GITHUB_PAT" \
    -H "Accept: application/vnd.github.ant-man-preview+json" \
    -H "Content-Type: application/json" \
    https://api.github.com/repos/${WILDFLY_REPO} \
    --data '{"event_type": "tag-released-images", "client_payload": { "wf-s2i-ref": "'"${currentBranch}"'"}'
fi

#!/bin/bash

# Prerequisits
# yq https://github.com/mikefarah/yq
# jq https://github.com/stedolan/jq

if [[ -z $GIT_TOKEN ]]; then
    echo "Please export a variable named 'GIT_TOKEN' containing personal access token for GitLab"
    exit 1
fi

function checkVersion {

    RAW=`yq read Terrafile $1.source`
    REGEX="^git@(.*):(.*)$"

    if [[ $RAW =~ $REGEX ]]; then
        SOURCE_DOMAIN="${BASH_REMATCH[1]}"
        SOURCE_PATH=`echo ${BASH_REMATCH[2]} | sed -e 's/\//%2F/g'`
    fi
    
    # echo "SOURCE_DOMAIN: $SOURCE_DOMAIN"
    # echo "SOURCE_PATH: $SOURCE_PATH"

    # API documentation - https://docs.gitlab.com/ee/api/tags.html
    API="https://$SOURCE_DOMAIN/api/v4/projects/$SOURCE_PATH"
    REPO_VERSION=`curl -qfs $API/repository/tags?private_token=$GIT_TOKEN | jq .[0].name -r `
    LOCAL_VERSION=`yq read Terrafile $1.version`

    # echo "REPO_VERSION: $REPO_VERSION"
    # echo "LOCAL_VERSION: $LOCAL_VERSION"

    if [[ "$REPO_VERSION" != "$LOCAL_VERSION" ]]; then
        echo "FAIL: $1 - repo: $REPO_VERSION / local: $LOCAL_VERSION" 
    else
        echo "PASS: $1 - version: $REPO_VERSION" 
    fi
}

export -f checkVersion
yq read Terrafile '[*]' --printMode p | xargs bash -c 'for arg; do checkVersion "$arg"; done' _

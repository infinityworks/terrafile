#!/bin/bash

# Prerequisits
# yq https://github.com/mikefarah/yq
# jq https://github.com/stedolan/jq

check_tput() {
  if `tput -V &> /dev/null`; then
    export bold=$(tput bold)
    export green=$(tput setaf 2)
    export blue=$(tput setaf 4)
    export red=$(tput setaf 1)
    export normal=$(tput sgr0)
  fi
}

check_tput

if [[ -z $GIT_TOKEN ]]; then
    echo "${red}Please export a variable named ${bold}GIT_TOKEN${normal}${red} containing your personal access token for GitLab${normal}"
    exit 1
fi

if ! `which terrafile &> /dev/null`; then
    echo "${red}${bold}Terrafile${normal}${red} not found in your path, please install it. Exiting...${normal}"
    exit 1
fi

if ! `which yq &> /dev/null`; then
    echo "${red}${bold}YQ${normal}${red} not found in your path, please install it. Exiting...${normal}"
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
    RESPONSE=`curl -qfs  --header "PRIVATE-TOKEN: $GIT_TOKEN" $API/repository/tags`
    REPO_VERSION=`jq .[0].name -r <<< "$RESPONSE"`
    LOCAL_VERSION=`yq read Terrafile $1.version`

    # echo "REPO_VERSION: $REPO_VERSION"
    # echo "LOCAL_VERSION: $LOCAL_VERSION"

    if [[ "$REPO_VERSION" != "$LOCAL_VERSION" ]]; then
        echo "${red}FAIL:${normal} $1 - repo: ${blue}$REPO_VERSION${normal} / local: ${red}$LOCAL_VERSION${normal}" 
    else
        echo "${green}PASS:${normal} $1 - version: ${blue}$REPO_VERSION"${normal}
    fi
}

export -f checkVersion
yq read Terrafile '[*]' --printMode p | xargs bash -c 'for arg; do checkVersion "$arg"; done' _

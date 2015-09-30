#!/bin/bash

################
# create-component-version
################
# andy.washbrook@thomsonreuters.com
################
# AW Tested on Mac OSX and Linux
################

# Optional argument with build number for manual builds...
#1=MANUAL_BUILD_NUMBER=1066

################ TODO must be updated by Component teams
COMPASS_COMPONENT="Client_Config"
COMPASS_COMPONENT_VERSION=0.0.1 # TODO AW retrieve from tag in future (jenkins integration)
################

################
# TODO grab latest tag rather than master
# git clone -n https://github.com/thomsonreuters/compass_puppet-common-tools.git common-tools
# git checkout `git describe --tags`
################
# TODO ensure compass_puppet in .gitignore
[ -d common-tools ] || git clone https://github.com/thomsonreuters/compass_puppet-common-tools.git common-tools

if [[ -d common-tools ]]; then
    cd common-tools
    git pull || echo "Warning: Updating component scripts from remote repo failed...git you are probably disconnected or proxy challenged!"
    cd -
else
    echo "Error: Could not clone component scripts repo, you are probably disconnected or proxy challenged!"
    exit 1 # No repo cached
fi

. ./common-tools/scripts/functions.sh

create_component_version "${COMPASS_COMPONENT}" "${COMPASS_COMPONENT_VERSION}" "${1}"

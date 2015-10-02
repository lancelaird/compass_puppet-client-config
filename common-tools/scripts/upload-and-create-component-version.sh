#!/bin/bash

################
# TODO must be updated by App teams
################
# CDA/CUDL Component does NOT have to be same be as package name or github repo name, spaces ok
################
COMPASS_COMPONENT="Homepage"
################
# Assumed to be name of github puppet repo compass_puppet-james-bond and name of app hiera key, so no spaces
################
export APP_NAME=homepage
################

set -o errexit # -e
set -o nounset # -u
set -o pipefail
set +o xtrace # -x

################
# andy.washbrook@thomsonreuters.com
################
# AW Tested on Mac OSX, OEL Linux and gitbash
################
# TWO use cases
# 1) App developer wants to enhance component package and release compass_puppet repo (during local dev or CI)
# - Package can be located anywhere, no assumptions on which dir it resides in!
# - Dev should be able to git clone project directly without renaming it compass_puppet
# 2) Puppet developer wants to enhance deployment (local dev)
# - Run from compass_puppet project
#Calling apps should build and package code as <pkg> no assumption on build or package type!
# - tag version <v>
# - pass two params <pkg> <v>
################

################
#PACKAGE="${PACKAGE_NAME}-${PACKAGE_VERSION}.x86_64.rpm"
#PACKAGE=compass-dashboard-0.1.00.1064-1.x86_64.rpm
################
# Full version including Jenkins build number and RPM Release
#PACKAGE_VERSION=0.1.0-410 # Real package
#PACKAGE_VERSION=0.1.00.1064-1 # Test package
################

if [[ $# -eq 2 ]]; then
    PACKAGE="${1}"
    PACKAGE_VERSION="${2}"
fi
: ${PACKAGE:?"Package must be set, eg. to bond.rpm"}
: ${PACKAGE_VERSION:?"Package Version must be set, eg. to 0.0.07-1"}

ORIGINAL_DIR="${PWD}"
# http://stackoverflow.com/questions/59895/can-a-bash-script-tell-what-directory-its-stored-in
COMPASS_PUPPET_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "${COMPASS_PUPPET_DIR}"

################
# TODO grab latest tag rather than master
# git clone -n https://github.com/thomsonreuters/compass_puppet-common-tools.git common-tools
# git checkout `git describe --tags`
################
# TODO ensure common-tools in compass_puppet .gitignore
[ -d common-tools ] || git clone https://github.com/thomsonreuters/compass_puppet-common-tools.git common-tools

if [[ -d common-tools ]]; then
    cd common-tools
    git pull || echo "Warning: Updating component scripts from remote repo failed...git you are probably disconnected or proxy challenged!"
    cd ..
else
    echo "Error: Could not clone component scripts repo, you are probably disconnected or proxy challenged!"
    exit 1 # No repo cached
fi

source ./common-tools/scripts/functions.sh

set -o errexit # -e is unset above

####### Upload to SAMI BIN and fail early if there is any problem
cd "${ORIGINAL_DIR}" # Return to PWD
ls "${PACKAGE}" # Force failure if package not available!
copy_list_of_files "${PACKAGE}"

cd "${COMPASS_PUPPET_DIR}"

###### Update Package Version in Hiera using Scribe
update_hiera_package_version "${APP_NAME}" "${PACKAGE_VERSION}"

####### Package and upload puppet code as new component version with CUDL
create_component_version_new "${COMPASS_COMPONENT}" "${PACKAGE_VERSION}"

cd "${ORIGINAL_DIR}" # Return to PWD

#!/bin/bash

set -o errexit # -e
set -o nounset # -u
set -o pipefail
#set -o xtrace # -x

################
# compass-create-release-puppet-master
################
# https://eegitemea.int.thomsonreuters.com/upg_platform_tools/compass_puppet/tree/master/scripts
################
# andy.washbrook@thomsonreuters.com
################
# AW Tested on Mac OSX and Linux
################

# Build Number set by User or CI

# If BUILD_NUMBER is set, assume invoked from CI, e.g Jenkins, in which case script invoked with no params

BUILD_NUMBER_PREFIX='auto'
if [[ $# -eq 1 ]]; then
    # Include branch in package name for manual pushes
    # http://stackoverflow.com/a/11958481
    BRANCH=`git rev-parse --symbolic-full-name --abbrev-ref HEAD`
#    BRANCH=`git symbolic-ref --short -q HEAD`
#    [ -z $BRANCH ] && BRANCH='detached'

    BUILD_NUMBER_PREFIX="${BRANCH}-manual"
    BUILD_NUMBER=$1
elif [[ -z $BUILD_NUMBER ]]; then
    echo "Expect to be invoked manually with numeric Build Number as the only argument, e.g. '11' by a human; or set BUILD_NUMBER='42' in environment if invoked from CI"
    exit 1
fi

set -o xtrace # -x

################

# Ensure we have latest version of this repo, including these scripts and puppet code
# Only pull if not invoked from CI
#[ -z $BUILD_NUMBER ] && git pull

#if [[ -z $BUILD_NUMBER ]]; then
#    # http://stackoverflow.com/a/11958481
#    BRANCH=`git symbolic-ref --short -q HEAD`
#    [ -z $BRANCH ] && BRANCH='detached'
#fi

################

# Compass Version pulled from utility functions

[ -f ./functions.sh ] && cd .. # Ensure we end up in top level repo dir
[ -f ./scripts/functions.sh ] && . ./scripts/functions.sh

################

COMPASS_COMPONENT=compass-puppet-master-package
COMPASS_RELEASE_VERSION="${COMPASS_VERSION}.${BUILD_NUMBER_PREFIX}-${BUILD_NUMBER}"

################

# Build the Package and update SAMI BIN puppet-package.tar.gz

PUPPET_PACKAGE="${COMPASS_COMPONENT}-${COMPASS_RELEASE_VERSION}.tar"
PUPPET_PACKAGE_URL="SAMI-BIN/Releases/Mount17/cpit_compass/${PUPPET_PACKAGE}"

TMP_DIR="zzzTmp"
mkdir -p ${TMP_DIR}
# Will ignore changes in working copy, but respect local changes?!
git archive --prefix=modules/ -o ${TMP_DIR}/${PUPPET_PACKAGE} HEAD hieradata/
tar -uvf ${TMP_DIR}/${PUPPET_PACKAGE} modules/*
################
#TODO Simon ( tar cf - modules hieradata ) |  ( cd $extractdir; tar xvf - ) )
################

# Upload to SAMI Release Share

#sami_upload ${TMP_DIR}/${PUPPET_PACKAGE}
copy_list_of_files "${TMP_DIR}/${PUPPET_PACKAGE}"

################

# Node utility to talk to CUDL via REST - will soon poll SAMI to confirm upload rather than wait 5 mins

# Update from Chris Spence Aug 22, no need for delay between, his scripts should wait for package
#sleep 300

node ./scripts/cudlRestClientAsyncPolling.js ${COMPASS_COMPONENT} ${COMPASS_RELEASE_VERSION}

#!/bin/bash

################
# Authors
################
# andy.washbrook@thomsonreuters.com
# laurent.lechelle@thomsonreuters.com
################

set +o errexit # +e
set -o nounset # -u
set -o pipefail
set +o xtrace # -x

################
# You may need to tweak the below
################
################
# Compasss release version, which will be appended with build number
COMPASS_VERSION='1.0.10' # TODO remove after all customers migrated off compass-create-release-puppet-master.sh

################
# New CPIT Robot account in SAMI which must be given read/write access to all release shares we integrate with
SAMI_USERNAME='s.sa.robot'
SAMI_PASSWORD='Manager2010'
# Amelia the Compass bot: https://github.com/tr-compass
GIT_USER_EMAIL="andy.washbrook@thomsonreuters.com"
GIT_USER_NAME=tr-compass
################
# TODO ensure in .gitignore
TMP_DIR="zzzTmp"
################

################
# As per https://thehub.thomsonreuters.com/docs/DOC-178696#networking, needs to be overridden for EMEA1
# 1) AMERS1a, 1b and 2a use: https://sami.cdt.int.thomsonreuters.com
# 2) EMEA1a use https://sami-virtual.dtc.reuint.com
################
## By default SAMI_URL does not use virtual address:
## Override as follows for SAMI Virtual in your local environnment (e.g. our emsci jenkins server):
SAMI_INTERNAL_URL=ftps://sami.cdt.int.thomsonreuters.com/Releases/Mount17/cpit_compass/
SAMI_VIRTUAL_URL=ftps://sami-virtual.dtc.reuint.com/Releases/Mount17/cpit_compass/
#SAMI_URL=ftps://sami-virtual.dtc.reuint.com/Releases/Mount17/cpit_compassfile/
#echo "SAMI_URL=${SAMI_URL:=ftps://sami.cdt.int.thomsonreuters.com/Releases/Mount17/cpit_compass/}, by default, set in EMEA1 and CPS if necessary to ${SAMI_VIRTUAL_URL}!"
function deriveSamiUrl
{
    set -o errexit # -e
    set +o nounset # +u
    set -o pipefail
    set +o xtrace # +x

    if [[ -z $SAMI_URL ]]; then
        say "Defaulting SAMI_URL to ${SAMI_INTERNAL_URL}. In EMEA1 and CPS you should override explicitely to ${SAMI_VIRTUAL_URL}"
        SAMI_URL=ftps://sami.cdt.int.thomsonreuters.com/Releases/Mount17/cpit_compass/
    else
        if ! [[ $SAMI_URL == *"/" ]]; then # ensure trailing slash if set by CI, curl needs it to upload
            SAMI_URL=${SAMI_URL}/
        fi
        if [[ $SAMI_URL == *"file/" ]]; then # ensure dedicated app specific compass files repo subdir is used
            if [[ -z $APP_NAME ]]; then
                error "If you set SAMI_URL with compassfile folder, you must provide APP_NAME"
            else
                SAMI_URL=${SAMI_URL}${APP_NAME}/
            fi
        fi
    fi

    export SAMI_URL
}
function update_hiera_package_version
#1 = name of our app, key to update in hiera
#2 = version of package
{
    if [[ $# -eq 2 ]]; then
        APP_NAME=$1
        PACKAGE_VERSION=$2
    else
        error "Expecting two args, not $*"
    fi

    set -o errexit # -e
    set -o nounset # -u
    set -o pipefail
    set +o xtrace # +x

    ###### Update Puppet Package using Scribe

    git config user.email $GIT_USER_EMAIL
    git config user.name $GIT_USER_NAME

    cd common-tools/scribe
    DEFAULT_CONFIG="../../modules/hieradata/default.yaml"
    rake hiera:compassartifact[${DEFAULT_CONFIG},${APP_NAME},${PACKAGE_VERSION},'x86_64','compass','Thomson Reuters']
    cat ${DEFAULT_CONFIG}
    cd -

    git commit -am "Compass puppet yaml updated with ${PACKAGE_VERSION}"

    git push origin master || say "Warning: Pushing updated version to remote repo failed...git you are probably disconnected or proxy challenged!"

    git tag "${PACKAGE_VERSION}"
    git push --tags
}

function create_component_version
{
    if [[ $# -eq 3 ]]; then
        COMPASS_COMPONENT=$1
        COMPASS_COMPONENT_VERSION=$2
        MANUAL_BUILD_NUMBER=$3
    else
        error "Expecting three args, not $*"
    fi

    set -o errexit # -e
    set +o nounset # +u
    set -o pipefail
    set +o xtrace # +x

    # Build Number set by User or CI

    # If BUILD_NUMBER is set, assume invoked from CI, e.g Jenkins, in which case script invoked with no params
    BUILD_NUMBER_PREFIX='auto'
    if [[ -n $MANUAL_BUILD_NUMBER ]]; then
        # Include branch in package name for manual pushes
        # http://stackoverflow.com/a/11958481
        BRANCH=`git rev-parse --symbolic-full-name --abbrev-ref HEAD`
    #    BRANCH=`git symbolic-ref --short -q HEAD`
    #    [ -z $BRANCH ] && BRANCH='detached'

        BUILD_NUMBER_PREFIX="${BRANCH}-manual"
        BUILD_NUMBER=$MANUAL_BUILD_NUMBER
    elif [[ -z $BUILD_NUMBER ]]; then
        say "Expect to be invoked manually with numeric Build Number as the only argument, e.g. '42' by a human; or set BUILD_NUMBER='42' in environment if invoked from CI"
        exit 1
    fi

    create_component_version_new "${COMPASS_COMPONENT}" "${COMPASS_COMPONENT_VERSION}.${BUILD_NUMBER_PREFIX}-${BUILD_NUMBER}"
}

function create_component_version_new
#1 = name of package
#2 = version of package
{
    if [[ $# -eq 2 ]]; then
        COMPASS_COMPONENT="${1}"
        COMPASS_RELEASE_VERSION=$2
    else
        error "Expecting two args, not $*"
    fi

    set -o nounset # -u
    set -o xtrace # -x

    ################

    # Ensure any space in package name become hypens with bash parameter expansion (tested with bash 3 osx, linux and gitbash windows)
    PUPPET_PACKAGE=`echo "${COMPASS_COMPONENT//[[:space:]]/_}-${COMPASS_RELEASE_VERSION}.tar" | tr "[:upper:]" "[:lower:]"`
    ################

    package_and_upload "${PUPPET_PACKAGE}"

    node ./common-tools/scripts/cudlRestClientAsyncPolling-Component-Stack.js "${COMPASS_COMPONENT}" ${COMPASS_RELEASE_VERSION}
}

function package_and_upload
#1 = name of package
{
    package_puppet_code "${1}"

    copy_list_of_files "${TMP_DIR}/${1}"
}

function package_puppet_code
#1 = name of package
{
    package=$1

    # Supports taring of old style full puppet hierarch with 'hieradata' and 'modules'
    # As well as newer flatter style with modules dir at top level with 'hieradata' amongst the modules inside
    # Will ignore changes in working copy, but respect local changes?!
    mkdir -p ${TMP_DIR}

    if [[ -d hieradata ]]; then # Old Style
        # Unfortunately: this will ignore changes in working copy, but respect local changes?!
        git archive --prefix=modules/ -o ${TMP_DIR}/$1 HEAD hieradata/
        tar -uvf ${TMP_DIR}/$1 modules/*
        ################
        #TODO Simon ( tar cf - modules hieradata ) |  ( cd $extractdir; tar xvf - ) )
        ################
    elif [[ -d modules ]]; then # New Style
        #http://unix.stackexchange.com/questions/38108/why-does-tar-exclude-create-an-empty-archive
        # TODO include only directories...
        tar --exclude=".*" --exclude common-tools --exclude $TMP_DIR -cvf $TMP_DIR/$1 modules
    else
        error "Error: Cannot find 'hieradata' nor 'modules' in current directoy, this is not a supported layout of puppet modules!"
    fi
}


function sami_upload
{
    [ -f $1 ] || error "invalid file path to upload to sami"

    ##AW Tested on Mac OSX and Linux
    # OSX curl -V
    #curl 7.30.0 (x86_64-apple-darwin13.0) libcurl/7.30.0 SecureTransport zlib/1.2.5
    #Protocols: dict file ftp ftps gopher http https imap imaps ldap ldaps pop3 pop3s rtsp smtp smtps telnet tftp
    #Features: AsynchDNS GSS-Negotiate IPv6 Largefile NTLM NTLM_WB SSL libz

    # We should not use continue/resume functionality for small files or from CI
    #    curl -C - -3 -k --disable-epsv --ftp-skip-pasv-ip --ftp-method singlecwd -u ${SAMI_USERNAME}:${SAMI_PASSWORD} -T $1 ftps://sami.cdt.int.thomsonreuters.com/Releases/Mount17/cpit_compass/

    curl -3 -k --disable-epsv --ftp-skip-pasv-ip --ftp-method singlecwd -u ${SAMI_USERNAME}:${SAMI_PASSWORD} -T $1 $SAMI_URL  \
        || true
}

################
# Adapted from compass_copy_generated_to_release_share.sh from RP team
################

COPY_ATTEMPTS=20
# Adding delay to SAMI upload as we had a job fail 20 times with transient errors http://ems-ci01.emea1.ciscloud:8080/job/compass-create-release-puppet-master/56/console
BACKOFF_DELAY_SECS=10

function copy_list_of_files
{
    list=$1
    count_cp=0

    set +e

    until [ $count_cp -eq $COPY_ATTEMPTS ]
    do
        say "Attempt ${count_cp}/${COPY_ATTEMPTS} to copy files."
        new_list=""
        for file in $list
        do
            say "Try ${count_cp}:  $file"
#            curl -3 -k --disable-epsv --ftp-skip-pasv-ip --ftp-method singlecwd -u foo:bar  -T $file ftps://sami.cdt.int.thomsonreuters.com/Releases/Mount17/cpit_compass/ # For negative testing
             curl -3 -k --disable-epsv --ftp-skip-pasv-ip --ftp-method singlecwd -u ${SAMI_USERNAME}:${SAMI_PASSWORD} -T $file $SAMI_URL

#            sami_upload $file ## Can't factor out as we can't handle the failure of curl within function...

            if [ $? -ne 0 ]; then
                warn "problem copying file $file [$count_cp] "
                warn "$file [$count_cp] "
                new_list="$new_list $file"
                say "WAITING $BACKOFF_DELAY_SECS seconds before trying next file"
                sleep $BACKOFF_DELAY_SECS
            else
                say "$file [$count_cp] - copied" 
            fi
        done

        if [ "$new_list" ]
        then
            count_cp=$(( $count_cp + 1 ))
            list="$new_list"
        else
            count_cp=$COPY_ATTEMPTS
        fi
    done

    set -e

    if [ "$new_list" ]
    then
        error "EXITING as the following files were not copied after $COPY_ATTEMPTS attempts: $new_list"
    fi
}

function copy_files_from_directory
{
    dir_name=$1
    list=""

    set +e

    if [ -d $dir_name ]; then
        for file in $dir_name/*.rpm
        do
            say "Try:  $file"
            curl -3 -k --disable-epsv --ftp-skip-pasv-ip --ftp-method singlecwd -u s.sa.robot:Manager2010  -T $file ftps://sami.cdt.int.thomsonreuters.com/Releases/Mount17/cpit_compass/
#            sami_upload $file

            if [ $? -ne 0 ]; then
                warn "problem copying file $file"
                warn "$file"
                list="$list $file"
            else
                say "$file - copied" 
            fi
        done
        if [ "$list" ] ; then copy_list_of_files "$list"
        fi
    fi

    set -e

}

function copy_rpms
{
    dir=$1
    dir_list="x86_64 noarch dist"
    for dir_name in $dir_list
    do
        copy_files_from_directory $dir/$dir_name
    done
}

prog=$(basename -- $0)
pid=$$
bold=`tput smso`
offbold=`tput rmso`
underline=`tput smul`
offunderline=`tput rmul`

function error
{
    set +x
    echo $bold "ERROR": "$prog: $*" $offbold
    exit 42
}
function warn
{
    set +x
    echo $underline "WARN": "$prog: $*" $offunderline
    set -x

}
function say
{
    set +x
    echo "INFO": "$prog: $*"
    set -x
}

# Run tests if functions.sh invoked directly from command line, actual usage will be sourced by another script
(
    [[ "${BASH_SOURCE[0]}" == "${0}" ]] || exit 0

    echo "------------------------------------------------------------------------"
    echo "Tests for functions.sh"
    echo "------------------------------------------------------------------------"

    function assertEquals()
    {
        msg=$1; shift
        expected=$1; shift
        actual=$1; shift
        /bin/echo -n "$msg: "
        if [ "$expected" != "$actual" ]; then
            echo "${bold}FAILED${offbold}: ${bold}EXPECTED=${underline}${expected}${offunderline}${offbold} ${bold}ACTUAL=${underline}${actual}${offunderline}${offbold}"
        else
            echo PASSED
        fi
    }
    (
        echo "test suite for deriveSamiUrl"
        set +o nounset # +u performing explicit assertions for these tests, so inappropriate
        unset SAMI_URL APP_NAME # needed if tests run with variables exported in environment
        (
            echo "basic cases with shared compass repo"
            (
                assertEquals "no SAMI_URL defined" "" $SAMI_URL
                deriveSamiUrl
                assertEquals "default SAMI_URL defined" ftps://sami.cdt.int.thomsonreuters.com/Releases/Mount17/cpit_compass/ $SAMI_URL
            )
            (
                SAMI_URL=ftps://sami-virtual.dtc.reuint.com/Releases/Mount17/cpit_compass/
                assertEquals "alternative SAMI_URL defined with trailing slash" ftps://sami-virtual.dtc.reuint.com/Releases/Mount17/cpit_compass/ $SAMI_URL
                deriveSamiUrl
                assertEquals "override respected" ftps://sami-virtual.dtc.reuint.com/Releases/Mount17/cpit_compass/ $SAMI_URL
            )
            (
                SAMI_URL=ftps://sami-virtual.dtc.reuint.com/Releases/Mount17/cpit_compass
                assertEquals "alternative SAMI_URL defined with missing trailing slash" ftps://sami-virtual.dtc.reuint.com/Releases/Mount17/cpit_compass $SAMI_URL
                deriveSamiUrl
                assertEquals "override respected with trailing slash" ftps://sami-virtual.dtc.reuint.com/Releases/Mount17/cpit_compass/ $SAMI_URL
            )
        )
        (
            echo "cases with dedicated subdir for 'snark' app files"
            APP_NAME=snark
    # not driven by app_name but by sami_url
    #        (
    #            echo "APP_NAME defined, but not SAMI_URL"
    #            assertEquals "APP_NAME defined" snark $APP_NAME
    #            assertEquals "no SAMI_URL defined" "" $SAMI_URL
    #            deriveSamiUrl
    #            assertEquals "SAMI_URL defined with app subdir" ftps://sami.cdt.int.thomsonreuters.com/Releases/Mount17/cpit_compassfile/snark/ $SAMI_URL
    #        )
            (
                echo "APP_NAME defined and SAMI_URL to compassfile"
                assertEquals "APP_NAME defined" snark $APP_NAME
                SAMI_URL=ftps://sami.cdt.int.thomsonreuters.com/Releases/Mount17/cpit_compassfile/
                assertEquals "SAMI_URL defined" ftps://sami.cdt.int.thomsonreuters.com/Releases/Mount17/cpit_compassfile/ $SAMI_URL
                deriveSamiUrl
                assertEquals "SAMI_URL defined with app subdir" ftps://sami.cdt.int.thomsonreuters.com/Releases/Mount17/cpit_compassfile/snark/ $SAMI_URL
            )
            (
                echo "APP_NAME defined and alternate SAMI_URL to compassfile with missing trailing slash"
                assertEquals "APP_NAME defined" snark $APP_NAME
                SAMI_URL=ftps://sami-virtual.dtc.reuint.com/Releases/Mount17/cpit_compassfile
                assertEquals "alternative SAMI_URL defined" ftps://sami-virtual.dtc.reuint.com/Releases/Mount17/cpit_compassfile $SAMI_URL
                deriveSamiUrl
                assertEquals "SAMI_URL defined with app subdir" ftps://sami-virtual.dtc.reuint.com/Releases/Mount17/cpit_compassfile/snark/ $SAMI_URL
            )
            # TODO test nonzero exit case when APP_NAME not set...
        )
    )

)

# TODO invoke as if/else??
[[ "${BASH_SOURCE[0]}" == "${0}" ]] || {
    deriveSamiUrl
}












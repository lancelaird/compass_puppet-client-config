#!/bin/bash

prog=$(basename $0)
pid=$$

function error
{
    logger -t "compass-apps[$pid]" -p ERROR "$prog: $*"
    logger -t "compass-apps[$pid]" -p ERROR "$prog: exiting with error"
    exit 42
}

function warn
{
    logger -t "compass-apps[$pid]" -p WARN "$prog: $*"
}

function say
{
    logger -t "compass-apps[$pid]" -p INFO "$prog: $*"
}

function run
{
    say $*
    $*
    return $?
}

function assertrun
{
    say $*
    $*
    ret=$?
    if [[ $ret != 0 ]]; then
        error "your command $* failed with exit code $ret."
    fi
}

say "Start $*"

##AW Moved to Nolio flow so we can include the wrapper script within puppet tarball
##   Also removed knowledge of puppet location of puppet code
#
#if [[ $# -ne 1 ]]; then
#    error "installer data missing"
#else
#    tgz_file=$1
#    if [[ ! -f $tgz_file ]]; then
#        error "installer data is not a file"
#    elif [[ $(file $tgz_file | grep gzip) == "" ]]; then
#        error "installer data is not a GZIP file"
#    fi
#fi
#
##assertrun mkdir -p /eikon/puppet/compass
##assertrun tar -xzf $tgz_file -C /eikon/puppet/compass
##assertrun bash /eikon/puppet/compass/run
assertrun bash ./run
assertrun god restart httpd
#assertrun service cudl restart

say "Completed with success"
exit 0

#!/bin/bash

set -o errexit # -e
set -o nounset # -u
set -o pipefail
set -o xtrace # -x

################
# compass-sami-upload
################
# https://eegitemea.int.thomsonreuters.com/upg_platform_tools/compass_puppet/tree/master/scripts
################
# andy.washbrook@thomsonreuters.com
################
# AW Tested on Mac OSX and Linux
################

# Invoke with file or files you want uploading reliably to sami
if [[ $# -eq 0 ]]; then
    echo "Expect to be invoked manually with file or files"
    exit 1
fi

################

# Compass Version pulled from utility functions

[ -f ./functions.sh ] && cd .. # Ensure we end up in top level repo dir
[ -f ./scripts/functions.sh ] && . ./scripts/functions.sh
[ -f ./common-tools/scripts/functions.sh ] && . ./common-tools/scripts/functions.sh

# Upload to SAMI Release Share
copy_list_of_files $*

#!/bin/bash

# AW - These are SAMI integration tools from other teams...

################
# compass_copy_generated_to_release_share
################
# Eikonmon team:
# From http://ems-ci01.emea1.ciscloud:8080/job/ems-build-endpoint-standalone-installer-with-puppet/
################

SAMI_URL=ftps://sami-virtual.dtc.reuint.com/Releases/Mount17/cpit_eikonmon/${PACKAGE_SAMI_TARGET}/

echo "----------------------------------------------------------------"
echo "Uploading artifacts to sami-bin... in $SAMI_URL"
echo
for f in *.zip *.md5; do
  echo "----------------------------------------------------------------"
  echo "uploading ${f}..."
  curl --upload-file ${f} \
       --user s.sa.robot:Manager2010 \
       --retry 20 \
       --retry-delay 10 \
       --ftp-method singlecwd \
       --insecure \
       --sslv3 \
       ${SAMI_URL}
  ex=$?
  if [ $ex -ne 0 ]; then
    exit $ex
  fi
done

################
# compass_copy_generated_to_release_share
################
###############
# Reverse Proxy team: olga.soika@thomsonreuters.com
################

if [[ $# -lt 1 ]]; then
    echo "need argument like 1.0.0/builddir-r1234"
    exit 1
fi

COPY_ATTEMPTS=20
BUILDDIR=$1
shift

COPYLOG=$BUILDDIR/copy.log

#if [[ ! -f $BUILDLOG ]]; then
#    echo "$BUILDLOG must exists"
#    exit 1
#fi

function copy_list_of_files
{
    rpm_list=$1
    count_cp=0

    until [ $count_cp -eq $COPY_ATTEMPTS ] 
    do
        echo "Try[ndex:$count_cp] to copy files." >>$COPYLOG
        new_rpm_list=""
        for rpm_file in $rpm_list 
        do 
            echo "Try[$count_cp]:  $rpm_file"
            curl -3 -k --disable-epsv --ftp-skip-pasv-ip --ftp-method singlecwd -u s.sa.robot:Manager2010  -T $rpm_file ftps://sami.cdt.int.thomsonreuters.com/Releases/Mount17/cpit_compass/
            if [ $? -ne 0 ]; then
                echo "ERROR  copying file $rpm_file [$count_cp] " >> $COPYLOG
                echo "ERROR :  $rpm_file [$count_cp] "
                new_rpm_list="$new_rpm_list $rpm_file"
            else
                echo "$rpm_file [$count_cp] - copied" >> $COPYLOG
            fi
        done

        if [ "$new_rpm_list" ] 
        then
            count_cp=$(( $count_cp + 1 ))
            rpm_list="$new_rpm_list"
        else
            count_cp=$COPY_ATTEMPTS
        fi
    done

    if [ "$new_rpm_list" ]
    then
        echo "There were $COPY_ATTEMPTS attempts to copy files." >>$COPYLOG
        echo "The following files haven't been copied: $new_rpm_list" >>$COPYLOG
    fi
}

function copy_rpms_from_directory
{
    dir_name=$1
    rpm_list=""
    if [ -d $dir_name ]; then
        for rpm_file in $dir_name/*.rpm
        do
            echo "Try:  $rpm_file"
            curl -3 -k --disable-epsv --ftp-skip-pasv-ip --ftp-method singlecwd -u s.sa.robot:Manager2010  -T $rpm_file ftps://sami.cdt.int.thomsonreuters.com/Releases/Mount17/cpit_compass/
            if [ $? -ne 0 ]; then
                echo "ERROR copying file $rpm_file" >> $COPYLOG
                echo "ERROR:  $rpm_file"
                rpm_list="$rpm_list $rpm_file"
            else
                echo "$rpm_file - copied" >> $COPYLOG
            fi
        done
        if [ "$rpm_list" ] ; then copy_list_of_files "$rpm_list"
        fi
    fi
}

function copy_rpms
{
    rpm_dir=$1
    dir_list="x86_64 noarch dist"
    for dir_name in $dir_list
    do
        copy_rpms_from_directory $rpm_dir/$dir_name
    done
}

echo "*********************" >> $COPYLOG
echo "*** Start copying ***" >> $COPYLOG
copy_rpms $BUILDDIR/reverseproxy/rpmbuilds/RPMS
copy_rpms  "$BUILDDIR/reverseproxy/autoupdate"
copy_rpms $BUILDDIR/config/rpmbuilds/RPMS

echo " done"

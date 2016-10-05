#!/bin/bash

# In K8S, ceph-disk prepare sometimes fails and can prevent the OSD from booting up. This script is meant to be ran
# as an pod init-container to prepare the disk first so the main pod will just have to activate. This skips if the
# device is already configured as an OSD device.

if [[ "$OSD_DEVICE" == "" ]]; then
    echo "DEVICE should be specified."
    exit 1
fi

if [[ "$(parted --script ${OSD_DEVICE} print | egrep '^ 1.*ceph data')" ]]; then
    echo "DEVICE is already an OSD. Will not zap and prepare."
    exit 0
fi

echo "========== Preparing $OSD_DEVICE =========="
success=false
while [[ "$success" == "false" ]]; do
    echo "=====> Zapping Device...
    sgdisk -Z $OSD_DEVICE
    echo "=====> Preparing Device...
    ceph-disk prepare $OSD_DEVICE
    if [[ "$?" == "0" ]]; then
        echo "=====> SUCCESS!!!"
        success=true
    fi
    sleep 1
done

#!/bin/bash
#
# Find out which VMware backups are moved in which fashion (san/nbd/nbssl)
#
# Author: Andreas Lindh <andreas@superblock.se>
#

VMWWARE_POLICIES=""
function find_vmware_policies {
    for policy in `bppllist`; do
        policy_type=`bpplinfo ${policy} -U | awk '/^Policy Type/ {print $3}'`
        if [ "${policy_type}" == "VMware" ]; then
            VMWARE_POLICIES="${VMWARE_POLICIES} ${policy}"
        fi
    done
}

function find_jobids {
    grepline=""
    for policy in $VMWARE_POLICIES; do
        if [ ! -z "${grepline}" ]; then
            grepline="${grepline}|${policy}"
        else
            grepline="(${grepline}${policy}"
        fi
    done
    grepline="${grepline})"

    jobs=`bperror -backstat -l -hoursago 24 | grep -E "${grepline}" | awk '{print $6}'`
}


find_vmware_policies
find_jobids

for jobid in $jobs; do
    client=`bpdbjobs -report -most_columns -jobid ${jobid} | awk -F',' '{print $7}'`
    transport_type=`bpdbjobs -report -all_columns -jobid ${jobid} | grep -Po 'Transport Type = (.*?)\,' | awk '{print $4}' | tr -d ','`
    if [ ! -z "${transport_type}" ]; then
        echo "JOBID: ${jobid}  CLIENT: ${client} TRANSPORT_TYPE: ${transport_type}"
    fi
done
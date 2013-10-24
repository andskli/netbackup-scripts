#!/bin/bash
#
# Add mediasrv to client.
#
# Author: Andreas Skarmutsos Lindh <andreas.skarmutsoslindh@gmail.com>
#
# TODO: Allow multiple media servers added in one cmd to minimize client
# communications
#

ME="$(basename "$0")"

BPGETCONFIGBIN=/usr/openv/netbackup/bin/admincmd/bpgetconfig
BPSETCONFIGBIN=/usr/openv/netbackup/bin/admincmd/bpsetconfig
BPPLLISTBIN=/usr/openv/netbackup/bin/admincmd/bppllist

function usage {
    echo "Usage: $ME [-c <client>/-f <path>/-p <policy>] -m <mediasrv>"
    echo -e "At least ONE of the following:"
    echo -e "\t-p <policy>\tspecifies all clients in that policy"
    echo -e "\t-c <client>\tname of client"
    echo -e "\t-f <path>\tpath to list of clients to be updated"
    echo -e "REQUIRED:\n\t-m <mediasrv>\tmedia server to add"
    exit 1
}

while getopts "c:f:m:p:" o; do
    case "${o}" in
        c)
            CLIENT=${OPTARG}
            ;;
        f)
            CLIENTLIST=${OPTARG}
            ;;
        m)
            MEDIASRV=${OPTARG}
            ;;
        p)
            POLICY=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))


function gen_mediasrvlist {
    SERVERS=`$BPGETCONFIGBIN -M $1 SERVER|awk -v MS=$MEDIASRV '$1=="SERVER" {print $1"="$3}
        END {print "SERVER="MS}'`
    echo $SERVERS
}

function new_mediasrvlist {
    for line in `gen_mediasrvlist $1`; do
        srv=$(echo $line|cut -d'=' -f2)
        echo "SERVER = $srv"
    done
}

if [ ! -z "$CLIENT" ]; then
    echo "Updating $CLIENT with new list"
    new_mediasrvlist $CLIENT | $BPSETCONFIGBIN -h $CLIENT 2>&1 >/dev/null
fi

if [ ! -z "$CLIENTLIST" ]; then
    if [ ! -f $CLIENTLIST ]; then
        echo "$CLIENTLIST not file"
        exit 1
    fi
    for client in `cat $CLIENTLIST`; do
        echo "Updating $client with new list"
        new_mediasrvlist $client | $BPSETCONFIGBIN -h $client 2>&1 >/dev/null
    done
fi

if [ ! -z "$POLICY" ]; then
    CLIENTS=`$BPPLLISTBIN $POLICY -l|grep ^CLIENT|awk '{print $2}'`
    for client in $CLIENTS; do
        echo "Updating $client with new list"
        new_mediasrvlist $client | $BPSETCONFIGBIN -h $client 2>&1 >/dev/null
    done
fi

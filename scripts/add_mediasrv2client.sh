#!/bin/bash
#
# Add mediasrv to client.
#
# Author: Andreas Skarmutsos Lindh <andreas.skarmutsoslindh@gmail.com>
#

ME="$(basename "$0")"

BPGETCONFIGBIN=/usr/openv/netbackup/bin/admincmd/bpgetconfig
BPSETCONFIGBIN=/usr/openv/netbackup/bin/admincmd/bpsetconfig

function usage {
    echo "Usage: $ME [-c <client>/-f <path to file containing list of clients>] -m <mediasrv>"
    exit 1
}

while getopts "c:f:m:" o; do
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


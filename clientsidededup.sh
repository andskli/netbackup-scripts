#!/bin/bash
#
# Change client side dedup setting for one or more clients, instead of
# using Host Properties>Master Server in GUI. Suitable when multiple
# clients needs to update/add this setting at once.
#
# Author: Andreas Skarmutsos Lindh <andreas.skarmutsoslindh@gmail.com>
#

ME="$(basename "$0")"

BPPLLISTBIN=/usr/openv/netbackup/bin/admincmd/bppllist
BPCLIENTBIN=/usr/openv/netbackup/bin/admincmd/bpclient

function usage {
    echo "Usage: $ME [-c <client>/-f <path>/-p <policy>] -s <prefclient/clientside/mediasrv>"
    echo -e "At least ONE of the following:"
    echo -e "\t-p <policy>\tspecifies all clients in that policy"
    echo -e "\t-c <client>\tname of client"
    echo -e "\t-f <path>\tpath to list of clients to be updated"
    echo -e "REQUIRED:"
    echo -e "\t-s\tSpecify prefclient to prefer client side dedup, clientside for"
    echo -e "\t\tclient side deuplication or mediasrv for media server dedup."
    exit 1
}

while getopts "c:f:p:s:" o; do
    case "${o}" in
        c)
            CLIENT=${OPTARG}
            ;;
        f)
            CLIENTLIST=${OPTARG}
            ;;
        p)
            POLICY=${OPTARG}
            ;;
        s)
            SETTING=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

# Check if client already exists in client attributes on master and#
# set behaviour of update function accordingly.
function set_needsaction {
    $BPCLIENTBIN -client $1 -l 2>&1 >/dev/null
    case "${?}" in
        0)
            needsaction="-update"
            ;;
        227)
            needsaction="-add"
            ;;
        *)
            needsaction="-add"
            ;;
    esac
}

# Set dedup setting for client
function set_clientsidededup {
    c=$1
    s=$2
    case "${s}" in
        mediasrv)
            dedupval=0
            ;;
        prefclient)
            dedupval=1
            ;;
        clientside)
            dedupval=2
            ;;
        *)
            usage
            ;;
    esac
    set_needsaction $c
    $BPCLIENTBIN -client $c $needsaction -client_direct $dedupval
}

function get_clientsidededup {
    c=$1
    cval=`$BPCLIENTBIN -client $c -l|sed -n '/\([0-9] \)/p'|awk '{print $12}'`
    case "${cval}" in
        0)
            # Deduplicate on the media server or move data via media server
            ;;
        1)
            # Prefer to use client-side deduplication or prefer to move data direct to storage
            ;;
        2)
            # Always use client-side deduplication or always move data direct to storage
            ;;
    esac
}

if [ -z "$SETTING" ]; then
    usage
fi

if [ ! -z "$CLIENT" ]; then
    echo "Updating $CLIENT with setting $SETTING"
    set_clientsidededup $CLIENT $SETTING  2>&1 >/dev/null
fi

if [ ! -z "$CLIENTLIST" ]; then
    if [ ! -f $CLIENTLIST ]; then
        echo "$CLIENTLIST not file"
        exit 1
    fi
    for client in `cat $CLIENTLIST`; do
        echo "Updating $client with setting $SETTING"
        set_clientsidededup $client $SETTING 2>&1 >/dev/null
    done
fi

if [ ! -z "$POLICY" ]; then
    CLIENTS=`$BPPLLISTBIN $POLICY -l|grep ^CLIENT|awk '{print $2}'`
    for client in $CLIENTS; do
        echo "Updating $client with setting $SETTING"
        set_clientsidededup $client $SETTING 2>&1 >/dev/null
    done
fi


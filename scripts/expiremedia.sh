#!/bin/bash
#
# Forcibly expire list of tapes from file, separated by newline
#
# Author: Andreas Skarmutsos Lindh <andreas.skarmutsoslindh@gmail.com>
#

ME="$(basename "$0")"

BPEXPDATE=/usr/openv/netbackup/bin/admincmd/bpexpdate

function usage {
    echo -e "Usage: $ME -f <path to file containing list of media> [-X]"
    echo -e "\t\tUse -X to forcibly expire media"
    exit 1
}
DOIT=0
while getopts "f:X:" o; do
    case "${o}" in
        f)
            FILE=${OPTARG}
            ;;
        X)
            DOIT=1
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

function expiry_tape {
    $BPEXPDATE -m $1 -d 0 -force
}

# Check for $FILE, if not file die.
[[ -f $FILE ]] || usage

for tape in `cat $FILE`; do
    if [ $DOIT -gt 0 ]; then
        echo "Expiring $tape"
        $BPEXPDATE -m $tape -d 0 -force
    else
        echo "Do you want to expire the following media?"
        echo -e "\t$tape"
        echo "Enter (yes/no):"
        read answer
        case "$answer" in
            yes)
                echo "You choose to expire media $tape"
                $BPEXPDATE -m $tape -d 0 -force
                ;;
            no)
                echo "Not expiring $tape"
                ;;
        esac
    fi
done



#!/bin/bash
#
# Expire list of tapes from a file containing a list of media id's
# separated by newline.
#
# Author: Andreas Skarmutsos Lindh <andreas.skarmutsoslindh@gmail.com>
#

ME="$(basename "$0")"

BPEXPDATEBIN=/usr/openv/netbackup/bin/admincmd/bpexpdate

function usage {
    echo -e "Usage: $ME -f <path to file containing list of media> [-X]"
    echo -e "\t\t-X\tForce expiration without questions"
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

# Check for $FILE, if not file die.
[[ -f $FILE ]] || usage
cat $FILE | while read tape; do
    if [ $DOIT -gt 0 ]; then
        echo "Expiring $tape"
        $BPEXPDATEBIN -m $tape -d 0 -force
    else
        echo "Do you want to expire the following media?"
        echo -e "\t$tape"
        echo "Enter (yes/no):"
        read answer
        case "$answer" in
            y|yes)
                echo "Will now expire media $tape"
                $BPEXPDATEBIN -m $tape -d 0 -force
                ;;
            n|no)
                echo "Not expiring $tape"
                ;;
        esac
    fi
done

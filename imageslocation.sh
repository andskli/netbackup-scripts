#!/bin/bash

PROGNAME=$0
PROGPATH=`echo $0 | sed -e 's,[\\/][^\\/][^\\/]*$,,'`


usage() { echo "Usage: $PROGNAME [-x] -f <file>" 1>&2; exit 1; }
while getopts "f:x" o; do
    case "${o}" in
        x)
            EXCEL="yes"
            ;;
        f)
            FILE=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

if [ -z "${FILE}" ]; then
    usage
fi


BPIMAGELISTBIN=/usr/openv/netbackup/bin/admincmd/bpimagelist

for image in `cat $FILE`; do
    #  bpimagelist -l -backupid BACKUPID_1392325224|awk '{print $9}'|egrep '^[A-z]{2,3}[0-9]{3,4}.*'
    MEDIA=""
    #ON_MEDIA=`$BPIMAGELISTBIN -l -backupid $image | awk '{print $9}' | egrep '^[A-z]{2,3}[0-9]{3,4}$' | sort -u`
    ON_MEDIA=`$BPIMAGELISTBIN -l -backupid $image | grep ^FRAG | awk '{print $9}' | sort -u`
    if [ "${#ON_MEDIA}" = "0" ]; then
        echo "$image,EXPIRED?"
    else
        for m in $ON_MEDIA; do
            if [ "$EXCEL"x = "yes"x ]; then
                MEDIA="$MEDIA,$m"
            else
                MEDIA="$MEDIA $m"
            fi
        done
        MEDIA=`echo $MEDIA | sed -r 's/^(\,)//'`
        if [ "$EXCEL"x = "yes"x ]; then
            echo "$image,$MEDIA"
        else
            echo "Image $image is on media.. $MEDIA"
        fi
    fi
done

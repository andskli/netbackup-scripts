#!/bin/bash

PROGNAME=$0
PROGPATH=`echo $0 | sed -e 's,[\\/][^\\/][^\\/]*$,,'`

IMAGELISTFILE=$1

BPIMAGELISTBIN=/usr/openv/netbackup/bin/admincmd/bpimagelist

for image in `cat $IMAGELISTFILE`; do
        #  bpimagelist -l -backupid tris011.hm.com_1392325224|awk '{print $9}'|egrep '^[A-z]{2,3}[0-9]{3,4}.*'
        MEDIA=""
        ON_MEDIA=`$BPIMAGELISTBIN -l -backupid $image | awk '{print $9}' | egrep '^[A-z]{2,3}[0-9]{3,4}$' | sort -u`
        for m in $ON_MEDIA; do
                MEDIA="$MEDIA $m"
        done
        if [ "${#ON_MEDIA}" -gt "1" ]; then
                echo "Image $image is on tape(s).. $MEDIA"
        else
                echo "Image $image is _NOT_ on tape!"
        fi
done

scripts
=======
_DISCLAIMER:_ These scripts are _not_ quality assured and properly tested. Please only use them if you know what you're in to. I do _not_ take responsibility for your potentially broken backup environment.

# clientsidededup.sh
Complements the script shipped with NetBackup by adding more flexibility in client selection and more options.

    Usage: clientsidededup.sh [-c <client>/-f <path>/-p <policy>] -s <prefclient/clientside/mediasrv>
    At least ONE of the following:
        -p <policy>     specifies all clients in that policy
        -c <client>     name of client
        -f <path>       path to list of clients to be updated
    REQUIRED:
        -s      Specify prefclient to prefer client side dedup, clientside for
                client side deuplication or mediasrv for media server dedup.

# expiremedia.sh
Simple script for expiring media

# excludelistmgr.pl
Manage excludelists for multiple NetBackup clients. Script tested on Linux & Windows (running VRTSPerl). Operations only performed on Windows clients.. (for unix/linux we should use puppet or similar to manage bp.conf, right? :))

    Usage: excludelistmgr.pl [options]

    Mandatory:
            -a <get/add/del/set>    Action to perform
    One of the following:
            -c <client>             Client which will be affected
            -p <policy>             Policy to work on
    One of the following:
            -e <exclude string>             String to exclude
            -f <path>               file with excludes, one on each line

            -d              Debug.


# mediasrvmgr.pl
Manage media servers for clients (policy/single client), add/del using specific media server or file containing media servers wanted.

Usage: mediasrvmgr.pl [options]

    Mandatory:
            -a <get/add/del>        Action to perform
    One of the following:
            -c <client>             Client which will be affected
            -p <policy>             Policy to work on
    One of the following:
            -m <media server>               name of media server
            -f <path>               file with media servers listed

            -d              Debug.


# backupsearch.pl
Search entire policy for clients with a backup between date X and Y containing a specific string. Use forward
slashes for search in windows like manner (see example).
Example:

    ./backupsearch.pl -t 13 -s 11/01/2013 -e 11/27/2013 -p <policy_name> -f "/C/Temp"




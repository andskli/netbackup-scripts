netbackup-scripts
=======
_DISCLAIMER:_ These scripts are _not_ quality assured and properly tested. Please only use them if you know what you're in to. I do _not_ take responsibility for your potentially broken backup environment.

### windows_wrapper.bat
The windows_wrapper.bat script is included to provide a simpler way to run the scripts from windows command prompt.

By default the perl binary points to, change it to where perl is installed (>5.8):

    set perlbin="C:\Program Files\VERITAS\VRTSPerl\bin\perl.exe"

### backupsearch.pl
Search entire policy for clients with a backup between date X and Y containing a specific string. Use forward
slashes for search in windows like manner (see example).
Example:

    ./backupsearch.pl -t 13 -s 11/01/2013 -e 11/27/2013 -p <policy_name> -f "/C/Temp"

### clientsidededupmgr.pl
Manage client side dedup settings for mutliple clients at once instead of using Host Properties->Master Server, which is a total buzzkill when changing settings for a big bunch of clients at once.

    $ perl clientsidededupmgr.pl -h
    Usage: clientsidededupmgr.pl [options]

    One of:
        -p <policy>     Name of policy containing clients to update
        -c <client>     Name of client to update
    Mandatory:
        -s <action>     Select one of preferclient/clientside/mediaserver/LIST
    Optional:
        -d <level>      Debug.

### excludelistmgr.pl
Manage excludelists for multiple NetBackup clients. Script tested on Linux & Windows (running VRTSPerl). Operations only performed on Windows clients.. (for unix/linux we should use puppet or similar to manage bp.conf, right? :))

    $ perl excludelistmgr.pl -h
    Usage: excludelistmgr.pl [options]

    Mandatory:
        -a <action>     Specify get/add/del/set to perform that action on the client set
    One of the following:
        -c <client>     Client which will be affected
        -p <policy>     Policy to work on
    One of the following:
        -e <string>     String to exclude. I.e. "C:\Temp\*"
        -f <path>       file with excludes, one on each line
    Optional:
        -d <level>      Debug.

### expiremedia.pl
Simple script for expiring media

    $ perl expiremedia.pl -h
    Usage: expiremedia.pl [options]

    Mandatory:
        -f <path>       file containing list of media ID's to be expired
        -X              force expiration without questions asked

        -d              Debug.

### mediasrvmgr.pl
Manage media servers for clients (policy/single client), add/del using specific media server or file containing media servers wanted.

    $ perl mediasrvmgr.pl -h
    Usage: mediasrvmgr.pl [options]

    Mandatory:
        -a <action>     Action to perform. Action can be any of add/get/del
    One of the following:
        -c <client>     Client which will be affected
        -p <policy>     Policy to work on
    One of the following:
        -m <server>     name of media server
        -f <path>       file with media servers listed 
    Optional:
        -d <level>      Debug.

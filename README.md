netbackup-scripts
=======
DISCLAIMER
These scripts are ___not___ quality assured and properly tested. Please only use them if you know what you're doing. I do ___not___ take responsibility for your potentially broken backup environment.

windows_wrapper.bat
-------
The ``windows_wrapper.bat`` batch file is included to provide a simpler way to run the scripts from windows command prompt.
Call it from a command prompt and use the name of the script you want to run as the first argument (i.e. ``windows_wrapper.bath excludelistmgr.pl -h``

By default the perl binary points to ``set perlbin="C:\Program Files\VERITAS\VRTSPerl\bin\perl.exe"``, because that's where Perl is installed on NetBackup windows servers usually. Change it to where perl is installed (>5.8) if that is a different location.

backupsearch.pl
------
Search entire policy for clients with a backup between date X and Y containing a specific string. Use forward
slashes and skip colon in drive path for search in windows like manner (see example).
Example ``./backupsearch.pl -t 13 -s 11/01/2013 -e 11/27/2013 -p <policy_name> -f "/C/Temp"``

    $ perl backupsearch.pl -h

    Usage: backupsearch.pl [options]

    Options:
        -f | --find <string>        : Search for string, note that you need to use /C/temp to search for C:/Temp
        -s | --start <mm/dd/yyyy>   : Start date
        -e | --end <mm/dd/yyyy>     : End date
        -p | --policy <name>        : Policy to search
        -t | --type N               : Policy type (use 13 for windows!!)
                                        0   Standard
                                        1   Proxy
                                        2   Non-Standard
                                        3   Apollo-wbak
                                        4   Oracle
                                        5   Any policy type
                                        6   Informix-On-BAR
                                        7   Sybase
                                        8   MS-Sharepoint
                                        10  NetWare
                                        11  DataTools-SQL-BackTrack
                                        12  Auspex-FastBackup
                                        13  MS-Windows-NT
                                        14  OS/2
                                        15  MS-SQL-Server
                                        16  MS-Exchange-Server
                                        17  SAP
                                        18  DB2
                                        19  NDMP
                                        20  FlashBackup
                                        21  Split-Mirror
                                        22  AFS
                                        24  DataStore
                                        25  Lotus-Notes
                                        28  MPE/iX
                                        29  FlashBackup-Windows
                                        30  Vault
                                        31  BE-MS-SQL-Server
                                        32  BE-MS-Exchange-Server
                                        34  Disk Staging
                                        35  NBU-Catalog
        -h | --help                 : show this help

clientsidededupmgr.pl
------
Manage client side dedup settings for mutliple clients at once instead of using Host Properties->Master Server, which is a total buzzkill when changing settings for a big bunch of clients at once.

    $ perl clientsidededupmgr.pl -h

    Usage: clientsidededupmgr.pl [options]

    Options:
        -p | --policy <name>        : Policy with clients to update
        -c | --client <name>        : Client to update
        -s | --set <setting>        : Set client side dedup setting to one of the
                                following: preferclient, clientside, mediaserver, LIST
        -h | --help                 : Show this help

excludelistmgr.pl
------
Manage excludelists for multiple NetBackup clients. Operations only performed on Windows clients.. (for unix/linux we should use puppet or similar to manage excludes and media servers with bp.conf, right? :-))

    $ perl excludelistmgr.pl -h

    Usage: excludelistmgr.pl [options]

    Mandatory:
        -a | --action <action>      : Specify get/add/del/set for the set of clients
        -p | --policy <name>        : Policy to work with
        -c | --client <name>        : Client to work with
        -e | --exclude <string>     : String to exclude. I.e. "C:\Temp\*"
        -f | --file <path>          : Path to file containing exclude list (newline separation)
        -h | --help                 : display this output


expiremedia.pl
------
Simple script for expiring media.

    $ perl expiremedia.pl -h

    Usage: expiremedia.pl [options]

    Options:

        -f | --file <path>      : File containing list of media ID's to be expired
        -X | --force            : Force expiration without questions asked

mediasrvmgr.pl
------
Manage media servers for clients (set on policy/single client level), add/del using specific media server or file containing media servers wanted.

    $ perl mediasrvmgr.pl -h

    Usage: mediasrvmgr.pl [options]

    Options:
        -a | --action <action>  : Action to perform, may be any of add/get/del
        -c | --client <name>    : Client that will be affected
        -p | --policy <name>    : Policy with clients that will be affected
        -m | --mediasrv <name>  : Name of media server to add/remove from clients
        -f | --file <path>      : Path to file with media servers which to add/remove
                                from clients
        -h | --help             : display this output

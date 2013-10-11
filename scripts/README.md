scripts
=======

# add_mediasrv2client.sh
Complements the binary that is shipped with NetBackup (add_media_server_on_clients), which is not properly documentet nor flexible in the way that it adds _all_ available media servers to the clients specified.

This script however adds a single media server (for now) onto a selection of clients. The selection is made either by specifying a single client, selecting all clients in a policy, or all clients in a file (separated by newline)

Example:
    Usage: add_mediasrv2client.sh [-c <client>/-f <path>/-p <policy>] -m <mediasrv>
    At least ONE of the following:
        -p <policy>     specifies all clients in that policy
        -c <client>     name of client
        -f <path>       path to list of clients to be updated
    REQUIRED:
        -m <mediasrv>   media server to add


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
simple script for expiring media (untested)

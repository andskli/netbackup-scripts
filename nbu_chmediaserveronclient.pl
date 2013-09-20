#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Std;
use Data::Dumper;

local $ENV{PATH} = "$ENV{PATH}:/usr/openv/netbackup/bin";
local $ENV{PATH} = "$ENV{PATH}:/usr/openv/netbackup/bin/admincmd";
local $ENV{PATH} = "$ENV{PATH}:/usr/openv/volmgr/bin";

my %opt;
getopts('a:m:c:h:?:d', \%opt) || output_usage();
output_usage() if $opt{'h'};

sub output_usage
{
    my $usage = "Usage: $0 [options]

Options:

    -a <add/del/show>        Action to perform, add/del supported.
    -c <client>         Client name to perform the action on.
    -m <mediasrv>       Mediaserver to add/remove.
    -d                  Debug.\n\n";

    die $usage;
}

if ($opt{'d'}) {
    print Dumper(\%opt);
}

if ((!$opt{'a'}) or
    (!$opt{'m'}) or
    (!$opt{'c'}))
{
    output_usage();
}


sub bpgetconfig
{
    my $client = @_;
    print STDERR ("> $client");
    system("bpgetconfig -s ", $client, " -A -L");
}

sub main
{
    my $client = $opt{'c'};
    my $mediasrv = $opt{'m'};
    my $action = $opt{'a'};

    bpgetconfig($client);
}
main()

#!/usr/bin/perl
#
# Author: Andreas Skarmutsos Lindh <andreas.skarmutsoslindh@gmail.com>
#
# Purpose of this script is to handle add/remove of media servers on clients.
#

use strict;
use warnings;
use Getopt::Std;
use Data::Dumper;

local $ENV{PATH} = "$ENV{PATH}:/usr/openv/netbackup/bin";
local $ENV{PATH} = "$ENV{PATH}:/usr/openv/netbackup/bin/admincmd";
local $ENV{PATH} = "$ENV{PATH}:/usr/openv/volmgr/bin";

my $bpgetconfigbin = "/usr/openv/netbackup/bin/admincmd/bpgetconfig";
my $bpsetconfigbin = "/usr/openv/netbackup/bin/admincmd/bpsetconfig";
my $addmediasrvbin = "/usr/openv/netbackup/bin/add_media_server_on_clients";

my %opt;
getopts('h?da:m:c:', \%opt) || output_usage();
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

sub parse_bpconf
{
    $in = $_;
    while ()
    {
        chomp;
        s/#.*//;
        s/^\s+//;
        s/\s+$//;
        next unless length;
        my ($key, $val) = split(/\s*=\s*/, $_, 2);
        $config{$key} = $val;
    }
    print Dumper(\%config);
}

sub bpgetconfig
{
    my $client = $_[0];
    my $output = `$bpgetconfigbin -M $client`;
    return $output;
}

sub main
{
    my $client = $opt{'c'};
    my $mediasrv = $opt{'m'};
    my $action = $opt{'a'};

    #&bpgetconfig($client, $action);
    if ($action eq "add")
    {
        &add_media_srv($client, $mediasrv);
    }
    elsif ($action eq "show")
    {
        my $c = &bpgetconfig($client);
        #print "DEBUG: $c\n";
        &parse_bpconf($c);
    }
}
main()

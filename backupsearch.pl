#!/usr/bin/perl
# Search NetBackup backups for specific file om a policy.
# Handy if looking for old backup files where clients have changed
#
# Author: Andreas Skarmutsos Lindh <andreas.skarmutsoslindh@gmail.com>
#
# References:
#   Backup type index: http://www.symantec.com/business/support/index?page=content&id=TECH27299
#
# TODO:
#   - Improve help with current policy type output
#   - Search specific client
#

#use strict;
use warnings;
use Getopt::Long;
use Data::Dumper;

# Check OS and adjust netbackup executable binaries accordingly
my $operating_system = $^O;
if ($operating_system eq "MSWin32")
{
    my $installpath = "\"C:\\Program Files\\Veritas\\NetBackup";
    our $bplistbin = $installpath."\\bin\\bplist\"";
    our $bppllistbin = $installpath."\\bin\\admincmd\\bppllist\"";
}
elsif ($operating_system eq "linux")
{
    my $installpath = "/usr/openv/netbackup";
    our $bplistbin = $installpath."/bin/admincmd/bplist";
    our $bppllistbin = $installpath."/bin/admincmd/bppllist";
}


output_usage() if ($#ARGV <= 1);
my %opt;
my $getoptresult = GetOptions(\%opt,
    "find|f=s" => \$searchstring,
    "start|s=s" => \$startdate,
    "end|e=s" => \$enddate,
    "policy|p=s" => \$policyname,
    "type|t=i" => \$policytype,
    "help|h" => \$help,
    "debug|d" => \$debug,
    );
output_usage() if (not $getoptresult);
output_usage() if ($help);

sub output_usage
{
    my $usage = qq{
Usage: $0 [options]

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
    -d | --debug                : debug
    -h | --help                 : show this help

};

    die $usage;
}

sub debug
{
    my $level = $_[0];
    my $msg = $_[1];
    if ($debug)
    {
        print "<$level> DEBUG: $msg\n";
    }
}

# Find clients in selected policy, takes one argument
sub clients_in_policy
{
    my $name = $_[0];
    my $output = `$bppllistbin $name -l`;
    my @out;
    foreach (split("\n", $output))
    {
        if (m/^CLIENT/)
        {
            @p = split /\s+/, $_;
            push(@out, $p[1]);
        }
    }
    return @out;
}

# searches after pattern with specified options, return status code of command
sub search
{
    my $client = $_[0];
    my $policytype = $_[1];
    my $startdate = $_[2];
    my $enddate = $_[3];
    my $searchstr = $_[4];

    # bplist -C nyserver1 -t 13 -b -R -l -I -s 01/01/2008 -e 07/30/2013 -PI "/C/Temp"
    print "Searching $client ...\n";
    $cmd = $bplistbin.' -C '.$client.' -t '.$policytype.' -b -R -l -I -s '.$startdate.' -e '.$enddate.' -PI "'.$searchstr.'"';
    debug(1, "Executing: $cmd");
    system($cmd);
    return $?; # return status code of cmd
}

sub main
{
    my @matched;
    my @clients = clients_in_policy($policyname);
    foreach $client (@clients)
    {
        my $ret = search($client, $policytype, $startdate, $enddate, $searchstring);
        if ($ret == 0)
        {
            push(@matched, $client); # push matched client into array
        }
    }
    if (length(@matched))
    {
        print "Matched string $searchstring on the following clients in policy $policyname:\n";
        foreach (@matched)
        {
            print "\t\t".$_."\n";
        }
    }
}

main()

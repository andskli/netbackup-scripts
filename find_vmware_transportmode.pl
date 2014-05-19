#!/usr/bin/perl
#
# Get information about transport modes for VMware polciices
#
# Author: Andreas Skarmutsos Lindh <andreas@superblock.se>
#

use warnings;
use Getopt::Long;
use Data::Dumper;
use File::Temp;
use File::Basename;

my $windows_temppath = dirname(__FILE__);

# Check OS and adjust paths accordingly
my $operating_system = $^O;
if ($operating_system eq "MSWin32")
{
    if (exists $ENV{'NBU_INSTALLDIR'})
    {
        $installpath = "$ENV{'NBU_INSTALLDIR'}";
        chomp($installpath);
    }
    our $bpplinfobin    = "\"$installpath\\NetBackup\\bin\\admincmd\\bpplinfo\"";
    our $bperrorbin     = "\"$installpath\\NetBackup\\bin\\admincmd\\bperror\"";
    our $bpdbjobsbin    = "\"$installpath\\NetBackup\\bin\\admincmd\\bpdbjobs\"";
}
elsif ($operating_system eq "linux")
{
    my $installpath     = "/usr/openv/netbackup";
    our $bpplinfobin    = $installpath."/bin/admincmd/bpplinfo";
    our $bperrorbin     = $installpath."/bin/admincmd/bperror";
    our $bpdbjobsbin    = $installpath."/bin/admincmd/bpdbjobs";
}

my %opt;
my $getoptresult = GetOptions(\%opt,
    "policy|p=s"      => \$policy,
    "help|h"          => \$help,
);
output_usage() if (not $getoptresult);
output_usage() if ($help);

sub output_usage
{
    my $usage = qq{
Usage: $0 [options]

Options:
    -p | --policy           : Which policy to check
    -h | --help             : display this output

};

    die $usage;
}

sub get_policy_transport_types
{
    my $policy = $_[0];
    my $output = `$bpplinfobin $policy -L`;
    foreach my $line (split("\n", $output))
    {
            if ($line =~ m/trantype/)
            {
                @matches = $line =~ m/trantype=(([a-z]|\:?)+)/g;
            }
    }
    foreach my $match (@matches)
    {
         push(@transporttypes, split(":", $match));
    }
    return @transporttypes;
}

sub find_jobids_by_policy
{
    my $policy = $_[0];
    my @jobs;
    my $output = `$bperrorbin -backstat -l -hoursago 24`;
    foreach my $line (split("\n", $output))
    {
        if ($line =~ m/POLICY $policy/)
        {
            my @x = split("\ ", $line);
            my $jobid = $x[5];
            my $parentjobid = $x[6];
            my $client = $x[8];

            # Ignore parent snapshot jobs
            unless ($jobid == $parentjobid) {
                push(@jobs, ($jobid, $client));
            }
        }
    }
    return @jobs;
}

sub get_transporttype
{
    my $jobid = $_[0];
    my $output = `$bpdbjobsbin -report -all_columns -jobid $jobid`;
    my @match = $output =~ m/Transport Type =  (.*?)\,/;
    my $transporttype = $match[0];
    
    return $transporttype;
}

sub main
{
    if ($policy)
    {
        my @transportmodes = get_policy_transport_types($policy);
        my @jobs = find_jobids_by_policy($policy);
        my $primary_transportmode = pop(@transportmodes);

        my @nodes_primary;
        my @nodes_secondary;

        foreach my $job (\@jobs)
        {
             print Dumper($job);
             my $jobid = $job->[0];
             my $client = $job->[1];
             print("JOBID: $jobid  CLIENT: $client\n");
             if ($primary_transportmode eq get_transporttype($jobid))
             {
                 push(@nodes_primary, $client);
             }
             else
             {
                 push(@nodes_secondary, $client);
             }
        }

        print("PRIMARY TRANSPORTMODE: $primary_transportmode\n");
        print("NODES USING PRIMARY TRANSPORT MODE ($primary_transportmode):\n");
        print Dumper(@nodes_primary);
        print("NODES USING SECONDARY TRANSPORT MODES:\n");
        print Dumper(@nodes_secondary);
    }
}

main()

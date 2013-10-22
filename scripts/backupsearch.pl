#!/usr/bin/perl
# Search NetBackup backups for specific file
#
# Author: Andreas Skarmutsos Lindh <andreas.skarmutsoslindh@gmail.com>
#
# Usage example:
#	./backupsearch.pl -t 13 -s 10/01/2013 -e 10/03/2013 -p Windows_policy_name -f "/C/Temp"
# 

#use strict;
use warnings;
use Getopt::Std;
use Data::Dumper;

my $bplistbin = "/usr/openv/netbackup/bin/bplist";
my $bppllistbin = "/usr/openv/netbackup/bin/admincmd/bppllist";

my %opt;
getopts('f:s:e:t:p:dh?', \%opt) or output_usage();
output_usage() if $opt{'h'};

if ((!$opt{'f'}) or
    (!$opt{'s'}) or
    (!$opt{'p'}) or
    (!$opt{'e'}) or
    (!$opt{'t'}))
{
    output_usage();
}

sub output_usage
{
	my $usage = "Usage: $0 [options]

	Options:
		-f <string>			Search for string, note that you need to use /C/temp to search for C:/Temp
		-s <mm/dd/yyyy>		Start date
		-e <mm/dd/yyyy>		End date
		-p <policy name>	Policy to search
		-t <type>			Policy type (use 13 for windows!!)
								0	Standard	
								1	Proxy
								2	Non-Standard
								3	Apollo-wbak
								4	Oracle
								5	Any policy type	
								6	Informix-On-BAR	
								7	Sybase	
								8	MS-Sharepoint
								10	NetWare
								11	DataTools-SQL-BackTrack
								12	Auspex-FastBackup
								13	MS-Windows-NT
								14	OS/2
								15	MS-SQL-Server
								16	MS-Exchange-Server
								17	SAP
								18	DB2
								19	NDMP	
								20	FlashBackup
								21	Split-Mirror
								22	AFS
								24	DataStore
								25	Lotus-Notes
								28	MPE/iX
								29	FlashBackup-Windows
								30	Vault
								31	BE-MS-SQL-Server
								32	BE-MS-Exchange-Server
								34	Disk Staging
								35	NBU-Catalog
		-d 					Debug.
	\n";

	die $usage;
}

sub debug
{
	my $level = $_[0];
	my $msg = $_[1];
	if ($opt{'d'})
	{
		print "<$level> DEBUG: $msg\n";
	}
}

# Find clients in selected policy, takes one argument
sub clients_in_policy
{
	my $policyname = $_[0];
	my $output = `$bppllistbin $policyname -l`;
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
	my $cmd = $bplistbin.' -C '.$client.' -t '.$policytype.' -b -R -l -I -s '.$startdate.' -e '.$enddate.' -PI "'.$searchstr.'" 2>1 >/dev/null';
	system($cmd);
	return $?; # return status code of cmd
}

sub main
{
	my @matched;
	my @clients = &clients_in_policy($opt{'p'});
	foreach $client (@clients)
	{
		my $ret = &search($client, $opt{'t'}, $opt{'s'}, $opt{'e'}, $opt{'f'});
		if ($ret == 0)
		{
			push(@matched, $client); # push matched client into array
		}
	}
	if (length(@matched))
	{
		print "Matched string ".$opt{'f'}." on the following clients in policy ".$opt{'p'}.":\n";
		foreach (@matched)
		{
			print "\t\t".$_."\n";
		}
	}
}

&main()

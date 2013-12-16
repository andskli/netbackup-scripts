#!/usr/bin/perl
#
# NetBackup -- manage bandwidth settings for clients.
# 
# By default NetBackup only provides methods for limiting bandwidth on
# IP/network basis, which is good. But for real life use cases sometimes
# clients in remote countries sit on different subnets, which is why we
# want to set bandwidth limits for all clients in a policy.
#
# Author: Andreas Skarmutsos Lindh <andreas.skarmutsoslindh@gmail.com>
#

#use strict;
use warnings;
use Getopt::Std;
use Data::Dumper;
use File::Temp;

my $windows_temppath = "C:\\Temp"; # FIXME

# Check OS and adjust netbackup executable binaries accordingly
my $operating_system = $^O;
if ($operating_system eq "MSWin32")
{
	my $installpath = "\"C:\\Program Files\\Veritas\\NetBackup";
	our $bpgetconfigbin = $installpath."\\bin\\admincmd\\bpgetconfig\"";
	our $bpsetconfigbin = $installpath."\\bin\\admincmd\\bpsetconfig\"";
	our $bppllistbin = $installpath."\\bin\\admincmd\\bppllist\"";
}
elsif ($operating_system eq "linux")
{
	my $installpath = "/usr/openv/netbackup";
	our $bpgetconfigbin = $installpath."/bin/admincmd/bpgetconfig";
	our $bpsetconfigbin = $installpath."/bin/admincmd/bpsetconfig";
	our $bppllistbin = $installpath."/bin/admincmd/bppllist";
}

my @tmpfiles;

my %opt;
getopts('a:p:c:f:e:dh?', \%opt) or output_usage();
output_usage() if $opt{'h'};

sub output_usage
{
	my $usage = "Usage: $0 [options]

Mandatory:
	-a <get/set>	Action to perform
	-l <limit>		The limit in MBit/s
One of the following:
	-c <client>		Client which will be affected
	-p <policy>		Policy to work on
	-n <network>	Specify

	-d 		Debug.\n";

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
sub get_clients_in_policy
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
			debug(1, "found client $p[1] in $policyname");
		}
	}
	return @out;
}

# Make tempfile containing network limits (comma separated).
# i.e. -- 192.168.1.0,192.168.1.255,2048
# make_tempfile(@array)
# @array should contain multiple strings with comma separated values as above
# Returns path to tempfile
sub make_tempfile
{
	my (@limits) = @{$_[0]};

	# Check OS
	if ($operating_system eq 'MSWin32')
	{
		$tmppath = $windows_temppath;
	}
	else
	{
		$tmppath = '/tmp';
	}
	
	my $tmp = File::Temp->new(
		TEMPLATE => 'tmpXXXXX',
		DIR => $tmppath,
		SUFFIX => '.dat',
		UNLINK => 0);
	
	chomp($tmp);
	debug(1, "Tmpfile: [$tmp]");

	foreach my $limit_row (@limits)
	{
		my ($ip_start, $ip_stop, $limit) = split(/,/, $limit_row);
		debug(1, "LIMIT_BANDWIDTH = $ip_start $ip_stop $limit");
		print $tmp "LIMIT_BANDWIDTH = $ip_start $ip_stop $limit\n";
	}

	debug(1, "Returning $tmp from make_tempfile()");
	return $tmp;
}
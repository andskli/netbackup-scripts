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
use File::Basename;

my $windows_temppath = dirname(__FILE__);

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
my $getoptresult = GetOptions(\%opt,
	"action|a=s" => \$actionopt,
	"limit|l=i" => \$limitopt,
	"client|c=s" => \$clientopt,
	"policy|p=s" => \$policyopt,
	"network|n=s" => \$networkopt,
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
	-a | --action <action>		: Which action to perform (get/set)
	-l | --limit <speed>		: Speed in KiB/Sec (symantec standard)
	-c | --client <name>		: Set for which client?
	-p | --policy <name>		: Set for which policy?
	-n | --network <network>	: Set for which network (should accept cidr mask)
	-d | --debug				: debug
	-h | --help					: display this help output

};

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
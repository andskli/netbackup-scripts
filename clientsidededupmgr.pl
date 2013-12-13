#!/usr/bin/perl
#
# Manage client side dedup settings for multiple clients at once
#
# Author: Andreas Skarmutsos Lindh <andreas.skarmutsoslindh@gmail.com>
#

#use strict;
use warnings;
use Getopt::Std;
use Data::Dumper;
use File::Temp;

my $windows_temppath = "C:\\Temp"; # FIXME

# Check which OS we're running on and adjust the script accordingly
my $operating_system = $^O;
if ($operating_system eq "MSWin32")
{
    my $installpath = "\"C:\\Program Files\\Veritas\\NetBackup";
    our $bppllistbin = $installpath."\\bin\\admincmd\\bppllist\"";
    our $bpclientbin = $installpath."\\bin\\admincmd\\bpclient\"";
}
else
{
	my $installpath = "/usr/openv/netbackup";
	our $bppllistbin = $installpath."/bin/admincmd/bppllist";
	our $bpclientbin = $installpath."/bin/admincmd/bpclient";
}

my %opt;
getopts('c:p:s:dh?', \%opt) or output_usage();

if ((!$opt{'p'} or
	(!$opt{'s'}) or
	(!$opt{'c'}) or
	($opt{'?'}) or
	($opt{'h'}))
{
	output_usage();
}

sub output_usage
{
	my $usage = "Usage: $0 [options]

One of:
	-p <policy>	Name of policy containing clients to update
	-c <client>	Name of client to update

Mandatory:
	-s [preferclient/clientside/mediaserver]	Specify which dedup
			mode to use	on client.

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

# check if client attributes exists for the given client and decide add/update
sub clientattributes_exists
{
	my $client = $_[0];
	system("$bpclientbin -client $client -l");
	if ($? == -1) {
		die "command failed: $!\n";
	}
	elsif ($? == 0)
	{
		debug(1, "$client exists and only needs -update");
		return 0;
	}
	else
	{
		debug(1, "$client does not exist and needs to be -add:ed");
		return 1;
	}
}

# set dedup mode for a client, example: set_mode("abc.def.com", "preferclient")
sub set_mode 
{
	my $client = $_[0];
	my $mode = $_[1];
	my $mode_n = $modes{$mode};
	my $action_needed;

	my %modes = (
		'mediaserver' => 0,
		'preferclient' => 1,
		'clientside' => 2
	);

	if (clientattributes_exists($client))
	{
		$action_needed = "-update";
	}
	else
	{
		$action_needed = "-add";
	}
	system("$bpclientbin -client $client $action_needed -client_direct $mode_n");
}

sub main
{
	# figure out which clients to operate on
	my @clients;
	if ($opt{'c'}) # if -c is set, juse use one client
	{
		push(@clients, $opt{'c'});
	}
	if ($opt{'p'}) # if -p is set, policy is specified and we need to fetch all clients
	{
		foreach (get_clients_in_policy($opt{'p'}))
		{
			push(@clients, $_);
		}
	}

	# figure out what setting to set
	my $mode_t = $opt{'s'};
	foreach my $client (@clients)
	{
		debug(1, "Setting mode $mode_t for $client");
		set_mode($client, $mode_t);
	}
}

main();

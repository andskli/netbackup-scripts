#!/usr/bin/perl
#
# Manage NetBackup client exclude lists for multiple clients at once.
#
# Author: Andreas Skarmutsos Lindh <andreas.skarmutsoslindh@gmail.com>
#

#use strict;
use warnings;
use Getopt::Std;
use Data::Dumper;

my $bpgetconfigbin = "/usr/openv/netbackup/bin/admincmd/bpgetconfig";
my $bpsetconfigbin = "/usr/openv/netbackup/bin/admincmd/bpsetconfig";
my $bppllistbin = "/usr/openv/netbackup/bin/admincmd/bppllist";

my %opt;
getopts('a:p:c:f:e:dh?', \%opt) or output_usage();
output_usage() if $opt{'h'};

sub output_usage
{
	my $usage = "Usage: $0 [options]

	Options:

	Mandatory:
		-a <get/add/del>	Action to perform
	One of the following:
		-c <client>					Client which will be affected
		-p <policy>					Policy to work on
	One of the following:
		-e <exclude string>			String to exclude

		-d 							Debug.
	\n\n";

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

# Func stolen from stackoverflow to make array unique
sub uniq
{
    return keys %{{ map { $_ => 1 } @_ }};
}

# Functions reversing back/forward-slashes
sub backslashify
{
	$_ =~ s/\//\\\\/g;
	return $_;
}
sub forwardslashify
{
	s/\\/\//g;
	return $_;
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
		}
	}
	return @out;
}

# Select what to get from bpgetconfig
# &get_excludes("xyz.abc.com")
sub get_excludes
{
	$client = $_[0];
	$type = "EXCLUDE";
	&debug(1, "Calling: $bpgetconfigbin -M $client $type");
	my @output = `$bpgetconfigbin -M $client $type`;
    return @output;
}

# Write excludelist to tempfile
# &make_tempfile(\@excludes)
# Returns path to tempfile
sub make_tempfile
{
	my (@excludes) = @{$_[0]};
	my $tmp = `mktemp`;
	&debug(1, "Created: $tmp");

	open(FH, ">>$tmp") or die "Can't open $tmp: $!";
	foreach (@excludes)
	{
		print FH $_;
	}
	close FH;

	return $tmp;
}

# &push_excludes($client, $excludetmpfile)
sub push_excludes
{
	my $client = $_[0];
	my $tmpfile = $_[1];

	my $cmd = $bpsetconfigbin.' -h '.$client.' '.$tmpfile.' 2>&1 >/dev/null';
	print `$cmd`;

	#unlink $tmpfile or die "Can't remove file $tmpfile: $!"; # rm tempfile
}

sub main
{

	# Figure out what clients to operate on
	my @clients;
	if ($opt{'c'}) # if -c is set, one client
	{
		push(@clients, $opt{'c'});
	}
	if ($opt{'p'}) # if -p, we specify a policy
	{
		my @clients = &get_clients_in_policy($opt{'p'});
	}

	# Figure out exclude input
	my @excludes;
	if ($opt{'e'})
	{
		push(@excludes, "EXCLUDE = ".$opt{'e'}."\n");
	}

	# get - fetch excludes and echo to stdout
	if ($opt{'a'} eq "get")
	{
		foreach $client (@clients)
		{
			print("Excludes for client $client:\n");
			print &get_excludes($client);
		}
	}
	# If we want to add exclude we have to loop thru each client
	if ($opt{'a'} eq "add")
	{
		foreach $client (@clients)
		{
			# Fetch existing client excludes and push them into @excludes list
			my @existing = &get_excludes($client);
			foreach $exclude (@existing)
			{
				push(@excludes, "$exclude\n");
			}
			my $f = &make_tempfile(\@excludes);
			&push_excludes($client, $f);
		}
	}
	# If we replace, just push the new exclude.
	if ($opt{'a'} eq "replace")
	{
		foreach $client (@clients)
		{
			my $f = &make_tempfile(\@excludes);
			&push_excludes($client, $f);
		}
	}
	# Delete
	if ($opt{'a'} eq "delete")
	{
		foreach $client (@clients)
		{
			my @existing = &get_excludes($client);
			my @excludes_to_remove = @excludes;
			my @excludes;

			foreach $toremove (@excludes_to_remove)
			{
				for (my $i = 0; $i <= $#existing; $i++)
				{
					push(@excludes, $existing[$i]) if $existing[$i] ne $toremove;
				}
			}
			
			my $f = &make_tempfile(\@excludes);
		}
	}
	
}

main()

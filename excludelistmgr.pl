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

my @tmpfiles;

my %opt;
getopts('a:p:c:f:e:dh?', \%opt) or output_usage();
output_usage() if $opt{'h'};

sub output_usage
{
	my $usage = "Usage: $0 [options]

	Options:

	Mandatory:
		-a <get/add/del/set>	Action to perform
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
			debug(1, "found client $p[1] in $policyname");
		}
	}
	return @out;
}

# Select what to get from bpgetconfig
# get_excludes("xyz.abc.com")
sub get_excludes
{
	$client = $_[0];
	$type = "EXCLUDE";
	debug(1, "Calling: $bpgetconfigbin -M $client $type");
	my @output = `$bpgetconfigbin -M $client $type`;
	return @output;
}

# Write excludelist to tempfile
# make_tempfile(\@excludes)
# Returns path to tempfile
sub make_tempfile
{
	my (@excludes) = @{$_[0]};
	my $tmp = `mktemp`;
	chomp $tmp;
	debug(1, "Created: $tmp");

	open(FH, ">>$tmp") or die "Can't open $tmp: $!";
	foreach (@excludes)
	{
		print FH $_;
	}
	close FH;

	return $tmp;
}

# push_excludes($client, $excludetmpfile)
sub push_excludes
{
	my $client = $_[0];
	my $tmpfile = $_[1];

	my $cmd = $bpsetconfigbin.' -h '.$client.' '.$tmpfile.' 2>&1 >/dev/null';
	print `$cmd`;
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
		foreach (get_clients_in_policy($opt{'p'}))
		{
			push(@clients, $_);
		}
	}

	# Figure out exclude input
	my @excludes;
	if ($opt{'e'}) # use string, preferrably '<string>'
	{
		push(@excludes, "EXCLUDE = ".$opt{'e'}."\n");
	}
	if ($opt{'f'}) # use file
	{
		my @filedata = do
		{
			open my $fh, "<", $opt{'f'}
				or die "could not open $opt{'f'}: $!";
			<$fh>;
		};

		foreach (@filedata)
		{
			debug(1, "Found row containing [".$_."] in $opt{'f'}");
			push(@excludes, "EXCLUDE = ".$_."\n");
		}
	}

	# get - fetch excludes and echo to stdout
	if ($opt{'a'} eq "get")
	{
		foreach $client (@clients)
		{
			debug(1, "processing $client");
			my @client_excludes = get_excludes($client);
			print "Excludes for client $client:\n";
			foreach (@client_excludes)
			{
				print "\t$_";
			}
		}
	}
	# If we want to add exclude we have to loop thru each client
	if ($opt{'a'} eq "add")
	{
		foreach $client (@clients)
		{
			# Fetch existing client excludes and push them into @excludes list
			my @new_excludes;
			my @existing = get_excludes($client);
			foreach $exclude (@existing)
			{
				push(@new_excludes, "$exclude\n");
			}
			foreach (@excludes)
			{
				push(@new_excludes, $_);
			}
			uniq(@new_excludes);
			my $f = make_tempfile(\@new_excludes);
			push_excludes($client, $f);
			push(@tmpfiles, $f);
			undef(@new_excludes);
		}
	}
	# If we replace, just push the new exclude.
	if ($opt{'a'} eq "set")
	{
		foreach $client (@clients)
		{
			uniq(@excludes);
			my $f = make_tempfile(\@excludes);
			push_excludes($client, $f);
			push(@tmpfiles, $f);
		}
	}
	# Delete
	if ($opt{'a'} eq "del")
	{
		foreach $client (@clients)
		{
			foreach $to_del (@excludes)
			{
				# logic goes here.
			}
		}
	}
	# Cleanup tempfiles
	foreach my $f (@tmpfiles)
	{
		debug(1, "Trying to delete [".$f."]");
		unlink $f or warn "Could not unlink $f: $!";
	}
}

main()

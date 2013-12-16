#!/usr/bin/perl
#
# Manage NetBackup client media servers.
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
getopts('a:p:c:m:f:dh?', \%opt) or output_usage();
output_usage() if $opt{'h'};

sub output_usage
{
	my $usage = "Usage: $0 [options]

Mandatory:
	-a <get/add/del>	Action to perform
One of the following:
	-c <client>		Client which will be affected
	-p <policy>		Policy to work on
One of the following:
	-m <media server>		name of media server
	-f <path>		file with media servers listed 

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

# Func stolen from stackoverflow to make array unique
sub uniq
{
	return keys %{{ map { $_ => 1 } @_ }};
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

sub pull_serverlist
{
	$client = $_[0];
	$type = "SERVER";
	debug(1, "Calling: $bpgetconfigbin -M $client $type");
	my @output = `$bpgetconfigbin -M $client $type`;
	return @output;
}

# push_serverlist($client, $tmpfile)
sub push_serverlist
{
	my $client = $_[0];
	my $tmpfile = $_[1];

	my $cmd = $bpsetconfigbin.' -h '.$client.' '.$tmpfile;
	print `$cmd`;
}


# Write excludelist to tempfile
# make_tempfile(\@serverlist)
# Returns path to tempfile
sub make_tempfile
{
	my (@serverlist) = @{$_[0]};
	
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

	foreach (@serverlist)
	{
		chomp($_);
		debug(2, "Printing $_ into [$tmp]");
		print $tmp "$_\n";
	}
	debug(1, "Returning $tmp from make_tempfile()");
	return $tmp;
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

	# Figure out media server(s)
	my @serverlist;
	if ($opt{'m'}) # use string, preferrably '<string>'
	{
		push(@serverlist, "SERVER = ".$opt{'m'});
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
			chomp($_);
			debug(1, "Found row containing [".$_."] in $opt{'f'}");
			push(@serverlist, "SERVER = $_");
		}
	}

	# get - fetch excludes and echo to stdout
	if ($opt{'a'} eq "get")
	{
		foreach $client (@clients)
		{
			debug(1, "processing $client");
			my @client_serverlist = pull_serverlist($client);
			print "SERVERs for client $client:\n";
			foreach (@client_serverlist)
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
			my @new_serverlist;
			my @existing_serverlist = pull_serverlist($client);
			foreach $server (@existing_serverlist)
			{
				push(@new_serverlist, $server);
			}
			foreach (@serverlist)
			{
				push(@new_serverlist, $_);
			}
			uniq(@new_serverlist);
			my $f = make_tempfile(\@new_serverlist);
			push_serverlist($client, $f);
			push(@tmpfiles, $f);
			undef(@new_serverlist);
		}
	}
	
	# Delete
	if ($opt{'a'} eq "del")
	{
		foreach $client (@clients)
		{
			my @existing_serverlist = pull_serverlist($client);
			
			# ugly way to compare and delete between two arrays
			my @new_serverlist = grep { my $x = $_; not grep { $x =~ /\Q$_/i } @serverlist } @existing_serverlist;

			if ($#new_serverlist < 1)
			{
				die "Removing ALL excludes. Not implemented yet, thus not executing\n";
			}

			uniq(@new_serverlist);
			my $f = make_tempfile(\@new_serverlist);
			push_serverlist($client, $f);
			push(@tmpfiles, $f);
			undef(@new_serverlist);
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

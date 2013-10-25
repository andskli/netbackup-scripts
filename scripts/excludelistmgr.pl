#!/usr/bin/perl
#
# Manage NetBackup client exclude lists for multiple clients at once.
#
# Author: Andreas Skarmutsos Lindh
#
# Needs fix for backslashed excludelists so that \b works properly. (windows)
#

#use strict;
use warnings;
use Getopt::Std;
use Data::Dumper;

my $bpgetconfigbin = "/usr/openv/netbackup/bin/admincmd/bpgetconfig";
my $bpsetconfigbin = "/usr/openv/netbackup/bin/admincmd/bpsetconfig";

my %opt;
getopts('a:p:c:f:e:dh?', \%opt) or output_usage();
output_usage() if $opt{'h'};

sub output_usage
{
	my $usage = "Usage: $0 [options]

	Options:
		-a <add/del/replace>		Action to perform
		-p <policy>					Policy for which clients will be affected
		-c <client>					Client which will be affected
		-f <file>					File containing exclude list
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


# Select what to get from bpgetconfig
# &bpgetconfig("xyz.zz.hm.com", "SERVER")
sub get_excludes
{
	$client = $_[0];
	$type = "EXCLUDE";
	&debug(1, "Calling: $bpgetconfigbin -M $client $type");
	my @output = `$bpgetconfigbin -M $client $type`;
    return @output;
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


sub main
{
	local $client = $opt{'c'};
	@excludelist = &get_excludes($client);
	$newexclude = 'EXCLUDE = '.$opt{'e'};

	push(@excludelist, $newexclude);
	foreach (@excludelist)
	{
		&forwardslashify($_);
	}

	my @newlist = &uniq(@excludelist);

	print Dumper(@newlist);
	my $longstr = join("\n", @newlist);
	my $longcmd = 'echo -e \''.$longstr.'\' | '.$bpsetconfigbin.' -h '.$client.' 2>1& >/dev/null';
	print `$longcmd`;
}

main()

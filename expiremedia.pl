#!/usr/bin/perl
#
# NetBackup script to expire tape(s).
#
# Author: Andreas Skarmutsos Lindh <andreas.skarmutsoslindh@gmail.com>
#

#use strict;
use warnings;
use Getopt::Std;
use Data::Dumper;

# Check OS and adjust netbackup executable binaries accordingly
my $operating_system = $^O;
if ($operating_system eq "MSWin32")
{
	my $installpath = "\"C:\\Program Files\\Veritas\\NetBackup";
	our $bpexpdatebin = $installpath."\\bin\\admincmd\\bpexpdate\"";
}
elsif ($operating_system eq "linux")
{
	my $installpath = "/usr/openv/netbackup";
	our $bpexpdatebin = $installpath."/bin/admincmd/bpexpdate";
}

my @tmpfiles;

my %opt;
getopts('X:f:dh?', \%opt) or output_usage();

if (!$opt{'f'}) { output_usage(); }

sub output_usage
{
	my $usage = "Usage: $0 [options]

Options:
\t-f <path>\t\tfile containing list of media ID's to be expired
\t-X\t\t\tforce expiration without questions asked
\t-d\t\t\tDebug.\n";

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

sub main
{
	my $file = $opt{'f'};
	debug(1, "Reading from $file");
	my @media_names;

	open(FH, $file);
	while(<FH>)
	{
		debug(1, "Read [$_] from $file");
		chomp $_;
		debug(1, "Pushing [$_] into \@media_names");
		push(@media_names, $_);
	}
	close(FH);
		
	foreach my $media (@media_names)
	{
		debug(1, "Adding $media to candidates for expiration");
	}
	if ($#media_names >= 0)
	{
		foreach my $media (@media_names)
		{
			if ($opt{'X'})
			{
				my $cmd = `$bpexpdatebin -m $media -d 0 -force`;
			}
			else
			{
				print "Really expire media $media? (yes/no): ";
				$answer = <STDIN>;
				print "\n";
				if ($answer =~ m/yes/i)
				{
					print "OK, you selected yes -- let's expire that media ($media)\n";
					my $cmd = `$bpexpdatebin -m $media -d 0 -force`;
					debug(1, "Called $cmd");
				}
				elsif ($answer =~ m/no/i)
				{
					print "Not expiring $media\n";
				}
			}
		}
	}
	else
	{
		die("There was insufficient in the list, exiting.\n");
	}

}

main();

#!/usr/bin/perl
#
# Manage NetBackup client exclude lists for multiple clients at once.
#
# Author: Andreas Skarmutsos Lindh <andreas@superblock.se>
#

#use strict;
use warnings;
use Getopt::Long;
use Data::Dumper;
use File::Temp;
use File::Basename;


my $windows_temppath = dirname(__FILE__);

# Check OS and adjust netbackup executable binaries accordingly
my $operating_system = $^O;
if ($operating_system eq "MSWin32")
{
    if (exists $ENV{'NBU_INSTALLDIR'})
    {
        $installpath = "$ENV{'NBU_INSTALLDIR'}";
        chomp($installpath);
    }
    our $bpgetconfigbin = "\"$installpath\\NetBackup\\bin\\admincmd\\bpgetconfig\"";
    our $bpsetconfigbin = "\"$installpath\\NetBackup\\bin\\admincmd\\bpsetconfig\"";
    our $bppllistbin = "\"$installpath\\NetBackup\\bin\\admincmd\\bppllist\"";
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
    "client|c=s" => \$clientopt,
    "policy|p=s" => \$policyopt,
    "exclude|e=s" => \$excludeopt,
    "file|f=s" => \$fileopt,
    "help|h|?" => \$help,
);
output_usage() if (not $getoptresult);
output_usage() if ($help);

sub output_usage
{
    my $usage = qq{
Usage: $0 [options]

Mandatory:
    -a | --action <action>      : Specify get/add/del/set for the set of clients
    -p | --policy <name>        : Policy to work with
    -c | --client <name>        : Client to work with
    -e | --exclude <string>     : String to exclude. I.e. \"C:\\Temp\\*\"
    -f | --file <path>          : Path to file containing exclude list (newline separation)
    -h | --help                 : display this output

};

    die $usage;
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
# get_excludes("xyz.abc.com")
sub get_excludes
{
    $client = $_[0];
    $type = "EXCLUDE";
    my @output = `$bpgetconfigbin -M $client $type`;
    return @output;
}

# Write excludelist to tempfile
# make_tempfile(\@excludes)
# Returns path to tempfile
sub make_tempfile
{
    my (@excludes) = @{$_[0]};
    
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

    foreach (@excludes)
    {
        chomp($_);
        print $tmp "$_\n";
    }
    return $tmp;
}

# push_excludes($client, $excludetmpfile)
sub push_excludes
{
    my $client = $_[0];
    my $tmpfile = $_[1];

    my $cmd = $bpsetconfigbin.' -h '.$client.' '.$tmpfile;
    print `$cmd`;
}


sub close_and_delete
{
    my $f = $_[0];
    close($f);
    if ($operating_system eq "MSWin32") {
        system("del /F $f");
    } else {
        unlink $f or warn "Could not unlink $f: $!\n";
    }
}


sub main
{
    # Figure out what clients to operate on
    my @clients;
    if ($clientopt) # if -c is set, one client
    {
        push(@clients, $clientopt);
    }
    if ($policyopt) # if -p, we specify a policy
    {
        foreach (get_clients_in_policy($policyopt))
        {
            push(@clients, $_);
        }
    }

    # Figure out exclude input
    my @excludes;
    if ($excludeopt) # use string, preferrably '<string>'
    {
        push(@excludes, "EXCLUDE = ".$excludeopt);
    }
    if ($fileopt) # use file
    {
        my @filedata = do
        {
            open my $fh, "<", $fileopt
                or die "could not open $fileopt: $!";
            <$fh>;
        };

        foreach (@filedata)
        {
            chomp($_);
            push(@excludes, "EXCLUDE = $_");
        }
    }

    # get - fetch excludes and echo to stdout
    if ($actionopt eq "get")
    {
        foreach $client (@clients)
        {
            my @client_excludes = get_excludes($client);
            print "Excludes for client $client:\n";
            foreach (@client_excludes)
            {
                s/^EXCLUDE \= (.*)$/$1/;
                print "\t$_";
            }
        }
    }
    # If we want to add exclude we have to loop thru each client
    if ($actionopt eq "add")
    {
        foreach $client (@clients)
        {
            # Fetch existing client excludes and push them into @excludes list
            my @new_excludes;
            my @existing = get_excludes($client);
            foreach $exclude (@existing)
            {
                push(@new_excludes, $exclude);
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
    if ($actionopt eq "set")
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
    if ($actionopt eq "del")
    {
        foreach $client (@clients)
        {
            my @existing = get_excludes($client);
            
            # ugly way to compare and delete between two arrays
            my @new_excludes = grep { my $x = $_; not grep { $x =~ /\Q$_/i } @excludes } @existing;

            if ($#new_excludes < 1)
            {
                die "Removing ALL excludes. Not implemented yet, thus not executing\n";
            }

            uniq(@new_excludes);
            my $f = make_tempfile(\@new_excludes);
            push_excludes($client, $f);
            push(@tmpfiles, $f);
            undef(@new_excludes);
        }
    }
    # Cleanup tempfiles
    foreach my $f (@tmpfiles)
    {
        close_and_delete($f);
    }
}

main()

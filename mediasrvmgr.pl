#!/usr/bin/perl
#
# Manage NetBackup client media servers.
#
# Author: Andreas Skarmutsos Lindh <andreas.skarmutsoslindh@gmail.com>
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
    "mediasrv|m=s" => \@mediasrvopt,
    "file|f=s" => \$fileopt,
    "help|h|?" => \$help,
);
output_usage() if (not $getoptresult);
output_usage() if ($help);

sub output_usage
{
    my $usage = qq{
Usage: $0 [options]

Options:
    -a | --action <action>  : Action to perform, may be any of add/get/del
    -c | --client <name>    : Client that will be affected
    -p | --policy <name>    : Policy with clients that will be affected
    -m | --mediasrv <name>  : Name of media server to add/remove from clients
    -f | --file <path>      : Path to file with media servers which to add/remove
                            from clients
    -h | --help             : display this output

};
    die $usage;
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
        }
    }
    return @out;
}

sub pull_serverlist
{
    $client = $_[0];
    $type = "SERVER";
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

    foreach (@serverlist)
    {
        chomp($_);
        print $tmp "$_\n";
    }
    return $tmp;
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

    # Figure out media server(s)
    my @serverlist;
    if (@mediasrvopt) # if -m
    {
    	foreach my $m (@mediasrvopt) {
    		push(@serverlist, "SERVER = $m");
    	}
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
            push(@serverlist, "SERVER = $_");
        }
    }

    # get - fetch excludes and echo to stdout
    if ($actionopt eq "get")
    {
        foreach $client (@clients)
        {
            my @client_serverlist = pull_serverlist($client);
            print "SERVERs for client $client:\n";
            foreach (@client_serverlist)
            {
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
    if ($actionopt eq "del")
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
        unlink $f or warn "Could not unlink $f: $!";
    }
}

main()

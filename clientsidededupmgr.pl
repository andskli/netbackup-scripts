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
    our $bpgetconfigbin = $installpath."\\bin\

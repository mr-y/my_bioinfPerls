#! /usr/bin/perl

use warnings;
use strict;

use IO::Uncompress::Gunzip;

sub help {
    print "This script prints the content of a GZIPed file to the screen. The only argument\nshould be the GZIP file.\n";
    exit;
}

for (my $i=0; $i < scalar @ARGV; ++$i) {
    if ($ARGV[$i] eq '-h' || $ARGV[$i] eq '--help') { &help(); }
    elsif ($i > 0) {
	die "The script should take the name of a GZIPed file as only argument.\n";
    }
}

my $file = new IO::Uncompress::Gunzip $ARGV[0] or die "IO::Uncompress::Gunzip failed\n";
while (<$file>) {
    print;
}


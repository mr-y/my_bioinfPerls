#! /usr/bin/perl

# The script should get a string with new and old names after the switch -c
# e.g. old_name1|new_name1,old_name2|new_name2, and the last argument should be the file name
# output is given to STDOUT

use strict;
use warnings;

my $file_name;
my %seq_names;

for (my $i=0; $i< scalar @ARGV; ++$i) {
    if ($ARGV[$i] eq '-c') {
	if (++$i < scalar @ARGV) {
	    my @temp = split /,/, $ARGV[$i];
	    foreach my $pair (@temp) {
		my ($old, $new) = split /\|/, $pair;
		$seq_names{$old} = $new;
	    }
	}
	else { die "-c require a comma separated string where old and new names are separated by |, e.g. old_name1|new_name1,old_name2|new_name2.\n" }
    }
    if ($i == (scalar @ARGV -1)) { $file_name = $ARGV[$i]; }
}

my $FH;

open $FH, '<', $file_name or die "Could not open $file_name: $!\n";

while (<$FH>) {
    chomp;
    if (s/^>//) {
	s/\s+$//;
	if (defined $seq_names{$_}) {
	    print ">$seq_names{$_}\n";
	}
	else { print ">$_\n"; }
    }
    else { print; print "\n"; }

}

close $FH;

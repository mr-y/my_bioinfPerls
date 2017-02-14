#! /usr/bin/perl -w

# Calculates the total length, number of scaffolds, N50, and L50 for a given fasta file (or STDIN)

use strict;

my @lengths;
my $total=0;
my $seq;

while (<>) {
    chomp;
    if (/^>/ && $seq) {
	push @lengths, length $seq;
	$total += length $seq;
	$seq = '';
    }
    else { s/\s+//g; $seq .= $_; }
}
push @lengths, length $seq;
$total += length $seq;
@lengths = sort {$a <=> $b} @lengths;
my $sum=0;
my $i;
for ($i = 0; $sum < $total/2 && $i < scalar @lengths; ++$i) {
    $sum += $lengths[$i];
    #print "$lengths[$i]\n";
}
print "Total length: $total bp\n";
print "Number of scaffolds: ", scalar @lengths, "\n";
print "N50: $lengths[$i-1] bp\n";
print "L50: $i\n";

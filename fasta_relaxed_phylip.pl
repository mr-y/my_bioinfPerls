#!/usr/bin/perl -w

use strict;
my @accnos;
my @seq;
my $counter=0;

if ($ARGV[0] eq '-h' || $ARGV[0] eq '--help') {
    print "This script takes a fasta file as input, either on STDIN or with the name of the\nfile given as an argument to the script, and convert the file to relaxed phylip\nformat (e.g. for RAxML).\n";
    exit;
}

while (my $input=<>) {
    chomp($input);
    if ($input =~ /^>/) {
        $accnos[$counter++] = $input;
    }
    else { $seq[$counter-1] .= $input; }
}
foreach (@seq) { $_ =~ s/[^a-zA-Z\-?]//g; }
foreach (@accnos) { $_ =~ s/^>//; }
foreach (@accnos) { $_ =~ s/[\(\)|:,;\[\]\t\'\" ]+/_/g; }
my $max_length=0;
foreach (@accnos) { if (length($_) > $max_length) { $max_length=length($_); } }

print scalar @accnos . " " . length $seq[0];
print "\n";

for (my $i=0; $i < scalar @accnos; ++$i) {
    print ($accnos[$i], (' ' x ($max_length+1-length($accnos[$i]))), "$seq[$i]\n");
}

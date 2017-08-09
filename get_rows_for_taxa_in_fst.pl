#! /usr/bin/perl -w

# This script will get the rows in a tab delimited file where the first columns match names in a fasta file

use strict;
my $fasta_file;
my $table_file;
my $sep = "\t";

sub help {
    print "This script will print the rows in a table (given by -t/--table) where the first\n";
    print "column is present as a name in a fasta file (given by -f/--fasta). E.g:\n\n";
    print "perl get_rows_for_taxa_in_fst.pl -f my.fst -t my.tab\n\n";
    exit;
}


for (my $i=0; $i < scalar @ARGV; ++$i) {
    if ($ARGV[$i] eq '-t' || $ARGV[$i] eq '--table') {
        if ($i < scalar @ARGV -1 && $ARGV[$i+1]=~/^[^-]/) {
            $table_file = $ARGV[++$i];
        }
	else { die "--table/-t require a file name as next argument.\n"; }
    }
    elsif ($ARGV[$i] eq '-f' || $ARGV[$i] eq '--fasta') {
        if ($i < scalar @ARGV -1 && $ARGV[$i+1]=~/^[^-]/) {
            $fasta_file = $ARGV[++$i];
        }
	else { die "--fasta/-f require a file name as next argument.\n" }
    }
    elsif ($ARGV[$i] eq '-s' || $ARGV[$i] eq '--separator') {
        if ($i < scalar @ARGV -1 && $ARGV[$i+1]=~/^[^-]/) {
            $sep = $ARGV[++$i];
        }
	else { die "--separator/-s require a character or string as next argument\n"; }
    }
    elsif ($ARGV[$i] eq '-h' || $ARGV[$i] eq '--help') {
	&help();
    }
}
my $FASTA;
my $TABLE;

if (!$fasta_file && !$table_file) { die "Need a fasta and a table file.\n" }
else {
    if ($fasta_file) {
        open $FASTA, '<', $fasta_file || die "Could not open $fasta_file: $!.\n";
    }
    if ($table_file) {
        open $TABLE, '<', $table_file || die "Could not open $table_file: $!.\n";
    }
    if (!$FASTA) { $FASTA = *STDIN; print STDERR "Expecting fasta input through STDIN.\n"; }
    if (!$TABLE) { $TABLE = *STDIN; print STDERR "Expecting table input through STDIN.\n"; }
}
my %names;
while (my $row = <$FASTA>) {
    chomp $row;
    if ($row =~ s/^>//) {
        $row =~ s/\s+$//;
        $names{$row} = 1;
    }
}
close $FASTA;

while (my $row = <$TABLE> {
    chomp $row;
    @temp = split /$sep/, $row;
    if (defined($names{$temp[0]}) {
        if ($names{$temp[0]} <= 0) {
            print STDERR "$temp[0] is found more than once in table.\n";
        }
        print "$row\n";
        --$names{$temp[0]};
    }
}

foreach (keys %names) {
    if ($names{$_} >0) {
        print STDERR "$_ in fasta file was not found in table.\n";
    }
}


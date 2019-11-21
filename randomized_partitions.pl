#! /usr/bin/perl

use warnings;
use strict;

my @files;
my @order;
my %sequences;
my @partitionlengths;
my $n_rep = 1;

sub help {
    print "Give fasta files with separate partitions as arguments to the program.\n";
    print "Number of replicats can be given by -n/--number_of_repetitions/--n_rep.\n";
    print "The randomised partitions will be written to files based on the given file name\nwith the added extention .rep and the number for that replicate.";
    print "\nWARNING!!! The program has not been extensively tested or validated.\n";
    exit;
}

for (my $i=0; $i < scalar @ARGV; ++$i) {
    if ($ARGV[$i] =~ /^-/) {
	if ($ARGV[$i] eq '-h' || $ARGV[$i] eq '--help') {
	    &help();
	}
	if ($ARGV[$i] eq '-n' || $ARGV[$i] eq '--number_of_repetitions' || $ARGV[$i] eq '--n_rep') {
	    if ($i+1 >= scalar @ARGV || $ARGV[$i+1] =~ /^-/) {
		die "-n/--number_of_repetitions require an integer as next argument.\n";
	    }
	    else { $n_rep = $ARGV[++$i]; }
	}
	else {
	    die "Unknown argument $ARGV[$i]. Give -h as argument for help."
	}
    }
    else {
	push @files, $ARGV[$i];
    }
}

my $totlength = 0;

for (my $i=0; $i < scalar @files; ++$i) {
    open INPUT, "<", $files[$i] or die "Could not open file $files[$i]: $!\n";
    $partitionlengths[$i] = 0;
    my %seqs;
    my $name;
    while (<INPUT>) {
	chomp;
	if (s/^>//) {
	    if (defined $name) {
		if (length $seqs{$name} > $partitionlengths[$i]) { $partitionlengths[$i] = length $seqs{$name}; }
	    }
	    $name = $_;
	    $seqs{$name} = '';
	    if (!defined $sequences{$name}) { push @order, $name; $sequences{$name} = '-' x $totlength; }
	}
	elsif (defined $name) {
	    s/\s//g;
	    $seqs{$name} .= $_;
	}
    }
    if (defined $name) {
	if (length $seqs{$name} > $partitionlengths[$i]) { $partitionlengths[$i] = length $seqs{$name}; }
    }
    foreach $name (keys %seqs) {
	if (length $seqs{$name} > $partitionlengths[$i]) { $seqs{$name} .= '-' x ($partitionlengths[$i] - length $seqs{$name}); }
	if (length $sequences{$name} < $totlength) { $sequences{$name} .= '-' x ($totlength-length $sequences{$name}); }
	$sequences{$name} .= $seqs{$name};
    }
    $totlength += $partitionlengths[$i];
    close INPUT;
}

my @columns;

for (my $i=0; $i < $totlength; ++$i) {
    push @columns, $i;
}

for (my $rep = 0; $rep < $n_rep; ++$rep) {
    my @randomorder = &fisher_yates_shuffle(@columns);
    my $start = 0;
    for (my $i=0; $i < scalar @files; ++$i) {
	open OUTPUT, '>', "$files[$i].rep$rep" or die "Could not open $files[$i].rep$rep: $!.";
	foreach my $name (@order) {
	    if (length $sequences{$name} < $totlength) { $sequences{$name} .= '-' x ($totlength-length $sequences{$name}); }
	    print OUTPUT ">$name\n";
	    for (my $pos = 0; $pos < $partitionlengths[$i]; ++$pos) {
		print OUTPUT substr $sequences{$name}, $columns[$start+$pos], 1;
	    }
	    print OUTPUT "\n";
	}
	close OUTPUT;
	$start += $partitionlengths[$i];
    }
}

sub fisher_yates_shuffle {
    my $i = scalar @_;
    while ($i--) {
	my $j = int rand ($i+1);
	@_[$i,$j] = @_[$j,$i];
    }
    return @_;
}

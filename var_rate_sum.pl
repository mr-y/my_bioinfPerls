#! /usr/bin/perl

use warnings;
use strict;

my @taxa;

my $n;

my @nodes;

my $mode = 'S';

my $n_gen;

while (<>) {
    chomp;
    if ($mode eq 'S') {
	$n = $_;
	$mode = 'T';
    }
    elsif ($mode eq 'T') {
	my ($number,$name) = split /\s+/;
	$taxa[$number] = $name;
	if ($number+1 == $n) { $mode = '#'; print STDERR "Read ", scalar @taxa, " taxa\n"; }
    }
    elsif ($mode eq '#') {
	$n = $_;
        $mode = 'N';
    }
    elsif ($mode eq 'N') {
	my ($number,$branch_length,$n_taxa,@taxa) = split /\s+/;
	if ($n_taxa != scalar @taxa) { print STDERR "Parsing or file incosistency for node $number.\n"; }
	$nodes[$number] = {};
	$nodes[$number]->{taxa} = \@taxa;
	if ($number+1 == $n) { $mode = 'C'; print STDERR "Read ", scalar @nodes, " nodes\n"; }
    }
    elsif ($mode eq 'C') {
	if (!/^It/) {
	   my @columns = split /\t/;
	   for (my $i=7; $i+4 < scalar @columns; $i += 4) {
		++$nodes[$columns[$i]]{$columns[$i+3]};
		#print STDERR "$columns[$i], $columns[$i+3] = $nodes[$columns[$i]]{$columns[$i+3]}\t"; 
	   }
	   #print STDERR "\n";
	   ++$n_gen;
	}
    }
}

my @order;

for (my $i=0; $i < scalar @nodes; ++$i) {
    if ($i==0) { $order[$i] = $i; }
    else {
	if (!defined($nodes[$i]->{Node})) { push @order, $i; }
	else {
	    my $value_to_move;
	    for (my $j=0; $j < scalar @order; ++$j) {
		if (defined $value_to_move) {
		    my $temp = $order[$j];
		    $order[$j] = $value_to_move;
		    $value_to_move = $temp;
		}
		elsif ( !defined($nodes[$order[$j]]->{Node}) || $nodes[$i]->{Node} > $nodes[$order[$j]]->{Node} ) {
		    $value_to_move = $order[$j];
		    $order[$j] = $i;
		}
	    }
	    if ($value_to_move) { push @order, $value_to_move; }
	    else { push @order, $i; }
	}
    }
}

print STDERR "Ordered ", scalar @order, " nodes\n";

foreach my $node (@order) {
    print $node, "\t";
    foreach (@{$nodes[$node]->{taxa}}) { print "$taxa[$_],"; }
    print "\t";
    if (defined $nodes[$node]->{Node}) { print "", ($nodes[$node]->{Node}/$n_gen), " ($nodes[$node]->{Node})"; }
    else { print "0"; }
    print "\t";
    if (defined $nodes[$node]->{Branch}) { print "", ($nodes[$node]->{Branch}/$n_gen), " ($nodes[$node]->{Branch})"; }
    else { print "0"; }
    print "\n"
}


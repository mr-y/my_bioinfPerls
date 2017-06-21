#! /usr/bin/perl -w

use strict;

my $sep="\t";
my $filename;
my $INPUT = *STDIN;
my $branch_length;
sub help {
    print "This script will make a phylogeny of a hirarchial taxonomy. Each terminal taxon\n";
    print "should be given on a row with the taxa it is nested in to its left. The\n";
    print "hirarchy for each taxon is assumed to be complete (i.e. the same taxon name\n";
    print "given in different position/column are considered to be different). Rows\n";
    print "starting with # will be ignored. Usage:\n\n";
    print "perl taxonomy_to_tree.pl [options] taxonomy_file.txt\n\n";
    print "Options:\n";
    print "-b/--branch_length [number] will give the length of each branch in the tree\n";
    print "                            (default: no branch length)\n";
    print "-f/--file [file name]       will give the name of the input file (default:\n";
    print "                            STDIN)\n";
    print "-h/--help                   will print this help\n";
    print "-s/--separator [string]     will give the separator between the ranks in the\n";
    print "                            hirarchy (default: tab [\\t])\n";
    exit;
}
for (my $i=0; $i < scalar @ARGV; ++ $i) {
    if ($ARGV[$i] eq '-s'|| $ARGV[$i] eq '--separator') {
	if ($i+1 < scalar @ARGV && defined($ARGV[$i+1])) {
	    $sep=$ARGV[++$i];
	}
	else { die "--separator/-s need a separator as next argument.\n"; }
    }
    elsif ($ARGV[$i] eq '-b' || $ARGV[$i] eq '--branch_length') {
	if ($i+1 < scalar @ARGV && $ARGV[$i+1]=~ /^[^-]/) {
	    $branch_length = $ARGV[++$i];
	}
	else { die "--branch_length/-b need a number as next argument.\n"; }
    }
    elsif ($ARGV[$i] eq '-f' || $ARGV[$i] eq '--file') {
	if ($i+1 < scalar @ARGV && $ARGV[$i+1]=~ /^[^-]/) {
	    $filename = $ARGV[++$i];
	}
	else { die "--file/-f need a file name as next argument.\n"; }
    }
    elsif ( $ARGV[$i] eq '-h' || $ARGV[$i] eq '--help') {
	&help();
    }
    elsif ( $i+1 == scalar @ARGV ) {
	$filename = $ARGV[$i];
    }
    else { die "Do not recognize argument $ARGV[$i].\n"; }
}
if ($filename) {
    open $INPUT, '<', $filename or die "Could not open $filename: $!.\n";
}
my %tree;
# pars file
while (my $row = <$INPUT>) {
    chomp $row;
    if ($row =~ /^#/) { next; }
    my @columns = split /$sep/, $row;
    my $hash_ref = \%tree;
    for (my $i=0; $i < scalar @columns; ++$i) {
	if ($hash_ref->{$columns[$i]}) {
	    $hash_ref = \%{$hash_ref->{$columns[$i]}};
	}
	else { 
	    $hash_ref->{$columns[$i]} = {};
	    $hash_ref = \%{$hash_ref->{$columns[$i]}};
	}
    }
}
# print tree
#print "N branches from root: ", scalar keys %tree, ".\n";
&print_hash_as_tree(\%tree,'',$branch_length);
print ";\n";
sub print_hash_as_tree {
    my $ref = shift;
    my $taxon = shift;
    my $branch_length = shift;
    #print "$taxon\n";
    my @keys = keys %{$ref};
    if (scalar @keys) {
	print '(';
	for (my $i=0; $i < scalar @keys; ++$i) {
	    if ($i) { print ','; }
	    &print_hash_as_tree(\%{$ref->{$keys[$i]}},$keys[$i],$branch_length);
	}
	print ")$taxon";
	if ($branch_length) { print ":$branch_length"; }
    }
    else { print $taxon; }
}

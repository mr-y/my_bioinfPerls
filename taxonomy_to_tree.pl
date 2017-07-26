#! /usr/bin/perl -w

use strict;

my $sep="\t";
my $filename;
my $INPUT = *STDIN;
my $branch_length;
my $mearge_taxon_on_single_branch = 'n';

sub help {
    print "This script will make a phylogeny of a hirarchial taxonomy. Each terminal taxon\n";
    print "should be given on a row with the taxa it is nested in to its left. The\n";
    print "hirarchy for each taxon is assumed to be complete (i.e. the same taxon name\n";
    print "given in different position/column are considered to be different). Rows\n";
    print "starting with # will be ignored. Usage:\n\n";
    print "perl taxonomy_to_tree.pl [options] taxonomy_file.txt\n\n";
    print "Options:\n";
    print "-b/--branch_length [number] will give the length of each branch in the tree\n";
    print "                            (default: no branch lengths). Alternatively it can\n";
    print "                            take a file with the taxon name in the first column\n";
    print "                            and the branch length in the second column. It is\n";
    print "                            also possible to give a default branch length by\n";
    print "                            giving default in the first column and the default\n";
    print "                            branch length in the second. The column separator\n";
    print "                            should be the same as for the taxonomy.\n";
    print "-f/--file [file name]       will give the name of the input file (default:\n";
    print "                            STDIN)\n";
    print "-h/--help                   will print this help\n";
    print "-m/--mearge_monotypic       will give one branch instead of a series of branches\n";
    print "                            when taxa are monotypic\n";
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
    elsif ($ARGV[$i] eq '-m'|| $ARGV[$i] eq '--mearge_monotypic') {
	$mearge_taxon_on_single_branch = 'y';
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
	$columns[$i] =~ s/^\s+//;
	$columns[$i] =~ s/\s+$//;
	if ($hash_ref->{$columns[$i]}) {
	    $hash_ref = \%{$hash_ref->{$columns[$i]}};
	}
	else { 
	    $hash_ref->{$columns[$i]} = {};
	    $hash_ref = \%{$hash_ref->{$columns[$i]}};
	}
    }
}
my %taxon_branches;
if (defined($branch_length) && $branch_length =~ /\D/) {
    print STDERR "Will read taxon branch lengths from file $branch_length.\n";
    open LENGTHS, '<', $branch_length || die "Could not open $branch_length: $!.\n";
    while (my $row = <LENGTHS>) {
	if ($row =~ /^#/) { next; }
	my @temp = split /$sep/, $row;
	$temp[0] =~ s/^\s+//;
	$temp[0] =~ s/\s+$//;
	if ($temp[0] =~ /default/i) { $temp[0] = lc $temp[0]; }
	if ($temp[0]) { $taxon_branches{$temp[0]} = $temp[1]; }
    }
    if (!defined($taxon_branches{'default'})) { $taxon_branches{'default'} = 0; }
}
else { $taxon_branches{'default'} = $branch_length; }
$branch_length = \%taxon_branches;

# print tree
# print "N branches from root: ", scalar keys %tree, ".\n";
&print_hash_as_tree(\%tree,'',$branch_length,0,$mearge_taxon_on_single_branch);
print ";\n";
sub print_hash_as_tree {
    my $ref = shift;
    my $taxon = shift;
    my $branch_length = shift;
    my $extra_branch_length = shift;
    my $mearge_branches = shift;
    #print "$taxon\n";
    my @keys = keys %{$ref};
    if (scalar @keys) {
	my $add_branch_length=0;
	if ($mearge_branches eq 'n' || scalar @keys > 1) { print '('; }
	elsif (defined $branch_length) {
	    if (defined($branch_length->{$taxon})) { $add_branch_length = $extra_branch_length + $branch_length->{$taxon}; }
	    elsif ($branch_length && defined($branch_length->{'default'})) { $add_branch_length = $extra_branch_length + $branch_length->{'default'}; }
	}
	for (my $i=0; $i < scalar @keys; ++$i) {
	    if ($i) { print ','; }
	    &print_hash_as_tree(\%{$ref->{$keys[$i]}},$keys[$i],$branch_length,$add_branch_length,$mearge_branches);
	}
	if ($mearge_branches eq 'n' || scalar @keys > 1) {
	    print ")$taxon";
	    if (defined($branch_length)) {
		if (!defined($branch_length->{$taxon})) { $taxon = 'default'; }
		print ':', $branch_length->{$taxon}+$extra_branch_length;
	    }
	}
    }
    else {
	print $taxon;
	if (defined($branch_length)) {
	    if (!defined($branch_length->{$taxon})) { $taxon = 'default'; }
	    print ':', $branch_length->{$taxon}+$extra_branch_length;
     	}
    }
}

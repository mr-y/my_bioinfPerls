#! /usr/bin/perl -w

use strict;

my $alignment_program = "linsi --thread 4"; #give alignment command up until sequence infile
my $exclude_file;
my $partition_file;
my $alignment_file;

for (my $i=0; $i < scalar @ARGV; ++$i) {
    if ($ARGV[$i] eq '-E' && $ARGV[$i+1] =~ /^[^-]/ && -e $ARGV[$i+1]) { $exclude_file=$ARGV[++$i] }
    elsif ($ARGV[$i] eq '-p' && $ARGV[$i+1] =~ /^[^-]/ && -e $ARGV[$i+1]) { $partition_file=$ARGV[++$i] }
    elsif ($ARGV[$i] eq '-f' && $ARGV[$i+1] =~ /^[^-]/ && -e $ARGV[$i+1]) { $alignment_file=$ARGV[++$i] }
    elsif ($ARGV[$i] eq '-C' && $ARGV[$i+1] =~ /^[^-]/) { $alignment_program=$ARGV[++$i] }
    else { die "Do not recognize argument $ARGV[$i]!!!\n"; }
}

my %partitions;
my @partition_order;

my %exclude_taxa;

if ($exclude_file) {
    open FILE, "<$exclude_file" or die "Could not open $exclude_file: $!.\n";
    while (<FILE>) {
	chomp;
	if(!/^#/) { $exclude_taxa{$_}++; }
    }
    close FILE;
}

if ($partition_file) {
    open FILE, "<$partition_file" or die "Could not open $partition_file: $!.\n";
    while (<FILE>) {
        chomp;
	if (/DNA,\s*(\w+)\s*=\s*([0-9\-]+)/) {
	    $partitions{$1} = $2;
	    push @partition_order, $1;
	}
    }
    close FILE;
}
else { die "Need a partition file, given after argument -p\n"; }

if ($alignment_file) {
    foreach my $section (@partition_order) {
	my ($start,$end) = split /-/, $partitions{$section};
	if ($start && $end && $start < $end) {
	    open FILE, "<$alignment_file" or die "Could not open $alignment_file: $!.\n";
	    open PARTITION, ">partition_$section.fst" or die "Could not open partition_$section.fst: $!.\n";
	    my $sequence;
	    my $name;
	    while (<FILE>) {
		chomp;
		if (s/^>//) {
		    if ($name && !$exclude_taxa{$name}) {
			if ($sequence) {
			    print PARTITION ">$name\n", substr($sequence,$start-1,$end-$start), "\n";
			}
			#print PARTITION ">$_\n";
		    }
		    $name = $_;
		    undef $sequence;
		}
		else {
		    s/\s//g;
		    if ($sequence) { $sequence .= $_; }
		    else { $sequence = $_; }
		}
	    }
    	    if ($sequence && !$exclude_taxa{$name}) {
		print PARTITION ">$name\n", substr($sequence,$start-1,$end-$start), "\n";
		undef $sequence;
	    }
	    close PARTITION;
	    close FILE;
	    system "$alignment_program partition_$section.fst > partition_$section.aln";
	    #unlink "partition_$section.fst";
	}
	else { die "Failure to parse start or end of partition $section.\n"; }
    }
    my %catenated_seq;
    my $start = 1;
    open PARTITION, ">new_$partition_file"  or die "Could not open new_$partition_file: $!.\n";
    my $length=0;
    foreach my $section (@partition_order) {
	my $name;
	open FILE, "<partition_$section.aln" or die "Could not open partition_$section.aln: $!.\n";
	while (<FILE>) {
	    chomp;
	    if (/^>/) { $name = $_; }
	    elsif ($name) {
		s/\s//g;
		if ($catenated_seq{$name}) { $catenated_seq{$name} .= $_; }
		else { $catenated_seq{$name} = $_; }
		if (length $catenated_seq{$name} > $length) { $length = length $catenated_seq{$name}; }
	    }
	}
	close FILE;
	#unlink "partition_$section.aln";
	if ($length > $start) { 
	    print PARTITION "DNA, $section = ", $start, '-', $length, "\n";
	    $start = $length+1;
	}
	else { print STDERR "No alignment for $section.\n"; }
    }
    close PARTITION;
    open FILE, ">new_$alignment_file" or die "Could not open new_$alignment_file: $!.\n";
    foreach (keys %catenated_seq) {
	print FILE $_, "\n", $catenated_seq{$_}, "\n";
    }
}
else { die "Need an alignment file, given after argument -f\n"; }

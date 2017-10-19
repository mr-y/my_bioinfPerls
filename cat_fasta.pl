#! /usr/bin/perl

use strict;
use warnings;

sub help {
    print "cat_fasta.pl will concatenate sequences for the same OTU (identified by name).\n";
    print "Sequences to concatenate should be given in separate in FASTA format in\n";
    print "separate files. The filenames can be given as the last arguments of by -f.\n";
    print "If the same name apears more than once in the same file the sequences will be\n";
    print "concatenated to the same OTU.\n";
    print "Usage:\nperl cat_fasta.pl [argvs] file1 file2 ...\nperl cat_fasta.pl -f file1 file2 ... [argvs]\n\n";
    print "Arguments (argvs):\n";
    print "-f / --files [list of files] will read the next arguments up until flag (-) as\n";
    print "                             sequence file names\n";
    print "-n / --name [name]           will read next argument as output file name\n";
    print "-h / --help                  will print this help.\n";
    exit;
}

my $OUTPUT=*STDOUT; # For output of cat sequences
my @seq_files;
my $output_file_name;
my $i = 0; # Iterator

#print STDERR "@ARGV\n";

for ($i=0; $i < scalar @ARGV; ++$i) {
    if ($ARGV[$i] eq '-n' || $ARGV[$i] eq '--name') {
	++$i;
	if ($ARGV[$i] =~ /^[^-]/ && $i < scalar @ARGV) {
	    if (-e $ARGV[$i]) {
		print STDERR "The file $ARGV[$i] already exist should it be overwritten (n/y):\n";
		my $answer = <STDIN>;
		if ($answer =~ /^[^Yy]/) { die "Will not overwrite $ARGV[$i], try again with different name for output.\n"; }
	    }
	    $output_file_name = $ARGV[$i];
	    open $OUTPUT, '>', $ARGV[$i] or die "Could not open $ARGV[$i]: $!.";
	}
	else { die "--name/-n require a name as next argument.\n"; }
    }
    elsif ($ARGV[$i] eq '-f' || $ARGV[$i] eq '--files') {
	for (++$i; $i < scalar @ARGV && $ARGV[$i] =~ /^[^-]/; ++$i) {
	    if (-e $ARGV[$i]) { push @seq_files, $ARGV[$i]; }
	    else { die "Could not find the file $ARGV[$i].\n"; }
	}
    }
    elsif ($ARGV[$i] eq '-h' || $ARGV[$i] eq '--help') { &help(); }
    elsif ($ARGV[$i] =~ /^-/) { die "Unrecognized argument: $ARGV[$i]. For list of recognized arguments give -h / --help.\n"; }
    else { last; }
}
#print STDERR ($i, " ", scalar @ARGV, " ", scalar @seq_files, "\n");
if ($i < scalar @ARGV && scalar @seq_files < 1) {
    for (; $i < scalar @ARGV && $ARGV[$i] =~ /^[^-]/; ++$i) {
	if (-e $ARGV[$i]) { push @seq_files, $ARGV[$i]; }
 	else { die "Could not find the file $ARGV[$i].\n"; }
    }
}
elsif ($i < scalar @ARGV) {
    die "Do not recognize $ARGV[$i]";
}
my %sequences;
my $PARTITIONS;
if ($output_file_name) {
    open $OUTPUT, '>', $output_file_name or die "Could not open $output_file_name: $!.\n";
    open $PARTITIONS, '>', "$output_file_name.partitions.txt" or die "Could not open $output_file_name.partitions.txt: $!.\n";
}
else {
    open $PARTITIONS, '>', "partitions.txt" or die "Could not open partitions.txt: $!.\n";
}

if (scalar @seq_files > 0) {
    my $max_length = 0;
    my $start_length = 0;
    foreach my $file (@seq_files) {
	my $INPUT;
	if ($file) {
	    open $INPUT, '<', $file or die "Could not open $file: $!.\n";
	    my $name;
	    while (<$INPUT>) {
		chomp;
		if (s/^>//) {
		    s/^\s+|\s+//g;
		    $name = $_;
		}
		elsif ($name) {
		    if (!$sequences{$name}) { $sequences{$name} = '-' x $start_length; }
		    $sequences{$name} .= $_;
		    if (length $sequences{$name} > $max_length) { $max_length = length $sequences{$name}; }
		}
	    }
	    close $INPUT;
	    print $PARTITIONS "$file = " . ($start_length+1) . "-$max_length\n";
	    foreach (keys %sequences) {
		my $length = length $sequences{$_};
		if ($length < $max_length) { $sequences{$_} .= '-' x ($max_length-$length); }
		elsif ($length > $max_length) { print STDERR "WARNING!!! Sequence length fault for $_ while reading $file.\n"; }
	    }
	    $start_length = $max_length;
	}
    }
    foreach my $name (keys %sequences) {
	print $OUTPUT ">$name\n$sequences{$name}\n"
    }
}
else {
    die "No sequence files.\n";
}

if ($output_file_name) { close $OUTPUT; }
close $PARTITIONS;

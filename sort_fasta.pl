#! /usr/bin/perl -w

use strict;

my $alignment = '';
my @order;
my $order_file;
my $tree_file;

for (my $i=0; $i < scalar @ARGV; ++$i) {
    if (($ARGV[$i] eq '-f' || $ARGV[$i] eq '--file') && ($ARGV[$i+1])) { $alignment = $ARGV[++$i]; }
    elsif (($ARGV[$i] eq '-o' || $ARGV[$i] eq '--order') && ($ARGV[$i+1])) { @order = split /,/, $ARGV[++$i]; }
    elsif (($ARGV[$i] eq '-r' || $ARGV[$i] eq '--order_file') && ($ARGV[$i+1])) { $order_file = $ARGV[++$i]; }
    elsif (($ARGV[$i] eq '-t' || $ARGV[$i] eq '--tree_file') && ($ARGV[$i+1])) { $tree_file = $ARGV[++$i]; }
    elsif ($ARGV[$i] eq '-h' || $ARGV[$i] eq '--help') { &help(); }
}

if (!$alignment || !(-e $alignment)) { die "Could not find $alignment. Dying.\n"; }
if ($order_file && -e $order_file) {
    open FILE, "<$order_file" or die "Could not open $order_file\n";
    my $i = 0;
    while (my $infile = <FILE>) {
	chomp $infile;
	$order[$i++] = $infile;
    }
    close FILE;
}
elsif ($tree_file && -e $tree_file) {
    open FILE, "<$tree_file" or die "Could not open $tree_file\n";
    my $input = <FILE>;
    close FILE;
    chomp $input;
    if ($input =~ s/\(|(\)[0-9\.]*)|;|,[0-9\.]*|:[0-9\.]*/,/g) {
	while($input =~ s/,,/,/g) { }
	$input =~ s/(^,)|(,$)//g;
	@order = split /,/, $input;
    }
    else { die "No tree in $tree_file.\n"; }
}

my %sequences;

open ALIGNMENT, "<$alignment" or die "Could not open $alignment\n";
my $name;
while (my $input = <ALIGNMENT>) {
    if ($input =~ s/^>//) {
	chomp $input;
	$name = $input;
	$sequences{$name} = '';
    }
    elsif ($name) { $sequences{$name} .= $input; }
}

close ALIGNMENT or die;

foreach (@order) {
    if ($sequences{$_}) {
	print '>', $_, "\n", $sequences{$_};
    }
    else { print STDERR "No sequence for $_!\n"; }
}

sub help {
    print "sort_fasta.pl needs an alignment file given after the argument -f or --file.\n";
    print "It also need the order to sort the sequences in the alignment. This can be\n";
    print "given by a comma separated string following the argument -o or --order, in a\n";
    print "file given following the argument -r or --order_file where the sequence name are\n";
    print "given in order on separate rows (and nothing else), or by a tree in a file whose\n";
    print "name is given following the argument -t or --tree_file.\n";
}

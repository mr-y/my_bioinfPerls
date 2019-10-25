#! /usr/bin/perl

use strict;
use warnings;

my %tips;
my %colorNames = (
    "BLACK" => "000000",
    "GREY" => "BEBEBE",
    "WHITE" => "FFFFFF",
    "BLUE" => "0000FF",
    "BROWN" => "A52A2A",
    "GREEN" => "00FF00",
    "ORANGE" => "FFA500",
    "PINK" => "FFC0CB",
    "RED" => "FF0000",
    "PURPLE" => "A020F0",
    "VIOLET" => "EE82EE",
    "YELLOW" => "FFFF00"
    );
my $treefile = "";
my $colorfile = "";
my $sep = "\t";

sub help {
    print "addFigtreeCol.pl add color to tips in a nexus formated tree in a way that can be\n";
    print "viewed in Figtree. It takes a tree file given after -t and a tab delimited table\n";
    print "given after -c. The table should have the taxon lable to color in the first\n";
    print "column and the color given by RBG hex in the second red (FF0000) default (if no\n";
    print "color given.\n";
    exit;
}

if (scalar @ARGV < 1) { &help(); }
for (my $i=0; $i < scalar @ARGV; ++$i) {
    if ($ARGV[$i] eq "-h" || $ARGV[$i] eq "--help") { &help(); }
    elsif ($ARGV[$i] eq "-t" || $ARGV[$i] eq "--tree") {
	++$i;
	if ($i < scalar @ARGV && !($ARGV[$i] =~ /^-/)) {
	    $treefile = $ARGV[$i];
	}
	else {
	    die "-t / --tree require the name on the nexus file containing the tree as the next argument\n";
	}
    }
    elsif ($ARGV[$i] eq "-c" || $ARGV[$i] eq "--color" || $ARGV[$i] eq "--colour") {
        ++$i;
        if ($i < scalar @ARGV && !($ARGV[$i] =~ /^-/)) {
            $colorfile = $ARGV[$i];
        }
        else {
            die "-c / --color require the name on the file containing the tips to color as next argument\n";
        }
    }
    elsif ($ARGV[$i] eq "-s" || $ARGV[$i] eq "--sep" || $ARGV[$i] eq "--separator") {
        ++$i;
        if ($i < scalar @ARGV && !($ARGV[$i] =~ /^-/)) {
            $sep = $ARGV[$i];
        }
        else {
            die "-s / --separator require the character(s) used to separate columns in the table woth colors as next argument.\n";
        }
    }
    else { die "Unknown argument $ARGV[$i].\n"; }
}

my $COLOR;
if ($colorfile) {
    open $COLOR, "<", $colorfile or die "Could not open $colorfile: $!\n";
}
else { die "No file for colors on tips given.\n"; }

while (<$COLOR>) {
    chomp;
    my ($taxon, $color) = split /$sep/;
    if (!$taxon) { next; }
    if (!$color) { $color = 'RED'; }
    $color =~ s/^\s+//;
    $color =~ s/\s+$//;
    $taxon =~ s/^\s+//;
    $taxon =~ s/\s+$//;
    $color = uc($color);
    if (!$color) { $color = 'RED'; }
    if ($colorNames{$color}) { $color = $colorNames{$color}; }
    if ($color =~ /[^0123456789ABCDEF]/) {
	die "Unknown color $color for $taxon.\n";
    }
    $tips{$taxon} = $color;
}

close $COLOR;

my $TREE;
if ($treefile) {
    open $TREE, "<", $treefile or die "Could not open $treefile: $!\n";
}
else { die "No tree file given\n"; }

my $taxlabelsFlag = 'F';
while (my $row = <$TREE>) {
    if ($row =~ /\btaxlabels\b/i) { $taxlabelsFlag = 'T'; }
    if ($taxlabelsFlag eq 'T') {
	my $temp = $row;
	$temp =~ s/^\s+//;
	$temp =~ s/\s+$//;
	$temp =~ s/\[.*\]//;
	if ($tips{$temp}) {
	    if ($row =~ /\[&!(.*)\]/) {
		my $annotations = $1;
		if ($annotations =~ /color=#[0123456789ABCDEF]{6}/) {
		    my $newAnnotations = $annotations;
		    $newAnnotations =~ s/color=#[0123456789ABCDEF]{6}/color=#$tips{$temp}/;
		    $row =~ s/$annotations/$newAnnotations/;
		}
		else { $row =~ s/\[&!/\[&!color=#$tips{$temp}/; }
	    }
	    else {
		$row =~ s/$temp/$temp\[&!color=#$tips{$temp}\]/
	    }
	}
    }
    if ($taxlabelsFlag eq 'T' && $row =~ /;/) { $taxlabelsFlag = 'E'; }
    print $row;
}

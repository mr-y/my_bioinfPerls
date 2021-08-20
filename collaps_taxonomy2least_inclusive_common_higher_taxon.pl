#! /usr/bin/perl

# This script will collapse taxon strings to the lowest level taxon common to the
# OTU The lowest level taxon is assumed to be the OTU. It is written in response
# to that the UNITE taxonomy is not always consistent, putting the same SH in
# separate species for different sequences.

# It should be called with [options] files

use strict;
use warnings;

my @order;
my %OTUs;
my $separator="\t";

my $i;
for ($i=0; $i < scalar @ARGV; ++$i) {
    if ($ARGV[$i] eq "-s") {
	++$i;
	if ($i < scalar @ARGV && !($ARGV[$i] =~ /^-/)) {
	    $separator=$ARGV[$i];
	}
	else { die "-s require a character as next argument!\n"; }
    }
    elsif (!($ARGV[$i] =~ /^-/)) { last; }
    else { die "Unknown argument: $ARGV[$i].\n"; }
}

# The rest of the arguments should be files
for (; $i < scalar @ARGV; ++$i) { # For each file
    open INPUTFILE, "<", $ARGV[$i] or die "Could not open $ARGV[$i]: $!\n";
    while (<INPUTFILE>) {
	chomp;
	if (/^#/) { push @order, $_; } # Ignore rows starting with #, but keep them for output
	else {
	    my @taxa = split /$separator/; # separate taxon levels
	    if ($taxa[-1]) { # need at least one taxon
		my $OTU = pop @taxa; # get lowest level taxon
		if (!$OTUs{$OTU}) { # if not present before add
		    $OTUs{$OTU} = join "$separator", @taxa;
		    push @order, $OTU; # print at first occurrence
		}
		else { # If present before compare taxon strings
		    my @comp_list = split /$separator/, $OTUs{$OTU};
		    $OTUs{$OTU} = "";
		    for (my $j=0; $j < scalar @taxa && $j < scalar @comp_list; ++$j) {
			if ($taxa[$j] eq $comp_list[$j]) {
			    if ($j > 0) { $OTUs{$OTU} .= $separator; }
			    $OTUs{$OTU} .= $taxa[$j];
			}
			else {
			    last;
			}
		    }
		}
	    }
	}
    }
}

foreach my $OTU (@order) { # print cleaned taxonomy
    if ($OTU =~ /^#/) { print "$OTU\n"; }
    else {
	print "$OTUs{$OTU}$separator$OTU\n";
    }
}

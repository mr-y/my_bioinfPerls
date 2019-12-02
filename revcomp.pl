#! /usr/bin/perl -w

# This script will complement and reverse all sequences in one or more fasta files

use strict;

my $seq; # variable to store sequences

# Loop over input files or STDIN
while (my $input = <>) {
    if ($input =~ /^\s*$/) { next; } # Skip blank lines
    elsif ($input =~ /^>/) { # Lines starting with > are sequence names
	if ($seq) { # if not first sequence name
	    print &rev_comp($seq), "\n"; # print reverse complementary of sequence
	}
	undef $seq; # clear the sequence for next entry
	print $input; # just print them
    }
    else { # if not name or blank line it must be a sequence
	chomp $input; # Remove new lines, they may be in weired places when reversing the sequence
	$input =~ s/\s+//g;
	$seq .= $input; # Save sequence
    }
}
if ($seq) { # we need to print also the last sequence
    print &rev_comp($seq), "\n";
}

sub rev_comp { # Function to reverse and complement
    my $seq = shift @_; # get the sequence
    $seq =~ tr/ACTGactg/TGACtgac/; # complement it
    $seq = reverse($seq); # reverse it
    return $seq; # return the reversed and complemented sequence
}

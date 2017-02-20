#! /usr/bin/perl -w

use strict;
use LWP::Simple;

if ($ARGV[-1] eq '-h' || $ARGV[-1] eq '--help') {
    print "This script downloads and outputs the representive sequence for a UNITE Species\n";
    print "Hypotheses (SH) in fasta format. The SH should be given in a file or through\n";
    print "STDIN one on each row. There should only be the SH code and nothing else.\n";
}
else {
    while (<>) {
	chomp;
	s/\s//g;
	if (!$_) { next; }
	my $SHentry = get "https://unite.ut.ee/bl_forw_sh.php?sh_name=$_#fndtn-panel1";
	my @SHentry = split /\n/, $SHentry;
	if (@SHentry) {
	    my $name = ">$_";
	    my $sequence = '';
	    my $mode = 'start';
	    my $seq_link = '';
	    foreach (@SHentry) {
		if ($mode eq 'start' && /panel radius unite_panel/) { $mode = 'name'; }
		elsif ($mode eq 'name' && /<b>([^<]+)<\/b>/) { $name .= "_$1"; $mode = 'repseq'; }
		elsif ($mode eq 'repseq' && /<b>(Representative|Reference) sequence[^<]*<\/b><a href='([^>]+)'>([^<]+)<\/a>/) { $name .= "_$3"; $seq_link = $2; last; }
	    }
	    $name =~ s/\s+/_/g;
	    if ($seq_link) {
		my $SEQentry = get "$seq_link";
		my @SEQentry = split /\n/, $SEQentry;
		my $pars_seq = 'no';
		foreach (@SEQentry) {
		    if ($pars_seq eq 'no' && /<table>/) { $pars_seq = 'soon'; }
		    elsif ($pars_seq eq 'soon' && /<nobr>Sequence [^<]*<\/nobr><\/td><td>([^<]+)<\/td>/) { $sequence = $1; }
		}
	    }
	    else {
		print STDERR "Could not find link to sequence for $name.\n";
		print STDERR $SHentry;
	    }
	    if ($sequence) {
		chomp $sequence;
		$sequence =~ s/\s+//g;
		print "$name\n$sequence\n";
	    }
	    else { print STDERR "Could not get sequence for $name.\n"; }
	}
	else { print STDERR "Could not get SH data from unite for $_\n"; }
    }
}

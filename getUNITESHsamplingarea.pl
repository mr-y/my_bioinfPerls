#! /usr/bin/perl

use strict;
use warnings;

use LWP::Simple;

if (@ARGV && ($ARGV[0] eq '-h' || $ARGV[0] eq '--help')) {
    print "This script will download and display the Sampling area for the UNITE SH\n";
    print "for an entry, given a tab separated table with entry name/accno in the first\n";
    print "column and SH in the second.\n";
}

while (my $row = <>) {
    chomp $row;
    my ($name, $SH, $accno) = split /\t/, $row;
    $name =~ s/i(^\s+)|(\s+$)//g;
    $SH =~ s/i(^\s+)|(\s+$)//g;
    #$search_term =~ s/ /%20/g;
    my @xml = get "https://unite.ut.ee/bl_forw_sh.php?sh_name=$SH#fndtn-panel1"; 
    @xml = split /\n\r|\n|\r/, $xml[0];
    #print "###\n@xml";
    #my $flag = 'b';
    print STDERR "Checking $accno\n";
    my %data = &parsForLargestSHforAccno($SH,\@xml, "YES");
    print "$name\t$accno\t$data{'name'}\t$data{'SH'}\t$data{'countries'}\n";
    #print "$name\t$accno\t$SH";
#    foreach (@xml) {

	#print ;
#	if (/<div class="panel radius unite_panel"/) {
#	    $flag = 'n';
#	}
#	elsif ($flag eq 'n' && /<b>([^<]*)/) {
#	    print "\t", $1;
#	    $flag = 'f';
#	}
#	elsif ($flag eq 'f' && /<tr><td>Accession number(.*)/) {
#	    print "\t";
#	    my @rows = split /<\/tr>/;
#	    for (my $i=2; $i < scalar @rows-1; ++$i) {
#		my @columns = split /<\/td>/, $rows[$i];
#		$columns[5] =~ s/<[^>]*>//g;
#		$columns[5] =~ s/i(^\s+)|(\s+$)//g;
#		if ($columns[5]) { 
#		    if ($i>2) { print "; "; }
#		    print "$columns[5]";
#		}
#	    }
#	}
#    }
#    print "\n";
    sleep(3);
}

sub parsForLargestSHforAccno {
    my %data = ('name' => "", 'countries' => "");
    $data{"SH"} = shift;
    my $page_ref = shift;
    my $largest = shift;
    print STDERR "    Checking $data{SH}\n";
    my $flag = 'b';
    foreach (@{$page_ref}) {
        chomp;
        if (/Newer version\(s\) of this SH is\/are available/) { $flag = "S"; }
        elsif (/There are no newer versions available for this SH/) { $flag = 'b'; }
        elsif ($flag eq "S" && m|(https://unite.ut.ee/bl_forw_sh.php\?sh_name=SH[0-9]+\.[0-9]+FU)|) {
            sleep(2);
            my @shtml = get $1;
            @shtml = split /\n\r|\n|\r/, $shtml[0];
            my $sh;
            if (/sh_name=(SH[0-9]+\.[0-9]+FU)/) {
                $sh = $1;
            }
            if ($sh && $data{'SH'} && $sh ne $data{'SH'}) {
                return parsForLargestSHforAccno($sh, \@shtml, $largest);
            }
        }
        elsif (/<div class="panel radius unite_panel"/) {
            $flag = 'n';
        }
        elsif ($flag eq 'n' && /<b>([^<]*)/) {
            #print "\t", $1;
            $flag = 'f';
            $data{'name'} = $1;
        }
        elsif ($flag eq 'f' && /<tr><td>Accession number(.*)/) {
            #print STDERR "## ## ##\n";
            my $countries = "";
            my @rows = split /<\/tr>/;
            for (my $i=2; $i < scalar @rows-1; ++$i) {
                my @columns = split /<\/td>/, $rows[$i];
                if ($columns[12] =~ /href=['"]([^'"]+)['"]/ && $largest && $largest eq 'YES') {
		    my $url = $1;
                    $columns[12] =~ /sh_name=(SH[0-9]+\.[0-9]+FU)/;
                    my $sh = $1;
                    if ($sh && $data{'SH'} && $sh ne $data{'SH'}) {
                        #print STDERR "$sh # $data{'SH'}\n";
                        sleep(2);
			my @shtml = get $url;
                        @shtml = split /\n\r|\n|\r/, $shtml[0];
                        return parsForLargestSHforAccno($sh, \@shtml, $largest);
                    }
                }
                $columns[5] =~ s/<[^>]*>//g;
                $columns[5] =~ s/i(^\s+)|(\s+$)//g;
                if ($columns[5]) {
                    if ($data{'countries'}) { $data{'countries'} .= "; "; }
                    $data{'countries'} .= $columns[5];
                }
            }
            return %data;
        }
    }
    return %data;
}


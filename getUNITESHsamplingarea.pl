#! /usr/bin/perl

use strict;
use warnings;

use LWP::Simple;
my $get_newest = 'NO';
my $get_largest = 'NO';
my @get_columns = (5,3);
my $INFILE = *STDIN;

if (@ARGV && ($ARGV[0] eq '-h' || $ARGV[0] eq '--help')) {
    print "This script will download and display the Sampling area for the UNITE SH\n";
    print "for an entry, given a tab separated table with entry name/accno in the first\n";
    print "column and SH in the second.\n";
}

while (my $row = <$INFILE>) {
    chomp $row;
    my ($name, $SH) = split /\t/, $row;
    $name =~ s/i(^\s+)|(\s+$)//g;
    $SH =~ s/i(^\s+)|(\s+$)//g;
    my @xml = get "https://unite.ut.ee/bl_forw_sh.php?sh_name=$SH#fndtn-panel1"; 
    @xml = split /\n\r|\n|\r/, $xml[0];
    print STDERR "Checking $name";
    my %data = &parsForLargestSHforAccno($SH,\@xml, \@get_columns, $get_newest, $get_largest);
    print "$name\t$data{'name'}\t$data{'SH'}";
    foreach (@get_columns) { print "\t$data{$_}"; }
    print "\n";
    sleep(3);
}

sub parsForLargestSHforAccno {
    my %data = ('name' => "");#, 'countries' => "");
    $data{"SH"} = shift;
    my $page_ref = shift;
    my $col_ref = shift;
    foreach (@$col_ref) {
	$data{$_} = '';
    }
    my $newest = shift;
    my $largest = shift;
    print STDERR "    Checking $data{SH}\n";
    my $flag = 'b';
    foreach (@{$page_ref}) {
        chomp;
        if ($newest && $newest eq "YES") {
	   if (/Newer version\(s\) of this SH is\/are available/) { $flag = "S"; }
	    elsif (/There are no newer versions available for this SH/) { $flag = 'b'; }
	}
        elsif ($flag eq "S" && m|(https://unite.ut.ee/bl_forw_sh.php\?sh_name=SH[0-9]+\.[0-9]+FU)|) {
            sleep(2);
            my @shtml = get $1;
            @shtml = split /\n\r|\n|\r/, $shtml[0];
            my $sh;
            if (/sh_name=(SH[0-9]+\.[0-9]+FU)/) {
                $sh = $1;
            }
            if ($sh && $data{'SH'} && $sh ne $data{'SH'}) {
                return parsForLargestSHforAccno($sh, \@shtml, $col_ref, $newest, $largest);
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
                        return parsForLargestSHforAccno($sh, \@shtml, $col_ref, $newest, $largest);
                    }
                }
		foreach (@$col_ref) {
		    $columns[$_] =~ s/<[^>]*>//g;
		    $columns[$_] =~ s/i(^\s+)|(\s+$)//g;
		    if ($columns[$_]) {
			if ($data{$_}) { $data{$_} .= "; "; }
			$data{$_} .= $columns[$_];
		    }
		}
            }
            return %data;
        }
    }
    return %data;
}


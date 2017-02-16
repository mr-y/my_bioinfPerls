#! /usr/bin/perl -w

# For indexfungorum API info http://www.indexfungorum.org/ixfwebservice/fungus.asmx

use LWP::Simple;

if ($ARGV[0] eq '-h' || $ARGV[0] eq '--help') {
    print "This script will download the first 10 hits in indexfungorum for names given in\n";
    print "file or by STDIN where each name should be on a separate row and no other\n";
    print "information may be given. It will output the given name and current name\n";
    print "according to indexfungorum for those names where these differ. When there are\n";
    print "many entries for the same name, the last will be used (out of maximum 10).\n";
}

while (my $species = <>) {
    chomp $species;
    my $search_term = $species;
    $search_term =~ s/ /%20/g;
    @xml = get "http://www.indexfungorum.org/ixfwebservice/fungus.asmx/NameSearch?SearchText=$search_term&AnywhereInText=false&MaxNumber=10";
#    print "http://www.indexfungorum.org/ixfwebservice/fungus.asmx/NameSearch?SearchText=$search_term&AnywhereInText=false&MaxNumber=10\n";
    #print "###\n@xml";
    foreach (@xml) {
	#print $_;
	if (/<CURRENT_x0020_NAME>(.+)<\/CURRENT_x0020_NAME>/) {
	    my $current = $1;
	    #print $current, "\n";
	    if ($current ne $species) { print "$species\t$current\n"; }
	}
    }
}

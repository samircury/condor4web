#!/usr/bin/perl

use 5.010;
use strict;
use warnings;
use Test::More;
use Data::Dumper;
use File::Slurp;
use Condor::QueueParser;

my @condor_q =  read_file( 'input.txt' ) ;

ok (scalar(@condor_q) > 100, 'Dummy input file is here');

my $cparser = Condor::QueueParser->new();

ok($cparser, 'Condor::QueueParser instance ok');

$cparser->load_schedds_xml(\@condor_q);

ok (scalar(keys %{$cparser->{'schedds_map'}}) == 2, "We got 2 schedulers here");

foreach my $schedd (keys %{$cparser->{'schedds_map'}}) {
	ok($cparser->{'schedds_map'}{$schedd}{'xml'}, "Got an xml for $schedd");

}

$cparser->convert_to_compatible_xml();
$cparser->xml_to_hrefs();

foreach my $schedd (keys %{$cparser->{'schedds_map'}}) {
	ok($cparser->{'schedds_map'}{$schedd}{'href'}, "Got a perl href for $schedd");
}


 foreach my $schedd (keys %{$cparser->{'schedds_map'}}) {
	ok(length($cparser->schedd_json($schedd)) > 2000,  "JSON Length is big enough to contain something relevant");
 }


done_testing();
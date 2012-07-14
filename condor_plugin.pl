#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;
use Storable::CouchDB;
use Condor::QueueParser;


open(FH, '<input.txt');
my @condor_q = <FH>;
close(FH);

my %schedds_map;
my $schedd;
my @submitter_xml;

sub main {
    
    my $condor_parser = Condor::QueueParser->new();
    $condor_parser->load_schedds_xml(\@condor_q);
    $condor_parser->xml_to_hashrefs();
    add_generic_fields($condor_parser->{'schedds_map'});
    populate_couch($condor_parser->{'schedds_map'});
	
	#%schedds_map = parse_all_schedds_xml(@condor_q);
	
	#xml_to_hashrefs(\%schedds_map);
	
}

sub add_generic_fields {
	my $schedds_map = shift;
	my %condor_state_map = {
	    '0' => 'unexpanded'	,
	    '1'	=> 'idle'	,
	    '2'	=> 'running'	,
	    '3' => 'removed'	,
	    '4'	=> 'completed'	,
	    '5'	=> 'held'	,
	    '6'	=> 'submission_err'
	};
	foreach my $schedd (keys %{$schedds_map}) {
	    foreach my $job (@{$schedds_map->{$schedd}{'href'}{'c'}}) {
		# Make assignment of specific to generic job attributes
		# Those have to be : submit_time, local_user, dn, status
		$job->{'dn'} = $job->{'x509userproxysubject'};
		# my $user = split('@', $job{'User'}{'s'});
		# $job{'local_user'} = $user[0];
		# $job{'status'} = $condor_state_map{$job{'JobStatus'}{'i'}};
		# $job{'status'} = ; 
		    
	    }
	}	
}
					
#upload what we got to couch :
# THIS IS THE INSERT METHOD!!
sub populate_couch {
	my $schedds_map = shift;
	my $couch =  Storable::CouchDB->new('uri' => 'http://samircury.iriscouch.com', 'db' => 'teste4' );
	foreach my $schedd (keys %{$schedds_map}) {
	    foreach my $job (@{$schedds_map->{$schedd}{'href'}{'c'}}) {		
		my $global_jobid = $job->{'GlobalJobId'};
		my $answer = $couch->store($global_jobid , $job) ;
		#check if the insertion was fine, die if not?
		
	    }
	}
}
# WE SHOULD CHECK WHETER THERE WAS AN ENTEREDCURRENTSTATUS LOWER AND UPDATE IT IF NOT
main();
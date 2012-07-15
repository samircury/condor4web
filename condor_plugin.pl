#!/usr/bin/perl

#use strict;
#use warnings;
use Data::Dumper;
use Storable::CouchDB;
use Condor::QueueParser;


open(FH, '<input.txt');
my @condor_q = <FH>;
close(FH);


my @submitter_xml;

sub main {
    
    my %schedds_map;
    my $condor_parser = Condor::QueueParser->new();
    %schedds_map = $condor_parser->load_schedds_xml(\@condor_q);
    %schedds_map = $condor_parser->convert_to_compatible_xml(\%schedds_map);
    %schedds_map = $condor_parser->xml_to_hrefs(\%schedds_map);
    add_generic_fields(\%schedds_maps);
    populate_couch(\%schedds_map);
	
	#%schedds_map = parse_all_schedds_xml(@condor_q);
	
	#xml_to_hashrefs(\%schedds_map);
	
}

sub add_generic_fields {
	
	my $schedds_map_href = shift;
	my %schedds_map = %{$schedds_map_href};
	
	my %condor_state_map = {
	    '0' => 'unexpanded'	,
	    '1'	=> 'idle'	,
	    '2'	=> 'running'	,
	    '3' => 'removed'	,
	    '4'	=> 'completed'	,
	    '5'	=> 'held'	,
	    '6'	=> 'submission_err'
	};
	foreach my $schedd (keys %schedds_map) {
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
	my $schedds_map_href = shift;
	my %schedds_map = %{$schedds_map_href};
	
	my $couch =  Storable::CouchDB->new('uri' => 'http://samircury.iriscouch.com', 'db' => 'teste5' );
	foreach my $schedd (keys %schedds_map) {
	    foreach my $job (@{$schedds_map{$schedd}{'href'}{'c'}}) {		
		my $global_jobid = $job->{'GlobalJobId'};
		if (not $global_jobid) {
			warn("Couldnt find a job name for a job in schedd $schedd");
			next;
		}
		my $answer = $couch->store($global_jobid , $job) ;
		#check if the insertion was fine, die if not?
		
	    }
	}
}
# WE SHOULD CHECK WHETER THERE WAS AN ENTEREDCURRENTSTATUS LOWER AND UPDATE IT IF NOT
main();
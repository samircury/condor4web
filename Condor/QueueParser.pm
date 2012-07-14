package Condor::QueueParser;

=pod

=head1 NAME

Condor::QueueParser - Spits condor queue's jobs in many ways

=head1 SYNOPSIS

  my $object = Condor::QueueParser->new(
      foo  => 'bar',
      flag => 1,
  );
  
  $object->dummy;

=head1 DESCRIPTION

The author was too lazy to write a description.

=head1 METHODS

=cut

use 5.010;
use strict;
use warnings;
use XML::Simple;
use JSON::XS;
use Data::Dumper;
our $VERSION = '0.01';

=pod

=head2 new
	
	# This will only create the object then you can play with it later (see other methods)
	my $cparser = Condor::QueueParser->new();
	
=cut

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;
	return $self;
}

my %schedds_map;
my $schedd;
my @submitter_xml;

=pod
=head2 load_schedds_xml
	# Here one should load the RAW output from $(condor_q -global -l -xml) it will spit a non-XML format and be converted later.
	$cparser->load_schedds_xml(\@condor_q);
	# What it does under the hood, is to get REAL XML for each schedd that the condor_q will present.
	# $cparser->{'schedds_map'}  will be then loaded with a key per schedd, which contains the {'xml'} already
=cut
sub load_schedds_xml {
	my $self = shift;
	my $condor_q = shift;
	my @text = @{$condor_q};
	my %schedds_map;
	my $schedd;
	
	
	die("come on, gimme some text") if (scalar(@text) < 1);

	foreach my $line (@text) {
	
		if ($line =~ m/^--.*Schedd\:(.*)\s\:(.*)/) {
			# $2 is useful but not used -- IP
			$schedd = $1;
		}
		if ($line =~ m/\<classads\>/) {
			# New scheed, record previous in the map and reset everything
			$schedds_map{$schedd}{'xml'} = \@submitter_xml;
			@submitter_xml = ();
		}
		push(@submitter_xml, $line);
	}	
	return %schedds_map;
}
=pod
=head2 convert_to_compatible_xml
Before this method runs, {xml} will contain the standard condor XML :

	<classads><c>   <a n="MyType"><s>Job</s></a>  

Afterwards, it will contain what I call "more compatible" XML :

	<classads>  <c> <MyType> Job </MyType> <TargetType> Machine </TargetType> 

=cut
sub convert_to_compatible_xml {
	my $self = shift;
	my $schedds_map_href = shift;
	my %schedds_map = %{$schedds_map_href};

	foreach my $schedd (keys %schedds_map) {
		
		die("There's no XML in the provided schedds_map , verify") if not $schedds_map{$schedd}{'xml'};
		my @real_xml=();

		 foreach my $line  (@{$schedds_map{$schedd}{'xml'}}) {
			 chomp $line;	
			 
			 #</x509userproxy>    <a n="GridMonitorJob"><b v="t"/></a> <GratiaJobOrigin>
			 # <a n="TargetType"><s>Machine</s></a>
			 if ( $line =~ m/\<a.*n\=\"(.*)\"\>\<.*\>(.*)\<.*\>\<\/a\>/ ) {
				 push(@real_xml, "<$1> $2 </$1>" );
			 }
			 elsif ($line =~ m/\<a.*n\=\"(.*)\"\>\<b v\=\"(.)\"\/\>\<\/a\>/) {
			 	# print "peguei b \n";
				 push(@real_xml, "<$1> $2 </$1>" );
			 }
			 else {
				push (@real_xml, $line);
			 }
		 }

		$schedds_map{$schedd}{'xml'} = \@real_xml;		
		# my $job_data = XMLin($xml);
		# $self->{'schedds_map'}{$schedd}{'href'} = $job_data;	
	}
	return %schedds_map;
}

=pod
=head2 xml_to_hrefs

This one should get the content of $self->{'schedds_map'}{$schedd}{'xml'} and populate $self->{'schedds_map'}{$schedd}{'href'} 
with a Perl equivalent multilevel hash, which will be the native format to Perl information, and you can use it in your application

=cut

sub xml_to_hrefs{
	my $self = shift;
	my $schedds_map_href = shift;
	my %schedds_map = %{$schedds_map_href};
	
	foreach my $schedd (keys %schedds_map) {
		die ('provide an xml in %schedds_map{$schedd}{xml} ') if not defined $schedds_map{$schedd}{'xml'} ;
		my $xml = "@{$schedds_map{$schedd}{'xml'}}";
		my $job_data = XMLin($xml);
		$schedds_map{$schedd}{'href'} = $job_data;	
	}
	return %schedds_map;
}
	
	
=pod
=head2 schedd_json
Maybe the most useful way to use it is :

	foreach my $schedd (keys %{$cparser->{'schedds_map'}}) {
		my $json = $cparser->schedd_json($schedd);
		# do something with $json;
	}

=cut

sub schedd_json {
	my $self = shift;
	my $schedds_map_href = shift;
	my %schedds_map = %{$schedds_map_href};
	my $schedd = shift;
	
	die("Which schedd?") if not $schedd;
	die("Come on, ask me something that exists, run xml_to_hashrefs") if not $self->{'schedds_map'}{$schedd}{'href'};
	my $coder = JSON::XS->new->ascii->pretty->allow_nonref;
	my $json = $coder->encode ($self->{'schedds_map'}{$schedd}{'href'});
	return $json;
}


1;

=pod

=head1 SUPPORT

Find support available at https://github.com/samircury/condor4web or the CPAN's tracking system

=head1 AUTHOR

Copyright 2012 Samir Cury.

=cut

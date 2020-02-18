#!/usr/bin/perl -w

###########################################################################
# $Id: rundeckAPI.pm, v0.9 r1 04/02/2020 13:58:58 CET XH Exp $
#
# Copyright 2020 Xavier Humbert <xavier.humbert@ac-nancy-metz.fr>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty
# of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program ;  if not, write to the
# Free Software Foundation, Inc.,
# 59 Temple Place - Suite 330,
# Boston, MA 02111-1307, USA
#
###########################################################################

package RundeckAPI;

use strict;
use warnings;
use POSIX qw(setlocale strftime);
use File::Basename;			# get basename()
use LWP::UserAgent;
use Data::Dumper;
use HTTP::Cookies;
use REST::Client;
use JSON;

use Exporter qw(import);

our @EXPORT_OK = qw(get post put delete);

# use Devel::NYTProf;

#####
## CONSTANTS
#####
our $TIMEOUT = 10;
our $VERSION = "1.0";

#####
## VARIABLES
#####
my $rc=0;

#####
## CONSTRUCTOR
#####

sub new {
	my($class, %args) = @_;
	my $self = {
		'url'		=> $args{'url'},
		'login'		=> $args{'login'},
		'password'	=> $args{'password'},
		'debug'		=> $args{'debug'},
		'result'	=> undef,
	};
# cretae and store a cookie jar
	my $cookie_jar = HTTP::Cookies->new(
		autosave		=> 1,
		ignore_discard	=> 1,
	);
	$self->{'cookie_jar'} = $cookie_jar;

# with this cookie, cretae an User-Agent
	my($prog, $dirs, $suffix) = fileparse($0, (".pl"));
	my $ua = LWP::UserAgent->new(
		'agent'			=> $prog . "-" . $VERSION,
		'timeout'		=> $TIMEOUT,
		'cookie_jar'	=> $self->{'cookie_jar'},
		'requests_redirectable' => ['GET', 'HEAD', 'POST', 'PUT', 'DELETE'],
		);
	$ua->show_progress ($args{'debug'});
 	$ua->proxy( ['http', 'https'], $args{'proxy'}) if (defined $args{'proxy'});
	$self->{'ua'} = $ua;

# connect to the client
	my $client = REST::Client->new(
		host		=> $self->{'url'},
		timeout		=> 10,
		useragent	=> $ua,
		follow		=> 1,
	);
	$client->addHeader ("Content-Type", 'application/x-www-form-urlencoded');
	$client->addHeader ("Accept", "application/json");
	$self->{'client'} = $client;
	$client->POST(
		"j_security_check",
		"j_username=$self->{'login'}" . "&" . "j_password=$self->{'password'}",
	);
	$rc = $client->responseCode ();
	my %hash = ();
	if ($rc != 200) {
		%hash = ('reqstatus' => 'UNKN');
	} else {
		%hash = ('reqstatus' => 'OK');
	}
	$self->{'result'} = \%hash;
	$self->{'result'}->{'httpstatus'} = $rc;

# done, bless object and return it
	bless ($self, $class);
	return $self;
}

#####
## METHODS
#####

sub get (){
	my $self = shift;
	my $endpoint = shift;
	my $responseHashRef = ();
	my $rc = 0;

	$self->{'client'}->GET($endpoint);
	$rc = $self->{'client'}->responseCode ();
	$self->{'result'}->{'httpstatus'} = $rc;
# if request did'nt succed, get outta there
	if ($rc-$rc%100 != 200) {
		$self->{'result'}->{'requstatus'} = 'CRIT';
		$self->{'result'}->{'httpstatus'} = $rc;
		return $self->{'result'};
	}
# handle case where test is "ping", response is "pong" in plain text
	my $responseContent = $self->{'client'}->responseContent();
	print Dumper($responseContent) if $self->{'debug'};
	if ($endpoint =~ /ping/) {
		$self->{'result'}->{'requstatus'} = 'CRIT';
		$self->{'result'}->{'requstatus'} = 'OK' if ($responseContent =~ /pong/);
		return $self->{'result'};
	}
# Last case : we've got a nice JSON
	$responseHashRef = decode_json($responseContent) if $responseContent ne '';
	$self->{'result'} = $responseHashRef;
	$self->{'result'}->{'requstatus'} = 'OK';
	$self->{'result'}->{'httpstatus'} = $rc;
	return $self->{'result'};
}

sub post(){
	my $self = shift;
	my $endpoint = shift;
	my $json = shift;
	my $responseHashRef = ();
	my $rc = 0;

	$self->{'client'}->addHeader ("Content-Type", 'application/json');
	$self->{'client'}->POST($endpoint, $json);
	$rc = $self->{'client'}->responseCode ();
	$self->{'result'}->{'httpstatus'} = $rc;
	if ($rc-$rc%100 != 200) {
		$self->{'result'}->{'requstatus'} = 'CRIT';
		$self->{'result'}->{'httpstatus'} = $rc;
		return $self->{'result'};
	}
	my $responseContent = $self->{'client'}->responseContent();
	print Dumper($responseContent) if $self->{'debug'};
	$responseHashRef = decode_json($responseContent) if $responseContent ne '';
	$self->{'result'} = $responseHashRef;
	$self->{'result'}->{'requstatus'} = 'OK';
	$self->{'result'}->{'httpstatus'} = $rc;
	return $self->{'result'};
}

sub put(){
	my $self = shift;
	my $endpoint = shift;
	my $json = shift;
	my $responseHashRef = ();
	my $rc = 0;

	$self->{'client'}->addHeader ("Content-Type", 'application/json');
	$self->{'client'}->PUT($endpoint, $json);
	$rc = $self->{'client'}->responseCode ();
	$self->{'result'}->{'httpstatus'} = $rc;
	if ($rc-$rc%100 != 200) {
		$self->{'result'}->{'requstatus'} = 'CRIT';
		$self->{'result'}->{'httpstatus'} = $rc;
		return $self->{'result'};
	}
	my $responseContent = $self->{'client'}->responseContent();
	print Dumper($responseContent) if $self->{'debug'};
	$responseHashRef = decode_json($responseContent) if $responseContent ne '';
	$self->{'result'} = $responseHashRef;
	$self->{'result'}->{'requstatus'} = 'OK';
	$self->{'result'}->{'httpstatus'} = $rc;
	return $self->{'result'};
}

sub delete () {
	my $self = shift;
	my $endpoint = shift;
	my $responseHashRef = ();
	my $rc = 0;

	$self->{'client'}->DELETE($endpoint);
	$rc = $self->{'client'}->responseCode ();
	$self->{'result'}->{'httpstatus'} = $rc;
	if ($rc-$rc%100 != 200) {
		$self->{'result'}->{'requstatus'} = 'CRIT';
		$self->{'result'}->{'httpstatus'} = $rc;
		return $self->{'result'};
	}
	my $responseContent = $self->{'client'}->responseContent();
	print Dumper($responseContent) if $self->{'debug'};
	$responseHashRef = decode_json($responseContent) if $responseContent ne '';
	$self->{'result'} = $responseHashRef;
	$self->{'result'}->{'requstatus'} = 'OK';
	$self->{'result'}->{'httpstatus'} = $rc;
	return $self->{'result'};
}

1;

=head1
NAME
RundeckAPI - simplifies authenticate, connect, request a Rundeck instance via REST API

=head1 SYNOPSIS
	use RundeckAPI;

	# create an object of type RundeckAPI :
	my $api = RundeckAPI->new(
		'url'		=> "https://my.rundeck.instance:4440",
		'login'		=> "admin",
		'password'	=> "passwd",
		'debug'		=> 1,
 		'proxy'		=> "http://proxy.mycompany.com/",
	);

=head1
METHODS
=head2
	# connect to Rundeck
	my $hashRef = $api->get("/api/27/system/info");
	my $json = '{some: value}';
	$hashRef = $api->put(/api/27/endpoint_for_put, $json);
	post is identical to put, and delete identical to get (items to be deleted are specified in th endpoint paramater)
Returns a hash reference containing the data sent by Rundeck.
See documentation for Rundeck's https://docs.rundeck.com/docs/api/rundeck-api.html and returned data


=head1
AUTHOR
	Xavier Humbert <xavier.humbert-at-ac-nancy-metz-dot-fr>

=cut

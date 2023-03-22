#!/usr/bin/perl -w

###########################################################################
# $Id: rundeckAPI.pm, v1.0 r1 04/02/2020 13:58:58 CET XH Exp $
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
use File::Basename;
use LWP::UserAgent;
use Data::Dumper;
use HTTP::Cookies;
use REST::Client;
use Scalar::Util qw(reftype);
use JSON;
use Storable qw(dclone);
use Exporter qw(import);

our @EXPORT_OK = qw(get post put delete postData putData);

#####
## CONSTANTS
#####
our $TIMEOUT = 10;
our $VERSION = "1.3.5.0";
#####
## VARIABLES
#####

#####
## CONSTRUCTOR
#####

sub new {
	my($class, %args) = @_;
	my $rc = 403;
	my $self = {
		'url'		=> $args{'url'},
		'login'		=> $args{'login'},
		'token'		=> $args{'token'},
		'debug'		=> $args{'debug'} || 0,
		'verbose'	=> $args{'verbose'} || 0,
		'result'	=> undef,
		'timeout'	=> $args{'timeout'} || $TIMEOUT,
	};
# create and store a cookie jar
	my $cookie_jar = HTTP::Cookies->new(
		autosave		=> 1,
		ignore_discard	=> 1,
	);
	$self->{'cookie_jar'} = $cookie_jar;

# with this cookie, cretae an User-Agent
	my($prog, $dirs, $suffix) = fileparse($0, (".pl"));
	my $ua = LWP::UserAgent->new(
		'agent'			=> $prog . "-" . $VERSION,
		'timeout'		=> $self->{'timeout'},
		'cookie_jar'	=> $self->{'cookie_jar'},
		'requests_redirectable' => ['GET', 'HEAD', 'POST', 'PUT', 'DELETE'],
		);
	$ua->show_progress ($args{'verbose'});
 	$ua->proxy( ['http', 'https'], $args{'proxy'}) if (defined $args{'proxy'});
	$self->{'ua'} = $ua;

# connect to the client
	my $client = REST::Client->new(
		host		=> $self->{'url'},
		timeout		=> $self->{'timeout'},
		useragent	=> $ua,
		follow		=> 1,
	);
	$client->addHeader ("Content-Type", 'application/x-www-form-urlencoded');
	$client->addHeader ("Accept", "application/json");
	$self->{'client'} = $client;

	if (defined $self->{'token'}) {
		$client->addHeader ("X-Rundeck-Auth-Token", $self->{'token'});
		$client->GET("/api/21/tokens/$self->{'login'}");
# check if token match id
		my $authJSON = $client->responseContent();
		$rc = $client->responseCode ();
		if (($rc-$rc%100 == 200) && (index($client->{'_res'}{'_content'}, 'alert alert-danger') == -1)) {
			my $jHash = decode_json ($authJSON);
			if (defined $jHash->[0]) {
				my $connOK = 0;
				foreach my $tokenInfo (@{$jHash}) {
					if ($tokenInfo->{'user'} eq $self->{'login'}) {
						$connOK = 1;
						last;
					}
				}
				if ($connOK) {
					$rc = 200;
				} else {
					$rc = 403;
				}

			} else {
				$rc = 403;
			}
		} else {
			$rc = 403;
		}
	}
	if ($rc-$rc%100 != 200) {
		$self->{'result'}->{'reqstatus' } = 'UNKN';
	} else {
		$self->{'result'}->{'reqstatus'} = 'OK';
	}
	$self->{'result'}->{'httpstatus'} = $rc;

# done, bless object and return it
	bless ($self, $class);
	$self->_logV1 ("Connected to $self->{'url'}") if ($rc-$rc%100 == 200);
	$self->_logD($self);
	return $self;
}

#####
## METHODS
#####

sub get (){		# endpoint
	my $self = shift;
	my $endpoint = shift;

	my $responsehash = ();
	my $rc = 0;

	# Handle secial case where endpoint is /api/XX/job, returns YAML
	if ($endpoint =~ /api\/[0-9]+\/job/) {
		$endpoint .= '?format=yaml';
	}

	$self->{'client'}->GET($endpoint);
	$rc = $self->{'client'}->responseCode ();
	$responsehash->{'httpstatus'} = $rc;

	if ($rc-$rc%100 != 200) {
		$responsehash->{'reqstatus'} = 'CRIT';
		$responsehash->{'httpstatus'} = $rc;
	} else {
		my $responseType = $self->{'client'}->responseHeader('content-type');
		my $responseContent = $self->{'client'}->responseContent();
		$responsehash = $self->_handleResponse($rc, $responseType, $responseContent);

	}
	return dclone ($responsehash);
}

sub post(){		# endpoint, json
	my $self = shift;
	my $endpoint = shift;
	my $json = shift;

	my $responsehash = ();
	my $rc = 0;

	$self->{'client'}->addHeader ("Content-Type", 'application/json');
	$self->{'client'}->POST($endpoint, $json);
	$rc = $self->{'client'}->responseCode ();
	$self->{'result'}->{'httpstatus'} = $rc;

	if ($rc-$rc%100 != 200) {
		$responsehash->{'reqstatus'} = 'CRIT';
		$responsehash->{'httpstatus'} = $rc;
	} else {
		my $responseType = $self->{'client'}->responseHeader('content-type');
		my $responseContent = $self->{'client'}->responseContent();
		$responsehash = $self->_handleResponse($rc, $responseType, $responseContent);
	}
	return dclone ($responsehash);
}

sub put(){		# endpoint, json
	my $self = shift;
	my $endpoint = shift;
	my $json = shift;

	my $responsehash = ();
	my $rc = 0;

	$self->{'client'}->addHeader ("Content-Type", 'application/json');
	$self->{'client'}->PUT($endpoint, $json);
	$rc = $self->{'client'}->responseCode ();
	$self->{'result'}->{'httpstatus'} = $rc;

	if ($rc-$rc%100 != 200) {
		$responsehash->{'reqstatus'} = 'CRIT';
		$responsehash->{'httpstatus'} = $rc;
	} else {
		my $responseType = $self->{'client'}->responseHeader('content-type');
		my $responseContent = $self->{'client'}->responseContent();
		$responsehash = $self->_handleResponse($rc, $responseType, $responseContent);
	}
	return dclone ($responsehash);
}

sub delete () {		# endpoint
	my $self = shift;
	my $endpoint = shift;

	my $responsehash = ();
	my $rc = 0;

	$self->{'client'}->DELETE($endpoint);
	$rc = $self->{'client'}->responseCode ();
	$responsehash->{'httpstatus'} = $rc;

	if ($rc-$rc%100 != 200) {
		$responsehash->{'reqstatus'} = 'CRIT';
		$responsehash->{'httpstatus'} = $rc;
	} else {
		my $responseType = $self->{'client'}->responseHeader('content-type');
		my $responseContent = $self->{'client'}->responseContent();
		$responsehash = $self->_handleResponse($rc, $responseType, $responseContent);
	}
	return dclone ($responsehash);
}

sub postData() {		# endpoint, mimetype, data
	my $self = shift;
	my $endpoint = shift;
	my $mimetype = shift;
	my $data = shift;

	my $responsehash = ();
	my $rc = 0;

	$self->{'client'}->addHeader ("Content-Type", $mimetype);
	$self->{'client'}->POST($endpoint, $data);
	$rc = $self->{'client'}->responseCode ();
	$self->{'result'}->{'httpstatus'} = $rc;

	if ($rc-$rc%100 != 200) {
		$responsehash->{'reqstatus'} = 'CRIT';
		$responsehash->{'httpstatus'} = $rc;
	} else {
		my $responseType = $self->{'client'}->responseHeader('content-type');
		my $responseContent = $self->{'client'}->responseContent();
		$responsehash = $self->_handleResponse($rc, $responseType, $responseContent);
	}
	return dclone ($responsehash);
}

sub putData() {		# endpoint, mimetype, data
	my $self = shift;
	my $endpoint = shift;
	my $mimetype = shift;
	my $data = shift;

	my $responsehash = ();
	my $rc = 0;

	$self->{'client'}->addHeader ("Content-Type", $mimetype);
	$self->{'client'}->PUT($endpoint, $data);
	$rc = $self->{'client'}->responseCode ();
	$self->{'result'}->{'httpstatus'} = $rc;

	if ($rc-$rc%100 != 200) {
		$responsehash->{'reqstatus'} = 'CRIT';
		$responsehash->{'httpstatus'} = $rc;
	} else {
		my $responseType = $self->{'client'}->responseHeader('content-type');
		my $responseContent = $self->{'client'}->responseContent();
		$responsehash = $self->_handleResponse($rc, $responseType, $responseContent);
	}
	return dclone ($responsehash);
}


sub _handleResponse () {
	my $self = shift;
	my $rc = shift;
	my $responseType = shift;
	my $responseContent = shift;

	my $responseJSON = ();
	my $responsehash = ();
	$responsehash->{'reqstatus'} = 'OK';
	$responsehash->{'httpstatus'} = 200;

	# is data JSON ?
	if ($responseType =~ /^application\/json.*/) {
		$self->_logV2($responseContent);
		$responseJSON = decode_json($responseContent) if $responseContent ne '';
		my $reftype = reftype($responseJSON);
		if (not defined $reftype) {
			$self->_bomb("Can't decode undef type");
		} elsif ($reftype eq 'ARRAY') {
			$self->_logV2("copying array");
			$responsehash->{'content'}{'arraycount'} = $#$responseJSON+1;
			for (my $i = 0; $i <= $#$responseJSON; $i++) {
				$responsehash->{'content'}{$i} = $responseJSON->[$i];
			}
		} elsif ($reftype eq 'SCALAR') {
			$self->_bomb("Can't decode scalar type");
		} elsif ($reftype eq 'HASH') {
			$self->_logV2("copying hash");
			$responsehash->{'content'} = $responseJSON;
		}
		$responsehash->{'reqstatus'} = 'OK';
		$responsehash->{'httpstatus'} = $rc;
	} elsif ($responseType =~ /text\/plain.*/) {
		$self->_logV2($responseContent);
		$responsehash->{'content'} = $responseContent;
	} else { # assume binary, like text, but do not log
		$responsehash->{'content'} = $responseContent;
	}
	return $responsehash;
}

sub _logV1() {
	my $self = shift;
	my $msg = shift;

	if ($self->{'verbose'} >= 1) {
		if (defined $msg) {
			print "$msg\n";
		} else {
			print "unknown $!";
		}
	}
}
sub _logV2() {
	my $self = shift;
	my $obj = shift;

	if ($self->{'verbose'} >= 2) {
		if (defined $obj) {
			print Dumper ($obj);
		} else {
			print "unknown objetc $!";
		}
	}
}

sub _logD() {
	my $self = shift;
	my $object = shift;

	print Dumper ($object) if $self->{'debug'};
}

sub _bomb() {
	my $self = shift;
	my $msg = shift;

	$msg .= "\nReport this to xavier.humbert\@ac-nancy-metz.fr with detail of the REST call you made";
	die $msg;
}
1;

=pod

=head1 NAME

RundeckAPI - simplifies authenticate, connect, queries to a Rundeck instance via REST API

=head1 SYNOPSIS
	use RundeckAPI;

	# create an object of type RundeckAPI :
	my $api = RundeckAPI->new(
		'url'		=> "https://my.rundeck.instance:4440",
		'login'		=> "admin",
		'token'		=> <token as generated with GUI, as an admin>
		'debug'		=> 1,
 		'proxy'		=> "http://proxy.mycompany.com/",
	);
	my $hashRef = $api->get("/api/27/system/info");
	my $json = '{some: value}';
	$hashRef = $api->put(/api/27/endpoint_for_put, $json);

=head1 METHODS

=over 12

=item C<new>

Returns an object authenticated and connected to a Rundeck Instance.
The field 'login' is not stricto sensu required, but it is a good security mesure to check if login/token match

=item C<get>

Sends a GET query. Request one argument, the enpoint to the API. Returns a hash reference

=item C<post>

Sends a POST query. Request two arguments, the enpoint to the API an the data in json format. Returns a hash reference

=item C<put>

Sends a PUT query. Similar to post

=item C<delete>

Sends a DELETE query. Similar to get

=item C<postData>

POST some data. Request three arguments : endpoint, mime-type and the appropriate data. Returns a hash reference.

=item C<putData>

PUT some data. Similar to postData

=item C<postFile>

Alias for compatibility for postData

=item C<putFile>

Alias for compatibility for putData

=back

=head1 RETURN VALUE

Returns a hash reference containing the data sent by Rundeck.

The returned value is structured like the following :

the fields `httpstatus` (200, 403, etc) and `requstatus` (OK, CRIT) are always present.

the field `content` is a hash (if the mime-type of the result is JSON), text or binary


=head1 SEE ALSO

See documentation for Rundeck's API https://docs.rundeck.com/docs/api/rundeck-api.html and returned data

=head1 AUTHOR
	Xavier Humbert <xavier.humbert-at-ac-nancy-metz-dot-fr>

=cut

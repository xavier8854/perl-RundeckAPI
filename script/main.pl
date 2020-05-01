#!/usr/bin/perl -w

###########################################################################
# $Id: main.pl, v1.0 r1 04/02/2020 14:31:53 CET XH Exp $
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

use strict;
use diagnostics;
use Data::Dumper;
use lib "../lib";
use RundeckAPI;
use Storable qw(dclone);

#####
## PROTOS
#####

#####
## CONSTANTS
#####

#####
## VARIABLES
#####
my $rc=0;

#####
## MAIN
#####

my $api = RundeckAPI->new(
		'url'		=> "https://rundeck.company.com:4440",
		'login'		=> "admin",
		'password'	=> "admin",
### OR
#		'token'		=> '<Token from GUI, as admin>'
		'debug'		=> 1,
 		'proxy'		=> "http://proxy.your.company:3128",
);

my $hashRef = $api->get("/api/27/system/info");

print Dumper($hashRef);

exit ($rc);


=pod


=cut

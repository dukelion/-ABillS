#!/usr/bin/perl -w


use strict;
use vars qw(%RAD_REQUEST %RAD_REPLY %RAD_CHECK  %REQUEST %conf 
 $begin_time
 $nas
);

#
# This the remapping of return values 
#
use constant  RLM_MODULE_REJECT=>    0;#  /* immediately reject the request */
use constant	RLM_MODULE_FAIL=>      1;#  /* module failed, don't reply */
use constant	RLM_MODULE_OK=>        2;#  /* the module is OK, continue */
use constant	RLM_MODULE_HANDLED=>   3;#  /* the module handled the request, so stop. */
use constant	RLM_MODULE_INVALID=>   4;#  /* the module considers the request invalid. */
use constant	RLM_MODULE_USERLOCK=>  5;#  /* reject the request (user is locked out) */
use constant	RLM_MODULE_NOTFOUND=>  6;#  /* user not found */
use constant	RLM_MODULE_NOOP=>      7;#  /* module succeeded without doing anything */
use constant	RLM_MODULE_UPDATED=>   8;#  /* OK (pairs modified) */
use constant	RLM_MODULE_NUMCODES=>  9;#  /* How many return codes there are */

use FindBin '$Bin';
my $debug = 1;

require $Bin ."/config.pl";
unshift(@INC, $Bin . '/../', $Bin . "/../Abills/$conf{dbtype}");

require $Bin ."/rauth.pl";
require $Bin ."/racct.pl";

$nas = undef;
my %NAS_INFO = ();


#**********************************************************
# 
#**********************************************************
sub convert_radpairs {
	%REQUEST = ();

	while(my($k, $v)=each %RAD_REQUEST) {
		$k =~ s/-/_/g;
		$k =~ tr/[a-z]/[A-Z]/;
		$REQUEST{$k}=$v;
	 }
}


#**********************************************************
# Function to handle authenticate
#
#**********************************************************
sub sql_connect {
	my $sql = Abills::SQL->connect($conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd});
  my $db  = $sql->{db};

  convert_radpairs();
 
  if ($REQUEST{'DHCP-Message-Type'}) {
  	return $db;
   }
  
  $REQUEST{NAS_IDENTIFIER}='' if (! $REQUEST{NAS_IDENTIFIER});
  if (! $NAS_INFO{$REQUEST{NAS_IP_ADDRESS}.'_'.$REQUEST{NAS_IDENTIFIER}}) {
    $nas = Nas->new($db, \%conf);
    if (get_nas_info($db, \%REQUEST) == 0) {		
      $NAS_INFO{$REQUEST{NAS_IP_ADDRESS}.'_'.$REQUEST{NAS_IDENTIFIER}}=$nas;
     }
    else {
    	return 0; 
     }
   }
  else {
  	$nas = $NAS_INFO{$REQUEST{NAS_IP_ADDRESS}.'_'.$REQUEST{NAS_IDENTIFIER}};
   }
  
  return $db;
}


#**********************************************************
# Function to handle authorize
#
#**********************************************************
sub authorize {
  $begin_time = check_time();

  my $db = sql_connect();
  if ( $db ) {
  	if (auth($db, \%REQUEST, $nas, { pre_auth => 1 }) == 0) {
      if ( auth($db, \%REQUEST, $nas) == 0 ) {
    	   return RLM_MODULE_OK;
       }
     }
   }

  return RLM_MODULE_REJECT;
}

#**********************************************************
# Function to handle authenticate
#
#**********************************************************
sub authenticate {
  $begin_time = check_time();

  my $db = sql_connect();
  if ( $db ) {
    if ( auth($db, \%REQUEST, $nas) == 0 ) {
    	return RLM_MODULE_OK;
     }
   }

	return RLM_MODULE_REJECT;
}



#**********************************************************
# accounting()
#**********************************************************
sub accounting {
  $begin_time = check_time();

  my $db = sql_connect();
  if ( $db ) {
    my $ret = acct($db, \%REQUEST, $nas);
   }

	return RLM_MODULE_OK;
}



1

#!/usr/bin/perl -w


use strict;
use vars qw(%RAD_REQUEST %RAD_REPLY %RAD_CHECK %conf 
 $begin_time
 $nas
);
#use Data::Dumper;


# This is hash wich hold original request from radius
#my %RAD_REQUEST;
# In this hash you add values that will be returned to NAS.
#my %RAD_REPLY;
#This is for check items
#my %RAD_CHECK;

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

#convert_radpairs();
require $Bin ."/racct.pl";
require $Bin ."/rauth.pl";

$nas = undef;
my %NAS_INFO = ();

#**********************************************************
# Function to handle authenticate
#
#**********************************************************
sub sql_connect {
	my $sql = Abills::SQL->connect($conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd});
  my $db  = $sql->{db};
  #$rc = $dbh->ping;

  if (! $NAS_INFO{$RAD_REQUEST{NAS_IP_ADDRESS}.'_'.$RAD_REQUEST{NAS_IDENTIFIER}}) {
    $nas = Nas->new($db, \%conf);
    if (get_nas_info($db, \%RAD_REQUEST) == 0) {		
      $NAS_INFO{$RAD_REQUEST{NAS_IP_ADDRESS}.'_'.$RAD_REQUEST{NAS_IDENTIFIER}}=$nas;
     }
    else {
    	return; 
     }
   }
  else {
  	$nas = $NAS_INFO{$RAD_REQUEST{NAS_IP_ADDRESS}.'_'.$RAD_REQUEST{NAS_IDENTIFIER}};
   }
  
  return $db;
}

#**********************************************************
# Function to handle authorize
#
#**********************************************************
sub authorize {
  $begin_time = check_time();
  convert_radpairs();

  my $db = sql_connect();
 
 
  if ( $db ) {
  	
  	if (auth($db, \%RAD_REQUEST, $nas, { pre_auth => 1 }) == 0) {
      if ( auth($db, \%RAD_REQUEST, $nas) == 0 ) {
         #$RAD_CHECK{'User-Password'} = 'test12345';
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
  
  my $db = sql_connect();
  
  if ( $db ) {
    if ( auth($db, \%RAD_REQUEST, $nas) == 0 ) {
    	return RLM_MODULE_OK;
     }
   }

  $RAD_CHECK{'Auth-Type'} = 'Accept';
	return RLM_MODULE_OK;
}



#**********************************************************
# accounting()
#**********************************************************
sub accounting {
  $begin_time = check_time();
  convert_radpairs();

  my $db = sql_connect();
  if ( $db ) {
     my $ret = acct($db, \%RAD_REQUEST, $nas);
   }

	return RLM_MODULE_OK;
}


#**********************************************************
# 
#**********************************************************
sub convert_radpairs {
	my %r = ();

	while(my($k, $v)=each %RAD_REQUEST) {
		$k =~ s/-/_/g;
		$k =~ tr/[a-z]/[A-Z]/;
		$r{$k}=$v;
	 }

  %RAD_REQUEST = %r;
}



#
#
#sub test_call {
#	my ($funcname) = @_;
#	# Some code goes here 
#	my $test = "------$funcname\n";
#	#%RAD_REQUEST %RAD_REPLY %RAD_CHECK
#	$test .= '%RAD_REQUEST'."\n";
#	while(my($k, $v)=each(%RAD_REQUEST)){
#	  $test .= "$k, $v\n";
#	 }
#  $test .= "========\n".'%RAD_CHECK'."\n";
#	while(my($k, $v)=each(%RAD_CHECK)){
#	  $test .= "$k, $v\n";
#	 }
#
#  #print $test;
#  my $a=`echo "$test" >> /tmp/perllog`;
#}


1

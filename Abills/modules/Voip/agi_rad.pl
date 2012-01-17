#!/usr/bin/perl
# Asterisk AGI support for radius Auth and Accounting

use vars  qw(%RAD %conf $db %AUTH $DATE $TIME $var_dir);

use strict;
local $SIG{HUP} = "IGNORE";
use Sys::Syslog;
use FindBin '$Bin';
require $Bin . '/../../../libexec/config.pl';
unshift(@INC, $Bin . '/../../../', $Bin . "/../Abills/$conf{dbtype}");
require Abills::Base;
Abills::Base->import();
my $begin_time = check_time();


use constant ACCESS_REQUEST               => 1;
use constant ACCESS_ACCEPT                => 2;
use constant ACCESS_REJECT                => 3;
use constant ACCOUNTING_REQUEST           => 4;
use constant ACCOUNTING_RESPONSE          => 5;
use constant ACCOUNTING_STATUS            => 6;


require Abills::Radius;
Abills::Radius->import();

my $debug = 1;

$conf{'VOIP_DEFAULTDIALTIMEOUT'}=20 if (! $conf{'VOIP_DEFAULTDIALTIMEOUT'});
#Max session time (sec)
#default 10800 (3hrs)
$conf{'VOIP_MAX_SESSION_TIME'}=10800 if (! $conf{'VOIP_MAX_SESSION_TIME'});
$conf{'timeshift'} = 0 if (! exists($conf{'VOIP_TIMESHIFT'}));
$conf{'VOIP_AGI_DIAL_DELIMITER'}='|' if (! $conf{'VOIP_AGI_DIAL_DELIMITER'});

# Creating new interface to asterisk
use Asterisk::AGI;
my $agi = new Asterisk::AGI;
my %data = ();

# Parsing input data
my %input = $agi->ReadParse();

$conf{'dictionary'} = $Bin . '/../../dictionary' if (! exists($conf{'dictionary'}));

# Let's find who calls!
$input{'callerid'} =~ /(^.+<(\d+)>$)|((^\d+$))/;
# Get AGI variables
# 'clear' Caller ID
$data{'caller'}          = $2 || $3;
$data{'channel'}         = $input{'channel'};
$data{'called'}          = $input{'dnid'};
$data{'confid'}          = $agi->get_variable('SIPCALLID');
$data{'codec'}           = $agi->get_variable('SIPCODEC');
$data{'useragent'}       = $agi->get_variable('SIPUSERAGENT');
$data{'sessionid'}       = $input{'uniqueid'};
$data{'calledgateway'}   = '';
# Default values
$data{'session_timeout'} = $conf{'VOIP_MAX_SESSION_TIME'} || 10800;
$data{'update_interval'} = 0 ; #$conf{'aliveinterval'} || 0;
#$data{'remote_ip'}       = $agi ->get_variable('SIPCHANINFO(peerip)');
$data{'remote_ip'}       = $agi ->get_variable('CHANNEL(peerip)');
#$data{'remote_ip'}       = $agi ->get_variable('SIPRECEIVEDIP');
$data{'theoretical_ip'}  = $agi ->get_variable('SIPTHEORETICALIP');
$data{'return_code'}     = 0;
$data{'dial_info'}       = '';
#my $call_origin = "originate";
#$call_origin = "answer" if $event{'State'} =~ /^Ring$/i;


my $call_type = "VoIP";
$call_type    = "Telephony" if $input{'Channel'} =~ /^(Zap)|(VPB)|(phone)|(Modem)|(CAPI)|(mISDN)|(Console)/;
my $protocol  = 'other';
$protocol     = 'sipv2' if $input{'Channel'} =~ /^SIP/i;
$protocol     = 'h323' if $input{'Channel'} =~ /^h323/i;
my $context   = $input{context};

my %rad_attributes = ();
my %rad_authorize_attributes = ();
my %rad_response = ();


# Setting NAS default radius attributes
$rad_attributes{'User-Name'}          = $data{'caller'};
$rad_attributes{'NAS-Identifier'}     = $conf{'VOIP_NAS_ID'};
$rad_attributes{'NAS-Port'}           = $conf{'VOIP_NAS_PORT'};
$rad_attributes{'NAS-IP-Address'}     = $conf{'VOIP_NAS_IP_ADDRESS'};
$rad_attributes{'Framed-IP-Address'}  = $data{'remote_ip'} || '0.0.0.0';
$rad_attributes{'Calling-Station-Id'} = $data{'caller'};
$rad_attributes{'Called-Station-Id'}  = $data{'called'};
$rad_attributes{'Service-Type'}       = 'Login-User';
$rad_attributes{'h323-conf-id'}       = $data{'confid'};
$rad_attributes{'h323-call-origin'}   = ($context eq 'answer') ? 'answer' : 'originate';
$rad_attributes{'Cisco-Call-Type'}    = "$call_type";
$rad_attributes{'Cisco-NAS-Port'}     = $data{'channel'};
$rad_attributes{'Cisco-AVPair'}       = "call-codec=$data{'codec'};";
$rad_attributes{'Cisco-AVPair'}      .= ($data{'useragent'})? "useragent=$data{'useragent'};" : "";
$rad_attributes{'Cisco-AVPair'}      .= "session-protocol=$protocol";


#Get NAS IP and ID
if (! exists($conf{'NAS_IP_ADDRESS'}) || ! exists($conf{'VOIP_NAS_ID'})) {
  use Sys::Hostname;
  my $hostname;
  $hostname = hostname();
  if (! exists($conf{'VOIP_NAS_ID'})) { $conf{'VOIP_NAS_ID'} = $hostname; }
  if (! exists($conf{'VOIP_NAS_IP_ADDRESS'})) {
    use Socket;
    $conf{'VOIP_NAS_IP_ADDRESS'} = inet_ntoa(scalar(gethostbyname($hostname || 'localhost')));
  }
}



#Auth request
my $r;
my $type = send_radius_request(ACCESS_REQUEST, \%rad_attributes);


if ($type != ACCESS_ACCEPT) {
	my $reply = "USER: $rad_attributes{'User-Name'} Call reject";
	$reply .= ($rad_response{'Reply-Message'}) ? " Reply-Message: ".$rad_response{'Reply-Message'} : '';
	
	syslog('LOG_ERR', $reply );
  $agi->verbose($reply, 3);
  $agi->hangup();
  exit 0;
}
else {
  $agi->verbose("RAD response type = \"$type\"", 3);
}

# Radius Session timeout 
if (defined($rad_response{'h323-credit-time'}) && $rad_response{'h323-credit-time'} < $data{'session_timeout'}){
  $data{'h323-credit-time'}=int($rad_response{'h323-credit-time'}); 
 } 
elsif (defined($rad_response{'Session-Timeout'}) && $rad_response{'Session-Timeout'} < $data{'session_timeout'}){
  $data{'session_timeout'}=int($rad_response{'Session-Timeout'}); 
} 

#return code
if (defined($rad_response{'h323-return-code'})) {
	$data{'return_code'}=$rad_response{'h323-return-code'};
}

$agi->set_variable('RADIUS_Status', 'OK');
$agi->set_variable('Dial_Info', $data{'dial_info'}) if $data{'dial_info'} ne '';
if ($data{return_code} != 0 && $data{return_code} != 13) {
  $agi->verbose('RAD h323-return-code='.$data{'return_code'}, 3);  
	$agi->hangup();
	exit;
}

#$agi->set_autohangup($data{'session_timeout'}) if $data{'session_timeout'} > 0;


if ($debug > 0) {
  $agi->verbose("RAD Pairs:");
  while(my( $k,$v) = each %rad_response) {
    $agi->verbose("$k = $v");
   }
}
#Make calling string 

my $rewrittennumber = $data{'called'};
my $protocol        = $conf{VOIP_AGI_PROTOCOL} || 'SIP';
$protocol           = $rad_response{'session-protocol'} if ($rad_response{'session-protocol'});
my $dialstring      = "$protocol/".$rewrittennumber; #."\@";
$dialstring         = $rad_response{'next-hop-ip'} if ($rad_response{'next-hop-ip'});

$agi->set_variable('LCRSTRING1', $dialstring);
$agi->set_variable('TIMELIMIT', $data{'session_timeout'});
$agi->set_variable('OPTIONS', '');



#Accountin request
my %rad_acct_attributes = %rad_attributes;
# Adding some attributes
$rad_acct_attributes{'Acct-Status-Type'} = "Start";
$rad_acct_attributes{'Acct-Delay-Time'}  = 0;
$rad_acct_attributes{'Acct-Session-Id'}  = $data{'sessionid'};
send_radius_request(ACCOUNTING_REQUEST, \%rad_acct_attributes);

$agi->verbose("Dial: $dialstring ");

my %peer = ( 'type'    => '',
             'host'    => '',
             'peername'=> '');

if ($peer{'type'} eq 'host') {
  $dialstring .= $peer{'host'};
 } 
else {
  $dialstring .= $peer{'peername'};
 }

# Dial Timeout
$dialstring .= "$conf{VOIP_AGI_DIAL_DELIMITER}$conf{'VOIP_DEFAULTDIALTIMEOUT'}";

if ($data{'session_timeout'} > 0){
  $dialstring .= "$conf{VOIP_AGI_DIAL_DELIMITER}";
  $dialstring .= "S(".$data{'session_timeout'}.")";
 }


syslog('info', "Start call CHANNEL: $input{'channel'} NUMBER:". $dialstring);
if ($debug == 1) {
  my $debug_info = '';
  while(my($k, $v)=each(%input)) {
    $debug_info .= "$k - $v,\n";	
   }
  syslog('debug', "$debug_info");
}

$agi->set_variable('TIMEOUT', $data{'session_timeout'});
$agi->exec('Dial', $dialstring);
#$agi->hangup();

  my $session_length   = $agi->get_variable('ANSWEREDTIME') + 0 + $conf{'VOIP_TIMESHIFT'};
  my $call_length      = $agi->get_variable('DIALEDTIME') + 0 + $conf{'VOIP_TIMESHIFT'};
  my $delay_time       = $call_length - $session_length;
  my $sip_msg_code     = $agi->get_variable('SIPLASTERRORCODE')+0;
  my $channel_state    = ''; #$agi->exec('GetChannelState','');  
  my $disconnect_cause = $agi->get_variable('DIALSTATUS');

  syslog('debug', "Disconnect cause: $disconnect_cause CHANNEL STATE: $channel_state SIP MSG CODE: $sip_msg_code");

  # Sending Radius STOP
  # Changing some attributes
  $rad_acct_attributes{'Acct-Status-Type'}   = "Stop";
  $rad_acct_attributes{'Acct-Delay-Time'}    = $delay_time;
  $rad_acct_attributes{'Acct-Session-Time'}  = $session_length;
  $rad_acct_attributes{'h323-gw-id'}         = $data{'calledgateway'};
  $rad_acct_attributes{'h323-voice-quality'} = 0;
  	

  my $currenttime = time();
  $rad_acct_attributes{'h323-setup-time'}      = sec2date($currenttime - $call_length - $delay_time);
  if ($session_length > 0) {
    $rad_acct_attributes{'h323-connect-time'}  = sec2date($currenttime - $session_length);
   }
  else { $rad_acct_attributes{'h323-connect-time'} = sec2date(0); }
  $rad_acct_attributes{'h323-disconnect-time'}     = sec2date($currenttime);
  $rad_acct_attributes{'h323-disconnect-cause'}    = 16;

  
  
  send_radius_request(ACCOUNTING_REQUEST, \%rad_acct_attributes);
  


#**********************************************************
# Radius section
#**********************************************************
sub send_radius_request {
  my ($request_type, $attributes) = @_;
  my $port = 1813;

  if ($request_type eq ACCESS_REQUEST) {
     $port = 1812;
   }

  $r = new Radius(Host    => "$conf{VOIP_RADIUS_SERVER_HOST}:$port",
                  Secret  => "$conf{VOIP_RADIUS_SERVER_SECRET}",
                  TimeOut => 15,
                 );

  if( ! defined($r) ) {
   	 syslog('LOG_ERR', "Can't connect $conf{VOIP_RADIUS_SERVER_HOST}$port ERROR: ". $r->get_error() );
     $agi->verbose('RADIUS server '. $conf{VOIP_RADIUS_SERVER_HOST}. 'ERROR:'.  $r->get_error(), 3);
     $agi->hangup();
     exit;
   }

  $r->load_dictionary($conf{'dictionary'}); # or die("Cannot load dictionary '$conf{dictionary}' !");

  my $type=0;

  $r->clear_attributes();
  while ( my ($key, $value) = each(%$attributes ) ) { 
	  $r->add_attributes({ Name  => $key, 
	  	                   Value => $value });
   }

  $r->send_packet($request_type) and $type = $r->recv_packet();


  if ($r->get_error() ne 'ENONE') {
    syslog('LOG_ERR', "RAD response: $type /Error ".$r->get_error() );
    $agi->verbose("RAD server error: ".$r->get_error(), 3);
    $agi->set_variable('RADIUS_Status', 'Error');
    $agi->hangup();
   }
  elsif( ! defined($type) ) {
    $agi->verbose("Wrong responce from RADIUS server. Check secret key.", 3);
    $agi->set_variable('RADIUS_Status', 'NoResponce');
    $agi->hangup();
   }

  my $get_attr='';
  undef %rad_response;

  for my $a ($r->get_attributes()) {
  	$rad_response{"$a->{'Name'}"}=$a->{'Value'};
    $get_attr .= "$a->{'Name'}=$a->{'Value'},\n";
   }

  syslog('LOG_DEBUG', "RAD Response: $type PAIRS: $get_attr");
  
  return $type;
}

1

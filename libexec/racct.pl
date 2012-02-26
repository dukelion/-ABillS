#!/usr/bin/perl -w
# Radius Accounting 
#

use vars  qw(%RAD %conf %ACCT
 $DATE $TIME
 %RAD_REQUEST %RAD_REPLY %RAD_CHECK 
 $begin_time
 $access_deny
 $Log
);
use strict;

use FindBin '$Bin';
require $Bin . '/config.pl';
unshift(@INC, $Bin . '/../', $Bin ."/../Abills/$conf{dbtype}");

require Abills::Base;
Abills::Base->import( qw(check_time get_radius_params) );
my %acct_mod = ();

require Abills::SQL;
my $sql = Abills::SQL->connect($conf{dbtype}, "$conf{dbhost}", $conf{dbname}, $conf{dbuser}, $conf{dbpasswd});
my $db = $sql->{db};

require Acct;
Acct->import();

require Log;
Log->import('log_add');




############################################################
# Accounting status types
# rfc2866
my %ACCT_TYPES = ('Start'          => 1,
                  'Stop'           => 2,
                  'Alive'          => 3,
                  'Interim-Update' => 3,
                  'Accounting-On'  => 7,
                  'Accounting-Off' => 8
                  ); 

my %USER_TYPES = ('Login-User'         => 1,
               'Framed-User'           => 2,       
               'Callback-Login-User'   => 3, 
               'Callback-Framed-User'  => 4,
               'Outbound-User'         => 5,
               'Administrative-User'   => 6,
               'NAS-Prompt-User'       => 7,
               'Authenticate-Only'     => 8,
               'Call-Check'            =>  10,
               'Callback-Administrative' =>  11,
               'Voic'                  => 12,
               'Fax'                   => 13);

my %ACCT_TERMINATE_CAUSES = (
                      'User-Request'        =>     1,
                      'Lost-Carrier'        =>     2,
                      'Lost-Service'        =>     3,
                      'Idle-Timeout'        =>     4,
                      'Session-Timeout'     =>     5,
                      'Admin-Reset'         =>     6,
                      'Admin-Reboot'        =>     7,
                      'Port-Error'          =>     8,
                      'NAS-Error'           =>     9,
                      'NAS-Request'         =>     10,
                      'NAS-Reboot'          =>     11,
                      'Port-Unneeded'       =>     12,
                      'Port-Preempted'      =>     13,
                      'Port-Suspended'      =>     14,
                      'Service-Unavailable' =>     15,
                      'Callback'            =>     16,
                      'User-Error'          =>     17,
                      'Host-Request'        =>     18,
                      'Supplicant-Restart'  =>     19,
                      'Reauthentication-Failure' => 20,
                      'Port-Reinit'         =>     21,
                      'Port-Disabled'       =>     22       
                    );

####################################################################
#test_radius_returns($RAD);
#####################################################################

my $access_deny = sub {
    my ($user, $message, $nas_num) = @_;
    if (! $Log) {
      $Log = Log->new($db, \%conf);
      $Log->{ACTION} = 'ACCT';
     }

    $Log->log_print('LOG_WARNING', $user, "$message", { ACTION => 'ACCT', NAS => { NAS_ID => $nas_num } });
    return 1;
   };

# Files account section
my $RAD;
my $nas = undef;
if (scalar( %RAD_REQUEST ) < 1) {
  $RAD = get_radius_params();

  if (! defined($RAD->{NAS_IP_ADDRESS})) {
    $RAD->{USER_NAME}='-' if (! defined($RAD->{USER_NAME}));
    $access_deny->("$RAD->{USER_NAME}", "Not specified NAS server", 0);
    exit 1;
   }
  else {
    require Nas;
    $nas = Nas->new($db, \%conf);	
    my %NAS_PARAMS = ();

    if ($RAD->{NAS_IP_ADDRESS} eq '0.0.0.0') {
 	    %NAS_PARAMS = ( CALLED_STATION_ID => $RAD->{CALLED_STATION_ID} );
     }
    else {
      $NAS_PARAMS{'IP'} = "$RAD->{NAS_IP_ADDRESS}";
     }

    if ($RAD->{NAS_IDENTIFIER}) {
      $NAS_PARAMS{NAS_IDENTIFIER}=$RAD->{NAS_IDENTIFIER};
     }

    $nas->info({ %NAS_PARAMS });

    my $acct;
    if ($nas->{errno} || $nas->{TOTAL} < 1) {
      $access_deny->("$RAD->{USER_NAME}", "Unknow server '$RAD->{NAS_IP_ADDRESS}'", 0);
     }
    else {
      $acct = acct($db, $RAD, $nas);
     }

    if($acct->{errno}) {
  	  $Log->log_print('LOG_ERR', $RAD->{USER_NAME}, "$acct->{errstr}". ( (defined($acct->{sql_errstr})) ? " ($acct->{sql_errstr})" : '' )  );
     }
  }
}



#*******************************************************************
# acct();
#*******************************************************************
sub acct {
 my ($db, $RAD, $nas) = @_;
 my $r = 0;

 $Log = Log->new($db, \%conf);
 $Log->{ACTION} = 'ACCT';

 my $begin_time = check_time();

 if ($RAD->{SERVICE_TYPE} && $USER_TYPES{$RAD->{SERVICE_TYPE}} 
    && ($USER_TYPES{$RAD->{SERVICE_TYPE}} == 6 || $USER_TYPES{$RAD->{SERVICE_TYPE}} == 7)) {
   $Log->log_print('LOG_DEBUG', "$RAD->{USER_NAME}", "$RAD->{SERVICE_TYPE}");
   return 0;	
  }

 my $acct_status_type = $ACCT_TYPES{$RAD->{ACCT_STATUS_TYPE}};

 $RAD->{INTERIUM_INBYTE}   = 0;
 $RAD->{INTERIUM_OUTBYTE}  = 0;
 $RAD->{INTERIUM_INBYTE2}  = 0;
 $RAD->{INTERIUM_OUTBYTE2} = 0;
 $RAD->{INBYTE2}  = 0;
 $RAD->{OUTBYTE2} = 0;
  
  #Cisco-AVPair
  if ($RAD->{CISCO_AVPAIR}) {
    if ($RAD->{CISCO_AVPAIR} =~ /client-mac-address=([a-f0-9\.\-\:]+)/) {
      $RAD->{CALLING_STATION_ID}=$1;
      if ($RAD->{CALLING_STATION_ID} =~ /(\S{2})(\S{2})\.(\S{2})(\S{2})\.(\S{2})(\S{2})/) {
        $RAD->{CALLING_STATION_ID}="$1:$2:$3:$4:$5:$6";
       }
     }
    elsif(ref $RAD->{CISCO_AVPAIR} eq 'ARRAY') {
    	foreach my $line (@{ $RAD->{CISCO_AVPAIR} }) {
        if ($line =~ /client-mac-address=([a-f0-9\.\-\:]+)/) {
          $RAD->{CALLING_STATION_ID}=$1;
          if ($RAD->{CALLING_STATION_ID} =~ /(\S{2})(\S{2})\.(\S{2})(\S{2})\.(\S{2})(\S{2})/) {
            $RAD->{CALLING_STATION_ID}="$1:$2:$3:$4:$5:$6";
           }
         }
    	 }
     }
    elsif (defined($RAD->{NAS_PORT}) && $RAD->{NAS_PORT} == 0 && ($RAD->{CISCO_NAS_PORT} && $RAD->{CISCO_NAS_PORT} =~ /\d\/\d\/\d\/(\d+)/)) {
     	$RAD->{NAS_PORT}=$1;
      }
   }

  if ($conf{octets_direction} && $conf{octets_direction} eq 'server') {
    $RAD->{INBYTE} = $RAD->{ACCT_INPUT_OCTETS} || 0;   # FROM client
    $RAD->{OUTBYTE} = $RAD->{ACCT_OUTPUT_OCTETS} || 0; # TO client

    if ($nas->{NAS_TYPE} eq 'mpd5' && $RAD->{MPD_INPUT_OCTETS}) {
  	  ($RAD->{INBYTE}, $RAD->{OUTBYTE},
       $RAD->{ACCT_INPUT_GIGAWORDS}, $RAD->{ACCT_OUTPUT_GIGAWORDS}) = (0,0,0,0); 

      for(my $i=0; $i<=$#{ $RAD->{MPD_INPUT_OCTETS} }; $i++) {
        my($class, $byte)=split(/:/, $RAD->{MPD_INPUT_OCTETS}->[$i]);
        $class = ($class == 0) ? '' : $class + 1;
        
        if ($class eq '' && $byte > 4294967296) {
          $RAD->{ACCT_INPUT_GIGAWORDS} = int($byte / 4294967296);
          $byte = $byte - ($RAD->{ACCT_INPUT_GIGAWORDS} * 4294967296);
         }
        
        $RAD->{'INBYTE' . $class}	= $byte;
        (undef, $byte)=split(/:/, $RAD->{MPD_OUTPUT_OCTETS}->[$i]);
        
        if ($class eq '' && $byte > 4294967296) {
          $RAD->{ACCT_OUTPUT_GIGAWORDS} = int($byte / 4294967296);
          $byte = $byte - ($RAD->{ACCT_OUTPUT_GIGAWORDS} * 4294967296);
         }
        
        $RAD->{'OUTBYTE'. $class }	= $byte;
       }
     }
    elsif ($nas->{NAS_TYPE} eq 'exppp') {
      #reverse byte parameters
      $RAD->{INBYTE}  = $RAD->{ACCT_OUTPUT_OCTETS} || 0;   # FROM client
      $RAD->{OUTBYTE} = $RAD->{ACCT_INPUT_OCTETS} || 0; # TO client
      $RAD->{INBYTE2}  = $RAD->{EXPPP_ACCT_LOCALOUTPUT_OCTETS} || 0;             # From client
      $RAD->{OUTBYTE2} = $RAD->{EXPPP_ACCT_LOCALINPUT_OCTETS} || 0;            # To client
      
      $RAD->{INTERIUM_INBYTE}   = $RAD->{EXPPP_ACCT_ITERIUMOUT_OCTETS} || 0;
      $RAD->{INTERIUM_OUTBYTE}  = $RAD->{EXPPP_ACCT_ITERIUMIN_OCTETS} || 0;
      $RAD->{INTERIUM_INBYTE2}  = $RAD->{EXPPP_ACCT_LOCALITERIUMOUT_OCTETS} || 0;
      $RAD->{INTERIUM_OUTBYTE2} = $RAD->{EXPPP_ACCT_LOCALITERIUMIN_OCTETS} || 0;
     }
    elsif ($nas->{NAS_TYPE} eq 'lepppd') {
      $RAD->{INBYTE} = $RAD->{ACCT_INPUT_OCTETS} || 0;   # FROM client
      $RAD->{OUTBYTE} = $RAD->{ACCT_OUTPUT_OCTETS} || 0; # TO client
      for(my $i=0; $i<4; $i++) {
      	if (defined($RAD->{'PPPD_INPUT_OCTETS_ZONES_'.$i})) {
          $RAD->{'INBYTE'.($i + 1)} = $RAD->{'PPPD_INPUT_OCTETS_ZONES_'.$i};
          $RAD->{'OUTBYTE'.($i + 1)} = $RAD->{'PPPD_OUTPUT_OCTETS_ZONES_'.$i};
      	 }
       }
     }
   }
  # From client
  else {
    $RAD->{INBYTE} = $RAD->{ACCT_OUTPUT_OCTETS} || 0; # FROM client
    $RAD->{OUTBYTE} = $RAD->{ACCT_INPUT_OCTETS} || 0; # TO client
    ($RAD->{ACCT_INPUT_GIGAWORDS}, $RAD->{ACCT_OUTPUT_GIGAWORDS}) = ($RAD->{ACCT_OUTPUT_GIGAWORDS}, $RAD->{ACCT_INPUT_GIGAWORDS}); 

    if ($nas->{NAS_TYPE} eq 'mpd5' && $RAD->{MPD_INPUT_OCTETS}) {

   	  if (ref $RAD->{MPD_INPUT_OCTETS} eq 'ARRAY') {
 	  	  ($RAD->{INBYTE}, $RAD->{OUTBYTE},
          $RAD->{ACCT_INPUT_GIGAWORDS}, $RAD->{ACCT_OUTPUT_GIGAWORDS}) = (0,0,0,0); 
        for(my $i=0; $i<=$#{ $RAD->{MPD_INPUT_OCTETS} }; $i++) {
          my($class, $byte)=split(/:/, $RAD->{MPD_INPUT_OCTETS}->[$i]);
          $class = ($class == 0) ? '' : $class + 1;
          if ($class eq '' && $byte > 4294967296) {
            $RAD->{ACCT_OUTPUT_GIGAWORDS} = int($byte / 4294967296);
            $byte = $byte - ($RAD->{ACCT_OUTPUT_GIGAWORDS} * 4294967296);
           }
          $RAD->{'OUTBYTE' . $class}= $byte;
          (undef, $byte)=split(/:/, $RAD->{MPD_OUTPUT_OCTETS}->[$i]);

          if ($class eq '' && $byte > 4294967296) {
            $RAD->{ACCT_INPUT_GIGAWORDS} = int($byte / 4294967296);
            $byte = $byte - ($RAD->{ACCT_INPUT_GIGAWORDS} * 4294967296);
           }

          $RAD->{'INBYTE'. $class}	= $byte;
        }
       }
      else {
          my($class, $byte)=split(/:/, $RAD->{MPD_INPUT_OCTETS});
          if ($class == 1) {
    	  	  ($RAD->{INBYTE}, $RAD->{OUTBYTE},
             $RAD->{ACCT_INPUT_GIGAWORDS}, $RAD->{ACCT_OUTPUT_GIGAWORDS}) = (0,0,0,0); 
            $RAD->{'OUTBYTE2'}	= $byte;
           }

          ($class, $byte)=split(/:/, $RAD->{MPD_OUTPUT_OCTETS});
          if ($class == 1) {
            $RAD->{'INBYTE2'}	= $byte;
           }
          else {
            $RAD->{INBYTE} = $RAD->{ACCT_OUTPUT_OCTETS} || 0; # FROM client
            $RAD->{OUTBYTE} = $RAD->{ACCT_INPUT_OCTETS} || 0; # TO client
           }
       }
     }
    elsif ($nas->{NAS_TYPE} eq 'exppp') {
      #reverse byte parameters
      $RAD->{INBYTE}   = $RAD->{ACCT_INPUT_OCTETS} || 0;   # FROM client
      $RAD->{OUTBYTE}  = $RAD->{ACCT_OUTPUT_OCTETS} || 0; # TO client
  
      $RAD->{INBYTE2}  = $RAD->{EXPPP_ACCT_LOCALINPUT_OCTETS} || 0;             # From client
      $RAD->{OUTBYTE2} = $RAD->{EXPPP_ACCT_LOCALOUTPUT_OCTETS} || 0;            # To client
      
      $RAD->{INTERIUM_INBYTE}   = $RAD->{EXPPP_ACCT_ITERIUMIN_OCTETS} || 0;
      $RAD->{INTERIUM_OUTBYTE}  = $RAD->{EXPPP_ACCT_ITERIUMOUT_OCTETS} || 0;
      $RAD->{INTERIUM_INBYTE2}  = $RAD->{EXPPP_ACCT_LOCALITERIUMIN_OCTETS} || 0;
      $RAD->{INTERIUM_OUTBYTE2} = $RAD->{EXPPP_ACCT_LOCALITERIUMOUT_OCTETS} || 0;

     }
    elsif ($nas->{NAS_TYPE} eq 'lepppd') {
      $RAD->{INBYTE} = $RAD->{ACCT_OUTPUT_OCTETS} || 0; # FROM client
      $RAD->{OUTBYTE} = $RAD->{ACCT_INPUT_OCTETS} || 0; # TO client
      for(my $i=0; $i<4; $i++) {
      	if (defined($RAD->{'PPPD_INPUT_OCTETS_ZONES_'.$i})) {
          $RAD->{'INBYTE'.($i+1)}  = $RAD->{'PPPD_OUTPUT_OCTETS_ZONES_'.$i};
          $RAD->{'OUTBYTE'.($i+1)} = $RAD->{'PPPD_INPUT_OCTETS_ZONES_'.$i};
      	 }
       }
     }
  }

  $RAD->{CONNECT_INFO}  = $RAD->{MPD_IFACE} if  ($RAD->{MPD_IFACE}); 
  $RAD->{LOGOUT}             = time;
  $RAD->{SESSION_START}      = (defined($RAD->{ACCT_SESSION_TIME})) ?  time - $RAD->{ACCT_SESSION_TIME} : 0;
  $RAD->{NAS_PORT}           = 0  if  (! defined($RAD->{NAS_PORT}));
  $RAD->{CONNECT_INFO}       = '' if  (! defined($RAD->{CONNECT_INFO}));
  $RAD->{ACCT_TERMINATE_CAUSE} =  ($RAD->{ACCT_TERMINATE_CAUSE} && defined($ACCT_TERMINATE_CAUSES{"$RAD->{ACCT_TERMINATE_CAUSE}"})) ? $ACCT_TERMINATE_CAUSES{"$RAD->{ACCT_TERMINATE_CAUSE}"} : 0;

  if ($RAD->{'TUNNEL_CLIENT_ENDPOINT'} && ! $RAD->{CALLING_STATION_ID}) { 
    $RAD->{CALLING_STATION_ID}=$RAD->{'TUNNEL_CLIENT_ENDPOINT'}; 
   } 
  elsif(! defined($RAD->{CALLING_STATION_ID})) {
    $RAD->{CALLING_STATION_ID} = '';
   }
# Make accounting with external programs
if ($conf{extern_acct_dir} && -d $conf{extern_acct_dir}) {
  opendir DIR, $conf{extern_acct_dir} or die "Can't open dir '$conf{extern_acct_dir}' $!\n";
    my @contents = grep  !/^\.\.?$/  , readdir DIR;
  closedir DIR;

  if ($#contents > -1) {
    my $res = "";
    foreach my $file (@contents) {
      if (-x "$conf{extern_acct_dir}/$file" && -f "$conf{extern_acct_dir}/$file") {
        # ACCT_STATUS IP_ADDRESS NAS_PORT
        $res = `$conf{extern_acct_dir}/$file $acct_status_type $RAD->{NAS_IP_ADDRESS} $RAD->{NAS_PORT} $nas->{NAS_TYPE} $RAD->{USER_NAME} $RAD->{FRAMED_IP_ADDRESS}`;
        $Log->log_print('LOG_DEBUG', $RAD->{USER_NAME}, "External accounting program '$conf{extern_acct_dir}' / '$file' pairs '$res'");
       }
     }

    if (defined($res)) {
      my @pairs = split(/ /, $res);
      foreach my $pair (@pairs) {
        my ($side, $value) = split(/=/, $pair);
        $RAD->{$side} = $value || '';
       }
     }
   }
}

my $Acct;

if(defined($ACCT{$nas->{NAS_TYPE}})) {
  if (! defined($acct_mod{"$nas->{NAS_TYPE}"})) {
    require $ACCT{$nas->{NAS_TYPE}} . ".pm";
    $ACCT{$nas->{NAS_TYPE}}->import();
   }

  $acct_mod{"$nas->{NAS_TYPE}"} = $ACCT{$nas->{NAS_TYPE}}->new($db, \%conf);  
  $r = $acct_mod{"$nas->{NAS_TYPE}"}->accounting($RAD, $nas, { RAD_REQUEST => \%RAD_REQUEST });
}
else {
  $acct_mod{'default'} = Acct->new($db, \%conf);
	$r = $acct_mod{"default"}->accounting($RAD, $nas);
}

#my $aaaaaaa = `echo "// $r->{errno} //" >> /tmp/12211`;

if ($r->{errno}) {
  $access_deny->("$RAD->{USER_NAME}", "[$r->{errno}] $r->{errstr}", $nas->{NAS_ID});
 }

 if ($conf{ACCT_DEBUG} && $begin_time > 0)  {
   Time::HiRes->import(qw(gettimeofday));
   my $end_time = gettimeofday();
   my $gen_time = $end_time - $begin_time;
   my $gt = sprintf(" GT: %2.5f", $gen_time);
  }

  return $r;
}




1

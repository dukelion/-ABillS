#!/usr/bin/perl
# Radius Accounting script
# Changes (20/02/2005)

use FindBin '$Bin';
require $Bin . '/config.pl';
my $begin_time = check_time();
require $Bin.'/Base.pm';
Base->import();
require $Bin . '/sql.pl';

#$conf{debugmods}='LOG_DEBUG';
#$logfile = $logacct;


############################################################
get_radius_params();

#if ($RAD{USER_NAME} eq 'petya') {
#  $conf{debug}=10;
#  $logfile=$base_dir . 'var/log/abills_petya.log';
#  test_radius_returns();
#}

my $nas_num=-1;
my $NAS_INFO = nas_params();

if (defined($NAS_INFO->{"$RAD{NAS_IP_ADDRESS}"})) {
   $nas_num = $NAS_INFO->{"$RAD{NAS_IP_ADDRESS}"};
 }
else {
   access_deny("$RAD{USER_NAME}", "Unknow server '$RAD{NAS_IP_ADDRESS}'");
   exit 1;
}

############################################################
# Accounting status types
my %ACCT_TYPES = ('Start', 1,
               'Stop', 2,
               'Alive', 3,
               'Accounting-On', 7,
               'Accounting-Off', 8);


my %USER_TYPES = ('Login-User', 1,
               'Framed-User', 2,       
               'Callback-Login-User', 3, 
               'Callback-Framed-User', 4,
               'Outbound-User', 5,
               'Administrative-User', 6,
               'NAS-Prompt-User', 7,
               'Authenticate-Only', 8,
               'Call-Check',  10);

acct();

my $rc = $db->disconnect;

#*******************************************************************
# acct();
#*******************************************************************
sub acct {
 if ($USER_TYPES{$RAD{SERVICE_TYPE}} == 6) {
     log_print('LOG_DEBUG', "ACCT [$RAD{USER_NAME}] $RAD{SERVICE_TYPE}");
     exit 0;	
    }

 my $sql = "";
 my %ACCT_INFO = ();

 $ACCT_INFO{ACCT_SESSION_ID} = $RAD{ACCT_SESSION_ID};
 $ACCT_INFO{USER_NAME} = $RAD{USER_NAME}; 
 $ACCT_INFO{FRAMED_IP_ADDRESS} = $RAD{FRAMED_IP_ADDRESS};
 $ACCT_INFO{NAS_IP_ADDRESS} = $RAD{NAS_IP_ADDRESS};

# if ($NAS_MODEL{$nas_num} eq 'dslmax')  {
#   $ACCT_INFO{NAS_PORT} = $RAD{X_ASCEND_MODEM_PORTNO} || 0;
#  }
# else {
  $ACCT_INFO{NAS_PORT} = $RAD{NAS_PORT} || 0;
#  }

  $ACCT_INFO{ACCT_STATUS_TYPE} = $ACCT_TYPES{$RAD{ACCT_STATUS_TYPE}};
  $ACCT_INFO{ACCT_SESSION_TIME} = $RAD{ACCT_SESSION_TIME};
  $ACCT_INFO{ACCT_TERMINATE_CAUSE} = $RAD{ACCT_TERMINATE_CAUSE} || 0;
  $ACCT_INFO{INBYTE} = $RAD{ACCT_INPUT_OCTETS} || 0;   # FROM client
  $ACCT_INFO{OUTBYTE} = $RAD{ACCT_OUTPUT_OCTETS} || 0; # TO client
  $ACCT_INFO{CID} =  $RAD{CALLING_STATION_ID} || '';
  $ACCT_INFO{CONNECT_INFO} = $RAD{CONNECT_INFO} || '';
  $ACCT_INFO{LOGOUT} = time;
  $ACCT_INFO{LOGIN} = time - $RAD{ACCT_SESSION_TIME};

# Exppp VENDOR params           
if ($NAS_INFO->{nt}{$nas_num} eq 'exppp') {
#reverse byte parameters
  $ACCT_INFO{INBYTE} = $RAD{ACCT_OUTPUT_OCTETS} || 0;             # From client
  $ACCT_INFO{OUTBYTE} =  $RAD{ACCT_INPUT_OCTETS} || 0;            # To client

  #local traffic
  $ACCT_INFO{INBYTE2}  = $RAD{EXPPP_ACCT_LOCALOUTPUT_OCTETS} || 0;
  $ACCT_INFO{OUTBYTE2} = $RAD{EXPPP_ACCT_LOCALINPUT_OCTETS} || 0;

  $ACCT_INFO{INTERIUM_INBYTE} = $RAD{EXPPP_ACCT_ITERIUMIN_OCTETS} || 0;
  $ACCT_INFO{INTERIUM_OUTBYTE} = $RAD{EXPPP_ACCT_ITERIUMOUT_OCTETS} || 0;
  $ACCT_INFO{INTERIUM_INBYTE2} = $RAD{EXPPP_ACCT_LOCALITERIUMIN_OCTETS} || 0;
  $ACCT_INFO{INTERIUM_OUTBYTE2} =  $RAD{EXPPP_ACCT_LOCALITERIUMOUT_OCTETS} || 0;
}




  my $acct_status_type = $ACCT_TYPES{$RAD{ACCT_STATUS_TYPE}};

   # Make accounting with external programs
   opendir DIR, $extern_acct_dir or die "Can't open dir '$extern_acct_dir' $!\n";
     my @contents = grep  !/^\.\.?$/  , readdir DIR;
   closedir DIR;

   if ($#contents > 0) {
      my $res = "";
      foreach my $file (@contents) {
         if (-x "$extern_acct_dir/$file") {
           $res = `$extern_acct_dir/$file $acct_status_type $ACCT_INFO{NAS_IP_ADDRESS} $ACCT_INFO{NAS_PORT}`;
           log_print('LOG_DEBUG', "External accounting program '$file' pairs '$res'");
          }
        }

      my @pairs = split(/ /, $res);
      foreach $pair (@pairs) {
        my ($side, $value) = split(/=/, $pair);
        $ACCT_INFO{$side} = int($value);
       }
    }


if ($acct_status_type == 1) { 
  $sql = "INSERT INTO calls 
   (status, user_name, started, lupdated, nas_ip_address, nas_port_id, acct_session_id, acct_session_time,
    acct_input_octets, acct_output_octets, framed_ip_address, CID, CONNECT_INFO)
    values ('$acct_status_type', \"$RAD{USER_NAME}\", now(), UNIX_TIMESTAMP(), INET_ATON('$RAD{NAS_IP_ADDRESS}'), 
     '$ACCT_INFO{NAS_PORT}', \"$RAD{ACCT_SESSION_ID}\", 0, 0, 0, INET_ATON('$RAD{FRAMED_IP_ADDRESS}'), '$ACCT_INFO{CID}', '$ACCT_INFO{CONNECT_INFO}');";

  log_print('LOG_SQL', "ACCT [$RAD{USER_NAME}] SQL: $sql");
  $q = $db->do("$sql") || die $db->errstr;
 }
# Stop status
elsif ($acct_status_type == 2) {

  my ($sum, $variant, $time_t, $traf_t) = session_sum("$RAD{USER_NAME}", $ACCT_INFO{LOGIN}, $ACCT_INFO{ACCT_SESSION_TIME}, \%ACCT_INFO);
  if ($sum == -2) {
    log_print('LOG_ERR', "ACCT [$RAD{USER_NAME}] Not exist");
   }
  elsif ($sum < 0) {
    log_print('LOG_DEBUG', "ACCT [$RAD{USER_NAME}] small session ($RAD{ACCT_SESSION_TIME}, $ACCT_INFO{INBYTE}, $ACCT_INFO{OUTBYTE})");
   }
  else {

    $sql = "INSERT INTO log (id, login, variant, duration, sent, recv, minp, kb,  sum, nas_id, port_id, ".
        "ip, CID, sent2, recv2, acct_session_id) VALUES ('$RAD{USER_NAME}', FROM_UNIXTIME($ACCT_INFO{LOGIN}), ".
        "'$variant', '$RAD{ACCT_SESSION_TIME}', '$ACCT_INFO{OUTBYTE}', '$ACCT_INFO{INBYTE}', ".
        "'$time_t', '$traf_t', '$sum', '$nas_num', ".
        "'$ACCT_INFO{NAS_PORT}', INET_ATON('$RAD{FRAMED_IP_ADDRESS}'), '$ACCT_INFO{CID}', ".
        "'$ACCT_INFO{OUTBYTE2}', '$ACCT_INFO{INBYTE2}',  \"$RAD{ACCT_SESSION_ID}\");";

    log_print('LOG_SQL', "ACCT [$RAD{USER_NAME}] SQL: $sql");

    $q = $db->do("$sql");

    if ($db->err) {
      my $filename = "$RAD{USER_NAME}.$RAD{ACCT_SESSION_ID}";
      log_print('LOG_WARNING', "ACCT [$RAD{USER_NAME}] Making accounting file '$filename'");
      mk_session_log(\%ACCT_INFO);
     }
# If SQL query filed
    else {
      if ($sum > 0) {
        $sql = "UPDATE users SET deposit=deposit-$sum WHERE id='$RAD{USER_NAME}';";
        log_print('LOG_SQL', "ACCT [$RAD{USER_NAME}] SQL: $sql");
        $q = $db->do("$sql;") or die $db->errstr;
        }
     }
   }

  # Delete from session wtmp
    $sql = "DELETE FROM  calls WHERE
      acct_session_id=\"$RAD{ACCT_SESSION_ID}\" and 
      user_name=\"$RAD{USER_NAME}\" and 
      nas_ip_address=INET_ATON('$RAD{NAS_IP_ADDRESS}');";

    log_print('LOG_SQL', "ACCT [$RAD{USER_NAME}] SQL: $sql");     
    $q = $db->do("$sql") || die $db->errstr;

}
#Alive status 3
elsif($acct_status_type == 3) {

## Experemental Linux alive hangup
## Author: Wanger
#if ($conf{experimentsl} eq 'yes') {
#  my ($sum, $variant, $time_t, $traf_t) = session_sum("$RAD{USER_NAME}", $ACCT_INFO{LOGIN}, $ACCT_INFO{ACCT_SESSION_TIME}, \%ACCT_INFO);
#  if ($sum > 0) {
#     $sql = "SELECT deposit, credit FROM users WHERE id=\"$RAD{USER_NAME}\";";
#     log_print('LOG_SQL', "ACCT [$RAD{USER_NAME}] SQL: $sql");
#     $q = $db->prepare("$sql") || die $db->errstr;
#     $q -> execute();
#     my ($deposit, $credir) = $q -> fetchrow();
#      if (($deposit + $credir) - $sum) < 0) {
#        log_print('LOG_WARNING', "ACCT [$RAD{USER_NAME}] Negative balance ($d - $sum) - kill session($RAD{ACCT_SESSION_ID})");
#        system ($Bin ."/modules/hangup.pl $RAD{ACCT_SESSION_ID}");
#       }
#  }
#}
###

  $sql = "UPDATE calls SET
    status='$acct_status_type',
    nas_port_id='$ACCT_INFO{NAS_PORT}',
    acct_session_time=UNIX_TIMESTAMP()-UNIX_TIMESTAMP(started),
    acct_input_octets='$ACCT_INFO{INBYTE}',
    acct_output_octets='$ACCT_INFO{OUTBYTE}',
    ex_input_octets='$ACCT_INFO{INBYTE2}',
    ex_output_octets='$ACCT_INFO{OUTBYTE2}',
    framed_ip_address=INET_ATON('$RAD{FRAMED_IP_ADDRESS}'),
    lupdated=UNIX_TIMESTAMP()
   WHERE
    acct_session_id=\"$RAD{ACCT_SESSION_ID}\" and 
    user_name=\"$RAD{USER_NAME}\" and
    nas_ip_address=INET_ATON('$RAD{NAS_IP_ADDRESS}');";

  log_print('LOG_SQL', "ACCT [$RAD{USER_NAME}] SQL: $sql");     
  $q = $db->do("$sql") || die $db->errstr;
}
else {
  log_print('LOG_WARNING', "ACCT [$RAD{USER_NAME}] Unknown accounting status: $RAD{ACCT_STATUS_TYPE} ($RAD{ACCT_SESSION_ID})");
}



#detalization for Exppp
if ($conf{s_detalization} eq 'yes') {
  $sql = "INSERT into s_detail (acct_session_id, nas_id, uid, acct_status, last_update, 
    sent1, recv1, sent2, recv2, id)
  VALUES (\"$RAD{ACCT_SESSION_ID}\", '$nas_num', '$RAD{USER_NAME}', '$acct_status_type', UNIX_TIMESTAMP(),
   '$ACCT_INFO{INTERIUM_INBYTE}', '$ACCT_INFO{INTERIUM_OUTBYTE}', 
   '$ACCT_INFO{INTERIUM_INBYTE2}', '$ACCT_INFO{INTERIUM_OUTBYTE2}', '$RAD{USER_NAME}');";

  log_print('LOG_SQL', "ACCT [$RAD{USER_NAME}] SQL: $sql");
  $q = $db->do("$sql") || die $db->errstr;
}

 my $GT = '';
 if ($begin_time > 0)  {
   my $end_time = gettimeofday();
   my $gen_time = $end_time - $begin_time;
   $GT = sprintf(" GT: %2.5f", $gen_time);
  }

log_print('LOG_DEBUG', "ACCT [$RAD{USER_NAME}] accounting status: $RAD{ACCT_STATUS_TYPE} ($RAD{ACCT_SESSION_ID})$GT");

}



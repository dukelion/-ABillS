#!/usr/bin/perl

use vars  qw(%RAD %conf $db);
use strict;

use FindBin '$Bin';
require $Bin . '/config.pl';
my $begin_time = check_time();
require $Bin . '/sql.pl';


=comments
        MS-CHAP-Challenge = 0x32323738343134393536353333333635
        MS-CHAP2-Response = 0x010017550ce222cfa39d348b93e93cd26f1a000000000000000026fe1a5e39097393b8a4ade5a466790bbefab075383ec58b

        MS-CHAP2-Success = 0x01533d30424446454530444634373846434335464338453041423939444344453842373341303835373245
        MS-MPPE-Recv-Key = 0x27ac8322247937ad3010161f1d5bbe5c
        MS-MPPE-Send-Key = 0x4f835a2babe6f2600a731fd89ef25a38
        MS-MPPE-Encryption-Policy = 0x00000001
        MS-MPPE-Encryption-Types = 0x00000006
=cut


####################################################################

get_radius_params();
test_radius_returns();
#####################################################################

if ($ARGV[0] eq 'pre_auth') { 
  pre_auth("$RAD{USER_NAME}");
  exit 0;
}

my $nas_num=-1;
my $NAS_INFO = nas_params();
# Max session tarffic limit  (Mb)
$conf{MAX_SESSION_TRAFFIC} = 2048; 

#my $aaa = `echo $ARGV[0] >> /tmp/argvvv`;

if (defined($NAS_INFO->{"$RAD{NAS_IP_ADDRESS}"})) {
   $nas_num = $NAS_INFO->{"$RAD{NAS_IP_ADDRESS}"};
 }
else {
   access_deny("$RAD{USER_NAME}", "Unknow server '$RAD{NAS_IP_ADDRESS}'", $nas_num);
   exit 1;
}


my $authtype = (defined($RAD{CHAP_PASSWORD}) && defined($RAD{CHAP_CHALLENGE})) ? 0 : $NAS_INFO->{at}{$nas_num};
my $nas_type  = $NAS_INFO->{nt}{$nas_num} || '';
my %RAD_PAIRS = ();
my $message = "";

auth();

my $rc  = $db->disconnect;

#*******************************************************************
# auth();
#*******************************************************************
sub auth {
 my $r = 1;
 my $GT = '';
 my $rr='';

 $r = authentication("$RAD{USER_NAME}", "$nas_num");

 #Show pairs
 while(my($rs, $ls)=each %RAD_PAIRS) {
   $rr .= "$rs = $ls,\n";	
  }
 print $rr;

 log_print('LOG_DEBUG', "AUTH [$RAD{USER_NAME}] $rr");

 if($r == 1) {
    print "Reply-Message = $message,\n";
    access_deny("$RAD{USER_NAME}", "$message", $nas_num);
  }

 print $NAS_INFO->{rp}{$nas_num};
 if ($begin_time > 0)  {
   my $end_time = gettimeofday();
   my $gen_time = $end_time - $begin_time;
   $GT = sprintf(" GT: %2.5f", $gen_time);
  }

 log_print('LOG_INFO', "AUTH [$RAD{USER_NAME}] NAS: $nas_num ($RAD{NAS_IP_ADDRESS})$GT");
 exit $r;	
}

#*******************************************************************
# POst authenti[ication
# authentication($USER, $nas_num)
#*******************************************************************
sub authentication {
 my ($USER, $nas_num) = @_;

my $sql = qq{
select
  u.uid,
  u.deposit + u.credit - v.credit_tresshold,
  if (u.logins=0, v.logins, u.logins) AS logins,
  u.filter_id,
  if(u.ip>0, INET_NTOA(u.ip), 0),
  INET_NTOA(u.netmask),
  u.variant,
  DECODE(password, '$conf{secretkey}'),
  u.speed,
  u.cid,
  v.day_time_limit,
  v.week_time_limit,
  v.month_time_limit,
  if(v.day_time_limit=0 and v.dt='0:00:00' AND v.ut='24:00:00',
   UNIX_TIMESTAMP(DATE_FORMAT(DATE_ADD(curdate(), INTERVAL 1 MONTH), '%Y-%m-01')) - UNIX_TIMESTAMP(),
  TIME_TO_SEC(v.ut)-TIME_TO_SEC(curtime())) as today_limit,
  day_traf_limit,
  week_traf_limit,
  month_traf_limit,
  if(v.hourp + v.df + v.abon=0 and sum(tt.in_price + tt.out_price)=0, 0, 1),
  if (count(un.uid) + count(vn.vid) = 0, 0,
    if (count(un.uid)>0, 1, 2)),
  count(tt.id),
  v.hourp,
  u.filter_id,
  UNIX_TIMESTAMP(),
  UNIX_TIMESTAMP(DATE_FORMAT(FROM_UNIXTIME(UNIX_TIMESTAMP()), '%Y-%m-%d')),
  DAYOFWEEK(FROM_UNIXTIME(UNIX_TIMESTAMP())),
  DAYOFYEAR(FROM_UNIXTIME(UNIX_TIMESTAMP()))
     FROM users u, variant v
     LEFT JOIN  trafic_tarifs tt ON (tt.vid=u.variant)
     LEFT JOIN users_nas un ON (un.uid = u.uid)
     LEFT JOIN vid_nas vn ON (vn.vid = v.vrnt)
     WHERE u.variant=v.vrnt
        AND u.id='$USER'
        AND (u.expire='0000-00-00' or u.expire > CURDATE())
        AND (u.activate='0000-00-00' or u.activate =< CURDATE())
        AND v.dt < CURTIME()
        AND CURTIME() < v.ut
       GROUP BY u.id
};

  log_print('LOG_SQL', "$sql");

  my $q = $db->prepare("$sql") || die $db->errstr;
  $q -> execute();

  if ($q->rows < 1) {
    $message = "Access denied";
    return 1;
  }
my($uid, $deposit, $logins, $filter, $ip, $netmask, $vid, $passwd, $uspeed, $cid, 
   $day_time_limit, $week_time_limit, $month_time_limit,  $today_limit,  
   $day_traf_limit,  $week_traf_limit,  $month_traf_limit, 
   $tp_payment,
   $nas, $traf_tarif, $time_tarif, $filter_id,
   $session_start, $day_begin, $day_of_week, $day_of_year) = $q -> fetchrow();

#Check allow nas server
# $nas 1 - See user nas
#      2 - See variant nas
 if ($nas > 0) {
   if ($nas == 1) {
      $sql = "SELECT un.uid FROM users_nas un WHERE un.uid='$uid' and un.nas_id='$nas_num'";
     }
   else {
      $sql = "SELECT nas_id FROM vid_nas WHERE vid='$vid' and nas_id='$nas_num'";
     }

   log_print('LOG_SQL', "$sql");
   my $q = $db->prepare("$sql") || die $db->errstr;
   $q -> execute();

   if ($q->rows < 1) {
     $message = "You are not authorized to log in $nas_num ($RAD{NAS_IP_ADDRESS})";
     return 1;
    }
  }

#Check CID (MAC) 
if ($cid ne '') {
   if ($cid =~ /:/ && $cid !~ /\//) {
      my @MAC_DIGITS_NEED=split(/:/, $cid);
      my @MAC_DIGITS_GET=split(/:/, $RAD{CALLING_STATION_ID});
      for(my $i=0; $i<=5; $i++) {
        if(hex('0x'.$MAC_DIGITS_NEED[$i]) != hex('0x'. $MAC_DIGITS_GET[$i])) {
          $message = "Wrong MAC '$RAD{CALLING_STATION_ID}'";
          return 1;
         }
       }
    }
   elsif($cid =~ /\//) {
     $RAD{CALLING_STATION_ID} =~ s/ //g;
     my ($cid_ip, $cid_mac, $trash) = split(/\//, $RAD{CALLING_STATION_ID}, 3);
     if ("$cid_ip/$cid_mac" ne $cid) {
       $message = "Wrong CID '$cid_ip/$cid_mac'";
       return 1;
      }
    }
   elsif($cid ne $RAD{CALLING_STATION_ID}) {
     $message = "Wrong CID '$RAD{CALLING_STATION_ID}'";
     return 1;
    }
}

#Auth chap
if (defined($RAD{CHAP_PASSWORD}) && defined($RAD{CHAP_CHALLENGE})) {
  if (check_chap("$RAD{CHAP_PASSWORD}", "$passwd", "$RAD{CHAP_CHALLENGE}", 0) == 0) {
    $message = "Wrong CHAP password '$passwd'";
    return 1;
   }      	 	
 }
#Auth MS-CHAP v1,v2
elsif(defined($RAD{MS_CHAP_CHALLENGE})) {
  # Its an MS-CHAP V2 request
  # See draft-ietf-radius-ms-vsa-01.txt,
  # draft-ietf-pppext-mschap-v2-00.txt, RFC 2548, RFC3079
  $RAD{MS_CHAP_CHALLENGE} =~ s/^0x//;
  my $challenge = pack("H*", $RAD{MS_CHAP_CHALLENGE});
  my ($usersessionkey, $lanmansessionkey, $ms_chap2_success);

  if (defined($RAD{MS_CHAP2_RESPONSE})) {
     $RAD{MS_CHAP2_RESPONSE} =~ s/^0x//; 
     my $rad_response = pack("H*", $RAD{MS_CHAP2_RESPONSE});
     my ($ident, $flags, $peerchallenge, $reserved, $response) = unpack('C C a16 a8 a24', $rad_response);

     if (check_mschapv2("$RAD{USER_NAME}", $passwd, $challenge, $peerchallenge, $response, $ident,
 	     \$usersessionkey, \$lanmansessionkey, \$ms_chap2_success) == 0) {
         $message = "Wrong MS-CHAP2 password";
         $RAD_PAIRS{'MS-CHAP-Error'}="\"$message\"";
         return 1;
	    }

     $RAD_PAIRS{'MS-CHAP2-SUCCESS'} = '0x' . bin2hex($ms_chap2_success);

     my ($send, $recv) = Radius::MSCHAP::mppeGetKeys($usersessionkey, $response, 16);


# MPPE Sent/Recv Key Not realizet now.
#        print "\n--\n'$usersessionkey'\n'$response'\n'$send'\n'$recv'\n--\n";
#        $RAD_PAIRS{'MS-MPPE-Send-Key'}="0x".bin2hex( substr(encode_mppe_key($send, $radsecret, $challenge), 0, 16));
#	       $RAD_PAIRS{'MS-MPPE-Recv-Key'}="0x".bin2hex( substr(encode_mppe_key($recv, $radsecret, $challenge), 0, 16));

#        my $radsecret = 'test';
#         $RAD_PAIRS{'MS-MPPE-Send-Key'}="0x".bin2hex(encode_mppe_key($send, $radsecret, $challenge));
#	       $RAD_PAIRS{'MS-MPPE-Recv-Key'}="0x".bin2hex(encode_mppe_key($recv, $radsecret, $challenge));

#        $RAD_PAIRS{'MS-MPPE-Send-Key'}='0x4f835a2babe6f2600a731fd89ef25a38';
#	       $RAD_PAIRS{'MS-MPPE-Recv-Key'}='0x27ac8322247937ad3010161f1d5bbe5c';
	       
        }
       else {
         if (check_mschap("$passwd", "$RAD{MS_CHAP_CHALLENGE}", "$RAD{MS_CHAP_RESPONSE}", 
	           \$usersessionkey, \$lanmansessionkey, \$message) == 0) {
           $message = "Wrong MS-CHAP password";
           $RAD_PAIRS{'MS-CHAP-Error'}="\"$message\"";
           return 1;
          }
        }

       $RAD_PAIRS{'MS-CHAP-MPPE-Keys'} = '0x' . unpack("H*", (pack('a8 a16', $lanmansessionkey, 
														$usersessionkey))) . "0000000000000000";

       # 1      Encryption-Allowed 
       # 2      Encryption-Required 
       $RAD_PAIRS{'MS-MPPE-Encryption-Policy'} = '0x00000001';
       $RAD_PAIRS{'MS-MPPE-Encryption-Types'} = '0x00000006';      
 }
#End MSchap auth
elsif($authtype == 1) {
  if (check_systemauth("$RAD{USER_NAME}", "$RAD{USER_PASSWORD}") == 0) { 
     $message = "Wrong password '$RAD{USER_PASSWORD}' $authtype";
     return 1;    	
   }
 } 
#If don't athorize any above methods auth PAP password
else {
  if($passwd ne "$RAD{USER_PASSWORD}") {
    $message = "Wrong password '$RAD{USER_PASSWORD}'";
    return 1;
   }
}



#Check deposit
if($tp_payment > 0 && $deposit <= 0) {
  $message = "User don't have money account '$deposit'. Rejected!";
  return 1;
 }

#Check  simultaneously logins if needs
if ($logins > 0) {
  $sql = "SELECT count(*) FROM calls WHERE user_name='$USER' and status <> 2;";
  log_print('LOG_SQL', "$sql");
       
   $q = $db->prepare($sql) || die $db->errstr;
   $q ->execute();
  my $total = $q->rows();
  my($active_logins) = $q->fetchrow();
  if ($active_logins >= $logins) {
    $message = "More then allow login ($logins/$active_logins)";
    return 1;
   }
}


#Time limits
# 0 - Total limit
# 1 - Day limit
# 2 - Week limit
# 3 - Month limit
my @time_limits=();
my @traf_limits= ();
my $time_limit = 0; 
my $traf_limit = $conf{MAX_SESSION_TRAFFIC};

     if (($day_time_limit > 0) || ($day_traf_limit > 0)) {
        $sql = "SELECT if($day_time_limit > 0, $day_time_limit - sum(duration), 0),
                       if($day_traf_limit > 0, $day_traf_limit - sum(sent + recv) / 1024 / 1024, 0) FROM log
            WHERE id='$USER' and DATE_FORMAT(login, '%Y-%m-%d')=curdate()
            GROUP BY DATE_FORMAT(login, '%Y-%m-%d');";

        $q = $db->prepare($sql) || die $db->errstr;
        $q ->execute();
        if ($q->rows == 0) {
          push (@time_limits, $day_time_limit) if ($day_time_limit > 0);
          push (@traf_limits, $day_traf_limit) if ($day_traf_limit > 0);
         } 
        else {
          ($time_limit, $traf_limit) = $q->fetchrow();
          push (@time_limits, $time_limit) if ($day_time_limit > 0);
          push (@traf_limits, $traf_limit) if ($day_traf_limit > 0);
         }
       }


     if (($week_time_limit > 0) || ($week_traf_limit > 0)) {
        $sql = "SELECT if($week_time_limit > 0, $week_time_limit - sum(duration), 0),
                       if($week_traf_limit > 0, $week_traf_limit - sum(sent+recv)  / 1024 / 1024, 0) FROM log
                 WHERE id='$USER' and (WEEK(login)=WEEK(curdate()) and YEAR(LOGIN)=YEAR(CURDATE()))
                 GROUP BY WEEK(login)=WEEK(curdate()),YEAR(LOGIN)=YEAR(CURDATE());";
      
        $q = $db->prepare($sql) || die $db->errstr;
        $q ->execute();
        if ($q->rows == 0) {
          push (@time_limits, $week_time_limit) if ($day_time_limit > 0);
          push (@traf_limits, $week_traf_limit) if ($day_traf_limit > 0);
         } 
        else {
          ($time_limit, $traf_limit) = $q->fetchrow();
          push (@time_limits, $time_limit) if ($day_time_limit > 0);
          push (@traf_limits, $traf_limit) if ($day_traf_limit > 0);
         }
       }

     if($month_time_limit > 0 || ($month_traf_limit > 0)) {
        $sql = "SELECT if($month_time_limit > 0, $month_time_limit - sum(duration), 0), 
                       if($month_traf_limit > 0, $month_traf_limit - sum(sent+recv)  / 1024 / 1024, 0) FROM log 
           WHERE id='$USER' and DATE_FORMAT(login, '%Y-%m')=DATE_FORMAT(curdate(), '%Y-%m')
           GROUP BY DATE_FORMAT(login, '%Y-%m');";
        
        $q = $db->prepare($sql) || die $db->errstr;
        $q ->execute();

        if ($q->rows == 0) {
          push (@time_limits, $month_time_limit) if ($month_time_limit > 0);
          push (@traf_limits, $month_traf_limit) if ($month_traf_limit > 0);
         } 
        else {
          ($time_limit, $traf_limit) = $q->fetchrow();
          push (@time_limits, $time_limit) if ($month_time_limit > 0);
          push (@traf_limits, $traf_limit) if ($month_traf_limit > 0);
         }
       }


#set traffic limit
     #push (@traf_limits, $prepaid_traff) if ($prepaid_traff > 0);




     for(my $i=0; $i<=$#traf_limits; $i++) {
        if ($traf_limit > $traf_limits[$i]) {

           $traf_limit = int($traf_limits[$i]);
         }
      }

     if($traf_limit < 0) {
       $message = "Rejected! Traffic limit utilized '$traf_limit Mb'";
       return 1;
      }

     if ($time_tarif > 0) {
       #push (@time_limits, int(($deposit / $time_tarif) *  60 * 60))  if ($time_tarif > 0);
       push (@time_limits, remaining_time($vid, $deposit, 
                                                $session_start, 
                                                $day_begin, 
                                                $day_of_week, 
                                                $day_of_year,
                                                { mainh_tarif => $time_tarif,
                                                  time_limit  => $today_limit  } 
                                          )
            );
      }

#set time limit
     $time_limit = $today_limit;
     for(my $i=0; $i<=$#time_limits; $i++) {
        if ($time_limit > $time_limits[$i]) {
           $time_limit = $time_limits[$i];
          }
       }

     if ($time_limit > 0) {
       $RAD_PAIRS{'Session-Timeout'} = "$time_limit";
      }
     elsif($time_limit < 0) {
       $message = "Rejected! Time limit utilized '$time_limit'";
       return 1; 
      }

     # Return radius attr    
     if ($ip ne '0') {
        $RAD_PAIRS{'Framed-IP-Address'} = "$ip";
      }
     else {
        $ip = get_ip($nas_num, "$RAD{NAS_IP_ADDRESS}");
        if ($ip == -1) {
          $message = "Rejected! There is no free IPs in address pools ($nas_num)";
          return 1; 
         }
        elsif($ip > 0) {
     	  $RAD_PAIRS{'Framed-IP-Address'} = "$ip";
     	 }
      }

     $RAD_PAIRS{'Framed-IP-Netmask'} = "$netmask";
     $RAD_PAIRS{'Filter-Id'} = "$filter_id" if (length($filter_id) > 0); 


####################################################################
# Vendor specific return
# ExPPP

my $v_speed=0;

if ($NAS_INFO->{nt}{$nas_num} eq 'exppp') {

  #$traf_tarif 
  my $EX_PARAMS = ex_params($vid, "$USER", { traf_limit => $traf_limit, 
                                            deposit => $deposit });

  #global Traffic
  if ($EX_PARAMS->{traf_limit} > 0) {
    $RAD_PAIRS{'Exppp-Traffic-Limit'} = $EX_PARAMS->{traf_limit} * 1024 * 1024;
   }

  #Local traffic
  if ($EX_PARAMS->{traf_limit_lo} > 0) {
    $RAD_PAIRS{'Exppp-LocalTraffic-Limit'} = $EX_PARAMS->{traf_limit_lo} * 1024 * 1024 ;
   }
       
  #Local ip tables
  if (defined($EX_PARAMS->{nets})) {
    $RAD_PAIRS{'Exppp-Local-IP-Table'} = "\"$conf{netsfilespath}$vid.nets\"";
   }

  #Shaper
  if ($uspeed > 0) {
    $RAD_PAIRS{'Exppp-Traffic-Shape'} = int($uspeed);
   }
  else {
    if ($EX_PARAMS->{speed}  > 0) {
      $RAD_PAIRS{'Exppp-Traffic-Shape'} = $EX_PARAMS->{speed};
     }
   }

=comments
        print "Exppp-Traffic-In-Limit = $trafic_inlimit,";
        print "Exppp-Traffic-Out-Limit = $trafic_outlimit,";
        print "Exppp-LocalTraffic-In-Limit = $trafic_lo_inlimit,";
        print "Exppp-LocalTraffic-Out-Limit = $trafic_lo_outlimit,";
=cut
 }
###########################################################
# MPD
elsif ($NAS_INFO->{nt}{$nas_num} eq 'mpd') {
  my $EX_PARAMS = ex_params($vid, "$USER", { traf_limit => $traf_limit, 
                                              deposit => $deposit });
 
  #global Traffic
  if ($EX_PARAMS->{traf_limit} > 0) {
    $RAD_PAIRS{'Exppp-Traffic-Limit'} = $EX_PARAMS->{traf_limit} * 1024 * 1024;
   }
       
#Shaper
#  if ($uspeed > 0) {
#    $RAD_PAIRS{'mpd-rule'} = "\"1=pipe %p1 ip from any to any\"";
#    $RAD_PAIRS{'mpd-pipe'} = "\"1=bw ". $uspeed ."Kbyte/s\"";
#   }
#  else {
#    if ($v_speed > 0) {
#      $RAD_PAIRS{'Exppp-Traffic-Shape'} = $v_speed;
#      $RAD_PAIRS{'mpd-rule'} = "1=pipe %p1 ip from any to any";
#      $RAD_PAIRS{'mpd-pipe'} = "1=bw ". $v_speed ."Kbyte/s";
#     }
#   }
 
  log_print('LOG_DEBUG', "MPD");
 }
###########################################################
# pppd + RADIUS plugin (Linux) http://samba.org/ppp/
elsif ($NAS_INFO->{nt}{$nas_num} eq 'pppd') {
  my $EX_PARAMS = ex_params($vid, "$USER", { traf_limit => $traf_limit, 
                                             deposit => $deposit });
  #global Traffic
  if ($EX_PARAMS->{traf_limit} > 0) {
    $RAD_PAIRS{'Session-Octets-Limit'} = $EX_PARAMS->{traf_limit} * 1024 * 1024;
    $RAD_PAIRS{'Octets-Direction'} = 0;
   }

  log_print('LOG_DEBUG', "Linux pppd");
 }



#####################################################################
   return 0;	
}


#*******************************************************************
# Extended parameters
# ex_params($vid)
#*******************************************************************
sub ex_params {
 my ($vid, $uid, $attr) = @_;	
 my $traf_limit = $attr->{traf_limit};
 my $deposit = (defined($attr->{deposit})) ? $attr->{deposit} : 0;

 my %EX_PARAMS = ();
 $EX_PARAMS{speed}=0;
 $EX_PARAMS{traf_limit}=0;
 $EX_PARAMS{traf_limit_lo}=0;

 my %prepaids = ();
 my %speeds = ();
 my %in_prices = ();
 my %out_prices = ();
 my %trafic_limits = ();
 
 
 #get traffic limits
# if ($traf_tarif > 0) {
   my $nets = 0;
   my $sql = "SELECT id, in_price, out_price, prepaid, speed, LENGTH(nets) FROM trafic_tarifs
             WHERE vid='$vid';";
   my $q = $db->prepare($sql) || die $db->errstr;
   $q ->execute();

   while(my($tt_id, $in_price, $out_price, $prepaid, $speed, $net) = $q->fetchrow()) {
     $prepaids{$tt_id}=$prepaid;
     $in_prices{$tt_id}=$in_price;
     $out_prices{$tt_id}=$out_price;
     $speeds{$tt_id}=$speed;
     $nets+=$net;
    }

   $EX_PARAMS{nets}=$nets if ($nets > 20);
   $EX_PARAMS{speed}=int($speeds{0});

#  }
# else {
#   return %EX_PARAMS;	
#  }


if ($prepaids{0}+$prepaids{1}>0) {
  $sql = "SELECT sum(sent+recv) / 1024 / 1024, sum(sent2+recv2) / 1024 / 1024 FROM log 
     WHERE id='$uid' and DATE_FORMAT(login, '%Y-%m')=DATE_FORMAT(curdate(), '%Y-%m')
     GROUP BY DATE_FORMAT(login, '%Y-%m');";

  $q = $db->prepare($sql) || die $db->errstr;
  $q ->execute();

  if ($q->rows == 0) {
    $trafic_limits{0}=$prepaids{0};
    $trafic_limits{1}=$prepaids{1};
   }
  else {
    my @used = $q->fetchrow();

    if ($used[0] < $prepaids{0}) {
      $trafic_limits{0}=$prepaids{0} - $used[0];
     }
    elsif($in_prices{0} + $out_prices{0} > 0) {
      $trafic_limits{0} = ($deposit / (($in_prices{0} + $out_prices{0}) / 2));
     }

    if ($used[1]  < $prepaids{1}) {
      $trafic_limits{1}=$prepaids{1} - $used[1];
     }
    elsif($in_prices{1} + $out_prices{1} > 0) {
      $trafic_limits{1} = ($deposit / (($in_prices{1} + $out_prices{1}) / 2));
     }
   }
   
 }
else {
  if ($in_prices{0}+$out_prices{0} > 0) {
    $trafic_limits{0} = ($deposit / (($in_prices{0} + $out_prices{0}) / 2));
   }

  if ($in_prices{1}+$out_prices{1} > 0) {
    $trafic_limits{1} = ($deposit / (($in_prices{1} + $out_prices{1}) / 2));
   }
  else {
    $trafic_limits{1} = 0;
   }
}

#Traffic limit


my $trafic_limit = 0;
if ($trafic_limits{0} > 0 || $traf_limit > 0) {
  if($trafic_limits{0} > $traf_limit && $traf_limit > 0) {
    $trafic_limit = $traf_limit;
   }
  elsif($trafic_limits{0} > 0) {
    #$trafic_limit = $trafic_limit * 1024 * 1024;
    #2Gb - (2048 * 1024 * 1024 ) - global traffic session limit
    $trafic_limit = ($trafic_limits{0} > $conf{MAX_SESSION_TRAFFIC}) ? $conf{MAX_SESSION_TRAFFIC} :  $trafic_limits{0};
   }
  else {
  	$trafic_limit = $traf_limit;
   }

  $EX_PARAMS{traf_limit} = int($trafic_limit);
}

#Local Traffic limit
if ($trafic_limits{1} > 0) {
  #10Gb - (10240 * 1024 * 1024) - local traffic session limit
  $trafic_limit = ($trafic_limits{1} > 10240) ? 10240 :  $trafic_limits{1};
  $EX_PARAMS{traf_limit_lo} = int($trafic_limit);
 }

 return \%EX_PARAMS;
}


#********************************************************************
# remaining_time
#********************************************************************
sub remaining_time {
  my ($vid, $deposit, $session_start, 
  $day_begin, $day_of_week, $day_of_year,
  $attr) = @_;
 
  my $time_limit = (defined($attr->{time_limit})) ? $attr->{time_limit} : 0;
  my $mainh_tarif = (defined($attr->{mainh_tarif})) ? $attr->{mainh_tarif} : 0;
  my $remaining_time = 0;


 my ($time_intervals, $interval_tarifs) = time_intervals($vid);

 if ($time_intervals == 0) {
    return 0;
    #return $deposit / $mainh_tarif * 60 * 60;	
  }
 
 my $holidays;
 if (defined($time_intervals->{8})) {
   $holidays = holidays_show({ format => 'daysofyear' });
  }


 my $tarif_day = 0;
 my $count = 0;
 $session_start = $session_start - $day_begin;

 while(($deposit > 0 && $count < 50)) {

  if ($time_limit != 0 && $time_limit < $remaining_time) {
     $remaining_time = $time_limit;
     last;
   }

    if (defined($time_intervals->{$day_of_week})) {
    	#print "Day tarif";
    	$tarif_day = $day_of_week;
     }
    elsif(defined($holidays->{$day_of_year}) && defined($time_intervals->{8})) {
    	#print "Holliday tarif '$day_of_year' ";
    	$tarif_day = 8;
     }
    else {
        #print "Normal tarif";
        $tarif_day = 0;
     }


     $count++;
     #print "$count) Tariff day: $tarif_day ($day_of_week / $day_of_year)\n";
     #print "Session start: $session_start\n";
     #print "Deposit: $deposit\n--------------\n";

     my $cur_int = $time_intervals->{$tarif_day};
     my $i = 0;
     while(my($int_begin, $int_end)=each %$cur_int) {
       my $price = 0;
       my $int_prepaid = 0;
       my $int_duration = 0;
       #$i++;
       #print "!! $int_begin, $int_end\n";
       #print "   $i) ";
       if ($int_begin <= $session_start && $session_start <= $int_end) {
          $int_duration = $int_end-$session_start;

          if ($interval_tarifs->{$tarif_day}{$int_begin} =~ /%$/) {
             my $tp = $interval_tarifs->{$tarif_day}{$int_begin};
             $tp =~ s/\%//;
             $price = $mainh_tarif  * ($tp / 100);
           }
          else {
             $price = $interval_tarifs->{$tarif_day}{$int_begin};
           }

          if ($price > 0) {
            $int_prepaid = $deposit / $price * 3600;
           }
          else {
            $int_prepaid = $int_duration;	
           }
          #print "Int Begin: $int_begin Int duration: $int_duration Int prepaid: $int_prepaid Prise: $price\n";



          if ($int_prepaid >= $int_duration) {
            $deposit -= ($int_duration / 3600 * $price);
            $session_start += $int_duration;
            $remaining_time += $int_duration;
            #print "DP $deposit ($int_prepaid > $int_duration) $session_start\n";
           }
          elsif($int_prepaid <= $int_duration) {
            $deposit =  0;          	
            $session_start += $int_prepaid;
            $remaining_time += $int_duration;
            #print "DL '$deposit' ($int_prepaid <= $int_duration) $session_start\n";
           }
         
        }

      }

  if ($session_start >= 86400) {
    $session_start=0;
    $day_of_week = ($day_of_week + 1 > 7) ? 1 : $day_of_week+1;
    $day_of_year = ($day_of_year + 1 > 365) ? 1 : $day_of_year + 1;
  }
 
 }

return int($remaining_time);
}




#*******************************************************************
# Authorization module
# pre_auth()
#*******************************************************************
sub pre_auth {
  my ($login)=@_;

if (! $RAD{MS_CHAP_CHALLENGE}) {
  print "Auth-Type := Accept\n";
  exit 0;
 }

  my $sql = "SELECT DECODE(password, '$conf{secretkey}') FROM users WHERE id='$login';";
  my $q = $db->prepare("$sql") || die $db->errstr;
  $q -> execute();

  if ($q->rows > 0) {
    my($password) = $q -> fetchrow();
    print "User-Password == \"$password\"";
    exit 0;
   }

  $message = "USER: '$login' not exist";
  exit 1;
}



#####################################################################
# Overrideable function that checks a MSCHAP password response
# $p is the current request
# $username is the users (rewritten) name
# $pw is the ascii plaintext version of the correct password if known
# rfc2548 Microsoft Vendor-specific RADIUS Attributes
sub check_mschap {
  my ($pw, $challenge, $response, $usersessionkeydest, $lanmansessionkeydest, $message) = @_;

  use lib $Bin;
  use MSCHAP;

  $response =~ s/^0x//; 
  $challenge =~ s/^0x//;
  $challenge = pack("H*", $challenge);
  $response = pack("H*", $response);
  my($ident, $flags, $lmresponse, $ntresponse) = unpack('C C a24 a24', $response);

  if ($flags == 1) {
    my $upw = Radius::MSCHAP::ASCIItoUnicode($pw);
    #return Radius::MSCHAP::NtChallengeResponse($challenge, $upw);
    return unless Radius::MSCHAP::NtChallengeResponse($challenge, $upw) eq $ntresponse;
    # Maybe generate a session key. 
    
    $$usersessionkeydest = Radius::MSCHAP::NtPasswordHash(Radius::MSCHAP::NtPasswordHash($upw))
	if defined $usersessionkeydest;
    $$lanmansessionkeydest = Radius::MSCHAP::LmPasswordHash($pw)
	if defined $lanmansessionkeydest;

#      $RAD_PAIRS{'MS-CHAP-MPPE-Keys'} = '0x' . unpack("H*", (pack('a8 a16', Radius::MSCHAP::LmPasswordHash($pw), 
#                                                                            Radius::MSCHAP::NtPasswordHash( Radius::MSCHAP::NtPasswordHash(Radius::MSCHAP::ASCIItoUnicode($pw)))))). "0000000000000000";
   }
  else {
     $$message = "MS-CHAP LM-response not implemented";
     #log_print('LOG_ERR', "MS-CHAP LM-response not implemented");
     return 0;
   }
  
  return 1;

}


#####################################################################
# $p is the current request
# Overrideable function that checks a MSCHAP password response
# $username is the users (rewritten) name
# $pw is the ascii plaintext version of the correct password if known
# $sessionkeydest is a ref to a string where the sesiosn key for MPPE will be returned
sub check_mschapv2
{
    my ($username, $pw, $challenge, $peerchallenge, $response, $ident,
	$usersessionkeydest, $lanmansessionkeydest,  $ms_chap2_success) = @_;


  use lib $Bin;
  use MSCHAP;

  my $upw = Radius::MSCHAP::ASCIItoUnicode($pw);
  return 
  unless &Radius::MSCHAP::GenerateNTResponse($challenge, $peerchallenge, $username, $upw) 
	       eq $response;


    # Maybe generate a session key. 
    $$usersessionkeydest = Radius::MSCHAP::NtPasswordHash
	(Radius::MSCHAP::NtPasswordHash($upw))
	if defined $usersessionkeydest;
    $$lanmansessionkeydest = Radius::MSCHAP::LmPasswordHash($pw)
	if defined $lanmansessionkeydest;

   
    $$ms_chap2_success=pack('C a42', $ident,
			  &Radius::MSCHAP::GenerateAuthenticatorResponseHash
			  ($$usersessionkeydest, $response, $peerchallenge, $challenge, "$username"))
			  if defined $ms_chap2_success;


    return 1;
}


#*******************************************************************
# Check chap password
# check_chap($given_password,$want_password,$given_chap_challenge,$debug) 
#*******************************************************************
sub check_chap {
 eval { require Digest::MD5; };
 if (! $@) {
    Digest::MD5->import();
   }
 else {
    log_print('LOG_ERR', "Can't load 'Digest::MD5' check http://www.cpan.org");
  }

my ($given_password,$want_password,$given_chap_challenge,$debug) = @_;

        $given_password =~ s/^0x//;
        $given_chap_challenge =~ s/^0x//;
        my $chap_password = pack("H*", $given_password);
        my $chap_challenge = pack("H*", $given_chap_challenge);
        my $md5 = new Digest::MD5;
        $md5->reset;
        $md5->add(substr($chap_password, 0, 1));
        $md5->add($want_password);
        $md5->add($chap_challenge);
        my $digest = $md5->digest();
        if ($digest eq substr($chap_password, 1)) { 
           return 1; 
          }
        else {
           return 0;
          }

}


#********************************************************************
# System auth function
# check_systemauth($user, $password)
#********************************************************************
sub check_systemauth {
 my ($user, $password)= @_;

 if ($< != 0) {
   log_print('LOG_ERR', "For system Authentification you need root privileges");
   exit 1;
  }

 my @pw = getpwnam("$user");

 if ($#pw < 0) {
    return 0;
  }
 
 my $salt = "$pw[1]";
 my $ep = crypt($password, $salt);

 if ($ep eq $pw[1]) {
    return 1;
  }
 else {
    return 0;
  }
}


#*******************************************************************
# returns:
#   -1 - No free adddress
#    0 - No address pool using nas servers ip address
#   192.168.101.1 - assign ip address
#
# get_ip($nas_num, $nas_ip)
#*******************************************************************
sub get_ip {
 my ($nas_num, $nas_ip) = @_;
 use IO::Socket;
 
#get ip pool
 my $sql = "SELECT ippools.ip, ippools.counts 
  FROM ippools
  WHERE ippools.nas='$nas_num';";
 
 log_print('LOG_SQL', "$sql");

 my $q = $db->prepare($sql)   || die $db->errstr;
 $q ->execute();
 if ($q->rows() < 1)  {
     return 0;	
  }

 my %pools = ();
 while(my($sip, $count) = $q -> fetchrow()) {
    for(my $i=$sip; $i<=$sip+$count; $i++) {
       $pools{$i}=undef;
     }
   }

#get active address and delete from pool

 $sql = "SELECT framed_ip_address
  FROM calls 
  WHERE nas_ip_address=INET_ATON('$nas_ip') and (status=1 or status>=3);";
 log_print('LOG_SQL', "$sql");

 $q = $db->prepare($sql)   || die $db->errstr;
 $q ->execute();
 my %used_ips = ();
 while(my($ip) = $q -> fetchrow()) {
   
   if(exists($pools{$ip})) {
      delete($pools{$ip});
     }
   }
 
 my ($assign_ip, undef) = each(%pools);
 if ($assign_ip) {
   $assign_ip = inet_ntoa(pack('N', $assign_ip));
   return $assign_ip; 	
  }
 else { # no addresses available in pools
   return -1;
  }

 return 0;
}




#*******************************************************************
# Internet cards
# icards()
#*******************************************************************
sub icards {
	
 return 0;	
}


#***********************************************************
# bin2hex()
#***********************************************************
sub bin2hex ($) {
 my $bin = shift;
 my $hex = '';
 
 
 for my $c (unpack("H*",$bin)){
   $hex .= $c;
 }

 return $hex;
}



#####################################################################
# Decode an MSCHAP MPPE key as per RFC 2548
# Its almost identical to encode_tunnel_password
# except there is no tag
sub encode_mppe_key
{
 my ($pwdin, $secret, $challenge) = @_;

# print "$pwdin, $secret, $challenge\n";

 eval { require Digest::MD5; };
 if (! $@) {
    Digest::MD5->import();
   }
 else {
    log_print('LOG_ERR', "Can't load 'Digest::MD5' check http://www.cpan.org");
  }

    my $P = pack('C',  length($pwdin)) . $pwdin;
    my $A = pack('n', rand(65535) | 0x8000);
#    my $c_i = $self->authenticator . $A;     # Ciphertext blocks
# $self->authenticator
    my $c_i = $A;     # Ciphertext blocks
#print pack("H*", '3cb6fe01a41e2c56fddac4dd90604df5');
    my $C;                                   # Encrypted result


    while (length($P)) {
      $c_i = substr($P, 0, 16, undef) ^ Digest::MD5::md5($secret . $c_i);
      $C .= $c_i;
     }


#	print length($C) ."$C\n";
#print "\n$A . ". length($C) ."\n";    
#print length($A . $C);
    return $A . $C;
}

sub decode_mppe_key
{
    my ($self, $encoded, $secret) = @_;

    my ($A, $S) = unpack('a2a*', $encoded);

    my ($p, $c_i, $b_i);
    $b_i = Digest::MD5::md5($secret . $self->authenticator . $A);

    while (length($S))
    {
	    $c_i = substr($S, 0, 16, undef);
	    $p .= $c_i ^ $b_i;
	    $b_i = Digest::MD5::md5($secret . $c_i);
    }

    # Decode the length and strip off the padding NULs
    my ($len, $password) = unpack('Ca*', $p);
    substr($password, $len) = '' if ($len < length($password));
    return $password;
}



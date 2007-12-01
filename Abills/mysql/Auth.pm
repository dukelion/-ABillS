package Auth;
# Auth functions
# 14.05.2006


use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION
);

use Exporter;
$VERSION = 2.00;
@ISA = ('Exporter');
@EXPORT = qw(
  &check_chap
  &check_company_account
  &check_bill_account
);

@EXPORT_OK = ();
%EXPORT_TAGS = ();

use main;
@ISA  = ("main");

use Billing;
my $Billing;

my $db;
my $CONF;
my $debug =0;



#**********************************************************
# Init 
#**********************************************************
sub new {
  my $class = shift;
  ($db, $CONF) = @_;
  my $self = { };
  bless($self, $class);

  if (! defined($CONF->{KBYTE_SIZE})) {
  	 $CONF->{KBYTE_SIZE}=1024;
  	}
  $Billing = Billing->new($db, $CONF);


  return $self;
}

#**********************************************************
# Dialup & VPN auth
#**********************************************************
sub dv_auth {
  my $self = shift;
  my ($RAD, $NAS, $attr) = @_;
	
	
  my ($ret, $RAD_PAIRS) = $self->authentication($RAD, $NAS, $attr);

  if ($ret == 1) {
     return 1, $RAD_PAIRS;
  }
  
  my $MAX_SESSION_TRAFFIC = $CONF->{MAX_SESSION_TRAFFIC} || 2048;
 
  $self->query($db, "select  if (dv.logins=0, tp.logins, dv.logins) AS logins,
  if(dv.filter_id != '', dv.filter_id, tp.filter_id),
  if(dv.ip>0, INET_NTOA(dv.ip), 0),
  INET_NTOA(dv.netmask),
  dv.tp_id,
  dv.speed,
  dv.cid,
  tp.day_time_limit,
  tp.week_time_limit,
  tp.month_time_limit,
  UNIX_TIMESTAMP(DATE_FORMAT(DATE_ADD(curdate(), INTERVAL 1 MONTH), '%Y-%m-01')) - UNIX_TIMESTAMP(),

  tp.day_traf_limit,
  tp.week_traf_limit,
  tp.month_traf_limit,
  tp.octets_direction,

  if (count(un.uid) + count(tp_nas.tp_id) = 0, 0,
    if (count(un.uid)>0, 1, 2)),

  UNIX_TIMESTAMP(),
  UNIX_TIMESTAMP(DATE_FORMAT(FROM_UNIXTIME(UNIX_TIMESTAMP()), '%Y-%m-%d')),
  DAYOFWEEK(FROM_UNIXTIME(UNIX_TIMESTAMP())),
  DAYOFYEAR(FROM_UNIXTIME(UNIX_TIMESTAMP())),
  dv.disable,
  tp.max_session_duration,
  tp.payment_type,
  tp.credit_tresshold,
  tp.rad_pairs,
  count(i.id),
  tp.age,
  dv.callback,
  dv.port,
  tp.traffic_transfer_period,
  tp.neg_deposit_filter_id

     FROM (dv_main dv, tarif_plans tp)
     LEFT JOIN users_nas un ON (un.uid = dv.uid)
     LEFT JOIN tp_nas ON (tp_nas.tp_id = tp.id)
     LEFT JOIN intervals i ON (tp.id = i.tp_id)
     WHERE dv.tp_id=tp.id
         AND dv.uid='$self->{UID}'
     GROUP BY dv.uid;");


  if($self->{errno}) {
  	$RAD_PAIRS->{'Reply-Message'}='SQL error';
  	return 1, $RAD_PAIRS;
   }
  elsif ($self->{TOTAL} < 1) {
    $RAD_PAIRS->{'Reply-Message'}="Service not allow";
    return 1, $RAD_PAIRS;
   }

  ($self->{LOGINS}, 
     $self->{FILTER}, 
     $self->{IP}, 
     $self->{NETMASK}, 
     $self->{TP_ID}, 
     $self->{USER_SPEED}, 
     $self->{CID},
     $self->{DAY_TIME_LIMIT},  $self->{WEEK_TIME_LIMIT},   $self->{MONTH_TIME_LIMIT}, $self->{TIME_LIMIT},
     $self->{DAY_TRAF_LIMIT},  $self->{WEEK_TRAF_LIMIT},   $self->{MONTH_TRAF_LIMIT}, $self->{OCTETS_DIRECTION},
     $self->{NAS}, 
     $self->{SESSION_START}, 
     $self->{DAY_BEGIN}, 
     $self->{DAY_OF_WEEK}, 
     $self->{DAY_OF_YEAR},
     $self->{DISABLE},
     $self->{MAX_SESSION_DURATION},
     $self->{PAYMENT_TYPE},
     $self->{CREDIT_TRESSHOLD},
     $self->{TP_RAD_PAIRS},
     $self->{INTERVALS},
     $self->{ACCOUNT_AGE},
     $self->{CALLBACK},
     $self->{PORT},
     $self->{TRAFFIC_TRANSFER_PERIOD},
     $self->{NEG_DEPOSIT_FILTER_ID}
    ) = @{ $self->{list}->[0] };

#DIsable
if ($self->{DISABLE}) {
  $RAD_PAIRS->{'Reply-Message'}="Service Disable";
  return 1, $RAD_PAIRS;
 }
elsif (( $RAD_PAIRS->{'Callback-Number'} || $RAD_PAIRS->{'Ascend-Callback'} ) && $self->{CALLBACK} != 1){
  $RAD_PAIRS->{'Reply-Message'}="Callback disabled";
  return 1, $RAD_PAIRS;
}


#Check allow nas server
# $nas 1 - See user nas
#      2 - See tp nas
 if ($self->{NAS} > 0) {
   my $sql;
   if ($self->{NAS} == 1) {
      $sql = "SELECT un.uid FROM users_nas un WHERE un.uid='$self->{UID}' and un.nas_id='$NAS->{NAS_ID}'";
    }
   else {
      $sql = "SELECT nas_id FROM tp_nas WHERE tp_id='$self->{TP_ID}' and nas_id='$NAS->{NAS_ID}'";
     }

   $self->query($db, "$sql");
   
   #print "$sql $self->{NAS}";
   
   if ($self->{TOTAL} < 1) {
     $RAD_PAIRS->{'Reply-Message'}="You are not authorized to log in $NAS->{NAS_ID} ($RAD->{NAS_IP_ADDRESS})";
     return 1, $RAD_PAIRS;
    }
  }

#Check CID (MAC) 
if ($self->{CID} ne '' && $self->{CID} ne '0') {
  my ($ret, $ERR_RAD_PAIRS) = $self->Auth_CID($RAD);
  return $ret, $ERR_RAD_PAIRS if ($ret == 1);
}

#Check port
if ($self->{PORT} > 0 && $self->{PORT} != $RAD->{NAS_PORT}) {
  $RAD_PAIRS->{'Reply-Message'}="Wrong port '$RAD->{NAS_PORT}'";
  return 1, $RAD_PAIRS;
}

#Check  simultaneously logins if needs
if ($self->{LOGINS} > 0) {
  $self->query($db, "SELECT count(*) FROM dv_calls WHERE user_name='$RAD->{USER_NAME}' and status <> 2;");
  my($active_logins) = @{ $self->{list}->[0] };
  if ($active_logins >= $self->{LOGINS}) {
    $RAD_PAIRS->{'Reply-Message'}="More then allow login ($self->{LOGINS}/$active_logins)";
    return 1, $RAD_PAIRS;
   }
}


my @time_limits = ();
my $remaining_time=0;
my $ATTR;

#Chack Company account if ACCOUNT_ID > 0
if ($self->{PAYMENT_TYPE} == 0) {
  $self->{DEPOSIT}=$self->{DEPOSIT}+$self->{CREDIT}-$self->{CREDIT_TRESSHOLD};

  #Check deposit
  if($self->{DEPOSIT} <= 0) {
    $RAD_PAIRS->{'Reply-Message'}="\"Negativ deposit '$self->{DEPOSIT}'. Rejected!\"";

    #Filtering with negative deposit
    if ($self->{NEG_DEPOSIT_FILTER_ID}) {
      $RAD_PAIRS->{'Filter-Id'} = "$self->{NEG_DEPOSIT_FILTER_ID}";
      
      # Return radius attr    
      if ($self->{IP} ne '0') {
        $RAD_PAIRS->{'Framed-IP-Address'} = "$self->{IP}";
       }
      else {
        my $ip = $self->get_ip($NAS->{NAS_ID}, "$RAD->{NAS_IP_ADDRESS}");
        if ($ip eq '-1') {
          $RAD_PAIRS->{'Reply-Message'}="Rejected! There is no free IPs in address pools (USED: $self->{USED_IPS})";
          return 1, $RAD_PAIRS;
         }
        elsif($ip eq '0') {
          #$RAD_PAIRS->{'Reply-Message'}="$self->{errstr} ($NAS->{NAS_ID})";
          #return 1, $RAD_PAIRS;
         }
        else {
          $RAD_PAIRS->{'Framed-IP-Address'} = "$ip";
         }
       }

      return 0, $RAD_PAIRS;
     }

    return 1, $RAD_PAIRS;
   }
 }
else {
  $self->{DEPOSIT}=0;
}

  if ($self->{INTERVALS} > 0)  {
     ($self->{TIME_INTERVALS}, $self->{INTERVAL_TIME_TARIF}, $self->{INTERVAL_TRAF_TARIF}) = $Billing->time_intervals($self->{TP_ID});
     ($remaining_time, $ATTR) = $Billing->remaining_time($self->{DEPOSIT}, {
    	    TIME_INTERVALS      => $self->{TIME_INTERVALS},
          INTERVAL_TIME_TARIF => $self->{INTERVAL_TIME_TARIF},
          INTERVAL_TRAF_TARIF => $self->{INTERVAL_TRAF_TARIF},
          SESSION_START       => $self->{SESSION_START},
          DAY_BEGIN           => $self->{DAY_BEGIN},
          DAY_OF_WEEK         => $self->{DAY_OF_WEEK},
          DAY_OF_YEAR         => $self->{DAY_OF_YEAR},
          REDUCTION           => $self->{REDUCTION},
          POSTPAID            => $self->{PAYMENT_TYPE}
         });
     print "RT: $remaining_time" if ($debug == 1);
   }


if (defined($ATTR->{TT})) {
  $self->{TT_INTERVAL} = $ATTR->{TT};
}
else {
  $self->{TT_INTERVAL} = 0;
}

#check allow period and time out
 if ($remaining_time == -1) {
 	  $RAD_PAIRS->{'Reply-Message'}="Not Allow day";
    return 1, $RAD_PAIRS;
  }
 elsif ($remaining_time == -2) {
    $RAD_PAIRS->{'Reply-Message'}="Not Allow time";
    $RAD_PAIRS->{'Reply-Message'} .= " Interval: $ATTR->{TT}" if ($ATTR->{TT});
    return 1, $RAD_PAIRS;
  }
 elsif($remaining_time > 0) {
    push (@time_limits, $remaining_time);
  }



#Periods Time and traf limits
# 0 - Total limit
# 1 - Day limit
# 2 - Week limit
# 3 - Month limit
#my @traf_limits = ();
my $time_limit  = $self->{TIME_LIMIT}; 
my $traf_limit  = $MAX_SESSION_TRAFFIC;

push @time_limits, $self->{MAX_SESSION_DURATION} if ($self->{MAX_SESSION_DURATION} > 0);

my @periods = ('DAY', 'WEEK', 'MONTH');
my %SQL_params = (
                  DAY   => "DATE_FORMAT(start, '%Y-%m-%d')=curdate()",
                  WEEK  => "(YEAR(curdate())=YEAR(start)) and (WEEK(curdate()) = WEEK(start))",
                  MONTH => "date_format(start, '%Y-%m')=date_format(curdate(), '%Y-%m')" 
                  );

foreach my $line (@periods) {
     if (($self->{$line . '_TIME_LIMIT'} > 0) || ($self->{$line . '_TRAF_LIMIT'} > 0)) {
        my $session_time_limit=$traf_limit;
        my $session_traf_limit=$traf_limit;
        $self->query($db, "SELECT if(". $self->{$line . '_TIME_LIMIT'} ." > 0, ". $self->{$line . '_TIME_LIMIT'} ." - sum(duration), 0),
                                  if(". $self->{$line . '_TRAF_LIMIT'} ." > 0, ". $self->{$line . '_TRAF_LIMIT'} ." - sum(sent + recv) / $CONF->{KBYTE_SIZE} / $CONF->{KBYTE_SIZE}, 0) 
            FROM dv_log
            WHERE uid='$self->{UID}' and $SQL_params{$line}
            GROUP BY uid;");

        if ($self->{TOTAL} == 0) {
          push (@time_limits, $self->{$line . '_TIME_LIMIT'}) if ($self->{$line . '_TIME_LIMIT'} > 0);
          $session_traf_limit = $self->{$line . '_TRAF_LIMIT'} if ($self->{$line . '_TRAF_LIMIT'} > 0);
         } 
        else {
          ($session_time_limit, $session_traf_limit) = @{ $self->{list}->[0] };
          push (@time_limits, $session_time_limit) if ($self->{$line . '_TIME_LIMIT'} > 0);
         }

        #print "$line / $traf_limit / $session_traf_limit". "------\n";
        if ($traf_limit > $session_traf_limit && $self->{$line . '_TRAF_LIMIT'} > 0) {
      	  $traf_limit = $session_traf_limit;
         }
        
        if($traf_limit <= 0) {
          $RAD_PAIRS->{'Reply-Message'}="Rejected! $line Traffic limit utilized '$traf_limit Mb'";
          return 1, $RAD_PAIRS;
         }

      }
}



#set time limit
 for(my $i=0; $i<=$#time_limits; $i++) {
   if ($time_limit > $time_limits[$i]) {
     $time_limit = $time_limits[$i];
    }
  }

 if ($time_limit > 0) {
   $RAD_PAIRS->{'Session-Timeout'} = "$time_limit";
  }
 elsif($time_limit < 0) {
   $RAD_PAIRS->{'Reply-Message'}="Rejected! Time limit utilized '$time_limit'";
   return 1, $RAD_PAIRS;
  }

# Return radius attr
 if ($self->{IP} ne '0') {
   $RAD_PAIRS->{'Framed-IP-Address'} = "$self->{IP}";
  }
 else {
   my $ip = $self->get_ip($NAS->{NAS_ID}, "$RAD->{NAS_IP_ADDRESS}");
   if ($ip eq '-1') {
     $RAD_PAIRS->{'Reply-Message'}="Rejected! There is no free IPs in address pools (USED: $self->{USED_IPS})";
     return 1, $RAD_PAIRS;
    }
   elsif($ip eq '0') {
     #$RAD_PAIRS->{'Reply-Message'}="$self->{errstr} ($NAS->{NAS_ID})";
     #return 1, $RAD_PAIRS;
    }
   else {
     $RAD_PAIRS->{'Framed-IP-Address'} = "$ip";
    }
  }

  $RAD_PAIRS->{'Framed-IP-Netmask'}="$self->{NETMASK}" if (defined( $RAD_PAIRS->{'Framed-IP-Address'} ));
  $RAD_PAIRS->{'Filter-Id'} = "$self->{FILTER}" if (length( $self->{FILTER} ) > 0); 



####################################################################
# Vendor specific return

# ExPPP
if ($NAS->{NAS_TYPE} eq 'exppp') {
  #$traf_tarif 
  my $EX_PARAMS = $self->ex_traffic_params({ 
  	                                        traf_limit => $traf_limit, 
                                            deposit    => $self->{DEPOSIT},
                                            MAX_SESSION_TRAFFIC => $MAX_SESSION_TRAFFIC });

  #global Traffic
  if ($EX_PARAMS->{traf_limit} > 0) {
    $RAD_PAIRS->{'Exppp-Traffic-Limit'} = int($EX_PARAMS->{traf_limit} * $CONF->{KBYTE_SIZE} * $CONF->{KBYTE_SIZE});
   }

  #Local traffic
  if ($EX_PARAMS->{traf_limit_lo} > 0) {
    $RAD_PAIRS->{'Exppp-LocalTraffic-Limit'} = int($EX_PARAMS->{traf_limit_lo} * $CONF->{KBYTE_SIZE} * $CONF->{KBYTE_SIZE});
   }
       
  #Local ip tables
  if (defined($EX_PARAMS->{nets})) {
    my $DV_EXPPP_NETFILES = (defined($CONF->{DV_EXPPP_NETFILES})) ? $CONF->{DV_EXPPP_NETFILES} : '';
    $RAD_PAIRS->{'Exppp-Local-IP-Table'} = "\"$DV_EXPPP_NETFILES$self->{TT_INTERVAL}.nets\"";
   }

#Radius Shaper for exppp
#  if ($self->{USER_SPEED} > 0) {
#    $RAD_PAIRS->{'Exppp-Traffic-Shape'} = int($self->{USER_SPEED});
#   }
#  else {
#    if ($EX_PARAMS->{speed}  > 0) {
#      $RAD_PAIRS->{'Exppp-Traffic-Shape'} = $EX_PARAMS->{speed};
#     }
#   }

=comments
        print "Exppp-Traffic-In-Limit = $trafic_inlimit,";
        print "Exppp-Traffic-Out-Limit = $trafic_outlimit,";
        print "Exppp-LocalTraffic-In-Limit = $trafic_lo_inlimit,";
        print "Exppp-LocalTraffic-Out-Limit = $trafic_lo_outlimit,";
=cut
 }
# Mikrotik (http://www.mikrotik.com)
elsif ($NAS->{NAS_TYPE} eq 'mikrotik') {
  #$traf_tarif 
  my $EX_PARAMS = $self->ex_traffic_params( { 
  	                                        traf_limit => $traf_limit, 
                                            deposit    => $self->{DEPOSIT},
                                            MAX_SESSION_TRAFFIC => $MAX_SESSION_TRAFFIC });

  #global Traffic
  if ($EX_PARAMS->{traf_limit} > 0) {
    $RAD_PAIRS->{'Mikrotik-Recv-Limit'} = int($EX_PARAMS->{traf_limit} * $CONF->{KBYTE_SIZE} * $CONF->{KBYTE_SIZE} / 2);
    $RAD_PAIRS->{'Mikrotik-Xmit-Limit'} = int($EX_PARAMS->{traf_limit} * $CONF->{KBYTE_SIZE} * $CONF->{KBYTE_SIZE} / 2);
    # $RAD_PAIRS->{'Mikrotik-Recv-Limit-Gigawords'}
    # $RAD_PAIRS->{'Mikrotik-Xmit-Limit-Gigawords'}
   }

#Shaper
  if ($self->{USER_SPEED} > 0) {
    $RAD_PAIRS->{'Mikrotik-Rate-Limit'} = "$self->{USER_SPEED}k";
   }
  elsif (defined($EX_PARAMS->{speed}->{0})) {
    $RAD_PAIRS->{'Ascend-Xmit-Rate'} = int($EX_PARAMS->{speed}->{0}->{IN}) * $CONF->{KBYTE_SIZE};
    $RAD_PAIRS->{'Ascend-Data-Rate'} = int($EX_PARAMS->{speed}->{0}->{OUT})* $CONF->{KBYTE_SIZE};
   }
 }
# Cisco Shaper
#
# lcp:interface-config#1=rate-limit input 256000 7500 7500 
#  conform-action continue 
#   exceed-action drop

######################
# MPD
elsif ($NAS->{NAS_TYPE} eq 'mpd4' && $RAD_PAIRS->{'Session-Timeout'} > 604800) {
	$RAD_PAIRS->{'Session-Timeout'}=604800;
 }
elsif ($NAS->{NAS_TYPE} eq 'mpd') {
  my $EX_PARAMS = $self->ex_traffic_params({ 
  	                                        traf_limit => $traf_limit, 
                                            deposit => $self->{DEPOSIT},
                                            MAX_SESSION_TRAFFIC => $MAX_SESSION_TRAFFIC });

  #global Traffic
  if ($EX_PARAMS->{traf_limit} > 0) {
    $RAD_PAIRS->{'Exppp-Traffic-Limit'} = $EX_PARAMS->{traf_limit} * $CONF->{KBYTE_SIZE} * $CONF->{KBYTE_SIZE};
   }
  # MPD have some problem with long time out value max timeout set to 7 days
  if ($RAD_PAIRS->{'Session-Timeout'} > 604800)    {
  	 $RAD_PAIRS->{'Session-Timeout'}=604800;
   }
#MPD standart radius based Shaper
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
 }
###########################################################
# pppd + RADIUS plugin (Linux) http://samba.org/ppp/
# lepppd - PPPD IPv4 zone counters 
elsif ($NAS->{NAS_TYPE} eq 'pppd' or ($NAS->{NAS_TYPE} eq 'lepppd')) {
  my $EX_PARAMS = $self->ex_traffic_params({ 
  	                                         traf_limit => $traf_limit, 
                                             deposit    => $self->{DEPOSIT},
                                             MAX_SESSION_TRAFFIC => $MAX_SESSION_TRAFFIC 
                                           });

  #global Traffic
  if ($EX_PARAMS->{traf_limit} > 0) {
    $RAD_PAIRS->{'Session-Octets-Limit'} = $EX_PARAMS->{traf_limit} * $CONF->{KBYTE_SIZE} * $CONF->{KBYTE_SIZE};
    $RAD_PAIRS->{'Octets-Direction'} = $self->{OCTETS_DIRECTION};
   }

  #Speed limit attributes 
  if ($self->{USER_SPEED} > 0) { 
    $RAD_PAIRS->{'PPPD-Upstream-Speed-Limit'} = int($self->{USER_SPEED}); 
    $RAD_PAIRS->{'PPPD-Downstream-Speed-Limit'} = int($self->{USER_SPEED}); 
   } 
  elsif (defined($EX_PARAMS->{speed}->{0})) { 
    $RAD_PAIRS->{'PPPD-Downstream-Speed-Limit'} = int($EX_PARAMS->{speed}->{0}->{OUT}); 
    $RAD_PAIRS->{'PPPD-Upstream-Speed-Limit'} = int($EX_PARAMS->{speed}->{0}->{IN}); 
   }
 }
#Chillispot www.chillispot.org
elsif ($NAS->{NAS_TYPE} eq 'chillispot') {
	
	my $EX_PARAMS = $self->ex_traffic_params({ traf_limit          => $traf_limit, 
                                             deposit             => $self->{DEPOSIT}, 
                                             MAX_SESSION_TRAFFIC => $MAX_SESSION_TRAFFIC }); 
  #global Traffic 
  if ($EX_PARAMS->{traf_limit} > 0) { 
    $RAD_PAIRS->{'ChilliSpot-Max-Total-Octets'} = int($EX_PARAMS->{traf_limit} * $CONF->{KBYTE_SIZE} * $CONF->{KBYTE_SIZE}); 
   } 
  #Shaper for chillispot 
  if ($self->{USER_SPEED} > 0) { 
     $RAD_PAIRS->{'WISPr-Bandwidth-Max-Down'} = int($self->{USER_SPEED}) * $CONF->{KBYTE_SIZE}; 
     $RAD_PAIRS->{'WISPr-Bandwidth-Max-Up'} = int($self->{USER_SPEED}) * $CONF->{KBYTE_SIZE}; 
   } 
  elsif (defined($EX_PARAMS->{speed}->{0})) { 
     $RAD_PAIRS->{'WISPr-Bandwidth-Max-Down'} = int($EX_PARAMS->{speed}->{0}->{IN}) * $CONF->{KBYTE_SIZE}; 
     $RAD_PAIRS->{'WISPr-Bandwidth-Max-Up'} = int($EX_PARAMS->{speed}->{0}->{OUT}) * $CONF->{KBYTE_SIZE}; 
   } 
	
}

#Auto assing MAC in first connect
if( defined($CONF->{MAC_AUTO_ASSIGN}) && 
       $CONF->{MAC_AUTO_ASSIGN}==1 && 
       $self->{CID} eq '' && 
       (defined($RAD->{CALLING_STATION_ID}) && $RAD->{CALLING_STATION_ID} =~ /:/ && $RAD->{CALLING_STATION_ID} !~ /\// )
      ) {
#  print "ADD MAC___\n";
  $self->query($db, "UPDATE dv_main SET cid='$RAD->{CALLING_STATION_ID}'
     WHERE uid='$self->{UID}';", 'do');
 }

# SET ACCOUNT expire date
if( $self->{ACCOUNT_AGE} > 0 && $self->{ACCOUNT_ACTIVATE} eq '0000-00-00') {
  $self->query($db, "UPDATE users SET  activate=curdate(), expire=curdate() + INTERVAL $self->{ACCOUNT_AGE} day 
     WHERE uid='$self->{UID}';", 'do');
 }


  if ($self->{TP_RAD_PAIRS}) {
    my @p = split(/,/, $self->{TP_RAD_PAIRS});
    foreach my $line (@p) {
     if ($line =~ /\+\=/ ) {
       my($left, $right)=split(/\+\=/, $line, 2);
       $right =~ s/\"//g;

       if (defined($RAD_PAIRS->{"$left"})) {
   	     $RAD_PAIRS->{"$left"} =~ s/\"//g;
   	     $RAD_PAIRS->{"$left"}="\"". $RAD_PAIRS->{"$left"} .",$right\"";
        }
       else {
     	   $RAD_PAIRS->{"$left"}="\"$right\"";
        }
       }
      else {
         my($left, $right)=split(/=/, $line, 2);
         if ($left =~ s/^!//) {
           delete $RAD_PAIRS->{"$left"};
   	      }
   	     else {  
   	       $RAD_PAIRS->{"$left"}="$right";
   	      }
       }
     }
   }
#OK
  return 0, $RAD_PAIRS, '';
}
	


#*********************************************************
# Auth_mac
# Mac auth function
#*********************************************************
sub Auth_CID {
  my $self = shift;
  my ($RAD, $attr) = @_;
  
  my $RAD_PAIRS;
  
  my @MAC_DIGITS_GET = ();
  if (! defined($RAD->{CALLING_STATION_ID})) {
     $RAD_PAIRS->{'Reply-Message'}="Wrong CID ''";
     return 1, $RAD_PAIRS, "Wrong CID ''";
   }


   if (($self->{CID} =~ /:/ || $self->{CID} =~ /-/)
       && $self->{CID} !~ /\./) {
      #@MAC_DIGITS_GET=split(/:/, $self->{CID}) if($self->{CID} =~ /:/);
      @MAC_DIGITS_GET=split(/:|-/, $self->{CID});
      
      

      #NAS MPD 3.18 with patch
      if ($RAD->{CALLING_STATION_ID} =~ /\//) {
         $RAD->{CALLING_STATION_ID} =~ s/ //g;
         my ($cid_ip, $trash);
         ($cid_ip, $RAD->{CALLING_STATION_ID}, $trash) = split(/\//, $RAD->{CALLING_STATION_ID}, 3);
       }

      my @MAC_DIGITS_NEED = split(/:|\.|-/, $RAD->{CALLING_STATION_ID});

      for(my $i=0; $i<=5; $i++) {
        if(hex($MAC_DIGITS_NEED[$i]) != hex($MAC_DIGITS_GET[$i])) {
          $RAD_PAIRS->{'Reply-Message'}="Wrong MAC '$RAD->{CALLING_STATION_ID}'";
          return 1, $RAD_PAIRS, "Wrong MAC '$RAD->{CALLING_STATION_ID}'";
         }
       }
    }
   # If like MPD CID
   # 192.168.101.2 / 00:0e:0c:4a:63:56 
   elsif($self->{CID} =~ /\//) {
     $RAD->{CALLING_STATION_ID} =~ s/ //g;
     my ($cid_ip, $cid_mac, $trash) = split(/\//, $RAD->{CALLING_STATION_ID}, 3);
     if ("$cid_ip/$cid_mac" ne $self->{CID}) {
       $RAD_PAIRS->{'Reply-Message'}="Wrong CID '$cid_ip/$cid_mac'";
       return 1, $RAD_PAIRS;
      }
    }
   elsif($self->{CID} ne $RAD->{CALLING_STATION_ID}) {
     $RAD_PAIRS->{'Reply-Message'}="Wrong CID '$RAD->{CALLING_STATION_ID}'";
     return 1, $RAD_PAIRS;
    }

}

#**********************************************************
# User authentication
# authentication($RAD_HASH_REF, $NAS_HASH_REF, $attr)
#
# return ($r, $RAD_PAIRS_REF);
#**********************************************************
sub authentication {
  my $self = shift;
  my ($RAD, $NAS, $attr) = @_;
  
 
  my $SECRETKEY = (defined($CONF->{secretkey})) ? $CONF->{secretkey} : '';
  my %RAD_PAIRS = ();
  
  #Get callback number
  if ($RAD->{USER_NAME} =~ /(\d+):(\S+)/) {
    my $number = $1;
    my $login =  $2;

    if ($CONF->{DV_CALLBACK_DENYNUMS} && $number=~/$CONF->{DV_CALLBACK_DENYNUMS}/) {
 	    $RAD_PAIRS{'Reply-Message'}="Forbidden Number '$number'";
      return 1, \%RAD_PAIRS;
     }

    if ($CONF->{DV_CALLBACK_PREFIX}) {
    	$number = $CONF->{DV_CALLBACK_PREFIX}.$number;
     }
    if ($NAS->{NAS_TYPE} eq 'lucent_max') {
    #	$RAD_PAIRS{'Ascend-Callback'}='Callback-Yes';
    	$RAD_PAIRS{'Ascend-Dial-Number'}=$number;
    	
    	
    	
    	$RAD_PAIRS{'Ascend-Data-Svc'}='Switched-modem';
      $RAD_PAIRS{'Ascend-Send-Auth'}='Send-Auth-None';
      $RAD_PAIRS{'Ascend-CBCP-Enable'}='CBCP-Enabled';
      $RAD_PAIRS{'Ascend-CBCP-Mode'}='CBCP-Profile-Callback';
      $RAD_PAIRS{'Ascend-CBCP-Trunk-Group'}=5;
      $RAD_PAIRS{'Ascend-Callback-Delay'}=30;
    	
    	#$RAD_PAIRS{'Ascend-Send-Secret'}='';
     }
    else {
      $RAD_PAIRS{'Callback-Number'}=$number;
     }

    $RAD->{USER_NAME}=$login;
   }

  $self->query($db, "select
  u.uid,
  DECODE(password, '$SECRETKEY'),
  UNIX_TIMESTAMP(),
  UNIX_TIMESTAMP(DATE_FORMAT(FROM_UNIXTIME(UNIX_TIMESTAMP()), '%Y-%m-%d')),
  DAYOFWEEK(FROM_UNIXTIME(UNIX_TIMESTAMP())),
  DAYOFYEAR(FROM_UNIXTIME(UNIX_TIMESTAMP())),
  u.company_id,
  u.disable,
  u.bill_id,
  u.credit,
  u.activate,
  u.reduction
     FROM users u
     WHERE 
        u.id='$RAD->{USER_NAME}'
        AND (u.expire='0000-00-00' or u.expire > CURDATE())
        AND (u.activate='0000-00-00' or u.activate <= CURDATE())
       GROUP BY u.id;");


  if($self->{errno}) {
  	$RAD_PAIRS{'Reply-Message'}='SQL error';
  	return 1, \%RAD_PAIRS;
   }
  elsif ($self->{TOTAL} < 1) {
    $RAD_PAIRS{'Reply-Message'}="Login Not Exist or Expire";
    return 1, \%RAD_PAIRS;
   }

  ($self->{UID}, 
     $self->{PASSWD}, 
     $self->{SESSION_START}, 
     $self->{DAY_BEGIN}, 
     $self->{DAY_OF_WEEK}, 
     $self->{DAY_OF_YEAR},
     $self->{COMPANY_ID},
     $self->{DISABLE},
     $self->{BILL_ID},
     $self->{CREDIT},
     $self->{ACCOUNT_ACTIVATE},
     $self->{REDUCTION}
    ) = @{ $self->{list}->[0] };


#Auth chap
if($RAD->{'HINT'} && $RAD->{'HINT'} eq 'NOPASS') {

 } 
elsif (defined($RAD->{CHAP_PASSWORD}) && defined($RAD->{CHAP_CHALLENGE})) {
  if (check_chap("$RAD->{CHAP_PASSWORD}", "$self->{PASSWD}", "$RAD->{CHAP_CHALLENGE}", 0) == 0) {
    $RAD_PAIRS{'Reply-Message'}="Wrong CHAP password";
    return 1, \%RAD_PAIRS;
   }      	 	
 }
#Auth MS-CHAP v1,v2
elsif(defined($RAD->{MS_CHAP_CHALLENGE})) {
  # Its an MS-CHAP V2 request
  # See draft-ietf-radius-ms-vsa-01.txt,
  # draft-ietf-pppext-mschap-v2-00.txt, RFC 2548, RFC3079
  $RAD->{MS_CHAP_CHALLENGE} =~ s/^0x//;
  my $challenge = pack("H*", $RAD->{MS_CHAP_CHALLENGE});
  my ($usersessionkey, $lanmansessionkey, $ms_chap2_success);

  if (defined($RAD->{MS_CHAP2_RESPONSE})) {
     $RAD->{MS_CHAP2_RESPONSE} =~ s/^0x//; 
     my $rad_response = pack("H*", $RAD->{MS_CHAP2_RESPONSE});
     my ($ident, $flags, $peerchallenge, $reserved, $response) = unpack('C C a16 a8 a24', $rad_response);

      

     
     if (check_mschapv2(($RAD_PAIRS{'Callback-Number'}) ? "$RAD_PAIRS{'Callback-Number'}:$RAD->{USER_NAME}" : $RAD->{USER_NAME},
       $self->{PASSWD}, $challenge, $peerchallenge, $response, $ident,
 	     \$usersessionkey, \$lanmansessionkey, \$ms_chap2_success) == 1) {
         $RAD_PAIRS{'MS-CHAP-Error'}="\"Wrong MS-CHAP2 password\"";
         $RAD_PAIRS{'Reply-Message'}=$RAD_PAIRS{'MS-CHAP-Error'};
         return 1, \%RAD_PAIRS;
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
         my $message;
  
         if (check_mschap("$self->{PASSWD}", "$RAD->{MS_CHAP_CHALLENGE}", "$RAD->{MS_CHAP_RESPONSE}", 
	           \$usersessionkey, \$lanmansessionkey, \$message) == 0) {
           $message = "Wrong MS-CHAP password";
           $RAD_PAIRS{'MS-CHAP-Error'}="\"$message\"";
           $RAD_PAIRS{'Reply-Message'}=$message;
           return 1, \%RAD_PAIRS;
          }
        }

#       $RAD_PAIRS{'MS-CHAP-MPPE-Keys'} = '0x' . unpack("H*", (pack('a8 a16', $lanmansessionkey, 
#														$usersessionkey))) . "0000000000000000";

       # 1      Encryption-Allowed 
       # 2      Encryption-Required 
       $RAD_PAIRS{'MS-MPPE-Encryption-Policy'} = '0x00000001';
       $RAD_PAIRS{'MS-MPPE-Encryption-Types'} = '0x00000006';      
    


 }
#End MSchap auth
elsif($NAS->{NAS_AUTH_TYPE} == 1) {
  if (check_systemauth("$RAD->{USER_NAME}", "$RAD->{USER_PASSWORD}") == 0) { 
    $RAD_PAIRS{'Reply-Message'}="Wrong password '$RAD->{USER_PASSWORD}' $NAS->{NAS_AUTH_TYPE}";
    $RAD_PAIRS{'Reply-Message'} .=  " CID: ". $RAD->{'CALLING_STATION_ID'} if ( $RAD->{'CALLING_STATION_ID'} );
    return 1, \%RAD_PAIRS;
   }
 } 
#If don't athorize any above methods auth PAP password
else {
  if(defined($RAD->{USER_PASSWORD}) && $self->{PASSWD} ne $RAD->{USER_PASSWORD}) {
    $RAD_PAIRS{'Reply-Message'}="Wrong password '$RAD->{USER_PASSWORD}'";
    return 1, \%RAD_PAIRS;
   }
}



if ($RAD->{CISCO_AVPAIR}) {
  if ($RAD->{CISCO_AVPAIR} =~ /client-mac-address=(\S+)/) {
    $RAD->{CALLING_STATION_ID}=$1;
  }
}



#DIsable
if ($self->{DISABLE}) {
  $RAD_PAIRS{'Reply-Message'}="Account Disable";
  return 1, \%RAD_PAIRS;
}

#Chack Company account if ACCOUNT_ID > 0
$self->check_company_account() if ($self->{COMPANY_ID} > 0);
if($self->{errno}) {
  $RAD_PAIRS{'Reply-Message'}=$self->{errstr};
  return 1, \%RAD_PAIRS;
 }



$self->check_bill_account();
if($self->{errno}) {
  $RAD_PAIRS{'Reply-Message'}=$self->{errstr};
  return 1, \%RAD_PAIRS;
 }

  return 0, \%RAD_PAIRS, '';
}


#*******************************************************************
#Chack Company account if ACCOUNT_ID > 0
# check_company_account()
#*******************************************************************
sub check_bill_account() {
  my $self = shift;

#get sum from bill account
   $self->query($db, "SELECT ROUND(deposit, 2) FROM bills WHERE id='$self->{BILL_ID}';");
   if($self->{errno}) {
  	  return $self;
     }
    elsif ($self->{TOTAL} < 1) {
      $self->{errno}=2;
      $self->{errstr}="Bill account Not Exist";
      return $self;
     }

   ($self->{DEPOSIT}) = $self->{list}->[0]->[0];

  return $self;
}

#*******************************************************************
#Chack Company account if ACCOUNT_ID > 0
# check_company_account()
#*******************************************************************
sub check_company_account () {
	my $self = shift;

  $self->query($db, "SELECT bill_id, 
                            disable,
                            credit FROM companies WHERE id='$self->{COMPANY_ID}';");

 
  if($self->{errno}) {
 	  return $self;
   }
  elsif ($self->{TOTAL} < 1) {
    $self->{errstr}="Company ID '$self->{COMPANY_ID}' Not Exist";

    $self->{errno}=1;
    return $self;
   }

  my $a_ref = $self->{list}->[0];

  ($self->{BILL_ID},
   $self->{DISABLE},
   $self->{COMPANY_CREDIT}
    ) = @$a_ref;

  
  $self->{CREDIT}+=$self->{COMPANY_CREDIT};


  return $self;
}


#*******************************************************************
# Extended traffic parameters
# ex_params($tp_id)
#*******************************************************************
sub ex_traffic_params {
 my ($self, $attr) = @_;	

 my $deposit = (defined($attr->{deposit})) ? $attr->{deposit} : 0;

 my %EX_PARAMS = ();
 $EX_PARAMS{traf_limit}=(defined($attr->{traf_limit})) ? $attr->{traf_limit} : 0;
 $EX_PARAMS{traf_limit_lo}=4090;

 my %prepaids      = ();
 my %speeds        = ();
 my %in_prices     = ();
 my %out_prices    = ();
 my %trafic_limits = ();
 my %expr          = ();
 
   my $nets = 0;

   $self->query($db, "SELECT id, in_price, out_price, prepaid, in_speed, out_speed, LENGTH(nets), expression
             FROM trafic_tarifs
             WHERE interval_id='$self->{TT_INTERVAL}';");

   if ($self->{TOTAL} < 1) {
     return \%EX_PARAMS;	
    }
   elsif($self->{errno}) {
   	 return \%EX_PARAMS;
    }

   my $list = $self->{list};
   foreach my $line (@$list) {
     $prepaids{$line->[0]}=$line->[3];
     $in_prices{$line->[0]}=$line->[1];
     $out_prices{$line->[0]}=$line->[2];
     $EX_PARAMS{speed}{$line->[0]}{IN}=$line->[4];
     $EX_PARAMS{speed}{$line->[0]}{OUT}=$line->[5];
     $expr{$line->[0]}=$line->[7] if (length($line->[7]) > 5);
     $nets+=$line->[6];
    }

   $EX_PARAMS{nets}=$nets if ($nets > 20);
   #$EX_PARAMS{speed}=int($speeds{0}) if (defined($speeds{0}));

#Get tarfic limit if prepaid > 0 or
# expresion exist
if ((defined($prepaids{0}) && $prepaids{0} > 0 ) || (defined($prepaids{1}) && $prepaids{1}>0 ) || $expr{0} || $expr{1}) {

  my $start_period = ($self->{ACCOUNT_ACTIVATE} ne '0000-00-00') ? "DATE_FORMAT(start, '%Y-%m-%d')>='$self->{ACCOUNT_ACTIVATE}'" : undef;
  my $used_traffic=$Billing->get_traffic({ UID    => $self->{UID},
                                           PERIOD => $start_period });

  #Make trafiic sum only for diration
  #Recv / IN
  if($self->{OCTETS_DIRECTION} == 1) {
 	  $used_traffic->{TRAFFIC_COUNTER}   = $used_traffic->{TRAFFIC_IN};
    $used_traffic->{TRAFFIC_COUNTER_2} = $used_traffic->{TRAFFIC_IN_2};
   }
  #Sent / OUT
  elsif ($self->{OCTETS_DIRECTION} == 2 ) {
 	  $used_traffic->{TRAFFIC_COUNTER}   = $used_traffic->{TRAFFIC_OUT};
    $used_traffic->{TRAFFIC_COUNTER_2} = $used_traffic->{TRAFFIC_OUT_2};
   }
  else {
 	  $used_traffic->{TRAFFIC_COUNTER}   = $used_traffic->{TRAFFIC_IN}+$used_traffic->{TRAFFIC_OUT};
    $used_traffic->{TRAFFIC_COUNTER_2} = $used_traffic->{TRAFFIC_IN_2}+$used_traffic->{TRAFFIC_OUT_2};
   }   

  if ($self->{TRAFFIC_TRANSFER_PERIOD}) {
    my $tp = $self->{TP_ID};
    
    #$prepaids{0} = $prepaids{0} * $self->{TRAFFIC_TRANSFER_PERIOD} ;
    #$prepaids{1} = $prepaids{1} * $self->{TRAFFIC_TRANSFER_PERIOD} ;
    my $interval = undef;
  	if ($self->{ACCOUNT_ACTIVATE} ne '0000-00-00') {
      $interval = "(DATE_FORMAT(start, '%Y-%m-%d')>='$self->{ACCOUNT_ACTIVATE}' - INTERVAL $self->{TRAFFIC_TRANSFER_PERIOD} * 30 DAY && 
       DATE_FORMAT(start, '%Y-%m-%d')<='$self->{ACCOUNT_ACTIVATE}')";

  	 }
    else {
    	$interval = "(DATE_FORMAT(start, '%Y-%m')>=DATE_FORMAT(curdate() - INTERVAL $self->{TRAFFIC_TRANSFER_PERIOD} MONTH, '%Y-%m') AND 
    	 DATE_FORMAT(start, '%Y-%m')>=DATE_FORMAT(curdate(), '%Y-%m') ) ";
     }
    
    # Traffic transfer
    my $transfer_traffic=$Billing->get_traffic({ UID      => $self->{UID},
                                                 INTERVAL => $interval,
                                                 TP_ID    => $tp
                                               });
                                           
     
 #     print $prepaids{0}."\n";
    if ($Billing->{TOTAL} > 0) {
      if($self->{OCTETS_DIRECTION} == 1) {
 	      $prepaids{0}   += $prepaids{0} - $transfer_traffic->{TRAFFIC_IN} if ( $prepaids{0} > $transfer_traffic->{TRAFFIC_IN} );
        $prepaids{1} += $prepaids{1} - $transfer_traffic->{TRAFFIC_IN_2} if ( $prepaids{1} > $transfer_traffic->{TRAFFIC_IN_2} );
       }
      #Sent / OUT
      elsif ($self->{OCTETS_DIRECTION} == 2 ) {
 	      $prepaids{0} += $prepaids{0} - $transfer_traffic->{TRAFFIC_OUT} if ( $prepaids{0} > $transfer_traffic->{TRAFFIC_OUT} );
        $prepaids{1} += $prepaids{1} - $transfer_traffic->{TRAFFIC_OUT_2} if ( $prepaids{1} > $transfer_traffic->{TRAFFIC_OUT_2} );
       }
      else {
 	      $prepaids{0} += $prepaids{0} - ($transfer_traffic->{TRAFFIC_IN}+$transfer_traffic->{TRAFFIC_OUT}) if ($prepaids{0} > ($transfer_traffic->{TRAFFIC_IN}+$transfer_traffic->{TRAFFIC_OUT}));
        $prepaids{1} += $prepaids{1} - ($transfer_traffic->{TRAFFIC_IN_2}+$transfer_traffic->{TRAFFIC_OUT_2}) if ( $prepaids{1} > ($transfer_traffic->{TRAFFIC_IN_2}+$transfer_traffic->{TRAFFIC_OUT_2}) );
       }   
     }
   }

  #print $prepaids{0}."\n";

  if ($self->{TOTAL} == 0) {
    $trafic_limits{0}=$prepaids{0} || 0;
    $trafic_limits{1}=$prepaids{1} || 0;
   }
  else {
    #my $used = $self->{list}->[0];
    #Check global traffic
   

    if ($used_traffic->{TRAFFIC_COUNTER} < $prepaids{0}) {
      $trafic_limits{0}=$prepaids{0} - $used_traffic->{TRAFFIC_COUNTER};
     }
    elsif($in_prices{0} > 0 && $out_prices{0} > 0) {
      $trafic_limits{0} = ($deposit / (($in_prices{0} + $out_prices{0}) / 2));
     }
    elsif($in_prices{0} > 0 && $out_prices{0} == 0) {
    	$trafic_limits{0} = ($deposit / $in_prices{0});
     }
    elsif($in_prices{0} == 0 && $out_prices{0} > 0) {
      $trafic_limits{0} = ($deposit / $out_prices{0});
     }
    
    # Check extended prepaid traffic
    if ($prepaids{1}) {
      if (($used_traffic->{TRAFFIC_COUNTER_2}  < $prepaids{1})) {
        $trafic_limits{1}=$prepaids{1} - $used_traffic->{TRAFFIC_COUNTER_2};
       }
      elsif($in_prices{1} > 0 && $out_prices{1} > 0) {
        $trafic_limits{1} = ($deposit / (($in_prices{1} + $out_prices{1}) / 2));
       }
      elsif($in_prices{1} > 0 && $out_prices{1} == 0) {
      	$trafic_limits{1} = ($deposit / $in_prices{1});
       }
      elsif($in_prices{1} == 0 && $out_prices{1} > 0) {
        $trafic_limits{1} = ($deposit / $out_prices{1});
       }
     }
   }
  #Use expresion 
  my $RESULT = $Billing->expression($self->{UID}, \%expr, { START_PERIOD => $self->{ACCOUNT_ACTIVATE},
  	                                                        debug        => 0 });
  	                                                        
  if ($RESULT->{TRAFFIC_LIMIT}) {
  	#print "LIMIT: $RESULT->{TRAFFIC_LIMIT} USED: $used_traffic->{TRAFFIC_SUM}";
  	$trafic_limits{0} =  $RESULT->{TRAFFIC_LIMIT} - $used_traffic->{TRAFFIC_COUNTER};
   }
  #End expresion   
 }
else {
  if($in_prices{0} > 0 && $out_prices{0} > 0) {
    $trafic_limits{0} = ($deposit / (($in_prices{0} + $out_prices{0}) / 2));
   }
  elsif($in_prices{0} > 0 && $out_prices{0} == 0) {
   	$trafic_limits{0} = ($deposit / $in_prices{0});
   }
  elsif($in_prices{0} == 0 && $out_prices{0} > 0) {
    $trafic_limits{0} = ($deposit / $out_prices{0});
   }



  if (defined($in_prices{1})) {
    if($in_prices{1} > 0 && $out_prices{1} > 0) {
      $trafic_limits{1} = ($deposit / (($in_prices{1} + $out_prices{1}) / 2));
     }
    elsif($in_prices{1} > 0 && $out_prices{1} == 0) {
    	$trafic_limits{1} = ($deposit / $in_prices{1});
     }
    elsif($in_prices{1} == 0 && $out_prices{1} > 0) {
      $trafic_limits{1} = ($deposit / $out_prices{1});
     }
   }
  else {
    $trafic_limits{1} = 0;
   }
}

#Traffic limit


my $trafic_limit = 0;
#2Gb - (2048 * 1024 * 1024 ) - global traffic session limit
if (defined($trafic_limits{0}) && $trafic_limits{0} > 0  && $trafic_limits{0} < $EX_PARAMS{traf_limit}) {
  if ($CONF->{MAX_SESSION_TRAFFIC}) {
    $trafic_limit = ($trafic_limits{0} > $CONF->{MAX_SESSION_TRAFFIC}) ? $CONF->{MAX_SESSION_TRAFFIC} :  $trafic_limits{0};
   }
  $EX_PARAMS{traf_limit} = ($trafic_limit < 1 && $trafic_limit > 0) ? 1 : int($trafic_limit);
}

#Local Traffic limit
if (defined($trafic_limits{1}) && $trafic_limits{1} > 0) {
  #10Gb - (10240 * 1024 * 1024) - local traffic session limit
  $trafic_limit = ($trafic_limits{1} > 4090) ? 4090 :  $trafic_limits{1};
  $EX_PARAMS{traf_limit_lo} = ($trafic_limit < 1 && $trafic_limit > 0) ? 1 : int($trafic_limit);
 }

 return \%EX_PARAMS;
}



#*******************************************************************
# returns:
#
#   -1 - No free adddress
#    0 - No address pool using nas servers ip address
#   192.168.101.1 - assign ip address
#
# get_ip($self, $nas_num, $nas_ip)
#*******************************************************************
sub get_ip {
 my $self = shift;
 my ($nas_num, $nas_ip) = @_;

#get ip pool
 $self->query($db, "SELECT ippools.ip, ippools.counts 
  FROM ippools
  WHERE ippools.nas='$nas_num';");

 if ($self->{TOTAL} < 1)  {
#     $self->{errno}=1;
#     $self->{errstr}='No ip pools';
     return 0;	
  }

 my %pools = ();
 my $list = $self->{list};
 foreach my $line (@$list) {
    my $sip   = $line->[0]; 
    my $count = $line->[1];

    for(my $i=$sip; $i<=$sip+$count; $i++) {
       $pools{$i}=undef;
     }
   }

#get active address and delete from pool
 $self->query($db, "SELECT framed_ip_address
  FROM dv_calls 
  WHERE nas_ip_address=INET_ATON('$nas_ip') and (status=1 or status>=3);");

 $list = $self->{list};
 $self->{USED_IPS}=0;

 foreach my $ip (@$list) {
   if(exists($pools{$ip->[0]})) {
      delete($pools{$ip->[0]});
      $self->{USED_IPS}++;
     }
   }
 
 my ($assign_ip, undef) = each(%pools);
 if ($assign_ip) {
   $assign_ip = int2ip($assign_ip);
   return $assign_ip; 	
  }
 else { # no addresses available in pools
   return -1;
  }

 return 0;
}



#*******************************************************************
# Convert integer value to ip
# int2ip($i);
#*******************************************************************
sub int2ip {
my $i = shift;
my (@d);

$d[0]=int($i/256/256/256);
$d[1]=int(($i-$d[0]*256*256*256)/256/256);
$d[2]=int(($i-$d[0]*256*256*256-$d[1]*256*256)/256);
$d[3]=int($i-$d[0]*256*256*256-$d[1]*256*256-$d[2]*256);
 return "$d[0].$d[1].$d[2].$d[3]";
}

#********************************************************************
# System auth function
# check_systemauth($user, $password)
#********************************************************************
sub check_systemauth {
 my ($user, $password)= @_;

 if ($< != 0) {
   log_print('LOG_ERR', "For system Authentification you need root privileges");
   return 1;
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



#*******************************************************************
# Authorization module
# pre_auth()
#*******************************************************************
sub pre_auth {
  my ($self, $RAD, $attr)=@_;
  
  
if (defined($RAD->{MS_CHAP_CHALLENGE}) || defined($RAD->{EAP_MESSAGE})) {
  
  my $login = $RAD->{USER_NAME};
  if ($RAD->{USER_NAME} =~ /:(.+)/) {
    $login = $1;	 
  }

  $self->query($db, "SELECT DECODE(password, '$CONF->{secretkey}') FROM users WHERE id='$login';");
  if ($self->{TOTAL} > 0) {
  	my $list = $self->{list}->[0];
    my $password = $list->[0];
    $self->{'RAD_CHECK'}{'User-Password'}="$password";
    print "User-Password == \"$password\"";
    return 0;
   }

  $self->{errno} = 1;
  $self->{errstr} = "USER: '$login' not exist";
  return 1;
 }
  
  $self->{'RAD_CHECK'}{'Auth-Type'}="Accept";
  print "Auth-Type := Accept\n";
  return 0;
}




#####################################################################
# Overrideable function that checks a MSCHAP password response
# $p is the current request
# $username is the users (rewritten) name
# $pw is the ascii plaintext version of the correct password if known
# rfc2548 Microsoft Vendor-specific RADIUS Attributes
sub check_mschap {
  my ($pw, $challenge, $response, $usersessionkeydest, $lanmansessionkeydest, $message) = @_;

  #use lib $Bin;
  use Abills::MSCHAP;

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

#      $RAD_PAIRS{'MS-CHAP-MPPE-Keys'} = '0x' . unpaAIRS{'MS-CHAP-MPPE-Keys'} = '0x' . unpaAIRS{'MS-CHAP-MPPE-Keys'} = '0x' . unpaAIRS{'MS-CHAP-MPPE-Keys'} = '0x' . unpack("H*", (pack('a8 a16', Radius::MSCHAP::LmPasswordHash($pw), 
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
sub check_mschapv2 {
  my ($username, $pw, $challenge, $peerchallenge, $response, $ident,
	$usersessionkeydest, $lanmansessionkeydest,  $ms_chap2_success) = @_;

  use Abills::MSCHAP;

  my $upw = Radius::MSCHAP::ASCIItoUnicode($pw);
  return 1
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


    return 0;
}





1
















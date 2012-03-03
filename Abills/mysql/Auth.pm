package Auth;
# Auth functions

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION
);

use Exporter;
$VERSION = 2.02;
@ISA = ('Exporter');
@EXPORT = qw(
  &check_chap
  &check_company_account
  &check_bill_account
  &get_ip
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
my $RAD_PAIRS;

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
  
  $CONF->{MB_SIZE} = $CONF->{KBYTE_SIZE} * $CONF->{KBYTE_SIZE};
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

  my $MAX_SESSION_TRAFFIC = $CONF->{MAX_SESSION_TRAFFIC} || 0;
  my $DOMAIN_ID = ($NAS->{DOMAIN_ID}) ? "AND tp.domain_id='$NAS->{DOMAIN_ID}'" : "AND tp.domain_id='0'";

  $self->query($db, "select  if (dv.logins=0, if(tp.logins is null, 0, tp.logins), dv.logins) AS logins,
  if(dv.filter_id != '', dv.filter_id, if(tp.filter_id is null, '', tp.filter_id)),
  if(dv.ip>0, INET_NTOA(dv.ip), 0),
  INET_NTOA(dv.netmask),
  dv.tp_id,
  dv.speed,
  dv.cid,
  
  tp.total_time_limit,
  tp.day_time_limit,
  tp.week_time_limit,
  tp.month_time_limit,
  UNIX_TIMESTAMP(DATE_FORMAT(DATE_ADD(curdate(), INTERVAL 1 MONTH), '%Y-%m-01')) - UNIX_TIMESTAMP(),

  tp.total_traf_limit,
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
  tp.neg_deposit_filter_id,
  tp.ext_bill_account,
  tp.credit,
  tp.ippool,
  dv.join_service,
  tp.tp_id,
  tp.active_day_fee,
  tp.neg_deposit_ippool

     FROM (dv_main dv)
     LEFT JOIN tarif_plans tp ON (dv.tp_id=tp.id $DOMAIN_ID)
     LEFT JOIN users_nas un ON (un.uid = dv.uid)
     LEFT JOIN tp_nas ON (tp_nas.tp_id = tp.tp_id)
     LEFT JOIN intervals i ON (tp.tp_id = i.tp_id)
     WHERE dv.uid='$self->{UID}'
     GROUP BY dv.uid;");


  if($self->{errno}) {
  	$RAD_PAIRS->{'Reply-Message'}='SQL error';
  	undef $db;
  	return 1, $RAD_PAIRS;
   }
  elsif ($self->{TOTAL} < 1) {
    $RAD_PAIRS->{'Reply-Message'}="Service not allow";
    return 1, $RAD_PAIRS;
   }
  $self->{USER_NAME}=$RAD->{USER_NAME};
  ($self->{LOGINS}, 
   $self->{FILTER}, 
   $self->{IP}, 
   $self->{NETMASK}, 
   $self->{TP_NUM}, 
   $self->{USER_SPEED}, 
   $self->{CID},
   $self->{TOTAL_TIME_LIMIT}, $self->{DAY_TIME_LIMIT},  $self->{WEEK_TIME_LIMIT},   $self->{MONTH_TIME_LIMIT}, $self->{TIME_LIMIT},
   $self->{TOTAL_TRAF_LIMIT}, $self->{DAY_TRAF_LIMIT},  $self->{WEEK_TRAF_LIMIT},   $self->{MONTH_TRAF_LIMIT}, $self->{OCTETS_DIRECTION},
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
   $self->{NEG_DEPOSIT_FILTER_ID},
   $self->{EXT_BILL_ACCOUNT},
   $self->{TP_CREDIT},
   $self->{TP_IPPOOL},
   $self->{JOIN_SERVICE},
   $self->{TP_ID},
   $self->{ACTIVE_DAY_FEE},
   $self->{NEG_DEPOSIT_IP_POOL},
    ) = @{ $self->{list}->[0] };


#DIsable
if ($self->{DISABLE}) {
	if ($self->{DISABLE} == 2) {
		 $self->query($db, "UPDATE dv_main SET disable=0 WHERE uid='$self->{UID}'", 'do');
	 }
	else {
	  if ($CONF->{DV_STATUS_NEG_DEPOSIT} && $self->{NEG_DEPOSIT_FILTER_ID}) {
      return $self->neg_deposit_filter_former($RAD, $NAS, $self->{NEG_DEPOSIT_FILTER_ID});
	   }
    $RAD_PAIRS->{'Reply-Message'}="Service Disabled $self->{DISABLE}";
    return 1, $RAD_PAIRS;
  }
 }
elsif (! $self->{JOIN_SERVICE} && $self->{TP_NUM} < 1) {
  $RAD_PAIRS->{'Reply-Message'}="No Tarif Selected";
  return 1, $RAD_PAIRS;
 }
elsif (! defined($self->{PAYMENT_TYPE}) && ! $self->{JOIN_SERVICE} ) {
  $RAD_PAIRS->{'Reply-Message'}="Service not allow";
  return 1, $RAD_PAIRS;
 }
elsif (( $RAD_PAIRS->{'Callback-Number'} || $RAD_PAIRS->{'Ascend-Callback'} ) && $self->{CALLBACK} != 1){
  $RAD_PAIRS->{'Reply-Message'}="Callback disabled";
  return 1, $RAD_PAIRS;
}


# Make join service operations
if ($self->{JOIN_SERVICE}) {
 if ($self->{JOIN_SERVICE} > 1) {
  
  $self->query($db, "select  
  if ($self->{LOGINS}>0, $self->{LOGINS}, tp.logins) AS logins,
  if('$self->{FILTER}' != '', '$self->{FILTER}', tp.filter_id),
  dv.tp_id,
  tp.total_time_limit,
  tp.day_time_limit,
  tp.week_time_limit,
  tp.month_time_limit,
  UNIX_TIMESTAMP(DATE_FORMAT(DATE_ADD(curdate(), INTERVAL 1 MONTH), '%Y-%m-01')) - UNIX_TIMESTAMP(),

  tp.total_traf_limit,
  tp.day_traf_limit,
  tp.week_traf_limit,
  tp.month_traf_limit,
  tp.octets_direction,

  if (count(un.uid) + count(tp_nas.tp_id) = 0, 0,
    if (count(un.uid)>0, 1, 2)),
  tp.max_session_duration,
  tp.payment_type,
  tp.credit_tresshold,
  tp.rad_pairs,
  count(i.id),
  tp.age,
  tp.traffic_transfer_period,
  tp.neg_deposit_filter_id,
  tp.ext_bill_account,
  tp.credit,
  tp.ippool,
  tp.tp_id
     FROM (dv_main dv, tarif_plans tp)
     LEFT JOIN users_nas un ON (un.uid = dv.uid)
     LEFT JOIN tp_nas ON (tp_nas.tp_id = tp.tp_id)
     LEFT JOIN intervals i ON (tp.tp_id = i.tp_id)
     WHERE dv.tp_id=tp.id
         AND dv.uid='$self->{JOIN_SERVICE}'
     GROUP BY dv.uid;");
	
	  if($self->{errno}) {
  	$RAD_PAIRS->{'Reply-Message'}='SQL error';
  	undef $db;
  	return 1, $RAD_PAIRS;
   }
  elsif ($self->{TOTAL} < 1) {
    $RAD_PAIRS->{'Reply-Message'}="Service not allow";
    return 1, $RAD_PAIRS;
   }

    (
     $self->{LOGINS}, 
     $self->{FILTER}, 
     $self->{TP_NUM}, 
     $self->{TOTAL_TIME_LIMIT}, $self->{DAY_TIME_LIMIT},  $self->{WEEK_TIME_LIMIT},   $self->{MONTH_TIME_LIMIT}, $self->{TIME_LIMIT},
     $self->{TOTAL_TRAF_LIMIT}, $self->{DAY_TRAF_LIMIT},  $self->{WEEK_TRAF_LIMIT},   $self->{MONTH_TRAF_LIMIT}, $self->{OCTETS_DIRECTION},
     $self->{NAS}, 
     $self->{MAX_SESSION_DURATION},
     $self->{PAYMENT_TYPE},
     $self->{CREDIT_TRESSHOLD},
     $self->{TP_RAD_PAIRS},
     $self->{INTERVALS},
     $self->{ACCOUNT_AGE},
     $self->{TRAFFIC_TRANSFER_PERIOD},
     $self->{NEG_DEPOSIT_FILTER_ID},
     $self->{EXT_BILL_ACCOUNT},
     $self->{TP_CREDIT},
     $self->{TP_IPPOOL},
     $self->{TP_ID},
    ) = @{ $self->{list}->[0] };
    $self->{UIDS} = "$self->{JOIN_SERVICE}";
   }
  else {
    $self->{UIDS} = "$self->{UID}";
   }

  $self->query($db, "SELECT uid FROM dv_main WHERE join_service='$self->{JOIN_SERVICE}';");
  foreach my $line ( @{ $self->{list} }) {
  	$self->{UIDS} .= ", $line->[0]";
   }
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
  
   if ($self->{TOTAL} < 1) {
     $RAD_PAIRS->{'Reply-Message'}="You are not authorized to log in $NAS->{NAS_ID} ($RAD->{NAS_IP_ADDRESS})";
     return 1, $RAD_PAIRS;
    }
  }

#Check CID (MAC) 
if ($self->{CID} ne '' && $self->{CID} !~ /ANY/i) {
	if ($NAS->{NAS_TYPE} eq 'cisco' && ! $RAD->{CALLING_STATION_ID}) {
   } 
  else {  
    my ($ret, $ERR_RAD_PAIRS) = $self->Auth_CID($RAD);
    return $ret, $ERR_RAD_PAIRS if ($ret == 1);
   }
}

#Check port
if ($self->{PORT} > 0 && $self->{PORT} != $RAD->{NAS_PORT}) {
  $RAD_PAIRS->{'Reply-Message'}="Wrong port '$RAD->{NAS_PORT}'";
  return 1, $RAD_PAIRS;
}

#Check  simultaneously logins if needs
if ($self->{LOGINS} > 0) {
  $self->query($db, "SELECT CID, INET_NTOA(framed_ip_address), nas_id FROM dv_calls WHERE user_name='$RAD->{USER_NAME}' and (status <> 2 and status < 11);");
  my($active_logins) = $self->{TOTAL};
  my %active_nas = ();
  foreach my $line (@{ $self->{list} }) {
#  	# Zap session with same CID
  	if ($line->[0] ne '' && $line->[0] eq $RAD->{CALLING_STATION_ID} 
  	   && $NAS->{NAS_TYPE} ne 'ipcad' 
  	   && $active_nas{$line->[2]} && $active_nas{$line->[2]} eq $line->[0]) {
  		$self->query($db, "UPDATE dv_calls SET status=2 WHERE user_name='$RAD->{USER_NAME}' and CID='$RAD->{CALLING_STATION_ID}' and status <> 2;", 'do');
         $self->{IP}=$line->[1];
    	   $active_logins--;
  	 }
    $active_nas{$line->[2]}=$line->[0];
   }

  if ($active_logins >= $self->{LOGINS}) {
    $RAD_PAIRS->{'Reply-Message'}="More then allow login ($self->{LOGINS}/$self->{TOTAL})";
    return 1, $RAD_PAIRS;
   }
}

my @time_limits = ();
my $remaining_time=0;
my $ATTR;

#Chack Company account if ACCOUNT_ID > 0
if ($self->{PAYMENT_TYPE} == 0) {
  #if not defined user credit use TP credit
  $self->{CREDIT} = $self->{TP_CREDIT} if ($self->{CREDIT} == 0 && ! $CONF->{user_credit_change});
  $self->{DEPOSIT}= $self->{DEPOSIT}+$self->{CREDIT}-$self->{CREDIT_TRESSHOLD};
  
  #Check EXT_BILL_ACCOUNT
  if ($self->{EXT_BILL_ACCOUNT} &&  $self->{EXT_BILL_DEPOSIT} < 0 && $self->{DEPOSIT} > 0 ) {
  	$self->{DEPOSIT} = $self->{EXT_BILL_DEPOSIT}+$self->{CREDIT};
   }

  #Check deposit
  if($self->{DEPOSIT} <= 0) {
    $RAD_PAIRS->{'Reply-Message'}="\"Negativ deposit '$self->{DEPOSIT}'. Rejected!\"";
    #Filtering with negative deposit
    if ($self->{NEG_DEPOSIT_FILTER_ID}) {
      return $self->neg_deposit_filter_former($RAD, $NAS, $self->{NEG_DEPOSIT_FILTER_ID});
     }
    else {
    	return 1, $RAD_PAIRS;
     }
   }
 }
else {
  $self->{DEPOSIT}=0;
 }


  if ($self->{INTERVALS} > 0 && ($self->{DEPOSIT} > 0 || $self->{PAYMENT_TYPE} > 0))  {
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
          POSTPAID            => $self->{PAYMENT_TYPE},
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
    if ($self->{NEG_DEPOSIT_FILTER_ID}) {
      return $self->neg_deposit_filter_former($RAD, $NAS, $self->{NEG_DEPOSIT_FILTER_ID});
     }

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
my $traf_limit  = $MAX_SESSION_TRAFFIC || undef;

my @direction_sum = (
  "sum(sent + recv) / $CONF->{MB_SIZE} + sum(acct_output_gigawords) * 4096 + sum(acct_input_gigawords) * 4096",
  "sum(recv) / $CONF->{MB_SIZE} + sum(acct_input_gigawords) * 4096",
  "sum(sent) / $CONF->{MB_SIZE} + sum(acct_output_gigawords) * 4096"
 );

push @time_limits, $self->{MAX_SESSION_DURATION} if ($self->{MAX_SESSION_DURATION} > 0);

my @periods = ('TOTAL', 'DAY', 'WEEK', 'MONTH');
my %SQL_params = (TOTAL => '',
                  DAY   => "and DATE_FORMAT(start, '%Y-%m-%d')=curdate()",
                  WEEK  => "and (YEAR(curdate())=YEAR(start)) and (WEEK(curdate()) = WEEK(start))",
                  MONTH => "and date_format(start, '%Y-%m')=date_format(curdate(), '%Y-%m')" 
                  );

my $WHERE = "uid='$self->{UID}'";
if ($self->{UIDS}) {
  $WHERE = "uid IN ($self->{UIDS})";
 }
elsif($self->{PAYMENT_TYPE} == 2) {
	$WHERE="CID='$RAD->{CALLING_STATION_ID}'";
 }


foreach my $line (@periods) {
     if (($self->{$line . '_TIME_LIMIT'} > 0) || ($self->{$line . '_TRAF_LIMIT'} > 0)) {
        my $session_time_limit=$time_limit;
        my $session_traf_limit=$traf_limit;

        $self->query($db, "SELECT if(". $self->{$line . '_TIME_LIMIT'} ." > 0, ". $self->{$line . '_TIME_LIMIT'} ." - sum(duration), 0),
                                  if(". $self->{$line . '_TRAF_LIMIT'} ." > 0, ". $self->{$line . '_TRAF_LIMIT'} ." - $direction_sum[$self->{OCTETS_DIRECTION}], 0),
                                  1
            FROM dv_log
            WHERE $WHERE $SQL_params{$line}
            GROUP BY 3;");

        if ($self->{TOTAL} == 0) {
          push (@time_limits, $self->{$line . '_TIME_LIMIT'}) if ($self->{$line . '_TIME_LIMIT'} > 0);
          $session_traf_limit = $self->{$line . '_TRAF_LIMIT'} if ($self->{$line . '_TRAF_LIMIT'} > 0);
         } 
        else {
          ($session_time_limit, $session_traf_limit) = @{ $self->{list}->[0] };
          push (@time_limits, $session_time_limit) if ($self->{$line . '_TIME_LIMIT'} > 0);
         }

        if ($self->{$line . '_TRAF_LIMIT'} > 0 && ($traf_limit > $session_traf_limit || ! $traf_limit) ) {
          $traf_limit = $session_traf_limit;
         }
        
        if(defined($traf_limit) && $traf_limit <= 0) {
          $RAD_PAIRS->{'Reply-Message'}="Rejected! $line Traffic limit utilized '$traf_limit Mb'";
          return 1, $RAD_PAIRS;
         }
      }
}

if ($self->{ACTIVE_DAY_FEE}) {
	push @time_limits, 86400 - ($self->{SESSION_START} - $self->{DAY_BEGIN});
}

#set time limit
 for(my $i=0; $i<=$#time_limits; $i++) {
   if ($time_limit > $time_limits[$i]) {
     $time_limit = $time_limits[$i];
    }
  }

 if ($self->{ACC_EXPIRE} != 0) {
   my $to_expire = $self->{ACC_EXPIRE}-$self->{SESSION_START};
   if ($to_expire < $time_limit) {
   	 $time_limit=$to_expire;
    }
  }

 if ($time_limit > 0) {
   $RAD_PAIRS->{'Session-Timeout'} = ($self->{NEG_DEPOSIT_FILTER_ID} && $time_limit < 5) ? int($time_limit+600) : "$time_limit";
  }
 elsif($time_limit < 0) {
   $RAD_PAIRS->{'Reply-Message'}="Rejected! Time limit utilized '$time_limit'";
   return 1, $RAD_PAIRS;
  }

if ($NAS->{NAS_TYPE} && $NAS->{NAS_TYPE} eq 'ipcad') {
	# SET ACCOUNT expire date
  if( $self->{ACCOUNT_AGE} > 0 && $self->{ACCOUNT_ACTIVATE} eq '0000-00-00') {
    $self->query($db, "UPDATE users SET  activate=curdate(), expire=curdate() + INTERVAL $self->{ACCOUNT_AGE} day 
      WHERE uid='$self->{UID}';", 'do');
   }
	return 0, $RAD_PAIRS, '';
 }


# Return radius attr
 if ($self->{IP} ne '0') {
   $RAD_PAIRS->{'Framed-IP-Address'} = "$self->{IP}";
  }
 else {
   my $ip = $self->get_ip($NAS->{NAS_ID}, "$RAD->{NAS_IP_ADDRESS}", { TP_IPPOOL => $self->{TP_IPPOOL} });
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
  if (length( $self->{FILTER} ) > 0) {
    $self->neg_deposit_filter_former($RAD, $NAS, $self->{FILTER}, { USER_FILTER => 1, RAD_PAIRS => $RAD_PAIRS });
   }


####################################################################
# Vendor specific return
#MPD5
if ($NAS->{NAS_TYPE} eq 'mpd5') {

  if (! $CONF->{mpd_filters}) {

   }
  elsif (! $NAS->{NAS_EXT_ACCT}) {
    $self->query($db, "SELECT tt.id, tc.nets, in_speed, out_speed
             FROM trafic_tarifs tt
             LEFT JOIN traffic_classes tc ON (tt.net_id=tc.id)
             WHERE tt.interval_id='$self->{TT_INTERVAL}' ORDER BY 1 DESC;");
 
  foreach my $line ( @{ $self->{list} } ) {
  	my $class_id    = $line->[0];
    my $filter_name = 'flt';

    if ($self->{TOTAL} == 1 || ($class_id == 0 && $line->[1] && $line->[1] =~ /0.0.0.0/)) {
         my $shapper_type = ($line->[2] > 4048) ? 'rate-limit' : 'shape';         
         
         if ( $line->[2] == 0 || $CONF->{ng_car}) {
            push @{$RAD_PAIRS->{'mpd-limit'} }, "out#$self->{TOTAL}#0=all pass";
          } 
         elsif(! $CONF->{ng_car}) {
           my $cir    = $line->[2] * 1024;
           my $nburst = int($cir*1.5/8);
           my $eburst = 2*$nburst;
           push @{$RAD_PAIRS->{'mpd-limit'} }, "out#$self->{TOTAL}#0=all $shapper_type $cir $nburst $eburst";

           #push @{$RAD_PAIRS->{'mpd-limit'} }, "out#$self->{TOTAL}#0=all $shapper_type ". ($line->[2] * 1024)." 4000";
          }

         if ( $line->[3] == 0 || $CONF->{ng_car}) {
           push @{$RAD_PAIRS->{'mpd-limit'} }, "in#$self->{TOTAL}#0=all pass";
          } 
         elsif(! $CONF->{ng_car}) {
           my $cir    = $line->[3] * 1024;
           my $nburst = int($cir*1.5/8);
           my $eburst = 2*$nburst;
           push @{$RAD_PAIRS->{'mpd-limit'} }, "in#$self->{TOTAL}#0=all $shapper_type $cir $nburst $eburst";

           #push @{$RAD_PAIRS->{'mpd-limit'} }, "in#$self->{TOTAL}#0=all $shapper_type ". ($line->[3] * 1024) ." 4000";
          }
   	   next ;
     }
    elsif($line->[1]) {
      $line->[1] =~ s/[\n\r]//g;
      my @net_list = split(/;/, $line->[1]);
  	
  	  my $i=1;
  	  $class_id = $class_id * 2 + 1 - 2 if ($class_id != 0);

        foreach my $net (@net_list) {
          push @{$RAD_PAIRS->{'mpd-filter'} }, ($class_id)."#$i=match dst net $net";
          push @{$RAD_PAIRS->{'mpd-filter'} }, ($class_id+1)."#$i=match src net $net";
  		  $i++;
  	   }
  	  
      push @{$RAD_PAIRS->{'mpd-limit'} }, "in#" . ($self->{TOTAL}-$line->[0]) ."#$line->[0]=flt". ($class_id) ." pass";
      push @{$RAD_PAIRS->{'mpd-limit'} }, "out#". ($self->{TOTAL}-$line->[0]) ."#$line->[0]=flt". ($class_id+1) ." pass";
     }
   }
  }
	#$RAD_PAIRS->{'Session-Timeout'}=604800;
 }
elsif($CONF->{cisco_shaper} && $NAS->{NAS_TYPE} eq 'cisco') {
  #$traf_tarif 
  if ($self->{USER_SPEED} > 0) {
    push @{ $RAD_PAIRS->{'Cisco-AVpair'} }, "lcp:interface-config#1=rate-limit output ". ( $self->{USER_SPEED} * 1024) ." 320000 320000 conform-action transmit exceed-action drop";
	  push @{ $RAD_PAIRS->{'Cisco-AVpair'} }, "lcp:interface-config#1=rate-limit input ". ($self->{USER_SPEED} * 1024) ." 32000 32000 conform-action transmit exceed-action drop";
   }
  else {
    my $EX_PARAMS = $self->ex_traffic_params( { 
  	                                        traf_limit => $traf_limit, 
                                            deposit    => $self->{DEPOSIT},
                                            MAX_SESSION_TRAFFIC => $MAX_SESSION_TRAFFIC });

    if ($EX_PARAMS->{speed}->{1}->{OUT}) {
  	  push @{ $RAD_PAIRS->{'Cisco-AVpair'} }, "lcp:interface-config#1=rate-limit output access-group 101 ". ($EX_PARAMS->{speed}->{1}->{IN} * 1024) ." 1000000  1000000 conform-action transmit exceed-action drop";
      push @{ $RAD_PAIRS->{'Cisco-AVpair'} }, "lcp:interface-config#1=rate-limit input access-group 102 ". ($EX_PARAMS->{speed}->{1}->{OUT} * 1024). " 1000000 1000000 conform-action transmit exceed-action drop";
     }

	  push @{ $RAD_PAIRS->{'Cisco-AVpair'} }, "lcp:interface-config#1=rate-limit output ". ( $EX_PARAMS->{speed}->{0}->{IN} * 1024) ." 320000 320000 conform-action transmit exceed-action drop" if ($EX_PARAMS->{speed}->{0}->{IN} && $EX_PARAMS->{speed}->{0}->{IN} > 0);
	  push @{ $RAD_PAIRS->{'Cisco-AVpair'} }, "lcp:interface-config#1=rate-limit input ". ($EX_PARAMS->{speed}->{0}->{OUT} * 1024) ."  32000 32000 conform-action transmit exceed-action drop" if ($EX_PARAMS->{speed}->{0}->{OUT} && $EX_PARAMS->{speed}->{0}->{OUT} > 0);
   }
 }
# ExPPP
elsif ($NAS->{NAS_TYPE} eq 'exppp') {
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
  if ($EX_PARAMS->{nets}) {
    $RAD_PAIRS->{'Exppp-Local-IP-Table'} = (defined($CONF->{DV_EXPPP_NETFILES})) ? "$CONF->{DV_EXPPP_NETFILES}$self->{TT_INTERVAL}.nets" : "$self->{TT_INTERVAL}.nets";
   }
 }
# Mikrotik
elsif ($NAS->{NAS_TYPE} eq 'mikrotik') {
  #$traf_tarif 
  my $EX_PARAMS = $self->ex_traffic_params( { 
  	                                        traf_limit => $traf_limit, 
                                            deposit    => $self->{DEPOSIT},
                                            MAX_SESSION_TRAFFIC => $MAX_SESSION_TRAFFIC });

  #global Traffic
  if ($EX_PARAMS->{traf_limit} > 0) {
    #Gigaword limit  	
  	if ($EX_PARAMS->{traf_limit} > 4096) {
  		my $giga_limit = $EX_PARAMS->{traf_limit} / 4096;
  		#$RAD_PAIRS->{'Mikrotik-Recv-Limit-Gigawords'}=int($giga_limit);
  		#$RAD_PAIRS->{'Mikrotik-Xmit-Limit-Gigawords'}=int($giga_limit);
      $RAD_PAIRS->{'Mikrotik-Total-Limit-Gigawords'}=int($giga_limit);
  		$EX_PARAMS->{traf_limit} = $EX_PARAMS->{traf_limit} - int($giga_limit) * 4096;
  	 }
  	$RAD_PAIRS->{'Mikrotik-Total-Limit'} = int($EX_PARAMS->{traf_limit} * $CONF->{KBYTE_SIZE} * $CONF->{KBYTE_SIZE});
    #$RAD_PAIRS->{'Mikrotik-Recv-Limit'} = int($EX_PARAMS->{traf_limit} * $CONF->{KBYTE_SIZE} * $CONF->{KBYTE_SIZE} / 2);
    #$RAD_PAIRS->{'Mikrotik-Xmit-Limit'} = int($EX_PARAMS->{traf_limit} * $CONF->{KBYTE_SIZE} * $CONF->{KBYTE_SIZE} / 2);
   }



  #Shaper
  if ($self->{USER_SPEED} > 0) {
    $RAD_PAIRS->{'Mikrotik-Rate-Limit'} = "$self->{USER_SPEED}k";
   }
  elsif (defined($EX_PARAMS->{speed}->{0})) {
    # New way add to address list    
    $RAD_PAIRS->{'Mikrotik-Address-List'} = "CLIENTS_$self->{TP_ID}";    
    # Ald way Make speed
    #$RAD_PAIRS->{'Ascend-Xmit-Rate'} = int($EX_PARAMS->{speed}->{0}->{IN}) * $CONF->{KBYTE_SIZE};
    #$RAD_PAIRS->{'Ascend-Data-Rate'} = int($EX_PARAMS->{speed}->{0}->{OUT})* $CONF->{KBYTE_SIZE};
   }
 }
# MPD4
elsif ($NAS->{NAS_TYPE} eq 'mpd4' && $RAD_PAIRS->{'Session-Timeout'} > 604800) {
	$RAD_PAIRS->{'Session-Timeout'}=604800;
 }
###########################################################
# pppd + RADIUS plugin (Linux) http://samba.org/ppp/
# lepppd - PPPD IPv4 zone counters 
elsif ($NAS->{NAS_TYPE} eq 'accel_pptp' or ($NAS->{NAS_TYPE} eq 'lepppd') or
   ($NAS->{NAS_TYPE} eq 'pppd')) {
  my $EX_PARAMS = $self->ex_traffic_params({ 
  	                                         traf_limit => $traf_limit, 
                                             deposit    => $self->{DEPOSIT},
                                             MAX_SESSION_TRAFFIC => $MAX_SESSION_TRAFFIC 
                                           });

  #global Traffic
  if ($EX_PARAMS->{traf_limit} > 0) {
    $RAD_PAIRS->{'Session-Octets-Limit'} = int($EX_PARAMS->{traf_limit} * $CONF->{KBYTE_SIZE} * $CONF->{KBYTE_SIZE});
    
    if ($CONF->{octets_direction} && $CONF->{octets_direction} eq 'user') {
      if($self->{OCTETS_DIRECTION} == 1) {
        $RAD_PAIRS->{'Octets-Direction'} = 2;
       }
      elsif($self->{OCTETS_DIRECTION} == 2) {
        $RAD_PAIRS->{'Octets-Direction'} = 1;
       }
      else {
      	$RAD_PAIRS->{'Octets-Direction'} = 0;
       }
     }
    else {
    	$RAD_PAIRS->{'Octets-Direction'}     = $self->{OCTETS_DIRECTION};
     }
   }

  $RAD_PAIRS->{'User-Name'}=$self->{USER_NAME};

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
#Chillispot
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
if( $CONF->{MAC_AUTO_ASSIGN} && 
    $self->{CID} eq '' && 
    $RAD->{CALLING_STATION_ID} && 
    $RAD->{CALLING_STATION_ID} =~ /:|\-/ && $RAD->{CALLING_STATION_ID} !~ /\// 
   ) {
  $self->query($db, "UPDATE dv_main SET cid='$RAD->{CALLING_STATION_ID}'
     WHERE uid='$self->{UID}';", 'do');
 }

# SET ACCOUNT expire date
if( $self->{ACCOUNT_AGE} > 0 && $self->{ACCOUNT_ACTIVATE} eq '0000-00-00') {
  $self->query($db, "UPDATE users SET  activate=curdate(), expire=curdate() + INTERVAL $self->{ACCOUNT_AGE} day 
     WHERE uid='$self->{UID}';", 'do');
 }

$RAD_PAIRS->{'Acct-Interim-Interval'}=$NAS->{NAS_ALIVE} if ($NAS->{NAS_ALIVE});

#check TP Radius Pairs
  if ($self->{TP_RAD_PAIRS}) {
    $self->{TP_RAD_PAIRS} =~ s/\r|\n//g;
    my @p = split(/,/, $self->{TP_RAD_PAIRS});
    foreach my $line (@p) {
      if ($line =~ /([a-zA-Z0-9\-]{6,25})\+\=(.{1,200})/ ) {
        my $left=$1;
        my $right=$2;

        #$right =~ s/\"//g;
        push( @{ $RAD_PAIRS->{"$left"} }, $right ); 
       }
      else {
         my($left, $right)=split(/=/, $line, 2);
         $left =~ s/^ //g;
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
  if (! $RAD->{CALLING_STATION_ID}) {
     $RAD_PAIRS->{'Reply-Message'}="Wrong CID ''";
     return 1, $RAD_PAIRS, "Wrong CID ''";
   }
 
 	my @CID_POOL = split(/;/, $self->{CID});
	#If auth from DHCP
  if ($CONF->{DHCP_CID_IP} || $CONF->{DHCP_CID_MAC} || $CONF->{DHCP_CID_MPD}) {
    $self->query($db, "SELECT INET_NTOA(dh.ip), dh.mac
	       FROM dhcphosts_hosts dh
         LEFT JOIN users u ON u.uid=dh.uid
	       WHERE  u.id='$RAD->{USER_NAME}'
	         AND dh.disable = 0
           AND dh.mac='$RAD->{CALLING_STATION_ID}'");
    if($self->{errno}) {
	      $RAD_PAIRS->{'Reply-Message'}='SQL error';
        undef $db;
        return 1, $RAD_PAIRS;
     }
    elsif ($self->{TOTAL} >0) {
	    foreach my $line (@{$self->{list}}) {
	      my $ip = $line->[0];
	      my $mac = $line->[1];
	      if (($RAD->{CALLING_STATION_ID} =~ /:/ || $RAD->{CALLING_STATION_ID} =~ /\-/)
      		&& $RAD->{CALLING_STATION_ID} !~ /\./ && $CONF->{DHCP_CID_MAC}) {
          	#MAC
          	push(@CID_POOL, $mac);
	       }
	      elsif ($RAD->{CALLING_STATION_ID} !~ /:/ && $RAD->{CALLING_STATION_ID} !~ /\-/
    		  && $RAD->{CALLING_STATION_ID} =~ /\./ && $CONF->{DHCP_CID_IP}) {
    		  #IP
          push(@CID_POOL, $ip);
    	   }
	      elsif ($RAD->{CALLING_STATION_ID} =~ /\// && $CONF->{DHCP_CID_MPD}) {
		    #MPD IP+MAC
         	push(@CID_POOL, "$ip/$mac");
	       }
	    }
    }
  }
 	
 	
  foreach my $TEMP_CID (@CID_POOL) { if ($TEMP_CID ne '') {
    if (($TEMP_CID =~ /:/ || $TEMP_CID =~ /\-/)
       && $TEMP_CID !~ /\./) {
      @MAC_DIGITS_GET=split(/:|-/, $TEMP_CID);

      #NAS MPD 3.18 with patch
      if ($RAD->{CALLING_STATION_ID} =~ /\//) {
         $RAD->{CALLING_STATION_ID} =~ s/ //g;
         my ($cid_ip, $trash);
         ($cid_ip, $RAD->{CALLING_STATION_ID}, $trash) = split(/\//, $RAD->{CALLING_STATION_ID}, 3);
       }

      my @MAC_DIGITS_NEED = split(/:|\-|\./, $RAD->{CALLING_STATION_ID});
      my $counter=0;

      for(my $i=0; $i<=5; $i++) {
         if(defined($MAC_DIGITS_NEED[$i]) && hex($MAC_DIGITS_NEED[$i]) == hex($MAC_DIGITS_GET[$i])) {
	         $counter++;
          }
       }
      return 0 if ($counter eq '6');
     }
    # If like MPD CID
    # 192.168.101.2 / 00:0e:0c:4a:63:56 
    elsif($TEMP_CID =~ /\//) {
      $RAD->{CALLING_STATION_ID} =~ s/ //g;
      my ($cid_ip, $cid_mac, $trash) = split(/\//, $RAD->{CALLING_STATION_ID}, 3);
      if ("$cid_ip/$cid_mac" eq $TEMP_CID) {
        return 0;
       }
     }
    elsif($TEMP_CID eq $RAD->{CALLING_STATION_ID}) {
      return 0;
     }
   }

  }

 $RAD_PAIRS->{'Reply-Message'}="Wrong CID '$RAD->{CALLING_STATION_ID}'";
 return 1, $RAD_PAIRS;
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

if ($NAS->{NAS_TYPE} eq 'cid_auth' && $RAD->{CALLING_STATION_ID}) {
  $self->query($db, "select
  u.uid,
  DECODE(u.password, '$SECRETKEY'),
  UNIX_TIMESTAMP(),
  UNIX_TIMESTAMP(DATE_FORMAT(FROM_UNIXTIME(UNIX_TIMESTAMP()), '%Y-%m-%d')),
  DAYOFWEEK(FROM_UNIXTIME(UNIX_TIMESTAMP())),
  DAYOFYEAR(FROM_UNIXTIME(UNIX_TIMESTAMP())),
  u.company_id,
  u.disable,
  u.bill_id,
  u.credit,
  u.activate,
  u.reduction,
  u.ext_bill_id,
  UNIX_TIMESTAMP(u.expire),
  u.id
     FROM users u, dv_main dv
     WHERE dv.uid=u.uid 
        AND dv.CID='$RAD->{CALLING_STATION_ID}'
        AND (u.expire='0000-00-00' or u.expire > CURDATE())
        AND (u.activate='0000-00-00' or u.activate <= CURDATE())
        AND u.deleted='0'
       GROUP BY u.id;");

   if ($self->{TOTAL} < 1) {
     $RAD->{USER_NAME}=$RAD->{CALLING_STATION_ID};
     if ($RAD->{USER_NAME}) {
     	  goto AUTH;
      }
    }
   else {
     $RAD->{USER_NAME}  = $self->{list}->[0]->[14];
     delete($RAD->{USER_PASSWORD});
    }
 }
else {
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
    	$RAD_PAIRS{'Ascend-Dial-Number'}=$number;
    	$RAD_PAIRS{'Ascend-Data-Svc'}         = 'Switched-modem';
      $RAD_PAIRS{'Ascend-Send-Auth'}        = 'Send-Auth-None';
      $RAD_PAIRS{'Ascend-CBCP-Enable'}      = 'CBCP-Enabled';
      $RAD_PAIRS{'Ascend-CBCP-Mode'}        = 'CBCP-Profile-Callback';
      $RAD_PAIRS{'Ascend-CBCP-Trunk-Group'} = 5;
      $RAD_PAIRS{'Ascend-Callback-Delay'}   = 30;
     }
    else {
      $RAD_PAIRS{'Callback-Number'}=$number;
     }

    $RAD->{USER_NAME}=$login;
   }
  elsif ($RAD->{USER_NAME} =~ / /) {
    $RAD_PAIRS{'Reply-Message'}="Login Not Exist or Expire. Space in login '$RAD->{USER_NAME}'";
    return 1, \%RAD_PAIRS;
   }

  AUTH:
  
  my $WHERE  = '';
  if ($NAS->{DOMAIN_ID}) {
  	$WHERE = "AND u.domain_id='$NAS->{DOMAIN_ID}'";
   }
  else {
  	$WHERE = "AND u.domain_id='0'";
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
  u.reduction,
  u.ext_bill_id,
  UNIX_TIMESTAMP(u.expire)
     FROM users u
     WHERE 
        u.id='$RAD->{USER_NAME}' $WHERE
        AND (u.expire='0000-00-00' or u.expire > CURDATE())
        AND (u.activate='0000-00-00' or u.activate <= CURDATE())
        AND u.deleted='0'
       GROUP BY u.id;");
}
  if($self->{errno}) {
  	$RAD_PAIRS{'Reply-Message'}='SQL error';
  	undef $db;
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
   $self->{REDUCTION},
   $self->{EXT_BILL_ID},
   $self->{ACC_EXPIRE}
   ) = @{ $self->{list}->[0] };


#Auth chap
if( $RAD->{HINT} && $RAD->{HINT} eq 'NOPASS') {

 } 
elsif ($RAD->{CHAP_PASSWORD} && $RAD->{CHAP_CHALLENGE}) {
  if (check_chap("$RAD->{CHAP_PASSWORD}", "$self->{PASSWD}", "$RAD->{CHAP_CHALLENGE}", 0) == 0) {
    $RAD_PAIRS{'Reply-Message'}="Wrong CHAP password";
    return 1, \%RAD_PAIRS;
   }      	 	
 }
#Auth MS-CHAP v1,v2
elsif($RAD->{MS_CHAP_CHALLENGE}) {
     
 }
#End MS-CHAP auth
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
  if ($RAD->{CISCO_AVPAIR} =~ /client-mac-address=([a-f0-9\.\-\:]+)/) {
    $RAD->{CALLING_STATION_ID}=$1;
    if ($RAD->{CALLING_STATION_ID} =~ /(\S{2})(\S{2})\.(\S{2})(\S{2})\.(\S{2})(\S{2})/) {
       $RAD->{CALLING_STATION_ID}="$1:$2:$3:$4:$5:$6";
     }
  }
}
elsif ($RAD->{'TUNNEL_CLIENT_ENDPOINT:0'}) {
  $RAD->{CALLING_STATION_ID}=$RAD->{'TUNNEL_CLIENT_ENDPOINT:0'};
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
#Check Bill account
# check_bill_account()
#*******************************************************************
sub check_bill_account() {
  my $self = shift;

  if ($CONF->{EXT_BILL_ACCOUNT} && $self->{EXT_BILL_ID}) {
    $self->query($db, "SELECT id, ROUND(deposit, 2) FROM bills 
     WHERE id='$self->{BILL_ID}' or id='$self->{EXT_BILL_ID}';");
    if($self->{errno}) {
      return $self;
     }
    elsif ($self->{TOTAL} < 1) {
      $self->{errno}=2;
      $self->{errstr}="Ext Bill account Not Exist";
      return $self;
     }

    foreach my $l (@{ $self->{list} })  {
      if ($self->{EXT_BILL_ID} && $l->[0] == $self->{EXT_BILL_ID}) {
        $self->{EXT_BILL_DEPOSIT} = $l->[1];
       }
      else {
      	$self->{DEPOSIT} = $l->[1];
       }
  	 } 
   }
  else {
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
   }
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

  ($self->{BILL_ID},
   $self->{DISABLE},
   $self->{COMPANY_CREDIT}
    ) = @{ $self->{list}->[0]  };
  $self->{CREDIT}=$self->{COMPANY_CREDIT} if ($self->{CREDIT} == 0);

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

 my %prepaids      = (0 => 0, 1 => 0);
 my %speeds        = ();
 my %in_prices     = ();
 my %out_prices    = ();
 my %trafic_limits = ();
 my %expr          = ();
 
   my $nets = 0;

   $self->query($db, "SELECT id, in_price, out_price, prepaid, in_speed, out_speed, net_id, expression
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
     $prepaids{$line->[0]}            = $line->[3];
     $in_prices{$line->[0]}           = $line->[1];
     $out_prices{$line->[0]}          = $line->[2];
     $EX_PARAMS{speed}{$line->[0]}{IN}= $line->[4];
     $EX_PARAMS{speed}{$line->[0]}{OUT}= $line->[5];
     $expr{$line->[0]}=$line->[7] if (length($line->[7]) > 5);
     $EX_PARAMS{nets} = 1 if ($line->[6] > 0);
    }

#Get tarfic limit if prepaid > 0 or
# expresion exist
if ((defined($prepaids{0}) && $prepaids{0} > 0 ) || (defined($prepaids{1}) && $prepaids{1}>0 ) || $expr{0} || $expr{1}) {

  my $start_period = ($self->{ACCOUNT_ACTIVATE} ne '0000-00-00') ? "DATE_FORMAT(start, '%Y-%m-%d')>='$self->{ACCOUNT_ACTIVATE}'" : undef;
  my $used_traffic=$Billing->get_traffic({ UID    => $self->{UID},
  	                                       UIDS   => $self->{UIDS},
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
    my $interval = undef;
  	if ($self->{ACCOUNT_ACTIVATE} ne '0000-00-00') {
      $interval = "(DATE_FORMAT(start, '%Y-%m-%d')>='$self->{ACCOUNT_ACTIVATE}' - INTERVAL $self->{TRAFFIC_TRANSFER_PERIOD} * 30 DAY && 
       DATE_FORMAT(start, '%Y-%m-%d')<='$self->{ACCOUNT_ACTIVATE}')";
  	 }
    else {
    	$interval = "(DATE_FORMAT(start, '%Y-%m')>=DATE_FORMAT(curdate() - INTERVAL $self->{TRAFFIC_TRANSFER_PERIOD} MONTH, '%Y-%m') AND 
    	 DATE_FORMAT(start, '%Y-%m')<=DATE_FORMAT(curdate(), '%Y-%m') ) ";
     }
    
    # Traffic transfer
    my $transfer_traffic=$Billing->get_traffic({ UID      => $self->{UID},
    	                                           UIDS     => $self->{UIDS},
                                                 INTERVAL => $interval,
                                                 TP_ID    => $self->{TP_ID},
                                                 TP_NUM   => $self->{TP_NUM},
                                               });

    if ($Billing->{TOTAL} > 0) {
      if($self->{OCTETS_DIRECTION} == 1) {
 	      $prepaids{0} += $prepaids{0} * $self->{TRAFFIC_TRANSFER_PERIOD} - $transfer_traffic->{TRAFFIC_IN} if ( $prepaids{0} > $transfer_traffic->{TRAFFIC_IN} );
        $prepaids{1} += $prepaids{1} * $self->{TRAFFIC_TRANSFER_PERIOD} - $transfer_traffic->{TRAFFIC_IN_2} if ( $prepaids{1} > $transfer_traffic->{TRAFFIC_IN_2} );
       }
      #Sent / OUT
      elsif ($self->{OCTETS_DIRECTION} == 2 ) {
 	      $prepaids{0} += $prepaids{0} * $self->{TRAFFIC_TRANSFER_PERIOD} - $transfer_traffic->{TRAFFIC_OUT} if ( $prepaids{0} > $transfer_traffic->{TRAFFIC_OUT} );
        $prepaids{1} += $prepaids{1} * $self->{TRAFFIC_TRANSFER_PERIOD} - $transfer_traffic->{TRAFFIC_OUT_2} if ( $prepaids{1} > $transfer_traffic->{TRAFFIC_OUT_2} );
       }
      else {
 	      $prepaids{0} += $prepaids{0} * $self->{TRAFFIC_TRANSFER_PERIOD} - ($transfer_traffic->{TRAFFIC_IN}+$transfer_traffic->{TRAFFIC_OUT}) if ($prepaids{0} > ($transfer_traffic->{TRAFFIC_IN}+$transfer_traffic->{TRAFFIC_OUT}));
        $prepaids{1} += $prepaids{1} * $self->{TRAFFIC_TRANSFER_PERIOD} - ($transfer_traffic->{TRAFFIC_IN_2}+$transfer_traffic->{TRAFFIC_OUT_2}) if ( $prepaids{1} > ($transfer_traffic->{TRAFFIC_IN_2}+$transfer_traffic->{TRAFFIC_OUT_2}) );
       }   
     }
   }

  if ($self->{TOTAL} == 0) {
    $trafic_limits{0}=$prepaids{0} || 0;
    $trafic_limits{1}=$prepaids{1} || 0;
   }
  else {
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
  	$trafic_limits{0} =  $RESULT->{TRAFFIC_LIMIT} - $used_traffic->{TRAFFIC_COUNTER};
   }

    if ($RESULT->{SPEED}) {
        $EX_PARAMS{speed}{0}{IN}=$RESULT->{SPEED};
        $EX_PARAMS{speed}{0}{OUT}=$RESULT->{SPEED};
     }
    else {
      if ($RESULT->{SPEED_IN}) {
        $EX_PARAMS{speed}{0}{IN}=$RESULT->{SPEED_IN};
       }
      if ($RESULT->{SPEED_OUT}) {
        $EX_PARAMS{speed}{0}{OUT}=$RESULT->{SPEED_OUT};
       }
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
  if ($self->{REDUCTION} && $self->{REDUCTION} < 100) {
    $EX_PARAMS{traf_limit} = $EX_PARAMS{traf_limit} * (100 / (100 - $self->{REDUCTION}));
   }
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
#   -2 - No Free Address in TP pool
#   -1 - No free address in nas pool
#    0 - No address pool using nas servers ip address
#   192.168.101.1 - assign ip address
#
# get_ip($self, $nas_num, $nas_ip)
#*******************************************************************
sub get_ip {
 my $self = shift;
 my ($nas_num, $nas_ip, $attr) = @_;

 if ($attr->{TP_IPPOOL}) {
   $self->query($db, "SELECT ippools.ip, ippools.counts, ippools.id FROM ippools
     WHERE ippools.id='$attr->{TP_IPPOOL}'
     ORDER BY ippools.priority;");
  }
 else {
   $self->query($db, "SELECT ippools.ip, ippools.counts, ippools.id FROM ippools, nas_ippools
     WHERE ippools.id=nas_ippools.pool_id AND nas_ippools.nas_id='$nas_num'
     ORDER BY ippools.priority;");
  }

 if ($self->{TOTAL} < 1)  {
   return 0;
  }

 my @pools_arr      = ();
 my $list           = $self->{list};
 my @used_pools_arr = ();

 foreach my $line (@$list) {
    my $sip   = $line->[0]; 
    my $count = $line->[1];
    my $id    = $line->[2];
    push @used_pools_arr, $id;
    my %pools = ();

    for(my $i=$sip; $i<=$sip+$count; $i++) {
      $pools{$i}=1;
     }
    push @pools_arr, \%pools;
  }

 my $used_pools = join(', ', @used_pools_arr); 

 #get active address and delete from pool
 # Select from active users and reserv ips
 $self->query($db, "SELECT c.framed_ip_address
  FROM dv_calls c
  INNER JOIN nas_ippools np ON (c.nas_id=np.nas_id)
  WHERE np.pool_id in ( $used_pools );");

 # AND (status<>2)

 $list = $self->{list};
 $self->{USED_IPS}=0;

 my %pool = %{ $pools_arr[0] };

 for(my $i=0; $i<=$#pools_arr; $i++) {
   %pool = %{ $pools_arr[$i] };
   foreach my $ip (@$list) {
     if(exists($pool{$ip->[0]})) {
       delete($pool{$ip->[0]});
       $self->{USED_IPS}++;
      }
    } 
   last if (scalar(keys %pool ) > 0);
  }

 my @ips_arr = keys %pool;
 my $assign_ip = ($#ips_arr > -1) ? $ips_arr[rand ($#ips_arr+1)] : undef;

 if ($assign_ip) {
   # Make reserv ip
   $self->query($db, "INSERT INTO dv_calls (started, user_name, uid, framed_ip_address, nas_id, status, acct_session_id)
      VALUES (now(), '$self->{USER_NAME}', '$self->{UID}', '$assign_ip', '$nas_num', '11', 'IP');", 'do');
 
   $assign_ip = int2ip($assign_ip);
   return $assign_ip;
  }
 else { # no addresses available in pools
   if ($attr->{TP_POOLS}) {
   	 $self->get_ip($nas_num, $nas_ip); 
    }
   else {
     return -1;
    }
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

if ($RAD->{MS_CHAP_CHALLENGE} || $RAD->{EAP_MESSAGE}) {
  my $login = $RAD->{USER_NAME} || '';
  if ($login =~ /:(.+)/) {
    $login = $1;	 
  }

  $self->query($db, "SELECT DECODE(password, '$CONF->{secretkey}') FROM users WHERE id='$login';");
  if ($self->{TOTAL} > 0) {
  	my $list = $self->{list}->[0];
    my $password = $list->[0];
    
    if ($CONF->{RADIUS2}) {
       print "Cleartext-Password := \"$password\"";
       $self->{'RAD_CHECK'}{'Cleartext-Password'}="$password";
     }
    else {
       print "User-Password == \"$password\"";
       $self->{'RAD_CHECK'}{'User-Password'}="$password";
     }
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

#**********************************************************
#
#**********************************************************
sub neg_deposit_filter_former () {
	my $self = shift;
	my ($RAD, $NAS, $NEG_DEPOSIT_FILTER_ID, $attr) = @_;
	
	if ($attr->{RAD_PAIRS}) {
	  $RAD_PAIRS = $attr->{RAD_PAIRS};
	 }
	else {
		undef $RAD_PAIRS;
	 }

	
	if (! $attr->{USER_FILTER}) {
    # Return radius attr    
      if ($self->{IP} ne '0' && ! $self->{NEG_DEPOSIT_IP_POOL}) {
        $RAD_PAIRS->{'Framed-IP-Address'} = "$self->{IP}";
       }
      else {
        my $ip = $self->get_ip($NAS->{NAS_ID}, "$RAD->{NAS_IP_ADDRESS}", { TP_IPPOOL => $self->{NEG_DEPOSIT_IP_POOL} || $self->{TP_IPPOOL} });
        if ($ip eq '-1') {
          $RAD_PAIRS->{'Reply-Message'}="Rejected! There is no free IPs in address pools (USED: $self->{USED_IPS}) ". (($self->{TP_IPPOOL}) ? " TP_IPPOOL: $self->{TP_IPPOOL}" : '' );
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
    }

   $NEG_DEPOSIT_FILTER_ID =~ s/\%IP\%/$RAD_PAIRS->{'Framed-IP-Address'}/g;
   $NEG_DEPOSIT_FILTER_ID =~ s/\%LOGIN\%/$RAD->{'USER_NAME'}/g;
   $self->{INFO}="Neg filter";
	 if ($NEG_DEPOSIT_FILTER_ID =~ /RAD:(.+)/) {
      	my $rad_pairs = $1;
        my @p = split(/,/, $rad_pairs);
        foreach my $line (@p) {        	
          if ($line =~ /([a-zA-Z0-9\-]{6,25})\s?\+\=(.{1,200})/ ) {
            my $left=$1;
            my $right=$2;
            #$right =~ s/\"//g;
            push( @{ $RAD_PAIRS->{"$left"} }, $right ); 
           }
          else {
            my($left, $right)=split(/=/, $line, 2);
            if ($left =~ s/^!//) {
              delete $RAD_PAIRS->{"$left"};
   	         }
   	        else {
   	        	#next if (! $self->{"$left"});
   	        	$right = '' if (! $right);
   	          $RAD_PAIRS->{"$left"}="$right";
   	         }
           }
         }
    }
   else {
    	$RAD_PAIRS->{'Filter-Id'} = "$NEG_DEPOSIT_FILTER_ID";
    }

  if ($attr->{USER_FILTER}) {
    return 0;
   }

	return 0, $RAD_PAIRS;
}

1
















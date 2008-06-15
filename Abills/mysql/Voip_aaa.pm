package Voip_aaa;
# VoIP AAA functions
#

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION
);

use Exporter;
$VERSION = 2.01;
@ISA = ('Exporter');
@EXPORT = qw();
@EXPORT_OK = ();
%EXPORT_TAGS = ();

# User name expration
use main;
use Billing;
use Auth;

@ISA  = ("main");
my ($db, $conf, $Billing);


my %RAD_PAIRS=();
my %ACCT_TYPES = ('Start',          1,
                  'Stop',           2,
                  'Alive',          3,
                  'Accounting-On',  7,
                  'Accounting-Off', 8);





#**********************************************************
# Init 
#**********************************************************
sub new {
  my $class = shift;
  ($db, $conf) = @_;
  my $self = { };
  bless($self, $class);

  my $Auth = Auth->new($db, $conf);
  $Billing = Billing->new($db, $conf);	

  return $self;
}



#**********************************************************
# Preproces
#**********************************************************
sub preproces {
	my ($RAD) = @_;
  
  my %CALLS_ORIGIN = (
  answer     => 0,
  originate  => 1,
  proxy      => 2) ;

	(undef, $RAD->{H323_CONF_ID})=split(/=/, $RAD->{H323_CONF_ID}, 2) if ($RAD->{H323_CONF_ID} =~ /=/);
	$RAD->{H323_CONF_ID} =~ s/ //g;

  if ($RAD->{H323_CALL_ORIGIN}) {
    (undef, $RAD->{H323_CALL_ORIGIN})=split(/=/, $RAD->{H323_CALL_ORIGIN}, 2) if ($RAD->{H323_CALL_ORIGIN} =~ /=/);
    $RAD->{H323_CALL_ORIGIN} = $CALLS_ORIGIN{$RAD->{H323_CALL_ORIGIN}};
   }

  (undef, $RAD->{H323_DISCONNECT_CAUSE}) = split(/=/, $RAD->{H323_DISCONNECT_CAUSE}, 2) if (defined($RAD->{H323_DISCONNECT_CAUSE}));

  $RAD->{CLIENT_IP_ADDRESS} = $RAD->{FRAMED_IP_ADDRESS} if($RAD->{FRAMED_IP_ADDRESS});

#        h323-gw-id = "h323-gw-id=ASMODEUSGK"

#  h323-setup-time = "h323-setup-time=14:48:32.000 EET Mon Dec 26 2005"
#  h323-connect-time = "h323-connect-time=14:48:58.000 EET Mon Dec 26 2005"
#  h323-disconnect-time = "h323-disconnect-time=14:51:38.000 EET Mon Dec 26 2005"
#  h323-disconnect-cause = "h323-disconnect-cause=10"
#  h323-remote-address = "h323-remote-address=192.168.101.4"
  
}




#**********************************************************
# user_info
#**********************************************************
sub user_info {
  my $self = shift;
  my ($RAD, $NAS) = @_;

  my $WHERE = " and number='$RAD->{USER_NAME}'";

  $self->query($db, "SELECT 
   voip.uid, 
   voip.number,
   voip.tp_id, 
   INET_NTOA(voip.ip),
   DECODE(password, '$conf->{secretkey}'),
   0,
   voip.allow_answer,
   voip.allow_calls,
   voip.disable,
   u.disable,
   u.reduction,
   u.bill_id,
   u.company_id,
   u.credit,
  UNIX_TIMESTAMP(),
  UNIX_TIMESTAMP(DATE_FORMAT(FROM_UNIXTIME(UNIX_TIMESTAMP()), '%Y-%m-%d')),
  DAYOFWEEK(FROM_UNIXTIME(UNIX_TIMESTAMP())),
  DAYOFYEAR(FROM_UNIXTIME(UNIX_TIMESTAMP()))

   FROM voip_main voip, 
        users u
   WHERE 
    u.uid=voip.uid
   $WHERE;");



  if ($self->{TOTAL} < 1) {
     return $self;
   }

  ($self->{UID},
   $self->{NUMBER},
   $self->{TP_ID}, 
   $self->{IP},
   $self->{PASSWORD},
   $self->{SIMULTANEOUSLY},
   $self->{ALLOW_ANSWER},
   $self->{ALLOW_CALLS},
   $self->{VOIP_DISABLE},
   $self->{USER_DISABLE},
   $self->{REDUCTION},
   $self->{BILL_ID},
   $self->{COMPANY_ID},
   $self->{CREDIT},

   $self->{SESSION_START}, 
   $self->{DAY_BEGIN}, 
   $self->{DAY_OF_WEEK}, 
   $self->{DAY_OF_YEAR}

  )= @{ $self->{list}->[0] };
  
  $self->{SIMULTANEOUSLY} = 0;

  #Chack Company account if ACCOUNT_ID > 0
  $self->check_company_account() if ($self->{COMPANY_ID} > 0);


$self->check_bill_account();
if($self->{errno}) {
  $RAD_PAIRS{'Reply-Message'}=$self->{errstr};
  return 1, \%RAD_PAIRS;
 }

  return $self;
}


#**********************************************************
# Accounting Work_
#**********************************************************
sub auth {
  my $self = shift;
  my ($RAD, $NAS) = @_;

  %RAD_PAIRS=();
  $self->user_info($RAD, $NAS);

  if($self->{errno}) {
    $RAD_PAIRS{'Reply-Message'}=$self->{errstr};
    return 1, \%RAD_PAIRS;
   }
  elsif ($self->{TOTAL} < 1) {
    $self->{errno} = 2;
    $self->{errstr} = 'ERROR_NOT_EXIST';
    $RAD_PAIRS{'Reply-Message'}="Caller Number Not Exist '$RAD->{USER_NAME}'";
    return 1, \%RAD_PAIRS;
   }

 if (defined($RAD->{CHAP_PASSWORD}) && defined($RAD->{CHAP_CHALLENGE})){
   if (check_chap("$RAD->{CHAP_PASSWORD}", "$self->{PASSWORD}", "$RAD->{CHAP_CHALLENGE}", 0) == 0) {
     $RAD_PAIRS{'Reply-Message'}="Wrong CHAP password '$self->{PASSWORD}'";
     return 1, \%RAD_PAIRS;
    }      	 	
  }
 else {
 	 if ($self->{IP} ne '0.0.0.0' && $self->{IP} ne $RAD->{FRAMED_IP_ADDRESS}) {
     $RAD_PAIRS{'Reply-Message'}="Not allow IP '$RAD->{FRAMED_IP_ADDRESS}' / $self->{IP} ";
     return 1, \%RAD_PAIRS;
 	  }
  }


#DIsable
if ($self->{DISABLE} ||  $self->{VOIP_DISABLE} || $self->{USER_DISABLE}) {
	#$RAD_PAIRS{'h323-return-code'}=7;
  $RAD_PAIRS{'Reply-Message'}="Account Disable";
  return 1, \%RAD_PAIRS;
}

$self->{PAYMENT_TYPE}=0;
if ($self->{PAYMENT_TYPE} == 0) {
  $self->{DEPOSIT}=$self->{DEPOSIT}+$self->{CREDIT}; #-$self->{CREDIT_TRESSHOLD};
  $RAD->{H323_CREDIT_AMOUNT}=$self->{DEPOSIT};
  #Check deposit
  if($self->{DEPOSIT}  <= 0) {
    $RAD_PAIRS{'Reply-Message'}="Negativ deposit '$self->{DEPOSIT}'. Rejected!";
    return 1, \%RAD_PAIRS;
   }
}
else {
  $self->{DEPOSIT}=0;
}



  
#  $self->check_bill_account();
# if call
  if(defined($RAD->{H323_CONF_ID})){
     preproces($RAD);
   
     if($self->{ALLOW_ANSWER} < 1 && $RAD->{H323_CALL_ORIGIN} == 0){
       $RAD_PAIRS{'Reply-Message'}="Not allow answer";
       return 1, \%RAD_PAIRS;
      }
     elsif($self->{ALLOW_CALLS} < 1 && $RAD->{H323_CALL_ORIGIN} == 1){
     	 $RAD_PAIRS{'Reply-Message'}="Not allow calls";
       return 1, \%RAD_PAIRS;
      }

     # Get route
     my $query_params = '';
     
     for (my $i=1; $i<=length($RAD->{'CALLED_STATION_ID'}); $i++) { 
     	 $query_params .= '\''. substr($RAD->{'CALLED_STATION_ID'}, 0, $i) . '\','; 
     	}
     chop($query_params);

     $self->query($db, "SELECT r.id,
      r.prefix,
      r.gateway_id,
      r.disable
     FROM voip_routes r
      WHERE r.prefix in ($query_params)
      ORDER BY 2 DESC LIMIT 1;");

    if ($self->{TOTAL} < 1) {
       #$RAD_PAIRS{'h323-return-code'}=8;
       $RAD_PAIRS{'Reply-Message'}="No route '". $RAD->{'CALLED_STATION_ID'} ."'";
       return 1, \%RAD_PAIRS;
     }

    ($self->{ROUTE_ID},
     $self->{PREFIX},
     $self->{GATEWAY_ID}, 
     $self->{ROUTE_DISABLE},
     $self->{TRUNK_PROTOCOL},
     $self->{TRUNK_PATH}
    )= @{ $self->{list}->[0] };
  
    if ($self->{ROUTE_DISABLE} == 1) {
       $RAD_PAIRS{'Reply-Message'}="Route disabled '". $RAD->{'CALLED_STATION_ID'} ."'";
       return 1, \%RAD_PAIRS;
     }


    #Get intervals and prices
    if ($RAD->{H323_CALL_ORIGIN} == 1) {
       $self->get_intervals();
       if ($self->{TOTAL} < 1) {
         $RAD_PAIRS{'Reply-Message'}="No price for route prefix '$self->{PREFIX}' number '". $RAD->{'CALLED_STATION_ID'} ."'";
         return 1, \%RAD_PAIRS;
        }

       my ($session_timeout, $ATTR) = $Billing->remaining_time($self->{DEPOSIT}, {
    	    TIME_INTERVALS      => $self->{TIME_PERIODS},
          INTERVAL_TIME_TARIF => $self->{PERIODS_TIME_TARIF},
          SESSION_START       => $self->{SESSION_START},
          DAY_BEGIN           => $self->{DAY_BEGIN},
          DAY_OF_WEEK         => $self->{DAY_OF_WEEK},
          DAY_OF_YEAR         => $self->{DAY_OF_YEAR},
          REDUCTION           => $self->{REDUCTION},
          POSTPAID            => $self->{PAYMENT_TYPE},
          PRICE_UNIT          => 'Min'
         });
    
       if ($session_timeout > 0) {
         $RAD_PAIRS{'Session-Timeout'}=$session_timeout;    	

         #$RAD_PAIRS{'h323-credit-time'}=$session_timeout;
       }
  

#Make trunk data for asterisk  
if ($NAS->{NAS_TYPE} eq 'asterisk' and $self->{TRUNK_PROTOCOL}) {
	  $self->{prepend} = '';

    if ( $self->{TRUNK_PROTOCOL} eq "Local" ) {
        $RAD_PAIRS{'next-hop-ip'} = "Local/"
          . $self->{prepend}
          . $RAD->{'CALLED_STATION_ID'} . "\@"
          . $self->{TRUNK_PROVIDER} . "/n";
    }
    elsif (  $self->{TRUNK_PROTOCOL} eq "IAX2" ) {
        $RAD_PAIRS{'next-hop-ip'} =
          "IAX2/" . $self->{TRUNK_PROVIDER} . "/" . $self->{prepend} . $RAD->{'CALLED_STATION_ID'};
     }
    elsif (  $self->{TRUNK_PROTOCOL} eq "Zap" ) {
        $RAD_PAIRS{'next-hop-ip'} =
          "Zap/" . $self->{TRUNK_PROVIDER} . "/" . $self->{prepend} . $RAD->{'CALLED_STATION_ID'};
    }
    elsif (  $self->{TRUNK_PROTOCOL} eq "SIP" ) {
        $RAD_PAIRS{'next-hop-ip'} =
          "SIP/" . $self->{prepend} . $RAD->{'CALLED_STATION_ID'} . "\@" . $self->{TRUNK_PROVIDER};
     }
    elsif (  $self->{TRUNK_PROTOCOL} eq "OH323" ) {
        $RAD_PAIRS{'next-hop-ip'} =
          "OH323/" . $self->{TRUNK_PROVIDER} . "/" . $self->{prepend} . $RAD->{'CALLED_STATION_ID'};
    }
    elsif (  $self->{TRUNK_PROTOCOL} eq "OOH323C" ) {
        $RAD_PAIRS{'next-hop-ip'} =
          "OOH323C/" . $self->{prepend} . $RAD->{'CALLED_STATION_ID'} . "\@" . $self->{TRUNK_PROVIDER};
    }
    elsif (  $self->{TRUNK_PROTOCOL} eq "H323" ) {
        $RAD_PAIRS{'next-hop-ip'} =
          "H323/" . $self->{prepend} . $RAD->{'CALLED_STATION_ID'} . "\@" . $self->{TRUNK_PROVIDER};
    }

    $RAD_PAIRS{'session-protocol'}=$self->{TRUNK_PROTOCOL};
    
 }    
       

  #Make start record in voip_calls
  my $SESSION_START = 'now()';
  $self->query($db, "INSERT INTO voip_calls 
   (  status,
      user_name,
      started,
      lupdated,
      calling_station_id,
      called_station_id,
      nas_id,
      client_ip_address,
      conf_id,
      call_origin,
      uid,
      bill_id,
      tp_id,
      route_id,
      reduction
   )
   values ('0', \"$RAD->{USER_NAME}\", $SESSION_START, UNIX_TIMESTAMP(), 
      '$RAD->{CALLING_STATION_ID}', '$RAD->{CALLED_STATION_ID}', '$NAS->{NAS_ID}',
      INET_ATON('$RAD->{CLIENT_IP_ADDRESS}'),
      '$RAD->{H323_CONF_ID}',
      '$RAD->{H323_CALL_ORIGIN}',
      '$self->{UID}',
      '$self->{BILL_ID}',
      '$self->{TP_ID}',
      '$self->{ROUTE_ID}',
      '$self->{REDUCTION}');", 'do');
   }
 }

  
  return 0, \%RAD_PAIRS;
}



#**********************************************************
#
#**********************************************************
sub get_intervals {
	my $self = shift;
	my ($attr) = @_;
	
	
  $self->query($db, "SELECT i.day, TIME_TO_SEC(i.begin), TIME_TO_SEC(i.end), 
    rp.price, i.id, rp.route_id,
    if (t.protocol IS NULL, '', t.protocol),
    if (t.protocol IS NULL, '', t.provider_ip)
      from intervals i, voip_route_prices rp
      LEFT JOIN voip_trunks t ON (rp.trunk=t.id)       
      where
         i.id=rp.interval_id 
         and i.tp_id  = '$self->{TP_ID}'
         and rp.route_id = '$self->{ROUTE_ID}';");

   my $list = $self->{list};
   my %time_periods = ();
   my %periods_time_tarif = ();
   $self->{TRUNK_PATH}='';
   $self->{TRUNK_PROVIDER}='';

   foreach my $line (@$list) {
     #$time_periods{INTERVAL_DAY}{INTERVAL_START}="INTERVAL_ID:INTERVAL_END";
     $time_periods{$line->[0]}{$line->[1]} = "$line->[4]:$line->[2]";
     #$periods_time_tarif{INTERVAL_ID} = "INTERVAL_PRICE";
     $periods_time_tarif{$line->[4]} = $line->[3];
     $self->{TRUNK_PROTOCOL}=$line->[6];
     $self->{TRUNK_PROVIDER}=$line->[7];
    }
  $self->{TIME_PERIODS}=\%time_periods;
  $self->{PERIODS_TIME_TARIF}=\%periods_time_tarif;
	
	
	return $self;
}



#**********************************************************
# Accounting Work_
#**********************************************************
sub accounting {
 my $self = shift;
 my ($RAD, $NAS)=@_;
 

 my $acct_status_type = $ACCT_TYPES{$RAD->{ACCT_STATUS_TYPE}};
 my $SESSION_START = (defined($RAD->{SESSION_START}) && $RAD->{SESSION_START} > 0) ?  "FROM_UNIXTIME($RAD->{SESSION_START})" : 'now()';
 
#   print "aaa $acct_status_type '$RAD->{ACCT_STATUS_TYPE}'  /$RAD->{SESSION_START}/"; 
#my $a=`echo "test $acct_status_type = $ACCT_TYPES{$RAD->{ACCT_STATUS_TYPE}}"  >> /tmp/12211 `;
 
 preproces($RAD);

#Start
if ($acct_status_type == 1) { 
  $self->query($db, "UPDATE voip_calls SET
    status='$acct_status_type',
    acct_session_id='$RAD->{ACCT_SESSION_ID}'
    WHERE conf_id='$RAD->{H323_CONF_ID}';", 'do');

 }
# Stop status
elsif ($acct_status_type == 2) {

  if ($RAD->{ACCT_SESSION_TIME} > 0) {
    $self->query($db, "SELECT 
      UNIX_TIMESTAMP(started),
      lupdated,
      acct_session_id,
      calling_station_id,
      called_station_id,
      nas_id,
      client_ip_address,
      conf_id,
      call_origin,
      uid,
      reduction,
      bill_id,
      tp_id,
      route_id,

      UNIX_TIMESTAMP(),
      UNIX_TIMESTAMP(DATE_FORMAT(FROM_UNIXTIME(UNIX_TIMESTAMP()), '%Y-%m-%d')),
      DAYOFWEEK(FROM_UNIXTIME(UNIX_TIMESTAMP())),
      DAYOFYEAR(FROM_UNIXTIME(UNIX_TIMESTAMP()))
    FROM voip_calls 
      WHERE 
      conf_id='$RAD->{H323_CONF_ID}'
      and call_origin='1';");

    if ($self->{TOTAL} < 1) {
   	  $self->{errno}=1;
  	  $self->{errstr}="Call not exists";
  	  $self->{Q}->finish();
  	  return $self;
     }
    elsif ($self->{errno}){
  	  $self->{errno}=1;
  	  $self->{errstr}="SQL error";
  	  return $self;
     }
  
    ($self->{SESSION_START},
     $self->{LAST_UPDATE},
     $self->{ACCT_SESSION_ID}, 
     $self->{CALLING_STATION_ID},
     $self->{CALLED_STATION_ID},
     $self->{NAS_ID},
     $self->{CLIENT_IP_ADDRESS},
     $self->{CONF_ID},
     $self->{CALL_ORIGIN},
     $self->{UID},
     $self->{REDUCTION},
     $self->{BILL_ID},
     $self->{TP_ID},
     $self->{ROUTE_ID},
   
     $self->{SESSION_STOP},
     $self->{DAY_BEGIN},
     $self->{DAY_OF_WEEK},
     $self->{DAY_OF_YEAR}
    
    )= @{ $self->{list}->[0] };
  

       $self->get_intervals();
       if ($self->{TOTAL} < 1) {
         $RAD_PAIRS{'Reply-Message'}="No price for route prefix '$self->{PREFIX}' number '". $RAD->{'CALLED_STATION_ID'} ."'";
         return 1, \%RAD_PAIRS;
        }

       $Billing->time_calculation({
    	    REDUCTION           => $self->{REDUCTION},
    	    TIME_INTERVALS      => $self->{TIME_PERIODS},
          PERIODS_TIME_TARIF =>  $self->{PERIODS_TIME_TARIF},
          SESSION_START       => $self->{SESSION_STOP} - $RAD->{ACCT_SESSION_TIME},
          ACCT_SESSION_TIME   => $RAD->{ACCT_SESSION_TIME},
          DAY_BEGIN           => $self->{DAY_BEGIN},
          DAY_OF_WEEK         => $self->{DAY_OF_WEEK},
          DAY_OF_YEAR         => $self->{DAY_OF_YEAR},
          PRICE_UNIT          => 'Min'
         });
  
  
    if ($Billing->{errno}) {
   	  $self->{errno}=$Billing->{errno};
  	  $self->{errstr}=$Billing->{errstr};
  	  return $self;
     }
  
    my $filename; 

    $self->query($db, "INSERT INTO voip_log (uid, start, duration, calling_station_id, called_station_id,
              nas_id, client_ip_address, acct_session_id, 
              tp_id, bill_id, sum,
              terminate_cause) 
        VALUES ('$self->{UID}', FROM_UNIXTIME($RAD->{SESSION_START}),  '$RAD->{ACCT_SESSION_TIME}', 
        '$RAD->{CALLING_STATION_ID}', '$RAD->{CALLED_STATION_ID}', 
        '$NAS->{NAS_ID}', INET_ATON('$RAD->{CLIENT_IP_ADDRESS}'), '$RAD->{ACCT_SESSION_ID}', 
        '$self->{TP_ID}', '$self->{BILL_ID}', '$Billing->{SUM}',
        '$RAD->{ACCT_TERMINATE_CAUSE}');", 'do');

    if ($self->{errno}) {
      $filename = "$RAD->{USER_NAME}.$RAD->{ACCT_SESSION_ID}";
      $self->{LOG_WARNING}="ACCT [$RAD->{USER_NAME}] Making accounting file '$filename'";
      $Billing->mk_session_log($RAD);
     }
# If SQL query filed
    else {
      if ($Billing->{SUM} > 0) {
         $self->query($db, "UPDATE bills SET deposit=deposit-$Billing->{SUM} WHERE id='$self->{BILL_ID}';", 'do');
       }
     }
   }
  else {
  	
   }

  # Delete from session wtmp
  $self->query($db, "DELETE FROM voip_calls 
     WHERE acct_session_id='$RAD->{ACCT_SESSION_ID}' 
     and user_name='$RAD->{USER_NAME}' 
     and nas_id='$NAS->{NAS_ID}'
     and conf_id='$RAD->{H323_CONF_ID}';", 'do');
 
}
#Alive status 3
elsif($acct_status_type eq 3) {
  #acct_session_time=UNIX_TIMESTAMP()-UNIX_TIMESTAMP(started),
  $self->query($db, "UPDATE voip_calls SET
    status='$acct_status_type',
    client_ip_address=INET_ATON('$RAD->{FRAMED_IP_ADDRESS}'),
    lupdated=UNIX_TIMESTAMP()
   WHERE
    acct_session_id='$RAD->{ACCT_SESSION_ID}' and 
    user_name='$RAD->{USER_NAME}' and
    client_ip_address=INET_ATON('$RAD->{CLIENT_IP_ADDRESS}');", 'do');
}
else {
  $self->{errno}=1;
  $self->{errstr}="ACCT [$RAD->{USER_NAME}] Unknown accounting status: $RAD->{ACCT_STATUS_TYPE} ($RAD->{ACCT_SESSION_ID})";
}

  if ($self->{errno}) {
  	$self->{errno}=1;
  	$self->{errstr}="ACCT $RAD->{ACCT_STATUS_TYPE} SQL Error";
   }



 return $self;
}


1

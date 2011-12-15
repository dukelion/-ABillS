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
# Pre_auth
#**********************************************************
sub pre_auth {
  my ($self, $RAD, $attr)=@_;

  $self->{'RAD_CHECK'}{'Auth-Type'}="Accept";
  return 0;
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
    $RAD->{H323_CALL_ORIGIN} = $CALLS_ORIGIN{$RAD->{H323_CALL_ORIGIN}} if ($RAD->{H323_CALL_ORIGIN} ne 1);
   }

  (undef, $RAD->{H323_DISCONNECT_CAUSE}) = split(/=/, $RAD->{H323_DISCONNECT_CAUSE}, 2) if (defined($RAD->{H323_DISCONNECT_CAUSE}));

  $RAD->{CLIENT_IP_ADDRESS} = $RAD->{FRAMED_IP_ADDRESS} if($RAD->{FRAMED_IP_ADDRESS});
}




#**********************************************************
# user_info
#**********************************************************
sub user_info {
  my $self = shift;
  my ($RAD, $NAS) = @_;

  my $WHERE = '';
  if (defined($RAD->{H323_CALL_ORIGIN}) && $RAD->{H323_CALL_ORIGIN}==0) {
    $WHERE = " and number='$RAD->{CALLED_STATION_ID}'"; 
    $RAD->{USER_NAME}=$RAD->{CALLED_STATION_ID};
   }
  else {
    $WHERE = " and number='$RAD->{USER_NAME}'";
   }

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
# 
#**********************************************************
sub number_expr {
	my ($RAD)=@_;
  my @num_expr = split(/;/, $conf->{VOIP_NUMBER_EXPR});

my $number = $RAD->{CALLED_STATION_ID};
for(my $i=0; $i<=$#num_expr; $i++) {
  my($left, $right)=split(/\//, $num_expr[$i]);
  my $r = eval "\"$right\"";
  if($RAD->{CALLED_STATION_ID} =~ s/$left/$r/) {
#    print "$i\n";
    last;
   }
}
	
	return 0;
}

#**********************************************************
# Accounting Work_
#**********************************************************
sub auth {
  my $self = shift;
  my ($RAD, $NAS) = @_;


  if(defined($RAD->{H323_CONF_ID})){
    preproces($RAD);
   }

  # For Cisco 
  if ($RAD->{USER_NAME} =~ /(\S+):(\d+)/) {
  	$RAD->{USER_NAME} = $2;
   }
  
  if($conf->{VOIP_NUMBER_EXPR}) {
  	number_expr($RAD);
   }

  %RAD_PAIRS=();
  $self->user_info($RAD, $NAS);

  if($self->{errno}) {
    $RAD_PAIRS{'Reply-Message'}=$self->{errstr};
    return 1, \%RAD_PAIRS;
   }
  elsif ($self->{TOTAL} < 1) {
    $self->{errno}  = 2;
    $self->{errstr} = 'ERROR_NOT_EXIST';
    if (! $RAD->{H323_CALL_ORIGIN}) {
    	$RAD_PAIRS{'Reply-Message'}="Answer Number Not Exist '$RAD->{USER_NAME}'";
     }
    else {
    	$RAD_PAIRS{'Reply-Message'}="Caller Number Not Exist '$RAD->{USER_NAME}'";
     }
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
if ($self->{VOIP_DISABLE}) {
	if ($self->{VOIP_DISABLE} == 2 && $RAD->{H323_CALL_ORIGIN} == 1) {
    $RAD_PAIRS{'Reply-Message'}="Incoming only";	
    return 1, \%RAD_PAIRS;
	 }
	else {
    $RAD_PAIRS{'Reply-Message'}="Service Disable";	
    return 1, \%RAD_PAIRS;
   }
}
elsif ($self->{USER_DISABLE}) {
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
     if($self->{ALLOW_ANSWER} < 1 && $RAD->{H323_CALL_ORIGIN} == 0){
       $RAD_PAIRS{'Reply-Message'}="Not allow answer";
       return 1, \%RAD_PAIRS;
      }
     elsif($self->{ALLOW_CALLS} < 1 && $RAD->{H323_CALL_ORIGIN} == 1){
     	 $RAD_PAIRS{'Reply-Message'}="Not allow calls";
       return 1, \%RAD_PAIRS;
      }

    $self->get_route_prefix($RAD);
    if ($self->{TOTAL}<1) {
    	$RAD_PAIRS{'Reply-Message'}="No route '". $RAD->{'CALLED_STATION_ID'} ."'";
    	return 1, \%RAD_PAIRS;
     }
    elsif ($self->{ROUTE_DISABLE} == 1) {
       $RAD_PAIRS{'Reply-Message'}="Route disabled '". $RAD->{'CALLED_STATION_ID'} ."'";
       return 1, \%RAD_PAIRS;
     }


    #Get intervals and prices
    #originate
    if ($RAD->{H323_CALL_ORIGIN} == 1) {
        $self->{INFO}="$RAD->{'CALLED_STATION_ID'}";       
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
       elsif ($self->{PAYMENT_TYPE} == 0 && $session_timeout == 0) {
         $RAD_PAIRS{'Reply-Message'}="Too small deposit for call'";
         return 1, \%RAD_PAIRS;
        }

#Make trunk data for asterisk  
if ($NAS->{NAS_TYPE} eq 'asterisk' and $self->{TRUNK_PROTOCOL}) {
	  $self->{prepend} = '';
    
    my $number = $RAD->{'CALLED_STATION_ID'};
    if (defined($self->{REMOVE_PREFIX})) {
    	$number =~ s/^$self->{REMOVE_PREFIX}//;
     }

    if (defined($self->{ADDPREFIX})) {
    	$number = $self->{ADDPREFIX}. $number;
     }

    if ( $self->{TRUNK_PROTOCOL} eq "Local" ) {
        $RAD_PAIRS{'next-hop-ip'} = "Local/"
          . $self->{prepend}
          . $number . "\@"
          . $self->{TRUNK_PROVIDER} . "/n";
    }
    elsif (  $self->{TRUNK_PROTOCOL} eq "IAX2" ) {
        $RAD_PAIRS{'next-hop-ip'} =
          "IAX2/" . $self->{TRUNK_PROVIDER} . "/" . $self->{prepend} . $number;
     }
    elsif (  $self->{TRUNK_PROTOCOL} eq "Zap" ) {
        $RAD_PAIRS{'next-hop-ip'} =
          "Zap/" . $self->{TRUNK_PROVIDER} . "/" . $self->{prepend} . $number;
    }
    elsif (  $self->{TRUNK_PROTOCOL} eq "SIP" ) {
        $RAD_PAIRS{'next-hop-ip'} =
          "SIP/" . $self->{prepend} . $number . "\@" . $self->{TRUNK_PROVIDER};
     }
    elsif (  $self->{TRUNK_PROTOCOL} eq "OH323" ) {
        $RAD_PAIRS{'next-hop-ip'} =
          "OH323/" . $self->{TRUNK_PROVIDER} . "/" . $self->{prepend} . $number;
    }
    elsif (  $self->{TRUNK_PROTOCOL} eq "OOH323C" ) {
        $RAD_PAIRS{'next-hop-ip'} =
          "OOH323C/" . $self->{prepend} . $number . "\@" . $self->{TRUNK_PROVIDER};
    }
    elsif (  $self->{TRUNK_PROTOCOL} eq "H323" ) {
        $RAD_PAIRS{'next-hop-ip'} =
          "H323/" . $self->{prepend} . $number . "\@" . $self->{TRUNK_PROVIDER};
    }

    $RAD_PAIRS{'session-protocol'}=$self->{TRUNK_PROTOCOL};
    
 }    
}
else {
	$RAD->{USER_NAME} = "$RAD->{CALLED_STATION_ID}";
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
#   }
 }

  
  return 0, \%RAD_PAIRS;
}

#**********************************************************
#
#**********************************************************
sub get_route_prefix {
	my $self = shift;
	my ($RAD) = @_;

	
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
     return $self;
   }

    ($self->{ROUTE_ID},
     $self->{PREFIX},
     $self->{GATEWAY_ID}, 
     $self->{ROUTE_DISABLE},
     $self->{TRUNK_PROTOCOL},
     $self->{TRUNK_PATH}
    )= @{ $self->{list}->[0] };
  
  return $self;
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
    if (t.protocol IS NULL, '', t.provider_ip),
    if (t.protocol IS NULL, '', t.addparameter),
    if (t.protocol IS NULL, '', t.removeprefix),
    if (t.protocol IS NULL, '', t.addprefix),
    if (t.protocol IS NULL, '', t.failover_trunk),
    rp.extra_tarification
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
     $self->{TRUNK_PROTOCOL}= $line->[6];
     $self->{TRUNK_PROVIDER}= $line->[7];
     $self->{ADDPARAMETER}  = $line->[8];
     $self->{REMOVE_PREFIX} = $line->[9];
     $self->{ADDPREFIX}     = $line->[10];
     $self->{FAILOVER_TRUNK}= $line->[11];
     $self->{EXTRA_TARIFICATION} = $line->[12];
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
 my $sesssion_sum = 0;
 $RAD->{CLIENT_IP_ADDRESS}='0.0.0.0' if (! $RAD->{CLIENT_IP_ADDRESS});

 preproces($RAD);

 if ($NAS->{NAS_TYPE} eq 'cisco_voip') {
   if ($RAD->{USER_NAME} =~ /(\S+):(\d+)/) {
  	 $RAD->{USER_NAME} = $2;
    }
#   if ($RAD->{H323_CALL_ORIGIN}==0) {
# 	   $RAD->{H323_CALL_ORIGIN} = 1;
# 	   $RAD->{USER_NAME}=$RAD->{CALLING_STATION_ID};
#    }
#   else {
#   	 $RAD->{H323_CALL_ORIGIN} = 0;
#   	 $RAD->{USER_NAME}=$RAD->{CALLED_STATION_ID};
#    }
  }

 if($conf->{VOIP_NUMBER_EXPR}) {
 	 number_expr($RAD);
  }

#Start
if ($acct_status_type == 1) { 
  if ($NAS->{NAS_TYPE} eq 'cisco_voip') {
    # For Cisco 
    $self->user_info($RAD, $NAS);
  	
  	my $sql = "INSERT INTO voip_calls 
     (  status,
      user_name,
      started,
      lupdated,
      calling_station_id,
      called_station_id,
      nas_id,
      conf_id,
      call_origin,
      uid,
      bill_id,
      tp_id,
      reduction,
      acct_session_id,
      route_id
     )
    values ($acct_status_type, '$RAD->{USER_NAME}', $SESSION_START, UNIX_TIMESTAMP(), 
      '$RAD->{CALLING_STATION_ID}', '$RAD->{CALLED_STATION_ID}', '$NAS->{NAS_ID}',
      '$RAD->{H323_CONF_ID}',
      '$RAD->{H323_CALL_ORIGIN}',
      '$self->{UID}',
      '$self->{BILL_ID}',
      '$self->{TP_ID}',
      '$self->{REDUCTION}',
      '$RAD->{ACCT_SESSION_ID}',
      ''
      );";
  	
  	$self->query($db, $sql, 'do');
   }
  else {
    $self->query($db, "UPDATE voip_calls SET
      status='$acct_status_type',
      acct_session_id='$RAD->{ACCT_SESSION_ID}'
      WHERE conf_id='$RAD->{H323_CONF_ID}';", 'do');
   }
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
    FROM voip_calls c, voip_tps  tp
      WHERE  c.tp_id=tp.id
      conf_id='$RAD->{H323_CONF_ID}'
      and call_origin='$RAD->{H323_CALL_ORIGIN}';");




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
  
    if ($self->{UID} == 0) {
  	   $self->{errno}=110;
	     $self->{errstr}="Number not found '". $RAD->{'USER_NAME'} ."'";
	     return $self;
     }
    elsif ($RAD->{H323_CALL_ORIGIN} == 1) {
       if (! $self->{ROUTE_ID}) {
         $self->get_route_prefix($RAD);
        }

       $self->get_intervals();
       if ($self->{TOTAL} < 1) {
    	   $self->{errno}=111;
   	     $self->{errstr}="No price for route prefix '$self->{PREFIX}' number '". $RAD->{'CALLED_STATION_ID'} ."'";
  	     return $self;
        }

       # Extra tarification  
       if ($self->{EXTRA_TARIFICATION}) {
       	 $self->query($db, "SELECT prepaid_time FROM voip_route_extra_tarification WHERE id='$self->{EXTRA_TARIFICATION}';");
       	 $self->{PREPAID_TIME} = $self->{list}->[0]->[0];
       	 if ($self->{PREPAID_TIME} > 0) {
       	 	 $self->{LOG_DURATION} = 0;
       	 	 my $sql = "SELECT sum(duration) FROM voip_log l, voip_route_prices rp WHERE l.route_id=rp.route_id
       	 	   AND uid='$self->{UID}' AND rp.extra_tarification='$self->{EXTRA_TARIFICATION}'";
       	 	 $self->query($db, "$sql");
       	 	 $self->{LOG_DURATION}=0;
       	 	 if($self->{TOTAL}>0) {
       	 	 	 $self->{LOG_DURATION}=$self->{list}->[0]->[0];
       	 	  }
       	 	 if ($RAD->{ACCT_SESSION_TIME}+$self->{LOG_DURATION} < $self->{PREPAID_TIME}) {
       	 	 	 $self->{PERIODS_TIME_TARIF}=undef;
       	 	  }
       	   elsif ($self->{LOG_DURATION} < $self->{PREPAID_TIME} && $RAD->{ACCT_SESSION_TIME}+$self->{LOG_DURATION} > $self->{PREPAID_TIME}) {
       	   	 $self->{PAID_SESSION_TIME} = $RAD->{ACCT_SESSION_TIME}+$self->{LOG_DURATION} - $self->{LOG_DURATION};
       	    }
       	  }
        }  

       #Id defined time tarif
       if ($self->{PERIODS_TIME_TARIF}) {
         $Billing->time_calculation({
    	      REDUCTION           => $self->{REDUCTION},
    	      TIME_INTERVALS      => $self->{TIME_PERIODS},
            PERIODS_TIME_TARIF  => $self->{PERIODS_TIME_TARIF},
            SESSION_START       => $self->{SESSION_STOP} - $RAD->{ACCT_SESSION_TIME},
            ACCT_SESSION_TIME   => $self->{PAID_SESSION_TIME} || $RAD->{ACCT_SESSION_TIME},
            DAY_BEGIN           => $self->{DAY_BEGIN},
            DAY_OF_WEEK         => $self->{DAY_OF_WEEK},
            DAY_OF_YEAR         => $self->{DAY_OF_YEAR},
            PRICE_UNIT          => 'Min',
            TIME_DIVISION       => $self->{TIME_DIVISION}
           });

         $sesssion_sum = $Billing->{SUM};
         if ($Billing->{errno}) {
   	       $self->{errno}=$Billing->{errno};
  	       $self->{errstr}=$Billing->{errstr};
  	       return $self;
          }   
       }
    }

    my $filename;   
    $self->query($db, "INSERT INTO voip_log (uid, start, duration, calling_station_id, called_station_id,
              nas_id, client_ip_address, acct_session_id, 
              tp_id, bill_id, sum,
              terminate_cause, route_id) 
        VALUES ('$self->{UID}', FROM_UNIXTIME($RAD->{SESSION_START}),  '$RAD->{ACCT_SESSION_TIME}', 
        '$RAD->{CALLING_STATION_ID}', '$RAD->{CALLED_STATION_ID}', 
        '$NAS->{NAS_ID}', INET_ATON('$RAD->{CLIENT_IP_ADDRESS}'), '$RAD->{ACCT_SESSION_ID}', 
        '$self->{TP_ID}', '$self->{BILL_ID}', '$sesssion_sum',
        '$RAD->{ACCT_TERMINATE_CAUSE}', '$self->{ROUTE_ID}');", 'do');

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
     and nas_id='$NAS->{NAS_ID}'
     and conf_id='$RAD->{H323_CONF_ID}';", 'do');
}
#Alive status 3
elsif($acct_status_type eq 3) {
  $self->query($db, "UPDATE voip_calls SET
    status='$acct_status_type',
    client_ip_address=INET_ATON('$RAD->{FRAMED_IP_ADDRESS}'),
    lupdated=UNIX_TIMESTAMP()
   WHERE
    acct_session_id='$RAD->{ACCT_SESSION_ID}' and 
    user_name='$RAD->{USER_NAME}'
    );", 'do');
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

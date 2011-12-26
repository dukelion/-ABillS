package Billing;
# Main billing functions
#

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION
);

use Exporter;
$VERSION = 2.00;
@ISA = ('Exporter');
@EXPORT = qw();
@EXPORT_OK = ();
%EXPORT_TAGS = ();

# User name expration
use main;
use Tariffs;
@ISA  = ("main");
my $db;
my $CONF;

my $tariffs; 
my $time_intervals=0;
my $periods_time_tarif=0;
my $periods_traf_tarif=0;


#**********************************************************
# Init 
#**********************************************************
sub new {
  my $class = shift;
  ($db, $CONF) = @_;
  my $self = { };
  bless($self, $class);
  $CONF->{MB_SIZE} = $CONF->{KBYTE_SIZE} * $CONF->{KBYTE_SIZE};

  return $self;
}


#**********************************************************
# Return TRAFFIC SUM
# 
#**********************************************************
sub traffic_calculations {
	my $self = shift;
	my ($RAD)=@_;
	
  my $sent  = $RAD->{OUTBYTE}  || 0;  #default from server
  my $recv  = $RAD->{INBYTE}   || 0;  #default to server
  my $sent2 = $RAD->{OUTBYTE2} || 0; 
  my $recv2 = $RAD->{INBYTE2}  || 0;

  my $traffic_period = ($self->{ACTIVATE} ne '0000-00-00') ? "DATE_FORMAT(start, '%Y-%m-%d')>='$self->{ACTIVATE}'" : "DATE_FORMAT(start, '%Y-%m')=DATE_FORMAT(FROM_UNIXTIME($RAD->{SESSION_START}), '%Y-%m')" ;
  
  
   

  
####################################################################
# Prepaid local and global traffic separately
my %traf_price  = ();
my %prepaid     = ( 0 => 0, 
                    1 => 0);
my %expr        = ();

my $list = $tariffs->tt_list( { TI_ID => $self->{TI_ID} });
#id, in_price, out_price, prepaid, speed, descr, nets
foreach my $line (@$list) {
   $traf_price{in}{$line->[0]}  =	$line->[1];
   $traf_price{out}{$line->[0]} =	$line->[2];
   $prepaid{$line->[0]}         = $line->[3];
   $expr{$line->[0]}            = $line->[8] if (length($line->[8]) > 7);
}

  my $used_traffic;
  if ($CONF->{rt_billing}) {
  	$sent  = $RAD->{INTERIUM_OUTBYTE}  || 0; #from server
    $recv  = $RAD->{INTERIUM_INBYTE}   || 0;  #to server
    $sent2 = $RAD->{INTERIUM_OUTBYTE1} || 0; 
    $recv2 = $RAD->{INTERIUM_INBYTE1}  || 0;
   }

#print "Traf Calc: $sent / $recv\n";
#


if ($prepaid{0} + $prepaid{1} > 0) {
  #Traffic transfert function
  if ($self->{TRAFFIC_TRANSFER_PERIOD}) {
    my $tp = $self->{TP_NUM};

 my $uid="uid='$self->{UID}'";
 if ($self->{UIDS}) {
 	  $uid="uid IN ($self->{UIDS})";
  }
 
    my $WHERE = '';

  	if ($self->{ACTIVATE} ne '0000-00-00') {
      $WHERE  = "(DATE_FORMAT(start, '%Y-%m-%d')>='$self->{ACTIVATE}' - INTERVAL $self->{TRAFFIC_TRANSFER_PERIOD}-1 * 30 DAY )";
      #&& DATE_FORMAT(start, '%Y-%m-%d')<='$self->{ACTIVATE}')";
  	 }
    else {
    	$WHERE  = "(DATE_FORMAT(start, '%Y-%m')>=DATE_FORMAT(DATE_FORMAT(start, '%Y-%m-01') - INTERVAL $self->{TRAFFIC_TRANSFER_PERIOD} MONTH, '%Y-%m'))";
     }

 	 #Get using traffic
   $self->query($db, "select sum(sent / $CONF->{MB_SIZE} + 4092 * acct_output_gigawords), 
     sum(recv  / $CONF->{MB_SIZE} + 4092 * acct_input_gigawords),
     sum(sent2) / $CONF->{MB_SIZE},  
     sum(recv2) / $CONF->{MB_SIZE},
     DATE_FORMAT(start, '%Y-%m')
   FROM dv_log
   WHERE $uid  and tp_id='$tp' and
    (  $WHERE
      ) 
   GROUP BY 5
   ;");

  if ($self->{TOTAL} > 0) {
    my ($class1, $class2)  = (0, 0);
    my $monthes = 0;
    my $prepaid1 = $prepaid{0};
    my $prepaid2 = $prepaid{1};
    $prepaid{0}=0;
    $prepaid{1}=0;
    foreach my $line (@{$self->{list}}) {
    	#print "$prepaid{0} / $prepaid1 :: ". ($line->[0]+$line->[1]) ."\n";
      $prepaid{0}      = ((($prepaid{0}>0) ? $prepaid{0} : 0) + $prepaid1) - ($line->[0]+$line->[1]);
      $prepaid{1}      = ((($prepaid{1}>0) ? $prepaid{1} : 0) + $prepaid2) - ($line->[2]+$line->[3]);     
          	
      if ($prepaid2 > $line->[2] + $line->[3]) {
        $used_traffic->{TRAFFIC_IN_2} += $line->[2];
        $used_traffic->{TRAFFIC_OUT_2}+= $line->[3];
        $prepaid{1} += $prepaid2;
       }
     }


    if ($prepaid{0} <= 0) {
       $used_traffic->{TRAFFIC_OUT}  = abs( $prepaid{0} ) / 2 ;
       $used_traffic->{TRAFFIC_IN}   = abs( $prepaid{0} ) / 2 ;
     }
    else {
      $used_traffic->{TRAFFIC_OUT}  = 0 ;
      $used_traffic->{TRAFFIC_IN}   = 0 ;
     } 
  }
 }
else {
	#Get traffic from begin of month
  $used_traffic = $self->get_traffic({ UID    => $self->{UID},
  	                                   UIDS   => $self->{UIDS},
 	                                     PERIOD => $traffic_period,
 	                                     STATS_ONLY => 1
   	                                  });
 }



   if ($CONF->{rt_billing}) {
   	 $used_traffic->{TRAFFIC_IN}     += int($RAD->{INBYTE} / $CONF->{MB_SIZE}); 
   	 $used_traffic->{TRAFFIC_OUT}    += int($RAD->{OUTBYTE} / $CONF->{MB_SIZE});
   	 $used_traffic->{TRAFFIC_IN_2}   += int($RAD->{INBYTE2} / $CONF->{MB_SIZE}); 
   	 $used_traffic->{TRAFFIC_OUT_2}  += int($RAD->{OUTBYTE2} / $CONF->{MB_SIZE});
    }
   elsif ($RAD->{ACCT_INPUT_GIGAWORDS}) {
     $recv = $recv + $RAD->{ACCT_INPUT_GIGAWORDS} * 4294967296;
     $sent = $sent + $RAD->{ACCT_OUTPUT_GIGAWORDS} * 4294967296;
    }


   $used_traffic->{ONLINE}=0;
   #Recv / IN
   if($self->{OCTETS_DIRECTION} == 1) {
     $used_traffic->{TRAFFIC_SUM}   = $used_traffic->{TRAFFIC_IN};
     $used_traffic->{TRAFFIC_SUM_2} = $used_traffic->{TRAFFIC_IN_2};
     $used_traffic->{ONLINE} = $recv;
     $used_traffic->{ONLINE2}= $recv2;
    }
   #Sent / Out
   elsif($self->{OCTETS_DIRECTION}==2) {
   	 $used_traffic->{TRAFFIC_SUM}  = $used_traffic->{TRAFFIC_OUT};
     $used_traffic->{TRAFFIC_SUM_2}= $used_traffic->{TRAFFIC_OUT_2};
   	 $used_traffic->{ONLINE} = $sent;
   	 $used_traffic->{ONLINE2}= $sent2;
    }
   else {
     $used_traffic->{TRAFFIC_SUM}   = $used_traffic->{TRAFFIC_OUT} + $used_traffic->{TRAFFIC_IN};
     $used_traffic->{TRAFFIC_SUM_2} = $used_traffic->{TRAFFIC_OUT_2} + $used_traffic->{TRAFFIC_IN_2};
     $used_traffic->{ONLINE}  = $sent + $recv;
     $used_traffic->{ONLINE2} = $sent2 + $recv2;
    }

   #print "($used_traffic->{TRAFFIC_SUM} + $used_traffic->{ONLINE} / $CONF->{MB_SIZE} < $prepaid{'0'})\n";
   # If left global prepaid traffic set traf price to 0
   if ($used_traffic->{TRAFFIC_SUM} + $used_traffic->{ONLINE} / $CONF->{MB_SIZE} < $prepaid{'0'}) {
     $traf_price{in}{0} = 0;
     $traf_price{out}{0} = 0;
    }
   # 
   elsif ($used_traffic->{TRAFFIC_SUM} + $used_traffic->{ONLINE} / $CONF->{MB_SIZE} > $prepaid{0} 
            && $used_traffic->{TRAFFIC_SUM} < $prepaid{0}) {
     my $not_prepaid = ($used_traffic->{TRAFFIC_SUM} + $used_traffic->{ONLINE} / $CONF->{MB_SIZE} - $prepaid{0}) *  $CONF->{MB_SIZE};
     $sent = ($self->{OCTETS_DIRECTION}==2) ?  $not_prepaid : ($self->{OCTETS_DIRECTION}==1) ? $sent : $not_prepaid / 2;
     $recv = ($self->{OCTETS_DIRECTION}==1) ?  $not_prepaid : ($self->{OCTETS_DIRECTION}==2) ? $recv : $not_prepaid / 2;
    }

   # If left local prepaid traffic set traf price to 0
   if ($used_traffic->{TRAFFIC_SUM_2} < $prepaid{1}) {
     $traf_price{in}{1} = 0;
     $traf_price{out}{1} = 0;
    }
   elsif ( $used_traffic->{TRAFFIC_SUM_2} + $used_traffic->{ONLINE2} / $CONF->{MB_SIZE} > $prepaid{1} 
      && ( $used_traffic->{TRAFFIC_SUM_2} < $prepaid{1}) ) {
     my $not_prepaid = ($used_traffic->{TRAFFIC_SUM_2} + $used_traffic->{ONLINE2} / $CONF->{MB_SIZE} - $prepaid{1}) * $CONF->{MB_SIZE};
     $sent2 = ($self->{OCTETS_DIRECTION}==2) ?  $not_prepaid : $not_prepaid / 2;
     $recv2 = ($self->{OCTETS_DIRECTION}==1) ?  $not_prepaid : $not_prepaid / 2;
    }
 }
#Expration 
elsif (scalar(keys %expr) > 0) {
  my $RESULT = $self->expression($self->{UID}, \%expr, { RAD_ALIVE => ($RAD->{ACCT_STATUS_TYPE} && $RAD->{ACCT_STATUS_TYPE} eq 'Alive')  ? 1 : 0,
                                                         debug     => 0,
                                                         SESSION_TRAFFIC   =>
                                                         {
                       		     SESSION_TRAFFIC_OUT   => $sent || 0, 
                               SESSION_TRAFFIC_IN    => $recv || 0,
                               SESSION_TRAFFIC_OUT_2 => $sent || 0,
                               SESSION_TRAFFIC_IN_2  => $recv2|| 0
         	                    }
                                                           
                                                          });

  if (! $RESULT->{PRICE_IN} && ! $RESULT->{PRICE_OUT} && defined($RESULT->{PRICE})) {
  	$RESULT->{PRICE_IN} = $RESULT->{PRICE};
  	$RESULT->{PRICE_OUT}= $RESULT->{PRICE};
   }
  
  $traf_price{in}{0} = $RESULT->{PRICE_IN} if (defined($RESULT->{PRICE_IN}));
  $traf_price{out}{0}= $RESULT->{PRICE_OUT} if (defined($RESULT->{PRICE_OUT}));
}


#####################################################################
# TRafic payments
 my $traf_sum = 0;

 my $gl_in  = ($traf_price{in}{0}) ? $recv / $CONF->{MB_SIZE} * $traf_price{in}{0} : 0;
 my $gl_out = ($traf_price{out}{0}) ? $sent / $CONF->{MB_SIZE} * $traf_price{out}{0} : 0;
 my $lo_in  = (defined($traf_price{in}{1})) ?  $recv2 / $CONF->{MB_SIZE} * $traf_price{in}{1} : 0;
 my $lo_out = (defined($traf_price{out}{1})) ?  $sent2 / $CONF->{MB_SIZE} * $traf_price{out}{1} : 0;
 
# print " my $gl_in  = ($traf_price{in}{0}) ? $recv / $CONF->{MB_SIZE} * $traf_price{in}{0} : 0;
# my $gl_out = ($traf_price{out}{0}) ? $sent / $CONF->{MB_SIZE} * $traf_price{out}{0} : 0;
#";
 
 
 $traf_sum  = $lo_in + $lo_out + $gl_in + $gl_out;

 return $traf_sum;
}


#**********************************************************
# Get traffic from some period
# UID     - user id
# PERIOD  - start period
# 
# Return traffic recalculation by MB 
#
#**********************************************************
sub get_traffic {
	my ($self, $attr) = @_;

	my %result = (
	   TRAFFIC_OUT   => 0, 
     TRAFFIC_IN    => 0,
     TRAFFIC_OUT_2 => 0,
     TRAFFIC_IN_2  => 0
	);

  my $period = "DATE_FORMAT(start, '%Y-%m')=DATE_FORMAT(curdate(), '%Y-%m')";
  if ($attr->{PERIOD}) {
    $period = $attr->{PERIOD};
   }
  elsif($attr->{INTERVAL}) {
  	$period = $attr->{INTERVAL};
   }
  
  if ($attr->{TP_ID}) {
  	$period .= " AND tp_id='$attr->{TP_ID}'";
   }

  my $WHERE = "='$attr->{UID}'";
  if ($attr->{UIDS}) {
  	$WHERE = "IN ($attr->{UIDS})";
   }

  $self->query($db, "SELECT sum(sent)  / $CONF->{MB_SIZE} + sum(acct_output_gigawords) * 4096,  
                            sum(recv)  / $CONF->{MB_SIZE} + sum(acct_input_gigawords) * 4096, 
                            sum(sent2) / $CONF->{MB_SIZE}, 
                            sum(recv2) / $CONF->{MB_SIZE},
                            1
       FROM dv_log 
       WHERE uid $WHERE and ($period)
       GROUP BY 5;");

  if ($self->{TOTAL} > 0) {
    ($result{TRAFFIC_OUT}, 
     $result{TRAFFIC_IN},
     $result{TRAFFIC_OUT_2},
     $result{TRAFFIC_IN_2}
    )=@{ $self->{list}->[0] };
   }

  if ($attr->{STATS_ONLY}) {
    $self->{PERIOD_TRAFFIC}=\%result;
	  return \%result;
   }

  $self->query($db, "SELECT sum(acct_output_octets)  / $CONF->{MB_SIZE} + sum(acct_output_gigawords) * 4096,  
                            sum(acct_input_octets)  / $CONF->{MB_SIZE} + sum(acct_input_gigawords) * 4096, 
                            sum(acct_output_octets) / $CONF->{MB_SIZE}, 
                            sum(ex_input_octets) / $CONF->{MB_SIZE},
                            1
       FROM dv_calls 
       WHERE uid $WHERE
       GROUP BY 5;");

  if ($self->{TOTAL} > 0) {
    my ($TRAFFIC_OUT, 
     $TRAFFIC_IN,
     $TRAFFIC_OUT_2,
     $TRAFFIC_IN_2
     )=@{ $self->{list}->[0] };
     
     $result{TRAFFIC_OUT}   += $TRAFFIC_OUT;
     $result{TRAFFIC_IN}    += $TRAFFIC_IN;
     $result{TRAFFIC_OUT_2} += $TRAFFIC_OUT_2;
     $result{TRAFFIC_IN_2}  += $TRAFFIC_IN_2;     
   }
  
  $self->{PERIOD_TRAFFIC}=\%result;
	return \%result;
}




#**********************************************************
# Get traffic from some period using IPN stats
# UID     - user id
# PERIOD  - start period
# 
# Return traffic recalculation by MB 
#
#**********************************************************
sub get_traffic_ipn {
	my ($self, $attr) = @_;

	my %result = (
	   TRAFFIC_OUT   => 0, 
     TRAFFIC_IN    => 0,
     TRAFFIC_OUT_2 => 0,
     TRAFFIC_IN_2  => 0
	);

  my $period = "DATE_FORMAT(start, '%Y-%m')=DATE_FORMAT(curdate(), '%Y-%m')";
  if ($attr->{PERIOD}) {
    $period = $attr->{PERIOD};
   }
  elsif($attr->{INTERVAL}) {
  	$period = $attr->{INTERVAL};
   }
  
  if ($attr->{TP_ID}) {
  	$period .= " AND tp_id='$attr->{TP_ID}'";
   }

  if (defined($attr->{TRAFFIC_CLASS})) {
  	$period .= " AND traffic_class='$attr->{TRAFFIC_CLASS}'";
   }

  my $WHERE = "='$attr->{UID}'";

  if ($attr->{UIDS}) {
  	$WHERE = "IN ($attr->{UIDS})";
   }


  $self->query($db, "SELECT traffic_class,
                            sum(traffic_out) / $CONF->{MB_SIZE},  
                            sum(traffic_in) / $CONF->{MB_SIZE}
       FROM ipn_log 
       WHERE uid $WHERE and ($period)
       GROUP BY 1;");
 
  foreach my $line (@{ $self->{list} }) {
    if ($line->[0] == $attr->{TRAFFIC_CLASS}) {
      $result{TRAFFIC_OUT}=$line->[1]; 
      $result{TRAFFIC_IN} =$line->[2];
     }
   }
 
  $self->{PERIOD_TRAFFIC}=\%result;
	return \%result;
}

#**********************************************************
# Calculate session sum
# Return 
# >= 0 - session sum
# -1 Less than minimun session trafic and time
# -2 Can't find user account
# -3 SQL Error
# -4 Company not found
# -5 TP not found
# -16 Not allow start period
#
# session_sum($USER_NAME, $SESSION_START, $SESSION_DURATION, $RAD_HASH_REF, $attr);
#**********************************************************
sub session_sum {
 my $self = shift;
 my ($USER_NAME, 
     $SESSION_START, 
     $SESSION_DURATION, 
     $RAD, 
     $attr) = @_;

 my $sum = 0;
 $attr->{DOMAIN_ID}=0 if (! $attr->{DOMAIN_ID});
 $CONF->{rt_billing}=undef if ($attr->{disable_rt_billing});
 $self->{TI_ID} = 0;
 
 my $sent  = $RAD->{OUTBYTE} || 0; #from server
 my $recv  = $RAD->{INBYTE}  || 0; #to server
 my $sent2 = $RAD->{OUTBYTE2}|| 0; 
 my $recv2 = $RAD->{INBYTE2} || 0;

 # Don't calculate if session smaller then $CONF->{MINIMUM_SESSION_TIME} and  $CONF->{MINIMUM_SESSION_TRAF}
 if (! $attr->{FULL_COUNT} && 
     (
      ($CONF->{MINIMUM_SESSION_TIME} && $SESSION_DURATION < $CONF->{MINIMUM_SESSION_TIME}) || 
      ($CONF->{MINIMUM_SESSION_TRAF} && $sent + $recv + $sent2 + $recv2 < $CONF->{MINIMUM_SESSION_TRAF})
     )
    ) {
    return -1, 0, 0, 0, 0, 0;
  }

 $self->{HANGUP}=undef;

 if ($attr->{UID}) {
   $self->query($db, "SELECT 
    UNIX_TIMESTAMP(DATE_FORMAT(FROM_UNIXTIME($SESSION_START), '%Y-%m-%d')),
    DAYOFWEEK(FROM_UNIXTIME($SESSION_START)),
    DAYOFYEAR(FROM_UNIXTIME($SESSION_START)),
    u.reduction,
    u.bill_id,
    u.activate,
    u.company_id,
    u.domain_id,
    u.credit,
    u.ext_bill_id
   FROM users u
   WHERE u.uid='$attr->{UID}';");

   if($self->{errno}) {
     return -3, 0, 0, 0, 0, 0;
    }
   #user not found
   elsif ($self->{TOTAL} < 1) {
     return -2, 0, 0, 0, 0, 0;	
    }

  $self->{UID}=$attr->{UID};
  ($self->{DAY_BEGIN}, 
   $self->{DAY_OF_WEEK}, 
   $self->{DAY_OF_YEAR}, 
   $self->{REDUCTION},
   $self->{BILL_ID}, 
   $self->{ACTIVATE},
   $self->{COMPANY_ID},
   $attr->{DOMAIN_ID},
   $self->{CREDIT},
   $self->{EXT_BILL_ID}
  ) = @{ $self->{list}->[0] };	
 	
 	$self->query($db, "SELECT 
    tp.min_session_cost,
    tp.payment_type,
    tp.octets_direction,
    tp.traffic_transfer_period,
    tp.total_time_limit,
    tp.total_traf_limit,
    tp.tp_id,
    tp.neg_deposit_filter_id,
    tp.bills_priority
   FROM tarif_plans tp
   WHERE tp.id='$attr->{TP_NUM}' AND tp.domain_id='$attr->{DOMAIN_ID}';");

   if($self->{errno}) {
     return -3, 0, 0, 0, 0, 0;
    }
   #TP not found
   elsif ($self->{TOTAL} < 1) {
     return -5, 0, 0, 0, 0, 0;	
    }

   $self->{TP_NUM}=$attr->{TP_NUM};

   ( $self->{MIN_SESSION_COST},
     $self->{PAYMENT_TYPE},
     $self->{OCTETS_DIRECTION},
     $self->{TRAFFIC_TRANSFER_PERIOD},
     $self->{TOTAL_TIME_LIMIT},
     $self->{TOTAL_TRAF_LIMIT},
     $self->{TP_ID},
     $self->{NEG_DEPOSIT_FILTER},
     $self->{BILLS_PRIORITY}
    ) = @{ $self->{list}->[0] };
  }
 #If defined TP_NUM
 elsif ($attr->{TP_NUM}) {
   $self->query($db, "SELECT 
    u.uid,
    UNIX_TIMESTAMP(DATE_FORMAT(FROM_UNIXTIME($SESSION_START), '%Y-%m-%d')),
    DAYOFWEEK(FROM_UNIXTIME($SESSION_START)),
    DAYOFYEAR(FROM_UNIXTIME($SESSION_START)),
    u.reduction,
    u.bill_id,
    u.activate,
    u.company_id,
    u.ext_bill_id
   FROM users u
   WHERE  u.id='$USER_NAME' and u.domain_id='$attr->{DOMAIN_ID}';");

   if($self->{errno}) {
     return -3, 0, 0, 0, 0, 0;
    }
   #user not found
   elsif ($self->{TOTAL} < 1) {
     return -2, 0, 0, 0, 0, 0;	
    }

  ($self->{UID}, 
   $self->{DAY_BEGIN}, 
   $self->{DAY_OF_WEEK}, 
   $self->{DAY_OF_YEAR}, 
   $self->{REDUCTION},
   $self->{BILL_ID}, 
   $self->{ACTIVATE},
   $self->{COMPANY_ID},
   $self->{EXT_BILL_ID},
  ) = @{ $self->{list}->[0] };	
 	
 	$self->query($db, "SELECT 
    tp.min_session_cost,
    tp.payment_type,
    tp.octets_direction,
    tp.traffic_transfer_period,
    tp.total_time_limit,
    tp.total_traf_limit,
    tp.tp_id,
    tp.bills_priority
   FROM tarif_plans tp
   WHERE tp.id='$attr->{TP_NUM}' AND tp.domain_id='$attr->{DOMAIN_ID}';");

   if($self->{errno}) {
     return -3, 0, 0, 0, 0, 0;
    }
   #TP not found
   elsif ($self->{TOTAL} < 1) {
     return -5, 0, 0, 0, 0, 0;	
    }

   $self->{TP_NUM}=$attr->{TP_NUM};

   ( $self->{MIN_SESSION_COST},
     $self->{PAYMENT_TYPE},
     $self->{OCTETS_DIRECTION},
     $self->{TRAFFIC_TRANSFER_PERIOD},
     $self->{TOTAL_TIME_LIMIT},
     $self->{TOTAL_TRAF_LIMIT},
     $self->{TP_ID},
     $self->{BILLS_PRIORITY}
    ) = @{ $self->{list}->[0] };

  }
 else {
  $self->query($db, "SELECT 
    u.uid,
    tp.id, 
    UNIX_TIMESTAMP(DATE_FORMAT(FROM_UNIXTIME($SESSION_START), '%Y-%m-%d')),
    DAYOFWEEK(FROM_UNIXTIME($SESSION_START)),
    DAYOFYEAR(FROM_UNIXTIME($SESSION_START)),
    u.reduction,
    u.bill_id,
    u.activate,
    tp.min_session_cost,
    u.company_id,
    tp.payment_type,
    tp.octets_direction,
    tp.traffic_transfer_period,
    tp.neg_deposit_filter_id,
    dv.join_service,
    tp.tp_id,
    tp.total_time_limit,
    tp.total_traf_limit,
    u.ext_bill_id,
    tp.bills_priority
   FROM (users u, 
      dv_main dv) 
   LEFT JOIN tarif_plans tp ON (dv.tp_id=tp.id AND tp.domain_id='$attr->{DOMAIN_ID}')
   WHERE dv.uid=u.uid AND u.domain_id='$attr->{DOMAIN_ID}'
   and u.id='$USER_NAME';");
 
   if($self->{errno}) {
     return -3, 0, 0, 0, 0, 0;
    }
   #user not found
   elsif ($self->{TOTAL} < 1) {
     return -2, 0, 0, 0, 0, 0;	
    }
  
  ($self->{UID}, 
   $self->{TP_NUM}, 
   $self->{DAY_BEGIN}, 
   $self->{DAY_OF_WEEK}, 
   $self->{DAY_OF_YEAR}, 
   $self->{REDUCTION},
   $self->{BILL_ID}, 
   $self->{ACTIVATE},
   $self->{MIN_SESSION_COST},
   $self->{COMPANY_ID},
   $self->{PAYMENT_TYPE},
   $self->{OCTETS_DIRECTION},
   $self->{TRAFFIC_TRANSFER_PERIOD},
   $self->{NEG_DEPOSIT_FILTER},
   $self->{JOIN_SERVICE},
   $self->{TP_ID},
   $self->{TOTAL_TIME_LIMIT},
   $self->{TOTAL_TRAF_LIMIT},
   $self->{EXT_BILL_ID},
   $self->{BILLS_PRIORITY}
  ) = @{ $self->{list}->[0] };
 }

 
 if ($self->{JOIN_SERVICE}) {
 	 if ($self->{JOIN_SERVICE} > 1) {
       $self->query($db, "SELECT 
        tp.id, 
        tp.min_session_cost,
        tp.payment_type,
        tp.octets_direction,
        tp.traffic_transfer_period,
        tp.neg_deposit_filter_id,
        tp.tp_id
       FROM ( dv_main dv,  tarif_plans tp)
       WHERE dv.tp_id=tp.id, tp.domain_id='$attr->{DOMAIN_ID}'
       and dv.uid='$self->{JOIN_SERVICE}';");

     if($self->{errno}) {
       return -3, 0, 0, 0, 0, 0;
      }
     #user not found
     elsif ($self->{TOTAL} < 1) {
       return -2, 0, 0, 0, 0, 0;	
      }

     (
      $self->{TP_NUM}, 
      $self->{MIN_SESSION_COST},
      $self->{PAYMENT_TYPE},
      $self->{OCTETS_DIRECTION},
      $self->{TRAFFIC_TRANSFER_PERIOD},
      $self->{NEG_DEPOSIT_FILTER},
      $self->{TP_ID}
     ) = @{ $self->{list}->[0] };

     $self->{UIDS} = "$self->{JOIN_SERVICE}";
    }
   else {
     $self->{UIDS} = "$self->{UID}";
     $self->{JOIN_SERVICE} = $self->{UID};
    }

   $self->query($db, "SELECT uid FROM dv_main WHERE join_service='$self->{JOIN_SERVICE}';");
   foreach my $line ( @{ $self->{list} }) {
  	 $self->{UIDS} .= ", $line->[0]";
   }
 }

if ($self->{TOTAL_TIME_LIMIT} && $self->{CHECK_SESSION}) {
	if ($SESSION_DURATION >= $self->{TOTAL_TIME_LIMIT}) {
		$self->{HANGUP}=1;
		return $self->{UID}, 0, $self->{BILL_ID}, $self->{TP_NUM}, 0, 0;
	 }
 }

if ($self->{NEG_DEPOSIT_FILTER}) {
  $self->query($db, "SELECT deposit FROM bills WHERE id='$self->{BILL_ID}';");
  if ($self->{TOTAL} > 0) {
	( $self->{DEPOSIT}  ) = @{ $self->{list}->[0] };
	if ($self->{DEPOSIT} + $self->{CREDIT} < 0) {
		return $self->{UID}, 0, $self->{BILL_ID}, $self->{TP_NUM}, 0, 0;
	 }
   }
  else {
     return $self->{UID}, 0, $self->{BILL_ID}, $self->{TP_NUM}, 0, 0;
   }
}

if ($self->{TOTAL_TRAF_LIMIT} && $self->{CHECK_SESSION}) {
	if ($sent + $recv >= $self->{TOTAL_TRAF_LIMIT}) {
		$self->{HANGUP}=1;
		return $self->{UID}, 0, $self->{BILL_ID}, $self->{TP_NUM}, 0, 0;
	 }
 }

 if ($attr->{USER_INFO}) {
 	 return $self->{UID}, $sum, $self->{BILL_ID}, $self->{TP_NUM}, 0, 0;
  }

 $tariffs = Tariffs->new($db, $CONF);
 $self->session_splitter($SESSION_START,
                         $SESSION_DURATION,
                         $self->{DAY_BEGIN},
                         $self->{DAY_OF_WEEK}, 
                         $self->{DAY_OF_YEAR},
                         { 
                         	 TP_ID  => $self->{TP_ID} 
                         	 }
                        );

 #session devisions
 my @sd = @{ $self->{TIME_DIVISIONS_ARR} };

if(! defined($self->{NO_TPINTERVALS})) {
  if ($#sd < 0) {
    print "Not allow start period" if ($self->{debug});
    #$self->{HANGUP}=1;
    return -16, 0, 0, 0, 0, 0;	
   }
  
  for(my $i=0; $i<=$#sd; $i++) {
    my ($k, $v)=split(/,/,  $sd[$i]);
    print "> $k, $v\n" if ($self->{debug});

    $self->{TI_ID}=$k;
    if($periods_time_tarif->{$k} && $periods_time_tarif->{$k} > 0) {
      $sum += ($v * $periods_time_tarif->{$k}) / 60 / 60;
     }
   
    if( $i == 0 && defined($periods_traf_tarif->{$k}) && $periods_traf_tarif->{$k} > 0) {
      $sum  += $self->traffic_calculations({ %$RAD, 
       	                                     SESSION_START => $SESSION_START, 
       	                                     UIDS          => $self->{UIDS} });
      last;
     }
   }
}

#print "$sent / $recv - $sum\n";

$sum = $sum * (100 - $self->{REDUCTION}) / 100 if ($self->{REDUCTION} > 0);

if (! $attr->{FULL_COUNT}) {
  $sum = $self->{MIN_SESSION_COST} if ($self->{MIN_SESSION_COST} && $sum < $self->{MIN_SESSION_COST} && $self->{MIN_SESSION_COST} > 0);
}

if ($self->{COMPANY_ID} > 0) {
  $self->query($db, "SELECT bill_id, vat FROM companies
    WHERE id='$self->{COMPANY_ID}';");

  if ($self->{TOTAL} < 1) {
 	  return -4, 0, 0, 0, 0, 0;	
 	 }

  ($self->{BILL_ID}, $self->{VAT})= @{ $self->{list}->[0] };
  $sum = $sum + ((100 + $self->{COMPANY_VAT}) / 100) if ($self->{COMPANY_VAT});
}

  if ($CONF->{BONUS_EXT_FUNCTIONS} && $self->{EXT_BILL_ID} && $sum > 0 && $self->{BILLS_PRIORITY}) {
  	$self->query($db, "SELECT deposit FROM bills WHERE id='$self->{EXT_BILL_ID}';");
  	($self->{EXT_DEPOSIT})= @{ $self->{list}->[0] };
  	if ($self->{EXT_DEPOSIT} > $sum || $self->{BILLS_PRIORITY} == 2) {
  		$self->{BILL_ID}=$self->{EXT_BILL_ID};
  	 }
  	#my $aaa = `echo "$self->{BILL_ID} / $self->{EXT_BILL_ID} / D: $self->{EXT_DEPOSIT} /  SUM: $sum ! $self->{BILLS_PRIORITY}" >> /tmp/test_bonus`;
   }

  return $self->{UID}, sprintf("%.6f", $sum), $self->{BILL_ID}, $self->{TP_NUM}, 0, 0;
}



#********************************************************************
# Get Time intervals
# time intervals($TP_ID, $attr)
#********************************************************************
sub time_intervals {
 my $self = shift;
 my ($TP_ID, $attr) = @_;

 $self->query($db, "SELECT i.day, TIME_TO_SEC(i.begin),
   TIME_TO_SEC(i.end),
   i.tarif,
   if(sum(tt.in_price+tt.out_price) IS NULL || sum(tt.in_price+tt.out_price)=0, 0, sum(tt.in_price+tt.out_price)),
   i.id
   FROM (intervals i)
   LEFT JOIN  trafic_tarifs tt ON (tt.interval_id=i.id)
   WHERE i.tp_id='$TP_ID'
   GROUP BY i.id
   ORDER BY 1,2;");

 if ($self->{TOTAL} < 1) {
   return 0;	
  }

 my %time_periods = ();
 my %periods_time_tarif = (); 
 my %periods_traf_tarif = ();
 
 my $list = $self->{list};

 foreach my $line (@$list) {
   #$time_periods{INTERVAL_DAY}{INTERVAL_START}="INTERVAL_ID:INTERVAL_END";
   $time_periods{$line->[0]}{$line->[1]} = "$line->[5]:$line->[2]";
   $periods_time_tarif{$line->[5]} = $line->[3];
   # Traffic price
   $periods_traf_tarif{$line->[5]} = $line->[4]; 
  }

 return (\%time_periods, \%periods_time_tarif, \%periods_traf_tarif); 
}




#********************************************************************
# Split session to intervals
# session_splitter($start, $duration, $day_begin, $day_of_week, 
#                  $day_or_year, $intervals)
#********************************************************************
sub session_splitter {
 my $self = shift;
 my ($start, 
     $duration, 
     $day_begin, 
     $day_of_week, 
     $day_of_year, 
     $attr) = @_;
 
 my $debug = $self->{debug} || 0;
 my @division_time_arr = ();
 $self->{TIME_DIVISIONS_ARR} = \@division_time_arr;

 if ($attr->{TP_ID}) {
   ($time_intervals, $periods_time_tarif, $periods_traf_tarif) = $self->time_intervals($attr->{TP_ID});
  }
 else {
   $time_intervals      = $attr->{TIME_INTERVALS}     if (defined($attr->{TIME_INTERVALS}));
   $periods_time_tarif  = $attr->{PERIODS_TIME_TARIF} if (defined($attr->{PERIODS_TIME_TARIF}));
   $periods_traf_tarif  = $attr->{PERIODS_TIME_TARIF} if (defined($attr->{PERIODS_TRAF_TARIF}));
 }


 if ($time_intervals == 0)  {
   $self->{NO_TPINTERVALS} = 'y';
   $self->{SUM}=0;
   return $self;
  }
 else {
 	 delete $self->{NO_TPINTERVALS};
  }

 my %holidays = ();

 if (defined($time_intervals->{8})) {
   my $list = $tariffs->holidays_list({ format => 'daysofyear' });
   foreach my $line (@$list) {
     $holidays{$line->[0]} = 1;
    }
  }

my $tarif_day = 0;
my $count = 0;
$start = $start - $day_begin;

if ($debug == 1) {
  require Abills::Base;
  Abills::Base->import(); 
} 

 print "DAY_OF_WEEK: $day_of_week DAY_OF_YEAR: $day_of_year\n" if ($debug == 1);
 
 while($duration > 0 && $count < 10) {
   if(defined($holidays{$day_of_year}) && defined($time_intervals->{8})) {
     $tarif_day = 8;
    }
   elsif (defined($time_intervals->{$day_of_week})) {
     $tarif_day = $day_of_week;
    }
   elsif(defined($time_intervals->{0})) {
     $tarif_day = 0;
    }
   else {
     return -1;
    }

   $count++;
   print "Count: $count TARRIF_DAY: $tarif_day\n" if ($debug == 1);
   print "\t> Start: $start (". sec2time($start, { str => 'yes' }) .") Duration: $duration\n" if ($debug == 1);

   my $cur_int = $time_intervals->{$tarif_day};
   my $i;
   my $prev_tarif = '';

   TIME_INTERVALS:
     my @intervals = sort { $a <=> $b } keys %$cur_int; 
     $i = -1;
      
     foreach my $int_begin (@intervals) {
       my ($int_id, $int_end) = split(/:/, $cur_int->{$int_begin}, 2);
       $i++;

       print "\t Int Start: $start (". sec2time($start, { str => 'yes' }) .") Duration: $duration / FROM $int_begin TO $int_end | ". sec2time($int_begin, { str => 'yes' }) if ($debug == 1);
       if ($start >= $int_begin && $start < $int_end) {
         print " <<=USE\n" if ($debug == 1);    

         # if defined prev_tarif
         if ($prev_tarif ne '') {
           my ($p_day, $p_begin)=split(/:/, $prev_tarif, 2);
           $int_end=$p_begin  if ($p_begin > $start);
           print "Prev tarif $prev_tarif / INT end: $int_end \n" if ($debug == 1);
          }
         
         #IF Start + DUARATION < END period last the calculation 
         if ($start + $duration < $int_end) {
            #experimental division time arr
            push @division_time_arr, "$int_id,$duration";
            $duration = 0;
         	  last;
          }
         else {
              my $int_time = $int_end - $start;
              push @division_time_arr, "$int_id,$int_time";
             	$duration = $duration - $int_time;
             	$start = $start + $int_time;
             	if ($start == 86400) {
             	  $day_of_week = ($day_of_week + 1 > 7) ? 1   : $day_of_week + 1;
             	  $day_of_year = ($day_of_year + 1 > 365) ? 1 : $day_of_year + 1;
             	  $start = 0;
             	  last;
            	 }
          }

           print "  INT/TIME: $division_time_arr[$#division_time_arr]\n" if($debug==1);
           next;
          }
        elsif($i == $#intervals) {
       	  print "\n!! LAST@@@@ $i == $#intervals\n" if ($debug == 1);

       	  $prev_tarif = "$tarif_day:$int_begin";
       	  if(($tarif_day == 9) && defined($time_intervals->{$day_of_week})) {
            $tarif_day = $day_of_week;
       	    $cur_int = $time_intervals->{$tarif_day};
       	    print "Go to >> $tarif_day\n" if ($debug == 1);
       	   }
       	  elsif (defined($time_intervals->{0}) && $tarif_day != 0) {
       	    $tarif_day = 0;
       	    $cur_int = $time_intervals->{$tarif_day};
       	    print "Go to >> $tarif_day\n" if ($debug == 1);

       	    goto TIME_INTERVALS;
       	   }
      	}

        print "\n" if($debug == 1);    
      }
  }

 $self->{TIME_DIVISIONS_ARR} = \@division_time_arr;
 $self->{SUM}=0;
 
 return $self;
}



#*******************************************************************
#
#
#*******************************************************************
sub time_calculation() {
	my $self = shift;
	my ($attr) = @_;
  my $sum = 0;

  delete $self->{errno};
  delete $self->{errstr};

  $self->session_splitter($attr->{SESSION_START},
                   $attr->{ACCT_SESSION_TIME},
                   $attr->{DAY_BEGIN},
                   $attr->{DAY_OF_WEEK}, 
                   $attr->{DAY_OF_YEAR},
                   {  TIME_INTERVALS      => $attr->{TIME_INTERVALS},
                      PERIODS_TIME_TARIF  => $attr->{PERIODS_TIME_TARIF},
                    }
                  );
 
 
 my %PRICE_UNITS = (
  Hour => 3600,
  Min  => 60
 );
 
 my $PRICE_UNIT = (defined($PRICE_UNITS{$attr->{PRICE_UNIT}})) ? 60 : 3600;

 #session devisions
 my @sd = @{ $self->{TIME_DIVISIONS_ARR} };

if(! defined($self->{NO_TPINTERVALS})) {
  if($#sd < 0) {
   	$self->{errno} = 3;
   	$self->{errstr} = "Not allow start period-";
   }

  foreach my $line (@sd) {
    my ($k, $v)=split(/,/,  $line);
    if($periods_time_tarif->{$k}) {
   	  $sum += ($v * $periods_time_tarif->{$k}) / $PRICE_UNIT;
     }
   }
}

  $sum = $sum * (100 - $attr->{REDUCTION}) / 100 if (defined($attr->{REDUCTION}) && $attr->{REDUCTION} > 0);
  $self->{SUM}=$sum;
  return $self;
}


#********************************************************************
# Get current time info
#   SESSION_START
#   DAY_BEGIN
#   DAY_OF_WEEK
#   DAY_OF_YEAR
#********************************************************************
sub get_timeinfo {
  my $self = shift;

  $self->query($db, "select
    UNIX_TIMESTAMP(),
    UNIX_TIMESTAMP(DATE_FORMAT(FROM_UNIXTIME(UNIX_TIMESTAMP()), '%Y-%m-%d')),
    DAYOFWEEK(FROM_UNIXTIME(UNIX_TIMESTAMP())),
    DAYOFYEAR(FROM_UNIXTIME(UNIX_TIMESTAMP()));");

  if($self->{errno}) {
    return $self;
   }

 ($self->{SESSION_START},
  $self->{DAY_BEGIN},
  $self->{DAY_OF_WEEK},
  $self->{DAY_OF_YEAR})  = @{ $self->{list}->[0] };

  return $self;
}


#********************************************************************
# remaining_time
#  returns
#    -1 = access deny not allow day
#    -2 = access deny not allow hour
#********************************************************************
sub remaining_time {
  my ($self)=shift;
  my ($deposit, 
      $attr) = @_;

  my %ATTR = ();
  my ($session_start,  
      $day_begin,
      $day_of_week,
      $day_of_year
     );

  my $PRICE_UNIT = 3600;
  if ($attr->{PRICE_UNIT}) {
    my %PRICE_UNITS = (
     Hour => 3600,
     Min  => 60
    );
    $PRICE_UNIT = $PRICE_UNITS{$attr->{PRICE_UNIT}} if  (defined($PRICE_UNITS{$attr->{PRICE_UNIT}}));
   }

  if (! defined($attr->{SESSION_START})) {
  	 $self->get_timeinfo();
  	 $session_start = $self->{SESSION_START};
     $day_begin     = $self->{DAY_BEGIN};
     $day_of_week   = $self->{DAY_OF_WEEK};
     $day_of_year   = $self->{DAY_OF_YEAR};
   }
  else {
  	 $session_start = $attr->{SESSION_START};
     $day_begin     = $attr->{DAY_BEGIN};
     $day_of_week   = $attr->{DAY_OF_WEEK};
     $day_of_year   = $attr->{DAY_OF_YEAR};
   }

  my $REDUCTION = (defined($attr->{REDUCTION})) ? $attr->{REDUCTION} : 0;
  $deposit = $deposit + ($deposit * (100 - $REDUCTION) / 100) if ($REDUCTION > 0);

  $time_intervals = $attr->{TIME_INTERVALS} || 0; 
  $periods_time_tarif = $attr->{INTERVAL_TIME_TARIF};
  $periods_traf_tarif = $attr->{INTERVAL_TRAF_TARIF} || undef;

  my $debug = $attr->{debug} || 0;
 
  my $time_limit = (defined($attr->{time_limit})) ? $attr->{time_limit} : 0;
  my $mainh_tarif = (defined($attr->{mainh_tarif})) ? $attr->{mainh_tarif} : 0;
  my $remaining_time = 0;


 if ($time_intervals == 0) {
    return 0, \%ATTR;
  }
 
 my %holidays = ();
 if (defined($time_intervals->{8})) {
   my $tariffs = Tariffs->new($db, $CONF);
   my $list = $tariffs->holidays_list({ format => 'daysofyear' });
   foreach my $line (@$list) {
     $holidays{$line->[0]} = 1;
    }
  }


 my $tarif_day = 0;
 my $count = 0;
 $session_start = $session_start - $day_begin;
 
 #If use post paid service
 while(($deposit > 0 || (defined($attr->{POSTPAID}) && $attr->{POSTPAID}>0 )) && $count < 50) {

   if ($time_limit != 0 && $time_limit < $remaining_time) {
     $remaining_time = $time_limit;
     last;
    }

   if(defined($holidays{$day_of_year}) && defined($time_intervals->{8})) {
    	#print "Holliday tarif '$day_of_year' ";
    	$tarif_day = 8;
    }
   elsif (defined($time_intervals->{$day_of_week})) {
    	#print "Day tarif '$day_of_week'";
    	$tarif_day = $day_of_week;
    }
   elsif(defined($time_intervals->{0})) {
      #print "Global tarif";
      $tarif_day = 0;
    }
   elsif($count > 0) {
      last;
    }
   else {
      return -1, \%ATTR;
    }
  
  print "Count:  $count Remain Time: $remaining_time\n" if ($debug == 1);
  # Time check
  # $session_start
     $count++;
     my $cur_int = $time_intervals->{$tarif_day};
     my $i;
     my $prev_tarif = '';
     
     TIME_INTERVALS:

     #my @intervals = sort keys %$cur_int; 
     my @intervals = sort { $a <=> $b } keys %$cur_int;
     $i = -1;
     
     #Check intervals
     foreach my $int_begin (@intervals) {
       my ($int_id, $int_end) = split(/:/, $cur_int->{$int_begin}, 2);
       $i++;

       my $price         = 0;
       my $traf_price    = 0;
       my $int_prepaid   = 0;
       my $int_duration  = 0;
       my $extended_time = 0;

       #begin > end / Begin: 22:00 => End: 3:00
       if ($int_begin > $int_end) {
       	 if( $session_start < 86400 && $session_start > $int_begin) {
       	   $extended_time = $int_end;
       	   $int_end = 86400;
       	  }
         elsif($session_start < $int_end) {
         	 $int_begin = 0;
          }
        } 

       print "Day: $tarif_day Session_start: $session_start => Int Begin: $int_begin End: $int_end Int ID: $int_id\n" if ($debug == 1);

       if (($int_begin <= $session_start) && ($session_start < $int_end)) {
          $int_duration = $int_end-$session_start;
          print " <<!=\n" if ($debug == 1);    

          # if defined prev_tarif
          if ($prev_tarif ne '') {
            	my ($p_day, $p_begin)=split(/:/, $prev_tarif, 2);
            	$int_end=$p_begin;
            	print "Prev tarif $prev_tarif / INT end: $int_end \n" if ($debug == 1);
           }

          #Time calculations/ Time tariff price
          if ($periods_time_tarif->{$int_id} =~ /%$/) {
             my $tp = $periods_time_tarif->{$int_id};
             $tp =~ s/\%//;
             $price = $mainh_tarif  * ($tp / 100);
           }
          else {
             $price = $periods_time_tarif->{$int_id} || 0;
           }

          if (! $ATTR{FIRST_INTERVAL}) {
          	$ATTR{FIRST_INTERVAL} = $int_id;
          	$ATTR{TIME_PRICE} = $price;
           }
          
          
          #Traf calculation
          if(defined($periods_traf_tarif->{$int_id})
             && $remaining_time == 0 
             && ($attr->{GET_INTERVAL} || ! $CONF->{rt_billing})
             ) {
            $ATTR{TT}=$int_id if (! defined($ATTR{TT}));            
            if ($periods_traf_tarif->{$int_id} > 0) {
              print "This tarif with traffic counts\n" if ($debug == 1);
              if ($int_end - $int_begin < 86400) {
                
                return int($int_duration), \%ATTR 
               }
              #Traffic tarif price
              $traf_price = $periods_traf_tarif->{$int_id};
             }
            if ($price && $price > 0) {
              $int_prepaid = int($deposit / $price * $PRICE_UNIT);
             }
            else {
              $int_prepaid = $int_duration;		
             }
           }
          # Check next traffic interval if the price is same add this interval to session timeout
          elsif(defined($periods_traf_tarif->{$int_id})
             && $periods_traf_tarif->{$int_id} > 0
             && ! $CONF->{rt_billing}
             && (($int_end - $int_begin < 86400) && $periods_traf_tarif->{$int_id} != $traf_price)
             ) {
             print "Next tarif with traffic counts (Remaining: $remaining_time) Day: $tarif_day Int Begin: $int_begin End: $int_end ID: $int_id\n" if ($debug == 1);
             return int($remaining_time), \%ATTR;
           }
          elsif ($price > 0) {
            $int_prepaid = int($deposit / $price * $PRICE_UNIT);
           }
          else {
            $int_prepaid = $int_duration;	
            $ATTR{TT}=$int_id if (! defined($ATTR{TT}) && defined($periods_traf_tarif));
           }

          #print "Int Begin: $int_begin Int duration: $int_duration Int prepaid: $int_prepaid Prise: $price\n";
          if ($int_prepaid >= $int_duration) {
            $deposit -= ($int_duration / $PRICE_UNIT * $price);
            $session_start += $int_duration;
            $remaining_time += $int_duration;
           }
          elsif($int_prepaid <= $int_duration) {
            $deposit =  0;    	
            $session_start += int($int_prepaid);
            $remaining_time += int($int_prepaid);
           }
        }
       elsif($i == $#intervals) {
       	  print "!! LAST@@@@ $i == Interval counts: $#intervals\n" if ($debug > 1);
       	  $prev_tarif = "$tarif_day:$int_begin";

       	  if (defined($time_intervals->{0}) && $tarif_day != 0) {
       	    $tarif_day = 0;
       	    $cur_int   = $time_intervals->{$tarif_day};
       	    print "Go to TIME_INTERVALS\n" if ($debug > 1);
       	    goto TIME_INTERVALS;
       	   }
       	  elsif($session_start < 86400) {
      	  	 if ($remaining_time > 0) {
      	  	   return int($remaining_time), \%ATTR;
      	  	  }
             else {
             	 #print "# Not allow hour $remaining_time";
             	 # return -2;
              }
      	   }
       	  next;
        }
      }

  return -2, \%ATTR if ($remaining_time == 0);

  if ($session_start >= 86400) {
    $session_start=0;
    $day_of_week = ($day_of_week + 1 > 7) ? 1 : $day_of_week+1;
    $day_of_year = ($day_of_year + 1 > 365) ? 1 : $day_of_year + 1;
   }
 }

return int($remaining_time), \%ATTR;
}

#*******************************************************************
# Make session log file
# mk_session_log(\$acct_info)
#*******************************************************************
sub mk_session_log  {
 my $self = shift;
 my ($acct_info) = @_;
 my $filename="$acct_info->{USER_NAME}.$acct_info->{ACCT_SESSION_ID}";

 open(FILE, ">$CONF->{SPOOL_DIR}/$filename") || die "Can't open file '$CONF->{SPOOL_DIR}/$filename' $!";
  while(my($k, $v)=each(%$acct_info)) {
     print FILE "$k:$v\n";
   }
 close(FILE);
}

#**********************************************************
# Extretions formul 
# attr - Atributes
#   PERIOD_TRAFFIC - period traffic summary
#**********************************************************
sub expression {
  my ($self, $UID, $expr, $attr) = @_;

  my $debug = $attr->{debug} || 0;
  my $RESULT;    

  #Expresion section
  if (scalar(keys %{ $expr }) > 0) {
    my $start_period = ($attr->{START_PERIOD} && $attr->{START_PERIOD} ne '0000-00-00') ? "DATE_FORMAT(start, '%Y-%m-%d')>='$attr->{START_PERIOD}'" : "DATE_FORMAT(start, '%Y-%m')>=DATE_FORMAT(curdate(), '%Y-%m')";

    if ($attr->{STOP_PERIOD} && $attr->{STOP_PERIOD} ne '0000-00-00') {
       $start_period .= " AND DATE_FORMAT(start, '%Y-%m-%d')<='$attr->{STOP_PERIOD}'";
     }

    my %ex = ();
    my $counters;
    while(my($id, $expresion_text) = each %{ $expr } ) {
  	  $expresion_text =~ s/\n|[\r]//g;
  	  my @expresions_array = split(/;/, $expresion_text);
 	  
  	  foreach my $expresion (@expresions_array) {
  	    print "ID: $id EXPR: $expresion\n" if ($debug > 0);
  	    my($left, $right)=split(/=/, $expresion);
  	  
  	    if($left =~ /([A-Z0-9_]+)(<|>)([A-Z0-9_0-9\.]+)/) {
    	    $ex{ARGUMENT}  = $1;
    	    $ex{EXPR}      = $2;
  	      $ex{PARAMETER} = $3;
  	      
          #$CONF->{KBYTE_SIZE} = 1;
  	      print "ARGUMENT: $ex{ARGUMENT} EXP: '$ex{EXPR}' PARAMETER: $ex{PARAMETER}\n" if ($debug > 0); 
  	      if ($ex{ARGUMENT} =~ /TRAFFIC/) {
            # for alive session expr price 0
            if ($ex{ARGUMENT} =~ /SESSION/) {
            	if ($attr->{RAD_ALIVE}) {
            	  $RESULT->{PRICE_IN}=0;
            	  $RESULT->{PRICE_OUT}=0;
            	  return $RESULT;
            	 }
            	else {
            	  $self->{PERIOD_TRAFFIC} = $attr->{SESSION_TRAFFIC};
            	 }
             }

            if ($self->{PERIOD_TRAFFIC}) {
            	$counters = $self->{PERIOD_TRAFFIC};
             }
            else {
  	      	  if (! $counters->{TRAFFIC_IN}) {
  	      	    if ($attr->{IPN}) {
  	      	      $counters = $self->get_traffic_ipn({ UID    => $UID,
  	      	  	                                       UIDS   => $attr->{UIDS},
     	                                                 PERIOD => $start_period,
     	                                                 TRAFFIC_CLASS => $attr->{TRAFFIC_CLASS}
   	                                                }); 
  	      	     }	
  	      	    else {	
  	      	      $counters = $self->get_traffic({ UID    => $UID,
  	      	  	                               UIDS   => $attr->{UIDS},
     	                                         PERIOD => $start_period,
   	                                          }); 
                 }
               }
             }

  	      	if ($ex{PARAMETER} !~ /^[0-9\.]+$/) {
  	      		$ex{PARAMETER} = $counters->{$ex{PARAMETER}} || 0;
   	      	 }

            if ( $ex{ARGUMENT} eq 'TRAFFIC_SUM' && ! $counters->{TRAFFIC_SUM}) {
              $counters->{TRAFFIC_SUM}=$counters->{TRAFFIC_IN}+$counters->{TRAFFIC_OUT};
             }

           	$counters->{$ex{ARGUMENT}}=0 if (! $counters->{$ex{ARGUMENT}});

            if($ex{EXPR} eq '<' && $counters->{$ex{ARGUMENT}}  <=  $ex{PARAMETER}) {
             	print "EXPR: $ex{EXPR} RES: $ex{ARGUMENT} RES VAL: $counters->{$ex{ARGUMENT}}\n" if ($debug > 0);
             	$RESULT = get_result($right);
             	$RESULT->{$ex{ARGUMENT}}=$counters->{$ex{ARGUMENT}};
             }
            elsif($ex{EXPR} eq '>' && $counters->{$ex{ARGUMENT}} >=  $ex{PARAMETER}) {
            	print "EXPR: $ex{EXPR} ARGUMENT: $counters->{$ex{ARGUMENT}}\n" if ($debug > 0);
            	$RESULT = get_result($right);
            	$RESULT->{$ex{ARGUMENT}}=$counters->{$ex{ARGUMENT}};
             }
            else {
            	print "No hits!\n" if ($debug > 0);
            	$RESULT->{TRAFFIC_LIMIT}=$ex{PARAMETER};
            	last if ($ex{ARGUMENT} !~ /SESSION/);
             }
  	       }
        }

      }
      $self->{RESULT}{$id}=$RESULT;
    }
  }
	
	return $RESULT;
}

#**********************************************************
# get expresion result
#**********************************************************
sub get_result {
  my ($right, $attr) = @_;

  my %RESULT = ();
  my @right_arr=split(/,/, $right);
  foreach my $line (@right_arr) {
    if ($line =~ /([A-Z0-9_]+):([0-9\.]+)/) {
 	    $RESULT{$1}=$2;
 	   }
	 }

  return \%RESULT;
}


1


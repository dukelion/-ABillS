package Acct;
# Accounting functions
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
use Billing;

@ISA  = ("main");
my ($db, $conf);



my %ACCT_TYPES = ('Start'          => 1,
                  'Stop'           => 2,
                  'Alive'          => 3,
                  'Interim-Update' => 3,
                  'Accounting-On'  => 7,
                  'Accounting-Off' => 8
                  ); 


#**********************************************************
# Init 
#**********************************************************
sub new {
  my $class = shift;
  ($db, $conf) = @_;
  my $self = { };
  bless($self, $class);

  return $self;
}


#**********************************************************
# Accounting Work_
#**********************************************************
sub accounting {
 my $self = shift;
 my ($RAD, $NAS)=@_;
 
 
 $self->{SUM} = 0 if (! $self->{SUM});
 my $acct_status_type = $ACCT_TYPES{$RAD->{ACCT_STATUS_TYPE}};
 my $SESSION_START = (defined($RAD->{SESSION_START}) && $RAD->{SESSION_START} > 0) ?  "FROM_UNIXTIME($RAD->{SESSION_START})" : "FROM_UNIXTIME(UNIX_TIMESTAMP())";

 $RAD->{ACCT_INPUT_GIGAWORDS}  = 0 if (! $RAD->{ACCT_INPUT_GIGAWORDS});
 $RAD->{ACCT_OUTPUT_GIGAWORDS} = 0 if (! $RAD->{ACCT_OUTPUT_GIGAWORDS});
 
 $RAD->{FRAMED_IP_ADDRESS} = '0.0.0.0' if(! defined($RAD->{FRAMED_IP_ADDRESS}));

 if (length($RAD->{ACCT_SESSION_ID}) > 25) {
   $RAD->{ACCT_SESSION_ID} = substr($RAD->{ACCT_SESSION_ID}, 0, 24);
  }



if ($NAS->{NAS_TYPE} eq 'cid_auth') {
  $self->query($db, "select
  u.uid,
  u.id
     FROM users u, dv_main dv
     WHERE dv.uid=u.uid AND dv.CID='$RAD->{CALLING_STATION_ID}';");

   if ($self->{TOTAL} < 1) {
     $RAD->{USER_NAME}=$RAD->{CALLING_STATION_ID};
    }
   else {
   	 $RAD->{USER_NAME}=$self->{list}->[0]->[1];
    } 
 }
#Call back function
elsif ($RAD->{USER_NAME} =~ /(\d+):(\S+)/) {
  $RAD->{USER_NAME}=$2;
  $RAD->{CALLING_STATION_ID}=$1;
}  

#Start
if ($acct_status_type == 1) {
  $self->query($db, "SELECT count(uid) FROM dv_calls 
    WHERE user_name='$RAD->{USER_NAME}' and acct_session_id='$RAD->{ACCT_SESSION_ID}';");
    
  if ($self->{list}->[0]->[0] < 1) {
    #Get TP_ID
    $self->query($db, "SELECT u.uid, dv.tp_id, dv.join_service FROM (users u, dv_main dv)
     WHERE u.uid=dv.uid and u.id='$RAD->{USER_NAME}';");
    if ($self->{TOTAL} > 0) {
      ($self->{UID},
       $self->{TP_ID},
       $self->{JOIN_SERVICE})= @{ $self->{list}->[0] };
       
       if ($self->{JOIN_SERVICE}) {
       	 if ($self->{JOIN_SERVICE} == 1) {
       	 	 $self->{JOIN_SERVICE}=$self->{UID};
       	  }
       	 $self->{TP_ID}='';
        }
     }
    else {
    	$RAD->{USER_NAME}='! '.$RAD->{USER_NAME};
     }
    
    #Get connection speed 
    if ($RAD->{X_ASCEND_DATA_RATE} && $RAD->{X_ASCEND_XMIT_RATE}) {
        $RAD->{CONNECT_INFO}="$RAD->{X_ASCEND_DATA_RATE} / $RAD->{X_ASCEND_XMIT_RATE}";
     }
    elsif ($RAD->{CISCO_SERVICE_INFO}) {
      $RAD->{CONNECT_INFO}="$RAD->{CISCO_SERVICE_INFO}";
     }

    my $sql = "INSERT INTO dv_calls
     (status, user_name, started, lupdated, nas_ip_address, nas_port_id, acct_session_id, framed_ip_address, CID, CONNECT_INFO, nas_id, tp_id,
      uid, join_service)
       values ('$acct_status_type', 
      '$RAD->{USER_NAME}', 
      $SESSION_START, 
      UNIX_TIMESTAMP(), 
      INET_ATON('$RAD->{NAS_IP_ADDRESS}'),
      '$RAD->{NAS_PORT}', 
      '$RAD->{ACCT_SESSION_ID}',
      INET_ATON('$RAD->{FRAMED_IP_ADDRESS}'), 
      '$RAD->{CALLING_STATION_ID}', 
      '$RAD->{CONNECT_INFO}', 
      '$NAS->{NAS_ID}',
      '$self->{TP_ID}', '$self->{UID}',
      '$self->{JOIN_SERVICE}');";
    $self->query($db, "$sql", 'do');

    $self->query($db, "DELETE FROM dv_calls WHERE nas_id='$NAS->{NAS_ID}' AND acct_session_id='IP' AND (framed_ip_address=INET_ATON('$RAD->{FRAMED_IP_ADDRESS}') or UNIX_TIMESTAMP()-UNIX_TIMESTAMP(started) > 120 );", 'do');
  }
 }
# Stop status
elsif ($acct_status_type == 2) {
  my $Billing = Billing->new($db, $conf);	
#IPN Service
  if ( $NAS->{NAS_EXT_ACCT} || $NAS->{NAS_TYPE} eq 'ipcad') {
    $self->query($db, "SELECT 
       dv.acct_input_octets,
       dv.acct_output_octets,
       dv.acct_input_gigawords,
       dv.acct_output_gigawords,
       dv.ex_input_octets,
       dv.ex_output_octets,
       dv.tp_id,
       dv.sum,
       dv.uid,
       u.bill_id,
       u.company_id
    FROM (dv_calls dv, users u)
    WHERE dv.uid=u.uid AND dv.user_name='$RAD->{USER_NAME}' AND dv.acct_session_id='$RAD->{ACCT_SESSION_ID}';");

    if($self->{errno}) {
 	    return $self;
     }
    elsif ($self->{TOTAL} < 1) {
      $self->{errno}=2;
      $self->{errstr}="Session account Not Exist '$RAD->{ACCT_SESSION_ID}'";
      return $self;
     }

    (
     $RAD->{INBYTE},
     $RAD->{OUTBYTE},
     $RAD->{ACCT_INPUT_GIGAWORDS},
     $RAD->{ACCT_OUTPUT_GIGAWORDS},
     $RAD->{INBYTE2},
     $RAD->{OUTBYTE2},
     $self->{TARIF_PLAN},
     $self->{SUM},
     $self->{UID},
     $self->{BILL_ID},
     $self->{COMPANY_ID}
    ) = @{ $self->{list}->[0] };

    if ($self->{COMPANY_ID} > 0) {
       $self->query($db, "SELECT bill_id FROM companies WHERE id='$self->{COMPANY_ID}';");
       if ($self->{TOTAL} < 1) {
         $self->{errno}=2;
         $self->{errstr}="Company not exists '$self->{COMPANY_ID}'";
         return $self;
    	  }
       ($self->{BILL_ID})= @{ $self->{list}->[0] };
     }

    if ($RAD->{INBYTE} > 4294967296) {
    	$RAD->{ACCT_INPUT_GIGAWORDS} = int($RAD->{INBYTE}/4294967296);
    	$RAD->{INBYTE} = $RAD->{INBYTE} - $RAD->{ACCT_INPUT_GIGAWORDS} * 4294967296;
     }

    if ($RAD->{OUTBYTE} > 4294967296) {
    	$RAD->{ACCT_OUTPUT_GIGAWORDS} = int($RAD->{OUTBYTE}/4294967296);
    	$RAD->{OUTBYTE} = $RAD->{OUTBYTE} - $RAD->{ACCT_OUTPUT_GIGAWORDS} * 4294967296;
     }


    if ($self->{UID} > 0 ) {
      $self->query($db, "INSERT INTO dv_log (uid, start, tp_id, duration, sent, recv,  
        sum, nas_id, port_id,
        ip, CID, sent2, recv2, acct_session_id, 
        bill_id,
        terminate_cause,
        acct_input_gigawords,
        acct_output_gigawords) 
        VALUES ('$self->{UID}', FROM_UNIXTIME($RAD->{SESSION_START}), '$self->{TARIF_PLAN}', '$RAD->{ACCT_SESSION_TIME}', 
        '$RAD->{OUTBYTE}', '$RAD->{INBYTE}', '$self->{SUM}', '$NAS->{NAS_ID}',
        '$RAD->{NAS_PORT}', INET_ATON('$RAD->{FRAMED_IP_ADDRESS}'), '$RAD->{CALLING_STATION_ID}',
        '$RAD->{OUTBYTE2}', '$RAD->{INBYTE2}', '$RAD->{ACCT_SESSION_ID}', 
        '$self->{BILL_ID}',
        '$RAD->{ACCT_TERMINATE_CAUSE}',
        '$RAD->{ACCT_INPUT_GIGAWORDS}',
        '$RAD->{ACCT_OUTPUT_GIGAWORDS}');", 'do');
      }
   }
  elsif ($conf->{rt_billing}) {
    $self->rt_billing($RAD, $NAS);

    if (! $self->{errno} ) {
      #return $self;
      $self->query($db, "INSERT INTO dv_log (uid, start, tp_id, duration, sent, recv, kb, sum, nas_id, port_id,
        ip, CID, sent2, recv2, acct_session_id, 
        bill_id,
        terminate_cause,
        acct_input_gigawords,
        acct_output_gigawords) 
        VALUES ('$self->{UID}', FROM_UNIXTIME($RAD->{SESSION_START}), '$self->{TARIF_PLAN}', '$RAD->{ACCT_SESSION_TIME}', 
        '$RAD->{OUTBYTE}', '$RAD->{INBYTE}', '$self->{TRAF_TARIF}', $self->{CALLS_SUM}+$self->{SUM}, '$NAS->{NAS_ID}',
        '$RAD->{NAS_PORT}', INET_ATON('$RAD->{FRAMED_IP_ADDRESS}'), '$RAD->{CALLING_STATION_ID}',
        '$RAD->{OUTBYTE2}', '$RAD->{INBYTE2}',  '$RAD->{ACCT_SESSION_ID}', 
        '$self->{BILL_ID}',
        '$RAD->{ACCT_TERMINATE_CAUSE}',
        '$RAD->{ACCT_INPUT_GIGAWORDS}',
        '$RAD->{ACCT_OUTPUT_GIGAWORDS}');", 'do');
     }      
    else {
      #DEbug only
      if ($conf->{ACCT_DEBUG}) {
        use POSIX qw(strftime);
        my $DATE_TIME = strftime "%Y-%m-%d %H:%M:%S", localtime(time);
        my $r = `echo "$DATE_TIME $self->{UID} - $RAD->{USER_NAME} / $RAD->{ACCT_SESSION_ID} / Time: $RAD->{ACCT_SESSION_TIME} / $self->{errstr}" >> /tmp/unknown_session.log`;
        #DEbug only end
       }

#      return $self;      
     }     
   }
  else {
    my %EXT_ATTR = ();
    
    #Get connected TP
    $self->query($db, "SELECT uid, tp_id, CONNECT_INFO FROM dv_calls
      WHERE
      acct_session_id='$RAD->{ACCT_SESSION_ID}' and nas_id='$NAS->{NAS_ID}';");

    ($EXT_ATTR{UID}, $EXT_ATTR{TP_NUM}, $EXT_ATTR{CONNECT_INFO}) = @{ $self->{list}->[0] } if ($self->{TOTAL} > 0);
  
    ($self->{UID}, 
     $self->{SUM}, 
     $self->{BILL_ID}, 
     $self->{TARIF_PLAN}, 
     $self->{TIME_TARIF}, 
     $self->{TRAF_TARIF}) = $Billing->session_sum("$RAD->{USER_NAME}", 
                                                   $RAD->{SESSION_START}, 
                                                   $RAD->{ACCT_SESSION_TIME}, 
                                                   $RAD, 
                                                   \%EXT_ATTR );
  #  return $self;
    if ($self->{UID} == -2) {
      $self->{errno}  = 1;   
      $self->{errstr} = "ACCT [$RAD->{USER_NAME}] Not exist";
     }
    elsif($self->{UID} == -3) {
      my $filename     = "$RAD->{USER_NAME}.$RAD->{ACCT_SESSION_ID}";
      $RAD->{SQL_ERROR}="$Billing->{errno}:$Billing->{errstr}";
      $self->{errno} = 1;
      $self->{errstr}= "SQL Error ($Billing->{errstr}) SESSION: '$filename'";
      $Billing->mk_session_log($RAD);
      return $self;
     }
    elsif ($self->{SUM} < 0) {
      $self->{LOG_DEBUG} =  "ACCT [$RAD->{USER_NAME}] small session ($RAD->{ACCT_SESSION_TIME}, $RAD->{INBYTE}, $RAD->{OUTBYTE})";
     }
    elsif ($self->{UID} <= 0) {
      $self->{LOG_DEBUG} =  "ACCT [$RAD->{USER_NAME}] small session ($RAD->{ACCT_SESSION_TIME}, $RAD->{INBYTE}, $RAD->{OUTBYTE}), $self->{UID}";
     }
    else {
      $self->query($db, "INSERT INTO dv_log (uid, start, tp_id, duration, sent, recv, kb,  sum, nas_id, port_id,
          ip, CID, sent2, recv2, acct_session_id, 
          bill_id,
          terminate_cause,
          acct_input_gigawords,
          acct_output_gigawords ) 
          VALUES ('$self->{UID}', FROM_UNIXTIME($RAD->{SESSION_START}), '$self->{TARIF_PLAN}', '$RAD->{ACCT_SESSION_TIME}', 
          '$RAD->{OUTBYTE}', '$RAD->{INBYTE}', '$self->{TRAF_TARIF}', '$self->{SUM}', '$NAS->{NAS_ID}',
          '$RAD->{NAS_PORT}', INET_ATON('$RAD->{FRAMED_IP_ADDRESS}'), '$RAD->{CALLING_STATION_ID}',
          '$RAD->{OUTBYTE2}', '$RAD->{INBYTE2}',  '$RAD->{ACCT_SESSION_ID}', 
          '$self->{BILL_ID}',
          '$RAD->{ACCT_TERMINATE_CAUSE}',
          '$RAD->{ACCT_INPUT_GIGAWORDS}',
          '$RAD->{ACCT_OUTPUT_GIGAWORDS}');", 'do');
 
      if ($self->{errno}) {
        my $filename = "$RAD->{USER_NAME}.$RAD->{ACCT_SESSION_ID}";
        $self->{LOG_WARNING}="ACCT [$RAD->{USER_NAME}] Making accounting file '$filename'";
        $Billing->mk_session_log($RAD);
       }
  # If SQL query filed
      else {
        if ($self->{SUM} > 0) {
          $self->query($db, "UPDATE bills SET deposit=deposit-$self->{SUM} WHERE id='$self->{BILL_ID}';", 'do');
         }
       }
    }
}

  # Delete from session
  $self->query($db, "DELETE FROM dv_calls WHERE acct_session_id='$RAD->{ACCT_SESSION_ID}' and nas_id='$NAS->{NAS_ID}';", 'do');
 }
#Alive status 3
elsif($acct_status_type eq 3) {
  $self->{SUM}=0 if (! $self->{SUM}); 
  if ($NAS->{NAS_EXT_ACCT}) {
    my $ipn_fields='';
  	if ($NAS->{IPN_COLLECTOR}) {
  	  $ipn_fields="sum=sum+$self->{SUM},
      acct_input_octets='$RAD->{INBYTE}',
      acct_output_octets='$RAD->{OUTBYTE}',
      ex_input_octets=ex_input_octets + $RAD->{INBYTE2},
      ex_output_octets=ex_output_octets + $RAD->{OUTBYTE2},
      acct_input_gigawords='$RAD->{ACCT_INPUT_GIGAWORDS}',
      acct_output_gigawords='$RAD->{ACCT_OUTPUT_GIGAWORDS}',";
     }

    $self->query($db, "UPDATE dv_calls SET
      $ipn_fields
      status='$acct_status_type',
      acct_session_time=UNIX_TIMESTAMP()-UNIX_TIMESTAMP(started),
      framed_ip_address=INET_ATON('$RAD->{FRAMED_IP_ADDRESS}'),
      lupdated=UNIX_TIMESTAMP()
    WHERE
      acct_session_id='$RAD->{ACCT_SESSION_ID}' and 
      user_name='$RAD->{USER_NAME}' and
      nas_id='$NAS->{NAS_ID}';", 'do');
  	return $self;
   }
  elsif ($NAS->{NAS_TYPE} eq 'ipcad') {
    return $self;
   }
  elsif ($conf->{rt_billing}) {
    $self->rt_billing($RAD, $NAS);
   }
   
  my $ex_octets = '';
  if ($RAD->{INBYTE2} || $RAD->{OUTBYTE2}) {
    $ex_octets = "ex_input_octets='$RAD->{INBYTE2}',  ex_output_octets='$RAD->{OUTBYTE2}', ";
   }
 
  $self->query($db, "UPDATE dv_calls SET
    status='$acct_status_type',
    acct_session_time=UNIX_TIMESTAMP()-UNIX_TIMESTAMP(started),
    acct_input_octets='$RAD->{INBYTE}',
    acct_output_octets='$RAD->{OUTBYTE}',
    $ex_octets
    framed_ip_address=INET_ATON('$RAD->{FRAMED_IP_ADDRESS}'),
    lupdated=UNIX_TIMESTAMP(),
    sum=sum+$self->{SUM},
    acct_input_gigawords='$RAD->{ACCT_INPUT_GIGAWORDS}',
    acct_output_gigawords='$RAD->{ACCT_OUTPUT_GIGAWORDS}'
   WHERE
    acct_session_id='$RAD->{ACCT_SESSION_ID}' and 
    user_name='$RAD->{USER_NAME}' and
    nas_id='$NAS->{NAS_ID}';", 'do');
 }
else {
  $self->{errno}=1;
  $self->{errstr}="ACCT [$RAD->{USER_NAME}] Unknown accounting status: $RAD->{ACCT_STATUS_TYPE} ($RAD->{ACCT_SESSION_ID})";
}

  if ($self->{errno}) {
  	$self->{errno}=1;
  	$self->{errstr}="ACCT $RAD->{ACCT_STATUS_TYPE} SQL Error";
  	return $self;
   }

#detalization for Exppp
if ($conf->{s_detalization}) {
  my $INBYTES = $RAD->{INBYTE} + (($RAD->{ACCT_INPUT_GIGAWORDS}) ? $RAD->{ACCT_INPUT_GIGAWORDS} * 4294967296 : 0);
  my $OUTBYTES = $RAD->{OUTBYTE} + (($RAD->{ACCT_OUTPUT_GIGAWORDS}) ? $RAD->{ACCT_OUTPUT_GIGAWORDS} * 4294967296 : 0);
  $RAD->{INTERIUM_INBYTE2} = $RAD->{INBYTE2}  || 0;
  $RAD->{INTERIUM_OUTBYTE2}= $RAD->{OUTBYTE2} || 0;

  $self->query($db, "INSERT into s_detail (acct_session_id, nas_id, acct_status, last_update, sent1, recv1, sent2, recv2, id, sum)
   VALUES ('$RAD->{ACCT_SESSION_ID}', '$NAS->{NAS_ID}',
    '$acct_status_type', UNIX_TIMESTAMP(),
    '$INBYTES', '$OUTBYTES',
    '$RAD->{INTERIUM_INBYTE2}', '$RAD->{INTERIUM_OUTBYTE2}',
    '$RAD->{USER_NAME}', '$self->{SUM}');", 'do');

}

 return $self;
}


#**********************************************************
# Alive accounting
#**********************************************************
sub rt_billing {
	my $self = shift;
  my ($RAD, $NAS)=@_;

  $self->query($db, "SELECT lupdated, UNIX_TIMESTAMP()-lupdated, 
   if($RAD->{INBYTE}   >= acct_input_octets AND $RAD->{ACCT_INPUT_GIGAWORDS}=acct_input_gigawords, 
        $RAD->{INBYTE} - acct_input_octets, 
        4294967296-acct_input_octets+4294967296*($RAD->{ACCT_INPUT_GIGAWORDS}-acct_input_gigawords-1)+$RAD->{INBYTE}),
   if($RAD->{OUTBYTE}  >= acct_output_octets AND $RAD->{ACCT_OUTPUT_GIGAWORDS}=acct_output_gigawords, 
        $RAD->{OUTBYTE}  - acct_output_octets,
        4294967296-acct_output_octets+4294967296*($RAD->{ACCT_OUTPUT_GIGAWORDS}-acct_output_gigawords-1)+$RAD->{OUTBYTE}),
   if($RAD->{INBYTE2}  >= ex_input_octets, $RAD->{INBYTE2}  - ex_input_octets, ex_input_octets),
   if($RAD->{OUTBYTE2} >= ex_output_octets, $RAD->{OUTBYTE2} - ex_output_octets, ex_output_octets),
   sum,
   tp_id,
   uid
   FROM dv_calls 
  WHERE nas_id='$NAS->{NAS_ID}' and acct_session_id='$RAD->{ACCT_SESSION_ID}';");

  if($self->{errno}) {
 	  return $self;
   }
  elsif ($self->{TOTAL} < 1) {
    $self->{errno}=2;
    $self->{errstr}="Session account rt Not Exist '$RAD->{ACCT_SESSION_ID}'";
    return $self;
   }

  ($RAD->{INTERIUM_SESSION_START},
   $RAD->{INTERIUM_ACCT_SESSION_TIME},
   $RAD->{INTERIUM_INBYTE},
   $RAD->{INTERIUM_OUTBYTE},
   $RAD->{INTERIUM_INBYTE1},
   $RAD->{INTERIUM_OUTBYTE1},
   $self->{CALLS_SUM},
   $self->{TP_NUM},
   $self->{UID}
   ) = @{ $self->{list}->[0] };
  
  my $Billing = Billing->new($db, $conf);	

#print "INterim:   $RAD->{INTERIUM_INBYTE},   $RAD->{INTERIUM_OUTBYTE}, \n";

  ($self->{UID}, 
   $self->{SUM}, 
   $self->{BILL_ID}, 
   $self->{TARIF_PLAN}, 
   $self->{TIME_TARIF}, 
   $self->{TRAF_TARIF}) = $Billing->session_sum("$RAD->{USER_NAME}", 
                                                $RAD->{INTERIUM_SESSION_START}, 
                                                $RAD->{INTERIUM_ACCT_SESSION_TIME}, 
                                                {  
                                                	 OUTBYTE  => ($RAD->{OUTBYTE}  + $RAD->{ACCT_OUTPUT_GIGAWORDS} * 4294967296) - $RAD->{INTERIUM_OUTBYTE},
                                                   INBYTE   => ($RAD->{INBYTE}   + $RAD->{ACCT_INPUT_GIGAWORDS} * 4294967296) - $RAD->{INTERIUM_INBYTE},
                                                   OUTBYTE2 => $RAD->{OUTBYTE2} - $RAD->{INTERIUM_OUTBYTE1},
                                                   INBYTE2  => $RAD->{INBYTE2}  - $RAD->{INTERIUM_INBYTE1},

                                                	 #OUTBYTE  => $RAD->{INTERIUM_OUTBYTE},
                                                   #INBYTE   => $RAD->{INTERIUM_INBYTE},
                                                   #OUTBYTE2 => $RAD->{INTERIUM_OUTBYTE1},
                                                   #INBYTE2  => $RAD->{INTERIUM_INBYTE1},

                                                	 INTERIUM_OUTBYTE  => $RAD->{INTERIUM_OUTBYTE},
                                                   INTERIUM_INBYTE   => $RAD->{INTERIUM_INBYTE},
                                                   INTERIUM_OUTBYTE1 => $RAD->{INTERIUM_INBYTE1},
                                                   INTERIUM_INBYTE1  => $RAD->{INTERIUM_OUTBYTE1},
                                                	},
                                                { FULL_COUNT => 1,
                                                  TP_NUM     => $self->{TP_NUM},
                                                  UID        => ($self->{TP_NUM}) ? $self->{UID} : undef,
                                                  DOMAIN_ID  => ($NAS->{DOMAIN_ID}) ? $NAS->{DOMAIN_ID} : 0,
                                                	  }
                                                );


#  my $a = `date >> /tmp/echoccc;
#   echo "
#   UID: $self->{UID}, 
#   SUM: $self->{SUM} / $self->{CALLS_SUM}, 
#   BILL_ID: $self->{BILL_ID}, 
#   TP: $self->{TARIF_PLAN}, 
#   TIME_TARRIF: $self->{TIME_TARIF}, 
#   TRAFF_TARRIF: $self->{TRAF_TARIF},
#   TIME INTERVAL ID: $Billing->{TI_ID}
#   
#   DURATION: $RAD->{INTERIUM_ACCT_SESSION_TIME},
#   IN: $RAD->{INTERIUM_INBYTE},
#   OUT: $RAD->{INTERIUM_OUTBYTE},
#   IN2: $RAD->{INTERIUM_INBYTE1},
#   OUT2: $RAD->{INTERIUM_OUTBYTE1}
#   \n" >> /tmp/echoccc`;

   $self->query($db, "SELECT traffic_type FROM dv_log_intervals 
     WHERE acct_session_id='$RAD->{ACCT_SESSION_ID}' 
           and interval_id='$Billing->{TI_ID}';"  );

   my %intrval_traffic = ();
   foreach my $line (@{ $self->{list} }) {
   	 $intrval_traffic{$line->[0]}=1;
    }

   my @RAD_TRAFF_SUFIX = ('', '1');
   $self->{SUM} = 0 if ($self->{SUM} < 0);
   
   for(my $traffic_type = 0; $traffic_type <= $#RAD_TRAFF_SUFIX; $traffic_type++) {
     next if ($RAD->{'INTERIUM_OUTBYTE'.$RAD_TRAFF_SUFIX[$traffic_type]} + $RAD->{'INTERIUM_INBYTE'.$RAD_TRAFF_SUFIX[$traffic_type]} < 1);

     if ($intrval_traffic{$traffic_type}) {
       $self->query($db, "UPDATE dv_log_intervals SET  
                               sent=sent+'". $RAD->{'INTERIUM_OUTBYTE'. $RAD_TRAFF_SUFIX[$traffic_type]} ."', 
                               recv=recv+'". $RAD->{'INTERIUM_INBYTE'. $RAD_TRAFF_SUFIX[$traffic_type]} ."', 
                               duration=duration+'$RAD->{INTERIUM_ACCT_SESSION_TIME}', 
                               sum=sum+'$self->{SUM}'
                         WHERE interval_id='$Billing->{TI_ID}' and acct_session_id='$RAD->{ACCT_SESSION_ID}' and traffic_type='$traffic_type';", 'do');
      }
     else {
       $self->query($db, "INSERT INTO dv_log_intervals (interval_id, sent, recv, duration, traffic_type, sum, acct_session_id)
        values ('$Billing->{TI_ID}', 
          '". $RAD->{'INTERIUM_OUTBYTE'. $RAD_TRAFF_SUFIX[$traffic_type]} ."', 
          '". $RAD->{'INTERIUM_INBYTE'. $RAD_TRAFF_SUFIX[$traffic_type]} ."', 
        '$RAD->{INTERIUM_ACCT_SESSION_TIME}', '$traffic_type', '$self->{SUM}', '$RAD->{ACCT_SESSION_ID}');", 'do');
      }
    }
 
#  return $self;
  if ($self->{UID} == -2) {
    $self->{errno}  = 1;   
    $self->{errstr} = "ACCT [$RAD->{USER_NAME}] Not exist";
   }
  elsif($self->{UID} == -3) {
    my $filename   = "$RAD->{USER_NAME}.$RAD->{ACCT_SESSION_ID}";
    $self->{errno} = 1;
    $self->{errstr}= "ACCT [$RAD->{USER_NAME}] Not allow start period '$filename'";
    $Billing->mk_session_log($RAD);
   }
  elsif ($self->{UID} == -5) {
    $self->{LOG_DEBUG} =  "ACCT [$RAD->{USER_NAME}] Can't find TP: $self->{TP_NUM} Session id: $RAD->{ACCT_SESSION_ID}";
    $self->{errno} = 1;
    print "ACCT [$RAD->{USER_NAME}] Can't find TP: $self->{TP_NUM} Session id: $RAD->{ACCT_SESSION_ID}\n";
   }
  elsif ($self->{SUM} < 0) {
    $self->{LOG_DEBUG} =  "ACCT [$RAD->{USER_NAME}] small session ($RAD->{ACCT_SESSION_TIME}, $RAD->{INBYTE}, $RAD->{OUTBYTE})";
   }
  elsif ($self->{UID} <= 0) {
    $self->{LOG_DEBUG} =  "ACCT [$RAD->{USER_NAME}] small session ($RAD->{ACCT_SESSION_TIME}, $RAD->{INBYTE}, $RAD->{OUTBYTE}), $self->{UID}";
    $self->{errno} = 1;
    #print "ACCT [$RAD->{USER_NAME}] /$RAD->{ACCT_STATUS_TYPE}/ small session ($RAD->{ACCT_SESSION_TIME}, $RAD->{INBYTE}, $RAD->{OUTBYTE}), ! $self->{UID}\n";
   }
  else {
    if ($self->{SUM} > 0) {
      $self->query($db, "UPDATE bills SET deposit=deposit-$self->{SUM} WHERE id='$self->{BILL_ID}';", 'do');
     }
   }
}

1

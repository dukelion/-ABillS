package Cisco_isg;
# Cisco_isg AAA functions
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


#**********************************************************
# Init 
#**********************************************************
sub new {
  my $class = shift;
  ($db, $conf) = @_;
  my $self = { };
  bless($self, $class);

  #$self->{debug}=1;
  my $Auth = Auth->new($db, $conf);
  $Billing = Billing->new($db, $conf);	

  return $self;
}

#**********************************************************
# user_info
#**********************************************************
sub user_info {
  my $self = shift;
  my ($RAD, $NAS) = @_;

  my $WHERE = " and dv.CID='$RAD->{USER_NAME}'";

  $self->query($db, "SELECT 
   u.id,
   dv.uid, 
   dv.tp_id, 
   INET_NTOA(dv.ip),
   dv.logins,
   dv.speed,
   dv.disable,
   u.disable,
   u.reduction,
   u.bill_id,
   u.company_id,
   u.credit,
   u.activate,
  UNIX_TIMESTAMP(),
  UNIX_TIMESTAMP(DATE_FORMAT(FROM_UNIXTIME(UNIX_TIMESTAMP()), '%Y-%m-%d')),
  DAYOFWEEK(FROM_UNIXTIME(UNIX_TIMESTAMP())),
  DAYOFYEAR(FROM_UNIXTIME(UNIX_TIMESTAMP()))

   FROM dv_main dv, 
        users u
   WHERE 
    u.uid=dv.uid
   $WHERE;");

  if ($self->{TOTAL} < 1) {
     return $self;
   }

  ($self->{USER_NAME},
   $self->{UID},
   $self->{TP_ID}, 
   $self->{IP},
   $self->{SIMULTANEOUSLY},
   $self->{SPEED},
   $self->{DV_DISABLE},
   $self->{USER_DISABLE},
   $self->{REDUCTION},
   $self->{BILL_ID},
   $self->{COMPANY_ID},
   $self->{CREDIT},
   $self->{ACCOUNT_ACTIVATE},

   $self->{SESSION_START}, 
   $self->{DAY_BEGIN}, 
   $self->{DAY_OF_WEEK}, 
   $self->{DAY_OF_YEAR}

  )= @{ $self->{list}->[0] };
  
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
sub auth {
  my $self = shift;
  my ($RAD, $NAS) = @_;


#Make TP
  if ($RAD->{USER_NAME} =~ /^TT_/) {
  	return  $self->make_tp($RAD);
 	 }

  %RAD_PAIRS=();
  $self->user_info($RAD, $NAS);

  if($self->{errno}) {
    $RAD_PAIRS{'Reply-Message'}=$self->{errstr};
    return 1, \%RAD_PAIRS;
   }
  elsif ($self->{TOTAL} < 1) {
    $self->{errno} = 2;
    $self->{errstr} = 'ERROR_NOT_EXIST';
    $RAD_PAIRS{'Reply-Message'}="User Not Exist '$RAD->{USER_NAME}'";
    return 1, \%RAD_PAIRS;
   }

  $RAD_PAIRS{'User-Name'}=$self->{USER_NAME};
  $RAD->{USER_NAME}=$self->{USER_NAME};

#DIsable
if ($self->{DISABLE} ||  $self->{DV_DISABLE} || $self->{USER_DISABLE}) {
  $RAD_PAIRS{'Reply-Message'}="Account Disable";
  return 1, \%RAD_PAIRS;
}


$self->{PAYMENT_TYPE} = 1;
if ($self->{PAYMENT_TYPE} == 0) {
  $self->{DEPOSIT}=$self->{DEPOSIT}+$self->{CREDIT}; #-$self->{CREDIT_TRESSHOLD};
  #Check deposit
  if($self->{DEPOSIT}  <= 0) {
    $RAD_PAIRS{'Reply-Message'}="Negativ deposit '$self->{DEPOSIT}'. Rejected!";
    return 1, \%RAD_PAIRS;
   }
}
else {
  $self->{DEPOSIT}=0;
}

  my $debug = 0;
  my @RAD_PAIRS_ARR = ();
  #DEFAULT Auth-Type = Accept
  #cisco-avpair = "subscriber:accounting-list=BH_ACCNT_LIST1",
  #Cisco-Account-Info = "ABasic_Internet_Service",
  #Cisco-Account-Info += "NSERVICE_406_BOD1M",
  #Cisco-Account-Info += "NSERVICE_406_VPN_1001c",
  #Exec-Program-Wait = "/usr/abills/libexec/rauth.pl",
  #Idle-Timeout = 1800

  #Speeds


  #$RAD_PAIRS{'Cisco-Account-Info'} = "ABasic_Internet_Service";
  #$RAD_PAIRS{'Cisco-Account-Info'} = "NSERVICE_406_BOD1M";
  my $service = 'Basic_Internet_Service'; # "TT_$self->{TP_ID}";
  
  push @RAD_PAIRS_ARR, "Cisco-Account-Info = \"A$service\"";
  push @RAD_PAIRS_ARR, "Cisco-Account-Info += \"NSERVICE_406_BOD1M\"";
  
  $RAD_PAIRS{'cisco-avpair'} = "subscriber:accounting-list=BH_ACCNT_LIST1";
  $RAD_PAIRS{'Idle-Timeout'} = 1800;

  print join(",\n", @RAD_PAIRS_ARR);
  print ",\n";

  return 0, \%RAD_PAIRS;
}




#**********************************************************
#
# Make TP RAD pairs
#**********************************************************
sub make_tp {
  my $self = shift;
  my ($RAD, $NAS) = @_;

  my %speeds = ();
  my %expr   = ();
  my %names  = ();
  my $TP_ID  = 0;

  if ($RAD->{USER_NAME} =~ /TT_(\d+)/) {
  	$TP_ID = $1;
   }
#
#  if ($self->{SPEED} > 0) {
#    $speeds{0}{IN}=int($self->{SPEED});
#    $speeds{0}{OUT}=int($self->{SPEED});
#   }
#  else {
#
#    ($self->{TIME_INTERVALS},
#     $self->{INTERVAL_TIME_TARIF}, 
#     $self->{INTERVAL_TRAF_TARIF}) = $Billing->time_intervals($TP_ID);
#
#    my ($remaining_time, $ret_attr) = $Billing->remaining_time($self->{DEPOSIT}, {
#    	    TIME_INTERVALS      => $self->{TIME_INTERVALS},
#          INTERVAL_TIME_TARIF => $self->{INTERVAL_TIME_TARIF},
#          INTERVAL_TRAF_TARIF => $self->{INTERVAL_TRAF_TARIF},
#          SESSION_START       => $self->{SESSION_START},
#          DAY_BEGIN           => $self->{DAY_BEGIN},
#          DAY_OF_WEEK         => $self->{DAY_OF_WEEK},
#          DAY_OF_YEAR         => $self->{DAY_OF_YEAR},
#          REDUCTION           => $self->{REDUCTION},
#          POSTPAID            => 1,
#          GET_INTERVAL        => 1
##          debug               => ($debug > 0) ? 1 : undef
#         });
#
##    print "RT: $remaining_time\n"  if ($debug == 1);
#    my %TT_IDS = %$ret_attr;
#
#
#    if (keys %TT_IDS > 0) {
#    	
#      require Tariffs;
#      Tariffs->import();
#      my $tariffs = Tariffs->new($db, $conf, undef);
#
#      #Get intervals
#      while(my($k, $v)=each( %TT_IDS)) {
#        print "> $k, $v\n" if ($debug > 0);
# 	      next if ($k ne 'TT');
# 	      my $list = $tariffs->tt_list({ TI_ID => $v });
# 	      foreach my $line (@$list)  {
# 	    	  $speeds{$line->[0]}{IN}="$line->[4]";
# 	    	  $speeds{$line->[0]}{OUT}="$line->[5]";
# 	    	  $names{$line->[0]}= ($line->[6]) ? "$line->[6]" : "Service_$line->[0]";
# 	    	  $expr{$line->[0]}="$line->[8]" if (length($line->[8]) > 5);
# 	    	  #print "$line->[0] $line->[6] $line->[4]\n";
# 	      }
#      }
#    }
#  
#   }
#
#
#  
#print "Expresion:================================\n" if ($debug > 0);
#  my $RESULT = $Billing->expression($self->{UID}, \%expr, { START_PERIOD => $self->{ACCOUNT_ACTIVATE}, 
#  	                                                      debug        => $debug } );
#print "\nEND: =====================================\n" if ($debug > 0);
#  
#  if (! $RESULT->{SPEED}) {
#    $speeds{0}{IN}=$RESULT->{SPEED_IN} if($RESULT->{SPEED_IN});
#    $speeds{0}{OUT}=$RESULT->{SPEED_OUT} if($RESULT->{SPEED_OUT});
#   }
#  else {
#  	$speeds{0}{IN}=$RESULT->{SPEED};
#  	$speeds{0}{OUT}=$RESULT->{SPEED};
#   }
#
#  
#  #Make speed
#  foreach my $traf_type (sort keys %speeds) {
#    my $speed = $speeds{$traf_type};
#    
#    my $speed_in  = (defined($speed->{IN}))  ? $speed->{IN}  : 0;
#    my $speed_out = (defined($speed->{OUT})) ? $speed->{OUT} : 0;
#
#    $RAD_PAIRS{'Cisco-Account-Info'} = "$names{$traf_type}";
#    $RAD_PAIRS{'Cisco-Service-Info'} = "$names{$traf_type}";
#    
#    
#    my $speed_in_rule = '';
#    my $speed_out_rule = '';
#    if ($speed_in > 0) {
#    	$speed_in_rule = "D;" . ($speed_in * 1000) .";". 
#      ( $speed_in / 8 * 1000 ).';'.
#      ( $speed_in / 4 * 1000 ).';';
#     }
#
#    if ($speed_out > 0) {
#    	$speed_out_rule = "U;". ($speed_out * 1000 ) .";". 
#      ( $speed_out / 8 * 1000 ).';'.
#      ( $speed_out / 4 * 1000 );
#     }
#
#    
#    if ($speed_in_rule ne '' || $speed_out_rule ne '') {
#      $RAD_PAIRS{'Cisco-Service-Info'} = "\"".$RAD_PAIRS{'Cisco-Service-Info'} .",Q$speed_out_rule;$speed_in_rule\"";
#     }
#
#  }
	
	return 0, \%RAD_PAIRS;
}


1

package Auth_mac;
# Cisco_isg AAA functions
# http://www.cisco.com/en/US/docs/ios/12_2sb/isg/coa/guide/isgcoa4.html

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION
);

use Exporter;
$VERSION = 2.11;
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

  my $Auth = Auth->new($db, $conf);
  $Billing = Billing->new($db, $conf);	

  return $self;
}

#**********************************************************
# 
#**********************************************************
sub user_info {
  my $self = shift;
  my ($RAD, $NAS) = @_;

  my $WHERE = '';
  my $EXT_TABLES = '';
  
  if ($conf->{AUTH_MAC_DHCP}) {
  	if ($RAD->{CALLING_STATION_ID} && $RAD->{CALLING_STATION_ID} =~ /([A-Fa-f0-9]{2})([A-Fa-f0-9]{2})\.([A-Fa-f0-9]{2})([A-Fa-f0-9]{2})\.([A-Fa-f0-9]{2})([A-Fa-f0-9]{2})/) {
  		$RAD->{CALLING_STATION_ID} = "$1:$2:$3:$4:$5:$6";
  	 }
    elsif ($RAD->{USER_NAME} =~ /([a-f0-9]{2})([a-f0-9]{2})([a-f0-9]{2})([a-f0-9]{2})([a-f0-9]{2})([a-f0-9]{2})/i) {
      $RAD->{CALLING_STATION_ID} = "$1:$2:$3:$4:$5:$6";
     }
  	else { 
  		$RAD->{CALLING_STATION_ID} =~ s/\-/:/g;
  	 }

    $WHERE = " and dhcp.mac='$RAD->{CALLING_STATION_ID}'";	
    $EXT_TABLES = "INNER JOIN dhcphosts_hosts dhcp ON (dhcp.uid=u.uid)";
   }
  else {
    $WHERE = " and dv.CID='$RAD->{CALLING_STATION_ID}'";
   }

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
  DAYOFYEAR(FROM_UNIXTIME(UNIX_TIMESTAMP())),

  tp.payment_type,
  tp.neg_deposit_filter_id,
  tp.credit,
  tp.credit_tresshold,
  tp.rad_pairs

   FROM (dv_main dv, users u)
   $EXT_TABLES
   LEFT JOIN tarif_plans tp ON  (dv.tp_id=tp.id)
   WHERE 
    u.uid=dv.uid
   $WHERE;");

	if($self->{TOTAL} < 1) {
  	return $self;
   }
	elsif($self->{errno}) {
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
   $self->{DAY_OF_YEAR},

   $self->{PAYMENT_TYPE},
   $self->{NEG_DEPOSIT_FILTER_ID},
   $self->{TP_CREDIT},
   $self->{CREDIT_TRESSHOLD},
   $self->{TP_RAD_PAIRS}

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

  $self->user_info($RAD, $NAS);

  if($self->{errno}) {
    $RAD_PAIRS{'Reply-Message'}=$self->{errstr};
    return 1, \%RAD_PAIRS;
   }
  elsif ($self->{TOTAL} < 1) {
    $self->{errno} = 2;
    $self->{errstr} = 'ERROR_NOT_EXIST';
    
    #Make guest vlan for unknown users
    if ($conf->{AUTH_MAC_GUEST_VID}) {
    	$RAD_PAIRS{'Tunnel-Type'}='VLAN';
    	$RAD_PAIRS{'Tunnel-Private-Group-Id'}="$conf->{AUTH_MAC_GUEST_VID}";
    	$RAD_PAIRS{'Tunnel-Medium-Type'}='IEEE-802';
    	return 0, \%RAD_PAIRS;
     }
    else {
      $RAD_PAIRS{'Reply-Message'}="User Not Exist '$RAD->{CALLING_STATION_ID}'";
      return 1, \%RAD_PAIRS;
     }
   }
  elsif (! defined($self->{PAYMENT_TYPE})) {
    $RAD_PAIRS{'Reply-Message'}="Service not allow";
    return 1, \%RAD_PAIRS;
   }

  #$RAD_PAIRS{'User-Name'}=$self->{USER_NAME};
  $RAD->{USER_NAME}=$self->{USER_NAME};

#DIsable
if ($self->{DISABLE} ||  $self->{DV_DISABLE} || $self->{USER_DISABLE}) {
  $RAD_PAIRS{'Reply-Message'}="Account Disable";
  return 1, \%RAD_PAIRS;
}

my $service = "TP_$self->{TP_ID}"; 
#$self->{PAYMENT_TYPE} = 1;
if ($self->{PAYMENT_TYPE} == 0) {
  $self->{CREDIT} = $self->{TP_CREDIT} if ($self->{CREDIT} == 0);

  $self->{DEPOSIT}=$self->{DEPOSIT}+$self->{CREDIT} - $self->{CREDIT_TRESSHOLD};
  #Check deposit

  if($self->{DEPOSIT}  <= 0) {
  	if (! $self->{NEG_DEPOSIT_FILTER_ID}) {
      $RAD_PAIRS{'Reply-Message'}="Negativ deposit '$self->{DEPOSIT}'. Rejected!";
      return 1, \%RAD_PAIRS;
     }
    return $self->neg_deposit_filter_former($self->{NEG_DEPOSIT_FILTER_ID});
   }
}
else {
  $self->{DEPOSIT}=0;
}





  if ($self->{TP_RAD_PAIRS}) {
    my @p = split(/,/, $self->{TP_RAD_PAIRS});
    foreach my $line (@p) {
    	$line =~ s/\n//g;
      if ($line =~ /([a-zA-Z0-9\-]{6,25})\+\=(.{1,200})/gi) {
        my $left = $1;
        my $right= $2;
        #$right =~ s/\"//g;
        push @{ $RAD_PAIRS{"$left"} }, $right; 
       }      
      else {
         my($left, $right)=split(/=/, $line, 2);
         $left =~ s/^ //g;
         if ($left =~ s/^!//) {
           delete $RAD_PAIRS{"$left"};
   	      }
   	     else {
   	       $RAD_PAIRS{"$left"}="$right";
   	      }
       }
     }
   }

  return 0, \%RAD_PAIRS;
}



#*******************************************************************
# Authorization module
# pre_auth()
#*******************************************************************
sub pre_auth {
  my ($self, $RAD, $attr)=@_;


if ($attr->{NAS_TYPE} eq 'mac_auth') {
   my $password = $RAD->{USER_NAME};

   if ($CONF->{RADIUS2}) {
       print "Cleartext-Password := \"$password\";";
       $self->{'RAD_CHECK'}{'Cleartext-Password'}="$password";
     }
    else {
       print "User-Password == \"$password\";";
       $self->{'RAD_CHECK'}{'User-Password'}="$password";
     }
 }
elsif ($RAD->{MS_CHAP_CHALLENGE} || $RAD->{EAP_MESSAGE}) {
  my $login = $RAD->{USER_NAME} || '';
  if ($login =~ /:(.+)/) {
    $login = $1;	 
  }

  $self->query($db, "SELECT DECODE(password, '$CONF->{secretkey}') FROM users WHERE id='$login';");
  if ($self->{TOTAL} > 0) {
  	my $list = $self->{list}->[0];
    my $password = $list->[0];
    
    if ($CONF->{RADIUS2}) {
       print "Cleartext-Password := \"$password\";\n";
       $self->{'RAD_CHECK'}{'Cleartext-Password'}="$password";
     }
    else {
       print "User-Password == \"$password\";\n";
       $self->{'RAD_CHECK'}{'User-Password'}="$password";
     }
    return 0;
   }

  $self->{errno} = 1;
  $self->{errstr} = "USER: '$login' not exist";
  return 1;
 }
  
  $self->{'RAD_CHECK'}{'Auth-Type'}="Accept-";

  print "Auth-Type := Accept\n";
  return 0;
}


1

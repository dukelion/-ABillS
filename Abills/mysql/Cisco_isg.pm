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
   dv.disable,
   u.disable,
   u.reduction,
   u.bill_id,
   u.company_id,
   u.credit,
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
   $self->{DV_DISABLE},
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

#DIsable
if ($self->{DISABLE} ||  $self->{DV_DISABLE} || $self->{USER_DISABLE}) {
  $RAD_PAIRS{'Reply-Message'}="Account Disable";
  return 1, \%RAD_PAIRS;
}

$self->{PAYMENT_TYPE}=0;
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

  
  return 0, \%RAD_PAIRS;
}






1

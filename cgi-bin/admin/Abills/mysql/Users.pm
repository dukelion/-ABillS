package Users;
# Administrators manage functions
#

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION
);

use Exporter;
$VERSION = 2.00;
@ISA = ('Exporter');

@EXPORT = qw(
);

@EXPORT_OK = ();
%EXPORT_TAGS = ();

# User name expration
my $usernameregexp = "^[a-z0-9_][a-z0-9_-]*\$"; # configurable;

my %conf = ();
$conf{max_username_length} = 10;

my $db;
my $uid;
my $aid;

#**********************************************************
# Init 
#**********************************************************
sub new {
  my $class = shift;
  $db = shift;
  my $self = { };
  bless($self, $class);
  return $self;
}







#**********************************************************
# User information
# info()
#**********************************************************
sub info {
  my $self = shift;
  ($uid) = shift;

  my $sql = "SELECT id, fio, phone, address, email, activate, expire, credit, reduction, 
            variant, logins, registration, disable,
            INET_NTOA(ip), INET_NTOA(netmask), speed, filter_id, cid, comments, account_id  
     FROM users WHERE uid='$uid';";

  my $q = $db->prepare($sql);
  $q ->execute(); 

  if($db->err > 0) {
     $self->{errno} = 3;
     $self->{errstr} = 'SQL_ERROR';
     return $self;
   }
  elsif ($q->rows < 1) {
     $self->{errno} = 2;
     $self->{errstr} = 'ERROR_NOT_EXIST';
     return $self;
   }

  ($self->{LOGIN}, 
   $self->{FIO}, 
   $self->{PHONE}, 
   $self->{ADDRESS}, 
   $self->{EMAIL}, 
   $self->{ACTIVATE}, $self->{EXPIRE}, 
   $self->{CREDIT}, 
   $self->{REDUCTION}, 
   $self->{TARIF_PLAN}, 
   $self->{SIMULTANEONSLY}, 
   $self->{REGISTRATION}, 
   $self->{DISABLE}, 
   $self->{IP}, 
   $self->{NETMASK}, 
   $self->{SPEED}, 
   $self->{FILTER_ID}, 
   $self->{CID}, 
   $self->{COMMENTS}, 
   $self->{ACCOUNT_ID},
   $self->{DEPOSIT})= $q->fetchrow();
  
  $self->{UID} = $uid;
  
  return $self;
}

#**********************************************************
# list()
#**********************************************************
sub list {
 my $self = shift;
 my ($attr) = @_;

 my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
 my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
 my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
 my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;


 my $WHERE  = '';
 
 # Start letter 
 if ($attr->{FIRST_LETTER}) {
    $WHERE .= ($WHERE ne '') ?  " and u.id LIKE '$attr->{FIRST_LETTER}%' " : "WHERE u.id LIKE '$attr->{FIRST_LETTER}%' ";
  }
 
 # Show users for spec tarifplan 
 if ($attr->{TP}) {
    $WHERE .= ($WHERE ne '') ?  " and u.variant='$attr->{TP}' " : "WHERE u.variant='$attr->{TP}' ";
  }

 # Show debeters
 if ($attr->{DEBETERS}) {
    $WHERE .= ($WHERE ne '') ?  " and u.id LIKE '$attr->{FIRST_LETTER}%' " : "WHERE u.id LIKE '$attr->{FIRST_LETTER}%' ";
  }
 
 my $q = $db->prepare("SELECT count(u.id) FROM users u $WHERE");
 
 $q ->execute(); 
 my ($total) = $q->fetchrow();

# print "SELECT u.id, u.fio, u.deposit, u.credit, v.name, u.uid 
#     FROM users u
#     LEFT JOIN  variant v ON  (v.vrnt=u.variant) 
#     $WHERE ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;";
 
 $q = $db->prepare("SELECT u.id, u.fio, u.deposit, u.credit, v.name, u.uid 
     FROM users u
     LEFT JOIN  variant v ON  (v.vrnt=u.variant) 
     $WHERE ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;") || die $db->errstr;

 $q ->execute(); 
 my @users = ();
 
 while(my @user = $q->fetchrow()) {
   push @users, \@user;
  }

  $self->{list} = \@users;
  return $self->{list}, $total;

}


#**********************************************************
# add()
#**********************************************************
sub add {
  my $self = shift;
  my ($attr) = @_;
  
  my $LOGIN = (defined($attr->{LOGIN})) ? $attr->{LOGIN} : '';
  my $EMAIL = (defined($attr->{EMAIL})) ? $attr->{EMAIL} : '';
  my $FIO = (defined($attr->{FIO})) ? $attr->{FIO} : '';
  my $PHONE = (defined($attr->{PHONE})) ? $attr->{PHONE} : '';
  my $ADDRESS = (defined($attr->{ADDRESS})) ? $attr->{ADDRESS} : '';
  my $ACTIVATE = (defined($attr->{ACTIVATE})) ? $attr->{ACTIVATE} : '0000-00-00';
  my $EXPIRE = (defined($attr->{EXPIRE})) ? $attr->{EXPIRE} : '0000-00-00';
  my $CREDIT = (defined($attr->{CREDIT})) ? $attr->{CREDIT} : 0;
  my $REDUCTION  = (defined($attr->{REDUCTION})) ? $attr->{REDUCTION} : 0;
  my $SIMULTANEONSLY = (defined($attr->{SIMULTANEONSLY})) ? $attr->{SIMULTANEONSLY} : 0;
  my $COMMENTS = (defined($attr->{COMMENTS})) ? $attr->{COMMENTS} : '';
  my $ACCOUNT_ID = (defined($attr->{ACCOUNT_ID})) ? $attr->{ACCOUNT_ID} : 0;
  my $DISABLE = (defined($attr->{DISABLE})) ? $attr->{DISABLE} : 0;
  
  my $TARIF_PLAN = (defined($attr->{TARIF_PLAN})) ? $attr->{TARIF_PLAN} : '';
  my $IP = (defined($attr->{IP})) ? $attr->{IP} : '0.0.0.0';
  my $NETMASK  = (defined($attr->{NETMASK})) ? $attr->{NETMASK} : '255.255.255.255';
  my $SPEED = (defined($attr->{SPEED})) ? $attr->{SPEED} : 0;
  my $FILTER_ID = (defined($attr->{FILTER_ID})) ? $attr->{FILTER_ID} : '';
  my $CID = (defined($attr->{CID})) ? $attr->{CID} : '';


  if ($LOGIN eq '') {
     $self->{errno} = 8;
     $self->{errstr} = 'ERROR_ENTER_NAME';
     return $self;
   }
  elsif (length($LOGIN) > $conf{max_username_length}) {
     $self->{errno} = 9;
     $self->{errstr} = 'ERROR_SHORT_PASSWORD';
     return $self;
   }
  elsif($LOGIN !~ /$usernameregexp/) {
     $self->{errno} = 10;
     $self->{errstr} = 'ERROR_WRONG_NAME';
     return $self; 	
   }
  elsif($EMAIL ne '') {
    if ($EMAIL !~ /^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/) {
      $self->{errno} = 11;
      $self->{errstr} = 'ERROR_WRONG_EMAIL';
      return $self;
     }
   }
    
  my $sql = "INSERT INTO users (id, fio, phone, address, email, activate, expire, credit, reduction, 
            variant, logins, registration, disable, ip, netmask, speed, filter_id, cid, comments, account_id)
           VALUES ('$LOGIN', '$FIO', '$PHONE', \"$ADDRESS\", '$EMAIL', '$ACTIVATE', '$EXPIRE', '$CREDIT', '$REDUCTION', 
            '$TARIF_PLAN', '$SIMULTANEONSLY', now(),  '$DISABLE', INET_ATON('$IP'), INET_ATON('$NETMASK'), '$SPEED', '$FILTER_ID', LOWER('$CID'), '$COMMENTS', '$ACCOUNT_ID');";

  print "$sql";
  my $q = $db->do($sql);

    
  if ($db->err == 1062) {
     $self->{errno} = 7;
     $self->{errstr} = 'ERROR_DUBLICATE';
     return $self;
   }
  elsif($db->err > 0) {
     $self->{errno} = 3;
     $self->{errstr} = 'SQL_ERROR';
     return $self;
   }

  return $self->{result};
}


#**********************************************************
# add()
#**********************************************************
sub change {
  my $self = shift;
  my ($uid, $attr) = @_;
  
  my %DATA = ();

  $DATA{LOGIN} = (defined($attr->{LOGIN})) ? $attr->{LOGIN} : '';
  $DATA{EMAIL} = (defined($attr->{EMAIL})) ? $attr->{EMAIL} : '';
  $DATA{FIO} = (defined($attr->{FIO})) ? $attr->{FIO} : '';
  $DATA{PHONE} = (defined($attr->{PHONE})) ? $attr->{PHONE} : '';
  $DATA{ADDRESS} = (defined($attr->{ADDRESS})) ? $attr->{ADDRESS} : '';
  $DATA{ACTIVATE} = (defined($attr->{ACTIVATE})) ? $attr->{ACTIVATE} : '0000-00-00';
  $DATA{EXPIRE} = (defined($attr->{EXPIRE})) ? $attr->{EXPIRE} : '0000-00-00';
  $DATA{CREDIT} = (defined($attr->{CREDIT})) ? $attr->{CREDIT} : 0;
  $DATA{REDUCTION}  = (defined($attr->{REDUCTION})) ? $attr->{REDUCTION} : 0;
  $DATA{SIMULTANEONSLY} = (defined($attr->{SIMULTANEONSLY})) ? $attr->{SIMULTANEONSLY} : 0;
  $DATA{COMMENTS} = (defined($attr->{COMMENTS})) ? $attr->{COMMENTS} : '';
  $DATA{ACCOUNT_ID} = (defined($attr->{ACCOUNT_ID})) ? $attr->{ACCOUNT_ID} : 0;
  $DATA{DISABLE} = (defined($attr->{DISABLE})) ? $attr->{DISABLE} : 0;
    
  $DATA{TARIF_PLAN} = (defined($attr->{TARIF_PLAN})) ? $attr->{TARIF_PLAN} : '';
  $DATA{IP} = (defined($attr->{IP})) ? $attr->{IP} : '0.0.0.0';
  $DATA{NETMASK}  = (defined($attr->{NETMASK})) ? $attr->{NETMASK} : '255.255.255.255';
  $DATA{SPEED} = (defined($attr->{SPEED})) ? $attr->{SPEED} : 0;
  $DATA{FILTER_ID} = (defined($attr->{FILTER_ID})) ? $attr->{FILTER_ID} : '';
  $DATA{CID} = (defined($attr->{CID})) ? $attr->{CID} : '';


  if($DATA{EMAIL} ne '') {
    if ($DATA{EMAIL} !~ /^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/) {
      $self->{errno} = 11;
      $self->{errstr} = 'ERROR_WRONG_EMAIL';
      return $self;
     }
   }

  my $CHANGES = "";
  my $CHANGES_LOG = "";

  my $q = $db -> prepare("SELECT  id, fio, phone, address, email, activate, expire, 
  credit, reduction, variant, logins, disable, INET_NTOA(ip), INET_NTOA(netmask), speed,  
  filter_id, cid, comments, account_id
     FROM users  WHERE uid=\"$uid\";");
  $q -> execute ();
  my %OLD = ();

  ($OLD{LOGIN}, $OLD{FIO}, $OLD{PHONE}, $OLD{ADDRESS}, $OLD{EMAIL}, $OLD{ACTIVATE}, $OLD{EXPIRE}, 
   $OLD{CREDIT}, $OLD{REDUCTION}, $OLD{TARIF_PLAN}, $OLD{SIMULTANEONSLY}, $OLD{DISABLE}, $OLD{IP}, 
   $OLD{NETMASK}, $OLD{SPEED}, $OLD{FILTER_ID}, $OLD{CID}, $OLD{COMMENTS}) = $q -> fetchrow();

  while(my($k, $v)=each(%DATA)) {
     if ($OLD{$k} ne $DATA{$k}){
        print "$k, $v / $DATA{$k} | $OLD{$k}/<br>";	
      }
   }

   
=comments 
#  my $sql = "UPDATE users SET 
#  id='$LOGIN', 
  fio='$FIO', 
  phone='$PHONE', 
  address='$ADDRESS', 
  email='$EMAIL', 
  activate='$ACTIVATE', 
  expire='$EXPIRE', 
  credit='$CREDIT', 
  reduction='$REDUCTION', 
  variant='$TARIF_PLAN', 
  logins='$SIMULTANEONSLY', 
  disable='$DISABLE',
  ip=INET_ATON('IP'), 
  netmask=INET_ATON('$NETMASK'), 
  speed='$SPEED', 
  filter_id='$FILTER_ID', 
  cid='$CID', 
  comments='$COMMENTS', 
  account_id='$ACCOUNT_ID'
  WHERE uid='$uid';";

  print "$sql";
=cut
  #my $q = $db->do($sql);

    
  if ($db->err == 1062) {
     $self->{errno} = 7;
     $self->{errstr} = 'ERROR_DUBLICATE';
     return $self;
   }
  elsif($db->err > 0) {
     $self->{errno} = 3;
     $self->{errstr} = 'SQL_ERROR';
     return $self;
   }

  return $self->{result};
}


#**********************************************************
# password()
#**********************************************************
sub password {
  my $self = shift;
  my ($password, $attr)=@_;

  my $secretkey = (defined($attr->{secretkey}))? $attr->{secretkey} : '';
  my $sql = "UPDATE admins SET password=ENCODE('$password', '$secretkey') WHERE aid='$aid';";
  my $q = $db->do($sql); 
  #print $sql;
  #$self->{errno}='test';
  return $self->{result};
}

1
package Users;
# Administrators manage functions
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
my $usernameregexp = "^[a-z0-9_][a-z0-9_-]*\$"; # configurable;

my %conf = ();
$conf{max_username_length} = 10;


use main;
@ISA  = ("main");


my $db;
my $uid;
my $admin;
my %DATA = ();

#**********************************************************
# Init 
#**********************************************************
sub new {
  my $class = shift;
  ($db, $admin) = @_;
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

  $self->query($db, "SELECT u.id, u.fio, u.phone, u.address, u.email, u.activate, u.expire, u.credit, u.reduction, 
            u.variant, u.logins, u.registration, u.disable,
            INET_NTOA(u.ip), INET_NTOA(u.netmask), u.speed, u.filter_id, u.cid, u.comments, u.account_id,
            if(acct.name IS NULL, 'N/A', acct.name), if(acct.name IS NULL, u.deposit, acct.deposit), tp.name, u.gid
     FROM users u
     LEFT JOIN accounts acct ON (u.account_id=acct.id)
     LEFT JOIN variant tp ON (u.variant=tp.vrnt)
     WHERE uid='$uid';");

  if ($self->{TOTAL} < 1) {
     $self->{errno} = 2;
     $self->{errstr} = 'ERROR_NOT_EXIST';
     return $self;
   }
  my $ar = $self->{list}->[0];

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
   $self->{ACCOUNT_NAME},
   $self->{DEPOSIT},
   $self->{TP_NAME},
   $self->{GID} )= @$ar;
   $self->{UID} = $uid;
  
  
  return $self;
}

#**********************************************************
#
#**********************************************************
sub defaults {
  my $self = shift;

  %DATA = ( LOGIN => '', 
   FIO => '', 
   PHONE => '', 
   ADDRESS => '', 
   EMAIL => '', 
   ACTIVATE => '0000-00-00', 
   EXPIRE => '0000-00-00', 
   CREDIT => 0, 
   REDUCTION => '0.00', 
   TARIF_PLAN => 0, 
   SIMULTANEONSLY => 0, 
   DISABLE => 0, 
   IP => '0.0.0.0', 
   NETMASK => '255.255.255.255', 
   SPEED => 0, 
   FILTER_ID => '', 
   CID => '', 
   COMMENTS => '', 
   ACCOUNT_ID => 0,
   DEPOSIT => 0,
   GID => 0 );

 
  $self = \%DATA;
  return $self;
}


#**********************************************************
# list()
#**********************************************************
sub list {
 my $self = shift;
 my ($attr) = @_;
 my @list = ();

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

 # Show debeters
 if ($attr->{ACCOUNT_ID}) {
    $WHERE .= ($WHERE ne '') ?  " and u.account_id='$attr->{ACCOUNT_ID}' " : "WHERE u.account_id='$attr->{ACCOUNT_ID}' ";
  }

 # Show groups
 if ($attr->{GID}) {
    $WHERE .= ($WHERE ne '') ?  " and u.gid='$attr->{GID}' " : "WHERE u.gid='$attr->{GID}' ";
  }

# print "SELECT u.id, u.fio, u.deposit, u.credit, v.name, u.uid 
#     FROM users u
#     LEFT JOIN  variant v ON  (v.vrnt=u.variant) 
#     $WHERE ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;";
 
 $self->query($db, "SELECT u.id, u.fio, if(acct.id IS NULL, u.deposit, acct.deposit), u.credit, v.name, u.uid 
     FROM users u
     LEFT JOIN  variant v ON  (v.vrnt=u.variant) 
     LEFT JOIN  accounts acct ON  (u.account_id=acct.id) 
     $WHERE ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;");

 my $list = $self->{list};

 if ($self->{TOTAL} > 0) {
    $self->query($db, "SELECT count(u.id) FROM users u $WHERE");
    my $a_ref = $self->{list}->[0];
    ($self->{TOTAL}) = @$a_ref;
   }

  return $list;
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
  my $REDUCTION  = (defined($attr->{REDUCTION})) ? $attr->{REDUCTION} : 0.00;
  my $SIMULTANEONSLY = (defined($attr->{SIMULTANEONSLY})) ? $attr->{SIMULTANEONSLY} : 0;
  my $COMMENTS = (defined($attr->{COMMENTS})) ? $attr->{COMMENTS} : '';
  my $ACCOUNT_ID = (defined($attr->{ACCOUNT_ID})) ? $attr->{ACCOUNT_ID} : 0;
  my $DISABLE = (defined($attr->{DISABLE})) ? $attr->{DISABLE} : 0;
  my $GID = (defined($attr->{GID})) ? $attr->{GID} : 65535;
  
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
            variant, logins, registration, disable, ip, netmask, speed, filter_id, cid, comments, account_id, gid)
           VALUES ('$LOGIN', '$FIO', '$PHONE', \"$ADDRESS\", '$EMAIL', '$ACTIVATE', '$EXPIRE', '$CREDIT', '$REDUCTION', 
            '$TARIF_PLAN', '$SIMULTANEONSLY', now(),  '$DISABLE', INET_ATON('$IP'), INET_ATON('$NETMASK'), '$SPEED', '$FILTER_ID', LOWER('$CID'), '$COMMENTS', '$ACCOUNT_ID', '$GID');";

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

  $self->{UID} = $db->{'mysql_insertid'};
  $self->{LOGIN} = $LOGIN;
  
  $admin->action_add($uid, "ADD $LOGIN");

  return $self;
}




#**********************************************************
# change()
#**********************************************************
sub change {
  my $self = shift;
  my ($uid, $attr) = @_;
  
  my %DATA = ();

  $DATA{LOGIN} = $attr->{LOGIN} if (defined($attr->{LOGIN}));
  $DATA{EMAIL} = $attr->{EMAIL} if (defined($attr->{EMAIL}));
  $DATA{FIO} =   $attr->{FIO} if (defined($attr->{FIO}));
  $DATA{PHONE} = $attr->{PHONE} if (defined($attr->{PHONE}));
  $DATA{ADDRESS} = $attr->{ADDRESS} if (defined($attr->{ADDRESS}));
  $DATA{ACTIVATE} = $attr->{ACTIVATE} if (defined($attr->{ACTIVATE}));
  $DATA{EXPIRE} = $attr->{EXPIRE} if (defined($attr->{EXPIRE}));
  $DATA{CREDIT} = $attr->{CREDIT} if (defined($attr->{CREDIT}));
  $DATA{REDUCTION}  = $attr->{REDUCTION} if (defined($attr->{REDUCTION}));
  $DATA{SIMULTANEONSLY} = $attr->{SIMULTANEONSLY} if (defined($attr->{SIMULTANEONSLY}));
  $DATA{COMMENTS} = $attr->{COMMENTS} if (defined($attr->{COMMENTS}));
  $DATA{ACCOUNT_ID} = $attr->{ACCOUNT_ID} if (defined($attr->{ACCOUNT_ID}));
  $DATA{DISABLE} = $attr->{DISABLE} if (defined($attr->{DISABLE}));
  $DATA{GID} = $attr->{GID} if (defined($attr->{GID}));
  $DATA{PASSWORD} = $attr->{PASSWORD} if (defined($attr->{PASSWORD}));
  my $secretkey = (defined($attr->{secretkey}))? $attr->{secretkey} : '';  

  $DATA{TARIF_PLAN} = $attr->{TARIF_PLAN} if (defined($attr->{TARIF_PLAN}));
  $DATA{IP} = $attr->{IP} if (defined($attr->{IP}));
  $DATA{NETMASK}  = $attr->{NETMASK} if (defined($attr->{NETMASK}));
  $DATA{SPEED} = $attr->{SPEED} if (defined($attr->{SPEED}));
  $DATA{FILTER_ID} = $attr->{FILTER_ID} if (defined($attr->{FILTER_ID}));
  $DATA{CID} = $attr->{CID} if (defined($attr->{CID}));


my %FIELDS = (LOGIN => 'id',
              EMAIL => 'email',
              FIO => 'fio',
              PHONE => 'phone',
              ADDRESS => 'address',
              ACTIVATE => 'activate',
              EXPIRE => 'expire',
              CREDIT => 'credit',
              REDUCTION => 'reduction',
              SIMULTANEONSLY => 'logins',
              COMMENTS => 'comments',
              ACCOUNT_ID => 'account_id',
              DISABLE => 'disable',
              GID => 'gid',
              PASSWORD => 'password',

              IP => 'ip',
              NETMASK => 'netmask',
              TARIF_PLAN=> 'variant',
              SPEED=> 'speed',
              CID=> 'cid'
             );

  if($DATA{EMAIL} ne '') {
    if ($DATA{EMAIL} !~ /^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/) {
      $self->{errno} = 11;
      $self->{errstr} = 'ERROR_WRONG_EMAIL';
      return $self;
     }
   }

  my $CHANGES_QUERY = "";
  my $CHANGES_LOG = "";
  
  my $OLD = $self->info($uid);
  if($OLD->{errno}) {
     $self->{errno} = $OLD->{errno};
     $self->{errstr} = $OLD->{errstr};
     return $self;
   }

  while(my($k, $v)=each(%DATA)) {
    if ($OLD->{$k} ne $DATA{$k}){
        if ($k eq 'PASSWORD') {
          $CHANGES_LOG .= "$k *->*;";
          $CHANGES_QUERY .= "$FIELDS{$k}=ENCODE('$DATA{$k}', '$secretkey'),";
         }
        elsif($k eq 'IP' || $k eq 'NETMASK') {
          $CHANGES_LOG .= "$k $OLD->{$k}->$DATA{$k};";
          $CHANGES_QUERY .= "$FIELDS{$k}=INET_ATON('$DATA{$k}'),";
         }
        else {
          $CHANGES_LOG .= "$k $OLD->{$k}->$DATA{$k};";
          $CHANGES_QUERY .= "$FIELDS{$k}='$DATA{$k}',";
         }
     }
   }


if ($CHANGES_QUERY eq '') {
  return $self->{result};	
}

# print $CHANGES_LOG;

  chop($CHANGES_QUERY);
  my $sql = "UPDATE users SET $CHANGES_QUERY
    WHERE uid='$uid'";

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

  $admin->action_add($uid, "$CHANGES_LOG");
  return $self->{result};
}



#**********************************************************
# del()
#**********************************************************
sub del {
  my $self = shift;

  $self->query($db, "DELETE FROM users WHERE uid='$self->{UID}';". 'do');

  $admin->action_add($uid, "DELETE");
  return $self->{result};
}

#**********************************************************
# list_allow nass
#**********************************************************
sub nas_list {
  my $self = shift;

  my @nas_list ;
 
  my $sql="SELECT nas_id FROM users_nas WHERE uid='$self->{UID}';";
  my $q = $db->prepare($sql) || die $db->strerr;
  $q ->execute();

  if ($q->rows > 0) {
    while(my ($nas) = $q->fetchrow()) {
      push @nas_list, $nas;
     }
   }
  else {
    $sql="SELECT nas_id FROM vid_nas WHERE vid='$self->{TARIF_PLAN}';";
    $q = $db->prepare($sql) || die $db->strerr;
    $q ->execute();
    if ($q->rows > 0) {
      while(my($nas_id)=$q->fetchrow()) {
         push @nas_list, $nas_id;
       }
     }
   }

	return \@nas_list;
}


#**********************************************************
# list_allow nass
#**********************************************************
sub nas_add {
 my $self = shift;
 my ($nas) = @_;
 
 $self->nas_del();
 foreach my $line (@$nas) {
   my $sql = "INSERT INTO users_nas (nas_id, uid)
        VALUES ('$line', '$self->{UID}');";	
   my $q = $db->do($sql) || die $db->errstr;
  }
  
  $admin->action_add($uid, "NAS ". join(',', @$nas) );
  return $self;
}

#**********************************************************
# nas_del
#**********************************************************
sub nas_del {
  my $self = shift;

  my $sql = "DELETE FROM users_nas WHERE uid='$self->{UID}';";	
  my $q = $db->do($sql) || die $db->errstr;

  if($db->err > 0) {
     $self->{errno} = 3;
     $self->{errstr} = 'SQL_ERROR';
     return $self;
   }

  $admin->action_add($uid, "DELETE NAS");
  return $self;
}

sub test {
 my  $self = shift;	

 print "test";
}


1
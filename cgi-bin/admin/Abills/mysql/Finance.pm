package Finance;
# Finance module
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
my $admin;
#my %DATA = ();

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
# fees
#**********************************************************
sub fees {
  my $class = shift;
  ($db, $admin) = @_;
  use Fees;
  my $fees = Fees->new($db, $admin);
  return $fees;
}



#**********************************************************
# Init 
#**********************************************************
sub payments {
  my $class = shift;
  ($db, $admin) = @_;
  my $self = { };
  bless($self, $class);
  return $self;
}


#**********************************************************
# add()
#**********************************************************
sub add {
  my $self = shift;
  my ($user, $sum, $attr) = @_;
  
  my $DESCRIBE = (defined($attr->{DESCRIBE})) ? $attr->{DESCRIBE} : '';
  my $ER = (defined($attr->{ER})) ? $attr->{ER} : 1;

  
  if ($sum <= 0) {
     $self->{errno} = 12;
     $self->{errstr} = 'ERROR_ENTER_SUM';
     return $self;
   }
  
  my $sql;

  if ($user->{ACCOUNT_ID} > 0) {
  	$sql = "SELECT deposit FROM accounts WHERE id='$user->{ACCOUNT_ID}';";
   }
  else {
    $sql = "SELECT deposit FROM users WHERE uid='$user->{UID}';";
   }
  
  my $q = $db -> prepare($sql)|| die $db->errstr;
  $q -> execute();
  if ($q->rows == 1) {
     my ($deposit)=$q -> fetchrow();
     if ($ER ne '') {
       $sum = $sum / $ER;
      }

    if ($user->{ACCOUNT_ID} > 0) {
      $db ->do("UPDATE accounts SET deposit=deposit+$sum WHERE id='$user->{ACCOUNT_ID}';") or
         die $db->errstr;
      }   
    else {
    	$db ->do("UPDATE users SET deposit=deposit+$sum WHERE uid='$user->{UID}';") or
         die $db->errstr;
      }

    my $sql = "INSERT INTO payments (uid, date, sum, dsc, ip, last_deposit, aid) 
           values ('$user->{UID}', now(), $sum, '$DESCRIBE', INET_ATON('$admin->{SESSION_IP}'), '$deposit', '$admin->{AID}');";
    $db -> do ($sql) or die $db->errstr;
    if($db->err > 0) {
       $self->{errno} = 3;
       $self->{errstr} = 'SQL_ERROR';
       return $self;
      }
  }

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

# $admin->log_action($uid, "ADD $LOGIN");
  return $self->{result};
}

#**********************************************************
# del $user, $id
#**********************************************************
sub del {
  my $self = shift;
  my ($user, $id) = @_;

  
  my $sql = "SELECT sum from payments WHERE id='$id';";
  my $q = $db->prepare($sql); 
  $q ->execute(); 

  if ($q->rows < 1) {
     $self->{errno} = 2;
     $self->{errstr} = 'ERROR_NOT_EXIST';
     return $self;
   }
  elsif($db->err > 0) {
     $self->{errno} = 3;
     $self->{errstr} = 'SQL_ERROR';
     return $self;
   }
  my($sum) = $q->fetchrow();


  if ($user->{ACCOUNT_ID} > 0) {
    $sql = "UPDATE accounts SET deposit=deposit-$sum WHERE id='$user->{ACCOUNT_ID}';";	
    print $sql;
     }
  else {
    $sql = "UPDATE users SET deposit=deposit-$sum WHERE uid='$user->{UID}';";	
   }

  $q = $db->do($sql); 
  if($db->err > 0) {
     $self->{errno} = 3;
     $self->{errstr} = 'SQL_ERROR';
     return $self;
   }

  $sql = "DELETE FROM payments WHERE id='$id';";
  $q = $db->do($sql); 

  if($db->err > 0) {
     $self->{errno} = 3;
     $self->{errstr} = 'SQL_ERROR';
     return $self;
   }

  $admin->action_add($user->{UID}, "DELETE PAYEMNTS SUM: $sum");
  return $self->{result};
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
 
 if ($attr->{UID}) {
    $WHERE .= ($WHERE ne '') ?  " and p.uid='$attr->{UID}' " : "WHERE p.uid='$attr->{UID}' ";
  }
 
 if ($attr->{AID}) {
    $WHERE .= ($WHERE ne '') ?  " and p.aid='$attr->{AID}' " : "WHERE p.aid='$attr->{AID}' ";
  }

 # Show debeters
 if ($attr->{DEBETERS}) {
    $WHERE .= ($WHERE ne '') ?  " and u.id LIKE '$attr->{FIRST_LETTER}%' " : "WHERE u.id LIKE '$attr->{FIRST_LETTER}%' ";
  }
 
 my $q = $db->prepare("SELECT count(p.id), sum(p.sum)  FROM payments p $WHERE");
 
 $q ->execute(); 
 my ($total, $sum) = $q->fetchrow();
 $self->{TOTAL} = $total;
 $self->{SUM} = $sum;
 
 $q = $db->prepare("SELECT p.id, u.id, p.date, p.sum, p.dsc, a.name, INET_NTOA(p.ip), p.last_deposit, p.uid 
    FROM payments p
    LEFT JOIN users u ON (u.uid=p.uid)
    LEFT JOIN admins a ON (a.id=p.aid)
    $WHERE 
    GROUP BY p.id
    ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;") || die $db->errstr;

 $q ->execute(); 
 my @list = ();
 
 while(my @row = $q->fetchrow()) {
   push @list, \@row;
  }

  $self->{LIST} = \@list;
  return $self->{LIST};
}






#**********************************************************
# exchange_list
#**********************************************************
sub exchange_list {
	my $self = shift;
  my ($attr) = @_;
  
 my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
 my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
# my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
# my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $q = $db->prepare("SELECT money, short_name, rate, changed, id 
    FROM exchange_rate
    ORDER BY $SORT $DESC;") || die $db->errstr;
  $q ->execute(); 

  my $total = $q->rows;

  my @list = ();
  while(my @row = $q->fetchrow()) {
     push @list, \@row;
   }

  $self->{list} = \@list;
  return $self->{list}, $total;
}


#**********************************************************
# exchange_add
#**********************************************************
sub exchange_add {
	my $self = shift;
  my ($money, $short_name, $rate) = @_;
  
  my $q = $db->do("INSERT INTO exchange_rate (money, short_name, rate, changed) 
   values ('$money', '$short_name', '$rate', now());");

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
	
	return $self;
}


#**********************************************************
# exchange_del
#**********************************************************
sub exchange_del {
	my $self = shift;
  my ($id) = @_;
  my $sql = "DELETE FROM exchange_rate WHERE id='$id';";
  my $q = $db->do($sql); 

  if($db->err > 0) {
     $self->{errno} = 3;
     $self->{errstr} = 'SQL_ERROR';
     return $self;
   }
	
	return $self;
}


#**********************************************************
# exchange_list
#**********************************************************
sub exchange_change {
	my $self = shift;
  my ($id, $money, $short_name, $rate) = @_;
 
  my $sql = "UPDATE exchange_rate SET
    money='$money', 
    short_name='$short_name', 
    rate='$rate',
    changed=now()
   WHERE id='$id';";
  my $q  = $db->do($sql);

  if($db->err > 0) {
     $self->{errno} = 3;
     $self->{errstr} = 'SQL_ERROR';
     return $self;
   }
	
	return $self;
}


#**********************************************************
# exchange_list
#**********************************************************
sub exchange_info {
	my $self = shift;
  my ($id) = @_;

  my $sql = "SELECT money, short_name, rate FROM exchange_rate WHERE id='$id';";
  my $q  = $db->prepare($sql);
  $q -> execute();
  ($self->{MU_NAME}, $self->{MU_SHORT_NAME}, $self->{EX_RATE})=$q->fetchrow();

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

	return $self;
}

1
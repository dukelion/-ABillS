package Fees;
# Finance module
# Fees 

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

my $db;
my $uid;
my $admin;
#my %DATA = ();
use main;
@ISA  = ("main");


#**********************************************************
# Init 
#**********************************************************
sub new {
  my $class = shift;
  ($db, $admin) = @_;
  my $self = { };
  bless($self, $class);
  $self->{debug}=1;
  return $self;
}


#**********************************************************
# add()
#**********************************************************
sub get {
  my $self = shift;
  my ($user, $sum, $attr) = @_;
  
  my $DESCRIBE = (defined($attr->{DESCRIBE})) ? $attr->{DESCRIBE} : '';
  
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

    if ($user->{ACCOUNT_ID} > 0) {
      $db ->do("UPDATE accounts SET deposit=deposit-$sum WHERE id='$user->{ACCOUNT_ID}';") or
         die $db->errstr;
      }   
    else {
    	$db ->do("UPDATE users SET deposit=deposit-$sum WHERE uid='$user->{UID}';") or
         die $db->errstr;
      }

    $sql = "INSERT INTO fees (uid, date, sum, dsc, ip, last_deposit, aid) 
           values ('$user->{UID}', now(), $sum, '$DESCRIBE', INET_ATON('$admin->{SESSION_IP}'), '$deposit', '$admin->{AID}');";

    print $sql;

    $db -> do ($sql) or die $db->errstr;
    if($db->err > 0) {
       $self->{errno} = 3;
       $self->{errstr} = 'SQL_ERROR';
       return $self;
      }
  }


  if($db->err > 0) {
     $self->{errno} = 3;
     $self->{errstr} = 'SQL_ERROR';
     return $self;
   }

  return $self->{result};
}

#**********************************************************
# del $user, $id
#**********************************************************
sub del {
  my $self = shift;
  my ($user, $id) = @_;

  $self->query($db, "SELECT sum from fees WHERE id='$id';");

  if ($self->{TOTAL} < 1) {
     $self->{errno} = 2;
     $self->{errstr} = 'ERROR_NOT_EXIST';
     return $self;
   }
  elsif($self->{errno}) {
     return $self;
   }

  my $a_ref = $self->{list}->[0];
  my($sum) = @$a_ref;

  my $sql;
  if ($user->{ACCOUNT_ID} > 0) {
    $sql = "UPDATE accounts SET deposit=deposit+$sum WHERE id='$user->{ACCOUNT_ID}';";	
   }
  else {
    $sql = "UPDATE users SET deposit=deposit+$sum WHERE uid='$user->{UID}';";	
   }

  $self->query($db, "$sql", 'do');

  $self->query($db, "DELETE FROM fees WHERE id='$id';", 'do');

  $admin->action_add($user->{UID}, "DELETE FEES SUM: $sum");
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
 my @list = (); 

 if ($attr->{UID}) {
    $WHERE .= ($WHERE ne '') ?  " and f.uid='$attr->{UID}' " : "WHERE f.uid='$attr->{UID}' ";
  }
 
 if ($attr->{AID}) {
    $WHERE .= ($WHERE ne '') ?  " and f.aid='$attr->{AID}' " : "WHERE f.aid='$attr->{AID}' ";
  }

 $self->query($db, "SELECT f.id, u.id, f.date, f.sum, f.dsc, a.name, INET_NTOA(f.ip), f.last_deposit, f.uid 
    FROM fees f
    LEFT JOIN users u ON (u.uid=f.uid)
    LEFT JOIN admins a ON (a.aid=f.aid)
    $WHERE 
    GROUP BY f.id
    ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;");

  my $list = $self->{list};


 $self->query($db, "SELECT count(f.id), sum(f.sum) FROM fees f $WHERE");
 my $a_ref = $self->{list}->[0];

 ($self->{TOTAL}, 
  $self->{SUM}) = @$a_ref;

  return $list;
}







1
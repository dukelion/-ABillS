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
# Administrator information
# info()
#**********************************************************
sub info {
  my $class = shift;
  ($aid) = shift;
  my ($attr) = @_;
  my $self = { };
  bless($self, $class);

  my $WHERE;
  if (defined($attr->{login}) && defined($attr->{password})) {
    my $secretkey = (defined($attr->{secretkey}))? $attr->{secretkey} : '';
    $WHERE = "WHERE id='$attr->{login}' and DECODE(password, '$secretkey')='$attr->{password}'";
   }
  else {
    $WHERE = "WHERE aid='$aid'";
   }

  my $sql = "SELECT aid, id, name, regdate  FROM admins $WHERE;";
  my $q = $db->prepare($sql) || die $db->errstr;
  $q ->execute(); 

  if ($aid == 0 && $q->rows < 1) {
     $self->{errno} = 4;
     $self->{errstr} = 'ERROR_WRONG_PASSWORD';
     return $self;
   }
  elsif ($q->rows < 1) {
     $self->{errno} = 2;
     $self->{errstr} = 'Not exist';
     return $self;
   }

  my ($aid, $name, $fio, $registration)= $q->fetchrow();
  
  $self->{aid}=$aid;
  $self->{name}="$name";
  $self->{fio} = "$fio";
  $self->{registration} = "$registration";

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
  $self->{errstr}='test';

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
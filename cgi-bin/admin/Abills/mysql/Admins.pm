package Admins;
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
my $aid;
my $IP;

#**********************************************************
#
#**********************************************************
sub new {
  my $class = shift;
  $db = shift;
  my $self = { };
  bless($self, $class);
  return $self;
}




#**********************************************************
# get_permissions()
#**********************************************************
sub get_permissions {
  my $self = shift;
  my %permissions = ();

  $aid = $self->{aid};

  my $sql = "SELECT section, actions FROM admin_permits WHERE aid='$aid';";
  my $q  = $db->prepare($sql);
  $q->execute();

  if ($q->rows < 1) {
     $self->{errno} = 2;
     $self->{errstr} = 'Not exist';
     return 0;
   }

  while(my($section, $action)=$q->fetchrow()) {
    $permissions{$section}{$action} = 'y';
   }

  $self->{permissions} = \%permissions;
  return $self->{permissions};
}



#**********************************************************
# set_permissions()
#**********************************************************
sub set_permissions {
  my $self = shift;
  my ($permissions) = @_;
  
  $aid = $self->{aid};
  my $sql = "DELETE FROM admin_permits WHERE aid='$aid';";
  my $q = $db->do($sql);

  while(my($section, $actions_hash)=each %$permissions) {
    while(my($action, $y)=each %$actions_hash) {
      my $sql = "INSERT INTO admin_permits (aid, section, actions) VALUES ('$aid', '$section', '$action');";
      my $q = $db->do($sql);
      #print $sql . "<br>\n";
     }
   }

  return $self->{permissions};
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

  $IP = (defined($attr->{IP}))? $attr->{IP} : '0.0.0.0';

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
  $self->{session_ip} = $IP;

  return $self;
}

#**********************************************************
# list()
#**********************************************************
sub list {
 my $self = shift;

 my $q = $db->prepare("select aid, id, name, regdate, gid FROM admins;") || die $db->errstr;
 $q ->execute(); 
 my @admins = ();
 
 while(my @admin = $q->fetchrow()) {
   push @admins, \@admin;
 }

  $self->{list} = \@admins;
  return $self->{list};
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
#  log_action()
#**********************************************************
sub log_action {
  my $self = shift;
  my ($uid, $actions) = @_;
 
  my $sql = "INSERT INTO userlog (aid, ip, datetime, changes, uid) VALUES ('$aid', '$IP', now(), '$actions', '$uid')";
  print $sql; 

  # my $q = $db->do($sql);

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
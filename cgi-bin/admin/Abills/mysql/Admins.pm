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

  $aid = $self->{AID};

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
  if (defined($attr->{LOGIN}) && defined($attr->{PASSWORD})) {
    my $SECRETKEY = (defined($attr->{SECRETKEY}))? $attr->{SECRETKEY} : '';
    $WHERE = "WHERE id='$attr->{LOGIN}' and DECODE(password, '$SECRETKEY')='$attr->{PASSWORD}'";
   }
  else {
    $WHERE = "WHERE aid='$aid'";
   }

  $IP = (defined($attr->{IP}))? $attr->{IP} : '0.0.0.0';

  my $sql = "SELECT aid, id, name, regdate, disable FROM admins $WHERE;";
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

  ($self->{AID},
   $self->{NAME},
   $self->{FIO},
   $self->{REGISTRATION},
   $self->{DISABLE} )= $q->fetchrow();


  $self->{SESSION_IP}  = $IP;

  return $self;
}

#**********************************************************
# list()
#**********************************************************
sub list {
 my $self = shift;

 my $q = $db->prepare("select aid, id, name, regdate, disable, gid FROM admins;") || die $db->errstr;
 $q ->execute(); 

 $self->{TOTAL} = $q->rows;

 my @list = ();
 while(my @row = $q->fetchrow()) {
   push @list, \@row;
 }

  $self->{list} = \@list;
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
#  action_add()
#**********************************************************
sub action_add {
  my $self = shift;
  my ($uid, $actions) = @_;
 
  my $sql = "INSERT INTO admin_actions (aid, ip, datetime, actions, uid) VALUES ('$aid', INET_ATON('$IP'), now(), '$actions', '$uid')";
#  print $sql; 
  my $q = $db->do($sql);

  if($db->err > 0) {
     $self->{errno} = 3;
     $self->{errstr} = 'SQL_ERROR';
     return $self;
   }

  return $self;
}

#**********************************************************
#  action_del()
#**********************************************************
sub action_del {
  my $self = shift;
  my ($action_id) = @_;
 
  my $sql = "DELETE FROM admin_actions WHERE id='$action_id';";
  my $q = $db->do($sql);
  if($db->err > 0) {
     $self->{errno} = 3;
     $self->{errstr} = 'SQL_ERROR';
     return $self;
   }

}


#**********************************************************
#  action_list()
#**********************************************************
sub action_list {
  my $self = shift;
  my ($attr) = @_;
  
  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $WHERE = '';
  my @list = ();

  # UID
  if ($attr->{UID}) {
    $WHERE .= ($WHERE ne '') ?  " and aa.uid='$attr->{UID}' " : "WHERE aa.uid='$attr->{UID}' ";
   }

  if ($attr->{AID}) {
    $WHERE .= ($WHERE ne '') ?  " and aa.aid='$attr->{AID}' " : "WHERE aa.aid='$attr->{AID}' ";
   }

 
  my $sql = "SELECT count(*) FROM admin_actions aa $WHERE;";
  my $q = $db->prepare($sql);
  $q ->execute(); 

  ($self->{TOTAL}) = $q->fetchrow();

#  print $sql;
  if ($self->{TOTAL} < 1) {
    $self->{list} = \@list;
    return $self->{list};
   }

  $q = $db->prepare("select aa.id, u.id, aa.datetime, aa.actions, a.id, INET_NTOA(aa.ip), aa.uid, aa.aid, aa.id
      FROM admin_actions aa
      LEFT JOIN admins a ON (aa.aid=a.aid)
      LEFT JOIN users u ON (aa.uid=u.uid)
       $WHERE ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;");
  $q ->execute(); 
 
 
  if($db->err > 0) {
     $self->{errno} = 3;
     $self->{errstr} = 'SQL_ERROR';
     return $self;
   }

  while(my @row = $q->fetchrow()) {
    push @list, \@row;
   }


  $self->{list} = \@list;
  return $self->{list};
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
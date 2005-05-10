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

use main;
@ISA  = ("main");

my %DATA;
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

$self->query($db, "SELECT section, actions FROM admin_permits WHERE aid='$self->{AID}';");
my $a_ref = $self->{list};

foreach my $line (@$a_ref) {
  my($section, $action)=@$line;
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
  
  $self->query($db, "DELETE FROM admin_permits WHERE aid='$self->{AID}';", 'do');
  while(my($section, $actions_hash)=each %$permissions) {
    while(my($action, $y)=each %$actions_hash) {
      $self->query($db, "INSERT INTO admin_permits (aid, section, actions) VALUES ('$self->{AID}', '$section', '$action');", 'do');
     }
   }
  return $self->{permissions};
}


#**********************************************************
# Administrator information
# info()
#**********************************************************
sub auth {
  my $class = shift;
  my ($attr) = @_;
  my $self = { };

  return $self;
}


#**********************************************************
# Administrator information
# info()
#**********************************************************
sub info {
  my ($self) = shift;
  ($aid) = shift;
  my ($attr) = @_;

  my $WHERE;
  my $PASSWORD = '0'; 
  if (defined($attr->{LOGIN}) && defined($attr->{PASSWORD})) {
    my $SECRETKEY = (defined($attr->{SECRETKEY}))? $attr->{SECRETKEY} : '';
    $WHERE = "WHERE id='$attr->{LOGIN}'";
    $PASSWORD = "if(DECODE(password, '$SECRETKEY')='$attr->{PASSWORD}', 0, 1)";
   }
  else {
    $WHERE = "WHERE aid='$aid'";
   }

  $IP = (defined($attr->{IP}))? $attr->{IP} : '0.0.0.0';
  $self->query($db, "SELECT aid, id, name, regdate, phone, disable, $PASSWORD FROM admins $WHERE;");

  if ($self->{TOTAL} < 1) {
     $self->{errno} = 2;
     $self->{errstr} = 'Not exist';
     return $self;
   }

  my $a_ref = $self->{list}->[0];
  if ($a_ref->[6] == 1) {
     $self->{errno} = 4;
     $self->{errstr} = 'ERROR_WRONG_PASSWORD';
     return $self;
   }

  ($self->{AID},
   $self->{A_LOGIN},
   $self->{A_FIO},
   $self->{A_REGISTRATION},
   $self->{A_PHONE},
   $self->{DISABLE} )= @$a_ref;

  $self->{SESSION_IP}  = $IP;

  return $self;
}

#**********************************************************
# list()
#**********************************************************
sub list {
 my $self = shift;
 $self->query($db, "select aid, id, name, regdate, disable, gid FROM admins;");
 return $self->{list};
}

#**********************************************************
# list()
#**********************************************************
sub change {
 my $self = shift;
 my ($attr) = @_;
 
 %DATA = $self->get_data($attr); 
 
 my $CHANGES_QUERY = "";
 my $CHANGES_LOG = "Tarif plan:";

 my %FIELDS = (AID =>   'aid',
           A_LOGIN => 'id',
           A_FIO => 'name',
           A_REGISTRATION => 'regdate',
           A_PHONE => 'phone',
           DISABLE => 'disable'
   );
 my $OLD = $self->info($self->{AID});

 while(my($k, $v)=each(%DATA)) {
    if ($OLD->{$k} ne $DATA{$k}){
      if ($FIELDS{$k}) {
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
  $self->query($db, "UPDATE admins SET $CHANGES_QUERY
    WHERE aid='$self->{AID}'", 'do');
#  $admin->action_add(0, "$CHANGES_LOG");

  $self->info($self->{AID});
  
  
	return $self;
}


#**********************************************************
# add()
#**********************************************************
sub add {
  my $self = shift;
  my ($attr) = @_;
  %DATA = $self->get_data($attr); 
  $self->query($db, "INSERT INTO admins (id, name, regdate, phone, disable) 
   VALUES ('$DATA{A_LOGIN}', '$DATA{A_FIO}', now(),  '$DATA{A_PHONE}', '$DATA{DISABLE}');", 'do');

  return $self;
}


#**********************************************************
# add()
#**********************************************************
sub del {
  my $self = shift;
  my ($id) = @_;
  $self->query($db, "DELETE FROM admins WHERE aid='$id';", 'do');
  return $self;
}


#**********************************************************
#  action_add()
#**********************************************************
sub action_add {
  my $self = shift;
  my ($uid, $actions) = @_;
  $self->query($db, "INSERT INTO admin_actions (aid, ip, datetime, actions, uid) VALUES ('$self->{AID}', INET_ATON('$IP'), now(), '$actions', '$uid')", 'do');
  return $self;
}

#**********************************************************
#  action_del()
#**********************************************************
sub action_del {
  my $self = shift;
  my ($action_id) = @_;
  $self->query($db, "DELETE FROM admin_actions WHERE id='$action_id';", 'do');
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

  $self->query($db, "select aa.id, u.id, aa.datetime, aa.actions, a.id, INET_NTOA(aa.ip), aa.uid, aa.aid, aa.id
      FROM admin_actions aa
      LEFT JOIN admins a ON (aa.aid=a.aid)
      LEFT JOIN users u ON (aa.uid=u.uid)
       $WHERE ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;");
  
  
  my $list = $self->{list};
  
  if ($self->{TOTAL} > 0) {
    $self->query($db, "SELECT count(*) FROM admin_actions aa $WHERE;");
    my $a_ref = $self->{list}->[0];
    ($self->{TOTAL}) = @$a_ref;
   }


  return $list;
}

#**********************************************************
# password()
#**********************************************************
sub password {
  my $self = shift;
  my ($password, $attr)=@_;

  my $secretkey = (defined($attr->{secretkey}))? $attr->{secretkey} : '';
  $self->query($db, "UPDATE admins SET password=ENCODE('$password', '$secretkey') WHERE aid='$aid';", 'do');

  return $self;
}


#**********************************************************
# Online Administrators
#**********************************************************
sub online {
	my $self = shift;
  my $time_out = 120;
  my $online_users = '';
  my %curuser = ();

 $self->query($db, "DELETE FROM web_online WHERE UNIX_TIMESTAMP()-logtime>$time_out;", 'do');

 $self->query($db, "SELECT admin, ip FROM web_online;");

 my $online_count = $self->{TOTAL} + 0;
 my $list = $self->{list};
 foreach my $row (@$list) {
	 $online_users .= "$row->[0] - $row->[1]\n";
   $curuser{"$row->[0]"}="$row->[1]" if ($row->[0] eq $self->{A_LOGIN} && $row->[1] eq $self->{SESSION_IP});
  }

 if ($curuser{"$self->{A_LOGIN}"} ne $self->{SESSION_IP}) {
   $self->query($db, "INSERT INTO web_online (admin, ip, logtime)
     values ('$self->{A_LOGIN}', '$self->{SESSION_IP}', UNIX_TIMESTAMP());", 'do');
   $online_users .= "$self->{A_LOGIN} - $self->{SESSION_IP};\n";
   $online_count++;
  }


 return ($online_users, $online_count);
}

1
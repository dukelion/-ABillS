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
  ($db, $CONF) = @_;
  my $self = { };
  bless($self, $class);

  return $self;
}

#**********************************************************
# admins_groups_list()
#**********************************************************
sub admins_groups_list {
	my $self = shift;
	my ($attr) = @_;
	
	if ($attr->{ALL}) {

	 }
	else {
    $WHERE = ($attr->{AID}) ? "AND ag.aid='$attr->{AID}'" : "AND ag.aid='$self->{AID}'";
   }

  $self->query($db, "SELECT ag.gid, ag.aid, g.name 
    FROM admins_groups ag, groups g
    WHERE g.gid=ag.gid $WHERE;");

  return $self->{list};
}


#**********************************************************
# admins_groups_list()
#**********************************************************
sub admin_groups_change {
	my $self = shift;
	my ($attr) = @_;

  
  $self->query($db, "DELETE FROM admins_groups WHERE aid='$self->{AID}';", 'do');
  my @groups = split(/,/, $attr->{GID});

  foreach my $gid (@groups) {
    $self->query($db, "INSERT INTO admins_groups (aid, gid) VALUES ('$attr->{AID}', '$gid');", 'do');
   }

	return $self;
}


#**********************************************************
# get_permissions()
#**********************************************************
sub get_permissions {
  my $self = shift;
  my %permissions = ();

$self->query($db, "SELECT section, actions FROM admin_permits WHERE aid='$self->{AID}';");

foreach my $line (@{ $self->{list} }) {
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
  my ($aid, $attr) = @_;

  my $PASSWORD = '0'; 
  my $WHERE;
  
  if (defined($attr->{LOGIN}) && defined($attr->{PASSWORD})) {
    my $SECRETKEY = (defined($attr->{SECRETKEY}))? $attr->{SECRETKEY} : '';
    $WHERE = "WHERE a.id='$attr->{LOGIN}'";
    $PASSWORD = "if(DECODE(a.password, '$SECRETKEY')='$attr->{PASSWORD}', 0, 1)";
   }
  else {
    $WHERE = "WHERE a.aid='$aid'";
   }

  $IP = (defined($attr->{IP}))? $attr->{IP} : '0.0.0.0';
  $self->query($db, "SELECT a.aid, a.id, a.name, a.regdate, a.phone, a.disable, a.web_options, a.gid, 
     count(ag.aid),
     email,
     $PASSWORD
     FROM 
      admins a
     LEFT JOIN  admins_groups ag ON (a.aid=ag.aid)
     $WHERE
     GROUP BY a.aid;");

  if ($self->{TOTAL} < 1) {
     $self->{errno} = 2;
     $self->{errstr} = 'Not exist';
     return $self;
   }

  my $a_ref = $self->{list}->[0];
  if ($a_ref->[10] == 1) {
     $self->{errno} = 4;
     $self->{errstr} = 'ERROR_WRONG_PASSWORD';
     return $self;
   }

  ($self->{AID},
   $self->{A_LOGIN},
   $self->{A_FIO},
   $self->{A_REGISTRATION},
   $self->{A_PHONE},
   $self->{DISABLE},
   $self->{WEB_OPTIONS},
   $self->{GID},
   $self->{GIDS},
   $self->{EMAIL}
    )= @$a_ref;
  
  if ($self->{GIDS} > 0) {
	  $self->query($db, "SELECT gid  FROM admins_groups WHERE aid='$self->{AID}';");
	  $self->{GIDS}='';
	  foreach my $line (@{ $self->{list} }) {
	  	$self->{GIDS} .= $line->[0]. ', ';
	   }
    $self->{GIDS}.=$self->{GID};
   }

   $self->{SESSION_IP}  = $IP;

  return $self;
}

#**********************************************************
# list()
#**********************************************************
sub list {
 my $self = shift;
 my ($attr) = @_;

 @WHERE_RULES = ();
 if ($attr->{GIDS}) {
 	 push @WHERE_RULES, "a.gid IN ($attr->{GIDS})";
  }
 elsif ($attr->{GID}) {
   push @WHERE_RULES, "a.gid='$attr->{GID}'";
  }
 
 $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';
 
 $self->query($db, "select a.aid, a.id, a.name, a.regdate, a.disable, g.name 
 FROM admins a
  LEFT JOIN groups g ON (a.gid=g.gid) 
 $WHERE
 ORDER BY $SORT $DESC;");

 return $self->{list};
}

#**********************************************************
# list()
#**********************************************************
sub change {
 my $self = shift;
 my ($attr) = @_;
  my %FIELDS = (AID    =>   'aid',
           A_LOGIN     => 'id',
           A_FIO       => 'name',
           A_REGISTRATION => 'regdate',
           A_PHONE     => 'phone',
           DISABLE     => 'disable',
           PASSWORD    => 'password',
           WEB_OPTIONS => 'web_options',
           GID         => 'gid',
           EMAIL       => 'email'
   );


 

 $self->changes($admin, { CHANGE_PARAM => 'AID',
		                      TABLE        => 'admins',
		                      FIELDS       => \%FIELDS,
		                      OLD_INFO     => $self->info($self->{AID}),
		                      DATA         => $attr
		                     } );



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

  $self->query($db, "INSERT INTO admins (id, name, regdate, phone, disable, gid, email) 
   VALUES ('$DATA{A_LOGIN}', '$DATA{A_FIO}', now(),  '$DATA{A_PHONE}', '$DATA{DISABLE}', '$DATA{GID}', '$DATA{EMAIL}');", 'do');

  return $self;
}


#**********************************************************
# delete()
#**********************************************************
sub del {
  my $self = shift;
  my ($id) = @_;

  $self->query($db, "DELETE FROM admins WHERE aid='$id';", 'do');
  $self->query($db, "DELETE FROM admin_permits WHERE aid='$id';", 'do');
  return $self;
}


#**********************************************************
#  action_add()
#**********************************************************
sub action_add {
  my $self = shift;
  my ($uid, $actions, $attr) = @_;
  
  my $MODULE = (defined($self->{MODULE})) ? $self->{MODULE} : '';
  
  $self->query($db, "INSERT INTO admin_actions (aid, ip, datetime, actions, uid, module) 
    VALUES ('$self->{AID}', INET_ATON('$IP'), now(), '$actions', '$uid', '$MODULE')", 'do');
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
  
  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my @list = ();
  @WHERE_RULES = ();
  $WHERE='';

  # UID
  if ($attr->{UID}) {
    push @WHERE_RULES, "aa.uid='$attr->{UID}'";
   }
  if ($attr->{AID}) {
    push @WHERE_RULES, "aa.aid='$attr->{AID}'";
   }
  elsif($attr->{ADMIN}) {
  	$attr->{ADMIN} =~ s/\*/\%/ig;
    push @WHERE_RULES, "a.id LIKE '$attr->{ADMIN}'";
   }

 # Start letter 
 if ($attr->{FIRST_LETTER}) {
    push @WHERE_RULES, "u.id LIKE '$attr->{FIRST_LETTER}%'";
  }
 elsif ($attr->{LOGIN}) {
    $attr->{LOGIN_EXPR} =~ s/\*/\%/ig;
    push @WHERE_RULES, "u.id='$attr->{LOGIN}'";
  }
 # Login expresion
 elsif ($attr->{LOGIN_EXPR}) {
    $attr->{LOGIN_EXPR} =~ s/\*/\%/ig;
    push @WHERE_RULES, "u.id LIKE '$attr->{LOGIN_EXPR}'";
  }
 
 if ($attr->{ACTION}) {
 	 $attr->{ACTION} =~ s/\*/\%/ig;
 	 push @WHERE_RULES, "aa.actions LIKE '$attr->{ACTION}'";
  }    

 # Date intervals
 if ($attr->{FROM_DATE}) {
   push @WHERE_RULES, "(date_format(aa.datetime, '%Y-%m-%d')>='$attr->{FROM_DATE}' and date_format(aa.datetime, '%Y-%m-%d')<='$attr->{TO_DATE}')";
  }

 if ($attr->{MODULE}) {
   push @WHERE_RULES, "aa.module='$attr->{MODULE}'";
  }

 if ($attr->{GIDS}) {
   push @WHERE_RULES, "a.gid IN ($attr->{GIDS})";
  }
 elsif ($attr->{GID}) {
   push @WHERE_RULES, "a.gid='$attr->{GID}'";
  }


  $WHERE = "WHERE " . join(' and ', @WHERE_RULES) if ($#WHERE_RULES > -1);

  $self->query($db, "select aa.id, u.id, aa.datetime, aa.actions, a.id, INET_NTOA(aa.ip), aa.module, aa.uid, aa.aid, aa.id
      FROM admin_actions aa
      LEFT JOIN admins a ON (aa.aid=a.aid)
      LEFT JOIN users u ON (aa.uid=u.uid)
      $WHERE ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;");
  
  my $list = $self->{list};
  
  $self->query($db, "SELECT count(*) FROM admin_actions aa 
    LEFT JOIN users u ON (aa.uid=u.uid)
    LEFT JOIN admins a ON (aa.aid=a.aid)
    $WHERE;");
    ($self->{TOTAL}) = @{ $self->{list}->[0] };

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
   $curuser{"$row->[0]"}="$row->[1]" if ($row->[0] eq $self->{A_LOGIN});
  }

 if ($curuser{$self->{A_LOGIN}} ne $self->{SESSION_IP}) {
   $self->query($db, "INSERT INTO web_online (admin, ip, logtime)
     values ('$self->{A_LOGIN}', '$self->{SESSION_IP}', UNIX_TIMESTAMP());", 'do');
   $online_users .= "$self->{A_LOGIN} - $self->{SESSION_IP};\n";
   $online_count++;
  }


 return ($online_users, $online_count);
}

1

package Admins;
# Administrators manage functions
#

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION
);

use Exporter;
$VERSION = 2.05;
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

	$WHERE = '';

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

  $self->system_action_add("AID:$attr->{AID} GID: ". (join(',', @groups)), { TYPE => 2 });
	return $self;
}


#**********************************************************
# get_permissions()
#**********************************************************
sub get_permissions {
  my $self = shift;
  my %permissions = ();

$self->query($db, "SELECT section, actions, module FROM admin_permits WHERE aid='$self->{AID}';");

foreach my $line (@{ $self->{list} }) {
  my($section, $action, $module)=@$line;
  $permissions{$section}{$action} = 1;
  if ($module) {
  	$self->{MODULES}{$module}=1;
   }
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
    	my ($perms, $module)=split(/_/, $action);
      $self->query($db, "INSERT INTO admin_permits (aid, section, actions, module) 
      VALUES ('$self->{AID}', '$section', '$perms', '$module');", 'do');
     }
   }
  
  $self->{CHANGED_AID}=$self->{AID};
  $self->{AID}=$self->{MAIN_AID};
  $IP=$self->{MAIN_SESSION_IP};  
  
  $self->system_action_add("AID:$self->{CHANGED_AID} PERMISION:", { TYPE => 2 });
  $self->{AID}= $self->{CHANGED_AID};
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
  elsif($attr->{DOMAIN_ID}) {
  	$WHERE = "WHERE a.domain_id='$attr->{DOMAIN_ID}'";
   }
  else {
    $WHERE = "WHERE a.aid='$aid'";
   }

  $IP = ($attr->{IP}) ? $attr->{IP} : '0.0.0.0';
  $self->query($db, "SELECT a.aid, a.id, a.name, a.regdate, a.phone, a.disable, a.web_options, a.gid, 
     count(ag.aid),
     a.email,
     a.comments,
     a.domain_id,
     d.name,
     a.min_search_chars,
     a.max_rows,
     a.address,
     a.cell_phone,
     a.pasport_num,
     a.pasport_date,
     a.pasport_grant,
     a.inn,
     a.birthday,
     $PASSWORD
     FROM 
      admins a
     LEFT JOIN  admins_groups ag ON (a.aid=ag.aid)
     LEFT JOIN  domains d ON (a.domain_id=d.id)
     $WHERE
     GROUP BY a.aid
     ORDER BY a.aid DESC
     LIMIT 1;");

  if ($self->{TOTAL} < 1) {
     $self->{errno} = 2;
     $self->{errstr}= 'Not exist';
     $self->{AID}   = 0;
     return $self;
   }

  my $a_ref = $self->{list}->[0];
  if ($a_ref->[22] == 1) {
     $self->{errno}  = 4;
     $self->{errstr} = 'ERROR_WRONG_PASSWORD';
     $self->{AID}    = $a_ref->[0],
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
   $self->{EMAIL},
   $self->{A_COMMENTS},
   $self->{DOMAIN_ID},
   $self->{DOMAIN_NAME},
   $self->{MIN_SEARCH_CHARS},
 	 $self->{MAX_ROWS},
 	 $self->{ADDRESS},
 	 $self->{CELL_PHONE},
 	 $self->{PASPORT_NUM},
 	 $self->{PASPORT_DATE},
 	 $self->{PASPORT_GRANT},
 	 $self->{INN},
 	 $self->{BIRTHDAY},
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

 if ($self->{DOMAIN_ID}) {
 	 push @WHERE_RULES, "a.domain_id IN ($self->{DOMAIN_ID})";
  }
 elsif ($attr->{DOMAIN_ID}) {
 	 push @WHERE_RULES, "a.domain_id IN ($attr->{DOMAIN_ID})";
  }

 
 $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';
 
 $self->query($db, "select a.aid, a.id, a.name, a.regdate, a.disable, g.name, d.name 
 FROM admins a
  LEFT JOIN groups g ON (a.gid=g.gid) 
  LEFT JOIN domains d ON (d.id=a.domain_id) 
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
           EMAIL       => 'email',
           A_COMMENTS  => 'comments',
           DOMAIN_ID   => 'domain_id',
           MIN_SEARCH_CHARS => 'min_search_chars',
 	         MAX_ROWS    => 'max_rows',           
           ADDRESS     => 'address',
           CELL_PHONE  => 'cell_phone',
           PASPORT_NUM   =>'pasport_num',
           PASPORT_DATE  => 'pasport_date',
           PASPORT_GRANT => 'pasport_grant',
           INN           => 'inn',
           BIRTHDAY      => 'birthday'           
   );
 
  if (! $attr->{A_LOGIN}) {
  	delete $FIELDS{A_LOGIN};
   }
 
  $admin->{MODULE}='';
  $IP   = $admin->{SESSION_IP};
  $attr->{DISABLE}=0 if (! $attr->{DISABLE} && $attr->{A_LOGIN});
  
  $self->changes($admin, { CHANGE_PARAM => 'AID',
		                       TABLE        => 'admins',
		                       FIELDS       => \%FIELDS,
		                       OLD_INFO     => $self->info($self->{AID}, { IP => $admin->{SESSION_IP} }),
		                       DATA         => $attr,
		                       EXT_CHANGE_INFO  => "AID:$self->{AID}"
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

  $self->query($db, "INSERT INTO admins (id, name, regdate, phone, disable, gid, email, comments, password, domain_id,
  min_search_chars, max_rows,
  address, cell_phone, pasport_num, pasport_date, pasport_grant, inn, birthday) 
   VALUES ('$DATA{A_LOGIN}', '$DATA{A_FIO}', now(),  '$DATA{A_PHONE}', '$DATA{DISABLE}', '$DATA{GID}', 
   '$DATA{EMAIL}', '$DATA{A_COMMENTS}', '$DATA{PASSWORD}', '$DATA{DOMAIN_ID}',
   '$DATA{MIN_SEARCH_CHARS}', '$DATA{MAX_ROWS}',
   '$DATA{ADDRESS}', '$DATA{CELL_PHONE}', '$DATA{PASPORT_NUM}', '$DATA{PASPORT_DATE}', '$DATA{PASPORT_GRANT}', '$DATA{INN}', '$DATA{BIRTHDAY}');", 'do');

  $self->{AID}=$self->{INSERT_ID};

  $self->system_action_add("AID:$self->{INSERT_ID} LOGIN:$DATA{A_LOGIN}", { TYPE => 1 });  
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
  
  $self->system_action_add("AID:$id", { TYPE => 10 });  
  return $self;
}


#**********************************************************
#  action_add()
#**********************************************************
sub action_add {
  my $self = shift;
  my ($uid, $actions, $attr) = @_;
  
  my $MODULE = (defined($self->{MODULE})) ? $self->{MODULE} : '';
  my $action_type = ($attr->{TYPE}) ? $attr->{TYPE} : '';
  
  if ($attr->{ACTION_COMMENTS}) {
  	$actions .= ":$attr->{ACTION_COMMENTS}";
   }

  $IP = $attr->{IP} if ($attr->{IP});

  $self->query($db, "INSERT INTO admin_actions (aid, ip, datetime, actions, uid, module, action_type) 
    VALUES ('$self->{AID}', INET_ATON('$IP'), now(), '$actions', '$uid', '$MODULE', '$action_type')", 'do');
  return $self;
}


#**********************************************************
#  action_del()
#**********************************************************
sub action_info {
  my $self = shift;
  my ($id) = @_;

  $self->query($db, "SELECT aid, INET_NTOA(ip), datetime, actions, uid, module, action_type 
    FROM admin_actions WHERE id='$id';");

  ($self->{AID},
   $self->{IP}, 
   $self->{DATETIME}, 
   $self->{ACTION}, 
   $self->{UID},
   $self->{MODULES},
   $self->{ACTION_TYPE}
  )= @{ $self->{list}->[0] };  
 
  return $self;
}


#**********************************************************
#  action_del()
#**********************************************************
sub action_del {
  my $self = shift;
  my ($id) = @_;

  $self->action_info($id);

  if ($self->{TOTAL} > 0) {
    $self->query($db, "DELETE FROM admin_actions WHERE id='$id';", 'do');
    $self->system_action_add("ACTION:$id DATETIME:$self->{DATETIME} UID:$self->{UID} CHANGED:$self->{ACTION}", { TYPE => 10 });    
   }
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
    push @WHERE_RULES, @{ $self->search_expr($attr->{ADMIN}, 'STR', 'a.id') };
   }
 # Start letter 
  elsif ($attr->{LOGIN}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{LOGIN}, 'STR', 'u.id') };
   }

  
 if ($attr->{ACTION}) {
 	 push @WHERE_RULES, @{ $self->search_expr($attr->{ACTION}, 'STR', 'aa.actions') };
  }    

 if (defined($attr->{TYPE}) && $attr->{TYPE} ne '') {
 	 push @WHERE_RULES, @{ $self->search_expr($attr->{TYPE}, 'INT', 'aa.action_type') };
  }    


 # Date intervals
 if ($attr->{FROM_DATE}) {
   push @WHERE_RULES, "(date_format(aa.datetime, '%Y-%m-%d')>='$attr->{FROM_DATE}' and date_format(aa.datetime, '%Y-%m-%d')<='$attr->{TO_DATE}')";
  }
 
 if ($attr->{MODULE}) {
   push @WHERE_RULES, "aa.module='$attr->{MODULE}'";
  }


 if ($attr->{GID} || $attr->{GIDS}) {
 	 $attr->{GIDS} = $attr->{GID} if (! $attr->{GIDS});
 	 my @system_admins=();
 	 push @system_admins, $CONF->{USERS_WEB_ADMIN_ID} if ($CONF->{USERS_WEB_ADMIN_ID});
 	 push @system_admins, $CONF->{SYSTEM_ADMIN_ID} if ($CONF->{SYSTEM_ADMIN_ID});
 	 my $system_admins = ''; 
 	 my $users_gid     = ''; 
 	 if (! $attr->{ADMIN} && ! $attr->{AID}) {
 	   $system_admins = "or a.aid IN (". join(',', @system_admins) .")";
 	   $users_gid     = "u.gid IN ($attr->{GIDS}) AND"; 
 	  }
   push @WHERE_RULES, "($users_gid (a.gid IN ($attr->{GIDS}) $system_admins))";
  }


  $WHERE = "WHERE " . join(' and ', @WHERE_RULES) if ($#WHERE_RULES > -1);

  $self->query($db, "select aa.id, u.id, aa.datetime, aa.actions, a.id, INET_NTOA(aa.ip), aa.module, 
      aa.action_type,
      aa.uid, aa.aid, aa.id
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
#  system_action_add()
#**********************************************************
sub system_action_add {
  my $self = shift;
  my ($actions, $attr) = @_;
  
  my $MODULE = (defined($self->{MODULE})) ? $self->{MODULE} : '';
  my $action_type = ($attr->{TYPE}) ? $attr->{TYPE} : '';
  #$IP = ($attr->{IP}) ? $attr->{IP} : '0.0.0.0';

  $self->query($db, "INSERT INTO admin_system_actions (aid, ip, datetime, actions, module, action_type) 
    VALUES ('$self->{AID}', INET_ATON('$IP'), now(), '$actions', '$MODULE', '$action_type')", 'do');
  return $self;
}

#**********************************************************
#  system_action_del()
#**********************************************************
sub system_action_del {
  my $self = shift;
  my ($action_id) = @_;
  $self->query($db, "DELETE FROM admin_system_actions WHERE id='$action_id';", 'do');
}


#**********************************************************
#  system_action_list()
#**********************************************************
sub system_action_list {
  my $self = shift;
  my ($attr) = @_;
  
  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my @list = ();
  @WHERE_RULES = ();
  $WHERE='';

  if ($attr->{AID}) {
    push @WHERE_RULES, "aa.aid='$attr->{AID}'";
   }
  elsif($attr->{ADMIN}) {
  	$attr->{ADMIN} =~ s/\*/\%/ig;
    push @WHERE_RULES, "a.id LIKE '$attr->{ADMIN}'";
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

 if (defined($attr->{TYPE}) && $attr->{TYPE} ne '') {
 	 push @WHERE_RULES, @{ $self->search_expr($attr->{TYPE}, 'INT', 'aa.action_type') };
  }    

 if ($attr->{GIDS}) {
   push @WHERE_RULES, "a.gid IN ($attr->{GIDS})";
  }
 elsif ($attr->{GID}) {
   push @WHERE_RULES, "a.gid='$attr->{GID}'";
  }


  $WHERE = "WHERE " . join(' and ', @WHERE_RULES) if ($#WHERE_RULES > -1);

  $self->query($db, "select aa.id, aa.datetime, aa.actions, a.id, INET_NTOA(aa.ip), aa.module, 
      aa.action_type,
      aa.aid
   FROM admin_system_actions aa
      LEFT JOIN admins a ON (aa.aid=a.aid)
      $WHERE ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;");
  
  my $list = $self->{list};
  
  $self->query($db, "SELECT count(*) FROM admin_system_actions aa 
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

  $self->system_action_add("AID:$self->{INSERT_ID} PASSWORD:****", { TYPE => 2 });  
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











=comments

#**********************************************************
# allow_ip_list()
#**********************************************************
sub allow_ip_list {
 my $self = shift;
 my ($attr) = @_;

 @WHERE_RULES = ();
 
 if ($attr->{IP}) {
 	 push @WHERE_RULES, "aip.ip=INET_ATON('$attr->{IP}')";
  }
 
 if ($attr->{AID}) {
   push @WHERE_RULES, "aip.aid='$attr->{AID}'";
  }

 
 $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';
 
 $self->query($db, "SELECT INET_NTOA(aip.ip)
 FROM admins_allow_ips aip
 $WHERE
 ORDER BY $SORT $DESC;");

 return $self->{list};
}



#**********************************************************
# add()
#**********************************************************
sub allow_ip_add {
  my $self = shift;
  my ($attr) = @_;
  %DATA = $self->get_data($attr); 

  $self->query($db, "INSERT INTO admins_allow_ips (ip) 
   VALUES ('$DATA{AID}', INET_ATON('$DATA{IP}'));", 'do');

  if ($self->{errno}) {
  	return $self;
   }

  $self->system_action_add("ALLOW IP: $DATA{IP}", { TYPE => 1 });  
  return $self;
}


#**********************************************************
# delete()
#**********************************************************
sub allow_ip_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query($db, "DELETE FROM admins_allow_ips WHERE ip=INET_ATON('$attr->{IP}');", 'do');
  
  $self->system_action_add("ALLOW IP: $attr->{IP}", { TYPE => 10 });  
  return $self;
}


=cut











1

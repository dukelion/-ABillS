package Msgs; 
# Message system 
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

use main;
@ISA  = ("main");

my $MODULE='Msgs';

#**********************************************************
# Init 
#**********************************************************
sub new {
  my $class = shift;
  ($db, $admin, $CONF) = @_;
  $admin->{MODULE}=$MODULE;
  my $self = { };

  bless($self, $class);
  return $self;
}


#**********************************************************
# messages_new
#**********************************************************
sub messages_new {
  my $self = shift;
  my ($attr) = @_;

 my @WHERE_RULES = ();
 my $EXT_TABLE   = '';
 my $fields = '';
 
 if ($attr->{USER_READ}) {
   push @WHERE_RULES, "m.user_read='$attr->{USER_READ}' AND admin_read>'0000-00-00 00:00:00' AND m.inner_msg='0'"; 
   $fields='count(*), \'\', \'\', max(m.id), m.chapter, m.id, 1';
  }
 elsif ($attr->{ADMIN_READ}) {
 	 $fields = "sum(if(admin_read='0000-00-00 00:00:00', 1, 0)), 
 	  sum(if(plan_date=curdate(), 1, 0)),
 	  sum(if(state = 0, 1, 0)), 
    1, 1,1,1
 	   ";
   #push @WHERE_RULES, "m.state=0";
  }

 if ($attr->{UID}) {
   push @WHERE_RULES, "m.uid='$attr->{UID}'"; 
 }

 if ($attr->{CHAPTERS}) {
   push @WHERE_RULES, "c.id IN ($attr->{CHAPTERS})"; 
  }

 if ($attr->{GIDS}) {
   push @WHERE_RULES, "u.gid IN ($attr->{GIDS})"; 
   $EXT_TABLE =  "LEFT JOIN users u  ON (m.uid = u.uid)";
 }


 $WHERE = ($#WHERE_RULES > -1) ? 'WHERE '. join(' and ', @WHERE_RULES)  : '';

 if ($attr->{SHOW_CHAPTERS}) {
   $self->query($db,   "SELECT c.id, c.name, sum(if(admin_read='0000-00-00 00:00:00', 1, 0)), 
 	  sum(if(plan_date=curdate(), 1, 0)),
 	  sum(if(state = 0, 1, 0)), 
 	   	  sum(if(resposible = $admin->{AID}, 1, 0)),1,1,1
    FROM msgs_chapters c
    LEFT JOIN msgs_messages m ON (m.chapter= c.id AND m.state=0)
    $EXT_TABLE
   $WHERE 
   GROUP BY c.id;");
   return $self->{list};
  }


 if ($attr->{GIDS}) {
   $self->query($db,   "SELECT $fields 
    FROM (msgs_messages m, users u)
   $WHERE and u.uid=m.uid GROUP BY 7Y;");
  }
 else {
   $self->query($db,   "SELECT $fields 
    FROM (msgs_messages m)
   $WHERE GROUP BY 7;");
  }

if ($self->{TOTAL}){
 ($self->{UNREAD}, $self->{TODAY}, $self->{OPENED}, $self->{LAST_ID}, $self->{CHAPTER}, $self->{MSG_ID}) = @{ $self->{list}->[0] };
}

  return $self;	
}

#**********************************************************
# messages_list
#**********************************************************
sub messages_list {
 my $self = shift;
 my ($attr) = @_;

 $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;
 $SORT      = ($attr->{SORT}) ? $attr->{SORT} : 1;
 $DESC      = (defined($attr->{DESC})) ? $attr->{DESC} : 'DESC';
 $PG        = (defined($attr->{PG})) ? $attr->{PG} : 0;

 @WHERE_RULES = ();
 
 if($attr->{LOGIN}) {
	 push @WHERE_RULES, @{ $self->search_expr($attr->{LOGIN}, 'STR', 'u.id') };
  }
 
 if ($attr->{DATE}) {
   push @WHERE_RULES, "date_format(m.date, '%Y-%m-%d')='$attr->{DATE}'";
  } 
 elsif ($attr->{FROM_DATE}) {
   push @WHERE_RULES, "(date_format(m.date, '%Y-%m-%d')>='$attr->{FROM_DATE}' and date_format(m.date, '%Y-%m-%d')<='$attr->{TO_DATE}')";
  }

 if (defined($attr->{INNER_MSG})) {
 	 push @WHERE_RULES, "m.inner_msg='$attr->{INNER_MSG}'"; 
  }

 if ($attr->{PLAN_FROM_DATE}) {
    push @WHERE_RULES, "(date_format(m.plan_date, '%Y-%m-%d')>='$attr->{PLAN_FROM_DATE}' and date_format(m.plan_date, '%Y-%m-%d')<='$attr->{PLAN_TO_DATE}')";
  }
 elsif ($attr->{PLAN_WEEK}) {
    push @WHERE_RULES, "(WEEK(m.plan_date)=WEEK(curdate()) and date_format(m.plan_date, '%Y')=date_format(curdate(), '%Y'))";
  }
 elsif ($attr->{PLAN_MONTH}) {
    push @WHERE_RULES, "date_format(m.plan_date, '%Y-%m')=date_format(curdate(), '%Y-%m')";
  }

 if ($attr->{MSG_ID}) {
 	  push @WHERE_RULES,  @{ $self->search_expr($attr->{MSG_ID}, 'INT', 'm.id') };
  }

 if (defined($attr->{SUBJECT})) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{SUBJECT}, 'STR', 'm.subject') };
  }

 if ($attr->{DELIGATION}) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{DELIGATION}, 'INT', 'm.delegation') };
  }

 if ($attr->{MESSAGE}) {
 	 push @WHERE_RULES, @{ $self->search_expr($attr->{MESSAGE}, 'STR', 'm.message') };
  }
 elsif (defined($attr->{REPLY})) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{USER_READ}, 'STR', 'm.user_read') };
  }

 if (defined($attr->{PHONE})) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{PHONE}, 'STR', 'm.phone') };
  }

 # Show groups
 if ($attr->{GIDS}) {
   push @WHERE_RULES, "(u.gid IN ($attr->{GIDS}) OR m.aid='$admin->{AID}')"; 
  }
 elsif ($attr->{GID}) {
   push @WHERE_RULES, "(u.gid='$attr->{GID}' OR m.aid='$admin->{AID}')"; 
  }

 if ($attr->{USER_READ}) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{USER_READ}, 'INT', 'm.user_read') };
  }

 if ($attr->{ADMIN_READ}) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{ADMIN_READ}, 'INT', 'm.admin_read') };
  }

 if ($attr->{CLOSED_DATE}) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{CLOSED_DATE}, 'INT', 'm.closed_date') };
  }

 if ($attr->{DONE_DATE}) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{DONE_DATE}, 'INT', 'm.done_date') };
  }

 if ($attr->{REPLY_COUNT}) {
   #push @WHERE_RULES, "r.admin_read='$attr->{ADMIN_READ}'";
  }

 if ($attr->{CHAPTERS_DELIGATION}) {
 	 my @WHERE_RULES_pre = ();
 	 while( my ($chapter, $deligation) =  each %{ $attr->{CHAPTERS_DELIGATION} } ) {
 	 	 my $privileges = '';
 	 	 if ($attr->{PRIVILEGES}) {
 	 	 	 if ($attr->{PRIVILEGES}->{$chapter} <= 2) {
 	 	 	 	  $privileges = " AND (m.resposible=0 or m.aid='$admin->{AID}' or m.resposible='$admin->{AID}')"
 	 	 	  }
 	 	  }
 	   push @WHERE_RULES_pre, "(m.chapter='$chapter' AND m.deligation<='$deligation' $privileges)";
 	  }
   push @WHERE_RULES,  "(". join(" or ", @WHERE_RULES_pre) .")";
  }
 elsif ($attr->{CHAPTERS}) {
   push @WHERE_RULES, "m.chapter IN ($attr->{CHAPTERS})"; 
  }
 
 if ($attr->{CHAPTER}) {
 	 push @WHERE_RULES, "m.chapter='$attr->{CHAPTER}'"; 
  }
 
 if ($attr->{UID}) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{UID}, 'INT', 'm.uid') };
 }

 
 if (defined($attr->{STATE})) {
   if ($attr->{STATE} == 4) {
   	 push @WHERE_RULES, @{ $self->search_expr('0000-00-00 00:00:00', 'INT', 'm.admin_read') };
    }
   elsif ($attr->{STATE} == 7) {
     push @WHERE_RULES, @{ $self->search_expr(">0", 'INT', 'm.deligation')  };
    }
   elsif ($attr->{STATE} == 8) {
     push @WHERE_RULES, @{ $self->search_expr("$admin->{AID}", 'INT', 'm.resposible')  };
    }
   else {
     push @WHERE_RULES, @{ $self->search_expr($attr->{STATE}, 'INT', 'm.state')  };
    }
  }

 if ($attr->{PRIORITY}) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{PRIORITY}, 'INT', 'm.state') };
  }

 if ($attr->{PLAN_DATE}) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{PLAN_DATE}, 'INT', 'm.plan_date') };
  }

 if ($attr->{PLAN_TIME}) {
   push @WHERE_RULES,  @{ $self->search_expr($attr->{PLAN_TIME}, 'INT', 'm.plan_time') };
  }

 if ($attr->{DISPATCH_ID}) {
   push @WHERE_RULES,  @{ $self->search_expr($attr->{DISPATCH_ID}, 'INT', 'm.dispatch_id') };
  }
 
 my $EXT_JOIN = ''; 

 if ($attr->{IP}) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{IP}, 'IP', 'm.ip') };
   $self->{SEARCH_FIELDS} = 'INET_NTOA(m.ip), ';
   $self->{SEARCH_FIELDS_COUNT}++;
  }

 if ($attr->{FULL_ADDRESS}) {
 	 $EXT_JOIN = 'LEFT JOIN users_pi pi ON (u.uid=pi.uid) ';
   $self->{SEARCH_FIELDS} = 'pi.fio, CONCAT(pi.address_street, \' \', pi.address_build, \'/\', pi.address_flat), pi.phone, ';
   $self->{SEARCH_FIELDS_COUNT} += 3;
  }

 if ($attr->{SHOW_TEXT}) {
   $self->{SEARCH_FIELDS} .= 'm.message, ';
   $self->{SEARCH_FIELDS_COUNT}++;
  }

 if ($attr->{PASSWORD}) {
   $self->{SEARCH_FIELDS} .= "DECODE(u.password, '$CONF->{secretkey}'), ";
   $self->{SEARCH_FIELDS_COUNT}++;
  }
 
 # resposible

 $WHERE = ($#WHERE_RULES > -1) ? 'WHERE '. join(' and ', @WHERE_RULES)  : '';


  $self->query($db,   "SELECT m.id,
if(m.uid>0, u.id, g.name),
m.subject,
mc.name,
m.date,
m.state,
$self->{SEARCH_FIELDS}
m.closed_date,
ra.id,
a.id,
m.priority,
CONCAT(m.plan_date, ' ', m.plan_time),
SEC_TO_TIME(sum(r.run_time)),
m.uid,
a.aid,
m.state,
m.gid,
m.user_read,
m.admin_read,
if(r.id IS NULL, 0, count(r.id)),
m.chapter,
DATE_FORMAT(plan_date, '%w'),
m.deligation,
m.inner_msg


FROM (msgs_messages m)
LEFT JOIN users u ON (m.uid=u.uid)
$EXT_JOIN
LEFT JOIN admins a ON (m.aid=a.aid)
LEFT JOIN groups g ON (m.gid=g.gid)
LEFT JOIN msgs_reply r ON (m.id=r.main_msg)
LEFT JOIN msgs_chapters mc ON (m.chapter=mc.id)
LEFT JOIN admins ra ON (m.resposible=ra.aid)
 $WHERE
GROUP BY m.id 
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;");


 my $list = $self->{list};

 if ($self->{TOTAL} > 0  || $PG > 0) {   
   $self->query($db, "SELECT count(DISTINCT m.id), 
   sum(if(m.admin_read = '0000-00-00 00:00:00', 1, 0)),
   sum(if(m.state = 0, 1, 0)),
   sum(if(m.state = 1, 1, 0)),
   sum(if(m.state = 2, 1, 0))
    FROM (msgs_messages m)
    LEFT JOIN users u ON (m.uid=u.uid)
    LEFT JOIN msgs_chapters mc ON (m.chapter=mc.id)
    $WHERE");

   ($self->{TOTAL},
    $self->{IN_WORK},
    $self->{OPEN},
    $self->{UNMAKED},
    $self->{CLOSED},
    ) = @{ $self->{list}->[0] };
  }

 $WHERE = '';
 @WHERE_RULES=();
  
 return $list;
}


#**********************************************************
# Message
#**********************************************************
sub message_add {
	my $self = shift;
	my ($attr) = @_;

  %DATA = $self->get_data($attr, { default => \%DATA }); 

  my $CLOSED_DATE = ($DATA{STATE} == 1 || $DATA{STATE} == 2 ) ? 'now()' : "'0000-00-00 00:00:00'";

  $self->query($db, "insert into msgs_messages (uid, subject, chapter, message, ip, date, reply, aid, state, gid,
   priority, lock_msg, plan_date, plan_time, user_read, admin_read, inner_msg, resposible, closed_date,
   phone, dispatch_id, survey_id)
    values ('$DATA{UID}', '$DATA{SUBJECT}', '$DATA{CHAPTER}', '$DATA{MESSAGE}', INET_ATON('$DATA{IP}'), now(), 
        '$DATA{REPLY}',
        '$admin->{AID}',
        '$DATA{STATE}', 
        '$DATA{GID}',
        '$DATA{PRIORITY}',
        '$DATA{LOCK}',
        '$DATA{PLAN_DATE}',
        '$DATA{PLAN_TIME}',
        '$DATA{USER_READ}',
        '$DATA{ADMIN_READ}',
        '$DATA{INNER_MSG}',
        '$DATA{RESPOSIBLE}',
        $CLOSED_DATE,
        '$DATA{PHONE}',
        '$DATA{DISPATCH_ID}',
        '$DATA{SURVEY_ID}'
        );", 'do');

  $self->{MSG_ID} = $self->{INSERT_ID};
  
	return $self;
}


#**********************************************************
# Bill
#**********************************************************
sub message_del {
	my $self = shift;
	my ($attr) = @_;

  @WHERE_RULES=();

  if ($attr->{ID}) {
    if ($attr->{ID} =~ /,/) {
    	push @WHERE_RULES, "id IN ($attr->{ID})";
     }
  	else {
  		push @WHERE_RULES, "id='$attr->{ID}'";
  	 }
   }

  if ($attr->{UID}) {
  	 push @WHERE_RULES, "uid='$attr->{UID}'";  	
   }

  $WHERE = ($#WHERE_RULES > -1) ? join(' and ', @WHERE_RULES)  : '';
  $self->query($db, "DELETE FROM msgs_messages WHERE $WHERE", 'do');

  $self->message_reply_del({ MAIN_MSG => $attr->{ID}, UID => $attr->{UID} });
  $self->query($db, "DELETE FROM msgs_attachments WHERE message_id='$attr->{ID}' and message_type=0", 'do');

	return $self;
}

#**********************************************************
# Bill
#**********************************************************
sub message_info {
	my $self = shift;
	my ($id, $attr) = @_;

  $WHERE = ($attr->{UID}) ? "and m.uid='$attr->{UID}'" : '';

  $self->query($db, "SELECT m.id,
  m.subject,
  m.par,
  m.uid,
  m.chapter,
  m.message,
  m.reply,
  INET_NTOA(m.ip),
  m.date,
  m.state,
  m.aid,
  u.id,
  a.id,
  mc.name,
  m.gid,
  g.name,
  m.state,
  m.priority,
  m.lock_msg,
  m.plan_date,
  m.plan_time,
  m.closed_date,
  m.done_date,
  m.user_read,
  m.admin_read,
  m.resposible,
  m.inner_msg,
  m.phone,
  m.dispatch_id,
  m.deligation,
  m.survey_id
    FROM (msgs_messages m)
    LEFT JOIN msgs_chapters mc ON (m.chapter=mc.id)
    LEFT JOIN users u ON (m.uid=u.uid)
    LEFT JOIN admins a ON (m.aid=a.aid)
    LEFT JOIN groups g ON (m.gid=g.gid)
  WHERE m.id='$id' $WHERE
  GROUP BY m.id;");

  if ($self->{TOTAL} < 1) {
     $self->{errno} = 2;
     $self->{errstr} = 'ERROR_NOT_EXIST';
     return $self;
   }

  ($self->{ID}, 
   $self->{SUBJECT},
   $self->{PARENT_ID},
   $self->{UID},
   $self->{CHAPTER},
   $self->{MESSAGE},
   $self->{REPLY},
   $self->{IP},
   $self->{DATE}, 
   $self->{STATE}, 
   $self->{AID},
   $self->{LOGIN},
   $self->{A_NAME},
   $self->{CHAPTER_NAME},
   $self->{GID},
   $self->{G_NAME},
   $self->{STATE},
   $self->{PRIORITY},
   $self->{LOCK},
   $self->{PLAN_DATE},
   $self->{PLAN_TIME},
   $self->{CLOSED_DATE},
   $self->{DONE_DATE},
   $self->{USER_READ},
 	 $self->{ADMIN_READ},
 	 $self->{RESPOSIBLE},
 	 $self->{INNER_MSG},
 	 $self->{PHONE},
 	 $self->{DISPATCH_ID},
 	 $self->{DELIGATION},
 	 $self->{SURVEY_ID}
  )= @{ $self->{list}->[0] };
	
	
  $self->attachment_info({ MSG_ID => $self->{ID} });

	return $self;
}


#**********************************************************
# change()
#**********************************************************
sub message_change {
  my $self = shift;
  my ($attr) = @_;
  
 
  my %FIELDS = (ID          => 'id',
                PARENT_ID   => 'par',
                UID			    => 'uid',
                CHAPTER     => 'chapter',
                MESSAGE     => 'message',
                REPLY       => 'reply',
                IP					=> 'ip',
                DATE        => 'date',
                STATE			  => 'state',
                AID         => 'aid',
                GID         => 'gid',
                PRIORITY    => 'priority',
                LOCK        => 'lock_msg',
                PLAN_DATE   => 'plan_date',
                PLAN_TIME   => 'plan_time',
                CLOSED_DATE => 'closed_date',
                DONE_DATE   => 'done_date',
                USER_READ   => 'user_read',
 	              ADMIN_READ  => 'admin_read',
 	              RESPOSIBLE  => 'resposible',
 	              INNER_MSG   => 'inner_msg',
 	              PHONE       => 'phone',
 	              DISPATCH_ID => 'dispatch_id',
 	              DELIGATION  => 'deligation'
             );

  #print "!! $attr->{STATE} !!!";
  $attr->{STATUS} = ($attr->{STATUS}) ? $attr->{STATUS} : 0;

  $admin->{MODULE}=$MODULE;
  $self->changes($admin,  { CHANGE_PARAM => 'ID',
                   TABLE        => 'msgs_messages',
                   FIELDS       => \%FIELDS,
                   OLD_INFO     => $self->message_info($attr->{ID}),
                   DATA         => $attr,
                   EXT_CHANGE_INFO  => "MSG_ID:$attr->{ID}"
                  } );

  return $self->{result};
}





#**********************************************************
# accounts_list
#**********************************************************
sub chapters_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  @WHERE_RULES = ();
 
 if($attr->{NAME}) {
	 push @WHERE_RULES, "mc.name='$attr->{NAME}'"; 
  }

 if($attr->{CHAPTERS}) {
	 push @WHERE_RULES, "mc.id IN ($attr->{CHAPTERS})"; 
  }

 if(defined($attr->{INNER_CHAPTER})) {
	 push @WHERE_RULES, "mc.inner_chapter IN ($attr->{INNER_CHAPTER})"; 
  }

 
 $WHERE = ($#WHERE_RULES > -1) ? 'WHERE ' . join(' and ', @WHERE_RULES)  : '';


  $self->query($db,   "SELECT mc.id, mc.name, mc.inner_chapter
    FROM msgs_chapters mc
    $WHERE
    GROUP BY mc.id 
    ORDER BY $SORT $DESC;");

 my $list = $self->{list};


	return $list;
}


#**********************************************************
# chapter_add
#**********************************************************
sub chapter_add {
	my $self = shift;
	my ($attr) = @_;

  %DATA = $self->get_data($attr, { default => \%DATA }); 

  $self->query($db, "insert into msgs_chapters (name, inner_chapter)
    values ('$DATA{NAME}', '$DATA{INNER_CHAPTER}');", 'do');
 
  $admin->system_action_add("MGSG_CHAPTER:$self->{INSERT_ID}", { TYPE => 1 });
	return $self;
}




#**********************************************************
# chapter_del
#**********************************************************
sub chapter_del {
	my $self = shift;
	my ($attr) = @_;

  @WHERE_RULES=();

  if ($attr->{ID}) {
  	 push @WHERE_RULES, "id='$attr->{ID}'";
   }

  $WHERE = ($#WHERE_RULES > -1) ? join(' and ', @WHERE_RULES)  : '';
  $self->query($db, "DELETE FROM msgs_chapters WHERE $WHERE", 'do');

	return $self;
}

#**********************************************************
# Bill
#**********************************************************
sub chapter_info {
	my $self = shift;
	my ($id, $attr) = @_;


  $self->query($db, "SELECT id,  name, inner_chapter
    FROM msgs_chapters 
  WHERE id='$id'");

  if ($self->{TOTAL} < 1) {
     $self->{errno} = 2;
     $self->{errstr} = 'ERROR_NOT_EXIST';
     return $self;
   }

  ($self->{ID}, 
   $self->{NAME},
   $self->{INNER_CHAPTER}
  )= @{ $self->{list}->[0] };

	return $self;
}


#**********************************************************
# change()
#**********************************************************
sub chapter_change {
  my $self = shift;
  my ($attr) = @_;
  
  $attr->{INNER_CHAPTER} = ($attr->{INNER_CHAPTER}) ? 1 : 0;
  
  my %FIELDS = (ID            => 'id',
                NAME          => 'name',
                INNER_CHAPTER => 'inner_chapter'
             );

  $admin->{MODULE}=$MODULE;
  $self->changes($admin,  { CHANGE_PARAM => 'ID',
                   TABLE        => 'msgs_chapters',
                   FIELDS       => \%FIELDS,
                   OLD_INFO     => $self->chapter_info($attr->{ID}),
                   DATA         => $attr,
                   
                  } );

  return $self->{result};
}


#**********************************************************
# accounts_list
#**********************************************************
sub admins_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  @WHERE_RULES = ();
 
 if($attr->{AID}) {
	 push @WHERE_RULES, "ma.aid='$attr->{AID}'"; 
  }

 if($attr->{EMAIL_NOTIFY}) {
	 push @WHERE_RULES, "ma.email_notify='$attr->{EMAIL_NOTIFY}'"; 
  }

 if($attr->{EMAIL}) {
 	 $attr->{EMAIL} =~ s/\*/\%/ig;
	 push @WHERE_RULES, "a.email LIKE '$attr->{EMAIL}'"; 
  }

 if($attr->{CHAPTER_ID}) {
   my $value = $self->search_expr($attr->{CHAPTER_ID}, 'INT');
 	 push @WHERE_RULES, "ma.chapter_id$value"; 
  }
 
 
 $WHERE = ($#WHERE_RULES > -1) ? 'WHERE ' . join(' and ', @WHERE_RULES)  : '';


  $self->query($db, "SELECT a.id, mc.name, ma.priority, ma.deligation_level, a.aid, 
     if(ma.chapter_id IS NULL, 0, ma.chapter_id), ma.email_notify, a.email
    FROM admins a 
    LEFT join msgs_admins ma ON (a.aid=ma.aid)
    LEFT join msgs_chapters mc ON (ma.chapter_id=mc.id)
    $WHERE
    ORDER BY $SORT $DESC;");

 my $list = $self->{list};

# if ($self->{TOTAL} > 0) {
#   $self->query($db, "SELECT count(*)
#     FROM msgs_chapters mc
#     $WHERE");

#   ($self->{TOTAL}) = @{ $self->{list}->[0] };
#  }
 
 
	return $list;
}


#**********************************************************
# chapter_add
#**********************************************************
sub admin_change {
	my $self = shift;
	my ($attr) = @_;
  
  my %DATA = $self->get_data($attr, { default => \%DATA }); 

  $self->admin_del({ AID => $attr->{AID}});
  
  my @chapters = split(/, /, $attr->{IDS});
  foreach my $id (@chapters) {
    $self->query($db, "insert into msgs_admins (aid, chapter_id, priority, email_notify, deligation_level)
      values ('$DATA{AID}', '$id','". $DATA{'PRIORITY_'. $id}."','". $DATA{'EMAIL_NOTIFY_'. $id}."', '". $DATA{'DELIGATION_LEVEL_'. $id}. "');", 'do');
   }

	return $self;
}




#**********************************************************
# chapter_del
#**********************************************************
sub admin_del {
	my $self = shift;
	my ($attr) = @_;

  $self->query($db, "DELETE FROM msgs_admins WHERE aid='$attr->{AID}'", 'do');

	return $self;
}

#**********************************************************
# Bill
#**********************************************************
sub admin_info {
	my $self = shift;
	my ($id, $attr) = @_;


  $self->query($db, "SELECT id,  name
    FROM msgs_chapters 
  WHERE id='$id'");

  if ($self->{TOTAL} < 1) {
     $self->{errno} = 2;
     $self->{errstr} = 'ERROR_NOT_EXIST';
     return $self;
   }

  ($self->{ID}, 
   $self->{NAME}
  )= @{ $self->{list}->[0] };

	return $self;
}


#**********************************************************
# message_reply_del
#**********************************************************
sub message_reply_del {
	my $self = shift;
	my ($attr) = @_;

  @WHERE_RULES=();


  if($attr->{MAIN_MSG}) {
    if ($attr->{MAIN_MSG} =~ /,/) {
    	push @WHERE_RULES, "main_msg IN ($attr->{MAIN_MSG})";
     }
  	else {
  		push @WHERE_RULES, "main_msg='$attr->{MAIN_MSG}'";
  	 }
   }
  elsif ($attr->{ID}) {
    push @WHERE_RULES, "id='$attr->{ID}'";
    $self->query($db, "DELETE FROM msgs_attachments WHERE message_id='$attr->{ID}' and message_type=1", 'do');
   }
  elsif ($attr->{UID}) {
  	push @WHERE_RULES, "id='$attr->{UID}'";
   }

  my $WHERE = ($#WHERE_RULES > -1) ? join(' and ', @WHERE_RULES)  : '';
  $self->query($db, "DELETE FROM msgs_reply WHERE $WHERE", 'do');
  


	return $self;
}



#**********************************************************
# messages_list
#**********************************************************
sub messages_reply_list {
  my $self = shift;
  my ($attr) = @_;


 $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;
 $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
 $DESC = (defined($attr->{DESC})) ? $attr->{DESC} : 'DESC';

 @WHERE_RULES = ();
 
 if($attr->{LOGIN}) {
	 push @WHERE_RULES, "u.id='$attr->{LOGIN}'"; 
  }
 
 if ($attr->{FROM_DATE}) {
    push @WHERE_RULES, "(date_format(m.date, '%Y-%m-%d')>='$attr->{FROM_DATE}' and date_format(m.date, '%Y-%m-%d')<='$attr->{TO_DATE}')";
  }

 if (defined($attr->{INNER_MSG})) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{INNER_MSG}, 'INT', 'mr.inner_msg') }; 
  }

 if (defined($attr->{REPLY})) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{REPLY}, '', 'm.reply') };
  }

 # Show groups
 if ($attr->{GIDS}) {
   push @WHERE_RULES, "u.gid IN ($attr->{GIDS})"; 
  }
 elsif ($attr->{GID}) {
   push @WHERE_RULES, "u.gid='$attr->{GID}'"; 
  }
 
 #DIsable
 if ($attr->{UID}) {
   push @WHERE_RULES, "m.uid='$attr->{UID}'"; 
 }

 #DIsable
 if ($attr->{STATE}) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{STATE}, 'INT', 'm.state') }; 
  }

 if ($attr->{ID}) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{ID}, 'INT', 'mr.id') }; 
  }
 

 $WHERE = ($#WHERE_RULES > -1) ? 'and ' . join(' and ', @WHERE_RULES)  : '';

  $self->query($db,   "SELECT mr.id,
    mr.datetime,
    mr.text,
    if(mr.aid>0, a.id, u.id),
    mr.status,
    mr.caption,
    INET_NTOA(mr.ip),
    ma.filename,
    ma.content_size,
    ma.id,
    mr.uid,
    SEC_TO_TIME(mr.run_time),
    mr.aid,
    mr.inner_msg,
    mr.survey_id
    FROM (msgs_reply mr)
    LEFT JOIN users u ON (mr.uid=u.uid)
    LEFT JOIN admins a ON (mr.aid=a.aid)
    LEFT JOIN msgs_attachments ma ON (mr.id=ma.message_id and ma.message_type=1 )
    WHERE main_msg='$attr->{MSG_ID}' $WHERE
    GROUP BY mr.id 
    ORDER BY datetime ASC;");
    #LIMIT $PG, $PAGE_ROWS    ;");
 
 return $self->{list};
}


#**********************************************************
# Reply ADD
#**********************************************************
sub message_reply_add {
	my $self = shift;
	my ($attr) = @_;
  
  %DATA = $self->get_data($attr, { default => \%DATA }); 
  $self->query($db, "insert into msgs_reply (main_msg,
   caption,
   text,
   datetime,
   ip,
   aid,
   status,
   uid,
   run_time,
   inner_msg,
   survey_id
   )
    values ('$DATA{ID}', '$DATA{REPLY_SUBJECT}', '$DATA{REPLY_TEXT}',  now(),
        INET_ATON('$DATA{IP}'), 
        '$DATA{AID}',
        '$DATA{STATE}',
        '$DATA{UID}', '$DATA{RUN_TIME}',
        '$DATA{REPLY_INNER_MSG}',
        '$DATA{SURVEY_ID}'
    );", 'do');
 
  
  $self->{REPLY_ID} = $self->{INSERT_ID};

  return $self;	
}

#**********************************************************
#
#**********************************************************
sub attachment_add () {
  my $self = shift;
  my ($attr) = @_;

 $self->query($db,  "INSERT INTO msgs_attachments ".
        " (message_id, filename, content_type, content_size, content, ".
        " create_time, create_by, change_time, change_by, message_type) " .
        " VALUES ".
        " ('$attr->{MSG_ID}', '$attr->{FILENAME}', '$attr->{CONTENT_TYPE}', '$attr->{FILESIZE}', ?, ".
        " current_timestamp, '$attr->{UID}', current_timestamp, '0', '$attr->{MESSAGE_TYPE}')", 
        'do', { Bind => [ $attr->{CONTENT}  ] } );

  return $self;
}


#**********************************************************
#
#**********************************************************
sub attachment_info () {
  my $self = shift;
  my ($attr) = @_;

  my $WHERE  ='';
  
  if ($attr->{MSG_ID}) {
    $WHERE = "message_id='$attr->{MSG_ID}' and message_type='0'";
   }
  elsif ($attr->{REPLY_ID}) {
    $WHERE = "message_id='$attr->{REPLY_ID}' and message_type='1'";
   }
  elsif ($attr->{ID}) {
  	$WHERE = "id='$attr->{ID}'";
   }

  if ($attr->{UID}) {
  	$WHERE .= " and (create_by='$attr->{UID}' or create_by='0')";
   }

 $self->query($db,  "SELECT id, filename, 
    content_type, 
    content_size,
    content
   FROM  msgs_attachments 
   WHERE $WHERE" );

 return $self if ($self->{TOTAL} < 1);

  ($self->{ATTACHMENT_ID},
   $self->{FILENAME}, 
   $self->{CONTENT_TYPE},
   $self->{FILESIZE},
   $self->{CONTENT}
  )= @{ $self->{list}->[0] };


  return $self;
}


#**********************************************************
# fees
#**********************************************************
sub messages_reports {
  my $self = shift;
  my ($attr) = @_;

 $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
 $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
 my $PG   = ($attr->{PG}) ? $attr->{PG} : 0;
 my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 100;

 $self->{SEARCH_FIELDS} = '';
 $self->{SEARCH_FIELDS_COUNT}=0;
 
 undef @WHERE_RULES;

 # Start letter 
 if ($attr->{FIRST_LETTER}) {
    push @WHERE_RULES, "u.id LIKE '$attr->{FIRST_LETTER}%'";
  }
 elsif ($attr->{LOGIN}) {
    push @WHERE_RULES, "u.id='$attr->{LOGIN}'";
  }
 # Login expresion
 elsif ($attr->{LOGIN}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{LOGIN}, 'STR', 'u.id') };
  }
 

 if ($attr->{STATUS}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{STATE}, 'INT', 'm.status') };
  }

 if ($attr->{UID}) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{UID}, 'INT', 'm.uid') };
  }


 my $date='date_format(m.date, \'%Y-%m-%d\')';

 if($attr->{TYPE}) {
   if($attr->{TYPE} eq 'ADMINS') {
     $date = 'a.id';
    }
   elsif ($attr->{TYPE} eq 'USER') {
 	   $date = 'u.id';
    }
   #elsif ($attr->{TYPE} eq 'DATE') { 
   #  $date = "date_format(m.date, '%Y-%m-%d')";
   # }
  }

 # Show groups
 if ($attr->{GIDS}) {
   push @WHERE_RULES, "u.gid IN ($attr->{GIDS})"; 
  }
 elsif ($attr->{GID}) {
   push @WHERE_RULES, "u.gid='$attr->{GID}'"; 
  }

 if ($attr->{DATE}) {
    push @WHERE_RULES, "date_format(m.date, '%Y-%m-%d')='$attr->{DATE}'";
    $date = "date_format(m.date, '%Y-%m-%d')";
  }
 elsif ($attr->{INTERVAL}) {
 	 my ($from, $to)=split(/\//, $attr->{INTERVAL}, 2);
   push @WHERE_RULES, "date_format(m.date, '%Y-%m-%d')>='$from' and date_format(m.date, '%Y-%m-%d')<='$to'";
  }
 elsif (defined($attr->{MONTH})) {
 	 push @WHERE_RULES, "date_format(m.date, '%Y-%m')='$attr->{MONTH}'";
   $date = "date_format(m.date, '%Y-%m-%d')";
  } 
 else {
 	 $date = "date_format(m.date, '%Y-%m')";
  }
 
 $WHERE = ($#WHERE_RULES > -1) ?  "WHERE " . join(' and ', @WHERE_RULES) : '';

 $self->query($db, "SELECT $date, 
   sum(if (m.state=0, 1, 0)),
   sum(if (m.state=1, 1, 0)),
   sum(if (m.state=2, 1, 0)),
   count(*),
   SEC_TO_TIME(sum(mr.run_time)),
   m.uid
   FROM msgs_messages m
  LEFT JOIN  users u ON (m.uid=u.uid)
  LEFT JOIN  admins a ON (m.aid=a.aid)
  LEFT JOIN  msgs_reply mr ON (m.id=mr.main_msg)
  $WHERE
  GROUP BY 1
  ORDER BY $SORT $DESC ; ");
#  LIMIT $PG, $PAGE_ROWS;");


  my $list = $self->{list};

  if ($self->{TOTAL} > 0 || $PG > 0) {
    $self->query($db, "SELECT count(DISTINCT m.id),
      sum(if (m.state=0, 1, 0)),
      sum(if (m.state=1, 1, 0)),
      sum(if (m.state=2, 1, 0)),
      SEC_TO_TIME(sum(mr.run_time)),
      sum(if(m.admin_read = '0000-00-00 00:00:00', 1, 0))
     FROM msgs_messages m
     LEFT JOIN  msgs_reply mr ON (m.id=mr.main_msg)
    $WHERE;");

    ($self->{TOTAL}, 
     $self->{OPEN}, 
     $self->{UNMAKED}, 
     $self->{MAKED},
     $self->{RUN_TIME},
     $self->{IN_WORK}) = @{ $self->{list}->[0] };
   }

  return $list;
}
























#**********************************************************
# accounts_list
#**********************************************************
sub dispatch_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  @WHERE_RULES = ();
 
 if($attr->{NAME}) {
	 push @WHERE_RULES, "d.name='$attr->{NAME}'"; 
  }

 if($attr->{CHAPTERS}) {
	 push @WHERE_RULES, "d.id IN ($attr->{CHAPTERS})"; 
  }

  if (defined($attr->{STATE}) && $attr->{STATE} ne '') {
   if ($attr->{STATE} == 4) {
   	 push @WHERE_RULES, @{ $self->search_expr('0000-00-00 00:00:00', 'INT', 'd.admin_read') };
    }
   else {
     push @WHERE_RULES, @{ $self->search_expr($attr->{STATE}, 'INT', 'd.state')  };
    }
  }


 
 $WHERE = ($#WHERE_RULES > -1) ? 'WHERE ' . join(' and ', @WHERE_RULES)  : '';


  $self->query($db,   "SELECT d.id, d.comments, d.plan_date, created, count(m.id)
    FROM msgs_dispatch d
    LEFT JOIN msgs_messages m ON (d.id=m.dispatch_id)
    $WHERE
    GROUP BY d.id 
    ORDER BY $SORT $DESC;");

 my $list = $self->{list};

# if ($self->{TOTAL} > 0 ) {
#   $self->query($db, "SELECT count(*)
#     FROM msgs_chapters mc
#     $WHERE");
#
#   ($self->{TOTAL}) = @{ $self->{list}->[0] };
#  }
 
 
	return $list;
}


#**********************************************************
# chapter_add
#**********************************************************
sub dispatch_add {
	my $self = shift;
	my ($attr) = @_;
  
 
  %DATA = $self->get_data($attr, { default => \%DATA }); 
 

  $self->query($db, "insert into msgs_dispatch (comments, created, plan_date, resposible, aid)
    values ('$DATA{COMMENTS}', now(), '$DATA{PLAN_DATE}', '$DATA{RESPOSIBLE}', '$admin->{AID}');", 'do');

  $self->{DISPATCH_ID}=$self->{INSERT_ID};
 
  $admin->system_action_add("MGSG_DISPATCH:$self->{INSERT_ID}", { TYPE => 1 });
	return $self;
}




#**********************************************************
# chapter_del
#**********************************************************
sub dispatch_del {
	my $self = shift;
	my ($attr) = @_;

  @WHERE_RULES=();

  if ($attr->{ID}) {
  	 push @WHERE_RULES, "id='$attr->{ID}'";
   }

  $WHERE = ($#WHERE_RULES > -1) ? join(' and ', @WHERE_RULES)  : '';
  $self->query($db, "DELETE FROM msgs_dispatch WHERE $WHERE", 'do');

	return $self;
}

#**********************************************************
# Bill
#**********************************************************
sub dispatch_info {
	my $self = shift;
	my ($id, $attr) = @_;


  $self->query($db, "SELECT md.id, md.comments, md.created, md.plan_date, 
  md.state,
  md.closed_date,
  a.aid,
  ra.aid,
  a.name,
  ra.name
    FROM msgs_dispatch md
    LEFT JOIN admins a ON (a.aid=md.aid)
    LEFT JOIN admins ra ON (ra.aid=md.resposible)
  WHERE md.id='$id'");

  if ($self->{TOTAL} < 1) {
     $self->{errno} = 2;
     $self->{errstr} = 'ERROR_NOT_EXIST';
     return $self;
   }

  ($self->{ID}, 
   $self->{COMMENTS}, 
   $self->{CREATED},
   $self->{PLAN_DATE},
   $self->{STATE},
   $self->{CLOSED_DATE},
   $self->{AID},
   $self->{RESPOSIBLE_ID},
   $self->{ADMIN_FIO},
   $self->{RESPOSIBLE_FIO},
     )= @{ $self->{list}->[0] };

	return $self;
}


#**********************************************************
# change()
#**********************************************************
sub dispatch_change {
  my $self = shift;
  my ($attr) = @_;
  
  $attr->{INNER_CHAPTER} = ($attr->{INNER_CHAPTER}) ? 1 : 0;
  
  my %FIELDS = (COMMENTS      => 'comments',
                PLAN_DATE     => 'plan_date',
                ID            => 'id',
                STATE         => 'state',
                CLOSED_DATE   => 'closed_date',
                RESPOSIBLE    => 'resposible'
             );

  $admin->{MODULE}=$MODULE;
  $self->changes($admin,  { CHANGE_PARAM => 'ID',
                   TABLE        => 'msgs_dispatch',
                   FIELDS       => \%FIELDS,
                   OLD_INFO     => $self->dispatch_info($attr->{ID}),
                   DATA         => $attr,
                   
                  } );

  return $self->{result};
}





#**********************************************************
# chapter_add
#**********************************************************
sub dispatch_admins_change {
	my $self = shift;
	my ($attr) = @_;
  
  my %DATA = $self->get_data($attr, { default => \%DATA }); 


  $self->query($db, "DELETE FROM msgs_dispatch_admins WHERE dispatch_id='$attr->{DISPATCH_ID}';", 'do');
  
  my @admins = split(/, /, $attr->{AIDS});
  foreach my $aid (@admins) {
    $self->query($db, "insert into msgs_dispatch_admins (dispatch_id, aid)
      values ('$DATA{DISPATCH_ID}', '$aid');", 'do');
   }

	return $self;
}


#**********************************************************
# chapter_add
#**********************************************************
sub dispatch_admins_list {
	my $self = shift;
	my ($attr) = @_;
  
  $self->query($db, "SELECT dispatch_id, aid FROM msgs_dispatch_admins WHERE dispatch_id='$attr->{DISPATCH_ID}';");

	return $self->{list};
}












































#**********************************************************
# messages_list
#**********************************************************
sub unreg_requests_list {
 my $self = shift;
 my ($attr) = @_;

 
 $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;
 $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
 $DESC = (defined($attr->{DESC})) ? $attr->{DESC} : 'DESC';


 @WHERE_RULES = ();
 
 if ($attr->{DATE}) {
   push @WHERE_RULES, "date_format(m.date, '%Y-%m-%d')='$attr->{DATE}'";
  } 
 elsif ($attr->{FROM_DATE}) {
   push @WHERE_RULES, "(date_format(m.date, '%Y-%m-%d')>='$attr->{FROM_DATE}' and date_format(m.date, '%Y-%m-%d')<='$attr->{TO_DATE}')";
  }

 if ($attr->{MSG_ID}) {
 	  push @WHERE_RULES,  @{ $self->search_expr($attr->{MSG_ID}, 'INT', 'm.id') };
  }

 if (defined($attr->{SUBJECT})) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{SUBJECT}, 'STR', 'm.subject') };
  }
 if ($attr->{MESSAGE}) {
 	 push @WHERE_RULES, @{ $self->search_expr($attr->{MESSAGE}, 'STR', 'm.message') };
  }
 elsif (defined($attr->{REPLY})) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{USER_READ}, 'STR', 'm.user_read') };
  }

 if (defined($attr->{PHONE})) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{PHONE}, 'STR', 'm.phone') };
  }

 if ($attr->{ADMIN_READ}) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{ADMIN_READ}, 'INT', 'm.admin_read') };
  }

 if ($attr->{CLOSED_DATE}) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{CLOSED_DATE}, 'INT', 'm.closed_date') };
  }

 if ($attr->{DONE_DATE}) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{DONE_DATE}, 'INT', 'm.done_date') };
  }

 if ($attr->{CHAPTERS}) {
   push @WHERE_RULES, "m.chapter IN ($attr->{CHAPTERS})"; 
  }
 
 if ($attr->{UID}) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{UID}, 'INT', 'm.uid') };
 }

 if (defined($attr->{STATE})) {
   if ($attr->{STATE} == 4) {
   	 push @WHERE_RULES, @{ $self->search_expr('0000-00-00 00:00:00', 'INT', 'm.admin_read') };
    }
   if ($attr->{STATE} == 7) {

    }
   else {
     push @WHERE_RULES, @{ $self->search_expr($attr->{STATE}, 'INT', 'm.state')  };
    }
  }

 if ($attr->{PRIORITY}) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{PRIORITY}, 'INT', 'm.state') };
  }

 my $EXT_JOIN = ''; 

 if ($attr->{SHOW_TEXT}) {
   $self->{SEARCH_FIELDS} .= 'm.message, ';
   $self->{SEARCH_FIELDS_COUNT}++;
  }
 

 $WHERE = ($#WHERE_RULES > -1) ? 'WHERE '. join(' and ', @WHERE_RULES)  : '';

  $self->query($db,   "SELECT  m.id,
  m.datetime,
  m.subject,
  m.fio,
  mc.name,
  ra.id,
  m.state,
  m.priority,
  m.closed_date,
  m.responsible_admin
FROM (msgs_unreg_requests m)
LEFT JOIN admins ra ON (m.received_admin=ra.aid)
LEFT JOIN msgs_chapters mc ON (m.chapter=mc.id)
 $WHERE
GROUP BY m.id 
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;");


 my $list = $self->{list};

 if ($self->{TOTAL} > 0  || $PG > 0) {
   
   $self->query($db, "SELECT count(*)
    FROM (msgs_unreg_requests m)
    LEFT JOIN msgs_chapters mc ON (m.chapter=mc.id)
    $WHERE");

   ($self->{TOTAL}) = @{ $self->{list}->[0] };
  }
 


 $WHERE = '';
 @WHERE_RULES=();
  
 return $list;
}


#**********************************************************
# Message
#**********************************************************
sub unreg_requests_add {
	my $self = shift;
	my ($attr) = @_;

  %DATA = $self->get_data($attr, { default => \%DATA }); 

  $self->query($db, "insert into msgs_unreg_requests (datetime, received_admin, ip, subject, comments, chapter, request, state,
   priority,
   fio,
   phone,
   email,
   address_street,
   address_build,
   address_flat,
   country_id,
   company,
   CONNECTION_TIME,
   location_id )
    values (now(), '$admin->{AID}', INET_ATON('$admin->{SESSION_IP}'),  '$DATA{SUBJECT}', '$DATA{COMMENTS}', '$DATA{CHAPTER}', '$DATA{REQUEST}',  '$DATA{STATE}',
        '$DATA{PRIORITY}',
        '$DATA{FIO}',
        '$DATA{PHONE}', 
        '$DATA{EMAIL}',
        '$DATA{ADDRESS_STREET}',
        '$DATA{ADDRESS_BUILD}',
        '$DATA{ADDRESS_FLAT}',
        '$DATA{COUNTRY}',
        '$DATA{COMPANY}',
        '$DATA{CONNECTION_TIME}',
        '$DATA{LOCATION_ID}'        
        );", 'do');

  $self->{MSG_ID} = $self->{INSERT_ID};
  
	return $self;
}


#**********************************************************
# unreg_requests_del
#**********************************************************
sub unreg_requests_del {
	my $self = shift;
	my ($attr) = @_;

  @WHERE_RULES=();

  if ($attr->{ID}) {
    if ($attr->{ID} =~ /,/) {
    	push @WHERE_RULES, "id IN ($attr->{ID})";
     }
  	else {
  		push @WHERE_RULES, "id='$attr->{ID}'";
  	 }
   }

  $WHERE = ($#WHERE_RULES > -1) ? join(' and ', @WHERE_RULES)  : '';
  $self->query($db, "DELETE FROM msgs_unreg_requests WHERE $WHERE", 'do');

	return $self;
}

#**********************************************************
# Bill
#**********************************************************
sub unreg_requests_info {
	my $self = shift;
	my ($id, $attr) = @_;

  $WHERE = ($attr->{UID}) ? "and m.uid='$attr->{UID}'" : '';

  $self->query($db, "SELECT 
    m.id,
    m.datetime,
    ra.id,
    m.state,
    m.priority,
    m.subject,
    mc.name,
    m.request,
    m.comments,
    m.responsible_admin,
    m.fio,
    m.phone,
    m.email,
    m.address_street,
    m.address_build,
    m.address_flat,
    m.ip,
    m.closed_date,
    m.uid,
    m.company,
    m.country_id,
    m.connection_time,
    m.location_id
    FROM (msgs_unreg_requests m)
    LEFT JOIN msgs_chapters mc ON (m.chapter=mc.id)
    LEFT JOIN admins ra ON (m.received_admin=ra.aid)
  WHERE m.id='$id' $WHERE
  GROUP BY m.id;");

  if ($self->{TOTAL} < 1) {
     $self->{errno} = 2;
     $self->{errstr} = 'ERROR_NOT_EXIST';
     return $self;
   }

  ($self->{ID},
   $self->{DATETIME},
   $self->{RECIEVED_ADMIN},
   $self->{STATE},
   $self->{PRIORITY},
   $self->{SUBJECT},
   $self->{CHAPTER},
   $self->{REQUEST},
   $self->{COMMENTS},
   $self->{RESPONSIBLE_ADMIN},
   $self->{FIO},
   $self->{PHONE},
   $self->{EMAIL},
   $self->{ADDRESS_STREET},
   $self->{ADDRESS_BUILD},
   $self->{ADDRESS_FLAT},
   $self->{IP},
   $self->{CLOSED_DATE},
   $self->{UID},
   $self->{COMPANY},
   $self->{COUNTRY},
   $self->{CONNECTION_TIME},
   $self->{LOCATION_ID},
  )= @{ $self->{list}->[0] };

 if ($self->{LOCATION_ID} > 0 ) {
   $self->query($db, "select d.id, d.city, d.name, s.name, b.number  
     FROM builds b
     LEFT JOIN streets s  ON (s.id=b.street_id)
     LEFT JOIN districts d  ON (d.id=s.district_id)
     WHERE b.id='$self->{LOCATION_ID}'");
   
    if ($self->{TOTAL} > 0) {
      ($self->{DISTRICT_ID}, 
       $self->{CITY}, 
       $self->{ADDRESS_DISTRICT}, 
       $self->{ADDRESS_STREET}, 
       $self->{ADDRESS_BUILD}, 
      )= @{ $self->{list}->[0] };
     }
  }

	
	return $self;
}


#**********************************************************
# unreg_requests_change()
#**********************************************************
sub unreg_requests_change {
  my $self = shift;
  my ($attr) = @_;
  
 
  my %FIELDS = ( ID    => 'id',
     DATETIME          => 'datetime',
     RECIEVED_ADMIN    => 'received_admin',
     STATE             => 'state',
     PRIORITY          => 'priority',
     SUBJECT           => 'subject',
     CHAPTER           => 'chapter',
     REQUEST           => 'request',
     COMMENTS          => 'comments',
     RESPONSIBLE_ADMIN => 'responsible_admin',
     FIO               => 'fio',
     PHONE             => 'phone',
     EMAIL             => 'email',
     ADDRESS_STREET    => 'address_street',
     ADDRESS_BUILD     => 'address_build',
     ADDRESS_FLAT      => 'address_flat',
     IP                => 'ip',
     CLOSED_DATE       => 'closed_date',
     UID               => 'uid',
     COMPANY           => 'company',
     COUNTRY           => 'country_id',
     CONNECTION_TIME   => 'connection_time',
     LOCATION_ID       => 'location_id'
             );
  $attr->{STATUS} = ($attr->{STATUS}) ? $attr->{STATUS} : 0;

  $admin->{MODULE}=$MODULE;
  
  $self->changes($admin,  { CHANGE_PARAM => 'ID',
                   TABLE        => 'msgs_unreg_requests',
                   FIELDS       => \%FIELDS,
                   OLD_INFO     => $self->unreg_requests_info($attr->{ID}),
                   DATA         => $attr,
                   EXT_CHANGE_INFO  => "MSG_ID:$attr->{ID}"
                  } );

  return $self->{result};
}



#**********************************************************
# survey_subjects_list
#**********************************************************
sub survey_subjects_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  @WHERE_RULES = ();
 
 if($attr->{NAME}) {
	 push @WHERE_RULES, "mc.name='$attr->{NAME}'"; 
  }

 if($attr->{CHAPTERS}) {
	 push @WHERE_RULES, "mc.id IN ($attr->{CHAPTERS})"; 
  }

 if(defined($attr->{INNER_CHAPTER})) {
	 push @WHERE_RULES, "mc.inner_chapter IN ($attr->{INNER_CHAPTER})"; 
  }

 
 $WHERE = ($#WHERE_RULES > -1) ? 'WHERE ' . join(' and ', @WHERE_RULES)  : '';
 $self->query($db,   "SELECT  ms.id, ms.name, ms.comments, ms.aid, ms.created
    FROM msgs_survey_subjects ms
    $WHERE
    GROUP BY ms.id 
    ORDER BY $SORT $DESC;");

 my $list = $self->{list};

 if ($self->{TOTAL} > 0 ) {
   $self->query($db, "SELECT count(*)
     FROM msgs_survey_subjects ms
     $WHERE");

   ($self->{TOTAL}) = @{ $self->{list}->[0] };
  }
 
	return $list;
}


#**********************************************************
# survey_subjects_add
#**********************************************************
sub survey_subject_add {
	my $self = shift;
	my ($attr) = @_;

  %DATA = $self->get_data($attr, { default => \%DATA }); 

  $self->query($db, "insert into msgs_survey_subjects (name, comments, aid, created)
    values ('$DATA{NAME}', '$DATA{COMMENTS}', '$admin->{AID}', now());", 'do');
 
	return $self;
}




#**********************************************************
# chapter_survey_subjects
#**********************************************************
sub survey_subject_del {
	my $self = shift;
	my ($attr) = @_;

  @WHERE_RULES=();

  if ($attr->{ID}) {
  	 push @WHERE_RULES, "id='$attr->{ID}'";
   }

  $WHERE = ($#WHERE_RULES > -1) ? join(' and ', @WHERE_RULES)  : '';
  $self->query($db, "DELETE FROM msgs_survey_subjects WHERE $WHERE", 'do');

	return $self;
}

#**********************************************************
# survey_subjects_info
#**********************************************************
sub survey_subject_info {
	my $self = shift;
	my ($id, $attr) = @_;


  $self->query($db, "SELECT id, name, comments, aid, created
    FROM msgs_survey_subjects 
  WHERE id='$id'");

  if ($self->{TOTAL} < 1) {
     $self->{errno} = 2;
     $self->{errstr} = 'ERROR_NOT_EXIST';
     return $self;
   }

  ($self->{SURVEY_ID}, 
   $self->{NAME},
   $self->{COMMENTS},
   $self->{AID},
   $self->{CREATED},
  )= @{ $self->{list}->[0] };

	return $self;
}


#**********************************************************
# survey_subjects_change()
#**********************************************************
sub survey_subject_change {
  my $self = shift;
  my ($attr) = @_;
  
  $attr->{INNER_CHAPTER} = ($attr->{INNER_CHAPTER}) ? 1 : 0;
  
  my %FIELDS = (SURVEY_ID     => 'id',
                NAME          => 'name',
                COMMENTS      => 'comments', 
             );

  $admin->{MODULE}=$MODULE;
  $self->changes($admin,  { CHANGE_PARAM => 'SURVEY_ID',
                   TABLE        => 'msgs_survey_subjects',
                   FIELDS       => \%FIELDS,
                   OLD_INFO     => $self->survey_subject_info($attr->{SURVEY_ID}),
                   DATA         => $attr,
                  } );

  return $self->{result};
}


#**********************************************************
# survey_subjects_list
#**********************************************************
sub survey_questions_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  @WHERE_RULES = ();
  
  if ($attr->{SURVEY}) {
	 push @WHERE_RULES, "mq.survey_id='$attr->{SURVEY}'"; 
  }
 
 $WHERE = ($#WHERE_RULES > -1) ? 'WHERE ' . join(' and ', @WHERE_RULES)  : '';

 $self->query($db,   "SELECT  mq.num, mq.question, mq.comments, mq.params, mq.user_comments, mq.fill_default, mq.id
    FROM msgs_survey_questions mq
    $WHERE
    ORDER BY $SORT $DESC;");

 my $list = $self->{list};

 if ($self->{TOTAL} > 0 ) {
   $self->query($db, "SELECT count(*)
     FROM msgs_survey_questions mq
     $WHERE");

   ($self->{TOTAL}) = @{ $self->{list}->[0] };
  }
 
	return $list;
}


#**********************************************************
# survey_questions_add
#**********************************************************
sub survey_question_add {
	my $self = shift;
	my ($attr) = @_;

  %DATA = $self->get_data($attr, { default => \%DATA }); 

  $self->query($db, "insert into msgs_survey_questions (num, question, comments, params, user_comments, survey_id, fill_default)
    values ('$DATA{NUM}', '$DATA{QUESTION}', '$DATA{COMMENTS}', '$DATA{PARAMS}', '$DATA{USER_COMMENTS}', '$DATA{SURVEY}', '$DATA{FILL_DEFAULT}');", 'do');
 
	return $self;
}


#**********************************************************
# urvey_questions_del
#**********************************************************
sub survey_question_del {
	my $self = shift;
	my ($attr) = @_;

  @WHERE_RULES=();

  if ($attr->{ID}) {
  	 push @WHERE_RULES, "id='$attr->{ID}'";
   }

  $WHERE = ($#WHERE_RULES > -1) ? join(' and ', @WHERE_RULES)  : '';
  $self->query($db, "DELETE FROM msgs_survey_questions WHERE $WHERE", 'do');

	return $self;
}

#**********************************************************
# survey_questions_info
#**********************************************************
sub survey_question_info {
	my $self = shift;
	my ($id, $attr) = @_;


  $self->query($db, "SELECT id, num, question, comments, params, user_comments, survey_id, fill_default
    FROM msgs_survey_questions 
  WHERE id='$id'");

  if ($self->{TOTAL} < 1) {
     $self->{errno} = 2;
     $self->{errstr} = 'ERROR_NOT_EXIST';
     return $self;
   }

  ($self->{ID}, 
   $self->{NUM},
   $self->{QUESTION},
   $self->{COMMENTS},
   $self->{PARAMS},
   $self->{USER_COMMENTS},
   $self->{SURVEY},
   $self->{FILL_DEFAULT}
  )= @{ $self->{list}->[0] };

	return $self;
}


#**********************************************************
# survey_questions_change()
#**********************************************************
sub survey_question_change {
  my $self = shift;
  my ($attr) = @_;
  
  $attr->{INNER_CHAPTER} = ($attr->{INNER_CHAPTER}) ? 1 : 0;
  $attr->{USER_COMMENTS} = ($attr->{USER_COMMENTS}) ? 1 : 0;
  $attr->{FILL_DEFAULT}  = ($attr->{FILL_DEFAULT}) ? 1 : 0;
  
  my %FIELDS = (ID           => 'id',
                NUM          => 'num',
                QUESTION     => 'question',
                COMMENTS     => 'comments', 
                PARAMS       => 'params',
                USER_COMMENTS=> 'user_comments',
                SURVEY       => 'survey_id',
                FILL_DEFAULT => 'fill_default'
             );

  
  $admin->{MODULE}=$MODULE;
  $self->changes($admin,  { CHANGE_PARAM => 'ID',
                   TABLE        => 'msgs_survey_questions',
                   FIELDS       => \%FIELDS,
                   OLD_INFO     => $self->survey_question_info($attr->{ID}),
                   DATA         => $attr,
                  } );

  return $self->{result};
}


#**********************************************************
#
#**********************************************************
sub survey_answer_show {
  my $self = shift;
  my ($attr) = @_;

  my $WHERE = ($attr->{REPLY_ID}) ? "AND reply_id='$attr->{REPLY_ID}'" : "AND msg_id='$attr->{MSG_ID}' AND reply_id='0' ";
	
  $self->query($db, "SELECT question_id,
  uid,
  answer,
  comments,
  date_time,
  survey_id 
  FROM msgs_survey_answers 
  WHERE survey_id='$attr->{SURVEY_ID}' 
  AND uid='$attr->{UID}' $WHERE;");
	
	return $self->{list};
}

#**********************************************************
#
#**********************************************************
sub survey_answer_add {
  my $self = shift;
  my ($attr) = @_;

  
  my @ids = split(/, /,  $attr->{IDS});
  
  my @fill_default = ();
  my %fill_default_hash = ();
  if ($attr->{FILL_DEFAULT}) {
  	@fill_default = split(/, /,  $attr->{FILL_DEFAULT});
  	foreach my $id (@fill_default) {
  	  $fill_default_hash{$id}=1;
  	 }
   }

	foreach my $id (@ids) {
		if ($attr->{FILL_DEFAULT} && ! $fill_default_hash{$id})  {
			 next;
		 }

		my $sql = "INSERT INTO msgs_survey_answers (question_id,
  uid,
  answer,
  comments,
  date_time,
  survey_id,
  msg_id,
  reply_id)
  values ('$id', 
  '$attr->{UID}', 
  '". $attr->{'PARAMS_'. $id}."', 
  '". $attr->{'USER_COMMENTS_'. $id} ."', 
  now(), 
  '$attr->{SURVEY_ID}',
  '$attr->{MSG_ID}',
  '$attr->{REPLY_ID}'
  );";
  
    $self->query($db, $sql, 'do');
	 }
	
	return $self;
}


#**********************************************************
#
#**********************************************************
sub survey_answer_del {
  my $self = shift;
  my ($attr) = @_;
  
  my $WHERE = ($attr->{REPLY_ID}) ? "AND reply_id='$attr->{REPLY_ID}'" : "'$attr->{MSG_ID}'";
  
  $self->query($db, "DELETE FROM msgs_survey_answers WHERE survey_id='$attr->{SURVEY_ID}' AND uid='$attr->{UID}' $WHERE;", 'do');
	return $self;
}


1


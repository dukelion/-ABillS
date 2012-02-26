package Mail;
# Mails
#

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION
@access_actions
);

use Exporter;
$VERSION = 2.00;
@ISA = ('Exporter');





@EXPORT = qw(
  @access_actions
);

@EXPORT_OK = ();
%EXPORT_TAGS = ();

# User name expration
@access_actions = ('OK', 'REJECT', 'DISCARD', 'ERROR');

use main;
@ISA  = ("main");


#**********************************************************
# Init 
#**********************************************************
sub new {
  my $class = shift;
  ($db, $admin, $CONF) = @_;
  $admin->{MODULE}='Mail';
  my $self = { };
  bless($self, $class);
  
  
  if ($CONF->{DELETE_USER}) {
    $self->mbox_del(0, { UID => $CONF->{DELETE_USER} });
   }

  
  return $self;
}



#**********************************************************
#
#**********************************************************
sub mbox_add {
	my $self = shift;
	my ($attr) = @_;
  %DATA = $self->get_data($attr); 
	
  $DATA{ANTIVIRUS} = (defined($attr->{ANTIVIRUS})) ? 0 : 1;
  $DATA{ANTISPAM} = (defined($attr->{ANTISPAM})) ? 0 : 1;

	
	$self->query($db, "INSERT INTO mail_boxes 
    (username,  domain_id, descr, maildir, create_date, change_date, mails_limit, box_size, status, 
     uid, 
     antivirus, antispam, expire, password) values
    ('$DATA{USERNAME}', '$DATA{DOMAIN_ID}', '$DATA{COMMENTS}', '$DATA{MAILDIR}', now(), now(), 
     '$DATA{MAILS_LIMIT}', '$DATA{BOX_SIZE}', '$DATA{DISABLE}', 
    '$DATA{UID}', 
    '$DATA{ANTIVIRUS}', '$DATA{ANTISPAM}', '$DATA{EXPIRE}', 
    ENCODE('$DATA{PASSWORD}', '$CONF->{secretkey}'));", 'do');
	
	return $self if ($self->{errno});
	
	$self->{MBOX_ID}=$self->{INSERT_ID};
	
	if ($DATA{DOMAIN_ID}) {
	  $self->domain_info({ MAIL_DOMAIN_ID => $DATA{DOMAIN_ID} });
   }
	else {
    $self->{DOMAIN}='';
	 }

	$self->{USER_EMAIL} = $DATA{USERNAME}.'@'.$self->{DOMAIN};
	
  $admin->action_add($DATA{UID}, "ADD $self->{USER_EMAIL}");
	
	return $self;
}

#**********************************************************
#
#**********************************************************
sub mbox_del {
	my $self = shift;
	my ($id, $attr) = @_;

  if ($CONF->{DELETE_USER}) {
  	$self->query($db, "DELETE FROM mail_boxes 
      WHERE uid='$CONF->{DELETE_USER}';", 'do');
   }
  else {
	  $self->query($db, "DELETE FROM mail_boxes 
      WHERE id='$id' and uid='$attr->{UID}';", 'do');
	 }


  $admin->action_add($attr->{UID}, "$attr->{UID}", { TYPE => 10 });
	return $self;
}


#**********************************************************
#
#**********************************************************
sub mbox_change {
	my $self = shift;
	my ($attr) = @_;


	my %FIELDS = (MBOX_ID      => 'id',
	              USERNAME     => 'username',  
	              DOMAIN_ID    => 'domain_id',
	              COMMENTS     => 'descr', 
	              MAILDIR      => 'maildir', 
	              CREATE_DATE  => 'create_date', 
	              CHANGE_DATE  => 'change_date', 
	              BOX_SIZE     => 'box_size',
	              MAILS_LIMIT  => 'mails_limit',
	              DISABLE      => 'status', 
	              UID          => 'uid', 
	              ANTIVIRUS    => 'antivirus', 
	              ANTISPAM     => 'antispam',
	              EXPIRE       => 'expire',
	              PASSWORD     => 'password'	              
	              );
	
  $attr->{ANTIVIRUS} = (defined($attr->{ANTIVIRUS})) ? 0 : 1;
  $attr->{ANTISPAM}  = (defined($attr->{ANTISPAM})) ? 0 : 1;
  $attr->{DISABLE}   = (defined($attr->{DISABLE})) ? 1 : 0;
	
 	$self->changes($admin, 
 	              { CHANGE_PARAM => 'MBOX_ID',
	                TABLE        => 'mail_boxes',
	                FIELDS       => \%FIELDS,
	                OLD_INFO     => $self->mbox_info($attr),
	                DATA         => $attr
		              } );


	

	return $self;
}






#**********************************************************
#
#**********************************************************
sub defaults {
	my $self = shift;
	
	return $self;
}

#**********************************************************
#
#**********************************************************
sub mbox_info {
	my $self = shift;
	my ($attr) = @_;
	
	my $WHERE = ($attr->{UID}) ? "and mb.uid='$attr->{UID}'" : '';
	
  $self->query($db, "SELECT mb.username,  mb.domain_id, md.domain, mb.descr, mb.maildir, mb.create_date, 
   mb.change_date, 
   mb.mails_limit, 
   mb.box_size, 
   mb.status, 
   mb.uid,
   mb.antivirus, 
   mb.antispam,
   mb.expire,
   mb.id
   FROM mail_boxes mb
   LEFT JOIN mail_domains md ON  (md.id=mb.domain_id) 
   WHERE mb.id='$attr->{MBOX_ID}' $WHERE;");

  if ($self->{TOTAL} < 1) {
     $self->{errno} = 2;
     $self->{errstr} = 'ERROR_NOT_EXIST';
     return $self;
   }

  ($self->{USERNAME}, 
   $self->{DOMAIN_ID}, 
   $self->{DOMAIN}, 
   $self->{COMMENTS}, 
   $self->{MAILDIR}, 
   $self->{CREATE_DATE}, 
   $self->{CHANGE_DATE}, 
   $self->{MAILS_LIMIT},    
   $self->{BOX_SIZE}, 
   $self->{DISABLE}, 
   $self->{UID}, 
   $self->{ANTIVIRUS}, 
   $self->{ANTISPAM},
   $self->{EXPIRE},
   $self->{MBOX_ID}
  )= @{ $self->{list}->[0] };

	
	return $self;
}

#**********************************************************
#
#**********************************************************
sub mbox_list {
	my $self = shift;
	my ($attr) = @_;

 $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
 $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
 $PG = ($attr->{PG}) ? $attr->{PG} : 0;
 $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

 @WHERE_RULES = ();

 if (defined($attr->{UID})) {
 	  push @WHERE_RULES, "mb.uid='$attr->{UID}'";
  }
 if ($attr->{FIRST_LETTER}) {
    push @WHERE_RULES, "mb.username LIKE '$attr->{FIRST_LETTER}%'";
  }
 # Show groups
 if ($attr->{GIDS}) {
   push @WHERE_RULES, "u.gid IN ($attr->{GIDS})"; 
  }
 elsif ($attr->{GID}) {
   push @WHERE_RULES, "u.gid='$attr->{GID}'"; 
  }

	my $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';
	
	$self->query($db, "SELECT mb.username, md.domain, u.id, mb.descr, mb.mails_limit, 
	      mb.box_size,
	      mb.antivirus, 
	      mb.antispam, mb.status, 
	      mb.create_date, mb.change_date, mb.expire, mb.maildir, 
	      mb.uid, 
	      mb.id
        FROM mail_boxes mb
        LEFT JOIN mail_domains md ON  (md.id=mb.domain_id)
        LEFT JOIN users u ON  (mb.uid=u.uid) 
        $WHERE
        ORDER BY $SORT $DESC
        LIMIT $PG, $PAGE_ROWS;");
 
  return $self if($self->{errno});

  my $list = $self->{list};

  if ($self->{TOTAL} >= $attr->{PAGE_ROWS} || $PG > 0 ) {
    $self->query($db, "SELECT count(*) FROM mail_boxes mb $WHERE");
    ($self->{TOTAL}) = @{ $self->{list}->[0] };
   }

  return $list;
}


#**********************************************************
#
#**********************************************************
sub domain_add {
	my $self = shift;
	my ($attr) = @_;
  %DATA = $self->get_data($attr); 
	
	$self->query($db, "INSERT INTO mail_domains (domain, comments, create_date, change_date, status, backup_mx, transport)
           VALUES ('$DATA{DOMAIN}', '$DATA{COMMENTS}', now(), now(), '$DATA{STATUS}', '$DATA{BACKUP_MX}', '$DATA{TRANSPORT}');", 'do');
	
	return $self;
}

#**********************************************************
#
#**********************************************************
sub domain_del {
	my $self = shift;
	my ($id) = @_;

	$self->query($db, "DELETE FROM mail_domains 
    WHERE id='$id';", 'do');
	
	return $self;
}


#**********************************************************
#
#**********************************************************
sub domain_change {
	my $self = shift;
	my ($attr) = @_;


	my %FIELDS = (MAIL_DOMAIN_ID   => 'id',
	              DOMAIN       => 'domain',
	              COMMENTS     => 'comments', 
	              CHANGE_DATE  => 'change_date', 
	              DISABLE      => 'status',
	              BACKUP_MX    => 'backup_mx',
	              TRANSPORT    => 'transport'
	              );


  $attr->{BACKUP_MX} = (! defined($attr->{BACKUP_MX})) ? 0 : 1;
 	$self->changes($admin, { CHANGE_PARAM => 'MAIL_DOMAIN_ID',
	                TABLE        => 'mail_domains',
	                FIELDS       => \%FIELDS,
	                OLD_INFO     => $self->domain_info($attr),
	                DATA         => $attr
		              } );
	
	
	return $self;
}

#**********************************************************
#
#**********************************************************
sub domain_info {
	my $self = shift;
	my ($attr) = @_;
	
	
  $self->query($db, "SELECT domain, comments, create_date, change_date, status, 
  backup_mx,
  transport,
  id
   FROM mail_domains WHERE id='$attr->{MAIL_DOMAIN_ID}';");

  if ($self->{TOTAL} < 1) {
     $self->{errno} = 2;
     $self->{errstr} = 'ERROR_NOT_EXIST';
     return $self;
   }

  ($self->{DOMAIN}, 
   $self->{COMMENTS}, 
   $self->{CREATE_DATE}, 
   $self->{CHANGE_DATE}, 
   $self->{DISABLE},
   $self->{BACKUP_MX},
   $self->{TRANSPORT},
   $self->{MAIL_DOMAIN_ID}
  ) = @{ $self->{list}->[0] };
	
	return $self;
}

#**********************************************************
#
#**********************************************************
sub domain_list {
	my $self = shift;
	my ($attr) = @_;

 
 $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
 $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
 $PG = ($attr->{PG}) ? $attr->{PG} : 0;
 $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;


 my @WHERE_RULES = ();

 if (defined($attr->{BACKUP_MX})) {
   push @WHERE_RULES, "md.backup_mx='$attr->{BACKUP_MX}'"; 
  }

 my $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';

 $self->query($db, "SELECT md.domain, md.comments, md.status, md.backup_mx, md.transport, md.create_date, 
	    md.change_date, count(*) as mboxes, md.id
        FROM mail_domains md
        LEFT JOIN mail_boxes mb ON  (md.id=mb.domain_id) 
        $WHERE
        GROUP BY md.id
        ORDER BY $SORT $DESC
        LIMIT $PG, $PAGE_ROWS;");
 
  return $self if($self->{errno});

  my $list = $self->{list};

  if ($self->{TOTAL} >= 0) {
    $self->query($db, "SELECT count(*) FROM mail_domains md $WHERE");
    ($self->{TOTAL}) = @{ $self->{list}->[0] };
   }

  return $list;
}



#**********************************************************
#
#**********************************************************
sub alias_add {
	my $self = shift;
	my ($attr) = @_;
  %DATA = $self->get_data($attr); 
	
	$self->query($db, "INSERT INTO mail_aliases (address, goto,  create_date, change_date, status)
           VALUES ('$DATA{ADDRESS}', '$DATA{GOTO}', now(), now(), '$DATA{STATUS}');", 'do');

	
	return $self;
}

#**********************************************************
#
#**********************************************************
sub alias_del {
	my $self = shift;
	my ($id, $attr) = @_;
	$self->query($db, "DELETE FROM mail_aliases  WHERE id='$id';", 'do');
	return $self;
}


#**********************************************************
#
#**********************************************************
sub alias_change {
	my $self = shift;
	my ($attr) = @_;


	my %FIELDS = (MAIL_ADDRESS  => 'address',
	              GOTO          => 'goto',
	              COMMENTS      => 'comments', 
	              CHANGE_DATE   => 'change_date', 
	              DISABLE       => 'status',
	              MAIL_ALIAS_ID => 'id'
	              );
	
 	$self->changes($admin, { CHANGE_PARAM => 'MAIL_ALIAS_ID',
	                TABLE        => 'mail_aliases',
	                FIELDS       => \%FIELDS,
	                OLD_INFO     => $self->alias_info($attr),
	                DATA         => $attr
		              } );

	
	
	return $self;
}

#**********************************************************
#
#**********************************************************
sub alias_info {
	my $self = shift;
	my ($attr) = @_;
	
	
  $self->query($db, "SELECT address,  goto, comments, create_date, change_date, status, id
   FROM mail_aliases WHERE id='$attr->{MAIL_ALIAS_ID}';");

  if ($self->{TOTAL} < 1) {
     $self->{errno} = 2;
     $self->{errstr} = 'ERROR_NOT_EXIST';
     return $self;
   }

  ($self->{ADDRESS}, 
   $self->{GOTO}, 
   $self->{COMMENTS}, 
   $self->{CREATE_DATE}, 
   $self->{CHANGE_DATE}, 
   $self->{DISABLE},
   $self->{MAIL_ALIAS_ID}
  )= @{ $self->{list}->[0] };
	
	return $self;
}

#**********************************************************
#
#**********************************************************
sub alias_list {
	my $self = shift;
	my ($attr) = @_;

	@WHERE_RULES = ();
	$WHERE = '';
	
	$self->query($db, "SELECT ma.address, ma.goto, ma.comments, ma.status, ma.create_date, 
	    ma.change_date, ma.id
        FROM mail_aliases ma
        $WHERE
        ORDER BY $SORT $DESC
        LIMIT $PG, $PAGE_ROWS;");
 
  return $self if($self->{errno});

  my $list = $self->{list};

  if ($self->{TOTAL} >= $attr->{PAGE_ROWS} || $PG > 0) {
    $self->query($db, "SELECT count(*) FROM mail_aliases $WHERE");
    ($self->{TOTAL}) = @{ $self->{list}->[0] };
   }

  return $list;
}




#**********************************************************
#
#**********************************************************
sub access_add {
	my $self = shift;
	my ($attr) = @_;
  %DATA = $self->get_data($attr); 

  if ($DATA{MACTION} == 3) {
  	 $DATA{FACTION} = "$access_actions[$DATA{MACTION}]:$DATA{CODE} $DATA{MESSAGE}";
    }
  else {
  	 $DATA{FACTION} = $access_actions[$DATA{MACTION}];
    }


  $self->query($db, "INSERT INTO mail_access (pattern, action, status, comments, change_date)
           VALUES ('$DATA{PATTERN}', '$DATA{FACTION}', '$DATA{DISABLE}', '$DATA{COMMENTS}', now());", 'do');

	return $self;
}

#**********************************************************
#
#**********************************************************
sub access_del {
	my $self = shift;
	
	my ($id, $attr) = @_;

	$self->query($db, "DELETE FROM mail_access WHERE id='$id';", 'do');
	return $self;
}


#**********************************************************
#
#**********************************************************
sub access_change {
	my $self = shift;
	my ($attr) = @_;


	my %FIELDS = (PATTERN      => 'pattern',
	              ACTION       => 'action',
	              DISABLE      => 'status',
	              COMMENTS     => 'comments'
	              );
	
  if ($attr->{MACTION} == 3) {
  	 $attr->{ACTION} = "$access_actions[$attr->{MACTION}]:$attr->{CODE} $attr->{MESSAGE}";
    }
  else {
  	 $attr->{ACTION} = $access_actions[$attr->{MACTION}];
    }

	
 	$self->changes($admin, { CHANGE_PARAM => 'MAIL_ACCESS_ID',
	                TABLE        => 'mail_access',
	                FIELDS       => \%FIELDS,
	                OLD_INFO     => $self->access_info($attr),
	                DATA         => $attr
		              } );

	
	
	return $self;
}

#**********************************************************
#
#**********************************************************
sub access_info {
	my $self = shift;
	my ($attr) = @_;
	
	
  $self->query($db, "SELECT pattern, action, status, comments, change_date, id
   FROM mail_access WHERE pattern='$attr->{PATTERN}';");

  if ($self->{TOTAL} < 1) {
     $self->{errno} = 2;
     $self->{errstr} = 'ERROR_NOT_EXIST';
     return $self;
   }

  ($self->{PATTERN}, 
   $self->{FACTION},
   $self->{DISABLE},
   $self->{COMMENTS},
   $self->{CHANGE_DATE},
   $self->{MAIL_ACCESS_ID}
  )= @{ $self->{list}->[0] };
	
	($self->{FACTION}, $self->{CODE}, $self->{MESSAGE})=split(/:| /, $self->{FACTION}, 3);
	
	return $self;
}

#**********************************************************
#
#**********************************************************
sub access_list {
	my $self = shift;
	my ($attr) = @_;
	
	$WHERE = '';
	
	$self->query($db, "SELECT pattern, action, comments, status, change_date, id
        FROM mail_access
        $WHERE
        ORDER BY $SORT $DESC
        LIMIT $PG, $PAGE_ROWS;");
 
  return $self if($self->{errno});

  my $list = $self->{list};

  if ($self->{TOTAL} >= $attr->{PAGE_ROWS}) {
    $self->query($db, "SELECT count(*) FROM mail_access $WHERE");
    ($self->{TOTAL}) = @{ $self->{list}->[0] };
   }

  return $list;
}



#**********************************************************
#
#**********************************************************
sub transport_add {
	my $self = shift;
	my ($attr) = @_;
  %DATA = $self->get_data($attr); 


  $self->query($db, "INSERT INTO mail_transport (domain, transport, comments, change_date) 
   values ('$DATA{DOMAIN}', '$DATA{TRANSPORT}', '$DATA{COMMENTS}', now());", 'do');

	return $self;
}

#**********************************************************
#
#**********************************************************
sub transport_del {
	my $self = shift;
	my ($id, $attr) = @_;

	$self->query($db, "DELETE FROM mail_transport WHERE id='$id';", 'do');
	return $self;
}


#**********************************************************
#
#**********************************************************
sub transport_change {
	my $self = shift;
	my ($attr) = @_;


	my %FIELDS = (DOMAIN             => 'domain',
	              TRANSPORT          => 'transport',
	              COMMENTS           => 'comments',
	              MAIL_TRANSPORT_ID  => 'id'
	              );
	
 	$self->changes($admin, { CHANGE_PARAM => 'MAIL_TRANSPORT_ID',
	                TABLE        => 'mail_transport',
	                FIELDS       => \%FIELDS,
	                OLD_INFO     => $self->transport_info($attr),
	                DATA         => $attr
		              } );
	
	return $self;
}

#**********************************************************
#
#**********************************************************
sub transport_info {
	my $self = shift;
	my ($attr) = @_;
	
	
  $self->query($db, "SELECT domain, transport, comments, change_date, id
   FROM mail_transport WHERE id='$attr->{MAIL_TRANSPORT_ID}';");

  if ($self->{TOTAL} < 1) {
     $self->{errno} = 2;
     $self->{errstr} = 'ERROR_NOT_EXIST';
     return $self;
   }

  ($self->{DOMAIN}, 
   $self->{TRANSPORT},
   $self->{COMMENTS},
   $self->{CHANGE_DATE},
   $self->{MAIL_TRANSPORT_ID}
  )= @{ $self->{list}->[0] };
	
	
	return $self;
}

#**********************************************************
#
#**********************************************************
sub transport_list {
	my $self = shift;
	my ($attr) = @_;
	
	$WHERE = '';
	
	$self->query($db, "SELECT domain, transport, comments, change_date, id
        FROM mail_transport
        $WHERE
        ORDER BY $SORT $DESC
        LIMIT $PG, $PAGE_ROWS;");
 
  return $self if($self->{errno});

  my $list = $self->{list};

  if ($self->{TOTAL} >= $attr->{PAGE_ROWS} || $PG > 0) {
    $self->query($db, "SELECT count(*) FROM mail_transport $WHERE");
    ($self->{TOTAL}) = @{ $self->{list}->[0] };
   }

  return $list;
}



#**********************************************************
#
#**********************************************************
sub spam_replace {
	my $self = shift;
	my ($attr) = @_;
  %DATA = $self->get_data($attr); 

  $self->spam_del(0, { USER_NAME  => "$DATA{USER_NAME}", 
  	                   PREFERENCE => "$DATA{PREFERENCE}"
  	                 });

  $self->query($db, "INSERT INTO mail_spamassassin (username, preference, value, comments, create_date, change_date) 
   values ('$DATA{USER_NAME}', '$DATA{PREFERENCE}', '$DATA{VALUE}', '$DATA{COMMENTS}', now(), now());", 'do');

	return $self;
}


#**********************************************************
#
#**********************************************************
sub spam_add {
	my $self = shift;
	my ($attr) = @_;
  %DATA = $self->get_data($attr); 

  $self->query($db, "INSERT INTO mail_spamassassin (username, preference, value, comments, create_date, change_date) 
   values ('$DATA{USER_NAME}', '$DATA{PREFERENCE}', '$DATA{VALUE}', '$DATA{COMMENTS}', now(), now());", 'do');

	return $self;
}

#**********************************************************
#
#**********************************************************
sub spam_del {
	my $self = shift;
	my ($id, $attr) = @_;

  if ($attr->{USER_NAME} && $attr->{PREFERENCE}) {
  	$WHERE="username='$attr->{USER_NAME}' and preference='$attr->{PREFERENCE}'";
   }
  else {
    $WHERE="prefid='$id'";
   }
   
	$self->query($db, "DELETE FROM mail_spamassassin WHERE $WHERE;", 'do');
	return $self;
}


#**********************************************************
#
#**********************************************************
sub spam_change {
	my $self = shift;
	my ($attr) = @_;


	my %FIELDS = (USER_NAME          => 'user_name',
	              PREFERENCE         => 'preference',
	              VALUE              => 'value',
	              COMMENTS           => 'comments',
	              CHANGE_DATE        => 'change_date',
	              ID                 => 'prefid'
	              );
	
 	$self->changes($admin, { CHANGE_PARAM => 'ID',
	                TABLE        => 'mail_spamassassin',
	                FIELDS       => \%FIELDS,
	                OLD_INFO     => $self->spam_info($attr),
	                DATA         => $attr
		              } );
	
	return $self;
}

#**********************************************************
#
#**********************************************************
sub spam_info {
	my $self = shift;
	my ($attr) = @_;
	
	
  $self->query($db, "SELECT username, preference, value, comments, create_date, change_date
   FROM mail_spamassassin WHERE prefid='$attr->{ID}';");

  if ($self->{TOTAL} < 1) {
     $self->{errno} = 2;
     $self->{errstr} = 'ERROR_NOT_EXIST';
     return $self;
   }

  ($self->{USER_NAME}, 
   $self->{PREFERENCE},
   $self->{VALUE},
   $self->{COMMENTS},
   $self->{CREATE_DATE},
   $self->{CHANGE_DATE}
  )= @{ $self->{list}->[0] };
	
	
	return $self;
}

#**********************************************************
#
#**********************************************************
sub spam_list {
	my $self = shift;
	my ($attr) = @_;
	
 @WHERE_RULES = (); 
 $WHERE = '';
 
 
 if ($attr->{USER_NAME}) {
    $attr->{USER_NAME} =~ s/\*/\%/ig;
    push @WHERE_RULES, "username LIKE '$attr->{USER_NAME}'";
  }

 if ($attr->{PREFERENCE}) {
    $attr->{PREFERENCE} =~ s/\*/\%/ig;
    push @WHERE_RULES, "preference LIKE '$attr->{PREFERENCE}'";
  }

 if ($attr->{VALUE}) {
    $attr->{VALUE} =~ s/\*/\%/ig;
    push @WHERE_RULES, "value LIKE '$attr->{VALUE}'";
  }

 if ($attr->{COMMENTS}) {
    $attr->{COMMENTS} =~ s/\*/\%/ig;
    push @WHERE_RULES, "comments LIKE '$attr->{COMMENTS}'";
  }

 $WHERE = "WHERE " . join(' and ', @WHERE_RULES) if($#WHERE_RULES > -1);
	
	$self->query($db, "SELECT username, preference, value, comments, change_date, prefid
        FROM mail_spamassassin
        $WHERE
        ORDER BY $SORT $DESC
        LIMIT $PG, $PAGE_ROWS;");
 
  return $self if($self->{errno});

  my $list = $self->{list};

  if ($self->{TOTAL} >= $attr->{PAGE_ROWS} || $PG > 0) {
    $self->query($db, "SELECT count(*) FROM mail_spamassassin $WHERE");
    ($self->{TOTAL}) = @{ $self->{list}->[0] };
   }

  return $list;
}



#**********************************************************
#
#**********************************************************
sub spam_awl_del {
  my $self = shift;
  my ($attr) = @_;

  if ($attr->{TYPE})  {
    $WHERE = '';

    if ($attr->{TYPE} eq 'USER') {
      $attr->{VALUE} =~ s/\*/\%/ig;
      $WHERE = "username LIKE '$attr->{VALUE}'";
     }
    elsif ($attr->{TYPE} eq 'EMAIL') {
      $attr->{VALUE} =~ s/\*/\%/ig;
      $WHERE = "email LIKE '$attr->{VALUE}'";
     }
    elsif ($attr->{TYPE} eq 'IP') {
      $attr->{VALUE} =~ s/\*/\%/ig;
      $WHERE = "IP LIKE $attr->{VALUE}";
     }
    elsif ($attr->{TYPE} eq 'COUNT') {
      my $value = $self->search_expr($attr->{VALUE}, 'INT');
      $WHERE = "count$value";
     }
    elsif ($attr->{TYPE} eq 'SCORE') {
      my $value = $self->search_expr($attr->{VALUE}, 'INT');
      $WHERE = "totscore$value";
     }

    $self->query($db, "DELETE FROM mail_awl WHERE $WHERE;", 'do');
   }
  else {
    my @selected = split(/, /, $attr->{IDS});
    
    foreach my $line (@selected) {
    	my ($username, $email) = split(/\|/, $line, 2);
    	$self->query($db, "DELETE FROM mail_awl WHERE username='$username' and email='$email';", 'do');
     }
   }

  return $self;
}


#**********************************************************
#
#**********************************************************
sub spam_awl_list {
	my $self = shift;
	my ($attr) = @_;

 $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
 $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
 $PG = ($attr->{PG}) ? $attr->{PG} : 0;
 $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

	
 @WHERE_RULES = (); 
 
 if ($attr->{USER_NAME}) {
    $attr->{USER_NAME} =~ s/\*/\%/ig;
    push @WHERE_RULES, "username LIKE '$attr->{USER_NAME}'";
  }

 if ($attr->{EMAIL}) {
    $attr->{EMAIL} =~ s/\*/\%/ig;
    push @WHERE_RULES, "email LIKE '$attr->{EMAIL}'";
  }

 if ($attr->{SCORE}) {
    my $value = $self->search_expr($attr->{SCORE}, 'INT');
    push @WHERE_RULES, "totscore$value";
  }

 if ($attr->{COUNT}) {
    my $value = $self->search_expr($attr->{COUNT}, 'INT');
    push @WHERE_RULES, "count$value";
  }

 $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';
 	
 $self->query($db, "SELECT username, email, ip, count, totscore
        FROM mail_awl
        $WHERE
        ORDER BY $SORT $DESC
        LIMIT $PG, $PAGE_ROWS;");
 
  return $self if($self->{errno});

  my $list = $self->{list};

  if ($self->{TOTAL} >= $attr->{PAGE_ROWS} || $PG > 0) {
    $self->query($db, "SELECT count(*) FROM mail_awl $WHERE");
    ($self->{TOTAL}) = @{ $self->{list}->[0] };
   }

  return $list;
}
1

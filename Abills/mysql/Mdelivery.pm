package Mdelivery;
# Mail delivery functions
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


my $uid;
#**********************************************************
# Init 
#**********************************************************
sub new {
  my $class = shift;
  ($db, $admin, $CONF) = @_;

  $admin->{MODULE}='Mdelivery';  
  my $self = { };
  bless($self, $class);
  
  return $self;
}



#**********************************************************
#
#**********************************************************
sub defaults {
  my $self = shift;

  %DATA = (
     DATE      => '0000-00-00', 
     SUBJECT   => '',
     AID       => 0, 
     FROM      => '', 
     TEXT      => '',
     UID       => 0,
     GID       => 0,
     PRIORITY  => 3
    );
 
  $self = \%DATA;
  return $self;
}

#**********************************************************
# User information
# info()
#**********************************************************
sub info {
  my $self = shift;
  my ($id) = @_;

  my $WHERE;

  $self->query($db, "SELECT 
     md.id,  
     md.date, 
     md.subject, 
     md.sender, 
     a.id, 
     md.added, 
     md.text,
     md.priority,
     u.id,
     g.name
     FROM mdelivery_list md
     LEFT JOIN admins a ON (md.aid=a.aid)
     LEFT JOIN groups g ON (md.gid=g.gid)
     LEFT JOIN users u ON (md.uid=u.uid)
     WHERE md.id='$id';");

  if ($self->{TOTAL} < 1) {
     $self->{errno} = 2;
     $self->{errstr} = 'ERROR_NOT_EXIST';
     return $self;
   }

  ($self->{ID},
   $self->{DATE},
   $self->{SUBJECT},
   $self->{SENDER}, 
   $self->{ADMIN}, 
   $self->{ADDED}, 
   $self->{TEXT},
   $self->{PRIORITY},
   $self->{USER}, 
   $self->{GROUP}
 )= @{ $self->{list}->[0] };
  
  
  return $self;
}


#**********************************************************
# User information
# info()
#**********************************************************
sub change {
  my $self = shift;
  my ($attr) = @_;

  $self->query($db, "UPDATE mdelivery_list SET status=1 WHERE id='$attr->{ID}';", 'do');

  return $self;
}



#**********************************************************
# Delete user info from all tables
#
# del(attr);
#**********************************************************
sub del {
  my $self = shift;
  my ($id) = @_;

  $self->query($db, "DELETE from mdelivery_list WHERE id='$id';", 'do');
  $self->user_list_del({ MDELIVERY_ID => $id });


  $admin->system_action_add("$id", { TYPE => 10 });

  return $self->{result};
}


#**********************************************************
# User information
# info()
#**********************************************************
sub add {
  my $self = shift;
  my ($attr) = @_;

  my $DATA = defaults();
  %DATA = $self->get_data($attr, { default => $DATA });

  $self->query($db, "INSERT INTO mdelivery_list (date, added, subject, sender, aid, text, uid, gid,
     priority)
     values ('$DATA{DATE}', now(), '$DATA{SUBJECT}', 
     '$DATA{FROM}', 
     '$admin->{AID}', 
     '$DATA{TEXT}', 
     '$DATA{UID}',
     '$DATA{GID}',
     '$DATA{PRIORITY}');", 'do');
   
  $self->{MDELIVERY_ID}=$self->{INSERT_ID};

  $self->user_list_add({ %$attr, MDELIVERY_ID => $self->{MDELIVERY_ID} });

  $admin->system_action_add("$self->{MDELIVERY_ID}", { TYPE => 1 });

  return $self;
}


#**********************************************************
# 
# 
#**********************************************************
sub user_list_add {
  my $self = shift;
  my ($attr) = @_;

  my @WHERE_RULES = ();
  my $JOIN_TABLES = '';

  if (defined($attr->{STATUS}) && $attr->{STATUS} ne '') {
    push @WHERE_RULES, @{ $self->search_expr($attr->{STATUS}, 'INT', "u.disable") };  
   }

  if ($attr->{GID}) {
  	push @WHERE_RULES, @{ $self->search_expr($attr->{GID}, 'INT', "u.gid") };  
   }

  if (defined($attr->{DV_STATUS}) && $attr->{DV_STATUS} ne '') {
  	push @WHERE_RULES, @{ $self->search_expr($attr->{DV_STATUS}, 'INT', "dv.disable") };  
  	$JOIN_TABLES = "LEFT JOIN dv_main dv ON (u.uid=dv.uid)";
   }

  if ($attr->{TP_ID}) {
  	push @WHERE_RULES, @{ $self->search_expr($attr->{TP_ID}, 'INT', "dv.tp_id") };  
  	$JOIN_TABLES = "LEFT JOIN dv_main dv ON (u.uid=dv.uid)";
   }

 if ($attr->{ADDRESS_STREET}) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{ADDRESS_STREET}, 'STR', 'pi.address_street') };
  }

 if ($attr->{ADDRESS_BUILD}) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{ADDRESS_BUILD}, 'STR', 'pi.address_build') };
  }

 if ($attr->{ADDRESS_FLAT}) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{ADDRESS_FLAT}, 'STR', 'pi.address_flat') };
  }


  $WHERE = ($#WHERE_RULES>-1) ? ' WHERE '. join(' AND ', @WHERE_RULES) : '';  

  $self->query($db, "INSERT INTO mdelivery_users (uid, mdelivery_id) SELECT u.uid, $attr->{MDELIVERY_ID} FROM users u
     LEFT JOIN users_pi pi ON (u.uid=pi.uid)
     $JOIN_TABLES
     $WHERE
     ORDER BY $SORT;");

  return $self;
}

#**********************************************************
# 
# 
#**********************************************************
sub user_list_change {
  my $self = shift;
  my ($attr) = @_;

  my @WHERE_RULES = ("mdelivery_id='$attr->{MDELIVERY_ID}'");

  if ($attr->{UID}) {
  	push @WHERE_RULES, @{ $self->search_expr($attr->{UID}, 'INT', "uid") };  
   }
  elsif ($attr->{ID}) {
  	push @WHERE_RULES, @{ $self->search_expr($attr->{ID}, 'INT', "id") };
   }

  $WHERE = ($#WHERE_RULES>-1) ? join(' AND ', @WHERE_RULES) : '';


  my $status = 1;
  $self->query($db, "UPDATE mdelivery_users SET status='$status' WHERE $WHERE;", 'do');

  return $self;
}




#**********************************************************
# 
# 
#**********************************************************
sub user_list_del {
  my $self = shift;
  my ($attr) = @_;

  my @WHERE_RULES = ();

  if ($attr->{UID}) {
  	push @WHERE_RULES, @{ $self->search_expr($attr->{UID}, 'INT', "uid") };  
   }
  elsif ($attr->{MDELIVERY_ID}) {
  	push @WHERE_RULES, @{ $self->search_expr($attr->{MDELIVERY_ID}, 'INT', "mdelivery_id") };
   }
  elsif ($attr->{ID}) {
  	push @WHERE_RULES, @{ $self->search_expr($attr->{ID}, 'INT', "id") };
   }

  $WHERE = ($#WHERE_RULES>-1) ? join(' AND ', @WHERE_RULES) : '';

  $self->query($db, "DELETE FROM mdelivery_users WHERE $WHERE;", 'do');

  return $self;
}



#**********************************************************
# 
# 
#**********************************************************
sub user_list {
  my $self = shift;
  my ($attr) = @_;

 $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
 $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
 $PG = ($attr->{PG}) ? $attr->{PG} : 0;
 $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;


  my @WHERE_RULES = ("u.uid=mdl.uid");

  if ($attr->{MDELIVERY_ID}) {
  	push @WHERE_RULES, @{ $self->search_expr($attr->{MDELIVERY_ID}, 'INT', "mdl.mdelivery_id") };
   } 

  if (defined($attr->{STATUS})) {
  	push @WHERE_RULES, @{ $self->search_expr($attr->{STATUS}, 'INT', "mdl.status") };
   } 


  $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';

  $self->query($db, "SELECT u.id, pi.fio, mdl.status, mdl.uid, pi.email FROM (mdelivery_users mdl, users u)
     LEFT JOIN users_pi pi ON (mdl.uid=pi.uid)
     $WHERE
     ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;");


  my $list = $self->{list};
  
  if ($self->{TOTAL} > 0) {
    $self->query($db, "SELECT count(*)
     FROM mdelivery_users mdl, users u
     $WHERE;");

    ($self->{TOTAL}) = @{ $self->{list}->[0] };
   }



  return $list;
}


#**********************************************************
# User information
# info()
#**********************************************************
sub list {
  my $self = shift;
  my ($attr) = @_;

 $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
 $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
 $PG = ($attr->{PG}) ? $attr->{PG} : 0;
 $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;


  @WHERE_RULES = ();
  
 if (defined($attr->{STATUS})) {
    push @WHERE_RULES, "md.status='$attr->{STATUS}'";
  }

 if ($attr->{DATE}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{DATE}, 'INT', "md.date") }
  }



  $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';

  $self->query($db, "SELECT 
    md.id,  md.date, md.subject, md.sender, a.id, md.added, length(md.text), md.status
     FROM mdelivery_list md
     LEFT JOIN admins a ON (md.aid=a.aid)
     $WHERE
     ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;");


  my $list = $self->{list};
  
  if ($self->{TOTAL} > 0) {
    $self->query($db, "SELECT count(*)
     FROM mdelivery_list md
     LEFT JOIN admins a ON (md.aid=a.aid) $WHERE;");

    ($self->{TOTAL}) = @{ $self->{list}->[0] };
   }
  return $list;
}



#**********************************************************
#
#**********************************************************
sub attachment_add () {
  my $self = shift;
  my ($attr) = @_;

 $self->query($db,  "INSERT INTO mdelivery_attachments ".
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
    $WHERE = "message_id='$attr->{MSG_ID}'";
   }
  elsif ($attr->{ID}) {
  	$WHERE = "id='$attr->{ID}'";
   }

  $self->query($db,  "SELECT id, filename, 
    content_type, 
    content_size,
    content
   FROM  mdelivery_attachments 
   WHERE $WHERE" );


  if ($self->{TOTAL} < 1) {
    return $self 
   }
  elsif ($self->{TOTAL} == 1) {
    ($self->{ATTACHMENT_ID},
     $self->{FILENAME}, 
     $self->{CONTENT_TYPE},
     $self->{FILESIZE},
     $self->{CONTENT}
    )= @{ $self->{list}->[0] };
    
    return $self;
   }
  else {
  	return $self->{list};
   }


}

1

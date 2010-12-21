package Shedule;
#Shedule SQL backend


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


my $db;
my $uid;
my $admin;
my $CONF;
my %DATA = ();


sub new {
  my $class = shift;
  ($db, $admin, $CONF) = @_;
  my $self = { };

  $admin->{MODULE}='';
  bless($self, $class);
  return $self;
}




#**********************************************************
# change()
#**********************************************************
sub change {
  my $self = shift;
  my ($attr) = @_;
  
  my %FIELDS = (H          => 'h', 
                D          => 'd', 
                M          => 'm', 
                Y          => 'y', 
                COUNTS     => 'counts',
                ACTION     => 'action',
                DATE       => 'date', 
                COMMENTS   => 'comments', 
                UID        => 'uid', 
                SHEDULE_ID => 'id',
             );
  
  $self->changes($admin, { CHANGE_PARAM => 'SHEDULE_ID',
                   TABLE        => 'shedule',
                   FIELDS       => \%FIELDS,
                   OLD_INFO     => $self->info({ ID => $attr->{SHEDULE_ID} }),
                   DATA         => $attr,
                   EXT_CHANGE_INFO  => "SHEDULE:$attr->{SHEDULE_ID}, RESULT: $attr->{RESULT}"
                  } );


  $self->info({ ID => $attr->{SHEDULE_ID} });

  return $self;
}

#**********************************************************
# info()
#**********************************************************
sub info {
 my $self = shift;
 my ($attr) = @_;
 
 @WHERE_RULES =();

 if ($attr->{UID}) {
   push @WHERE_RULES, "s.uid='$attr->{UID}'";
  }
 
 if ($attr->{TYPE}) {
   push @WHERE_RULES, "s.type='$attr->{TYPE}'";
  }

 if ($attr->{MODULE}) {
   push @WHERE_RULES, "s.module='$attr->{MODULE}'";
  }
 
 if ($attr->{ID}) {
 	 push @WHERE_RULES, "s.id='$attr->{ID}'";
  }


 $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';

 $self->query($db, "SELECT s.h, s.d, s.m, s.y, s.counts, s.action, s.date, s.comments, s.uid, s.id, a.id, s.admin_action 
    FROM shedule s
    LEFT JOIN admins a ON (a.aid=s.aid) 
    $WHERE;");

 if ($self->{TOTAL} < 1) {
   $self->{errno} = 2;
   $self->{errstr} = 'ERROR_NOT_EXIST';
   return $self;
  }

  ($self->{H}, 
   $self->{D}, 
   $self->{M}, 
   $self->{Y}, 
   $self->{COUNTS},
   $self->{ACTION},
   $self->{DATE}, 
   $self->{COMMENTS}, 
   $self->{UID}, 
   $self->{SHEDULE_ID},
   $self->{ADMIN_NAME},
   $self->{ADMIN_ACTION}
  )= @{ $self->{list}->[0] };


 return $self;
}



#**********************************************************
# list()
#**********************************************************
sub list {
 my $self = shift;
 my ($attr) = @_;

 $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
 $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
 $PG    = ($attr->{PG}) ? $attr->{PG} : 0;
 $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

 @WHERE_RULES =();
 
 if ($attr->{UID}) {
   push @WHERE_RULES, "s.uid='$attr->{UID}'";
  }
 
 if ($attr->{AID}) {
   push @WHERE_RULES, "s.aid='$attr->{AID}'";
  }

 if ($attr->{TYPE}) {
   push @WHERE_RULES, "s.type='$attr->{TYPE}'";
  }

 if ($attr->{Y}) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{Y}, 'STR', 's.y') };
  }

 if ($attr->{M}) {
 	 push @WHERE_RULES, @{ $self->search_expr($attr->{M}, 'STR', 's.m') };
  }

 if ($attr->{D}) {
 	 push @WHERE_RULES, @{ $self->search_expr($attr->{D}, 'STR', 's.d') };
  }

 if ($attr->{MODULE}) {
   push @WHERE_RULES, "s.module='$attr->{MODULE}'";
  }

 if ($attr->{COMMENTS}) {
   push @WHERE_RULES, @{ $self->search_expr("$attr->{COMMENTS}", 'STR', 's.comments') };
  }

 if (defined($attr->{ACTION})) {
   push @WHERE_RULES, @{ $self->search_expr("$attr->{ACTION}", 'STR', 's.action') };
  }

 if (defined($attr->{ADMIN_ACTION})) {
   push @WHERE_RULES, @{ $self->search_expr("$attr->{ADMIN_ACTION}", 'STR', 's.admin_action') };
  }


 # Show groups
 if ($attr->{GIDS}) {
   push @WHERE_RULES, "u.gid IN ($attr->{GIDS})"; 
  }
 elsif ($attr->{GID}) {
   push @WHERE_RULES, "u.gid='$attr->{GID}'"; 
  }

 $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';
  
 $self->query($db, "SELECT s.h, s.d, s.m, s.y, s.counts, u.id, s.type, s.action, s.module, a.id, s.date, s.comments, a.aid, s.uid, s.id  
    FROM shedule s
    LEFT JOIN users u ON (u.uid=s.uid)
    LEFT JOIN admins a ON (a.aid=s.aid) 
   $WHERE
  ORDER BY $SORT $DESC
  LIMIT $PG, $PAGE_ROWS");

 my $list = $self->{list};

 if ($self->{TOTAL} > 0) {
   $self->query($db, "SELECT count(*)   FROM shedule s
      LEFT JOIN users u ON (u.uid=s.uid)
      LEFT JOIN admins a ON (a.aid=s.aid) 
     $WHERE");
 
   ($self->{TOTAL}
    )= @{ $self->{list}->[0] };
  }

  return $list;
}





#**********************************************************
# Add new shedule
# add($self)
#**********************************************************
sub add {
 my $self = shift;
 my ($attr) = @_;

 my $H           = (defined($attr->{H})) ? $attr->{H} : '*';
 my $D           = (defined($attr->{D})) ? $attr->{D} : '*';
 my $M           = (defined($attr->{M})) ? $attr->{M} : '*';
 my $Y           = (defined($attr->{Y})) ? $attr->{Y} : '*';
 my $COUNT       = (defined($attr->{COUNT})) ? int($attr->{COUNT}): 0;
 my $UID         = (defined($attr->{UID})) ? int($attr->{UID}) : 0;
 my $TYPE        = (defined($attr->{TYPE})) ? $attr->{TYPE} : '';
 my $ACTION      = (defined($attr->{ACTION})) ? $attr->{ACTION} : '';
 my $MODULE      = (defined($attr->{MODULE})) ? $attr->{MODULE} : '';
 my $COMMENTS    = (defined($attr->{COMMENTS})) ? $attr->{COMMENTS} : '';
 my $ADMIN_ACTION= (defined($attr->{ADMIN_ACTION})) ? $attr->{ADMIN_ACTION} : '';
 
 $self->query($db, "INSERT INTO shedule (h, d, m, y, uid, type, action, aid, date, module, comments, admin_action, counts) 
        VALUES ('$H', '$D', '$M', '$Y', '$UID', '$TYPE', '$ACTION', '$admin->{AID}', now(), '$MODULE', '$COMMENTS', '$ADMIN_ACTION', '$COUNT');", 'do');

 if ($self->{errno}) {
     $self->{errno} = 7;
     $self->{errstr} = 'ERROR_DUBLICATE';
     return $self;
   }

 $admin->action_add($UID, "SHEDULE:$self->{INSERT_ID}");

 return $self;	
}


#**********************************************************
# Add new shedule
# add($self)
#**********************************************************
sub del {
 my $self = shift;
 my ($attr) = @_;

 my $result = $attr->{RESULT} || 0;

 if ($attr->{IDS}) {
   $self->query($db, "DELETE FROM shedule WHERE id IN ( $attr->{IDS} );", 'do');
   $admin->system_action_add("SHEDULE:$attr->{IDS} UID:$self->{UID}", { TYPE => 10 });    
   return $self;	
  }
 
 $self->info({ ID => $attr->{ID}});

 if ($self->{TOTAL} > 0) {
   $self->query($db, "DELETE FROM shedule WHERE id='$attr->{ID}';", 'do');
   $admin->system_action_add("SHEDULE:$attr->{ID} UID:$self->{UID} RESULT: $result", { TYPE => 10 });    
  } 
  
 return $self;	
}


1

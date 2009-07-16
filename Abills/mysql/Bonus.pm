package Bonus;
# Dialup & Vpn  managment functions
#



use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION);

use Exporter;
$VERSION = 2.00;
@ISA = ('Exporter');

@EXPORT = qw();

@EXPORT_OK = ();
%EXPORT_TAGS = ();

use main;
@ISA  = ("main");

use Tariffs;
use Users;
use Fees;

my $uid;
my $MODULE='Bonus';

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
# User information
# info()
#**********************************************************
sub info {
  my $self = shift;
  my ($id) = @_;
  
  my $WHERE = "WHERE id='$id'";

  $self->query($db, "SELECT tp_id, 
    period,
    range_begin, 
    range_end,
    sum,
    comments,
    id
     FROM bonus_main 
   $WHERE;");

  if ($self->{TOTAL} < 1) {
     $self->{errno} = 2;
     $self->{errstr} = 'ERROR_NOT_EXIST';
     return $self;
   }

  (
   $self->{TP_ID}, 
   $self->{PERIOD}, 
   $self->{RANGE_BEGIN}, 
   $self->{RANGE_END}, 
   $self->{SUM}, 
   $self->{COMMENTS}, 
   $self->{ID}
  )= @{ $self->{list}->[0] };

  return $self;
}



#**********************************************************
#
#**********************************************************
sub defaults {
  my $self = shift;

  my %DATA = (
   TP_ID          => 0, 
   PERIOD         => 0, 
   RANGE_BEGIN    => 0, 
   RANGE_END      => 0, 
   SUM            => '0.00', 
   COMMENTS       => ''
  );

 
  $self = \%DATA;
  return $self;
}


#**********************************************************
# add()
#**********************************************************
sub add {
  my $self = shift;
  my ($attr) = @_;
  my %DATA = $self->get_data($attr); 

  $self->query($db,  "INSERT INTO bonus_main (tp_id, range_begin, range_end, sum, comments, period)
        VALUES ('$DATA{TP_ID}', 
        '$DATA{RANGE_BEGIN}', '$DATA{RANGE_END}', '$DATA{SUM}', '$DATA{COMMENTS}', '$DATA{PERIOD}');", 'do');
  return $self;
}




#**********************************************************
# change()
#**********************************************************
sub change {
  my $self = shift;
  my ($attr) = @_;
  
  my %FIELDS = (TP_ID            => 'tp_id',
                RANGE_BEGIN      => 'range_begin',
                RANGE_END        => 'range_end',
                SUM              => 'sum',
                COMMENTS         => 'comments',
                ID               => 'id',
                PERIOD           => 'period'
               );
  
  $self->changes($admin, { CHANGE_PARAM => 'ID',
                   TABLE        => 'bonus_main',
                   FIELDS       => \%FIELDS,
                   OLD_INFO     => $self->info($attr->{ID}),
                   DATA         => $attr
                  } );
  return $self->{result};
}



#**********************************************************
# Delete user info from all tables
#
# del(attr);
#**********************************************************
sub del {
  my $self = shift;
  my ($attr) = @_;
  $self->query($db, "DELETE from bonus_main WHERE id='$attr->{ID}';", 'do');
  return $self->{result};
}




#**********************************************************
# list()
#**********************************************************
sub list {
 my $self = shift;
 my ($attr) = @_;

 $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
 $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
 $PG = ($attr->{PG}) ? $attr->{PG} : 0;
 $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;


 undef @WHERE_RULES;
 $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';
 
 $self->query($db, "SELECT tp_id, period, range_begin, range_end, sum, comments, id
     FROM bonus_main
     $WHERE 
     ORDER BY $SORT $DESC;");

 return $self if($self->{errno});

 my $list = $self->{list};

 if ($self->{TOTAL} >= 0) {
    $self->query($db, "SELECT count(b.id) FROM bonus_main b $WHERE");
    ($self->{TOTAL}) = @{ $self->{list}->[0] };
   }

  return $list;
}


#**********************************************************
# Periodic
#**********************************************************
sub periodic {
  my $self = shift;
  my ($period) = @_;
  
  if($period eq 'daily') {
    $self->daily_fees();
  }
  
  return $self;
}






#**********************************************************
# User information
# info()
#**********************************************************
sub tp_info {
  my $self = shift;
  my ($id) = @_;
  
  my $WHERE = "WHERE id='$id'";

  $self->query($db, "SELECT id, 
    name,
    state
     FROM bonus_tps 
   $WHERE;");

  if ($self->{TOTAL} < 1) {
     $self->{errno} = 2;
     $self->{errstr} = 'ERROR_NOT_EXIST';
     return $self;
   }

  (
   $self->{TP_ID}, 
   $self->{NAME}, 
   $self->{STATE}
  )= @{ $self->{list}->[0] };

  return $self;
}



#**********************************************************
# tp_add()
#**********************************************************
sub tp_add {
  my $self = shift;
  my ($attr) = @_;
  my %DATA = $self->get_data($attr); 

  $self->query($db,  "INSERT INTO bonus_tps (name, state)
        VALUES ('$DATA{NAME}', '$DATA{STATE}');", 'do');

  return $self;
}




#**********************************************************
# change()
#**********************************************************
sub tp_change {
  my $self = shift;
  my ($attr) = @_;
  
  my %FIELDS = (ID            => 'id',
                NAME          => 'name',
                STATE         => 'state'
               );
  
  $attr->{STATE} = ($attr->{STATE}) ? 1 : 0;
  
  $self->changes($admin, { CHANGE_PARAM => 'ID',
                   TABLE        => 'bonus_tps',
                   FIELDS       => \%FIELDS,
                   OLD_INFO     => $self->tp_info($attr->{ID}),
                   DATA         => $attr
                  } );
  return $self->{result};
}



#**********************************************************
# Delete user info from all tables
#
# del(attr);
#**********************************************************
sub tp_del {
  my $self = shift;
  my ($attr) = @_;
  $self->query($db, "DELETE from bonus_tps WHERE id='$attr->{ID}';", 'do');
  return $self->{result};
}


#**********************************************************
# list()
#**********************************************************
sub tp_list {
 my $self = shift;
 my ($attr) = @_;

 $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
 $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
 $PG = ($attr->{PG}) ? $attr->{PG} : 0;
 $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;


 undef @WHERE_RULES;
 $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';
 
 $self->query($db, "SELECT id, name, state
     FROM bonus_tps
     $WHERE 
     ORDER BY $SORT $DESC;");

 return $self if($self->{errno});

 my $list = $self->{list};

 if ($self->{TOTAL} >= 0) {
    $self->query($db, "SELECT count(b.id) FROM bonus_tps b $WHERE");
    ($self->{TOTAL}) = @{ $self->{list}->[0] };
   }

  return $list;
}








































#**********************************************************
# User information
# info()
#**********************************************************
sub rule_info {
  my $self = shift;
  my ($id) = @_;
  
  my $WHERE = "WHERE id='$id'";

  $self->query($db, "SELECT tp_id,
    period,
    rules,
    rule_value,
    actions,
    id
     FROM bonus_rules 
   $WHERE;");

  if ($self->{TOTAL} < 1) {
     $self->{errno} = 2;
     $self->{errstr} = 'ERROR_NOT_EXIST';
     return $self;
   }

  (
   $self->{TP_ID}, 
   $self->{PERIOD}, 
   $self->{RULE},
   $self->{RULE_VALUE},
   $self->{ACTIONS},
   $self->{ID}
  )= @{ $self->{list}->[0] };

  return $self;
}



#**********************************************************
# tp_add()
#**********************************************************
sub rule_add {
  my $self = shift;
  my ($attr) = @_;
  my %DATA = $self->get_data($attr); 

  $self->query($db,  "INSERT INTO bonus_rules (tp_id,
    period,
    rules,
    rule_value,
    actions)
        VALUES ('$DATA{TP_ID}', '$DATA{PERIOD}', '$DATA{RULE}', '$DATA{RULE_VALUE}', '$DATA{ACTIONS}');", 'do');

  return $self;
}




#**********************************************************
# change()
#**********************************************************
sub rule_change {
  my $self = shift;
  my ($attr) = @_;
  
  my %FIELDS = (ID            => 'id',
                TP_ID         => 'tp_id',
                PERIOD        => 'period',
                RULE          => 'rules',
                RULE_VALUE    => 'rule_value',
                ACTIONS       => 'actions'
               );
  
  $self->changes($admin, { CHANGE_PARAM => 'ID',
                   TABLE        => 'bonus_rules',
                   FIELDS       => \%FIELDS,
                   OLD_INFO     => $self->rule_info($attr->{ID}),
                   DATA         => $attr
                  } );

  return $self;
}



#**********************************************************
# Delete user info from all tables
#
# del(attr);
#**********************************************************
sub rule_del {
  my $self = shift;
  my ($attr) = @_;
  $self->query($db, "DELETE from bonus_rules WHERE id='$attr->{ID}';", 'do');
  return $self;
}


#**********************************************************
# list()
#**********************************************************
sub rule_list {
 my $self = shift;
 my ($attr) = @_;

 $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
 $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

 undef @WHERE_RULES;
 if ($attr->{TP_ID}) {
 	 push @WHERE_RULES, "tp_id='$attr->{TP_ID}'"; 
  }


 
 $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';
 
 $self->query($db, "SELECT period, rules, rule_value, actions, id
     FROM bonus_rules
     $WHERE 
     ORDER BY $SORT $DESC;");

 return $self if($self->{errno});

  my $list = $self->{list};

  return $list;
}
















































































#**********************************************************
# User information
# info()
#**********************************************************
sub user_info {
  my $self = shift;
  my ($id) = @_;
  
  my $WHERE = "WHERE uid='$id'";

  $self->query($db, "SELECT uid,
    tp_id,
    state
     FROM bonus_main
   $WHERE;");

  if ($self->{TOTAL} < 1) {
     $self->{errno} = 2;
     $self->{errstr} = 'ERROR_NOT_EXIST';
     return $self;
   }

  (
   $self->{UID}, 
   $self->{TP_ID}, 
   $self->{STATE}
  )= @{ $self->{list}->[0] };

  return $self;
}



#**********************************************************
# tp_add()
#**********************************************************
sub user_add {
  my $self = shift;
  my ($attr) = @_;
  my %DATA = $self->get_data($attr); 

  $self->query($db,  "INSERT INTO bonus_main (uid, tp_id, state)
        VALUES ('$DATA{UID}', '$DATA{TP_ID}', '$DATA{STATE}');", 'do');

  return $self;
}




#**********************************************************
# change()
#**********************************************************
sub user_change {
  my $self = shift;
  my ($attr) = @_;
  
  my %FIELDS = (UID      => 'uid',
                TP_ID    => 'tp_id',
                STATE    => 'state',
               );
  
  $attr->{STATE} = ($attr->{STATE}) ? 1 : 0;
  
  $self->changes($admin, { CHANGE_PARAM => 'UID',
                   TABLE        => 'bonus_main',
                   FIELDS       => \%FIELDS,
                   OLD_INFO     => $self->user_info($attr->{UID}),
                   DATA         => $attr
                  } );

  return $self;
}



#**********************************************************
# Delete user info from all tables
#
# del(attr);
#**********************************************************
sub user_del {
  my $self = shift;
  my ($attr) = @_;
  $self->query($db, "DELETE from bonus_main WHERE uid='$attr->{UID}';", 'do');

  return $self;
}


#**********************************************************
# list()
#**********************************************************
sub user_list {
 my $self = shift;
 my ($attr) = @_;

 $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
 $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
 $PG = ($attr->{PG}) ? $attr->{PG} : 0;
 $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;
 undef @WHERE_RULES;
 
 if ($attr->{TP_ID}) {
 	 push @WHERE_RULES, "tp_id='$attr->{TP_ID}'"; 
  }


 
 $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';
 
 $self->query($db, "SELECT u.id, pi.fio, b_tp.name, bu.state, bu.uid
     FROM (bonus_main bu, users u)
     
     LEFT JOIN users_pi pi ON (u.uid=pi.uid)
     LEFT JOIN bonus_tps b_tp ON (b_tp.id=bu.tp_id)
     WHERE bu.uid=u.uid
     ORDER BY $SORT $DESC
     LIMIT $PG, $PAGE_ROWS;");

 return $self if($self->{errno});

  my $list = $self->{list};

  return $list;
}



1

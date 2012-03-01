package Bonus;
# Bonus modules
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
use Bills;

my $Bill;
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
  $Bill=Bills->new($db, $admin, $CONF); 
  
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
   COMMENTS       => '',
   EXPIRE         => '0000-00-00',
   DESCRIBE       => '',
   METHOD         => 0,
   EXT_ID         => '',
   INNER_DESCRIBE => ''
  );

 
  $self = \%DATA;
  return $self;
}


##**********************************************************
## add()
##**********************************************************
#sub add {
#  my $self = shift;
#  my ($attr) = @_;
#  my %DATA = $self->get_data($attr); 
#
#  $self->query($db,  "INSERT INTO bonus_main (tp_id, range_begin, range_end, sum, comments, period)
#        VALUES ('$DATA{TP_ID}', 
#        '$DATA{RANGE_BEGIN}', '$DATA{RANGE_END}', '$DATA{SUM}', '$DATA{COMMENTS}', '$DATA{PERIOD}');", 'do');
#  return $self;
#}




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



##**********************************************************
## Delete user info from all tables
##
## del(attr);
##**********************************************************
#sub del {
#  my $self = shift;
#  my ($attr) = @_;
#  $self->query($db, "DELETE from bonus_main WHERE id='$attr->{ID}';", 'do');
#  return $self->{result};
#}




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


#**********************************************************
# add()
#**********************************************************
sub bonus_operation {
  my $self = shift;
  my ($user, $attr) = @_;

  %DATA = $self->get_data($attr, { default => defaults() }); 
 
  if ($DATA{SUM} <= 0) {
     $self->{errno} = 12;
     $self->{errstr} = 'ERROR_ENTER_SUM';
     return $self;
   }
  
  if ($DATA{CHECK_EXT_ID}) {
    $self->query($db, "SELECT id, date FROM bonus_log WHERE ext_id='$DATA{CHECK_EXT_ID}';");
    if ($self->{TOTAL} > 0) {
      $self->{errno}=7;
      $self->{errstr}='ERROR_DUBLICATE';
      $self->{ID}=$self->{list}->[0][0];
      $self->{DATE}=$self->{list}->[0][1];
      return $self;	
     }
   }
  
  #$db->{AutoCommit}=0; 
  $user->{EXT_BILL_ID} = $attr->{BILL_ID} if ($attr->{BILL_ID});
  
  if ($user->{EXT_BILL_ID} > 0) {
    my $bill_action_type = '';    
    if ($DATA{ACTION_TYPE}) {
    	$bill_action_type='take';
     }
    else {
    	$bill_action_type='add';
     }


      $Bill->info( { BILL_ID => $user->{EXT_BILL_ID} } );
      $Bill->action($bill_action_type, $user->{EXT_BILL_ID}, $DATA{SUM});
      if($Bill->{errno}) {
        return $self;
       }

    my $date = ($DATA{DATE}) ? "'$DATA{DATE}'" : 'now()';
    $self->query($db, "INSERT INTO bonus_log (uid, bill_id, date, sum, dsc, ip, last_deposit, aid, method, ext_id,
           inner_describe, action_type, expire) 
           values ('$user->{UID}', '$user->{EXT_BILL_ID}', $date, '$DATA{SUM}', '$DATA{DESCRIBE}', INET_ATON('$admin->{SESSION_IP}'), 
           '$Bill->{DEPOSIT}', '$admin->{AID}', '$DATA{METHOD}', 
           '$DATA{EXT_ID}', '$DATA{INNER_DESCRIBE}', '$DATA{ACTION_TYPE}', '$DATA{EXPIRE}');", 'do');

    $self->{BONUS_PAYMENT_ID}=$self->{INSERT_ID};
  }
  else {
    $self->{errno}=14;
    $self->{errstr}='No Bill';
  }
  
  #$db->commit;
  #$db->rollback;
  
  return $self;
}


#**********************************************************
# del $user, $id
#**********************************************************
sub bonus_operation_del {
  my $self = shift;
  my ($user, $id) = @_;
  
  $self->query($db, "SELECT sum, bill_id, action_type from bonus_log WHERE id='$id';");

  if ($self->{TOTAL} < 1) {
     $self->{errno} = 2;
     $self->{errstr} = 'ERROR_NOT_EXIST';
     return $self;
   }
  elsif($self->{errno}) {
     return $self;
   }

  my($sum, $bill_id, $action_type) = @{ $self->{list}->[0] };
  my $bill_action = 'take';
  if ($action_type) {
  	 $bill_action='add';
   }
  $Bill->action($bill_action, $bill_id, $sum); 

  $self->query($db, "DELETE FROM bonus_log WHERE id='$id';", 'do');
  $admin->action_add($user->{UID}, "BONUS $bill_action:$id SUM:$sum", { TYPE => 10 });

  return $self;
}



#**********************************************************
# list()
#**********************************************************
sub bonus_operation_list {
 my $self = shift;
 my ($attr) = @_;

 $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
 $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
 $PG   = ($attr->{PG}) ? $attr->{PG} : 0;
 $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;
 $self->{SEARCH_FIELDS} ='';
 undef @WHERE_RULES;
 my $EXT_TABLES = '';
 
 if ($attr->{UID}) {
    push @WHERE_RULES, "p.uid='$attr->{UID}' ";
  }
 elsif ($attr->{LOGIN_EXPR}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{LOGIN_EXPR}, 'STR', 'u.id') };
  }
 
 if ($attr->{AID}) {
    push @WHERE_RULES, "p.aid='$attr->{AID}' ";
  }

 if ($attr->{A_LOGIN}) {
 	 push @WHERE_RULES,  @{ $self->search_expr($attr->{A_LOGIN}, 'STR', 'a.id') };
  }

 if ($attr->{DESCRIBE}) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{DESCRIBE}, 'STR', 'p.dsc') };
  }

 if ($attr->{INNER_DESCRIBE}) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{INNER_DESCRIBE}, 'STR', 'p.inner_describe') };
  }


 if ($attr->{SUM}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{SUM}, 'INT', 'p.sum') };
  }

 if (defined($attr->{METHOD})) {
   push @WHERE_RULES, "p.method IN ($attr->{METHOD}) ";
  }

 if ($attr->{DOMAIN_ID}) {
   push @WHERE_RULES, "u.domain_id='$attr->{DOMAIN_ID}' ";
  }

 if ($attr->{DATE}) {
    push @WHERE_RULES, @{ $self->search_expr("$attr->{DATE}", 'INT', 'date_format(p.date, \'%Y-%m-%d\')') };
  }
 elsif ($attr->{MONTH}) {
    my $value = $self->search_expr("$attr->{MONTH}", 'INT');
    push @WHERE_RULES,  " date_format(p.date, '%Y-%m')$value ";
  }
 # Date intervals
 elsif ($attr->{FROM_DATE}) {
   push @WHERE_RULES, @{ $self->search_expr(">=$attr->{FROM_DATE}", 'DATE', 'date_format(p.date, \'%Y-%m-%d\')') },
   @{ $self->search_expr("<=$attr->{TO_DATE}", 'DATE', 'date_format(p.date, \'%Y-%m-%d\')') };
  }
 elsif ($attr->{PAYMENT_DAYS}) {
 	 my $expr = '=';
 	 if ($attr->{PAYMENT_DAYS} =~ s/^(<|>)//) {
 	   $expr = $1;
 	  }
 	 push @WHERE_RULES, "p.date $expr curdate() - INTERVAL $attr->{PAYMENT_DAYS} DAY";
  }


 if ($attr->{EXPIRE}) {
    push @WHERE_RULES, @{ $self->search_expr("$attr->{EXPIRE}", 'INT', 'date_format(p.expire, \'%Y-%m-%d\')') };
  }

 if ($attr->{DEPOSIT}) {
    push @WHERE_RULES, @{ $self->search_expr("$attr->{DEPOSIT}", 'INT', 'b.deposit', { EXT_FIELD => 1 }) };
    $EXT_TABLES .= "INNER JOIN bills b ON p.bill_id=b.id";
  }


 if ($attr->{BILL_ID}) {
 	 push @WHERE_RULES, @{ $self->search_expr("$attr->{BILL_ID}", 'INT', 'p.bill_id') };
  }
 elsif ($attr->{COMPANY_ID}) {
 	 push @WHERE_RULES, @{ $self->search_expr($attr->{COMPANY_ID}, 'INT', 'u.company_id') };
  }

 if ($attr->{EXT_ID}) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{EXT_ID}, 'STR', 'p.ext_id') };
  }
 elsif($attr->{EXT_IDS}) {
 	 push @WHERE_RULES, "p.ext_id in ($attr->{EXT_IDS})";
  }
 
 if ($attr->{ID}) {
 	 push @WHERE_RULES, @{ $self->search_expr("$attr->{ID}", 'INT', 'p.id') };
  }

 # Show groups
 if ($attr->{GIDS}) {
    push @WHERE_RULES, "u.gid IN ( $attr->{GIDS} )";
  }
 elsif ($attr->{GID}) {
    push @WHERE_RULES, "u.gid='$attr->{GID}'";
  }

 if($attr->{FIO}) {
   $EXT_TABLES .= 'LEFT JOIN users_pi pi ON (u.uid=pi.uid)';
   $self->{SEARCH_FIELDS} .= 'pi.fio, ';
   $self->{SEARCH_FIELDS_COUNT}++;
  }

 $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';
 
 $self->query($db, "SELECT p.id, u.id, $self->{SEARCH_FIELDS} p.date, p.dsc, p.sum, p.last_deposit, p.expire, p.method, 
      p.ext_id, p.bill_id, if(a.name is null, 'Unknown', a.name),  
      INET_NTOA(p.ip), p.action_type, p.uid, p.inner_describe
    FROM bonus_log p
    LEFT JOIN users u ON (u.uid=p.uid)
    LEFT JOIN admins a ON (a.aid=p.aid)
    $EXT_TABLES
    $WHERE 
    GROUP BY p.id
    ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;");

 $self->{SUM}='0.00';

 return $self->{list}  if ($self->{TOTAL} < 1);
 my $list = $self->{list};

 $self->query($db, "SELECT count(p.id), sum(p.sum), count(DISTINCT p.uid) FROM bonus_log p
  LEFT JOIN users u ON (u.uid=p.uid)
  LEFT JOIN admins a ON (a.aid=p.aid)
  $EXT_TABLES
   $WHERE");

 ( $self->{TOTAL},
   $self->{SUM},
   $self->{TOTAL_USERS} )= @{ $self->{list}->[0] };

 return $list;
}













#**********************************************************
# 
# service_discount_info()
#**********************************************************
sub service_discount_info {
  my $self = shift;
  my ($id) = @_;
  
  my $WHERE = "WHERE uid='$id'";

  $self->query($db, "SELECT id,
    service_period,
    registration_days,
    discount,
    discount_days
     FROM bonus_service_discount
   $WHERE;");

  if ($self->{TOTAL} < 1) {
     $self->{errno} = 2;
     $self->{errstr} = 'ERROR_NOT_EXIST';
     return $self;
   }

  (
   $self->{ID}, 
   $self->{SERVICE_PERIOD}, 
   $self->{REGISTRATION_DAY}, 
   $self->{DISCOUNT}, 
   $self->{DISCOUNT_DAYS}
  )= @{ $self->{list}->[0] };

  return $self;
}



#**********************************************************
# service_discount_add()
#**********************************************************
sub service_discount_add {
  my $self = shift;
  my ($attr) = @_;
  my %DATA = $self->get_data($attr); 


  $self->{debug}=1;
  
  $self->query($db,  "INSERT INTO bonus_service_discount (service_period, registration_days, discount, discount_days)
        VALUES ('$DATA{SERVICE_PERIOD}', '$DATA{REGISTRATION_DAYS}', '$DATA{DISCOUNT}', '$DATA{DISCOUNT_DAYS}');", 'do');

  return $self;
}




#**********************************************************
# change()
#**********************************************************
sub service_discount_change {
  my $self = shift;
  my ($attr) = @_;
  
  my %FIELDS = ( ID               => 'id', 
                 SERVICE_PERIOD   => 'service_period', 
                 REGISTRATION_DAY => 'registration_day', 
                 DISCOUNT         => 'discount', 
                 DISCOUNT_DAYS    => 'discount_days'
               );
  
  $attr->{STATE} = ($attr->{STATE}) ? 1 : 0;
  
  $self->changes($admin, { CHANGE_PARAM => 'ID',
                   TABLE        => 'bonus_service_discount',
                   FIELDS       => \%FIELDS,
                   OLD_INFO     => $self->service_discount_info($attr->{ID}),
                   DATA         => $attr
                  } );

  return $self;
}



#**********************************************************
#
# service_discount_del(attr);
#**********************************************************
sub service_discount_del {
  my $self = shift;
  my ($attr) = @_;
  $self->query($db, "DELETE from bonus_service_discount WHERE id='$attr->{ID}';", 'do');

  return $self;
}


#**********************************************************
# service_discount_list()
#**********************************************************
sub service_discount_list {
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


 if ($attr->{REGISTRATION_DAYS}) {
 	 push @WHERE_RULES, @{ $self->search_expr("$attr->{REGISTRATION_DAYS}", 'INT', 'registration_days') };
  }

 if ($attr->{PERIODS}) {
 	 push @WHERE_RULES, @{ $self->search_expr("$attr->{PERIODS}", 'INT', 'service_period') };
  }





 
 $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';
 
 $self->query($db, "SELECT service_period, registration_days, discount, discount_days, id
     FROM bonus_service_discount
     $WHERE 
     ORDER BY $SORT $DESC
     LIMIT $PG, $PAGE_ROWS;");

 return $self if($self->{errno});

 my $list = $self->{list};

 return $list;
}


1

package Voip;
# Voip  managment functions
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
use Tariffs;
my $tariffs = Tariffs->new($db, $CONF, $admin);

my $MODULE='Voip';

@ISA  = ("main");
my $uid;


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
sub user_info {
  my $self = shift;
  my ($uid, $attr) = @_;

  my @WHERE_RULES  = ();
  my $WHERE = '';

  if(defined($attr->{LOGIN})) {
    use Users;
    my $users = Users->new($db, $admin, $CONF);   
    $users->info(0, {LOGIN => "$attr->{LOGIN}"});
    if ($users->{errno}) {
       $self->{errno} = 2;
       $self->{errstr} = 'ERROR_NOT_EXIST';
       return $self; 
     }

    $uid             = $users->{UID};
    $self->{DEPOSIT} = $users->{DEPOSIT}; 
    push @WHERE_RULES, "voip.uid='$uid'";
   }
  elsif($uid > 0){
  	push @WHERE_RULES, "voip.uid='$uid'";
   }

  if(defined($attr->{NUMBER})) {
  	push @WHERE_RULES, "voip.number='$attr->{NUMBER}'";
  }

  if(defined($attr->{IP})) {
  	push @WHERE_RULES, "voip.ip=INET_ATON('$attr->{IP}')";
  }
  
  #my $PASSWORD = '0'; 
  
  $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';
  
  $self->query($db, "SELECT 
   voip.uid, 
   voip.number,
   voip.tp_id, 
   tarif_plans.name, 
   INET_NTOA(voip.ip),
   voip.disable,
   voip.allow_answer,
   voip.allow_calls,
   voip.cid,
   voip.logins,
   voip.registration,
   tarif_plans.id
     FROM voip_main voip
     LEFT JOIN voip_tps tp ON (voip.tp_id=tp.id)
     LEFT JOIN tarif_plans ON (tarif_plans.tp_id=voip.tp_id)
   $WHERE;");

  if ($self->{TOTAL} < 1) {
     $self->{errno} = 2;
     $self->{errstr} = 'ERROR_NOT_EXIST';
     return $self;
   }


  ($self->{UID},
   $self->{NUMBER},
   $self->{TP_ID}, 
   $self->{TP_NAME}, 
   $self->{IP}, 
   $self->{DISABLE},
   $self->{ALLOW_ANSWER},
   $self->{ALLOW_CALLS},
   $self->{CID},
   $self->{SIMULTANEOUSLY},
   $self->{REGISTRATION},
   $self->{TP_NUM}

  )= @{ $self->{list}->[0] };
  

  
  return $self;
}



#**********************************************************
#
#**********************************************************
sub defaults {
  my $self = shift;

  %DATA = (
   TP_ID    => 0, 
   NUMBER   => 0, 
   DISABLE  => 0, 
   IP       => '0.0.0.0', 
   CID      => '',
  );

 
  $self = \%DATA;
  return $self;
}


#**********************************************************
# add()
#**********************************************************
sub user_add {
  my $self = shift;
  my ($attr) = @_;
  
  %DATA = $self->get_data($attr); 

  $self->query($db,  "INSERT INTO voip_main (uid, number, registration, tp_id, 
             disable, ip, cid, allow_answer, allow_calls
       )
        VALUES ('$DATA{UID}', '$DATA{NUMBER}', now(),
        '$DATA{TP_ID}', '$DATA{DISABLE}', INET_ATON('$DATA{IP}'), 
        LOWER('$DATA{CID}'), '$DATA{ALLOW_ANSWER}', '$DATA{ALLOW_CALLS}');", 'do');
  
  return $self if ($self->{errno});
  
 
  $admin->action_add($DATA{UID}, "ADDED", { TYPE => 1 });


  return $self;
}




#**********************************************************
# change()
#**********************************************************
sub user_change {
  my $self = shift;
  my ($attr) = @_;
  
  my %FIELDS = (SIMULTANEONSLY => 'logins',
                NUMBER					 => 'number',
                DISABLE          => 'disable',
                IP               => 'ip',
                TP_ID            => 'tp_id',
                CID              => 'cid',
                UID              => 'uid',
                FILTER_ID        => 'filter_id',
                ALLOW_ANSWER     => 'allow_answer',
                ALLOW_CALLS      => 'allow_calls'                
             );


  $attr->{ALLOW_ANSWER} = ($attr->{ALLOW_ANSWER}) ? 1 : 0;
  $attr->{ALLOW_CALLS}  = ($attr->{ALLOW_CALLS})  ? 1 : 0;

  $self->changes($admin,  { CHANGE_PARAM => 'UID',
                   TABLE        => 'voip_main',
                   FIELDS       => \%FIELDS,
                   OLD_INFO     => $self->user_info($attr->{UID}),
                   DATA         => $attr
                  } );

  return $self->{result};
}



#**********************************************************
# Delete user info from all tables
#
# del(attr);
#**********************************************************
sub user_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query($db, "DELETE from voip_main WHERE uid='$self->{UID}';", 'do');
  $admin->action_add($self->{UID}, "$self->{UID}", { TYPE => 10 });

  return $self->{result};
}




#**********************************************************
# list()
#**********************************************************
sub user_list {
 my $self = shift;
 my ($attr) = @_;
 my @list = ();

 $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
 $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
 $PG = ($attr->{PG}) ? $attr->{PG} : 0;
 $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

 
 $self->{SEARCH_FIELDS} = '';
 $self->{SEARCH_FIELDS_COUNT}=0;

 undef @WHERE_RULES;
 push @WHERE_RULES, "u.uid = service.uid";
 
 if ($attr->{USERS_WARNINGS}) {
   $self->query($db, " SELECT u.id, pi.email, dv.tp_id, u.credit, b.deposit, tp.name, tp.uplimit
         FROM (users u, voip_main dv, bills b)
         LEFT JOIN tarif_plans tp ON dv.tp_id = tp.id
         LEFT JOIN users_pi pi ON u.uid = dv.uid
         WHERE u.bill_id=b.id
           and b.deposit<tp.uplimit AND tp.uplimit > 0 AND b.deposit+u.credit>0
         ORDER BY u.id;");

   my $list = $self->{list};
   return $list;
  }
 elsif($attr->{CLOSED}) {
   $self->query($db, "SELECT u.id, pi.fio, if(company.id IS NULL, b.deposit, b.deposit), 
      u.credit, tp.name, u.disable, 
      u.uid, u.company_id, u.email, u.tp_id, if(l.start is NULL, '-', l.start)
     FROM (users u, bills b)
     LEFT JOIN users_pi pi ON u.uid = dv.uid
     LEFT JOIN tarif_plans tp ON  (tp.id=u.tp_id) 
     LEFT JOIN companies company ON  (u.company_id=company.id) 
     LEFT JOIN voip_log l ON  (l.uid=u.uid) 
     WHERE  
        u.bill_id=b.id
        and (b.deposit+u.credit-tp.credit_tresshold<=0)
        or (
        (u.expire<>'0000-00-00' and u.expire < CURDATE())
        AND (u.activate<>'0000-00-00' and u.activate > CURDATE())
        )
        or u.disable=1
     GROUP BY u.uid
     ORDER BY $SORT $DESC;");

   my $list = $self->{list};
   return $list;
  }

 if ($attr->{LOGIN}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{LOGIN}, 'STR', 'u.id') }; 
  }

 

 if ($attr->{IP}) {
    if ($attr->{IP} =~ m/\*/g) {
      my ($i, $first_ip, $last_ip);
      my @p = split(/\./, $attr->{IP});
      for ($i=0; $i<4; $i++) {

         if ($p[$i] eq '*') {
           $first_ip .= '0';
           $last_ip .= '255';
          }
         else {
           $first_ip .= $p[$i];
           $last_ip .= $p[$i];
          }
         if ($i != 3) {
           $first_ip .= '.';
           $last_ip .= '.';
          }
       }
      push @WHERE_RULES, "(service.ip>=INET_ATON('$first_ip') and service.ip<=INET_ATON('$last_ip'))";
     }
    else {
      my $value = $self->search_expr($attr->{IP}, 'IP');
      push @WHERE_RULES, "service.ip$value";
    }

    $self->{SEARCH_FIELDS} = 'INET_NTOA(service.ip), ';
    $self->{SEARCH_FIELDS_COUNT}++;
  }

 if ($attr->{PHONE}) {
    my $value = $self->search_expr($attr->{PHONE}, 'INT');
    push @WHERE_RULES, "u.phone$value";
  }


 if ($attr->{DEPOSIT}) {
    my $value = $self->search_expr($attr->{DEPOSIT}, 'INT');
    push @WHERE_RULES, "u.deposit$value";
  }


 if ($attr->{CID}) {
    $attr->{CID} =~ s/\*/\%/ig;
    push @WHERE_RULES, "service.cid LIKE '$attr->{CID}'";
    $self->{SEARCH_FIELDS} .= 'service.cid, ';
    $self->{SEARCH_FIELDS_COUNT}++;
  }

 if ($attr->{PASSWORD}) {
    $self->{SEARCH_FIELDS} .= "DECODE(u.password, '$CONF->{secretkey}'), ";
    $self->{SEARCH_FIELDS_COUNT}++;
  }

 if ($attr->{COMMENTS}) {
   $attr->{COMMENTS} =~ s/\*/\%/ig;
   push @WHERE_RULES, "pi.comments LIKE '$attr->{COMMENTS}'";
  }


 if ($attr->{FIO}) {
    $attr->{FIO} =~ s/\*/\%/ig;
    push @WHERE_RULES, "pi.fio LIKE '$attr->{FIO}'";
  }

 # Show users for spec tarifplan 
 if ($attr->{TP_ID}) {
    push @WHERE_RULES, "service.tp_id='$attr->{TP_ID}'";
  }

 # Show debeters
 if ($attr->{DEBETERS}) {
    push @WHERE_RULES, "u.id LIKE '$attr->{FIRST_LETTER}%'";
  }

 # Show debeters
 if ($attr->{COMPANY_ID}) {
    push @WHERE_RULES, "u.company_id='$attr->{COMPANY_ID}'";
  }

 # Show groups
 if ($attr->{GIDS}) {
   push @WHERE_RULES, "u.gid IN ($attr->{GIDS})"; 
  }
 elsif ($attr->{GID}) {
   push @WHERE_RULES, "u.gid='$attr->{GID}'";
  }

#Activate
 if ($attr->{ACTIVATE}) {
   my $value = $self->search_expr("$attr->{ACTIVATE}", 'INT');
   push @WHERE_RULES, "(u.activate='0000-00-00' or u.activate$value)"; 
 }

#Expire
 if ($attr->{EXPIRE}) {
   my $value = $self->search_expr("$attr->{EXPIRE}", 'INT');
   push @WHERE_RULES, "(u.expire='0000-00-00' or u.expire$value)"; 
 }

#DIsable
 if ($attr->{DISABLE}) {
   push @WHERE_RULES, "u.disable='$attr->{DISABLE}'"; 
 }

 if (defined($attr->{STATUS}) && $attr->{STATUS} ne '') {
   push @WHERE_RULES,  @{ $self->search_expr($attr->{STATUS}, 'INT', 'service.disable') };
  }
 
 if (defined($attr->{LOGIN_STATUS})) {
   push @WHERE_RULES, "u.disable='$attr->{LOGIN_STATUS}'"; 
  }



 if ($attr->{NUMBER}) {
    push @WHERE_RULES,  @{ $self->search_expr("$attr->{NUMBER}", 'INT', 'service.number') };
 }

 
 $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';
 
 
 $self->query($db, "SELECT u.id, 
      pi.fio, if(u.company_id > 0, cb.deposit, b.deposit),
      u.credit, tp.name, 
      u.disable, 
      service.number,
      $self->{SEARCH_FIELDS}
      u.uid, u.company_id, pi.email, service.tp_id, u.activate, u.expire, 
      if(u.company_id > 0, company.bill_id, u.bill_id) AS bill_id,
      service.disable
     FROM (users u, voip_main service)
     LEFT JOIN users_pi pi ON (u.uid = pi.uid)
     LEFT JOIN bills b ON u.bill_id = b.id
     LEFT JOIN tarif_plans tp ON (tp.id=service.tp_id) 
     LEFT JOIN companies company ON  (u.company_id=company.id) 
     LEFT JOIN bills cb ON  (company.bill_id=cb.id)

     $WHERE 
     GROUP BY u.uid
     ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;");

 return $self if($self->{errno});

 my $list = $self->{list};

 if ($self->{TOTAL} >= 0) {
    $self->query($db, "SELECT count(u.id) FROM (users u, voip_main service) $WHERE");
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
# route_add
#**********************************************************
sub route_add {
  my $self = shift;
  my ($attr) = @_;
  
  %DATA = $self->get_data($attr); 
  my $action = 'INSERT';
  if ($attr->{REPLACE}) {
  	$action = 'REPLACE';
   }

  $self->query($db,  "$action INTO voip_routes (prefix, parent, name, disable, date,
        descr) 
        VALUES ('$DATA{ROUTE_PREFIX}', '$DATA{PARENT_ID}',  '$DATA{ROUTE_NAME}', '$DATA{DISABLE}', now(),
        '$DATA{DESCRIBE}');", 'do');

  return $self if ($self->{errno});

  $admin->system_action_add("ROUTES: $DATA{ROUTE_PREFIX}", { TYPE => 1 });
  return $self;
}


#**********************************************************
# Route information
# route_info()
#**********************************************************
sub route_info {
  my $self = shift;
  my ($id, $attr) = @_;

  $self->query($db, "SELECT 
   id,
   prefix,
   parent,
   name,
   date,
   disable,
   descr
     FROM voip_routes
   WHERE id='$id';");

  if ($self->{TOTAL} < 1) {
     $self->{errno} = 2;
     $self->{errstr} = 'ERROR_NOT_EXIST';
     return $self;
   }

  ($self->{ROUTE_ID},
   $self->{ROUTE_PREFIX}, 
   $self->{PARENT_ID}, 
   $self->{ROUTE_NAME}, 
   $self->{DATE},
   $self->{DISABLE},
   $self->{DESCRIBE}
  )= @{ $self->{list}->[0] };  
  
  return $self;
}

#**********************************************************
# route_del
#**********************************************************
sub route_del {
  my $self = shift;
  my ($id, $attr) = @_;
  
  my $WHERE = '';
  
  if ($id > 0) {
  	$WHERE = "id='$id'";
   }
  elsif ($attr->{ALL}) {
  	$WHERE  = "id > '0'";
  	$id='ALL';
   }
  
  $self->query($db,  "DELETE FROM voip_routes WHERE $WHERE;", 'do');
  return $self if ($self->{errno});

  $admin->system_action_add("ROUTES: $id", { TYPE => 10 });

  return $self;
}

#**********************************************************
# route_change()
#**********************************************************
sub route_change {
  my $self = shift;
  my ($attr) = @_;
  
  my %FIELDS = (ROUTE_ID       => 'id',
   							PARENT_ID      => 'parent',
                DISABLE        => 'disable',
                ROUTE_PREFIX   => 'prefix',
                ROUTE_NAME     => 'name',
                DESCRIBE       => 'descr',
             );


  $self->changes($admin,  { CHANGE_PARAM => 'ROUTE_ID',
                   TABLE        => 'voip_routes',
                   FIELDS       => \%FIELDS,
                   OLD_INFO     => $self->route_info($attr->{ROUTE_ID}),
                   DATA         => $attr
                  } );

  return $self->{result};
}




#**********************************************************
# route_list()
#**********************************************************
sub routes_list {
 my $self = shift;
 my ($attr) = @_;
 my @list = ();

 $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
 $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
 $PG = ($attr->{PG}) ? $attr->{PG} : 0;
 $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;


 undef @WHERE_RULES;

 if ($attr->{ROUTE_PREFIX}) {
   $attr->{ROUTE_PREFIX} =~ s/\*/\%/ig;
   push @WHERE_RULES, "r.prefix LIKE '$attr->{ROUTE_PREFIX}'";
  }

 if ($attr->{DESCRIBE}) {
   $attr->{DESCRIBE} =~ s/\*/\%/ig;
   push @WHERE_RULES, "r.descr LIKE '$attr->{DESCRIBE}'";
  }

 if ($attr->{ROUTE_NAME}) {
   $attr->{ROUTE_NAME} =~ s/\*/\%/ig;
   push @WHERE_RULES, "r.name LIKE '$attr->{ROUTE_NAME}'";
  }

 $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';

 $self->query($db, "SELECT r.prefix, r.name, r.disable, r.date, r.id, r.parent
     FROM voip_routes r
     $WHERE 
     ORDER BY $SORT $DESC 
     LIMIT $PG, $PAGE_ROWS;");

 return $self if($self->{errno});

 my $list = $self->{list};

 if ($self->{TOTAL} >= 0) {
    $self->query($db, "SELECT count(r.id) FROM voip_routes r $WHERE");
    ($self->{TOTAL}) = @{ $self->{list}->[0] };
   }

  return $list;
}


#**********************************************************
# route price list
# rp_list()
#**********************************************************
sub rp_add {
 my $self = shift;
 my ($attr) = @_;

 my $value = '';
		 while(my($k, $v)=each %$attr) {
		 	  if($k =~ /^p_/) {
		 	    my(undef, $route, $interval)=split(/_/, $k, 3);

		 	    my $trunk = $attr->{"t_". $route ."_" . $interval} ||  0;
		 	    my $extra_tarif = $attr->{"et_". $route ."_" . $interval} ||  0;
		 	    my $unit_price  = 0;
		 	    if ($CONF->{VOIP_UNIT_TARIFICATION}) {
		 	      $unit_price = $v;
		 	      $v  = $v * $attr->{EXCHANGE_RATE} if ($attr->{EXCHANGE_RATE} && $attr->{EXCHANGE_RATE} > 0);
		 	     }
		 	    $value .= "('$route', '$interval', '$v', now(), '$trunk', '$extra_tarif', '$unit_price'),";
		     }
		  }

 chop($value);

 $self->query($db, "REPLACE INTO voip_route_prices (route_id, interval_id, price, date, trunk, extra_tarification, unit_price) VALUES
  $value;", 'do');
 return $self if($self->{errno});

 return $self;
}



#**********************************************************
# route price change exchange rate
# rp_change_exhange_rate()
#**********************************************************
sub rp_change_exhange_rate {
 my $self = shift;
 my ($attr) = @_;
 
 if ($attr->{EXCHANGE_RATE} > 0) {
   $self->query($db, "UPDATE voip_route_prices SET price = unit_price * $attr->{EXCHANGE_RATE};", 'do');
   return $self if($self->{errno});
  }

 return $self;
}


#**********************************************************
# route price list
# rp_list()
#**********************************************************
sub rp_list {
 my $self = shift;
 my ($attr) = @_;
 my @list = ();

 
 my $search_fields = '';
 undef @WHERE_RULES;

 if ($attr->{PRICE}) {
    my $value = $self->search_expr($attr->{PRICE}, 'INT');
    push @WHERE_RULES, "rp.price$value";
  }


 $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';

 $self->query($db, "SELECT rp.interval_id, rp.route_id, rp.date, rp.price, rp.trunk, rp.extra_tarification, rp.unit_price
     FROM voip_route_prices rp 
     $WHERE 
     ORDER BY $SORT $DESC 
;");

 return $self if($self->{errno});

 my $list = $self->{list};

 if ($self->{TOTAL} >= 0) {
    $self->query($db, "SELECT count(route_id) FROM voip_route_prices rp $WHERE");
    ($self->{TOTAL}) = @{ $self->{list}->[0] };
   }

  return $list;
}



#**********************************************************
# list
#**********************************************************
sub tp_list() {
  my $self = shift;
  my ($attr) = @_;

 my $WHERE = 'WHERE tp.tp_id=voip.id';

 $self->query($db, "SELECT tp.id, tp.name, if(sum(i.tarif) is NULL or sum(i.tarif)=0, 0, 1), 
    tp.payment_type,
    tp.day_fee, tp.month_fee, 
    tp.logins, 
    tp.age,
    tp.tp_id
    FROM (tarif_plans tp, voip_tps voip)
    LEFT JOIN intervals i ON (i.tp_id=tp.tp_id)
    $WHERE
    GROUP BY tp.id
    ORDER BY $SORT $DESC;");

 return $self->{list};
}








#**********************************************************
# Default values
#**********************************************************
sub tp_defaults {
  my $self = shift;

  my %DATA = ( TP_ID => 0, 
            NAME => '',  
            TIME_TARIF => '0.00000',
            DAY_FEE => '0,00',
            MONTH_FEE => '0.00',
            SIMULTANEOUSLY => 0,
            AGE => 0,
            DAY_TIME_LIMIT => 0,
            WEEK_TIME_LIMIT => 0,
            MONTH_TIME_LIMIT => 0,
            ACTIV_PRICE => '0.00',
            CHANGE_PRICE         => '0.00',
            CREDIT_TRESSHOLD     => '0.00',
            ALERT                => 0,
            MAX_SESSION_DURATION => 0,
            PAYMENT_TYPE         => 0,
            MIN_SESSION_COST     => '0.00000',
            RAD_PAIRS            => '',
            FIRST_PERIOD         => 0,
            FIRST_PERIOD_STEP    => 0,
            NEXT_PERIOD          => 0,
            NEXT_PERIOD_STEP     => 0,
            FREE_TIME            => 0
         );   
 
 
  $self->{DATA} = \%DATA;

  return \%DATA;
}


#**********************************************************
# Add
#**********************************************************
sub tp_add {
  my $self = shift;
  my ($attr) = @_;


  $attr->{MODULE}='Voip';
  $tariffs->add({ %$attr });

  $tariffs->{TP_ID} = $tariffs->{INSERT_ID};

  if (defined($tariffs->{errno})) {
  	$self->{errno} = $tariffs->{errno};
  	return $self;
  }

  my $DATA = tp_defaults();
  
  %DATA = $self->get_data($attr, { default => $DATA }); 

  $self->query($db, "INSERT INTO voip_tps (id, 
     rad_pairs,
     max_session_duration, 
     min_session_cost, 
     day_time_limit, 
     week_time_limit,  
     month_time_limit, 

     first_period,
     first_period_step,
     next_period,
     next_period_step,
     free_time,
     time_division
     )
    values ('$tariffs->{TP_ID}', 
  '$DATA{RAD_PAIRS}', 
  '$DATA{MAX_SESSION_DURATION}', 
  '$DATA{MIN_SESSION_COST}', 
  '$DATA{DAY_TIME_LIMIT}', 
  '$DATA{WEEK_TIME_LIMIT}',  
  '$DATA{MONTH_TIME_LIMIT}', 

  '$DATA{FIRST_PERIOD}',
  '$DATA{FIRST_PERIOD_STEP}',
  '$DATA{NEXT_PERIOD}', 
  '$DATA{NEXT_PERIOD_STEP}', 
  '$DATA{FREE_TIME}',
  '$DATA{TIME_DIVISION}');", 'do');

  return $self;
}


#**********************************************************
# change
#**********************************************************
sub tp_change {
  my $self = shift;
  my ($tp_id, $attr) = @_;


  #$attr->{MODULE}='Voip';
  $tariffs->change($tp_id, { %$attr, MODULE=>'Voip' });
  if (defined($tariffs->{errno})) {
  	$self->{errno} = $tariffs->{errno};
  	return $self;
  }

  my %FIELDS = ( TP_ID => 'id', 
            DAY_TIME_LIMIT =>   'day_time_limit',
            WEEK_TIME_LIMIT =>  'week_time_limit',
            MONTH_TIME_LIMIT => 'month_time_limit',
            MAX_SESSION_DURATION => 'max_session_duration',
            MIN_SESSION_COST     => 'min_session_cost',
            RAD_PAIRS            => 'rad_pairs',
            FIRST_PERIOD         => 'first_period',
            FIRST_PERIOD_STEP    => 'first_period_step',
            NEXT_PERIOD          => 'next_period',
            NEXT_PERIOD_STEP     => 'next_period_step',
            FREE_TIME            => 'free_time',
            TIME_DIVISION        => 'time_division'
         );   

	$self->changes($admin, { CHANGE_PARAM => 'TP_ID',
		                TABLE        => 'voip_tps',
		                FIELDS       => \%FIELDS,
		                OLD_INFO     => $self->tp_info($tp_id, $attr),
		                DATA         => $attr
		              } );

  
  $self->tp_info($tp_id);
	
	return $self;
}

#**********************************************************
# del
#**********************************************************
sub tp_del {
  my $self = shift;
  my ($id) = @_;
  	
  $self->query($db, "DELETE FROM voip_tps WHERE id='$id';", 'do');
  $tariffs->del($id);
  
  
 return $self;
}

#**********************************************************
# Info
#**********************************************************
sub tp_info {
  my $self = shift;
  my ($id, $attr) = @_;
  
  
  $self = $tariffs->info($attr->{TP_ID});
  
  if ($attr->{CHG_TP_ID}) {
    $self = $tariffs->info($attr->{CHG_TP_ID});
   }
  else {
    $self = $tariffs->info($id);
   }

  if (defined($self->{errno})) {
  	return $self;
  }


  $self->query($db, "SELECT tp.id, 
      voip.day_time_limit, 
      voip.week_time_limit,  
      voip.month_time_limit, 
      voip.max_session_duration,
      voip.min_session_cost,
      voip.rad_pairs,
     voip.first_period,
     voip.first_period_step,
     voip.next_period,
     voip.next_period_step,
     voip.free_time,
     voip.id,
     voip.time_division

    FROM (voip_tps voip, tarif_plans tp)
    WHERE 
    voip.id=tp.tp_id AND
    voip.id='$id';");

  if ($self->{TOTAL} < 1) {
     $self->{errno} = 2;
     $self->{errstr} = 'ERROR_NOT_EXIST';
     return $self;
   }

 
  ($self->{ID}, 
   $self->{DAY_TIME_LIMIT}, 
   $self->{WEEK_TIME_LIMIT}, 
   $self->{MONTH_TIME_LIMIT}, 
   $self->{MAX_SESSION_DURATION},
   $self->{MIN_SESSION_COST},
   $self->{RAD_PAIRS},
   $self->{FIRST_PERIOD},
   $self->{FIRST_PERIOD_STEP},
   $self->{NEXT_PERIOD},
   $self->{NEXT_PERIOD_STEP},
   $self->{FREE_TIME},
   $self->{TP_ID},
   $self->{TIME_DIVISION}
  ) = @{ $self->{list}->[0] };


  return $self;
}





#**********************************************************
# route_add
#**********************************************************
sub trunk_add {
  my $self = shift;
  my ($attr) = @_;
  
  %DATA = $self->get_data($attr); 


  $self->query($db,  "INSERT INTO voip_trunks (	name,
	trunkprefix,
	protocol,
	provider_ip,
	removeprefix,
	addprefix,
	secondusedreal,
	secondusedcarrier,
	secondusedratecard,
	failover_trunk,
	addparameter,
	provider_name
 ) 
        VALUES ('$DATA{NAME}', '$DATA{TRUNKPREFIX}',  '$DATA{PROTOCOL}', '$DATA{PROVIDER_IP}', 
        '$DATA{REMOVE_PREFIX}',
        '$DATA{ADD_PREFIX}',
        '$DATA{SECONDUSEDREAL}',
        '$DATA{SECONDUSEDCARRIER}',
        '$DATA{SECONDUSEDRATECARD}',
        '$DATA{FAILOVER_TRUNK}',
        '$DATA{ADDPARAMETER}',
        '$DATA{PROVIDER_NAME}'
        );", 'do');


  return $self if ($self->{errno});

#  $admin->action_add($DATA{UID}, "ADDED", { MODULE => 'voip'});
 
  return $self;
}


#**********************************************************
# Route information
# route_info()
#**********************************************************
sub trunk_info {
  my $self = shift;
  my ($id, $attr) = @_;

  $self->query($db, "SELECT 
   name,
	trunkprefix,
	protocol,
	provider_ip,
	removeprefix,
	addprefix,
	secondusedreal,
	secondusedcarrier,
	secondusedratecard,
	failover_trunk,
	addparameter,
	provider_name
     FROM voip_trunks
   WHERE id='$id';");

  if ($self->{TOTAL} < 1) {
     $self->{errno} = 2;
     $self->{errstr} = 'ERROR_NOT_EXIST';
     return $self;
   }

  ($self->{NAME}, 
  $self->{TRUNKPREFIX},  
  $self->{PROTOCOL}, 
  $self->{PROVIDER_IP}, 
  $self->{REMOVE_PREFIX},
  $self->{ADD_PREFIX},
  $self->{SECONDUSEDREAL},
  $self->{SECONDUSEDCARRIER},
  $self->{SECONDUSEDRATECARD},
  $self->{FAILOVER_TRUNK},
  $self->{ADDPARAMETER},
  $self->{PROVIDER_NAME}
  )= @{ $self->{list}->[0] };
  
  return $self;
}

#**********************************************************
# route_del
#**********************************************************
sub trunk_del {
  my $self = shift;
  my ($id) = @_;
  
  $self->query($db,  "DELETE FROM voip_trunks WHERE id='$id';", 'do');
  return $self if ($self->{errno});

#  $admin->action_add($DATA{UID}, "ADDED", { MODULE => 'voip'});
 
  return $self;
}

#**********************************************************
# route_change()
#**********************************************************
sub trunk_change {
  my $self = shift;
  my ($attr) = @_;

my %FIELDS = (ID             => 'id',
              NAME           => 'name', 
              TRUNKPREFIX    => 'trunkprefix',  
              PROTOCOL       => 'protocol',
              PROVIDER_IP    => 'provider_ip',
              REMOVE_PREFIX  => 'removeprefix',
              ADD_PREFIX     => 'add_prefix',
              SECONDUSEDREAL => 'secondusedreal',
              SECONDUSEDCARRIER   => 'secondusedcarrier',
              SECONDUSEDRATECARD   => 'secondusedratecard',
              FAILOVER_TRUNK    => 'failover_trunk',
              ADDPARAMETER   => 'addparameter',
              PROVIDER_NAME  => 'provider_name'
             );


  $self->changes($admin,  { CHANGE_PARAM => 'ID',
                   TABLE        => 'voip_trunks',
                   FIELDS       => \%FIELDS,
                   OLD_INFO     => $self->trunk_info($attr->{ID}),
                   DATA         => $attr
                  } );

  return $self->{result};
}




#**********************************************************
# route_list()
#**********************************************************
sub trunk_list {
 my $self = shift;
 my ($attr) = @_;
 my @list = ();

 $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
 $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
 $PG = ($attr->{PG}) ? $attr->{PG} : 0;
 $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;


 @WHERE_RULES = ();
 my $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';

 $self->query($db, "SELECT id, name, protocol, provider_name, failover_trunk
      FROM voip_trunks
     $WHERE 
     ORDER BY $SORT $DESC 
     LIMIT $PG, $PAGE_ROWS;");

 return $self if($self->{errno});

 my $list = $self->{list};

 if ($self->{TOTAL} >= 0) {
    $self->query($db, "SELECT count(id) FROM voip_trunks $WHERE");
    ($self->{TOTAL}) = @{ $self->{list}->[0] };
   }

  return $list;
}




#**********************************************************
# Extra tarification
# extra_tarification_info()
#**********************************************************
sub extra_tarification_info {
  my $self = shift;
  my ($attr) = @_;

  
  $self->query($db, "SELECT id,
  name,
  prepaid_time
     FROM voip_route_extra_tarification
  WHERE id='$attr->{ID}';");

  if ($self->{TOTAL} < 1) {
     $self->{errno} = 2;
     $self->{errstr} = 'ERROR_NOT_EXIST';
     return $self;
   }


  ($self->{ID},
   $self->{NAME},
   $self->{PREPAID_TIME}
  )= @{ $self->{list}->[0] };
  
  return $self;
}


#**********************************************************
# extra_tarification_add()
#**********************************************************
sub extra_tarification_add {
  my $self = shift;
  my ($attr) = @_;
  
  %DATA = $self->get_data($attr); 

  $self->query($db,  "INSERT INTO voip_route_extra_tarification (name, date, prepaid_time)
        VALUES ('$DATA{NAME}', now(), '$DATA{PREPAID_TIME}');", 'do');  
  return $self if ($self->{errno}); 


  return $self;
}




#**********************************************************
# extra_tarification_change()
#**********************************************************
sub extra_tarification_change {
  my $self = shift;
  my ($attr) = @_;
  
  my %FIELDS = (ID           => 'id',
                NAME				 => 'name',
                PREPAID_TIME => 'prepaid_time',
               );

  $self->changes($admin,  { CHANGE_PARAM => 'ID',
                   TABLE        => 'voip_route_extra_tarification',
                   FIELDS       => \%FIELDS,
                   OLD_INFO     => $self->extra_tarification_info( $attr ),
                   DATA         => $attr
                  } );

  return $self->{result};
}



#**********************************************************
# 
# extra_tarification_del(attr);
#**********************************************************
sub extra_tarification_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query($db, "DELETE from voip_route_extra_tarification WHERE id='$attr->{ID}';", 'do');

  return $self->{result};
}


#**********************************************************
# extra_tarification_list()
#**********************************************************
sub extra_tarification_list {
 my $self = shift;
 my ($attr) = @_;
 my @list = ();

 $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
 $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
 $PG = ($attr->{PG}) ? $attr->{PG} : 0;
 $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;
 my @WHERE_RULES = ();
 

 
 if ($attr->{NAME}) {
   push @WHERE_RULES, @{ $self->search_expr("'$attr->{NAME}'", 'STR', 'et.name') }; 
  }

 if ($attr->{ID}) {
   push @WHERE_RULES, @{ $self->search_expr("'$attr->{ID}'", 'INT', 'et.id') }; 
  }

 
 $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';
 
 
 $self->query($db, "SELECT id, name, prepaid_time
     FROM voip_route_extra_tarification
     $WHERE 
     ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;");

 return $self if($self->{errno});
 my $list = $self->{list};

 if ($self->{TOTAL} >= 0) {
    $self->query($db, "SELECT count(id) FROM voip_route_extra_tarification $WHERE");
    ($self->{TOTAL}) = @{ $self->{list}->[0] };
   }

  return $list;
}
1

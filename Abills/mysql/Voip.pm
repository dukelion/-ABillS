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
  
  if ($CONF->{DELETE_USER}) {
    $self->{UID}=$CONF->{DELETE_USER};
    $self->user_del({ UID => $CONF->{DELETE_USER} });
   }

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
   voip.logins
     FROM voip_main voip
     LEFT JOIN voip_tps tp ON (voip.tp_id=tp.id)
     LEFT JOIN tarif_plans ON (tarif_plans.id=tp.id)
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
   $self->{REGISTRATION}

  )= @{ $self->{list}->[0] };
  

  
  return $self;
}



#**********************************************************
#
#**********************************************************
sub defaults {
  my $self = shift;

  %DATA = (
   TP_ID => 0, 
   NUMBER => 0, 
   DISABLE => 0, 
   IP => '0.0.0.0', 
   CID => '',
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
             disable, ip, cid)
        VALUES ('$DATA{UID}', '$DATA{NUMBER}', now(),
        '$DATA{TARIF_PLAN}', '$DATA{DISABLE}', INET_ATON('$DATA{IP}'), 
        LOWER('$DATA{CID}'));", 'do');
  
  return $self if ($self->{errno});
  
 
  $admin->action_add($DATA{UID}, "ADDED");


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
              FILTER_ID        => 'filter_id'
             );



  $self->changes($admin,  { CHANGE_PARAM => 'UID',
                   TABLE        => 'voip_main',
                   FIELDS       => \%FIELDS,
                   OLD_INFO     => $self->user_info($attr->{UID}),
                   DATA         => $attr
                  } );


  $admin->action_add($attr->{UID}, "$self->{result}");

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
  $admin->action_add($self->{UID}, "DELETE $self->{UID}");

  return $self->{result};
}




#**********************************************************
# list()
#**********************************************************
sub user_list {
 my $self = shift;
 my ($attr) = @_;
 my @list = ();

 
 my $search_fields = '';
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
        and (b.deposit+u.credit-tp.credit_tresshold<=0
        and tp.hourp+tp.df+tp.abon>=0)
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
      push @WHERE_RULES, "(u.ip>=INET_ATON('$first_ip') and u.ip<=INET_ATON('$last_ip'))";
     }
    else {
      my $value = $self->search_expr($attr->{IP}, 'IP');
      push @WHERE_RULES, "u.ip$value";
    }
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
    push @WHERE_RULES, "voip_main.cid LIKE '$attr->{CID}'";
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
 if ($attr->{GID}) {
    push @WHERE_RULES, "u.gid='$attr->{GID}'";
  }

#Activate
 if ($attr->{ACTIVATE}) {
   my $value = $self->search_expr("'$attr->{ACTIVATE}'", 'INT');
   push @WHERE_RULES, "(u.activate='0000-00-00' or u.activate$value)"; 
 }

#Expire
 if ($attr->{EXPIRE}) {
   my $value = $self->search_expr("'$attr->{EXPIRE}'", 'INT');
   push @WHERE_RULES, "(u.expire='0000-00-00' or u.expire$value)"; 
 }

#DIsable
 if ($attr->{DISABLE}) {
   push @WHERE_RULES, "u.disable='$attr->{DISABLE}'"; 
 }


 if ($attr->{NUMBER}) {
   my $value = $self->search_expr("'$attr->{NUMBER}'", 'INT');
   push @WHERE_RULES, "service.number$value"; 
 }

 
 $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';
 
 
 $self->query($db, "SELECT u.id, 
      pi.fio, if(company.id IS NULL, b.deposit, b.deposit), u.credit, tp.name, 
      u.disable, 
      service.number,
      u.uid, u.company_id, pi.email, service.tp_id, u.activate, u.expire, u.bill_id
     FROM (users u, voip_main service)
     LEFT JOIN users_pi pi ON (u.uid = pi.uid)
     LEFT JOIN bills b ON u.bill_id = b.id
     LEFT JOIN tarif_plans tp ON (tp.id=service.tp_id) 
     LEFT JOIN companies company ON  (u.company_id=company.id) 
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

  $self->query($db,  "INSERT INTO voip_routes (prefix, parent, name, disable, date,
        gateway_id,
        descr) 
        VALUES ('$DATA{ROUTE_PREFIX}', '$DATA{PARENT_ID}',  '$DATA{ROUTE_NAME}', '$DATA{DISABLE}', now(),
        '$DATA{GATEWAY_ID}',
        '$DATA{DESCRIBE}');", 'do');


  return $self if ($self->{errno});

#  $admin->action_add($DATA{UID}, "ADDED", { MODULE => 'voip'});
 
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
   descr,
   gateway_id
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
   $self->{DESCRIBE},
   $self->{GATEWAY_ID}
  )= @{ $self->{list}->[0] };
  
  
  
  
  return $self;
}

#**********************************************************
# route_del
#**********************************************************
sub route_del {
  my $self = shift;
  my ($id) = @_;
  
  $self->query($db,  "DELETE FROM voip_routes WHERE id='$id';", 'do');
  return $self if ($self->{errno});

#  $admin->action_add($DATA{UID}, "ADDED", { MODULE => 'voip'});
 
  return $self;
}

#**********************************************************
# route_change()
#**********************************************************
sub route_change {
  my $self = shift;
  my ($attr) = @_;
  
  my %FIELDS = (ROUTE_ID        => 'id',
   							PARENT_ID       => 'parent',
                DISABLE        => 'disable',
                ROUTE_PREFIX   => 'prefix',
                ROUTE_NAME     => 'name',
                DESCRIBE       => 'descr',
                GATEWAY_ID     => 'gateway_id'
                
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

 $self->query($db, "SELECT r.prefix, r.name, r.disable, r.date, r.gateway_id, r.id, r.parent
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
		 	    my($trash, $route, $interval)=split(/_/, $k, 3);
		 	    $value .= "('$route', '$interval', '$v', now()),";
		     }

		  }

  chop($value);
  
 $self->query($db, "REPLACE INTO voip_route_prices (route_id, interval_id, price, date) VALUES
  $value;", 'do');

 return $self if($self->{errno});



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

 $self->query($db, "SELECT rp.interval_id, rp.route_id, rp.date, rp.price
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

 my $WHERE = 'WHERE tp.id=voip.id';

 $self->query($db, "SELECT tp.id, tp.name, if(sum(i.tarif) is NULL or sum(i.tarif)=0, 0, 1), 
    tp.payment_type,
    tp.day_fee, tp.month_fee, 
    tp.logins, 
    tp.age
    FROM (tarif_plans tp, voip_tps voip)
    LEFT JOIN intervals i ON (i.tp_id=tp.id)
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


  $tariffs->add({ %$attr });

  if (defined($tariffs->{errno})) {
  	$self->{errno} = $tariffs->{errno};
  	return $self;
  }
  my $DATA = tp_defaults();


#  while(my($k, $v)=each %$DATA) {
#  	print "$k, $v<br>\n";
#  }
  
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
     free_time
     )
    values ('$DATA{TP_ID}', 
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
  '$DATA{FREE_TIME}');", 'do');

  return $self;
}


#**********************************************************
# change
#**********************************************************
sub tp_change {
  my $self = shift;
  my ($tp_id, $attr) = @_;


  $tariffs->change($tp_id, { %$attr });
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
            FREE_TIME            => 'free_time'
         );   

  if ($tp_id != $attr->{CHG_TP_ID}) {
  	 $FIELDS{CHG_TP_ID}='id';
  	 

   }

	$self->changes($admin, { CHANGE_PARAM => 'TP_ID',
		                TABLE        => 'voip_tps',
		                FIELDS       => \%FIELDS,
		                OLD_INFO     => $self->tp_info($tp_id, $attr),
		                DATA         => $attr
		              } );


  if ($tp_id != $attr->{CHG_TP_ID}) {
  	 $attr->{TP_ID} = $attr->{CHG_TP_ID};
   }

  
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
  
  
  if ($attr->{CHG_TP_ID}) {
    $self = $tariffs->info($attr->{CHG_TP_ID});
   }
  else {
    $self = $tariffs->info($id);
   }

  if (defined($self->{errno})) {
  	return $self;
  }


  $self->query($db, "SELECT id, 
      day_time_limit, week_time_limit,  month_time_limit, 
      max_session_duration,
      min_session_cost,
      rad_pairs,
     first_period,
     first_period_step,
     next_period,
     next_period_step,
     free_time

    FROM voip_tps
    WHERE id='$id';");

  if ($self->{TOTAL} < 1) {
     $self->{errno} = 2;
     $self->{errstr} = 'ERROR_NOT_EXIST';
     return $self;
   }

 
  ($self->{TP_ID}, 
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
   $self->{FREE_TIME}

  ) = @{ $self->{list}->[0] };


  return $self;
}





1

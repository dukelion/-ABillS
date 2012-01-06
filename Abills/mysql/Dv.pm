package Dv;
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
my $MODULE='Dv';

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
  my ($uid, $attr) = @_;

  if(defined($attr->{LOGIN})) {
    use Users;
    my $users = Users->new($db, $admin, $CONF);   
    $users->info(0, {LOGIN => "$attr->{LOGIN}"});
    if ($users->{errno}) {
       $self->{errno} = 2;
       $self->{errstr} = 'ERROR_NOT_EXIST';
       return $self; 
     }

    $uid              = $users->{UID};
    $self->{DEPOSIT}  = $users->{DEPOSIT};
    $self->{ACCOUNT_ACTIVATE} = $users->{ACTIVATE};
    $WHERE =  "WHERE dv.uid='$uid'";
   }
  
  
  $WHERE =  "WHERE dv.uid='$uid'";
  
  if (defined($attr->{IP})) {
  	$WHERE = "WHERE dv.ip=INET_ATON('$attr->{IP}')";
   }

  $admin->{DOMAIN_ID}=0 if (! defined($admin->{DOMAIN_ID}));
  
  $self->query($db, "SELECT dv.uid, dv.tp_id, 
   tp.name, 
   dv.logins, 
   INET_NTOA(dv.ip), 
   INET_NTOA(dv.netmask), 
   dv.speed, 
   dv.filter_id, 
   dv.cid,
   dv.disable,
   dv.callback,
   dv.port,
   tp.gid,
   tp.month_fee,
   tp.day_fee,
   tp.postpaid_monthly_fee,
   tp.payment_type,
   dv.join_service,
   dv.turbo_mode,
   tp.abon_distribution,
   tp.credit,
   tp.tp_id,
   tp.priority,
   tp.activate_price,
   tp.age,
   tp.filter_id
     FROM dv_main dv
     LEFT JOIN tarif_plans tp ON (dv.tp_id=tp.id and tp.domain_id='$admin->{DOMAIN_ID}')
   $WHERE;");

  if ($self->{TOTAL} < 1) {     
  	 $self->{errno} = 2;
     $self->{errstr} = 'ERROR_NOT_EXIST';
     return $self;
   }


  ($self->{UID},
   $self->{TP_ID}, 
   $self->{TP_NAME}, 
   $self->{SIMULTANEONSLY}, 
   $self->{IP}, 
   $self->{NETMASK}, 
   $self->{SPEED}, 
   $self->{FILTER_ID}, 
   $self->{CID},
   $self->{STATUS},
   $self->{CALLBACK},
   $self->{PORT},
   $self->{TP_GID},
   $self->{MONTH_ABON},
   $self->{DAY_ABON},
   $self->{POSTPAID_ABON}, 
   $self->{PAYMENT_TYPE},
   $self->{JOIN_SERVICE},
   $self->{TURBO_MODE},
   $self->{ABON_DISTRIBUTION},
   $self->{TP_CREDIT},
   $self->{TP_NUM},
   $self->{TP_PRIORITY},
   $self->{TP_ACTIVATION_PRICE},
   $self->{TP_AGE},
   $self->{TP_FILTER_ID}
  )= @{ $self->{list}->[0] };
  

  return $self;
}



#**********************************************************
#
#**************************************
sub defaults {
  my $self = shift;

  my %DATA = (
   TP_ID     => 0, 
   SIMULTANEONSLY => 0, 
   STATUS         => 0, 
   IP             => '0.0.0.0', 
   NETMASK        => '255.255.255.255', 
   SPEED          => 0, 
   FILTER_ID      => '', 
   CID            => '',
   CALLBACK       => 0,
   PORT           => 0,
   JOIN_SERVICE   => 0,
   TURBO_MODE     => 0
  );

  $self = \%DATA ;
  return $self;
}


#**********************************************************
# add()
#**********************************************************
sub add {
  my $self = shift;
  my ($attr) = @_;
  
  my %DATA = $self->get_data($attr, { default => defaults() }); 

  if ($DATA{TP_ID} > 0 && ! $DATA{STATUS}) {
     my $tariffs = Tariffs->new($db, $CONF, $admin);

     $self->{TP_INFO}=$tariffs->info(0, { ID => $DATA{TP_ID} });
     

     #Take activation price
     if($tariffs->{ACTIV_PRICE} > 0) {
       my $user = Users->new($db, $admin, $CONF);
       $user->info($DATA{UID});
       
       if($CONF->{FEES_PRIORITY}=~/bonus/  && $user->{EXT_BILL_DEPOSIT}) {
         $user->{DEPOSIT}+=$user->{EXT_BILL_DEPOSIT};
        }

       
       if ($user->{DEPOSIT} + $user->{CREDIT} < $tariffs->{ACTIV_PRICE} && $tariffs->{PAYMENT_TYPE} == 0) {
         $self->{errno}=15;
       	 return $self; 
        }

       my $fees = Fees->new($db, $admin, $CONF);
       $fees->take($user, $tariffs->{ACTIV_PRICE}, { DESCRIBE  => "ACTIV TP" });  

       $tariffs->{ACTIV_PRICE}=0;
      }
   }

  $self->query($db,  "INSERT INTO dv_main (uid, registration, 
             tp_id, 
             logins, 
             disable, 
             ip, 
             netmask, 
             speed, 
             filter_id, 
             cid,
             callback,
             port,
             join_service,
             turbo_mode)
        VALUES ('$DATA{UID}', now(),
        '$DATA{TP_ID}', '$DATA{SIMULTANEONSLY}', '$DATA{STATUS}', INET_ATON('$DATA{IP}'), 
        INET_ATON('$DATA{NETMASK}'), '$DATA{SPEED}', '$DATA{FILTER_ID}', LOWER('$DATA{CID}'),
        '$DATA{CALLBACK}',
        '$DATA{PORT}', '$DATA{JOIN_SERVICE}', '$DATA{TURBO_MODE}');", 'do');

  return $self if ($self->{errno});

  $admin->{MODULE}=$MODULE;
  $admin->action_add("$DATA{UID}", "ACTIVE", { TYPE => 1 });
  return $self;
}




#**********************************************************
# change()
#**********************************************************
sub change {
  my $self = shift;
  my ($attr) = @_;
  
  my %FIELDS = (SIMULTANEONSLY => 'logins',
              STATUS           => 'disable',
              IP               => 'ip',
              NETMASK          => 'netmask',
              TP_ID            => 'tp_id',
              SPEED            => 'speed',
              CID              => 'cid',
              UID              => 'uid',
              FILTER_ID        => 'filter_id',
              CALLBACK         => 'callback',
              PORT             => 'port',
              JOIN_SERVICE     => 'join_service',
              TURBO_MODE       => 'turbo_mode'
             );
  
  if (! $attr->{CALLBACK}) {
  	$attr->{CALLBACK}=0;
   }

  my $old_info = $self->info($attr->{UID});
  $self->{OLD_STATUS}=$old_info->{STATUS};


  if ($attr->{TP_ID} && $old_info->{TP_ID} != $attr->{TP_ID}) {
     my $tariffs = Tariffs->new($db, $CONF, $admin);

     $tariffs->info(0, { ID => $old_info->{TP_ID} }); 
 
     $self->{TP_INFO_OLD}->{PRIORITY}=$tariffs->{PRIORITY};
     $self->{TP_INFO}    = $tariffs->info(0, { ID => $attr->{TP_ID} });
     
     my $user = Users->new($db, $admin, $CONF);

     $user->info($attr->{UID});
     if($CONF->{FEES_PRIORITY} && $CONF->{FEES_PRIORITY}=~/bonus/  && $user->{EXT_BILL_DEPOSIT}) {
       $user->{DEPOSIT}+=$user->{EXT_BILL_DEPOSIT};
      }

     #Active TP     
     if ($old_info->{STATUS} == 2 && (defined($attr->{STATUS}) && $attr->{STATUS} == 0) && $tariffs->{ACTIV_PRICE} > 0) {
       if ($user->{DEPOSIT} + $user->{CREDIT} < $tariffs->{ACTIV_PRICE} && $tariffs->{PAYMENT_TYPE} == 0 && $tariffs->{POSTPAID_FEE} == 0) {
         $self->{errno}=15;
       	 return $self; 
        }

       my $fees = Fees->new($db, $admin, $CONF);
       $fees->take($user, $tariffs->{ACTIV_PRICE}, { DESCRIBE  => "ACTIV TP" });  

       $tariffs->{ACTIV_PRICE}=0;
      }
     # Change TP
     elsif($tariffs->{CHANGE_PRICE} > 0 && 
       ($self->{TP_INFO_OLD}->{PRIORITY} - $tariffs->{PRIORITY} > 0 || $self->{TP_INFO_OLD}->{PRIORITY} + $tariffs->{PRIORITY} == 0) && ! $attr->{NO_CHANGE_FEES} ) {

       if ($user->{DEPOSIT} + $user->{CREDIT} < $tariffs->{CHANGE_PRICE}) {
         $self->{errno}=15;
       	 return $self; 
        }

       my $fees = Fees->new($db, $admin, $CONF);
       $fees->take($user, $tariffs->{CHANGE_PRICE}, { DESCRIBE  => "CHANGE TP" });  
      }

     if ($tariffs->{AGE} > 0) {
       my $user = Users->new($db, $admin, $CONF);

       use POSIX qw(strftime);
       my $EXPITE_DATE = strftime( "%Y-%m-%d", localtime(time + 86400 * $tariffs->{AGE}) );
       $user->change($attr->{UID}, { EXPIRE => $EXPITE_DATE, UID => $attr->{UID} });
     }
    else {
       my $user = Users->new($db, $admin, $CONF);
       $user->change($attr->{UID}, { EXPIRE => "0000-00-00", UID => $attr->{UID} });
     }
   }
  elsif (($old_info->{STATUS} == 2 && $attr->{STATUS} == 0) || 
         ($old_info->{STATUS} == 4 && $attr->{STATUS} == 0) || 
         ($old_info->{STATUS} == 5 && $attr->{STATUS} == 0)         
          ) {
    my $tariffs = Tariffs->new($db, $CONF, $admin);
    $self->{TP_INFO}=$tariffs->info(0, { ID => $old_info->{TP_ID} });
   }
  elsif ($old_info->{STATUS} == 3 && $attr->{STATUS} == 0 && $attr->{STATUS_DAYS}) {
     my $user = Users->new($db, $admin, $CONF);
     $user->info($attr->{UID});

     my $fees = Fees->new($db, $admin, $CONF);
     my ($perios, $sum)=split(/:/, $CONF->{DV_REACTIVE_PERIOD}, 2);
     $fees->take($user, $sum, { DESCRIBE  => "REACTIVE" });
   }

  $attr->{JOIN_SERVICE} = ($attr->{JOIN_SERVICE}) ? $attr->{JOIN_SERVICE} : 0;

  $admin->{MODULE}=$MODULE;
  $self->changes($admin, { CHANGE_PARAM => 'UID',
                   TABLE        => 'dv_main',
                   FIELDS       => \%FIELDS,
                   OLD_INFO     => $old_info,
                   DATA         => $attr
                  } );


  $self->{TP_INFO}->{ACTIV_PRICE}=0;

  $self->info($attr->{UID});

  return $self;
}



#**********************************************************
# Delete user info from all tables
#
# del(attr);
#**********************************************************
sub del {
  my $self = shift;
  my ($attr) = @_;

  $self->query($db, "DELETE from dv_main WHERE uid='$self->{UID}';", 'do');
  $self->query($db, "DELETE from dv_log WHERE uid='$self->{UID}';", 'do');


  $admin->action_add($self->{UID}, "$self->{UID}", { TYPE => 10 });
  return $self->{result};
}




#**********************************************************
# list()
#**********************************************************
sub list {
 my $self = shift;
 my ($attr) = @_;
 my @list = ();

 $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
 $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
 $PG = ($attr->{PG}) ? $attr->{PG} : 0;
 $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

 my $GROUP_BY = 'u.uid';

 if ($attr->{GROUP_BY}) {
 	 $GROUP_BY = $attr->{GROUP_BY};
  }

 $self->{SEARCH_FIELDS} = '';
 $self->{SEARCH_FIELDS_COUNT}=0;

 @WHERE_RULES = ("u.uid = dv.uid");
 
 if ($attr->{USERS_WARNINGS}) {
   $self->query($db, "SELECT u.id, pi.email, dv.tp_id, u.credit, b.deposit, tp.name, tp.uplimit, pi.phone,
      pi.fio
         FROM (users u,
               dv_main dv,
               bills b,
               tarif_plans tp)
         LEFT JOIN users_pi pi ON u.uid = pi.uid
         WHERE
               u.uid=dv.uid
           and u.disable = 0
           and u.bill_id=b.id
           and dv.tp_id = tp.id
           and dv.disable = 0
           and b.deposit<tp.uplimit AND tp.uplimit > 0 AND b.deposit+u.credit>0
         GROUP BY u.uid
         ORDER BY u.id;");


   return $self if ($self->{errno});
   
   my $list = $self->{list};
   return $list;
  }
 elsif($attr->{CLOSED}) {
   $self->query($db, "SELECT u.id, pi.fio, if(company.id IS NULL, b.deposit, b.deposit), 
      u.credit, tp.name, u.disable, 
      u.uid, u.company_id, u.email, u.tp_id, if(l.start is NULL, '-', l.start)
     FROM ( users u, bills b )
     LEFT JOIN users_pi pi ON u.uid = dv.uid
     LEFT JOIN tarif_plans tp ON  (tp.id=u.tp_id) 
     LEFT JOIN companies company ON  (u.company_id=company.id) 
     LEFT JOIN dv_log l ON  (l.uid=u.uid) 
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
      push @WHERE_RULES, "(dv.ip>=INET_ATON('$first_ip') and dv.ip<=INET_ATON('$last_ip'))";
     }
    else {
      push @WHERE_RULES, @{ $self->search_expr($attr->{IP}, 'IP', 'dv.ip') };
    }

    $self->{SEARCH_FIELDS} = 'INET_NTOA(dv.ip), ';
    $self->{SEARCH_FIELDS_COUNT}++;
  }


   if (! $admin->{permissions}->{0} || ! $admin->{permissions}->{0}->{8} || 
     ($attr->{USER_STATUS} && ! $attr->{DELETED})) {
	   push @WHERE_RULES,  @{ $self->search_expr(0, 'INT', 'u.deleted', { EXT_FIELD => 1 })  };
    }
   elsif (defined($attr->{DELETED})) {
  	 push @WHERE_RULES,  @{ $self->search_expr("$attr->{DELETED}", 'INT', 'u.deleted', { EXT_FIELD => 1 })  };
    }


 if ($attr->{NETMASK}) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{NETMASK}, 'IP', 'INET_NTOA(dv.netmask)', { EXT_FIELD => 1 }) };
  }

 if ($attr->{DEPOSIT}) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{DEPOSIT}, 'INT', 'b.deposit') }; 
  }

 if ($attr->{JOIN_SERVICE}) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{JOIN_SERVICE}, 'INT', 'dv.join_service', { EXT_FIELD => 1 }) } ;
  }

 if ($attr->{SIMULTANEONSLY}) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{SIMULTANEONSLY}, 'INT', 'dv.logins', { EXT_FIELD => 1 }) } ;
  }

 if ($attr->{SPEED}) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{SPEED}, 'INT', 'dv.speed', { EXT_FIELD => 1 }) };
  }

 if ($attr->{PORT}) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{PORT}, 'INT', 'dv.port', { EXT_FIELD => 1 }) };
  }

 if ($attr->{CID}) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{CID}, 'STR', 'dv.cid', { EXT_FIELD => 1 }) };
  }

 if ($attr->{ALL_FILTER_ID}) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{ALL_FILTER_ID}, 'STR', 'if(dv.filter_id<>\'\', dv.filter_id, tp.filter_id)', { EXT_FIELD => 1 }) };
  }
 elsif ($attr->{FILTER_ID}) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{FILTER_ID}, 'STR', 'dv.filter_id', { EXT_FIELD => 1 }) };
  }

 if ($attr->{COMMENTS}) {
   $attr->{COMMENTS} =~ s/\*/\%/ig;
   push @WHERE_RULES, "u.comments LIKE '$attr->{COMMENTS}'";
  }

 if ($attr->{FIO}) {
   $attr->{FIO} =~ s/\*/\%/ig;
   push @WHERE_RULES, "u.fio LIKE '$attr->{FIO}'";
  }

 # Show users for spec tarifplan 
 if (defined($attr->{TP_ID})) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{TP_ID}, 'INT', 'dv.tp_id') };
   $self->{SEARCH_FIELDS} .= 'tp.name, ';
   $self->{SEARCH_FIELDS_COUNT}++;
  }

 if (defined($attr->{TP_CREDIT})) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{TP_CREDIT}, 'INT', 'tp.credit', { EXT_FIELD => 1 }) };
  }

 if (defined($attr->{PAYMENT_TYPE})) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{PAYMENT_TYPE}, 'INT', 'tp.payment_type', { EXT_FIELD => 1 }) };
  }

 # Show debeters
 if ($attr->{DEBETERS}) {
   push @WHERE_RULES, "u.id LIKE '$attr->{FIRST_LETTER}%'";
  }

 if (defined($attr->{COMPANY_ID}) && $attr->{COMPANY_ID} ne '') {
   push @WHERE_RULES, @{ $self->search_expr($attr->{COMPANY_ID}, 'INT', 'u.company_id') };
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
   push @WHERE_RULES, "(u.activate='0000-00-00' or u.activate$attr->{ACTIVATE})"; 
 }

#Expire
 if ($attr->{EXPIRE}) {
   my $value = $self->search_expr("$attr->{EXPIRE}", 'INT');
   push @WHERE_RULES, "(u.expire='0000-00-00' or u.expire$attr->{EXPIRE})"; 
 }

#DIsable
 if (defined($attr->{STATUS}) && $attr->{STATUS} ne '') {
   push @WHERE_RULES,  @{ $self->search_expr($attr->{STATUS}, 'INT', 'dv.disable') };
  }
 
 if (defined($attr->{LOGIN_STATUS})) {
   push @WHERE_RULES, "u.disable='$attr->{LOGIN_STATUS}'"; 
  }

 my $EXT_TABLE = '';
 if ($attr->{EXT_BILL}) {
   $self->{SEARCH_FIELDS} .= 'if(u.company_id > 0, ext_cb.deposit, ext_b.deposit), ';
   $self->{SEARCH_FIELDS_COUNT}++;
 	 $EXT_TABLE .= "
     LEFT JOIN bills ext_b ON (u.ext_bill_id = ext_b.id)
     LEFT JOIN bills ext_cb ON  (company.ext_bill_id=ext_cb.id) ";
  }

 $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';
 
 $self->query($db, "SELECT u.id, 
      pi.fio, if(u.company_id > 0, cb.deposit, b.deposit), 
      u.credit, 
      tp.name, 
      dv.disable, 
      $self->{SEARCH_FIELDS}
      u.uid, 
      u.company_id, 
      pi.email, 
      dv.tp_id, 
      u.activate, 
      u.expire, 
      if(u.company_id > 0, company.bill_id, u.bill_id) AS bill_id,
      u.reduction,
      if(u.company_id > 0, company.ext_bill_id, u.ext_bill_id) AS ext_bill_id
     FROM (users u, dv_main dv)
     LEFT JOIN users_pi pi ON (u.uid = pi.uid)
     LEFT JOIN bills b ON (u.bill_id = b.id)
     LEFT JOIN tarif_plans tp ON (tp.id=dv.tp_id) 
     LEFT JOIN companies company ON  (u.company_id=company.id) 
     LEFT JOIN bills cb ON  (company.bill_id=cb.id)
     $EXT_TABLE
     $WHERE 
     GROUP BY $GROUP_BY
     ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;");

 return $self if($self->{errno});

 my $list = $self->{list};

 if ($self->{TOTAL} >= 0 && ! $attr->{SKIP_TOTAL}) {
    $self->query($db, "SELECT count(u.id) FROM (users u, dv_main dv) 
    LEFT JOIN tarif_plans tp ON (tp.id=dv.tp_id) 
    $WHERE");
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
# get tp speed
#**********************************************************
sub get_speed {
  my $self = shift;
  my ($attr) = @_;

  my $EXT_TABLE = '';

  $self->{SEARCH_FIELDS}      ='';
  $self->{SEARCH_FIELDS_COUNT}=0;

  if ($attr->{LOGIN}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{LOGIN}, 'STR', 'u.id') };
    $EXT_TABLE .= "LEFT JOIN dv_main dv ON (dv.tp_id = tp.id )
    LEFT JOIN users u ON (dv.uid = u.uid )";
    
    $self->{SEARCH_FIELDS}      = ', dv.speed, u.activate, dv.netmask, dv.join_service, dv.uid';
    $self->{SEARCH_FIELDS_COUNT}+=3;
   }
  elsif ($attr->{UID}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{UID}, 'STR', 'u.uid') };
    $EXT_TABLE .= "LEFT JOIN dv_main dv ON (dv.tp_id = tp.id )
    LEFT JOIN users u ON (dv.uid = u.uid )";
    
    $self->{SEARCH_FIELDS}      = ', dv.speed, u.activate, dv.netmask, dv.join_service, dv.uid';
    $self->{SEARCH_FIELDS_COUNT}+=3;
   }


  if ($attr->{TP_ID}) {
    push @WHERE_RULES, "tp.id='$attr->{TP_ID}'"; 
   }

 $WHERE = ($#WHERE_RULES > -1) ? "AND " . join(' and ', @WHERE_RULES)  : '';
 
 $self->query($db, "SELECT tp.tp_id, tp.id, tt.id, tt.in_speed, tt.out_speed, tt.net_id, tt.expression 
  $self->{SEARCH_FIELDS} 
FROM trafic_tarifs tt
LEFT JOIN intervals intv ON (tt.interval_id = intv.id)
LEFT JOIN tarif_plans tp ON (tp.tp_id = intv.tp_id)
$EXT_TABLE
WHERE intv.begin <= DATE_FORMAT( NOW(), '%H:%i:%S' ) 
 AND intv.end >= DATE_FORMAT( NOW(), '%H:%i:%S' )
 AND tp.module='Dv'
 $WHERE
AND intv.day IN (select if ( intv.day=8, 
		(SELECT if ((select    count(*) from    holidays where     DATE_FORMAT( NOW(), '%c-%e' ) = day)>0, 8,
                (select if (intv.day=0, 0, (select intv.day from intervals as intv where DATE_FORMAT( NOW() + INTERVAL 1 DAY, '%w') = intv.day LIMIT 1))))),
        (select if (intv.day=0, 0,
                (select intv.day from intervals as intv where DATE_FORMAT( NOW() + INTERVAL 1 DAY, '%w') = intv.day LIMIT 1)))))
GROUP BY tp.tp_id, tt.id
ORDER by tp.tp_id, tt.id;");
  
  return $self->{list};
}


1
 

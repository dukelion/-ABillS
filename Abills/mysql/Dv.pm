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

my %SEARCH_PARAMS = (TP_ID => 0, 
   SIMULTANEONSLY => 0, 
   STATUS        => 0, 
   IP             => '0.0.0.0', 
   NETMASK        => '255.255.255.255', 
   SPEED          => 0, 
   FILTER_ID      => '', 
   CID            => '', 
   REGISTRATION   => ''
);

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
    $self->del({ UID => $CONF->{DELETE_USER} });
   }
  
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
   tp.postpaid_monthly_fee,
   tp.payment_type,
   dv.join_service,
   dv.turbo_mode,
   tp.abon_distribution,
   tp.credit
     FROM dv_main dv
     LEFT JOIN tarif_plans tp ON (dv.tp_id=tp.id)
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
   $self->{POSTPAID_ABON}, 
   $self->{PAYMENT_TYPE},
   $self->{JOIN_SERVICE},
   $self->{TURBO_MODE},
   $self->{ABON_DISTRIBUTION},
   $self->{TP_CREDIT}
  )= @{ $self->{list}->[0] };
  
  
  return $self;
}



#**********************************************************
#
#**********************************************************
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
   JOIN_SERVICE   => 0
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

     $self->{TP_INFO}=$tariffs->info($DATA{TP_ID});
     

     #Take activation price
     if($tariffs->{ACTIV_PRICE} > 0) {
       my $user = Users->new($db, $admin, $CONF);
       $user->info($DATA{UID});
       
       if ($user->{DEPOSIT} + $user->{CREDIT} < $tariffs->{ACTIV_PRICE} && $tariffs->{PAYMENT_TYPE} == 0) {
         
         #print "$user->{DEPOSIT} + $user->{CREDIT} < $tariffs->{ACTIV_PRICE}";
         
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
  $admin->action_add("$DATA{UID}", "ACTIVE");
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
              JOIN_SERVICE     => 'join_service'
             );
  
  if (! $attr->{CALLBACK}) {
  	$attr->{CALLBACK}=0;
   }

  
  my $old_info = $self->info($attr->{UID});
  
  
  if ($attr->{TP_ID} && $old_info->{TP_ID} != $attr->{TP_ID}) {
     my $tariffs = Tariffs->new($db, $CONF, $admin);

     $self->{TP_INFO}=$tariffs->info($attr->{TP_ID});
     
     my $user = Users->new($db, $admin, $CONF);

     $user->info($attr->{UID});
     
     if ($old_info->{STATUS} == 2 && (defined($attr->{STATUS}) && $attr->{STATUS} == 0) && $tariffs->{ACTIV_PRICE} > 0) {
       
       
       if ($user->{DEPOSIT} + $user->{CREDIT} < $tariffs->{ACTIV_PRICE} && $tariffs->{PAYMENT_TYPE} == 0 && $tariffs->{POSTPAID_FEE} == 0) {
        
         $self->{errno}=15;
       	 return $self; 
        }

       my $fees = Fees->new($db, $admin, $CONF);
       $fees->take($user, $tariffs->{ACTIV_PRICE}, { DESCRIBE  => "ACTIV TP" });  

       $tariffs->{ACTIV_PRICE}=0;
      }
     elsif($tariffs->{CHANGE_PRICE} > 0) {
      
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
       #"curdate() + $tariffs->{AGE} days";
       $user->change($attr->{UID}, { EXPIRE => $EXPITE_DATE, UID => $attr->{UID} });
     }
   }
  elsif ($old_info->{STATUS} == 2 && $attr->{STATUS} == 0) {
    my $tariffs = Tariffs->new($db, $CONF, $admin);
    $self->{TP_INFO}=$tariffs->info($old_info->{TP_ID});
   }

  $attr->{JOIN_SERVICE} = ($attr->{JOIN_SERVICE}) ? $attr->{JOIN_SERVICE} : 0;

  $admin->{MODULE}=$MODULE;
  $self->changes($admin, { CHANGE_PARAM => 'UID',
                   TABLE        => 'dv_main',
                   FIELDS       => \%FIELDS,
                   OLD_INFO     => $old_info,
                   DATA         => $attr
                  } );


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

  $admin->action_add($self->{UID}, "DELETE");
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


 $self->{SEARCH_FIELDS} = '';
 $self->{SEARCH_FIELDS_COUNT}=0;

 @WHERE_RULES = ("u.uid = dv.uid");
 
 if ($attr->{USERS_WARNINGS}) {
   $self->query($db, "SELECT u.id, pi.email, dv.tp_id, u.credit, b.deposit, tp.name, tp.uplimit
         FROM (users u,
               dv_main dv,
               bills b,
               tarif_plans tp)
         LEFT JOIN users_pi pi ON u.uid = pi.uid
         WHERE
               u.uid=dv.uid
           and u.bill_id=b.id
           and dv.tp_id = tp.id
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
   push @WHERE_RULES, @{ $self->search_expr($attr->{LOGIN}, 'STR', 'u.id') };
  }
 # Login expresion
 elsif ($attr->{LOGIN_EXPR}) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{LOGIN_EXPR}, 'STR', 'u.id') };
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


  if ($attr->{NETMASK}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{NETMASK}, 'INT', 'dv.netmask') };
   }

 if ($attr->{DEPOSIT}) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{DEPOSIT}, 'INT', 'u.deposit') };
  }

 if ($attr->{JOIN_SERVICE}) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{JOIN_SERVICE}, 'INT', 'dv.join_service') } ;
   $self->{SEARCH_FIELDS} .= 'dv.join_service, ';
   $self->{SEARCH_FIELDS_COUNT}++;
  }

 if ($attr->{SIMULTANEONSLY}) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{SIMULTANEONSLY}, 'INT', 'dv.logins') } ;
   $self->{SEARCH_FIELDS} .= 'dv.logins, ';
   $self->{SEARCH_FIELDS_COUNT}++;
  }


 if ($attr->{SPEED}) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{SPEED}, 'INT', 'dv.speed') };
   $self->{SEARCH_FIELDS} .= 'dv.speed, ';
   $self->{SEARCH_FIELDS_COUNT}++;
  }

 if ($attr->{PORT}) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{PORT}, 'INT', 'dv.port') };
   $self->{SEARCH_FIELDS} .= 'dv.port, ';
   $self->{SEARCH_FIELDS_COUNT}++;
  }

 if ($attr->{CID}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{CID}, 'STR', 'dv.cid') };
    $self->{SEARCH_FIELDS} .= 'dv.cid, ';
    $self->{SEARCH_FIELDS_COUNT}++;
  }

 if ($attr->{FILTER_ID}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{FILTER_ID}, 'STR', 'dv.filter_id') };
    $self->{SEARCH_FIELDS} .= 'dv.filter_id, ';
    $self->{SEARCH_FIELDS_COUNT}++;
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
   push @WHERE_RULES, @{ $self->search_expr($attr->{TP_CREDIT}, 'INT', 'tp.credit') };
   $self->{SEARCH_FIELDS} .= 'tp.credit, ';
   $self->{SEARCH_FIELDS_COUNT}++;
  }

 if (defined($attr->{PAYMENT_TYPE})) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{PAYMENT_TYPE}, 'INT', 'tp.payment_type') };
   $self->{SEARCH_FIELDS} .= 'tp.payment_type, ';
   $self->{SEARCH_FIELDS_COUNT}++;
  }


 # Show debeters
 if ($attr->{DEBETERS}) {
   push @WHERE_RULES, "u.id LIKE '$attr->{FIRST_LETTER}%'";
  }

 if ($attr->{COMPANY_ID}) {
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
   push @WHERE_RULES, "dv.disable='$attr->{STATUS}'"; 
 }
 
 if (defined($attr->{LOGIN_STATUS})) {
   push @WHERE_RULES, "u.disable='$attr->{LOGIN_STATUS}'"; 
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
     $WHERE 
     GROUP BY u.uid
     ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;");

 return $self if($self->{errno});

 my $list = $self->{list};

 if ($self->{TOTAL} >= 0) {
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




1

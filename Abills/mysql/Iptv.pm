package Iptv;
# Iptv  managment functions
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
my $MODULE='Iptv';

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
    $WHERE =  "WHERE service.uid='$uid'";
   }  
  
  $WHERE =  "WHERE service.uid='$uid'";

  $self->query($db, "SELECT service.uid, 
   service.tp_id, 
   tp.name, 
   tp.tp_id, 
   service.filter_id, 
   service.cid,
   service.disable,
   service.pin,
   service.vod,
   tp.gid,
   tp.month_fee,
   tp.day_fee,
   tp.postpaid_monthly_fee,
   tp.payment_type,
   tp.period_alignment,
   tp.id,
   service.dvcrypt_id
     FROM iptv_main service
     LEFT JOIN tarif_plans tp ON (service.tp_id=tp.tp_id)
   $WHERE;");

  if ($self->{TOTAL} < 1) {
     $self->{errno} = 2;
     $self->{errstr} = 'ERROR_NOT_EXIST';
     return $self;
   }


  ($self->{UID},
   $self->{TP_ID}, 
   $self->{TP_NAME}, 
   $self->{TP_NUM}, 
   $self->{CID}, 
   $self->{FILTER_ID}, 
   $self->{STATUS},
   $self->{PIN},
   $self->{VOD},
   $self->{TP_GID},
   $self->{MONTH_ABON},
   $self->{DAY_ABON},
   $self->{POSTPAID_ABON}, 
   $self->{PAYMENT_TYPE},
   $self->{PERIOD_ALIGNMENT},
   $self->{TP_NUM},
   $self->{DVCRYPT_ID}
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
   PIN            => '',
   DVCRYPT_ID     => ''
  );

  $self = \%DATA ;
  return $self;
}


#**********************************************************
# add()
#**********************************************************
sub user_add {
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
         $self->{errno}=15;
       	 return $self; 
        }

       my $fees = Fees->new($db, $admin, $CONF);
       $fees->take($user, $tariffs->{ACTIV_PRICE}, { DESCRIBE  => "ACTIV TP" });  
       $tariffs->{ACTIV_PRICE}=0;
      }
   }

  $self->query($db,  "INSERT INTO iptv_main (uid, registration, 
             tp_id, 
             disable, 
             filter_id,
             pin,
             vod,
             dvcrypt_id
             )
        VALUES ('$DATA{UID}', now(),
        '$DATA{TP_ID}', '$DATA{STATUS}',
        '$DATA{FILTER_ID}',
        '$DATA{PIN}',
        '$DATA{VOD}',
        '$DATA{DVCRYPT_ID}'
         );", 'do');

  return $self if ($self->{errno});
  $admin->action_add("$DATA{UID}", "", { TYPE => 1 });
  return $self;
}




#**********************************************************
# change()
#**********************************************************
sub user_change {
  my $self = shift;
  my ($attr) = @_;

  my %FIELDS = (SIMULTANEONSLY => 'logins',
              STATUS           => 'disable',
              IP               => 'ip',
              NETMASK          => 'netmask',
              TP_ID            => 'tp_id',
              UID              => 'uid',
              FILTER_ID        => 'filter_id',
              PIN              => 'pin',
              VOD              => 'vod',
              DVCRYPT_ID       => 'dvcrypt_id'
             );
  
  $attr->{VOD} = (! defined($attr->{VOD})) ? 0 : 1;
  my $old_info = $self->user_info($attr->{UID});
  
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
                   TABLE        => 'iptv_main',
                   FIELDS       => \%FIELDS,
                   OLD_INFO     => $old_info,
                   DATA         => $attr
                  } );

  $self->user_info($attr->{UID});
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

  $self->query($db, "DELETE from iptv_main WHERE uid='$self->{UID}';", 'do');

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
 
 if ($attr->{LOGIN}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{LOGIN}, 'STR', 'u.id') };
  }
 
 if ($attr->{DEPOSIT}) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{DEPOSIT}, 'INT', 'u.deposit') };
  }

 if ($attr->{FILTER_ID}) {
    $attr->{FILTER_ID} =~ s/\*/\%/ig;
    push @WHERE_RULES, "service.filter_id LIKE '$attr->{FILTER_ID}'";
    $self->{SEARCH_FIELDS} .= 'service.filter_id, ';
    $self->{SEARCH_FIELDS_COUNT}++;
  }

 if ($attr->{DVCRYPT_ID}) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{DVCRYPT_ID}, 'INT', 'service.dvcrypt_id', { EXT_FIELD => 1 }) };
  }

 if ($attr->{FIO}) {
    $attr->{FIO} =~ s/\*/\%/ig;
    push @WHERE_RULES, @{ $self->search_expr($attr->{FIO}, 'STR', 'u.fio') };
  }


 if ($attr->{COMMENTS}) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{COMMENTS}, 'STR', 'service.comments', { EXT_FIELD => 1 }) };
  }

 # Show users for spec tarifplan 
 if (defined($attr->{TP_ID})) {
 	  push @WHERE_RULES, @{ $self->search_expr($attr->{TP_ID}, 'INT', 'service.tp_id', { EXT_FIELD => 1 }) };
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
   push @WHERE_RULES, "(u.activate='0000-00-00' or u.activate$attr->{ACTIVATE})"; 
 }

#Expire
 if ($attr->{EXPIRE}) {
   my $value = $self->search_expr("$attr->{EXPIRE}", 'INT');
   push @WHERE_RULES, "(u.expire='0000-00-00' or u.expire$attr->{EXPIRE})"; 
 }

#DIsable
 if (defined($attr->{STATUS})) {
   push @WHERE_RULES, "service.disable='$attr->{STATUS}'"; 
 }
 
 if (defined($attr->{LOGIN_STATUS})) {
   push @WHERE_RULES, "u.disable='$attr->{LOGIN_STATUS}'"; 
  }
 
 if ($attr->{MONTH_PRICE}) {
   push @WHERE_RULES, @{ $self->search_expr("$attr->{MONTH_PRICE}", 'INT', 'ti_c.month_price') };
  }


 $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';


my $list;

if ($attr->{SHOW_CHANNELS}) {
  	$self->query($db, "SELECT  u.id, 
        if(u.company_id > 0, cb.deposit, b.deposit), 
        u.credit, 
        tp.name, 
        $self->{SEARCH_FIELDS}
        u.uid, 
        u.company_id, 
        service.tp_id, 
        u.activate, 
        u.expire, 
        if(u.company_id > 0, company.bill_id, u.bill_id),
        u.reduction,
        if(u.company_id > 0, company.ext_bill_id, u.ext_bill_id),
        ti_c.channel_id, 
        c.num,
        c.name,
        ti_c.month_price,
        u.disable,
        service.disable
   from (intervals i, 
     iptv_ti_channels ti_c,
     users u,
     iptv_main service,
     iptv_users_channels uc,
     iptv_channels c)
    
     LEFT JOIN tarif_plans tp ON (tp.tp_id=service.tp_id) 
     LEFT JOIN bills b ON (u.bill_id = b.id)
     LEFT JOIN companies company ON  (u.company_id=company.id) 
     LEFT JOIN bills cb ON  (company.bill_id=cb.id)
$WHERE 
  AND i.id=ti_c.interval_id
  AND uc.channel_id=c.id
  AND u.uid=uc.uid
  AND ti_c.channel_id=uc.channel_id
GROUP BY uc.uid, channel_id
ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;");


 $list = $self->{list};
 
 }
else { 
 $self->query($db, "SELECT u.id, 
      pi.fio, if(u.company_id > 0, cb.deposit, b.deposit), 
      u.credit, 
      tp.name, 
      service.disable, 
      $self->{SEARCH_FIELDS}
      u.uid, 
      u.company_id, 
      pi.email, 
      service.tp_id, 
      u.activate, 
      u.expire, 
      if(u.company_id > 0, company.bill_id, u.bill_id),
      u.reduction,
      if(u.company_id > 0, company.ext_bill_id, u.ext_bill_id)
     FROM (users u, iptv_main service)
     LEFT JOIN users_pi pi ON (u.uid = pi.uid)
     LEFT JOIN bills b ON (u.bill_id = b.id)
     LEFT JOIN tarif_plans tp ON (tp.id=service.tp_id) 
     LEFT JOIN companies company ON  (u.company_id=company.id) 
     LEFT JOIN bills cb ON  (company.bill_id=cb.id)
     $WHERE 
     GROUP BY u.uid
     ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;");

 return $self if($self->{errno});

 $list = $self->{list};

 if ($self->{TOTAL} >= 0) {
    $self->query($db, "SELECT count(u.id) FROM (users u, iptv_main service) $WHERE");
    ($self->{TOTAL}) = @{ $self->{list}->[0] };
   }
}
  return $list;
}


#**********************************************************
# User information
# info()
#**********************************************************
sub user_tp_channels_list {
	my $self = shift;
  my ($attr) = @_;

  @WHERE_RULES = ();
  
  #DIsable
 if (defined($attr->{STATUS})) {
   push @WHERE_RULES, "service.disable='$attr->{STATUS}'"; 
 }
 
 if (defined($attr->{LOGIN_STATUS})) {
   push @WHERE_RULES, "u.disable='$attr->{LOGIN_STATUS}'"; 
  }
  
  my $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';

 my $list = $self->{list};
 return $self if($self->{errno});

 if ($self->{TOTAL} >= 0) {
    $self->query($db, "SELECT count(u.id) FROM (users u, iptv_main service) $WHERE");
    ($self->{TOTAL}) = @{ $self->{list}->[0] };
   }
	
	return $self->{list};
}

#**********************************************************
# User information
# info()
#**********************************************************
sub channel_info {
  my $self = shift;
  my ($attr) = @_;

  $WHERE =  "WHERE id='$attr->{ID}'";

  $self->query($db, "SELECT id,
   name,
   num,
   port,
   comments,
   disable
     FROM iptv_channels
   $WHERE;");

  if ($self->{TOTAL} < 1) {
     $self->{errno} = 2;
     $self->{errstr} = 'ERROR_NOT_EXIST';
     return $self;
   }

  ($self->{ID},
   $self->{NAME}, 
   $self->{NUMBER}, 
   $self->{PORT}, 
   $self->{DESCRIBE},
   $self->{DISABLE}
  )= @{ $self->{list}->[0] };
  
  
  return $self;
}



#**********************************************************
#
#**********************************************************
sub channel_defaults {
  my $self = shift;

  my %DATA = (
   ID            => 0, 
   NAME          => '', 
   NUMBER        => 0, 
   PORT          => 0, 
   DESCRIBE      => '', 
   DISABLE       => 0
  ); 

  $self = \%DATA ;
  return $self;
}


#**********************************************************
# add()
#**********************************************************
sub channel_add {
  my $self = shift;
  my ($attr) = @_;
  
  my %DATA = $self->get_data($attr, { default => channel_defaults() }); 

  $self->query($db,  "INSERT INTO iptv_channels (   name,
   num,
   port,
   comments,
   disable
             )
        VALUES (
   '$DATA{NAME}', 
   '$DATA{NUMBER}', 
   '$DATA{PORT}', 
   '$DATA{DESCRIBE}',
   '$DATA{DISABLE}'
         );", 'do');

  return $self if ($self->{errno});

  #$admin->action_add("$DATA{UID}", "ACTIVE");
  return $self;
}




#**********************************************************
# change()
#**********************************************************
sub channel_change {
  my $self = shift;
  my ($attr) = @_;
  

  
  my %FIELDS = (   ID            => 'id', 
   NAME          => 'name', 
   NUMBER        => 'num', 
   PORT          => 'port', 
   DESCRIBE      => 'comments', 
   DISABLE       => 'disable'

             );
  

  my $old_info = $self->channel_info({ ID => $attr->{ID} });

  $admin->{MODULE}=$MODULE;
  $self->changes($admin, { CHANGE_PARAM => 'ID',
                   TABLE        => 'iptv_channels',
                   FIELDS       => \%FIELDS,
                   OLD_INFO     => $old_info,
                   DATA         => $attr
                  } );

  return $self if ($self->{errno});

  $self->channel_info({ ID => $attr->{ID} });
  

  return $self;
}



#**********************************************************
# Delete user info from all tables
#
# del(attr);
#**********************************************************
sub channel_del {
  my $self = shift;
  my ($id) = @_;

  $self->query($db, "DELETE from iptv_channels WHERE id='$id';", 'do');

  #$admin->action_add($self->{UID}, "DELETE");
  return $self->{result};
}




#**********************************************************
# list()
#**********************************************************
sub channel_list {
 my $self = shift;
 my ($attr) = @_;
 my @list = ();

 $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
 $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
 $PG = ($attr->{PG}) ? $attr->{PG} : 0;
 $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

 undef @WHERE_RULES;


 # Start letter 
 if ($attr->{NAME}) {
    $attr->{LOGIN_EXPR} =~ s/\*/\%/ig;
    push @WHERE_RULES, "name='$attr->{NAME}'";
  }
 
 if ($attr->{DESCRIBE}) {
    $attr->{DESCRIBE} =~ s/\*/\%/ig;
    push @WHERE_RULES, "comments LIKE '$attr->{DESCRIBE}'";
  }
 
 if ($attr->{NUMBER}) {
    my $value = $self->search_expr($attr->{NUMBER}, 'INT');
    push @WHERE_RULES, "number$value";
  }

 if ($attr->{PORT}) {
    my $value = $self->search_expr($attr->{PORT}, 'INT');
    push @WHERE_RULES, "port$value";
  }

#DIsable
 if (defined($attr->{DISABLE})) {
   push @WHERE_RULES, "disable='$attr->{DISABLE}'"; 
 }
 
 $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';
 
 
 $self->query($db, "SELECT num, name,   comments, port,
   disable, id
     FROM iptv_channels
     $WHERE 
     ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;");

 return $self if($self->{errno});

 my $list = $self->{list};

 if ($self->{TOTAL} >= 0) {
    $self->query($db, "SELECT count(*) FROM iptv_channels $WHERE");
    ($self->{TOTAL}) = @{ $self->{list}->[0] };
   }

  return $list;
}



#**********************************************************
#
#**********************************************************
sub tp_defaults {
  my $self = shift;

  my %DATA = (
   ID            => 0, 
   NAME          => '', 
   NUMBER        => 0, 
   PORT          => 0, 
   DESCRIBE      => '', 
   DISABLE       => 0
  );

  $self = \%DATA ;
  return $self;
}

#**********************************************************
# add()
#**********************************************************
sub user_channels {
  my $self = shift;
  my ($attr) = @_;
  
  my %DATA = $self->get_data($attr); 


  $self->query($db,  "DELETE FROM iptv_users_channels WHERE uid='$DATA{UID}'", 'do'),

  my @ids = split(/, /, $attr->{IDS});

  foreach my $id (@ids) {
    $self->query($db,  "INSERT INTO iptv_users_channels 
     ( uid, tp_id, channel_id, changed)
        VALUES ( '$DATA{UID}',  '$DATA{TP_ID}', '$id', now());", 'do');
   }
  
  return $self;
}


#**********************************************************
# add()
#**********************************************************
sub user_channels_list {
  my $self = shift;
  my ($attr) = @_;
  
  $self->query($db,  "SELECT uid, tp_id, channel_id, changed FROM iptv_users_channels 
     WHERE tp_id='$attr->{TP_ID}' and uid='$attr->{UID}';");
  
  $self->{USER_CHANNELS} = $self->{TOTAL};
  return $self->{list};
}



#**********************************************************
# add()
#**********************************************************
sub channel_ti_change {
  my $self = shift;
  my ($attr) = @_;
  
  my %DATA = $self->get_data($attr); 


  $self->query($db,  "DELETE FROM iptv_ti_channels WHERE interval_id='$attr->{INTERVAL_ID}'", 'do'),

  my @ids = split(/, /, $attr->{IDS});

  foreach my $id (@ids) {
    $self->query($db,  "INSERT INTO iptv_ti_channels 
     ( interval_id, channel_id, month_price, day_price, mandatory)
        VALUES ( '$DATA{INTERVAL_ID}',  '$id', '". $DATA{'MONTH_PRICE_'.$id} ."', 
        '". $DATA{'DAY_PRICE_'.$id}."', '". $DATA{'MANDATORY_'.$id}."');", 'do');
   }

  return $self if ($self->{errno});

  #$admin->action_add("$DATA{UID}", "ACTIVE");
  return $self;
}

#**********************************************************
# list()
#**********************************************************
sub channel_ti_list {
 my $self = shift;
 my ($attr) = @_;
 my @list = ();

 $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
 $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
 $PG   = ($attr->{PG}) ? $attr->{PG} : 0;
 $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

 undef @WHERE_RULES;

 # Start letter 
 if ($attr->{NAME}) {
    $attr->{LOGIN_EXPR} =~ s/\*/\%/ig;
    push @WHERE_RULES, "name='$attr->{NAME}'";
  }
 
 if ($attr->{DESCRIBE}) {
    $attr->{DESCRIBE} =~ s/\*/\%/ig;
    push @WHERE_RULES, "comments LIKE '$attr->{DESCRIBE}'";
  }
 
 if ($attr->{NUMBER}) {
    my $value = $self->search_expr($attr->{NUMBER}, 'INT');
    push @WHERE_RULES, "number$value";
  }

 if ($attr->{PORT}) {
    my $value = $self->search_expr($attr->{PORT}, 'INT');
    push @WHERE_RULES, "port$value";
  }
 
 if ($attr->{IDS}) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{IDS}, 'INT', 'c.id') };
  }
 
 if ($attr->{INTERVAL_ID}) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{TI}, 'INT', 'ic.interval_id') };
   $attr->{TI}=$attr->{INTERVAL_ID};
  }

 if ($attr->{MANDATORY}) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{MANDATORY}, 'INT', 'ic.mandatory') };
  }

#DIsable
 if (defined($attr->{DISABLE})) {
   push @WHERE_RULES, "disable='$attr->{DISABLE}'"; 
 }
 
 $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';
 
 $self->query($db, "SELECT if (ic.channel_id IS NULL, 0, 1),
   c.num, c.name,  c.comments, ic.month_price, ic.day_price, ic.mandatory, c.port,
   c.disable, c.id
     FROM iptv_channels c
     LEFT JOIN iptv_ti_channels ic ON (id=ic.channel_id and ic.interval_id='$attr->{TI}')
     $WHERE
     ORDER BY $SORT $DESC ;");

 return $self if($self->{errno});

 my $list = $self->{list};

 if ($self->{TOTAL} >= 0) {
    $self->query($db, "SELECT count(*), sum(if (ic.channel_id IS NULL, 0, 1)) 
     FROM iptv_channels c
     LEFT JOIN iptv_ti_channels ic ON (c.id=ic.channel_id and ic.interval_id='$attr->{TI}')
     $WHERE
    ");

    ($self->{TOTAL}, $self->{ACTIVE}) = @{ $self->{list}->[0] };
   }

  return $list;
}


#**********************************************************
#
#**********************************************************
sub reports_channels_use  {
  my $self = shift;
	my ($attr)=@_;
	
	
 $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
 $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
 $PG = ($attr->{PG}) ? $attr->{PG} : 0;
 $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;
	my $sql = "SELECT c.num,  c.name, count(uc.uid), sum(if(if(company.id IS NULL, b.deposit, cb.deposit)>0, 0, 1))
FROM iptv_channels c
LEFT JOIN iptv_users_channels uc ON (c.id=uc.channel_id)
LEFT JOIN users u ON (uc.uid=u.uid)
LEFT JOIN bills b ON (u.bill_id = b.id)
LEFT JOIN companies company ON  (u.company_id=company.id) 
LEFT JOIN bills cb ON  (company.bill_id=cb.id)
GROUP BY c.id
ORDER BY $SORT $DESC ";


#	$sql = "select c.num, c.name, count(*), c.id
#FROM iptv_channels c 
#LEFT JOIN iptv_ti_channels ic  ON (c.id=ic.channel_id)
#LEFT JOIN intervals i ON (ic.interval_id=i.id)
#LEFT JOIN tarif_plans tp ON (tp.tp_id=i.tp_id)
#LEFT JOIN iptv_main u ON (tp.tp_id=u.tp_id)
#group BY c.id
#     ORDER BY $SORT $DESC ;";
	
	
	$self->query($db, $sql);

 return $self if($self->{errno});

 my $list = $self->{list};

# if ($self->{TOTAL} >= 0) {
#    $self->query($db, "SELECT count(*), sum(if (ic.channel_id IS NULL, 0, 1)) 
#     FROM iptv_channels c
#     LEFT JOIN iptv_ti_channels ic ON (c.id=ic.channel_id and ic.interval_id='$attr->{TI}')
#     $WHERE
#    ");
#
#    ($self->{TOTAL}, $self->{ACTIVE}) = @{ $self->{list}->[0] };
#   }

  return $list;	
}



1
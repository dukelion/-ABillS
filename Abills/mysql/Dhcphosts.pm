package Dhcphosts;
#
# DHCP server managment and user control
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

my $MODULE='Dhcphosts';


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
# routes_list()
#**********************************************************
sub routes_list {
 my $self = shift;
 my ($attr) = @_;

 undef @WHERE_RULES;
 if ($attr->{NET_ID}) {
   push @WHERE_RULES, "r.network='$attr->{NET_ID}'"; 
 }
 if ($attr->{RID}) {
   push @WHERE_RULES, "r.id='$attr->{RID}'"; 
 }

 $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';

 $self->query($db, "SELECT 
    r.id, r.network, inet_ntoa(r.src),
    INET_NTOA(r.mask),
    inet_ntoa(r.router),
    n.name
     FROM dhcphosts_routes r
     left join dhcphosts_networks n on r.network=n.id
     $WHERE
     ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;");

 return $self if($self->{errno});


 my $list = $self->{list};

 if ($self->{TOTAL} > 0) {
    $self->query($db, "SELECT count(*) FROM dhcphosts_routes r $WHERE");
    ($self->{TOTAL}) = @{ $self->{list}->[0] };
  }

  return $list;
};


#**********************************************************
# host_defaults()
#**********************************************************
sub network_defaults {
  my $self = shift;

  my %DATA = (
   ID              => '0',
   NAME            => 'DHCP_NET',
   NETWORK         => '0.0.0.0',   
   MASK            => '255.255.255.0',
   BLOCK_NETWORK   =>  0,
   BLOCK_MASK      =>  0,
   DOMAINNAME      => '',
   DNS             => '',
   COORDINATOR     => '',
   PHONE           => '',
   ROUTERS         => '',
   DISABLE         => 0,
   OPTION_82       => 0,
   IP_RANGE_FIRST  => '0.0.0.0',
   IP_RANGE_LAST   => '0.0.0.0',
   COMMENTS        => '',
   DENY_UNKNOWN_CLIENTS => 0,
   AUTHORITATIVE   => 0, 
   GUEST_VLAN      => 0,
   STATIC          => 0
  );

 
  $self = \%DATA;
  return $self;
}




#**********************************************************
# network_add()
#**********************************************************
sub network_add {
  my $self=shift;
  my ($attr)=@_;
  
  my %DATA = $self->get_data($attr, { default => network_defaults() }); 


  $self->query($db,"INSERT INTO dhcphosts_networks 
     (name,network,mask, routers, coordinator, phone, dns, dns2, ntp,
      suffix, disable,
      ip_range_first, ip_range_last, comments,  deny_unknown_clients,  authoritative, net_parent, guest_vlan, static) 
     VALUES('$DATA{NAME}', INET_ATON('$DATA{NETWORK}'), INET_ATON('$DATA{MASK}'), INET_ATON('$DATA{ROUTERS}'),
       '$DATA{COORDINATOR}', '$DATA{PHONE}', '$DATA{DNS}', '$DATA{DNS2}',  '$DATA{NTP}', 
       '$DATA{DOMAINNAME}',
       '$DATA{DISABLE}',
       INET_ATON('$DATA{IP_RANGE_FIRST}'),
       INET_ATON('$DATA{IP_RANGE_LAST}'),
       '$DATA{COMMENTS}',
       '$DATA{DENY_UNKNOWN_CLIENTS}',
       '$DATA{AUTHORITATIVE}',
       '$DATA{NET_PARENT}',
       '$DATA{GUEST_VLAN}',
       '$DATA{STATIC}'
       )", 'do');

  $admin->system_action_add("DHCPHOSTS_NET:$self->{INSERT_ID}", { TYPE => 1 });    

  return $self;
}

#**********************************************************
# network_delete()
#**********************************************************
sub network_del {
  my $self=shift;
  my ($id)=@_;

  $self->query($db, "DELETE FROM dhcphosts_networks where id='$id';", 'do');
  $self->query($db, "DELETE FROM dhcphosts_hosts where network='$id';", 'do');

  $admin->system_action_add("DHCPHOSTS_NET:$id", { TYPE => 10 });    
  return $self;
};


#**********************************************************
# network_update()
#**********************************************************sub change {
sub network_change {
  my $self = shift;
  my ($attr) = @_;
 
 my %FIELDS = (
   ID              => 'id',
   NAME            => 'name',
   NETWORK         => 'network',   
   MASK            => 'mask',
   BLOCK_NETWORK   => 'block_network',
   BLOCK_MASK      => 'block_mask',
   DOMAINNAME      => 'suffix',
   DNS             => 'dns',
   DNS2            => 'dns2',
   NTP             => 'ntp',
   COORDINATOR     => 'coordinator',
   PHONE           => 'phone',
   ROUTERS         => 'routers',
   DISABLE         => 'disable',
   IP_RANGE_FIRST  => 'ip_range_first',
   IP_RANGE_LAST   => 'ip_range_last',
   COMMENTS        => 'comments',
   DENY_UNKNOWN_CLIENTS => 'deny_unknown_clients',
   AUTHORITATIVE   => 'authoritative',
   NET_PARENT      => 'net_parent',
   GUEST_VLAN      => 'guest_vlan',
   STATIC          => 'static'
   );


  $attr->{DENY_UNKNOWN_CLIENTS} = (defined($attr->{DENY_UNKNOWN_CLIENTS})) ? 1 : 0;
  $attr->{AUTHORITATIVE}        = (defined($attr->{AUTHORITATIVE})) ? 1 : 0;
  $attr->{DISABLE}              = (defined($attr->{DISABLE})) ? 1 : 0;
  $attr->{STATIC}               = (defined($attr->{STATIC})) ? 1 : 0;

	$self->changes($admin, { CHANGE_PARAM => 'ID',
		               TABLE        => 'dhcphosts_networks',
		               FIELDS       => \%FIELDS,
		               OLD_INFO     => $self->network_info($attr->{ID}),
		               DATA         => $attr,
		               EXT_CHANGE_INFO  => "DHCPHOSTS_NET:$attr->{ID}"
		              } );

  return $self;
}


#**********************************************************
# Info
#**********************************************************
sub network_info {
  my $self = shift;
  my ($id) = @_;

  $self->query($db, "SELECT
   id,
   name,
   INET_NTOA(network),
   INET_NTOA(mask),
   INET_NTOA(routers),
   INET_NTOA(block_network),
   INET_NTOA(block_mask),
   suffix,
   dns,
   dns2,
   ntp,
   coordinator,
   phone,
   disable,
   INET_NTOA(ip_range_first),
   INET_NTOA(ip_range_last),
   static,
   comments,
   deny_unknown_clients,
   authoritative,
   net_parent,
   guest_vlan
  FROM dhcphosts_networks

  WHERE id='$id';");

  if ($self->{TOTAL} < 1) {
     $self->{errno} = 2;
     $self->{errstr} = 'ERROR_NOT_EXIST';
     return $self;
   }

  ($self->{ID}, 
   $self->{NAME}, 
   $self->{NETWORK}, 
   $self->{MASK}, 
   $self->{ROUTERS}, 
   $self->{BLOCK_NETWORK}, 
   $self->{BLOCK_MASK}, 
   $self->{DOMAINNAME}, 
   $self->{DNS},
   $self->{DNS2},
   $self->{NTP},
   $self->{COORDINATOR},
   $self->{PHONE},
   $self->{DISABLE},
   $self->{IP_RANGE_FIRST},
   $self->{IP_RANGE_LAST},
   $self->{STATIC},
   $self->{COMMENTS},
   $self->{DENY_UNKNOWN_CLIENTS},
   $self->{AUTHORITATIVE},
   $self->{NET_PARENT},
   $self->{GUEST_VLAN}
   ) = @{ $self->{list}->[0] };
    
  return $self;
}


#**********************************************************
# networks_list()
#**********************************************************
sub networks_list {
 my $self = shift;
 my ($attr) = @_;

 $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
 $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
 $PG = ($attr->{PG}) ? $attr->{PG} : 0;
 $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

 undef @WHERE_RULES;
 if (defined($attr->{DISABLE})) {
   push @WHERE_RULES, "disable='$attr->{DISABLE}'"; 
  }

 if (defined($attr->{PARENT}) && $attr->{PARENT} ne '') {
 	 push @WHERE_RULES, "net_parent='$attr->{PARENT}'"; 
  }

 $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';
 
 $self->query($db, "SELECT 
    id, name, INET_NTOA(network),
     INET_NTOA(mask),
     coordinator,
     phone,
     disable,
     net_parent,
     guest_vlan
     FROM dhcphosts_networks
     $WHERE
     ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;");

 return $self if ($self->{errno});

 my $list = $self->{list};

 if ($self->{TOTAL} > 0 || $PG > 0) {
   $self->query($db, "SELECT count(*) FROM dhcphosts_networks $WHERE");
   ($self->{TOTAL}) = @{ $self->{list}->[0] };
  }

 return $list;
};



#**********************************************************
# host_defaults()
#**********************************************************
sub host_defaults {
  my $self = shift;

  my %DATA = (
   MAC            => '00:00:00:00:00:00', 
   EXPIRE         => '0000-00-00', 
   IP             => '0.0.0.0',
   COMMENTS       => '',
   VID            => 0,
   NAS_ID         => 0,
   OPTION_82      => 0,
   HOSTNAME       => '', 
   NETWORK        => 0, 
   BLOCKTIME      => '', 
   FORCED         => '',
   DISABLE        => '',
   EXPIRE         => '',
   PORTS          => '',
   BOOT_FILE      => '',
   NEXT_SERVER    => '',
   IPN_ACTIVATE   => ''
  );

 
  $self = \%DATA;
  return $self;
}


#**********************************************************
# host_add()
#**********************************************************
sub host_add {
  my $self=shift;
  my ($attr)=@_;

  my %DATA = $self->get_data($attr, { default => host_defaults() }); 

  $self->query($db, "INSERT INTO dhcphosts_hosts (uid, hostname, network, ip, mac, blocktime, 
    forced, disable, expire, comments, option_82, vid, nas, ports, boot_file, next_server, ipn_activate) 
    VALUES('$DATA{UID}', '$DATA{HOSTNAME}', '$DATA{NETWORK}',
      INET_ATON('$DATA{IP}'), '$DATA{MAC}', '$DATA{BLOCKTIME}', '$DATA{FORCED}', '$DATA{DISABLE}',
      '$DATA{EXPIRE}',
      '$DATA{COMMENTS}', '$DATA{OPTION_82}', '$DATA{VID}', '$DATA{NAS_ID}', '$DATA{PORTS}',
      '$DATA{BOOT_FILE}',
      '$DATA{NEXT_SERVER}',
      '$DATA{IPN_ACTIVATE}'
      );", 'do');
  
  $admin->action_add($DATA{UID}, "ADD $DATA{IP}/$DATA{MAC}");

  return $self;
}

#**********************************************************
# host_del()
#**********************************************************
sub host_del {
  my $self=shift;
  my ($attr)=@_;
  my $uid;
  my $action; 

  if ($attr->{UID}) {
  	$WHERE = "uid='$attr->{UID}'";
  	$action= "DELETE ALL HOSTS"; 
  	$uid   = $attr->{UID};
   }
  else {
  	$WHERE   = "id='$attr->{ID}'";
  	my $host = $self->host_info($attr->{ID});
    $uid     = $host->{UID}; 
  	$action  = "DELETE HOST $host->{HOSTNAME} ($host->{IP}/$host->{MAC})"; 
   }

  $self->query($db, "DELETE FROM dhcphosts_hosts where $WHERE", 'do');
 

  $admin->action_add($uid, "$action", { TYPE => 10 }); 

  return $self;
};

#**********************************************************
# host_check()
#**********************************************************
sub host_check {
  my $self=shift;
  my ($attr)=@_;

  my %DATA = $self->get_data($attr);

  my $net = $self->network_info($DATA{NETWORK});

  $self->{errno}=17 if ($self->{TOTAL} == 0);

  my $ip = unpack("N",pack("C4",split(/\./,$DATA{IP})));
  my $mask = unpack("N",pack("C4",split(/\./,$net->{MASK})));
  if (unpack("N",pack("C4",split(/\./,$net->{NETWORK})))!=($ip&$mask)){
    $self->{errno}=17 if ($ip!=0);
  }

  return $self;
} 

#**********************************************************
#host_info()
#**********************************************************
sub host_info {
  my $self=shift;
  my ($id, $attr)=@_;


  if ($attr->{IP}) {
  	$WHERE = "ip=INET_ATON('$attr->{IP}')";
   }
  else {
  	$WHERE = "id='$id'";
   }

  $self->query($db, "SELECT
   uid, 
   hostname, 
   network, 
   INET_NTOA(ip), 
   mac, 
   blocktime, 
   forced,
   disable,
   expire,
   option_82,
   vid,
   comments,
   nas,
   ports,
   boot_file, 
   changed,
   next_server,
   ipn_activate
  FROM dhcphosts_hosts
  WHERE $WHERE;");

  if ($self->{TOTAL} < 1) {
     $self->{errno} = 2;
     $self->{errstr} = 'ERROR_NOT_EXIST';
     return $self;
   }

  ($self->{UID}, 
   $self->{HOSTNAME}, 
   $self->{NETWORK}, 
   $self->{IP}, 
   $self->{MAC}, 
   $self->{BLOCKTIME}, 
   $self->{FORCED},
   $self->{DISABLE},
   $self->{EXPIRE},
   $self->{OPTION_82},
   $self->{VID},
   $self->{COMMENTS},
   $self->{NAS_ID},
   $self->{PORTS},
   $self->{BOOT_FILE},
   $self->{CHANGED},
   $self->{NEXT_SERVER},
   $self->{IPN_ACTIVATE},
   ) = @{ $self->{list}->[0] };

  return $self;
};


#**********************************************************
#host_change()
#**********************************************************
sub host_change {
 my $self=shift;
 my ($attr) = @_;

 my %FIELDS = (
   ID          => 'id',
   UID         => 'uid',
   HOSTNAME    => 'hostname', 
   NETWORK     => 'network', 
   IP         =>  'ip', 
   MAC         => 'mac', 
   BLOCKTIME   => 'blocktime', 
   FORCED      => 'forced',
   DISABLE     => 'disable',
   COMMENTS    => 'comments',
   EXPIRE      => 'expire',
   OPTION_82   => 'option_82',
   VID         => 'vid',
   NAS_ID      => 'nas',
   PORTS       => 'ports',
   BOOT_FILE   => 'boot_file',
   NEXT_SERVER => 'next_server',
   IPN_ACTIVATE=> 'ipn_activate'
#   CHANGED     => 'changed'
  );

  $attr->{OPTION_82}    = ($attr->{OPTION_82}) ? 1 : 0;
  $attr->{IPN_ACTIVATE} = ($attr->{IPN_ACTIVATE}) ? 1 : 0;
  $attr->{DISABLE}      = ($attr->{DISABLE}) ? 1 : 0;
  

	$self->changes($admin, { CHANGE_PARAM => 'ID',
		               TABLE        => 'dhcphosts_hosts',
		               FIELDS       => \%FIELDS,
		               OLD_INFO     => $self->host_info($attr->{ID}),
		               DATA         => $attr
		              } );

  return $self;
};




#**********************************************************
# route_add()
#**********************************************************
sub route_add {
    my $self=shift;
    my ($attr) = @_;

    my %DATA = $self->get_data($attr);
    $self->query($db, "INSERT INTO dhcphosts_routes 
       (network, src, mask, router) 
    values($DATA{NET_ID},INET_ATON('$DATA{SRC}'), INET_ATON('$DATA{MASK}'), INET_ATON('$DATA{ROUTER}'))", 'do');


    $admin->system_action_add("DHCPHOSTS_NET:$DATA{NET_ID} ROUTE:$self->{INSERT_ID}", { TYPE => 1 });    
    return $self;
};

#**********************************************************
# route_delete()
#**********************************************************
sub route_del {
  my $self=shift;
  my ($id)=@_;
  $self->query($db,"DELETE FROM dhcphosts_routes where id='$id'", 'do');

  $admin->system_action_add("DHCPHOSTS_NET: ROUTE:$id", { TYPE => 10 });    
  return $self;
};


#**********************************************************
# route_update()
#**********************************************************
sub route_change {
    my $self=shift;
    my ($attr)=@_;

 my %FIELDS = (
   ID         => 'id',
   NET_ID     => 'network',
   SRC        => 'src', 
   MASK       => 'mask', 
   ROUTER     => 'router'
  );

	$self->changes($admin, { CHANGE_PARAM => 'ID',
		               TABLE        => 'dhcphosts_routes',
		               FIELDS       => \%FIELDS,
		               OLD_INFO     => $self->route_info($attr->{ID}),
		               DATA         => $attr,
		               EXT_CHANGE_INFO  => "DHCPHOSTS_ROUTE:$attr->{ID}"
		              } );

  return $self if($self->{errno});
};

#**********************************************************
# route_update()
#**********************************************************
sub route_info {
  my $self=shift;
  my ($id)=@_;


  $self->query($db,"SELECT 
   id,
   network,
   INET_NTOA(src),
   INET_NTOA(mask),
   INET_NTOA(router)
 
   FROM dhcphosts_routes WHERE id='$id';");

  if ($self->{TOTAL} < 1) {
     $self->{errno} = 2;
     $self->{errstr} = 'ERROR_NOT_EXIST';
     return $self;
   }

  ($self->{NET_ID}, 
   $self->{NETWORK}, 
   $self->{SRC}, 
   $self->{MASK}, 
   $self->{ROUTER}
   ) = @{ $self->{list}->[0] };


  return $self;
};



#**********************************************************
# hosts_list()
#**********************************************************
sub hosts_list {
 my $self = shift;
 my ($attr) = @_;

 $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
 $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
 $PG = ($attr->{PG}) ? $attr->{PG} : 0;
 $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

 @WHERE_RULES = ();

 $self->{SEARCH_FIELDS}='';
 $self->{SEARCH_FIELDS_COUNT} = 0;
 if ($attr->{ID}) {
   push @WHERE_RULES, "h.id='$attr->{ID}'"; 
  }
 else {
  if ($attr->{UID}) {
	  push @WHERE_RULES, "h.uid='$attr->{UID}'"; 
   }
 }

 if ($attr->{LOGIN}) {
   push @WHERE_RULES, @{ $self->search_expr("$attr->{LOGIN}", 'STR', 'u.id') };
  }

 if ($attr->{GIDS}) {
   push @WHERE_RULES, "u.gid IN ($attr->{GIDS})"; 
  }
 elsif ($attr->{GID}) {
   push @WHERE_RULES, "u.gid='$attr->{GID}'"; 
  }

 if ($attr->{HOSTNAME}) {
   push @WHERE_RULES, @{ $self->search_expr("$attr->{HOSTNAME}", 'STR', 'h.hostname') };
  }
 
 if ($attr->{MAC}) {
   push @WHERE_RULES, @{ $self->search_expr("$attr->{MAC}", 'STR', 'h.mac') };
  }

 if ($attr->{IPN_ACTIVATE}) {
   push @WHERE_RULES, @{ $self->search_expr("$attr->{IPN_ACTIVATE}", 'INT', 'h.ipn_activate') };
  }

 if ($attr->{NETWORK}) {
   push @WHERE_RULES, "h.network='$attr->{NETWORK}'"; 
  }

 if ($attr->{IPS}) {
 	 my @ip_arr = split(/,/, $attr->{IPS});
 	 $attr->{IPS}='';
 	 foreach my $ip (@ip_arr) {
 	   $ip =~ s/ //g;
 	   $attr->{IPS}.="INET_ATON('$ip'),";
 	 }
 	 chop($attr->{IPS});
 	 push @WHERE_RULES, "h.ip IN ($attr->{IPS})";
  }
 elsif ($attr->{IP}) {
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
      push @WHERE_RULES, "(h.ip>=INET_ATON('$first_ip') and h.ip<=INET_ATON('$last_ip'))";
     }
    else {
      push @WHERE_RULES, @{ $self->search_expr("$attr->{IP}", 'IP', 'h.ip') };
    }
  }

  if ($attr->{EXPIRE}) {
    push @WHERE_RULES, @{ $self->search_expr("$attr->{EXPIRE}", 'INT', 'h.expire') };
   }

  if (defined($attr->{STATUS})) {
    push @WHERE_RULES, "h.disable='$attr->{STATUS}'";
   }

  if (defined($attr->{USER_DISABLE})) {
    push @WHERE_RULES, "u.disable='$attr->{USER_DISABLE}'";
   }

 if (defined($attr->{DELETED})) {
 	 push @WHERE_RULES,  @{ $self->search_expr("$attr->{DELETED}", 'INT', 'u.deleted', { EXT_FIELD => 1 })  };
  }
 elsif (! $admin->{permissions}->{0} || ! $admin->{permissions}->{0}->{8}) {
	 push @WHERE_RULES,  @{ $self->search_expr(0, 'INT', 'u.deleted', { EXT_FIELD => 1 })  };
  }

  # Deposit chech
  my $EXT_TABLES   = ''; 
  my $extra_fields = '';
  if (defined($attr->{DHCPHOSTS_EXT_DEPOSITCHECK})) {
    $extra_fields = ', if(company.id IS NULL,ext_b.deposit,ext_cb.deposit) ';

    $EXT_TABLES = "
            LEFT JOIN companies company ON  (u.company_id=company.id) 
            LEFT JOIN bills ext_b ON (u.ext_bill_id = ext_b.id)
            LEFT JOIN bills ext_cb ON  (company.ext_bill_id=ext_cb.id) ";
   }
  elsif (defined($attr->{DHCPHOSTS_DEPOSITCHECK})) {
  	$EXT_TABLES = 'LEFT JOIN bills b ON (u.bill_id = b.id)
     LEFT JOIN companies company ON  (u.company_id=company.id) 
     LEFT JOIN bills cb ON  (company.bill_id=cb.id)'; 
    $extra_fields = ', if(company.id IS NULL, b.deposit, cb.deposit) + u.credit';
   }

  if ($attr->{OPTION_82}) {
    push @WHERE_RULES, @{ $self->search_expr("$attr->{OPTION_82}", 'INT', 'h.option_82', { EXT_FIELD => 1 }) };
  }

  if ($attr->{PORTS}) {
    push @WHERE_RULES, @{ $self->search_expr("$attr->{PORTS}", 'STR', 'h.ports', { EXT_FIELD => 1 }) };
  }

  if ($attr->{NAS_ID}) {
    push @WHERE_RULES, @{ $self->search_expr("$attr->{NAS_ID}", 'INT', 'h.nas', { EXT_FIELD => 1 }) };
  }

  if ($attr->{VID}) {
    push @WHERE_RULES, @{ $self->search_expr("$attr->{VID}", 'INT', 'h.vid', { EXT_FIELD => 1 }) };
  }

  if ($attr->{BOOT_FILE}) {
    push @WHERE_RULES, @{ $self->search_expr("$attr->{BOOT_FILE}", 'STR', 'h.boot_file', { EXT_FIELD => 1 }) };
   }

  if ($attr->{NEXT_SERVER}) {
    push @WHERE_RULES, @{ $self->search_expr("$attr->{NEXT_SERVER}", 'STR', 'h.next_server', { EXT_FIELD => 1 }) };
   }


 $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';

 my $fields = "h.id, u.id, h.ip, h.hostname, n.name, h.network, h.mac, h.disable, h.expire, h.forced,  h.blocktime,";
 
 if ($attr->{VIEW}) {
 	 $fields = "h.id, u.id, h.ip, h.hostname, concat(n.name, ' : ', h.network), h.mac, h.disable, h.nas, h.vid, h.ports,";
  }
 
 $self->query($db, "SELECT $fields INET_NTOA(h.ip), $self->{SEARCH_FIELDS} seen, h.uid,
      if ((u.expire <> '0000-00-00' && curdate() > u.expire) || (h.expire <> '0000-00-00' && curdate() > h.expire), 1, 0)
      $extra_fields
     FROM (dhcphosts_hosts h)
     left join dhcphosts_networks n on h.network=n.id
     left join users u on h.uid=u.uid
     $EXT_TABLES
     $WHERE
     ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;");

 return $self if($self->{errno});
 my $list = $self->{list};


 if ($self->{TOTAL} > 0) {
    $self->query($db, "SELECT count(*) FROM dhcphosts_hosts h
     left join users u on h.uid=u.uid
     $WHERE");
    ($self->{TOTAL}) = @{ $self->{list}->[0] };
  }

 return $list;
}


#**********************************************************
# host_defaults()
#**********************************************************
sub leases_defaults {
  my $self = shift;

  my %DATA = (
   STARTS    => '', 
   ENDS      => '', 
   STATE     => 0, 
   NEXT_STATE=> 0,
   HARDWARE  => '', 
   UID       => '', 
   CIRCUIT_ID=> '', 
   REMOTE_ID => '',
   HOSTNAME  => '',
   NAS_ID    => 0,
   IP        => '0.0.0.0'
  );

 
  $self = \%DATA;
  return $self;
}

#**********************************************************
# leases_update()
#**********************************************************
sub leases_update {
  my $self=shift;
  my ($attr)=@_;
  
  my %DATA = $self->get_data($attr, { default => leases_defaults() }); 

  $self->query($db,"INSERT INTO dhcphosts_leases 
     (  start,  ends,
  state,
  next_state,
  hardware,
  uid,
  circuit_id,
  remote_id,
  hostname,
  nas_id,
  ip ) 
     VALUES('$DATA{STARTS}', '$DATA{ENDS}', '$DATA{STATE}', '$DATA{NEXT_STATE}',
       '$DATA{HARDWARE}', '$DATA{UID}', '$DATA{CIRCUIT_ID}', '$DATA{REMOTE_ID}',
       '$DATA{HOSTNAME}',
       '$DATA{NAS_ID}',
       INET_ATON('$DATA{IP}') )", 'do');

  return $self;
}

#**********************************************************
# leases_list()
#**********************************************************
sub leases_list {
  my $self=shift;
  my ($attr)=@_;
  
  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  @WHERE_RULES = ();
  
  if ($attr->{HOSTNAME}) {
    push @WHERE_RULES, @{ $self->search_expr("$attr->{HOSTNAME}", 'STR', 'hostname') };
   }
 
 if ($attr->{HARDWARE}) {
   push @WHERE_RULES, @{ $self->search_expr("$attr->{HARDWARE}", 'STR', 'hardware') };
  }

 if ($attr->{REMOTE_ID}) {
   push @WHERE_RULES, @{ $self->search_expr("$attr->{REMOTE_ID}", 'STR', 'remote_id') };
  }

 if ($attr->{CIRCUIT_ID}) {
   push @WHERE_RULES, @{ $self->search_expr("$attr->{CIRCUIT_ID}", 'STR', 'circuit_id') };
  }

 if ($attr->{IP}) {
 	 push @WHERE_RULES, @{ $self->search_expr("$attr->{IP}", 'IP', 'ip') };
  }

 if ($attr->{ENDS}) {
   push @WHERE_RULES, @{ $self->search_expr("$attr->{ENDS}", 'INT', 'ends') };
  }

 if ($attr->{STARTS}) {
   push @WHERE_RULES, @{ $self->search_expr("$attr->{STARTS}", 'INT', 'starts') };
  }

 if (defined($attr->{STATE})) {
   push @WHERE_RULES, "state='$attr->{STATE}'";
  }

 if (defined($attr->{NEXT_STATE})) {
   push @WHERE_RULES, "next_state='$attr->{NEXT_STATE}'";
  }

 if (defined($attr->{NAS_ID})) {
   push @WHERE_RULES, "nas_id='$attr->{NAS_ID}'";
  }

 if ($attr->{PORTS}) {
   push @WHERE_RULES, @{ $self->search_expr("$attr->{PORTS}", 'INT', 'l.port') };
  }

 if ($attr->{VID}) {
   push @WHERE_RULES, @{ $self->search_expr("$attr->{VID}", 'INT', 'l.vlan') };
  }

 $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';

 # IP, START, MAC, HOSTNAME, ENDS, STATE, REMOTE_ID, 
 
  $self->query($db,"SELECT if (l.uid > 0, u.id, ''), 
  INET_NTOA(l.ip), l.start, l.hardware, l.hostname, 
  l.ends,
  l.state,
  l.port,
  l.vlan,
  l.flag,
  l.remote_id,
  l.circuit_id,
  l.next_state,
  l.uid,
  l.nas_id
  FROM dhcphosts_leases  l
  LEFT JOIN users u ON (u.uid=l.uid)
   $WHERE 
  ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS; ");

  my $list = $self->{list};

  $self->query($db,"SELECT count(*) FROM dhcphosts_leases $WHERE;");

  ($self->{TOTAL}) = @{ $self->{list}->[0] };  

  return $list;
}

#**********************************************************
# leases_update()
#**********************************************************
sub leases_clear {
  my $self=shift;
  my ($attr)=@_;
  
  my %DATA = $self->get_data($attr, { default => leases_defaults() }); 

  $self->query($db,"DELETE FROM dhcphosts_leases WHERE nas_id='$DATA{NAS_ID}';", 'do');
  return $self;
}




#**********************************************************
# host_add()
#**********************************************************
sub log_add {
  my $self=shift;
  my ($attr)=@_;

  my %DATA = $self->get_data($attr); 

  $self->query($db, "INSERT INTO dhcphosts_log (datetime, hostname, message_type, message) 
    VALUES('$DATA{DATETIME}', '$DATA{HOSTNAME}', '$DATA{MESSAGE_TYPE}', '$DATA{MESSAGE}');", 'do');
  
  return $self;
}

#**********************************************************
# host_delete()
#**********************************************************
sub log_del {
  my $self=shift;
  my ($attr)=@_;
  my $uid;
  my $action; 

  if ($attr->{DAYS_OLD}) {
  	$WHERE = "datetime < curdate() - INTERVAL $attr->{DAYS_OLD} day";
   } 
  elsif ($attr->{DATE}) {
  	$WHERE = "datetime='$attr->{DATETIME}'";
   }

  $self->query($db, "DELETE FROM dhcphosts_log where $WHERE", 'do');
  #$admin->system_action_add("DHCPLOG", { TYPE => 10 }); 
  return $self;
};


#**********************************************************
# hosts_list()
#**********************************************************
sub log_list {
 my $self = shift;
 my ($attr) = @_;

 @WHERE_RULES = ();
 $self->{SEARCH_FIELDS}='';
 $self->{SEARCH_FIELDS_COUNT} = 0;
 my @ids = ();
 if ($attr->{UID}) {
  	my $line = $self->hosts_list({ UID => $attr->{UID} });
  	
  	if ($self->{TOTAL} > 0) {
  		foreach my $line ( @{ $line } ) {
  			 push @ids, $line->[11], $line->[6];
  		 }
  	 }
    @WHERE_RULES = ();
    if ($#ids > -1) {
      $attr->{MESSAGE} ='* '. join(" *,* ", @ids) . ' *';
    }
   $self->{IDS}=\@ids;
  }

 $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
 $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
 $PG = ($attr->{PG}) ? $attr->{PG} : 0;
 $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

 if ($attr->{ID}) {
   push @WHERE_RULES, "l.id='$attr->{ID}'"; 
  }

 if ($attr->{LOGIN}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{LOGIN}, 'STR', 'u.id', { EXT_FIELD => 1 }) }; 
  }

 if ($attr->{GIDS}) {
   push @WHERE_RULES, "u.gid IN ($attr->{GIDS})"; 
  }
 elsif ($attr->{GID}) {
   push @WHERE_RULES, "u.gid='$attr->{GID}'"; 
  }

 if ($attr->{HOSTNAME}) {
   push @WHERE_RULES, @{ $self->search_expr("$attr->{HOSTNAME}", 'STR', 'l.hostname') };
  }
 
 if ($attr->{MAC}) {
   push @WHERE_RULES, @{ $self->search_expr("$attr->{MAC}", 'STR', 'l.mac') };
  }

 if ($attr->{MESSAGE_TYPE}) {
   push @WHERE_RULES, @{ $self->search_expr("$attr->{MESSAGE_TYPE}", 'INT', 'l.message_type') };
  }


 if ($attr->{MESSAGE}) {
   push @WHERE_RULES, @{ $self->search_expr("$attr->{MESSAGE}", 'STR', 'l.message') };
  }

if ($attr->{FROM_DATE}) {
   push @WHERE_RULES, "(date_format(l.datetime, '%Y-%m-%d')>='$attr->{FROM_DATE}' and date_format(l.datetime, '%Y-%m-%d')<='$attr->{TO_DATE}')";
 }

 $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';

 $self->query($db, "SELECT l.datetime, l.hostname, l.message_type, l.message
     FROM (dhcphosts_log l)
     $WHERE
     ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;");

 return $self if($self->{errno});

 my $list = $self->{list};

 if ($self->{TOTAL} > 0) {
    $self->query($db, "SELECT count(*) FROM dhcphosts_log l
     $WHERE");
    ($self->{TOTAL}) = @{ $self->{list}->[0] };
  }

 return $list;
}


1




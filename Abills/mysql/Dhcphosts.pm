package Dhcphosts;
# Special thanx for dreamer_538
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

  if ($CONF->{DELETE_USER}) {
    $self->host_del({ UID => $CONF->{DELETE_USER} });
   }
 
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
# network_add()
#**********************************************************
sub network_add {
  my $self=shift;
  my ($attr)=@_;
  

  $self->query($db,"INSERT INTO dhcphosts_networks 
     (name,network,mask, routers, coordinator, phone, dns, suffix, disable) 
     VALUES('$attr->{NAME}', INET_ATON('$attr->{NETWORK}'), INET_ATON('$attr->{MASK}'), INET_ATON('$attr->{ROUTERS}'),
       '$attr->{COORDINATOR}', '$attr->{PHONE}', '$attr->{DNS}', '$attr->{DOMAINNAME}',
       '$attr->{DISABLE}')", 'do');

  return $self;
}

#**********************************************************
# network_delete()
#**********************************************************
sub network_del {
  my $self=shift;
  my ($id)=@_;

  $self->query($db, "DELETE FROM dhcphosts_networks where id='$id';", 'do');

  return $self;
};


#**********************************************************
# network_update()
#**********************************************************sub change {
sub network_change {
  my $self = shift;
  my ($attr) = @_;

 
 my %FIELDS = (
   ID            => 'id',
   NAME          => 'name',
   NETWORK       => 'network',   
   MASK          => 'mask',
   BLOCK_NETWORK => 'block_network',
   BLOCK_MASK    => 'block_mask',
   DOMAINNAME    => 'suffix',
   DNS           => 'dns',
   COORDINATOR   => 'coordinator',
   PHONE         => 'phone',
   ROUTERS       => 'routers',
   DISABLE       => 'disable'

   );

	$self->changes($admin, { CHANGE_PARAM => 'ID',
		               TABLE        => 'dhcphosts_networks',
		               FIELDS       => \%FIELDS,
		               OLD_INFO     => $self->network_info($attr->{ID}),
		               DATA         => $attr
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
   coordinator,
   phone,
   disable
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
   $self->{COORDINATOR},
   $self->{PHONE},
   $self->{DISABLE}
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



 $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';
 
 $self->query($db, "SELECT 
    id, name, INET_NTOA(network),
     INET_NTOA(mask),
     coordinator,
     phone,
     disable
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
   NAS            => 0
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

  my %DATA = $self->get_data($attr); 

  $self->query($db, "INSERT INTO dhcphosts_hosts (uid, hostname, network, ip, mac, blocktime, 
    forced, disable, expire, comments, vid, nas, ports) 
    VALUES('$DATA{UID}', '$DATA{HOSTNAME}', '$DATA{NETWORK}',
      INET_ATON('$DATA{IP}'), '$DATA{MAC}', '$DATA{BLOCKTIME}', '$DATA{FORCED}', '$DATA{DISABLE}',
      '$DATA{EXPIRE}',
      '$DATA{COMMENTS}', '$DATA{VID}', '$DATA{NAS}', '$DATA{PORTS}');", 'do');


  
  $admin->action_add($DATA{DATA}, "ADD $DATA{IP}/$DATA{MAC}");

  return $self;
}

#**********************************************************
# host_delete()
#**********************************************************
sub host_del {
  my $self=shift;
  my ($attr)=@_;

  if ($attr->{UID}) {
  	$WHERE =  "uid='$attr->{UID}'";
   }
  else {
  	$WHERE = "id='$attr->{ID}'";
   }

  $self->query($db, "DELETE FROM dhcphosts_hosts where $WHERE", 'do');
  
  if ($attr->{UID}) {
    $admin->action_add($attr->{UID}, "DELETE");
   }

  return $self;
};

#**********************************************************
#route_update()
#**********************************************************
sub host_info {
  my $self=shift;
  my ($id)=@_;


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
   vid,
   comments,
   nas,
   ports
  FROM dhcphosts_hosts
  WHERE id='$id';");

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
   $self->{VID},
   $self->{COMMENTS},
   $self->{NAS},
   $self->{PORTS}
   ) = @{ $self->{list}->[0] };
  return $self;
};


#**********************************************************
#route_update()
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
   VID         => 'vid',
   NAS         => 'nas',
   PORTS       => 'ports'
  );



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

    return $self;
};

#**********************************************************
# route_delete()
#**********************************************************
sub route_del {
  my $self=shift;
  my ($id)=@_;
  $self->query($db,"DELETE FROM dhcphosts_routes where id='$id'", 'do');

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
		               DATA         => $attr
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

 undef @WHERE_RULES;
 if ($attr->{ID}) {
   push @WHERE_RULES, "h.id='$attr->{ID}'"; 
  }
 else {
  if ($attr->{UID}) {
	  push @WHERE_RULES, "h.uid='$attr->{UID}'"; 
   }
 }

 if ($attr->{LOGIN_EXPR}) {
   $attr->{LOGIN_EXPR} =~ s/\*/\%/g;
   push @WHERE_RULES, "u.id LIKE '$attr->{LOGIN_EXPR}'"; 
  }

 if ($attr->{GIDS}) {
   push @WHERE_RULES, "u.gid IN ($attr->{GIDS})"; 
  }
 elsif ($attr->{GID}) {
   push @WHERE_RULES, "u.gid=$attr->{GID}"; 
  }


 if ($attr->{HOSTNAME}) {
   $attr->{HOSTNAME} =~ s/\*/\%/g;
   push @WHERE_RULES, "h.hostname LIKE '$attr->{HOSTNAME}'"; 
  }
 
 if ($attr->{MAC}) {
   $attr->{MAC} =~ s/\*/\%/g;
   push @WHERE_RULES, "h.mac LIKE '$attr->{MAC}'"; 
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
      my $value = $self->search_expr($attr->{IP}, 'IP');
      push @WHERE_RULES, "h.ip$value";
    }
  }

  if ($attr->{EXPIRE}) {
    my $value = $self->search_expr($attr->{EXPIRE}, 'INT');
    push @WHERE_RULES, "h.expire$value";
  }

  if (defined($attr->{STATUS})) {
    push @WHERE_RULES, "h.disable='$attr->{STATUS}'";
  }

  if (defined($attr->{USER_DISABLE})) {
    push @WHERE_RULES, "u.disable='$attr->{USER_DISABLE}'";
  }

  # Deposit chech
  my $extra_db     = ''; 
  my $extra_fields = '';
  if ($attr->{DHCPHOSTS_DEPOSITCHECK}) {
  	$extra_db = 'LEFT JOIN bills b ON (u.bill_id = b.id)
     LEFT JOIN companies company ON  (u.company_id=company.id) 
     LEFT JOIN bills cb ON  (company.bill_id=cb.id)'; 
    $extra_fields = ', if(company.id IS NULL, b.deposit, cb.deposit) + u.credit';
   }


 $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';

 $self->query($db, "SELECT 
    h.id, u.id, INET_NTOA(h.ip), h.hostname, n.name, h.network, h.mac, h.expire, h.forced, 
      h.blocktime, h.disable, seen, h.uid,
      if ((u.expire <> '0000-00-00' && curdate() > u.expire) || (h.expire <> '0000-00-00' && curdate() > h.expire), 1, 0)
      $extra_fields
     FROM (dhcphosts_hosts h)
     left join dhcphosts_networks n on h.network=n.id
     left join users u on h.uid=u.uid
     $extra_db
     $WHERE
     ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;");

 return $self if($self->{errno});


 my $list = $self->{list};


 if ($self->{TOTAL} > 0) {
    $self->query($db, "SELECT count(*) FROM dhcphosts_hosts h $WHERE");
    ($self->{TOTAL}) = @{ $self->{list}->[0] };
  }

 return $list;
}






1



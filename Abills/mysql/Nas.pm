package Nas;
#Nas Server configuration and managing
 
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION
);


my $db;
use main;
@ISA  = ("main");
my $CONF;
my $SECRETKEY = '';

sub new {
  my $class = shift;
  ($db, $CONF) = @_;
  $SECRETKEY = (defined($CONF->{secretkey})) ? $CONF->{secretkey}: '';
  my $self = { };
  bless($self, $class);
  #$self->{debug}=1;
  return $self;
}

#***************************************************************
# nas_params($attr);
#***************************************************************
sub nas_params {
 my $self = shift;
 my ($attr) = @_;
 
 my $WHERE = (defined $attr->{nas_ip}) ? "WHERE ip='$attr->{nas_ip}'" : '';
 	
 
 my %NAS_INFO = ();
 my $sql = "SELECT id, name, nas_identifier, descr, ip, nas_type, auth_type, mng_host_port, mng_user, 
 DECODE(mng_password, '$SECRETKEY'), rad_pairs 
 FROM nas
 $WHERE;";
 
 #log_print('LOG_SQL', "$sql");
 my $q = $db->prepare("$sql") || die $self->{db}->strerr;
 $q -> execute();
 while(my($id, $name, $nas_identifier, $describe, $ip, $nas_type, $auth_type, $mng_ip_port, 
     $mng_user, $mng_password, $rad_pairs)=$q->fetchrow()) {
     $NAS_INFO{$ip}=$id;
     $NAS_INFO{$ip}{$nas_identifier}=$id;

     $NAS_INFO{$id}{name}=$name || '';
     $NAS_INFO{$id}{nt}=$nas_type  || '';
     $NAS_INFO{$id}{at}=$auth_type || 0;
     $NAS_INFO{$id}{rp}=$rad_pairs || '';
     $NAS_INFO{$id}{mng_user}=$mng_user || '';
     $NAS_INFO{$id}{mng_password}=$mng_password || '';
     my ($mip, $mport)=split(/:/, $mng_ip_port);
     $NAS_INFO{$id}{mng_ip}=$mip || '0.0.0.0';
     $NAS_INFO{$id}{mng_port}=$mport || 0;     
  }
 return \%NAS_INFO;
}

#**********************************************************
# Nas list
#**********************************************************
sub list {
 my $self = shift;
 my ($attr) = @_;

  my @WHERE_RULES  = ();

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  if(defined($attr->{TYPE})) {
  	push @WHERE_RULES, "nas_type='$attr->{TYPE}'";
  }

  if(defined($attr->{DISABLE})) {
  	push @WHERE_RULES, "disable='$attr->{DISABLE}'";
  }

  if($attr->{NAS_IDS}) {
  	push @WHERE_RULES, "id IN ($attr->{NAS_IDS})";
  }

 
 $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';
 
 $self->query($db, "SELECT id, name, nas_identifier, ip,  nas_type, auth_type, disable, descr, alive,
  mng_host_port, mng_user, DECODE(mng_password, '$SECRETKEY'), rad_pairs, ext_acct
  FROM nas
  $WHERE
  ORDER BY $SORT $DESC;");

 return $self->{list};
}

#***************************************************************
# nas_params($attr);
#***************************************************************
sub info {
 my $self = shift;
 my ($attr) = @_;
 
 my $WHERE = '';

 if (defined($attr->{IP})) {
 	 $WHERE = "ip='$attr->{IP}'";
   if (defined($attr->{NAS_IDENTIFIER})) {
     $WHERE .= " and (nas_identifier='$attr->{NAS_IDENTIFIER}' or nas_identifier='')";	
    }
   else {
   	 $WHERE .= " and nas_identifier=''";
    }
  }
 elsif(defined($attr->{NAS_ID})) {
   $WHERE = "id='$attr->{NAS_ID}'";
  }


$self->query($db, "SELECT id, name, nas_identifier, descr, ip, nas_type, auth_type, mng_host_port, mng_user, 
 DECODE(mng_password, '$SECRETKEY'), rad_pairs, alive, disable, ext_acct
 FROM nas
 WHERE $WHERE
 ORDER BY nas_identifier DESC;");

 if(defined($self->{errno})) {
   return $self;
  }
 elsif($self->{TOTAL} < 1) {
   $self->{errstr}="ERROR_NOT_EXIST";
   $self->{errno}=2;
   return $self;
  }

 ( $self->{NAS_ID},
   $self->{NAS_NAME}, 
   $self->{NAS_INDENTIFIER}, 
   $self->{NAS_DESCRIBE}, 
   $self->{NAS_IP}, 
   $self->{NAS_TYPE}, 
   $self->{NAS_AUTH_TYPE}, 
   $self->{NAS_MNG_IP_PORT}, 
   $self->{NAS_MNG_USER}, 
   $self->{NAS_MNG_PASSWORD}, 
   $self->{NAS_RAD_PAIRS},
   $self->{NAS_ALIVE},
   $self->{NAS_DISABLE},
   $self->{NAS_EXT_ACCT}) = @{ $self->{list}->[0] };

 return $self;
}




#**********************************************************
#
#**********************************************************
sub change {
 my $self = shift;
 my ($attr) = @_;

 my %DATA = $self->get_data($attr); 
 my $CHANGES_QUERY = "";
 my $CHANGES_LOG = "NAS:";

 $attr->{NAS_DISABLE} = (defined($attr->{NAS_DISABLE})) ? 1 : 0;

 my %FIELDS = (NAS_ID => 'id', 
  NAS_NAME            => 'name', 
  NAS_INDENTIFIER     => 'nas_identifier', 
  NAS_DESCRIBE        => 'descr', 
  NAS_IP              => 'ip', 
  NAS_TYPE            => 'nas_type', 
  NAS_AUTH_TYPE       => 'auth_type', 
  NAS_MNG_IP_PORT     => 'mng_host_port', 
  NAS_MNG_USER        => 'mng_user', 
  NAS_MNG_PASSWORD    => 'mng_password', 
  NAS_RAD_PAIRS       => 'rad_pairs',
  NAS_ALIVE           => 'alive',
  NAS_DISABLE         => 'disable',
  NAS_EXT_ACCT        => 'ext_acct');


  	$self->changes($admin, { CHANGE_PARAM => 'NAS_ID',
		                TABLE        => 'nas',
		                FIELDS       => \%FIELDS,
		                OLD_INFO     => $self->info({ NAS_ID => $self->{NAS_ID} }),
		                DATA         => $attr
		              } );

  $self->info({ NAS_ID => $self->{NAS_ID} });
  
  return $self;
}

#**********************************************************
# Add nas server
# add($self)
#**********************************************************
sub add {
 my $self = shift;
 my ($attr) = @_;
 
 %DATA = $self->get_data($attr); 

 $self->query($db, "INSERT INTO nas (name, nas_identifier, descr, ip, nas_type, auth_type, mng_host_port, mng_user, 
 mng_password, rad_pairs, alive, disable, ext_acct)
 values ('$DATA{NAS_NAME}', '$DATA{NAS_INDENTIFIER}', '$DATA{NAS_DESCRIBE}', '$DATA{NAS_IP}', '$DATA{NAS_TYPE}', '$DATA{NAS_AUTH_TYPE}',
  '$DATA{NAS_MNG_IP_PORT}', '$DATA{NAS_MNG_USER}', ENCODE('$DATA{NAS_MNG_PASSWORD}', '$SECRETKEY'), '$DATA{NAS_RAD_PAIRS}',
  '$DATA{NAS_ALIVE}', '$DATA{NAS_DISABLE}', '$DATA{NAS_EXT_ACCT}');", 'do');


 return 0;	
}

#**********************************************************
# Add nas server
# add($self)
#**********************************************************
sub del {
 my $self = shift;
 my ($id) = @_;
 
 $self->query($db, "DELETE FROM nas WHERE id='$id'", 'do');
 return 0;	
}



#**********************************************************
# NAS IP Pools
# 
#**********************************************************
sub nas_ip_pools_list {
 my $self = shift;
 my ($attr) = @_;
 
 $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
 $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
 
 my $WHERE_NAS = ($self->{NAS_ID}) ? "AND np.nas_id='$self->{NAS_ID}'" : '' ;

 $self->query($db, "SELECT if (np.nas_id IS NULL, 0, np.nas_id),
   n.name, pool.name, 
   pool.ip, pool.ip + pool.counts, pool.counts,     pool.priority,
    INET_NTOA(pool.ip), INET_NTOA(pool.ip + pool.counts), 
    pool.id, np.nas_id
    FROM ippools pool
    LEFT JOIN  nas_ippools np ON (np.pool_id=pool.id $WHERE_NAS)
    LEFT JOIN nas n ON (n.id=np.nas_id)
      ORDER BY $SORT $DESC");


 return $self->{list};	
}

#**********************************************************
# NAS IP Pools
# 
#**********************************************************
sub nas_ip_pools_set {
 my $self = shift;
 my ($attr) = @_;
 
 $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
 $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
 
 $self->query($db, "DELETE FROM nas_ippools WHERE nas_id='$self->{NAS_ID}'", 'do');

 foreach my $id ( split(/, /, $attr->{ids})) {
   $self->query($db, "INSERT INTO nas_ippools (pool_id, nas_id) 
    VALUES ('$id', '$attr->{NAS_ID}');", 'do');
  }

 return $self->{list};	
}


#**********************************************************
# NAS IP Pools
# 
#**********************************************************
sub ip_pools_info {
 my $self = shift;
 my ($id) = @_;
 
 my $WHERE = '';

 $self->query($db, "SELECT id, INET_NTOA(ip), counts, name, priority
   FROM ippools  WHERE id='$id';");

 if(defined($self->{errno})) {
   return $self;
  }
 elsif($self->{TOTAL} < 1) {
   $self->{errstr}="ERROR_NOT_EXIST";
   $self->{errno}=2;
   return $self;
  }

 ( $self->{ID},
   $self->{NAS_IP_SIP},
   $self->{NAS_IP_COUNT}, 
   $self->{POOL_NAME}, 
   $self->{POOL_PRIORITY},
   $self->{NAS_IP_SIP_INT}
   ) = @{ $self->{list}->[0] };

 return $self;	
}


#**********************************************************
# NAS IP Pools
# 
#**********************************************************
sub ip_pools_change {
 my $self = shift;
 my ($attr) = @_; 


 my %FIELDS = (ID => 'id', 
  POOL_NAME       => 'name', 
  NAS_IP_COUNT    => 'counts', 
  POOL_PRIORITY   => 'priority', 
  NAS_IP_SIP_INT  => 'ip'
 );


	$self->changes($admin, { CHANGE_PARAM => 'ID',
		                TABLE        => 'ippools',
		                FIELDS       => \%FIELDS,
		                OLD_INFO     => $self->ip_pools_info($attr->{ID}),
		                DATA         => $attr
		              } );

  
  return $self;
}

#**********************************************************
# IP pools list
# add($self)
#**********************************************************
sub ip_pools_list {
 my $self = shift;
 my ($attr) = @_;
 
 $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
 $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
 
 my $WHERE = (defined($self->{NAS_ID})) ? "and pool.nas='$self->{NAS_ID}'" : '' ;

 $self->query($db, "SELECT nas.name, pool.name, 
   pool.ip, pool.ip + pool.counts, pool.counts, pool.priority,
    INET_NTOA(pool.ip), INET_NTOA(pool.ip + pool.counts), 
    pool.id, pool.nas
    FROM ippools pool, nas 
    WHERE pool.nas=nas.id
    $WHERE  ORDER BY $SORT $DESC");


 return $self->{list};	
}


#**********************************************************
# Add nas server
# add($self)
#**********************************************************
sub ip_pools_add {
 my $self = shift;
 my ($attr) = @_;
 my %DATA = $self->get_data($attr); 
 
 $self->query($db, "INSERT INTO ippools (nas, ip, counts, name, priority) 
   VALUES ('$DATA{NAS_ID}', INET_ATON('$DATA{NAS_IP_SIP}'), '$DATA{NAS_IP_COUNT}',
   '$DATA{POOL_NAME}', '$DATA{POOL_PRIORITY}')", 'do');

 return 0;	
}


#**********************************************************
# Add nas server
# add($self)
#**********************************************************
sub ip_pools_del {
 my $self = shift;
 my ($id) = @_;
 
 $self->query($db, "DELETE FROM ippools WHERE id='$id'", 'do');
 return 0;	
}



#**********************************************************
# Statistic
# stats($self)
#**********************************************************
sub stats {
 my $self = shift;
 my ($attr) = @_;

 my $WHERE = "WHERE date_format(start, '%Y-%m')=date_format(curdate(), '%Y-%m')";
 
 $SORT = ($attr->{SORT} == 1) ? "1,2" : $attr->{SORT};
 $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

 if(defined($attr->{NAS_ID})) {
   $WHERE .= "and id='$attr->{NAS_ID}'";
  }
 
 $self->query($db, "select n.name, l.port_id, count(*),
   if(date_format(max(l.start), '%Y-%m-%d')=curdate(), date_format(max(l.start), '%H-%i-%s'), max(l.start)),
   SEC_TO_TIME(avg(l.duration)), SEC_TO_TIME(min(l.duration)), SEC_TO_TIME(max(l.duration)),
   l.nas_id
   FROM dv_log l
   LEFT JOIN nas n ON (n.id=l.nas_id)
   $WHERE
   GROUP BY l.nas_id, l.port_id 
   ORDER BY $SORT $DESC;");

 return $self->{list};	
}




#**********************************************************
# Nas list
#**********************************************************
sub log_list {
 my $self = shift;
 my ($attr) = @_;

  my @WHERE_RULES  = ();

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  if(defined($attr->{USER})) {
  	push @WHERE_RULES, @{ $self->search_expr($attr->{USER}, 'STR', 'l.user') };
  }

  if(defined($attr->{MESSAGE})) {
  	push @WHERE_RULES, @{ $self->search_expr($attr->{USER}, 'STR', 'l.message') };
  }

  if($attr->{DATE}) {
  	push @WHERE_RULES, @{ $self->search_expr($attr->{DATE}, 'INT', 'l.date') };
   }

  if($attr->{TIME}) {
  	push @WHERE_RULES, @{ $self->search_expr($attr->{TIME}, 'INT', 'l.time') };
   }

  if($attr->{LOG_TYPE}) {
  	push @WHERE_RULES, @{ $self->search_expr($attr->{LOG_TYPE}, 'INT', 'l.log_type') };
   }

 
 $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';
 
 $self->query($db, "SELECT l.date, l.log_type, l.action, l.user, l.message
  FROM errors_log l
  $WHERE
  ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;");

 return $self->{list};
}

#**********************************************************
# Add nas server
# add($self)
#**********************************************************
sub log_add {
 my $self = shift;
 my ($attr) = @_;
 
 %DATA = $self->get_data($attr); 
 # $date, $time, $log_type, $action, $user, $message

 $self->query($db, "INSERT INTO errors_log (date, log_type, action, user, message)
 values (now(), '$DATA{LOG_TYPE}', '$DATA{ACTION}', '$DATA{USER}', '$DATA{MESSAGE}');", 'do');


 return 0;	
}

#**********************************************************
# Add nas server
# add($self)
#**********************************************************
sub log_del {
 my $self = shift;
 my ($attr) = @_;
 
 %DATA = $self->get_data($attr); 

 #$self->query($db, "INSERT INTO errors_log (date, time, log_type, action, user, message)
 #values (curdate(), curtime(), '$DATA{LOG_TYPE}', '$DATA{ACTION}', '$DATA{USER}', #'$DATA{MESSAGE}');", 'do');


 return 0;	
}

1


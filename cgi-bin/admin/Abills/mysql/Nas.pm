package Nas;
 
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION
);


my $db;
use main;
@ISA  = ("main");
my %DATA;

sub new {
  my $class = shift;
  $db = shift;
  my $self = { };
  bless($self, $class);
#  $self->{debug}=1;
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
 DECODE(mng_password, '$self->{secretkey}'), rad_pairs 
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
 
 my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
 my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
 my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
 my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;


 $self->query($db, "SELECT id, name, nas_identifier, descr, ip,  nas_type, auth_type
  FROM nas
  ORDER BY $SORT $DESC;");

 return $self->{list};
}

#***************************************************************
# nas_params($attr);
#***************************************************************
sub info {
 my $self = shift;
 my ($id, $attr) = @_;
 
 $self->query($db, "SELECT id, name, nas_identifier, descr, ip, nas_type, auth_type, mng_host_port, mng_user, 
 DECODE(mng_password, '$attr->{SECRETKEY}'), rad_pairs 
 FROM nas
 WHERE id='$id';");
 my $a_ref = $self->{list}->[0];
 
 ( $self->{NID},
   $self->{NAS_NAME}, 
   $self->{NAS_INDENTIFIER}, 
   $self->{NAS_DESCRIBE}, 
   $self->{NAS_IP}, 
   $self->{NAS_TYPE}, 
   $self->{NAS_AUTH_TYPE}, 
   $self->{NAS_MNG_IP_PORT}, 
   $self->{NAS_MNG_USER}, 
   $self->{NAS_MNG_PASSWORD}, 
   $self->{NAS_RAD_PAIRS}) = @$a_ref;


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


 my %FIELDS = (NID => 'id', 
  NAS_NAME => 'name', 
  NAS_INDENTIFIER => 'nas_identifier', 
  NAS_DESCRIBE => 'descr', 
  NAS_IP => 'ip', 
  NAS_TYPE => 'nas_type', 
  NAS_AUTH_TYPE => 'auth_type', 
  NAS_MNG_IP_PORT => 'mng_host_port', 
  NAS_MNG_USER => 'mng_user', 
  NAS_MNG_PASSWORD => 'mng_password', 
  NAS_RAD_PAIRS => 'rad_pairs');


 my $OLD = $self->info($self->{NID}, { SECRETKEY => $attr->{SECRETKEY} } );

 while(my($k, $v)=each(%DATA)) {
    if ($OLD->{$k} ne $DATA{$k}){
      if ($k eq 'NAS_MNG_PASSWORD') {
      	 $CHANGES_LOG .= "$k *->*;";
         $CHANGES_QUERY .= "$FIELDS{$k}=ENCODE('$DATA{$k}', '$attr->{SECRETKEY}'),";
       }
      elsif ($FIELDS{$k}) {
         $CHANGES_LOG .= "$k $OLD->{$k}->$DATA{$k};";
         $CHANGES_QUERY .= "$FIELDS{$k}='$DATA{$k}',";
       }
     }
  }


if ($CHANGES_QUERY eq '') {
  return $self->{result};	
}

  chop($CHANGES_QUERY);
  $self->query($db, "UPDATE nas SET $CHANGES_QUERY
    WHERE id='$self->{NID}'", 'do');
#  $admin->action_add(0, "$CHANGES_LOG");

  $self->info($self->{NID}, {SECRETKEY => $attr->{SECRETKEY} });
  
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
 mng_password, rad_pairs)
 values ('$DATA{NAS_NAME}', '$DATA{NAS_INDENTIFIER}', '$DATA{NAS_DESCRIBE}', '$DATA{NAS_IP}', '$DATA{NAS_TYPE}', '$DATA{NAS_AUTH_TYPE}',
  '$DATA{NAS_MNG_IP_PORT}', '$DATA{NAS_MNG_USER}', ENCODE('$DATA{NAS_MNG_PASSWORD}', '$attr->{SECRETKEY}'), '$DATA{NAS_RAD_PAIRS}');", 'do');


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
# Add nas server
# add($self)
#**********************************************************
sub ip_pools_list {
 my $self = shift;
 my ($attr) = @_;
 
 my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
 my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
# my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
# my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

 
 my $WHERE = (defined($self->{NID})) ? "and pool.nas='$self->{NID}'" : '' ;

 $self->query($db, "SELECT nas.name, pool.ip, pool.ip + pool.counts, pool.counts,
    INET_NTOA(pool.ip), INET_NTOA(pool.ip + pool.counts), pool.id, pool.nas
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
 
 $self->query($db, "INSERT INTO ippools (nas, ip, counts) 
   VALUES ('$self->{NID}', INET_ATON('$DATA{NAS_IP_SIP}'), '$DATA{NAS_IP_COUNT}')", 'do');
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
 
 my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
 my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

 $self->query($db, "select n.name, l.port_id, count(*),
   if(date_format(max(l.login), '%Y-%m-%d')=curdate(), date_format(max(l.login), '%H-%i-%s'), max(l.login)),
   SEC_TO_TIME(avg(l.duration)), SEC_TO_TIME(min(l.duration)), SEC_TO_TIME(max(l.duration)),
   l.nas_id
   FROM log l
   LEFT JOIN nas n ON (n.id=l.nas_id)
   WHERE date_format(login, '%Y-%m')=date_format(curdate(), '%Y-%m')
   GROUP BY l.nas_id, l.port_id 
   ORDER BY $SORT $DESC;");

 return $self->{list};	
}




1
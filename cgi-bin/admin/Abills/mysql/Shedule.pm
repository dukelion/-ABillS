package Shedule;
 
use vars qw ($db);
#use strict;

my $db;


sub new {
  my $class = shift;
  $db = shift;
  my $self = { };
  bless($self, $class);
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
# Add new shedule
# add($self)
#**********************************************************
sub add {
 my $self = shift;
 my ($admin, $attr) = @_;

 my $descr=(defined($attr->{descr})) ? $attr->{descr} : '';

 my $h=(defined($attr->{h})) ? $attr->{h} : '*';
 my $d=(defined($attr->{d})) ? $attr->{d} : '*';
 my $m=(defined($attr->{m})) ? $attr->{m} : '*';
 my $y=(defined($attr->{y})) ? $attr->{y} : '*';
 my $count=(defined($attr->{count})) ? int($attr->{count}): 0;
 my $uid=(defined($attr->{uid})) ? int($attr->{uid}) : 0;
 my $type=(defined($attr->{type})) ? $attr->{type} : '';
 my $action=(defined($attr->{action})) ? $attr->{action} : '';
  
 $sql = "INSERT INTO shedule (h, d, m, y, uid, type, action, aid, date) 
        VALUES ('$h', '$d', '$m', '$y', '$uid', '$type', '$action', '$admin->{aid}', now());";

 $q = $db->do($sql) || die $db->strerr;

 if ($db->err == 1062) {
     $self->{errno} = 7;
     $self->{errstr} = 'ERROR_DUBLICATE';
     return $self;
   }
 elsif($db->err > 0) {
     $self->{errno} = 3;
     $self->{errstr} = 'SQL_ERROR';
     return $self;
  }


 return $self;	
}





#**********************************************************
# Add new shedule
# add($self)
#**********************************************************
sub del {
 my $self = shift;
 my ($admin) = @_;

  
  my $id = int($attr->{id});
  my $sql = "DELETE FROM shedule WHERE id='$id';";
  my $q = $db->do($sql) || die $db->strerr;


 if ($db->err == 1062) {
     $self->{errno} = 7;
     $self->{errstr} = 'ERROR_DUBLICATE';
     return $self;
   }
 elsif($db->err > 0) {
     $self->{errno} = 3;
     $self->{errstr} = 'SQL_ERROR';
     return $self;
  }


 return $self;	
}


1
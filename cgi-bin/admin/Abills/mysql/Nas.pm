package Nas;
 
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
# Add nas server
# add($self)
#**********************************************************
sub add {
 my $self = shift;
 my ($attr) = @_;
	

 return 0;	
}


1
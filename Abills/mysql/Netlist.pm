package Netlist;
#Nas Server configuration and managing
 
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION
);


my $db;
use main;
use Socket;

@ISA  = ("main");
my $CONF;
my $admin;
my $SECRETKEY = '';

sub new {
  my $class = shift;
  ($db, $admin, $CONF) = @_;
  my $self = { };
  bless($self, $class);
  return $self;
}

#**********************************************************
# list
#**********************************************************
sub groups_list() {
  my $self = shift;
  my ($attr) = @_;

 $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
 $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

 my @list = ();
 $self->query($db, "SELECT ng.name, ng.comments, count(ni.ip), ng.id
    FROM netlist_groups ng
    LEFT JOIN netlist_ips ni ON (ng.id=ni.gid)
    GROUP BY ng.id
    ORDER BY $SORT $DESC;");


 if ($self->{errno}) {
 	  return \@list;
  }
 

 return $self->{list};
}


#**********************************************************
# Add
#**********************************************************
sub group_add {
  my $self = shift;
  my ($attr) = @_;

  
  %DATA = $self->get_data($attr); 

  $self->query($db, "INSERT INTO netlist_groups (name, comments)
    values ('$DATA{NAME}', '$DATA{COMMENTS}');", 'do');

  $self->{GID}=$self->{INSERT_ID};

  return $self;
}


#**********************************************************
# change
#**********************************************************
sub group_change {
  my $self = shift;
  my ($attr) = @_;


  my %FIELDS = ( ID       => 'id', 
                 NAME     => 'name',
                 COMMENTS => 'comments'
                );   
 
	$self->changes($admin, { CHANGE_PARAM => 'ID',
		                TABLE        => 'netlist_groups',
		                FIELDS       => \%FIELDS,
		                OLD_INFO     => $self->group_info($attr->{ID}, $attr),
		                DATA         => $attr
		              } );
 
	return $self;
}

#**********************************************************
# del
#**********************************************************
sub group_del {
  my $self = shift;
  my ($id) = @_;
  	
  $self->query($db, "DELETE FROM netlist_groups WHERE id='$id';", 'do');
  
 return $self;
}

#**********************************************************
# Info
#**********************************************************
sub group_info {
  my $self = shift;
  my ($id, $attr) = @_;
  
  

  $self->query($db, "SELECT id, 
       name,
       comments
    FROM netlist_groups
    WHERE id='$id';");

  if ($self->{TOTAL} < 1) {
     $self->{errno} = 2;
     $self->{errstr} = 'ERROR_NOT_EXIST';
     return $self;
   }

 
  ($self->{ID}, 
   $self->{NAME}, 
   $self->{COMMENTS}
  ) = @{ $self->{list}->[0] };


  return $self;
}



#**********************************************************
# list
#**********************************************************
sub ip_list() {
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  $PG   = ($attr->{PG}) ? $attr->{PG} : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  @WHERE_RULES = ();

  if ($attr->{GID}) {
    my $value = $self->search_expr($attr->{GID}, 'INT');
    push @WHERE_RULES, "ni.gid$value";
   }

  if ($attr->{IP}) {
    push @WHERE_RULES, "ni.ip=INET_ATON('$attr->{IP}')";
   }

  if ($attr->{STATUS}) {
    push @WHERE_RULES, "ni.status='$attr->{STATUS}'";
   }

  if ($attr->{HOSTNAME}) {
  	$attr->{HOSTNAME} =~ s/\*/\%/ig;
    push @WHERE_RULES, "ni.hostname LIKE '$attr->{HOSTNAME}'";
   }


 $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : ''; 

 $self->query($db, "SELECT ni.ip, INET_NTOA(ni.netmask), ni.hostname, 
      ni.descr,
      ng.name, 
      ni.status, DATE_FORMAT(ni.date, '%Y-%m-%d'), INET_NTOA(ni.ip)
    FROM netlist_ips ni
    LEFT JOIN netlist_groups ng ON (ng.id=ni.gid)
    $WHERE
    GROUP BY ni.ip
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;");


 my $list = $self->{list};
 
 if ($self->{TOTAL} > 0) {
   $self->query($db, "SELECT count(*)
    FROM netlist_ips ni
    LEFT JOIN netlist_groups ng ON (ng.id=ni.gid)
    $WHERE;");

   ($self->{TOTAL}) = @{ $self->{list}->[0] };
  }


 return $list;
}


#**********************************************************
# Add
#**********************************************************
sub ip_add {
  my $self = shift;
  my ($attr) = @_;

  

  %DATA = $self->get_data($attr); 

  $self->query($db, "INSERT INTO netlist_ips (ip, netmask, hostname, 
     gid,
     status,
     comments,
     date,
     descr,
     aid)
    values (INET_ATON('$DATA{IP}'), INET_ATON('$DATA{NETMASK}'), '$DATA{HOSTNAME}',
      '$DATA{GID}',
      '$DATA{STATUS}',
      '$DATA{COMMENTS}',
      now(),
      '$DATA{DESCR}',
      '$admin->{AID}'
     );", 'do');

  return $self;
}


#**********************************************************
# change
#**********************************************************
sub ip_change {
  my $self = shift;
  my ($attr) = @_;


  my %FIELDS = ( IP_NUM    => 'ip', 
                 NETMASK   => 'netmask',
                 HOSTNAME  => 'hostname',
                 GID       => 'gid',
                 STATUS    => 'status',
                 COMMENTS  => 'comments',
                 IP				 => 'ip',
                 DESCR     => 'descr'
                );   

  if ($attr->{IDS}) {
  	my @ids_array = split(/, /, $attr->{IDS});
  	foreach my $a (@ids_array) {
      $attr->{IP_NUM} = $a;	
      $attr->{HOSTNAME}  = gethostbyaddr(inet_aton($a), AF_INET) if ($attr->{RESOLV});

	    $self->changes($admin, { CHANGE_PARAM => 'IP_NUM',
		                           TABLE        => 'netlist_ips',
		                           FIELDS       => \%FIELDS,
		                           OLD_INFO     => $self->ip_info($attr->{IP_NUM}, $attr),
		                           DATA         => $attr
		                          } );

      return $self if ($self->{errno});

  	 }
  	return 0;
   }
 
	$self->changes($admin, { CHANGE_PARAM => 'IP_NUM',
		                       TABLE        => 'netlist_ips',
		                       FIELDS       => \%FIELDS,
		                       OLD_INFO     => $self->ip_info($attr->{IP_NUM}, $attr),
		                       DATA         => $attr
		                      } );
 
	return $self;
}

#**********************************************************
# del
#**********************************************************
sub ip_del {
  my $self = shift;
  my ($ip) = @_;
  	
  $self->query($db, "DELETE FROM netlist_ips WHERE ip='$ip';", 'do');
  
 return $self;
}

#**********************************************************
# Info
#**********************************************************
sub ip_info {
  my $self = shift;
  my ($ip, $attr) = @_;
  
  

  $self->query($db, "SELECT INET_NTOA(ip), 
       INET_NTOA(netmask),
       hostname,
       gid,
       status,
       comments,
       descr,
       ip
    FROM netlist_ips
    WHERE ip='$ip';");

  if ($self->{TOTAL} < 1) {
     $self->{errno} = 2;
     $self->{errstr} = 'ERROR_NOT_EXIST';
     return $self;
   }

  ($self->{IP}, 
   $self->{NETMASK}, 
   $self->{HOSTNAME},
   $self->{GID},
   $self->{STATUS},
   $self->{COMMENTS},
   $self->{DESCR},
   $self->{IP_NUM},
  ) = @{ $self->{list}->[0] };


  return $self;
}

1

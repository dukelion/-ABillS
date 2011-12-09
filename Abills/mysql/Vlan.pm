package Vlan;
# Vlan  managment functions
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


my $uid;
my $MODULE='Vlan';

my %SEARCH_PARAMS = (VLAN_ID   => 0, 
                     IP        => '0.0.0.0', 
                     NETMASK   => '255.255.255.255', 
                     DHCP      => 0
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
 
  return $self;
}




#**********************************************************
# User information
# info()
#**********************************************************
sub info {
  my $self = shift;
  my ($uid, $attr) = @_;

  $WHERE =  "WHERE uid='$uid'";
  
  if (defined($attr->{IP})) {
  	$WHERE = "WHERE ip=INET_ATON('$attr->{IP}')";
   }
  
  $self->query($db, "SELECT vlan_id,
   INET_NTOA(ip), 
   INET_NTOA(netmask), 
   disable, 
   dhcp,
   pppoe,
   nas_id,
   INET_NTOA(unnumbered_ip)
     FROM vlan_main
   $WHERE;");

  if ($self->{TOTAL} < 1) {
     $self->{errno} = 2;
     $self->{errstr} = 'ERROR_NOT_EXIST';
     return $self;
   }

  ($self->{VLAN_ID},
   $self->{IP}, 
   $self->{NETMASK}, 
   $self->{DISABLE},
   $self->{DHCP},
   $self->{PPPOE},
   $self->{NAS_ID},
   $self->{UNNUMBERED_IP},
  )= @{ $self->{list}->[0] };

  return $self;
}



#**********************************************************
#
#**********************************************************
sub defaults {
  my $self = shift;

  my %DATA = (
   VLAN_ID        => 0, 
   DISABLE        => 0, 
   IP             => '0.0.0.0', 
   NETMASK        => '255.255.255.255', 
   DHCP           => 0,
   NAS_ID         => 0,
   PPPOE          => 0,
   UNNUMBERED_IP     => 0
  );

  $self = \%DATA;
  return $self;
}


#**********************************************************
# add()
#**********************************************************
sub add {
  my $self = shift;
  my ($attr) = @_;
  

  
  my %DATA = $self->get_data($attr, { default => defaults() }); 

  $self->query($db,  "INSERT INTO vlan_main (uid, vlan_id, 
             ip, 
             netmask, 
             disable, 
             dhcp,
             pppoe,
             nas_id,
             unnumbered_ip
           )
        VALUES ('$DATA{UID}', '$DATA{VLAN_ID}', INET_ATON('$DATA{IP}'), 
        INET_ATON('$DATA{NETMASK}'), '$DATA{DISABLE}', 
        '$DATA{DHCP}',
        '$DATA{PPPOE}',
        '$DATA{NAS_ID}',
        INET_ATON('$DATA{UNNUMBERED_IP}'));", 'do');

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
  
  my %FIELDS = (
              DISABLE          => 'disable',
              IP               => 'ip',
              NETMASK          => 'netmask',
              VLAN_ID          => 'vlan_id',
              DHCP             => 'dhcp',
              PPPOE            => 'pppoe',
              UID              => 'uid',
              NAS_ID           => 'nas_id',
              UNNUMBERED_IP       => 'unnumbered_ip' 
             );
  
  $attr->{DHCP} = ($attr->{DHCP}) ? $attr->{DHCP} : 0;
  $attr->{PPPOE} = ($attr->{PPPOE}) ? $attr->{PPPOE} : 0;
  
  my $old_info = $self->info($attr->{UID});
  
  $admin->{MODULE}=$MODULE;
  $self->changes($admin, { CHANGE_PARAM => 'UID',
                   TABLE        => 'vlan_main',
                   FIELDS       => \%FIELDS,
                   OLD_INFO     => $old_info,
                   DATA         => $attr
                  } );

  return $self->{result};
}



#**********************************************************
# Delete user info from all tables
#
# del(attr);
#**********************************************************
sub del {
  my $self = shift;
  my ($attr) = @_;

  $self->query($db, "DELETE from vlan_main WHERE uid='$self->{UID}';", 'do');

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


 $self->{SEARCH_FIELDS} = '';
 $self->{SEARCH_FIELDS_COUNT}=0;

 undef @WHERE_RULES;
 push @WHERE_RULES, "u.uid = vlan.uid";
 

 if ($attr->{LOGIN}) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{LOGIN}, 'STR', 'u.id') };
  }
 elsif ($attr->{UID}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{UID}, 'INT', 'vlan.uid') };
  }

 

  if ($attr->{IP}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{IP}, 'IP', 'vlan.ip') };
    $self->{SEARCH_FIELDS} = 'INET_NTOA(vlan.ip), ';
    $self->{SEARCH_FIELDS_COUNT}++;
   }
 
  if ($attr->{UNNUMBERED_IP}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{UNNUMBERED_IP}, 'IP', 'vlan.unnumbered_ip') };
    $self->{SEARCH_FIELDS} = 'INET_NTOA(vlan.unnumbered_ip), ';
    $self->{SEARCH_FIELDS_COUNT}++;
   }


 if ($attr->{PPPOE}) {
    push @WHERE_RULES, "vlan.pppoe='$attr->{PPPOE}'";
  }

 if ($attr->{DHCP}) {
    push @WHERE_RULES, "vlan.dhcp='$attr->{DHCP}'";
  }

 if ($attr->{COMMENTS}) {
   $attr->{COMMENTS} =~ s/\*/\%/ig;
   push @WHERE_RULES, "u.comments LIKE '$attr->{COMMENTS}'";
  }


 if ($attr->{FIO}) {
    $attr->{FIO} =~ s/\*/\%/ig;
    push @WHERE_RULES, "u.fio LIKE '$attr->{FIO}'";
  }

 # Show groups
 if ($attr->{GIDS}) {
   push @WHERE_RULES, "u.gid IN ($attr->{GIDS})"; 
  }
 elsif ($attr->{GID}) {
   push @WHERE_RULES, "u.gid='$attr->{GID}'"; 
  }

 if ($attr->{NAS_ID}) {
    push @WHERE_RULES, "vlan.nas_id='$attr->{NAS_ID}'";
  }


 # Show groups
 if ($attr->{VLAN_ID}) {
   push @WHERE_RULES, "vlan.vlan_id='$attr->{VLAN_ID}'";
  }


#DIsable
 if (defined($attr->{DISABLE})) {
   push @WHERE_RULES, "vlan.disable='$attr->{DISABLE}'"; 
 }

 my $GROUP_BY = "GROUP BY u.uid";

 if (defined($attr->{VLAN_GROUP})) {
   $GROUP_BY = "GROUP BY vlan.vlan_id";
   $self->{SEARCH_FIELDS} = 'max(INET_NTOA(vlan.ip)), min(INET_NTOA(vlan.netmask)), INET_NTOA(vlan.unnumbered_ip),';
   $self->{SEARCH_FIELDS_COUNT}+=2;
  }


 $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';
 

 $self->query($db, "SELECT u.id, 
      pi.fio, 
      if(u.company_id > 0, cb.deposit, b.deposit), 
      u.credit, 
      vlan.vlan_id,
      INET_NTOA(vlan.ip),
      CONCAT(INET_NTOA(vlan.ip+1), ' - ', INET_NTOA(vlan.ip + 4294967294 - vlan.netmask - 1)),
      vlan.disable, 
      vlan.dhcp,
      vlan.pppoe,
      INET_NTOA(vlan.netmask),
      $self->{SEARCH_FIELDS}
      u.uid, 
      u.activate, 
      u.expire
     FROM (users u, vlan_main vlan)
     LEFT JOIN users_pi pi ON (u.uid = pi.uid)
     LEFT JOIN bills b ON (u.bill_id = b.id)
     LEFT JOIN companies company ON  (u.company_id=company.id) 
     LEFT JOIN bills cb ON  (company.bill_id=cb.id)
     $WHERE 
     $GROUP_BY
     ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;");

 return $self if($self->{errno});

 my $list = $self->{list};

 if ($self->{TOTAL} >= 0) {
    $self->query($db, "SELECT count(u.id) FROM (users u, vlan_main vlan) $WHERE");
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

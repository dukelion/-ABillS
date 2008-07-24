package Abon;
# Periodic payments  managment functions
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

my $MODULE='Abon';

@ISA  = ("main");
my $uid;


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
sub tariff_info {
  my $self = shift;
  my ($id) = @_;

  my @WHERE_RULES  = ("id='$id'");
  my $WHERE = '';

 
  $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';
  
  $self->query($db, "SELECT 
   name,
   period,
   price,
   payment_type,
   id
     FROM abon_tariffs
   $WHERE;");

  if ($self->{TOTAL} < 1) {
     $self->{errno} = 2;
     $self->{errstr} = 'ERROR_NOT_EXIST';
     return $self;
   }

  ($self->{NAME},
   $self->{PERIOD},
   $self->{SUM}, 
   $self->{PAYMENT_TYPE},
   $self->{ABON_ID}
  )= @{ $self->{list}->[0] };
  

  
  return $self;
}



#**********************************************************
#
#**********************************************************
sub defaults {
  my $self = shift;

  %DATA = (
   ID => 0, 
   PERIOD => 0, 
   SUM => '0.00'
  );

 
  $self = \%DATA;
  return $self;
}


#**********************************************************
# add()
#**********************************************************
sub tariff_add {
  my $self = shift;
  my ($attr) = @_;
  
  %DATA = $self->get_data($attr); 

  $self->query($db,  "INSERT INTO abon_tariffs (id, name, period, price, payment_type)
        VALUES ('$DATA{ID}', '$DATA{NAME}', '$DATA{PERIOD}', '$DATA{SUM}', '$DATA{PAYMENT_TYPE}');", 'do');

  return $self if ($self->{errno});
#  $admin->action_add($DATA{UID}, "ADDED");
  return $self;
}




#**********************************************************
# change()
#**********************************************************
sub tariff_change {
  my $self = shift;
  my ($attr) = @_;
  
  my %FIELDS = (ABON_ID        => 'id',
              NAME				     => 'name',
              PERIOD           => 'period',
              SUM              => 'price',
              PAYMENT_TYPE     => 'payment_type'
             );

  $self->changes($admin,  { CHANGE_PARAM => 'ABON_ID',
                   TABLE        => 'abon_tariffs',
                   FIELDS       => \%FIELDS,
                   OLD_INFO     => $self->tariff_info($attr->{ABON_ID}),
                   DATA         => $attr
                  } );


  #$admin->action_add($DATA{UID}, "$self->{result}");

  return $self->{result};
}



#**********************************************************
# Delete user info from all tables
# del(attr);
#**********************************************************
sub tariff_del {
  my $self = shift;
  my ($id) = @_;
  
  $self->query($db, "DELETE from abon_tariffs WHERE id='$id';", 'do');
  return $self->{result};
}

#**********************************************************
# list()
#**********************************************************
sub tariff_list {
 my $self = shift;
 my ($attr) = @_;
 @WHERE_RULES = ();

 if ($attr->{IDS}) {
    push @WHERE_RULES, "id IN ($attr->{IDS})";
  }

 $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';
 
 $self->query($db, "SELECT name, price, period, payment_type, count(ul.uid), id 
     FROM abon_tariffs
     LEFT JOIN abon_user_list ul ON (abon_tariffs.id=ul.tp_id)
     $WHERE
     GROUP BY abon_tariffs.id
     ORDER BY $SORT $DESC;");

  return $self->{list};
}



#**********************************************************
# user_list()
#**********************************************************
sub user_list {
 my $self = shift;
 my ($attr) = @_;

 @WHERE_RULES = ("u.uid=ul.uid", "at.id=ul.tp_id");

 # Start letter 
 if ($attr->{FIRST_LETTER}) {
    push @WHERE_RULES, "u.id LIKE '$attr->{FIRST_LETTER}%'";
  }
 elsif ($attr->{LOGIN}) {
    $attr->{LOGIN_EXPR} =~ s/\*/\%/ig;
    push @WHERE_RULES, "u.id='$attr->{LOGIN}'";
  }
 # Login expresion
 elsif ($attr->{LOGIN_EXPR}) {
    $attr->{LOGIN_EXPR} =~ s/\*/\%/ig;
    push @WHERE_RULES, "u.id LIKE '$attr->{LOGIN_EXPR}'";
  }

 if ($attr->{COMPANY_ID}) {
    push @WHERE_RULES, "u.company_id='$attr->{COMPANY_ID}'";
  }


 if ($attr->{GIDS}) {
    push @WHERE_RULES, "u.gid IN ($attr->{GIDS})";
  }
 elsif ($attr->{GID}) {
    push @WHERE_RULES, "u.gid='$attr->{GID}'";
  }


 if ($attr->{ABON_ID}) {
 	 push @WHERE_RULES, "at.id='$attr->{ABON_ID}'";
  }

 $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';
 
 $self->query($db, "SELECT u.id, pi.fio, at.name, at.price, at.period,
     ul.date, u.uid, at.id
     FROM (users u, abon_user_list ul, abon_tariffs at)
     LEFT JOIN users_pi pi ON u.uid = pi.uid
     $WHERE
     GROUP BY ul.uid, ul.tp_id
     ORDER BY $SORT $DESC
     LIMIT $PG, $PAGE_ROWS;");
 my $list = $self->{list};


 if ($self->{TOTAL} > 0) {
    $self->query($db, "SELECT count(u.uid)
     FROM (users u, abon_user_list ul, abon_tariffs at)
     $WHERE");

    ($self->{TOTAL}) = @{ $self->{list}->[0] };
   }



 return $list;
}

#**********************************************************
# user_tariffs()
#**********************************************************
sub user_tariff_list {
 my $self = shift;
 my ($uid, $attr) = @_;

# @WHERE_RULES = ("ul.uid='$uid'");
# $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';
 
 $self->query($db, "SELECT id, name, price, period, ul.date, count(ul.uid)
     FROM abon_tariffs
     LEFT JOIN abon_user_list ul ON (abon_tariffs.id=ul.tp_id and ul.uid='$uid')
     GROUP BY id
     ORDER BY $SORT $DESC;");

 my $list = $self->{list};

 return $list;
}

#**********************************************************
# user_tariffs()
#**********************************************************
sub user_tariff_change {
 my $self = shift;
 my ($attr) = @_;


 $self->query($db, "DELETE from abon_user_list WHERE uid='$attr->{UID}';", 'do');

 
 my @tp_array = split(/, /, $attr->{IDS});
 my $abon_log = "";
 
 foreach my $tp_id (@tp_array) {
   $self->query($db, "INSERT INTO abon_user_list (uid, tp_id) VALUES ('$attr->{UID}', '$tp_id');", 'do');
   $abon_log.="$tp_id, ";
  }


 $admin->action_add($attr->{UID}, "$abon_log");
 return $self;
}



#**********************************************************
# user_tariffs()
#**********************************************************
sub user_tariff_update {
 my $self = shift;
 my ($attr) = @_;

 my $DATE = ($attr->{DATE}) ? "'$attr->{DATE}'" : "now()"; 
 
 $self->query($db, "UPDATE abon_user_list SET date=$DATE
   WHERE uid='$attr->{UID}' and tp_id='$attr->{TP_ID}';", 'do');

 return $self;
}



#**********************************************************
# Periodic
#**********************************************************
sub periodic_list {
  my $self = shift;
  my ($period) = @_;
  

 $self->query($db, "SELECT at.period, at.price, u.uid, if(u.company_id > 0, c.bill_id, u.bill_id),
  u.id, at.id, at.name,
  if(c.name IS NULL, b.deposit, cb.deposit),
  if(u.company_id > 0, c.credit, u.credit),
  u.disable,
  at.id,
  at.payment_type
  FROM (abon_tariffs at, abon_user_list al, users u)
     LEFT JOIN bills b ON (u.bill_id=b.id)
     LEFT JOIN companies c ON (u.company_id=c.id)
     LEFT JOIN bills cb ON (c.bill_id=cb.id)
WHERE
at.id=al.tp_id and
al.uid=u.uid
ORDER BY 1;");

 my $list = $self->{list};


  
  return $list;
}








1

package Marketing;
# Marketing  functions
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

my $MODULE='Marketing';

my %SEARCH_PARAMS = (TP_ID => 0, 
   SIMULTANEONSLY => 0, 
   STATUS        => 0, 
   IP             => '0.0.0.0', 
   NETMASK        => '255.255.255.255', 
   SPEED          => 0, 
   FILTER_ID      => '', 
   CID            => '', 
   REGISTRATION   => ''
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
  
  #if ($CONF->{DELETE_USER}) {
  #  $self->{UID}=$CONF->{DELETE_USER};
  #  $self->del({ UID => $CONF->{DELETE_USER} });
  # }
  
  return $self;
}




#**********************************************************
# report1()
#**********************************************************
sub report1 {
 my $self = shift;
 my ($attr) = @_;
 my @list = ();

 $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
 $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
 $PG = ($attr->{PG}) ? $attr->{PG} : 0;
 $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;


 $self->{SEARCH_FIELDS} = '';
 $self->{SEARCH_FIELDS_COUNT}=0;

 @WHERE_RULES = ( 'u.disable=0' );
 


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


 if ($attr->{DEPOSIT}) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{DEPOSIT}, 'INT', 'u.deposit') };
  }



 $WHERE = ($#WHERE_RULES > -1) ? 'and '. join(' and ', @WHERE_RULES)  : '';



 
 $self->query($db, "SELECT 
      if (pi._c_address <> '', pi._c_address, pi.address_street),
      if (pi._c_build <> '', pi._c_build, pi.address_build),
      count(*) 
     FROM (users_pi pi, users u)
     WHERE u.uid=pi.uid $WHERE
     GROUP BY 1,2
     ORDER BY $SORT $DESC 
     LIMIT $PG, $PAGE_ROWS;");

 return $self if($self->{errno});

 my $list = $self->{list};

 if ($self->{TOTAL} >= 0) {
    $self->query($db, "SELECT count(*) FROM (users u, users_pi pi) 
    WHERE u.uid=pi.uid");
    ($self->{TOTAL}) = @{ $self->{list}->[0] };
   }

  return $list;
}





#**********************************************************
# report1()
#**********************************************************
sub internet_fees_monitor {
 my $self = shift;
 my ($attr) = @_;
 my @list = ();

 $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
 $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
 $PG = ($attr->{PG}) ? $attr->{PG} : 0;
 $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;


 $self->{SEARCH_FIELDS} = '';
 $self->{SEARCH_FIELDS_COUNT}=0;

 @WHERE_RULES = ();
 


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


 if ($attr->{DEPOSIT}) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{DEPOSIT}, 'INT', 'u.deposit') };
  }

 if ($attr->{TP_ID}) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{TP_ID}, 'INT', 'tp.id') };
  }

 if (defined($attr->{STATUS}) && $attr->{STATUS} ne '') {
   push @WHERE_RULES, @{ $self->search_expr($attr->{STATUS}, 'INT', 'dv.disable') };
  }

 my $date = 'curdate()'; 

 if ($attr->{FROM_Y}) {
 	 $date = sprintf("'%s-%.2d-%.2d'", $attr->{FROM_Y}, ($attr->{FROM_M}+1), $attr->{FROM_D});
  }
 

 

 my $WHERE = ($#WHERE_RULES > -1) ? 'WHERE '. join(' and ', @WHERE_RULES)  : '';


 $self->query($db, "select u.uid,  u.id, 
   u.disable,
   dv.disable,
   dv.tp_id, 
   tp.name, 
   tp.month_fee,
   sum(if (DATE_FORMAT($date, '%Y-%m-01')=DATE_FORMAT(f.date, '%Y-%m-%d'), 1, 0)),
   max(f.date)

  from users u
  inner join dv_main dv on (dv.uid=u.uid)
  inner join tarif_plans tp on (dv.tp_id=tp.id)
  left join fees f on (f.uid=u.uid)
  $WHERE
  GROUP BY u.uid
     ORDER BY $SORT $DESC 
     LIMIT $PG, $PAGE_ROWS;");

 return $self if($self->{errno});

 my $list = $self->{list};

 if ($self->{TOTAL} >= 0) {
    $self->query($db, "SELECT count(distinct u.uid) FROM  users u
     inner join dv_main dv on (dv.uid=u.uid)
     inner join tarif_plans tp on (dv.tp_id=tp.id)
    $WHERE;");
    ($self->{TOTAL}) = @{ $self->{list}->[0] };
   }

  return $list;
}





#**********************************************************
# report1()
#**********************************************************
sub increase_report {
 my $self = shift;
 my ($attr) = @_;
 my @list = ();

 $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
 $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
 $PG = ($attr->{PG}) ? $attr->{PG} : 0;
 $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;


 $self->{SEARCH_FIELDS} = '';
 $self->{SEARCH_FIELDS_COUNT}=0;

 @WHERE_RULES = ();
 

 my $date = 'DATE_FORMAT(datetime, \'%Y-%m\')'; 

 if ($attr->{PERIOD}) {
 	 $date = "DATE_FORMAT(datetime, \'%Y-%m-%d\')";
  }

 if ($attr->{MODULE}) {
 	 push @WHERE_RULES, @{ $self->search_expr($attr->{MODULE}, 'INT', 'aa.module') };
  }
 else {
 	 push @WHERE_RULES, 'aa.module=\'\'';
  }
 
 if ($attr->{MONTH}) {
 	 push @WHERE_RULES, "date_format(aa.datetime, '%Y-%m')='$attr->{MONTH}'";
 	 $date = "DATE_FORMAT(datetime, \'%Y-%m-%d\')";
  }
 elsif ($attr->{INTERVAL}) {
   my ($from, $to)=split(/\//, $attr->{INTERVAL}, 2);
   push @WHERE_RULES, "date_format(aa.datetime, '%Y-%m-%d')>='$from' and date_format(aa.datetime, '%Y-%m-%d')<='$to'";
  }

 my $WHERE = ($#WHERE_RULES > -1) ? 'WHERE '. join(' and ', @WHERE_RULES)  : '';


 $self->query($db, "select $date,
  sum(if(action_type = 1, 1, 0)),
  sum(if(action_type = 9, 1, 0)),
  sum(if(action_type = 10, 1, 0))
  
  FROM admin_actions aa
  $WHERE 
  GROUP BY 1
     ORDER BY $SORT $DESC 
     LIMIT $PG, $PAGE_ROWS;");

 return $self if($self->{errno});

 my $list = $self->{list};


 if ($self->{TOTAL} >= 0) {
    $self->query($db, "SELECT count(distinct $date) FROM admin_actions aa
    $WHERE;");
    ($self->{TOTAL}) = @{ $self->{list}->[0] };
   }




  return $list;
}














1

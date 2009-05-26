package Fees;
# Finance module
# Fees 

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION
);

use Exporter;
$VERSION = 2.00;
@ISA = ('Exporter');

@EXPORT = qw(
);

@EXPORT_OK = ();
%EXPORT_TAGS = ();

use main;
use Bills;
@ISA  = ("main");
use Finance;
@ISA  = ("Finance");


my $Bill;
my $admin;
my $CONF;

#**********************************************************
# Init 
#**********************************************************
sub new {
  my $class = shift;
  ($db, $admin, $CONF) = @_;
  my $self = { };
  bless($self, $class);
  
#  $self->{debug}=1;
  
  $Bill=Bills->new($db, $admin, $CONF); 

  return $self;
}


#**********************************************************
#
#**********************************************************
sub defaults {
  my $self = shift;

  my %DATA = (
   UID             => 0, 
   BILL_ID         => 0,
   SUM             => 0.00,
   DESCRIBE        => '',
   SESSION_IP      => 0.0.0.0,
   DEPOSIT         => 0.00,
   AID             => 0,
   COMPANY_VAT     => 0,
   INNER_DESCRIBE  => '',
   METHOD          => 0
  );

 
  $self = \%DATA;
  return $self;
}

#**********************************************************
# Take sum from bill account
# take()
#**********************************************************
sub take {
  my $self = shift;
  my ($user, $sum, $attr) = @_;
  
  %DATA = $self->get_data($attr, { default => defaults() });
  my $DESCRIBE = ($attr->{DESCRIBE}) ? $attr->{DESCRIBE} : '';
  my $DATE  =  ($attr->{DATE}) ? "'$attr->{DATE}'" : 'now()';
  $DATA{INNER_DESCRIBE} = '' if (! $DATA{INNER_DESCRIBE}) ;
  
  if ($sum <= 0) {
     $self->{errno} = 12;
     $self->{errstr} = 'ERROR_ENTER_SUM';
     return $self;
   }
  
  $user->{BILL_ID} = $attr->{BILL_ID} if ($attr->{BILL_ID});
  
  if ($user->{BILL_ID} && $user->{BILL_ID} > 0) {
    $Bill->info( { BILL_ID => $user->{BILL_ID} } );
    
    if ($user->{COMPANY_VAT}) {
      $sum = $sum * ((100 + $user->{COMPANY_VAT}) / 100);
     }
    else {
    	$user->{COMPANY_VAT}=0;
     }

    $Bill->action('take', $user->{BILL_ID}, $sum);
    if($Bill->{errno}) {
       $self->{errno}  = $Bill->{errno};
       $self->{errstr} =  $Bill->{errstr};
       return $self;
      }

    $self->{SUM}=$sum;
    $self->query($db, "INSERT INTO fees (uid, bill_id, date, sum, dsc, ip, last_deposit, aid, vat, inner_describe, method) 
           values ('$user->{UID}', '$user->{BILL_ID}', $DATE, '$self->{SUM}', '$DESCRIBE', 
            INET_ATON('$admin->{SESSION_IP}'), '$Bill->{DEPOSIT}', '$admin->{AID}',
            '$user->{COMPANY_VAT}', '$DATA{INNER_DESCRIBE}', '$DATA{METHOD}')", 'do');

    if($self->{errno}) {
      return $self;
     }
  }
  else {
    $self->{errno}=14;
    $self->{errstr}='No Bill';
  }


  return $self;
}

#**********************************************************
# del $user, $id
#**********************************************************
sub del {
  my $self = shift;
  my ($user, $id) = @_;

  $self->query($db, "SELECT sum, bill_id from fees WHERE id='$id';");

  if ($self->{TOTAL} < 1) {
     $self->{errno} = 2;
     $self->{errstr} = 'ERROR_NOT_EXIST';
     return $self;
   }
  elsif($self->{errno}) {
     return $self;
   }

  my($sum, $bill_id) = @{ $self->{list}->[0] };
  

  $Bill->action('add', $bill_id, $sum); 

  $self->query($db, "DELETE FROM fees WHERE id='$id';", 'do');
  $admin->action_add($user->{UID}, "FEES:$id SUM:$sum", { TYPE => 10 });

  return $self->{result};
}



#**********************************************************
# list()
#**********************************************************
sub list {
 my $self = shift;
 my ($attr) = @_;

 $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
 $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
 $PG = ($attr->{PG}) ? $attr->{PG} : 0;
 $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;


 my @list = (); 
 undef @WHERE_RULES;

 if ($attr->{UID}) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{UID}, 'INT', 'f.uid') };
  }
 # Start letter 
 elsif ($attr->{LOGIN_EXPR}) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{LOGIN_EXPR}, 'STR', 'u.id') };
  }


 if ($attr->{BILL_ID}) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{BILL_ID}, 'INT', 'f.bill_id') };
  }
 elsif ($attr->{COMPANY_ID}) {
 	 push @WHERE_RULES, @{ $self->search_expr($attr->{COMPANY_ID}, 'INT', 'u.company_id') };
  }

 
 if ($attr->{AID}) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{AID}, 'INT', 'f.aid') };
  }

 if ($attr->{ID}) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{ID}, 'INT', 'f.id') };
  }

 if ($attr->{A_LOGIN}) {
 	 push @WHERE_RULES, @{ $self->search_expr($attr->{A_LOGIN}, 'STR', 'a.id') };
 }

 # Show debeters
 if ($attr->{DESCRIBE}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{DESCRIBE}, 'STR', 'f.dsc') };
  }

 if ($attr->{INNER_DESCRIBE}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{INNER_DESCRIBE}, 'STR', 'f.inner_describe') };
  }

 if (defined($attr->{METHOD}) && $attr->{METHOD} >=0) {
    push @WHERE_RULES, "f.method IN ($attr->{METHOD}) ";
  }

 if ($attr->{SUM}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{SUM}, 'INT', 'f.sum') };
  }

 # Show groups
 if ($attr->{GIDS}) {
   push @WHERE_RULES, "u.gid IN ($attr->{GIDS})";
  }
 elsif ($attr->{GID}) {
   push @WHERE_RULES, "u.gid='$attr->{GID}'";
  }

 # Date
 if ($attr->{FROM_DATE}) {
   push @WHERE_RULES, "(date_format(f.date, '%Y-%m-%d')>='$attr->{FROM_DATE}' and date_format(f.date, '%Y-%m-%d')<='$attr->{TO_DATE}')";
  }
 elsif ($attr->{DATE}) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{DATE}, 'INT', 'date_format(f.date, \'%Y-%m-%d\')') };
  }
 # Month
 elsif ($attr->{MONTH}) {
   push @WHERE_RULES, "date_format(f.date, '%Y-%m')='$attr->{MONTH}'";
  }
 # Date




 $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';
 
 $self->query($db, "SELECT f.id, u.id, f.date, f.sum, f.dsc, f.method,
 if(a.name is NULL, 'Unknown', a.name), 
              INET_NTOA(f.ip), f.last_deposit, f.bill_id, f.uid, f.inner_describe
    FROM fees f
    LEFT JOIN users u ON (u.uid=f.uid)
    LEFT JOIN admins a ON (a.aid=f.aid)
    $WHERE 
    GROUP BY f.id
    ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;");

 $self->{SUM}        = '0.00';
 $self->{TOTAL_USERS}= 0;

 return $self->{list}  if ($self->{TOTAL} < 1);
 my $list = $self->{list};

if ($self->{TOTAL} > 0 || $PG > 0 ) {
 $self->query($db, "SELECT count(*), sum(f.sum), count(DISTINCT f.uid) FROM fees f 
  LEFT JOIN users u ON (u.uid=f.uid) 
  LEFT JOIN admins a ON (a.aid=f.aid)
 $WHERE");

 ($self->{TOTAL}, 
  $self->{SUM},
  $self->{TOTAL_USERS}) = @{ $self->{list}->[0] };
}

  return $list;
}

#**********************************************************
# report
#**********************************************************
sub reports {
  my $self = shift;
  my ($attr) = @_;

 $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
 $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
 my $date = '';
 undef @WHERE_RULES;
 
 if ($attr->{GIDS}) {
   push @WHERE_RULES, "u.gid IN ( $attr->{GIDS} )";
  }
 elsif ($attr->{GID}) {
   push @WHERE_RULES, "u.gid='$attr->{GID}'";
  }
 
 if ($attr->{BILL_ID}) {
   push @WHERE_RULES, "f.BILL_ID IN ( $attr->{BILL_ID} )";
  }




 
 if($attr->{DATE}) {
   push @WHERE_RULES, "date_format(f.date, '%Y-%m-%d')='$attr->{DATE}'";
  }
 elsif ($attr->{INTERVAL}) {
 	 my ($from, $to)=split(/\//, $attr->{INTERVAL}, 2);
   push @WHERE_RULES, "date_format(f.date, '%Y-%m-%d')>='$from' and date_format(f.date, '%Y-%m-%d')<='$to'";
  }
 elsif (defined($attr->{MONTH})) {
 	 push @WHERE_RULES, "date_format(f.date, '%Y-%m')='$attr->{MONTH}'";
   $date = "date_format(f.date, '%Y-%m-%d')";
  } 
 else {
 	 $date = "date_format(f.date, '%Y-%m')";
  }

   my $GROUP = 1;
   $attr->{TYPE}='' if (! $attr->{TYPE});
   my $ext_tables = '';

   if ($attr->{TYPE} eq 'HOURS') {
     $date = "date_format(f.date, '%H')";
    }
   elsif ($attr->{TYPE} eq 'DAYS') {
     $date = "date_format(f.date, '%Y-%m-%d')";
    }
   elsif($attr->{TYPE} eq 'METHOD') {
   	 $date = "f.method";   	
    }
   elsif($attr->{TYPE} eq 'ADMINS') {
   	 $date = "a.id";   	
    }
   elsif($attr->{TYPE} eq 'FIO') {
   	 $ext_tables = 'LEFT JOIN users_pi pi ON (u.uid=pi.uid)';
   	 $date  = "pi.fio";  
   	 $GROUP = 5; 	
    }
   elsif($date eq '') {
     $date = "u.id";   	
    }  
 

  if (defined($attr->{METHODS}) and $attr->{METHODS} ne '') {
    push @WHERE_RULES, "f.method IN ($attr->{METHODS}) ";
   }

  my $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';
 
  $self->query($db, "SELECT $date, count(DISTINCT f.uid), count(*),  sum(f.sum), f.uid 
      FROM fees f
      LEFT JOIN users u ON (u.uid=f.uid)
      LEFT JOIN admins a ON (f.aid=a.aid)
      $ext_tables
      $WHERE 
      GROUP BY $GROUP
      ORDER BY $SORT $DESC;");

 my $list = $self->{list}; 

 $self->{SUM}  = '0.00';
 $self->{USERS}= 0; 
if ($self->{TOTAL} > 0 || $PG > 0 ) {	
  $self->query($db, "SELECT count(DISTINCT f.uid), count(*), sum(f.sum) 
      FROM fees f
      LEFT JOIN users u ON (u.uid=f.uid)
      $WHERE;");

  ($self->{USERS}, 
   $self->{TOTAL}, 
   $self->{SUM}) = @{ $self->{list}->[0] };
}
	
	return $list;
}




1

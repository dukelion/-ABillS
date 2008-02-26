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
# Take sum from bill account
# take()
#**********************************************************
sub take {
  my $self = shift;
  my ($user, $sum, $attr) = @_;
  
  
  %DATA = $self->get_data($attr);
  my $DESCRIBE = (defined($attr->{DESCRIBE})) ? $attr->{DESCRIBE} : '';
  my $DATE  =  (defined($attr->{DATE})) ? "'$attr->{DATE}'" : 'now()';
  
  if ($sum <= 0) {
     $self->{errno} = 12;
     $self->{errstr} = 'ERROR_ENTER_SUM';
     return $self;
   }
  
  $user->{BILL_ID} = $attr->{BILL_ID} if ($attr->{BILL_ID});
  
  if ($user->{BILL_ID} > 0) {
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
    $self->query($db, "INSERT INTO fees (uid, bill_id, date, sum, dsc, ip, last_deposit, aid, vat) 
           values ('$user->{UID}', '$user->{BILL_ID}', $DATE, '$self->{SUM}', '$DESCRIBE', 
            INET_ATON('$admin->{SESSION_IP}'), '$Bill->{DEPOSIT}', '$admin->{AID}',
            '$user->{COMPANY_VAT}');", 'do');

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
  $admin->action_add($user->{UID}, "DELETE FEES SUM: $sum");

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
    push @WHERE_RULES, "f.uid='$attr->{UID}'";
  }
 # Start letter 
 elsif ($attr->{LOGIN_EXPR}) {
    $attr->{LOGIN_EXPR} =~ s/\*/\%/ig;
    push @WHERE_RULES, "u.id LIKE '$attr->{LOGIN_EXPR}'";
  }
 
 if ($attr->{AID}) {
    push @WHERE_RULES, "f.aid='$attr->{AID}'";
  }

 if ($attr->{A_LOGIN}) {
 	 $attr->{A_LOGIN} =~ s/\*/\%/ig;
 	 push @WHERE_RULES, "a.id LIKE '$attr->{A_LOGIN}'";
 }

 # Show debeters
 if ($attr->{DESCRIBE}) {
    $attr->{DESCRIBE} =~ s/\*/\%/g;
    push @WHERE_RULES, "f.dsc LIKE '$attr->{DESCRIBE}'";
  }

 # Show debeters
 if ($attr->{SUM}) {
    my $value = $self->search_expr($attr->{SUM}, 'INT');
    push @WHERE_RULES, "f.sum$value";
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
    push @WHERE_RULES, "date_format(f.date, '%Y-%m-%d')='$attr->{DATE}'";
  }
 # Month
 elsif ($attr->{MONTH}) {
    push @WHERE_RULES, "date_format(f.date, '%Y-%m')='$attr->{MONTH}'";
  }
 # Date


 if ($attr->{COMPANY_ID}) {
 	 push @WHERE_RULES, "u.company_id='$attr->{COMPANY_ID}'";
  }


 $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';
 
 $self->query($db, "SELECT f.id, u.id, f.date, f.sum, f.dsc, if(a.name is NULL, 'Unknown', a.name), 
              INET_NTOA(f.ip), f.last_deposit, f.bill_id, f.uid
    FROM fees f
    LEFT JOIN users u ON (u.uid=f.uid)
    LEFT JOIN admins a ON (a.aid=f.aid)
    $WHERE 
    GROUP BY f.id
    ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;");

 $self->{SUM} = '0.00';
 return $self->{list}  if ($self->{TOTAL} < 1);
 my $list = $self->{list};

if ($self->{TOTAL} > 0 || $PG > 0 ) {
 $self->query($db, "SELECT count(*), sum(f.sum) FROM fees f 
  LEFT JOIN users u ON (u.uid=f.uid) 
  LEFT JOIN admins a ON (a.aid=f.aid)
 $WHERE");

 ($self->{TOTAL}, 
  $self->{SUM}) = @{ $self->{list}->[0] };
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
 
 if(defined($attr->{DATE})) {
   push @WHERE_RULES, "date_format(f.date, '%Y-%m-%d')='$attr->{DATE}'";
  }
 elsif ($attr->{INTERVAL}) {
 	 my ($from, $to)=split(/\//, $attr->{INTERVAL}, 2);
   push @WHERE_RULES, "date_format(f.date, '%Y-%m-%d')>='$from' and date_format(f.date, '%Y-%m-%d')<='$to'";
   if ($attr->{TYPE} eq 'HOURS') {
     $date = "date_format(f.date, '%H')";
    }
   elsif ($attr->{TYPE} eq 'DAYS') {
     $date = "date_format(f.date, '%Y-%m-%d')";
    }
   else {
     $date = "u.id";   	
    }  
  }
 elsif (defined($attr->{MONTH})) {
 	 push @WHERE_RULES, "date_format(f.date, '%Y-%m')='$attr->{MONTH}'";
   $date = "date_format(f.date, '%Y-%m-%d')";
  } 
 else {
 	 $date = "date_format(f.date, '%Y-%m')";
  }



  my $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';
 
  $self->query($db, "SELECT $date, count(*), sum(f.sum) 
      FROM fees f
      LEFT JOIN users u ON (u.uid=f.uid)
      $WHERE 
      GROUP BY 1
      ORDER BY $SORT $DESC;");

 my $list = $self->{list}; 

 $self->{SUM} = '0.00';
if ($self->{TOTAL} > 0 || $PG > 0 ) {	
  $self->query($db, "SELECT count(*), sum(f.sum) 
      FROM fees f
      LEFT JOIN users u ON (u.uid=f.uid)
      $WHERE;");

  ($self->{TOTAL}, 
   $self->{SUM}) = @{ $self->{list}->[0] };
}
	
	return $list;
}




1

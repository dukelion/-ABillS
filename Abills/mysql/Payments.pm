package Payments;
# Payments Finance module
#

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION
);

use Exporter;
$VERSION = 2.05;
@ISA = ('Exporter');

@EXPORT = qw(
);

@EXPORT_OK = ();
%EXPORT_TAGS = ();


use main;
@ISA  = ("main");
use Finance;
@ISA  = ("Finance");

use Bills;
my $Bill;

my %FIELDS = (UID      => 'uid', 
              DATE     => 'date', 
              SUM      => 'sum', 
              DESCRIBE => 'dsc', 
              IP       => 'ip',
              LAST_DEPOSIT => 'last_deposit', 
              AID      => 'aid',
              METHOD   => 'method',
              EXT_ID   => 'ext_id',
              BILL_ID  => 'bill_id',
              AMOUNT   => 'amount',
              CURRENCY => 'currency'
             );



#**********************************************************
# Init 
#**********************************************************
sub new {
  my $class = shift;
  ($db, $admin, $CONF) = @_;
  my $self = { };
  bless($self, $class);
  $Bill=Bills->new($db, $admin, $CONF); 
  return $self;
}


#**********************************************************
# Default values
#**********************************************************
sub defaults {
  my $self = shift;

  %DATA = (UID          => 0,
           BILL_ID      => 0, 
           SUM          => '0.00', 
           DESCRIBE     => '', 
           INNER_DESCRIBE => '',
           IP           => '0.0.0.0',
           LAST_DEPOSIT => '0.00', 
           AID          => 0,
           METHOD       => 0,
           ER           => 1,
           EXT_ID       => '',
           AMOUNT       => '0.00',
           CURRENCY     => '0'
          );

  $self = \%DATA;
  return $self;
}



#**********************************************************
# add()
#**********************************************************
sub add {
  my $self = shift;
  my ($user, $attr) = @_;

  %DATA = $self->get_data($attr, { default => defaults() }); 
  if ($DATA{SUM} <= 0) {
     $self->{errno} = 12;
     $self->{errstr} = 'ERROR_ENTER_SUM';
     return $self;
   }
  

  
  if ($DATA{CHECK_EXT_ID}) {
    $self->query($db, "SELECT id, date, sum, uid FROM payments WHERE ext_id='$DATA{CHECK_EXT_ID}';");
    if ($self->{TOTAL} > 0) {
      $self->{errno} = 7;
      $self->{errstr}= 'ERROR_DUBLICATE';
      $self->{ID}    = $self->{list}->[0][0];
      $self->{DATE}  = $self->{list}->[0][1];
      $self->{SUM}   = $self->{list}->[0][2];
      $self->{UID}   = $self->{list}->[0][3];
      return $self;
     }
   }
  
  $db->{AutoCommit}=0; 
  $user->{BILL_ID} = $attr->{BILL_ID} if ($attr->{BILL_ID});
  
  $DATA{AMOUNT}=$DATA{SUM};
  if ($user->{BILL_ID} > 0) {
    if ($DATA{ER} && $DATA{ER} != 1) {
      $DATA{SUM} = sprintf("%.2f", $DATA{SUM} / $DATA{ER});
     }

    $Bill->info( { BILL_ID => $user->{BILL_ID} } );
    $Bill->action('add', $user->{BILL_ID}, $DATA{SUM});
    if($Bill->{errno}) {
      return $self;
     }
    
    my $date = ($DATA{DATE}) ? "'$DATA{DATE}'" : 'now()';
    
    $self->query($db, "INSERT INTO payments (uid, bill_id, date, sum, dsc, ip, last_deposit, aid, method, ext_id,
           inner_describe, amount, currency) 
           values ('$user->{UID}', '$user->{BILL_ID}', $date, '$DATA{SUM}', '$DATA{DESCRIBE}', INET_ATON('$admin->{SESSION_IP}'), '$Bill->{DEPOSIT}', '$admin->{AID}', '$DATA{METHOD}', 
           '$DATA{EXT_ID}', '$DATA{INNER_DESCRIBE}', '$DATA{AMOUNT}', '$DATA{CURRENCY}');", 'do');
    
    if (! $self->{errno}){
 	    if ($CONF->{payment_chg_activate} && $user->{ACTIVATE} ne '0000-00-00') {
        $user->change($user->{UID}, { UID      => $user->{UID}, 
      	                              ACTIVATE => "$admin->{DATE}",
      	                              EXPIRE   => '0000-00-00' 
      	                             });
       }
      $self->{SUM}=$DATA{SUM} ;
      $db->commit() if (! $attr->{TRANSACTION}); 
     }
    else {
    	$db->rollback();
     } 
     
    $self->{PAYMENT_ID}=$self->{INSERT_ID};
   }
  else {
    $self->{errno}=14;
    $self->{errstr}='No Bill';
  }
  
  $db->{AutoCommit}=1  if (! $attr->{NO_AUTOCOMMIT} && ! $attr->{TRANSACTION});

  return $self;
}

#**********************************************************
# del $user, $id
#**********************************************************
sub del {
  my $self = shift;
  my ($user, $id) = @_;

  
  $self->query($db, "SELECT sum, bill_id from payments WHERE id='$id';");

  if ($self->{TOTAL} < 1) {
     $self->{errno} = 2;
     $self->{errstr} = 'ERROR_NOT_EXIST';
     return $self;
   }
  elsif($self->{errno}) {
     return $self;
   }


  my($sum, $bill_id) = @{ $self->{list}->[0] };

  $Bill->action('take', $bill_id, $sum); 
  

  $self->query($db, "DELETE FROM payments WHERE id='$id';", 'do');
  $admin->action_add($user->{UID}, "PAYEMNTS:$id SUM:$sum", { TYPE => 10 });

  return $self;
}



#**********************************************************
# list()
#**********************************************************
sub list {
 my $self = shift;
 my ($attr) = @_;


 $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
 $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
 $PG   = ($attr->{PG}) ? $attr->{PG} : 0;
 $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;
 
 undef @WHERE_RULES;
 
 if ($attr->{UID}) {
    push @WHERE_RULES, "p.uid='$attr->{UID}' ";
  }
 elsif ($attr->{LOGIN}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{LOGIN}, 'STR', 'u.id') };
  }
 
 if ($attr->{AID}) {
    push @WHERE_RULES, "p.aid='$attr->{AID}' ";
  }

 if ($attr->{A_LOGIN}) {
 	 push @WHERE_RULES,  @{ $self->search_expr($attr->{A_LOGIN}, 'STR', 'a.id') };
  }

 if ($attr->{DESCRIBE}) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{DESCRIBE}, 'STR', 'p.dsc') };
  }

 if ($attr->{INNER_DESCRIBE}) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{INNER_DESCRIBE}, 'STR', 'p.inner_describe') };
  }


 if ($attr->{SUM}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{SUM}, 'INT', 'p.sum') };
  }

 if ($attr->{AMOUNT}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{AMOUNT}, 'INT', 'p.amount') };
  }

 if ($attr->{CURRENCY}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{CURRENCY}, 'INT', 'p.currency') };
  }


 if (defined($attr->{METHOD})) {
   push @WHERE_RULES, "p.method IN ($attr->{METHOD}) ";
  }

 if ($attr->{DOMAIN_ID}) {
   push @WHERE_RULES, "u.domain_id='$attr->{DOMAIN_ID}' ";
  }

 if ($attr->{DATE}) {
    push @WHERE_RULES, @{ $self->search_expr("$attr->{DATE}", 'INT', 'date_format(p.date, \'%Y-%m-%d\')') };
  }
 elsif ($attr->{MONTH}) {
    my $value = $self->search_expr("$attr->{MONTH}", 'INT');
    push @WHERE_RULES,  " date_format(p.date, '%Y-%m')$value ";
  }
 # Date intervals
 elsif ($attr->{FROM_DATE}) {
   push @WHERE_RULES, @{ $self->search_expr(">=$attr->{FROM_DATE}", 'DATE', 'date_format(p.date, \'%Y-%m-%d\')') },
   @{ $self->search_expr("<=$attr->{TO_DATE}", 'DATE', 'date_format(p.date, \'%Y-%m-%d\')') };
  }
 elsif ($attr->{FROM_DATE_TIME}) {
   push @WHERE_RULES, @{ $self->search_expr(">=$attr->{FROM_DATE_TIME}", 'DATE', 'p.date') },
   @{ $self->search_expr("<=$attr->{TO_DATE_TIME}", 'DATE', 'p.date') };
  }
 elsif ($attr->{PAYMENT_DAYS}) {
 	 my $expr = '=';
 	 if ($attr->{PAYMENT_DAYS} =~ s/^(<|>)//) {
 	   $expr = $1;
 	  }
 	 push @WHERE_RULES, "p.date $expr curdate() - INTERVAL $attr->{PAYMENT_DAYS} DAY";
  }

 if ($attr->{BILL_ID}) {
 	 push @WHERE_RULES, @{ $self->search_expr("$attr->{BILL_ID}", 'INT', 'p.bill_id') };
  }
 elsif ($attr->{COMPANY_ID}) {
 	 push @WHERE_RULES, @{ $self->search_expr($attr->{COMPANY_ID}, 'INT', 'u.company_id') };
  }

 if ($attr->{EXT_ID}) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{EXT_ID}, 'STR', 'p.ext_id') };
  }
 elsif($attr->{EXT_IDS}) {
 	 push @WHERE_RULES, "p.ext_id in ($attr->{EXT_IDS})";
  }
 
 if ($attr->{ID}) {
 	 push @WHERE_RULES, @{ $self->search_expr("$attr->{ID}", 'INT', 'p.id') };
  }

 # Show groups
 if ($attr->{GIDS}) {
    push @WHERE_RULES, "u.gid IN ( $attr->{GIDS} )";
  }
 elsif ($attr->{GID}) {
    push @WHERE_RULES, "u.gid='$attr->{GID}'";
  }

 my $ext_tables  = '';
 my $login_field = '';
 if($attr->{FIO}) {
   $ext_tables = 'LEFT JOIN users_pi pi ON (u.uid=pi.uid)';
   $login_field  = "pi.fio,";  
  }

 $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';
 
 $self->query($db, "SELECT p.id, u.id, $login_field p.date, p.dsc, p.sum, p.last_deposit, p.method, 
      p.ext_id, p.bill_id, 
      if(a.name is null, 'Unknown', a.name),  
      INET_NTOA(p.ip), 
      p.amount,
      p.currency,
      p.uid, 
      p.inner_describe
    FROM payments p
    LEFT JOIN users u ON (u.uid=p.uid)
    LEFT JOIN admins a ON (a.aid=p.aid)
    $ext_tables
    $WHERE 
    GROUP BY p.id
    ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;");

 $self->{SUM}='0.00';

 return $self->{list}  if ($self->{TOTAL} < 1);
 my $list = $self->{list};

 $self->query($db, "SELECT count(p.id), sum(p.sum), count(DISTINCT p.uid) FROM payments p
  LEFT JOIN users u ON (u.uid=p.uid)
  LEFT JOIN admins a ON (a.aid=p.aid) $WHERE");

 ( $self->{TOTAL},
   $self->{SUM},
   $self->{TOTAL_USERS} )= @{ $self->{list}->[0] };

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
 my $date       = '';
 my $ext_tables = '';
 my $GROUP      = 1;
 
 undef @WHERE_RULES;

 if ($attr->{GIDS}) {
   push @WHERE_RULES, "u.gid IN ( $attr->{GIDS} )";
  }
 elsif ($attr->{GID}) {
   push @WHERE_RULES, "u.gid='$attr->{GID}'";
  }

 if (defined($attr->{METHODS}) and $attr->{METHODS} ne '') {
    push @WHERE_RULES, "p.method IN ($attr->{METHODS}) ";
  }

 if(defined($attr->{DATE})) {
   push @WHERE_RULES, "date_format(p.date, '%Y-%m-%d')='$attr->{DATE}'";
  }
 elsif ($attr->{INTERVAL}) {
 	 my ($from, $to)=split(/\//, $attr->{INTERVAL}, 2);
   
   push @WHERE_RULES, @{ $self->search_expr(">=$from", 'DATE', 'date_format(p.date, \'%Y-%m-%d\')') },
   @{ $self->search_expr("<=$to", 'DATE', 'date_format(p.date, \'%Y-%m-%d\')') };

   if ($attr->{TYPE} eq 'HOURS') {
     $date = "date_format(p.date, '%H')";
    }
   elsif ($attr->{TYPE} eq 'DAYS') {
     $date = "date_format(p.date, '%Y-%m-%d')";
    }
   elsif($attr->{TYPE} eq 'PAYMENT_METHOD') {
   	 $date = "p.method";   	
    }
   elsif($attr->{TYPE} eq 'FIO') {
   	 $ext_tables = 'LEFT JOIN users_pi pi ON (u.uid=pi.uid)';
   	 $date  = "pi.fio";  
   	 $GROUP = 5; 	
    } 
   elsif($attr->{TYPE} eq 'ADMINS') {
   	 $date = "a.id";   	
    }
   else {
     $date = "u.id";   	
    }  
  }
 elsif (defined($attr->{MONTH})) {
 	 push @WHERE_RULES, "date_format(p.date, '%Y-%m')='$attr->{MONTH}'";
   $date = "date_format(p.date, '%Y-%m-%d')";
  } 
 elsif ($attr->{PAYMENT_DAYS}) {
 	 my $expr = '=';
 	 if ($attr->{PAYMENT_DAYS} =~ /(<|>)/) {
 	   $expr = $1;
 	  }
 	 push @WHERE_RULES, "p.date $expr curdate() - INTERVAL $attr->{PAYMENT_DAYS} DAY";
  } 
 else {
 	 $date = "date_format(p.date, '%Y-%m')";
  }

 if ($attr->{ADMINS}) {
 	 push @WHERE_RULES,  @{ $self->search_expr($attr->{ADMINS}, 'STR', 'a.id') };
 	 $date = 'u.id';
  }


  my $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';
 
  $self->query($db, "SELECT $date, count(DISTINCT p.uid), count(*), sum(p.sum), p.uid 
      FROM (payments p)
      LEFT JOIN users u ON (u.uid=p.uid)
      LEFT JOIN admins a ON (a.aid=p.aid)
      $ext_tables
      $WHERE 
      GROUP BY 1
      ORDER BY $SORT $DESC;");

 my $list = $self->{list}; 
 
 if ($self->{TOTAL} > 0) {
   $self->query($db, "SELECT count(DISTINCT p.uid), count(*), sum(p.sum) 
      FROM payments p
      LEFT JOIN users u ON (u.uid=p.uid)
      $WHERE;");

   ($self->{USERS},
    $self->{TOTAL}, 
    $self->{SUM}) = @{ $self->{list}->[0] };
  }
 else {
   $self->{USERS}=0; 
   $self->{TOTAL}=0; 
   $self->{SUM}=0.00;
  }

	return $list;
}



1

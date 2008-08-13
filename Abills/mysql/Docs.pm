package Docs;
# Documents functions functions
#

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION
);

use Exporter;
$VERSION = 2.00;
@ISA = ('Exporter');

@EXPORT = qw();

@EXPORT_OK = ();
%EXPORT_TAGS = ();

use main;
@ISA  = ("main");


#**********************************************************
# Init 
#**********************************************************
sub new {
  my $class = shift;
  ($db, $admin, $CONF) = @_;
  my $self = { };
  bless($self, $class);

  if ($CONF->{DELETE_USER}) {
    $self->{UID}=$CONF->{DELETE_USER};
    $self->del({ UID => $CONF->{DELETE_USER} });
   }

  $CONF->{DOCS_ACCOUNT_EXPIRE_PERIOD}=30 if (! $CONF->{DOCS_ACCOUNT_EXPIRE_PERIOD});

#  $self->{debug}=1;
  return $self;
}



#**********************************************************
# Default values
#**********************************************************
sub account_defaults {
  my $self = shift;

  %DATA = ( SUM    => '0.00',
            COUNTS => 1,
            UNIT   => 1
          );   
 
  $self = \%DATA;
  return $self;
}


#**********************************************************
# accounts_list
#**********************************************************
sub docs_invoice_list {
  my $self = shift;
  my ($attr) = @_;

 $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
 $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';


 @WHERE_RULES = ("d.id=o.invoice_id");
 
 if($attr->{LOGIN_EXPR}) {
 	 require Users;
	 push @WHERE_RULES, "d.uid='$attr->{UID}'"; 
  }
 
 if($attr->{CUSTOMER}) {
   $attr->{CUSTOMER} =~ s/\*/\%/ig;
	 push @WHERE_RULES, "d.customer='$attr->{CUSTOMER}'"; 
  }
 
 if ($attr->{FROM_DATE}) {
    push @WHERE_RULES, "(date_format(d.date, '%Y-%m-%d')>='$attr->{FROM_DATE}' and date_format(d.date, '%Y-%m-%d')<='$attr->{TO_DATE}')";
  }

 if ($attr->{DOC_ID}) {
 	  my $value = $self->search_expr($attr->{DOC_ID}, 'INT');
    push @WHERE_RULES, "d.acct_id$value";
  }

 if ($attr->{SUM}) {
 	  my $value = $self->search_expr($attr->{SUM}, 'INT');
    push @WHERE_RULES, "o.price * o.counts$value";
  }

 # Show groups
 if ($attr->{GIDS}) {
   push @WHERE_RULES, "u.gid IN ($attr->{GIDS})"; 
  }
 elsif ($attr->{GID}) {
   push @WHERE_RULES, "u.gid='$attr->{GID}'"; 
  }

 
 #DIsable
 if ($attr->{UID}) {
   push @WHERE_RULES, "d.uid='$attr->{UID}'"; 
 }
 

 $WHERE = ($#WHERE_RULES > -1) ? 'WHERE ' . join(' and ', @WHERE_RULES)  : '';


  $self->query($db,   "SELECT d.invoice_id, d.date, d.customer,  sum(o.price * o.counts), u.id, a.name, d.created, d.uid, d.id
    FROM (docs_invoice d, docs_invoice_orders o)
    LEFT JOIN users u ON (d.uid=u.uid)
    LEFT JOIN admins a ON (d.aid=a.aid)
    $WHERE
    GROUP BY d.id 
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;");


 return $self->{list}  if ($self->{TOTAL} < 1);
 my $list = $self->{list};


 $self->query($db, "SELECT count(*)
    FROM (docs_invoice d, docs_invoice_orders o)
    LEFT JOIN users u ON (d.uid=u.uid)
    $WHERE");

 ($self->{TOTAL}) = @{ $self->{list}->[0] };

	return $list;
}

#**********************************************************
# Bill
#**********************************************************
sub docs_invoice_info {
	my $self = shift;
	my ($id, $attr) = @_;

  $WHERE = ($attr->{UID}) ? "and d.uid='$attr->{UID}'" : '';

  $self->query($db, "SELECT 
   d.invoice_id,
   d.date,
   d.customer,
   sum(o.price * o.counts), 
   d.phone,
   if(d.vat>0, FORMAT(sum(o.price * o.counts) / ((100+d.vat)/ d.vat), 2), FORMAT(0, 2)),
   a.name,
   u.id,
   d.created,
   d.by_proxy_seria,
   d.by_proxy_person,
   d.by_proxy_date,
   d.id
    FROM (docs_invoice d, docs_invoice_orders o)
    LEFT JOIN users u ON (d.uid=u.uid)
    LEFT JOIN admins a ON (d.aid=a.aid)
    WHERE d.id=o.invoice_id and d.id='$id' $WHERE
    GROUP BY d.id;");

  if ($self->{TOTAL} < 1) {
     $self->{errno} = 2;
     $self->{errstr} = 'ERROR_NOT_EXIST';
     return $self;
   }

  ($self->{INVOICE_ID}, 
   $self->{DATE}, 
   $self->{CUSTOMER}, 
   $self->{SUM},
   $self->{PHONE},
   $self->{VAT},
   $self->{ADMIN},
   $self->{USER},
   $self->{CREATED},
   $self->{BY_PROXY_SERIA},
   $self->{BY_PROXY_PERSON},
   $self->{BY_PROXY_DATE}
  )= @{ $self->{list}->[0] };
	
  if ($self->{TOTAL} > 0) {
    $self->{NUMBER}=$self->{INVOICE_ID};
 
    $self->query($db, "SELECT invoice_id, orders, unit, counts, price
      FROM docs_invoice_orders WHERE invoice_id='$id'");
    $self->{ORDERS}=$self->{list};
   }

	return $self;
}



#**********************************************************
# Bill
#**********************************************************
sub docs_invoice_add {
	my $self = shift;
	my ($attr) = @_;
 
 
 
  %DATA = $self->get_data($attr, { default => \%DATA }); 
  
  if (! defined($attr->{ORDERS}) || $#{ $attr->{ORDERS} } < 0) {
  	$self->{errno}=1;
  	$self->{errstr}="No orders";

  	return $self;
  }
  
  
  $DATA{DATE}    = ($attr->{DATE})    ? "'$attr->{DATE}'" : 'now()';
  $DATA{INVOICE_ID} = ($attr->{INVOICE_ID}) ? $attr->{INVOICE_ID}  : $self->docs_nextid({ TYPE => 'INVOICE' });
  

  $self->query($db, "insert into docs_invoice (invoice_id, date, created, customer, phone, aid, uid,
    by_proxy_seria,
    by_proxy_person,
    by_proxy_date)
      values ('$DATA{INVOICE_ID}', $DATA{DATE}, now(), \"$DATA{CUSTOMER}\", \"$DATA{PHONE}\", 
      \"$admin->{AID}\", \"$DATA{UID}\",
      '$DATA{BY_PROXY_SERIA}',
      '$DATA{BY_PROXY_PERSON}',
      '$DATA{BY_PROXY_DATE}');", 'do');
 
  return $self if($self->{errno});
  $self->{DOC_ID}=$self->{INSERT_ID};
  
  foreach my $line (@{ $attr->{ORDERS} }) {
    my ($order, $unit, $count,  $sum)=split(/\|/, $line, 4);
    $self->query($db, "INSERT INTO docs_invoice_orders (invoice_id, orders, counts, unit, price)
      values ($self->{DOC_ID}, \"$order\", '$count', '$unit', '$sum')", 'do');
  }

  return $self if($self->{errno});
  
  $self->{INVOICE_ID}=$DATA{ACCT_ID};
  $self->docs_invoice_info($self->{DOC_ID});

	return $self;
}


#**********************************************************
# Bill
#**********************************************************
sub docs_invoice_del {
	my $self = shift;
	my ($id, $attr) = @_;

  if ($id == 0 && $attr->{UID}) {
    #$self->query($db, "DELETE FROM docs_acct_orders WHERE acct_id='$id'", 'do');
    #$self->query($db, "DELETE FROM docs_acct WHERE uid='$id'", 'do');
   }
  else {
    $self->query($db, "DELETE FROM docs_invoice_orders WHERE acct_id='$id'", 'do');
    $self->query($db, "DELETE FROM docs_invoice WHERE id='$id'", 'do');
   }

	return $self;
}


#**********************************************************
# accounts_list
#**********************************************************
sub accounts_list {
  my $self = shift;
  my ($attr) = @_;

 $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
 $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';


 @WHERE_RULES = ("d.id=o.acct_id");
 
 if($attr->{LOGIN_EXPR}) {
 	 require Users;
	 push @WHERE_RULES, "d.uid='$attr->{UID}'"; 
  }

 if($attr->{CUSTOMER}) {
   $attr->{CUSTOMER} =~ s/\*/\%/ig;
	 push @WHERE_RULES, "d.customer LIKE '$attr->{CUSTOMER}'"; 
  }

 
 if ($attr->{FROM_DATE}) {
    push @WHERE_RULES, "(date_format(d.date, '%Y-%m-%d')>='$attr->{FROM_DATE}' and date_format(d.date, '%Y-%m-%d')<='$attr->{TO_DATE}')";
  }

 if ($attr->{DOC_ID}) {
 	  my $value = $self->search_expr($attr->{DOC_ID}, 'INT');
    push @WHERE_RULES, "d.acct_id$value";
  }

 if ($attr->{SUM}) {
 	  my $value = $self->search_expr($attr->{SUM}, 'INT');
    push @WHERE_RULES, "o.price * o.counts$value";
  }

 # Show groups
 if ($attr->{GIDS}) {
   push @WHERE_RULES, "u.gid IN ($attr->{GIDS})"; 
  }
 elsif ($attr->{GID}) {
   push @WHERE_RULES, "u.gid='$attr->{GID}'"; 
  }

 
 #DIsable
 if ($attr->{UID}) {
   push @WHERE_RULES, "d.uid='$attr->{UID}'"; 
 }
 

 $WHERE = ($#WHERE_RULES > -1) ? 'WHERE ' . join(' and ', @WHERE_RULES)  : '';


  $self->query($db,   "SELECT d.acct_id, d.date, d.customer,  sum(o.price * o.counts), u.id, a.name, d.created, d.uid, d.id
    FROM (docs_acct d, docs_acct_orders o)
    LEFT JOIN users u ON (d.uid=u.uid)
    LEFT JOIN admins a ON (d.aid=a.aid)
    $WHERE
    GROUP BY d.acct_id 
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;");


 return $self->{list}  if ($self->{TOTAL} < 1);
 my $list = $self->{list};


 $self->query($db, "SELECT count(*)
    FROM (docs_acct d, docs_acct_orders o)    
    LEFT JOIN users u ON (d.uid=u.uid)
    $WHERE");

 ($self->{TOTAL}) = @{ $self->{list}->[0] };

	return $list;
}

#**********************************************************
# accounts_list
#**********************************************************
sub docs_nextid {
  my $self = shift;
  my ($attr) = @_;

  my $sql = '';

  if ($attr->{TYPE} eq 'ACCOUNT') {
    $sql = "SELECT max(d.acct_id), count(*) FROM docs_acct d
     WHERE YEAR(date)=YEAR(curdate());";
   }
  elsif($attr->{TYPE} eq 'INVOICE') {
    $sql = "SELECT max(d.invoice_id), count(*) FROM docs_invoice d
     WHERE YEAR(date)=YEAR(curdate());";
   }

  $self->query($db,   "$sql");

  ($self->{NEXT_ID},
   $self->{TOTAL}) = @{ $self->{list}->[0] };
 

 
  $self->{NEXT_ID}++;
	return $self->{NEXT_ID};
}


#**********************************************************
# Bill
#**********************************************************
sub account_add {
	my $self = shift;
	my ($attr) = @_;
  
 
  %DATA = $self->get_data($attr, { default => \%DATA }); 
  $DATA{DATE}    = ($attr->{DATE})    ? "'$attr->{DATE}'" : 'now()';
  $DATA{ACCT_ID} = ($attr->{ACCT_ID}) ? $attr->{ACCT_ID}  : $self->docs_nextid({ TYPE => 'ACCOUNT' });

  

  $self->query($db, "insert into docs_acct (acct_id, date, created, customer, phone, aid, uid)
      values ('$DATA{ACCT_ID}', $DATA{DATE}, now(), \"$DATA{CUSTOMER}\", \"$DATA{PHONE}\", 
      \"$admin->{AID}\", \"$DATA{UID}\");", 'do');
 
  return $self if($self->{errno});
  $self->{DOC_ID}=$self->{INSERT_ID};

  $self->query($db, "INSERT INTO docs_acct_orders (acct_id, orders, counts, unit, price)
      values ($self->{DOC_ID}, \"$DATA{ORDERS}\", '$DATA{COUNTS}', '$DATA{UNIT}',
 '$DATA{SUM}')", 'do');

  return $self if($self->{errno});
  
  $self->{ACCT_ID}=$DATA{ACCT_ID};
  $self->account_info($self->{DOC_ID});

  #push @{$self->{ORDERS}}, "$DATA{ACCT_ID}|$DATA{COUNTS}|$DATA{UNIT}|$DATA{SUM}";
  

	return $self;
}


#**********************************************************
# Bill
#**********************************************************
sub account_del {
	my $self = shift;
	my ($id, $attr) = @_;

  if ($id == 0 && $attr->{UID}) {
    #$self->query($db, "DELETE FROM docs_acct_orders WHERE acct_id='$id'", 'do');
    #$self->query($db, "DELETE FROM docs_acct WHERE uid='$id'", 'do');
   }
  else {
    $self->query($db, "DELETE FROM docs_acct_orders WHERE acct_id='$id'", 'do');
    $self->query($db, "DELETE FROM docs_acct WHERE id='$id'", 'do');
   }

	return $self;
}

#**********************************************************
# Bill
#**********************************************************
sub account_info {
	my $self = shift;
	my ($id, $attr) = @_;

  $WHERE = ($attr->{UID}) ? "and d.uid='$attr->{UID}'" : '';  
  

  $self->query($db, "SELECT d.acct_id, 
   d.date, 
   d.customer,  
   sum(o.price * o.counts), 
   d.phone,
   if(d.vat>0, FORMAT(sum(o.price * o.counts) / ((100+d.vat)/ d.vat), 2), FORMAT(0, 2)),
   u.id, 
   a.name, 
   d.created, 
   d.uid, 
   d.id,
   pi.fio,
   pi.address_street,
   pi.address_build,
   pi.address_flat,
   pi.phone,
   pi.contract_id,
   d.date + interval $CONF->{DOCS_ACCOUNT_EXPIRE_PERIOD} day
   
    FROM (docs_acct d, docs_acct_orders o)
    LEFT JOIN users u ON (d.uid=u.uid)
    LEFT JOIN users_pi pi ON (pi.uid=u.uid)
    LEFT JOIN admins a ON (d.aid=a.aid)
    WHERE d.id=o.acct_id and d.id='$id' $WHERE
    GROUP BY d.id;");

  if ($self->{TOTAL} < 1) {
     $self->{errno} = 2;
     $self->{errstr} = 'ERROR_NOT_EXIST';
     return $self;
   }
  ($self->{ACCT_ID}, 
   $self->{DATE}, 
   $self->{CUSTOMER}, 
   $self->{SUM},
   $self->{PHONE},
   $self->{VAT},
   $self->{LOGIN}, 
   $self->{ADMIN}, 
   $self->{CREATED}, 
   $self->{UID},
   $self->{DOC_ID},
   $self->{FIO},

   $self->{ADDRESS_STREET}, 
   $self->{ADDRESS_BUILD}, 
   $self->{ADDRESS_FLAT}, 
   $self->{PHONE},
   $self->{CONTRACT_ID},
   $self->{EXPIRE_DATE}
  )= @{ $self->{list}->[0] };
	
  
  if ($self->{TOTAL} > 0) {
    $self->{NUMBER}=$self->{ACCT_ID};
 
    $self->query($db, "SELECT acct_id, orders, counts, unit, price
     FROM docs_acct_orders WHERE acct_id='$id'");
  
    $self->{ORDERS}=$self->{list};
   }

	return $self;
}


#**********************************************************
# change()
#**********************************************************
sub account_change {
  my $self = shift;
  my ($attr) = @_;
  
  my %FIELDS = (ACCT_ID     => 'acct_id',
                DATE        => 'date',
                CUSTOMER    => 'customer',
                SUM         => 'sum',
                ID          => 'id',
                UID         => 'uid'
             );


  $self->changes($admin,  { CHANGE_PARAM => 'ID',
                   TABLE        => 'docs_acct',
                   FIELDS       => \%FIELDS,
                   OLD_INFO     => $self->account_info($attr->{DOC_ID}),
                   DATA         => $attr
                  } );

  return $self->{result};
}









1

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
	 push @WHERE_RULES, @{ $self->search_expr($attr->{LOGIN_EXPR}, 'STR', 'u.id') };
  }
 elsif($attr->{CUSTOMER}) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{CUSTOMER}, 'STR', 'd.customer') };
  }
 
 if($attr->{AID}) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{AID}, 'STR', 'a.id') };
  }
 
 if ($attr->{FROM_DATE}) {
    push @WHERE_RULES, "(date_format(d.date, '%Y-%m-%d')>='$attr->{FROM_DATE}' and date_format(d.date, '%Y-%m-%d')<='$attr->{TO_DATE}')";
  }

 if ($attr->{DOC_ID}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{DOC_ID}, 'INT', 'd.acct_id') };
  }

 if ($attr->{SUM}) {
 	  push @WHERE_RULES, @{ $self->search_expr($attr->{SUM}, 'INT', 'o.price * o.counts') };
  }

 # Show groups
 if ($attr->{GIDS}) {
   push @WHERE_RULES, "u.gid IN ($attr->{GIDS})"; 
  }
 elsif ($attr->{GID}) {
   push @WHERE_RULES, "u.gid='$attr->{GID}'"; 
  }

 if (defined($attr->{PAYMENT_METHOD}) && $attr->{PAYMENT_METHOD} ne '') {
    push @WHERE_RULES, @{ $self->search_expr($attr->{PAYMENT_METHOD}, 'INT', 'p.method') };
  }
 
 #DIsable
 if ($attr->{UID}) {
   push @WHERE_RULES, "d.uid='$attr->{UID}'"; 
 }

 if ($attr->{FULL_INFO}) {
   $self->{EXT_FIELDS}=",
 	 pi.address_street,
   pi.address_build,
   pi.address_flat,
   if (d.phone<>0, d.phone, pi.phone),
   pi.contract_date,
   u.id";
  }


 $WHERE = ($#WHERE_RULES > -1) ? 'WHERE ' . join(' and ', @WHERE_RULES)  : '';


  $self->query($db,   "SELECT d.invoice_id, d.date, if(d.customer='-' or d.customer='', pi.fio, d.customer), sum(o.price * o.counts), u.id, a.name, d.created, p.method, d.uid, d.id $self->{EXT_FIELDS}
    FROM (docs_invoice d, docs_invoice_orders o)
    LEFT JOIN users u ON (d.uid=u.uid)
    LEFT JOIN admins a ON (d.aid=a.aid)
    LEFT JOIN users_pi pi ON (pi.uid=u.uid)
    LEFT JOIN payments p ON (d.payment_id=p.id)
    $WHERE
    GROUP BY d.id 
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;");


 return $self->{list}  if ($self->{TOTAL} < 1);
 my $list = $self->{list};

 $self->query($db, "SELECT count(*)
    FROM (docs_invoice d, docs_invoice_orders o)
    LEFT JOIN users u ON (d.uid=u.uid)
    LEFT JOIN admins a ON (d.aid=a.aid)
    LEFT JOIN payments p ON (d.payment_id=p.id)
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
  
  print "Content-Type: text/html\n\n";
  $self->{debug}=1;
  
  
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
   d.id,
   d.uid,
   d.date + interval $CONF->{DOCS_ACCOUNT_EXPIRE_PERIOD} day,
   d.payment_id
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
   $self->{TOTAL_SUM},
   $self->{PHONE},
   $self->{VAT},
   $self->{ADMIN},
   $self->{LOGIN},
   $self->{CREATED},
   $self->{BY_PROXY_SERIA},
   $self->{BY_PROXY_PERSON},
   $self->{BY_PROXY_DATE},
   $self->{DOC_ID},
   $self->{UID},
   $self->{EXPIRE_DATE},
   $self->{PAYMENT_ID}
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

  if ($attr->{ORDER}) {
    push @{ $attr->{ORDERS} }, "$attr->{ORDER}|0|1|$attr->{SUM}";
   }

  if (! defined($attr->{ORDERS}) || $#{ $attr->{ORDERS} } < 0) {
  	$self->{errno}=1;
  	$self->{errstr}="No orders";
  	return $self;
  }

  $DATA{DATE}       = ($attr->{DATE})    ? "'$attr->{DATE}'" : 'now()';
  $DATA{INVOICE_ID} = ($attr->{INVOICE_ID}) ? $attr->{INVOICE_ID}  : $self->docs_nextid({ TYPE => 'INVOICE' });

  $self->query($db, "insert into docs_invoice (invoice_id, date, created, customer, phone, aid, uid,
    by_proxy_seria,
    by_proxy_person,
    by_proxy_date,
    payment_id)
      values ('$DATA{INVOICE_ID}', $DATA{DATE}, now(), \"$DATA{CUSTOMER}\", \"$DATA{PHONE}\", 
      \"$admin->{AID}\", \"$DATA{UID}\",
      '$DATA{BY_PROXY_SERIA}',
      '$DATA{BY_PROXY_PERSON}',
      '$DATA{BY_PROXY_DATE}',
      '$DATA{PAYMENT_ID}');", 'do');
 
  return $self if($self->{errno});
  $self->{DOC_ID}=$self->{INSERT_ID};
  
  
  
  foreach my $line (@{ $attr->{ORDERS} }) {
    my ($order, $unit, $count,  $sum)=split(/\|/, $line, 4);
    $self->query($db, "INSERT INTO docs_invoice_orders (invoice_id, orders, counts, unit, price)
      values ($self->{DOC_ID}, \"$order\", '$count', '$unit', '$sum')", 'do');
  }

  return $self if($self->{errno});
  
  $self->{INVOICE_ID}=$DATA{INVOICE_ID};
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
 $PG   = ($attr->{PG}) ? $attr->{PG} : 0;
 $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;


 @WHERE_RULES = ("d.id=o.acct_id");

 if($attr->{CUSTOMER}) {
   $attr->{CUSTOMER} =~ s/\*/\%/ig;
	 push @WHERE_RULES, "d.customer LIKE '$attr->{CUSTOMER}'"; 
  }
 elsif($attr->{LOGIN_EXPR}) {
   $attr->{LOGIN_EXPR} =~ s/\*/\%/ig;
	 push @WHERE_RULES, "u.id LIKE '$attr->{LOGIN_EXPR}'"; 
  }
 
 if ($attr->{FROM_DATE}) {
    push @WHERE_RULES, "(date_format(d.date, '%Y-%m-%d')>='$attr->{FROM_DATE}' and date_format(d.date, '%Y-%m-%d')<='$attr->{TO_DATE}')";
  }

 if (defined($attr->{PAYMENT_ID})) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{PAYMENT_ID}, 'INT', 'd.payment_id') };
  }

 if (defined($attr->{PAYMENT_METHOD}) && $attr->{PAYMENT_METHOD} ne '') {
    push @WHERE_RULES, @{ $self->search_expr($attr->{PAYMENT_METHOD}, 'INT', 'p.method') };
  }

 if ($attr->{DOC_ID}) {
 	  my $value = $self->search_expr($attr->{DOC_ID}, 'INT');
    push @WHERE_RULES, "d.acct_id$value";
  }

 if ($attr->{SUM}) {
 	  my $value = $self->search_expr($attr->{SUM}, 'INT');
    push @WHERE_RULES, "o.price * o.counts$value";
  }

 if($attr->{AID}) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{AID}, 'STR', 'a.id') };
  }

 # Show groups
 if ($attr->{GIDS}) {
   push @WHERE_RULES, "u.gid IN ($attr->{GIDS})"; 
  }
 elsif ($attr->{GID}) {
   push @WHERE_RULES, "u.gid='$attr->{GID}'"; 
  }

 if ($attr->{PAID_STATUS}) {
   push @WHERE_RULES, "d.payment_id". ( ($attr->{PAID_STATUS} == 1) ? '>\'0' : '=\'0' ) ."'"; 
  }   

 #DIsable
 if ($attr->{UID}) {
   push @WHERE_RULES, "d.uid='$attr->{UID}'"; 
 }
 
 if ($attr->{FULL_INFO}) {
   $self->{EXT_FIELDS}=",
 	 pi.address_street,
   pi.address_build,
   pi.address_flat,
   if (d.phone<>0, d.phone, pi.phone),
   pi.contract_id,
   pi.contract_date,
   if(u.company_id > 0, c.bill_id, u.bill_id)";
  }

 $WHERE = ($#WHERE_RULES > -1) ? 'WHERE ' . join(' and ', @WHERE_RULES)  : '';

 $self->query($db,   "SELECT d.acct_id, d.date, if(d.customer='-' or d.customer='', pi.fio, d.customer),  sum(o.price * o.counts), d.payment_id, u.id, a.name, d.created, p.method, d.uid, d.id $self->{EXT_FIELDS}
    FROM (docs_acct d, docs_acct_orders o)
    LEFT JOIN users u ON (d.uid=u.uid)
    LEFT JOIN admins a ON (d.aid=a.aid)
    LEFT JOIN users_pi pi ON (pi.uid=u.uid)
    LEFT JOIN companies c ON (u.company_id=c.id)
    LEFT JOIN payments p ON (d.payment_id=p.id)
    $WHERE
    GROUP BY d.acct_id 
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;");


 return $self->{list}  if ($self->{TOTAL} < 1);
 my $list = $self->{list};


 $self->query($db, "SELECT count(*)
    FROM (docs_acct d, docs_acct_orders o)    
    LEFT JOIN users u ON (d.uid=u.uid)
    LEFT JOIN admins a ON (d.aid=a.aid)
    LEFT JOIN payments p ON (d.payment_id=p.id)
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
  elsif($attr->{TYPE} eq 'TAX_INVOICE') {
    $sql = "SELECT max(d.tax_invoice_id), count(*) FROM docs_tax_invoices d
     WHERE YEAR(date)=YEAR(curdate());";
   }
  elsif($attr->{TYPE} eq 'ACT') {
    $sql = "SELECT max(d.act_id), count(*) FROM docs_acts d
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

  if ($attr->{IDS}) {
  	my @ids_arr = split(/, /, $attr->{IDS});

  	foreach my $id (@ids_arr) {
      $DATA{'COUNTS_'.$id} = 1 if (! $DATA{'COUNTS_'.$id});
      $self->query($db, "INSERT INTO docs_acct_orders (acct_id, orders, counts, unit, price)
         values (". $self->{'DOC_ID'}.", \"". $DATA{'ORDER_'. $id}."\", '". $DATA{'COUNTS_'.$id}."', '". $DATA{'UNIT_'.$id} ."',
       '". $DATA{'SUM_'.$id}."')", 'do');
  	 }
   }
  else {
    $DATA{COUNTS} = 1 if (! $DATA{COUNTS});
    $self->query($db, "INSERT INTO docs_acct_orders (acct_id, orders, counts, unit, price)
       values ($self->{DOC_ID}, \"$DATA{ORDER}\", '$DATA{COUNTS}', '$DATA{UNIT}',
    '$DATA{SUM}')", 'do');
   } 

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
   if (d.phone<>0, d.phone, pi.phone),
   pi.contract_id,
   pi.contract_date,
   d.date + interval $CONF->{DOCS_ACCOUNT_EXPIRE_PERIOD} day,
   u.company_id,
   c.name
   
   
    FROM (docs_acct d, docs_acct_orders o)
    LEFT JOIN users u ON (d.uid=u.uid)
    LEFT JOIN companies c ON (u.company_id=c.id)
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
   $self->{TOTAL_SUM},
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
   $self->{CONTRACT_DATE},
   $self->{EXPIRE_DATE},
   $self->{COMPANY_ID},
   $self->{COMPANY_NAME}
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
                UID         => 'uid',
                PAYMENT_ID  => 'payment_id'
             );

  my $old_info =   $self->account_info($attr->{ID});

  $self->changes($admin,  { CHANGE_PARAM => 'ID',
                   TABLE        => 'docs_acct',
                   FIELDS       => \%FIELDS,
                   OLD_INFO     => $old_info,
                   DATA         => $attr
                  } );


  return $self;
}



#**********************************************************
# Del documents
#**********************************************************
sub del {
 my $self = shift;

}


#**********************************************************
# accounts_list
#**********************************************************
sub tax_invoice_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  @WHERE_RULES = ();
 
 if($attr->{LOGIN_EXPR}) {
 	 require Users;
	 push @WHERE_RULES, @{ $self->search_expr($attr->{UID}, 'INT', 'd.uid') };
  }

 if ($attr->{FROM_DATE}) {
    push @WHERE_RULES, "(date_format(d.date, '%Y-%m-%d')>='$attr->{FROM_DATE}' and date_format(d.date, '%Y-%m-%d')<='$attr->{TO_DATE}')";
  }

 if ($attr->{DOC_ID}) {
    push @WHERE_RULES, $self->search_expr($attr->{DOC_ID}, 'INT', 'd.tax_invoice_id');
  }

 if ($attr->{SUM}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{SUM}, 'INT', 'o.price * o.counts') };
  }

 # Show groups
 if ($attr->{GIDS}) {
   push @WHERE_RULES, "u.gid IN ($attr->{GIDS})"; 
  }
 elsif ($attr->{GID}) {
   push @WHERE_RULES, "u.gid='$attr->{GID}'"; 
  }

 
 if ($attr->{COMPANY_ID}) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{COMPANY_ID}, 'INT', 'd.company_id') };
 }
 if ($attr->{UID}) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{UID}, 'INT', 'd.uid') };
 }

 my $EXT_TABLES = '';
 if ($attr->{FULL_INFO}) {
   $EXT_TABLES = "LEFT JOIN users u ON (d.uid=u.uid)
      LEFT JOIN users_pi pi ON (pi.uid=u.uid)";

   $self->{EXT_FIELDS}=",
   if(d.vat>0, FORMAT(sum(o.price * o.counts) / ((100+d.vat)/ d.vat), 2), FORMAT(0, 2)),
   pi.fio,
   pi.address_street,
   pi.address_build,
   pi.address_flat,
   pi.phone,
   c.contract_id,
   c.contract_date,
   d.company_id,
   d.date + interval $CONF->{DOCS_ACCOUNT_EXPIRE_PERIOD} day";
  } 

 $WHERE = ($#WHERE_RULES > -1) ? 'WHERE ' . join(' and ', @WHERE_RULES)  : '';






  $self->query($db,   "SELECT d.tax_invoice_id, d.date, c.name, sum(o.price * o.counts), a.name, d.created, d.uid, d.company_id, d.id $self->{EXT_FIELDS}
    FROM (docs_tax_invoices d)
    LEFT JOIN docs_tax_invoice_orders o ON (d.id=o.tax_invoice_id)
    LEFT JOIN companies c ON (d.company_id=c.id)
    LEFT JOIN admins a ON (d.aid=a.aid)
    $EXT_TABLES
    $WHERE
    GROUP BY d.tax_invoice_id 
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;");


 $self->{SUM}=0.00;
 return $self->{list}  if ($self->{TOTAL} < 1);
 my $list = $self->{list};


 $self->query($db, "SELECT count(DISTINCT d.tax_invoice_id), sum(o.price*o.counts)
    FROM (docs_tax_invoices d)
    LEFT JOIN docs_tax_invoice_orders o ON (d.id=o.tax_invoice_id)
    LEFT JOIN companies c ON (d.company_id=c.id)
    $WHERE");

 ($self->{TOTAL}, $self->{SUM}) = @{ $self->{list}->[0] };

	return $list;
}


#**********************************************************
# tax_invoice_reports
#**********************************************************
sub tax_invoice_reports {
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  $PG   = ($attr->{PG}) ? $attr->{PG} : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;


 @WHERE_RULES = ();
 
 if($attr->{LOGIN_EXPR}) {
 	 require Users;
	 push @WHERE_RULES, @{ $self->search_expr($attr->{UID}, 'INT', 'd.uid') };
  }

 if ($attr->{FROM_DATE}) {
    push @WHERE_RULES, "(date_format(d.date, '%Y-%m-%d')>='$attr->{FROM_DATE}' and date_format(d.date, '%Y-%m-%d')<='$attr->{TO_DATE}')";
  }
 elsif ($attr->{MONTH}) {
    push @WHERE_RULES, "(date_format(d.date, '%Y-%m')='$attr->{MONTH}')";
  }


 if ($attr->{DOC_ID}) {
    push @WHERE_RULES, $self->search_expr($attr->{DOC_ID}, 'INT', 'd.tax_invoice_id');
  }

 if ($attr->{SUM}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{SUM}, 'INT', 'o.price * o.counts') };
  }

 # Show groups
 if ($attr->{GIDS}) {
   push @WHERE_RULES, "u.gid IN ($attr->{GIDS})"; 
  }
 elsif ($attr->{GID}) {
   push @WHERE_RULES, "u.gid='$attr->{GID}'"; 
  }

 
 if ($attr->{COMPANY_ID}) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{COMPANY_ID}, 'INT', 'd.company_id') };
 }
 if ($attr->{UID}) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{UID}, 'INT', 'd.uid') };
 }
 

 $WHERE = ($#WHERE_RULES > -1) ? 'AND ' . join(' and ', @WHERE_RULES)  : '';


  $self->query($db,   "SELECT 0, DATE_FORMAT(d.date, '%d%m%Y'), d.invoice_id, pi.fio,
    pi._inn, 
    ROUND(sum(inv_orders.price*counts), 2), 
    ROUND(sum(inv_orders.price*counts) - sum(inv_orders.price*counts) /6, 2),  
    ROUND(sum(inv_orders.price*counts) / 6, 2), 
    '-',  'X', '-', 'X', '-', 'X'

FROM (users u, docs_invoice d)
LEFT JOIN users_pi pi ON (d.uid=pi.uid)
LEFT JOIN docs_invoice_orders inv_orders ON (inv_orders.invoice_id=d.id)
WHERE u.uid=d.uid $WHERE
GROUP BY d.id
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;");


 $self->{SUM}=0.00;
 return $self->{list}  if ($self->{TOTAL} < 1);
 my $list = $self->{list};

#
# $self->query($db, "SELECT count(DISTINCT d.tax_invoice_id), sum(o.price*o.counts)
#    FROM (docs_tax_invoices d)
#    LEFT JOIN docs_tax_invoice_orders o ON (d.id=o.tax_invoice_id)
#    LEFT JOIN companies c ON (d.company_id=c.id)
#    $WHERE");
#
# ($self->{TOTAL}, $self->{SUM}) = @{ $self->{list}->[0] };

	return $list;
}







#**********************************************************
# Bill
#**********************************************************
sub tax_invoice_add {
	my $self = shift;
	my ($attr) = @_;
  
 
  %DATA = $self->get_data($attr, { default => \%DATA }); 
  $DATA{DATE}   = ($attr->{DATE})    ? "'$attr->{DATE}'" : 'now()';
  $DATA{DOC_ID} = ($attr->{DOC_ID}) ? $attr->{DOC_ID}  : $self->docs_nextid({ TYPE => 'TAX_INVOICE' });

  $self->query($db, "insert into docs_tax_invoices (tax_invoice_id, date, created, aid, uid, company_id)
      values ('$DATA{DOC_ID}', $DATA{DATE}, now(), \"$admin->{AID}\", \"$DATA{UID}\", '$DATA{COMPANY_ID}');", 'do');
 
  return $self if($self->{errno});
  $self->{DOC_ID}=$self->{INSERT_ID};

  if (! $attr->{IDS}) {
  	
   }

  if ($attr->{IDS}) {
  	my @ids_arr = split(/, /, $attr->{IDS});

  	foreach my $id (@ids_arr) {
      $DATA{'COUNTS_'.$id} = 1 if (! $DATA{'COUNTS_'.$id});
      $self->query($db, "INSERT INTO docs_tax_invoice_orders (tax_invoice_id, orders, counts, unit, price)
         values (". $self->{'DOC_ID'}.", \"". $DATA{'ORDER_'. $id}."\", '". $DATA{'COUNTS_'.$id}."', '". $DATA{'UNIT_'.$id} ."',
       '". $DATA{'SUM_'.$id}."')", 'do');
  	 }
   }

  return $self if($self->{errno});
  
  $self->tax_invoice_info($self->{DOC_ID});

	return $self;
}


#**********************************************************
# Bill
#**********************************************************
sub tax_invoice_del {
	my $self = shift;
	my ($id, $attr) = @_;

  if ($id == 0 && $attr->{UID}) {
    #$self->query($db, "DELETE FROM docs_acct_orders WHERE acct_id='$id'", 'do');
    #$self->query($db, "DELETE FROM docs_acct WHERE uid='$id'", 'do');
   }
  else {
    $self->query($db, "DELETE FROM docs_tax_invoice_orders WHERE tax_invoice_id='$id'", 'do');
    $self->query($db, "DELETE FROM docs_tax_invoices WHERE id='$id'", 'do');
   }

	return $self;
}

#**********************************************************
# Bill
#**********************************************************
sub tax_invoice_info {
	my $self = shift;
	my ($id, $attr) = @_;

  $WHERE = ($attr->{UID}) ? "and d.uid='$attr->{UID}'" : '';  
  

  $self->query($db, "SELECT d.tax_invoice_id, 
   d.date, 
   sum(o.price * o.counts), 
   if(d.vat>0, FORMAT(sum(o.price * o.counts) / ((100+d.vat)/ d.vat), 2), FORMAT(0, 2)),
   u.id, 
   c.name, 
   d.created, 
   d.uid, 
   d.id,
   pi.fio,
   pi.address_street,
   pi.address_build,
   pi.address_flat,
   pi.phone,
   c.contract_id,
   c.contract_date,
   d.company_id,
   d.date + interval $CONF->{DOCS_ACCOUNT_EXPIRE_PERIOD} day
   
    FROM (docs_tax_invoices d, docs_tax_invoice_orders o)
    LEFT JOIN users u ON (d.uid=u.uid)
    LEFT JOIN users_pi pi ON (pi.uid=u.uid)
    LEFT JOIN companies c ON (c.id=d.company_id)
    LEFT JOIN admins a ON (d.aid=a.aid)
    WHERE d.id=o.tax_invoice_id and d.id='$id' $WHERE
    GROUP BY d.id;");

  if ($self->{TOTAL} < 1) {
     $self->{errno}  = 2;
     $self->{errstr} = 'ERROR_NOT_EXIST';
     return $self;
   }

  ($self->{TAX_INVOICE_ID}, 
   $self->{DATE}, 
   $self->{TOTAL_SUM},
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
   $self->{CONTRACT_DATE},
   $self->{COMPANY_NAMA},
   $self->{EXPIRE_DATE}
  )= @{ $self->{list}->[0] };
	
  
  if ($self->{TOTAL} > 0) {
    $self->{NUMBER}=$self->{ACCT_ID};
 
    $self->query($db, "SELECT tax_invoice_id, orders, counts, unit, price
     FROM docs_tax_invoice_orders WHERE tax_invoice_id='$id'");
  
    $self->{ORDERS}=$self->{list};
   }

	return $self;
}


#**********************************************************
# change()
#**********************************************************
sub tax_invoice_change {
  my $self = shift;
  my ($attr) = @_;
  
  
  my %FIELDS = (DOC_ID      => 'doc_id',
                COMPANY_ID  => 'company_id',
                DATE        => 'date',
                SUM         => 'sum',
                ID          => 'id',
                UID         => 'uid'
             );


  $self->changes($admin,  { CHANGE_PARAM => 'ID',
                   TABLE        => 'docs_tax_invoices',
                   FIELDS       => \%FIELDS,
                   OLD_INFO     => $self->tax_invoice_info($attr->{DOC_ID}),
                   DATA         => $attr
                  } );

  return $self->{result};
}


#**********************************************************
# accounts_list
#**********************************************************
sub acts_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';


 @WHERE_RULES = ();
 
 if($attr->{LOGIN_EXPR}) {
 	 require Users;
	 push @WHERE_RULES, @{ $self->search_expr($attr->{UID}, 'INT', 'd.uid') };
  }

 if ($attr->{FROM_DATE}) {
    push @WHERE_RULES, "(date_format(d.date, '%Y-%m-%d')>='$attr->{FROM_DATE}' and date_format(d.date, '%Y-%m-%d')<='$attr->{TO_DATE}')";
  }

 if ($attr->{DOC_ID}) {
    push @WHERE_RULES, $self->search_expr($attr->{DOC_ID}, 'INT', 'd.act_id');
  }

 if ($attr->{SUM}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{SUM}, 'INT', 'd.sum') };
  }

 # Show groups
 if ($attr->{GIDS}) {
   push @WHERE_RULES, "u.gid IN ($attr->{GIDS})"; 
  }
 elsif ($attr->{GID}) {
   push @WHERE_RULES, "u.gid='$attr->{GID}'"; 
  }

 
 if ($attr->{COMPANY_ID}) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{COMPANY_ID}, 'INT', 'd.company_id') };
 }
 if ($attr->{UID}) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{UID}, 'INT', 'd.uid') };
 }
 

 $WHERE = ($#WHERE_RULES > -1) ? 'WHERE ' . join(' and ', @WHERE_RULES)  : '';


  $self->query($db,   "SELECT d.act_id, d.date, c.name, d.sum, a.name, d.created, d.uid, d.company_id, d.id
    FROM (docs_acts d)
    LEFT JOIN companies c ON (d.company_id=c.id)
    LEFT JOIN admins a ON (d.aid=a.aid)
    $WHERE
    GROUP BY d.act_id 
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;");


 $self->{SUM}=0.00;
 return $self->{list}  if ($self->{TOTAL} < 1);
 my $list = $self->{list};


 $self->query($db, "SELECT count(DISTINCT d.act_id), sum(d.sum)
    FROM (docs_acts d)
    LEFT JOIN companies c ON (d.company_id=c.id)
    $WHERE");

 ($self->{TOTAL}, $self->{SUM}) = @{ $self->{list}->[0] };

	return $list;
}


#**********************************************************
# Bill
#**********************************************************
sub act_add {
	my $self = shift;
	my ($attr) = @_;
  
 
  %DATA = $self->get_data($attr, { default => \%DATA }); 
  $DATA{DATE}   = ($attr->{DATE})    ? "'$attr->{DATE}'" : 'now()';
  $DATA{DOC_ID} = ($attr->{DOC_ID}) ? $attr->{DOC_ID}  : $self->docs_nextid({ TYPE => 'ACT' });

  $self->query($db, "insert into docs_acts (act_id, date, created, aid, uid, company_id, sum)
      values ('$DATA{DOC_ID}', $DATA{DATE}, now(), \"$admin->{AID}\", \"$DATA{UID}\", '$DATA{COMPANY_ID}', '$DATA{SUM}');", 'do');
 
  return $self if($self->{errno});
  $self->{DOC_ID}=$self->{INSERT_ID};
 
	return $self;
}


#**********************************************************
# Bill
#**********************************************************
sub act_del {
	my $self = shift;
	my ($id, $attr) = @_;

  if ($id == 0 && $attr->{UID}) {
    #$self->query($db, "DELETE FROM docs_acct_orders WHERE acct_id='$id'", 'do');
    #$self->query($db, "DELETE FROM docs_acct WHERE uid='$id'", 'do');
   }
  else {
    $self->query($db, "DELETE FROM docs_acts WHERE id='$id'", 'do');
   }

	return $self;
}

#**********************************************************
# Bill
#**********************************************************
sub act_info {
	my $self = shift;
	my ($id, $attr) = @_;

  $WHERE = ($attr->{UID}) ? "and d.uid='$attr->{UID}'" : '';  
  

  $self->query($db, "SELECT d.act_id, 
   d.date, 
   date_format(d.date, '%Y-%m'),
   d.sum, 
   if(d.vat>0, FORMAT(d.sum / ((100+d.vat)/ d.vat), 2), FORMAT(0, 2)),
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
   c.contract_id,
   c.contract_date,
   d.company_id,
   c.name,
   d.date + interval $CONF->{DOCS_ACCOUNT_EXPIRE_PERIOD} day
   
   
    FROM (docs_acts d)
    LEFT JOIN users u ON (d.uid=u.uid)
    LEFT JOIN users_pi pi ON (pi.uid=u.uid)
    LEFT JOIN companies c ON (c.id=d.company_id)
    LEFT JOIN admins a ON (d.aid=a.aid)
    WHERE d.id='$id' $WHERE
    GROUP BY d.id;");

  if ($self->{TOTAL} < 1) {
     $self->{errno}  = 2;
     $self->{errstr} = 'ERROR_NOT_EXIST';
     return $self;
   }

  ($self->{ACT_ID}, 
   $self->{DATE}, 
   $self->{MONTH}, 
   $self->{TOTAL_SUM},
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
   $self->{CONTRACT_DATE},
   $self->{COMPANY_ID},
   $self->{COMPANY_NAME},
   $self->{EXPIRE_DATE}

  )= @{ $self->{list}->[0] };
	
	return $self;
}


#**********************************************************
# change()
#**********************************************************
sub act_change {
  my $self = shift;
  my ($attr) = @_;
  
  
  my %FIELDS = (DOC_ID      => 'doc_id',
                COMPANY_ID  => 'company_id',
                DATE        => 'date',
                SUM         => 'sum',
                ID          => 'id',
                UID         => 'uid'
               );


  $self->changes($admin,  { CHANGE_PARAM => 'ID',
                   TABLE        => 'docs_acts',
                   FIELDS       => \%FIELDS,
                   OLD_INFO     => $self->act_info($attr->{DOC_ID}),
                   DATA         => $attr
                  } );

  return $self->{result};
}


1

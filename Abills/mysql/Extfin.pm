package Extfin;
# External finance manage functions
#

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION
);

use Exporter;
$VERSION = 2.01;
@ISA = ('Exporter');

@EXPORT = qw();

@EXPORT_OK = ();
%EXPORT_TAGS = ();

# User name expration
#my $usernameregexp = "^[a-z0-9_][a-z0-9_-]*\$"; # configurable;

use main;
@ISA  = ("main");


#**********************************************************
# Init 
#**********************************************************
sub new {
  my $class = shift;
  ($db, $admin, $CONF) = @_;
  
  $admin->{MODULE}='Extfin';
  #  $CONF->{MAX_USERNAME_LENGTH} = 10 if (! defined($CONF->{MAX_USERNAME_LENGTH}));
  #if (defined($CONF->{USERNAMEREGEXP})) {
  #	$usernameregexp=$CONF->{USERNAMEREGEXP};
  # }

  my $self = { };

  bless($self, $class);

  return $self;
}







#**********************************************************
# defauls user settings
#**********************************************************
sub defaults {
  my $self = shift;

  %DATA = ( LOGIN => '', 
   ACTIVATE       => '0000-00-00', 
   EXPIRE         => '0000-00-00', 
   CREDIT         => 0, 
   REDUCTION      => '0.00', 
   SIMULTANEONSLY => 0, 
   DISABLE        => 0, 
   COMPANY_ID     => 0,
   GID            => 0,
   DISABLE        => 0,
   PASSWORD       => '');
 
  $self = \%DATA;
  return $self;
}



#**********************************************************
# list()
#**********************************************************
sub customers_list {
 my $self = shift;
 my ($attr) = @_;
 my @list = ();

 $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
 $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
 my $PG   = ($attr->{PG}) ? $attr->{PG} : 0;
 my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 100000;

 $self->{SEARCH_FIELDS} = '';
 $self->{SEARCH_FIELDS_COUNT}=0;

 
 undef @WHERE_RULES;

 # Start letter 
 if ($attr->{FIRST_LETTER}) {
    push @WHERE_RULES, "u.id LIKE '$attr->{FIRST_LETTER}%'";
  }
 elsif ($attr->{LOGIN}) {
    push @WHERE_RULES, "u.id='$attr->{LOGIN}'";
  }
 # Login expresion
 elsif ($attr->{LOGIN_EXPR}) {
    $attr->{LOGIN_EXPR} =~ s/\*/\%/ig;
    push @WHERE_RULES, "u.id LIKE '$attr->{LOGIN_EXPR}'";
  }
 

 if ($attr->{PHONE}) {
    my $value = $self->search_expr($attr->{PHONE}, 'INT');
    push @WHERE_RULES, "pi.phone$value";
    $self->{SEARCH_FIELDS} = 'pi.phone, ';
    $self->{SEARCH_FIELDS_COUNT}++;
  }

 if ($attr->{ADDRESS_STREET}) {
    $attr->{ADDRESS_STREET} =~ s/\*/\%/ig;
    push @WHERE_RULES, "pi.address_street LIKE '$attr->{ADDRESS_STREET}' ";
    $self->{SEARCH_FIELDS} .= 'pi.address_street, ';
    $self->{SEARCH_FIELDS_COUNT}++;
  }

 if ($attr->{ADDRESS_BUILD}) {
    $attr->{ADDRESS_BUILD} =~ s/\*/\%/ig;
    push @WHERE_RULES, "pi.address_build LIKE '$attr->{ADDRESS_BUILD}'";
    $self->{SEARCH_FIELDS} .= 'pi.address_build, ';
    $self->{SEARCH_FIELDS_COUNT}++;
  }

 if ($attr->{ADDRESS_FLAT}) {
    $attr->{ADDRESS_FLAT} =~ s/\*/\%/ig;
    push @WHERE_RULES, "pi.address_flat LIKE '$attr->{ADDRESS_FLAT}'";
    $self->{SEARCH_FIELDS} .= 'pi.address_flat, ';
    $self->{SEARCH_FIELDS_COUNT}++;
  }



 if ($attr->{CONTRACT_ID}) {
    $attr->{CONTRACT_ID} =~ s/\*/\%/ig;
    push @WHERE_RULES, "pi.contract_id LIKE '$attr->{CONTRACT_ID}'";
    $self->{SEARCH_FIELDS} .= 'pi.contract_id, ';
    $self->{SEARCH_FIELDS_COUNT}++;
  }

 if ($attr->{REGISTRATION}) {
    my $value = $self->search_expr("'$attr->{REGISTRATION}'", 'INT');
    push @WHERE_RULES, "u.registration LIKE '$attr->{REGISTRATION}'";
    $self->{SEARCH_FIELDS} .= 'u.registration, ';
    $self->{SEARCH_FIELDS_COUNT}++;
  }


 if ($attr->{DEPOSIT}) {
    my $value = $self->search_expr($attr->{DEPOSIT}, 'INT');
    push @WHERE_RULES, "b.deposit$value";
  }

 if ($attr->{CREDIT}) {
    my $value = $self->search_expr($attr->{CREDIT}, 'INT');
    push @WHERE_RULES, "u.credit$value";
  }


 if ($attr->{COMMENTS}) {
  	$attr->{COMMENTS} =~ s/\*/\%/ig;
 	  push @WHERE_RULES, "pi.comments LIKE '$attr->{COMMENTS}'";
    $self->{SEARCH_FIELDS} .= 'pi.comments, ';
    $self->{SEARCH_FIELDS_COUNT}++;
  }    


 if ($attr->{FIO}) {
    $attr->{FIO} =~ s/\*/\%/ig;
    push @WHERE_RULES, "pi.fio LIKE '$attr->{FIO}'";
  }

 # Show debeters
 if ($attr->{DEBETERS}) {
    push @WHERE_RULES, "b.deposit<0";
  }

 if ($attr->{COMPANY_ID}) {
    push @WHERE_RULES, "u.company_id='$attr->{COMPANY_ID}'";
  }

 # Show groups
 if ($attr->{GIDS}) {
   push @WHERE_RULES, "u.gid IN ($attr->{GIDS})"; 
  }
 elsif ($attr->{GID}) {
   push @WHERE_RULES, "u.gid='$attr->{GID}'"; 
  }


#Activate
 if ($attr->{ACTIVATE}) {
   my $value = $self->search_expr("$attr->{ACTIVATE}", 'INT');
   push @WHERE_RULES, "(u.activate$value)"; 
   
   #push @WHERE_RULES, "(u.activate='0000-00-00' or u.activate$value)"; 
   $self->{SEARCH_FIELDS} .= 'u.activate, ';
   $self->{SEARCH_FIELDS_COUNT}++;
 }

#Expire
 if ($attr->{EXPIRE}) {
   my $value = $self->search_expr("$attr->{EXPIRE}", 'INT');
   push @WHERE_RULES, "(u.expire$value)"; 
   #push @WHERE_RULES, "(u.expire='0000-00-00' or u.expire$value)"; 
   
   $self->{SEARCH_FIELDS} .= 'u.expire, ';
   $self->{SEARCH_FIELDS_COUNT}++;
 }

#DIsable
 if ($attr->{DISABLE}) {
   push @WHERE_RULES, "u.disable='$attr->{DISABLE}'"; 
 }
 
 
 
 $WHERE = ($#WHERE_RULES > -1) ?  "WHERE " . join(' and ', @WHERE_RULES) : '';
 
#Show last paymenst
 
       # Group, Kod, Наименование, Вид контрагента, Полное наименование, Юредический адрес, Почтовый адрес, 
      # номер телефона, ИНН, основной договор, основной счёт, 


 #$PAGE_ROWS = 23000;
 
 $self->query($db, "SELECT  
                         u.uid, 
                         if(u.company_id > 0, company.name, 
                            if(pi.fio<>'', pi.fio, u.id)),
                         if(u.company_id > 0, company.name, 
                            if(pi.fio<>'', pi.fio, u.id)),
                         u.gid,
                         g.name,
                         if(company.id IS NULL, 0, 1),
                         if(u.company_id > 0, company.address, CONCAT(pi.address_street, pi.address_build, pi.address_flat)),
                         pi.phone,
                         if(u.company_id > 0, company.contract_id, pi.contract_id),
                         if(u.company_id > 0, company.bill_id, u.bill_id),
                         if(u.company_id > 0, company.bank_account, ''),
                         if(u.company_id > 0, company.bank_name, ''),
                         if(u.company_id > 0, company.cor_bank_account, '')
                       
                         
     FROM users u
     LEFT JOIN users_pi pi ON (u.uid = pi.uid)
     LEFT JOIN companies company ON  (u.company_id=company.id) 
   
     LEFT JOIN bills b ON (u.bill_id = b.id)
     LEFT JOIN bills cb ON  (company.bill_id=cb.id)
     LEFT JOIN groups g ON  (u.gid=g.gid)
     
     $WHERE
     GROUP BY 10
     ORDER BY $SORT $DESC 
     LIMIT $PG, $PAGE_ROWS;");

  return $self if($self->{errno});
  my $list = $self->{list};


  return $list;
}

#**********************************************************
#
#**********************************************************
sub payment_deed {
	my $self = shift;
	my ($attr) = @_;
 
 my %PAYMENT_DEED = ();
 my @WHERE_RULES_DV = ();
 @WHERE_RULES = ();
 my %NAMES=();

 if ($attr->{DATE_FROM}) {
 	  push @WHERE_RULES, "DATE_FORMAT(f.date, '%Y-%m-%d')>='$attr->{DATE_FROM}' AND DATE_FORMAT(f.date, '%Y-%m-%d')<='$attr->{DATE_TO}'";
 	  push @WHERE_RULES_DV, "DATE_FORMAT(dv.start, '%Y-%m-%d')>='$attr->{DATE_FROM}' AND DATE_FORMAT(dv.start, '%Y-%m-%d')<='$attr->{DATE_TO}'";
   }
 elsif ($attr->{MONTH}) {
   push @WHERE_RULES, "DATE_FORMAT(f.date, '%Y-%m')='$attr->{MONTH}'";
   push @WHERE_RULES_DV, "DATE_FORMAT(dv.start, '%Y-%m')='$attr->{MONTH}'";
  }

  # Show groups
  if ($attr->{GIDS}) {
    push @WHERE_RULES, "u.gid IN ($attr->{GIDS})"; 
    push @WHERE_RULES_DV, "u.gid IN ($attr->{GIDS})"; 
   }
  elsif ($attr->{GID}) {
    push @WHERE_RULES, "u.gid='$attr->{GID}'"; 
    push @WHERE_RULES_DV, "u.gid IN ($attr->{GIDS})"; 
   }
 
  #Don't use bonus
 
 my $WHERE = ($#WHERE_RULES > -1) ? join(' and ', @WHERE_RULES)  : '';
 my $WHERE_DV = ($#WHERE_RULES > -1) ? join(' and ', @WHERE_RULES_DV)  : '';

 my $info_fields = '';
 my $info_fields_count = 0;
 if ($attr->{INFO_FIELDS}) {
  	my @info_arr = split(/, /, $attr->{INFO_FIELDS});
    $info_fields = ', '. join(', ', @info_arr);
    $info_fields_count = $#info_arr;
  }


 #Get fees
 $self->query($db, "SELECT
  if(u.company_id > 0, company.bill_id, u.bill_id),
  sum(f.sum),
  if(u.company_id > 0, company.name, if(pi.fio<>'', pi.fio, u.id)),
  if(u.company_id > 0, company.name, if(pi.fio<>'', pi.fio, u.id)),
  if(u.company_id > 0, 1, 0),
  if(u.company_id > 0, company.vat, 0),
  u.uid,
  max(date) $info_fields
     FROM (users u, fees f)
     LEFT JOIN users_pi pi ON (u.uid = pi.uid)
     LEFT JOIN companies company ON  (u.company_id=company.id)

     WHERE u.uid=f.uid and $WHERE
     GROUP BY 1
     ORDER BY $SORT $DESC ;");

  foreach my $line (@{ $self->{list} } ) {
        next if (! $line->[0]);

  	$PAYMENT_DEED{$line->[0]}=$line->[1];
 	  #Name|Type|VAT
 	  $NAMES{$line->[0]}="$line->[2]|$line->[4]|$line->[5]";
 	  if ($info_fields_count > 0) {
 	    for (my $i=0; $i<=$info_fields_count; $i++) {
 	       $NAMES{$line->[0]}.="|". $line->[8+$i];
 	     }
 	   }
   }
 
 #Get Dv use
 $self->query($db, "SELECT
 if(u.company_id > 0, company.bill_id, u.bill_id),
 sum(dv.sum),
 if(u.company_id > 0, company.name, if(pi.fio<>'', pi.fio, u.id)),
 if(u.company_id > 0, company.name, if(pi.fio<>'', pi.fio, u.id)),
  if(u.company_id > 0, 1, 0),
  if(u.company_id > 0, company.vat, 0),
  u.uid $info_fields
     FROM (users u, dv_log dv)
     LEFT JOIN users_pi pi ON (u.uid = pi.uid)
     LEFT JOIN companies company ON  (u.company_id=company.id)
     WHERE u.uid=dv.uid and $WHERE_DV
     GROUP BY 1
     ORDER BY 2 DESC
   ;");


  foreach my $line (@{ $self->{list} } ) {
    if (! $PAYMENT_DEED{$line->[0]}) {
  	  $PAYMENT_DEED{$line->[0]}+=$line->[1];
  	  #Name|Type|VAT
  	  $NAMES{$line->[0]}="$line->[2]|$line->[4]|$line->[5]";
  	  
   	  if ($info_fields_count > 0) {
  	    for (my $i=0; $i<=$info_fields_count; $i++) {
  	       $NAMES{$line->[0]}.="|". $line->[8+$i];
 	      }
 	     }
  	 }
    else {
    	$PAYMENT_DEED{$line->[0]}+=$line->[1];
     }
   }
  
#  #Ipn
#  $self->query($db, "SELECT
# if(u.company_id > 0, company.bill_id, u.bill_id),
# sum(dv.sum),
# if(u.company_id > 0, company.name, if(pi.fio<>'', pi.fio, u.id)),
# if(u.company_id > 0, company.name, if(pi.fio<>'', pi.fio, u.id)),
#  if(u.company_id > 0, 1, 0),
#  if(u.company_id > 0, company.vat, 0),
#  u.uid $info_fields
#     FROM (users u, ipn_log dv)
#     LEFT JOIN users_pi pi ON (u.uid = pi.uid)
#     LEFT JOIN companies company ON  (u.company_id=company.id)
#     WHERE u.uid=dv.uid and $WHERE_DV
#     GROUP BY 1
#     ORDER BY 2 DESC
#   ;");
#
#
#  foreach my $line (@{ $self->{list} } ) {
#    if (! $PAYMENT_DEED{$line->[0]}) {
#  	  $PAYMENT_DEED{$line->[0]}+=$line->[1];
#  	  #Name|Type|VAT
#  	  $NAMES{$line->[0]}="$line->[2]|$line->[4]|$line->[5]";
#  	  
#   	  if ($info_fields_count > 0) {
#  	    for (my $i=0; $i<=$info_fields_count; $i++) {
#  	       $NAMES{$line->[0]}.="|". $line->[8+$i];
# 	      }
# 	     }
#  	 }
#    else {
#    	$PAYMENT_DEED{$line->[0]}+=$line->[1];
#     }
#   }
#  

  $self->{PAYMENT_DEED}=\%PAYMENT_DEED;
  $self->{NAMES}=\%NAMES;

	return $self;
}



#**********************************************************
# make
#**********************************************************
sub summary_add {
  my $self = shift;
  my ($attr) = @_;

  my %DATA = $self->get_data($attr); 

  $self->query($db, "INSERT INTO extfin_reports (period, bill_id, sum, date, aid)
  VALUES ('$DATA{PERIOD}', '$DATA{BILL_ID}', '$DATA{SUM}', '$DATA{DATE}', '$admin->{AID}');", 'do');

  return $self;
}


#**********************************************************
# del
#**********************************************************
sub summary_del {
  my $self = shift;
  my ($attr) = @_;
 
  $self->query($db, "DELTE FROM extfin_reports WHERE id='$attr->{ID}';", 'do');
 
  return $self;
}


#**********************************************************
# Show full reports
#**********************************************************
sub extfin_report_deeds {
  my $self = shift;
  my ($attr) = @_;

 print "Content-Type: text/html\n\n";
 #print "aaaaaaaaaaaaaa";

 @WHERE_RULES = ();
 my %NAMES=();

 if ($attr->{MONTH}) {
   push @WHERE_RULES, "report.period='$attr->{MONTH}'";
  }
 elsif ($attr->{DATE_FROM}) {
 	 push @WHERE_RULES, "report.period>='$attr->{DATE_FROM}' AND report.period<='$attr->{DATE_TO}'";
  }

 if ($attr->{GID}) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{GID}, 'INT', 'u.gid') }; 
  }




 my $WHERE = ($#WHERE_RULES > -1) ? join(' and ', @WHERE_RULES)  : '';

 $self->query($db, "SELECT report.id,
   report.period,
   report.bill_id,
   IF(company.name is not null, company.name,
    IF(pi.fio<>'', pi.fio, u.id)),
   IF(company.name is not null, 1, 0),
   report.sum,
   IF(company.name is not null, company.vat, 0),
   report.date,
   report.aid, 
   u.uid
  FROM extfin_reports report
  INNER JOIN bills b ON (report.bill_id = b.id)
  LEFT JOIN users u ON (b.id = u.bill_id)
  LEFT JOIN users_pi pi ON (u.uid = pi.uid)
  LEFT JOIN companies company ON (b.id=company.bill_id)
  WHERE $WHERE
   GROUP BY 1
  ORDER BY $SORT $DESC 
   ;");



  return $self->{list};
}


#**********************************************************
# fees
#**********************************************************
sub paid_add {
  my $self = shift;
  my ($attr) = @_;

  my %DATA = $self->get_data($attr, { default => { DESCRIBE => '',
                                                   STATUS   => 0 
  	                                             } }); 

  my $status_date = ($DATA{STATUS} && $DATA{STATUS} > 0) ?  'now()' : '0000-00-00';
  $self->query($db, "INSERT INTO extfin_paids 
   (date, sum, comments, uid, aid, status, type_id, ext_id, status_date, maccount_id)
  VALUES ('$DATA{DATE}', '$DATA{SUM}', '$DATA{DESCRIBE}', '$DATA{UID}', '$admin->{AID}', 
  '$DATA{STATUS}', '$DATA{TYPE}', '$DATA{EXT_ID}', $status_date,
  '$DATA{MACCOUNT_ID}');", 'do');

  return $self;
}




#**********************************************************
# fees
#**********************************************************
sub paid_periodic_add {
  my $self = shift;
  my ($attr) = @_;

  my %DATA = $self->get_data($attr); 
  my @ids_arr = split(/, /, $DATA{IDS});
  
  $self->paid_periodic_del({ UID => $DATA{UID} });
  
  foreach my $id (@ids_arr) {
    $self->query($db, "INSERT INTO extfin_paids_periodic 
      (uid, type_id, comments, sum, date, aid, maccount_id)
    VALUES ('$DATA{UID}', '$id',  '". $DATA{'COMMENTS_'.$id} ."', '". $DATA{'SUM_'.$id} ."', 
     now(), '$admin->{AID}', '". $DATA{'MACCOUNT_ID_'. $id} ."');", 'do');
   }

  return $self;
}

#**********************************************************
# fees
#**********************************************************
sub paid_periodic_del {
  my $self = shift;
  my ($attr) = @_;

 
  $self->query($db, "DELETE FROM extfin_paids_periodic 
   WHERE uid='$attr->{UID}';", 'do');

  return $self;
}



#**********************************************************
# fees
#**********************************************************
sub paid_periodic_list {
  my $self = shift;
  my ($attr) = @_;

 $WHERE = '';
 undef @WHERE_RULES;

 my $JOIN_WHERE = '';
 if ($attr->{UID}) {
   $JOIN_WHERE = " AND pp.uid='$attr->{UID}'";
  }

 if ($attr->{SUM}) {
   #my $value = $self->search_expr($attr->{SUM}, 'INT');
 	 push @WHERE_RULES, "pp.sum$attr->{SUM}";
  }

 
 $WHERE = ($#WHERE_RULES > -1) ?  "and " . join(' and ', @WHERE_RULES) : '';


 $self->query($db, "SELECT pt.id, pt.name, if(pp.id IS NULL, 0, pp.sum), 
   pp.comments, pp.maccount_id,
   a.id, 
   pp.date, pp.aid, pp.uid
   FROM extfin_paids_types pt
   LEFT join extfin_paids_periodic pp on (pt.id=pp.type_id $JOIN_WHERE)
   LEFT join admins a on (pp.aid=a.aid)
   WHERE pt.periodic='1' $WHERE
  ");

 my $list = $self->{list};


  return $list;
}



#**********************************************************
# fees
#**********************************************************
sub paid_change {
  my $self = shift;
  my ($attr) = @_;

	my %FIELDS = (ID       => 'id', 
	              DATE     => 'date', 
	              SUM      => 'sum', 
	              DESCRIBE => 'comments', 
	              UID      => 'uid', 
	              AID      => 'aid', 
	              STATUS   => 'status',
	              TYPE     => 'type_id',
	              EXT_ID   => 'ext_id',
	              STATUS_DATE => 'status_date',
	              MACCONT_ID  => 'maccount_id'
	              );

  $attr->{STATUS} = 0 if (! $attr->{STATUS});


 	$self->changes($admin, { CHANGE_PARAM => 'ID',
	                TABLE        => 'extfin_paids',
	                FIELDS       => \%FIELDS,
	                OLD_INFO     => $self->paid_info($attr),
	                DATA         => $attr
		              } );
	

  return $self;
}


#**********************************************************
# fees
#**********************************************************
sub paid_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query($db, "DELETE FROM extfin_paids 
    WHERE id='$attr->{ID}';", 'do');

  return $self;
}

#**********************************************************
# fees
#**********************************************************
sub paid_info {
  my $self = shift;
  my ($attr) = @_;

  $self->query($db, "SELECT date, sum, comments, uid, aid, 
  status, status_date, type_id, ext_id, maccount_id
   FROM extfin_paids
  WHERE id='$attr->{ID}';");

  if ($self->{TOTAL} < 1) {
     $self->{errno} = 2;
     $self->{errstr} = 'ERROR_NOT_EXIST';
     return $self;
   }

  ($self->{DATE}, 
   $self->{SUM}, 
   $self->{DESCRIBE}, 
   $self->{UID}, 
   $self->{AID},
   $self->{STATUS},
   $self->{STATUS_DATE},
   $self->{TYPE},
   $self->{EXT_ID},
   $self->{MACCOUNT_ID}
  ) = @{ $self->{list}->[0] };
	
  return $self;
}




#**********************************************************
# fees
#**********************************************************
sub paids_list {
  my $self = shift;
  my ($attr) = @_;

 $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
 $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
 my $PG   = ($attr->{PG}) ? $attr->{PG} : 0;
 my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 100;

 $self->{SEARCH_FIELDS} = '';
 $self->{SEARCH_FIELDS_COUNT}=0;
 
 undef @WHERE_RULES;

 # Start letter 
 if ($attr->{FIRST_LETTER}) {
    push @WHERE_RULES, "u.id LIKE '$attr->{FIRST_LETTER}%'";
  }
 elsif ($attr->{LOGIN}) {
    push @WHERE_RULES, "u.id='$attr->{LOGIN}'";
  }
 # Login expresion
 elsif ($attr->{LOGIN_EXPR}) {
    $attr->{LOGIN_EXPR} =~ s/\*/\%/ig;
    push @WHERE_RULES, "u.id LIKE '$attr->{LOGIN_EXPR}'";
  }
 
 if ($attr->{SUM}) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{SUM}, 'INT', 'p.sum') };
  }
 if ($attr->{GID}) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{GID}, 'INT', 'u.gid') }; 
  }
 if ($attr->{STATUS}) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{STATE}, 'INT', 'p.status'); }
  }

 if ($attr->{TYPE}) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{TYPE}, 'INT', 'p.type_id') };
  }

 if (defined($attr->{PAYMENT_METHOD})) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{PAYMENT_METHOD}, 'INT', 'p.maccount_id') };
  }


 if ($attr->{UID}) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{UID}, 'INT', 'u.uid') };
  }


 if ($attr->{DESCRIBE}) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{DESCRIBE}, 'STR', 'p.comments') };
  }

 if ($attr->{DATE}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{DATE}, 'INT', 'p.date') };
  }
 elsif ($attr->{INTERVAL}) {
 	 my ($from, $to)=split(/\//, $attr->{INTERVAL}, 2);
   push @WHERE_RULES, "date_format(p.date, '%Y-%m-%d')>='$from' and date_format(p.date, '%Y-%m-%d')<='$to'";
  }
# elsif (defined($attr->{MONTH})) {
# 	 push @WHERE_RULES, "date_format(p.date, '%Y-%m')='$attr->{MONTH}'";
#   $date = "date_format(p.date, '%Y-%m-%d')";
#  } 
# else {
# 	 $date = "date_format(p.date, '%Y-%m')";
#  }
 
 my $GROUP = '';
 
 if ($attr->{GROUP}) {
 	 $GROUP = "GROUP BY $attr->{GROUP}";
  }
 
 $WHERE = ($#WHERE_RULES > -1) ?  "and " . join(' and ', @WHERE_RULES) : '';

 $self->query($db, "SELECT p.id, p.date, u.id, p.sum, pt.name, p.comments, p.maccount_id, a.id, p.status, 
    p.status_date,  p.ext_id, p.uid, p.aid, p.type_id
   FROM (extfin_paids p, 
        users u,
        admins a)
   LEFT JOIN extfin_paids_types pt ON (p.type_id=pt.id)
  WHERE 
  p.uid=u.uid and p.aid=a.aid
  $WHERE
  $GROUP
  ORDER BY $SORT $DESC 
  LIMIT $PG, $PAGE_ROWS;");


  my $list = $self->{list};

  if ($self->{TOTAL} > 0 || $PG > 0) {
    $self->query($db, "SELECT count(p.id), sum(sum)
     FROM (extfin_paids p, admins a)
    LEFT JOIN extfin_paids_types pt ON (p.type_id=pt.id)
    WHERE p.aid=a.aid $WHERE;");
    ($self->{TOTAL}, 
     $self->{SUM}) = @{ $self->{list}->[0] };
   }
  
  

  return $list;
}


#**********************************************************
# fees
#**********************************************************
sub paid_reports {
  my $self = shift;
  my ($attr) = @_;
 

 $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
 $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
 my $PG   = ($attr->{PG}) ? $attr->{PG} : 0;
 my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 100;

 $self->{SEARCH_FIELDS} = '';
 $self->{SEARCH_FIELDS_COUNT}=0;
 
 undef @WHERE_RULES;

 # Start letter 
 if ($attr->{FIRST_LETTER}) {
    push @WHERE_RULES, "u.id LIKE '$attr->{FIRST_LETTER}%'";
  }
 elsif ($attr->{LOGIN}) {
    push @WHERE_RULES, "u.id='$attr->{LOGIN}'";
  }
 # Login expresion
 elsif ($attr->{LOGIN_EXPR}) {
    $attr->{LOGIN_EXPR} =~ s/\*/\%/ig;
    push @WHERE_RULES, "u.id LIKE '$attr->{LOGIN_EXPR}'";
  }
 
 if ($attr->{SUM}) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{SUM}, 'INT', 'p.sum') };
  }

 if ($attr->{STATUS}) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{STATE}, 'INT', 'p.status'); }
  }

 if ($attr->{PAYMENT_TYPE}) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{PAIDS_TYPE}, 'INT', 'p.type_id') };
  }
 
 if ($attr->{FIELDS}) {
   push @WHERE_RULES, "p.type_id IN ($attr->{FIELDS})";
  }

 if ($attr->{GID}) {
   push @WHERE_RULES, "u.gid='$attr->{GID}'";
  }
 elsif ($attr->{GIDS}) {
   push @WHERE_RULES, "u.gid IN ($attr->{GIDS})";
  }

 if ($attr->{DESCRIBE}) {
    $attr->{DESCRIBE} =~ s/\*/\%/ig;
    push @WHERE_RULES, "p.descr LIKE '$attr->{DESCRIBE}'";
  }

 my $date='p.date';

 if ($attr->{TYPE}) {
   if($attr->{TYPE} eq 'PAYMENT_METHOD') {
     $date = "p.maccount_id";
    }
   elsif ($attr->{TYPE} eq 'PAYMENT_TYPE') {
 	   $date = "p.type_id";
    }
   elsif ($attr->{TYPE} eq 'USER') {
 	   $date = "u.id";
    }
   elsif ($attr->{TYPE} eq 'ADMINS') {
 	   $date = "a.id";
    }

  }

 if ($attr->{DATE}) {
    push @WHERE_RULES, "p.date='$attr->{DATE}'";
  }
 elsif ($attr->{INTERVAL}) {
 	 my ($from, $to)=split(/\//, $attr->{INTERVAL}, 2);
   push @WHERE_RULES, "date_format(p.date, '%Y-%m-%d')>='$from' and date_format(p.date, '%Y-%m-%d')<='$to'";
  }
 elsif (defined($attr->{MONTH})) {
 	 push @WHERE_RULES, "date_format(p.date, '%Y-%m')='$attr->{MONTH}'";
   $date = "date_format(p.date, '%Y-%m-%d')";
  } 
 else {
 	 $date = "date_format(p.date, '%Y-%m')";
  }
 
 $WHERE = ($#WHERE_RULES > -1) ?  "and " . join(' and ', @WHERE_RULES) : '';

 $self->query($db, "SELECT $date, 
   sum(if(p.status=0, 0, 1)), 
   sum(if(p.status=0, 0, p.sum)), 
   count(p.id), 
   sum(p.sum),
   p.uid
   FROM extfin_paids p, users u, admins a
  WHERE p.uid=u.uid and p.aid=a.aid $WHERE
  GROUP BY 1
  ORDER BY $SORT $DESC ");
#  LIMIT $PG, $PAGE_ROWS;");


  my $list = $self->{list};

  if ($self->{TOTAL} > 0 || $PG > 0) {
    $self->query($db, "SELECT count(p.id), sum(sum)
     FROM extfin_paids p, admins a, users u 
    WHERE p.uid=u.uid and p.aid=a.aid $WHERE;");
    ($self->{TOTAL}, $self->{SUM}) = @{ $self->{list}->[0] };
   }

  return $list;
}


#**********************************************************
# fees
#**********************************************************
sub paid_type_add {
  my $self = shift;
  my ($attr) = @_;

  my %DATA = $self->get_data($attr); 

  $self->query($db, "INSERT INTO extfin_paids_types 
   (name, periodic)
  VALUES ('$DATA{NAME}', '$DATA{PERIODIC}');", 'do');

  return $self;
}


#**********************************************************
# fees
#**********************************************************
sub paid_type_change {
  my $self = shift;
  my ($attr) = @_;

	my %FIELDS = ('ID'       => 'id', 
	              'NAME'     => 'name',
	              'PERIODIC' => 'periodic'
	              );


  $attr->{PERIODIC}=0 if (! $attr->{PERIODIC});

 	$self->changes($admin, { CHANGE_PARAM => 'ID',
	                TABLE        => 'extfin_paids_types',
	                FIELDS       => \%FIELDS,
	                OLD_INFO     => $self->paid_type_info($attr),
	                DATA         => $attr
		              } );
	

  return $self;
}


#**********************************************************
# fees
#**********************************************************
sub paid_type_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query($db, "DELETE FROM extfin_paids_types 
    WHERE id='$attr->{ID}';", 'do');

  return $self;
}

#**********************************************************
# fees
#**********************************************************
sub paid_type_info {
  my $self = shift;
  my ($attr) = @_;

  $self->query($db, "SELECT id, name, periodic
   FROM extfin_paids_types
  WHERE id='$attr->{ID}';");

  if ($self->{TOTAL} < 1) {
     $self->{errno} = 2;
     $self->{errstr} = 'ERROR_NOT_EXIST';
     return $self;
   }

  ($self->{ID}, 
   $self->{NAME},
   $self->{PERIODIC}
  ) = @{ $self->{list}->[0] };
	
  return $self;
}


#**********************************************************
# fees
#**********************************************************
sub paid_types_list {
  my $self = shift;
  my ($attr) = @_;

 $WHERE = '';

 if ($attr->{PERIODIC}) {
 	 $WHERE = "WHERE periodic='$attr->{PERIODIC}'";
  }

 $self->query($db, "SELECT id, name, periodic
   FROM extfin_paids_types
   $WHERE
  ");

 my $list = $self->{list};


  return $list;
}


#**********************************************************
#
#**********************************************************
sub extfin_debetors {
  my $self = shift;
  my ($attr) = @_;

  @WHERE_RULES = ();

  # Show groups
  if ($attr->{GIDS}) {
    push @WHERE_RULES, "u.gid IN ($attr->{GIDS})"; 
   }
  elsif ($attr->{GID}) {
    push @WHERE_RULES, "u.gid='$attr->{GID}'"; 
   }

  my $ext_field = '';

  if ($attr->{DATE}) {
    push @WHERE_RULES, "date_format(f.date, '%Y-%m-%d')<='$attr->{DATE}'";
    
    push @WHERE_RULES, "(f.last_deposit-f.sum<0)";
    $attr->{DATE} = "'$attr->{DATE}'";
    $ext_field = "\@A:=f.last_deposit-f.sum,";
   }
  else {
    push @WHERE_RULES, "( b.deposit < 0 or cb.deposit < 0 ) and (f.last_deposit >=0 and f.last_deposit-sum<0)";
    $ext_field = "\@A:=if(company.id IS NULL,b.deposit,cb.deposit),";
    $attr->{DATE} = 'CURDATE()';
   }
  
  $WHERE = ($#WHERE_RULES > -1) ?  "and " . join(' and ', @WHERE_RULES) : ''; 

  $self->query($db, "SELECT '', u.id, pi.contract_id,
   pi.fio,
   pi.contract_date,
   dv.tp_id,
   $ext_field
   if(DATEDIFF($attr->{DATE}, f.date) < 32, \@A, ''),
   if(DATEDIFF($attr->{DATE}, f.date) > 33 and DATEDIFF($attr->{DATE}, f.date) < 54 , \@A, ''),
   if(DATEDIFF($attr->{DATE}, f.date) > 65 and DATEDIFF($attr->{DATE}, f.date) < 96 , \@A, ''),
   if(DATEDIFF($attr->{DATE}, f.date) > 97 and DATEDIFF($attr->{DATE}, f.date) < 183 , \@A, ''),
   if(DATEDIFF($attr->{DATE}, f.date) > 184 and DATEDIFF($attr->{DATE}, f.date) < 365 , \@A, ''),
   if(DATEDIFF($attr->{DATE}, f.date) > 365 , \@A, ''),

   u.uid
  FROM (users u, fees f)
     LEFT JOIN users_pi pi ON (u.uid = pi.uid)
     LEFT JOIN bills b ON (u.bill_id = b.id)
     LEFT JOIN companies company ON  (u.company_id=company.id)
     LEFT JOIN bills cb ON  (company.bill_id=cb.id)
     LEFT JOIN dv_main dv ON  (u.uid=dv.uid)
WHERE u.uid=f.uid $WHERE
GROUP BY f.uid
ORDER BY f.date DESC;");

  my $list = $self->{list};


  return $list;
}

1

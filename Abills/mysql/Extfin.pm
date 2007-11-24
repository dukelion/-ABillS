package Extfin;
# Users manage functions
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

# User name expration
my $usernameregexp = "^[a-z0-9_][a-z0-9_-]*\$"; # configurable;

use main;
@ISA  = ("main");


#**********************************************************
# Init 
#**********************************************************
sub new {
  my $class = shift;
  ($db, $admin, $CONF) = @_;

  #$WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';
  
  $admin->{MODULE}='Extfin';
#  $CONF->{MAX_USERNAME_LENGTH} = 10 if (! defined($CONF->{MAX_USERNAME_LENGTH}));
  
  if (defined($CONF->{USERNAMEREGEXP})) {
  	$usernameregexp=$CONF->{USERNAMEREGEXP};
   }

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
 my $search_fields = '';

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
 	  push @WHERE_RULES, "f.date>='$attr->{DATE_FROM}' AND f.date<='$attr->{DATE_TO}'";
 	  push @WHERE_RULES_DV, "dv.start>='$attr->{DATE_FROM}' AND dv.start<='$attr->{DATE_TO}'";
   }
 elsif ($attr->{MONTH}) {
   push @WHERE_RULES, "DATE_FORMAT(f.date, '%Y-%m')='$attr->{MONTH}'";
   push @WHERE_RULES_DV, "DATE_FORMAT(dv.start, '%Y-%m')='$attr->{MONTH}'";
  }
 
 
 my $WHERE = ($#WHERE_RULES > -1) ? join(' and ', @WHERE_RULES)  : '';
 my $WHERE_DV = ($#WHERE_RULES > -1) ? join(' and ', @WHERE_RULES_DV)  : '';


 #Get fees
 $self->query($db, "SELECT
 if(u.company_id > 0, company.bill_id, u.bill_id),
 sum(f.sum),
     if(u.company_id > 0, company.name,
          if(pi.fio<>'', pi.fio, u.id)),
                         if(u.company_id > 0, company.name,
                            if(pi.fio<>'', pi.fio, u.id)),
  if(u.company_id > 0, 1, 0),
  if(u.company_id > 0, company.vat, 0),
  u.uid,
  max(date)
     FROM (users u, fees f)
     LEFT JOIN users_pi pi ON (u.uid = pi.uid)
     LEFT JOIN companies company ON  (u.company_id=company.id)

     WHERE u.uid=f.uid and $WHERE
     GROUP BY 1
     ORDER BY $SORT $DESC 
     LIMIT 10
   ;");

  foreach my $line (@{ $self->{list} } ) {
  	$PAYMENT_DEED{$line->[0]}=$line->[1];
 	  #Name|Type|VAT
 	  $NAMES{$line->[0]}="$line->[2]|$line->[4]|$line->[5]";
   }
	
 $self->query($db, "SELECT
 if(u.company_id > 0, company.bill_id, u.bill_id),
 sum(dv.sum),
 if(u.company_id > 0, company.name,
          if(pi.fio<>'', pi.fio, u.id)),
                         if(u.company_id > 0, company.name,
                            if(pi.fio<>'', pi.fio, u.id)),
  if(u.company_id > 0, 1, 0),
  if(u.company_id > 0, company.vat, 0),
  u.uid
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
  	 }
   }


  $self->{PAYMENT_DEED}=\%PAYMENT_DEED;
  $self->{NAMES}=\%NAMES;

	
	
	
	return $self;
}

1

package Companies;
# Companies
#

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION
);

use Exporter;
$VERSION = 3.00;
@ISA = ('Exporter');

@EXPORT = qw(
);

@EXPORT_OK = ();
%EXPORT_TAGS = ();

use Users;

use main;
@ISA  = ("main");

my $users;


#**********************************************************
# Init 
#**********************************************************
sub new {
  my $class = shift;
  ($db, $admin, $CONF) = @_;
  my $self = { };
  bless($self, $class);
  $users = Users->new($db, $admin, $CONF); 
  return $self;
}


#**********************************************************
# defauls user settings
#**********************************************************
sub defaults {
  my $self = shift;

  %DATA = (
 COMPANY_ID      => 0, 
 COMPANY_NAME    => '',
 TAX_NUMBER      => '',
 BANK_ACCOUNT    => '',
 BANK_NAME       => '',
 COR_BANK_ACCOUNT=> '',
 BANK_BIC        => '',
 DISABLE         => 0,
 CREDIT          => '',
 CREDIT_DATE     => '',
 ADDRESS         => '',
 PHONE           => '',
 VAT             => '',
 CONTRACT_ID     => '',
 CONTRACT_DATE   => '0000-00-00',
 BILL_ID         => 0,
 EXT_BILL_ID     => 0,
 DOMAIN_ID       => 0,
 REPRESENTATIVE  => ''
 );
 
  $self = \%DATA;
  return $self;
}

#**********************************************************
# Add
#**********************************************************
sub add {
  my $self = shift;
  my ($attr) = @_;


  my $name = (defined($attr->{COMPANY_NAME})) ? $attr->{COMPANY_NAME} : '';
  
  if ($name eq '') {
    $self->{errno}  = 8;
    $self->{errstr} = 'ERROR_ENTER_NAME';
    return $self;
   }


#Info fields
  my $info_fields = '';
  my $info_fields_val = '';

	my $list = $users->config_list({ PARAM => 'ifc*' });
  if ($users->{TOTAL} > 0) {
    my @info_fields_arr = ();
    my @info_fields_val = ();

    foreach my $line (@$list) {
      if ($line->[0] =~ /ifc(\S+)/) {
      	my $value = $1;
    	  push @info_fields_arr, $value;

        if (defined($attr->{$value})) {
    	    #attach
    	    if ( ref $attr->{$value} eq 'HASH' && $attr->{$value}{filename}) {
            $self->attachment_add({ 
            	TABLE        => $value.'_file',
              CONTENT      => $attr->{$value}{Contents},
              FILESIZE     => $attr->{$value}{Size},
              FILENAME     => $attr->{$value}{filename},
              CONTENT_TYPE => $attr->{$value}{'Content-Type'}
             });
            $attr->{$value}=$self->{INSERT_ID};
           }
          else {
          	$attr->{$value} =~ s/^ +|[ \n]+$//g;
           }
         }
   	    else {
   	    	$attr->{$value} = '';
   	     }

        push @info_fields_val, "'$attr->{$value}'";
      }

     }
    $info_fields = ', '. join(', ', @info_fields_arr);
    $info_fields_val = ', '. join(', ', @info_fields_val);
   }

  my $prefix='';
  my $sufix =''; 
  if ($attr->{CONTRACT_TYPE}) {
  	($prefix, $sufix)=split(/\|/, $attr->{CONTRACT_TYPE});
   }


  my %DATA = $self->get_data($attr, { default => defaults() }); 
  $self->query($db, "INSERT INTO companies (id, name, tax_number, bank_account, bank_name, cor_bank_account, 
     bank_bic, disable, credit, credit_date, address, phone, vat, contract_id, contract_date,
     bill_id, ext_bill_id, registration, domain_id, representative, contract_sufix
     $info_fields) 
     VALUES ('$DATA{COMPANY_ID}', '$DATA{COMPANY_NAME}', '$DATA{TAX_NUMBER}', '$DATA{BANK_ACCOUNT}', '$DATA{BANK_NAME}', '$DATA{COR_BANK_ACCOUNT}', 
      '$DATA{BANK_BIC}', '$DATA{DISABLE}', '$DATA{CREDIT}', '$DATA{CREDIT_DATE}',
      '$DATA{ADDRESS}', '$DATA{PHONE}',
      '$DATA{VAT}', '$DATA{CONTRACT_ID}', '$DATA{CONTRACT_DATE}',
      '$DATA{BILL_ID}', '$DATA{EXT_BILL_ID}', now(), '$admin->{DOMAIN_ID}', '$DATA{REPRESENTATIVE}', '$sufix'
      $info_fields_val
      );", 'do');

  if ($self->{errno}) {
  	return $self;
   }

  $self->{COMPANY_ID} = $self->{INSERT_ID};

  if ($attr->{CREATE_BILL}) {
  	$self->change({ 
  		 DISABLE     => int($DATA{DISABLE}),
  		 COMPANY_ID  => $self->{COMPANY_ID},
  		 CREATE_BILL => 1,
  		 CREATE_EXT_BILL  => $attr->{CREATE_EXT_BILL}  		 
  		 });
   }



  return $self;
}


#**********************************************************
# Change
#**********************************************************
sub change {
  my $self = shift;
  my ($attr) = @_;


  my $old_info = $self->info($attr->{COMPANY_ID});

  if($attr->{CREATE_BILL}) {
  	 use Bills;
  	 my $Bill = Bills->new($db, $admin, $CONF);
  	 $Bill->create({ COMPANY_ID => $self->{COMPANY_ID}, UID => 0 });
     if($Bill->{errno}) {
       $self->{errno}  = $Bill->{errno};
       $self->{errstr} =  $Bill->{errstr};
       return $self;
      }
     $attr->{BILL_ID}=$Bill->{BILL_ID};
     $attr->{DISABLE}=$old_info->{DISABLE};
     
     if ($attr->{CREATE_EXT_BILL}) {
    	 $Bill->create({ COMPANY_ID => $self->{COMPANY_ID} });
       if($Bill->{errno}) {
         $self->{errno}  = $Bill->{errno};
         $self->{errstr} =  $Bill->{errstr};
         return $self;
        }
       $attr->{EXT_BILL_ID}=$Bill->{BILL_ID};
      }
   }
  elsif ($attr->{CREATE_EXT_BILL}) {
  	   use Bills;
  	   my $Bill = Bills->new($db, $admin, $CONF);
    	 $Bill->create({ COMPANY_ID => $self->{COMPANY_ID} });
       $attr->{DISABLE}=$old_info->{DISABLE};

       if($Bill->{errno}) {
         $self->{errno}  = $Bill->{errno};
         $self->{errstr} =  $Bill->{errstr};
         return $self;
        }
       $attr->{EXT_BILL_ID}=$Bill->{BILL_ID};
   }
 
 my %FIELDS = (
   COMPANY_NAME   => 'name', 
   TAX_NUMBER     => 'tax_number', 
   BANK_ACCOUNT   => 'bank_account', 
   BANK_NAME      => 'bank_name', 
   COR_BANK_ACCOUNT => 'cor_bank_account', 
   BANK_BIC       => 'bank_bic',
   DISABLE        => 'disable',
   CREDIT         => 'credit',
   CREDIT_DATE    => 'credit_date',
   BILL_ID        => 'bill_id',
   EXT_BILL_ID    => 'ext_bill_id',
   COMPANY_ID     => 'id',
   ADDRESS        => 'address',
   PHONE          => 'phone',
   VAT            => 'vat',
   CONTRACT_ID    => 'contract_id',
   CONTRACT_DATE  => 'contract_date',
   CONTRACT_SUFIX => 'contract_sufix',
   DOMAIN_ID      => 'domain_id',
   REPRESENTATIVE => 'representative'
   );



  $attr->{DOMAIN_ID}=$admin->{DOMAIN_ID};

	my $list = $users->config_list({ PARAM => 'ifc*'});
  if ($users->{TOTAL} > 0) {
    foreach my $line (@$list) {
      if ($line->[0] =~ /ifc(\S+)/) {
        my $field_name = $1;
        $FIELDS{$field_name}="$field_name";
        my ($position, $type, $name)=split(/:/, $line->[1]);

        if ($type == 13) {
    	    #attach
    	    if ( ref $attr->{$field_name} eq 'HASH' && $attr->{$field_name}{filename}) {
            $self->attachment_add({
            	TABLE        => $field_name.'_file',
              CONTENT      => $attr->{$field_name}{Contents},
              FILESIZE     => $attr->{$field_name}{Size},
              FILENAME     => $attr->{$field_name}{filename},
              CONTENT_TYPE => $attr->{$field_name}{'Content-Type'}
             });
            $attr->{$field_name}=$self->{INSERT_ID};
           }
          else {
          	delete $attr->{$field_name};
           }
         }
        elsif ($type == 4) {
        	$attr->{$field_name} = 0 if (! $attr->{$field_name});
         }
      }
     }
   }

  my ($prefix, $sufix); 
  if ($attr->{CONTRACT_TYPE}) {
  	($prefix, $sufix)=split(/\|/, $attr->{CONTRACT_TYPE});
  	$attr->{CONTRACT_SUFIX}=$sufix;
   }


	$self->changes($admin, { CHANGE_PARAM => 'COMPANY_ID',
		               TABLE        => 'companies',
		               FIELDS       => \%FIELDS,
		               OLD_INFO     => $old_info,
		               DATA         => $attr
		              } );


  $self->info($attr->{COMPANY_ID});

  return $self;
}


#**********************************************************
# Del
#**********************************************************
sub del {
  my $self = shift;
  my ($company_id) = @_;
  $self->query($db, "DELETE FROM companies WHERE id='$company_id';", 'do');
  return $self;
}


#**********************************************************
# Info
#**********************************************************
sub info {
  my $self = shift;
  my ($company_id) = @_;

#Make info fields use
  my $info_fields = '';
  my @info_fields_arr = ();

	my $list = $users->config_list({ PARAM => 'ifc*', SORT => 2 });
  if ($users->{TOTAL} > 0) {
    my %info_fields_hash = ();

    foreach my $line (@$list) {
      if ($line->[0] =~ /ifc(\S+)/) {
    	  push @info_fields_arr, $1;
        $info_fields_hash{$1}="$line->[1]";
       }
     }
    $info_fields = ', '. join(', ', @info_fields_arr) if ($#info_fields_arr > -1);
    $self->{INFO_FIELDS_ARR}  = \@info_fields_arr;
    $self->{INFO_FIELDS_HASH} = \%info_fields_hash;   
   }

  $self->query($db, "SELECT c.id, c.name, c.credit, c.credit_date,
  c.tax_number, c.bank_account, c.bank_name, 
  c.cor_bank_account, c.bank_bic, c.disable, c.bill_id, b.deposit,
  c.address, c.phone,
  c.vat, contract_id, contract_DATE,
  c.ext_bill_id,
  c.registration,
  c.domain_id,
  c.representative,
  c.contract_sufix
  $info_fields
    FROM companies c
    LEFT JOIN bills b ON (c.bill_id=b.id)
    WHERE c.id='$company_id';");

  if ($self->{TOTAL} < 1) {
     $self->{errno} = 2;
     $self->{errstr} = 'ERROR_NOT_EXIST';
     return $self;
   }

  my @INFO_ARR = ();

  ($self->{COMPANY_ID}, 
   $self->{COMPANY_NAME}, 
   $self->{CREDIT}, 
   $self->{CREDIT_DATE}, 
   $self->{TAX_NUMBER}, 
   $self->{BANK_ACCOUNT}, 
   $self->{BANK_NAME}, 
   $self->{COR_BANK_ACCOUNT}, 
   $self->{BANK_BIC},
   $self->{DISABLE},
   $self->{BILL_ID},
   $self->{DEPOSIT},
   $self->{ADDRESS},
   $self->{PHONE},
   $self->{VAT},
   $self->{CONTRACT_ID},
   $self->{CONTRACT_DATE},
   $self->{EXT_BILL_ID},
   $self->{REGISTRATION},
   $self->{DOMAIN_ID},
   $self->{REPRESENTATIVE},
   $self->{CONTRACT_SUFIX},
   @INFO_ARR
   ) = @{ $self->{list}->[0] };
  
   $self->{INFO_FIELDS_VAL} = \@INFO_ARR;
  
   my $i = 0;
   foreach my $val (@INFO_ARR) {
   	 $self->{$info_fields_arr[$i]}=$val;
   	 $self->{'INFO_FIELDS_VAL_'.$i}=$val;
  	 $i++;
    }

  
   if ($CONF->{EXT_BILL_ACCOUNT} && $self->{EXT_BILL_ID} > 0) {
 	 $self->query($db, "SELECT b.deposit, b.uid
     FROM bills b WHERE id='$self->{EXT_BILL_ID}';");

   if ($self->{TOTAL} < 1) {
     $self->{errno} = 2;
     $self->{errstr} = 'ERROR_NOT_EXIST';
     return $self;
    }

   ($self->{EXT_BILL_DEPOSIT},
    $self->{EXT_BILL_OWNER}
    )= @{ $self->{list}->[0] };
  } 

  
  return $self;
}



#**********************************************************
# List
#**********************************************************
sub list {
 my $self = shift;
 my ($attr) = @_;

 
 $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
 $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
 $PG   = ($attr->{PG}) ? $attr->{PG} : 0;
 $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;
 @WHERE_RULES = ();

 if ($attr->{CONTRACT_ID}) {
   push @WHERE_RULES, @{ $self->search_expr("$attr->{CONTRACT_ID}", 'STR', 'c.contract_id') };
 }

 if ($admin->{DOMAIN_ID}) {
 	 push @WHERE_RULES, @{ $self->search_expr("$admin->{DOMAIN_ID}", 'INT', 'c.domain_id', { EXT_FIELD => 1 }) };
  }
 elsif ($attr->{DOMAIN_ID}) {
   push @WHERE_RULES, @{ $self->search_expr("$attr->{DOMAIN_ID}", 'INT', 'c.domain_id', { EXT_FIELD => 1 }) };
  }

 if ($attr->{COMPANY_NAME}) {
   push @WHERE_RULES, @{ $self->search_expr("$attr->{COMPANY_NAME}", 'STR', 'c.name') };
  }

 if ($attr->{COMPANY_ID}) {
   push @WHERE_RULES, @{ $self->search_expr("$attr->{COMPANY_ID}", 'INT', 'c.id') };
  }


 if ($attr->{CREDIT_DATE}) {
   push @WHERE_RULES, @{ $self->search_expr("$attr->{CREDIT_DATE}", 'INT', 'c.credit_date') };
  }

 if ($attr->{CREDIT}) {
   push @WHERE_RULES, @{ $self->search_expr("$attr->{CREDIT}", 'INT', 'c.credit') };
  }

 if ($attr->{LOGIN}) {
   push @WHERE_RULES, @{ $self->search_expr("$attr->{LOGIN}", 'STR', 'c.name') };
  }

 my $WHERE = ($#WHERE_RULES > -1) ?  "WHERE " . join(' and ', @WHERE_RULES) : ''; 



 $self->query($db, "SELECT c.name, b.deposit, c.registration, count(u.uid), c.disable, c.id, 
   c.disable, c.bill_id, c.credit, c.credit_date
    FROM companies  c
    LEFT JOIN users u ON (u.company_id=c.id)
    LEFT JOIN bills b ON (b.id=c.bill_id)
    $WHERE
    GROUP BY c.id
    ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;");
 my $list = $self->{list};

    if ($self->{TOTAL} > 0 || $PG > 0) {
      $self->query($db, "SELECT count(c.id) FROM companies c $WHERE;");
      ($self->{TOTAL}) = @{ $self->{list}->[0] };
     }

return $list;
}



#**********************************************************
# List
#**********************************************************
sub admins_list {
 my $self = shift;
 my ($attr) = @_;
 
 $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
 $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
 $PG   = ($attr->{PG}) ? $attr->{PG} : 0;
 $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;
 my @WHERE_RULES = ();
 my $WHERE = '';


 if ($attr->{UID}) {
 	 push @WHERE_RULES, "u.uid='$attr->{UID}'";
  }

 if ($attr->{GET_ADMINS}) {
 	 push @WHERE_RULES, "ca.uid>0";
  }

 if ($attr->{COMPANY_ID}) {
 	 push @WHERE_RULES, "c.id='$attr->{COMPANY_ID}'";
  }

 $WHERE = ' AND ' . join(' and ', @WHERE_RULES) if   ($#WHERE_RULES > -1); 

 $self->query($db, "SELECT if(ca.uid is null, 0, 1), u.id, pi.fio, pi.email, u.uid
    FROM (companies  c, users u)
    LEFT JOIN companie_admins ca ON (ca.uid=u.uid)
    LEFT JOIN users_pi pi ON (pi.uid=u.uid)
    WHERE u.company_id=c.id $WHERE
    ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;");

 my $list = $self->{list};

 return $list;
}



#**********************************************************
# List
#**********************************************************
sub admins_change {
 my $self = shift;
 my ($attr) = @_;
 
 
 my @ADMINS = split(/, /, $attr->{IDS});

 $self->query($db, "DELETE FROM companie_admins WHERE company_id='$attr->{COMPANY_ID}';", 'do');


 foreach my $uid (@ADMINS) {
   $self->query($db, "INSERT INTO companie_admins (company_id, uid)
    VALUES ('$attr->{COMPANY_ID}', '$uid');", 'do');
  }

 return $self;
}



1

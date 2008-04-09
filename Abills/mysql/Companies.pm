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
  #$self->{debug}=1;
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
    $self->{errno} = 8;
    $self->{errstr} = 'ERROR_ENTER_NAME';
    return $self;
   }

  my %DATA = $self->get_data($attr); 
  $self->query($db, "INSERT INTO companies (name, tax_number, bank_account, bank_name, cor_bank_account, 
     bank_bic, disable, credit, address, phone, vat, contract_id,
     bill_id, ext_bill_id) 
     VALUES ('$DATA{COMPANY_NAME}', '$DATA{TAX_NUMBER}', '$DATA{BANK_ACCOUNT}', '$DATA{BANK_NAME}', '$DATA{COR_BANK_ACCOUNT}', 
      '$DATA{BANK_BIC}', '$DATA{DISABLE}', '$DATA{CREDIT}',
      '$DATA{ADDRESS}', '$DATA{PHONE}',
      '$DATA{VAT}', '$DATA{CONTRACT_ID}',
      '$DATA{BILL_ID}', '$DATA{EXT_BILL_ID}'
      );", 'do');

  $self->{COMPANY_ID} = $self->{INSERT_ID};

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
  	 $Bill->create({ COMPANY_ID => $self->{COMPANY_ID} });
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
       #$DATA{BILL_ID}=$Bill->{BILL_ID};
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
   BILL_ID        => 'bill_id',
   EXT_BILL_ID    => 'ext_bill_id',
   COMPANY_ID     => 'id',
   ADDRESS        => 'address',
   PHONE          => 'phone',
   VAT            => 'vat',
   CONTRACT_ID    => 'contract_id'
   );

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

  $self->query($db, "SELECT c.id, c.name, c.credit, c.tax_number, c.bank_account, c.bank_name, 
  c.cor_bank_account, c.bank_bic, c.disable, c.bill_id, b.deposit,
  c.address, c.phone,
  c.vat, contract_id,
  c.ext_bill_id
    FROM companies c
    LEFT JOIN bills b ON (c.bill_id=b.id)
    WHERE c.id='$company_id';");

  if ($self->{TOTAL} < 1) {
     $self->{errno} = 2;
     $self->{errstr} = 'ERROR_NOT_EXIST';
     return $self;
   }

  ($self->{COMPANY_ID}, 
   $self->{COMPANY_NAME}, 
   $self->{CREDIT}, 
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
   $self->{EXT_BILL_ID}
   ) = @{ $self->{list}->[0] };
  
  
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
 my $WHERE = '';
 
 $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
 $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
 $PG = ($attr->{PG}) ? $attr->{PG} : 0;
 $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;


 if ($attr->{LOGIN_EXPR}) {
    $attr->{LOGIN_EXPR} =~ s/\*/\%/ig;
    $WHERE .= ($WHERE ne '') ?  " and c.name LIKE '$attr->{LOGIN_EXPR}' " : "WHERE c.name LIKE '$attr->{LOGIN_EXPR}' ";
  }

 $self->query($db, "SELECT c.name, b.deposit, c.registration, count(u.uid), c.disable, c.id, c.disable, c.bill_id
    FROM companies  c
    LEFT JOIN users u ON (u.company_id=c.id)
    LEFT JOIN bills b ON (b.id=c.bill_id)
    $WHERE
    GROUP BY c.id
    ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;");
 my $list = $self->{list};

    $self->query($db, "SELECT count(c.id) FROM companies c $WHERE;");
    ($self->{TOTAL}) = @{ $self->{list}->[0] };

return $list;
}





1

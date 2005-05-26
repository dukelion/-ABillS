package Accounts;
# Accounts manage functions
#

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
@ISA  = ("main");

my $db;

#**********************************************************
# Init 
#**********************************************************
sub new {
  my $class = shift;
  $db = shift;
  my $self = { };
  bless($self, $class);
#  $self->{debug}=1;
  return $self;
}

#**********************************************************
# Add
#**********************************************************
sub add {
  my $self = shift;
  my ($attr) = @_;

  my $name = (defined($attr->{ACCOUNT_NAME})) ? $attr->{ACCOUNT_NAME} : '';
  
  if ($name eq '') {
    $self->{errno} = 8;
    $self->{errstr} = 'ERROR_ENTER_NAME';
    return $self;
   }

  my %DATA = $self->get_data($attr); 
  $self->query($db, "INSERT INTO accounts (name, tax_number, bank_account, bank_name, cor_bank_account, bank_bic) 
     VALUES ('$DATA{ACCOUNT_NAME}', '$DATA{TAX_NUMBER}', '$DATA{BANK_ACCOUNT}', '$DATA{BANK_NAME}', '$DATA{COR_BANK_ACCOUNT}', 
      '$DATA{BANK_BIC}');", 'do');

  return $self;
}


#**********************************************************
# Add
#**********************************************************
sub change {
  my $self = shift;
  my ($account_id, $attr) = @_;

  my $name = (defined($attr->{ACCOUNT_NAME})) ? $attr->{ACCOUNT_NAME} : '';
  
  if ($name eq '') {
    $self->{errno} = 8;
    $self->{errstr} = 'ERROR_ENTER_NAME';
    return $self;
   }

 my %DATA = $self->get_data($attr); 
 my $CHANGES_QUERY = "";
 my $CHANGES_LOG = "Account:";

#   DEPOST => 'deposit', 
#   ACCOUNT_ID => 'id', 
 my %FIELDS = (
   ACCOUNT_NAME => 'name', 
   TAX_NUMBER => 'tax_number', 
   BANK_ACCOUNT => 'bank_account', 
   BANK_NAME => 'bank_name', 
   COR_BANK_ACCOUNT => 'cor_bank_account', 
   BANK_BIC => 'bank_bic'
   );

 my $OLD = $self->info($account_id);

 while(my($k, $v)=each(%DATA)) {
    if ($OLD->{$k} ne $DATA{$k}){
      if ($FIELDS{$k}) {
         $CHANGES_LOG .= "$k $OLD->{$k}->$DATA{$k};";
         $CHANGES_QUERY .= "$FIELDS{$k}='$DATA{$k}',";
       }
     }
  }

if ($CHANGES_QUERY eq '') {
  return $self->{result};	
}

# print $CHANGES_LOG;
  chop($CHANGES_QUERY);
  $self->query($db, "UPDATE accounts SET $CHANGES_QUERY
    WHERE id='$account_id';", 'do');

#  $admin->action_add(0, "$CHANGES_LOG");

  $self->info($account_id);

  return $self;
}


#**********************************************************
# Info
#**********************************************************
sub del {
  my $self = shift;
  my ($account_id) = @_;
  $self->query($db, "DELETE FROM accounts WHERE id='$account_id';", 'do');
  return $self;
}


#**********************************************************
# Info
#**********************************************************
sub info {
  my $self = shift;
  my ($account_id) = @_;

  $self->query($db, "SELECT id, name, deposit, tax_number, bank_account, bank_name, cor_bank_account, bank_bic
    FROM accounts WHERE id='$account_id';");

  if ($self->{TOTAL} < 1) {
     $self->{errno} = 2;
     $self->{errstr} = 'ERROR_NOT_EXIST';
     return $self;
   }

  my $a_ref = $self->{list}->[0];

  ($self->{ACCOUNT_ID}, 
   $self->{ACCOUNT_NAME}, 
   $self->{DEPOST}, 
   $self->{TAX_NUMBER}, 
   $self->{BANK_ACCOUNT}, 
   $self->{BANK_NAME}, 
   $self->{COR_BANK_ACCOUNT}, 
   $self->{BANK_BIC}) = @$a_ref;
    
  return $self;
}



#**********************************************************
# List
#**********************************************************
sub list {
 my $self = shift;
 my ($attr) = @_;
 my $WHERE = '';
 
 my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
 my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
 my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
 my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;


 if ($attr->{LOGIN_EXPR}) {
    $attr->{LOGIN_EXPR} =~ s/\*/\%/ig;
    $WHERE .= ($WHERE ne '') ?  " and a.name LIKE '$attr->{LOGIN_EXPR}' " : "WHERE a.name LIKE '$attr->{LOGIN_EXPR}' ";
  }

 $self->query($db, "SELECT a.name, a.deposit, a.registration, count(u.uid), a.id
    FROM accounts a
    LEFT JOIN users u ON (u.account_id=a.id)
    $WHERE
    GROUP BY a.id
    ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;");
 my $list = $self->{list};

 if ($self->{TOTAL} > 0) {
    $self->query($db, "SELECT count(a.id) FROM accounts a;");
    my $a_ref = $self->{list}->[0];
    ($self->{TOTAL}) = @$a_ref;
   }

#  $self->{list}=$list;

return $list;
}





1
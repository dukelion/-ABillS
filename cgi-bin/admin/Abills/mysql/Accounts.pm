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


my $db;
# Customer id
my $aid; 


#**********************************************************
# Init 
#**********************************************************
sub new {
  my $class = shift;
  $db = shift;
  my $self = { };
  bless($self, $class);
  return $self;
}

#**********************************************************
# Add
#**********************************************************
sub add {
  my $self = shift;
  my ($attr) = @_;

  my $name = (defined($attr->{NAME})) ? $attr->{NAME} : '';
  
  if ($name eq '') {
    $self->{errno} = 8;
    $self->{errstr} = 'ERROR_ENTER_NAME';
    return $self;
   }

  my $tax_number  = (defined($attr->{TAX_NUMBER})) ? $attr->{TAX_NUMBER} : '';
  my $bank_account = (defined($attr->{BANK_ACCOUNT})) ? $attr->{BANK_ACCOUNT} : '';
  my $bank_name = (defined($attr->{BANK_NAME})) ? $attr->{BANK_NAME} : '';
  my $cor_bank_account = (defined($attr->{COR_BANK_ACCOUNT})) ? $attr->{COR_BANK_ACCOUNT} : '';
  my $bank_bic = (defined($attr->{BANK_BIC})) ? $attr->{BANK_BIC} : '';

  my $sql = "INSERT INTO accounts (name, tax_number, bank_account, bank_name, cor_bank_account, bank_bic) 
     VALUES ('$name', '$tax_number', '$bank_account', '$bank_name', '$cor_bank_account', '$bank_bic');";
  my $q = $db->do($sql); 

  if ($db->err == 1062) {
     $self->{errno} = 7;
     $self->{errstr} = 'ERROR_DUBLICATE';
     return $self;
   }
  elsif($db->err > 0) {
     $self->{errno} = 3;
     $self->{errstr} = 'SQL_ERROR';
     return $self;
   }

  print $sql;

  return $self;
}


#**********************************************************
# Add
#**********************************************************
sub change {
  my $self = shift;
  my ($account_id, $attr) = @_;

  my $name = (defined($attr->{NAME})) ? $attr->{NAME} : '';
  
  if ($name eq '') {
    $self->{errno} = 8;
    $self->{errstr} = 'ERROR_ENTER_NAME';
    return $self;
   }

  my $tax_number  = (defined($attr->{TAX_NUMBER})) ? $attr->{TAX_NUMBER} : '';
  my $bank_account = (defined($attr->{BANK_ACCOUNT})) ? $attr->{BANK_ACCOUNT} : '';
  my $bank_name = (defined($attr->{BANK_NAME})) ? $attr->{BANK_NAME} : '';
  my $cor_bank_account = (defined($attr->{COR_BANK_ACCOUNT})) ? $attr->{COR_BANK_ACCOUNT} : '';
  my $bank_bic = (defined($attr->{BANK_BIC})) ? $attr->{BANK_BIC} : '';

  my $sql = "UPDATE
     accounts SET 
     name='$name', 
     tax_number='$tax_number', 
     bank_account='$bank_account', 
     bank_name='$bank_name', 
     cor_bank_account='$cor_bank_account', 
     bank_bic='$bank_bic'
     WHERE id='$account_id';";
  my $q = $db->do($sql); 

  if ($db->err == 1062) {
     $self->{errno} = 7;
     $self->{errstr} = 'ERROR_DUBLICATE';
     return $self;
   }
  elsif($db->err > 0) {
     $self->{errno} = 3;
     $self->{errstr} = 'SQL_ERROR';
     return $self;
   }

  return $self;
}


#**********************************************************
# Info
#**********************************************************
sub del {
  my $self = shift;
  my ($account_id) = @_;

  my $sql = "DELETE FROM accounts WHERE id='$account_id';";
  my $q = $db->do($sql); 

  return $self;
}


#**********************************************************
# Info
#**********************************************************
sub info {
  my $self = shift;
  my ($account_id) = @_;

  my $sql = "SELECT name, deposit, tax_number, bank_account, bank_name, cor_bank_account, bank_bic
    FROM accounts WHERE id='$account_id';";

  my $q = $db->prepare($sql) || die $db->errstr;
  $q ->execute(); 

  if ($q->rows < 1) {
     $self->{errno} = 2;
     $self->{errstr} = 'ERROR_NOT_EXIST';
     return $self;
   }

  ($self->{ACCOUNT_NAME}, 
   $self->{DEPOST}, 
   $self->{TAX_NUMBER}, 
   $self->{BANK_ACCOUNT}, 
   $self->{BANK_NAME}, 
   $self->{COR_BANK_ACCOUNT}, 
   $self->{BANK_BIC})= $q->fetchrow();
    
  return $self;
}



#**********************************************************
# List
#**********************************************************
sub list {
 my $self = shift;
 my ($attr) = @_;

 my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
 my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
 my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
 my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

 
 my $q = $db->prepare("SELECT count(a.id) FROM accounts a;");

 $q ->execute(); 
 my ($total) = $q->fetchrow();

# print "SELECT u.id, u.fio, u.deposit, u.credit, v.name, u.uid 
#     FROM users u
#     LEFT JOIN  variant v ON  (v.vrnt=u.variant) 
#     $WHERE ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;";
 
   $q = $db->prepare("SELECT a.name, a.deposit, count(u.uid), a.id
    FROM accounts a
    LEFT JOIN users u ON (u.account_id=a.id)
    GROUP BY a.id
    ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;");

 $q ->execute(); 
 my @accounts = ();
 
 while(my @account = $q->fetchrow()) {
   push @accounts, \@account;
  }

$self->{list} = \@accounts;
return $self->{list}, $total;
}





1
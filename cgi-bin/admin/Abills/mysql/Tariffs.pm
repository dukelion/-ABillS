package Tariffs;
# Tarif plans functions
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


use Accounts;

my $db;
# Customer id
my $cid; 


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
# Account
#**********************************************************
sub account {
  my $self = shift;
  my $account = Accounts->new($db);

  #print  $account->{errno};
  #print  $account->{errstr};
  
  return $account;
}






#**********************************************************
# Add
#**********************************************************
sub add {
  my $self = shift;
  my ($attr) = @_;

  my $name = (defined($attr->{NAME})) ? $attr->{NAME} : '';
  my $tax_number  = (defined($attr->{TAX_NUMBER})) ? $attr->{TAX_NUMBER} : '';
  my $bank_account = (defined($attr->{BANK_ACCOUNT})) ? $attr->{BANK_ACCOUNT} : '';
  my $bank_name = (defined($attr->{BANK_NAME})) ? $attr->{BANK_NAME} : '';
  my $cor_bank_account = (defined($attr->{COR_BANK_ACCOUNT})) ? $attr->{COR_BANK_ACCOUNT} : '';
  my $bank_bic = (defined($attr->{BANK_BIC})) ? $attr->{BANK_BIC} : '';

  my $sql = "INSERT INTO accounts (name, tax_number, bank_account, bank_name, cor_bank_account, bank_bic) 
     VALUES ('$name', '$tax_number', '$bank_account', '$bank_name', '$cor_bank_account', '$bank_bic');";

  print $sql;

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

  print $sql;

  return $self;
}


#**********************************************************
# list
#**********************************************************
sub list {
  my $self = shift;
  my ($account_id) = @_;

  my $q = $db->prepare("SELECT vrnt, name FROM variant;") || die $db->strerr;
  $q ->execute();
  my @tarrifs = ();
 
  while(my @tarrif = $q->fetchrow()) {
    push @tarrifs, \@tarrif;
   }

  $self->{list} = \@tarrifs;
  return $self->{list};

  return $self;
}


#**********************************************************
# nas_list
#**********************************************************
sub nas_list {
	my $self = shift;
	

	
	return $self;
}


#**********************************************************
# nas_add
#**********************************************************
sub nas_add {
	my $self = shift;
	
	return $self;
}


#**********************************************************
# nas_del
#**********************************************************
sub nas_del {
	my $self = shift;
  my $sql = "DELETE FROM vid_nas WHERE vid='$self->{VID}';";	

  my $q = $db->do($sql) || die $db->errstr;

  if($db->err > 0) {
     $self->{errno} = 3;
     $self->{errstr} = 'SQL_ERROR';
     return $self;
   }

#  $admin->action_add($uid, "DELETE NAS");
	return $self;
}


1
package Customers;
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
  
  return $account;
}









1
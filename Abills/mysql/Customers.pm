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


use Companies;

my $db;
my $admin;
my $CONF;
# Customer id


#**********************************************************
# Init 
#**********************************************************
sub new {
  my $class = shift;
  ($db, $admin, $CONF)=@_;
  my $self = { };
  bless($self, $class);
  return $self;
}


#**********************************************************
# Account
#**********************************************************
sub company {
  my $self = shift;
  my $Companies = Companies->new($db, $admin, $CONF);
  
  return $Companies;
}









1

package main;
use strict;

#Main SQL function

use DBI;

sub connect {
  my $class = shift;
  my $self = { };
  my ($dbhost, $dbname, $dbuser, $dbpasswd) = @_;
  bless($self, $class);
#  $self->{TEST}='testsst new';
  $self->{db} = DBI -> connect("DBI:mysql:database=$dbname;host=$dbhost", "$dbuser", "$dbpasswd") or
    die "Unable connect to server '$dbhost:$dbname' $!\n";
  return $self;
}

#**********************************************************
#  do
# type.  do 
#        list
#**********************************************************
sub query {
	my $self = shift;
  my ($query, $type, $attr)	= @_;

  
#if ($type eq 'do') {
  my  $q = $self->{db}->prepare($query);
  $q ->execute(); 
#}
#else {
#  $q = $db->prepare($query);
#  $q ->execute(); 
#}

if ($self->{db}->err == 1062) {
  $self->{errno} = 7;
  $self->{errstr} = 'ERROR_DUBLICATE';
  return $self;
 }
elsif($self->{db}->err > 0) {
  $self->{errno} = 3;
  $self->{errstr} = 'SQL_ERROR';
  return $self;
 }

$self->{rows} = $q->rows;
if ($q->rows > 0) {
  my @rows;
  while(my @row = $q->fetchrow()) {
   push @rows, \@row;
  }
  $self->{list} = \@rows;
}

  return $self;
}


1
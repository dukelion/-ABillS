package main;
use strict;

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

1
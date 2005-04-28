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
  my ($db, $query, $type, $attr)	= @_;

print "<p>$query</p>\n";

  if (defined($attr->{test})) {
  	 return $self;
   }

my $q;

if ($type eq 'do') {
  $q = $db->do($query);
  $self->{TOTAL} = 0;
}
else {
  $q = $db->prepare($query);
  $q ->execute(); 
  $self->{TOTAL} = $q->rows;
}

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

if ($self->{TOTAL} > 0) {
  my @rows;
  while(my @row = $q->fetchrow()) {
#   print "---$row[0] -";
   push @rows, \@row;
  }
  $self->{list} = \@rows;
}
else {
	delete $self->{list};
}
  return $self;
}



#**********************************************************
# get_data
#**********************************************************
sub get_data {
	my ($self) =shift;
	my ($params, $attr) = @_;
  my %DATA;
  
  if(defined($attr->{default})) {
  	 my $dhr = $attr->{default};
  	 %DATA = %$dhr;
   }
  
  while(my($k, $v)=each %$params) {
  	$DATA{$k}=$v;
#    print "--$k, $v<br>\n";
   }
  
	return %DATA;
}


1
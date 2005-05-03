package Abills::SQL;


sub connect {
  my $class = shift;
  my $self = { };
  my ($sql_type, $dbhost, $dbname, $dbuser, $dbpasswd) = @_;
  bless($self, $class);
  $self->{sql_type} = $sql_type;
  #use lib $lib;
  #unshift(@INC, "Abills/$sql_type/");
  eval { require "main.pm"; };
  if (! $@) {
    "main"->import();
   }
  else {
    print "Module '$sql_type' not supported yet";
   }

  my $sql = "main"->connect($dbhost, $dbname, $dbuser, $dbpasswd);
  $self->{db}=$sql->{db};
  $self->{mysql}=$sql;
  return $self;
}


1
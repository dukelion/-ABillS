# SQL module

 use DBI;
 $db = DBI -> connect("DBI:mysql:database=$conf{dbname};host=$conf{dbhost}", "$conf{dbuser}", "$conf{dbpasswd}")
or
 die "Unable connect to server '$conf{dbhost}'\n" . $DBI::errstr;

package main;
use strict;
#Main SQL function

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION
  $db
  $admin
  $CONF
  %DATA
  $OLD_DATA
  @WHERE_RULES
  $WHERE
  
  $SORT
  $DESC
  $PG
  $PAGE_ROWS
);

use Exporter;
$VERSION = 2.00;
@ISA = ('Exporter');

@EXPORT = qw(
  $db
  $admin
  $CONF
  @WHERE_RULES
  $WHERE
  %DATA
  %OLD_DATA
  
  $SORT
  $DESC
  $PG
  $PAGE_ROWS
);

@EXPORT_OK = ();
%EXPORT_TAGS = ();


$db    = undef;
$admin = undef;
$CONF  = undef;
@WHERE_RULES = ();
$WHERE = '';
%DATA  = ();
$OLD_DATA   = (); #all data

$SORT      = 1;
$DESC      = '';
$PG        = 0;
$PAGE_ROWS = 25;

my $query_count = 0;

use DBI;

#**********************************************************
# Connect to DB
#**********************************************************
sub connect {
  my $class = shift;
  my $self = { };
  my ($dbhost, $dbname, $dbuser, $dbpasswd, $attr) = @_;
  bless($self, $class);
  $self->{db} = DBI->connect_cached("DBI:mysql:database=$dbname;host=$dbhost", "$dbuser", "$dbpasswd") or print 
       "Content-Type: text/html\n\nError: Unable connect to DB server '$dbhost:$dbname'\n";

  #For mysql 5 or highter
  $self->{db}->do("set names ".$attr->{CHARSET}) if ($attr->{CHARSET});
 
  $self->{query_count}=0;
  return $self;
}


sub disconnect {
  my $self = shift;
  $self->{db}->disconnect;
  return $self;
}

#**********************************************************
#
#**********************************************************
sub db_version {
	my $self = shift;
  my ($attr)	= @_;

  my $version = $db->get_info( 18 ); 
  if ($version =~ /^(\d+\.\d+)/) {
   	$version = $1;
   }

  return $version;
}

#**********************************************************
#  do
# type. do 
#       list
#**********************************************************
sub query {
	my $self = shift;
  my ($db, $query, $type, $attr)	= @_;

  $self->{errstr}=undef;
  $self->{errno}=undef;
  $self->{TOTAL} = 0;
  #$self->{debug}=1;
  print "<p>$query</p>\n" if ($self->{debug});

 	 
  if (defined($attr->{test})) {
  	 return $self;
   }

my $q;

my @Array = ();
# check bind params
if ($attr->{Bind}) {
  
  foreach my $Data (@{ $attr->{Bind} }) {
    push(@Array, $Data);
    #print ref(\$Data);
#    if (ref($Data) eq 'SCALAR') {
#      push(@Array, $$Data);
#     }
#    else  {
#      $self->{errno} = 7;
#      $self->{errstr} = "No SCALAR param in Bind!";
#      return $self;
#     }

   }

 }

if ($type && $type eq 'do') {
#  print $query;
  $q = $db->do($query, undef, @Array);
  if (defined($db->{'mysql_insertid'})) {
  	 $self->{INSERT_ID} = $db->{'mysql_insertid'};
   }
 }
else {
  $q = $db->prepare($query); # || die $db->errstr;
  if($db->err) {
     $self->{errno} = 3;
     $self->{sql_errno}=$db->err;
     $self->{sql_errstr}=$db->errstr;
     $self->{errstr}=$db->errstr;
   
     return $self->{errno};
   }
  
  if ($attr->{MULTI_QUERY}) {
    foreach my $line ( @{ $attr->{MULTI_QUERY} } ) {
      $q->execute( @$line );
      if($db->err) {
        $self->{errno} = 3;

        $self->{sql_errno}=$db->err;
        $self->{sql_errstr}=$db->errstr;
        $self->{errstr}=$db->errstr;
        return $self->{errno};
       }
     }
   }
  else {
    $q->execute();
    if($db->err) {
      $self->{errno} = 3;

      $self->{sql_errno}=$db->err;
      $self->{sql_errstr}=$db->errstr;
      $self->{errstr}=$db->errstr;
      return $self->{errno};
     }
    $self->{TOTAL} = $q->rows;
  }
  $self->{Q}=$q;
#  $self->{NUM_OF_FIELDS} = $q->{NUM_OF_FIELDS};
}



if($db->err) {

  if ($db->err == 1062) {
    $self->{errno} = 7;
    $self->{errstr} = 'ERROR_DUBLICATE';
    return $self;
   }

  $self->{errno} = 3;
  $self->{errstr} = 'SQL_ERROR'; # . ( ($self->{db}->strerr) ? $self->{db}->strerr : '' );
  return $self;
 }

if ($self->{TOTAL} > 0) {
  my @rows;
  
#  if ($type && $type eq 'fields_list') {
#    my @rows_h = ();
#    while(my $row_hashref = $q->fetchrow_hashref()) {
#      push @rows_h, $row_hashref;
#     }
#  	$self->{list_hash} = \@rows_h;
#   }
#  else {
    while(my @row = $q->fetchrow()) {
      push @rows, \@row;
     }
#   }
 
  $self->{list} = \@rows;
 }
else {
	delete $self->{list};
}

 $self->{query_count}++;
 return $self;
}



#**********************************************************
# get_data
#**********************************************************
sub get_data {
	my $self=shift;
	my ($params, $attr) = @_;
  my %DATA;
  
  if(defined($attr->{default})) {
  	 %DATA = %{ $attr->{default} };
   }
  
  while(my($k, $v)=each %$params) {
  	 next if (! $params->{$k} && defined($DATA{$k})) ;
  	 $v =~ s/^ +|[ \n]+$//g if ($v);
  	 $DATA{$k}=$v;
   }
  
	return %DATA;
}


#**********************************************************
# search_expr($self, $value, $type)
#
# type of fields
# IP -  IP Address
# INT - integer
# STR - string
#**********************************************************
sub search_expr {
  my $self=shift;
  my ($value, $type, $field, $attr)=@_;

 	if ($attr->{EXT_FIELD}) {
    $self->{SEARCH_FIELDS} .= ($attr->{EXT_FIELD} ne '1') ? "$attr->{EXT_FIELD}, " : "$field, ";
    $self->{SEARCH_FIELDS_COUNT}++;
 	 }	
 
  if ($value =~ s/;/,/g ) {
  	my @val_arr     = split(/,/, $value);  
  	$value = "'". join("', '", @val_arr) ."'";
  	return [ "$field IN ($value)" ];
   }


  my @val_arr     = split(/,/, $value);  
  my @result_arr  = ();

  foreach my $v (@val_arr) { 
    my $expr = '=';

    if ($type eq 'DATE' && ( $v =~ /([=><!]{0,2})(\d{2})[\/\.\-](\d{2})[\/\.\-](\d{4})/ )) {
    	$v = "$1$4-$3-$2";
     }

    if($type eq 'INT' && $v =~ s/\*//g) {
      $expr = '>';
     }
    elsif ($v =~ s/^!//) {
    	$expr = ' <> ';
     }
    elsif ($type eq 'STR') {
    	$expr = ' LIKE ';
    	$v =~ s/\*/\%/g;
     }
    elsif ( $v =~ s/^([<>=]{1,2})// ) {
      $expr = $1;
     }
  
    if ($type eq 'IP') {
      $v = "INET_ATON('$v')";
     }
    else {
      $v="'$v'";
     }

    $value = $expr . $v;
   
    push @result_arr, "$field$value" if ($field);
   }

  if ($field) {
  	if ($type ne 'INT' && $type ne 'DATE') {
  		return [ '('. join(' or ', @result_arr)  .')']; 
  	 }
    return \@result_arr; 
   }

  return $value;
}


#**********************************************************
# change_constructor($self, $uid, $attr)
# $attr 
#  CHANGE_PARAM - chenging param
#  TABLE        - changing table
#  \%FIELDS     - fields of table
#  ...          - data
#  OLD_INFO     - OLD infomation for compare
#**********************************************************
sub changes {
  my $self = shift;
  my ($admin, $attr) = @_;
  
  my $TABLE        = $attr->{TABLE};
  my $CHANGE_PARAM = $attr->{CHANGE_PARAM};
  my $FIELDS       = $attr->{FIELDS};
  my %DATA         = $self->get_data($attr->{DATA}); 


  if (! $DATA{UNCHANGE_DISABLE} ) {
    $DATA{DISABLE} = (defined($DATA{DISABLE})) ? $DATA{DISABLE} : undef;
   }

  if(defined($DATA{EMAIL}) && $DATA{EMAIL} ne '') {
    if ($DATA{EMAIL} !~ /(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))/) {
      $self->{errno} = 11;
      $self->{errstr} = 'ERROR_WRONG_EMAIL';
      return $self;
     }
   }

  $OLD_DATA = $attr->{OLD_INFO}; #  $self->info($uid);
  if($OLD_DATA->{errno}) {
     $self->{errno}  = $OLD_DATA->{errno};
     $self->{errstr} = $OLD_DATA->{errstr};
     return $self;
   }

  my $CHANGES_QUERY = "";
  my $CHANGES_LOG = "";

  while(my($k, $v)=each(%DATA)) {
  	#print "$k, $v<br>\n";
    $OLD_DATA->{$k} = '' if (! $OLD_DATA->{$k});
    if (defined($FIELDS->{$k}) && $OLD_DATA->{$k} ne $DATA{$k}){
        if ($k eq 'PASSWORD' || $k eq 'NAS_MNG_PASSWORD') {
          $CHANGES_LOG .= "$k *->*;";
          $CHANGES_QUERY .= "$FIELDS->{$k}=ENCODE('$DATA{$k}', '$CONF->{secretkey}'),";
         }
        elsif($k eq 'IP' || $k eq 'NETMASK') {
          if ($DATA{$k} !~ /\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/) {
            $DATA{$k} = '0.0.0.0' ;
           }
          
          $CHANGES_LOG   .= "$k $OLD_DATA->{$k}->$DATA{$k};";
          $CHANGES_QUERY .= "$FIELDS->{$k}=INET_ATON('$DATA{$k}'),";
         }
        elsif($k eq 'CHANGED') {
          $CHANGES_QUERY .= "$FIELDS->{$k}=now(),";
         }
        else {
        	if (! $OLD_DATA->{$k} && ($DATA{$k} eq '0' || $DATA{$k} eq '')) {
        		next;
           }

          if ($k eq 'DISABLE') {
            if ($DATA{$k} == 0){
              $self->{ENABLE} = 1;
              $self->{DISABLE}= undef;
             }
            else {
            	$self->{DISABLE}=1;
             }
           }
          elsif($k eq 'STATUS') {
            $self->{CHG_STATUS}=$OLD_DATA->{$k}.'->'.$DATA{$k};
            $self->{'STATUS'}=$DATA{$k};
           }
          elsif($k eq 'TP_ID') {
            $self->{CHG_TP}=$OLD_DATA->{$k}.'->'.$DATA{$k};
           }
          elsif($k eq 'GID') {
            $self->{CHG_GID}=$OLD_DATA->{$k}.'->'.$DATA{$k};
           }
          elsif($k eq 'CREDIT') {
            $self->{CHG_CREDIT}=$OLD_DATA->{$k}.'->'.$DATA{$k};
           }
          else {
            $CHANGES_LOG .= "$k $OLD_DATA->{$k}->$DATA{$k};";
           }

          $CHANGES_QUERY .= "$FIELDS->{$k}='$DATA{$k}',";
         }
     }
   }



if ($CHANGES_QUERY eq '') {
  return $self->{result};	
 }
else {
  $self->{CHANGES_LOG}=$CHANGES_LOG;
}

  chop($CHANGES_QUERY);
  
  my $extended = ($attr->{EXTENDED}) ? $attr->{EXTENDED} : '' ;
  
  $self->query($db, "UPDATE $TABLE SET $CHANGES_QUERY WHERE $FIELDS->{$CHANGE_PARAM}='$DATA{$CHANGE_PARAM}'$extended", 'do');

  if($self->{errno}) {
    return $self;
   }

  $CHANGES_LOG = $attr->{EXT_CHANGE_INFO}.' '.$CHANGES_LOG if ($attr->{EXT_CHANGE_INFO});
  if (defined($DATA{UID}) && $DATA{UID} > 0 && defined($admin)) {
    if ($self->{'DISABLE'}) {
      $admin->action_add($DATA{UID}, "", { TYPE => 9, ACTION_COMMENTS => $DATA{ACTION_COMMENTS} });
     }

    if ($self->{'ENABLE'}) {
      $admin->action_add($DATA{UID}, "", { TYPE => 8 });
     }

    if ($CHANGES_LOG ne '') {
      $admin->action_add($DATA{UID}, "$CHANGES_LOG", { TYPE => 2});
     }

    if($self->{'CHG_TP'}) {
      $admin->action_add($DATA{UID}, "$self->{'CHG_TP'}", { TYPE => 3});
     }

    if($self->{CHG_GID}) {
      $admin->action_add($DATA{UID}, "$self->{CHG_GID}", { TYPE => 26 });
     }

    if(defined($self->{'STATUS'}) && $self->{'STATUS'} ne '') {
      $admin->action_add($DATA{UID}, "$self->{'STATUS'}", { TYPE => ($self->{'STATUS'}==3) ? 14 : 4 });
     }

    if($self->{CHG_CREDIT}) {
      $admin->action_add($DATA{UID}, "$self->{'CHG_CREDIT'}", { TYPE => 5 });
     }
   }
  elsif(defined($admin)) {
    if ($self->{'DISABLE'}) {
      $admin->system_action_add("$CHANGES_LOG", { TYPE => 9 });
     }
    elsif ($self->{'ENABLE'}) {
      $admin->system_action_add("$CHANGES_LOG", { TYPE => 8 });
     }
    else {
      $admin->system_action_add("$CHANGES_LOG", { TYPE => 2 });
     }
   }
  return $self->{result};
}


1

package Sqlcmd;
# SQL commander
#

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION);

use Exporter;
$VERSION = 2.00;
@ISA = ('Exporter');

@EXPORT = qw();

@EXPORT_OK = ();
%EXPORT_TAGS = ();

use main;
@ISA  = ("main");


#**********************************************************
# Init 
#**********************************************************
sub new {
  my $class = shift;
  ($db, $admin, $CONF) = @_;
  my $self = { };
  bless($self, $class);
  return $self;
}




#**********************************************************
# User information
# info()
#**********************************************************
sub info {
  my $self = shift;
  my ($attr) = @_;

 my $list;
 $SORT = ($attr->{SORT}) ? $attr->{SORT} : 0;
 $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
 my $DATE = $attr->{DATE} || '0000-00-00';

 my $type = $attr->{TYPE} || '';
 
  if ($type eq 'showtables') {
    
    if ($attr->{ACTION} && $attr->{ACTION} eq 'ROTATE') {
    	$DATE =~ s/-/\_/g;
 	    # CREATE TABLE LIKE work from version 4.1

      my $version = $self->db_version();
      if ($version < 4.1) {
      	$self->{errno}=1;
      	$self->{errstr}="MYSQL: $version. Version Lower 4.1 not support RENAME Syntax";
      	return $self;
       }

 	    my @tables_arr = split(/, /, $attr->{TABLES});
      foreach my $table (@tables_arr) {
        print "CREATE TABLE IF NOT EXISTS ". $table ."_2 LIKE $table ;".
        "RENAME TABLE $table TO $table". "_$DATE, $table". "_2 TO $table;";
        my $sth = $db->do( "CREATE TABLE IF NOT EXISTS ". $table ."_2 LIKE $table ;");
        $sth = $db->do( "RENAME TABLE $table TO $table". "_$DATE, $table". "_2 TO $table;");
       }
     }
    
    
    my $sth = $db->prepare( "SHOW TABLE STATUS FROM $CONF->{dbname}" );
    $sth->execute();
    my $pri_keys = $sth->{mysql_is_pri_key};
    my $names = $sth->{NAME};

    push @$names, 'CHECK';

    $self->{FIELD_NAMES}=$names;

    my @rows = ();
    my @row_array = ();

    while(my @row_array = $sth->fetchrow()) {
      my $i=0;
      my %Rows_hash = ();
      foreach my $line (@row_array) {
      	$Rows_hash{"$names->[$i]"}=$line;
      	$i++;
       }
      # check syntax
      if ($attr->{'fields'} =~ /CHECK/) {
        my $q = $db->prepare( "CHECK TABLE $row_array[0]");
        $q->execute();
        my @res = $q->fetchrow();
        $Rows_hash{"$names->[$i]"}="$res[2] / $res[3]";
      }
      push @rows, \%Rows_hash;
    }



    $list = \@rows;
    #show indexes
    # SHOW INDEX FROM $row_array[0];
    return $list;
  }
 elsif ($type eq 'showtriggers') {
    $self->query($db, "SHOW TRIGGERS");
 	  return $self->{list}     
  }

  return $self;
}


#**********************************************************
# maintenance()
#**********************************************************
sub maintenance  {
	
	
}

#**********************************************************
# list()
#**********************************************************
sub list {
 my $self = shift;
 my ($attr) = @_;
 my @list = ();

 $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
 $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
 $PG = ($attr->{PG}) ? $attr->{PG} : 0;
 $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

 my $search_fields = '';

 my @QUERY_ARRAY = ();
 if ($attr->{QUERY} =~ /;/) {
 	  @QUERY_ARRAY = split(/;/, $attr->{QUERY});
  }
 else {
   push @QUERY_ARRAY, $attr->{QUERY};
 }


my @rows = ();

foreach my $query (@QUERY_ARRAY) {

	next if (length($query) < 5);

  my $q = $db->prepare("$query",  { "mysql_use_result" => ($query !~ /!SELECT/gi ) ? 0 : 1   } ) || die $db->errstr;
  if($db->err) {
     $self->{errno} = 3;
     $self->{sql_errno}=$db->err;
     $self->{sql_errstr}=$db->errstr;
     $self->{errstr}=$db->errstr;
   
     return $self->{errno};
   }
  $q->execute(); 


  if($db->err) {
     $self->{errno} = 3;
     $self->{sql_errno}=$db->err;
     $self->{sql_errstr}=$db->errstr;
     $self->{errstr}="$query / ".$db->errstr;
     
     return $self;
   }
  
   $self->{MYSQL_FIELDS_NAMES}  = $q->{NAME};
   $self->{MYSQL_IS_PRIMARY_KEY}= $q->{mysql_is_pri_key};
   $self->{MYSQL_IS_NOT_NULL}   = $q->{mysql_is_not_null};
   $self->{MYSQL_LENGTH}        = $q->{mysql_length};
   $self->{MYSQL_MAX_LENGTH}    = $q->{mysql_max_length};
   $self->{MYSQL_IS_KEY}        = $q->{mysql_is_key};
   $self->{MYSQL_TYPE_NAME}     = $q->{mysql_type_name};


   $self->{TOTAL} = $q->rows;


   while(my @row = $q->fetchrow()) {
     push @rows, \@row;
    }

  return $self if($self->{errno});
  
  push @{ $self->{EXECUTED_QUERY} }, $query;
}
 
  $admin->system_action_add("SQLCMD:$attr->{QUERY}", { TYPE => 1 });    
  my $list = \@rows;
  return $list;
}

#**********************************************************
# show 
#**********************************************************
sub sqlcmd_info {
 my $self = shift;

my @row;
my %stats = ();
my %vars = ();

# Determine MySQL version
my $query = $db->prepare("SHOW VARIABLES LIKE 'version';");
$query->execute();
@row = $query->fetchrow_array();

my ($major, $minor, $patch) = ($row[1] =~ /(\d{1,2})\.(\d{1,2})\.(\d{1,2})/);

if($major == 5 && (($minor == 0 && $patch >= 2) || $minor > 0)) {
  $query = $db->prepare("SHOW GLOBAL STATUS;");
}
else { 
  $query = $db->prepare("SHOW STATUS;"); 
 }


# Get status values
$query->execute();
while(@row = $query->fetchrow_array()) { 
	$stats{$row[0]} = $row[1]; 
 }

# Get server system variables
$query = $db->prepare("SHOW VARIABLES;");
$query->execute();
while(@row = $query->fetchrow_array()) { 
	$vars{$row[0]} = $row[1]; 
 }
   
 return \%stats, \%vars;
}














#**********************************************************
# add()
#**********************************************************
sub history_add {
  my $self = shift;
  my ($attr) = @_;
  
  $self->query($db,  "INSERT INTO sqlcmd_history (datetime,
                  aid,  sql_query,  db_id,  comments)
               VALUES (now(), $admin->{AID}, '$attr->{SQL_QUERY}', '$attr->{DB_ID}', '$attr->{COMMENTS}');", 'do');

  return $self;
}


#**********************************************************
# Delete user info from all tables
#
# del(attr);
#**********************************************************
sub history_del {
  my $self = shift;
  my ($attr) = @_;
 
  my $DEL = '';
  if ($attr->{IDS}) {
  	$DEL = "id IN ('$attr->{IDS}')";
   }
  else {
    $DEL = "id='$attr->{ID}'";
   }
 
  $self->query($db, "DELETE from sqlcmd_history WHERE $DEL;", 'do');

  return $self->{result};
}

#**********************************************************
# list_allow nass
#**********************************************************
sub history_list {
  my $self = shift;
  my $list;

  $self->query($db, "SELECT datetime, comments, id FROM sqlcmd_history WHERE aid='$admin->{AID}' 
  ORDER BY 1 DESC
  LIMIT $PG, $PAGE_ROWS;");


	return $self->{list};
}



#**********************************************************
# list_allow nass
#**********************************************************
sub history_query {
  my $self = shift;
  my ($attr)=@_;


  $self->query($db, "SELECT datetime, 
   sql_query,
   comments, 
   id FROM sqlcmd_history 
   WHERE aid='$admin->{AID}' 
   AND id = '$attr->{QUERY_ID}';
   ");
   
  

  if ($self->{TOTAL} < 1){
  	 return $self;
   }

  ($self->{DATETIME},
   $self->{SQL_QUERY},
   $self->{COMENTS},
   $self->{ID}
   ) = @{ $self->{list}->[0] };

	return $self;
}



1

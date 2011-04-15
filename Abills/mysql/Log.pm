package Log;
#Make logs
 
use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION

%log_levels
);


@EXPORT_OK = qw(log_add);
@EXPORT = qw(%log_levels);

my $db;
use main;
@ISA  = ("main");
my $CONF;

# Log levels. For details see <syslog.h>
%log_levels = ('LOG_EMERG' => 0,
'LOG_ALERT'   => 1,
'LOG_CRIT'    => 2,
'LOG_ERR'     => 3,
'LOG_WARNING' => 4,
'LOG_NOTICE'  => 5,
'LOG_INFO'    => 6,
'LOG_DEBUG'   => 7,
'LOG_SQL'     => 8);

#**********************************************************
# Log new
#**********************************************************
sub new {
  my $class = shift;
  ($db, $CONF) = @_;

  my $self = { };
  bless($self, $class);

  return $self;
}


#**********************************************************
# Log list
#**********************************************************
sub log_list {
 my $self = shift;
 my ($attr) = @_;

  my @WHERE_RULES  = ();
  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;


  if(defined($attr->{USER})) {
  	push @WHERE_RULES, @{ $self->search_expr($attr->{USER}, 'STR', 'l.user') };
  }
  elsif($attr->{LOGIN_EXPR}) {
  	push @WHERE_RULES, @{ $self->search_expr($attr->{LOGIN_EXPR}, 'STR', 'l.user') };
  }

  if ($attr->{INTERVAL}) {
 	  my ($from, $to)=split(/\//, $attr->{INTERVAL}, 2);
    push @WHERE_RULES, "date_format(l.date, '%Y-%m-%d')>='$from' and date_format(l.date, '%Y-%m-%d')<='$to'";
   }

  if(defined($attr->{MESSAGE})) {
  	push @WHERE_RULES, @{ $self->search_expr($attr->{MESSAGE}, 'STR', 'l.message') };
  }

  if($attr->{DATE}) {
  	push @WHERE_RULES, @{ $self->search_expr($attr->{DATE}, 'INT', 'l.date') };
   }

  if($attr->{TIME}) {
  	push @WHERE_RULES, @{ $self->search_expr($attr->{TIME}, 'INT', 'l.time') };
   }

  if($attr->{LOG_TYPE}) {
  	push @WHERE_RULES, @{ $self->search_expr($attr->{LOG_TYPE}, 'INT', 'l.log_type') };
   }

  if($attr->{NAS_ID}) {
  	push @WHERE_RULES, @{ $self->search_expr($attr->{NAS_ID}, 'INT', 'l.nas_id') };
   }
 
 $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';
 
 $self->query($db, "SELECT l.date, l.log_type, l.action, l.user, l.message, l.nas_id
  FROM errors_log l
  $WHERE
  ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;");

 my $list = $self->{list};
 $self->{OUTPUT_ROWS}=$self->{TOTAL};

 $self->query($db, "SELECT l.log_type, count(*)
  FROM errors_log l
  $WHERE
  GROUP BY 1
  ORDER BY 1;");  

 return $list;
}



#**********************************************************
# Make log records
# log_print($self)
#**********************************************************
sub log_print  {
  my ($self, $LOG_TYPE, $USER_NAME, $MESSAGE, $attr) = @_;
  my $Nas = $attr->{NAS} || undef;
  
  if ($CONF->{debugmods} =~ /$LOG_TYPE/) {
    if ($CONF->{ERROR2DB}) {
      $self->log_add({LOG_TYPE => $log_levels{$LOG_TYPE},
                      ACTION   => $attr->{'ACTION'} || $self->{ACTION} || '', 
                      USER_NAME=> $USER_NAME || '-',
                      MESSAGE  => "$MESSAGE",
                      NAS_ID   => $Nas->{NAS_ID}
                    });
     }
    else {
    	use POSIX qw(strftime); 
    	my $DATE = strftime "%Y-%m-%d", localtime(time);
      my $TIME = strftime "%H:%M:%S", localtime(time);
      my $nas  = (defined($Nas->{NAS_ID})) ? "NAS: $Nas->{NAS_ID} ($Nas->{NAS_IP}) " : '';
      
      if(open(FILE, ">>$CONF->{LOGFILE}")) {
        print FILE "$DATE $TIME $LOG_TYPE: AUTH [$USER_NAME] $nas$MESSAGE\n";
        close(FILE);
       }
      else {
        print  "Can't open file '$CONF->{LOGFILE}' $!\n";
       }
     }

    if ($self->{PRINT} || $attr->{PRINT}) {
 	    use POSIX qw(strftime); 
    	my $DATE = strftime "%Y-%m-%d", localtime(time);
      my $TIME = strftime "%H:%M:%S", localtime(time);
      my $nas  = (defined($Nas->{NAS_ID})) ? "NAS: $Nas->{NAS_ID} ($Nas->{NAS_IP}) " : '';
      print "$DATE $TIME $LOG_TYPE: AUTH [$USER_NAME] $nas$MESSAGE\n";
    }
   }
};


#**********************************************************
# Add log records
# log_add($self)
#**********************************************************
sub log_add {
 my $self = shift;
 my ($attr) = @_;
 
 my %DATA = $self->get_data($attr); 
 # $date, $time, $log_type, $action, $user, $message
 $DATA{MESSAGE} =~ s/'/\\'/g;
 $DATA{NAS_ID}=(! $attr->{NAS_ID}) ? 0 : $attr->{NAS_ID};

 $self->query($db, "INSERT INTO errors_log (date, log_type, action, user, message, nas_id)
 values (now(), '$DATA{LOG_TYPE}', '$DATA{ACTION}', '$DATA{USER_NAME}', '$DATA{MESSAGE}',  '$DATA{NAS_ID}');", 'do');


 return 0;	
}


#**********************************************************
# Del log records
# log_del($self)
#**********************************************************
sub log_del {
 my $self = shift;
 my ($attr) = @_;
 
 my $WHERE='';
 
 if ($attr->{LOGIN}) {
 	 $WHERE = "user='$attr->{LOGIN}'";
  }
 
 $self->query($db, "DELETE FROM errors_log WHERE $WHERE;", 'do');

 return 0;	
}

1


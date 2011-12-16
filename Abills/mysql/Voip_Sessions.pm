package Voip_Sessions;
# Stats functions
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

use main;
@ISA  = ("main");

my $db;
my $admin;
my $CONF;

#**********************************************************
# Init 
#**********************************************************
sub new {
  my $class = shift;
  ($db, $admin, $CONF) = @_;
  my $self = { };
  bless($self, $class);
  
  if ($CONF->{DELETE_USER}) {
    $self->del($CONF->{DELETE_USER}, '', '', '', { DELETE_USER => $CONF->{DELETE_USER} });
   }

  return $self;
}


#**********************************************************
# del
#**********************************************************
sub del {
  my $self = shift;
  my ($uid, $session_id, $nas_id, $session_start, $attr) = @_;


  if ($attr->{DELETE_USER}) {
    $self->query($db, "DELETE FROM voip_log WHERE uid='$attr->{DELETE_USER}';", 'do');
   }
  else {
    $self->query($db, "DELETE FROM voip_log 
      WHERE uid='$uid' and start='$session_start' and nas_id='$nas_id' and acct_session_id='$session_id';", 'do');
   }

  return $self;
}


#**********************************************************
# online()
#********************************************************** 
sub online {
	my $self = shift;
	my ($attr) = @_;

 my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
 my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
 
 my $WHERE;
 
 if (defined($attr->{ZAPED})) {
 	 $WHERE = "c.status=2";
  }
 else {
   $WHERE = "c.status=1 or c.status>=3";
 } 
 
 $self->query($db, "SELECT c.user_name, 
                          pi.fio, 
                          calling_station_id,
                          called_station_id,
                          SEC_TO_TIME(UNIX_TIMESTAMP() - UNIX_TIMESTAMP(c.started)),
                          c.call_origin,
                          INET_NTOA(c.client_ip_address),
                          c.status,
                          c.nas_id,
                          c.uid,
  c.acct_session_id, 
  pi.phone, 
  service.tp_id, 
  0, 
  u.credit, 
  if(date_format(c.started, '%Y-%m-%d')=curdate(), date_format(c.started, '%H:%i:%s'), c.started)

 FROM voip_calls c
 LEFT JOIN users u     ON u.uid=c.uid
 LEFT JOIN voip_main service  ON (service.uid=u.uid)
 LEFT JOIN users_pi pi ON (pi.uid=u.uid)
 WHERE $WHERE
 ORDER BY $SORT $DESC;");
 
 if ($self->{TOTAL} < 1) {
 	 return $self;
  }


 my $list = $self->{list};
 my %dub_logins = ();
 my %nas_sorted = ();
 
 
 foreach my $line (@$list) {
 	  $dub_logins{$line->[0]}++;
    push( @{ $nas_sorted{"$line->[7]"} }, [ $line->[0], $line->[1], $line->[2], $line->[3], $line->[4], $line->[5], $line->[6], $line->[7], $line->[8], 
      
      $line->[9], $line->[10], $line->[11], 
      $line->[13], $line->[14], $line->[15], $line->[16], $line->[17], $line->[18], $line->[19], $line->[20], $line->[21], $line->[22]]);
  }
 
 
 $self->{dub_logins}=\%dub_logins;
 $self->{nas_sorted}=\%nas_sorted;

 return $self->{list};	
}


#**********************************************************
# online_del()
#********************************************************** 
sub online_del {
	my $self = shift;
	my ($attr) = @_;

  if ($attr->{SESSIONS_LIST}) {
  	my $session_list = join("', '", @{$attr->{SESSIONS_LIST}});
  	$WHERE = "acct_session_id in ( '$session_list' )";
   }
  else {
    my $NAS_ID  = (defined($attr->{NAS_ID})) ? $attr->{NAS_ID} : '';
    my $ACCT_SESSION_ID = (defined($attr->{ACCT_SESSION_ID})) ? $attr->{ACCT_SESSION_ID} : '';
    $WHERE = "nas_id='$NAS_ID'
            and acct_session_id='$ACCT_SESSION_ID'";
   }

  $self->query($db, "DELETE FROM voip_calls WHERE $WHERE;", 'do');

  return $self;
}



#**********************************************************
# Add online session to log
# online2log()
#********************************************************** 
sub online_info {
	my $self = shift;
	my ($attr) = @_;

  
  my $NAS_ID  = (defined($attr->{NAS_ID})) ? $attr->{NAS_ID} : '';
#  my $NAS_PORT        = (defined($attr->{NAS_PORT})) ? $attr->{NAS_PORT} : '';
  my $ACCT_SESSION_ID = (defined($attr->{ACCT_SESSION_ID})) ? $attr->{ACCT_SESSION_ID} : '';
  
  $self->query($db, "SELECT user_name, 
    UNIX_TIMESTAMP(started), 
    UNIX_TIMESTAMP() - UNIX_TIMESTAMP(started), 
    INET_NTOA(client_ip_address),
    lupdated,
    nas_id,
    calling_station_id,
    called_station_id,
    acct_session_id,
    conf_id,
    INET_NTOA(client_ip_address),
    call_origin
    FROM voip_calls 
    WHERE nas_id='$NAS_ID'
     and acct_session_id='$ACCT_SESSION_ID'");


  if ($self->{TOTAL} < 1) {
     $self->{errno} = 2;
     $self->{errstr} = 'ERROR_NOT_EXIST';
     return $self;
   }

  ($self->{USER_NAME}, 
   $self->{SESSION_START}, 
   $self->{ACCT_SESSION_TIME}, 
   $self->{CLIENT_IP_ADDRESS}, 
   $self->{LAST_UPDATE}, 
   $self->{NAS_ID}, 
   $self->{CALLING_STATION_ID},
   $self->{CALLED_STATION_ID},
   $self->{ACCT_SESSION_ID},
   $self->{H323_CONF_ID},
   $self->{CLIENT_IP_ADDRESS},
   $self->{H323_CALL_ORIGIN},
   $self->{CONNECT_TERM_REASON}, 
   
    )= @{ $self->{list}->[0] };


  return $self;
}




#**********************************************************
# Session zap
#**********************************************************
sub zap {
  my $self=shift;
  my ($nas_id, $acct_session_id, $nas_port_id)=@_;

  my $WHERE = ($nas_id && $acct_session_id) ? "WHERE nas_id=INET_ATON('$nas_id') and acct_session_id='$acct_session_id'" : '';
  $self->query($db, "UPDATE voip_calls SET status=2 $WHERE;", 'do');

  return $self;
}

#**********************************************************
# Session detail
#**********************************************************
sub session_detail {
 my $self = shift;	
 my ($attr) = @_;
 
 $WHERE = " and l.uid='$attr->{UID}'" if ($attr->{UID});
 
 $self->query($db, "SELECT 
  l.start,
  l.start + INTERVAL l.duration SECOND,
  l.duration,
  l.tp_id,
  tp.name,
  INET_NTOA(client_ip_address),
  l.calling_station_id,
  l.called_station_id,
  l.nas_id,
  n.name,
  n.ip,
  l.bill_id,
  u.id,
  l.uid,
  l.acct_session_id,
  l.route_id,
  l.terminate_cause,
  l.sum
 FROM (voip_log l, users u)
 LEFT JOIN tarif_plans tp ON (l.tp_id=tp.tp_id) 
 LEFT JOIN nas n ON (l.nas_id=n.id) 
 WHERE l.uid=u.uid 
 $WHERE
 and acct_session_id='$attr->{SESSION_ID}';");

  if ($self->{TOTAL} < 1) {
     $self->{errno} = 2;
     $self->{errstr} = 'ERROR_NOT_EXIST';
     return $self;
   }
 
  ($self->{START}, 
   $self->{STOP}, 
   $self->{DURATION}, 
   $self->{TP_ID}, 
   $self->{TP_NAME}, 
   $self->{IP}, 
   $self->{CALLING_STATION_ID}, 
   $self->{CALLED_STATION_ID}, 
   $self->{NAS_ID}, 
   $self->{NAS_NAME},
   $self->{NAS_IP},
   $self->{BILL_ID}, 
   $self->{LOGIN}, 
   $self->{UID}, 
   $self->{SESSION_ID},

   $self->{ROUTE_ID},
   $self->{ACCT_TERMINATE_CAUSE},
   $self->{SUM}
    )= @{ $self->{list}->[0] } ;

 return $self;
}



#**********************************************************
# Periods totals
# periods_totals($self, $attr);
#**********************************************************
sub periods_totals {
 my $self = shift;
 my ($attr) = @_;
 my $WHERE = '';
 
 if($attr->{UID})  {
   $WHERE .= ($WHERE ne '') ?  " and uid='$attr->{UID}' " : "WHERE uid='$attr->{UID}' ";
  }

 $self->query($db, "SELECT  
   SEC_TO_TIME(sum(if(date_format(start, '%Y-%m-%d')=curdate(), duration, 0))), 
   sum(if(date_format(start, '%Y-%m-%d')=curdate(), sum, 0)), 
   
   SEC_TO_TIME(sum(if(TO_DAYS(curdate()) - TO_DAYS(start) = 1, duration, 0))),
   sum(if(TO_DAYS(curdate()) - TO_DAYS(start) = 1, sum, 0)),
   
   SEC_TO_TIME(sum(if((YEAR(curdate())=YEAR(start)) and WEEK(curdate()) = WEEK(start), duration, 0))),
   sum(if((YEAR(curdate())=YEAR(start)) and WEEK(curdate()) = WEEK(start), sum, 0)),
   
   SEC_TO_TIME(sum(if(date_format(start, '%Y-%m')=date_format(curdate(), '%Y-%m'), duration, 0))),
   sum(if(date_format(start, '%Y-%m')=date_format(curdate(), '%Y-%m'), sum, 0)),
   
   SEC_TO_TIME(sum(duration)),
   sum(sum)
   
   FROM voip_log $WHERE;");
  
  (   $self->{duration_0}, 
     $self->{sum_0}, 
      $self->{duration_1},
     $self->{sum_1}, 
      $self->{duration_2}, 
     $self->{sum_2}, 
      $self->{duration_3}, 
     $self->{sum_3}, 
      $self->{duration_4},
     $self->{sum_4} ) =  @{ $self->{list}->[0] };
  
  
  return $self;	
}

#**********************************************************
# List
#**********************************************************
sub list {
 my $self = shift;
 my ($attr) = @_;

 $PG = ($attr->{PG}) ? $attr->{PG} : 0;
 $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;
 $SORT = ($attr->{SORT}) ? $attr->{SORT} : 2;
 $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

 undef @WHERE_RULES; 
 
#UID
 if ($attr->{UID}) {
    push @WHERE_RULES, "l.uid='$attr->{UID}'";
  }
 elsif ($attr->{LOGIN}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{LOGIN}, 'STR', 'u.id') };
  }

 if ($attr->{LIST_UIDS}) {
   push @WHERE_RULES, "l.uid IN ($attr->{LIST_UIDS})";
  }


#IP
 if ($attr->{IP}) {
   push @WHERE_RULES, "l.ip=INET_ATON('$attr->{IP}')";
  }

#NAS ID
 if ($attr->{NAS_ID}) {
   push @WHERE_RULES, "l.nas_id='$attr->{NAS_ID}'";
  }

#CALLING_STATION_ID
 if ($attr->{CALLING_STATION_ID}) {
   if($attr->{CALLING_STATION_ID}) {
     $attr->{CALLING_STATION_ID} =~ s/\*/\%/ig;
     push @WHERE_RULES, "l.calling_station_id LIKE '$attr->{CALLING_STATION_ID}'";
    }
   else {
     push @WHERE_RULES, "l.calling_station_id='$attr->{CALLING_STATION_ID}'";
    }
  }

#CALLED_STATION_ID
 if ($attr->{CALLED_STATION_ID}) {
   if($attr->{CALLED_STATION_ID}) {
     $attr->{CALLED_STATION_ID} =~ s/\*/\%/ig;
     push @WHERE_RULES, "l.called_station_id LIKE '$attr->{CALLED_STATION_ID}'";
    }
   else {
     push @WHERE_RULES, "l.called_station_id='$attr->{CALLED_STATION_ID}'";
    }
  }


#TARIF_PLAN
 if ($attr->{TARIF_PLAN}) {
   push @WHERE_RULES, "l.tp_id='$attr->{TARIF_PLAN}'";
  }

 #Session ID
 if ($attr->{ACCT_SESSION_ID}) {
   push @WHERE_RULES, "l.acct_session_id='$attr->{ACCT_SESSION_ID}'";
  }

 # Show groups
 if ($attr->{GIDS}) {
   push @WHERE_RULES, "u.gid IN ($attr->{GIDS})"; 
  }
 elsif ($attr->{GID}) {
   push @WHERE_RULES, "u.gid='$attr->{GID}'"; 
  }

 if ($attr->{FROM_DATE}) {
    push @WHERE_RULES, "(date_format(l.start, '%Y-%m-%d')>='$attr->{FROM_DATE}' and date_format(l.start, '%Y-%m-%d')<='$attr->{TO_DATE}')";
  }

 
#Interval from date to date
if ($attr->{INTERVAL}) {
 	 my ($from, $to)=split(/\//, $attr->{INTERVAL}, 2);
   push @WHERE_RULES, "date_format(start, '%Y-%m-%d')>='$from' and date_format(start, '%Y-%m-%d')<='$to'";
  }
#Period
elsif (defined($attr->{PERIOD})) {
   my $period = $attr->{PERIOD};   
   if ($period == 4) { $WHERE .= ''; }
   else {
     $WHERE .= ($WHERE ne '') ? ' and ' : 'WHERE ';
     if($period == 0)    {  push @WHERE_RULES, "date_format(start, '%Y-%m-%d')=curdate()"; }
     elsif($period == 1) {  push @WHERE_RULES, "TO_DAYS(curdate()) - TO_DAYS(l.start) = 1 ";  }
     elsif($period == 2) {  push @WHERE_RULES, "YEAR(curdate()) = YEAR(l.start) and (WEEK(curdate()) = WEEK(start)) ";  }
     elsif($period == 3) {  push @WHERE_RULES, "date_format(start, '%Y-%m')=date_format(curdate(), '%Y-%m') "; }
     elsif($period == 5) {  push @WHERE_RULES, "date_format(start, '%Y-%m-%d')='$attr->{DATE}' "; }
     else {$WHERE .= "date_format(start, '%Y-%m-%d')=curdate() "; }
    }
 }
elsif($attr->{DATE}) {
	 push @WHERE_RULES, "date_format(start, '%Y-%m-%d')='$attr->{DATE}'";
}
#else {
#	 push @WHERE_RULES, "date_format(start, '%Y-%m-%d')=curdate()";
#}
#From To


 push @WHERE_RULES, "u.uid=l.uid";
 $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';


 $self->query($db, "SELECT 
 u.id, 
 l.start, 
 SEC_TO_TIME(l.duration), 
 l.tp_id,
 l.calling_station_id, 
 l.called_station_id,
 l.nas_id, 
 INET_NTOA(l.client_ip_address), 
 l.sum,
 l.acct_session_id, 
 l.bill_id, 
 l.uid,
 UNIX_TIMESTAMP(l.start),
 l.duration
  FROM (voip_log l, users u)
  $WHERE
  ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;");

 my $list = $self->{list};


 if ($self->{TOTAL} > 0) {
    $self->query($db, "SELECT count(*), SEC_TO_TIME(sum(l.duration)), sum(sum)  
      FROM (voip_log l, users u)
     $WHERE;");

    ($self->{TOTAL},
     $self->{DURATION},
     $self->{SUM}) = @{ $self->{list}->[0] };
  }

return $list;
}


#**********************************************************
# session calculation
# min max average
#**********************************************************
sub calculation {
	my ($self) = shift;
	my ($attr) = @_;

  my $WHERE;

#Login
  if ($attr->{UID}) {
    $WHERE .= ($WHERE ne '') ?  " and l.uid='$attr->{UID}' " : "WHERE l.uid='$attr->{UID}' ";
   }

  $self->query($db, "SELECT SEC_TO_TIME(min(l.duration)), SEC_TO_TIME(max(l.duration)), SEC_TO_TIME(avg(l.duration)),
  min(l.sum), max(l.sum), avg(l.sum)
  FROM voip_log l $WHERE");

  ($self->{min_dur}, 
   $self->{max_dur}, 
   $self->{avg_dur}, 
   $self->{min_sum}, 
   $self->{max_sum}, 
   $self->{avg_sum}) =  @{ $self->{list}->[0] };

	return $self;
}


#**********************************************************
# Use
#**********************************************************
sub reports {
	my ($self) = shift;
	my ($attr) = @_;

 undef @WHERE_RULES;
 my $date = '';

 
 if (defined($attr->{MONTH})) {
 	 push @WHERE_RULES, "date_format(l.start, '%Y-%m')='$attr->{MONTH}'";
   $date = "date_format(l.start, '%Y-%m-%d')";
  } 
 else {
 	 $date = "date_format(l.start, '%Y-%m')";
  }

 # Show groups
 if ($attr->{GIDS}) {
   push @WHERE_RULES, "u.gid IN ($attr->{GIDS})"; 
  }
 elsif ($attr->{GID}) {
   push @WHERE_RULES, "u.gid='$attr->{GID}'"; 
  }

 if ($attr->{DATE}) {
  push @WHERE_RULES, "date_format(l.start, '%Y-%m-%d')='$attr->{DATE}'";
 }

 my $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';

 if(defined($attr->{DATE})) {
   $self->query($db, "select date_format(l.start, '%Y-%m-%d'), if(u.id is NULL, CONCAT('> ', l.uid, ' <'), u.id), count(l.uid), 
     sec_to_time(sum(l.duration)), sum(l.sum), l.uid
      FROM voip_log l
      LEFT JOIN users u ON (u.uid=l.uid)
      $WHERE 
      GROUP BY l.uid 
      ORDER BY $SORT $DESC");
  }
 else {
  $self->query($db, "select $date, count(DISTINCT l.uid), 
      count(l.uid),
      sec_to_time(sum(l.duration)), 
      sum(l.sum)
       FROM voip_log l
       LEFT JOIN users u ON (u.uid=l.uid)
       $WHERE    
       GROUP BY 1 
       ORDER BY $SORT $DESC;");
  }

  my $list = $self->{list}; 

  $self->{USERS}=0; 
  $self->{SESSIONS}=0; 
  $self->{DURATION}=0; 
  $self->{SUM}=0;
  
  return $list if ($self->{TOTAL} < 1);

  $self->query($db, "select count(DISTINCT l.uid), 
      count(l.uid),
      sec_to_time(sum(l.duration)), 
      sum(l.sum)
       FROM voip_log l
       LEFT JOIN users u ON (u.uid=l.uid)
       $WHERE;");

   my $a_ref = $self->{list}->[0];
 
  ($self->{USERS}, 
   $self->{SESSIONS}, 
   $self->{DURATION}, 
   $self->{SUM}) = @$a_ref;



	return $list;
}




1

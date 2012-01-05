package Ipn;
# Ipn functions
#
#


use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION
);

use Exporter;
$VERSION = 2.00;
@ISA = ('Exporter');
@EXPORT = qw( );

@EXPORT_OK = ();
%EXPORT_TAGS = ();


use Abills::Base qw(ip2int int2ip);
use main;
@ISA  = ("main");


require Billing;
Billing->import();
my $Billing;

use POSIX qw(strftime);
my $DATE = strftime "%Y-%m-%d", localtime(time);
my ($Y, $M, $D)=split(/-/, $DATE, 3);

my %ips = ();
my $db;
my $CONF;
my $debug = 0;

my %intervals = ();
my %tp_interval = ();


my @zoneids;
my @clients_lst = ();

#**********************************************************
# Init 
#**********************************************************
sub new {
  my $class = shift;
  ($db, $CONF) = @_;
  my $self = { };
  bless($self, $class);

  $admin->{MODULE}='Ipn';
 
  if (! defined($CONF->{KBYTE_SIZE})){
  	$CONF->{KBYTE_SIZE}=1024;
   }

  $CONF->{MB_SIZE} = $CONF->{KBYTE_SIZE} * $CONF->{KBYTE_SIZE};

  if ($CONF->{DELETE_USER}) {
    $self->user_del({ UID => $CONF->{DELETE_USER} });
   }
  
  $self->{TRAFFIC_ROWS}=0;
  $Billing = Billing->new($db, $CONF);
  return $self;
}


#**********************************************************
# Delete user log
# user_del 
#**********************************************************
sub user_del {
  my $self = shift;
  my ($attr) = @_;
 
  $self->query($db, "DELETE FROM ipn_log WHERE uid='$attr->{UID}';", 'do');
  #$admin->action_add($attr->{UID}, "$attr->{UID}", { TYPE => 10 });
  return $self;   
}



#**********************************************************
# status
#**********************************************************
sub user_status {
 my $self = shift;
 my ($DATA) = @_;

 my $SESSION_START = 'now()';
 my $sql = "INSERT INTO dv_calls
   (status, 
    user_name, 
    started, 
    lupdated, 
    nas_port_id, 
    acct_session_id, 
    framed_ip_address, 
    CID, 
    CONNECT_INFO, 
    nas_id,
    uid,
    tp_id
)
    values (
    '$DATA->{ACCT_STATUS_TYPE}', 
    \"$DATA->{USER_NAME}\", 
    $SESSION_START, 
    UNIX_TIMESTAMP(), 
    '$DATA->{NAS_PORT}', 
    \"$DATA->{ACCT_SESSION_ID}\",
     INET_ATON('$DATA->{FRAMED_IP_ADDRESS}'), 
    '$DATA->{CALLING_STATION_ID}', 
    '$DATA->{CONNECT_INFO}', 
    '$DATA->{NAS_ID}',
    '$DATA->{UID}',
    '$DATA->{TP_ID}'
  );";

  $self->query($db, "$sql", 'do');
 return $self;
}


#**********************************************************
# traffic_add_log
#**********************************************************
sub traffic_recalc {
  my $self = shift;
  my ($attr) = @_;
 
  $self->query($db, "  UPDATE ipn_log SET
     sum='$attr->{SUM}'
   WHERE 
         uid='$attr->{UID}' and 
         start='$attr->{START}' and 
         traffic_class='$attr->{TRAFFIC_CLASS}' and 
         traffic_in='$attr->{IN}' and 
         traffic_out='$attr->{OUT}' and
         session_id='$attr->{SESSION_ID}';", 'do');

  return $self;
}

#**********************************************************
# traffic_add_log
#**********************************************************
sub traffic_recalc_bill {
  my $self = shift;
  my ($attr) = @_;
 
  $self->query($db, "UPDATE bills SET
      deposit=deposit + $attr->{SUM}
    WHERE 
    id='$attr->{BILL_ID}';", 'do');

  return $self;
}

#**********************************************************
# Acct_stop
#**********************************************************
sub acct_stop {
  my $self = shift;
  my ($attr) = @_;

  my $WHERE = '';
  if (defined($attr->{SESSION_ID})) {
  	$WHERE="acct_session_id='$attr->{SESSION_ID}'";
   }
  elsif ($attr->{USER_NAME} && $attr->{NAS_ID} && $attr->{STATUS}) {
  	$WHERE="user_name='$attr->{USER_NAME}' AND calls.nas_id='$attr->{NAS_ID}' AND  status='$attr->{STATUS}' ";
   }
  else {
    return $self;
   }

  my $ACCT_TERMINATE_CAUSE = (defined($attr->{ACCT_TERMINATE_CAUSE})) ? $attr->{ACCT_TERMINATE_CAUSE} : 0;

  my	$sql="select u.uid, calls.framed_ip_address, 
      calls.user_name,
      calls.acct_session_id,
      calls.acct_input_octets,
      calls.acct_output_octets,
      dv.tp_id,
      if(u.company_id > 0, cb.id, b.id),
      if(c.name IS NULL, b.deposit, cb.deposit)+u.credit,
      calls.started,
      UNIX_TIMESTAMP()-UNIX_TIMESTAMP(calls.started),
      nas_id,
      nas_port_id
    FROM (dv_calls calls, users u)
      LEFT JOIN companies c ON (u.company_id=c.id)
      LEFT JOIN bills b ON (u.bill_id=b.id)
      LEFT JOIN bills cb ON (c.bill_id=cb.id)
      LEFT JOIN dv_main dv ON (u.uid=dv.uid)
    WHERE u.uid=calls.uid and $WHERE;";



  $self->query($db, $sql);
  
  if ($self->{TOTAL} < 1){
  	 $self->{errno}=2;
  	 $self->{errstr}='ERROR_NOT_EXIST';
  	 return $self;
   }


  ($self->{UID},
   $self->{FRAMED_IP_ADDRESS},
   $self->{USER_NAME},
   $self->{ACCT_SESSION_ID},
   $self->{INPUT_OCTETS},
   $self->{OUTPUT_OCTETS},
   $self->{TP_ID},
   $self->{BILL_ID},
   $self->{DEPOSIT},
   $self->{START},
   $self->{ACCT_SESSION_TIME},
   $self->{NAS_ID},
   $self->{NAS_PORT}
  ) = @{ $self->{list}->[0] };
 
 $self->query($db, "SELECT sum(l.traffic_in), 
   sum(l.traffic_out),
   sum(l.sum),
   l.nas_id
   from ipn_log l
   WHERE session_id='$self->{ACCT_SESSION_ID}'
   GROUP BY session_id  ;");  


  if ($self->{TOTAL} < 1) {
    $self->{TRAFFIC_IN} = 0;
    $self->{TRAFFIC_OUT}= 0;
    $self->{SUM}        = 0;
    $self->{NAS_ID}     = 0;
    $self->query($db, "DELETE from dv_calls WHERE acct_session_id='$self->{ACCT_SESSION_ID}';", 'do');
    return $self;
  }
  
  ($self->{TRAFFIC_IN},
   $self->{TRAFFIC_OUT},
   $self->{SUM}
  ) = @{ $self->{list}->[0] };

 
  $self->{GW_INPUT_OCTETS}=0; 
  $self->{GW_OUTPUT_OCTETS}=0;
  if ($self->{INPUT_OCTETS} > 4294967294) {
  	$self->{GW_INPUT_OCTETS} = int($self->{INPUT_OCTETS} / 4294967294);
  	$self->{INPUT_OCTETS}=$self->{INPUT_OCTETS} % 4294967294;
   }

  if ($self->{OUTPUT_OCTETS} > 4294967294) {
  	$self->{GW_OUTPUT_OCTETS} = int($self->{OUTPUT_OCTETS} / 4294967294);
  	$self->{OUTPUT_OCTETS}=$self->{OUTPUT_OCTETS} % 4294967294;
   }


  $self->query($db, "INSERT INTO dv_log (uid, 
    start, 
    tp_id, 
    duration, 
    sent, 
    recv, 
    minp, 
    kb,  
    sum, 
    nas_id, 
    port_id,
    ip, 
    CID, 
    sent2, 
    recv2, 
    acct_session_id, 
    bill_id,
    terminate_cause,
    acct_input_gigawords,
    acct_output_gigawords
    ) 
        VALUES ('$self->{UID}', '$self->{START}', '$self->{TP_ID}', 
          '$self->{ACCT_SESSION_TIME}', 
          '$self->{OUTPUT_OCTETS}', '$self->{INPUT_OCTETS}', 
          '0', '0', '$self->{SUM}', '$self->{NAS_ID}',
          '$self->{NAS_PORT}', 
          '$self->{FRAMED_IP_ADDRESS}', 
          '',
          '0', 
          '0',  
          '$self->{ACCT_SESSION_ID}', 
          '$self->{BILL_ID}',
          '$ACCT_TERMINATE_CAUSE',
          '$self->{GW_INPUT_OCTETS}', 
          '$self->{GW_OUTPUT_OCTETS}'
       );", 'do');

  $self->query($db, "DELETE from dv_calls WHERE acct_session_id='$self->{ACCT_SESSION_ID}';", 'do');
}


#**********************************************************
# List
#**********************************************************
sub list {
 my $self = shift;
 my ($attr) = @_;

 undef @WHERE_RULES; 

 my $table_name = "ipn_traf_log_". $Y."_".$M;

 my $GROUP = '';
 my $size  = 'size';
 
 if ($attr->{GROUPS}) {
 	  $GROUP = "GROUP BY $attr->{GROUPS}";
 	  $size = "sum(size)";
  }


if ($attr->{SRC_ADDR}) {
   push @WHERE_RULES, "src_addr=INET_ATON('$attr->{SRC_ADDR}')";
 }

if (defined($attr->{SRC_PORT}) && $attr->{SRC_PORT} =~ /^\d+$/) {
   push @WHERE_RULES, "src_port='$attr->{SRC_PORT}'";
 }

if ($attr->{DST_ADDR}) {
   push @WHERE_RULES, "dst_addr=INET_ATON('$attr->{DST_ADDR}')";
 }

if (defined($attr->{DST_PORT}) && $attr->{DST_PORT} =~ /^\d+$/ ) {
   push @WHERE_RULES, "dst_port='$attr->{DST_PORT}'";
 }



my $f_time = 'f_time';


#Interval from date to date
if ($attr->{INTERVAL}) {
 	my ($from, $to)=split(/\//, $attr->{INTERVAL}, 2);
  push @WHERE_RULES, "date_format(f_time, '%Y-%m-%d')>='$from' and date_format(f_time, '%Y-%m-%d')<='$to'";
 }
#Period
elsif (defined($attr->{PERIOD})) {
   my $period = $attr->{PERIOD} || 0;   
   if ($period == 4) { $WHERE .= ''; }
   else {
     $WHERE .= ($WHERE ne '') ? ' and ' : 'WHERE ';
     if($period == 0)    {  push @WHERE_RULES, "date_format(f_time, '%Y-%m-%d')=curdate()"; }
     elsif($period == 1) {  push @WHERE_RULES, "TO_DAYS(curdate()) - TO_DAYS(f_time) = 1 ";  }
     elsif($period == 2) {  push @WHERE_RULES, "YEAR(curdate()) = YEAR(f_time) and (WEEK(curdate()) = WEEK(f_time)) ";  }
     elsif($period == 3) {  push @WHERE_RULES, "date_format(f_time, '%Y-%m')=date_format(curdate(), '%Y-%m') "; }
     elsif($period == 5) {  push @WHERE_RULES, "date_format(f_time, '%Y-%m-%d')='$attr->{DATE}' "; }
     else {$WHERE .= "date_format(f_time, '%Y-%m-%d')=curdate() "; }
    }
 }
elsif($attr->{DATE}) {
	 push @WHERE_RULES, "date_format(f_time, '%Y-%m-%d')='$attr->{DATE}'";
}


my $lupdate = '';

if ($attr->{INTERVAL_TYPE} eq 3) {
  $lupdate = "DATE_FORMAT(f_time, '%Y-%m-%d')";	
  $GROUP="GROUP BY 1";
  $size = 'sum(size)';
}
elsif($attr->{INTERVAL_TYPE} eq 2) {
  $lupdate = "DATE_FORMAT(f_time, '%Y-%m-%d %H')";	
  $GROUP="GROUP BY 1";
  $size = 'sum(size)';
}
#elsif($attr->{INTERVAL_TYPE} eq 'sessions') {
#	$WHERE = '';
#  $lupdate = "f_time";
#  $GROUP=2;
#}
else {
  $lupdate = "f_time";
}



 $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';




#$PAGE_ROWS = 10;

 $self->query($db, "SELECT 
  $lupdate,
  $size,
  INET_NTOA(src_addr),
  src_port,
  INET_NTOA(dst_addr),
  dst_port,

  protocol
  FROM $table_name
  $WHERE
  $GROUP
  ORDER BY $SORT $DESC 
  LIMIT $PG, $PAGE_ROWS
  ;");


  #

 my $list = $self->{list};

 $self->query($db, "SELECT 
  count(*),  sum(size)
  from $table_name
  ;");

  ($self->{COUNT},
   $self->{SUM}) = @{ $self->{list}->[0] };


  return $list;
}


#**********************************************************
# host_list
#**********************************************************
sub hosts_list {
  my $self = shift;
  my ($attr) = @_;
	
	
}


#**********************************************************
#
#**********************************************************
sub stats {
 my $self=shift;
 my ($attr) = @_;
 
 undef @WHERE_RULES;  
 
 if ($attr->{UID}) {
     push @WHERE_RULES, "l.uid='$attr->{UID}'"; 	
  }

 if ($attr->{SESSION_ID}) {
     push @WHERE_RULES, "l.session_id='$attr->{SESSION_ID}'"; 	
  }


 if ($attr->{UID}) {
 	
 }
 
 my $GROUP = 'l.uid, l.ip, l.traffic_class';

 $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';
 $self->query($db, "SELECT u.id, min(l.start), INET_NTOA(l.ip), 
   l.traffic_class,
   tt.descr,
   sum(l.traffic_in), sum(l.traffic_out),
   sum(sum),
   l.nas_id
   from (ipn_log l)
   LEFT join  users u ON (l.uid=u.uid)
   LEFT join  trafic_tarifs tt ON (l.interval_id=tt.interval_id and l.traffic_class=tt.id)
   $WHERE 
   GROUP BY $GROUP
  ;");
  #

 my $list = $self->{list};


 $self->query($db, "SELECT 
  count(*),  sum(l.traffic_in), sum(l.traffic_out)
  from  ipn_log l
  $WHERE
  ;");

  ($self->{COUNT},
   $self->{SUM}) = @{ $self->{list}->[0] };


  return $list;
}


#**********************************************************
#
#**********************************************************
sub reports_users {
 my $self=shift;
 my ($attr) = @_;
 
 $self->query($db, "SET SQL_BIG_SELECTS=1;");

my $GROUP   = '1';
my $date    = '';
 
 undef @WHERE_RULES;  
 if ($attr->{UID}) {
   push @WHERE_RULES, "l.uid='$attr->{UID}'"; 	
   $date = " DATE_FORMAT(start, '%Y-%m-%d'), l.traffic_class, tt.descr";
   $GROUP = '1, 2';
  }
 else {
   $date = " DATE_FORMAT(start, '%Y-%m-%d'), count(DISTINCT l.uid) ";
  }

if ($attr->{SESSION_ID}) {
	push @WHERE_RULES, "session_id='$attr->{SESSION_ID}'";
}
 
 #Interval from date to date
if ($attr->{INTERVAL}) {
 	my ($from, $to)=split(/\//, $attr->{INTERVAL}, 2);
  push @WHERE_RULES, "date_format(start, '%Y-%m-%d')>='$from' and date_format(start, '%Y-%m-%d')<='$to'";

   $attr->{TYPE}='-' if (! $attr->{TYPE});
   if ($attr->{TYPE} eq 'HOURS' ) {
     $date = "date_format(l.start, '\%H'), count(DISTINCT l.uid)";
    }
   elsif ($attr->{TYPE} eq 'DAYS_TCLASS') {
     $date = "date_format(l.start, '%Y-%m-%d'), '-', l.traffic_class, tt.descr";
     $GROUP = '1,3';
    }
   elsif ($attr->{TYPE} eq 'DAYS') {
     $date = "date_format(l.start, '%Y-%m-%d'), count(DISTINCT l.uid)";
    }
   elsif ($attr->{TYPE} eq 'TP') {
     $date = "l.tp_id";
    }
   elsif ($attr->{TYPE} eq 'TERMINATE_CAUSE') {
   	 $date = "l.terminate_cause"
    }
   elsif ($attr->{TYPE} eq 'GID') {
     $date = "u.gid"
    }
#   elsif ($attr->{GID} eq 'GID') {
#   	 $date = "u.gid"
#    }
#   else {
#     $date = "u.id";   	
#    }  

 }
#Period
elsif (defined($attr->{PERIOD})) {
   my $period = $attr->{PERIOD} || 0;   
   if ($period == 4) { $WHERE .= ''; }
   else {
     $WHERE .= ($WHERE ne '') ? ' and ' : 'WHERE ';
     if($period == 0)    {  push @WHERE_RULES, "date_format(start, '%Y-%m-%d')=curdate()"; }
     elsif($period == 1) {  push @WHERE_RULES, "TO_DAYS(curdate()) - TO_DAYS(start) = 1 ";  }
     elsif($period == 2) {  push @WHERE_RULES, "YEAR(curdate()) = YEAR(start) and (WEEK(curdate()) = WEEK(start)) ";  }
     elsif($period == 3) {  push @WHERE_RULES, "date_format(start, '%Y-%m')=date_format(curdate(), '%Y-%m') "; }
     elsif($period == 5) {  push @WHERE_RULES, "date_format(start, '%Y-%m-%d')='$attr->{DATE}' "; }
     else {$WHERE .= "date_format(start, '%Y-%m-%d')=curdate() "; }
    }
 }
elsif($attr->{HOUR}) {
   push @WHERE_RULES, "date_format(start, '%Y-%m-%d %H')='$attr->{HOUR}'";
	 $GROUP = "1, 2, 3";
	 $date = "DATE_FORMAT(start, '%Y-%m-%d %H'), u.id, l.traffic_class, tt.descr ";
 }
elsif($attr->{DATE}) {
	 push @WHERE_RULES, "date_format(start, '%Y-%m-%d')='$attr->{DATE}'";

   if ($attr->{UID}) {
   	 $GROUP = "1, 2";
     #push @WHERE_RULES, "l.uid='$attr->{UID}'"; 	
     $date = " DATE_FORMAT(start, '%Y-%m-%d %H'), l.traffic_class, tt.descr";
    }
   elsif($attr->{HOURS}) {
   	 $GROUP = "1, 3";
	   $date = "DATE_FORMAT(start, '%Y-%m-%d %H'), count(DISTINCT u.id), l.traffic_class, tt.descr ";
    }
   else {
   	 $GROUP = "1, 2, 3";
	   $date = "DATE_FORMAT(start, '%Y-%m-%d'), u.id, l.traffic_class, tt.descr ";
	  }
}
elsif (defined($attr->{MONTH})) {
 	 push @WHERE_RULES, "date_format(l.start, '%Y-%m')='$attr->{MONTH}'";
 } 
else {
 	 $date = "date_format(l.start, '%Y-%m'), count(DISTINCT u.id), "; 
 }

if ($attr->{FROM_TIME} && $attr->{TO_TIME}) {
	if ($attr->{FROM_TIME}ne'00:00:00' || $attr->{TO_TIME} ne '24:00:00') {
		push @WHERE_RULES, "(date_format(l.start, '%H-%i')>='$attr->{FROM_TIME}' AND date_format(l.start, '%H-%i')<='$attr->{TO_TIME}' )";
	 }
}

# Show groups
 if ($attr->{GIDS}) {
   push @WHERE_RULES, "u.gid IN ($attr->{GIDS})"; 
  }
 elsif ($attr->{GID}) {
   push @WHERE_RULES, "u.gid='$attr->{GID}'"; 
  }




# Compnay
 if ($attr->{COMPANY_ID}) {
   push @WHERE_RULES, "u.company_id=$attr->{COMPANY_ID}"; 
  }

 $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';

 $self->query($db, "SELECT $date,
   sum(l.traffic_in), sum(l.traffic_out), sum(l.sum),
   l.nas_id, l.uid
   from ipn_log l
   LEFT join  users u ON (l.uid=u.uid)
   LEFT join  trafic_tarifs tt ON (l.interval_id=tt.interval_id and l.traffic_class=tt.id)
   $WHERE 
   GROUP BY $GROUP
  ;");
  #

 my $list = $self->{list};


 $self->query($db, "SELECT 
  count(*),  sum(l.traffic_in), sum(l.traffic_out)
  from  ipn_log l

  $WHERE
  ;");

  ($self->{COUNT},
   $self->{SUM}) = @{ $self->{list}->[0] };

  return $list;
}




#**********************************************************
#
#**********************************************************
sub reports {
 my $self = shift;
 my ($attr) = @_;

 my $table_name = "ipn_traf_log_". $Y."_".$M;
 undef @WHERE_RULES; 
 my $GROUP = '';
 my $size  = 'size';
 
 if ($attr->{GROUPS}) {
 	  $GROUP = "GROUP BY $attr->{GROUPS}";
 	  $size = "sum(size)";
  }

if ($attr->{SRC_ADDR}) {
   push @WHERE_RULES, "src_addr=INET_ATON('$attr->{SRC_ADDR}')";
 }

if (defined($attr->{SRC_PORT}) && $attr->{SRC_PORT} =~ /^\d+$/) {
   push @WHERE_RULES, "src_port='$attr->{SRC_PORT}'";
 }

if ($attr->{DST_ADDR}) {
   push @WHERE_RULES, "dst_addr=INET_ATON('$attr->{DST_ADDR}')";
 }

if (defined($attr->{DST_PORT}) && $attr->{DST_PORT} =~ /^\d+$/ ) {
   push @WHERE_RULES, "dst_port='$attr->{DST_PORT}'";
 }

my $f_time = 'f_time';
#Interval from date to date
if ($attr->{INTERVAL}) {
 	my ($from, $to)=split(/\//, $attr->{INTERVAL}, 2);
  push @WHERE_RULES, "date_format(f_time, '%Y-%m-%d')>='$from' and date_format(f_time, '%Y-%m-%d')<='$to'";
 }
#Period
elsif (defined($attr->{PERIOD})) {
   my $period = $attr->{PERIOD} || 0;   
   if ($period == 4) { $WHERE .= ''; }
   else {
     $WHERE .= ($WHERE ne '') ? ' and ' : 'WHERE ';
     if($period == 0)    {  push @WHERE_RULES, "date_format(f_time, '%Y-%m-%d')=curdate()"; }
     elsif($period == 1) {  push @WHERE_RULES, "TO_DAYS(curdate()) - TO_DAYS(f_time) = 1 ";  }
     elsif($period == 2) {  push @WHERE_RULES, "YEAR(curdate()) = YEAR(f_time) and (WEEK(curdate()) = WEEK(f_time)) ";  }
     elsif($period == 3) {  push @WHERE_RULES, "date_format(f_time, '%Y-%m')=date_format(curdate(), '%Y-%m') "; }
     elsif($period == 5) {  push @WHERE_RULES, "date_format(f_time, '%Y-%m-%d')='$attr->{DATE}' "; }
     else {$WHERE .= "date_format(f_time, '%Y-%m-%d')=curdate() "; }
    }
 }
elsif($attr->{HOUR}) {
   push @WHERE_RULES, "date_format(f_time, '%Y-%m-%d %H')='$attr->{HOUR}'";
 }
elsif($attr->{DATE}) {
	 push @WHERE_RULES, "date_format(f_time, '%Y-%m-%d')='$attr->{DATE}'";
}


my $lupdate = '';

if ($attr->{INTERVAL_TYPE} eq 3) {
  $lupdate = "DATE_FORMAT(f_time, '%Y-%m-%d')";	
  $GROUP="GROUP BY 1";
  $size = 'sum(size)';
}
elsif($attr->{INTERVAL_TYPE} eq 2) {
  $lupdate = "DATE_FORMAT(f_time, '%Y-%m-%d %H')";	
  $GROUP="GROUP BY 1";
  $size = 'sum(size)';
}
else {
  $lupdate = "f_time";
}

 $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';
 my $list;

if (defined($attr->{HOSTS})) {
 	 $self->query($db, "SELECT INET_NTOA(src_addr), sum(size), count(*)
     from $table_name
     $WHERE
     GROUP BY 1
    ORDER BY 2 DESC 
    LIMIT $PG, $PAGE_ROWS;");
   $self->{HOSTS_LIST_FROM} = $self->{list};

 	 $self->query($db, "SELECT INET_NTOA(dst_addr), sum(size), count(*)
     from $table_name
     $WHERE
     GROUP BY 1
    ORDER BY 2 DESC 
    LIMIT $PG, $PAGE_ROWS;");
   $self->{HOSTS_LIST_TO} = $self->{list};
 }
elsif (defined($attr->{PORTS})) {
 	 $self->query($db, "SELECT src_port, sum(size), count(*)
     from  $table_name
     $WHERE
     GROUP BY 1
    ORDER BY 2 DESC 
    LIMIT $PG, $PAGE_ROWS;");
   $self->{PORTS_LIST_FROM} = $self->{list};

 	 $self->query($db, "SELECT dst_port, sum(size), count(*)
     from  $table_name
     $WHERE
     GROUP BY 1
    ORDER BY 2 DESC 
    LIMIT $PG, $PAGE_ROWS;");
   $self->{PORTS_LIST_TO} = $self->{list};
 }
else {
#$PAGE_ROWS = 10;
 $self->query($db, "SELECT   $lupdate,
   sum(if(src_port=0 && (src_port + dst_port>0), size, 0)),
   sum(if(dst_port=0 && (src_port + dst_port>0), size, 0)),
   sum(if(src_port=0 && dst_port=0, size, 0)),
   sum(size),
   count(*)
   from  $table_name
   $WHERE
   $GROUP
  ORDER BY $SORT $DESC 
  LIMIT $PG, $PAGE_ROWS;
  ;");
}

 $list = $self->{list};

 $self->query($db, "SELECT 
  count(*),  suuuuuuum(size)
  from  $table_name
  $WHERE
  ;");

  ($self->{COUNT},
   $self->{SUM}) = @$self->{list}->[0];
 return $list;
}



sub is_client_ip($) {
  my $self = shift;
  my $ip = shift @_;

    if ($self->{debug}) { print "--- CALL is_client_ip($ip),\t\$#clients_lst = $#clients_lst\n"; }
    if ($#clients_lst < 0) {return 0;} # nienie iono!
    foreach my $i (@clients_lst) {
	    if ($i eq $ip) { return 1; }
     }
    if ($self->{debug}) { print "         Client $ip not found in \@clients_lst\n"; }
    return 0;
}

# ii?aaaeyao iaee?ea yeaiaioa a ianneaa (iannea ii nnueea)
sub is_exist($$) {
    my ($arrayref, $elem) = @_;
    # anee nienie iono, n?eoaai, ?oi yeaiaio a iaai iiiaaaao
    if ($#{@$arrayref} == -1) { return 1; }
    
    foreach my $e (@$arrayref) {
	    if ($e eq $elem) { return 1; }
     }
    
    return 0;
}


#**********************************************************
#
#**********************************************************
sub comps_list {
 my $self = shift;
 my ($attr) = @_;
 
 $self->query($db, "SELECT number, name, INET_NTOA(ip), cid, id FROM ipn_club_comps
  ORDER BY $SORT $DESC ;");
 
  my $list = $self->{list};
  return $list;
}

#**********************************************************
#
#**********************************************************
sub comps_add {
 my $self = shift;
 my ($attr) = @_;

  $self->query($db, "INSERT INTO ipn_club_comps (number, name, ip, cid)
  values ('$attr->{NUMBER}', '$attr->{NAME}', INET_ATON('$attr->{IP}'), '$attr->{CID}');", 'do');

}

#**********************************************************
#
#**********************************************************
sub comps_info {
 my $self = shift;
 my ($id) = @_;
 
  $self->query($db, "SELECT 
  number,
  name,
  INET_NTOA(ip),
  cid
  FROM ipn_club_comps
  WHERE id='$id';");

  ($self->{NUMBER},
   $self->{NAME},
   $self->{IP},
   $self->{CID}
   ) = @{ $self->{list}->[0] };
 
 return $self;
}

#**********************************************************
#
#**********************************************************
sub comps_change {
 my $self = shift;
 my ($attr) = @_;
 
 	my %FIELDS = (NUMBER => 'number',
 	              ID     => 'id',
	              NAME   => 'name', 
	              IP     => 'ip',
	              CID    => 'cid'); 



 	$self->changes($admin, { CHANGE_PARAM => 'ID',
		                TABLE        => 'ipn_club_comps',
		                FIELDS       => \%FIELDS,
		                OLD_INFO     => $self->comps_info($attr->{ID}),
		                DATA         => $attr
		              } );

 
 
}

#**********************************************************
#
#**********************************************************
sub comps_del {
 my $self = shift;
 my ($id) = @_;

 $self->query($db, "DELETE FROM ipn_club_comps WHERE id='$id';");

 return $self;
}


#*******************************************************************
# Delete information from user log
# log_del($i);
#*******************************************************************
sub log_del {
	my $self = shift;
	my ($attr) = @_;

 if ($attr->{UID}) {
   push @WHERE_RULES, "ipn_log.uid='$attr->{UID}'";
  }

 if ($attr->{SESSION_ID}) {
   push @WHERE_RULES, "ipn_log.session_id='$attr->{SESSION_ID}'";
  }

 my $WHERE = "WHERE " . join(' and ', @WHERE_RULES);
 $self->query($db, "DELETE FROM ipn_log WHERE $WHERE;");

 return $self;
}

#*******************************************************************
# Delete information from user log
# log_del($i);
#*******************************************************************
sub prepaid_rest {
	my $self = shift;
	my ($attr) = @_;
  my $info = $attr->{INFO};

 my $octets_direction = "l.traffic_in + l.traffic_out";
 
 
 #Recv
 if ($info->[0]->[6] == 1) {
   $octets_direction = "l.traffic_in";
  }
 #sent
 elsif ($info->[0]->[6] == 2) {
   $octets_direction = "l.traffic_out";
  }


 $self->query($db, "SELECT l.traffic_class, (sum($octets_direction)) / $CONF->{MB_SIZE}
   from ipn_log l
   WHERE l.uid='$attr->{UID}' and DATE_FORMAT(start, '%Y-%m-%d')>='$info->[0]->[3]'
   GROUP BY l.traffic_class, l.uid ;");
  
 my %traffic = ();
 foreach my $line (@{ $self->{list} }) {
    $traffic{$line->[0]}=$line->[1];
  }

  $self->{TRAFFIC}=\%traffic;

  return $info;
}

#*******************************************************************
# Delete information from user log
# log_del($i);
#*******************************************************************
sub recalculate {
  my $self = shift;
	my ($attr) = @_;

  my ($from, $to)=split(/\//, $attr->{INTERVAL}, 2);
  #push @WHERE_RULES, "date_format(f_time, '%Y-%m-%d')>='$from' and date_format(f_time, '%Y-%m-%d')<='$to'";


  $self->query($db, "SELECT start,
   traffic_class,
   traffic_in,
   traffic_out,
   nas_id,
   INET_NTOA(ip),
   interval_id,
   sum,
   session_id
   from ipn_log l
   WHERE l.uid='$attr->{UID}' and 
     (
      DATE_FORMAT(start, '%Y-%m-%d')>='$from'
      and DATE_FORMAT(start, '%Y-%m-%d')<='$to'
      )
   ;");



  return $self;	
}

#*******************************************************************
# AMon Alive Check
# online_alive($i);
#*******************************************************************
sub online_alive {
  my $self = shift;
	my ($attr) = @_;

  my $session_id = ($attr->{SESSION_ID}) ? "and acct_session_id='$attr->{SESSION_ID}'" : '';
	
  $self->query($db, "SELECT CID FROM dv_calls
   WHERE  user_name='$attr->{LOGIN}'
    and framed_ip_address=INET_ATON('$attr->{REMOTE_ADDR}');");
 
  if ($self->{TOTAL} > 0) {
    my $sql = "UPDATE dv_calls SET  lupdated=UNIX_TIMESTAMP(),
    CONNECT_INFO='$attr->{CONNECT_INFO}',
    status=3
     WHERE user_name = '$attr->{LOGIN}'  
    $session_id
    and framed_ip_address=INET_ATON('$attr->{REMOTE_ADDR}')";

    $self->query($db, $sql, 'do' );
    $self->{TOTAL} = 1;
   }

  return $self;	
}

#*******************************************************************
# Delete information from detail table
# and log table
#*******************************************************************
sub ipn_log_rotate {
  my $self = shift;
	my ($attr) = @_;
  
  my $DATE = (strftime "%Y_%m_%d", localtime(time - 86400));  
  $self->query($db, "SHOW TABLES LIKE 'ipn_traf_detail_$DATE';");
  return $self if ($self->{TOTAL} > 0);
  
  
 my @rq = (); 
 my $version = $self->db_version();
 #Detail Daily rotate
 if ($attr->{DETAIL} && $version > 4.1 ) {
   @rq = (
    'CREATE TABLE IF NOT EXISTS ipn_traf_detail_new LIKE ipn_traf_detail;',
    'RENAME TABLE ipn_traf_detail TO ipn_traf_detail_'. $DATE .
    ', ipn_traf_detail_new TO ipn_traf_detail;',
    'DELETE FROM ipn_unknow_ips;',
    
      );
  }
 else {
   @rq = ("DELETE FROM ipn_traf_detail WHERE f_time < f_time - INTERVAL $attr->{PERIOD} DAY;");
  }

 #IPN log rotate
 if ($attr->{LOG} && $version > 4.1) {
   push @rq, 
    'DROP TABLE IF EXISTS ipn_log_new;',
    'CREATE TABLE ipn_log_new LIKE ipn_log;',

    'INSERT INTO ipn_log_new (
         uid,
         start,
         stop,
         traffic_class,
         traffic_in,
         traffic_out,
         session_id,
         sum
    ) 
    SELECT uid, start, start, traffic_class, traffic_in, traffic_out,  session_id, sum FROM ipn_log 
      WHERE start >= \''. $admin->{DATE} .'\' - INTERVAL '. $attr->{PERIOD} .' DAY; ',


    'DROP TABLE IF EXISTS ipn_log_backup;',
    'RENAME TABLE 
      ipn_log  TO ipn_log_backup, 
      ipn_log_new TO ipn_log;',
    'DELETE FROM ipn_log_backup  WHERE start >= \''. $admin->{DATE}. '\' - INTERVAL '. $attr->{PERIOD} .' DAY; ';
  }

 foreach my $query (@rq) {
   $self->query($db, "$query", 'do');
  }

 return $self;
}

#*******************************************************************
# Delete information from user log
# log_del($i);
#*******************************************************************
sub user_detail {
  my $self = shift;
	my ($attr) = @_;
  my $list;


 $PG = ($attr->{PG}) ? $attr->{PG} : 0;
 $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;
 $SORT = ($attr->{SORT}) ? $attr->{SORT} : 2;
 $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

 undef @WHERE_RULES; 
 my @GROUP_RULES = (); 
 
if ($attr->{INTERVAL}) {
  my ($from, $to)=split(/\//, $attr->{INTERVAL}, 2);
  push @WHERE_RULES, "date_format(s_time, '%Y-%m-%d')>='$from' and date_format(f_time, '%Y-%m-%d')<='$to'";
  
  
  #Period
  if ($from) {
    my  $s_time = ($from =~ /^\d{4}-\d{2}-\d{2}$/) ? 'DATE_FORMAT(s_time, \'%Y-%m-%d\')' : 's_time' ;
	  push @WHERE_RULES, "$s_time >= '$from'";
	  if ($from =~ /(\d{4})-(\d{2})-(\d{2})/) {
	    $attr->{START_DATE} = "$1$2$3";
	   }
  }

  my  $s_time = ($to =~ /^\d{4}-\d{2}-\d{2}$/) ? 'DATE_FORMAT(s_time, \'%Y-%m-%d\')' : 's_time' ;

  push @WHERE_RULES, "$s_time <= '$to'";
  if ($to =~ /(\d{4})-(\d{2})-(\d{2})/) {
    $attr->{FINISH_DATE} = "$1$2$3";
   }
  
}

if ($attr->{UID}) {
   push @WHERE_RULES, "uid='$attr->{UID}'";
 }

if (defined($attr->{SRC_PORT}) && $attr->{SRC_PORT} =~ /^\d+$/) {
   push @WHERE_RULES, "src_port='$attr->{SRC_PORT}'";
 }

if ($attr->{DST_IP}) {
  my @ips_arr = split(/,/, $attr->{DST_IP});
  my @ip_q = ();
  foreach my $ip (sort @ips_arr) {
    if ($ip =~ /(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\/(\d{1,2})/) {
      my $ip   = $1;
      my $bits = $2;
      my $mask = 0b1111111111111111111111111111111;

      $mask = int(sprintf("%d", $mask >> ($bits - 1)));
      my $last_ip = ip2int($ip) | $mask;
      my $first_ip = $last_ip - $mask;
      print "IP FROM: ". int2ip($first_ip) ." TO: ". int2ip($last_ip). "\n" if ($debug > 2);
        push @ip_q, "(
                       (dst_addr>='$first_ip' and dst_addr<='$last_ip' )  
                      )";
     }
          elsif ($ip =~ /\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/) {
            push @ip_q, "dst_addr=INET_ATON('$ip')";
           }
   }

   push @WHERE_RULES, '(' . join(' or ', @ip_q) . ')';
}



if ($attr->{SRC_IP}) {
  my @ips_arr = split(/,/, $attr->{SRC_IP});
  my @ip_q = ();
  foreach my $ip (sort @ips_arr) {
    if ($ip =~ /(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\/(\d{1,2})/) {
      my $ip   = $1;
      my $bits = $2;
      my $mask = 0b1111111111111111111111111111111;

      $mask = int(sprintf("%d", $mask >> ($bits - 1)));
      my $last_ip = ip2int($ip) | $mask;
      my $first_ip = $last_ip - $mask;
      print "IP FROM: ". int2ip($first_ip) ." TO: ". int2ip($last_ip). "\n" if ($debug > 2);
        push @ip_q, "(
                       (src_addr>='$first_ip' and src_addr<='$last_ip' )  
                      )";
     }
          elsif ($ip =~ /\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/) {
            push @ip_q, "src_addr=INET_ATON('$ip')";
           }
   }

   push @WHERE_RULES, '(' . join(' or ', @ip_q) . ')';
}

if (defined($attr->{DST_PORT}) && $attr->{DST_PORT} =~ /^\d+$/ ) {
   push @WHERE_RULES, "dst_port='$attr->{DST_PORT}'";
 }

if ($attr->{DST_IP_GROUP}) {
   push @GROUP_RULES, 'dst_addr';
 }

if ($attr->{SRC_IP_GROUP}) {
   push @GROUP_RULES, 'src_addr';
 }



my $GROUP_BY = '';
my $size = 'size';

my $WHERE    = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';

if ($#GROUP_RULES > -1) {
  $GROUP_BY = "GROUP BY " . join(', ', @GROUP_RULES) ;
  $size = 'sum(size)';
 } 


my @tables = ();

$self->query($db, "SHOW TABLES;");
$list = $self->{list};

foreach my $line (@$list) {
  my $table = $line->[0];
  if ($table =~ m/ipn_traf_detail_(\d{4})_(\d{2})_(\d{2})/) {
  	 my $table_date="$1$2$3";
  	 if ($table_date >= $attr->{START_DATE} && $table_date <= $attr->{FINISH_DATE}) {
  	 	  print $table."\n" if ($debug > 1);
  	 	  push @tables, $table;
  	  }
   }
}

push @tables, 'ipn_traf_detail';
my @sql_arr = ();
foreach my $table (@tables) {
  my $date ;
  if ($table =~ m/ipn_traf_detail_(\d{4})_(\d{2})_(\d{2})/) {
    $date = "$1-$2-$3";
   }
  
  push @sql_arr,   "SELECT s_time,	f_time,
    INET_NTOA(src_addr),
    src_port,
    INET_NTOA(dst_addr),
    dst_port,
    protocol,
    $size,
    nas_id 
  FROM $table 
    $WHERE
    $GROUP_BY
    ";
}
 
 my $sql = join(" UNION ", @sql_arr);
 $self->query($db, "$sql LIMIT $PG,$PAGE_ROWS");
 $list = $self->{list};

  
  
  if ($self->{TOTAL} > 0 && $#GROUP_RULES < 0) {
    #$self->{debug}=1;
    my $totals = 0;
    foreach my $table (@tables) {
      $self->query($db, "SELECT count(*) from $table
        $WHERE ;");
      $totals += $self->{list}->[0]->[0];
     }
    $self->{TOTAL}=$totals;
   }


  return $list;	
}


#**********************************************************
# List
#**********************************************************
sub unknown_ips_list {
 my $self = shift;
 my ($attr) = @_;
 $WHERE = '';

 $PG = ($attr->{PG}) ? $attr->{PG} : 0;
 $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;
 $SORT = ($attr->{SORT}) ? $attr->{SORT} : 2;
 $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';


 $self->query($db, "SELECT 
  datetime,
  INET_NTOA(src_ip),
  INET_NTOA(dst_ip),
  size,
  nas_id
  FROM ipn_unknow_ips
  $WHERE
  ORDER BY $SORT $DESC 
  LIMIT $PG, $PAGE_ROWS
  ;");

 my $list = $self->{list};

 $self->query($db, "SELECT count(*), sum(size) from ipn_unknow_ips;");
 ($self->{TOTAL}, $self->{TOTAL_TRAFFIC}) = @{ $self->{list}->[0] };

  return $list;
}
1



package Dv_Sessions;
# Dv Stats functions
#



use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION
);

use Exporter;
$VERSION = 2.00;
@ISA = ('Exporter');

@EXPORT = qw();

@EXPORT_OK   = ();
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
    $self->query($db, "DELETE FROM dv_log WHERE uid='$attr->{DELETE_USER}';", 'do');
   }
  else {
  	$self->query($db, "show tables LIKE 'traffic_prepaid_sum'");
  	
  	if ($self->{TOTAL} > 0) {
      $self->query($db, "UPDATE traffic_prepaid_sum pl, dv_log l SET 
         traffic_in=traffic_in-(l.recv + 4294967296 * acct_input_gigawords),
         traffic_out=traffic_out-(l.sent + 4294967296 * acct_output_gigawords)
         WHERE pl.uid=l.uid AND l.uid='$uid' and l.start='$session_start' and l.nas_id='$nas_id' 
          and l.acct_session_id='$session_id';", 'do');
  	 }
  	
     $self->query($db, "DELETE FROM dv_log 
       WHERE uid='$uid' and start='$session_start' and nas_id='$nas_id' and acct_session_id='$session_id';", 'do');
   }

  return $self;
}

#**********************************************************
# online()
#********************************************************** 
sub online_update {
	my $self = shift;
	my ($attr) = @_;
  my @SET_RULES = ();
  
  push @SET_RULES, 'lupdated=UNIX_TIMESTAMP()' if (defined($attr->{STATUS}) && $attr->{STATUS} == 5);

  if (defined($attr->{in})) {
   	push @SET_RULES, "acct_input_octets='$attr->{in}'";
   }
  if (defined($attr->{out})) {
  	push @SET_RULES, "acct_output_octets='$attr->{out}'";
   }

  if (defined($attr->{STATUS})) {
  	push @SET_RULES, "status='$attr->{STATUS}'";
   }
 
  my $SET = ($#SET_RULES > -1) ? join(', ', @SET_RULES)  : '';

  $self->query($db, "UPDATE dv_calls SET $SET
   WHERE 
    user_name='$attr->{USER_NAME}'
    and acct_session_id='$attr->{ACCT_SESSION_ID}'; ", 'do');

  return $self;
}



#**********************************************************
# online()
#********************************************************** 
sub online_count {
  my $self = shift;
  my ($attr) = @_;

 $self->query($db, "SELECT n.id, n.name, n.ip, n.nas_type,  
   sum(if (c.status=1 or c.status>=3, 1, 0)),
   count(distinct uid),
   sum(if (status=2, 1, 0)), 
   sum(if (status>3, 1, 0))
 FROM dv_calls c, nas n
 WHERE c.nas_id=n.id AND c.status<11
 GROUP BY c.nas_id
 ORDER BY $SORT $DESC;");

 my $list = $self->{list};

 if ($self->{TOTAL} > 0) {
 	 $self->query($db, "SELECT 1, count(uid),  
 	   sum(if (c.status=1 or c.status>=3, 1, 0)),
 	   sum(if (status=2, 1, 0))
   FROM dv_calls c 
   WHERE c.status<11
   GROUP BY 1;");

   (undef,
    $self->{TOTAL},
    $self->{ONLINE},
    $self->{ZAPED}
    )= @{ $self->{list}->[0] };
  }

 return $list;
}


#**********************************************************
# online()
#********************************************************** 
sub online {
	my $self = shift;
	my ($attr) = @_;

  my $WHERE = '';
  my $EXT_TABLE = '';

  $admin->{DOMAIN_ID}=0 if (! $admin->{DOMAIN_ID});

  if ($attr->{COUNT}) {
  	if ($attr->{ZAPED}) {
  		$WHERE = 'WHERE c.status=2';
  	 }
    else {
  		$WHERE = 'WHERE ((c.status=1 or c.status>=3) AND c.status<11)';
     }

  	$self->query($db, "SELECT  count(*) FROM dv_calls c $WHERE;");
    $self->{TOTAL} = $self->{list}->[0][0];
  	return $self;
   }

  my @FIELDS_ALL = (
   'c.user_name',
   'pi.fio',
   'c.nas_port_id',
   'c.framed_ip_address',
   'SEC_TO_TIME(UNIX_TIMESTAMP() - UNIX_TIMESTAMP(c.started))',

   'c.acct_input_octets + 4294967296 * acct_input_gigawords', 
   'c.acct_output_octets + 4294967296 * acct_output_gigawords', 
   'c.ex_input_octets', 
   'c.ex_output_octets',
 
   'c.CID',                           
   'c.acct_session_id',
   'dv.tp_id',
   'c.CONNECT_INFO',
   'dv.speed',   
   'c.sum',
   'c.status',
   'concat(pi.address_street,\' \', pi.address_build,\'/\', pi.address_flat)', 
   'u.gid',
   'c.turbo_mode',
   'c.join_service',

   'pi.phone',
   'INET_NTOA(c.framed_ip_address)',
   'u.uid',
   'INET_NTOA(c.nas_ip_address)',
   'if(company.name IS NULL, b.deposit, cb.deposit)',
   'u.credit',
   'if(date_format(c.started, "%Y-%m-%d")=curdate(), date_format(c.started, "%H:%i:%s"), c.started)',
   'c.nas_id',
   'UNIX_TIMESTAMP()-c.lupdated',
   'c.acct_session_time',
   'c.lupdated - UNIX_TIMESTAMP(c.started)',
   'dv.filter_id',
   'c.uid',
   'c.join_service'
   );

  my %FIELDS_NAMES_HASH = (
   USER_NAME      => 'c.user_name',
   FIO            => 'pi.fio',
   NAS_PORT_ID    => 'c.nas_port_id',
   CLIENT_IP_NUM  => 'c.framed_ip_address',
   DURATION       => 'SEC_TO_TIME(UNIX_TIMESTAMP() - UNIX_TIMESTAMP(c.started))',

   INPUT_OCTETS   => 'c.acct_input_octets + 4294967296 * acct_input_gigawords',
   OUTPUT_OCTETS  => 'c.acct_output_octets + 4294967296 * acct_output_gigawords',
   INPUT_OCTETS2  => 'c.ex_input_octets',
   OUTPUT_OCTETS2 => 'c.ex_output_octets',
 
   CID             => 'c.CID',
   DV_CID          => 'dv.cid',
   ACCT_SESSION_ID => 'c.acct_session_id',
   TP_ID           => 'dv.tp_id',
   CALLS_TP_ID     => 'c.tp_id',
   CONNECT_INFO    => 'c.CONNECT_INFO',
   SPEED           => 'dv.speed',   
   SUM             => 'c.sum',
   STATUS          => 'c.status',
   ADDRESS_FULL    => ($CONF->{ADDRESS_REGISTER}) ? 'concat(streets.name,\' \', builds.number, \'/\', pi.address_flat) AS ADDRESS'  : 'concat(pi.address_street,\' \', pi.address_build,\'/\', pi.address_flat) AS ADDRESS', 
   GID             => 'u.gid',
   TURBO_MODE      => 'c.turbo_mode',
   JOIN_SERVICE    => 'c.join_service',

   PHONE           => 'pi.phone',
   CLIENT_IP       => 'INET_NTOA(c.framed_ip_address) AS client_ip',
   UID             => 'u.uid',
   NAS_IP          => 'INET_NTOA(c.nas_ip_address) AS nas_ip',
   DEPOSIT         => 'if(company.name IS NULL, b.deposit, cb.deposit)',
   CREDIT          => 'if(u.company_id=0, u.credit, if (u.credit=0, company.credit, u.credit))',
   STARTED         => 'if(date_format(c.started, "%Y-%m-%d")=curdate(), date_format(c.started, "%H:%i:%s"), c.started)',
   NAS_ID          => 'c.nas_id',
   LAST_ALIVE      => 'UNIX_TIMESTAMP()-c.lupdated',
   ACCT_SESSION_TIME => 'UNIX_TIMESTAMP() - UNIX_TIMESTAMP(c.started)',
   DURATION_SEC    => 'c.lupdated - UNIX_TIMESTAMP(c.started)',
   FILTER_ID       => 'if(dv.filter_id<>\'\', dv.filter_id, tp.filter_id)',
   SESSION_START   => 'UNIX_TIMESTAMP(started)',
   DISABLE         => 'u.disable',
   DV_STATUS       => 'dv.disable',
   
   TP_NAME            => 'tp.tp_name',
   TP_BILLS_PRIORITY  => 'tp.bills_priority',
   TP_CREDIT          => 'tp.credit',
  );


  my @RES_FIELDS = (0, 1, 2, 3, 4, 5, 6, 7, 8);
 
  if ($attr->{FIELDS}) {
  	@RES_FIELDS = @{ $attr->{FIELDS} };
   }
  
  my $fields = '';
  my $port_id=0;
  
  
  for(my $i=0; $i<=$#RES_FIELDS; $i++) {
  	if ($RES_FIELDS[$i] == 2) {
  		$port_id=$i;
  	 }
    elsif ($RES_FIELDS[$i] == 16 && $CONF->{ADDRESS_REGISTER}) {
      $EXT_TABLE .= "LEFT JOIN builds ON (builds.id=pi.location_id)
        LEFT JOIN streets ON (streets.id=builds.street_id)";
      $FIELDS_ALL[16]='concat(streets.name,\' \', builds.number, \'/\', pi.address_flat) AS ADDRESS';  
  	 }
 	  elsif ($RES_FIELDS[$i] == 11){
 	 	  $FIELDS_ALL[11] = "CONCAT(dv.tp_id, '/', tp.name)";
 	 	  $EXT_TABLE .= "LEFT JOIN tarif_plans tp ON (tp.id=dv.tp_id AND tp.module='Dv')";
 	   }
    
    $fields .= "$FIELDS_ALL[$RES_FIELDS[$i]], ";
   }

  my $RES_FIELDS_COUNT = $#RES_FIELDS;

  if ($attr->{FIELDS_NAMES}) {
  	$fields='';
    $RES_FIELDS_COUNT = 0;
  	foreach my $field ( @{ $attr->{FIELDS_NAMES} } ) {
  	  $fields .= "$FIELDS_NAMES_HASH{$field},\n ";	
  	  if ($field =~ /TP_BILLS_PRIORITY|TP_NAME|FILTER_ID|TP_CREDIT/ && $EXT_TABLE !~ /tarif_plans/) {
  	  	$EXT_TABLE .= "LEFT JOIN tarif_plans tp ON (tp.id=dv.tp_id AND tp.module='Dv')";
  	   }
  	  $RES_FIELDS_COUNT++;
  	 }
    $RES_FIELDS_COUNT--;
   }

 $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
 $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
 
 my @WHERE_RULES = ();
 
 if ($attr->{ZAPED}) {
 	 push @WHERE_RULES, "c.status=2";
  }
 elsif ($attr->{ALL}) {

  }
 elsif($attr->{STATUS}) {
 	 push @WHERE_RULES, @{ $self->search_expr("$attr->{STATUS}", 'INT', 'c.status') };
  }
 else {
   push @WHERE_RULES, "((c.status=1 or c.status>=3) AND c.status<11)";
  } 
 
 if (defined($attr->{USER_NAME})) {
 	 push @WHERE_RULES, @{ $self->search_expr("$attr->{USER_NAME}", 'STR', 'c.user_name') }
  }
 elsif ($attr->{UID}) {
   push @WHERE_RULES, @{ $self->search_expr("$attr->{UID}", 'INT', 'c.uid') }
  }

 if (defined($attr->{SESSION_ID})) {
 	 push @WHERE_RULES, "c.acct_session_id LIKE '$attr->{SESSION_ID}'";
  }

 if ($attr->{SESSION_IDS}) {
 	 my @session_arr = split(/, /, $attr->{SESSION_IDS});
 	 my $w = "'". join('\', \'', @session_arr) . "'";
 	 push @WHERE_RULES, "c.acct_session_id IN ($w)";
  }
 

 # Show groups
 if ($attr->{GIDS}) {
   push @WHERE_RULES, "u.gid IN ($attr->{GIDS})"; 
  }
 elsif ($attr->{GID}) {
   push @WHERE_RULES, "u.gid='$attr->{GID}'"; 
  }

 if ($attr->{DOMAIN_ID}) {
   push @WHERE_RULES, @{ $self->search_expr("$attr->{DOMAIN_ID}", 'INT', 'u.domain_id') };
  }

 if (defined($attr->{FRAMED_IP_ADDRESS})) {
 	 push @WHERE_RULES, "framed_ip_address=INET_ATON('$attr->{FRAMED_IP_ADDRESS}')";
  }

 if ($attr->{TP_ID}) {
 	 push @WHERE_RULES, "dv.tp_id='$attr->{TP_ID}'";
  }

 if ($attr->{NAS_ID}) {
 	 push @WHERE_RULES, "nas_id IN ($attr->{NAS_ID})";
  } 
 

 if ($attr->{FILTER}) {
 	 my $filter_field = '';
 	 if ($attr->{FILTER_FIELD} == 3){
 	 	 $filter_field = "INET_NTOA(framed_ip_address)";
 	  }
 	 #elsif ($attr->{FILTER_FIELD} == 11){
 	 #	 $filter_field = "CONCAT(dv.tp_id, tp.name)";
 	 #	 $EXT_TABLE .= "LEFT JOIN tarif_plans tp ON (tp.id=dv.tp_id AND tp.module='Dv')"
 	 # }
 	 elsif($attr->{FILTER_FIELD} == 16 && $CONF->{ADDRESS_REGISTER}) {
     if ($EXT_TABLE !~ /builds/) {
       $EXT_TABLE .= "INNER JOIN builds b ON (builds.id=pi.location_id)
       INNER JOIN streets s ON (streets.id=builds.street_id)";
 	 	  }

 	 	 $filter_field = 'concat(streets.name, \', \', builds.number)'; 	 	 
 	  }
 	 else {
 	 	 $filter_field = $FIELDS_ALL[$attr->{FILTER_FIELD}];
 	  }

 	 push @WHERE_RULES, ($attr->{FILTER} =~ s/\*/\%/g) ? "$filter_field LIKE '$attr->{FILTER}'" : "$filter_field='$attr->{FILTER}'";
  }
 
 
 $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';
 
 $self->query($db, "SELECT $fields
   pi.phone,
   INET_NTOA(c.framed_ip_address),
   u.uid,
   INET_NTOA(c.nas_ip_address),
   if(company.name IS NULL, b.deposit, cb.deposit),
   if(u.company_id=0, u.credit,
          if (u.credit=0, company.credit, u.credit)),
   if(date_format(c.started, '%Y-%m-%d')=curdate(), date_format(c.started, '%H:%i:%s'), c.started),
   UNIX_TIMESTAMP()-c.lupdated,
   c.status,
   c.nas_id,
   c.user_name,
   c.nas_port_id,
   c.acct_session_id,
   c.CID,
   dv.tp_id
 FROM dv_calls c
 LEFT JOIN users u     ON (u.uid=c.uid)
 LEFT JOIN dv_main dv  ON (dv.uid=u.uid)
 LEFT JOIN users_pi pi ON (pi.uid=u.uid)

 LEFT JOIN bills b ON (u.bill_id=b.id)
 LEFT JOIN companies company ON (u.company_id=company.id)
 LEFT JOIN bills cb ON (company.bill_id=cb.id)
 $EXT_TABLE

 $WHERE
 ORDER BY $SORT $DESC;", 'fields_list');

 my %dub_logins = ();
 my %dub_ports  = ();
 my %nas_sorted = ();

 if ($self->{TOTAL} < 1) {
 	 $self->{dub_ports} =\%dub_ports;
   $self->{dub_logins}=\%dub_logins;
   $self->{nas_sorted}=\%nas_sorted;

 	 return $self->{list};
  }


 my $list = $self->{list};
 my $nas_id_field = $RES_FIELDS_COUNT+10;
 foreach my $line (@$list) {
 	  $dub_logins{$line->[0]}++;
 	  $dub_ports{$line->[$nas_id_field]}{$line->[$port_id]}++;
    
    my @fields = ();
    for(my $i=0; $i<=$RES_FIELDS_COUNT+15; $i++) {
       push @fields, $line->[$i];
     }

    push( @{ $nas_sorted{"$line->[$nas_id_field]"} }, [ @fields ]);
  }

 $self->{dub_ports} =\%dub_ports;
 $self->{dub_logins}=\%dub_logins;
 $self->{nas_sorted}=\%nas_sorted;

 return $self->{list};	
}

#**********************************************************
# online_del()
#********************************************************** 
sub online_join_services {
 my $self = shift;
 my ($attr) = @_;
 
 $self->query($db, "SELECT  join_service, 
   sum(c.acct_input_octets) + 4294967296 * sum(acct_input_gigawords), 
   sum(c.acct_output_octets) + 4294967296 * sum(acct_output_gigawords) 
 FROM dv_calls c
 GROUP BY join_service;");
 
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
    my $NAS_PORT        = (defined($attr->{NAS_PORT})) ? $attr->{NAS_PORT} : '';
    my $ACCT_SESSION_ID = (defined($attr->{ACCT_SESSION_ID})) ? $attr->{ACCT_SESSION_ID} : '';
    $WHERE = "nas_id='$NAS_ID'
            and nas_port_id='$NAS_PORT' 
            and acct_session_id='$ACCT_SESSION_ID'";
   }

  $self->query($db, "SELECT uid, user_name, started, SEC_TO_TIME(lupdated-UNIX_TIMESTAMP(started)), sum FROM dv_calls WHERE $WHERE");
  foreach my $line ( @{  $self->{list} } ) {
    $admin->action_add("$line->[0]", "START: $line->[2] DURATION: $line->[3] SUM: $line->[4]", { MODULE => 'Dv', TYPE => 13 });
   }

  $self->query($db, "DELETE FROM dv_calls WHERE $WHERE;", 'do');

  return $self;
}


#**********************************************************
# Add online session to log
# online2log()
#********************************************************** 
sub online_info {
	my $self = shift;
	my ($attr) = @_;

   undef @WHERE_RULES; 

   if($attr->{NAS_ID}) {
   	  push @WHERE_RULES, "nas_id='$attr->{NAS_ID}'";
    }
   elsif (defined($attr->{NAS_IP_ADDRESS})) {
      push @WHERE_RULES, "nas_ip_address=INET_ATON('$attr->{NAS_IP_ADDRESS}')";
    }
   
   if (defined($attr->{NAS_PORT})) {
     push @WHERE_RULES, "nas_port_id='$attr->{NAS_PORT}'";
    }
   
   if (defined($attr->{ACCT_SESSION_ID})) {
     push @WHERE_RULES, "acct_session_id='$attr->{ACCT_SESSION_ID}'";
    }
 
  $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';
 
  $self->query($db, "SELECT user_name, UNIX_TIMESTAMP(started), acct_session_time, 
   acct_input_octets,
   acct_output_octets,
   ex_input_octets,
   ex_output_octets,
   connect_term_reason,
   INET_NTOA(framed_ip_address),
   lupdated,
   nas_port_id,
   INET_NTOA(nas_ip_address),
      CID,
      CONNECT_INFO,
      acct_session_id,
      nas_id,
      started,
      acct_input_gigawords 
      acct_output_gigawords 
 
      FROM dv_calls 
   $WHERE 
   ");


  if ($self->{TOTAL} < 1) {
     $self->{errno} = 2;
     $self->{errstr} = 'ERROR_NOT_EXIST';
     return $self;
   }

  ($self->{USER_NAME}, 
   $self->{SESSION_START}, 
   $self->{ACCT_SESSION_TIME}, 
   $self->{ACCT_INPUT_OCTETS}, 
   $self->{ACCT_OUTPUT_OCTETS}, 
   $self->{ACCT_EX_INPUT_OCTETS}, 
   $self->{ACCT_EX_OUTPUT_OCTETS}, 
   $self->{CONNECT_TERM_REASON}, 
   $self->{FRAMED_IP_ADDRESS}, 
   $self->{LAST_UPDATE}, 
   $self->{NAS_PORT}, 
   $self->{NAS_IP_ADDRESS}, 
   $self->{CALLING_STATION_ID},
   $self->{CONNECT_INFO},
   $self->{ACCT_SESSION_ID},
   $self->{NAS_ID},
   $self->{ACCT_SESSION_STARTED},
   $self->{ACCT_INPUT_GIGAWORDS},
   $self->{ACCT_OUTPUT_GIGAWORDS}
    )= @{ $self->{list}->[0] };

  return $self;
}

#**********************************************************
# Session zap
#**********************************************************
sub zap {
  my $self=shift;
  my ($nas_id, $nas_port_id, $acct_session_id, $attr)=@_;
  
  my $WHERE = '';

  if ($attr->{NAS_ID}) {
  	$WHERE = "WHERE nas_id='$attr->{NAS_ID}'";
   }  
  elsif (! defined($attr->{ALL})) {
    $WHERE = "WHERE nas_id='$nas_id' and nas_port_id='$nas_port_id'";
   }

  if ($acct_session_id) {
  	$WHERE .= "and acct_session_id='$acct_session_id'";
   }

  $self->query($db, "UPDATE dv_calls SET status='2' $WHERE;", 'do');
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
  l.sent + 4294967296 * acct_output_gigawords, 
  l.recv + 4294967296 * acct_input_gigawords,
  l.recv2,
  l.sent2, 
  INET_NTOA(l.ip),
  l.CID,
  l.nas_id,
  n.name,
  n.ip,
  l.port_id,
  l.minp,
  l.kb,
  l.sum,
  l.bill_id,
  u.id,
  l.uid,
  l.acct_session_id,
  l.terminate_cause,
  UNIX_TIMESTAMP(l.start)
 FROM (dv_log l, users u)
 LEFT JOIN tarif_plans tp ON (l.tp_id=tp.id) 
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
   $self->{SENT}, 
   $self->{RECV}, 
   $self->{SENT2},   
   $self->{RECV2},   
   $self->{IP}, 
   $self->{CID}, 
   $self->{NAS_ID}, 
   $self->{NAS_NAME},
   $self->{NAS_IP},
   $self->{NAS_PORT}, 
   $self->{TIME_TARIFF},
   $self->{TRAF_TARIFF},
   $self->{SUM}, 
   $self->{BILL_ID}, 
   $self->{LOGIN}, 
   $self->{UID}, 
   $self->{SESSION_ID},
   $self->{ACCT_TERMINATE_CAUSE},
   $self->{START_UNIXTIME}
    )= @{ $self->{list}->[0] };


 return $self;
}

#**********************************************************
# detail_list()
#**********************************************************
sub detail_list {
	my $self = shift;
	my ($attr) = @_;

 $PG = ($attr->{PG}) ? $attr->{PG} : 0;
 $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;
 $SORT = ($attr->{SORT}) ? $attr->{SORT} : 2;
 $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

	
my $lupdate;
	
my $WHERE = ($attr->{SESSION_ID}) ? "and acct_session_id='$attr->{SESSION_ID}'" : '';	
my $GROUP;

if ($attr->{PERIOD} eq 'days') {
  $lupdate = "DATE_FORMAT(FROM_UNIXTIME(last_update), '%Y-%m-%d')";	
  $GROUP = $lupdate;
  $WHERE = '';
}
elsif($attr->{PERIOD} eq 'hours') {
  $lupdate = "DATE_FORMAT(FROM_UNIXTIME(last_update), '%Y-%m-%d %H')";	
  $GROUP = $lupdate;
  $WHERE = '';
}
elsif($attr->{PERIOD} eq 'sessions') {
	$WHERE = '';
  $lupdate = "FROM_UNIXTIME(last_update)";
  $GROUP='acct_session_id';
}
else {
  $lupdate = "FROM_UNIXTIME(last_update)";
  $GROUP = $lupdate;
}

 $self->query($db, "SELECT $lupdate, acct_session_id, nas_id, 
   sum(sent1), sum(recv1), sum(recv2), sum(sent2) sum
  FROM s_detail 
  WHERE id='$attr->{LOGIN}' $WHERE
  GROUP BY $GROUP 
  ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;" );

 my $list = $self->{list};

 if ($self->{TOTAL} > 0) {
    $self->query($db, "SELECT count(DISTINCT $lupdate)
      FROM s_detail 
     WHERE id='$attr->{LOGIN}' $WHERE ;");
    
    ($self->{TOTAL}) = @{ $self->{list}->[0] };
  }

  return $list;
}


#**********************************************************
# detail_list()
#**********************************************************
sub detail_sum {
	my $self = shift;
	my ($attr) = @_;

 my $lupdate;
 my $GROUP;

 my $interval = 3600;
 if ($attr->{INTERVAL}) {
   $interval = $attr->{INTERVAL};
  }

 $self->query($db, "select ((SELECT  sent1+recv1
  FROM s_detail 
  WHERE id='$attr->{LOGIN}' AND last_update>UNIX_TIMESTAMP()-$interval
  ORDER BY last_update DESC
  LIMIT 1 ) - (SELECT  sent1+recv1
  FROM s_detail 
  WHERE id='$attr->{LOGIN}' AND last_update>UNIX_TIMESTAMP()-$interval
  ORDER BY last_update
  LIMIT 1));" );

  my $speed = 0;

  if ( $self->{TOTAL} > 0 ) {
    $self->{TOTAL_TRAFFIC} = $self->{list}->[0]->[0] || 0;
    $speed =  int($self->{TOTAL_TRAFFIC} / $interval);
   }
	
  return $speed;
}

#**********************************************************
# Periods totals
# periods_totals($self, $attr);
#**********************************************************
sub periods_totals {
 my $self = shift;
 my ($attr) = @_;
 my $WHERE = '';
 
 if ($attr->{UIDS}) {
   $WHERE .= "WHERE uid IN ($attr->{UIDS})";
  }
 elsif($attr->{UID})  {
   $WHERE .= ($WHERE ne '') ?  " and uid='$attr->{UID}' " : "WHERE uid='$attr->{UID}' ";
  }

 $self->query($db, "SELECT  
   sum(if(date_format(start, '%Y-%m-%d')=curdate(), sent + 4294967296 * acct_output_gigawords, 0)), 
   sum(if(date_format(start, '%Y-%m-%d')=curdate(), recv + 4294967296 * acct_input_gigawords, 0)), 
   SEC_TO_TIME(sum(if(date_format(start, '%Y-%m-%d')=curdate(), duration, 0))), 

   sum(if(TO_DAYS(curdate()) - TO_DAYS(start) = 1, sent + 4294967296 * acct_output_gigawords, 0)),
   sum(if(TO_DAYS(curdate()) - TO_DAYS(start) = 1, recv + 4294967296 * acct_input_gigawords, 0)),
   SEC_TO_TIME(sum(if(TO_DAYS(curdate()) - TO_DAYS(start) = 1, duration, 0))),

   sum(if((YEAR(curdate())=YEAR(start)) and (WEEK(curdate()) = WEEK(start)), sent + 4294967296 * acct_output_gigawords, 0)),
   sum(if((YEAR(curdate())=YEAR(start)) and  WEEK(curdate()) = WEEK(start), recv + 4294967296 * acct_input_gigawords, 0)),
   SEC_TO_TIME(sum(if((YEAR(curdate())=YEAR(start)) and WEEK(curdate()) = WEEK(start), duration, 0))),
                                                                              
   sum(if(date_format(start, '%Y-%m')=date_format(curdate(), '%Y-%m'), sent + 4294967296 * acct_output_gigawords, 0)), 
   sum(if(date_format(start, '%Y-%m')=date_format(curdate(), '%Y-%m'), recv + 4294967296 * acct_input_gigawords, 0)), 
   SEC_TO_TIME(sum(if(date_format(start, '%Y-%m')=date_format(curdate(), '%Y-%m'), duration, 0))),
  
   sum(sent + 4294967296 * acct_output_gigawords), 
   sum(recv + 4294967296 * acct_input_gigawords), 
   SEC_TO_TIME(sum(duration))
   FROM dv_log $WHERE;");

   if ($self->{TOTAL} == 0) {
   	 return $self;
    }

  ($self->{sent_0}, 
   $self->{recv_0}, 
   $self->{duration_0}, 
   $self->{sent_1}, 
   $self->{recv_1}, 
   $self->{duration_1},
   $self->{sent_2}, 
   $self->{recv_2}, 
   $self->{duration_2}, 
   $self->{sent_3}, 
   $self->{recv_3}, 
   $self->{duration_3}, 
   $self->{sent_4}, 
   $self->{recv_4}, 
   $self->{duration_4}) =  @{ $self->{list}->[0] };
  
  for(my $i=0; $i<5; $i++) {
    $self->{'sum_'. $i } = $self->{'sent_' . $i } + $self->{'recv_' . $i};
  }

  return $self;	
}


#**********************************************************
#
#**********************************************************
sub prepaid_rest {
  my $self = shift;	
  my ($attr) = @_;
	
	$CONF->{MB_SIZE} = $CONF->{KBYTE_SIZE} * $CONF->{KBYTE_SIZE};
	
	#Get User TP and intervals
  $self->query($db, "select tt.id, i.begin, i.end, 
    if(u.activate<>'0000-00-00', u.activate, DATE_FORMAT(curdate(), '%Y-%m-01')), 
    tt.prepaid, 
    u.id, 
    tp.octets_direction, 
    u.uid, 
    dv.tp_id, 
    tp.name,
    if (PERIOD_DIFF(DATE_FORMAT(curdate(),'%Y%m'),DATE_FORMAT(u.registration, '%Y%m')) < tp.traffic_transfer_period, 
      PERIOD_DIFF(DATE_FORMAT(curdate(),'%Y%m'),DATE_FORMAT(u.registration, '%Y%m'))+1, tp.traffic_transfer_period), 
    tp.day_traf_limit,
    tp.week_traf_limit,
    tp.month_traf_limit
  from (users u,
        dv_main dv,
        tarif_plans tp,
        intervals i,
        trafic_tarifs tt)
WHERE
     u.uid=dv.uid
 and dv.tp_id=tp.id
 and tp.tp_id=i.tp_id
 and i.id=tt.interval_id
 and u.uid='$attr->{UID}'
 ORDER BY 1
 ");

 if($self->{TOTAL} < 1) {
 	  return 0;
  }

 $self->{INFO_LIST}    = $self->{list};
 my $login             = $self->{INFO_LIST}->[0]->[5];
 my $traffic_transfert = $self->{INFO_LIST}->[0]->[10];
 
 my %prepaid_traffic = (0 => 0,
                        1 => 0 );

 my %rest            = (0 => 0,
                        1 => 0 );
 
 foreach my $line ( @{ $self->{list} } ) {
   $prepaid_traffic{$line->[0]} = $line->[4];
   $rest{$line->[0]} = $line->[4];
  }

 return 1 if ($attr->{INFO_ONLY});
 
 my $octets_direction = "(sent + 4294967296 * acct_output_gigawords) + (recv + 4294967296 * acct_input_gigawords) ";
 my $octets_direction2 = "sent2 + recv2";
 my $octets_online_direction = "acct_input_octets + acct_output_octets";
 my $octets_online_direction2 = "ex_input_octets + ex_output_octets";
 
 if ($self->{INFO_LIST}->[0]->[6] == 1) {
   $octets_direction = "recv + 4294967296 * acct_input_gigawords ";
   $octets_direction2 = "recv2";
   $octets_online_direction = "acct_input_octets + 4294967296 * acct_input_gigawords";
   $octets_online_direction2 = "ex_input_octets";
  }
 elsif ($self->{INFO_LIST}->[0]->[6] == 2) {
   $octets_direction  = "sent + 4294967296 * acct_output_gigawords ";
   $octets_direction2 = "sent2";
   $octets_online_direction = "acct_output_octets + 4294967296 * acct_output_gigawords";
   $octets_online_direction2 = "ex_output_octets";
  }

 my $uid="uid='$attr->{UID}'";
 if ($attr->{UIDS}) {
 	  $uid="uid IN ($attr->{UIDS})";
  }



 #Traffic transfert
 my $GROUP = '4';
 if ($traffic_transfert > 0) {
    $GROUP = '3';
   }

   my $WHERE = '';

   if ($attr->{FROM_DATE}) {
     $WHERE  = "date_format(l.start, '%Y-%m-%d')>='$attr->{FROM_DATE}' and date_format(l.start, '%Y-%m-%d')<='$attr->{TO_DATE}'";
    }
   else {
     $WHERE  = "DATE_FORMAT(start, '%Y-%m-%d')>='$self->{INFO_LIST}->[0]->[3]' - INTERVAL $traffic_transfert MONTH ";
       #and DATE_FORMAT(start, '%Y-%m-%d')<='$self->{INFO_LIST}->[0]->[3]'";
    }

 	 #Get using traffic
   $self->query($db, "select  
     sum($octets_direction) / $CONF->{MB_SIZE},
     sum($octets_direction2) / $CONF->{MB_SIZE},
     DATE_FORMAT(start, '%Y-%m'), 
     1
   FROM dv_log
   WHERE $uid  and tp_id='$self->{INFO_LIST}->[0]->[8]' and
    (  $WHERE
      ) 
   GROUP BY $GROUP
   ;");

  if ($self->{TOTAL} > 0) {
    my ($class1, $class2)  = (0, 0);
    $self->{INFO_LIST}->[0]->[4]  = 0;
    if ($prepaid_traffic{1}) { $self->{INFO_LIST}->[1]->[4]  = 0 };
    foreach my $line (@{$self->{list}}) {
      $class1      = ((($class1>0) ? $class1 : 0) + $prepaid_traffic{0}) - $line->[0];
      $class2      = ((($class2>0) ? $class2 : 0) + $prepaid_traffic{1}) - $line->[1];
      
      $self->{INFO_LIST}->[0]->[4] += $prepaid_traffic{0};
      if ($prepaid_traffic{1}) {
        $self->{INFO_LIST}->[1]->[4] += $prepaid_traffic{1};
       }
     }
    
    $rest{0} = $class1;
    $rest{1} = $class2;
   }
# }
 
 #Check sessions
 #Get using traffic
# $self->query($db, "select  
#  $rest{0} - sum($octets_direction) / $CONF->{MB_SIZE},
#  $rest{1} - sum($octets_direction2) / $CONF->{MB_SIZE},
#  1
# FROM dv_log
# WHERE $uid ".
# #and tp_id='$self->{INFO_LIST}->[0]->[8]'
#  "AND DATE_FORMAT(start, '%Y-%m-%d')>='$self->{INFO_LIST}->[0]->[3]'
# GROUP BY 3
# ;");
#
# if ($self->{TOTAL} > 0) {
#   ($rest{0}, 
#    $rest{1} 
#    ) =  @{ $self->{list}->[0] };
#  }

 #Check online
 $self->query($db, "select 
  $rest{0} - sum($octets_online_direction) / $CONF->{MB_SIZE},
  $rest{1} - sum($octets_online_direction2) / $CONF->{MB_SIZE},
  1
 FROM dv_calls
 WHERE $uid
 GROUP BY 3;");

 if ($self->{TOTAL} > 0) {
   ($rest{0}, 
    $rest{1} 
    ) =  @{ $self->{list}->[0] };
  }
 
 $self->{REST}=\%rest;
  
 return 1;
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
 
 @WHERE_RULES = (); 
 
  %{$self->{SESSIONS_FIELDS}} = (LOGIN           => 'u.id', 
                                 START           => 'l.start', 
                                 DURATION        => 'SEC_TO_TIME(l.duration)', 
                                 TP              => 'l.tp_id',
                                 SENT            => 'l.sent', 
                                 RECV            => 'l.recv', 
                                 CID             => 'l.CID', 
                                 NAS_ID          => 'l.nas_id', 
                                 IP_INT          => 'l.ip', 
                                 SUM             => 'l.sum', 
                                 IP              => 'INET_NTOA(l.ip)', 
                                 ACCT_SESSION_ID => 'l.acct_session_id', 
                                 UID             => 'l.uid', 
                                 START_UNIX_TIME => 'UNIX_TIMESTAMP(l.start)',
                                 DURATION_SEC    => 'l.duration',
                                 SEND            => 'l.sent2', 
                                 RECV            => 'l.recv2');
 
 if ($attr->{UID}) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{UID}, 'INT', 'l.uid') };
  }
 elsif ($attr->{LOGIN}) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{LOGIN}, 'STR', 'u.id') };
  }

#IP
 if ($attr->{IP}) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{IP}, 'IP', 'l.ip') };
  }

#NAS ID
 if ($attr->{NAS_ID}) {
   push @WHERE_RULES, "l.nas_id='$attr->{NAS_ID}'";
  }

 if ($attr->{SUM}) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{SUM}, 'INT', 'l.sum') };
  }


#NAS ID
 if ($attr->{CID}) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{CID}, 'STR', 'l.cid') }; 
  }

#NAS PORT
 if ($attr->{NAS_PORT}) {
   push @WHERE_RULES, "l.port_id='$attr->{NAS_PORT}'";
  }

#TARIF_PLAN
 if ($attr->{TARIF_PLAN}) {
   push @WHERE_RULES, "l.tp_id='$attr->{TARIF_PLAN}'";
  }

#Session ID
if ($attr->{ACCT_SESSION_ID}) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{ACCT_SESSION_ID}, 'STR', 'l.acct_session_id') }; 
  }

 # Show groups
 if ($attr->{GIDS}) {
   push @WHERE_RULES, "u.gid IN ($attr->{GIDS})"; 
  }
 elsif ($attr->{GID}) {
   push @WHERE_RULES, "u.gid='$attr->{GID}'"; 
  }


if ($attr->{TERMINATE_CAUSE}) {
	push @WHERE_RULES, @{ $self->search_expr($attr->{TERMINATE_CAUSE}, 'INT', 'l.terminate_cause', { EXT_FIELD => 1 }) };
 }
elsif ($attr->{SHOW_TERMINATE_CAUSE}) {
	$self->{SEARCH_FIELDS}.="l.terminate_cause,";
	$self->{SEARCH_FIELDS_COUNT}+=1;
}


if ($attr->{FROM_DATE}) {
   push @WHERE_RULES, "(date_format(l.start, '%Y-%m-%d')>='$attr->{FROM_DATE}' and date_format(l.start, '%Y-%m-%d')<='$attr->{TO_DATE}')";
 }

if ($attr->{DATE}) {
   push @WHERE_RULES, @{ $self->search_expr($attr->{DATE}, 'INT', 'l.start') }; 
 }
elsif ($attr->{MONTH}) {
   push @WHERE_RULES, "date_format(l.start, '%Y-%m')>='$attr->{MONTH}'";
 }


#Interval from date to date
if ($attr->{INTERVAL}) {
 	 my ($from, $to)=split(/\//, $attr->{INTERVAL}, 2);
   push @WHERE_RULES, "date_format(start, '%Y-%m-%d')>='$from' and date_format(start, '%Y-%m-%d')<='$to'";
  }
#Period
elsif (defined($attr->{PERIOD}) ) {
   my $period = int($attr->{PERIOD});   
   if ($period == 4) { $WHERE .= ''; }
   else {
     $WHERE .= ($WHERE ne '') ? ' and ' : 'WHERE ';
     if($period == 0)    {  push @WHERE_RULES, "date_format(start, '%Y-%m-%d')=curdate()"; }
     elsif($period == 1) {  push @WHERE_RULES, "TO_DAYS(curdate()) - TO_DAYS(start) = 1 ";  }
     elsif($period == 2) {  push @WHERE_RULES, "YEAR(curdate()) = YEAR(start) and (WEEK(curdate()) = WEEK(start)) ";  }
     elsif($period == 3) {  push @WHERE_RULES, "date_format(start, '%Y-%m')=date_format(curdate(), '%Y-%m') "; }
     elsif($period == 5) {  push @WHERE_RULES, "date_format(start, '%Y-%m-%d')='$attr->{DATE}' "; }
     #Prev month
     elsif($period == 6) {  push @WHERE_RULES, "date_format(start, '%Y-%m')=date_format(curdate() - interval 1 month, '%Y-%m') "; }
     else {$WHERE .= "date_format(start, '%Y-%m-%d')=curdate() "; }
    }
 }


 $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';


 $self->query($db, "SELECT u.id, l.start, SEC_TO_TIME(l.duration), l.tp_id,
  l.sent + 4294967296 * acct_output_gigawords, l.recv + 4294967296 * acct_input_gigawords, l.CID, l.nas_id, l.ip, l.sum, 
  $self->{SEARCH_FIELDS}
  INET_NTOA(l.ip), 
  l.acct_session_id, 
  l.uid, 
  UNIX_TIMESTAMP(l.start),
  l.duration,
  l.recv2, l.sent2
  FROM dv_log l
  INNER JOIN users u ON (u.uid=l.uid)
  $WHERE
  ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;");


 my $list = $self->{list};



 if ($self->{TOTAL} > 0) {
    my $users_table = ($WHERE =~ /u\./) ? "INNER JOIN users u ON (u.uid=l.uid)" : '' ;
    $self->query($db, "SELECT count(l.uid), SEC_TO_TIME(sum(l.duration)), 
      sum(l.sent + 4294967296 * acct_output_gigawords), sum(l.recv + 4294967296 * acct_input_gigawords), 
      sum(l.sent2), sum(l.recv2), 
      sum(sum)  
      FROM dv_log l
      $users_table
     $WHERE;");

    ($self->{TOTAL},
     $self->{DURATION},
     $self->{TRAFFIC_IN},
     $self->{TRAFFIC_OUT},
     $self->{TRAFFIC2_IN},
     $self->{TRAFFIC2_OUT},
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

  @WHERE_RULES = ();

#Login  
if ($attr->{UIDS}) {
  push @WHERE_RULES, "l.uid IN ($attr->{UIDS})";
 }
elsif ($attr->{UID}) {
	push @WHERE_RULES, "l.uid='$attr->{UID}'";
 }

if($attr->{INTERVAL}) {
 	 my ($from, $to)=split(/\//, $attr->{INTERVAL}, 2);
   push @WHERE_RULES, "date_format(start, '%Y-%m-%d')>='$from' and date_format(start, '%Y-%m-%d')<='$to'";
 }
#Period
elsif (defined($attr->{PERIOD}) ) {
   my $period = int($attr->{PERIOD});   
   if ($period == 4) {  

   	}
   else {
     if($period == 0)    {  push @WHERE_RULES, "date_format(start, '%Y-%m-%d')=curdate()"; }
     elsif($period == 1) {  push @WHERE_RULES, "TO_DAYS(curdate()) - TO_DAYS(start) = 1 ";  }
     elsif($period == 2) {  push @WHERE_RULES, "YEAR(curdate()) = YEAR(start) and (WEEK(curdate()) = WEEK(start)) ";  }
     elsif($period == 3) {  push @WHERE_RULES, "date_format(start, '%Y-%m')=date_format(curdate(), '%Y-%m') "; }
     elsif($period == 5) {  push @WHERE_RULES, "date_format(start, '%Y-%m-%d')='$attr->{DATE}' "; }
    }
 }

  $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';


  $self->query($db, "SELECT 
  SEC_TO_TIME(min(l.duration)), SEC_TO_TIME(max(l.duration)), SEC_TO_TIME(avg(l.duration)), SEC_TO_TIME(sum(l.duration)),
  min(l.sent + 4294967296 * acct_output_gigawords), max(l.sent + 4294967296 * acct_output_gigawords), avg(l.sent + 4294967296 * acct_output_gigawords), sum(l.sent + 4294967296 * acct_output_gigawords),
  min(l.recv + 4294967296 * acct_input_gigawords), max(l.recv + 4294967296 * acct_input_gigawords), avg(l.recv + 4294967296 * acct_input_gigawords), sum(l.recv + 4294967296 * acct_input_gigawords ),
  min(l.recv+l.sent), max(l.recv+l.sent), avg(l.recv+l.sent), sum(l.recv+l.sent)
  FROM dv_log l $WHERE");

  if ($self->{TOTAL} == 0) {
 	  return $self;
   }


  ($self->{min_dur}, 
   $self->{max_dur}, 
   $self->{avg_dur}, 
   $self->{total_dur}, 

   $self->{min_sent}, 
   $self->{max_sent}, 
   $self->{avg_sent},
   $self->{total_sent},
   
   $self->{min_recv}, 
   $self->{max_recv}, 
   $self->{avg_recv}, 
   $self->{total_recv}, 

   $self->{min_sum}, 
   $self->{max_sum}, 
   $self->{avg_sum},
  $self->{total_sum}) =  @{ $self->{list}->[0] };

	return $self;
}


#**********************************************************
# Use
#**********************************************************
sub reports {
	my ($self) = shift;
	my ($attr) = @_;

 $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
 $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
 undef @WHERE_RULES;
 my $date = '';
 my $EXT_TABLES = '';
 my $ext_fields = ', u.company_id';

 my @FIELDS_ARR = ('DATE', 
                   'USERS',
                   'USERS_FIO',
                   'TP',
                   'SESSIONS', 
                   'TRAFFIC_RECV', 
                   'TRAFFIC_SENT',
                   'TRAFFIC_SUM', 
                   'TRAFFIC_2_SUM', 
                   'DURATION', 
                   'SUM',
                   );

 $self->{REPORT_FIELDS} = {DATE            => '',  	
                           USERS           => 'u.id',
                           USERS_FIO       => 'u.fio',
                           SESSIONS        => 'count(l.uid)',
                           TERMINATE_CAUSE => 'l.terminate_cause',                           
                           TRAFFIC_SUM     => 'sum(l.sent + 4294967296 * acct_output_gigawords + l.recv + 4294967296 * acct_input_gigawords)',
                           TRAFFIC_2_SUM   => 'sum(l.sent2 + l.recv2)',
                           DURATION        => 'sec_to_time(sum(l.duration))',
                           SUM             => 'sum(l.sum)',
                           TRAFFIC_RECV    => 'sum(l.recv + 4294967296 * acct_input_gigawords)',
                           TRAFFIC_SENT    => 'sum(l.sent + 4294967296 * acct_output_gigawords)',
                           USERS_COUNT     => 'count(DISTINCT l.uid)',
                           TP              => 'l.tp_id',
                           COMPANIES       => 'c.name'
                          };
 
 
 my $EXT_TABLE = 'users';

  
 if ($attr->{TP_ID}) {
 	 push @WHERE_RULES, " l.tp_id='$attr->{TP_ID}'";
  }

 
 if(defined($attr->{DATE})) {
   push @WHERE_RULES, " date_format(l.start, '%Y-%m-%d')='$attr->{DATE}'";
  }
 elsif ($attr->{INTERVAL}) {
   my ($from, $to)=split(/\//, $attr->{INTERVAL}, 2);
   push @WHERE_RULES, "date_format(l.start, '%Y-%m-%d')>='$from' and date_format(l.start, '%Y-%m-%d')<='$to'";
   $attr->{TYPE}='-' if (! $attr->{TYPE});
   if ($attr->{TYPE} eq 'HOURS' ) {
     $date = "date_format(l.start, '\%H')";
    }
   elsif ($attr->{TYPE} eq 'DAYS') {
     $date = "date_format(l.start, '%Y-%m-%d')";
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
   elsif ($attr->{TYPE} eq 'COMPANIES') {
 	   $date = "c.name";
 	   $EXT_TABLES = "INNER JOIN companies c ON (c.id=u.company_id)";
    }
   else {
     $date = "u.id";   	
    }  
  }
 elsif ($attr->{MONTH}) {
 	 push @WHERE_RULES, "date_format(l.start, '%Y-%m')='$attr->{MONTH}'";
   $date = "date_format(l.start, '%Y-%m-%d')";
  } 
 else {
 	 $date = "date_format(l.start, '%Y-%m')";
  }

 # Compnay
 if ($attr->{COMPANY_ID}) {
   push @WHERE_RULES, "u.company_id=$attr->{COMPANY_ID}"; 
  }

 # Show groups
 if ($attr->{GIDS}) {
   push @WHERE_RULES, "u.gid IN ($attr->{GIDS})"; 
  }
 elsif ($attr->{GID}) {
   push @WHERE_RULES, "u.gid='$attr->{GID}'"; 
  }

 my $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';


$self->{REPORT_FIELDS}{DATE}=$date;
my $fields = "$date, count(DISTINCT l.uid), 
      count(l.uid),
      sum(l.sent + 4294967296 * acct_output_gigawords + l.recv + 4294967296 * acct_input_gigawords), 
      sum(l.sent2 + l.recv2),
      sec_to_time(sum(l.duration)), 
      sum(l.sum)";

if ($attr->{FIELDS}) {
	my @fields_array = split(/, /, $attr->{FIELDS});
	my @show_fields = ();
  my %get_fields_hash = ();

  foreach my $line (@fields_array) {
  	$get_fields_hash{$line}=1;
    if ($line eq 'USERS_FIO') {
      $EXT_TABLE = 'users_pi';
      $date = 'u.fio';
      #$ext_fields = '';
     }
    elsif ($line =~ /^_(\S+)/) {
      #$date = 
      my $f = '_'.$1;
      push @FIELDS_ARR, $f;
      $self->{REPORT_FIELDS}{$f}='u.'.$f;
      $EXT_TABLE  = 'users_pi';
      #$ext_fields = '';
     }
   }
  
  foreach my $k (@FIELDS_ARR) {
    if ($get_fields_hash{$k}) {
      push @show_fields, $self->{REPORT_FIELDS}{$k} ;
     }
  } 

  $fields = join(', ', @show_fields)
}
 
 
 if(defined($attr->{DATE})) {
   if (defined($attr->{HOURS})) {
   	$self->query($db, "select date_format(l.start, '%Y-%m-%d %H')start, '%Y-%m-%d %H')start, '%Y-%m-%d %H'), 
   	count(DISTINCT l.uid), count(l.uid), 
    sum(l.sent + 4294967296 * acct_output_gigawords + l.recv + 4294967296 * acct_input_gigawords), 
     sum(l.sent2 + l.recv2), sec_to_time(sum(l.duration)), sum(l.sum), l.uid $ext_fields
      FROM dv_log l
      LEFT JOIN $EXT_TABLE u ON (u.uid=l.uid)
      $EXT_TABLES
      $WHERE 
      GROUP BY 1 
      ORDER BY $SORT $DESC");
    }
   else {
   	$self->query($db, "select date_format(l.start, '%Y-%m-%d'), if(u.id is NULL, CONCAT('> ', l.uid, ' <'), u.id), count(l.uid), 
    sum(l.sent + 4294967296 * acct_output_gigawords + l.recv + 4294967296 * acct_input_gigawords), sum(l.sent2 + l.recv2), sec_to_time(sum(l.duration)), sum(l.sum), l.uid ext_fields
      FROM dv_log l
      LEFT JOIN $EXT_TABLE u ON (u.uid=l.uid)
      $EXT_TABLES
      $WHERE 
      GROUP BY l.uid 
      ORDER BY $SORT $DESC");
    }
  }
 elsif ($attr->{TP}) {
 	 print "TP";
  }
 else {
  $self->query($db, "select $fields,
      l.uid $ext_fields
       FROM dv_log l
       LEFT JOIN $EXT_TABLE u ON (u.uid=l.uid)
       $EXT_TABLES
       $WHERE    
       GROUP BY 1 
       ORDER BY $SORT $DESC;");
  }

  my $list = $self->{list}; 

  $self->{USERS}    = 0; 
  $self->{SESSIONS} = 0; 
  $self->{TRAFFIC}  = 0; 
  $self->{TRAFFIC_2}= 0; 
  $self->{DURATION} = 0; 
  $self->{SUM}      = 0;

  return $list if ($self->{TOTAL} < 1);

  $self->query($db, "select count(DISTINCT l.uid), 
      count(l.uid),
      sum(l.sent + 4294967296 * acct_output_gigawords),
      sum(l.recv + 4294967296 * acct_input_gigawords), 
      sum(l.sent2),
      sum(l.recv2),
      sec_to_time(sum(l.duration)), 
      sum(l.sum)
       FROM dv_log l
       LEFT JOIN $EXT_TABLE u ON (u.uid=l.uid)
       $EXT_TABLES
       $WHERE;");

 
  ($self->{USERS}, 
   $self->{SESSIONS}, 
   $self->{TRAFFIC_OUT}, 
   $self->{TRAFFIC_IN},
   $self->{TRAFFIC_2_OUT}, 
   $self->{TRAFFIC_2_IN}, 
   $self->{DURATION}, 
   $self->{SUM}) = @{ $self->{list}->[0] };

   $self->{TRAFFIC} = $self->{TRAFFIC_OUT} + $self->{TRAFFIC_IN};
   $self->{TRAFFIC_2} = $self->{TRAFFIC_2_OUT} + $self->{TRAFFIC_2_IN};

	return $list;
}



#**********************************************************
# List
#**********************************************************
sub list_log_intervals {
 my $self = shift;
 my ($attr) = @_;

 $PG = ($attr->{PG}) ? $attr->{PG} : 0;
 $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;
 $SORT = ($attr->{SORT}) ? $attr->{SORT} : 2;
 $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
 
 undef @WHERE_RULES; 
 
 
#UID
 if ($attr->{ACCT_SESSION_ID}) {
    push @WHERE_RULES, "l.acct_session_id='$attr->{ACCT_SESSION_ID}'";
  }

 
 $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';




 $self->query($db, "SELECT interval_id,
                           traffic_type,
                           sent,
                           recv,
                           duration,
                           sum
  FROM dv_log_intervals l
  $WHERE
  ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;");


 my $list = $self->{list};

 return $list;
}

#**********************************************************
# Rotete logs
#**********************************************************
sub log_rotate {
	my $self = shift;
	my ($attr)=@_;
	
  my $version = $self->db_version();
  my @rq = ();
 
 if ($version > 4.1) {
 	 push @rq, 'CREATE TABLE IF NOT EXISTS errors_log_new LIKE errors_log;',
     'CREATE TABLE IF NOT EXISTS errors_log_new_sorted LIKE errors_log;',
     'RENAME TABLE errors_log TO errors_log_old, errors_log_new TO errors_log;',
     'INSERT INTO errors_log_new_sorted SELECT max(date), log_type, action, user, message, nas_id FROM errors_log_old GROUP BY user,message,nas_id;',
     'INSERT INTO errors_log_new_sorted SELECT max(date), log_type, action, user, message, nas_id FROM errors_log GROUP BY user,message,nas_id;',
     'DROP TABLE errors_log_old;',
     'RENAME TABLE errors_log TO errors_log_old, errors_log_new_sorted TO errors_log;',
     'DROP TABLE errors_log_old';

   if (! $attr->{DAILY}) {
     use POSIX qw(strftime);
     my $DATE = (strftime "%Y_%m_%d", localtime(time - 86400));
 	   push @rq,
     'CREATE TABLE IF NOT EXISTS s_detail_new LIKE s_detail;',
     'RENAME TABLE s_detail TO s_detail_'. $DATE .
      ', s_detail_new TO s_detail;',

     #'CREATE TABLE IF NOT EXISTS errors_log_new LIKE errors_log;',
     #'RENAME TABLE errors_log TO errors_log_'. $DATE .
     # ', errors_log_new TO errors_log;',


     'CREATE TABLE IF NOT EXISTS dv_log_intervals_new LIKE dv_log_intervals;',
     'DROP TABLE dv_log_intervals_old',
     'RENAME TABLE dv_log_intervals TO dv_log_intervals_old'.
      ', dv_log_intervals_new TO dv_log_intervals;';
    }
  }
 else {
   push @rq, "DELETE from s_detail
            WHERE last_update < UNIX_TIMESTAMP()- $attr->{PERIOD} * 24 * 60 * 60;";
  
    # LOW_PRIORITY
   push @rq, "DELETE dv_log_intervals from dv_log, dv_log_intervals
     WHERE
     dv_log.acct_session_id=dv_log_intervals.acct_session_id
      and dv_log.start < curdate() - INTERVAL $attr->{PERIOD} DAY;";
  }

  foreach my $query (@rq) {
    $self->query($db, "$query", 'do'); 
   }

	return $self;
}

1

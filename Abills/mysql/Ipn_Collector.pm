package Ipn_Collector;
# Ipn Collector functions


use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION
);

use Exporter;
$VERSION = 2.01;
@ISA = ('Exporter');
@EXPORT = qw(
  &ip_in_zone
  &is_exist
);

@EXPORT_OK = ();
%EXPORT_TAGS = ();

use main;
@ISA  = ("main");


require Billing;
Billing->import();
my $Billing;

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

  if (! defined($CONF->{KBYTE_SIZE})){
  	$CONF->{KBYTE_SIZE}=1024;
   }

  $CONF->{MB_SIZE} = $CONF->{KBYTE_SIZE} * $CONF->{KBYTE_SIZE};
  
  $self->{TRAFFIC_ROWS}=0;
  $self->{UNKNOWN_TRAFFIC_ROWS}=0;

  $Billing = Billing->new($db, $CONF);
  return $self;
}


#**********************************************************
# user_ips
#**********************************************************
sub user_ips {
  my $self = shift;
  my ($DATA) = @_;

  
  my $sql;
  
  if ($DATA->{NAS_ID} =~ /(\d+)-(\d+)/) {
  	my $first = $1;
  	my $last = $2;
  	my @nas_arr = ();
  	for(my $i=$1; $i<=$2; $i++) {
  	  push @nas_arr, $i;
     }

    $DATA->{NAS_ID} = join(',', @nas_arr);
   }
  
  
  if ($CONF->{IPN_STATIC_IP}) {
	  $sql="select u.uid, dv.ip, u.id, 
	   if(calls.acct_session_id, calls.acct_session_id, ''),
	   0,
	   0,
	   dv.tp_id, 
		 if (u.company_id > 0, cb.id, b.id),
		 if (c.name IS NULL, b.deposit, cb.deposit)+u.credit,
		 tp.payment_type,
		 0,
		 0,
		 tp.octets_direction,
		 u.reduction,
		 '',
		 u.activate
		 FROM (users u, dv_main dv)
		 LEFT JOIN companies c ON (u.company_id=c.id)
		 LEFT JOIN bills b ON (u.bill_id=b.id)
		 LEFT JOIN bills cb ON (c.bill_id=cb.id)
		 LEFT JOIN tarif_plans tp ON (tp.id=dv.tp_id)
		 LEFT JOIN dv_calls calls ON (u.id=calls.user_name)
		 WHERE u.uid=dv.uid 
		  and dv.ip > 0 and u.disable=0 and dv.disable=0;";
   }
  elsif ( $CONF->{IPN_DEPOSIT_OPERATION} ) {
  	$sql="select u.uid, calls.framed_ip_address, calls.user_name,
      calls.acct_session_id,
      calls.acct_input_octets,
      calls.acct_output_octets,
      dv.tp_id,
      if(u.company_id > 0, cb.id, b.id),
      if(c.name IS NULL, b.deposit, cb.deposit)+u.credit,
      tp.payment_type,
      UNIX_TIMESTAMP() - calls.lupdated,
      calls.nas_id,
      tp.octets_direction,
      u.reduction,
      CONNECT_INFO,
      u.activate
    FROM (dv_calls calls, users u)
      LEFT JOIN companies c ON (u.company_id=c.id)
      LEFT JOIN bills b ON (u.bill_id=b.id)
      LEFT JOIN bills cb ON (c.bill_id=cb.id)
      LEFT JOIN dv_main dv ON (u.uid=dv.uid)
      LEFT JOIN tarif_plans tp ON (tp.id=dv.tp_id)
    WHERE u.id=calls.user_name
    and calls.nas_id IN ($DATA->{NAS_ID});";
  }
  else {
  	$sql = "SELECT u.uid, calls.framed_ip_address, calls.user_name, 
    calls.acct_session_id,
    calls.acct_input_octets,
    calls.acct_output_octets,
    calls.tp_id,
    NUll,
    NULL,
    1,
    UNIX_TIMESTAMP() - calls.lupdated,
    calls.nas_id,
    0,
    u.reduction,
    CONNECT_INFO,
    u.activate
    FROM (dv_calls calls, users u)
   WHERE u.id=calls.user_name
   and calls.nas_id IN ($DATA->{NAS_ID});";
  }  
  
  $self->query($db, $sql);

  my $list = $self->{list};
  my %session_ids    = ();
  my %users_info     = ();
  my %interim_times  = ();
  my %connect_info   = ();
  
  $ips{0}='0';
  $self->{0}{IN}=0;
 	$self->{0}{OUT}=0;

  foreach my $line (@$list) {
     #UID
  	 $ips{$line->[1]}         = $line->[0];
     
     #IN / OUT octets
  	 $self->{$line->[1]}{IN}  = $line->[4];
  	 $self->{$line->[1]}{OUT} = $line->[5];
     
     #user NAS
     $self->{$line->[1]}{NAS_ID} = $line->[11];
     
     #Octet direction
     $self->{$line->[1]}{OCTET_DIRECTION} = $line->[12];
     
  	 $users_info{TPS}{$line->[0]} = $line->[6];
   	 #User login
   	 $users_info{LOGINS}{$line->[0]} = $line->[2];
     #Session ID
     $session_ids{$line->[1]} = $line->[3];
     $interim_times{$line->[3]}=$line->[10];
     $connect_info{$line->[3]}=$line->[14];
     #$self->{INTERIM}{$line->[3]}{TIME}=$line->[10];

    
     #If post paid set deposit to 0
     #if (defined($line->[9]) && $line->[9] == 1) {
  	   #Payment type 0 - prepaid / 1 - postpaid
  	 $users_info{PAYMENT_TYPE}{$line->[0]} = $line->[9];
  	 #  $users_info{DEPOSIT}{$line->[0]} = 0;
  	 # } 
  	 #else {
  	 $users_info{DEPOSIT}{$line->[0]} = $line->[8];
  	 # }
     $users_info{REDUCTION}{$line->[0]} = $line->[13];
     $users_info{ACTIVATE}{$line->[0]} = $line->[15];
 	   $users_info{BILL_ID}{$line->[0]} = $line->[7];  	 
 	 	
  	 push @clients_lst, $line->[1];
   }
 
  $self->{USERS_IPS}     = \%ips;
  $self->{USERS_INFO}    = \%users_info;
  $self->{SESSIONS_ID}   = \%session_ids;
  $self->{INTERIM_TIME}  = \%interim_times;
  $self->{CONNECT_INFO}  = \%connect_info;
  
  return $self;
}


#**********************************************************
#
#**********************************************************
sub traffic_agregate_clean {
  my $self = shift;
  delete $self->{AGREGATE_USERS};
  delete $self->{INTERIM};
  delete $self->{IN};
}

#**********************************************************
# traffic_agregate_users
# Get Data and agregate it by users
#**********************************************************
sub traffic_agregate_users {
  my $self = shift;
  my ($DATA) = @_;

  my $users_ips=$self->{USERS_IPS};
  my $y = 0;
 
  if (defined($users_ips->{$DATA->{SRC_IP}})) {
 	  push @{ $self->{AGREGATE_USERS}{$users_ips->{$DATA->{SRC_IP}}}{OUT} }, { %$DATA };
 	  $DATA->{UID}=$users_ips->{$DATA->{SRC_IP}};
 		$y++;
   }

  if (defined($users_ips->{$DATA->{DST_IP}})) {
    push @{ $self->{AGREGATE_USERS}{$users_ips->{$DATA->{DST_IP}}}{IN} }, { %$DATA };
    $DATA->{UID}=$users_ips->{$DATA->{DST_IP}};
	  $y++;
   }
  #Unknow Ips
  elsif ($y < 1) {
  	$DATA->{UID}=0;
    if ($CONF->{UNKNOWN_IP_LOG}) {
  	  $self->{INTERIM}{$DATA->{UID}}{OUT}+=$DATA->{SIZE};
      push @{ $self->{IN} }, "$DATA->{SRC_IP}/$DATA->{DST_IP}/$DATA->{SIZE}";	
     }
    $self->{UNKNOWN_TRAFFIC_ROWS}++;
    return $self;
   }
  
  $self->{TRAFFIC_ROWS}++;

  #Make user detalization
  if ($CONF->{IPN_DETAIL} && $DATA->{UID} > 0) {
  	  $self->traffic_add({ 
        SRC_IP   => $DATA->{SRC_IP}, 
        DST_IP   => $DATA->{DST_IP},
        SRC_PORT => $DATA->{SRC_PORT} || 0,
        DST_PORT => $DATA->{DST_PORT} || 0,
        PROTOCOL => $DATA->{PROTOCOL} || 0, 
        SIZE     => $DATA->{SIZE},
        NAS_ID   => $DATA->{NAS_ID} || 0,
        UID      => $DATA->{UID},
        START    => $DATA->{START},
        STOP     => $DATA->{STOP}
      });
   }

  return $self;
}


#**********************************************************
#
#**********************************************************
sub traffic_agregate_nets {
  my $self = shift;
  my ($DATA) = @_;

  my $AGREGATE_USERS  = $self->{AGREGATE_USERS}; 
  my $ips       = $self->{USERS_IPS};
  my $user_info = $self->{USERS_INFO};

  require Dv;
  Dv->import();
  my $Dv = Dv->new($db, undef, $CONF);

  #Get user and session TP
  while (my ($uid, $session_tp) = each ( %{ $user_info->{TPS} } )) {

    my $TP_ID = 0;
    my $user = $Dv->info($uid);

    if ($Dv->{TOTAL} > 0) {
    	$TP_ID = $user->{TP_ID} || 0;
      $self->{USERS_INFO}->{TPS}->{$uid}=$TP_ID;
     }
    
    
    my ($remaining_time, $ret_attr);
    if (! defined( $tp_interval{$TP_ID} )) {
      ($user->{TIME_INTERVALS},
       $user->{INTERVAL_TIME_TARIF},
       $user->{INTERVAL_TRAF_TARIF}) = $Billing->time_intervals($TP_ID);

      ($remaining_time, $ret_attr) = $Billing->remaining_time(0, {
          TIME_INTERVALS      => $user->{TIME_INTERVALS},
          INTERVAL_TIME_TARIF => $user->{INTERVAL_TIME_TARIF},
          INTERVAL_TRAF_TARIF => $user->{INTERVAL_TRAF_TARIF},
          SESSION_START       => $user->{SESSION_START},
          DAY_BEGIN           => $user->{DAY_BEGIN},
          DAY_OF_WEEK         => $user->{DAY_OF_WEEK},
          DAY_OF_YEAR         => $user->{DAY_OF_YEAR},
          REDUCTION           => $user->{REDUCTION},
          POSTPAID            => 1 
         });

       #$tp_interval{$TP_ID} = (defined($ret_attr->{TT}) && $ret_attr->{TT} > 0) ? $ret_attr->{TT} :  0;
       
       $tp_interval{$TP_ID} = ($ret_attr->{FIRST_INTERVAL}) ? $ret_attr->{FIRST_INTERVAL} :  0;
       $intervals{$tp_interval{$TP_ID}}{TIME_TARIFF} = ($ret_attr->{TIME_PRICE}) ? $ret_attr->{TIME_PRICE} :  0;
     }

    print "\nUID: $uid\n####TP $TP_ID Interval: $tp_interval{$TP_ID}  ####\n" if ($self->{debug}); 


    if (! defined(  $intervals{$tp_interval{$TP_ID}}{ZONES} )) {
    	$self->get_zone({ TP_INTERVAL => $tp_interval{$TP_ID} });
     }

   my $data_hash;
   
   #Get agrigation data
   if (defined($AGREGATE_USERS->{$uid})) {
     $data_hash = $AGREGATE_USERS->{$uid};
    }
   # Go to next user
   else {
   	 next;
    }

   my %zones;

   @zoneids = @{ $intervals{$tp_interval{$TP_ID}}{ZONEIDS} };
   %zones   = %{ $intervals{$tp_interval{$TP_ID}}{ZONES} };
    
    if (defined($data_hash->{OUT})) {
      #Get User data array
      my $DATA_ARRAY_REF = $data_hash->{OUT};
      
      foreach my $DATA ( @$DATA_ARRAY_REF ) {
   	    #print "------ < $DATA->{SIZE} ". int2ip($DATA->{SRC_IP}) .":$DATA->{SRC_PORT} -> ". int2ip($DATA->{DST_IP}) .":$DATA->{DST_PORT}\n" if ($self->{debug});
  	    if ( $#zoneids >= 0 ) {
  	     
  	      foreach my $zid (@zoneids) {
    	      if (ip_in_zone($DATA->{DST_IP}, $DATA->{DST_PORT}, $zid, \%zones)) {
		          $self->{INTERIM}{$DATA->{SRC_IP}}{"$zid"}{OUT} += $DATA->{SIZE};
	  	        print " $zid ". int2ip($DATA->{SRC_IP}) .":$DATA->{SRC_PORT} -> ". int2ip($DATA->{DST_IP}) .":$DATA->{DST_PORT}  $DATA->{SIZE} / $zones{$zid}{PriceOut}\n" if ($self->{debug});;
		          last;
		         }
	         }
         
         }
	      else {
	    	  print " < $DATA->{SIZE} ". int2ip($DATA->{SRC_IP}) .":$DATA->{SRC_PORT} -> ". int2ip($DATA->{DST_IP}) .":$DATA->{DST_PORT}\n" if ($self->{debug});
	    	  $self->{INTERIM}{$DATA->{SRC_IP}}{"0"}{OUT} += $DATA->{SIZE};
	       }
      } 
    }

    if (defined($data_hash->{IN})) {
      #Get User data array
      my $DATA_ARRAY_REF = $data_hash->{IN};
      foreach my $DATA ( @$DATA_ARRAY_REF ) {
  	    #print "!!------ < $DATA->{SIZE} ". int2ip($DATA->{SRC_IP}) .":$DATA->{SRC_PORT} -> ". int2ip($DATA->{DST_IP}) .":$DATA->{DST_PORT}\n" if ($self->{debug});
  	    if ($#zoneids >= 0) {
 	        foreach my $zid (@zoneids) {
 		        if (ip_in_zone($DATA->{SRC_IP}, $DATA->{SRC_PORT}, $zid, \%zones)) {
	    	      $self->{INTERIM}{$DATA->{DST_IP}}{"$zid"}{IN} += $DATA->{SIZE};
    		      print " $zid ". int2ip($DATA->{DST_IP}) .":$DATA->{DST_PORT} <- ". int2ip($DATA->{SRC_IP})  .":$DATA->{SRC_PORT}  $DATA->{SIZE} / $zones{$zid}{PriceIn}\n" if ($self->{debug});
  		        last;
		         }
	         }
         }
	      else {
	    	  print " > $DATA->{SIZE} ". int2ip($DATA->{SRC_IP}) .":$DATA->{SRC_PORT} -> ". int2ip($DATA->{DST_IP}) .":$DATA->{DST_PORT}\n" if ($self->{debug});
	    	  $self->{INTERIM}{$DATA->{DST_IP}}{"0"}{IN} += $DATA->{SIZE};
	       }
       }
     }

}

}

#**********************************************************
#
#**********************************************************
sub get_interval_params {
	my $self = shift;


	return \%intervals, \%tp_interval;
}

#**********************************************************
# Get zones from db
#**********************************************************
sub get_zone {
	my $self = shift;
	my ($attr)=@_;


	my $zoneid  = 0;
	my %zones   = ();
	my @zoneids = ();

  my $tariff  = $attr->{TP_INTERVAL} || 0;
 
  require Tariffs;
  Tariffs->import();
  my $tariffs = Tariffs->new($db, $admin, $CONF);
  my $list = $tariffs->tt_list({ TI_ID => $tariff });

  foreach my $line (@$list) {
 	    #$speeds{$line->[0]}{IN}="$line->[4]";
 	    #$speeds{$line->[0]}{OUT}="$line->[5]";
      $zoneid=$line->[0];

      $zones{$zoneid}{PriceIn}=$line->[1]+0;
      $zones{$zoneid}{PriceOut}=$line->[2]+0;
      $zones{$zoneid}{PREPAID_TSUM}=$line->[3]+0;

  	  my $ip_list="$line->[7]";
  	  #Make ip hash
      # !10.10.0.0/24:3400
      # [Negative][IP][/NETMASK][:PORT]
      my @ip_list_array = split(/\n|;/, $ip_list);
      
      push @zoneids, $zoneid;

      my $i = 0;      

      foreach my $ip_full (@ip_list_array) {
   	    if ($ip_full =~ /([!]{0,1})(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})(\/{0,1})(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}|\d{1,2})(:{0,1})(\S{0,100})/ ) {
   	    	my $NEG      = $1 || ''; 
   	    	my $IP       = unpack("N", pack("C4", split( /\./, $2))); 
   	    	my $NETMASK  = (length($4) < 3) ? unpack "N", pack("B*",  ( "1" x $4 . "0" x (32 - $4) )) : unpack("N", pack("C4", split( /\./, "$4")));
   	    	
   	      print "REG $i ID: $zoneid NEGATIVE: $NEG IP: ".  int2ip($IP). " MASK: ". int2ip($NETMASK) ." Ports: $6<br>\n" if ($self->{debug});

  	      $zones{$zoneid}{A}[$i]{IP}   = $IP;
	        $zones{$zoneid}{A}[$i]{Mask} = $NETMASK;
	        $zones{$zoneid}{A}[$i]{Neg}  = $NEG;
        
	        #Get ports
	        @{$zones{$zoneid}{A}[$i]{'Ports'}} = ();
          if ($6 ne '')	{      	
	      	  my @PORTS_ARRAY = split(/,/, $6);
	      	  foreach my $port (@PORTS_ARRAY) {
	      	    push @{$zones{$zoneid}{A}[$i]{Ports}}, $port;
    	      	#while (my $ref2=$sth2->fetchrow_hashref()) {
	            #  if ($DEBUG) { print "$ref2->{'PortNum'} "; }
	            #  push @{$zones{$zoneid}{A}[$i]{Ports}}, $ref2->{'PortNum'};
	            #}
             }
           }
          $i++;
   	     }

        
        
       }
 	 }

   @{$intervals{$tariff}{ZONEIDS}}=@zoneids;
   %{$intervals{$tariff}{ZONES}}=%zones;

   $self->{ZONES_IDS}=$intervals{$tariff}{ZONEIDS};
   $self->{ZONES}=$intervals{$tariff}{ZONES};

   print " Tariff Interval: $tariff\n".
   " Zone Ids:". @{$intervals{$tariff}{ZONEIDS}}."\n".
   " Zones:". %{$intervals{$tariff}{ZONES}}."\n" if ($self->{debug}); 

  return $self;
}





#**********************************************************
# ii?aaaeyao i?eiaaea?iinou aa?ana ciia, ciiu caaaiu NOIA?-IOIA?-oyoai %zones
#**********************************************************
sub ip_in_zone($$$$) {
    my $self;
    my ($ip_num, 
        $port, 
        $zoneid,
        $zone_data) = @_;
    
    my $res = 0;
    # debug
    my %zones = %$zone_data;

    if ($self->{debug}) { print "--- CALL ip_in_zone($ip_num, $port, $zoneid) -> \n"; }
    # eaai ii nieneo aa?ania ciiu
    for (my $i=0; $i<=$#{$zones{$zoneid}{A}}; $i++) {
	     
	     my $adr_hash = \%{ $zones{$zoneid}{A}[$i] };
       
       my $a_ip  = $$adr_hash{'IP'}; 
       my $a_msk = $$adr_hash{'Mask'}; 
       my $a_neg = $$adr_hash{'Neg'}; 
       my $a_ports_ref = \@{ $$adr_hash{'Ports'} };
       
       #print "AAAAAAAA:" . @$a_ports_ref . "\n";
       
       # anee aa?an iiiaaaao a iianaou
       if ( (( $a_ip & $a_msk) == ($ip_num & $a_msk)) && # aa?an niaiaaaao
              (is_exist($a_ports_ref, $port)) ) {       # E ii?o niaiaaaao

          #print ">>". int2ip($a_ip). " & $a_msk / ". int2ip($ip_num) ." $zoneid / $res\n";
	        if ($a_neg) { # anee onoaiiaeai aeo aua?anuaaiey aa?ana
		        $res = 0; # oi aua?anuaaai iaeaaiiue aa?an ec ciiu
	         } 
	        else {
		        $res = 1;
            #print ">>". int2ip($a_ip). " & $a_msk / ". int2ip($ip_num) ." $zoneid / $res\n";
		        next; #next
	         }
	      }
    }
    
    #if ($self->{debug}) { print "IP is " . ($res ? "" : "not ") . "in zone $zoneid\n";  }
    return $res;									  												      
}



#**********************************************************
# traffic_add_log
#**********************************************************
sub traffic_add_user {
  my $self = shift;
  my ($DATA) = @_;
 
  my $start = (! $DATA->{START}) ? 'now()':  "'$DATA->{START}'";
  my $stop  = (! $DATA->{STOP}) ?  0 : "'$DATA->{STOP}'";
 
 
  if ($DATA->{INBYTE} + $DATA->{OUTBYTE} > 0) {
    $self->query($db, "insert into ipn_log (
         uid,
         start,
         stop,
         traffic_class,
         traffic_in,
         traffic_out,
         nas_id,
         ip,
         interval_id,
         sum,
         session_id
       )
     VALUES (
       '$DATA->{UID}',
        $start,
        $stop,
       '$DATA->{TARFFIC_CLASS}',
       '$DATA->{INBYTE}',
       '$DATA->{OUTBYTE}',
       '$DATA->{NAS_ID}',
       '$DATA->{IP}',
       '$DATA->{INTERVAL}',
       '$DATA->{SUM}',
       '$DATA->{SESSION_ID}'
      );", 'do');
   }


  if ($self->{USERS_INFO}->{DEPOSIT}->{$DATA->{UID}}) {
  	#Take money from bill
    if ($DATA->{SUM} > 0) {
   	  $self->query($db, "UPDATE bills SET deposit=deposit-$DATA->{SUM} WHERE id='$self->{USERS_INFO}->{BILL_ID}->{$DATA->{UID}}';", 'do');
     }
    #If negative deposit hangup
    if ($self->{USERS_INFO}->{DEPOSIT}->{$DATA->{UID}} - $DATA->{SUM} < 0) {
      $self->{USERS_INFO}->{DEPOSIT}->{$DATA->{UID}}=$self->{USERS_INFO}->{DEPOSIT}->{$DATA->{UID}} - $DATA->{SUM};
     }
   }

  return $self;
}


#**********************************************************
# traffic_user_get
# Get used traffic from DB
#**********************************************************
sub traffic_user_get {
  my $self = shift;
  my ($attr) = @_;

  my $uid        = $attr->{UID};
  my $traffic_id = $attr->{TRAFFIC_ID} || 0;
  my $from       = $attr->{FROM} || '';
  my %result = ();


  if ($attr->{DATE_TIME}) {
  	$WHERE = "start>=$attr->{DATE_TIME}";
   }
  elsif ($attr->{INTERVAL}) {
  	my ($from, $to)=split(/\//, $attr->{INTERVAL});
  	$from = ($from eq '0000-00-00') ? 'DATE_FORMAT(start, \'%Y-%m\')>=DATE_FORMAT(curdate(), \'%Y-%m\')' : "DATE_FORMAT(start, '\%Y-\%m-\%d')>='$from'";
  	$WHERE = "( $from AND start<'$to') ";
   }
  elsif ($attr->{ACTIVATE} && $attr->{ACTIVATE} ne '0000-00-00') {
  	$WHERE = "DATE_FORMAT(start, '%Y-%m-%d')>='$attr->{ACTIVATE}'";
   }
  else {
    $WHERE = "DATE_FORMAT(start, '%Y-%m')>=DATE_FORMAT(curdate(), '%Y-%m')";
   }

  $self->query($db, "SELECT traffic_class, sum(traffic_in) / $CONF->{MB_SIZE}, sum(traffic_out) / $CONF->{MB_SIZE} 
    FROM ipn_log
        WHERE uid='$uid'
        and $WHERE
        GROUP BY uid, traffic_class;");
 
  foreach my $line (@{ $self->{list} }) {
    #Trffic class
  	$result{$line->[0]}{TRAFFIC_IN}=$line->[1];
  	$result{$line->[0]}{TRAFFIC_OUT}=$line->[2];
   }

  return \%result;
}
 
#**********************************************************
# traffic_add
#**********************************************************
sub traffic_add {
  my $self = shift;
  my ($DATA) = @_;

 #my $table_name = 'ipn_traf_detail';
 my $UID = $DATA->{UID} || 0;

 $DATA->{START} = (! $DATA->{START}) ? 'now()' : "'$DATA{START}'";
 $DATA->{STOP}  = (! $DATA->{STOP}) ?  'now()' : "'$DATA{STOP}'";

 $self->query($db, "insert into ipn_traf_detail (src_addr,
       dst_addr,
       src_port,
       dst_port,
       protocol,
       size,
       s_time,
       f_time,
       nas_id,
       uid)
     VALUES (
        $DATA->{SRC_IP},
        $DATA->{DST_IP},
       '$DATA->{SRC_PORT}',
       '$DATA->{DST_PORT}',
       '$DATA->{PROTOCOL}',
       '$DATA->{SIZE}',
        $DATA->{START},
        $DATA->{STOP},
        '$DATA->{NAS_ID}',
        '$UID'
      );", 'do');

  return $self;
}



#**********************************************************
# Acct_stop
#**********************************************************
sub acct_stop {
  my $self = shift;
  my ($attr) = @_;
  my $session_id;


  if (defined($attr->{SESSION_ID})) {
  	$session_id=$attr->{SESSION_ID};
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
    WHERE u.id=calls.user_name and acct_session_id='$session_id';";

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
   WHERE session_id='$session_id'
   GROUP BY session_id  ;");  


  if ($self->{TOTAL} < 1) {
    $self->{TRAFFIC_IN}=0;
    $self->{TRAFFIC_OUT}=0;
    $self->{SUM}=0;
    $self->{NAS_ID}=0;
    $self->query($db, "DELETE from dv_calls WHERE acct_session_id='$self->{ACCT_SESSION_ID}';", 'do');
    return $self;
  }
  
  ($self->{TRAFFIC_IN},
   $self->{TRAFFIC_OUT},
   $self->{SUM}
  ) = @{ $self->{list}->[0] };



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
    terminate_cause) 
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
          '$ACCT_TERMINATE_CAUSE');", 'do');

  $self->query($db, "DELETE from dv_calls WHERE acct_session_id='$self->{ACCT_SESSION_ID}';", 'do');

}

#*******************************************************************
# Convert integer value to ip
# int2ip($i);
#*******************************************************************
sub tcollector {
 my $self = shift;
 my ($attr) = @_;


 return $self;
}


#**********************************************************
#
#**********************************************************
sub is_client_ip($) {
  my $self = shift;
  my $ip = shift @_;

  if ($self->{debug}) { print "--- CALL is_client_ip($ip),\t\$#clients_lst = $#clients_lst\n"; }
  if ($#clients_lst < 0) {return 0;} # nienie iono!
  foreach my $i (@clients_lst) {
	  if ($i eq $ip) { return 1; }
   }
  if ($self->{debug}) { print "   Client $ip not found in \@clients_lst\n"; }

  return 0;
}

#**********************************************************
#
#**********************************************************
sub is_exist($$) {
  my ($arrayref, $elem) = @_;
  # anee nienie iono, n?eoaai, ?oi yeaiaio a iaai iiiaaaao
  if ($#{ $arrayref } == -1) { return 1; }
    
  foreach my $e (@$arrayref) {
    if ($e eq $elem) { return 1; }
   }
 return 0;
}


#*******************************************************************
# Convert integer value to ip
# int2ip($i);
#*******************************************************************
sub int2ip {
my $i = shift;

my (@d);
$d[0]=int($i/256/256/256);
$d[1]=int(($i-$d[0]*256*256*256)/256/256);
$d[2]=int(($i-$d[0]*256*256*256-$d[1]*256*256)/256);
$d[3]=int($i-$d[0]*256*256*256-$d[1]*256*256-$d[2]*256);
 return "$d[0].$d[1].$d[2].$d[3]";
}







1



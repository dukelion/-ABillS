#!/usr/bin/perl -w

use vars  qw(%RAD %conf %AUTH
 %RAD_REQUEST %RAD_REPLY %RAD_CHECK 
 $nas
 $Log
 $begin_time
);

use strict;
use FindBin '$Bin';
require $Bin . '/config.pl';
unshift(@INC, $Bin . '/../', $Bin . "/../Abills/$conf{dbtype}");

require Abills::Base;
Abills::Base->import( qw(check_time get_radius_params) );
$begin_time = check_time();

my %auth_mod = ();
require Abills::SQL;
my $sql = Abills::SQL->connect($conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd});
my $db  = $sql->{db};
require Nas;
$nas    = undef;

require Auth;
Auth->import();

require Log;
Log->import('log_print');

my $GT  = '';
my $rr  = '';

my $RAD = get_radius_params();

if ($RAD->{NAS_IP_ADDRESS}) {
  $Log = Log->new($db, \%conf);
  my $ret = get_nas_info($db, $RAD);
  if (defined($ARGV[0]) && $ARGV[0] eq 'pre_auth') {
    auth($db, $RAD, $nas, { pre_auth => 1 });
    exit 0;
   }
  elsif (defined($ARGV[0]) && $ARGV[0] eq 'post_auth') {
    inc_postauth($db, $RAD, $nas);
    exit 0;
   }

  if($ret == 0) {
    $ret = auth($db, $RAD, $nas);
  }

  if ($ret == 0) {
    print $rr;
   }
  elsif($RAD_REPLY{'Reply-Message'}) {
    print "Reply-Message = \"$RAD_REPLY{'Reply-Message'}\"\n";
   }

  exit $ret;
}


#*******************************************************************
# get_nas_info();
#*******************************************************************
sub get_nas_info {
 my ($db, $RAD)=@_;
 
 $nas = Nas->new($db, \%conf);
 
 $RAD->{NAS_IP_ADDRESS}='' if (!defined($RAD->{NAS_IP_ADDRESS}));
 $RAD->{USER_NAME}='' if (! defined($RAD->{USER_NAME}));

 my %NAS_PARAMS = ('IP' => "$RAD->{NAS_IP_ADDRESS}");
 
 if ($RAD->{NAS_IP_ADDRESS} eq '0.0.0.0' && ! $RAD->{'DHCP_MESSAGE_TYPE'}) {
 	 %NAS_PARAMS = ( CALLED_STATION_ID => $RAD->{CALLED_STATION_ID} );
  }

 $NAS_PARAMS{NAS_IDENTIFIER}=$RAD->{NAS_IDENTIFIER} if ($RAD->{NAS_IDENTIFIER});
 $nas->info({ %NAS_PARAMS });

if (defined($nas->{errno}) || $nas->{TOTAL} < 1) {
	if ($RAD->{MIKROTIK_HOST_IP}) {		
		$nas->info({ NAS_ID => $RAD->{NAS_IDENTIFIER} });
		if (defined($nas->{errno}) || $nas->{TOTAL} < 1) {
      access_deny("$RAD->{USER_NAME}", "Unknow server '$RAD->{NAS_IP_ADDRESS}'". 
        (($RAD->{NAS_IDENTIFIER}) ? " Nas-Identifier: $RAD->{NAS_IDENTIFIER}" : ''  )
       .' '. (( $RAD->{NAS_IP_ADDRESS} eq '0.0.0.0' ) ? $RAD->{CALLED_STATION_ID} : ''), 0, $db);
      $RAD_REPLY{'Reply-Message'}="Unknow server '$RAD->{NAS_IP_ADDRESS}'";
      return 1;
		 }
	  $nas->{NAS_IP}=$RAD->{NAS_IP_ADDRESS};
	 }
  else {
    access_deny("$RAD->{USER_NAME}", "Unknow server '$RAD->{NAS_IP_ADDRESS}'". 
      (($RAD->{NAS_IDENTIFIER}) ? " Nas-Identifier: $RAD->{NAS_IDENTIFIER}" : ''  )
     .' '. (( $RAD->{NAS_IP_ADDRESS} eq '0.0.0.0' && ! $RAD->{'DHCP_MESSAGE_TYPE'} ) ? $RAD->{CALLED_STATION_ID} : ''), 0, $db);
    $RAD_REPLY{'Reply-Message'}="Unknow server '$RAD->{NAS_IP_ADDRESS}'";
    return 1;
   }
 }
elsif(! $nas->{NAS_TYPE} eq 'dhcp' && (! defined($RAD->{USER_NAME}) || $RAD->{USER_NAME} eq '')) {
  return 1;
 }
elsif($nas->{NAS_DISABLE} > 0) {
  access_deny("$RAD->{USER_NAME}", "Disabled NAS server '$RAD->{NAS_IP_ADDRESS}'", 0, $db);
  return 1;
}

  $nas->{at} = 0 if (defined($RAD->{CHAP_PASSWORD}) && defined($RAD->{CHAP_CHALLENGE}));
  return 0;
}


#*******************************************************************
# auth();
#*******************************************************************
sub auth {
 my ($db, $RAD, $nas, $attr)=@_;
 my ($r, $RAD_PAIRS);

 $Log = Log->new($db, \%conf);
 $Log->{ACTION} = 'AUTH';
 
 if(defined($conf{tech_works})) {
 	 $RAD_REPLY{'Reply-Message'}="$conf{tech_works}";
 	 return 1;
  }

 if ($attr->{'pre_auth'}) {
   my $nas_type = ($AUTH{$nas->{NAS_TYPE}}) ? $nas->{NAS_TYPE} : 'default';
   
   if ($AUTH{$nas_type} && ! defined($auth_mod{$nas_type})) {
     require $AUTH{$nas_type} . ".pm";
     $AUTH{$nas_type}->import();
    }

   if ($AUTH{$nas->{NAS_TYPE}}) {
   	  $auth_mod{$nas_type} = $AUTH{$nas_type}->new($db, \%conf);
    }
   else {
   	  $auth_mod{$nas_type} = Auth->new($db, \%conf);
    }
   
   $r = $auth_mod{$nas_type}->pre_auth($RAD, $nas);

   if ($auth_mod{$nas_type}->{errno}) {
     $Log->log_print('LOG_INFO', $RAD->{USER_NAME}, "MS-CHAP PREAUTH FAILED. Wrong password or login$GT", { NAS => $nas });
    }
   else {
      while(my($k, $v)=each(%{ $auth_mod{$nas_type}->{'RAD_CHECK'} })) {
      	$RAD_CHECK{$k}=$v;
       }
    }
   return $r;	
  }
 $rr = '';

if ($RAD->{DHCP_MESSAGE_TYPE}) {
	$nas->{NAS_TYPE}='dhcp';
}

if($AUTH{$nas->{NAS_TYPE}}) {
  if (! defined($auth_mod{"$nas->{NAS_TYPE}"})) {
    require $AUTH{$nas->{NAS_TYPE}} . ".pm";
    $AUTH{$nas->{NAS_TYPE}}->import();
   }

  $auth_mod{"$nas->{NAS_TYPE}"}->{INFO}=undef;
  $auth_mod{"$nas->{NAS_TYPE}"} = $AUTH{$nas->{NAS_TYPE}}->new($db, \%conf);
  ($r, $RAD_PAIRS) = $auth_mod{"$nas->{NAS_TYPE}"}->auth($RAD, $nas, { RAD_REQUEST => \%RAD_REQUEST });
}
else {
  $auth_mod{'default'} = Auth->new($db, \%conf); 
  ($r, $RAD_PAIRS) = $auth_mod{"default"}->dv_auth($RAD, $nas, 
                                       { MAX_SESSION_TRAFFIC => $conf{MAX_SESSION_TRAFFIC}  } );
}

%RAD_REPLY = %$RAD_PAIRS;
    
#If Access deny
 if($r == 1){
    my $message = "$RAD_PAIRS->{'Reply-Message'} ";
    if ($RAD_PAIRS->{'Reply-Message'} eq 'SQL error') {
    	undef %auth_mod;
     }

    if ($auth_mod{"default"}->{errstr}) {
    	 $auth_mod{"default"}->{errstr}=~s/\n//g;
    	 $message .= $auth_mod{"default"}->{errstr};
     }

    my $CID = ($RAD->{CALLING_STATION_ID}) ? " CID: $RAD->{CALLING_STATION_ID} " : '';
    access_deny("$RAD->{USER_NAME}", "$message$CID", $nas->{NAS_ID}, $db);
    $RAD_CHECK{'Auth-Type'} = 'Reject';
    return $r;
  }
 else {
 	 #GEt Nas rad pairs
 	 $nas->{NAS_RAD_PAIRS} =~ tr/\n\r//d;

   my @pairs_arr = split(/,/, $nas->{NAS_RAD_PAIRS});
   foreach my $line (@pairs_arr) {
     if ($line =~ /([a-zA-Z0-9\-]{6,25})\+\=(.{1,200})/ ) {
       my $left=$1;
       my $right=$2;
 	     push @{ $RAD_REPLY{"$left"} }, $right;
      }
     else {
       my($left, $right)=split(/=/, $line, 2);
       if ($left =~ s/^!//) {
         delete $RAD_REPLY{"$left"};
   	    }
   	   else {
   	     $RAD_REPLY{"$left"}="$right";
   	    }
       }
     }

   $RAD_CHECK{'Auth-Type'} = 'Accept' if ($RAD->{CHAP_PASSWORD});
   #Show pairs
   while(my($rs, $ls)=each %RAD_REPLY) {
     if (ref($ls) eq 'ARRAY') {
     	 $rr .= "$rs += " . join(",\n$rs += ", @$ls);
         $rr .= ",\n";
     	}
     else {
       $rr .= "$rs = $ls,\n";
     }
    }

   $Log->log_print('LOG_DEBUG', $RAD->{USER_NAME}, "$rr", { NAS => $nas });
 }



 if ($begin_time > 0)  {
   Time::HiRes->import(qw(gettimeofday));
   my $end_time = gettimeofday();
   my $gen_time = $end_time - $begin_time;
   $GT = sprintf(" GT: %2.5f", $gen_time);
  }

  my $CID = ($RAD->{CALLING_STATION_ID}) ? " CID: $RAD->{CALLING_STATION_ID} " : '';

  $Log->log_print('LOG_INFO', $RAD->{USER_NAME}, (($auth_mod{"$nas->{NAS_TYPE}"}->{INFO}) ? ' '.$auth_mod{"$nas->{NAS_TYPE}"}->{INFO} : '')."$CID$GT", { NAS => $nas });
  return $r;
}



#*******************************************************************
# inc_postauth()
#*******************************************************************
sub inc_postauth {
  my ($db, $RAD) = @_;
  
  
  use constant    L_DBG=>         1;
  use constant    L_AUTH=>        2;
  use constant    L_INFO=>        3;
  use constant    L_ERR=>         4;
  use constant    L_PROXY=>       5;
  use constant    L_CONS=>        128;
  $Log->{ACTION} = 'AUTH';
  my $reject_info = '';
# DHCP Section  
  if ($RAD_REQUEST{'DHCP-Message-Type'}) {
#    &radiusd::radlog(L_ERR, " --- START --- ". $RAD_REQUEST{'DHCP-Server-IP-Address'});

    if ($RAD_REQUEST{'DHCP-Gateway-IP-Address'}) {
    	$RAD_REQUEST{'Nas-IP-Address'}=$RAD_REQUEST{'DHCP-Gateway-IP-Address'};
     }
    else {
      $RAD_REQUEST{'Nas-IP-Address'}=$RAD_REQUEST{'DHCP-Server-IP-Address'};
     }

    $RAD_REQUEST{'User-Name'}=$RAD_REQUEST{'DHCP-Client-Hardware-Address'};
    my $db = sql_connect();
    #Don't find nas exit
    if (! $db ) {
    	return 1;
     }
    $nas->{NAS_TYPE}='dhcp';
    my $Log = Log->new($db, \%conf); 
    $Log->{ACTION} = 'AUTH';
    if (! defined($auth_mod{"$nas->{NAS_TYPE}"})) {
      require $AUTH{$nas->{NAS_TYPE}} . ".pm";
      $AUTH{$nas->{NAS_TYPE}}->import();
     }

    $auth_mod{"$nas->{NAS_TYPE}"} = $AUTH{$nas->{NAS_TYPE}}->new($db, \%conf);
    my ($r, $RAD_PAIRS) = $auth_mod{"$nas->{NAS_TYPE}"}->auth(\%RAD_REQUEST, $nas);
    my $message = $RAD_PAIRS->{'Reply-Message'} || '';
    
    if ($auth_mod{"$nas->{NAS_TYPE}"}->{INFO}) {
    	 $message .= $auth_mod{"$nas->{NAS_TYPE}"}->{INFO};
     }

    if ($r == 2) {
      $Log->log_print('LOG_INFO', $RAD_PAIRS->{'User-Name'}, $message." ". $RAD_REQUEST{'DHCP-Client-Hardware-Address'} ." $GT", { NAS => $nas });
      $r=0;
     }
    else {
    	$RAD_REPLY{'DHCP-DHCP-Error-Message'} = "$message";
    	access_deny($RAD_PAIRS->{'User-Name'}, "$message$GT", $nas->{NAS_ID}, $db);
    	$r=1 if (! $r);
     }
 
    delete($RAD_REQUEST{'User-Name'}); 
    while(my ($k, $v) = each %$RAD_PAIRS) {
    	$RAD_REPLY{$k}=$v;
     }

    my $out = "\nREQUEST ======================================\n";

    while(my ($k, $v) = each %RAD_REQUEST) {
    	$out.="$k -> $v\n";
     }
    
    $out .= "RePLY ======================================\n";
    while(my ($k, $v) = each %RAD_REPLY) {
    	$out.="$k -> $v\n";
     }

#    my $rew = `echo "$out" >> /tmp/rad_dhcp`;
    return $r;
   }
# END DHCP SECTION

  if (%RAD_REQUEST) {
    if ($RAD_REPLY{'Reply-Message'}) {
      return 0;
     }

    my $db = sql_connect();
    if ($RAD_REQUEST{'Calling-Station-Id'}) {
      $reject_info="CID: $RAD_REQUEST{'Calling-Station-Id'}";
     }
    $Log->log_print('LOG_WARNING', $RAD_REQUEST{'User-Name'}, "REJECT Wrong password or account not exists $reject_info$GT", { NAS => $nas });
    return 0;
   }
  else {  	 
    if ($RAD->{CALLING_STATION_ID}) {
      $reject_info="CID: $RAD->{CALLING_STATION_ID}";
     }

    $Log->log_print('LOG_WARNING', $RAD->{USER_NAME}, "REJECT Wrong password or account not exists $reject_info$GT", { NAS => $nas });
   }
}



#*******************************************************************
# access_deny($user, $message);
#*******************************************************************
sub access_deny { 
  my ($user_name, $message, $nas_num, $db, $attr) = @_;

  my $Log = Log->new($db, \%conf);
  $Log->{ACTION} = 'AUTH';
  $Log->log_print('LOG_WARNING', $user_name, "$message", { NAS => $nas });
  
  #External script for error connections
  if ($conf{AUTH_ERROR_CMD}) {
  	 my @cmds = split(/;/, $conf{AUTH_ERROR_CMD});
  	 my $RAD  = get_radius_params();
  	 foreach my $expr_cmd (@cmds) {
  	 	 $RAD->{NAS_PORT}=0 if (! $RAD->{NAS_PORT});
  	 	 my ($expr, $cmd)=split(/:/, $expr_cmd);
  	 	 	  if ($message =~ /$expr/) {
  	 	 	  	my $result = system("$cmd USER_NAME=$user_name NAS_PORT=$RAD->{NAS_PORT} NAS_IP=$nas->{NAS_IP} ERROR=$message");
  	 	 	   }
  	 	  }
  	  }
  return 1;
}

1

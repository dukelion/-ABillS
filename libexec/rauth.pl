#!/usr/bin/perl -w




use vars  qw(%RAD %conf %AUTH
 %RAD_REQUEST %RAD_REPLY %RAD_CHECK 
 %log_levels
 $nas
 $begin_time
);

use strict;
use FindBin '$Bin';
require $Bin . '/config.pl';
unshift(@INC, $Bin . '/../', $Bin . "/../Abills/$conf{dbtype}");

require Abills::Base;
Abills::Base->import();
$begin_time = check_time();

# Max session tarffic limit  (Mb)
my %auth_mod = ();
require Abills::SQL;
my $sql = Abills::SQL->connect($conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd});
my $db  = $sql->{db};
require Nas;
$nas = undef;

require Auth;
Auth->import();

my $GT  = '';
my $rr  = '';

#my $t = "\n\n";
#while(my($k, $v)=each(%$RAD)) {
#	$t .= "$k=\\\"$v\\\"\n";
#}
##print $t;
#my $a = `echo "$t" >> /tmp/voip_test`;

#if (scalar(%RAD_REQUEST ) < 1 ) {

my $log_print = sub {
  my ($LOG_TYPE, $USER_NAME, $MESSAGE, $attr) = @_;


  my $Nas = $attr->{NAS}; 

  if ($conf{debugmods} =~ /$LOG_TYPE/) {
    if ($conf{ERROR2DB} && $attr->{NAS}) {

      $Nas->log_add({LOG_TYPE => $log_levels{$LOG_TYPE},
                     ACTION   => 'AUTH', 
                     USER_NAME=> "$USER_NAME",
                     MESSAGE  => "$MESSAGE"
                    });

     }
    else {
      log_print("$LOG_TYPE", "AUTH [$USER_NAME] NAS: $Nas->{NAS_ID} ($Nas->{NAS_IP}) $MESSAGE");      
     }
   }
};


my $RAD = get_radius_params();
if ($RAD->{NAS_IP_ADDRESS}) {	
  my $ret = get_nas_info($db, $RAD);
  if (defined($ARGV[0]) && $ARGV[0] eq 'pre_auth') {
    auth($db, $RAD, $nas, { pre_auth => 1 });
    exit 0;
   }
  elsif (defined($ARGV[0]) && $ARGV[0] eq 'post_auth') {
    post_auth($RAD);
    exit 0;
   }

  
  if($ret == 0) {
    $ret = auth($db, $RAD, $nas);
  }
  #$db->disconnect();
  
  if ($ret == 0) {
    print $rr;
   }
  else {
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
 
 if ($RAD->{NAS_IP_ADDRESS} eq '0.0.0.0') {
 	 %NAS_PARAMS = ( CALLED_STATION_ID => $RAD->{CALLED_STATION_ID} );
  }
 	
 	
 
 $NAS_PARAMS{NAS_IDENTIFIER}=$RAD->{NAS_IDENTIFIER} if ($RAD->{NAS_IDENTIFIER});
 $nas->info({ %NAS_PARAMS });

if (defined($nas->{errno}) || $nas->{TOTAL} < 1) {
  access_deny("$RAD->{USER_NAME}", "Unknow server '$RAD->{NAS_IP_ADDRESS}'". (( $RAD->{NAS_IP_ADDRESS} eq '0.0.0.0' ) ? $RAD->{CALLED_STATION_ID} : '') ." [$nas->{errno}] $nas->{errstr}", 0);
  $RAD_REPLY{'Reply-Message'}="Unknow server '$RAD->{NAS_IP_ADDRESS}'";
  return 1;
 }
elsif(! defined($RAD->{USER_NAME}) || $RAD->{USER_NAME} eq '') {
  return 1;
 }
elsif($nas->{NAS_DISABLE} > 0) {
  access_deny("$RAD->{USER_NAME}", "Disabled NAS server '$RAD->{NAS_IP_ADDRESS}'", 0);
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

 if(defined($conf{tech_works})) {
 	 $RAD_REPLY{'Reply-Message'}="$conf{tech_works}";
 	 return 1;
  }

 

 if ($attr->{'pre_auth'}) {
   $auth_mod{'default'} = Auth->new($db, \%conf);
   $r = $auth_mod{'default'}->pre_auth($RAD);
   if ($auth_mod{'default'}->{errno}) {
     $log_print->('LOG_INFO', $RAD->{USER_NAME}, "MS-CHAP PREAUTH FAILED$GT", { NAS => $nas });
    }
   else {
      while(my($k, $v)=each(%{ $auth_mod{'default'}->{'RAD_CHECK'} })) {
      	$RAD_CHECK{$k}=$v;
       }
    }
   return $r;	
  }


 $rr = '';


if(defined($AUTH{$nas->{NAS_TYPE}})) {
  if (! defined($auth_mod{"$nas->{NAS_TYPE}"})) {
    require $AUTH{$nas->{NAS_TYPE}} . ".pm";
    $AUTH{$nas->{NAS_TYPE}}->import();
   }

  $auth_mod{"$nas->{NAS_TYPE}"} = $AUTH{$nas->{NAS_TYPE}}->new($db, \%conf);
  ($r, $RAD_PAIRS) = $auth_mod{"$nas->{NAS_TYPE}"}->auth($RAD, $nas);
}
else {
  $auth_mod{'default'} = Auth->new($db, \%conf); # if (! $auth_mod{'default'});
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
    access_deny("$RAD->{USER_NAME}", "$message$CID", $nas->{NAS_ID});
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

      $RAD_CHECK{'Auth-Type'} = 'Accept' if (RAD->{CHAP_PASSWORD});
     }
   
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

   $log_print->('LOG_DEBUG', $RAD->{USER_NAME}, "$rr", { NAS => $nas});
 }

 if ($begin_time > 0)  {
   Time::HiRes->import(qw(gettimeofday));
   my $end_time = gettimeofday();
   my $gen_time = $end_time - $begin_time;
   $GT = sprintf(" GT: %2.5f", $gen_time);
  }


  my $CID = ($RAD->{CALLING_STATION_ID}) ? " CID: $RAD->{CALLING_STATION_ID} " : '';

  $log_print->('LOG_INFO', $RAD->{USER_NAME}, "$CID$GT", { NAS => $nas});
  return $r;
}



#*******************************************************************
# post_auth()
#*******************************************************************
sub post_auth {
  my ($RAD) = @_;
  my $reject_info = '';
  if (defined(%RAD_REQUEST)) {

    if ($RAD_REQUEST{'Calling-Station-Id'}) {
      $reject_info=" CID $RAD_REQUEST{'Calling-Station-Id'}";
     }
    $log_print->('LOG_WARNING', $RAD_REQUEST{'User-Name'}, "REJECT Wrong password $reject_info$GT", { NAS => $nas});
    return 0;
   }
  else { 
    if ($RAD->{CALLING_STATION_ID}) {
      $reject_info=" CID $RAD->{CALLING_STATION_ID}";
     }
    $log_print->('LOG_WARNING', $RAD->{USER_NAME}, "REJECT Wrong password$reject_info$GT", { NAS => $nas});
   }
}



#*******************************************************************
# access_deny($user, $message);
#*******************************************************************
sub access_deny { 
  my ($user_name, $message, $nas_num) = @_;

  $log_print->('LOG_WARNING', $user_name, "$message", { NAS => $nas});

  #External script for error connections
  if ($conf{AUTH_ERROR_CMD}) {
  	 my @cmds = split(/;/, $conf{AUTH_ERROR_CMD});
  	 
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

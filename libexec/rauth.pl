#!/usr/bin/perl -w




use vars  qw(%RAD %conf $db %AUTH
 %RAD_REQUEST %RAD_REPLY %RAD_CHECK 
 %auth_mod
 $begin_time
 $nas);

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
$auth_mod{'default'} = Auth->new($db, \%conf);

my $GT  = '';
my $rr  = '';

#my $t = "\n\n";
#while(my($k, $v)=each(%$RAD)) {
#	$t .= "$k=\\\"$v\\\"\n";
#}
##print $t;
#my $a = `echo "$t" >> /tmp/voip_test`;

# files auth section
my $RAD;

if (scalar(keys %RAD_REQUEST ) < 1 ) {
  $RAD = get_radius_params();
  if (defined($ARGV[0]) && $ARGV[0] eq 'pre_auth') {
    auth($db, $RAD, { pre_auth => 1 });
    exit 0;
   }
  elsif (defined($ARGV[0]) && $ARGV[0] eq 'post_auth') {
    post_auth();
    exit 0;
   }

  my $ret = get_nas_info($db, $RAD);
  if($ret == 0) {
    $ret = auth($db, $RAD);
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
 $RAD->{USER_NAME}='' if (!defined($RAD->{USER_NAME}));

 my %NAS_PARAMS = ('IP' => "$RAD->{NAS_IP_ADDRESS}");
 $NAS_PARAMS{NAS_IDENTIFIER}=$RAD->{NAS_IDENTIFIER} if (defined($RAD->{NAS_IDENTIFIER}));
 $nas->info({ %NAS_PARAMS });

## print "$RAD->{NAS_IP_ADDRESS} $RAD->{'NAS-IP-Address'} /// $nas->{errno}) || $nas->{TOTAL}";
#
if (defined($nas->{errno}) || $nas->{TOTAL} < 1) {
  # (defined($RAD->{NAS_IDENTIFIER})) ? $RAD->{NAS_IDENTIFIER} : ''
  access_deny("$RAD->{USER_NAME}", "Unknow server '$RAD->{NAS_IP_ADDRESS}' [$nas->{errno}] $nas->{errstr}", 0);
  $RAD_REPLY{'Reply-Message'}="Unknow server '$RAD->{NAS_IP_ADDRESS}'";
  return 1;
 }
elsif(! defined($RAD->{USER_NAME}) || $RAD->{USER_NAME} eq '') {
  #access_deny("$RAD->{USER_NAME}", "Disabled NAS server '$RAD->{NAS_IP_ADDRESS}'", 0);
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
 my ($db, $RAD, $attr)=@_;
 my ($r, $RAD_PAIRS);

 if(defined($conf{tech_works})) {
 	 $RAD_REPLY{'Reply-Message'}="$conf{tech_works}";
 	 return 1;
  }


 if ($attr->{'pre_auth'}) {
   $r = $auth_mod{'default'}->pre_auth($RAD);
   if ($auth_mod{'default'}->{errno}) {
     log_print('LOG_INFO', "AUTH [$RAD->{USER_NAME}] MS-CHAP PREAUTH FAILED$GT");
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
    $auth_mod{"$nas->{NAS_TYPE}"} = $AUTH{$nas->{NAS_TYPE}}->new($db, \%conf);
   }

  ($r, $RAD_PAIRS) = $auth_mod{"$nas->{NAS_TYPE}"}->auth($RAD, $nas);
}
else {
  ($r, $RAD_PAIRS) = $auth_mod{"default"}->dv_auth($RAD, $nas, 
                                       { MAX_SESSION_TRAFFIC => $conf{MAX_SESSION_TRAFFIC}  } );
                                       
}

%RAD_REPLY = %$RAD_PAIRS;

#If Access deny
 if($r == 1){
    my $message = "$RAD_PAIRS->{'Reply-Message'} ";
    if ($auth_mod{"default"}->{errstr}) {
    	 $auth_mod{"default"}->{errstr}=~s/\n//g;
    	 $message .= $auth_mod{"default"}->{errstr};
     }
    my $CID = ($RAD->{CALLING_STATION_ID}) ? " CID: $RAD->{CALLING_STATION_ID} " : '';
    access_deny("$RAD->{USER_NAME}", "$message$CID", $nas->{NAS_ID});
    return $r;
  }
 else {
 	 #GEt Nas rad pairs
 	 $nas->{NAS_RAD_PAIRS} =~ tr/\n\r//d;

   my @pairs_arr = split(/,/, $nas->{NAS_RAD_PAIRS});
   foreach my $line (@pairs_arr) {
     if ($line =~ /\+\=/ ) {
       my($left, $right)=split(/\+\=/, $line, 2);
       $right =~ s/\"//g;

       if (defined($RAD_REPLY{"$left"})) {
   	     $RAD_REPLY{"$left"} =~ s/\"//g;
   	     $RAD_REPLY{"$left"}="\"". $RAD_REPLY{"$left"} .",$right\"";
        }
       else {
     	   $RAD_REPLY{"$left"}="\"$right\"";
        }
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
      $RAD_CHECK{'Auth-Type'} = 'Accept';
     }
   
   #$RAD_REPLY{'cisco-avpair'}="\"tunnel-type=VLAN,tunnel-medium-type==IEEE-802,tunnel-private-group-id=1, ip:inacl#1=deny ip 10.10.10.10 0.0.255.255 20.20.20.20 255.255.0.0\"";

   #Show pairs
   while(my($rs, $ls)=each %RAD_REPLY) {
     $rr .= "$rs = $ls,\n";
    }

   log_print('LOG_DEBUG', "AUTH [$RAD->{USER_NAME}] $rr");
 }

 if ($begin_time > 0)  {
   Time::HiRes->import(qw(gettimeofday));
   my $end_time = gettimeofday();
   my $gen_time = $end_time - $begin_time;
   $GT = sprintf(" GT: %2.5f", $gen_time);
  }


  my $CID = ($RAD->{CALLING_STATION_ID}) ? " CID: $RAD->{CALLING_STATION_ID} " : '';
  log_print('LOG_INFO', "AUTH [$RAD->{USER_NAME}] NAS: $nas->{NAS_ID} ($RAD->{NAS_IP_ADDRESS})$CID$GT");
  return $r;
}



#*******************************************************************
# post_auth()
#*******************************************************************
sub post_auth {
  my $reject_info = '';
  if (defined(%RAD_REQUEST)) {
    return 0;
    if (defined($RAD_REQUEST{CALLING_STATION_ID})) {
      $reject_info=" CID $RAD_REQUEST{CALLING_STATION_ID}";
     }
    log_print('LOG_INFO', "AUTH [$RAD_REQUEST{'User-Name'}] AUTH REJECT$reject_info$GT");
   }
  else {
    if (defined($RAD->{CALLING_STATION_ID})) {
      $reject_info=" CID $RAD->{CALLING_STATION_ID}";
     }
    log_print('LOG_INFO', "AUTH [$RAD->{USER_NAME}] AUTH REJECT$reject_info$GT");
   }

  # return RLM_MODULE_OK;
}



#*******************************************************************
# access_deny($user, $message);
#*******************************************************************
sub access_deny {
  my ($user, $message, $nas_num) = @_;

  log_print('LOG_WARNING', "AUTH [$user] NAS: $nas_num $message");

  return 1;
}




1

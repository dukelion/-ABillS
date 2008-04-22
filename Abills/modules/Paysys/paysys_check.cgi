#!/usr/bin/perl -w
# Check payments incomming request
#


use vars qw($begin_time %FORM %LANG 
$DATE $TIME
$CHARSET 
@MODULES);

BEGIN {
 my $libpath = '../';
 
 $sql_type='mysql';
 unshift(@INC, $libpath ."Abills/$sql_type/");
 unshift(@INC, $libpath);
 unshift(@INC, $libpath . 'libexec/');

 eval { require Time::HiRes; };
 if (! $@) {
    Time::HiRes->import(qw(gettimeofday));
    $begin_time = gettimeofday();
   }
 else {
    $begin_time = 0;
  }
}



require "config.pl";
use Abills::Base;
use Abills::SQL;
use Abills::HTML;
use Users;
use Paysys;
use Finance;
use Admins;







my $html = Abills::HTML->new();
my $sql = Abills::SQL->connect($conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd});
my $db = $sql->{db};
#Operation status
my $status = '';

#Check allow ips
if ($conf{PAYSYS_IPS}) {
	$conf{PAYSYS_IPS}=~s/ //g;
	@ips_arr = split(/,/, $conf{PAYSYS_IPS});
	
	#Default DENY FROM all
	my $allow = 0;
	foreach my $ip (@ips_arr) {
		#Deny address
		if ($ip =~ /^!/  && $ip =~ /$ENV{REMOTE_ADDR}$/) {
      last;
		 }
		#allow address
		elsif ($ENV{REMOTE_ADDR} =~ /^$ip/) {
			$allow=1;
			last;
		 }
	  #allow from all networks
	  elsif ($ip eq '0.0.0.0') {
	  	$allow=1;
	  	last;
	   }
	 }

  #Address not allow
  #Send info mail to admin
  if (! $allow) {
  	print "Content-Type: text/html\n\n";
  	print "Error: IP '$ENV{REMOTE_ADDR}' DENY by System";
    sendmail("$conf{ADMIN_MAIL}", "$conf{ADMIN_MAIL}", "ABillS - Paysys", 
              "IP '$ENV{REMOTE_ADDR}' DENY by System", "$conf{MAIL_CHARSET}", "2 (High)");
  	exit;
   } 
}


my $Paysys = Paysys->new($db, undef, \%conf);
my $admin = Admins->new($db, \%conf);
$admin->info($conf{SYSTEM_ADMIN_ID}, { IP => '127.0.0.1' });
my $payments = Finance->payments($db, $admin, \%conf);

my $users = Users->new($db, $admin, \%conf); 


#SMS proxy
# Need other header
if($FORM{smsid}) {
  smsproxy_payments();
  exit;
 }
elsif( $FORM{txn_id} ) {
	paysys_osmp();
}



print "Content-Type: text/html\n\n";

eval { require Digest::MD5; };
if (! $@) {
   Digest::MD5->import();
  }
else {
   print "Can't load 'Digest::MD5' check http://www.cpan.org";
   exit;
 }

my $md5 = new Digest::MD5;


#DEbug
my $output2 = '';
while(my($k, $v)=each %FORM) {
 	$output2 .= "$k, $v\n"	if ($k ne '__BUFFER');
}

payments();


#debug
#my $a=`echo "-----\n$output2\n-$status \n"  >> /tmp/test_paysys`;
#print "//".$output2;


#**********************************************************
#
#**********************************************************
sub payments {

  if ($FORM{LMI_PAYMENT_NO}) { # || $FORM{LMI_HASH}) {
  	wm_payments();
   }
  elsif($FORM{rupay_action}) {
  	rupay_payments();
   }
  else {
  	print "Error: Unknown payment system";
  	#$output2 .= "Unknown payment system"; 
   }
}




#**********************************************************
#
#**********************************************************
sub paysys_osmp {


 print "Content-Type: text/xml\n\n";
# print "Content-Type: text/html\n\n";
  


my $comments = '';
my %status_hash = (0	=> 'Success',
1 => 'Temporary error',
4	=> 'Wrong client indentifier',
5	=> 'Failed witness a signature',
6	=> 'Unknown terminal',
7	=> 'Payments deny',
300	=> 'Unknown error',
8	=> 'Double request',
9	=> 'Key Info mismatch'
);


my $command = $FORM{command};
my $CHECK_FIELD = $conf{PAYSYS_OSMP_ACCOUNT_KEY} || 'UID';

#Check user account
#https://service.someprovider.ru:8443/payment_app.cgi?command=check&txn_id=1234567&account=0957835959&sum=10.45
if ($command eq 'check') {

  my $list = $users->list({ $CHECK_FIELD => $FORM{account} });

  if ($users->{errno}) {
	  $status = 300; 
   }
  elsif ($users->{TOTAL} < 1) {
	  $status =  4;
	  $comments = 'User Not Exist';
   }
  else {
    $status = 0; 
   }

if ($status > 0) {
  $comments = $status_hash{$status} if ($comments eq '');
}

print << "[END]";
<?xml version="1.0" encoding="UTF-8"?> 
<response><osmp_txn_id>$FORM{txn_id}</osmp_txn_id>
<result>$status</result>
<comment>$comments</comment>
</response>
[END]

}
#https://service.someprovider.ru:8443/payment_app.cgi?command=pay&txn_id=1234567&txn_date=20050815120133&account=0957835959&sum=10.45
elsif ($command eq 'pay') {

  my $user;
  my $payments_id = 0;

  if ($CHECK_FIELD eq 'UID') {
    $user = $users->info($FORM{account});
   }
  else {
    my $list = $users->list({ $CHECK_FIELD => $FORM{account} });

    if (! $users->{errno} && $users->{TOTAL} > 0 ) {

      $uid = $list->[0]->[4+$users->{SEARCH_FIELDS_COUNT}];
      $user = $users->info($uid); 

     }
   }

  if ($users->{errno}) {
	  $status = 300; 
	  $comments='Dublicate Request';
   }
  elsif ($users->{TOTAL} < 1) {
	  $status =  4;
   }
  else {
    #Add payments
    $payments->add($user, {SUM          => $FORM{sum},
    	                     DESCRIBE     => 'OSMP', 
    	                     METHOD       => '2', 
  	                       EXT_ID       => "$FORM{txn_id}",
  	                       CHECK_EXT_ID => "$FORM{txn_id}" } );  


    if ($payments->{errno} == 7) {
      $status = 300;  	
     }
    elsif ($payments->{errno}) {
      $status = 4;
     }
    else {
    	$status = 0;
     }    

    $Paysys->add({ SYSTEM_ID   => 4, 
 	              DATETIME       => "'$DATE $TIME'", 
 	              SUM            => "$FORM{sum}",
  	            UID            => "$uid", 
                IP             => '0.0.0.0',
                TRANSACTION_ID => "$FORM{txn_id}",
                INFO           => "TYPE: $FORM{command} PS_TIME: $FORM{$FORM{txn_date}} STATUS: $status $status_hash{$status}",
                PAYSYS_IP      => "$ENV{'REMOTE_ADDR'}"
               });

    $payments_id = $Paysys->{INSERT_ID};
	 }

if ($status > 0) {
  $comments = $status_hash{$status} if ($comments eq '');
}



print << "[END]";
<?xml version="1.0" encoding="UTF-8"?> 
<response><osmp_txn_id>$FORM{txn_id}</osmp_txn_id>
<result>$status</result> 
<prv_txn>$payments_id</prv_txn> 
<sum>$FORM{sum}</sum> 
<result>$status</result> 
<comment>$comments</comment> 
</response> 
[END]
}
 


exit;

}




#**********************************************************
#
#**********************************************************
sub smsproxy_payments {

# $FORM{smsid}="1174921221.133533";
# $FORM{num}="1171&";
# $FORM{operator}="Mѓ_Moskva&";
# $FORM{user_id}="891612345XX&";
# $FORM{cost}="3.098&";
# $FORM{msg}="xxx";
 my $skey = $FORM{skey};
 my $prefix = $FORM{prefix};
 my %prefix_keys = ();

 my @keys_arr = split(/,/, $conf{PAYSYS_SMSPROXY_KEYS});
 
# foreach my $line (@keys_arr) {
#   my($prefix, $key)=split(/:/, $line);
#   $prefix_keys{$prefix}=$key;  
#  }
#
# $md5->reset;
# $md5->add($prefix_keys{$prefix});
# my $digest = $md5->hexdigest();
#
# #Unknown service
# if ($digest ne $skey) {
#   
#   return 0;
#  }
#
#
# #Info section  
# $Paysys->add({ SYSTEM_ID      => 3, 
# 	              DATETIME       => "$DATE $TIME", 
# 	              SUM            => "$FORM{cost}",
#  	            UID            => "", 
#                IP             => "0.0.0.0",
#                TRANSACTION_ID => "",
#                INFO           => "ID: $FORM{smsid}, NUM: $FORM{num}, OPERATOR: $FORM{operator}, USER_ID: $FORM{user_id}, MSG: $FORM{msg}, STATUS:",
#                PAYSYS_IP      => "$ENV{'REMOTE_ADDR'}"
#               });
#
# my $code = mk_unique_value(8);
#
#
#if ($list) {
#	print "smsid: $FORM{smsid}\n";
#  print "status: reply\n";
#  print "Content-Type:text/plain\n\n";
#  print $conf{PAYSYS_SMSPROXY_MSG} if ($conf{PAYSYS_SMSPROXY_MSG});
#  print " CODE: $code";
# }
#else {
#	
#}
#
}


#**********************************************************
#
#**********************************************************
sub rupay_payments {

$md5->reset;
my $checksum = '';
my $info = '';
my $user = $users->info($FORM{user_field_UID});

if ($user->{errno}) {
	$status = "ERROR: $user->{errno}";
 }
elsif ($user->{TOTAL} < 0) {
	$status = "User not exist";
 }
elsif ($FORM{rupay_site_id} ne $conf{PAYSYS_RUPAY_ID}) {
	$status = 'Not valid money account';
 }

while(my($k, $v)=each %FORM) {
  $info .= "$k, $v\n" if ($k =~ /^rupay|^user_field/);
 }


#notification
#Make checksum
if ($FORM{rupay_action} eq 'add') {
  $md5->add("$FORM{rupay_action}::$FORM{rupay_site_id}::$FORM{rupay_order_id}::$FORM{rupay_name_service}::$FORM{rupay_id}::$FORM{rupay_sum}::$FORM{rupay_user}::$FORM{rupay_email}::$FORM{rupay_data}::$conf{PAYSYS_RUPAY_SECRET_KEY}");
  $checksum = $md5->hexdigest();	

  $status = 'Preview Request';
  if ($FORM{rupay_hash} ne $checksum) {
  	$status = "Incorect checksum '$checksum'";
   }

  #Info section  
  $Paysys->add({ SYSTEM_ID      => 2, 
  	             DATETIME       => '', 
  	             SUM            => $FORM{rupay_sum},
  	             UID            => $FORM{user_field_UID}, 
                 IP             => $FORM{user_field_IP},
                 TRANSACTION_ID => $FORM{rupay_order_id},
                 INFO           => "STATUS, $status\n$info",
                 PAYSYS_IP      => "$ENV{'REMOTE_ADDR'}"
               });
 } 
#Add paymets
elsif ($FORM{rupay_action} eq 'update') {
  #Make checksum
  $md5->add("$FORM{rupay_action}::$FORM{rupay_site_id}::$FORM{rupay_order_id}::$FORM{rupay_sum}::$FORM{rupay_id}::$FORM{rupay_data}::$FORM{rupay_status}::$conf{PAYSYS_RUPAY_SECRET_KEY}"); 
  $checksum = $md5->hexdigest();	


  if ($FORM{rupay_hash} ne $checksum) {
  	$status = 'Incorect checksum';
   }
  elsif($status eq '') {
    #Add payments
    my $er = ($FORM{'5.ER'}) ? $payments->exchange_info() : { ER_RATE => 1 } ;  
    $payments->add($user, {SUM          => $FORM{rupay_sum},
    	                     DESCRIBE     => 'RUpay', 
    	                     METHOD       => '2', 
  	                       EXT_ID       => $FORM{rupay_order_id}, 
  	                       ER           => $er->{ER_RATE} } );  

    if ($payments->{errno}) {
      $info = "PAYMENT ERROR: $payments->{errno}\n";
     }
    else {
    	$status = "Added $payments->{INSERT_ID}\n";
     }
   }

  #Info section  
  $Paysys->add({ SYSTEM_ID      => 2, 
  	             DATETIME       => '', 
  	             SUM            => $FORM{rupay_sum},
  	             UID            => $FORM{user_field_UID}, 
                 IP             => $FORM{user_field_IP},
                 TRANSACTION_ID => $FORM{rupay_order_id},
                 INFO           => "STATUS, $status\n$info",
                 PAYSYS_IP      => "$ENV{'REMOTE_ADDR'}"
               });

  $output2 .= "Paysys:".$Paysys->{errno} if ($Paysys->{errno});
  $output2 .= "CHECK_SUM: $checksum\n";
 }


}

#**********************************************************
# https://merchant.webmoney.ru/conf/guide.asp
#
#**********************************************************
sub wm_payments {



#Pre request section
if($FORM{'LMI_PREREQUEST'} && $FORM{'LMI_PREREQUEST'} == 1) { 

 
 }
#Payment notification
elsif($FORM{LMI_HASH}) {
  my $checksum = wm_validate();
  my $info = '';
	my $user = $users->info($FORM{UID});
	
	my @ACCOUNTS = split(/;/, $conf{PAYSYS_WEBMONEY_ACCOUNTS});
	
  if (! in_array($FORM{LMI_PAYEE_PURSE}, \@ACCOUNTS)) {
  	$status = 'Not valid money account';
  	#return 0;
   }
  elsif (defined($FORM{LMI_MODE}) && $FORM{LMI_MODE} == 1) {
  	$status = 'Test mode';
  	#return 0;
   }
  elsif (length($FORM{LMI_HASH}) != 32 ) {
  	$status = 'Not MD5 checksum';
   }
  elsif ($FORM{LMI_HASH} ne $checksum) {
  	$status = "Incorect checksum '$checksum'";
   }
  elsif ($user->{errno}) {
		$status = "ERROR: $user->{errno}";
	 }
	elsif ($user->{TOTAL} < 0) {
		$status = "User not exist";
	 }
  else {
    #Add payments
    my $er = 1;
    
    
    if ($FORM{LMI_PAYEE_PURSE} =~ /^(\S)/ ) {
      my $payment_unit = 'WM'.$1;
      $payments->exchange_info(0, { SHORT_NAME => "$payment_unit"  });
      if ($payments->{TOTAL} > 0) {
      	$er = $payments->{ER_RATE};
       }
     }
    
    #my $er = ($FORM{'5.ER'}) ? $payments->exchange_info() : { ER_RATE => 1 } ;  
    $payments->add($user, {SUM          => $FORM{LMI_PAYMENT_AMOUNT},
    	                     DESCRIBE     => 'Webmoney', 
    	                     METHOD       => '2', 
  	                       EXT_ID       => $FORM{LMI_PAYMENT_NO}, 
  	                       ER           => $er
  	                       } );  

    if ($payments->{errno}) {
      $info = "PAYMENT ERROR: $payments->{errno}\n";
     }
    else {
    	$status = "Added $payments->{INSERT_ID}\n";
     }
   }
  
  while(my($k, $v)=each %FORM) {
    $info .= "$k, $v\n" if ($k =~ /^LMI/);
   }

  #Info section  
  $Paysys->add({ SYSTEM_ID      => 1, 
  	             DATETIME       => '', 
  	             SUM            => $FORM{LMI_PAYMENT_AMOUNT},
  	             UID            => $FORM{UID}, 
                 IP             => $FORM{IP},
                 TRANSACTION_ID => $FORM{LMI_PAYMENT_NO},
                 INFO           => "STATUS, $status\n$info",
                 PAYSYS_IP      => "$ENV{'REMOTE_ADDR'}"
               });

  $output2 .= "Paysys:".$Paysys->{errno} if ($Paysys->{errno});
  $output2 .= "CHECK_SUM: $checksum\n";
}

}

#**********************************************************
# Webmoney MD5 validate
#**********************************************************
sub wm_validate {
  $md5->reset;

	$md5->add($FORM{LMI_PAYEE_PURSE}); 
	$md5->add($FORM{LMI_PAYMENT_AMOUNT});
  $md5->add($FORM{LMI_PAYMENT_NO});
  $md5->add($FORM{LMI_MODE}); 
  $md5->add($FORM{LMI_SYS_INVS_NO});
  $md5->add($FORM{LMI_SYS_TRANS_NO});
  $md5->add($FORM{LMI_SYS_TRANS_DATE});
  $md5->add($conf{PAYSYS_LMI_SECRET_KEY}); 
  #$md5->add($FORM{LMI_SECRET_KEY}); 
  $md5->add($FORM{LMI_PAYER_PURSE}); 
  $md5->add($FORM{LMI_PAYER_WM}); 

  my $digest = uc($md5->hexdigest());	
  
  return $digest;
}

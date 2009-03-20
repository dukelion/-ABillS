#!/usr/bin/perl -w
# Paysys processing system
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


if ($conf{PAYSYS_PASSWD}) {
	my($user, $password)=split(/:/, $conf{PAYSYS_PASSWD});
	
	if (defined($ENV{HTTP_CGI_AUTHORIZATION})) {
  $ENV{HTTP_CGI_AUTHORIZATION} =~ s/basic\s+//i;
  my ($REMOTE_USER,$REMOTE_PASSWD) = split(/:/, decode_base64($ENV{HTTP_CGI_AUTHORIZATION}));  

#  print "Content-Type: text/html\n\n";
#  print "($REMOTE_PASSWD ne $password || $REMOTE_USER ne $user)";

  if ((! $REMOTE_PASSWD) || ($REMOTE_PASSWD && $REMOTE_PASSWD ne $password) 
    || (! $REMOTE_USER) || ($REMOTE_USER && $REMOTE_USER ne $user)) {
    print "WWW-Authenticate: Basic realm=\"Billing system\"\n";
    print "Status: 401 Unauthorized\n";
    print "Content-Type: text/html\n\n";
    print "Access Deny";
    exit;
   }
  }
}



my $Paysys = Paysys->new($db, undef, \%conf);
my $admin = Admins->new($db, \%conf);
$admin->info($conf{SYSTEM_ADMIN_ID}, { IP => '127.0.0.1' });
my $payments = Finance->payments($db, $admin, \%conf);

my $users = Users->new($db, $admin, \%conf); 


#DEbug
my $output2 = '';
while(my($k, $v)=each %FORM) {
 	$output2 .= "$k, $v\n"	if ($k ne '__BUFFER');
}

if( $FORM{txn_id} || $FORM{prv_txn} || defined($FORM{prv_id}) ) {
	osmp_payments();
 }
elsif ($FORM{SHOPORDERNUMBER}) {
  portmone_payments();
 }


#Check payment system by IP

#OSMP
my $first_ip = unpack("N", pack("C4", split( /\./, '79.142.16.0')));
my $mask_ips = unpack("N", pack("C4", split( /\./, '255.255.255.255'))) - unpack("N", pack("C4", split( /\./, '255.255.240.0')));
my $last_ip  = $first_ip + $mask_ips;
my $ip_num   = unpack("N", pack("C4", split( /\./, $ENV{REMOTE_ADDR})));

if ($ip_num > $first_ip && $ip_num < $last_ip){
        print "Content-Type: text/xml\n\n";
        print "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
        print "<response>\n";
        print "<result>300</result>\n";
        print "<result1>$ENV{REMOTE_ADDR}</result1>\n";
        print " </response>\n";
        exit;
 } 


print "Content-Type: text/html\n\n";

eval { require Digest::MD5; };
if (! $@) {
   Digest::MD5->import();
  }
else {
   print "Content-Type: text/html\n\n";
   print "Can't load 'Digest::MD5' check http://www.cpan.org";
   exit;
 }

my $md5 = new Digest::MD5;


#DEbug
payments();




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
  elsif ($FORM{id_ups}) {
  	ukrpays_payments();
   }
  elsif($FORM{smsid}) {
    smsproxy_payments();
    exit;
   }
  elsif ($FORM{sign}) {
  	usmp_payments();
   }
  else {
    print "Error: Unknown payment system";
   }
}


#**********************************************************
#
#**********************************************************
sub portmone_payments {
  #Get order
  my $status = 0;
  my $list = $Paysys->list({ TRANSACTION_ID => "$FORM{'SHOPORDERNUMBER'}", 
      	                     INFO           => '-'
  	                         });




      if ($Paysys->{TOTAL} > 0) {
	      #$html->message('info', $_INFO, "$_ADDED $_SUM: $list->[0][3] ID: $FORM{SHOPORDERNUMBER }");
	      my $uid = $list->[0][7];
	      my $sum = $list->[0][3];
        my $user = $users->info($uid);
        $payments->add($user, {SUM      => $sum,
    	                     DESCRIBE     => 'PORTMONE', 
    	                     METHOD       => '2', 
  	                       EXT_ID       => "PM:$FORM{SHOPORDERNUMBER}",
  	                       CHECK_EXT_ID => "PM:$FORM{SHOPORDERNUMBER}" } );  


        #Exists
        if ($payments->{errno} && $payments->{errno} == 7) {
          $status = 8;  	
         }
        elsif ($payments->{errno}) {
          $status = 4;
         }
        else {
          $Paysys->change({ ID     => $list->[0][0],
         	                  INFO   => "APPROVALCODE: $FORM{APPROVALCODE}" 
         	                 })  ;
      	  $status = 1;
         }    


        

        

	      if ($conf{PAYSYS_EMAIL_NOTICE}) {
	      	my $message = "\n".
	      	 "System: Portmone\n".
	      	 "DATE: $DATE $TIME\n".
	      	 "LOGIN: $user->{LOGIN} [$uid]\n".
	      	 "\n".
       	   "\n".
	      	 "ID: $FORM{SHOPORDERNUMBER}\n".
	      	 "SUM: $sum\n";

          sendmail("$conf{ADMIN_MAIL}", "$conf{ADMIN_MAIL}", "Paysys Portmone Add", 
              "$message", "$conf{MAIL_CHARSET}", "2 (High)");
	      	
	       }
	     }
	
	#money added sucesfully
	
  #print "Content-Type: text/html\n\n";
  #print "// $ENV{SCRIPT_NAME} $ENV{REQUEST_URI}//";
  
	my $home_url = '/index.cgi';
  $home_url = $ENV{SCRIPT_NAME};
  $home_url =~ s/paysys_check.cgi/index.cgi/;
  
	if ($status == 1) {
	  print "Location: $home_url?index=$FORM{index}&sid=$FORM{sid}&SHOPORDERNUMBER=$FORM{SHOPORDERNUMBER}&TRUE=1". "\n\n";
	 }
	else {
		#print "Content-Type: text/html\n\n";
		#print "FAILED PAYSYS: Portmone SUM: $FORM{BILL_AMOUNT} ID: $FORM{SHOPORDERNUMBER} STATUS: $status";
		print "Location: $home_url?index=$FORM{index}&sid=$FORM{sid}&SHOPORDERNUMBER=$FORM{SHOPORDERNUMBER}". "\n\n";
	 }

	exit;
}

#**********************************************************
# OSMP / Pegas
#**********************************************************
sub osmp_payments {

 if ($conf{PAYSYS_PEGAS_PASSWD}) {
	my($user, $password)=split(/:/, $conf{PAYSYS_PEGAS_PASSWD});
	
	if (defined($ENV{HTTP_CGI_AUTHORIZATION})) {
  $ENV{HTTP_CGI_AUTHORIZATION} =~ s/basic\s+//i;
  my ($REMOTE_USER,$REMOTE_PASSWD) = split(/:/, decode_base64($ENV{HTTP_CGI_AUTHORIZATION}));  

#  print "Content-Type: text/html\n\n";
#  print "($REMOTE_PASSWD ne $password || $REMOTE_USER ne $user)";

  if ((! $REMOTE_PASSWD) || ($REMOTE_PASSWD && $REMOTE_PASSWD ne $password) 
    || (! $REMOTE_USER) || ($REMOTE_USER && $REMOTE_USER ne $user)) {
    print "WWW-Authenticate: Basic realm=\"Billing system\"\n";
    print "Status: 401 Unauthorized\n";
    print "Content-Type: text/html\n\n";
    print "Access Deny";
    exit;
   }
  }
 }


 print "Content-Type: text/xml\n\n";
# print "Content-Type: text/html\n\n";
 my $txn_id            = 'osmp_txn_id';
 my $payment_system    = 'OSMP';
 my $payment_system_id = 4;
 my $CHECK_FIELD = $conf{PAYSYS_OSMP_ACCOUNT_KEY} || 'UID';

my %status_hash = (0	=> 'Success',
  1   => 'Temporary DB error',
  4	  => 'Wrong client indentifier',
  5	  => 'Failed witness a signature',
  6	  => 'Unknown terminal',
  7	  => 'Payments deny',
  
  8	  => 'Double request',
  9	  => 'Key Info mismatch',
  79  => 'Счёт абонента не активен',
  300	=> 'Unknown error',
  );



 #For pegas
 if ($conf{PAYSYS_PEGAS}) {
 	 $txn_id            = 'txn_id';
 	 $payment_system    = 'PEGAS';
 	 $payment_system_id = 9;
 	 $status_hash{5}='Неверный индентификатор абонента';
 	 $status_hash{243}='Невозможно проверитьсостояние счёта';
 	 $CHECK_FIELD       = $conf{PAYSYS_PEGAS_ACCOUNT_KEY} || 'UID';
  }

my $comments = '';
my $command = $FORM{command};
$FORM{account} =~ s/^0+//g if ($FORM{account});
my %RESULT_HASH=( result => 300 );
my $results = '';

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



$RESULT_HASH{result} = $status;

#For OSMP
if ($payment_system_id == 4) {
  $RESULT_HASH{$txn_id}= $FORM{txn_id} ;
  $RESULT_HASH{prv_txn}= $FORM{prv_txn};
 }

}
#Cancel payments
elsif ($command eq 'cancel') {
  my $prv_txn = $FORM{prv_txn};
  $RESULT_HASH{prv_txn}=$prv_txn;

  my $list = $payments->list({ ID => "$prv_txn", EXT_ID => "PEGAS:*"  });

  if ($payments->{errno}) {
      $RESULT_HASH{result}=1;
   }
  elsif ($payments->{TOTAL} < 1) {
  	$RESULT_HASH{result}=79;
   }
  else {
	  my %user = (
     BILL_DI => $list->[10],
     UID     => $list->[11]
    );

  	$payments->del(\%user, $prv_txn);
    if (! $payments->{errno}) {
      $RESULT_HASH{result}=0;
     }
    else {
      $RESULT_HASH{result}=1;
     }
   }
 }
elsif ($command eq 'balance') {
  	
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

      my $uid = $list->[0]->[5+$users->{SEARCH_FIELDS_COUNT}];
      $user = $users->info($uid); 
     }
   }

  if ($users->{errno}) {
    $status = ($users->{errno} == 2) ? 5 : 300;
   }
  elsif ($users->{TOTAL} < 1) {
	  $status =  4;
   }
  else {
    #Add payments
    $payments->add($user, {SUM          => $FORM{sum},
    	                     DESCRIBE     => "$payment_system", 
    	                     METHOD       => '2', 
  	                       EXT_ID       => "$payment_system:$FORM{txn_id}",
  	                       CHECK_EXT_ID => "$payment_system:$FORM{txn_id}" } );  


    #Exists
    if ($payments->{errno} && $payments->{errno} == 7) {
      $status      = 0;  	
      $payments_id = $payments->{ID};
     }
    elsif ($payments->{errno}) {
      $status = 4;
     }
    else {
    	$status = 0;
    	$Paysys->add({ SYSTEM_ID   => $payment_system_id, 
 	              DATETIME       => "'$DATE $TIME'", 
 	              SUM            => "$FORM{sum}",
  	            UID            => "$user->{UID}", 
                IP             => '0.0.0.0',
                TRANSACTION_ID => "$payment_system:$FORM{txn_id}",
                INFO           => "TYPE: $FORM{command} PS_TIME: ".
  (($FORM{txn_date}) ? $FORM{txn_date} : '' ) ." STATUS: $status $status_hash{$status}",
                PAYSYS_IP      => "$ENV{'REMOTE_ADDR'}"
               });

      $payments_id = ($Paysys->{INSERT_ID}) ? $Paysys->{INSERT_ID} : 0;
     }    


	 }

$RESULT_HASH{result} = $status;
$RESULT_HASH{$txn_id}= $FORM{txn_id};
$RESULT_HASH{prv_txn}= $payments_id;
$RESULT_HASH{sum}    = $FORM{sum};
}
 


#Result output
$RESULT_HASH{comment}=$status_hash{$RESULT_HASH{result}} if ($RESULT_HASH{result} && ! $RESULT_HASH{comment});

while(my($k, $v) = each %RESULT_HASH) {
	$results .= "<$k>$v</$k>\n";
}

print << "[END]";
<?xml version="1.0" encoding="UTF-8"?> 
<response>
$results
</response> 
[END]


exit;

}


#**********************************************************
# http://usmp.com.ua/
# Example:
# /paysys_check.cgi?account=638&date=13.12.08%2001%3A42%3A21&hash=5237893&id=138&sum=66&testMode=0&type=1&sign=a97e377896b2630fe491d6e0d79a8f484bf357b4f5c5197e8ffc7466d1b6693d0dc892e1380ab4104bc920ccfdc808fe898524330bcefd7c7c2407668a9a845f47f693202119820cce77928a377a316c99c561c5d81811f929d3b39c0e37d893901f35e30352e3e8acd49abcbbe2033c3847d81c0bd06728d24f36e116be6d49
#
#**********************************************************
sub usmp_payments {


eval { require Crypt::OpenSSL::RSA; };
if (! $@) {
   Crypt::OpenSSL::RSA->import();
 }
else {
   print "Content-Type: text/html\n\n";
   print "Can't load 'Crypt::OpenSSL::RSA' check http://www.cpan.org";
   exit;
 }


my $CHECK_FIELD = $conf{PAYSYS_USMP_ACCOUNT_KEY} || 'UID';

my $id    = $FORM{'id'};
my $accid = $FORM{'account'};
my $summ  = $FORM{'sum'};
my $sign  = $FORM{'sign'};
my $hash  = $FORM{'hash'};
my $date  = $FORM{'date'};

my $err_code = 0;

#Check user account
my $list = $users->list({ $CHECK_FIELD => $accid });

my $user ;
if ($users->{errno}) {
  err_trap(7, $users->{errstr});
 }
elsif ($users->{TOTAL} < 1) {
  $err_code = 2
 }
else {
  my $uid = $list->[0]->[5+$users->{SEARCH_FIELDS_COUNT}];
	$user = $users->info($uid); 
}

if (!$err_code) {    
	$date =~ s/\s/%20/;
	$date =~ s/:/%3A/g;
	my $data = "account=" . $accid . "&date=" . $date . "&hash=" . $hash . "&id=" . $id . "&sum=" . $summ . "&testMode=0&type=1";
	
	if (! -f $conf{PAYSYS_USMP_KEYFILE}) {
		print "code=2";
		print "Can't find cert file.";
		return 0;
	 }
	
	my $rsa_pub = Crypt::OpenSSL::RSA->new_public_key(read_public_key($conf{PAYSYS_USMP_KEYFILE}));

	$rsa_pub->use_md5_hash();
	my $signature = pack('H*', $sign);
	if ($rsa_pub->verify($data, $signature)) {
    $payments->add($user, {SUM          => $summ,
     	                     DESCRIBE     => 'USMP', 
    	                     METHOD       => '2', 
    	                     EXT_ID       => "USMP:$id",
  	                       CHECK_EXT_ID => "USMP:$id" } );  
    if ($payments->{errno}) {
      err_trap(7, $payments->{errstr});
     }  
    

    $Paysys->add({ SYSTEM_ID   => 7, 
 	              DATETIME       => "'$DATE $TIME'", 
 	              SUM            => "$summ",
  	            UID            => "$accid", 
                IP             => '0.0.0.0',
                TRANSACTION_ID => "USMP:$id",
                INFO           => "STATUS: $err_code",
                PAYSYS_IP      => "$ENV{'REMOTE_ADDR'}"
               });

     }
   }    


print "code=$err_code&message=Done&date=" . get_date();

}


#**********************************************************
#
#**********************************************************
sub smsproxy_payments {


#https//demo.abills.net.ua:9443/paysys_check.cgi?skey=827ccb0eea8a706c4c34a16891f84e7b&smsid=1208992493215&num=1171&operator=Tester&user_id=1234567890&cost=1.5&msg=%20Test_messages




 my $sms_num     = $FORM{num}     || 0;
 my $cost        = $FORM{cost_rur}|| 0;
 my $skey        = $FORM{skey}    || '';
 my $prefix      = $FORM{prefix}  || '';

 my %prefix_keys = ();
 my $service_key = '';
 
 if ($conf{PAYSYS_SMSPROXY_KEYS} && $conf{PAYSYS_SMSPROXY_KEYS} =~ /:/) {
   my @keys_arr = split(/,/, $conf{PAYSYS_SMSPROXY_KEYS});

   foreach my $line (@keys_arr) {
     my($num, $key)=split(/:/, $line);
     if ($num eq $sms_num) {
       $prefix_keys{$num}=$key;  
       $service_key = $key;
      }
    }
  }
 else {
   $prefix_keys{$sms_num}=$conf{PAYSYS_SMSPROXY_KEYS};  
   $service_key = $conf{PAYSYS_SMSPROXY_KEYS};
  }

 $md5->reset;
 $md5->add($service_key);
 my $digest = $md5->hexdigest();

 print "smsid: $FORM{smsid}\n";


 if ($digest ne $skey) {
   print "status:reply\n";
   print "content-type: text/plain\n\n";
   print "Wrong key!\n";
   return 0;
  }


my $code = mk_unique_value(8);
#Info section  
 my ($transaction_id, $m_secs)=split(/\./, $FORM{smsid}, 2);
 

 my $er = 1;
 $payments->exchange_info(0, { SHORT_NAME => "SMSPROXY"  });
 if ($payments->{TOTAL} > 0) {
  	$er = $payments->{ER_RATE};
   }

 if ($payments->{errno}) {
   print "status:reply\n";
   print "content-type: text/plain\n\n";
   print "PAYMENT ERROR: $payments->{errno}!\n";
   return 0;
  }
 
 $Paysys->add({ SYSTEM_ID      => 3, 
 	              DATETIME       => "'$DATE $TIME'", 
 	              SUM            => "$cost",
 	              UID            => "", 
                IP             => "0.0.0.0",
                TRANSACTION_ID => "$transaction_id",
                INFO           => "ID: $FORM{smsid}, NUM: $FORM{num}, OPERATOR: $FORM{operator}, USER_ID: $FORM{user_id}",
                PAYSYS_IP      => "$ENV{'REMOTE_ADDR'}",
                CODE           => $code
               });


  if ($Paysys->{errno} && $Paysys->{errno} == 7) {
    print "status:reply\n";
    print "content-type: text/plain\n\n";
    print "Request dublicated $FORM{smsid}\n";
    return 0;
   }


  print "status:reply\n";
  print "content-type: text/plain\n\n";
  print $conf{PAYSYS_SMSPROXY_MSG} if ($conf{PAYSYS_SMSPROXY_MSG});
  print " CODE: $code";

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
                 TRANSACTION_ID => "$FORM{rupay_order_id}",
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
                 TRANSACTION_ID => "$FORM{rupay_order_id}",
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
                 TRANSACTION_ID => "$FORM{LMI_PAYMENT_NO}",
                 INFO           => "STATUS, $status\n$info",
                 PAYSYS_IP      => "$ENV{'REMOTE_ADDR'}"
               });

  $output2 .= "Paysys:".$Paysys->{errno} if ($Paysys->{errno});
  $output2 .= "CHECK_SUM: $checksum\n";
}

}


#**********************************************************
# http://portmone.com.ua/
#
#**********************************************************
#sub portmone_payments {
#
#
#  my $checksum = wm_validate();
#  my $info = '';
#	my $user = $users->info($FORM{UID});
#	
#	my @ACCOUNTS = split(/;/, $conf{PAYSYS_WEBMONEY_ACCOUNTS});
#	
#  if (! in_array($FORM{LMI_PAYEE_PURSE}, \@ACCOUNTS)) {
#  	$status = 'Not valid money account';
#  	#return 0;
#   }
#  elsif (defined($FORM{LMI_MODE}) && $FORM{LMI_MODE} == 1) {
#  	$status = 'Test mode';
#  	#return 0;
#   }
#  elsif (length($FORM{LMI_HASH}) != 32 ) {
#  	$status = 'Not MD5 checksum';
#   }
#  elsif ($FORM{LMI_HASH} ne $checksum) {
#  	$status = "Incorect checksum '$checksum'";
#   }
#  elsif ($user->{errno}) {
#		$status = "ERROR: $user->{errno}";
#	 }
#	elsif ($user->{TOTAL} < 0) {
#		$status = "User not exist";
#	 }
#  else {
#    #Add payments
#    my $er = 1;
#    
#    
#    if ($FORM{LMI_PAYEE_PURSE} =~ /^(\S)/ ) {
#      my $payment_unit = 'WM'.$1;
#      $payments->exchange_info(0, { SHORT_NAME => "$payment_unit"  });
#      if ($payments->{TOTAL} > 0) {
#      	$er = $payments->{ER_RATE};
#       }
#     }
#    
#    #my $er = ($FORM{'5.ER'}) ? $payments->exchange_info() : { ER_RATE => 1 } ;  
#    $payments->add($user, {SUM          => $FORM{LMI_PAYMENT_AMOUNT},
#    	                     DESCRIBE     => 'Webmoney', 
#    	                     METHOD       => '2', 
#  	                       EXT_ID       => $FORM{SHOPORDERNUMBER}, 
#  	                       ER           => $er
#  	                       } );  
#
#    if ($payments->{errno}) {
#      $info = "PAYMENT ERROR: $payments->{errno}\n";
#     }
#    else {
#    	$status = "Added $payments->{INSERT_ID}\n";
#     }
#   }
#  
#  while(my($k, $v)=each %FORM) {
#    $info .= "$k, $v\n" if ($k =~ /^LMI/);
#   }
#
#  #Info section  
#  $Paysys->add({ SYSTEM_ID      => 1, 
#  	             DATETIME       => '', 
#  	             SUM            => $FORM{SUM},
#  	             UID            => $FORM{UID}, 
#                 IP             => $FORM{IP},
#                 TRANSACTION_ID => "$FORM{SHOPORDERNUMBER}",
#                 INFO           => "STATUS, $status\n$info",
#                 PAYSYS_IP      => "$ENV{'REMOTE_ADDR'}"
#               });
#
#  $output2 .= "Paysys:".$Paysys->{errno} if ($Paysys->{errno});
#  $output2 .= "CHECK_SUM: $checksum\n";
#
#
#}


#**********************************************************
# http://ukrpays.com/
#
#**********************************************************
sub ukrpays_payments {
#Pre request section


if($FORM{hash}) {
  $md5->reset;
	$md5->add($FORM{id_ups}); 
	$md5->add($FORM{login});
  $md5->add($FORM{amount});
  $md5->add($FORM{date}); 
  $md5->add($conf{PAYSYS_UKRPAYS_SECRETKEY});

  my $checksum = $md5->hexdigest();	

  my $info = '';
	my $user = $users->info($FORM{login});
	
  if ($FORM{hash} ne $checksum) {
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
    
    
    #if ($FORM{LMI_PAYEE_PURSE} =~ /^(\S)/ ) {
    #  my $payment_unit = 'WM'.$1;
    #  $payments->exchange_info(0, { SHORT_NAME => "$payment_unit"  });
    #  if ($payments->{TOTAL} > 0) {
    #  	$er = $payments->{ER_RATE};
    #   }
    # }
    
    $payments->add($user, {SUM          => $FORM{amount},
    	                     DESCRIBE     => 'Ukrpays', 
    	                     METHOD       => '2', 
  	                       EXT_ID       => "UKRPAYS:$FORM{id_ups}", 
  	                       CHECK_EXT_ID => "UKRPAYS:$FORM{id_ups}", 
  	                       ER           => $er
  	                       } );  

    if ($payments->{errno}) {
      if ($payments->{errno} == 7) {
        $info = "PAYMENTS DUBLICATE: UKRPAYS:$FORM{id_ups}\n";
       }
      else {
        $info = "PAYMENT ERROR: $payments->{errno}\n";
       }

      
     }
    else {
    	$status = "Added $payments->{INSERT_ID}\n";
     }
   }
  
  while(my($k, $v)=each %FORM) {
    $info .= "$k, $v\n" if ($k !~ /__B/);
   }

  $status =~ s/'/\\'/g;

  #Info section  
  $Paysys->add({ SYSTEM_ID      => 6, 
  	             DATETIME       => '', 
  	             SUM            => $FORM{amount},
  	             UID            => $FORM{login}, 
                 IP             => $FORM{IP} || '0.0.0.0',
                 TRANSACTION_ID => "UKRPAYS:$FORM{id_ups}",
                 INFO           => "STATUS, $status\n$info",
                 PAYSYS_IP      => "$ENV{'REMOTE_ADDR'}"
               });

  if ($Paysys->{errno}) {
    if ($Paysys->{errno}==7) {
      $output2 = "TRANSACTION DUBLICATE: UKRPAYS:$FORM{id_ups}\n";
     }
    else {
      $status = $output2;
     }
    $status = $output2;
   }
  else {
  	$status = 'payment complete';
   }

  $output2 .= "CHECK_SUM: $checksum\n";
}

   print $status;
}


#**********************************************************
# Read Public Key
#**********************************************************
sub read_public_key {
  my ($filename) = @_;
  my $cert = "";

  open (CERT, "$filename") || die "Can't open '$filename' $!\n";
    while (<CERT>) {
     	$cert .= $_;
     }
  close CERT;

  return $cert;        
}

#**********************************************************
# Error Trap
#**********************************************************
sub err_trap {
  my ($err_code, $error) = @_;
  print "code=$err_code";
  die "Paysys database error: $error\n";
}


#**********************************************************
# Get Date
#**********************************************************
sub get_date {
    my ($sec, $min, $hour, $mday, $mon, $year) = (localtime time)[0, 1, 2, 3, 4, 5];
    $year -= 100;
    $mon++;
    $year = "0$year" if $year < 10;
    $mday = "0$mday" if $mday < 10;
    $mon = "0$mon" if $mon < 10;
    $hour = "0$hour" if $hour < 10;
    $min = "0$min" if $min < 10;
    $sec = "0$sec" if $sec < 10;
    
    return "$mday.$mon.$year $hour:$min:$sec";
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

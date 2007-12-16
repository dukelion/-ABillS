#!/usr/bin/perl -w
# Check payments incomming request
#


use vars qw($begin_time %FORM %LANG $CHARSET @MODULES);
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

my $Paysys = Paysys->new($db, undef, \%conf);

my $admin = Admins->new($db, \%conf);
$admin->info($conf{SYSTEM_ADMIN_ID}, { IP => '127.0.0.1' });
my $payments = Finance->payments($db, $admin, \%conf);

my $users = Users->new($db, $admin, \%conf); 


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
  	print "Unknown payment system";
  	#$output2 .= "Unknown payment system"; 
   }
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
                 INFO           => "STATUS, $status\n$info"
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
                 INFO           => "STATUS, $status\n$info"
               });

  $output2 .= "Paysys:".$Paysys->{errno} if ($Paysys->{errno});
  $output2 .= "CHECK_SUM: $checksum\n";
 }


}

#**********************************************************
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
                 INFO           => "STATUS, $status\n$info"
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

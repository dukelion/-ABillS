#!/usr/bin/perl
# Paysys processing system
# Check payments incomming request
#

use vars qw($begin_time %FORM %LANG
$DATE $TIME
$CHARSET
@MODULES
$admin
$users
$payments
$Paysys
$debug
%conf
%PAYSYS_PAYMENTS_METHODS
$md5
$html
$systems_ips
%systems_ident_params
%system_params
);

BEGIN {
 my $libpath = '../';

 $sql_type='mysql';
 unshift(@INC, $libpath ."Abills/$sql_type/");
 unshift(@INC, $libpath);
 unshift(@INC, $libpath . 'libexec/');
 unshift(@INC, $libpath . 'Abills/modules/Paysys');
 unshift(@INC, $libpath . 'Abills');

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

$debug     = $conf{PAYSYS_DEBUG} || 0;
$html   = Abills::HTML->new();
my $sql    = Abills::SQL->connect($conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser},
    $conf{dbpasswd}, { CHARSET => ($conf{dbcharset}) ? $conf{dbcharset} : undef  });
my $db     = $sql->{db};
#Operation status
my $status = '';

require "Abills/templates.pl";

if ($Paysys::VERSION < 3.2) {
	print "Content=-Type: text/html\n\n";
 	print "Please update module 'Paysys' to version 3.2 or higher. http://abills.net.ua/";
 	return 0;
 }


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

$Paysys   = Paysys->new($db, undef, \%conf);
$admin    = Admins->new($db, \%conf);
$admin->info($conf{SYSTEM_ADMIN_ID}, { IP => $ENV{REMOTE_ADDR} });
$payments = Finance->payments($db, $admin, \%conf);
$users    = Users->new($db, $admin, \%conf);

%PAYSYS_PAYMENTS_METHODS=%{ cfg2hash($conf{PAYSYS_PAYMENTS_METHODS}) };

#debug =========================================

my $output2 = '';
#read(STDIN, $output2, $ENV{'CONTENT_LENGTH'});
#$output2 = '!!';
if ($debug > 0) {
  while(my($k, $v)=each %FORM) {
 	  $output2 .= "$k -> $v\n"	if ($k ne '__BUFFER');
   }
  mk_log($output2);
}
#END debug =====================================

eval { require Digest::MD5; };
if (! $@) {
   Digest::MD5->import();
  }
else {
   print "Content-Type: text/html\n\n";
   print "Can't load 'Digest::MD5' check http://www.cpan.org";
   exit;
 }

$md5 = new Digest::MD5;

if ($conf{PAYSYS_SUCCESSIONS}) {
	$conf{PAYSYS_SUCCESSIONS} =~ s/[\n\r]+//g;
  my @systems_arr = split(/;/, $conf{PAYSYS_SUCCESSIONS});
  # IPS:ID:NAME:SHORT_NAME:MODULE_function;
  foreach my $line ( @systems_arr ) {
  	my ($ips, $id, $name, $short_name, $function)=split(/:/, $line);
  	
  	%system_params = ( SYSTEM_SHORT_NAME => $id, 
                       SYSTEM_ID         => $short_name
                      );
  	
  	my @ips_arr = split(/,/, $ips);
  	if (in_array($ENV{REMOTE_ADDR}, \@ips_arr)) {
  	  if ($function=~/\.pm/) {
  	    require "$function";
  	   }
  	  else {
  		  $function->({ %system_params });
  	   }

  	  exit; 
  	 }
   }
}




my $ip_num   = unpack("N", pack("C4", split( /\./, $ENV{REMOTE_ADDR})));
if ($ip_num >= ip2int('213.186.115.164') && $ip_num <= ip2int('213.186.115.190')) {
  require "Ibox.pm";
	exit;
 }
elsif ($ip_num >= ip2int('217.117.64.232') && $ip_num <= ip2int('217.117.64.238')) {
  require "Privat_terminal.pm";
	exit;
 }
# Privat bank terminal interface
elsif ('75.101.163.115,213.154.214.76' =~ /$ENV{REMOTE_ADDR}/) {
	require "Privat_terminal.pm";
	exit;
 }
elsif( $FORM{signature} && $FORM{operation_xml}) {
  require "Liqpay.pm";
  liqpay_payments();
	exit;
 }
# IP: 77.120.97.36
elsif( $FORM{merchantid} ) {
  require "Regulpay.pm";
  exit;
 }
# IP: -
elsif( $FORM{params} ) {
  require "Sberbank.pm";
  exit;
 }
elsif( $FORM{action} && $conf{PAYSYS_TELCELL_ACCOUNT_KEY} ) {
  require "Telcell.pm";
  exit;
 }
elsif( $FORM{action} ) {
  require "Cyberplat.pm";
  exit;
 }
elsif( $FORM{txn_id} || $FORM{prv_txn} || defined($FORM{prv_id}) || ( $FORM{command} && $FORM{account}  ) ) {
	osmp_payments();
 }
elsif ($FORM{SHOPORDERNUMBER}) {
  portmone_payments();
 }
elsif($FORM{AcqID}) {
	privatbank_payments();
 }
elsif($FORM{operation} || $ENV{'QUERY_STRING'} =~ /operation=/) {
	require "Comepay.pm";
	exit;
 }
elsif ($FORM{'<OPERATION id'} || $FORM{'%3COPERATION%20id'}) {
	require "Express-oplata.pm";
	exit;
 }
elsif($FORM{ACT}) {
	require "24_non_stop.pm";
	exit;
}
elsif($conf{PAYSYS_GIGS_IPS} && $conf{PAYSYS_GIGS_IPS} =~ /$ENV{REMOTE_ADDR}/) {
	require "Gigs.pm";
}
elsif(	$conf{PAYSYS_GAZPROMBANK_ACCOUNT_KEY} &&
		($FORM{lsid} || 
		$FORM{trid} || 
		$FORM{dtst})) {
	require "Gazprombank.pm";
	exit;
 }
elsif ($ENV{REMOTE_ADDR} =~ /^193\.110\.17\.230$/) {
 	require "Zaplati_sumy.pm";
 	exit;
 }
elsif ($ENV{REMOTE_ADDR} =~ /^77\.222\.134\.205$/) {
  require "Ipay.pm";
  exit;
}

#Check payment system by IP

#OSMP
my $first_ip = unpack("N", pack("C4", split( /\./, '79.142.16.0')));
my $mask_ips = unpack("N", pack("C4", split( /\./, '255.255.255.255'))) - unpack("N", pack("C4", split( /\./,'255.255.240.0')));
my $last_ip  = $first_ip + $mask_ips;


if ($ENV{REMOTE_ADDR} =~ /^92\.125\./) {
	osmp_payments_v4();
	exit;
 }
elsif ($ENV{REMOTE_ADDR} =~ /^93\.183\.196\.26$/ ||
       $ENV{REMOTE_ADDR} =~ /^195\.230\.131\.50$/||
       $ENV{REMOTE_ADDR} =~ /^93\.183\.196\.28$/
        ) {
 	require "Easysoft.pm";
 	exit;
 }
elsif ($conf{PAYSYS_ERIPT_IPS} =~ /$ENV{REMOTE_ADDR}/) {
 	require "Erip.pm";
 	exit;
 }
elsif ($ip_num > $first_ip && $ip_num < $last_ip) {
  print "Content-Type: text/xml\n\n"
     . "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
     . "<response>\n"
     . "<result>300</result>\n"
     . "<result1>$ENV{REMOTE_ADDR}</result1>\n"
     . " </response>\n";
        exit;
 }
#USMP
elsif('77.222.138.142,78.30.232.14' =~ /$ENV{REMOTE_ADDR}/) {
  require "Usmp.pm";
  exit;
 }
elsif ($FORM{payment} && $FORM{payment}=~/pay_way/) {
 	require "P24.pm";
 	p24_payments();
 	exit;
 }


print "Content-Type: text/html\n\n";

#New module load method
#
#use FindBin '$Bin';
#my %systems_ips = ();
#my %systemS_params = ();
#
#my $modules_dir = $Bin."/../Abills/modules/Paysys/";
#$debug = 4;
#opendir DIR, $modules_dir or die "Can't open dir '$modules_dir' $!\n";
#    my @paysys_modules = grep  /\.pm$/  , readdir DIR;
#closedir DIR;
#
#for(my $i=0; $i<=$#paysys_modules; $i++) {
#	my $paysys_module = $paysys_modules[$i];
#	undef $system_ips;
#	undef $systems_ident_params;
#	
#  print "$paysys_module"; 	 
#  require "$modules_dir$paysys_module";
#
#  my $pay_function = $paysys_module.'_payment';
#  if (! defined(&$pay_function)) {
#  	print "Not found" if ($debug > 2);
#  	next;
#   }
#
#	if ($debug > 3) {
# 
#	  if ($system_ips) {
#	    my @ips = split(/,/, $system_ips);
#	    foreach my $ip (@ips) {
#	      $systems_ips{$ip}="$paysys_module"."_payment";
#	     }
#	   }
#	  elsif (defined(%systems_ident_params)) {
#	    while(my ($param, $function) = %systems_ident_params) {
#	      $systemS_params{$param}="$paysys_module:$function";;
#	     }
#	   }
#	 
#	  if (!$@) {
#	  	print "Loaded";
#	   }
#	  print "<br>\n";
#	 }
#}

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
  	require "Ukrpays.pm";
   }
  elsif($FORM{smsid}) {
    smsproxy_payments();
   }
  elsif ($FORM{sign}) {
  	usmp_payments();
   }
  elsif ($FORM{lr_paidto}) {
 		require "Libertyreserve.pm";
   }
  else {
    print "Error: Unknown payment system";
    if (scalar keys %FORM > 0) {
     	if ($debug == 0) {
     	  while(my($k, $v)=each %FORM) {
	        $output2 .= "$k -> $v\n"	if ($k ne '__BUFFER');
        }
       }
    	mk_log($output2, { PAYSYS_ID => 'Unknown' });
    }
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
	      my $uid = $list->[0][8];
	      my $sum = $list->[0][3];
        my $user = $users->info($uid);
        $payments->add($user, {SUM      => $sum,
    	                     DESCRIBE     => 'PORTMONE',
    	                     METHOD       => ($conf{PAYSYS_PAYMENTS_METHODS} && $PAYSYS_PAYMENTS_METHODS{45}) ? 45 : '2',
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
#MerID=100000000918471 
#OrderID=test00000001g5hg45h45
#AcqID=414963
#Signature=e2DkM6RYyNcn6+okQQX2BNeg/+k=
#ECI=5
#IP=217.117.65.41
#CountryBIN=804
#CountryIP=804
#ONUS=1
#Time=22/01/2007 13:56:38
#Signature2=nv7CcUe5t9vm+uAo9a52ZLHvRv4=
#ReasonCodeDesc=Transaction is approved.
#ResponseCode=1
#ReasonCode=1
#ReferenceNo=702308304646
#PaddedCardNo=XXXXXXXXXXXX3982
#AuthCode=073291
#**********************************************************
sub privatbank_payments {
  #Get order
  my $status = 0;

  my $list = $Paysys->list({ TRANSACTION_ID => "$FORM{'OrderID'}",
      	                     INFO           => '-',
  	                         });

 if ($Paysys->{TOTAL} > 0) {
   if (	$FORM{ReasonCode} == 1 ) {    
	      #$html->message('info', $_INFO, "$_ADDED $_SUM: $list->[0][3] ID: $FORM{SHOPORDERNUMBER }");
	      my $uid = $list->[0][8];
	      my $sum = $list->[0][3];
        my $user = $users->info($uid);
        $payments->add($user, {SUM      => $sum,
    	                     DESCRIBE     => 'PBANK',
    	                     METHOD       => ($conf{PAYSYS_PAYMENTS_METHODS} && $PAYSYS_PAYMENTS_METHODS{48}) ? 48 : '2', 
  	                       EXT_ID       => "PBANK:$FORM{OrderID}",
  	                       CHECK_EXT_ID => "PBANK:$FORM{OrderID}" } ); 


        #Exists
        if ($payments->{errno} && $payments->{errno} == 7) {
          $status = 8;  	
         }
        elsif ($payments->{errno}) {
          $status = 4;
         }
        else{
   	      $Paysys->change({ ID        => $list->[0][0],
   	      	                PAYSYS_IP => $ENV{'REMOTE_ADDR'},
 	                          INFO      => "ReasonCode: $FORM{ReasonCode}\n Authcode: $FORM{AuthCode}\n PaddedCardNo:$FORM{PaddedCardNo}\n ResponseCode: $FORM{ResponseCode}\n ReasonCodeDesc: $FORM{ReasonCodeDesc}\n IP: $FORM{IP}\n Signature:$FORM{Signature}"
 	                  });
         }

	      if ($conf{PAYSYS_EMAIL_NOTICE}) {
	      	my $message = "\n".
	      	 "System: Privat Bank\n".
	      	 "DATE: $DATE $TIME\n".
	      	 "LOGIN: $user->{LOGIN} [$uid]\n".
	      	 "\n".
       	   "\n".
	      	 "ID: $list->[0][0]\n".
	      	 "SUM: $sum\n";

          sendmail("$conf{ADMIN_MAIL}", "$conf{ADMIN_MAIL}", "Privat Bank Add",
              "$message", "$conf{MAIL_CHARSET}", "2 (High)");
	      	
	       }

    }
   else {
     $Paysys->change({ ID        => $list->[0][0],
     	                 PAYSYS_IP => $ENV{'REMOTE_ADDR'},
 	                     INFO      => "ReasonCode: $FORM{ReasonCode}. $FORM{ReasonCodeDesc}"
 	                 });
  	}

  }
	
 
	my $home_url = '/index.cgi';
  $home_url = $ENV{SCRIPT_NAME};
  $home_url =~ s/paysys_check.cgi/index.cgi/;
 
	if ($FORM{ResponseCode} == 1) {
	  print "Location: $home_url?PAYMENT_SYSTEM=48&OrderID=$FORM{OrderID}&TRUE=1". "\n\n";
	 }
	else {
		#print "Content-Type: text/html\n\n";
		#print "FAILED PAYSYS: Portmone SUM: $FORM{BILL_AMOUNT} ID: $FORM{SHOPORDERNUMBER} STATUS: $status";
		print "Location:$home_url?PAYMENT_SYSTEM=48&OrderID=$FORM{OrderID}&FALSE=1&ReasonCodeDesc=$FORM{ReasonCodeDesc}&ReasonCode=$FORM{ReasonCode}&ResponseCode=$FORM{ResponseCode}". "\n\n";
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
 my $txn_id            = 'osmp_txn_id';
 my $payment_system    = 'OSMP';
 my $payment_system_id = 44;
 my $CHECK_FIELD       = $conf{PAYSYS_OSMP_ACCOUNT_KEY} || 'UID';

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
 if ($conf{PAYSYS_PEGAS} && $ENV{REMOTE_ADDR} ne '213.186.115.164') {
 	 $txn_id            = 'txn_id';
 	 $payment_system    = 'PEGAS';
 	 $payment_system_id = 49;
 	 $status_hash{5}    = 'Неверный индентификатор абонента';
 	 $status_hash{243}  = 'Невозможно проверитьсостояние счёта';
 	 $CHECK_FIELD       = $conf{PAYSYS_PEGAS_ACCOUNT_KEY} || 'UID';
  }

my $comments = '';
my $command = $FORM{command};

$FORM{account} =~ s/^0+//g if ($FORM{account} && $CHECK_FIELD eq 'UID');

my %RESULT_HASH=( result => 300 );
my $results = '';

mk_log("$payment_system: $ENV{QUERY_STRING}") if ($debug > 0);

#Check user account
#https://service.someprovider.ru:8443/payment_app.cgi?command=check&txn_id=1234567&account=0957835959&sum=10.45
if ($command eq 'check') {
  my $list = $users->list({ $CHECK_FIELD => $FORM{account} });

  if (! $conf{PAYSYS_PEGAS} && ! $FORM{sum}) {
  	$status = 300;
   }
  elsif ($users->{errno}) {
	  $status = 300;
   }
  elsif ($users->{TOTAL} < 1) {
    if ($CHECK_FIELD eq 'UID' && $FORM{account} !~ /\d+/) {
      $status   =  4;
     }
    elsif ($FORM{account} !~ /$conf{USERNAMEREGEXP}/)  {
      $status   =  4;
     }
	  else {
	  	$status   =  5;
	   }
	  $comments = 'User Not Exist';
   }
  else {
    $status = 0;
   }

  $RESULT_HASH{result} = $status;

  #For OSMP
  if ($payment_system_id == 44) {
    $RESULT_HASH{$txn_id}= $FORM{txn_id} ;
    $RESULT_HASH{prv_txn}= $FORM{prv_txn};
    $RESULT_HASH{comment}= "Balance: $list->[0]->[2]" if ($status == 0);
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
  	if ($conf{PAYSYS_PEGAS})  {
  		$RESULT_HASH{result}=0;
  	 }
  	else {
  	  $RESULT_HASH{result}=79;
  	 }
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
  elsif (! $FORM{sum}) {
	  $status =  300;
   }
  else {
    #Add payments
    $payments->add($user, {SUM          => $FORM{sum},
    	                     DESCRIBE     => "$payment_system",
    	                     METHOD       => ($conf{PAYSYS_PAYMENTS_METHODS} && $PAYSYS_PAYMENTS_METHODS{$payment_system_id}) ?$payment_system_id : '2', ,
  	                       EXT_ID       => "$payment_system:$FORM{txn_id}",
  	                       CHECK_EXT_ID => "$payment_system:$FORM{txn_id}" } ); 

    cross_modules_call('_payments_maked', { USER_INFO => $user, QUITE => 1 });

    #Exists
    if ($payments->{errno} && $payments->{errno} == 7) {
      $status      = 0;  	
      $payments_id = $payments->{ID};
     }
    elsif ($payments->{errno}) {
      $status = 4;
     }
    else {
      $payments_id = ($payments->{INSERT_ID}) ? $payments->{INSERT_ID} : 0;
    	$status = 0;
    	$Paysys->add({ SYSTEM_ID   => $payment_system_id,
 	              DATETIME       => "'$DATE $TIME'",
 	              SUM            => "$FORM{sum}",
  	            UID            => "$user->{UID}",
                IP             => $ENV{REMOTE_ADDR},
                TRANSACTION_ID => "$payment_system:$FORM{txn_id}",
                INFO           => "TYPE: $FORM{command} PS_TIME: ".
  (($FORM{txn_date}) ? $FORM{txn_date} : '' ) ." STATUS: $status $status_hash{$status}",
                PAYSYS_IP      => "$ENV{'REMOTE_ADDR'}",
                STATUS         => 2
               });
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


my $response = qq{<?xml version="1.0" encoding="UTF-8"?>
<response>
$results
</response>
};


print $response;
if ($debug > 0) {
  mk_log($response);	
}



exit;
}

#**********************************************************
# OSMP
# protocol-version 4.00
# IP 92.125.xxx.xxx
# $conf{PAYSYS_OSMP_LOGIN}
# $conf{PAYSYS_OSMP_PASSWD}
# $conf{PAYSYS_OSMP_SERVICE_ID}
# $conf{PAYSYS_OSMP_TERMINAL_ID}
#
#**********************************************************
sub osmp_payments_v4 {
 my ($attr) = @_;
 
 my $version = '0.2';
 $debug      =  1;
 print "Content-Type: text/xml\n\n";

 my $payment_system    = $attr->{SYSTEM_SHORT_NAME} || 'OSMP';
 my $payment_system_id = $attr->{SYSTEM_ID} || 61;
 
 my $CHECK_FIELD = $conf{PAYSYS_OSMP_ACCOUNT_KEY} || 'UID';
 $FORM{__BUFFER}='' if (! $FORM{__BUFFER});
 $FORM{__BUFFER}=~s/data=//;


eval { require XML::Simple; };
if (! $@) {
   XML::Simple->import();
 }
else {
   print "Content-Type: text/html\n\n";
   print "Can't load 'XML::Simple' check http://www.cpan.org";
   exit;
 }

$FORM{__BUFFER} =~ s/encoding="windows-1251"//g;
my $_xml = eval { XMLin("$FORM{__BUFFER}", forcearray=>1) };

if($@) {
  mk_log("---- Content:\n".
      $FORM{__BUFFER}.
      "\n----XML Error:\n".
      $@
      ."\n----\n");

  return 0;
}
else {
  if ($debug == 1) {
 	  mk_log($FORM{__BUFFER});
   }
}



my %request_hash = ();
my $request_type = '';

my $status_id    = 0;
my $result_code  = 0;
my $service_id   = 0;
my $response     = '';

my $BALANCE      = 0.00;
my $OVERDRAFT    = 0.00;
my $txn_date     = "$DATE$TIME";
$txn_date =~ s/[-:]//g;
my $txn_id = 0;

$request_hash{'protocol-version'}   =  $_xml->{'protocol-version'}->[0];
$request_hash{'request-type'}       =  $_xml->{'request-type'}->[0] || 0;
$request_hash{'terminal-id'}        =  $_xml->{'terminal-id'}->[0];
$request_hash{'login'}              =  $_xml->{'extra'}->{'login'}->{'content'};
$request_hash{'password'}           =  $_xml->{'extra'}->{'password'}->{'content'};
$request_hash{'password-md5'}       =  $_xml->{'extra'}->{'password-md5'}->{'content'};
$request_hash{'client-software'}    =  $_xml->{'extra'}->{'client-software'}->{'content'};
my $transaction_number              =  $_xml->{'transaction-number'}->[0] || '';

$request_hash{'to'} = $_xml->{to};

if ($request_hash{'password-md5'}) {
  $md5->reset;
  $md5->add($conf{PAYSYS_OSMP_PASSWD});
  $conf{PAYSYS_OSMP_PASSWD} = lc($md5->hexdigest());	
}


if ($conf{PAYSYS_OSMP_LOGIN} ne $request_hash{'login'} ||
 ($request_hash{'password'} && $conf{PAYSYS_OSMP_PASSWD} ne $request_hash{'password'})) {
	$status_id    = 150;
	$result_code  = 1;


  $response = qq{
<txn-date>$txn_date</txn-date>
<status-id>$status_id</status-id>
<txn-id>$txn_id</txn-id>
<result-code>$result_code</result-code>
};	
 }
elsif (defined($_xml->{'status'})) {
	my $count = $_xml->{'status'}->[0]->{count};
  my @payments_arr=();
  my %payments_status = ();
 
  for(my $i=0; $i<$count; $i++) {
  	push @payments_arr, $_xml->{'status'}->[0]->{'payment'}->[$i]->{'transaction-number'}->[0];
   } 

  my $ext_ids = "'$payment_system:". join("', '$payment_system:", @payments_arr)."'";
  my $list = $payments->list({ EXT_IDS => $ext_ids, PAGE_ROWS => 100000  });

  if ($payments->{errno}) {
     $status_id=78;
   }
  else {
    foreach my $line (@$list) {
  	  my $ext = $line->[7];
  	  $ext =~ s/$payment_system://g;
  	  $payments_status{$ext}=$line->[0];
     }

    foreach my $id (@payments_arr) {
      if ($id < 1) {
    	  $status_id=160;
       }
      elsif ($payments_status{$id}) {
    	  $status_id=60;
       }         
      else {
        $status_id=10;
       }

      $response .= qq{
<payment transaction-number="$id" status="$status_id" result-code="0" final-status="true" fatal-error="true">
</payment>\n };
     }	
   }
 }
#User info
elsif ($request_hash{'request-type'} == 1) {
  my $to             = $request_hash{'to'}->[0];
  my $amount         = $to->{'amount'}->[0];
  my $sum            = $amount->{'content'};
  my $currency       = $amount->{'currency-code'};
  my $account_number = $to->{'account-number'}->[0];
  my $service_id     = $to->{'service-id'}->[0];
  my $receipt_number = $_xml->{receipt}->[0]->{'receipt-number'}->[0];

  my $user;
  my $payments_id = 0;
 
  if ($account_number !~ /$conf{USERNAMEREGEXP}/)  {
    $status_id   =  4;
    $result_code =  1;
   }
  elsif ($CHECK_FIELD eq 'UID') {
    $user = $users->info($account_number);
    $BALANCE      = sprintf("%2.f", $user->{DEPOSIT});
    $OVERDRAFT    = $user->{CREDIT};
   }
  else {
    my $list = $users->list({ $CHECK_FIELD => $account_number });

    if (! $users->{errno} && $users->{TOTAL} > 0 ) {
      my $uid = $list->[0]->[5+$users->{SEARCH_FIELDS_COUNT}];
      $user = $users->info($uid);
      $BALANCE      = sprintf("%2.f", $user->{DEPOSIT});
      $OVERDRAFT    = $user->{CREDIT};
     }
   }

  if ($users->{errno}) {
	  $status_id   =  79;
	  $result_code =  1;
   }
  elsif ($users->{TOTAL} < 1) {
	  $status_id   =  5;
	  $result_code =  1;
   }


$response = qq{
<txn-date>$txn_date</txn-date>
<status-id>$status_id</status-id>
<txn-id>$txn_id</txn-id>
<result-code>$result_code</result-code>
<from>
<service-id>$service_id</service-id>
<account-number>$account_number</account-number>
</from>
<to>
<service-id>1</service-id>
<amount>amount</amount>
<account-number>$account_number</account-number>
<extra name="FIO">$user->{FIO}</extra>
</to>};
}
# Payments
elsif($request_hash{'request-type'} == 2) {
  my $to             = $request_hash{'to'}->[0];
  my $amount         = $to->{'amount'}->[0];
  my $sum            = $amount->{'content'};
  my $currency       = $amount->{'currency-code'};
  my $account_number = $to->{'account-number'}->[0];
  my $service_id     = $to->{'service-id'}->[0];
  my $receipt_number = $_xml->{receipt}->[0]->{'receipt-number'}->[0];
 
  my $txn_id = 0;
  my $user;
  my $payments_id = 0;

  if ($CHECK_FIELD eq 'UID') {
    $user = $users->info($account_number);
    $BALANCE      = sprintf("%2.f", $user->{DEPOSIT});
    $OVERDRAFT    = $user->{CREDIT};
   }
  else {
    my $list = $users->list({ $CHECK_FIELD => $account_number });

    if (! $users->{errno} && $users->{TOTAL} > 0 ) {
      my $uid     = $list->[0]->[5+$users->{SEARCH_FIELDS_COUNT}];
      $user       = $users->info($uid);
      $BALANCE    = sprintf("%2.f", $user->{DEPOSIT});
      $OVERDRAFT  = $user->{CREDIT};
     }
   }

  if ($users->{errno}) {
	  $status_id   =  79;
	  $result_code =  1;
   }
  elsif ($users->{TOTAL} < 1) {
	  $status_id   =  5;
	  $result_code =  1;
   }
  else {
    #Add payments
    $payments->add($user, {SUM          => $sum,
    	                     DESCRIBE     => "$payment_system",
    	                     METHOD       => ($conf{PAYSYS_PAYMENTS_METHODS} && $PAYSYS_PAYMENTS_METHODS{44}) ? 44 : '2', 
  	                       EXT_ID       => "$payment_system:$transaction_number",
  	                       CHECK_EXT_ID => "$payment_system:$transaction_number" } ); 

    cross_modules_call('_payments_maked', { USER_INFO => $user, QUITE => 1 });

    #Exists
    if ($payments->{errno} && $payments->{errno} == 7) {
      $status_id   = 10;  	
      $result_code =  1;
      $payments_id = $payments->{ID};
     }
    elsif ($payments->{errno}) {
      $status_id = 78;
      $result_code =  1;
     }
    else {
    	$Paysys->add({ SYSTEM_ID => $payment_system_id,
 	              DATETIME       => "'$DATE $TIME'",
 	              SUM            => "$sum",
  	            UID            => "$user->{UID}",
                IP             => '0.0.0.0',
                TRANSACTION_ID => "$payment_system:$transaction_number",
                INFO           => " STATUS: $status_id RECEIPT Number: $receipt_number",
                PAYSYS_IP      => "$ENV{'REMOTE_ADDR'}"
               });

      $payments_id = ($Paysys->{INSERT_ID}) ? $Paysys->{INSERT_ID} : 0;
      $txn_id = $payments_id;
     }   
	 }

$response = qq{
<txn-date>$txn_date</txn-date>
<txn-id>$txn_id</txn-id>
<receipt>
<datetime>0</datetime>
</receipt>
<from>
<service-id>$service_id</service-id>
<amount>$sum</amount>
<account-number>$account_number</account-number>
</from>
<to>
<service-id>$service_id</service-id>
<amount>$sum</amount>
<account-number>$account_number</account-number>
</to>
}
}
# Pack processing
elsif($request_hash{'request-type'} == 10) {
	my $count = $_xml->{auth}->[0]->{count};
  my $final_status='';
  my $fatal_error='';
	
	for($i=0; $i < $count; $i++) {
    my %request_hash = %{ $_xml->{auth}->[0]->{payment}->[$i] };
    my $to             = $request_hash{'to'}->[0];
    $transaction_number = $request_hash{'transaction-number'}->[0] || '';
#    my $amount         = $to->{'amount'}->[0];
    my $sum            = $to->{'amount'}->[0];
#    my $currency       = $amount->{'currency-code'};
    my $account_number = $to->{'account-number'}->[0];
    my $service_id     = $to->{'service-id'}->[0];
    my $receipt_number = $_xml->{receipt}->[0]->{'receipt-number'}->[0];

  if ($CHECK_FIELD eq 'UID') {
    $user       = $users->info($account_number);
    $BALANCE    = sprintf("%2.f", $user->{DEPOSIT});
    $OVERDRAFT  = $user->{CREDIT};
   }
  else {
    my $list = $users->list({ $CHECK_FIELD => $account_number });

    if (! $users->{errno} && $users->{TOTAL} > 0 ) {
      my $uid    = $list->[0]->[5+$users->{SEARCH_FIELDS_COUNT}];
      $user      = $users->info($uid);
      $BALANCE   = sprintf("%2.f", $user->{DEPOSIT});
      $OVERDRAFT = $user->{CREDIT};
     }
   }

  if ($users->{errno}) {
	  $status_id   =  79;
	  $result_code =  1;
   }
  elsif ($users->{TOTAL} < 1) {
	  $status_id   =  0;
	  $result_code =  0;
   }
  else {
    #Add payments
    $payments->add($user, {SUM          => $sum,
    	                     DESCRIBE     => "$payment_system",
    	                     METHOD       => ($conf{PAYSYS_PAYMENTS_METHODS} && $PAYSYS_PAYMENTS_METHODS{44}) ? 44 : '2', 
  	                       EXT_ID       => "$payment_system:$transaction_number",
  	                       CHECK_EXT_ID => "$payment_system:$transaction_number" } ); 

    #Exists
    if ($payments->{errno} && $payments->{errno} == 7) {
      $status_id   = 10;  	
      $result_code =  1;
      $payments_id = $payments->{ID};
     }
    elsif ($payments->{errno}) {
      $status_id   = 78;
      $result_code =  1;
     }
    else {
    	$Paysys->add({ SYSTEM_ID   => $payment_system_id,
 	              DATETIME       => "'$DATE $TIME'",
 	              SUM            => "$sum",
  	            UID            => "$user->{UID}",
                IP             => '0.0.0.0',
                TRANSACTION_ID => "$payment_system:$transaction_number",
                INFO           => " STATUS: $status_id RECEIPT Number: $receipt_number",
                PAYSYS_IP      => "$ENV{'REMOTE_ADDR'}"
               });

      $payments_id = ($Paysys->{INSERT_ID}) ? $Paysys->{INSERT_ID} : 0;
      $txn_id = $payments_id;
      $status_id = 51;
     }   
	 }

   $fatal_error = ($status_id != 51 && $status_id != 0) ? 'true' : 'false';
$response .= qq{
<payment status="$status_id" transaction-number="$transaction_number" result-code="$result_code" final-status="true"fatal-error="$fatal_error">
<to>
<service-id>$service_id</service-id>
<amount>$sum</amount>
<account-number>$account_number</account-number>
</to>
</payment>
	
};

}
}

my $output = qq{<?xml version="1.0" encoding="windows-1251"?>
<response requestTimeout="60">
<protocol-version>4.00</protocol-version>
<configuration-id>0</configuration-id>
<request-type>$request_hash{'request-type'}</request-type>
<terminal-id>$request_hash{'terminal-id'}</terminal-id>
<transaction-number>$transaction_number</transaction-number>
<status-id>$status_id</status-id>
};

$output .= $response . qq{
 <operator-id>$admin->{AID}</operator-id>
 <extra name="REMOTE_ADDR">$ENV{REMOTE_ADDR}</extra>
 <extra name="client-software">ABillS Paysys $payment_system $version</extra>
 <extra name="version-conf">$version</extra>
 <extra name="serial">$version</extra>
 <extra name="BALANCE">$BALANCE</extra>
 <extra name="OVERDRAFT">$OVERDRAFT</extra>
</response>};

print $output;

if ($debug > 0) {
 	mk_log("RESPONSE:\n". $output);
 }


return $status_id;
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

 $Paysys->add({ SYSTEM_ID      => 43,
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
  $Paysys->add({ SYSTEM_ID      => 42,
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
    	                     METHOD       => ($conf{PAYSYS_PAYMENTS_METHODS} && $PAYSYS_PAYMENTS_METHODS{42}) ? 42 : '2',
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
  $Paysys->add({ SYSTEM_ID      => 42,
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
   }
  elsif (defined($FORM{LMI_MODE}) && $FORM{LMI_MODE} == 1) {
  	$status = 'Test mode';
   }
  elsif (length($FORM{LMI_HASH}) != 32 ) {
  	$status = 'Not MD5 checksum';
   }
  elsif ($FORM{LMI_HASH} ne $checksum) {
  	$status = "Incorect checksum \"$checksum/$FORM{LMI_HASH}\"";
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
    my $pay_describe = ($FORM{LMI_PAYMENT_DESC} && $conf{dbcharset} eq 'utf8') ? convert($FORM{LMI_PAYMENT_DESC}, { win2utf8 =>1 }) : 'Webmoney';
    $payments->add($user, {SUM          => $FORM{LMI_PAYMENT_AMOUNT},
    	                     DESCRIBE     => $pay_describe,
    	                     METHOD       => ($conf{PAYSYS_PAYMENTS_METHODS} && $PAYSYS_PAYMENTS_METHODS{41}) ? 41 : '2',
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
  $Paysys->add({ SYSTEM_ID      => 41,
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
#  $Paysys->add({ SYSTEM_ID      => 41,
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

#**********************************************************
# mak_log
#**********************************************************
sub mk_log {
  my ($message, $attr) = @_;
  my $paysys = $attr->{PAYSYS_ID} || '';
  my $paysys_log_file = 'paysys_check.log';
  if (open(FILE, ">>$paysys_log_file")) {
    print FILE "\n$DATE $TIME $ENV{REMOTE_ADDR} $paysys =========================\n";
   
    if ($attr->{REQUEST}) {
    	print FILE "$attr->{REQUEST}\n=======\n";
     }
   
    print FILE $message;
	  close(FILE);
	 }
  else {
    print "Can't open file '$paysys_log_file' $!\n";
   }
}


#**********************************************************
# Calls function for all registration modules if function exist
#
# cross_modules_call(function_sufix, attr)
#**********************************************************
sub cross_modules_call  {
  my ($function_sufix, $attr) = @_;

eval {
  my %full_return  = ();
  my @skip_modules = ();
  open($SAVEOUT, ">&", STDOUT) or die "XXXX: $!";

  #Reset out
  open STDIN, '/dev/null';
  open STDOUT, '/dev/null';
  open STDERR, '/dev/null'; 

  if ($attr->{SKIP_MODULES}) {
  	$attr->{SKIP_MODULES}=~s/\s+//g;
  	@skip_modules=split(/,/, $attr->{SKIP_MODULES});
   }
 
  foreach my $mod (@MODULES) {
  	if (in_array($mod, \@skip_modules)) {
  		next;
  	 }
    require "Abills/modules/$mod/webinterface";
    my $function = lc($mod).$function_sufix;
    my $return;
    if (defined(&$function)) {
     	$return = $function->($attr);
     }
    $full_return{$mod}=$return;
   }
  open (STDOUT, ">&", $SAVEOUT); 
};

  return \%full_return;
}



#**********************************************************
# load_module($string, \%HASH_REF);
#**********************************************************
sub load_module {
	my ($module, $attr) = @_;

	my $lang_file = '';
  foreach my $prefix (@INC) {
    my $realfilename = "$prefix/Abills/modules/$module/lng_$attr->{language}.pl";
    if (-f $realfilename) {
      $lang_file =  $realfilename;
      last;
     }
    elsif (-f "$prefix/Abills/modules/$module/lng_english.pl") {
    	$lang_file = "$prefix/Abills/modules/$module/lng_english.pl";
     }
   }

  if ($lang_file ne '') {
    require $lang_file;
   }

 	require "Abills/modules/$module/webinterface";

	return 0;
}

1

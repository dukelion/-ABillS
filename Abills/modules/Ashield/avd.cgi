#!/usr/bin/perl -w
# AVD processing system
#

use vars qw($begin_time %FORM %LANG 
$DATE $TIME
$CHARSET 
@MODULES
$admin
$users 
$payments
);

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
use Finance;
use Admins;
use Ashield;
use Fees;

require "language/$conf{default_language}.pl";
my $debug  = $conf{ASHIELD_AVD_DEBUG} || 0;
my $html   = Abills::HTML->new();
my $sql    = Abills::SQL->connect($conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser},
    $conf{dbpasswd}, { CHARSET => ($conf{dbcharset}) ? $conf{dbcharset} : undef  });
my $db     = $sql->{db};
#Operation status
my $status = '';

$admin = Admins->new($db, \%conf);
$users = Users->new($db, $admin, \%conf); 
my $Ashield = Ashield->new($db, $admin, \%conf);
my $Tariffs = Tariffs->new($db, \%conf, $admin);
my $Fees    = Fees->new($db, $admin, \%conf);
my $remote_ip = $ENV{REMOTE_ADDR} || '0.0.0.0';

$FORM{'__BUFFER'}=q{<?xml version="1.0" encoding="UTF-8"?>
<users-list xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.av-desk.com/static/avdpo/schema/1.0/USERS http://www.av-desk.com/static/avdpo/schema/1.0/users-list.xsd" lang-code="en" status="true">
  <user id="1" login="drew">
    <name>Андрей</name>
    <patronymic></patronymic>
    <last-name>Сипиев</last-name>
    <billing-id></billing-id>
    <billing-login></billing-login>
    <billing-contract></billing-contract>
    <email>kaktatak@gmail.com</email>
    <status>ENABLE</status>
    <max-agents>-1</max-agents>
    <address></address>
    <rights>0</rights>
    <legal-subject>20</legal-subject>
    <type>ADMIN</type>
    <group id="1"><![CDATA[Administrators]]></group>
    <createdtime>2010-10-07 01:00:08</createdtime>
    <modifiedtime>2010-10-07 01:00:08</modifiedtime>
    <avdesk-admin-uuid></avdesk-admin-uuid>
    <avdesk-admin-login></avdesk-admin-login>
    <avdesk-admin-password></avdesk-admin-password>
    <description/>
    <agents total="2">
      <agent unsubscribed="0" auto-prolongation="">
        <createdtime>2010-11-27 14:38:13</createdtime>
        <uuid>hoc-aa2a08c6-570c-5021-8c19-e994c1d4</uuid>
        <password>6T5iHkRmOIfHy</password>
        <current-tariff>STANDART</current-tariff>
        <grace-period>
          <begin></begin>
          <end></end>
        </grace-period>
        <subscription-period>30</subscription-period>
        <url>http://drweb.mlan.net.ua:9080/download/download.ds?id=hoc-aa2a08c6-570c-5021-8c19-e994c1d4</url>
      </agent>
      <agent unsubscribed="0" auto-prolongation="1">
        <createdtime>2010-11-27 12:42:36</createdtime>
        <uuid>hoc-c0196230-aaac-c4f8-4ebf-a4fd6ac3</uuid>
        <password>28wSxn6ETESfB</password>
        <current-tariff>CLASSIC</current-tariff>
        <grace-period>
          <begin>2010-11-27 13:42:36</begin>
          <end>2010-12-28 13:42:36</end>
        </grace-period>
        <subscription-period>30</subscription-period>
        <url>http://drweb.mlan.net.ua:9080/download/download.ds?id=hoc-c0196230-aaac-c4f8-4ebf-a4fd6ac3</url>
      </agent>
    </agents>
  </user>
  <user id="2" login="abills">
    <name>abills</name>
    <patronymic></patronymic>
    <last-name>billing</last-name>
    <billing-id></billing-id>
    <billing-login></billing-login>
    <billing-contract></billing-contract>
    <email>abills@mlan.net.ua</email>
    <status>ENABLE</status>
    <max-agents>-1</max-agents>
    <address></address>
    <rights>0</rights>
    <legal-subject>20</legal-subject>
    <type>ADMIN</type>
    <group id="1"><![CDATA[Administrators]]></group>
    <createdtime>2010-11-21 22:49:20</createdtime>
    <modifiedtime>2010-11-21 22:49:20</modifiedtime>
    <avdesk-admin-uuid></avdesk-admin-uuid>
    <avdesk-admin-login></avdesk-admin-login>
    <avdesk-admin-password></avdesk-admin-password>
    <description/>
    <agents total="0"/>
  </user>
  <user id="3" login="test">
    <name>-</name>
    <patronymic>-</patronymic>
    <last-name>-</last-name>
    <billing-id>2263</billing-id>
    <billing-login>test</billing-login>
    <billing-contract></billing-contract>
    <email>asm@yes.net.ua</email>
    <status>ENABLE</status>
    <max-agents>-1</max-agents>
    <address></address>
    <rights>0</rights>
    <legal-subject>20</legal-subject>
    <type>USER</type>
    <group id="3"><![CDATA[Users]]></group>
    <createdtime>2010-11-27 00:13:45</createdtime>
    <modifiedtime>2010-11-27 00:13:45</modifiedtime>
    <avdesk-admin-uuid></avdesk-admin-uuid>
    <avdesk-admin-login></avdesk-admin-login>
    <avdesk-admin-password></avdesk-admin-password>
    <description/>
    <agents total="0"/>
  </user>
</users-list>};

my $drweb_version = $conf{ASHIELD_DRWEB_VERSION} || 1;

if ($drweb_version != 1) {
	drweb_periodic({ CONTENT => $FORM{'__BUFFER'}  });
	
	exit;
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
		elsif ($remote_ip =~ /^$ip/) {
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
    sendmail("$conf{ADMIN_MAIL}", "$conf{ADMIN_MAIL}", "ABillS - Ashield", 
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



$admin->info($conf{SYSTEM_ADMIN_ID}, { IP => '127.0.0.1' });
$payments = Finance->payments($db, $admin, \%conf);


#debug =========================================
my $output2 = '';
while(my($k, $v)=each %FORM) {
 	$output2 .= "$k, $v\n"	if ($k ne '__BUFFER');
}
#my $rew `echo $output2 >> /tmp/ukrpays`;
#END debug =====================================

print "Content-Type: text/html\n\n";

#$FORM{'__BUFFER'}=qq{xml=<?xml version="1.0" encoding="UTF-8"?>
#<personal-office timestamp="20100610203403">
#  <login>test3</login>
#  <name>test tewtst</name>
#  <lastname>test</lastname>
#  <action>
#    <type>3</type>
#    <agentuuid>3bccbd92-d21d-b211-8dbc-ea17cb6d883e</agentuuid>
#    <groupuuid>ebe76ffc-69e1-4757-b2b3-41506832bc9b</groupuuid>
#    <groupname>AV+AS</groupname>
#    <datetime>20100610203403</datetime>
#  </action>
#</personal-office>
#&checkword=827ccb0eea8a706c4c34a16891f84e7b};

mk_log($FORM{'__BUFFER'});

my @pairs = split(/&/, $FORM{'__BUFFER'});
foreach my $line (@pairs) {
	my ($key, $val)=split(/=/, $line, 2);
	$FORM{$key}=$val;
}

avd_add({ CONTENT    => $FORM{'xml'},
	        checkword  => $FORM{'checkword'}
     	});


#**********************************************************
# mak_log
#1. Оформление новой подписки.
#2. Смена тарифного плана.
#3. Возобновление подписки.
#4. Активация блокировки.
#5. Отказ от услуги.
# graceperiod
#**********************************************************
sub avd_add {
  my ($attr) = @_;

eval { require XML::Simple; };
if (! $@) {
   XML::Simple->import();
 }
else {
   print "Content-Type: text/plain\n\n";
   print "Can't load 'XML::Simple' check http://www.cpan.org";
   mk_log("Error: Can't load 'XML::Simple' check http://www.cpan.org\n");
   exit;
 }


#$FORM{xml} =~ s/encoding="windows-1251"//g;
my $_xml = eval { XMLin("$attr->{CONTENT}", forcearray=>1) };

if($@) {
  mk_log("---- Content:\n".
      $attr->{CONTENT}.
      "\n----XML Error:\n".
      $@
      ."\n----\n");
  return 0;
 }
else {
  if ($debug > 0) {
 	  mk_log($attr->{CONTENT});
   }
}


my $status  = $_xml->{'action'}->[0]->{type}->[0];
my $agent   = $_xml->{'action'}->[0]->{agentuuid}->[0];
my ($y, $m, $d)=split(/-/, $DATE, 3);
my $cur_date="$y$m$d"; 


if ($status < 4) {
  my $login   = $_xml->{'login'}->[0];
  my $list    = $users->list({ LOGIN => $login });
  my $TP_NAME = $_xml->{'action'}->[0]->{tariffplancode}->[0];
  
  my $uid = $list->[0]->[5+$users->{SEARCH_FIELDS_COUNT}];
  if ($users->{error}) {
	  mk_log("Error user '$login'");
   }
  elsif($users->{TOTAL} < 1) {	
	  mk_log("Can't find user '$login'");
   }
  else {
  	require "Abills/modules/Ashield/webinterface";
	  my $user = $users->info($uid);
	  
	  if ( $status == 3 ) {
       #get TP
	     my $result_hash;
	     if ($drweb_version == 1) {
	       $result_hash = ashield_drweb_request('interfaces/user_agents.php', {
      	  login      => "$users->{LOGIN}",
      	  id         => "$agent",
      	  checkword  => $conf{ASHIELD_DRWEB_CABINET_PASSWD}
      	  },
      	  { SERVER_ADDR    => "$conf{ASHIELD_DRWEB_CABINET_HOST}",
      	  	});
         }
       else {
       	  $result_hash=ashield_drweb_request('interfaces/get_user_info.php', {
      	  login      => "$users->{LOGIN}",
      	  checkword  => $conf{ASHIELD_DRWEB_CABINET_PASSWD},
      	  options    => 1,
      	  subscribes => 1,
      	  },
      	  { SERVER_ADDR    => "$conf{ASHIELD_DRWEB_CABINET_HOST}",
      	  	});
       	 $result_hash = $result_hash->{user}->[0];
        } 
       foreach my $k (@{ $result_hash->{agents}->[0]->{agent} }) { 
	       if ($k->{uuid}->[0] eq $agent) {
	       	 $TP_NAME = $k->{'current-tariff'}->[0] || $k->{tariffplancode}->[0];
	       	 last;
	        }
	      }
	    } 

      $Tariffs->info(0, { NAME => "$TP_NAME", MODULE => 'Ashield' });

      if ($Tariffs->{TOTAL} < 1) {
    	  mk_log("Tariff not exists. TP: '$TP_NAME'");
       }
      else {
		    my $agents_result_hash;
	      if ($drweb_version == 1) {
          my $agents_result_hash=ashield_drweb_request('interfaces/user_agents.php', {
       	    login      => "$users->{LOGIN}",
      	    checkword  => $conf{ASHIELD_DRWEB_CABINET_PASSWD}
      	    },
      	     { SERVER_ADDR    => "$conf{ASHIELD_DRWEB_CABINET_HOST}",
      	  	  });
         }
        else {
        	 $agents_result_hash=ashield_drweb_request('interfaces/get_user_info.php', {
      	     login      => "$users->{LOGIN}",
      	     checkword  => $conf{ASHIELD_DRWEB_CABINET_PASSWD},
      	     options    => 1,
      	     subscribes => 1,
      	    },
      	   { SERVER_ADDR    => "$conf{ASHIELD_DRWEB_CABINET_HOST}",
      	  	  });
       	   $agents_result_hash = $agents_result_hash->{user}->[0];
         }
        my $agent_count = $#{ $agents_result_hash->{agents}->[0]->{agent} };

        my $sum = $Tariffs->{MONTH_FEE};  
        $Tariffs->{PERIOD_ALIGNMENT}=1;
        if ($Tariffs->{PERIOD_ALIGNMENT}) {
        	my ($y, $m, $d)=split(/-/, $DATE);
          my $days_in_month=($m!=2?(($m%2)^($m>7))+30:(!($y%400)||!($y%4)&&($y%25)?29:28));
          $conf{START_PERIOD_DAY} = 1;
          $sum = sprintf("%.2f", ($sum / $days_in_month) * ($days_in_month - $d + $conf{START_PERIOD_DAY}));
         }
      
        if ($conf{ASHIELD_DRWEB_FREE_PERIOD} &&  $agent_count == 0
            && $status == 1) {
          print "Free Activate\n" if ($debug > 0);    	
         }
        elsif($status < 4 && ($user->{DEPOSIT} + $user->{CREDIT} > 0 || $Tariffs->{PAYMENT_TYPE})) {
          $Fees->take($users, "$sum", 
                     { DESCRIBE  => "Dr.Web TP: $TP_NAME", 
 	                     DATE      => "$DATE $TIME"
  	                  });


       	  my $result = ashield_drweb_request('api/2.0/change-customer-info.ds', { 
 	     	 	   id       => $agent, 
 	     	 	   blockbeg => '00000000',
 	     	 	   blockend => '00000000'
 	     	 	   }); 

 	        if ( $result->{error} ) { 	      	 
 	        	 my $code = $result->{error}->[0]->{code}->[0];
 	           if ($code == 17) {
 	           	 print "'$_xml->{'action'}->[0]->{agentuuid}->[0]', Customer Not Exist\n";
 	            }
             else {
           	   print "Block '$user->{LOGIN}' '$cur_date' $code / $result->{error}->[0]->{message}->[0]\n";
              }
 	         }
          else {    
  	        print "Activate\n" if ($debug > 0);
  	       }
         }
      #block account
        else {
        	my $result = ashield_drweb_request('api/2.0/change-customer-info.ds', { 
 	     	 	   id       => $_xml->{'action'}->[0]->{agentuuid}->[0], 
 	     	 	   blockbeg => $cur_date,
 	     	 	   blockend => '20300101'
 	     	 	   }); 
 	       
 	        if ( $result->{error} ) { 	      	 
 	        	 my $code = $result->{error}->[0]->{code}->[0];
 	           if ($code == 17) {
 	           	 print "'$_xml->{'action'}->[0]->{agentuuid}->[0]', Customer Not Exist\n";
 	            }
             else {
           	   print "Block '$user->{LOGIN}' '$cur_date' $code / $result->{error}->[0]->{message}->[0]\n";
              }
 	         }
 	        else {
 	           print "$result->{customers}->[0]->{customer}->[0]->{id}->[0] ".
 	            "BLOCKING: $result->{customers}->[0]->{customer}->[0]->{blockbeg}->[0]\n" if ($debug > 0);
 	         }
         }
      }
      if (! $Fees->{error}) {
        $Ashield->ashield_avd_add({ UID => $users->{UID},
      	 STATE      => $_xml->{'action'}->[0]->{type}->[0],
         AGENTUUID  => $_xml->{'action'}->[0]->{agentuuid}->[0],
         GROUPUUID  => $_xml->{'action'}->[0]->{groupuuid}->[0],
         GROUPNAME  => $_xml->{'action'}->[0]->{groupname}->[0],
         TARIFFPLANCODE  => $TP_NAME,
         TP_ID      => $Tariffs->{TP_ID} });
       }
  }
 }

}


#**********************************************************
# mak_log
#**********************************************************
sub mk_log {
  my ($message, $attr) = @_;
 
  if (open(FILE, ">>/tmp/avd.log")) {
    print FILE "\n$DATE $TIME $remote_ip=========================\n";
    print FILE $message;
	  close(FILE);
	 }
  else {
    print "Can't open file '/tmp/avd.log' $! \n";
   }
}


#**********************************************************
# drweb_periodic
#**********************************************************
sub drweb_periodic {
	  my ($attr) = @_;

eval { require XML::Simple; };
if (! $@) {
   XML::Simple->import();
 }
else {
   print "Content-Type: text/plain\n\n";
   print "Can't load 'XML::Simple' check http://www.cpan.org";
   mk_log("Error: Can't load 'XML::Simple' check http://www.cpan.org\n");
   exit;
 }

#$FORM{xml} =~ s/encoding="windows-1251"//g;
my $_xml = eval { XMLin("$attr->{CONTENT}", forcearray=>1) };

if($@) {
  mk_log("---- Content:\n".
      $attr->{CONTENT}.
      "\n----XML Error:\n".
      $@
      ."\n----\n");
  return 0;
 }
else {
  if ($debug > 0) {
 	  mk_log($attr->{CONTENT});
   }
}





}


1

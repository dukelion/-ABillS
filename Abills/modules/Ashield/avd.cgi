#!/usr/bin/perl -w
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
%PAYSYS_PAYMENTS_METHODS
);

BEGIN {
 my $libpath = '../';
 
 $sql_type='mysql';
 unshift(@INC, $libpath ."Abills/$sql_type/");
 unshift(@INC, $libpath);
 unshift(@INC, $libpath . 'libexec/');
 unshift(@INC, $libpath . 'Abills/modules/Paysys');

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

my $debug  = $conf{PAYSYS_DEBUG} || 0;
my $html   = Abills::HTML->new();
my $sql    = Abills::SQL->connect($conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser},
    $conf{dbpasswd}, { CHARSET => ($conf{dbcharset}) ? $conf{dbcharset} : undef  });
my $db     = $sql->{db};
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

$admin = Admins->new($db, \%conf);
$admin->info($conf{SYSTEM_ADMIN_ID}, { IP => '127.0.0.1' });
$payments = Finance->payments($db, $admin, \%conf);
$users = Users->new($db, $admin, \%conf); 

#debug =========================================
my $output2 = '';
while(my($k, $v)=each %FORM) {
 	$output2 .= "$k, $v\n"	if ($k ne '__BUFFER');
}
#my $rew `echo $output2 >> /tmp/ukrpays`;
#END debug =====================================

print "Content-Type: text/html\n\n";

$FORM{'__BUFFER'}=qq{xml=<?xml version="1.0" encoding="UTF-8"?>
<personal-office timestamp="20100406015006">
  <login>galaktika</login>
  <name></name>
  <lastname>-</lastname>
  <action>
    <type>1</type>
    <agentuuid>927f210d-d21d-b211-9ca9-a118a14d0e34</agentuuid>
    <groupuuid>ebe76ffc-69e1-4757-b2b3-41506832bc9b</groupuuid>
    <groupname>AV+AS</groupname>
    <tariffplancode>STANDART</tariffplancode>
  </action>
</personal-office>
&checkword=827ccb0eea8a706c4c34a16891f84e7b};

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
#**********************************************************
sub avd_add {
  my ($attr) = @_;

#$attr->{CONTENT} = qq{xml=<?xml version="1.0" encoding="UTF-8"?>
#<personal-office timestamp="20100406015006">
#  <login>galaktika</login>
#  <name></name>
#  <lastname>-</lastname>
#  <action>
#    <type>1</type>
#    <agentuuid>927f210d-d21d-b211-9ca9-a118a14d0e34</agentuuid>
#    <groupuuid>ebe76ffc-69e1-4757-b2b3-41506832bc9b</groupuuid>
#    <groupname>AV+AS</groupname>
#    <tariffplancode>STANDART</tariffplancode>
#  </action>
#</personal-office>
#&checkword=827ccb0eea8a706c4c34a16891f84e7b};
#
##$attr->{CONTENT} =~ /(.+)/;
##print "\n$1\n";
#
#my @Arr = split(/&/, $attr->{CONTENT});
#
#
#
#my($k, $val) = split(/=/, $Arr[0], 2);

eval { require XML::Simple; };
if (! $@) {
   XML::Simple->import();
 }
else {
   print "Content-Type: text/plain\n\n";
   print "Can't load 'XML::Simple' check http://www.cpan.org";
   mk_log("---- Error: Can't load 'XML::Simple' check http://www.cpan.org\n");
   exit;
 }

$FORM{xml} =~ s/encoding="windows-1251"//g;
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
  print << "[END]";
  
$_xml->{'login'}->[0];
$_xml->{'lastname'}->[0];

Type: $_xml->{'action'}->[0]->{type}->[0];
TP: $_xml->{'action'}->[0]->{tariffplancode}->[0];
[END]

}



#**********************************************************
# mak_log
#**********************************************************
sub mk_log {
  my ($message, $attr) = @_;
 
  if (open(FILE, ">>/tmp/avd.log")) {
    print FILE "\n$DATE $TIME $ENV{REMOTE_ADDR}=========================\n";
    print FILE $message;
	  close(FILE);
	 }
  else {
    print "Can't open file '/tmp/avd.log' $! \n";
   }
}

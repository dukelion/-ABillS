#!/usr/bin/perl -w
# Sharing registration
#


use vars qw($begin_time %FORM %LANG $CHARSET 
  @MODULES
  @REGISTRATION
  $PROGRAM
  $html
  $users
  $Bin
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
require "Abills/templates.pl";
require "Abills/defs.conf";

use Abills::Base;
use Abills::SQL;
use Abills::HTML;
use Users;
#use Paysys;
use Finance;
use Admins;
use Tariffs;
use Sharing;



$html = Abills::HTML->new({ CONF => \%conf, NO_PRINT => 1, });

my $sql = Abills::SQL->connect($conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd});
my $db = $sql->{db};
#Operation status
my $status = '';
#my $Paysys = Paysys->new($db, undef, \%conf);

my $admin = Admins->new($db, \%conf);
$admin->info($conf{SYSTEM_ADMIN_ID}, { IP => '127.0.0.1' });
my $payments = Finance->payments($db, $admin, \%conf);
$users = Users->new($db, $admin, \%conf); 


if (! defined( @REGISTRATION ) ) {
  print "Content-Type: text/html\n\n";
  print "Can't find modules services for registration";
	exit;
}

$html->{language}=$FORM{language} if (defined($FORM{language}));
require "../language/$html->{language}.pl";


if ($FORM{module}) {
	my $m = $FORM{module};
	require "Abills/modules/$m/config";
	require "Abills/modules/$m/webinterface";
	$m = lc($m);
	my $function = $m . '_registration';
  $function->();
  
#  exit;
 }
elsif ($FORM{FORGOT_PASSWD}) {
	password_recovery();
	
#	exit;
 }
elsif($#REGISTRATION == 0) {
	my $m = $REGISTRATION[0];
	require "Abills/modules/$m/config";
	require "Abills/modules/$m/webinterface";
	$m = lc($m);
	my $function = $m . '_registration';
  $function->();
  
#  exit;
}
else {
  foreach my $m (@REGISTRATION) {
	  #require "Abills/modules/$m/config";
	  #require "Abills/modules/$m/webinterface";
    print $html->button($m, "module=$m");
  }
}


$html->{METATAGS}=templates('metatags_client');  
print $html->header();
$OUTPUT{BODY}="$html->{OUTPUT}";
print $html->tpl_show(templates('form_client_start'), \%OUTPUT);



#**********************************************************
# Password recovery
#**********************************************************
sub password_recovery {
  
  if ($FORM{SEND}) {
    
    if (($FORM{EMAIL} && $FORM{EMAIL} =~ m/\*/) || ($FORM{LOGIN} && $FORM{LOGIN} =~ m/\*/)) {
    	$html->message('err', $_ERROR, "$ERR_WRONG_DATA");
      return 0;
     }
    my $list = $users->list({ %FORM });
	
  	if ($users->{TOTAL} > 0) {
  		my @u = @$list;
	    my $message = '';
	    my $email = $FORM{EMAIL} || '';
      my $uid = $line->[5];
      if ($FORM{LOGIN} && ! $FORM{EMAIL}) {
      	$email = $u[0][7];
       }

      if ($FORM{EMAIL}) {
        $uid = $line->[6];
       }
     

	    foreach my $line (@u) {
	       $users->info($line->[($FORM{EMAIL}) ? 6 : 5 ], { SHOW_PASSWORD => 1 });
    	   $message .= "$_LOGIN:  $users->{LOGIN}\n".
	                   "$_PASSWD: $users->{PASSWORD}\n".
	                   "================================================\n";
	     }

	   $message = $html->tpl_show(templates('msg_passwd_recovery'), 
	                                                    { MESSAGE => $message }, 
	                                                    { OUTPUT2RETURN => 1 });

     if ($email ne '') {
       sendmail("$conf{ADMIN_MAIL}", "$email", "$PROGRAM Password Repair", 
              "$message", "$conf{MAIL_CHARSET}", "");
 		   $html->message('info', $_INFO, "$_SENDED");
      }
	   else {
	   	 $html->message('info', $_INFO, "$_NOT_EXIST");
	    }
	
		  return 0;
	   }
	  else {
		  $html->message('err', $_ERROR, "$_NOT_EXIST");
	   }
	}
	
	$html->tpl_show(templates('form_forgot_passwd'), undef);
}

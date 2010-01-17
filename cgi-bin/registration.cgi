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

my $sql = Abills::SQL->connect($conf{dbtype}, 
                               $conf{dbhost}, 
                               $conf{dbname}, 
                               $conf{dbuser}, 
                               $conf{dbpasswd},
                               { CHARSET => ($conf{dbcharset}) ? $conf{dbcharset} : undef });
my $db = $sql->{db};

if ($conf{LANGS}) {
	$conf{LANGS} =~ s/\n//g;
	my(@lang_arr)=split(/;/, $conf{LANGS});
	%LANG = ();
	foreach my $l (@lang_arr) {
		my ($lang, $lang_name)=split(/:/, $l);
		$lang =~ s/^\s+//;
		$LANG{$lang}=$lang_name;
	 } 
}

my %INFO_HASH = ();

$INFO_HASH{SEL_LANGUAGE} = $html->form_select('language', 
                                { EX_PARAMS => 'onChange="selectLanguage()"',
 	                                SELECTED  => $html->{language},
 	                                SEL_HASH  => \%LANG,
 	                                NO_ID     => 1 });


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
 }
elsif ($FORM{FORGOT_PASSWD}) {
	password_recovery();
 }
elsif($#REGISTRATION > -1) {
  if($#REGISTRATION > 0 && ! $FORM{registration}) {
    foreach my $m (@REGISTRATION) {
      $html->{OUTPUT} .= $html->button($m, "module=$m", { BUTTON => 1 }) . ' ';
    }
   }

	my $m = $REGISTRATION[0];
	require "Abills/modules/$m/config";
	require "Abills/modules/$m/webinterface";
	$m = lc($m);
	my $function = $m . '_registration';
  $function->({ %INFO_HASH });
 }
else {

 }


$html->{METATAGS}= templates('metatags_client');  
print $html->header();
$OUTPUT{BODY}    = "$html->{OUTPUT}";
print $html->tpl_show(templates('form_client_start'), { %OUTPUT, TITLE_TEXT => $_REGISTRATION });


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

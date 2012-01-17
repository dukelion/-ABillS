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
require "Abills/templates.pl";
require "Abills/defs.conf";

use Abills::Base;
use Abills::SQL;
use Abills::HTML;
use Users;
use Paysys;
use Finance;
use Admins;
use Tariffs;
use Dv;






my $html = Abills::HTML->new({ CONF     => \%conf });
my $sql = Abills::SQL->connect($conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd});
my $db = $sql->{db};
#Operation status
my $status = '';

my $Paysys = Paysys->new($db, undef, \%conf);
my $Dv = Dv->new($db, $admin, \%conf);

my $admin = Admins->new($db, \%conf);
$admin->info($conf{SYSTEM_ADMIN_ID}, { IP => '127.0.0.1' });
my $payments = Finance->payments($db, $admin, \%conf);
my $users = Users->new($db, $admin, \%conf); 
my $tariffs = Tariffs->new($db, \%conf, $admin);

print "Content-Type: text/html\n\n";

$html->{language}=$FORM{language} if (defined($FORM{language}));
require "../language/$html->{language}.pl";

dv_registration();

#**********************************************************
#
#**********************************************************
sub dv_registration  {
	my ($attr) = @_;
	
	if ($FORM{reg}) {

    if ($FORM{EMAIL} !~ /^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/) {
      $html->message('err', $_ERROR, "$_WRONG_EMAIL");		
      return 0;
     }

    my $password = mk_unique_value(8);
    
    my $user=$users->add({ LOGIN       => $FORM{LOGIN}, 
    	                     CREATE_BILL => 1,
    	                     PASSWORD    => $password });
    my $message = '';
    if (! $user->{errno}) {
   	  my $UID = $user->{UID};
   	  $user = $user->info($UID);

      #3 personal info
      $user->pi_add({ UID   => "$UID", 
      	              FIO   => "$FORM{FIO}",
      	              EMAIL => "$FORM{EMAIL}" });

      if ($user->{errno}) {
	      $html->message('err', $_ERROR, "[$user->{errno}] $err_strs{$user->{errno}}");		
	      return 0;
       }

      #4 Dv
   	  $Dv->add({UID => $UID, TP_ID => $FORM{TP_ID} });
  		if (! $Dv->{errno}) {
	  	  $html->tpl_show(_include('dv_reg_complete', 'Dv'), { %$Dv, %FORM });

        #Send mail 
  	    my $message = $html->tpl_show(_include('dv_reg_complete_mail', 'Dv'), { %$Dv, %FORM, PASSWORD => "$password" }, { notprint => 1 });

  	    sendmail("$conf{ADMIN_MAIL}", "$FORM{EMAIL}", "REGISTRATION", 
              "$message", "$conf{MAIL_CHARSET}");

       }
      else {
        $html->message('err', $_ERROR, "[$Dv->{errno}] $err_strs{$Dv->{errno}}");
       }
		  return 0;
		 }
		else {
	    if ($user->{errno} == 7) {
        $html->message('err', $_ERROR, "$_USER_EXIST");		
	     }
	    else {
	      $html->message('err', $_ERROR, "[$user->{errno}] $err_strs{$user->{errno}}");		
	     }
		 }
		


	 }
	else {

		#$html->message('err', $_ERROR, "$_REGISTRATION");
	 }

	 $Dv->{TP_SEL} = $html->form_select('TP_ID', 
                                          { 
 	                                          SELECTED          => $FORM{TP_ID},
 	                                          SEL_MULTI_ARRAY   => $tariffs->list({ %LIST_PARAMS }),
 	                                          MULTI_ARRAY_KEY   => 0,
 	                                          MULTI_ARRAY_VALUE => 1,
 	                                        });
	
  $html->tpl_show(_include('dv_registration', 'Dv'), $Dv);

	return 0;
}

#!/usr/bin/perl -w
# Main  registration engine
#
#


use vars qw($begin_time %FORM %LANG %conf $CHARSET 
  @MODULES
  @REGISTRATION
  $PROGRAM
  $html
  $users
  $Bin
  $ERR_WRONG_DATA
  $ERR_CANT_CREATE_FILE
  $DATE
  $TIME
  $sid
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

my $admin = Admins->new($db, \%conf);
$admin->info($conf{SYSTEM_ADMIN_ID}, { IP => '127.0.0.1' });
my $payments = Finance->payments($db, $admin, \%conf);
$users = Users->new($db, $admin, \%conf); 
#my $Paysys = Paysys->new($db, undef, \%conf);


if (! defined( @REGISTRATION ) ) {
  print "Content-Type: text/html\n\n";
  print "Can't find modules services for registration";
	exit;
}

$html->{language}=$FORM{language} if ($FORM{language});
require "../language/$html->{language}.pl";
$INFO_HASH{SEL_LANGUAGE} = $html->form_select('language', 
                                { EX_PARAMS => 'onChange="selectLanguage()"',
 	                                SELECTED  => $html->{language},
 	                                SEL_HASH  => \%LANG,
 	                                NO_ID     => 1 });



if ($FORM{FORGOT_PASSWD}) {
	password_recovery();
 }
elsif ($FORM{qindex} && $FORM{qindex}==30) {
	form_address_sel();
 }
elsif($#REGISTRATION > -1) {
	my $m = $REGISTRATION[0];
	if ($FORM{module}) {
	  $m = $FORM{module};
	 }
  else {
    if($#REGISTRATION > 0 && ! $FORM{registration}) {
      foreach my $m (@REGISTRATION) {
        $html->{OUTPUT} .= $html->button($m, "module=$m", { BUTTON => 1 }) . ' ';
     }
    }
   }

  $conf{REGISTRATION_CAPTCHA}=1 if (! defined($conf{REGISTRATION_CAPTCHA}));

  if ($conf{REGISTRATION_CAPTCHA}) {
    eval { require Authen::Captcha; };
    if (! $@) {
      Authen::Captcha->import();
     }
    else {
    	print "Content-Type: text/html\n\n";
      print "Can't load 'Authen::Captcha'. Please Install it from http://cpan.org";
      print $html->pre($@);
      exit; 
     }

    if (! -d $base_dir.'/cgi-bin/captcha/') {
    	if (! mkdir("$base_dir/cgi-bin/captcha/")) {
    	   $html->message('err', $_ERROR, "$ERR_CANT_CREATE_FILE '$base_dir/cgi-bin/captcha/' $_ERROR: $!\n");
    	   $html->message('info', $_INFO, "$_NOT_EXIST '$base_dir/cgi-bin/captcha/'");
    	  }
     }
    else {
      
      # create a new object
      $INFO_HASH{CAPTCHA_OBJ} = Authen::Captcha->new(
         data_folder   => $base_dir.'/cgi-bin/captcha/',
         output_folder => $base_dir.'/cgi-bin/captcha/',
        );



      my $number_of_characters = 5;
      my $md5sum = $INFO_HASH{CAPTCHA_OBJ}->generate_code($number_of_characters);
      if($@) {
        print "Content-Type: text/html\n\n";
        print $@;
        exit;
       }
      $INFO_HASH{CAPTCHA}  = "
       <input type=hidden name=C value=$md5sum>
       <tr><td align=right><img src='/captcha/". $md5sum.".png'></td><td><input type='text' name='CCODE'></td></tr>";
     }
   }
  $INFO_HASH{RULES}    = $html->tpl_show(templates('form_accept_rules'), {  }, { OUTPUT2RETURN => 1 });
  $INFO_HASH{language} = $html->{language};
  
  if (! $FORM{DOMAIN_ID}) {
  	$FORM{DOMAIN_ID}=0;
  	$INFO_HASH{DOMAIN_ID}=0;
   }

	require "Abills/modules/$m/config";
	require "Abills/modules/$m/webinterface";

	if (-f "../Abills/modules/Msgs/lng_$html->{language}.pl") {
	  require "../Abills/modules/Msgs/lng_$html->{language}.pl";
	 }

	$m = lc($m);
	my $function = $m . '_registration';
  my $return = $function->({ %INFO_HASH });
  

  #Send E-mail to admin after registration
  if ($return && $return == 2) {
  	my $message = qq{
New Registrations
=========================================
Username: $FORM{LOGIN}
Fio:      $FORM{FIO}
DATE:     $DATE $TIME
IP:       $ENV{REMOTE_ADDR}
Module:   $m
E-Mail:   $FORM{EMAIL}
=========================================

};

    if ($conf{REGISTRATION_EXTERNAL}) {
    	if (! _external($conf{REGISTRATION_EXTERNAL}, { %FORM }) ) {
         #return 0;
       }
     }

    sendmail("$conf{ADMIN_MAIL}", "$conf{ADMIN_MAIL}", "New registrations", 
              "$message", "$conf{MAIL_CHARSET}", "");
   }
  
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
     
    my $list = $users->list({ PHONE => '*', %FORM });
  	if ($users->{TOTAL} > 0) {
  		my @u       = @$list;
	    my $message = '';
	    my $email   = $FORM{EMAIL} || '';
      my $phone   = $list->[0][3+$users->{SEARCH_FIELDS_COUNT}];
      my $uid     = $list->[0][5+$users->{SEARCH_FIELDS_COUNT}];
      
      if ($FORM{LOGIN} && ! $FORM{EMAIL}) {
      	$email    = $u[0][7+$users->{SEARCH_FIELDS_COUNT}];
       }

	    foreach my $line (@u) {
         if ($FORM{EMAIL}) {
           $uid = $line->[5+$users->{SEARCH_FIELDS_COUNT}];
          }
	       $users->info($uid, { SHOW_PASSWORD => 1 });
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
	   	  $html->message('info', $_INFO, "E-Mail $_NOT_EXIST");
	     }
	
	
	
      if ($FORM{SEND_SMS}) {
        require "Abills/modules/Sms/webinterface";
        if(sms_send({ NUMBER  => $phone,
                   MESSAGE => $message,
                   UID     => $uid 
                 })) {
          $html->message('info', "$_INFO", "SMS $_SENDED");        	
         }
       }      
	    return 0;
	   }
	  else {
		  $html->message('err', $_ERROR, "$_NOT_EXIST");
	   }
	}
	
	my %info = ();
  if (in_array('Sms', \@MODULES) ) {
    $info{EXTRA_PARAMS} = $html->tpl_show(_include('sms_check_form', 'Sms'), undef, { OUTPUT2RETURN => 1 });
   }

	$html->tpl_show(templates('form_forgot_passwd'), \%info);
}


#**********************************************************
# Make external operations
#**********************************************************
sub _external {
  my ($file, $attr) = @_;

  my $arguments = '';
  while(my ($k, $v) = each %$attr) {
        if ($k ne '__BUFFER' && $k =~ /[A-Z0-9_]/) {
                $arguments .= " $k=\"$v\"";
         }
   }

  my $result = `$file $arguments`;
  my ($num, $message)=split(/:/, $result, 2);
  if ($num == 1) {
        $html->message('info', "_EXTERNAL $_ADDED", "$message");
        return 1;
   }
  else {
          $html->message('err', "_EXTERNAL $_ERROR", "[$num] $message");
    return 0;
   }
}



#**********************************************************
# Ajax address form
#**********************************************************
sub form_address_sel {

   print "Content-Type: text/html\n\n";
   my $js_list = ''; 	
 	 my $id        =   $FORM{'JsHttpRequest'};
   my $jsrequest =   $FORM{'jsrequest'};
   ($id, undef)  = split(/-/,$id);   	

   if ($FORM{STREET}) {
     my $list = $users->build_list({ STREET_ID => $FORM{STREET}, PAGE_ROWS => 10000 });
     if ($users->{TOTAL} > 0) {
       foreach my $line (@$list) {
         $js_list .= "<option class='spisok' value='p3|$line->[0]|l3|$line->[6]'>$line->[0]</option>"; 
        }
      }
     else {
       $js_list .= "<option class='spisok' value='p3||l3|0'>$_NOT_EXIST</option>"; 
      }

      my $size = ($users->{TOTAL} > 10) ? 10 : $users->{TOTAL};
      $size = 2 if ($size < 2); 
      $js_list = "<select style='width: inherit;' size='$size' onchange='insert(this)' id='build'>".
        $js_list . "</select>";

     print qq{JsHttpRequest.dataReady({ "id": "$id", 
   	     "js": { "list": "$js_list" }, 
         "text": "" }) };
    }
   elsif ($FORM{DISTRICT_ID}) {
     my $list = $users->street_list({ DISTRICT_ID => $FORM{DISTRICT_ID}, PAGE_ROWS => 1000 });
     if ($users->{TOTAL} > 0) {
       foreach my $line (@$list) {
         $js_list .= "<option class='spisok' value='p2|$line->[1]|l2|$line->[0]'>$line->[1]</option>"; 
        }
      }
     else {
       $js_list .= "<option class='spisok' value='p2||l2|0'>$_NOT_EXIST</option>"; 
      }

     my $size = ($users->{TOTAL} > 10) ? 10 : $users->{TOTAL};
     $size = 2 if ($size < 2);
     $js_list = "<select style='width: inherit;' size='$size' onchange='insert(this)' id='street'>".
         $js_list . "</select>";

     print qq{JsHttpRequest.dataReady({ "id": "$id", 
   	    "js": { "list": "$js_list" }, 
        "text": "" }) };
    } 	
   else {
     my $list = $users->district_list({ %LIST_PARAMS, PAGE_ROWS => 1000 });
     foreach my $line (@$list) {
     	 $js_list .= "<option class='spisok' value='p1|$line->[1]|l1|$line->[0]'>$line->[1]</option>"; 
      }

     my $size = ($users->{TOTAL} > 10) ? 10 : $users->{TOTAL};
     $size=2 if ($size < 2);
     $js_list = "<select style='width: inherit;' size='$size' onchange='insert(this)' id='block'>".
       $js_list . "</select>";

     print qq{JsHttpRequest.dataReady({ "id": "$id", 
   	    "js": { "list": "$js_list" }, 
        "text": "" }) };
    }
 	 exit;
}


#**********************************************************
# Get function index
#
# get_function_index($function_name, $attr) 
#**********************************************************
sub get_function_index  {
  my ($function_name, $attr) = @_;
  my $function_index = 0;
  
  foreach my $k (keys %functions) { 	
  	my $v = $functions{$k};
    if ($v eq "$function_name") {
       $function_index = $k;
       if ($attr->{ARGS} && $attr->{ARGS} ne $menu_args{$k}) {
       	 next;
        }
       last;
     }
   }

  return $function_index;
}

1
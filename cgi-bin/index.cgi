#!/usr/bin/perl 
# ABillS User Web interface
#


use vars qw($begin_time %LANG $CHARSET @MODULES $USER_FUNCTION_LIST 
$UID $user $admin 
$sid

@ones
@twos
@fifth
@one
@onest
@ten
@tens
@hundred
@money_unit_names
@EX_PAYMENT_METHODS
%menu_items
%menu_args
);

BEGIN {
 my $libpath = '../';
 
 $sql_type='mysql';
 unshift(@INC, $libpath ."Abills/$sql_type/");
 unshift(@INC, $libpath ."Abills/");
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
require "Abills/defs.conf";
use Abills::Base;
use Abills::SQL;
use Abills::HTML;
use Users;
use Finance;


$html = Abills::HTML->new( { IMG_PATH => 'img/',
	                           NO_PRINT => 1,
	                           CONF     => \%conf,
	                           CHARSET  => $conf{default_charset},
	                       });

my $sql = Abills::SQL->connect($conf{dbtype}, 
                               $conf{dbhost}, 
                               $conf{dbname}, 
                               $conf{dbuser}, 
                               $conf{dbpasswd},
                               { CHARSET => ($conf{dbcharset}) ? $conf{dbcharset} : undef });
my $db = $sql->{db};
$html->{language}=$FORM{language} if (defined($FORM{language}) && $FORM{language} =~ /[a-z_]/);

require "../language/$html->{language}.pl";
$sid = $FORM{sid} || ''; # Session ID
$html->{CHARSET}=$CHARSET if ($CHARSET);

my $cookies_time=gmtime(time()+$conf{web_session_timeout})." GMT";

if ((length($COOKIES{sid})>1) && (! $FORM{passwd})) {
  $COOKIES{sid} =~ s/\"//g;
  $COOKIES{sid} =~ s/\'//g;
  $sid = $COOKIES{sid};
}
elsif((length($COOKIES{sid})>1) && (defined($FORM{passwd}))){
	$html->setCookie('sid', "", "$cookies_time", $web_path, $domain, $secure);
	$COOKIES{sid}=undef;
}

#Cookie section ============================================
if (defined($FORM{colors})) {
  my $cook_colors = (defined($FORM{default})) ?  '' : $FORM{colors};
  $html->setCookie('colors', "$cook_colors", "Fri, 1-Jan-2038 00:00:01", $web_path, $domain, $secure);
 }
#Operation system ID
$html->setCookie('OP_SID', "$FORM{OP_SID}", "$cookies_time", $web_path, $domain, $secure) if (defined($FORM{OP_SID}));
$html->setCookie('language', "$FORM{language}", "Fri, 1-Jan-2038 00:00:01", $web_path, $domain, $secure) if (defined($FORM{language}));

if (defined($FORM{sid})) {
  $html->setCookie('sid', "$FORM{sid}", "$cookies_time", $web_path, $domain, $secure);
  $COOKIES{sid}=$FORM{sid};
}
#===========================================================

require Admins;
Admins->import();
$admin = Admins->new($db, \%conf);
$admin->info($conf{USERS_WEB_ADMIN_ID} ? $conf{USERS_WEB_ADMIN_ID} : $conf{SYSTEM_ADMIN_ID}, { DOMAIN_ID => $FORM{DOMAIN_ID}, IP => $ENV{REMOTE_ADDR} });
$admin->{SESSION_IP}=$ENV{REMOTE_ADDR};
$conf{WEB_TITLE} = $admin->{DOMAIN_NAME} if ($admin->{DOMAIN_NAME});

require "Abills/templates.pl";
$html->{METATAGS}=templates('metatags_client');

my $uid = 0;
my $page_qs;
my %OUTPUT = ();
my $login  = $FORM{user} || '';
my $passwd = $FORM{passwd} || '';
delete($conf{PASSWORDLESS_ACCESS}) if ($FORM{xml});

$user=Users->new($db, $admin, \%conf); 


($uid, $sid, $login) = auth("$login", "$passwd", "$sid");

my %uf_menus = ();

if ($uid > 0) {
  $UID = $uid;
  my $default_index = 10;
  #Quick Amon Alive Update
  # $ENV{HTTP_USER_AGENT} =~ /^AMon /
  if ($FORM{ALIVE}) {
 	  require "Abills/modules/Ipn/webinterface";
    print $html->header();
    $LIST_PARAMS{LOGIN}=$user->{LOGIN};
    ipn_user_activate();
    $OUTPUT{BODY}=$html->{OUTPUT};    
    print $html->tpl_show(templates('form_client_start'), \%OUTPUT);
 	  exit;
   }

  accept_rules() if ($conf{ACCEPT_RULES});
  my @m = (
   "10:0:$_USER_INFO:form_info:::",
   );
  if ($conf{user_finance_menu}) {
     push @m, "40:0:$_FINANCES:form_payments:::";
     push @m, "41:40:$_FEES:form_fees:::";
     push @m, "42:40:$_PAYMENTS:form_payments:::";
     if ($conf{MONEY_TRANSFER}) {
     	 push @m, "43:40:$_MONEY_TRANSFER:form_money_transfer:::";
      }
   }
  push @m, "17:0:$_PASSWD:form_passwd:::" if($conf{user_chg_passwd});
  mk_menu(\@m);

  $html->{SID}=$sid;
  
  if (! $FORM{pdf} && -f '../Abills/templates/_form_client_custom_menu.tpl') {
    $OUTPUT{MENU}=$html->tpl_show(templates('form_client_custom_menu'), $user, { OUTPUT2RETURN => 1 });
   }
  else {
    if ($conf{MENU_NEW}) {
 	    (undef, $OUTPUT{MENU}) = $html->menu2(\%menu_items, \%menu_args, undef, 
        { EX_ARGS         => "&sid=$sid", 
     	    ALL_PERMISSIONS => 1,
       	  FUNCTION_LIST   => \%functions
        });
     }
    else {
      (undef, $OUTPUT{MENU}) = $html->menu(\%menu_items, \%menu_args, undef, 
       { EX_ARGS         => "&sid=$sid", 
     	   ALL_PERMISSIONS => 1,
     	  FUNCTION_LIST   => \%functions
       });
     }
   }

  if ($html->{ERROR}) {
  	$html->message('err',  $_ERROR, "$html->{ERROR}");
  	exit;
   }

  $OUTPUT{DATE} = $DATE;
  $OUTPUT{TIME} = $TIME;
  $OUTPUT{LOGIN}= $login;
  $OUTPUT{IP}   = $ENV{REMOTE_ADDR};
  $pages_qs     = "&UID=$user->{UID}&sid=$sid";
  $OUTPUT{STATE}= ($user->{DISABLE}) ? $html->color_mark("$_DISABLE", $_COLORS[6])  : $_ENABLE;
  
  if ($COOKIES{lastindex}) {
  	$index=int($COOKIES{lastindex});
    $html->setCookie('lastindex', '', "Fri, 1-Jan-2038 00:00:01", $web_path, $domain, $secure);
   }

  $LIST_PARAMS{UID}  = $user->{UID};
  $LIST_PARAMS{LOGIN}= $user->{LOGIN};

  $index = int($FORM{qindex}) if ($FORM{qindex});
  print $html->header() if ($FORM{header});

  if ($FORM{qindex}) {
    if(defined($module{$FORM{qindex}})) {
 	   	load_module($module{$FORM{qindex}}, $html);
     }

    $functions{$FORM{qindex}}->();
    print "$html->{OUTPUT}";
    exit;
   }

  if(defined($module{$index})) {
 	 	load_module($module{$index}, $html);
   }

  $index=$default_index if ($index == 0);

  if (defined($functions{$index})) {
    if (! $FORM{index} && $user->{DEPOSIT} + $user->{CREDIT} < 0) {
      form_info({ NEG_DEPOSIT => 1 });
     }
    else {
      $functions{$index}->();
     }
   }
  else {
    $functions{$default_index}->();
   }

  $OUTPUT{BODY}=$html->{OUTPUT};
  $html->{OUTPUT}='';
  if ($conf{AMON_UPDATE}  && $ENV{HTTP_USER_AGENT} =~ /AMon \[(\S+)\]/) {
  	$user_version = $1;
  	my ($u_url, $u_version, $u_checksum)=split(/\|/, $conf{AMON_UPDATE}, 3);
    if ($u_version > $user_version) {
    	$OUTPUT{BODY} = "<AMON_UPDATE url=\"$u_url\" version=\"$u_version\" checksum=\"$u_checksum\" />\n". $OUTPUT{BODY};
     }
   }
  
  $OUTPUT{STATE} = ($user->{SERVICE_STATUS}) ? $user->{SERVICE_STATUS}  : $OUTPUT{STATE};
  $OUTPUT{BODY}  = $html->tpl_show(templates('form_client_main'), \%OUTPUT);
 }
else {
  form_login();
}

print $html->header();
$OUTPUT{BODY}="$html->{OUTPUT}";
print $html->tpl_show(templates('form_client_start'), \%OUTPUT);


$html->test() if ($conf{debugmods} =~ /LOG_DEBUG/);


#==========================================================
#
#==========================================================
sub mk_menu {
  my ($menu) = @_;
 
  my $maxnumber  = 0;
  
  foreach my $line ( @$menu ) {
	  my ($ID, $PARENT, $NAME, $FUNTION_NAME, $SHOW_SUBMENU, $OP)=split(/:/, $line);
    $menu_items{$ID}{$PARENT}=$NAME;
    $menu_names{$ID} = $NAME;
    $functions{$ID}  = $FUNTION_NAME if ($FUNTION_NAME  ne '');
    $maxnumber=$ID if ($maxnumber < $ID);
   }

  foreach my $m (@MODULES) {
    if(my $return = do "Abills/modules/$m/config") {
     }

    my %module_fl=();

    next if (keys %USER_FUNCTION_LIST < 1);
    my @sordet_module_menu = sort keys %USER_FUNCTION_LIST;

    foreach my $line (@sordet_module_menu) {
      $maxnumber++;
      my($ID, $SUB, $NAME, $FUNTION_NAME, $ARGS)=split(/:/, $line, 5);
      $ID = int($ID);
      my $v = $USER_FUNCTION_LIST{$line};
      $module_fl{"$ID"}=$maxnumber;
      
      if ($index < 1 && $ARGS eq 'defaultindex') {
        $default_index=$maxnumber;
        $index=$default_index;
       }
      elsif ($ARGS ne '' && $ARGS ne 'defaultindex') {
        $menu_args{$maxnumber}=$ARGS;
       }
     
      if($SUB > 0) {
        $menu_items{$maxnumber}{$module_fl{$SUB}}=$NAME;
       } 
      else {
        $menu_items{$maxnumber}{$v}=$NAME;
        if ($SUB == -1) {
          $uf_menus{$maxnumber}=$NAME;
         }
      }
      $menu_names{$maxnumber} = $NAME;
      $functions{$maxnumber}  = $FUNTION_NAME if ($FUNTION_NAME  ne '');
      $module{$maxnumber}     = $m;
    }
    %USER_FUNCTION_LIST = ();
  }

  if (! $conf{PASSWORDLESS_ACCESS}) {
    $menu_names{1000}    = "$_LOGOUT";
    $functions{1000}     = 'logout';
    $menu_items{1000}{0} = $_LOGOUT;
  }
}

#**********************************************************
# form_stats
#**********************************************************
sub form_info {
  my ($attr) = @_;

  use POSIX qw(strftime);
  
  $admin->{SESSION_IP}=$ENV{REMOTE_ADDR}; 
  my $Payments = Finance->payments($db, $admin, \%conf);
  
  #Credit functions
  if ( $conf{user_credit_change} ) {
    my ($sum, $days, $price, $month_changes, $payments_expr) = split(/:/, $conf{user_credit_change}) ;
    $month_changes = 0 if (!$month_changes);
    my $credit_date = strftime "%Y-%m-%d", localtime(time + int($days) * 86400);

    if (in_array('Dv', \@MODULES) ) {
        require "Abills/modules/Dv/webinterface";
        my $Dv       = Dv->new($db, $admin, \%conf);
        $Dv->info($user->{UID});
        $sum = $Dv->{TP_CREDIT} if ($Dv->{TP_CREDIT} > 0);
     }

    if ($month_changes) {
      my ($y, $m, $d) = split(/\-/, $DATE);
      $admin->action_list({ UID       => $user->{UID},
      	                    TYPE      => 5,
      	                    AID	      => $admin->{AID},
      	                    FROM_DATE => "$y-$m-01",
      	                    TO_DATE   => "$y-$m-31"
      	                   });
      
      if ($admin->{TOTAL} >= $month_changes) {
        $user->{CREDIT_CHG_BUTTON} = $html->color_mark("$ERR_CREDIT_CHANGE_LIMIT_REACH. $_TOTAL: $admin->{TOTAL}/$month_changes", $_COLORS[6]);
        #$FORM{change_credit}=undef;
        $sum = -1;
       }
     }
    #PERIOD=days;MAX_CREDIT_SUM=sum;MIN_PAYMENT_SUM=sum;
    if ($payments_expr && $sum != -1) {
    	my %params = (PERIOD          => 0,
    	              MAX_CREDIT_SUM  => 1000,
    	              MIN_PAYMENT_SUM => 1,
    	              PERCENT         => 100
    	              );
    	my @params_arr = split(/;/, $payments_expr);
    	
    	foreach my $line (@params_arr) {
    		my ($k, $v)=split(/=/, $line);
    		$params{$k}=$v;
    	 }
      
      $Payments->list({ UID          => $user->{UID}, 
      	                PAYMENT_DAYS => ">$params{PERIOD}",
      	                SUM          => ">$params{MIN_PAYMENT_SUM}"
      	                });
    	
    	if ($Payments->{TOTAL} > 0) {
    	  $sum = $Payments->{SUM} / 100 *  $params{PERCENT};
    	  if ($sum > $params{MAX_CREDIT_SUM}) {
    		  $sum=$params{MAX_CREDIT_SUM};
    	   }
    	 }
    	else {
    		$sum = 0;
    	 }
     }
    
    if ($user->{DISABLE}) {
    	
     }
    elsif ($user->{CREDIT} < sprintf("%.2f", $sum)) {
       if ($FORM{change_credit}) {
         $user->change($user->{UID}, { UID         => $user->{UID},
                                       CREDIT      => $sum,
                                       CREDIT_DATE => $credit_date
                                     });
         if (! $user->{errno}) {
            $html->message('info', "$_CHANGED", " $_CREDIT: $sum");
            if ($price && $price > 0) {
              my $Fees = Finance->fees($db, $admin, \%conf);
              $Fees->take($user, $price, { DESCRIBE => "$_CREDIT $_ENABLE" } );              
             }
            cross_modules_call('_payments_maked', { USER_INFO => $user, QUITE => 1 }); 
            if ($conf{external_userchange}) {
              if (! _external($conf{external_userchange}, $user) ) {
     	          return 0;
               }
             }
          }

         $user->{CREDIT}     = $sum;
         $user->{CREDIT_DATE}= $credit_date;
        }
       else {
         $user->{CREDIT_CHG_BUTTON} =  $html->button("$_SET $_CREDIT: ". sprintf("%.2f", $sum) . 
           (($price && $price > 0) ? sprintf(" (%s: %.2f)", "$_CREDIT $_CHANGE $_PRICE", $price) : undef),  
           "index=$index&sid=$sid&change_credit=$sum", { BUTTON => 1 });
        }
     }
   }
  
  if ($attr->{NEG_DEPOSIT}) {
     form_neg_deposit($user) ;
    }
  else {
  	if (! $conf{DOCS_SKIP_NEXT_PERIOD_ACCOUNT}) {
  	  if (in_array('Docs', \@MODULES) ) {
    	  $FORM{ALL_SERVICES}=1;
    	  load_module('Docs', $html);
    	  docs_invoice();
       }
     }
   }
  
  if ($conf{user_chg_pi}) {
  	if ($FORM{chg}) {
  		$user->pi();
  		$user->{ACTION}='change';
  		$user->{LNG_ACTION}=$_CHANGE;
  		$html->tpl_show(templates('form_chg_client_info'), $user);
  		return 0;
  	 }
  	elsif ($FORM{change}) {
      $user->pi_change({  %FORM, UID => $user->{UID} });
      if (! $user->{errno}) {
        $html->message('info', $_CHANGED, "$_CHANGED");
       }
  	 }
   }

  $user->pi();

  $LIST_PARAMS{PAGE_ROWS}=1;
  $LIST_PARAMS{DESC}='desc';
  $LIST_PARAMS{SORT}=1;
  my $list = $Payments->list( { %LIST_PARAMS } );
  
  $user->{PAYMENT_DATE}=$list->[0]->[2];
  $user->{PAYMENT_SUM}=$list->[0]->[4];
  if ($conf{EXT_BILL_ACCOUNT} && $user->{EXT_BILL_ID} > 0) {
    $user->{EXT_DATA}=$html->tpl_show(templates('form_ext_bill'), 
                                             $user, { OUTPUT2RETURN => 1 });
   }
  
  $user->{STATUS} = ($user->{DISABLE}) ? $html->color_mark("$_DISABLE", $_COLORS[6])  : $_ENABLE;
  my $deposit = sprintf("%.2f", $user->{DEPOSIT});
  $user->{DEPOSIT} = ($deposit < $user->{DEPOSIT}) ? $deposit + 0.01 : $deposit;
  my $sum  = ($user->{DEPOSIT} < 0) ? abs($user->{DEPOSIT}*2) : 0;
  $pages_qs = "&SUM=$sum&sid=$sid";
  if (in_array('Docs', \@MODULES) ) {
  	my $fn_index = get_function_index('docs_invoices_list');
    $user->{DOCS_ACCOUNT} = $html->button("$_INVOICE_CREATE", "index=$fn_index$pages_qs", { BUTTON => 1} );
   }

  if (in_array('Paysys', \@MODULES) ) {
  	my $fn_index = get_function_index('paysys_payment');
  	$user->{PAYSYS_PAYMENTS} = $html->button("$_BALANCE_RECHARCHE", "index=$fn_index$pages_qs", { BUTTON => 1} );
   }

  #Show users info field
  my $i=-1; 
  foreach my $field_id ( @{ $user->{INFO_FIELDS_ARR} } ) {
    my($position, $type, $name, $user_portal)=split(/:/, $user->{INFO_FIELDS_HASH}->{$field_id});
    $i++;
    next if ($user_portal == 0);
      
    my $extra = '';
    if ($field_id eq '_rating') {
      $extra = $html->button($_RATING, "index=". get_function_index('dv_rating_user'), { BUTTON => 1 });
     }
  	$user->{INFO_FIELDS}.= "<tr><td>". ( eval "\"$name\"" ). ":</td><td valign=center>$user->{INFO_FIELDS_VAL}->[$i] $extra</td></tr>\n";
   }

  $html->tpl_show(templates('form_client_info'), $user);

  if ($conf{user_chg_pi}) {
    $html->form_main({ CONTENT => $html->form_input('chg', "$_CHANGE", { TYPE => 'SUBMIT', OUTPUT2RETURN => 1 } ),
	                     HIDDEN  => { 
	                                 sid   => $sid,
	                                 index => "$index"
	                    }});
   }


  if (in_array('Dv', \@MODULES) ) {
     require "Abills/modules/Dv/webinterface";
     dv_user_info();
   }
}


#**********************************************************
# form_login  
#**********************************************************
sub form_login {
 my %first_page = ();

 if ($conf{tech_works}) {
 	  $html->message('info', $_INFO, "$conf{tech_works}");
 	  return 0;
  }
 
#Make active lang list
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
 
 my %QT_LANG = (
 byelorussian	=> 22,
 bulgarian    => 20,
 english      => 31,
 french       => 37,
 polish       => 90,
 russian      => 96,
 ukraine      => 129,
 );
 
 $first_page{SEL_LANGUAGE} = $html->form_select('language', 
                                { EX_PARAMS  => 'onChange="selectLanguage()"',
 	                                SELECTED   => $html->{language},
 	                                SEL_HASH   => \%LANG,
 	                                NO_ID      => 1,
 	                                EXT_PARAMS => { qt_locale => \%QT_LANG }
 	                              });

 $OUTPUT{BODY} = $html->tpl_show(templates('form_client_login'), \%first_page);
}

#*******************************************************************
# Auth throught the radius or ftp
#*******************************************************************
sub auth_radius {
	my ($login, $passwd, $sid)=@_;
  my $res = 0;
  
  my $check_access = $conf{check_access};

  #check password throught ftp access
  if ($conf{check_access} && $conf{check_access}{NAS_IP} =~ /(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}):21/) {
  	my $ftpserver = $1;
    if ($res < 1) {
      eval { require Net::FTP; };
      if (! $@) {
        Net::FTP->import();
        my $ftp = Net::FTP->new($ftpserver) || die "could not connect to the server '$ftpserver' $!";
        $res = $ftp->login("$login", "$passwd");
        $ftp->quit();
       }
      else {
        $html->message('info', $_INFO, "Install 'libnet' module from http://cpan.org");
       }
     }
   }
  elsif ($check_access->{NAS_SECRET}) {
    use Abills::Radius;
    $conf{'dictionary'} = '../Abills/dictionary' if (! exists($conf{'dictionary'}));
    $r = new Radius(Host   => "$check_access->{NAS_IP}",
                    Secret => "$check_access->{NAS_SECRET}"
                    ) or die ("Can't connect to '$check_access->{NAS_IP}' $!");

    $r->load_dictionary($conf{'dictionary'}) || die("Cannot load dictionary '$conf{dictionary}' !");
 
    if($r->check_pwd("$login", "$passwd", "$check_access->{NAS_FRAMED_IP}")) {
      $res = 1;
     }
   }

	return $res;
}

#*******************************************************************
# FTP authentification
# auth($login, $pass)
#*******************************************************************
sub auth { 
 my ($login, $password, $sid) = @_;
 my $uid = 0;
 my $ret = 0;
 my $res = 0;
 my $REMOTE_ADDR = $ENV{'REMOTE_ADDR'} || '';
 my $HTTP_X_FORWARDED_FOR = $ENV{'HTTP_X_FORWARDED_FOR'} || '';
 my $ip = "$REMOTE_ADDR/$HTTP_X_FORWARDED_FOR";

 $conf{PASSWORDLESS_ACCESS}=$ENV{USER_CHECK_DEPOSIT} if (! $conf{PASSWORDLESS_ACCESS});

#Passwordless Access
if ($conf{PASSWORDLESS_ACCESS}) {
    require  Dv_Sessions;
    Dv_Sessions->import();
    my $sessions = Dv_Sessions->new($db, $admin, \%conf);
	  my $list = $sessions->online({ FRAMED_IP_ADDRESS => "$REMOTE_ADDR" });

    if ($sessions->{TOTAL} == 1) {
      $login   = $list->[0]->[0];
      $ret     = $list->[0]->[11];
      #$time    = time;
      $sid     = mk_unique_value(14);
      $user->info($ret);

      $user->{REMOTE_ADDR}=$REMOTE_ADDR;
      return ($ret, $sid, $login);
    }
   else {
     require  Dv;
     Dv->import();
     my $Dv   = Dv->new($db, $admin, \%conf);
	   my $list = $Dv->info(0, { IP => "$REMOTE_ADDR" });

     if ($Dv->{TOTAL} == 1) {
       $login   = $Dv->{LOGIN} || '';
       $ret     = $Dv->{UID};
       #$time    = time;
       $sid     = mk_unique_value(14);
       $user->info($ret);
       $user->{REMOTE_ADDR}=$REMOTE_ADDR;
       return ($ret, $sid, $user->{LOGIN});      
      }
    }
  }

if ($index == 1000) {
  $user->web_session_del({ SID => $FORM{sid} });
  return 0;
 }
elsif (length($sid) > 1) {
  
  $user->web_session_info({ SID => $sid });

  if ($user->{TOTAL} < 1) { 
    #$html->message('err', "$_ERROR", "$_NOT_LOGINED");	
    return 0; 
   }
  elsif ($user->{errno}) {
  	$html->message('err', "$_ERROR", "$_ERROR");
  	return 0;
   }
  elsif ($conf{web_session_timeout} < $user->{ACTIVATE}) {
  	$html->message('info', "$_INFO", 'Session Expire');	
  	$user->web_session_del({ SID => $sid });
  	return 0;
   }
  elsif($user->{REMOTE_ADDR} ne $REMOTE_ADDR) {
    $html->message('err', "$_ERROR", 'WRONG IP');	
    return 0; 
   }
  
  $user->info($user->{UID});

  return ($user->{UID}, $sid, $user->{LOGIN});
 }
else {
  return 0 if (! $login  || ! $password);
  
  if ($conf{wi_bruteforce}) {
  	$user->bruteforce_list({ LOGIN    => $login,
  		                       PASSWORD => $password,
  		                       CHECK    => 1 });

  	if ($user->{TOTAL} > $conf{wi_bruteforce}) {
  		$OUTPUT{BODY} = $html->tpl_show(templates('form_bruteforce_message'), undef);
  		return 0;
  	 }
   }
  
  #check password from RADIUS SERVER if defined $conf{check_access}
  if ($conf{check_access}) {
    $res = auth_radius("$login", "$password")
   }
  #check password direct from SQL
  else {
    $res = auth_sql("$login", "$password") if ($res < 1);
   }
}

#Get user ip
if (defined($res) && $res > 0) {
  $user->info(0, { LOGIN => "$login" });

  if ($user->{TOTAL} > 0) {
    $sid = mk_unique_value(16);
    $ret = $user->{UID};
    $user->{REMOTE_ADDR}=$REMOTE_ADDR;
    $user->web_session_add({ UID         => $user->{UID},
    	                       SID         => $sid,
    	                       LOGIN       => $login,
    	                       REMOTE_ADDR => $REMOTE_ADDR,
    	                       EXT_INFO    => $ENV{HTTP_USER_AGENT}
    	                     });
   }
  else {
    $html->message('err', "$_ERROR", "$ERR_WRONG_PASSWD");
   }
 }
else {
   $user->bruteforce_add({ LOGIN       => $login, 
 	                         PASSWORD    => $password,
    	                     REMOTE_ADDR => $REMOTE_ADDR,
    	                     AUTH_STATE  => $ret });

   $html->message('err', "$_ERROR", "$ERR_WRONG_PASSWD");
   $ret = 0;
 }

 return ($ret, $sid, $login);
}

#*******************************************************************
# Authentification from SQL DB
# auth_sql($login, $password)
#*******************************************************************
sub auth_sql {
 my ($login, $password) = @_;
 my $ret = 0;

 $user->info(0, {
 	                   LOGIN => "$login", 
 	                   PASSWORD => "$password" }
 	               ); 

if ($user->{TOTAL} < 1) {
  #$html->message('err', $_ERROR, "$_NOT_FOUND");
}
elsif($user->{errno}) {
	$html->message('err', $_ERROR, "$user->{errno} $user->{errstr}");
}
else {
  $ret = $user->{UID};
}

 return $ret;	
}


#**********************************************************
# form_passwd($attr)
#**********************************************************
sub form_passwd {
 my ($attr)=@_;
 my $hidden_inputs;

 $conf{PASSWD_SYMBOLS}='\[a-zA-Z0-9_\-\$\#\@\!\*\&\^\%\]' if (! $conf{PASSWD_SYMBOLS}); 

if ($FORM{newpassword} eq '') {

 }
elsif (length($FORM{newpassword}) < $conf{PASSWD_LENGTH}) {
  $html->message('err', $_ERROR, $ERR_SHORT_PASSWD);
 }
elsif ($FORM{newpassword} !~ /^[$conf{PASSWD_SYMBOLS}]*$/) {
  $html->message('err', $_ERROR, $ERR_SYMBOLS_PASSWD);
 }
elsif ($FORM{newpassword} eq $FORM{confirm}) {
  %INFO = ( PASSWORD => $FORM{newpassword},
            UID      => $user->{UID},
            DISABLE  => $user->{DISABLE}
            );

  $user->change($user->{UID}, { %INFO });

  if(!$user->{errno}) {
  	 $html->message('info', $_INFO, "$_CHANGED");	
   }
  else {
  	 $html->message('err', $_ERROR, "[$user->{errno}] $err_strs{$user->{errno}}");	
   }
  return 0;
}
elsif($FORM{newpassword} ne $FORM{confirm}) {
  $html->message('err', $_ERROR, $ERR_WRONG_CONFIRM);
}

 my $password_form;
 $password_form->{ACTION}      = 'change';
 $password_form->{LNG_ACTION}  = "$_CHANGE";
 $password_form->{GEN_PASSWORD}= mk_unique_value(8);
 $html->tpl_show(templates('form_password'), $password_form);

 return 0;
}

#**********************************************************
#
# Report main interface
#**********************************************************
sub accept_rules {
  my ($attr) = @_;

  $user->pi({ UID => $user->{UID} });
  if ($FORM{ACCEPT} &&  $FORM{accept}) {
    if ($user->{TOTAL} == 0) {
      $user->pi_add({ UID => $user->{UID}, ACCEPT_RULES => 1 });
     }
    else {
      $user->pi_change({ UID => $user->{UID}, ACCEPT_RULES => 1 });    
     }

    return 0;
  }


  if ($user->{ACCEPT_RULES}) {

    return 0;
   }

  $html->tpl_show(templates('form_accept_rules'), $user);
	
  print $html->header();
  $OUTPUT{BODY}="$html->{OUTPUT}";
  print $OUTPUT{BODY};
  exit;
}

#**********************************************************
#
# Report main interface
#**********************************************************
sub reports {
 my ($attr) = @_;
 
my $EX_PARAMS; 
my ($y, $m, $d);
$type='DATE';

if ($FORM{MONTH}) {
  $LIST_PARAMS{MONTH}=$FORM{MONTH};
	$pages_qs="&MONTH=$LIST_PARAMS{MONTH}";
 }
elsif($FORM{allmonthes}) {
	$type='MONTH';
	$pages_qs="&allmonthes=1";
 }
else {
	($y, $m, $d)=split(/-/, $DATE, 3);
	$LIST_PARAMS{MONTH}="$y-$m";
	$pages_qs="&MONTH=$LIST_PARAMS{MONTH}";
}


if ($LIST_PARAMS{UID}) {
	 $pages_qs.="&UID=$LIST_PARAMS{UID}";
 }
else {
  if ($FORM{GID}) {
	  $LIST_PARAMS{GID}=$FORM{GID};
    $pages_qs="&GID=$FORM{GID}";
    delete $LIST_PARAMS{GIDS};
   }
}

my @rows = ();

my $FIELDS='';

if ($attr->{FIELDS}) {
  my %fields_hash = (); 
  if (defined($FORM{FIELDS})) {
  	my @fileds_arr = split(/, /, $FORM{FIELDS});
   	foreach my $line (@fileds_arr) {
   		$fields_hash{$line}=1;
   	 }
   }

  $LIST_PARAMS{FIELDS}=$FORM{FIELDS};
  $pages_qs="&FIELDS=$FORM{FIELDS}";

  my $table2 = $html->table({ width => '100%' });
  my @arr = ();
  my $i=0;

  foreach my $line (sort keys %{ $attr->{FIELDS} }) {
  	my ($id, $k)=split(/:/, $line);
  	
  	push @arr, $html->form_input("FIELDS", $k, { TYPE => 'checkbox', STATE => (defined($fields_hash{$k})) ? 'checked' : undef, OUTPUT2RETURN => 1 }). " $attr->{FIELDS}{$line}";
  	$i++;
  	if ($#arr > 1) {
      $table2->addrow(@arr);
      @arr = ();
     }
   }

  if ($#arr > -1 ) {
    $table2->addrow(@arr);
   }
  $FIELDS .= $table2->show({ OUTPUT2RETURN => 1 });
 }  


if ($attr->{PERIOD_FORM}) {	
  	my @rows = ("$_FROM: ".  $html->date_fld2('FROM_DATE', { MONTHES => \@MONTHES, FORM_NAME => 'form_reports', WEEK_DAYS => \@WEEKDAYS }) .
               " $_TO: ".   $html->date_fld2('TO_DATE', { MONTHES => \@MONTHES, FORM_NAME => 'form_reports', WEEK_DAYS => \@WEEKDAYS } ) );

		if (! $attr->{NO_GROUP}) {
	  push @rows, "$_TYPE:",   $html->form_select('TYPE', 
                                                     { SELECTED     => $FORM{TYPE},
 	                                                     SEL_HASH     => { DAYS  => $_DAYS, 
 	                                                                       USER  => $_USERS, 
 	                                                                       HOURS => $_HOURS,
 	                                                                       ($attr->{EXT_TYPE}) ? %{ $attr->{EXT_TYPE} } : ''
 	                                                                      },
 	                                                     NO_ID        => 1
 	                                                     });
	}


  if ($attr->{EX_INPUTS}) {
  	foreach my $line (@{ $attr->{EX_INPUTS} }) {
       push @rows, $line;
     }
   }

	$table = $html->table( { width    => '100%',
	                         rowcolor => $_COLORS[1],
                           rows     => [[@rows , 
 	                                       ($attr->{XML}) ? 
 	                                          $html->form_input('NO_MENU', 1, { TYPE => 'hidden' }).
 	                                          $html->form_input('xml', 1, { TYPE => 'checkbox', OUTPUT2RETURN => 1 })."XML" : ''.
                                            $html->form_input('show', $_SHOW, { TYPE => 'submit', OUTPUT2RETURN => 1 }) ]
                                         ],                                   
                      });

  print $html->form_main({ CONTENT => $table->show({ OUTPUT2RETURN => 1 }).$FIELDS,
	                         NAME    => 'form_reports',
	                         HIDDEN  => { 
	                                     'index' => "$index",
	                                     ($attr->{HIDDEN}) ? %{ $attr->{HIDDEN} } : undef
	                                    }});

  if (defined($FORM{show})) {
    $pages_qs .= "&show=1&FROM_DATE=$FORM{FROM_DATE}&TO_DATE=$FORM{TO_DATE}";
    $LIST_PARAMS{TYPE}=$FORM{TYPE};
    $LIST_PARAMS{INTERVAL} = "$FORM{FROM_DATE}/$FORM{TO_DATE}";
   }
}

if (defined($FORM{DATE})) {
  ($y, $m, $d)=split(/-/, $FORM{DATE}, 3);	

  $LIST_PARAMS{DATE}="$FORM{DATE}";
  $pages_qs .="&DATE=$LIST_PARAMS{DATE}";

  if (defined($attr->{EX_PARAMS})) {
   	my $EP = $attr->{EX_PARAMS};
	  while(my($k, $v)=each(%$EP)) {
     	if ($FORM{EX_PARAMS} eq $k) {
        $EX_PARAMS .= ' '.$html->b($v);
        $LIST_PARAMS{$k}=1;
     	  if ($k eq 'HOURS') {
    	  	 undef $attr->{SHOW_HOURS};
	       } 
     	 }
     	else {
     	  $EX_PARAMS .= $html->button($v, "index=$index$pages_qs&EX_PARAMS=$k", { BUTTON => 1} ).  ' ';
     	 }
	  }
  }



  my $days = '';
  for ($i=1; $i<=31; $i++) {
     $days .= ($d == $i) ? ' '. $html->b($i) : ' '.$html->button($i, sprintf("index=$index&DATE=%d-%02.f-%02.f&EX_PARAMS=$FORM{EX_PARAMS}%s%s", $y, $m, $i, 
       (defined($FORM{GID})) ? "&GID=$FORM{GID}" : '', 
       (defined($FORM{UID})) ? "&UID=$FORM{UID}" : '' ), { BUTTON => 1 });
   }
  
  
  @rows = ([ "$_YEAR:",  $y ],
           [ "$_MONTH:", $MONTHES[$m-1] ], 
           [ "$_DAY:",   $days ]);
  
  if ($attr->{SHOW_HOURS}) {
    my(undef, $h)=split(/ /, $FORM{HOUR}, 2);
    my $hours = '';
    for (my $i=0; $i<24; $i++) {
    	$hours .= ($h == $i) ? $html->b($i) : ' '.$html->button($i, sprintf("index=$index&HOUR=%d-%02.f-%02.f+%02.f&EX_PARAMS=$FORM{EX_PARAMS}$pages_qs", $y, $m, $d, $i), { BUTTON => 1 });
     }
 	  $LIST_PARAMS{HOUR}="$FORM{HOUR}";
  	push @rows, [ "$_HOURS", $hours ];
   }

  if ($attr->{EX_PARAMS}) {
    push @rows, [' ', $EX_PARAMS];
   }  

  $table = $html->table({ width       => '100%',
                          rowcolor   => $_COLORS[1],
                          cols_align => ['right', 'left'],
                          rows       => [ @rows ]
                         });
  print $table->show();
}
}

#*******************************************************************
# form_fees
#*******************************************************************
sub form_fees {
	if (! $FORM{sort}) {
		$LIST_PARAMS{SORT}=1;
		$LIST_PARAMS{DESC}='DESC';
	 }
	
 my @FEES_METHODS = ($_ONE_TIME, $_ABON, $_FINE, $_ACTIVATE, $_MONEY_TRANSFER);
 push @FEES_METHODS, @EX_FEES_METHODS if (@EX_FEES_METHODS);

my $fees = Finance->fees($db, $admin, \%conf);
my $list = $fees->list( { %LIST_PARAMS } );
my $table = $html->table( { width       => '100%',
                            caption     => "$_FEES",
                            border      => 1,
                            title_plain => ['', $_LOGIN, $_DATE, $_DESCRIBE, $_SUM, $_DEPOSIT, $_TYPE, $_BILL],
                            cols_align => ['right', 'left', 'right', 'right', 'left', 'left', 'left', 'right', 'right'],
                            qs         => $pages_qs,
                            pages      => $fees->{TOTAL},
                            ID         => 'FEES'
                        } );


$pages_qs .= "&subf=2" if (! $FORM{subf});
foreach my $line (@$list) {

  $table->addrow('', 
   $line->[1], 
   $line->[2], 
   $line->[3], 
   $line->[4],  
   $line->[5],
   $FEES_METHODS[$line->[6]],
   "$line->[7]",
   );
}

print $table->show();

$table = $html->table( { width      => '100%',
                         cols_align => ['right', 'right', 'right', 'right'],
                         rows       => [ [ "$_TOTAL:", $html->b($fees->{TOTAL}), "$_SUM:", $html->b($fees->{SUM}) ] ],
                         rowcolor   => $_COLORS[2]
                      } );
print $table->show();
}


#*******************************************************************
# form_payments
#*******************************************************************
sub form_payments {
@PAYMENT_METHODS = ("$_CASH", "$_BANK", "$_EXTERNAL_PAYMENTS", 'Credit Card', "$_BONUS", "$_CORRECTION", "$_COMPENSATION", "$_MONEY_TRANSFER");
push @PAYMENT_METHODS, @EX_PAYMENT_METHODS if (@EX_PAYMENT_METHODS);

my $Payments = Finance->payments($db, $admin, \%conf);

if (! $FORM{sort}) {
  $LIST_PARAMS{sort}=1;
  $LIST_PARAMS{DESC}='DESC';
}
my $list  = $Payments->list( { %LIST_PARAMS } );
my $table = $html->table( { width      => '100%',
                            caption    => "$_PAYMENTS",
                            border     => 1,
                            title_plain      => ['', $_LOGIN, $_DATE, $_DESCRIBE, $_SUM, $_DEPOSIT ], # $_PAYMENT_METHOD, 'EXT ID', "$_BILL"],
                            cols_align => ['right', 'left', 'left', 'right', 'right', 'left', 'right', 'right', 'left', 'left'],
                            qs         => $pages_qs,
                            pages      => $Payments->{TOTAL},
                            ID         => 'PAYMENTS'
                           } );

foreach my $line (@$list) {
  $table->addrow('', 
  $html->button($line->[1], "index=15&UID=$line->[11]"), 
  $line->[2], 
  $line->[3], 
  $line->[4],  
  "$line->[5]", 
#  $PAYMENT_METHODS[$line->[6]], 
#  "$line->[7]", 
#  "$line->[8]", 
  );
}

print $table->show();

$table = $html->table({ width      => '100%',
                        cols_align => ['right', 'right', 'right', 'right'],
                        rows       => [ [ "$_TOTAL:", $html->b($Payments->{TOTAL}), 
                                          "$_SUM:", $html->b($Payments->{SUM}) 
                                       ] ],
                        rowcolor   => $_COLORS[2]
                      });
print $table->show();
}

#*******************************************************************
# form_period
#*******************************************************************
sub form_period  {
 my ($period, $attr) = @_;

 my @periods = ("$_NEXT_PERIOD", "$_DATE");
 $attr->{TP}->{date_fld} = $html->date_fld2('DATE', { FORM_NAME => 'user', MONTHES => \@MONTHES, WEEK_DAYS => \@WEEKDAYS, NEXT_DAY => 1 });
 my $form_period='';
 $form_period .= "<tr><td>$_DATE:</td><td>";
 $period=1;

 for(my $i=$#periods; $i>-1; $i--) {
 	 my $t = $periods[$i];
   $form_period .= $html->br().$html->br();
   $form_period .= $html->form_input('period', "$i", { TYPE          => "radio", 
   	                                                   STATE         => ($i eq $period) ? 1 : undef, 
   	                                                   OUTPUT2RETURN => 1
   	                                                  });

   $form_period .= ($i == 0) ? ($attr->{ABON_DATE}) ? $t ." ($attr->{ABON_DATE})" : "$_NOW" : $t. " $attr->{TP}->{date_fld}";
 }

 $form_period .= "</td></tr>\n";
 return $form_period;	
}

#**********************************************************
# transfer funds between users accounts 
#**********************************************************
sub form_money_transfer {
	my ($attr) = @_;

  my $deposit_limit  = 0;
  my $transfer_price = 0;

  $admin->{SESSION_IP}=$ENV{REMOTE_ADDR};

  if ($conf{MONEY_TRANSFER} =~ /:/) {
    ($deposit_limit, $transfer_price, $no_companies)=split(/:/, $conf{MONEY_TRANSFER});
    
    if ($no_companies eq 'NO_COMPANIES' && $user->{COMPANY_ID}) {
    	 $html->message('info', $_ERROR, "$ERR_ACCESS_DENY");
    	 return 0;
     }
   }
  $transfer_price = sprintf("%.2f", $transfer_price);

if ($FORM{s2} || $FORM{transfer}) {
  $FORM{SUM} = sprintf("%.2f", $FORM{SUM});

	if ($user->{DEPOSIT} < $FORM{SUM} + $deposit_limit + $transfer_price) {
	  $html->message('err', $_ERROR, "$ERR_SMALL_DEPOSIT");
	 }
	elsif (! $FORM{SUM}) {
	  $html->message('err', $_ERROR, "$ERR_WRONG_SUM");
	 }
	elsif (! $FORM{RECIPIENT}) {
		$html->message('err', $_ERROR, "$_SELECT_USER");
	 }
	elsif ($FORM{RECIPIENT} == $user->{UID}) {
		$html->message('err', $_ERROR, "$_USER_NOT_EXIST");
	 }
	else {
		my $user2=Users->new($db, $admin, \%conf); 
		$user2->info(int($FORM{RECIPIENT}));
		if ($user2->{TOTAL} < 1) {
			$html->message('err', $_ERROR, "$_USER_NOT_EXIST");
		 }
	  else {
	  	$user2->pi({ UID => $user2->{UID} });
      
	    if (! $FORM{ACCEPT} && $FORM{transfer}) {
		    $html->message('err', $_ERROR, "$ERR_ACCEPT_RULES");
		    $html->tpl_show(templates('form_money_transfer_s2'), { %$user2, %FORM });	
	     }
	   	elsif ($FORM{transfer}) {
    		#Fees 
    		my $Fees = Finance->fees($db, $admin, \%conf);
        $Fees->take($user, $FORM{SUM}, { DESCRIBE => "$_USER: $user2->{UID}", 
        	                               METHOD   => 4 });  
        if ($fees->{errno}) {
          $html->message('err', $_ERROR, "[$fees->{errno}] $err_strs{$fees->{errno}}");	
         }
        else {
        	$html->message('info', $_FEES, "$_TAKE SUM: $FORM{SUM}". (($transfer_price >0) ? " $_COMMISSION $_SUM: $transfer_price" : '' ));
        	my $Payments = Finance->payments($db, $admin, \%conf);
          $Payments->add($user2, { DESCRIBE       => "$_USER: $user->{UID}",
          	                       INNER_DESCRIBE => "$Fees->{INSERT_ID}",
          	                       SUM            => $FORM{SUM},
          	                       METHOD         => 7
          	                      });  

          if ($Payments->{errno}) {
            $html->message('err', $_ERROR, "[$Payments->{errno}] $err_strs{$Payments->{errno}}");	
           } 
          else {
          	my $message = "# $Payments->{INSERT_ID} $_MONEY_TRANSFER $_SUM: $FORM{SUM}";
            if ($transfer_price > 0) {
          		my $Fees = Finance->fees($db, $admin, \%conf);
              $Fees->take($user, $transfer_price, { DESCRIBE => "$_USER: $user2->{UID} $_COMMISSION", 
        	                                          METHOD   => 4,
        	                                           });
              if (! $fees->{errno}) {
                #$message .= " $_COMMISSION $_SUM: $transfer_price";	
               }
             }

            $html->message('info', $_PAYMENTS, $message);
            $users2->{PAYMENT_ID}=$Payments->{INSERT_ID};
            cross_modules_call('_payments_maked', { USER_INFO => $user2, QUITE => 1 });
           }
         }

    		#Payments
        $html->tpl_show(templates('form_money_transfer_s3'), { %FORM, %$user2 });			
	     }
	    elsif ($FORM{s2}) {
	    	$user2->{COMMISSION} = "$_COMMISSION: $transfer_price";
	      $html->tpl_show(templates('form_money_transfer_s2'), { %$user2, %FORM });	
	     }
	    return 0; 	
	   }
	 }
}

 $html->tpl_show(templates('form_money_transfer_s1'), \%FORM); 	
}


#**********************************************************
# Calls function for all registration modules if function exist 
#
# cross_modules_call(function_sufix, attr) 
#**********************************************************
sub cross_modules_call  {
  my ($function_sufix, $attr) = @_;

  my %full_return = '';

  foreach my $mod (@MODULES) {
    require "Abills/modules/$mod/webinterface";
    my $function = lc($mod).$function_sufix;
    my $return;
    if (defined(&$function)) {
     	$return = $function->($attr);
     }
    $full_return{$mod}=$return;
   }

  return \%full_return;
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


#**********************************************************
# Get function index
#
# get_function_index($function_name, $attr) 
#**********************************************************
sub form_neg_deposit {
  my ($user, $attr)=@_;

  if (in_array('Docs', \@MODULES) ) {
   	my $fn_index = get_function_index('docs_invoices_list');
    $user->{DOCS_BUTTON} = $html->button("$_INVOICE_CREATE", "index=$fn_index$pages_qs", { BUTTON => 1} );
   }

  if (in_array('Paysys', \@MODULES) ) {
    my $fn_index = get_function_index('paysys_payment');
    $user->{PAYMENT_BUTTON} = $html->button("$_BALANCE_RECHARCHE", "index=$fn_index$pages_qs", { BUTTON => 1} );
   }

 	$html->tpl_show(templates('form_neg_deposit'), $user);	
}


#**********************************************************
# Make external operations
#**********************************************************
sub _external {
	my ($file, $attr) = @_;
  
  my $arguments = '';
  $attr->{LOGIN}      = $users->{LOGIN};
  $attr->{DEPOSIT}    = $users->{DEPOSIT};
  $attr->{CREDIT}     = $users->{CREDIT};
  $attr->{GID}        = $users->{GID};
  $attr->{COMPANY_ID} = $users->{COMPANY_ID};
  
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

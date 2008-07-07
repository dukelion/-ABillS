#!/usr/bin/perl 
# ABillS User Web interface
#
#



use vars qw($begin_time %LANG $CHARSET @MODULES $FUNCTIONS_LIST $USER_FUNCTION_LIST $UID $user $admin 
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
require "Abills/defs.conf";
require "Abills/templates.pl";
use Abills::Base;
use Abills::SQL;
use Abills::HTML;
use Users;
use Finance;


$html = Abills::HTML->new( { IMG_PATH => 'img/',
	                     NO_PRINT => 1,
	                     CONF     => \%conf,
	                     CHARSET  => $conf{default_charset}
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
if ((length($COOKIES{sid})>1) && (! $FORM{passwd})) {
  $COOKIES{sid} =~ s/"//g;
  $COOKIES{sid} =~ s/'//g;
  $sid = $COOKIES{sid};
}
elsif((length($COOKIES{sid})>1) && (defined($FORM{passwd}))){
	$html->setCookie('sid', "", "Fri, 1-Jan-2038 00:00:01", $web_path, $domain, $secure);
	$COOKIES{sid}=undef;
}

#Cookie section ============================================
if (defined($FORM{colors})) {
  my $cook_colors = (defined($FORM{default})) ?  '' : $FORM{colors};
  $html->setCookie('colors', "$cook_colors", "Fri, 1-Jan-2038 00:00:01", $web_path, $domain, $secure);
 }
#Operation system ID
$html->setCookie('OP_SID', "$FORM{OP_SID}", "Fri, 1-Jan-2038 00:00:01", $web_path, $domain, $secure) if (defined($FORM{OP_SID}));
$html->setCookie('language', "$FORM{language}", "Fri, 1-Jan-2038 00:00:01", $web_path, $domain, $secure) if (defined($FORM{language}));

if (defined($FORM{sid})) {
  $html->setCookie('sid', "$FORM{sid}", "Fri, 1-Jan-2038 00:00:01", $web_path, $domain, $secure);
}
#===========================================================


if ($index == 10) {
  $user=Users->new($db, $admin, \%conf); 
  logout();

  print "Location: $SELF_URL". "\n\n";
  exit;
}

my $maxnumber = 0;
my $uid = 0;
my $page_qs;

require Admins;
Admins->import();
$admin = Admins->new($db, \%conf);
$admin->info($conf{SYSTEM_ADMIN_ID}, { IP => '127.0.0.1' });

my %OUTPUT = ();

my $login = $FORM{user} || '';
my $passwd = $FORM{passwd} || '';

my @m = (
   "10:0:$_LOGOUT:logout:::",
   "30:0:$_USER_INFO:form_info:::",
   );

if ($conf{user_finance_menu}) {
   push @m, "40:0:$_FINANCES:form_payments:::";
   push @m, "41:40:$_FEES:form_fees:::";
}

$user=Users->new($db, $admin, \%conf); 

($uid, $sid, $login) = auth("$login", "$passwd", "$sid");

my %uf_menus = ();

if ($uid > 0) {
  $UID = $uid;
  my $default_index = 30;
  
  #Quick Amon Alive Update
  # $ENV{HTTP_USER_AGENT} =~ /^AMon /
  if ($FORM{ALIVE}) {
 	  require "Abills/modules/Ipn/webinterface";

# 	  my $text = '';
# 	  while(my($k, $v)=each %FORM) {
# 	    $text .= "$k, $v\n";
# 	    }
#    my $aa = `echo "$text\n=====\n" >> /tmp/amon`;

    print $html->header();
    $LIST_PARAMS{LOGIN}=$user->{LOGIN};
    ipn_user_activate();
    $OUTPUT{BODY}=$html->{OUTPUT};    
    print $html->tpl_show(templates('form_client_start'), \%OUTPUT);
 	  exit;
   }
  
  push @m, "17:0:$_PASSWD:form_passwd:::" if($conf{user_chg_passwd});

  mk_menu();

  $html->{SID}=$sid;
  (undef, $OUTPUT{MENU}) = $html->menu(\%menu_items, \%menu_args, undef, 
     { EX_ARGS         => "&sid=$sid", 
     	 ALL_PERMISSIONS => 1,
     	 FUNCTION_LIST   => \%functions
     });
  
  if ($html->{ERROR}) {
  	$html->message('err',  $_ERROR, "$html->{ERROR}");
  	exit;
  }

  $OUTPUT{DATE}=$DATE;
  $OUTPUT{TIME}=$TIME;
  $OUTPUT{LOGIN}=$login;
  $OUTPUT{IP}=$user->{REMOTE_ADDR};

  $pages_qs="&UID=$user->{UID}&sid=$sid";
  $LIST_PARAMS{UID}=$user->{UID};
  $LIST_PARAMS{LOGIN}=$user->{LOGIN};

  $index = $FORM{qindex} if ($FORM{qindex});
  my $lang_file = '';
  foreach my $prefix (@INC) {
    my $realfilename = "$prefix/Abills/modules/$module{$index}/lng_$html->{language}.pl";
    if (-f $realfilename) {
      $lang_file =  $realfilename;
      last;
     }
    elsif (-f "$prefix/Abills/modules/$module{$index}/lng_english.pl") {
    	$lang_file = "$prefix/Abills/modules/$module{$index}/lng_english.pl";
     }
   }

  if ($lang_file ne '') {
    require $lang_file;
   }

  if ($FORM{qindex}) {
    if(defined($module{$FORM{qindex}})) {
 	   	require "Abills/modules/$module{$FORM{qindex}}/webinterface";
     }

    $functions{$FORM{qindex}}->();
    print "$html->{OUTPUT}";
    exit;
   }

  if(defined($module{$index})) {
 	 	require "Abills/modules/$module{$index}/webinterface";
   }

  if ($index != 0 && defined($functions{$index})) {
    $functions{$index}->();
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
  
  
  $OUTPUT{BODY}=$html->tpl_show(templates('form_client_main'), \%OUTPUT);

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
 
  $maxnumber  = 0;
  
  foreach my $line (@m) {
	  my ($ID, $PARENT, $NAME, $FUNTION_NAME, $SHOW_SUBMENU, $OP)=split(/:/, $line);
    $menu_items{$ID}{$PARENT}=$NAME;
    $menu_names{$ID} = $NAME;
    $functions{$ID}  = $FUNTION_NAME if ($FUNTION_NAME  ne '');
    $maxnumber=$ID if ($maxnumber < $ID);
   }

  foreach my $m (@MODULES) {

    if(my $return = do "Abills/modules/$m/config") {
     }
#                 warn "couldn't parse Abills/modules/$m/config: $@" if $@;
#                 warn "couldn't do Abills/modules/$m/config: $!"    unless defined $return;
#                 warn "couldn't run "."Abills/modules/$m/config"       unless $return;
#       }

#  	require "Abills/modules/$m/config";
    my %module_fl=();

    next if (keys %USER_FUNCTION_LIST < 1);
    my @sordet_module_menu = sort keys %USER_FUNCTION_LIST;

    foreach my $line (@sordet_module_menu) {
      $maxnumber++;
      my($ID, $SUB, $NAME, $FUNTION_NAME, $ARGS)=split(/:/, $line, 5);
      $ID = int($ID);
      my $v = $USER_FUNCTION_LIST{$line};

      $module_fl{"$ID"}=$maxnumber;
      #$fl .= "$FUNTION_NAME $maxnumber\n";
      
      if ($index < 1 && $ARGS eq 'defaultindex') {
        $default_index=$maxnumber;
        $index=$default_index;
       }
      elsif ($ARGS ne '' && $ARGS ne 'defaultindex') {
        $menu_args{$maxnumber}=$ARGS;
       }
      #print "$line -- $ID, $SUB, $NAME, $FUNTION_NAME  // $module_fl{$SUB} PARENT: $v<br/>";
     
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
}

#**********************************************************
# form_stats
#**********************************************************
sub form_info {
  
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
  
  my $payments = Finance->payments($db, $admin, \%conf);
  $LIST_PARAMS{PAGE_ROWS}=1;
  $LIST_PARAMS{DESC}='desc';
  $LIST_PARAMS{SORT}=1;
  my $list = $payments->list( { %LIST_PARAMS } );
  
  $user->{PAYMENT_DATE}=$list->[0]->[2];
  $user->{PAYMENT_SUM}=$list->[0]->[3];
  if ($conf{EXT_BILL_ACCOUNT} && $user->{EXT_BILL_ID} > 0) {
    $user->{EXT_DATA}=$html->tpl_show(templates('form_ext_bill'), 
                                             $user, { OUTPUT2RETURN => 1 });
   }
  $html->tpl_show(templates('form_client_info'), $user);

  if ($conf{user_chg_pi}) {
    $html->form_main({ CONTENT => $html->form_input('chg', "$_CHANGE", { TYPE => 'SUBMIT', OUTPUT2RETURN => 1 } ),
	                     HIDDEN  => { 
	                                 sid   => $sid,
	                                 index => "$index"
	                    }});
  	
   }
}






##*******************************************************************
## WHERE period
## base_state($where, $period);
##*******************************************************************
#sub stats_calculation  {
#  my ($sessions) = @_;
#
#$sessions->calculation({ %LIST_PARAMS }); 
#my $table = $html->table( { width => '640',
#	                          rowcolor => $_COLORS[1],
#                            title_plain => ["-", "$_MIN", "$_MAX", "$_AVG"],
#                            cols_align => ['left', 'right', 'right', 'right'],
#                            rows => [ [ $_DURATION,  $sessions->{min_dur}, $sessions->{max_dur}, $sessions->{avg_dur} ],
#                                          [ "$_TRAFFIC $_RECV", int2byte($sessions->{min_recv}), int2byte($sessions->{max_recv}), int2byte($sessions->{avg_recv}) ],
#                                          [ "$_TRAFFIC $_SENT", int2byte($sessions->{min_sent}), int2byte($sessions->{max_sent}), int2byte($sessions->{avg_sent}) ],
#                                          [ "$_TRAFFIC $_SUM",  int2byte($sessions->{min_sum}),  int2byte($sessions->{max_sum}),  int2byte($sessions->{avg_sum}) ]
#                                        ]
#                               } );
#print $table->show();
#}


#**********************************************************
# form_login  
#**********************************************************
sub form_login {
 my %first_page = ();
 $first_page{SEL_LANGUAGE} = $html->form_select('language', 
                                { EX_PARAMS => 'onChange="selectLanguage()"',
 	                                SELECTED  => $html->{language},
 	                                SEL_HASH  => \%LANG,
 	                                NO_ID     => 1 });

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
  if ($conf{check_access}{NAS_IP} =~ /(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}):21/) {
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


#Passwordless Access
if ($conf{PASSWORDLESS_ACCESS}) {
    require  Dv_Sessions;
    Dv_Sessions->import();
    my $sessions = Dv_Sessions->new($db, $admin, \%conf);
	  my $list = $sessions->online({ FRAMED_IP_ADDRESS => "$REMOTE_ADDR" });
    
    if ($sessions->{TOTAL} > 0) {
      $login   = $list->[0]->[0];
      $ret     = $list->[0]->[11];
      #$time    = time;
      $sid     = mk_unique_value(14);
      $action  = 'Access';
      $user->info($ret);
      return ($ret, $sid, $login);
    }
  }

if (defined($FORM{op}) && $FORM{op} eq 'logout') {
  $user->web_session_del({ SID => $FORM{sid} });
  return 0;
 }
elsif (length($sid) > 1) {
  
  $user->web_session_info({ SID => $sid });

  if ($user->{TOTAL} < 1) { 
    $html->message('err', "$_ERROR", "$_NOT_LOGINED");	
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
  if (defined($conf{check_access})) {
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

    $action = 'Access';
   }
  else {
    $html->message('err', "$_ERROR", "$ERR_WRONG_PASSWD");
    $action = 'Error';
   }
 }
else {
   $user->bruteforce_add({ LOGIN       => $login, 
 	                         PASSWORD    => $password,
    	                     REMOTE_ADDR => $REMOTE_ADDR,
    	                     AUTH_STATE  => $ret });

   $html->message('err', "$_ERROR", "$ERR_WRONG_PASSWD");
   $ret = 0;
   $action = 'Error';
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

 
if ($FORM{newpassword} eq '') {

 }
elsif (length($FORM{newpassword}) < $conf{PASSWD_LENGTH}) {
  $html->message('err', $_ERROR, $err_strs{6});
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
  $html->message('err', $_ERROR, $err_strs{5});
}

 my $password_form;
 $password_form->{ACTION}='change';
 $password_form->{LNG_ACTION}="$_CHANGE";
 $password_form->{GEN_PASSWORD}=mk_unique_value(8);
 $html->tpl_show(templates('form_password'), $password_form);

 return 0;
}

sub logout {
	$FORM{op}='logout';
	auth('', '', $sid);
	#$html->message('info', $_INFO, $_LOGOUT);
	
	
	
	return 0;
}


#**********************************************************
#
# FIELDS => FIELDS_HASH
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
	$pages_qs="&allmonthes=y";
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
   }

  #$user->{GROUPS_SEL} = sel_groups();
  #$html->tpl_show(templates('groups_sel'), $user);
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
  
  foreach my $line (sort keys %{ $attr->{FIELDS} }) {
  	my ($id, $k)=split(/:/, $line);
  	$FIELDS .= $html->form_input("FIELDS", $k, { TYPE => 'checkbox', STATE => (defined($fields_hash{$k})) ? 'checked' : undef }). " $attr->{FIELDS}{$line}";
   }
 }  


if ($attr->{PERIOD_FORM}) {
	$table = $html->table( { width    => '100%',
	                         rowcolor => $_COLORS[1],
                           rows     => [["$_FROM: ",   $html->date_fld('from', { MONTHES => \@MONTHES} ),
                                          "$_TO: ",    $html->date_fld('to', { MONTHES => \@MONTHES } ), 
 	                                        ($attr->{XML}) ? 
 	                                        $html->form_input('NO_MENU', 1, { TYPE => 'hidden' }).
 	                                        $html->form_input('xml', 1, { TYPE => 'checkbox' })."XML" : '',

                                          $html->form_input('show', $_SHOW, { TYPE => 'submit', OUTPUT2RETURN => 1 }) ]
                                         ],                                   
                      });
 
  print $html->form_main({ CONTENT => $table->show({ OUTPUT2RETURN => 1 }).$FIELDS,
	                         HIDDEN  => { 
	                                    ($attr->{HIDDEN}) ? %{ $attr->{HIDDEN} } : undef,
	                                    index => "$index"
	                                    }});

  if (defined($FORM{show})) {
    $pages_qs .= "&show=y&fromD=$FORM{fromD}&fromM=$FORM{fromM}&fromY=$FORM{fromY}&toD=$FORM{toD}&toM=$FORM{toM}&toY=$FORM{toY}";
    $FORM{fromM}++;
    $FORM{toM}++;
    $FORM{fromM} = sprintf("%.2d", $FORM{fromM}++);
    $FORM{toM} = sprintf("%.2d", $FORM{toM}++);

    $LIST_PARAMS{TYPE}=$FORM{TYPE};
    $LIST_PARAMS{INTERVAL} = "$FORM{fromY}-$FORM{fromM}-$FORM{fromD}/$FORM{toY}-$FORM{toM}-$FORM{toD}";
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
        $EX_PARAMS .= " <b>$v</b> ";
        $LIST_PARAMS{$k}=1;
        #$pages_qs .="&EX_PARAMS=$k";

     	  if ($k eq 'HOURS') {
    	  	 undef $attr->{SHOW_HOURS};
	       } 
     	 }
     	else {
     	  $EX_PARAMS .= '::'. $html->button($v, "index=$index$pages_qs&EX_PARAMS=$k");
     	 }
	  }
  
  }



  my $days = '';
  for ($i=1; $i<=31; $i++) {
     $days .= ($d == $i) ? " <b>$i </b>" : ' '.$html->button($i, sprintf("index=$index&DATE=%d-%02.f-%02.f&EX_PARAMS=$FORM{EX_PARAMS}%s%s", $y, $m, $i, 
       (defined($FORM{GID})) ? "&GID=$FORM{GID}" : '', 
       (defined($FORM{UID})) ? "&UID=$FORM{UID}" : '' ));
   }
  
  
  @rows = ([ "$_YEAR:",  $y ],
           [ "$_MONTH:", $MONTHES[$m-1] ], 
           [ "$_DAY:",   $days ]);
  
  if ($attr->{SHOW_HOURS}) {
    my(undef, $h)=split(/ /, $FORM{HOUR}, 2);
    my $hours = '';
    for (my $i=0; $i<24; $i++) {
    	$hours .= ($h == $i) ? " <b>$i </b>" : ' '.$html->button($i, sprintf("index=$index&HOUR=%d-%02.f-%02.f+%02.f&EX_PARAMS=$FORM{EX_PARAMS}$pages_qs", $y, $m, $d, $i));
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
# form_period
#*******************************************************************
sub form_fees {
	
	
	if (! $FORM{sort}) {
		$LIST_PARAMS{SORT}=1;
		$LIST_PARAMS{DESC}='DESC';
	 }
	
my $fees = Finance->fees($db, $admin, \%conf);
my $list = $fees->list( { %LIST_PARAMS } );
my $table = $html->table( { width      => '100%',
                            caption    => "$_FEES",
                            border     => 1,
                            title      => ['ID', $_LOGIN, $_DATE, $_SUM, $_DESCRIBE, $_ADMINS, 'IP',  $_DEPOSIT],
                            cols_align => ['right', 'left', 'right', 'right', 'left', 'left', 'right', 'right'],
                            qs         => $pages_qs,
                            pages      => $fees->{TOTAL}
                        } );


$pages_qs .= "&subf=2" if (! $FORM{subf});
foreach my $line (@$list) {

  $table->addrow($html->b($line->[0]), $html->button($line->[1], "index=15&UID=$line->[8]"), $line->[2], 
   $line->[3], $line->[4],  "$line->[5]", "$line->[6]", "$line->[7]");
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
# form_period
#*******************************************************************
sub form_payments {
	
my @PAYMENT_METHODS = ('Cash', 'Bank', 'Internet Card', 'Credit Card', 'Bonus');
my $payments = Finance->payments($db, $admin, \%conf);


my $list = $payments->list( { %LIST_PARAMS } );
my $table = $html->table( { width      => '100%',
                            caption    => "$_PAYMENTS",
                            border     => 1,
                            title      => ['ID', $_LOGIN, $_DATE, $_SUM, $_DESCRIBE, $_ADMINS, 'IP',  $_DEPOSIT, $_PAYMENT_METHOD, 'EXT ID', "$_BILL"],
                            cols_align => ['right', 'left', 'right', 'right', 'left', 'left', 'right', 'right', 'left', 'left'],
                            qs         => $pages_qs,
                            pages      => $payments->{TOTAL}
                           } );

$pages_qs .= "&subf=2" if (! $FORM{subf});

foreach my $line (@$list) {
  $table->addrow($html->b($line->[0]), 
  $html->button($line->[1], "index=15&UID=$line->[11]"), 
  $line->[2], 
  $line->[3], 
  $line->[4],  
  "$line->[5]", 
  "$line->[6]", 
  "$line->[7]", 
  $PAYMENT_METHODS[$line->[8]], 
  "$line->[9]", 
  "$line->[10]", 
  );
}

print $table->show();

$table = $html->table({ width      => '100%',
                        cols_align => ['right', 'right', 'right', 'right'],
                        rows       => [ [ "$_TOTAL:", $html->b($payments->{TOTAL}), 
                                          "$_SUM", $html->b($payments->{SUM}) 
                                       ] ],
                        rowcolor   => $_COLORS[2]
                      });
print $table->show();
}

#*******************************************************************
# form_period
#*******************************************************************
sub form_period  {
 my ($period) = @_;

 my @periods = ("$_NOW", "$_DATE");
 my $date_fld = $html->date_fld('date_', { MONTHES => \@MONTHES });
 my $form_period='';

 $form_period .= "<tr><td>$_DATE:</td><td>";

 my $i=0;
 foreach my $t (@periods) {
   $form_period .= "<BR/><BR/>";
   $form_period .= $html->form_input('period', "$i", { TYPE          => "radio", 
   	                                                   STATE         => ($i eq $period) ? 1 : undef, 
   	                                                   OUTPUT2RETURN => 1
   	                                                  });
   $form_period .= $t;       
   $i++;
 }
 $form_period .= "$date_fld</td></tr>\n";


 return $form_period;	
}


1

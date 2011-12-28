#!/usr/bin/perl
# 
# http://www.maani.us/charts/index.php

BEGIN {
  my $libpath = '../../';
  $sql_type='mysql';
  unshift(@INC, $libpath ."Abills/$sql_type/");
  unshift(@INC, $libpath);
  unshift(@INC, $libpath . 'libexec/');
  unshift(@INC, $libpath . 'Abills/');
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
#
#====End config

use vars qw(%conf 
  %FUNCTIONS_LIST
  @PAYMENT_METHODS
  @EX_PAYMENT_METHODS  
  %FEES_METHODS

  @state_colors
  %permissions

  $REMOTE_USER
  $REMOTE_PASSWD

  $domain
  $secure

  $html
 
  $begin_time %LANG $CHARSET @MODULES $FUNCTIONS_LIST $USER_FUNCTION_LIST 
  $index
  $UID 
  $user 
  $admin $sid
  $ui
  );
#
#use strict;

#use FindBin '$Bin2';
use Abills::SQL;
use Abills::HTML;
use Nas;
use Admins;


my $sql = Abills::SQL->connect($conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd},
  { CHARSET => ($conf{dbcharset}) ? $conf{dbcharset} : undef  });

$db = $sql->{db};
$sql->{db}->{debug}=1;
$admin = Admins->new($db, \%conf);
use Abills::Base;

@state_colors = ("#00FF00", "#FF0000", "#AAAAFF");

#**********************************************************
#IF Mod rewrite enabled
#
#    <IfModule mod_rewrite.c>
#        RewriteEngine on
#        RewriteCond %{HTTP:Authorization} ^(.*)
#        RewriteRule ^(.*) - [E=HTTP_CGI_AUTHORIZATION:%1]
#        Options Indexes ExecCGI SymLinksIfOwnerMatch
#    </IfModule>
#    Options Indexes ExecCGI FollowSymLinks
#
#**********************************************************
#print "Content-Type: texthtml\n\n";    
#while(my($k, $v)=each %ENV) {
#	print "$k, $v\n";
#}
#exit;
%permissions = ();
if (defined($ENV{HTTP_CGI_AUTHORIZATION})) {
  $ENV{HTTP_CGI_AUTHORIZATION} =~ s/basic\s+//i;
  my ($REMOTE_USER,$REMOTE_PASSWD) = split(/:/, decode_base64($ENV{HTTP_CGI_AUTHORIZATION}));  

  my $res =  check_permissions("$REMOTE_USER", "$REMOTE_PASSWD");
  if ($res == 1) {
    print "WWW-Authenticate: Basic realm=\"$conf{WEB_TITLE} Billing System\"\n";
    print "Status: 401 Unauthorized\n";
   }
  elsif ($res == 2) {
    print "WWW-Authenticate: Basic realm=\"Billing system / '$REMOTE_USER' Account Disabled\"\n";
    print "Status: 401 Unauthorized\n";
   }

}
else {
  check_permissions('$REMOTE_USER');
}

if ($admin->{DOMAIN_ID}) {
	$conf{WEB_TITLE}=$admin->{DOMAIN_NAME};
}

$index = 0;
$html = Abills::HTML->new({ CONF     => \%conf, 
                            NO_PRINT => 0, 
                            PATH     => $conf{WEB_IMG_SCRIPT_PATH} || '../',
                            CHARSET  => $conf{default_charset},
	                          %{ $admin->{WEB_OPTIONS} } });

require "../../language/$html->{language}.pl";

if ($admin->{errno}) {
  print "Content-type: text/html\n\n";
  my $message = "$ERR_ACCESS_DENY";

  if ($admin->{errno} == 2) {
  	$message = "Account $_DISABLED or $admin->{errstr}";
   }
  elsif ($admin->{errno} == 3) {
  	$message = "$ERR_UNALLOW_IP";
   }
  elsif ($admin->{errno} == 4) {
  	$message = "$ERR_WRONG_PASSWD";
   }
  elsif (! defined($REMOTE_USER)) {
    $message = "Wrong password";
   }
  elsif (! defined($REMOTE_PASSWD)) {
  	$message = "'mod_rewrite' not install";
   }
  else {
    $message = $err_strs{$admin->{errno}};
   }

  $html->message('err', $_ERROR, "$message");
  exit;
}


require "Abills/templates.pl";
#Operation system ID
if ($FORM{OP_SID}) {
  $html->setCookie('OP_SID', $FORM{OP_SID}, "Fri, 1-Jan-2038 00:00:01", '', $domain, $secure);
}

if (defined($FORM{DOMAIN_ID})) {
  $html->setCookie('DOMAIN_ID', "$FORM{DOMAIN_ID}", "Fri, 1-Jan-2038 00:00:01", $web_path, $domain, $secure);
  $COOKIES{DOMAIN_ID}=$FORM{DOMAIN_ID};
 }

#Admin Web_options
if ($FORM{AWEB_OPTIONS}) {
  my %WEB_OPTIONS = ( language  => 1,
                      REFRESH   => 1,
                      colors    => 1,
                      PAGE_ROWS => 1
                    );

	my $web_options = '';
	
	if (! $FORM{default}) {
	  while(my($k, $v)=each %WEB_OPTIONS){
		  if ($FORM{$k}) {
  			$web_options .= "$k=$FORM{$k};";
	  	 }
      else {
    	  $web_options .= "$k=$admin->{WEB_OPTIONS}{$k};" if ($admin->{WEB_OPTIONS}{$k});
       } 
	   }
   }

  if (defined($FORM{quick_set})) {
    my(@qm_arr) = split(/, /, $FORM{qm_item});
    $web_options.="qm=";
    foreach my $line (@qm_arr) {
      $web_options .= (defined($FORM{'qm_name_'.$line})) ? "$line:".$FORM{'qm_name_'.$line}."," : "$line:,";
     }
    chop($web_options);
   }
  else {
    $web_options.="qm=$admin->{WEB_OPTIONS}{qm};";
   }
  
  $admin->change({ AID => $admin->{AID}, WEB_OPTIONS => $web_options });

  print "Location: $SELF_URL?index=$FORM{index}", "\n\n";
  exit;
}


#===========================================================
my @actions = ([$_INFO, $_ADD, $_LIST, $_PASSWD, $_CHANGE, $_DEL, $_ALL, $_MULTIUSER_OP, "$_SHOW $_DELETED", "$_CREDIT", "$_TARIF_PLANS", "$_REDUCTION"],  # Users
               [$_LIST, $_ADD, $_DEL, $_ALL, $_DATE],                         # Payments
               [$_LIST, $_GET, $_DEL, $_ALL],                                 # Fees
               [$_LIST, $_DEL],                                               # reports view
               [$_LIST, $_ADD, $_CHANGE, $_DEL, $_ADMINS, "$_SYSTEM $_LOG", $_DOMAINS],                    # system magment
               [$_MONITORING, $_HANGUP],
               [$_SEARCH],                                                    # Search
               [$_ALL],                                                       # Modules managments               
               [$_PROFILE],
               [$_LIST, $_ADD, $_CHANGE, $_DEL],
               );


if ($admin->{GIDS}) {
	$LIST_PARAMS{GIDS}=$admin->{GIDS} 
 }
elsif  ($admin->{GID} > 0) {
  $LIST_PARAMS{GID}=$admin->{GID} 
 }

if  ($admin->{DOMAIN_ID} > 0) {
  $LIST_PARAMS{DOMAIN_ID}=$admin->{DOMAIN_ID};
 }

if  ($admin->{MAX_ROWS} > 0) {
  $LIST_PARAMS{PAGE_ROWS}=$admin->{MAX_ROWS};
  $FORM{PAGE_ROWS}=$admin->{MAX_ROWS};
  $html->{MAX_ROWS}=$admin->{MAX_ROWS};
 }



#Global Vars
@action         = ('add', $_ADD);
@bool_vals      = ($_NO, $_YES);
@PAYMENT_METHODS= ("$_CASH", "$_BANK", "$_EXTERNAL_PAYMENTS", 'Credit Card', "$_BONUS", "$_CORRECTION", "$_COMPENSATION", "$_MONEY_TRANSFER");
@status         = ("$_ENABLE", "$_DISABLE");
my %menu_items  = ();
my %menu_names  = ();
my $maxnumber   = 0;
my %uf_menus    = (); #User form menu list
my %menu_args   = ();

fl();
my %USER_SERVICES = ();
#Add modules
foreach my $m (@MODULES) {
	next if ($admin->{MODULES} && ! $admin->{MODULES}{$m});
	require "Abills/modules/$m/config";
  my %module_fl=();

  my @sordet_module_menu = sort keys %FUNCTIONS_LIST;
  foreach my $line (@sordet_module_menu) {
   
    $maxnumber++;
    my($ID, $SUB, $NAME, $FUNTION_NAME, $ARGS)=split(/:/, $line, 5);
    $ID = int($ID);
    my $v = $FUNCTIONS_LIST{$line};

    $module_fl{"$ID"}=$maxnumber;
    if ($ARGS && $ARGS ne '') {
      $menu_args{$maxnumber}=$ARGS ;
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

    #make user service list
    if ($SUB == 0 && $FUNCTIONS_LIST{$line} == 11) {
      $USER_SERVICES{$maxnumber}="$NAME" ;
     }

    $menu_names{$maxnumber}= $NAME;
    $functions{$maxnumber} = $FUNTION_NAME if ($FUNTION_NAME  ne '');
    $module{$maxnumber}    = $m;
  }
}

use Users;
$users = Users->new($db, $admin, \%conf); 

#Quick index
# Show only function results whithout main windows
if ($FORM{qindex}) {
  $index = $FORM{qindex};
  if ($FORM{header}) {
  	$html->{METATAGS}=templates('metatags');  
  	print $html->header();
   }
  
  if ($index == -1) {
  	$html->{METATAGS}=templates('metatags');  
  	print $html->header();
  	form_purchase_module({ MODULE => $FORM{MODULE} });
  	exit;
   }
  
  if(defined($module{$index})) {
 	 	load_module($module{$index}, $html);
   }
  if ($functions{$index}) {
    $functions{$index}->();
   }
  else {
  	print "Content/type: text/html\n\n";
  	print "Function not exist!";
   }
  exit;
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


$html->{METATAGS}=templates('metatags');
if(($FORM{UID} && $FORM{UID} =~ /^(\d+)$/ && $FORM{UID} > 0) || ($FORM{LOGIN} && $FORM{LOGIN} && $FORM{LOGIN} !~ /\*/ && ! $FORM{add} && !$FORM{next})) {
 	$ui = user_info($FORM{UID}, { LOGIN => ($FORM{LOGIN}) ? $FORM{LOGIN} : undef });
 	$html->{WEB_TITLE} = "$conf{WEB_TITLE} [$ui->{LOGIN}]";
 }

print $html->header();
my ($menu_text, $navigat_menu) = mk_navigator();
($admin->{ONLINE_USERS}, $admin->{ONLINE_COUNT}) = $admin->online();




my %SEARCH_TYPES = (11 => $_USERS,
                    2  => $_PAYMENTS,
                    3  => $_FEES,
                    13 => $_COMPANY
                   );

if(defined($FORM{index}) && $FORM{index} != 7 && ! defined($FORM{type})) {
	$FORM{type}=$FORM{index};
 }
elsif (! defined $FORM{type}) {
	$FORM{type}=15;
}



$admin->{SEL_TYPE} = $html->form_select('type', 
                                { SELECTED   => (! $SEARCH_TYPES{$FORM{type}}) ? 11 : $FORM{type},
 	                                SEL_HASH   => \%SEARCH_TYPES,
 	                                NO_ID      => 1
 	                                #EX_PARAMS => 'onChange="selectstype()"'
 	                               });


#Domains sel
if (in_array('Multidoms', \@MODULES) && $permissions{10}) {
  load_module('Multidoms', $html);
  $FORM{DOMAIN_ID}       = $COOKIES{DOMAIN_ID};
  $admin->{DOMAIN_ID}    = $FORM{DOMAIN_ID};
  $LIST_PARAMS{DOMAIN_ID}= $admin->{DOMAIN_ID};
  $admin->{SEL_DOMAINS}  = "$_DOMAINS:" . $html->form_main({ CONTENT => multidoms_domains_sel(),
	                       HIDDEN  => { index      => $index, 
	                       	            COMPANY_ID => $FORM{COMPANY_ID} 
	                       	            },
	                       SUBMIT  => { action   => "$_CHANGE"
	                       	           } });
 }


## Visualisation begin
print "<table width='100%' border='0' cellpadding='0' cellspacing='1'>\n";
$admin->{DATE}=$DATE;
$admin->{TIME}=$TIME;
if(defined($conf{tech_works})) {
  $admin->{TECHWORK} = "<tr><th class='red' colspan='2'>$conf{tech_works}</th></tr>\n";
}

#Quick Menu
if ($admin->{WEB_OPTIONS}{qm} && ! $FORM{xml}) {
  $admin->{QUICK_MENU} = "<tr class='HEADER_QM'><td colspan='2' class='noprint'><table  width='100%' border='0'><tr>\n";
	my @a = split(/,/, $admin->{WEB_OPTIONS}{qm});
  my $i = 0;
	foreach my $line (@a) {
    if (  $i % 6 == 0 && $i > 0) {
      $admin->{QUICK_MENU} .= "</tr>\n<tr>\n";
     }

    my ($qm_id, $qm_name)=split(/:/, $line, 2);
    my $color=($qm_id eq $index) ? 'title_color' : 'even';
    
    $qm_name = $menu_names{$qm_id} if ($qm_name eq '');
    
    $admin->{QUICK_MENU} .= "  <th class='$color'>";
    if (defined($menu_args{$qm_id}) && $menu_args{$qm_id} !~ /=/) {
    	my $args = 'LOGIN' if ($menu_args{$qm_id} eq 'UID');
      $admin->{QUICK_MENU} .= $html->button("$qm_name", '', 
         { JAVASCRIPT => "javascript: Q=prompt('$menu_names{$qm_id}',''); ".
         	               "if (Q != null) {  Q='". "&$args='+Q;  }else{Q = ''; } ".
         	               " this.location.href='$SELF_URL?index=$qm_id'+Q;" 
         	           });
     }
    else {
    	my $args = ($menu_args{$qm_id} =~ /=/) ? "&$menu_args{$qm_id}" : '';
      $admin->{QUICK_MENU} .= $html->button($qm_name, "index=$qm_id$args");
     } 
     
    $admin->{QUICK_MENU} .= "  </th>\n";
	  $i++;
	 }
  
  $admin->{QUICK_MENU} .= "</tr></table>\n</td></tr>\n";
}

print $html->tpl_show(templates('header'), $admin, { OUTPUT2RETURN => 1 });
print $admin->{QUICK_MENU} if ($admin->{QUICK_MENU});

print "<tr  class='noprint'><td valign='top' rowspan='2' class='MENU_BACK'>
$menu_text
</td><td style='height: 20px;' class='noprint, title_color'>$navigat_menu</td></tr>
<tr class='CONTENT'><td valign='top' align='center'>";

if ($functions{$index}) {
  if(defined($module{$index})) {
 	 	load_module($module{$index}, $html);
   }
 	  
  if(($FORM{UID} && $FORM{UID} > 0) || ($FORM{LOGIN} && $FORM{LOGIN} ne ''  && $FORM{LOGIN} !~ /\*/ && ! $FORM{add})) {
  	print $ui->{TABLE_SHOW};

  	if($ui->{errno}==2) {
  		$html->message('err', $_ERROR, "[$FORM{UID}] $_USER_NOT_EXIST")
  	 }
    elsif ($admin->{GIDS} &&  $admin->{GIDS} !~ /$ui->{GID}/ ) {
    	$html->message('err', $_ERROR, "[$FORM{UID}] $_USER_NOT_EXIST GID: $admin->{GIDS} / $ui->{GID}")
     }
  	else {
  	  $functions{$index}->({ USER_INFO => $ui });
  	}
   }
  elsif ($index == 0) {
  	form_start();
   }
  else {
    $functions{$index}->();
   }
}
else {
  $html->message('err', $_ERROR,  "Function not exist ($index / $functions{$index})");	
}


if ($begin_time > 0) {
  my $end_time = gettimeofday;
  my $gen_time = $end_time - $begin_time;
  my $uptime   = `uptime`;
  $admin->{VERSION} = $conf{version} . " (GT: ". sprintf("%.6f", $gen_time). ") <b class='noprint'>UP: $uptime</b>";
}

print "</td></tr>";
print $html->tpl_show(templates('footer'), $admin, { OUTPUT2RETURN => 1 });
print "</table>\n";
$html->test();




#**********************************************************
#
# check_permissions()
#**********************************************************
sub check_permissions {
  my ($login, $password, $attr)=@_;


  if ($conf{ADMINS_ALLOW_IP}) {
  	$conf{ADMINS_ALLOW_IP} =~ s/ //g;
  	my @allow_ips_arr  = split(/,/, $conf{ADMINS_ALLOW_IP});
  	my $allow_ips_hash = ();
  	foreach my $ip (@allow_ips_arr) {
  		$allow_ips_hash{$ip}=1; 		
  	 }
  	if (! $allow_ips_hash{$ENV{REMOTE_ADDR}})  {
      $admin->system_action_add("$login:$password DENY IP: $ENV{REMOTE_ADDR}", { TYPE => 11 });
      $admin->{errno} = 3;
  		return 3;
  	 }
   }


  $login    =~ s/"/\\"/g;
  $login    =~ s/'/\''/g;
  $password =~ s/"/\\"/g;
  $password =~ s/'/\\'/g;

  my %PARAMS = ( LOGIN     => "$login", 
                 PASSWORD  => "$password",
                 SECRETKEY => $conf{secretkey},
                 IP        => $ENV{REMOTE_ADDR} || '0.0.0.0'
                );


  $admin->info(0, { %PARAMS } );
  if ($admin->{errno}) {
    if ($admin->{errno} == 4) {
      $admin->system_action_add("$login:$password", { TYPE => 11 });
      $admin->{errno} = 4;
     }
    return 1;
   }
  elsif($admin->{DISABLE} == 1) {
  	$admin->{errno}=2;
  	$admin->{errstr} = 'DISABLED';
  	return 2;
   }

  
  if ($admin->{WEB_OPTIONS}) {
    my @WO_ARR = split(/;/, $admin->{WEB_OPTIONS}	);
    foreach my $line (@WO_ARR) {
    	my ($k, $v)=split(/=/, $line);
    	$admin->{WEB_OPTIONS}{$k}=$v;
     }
   }
  
  %permissions = %{ $admin->get_permissions() };
  return 0;
}


#**********************************************************
# Start form
#**********************************************************
sub form_start {

return 0 if ($FORM{'xml'} && $FORM{'xml'} == 1);

my  %new_hash = ();

while((my($findex, $hash)=each(%menu_items))) {
   while(my($parent, $val)=each %$hash) {
     $new_hash{$parent}{$findex}=$val;
    }
}

my @menu_sorted = sort {
  $b <=> $a
} keys %{ $new_hash{0} };

my $table2 = $html->table({ width    => '100%',
	                          border   => 0 
	                        });

$table2->{rowcolor}='row_active';

my $table;
my @rows = ();

for(my $parent=1; $parent<$#menu_sorted; $parent++) { 
  my $val = $new_hash{0}{$parent};
  $table->{rowcolor}='row_active';

  if (! defined($permissions{($parent-1)})) {
  	next;
   }

  if ($parent != 0) {
    $table = $html->table({ width       => '200',
                            title_plain => [ $html->button($html->b($val), "index=$parent") ],
                            border      => 1,
                            cols_align  => ['left']
                          });
   }

  if (defined($new_hash{$parent})) {
    $table->{rowcolor}='odd';
    my $mi = $new_hash{$parent};

      foreach my $k ( sort keys %$mi) {
        $val=$mi->{$k};
        $table->addrow("&nbsp;&nbsp;&nbsp; ". $html->button($val, "index=$k"));
        delete($new_hash{$parent}{$k});
      }
  }

  push @rows, $table->td($table->show(), { bgcolor => $_COLORS[1], valign => 'top', align => 'center' });

  if ($#rows > 1) {
    $table2->addtd(@rows);
    undef @rows;
   }
}

$table2->addtd(@rows);
print $table2->show();
}


#**********************************************************
# 1.	Регистрация пользователя (изменение набора реквизитов персональной информации о пользователе);
# 2.	Подключение  пользователю Интернет-тарифа;
# 3.	Подключение набора периодических сервисов;
# 4.	Регистрация набора одноразовых сервисов;
# 5.	Генерация первого инвойса.
# 6.	Генерация договора.
# 7.	Создание тикета на подключение
#**********************************************************
sub form_wizard {
  my ($attr) = @_;


# Function name:module:describe
my %steps = (
  1 =>  "user_form::$_ADD $_USER",
  2 =>  "form_payments::$_PAYMENTS",
  5 =>  "form_fees_wizard::$_FEES",
);

$index = get_function_index('form_wizard');

$steps{3}= 'dv_user:Dv:Internet' if (in_array('Dv', \@MODULES));
$steps{4}= "abon_user:Abon:$_ABON" if (in_array('Abon', \@MODULES));
$steps{6}= "msgs_admin_add:Msgs:$_MESSAGES" if (in_array('Msgs', \@MODULES));


if ($conf{REG_WIZARD}) {
	$conf{REG_WIZARD}=~s/[\r\n]+//g;
	%steps=();
	my @arr  = split(/;/, ';'.$conf{REG_WIZARD});
	for(my $i=1; $i<=$#arr; $i++) {
		$steps{$i}=$arr[$i];
	 }
}




my $return=0;
my $reg_output = '';
START:
delete $FORM{OP_SID};
if (! $FORM{step}) {
  $FORM{step}= 1;
 }
elsif ($FORM{back}) {
	$FORM{step}=$FORM{step}-2;
 }
elsif ($FORM{update}) {
	$FORM{step}--;
	$FORM{back}=1;
}

  if ($FORM{UID}) {
  	$LIST_PARAMS{UID}=$FORM{UID};
  	$users->info($FORM{UID});
  	$users->pi({ UID => $FORM{UID} });
   }
  #Make functions
  if($FORM{step} > 1 && ! $FORM{back}) {
      $html->{NO_PRINT}=1;
      REG:
 	  	$db->{AutoCommit} = 0;
    	my $step=$FORM{step}-1;
    	my ($fn, $module, $describe)=split(/:/, $steps{$step}, 3);
    	
  		if ($module) {
  			if (in_array($module, \@MODULES)) {
          load_module($module, $html);
         }
        else {
        	next;
         } 
       }

      if (! $FORM{change}) {
 	      $FORM{add} = 1 ;
 	     }
 	    else {
 	    	$FORM{next} = 1 ;
 	     }

 	    $FORM{UID} = $LIST_PARAMS{UID} if (! $FORM{UID} && $LIST_PARAMS{UID});
    	#while(my($k, $v)=each %FORM) {
    	#	print "$k, $v<br>";
    	# }
    	$return = $fn->({ REGISTRATION => 1, USER_INFO => ($FORM{UID}) ? $users : undef });
    	$LIST_PARAMS{UID}=$FORM{UID};
    	# Error
    	if ($return) {
    		$db->rollback();
    		$FORM{step}+=1;
    		$FORM{back}=1;
    		$html->{NO_PRINT}=undef; 
 		    undef $FORM{add} ;
        undef $FORM{change} ;
        $reg_output = $html->{OUTPUT};
    		goto START;
    	 }
      else {
        $db->commit();
       }
    undef $FORM{add} ;
    undef $FORM{change} ;
    
    $html->{NO_PRINT}=undef; 
    $reg_output = $html->{OUTPUT};
   }


  # Make navigate menu
  my $table = $html->table({ width      => '100%',
                             border     => 1,
                           });
  	
    my ($fn, $module, $describe)=split(/:/, $steps{$FORM{step}}, 3);
    my @rows = ();
    $table->{rowcolor}=$_COLORS[1];
    foreach my $i ( sort keys %steps ) {
    	 my ($fn, $module, $describe)=split(/:/, $steps{$i}, 3);
       if ($i<$FORM{step}) {
         push @rows, $table->th($html->button("$_STEP: $i $describe", "index=$index&back=1&UID=$FORM{UID}&step=".($i+2)));
        }
       elsif ($i == $FORM{step}) {
         push @rows, $table->th("$_STEP: $i $describe", { class => 'table_title' });
        }
       else{
       	 push @rows, $table->th("$_STEP $i: ".$describe, { class => 'even' });
        }
     }
    $table->addtd( @rows );
    if ($FORM{finish}) {
    	$reg_output='';;
     }
    print $table->show().$reg_output; # if (! $return);

    if (! $steps{$FORM{step}} || $FORM{finish} || (! $FORM{next} && $FORM{step} == 2 && ! $FORM{back})) { # && ! $FORM{back})) {
      $html->message('info', $_INFO, "$_REGISTRATION_COMPLETE");
      undef $FORM{UID};
      undef $FORM{LOGIN};
      form_users();
      return 0;
     }


  	if ($module) {
  		if (in_array($module, \@MODULES)) {
        load_module($module, $html);
       }
      else {
      	$FORM{step}++;
      	goto START;
       }
  	 }



    $FORM{step}++;
 	  $fn->({ %FORM,
 	  	      ACTION      => 'next',
 	  	      REGISTRATION=> 1,
 	  	      #USER        => \%FORM,
 	  	      USER_INFO   => ($FORM{UID}) ? $users : undef,
 	  	      LNG_ACTION  => ($steps{$FORM{step}}) ? "$_NEXT " : "$_REGISTRATION_COMPLETE",
 	  	      BACK_BUTTON => ($FORM{step} > 2) ? $html->form_input('finish', "$_FINISH", {  TYPE => 'submit' }).' '. $html->form_input('back', "$_BACK", {  TYPE => 'submit' }) : (! $FORM{back}) ? $html->form_input('add', "$_FINISH", {  TYPE => 'submit' }) : $html->form_input('change', "$_FINISH", {  TYPE => 'submit' }),
 	  	      UID         => $FORM{UID},
 	  	      SUBJECT     => $_REGISTRATION
 	  	     });
#   }
}

#**********************************************************
#
#**********************************************************
#sub form_user_wizard {
#  my ($attr)=@_;
#  
#  
#  my $main_account = $html->tpl_show(templates('form_user'), $user_info, { OUTPUT2RETURN => 1 });
#  $main_account =~ s/<FORM.+>//ig;
#  $main_account =~ s/<\/FORM>//ig;
#  $main_account =~ s/<input.+type=submit.+>//ig;
#  $main_account =~ s/<input.+index.+>//ig;
#  $main_account =~ s/user_form/users_pi/ig;
#   
#  $html->tpl_show(templates('form_pi'), { %$user_info, MAIN_USER_TPL => $main_account }); 
#  
#  return 0;
#}



#**********************************************************
#
#**********************************************************
sub form_companies {
  my ($attr)=@_;

  use Customers;	
  my $customer = Customers->new($db, $admin, \%conf);
  my $company = $customer->company();
  
  
if ($FORM{add}) {
  if (! $permissions{0}{1} ) {
    $html->message('err', $_ERROR, "$ERR_ACCESS_DENY");  	
    return 0;
   }

  $company->add({ %FORM });
 
  if (! $company->{errno}) {
    $html->message('info', $_ADDED, "$_ADDED ". $html->button("$FORM{COMPANY_NAME}", 'index=13&COMPANY_ID='.$company->{COMPANY_ID}));
   }
 }
elsif ($FORM{import}) {
  if (! $permissions{0}{1} ) {
    $html->message('err', $_ERROR, "$ERR_ACCESS_DENY");  	
    return 0;
   }

   #Create service cards from file
   my $imported = 0;
   my $impoted_named = '';
   if(defined($FORM{FILE_DATA})) {
      	my @rows = split(/[\r]{0,1}\n/, $FORM{"FILE_DATA"}{'Contents'});

        foreach my $line (@rows) {
        	 my @params    = split(/\t/, $line);
        	 my %USER_HASH = (CREATE_BILL  => 1,
        	                  COMPANY_NAME => $params[0]);

           next if ($USER_HASH{COMPANY_NAME} eq '');
            
           for(my $i=1; $i<=$#params; $i++) {
           	 my($k, $v)=split(/=/, $params[$i], 2);
           	 $v =~ s/\"//g;
           	 $USER_HASH{$k}=$v;
            }
          $impoted_named .= "$USER_HASH{COMPANY_NAME}\n";
          $imported++;
          $USER_HASH{COMPANY_NAME}=~s/'/\\'/g;
          
          $company->add({ %USER_HASH });
          if ($company->{errno}) {
            $html->message('err', $_ERROR, "Line:$impoted_named  '$USER_HASH{COMPANY_NAME}' [$company->{errno}] $err_strs{$company->{errno}}");
            return 0;
           }
         }         

      	my $message = "$_FILE $_NAME:  $FORM{FILE_DATA}{filename}\n".
                   "$_TOTAL:  $imported\n".
                   "$_SIZE: $FORM{FILE_DATA}{Size}\n".
                   "$impoted_named\n";

      	$html->message('info', $_INFO, "$message");
    }
 }
elsif($FORM{change}) {
  if (! $permissions{0}{4} ) {
    $html->message('err', $_ERROR, "$ERR_ACCESS_DENY");  	
    return 0;
   }

  $company->change({ %FORM });

  if (! $company->{errno}) {
    $html->message('info', $_INFO, $_CHANGED. " # $company->{ACCOUNT_NAME}");
    goto INFO;  	 
   }
 }
elsif($FORM{COMPANY_ID}) {
  
  INFO:
  $company->info($FORM{COMPANY_ID});
  #print contract
  if ($FORM{PRINT_CONTRACT}) {
    load_module('Docs', $html);
    docs_contract({ COMPANY_CONTRACT => 1, %$company });
  	return 0;
   }

  $LIST_PARAMS{COMPANY_ID}=$FORM{COMPANY_ID};
  $LIST_PARAMS{BILL_ID}=$company->{BILL_ID};
  $pages_qs .= "&COMPANY_ID=$FORM{COMPANY_ID}";
  $pages_qs .= "&subf=$FORM{subf}";
  if (in_array('Docs', \@MODULES) ) {
    $company->{PRINT_CONTRACT} = $html->button("$_PRINT", "qindex=$index&COMPANY_ID=$FORM{COMPANY_ID}&PRINT_CONTRACT=$FORM{COMPANY_ID}". (($conf{DOCS_PDF_PRINT}) ? '&pdf=1' : '' ), { ex_params => ' target=new', CLASS => 'print rightAlignText' }) ;
   }

  func_menu({ 
  	         'ID'   => $company->{COMPANY_ID}, 
  	         $_NAME => $company->{COMPANY_NAME}
  	       }, 
  	{ 
  	 $_INFO     => ":COMPANY_ID=$company->{COMPANY_ID}",
     $_USERS    => "11:COMPANY_ID=$company->{COMPANY_ID}",
     $_PAYMENTS => "2:COMPANY_ID=$company->{COMPANY_ID}",
     $_FEES     => "3:COMPANY_ID=$company->{COMPANY_ID}",
     $_ADD_USER => "24:COMPANY_ID=$FORM{COMPANY_ID}",
     $_BILL     => "19:COMPANY_ID=$FORM{COMPANY_ID}"
  	 },
  	 {
  	 	 f_args => { COMPANY => $company }
  	 	} 
  	 );

   #Sub functions
  if (! $FORM{subf}) {
    if ($permissions{0}{4} ) {
      $company->{ACTION}='change';
      $company->{LNG_ACTION}=$_CHANGE;
     }
    $company->{DISABLE} = ($company->{DISABLE} > 0) ? 'checked' : '';
    
    if ($conf{EXT_BILL_ACCOUNT} && $company->{EXT_BILL_ID}) {
      $company->{EXDATA} = $html->tpl_show(templates('form_ext_bill'), $company, { OUTPUT2RETURN => 1 });
     }
    
#Info fields
    my $i=0; 
    foreach my $field_id ( @{ $company->{INFO_FIELDS_ARR} } ) {
      my($position, $type, $name)=split(/:/, $company->{INFO_FIELDS_HASH}->{$field_id});

      my $input = '';
      if ($type == 2) {
        $input = $html->form_select("$field_id", 
                                { SELECTED          => $company->{INFO_FIELDS_VAL}->[$i],
 	                                SEL_MULTI_ARRAY   => $users->info_lists_list( { LIST_TABLE => $field_id.'_list' }), 
 	                                MULTI_ARRAY_KEY   => 0,
 	                                MULTI_ARRAY_VALUE => 1,
 	                                SEL_OPTIONS       => { 0 => '-N/S-'},
 	                                NO_ID             => 1
 	                               });
    	
       }
      elsif ($type == 4) {
    	  $input = $html->form_input($field_id, 1, { TYPE  => 'checkbox',  
    		                                           STATE => ($company->{INFO_FIELDS_VAL}->[$i]) ? 1 : undef  });
       }
      elsif ($type == 3) {
        $input = $html->form_textarea($field_id, "$company->{INFO_FIELDS_VAL}->[$i]");
       }
      elsif ($type == 13) {
        $input = $html->form_input($field_id, "$company->{INFO_FIELDS_VAL}->[$i]", { TYPE => 'file' });
        if ($company->{INFO_FIELDS_VAL}->[$i]) {
        	$users->attachment_info({ ID => $company->{INFO_FIELDS_VAL}->[$i], TABLE => $field_id.'_file' });
          $input .= ' '. $html->button("$users->{FILENAME}, ". int2byte($users->{FILESIZE}), "qindex=". get_function_index('user_pi') ."&ATTACHMENT=$field_id:$company->{INFO_FIELDS_VAL}->[$i]", { BUTTON => 1 });
         }
       }
      else {
    	  $input = $html->form_input($field_id, "$company->{INFO_FIELDS_VAL}->[$i]", { SIZE => 40 });
       }
  	  $company->{INFO_FIELDS}.= "<tr><td>$name:</td><td>$input</td></tr>\n";
      $i++;
     }

    $company->{CONTRACT_DATE} = $html->date_fld2('CONTRACT_DATE', { FORM_NAME => 'company',
  	                                                              WEEK_DAYS => \@WEEKDAYS,
  	                                                              MONTHES   => \@MONTHES,
  	                                                              DATE      => $company->{CONTRACT_DATE} });

  if (in_array('Docs', \@MODULES) ) {
    if ($conf{DOCS_CONTRACT_TYPES}) {
    	$conf{DOCS_CONTRACT_TYPES} =~ s/\n//g;
      my (@contract_types_list)=split(/;/, $conf{DOCS_CONTRACT_TYPES});

      my %CONTRACTS_LIST_HASH = ();
      $FORM{CONTRACT_SUFIX}="|$company->{CONTRACT_SUFIX}";
      foreach my $line (@contract_types_list) {
      	my ($prefix, $sufix, $name, $tpl_name)=split(/:/, $line);
      	$prefix =~ s/ //g;
      	$CONTRACTS_LIST_HASH{"$prefix|$sufix"}=$name;
       }

      $company->{CONTRACT_TYPE}=" $_TYPE: ".$html->form_select('CONTRACT_TYPE', 
                                { SELECTED   => $FORM{CONTRACT_SUFIX},
 	                                SEL_HASH   => {'' => '', %CONTRACTS_LIST_HASH },
 	                                NO_ID      => 1
 	                               });
     }
   }

    $html->tpl_show(templates('form_company'), $company);
  }


  
 }
elsif($FORM{del} && $FORM{is_js_confirmed}  && $permissions{0}{5} ) {
   $company->del( $FORM{del} );
   $html->message('info', $_INFO, "$_DELETED # $FORM{del}");
 }
else {
	
	if ($FORM{letter}) {
    $LIST_PARAMS{COMPANY_NAME} = "$FORM{letter}*";
    $pages_qs .= "&letter=$FORM{letter}";
   }
	print $html->letters_list({ pages_qs => $pages_qs  }); 

  my $list = $company->list( { %LIST_PARAMS } );
  my $table = $html->table( { width      => '100%',
                              caption    => $_COMPANIES,
                              border     => 1,
                              title      => [$_NAME, $_DEPOSIT, $_REGISTRATION, $_USERS, $_STATUS, '-', '-'],
                              cols_align => ['left', 'right', 'right', 'right', 'center', 'center'],
                              pages      => $company->{TOTAL},
                              qs         => $pages_qs,
                              ID         => 'COMPANY_ID',
                              EXPORT     => ' XML:&xml=1',
                            } );


  foreach my $line (@$list) {
    $table->addrow($line->[0],  
      $line->[1], 
      $line->[2], 
      $html->button($line->[3], "index=13&COMPANY_ID=$line->[5]&subf=11"), 
      "$status[$line->[4]]",
      $html->button($_INFO, "index=13&COMPANY_ID=$line->[5]", { CLASS => 'change' }), 
      (defined($permissions{0}{5})) ? $html->button($_DEL, "index=13&del=$line->[5]", { MESSAGE => "$_DEL $line->[0]?", CLASS => 'del' }) : ''
      );
   }
  print $table->show();

  $table = $html->table( { width      => '100%',
                           cols_align => ['right', 'right'],
                           rows       => [ [ "$_TOTAL:", $html->b($company->{TOTAL}) ] ]
                       } );
  print $table->show();

  if (! $FORM{search}  ) {
    print $html->form_main({ CONTENT => "$_FILE: ".$html->form_input('FILE_DATA', '', { TYPE => 'file' }),
  	                       ENCTYPE => 'multipart/form-data',
	                         HIDDEN  => { index      => $index, 
	                       	            },
	                         SUBMIT  => { import   => "$_IMPORT"
	                       	           } });
   }
}
  if ($company->{errno}) {
    $html->message('info', $_ERROR, "[$company->{errno}] $err_strs{$company->{errno}}");
   }

}

#**********************************************************
# Functions menu
#**********************************************************
sub form_companie_admins {
 my ($attr) = @_;

 my $customer = Customers->new($db, $admin, \%conf);
 my $company = $customer->company();

 if ($FORM{change}) {
 	  ADD_ADMIN:
    $company->admins_change({ %FORM });
    if (! $company->{errno}) {
      $html->message('info', $_INFO, "$_CHANGED");
     }
    if ($attr->{REGISTRATION}) {
    	 return 0;
     }
   }

 if ($company->{errno}) {
   $html->message('err', $_ERROR, "[company->{errno}] $err_strs{$company->{errno}}");	
  }

my $table = $html->table( { width      => '100%',
                            caption    => "$_ADMINS",
                            border     => 1,
                            title      => ["$_ALLOW", "$_LOGIN", "$_FIO", 'E-mail'],
                            cols_align => ['right', 'left', 'left', 'left' ],
                            qs         => $pages_qs,
                            ID         => 'COMPANY_ADMINS'
                           });

if (! defined($FORM{sort})) {
  $LIST_PARAMS{SORT}=2;
 }


my $list = $company->admins_list({ COMPANY_ID => $FORM{COMPANY_ID}, 
	                                 PAGE_ROWS  => 10000 
	                                 });

if ($attr->{REGISTRATION})  {
  if ($FORM{add} && $company->{TOTAL}==1 && ! $list->[0]->[0]) {
	  $FORM{IDS}=$FORM{UID};
	  goto ADD_ADMIN;
	 }
	return 0;
}

foreach my $line (@$list) {
  $table->addrow($html->form_input('IDS', "$line->[4]", 
                                                   { TYPE          => 'checkbox',
  	                                                 OUTPUT2RETURN => 1,
       	                                             STATE         => ($line->[0]) ? 1 : undef
       	                                          }), 
    user_ext_menu($line->[4], $line->[1]),
    $line->[2],
    $line->[3]
    );
}

print $html->form_main({ CONTENT => $table->show({ OUTPUT2RETURN => 1 }),
	                       HIDDEN  => { index      => $index, 
	                       	            COMPANY_ID => $FORM{COMPANY_ID} },
	                       SUBMIT  => { change   => "$_CHANGE"
	                       	           } });
}


#**********************************************************
# Functions menu
#**********************************************************
sub func_menu {
  my ($header, $items, $f_args)=@_; 
 
  return '' if ($FORM{pdf});
 
print "<TABLE width=\"100%\" bgcolor=\"$_COLORS[2]\">\n";

while(my($k, $v)=each %$header) {
  print "<tr><td>$k: </td><td valign=top>$v</td></tr>\n";
}
print "<tr bgcolor=\"$_COLORS[1]\"><td colspan=\"2\">\n";

my $menu;
#while(my($name, $v)=each  %$items) {
foreach my $name (sort {$items->{$a} cmp $items->{$b}} keys %$items) {
  my $v = $items->{$name};
  my ($subf, $ext_url, $class)=split(/:/, $v, 3);
  $menu .= ($FORM{subf} && $FORM{subf} eq $subf) ? ' '. $html->b($name) : ' '. $html->button($name, "index=$index&$ext_url&subf=$subf", { ($class) ? (CLASS => $class)  : (BUTTON => 1)  });
}

print "$menu</td></tr>
</TABLE>\n";

if ($FORM{subf}) {
  if ($functions{$FORM{subf}}) {
    if(defined($module{$FORM{subf}})) {
    	load_module($module{$FORM{subf}}, $html);
     }

    $functions{$FORM{subf}}->($f_args->{f_args});
   }
  else {
  	$html->message('err', $_ERROR, "Function not Defined");
   }
 } 
}

#**********************************************************
# add_company()
#**********************************************************
sub add_company {
  my $company;
  $company->{ACTION}='add';
  $company->{LNG_ACTION}=$_ADD;
  $company->{BILL_ID}=$html->form_input('CREATE_BILL', 1, { TYPE => 'checkbox', STATE => 1 }) . ' ' .$_CREATE;

  my $list = $users->config_list({ PARAM => 'ifc*', SORT => 2 });

  foreach my $line (@$list) {
    my $field_id       = '';

    if ($line->[0] =~ /ifc(\S+)/) {
    	$field_id = $1;
     }

    my($position, $type, $name)=split(/:/, $line->[1]);
    my $input = '';
    if ($type == 2) {
        $input = $html->form_select("$field_id", 
                                { SELECTED          => undef,
 	                                SEL_MULTI_ARRAY   => $users->info_lists_list( { LIST_TABLE => $field_id.'_list' }), 
 	                                MULTI_ARRAY_KEY   => 0,
 	                                MULTI_ARRAY_VALUE => 1,
 	                                SEL_OPTIONS       => { 0 => '-N/S-' },
 	                                NO_ID             => 1
 	                               });
    	
      }
     elsif ($type == 4) {
   	  $input = $html->form_input($field_id, 1, { TYPE  => 'checkbox',  
   		                                           STATE => ($company->{INFO_FIELDS_VAL}->[$i]) ? 1 : undef  });
      }
     elsif ($type == 3) {
        $input = $html->form_textarea($field_id, "$company->{INFO_FIELDS_VAL}->[$i]");
       }
     elsif ($type == 13) {
        $input = $html->form_input($field_id, "$company->{INFO_FIELDS_VAL}->[$i]", { TYPE => 'file' });
       }
     else {
   	   $input = $html->form_input($field_id, "$company->{INFO_FIELDS_VAL}->[$i]", { SIZE => 40 });
      }
    
  	  $company->{INFO_FIELDS}.= "<tr><td>$name:</td><td>$input</td></tr>\n";
   }


    $company->{CONTRACT_DATE} = $html->date_fld2('CONTRACT_DATE', { FORM_NAME => 'company',
  	                                                              WEEK_DAYS => \@WEEKDAYS,
  	                                                              MONTHES   => \@MONTHES,
  	                                                              DATE      => $company->{CONTRACT_DATE} });

  if (in_array('Docs', \@MODULES) ) {
    $company->{PRINT_CONTRACT} = $html->button("$_PRINT", "qindex=15&UID=$user_pi->{UID}&PRINT_CONTRACT=$user_pi->{UID}". (($conf{DOCS_PDF_PRINT}) ? '&pdf=1' : '' ), { ex_params => ' target=new', CLASS => 'print rightAlignText' }) ;
    
    if ($conf{DOCS_CONTRACT_TYPES}) {
    	$conf{DOCS_CONTRACT_TYPES} =~ s/\n//g;
      my (@contract_types_list)=split(/;/, $conf{DOCS_CONTRACT_TYPES});
      my %CONTRACTS_LIST_HASH = ();
      $FORM{CONTRACT_SUFIX}="|$company->{CONTRACT_SUFIX}";
      foreach my $line (@contract_types_list) {
      	my ($prefix, $sufix, $name, $tpl_name)=split(/:/, $line);
      	$prefix =~ s/ //g;
      	$CONTRACTS_LIST_HASH{"$prefix|$sufix"}=$name;
       }

      $company->{CONTRACT_TYPE}=" $_TYPE: ".$html->form_select('CONTRACT_TYPE', 
                                { SELECTED   => $FORM{CONTRACT_SUFIX},
 	                                SEL_HASH   => {'' => '', %CONTRACTS_LIST_HASH },
 	                                NO_ID      => 1
 	                               });
     }
   }


  
  $html->tpl_show(templates('form_company'), $company);
}



#**********************************************************
# user_form()
#**********************************************************
sub user_form {
 my ($attr) = @_;

	$index = 15 if (! $attr->{ACTION} && ! $attr->{REGISTRATION});

 if ($FORM{add} || $FORM{change}) {
 	 form_users($attr);
  }
 elsif (! $attr->{USER_INFO}) {
   my $user = Users->new($db, $admin, \%conf); 
   $user_info = $user->defaults();

   if ($FORM{COMPANY_ID}) {
     use Customers;	
     my $customers = Customers->new($db, $admin, \%conf);
     my $company   = $customers->company->info($FORM{COMPANY_ID});
 	   $user_info->{COMPANY_ID}=$FORM{COMPANY_ID};
     $user_info->{EXDATA} =  "<tr><td>$_COMPANY:</td><td>". (($company->{COMPANY_ID} > 0) ? $html->button($company->{COMPANY_NAME}, "index=13&COMPANY_ID=$company->{COMPANY_ID}", { BUTTON => 1 }) : '' ). "</td></tr>\n";
    }
   
   if ($admin->{GIDS}) {
   	 $user_info->{GID} = sel_groups();
    }
   elsif ($admin->{GID}) {
   	 $user_info->{GID} .=  $html->form_input('GID', "$admin->{GID}", { TYPE => 'hidden' }); 
    }
   else {
   	 $FORM{GID}=$attr->{GID};
   	 delete $attr->{GID};
   	 $user_info->{GID} = sel_groups();
    }

   $user_info->{EXDATA} .=  $html->tpl_show(templates('form_user_exdata_add'), { %$attr, CREATE_BILL => ' checked'  }, { OUTPUT2RETURN => 1 });
   $user_info->{EXDATA} .=  $html->tpl_show(templates('form_ext_bill_add'), { CREATE_EXT_BILL => ' checked' }, { OUTPUT2RETURN => 1 }) if ($conf{EXT_BILL_ACCOUNT});

   if ($user_info->{DISABLE} > 0) {
     $user_info->{DISABLE}      = ' checked';
     $user_info->{DISABLE_MARK} = $html->color_mark($html->b($_DISABLE), $_COLORS[6]);
    } 
   else {
   	 $user_info->{DISABLE} = '';
    }

   my $main_account = $html->tpl_show(templates('form_user'), { %$user_info, %$attr  }, { OUTPUT2RETURN => 1 });
   $main_account .= $html->tpl_show(templates('form_password'), { %$user_info, %$attr  }, { OUTPUT2RETURN => 1 });

   $main_account =~ s/<FORM.+>//ig;
   $main_account =~ s/<\/FORM>//ig;
   $main_account =~ s/<input.+type=submit.+>//ig;
   $main_account =~ s/<input.+index.+>//ig;
   $main_account =~ s/user_form/users_pi/ig;

   user_pi({ MAIN_USER_TPL => $main_account, %$attr });
  }
 else {
	 $user_info = $attr->{USER_INFO};
 	 $FORM{UID} = $user_info->{UID};
   $user_info->{COMPANY_NAME}=$html->color_mark("$_NOT_EXIST ID: $user_info->{COMPANY_ID}", $_COLORS[6]) if ($user_info->{COMPANY_ID} && ! $user_info->{COMPANY_NAME}) ;

   $user_info->{EXDATA} = $html->tpl_show(templates('form_user_exdata'), 
                                          $user_info, { OUTPUT2RETURN => 1 });
   if ($conf{EXT_BILL_ACCOUNT} && $user_info->{EXT_BILL_ID}) {
     $user_info->{EXDATA} .= $html->tpl_show(templates('form_ext_bill'), 
                                             $user_info, { OUTPUT2RETURN => 1 });
    }

   if ($user_info->{DISABLE} > 0) {
     $user_info->{DISABLE} = ' checked';
     $user_info->{DISABLE_MARK} = $html->color_mark($html->b($_DISABLE), $_COLORS[6]);
     
     my $list = $admin->action_list({ UID       => $user_info->{UID},
     	                     TYPE      => 9,
     	                     PAGE_ROWS => 1,
     	                     SORT      => 1,
     	                     DESC      => 'DESC'
     	                     });
     if ($admin->{TOTAL}>0) {
       $user_info->{DISABLE_COMMENTS}=$list->[0][3];
      }
    } 
   else {
   	 $user_info->{DISABLE} = '';
    }


   $user_info->{ACTION}='change';
   $user_info->{LNG_ACTION}=$_CHANGE;

   if ($permissions{5}) {
     my $info_field_index = get_function_index('form_info_fields');
     $user_info->{ADD_INFO_FIELD}=$html->button("$_ADD $_INFO_FIELDS", "index=$info_field_index", { CLASS => 'add rightAlignText', ex_params => ' target=_info_fields' });
    }

   if ($permissions{0}{3}) {
   	 $user_info->{PASSWORD} = ($FORM{SHOW_PASSWORD}) ? "$_PASSWD: '$user_info->{PASSWORD}'" : $html->button("$_SHOW $_PASSWD", "index=$index&UID=$LIST_PARAMS{UID}&SHOW_PASSWORD=1", { BUTTON => 1 }). ' '. $html->button("$_CHANGE $_PASSWD", "index=". get_function_index('form_passwd')  ."&UID=$LIST_PARAMS{UID}", { BUTTON => 1 });
    }
   
   if (in_array('Sms', \@MODULES) ) {
     $user_info->{PASSWORD} .= ' '. $html->button("$_SEND $_PASSWD SMS", "index=$index&header=1&UID=$LIST_PARAMS{UID}&SHOW_PASSWORD=1&SEND_SMS_PASSWORD=1", {  BUTTON => 1, MESSAGE => "$_SEND $_PASSWD SMS ?" });
   }

   if ($attr->{REGISTRATION}) {
 	   my $main_account = $html->tpl_show(templates('form_user'), { %$user_info, %$attr  }, { OUTPUT2RETURN => 1 });
     $main_account =~ s/<FORM.+>//ig;
     $main_account =~ s/<\/FORM>//ig;
     $main_account =~ s/<input.+type=submit.+>//ig;
     $main_account =~ s/<input.+index.+>//ig;
     $main_account =~ s/user_form/users_pi/ig;
     user_pi({ MAIN_USER_TPL => $main_account, %$attr });
    }
   else {
     $html->tpl_show(templates('form_user'), $user_info);
    }
  }

}


#**********************************************************
# form_groups()
#**********************************************************
sub form_groups {

if ($FORM{add}) {
  if (! $permissions{0}{1} ) {
    $html->message('err', $_ERROR, "$ERR_ACCESS_DENY");  	
    return 0;
   }
  elsif ($LIST_PARAMS{GID} || $LIST_PARAMS{GIDS}) {
    $html->message('err', $_ERROR, "$ERR_ACCESS_DENY");
   }
  else {
    $users->group_add( { %FORM });
    if (! $users->{errno}) {
      $html->message('info', $_ADDED, "$_ADDED [$FORM{GID}]");
     }
   }
}
elsif($FORM{change}){
  if (! $permissions{0}{4} ) {
    $html->message('err', $_ERROR, "$ERR_ACCESS_DENY");  	
    return 0;
   }

  $users->group_change($FORM{chg}, { %FORM });
  if (! $users->{errno}) {
    $html->message('info', $_CHANGED, "$_CHANGED $users->{GID}");
   }
}
elsif(defined($FORM{GID})){
  $users->group_info( $FORM{GID} );

  $LIST_PARAMS{GID}=$users->{GID};
  delete $LIST_PARAMS{GIDS};
  $pages_qs="&GID=$users->{GID}&subf=$FORM{subf}";

  func_menu({ 
  	         'ID'   => $users->{GID}, 
  	         $_NAME => $users->{G_NAME}
  	       }, 
  	{ 
     $_CHANGE   => ":GID=$users->{GID}:change rightAlignText",
     $_USERS    => "11:GID=$users->{GID}:users rightAlignText",
     $_PAYMENTS => "2:GID=$users->{GID}:payments rightAlignText",
     $_FEES     => "3:GID=$users->{GID}:fees rightAlignText",
  	 });
  
    if (! $permissions{0}{4} ) {
      return 0;
     }

  $users->{ACTION}='change';
  $users->{LNG_ACTION}=$_CHANGE;
  $users->{SEPARATE_DOCS} = ($users->{SEPARATE_DOCS}) ?  'checked' : '';
  $html->tpl_show(templates('form_groups'), $users);
 
  return 0;
 }
elsif(defined($FORM{del}) && $FORM{is_js_confirmed} && $permissions{0}{5}){
  $users->list({ GID => $FORM{del} });

  if ($users->{TOTAL} > 0) {
    $html->message('info', $_DELETED, "$_USER_EXIST.");
   }
  else {
    $users->group_del( $FORM{del} );
    if (! $users->{errno}) {
      $html->message('info', $_DELETED, "$_DELETED GID: $FORM{del}");
     }
   }
}


if ($users->{errno}) {
   $html->message('err', $_ERROR, "[$users->{errno}] $err_strs{$users->{errno}}");	
  }

my $list = $users->groups_list({ %LIST_PARAMS });
my $table = $html->table( { width      => '100%',
                            caption    => "$_GROUPS",
                            border     => 1,
                            title      => [$_ID, $_NAME, $_DESCRIBE, $_USERS, '-', '-'],
                            cols_align => ['right', 'left', 'left', 'right', 'center', 'center'],
                            qs         => $pages_qs,
                            pages      => $users->{TOTAL},
                            ID         => 'GROUPS'
                       } );

foreach my $line (@$list) {
  my $delete = (defined($permissions{0}{5})) ?  $html->button($_DEL, "index=27$pages_qs&del=$line->[0]", { MESSAGE => "$_DEL [$line->[0]]?", CLASS => 'del' }) : ''; 

  $table->addrow($html->b($line->[0]), 
   "$line->[1]", 
   "$line->[2]", 
   $html->button($line->[3], "index=27&GID=$line->[0]&subf=15"), 
   $html->button($_INFO, "index=27&GID=$line->[0]", { CLASS => 'change' }),
   $delete);
}
print $table->show();


$table = $html->table({ width      => '100%',
                        cols_align => ['right', 'right'],
                        rows       => [ [ "$_TOTAL:", $html->b($users->{TOTAL}) ] ]
                      });
print $table->show();
}



#**********************************************************
# add_groups()
#**********************************************************
sub add_groups {

  return 0 if ($LIST_PARAMS{GID} || $LIST_PARAMS{GIDS});

  my $users;
  $users->{ACTION}='add';
  $users->{LNG_ACTION}=$_ADD;
  $html->tpl_show(templates('form_groups'), $users); 
}

#**********************************************************
#
#**********************************************************
sub user_ext_menu {
	my ($UID, $LOGIN, $attr)=@_;
	

my $payments_menu = (defined($permissions{1})) ? '<li>'. $html->button($_PAYMENTS, "UID=$UID&index=2").'</li>' : '';
my $fees_menu     = (defined($permissions{2})) ? '<li>' .$html->button($_FEES, "UID=$UID&index=3").'</li>' : '';
my $sendmail_manu = '<li>'. $html->button($_SEND_MAIL, "UID=$UID&index=31"). '</li>';

my $second_menu = '';
my %userform_menus = (
             22 =>  $_LOG,
             21 =>  $_COMPANY,
             12 =>  $_GROUP,
             18 =>  $_NAS,
             20 =>  $_SERVICES,
             19	=>  $_BILL
             );

$userform_menus{17}=$_PASSWD if ($permissions{0}{3});

while(my($k, $v)=each %uf_menus) {
	$userform_menus{$k}=$v;
}

  #Make service menu
  my $service_menu       = '';
  my $service_func_index = 0;
  my $service_func_menu  = '';
  foreach my $key ( sort keys %menu_items) {
	  if (defined($menu_items{$key}{20})) {
	  	$service_func_index=$key if (($FORM{MODULE} && $FORM{MODULE} eq $module{$key} || ! $FORM{MODULE}) && $service_func_index == 0);
		  $service_menu .= '<li>'. $html->button($menu_items{$key}{20}, "UID=$UID&index=$key");
	   }
  
   	if ($service_func_index > 0 && $menu_items{$key}{$service_func_index}) {
	  	 $service_func_menu .= $html->button($menu_items{$key}{$service_func_index}, "UID=$UID&index=$key") .' ';
 	 	 }
   }


foreach my $k (sort { $b <=> $a } keys %userform_menus) {
	my $v = $userform_menus{$k};
  my $url =  "index=$k&UID=$UID";
  my $a = (defined($FORM{$k})) ? $html->b($v) : $v;
  $second_menu .= "<li>" . $html->button($a,  "$url").'</li>';
}

my $ext_menu = qq{
<div id=quick_menu class=noprint>
<ul id=topNav>
  <li><a href="#"><img src='/img/user.png' border=0/></a>
  <ul>
    $payments_menu
    $fees_menu
    $sendmail_manu
    <li><a href='#'>Service >> </a>
      <ul>
       $service_menu
      </ul>
    </li>
    <li><a href='#'>$_OTHER >> </a>
      <ul>
        $second_menu
      </ul>
    </li> 
   </ul>
   </li> 
</ul>
</div>
};
  
  
  my $return = $ext_menu; 
  if ($attr->{SHOW_UID}) {
    $return .= ' : '. $html->button($html->b($LOGIN), "index=15&UID=${UID}"). " (UID: $UID) ";
   }
  else {
    $return .= $html->button($LOGIN, "index=15&UID=$UID". (($attr->{EXT_PARAMS}) ? "&$attr->{EXT_PARAMS}" : ''), {  TITLE => $attr->{TITLE}  });
   }
	
	return $return;
}



#**********************************************************
# user_info
#**********************************************************
sub user_info {
  my ($UID)=@_;

	my $user_info = $users->info( $UID , { %FORM });
  my $deleted   = ($user_info->{DELETED}) ? $html->color_mark($html->b($_DELETED), '#FF0000') : '';
  my $ext_menu  = user_ext_menu($user_info->{UID}, $user_info->{LOGIN}, { SHOW_UID => 1 });
  
  $table = $html->table({ width      => '100%',
  	                      rowcolor   => 'even',
  	                      border     => 0,
                          cols_align => ['left:noprint'],
                          rows       => [ [ "$ext_menu".  $deleted ] ],
                          class      => 'form',
                        });

  $user_info->{TABLE_SHOW} = $table->show();
  $LIST_PARAMS{UID}=$user_info->{UID};
  $pages_qs =  "&UID=$user_info->{UID}";
  $pages_qs .= "&subf=$FORM{subf}" if (defined($FORM{subf}));
  
  return 	$user_info;
}



#**********************************************************
#
#**********************************************************
sub form_show_attach {
  my ($attr) = @_;


  if ($FORM{ATTACHMENT} =~ /(.+):(.+)/) {
  	$FORM{TABLE}     = $1.'_file';
  	$FORM{ATTACHMENT}= $2;
   }

	$users->attachment_info({ ID    => $FORM{ATTACHMENT},
		                        TABLE => $FORM{TABLE}, 
				                    UID   => $user->{UID} });

  if ($users->{TOTAL}==0) {
    print "Content-Type: text/html\n\n";
  	print "$_ERROR: $_ATTACHMENT $_NOT_EXIST\n";  	
  	return 0;
   }
  	
  print "Content-Type: $users->{CONTENT_TYPE}; filename=\"$users->{FILENAME}\"\n".
  "Content-Disposition: attachment; filename=\"$users->{FILENAME};\" size=$users->{FILESIZE};".
  "\n\n";
  print "$users->{CONTENT}";
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
       	 $line->[1]=~s/\'/&rsquo;/g;
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
     my $list = $users->street_list({ DISTRICT_ID => $FORM{DISTRICT_ID}, PAGE_ROWS => 1000, SORT => 2 });
     if ($users->{TOTAL} > 0) {
       foreach my $line (@$list) {
       	 $line->[1]=~s/\'/&rsquo;/g;
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
#
#**********************************************************
sub user_pi {
  my ($attr) = @_;

  my $user;
  if ($attr->{USER_INFO}) {
    $user = $attr->{USER_INFO};
   }
  else {
  	$user = $users->info( $FORM{UID} );
   }
 
 if ($FORM{ATTACHMENT}) {
 	  form_show_attach();
 	  return 0;
  }
 elsif ($FORM{address}) {
   form_address_sel();
  } 
 elsif($FORM{add}) {
   if (! $permissions{0}{1} ) {
      $html->message('err', $_ERROR, "$ERR_ACCESS_DENY");  	
    	return 0;
    }

 	 my $user_pi = $user->pi_add({ %FORM });
   if (! $user_pi->{errno}) {
   	return 0 if ($attr->{REGISTRATION});
    $html->message('info', $_ADDED, "$_ADDED");	
   }
  }
 elsif($FORM{change}) {
   if (! $permissions{0}{4} ) {
      $html->message('err', $_ERROR, "$ERR_ACCESS_DENY");  	
    	return 0;
    }


 	 my $user_pi = $user->pi_change({ %FORM });
   if (! $user_pi->{errno}) {
    $html->message('info', $_CHAGED, "$_CHANGED");	
   }
 }

  if ($user_pi->{errno}) {
    $html->message('err', $_ERROR, "[$user_pi->{errno}] $err_strs{$user_pi->{errno}}");	
   }

  my $user_pi = $user->pi();

  if($user_pi->{TOTAL} < 1 && $permissions{0}{1}) {
    if ($attr->{ACTION}) {
      $user_pi->{ACTION}    = $attr->{ACTION};
      $user_pi->{LNG_ACTION}= $attr->{LNG_ACTION};
     }
    else {
  	  $user_pi->{ACTION}='add';
   	  $user_pi->{LNG_ACTION}=$_ADD;
     }
   }
  elsif($permissions{0}{4}) {
    if ($attr->{ACTION}) {
      $user_pi->{ACTION}    = $attr->{ACTION};
      $user_pi->{LNG_ACTION}= $attr->{LNG_ACTION};
     }
    else {
 	    $user_pi->{ACTION}='change';
	    $user_pi->{LNG_ACTION}=$_CHANGE;
	   }
    $user_pi->{ACTION}='change'; 
   }


  #Info fields
  my $i=0; 
  foreach my $field_id ( @{ $user_pi->{INFO_FIELDS_ARR} } ) {
    my($position, $type, $name, $user_portal)=split(/:/, $user_pi->{INFO_FIELDS_HASH}->{$field_id});

    my $input = '';
    if ($type == 2) {
      $input = $html->form_select("$field_id", 
                                { SELECTED          => $user_pi->{INFO_FIELDS_VAL}->[$i],
 	                                SEL_MULTI_ARRAY   => $user->info_lists_list( { LIST_TABLE => $field_id.'_list' }), 
 	                                MULTI_ARRAY_KEY   => 0,
 	                                MULTI_ARRAY_VALUE => 1,
 	                                SEL_OPTIONS       => { 0 => '-N/S-'},
 	                                NO_ID             => 1
 	                               });
    	
     }
    elsif ($type == 4) {
    	$input = $html->form_input($field_id, 1, { TYPE  => 'checkbox',  
    		                                         STATE => ($user_pi->{INFO_FIELDS_VAL}->[$i]) ? 1 : undef  });
     }
    #'ICQ', 
    elsif ($type == 8) {
    	$input = $html->form_input($field_id, "$user_pi->{INFO_FIELDS_VAL}->[$i]", { SIZE => 10 });
    	if ($user_pi->{INFO_FIELDS_VAL}->[$i] ne '') {
    		#
    	  $input .= " <a href=\"http://www.icq.com/people/about_me.php?uin=$user_pi->{INFO_FIELDS_VAL}->[$i]\"><img  src=\"http://status.icq.com/online.gif?icq=$user_pi->{INFO_FIELDS_VAL}->[$i]&img=21\" border=0></a>";
    	 }
     }
    #'URL', 
    elsif ($type == 9) {
    	$input = $html->form_input($field_id, "$user_pi->{INFO_FIELDS_VAL}->[$i]", { SIZE => 35 }) . $html->button("$_GO", "", { 
    		 GLOBAL_URL => "$user_pi->{INFO_FIELDS_VAL}->[$i]",
    		 ex_params  => ' target='.$user_pi->{INFO_FIELDS_VAL}->[$i], 
    		 BUTTON     =>  1 });
     }
    #'PHONE', 
    #'E-Mail'
    #'SKYPE'
    elsif ($type == 12) {
      $input = $html->form_input($field_id, "$user_pi->{INFO_FIELDS_VAL}->[$i]", { SIZE => 20 });
      if ($user_pi->{INFO_FIELDS_VAL}->[$i] ne '') {
        $input .= qq{  <script type="text/javascript" src="http://download.skype.com/share/skypebuttons/js/skypeCheck.js"></script>  <a href="skype:abills.support?call"><img src="http://mystatus.skype.com/smallclassic/$user_pi->{INFO_FIELDS_VAL}->[$i]" style="border: none;" width="114" height="20"/></a>};
       }
     }
    elsif ($type == 3) {
      $input = $html->form_textarea($field_id, "$user_pi->{INFO_FIELDS_VAL}->[$i]");
     }
    elsif ($type == 13) {
      $input = $html->form_input($field_id, "$user_pi->{INFO_FIELDS_VAL}->[$i]", { TYPE => 'file' });
      if ($user_pi->{INFO_FIELDS_VAL}->[$i]) {
      	$user_pi->attachment_info({ ID => $user_pi->{INFO_FIELDS_VAL}->[$i], TABLE => $field_id.'_file' });
      	
        $input .= ' '. $html->button("$user_pi->{FILENAME}, ". int2byte($user_pi->{FILESIZE}), "qindex=". get_function_index('user_pi') ."&ATTACHMENT=$field_id:$user_pi->{INFO_FIELDS_VAL}->[$i]", { BUTTON => 1 });
       }
     }
    else {
    	$user_pi->{INFO_FIELDS_VAL}->[$i]=~ s/\"/&quot;/g;
    	$input = $html->form_input($field_id, "$user_pi->{INFO_FIELDS_VAL}->[$i]", { SIZE => 40 });
     }


  	$user_pi->{INFO_FIELDS}.= "<tr><td>". ( eval "\"$name\"" ). ":</td><td valign=center>$input</td></tr>\n";
    $i++;
   }

  if (in_array('Docs', \@MODULES) ) {
    $user_pi->{PRINT_CONTRACT} = $html->button("$_PRINT", "qindex=15&UID=$user_pi->{UID}&PRINT_CONTRACT=$user_pi->{UID}". (($conf{DOCS_PDF_PRINT}) ? '&pdf=1' : '' ), { ex_params => ' target=new', CLASS => 'print rightAlignText' }) ;
    
    if ($conf{DOCS_CONTRACT_TYPES}) {
    	$conf{DOCS_CONTRACT_TYPES} =~ s/\n//g;
      my (@contract_types_list)=split(/;/, $conf{DOCS_CONTRACT_TYPES});

      my %CONTRACTS_LIST_HASH = ();
      $FORM{CONTRACT_SUFIX}="|$user_pi->{CONTRACT_SUFIX}";
      foreach my $line (@contract_types_list) {
      	my ($prefix, $sufix, $name, $tpl_name)=split(/:/, $line);
      	$prefix =~ s/ //g;
      	$CONTRACTS_LIST_HASH{"$prefix|$sufix"}=$name;
       }

      $user_pi->{CONTRACT_TYPE}=" $_TYPE: ".$html->form_select('CONTRACT_TYPE', 
                                { SELECTED   => $FORM{CONTRACT_SUFIX},
 	                                SEL_HASH   => {'' => '', %CONTRACTS_LIST_HASH },
 	                                NO_ID      => 1
 	                               });
     }
   }

  if ($conf{ACCEPT_RULES}) {
    $user_pi->{ACCEPT_RULES} = ($user_pi->{ACCEPT_RULES}) ? $_YES :  $html->color_mark($html->b($_NO), $_COLORS[6]);
   }

  $index=30 if (! $attr->{MAIN_USER_TPL});
  $user_pi->{PASPORT_DATE} = $html->date_fld2('PASPORT_DATE', { FORM_NAME => 'users_pi',
  	                                                            WEEK_DAYS => \@WEEKDAYS,
  	                                                            MONTHES   => \@MONTHES,
  	                                                            DATE      => $user_pi->{PASPORT_DATE}
  	                                                            });

  $user_pi->{CONTRACT_DATE} = $html->date_fld2('CONTRACT_DATE', { FORM_NAME => 'users_pi',
  	                                                              WEEK_DAYS => \@WEEKDAYS,
  	                                                              MONTHES   => \@MONTHES,
  	                                                              DATE      => $user_pi->{CONTRACT_DATE} });

  if ($conf{ADDRESS_REGISTER}) {
  	my $add_address_index        = get_function_index('form_districts');
  	$user_pi->{ADD_ADDRESS_LINK} = $html->button("$_ADD $_ADDRESS", "index=$add_address_index", { CLASS => 'add rightAlignText' });
  	$user_pi->{ADDRESS_TPL}      = $html->tpl_show(templates('form_address_sel'), $user_pi, { OUTPUT2RETURN => 1 });
   }
  else {
  	my $countries = $html->tpl_show(templates('countries'), undef, { OUTPUT2RETURN => 1 });
  	my @countries_arr  = split(/\n/, $countries);
    my %countries_hash = ();
    foreach my $c (@countries_arr) {
    	my ($id, $name)=split(/:/, $c);
    	$countries_hash{int($id)}=$name;
     }
    $user_pi->{COUNTRY_SEL} = $html->form_select('COUNTRY_ID', 
                                { SELECTED   => $user_pi->{COUNTRY_ID},
 	                                SEL_HASH   => {'' => '', %countries_hash },
 	                                NO_ID      => 1
 	                               });
    $user_pi->{ADDRESS_TPL} = $html->tpl_show(templates('form_address'), $user_pi, { OUTPUT2RETURN => 1 });	
   }

  $html->tpl_show(templates('form_pi'), { %$attr, UID => $LIST_PARAMS{UID}, %$user_pi,  });
}

#**********************************************************
# form_users()
#**********************************************************
sub form_users {
  my ($attr)=@_;

  if ($FORM{PRINT_CONTRACT}) {
    load_module('Docs', $html);
    docs_contract();
  	return 0;
   }
 	elsif ($FORM{SEND_SMS_PASSWORD}) {
    load_module('Sms', $html);
    $users->info($FORM{UID}, { SHOW_PASSWORD => 1 });
    $users->pi({ UID => $FORM{UID} });
    if(sms_send({ NUMBER   => $users->{PHONE},,
                  MESSAGE => "LOGIN: $users->{LOGIN} PASSWORD: $users->{PASSWORD}",
                  UID     => $users->{UID}
                })) {
       $html->message('info', "$_INFO", "$_PASSWD SMS $_SENDED");        	
      }
 	 	return 0;
 	 }



if($attr->{USER_INFO}) {
  my $user_info = $attr->{USER_INFO};
  if ($users->{errno}) {
    $html->message('err', $_ERROR, "[$users->{errno}] $err_strs{$users->{errno}}");	
    return 0;
   }

	
  print "<table width=\"100%\" border=\"0\" cellspacing=\"1\" cellpadding=\"2\"><tr><td valign=\"top\" align=\"center\">\n";
  #Make service menu
  my $service_menu       = '';
  my $service_func_index = 0;
  my $service_func_menu  = '';
  foreach my $key ( sort keys %menu_items) {
	  if (defined($menu_items{$key}{20})) {
	  	$service_func_index=$key if (($FORM{MODULE} && $FORM{MODULE} eq $module{$key} || ! $FORM{MODULE}) && $service_func_index == 0);
		  $service_menu .= '<li class=umenu_item>'. $html->button($menu_items{$key}{20}, "UID=$user_info->{UID}&index=$key");
	   }
  
   	if ($service_func_index > 0 && $menu_items{$key}{$service_func_index}) {
	  	 $service_func_menu .= $html->button($menu_items{$key}{$service_func_index}, "UID=$user_info->{UID}&index=$key") .' ';
 	 	 }
   }

  form_passwd({ USER_INFO => $user_info }) if (defined($FORM{newpassword}));

  if ($FORM{change}) {
    if (! $permissions{0}{4} ) {
      $html->message('err', $_ERROR, "$ERR_ACCESS_DENY");  	
    	print "</td></table>\n";
    	return 0;
     }
    elsif (! $permissions{0}{9} && $user_info->{CREDIT} != $FORM{CREDIT}) {
    	$html->message('err', $_ERROR, "$_CHANGE $_CREDIT $ERR_ACCESS_DENY");  	
      $FORM{CREDIT}=undef;
     }
    elsif (! $permissions{0}{11} && $user_info->{REDUCTION} != $FORM{REDUCTION}) {
    	$html->message('err', $_ERROR, "$_REDUCTION $ERR_ACCESS_DENY");  	
      $FORM{REDUCTION}=undef;
     }

    $user_info->change($user_info->{UID}, { %FORM } );
    if ($user_info->{errno}) {
      $html->message('err', $_ERROR, "[$user_info->{errno}] $err_strs{$user_info->{errno}}");	
      user_form();    
      print "</td></table>\n";
      return 0;	
     }
    else {
      $html->message('info', $_CHANGED, "$_CHANGED $users->{info}");
      if (defined($FORM{FIO}))  {
        $users->pi_change({ %FORM });      	
       }

      cross_modules_call('_payments_maked', { USER_INFO => $user_info, }); 
      
      #External scripts 
      if ($conf{external_userchange}) {
        if (! _external($conf{external_userchange}, { %FORM }) ) {
     	    return 0;
         }
       }
      if ($attr->{REGISTRATION}){
        print "</td></tr></table>\n";
        return 0 
       }
     }
   }
  elsif ($FORM{del_user} && $FORM{is_js_confirmed} && $index == 15 && $permissions{0}{5} ) {
    user_del({ USER_INFO => $user_info });
    print "</td></tr></table>\n";
    return 0;
   }
  else {
    if (! $permissions{0}{4}) {
      @action = ();
     }
    else {
      @action = ('change', $_CHANGE);
     }

    user_form({ USER_INFO => $user_info });
    
    if ($conf{USER_ALL_SERVICES}) {

  
  foreach my $module (@MODULES) {
  	$FORM{MODULE}=$module;
  	my $service_func_index = 0;
  	my $service_func_menu  = '';
 	  my $service_menu       = '';
    foreach my $key ( sort keys %menu_items) {
	    if (defined($menu_items{$key}{20})) {
	  	  $service_func_index=$key if (($FORM{MODULE} && $FORM{MODULE} eq $module{$key} || ! $FORM{MODULE}) && $service_func_index == 0);
		    $service_menu .= '<li class=umenu_item>'. $html->button($menu_items{$key}{20}, "UID=$user_info->{UID}&index=$key");
	     }
  
   	  if ($service_func_index > 0 && $menu_items{$key}{$service_func_index}) {
	  	  $service_func_menu .= $html->button($menu_items{$key}{$service_func_index}, "UID=$user_info->{UID}&index=$key") .' ';
 	 	   }
     }
     if ($service_func_index) {
       print "<TABLE width='100%' border=0>
        <TR><TH class=form_title>$module</TH></TR>
        <TR><TH class=odd><div id='rules'><ul><li class='center'>$service_func_menu</li></ul></div></TH></TR></TABLE>\n";

        $index = $service_func_index;
        if(defined($module{$service_func_index})) {
          load_module($module{$service_func_index}, $html);
         }

        $functions{$service_func_index}->({ USER_INFO => $user_info });
      }
   }

     }
    else {
#===============     
    #$service_func_index
    if ($functions{$service_func_index}) {
      $index = $service_func_index;
      if(defined($module{$service_func_index})) {
        load_module($module{$service_func_index}, $html);
       }
    
      print "<TABLE width='100%' border=0>
      <TR><TH class=form_title>$module{$service_func_index}</TH></TR>
      <TR><TH class=even><div id='rules'><ul><li class='center'>$service_func_menu</li></ul></div></TH></TR>
    </TABLE>\n";
  
      $functions{$service_func_index}->({ USER_INFO => $user_info });
    }
#===============
    }
    user_pi({ %$attr, USER_INFO => $user_info });
   }

my $payments_menu = (defined($permissions{1})) ? '<li class=umenu_item>'. $html->button($_PAYMENTS, "UID=$user_info->{UID}&index=2").'</li>' : '';
my $fees_menu     = (defined($permissions{2})) ? '<li class=umenu_item>' .$html->button($_FEES, "UID=$user_info->{UID}&index=3").'</li>' : '';
my $sendmail_manu = '<li class=umenu_item>'. $html->button($_SEND_MAIL, "UID=$user_info->{UID}&index=31"). '</li>';

my $second_menu = '';
my %userform_menus = (
             22 =>  $_LOG,
             21 =>  $_COMPANY,
             12 =>  $_GROUP,
             18 =>  $_NAS,
             20 =>  $_SERVICES,
             19	=>  $_BILL
             );

$userform_menus{17}=$_PASSWD if ($permissions{0}{3});

while(my($k, $v)=each %uf_menus) {
	$userform_menus{$k}=$v;
}

foreach my $k (sort { $b <=> $a } keys %userform_menus) {
	my $v   = $userform_menus{$k};
  my $url =  "index=$k&UID=$user_info->{UID}";
  my $a   = (defined($FORM{$k})) ? $html->b($v) : $v;
  $second_menu .= "<li class=umenu_item>" . $html->button($a,  "$url").'</li>';
}


my $full_delete = '';
if ($admin->{permissions}->{0} && $admin->{permissions}->{0}->{8} && ($user_info->{DELETED})) {
  $second_menu .= "<li class=umenu_item>". $html->button($_UNDELETE, "index=15&del_user=1&UNDELETE=1&UID=$user_info->{UID}&is_js_confirmed=1").'</li>';
  $full_delete = "&FULL_DELETE=1";
}

$second_menu .= "<li class=umenu_item>". $html->button($_DEL, "index=15&del_user=1&UID=$user_info->{UID}$full_delete", { MESSAGE => "$_USER: $user_info->{LOGIN} / $user_info->{UID}" }).'</li>' if (defined($permissions{0}{5}));

print "
</td><td bgcolor='$_COLORS[3]' valign='top' width='180'>
<table width='100%' border='0' cellspacing='0' cellpadding='0'><tr><td>
<div class=l_user_menu>
<ul class=user_menu>
  $payments_menu
  $fees_menu
  $sendmail_manu
</ul>
</div>
</td></tr>
<tr><td>
  <div class=l_user_menu> 
  <ul class=user_menu>
   $service_menu
  </ul></div>
<div class=l_user_menu>
<ul class=user_menu>
 $second_menu
</ul></div>
</td></tr>
</table>
</td></tr></table>\n";
  return 0;
}
elsif ( $FORM{add}) {
  if (! $permissions{0}{1} ) {
    $html->message('err', $_ERROR, "$ERR_ACCESS_DENY");  	
  	return 0;
   }

  if ($FORM{newpassword}) {
    if (length($FORM{newpassword}) < $conf{PASSWD_LENGTH}) {
      $html->message('err', $_ERROR,  "$ERR_SHORT_PASSWD $conf{PASSWD_LENGTH}");
     }
    elsif ($FORM{newpassword} eq $FORM{confirm}) {
      $FORM{PASSWORD} = $FORM{newpassword};
     }
    elsif($FORM{newpassword} ne $FORM{confirm}) {
      $html->message('err', $_ERROR, "$ERR_WRONG_CONFIRM");
     }
    else {
    	$FORM{PASSWORD}=$FORM{newpassword};
     }
   }


  $FORM{REDUCTION}=100 if ($FORM{REDUCTION} && $FORM{REDUCTION} > 100);

  my $user_info = $users->add({ %FORM });  
  if ($users->{errno}) {
  	if ($users->{errno} == 10) {
  		$html->message('err', $_ERROR, "'$FORM{LOGIN}' $ERR_WRONG_NAME");	
  	 }
  	elsif ($users->{errno} == 7) {
  		$html->message('err', $_ERROR, "'$FORM{LOGIN}' $_USER_EXIST");	
  	 }
  	else { 
      $html->message('err', $_ERROR, "[$users->{errno}] $err_strs{$users->{errno}}");	
     }

    delete($FORM{add});
    #user_form();    
    return 1;	
   }
  else {
    $html->message('info', $_ADDED, "$_ADDED '$user_info->{LOGIN}' / [$user_info->{UID}]");
    if ($conf{external_useradd}) {
      if (! _external($conf{external_useradd}, { %FORM }) ) {
        return 0;
       }
     }
  	
    $user_info = $users->info( $user_info->{UID}, { SHOW_PASSWORD => 1 } );
    $html->tpl_show(templates('form_user_info'), $user_info);
    $LIST_PARAMS{UID}= $user_info->{UID};
    $FORM{UID}       = $user_info->{UID};
    user_pi({ %$attr, REGISTRATION => 1 });
    #$index=get_function_index('form_payments');
    #form_payments({ USER => $user_info });
    if ($FORM{COMPANY_ID})  {
      form_companie_admins($attr);
     }
    return 0;
   }
}
#Multi user operations
elsif ($FORM{MULTIUSER}) {
  my @multiuser_arr = split(/, /, $FORM{IDS});
  my $count = 0;
	my %CHANGE_PARAMS = ();
 	while(my($k, $v)=each %FORM) {
 		if ($k =~ /^MU_(\S+)/) {
 			my $val = $1;
      $CHANGE_PARAMS{$val}=$FORM{$val};
	   }
	 }

  if (! defined($FORM{DISABLE})) {
    $CHANGE_PARAMS{UNCHANGE_DISABLE}=1 ;
   }
  else {
  	$CHANGE_PARAMS{DISABLE}=$FORM{MU_DISABLE} || 0;
   }

  if ($#multiuser_arr < 0) {
  	$html->message('err', $_MULTIUSER_OP, "$_SELECT_USER");
   }
  elsif (scalar keys %CHANGE_PARAMS < 1) {
  	#$html->message('err', $_MULTIUSER_OP, "$_SELECT_USER");
   }
  else {
  	foreach my $uid (@multiuser_arr) {
  		if ($FORM{DEL} && $FORM{MU_DEL}) {
  	    my $user_info = $users->info( $uid );
        user_del({ USER_INFO => $user_info });

        if ($users->{errno}) {
          $html->message('err', $_ERROR, "[$users->{errno}] $err_strs{$users->{errno}}");	
         }
  		 }
  		else {
  			$users->change($uid, { UID => $uid, %CHANGE_PARAMS } );
  			if ($users->{errno}) {
  			  $html->message('err', $_ERROR, "[$users->{errno}] $err_strs{$users->{errno}}");	
  			  return 0;
  			 }
  		 }
  	 }
    $html->message('info', $_MULTIUSER_OP, "$_TOTAL: ". $#multiuser_arr+1 ." IDS: $FORM{IDS}");
   }
}


if (! $permissions{0}{2}) {
	return 0;
}

if ($FORM{COMPANY_ID} && ! $FORM{change}) {
  print $html->br($html->b("$_COMPANY:") .  $FORM{COMPANY_ID});
  $pages_qs .= "&COMPANY_ID=$FORM{COMPANY_ID}";
  $LIST_PARAMS{COMPANY_ID} = $FORM{COMPANY_ID};
 }  

if ($FORM{letter}) {
  $LIST_PARAMS{LOGIN} = "$FORM{letter}*";
  $pages_qs .= "&letter=$FORM{letter}";
 } 

my @statuses = ($_ALL, $_ACTIV, $_DEBETORS, $_DISABLE, $_EXPIRE, $_CREDIT);
if ($admin->{permissions}->{0} && $admin->{permissions}->{0}->{8}) {
  push @statuses, $_DELETED,
}

my $i=0;
my $users_status = 0;
foreach my $name ( @statuses ) {
	if (defined($FORM{USERS_STATUS}) && $FORM{USERS_STATUS} == $i && $FORM{USERS_STATUS} ne '') {
    $LIST_PARAMS{USER_STATUS}=1;
    if ($i == 1) {
    	$LIST_PARAMS{ACTIVE}=1;
     }
    elsif ($i == 2) {
      $LIST_PARAMS{DEPOSIT}='<0';
     }
    elsif ($i == 3) {
    	$LIST_PARAMS{DISABLE}=1;
     }
    elsif ($i == 4) {
    	$LIST_PARAMS{EXPIRE}="<$DATE,>0000-00-00";
     }
    elsif ($i == 5) {
    	$LIST_PARAMS{CREDIT}=">0";
     }
    elsif ($i == 6) {
    	$LIST_PARAMS{DELETED}=1;
     }

    $pages_qs   .= "&USERS_STATUS=$i";
    $status_bar .= ' '.$html->b($name);
    $users_status = $i;
	 }
	else {
		my $qs = $pages_qs;
		$qs    =~ s/\&USERS_STATUS=\d//;
	  $status_bar .= ' '.$html->button("$name", "index=$index&USERS_STATUS=$i$qs");
	 }
  $i++;
}

my $list = $users->list( { %LIST_PARAMS, FULL_LIST => 1 } );

if ($users->{errno}) {
  $html->message('err', $_ERROR, "[$users->{errno}] $err_strs{$users->{errno}}");	
  return 0;
 }
elsif ($users->{TOTAL} == 1) {
	$FORM{index} = 15;
	if (! $FORM{UID}) {
	  $FORM{UID}   = $list->[0]->[5+$users->{SEARCH_FIELDS_COUNT}];
	  if ($FORM{LOGIN}=~/\*/ || $FORM{LOGIN} eq '') {
      delete $FORM{LOGIN}; 
      $ui          = user_info($FORM{UID});
      print $ui->{TABLE_SHOW};
     }
   }

  form_users({ USER_INFO => $ui });
	return 0;
 }
elsif ($users->{TOTAL} == 0) {
  $html->message('err', $_ERROR, "$_USER $_NOT_EXIST");	
	return 0;
}

print $html->letters_list({ pages_qs => $pages_qs  }); 



my @TITLE = ($_LOGIN, $_FIO, $_DEPOSIT, $_CREDIT, $_STATUS, '-', '-');
my %SEARCH_TITLES = ('if(company.id IS NULL,ext_b.deposit,ext_cb.deposit)' => "$_EXTRA $_DEPOSIT",
                  'max(p.date)'       => "$_PAYMENTS $_DATE",
                  'pi.email'          => 'E-Mail', 
                  'pi.address_street' => $_ADDRESS, 
                  'pi.pasport_date'   => "$_PASPORT $_DATE", 
                  'pi.pasport_num'    => "$_PASPORT $_NUM", 
                  'pi.pasport_grant'  => "$_PASPORT $_GRANT", 
                  'pi.address_build'  => "$_ADDRESS_BUILD", 
                  'pi.address_flat'   => "$_ADDRESS_FLAT", 
                  'pi.city'           => "$_CITY", 
                  'pi.zip'            => "$_ZIP", 
                  'pi.contract_id'    => "$_CONTRACT_ID", 
                  'u.registration'    => "$_REGISTRATION", 
                  'pi.phone'          => "$_PHONE",
                  'pi.comments'       => "$_COMMENTS", 
                  'if(company.id IS NULL,b.id,cb.id)' => 'BILL ID', 
                  'u.activate'        => "$_ACTIVATE", 
                  'u.expire'          => "$_EXPIRE",
                  'u.credit_date'     => "$_CREDIT $_DATE",
                  'u.reduction'       => "$_REDUCTION",
                  'u.domain_id'       => 'DOMAIN ID',
                  'builds.number'     => "$_BUILDS",
                  'streets.name'      => "$_STREETS",
                  'districts.name'    => "$_DISTRICTS",
                  'u.deleted'         => "$_DELETED",
                  'u.gid'             => "$_GROUP",
                  'builds.id'       => 'Location ID'
                    );

if ($users->{EXTRA_FIELDS}) {
  foreach my $line (@{ $users->{EXTRA_FIELDS} }) {
    if ($line->[0] =~ /ifu(\S+)/) {
      my $field_id = $1;
      my ($position, $type, $name, $user_portal)=split(/:/, $line->[1]);
      if ($type == 2) {
        $SEARCH_TITLES{$field_id.'_list.name'}=eval "\"$name\"";
       }
      else {
        $SEARCH_TITLES{'pi.'.$field_id}=eval "\"$name\"";
       }
     }
   }
}


my @EX_TITLE_ARR  = split(/, /, $users->{SEARCH_FIELDS});

for(my $i=0; $i<$users->{SEARCH_FIELDS_COUNT}; $i++) {
	push @TITLE, '-';
	$TITLE[5+$i] = $SEARCH_TITLES{$EX_TITLE_ARR[$i]} || "$_SEARCH";
 }

#User list
my $table = $html->table( { width      => '100%',
                            caption    => "$_USERS - ". $statuses[$users_status],
                            title      => \@TITLE,
                            cols_align => ['left', 'left', 'right', 'right', 'center', 'right', 'center:noprint', 'center:noprint'],
                            qs         => $pages_qs,
                            pages      => $users->{TOTAL},
                            ID         => 'USERS_LIST',
                            header     => ($permissions{0}{7}) ? "<script language=\"JavaScript\" type=\"text/javascript\">
<!-- 
function CheckAllINBOX() {
  for (var i = 0; i < document.users_list.elements.length; i++) {
    if(document.users_list.elements[i].type == 'checkbox' && document.users_list.elements[i].name == 'IDS'){
      document.users_list.elements[i].checked =         !(document.users_list.elements[i].checked);
    }
  }
}
//-->
</script>\n
<a href=\"javascript:void(0)\" onClick=\"CheckAllINBOX();\" class=export_button>$_SELECT_ALL</a>\n$status_bar" : undef,           
                            EXPORT  => ' XML:&xml=1;',
                            MENU    => "$_ADD:index=".get_function_index('form_wizard').':add'.
                            ";$_SEARCH:index=".get_function_index('form_search').":search"
                         });




foreach my $line (@$list) {
	my $uid = $line->[5+$users->{SEARCH_FIELDS_COUNT}];
  my $payments = ($permissions{1}) ? $html->button($_PAYMENTS, "index=2&UID=$uid", { CLASS => 'payments' }) : ''; 
  my $fees     = ($permissions{2}) ? $html->button($_FEES, "index=3&UID=$uid", { CLASS => 'fees' }) : '';

  my @fields_array  = ();
  for(my $i=0; $i<$users->{SEARCH_FIELDS_COUNT}; $i++){
    if ($conf{EXT_BILL_ACCOUNT} && $i == 0) {
      $line->[5] = ($line->[5] < 0) ? $html->color_mark($line->[5], $_COLORS[6]) : $line->[5];
     }
    elsif ($EX_TITLE_ARR[$i] eq 'u.deleted') {
    	$line->[5+$i]=$html->color_mark($bool_vals[$line->[5+$i]], ($line->[5+$i]==1) ? $state_colors[$line->[5+$i]] : '');
     }
    push @fields_array, $table->td($line->[5+$i]);
   }

  my $multiuser = ($permissions{0}{7}) ? $html->form_input('IDS', "$uid", { TYPE => 'checkbox', }) : '';
  $table->addtd(
                  $table->td(
                  $multiuser.user_ext_menu($uid, $line->[0])), #.$html->button($line->[0], "index=15&UID=$uid") ), 
                  $table->td($line->[1]), 
                  $table->td( ($line->[2] + $line->[3] < 0) ? $html->color_mark($line->[2], $_COLORS[6]) : $line->[2] ), 
                  $table->td($line->[3]), 
                  $table->td($status[$line->[4]], { bgcolor => $state_colors[$line->[4]], align=>'center' }), 
                  #$table->td($html->img((($line->[4]) ? '/img/button_off.png' : '/img/button_activate.png'), $status[$line->[4]]), { align=>'center' }),
                  @fields_array, 
                  $table->td($payments),
                  $table->td($fees),
         );

}


  my @totals_rows = ([ $html->button("$_TOTAL:", "index=$index&USERS_STATUS=0"), $html->b($users->{TOTAL}) ],
                     [ $html->button("$_EXPIRE:", "index=$index&USERS_STATUS=2"), $html->b($users->{TOTAL_EXPIRED}) ],
                     [ $html->button("$_DISABLE:", "index=$index&USERS_STATUS=3"), $html->b($users->{TOTAL_DISABLED}) ]
                     );
                                             

  if ($admin->{permissions}->{0} && $admin->{permissions}->{0}->{8}) {
  	$users->{TOTAL} -= $users->{TOTAL_DELETED};
  	$totals_rows[0] = [ $html->button("$_TOTAL:", "index=$index&USERS_STATUS=0"), $html->b($users->{TOTAL}) ];
  	push @totals_rows,  [$html->button("$_DELETED:", "index=$index&USERS_STATUS=4"),  $html->b($users->{TOTAL_DELETED})],
   }

  

  my $table2 = $html->table({ width      => '100%',
                              cols_align => ['right', 'right'],
                              rows       => [ @totals_rows ]
                            });


if ($permissions{0}{7}) {
  my $table3 = $html->table( { width      => '100%',
  	                           caption    => "$_MULTIUSER_OP",
                               cols_align => ['left', 'left'],
                               rowcolor   => $_COLORS[1],
                               rows       => [ [ $html->form_input('MU_GID', "1", { TYPE => 'checkbox', }). $_GROUP,    sel_groups()],
                                           [ $html->form_input('MU_DISABLE', "1", { TYPE => 'checkbox', }). $_DISABLE,  $html->form_input('DISABLE', "1", { TYPE => 'checkbox', }) . $_CONFIRM ],
                                           [ $html->form_input('MU_DEL', "1", { TYPE => 'checkbox', }). $_DEL,      $html->form_input('DEL', "1", { TYPE => 'checkbox', }) . $_CONFIRM ],
                                           [ $html->form_input('MU_ACTIVATE', "1", { TYPE => 'checkbox', }). $_ACTIVATE, $html->form_input('ACTIVATE', "0000-00-00") ], 
                                           [ $html->form_input('MU_EXPIRE', "1", { TYPE => 'checkbox', }). $_EXPIRE,   $html->form_input('EXPIRE', "0000-00-00")   ], 
                                           [ $html->form_input('MU_CREDIT', "1", { TYPE => 'checkbox', }). $_CREDIT,   $html->form_input('CREDIT', "0")   ], 
                                           [ $html->form_input('MU_CREDIT_DATE', "1", { TYPE => 'checkbox', }). "$_CREDIT $_DATE",   $html->form_input('CREDIT_DATE', "0000-00-00")   ], 
                                           [ '',         $html->form_input('MULTIUSER', "$_CHANGE", { TYPE => 'submit'})   ], 
                                         
                                         ]
                       });

   print $html->form_main({ CONTENT => $table->show({ OUTPUT2RETURN => 1 }).
   	                                   ( (! $admin->{MAX_ROWS}) ? $table2->show({ OUTPUT2RETURN => 1 }) : '' ).
   	                                   $table3->show({ OUTPUT2RETURN => 1 }),
	                          HIDDEN  => { index => 11,
	                          	           FULL_DELETE => ($admin->{permissions}->{0} && $admin->{permissions}->{0}->{8}) ? 1 : undef,
	                       	              },
	                       	  NAME    => 'users_list'
                       });



 }
else {
  print $table->show();
  print $table2->show() if (! $admin->{MAX_ROWS});	
 }
}


#**********************************************************
# user_del
#**********************************************************
sub user_del {
  my ($attr) = @_;
  
  my $user_info = $attr->{USER_INFO};
  
  if ($FORM{UNDELETE}) {
  	$user_info->change($user_info->{UID}, { UID => $user_info->{UID}, DELETED => 0 });
  	$html->message('info', $_UNDELETED, "UID: [$user_info->{UID}] $_UNDELETED $user_info->{LOGIN}");
    return 0;	
   }
  
  
  $user_info->del({ %FORM });
  $conf{DELETE_USER}=$user_info->{UID};

  if ($user_info->{errno}) {
    $html->message('err', $_ERROR, "[$user_info->{errno}] $err_strs{$user_info->{errno}}");	
   }
  else {
  	if ($conf{external_userdel}) {
      if (! _external($conf{external_userdel}, { LOGIN => $email_u, %FORM,  %$user_info }) ) {
         $html->message('err', $_DELETED, "External cmd: $conf{external_userdel}");
        }
     }
    $html->message('info', $_DELETED, "UID: [$user_info->{UID}] $_DELETED $users->{info}");
   }

if ($FORM{FULL_DELETE}) {
  my $mods = '';
  foreach my $mod (@MODULES) {
  	$mods .= "$mod,";
   	load_module($mod, $html);
    my $function = lc($mod).'_user_del';
    if (defined(&$function)) {
     	$function->($user_info->{UID}, $user_info );
     }
   }

  if ($user_info->{errno}) {
    $html->message('err', $_ERROR, "[$user_info->{errno}] $err_strs{$user_info->{errno}}");	
   }
  else {
  	if ($conf{external_userdel}) {
      if (! _external($conf{external_userdel}, { LOGIN => $email_u, %FORM,  %$user_info }) ) {
         $html->message('err', $_DELETED, "External cmd: $conf{external_userdel}");
        }
     }

    $html->message('info', $_DELETED, "UID: [$user_info->{UID}] $_DELETED $users->{info} $_MODULES: $mods");
   }
 }

  return 0;
}

#**********************************************************
# user_group
#**********************************************************
sub user_group {
  my ($attr) = @_;
  my $user = $attr->{USER_INFO};

  $user->{SEL_GROUPS} = sel_groups();
  $html->tpl_show(templates('form_chg_group'), $user);
}

#**********************************************************
# user_company
#**********************************************************
sub user_company {
 my ($attr) = @_;
 my $user_info = $attr->{USER_INFO};
 use Customers;
 my $customer = Customers->new($db, $admin, \%conf);
 my $company  = $customer->company();



form_search({ SIMPLE        => { $_COMPANY => 'COMPANY_NAME' },
	            HIDDEN_FIELDS => { UID       => $FORM{UID} }
	           });


my $list  = $company->list({ %LIST_PARAMS });
my $table = $html->table( { width      => '100%',
                            border     => 1,
                            title      => ["$_NAME", "$_DEPOSIT",  '-'],
                            cols_align => ['right', 'left', 'center:noprint'],
                            qs         => $pages_qs,
                            pages      => $company->{TOTAL},
                            ID         => 'COMPANY_LIST'
                           });

  $table->addrow($_DEFAULT,
    '',
    $html->button("$_DEL", "index=". get_function_index('form_users') ."&change=1&UID=$FORM{UID}&COMPANY_ID=0", { CLASS => 'del'  }), 
    );


foreach my $line (@$list) {
	$table->{rowcolor} = ($user_info->{COMPANY_ID} == $line->[5]) ? $_COLORS[0] : undef;
  $table->addrow(($user_info->{COMPANY_ID} == $line->[5]) ? $html->b($line->[0]) : $line->[0],
    $line->[1],
    ($user_info->{COMPANY_ID} == $line->[5]) ? ''  : $html->button("$_CHANGE", "index=". get_function_index('form_users') ."&change=1&UID=$FORM{UID}&COMPANY_ID=$line->[5]", { CLASS => 'add' }), 
    );
}

print $table->show();
}

#**********************************************************
# Users and Variant NAS Servers
# form_nas_allow()
#**********************************************************
sub form_nas_allow {
 my ($attr) = @_;
 my @allow = split(/, /, $FORM{ids});
 my %allow_nas = (); 
 my %EX_HIDDEN_PARAMS = (subf  => "$FORM{subf}",
	                       index => "$index");

if ($attr->{USER_INFO}) {
  my $user = $attr->{USER_INFO};
  if ($FORM{change}) {
    $user->nas_add(\@allow);
    if (! $user->{errno}) {
      $html->message('info', $_INFO, "$_ALLOW $_NAS: $FORM{ids}");
     }
   }
  elsif($FORM{default}) {
    $user->nas_del();
    if (! $user->{errno}) {
      $html->message('info', $_NAS, "$_CHANGED");
     }
   }

  if ($user->{errno}) {
    $html->message('err', $_ERROR, "[$user->{errno}] $err_strs{$user->{errno}}");	
   }

  my $list = $user->nas_list();
  foreach my $line (@$list) {
     $allow_nas{$line->[0]}='test';
   }
  
  $EX_HIDDEN_PARAMS{UID}=$user->{UID};
 }
elsif($attr->{TP}) {
  my $tarif_plan = $attr->{TP};

  if ($FORM{change}){
    $tarif_plan->nas_add(\@allow);
    if ($tarif_plan->{errno}) {
      $html->message('err', $_ERROR, "[$tarif_plan->{errno}] $err_strs{$tarif_plan->{errno}}");	
     }
    else {
      $html->message('info', $_INFO, "$_ALLOW $_NAS: $FORM{ids}");
     }
   }
  
  my $list = $tarif_plan->nas_list();
  foreach my $nas_id (@$list) {
    $allow_nas{$nas_id->[0]}=1;
   }

  $EX_HIDDEN_PARAMS{TP_ID}=$tarif_plan->{TP_ID};
}
elsif (defined($FORM{TP_ID})) {
  $FORM{chg}=$FORM{TP_ID};
  $FORM{subf}=$index;
  dv_tp();
  return 0;
 }

my $nas = Nas->new($db, \%conf);


my $table = $html->table( { width      => '100%',
                            caption    => "$_NAS",
                            border     => 1,
                            title      => ["$_ALLOW", "$_NAME", 'NAS-Identifier', "IP", "$_TYPE", "$_AUTH"],
                            cols_align => ['right', 'left', 'left', 'right', 'left', 'left'],
                            qs         => $pages_qs,
                            ID         => 'NAS_ALLOW'
                           });

if (! defined($FORM{sort})) {
  $LIST_PARAMS{SORT}=1;
 }


my $list = $nas->list({ %LIST_PARAMS, 
	                      PAGE_ROWS => 100000 });

foreach my $line (@$list) {
  $table->addrow(" $line->[0]". $html->form_input('ids', "$line->[0]", 
                                                   { TYPE          => 'checkbox',
  	                                                 OUTPUT2RETURN => 1,
       	                                             STATE         => (defined($allow_nas{$line->[0]}) || $allow_nas{all}) ? 1 : undef
       	                                          }), 
    $line->[1], 
    $line->[2],  
    $line->[3],  
    $line->[4], 
    $auth_types[$line->[5]]
    );
}

print $html->form_main({ CONTENT => $table->show({ OUTPUT2RETURN => 1 }),
	                       HIDDEN  => { %EX_HIDDEN_PARAMS },
	                       SUBMIT  => { change   => "$_CHANGE",
	                       	            default  => $_DEFAULT 
	                       	           } });
}




#**********************************************************
# form_bills();
#**********************************************************
sub form_bills {
  my ($attr) = @_;
  my $user = $attr->{USER_INFO};

  if($FORM{UID} && $FORM{change}) {
  	form_users({ USER_INFO => $user } ); 
  	return 0;
  }
  
  if (! $attr->{EXT_BILL_ONLY}) {
    use Bills;
    my  $bills = Bills->new($db);
    my $list = $bills->list({  COMPANY_ONLY => 1,
  	                           UID          => $user->{UID} 
  	                        });

    my %BILLS_HASH = ();

    foreach my $line (@$list) {
      if($line->[3] ne '') {
        $BILLS_HASH{$line->[0]}="$line->[0] : $line->[3] :$line->[1]";
       }
      elsif($line->[2] ne '') {
    	  $BILLS_HASH{$line->[0]}=">> $line->[0] : Personal :$line->[1]";
       }
     }

    $user->{SEL_BILLS} .= $html->form_select('BILL_ID', 
                                { SELECTED   => '',
 	                                SEL_HASH   => {'' => '', %BILLS_HASH },
 	                                NO_ID      => 1
 	                               });


    $user->{CREATE_BILL}      = ' checked' if (! $FORM{COMPANY_ID} && $user->{BILL_ID} < 1);
    $user->{BILL_TYPE}        = $_PRIMARY;
    $user->{CREATE_BILL_TYPE} = 'CREATE_BILL';
    $html->tpl_show(templates('form_chg_bill'), $user);
  }

  if ($conf{EXT_BILL_ACCOUNT} || $attr->{EXT_BILL_ONLY}) {  	
    $html->tpl_show(templates('form_chg_bill'), {
    	   BILL_ID          => $user->{EXT_BILL_ID},
    	   BILL_TYPE        => $_EXTRA,
    	   CREATE_BILL_TYPE => 'CREATE_EXT_BILL',
    	   LOGIN            => $user->{LOGIN},
    	   CREATE_BILL      => (! $FORM{COMPANY_ID} && $user->{EXT_BILL_ID} < 1) ? ' checked'  : '',
    	   SEL_BILLS        => $user->{SEL_BILLS},
    	   UID              => $user->{UID},
    	   SEL_BILLS        => $html->form_select('EXT_BILL_ID', 
                                { SELECTED   => '',
 	                                SEL_HASH   => {'' => '', %BILLS_HASH },
 	                                NO_ID      => 1
 	                               })
 
    	  });
   }

}



#**********************************************************
# form_system_changes();
#**********************************************************
sub form_system_changes {
 my ($attr) = @_; 
 my %search_params = ();
 
  my %action_types = ( 0  => 'Unknown', 
                   1  => "$_ADDED",
                   2  => "$_CHANGED",
                   3  => "$_CHANGED $_TARIF_PLAN",
                   4  => "$_CHANGED $_STATUS",
                   5  => '-',
                   6  => "$_INFO",
                   7  => '-',
                   8  => "$_ENABLE",
                   9  => "$_DISABLE",
                   10 => "$_DELETED",
                   11 => "$ERR_WRONG_PASSWD",
                   13 => "Online $_DEL",
                   27 => "$_SHEDULE $_ADDED",
                   28 => "$_SHEDULE $_DELETED",
                   
                   41 => "$_CHANGED $_EXCHANGE_RATE",
                   42 => "$_DELETED $_EXCHANGE_RATE",
                   );

 
if ($permissions{4}{3} && $FORM{del} && $FORM{is_js_confirmed}) {
	$admin->system_action_del( $FORM{del} );
  if ($admins->{errno}) {
    $html->message('err', $_ERROR, "[$admins->{errno}] $err_strs{$admins->{errno}}");	
   }
  else {
    $html->message('info', $_DELETED, "$_DELETED [$FORM{del}]");
   }
 }
elsif($FORM{AID} && ! defined($LIST_PARAMS{AID})) {
	$FORM{subf}=$index;
	form_admins();
	return 0;
 }


if (! defined($FORM{sort})) {
  $LIST_PARAMS{SORT}=1;
  $LIST_PARAMS{DESC}=DESC;
 }


%search_params=%FORM;
$search_params{MODULES_SEL} = $html->form_select('MODULE', 
                                { SELECTED      => $FORM{MODULE},
 	                                SEL_ARRAY     => ['', @MODULES],
 	                                OUTPUT2RETURN => 1
 	                               });

$search_params{TYPE_SEL} = $html->form_select('TYPE', 
                                { SELECTED      => $FORM{TYPE},
                                	SEL_HASH      => {'' => $_ALL, %action_types },
                                	SORT_KEY      => 1,
 	                                OUTPUT2RETURN => 1
 	                               });


form_search({ HIDDEN_FIELDS => $LIST_PARAMS{AID},
	            SEARCH_FORM   => $html->tpl_show(templates('form_history_search'), \%search_params, { OUTPUT2RETURN => 1 })
	           });


my $list = $admin->system_action_list({ %LIST_PARAMS });
my $table = $html->table( { width      => '100%',
                            border     => 1,
                            title      => ['#', $_DATE,  $_CHANGED,  $_ADMIN,   'IP', "$_MODULES", "$_TYPE", '-'],
                            cols_align => ['right', 'left', 'right', 'left', 'left', 'right', 'left', 'left', 'center:noprint'],
                            qs         => $pages_qs,
                            pages      => $admin->{TOTAL},
                            ID         => 'ADMIN_SYSTEM_ACTIONS'
                           });



foreach my $line (@$list) {
  my $delete = ($permissions{4}{3}) ? $html->button($_DEL, "index=$index$pages_qs&del=$line->[0]", { MESSAGE => "$_DEL [$line->[0]] ?", CLASS => 'del' }) : ''; 

  $table->{rowcolor}=undef;
  my $color = undef;
  if (in_array($line->[6], [10, 28, 13])) {
  	$color='red';
   }
  elsif (in_array($line->[6], [1, 7])) {
  	$table->{rowcolor}=$_COLORS[3];
   }

  $table->addrow($html->b($line->[0]),
    $html->color_mark($line->[1], $color),
    $html->color_mark($line->[2], $color),
    $line->[3], 
    $line->[4], 
    $line->[5], 
    $html->color_mark($action_types{$line->[6]}, $color), 
    $delete);
}



print $table->show();
$table = $html->table( { width      => '100%',
                         cols_align => ['right', 'right'],
                         rows       => [ [ "$_TOTAL:", $html->b($admin->{TOTAL}) ] ]
                       } );
print $table->show();

}





#**********************************************************
# form_changes();
#**********************************************************
sub form_changes {
 my ($attr) = @_; 
 my %search_params = ();
 
 my %action_types = ( 0  => 'Unknown', 
                   1  => "$_ADDED",
                   2  => "$_CHANGED",
                   3  => "$_CHANGED $_TARIF_PLAN",
                   4  => "$_STATUS",
                   5  => "$_CHANGED $_CREDIT",
                   6  => "$_INFO",
                   7  => "$_REGISTRATION",
                   8  => "$_ENABLE",
                   9  => "$_DISABLE",
                   10 => "$_DELETED",
                   11 => '',
                   12 => "$_DELETED $_USER",
                   13 => "Online $_DELETED",
                   14 => "$_HOLD_UP",
                   15 => "$_HANGUP",
                   26 => "$_CHANGE $_GROUP",
                   27 => "$_SHEDULE $_ADD",
                   28 => "$_SHEDULE $_DEL",
                   31 => "$_CARDS $_USED"
                   );
 
if ($permissions{4}{3} && $FORM{del} && $FORM{is_js_confirmed}) {
	$admin->action_del( $FORM{del} );
  if ($admins->{errno}) {
    $html->message('err', $_ERROR, "[$admins->{errno}] $err_strs{$admins->{errno}}");	
   }
  else {
    $html->message('info', $_DELETED, "$_DELETED [$FORM{del}]");
   }
 }
elsif($FORM{AID} && ! defined($LIST_PARAMS{AID})) {
	$FORM{subf}=$index;
	form_admins();
	return 0;
 }


if (! defined($FORM{sort})) {
  $LIST_PARAMS{SORT}=1;
  $LIST_PARAMS{DESC}=DESC;
 }


%search_params=%FORM;
$search_params{MODULES_SEL} = $html->form_select('MODULE', 
                                { SELECTED      => $FORM{MODULE},
 	                                SEL_ARRAY     => ['', @MODULES],
 	                                OUTPUT2RETURN => 1
 	                               });

$search_params{TYPE_SEL} = $html->form_select('TYPE', 
                                { SELECTED      => $FORM{TYPE},
                                	SEL_HASH      => {'' => $_ALL, %action_types },
                                	SORT_KEY      => 1,
 	                                OUTPUT2RETURN => 1
 	                               });

form_search({ HIDDEN_FIELDS => $LIST_PARAMS{AID},
	            SEARCH_FORM   => $html->tpl_show(templates('form_history_search'), \%search_params, { OUTPUT2RETURN => 1 })
	           });


my $list  = $admin->action_list({ %LIST_PARAMS });

my $table = $html->table( { width      => '100%',
                            border     => 1,
                            title      => ['#', 'UID',  $_DATE,  $_CHANGED,  $_ADMIN,   'IP', "$_MODULES", "$_TYPE", '-'],
                            cols_align => ['right', 'left', 'right', 'left', 'left', 'right', 'left', 'left', 'center:noprint'],
                            qs         => $pages_qs,
                            pages      => $admin->{TOTAL},
                            ID         => 'ADMIN_ACTIONS'
                           });



foreach my $line (@$list) {
  my $delete = ($permissions{4}{3}) ? $html->button($_DEL, "index=$index$pages_qs&del=$line->[0]", { MESSAGE => "$_DEL [$line->[0]] ?", CLASS => 'del' }) : ''; 
  
  my $color = undef;
  if (in_array($line->[7], [10, 28, 13])) {
  	$color='red';
   }
  elsif (in_array($line->[7], [1, 7])) {
  	$table->{rowcolor}=$_COLORS[3];
   }
  else {
  	$table->{rowcolor}=undef;
   }
  $table->addrow($html->b($line->[0]),
    $html->button($line->[1], "index=15&UID=$line->[8]"), 
    $html->color_mark($line->[2], $color), 
    $html->color_mark($line->[3], $color), 
    $line->[4],  
    $line->[5], 
    $line->[6], 
    $html->color_mark($action_types{$line->[7]}, $color), 
    $delete);
}



print $table->show();
$table = $html->table( { width      => '100%',
                         cols_align => ['right', 'right'],
                         rows       => [ [ "$_TOTAL:", $html->b($admin->{TOTAL}) ] ]
                       } );
print $table->show();
}


#**********************************************************
# Time intervals
# form_intervals()
#**********************************************************
sub form_intervals {
  my ($attr) = @_;

  my @DAY_NAMES = ("$_ALL", 
                "$WEEKDAYS[7]",
                "$WEEKDAYS[1]", 
                "$WEEKDAYS[2]", 
                "$WEEKDAYS[3]", 
                "$WEEKDAYS[4]", 
                "$WEEKDAYS[5]", 
                "$WEEKDAYS[6]", 
                "$_HOLIDAYS");

  my %visual_view = ();
  my $tarif_plan;
  my $max_traffic_class_id = 0; #Max taffic class id

if(defined($attr->{TP})) {
  $tarif_plan = $attr->{TP};
 	$tarif_plan->{ACTION}='add';
 	$tarif_plan->{LNG_ACTION}=$_ADD;


  if(defined($FORM{tt})) {
    dv_traf_tarifs({ TP => $tarif_plan });
   }
  elsif ($FORM{add}) {
    $tarif_plan->ti_add( { %FORM });
    if (! $tarif_plan->{errno}) {
      $html->message('info', $_INFO, "$_INTERVALS $_ADDED");
      $tarif_plan->ti_defaults();
     }
   }
  elsif($FORM{change}) {
    $tarif_plan->ti_change( $FORM{TI_ID}, { %FORM } );

    if (! $tarif_plan->{errno}) {
      $html->message('info', $_INFO, "$_INTERVALS $_CHANGED [$tarif_plan->{TI_ID}]");
     }
   }
  elsif(defined($FORM{chg})) {
  	$tarif_plan->ti_info( $FORM{chg} );
    if (! $tarif_plan->{errno}) {
      $html->message('info', $_INFO, "$_INTERVALS $_CHANGE [$FORM{chg}]");
     }

 	 	$tarif_plan->{ACTION}='change';
 	 	$tarif_plan->{LNG_ACTION}=$_CHANGE;
   }
  elsif($FORM{del} && $FORM{is_js_confirmed}) {
    $tarif_plan->ti_del($FORM{del});
    if (! $tarif_plan->{errno}) {
      $html->message('info', $_DELETED, "$_DELETED $FORM{del}");
     }
   }
  else {
 	 	$tarif_plan->ti_defaults();
   }

  if ($tarif_plan->{errno}) {
    $html->message('err', $_ERROR, "[$tarif_plan->{errno}] $err_strs{$tarif_plan->{errno}} $tarif_plan->{errstr}");	
   }

  my $list = $tarif_plan->ti_list({ %LIST_PARAMS });
  my $table = $html->table( { width      => '100%',
                              caption    => "$_INTERVALS",
                              border     => 1,
                              title      => ['#', $_DAYS, $_BEGIN, $_END, $_HOUR_TARIF, $_TRAFFIC, '-', '-',  '-'],
                              cols_align => ['left', 'left', 'right', 'right', 'right', 'center', 'center', 'center', 'center', 'center'],
                              qs         => $pages_qs,
                           } );

  my $color="AAA000";
  foreach my $line (@$list) {

    my $delete = $html->button($_DEL, "index=$index$pages_qs&del=$line->[0]", { MESSAGE => "$_DEL [$line->[0]] ?", CLASS => 'del'}); 
    $color = sprintf("%06x", hex('0x'. $color) + 7000);
     
    #day, $hour|$end = color
    my ($h_b, $m_b, $s_b)=split(/:/, $line->[2], 3);
    my ($h_e, $m_e, $s_e)=split(/:/, $line->[3], 3);

     push ( @{$visual_view{$line->[1]}}, "$h_b|$h_e|$color|$line->[0]")  ;

    if (($FORM{tt} eq $line->[0]) || ($FORM{chg} eq $line->[0])) {
       $table->{rowcolor}='row_active';
     }
    else {
    	 undef($table->{rowcolor});
     }
    
    $table->addtd(
                  $table->td($line->[0], { rowspan => ($line->[5] > 0) ? 2 : 1 } ), 
                  $table->td($html->b($DAY_NAMES[$line->[1]])), 
                  $table->td($line->[2]), 
                  $table->td($line->[3]), 
                  $table->td($line->[4]), 
                  $table->td($html->button($_TRAFFIC, "index=$index$pages_qs&tt=$line->[0]", { CLASS => 'traffic' })),
                  $table->td($html->button($_CHANGE, "index=$index$pages_qs&chg=$line->[0]", { CLASS => 'change' })),
                  $table->td($delete),
                  $table->td("&nbsp;", { bgcolor => '#'.$color, rowspan => ($line->[5] > 0) ? 2 : 1 })
      );

     if($line->[5] > 0) {
     	 my $TI_ID = $line->[0];
     	 #Traffic tariff IN (1 Mb) Traffic tariff OUT (1 Mb) Prepaid (Mb) Speed (Kbits) Describe NETS 
       my $table2 = $html->table({ width       => '100%',
                                   title_plain => ["#", "$_TRAFFIC_TARIFF In ", "$_TRAFFIC_TARIFF Out ", "$_PREPAID (Mb)", "$_SPEED IN",  "$_SPEED OUT", "DESCRIBE", "NETS", "-", "-"],
                                   cols_align  => ['center', 'right', 'right', 'right', 'right', 'right', 'left', 'right', 'center', 'center', 'center'],
                                   caption     => "$_TRAFIC_TARIFS"
                                  } );

       my $list_tt = $tarif_plan->tt_list({ TI_ID => $line->[0] });
       foreach my $line (@$list_tt) {
          $max_traffic_class_id=$line->[0] if ($line->[0] > $max_traffic_class_id);
          $table2->addrow($line->[0], 
           $line->[1], 
           $line->[2], 
           $line->[3], 
           $line->[4], 
           $line->[5], 
           $line->[6], 
           convert($line->[7], { text2html => 1  }),
           $html->button($_CHANGE, "index=$index$pages_qs&tt=$TI_ID&chg=$line->[0]", { CLASS => 'change' }),
           $html->button($_DEL, "index=$index$pages_qs&tt=$TI_ID&del=$line->[0]", { MESSAGE => "$_DEL [$line->[0]]?", CLASS => 'del'  } ));
        }

       my $table_traf = $table2->show();
  
       $table->addtd($table->td("$table_traf", { bgcolor => $_COLORS[2], colspan => 7}));
     }
     
   };
  print $table->show();
  
 }
elsif (defined($FORM{TP_ID})) {
  $FORM{subf}=$index;
  dv_tp();
  return 0;
 }

if ($tarif_plan->{errno}) {
   $html->message('err', $_ERROR, "[$tarif_plan->{errno}] $err_strs{$tarif_plan->{errno}} $tarif_plan->{errstr}");	
 }


$table = $html->table({ width       => '100%',
	                      title_plain => [$_DAYS, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13,14,15,16,17,18, 19, 20, 21, 22, 23],
                        caption     => "$_INTERVALS",
                        rowcolor    => 'odd'
                        });



for(my $i=0; $i<9; $i++) {
  my @hours = ();
  my ($h_b, $h_e, $color, $p);

  my $link = "&nbsp;";
  for(my $h=0; $h<24; $h++) {

  	 if(defined($visual_view{$i})) {
  	   $day_periods = $visual_view{$i};
       foreach my $line (@$day_periods) {
     	   ($h_b, $h_e, $color, $p)=split(/\|/, $line, 4);
     	   if (($h >= $h_b) && ($h < $h_e)) {
  	   	   $tdcolor = '#'.$color;
  	 	     $link = $html->button('#', "index=$index&TP_ID=$FORM{TP_ID}&subf=$FORM{subf}&chg=$p");
  	 	     last;
  	 	    }
  	     else {
  	 	     $link = "&nbsp;";
  	 	     $tdcolor = $_COLORS[1];
  	      }
       }
     }
  	 else {
  	 	 $link = "&nbsp;";
  	 	 $tdcolor = $_COLORS[1];
  	  }

  	 push(@hours, $table->td("$link", { align=>'center', bgcolor => $tdcolor }) );
    }

  $table->addtd($table->td($DAY_NAMES[$i]), @hours);
}

print $table->show();

if (defined($FORM{tt})) {
  my %TT_IDS = (0 => "Global",
                1 => "Extended 1",
                2 => "Extended 2" );

  if ($max_traffic_class_id >= 2) {
  	for (my $i=3; $i<$max_traffic_class_id+2; $i++) { 
  	  $TT_IDS{$i}="Extended $i";
  	 }
  }

  $tarif_plan->{SEL_TT_ID} = $html->form_select('TT_ID', 
                                { SELECTED    => $tarif_plan->{TT_ID},
 	                                SEL_HASH   => \%TT_IDS,
 	                               });
  
  if ($conf{DV_EXPPP_NETFILES}) {
     $tarif_plan->{DV_EXPPP_NETFILES}="EXPPP_NETFILES: ". $html->form_input('DV_EXPPP_NETFILES', '1', 
                                                       { TYPE          => 'checkbox',
       	                                                 OUTPUT2RETURN => 1,
       	                                                 STATE         => 1
       	                                                }  
       	                                               );
   }
  
  $tarif_plan->{NETS_SEL} = $html->form_select('TT_NET_ID', 
                                         { 
 	                                          SELECTED          => $tarif_plan->{TT_NET_ID},
 	                                          SEL_MULTI_ARRAY   => [ [ 0, ''], @{ $tarif_plan->traffic_class_list({ %LIST_PARAMS}) } ],
 	                                          MULTI_ARRAY_KEY   => 0,
 	                                          MULTI_ARRAY_VALUE => 1,
 	                                          MAIN_MENU         => get_function_index('dv_traffic_classes'),
 	                                          MAIN_MENU_AGRV    => "chg=$tarif_plan->{TT_NET_ID}"
 	                                        });

  $html->tpl_show(_include('dv_tt', 'Dv'), $tarif_plan);
}
else {

  my $day_id = $FORM{day} || $tarif_plan->{TI_DAY};

  $tarif_plan->{SEL_DAYS} = $html->form_select('TI_DAY', 
                                { SELECTED      => $day_id || $FORM{TI_DAY},
 	                                SEL_ARRAY     => \@DAY_NAMES,
 	                                ARRAY_NUM_ID  => 1
 	                               });
  $html->tpl_show(templates('form_ti'), $tarif_plan);
}

}



#**********************************************************
# form_hollidays
#**********************************************************
sub form_holidays {
	my $holidays = Tariffs->new($db, \%conf, $admin);
	
  my %holiday = ();

if ($FORM{add}) {
  my($add_month, $add_day)=split(/-/, $FORM{add});
  $add_month++;

  $holidays->holidays_add({MONTH => $add_month, 
  	                       DAY   => $add_day
  	                      });

  if (! $holidays->{errno}) {
    $html->message('info', $_INFO, "$_ADDED");	
   }
}
elsif($FORM{del} && $FORM{is_js_confirmed}){
  $holidays->holidays_del($FORM{del});

  if (! $holidays->{errno}) {
    $html->message('info', $_INFO, "$_DELETED");	
  }
}

if ($holidays->{errno}) {
    $html->message('err', $_ERROR, "[$holidays->{errno}] $err_strs{$holidays->{errno}}");	
 }


my $list = $holidays->holidays_list( { %LIST_PARAMS });
my $table = $html->table( { caption    => "$_HOLIDAYS",
	                          width      => '640',
                            title      => [$_DAY,  $_DESCRIBE, '-'],
                            cols_align => ['left', 'left', 'center'],
                          } );
my ($delete); 
foreach my $line (@$list) {
	my ($m, $d)=split(/-/, $line->[0]);
	$m--;
  $delete = $html->button($_DEL, "index=75&del=$line->[0]", { MESSAGE => "$_DEL ?", CLASS => 'del' }); 
  $table->addrow("$d $MONTHES[$m]", $line->[1], $delete);
}

print $table->show();

$table = $html->table( { width      => '640',
                         cols_align => ['right', 'right'],
                         rows       => [ [ "$_TOTAL:", $html->b($holidays->{TOTAL}) ] ]
                               } );
print $table->show();

my $year = $FORM{year} || strftime("%Y", localtime(time));
my $month = $FORM{month} || 0;

if ($month + 1 > 11) {
  $n_month = 0;
  $n_year = $FORM{year}+1;
}
else {
 $n_month = $month + 1;
 $n_year = $year;
}

if ($month - 1 < 0) {
  $p_month = 11;
  $p_year = $year-1;
 }
else {
  $p_month = $month - 1;
  $p_year = $year;
}

my $tyear = $year - 1900;
my $curtime = POSIX::mktime(0, 1, 1, 1, $month, $tyear);
my ($sec,$min,$hour,$mday,$mon, $gyear,$gwday,$yday,$isdst) = gmtime($curtime);

print "<br><TABLE width=\"400\" cellspacing=\"0\" cellpadding=\"0\" border=\"0\">
<tr><TD bgcolor=\"$_COLORS[4]\">
<TABLE width=\"100%\" cellspacing=1 cellpadding=0 border=0>
<tr bgcolor=\"$_COLORS[0]\"><th>". $html->button(' << ', 'index=75&month='.$p_month. '&year='.$p_year). "</th><th colspan='5'>$MONTHES[$month] $year</th><th>". $html->button(' >> ', "index=75&month=$n_month&year=$n_year") ."</th></tr>
<tr bgcolor=\"$_COLORS[0]\"><th>$WEEKDAYS[1]</th><th>$WEEKDAYS[2]</th><th>$WEEKDAYS[3]</th>
<th>$WEEKDAYS[4]</th><th>$WEEKDAYS[5]</th>
<th><font color=\"#FF0000\">$WEEKDAYS[6]</font></th><th><font color=#FF0000>$WEEKDAYS[7]</font></th></tr>\n";



my $day = 1;
my $month_days = 31;
while($day < $month_days) {
  print "<tr bgcolor=\"$_COLORS[1]\">";
  for($wday=0; $wday < 7 and $day <= $month_days; $wday++) {
     if ($day == 1 && $gwday != $wday) { 
       print "<td>&nbsp;</td>";
       if ($wday == 7) {
       	 print "$day == 1 && $gwday != $wday";
       	 return 0;
       	}
      }
     else {
       my $bg = '';
       if ($wday > 4) {
       	  $bg = "bgcolor=\"$_COLORS[2]\"";
       	}

       if (defined($holiday{$month}{$day})) {
         print "<th bgcolor=\"$_COLORS[0]\">$day</th>";
        }
       else {
         print "<td align=right $bg>". $html->button($day, "index=75&add=$month-$day"). '</td>';
        }
       $day++;
      }
    }
  print "</tr>\n";
}


print "</table>\n</td></tr></table>\n";

}

#**********************************************************
# form_admins()
#**********************************************************
sub form_admins {

my $admin_form = Admins->new($db, \%conf);
$admin_form->{ACTION}='add';
$admin_form->{LNG_ACTION}=$_ADD;

if ($FORM{AID}) {
  $admin_form->info($FORM{AID});

  $FORM{DOMAIN_ID}  = $admin_form->{DOMAIN_ID};
  $LIST_PARAMS{AID} = $admin_form->{AID};  	
  $pages_qs = "&AID=$admin_form->{AID}&subf=$FORM{subf}";

  my $A_LOGIN = $html->form_main({ CONTENT => $html->form_select('AID', 
                                          { 
 	                                          SELECTED          => $FORM{AID},
 	                                          SEL_MULTI_ARRAY   => $admin->list({ %LIST_PARAMS }),
 	                                          MULTI_ARRAY_KEY   => 0,
 	                                          MULTI_ARRAY_VALUE => 1,
 	                                        }),
	                                          HIDDEN  => { index => "$index",
	                                          	           subf  => $FORM{subf} 
	                                          	           },
	                                          SUBMIT  => { show  => "$_SHOW" } 
	                        });

  func_menu({ 
  	         'ID'   => $admin_form->{AID}, 
  	         $_NAME => $A_LOGIN
  	       }, 
  	{ 
  	 $_CHANGE         => ":AID=$admin_form->{AID}:change rightAlignText",
     $_LOG            => "51:AID=$admin_form->{AID}:history rightAlignText",
     $_FEES           => "3:AID=$admin_form->{AID}:fees rightAlignText",
     $_PAYMENTS       => "2:AID=$admin_form->{AID}:payments rightAlignText",
     $_PERMISSION     => "52:AID=$admin_form->{AID}:permissions rightAlignText",
     $_PASSWD         => "54:AID=$admin_form->{AID}:password rightAlignText",
     $_GROUP          => "58:AID=$admin_form->{AID}:users rightAlignText",
#     IP               => "59:AID=$admin_form->{AID}:",
  	 },
  	{
  		f_args => { ADMIN => $admin_form }
  	 });

  form_passwd({ ADMIN => $admin_form}) if (defined($FORM{newpassword}));

  if ($FORM{subf}) {
   	return 0;
   }
  elsif($FORM{change}) {
  	$admin_form->{MAIN_SESSION_IP}=$admin->{SESSION_IP};
    $admin_form->change({	%FORM  });
    if (! $admin_form->{errno}) {
      $html->message('info', $_CHANGED, "$_CHANGED ");	
     }
   }
  $admin_form->{ACTION}='change';
  $admin_form->{LNG_ACTION}=$_CHANGE;
 }
elsif ($FORM{add}) {
  $admin_form->{AID}=$admin->{AID};
  if (! $FORM{A_LOGIN}) {
      $html->message('err', $_ERROR, "$ERR_WRONG_DATA $_ADMIN $_LOGIN");  	
    }
  else {
    $admin_form->add({ %FORM, DOMAIN_ID => $admin->{DOMAIN_ID} });
    if (! $admin_form->{errno}) {
       $html->message('info', $_INFO, "$_ADDED");	
     }
   }
}
elsif($FORM{del} && $FORM{is_js_confirmed}) {
	if ($FORM{del} == $conf{SYSTEM_ADMIN_ID}) {
		$html->message('err', $_ERROR, "Can't delete system admin. Check ". '$conf{SYSTEM_ADMIN_ID}=1;');	
	 }
  else { 
  	$admin_form->{AID}=$admin->{AID};
  	$admin_form->del($FORM{del});
    if (! $admin_form->{errno}) {
      $html->message('info', $_DELETE, "$_DELETED");	
    }
   } 
}


if ($admin_form->{errno}) {
  $html->message('err', $_ERROR, $err_strs{$admin_form->{errno}});	
 }

$admin_form->{PASPORT_DATE} = $html->date_fld2('PASPORT_DATE', { FORM_NAME => 'admin_form',
	                                                            WEEK_DAYS => \@WEEKDAYS,
 	                                                            MONTHES   => \@MONTHES,
 	                                                            DATE      => $user_pi->{PASPORT_DATE}
                                                            });


$admin_form->{DISABLE} = ($admin_form->{DISABLE} > 0) ? 'checked' : '';
$admin_form->{GROUP_SEL} = sel_groups();

if ($admin->{DOMAIN_ID}) {
	$admin_form->{DOMAIN_SEL} = $admin->{DOMAIN_NAME};
 }
elsif (in_array('Multidoms', \@MODULES)) {
  load_module('Multidoms', $html);
  $admin_form->{DOMAIN_SEL} = multidoms_domains_sel();
 }
else  {
  $admin_form->{DOMAIN_SEL}  = '';  
 }

$html->tpl_show(templates('form_admin'), $admin_form);

my $table = $html->table({ width      => '100%',
	                         caption    => $_ADMINS,
                           border     => 1,
                           title      => ['ID',"$_LOGIN", $_FIO, $_CREATE, $_STATUS,  $_GROUPS, 'Domain', 
                              '-', '-', '-', '-', '-', '-'],
                           cols_align => ['right', 'left', 'left', 'right', 'left', 'left', 'center', 
                              'center', 'center', 'center', 'center', 'center'],
                           ID         => 'ADMINS_LIST'
                         });

my $list = $admin_form->admins_groups_list({ ALL => 1 });
my %admin_groups=();
foreach my $line ( @$list) {
	$admin_groups{$line->[1]}.=", $line->[0]:$line->[2]";
}

$list = $admin->list({ %LIST_PARAMS, DOMAIN_ID => $admin->{DOMAIN_ID} });
foreach my $line (@$list) {
  $table->addrow($line->[0], 
    $line->[1], 
    $line->[2], 
    $line->[3], 
    $status[$line->[4]], 
    $line->[5] . $admin_groups{$line->[0]}, 
    $line->[6],
   $html->button($_PERMISSION, "index=$index&subf=52&AID=$line->[0]", { CLASS => 'permissions' }),
   $html->button($_LOG, "index=$index&subf=51&AID=$line->[0]", { CLASS => 'history' }),
   $html->button($_PASSWD, "index=$index&subf=54&AID=$line->[0]", { CLASS => 'password' }),
   $html->button($_INFO, "index=$index&AID=$line->[0]", { CLASS => 'change' }), 
   $html->button($_DEL, "index=$index&del=$line->[0]", { MESSAGE => "$_DEL ?",  CLASS => 'del' } ));
}
print $table->show();

$table = $html->table( { width      => '100%',
                         cols_align => ['right', 'right'],
                         rows       => [ [ "$_TOTAL:", $html->b($admin->{TOTAL}) ] ]
                     } );
print $table->show();
}

#**********************************************************
# form_admins_group();
#**********************************************************
sub form_admins_groups {
  my ($attr) = @_; 

  if(! defined($attr->{ADMIN})) {
    $FORM{subf}=58;
    form_admins();
    return 0;	
   }
  my $admin = $attr->{ADMIN};

if ($FORM{change}) {
	my $admin = $attr->{ADMIN};
	$admin->admin_groups_change({ %FORM });
  if ($admin->{errno}) {
    $html->message('err', $_ERROR, "[$admin->{errno}] $err_strs{$admin->{errno}}");	
   }
  else {
    $html->message('info', $_CHANGED, "$_CHENGED GID: [$FORM{GID}]");
   }
 }

my $table = $html->table( { width      => '100%',
                            caption    => $_GROUP,
                            border     => 1,
                            title      => ['ID', $_NAME, '-' ],
                            cols_align => ['left', 'left', 'center' ],
                        } );

my $list = $admin->admins_groups_list({ AID => $LIST_PARAMS{AID}  });
my %admins_group_hash = ();

foreach my $line (@$list) {
	$admins_group_hash{$line->[0]}=1;
}

$list = $users->groups_list();
foreach my $line (@$list) {
  $table->addrow(
     $html->form_input('GID', "$line->[0]", { TYPE => 'checkbox', STATE => (defined($admins_group_hash{$line->[0]})) ? 'checked' : undef }) . $line->[0], 
     $line->[1],
     ''
    );
}

print $html->form_main({ CONTENT => $table->show({ OUTPUT2RETURN => 1 }),
	                       HIDDEN  => { index => $index,
                                      AID   => "$FORM{AID}",
                                      subf  => "$FORM{subf}"
                                     },
	                       SUBMIT  => { change   => "$_CHANGE"
	                       	           } 
	                     });
}


##**********************************************************
## form_admins_ips();
##**********************************************************
#sub form_admins_ips {
#  my ($attr) = @_; 
#
#  if(! defined($attr->{ADMIN})) {
#    $FORM{subf}=59;
#    form_admins();
#    return 0;	
#   }
#
#my $admin = $attr->{ADMIN};
#if ($FORM{add}) {
#	my $admin = $attr->{ADMIN};
#	$admin->allow_ip_add({ %FORM });
#  if ($admin->{errno}) {
#    $html->message('err', $_ERROR, "[$admin->{errno}] $err_strs{$admin->{errno}}");	
#   }
#  else {
#    $html->message('info', $_ADDED, "$_ADDED $FORM{IP}");
#   }
# }
#elsif ($FORM{del} && $FORM{is_js_confirmed}) {
#  $admin->allow_ip_del({ %FORM });
#  if (! $nas->{errno}) {
#    $html->message('info', $_INFO, "$_DELETED [$FORM{IP}]");
#   }
#}
#
#$admin->{ACTION}='add';
#$admin->{LNG_ACTION}=$_ADD;
#
#$html->tpl_show(templates('form_admin_allow_ip'), $admin);
#
#my $table = $html->table( { width      => '400',
#                            caption    => "$_ALLOW IP",
#                            border     => 1,
#                            title      => ['IP', '-' ],
#                            cols_align => ['left', 'center' ],
#                        } );
#
#my $list = $admin->allow_ip_list({ AID => $LIST_PARAMS{AID}  });
#foreach my $line (@$list) {
#  $table->addrow(
#     $line->[0],
#     $html->button($_DEL, "index=$index&del=1&IP=$line->[0]&AID=$FORM{AID}", { MESSAGE => "$_DEL IP '$line->[0]'?", BUTTON => 1  }) 
#    );
#}
#
#print $table->show();
#
#}

#**********************************************************
# permissions();
#**********************************************************
sub form_admin_permissions {
 my ($attr) = @_;
 my %permits = ();

 if(! defined($attr->{ADMIN})) {
    $FORM{subf}=52;
    form_admins();
    return 0;	
  }

 my $admin_form = $attr->{ADMIN};

 if ($FORM{set}) {
   while(my($k, $v)=each(%FORM)) {
       if ($v eq '1') {
         my($section_index, $action_index)=split(/_/, $k, 2);
         $permits{$section_index}{$action_index}=1 if ($section_index >= 0);
        }
    }

   $admin_form->{MAIN_AID}=$admin->{AID};
   $admin_form->{MAIN_SESSION_IP}=$admin->{SESSION_IP};
   $admin_form->set_permissions(\%permits);

   if ($admin_form->{errno}) {
     $html->message('err', $_ERROR, "[$admin_form->{errno}] $err_strs{$admin_form->{errno}}");
    }
   else {
     $html->message('info', $_INFO, "$_CHANGED");
    }
  }

 my $p = $admin_form->get_permissions();
 if ($admin_form->{errno}) {
    $html->message('err', $_ERROR, "$err_strs{$admin->{errno}}");
    return 0;
  }

my %ADMIN_TYPES = (1 => "$_ALL $_PERMISSION",
                   2 => "$_MANAGER",
                   3 => "$_SUPPORT",
                   4 => "$_ACCOUNTANT",
                   );


if ($FORM{ADMIN_TYPE}) {
	my %admins_type_permits = ();
	my %admins_modules      = ();

  $admins_type_permits{1} = {
    0 => { 0 => 1,
           1 => 1,
   	       2 => 1,
   	       3 => 1,
   	       4 => 1,
   	       5 => 1,
   	       6 => 1,
   	       7 => 1,
   	       8 => 1, 
   	       9 => 1, 
   	       10=> 1, 
   	       11=> 1
   	      },
   	1 => { 0 => 1,
   	       1 => 1,
   	       2 => 1,
   	       3 => 1,
   	       4 => 1 
   	      },
   	2 => { 0 => 1,
   	       1 => 1,
   	       2 => 1,
   	       3 => 1
   	      },
   	3 => { 0 => 1,
   	       1 => 1
   	      },
   	4 => { 0 => 1,
   	       1 => 1,
   	       2 => 1,
   	       3 => 1,
   	       4 => 1,
   	       5 => 1,
   	       6 => 1
   		    },
   	5 => { 0 => 1,
   		     1 => 1
   		    },
   	6 => { 0 => 1 },
   	7 => { 0 => 1 },
  	8 => { 0 => 1 },
	};

  $admins_type_permits{2} = {
    0 => { 0 => 1,
           1 => 1,
   	       2 => 1,
   	       3 => 1,
   	       4 => 1,
   	       9 => 1, 
   	       10=> 1,
   	       11=> 1 
   	      },
   	1 => { 0 => 1,
   	       1 => 1,
   	      },
   	2 => { 0 => 1,
   	       1 => 1,
   	      },
   	5 => { 0 => 1,
   		     1 => 1
   		    },
   	6 => { 0 => 1 },
   	7 => { 0 => 1 },
  	8 => { 0 => 1 },
	};


  $admins_type_permits{3} = {
    0 => { 0 => 1,
           2 => 1,
   	      },
   	5 => { 0 => 1,
   		     1 => 1
   		    },
   	6 => { 0 => 1 },
   	7 => { 0 => 1 },
  	8 => { 0 => 1 },
	};

  $admins_modules{3} = { 'Msgs'      => 1,
  	                     'Maps'      => 1,
  	                     'Snmputils' => 1,
  	                     'Notepad'   => 1 };

  $admins_type_permits{4} = {
    0 => { 0 => 1,
   	       2 => 1,
   	      },
   	1 => { 0 => 1,
   	       1 => 1,
   	       2 => 1,
   	       3 => 1,
   	       4 => 1 
   	      },
   	2 => { 0 => 1,
   	       1 => 1,
   	       2 => 1,
   	       3 => 1
   	      },
   	3 => { 0 => 1,
   	       1 => 1
   	      },
   	6 => { 0 => 1 },
   	7 => { 0 => 1 },
  	8 => { 0 => 1 },
	};

  $admins_modules{4} = { 'Docs'      => 1,
  	                     'Paysys'    => 1,
  	                     'Cards'     => 1,
  	                     'Extfin'    => 1,
  	                     'Notepad'   => 1
  	                    };

  %permits               = %{ $admins_type_permits{$FORM{ADMIN_TYPE}} };
  $admin_form->{MODULES} = $admins_modules{$FORM{ADMIN_TYPE}};
 }
else {
	%permits = %$p;
}


foreach my $k (sort keys(%ADMIN_TYPES)) {
	my $button = ($FORM{ADMIN_TYPE} eq $k) ? $html->b($ADMIN_TYPES{$k}. ' ') : $html->button($ADMIN_TYPES{$k}, "index=$index&subf=$FORM{subf}&AID=$FORM{AID}&ADMIN_TYPE=$k", { BUTTON => 1 }) .'  ';
	print $button;
}



my $table = $html->table( { width       => '90%',
                            border      => 1,
                            caption     => "$_PERMISSION",
                            title_plain => ['ID', $_NAME, $_DESCRIBE, '-'],
                            cols_align  => ['right', 'left', 'center'],
                            ID          => 'ADMIN_PERMISSIONS',
                        } );


foreach my $k ( sort keys %menu_items ) {
  my $v = $menu_items{$k};
  
  if (defined($menu_items{$k}{0}) && $k > 0) {
  	$table->{rowcolor}='row_active';
  	$table->addrow("$k:", $html->b($menu_items{$k}{0}), '', '');
    $k--;
    my $actions_list = $actions[$k];
    my $action_index = 0;
    $table->{rowcolor}=undef;
    foreach my $action (@$actions_list) {
      $table->addrow("$action_index", "$action", '',
      $html->form_input($k."_$action_index", 1, { TYPE          => 'checkbox',
       	                                          OUTPUT2RETURN => 1,
       	                                          STATE         => (defined($permits{$k}{$action_index})) ? '1' : undef  
       	                                         })  
       	                                              );

      $action_index++;
     }
   }
 }

if (in_array('Multidoms', \@MODULES)) {
  	my $k=10;
  	$table->{rowcolor}='row_active';
  	$table->addrow("10:", $html->b($_DOMAINS), '', '');
    my $actions_list  = $actions[9];
    my $action_index  = 0;
    $table->{rowcolor}= undef;
    foreach my $action (@$actions_list) {
      $table->addrow("$action_index", "$action", '',
        $html->form_input($k."_$action_index", 1, { TYPE          => 'checkbox',
       	                                            OUTPUT2RETURN => 1,
       	                                            STATE         => (defined($permits{$k}{$action_index})) ? '1' : undef  
       	                                         })  
       	                                     );
      $action_index++;
     }
}

my $table2 = $html->table( { width       => '500',
                            border      => 1,
                            caption     => "$_MODULES",
                            title_plain => [$_NAME, ''],
                            cols_align  => ['right', 'left', 'center'],
                            ID          => 'ADMIN_MODULES'
                        } );


my $i=0;
foreach my $name (sort @MODULES) {
  	$table2->addrow("$name", 
  	  	$html->form_input("9_". $i. "_". $name, '1', { TYPE          => 'checkbox',
       	                                 OUTPUT2RETURN => 1,
       	                                 STATE         => ($admin_form->{MODULES}{$name}) ? '1' : undef  
       	                                    })
       	                                   );
   $i++;
 }
  
  
print $html->form_main({ CONTENT => $table->show({ OUTPUT2RETURN => 1 }).
	                        $table2->show({ OUTPUT2RETURN => 1 }),
	                       HIDDEN  => { index => '50',
                                      AID   => "$FORM{AID}",
                                      subf  => "$FORM{subf}"
                                     },
	                       SUBMIT  => { set   => "$_SET"
	                       	           } });
}


#**********************************************************
# 
# profile()
#**********************************************************
sub admin_profile {
 #my ($admin) = @_;

 my @colors_descr = ('# 0 TH', 
                     '# 1 TD.1',
                     '# 2 TD.2',
                     '# 3 TH.sum, TD.sum',
                     '# 4 border',
                     '# 5',
                     '# 6 Error, Warning',
                     '# 7 vlink',
                     '# 8 link',
                     '# 9 Text',
                     '#10 background'
                    );

if ($FORM{colors}) {
  print "$FORM{colors} ". $html->{language};
}


my $REFRESH= $admin->{WEB_OPTIONS}{REFRESH}   || 60;
my $ROWS   = $admin->{WEB_OPTIONS}{PAGE_ROWS} || $PAGE_ROWS;


my $SEL_LANGUAGE = $html->form_select('language', 
                                { 
 	                                SELECTED  => $html->{language},
 	                                SEL_HASH  => \%LANG 
 	                               });

print << "[END]";
<form action="$SELF_URL" METHOD="POST">
<input type="hidden" name="index" value="$index"/>
<input type="hidden" name="AWEB_OPTIONS" value="1"/>
<TABLE width="640" cellspacing="0" cellpadding="0" border="0"><tr><TD bgcolor="$_COLORS[4]">
<TABLE width="100%" cellspacing="1" cellpadding="0" border="0"><tr bgcolor="$_COLORS[1]"><td colspan="2">$_LANGUAGE:</td>
<td>$SEL_LANGUAGE</td></tr>
<tr bgcolor="$_COLORS[1]"><th colspan="3">&nbsp;</th></tr>
<tr bgcolor="$_COLORS[0]"><th colspan="2">$_PARAMS</th><th>$_VALUE</th></tr>

[END]


 for($i=0; $i<=10; $i++) {
   print "<tr bgcolor=\"$_COLORS[1]\"><td width=30% bgcolor=\"$_COLORS[$i]\">$i</td><td>$colors_descr[$i]</td><td><input type=text name=colors value='$_COLORS[$i]'></td></tr>\n";
  } 
 

print "
</table>
<br>
<table width=\"100%\">
<tr><td colspan=\"2\">&nbsp;</td></tr>
<tr><td>$_REFRESH (sec.):</td><td><input type='input' name='REFRESH' value='$REFRESH'/></td></tr>
<tr><td>$_ROWS:</td><td><input type='input' name='PAGE_ROWS' value='$PAGE_ROWS'/></td></tr>
</table>
</td></tr></table>
<br>
<input type='submit' name='set' value='$_SET'/> 
<input type='submit' name='default' value='$_DEFAULT'/>
</form><br>\n";
   
my %profiles = ();
$profiles{'Black'} = "#333333, #000000, #444444, #555555, #777777, #FFFFFF, #FF0000, #BBBBBB, #FFFFFF, #EEEEEE, #000000";
$profiles{'Green'} = "#33AA44, #FFFFFF, #eeeeee, #dddddd, #E1E1E1, #FFFFFF, #FF0000, #000088, #0000A0, #000000, #FFFFFF";
$profiles{'Ligth Green'} = "#4BD10C, #FFFFFF, #eeeeee, #dddddd, #E1E1E1, #FFFFFF, #FF0000, #000088, #0000A0, #000000, #FFFFFF";
$profiles{'IO'} = "#FCBB43, #FFFFFF, #eeeeee, #dddddd, #E1E1E1, #FFFFFF, #FF0000, #000088, #0000A0, #000000, #FFFFFF";
$profiles{'Cisco'} = "#99CCCC, #FFFFFF, #FFFFFF, #669999, #669999, #FFFFFF, #FF0000, #003399, #003399, #000000, #FFFFFF";

while(my($thema, $colors)=each %profiles ) {
  my $url = "index=$index&AWEB_OPTIONS=1&set=set";
  my @c = split(/, /, $colors);
  foreach my $line (@c) {
      $line =~ s/#/%23/ig;
      $url .= "&colors=$line";
    }
  print ' '. $html->button("$thema", $url, { BUTTON => 1 });
}

 return 0;
}


#**********************************************************
# form_nas
#**********************************************************
sub form_nas {
  my $nas = Nas->new($db, \%conf);	
  $nas->{ACTION}='add';
  $nas->{LNG_ACTION}=$_ADD;

if($FORM{NAS_ID}) {
  $nas->info( { NAS_ID => $FORM{NAS_ID}	} );
  $pages_qs .= "&NAS_ID=$FORM{NAS_ID}&subf=$FORM{subf}";
  $LIST_PARAMS{NAS_ID} = $FORM{NAS_ID};
  %F_ARGS = ( NAS => $nas );
  
  if ($nas->{NAS_TYPE} eq 'chillispot' && -f "../wrt_configure.cgi") {
    $ENV{HTTP_HOST} =~ s/\:(\d+)//g;
    $nas->{EXTRA_PARAMS} = $html->tpl_show(templates('form_nas_configure'), { %$nas,
    	 CONFIGURE_DATE => "wget -O /tmp/setup.sh http://$ENV{HTTP_HOST}/hotspot/wrt_configure.cgi?". (($nas->{DOMAIN_ID}) ? "DOMAIN_ID=$nas->{DOMAIN_ID}\\\&" : '') ."NAS_ID=$nas->{NAS_ID}; chmod 755 /tmp/setup.sh; /tmp/setup.sh",
    	 PARAM1  => "wget -O /tmp/setup.sh http://$ENV{HTTP_HOST}/hotspot/wrt_configure.cgi?DOMAIN_ID=$admin->{DOMAIN_ID}\\\&NAS_ID=$nas->{NAS_ID}",
    	 PARAM2  => "; chmod 755 /tmp/setup.sh; /tmp/setup.sh",
    	 }, { OUTPUT2RETURN => 1 });
   }
  
  $nas->{CHANGED} = "($_CHANGED: $nas->{CHANGED})";
  $nas->{NAME_SEL} = $html->form_main({ CONTENT => $html->form_select('NAS_ID', 
                                         { 
 	                                          SELECTED  => $FORM{NAS_ID},
 	                                          SEL_MULTI_ARRAY   => $nas->list({ %LIST_PARAMS }),
 	                                          MULTI_ARRAY_KEY   => 0,
 	                                          MULTI_ARRAY_VALUE => 1,
 	                                        }),
	                       HIDDEN  => { index => '61',
                                      AID   => "$FORM{AID}",
                                      subf  => "$FORM{subf}"
                                     },
	                       SUBMIT  => { show   => "$_SHOW"
	                       	           } });

  func_menu({ 
  	         'ID' =>   $nas->{NAS_ID}, 
  	         $_NAME => $nas->{NAME_SEL}
  	       }, 
  	{ 
  	 $_INFO          => ":NAS_ID=$nas->{NAS_ID}",
     'IP Pools'      => "62:NAS_ID=$nas->{NAS_ID}",
     $_STATS         => "63:NAS_ID=$nas->{NAS_ID}"
  	 },
  	{
  		f_args => { %F_ARGS }
  	 });

  if ($FORM{subf}) {
  	return 0;
   }
  elsif($FORM{change}) {
    $nas->change({ %FORM, DOMAIN_ID => $admin->{DOMAIN_ID} });  
    if (! $nas->{errno}) {
       $html->message('info', $_CHANGED, "$_CHANGED $nas->{NAS_ID}");
     }
   }

  $nas->{LNG_ACTION}=$_CHANGE;
  $nas->{ACTION}='change';
 }
elsif ($FORM{add}) {
  $nas->add({	%FORM, DOMAIN_ID => $admin->{DOMAIN_ID}	});

  if (! $nas->{errno}) {
    $html->message('info', $_INFO, "$_ADDED '$FORM{NAS_IP}'");
   }
 }
elsif ($FORM{del} && $FORM{is_js_confirmed}) {
  $nas->del($FORM{del});
  if (! $nas->{errno}) {
    $html->message('info', $_INFO, "$_DELETED [$FORM{del}]");
   }
}

if ($nas->{errno}) {
  $html->message('err', $_ERROR, "$err_strs{$nas->{errno}}");
 }

 my %nas_descr = (
  '3com_ss'   => "3COM SuperStack Switch",
  'nortel_bs' => "Nortel Baystack Switch",
  'asterisk'  => "Asterisk",
  'usr'       => "USR Netserver 8/16",
  'pm25'      => 'LIVINGSTON portmaster 25',
  'ppp'       => 'FreeBSD ppp demon',
  'exppp'     => 'FreeBSD ppp demon with extended futures',
  'dslmax'    => 'ASCEND DSLMax',
  'celan'     => 'CeLAN Switch',
  'expppd'    => 'pppd deamon with extended futures',
  'edge_core' => 'EdgeCore Switch',
  'radpppd'   => 'pppd version 2.3 patch level 5.radius.cbcp',
  'lucent_max'=> 'Lucent MAX',
  'mac_auth'  => 'MAC auth',
  'mpd'       => 'MPD with kha0s patch',
  'mpd4'      => 'MPD 4.xx',
  'mpd5'      => 'MPD 5.xx',
  'ipcad'     => 'IP accounting daemon with Cisco-like ip accounting export',
  'lepppd'    => 'Linux PPPD IPv4 zone counters',
  'pppd'      => 'pppd + RADIUS plugin (Linux)',
  'pppd_coa'  => 'pppd + RADIUS plugin + radcoad (Linux)',
  'accel_pptp'=> 'Linux accel-pptp',
  'gnugk'     => 'GNU GateKeeper',
  'cid_auth'  => 'Auth clients by CID',
  'cisco'     => 'Cisco',
  'cisco_voip'=> 'Cisco Voip',
  'dell'      => 'Dell Switch',
  'cisco_isg' => 'Cisco ISG',
  'patton'    => 'Patton RAS 29xx',
  'cisco_air' => 'Cisco Aironets',
  'bsr1000'   => 'CMTS Motorola BSR 1000',
  'mikrotik'  => 'Mikrotik (http://www.mikrotik.com)',
  'dlink_pb'  => 'Dlink IP-MAC-Port Binding',
  'other'     => 'Other nas server',
  'chillispot'=> 'Chillispot (www.chillispot.org)',
  'openvpn'   => 'OpenVPN with RadiusPlugin',
  'vlan'      => 'Vlan managment',
  'qbridge'   => 'Q-BRIDGE',
  'dhcp'      => 'DHCP FreeRadius in DHCP mode',
  'ls_pap2t'  => 'Linksys pap2t',
  'ls_spa8000'=> 'Linksys spa8000'
 );


  if (defined($conf{nas_servers})) {
  	%nas_descr = ( %nas_descr,  %{$conf{nas_servers}} );
   }

  $nas->{SEL_TYPE} = $html->form_select('NAS_TYPE', 
                                { SELECTED   => $nas->{NAS_TYPE},
 	                                SEL_HASH   => \%nas_descr,
 	                                SORT_KEY   => 1 
 	                               });

  $nas->{SEL_AUTH_TYPE} = $html->form_select('NAS_AUTH_TYPE', 
                                { SELECTED     => $nas->{NAS_AUTH_TYPE},
 	                                SEL_ARRAY    => \@auth_types,
                                  ARRAY_NUM_ID => 1
 	                               });

  $nas->{NAS_EXT_ACCT} = $html->form_select('NAS_EXT_ACCT', 
                                { SELECTED     => $nas->{NAS_EXT_ACCT},
 	                                SEL_ARRAY    => ['', 'IPN'],
                                  ARRAY_NUM_ID => 1 	                                
 	                               });

  $nas->{NAS_DISABLE}   = ($nas->{NAS_DISABLE} > 0) ? ' checked' : '';

    if ($conf{ADDRESS_REGISTER}) {
     	$nas->{ADDRESS_TPL} = $html->tpl_show(templates('form_address_sel'), $nas, { OUTPUT2RETURN => 1 });
     }
    else {
  	  my $countries = $html->tpl_show(templates('countries'), undef, { OUTPUT2RETURN => 1 });
  	  my @countries_arr  = split(/\n/, $countries);
      my %countries_hash = ();
      foreach my $c (@countries_arr) {
    	  my ($id, $name)=split(/:/, $c);
    	  $countries_hash{int($id)}=$name;
       }
      $nas->{COUNTRY_SEL} = $html->form_select('COUNTRY_ID', 
                                { SELECTED   => $FORM{COUNTRY_ID},
 	                                SEL_HASH   => {'' => '', %countries_hash },
 	                                NO_ID      => 1
 	                               });

      $nas->{ADDRESS_TPL}   = $html->tpl_show(templates('form_address'), $nas, { OUTPUT2RETURN => 1 });
    }

  $nas->{NAS_GROUPS_SEL}= sel_nas_groups({ GID => $nas->{GID} });
  $html->tpl_show(templates('form_nas'), $nas);



my $table = $html->table({ width      => '100%',
                        cols_align => ['right', 'right',],
                        rows       => [ [ "$_GROUPS:", sel_nas_groups(). $html->form_input("1", "$_SHOW", { TYPE => 'submit' })  ] ]
                      });

print $html->form_main({  CONTENT => $table->show(),
	                        HIDDEN  => { index  => "$index",
                                     },
                       });


$table = $html->table( { width      => '100%',
                            caption    => "$_NAS",
                            title      => ["ID", "$_NAME", "NAS-Identifier", "IP", "$_TYPE", "$_AUTH", 
                             "$_STATUS", "$_DESCRIBE", '-', '-', '-'],
                            cols_align => ['center', 'left', 'left', 'right', 'left', 'left', 'center', 'left', 
                              'center:noprint', 'center:noprint', 'center:noprint'],
                            ID         => 'NAS_LIST'
                           });

my $list = $nas->list({ %FORM, %LIST_PARAMS, DOMAIN_ID => $admin->{DOMAIN_ID} });
foreach my $line (@$list) {
  my $delete = $html->button($_DEL, "index=61&del=$line->[0]", { MESSAGE => "$_DEL NAS '$line->[1]'?", CLASS => 'del', TEXT => $_DEL  }); 
  
  $table->{rowcolor} = ($FORM{NAS_ID} && $FORM{NAS_ID} == $line->[0]) ? 'row_active' : undef ;
  
  $table->addrow($line->[0], 
    $line->[1], 
    $line->[2], 
    $line->[3], $line->[4], $auth_types[$line->[5]], 
    $status[$line->[6]],
    $line->[7],
    $html->button("IP POOLs", "index=62&NAS_ID=$line->[0]", { BUTTON => 1 }),
    $html->button("$_CHANGE", "index=61&NAS_ID=$line->[0]", { CLASS => 'change', TEXT => $_CHANGE  }),
    $delete);
}
print $table->show();

$table = $html->table( { width      => '100%',
                         cols_align => ['right', 'right'],
                         rows       => [ [ "$_TOTAL:", $html->b($nas->{TOTAL}) ] ]
                     } );
print $table->show();
}



#**********************************************************
# sel_nas_groups
#**********************************************************
sub sel_nas_groups {
  my ($attr) = @_;

  my $GROUPS_SEL = '';
  my $GID = $attr->{GID} || $FORM{GID};

  my $nas = Nas->new($db, \%conf);	
  $GROUPS_SEL = $html->form_select('GID', 
                                { 
 	                                SELECTED          => $GID,
 	                                SEL_MULTI_ARRAY   => $nas->nas_group_list({ DOMAIN_ID => $admin->{DOMAIN_ID} }),
 	                                MULTI_ARRAY_KEY   => 0,
 	                                MULTI_ARRAY_VALUE => 1,
 	                                SEL_OPTIONS       => { 0 => "" }
 	                               });

  return $GROUPS_SEL;	
}

#**********************************************************
# form_nas
#**********************************************************
sub form_nas_groups {
  
  my $nas = Nas->new($db, \%conf);	
  $nas->{ACTION}     = 'add';
  $nas->{LNG_ACTION} = $_ADD;


if ($FORM{add}) {
  $nas->nas_group_add( { %FORM, DOMAIN_ID => $admin->{DOMAIN_ID} });
  if (! $nas->{errno}) {
      $html->message('info', $_ADDED, "$_ADDED");
    }
 }
elsif($FORM{change}){
  $nas->nas_group_change({ %FORM });
  if (! $nas->{errno}) {
    $html->message('info', $_CHANGED, "$_CHANGED $nas->{GID}");
   }
 }
elsif($FORM{chg}){
  $nas->nas_group_info({ ID => $FORM{chg} });

  $nas->{ACTION}='change';
  $nas->{LNG_ACTION}=$_CHANGE;
 }
elsif(defined($FORM{del}) && $FORM{is_js_confirmed}){
  $nas->nas_group_del( $FORM{del} );
  if (! $nas->{errno}) {
    $html->message('info', $_DELETED, "$_DELETED $users->{GID}");
   }
}


if ($nas->{errno}) {
   $html->message('err', $_ERROR, "[$nas->{errno}] $err_strs{$nas->{errno}}");	
  }


$nas->{DISABLE} = ($nas->{DISABLE}) ? ' checked' : '';

$html->tpl_show(templates('form_nas_group'), $nas);

my $list = $nas->nas_group_list({ %LIST_PARAMS, DOMAIN_ID => $admin->{DOMAIN_ID} });
my $table = $html->table( { width      => '100%',
                            caption    => "$_NAS $_GROUPS",
                            border     => 1,
                            title      => ['#', $_NAME, $_COMMENTS, $_STATUS, '-', '-', '-'],
                            cols_align => ['right', 'left', 'left', 'center', 'center:noprint', 'center:noprint'],
                            qs         => $pages_qs,
                            pages      => $nas->{TOTAL}
                       } );

foreach my $line (@$list) {
  my $delete = $html->button($_DEL, "index=$index$pages_qs&del=$line->[0]", { MESSAGE => "$_DEL [$line->[0]]?", CLASS => 'del' }); 

  $table->addrow($html->b($line->[0]), 
   "$line->[1]", 
   "$line->[2]", 
   $html->color_mark($status[$line->[3]], $state_colors[$line->[3]]),
   $html->button($_NAS, "index=". ($index - 3) ."&GID=$line->[0]", { BUTTON => 1 }), 
   $html->button($_CHANGE, "index=$index&chg=$line->[0]", { CLASS => 'change' }),
   $delete);
}
print $table->show();


$table = $html->table({ width      => '100%',
                        cols_align => ['right', 'right'],
                        rows       => [ [ "$_TOTAL:", $html->b($nas->{TOTAL}) ] ]
                      });
print $table->show();
}


#**********************************************************
# form_ip_pools()
#**********************************************************
sub form_ip_pools {
	my ($attr) = @_;
	my $nas;

  $nas->{ACTION}='add';
  $nas->{LNG_ACTION}="$_ADD";

  
if ($attr->{NAS}) {
	$nas = $attr->{NAS};

 	if ($FORM{BIT_MASK} && ! $FORM{NAS_IP_COUNT}) {
 		my $mask = 0b0000000000000000000000000000001;
    $FORM{NAS_IP_COUNT} =  sprintf("%d", $mask << ($FORM{BIT_MASK}-1)) -1;
 	 }

  if ($FORM{add}) {
 
    if ($FORM{POOL_SPEED} && ! $FORM{BIT_MASK}) {
    	$html->message('err', "$_ERROR", "Select Mask");
     }
  	else {
      $nas->ip_pools_add({ %FORM  });
      if (! $nas->{errno}) {
        $html->message('info', $_INFO, "$_ADDED");
       }
     }
   }
  elsif($FORM{change}) {
    if ($FORM{POOL_SPEED} && ! $FORM{BIT_MASK}) {
    	$html->message('err', "$_ERROR", "Select Mask");
     }
  	else {
      $nas->ip_pools_change({ %FORM, 
    	                      ID => $FORM{chg},
    	                      NAS_IP_SIP_INT => ip2int($FORM{NAS_IP_SIP}) });

      if (! $nas->{errno}) {
         $html->message('info', $_INFO, "$_CHANGED");
       }
     }
   }
  elsif($FORM{chg}) {
    $nas->ip_pools_info($FORM{chg});

    if (! $nas->{errno}) {
       $html->message('info', $_INFO, "$_CHANGING");
       $nas->{ACTION}='change';
       $nas->{LNG_ACTION}="$_CHANGE";
     }
   }
  elsif($FORM{set}) {
    $nas->nas_ip_pools_set({ %FORM });

    if (! $nas->{errno}) {
       $html->message('info', $_INFO, "$_CHANGED");
     }
   }
  elsif($FORM{del} && $FORM{is_js_confirmed} ) {
    $nas->ip_pools_del( $FORM{del} );

    if (! $nas->{errno}) {
       $html->message('info', $_INFO, "$_DELETED");
     }
   }
  
  $pages_qs        = "&NAS_ID=$nas->{NAS_ID}";
  $nas->{STATIC}   = ' checked' if ($nas->{STATIC});
  $nas->{BIT_MASK} = $html->form_select('BIT_MASK', 
                                { SELECTED      => $FORM{BIT_MASK},
 	                                SEL_ARRAY     => ['', 32, 31, 30, 29, 28, 27,26,25,24,23,22,21,20,19,18,17,16],
 	                                ARRAY_NUM_ID  => 1
 	                               });
  
  $html->tpl_show(templates('form_ip_pools'), { %FORM, %$nas, INDEX => 62 });
 }
elsif($FORM{NAS_ID}) {
  $FORM{subf}=$index;
  form_nas();
  return 0;
 }
else {
  $nas = Nas->new($db, \%conf);	
}

if ($nas->{errno}) {
  $html->message('err', $_ERROR, "$err_strs{$nas->{errno}}");
 }

my $list = $nas->nas_ip_pools_list({ %LIST_PARAMS });	
my $table = $html->table( { width      => '100%',
                            caption    => "NAS IP POOLs",
                            border     => 1,
                            title      => ['', "NAS", "$_NAME", "$_BEGIN", "$_END", "$_COUNT", "$_PRIORITY", "$_SPEED (Kbits)", '-', '-'],
                            cols_align => ['right', 'left', 'right', 'right', 'right', 'right', 'center', 'center'],
                            qs         => $pages_qs,
                            pages      => $payments->{TOTAL},
                            ID         => 'NAS_IP_POOLS'
                           });



foreach my $line (@$list) {
  my $delete = $html->button($_DEL, "index=62$pages_qs&del=$line->[10]", { MESSAGE => "$_DEL POOL $line->[10]?", CLASS => 'del' }); 
  my $change = $html->button($_CHANGE, "index=62$pages_qs&chg=$line->[10]", { CLASS => 'change' }); 
  $table->{rowcolor} = ($line->[10] eq $FORM{chg}) ? 'row_active' : undef;

  $table->addrow(
    ($line->[12]) ? 'static' : $html->form_input('ids', $line->[10], { TYPE => 'checkbox', STATE => ($line->[0]) ? 'checked' : undef }),
    $html->button($line->[1], "index=61&NAS_ID=$line->[10]"), 
    $line->[2],
    $line->[8], 
    $line->[9],
    $line->[5], 
    $line->[6],
    $line->[7],
    $change,
    $delete);
}


print $html->form_main({  CONTENT => $table->show(),
	                        HIDDEN  => { index  => "62",
                                       NAS_ID => "$FORM{NAS_ID}",
                                     },
	                        SUBMIT  => { set   => "$_SET"
	                       	           } });


return 0;
}

#**********************************************************
# form_nas_stats()
#**********************************************************
sub form_nas_stats {
  my ($attr) = @_;
  my $nas;

if ($attr->{NAS}) {
	$nas = $attr->{NAS};

 }
elsif($FORM{NAS_ID}) {
  $FORM{subf}=$index;
  form_nas();
  return 0;
 }
else {
	$nas = Nas->new($db, \%conf);	
}


my $table = $html->table( { width      => '100%',
                            caption    => "$_STATS",
                            border     => 1,
                            title      => ["NAS", "NAS_PORT", "$_SESSIONS", "$_LAST_LOGIN", "$_AVG", "$_MIN", "$_MAX"],
                            cols_align => ['left', 'right', 'right', 'right', 'right', 'right', 'right'],
                            ID         => 'NAS_STATS'
                        } );

my $list = $nas->stats({ %LIST_PARAMS });	

foreach my $line (@$list) {
  $table->addrow($html->button($line->[0], "index=61&NAS_ID=$line->[7]"), 
     $line->[1], $line->[2],  $line->[3],  $line->[4], $line->[5], $line->[6] );
}

print $table->show();
}


#**********************************************************
# form_back_money()
#**********************************************************
sub form_back_money {
  my ($type, $sum, $attr)	= @_;
  my $UID;

if ($type eq 'log') {
	if(defined($attr->{LOGIN})) {
     my $list = $users->list( { LOGIN => $attr->{LOGIN} } );

     if($users->{TOTAL} < 1) {
     	 $html->message('err', $_USER, "[$users->{errno}] $err_strs{$users->{errno}}");
     	 return 0;
      }
	   $UID = $list->[0]->[6];
	 }
  else {
	  $UID = $attr->{UID};
   }
}

my $user = $users->info($UID);

my $OP_SID = mk_unique_value(16);

print $html->form_main({HIDDEN  => { index  => "$index",
                                     subf   => "$index",
                                     sum    => "$sum",
                                     OP_SID => "$OP_SID",
                                     UID    => "$UID",
                                     BILL_ID => $user->{BILL_ID}
                                     },
                        SUBMIT  => { bm   => "$_BACK_MONEY ?"
	                       	           } });
}


#**********************************************************
# form_passwd($attr)
#**********************************************************
sub form_passwd {
 my ($attr)=@_;

 my $password_form; 
 
 if (defined($FORM{AID})) {
   $password_form->{HIDDDEN_INPUT} = $html->form_input('AID', "$FORM{AID}", { TYPE => 'hidden',
       	                                OUTPUT2RETURN => 1
       	                               });
 	 $index=50;
 	}
 elsif (defined($attr->{USER_INFO})) {
	 $password_form->{HIDDDEN_INPUT} = $html->form_input('UID', "$FORM{UID}", { TYPE => 'hidden',
       	                               OUTPUT2RETURN => 1
       	                               });
	 $index=15 if (! $attr->{REGISTRATION});
 }

$conf{PASSWD_LENGTH}=8 if (! $conf{PASSWD_LENGTH});

if ($FORM{newpassword} eq '') {

 }
elsif (length($FORM{newpassword}) < $conf{PASSWD_LENGTH}) {
  $html->message('err', $_ERROR,  "$ERR_SHORT_PASSWD $conf{PASSWD_LENGTH}");
 }
elsif ($FORM{newpassword} eq $FORM{confirm}) {
  $FORM{PASSWORD} = $FORM{newpassword};
  }
elsif($FORM{newpassword} ne $FORM{confirm}) {
  $html->message('err', $_ERROR, "$ERR_WRONG_CONFIRM");
}

$password_form->{PW_CHARS}  = $conf{PASSWD_SYMBOLS} || "abcdefhjmnpqrstuvwxyz23456789ABCDEFGHJKLMNPQRSTUVWYXZ";
$password_form->{PW_LENGTH} = $conf{PASSWD_LENGTH} || 6;
$password_form->{ACTION}    = 'change';
$password_form->{LNG_ACTION}= "$_CHANGE";

$password_form->{ACTION}    = 'change';
$password_form->{LNG_ACTION}= "$_CHANGE";

$html->tpl_show(templates('form_password'), $password_form);

 return 0;
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

  my $table2 = $html->table({ width => '100%', rowcolor => 'static' });
  my @arr = ();
  my $i=0;

  foreach my $line (sort keys %{ $attr->{FIELDS} }) {
  	my ($id, $k, $align)=split(/:/, $line);
  	push @arr, $html->form_input("FIELDS", $k, { TYPE => 'checkbox', STATE => (defined($fields_hash{$k})) ? 'checked' : undef }). " $attr->{FIELDS}{$line}";
  	$i++;
  	if ($#arr > 1) {
      $table2->addrow(@arr);
      @arr = ();
     }
   }

  if ($#arr > -1 ) {
    $table2->addrow(@arr);
   }

  $FIELDS .= $table2->show();
 }  


if ($attr->{PERIOD_FORM}) {
	my @rows = ("$_FROM: ".  $html->date_fld2('FROM_DATE', { MONTHES => \@MONTHES, FORM_NAME => 'form_reports', WEEK_DAYS => \@WEEKDAYS }) .
              " $_TO: ".   $html->date_fld2('TO_DATE', { MONTHES => \@MONTHES, FORM_NAME => 'form_reports', WEEK_DAYS => \@WEEKDAYS } ) );
	
	if (! $attr->{NO_GROUP}) {
	  push @rows, "$_GROUP:",  sel_groups(),
                "$_TYPE:",   $html->form_select('TYPE', 
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
	                         rowcolor => 'odd',
                           rows     => [[@rows, 
 	                                        ($attr->{XML}) ? 
 	                                          $html->form_input('NO_MENU', 1, { TYPE => 'hidden' }).
 	                                          $html->form_input('xml', 1, { TYPE => 'checkbox' })."XML" : '',

                                          $html->form_input('show', $_SHOW, { TYPE => 'submit' }) ]
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
     	  $EX_PARAMS .= ' '. $html->button($v, "index=$index$pages_qs&EX_PARAMS=$k", { BUTTON => 1});
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

  $table = $html->table({ width      => '100%',
                          rowcolor   => 'odd',
                          cols_align => ['right', 'left'],
                          rows       => [ @rows ]
                         });
  print $table->show();
}

}

#**********************************************************
#
#**********************************************************
sub report_fees_month {
	$FORM{allmonthes}=1;
  report_fees();
}

#**********************************************************
#
#**********************************************************
sub report_fees {

  if (! $permissions{2} || ! $permissions{2}{0}) {
  	$html->message('err', $_ERROR, "$ERR_ACCESS_DENY");  	
  	return 0;
  }

  %FEES_METHODS = %{ get_fees_types() };
  
  while(my($k, $v)=each %FEES_METHODS ) {
  	$METHODS_HASH{"$k:$k"}="$v";
   }

  reports({ DATE        => $FORM{DATE}, 
  	        REPORT      => '',
            PERIOD_FORM => 1,
  	        FIELDS      => { %METHODS_HASH },
  	        EXT_TYPE    => { METHOD => $_TYPE,
  	        	               ADMINS => $_ADMINS,
  	        	               FIO    => $_FIO,
  	        	               COMPANIES => "$_COMPANIES"
  	        	              }
         });

  if ( defined($FORM{FIELDS}) && $FORM{FIELDS} >= 0 ) {
  	$LIST_PARAMS{METHODS}=$FORM{FIELDS};
   }

  $LIST_PARAMS{PAGE_ROWS}=1000000;
  use Finance;
  my $fees = Finance->fees($db, $admin, \%conf);

  my $graph_type= 'month_stats';
  my %DATA_HASH = ();
  my %AVG       = ();
  my %CHART     = ();
  my $num       = 0;
  my @CHART_TYPE= ('area', 'line', 'column');

if (defined($FORM{DATE})) {
	$graph_type='';
  $list = $fees->list( { %LIST_PARAMS } );
  $table_fees = $html->table( { width      => '100%',
                            caption    => "$_FEES",
                            border     => 1,
                            title      => ['ID', $_LOGIN, $_DATE, $_DESCRIBE, $_SUM, $_DEPOSIT, $_TYPE,  "$_BILLS", $_ADMINS, 'IP','-'],
                            cols_align => ['right', 'left', 'right', 'right', 'left', 'left', 'right', 'right', 'left', 'center:noprint'],
                            qs         => $pages_qs,
                            pages      => $fees->{TOTAL},
                            ID         => 'REPORTS_FEES',
                            EXPORT     => $_EXPORT .' XML:&xml=1',
                        } );


  $pages_qs .= "&subf=2" if (! $FORM{subf});
  foreach my $line (@$list) {
    $table_fees->addrow(
    $html->b($line->[0]), 
      $html->button($line->[1], "index=15&UID=".$line->[10]), 
      $line->[2], 
      $line->[3]. ( ($line->[11] ) ? $html->br(). $html->b($line->[11]) : '' ), 
      $line->[4], 
      "$line->[5]",
      $FEES_METHODS{$line->[6]}, 
      ($BILL_ACCOUNTS{$line->[7]}) ? $BILL_ACCOUNTS{$line->[7]} : "$line->[7]",
      "$line->[8]", 
      "$line->[9]",
     );
  }
 }   
else{ 
  $type=($FORM{TYPE}) ? $FORM{TYPE} : 'DATE';
   
  #Fees###################################################
  my @TITLE = ("$_DATE", "$_USERS", "$_COUNT", $_SUM);
  if ($type eq 'METHOD') {
  	$TITLE[0]=$_METHOD;
  	@CHART_TYPE= ('pie');
   }
  elsif ($type eq 'USER') {
  	$TITLE[0]=$_USERS;
  	$type="search=1&LOGIN";
  	$index=3;
  	$graph_type='';
   }
  elsif ($type eq 'COMPANIES') {
  	$TITLE[0]=$_COMPANIES;
  	$graph_type='';
   }
  elsif ($type eq 'ADMINS')  {
    $TITLE[0]=$_ADMINS;
    $graph_type='';
   }
  elsif ($type eq 'FIO')  {
    $TITLE[0]=$_FIO;
    $graph_type='';
   }
  elsif ($FORM{ADMINS})  {
    $TITLE[0]=$_USERS;
    $graph_type='';
   } 
  elsif ($type eq 'HOURS')  {
    $TITLE[0]=$_HOURS;
   }
  elsif ($type eq 'METHOD')  {
    $TITLE[0]=$_TYPE;
   }


  $table_fees = $html->table({ width      => '100%',
	                             caption    => $_FEES, 
                               title      => \@TITLE,
                               cols_align => ['right', 'right', 'right', 'right'],
                               qs         => $pages_qs,
                               ID         => 'REPORT_FEES',
                               EXPORT     => $_EXPORT .' XML:&xml=1',
                               });

  $list = $fees->reports({ %LIST_PARAMS });
  foreach my $line (@$list) {
    my $main_column = '';
    if ($type eq 'METHOD') {
    	$main_column = $FEES_METHODS{$line->[0]};
     }
    elsif($type eq 'FIO' || $type eq 'USER' || $FORM{ADMINS}) {
      if (! $line->[0] || $line->[0] eq '') {
        $main_column = $html->button($html->color_mark("!!! UNKNOWN", $_COLORS[6]), "index=11&UID=$line->[4]");
       }
      else {
        $main_column = $html->button($line->[0], "index=11&UID=$line->[4]");
       }
     }
    elsif($line->[0] =~ /^\d{4}-\d{2}$/ ) {
    	$main_column = $html->button($line->[0], "index=$index&MONTH=$line->[0]$pages_qs");
     }
    elsif ($type eq 'COMPANIES') {
    	$main_column = $html->button($line->[0], "index=13&COMPANY_ID=$line->[5]");
     }
    else { 
      $main_column = $html->button($line->[0], "index=$index&$type=$line->[0]$pages_qs");
     }

    
    $table_fees->addrow(
    $main_column,
    $line->[1], 
    $line->[2], 
    $html->b($line->[3]) );

    if ($type eq 'METHOD') {
      $DATA_HASH{TYPE}[$num+1]  = $line->[3];
      $CHART{X_TEXT}[$num]      = $line->[0];
      $num++;
     }
    else {
      if ($line->[0] =~ /(\d+)-(\d+)-(\d+)/) {
        $num = $3;
       }
      elsif ($line->[0] =~ /(\d+)-(\d+)/) {
   	    $CHART{X_LINE}[$num]=$line->[0];
   	    $CHART{X_TEXT}[$num]=$line->[0];
   	    $num++;
       }
      elsif ($type eq 'HOURS') {
      	$graph_type='day_stats';
      	$num = $line->[0];
       }

      $DATA_HASH{USERS}[$num]  = $line->[1];      
      $DATA_HASH{TOTALS}[$num] = $line->[2];
      $DATA_HASH{SUM}[$num]    = $line->[3];
      
      $AVG{USERS}   = $line->[1] if ($AVG{USERS} < $line->[1]);
      $AVG{TOTALS}  = $line->[2] if ($AVG{TOTALS} < $line->[2]);
      $AVG{SUM}     = $line->[3] if ($AVG{SUM} < $line->[3]);
    }
   }



}

  print $table_fees->show();	
  $table = $html->table( { width      => '100%',
                           cols_align => ['right', 'right', 'right', 'right', 'right', 'right'],
                           rows       => [ [ 
                              "$_USERS: ". $html->b($fees->{USERS}), 
                              "$_TOTAL: ". $html->b($fees->{TOTAL}), 
                              "$_SUM: ". $html->b($fees->{SUM}) ] ],
                           rowcolor   => 'even'
                          });
  print $table->show();
  
  if ($graph_type ne '') {
    print $html->make_charts({  
	        PERIOD     => $graph_type,
	        DATA       => \%DATA_HASH,
	        AVG        => \%AVG,
	        TYPE       => \@CHART_TYPE,
	        TRANSITION => 1,
          OUTPUT2RETURN => 1,
          %CHART 
       });
   }

}

#**********************************************************
#
#**********************************************************
sub report_payments_month {
	$FORM{allmonthes}=1;
  report_payments();
}


#**********************************************************
#
#**********************************************************
sub report_payments {
  if (! $permissions{1} || ! $permissions{1}{0}) {
  	$html->message('err', $_ERROR, "$ERR_ACCESS_DENY");  	
  	return 0;
  }

  my %METHODS_HASH = ();
  push @PAYMENT_METHODS, @EX_PAYMENT_METHODS if (@EX_PAYMENT_METHODS);

  for(my $i=0; $i<=$#PAYMENT_METHODS; $i++) {
	  $METHODS_HASH{"$i:$i"}="$PAYMENT_METHODS[$i]";
	  $PAYMENTS_METHODS{$i}=$PAYMENT_METHODS[$i];
   }

  my %PAYSYS_PAYMENT_METHODS = %{ cfg2hash($conf{PAYSYS_PAYMENTS_METHODS}) };
  while(my($k, $v) = each %PAYSYS_PAYMENT_METHODS ) {
	  $PAYMENTS_METHODS{$k}=$v;
   }


  while(my($k, $v) = each %PAYSYS_PAYMENT_METHODS ) {
	  $METHODS_HASH{"$k:$k"}=$v;
   }


  reports({ DATE        => $FORM{DATE}, 
  	        REPORT      => '',
  	        PERIOD_FORM => 1,
  	        FIELDS      => { %METHODS_HASH },
  	        EXT_TYPE    => { PAYMENT_METHOD => $_PAYMENT_METHOD,
  	        	               ADMINS => $_ADMINS,
  	        	               FIO    => $_FIO }
         });
  
  if (defined($FORM{FIELDS}) && $FORM{FIELDS} >= 0) {
  	$LIST_PARAMS{METHODS}=$FORM{FIELDS};
   }

  $LIST_PARAMS{PAGE_ROWS}=1000000;
  use Finance;
  
  my $payments = Finance->payments($db, $admin, \%conf);
 
  my $graph_type= 'month_stats';
  my %DATA_HASH = ();
  my %AVG       = ();
  my %CHART     = ();
  my @CHART_TYPE= ('area', 'line', 'column');
  my $num       = 0;

 
if ($FORM{DATE}) {
	$graph_type = '';

  $list = $payments->list( { %LIST_PARAMS } );
  $table = $html->table( { width      => '100%',
                           caption    => "$_PAYMENTS",
                              title    => ['ID', $_LOGIN, $_DATE, $_DESCRIBE, $_SUM, $_DEPOSIT, 
                                   $_PAYMENT_METHOD, 'EXT ID', "$_BILL", $_ADMINS, 'IP'],
                           cols_align => ['right', 'left', 'right', 'right', 'left', 'left', 'right', 'right', 'left', 'left', 'center:noprint'],
                           qs         => $pages_qs,
                           pages      => $payments->{TOTAL},
                           ID         => 'REPORTS_PAYMENTS',
                           EXPORT     => ' XML:&xml=1',
                        } );

  my $pages_qs .= "&subf=2" if (! $FORM{subf});
  foreach my $line (@$list) {
    $table->addrow($html->b($line->[0]), 
    $html->button($line->[1], "index=15&UID=$line->[11]"), 
    $line->[2], 
    $line->[3], 
    $line->[4] . ( ($line->[12] ) ? ' ('. $html->b($line->[12]) .') ' : '' ), 
    "$line->[5]", 
    $PAYMENTS_METHODS{$line->[6]}, 
    "$line->[7]", 
    ($conf{EXT_BILL_ACCOUNT} && $attr->{USER_INFO}) ? $BILL_ACCOUNTS{$line->[8]} : "$line->[8]",
    "$line->[9]", 
    "$line->[10]", 
    );
  }
 }   
else { 
  if ($FORM{TYPE}) {
    $type = $FORM{TYPE};
    $pages_qs .= "&TYPE=$type";
   }
  else {
  	$type = 'DATE';
   }

  my @CAPTION = ("$_DATE", "$_USERS", "$_COUNT", $_SUM);
  if ($type eq 'PAYMENT_METHOD') {
  	$CAPTION[0]=$_PAYMENT_METHOD;
  	$graph_type='pie';
  	@CHART_TYPE=('pie');
   }
  elsif ($type eq 'USER') {
  	$CAPTION[0]=$_USERS;
  	$type="search=1&LOGIN";
  	$LIST_PARAMS{METHODS}=$FORM{METHODS};
  	$graph_type='';
   }
  elsif ($type eq 'FIO') {
  	$CAPTION[0]=$_FIO;
  	$graph_type='';
   }
  elsif ($FORM{ADMINS})  {
    $CAPTION[0]=$_USERS;
    $LIST_PARAMS{ADMINS}=$FORM{ADMINS};
    $graph_type='';
   }
  elsif ($type eq 'ADMINS')  {
    $CAPTION[0]=$_ADMINS;
    $graph_type='';
   }
  elsif ($type eq 'HOURS')  {
    $CAPTION[0]=$_HOURS;
   }

  $table = $html->table({ width      => '100%',
	                        caption    => $_PAYMENTS, 
                          title      => \@CAPTION,
                          cols_align => ['right', 'right', 'right', 'right'],
                          qs         => $pages_qs,
                          ID         => 'REPORT_PAYMENTS',
                          EXPORT     => ' XML:&xml=1',
                        });

  $list = $payments->reports({ %LIST_PARAMS });
  $index = 2 if ($type =~ /search/);
  foreach my $line (@$list) {
    my $main_column = '';

    if ($type eq 'PAYMENT_METHOD') {
    	$pages_qs =~ s/TYPE=PAYMENT_METHOD//;
    	$pages_qs =~ s/FIELDS=[0-9,\ ]+&//;
    	$main_column = $html->button($PAYMENTS_METHODS{$line->[0]},"index=$index&TYPE=USER&METHODS=$line->[0]$pages_qs&FIELDS=$line->[0]");
     }
    elsif($type eq 'FIO' || $type eq 'USER' || $FORM{ADMINS}) {
      if (! $line->[0] || $line->[0] eq '') {
        $main_column = $html->button($html->color_mark("$_UNKNOWN UID:$line->[4]", $_COLORS[6]), "index=11&UID=$line->[4]");
       }
      else {
        $main_column = $html->button($line->[0], "index=11&UID=$line->[4]");
       }
     }
    #elsif ($FORM{TYPE} && $FORM{TYPE} eq 'ADMINS')  {
    #  $CAPTION[0]=$_ADMINS;
    #  $graph_type='';
    # }
    elsif($line->[0] =~ /^\d{4}-\d{2}$/ ) {
    	$main_column = $html->button($line->[0], "index=$index&MONTH=$line->[0]$pages_qs");
     }
    else { 
      $main_column = $html->button($line->[0], "index=$index&$type=$line->[0]$pages_qs");
     }
  	
    $table->addrow(
      $main_column, 
      $line->[1], 
      $line->[2], 
      $html->b($line->[3]) );

    if ($type eq 'ADMINS') { 
    	
     }
    elsif ($type eq 'PAYMENT_METHOD') {
      $DATA_HASH{TYPE}[$num+1] = $line->[3];
      $CHART{X_TEXT}[$num]     = $PAYMENT_METHODS[$line->[0]];
      $num++;
     }
    else {
      if ($line->[0] =~ /(\d+)-(\d+)-(\d+)/) {
        $num = $3;
       }
      elsif ($line->[0] =~ /(\d+)-(\d+)/) {
   	    $CHART{X_LINE}[$num]=$line->[0];
   	    $CHART{X_TEXT}[$num]=$line->[0];
   	    $num++;
       }
      elsif ($type eq 'HOURS') {
      	$graph_type='day_stats';
      	$num = $line->[0];
       }

      $DATA_HASH{USERS}[$num]  = $line->[1];      
      $DATA_HASH{TOTALS}[$num] = $line->[2];
      $DATA_HASH{SUM}[$num]    = $line->[3];
      
      $AVG{USERS}   = $line->[1] if ($AVG{USERS} < $line->[1]);
      $AVG{TOTALS}  = $line->[2] if ($AVG{TOTALS} < $line->[2]);
      $AVG{SUM}     = $line->[3] if ($AVG{SUM} < $line->[3]);
     }
   }

}

  print $table->show();

  $table = $html->table( { width      => '100%',
                           cols_align => ['right', 'right', 'right', 'right'],
                           rows       => [ [ 
                           "$_USERS: ". $html->b($payments->{USERS}),
                           "$_TOTAL: ". $html->b($payments->{TOTAL}), 
                           "$_SUM: ". $html->b($payments->{SUM}) ] ],
                           rowcolor   => 'even'
                       } );

  print $table->show();

  if ($graph_type ne '') {
    print $html->make_charts({  
	        PERIOD     => $graph_type,
	        DATA       => \%DATA_HASH,
	        AVG        => \%AVG,
	        TYPE       => \@CHART_TYPE,
	        TRANSITION => 1,
          OUTPUT2RETURN => 1,
          %CHART 
       });
   }
}

#**********************************************************
# Main functions
#**********************************************************
sub fl {

	# ID:PARENT:NAME:FUNCTION:SHOW SUBMENU:module:
my @m = (
 "0:0::null:::",
 "1:0:$_CUSTOMERS:form_users:::",
 "11:1:$_LOGINS:form_users:::",
 "13:1:$_COMPANY:form_companies:::",
 "16:13:$_ADMIN:form_companie_admins:COMPANY_ID::",

 "15:11:$_INFO:form_users:UID::",
 "22:15:$_LOG:form_changes:UID::",
 "17:15:$_PASSWD:form_passwd:UID::",
 "18:15:$_NAS:form_nas_allow:UID::",
 "19:15:$_BILL:form_bills:UID::",
 "20:15:$_SERVICES:null:UID::",
 "21:15:$_COMPANY:user_company:UID::",
 "101:15:$_PAYMENTS:form_payments:UID::",
 "102:15:$_FEES:form_fees:UID::",

 "12:15:$_GROUP:user_group:UID::",
 "27:1:$_GROUPS:form_groups:::",

 "30:15:$_USER_INFO:user_pi:UID::",
 "31:15:Send e-mail:form_sendmail:UID::",

 "2:0:$_PAYMENTS:form_payments:::",
 "3:0:$_FEES:form_fees:::",
 "4:0:$_REPORTS:null:::",
 "41:4:$_PAYMENTS:report_payments:::",
 "42:41:$_MONTH:report_payments_month:::",
 "44:4:$_FEES:report_fees:::",
 "45:44:$_MONTH:report_fees_month:::",

 "5:0:$_SYSTEM:null:::",
  
 "61:5:$_NAS:form_nas:::",
 "62:61:IP POOLs:form_ip_pools:::",
 "63:61:$_NAS_STATISTIC:form_nas_stats:::",
 "64:61:$_GROUPS:form_nas_groups:::",

 "65:5:$_EXCHANGE_RATE:form_exchange_rate:::",
 
 "66:5:$_LOG:form_changes:::",

# "68:5:$_LOCATIONS:form_districts:::",
# "69:68:$_STREETS:form_streets::",

 "75:5:$_HOLIDAYS:form_holidays:::",
 
 "85:5:$_SHEDULE:form_shedule:::",
 "86:5:$_BRUTE_ATACK:form_bruteforce:::",
 "90:5:$_MISC:null:::",
 "91:90:$_TEMPLATES:form_templates:::",
 "92:90:$_DICTIONARY:form_dictionary:::",
 "93:90:Config:form_config:::",
 "94:90:WEB server:form_webserver_info:::",
 "95:90:$_SQL_BACKUP:form_sql_backup:::",
 "96:90:$_INFO_FIELDS:form_info_fields:::",
 "97:96:$_LIST:form_info_lists:::",
 "98:90:$_TYPE $_FEES:form_fees_types:::",
 "6:0:$_MONITORING:null:::",
  
 "7:0:$_SEARCH:form_search:::",

 "8:0:$_OTHER:null:::",
 "9:0:$_PROFILE:admin_profile:::",
 #"53:9:$_PROFILE:admin_profile:::",
 "99:9:$_FUNCTIONS_LIST:flist:::",
 );


if ($conf{NON_PRIVILEGES_LOCATION_OPERATION}) {
 push @m, "68:8:$_LOCATIONS:form_districts:::",
 "69:68:$_STREETS:form_streets::";
 }
else {
 push @m, "68:5:$_LOCATIONS:form_districts:::",
 "69:68:$_STREETS:form_streets::";
}
	


if ($permissions{4} && $permissions{4}{4}) {
  push @m, "50:5:$_ADMINS:form_admins:::";
  push @m, "51:50:$_LOG:form_changes:AID::";
  push @m, "52:50:$_PERMISSION:form_admin_permissions:AID::";
  push @m, "54:50:$_PASSWD:form_passwd:AID::";
  push @m, "55:50:$_FEES:form_fees:AID::";
  push @m, "56:50:$_PAYMENTS:form_payments:AID::";
  push @m, "57:50:$_CHANGE:form_admins:AID::";
  push @m, "58:50:$_GROUPS:form_admins_groups:AID::" if ($admin->{GID} == 0);
  #push @m, "59:50:$_ALLOW IP:form_admins_ips:AID::";
}

if ($permissions{4} && $permissions{4}{5}) {
  push @m, "67:66:$_SYSTEM $_LOG:form_system_changes:::";
}

if ($permissions{0} && $permissions{0}{1}) {
  push @m, "24:11:$_ADD:form_wizard:::" ;
  push @m, "14:13:$_ADD:add_company:::";
  push @m, "28:27:$_ADD:add_groups:::";
}



foreach my $line (@m) {
	my ($ID, $PARENT, $NAME, $FUNTION_NAME, $ARGS, $OP)=split(/:/, $line);
  $menu_items{$ID}{$PARENT}= $NAME;
  $menu_names{$ID}         = $NAME;
  $functions{$ID}          = $FUNTION_NAME if ($FUNTION_NAME  ne '');
  $menu_args{$ID}          = $ARGS if ($ARGS ne '');
  $maxnumber               = $ID if ($maxnumber < $ID);
}
	
}


#**********************************************************
# mk_navigator()
#**********************************************************
sub mk_navigator {

my ($menu_navigator, $menu_text) = $html->menu(\%menu_items, 
                                               \%menu_args, 
                                               \%permissions,
                                              { 
     	                                          FUNCTION_LIST   => \%functions
     	                                         }
                                               );
  
  if ($html->{ERROR}) {
  	$html->message('err',  $_ERROR, "$html->{ERROR}");
  	exit;
  }

return  $menu_text, "/".$menu_navigator;
}

#**********************************************************
# Functions list
#**********************************************************
sub flist {

my  %new_hash = ();
while((my($findex, $hash)=each(%menu_items))) {
   while(my($parent, $val)=each %$hash) {
     $new_hash{$parent}{$findex}=$val;
    }
}

my $h = $new_hash{0};
my @last_array = ();

my @menu_sorted = sort {
   $b <=> $a
 } keys %$h;

my %qm = ();
if (defined($admin->{WEB_OPTIONS}{qm})) {
	my @a = split(/,/, $admin->{WEB_OPTIONS}{qm});
	foreach my $line (@a) {
     my($id, $custom_name)=split(/:/, $line, 2);
     $qm{$id} = ($custom_name ne '') ? $custom_name : '';
	 }
}

my $table = $html->table({ width      => '100%',
                           border     => 1,
                           cols_align => ['right', 'left', 'right', 'right', 'left', 'left', 'right'],
                           ID         => 'PROFILE_FUNCTION_LIST'                           
                         });

for(my $parent=0; $parent<=$#menu_sorted; $parent++) { 
  my $val    = $h->{$parent};
  my $level  = 0;
  my $prefix = '';
  $table->{rowcolor}='row_active';

  next if (! defined($permissions{($parent-1)}));  
  $table->addrow("$level:", "$parent >> ". $html->button($html->b($val), "index=$parent"). "<<", '') if ($parent != 0);

  if (defined($new_hash{$parent})) {
    $table->{rowcolor}=undef;
    $level++;
    $prefix .= "&nbsp;&nbsp;&nbsp;";
    label:
      while(my($k, $val)=each %{ $new_hash{$parent} }) {
        my $checked = undef;
        if (defined($qm{$k})) { 
        	$checked = 1;  
        	$val = $html->b($val);
         }
        
        $table->addrow("$k ". $html->form_input('qm_item', "$k", { TYPE          => 'checkbox',
       	                                                           OUTPUT2RETURN => 1,
       	                                                           STATE         => $checked  
       	                                        }),  
                     "$prefix ". $html->button($val, "index=$k"), 
                     $html->form_input("qm_name_$k", $qm{$k}, { OUTPUT2RETURN => 1 }) );

        if (defined($new_hash{$k})) {
      	   $mi = $new_hash{$k};
      	   $level++;
           $prefix .= "&nbsp;&nbsp;&nbsp;";
           push @last_array, $parent;
           $parent = $k;
         }
        delete($new_hash{$parent}{$k});
      }
    
    if ($#last_array > -1) {
      $parent = pop @last_array;	
      $level--;
      
      $prefix = substr($prefix, 0, $level * 6 * 3);
      goto label;
     }
    delete($new_hash{0}{$parent});
   }
}

print $html->form_main({ CONTENT => $table->show({ OUTPUT2RETURN => 1 }),
	                       HIDDEN  => { index        => "$index",
	                       	            AWEB_OPTIONS => 1,
                                     },
	                       SUBMIT  => { quick_set => "$_SET"
	                       	           } });
}

#**********************************************************
# form_payments
#**********************************************************
sub form_payments () {
 my ($attr) = @_; 

 use Finance;
 my $payments = Finance->payments($db, $admin, \%conf);
 
 return 0 if (! $permissions{1});

 %PAYMENTS_METHODS = ();
 my %BILL_ACCOUNTS = ();

 if ($FORM{print}) {
   load_module('Docs', $html);
   if ($FORM{ACCOUNT_ID}) {
   	 docs_account({ %FORM  });
    }
   else {
     docs_invoice({ %FORM  });
    }
   exit;
  }


if ($attr->{USER_INFO}) {
  my $user = $attr->{USER_INFO};
  $payments->{UID} = $user->{UID};
  
  if ($conf{EXT_BILL_ACCOUNT}) {
    $BILL_ACCOUNTS{$user->{BILL_ID}}     = "$_PRIMARY : $user->{BILL_ID}" if ($user->{BILL_ID}); 
    $BILL_ACCOUNTS{$user->{EXT_BILL_ID}} = "$_EXTRA : $user->{EXT_BILL_ID}" if ($user->{EXT_BILL_ID}); 
   }

  if (in_array('Docs', \@MODULES) ) {
    $FORM{QUICK}=1;
  	load_module('Docs', $html);
   }

  if(! $attr->{REGISTRATION}) {
    if($user->{BILL_ID} < 1) {
      form_bills({ USER_INFO => $user });
      return 0;
     }
   }

  if ($FORM{DATE}) {
    ($DATE, $TIME)=split(/ /, $FORM{DATE});
   }


  if (defined($FORM{OP_SID1}) and $FORM{OP_SID} eq $COOKIES{OP_SID}) {
 	  $html->message('err', $_ERROR, "$_EXIST");
   }
  elsif ($FORM{add} && $FORM{SUM}) {
  	$FORM{SUM} =~ s/,/\./g;
  	
  	if ($FORM{SUM}!~/[0-9\.]+/) {
  	  $html->message('err', $_ERROR, "$ERR_WRONG_SUM");	
      return 1 if ($attr->{REGISTRATION});
  	 }
  	else {
      if( $FORM{ACCOUNT_ID} && $FORM{ACCOUNT_ID} eq 'create') {
    	  $LIST_PARAMS{UID}= $FORM{UID};
    	  $FORM{create}    = 1;
    	  $FORM{CUSTOMER}  = '-';
    	  $FORM{ORDER}     = $FORM{DESCRIBE};
    	  docs_account();    	
       }
      elsif($FORM{ACCOUNT_ID}) {
    	  $Docs->account_info($FORM{ACCOUNT_ID});
        if ($Docs->{TOTAL} == 0) {
      	  $FORM{ACCOUNT_SUM}=0;
         }
        else {
      	  $FORM{ACCOUNT_SUM} = $Docs->{TOTAL_SUM};
         }
       }

   	  if ($FORM{ACCOUNT_SUM} && $FORM{ACCOUNT_SUM} != $FORM{SUM})  {
        $html->message('err', "$_PAYMENTS: $ERR_WRONG_SUM", "$_ACCOUNT $_SUM: $Docs->{TOTAL_SUM} / $_PAYMENTS $_SUM: $FORM{SUM}");
       }
      else {
        my $er = $payments->exchange_info($FORM{ER});
        $FORM{ER} = $er->{ER_RATE};
        $payments->add($user, { %FORM } );  
        if ($payments->{errno}) {
      	  if ($payments->{errno}==12) {
      		  $html->message('err', $_ERROR, "$ERR_WRONG_SUM");	
      	   }
      	  else {
            $html->message('err', $_ERROR, "[$payments->{errno}] $err_strs{$payments->{errno}}");	
           }
          return 1 if ($attr->{REGISTRATION});
         }
        else {
          $html->message('info', $_PAYMENTS, "$_ADDED $_SUM: $FORM{SUM} $er->{ER_SHORT_NAME}");
        
          if ($conf{external_payments}) {
            if (! _external($conf{external_payments}, { %FORM }) ) {
     	        return 0;
             }
           }
          #Make cross modules Functions
          $attr->{USER_INFO}->{DEPOSIT}+=$FORM{SUM};
          $FORM{PAYMENTS_ID} = $payments->{PAYMENT_ID};
          cross_modules_call('_payments_maked', { %$attr, PAYMENT_ID => $payments->{PAYMENT_ID} });
        }
       }
     }
   }
  elsif($FORM{del} && $FORM{is_js_confirmed}) {
  	if (! defined($permissions{1}{2})) {
      $html->message('err', $_ERROR, "[13] $err_strs{13}");
      return 0;		
	   }

    $payments->del($user, $FORM{del});
    if ($payments->{errno}) {
      $html->message('err', $_ERROR, "[$payments->{errno}] $err_strs{$payments->{errno}}");	
     }
    else {
      $html->message('info', $_PAYMENTS, "$_DELETED ID: $FORM{del}");
     }
   }



return 0 if ($attr->{REGISTRATION} && $FORM{add});
#exchange rate sel
$payments->{SEL_ER}=$html->form_select('ER', 
                                { 
 	                                SELECTED          => undef,
 	                                SEL_MULTI_ARRAY   => [ ['', '', '', '', ''], @{ $payments->exchange_list() } ],
 	                                MULTI_ARRAY_KEY   => 4,
 	                                MULTI_ARRAY_VALUE => '1,2',
 	                                NO_ID             => 1
 	                               });


push @PAYMENT_METHODS, @EX_PAYMENT_METHODS if (@EX_PAYMENT_METHODS);

for(my $i=0; $i<=$#PAYMENT_METHODS; $i++) {
	$PAYMENTS_METHODS{"$i"}="$PAYMENT_METHODS[$i]";
 }

my %PAYSYS_PAYMENT_METHODS = %{ cfg2hash($conf{PAYSYS_PAYMENTS_METHODS}) };

while(my($k, $v) = each %PAYSYS_PAYMENT_METHODS ) {
	$PAYMENTS_METHODS{$k}=$v;
}

$payments->{SEL_METHOD} = $html->form_select('METHOD', 
                                { SELECTED     => (defined($FORM{METHOD}) && $FORM{METHOD} ne '') ? $FORM{METHOD} : '',
 	                                SEL_HASH     => \%PAYMENTS_METHODS,
 	                                NO_ID        => 1,
 	                                SORT_KEY     => 1
 	                               });

if ($permissions{1} && $permissions{1}{1}) {
   $payments->{OP_SID} = mk_unique_value(16);
   
   if ($conf{EXT_BILL_ACCOUNT}) {
     $payments->{EXT_DATA} = "<tr><td colspan=2>$_BILL:</td><td>". $html->form_select('BILL_ID', 
                                { SELECTED     => $FORM{BILL_ID} || $attr->{USER_INFO}->{BILL_ID},
 	                                SEL_HASH     => \%BILL_ACCOUNTS,
 	                                NO_ID        => 1
 	                               }).
 	                             "</td></tr>\n";
    }
   
  if ($permissions{1}{4}) {
    my $date_field = $html->date_fld2('DATE', { DATE=>$DATE, TIME => $TIME, MONTHES => \@MONTHES, FORM_NAME => 'user', WEEK_DAYS => \@WEEKDAYS });
    $payments->{DATE} = "<tr><td colspan=2>$_DATE:</td><td>$date_field</td></tr>\n";
   }

  if (in_array('Docs', \@MODULES) ) {
  	my $ACCOUNTS_SEL = $html->form_select("ACCOUNT_ID", 
                                { SELECTED          => $FORM{ACCOUNT_ID},
 	                                SEL_MULTI_ARRAY   => $Docs->accounts_list({ UID => $user->{UID}, PAYMENT_ID => 0, PAGE_ROWS => 100, SORT => 2, DESC => 'DESC' }), 
 	                                MULTI_ARRAY_KEY   => 10,
 	                                MULTI_ARRAY_VALUE => '0,1,3',
 	                                MULTI_ARRAY_VALUE_PREFIX => "$_NUM: ,$_DATE: ,$_SUM:",
 	                                SEL_OPTIONS       => { 0 => '', create => $_CREATE },
 	                                NO_ID             => 1,
 	                               });

    $payments->{DOCS_ACCOUNT_ELEMENT}="<tr><th colspan=3 class='form_title'>$_DOCS</th></tr>\n".
    "<tr><td colspan=2>$_ACCOUNT:</td><td>$ACCOUNTS_SEL</td></tr>";
   }


   if (in_array('Docs', \@MODULES) ) {
     $payments->{DOCS_ACCOUNT_ELEMENT} .= "<tr><td colspan=2>$_INVOICE:</td><td>". $html->form_input('CREATE_INVOICE', '1', { TYPE => 'checkbox', STATE => 1 }). "</td></tr>\n";
    }   
   
   
   if ($attr->{ACTION}) {
	   $payments->{ACTION}    = $attr->{ACTION};
	   $payments->{LNG_ACTION}= $attr->{LNG_ACTION};
	  }
	 else {
	   $payments->{ACTION}    = 'add';
	   $payments->{LNG_ACTION}= $_ADD;
	  }

   
   $html->tpl_show(templates('form_payments'), { %FORM, %$attr, %$payments   });
   #return 0 if ($attr->{REGISTRATION});
 }
}
elsif($FORM{AID} && ! defined($LIST_PARAMS{AID})) {
	$FORM{subf}=$index;
	form_admins();
	return 0;
 }
elsif($FORM{UID}) {
	$index = get_function_index('form_payments');
	form_users();
	return 0;
 }	
elsif($index != 7) {
  $FORM{type} = $FORM{subf} if ($FORM{subf});
	form_search({ HIDDEN_FIELDS => { subf => ($FORM{subf}) ? $FORM{subf} : undef,
		                               COMPANY_ID => $FORM{COMPANY_ID}  },
		            ID            => 'SEARCH_PAYMENTS' 
		           });
}

return 0 if (! $permissions{1}{0});

if (! defined($FORM{sort})) {
  $LIST_PARAMS{SORT}=1;
  $LIST_PARAMS{DESC}=DESC;
 }

$LIST_PARAMS{ID}=$FORM{ID} if ($FORM{ID});

my $list = $payments->list( { %LIST_PARAMS } );
my $table = $html->table( { width      => '100%',
                            caption    => "$_PAYMENTS",
                            border     => 1,
                            title      => ['ID', $_LOGIN, $_DATE, $_DESCRIBE,  $_SUM, $_DEPOSIT, 
                                   $_PAYMENT_METHOD, 'EXT ID', "$_BILL", $_ADMINS, 'IP', '-'],
                            cols_align => ['right', 'left', 'right', 'right', 'left', 'left', 'right', 'right', 'left', 'left', 'center:noprint'],
                            qs         => $pages_qs,
                            pages      => $payments->{TOTAL},
                            EXPORT     => ' XML:&xml=1',
                            ID         => 'PAYMENTS'
                           } );


my $pages_qs .= "&subf=2" if (! $FORM{subf});
foreach my $line (@$list) {
  my $delete = ($permissions{1}{2}) ?  $html->button($_DEL, "index=2&del=$line->[0]&UID=". $line->[11] ."$pages_qs", { MESSAGE => "$_DEL [$line->[0]] ?", CLASS => 'del' }) : ''; 

  $table->addrow($html->b($line->[0]), 
  $html->button($line->[1], "index=15&UID=$line->[11]"), 
  $line->[2], 
  $line->[3].( ($line->[12] ) ? $html->br(). $html->b($line->[12]) : '' ), 
  $line->[4], 
  "$line->[5]", 
  $PAYMENTS_METHODS{$line->[6]}, 
  "$line->[7]", 
  ($conf{EXT_BILL_ACCOUNT} && $attr->{USER_INFO}) ? $BILL_ACCOUNTS{$line->[8]} : "$line->[8]",
  "$line->[9]", 
  "$line->[10]",   
  $delete);
}

print $table->show();

if (! $admin->{MAX_ROWS}) {
  $table = $html->table({ width      => '100%',
                        cols_align => ['right', 'right', 'right', 'right', 'right', 'right' ],
                        rows       => [ [ "$_TOTAL:", $html->b($payments->{TOTAL}), 
                                          "$_USERS:", $html->b($payments->{TOTAL_USERS}), 
                                          "$_SUM",    $html->b($payments->{SUM}) ] ],
                        rowcolor   => 'even'
                      });
  print $table->show();
 }

}

#**********************************************************
# form_exchange_rate
#**********************************************************
sub form_exchange_rate {
 use Finance;
 my $finance = Finance->new($db, $admin);

 $finance->{ACTION}='add';
 $finance->{LNG_ACTION}="$_ADD";

if ($FORM{add}) {
	$finance->exchange_add({ %FORM });
  if ($finance->{errno}) {
    $html->message('err', $_ERROR, "[$finance->{errno}] $err_strs{$finance->{errno}}");	
   }
  else {
    $html->message('info', $_EXCHANGE_RATE, "$_ADDED");
   }
}
elsif($FORM{change}) {
	$finance->exchange_change("$FORM{chg}", { %FORM });
  if ($finance->{errno}) {
    $html->message('err', $_ERROR, "[$finance->{errno}] $err_strs{$finance->{errno}}");	
   }
  else {
    $html->message('info', $_EXCHANGE_RATE, "$_CHANGED");
   }
}
elsif($FORM{chg}) {
	$finance->exchange_info("$FORM{chg}");

  if ($finance->{errno}) {
    $html->message('err', $_ERROR, "[$finance->{errno}] $err_strs{$finance->{errno}}");	
   }
  else {
    $finance->{ACTION}='change';
    $finance->{LNG_ACTION}="$_CHANGE";
    $html->message('info', $_EXCHANGE_RATE, "$_CHANGING");
   }
}
elsif($FORM{del} && $FORM{is_js_confirmed}) {
	$finance->exchange_del("$FORM{del}");
  if ($finance->{errno}) {
    $html->message('err', $_ERROR, "[$finance->{errno}] $err_strs{$finance->{errno}}");	
   }
  else {
    $html->message('info', $_EXCHANGE_RATE, "$_DELETED");
   }
}
	

$html->tpl_show(templates('form_er'), $finance);
my $table = $html->table({ width      => '640',
                           title      => ["$_MONEY", "$_SHORT_NAME", "$_EXCHANGE_RATE (1 unit =)", "$_CHANGED", '-', '-'],
                           cols_align => ['left', 'left', 'right', 'center', 'center'],
                          });

my $list = $finance->exchange_list( {%LIST_PARAMS} );
foreach my $line (@$list) {
  $table->addrow($line->[0], 
     $line->[1], 
     $line->[2], 
     $line->[3], 
     $html->button($_CHANGE, "index=65&chg=$line->[4]", { CLASS => 'change' }), 
     $html->button($_DEL, "index=65&del=$line->[4]", { MESSAGE => "$_DEL [$line->[0]]?", CLASS => 'del' } ));
}

print $table->show();
}


#**********************************************************
# form_fees_types
#**********************************************************
sub form_fees_types {
 my ($attr) = @_;

 use Finance;
 my $fees = Finance->fees($db, $admin, \%conf);

  
 $fees->{ACTION}     = 'add';
 $fees->{LNG_ACTION} = $_ADD;

if ($FORM{add}) {
  $fees->fees_type_add( { %FORM });
  if (! $fees->{errno}) {
      $html->message('info', $_ADDED, "$_ADDED");
    }
 }
elsif($FORM{change}){
  $fees->fees_type_change({ %FORM });
  if (! $fees->{errno}) {
    $html->message('info', $_CHANGED, "$_CHANGED $nas->{GID}");
   }
 }
elsif($FORM{chg}){
  $fees->fees_type_info({ ID => $FORM{chg} });
  $fees->{ACTION}    ='change';
  $fees->{LNG_ACTION}=$_CHANGE;
 }
elsif(defined($FORM{del}) && $FORM{is_js_confirmed}){
  $fees->fees_type_del( $FORM{del} );
  if (! $fees->{errno}) {
    $html->message('info', $_DELETED, "$_DELETED $FORM{del}");
   }
}


if ($fees->{errno}) {
   $html->message('err', $_ERROR, "[$fees->{errno}] $err_strs{$fees->{errno}}");	
  }

$html->tpl_show(templates('form_fees_types'), $fees);

my $list =  $fees->fees_type_list({ %LIST_PARAMS });
my $table = $html->table( { width      => '100%',
                            caption    => "$_FEES $_TYPES",
                            border     => 1,
                            title      => ['#', $_NAME, $_COMMENTS, $_SUM, '-', '-'],
                            cols_align => ['right', 'left', 'left', 'center', 'center:noprint'],
                            qs         => $pages_qs,
                            pages      => $nas->{TOTAL}
                       } );

foreach my $line (@$list) {
  my $delete = $html->button($_DEL, "index=$index$pages_qs&del=$line->[0]", { MESSAGE => "$_DEL [$line->[0]]?", CLASS => 'del' }); 

  $table->addrow($line->[0], 
   ($line->[1]=~/\$/) ? eval($line->[1]) : $line->[1], 
   "$line->[2]", 
   "$line->[3]", 
   $html->button($_CHANGE, "index=$index&chg=$line->[0]", { CLASS => 'change' }),
   $delete);
}
print $table->show();
}

#**********************************************************
# get_fees_types
# 
# return $Array_ref
#**********************************************************
sub get_fees_types  {
 my ($attr) = @_;

 use Finance;
 my %FEES_METHODS = ();
 my $fees = Finance->fees($db, $admin, \%conf);
 my $list = $fees->fees_type_list({   });
 foreach my $line (@$list) {
   if ($FORM{METHOD} && $FORM{METHOD} == $line->[0]) {
   	 $FORM{SUM}=$line->[3] if ($line->[3] > 0);
 		 $FORM{DESCRIBE}=$line->[2] if ($line->[2]);
 	  }
   
 	 $FEES_METHODS{$line->[0]}=(($line->[1]=~/\$/) ? eval($line->[1]) : $line->[1]) . (($line->[3] > 0) ? (($attr->{SHORT}) ? ":$line->[3]" : " ($_SERVICE $_PRICE: $line->[3])") : '');
  }
 
 return \%FEES_METHODS;
}

#**********************************************************
# form_fees_wizard
#**********************************************************
sub form_fees_wizard  {
	my ($attr)=@_;
  my $fees = Finance->fees($db, $admin, \%conf);
 

if ($FORM{add}) {
	%FEES_METHODS = %{ get_fees_types({ SHORT => 1 }) };

	my $i=0;
	my $message = '';
	while(defined($FORM{'METHOD_'.$i}) && $FORM{'METHOD_'.$i} ne '') {
		my ($type_describe,$price)=split(/:/, $FEES_METHODS{$FORM{'METHOD_'.$i}}, 2);
		
		if (! $FORM{'SUM_'.$i} && $price > 0) {
			$FORM{'SUM_'.$i} = $price;
		 }		

    if ($FORM{'SUM_'.$i} <= 0) {
      $i++;
      next   
     }    

    $fees->take($attr->{USER_INFO}, $FORM{'SUM_'.$i}, { DESCRIBE       => $FORM{'DESCRIBE_'.$i},
    	                                     INNER_DESCRIBE => $FORM{'INNER_DESCRIBE_'.$i} } );      


    $message .= "$type_describe $_SUM: ". sprintf('%.2f', $FORM{'SUM_'.$i}) .", ". $FORM{'DESCRIBE_'.$i}."\n";
    
    $i++;
	 }
	
	if ($message ne '') {
		$html->message('info', $_FEES, "$message");
	 }
	
	return 0;
}


%FEES_METHODS = %{ get_fees_types() };
  
my $table = $html->table( { width      => '100%',
                            caption    => "$_FEES $_TYPES",
                            border     => 1,
                            title      => [ '#', $_TYPE, $_SUM, $_DESCRIBE, "$_ADMIN $_DESCRIBE" ],
                            cols_align => ['right', 'left', 'left', 'left', 'center:noprint'],
                            qs         => $pages_qs,
                            #pages      => $nas->{TOTAL},
                            ID         => 'FEES_WIZARD',
                            class      => 'form'
                            
                       } );


for (my $i=0; $i<=6; $i++) {
  my $method =  $html->form_select('METHOD_'.$i, 
                                { SELECTED     => $FORM{'METHOD_'.$i},
 	                                SEL_HASH     => { %FEES_METHODS },
 	                                NO_ID        => 1,
 	                                SORT_KEY     => 1
 	                               });

  $table->addrow(($i+1), 
   $method,
   $html->form_input('SUM_'.$i, $FORM{'SUM_'.$i}, { SIZE => 8 }),
   $html->form_input('DESCRIBE_'.$i, $FORM{'DESCRIBE_'.$i}, { SIZE => 30 }),
   $html->form_input('INNER_DESCRIBE_'.$i, $FORM{'INNER_DESCRIBE_'.$i}, { SIZE => 30 }),
   );
}


if ($attr->{ACTION}) {
  my $action = "";
  if ($attr->{ACTION}) {
	  $action = $html->br(). $html->form_input('finish', "$_REGISTRATION_COMPLETE", {  TYPE => 'submit' }).' '.
	  $html->form_input('back', "$_BACK", {  TYPE => 'submit' }).' '.
	  $html->form_input('next', "$_NEXT", {  TYPE => 'submit' });
   }
  else{
	  $action = $html->form_input('change', "$_CHANGE", {  TYPE => 'submit' });
   }

  $table->{extra}='colspan=5 align=center';
  $table->{rowcolor}='even';
  $table->addrow($action);
	print $html->form_main({ CONTENT => $table->show({ OUTPUT2RETURN => 1 }),
	                         HIDDEN  => { index    => "$index",
	                         	            step     => $FORM{step},
	                         	            UID      => "$FORM{UID}"
                                     },
	                         #SUBMIT  =>  { $atrr->{ACTION}   => $attr->{LNG_ACTION} } 
	                       });
 }
else {
  return $output;
 }
}



#**********************************************************
# form_fees
#**********************************************************
sub form_fees  {
 my ($attr) = @_;
 my $period = $FORM{period} || 0;
 
 return 0 if (! defined ($permissions{2}));


 my $fees = Finance->fees($db, $admin, \%conf);
 my %BILL_ACCOUNTS = ();
 
 %FEES_METHODS = %{ get_fees_types() };

if ($attr->{USER_INFO}) {
  my $user = $attr->{USER_INFO};

  if ($conf{EXT_BILL_ACCOUNT}) {
    $BILL_ACCOUNTS{$attr->{USER_INFO}->{BILL_ID}} = "$_PRIMARY : $attr->{USER_INFO}->{BILL_ID}" if ($attr->{USER_INFO}->{BILL_ID}); 
    $BILL_ACCOUNTS{$attr->{USER_INFO}->{EXT_BILL_ID}} = "$_EXTRA : $attr->{USER_INFO}->{EXT_BILL_ID}" if ($attr->{USER_INFO}->{EXT_BILL_ID}); 
   }

  if($user->{BILL_ID} < 1) {
    form_bills({ USER_INFO => $user });
    return 0;
  }
  
  use Shedule;
  my $shedule = Shedule->new($db, $admin, \%conf); 

  $fees->{UID} = $user->{UID};
  if ($FORM{take} && $FORM{SUM}) {
  	$FORM{SUM} =~ s/,/\./g;
    # add to shedule
    if ($FORM{ER} && $FORM{ER} ne '') {
      my $er     = $fees->exchange_info($FORM{ER});
      $FORM{ER}  = $er->{ER_RATE};
      $FORM{SUM} = $FORM{SUM} / $FORM{ER};
    }

    if ($period == 2) {
  	  use POSIX;
  	  my ($y, $m, $d)=split(/-/, $FORM{DATE});
  	  
      my $seltime = POSIX::mktime(0, 0, 0, $d, ($m-1), ($y - 1900));
      my $FEES_DATE = "$FORM{DATE}";

      if ($seltime - 86400 <= time()) {
        $fees->take($user, $FORM{SUM}, { %FORM, DATE => $FEES_DATE } );  
        if ($fees->{errno}) {
          $html->message('err', $_ERROR, "[$fees->{errno}] $err_strs{$fees->{errno}}");	
         }
        else {
        	$html->message('info', $_FEES, "$_TAKE $_SUM: $fees->{SUM} $_DATE: $FEES_DATE");
         }
       }
      else { 
        $shedule->add( { DESCRIBE => $FORM{DESCR}, 
      	               D        => $d,
      	               M        => $m,
      	               Y        => $y,
                       UID      => $user->{UID},
                       TYPE     => 'fees',
                       ACTION   => ( $conf{EXT_BILL_ACCOUNT} ) ? "$FORM{SUM}:$FORM{DESCRIBE}:BILL_ID=$FORM{BILL_ID}" : "$FORM{SUM}:$FORM{DESCRIBE}"
                      } );

        if ($shedule->{errno}) {
          $html->message('err', $_ERROR, "[$shedule->{errno}] $err_strs{$shedule->{errno}}");	
         }
        else {
  	      $html->message('info', $_SHEDULE, "$_ADDED");
         }
      }
     }
    #Add now
    else {
    	delete $FORM{DATE};
      $fees->take($user, $FORM{SUM}, { %FORM } );  
      if ($fees->{errno}) {
        $html->message('err', $_ERROR, "[$fees->{errno}] $err_strs{$fees->{errno}}");	
       }
      else {
        $html->message('info', $_FEES, "$_TAKE $_SUM: $fees->{SUM}");
        
        #External script
        if ($conf{external_fees}) {
          if (! _external($conf{external_fees}, { %FORM }) ) {
       	    return 0;
           }
         }
       }
    }
   }
  elsif ($FORM{del} && $FORM{is_js_confirmed}) {
  	if (! defined($permissions{2}{2})) {
      $html->message('err', $_ERROR, "[13] $err_strs{13}");
      return 0;		
	   }

	  $fees->del($user,  $FORM{del});
    if ($fees->{errno}) {
      $html->message('err', $_ERROR, "[$fees->{errno}] $err_strs{$fees->{errno}}");
     }
    else {
      $html->message('info', $_DELETED, "$_DELETED [$FORM{del}]");
    }
   }


  my $list = $shedule->list({ UID  => $user->{UID},
                              TYPE => 'fees' 
                             });
  
  if ($shedule->{TOTAL} > 0) {
     my $table2 = $html->table( { width      => '100%',
                            caption     => "$_SHEDULE",
                            border      => 1,
                            title_plain => ['#', $_DATE, $_SUM, '-'],
                            cols_align  => ['right', 'right', 'right', 'left',  'center:noprint'],
                            qs          => $pages_qs,
                            ID          => 'USER_SHEDULE'
                        } );

     foreach my $line (@$list) {
     	 my ($sum, undef) = split(/:/, $line->[7]);
     	   my $delete = ($permissions{2}{2}) ?  $html->button($_DEL, "index=85&del=$line->[14]", 
           { MESSAGE => "$_DEL ID: $line->[13]?", CLASS => 'del' }) : ''; 

     	 $table2->addrow($line->[13], "$line->[3]-$line->[2]-$line->[1]", sprintf('%.2f', $sum), $delete);
      }
     
     $fees->{SHEDULE}=$table2->show();
   }
  
  $fees->{PERIOD_FORM}=form_period($period, { TD_EXDATA  => 'colspan=2' });
  if ($permissions{2} && $permissions{2}{1}) {
    #exchange rate sel
    $fees->{SEL_ER}=$html->form_select('ER', 
                                { 
 	                                SELECTED          => undef,
 	                                SEL_MULTI_ARRAY   => [ ['', '', '', '', ''], @{ $fees->exchange_list() }],
 	                                MULTI_ARRAY_KEY   => 4,
 	                                MULTI_ARRAY_VALUE => '1,2',
 	                                NO_ID             => 1
 	                               });

    if ($conf{EXT_BILL_ACCOUNT}) {
       $fees->{EXT_DATA} = "<tr><td colspan=2>$_BILL:</td><td>". $html->form_select('BILL_ID', 
                                { SELECTED     => $FORM{BILL_ID} || $attr->{USER_INFO}->{BILL_ID},
 	                                SEL_HASH     => \%BILL_ACCOUNTS,
 	                                NO_ID        => 1
 	                               }).
 	                             "</td></tr>\n";
      }

    $fees->{SEL_METHOD} = $html->form_select('METHOD', 
                                { SELECTED     => (defined($FORM{METHOD}) && $FORM{METHOD} ne '') ? $FORM{METHOD} : '',
 	                                SEL_HASH     => \%FEES_METHODS,
 	                                NO_ID        => 1,
 	                                SORT_KEY     => 1,
                                  MAIN_MENU    => get_function_index('form_fees_types'),
 	                               });



#    $fees->{SEL_METHOD}=$html->form_select('METHOD', 
#                                { 
# 	                                SELECTED          => undef,
# 	                                SEL_MULTI_ARRAY   => $fees->fees_type_list(),
# 	                                MULTI_ARRAY_KEY   => 1,
# 	                                MULTI_ARRAY_VALUE => '1,3',
# 	                                NO_ID             => 1
# 	                               });

    

    $html->tpl_show(templates('form_fees'), $fees);
   }
}
elsif($FORM{AID} && ! defined($LIST_PARAMS{AID})) {
	$FORM{subf}=$index;
	
  form_admins();
	return 0;
 }
elsif($FORM{UID}) {
	form_users();
	return 0;
}
elsif($index != 7) {
  $FORM{type} = $FORM{subf} if ($FORM{subf});
	form_search({ HIDDEN_FIELDS => { subf       => ($FORM{subf}) ? $FORM{subf} : undef,
		                               COMPANY_ID => $FORM{COMPANY_ID} } });
}

return 0 if (! $permissions{2}{0});

if (! defined($FORM{sort})) {
  $LIST_PARAMS{SORT}=1;
  $LIST_PARAMS{DESC}=DESC;
 }


my $list = $fees->list( { %LIST_PARAMS } );
my $table = $html->table( { width      => '100%',
                            caption    => "$_FEES",
                            border     => 1,
                            title      => ['ID', $_LOGIN, $_DATE, $_DESCRIBE,  $_SUM, $_DEPOSIT, $_TYPE, "$_BILLS", $_ADMINS, 'IP','-'],
                            cols_align => ['right', 'left', 'right', 'right', 'left', 'left', 'right', 'right', 'left', 'center:noprint'],
                            qs         => $pages_qs,
                            pages      => $fees->{TOTAL},
                            ID         => 'FEES',
                            EXPORT     => $_EXPORT .' XML:&xml=1',
                        } );


$pages_qs .= "&subf=2" if (! $FORM{subf});
foreach my $line (@$list) {
  my $delete = ($permissions{2}{2}) ?  $html->button($_DEL, "index=3&del=$line->[0]&UID=".$line->[10], 
   { MESSAGE => "$_DEL ID: $line->[0]?", CLASS => 'del' }) : ''; 

  $table->addrow($html->b($line->[0]), 
  $html->button($line->[1], "index=15&UID=".$line->[10]), 
  $line->[2], 
  $line->[3]. ( ($line->[11] ) ? $html->br(). $html->b($line->[11]) : '' ), 
  $line->[4], 
  "$line->[5]",
  $FEES_METHODS{$line->[6]}, 
  ($BILL_ACCOUNTS{$line->[7]}) ? $BILL_ACCOUNTS{$line->[7]} : "$line->[7]",
  "$line->[8]", 
  "$line->[9]",
  $delete);
}

print $table->show();

if (! $admin->{MAX_ROWS}) {
  $table = $html->table( { width      => '100%',
                         cols_align => ['right', 'right', 'right', 'right', 'right', 'right'],
                         rows       => [ [ "$_TOTAL:", $html->b($fees->{TOTAL}), 
                                           "$_USERS:", $html->b($fees->{TOTAL_USERS}),
                                           "$_SUM:",   $html->b($fees->{SUM})
                                       ] ],
                         rowcolor   => 'even'
                     } );
  print $table->show();
 }


}

#**********************************************************
#
#**********************************************************
sub form_sendmail {
 my %MAIL_PRIORITY = (2 => 'High', 
                      3 => 'Normal', 
                      4 => 'Low');

 my $user = $users->info($FORM{UID});
 $user->pi();
 

 $user->{EMAIL} = (defined($user->{EMAIL}) && $user->{EMAIL} ne '') ? $user->{EMAIL} : $user->{LOGIN} .'@'. $conf{USERS_MAIL_DOMAIN};
 $user->{FROM} = $FORM{FROM} || $conf{ADMIN_MAIL};

 if ($FORM{sent}) {

   my @ATTACHMENTS = ();
   for(my $i=1; $i<=2; $i++) {
       if ($FORM{'FILE_UPLOAD_'. $i}) {
         push @ATTACHMENTS, {
           FILENAME      => $FORM{'FILE_UPLOAD_'. $i}{filename},
           CONTENT_TYPE  => $FORM{'FILE_UPLOAD_'. $i}{'Content-Type'},
           FILESIZE      => $FORM{'FILE_UPLOAD_'. $i}{Size},
           CONTENT       => $FORM{'FILE_UPLOAD_'. $i}{Contents},
          };
        }
    }

   sendmail("$user->{FROM}", "$user->{EMAIL}", "$FORM{SUBJECT}", "$FORM{TEXT}", 
     "$conf{MAIL_CHARSET}", "$FORM{PRIORITY} ($MAIL_PRIORITY{$FORM{PRIORITY}})", 
     { ATTACHMENTS => ($#ATTACHMENTS > -1) ? \@ATTACHMENTS : undef });
   my $table = $html->table({ width    => '100%',
                              rows     => [ [ "$_USER:",    "$user->{LOGIN}" ],
                                            [ "E-Mail:",    "$user->{EMAIL}" ],
                                            [ "$_SUBJECT:", "$FORM{SUBJECT}" ],
                                            [ "$_FROM:",    "$user->{FROM}"  ],
                                            [ "PRIORITY:",  "$FORM{PRIORITY} (". $MAIL_PRIORITY{$FORM{PRIORITY}} .")"]    
                                           ],
                              rowcolor => 'odd'
                              });

   $html->message('info', $_SENDED, $table->show());
   return 0;
  }

 $user->{EXTRA} = "<tr><td>$_TO:</td><td bgcolor='$_COLORS[2]'>$user->{EMAIL}</td></tr>\n";
 $user->{PRIORITY_SEL}=$html->form_select('PRIORITY', 
                                { SELECTED  => $FORM{PRIORITY},
 	                                SEL_HASH  => \%MAIL_PRIORITY
 	                               });

 $html->tpl_show(templates('mail_form'), $user); 
}


#**********************************************************
# Search form
#**********************************************************
sub form_search {
  my ($attr) = @_;

  my %SEARCH_DATA = $admin->get_data(\%FORM);  

if ($FORM{search}) {
	$LIST_PARAMS{LOGIN}=$FORM{LOGIN};
  $pages_qs  = "&search=1";
  $pages_qs .= "&type=$FORM{type}" if ($pages_qs !~ /&type=/);
	
	while(my($k, $v)=each %FORM) {
		if ($k =~ /([A-Z0-9]+|_[a-z0-9]+)/ && $v ne '' && $k ne '__BUFFER') {
		  $LIST_PARAMS{$k}= $v;
	    $pages_qs      .= "&$k=$v";
		 }
	 }

  if ($FORM{type} ne $index) {
    $functions{$FORM{type}}->();
   }
}


if (defined($attr->{HIDDEN_FIELDS})) {
	my $SEARCH_FIELDS = $attr->{HIDDEN_FIELDS};
	while(my($k, $v)=each( %$SEARCH_FIELDS )) {
	  $SEARCH_DATA{HIDDEN_FIELDS}.=$html->form_input("$k", "$v", { TYPE          => 'hidden',
       	                                                         OUTPUT2RETURN => 1
      	                                                        });
	 }
}

 $SEARCH_DATA{HIDDEN_FIELDS}.=$html->form_input("GID", "$FORM{GID}", { TYPE => 'hidden', OUTPUT2RETURN => 1 })  if ($FORM{GID});


if (defined($attr->{SIMPLE})) {
	my $SEARCH_FIELDS = $attr->{SIMPLE};
	while(my($k, $v)=each( %$SEARCH_FIELDS )) {
    $SEARCH_DATA{SEARCH_FORM}.="<tr><td>$k:</td><td>";
	  if ( ref $v eq 'HASH' ) {
      $SEARCH_DATA{SEARCH_FORM}.=$html->form_select("$k",
			                                   {   SELECTED => $FORM{$k},
		                                         SEL_HASH => $v
                                          });
	   }
	  else {
	    $SEARCH_DATA{SEARCH_FORM}.=$html->form_input("$v", '%'. $v .'%');
	   }
    $SEARCH_DATA{SEARCH_FORM}.="</td></tr>\n";
	 }

  $html->tpl_show(templates('form_search_simple'), \%SEARCH_DATA);
 }
elsif ($attr->{TPL}) {
	#defined();
 }
elsif(! $FORM{pdf}) {
  my $group_sel = sel_groups();
  my %search_form = ( 
     2  => 'form_search_payments',
     3  => 'form_search_fees',
     11 => 'form_search_users',
     13 => 'form_search_companies'
    );

  $FORM{type}=11 if ($FORM{type} == 15);

  if( $FORM{LOGIN} && $admin->{MIN_SEARCH_CHARS} && length($FORM{LOGIN}) < $admin->{MIN_SEARCH_CHARS}) {
	  $html->message('err', $_ERROR, "$_ERR_SEARCH_VAL_TOSMALL. $_MIN: $admin->{MIN_SEARCH_CHARS}");
	  return 0;
   }

if (defined($attr->{SEARCH_FORM})) {
	$SEARCH_DATA{SEARCH_FORM} = $attr->{SEARCH_FORM}
 } 
elsif($search_form{$FORM{type}}) {
  if ($FORM{type} == 2) {
   push @PAYMENT_METHODS, @EX_PAYMENT_METHODS if (@EX_PAYMENT_METHODS);
   %PAYMENTS_METHODS = ();
   
   for(my $i=0; $i<=$#PAYMENT_METHODS; $i++) {
	   $PAYMENTS_METHODS{"$i"}="$PAYMENT_METHODS[$i]";
    }

   my %PAYSYS_PAYMENT_METHODS = %{ cfg2hash($conf{PAYSYS_PAYMENTS_METHODS}) };

   while(my($k, $v) = each %PAYSYS_PAYMENT_METHODS ) {
	   $PAYMENTS_METHODS{$k}=$v;
    }

   $info{SEL_METHOD} = $html->form_select('METHOD', 
                                { SELECTED     => (defined($FORM{METHOD}) && $FORM{METHOD} ne '') ? $FORM{METHOD} : '',
 	                                SEL_HASH     => \%PAYMENTS_METHODS,
 	                                SORT_KEY     => 1,
 	                                SEL_OPTIONS   => { '' => $_ALL }
 	                               });
   }
  elsif ($FORM{type} == 3) {
    $info{SEL_METHOD} =  $html->form_select('METHOD', 
                                { SELECTED      => (defined($FORM{METHOD}) && $FORM{METHOD} ne '') ? $FORM{METHOD} : '',
 	                                SEL_HASH      => get_fees_types(),
 	                                ARRAY_NUM_ID  => 1,
                                  SEL_OPTIONS   => { '' => $_ALL }
 	                               });
   }
  elsif ($FORM{type} == 11 || $FORM{type} == 15) {
    $FORM{type}=11;

    my $i=0; 
    my $list = $users->config_list({ PARAM => 'ifu*', SORT => 2  });
    if ($users->{TOTAL} > 0) {
    	 $info{INFO_FIELDS}.= "<tr><th colspan='3' bgcolor='$_COLORS[0]'>$_INFO_FIELDS</th></tr>\n"
      }
    foreach my $line (@$list) {
      my $field_id       = '';
      if ($line->[0] =~ /ifu(\S+)/) {
    	  $field_id = $1;
       }

      my($position, $type, $name, $user_portal)=split(/:/, $line->[1]);

      my $input = '';
      if ($type == 2) {
        $input = $html->form_select("$field_id", 
                                { SELECTED          => $FORM{$field_id},
 	                                SEL_MULTI_ARRAY   => $users->info_lists_list( { LIST_TABLE => $field_id.'_list' }), 
 	                                MULTI_ARRAY_KEY   => 0,
 	                                MULTI_ARRAY_VALUE => 1,
 	                                SEL_OPTIONS       => { 0 => '-N/S-'},
 	                                NO_ID             => 1
 	                               });
    	
       }
      elsif ($type == 5) {
      	 next;
       }
      elsif ($type == 4) {
    	  $input = $html->form_input($field_id, 1, { TYPE  => 'checkbox',  
    		                                           STATE => ($FORM{$field_id}) ? 1 : undef  });
       }
      else {
    	  $input = $html->form_input($field_id, "$FORM{$field_id}", { SIZE => 40 });
       }

      $info{INFO_FIELDS}.= "<tr><td colspan=2>". (eval "\"$name\"") . ":</td><td>$input</td></tr>\n";
      $i++;
     }


    $info{CREDIT_DATE}  = $html->date_fld2('CREDIT_DATE', { NO_DEFAULT_DATE => 1, MONTHES => \@MONTHES, FORM_NAME => 'form_search', WEEK_DAYS => \@WEEKDAYS, TABINDEX => 12 });
    $info{CONTRACT_DATE}= $html->date_fld2('CONTRACT_DATE', { NO_DEFAULT_DATE => 1, MONTHES => \@MONTHES, FORM_NAME => 'form_search', WEEK_DAYS => \@WEEKDAYS, TABINDEX => 12 });
    $info{PAYMENTS}     = $html->date_fld2('PAYMENTS', { NO_DEFAULT_DATE => 1, MONTHES => \@MONTHES, FORM_NAME => 'form_search', WEEK_DAYS => \@WEEKDAYS, TABINDEX => 14 });
    $info{REGISTRATION} = $html->date_fld2('REGISTRATION', { NO_DEFAULT_DATE => 1, MONTHES => \@MONTHES, FORM_NAME => 'form_search', WEEK_DAYS => \@WEEKDAYS, TABINDEX => 16 });
    $info{ACTIVATE}     = $html->date_fld2('ACTIVATE', { NO_DEFAULT_DATE => 1, MONTHES => \@MONTHES, FORM_NAME => 'form_search', WEEK_DAYS => \@WEEKDAYS, TABINDEX => 17 });
    $info{EXPIRE}       = $html->date_fld2('EXPIRE', { NO_DEFAULT_DATE => 1, MONTHES => \@MONTHES, FORM_NAME => 'form_search', WEEK_DAYS => \@WEEKDAYS, TABINDEX => 18 });
    $info{PASPORT_DATE} = $html->date_fld2('PASPORT_DATE', { NO_DEFAULT_DATE => 1, MONTHES => \@MONTHES, FORM_NAME => 'form_search', WEEK_DAYS => \@WEEKDAYS, TABINDEX => 27 });

    if (in_array('Docs', \@MODULES) ) {
      if ($conf{DOCS_CONTRACT_TYPES}) {
    	  $conf{DOCS_CONTRACT_TYPES} =~ s/\n//g;
        my (@contract_types_list)=split(/;/, $conf{DOCS_CONTRACT_TYPES});

        my %CONTRACTS_LIST_HASH = ();
        foreach my $line (@contract_types_list) {
      	  my ($prefix, $sufix, $name, $tpl_name)=split(/:/, $line);
      	  
      	  #print "P $prefix, $sufix, $name, $tpl_name<br>";
      	  
      	  $prefix =~ s/ //g;
      	  $CONTRACTS_LIST_HASH{"$prefix|$sufix"}=$name;
         }

        $info{CONTRACT_SUFIX}=$html->form_select('CONTRACT_SUFIX', 
                                { SELECTED   => $FORM{CONTRACT_SUFIX},
 	                                SEL_HASH   => {'' => '', %CONTRACTS_LIST_HASH },
 	                                NO_ID      => 1
 	                               });
       
       }
     }

    if ($conf{ADDRESS_REGISTER}) {
     	$info{ADDRESS_FORM} = $html->tpl_show(templates('form_address_sel'), $user_pi, { OUTPUT2RETURN => 1 });
     	$info{ADDRESS_FORM} .= "<tr><td>$_NO_RECORD</td><td><input type=checkbox name='NOT_FILLED' value='1'></td></tr>";
     }
    else {
  	  my $countries = $html->tpl_show(templates('countries'), undef, { OUTPUT2RETURN => 1 });
  	  my @countries_arr  = split(/\n/, $countries);
      my %countries_hash = ();
      foreach my $c (@countries_arr) {
    	  my ($id, $name)=split(/:/, $c);
    	  $countries_hash{int($id)}=$name;
       }
      $user_pi->{COUNTRY_SEL} = $html->form_select('COUNTRY_ID', 
                                { SELECTED   => $FORM{COUNTRY_ID},
 	                                SEL_HASH   => {'' => '', %countries_hash },
 	                                NO_ID      => 1
 	                               });
      $info{ADDRESS_FORM} = $html->tpl_show(templates('form_address'), $user_pi, { OUTPUT2RETURN => 1 });	
     }
   }
  elsif ($FORM{type} == 13) {
    my $i=0; 
    my $list = $users->config_list({ PARAM => 'ifu*', SORT => 2  });
    if ($users->{TOTAL} > 0) {
    	 $info{INFO_FIELDS}.= "<tr><th colspan='3' bgcolor='$_COLORS[0]'>$_INFO_FIELDS</th></tr>\n"
      }
    foreach my $line (@$list) {
      my $field_id       = '';
      if ($line->[0] =~ /ifu(\S+)/) {
    	  $field_id = $1;
       }

      my($position, $type, $name, $user_portal)=split(/:/, $line->[1]);

      my $input = '';
      if ($type == 2) {
        $input = $html->form_select("$field_id", 
                                { SELECTED          => $FORM{$field_id},
 	                                SEL_MULTI_ARRAY   => $users->info_lists_list( { LIST_TABLE => $field_id.'_list' }), 
 	                                MULTI_ARRAY_KEY   => 0,
 	                                MULTI_ARRAY_VALUE => 1,
 	                                SEL_OPTIONS       => { 0 => '-N/S-'},
 	                                NO_ID             => 1
 	                               });
    	
       }
      elsif ($type == 5) {
      	 next;
       }
      elsif ($type == 4) {
    	  $input = $html->form_input($field_id, 1, { TYPE  => 'checkbox',  
    		                                           STATE => ($FORM{$field_id}) ? 1 : undef  });
       }
      else {
    	  $input = $html->form_input($field_id, "$FORM{$field_id}", { SIZE => 40 });
       }

      $info{INFO_FIELDS}.= "<tr><td colspan=2>". (eval "\"$name\"") . ":</td><td>$input</td></tr>\n";
      $i++;
     }

    $info{CREDIT_DATE}  = $html->date_fld2('CREDIT_DATE', { NO_DEFAULT_DATE => 1, MONTHES => \@MONTHES, FORM_NAME => 'form_search', WEEK_DAYS => \@WEEKDAYS, TABINDEX => 12 });
    $info{PAYMENTS}     = $html->date_fld2('PAYMENTS', { NO_DEFAULT_DATE => 1, MONTHES => \@MONTHES, FORM_NAME => 'form_search', WEEK_DAYS => \@WEEKDAYS, TABINDEX => 14 });
    $info{REGISTRATION} = $html->date_fld2('REGISTRATION', { NO_DEFAULT_DATE => 1, MONTHES => \@MONTHES, FORM_NAME => 'form_search', WEEK_DAYS => \@WEEKDAYS, TABINDEX => 16 });
    $info{ACTIVATE}     = $html->date_fld2('ACTIVATE', { NO_DEFAULT_DATE => 1, MONTHES => \@MONTHES, FORM_NAME => 'form_search', WEEK_DAYS => \@WEEKDAYS, TABINDEX => 17 });
    $info{EXPIRE}       = $html->date_fld2('EXPIRE', { NO_DEFAULT_DATE => 1, MONTHES => \@MONTHES, FORM_NAME => 'form_search', WEEK_DAYS => \@WEEKDAYS, TABINDEX => 18 });

    if ($conf{ADDRESS_REGISTER}) {
     	$info{ADDRESS_FORM} = $html->tpl_show(templates('form_address_sel'), $user_pi, { OUTPUT2RETURN => 1 });
     	$info{ADDRESS_FORM} .= "<tr><td>$_NO_RECORD</td><td><input type=checkbox name='NOT_FILLED' value='1'></td></tr>";
     }
    else {
  	  my $countries = $html->tpl_show(templates('countries'), undef, { OUTPUT2RETURN => 1 });
  	  my @countries_arr  = split(/\n/, $countries);
      my %countries_hash = ();
      foreach my $c (@countries_arr) {
    	  my ($id, $name)=split(/:/, $c);
    	  $countries_hash{int($id)}=$name;
       }
      $user_pi->{COUNTRY_SEL} = $html->form_select('COUNTRY_ID', 
                                { SELECTED   => $FORM{COUNTRY_ID},
 	                                SEL_HASH   => {'' => '', %countries_hash },
 	                                NO_ID      => 1
 	                               });
      $info{ADDRESS_FORM} = $html->tpl_show(templates('form_address'), $user_pi, { OUTPUT2RETURN => 1 });	
     }
   }	

	$SEARCH_DATA{SEARCH_FORM} =  $html->tpl_show(templates($search_form{$FORM{type}}), { %FORM, %info, GROUPS_SEL => $group_sel }, { OUTPUT2RETURN => 1 });
	$SEARCH_DATA{SEARCH_FORM} .= $html->form_input('type', "$FORM{type}", { TYPE => 'hidden' });
 }

$SEARCH_DATA{FROM_DATE} = $html->date_fld2('FROM_DATE', { MONTHES => \@MONTHES, FORM_NAME => 'form_search', WEEK_DAYS => \@WEEKDAYS });
$SEARCH_DATA{TO_DATE}   = $html->date_fld2('TO_DATE', { MONTHES => \@MONTHES, FORM_NAME => 'form_search', WEEK_DAYS => \@WEEKDAYS } );

my $SEL_TYPE = $html->form_select('type', 
                                { SELECTED   => $FORM{type},
 	                                SEL_HASH   => \%SEARCH_TYPES,
 	                                NO_ID      => 1
 	                               });
if ($index == 7) {
	$SEARCH_DATA{SEL_TYPE}="<tr><td colspan='2'>\n<table width='100%'><tr>";
	
	while(my($k, $v) = each %SEARCH_TYPES ) {
    if ($k == 11 || $k == 13 || $permissions{($k-1)}) {
		  $SEARCH_DATA{SEL_TYPE}.= "<th";
		  $SEARCH_DATA{SEL_TYPE}.= " bgcolor=$_COLORS[0]" if ($FORM{type} eq $k);
		  $SEARCH_DATA{SEL_TYPE}.= '>';
		  $SEARCH_DATA{SEL_TYPE}.= $html->button($v, "index=$index&type=$k"); #&search=1");
		  $SEARCH_DATA{SEL_TYPE}.="</th>\n";
 		 }
	 }

$SEARCH_DATA{SEL_TYPE}.="</tr>
</table>\n</td></tr>\n";
}

  $html->tpl_show(templates('form_search'), { %SEARCH_DATA  }, { ID => $attr->{ID} });
}

}

#**********************************************************
# form_shedule()
#**********************************************************
sub form_shedule {

use Shedule;
my $Shedule = Shedule->new($db, $admin);

if ($FORM{add}) {
	$Shedule->add({ D => $FORM{D},
		M        => $FORM{M},
		Y        => $FORM{Y},
		TYPE     => $FORM{TYPE},
		ACTION   => $FORM{ACTION},
		COMMENTS => $FORM{COMMENTS},
		COUNT    => $FORM{COUNT}
	 });

  if (! $Shedule->{errno}) {
    $html->message('info', $_ADDED, "$_ADDED [$Shedules->{INSERT_ID}]");
   }
 }
elsif ($FORM{del} && $FORM{is_js_confirmed}) {
  $Shedule->del({ ID => $FORM{del} });
  if (! $Shedule->{errno}) {
    $html->message('info', $_DELETED, "$_DELETED [$FORM{del}]");
   }
}

  if ($Shedule->{errno}) {
    $html->message('err', $_ERROR, "[$Shedule->{errno}] $err_strs{$Shedule->{errno}}");
   }



$Shedule->{SEL_D} = $html->form_select('D', 
                                { SELECTED   => $FORM{D},
 	                                SEL_HASH   => { '*' => '*', 	                                	
 	                                	1 => 1,
 	                                	2 => 2,
 	                                	3 => 3,
 	                                	4 => 4,
 	                                	5 => 5,
 	                                	6 => 6,
 	                                	7 => 7,
 	                                	8 => 8,
 	                                	9 => 9,
 	                                	10 => 10,
 	                                	11 => 11,
 	                                	12 => 12,
 	                                	13 => 13,
 	                                	14 => 14,
 	                                	15 => 15,
 	                                	16 => 16,
 	                                	17 => 17,
 	                                	18 => 18,
 	                                	19 => 19,
 	                                	20 => 20,
 	                                	21 => 21,
 	                                	22 => 22,
 	                                	23 => 23,
 	                                	24 => 24,
 	                                	25 => 25,
 	                                	26 => 26,
 	                                	27 => 27,
 	                                	28 => 28,
 	                                	29 => 29,
 	                                	30 => 30,
 	                                	31 => 31 	                                	
 	                                	}, 
 	                                NO_ID       => 1,
 	                                SORT_KEY_NUM   => 1
 	                               });

$Shedule->{SEL_M} = $html->form_select('M', 
                                { SELECTED   => $FORM{M},
 	                                SEL_HASH   => { '*' => '*',
 	                                	 1 => $MONTHES[0],
 	                                	 2 => $MONTHES[1],
 	                                	 3 => $MONTHES[2],
 	                                	 4 => $MONTHES[3],
 	                                	 5 => $MONTHES[4],
 	                                	 6 => $MONTHES[5],
 	                                	 7 => $MONTHES[6],
 	                                	 8 => $MONTHES[7],
 	                                	 9 => $MONTHES[8],
 	                                	 10 => $MONTHES[9],
 	                                	 11 => $MONTHES[10],
 	                                	 12 => $MONTHES[11],
 	                                	}, 
 	                                NO_ID      => 1,
 	                                SORT_KEY_NUM   => 1
 	                               });

my ($YEAR, $MONTH, $DAY)=split(/-/, $DATE);

$Shedule->{SEL_Y} = $html->form_select('Y', 
                                { SELECTED   => $FORM{Y},
 	                                SEL_HASH   => { '*' => '*', $YEAR => $YEAR, ($YEAR+1) => ($YEAR+1), ($YEAR+2) => ($YEAR+2) },
	                                NO_ID      => 1,
	                                SORT_KEY_NUM   => 1
 	                               });

$Shedule->{SEL_TYPE} = $html->form_select('TYPE', 
                                { SELECTED   => $FORM{TYPE},
 	                                SEL_HASH   => { 'sql' => 'SQL' },
	                                NO_ID      => 1,
 	                               }); 	                               



$html->tpl_show(templates("form_shedule"), { %$Shedule }, );  	



my %TYPES = ('tp'    => "$_CHANGE $_TARIF_PLAN",
             'fees'  => "$_FEES",
             'status'=> "$_STATUS",
             'sql'   => 'SQL'
             ); 

my $list = $Shedule->list( { %LIST_PARAMS } );
my $table = $html->table( { width      => '100%',
                            border     => 1,
                            caption    => "$_SHEDULE",
                            title      => ["$_HOURS", "$_DAY", "$_MONTH", "$_YEAR", "$_COUNT", "$_USER", "$_TYPE", "$_VALUE", "$_MODULES", "$_ADMINS", "$_CREATED", "$_COMMENTS", "-"],
                            cols_align => ['right', 'right', 'right', 'right', 'right', 'left', 'right', 'right', 'right', 'left', 'right', 'center'],
                            qs         => $pages_qs,
                            pages      => $Shedule->{TOTAL},
                            ID         => 'SHEDULE'
                          });
my ($y, $m, $d)=split(/-/, $DATE, 3);
foreach my $line (@$list) {
  my $delete = ($permissions{4}{3}) ?  $html->button($_DEL, "index=$index&del=$line->[14]", { MESSAGE =>  "$_DEL [$line->[14]]?",  CLASS => 'del' }) : '-'; 
  my $value = "$line->[7]";
  
  if ($line->[6] eq 'status') {
  	my @service_status_colors = ("$_COLORS[9]", "$_COLORS[6]", '#808080', '#0000FF', '#FF8000', '#009999');
    my @service_status = ( "$_ENABLE", "$_DISABLE", "$_NOT_ACTIVE", "$_HOLD_UP", "$_DISABLE: $_NON_PAYMENT", "$ERR_SMALL_DEPOSIT" );
  	$value = $html->color_mark($service_status[$line->[7]], $service_status_colors[$line->[7]])
   }
  
  if (int($line->[3].$line->[2].$line->[1]) <= int($y.$m.$d) && 
       $line->[3] ne '*' && $line->[2] ne '*'  && $line->[1] ne '*') {
  	$table->{rowcolor}=$_COLORS[6];
   }
  else {
  	$table->{rowcolor}=undef;
   }
  
  $table->addrow($html->b($line->[0]), $line->[1], $line->[2], 
    $line->[3],  $line->[4],  
    $html->button($line->[5], "index=15&UID=$line->[13]"), 
    ($TYPES{$line->[6]}) ? $TYPES{$line->[6]} : $line->[6], 
    $value,
    "$line->[8]", 
    "$line->[9]", 
    "$line->[10]", 
    "$line->[11]", 
    $delete);
}
print $table->show();

$table = $html->table({ width      => '100%',
                        cols_align => ['right', 'right', 'right', 'right'],
                        rows       => [ [ "$_TOTAL:", $html->b($Shedule->{TOTAL}) ] ]
                       });
print $table->show();
}

#**********************************************************
# Create templates
# form_templates()
#**********************************************************
sub form_templates {
  
  my $sys_templates = '../../Abills/modules';
  my $main_templates_dir = '../../Abills/main_tpls/';
  my $template = '';
  my %info = ();
  my $main_tpl_name = '';
  
  my $domain_path = '';
  if ($admin->{DOMAIN_ID}) {
  	$domain_path="$admin->{DOMAIN_ID}/";
	  $conf{TPL_DIR} = "$conf{TPL_DIR}/$domain_path";
	  if (! -d "$conf{TPL_DIR}") {
    	if (! mkdir("$conf{TPL_DIR}") ) {
    		$html->message('err', $_ERROR, "$ERR_CANT_CREATE_FILE '$conf{TPL_DIR}' $_ERROR: $!\n");
    	  }
     }
   }

$info{ACTION_LNG}=$_CHANGE;

if ($FORM{create}) {
   $FORM{create} =~ s/ |\///g;
   my ($module, $file, $lang)=split(/:/, $FORM{create}, 3);
   my $filename = ($module) ? "$sys_templates/$module/templates/$file" : "$main_templates_dir/$file";

   if ($lang ne '') {
   	  $file =~ s/\.tpl/_$lang/;
   	  $file .= '.tpl';
    }

   $main_tpl_name = $file;
   $info{TPL_NAME} = "$module"._."$file";

   if (-f  $filename ) {
	  open(FILE, $filename) || $html->message('err', $_ERROR, "Can't open file '$filename' $!\n");;
  	  while(<FILE>) {
	    	$info{TEMPLATE} .= $_;
	    }	 
	  close(FILE);
   }

  $info{TEMPLATE} =~ s/\\"/"/g;
  show_tpl_info($filename);
 }
elsif ($FORM{SHOW}) {
	print $html->header();
  my ($module, $file, $lang)=split(/:/, $FORM{SHOW}, 3);
  $file =~ s/.tpl//;
  $file =~ s/ |\///g;

  $html->{language}=$lang if ($lang ne '');

  if ($module) {
    my $realfilename = "$prefix/Abills/modules/$module/lng_$html->{language}.pl";
    my $lang_file;
    my $prefix = '../..';
    if (-f $realfilename) {
      $lang_file =  $realfilename;
     }
    elsif (-f "$prefix/Abills/modules/$module/lng_english.pl") {
   	  $lang_file = "$prefix/Abills/modules/$module/lng_english.pl";
     }

    if ($lang_file ne '') {
      require $lang_file;
     }
   }

  print "<center>";
  if ($module) {
    $html->tpl_show(_include("$file", "$module"), { LNG_ACTION => $_ADD },  ); 
   }
  else {
    $html->tpl_show(templates("$file"), { LNG_ACTION => $_ADD }, );  	
   } 
  print "</center>\n";
	
	return 0;
 }
elsif ($FORM{change}) {
  my $FORM2  = ();
  my @pairs = split(/&/, $FORM{__BUFFER});
  $info{ACTION_LNG}=$_CHANGE;
  
  foreach my $pair (@pairs) {
    my ($side, $value) = split(/=/, $pair);
    $value =~ tr/+/ /;
    $value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;

    if (defined($FORM2{$side})) {
      $FORM2{$side} .= ", $value";
     }
    else {
      $FORM2{$side} = $value;
     }
   }

  if ($FORM{FORMAT} && $FORM{FORMAT} eq 'unix') {
  	$FORM2{template} =~ s/\r//g;
   }

  $info{TEMPLATE} = $FORM2{template};
  $info{TPL_NAME} = $FORM{tpl_name};
  $info{TEMPLATE} = convert($info{TEMPLATE}, { '2_tpl' => 1 });
  $info{TEMPLATE} =~ s/"/\\"/g;
  $info{TEMPLATE} =~ s/\@/\\@/g;
	
	if (open(FILE, ">$conf{TPL_DIR}/$FORM{tpl_name}")) {
	  print FILE "$info{TEMPLATE}";
	  close(FILE);
	  $html->message('info', $_INFO, "$_CHANGED '$FORM{tpl_name}'");
	 }
  else {
  	$html->message('err', $_ERROR, "Can't open file '$conf{TPL_DIR}/$FORM{tpl_name}' $!\n");
   }

  $main_tpl_name = $FORM{tpl_name};
  $main_tpl_name =~ s/^_//;
  $info{TEMPLATE} =~ s/\\"/"/g;
  $info{TEMPLATE} =~ s/\\\@/\@/g;
 }
elsif ($FORM{FILE_UPLOAD}) {
	upload_file($FORM{FILE_UPLOAD});
 }
elsif ($FORM{file_del} && $FORM{is_js_confirmed} ) {
  $FORM{file_del} =~ s/ |\///g;
  if(unlink("$conf{TPL_DIR}/$FORM{file_del}") == 1 ) {	
	  $html->message('info', $_DELETED, "$_DELETED: '$FORM{file_del}'");
	 }
  else {
  	$html->message('err', $_DELETED, "$_ERROR");
   }
 }
elsif ($FORM{del} && $FORM{is_js_confirmed} ) {
  $FORM{del} =~ s/ |\///g;
  if(unlink("$conf{TPL_DIR}/$FORM{del}") == 1 ) {	
	  $html->message('info', $_DELETED, "$_DELETED: '$FORM{del}'");
	 }
  else {
  	$html->message('err', $_DELETED, "$_ERROR");
   }
 }
elsif($FORM{tpl_name}) {
    show_tpl_info("$conf{TPL_DIR}/$FORM{tpl_name}");
  
  if (-f  "$conf{TPL_DIR}/$FORM{tpl_name}" ) {
	  open(FILE, "$conf{TPL_DIR}/$FORM{tpl_name}") || $html->message('err', $_ERROR, "Can't open file '$conf{TPL_DIR}/$FORM{tpl_name}' $!\n");;
  	  while(<FILE>) {
	    	 $info{TEMPLATE} .= $_;
	    }	 
	  close(FILE);
    $info{TPL_NAME} = $FORM{tpl_name};
    $html->message('info', $_CHAMGE, "$_CHANGE: $FORM{tpl_name}");
    
    $main_tpl_name = $FORM{tpl_name};
    $main_tpl_name =~ s/^_//;
    
    $info{TEMPLATE} =~ s/\\"/"/g;
   }
}

#$html->tpl_show(templates('form_template_editor'), { %info });

$info{TEMPLATE} = convert($info{TEMPLATE}, { from_tpl => 1 });

print << "[END]";
<form action='$SELF_URL' METHOD='POST'>
<input type="hidden" name="index" value='$index'>
<input type="hidden" name="tpl_name" value='$info{TPL_NAME}'>
<table>
<tr bgcolor="$_COLORS[0]"><th>$_TEMPLATES</th></tr>
<tr bgcolor="$_COLORS[0]"><td>$info{TPL_NAME}</td></tr>
<tr><td>
   <textarea cols="100" rows="30" name="template">$info{TEMPLATE}</textarea>
</td></tr>
<tr bgcolor=$_COLORS[2]><td>FORMAT: 
<select name=FORMAT>
  <option value=unix>Unix</option>
  <option value=win>Win</option>
</select>
</td></tr>
<tr><td>$conf{TPL_DIR}/$info{TPL_NAME}</td></tr>
</table>
<input type="submit" name="change" value='$info{ACTION_LNG}'>
</form>
[END]



my @caption = keys %LANG;

my $table = $html->table( { width       => '100%',
	                          caption     => $_TEMPLATES,
                            title_plain => ["FILE", "$_SIZE (Byte)", "$_DATE", "$_DESCRIBE",  "$_MAIN", @caption],
                            cols_align  => ['left', 'right', 'right', 'left', 'center', 'center'],
                            ID          => 'TEMPLATES_LIST'
                         } );

use POSIX qw(strftime);

#Main templates section
$table->{rowcolor}= 'row_active';
$table->{extra}   = "colspan='". ( 6 + $#caption )."' class='small'";
$table->addrow("$_PRIMARY: ($main_templates_dir) ");
if (-d $main_templates_dir ) {
    my $tpl_describe = get_tpl_describe("$main_templates_dir/describe.tpls");
    opendir DIR, "$main_templates_dir" or die "Can't open dir '$sys_templates/main_tpls' $!\n";
      my @contents = grep  !/^\.\.?$/  , readdir DIR;
    closedir DIR;
    $table->{rowcolor}=undef;
    $table->{extra}=undef;
    foreach my $file (sort @contents) {
      if (-d "$main_templates_dir".$file) {
      	next;
       } 
      elsif ($file !~ /\.tpl$/) {
      	next;
       }

      ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,
        $blksize,$blocks);

      if (-f "$conf{TPL_DIR}/$module"."_$file") {
        ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,
         $blksize,$blocks)=stat("$conf{TPL_DIR}/$module"."_$file");
        $mtime = strftime "%Y-%m-%d", localtime($mtime);
       }
      else {
 	      ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,
         $blksize,$blocks)=stat("$main_templates_dir".$file);
        $mtime = strftime "%Y-%m-%d", localtime($mtime);
       }

      # LANG
      my @rows = (
      "$file", $size, $mtime, 
         (($tpl_describe->{$file}) ? $tpl_describe->{$file} : '' ),
         $html->button($_SHOW, "#", { NEW_WINDOW => "$SELF_URL?qindex=$index&SHOW=$module:$file", CLASS => 'show rightAlignText', SIZE => 10 }) .
         ( (-f "$conf{TPL_DIR}/_$file") ? $html->button($_CHANGE, "index=$index&tpl_name="."_$file", { CLASS => 'change rightAlignText', }) : $html->button($_CREATE, "index=$index&create=:$file", { CLASS => 'add rightAlignText' }) ) .
         ( (-f "$conf{TPL_DIR}/_$file") ? $html->button($_DEL, "index=$index&del=". "_$file", { MESSAGE => "$_DEL '$file'", CLASS => 'del rightAlignText' }) : '' )
      );    

      $file =~ s/\.tpl//;
      foreach my $lang (@caption) {
      	 my $f = '_'.$file.'_'.$lang.'.tpl';
        push @rows,  ((-f "$conf{TPL_DIR}/$f") ? $html->button($_SHOW, "index=$index#", { NEW_WINDOW => "$SELF_URL?qindex=$index&SHOW=$module:$file:$lang" , CLASS => 'show rightAlignText' }).$html->br(). $html->button($_CHANGE, "index=$index&tpl_name=$f", { CLASS => 'change rightAlignText' }) : $html->button($_CREATE, "index=$index&create=:$file".'.tpl'.":$lang", { CLASS => 'add rightAlignText' }) ).
         ( (-f "$conf{TPL_DIR}/$f") ? $html->button($_DEL, "index=$index&del=$f", { MESSAGE => "$_DEL '$f'", CLASS => 'del rightAlignText' }) : '' );
       }

      $table->{rowcolor} = ($file.'.tpl' eq $main_tpl_name) ? 'row_active' : undef;
      $table->addrow(
         @rows
         );
     }

 }


foreach my $module (sort @MODULES) {
	$table->{rowcolor}="row_active";
	$table->{extra}="colspan='". ( 6 + $#caption )."'";
	$table->addrow("$module ($sys_templates/$module/templates)");

	if (-d "$sys_templates/$module/templates" ) {
		my $tpl_describe = get_tpl_describe("$sys_templates/$module/templates/describe.tpls");
		
    opendir DIR, "$sys_templates/$module/templates" or die "Can't open dir '$sys_templates/$module/templates' $!\n";
      my @contents = grep  !/^\.\.?$/ && /\.tpl$/  , readdir DIR;
    closedir DIR;

    $table->{rowcolor}=undef;
    $table->{extra}=undef;

    foreach my $file (sort @contents) {
      next if (-d "$sys_templates/$module/templates/".$file);

      my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,
        $blksize,$blocks);

      if (-f "$conf{TPL_DIR}/$module"."_$file") {
        ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,
         $blksize,$blocks)=stat("$conf{TPL_DIR}/$module"."_$file");
        $mtime = strftime "%Y-%m-%d", localtime($mtime);
       }
      else {
 	      ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,
         $blksize,$blocks)=stat("$sys_templates/$module/templates/".$file);
        $mtime = strftime "%Y-%m-%d", localtime($mtime);
       }

      # LANG
      my @rows = ("$file", $size, $mtime, 
         (($tpl_describe->{$file}) ? $tpl_describe->{$file} : '' ),
         $html->button($_SHOW, "index=$index#", { NEW_WINDOW => "$SELF_URL?qindex=$index&SHOW=$module:$file", CLASS => 'show rightAlignText' }) .
         ( (-f "$conf{TPL_DIR}/$module"."_$file") ? $html->button($_CHANGE, "index=$index&tpl_name=$module"."_$file", { CLASS => 'change rightAlignText' }) : $html->button($_CREATE, "index=$index&create=$module:$file", { CLASS => 'add rightAlignText' }) ). 
         ( (-f "$conf{TPL_DIR}/$module"."_$file") ? $html->button($_DEL, "index=$index&del=$module". "_$file", { MESSAGE => "$_DEL $file", CLASS => 'del rightAlignText' }) : '' )
        );
      
      
      $file =~ s/\.tpl//;

      foreach my $lang (@caption) {
      	  my $f = '_'.$file.'_'.$lang.'.tpl';
      	
        push @rows,  ((-f "$conf{TPL_DIR}/$module"."$f") ? $html->button($_SHOW, "index=$index#", { NEW_WINDOW => "$SELF_URL?qindex=$index&SHOW=$module:$file:$lang", { CLASS => 'show rightAlignText' } }) .
        	$html->button($_CHANGE, "index=$index&tpl_name=$module"."$f", {  CLASS => 'change rightAlignText' } ) : $html->button($_CREATE, "index=$index&create=$module:$file".'.tpl'.":$lang", { CLASS => 'add rightAlignText' }) ).
         ((-f "$conf{TPL_DIR}/$module"."$f") ? $html->button($_DEL, "index=$index&del=$module". "$f", { MESSAGE => "$_DEL $file", CLASS => 'del rightAlignText' }) : '');
       }

      $table->addrow(@rows);
     }
   }
}

print $table->show();

my $table = $html->table( { width       => '600',
	                          caption     => $_OTHER,
                            title_plain => ["FILE", "$_SIZE (Byte)", "$_DATE", "$_DESCRIBE",  "-" ],
                            cols_align  => ['left', 'right', 'right', 'left', 'center', 'center']
                         } );

	if (-d "$conf{TPL_DIR}" ) {
    opendir DIR, "$conf{TPL_DIR}" or die "Can't open dir '$sys_templates/$module/templates' $!\n";
      my @contents = grep  !/^\.\.?$/ && !/\.tpl$/  , readdir DIR;
    closedir DIR;

    $table->{rowcolor}=undef;
    $table->{extra}=undef;

    foreach my $file (sort @contents) {
      next if (-d "$conf{TPL_DIR}/".$file);

      my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,
        $blksize,$blocks);

      ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,
         $blksize,$blocks)=stat("$conf{TPL_DIR}/$file");
        $mtime = strftime "%Y-%m-%d", localtime($mtime);

      $table->addrow("$file", $size, $mtime, $describe,
         $html->button($_DEL, "index=$index&file_del=$file", { MESSAGE => "$_DEL '$file'", CLASS => 'del' }));
     }

   }
 print $table->show();
 
 $html->tpl_show(templates('form_fileadd'), undef);
}



#**********************************************************
# Get teblate describe 
#**********************************************************
sub get_tpl_describe {
  my ($file) = @_;
  my %tpls_describe = ();

if (! -f  $file ) {
  return \%tpls_describe;
}

  my %tpls_describe = ();

	my $content = '';
	open(FILE, "$file") ;
	  while(<FILE>) {
	  	$content .= $_;
	   }
	close(FILE);

  my @arr = split(/\n/,  $content); 
	foreach my $line (@arr) {
		if ($line =~ /^#/) {
			next;
		 }
		my($tpl, $lang, $describe)=split(/:/, $line, 3);
		
		if ($lang eq $html->{language}) {
		  $tpls_describe{$tpl}=$describe;
		 }
	 }
	return \%tpls_describe;
}



#**********************************************************
#
#**********************************************************
sub show_tpl_info {
  my ($filename) = @_;

  $filename =~ s/\.tpl$//;
  my $table = $html->table( { width       => '600',
  	                          caption     => "$_INFO - '$filename'",
                              title_plain => ["$_NAME", "$_DESCRIBE", "$_PARAMS"],
                              cols_align  => ['left', 'left', 'left'],
                              ID          => 'TPL_INFO'
                           } );


  my $tpl_params = tpl_describe("$filename");
  foreach my $key (sort keys %$tpl_params) {
    $table->addrow('%'.$key.'%',
                   $tpl_params->{$key}->{DESCRIBE},
                   $tpl_params->{$key}->{PARAMS}
                   );  	
   }
  
  print $table->show();
  
 }
 
#**********************************************************
# Get template describe. Variables and other
# tpl describe file format
# TPL_VARIABLE:TPL_VARIABLE_DESCRIBE:DESCRIBE_LANG:PARAMS
#**********************************************************
sub tpl_describe {
	my ($tpl_name, $attr) = @_;
	my $filename   = $tpl_name.'.dsc';
	my $content    = '';
  my %TPL_DESCRIBE = ();

  if (! -f $filename) {
  	$html->message('info', "$_INFO", "$_INFO $_NOT_EXIST ($filename)");
  	return \%TPL_DESCRIBE;
   }

	open(FILE, "$filename") or die "Can't open file '$filename' $!\n";
	  while(<FILE>) {
	  	$content .= $_;
	   }
	open(FILE);

 	my @rows = split(/\n/, $content);
  
  foreach my $line (@rows) {
  	if ($line =~ /^#/) {
  		next;
  	 }
  	elsif($line =~ /^(\S+):(.+):(\S+):(\S{0,200})/) {
    	my $name    = $1;
    	my $describe= $2;
    	my $lang    = $3;
    	my $params  = $4;
    	next if ($attr->{LANG} && $attr->{LANG} ne $lang);
    	$TPL_DESCRIBE{$name}{DESCRIBE}=$describe;
    	$TPL_DESCRIBE{$name}{LANG}    =$lang;
    	$TPL_DESCRIBE{$name}{PARAMS}  =$params;
     }
   }

   return \%TPL_DESCRIBE;
}

#**********************************************************
# form_period
#**********************************************************
sub form_period  {
 my ($period, $attr) = @_;
 my @periods = ("$_NOW", "$_NEXT_PERIOD", "$_DATE");
 my $date_fld = $html->date_fld2('DATE', { FORM_NAME => 'user', MONTHES => \@MONTHES, WEEK_DAYS => \@WEEKDAYS, NEXT_DAY => 1 });
 my $form_period='';
 $form_period .= "<tr><td ". (($attr->{TD_EXDATA}) ? $attr->{TD_EXDATA} : '' ) .
  " rowspan=". ( ($attr->{ABON_DATE}) ? 3 : 2 ) .">$_DATE:</td><td>";

 $form_period .= $html->form_input('period', "0", { TYPE          => "radio", 
   	                                                STATE         => 1, 
   	                                                OUTPUT2RETURN => 1
 	                                                  }). "$periods[0]";

 $form_period .= "</td></tr>\n";

 for(my $i=1; $i<=$#periods; $i++) {
   my $period_name = $periods[$i];

   my $period = $html->form_input('period', "$i", { TYPE          => "radio", 
   	                                                STATE         => ($i eq $period) ? 1 : undef, 
   	                                                OUTPUT2RETURN => 1
   	                                                  });


   if ($i == 1) {
     next if (! $attr->{ABON_DATE});
     $period .= "$period_name  ($attr->{ABON_DATE})" ;
    }
   elsif($i == 2) {
     $period .= "$period_name $date_fld"   	
    }

   $form_period .= "<tr><td>$period</td></tr>\n";
 }

 return $form_period;	
}


#**********************************************************
#
# form_dictionary();
#**********************************************************
sub form_dictionary {
	my $sub_dict = $FORM{SUB_DICT} || '';

 ($sub_dict, undef) = split(/\./, $sub_dict, 2);
  if ($FORM{change}) {
  	my $out = '';
  	my $i=0;
  	while(my($k, $v)=each %FORM) {
  		 if ($k =~ /$sub_dict/ && $k ne '__BUFFER') {
  		    my ($pre, $key)=split(/_/, $k, 2);
 		      $key =~ s/\%40/\@/;
          if ($key =~ /@/) {
   		    	$v =~ s/\\'/'/g;
   		    	$v =~ s/\\"/"/g;
   		    	$v =~ s/\;$//g;
   		    	$out .= "$key=$v;\n"; 
  		     }
  		    else {
  		      $key =~ s/\%24/\$/;
  		      $v =~ s/'/\\'/;
  		    	$out .= "$key='$v';\n"; 
  		     }
  		    $i++;
  		  }
  		  
  	 }

    if (open(FILE, ">../../language/$sub_dict.pl" )) { 
      print FILE "$out";
	    close(FILE);
     	$html->message('info', $_CHANGED, "$_CHANGED '$FORM{SUB_DICT}'");
     }
    else {
    	$html->message('err', $_ERROR, "Can't open file '../../language/$sub_dict.pl' $!");
     }
   }


	my $table = $html->table({ width       => '600',
                             title_plain => ["$_NAME", "-"],
                             cols_align  => ['left', 'center']
                            });

#show dictionaries
 opendir DIR, "../../language/" or die "Can't open dir '../../language/' $!\n";
   my @contents = grep  !/^\.\.?$/  , readdir DIR;
 closedir DIR;

 if ($#contents > 0) {
   foreach my $file (@contents) {
    if (-f "../../language/". $file) {
        if ($sub_dict. ".pl" eq $file) {
          $table->{rowcolor}='row_active';
         }
        else {
    	    undef($table->{rowcolor});
         }
        $table->addrow("$file", $html->button($_CHANGE, "index=$index&SUB_DICT=$file", { CLASS => 'change' }));
      }
    }
  }
  
  print $table->show();

  #Open main dictionary	
  my %main_dictionary = ();

	open(FILE, "<../../language/english.pl") || print "Can't open file '../../language/english.pl' $!\n";
	  while(<FILE>) {
	  	 my($name, $value)=split(/=/, $_, 2);
       $name =~ s/ //ig;
       if ($_ =~ /^@/){
       	 $main_dictionary{"$name"}=$value;
        }
       elsif ($_ !~ /^#|^\n/){
         $main_dictionary{"$name"}=clearquotes($value, { EXTRA => "|\'|;" });
        }
	   }
	close(FILE);

  my %sub_dictionary = ();
  if ($sub_dict ne '') {
    #Open main dictionary	
	  open(FILE, "<../../language/". $sub_dict . ".pl" ) || print "Can't open file '../../language/$sub_dict.pl' $!\n";
  	  while(<FILE>) {
	    	 my($name, $value)=split(/=/, $_, 2);
         $name =~ s/ //ig;
	    	 if ($_ =~ /^@/){
       	   $sub_dictionary{"$name"}=$value;
          }
	    	 elsif ($_ !~ /^#|^\n/) {
           $sub_dictionary{"$name"}=clearquotes($value, { EXTRA => "|\'|;" }) 
          }
	     }
	  close(FILE);
   }

	$table = $html->table( { width       => '600',
                           title_plain => ["$_NAME", "$_VALUE", "-"],
                           cols_align  => ['left', 'left', 'center'],
                           ID          => 'FORM_DICTIONARY'
                        } );

  foreach my $k (sort keys %main_dictionary) {
  	 my $v = $main_dictionary{$k};
     my $v2 = '';
  	 if (defined($sub_dictionary{"$k"})) {
  	 	 $v2 = $sub_dictionary{"$k"}	;
       $table->{rowcolor}=undef;
  	  }
  	 else {
  	 	 $v2 = '--';
  	 	 $table->{rowcolor}='row_active';
  	  }
     
     $table->addrow(
        $html->form_input('NAME', "$k", { SIZE => 30 }), 
        $html->form_input("$k", "$v", { SIZE => 45 }), 
        $html->form_input($sub_dict ."_". $k, "$v2", { SIZE => 45 })
       ); 
   }

   $table->{rowcolor}='row_active';
   $table->addrow("$_TOTAL", "$i", ''); 

print $html->form_main({ CONTENT => $table->show({ OUTPUT2RETURN => 1 }),
	                       HIDDEN  => { index    => "$index",
                                      SUB_DICT => "$sub_dict"
                                     },
	                       SUBMIT  => { change   => "$_CHANGE"
	                       	           } });

}

#**********************************************************
# form_webserver_info()
#**********************************************************
sub form_webserver_info {
  my $web_error_log = $conf{WEB_SERVER_ERROR_LOG} || "/var/log/httpd/abills-error.log";

	my $table = $html->table( {
		                         caption     => 'WEB server info',
		                         width       => '600',
                             title_plain => ["$_NAME", "$_VALUE", "-"],
                             cols_align  => ['left', 'left', 'center'],
                             ID          => 'WEBSERVER_INFO'
                          } );

 foreach my $k (sort keys %ENV) {
    $table->addrow($k, $ENV{$k}, '');
  }
 print $table->show(); 

 $table = $html->table( {
		                         caption     => '/var/log/httpd/abills-error.log',
		                         width       => '100%',
                             title_plain => ["$_DATE", "$_ERROR", "CLIENT", "LOG"],
                             cols_align  => ['left', 'left', 'left', 'left'],
                             ID          => 'WEBSERVER_LOG'
                          } );

 if ( -f $web_error_log) {
   open(LOG_FILE, "/usr/bin/tail -100 $web_error_log |") or print $html->message('err', $_ERROR, "Can't open file $!"); 
     while(<LOG_FILE>) {
       if (/\[(.+)\] \[(\S+)\] \[client (.+)\] (.+)/) {
         $table->addrow($1, $2, $3, $4);
        }
       else {
       	 $table->addrow('', '', '', $_);
        }
      }
   close(LOG_FILE);

   print $table->show();
  }
}

#**********************************************************
# form config
# Show system config
#**********************************************************
sub form_config {

	my $table = $html->table( {caption     => 'config options',
		                         width       => '600',
                             title_plain => ["$_NAME", "$_VALUE", "-"],
                             cols_align  => ['left', 'left', 'center']
                          } );
  $table->addrow("Perl Version:", $], '');
  
  
  foreach my $k (sort keys %conf) {
     if ($k eq 'dbpasswd') {
      	$conf{$k}='*******';
      }
     $table->addrow($k, $conf{$k}, '');
   }

	print $table->show();
}

#**********************************************************
# sel_groups();
#**********************************************************
sub sel_groups {
  my $GROUPS_SEL = '';

  if ($admin->{GID} > 0 && ! $admin->{GIDS}) {
  	$users->group_info($admin->{GID});
  	$GROUPS_SEL = "$admin->{GID}:$users->{G_NAME}";
   }
  else {
    $GROUPS_SEL = $html->form_select('GID', 
                                { 
 	                                SELECTED          => $FORM{GID},
 	                                SEL_MULTI_ARRAY   => $users->groups_list({ GIDS => ($admin->{GIDS}) ? $admin->{GIDS} : undef }),
 	                                MULTI_ARRAY_KEY   => 0,
 	                                MULTI_ARRAY_VALUE => 1,
 	                                SEL_OPTIONS       => ($admin->{GIDS}) ?  undef : { '' => "$_ALL" },
 	                                MAIN_MENU         => get_function_index('form_groups'),
 	                               });
   }

  return $GROUPS_SEL;	
}


#**********************************************************
# Make SQL backup
#**********************************************************
sub form_sql_backup {
 my ($attr)=@_;

if ($FORM{mk_backup}) {
   $conf{dbcharset}='latin1' if (!$conf{dbcharset});
	 my $tables = '';
	 my $backup_file = "$conf{BACKUP_DIR}/abills-$DATE.sql.gz"; 
	 if ($attr->{TABLES}) {
	 	 my @tables_arr = split(/,/, $attr->{TABLES});
	 	 $tables = join(' ', @tables_arr);
	 	 if ($#tables_arr == 0) {
	 	 	 $backup_file = "$conf{BACKUP_DIR}/abills_$tables-$DATE.sql.gz"; 
	 	  }
	 	 else {
	 	 	 $backup_file = "$conf{BACKUP_DIR}/abills_tables-$DATE.sql.gz"; 
	 	  }
	  }
  
   my $cmd = qq{ $MYSQLDUMP --default-character-set=$conf{dbcharset} --host=$conf{dbhost} --user="$conf{dbuser}" --password="$conf{dbpasswd}" $conf{dbname} $tables | $GZIP > $backup_file };
   my $res = `$cmd`;
   $cmd =~ s/password=\"(.+)\" /password=\"\*\*\*\*\" /g;
   $html->message('info', $_INFO, "Backup created: $res ($backup_file)\n'$cmd'");
 }
elsif($FORM{del} && $FORM{is_js_confirmed}) {
  my $status = unlink("$conf{BACKUP_DIR}/$FORM{del}");
  $html->message('info', $_INFO, "$_DELETED : $conf{BACKUP_DIR}/$FORM{del} [$status]");
}

  my $table = $html->table( { width      => '600',
                              caption    => "$_SQL_BACKUP",
                              border     => 1,
                              title      => ["$_NAME", $_DATE, $_SIZE, '-'],
                              cols_align => ['left', 'right', 'right', 'center'],
                              ID         => 'SQL_BACKUP_LIST'
                          } );


  opendir DIR, $conf{BACKUP_DIR} or $html->message('err', $_ERROR, "Can't open dir '$conf{BACKUP_DIR}' $!\n");
    my @contents = grep  !/^\.\.?$/  , readdir DIR;
  closedir DIR;

  use POSIX qw(strftime);
  foreach my $filename (@contents) {
    my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks)=stat("$conf{BACKUP_DIR}/$filename");
    my $date = strftime "%Y-%m-%d %H:%M:%S", localtime($mtime);
    $table->addrow($filename,  $date, $size, $html->button($_DEL, "index=$index&del=$filename", { MESSAGE => "$_DEL $filename?",  CLASS => 'del' })
    );
   }

 print  $table->show();
 print  $html->button($_CREATE, "index=$index&mk_backup=1", { BUTTON => 1 });
}


#**********************************************************
#
#**********************************************************
sub form_bruteforce {
if(defined($FORM{del}) && $FORM{is_js_confirmed} && $permissions{0}{5} ) {
   $users->bruteforce_del({ LOGIN => $FORM{del} });
   $html->message('info', $_INFO, "$_DELETED # $FORM{del}");
 }
	
	$LIST_PARAMS{LOGIN} = $FORM{LOGIN} if ($FORM{LOGIN});
	
  my $list = $users->bruteforce_list( { %LIST_PARAMS } );
  my $table = $html->table( { width      => '100%',
                              caption    => "$_BRUTE_ATACK",
                              border     => 1,
                              title      => [$_LOGIN, $_PASSWD, $_DATE, $_COUNT, 'IP', '-', '-'],
                              cols_align => ['left', 'left', 'right', 'right', 'center', 'center'],
                              pages      => $users->{TOTAL},
                              qs         => $pages_qs,
                              ID         => 'FORM_BRUTEFORCE'
                           } );

  foreach my $line (@$list) {
    $table->addrow($line->[0],  
      $line->[1], 
      $line->[2], 
      $line->[3], 
      $line->[4], 
      $html->button($_INFO, "index=$index&LOGIN=$line->[0]", { CLASS => 'show' }), 
      (defined($permissions{0}{5})) ? $html->button($_DEL, "index=$index&del=$line->[0]", { MESSAGE => "$_DEL $line->[0]?", CLASS => 'del' }) : ''
      );
   }
  print $table->show();

  $table = $html->table( { width      => '100%',
                           cols_align => ['right', 'right'],
                           rows       => [ [ "$_TOTAL:", $html->b($users->{TOTAL}) ] ]
                        } );
  print $table->show();

}

#**********************************************************
# Tarif plans groups
# form_tp
#**********************************************************
sub form_tp_groups {

 use Tariffs;
 my $Tariffs = Tariffs->new($db, \%conf, $admin);

 $Tarrifs = $Tariffs->tp_group_defaults();
 $Tariffs->{LNG_ACTION}=$_ADD;
 $Tariffs->{ACTION}='ADD';

if($FORM{ADD}) {
  $Tariffs->tp_group_add({ %FORM });
  if (! $Tariffs->{errno}) {
    $html->message('info', $_ADDED, "$_ADDED GID: $Tariffs->{GID}");
   }
 }
elsif($FORM{change}) {
  $Tariffs->tp_group_change({	%FORM  });
  if (! $Tariffs->{errno}) {
    $html->message('info', $_CHANGED, "$_CHANGED ");	
   }
 }
elsif($FORM{chg}) {
  $Tariffs->tp_group_info($FORM{chg});
  if (! $Tariffs->{errno}) {
    $html->message('info', $_CHANGED, "$_CHANGED ");	
   }

  $Tariffs->{ACTION}='change';
  $Tariffs->{LNG_ACTION}=$_CHANGE;
 }
elsif(defined($FORM{del}) && $FORM{is_js_confirmed}) {
  $Tariffs->tp_group_del($FORM{del});
  if (! $Tariffs->{errno}) {
    $html->message('info', $_DELETE, "$_DELETED $FORM{del}");
   }
}


if ($Tariffs->{errno}) {
    $html->message('err', $_ERROR, "[$Tariffs->{errno}] $err_strs{$Tariffs->{errno}}");	
 }

$Tariffs->{USER_CHG_TP} = ($Tarrifs->{USER_CHG_TP}) ? 'checked' : '';
$html->tpl_show(templates('form_tp_group'), $Tarrifs);


my $list = $Tariffs->tp_group_list({ %LIST_PARAMS });	

# Time tariff Name Begin END Day fee Month fee Simultaneously - - - 
my $table = $html->table( { width      => '100%',
                            caption    => "$_GROUPS",
                            border     => 1,
                            title      => ['#', $_NAME, $_USER_CHG_TP, $_COUNT, '-', '-' ],
                            cols_align => ['right', 'left', 'center', 'right', 'center:noprint', 'center:noprint' ],
                           } );

my ($delete, $change);
foreach my $line (@$list) {
  if ($permissions{4}{1}) {
    $delete = $html->button($_DEL, "index=$index&del=$line->[0]", { MESSAGE => "$_DEL $line->[0]?", CLASS => 'del' }); 
    $change = $html->button($_CHANGE, "index=$index&chg=$line->[0]", { CLASS => 'change' });
   }
  
  if($FORM{TP_ID} eq $line->[0]) {
  	$table->{rowcolor}='row_active';
   }
  else {
  	undef($table->{rowcolor});
   }
  
  $table->addrow("$line->[0]", 
   $line->[1],
   $bool_vals[$line->[2]], 
   $line->[3],
   $change,
   $delete);
}

print $table->show();

$table = $html->table( { width      => '100%',
                         cols_align => ['right', 'right'],
                         rows       => [ [ "$_TOTAL:", $html->b($Tariffs->{TOTAL}) ] ]
                               } );
print $table->show();
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
# Information fields
#**********************************************************
sub form_info_fields {
	if ($FORM{USERS_ADD}) {
		if (length($FORM{FIELD_ID}) > 15) {
			$html->message('err', $_ERROR, "$ERR_WRONG_DATA");
		 }
		else {
		  $users->info_field_add({ %FORM  });
		  if (! $users->{errno}) {
			  $html->message('info', $_INFO, "$_ADDED: $FORM{FIELD_ID} - $FORM{NAME}");
		   }
     }
	 }
	elsif ($FORM{COMPANY_ADD}) {
		$users->info_field_add({ %FORM  });
		if (! $users->{errno}) {
			$html->message('info', $_INFO, "$_ADDED: $FORM{FIELD_ID} - $FORM{NAME}");
		 }
	 }
	elsif ($FORM{del} && $FORM{is_js_confirmed}) {
		$users->info_field_del({ SECTION => $FORM{del}, %FORM });
		if (! $users->{errno}) {
			$html->message('info', $_INFO, "$_DELETED: $FORM{FIELD_ID}");
		 }
	 }

  if ($users->{errno}) {
    $html->message('err', $_ERROR, "[$users->{errno}] $err_strs{$users->{errno}}");
   }


  my @fields_types = ('String', 'Integer', $_LIST, $_TEXT, 'Flag', 'Blob', 'PCRE', 'AUTOINCREMENT', 'ICQ', 'URL', 'PHONE', 'E-Mail', 'Skype', "$_FILE");

  my $fields_type_sel = $html->form_select('FIELD_TYPE', 
                                { SELECTED   => $FORM{field_type},
 	                                SEL_ARRAY  => \@fields_types, 
 	                                NO_ID      => 1,
 	                                ARRAY_NUM_ID => 1
 	                               });


	my $list = $users->config_list({ PARAM => 'ifu*', SORT => 2});
	
  my $table = $html->table( { width      => '500',
                              caption    => "$_INFO_FIELDS - $_USERS",
                              border     => 1,
                              title      => [$_NAME, 'SQL field', $_TYPE, $_PRIORITY, "$_USER_PORTAL", '-'],
                              cols_align => ['left', 'left', 'left', 'right', 'left', 'center', 'center' ],
                              ID         => 'INFO_FIELDS'
                           } );


  foreach my $line (@$list) {
    my $field_name       = '';

    if ($line->[0] =~ /ifu(\S+)/) {
    	$field_name = $1;
     }

    my($position, $field_type, $name, $user_portal)=split(/:/, $line->[1]);

    $table->addrow($name,  
      $field_name, 
      ($field_type == 2) ? $html->button($fields_types[$field_type], "index=". ($index + 1) ."&LIST_TABLE=$field_name".'_list') : $fields_types[$field_type],  
      $position,
      $bool_vals[$user_portal],
      (defined($permissions{4}{3})) ? $html->button($_DEL, "index=$index&del=ifu&FIELD_ID=$field_name", { MESSAGE => "$_DEL $field_name?", CLASS => 'del' }) : ''      
      );
   }

  $table->addrow($html->form_input('NAME', ''),  
      $html->form_input('FIELD_ID', '', { SIZE => 12 }),  
      $fields_type_sel, 
      $html->form_input('POSITION', 0, { SIZE => 10 }),  
      $html->form_input('USERS_PORTAL', 1, {  TYPE => 'CHECKBOX' }),
      $html->form_input('USERS_ADD', $_ADD, {  TYPE => 'SUBMIT' }),
      
      );


   print $html->form_main({ CONTENT => $table->show(),
	                          HIDDEN  => { index => $index,
	                       	              },
	                       	  NAME    => 'users_fields'
                         });


  $list = $users->config_list({ PARAM => 'ifc*', SORT => 2 });
  $table = $html->table( { width      => '500',
                           caption    => "$_INFO_FIELDS - $_COMPANIES",
                           border     => 1,
                           title      => [$_NAME, 'SQL field', $_TYPE, $_PRIORITY, "$_USER_PORTAL", '-'],
                           cols_align => ['left', 'left', 'left', 'right', 'left', 'center', 'center' ],
                           } );


  foreach my $line (@$list) {
    my $field_name       = '';

    if ($line->[0] =~ /ifc(\S+)/) {
    	$field_name = $1;
     }

    my($position, $field_type, $name, $user_portal)=split(/:/, $line->[1]);

    $table->addrow($name,  
      $field_name, 
      ($field_type == 2) ? $html->button($fields_types[$field_type], "index=". ($index + 1) ."&LIST_TABLE=$field_name".'_list') : $fields_types[$field_type], 
      $position,
      $bool_vals[$user_portal],
      (defined($permissions{4}{3})) ? $html->button($_DEL, "index=$index&del=ifc&FIELD_ID=$field_name", { MESSAGE => "$_DEL $field_name ?", CLASS => 'del' }) : '',
      
      );
   }

  $table->addrow($html->form_input('NAME', ''),  
      $html->form_input('FIELD_ID', '', { SIZE => 12 }),  
      $fields_type_sel, 
      $html->form_input('POSITION', 0, { SIZE=> 10 }),  
      $html->form_input('USERS_PORTAL', 1, {  TYPE => 'CHECKBOX' }),
      $html->form_input('COMPANY_ADD', $_ADD, {  TYPE => 'SUBMIT' })
      );


   print $html->form_main({ CONTENT => $table->show(),
	                          HIDDEN  => { index => $index,
	                       	              },
	                       	  NAME    => 'company_fields'
                         });
}


#**********************************************************
# Information lists
#**********************************************************
sub form_info_lists {

  @ACTIONS = ('add', $_ADD);
  
	if ($FORM{add}) {
		$users->info_list_add({ %FORM  });
		if (! $users->{errno}) {
			$html->message('info', $_INFO, "$_ADDED: $FORM{FIELD_ID} - $FORM{NAME}");
		 }
	 }
	elsif ($FORM{change}) {
		$users->info_list_change($FORM{chg}, { ID => $FORM{chg}, %FORM  });
		if (! $users->{errno}) {
			$html->message('info', $_INFO, "$_CHANGED: $FORM{ID}");
		 }
	 }
	elsif ($FORM{chg}) {
		$users->info_list_info($FORM{chg},  {  %FORM  });
		if (! $users->{errno}) {
			$html->message('info', $_INFO, "$_CHANGE: $FORM{chg}");
			@ACTIONS = ('change', $_CHANGE);
		 }
	 }
	elsif ($FORM{del} && $FORM{is_js_confirmed}) {
		$users->info_list_del({ ID => $FORM{del}, %FORM });
		if (! $users->{errno}) {
			$html->message('info', $_INFO, "$_DELETED: $FORM{FIELD_ID}");
		 }
	 }

  if ($users->{errno}) {
    $html->message('err', $_ERROR, "[$users->{errno}] $err_strs{$users->{errno}}");
   }
	
  my $list = $users->config_list({ PARAM => 'if*',
  	                               VALUE => '2:*'});

  my %lists_hash = ();

  foreach my $line (@$list) {
    my $field_name       = '';

    if ($line->[0] =~ /if[u|c](\S+)/) {
    	$field_name = $1;
     }

    my($position, $field_type, $name)=split(/:/, $line->[1]);
    $lists_hash{$field_name.'_list'}=$name;
   }



  my $lists_sel = $html->form_select('LIST_TABLE', 
                                { SELECTED   => $FORM{LIST_TABLE},
 	                                SEL_HASH   => \%lists_hash, 
 	                                NO_ID      => 1,
 	                               });

  my $table = $html->table( { width      => '100%',
  	                        rows       => [[ $lists_sel, $html->form_input('SHOW', $_SHOW, {TYPE => 'submit' }) ]]
  	                       });


  print $html->form_main({ CONTENT => $table->show(),
	                         HIDDEN  => { index  => $index,
 	                       	              },
	                       	 NAME    => 'tables_list'
                         });


	if ($FORM{LIST_TABLE}) {
     my $table = $html->table( { width      => '450',
                           caption    => "$_LIST",
                           border     => 1,
                           title      => ['#', $_NAME, '-', '-'],
                           cols_align => ['right', 'left', 'center', 'center' ],
                           ID         => 'LIST'
                           } );

     $list = $users->info_lists_list({ %FORM }); 

     foreach my $line (@$list) {
       $table->addrow($line->[0],  
         $line->[1],
         $html->button($_CHANGE, "index=$index&LIST_TABLE=$FORM{LIST_TABLE}&chg=$line->[0]", { CLASS => 'change' }), 
         (defined($permissions{0}{5})) ? $html->button($_DEL, "index=$index&LIST_TABLE=$FORM{LIST_TABLE}&del=$line->[0]", { MESSAGE => "$_DEL $line->[0] / $line->[1]?", CLASS => 'del' }) : ''
        );
      }

     $table->addrow($users->{ID},  
        $html->form_input('NAME', "$users->{NAME}", { SIZE => 80 }),  
        $html->form_input("$ACTIONS[0]", "$ACTIONS[1]", {  TYPE => 'SUBMIT' })
      );


     print $html->form_main({ CONTENT => $table->show(),
	                          HIDDEN  => { index      => $index,
	                          	           chg        => $FORM{chg},
	                          	           LIST_TABLE => $FORM{LIST_TABLE}
	                       	              },
	                       	  NAME    => 'list_add'
                         });
 }
}


#**********************************************************
#
#**********************************************************
sub form_districts {
 $users->{ACTION}='add';
 $users->{LNG_ACTION}="$_ADD";

if ($FORM{add}) {
	$users->district_add({ %FORM });

  if (! $users->{errno}) {
    if ($FORM{FILE_UPLOAD}) {
    	my $name = '';
    	if ($FORM{FILE_UPLOAD}{filename} =~ /\.(\S+)$/i) {
    		$name = $users->{INSERT_ID}.'.'.lc($1);
    	 }
    	upload_file($FORM{FILE_UPLOAD}, { PREFIX => 'maps', FILE_NAME => $name, REWRITE => 1 });
     }

    $html->message('info', $_DISTRICT, "$_ADDED");
   }
}
elsif($FORM{change}) {
	$users->district_change("$FORM{ID}", { %FORM });

  if (! $users->{errno}) {
    $html->message('info', $_DISTRICTS, "$_CHANGED");
    if ($FORM{FILE_UPLOAD}) {
    	my $name = '';
    	if ($FORM{FILE_UPLOAD}{filename} =~ /\.([a-z0-9]+)$/i) {
    		$name = $FORM{ID} .'.'.lc($1);
    	 }

    	upload_file($FORM{FILE_UPLOAD}, { PREFIX => 'maps', FILE_NAME => $name, REWRITE => 1 });
     }
   }
}
elsif($FORM{chg}) {
	$users->district_info({ ID => $FORM{chg} });

  if (! $users->{errno}) {
    $users->{ACTION}='change';
    $users->{LNG_ACTION}="$_CHANGE";
    $html->message('info', $_DISTRICTS, "$_CHANGING");
   }
}
elsif($FORM{del} && $FORM{is_js_confirmed}) {
	$users->district_del($FORM{del});

  if (! $users->{errno}) {
    $html->message('info', $_DISTRICTS, "$_DELETED");
   }
}

if ($users->{errno}) {
  if ($users->{errno} == 7) {
  	$html->message('err', $_ERROR, "$_EXIST");	
   }
  else {
    $html->message('err', $_ERROR, "[$users->{errno}] $err_strs{$users->{errno}}");	
   }
 }


my $countries = $html->tpl_show(templates('countries'), undef, { OUTPUT2RETURN => 1 });
my @countries_arr  = split(/\n/, $countries);
my %countries_hash = ();
foreach my $c (@countries_arr) {
  my ($id, $name)=split(/:/, $c);
  $countries_hash{int($id)}=$name;
 }

$users->{COUNTRY_SEL} = $html->form_select('COUNTRY', 
                                { SELECTED   => $users->{COUNTRY} || $FORM{COUNTRY},
 	                                SEL_HASH   => { '' => '', %countries_hash },
 	                                NO_ID      => 1
 	                               });

$html->tpl_show(templates('form_district'), $users);

my $table = $html->table({ width      => '100%',
	                         caption    => $_DISTRICTS,
                           title      => ["#", "$_NAME", "$_COUNTRY", "$_CITY", "$_ZIP", "$_STREETS", "$_MAP", '-', '-'],
                           cols_align => ['right', 'left', 'left', 'left', 'left', 'right', 'right', 'center', 'center'],
                           ID         => 'DISTRICTS_LIST'
                          });

my $list = $users->district_list({ %LIST_PARAMS });
foreach my $line (@$list) {
  my $map = '';
  
  if (-f $conf{TPL_DIR}.'/maps/'.$line->[0].'.gif' || -f $conf{TPL_DIR}.'/maps/'.$line->[0].'.jpg' || -f $conf{TPL_DIR}.'/maps/'.$line->[0].'.png') {
  	 if (in_array('Maps', \@MODULES)) {
  	 	 $map = $html->button($bool_vals[1], "DISTRICT_ID=$line->[0]&index=". get_function_index('maps_main'), { BUTTON => 1 });
  	 	} 
     else {
       $map = $html->button($bool_vals[1], '#', { NEW_WINDOW => "index.cgi?MODULE=Maps&qindex=-1", NEW_WINDOW_SIZE => "670:340", BUTTON => 1 });
      }
   } 
  else {
  	$map = $bool_vals[0];
   }

  
  
  $table->addrow($line->[0], 
     $line->[1], 
     $country_hash{$line->[2]}, 
     $line->[3], 
     $line->[4],
     $html->button($line->[5], "index=". ($index+1). "&DISTRICT_ID=$line->[0]" ), 
     $map,
     $html->button($_CHANGE, "index=$index&chg=$line->[0]", { CLASS => 'change' }), 
     $html->button($_DEL, "index=$index&del=$line->[0]", { MESSAGE => "$_DEL [$line->[0]]?", CLASS => 'del' } ));
}

print $table->show();	
}



#**********************************************************
#
#**********************************************************
sub form_streets {
 $users->{ACTION}='add';
 $users->{LNG_ACTION}="$_ADD";


if ($FORM{BUILDS}) {
	form_builds();
	
	return 0;
 }
elsif ($FORM{add}) {
	$users->street_add({ %FORM });

  if (! $users->{errno}) {
    $html->message('info', $_ADDRESS_STREET, "$_ADDED");
   }
}
elsif($FORM{change}) {
	$users->street_change("$FORM{ID}", { %FORM });

  if (! $users->{errno}) {
    $html->message('info', $_ADDRESS_STREET, "$_CHANGED");
   }
}
elsif($FORM{chg}) {
	$users->street_info({ ID => $FORM{chg} });

  if (! $users->{errno}) {
    $users->{ACTION}='change';
    $users->{LNG_ACTION}="$_CHANGE";
    $html->message('info', $_ADDRESS_STREET, "$_CHANGING");
   }
}
elsif($FORM{del} && $FORM{is_js_confirmed}) {
	$users->street_del($FORM{del});

  if (! $users->{errno}) {
    $html->message('info', $_ADDRESS_STREET, "$_DELETED");
   }
}

if ($users->{errno}) {
  if ($users->{errno} == 7) {
  	$html->message('err', $_ERROR, "$_EXIST");	
   }
  else {
    $html->message('err', $_ERROR, "[$users->{errno}] $err_strs{$users->{errno}}");	
   }
 }


$users->{DISTRICTS_SEL} = $html->form_select("DISTRICT_ID", 
                                { SELECTED          => $users->{DISTRICT_ID} || $FORM{DISTRICT_ID},
 	                                SEL_MULTI_ARRAY   => $users->district_list({ PAGE_ROWS => 1000 }), 
 	                                MULTI_ARRAY_KEY   => 0,
 	                                MULTI_ARRAY_VALUE => 1,
 	                                SEL_OPTIONS       => { 0 => '-N/S-'},
 	                                NO_ID             => 1
 	                               });

#$html->tpl_show(templates('form_street_search'), $users);

if ($FORM{DISTRICT_ID}) {
  $LIST_PARAMS{DISTRICT_ID}=$FORM{DISTRICT_ID};
  $pages_qs.="&DISTRICT_ID=$LIST_PARAMS{DISTRICT_ID}";
 }

if (! $FORM{sort}) {
  $LIST_PARAMS{SORT}=2;
}

my $list = $users->street_list({ %LIST_PARAMS, USERS_INFO => 1 });
my $table = $html->table({ width      => '640',
	                         caption    => $_STREETS,
                           title      => [ "#", "$_NAME", "$_DISTRICTS", $_BUILDS, $_USERS, '-', '-' ],
                           cols_align => ['right', 'left', 'left', 'right', 'center', 'center', 'center'],
                           pages      => $users->{TOTAL},                           
                           qs         => $pages_qs,
                           ID         => 'STREET_LIST'
                          });

foreach my $line (@$list) {
  $table->addrow($line->[0], 
     $line->[1], 
     $line->[2], 
     $html->button($line->[3], "index=$index&BUILDS=$line->[0]"), 
     $html->button($line->[4], "&search=1&index=". get_function_index('form_search') ."&STREET_ID=$line->[0]" ), 
     $html->button($_CHANGE, "index=$index&chg=$line->[0]", { CLASS => 'change' }), 
     $html->button($_DEL, "index=$index&del=$line->[0]", { MESSAGE => "$_DEL [$line->[0]]?", CLASS => 'del' } ));
}
print $table->show();	


$table = $html->table( { width      => '640',
                         cols_align => ['right', 'right'],
                         rows       => [ [ "$_TOTAL:", "$_STREETS: ". $html->b($users->{TOTAL}), 
                                                       "$_BUILDS: ". $html->b($users->{TOTAL_BUILDS}),
                                                       "$_USERS: ".$html->b($users->{TOTAL_USERS}),
                                                       "$_DENSITY_OF_CONNECTIONS: " .  $html->b($users->{DENSITY_OF_CONNECTIONS})
                                        ] ]
                     } );
print $table->show();


$html->tpl_show(templates('form_street'), $users);
}


#**********************************************************
#
#**********************************************************
sub form_builds {
 $users->{ACTION}='add';
 $users->{LNG_ACTION}="$_ADD";


if ($FORM{add}) {
	$users->build_add({ %FORM });

  if (! $users->{errno}) {
    $html->message('info', $_ADDRESS_BUILD, "$_ADDED");
   }
}
elsif($FORM{change}) {
	$users->build_change("$FORM{ID}", { %FORM });

  if (! $users->{errno}) {
    $html->message('info', $_ADDRESS_BUILD, "$_CHANGED");
   }
}
elsif($FORM{chg}) {
	$users->build_info({ ID => $FORM{chg} });

  if (! $users->{errno}) {
    $users->{ACTION}='change';
    $users->{LNG_ACTION}="$_CHANGE";
    $html->message('info', $_ADDRESS_BUILD, "$_CHANGING");
   }
}
elsif($FORM{del} && $FORM{is_js_confirmed}) {
	$users->build_del($FORM{del});

  if (! $users->{errno}) {
    $html->message('info', $_ADDRESS_BUILD, "$_DELETED");
   }
}

if ($users->{errno}) {
  if ($users->{errno} == 7) {
  	$html->message('err', $_ERROR, "$_EXIST");	
   }
  else {
    $html->message('err', $_ERROR, "[$users->{errno}] $err_strs{$users->{errno}}");	
   }
 }


$users->{STREET_SEL} = $html->form_select("STREET_ID", 
                                { SELECTED          => $users->{STREET_ID} || $FORM{BUILDS},
 	                                SEL_MULTI_ARRAY   => $users->street_list({ PAGE_ROWS => 10000 }), 
 	                                MULTI_ARRAY_KEY   => 0,
 	                                MULTI_ARRAY_VALUE => 1,
 	                                SEL_OPTIONS       => { 0 => '-N/S-'},
 	                                NO_ID             => 1
 	                               });

$html->tpl_show(templates('form_build'), $users);

$LIST_PARAMS{DISTRICT_ID}=$FORM{DISTRICT_ID} if ($FORM{DISTRICT_ID});
$pages_qs .= "&BUILDS=$FORM{BUILDS}" if ($FORM{BUILDS});


my $list = $users->build_list({ %LIST_PARAMS, STREET_ID => $FORM{BUILDS}, CONNECTIONS => 1 });

my $table = $html->table({ width      => '100%',
	                         caption    => $_BUILDS,
                           title      => ["$_NUM", "$_FLORS", "$_ENTRANCES", "$_FLATS", "$_STREETS", "$_CENNECTED $_USERS", "$_DENSITY_OF_CONNECTIONS", "$_ADDED",   '-', '-'],
                           cols_align => ['right', 'left', 'left', 'right', 'center', 'center'],
                           pages      => $users->{TOTAL},                           
                           qs         => $pages_qs,
                           ID         => 'STREET_LIST'
                          });


foreach my $line (@$list) {
  $table->addrow($line->[0], 
     $line->[1], 
     $line->[2], 
     $line->[3], 
     $line->[4], 
     $html->button($line->[5], "&search=1&index=". get_function_index('form_search') ."&LOCATION_ID=$line->[8]" ),  
     $line->[6].' %',
     $line->[7],
     $html->button($_CHANGE, "index=$index&chg=$line->[8]&BUILDS=$FORM{BUILDS}", { CLASS => 'change' }), 
     $html->button($_DEL, "index=$index&del=$line->[8]&BUILDS=$FORM{BUILDS}", { MESSAGE => "$_DEL [$line->[0]]?", CLASS => 'del' } ));
}
print $table->show();	
$table = $html->table( { width      => '640',
                         cols_align => ['right', 'right'],
                         rows       => [ [ "$_TOTAL:", $html->b($users->{TOTAL}) ] ]
                       } );
print $table->show();

}


#**********************************************************
# Calls function for all registration modules if function exist 
#
# HASH_REF = cross_modules_call(function_sufix, attr) 
#
# return HASH_REF
#   MODULE -> return
#**********************************************************
sub cross_modules_call {
  my ($function_sufix, $attr) = @_;

  my %full_return = ();
  my @skip_modules = ();
  
  if ($attr->{SKIP_MODULES}) {
  	$attr->{SKIP_MODULES}=~s/\s+//g;
  	@skip_modules=split(/,/, $attr->{SKIP_MODULES});
   }


  foreach my $mod (@MODULES) {
    load_module("$mod", $html);

  	if (in_array($mod, \@skip_modules)) {
  		next;
  	 }

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

  #while(my($k, $v)=each %functions) {
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
sub form_purchase_module  {
  my ($attr) = @_;

  print "<p>модуль '$attr->{MODULE}' не установлен в системе, по вопросам приобретения модуля обратитесь к разработчику
  <a href='http://abills.net.ua' target=_newa>ABillS.net.ua</a> 
  
  <p>
  Purchase this module '$attr->{MODULE}'. 
  <p>
  For more information visit <a href='http://abills.net.ua' target=_newa>ABillS.net.ua</a>";

  return 0;
}

#**********************************************************
# Get function index
#
# form_view($attr) 
#  VIEW = HASH_REF
#**********************************************************
sub form_view  {
  my ($attr) = @_;

  my %info = ();
  $info{VIEW_SEL} = $html->form_select('VIEW', 
                                { SELECTED   => $FORM{VIEW} || 0,
 	                                SEL_HASH   => $attr->{VIEW},
 	                                NO_ID      => 1,
 	                               });

  $info{EX_PARAMS} = '';

  return $html->tpl_show(templates('form_view'), \%info, { OUTPUT2RETURN => 1 });
}

#**********************************************************
#
#**********************************************************
sub upload_file {
  my ($file, $attr)= @_;
	

  my $safe_filename_characters = ($attr->{SAFE_FILENAME_CHARACTERS}) ? $attr->{SAFE_FILENAME_CHARACTERS} : "a-zA-Z0-9_.-"; 
  my $file_name                = ($attr->{FILE_NAME}) ? $attr->{FILE_NAME} : $file->{filename};

  $file_name =~ tr/ /_/;
  $file_name =~ s/[^$safe_filename_characters]//g; 

  my $dir = ($attr->{PREFIX}) ? "$conf{TPL_DIR}/".$attr->{PREFIX} : $conf{TPL_DIR};

  if (! -d $dir) {
  	mkdir($dir);
   }
  
  if (! $attr->{REWRITE} && -f "$dir/$file_name") {
    $html->message('err', $_ERROR, "$_EXIST '$file_name'");
   }
  elsif( open(FILE, ">$dir/$file_name") ) { ;
      binmode FILE;
     	print FILE $file->{Contents};
    close(FILE);
    $html->message('info', $_INFO, "$_ADDED: '$file_name' $_SIZE: $file->{Size}");
   }
  else {
  	$html->message('err', $_ERROR, "$_ERROR  '$!'");
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

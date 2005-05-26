#!/usr/bin/perl

#use vars qw($begin_time);
BEGIN {
 $sql_type='mysql';
 unshift(@INC, "Abills/$sql_type/");

 eval { require Time::HiRes; };
 if (! $@) {
    Time::HiRes->import(qw(gettimeofday));
    $begin_time = gettimeofday();
   }
 else {
    $begin_time = 0;
  }
}



#==== config options
#DB settings
$conf{dbtype}='mysql';
$conf{dbhost}='localhost';
$conf{dbname}='abills';
$conf{dbuser}='asm';
$conf{dbpasswd}='test1r';

#
$conf{netsfilespath}='nets';
$conf{secretkey}="test12345678901234567890";
$conf{passwd_length}=6;
$conf{username_length}=15;
$conf{list_max_recs}=25;
$conf{default_language}='english';
$conf{default_charset}='windows-1251';

use POSIX qw(strftime);
my $DATE = strftime "%Y-%m-%d", localtime(time);
my $TIME = strftime "%H:%M:%S", localtime(time);


my $domain = '';
my $web_path = '';
my $secure = '';
# Autheization options
my @auth_types = ('SQL', 'System');

my %err_strs = (
  1 => $_ERROR,
  2 => ERROR_NOT_EXIST,
  3 => ERROR_SQL,
  4 => ERROR_WRONG_PASSWORD,
  5 => ERROR_WRONG_CONFIRM,     
  6 => ERROR_SHORT_PASSWORD,
  7 => ERROR_DUBLICATE,
  8 => ERROR_ENTER_NAME,
  9 => ERROR_LONG_USERNAME,
  10 => ERROR_WRONG_NAME,
  11 => ERROR_WRONG_EMAIL,
  12 => ERROR_ENTER_SUM,
  13 => PERMISIION_DENIED
);


%LANG = ('english' => 'English',
    'russian' => 'Русский',
    'russian-koi8-r' => 'Russian KOI8-r',
    'ukraine' => 'Українська',
    'bulgarian' => 'Болгарска');

my $lang_charset='windows-1251';

#==== End config


















#use FindBin '$Bin2';
use Abills::SQL;
use Abills::HTML;
use Nas;
use Admins;

my $html = Abills::HTML->new();
my $sql = Abills::SQL->connect($conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd});
my $db = $sql->{db};
my $admin = Admins->new($db);
require "../../language/$html->{language}.pl";
my %permissions = ();

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
#print "Content-type: test/html\n\n";
if (defined($ENV{HTTP_CGI_AUTHORIZATION})) {
  use Abills::Base;
  $ENV{HTTP_CGI_AUTHORIZATION} =~ s/basic\s+//i;
  my ($REMOTE_USER,$REMOTE_PASSWD) = split(/:/, decode_base64($ENV{HTTP_CGI_AUTHORIZATION}));  

  if (check_permissions("$REMOTE_USER", "$REMOTE_PASSWD") == 1) {
    print "WWW-Authenticate: Basic realm=\"Billing system\"\n";
    print "Status: 401 Unauthorized\n";
   }
}
else {
  check_permissions('asm', 'test1r');
}

if ($admin->{errno}) {
  print "Content-type: test/html\n\n";
  message('err', $_ERROR, "Access Deny"); #$err_strs{$admin->{errno}}");
  exit;
}


if (defined($FORM{colors})) {
  my $cook_colors = (defined($FORM{default})) ?  '' : $FORM{colors};
  $html->setCookie('colors', '$cook_colors', "Fri, 1-Jan-2038 00:00:01", $web_path, $domain, $secure);
 }
#$html->setCookie('language', '$FORM{language}', "Fri, 1-Jan-2038 00:00:01", $web_path, $domain, $secure) if (defined($FORM{language}));
#$html->setCookie('opid', "$FORM{opid}", "Fri, 1-Jan-2038 00:00:01", $web_path, $domain, $secure);
print $html->header();

my @actions = ([$_SA_ONLY, $_ADD, $_LIST, $_PASSWD, $_CHANGE, $_DEL, $_ALL],  # Users
               [$_LIST, $_ADD, $_DEL, $_ALL],                # Payments
               [$_LIST, $_ADD, $_DEL, $_ALL],                                 # Fees
               [$_ALL],                                                       # reports view
               [$_ALL],                                                       # system magment
               [$_ALL]                                                        # Modules managments
               );

my %LIST_PARAMS = ( SORT => $SORT,
	       DESC => $DESC,
	       PG => $PG,
	       PAGE_ROWS => $PAGE_ROWS,
	      );

my @action = ('add', $_ADD);
my @PAYMENT_METHODS = ('Cashe', 'Bank', 'Credit Card', 'Internet Card');

my %op_names = ();
my %menu_items = ();
my %functions = ();
my %sub_show = ();

my $index = $FORM{index} || 0;
my $root_index = 0;
my $pages_qs = '';
my ($main_menu, $sub_menu, $navigat_menu) = mk_navigator();
my ($online_users, $online_count) = $admin->online();
my %SEARCH_TYPES = (11 => $_USERS,
                    2 => $_PAYMENTS,
                    3 => $_FEES,
                    41 => $_LAST_LOGIN,
                    13 => $_COMPANY
);

$FORM{type}=11 if (! defined $FORM{type});

my $SEL_TYPE = "<select name=type>\n";
while(my($k, $v)=each %SEARCH_TYPES) {
	$SEL_TYPE .= "<option value=$k";
	$SEL_TYPE .= ' selected' if ($FORM{type} eq $k);
	$SEL_TYPE .= ">$v\n";
}
$SEL_TYPE .= "</select>\n";



print "<table width=100%>
<tr bgcolor=$_COLORS[3]><td colspan=2>

<table width=100% border=0>
<form action=$SELF_URL>
  <tr><th align=left>$_DATE: $DATE $TIME Admin: <a href='$SELF_URL?index=53'>$admin->{A_LOGIN}</a> / Online: <abbr title=\"$online_users\"><a href='$SELF_URL?index=50' title='$online_users'>Online: $online_count</a></abbr></th>
  <th align=right><input type=hidden name=index value=100>
  Search: $SEL_TYPE <input type=text name=LOGIN_EXPR value='$FORM{LOGIN_EXPR}'></th></tr>
</form>
</table>

</td></tr>

<tr><td valign=top width=18% bgcolor=$_COLORS[2] rowspan=2><p>\n";
print $html->menu(1, 'op', "", $main_menu, $sub_menu);
my $sub_menus = sub_menu($index);


#DEBUG#####################################
print "<table border=1>
<tr><td>index</td><td>$index</td></td></tr>
<tr bgcolor=$_COLORS[2]><td>OP</td><td>$OP</td></tr>\n";	

  while(my($k, $v)=each %FORM) {
    print "<tr><td>$k</td><td>$v</td></tr>\n";	
   }

print "</table>\n";
#DEBUG#####################################

print "</td><td bgcolor=$_COLORS[0]>$navigat_menu</td></tr>\n";
print "<tr><td valign=top align=center>";

if ($functions{$index}) {
  $OP = $op_names{$index};
  my $m;
  while(my($k, $v) = each %$sub_menus ) {
  	 $m .= "<a  href='$SELF_URL?index=$k'>$v</a> :: ";
   }
  if ($m ne '') {
    print "<Table width=100% border=0><tr><td align=right>$m</td></tr></table>\n";
   }

  $functions{$index}->();
}
else {
  message('err', $_ERROR,  "Function not exist ($index / $root_index)");	
}


print "</td></tr></table>\n";
if ($begin_time > 0) {
  my $end_time = gettimeofday;
  my $gen_time = $end_time - $begin_time;
  $conf{version} .= " (Generation time: $gen_time)";
}
print '<hr>'. $conf{version};































#**********************************************************
#
# check_permissions()
#**********************************************************
sub check_permissions {
  my ($login, $password)=@_;

  $admin->info(0, {LOGIN => "$login", 
                            PASSWORD => "$password",
                            SECRETKEY => $conf{secretkey},
                            IP => $SESSION_IP
                             }
                           );

  if ($admin->{errno}) {
    return 1;
   }

  my $p_ref = $admin->get_permissions();
  %permissions = %$p_ref;
  
  return 0;
}


#**********************************************************
# form_customers
#**********************************************************
sub form_customers {
  use Customers;	

my $customers = Customers->new($db); 
my $table = Abills::HTML->table( { width => '100%',
                                   border => 1,
                                   title => [$_LOGIN, $_FIO, $_DEPOSIT, $_CREDIT, $_TARIF_PLANS, '-', '-'],
                                   cols_align => ['left', 'left', 'right', 'right', 'left', 'center', 'center', 'center', 'center'],
                                  } );


print $html->pages($total, "op=users$pages_qs");
print $table->show();
print $html->pages($total, "op=users$pages_qs");
}


#**********************************************************
# form_customers
#**********************************************************
sub form_accounts {
  use Customers;	
  my $customer = Customers->new($db);
  my $account = $customer->account();

if ($FORM{add}) {
  $account->add({ ACCOUNT_NAME => $FORM{ACCOUNT_NAME},
                  TAX_NUMBER => $FORM{TAX_NUMBER},
                  BANK_ACCOUNT => $FORM{BANK_ACCOUNT},
                  BANK_NAME => $FORM{BANK_NAME}, 
                  COR_BANK_ACCOUNT => $FORM{COR_BANK_ACCOUNT},
                  BANK_BIC => $FORM{BANK_BIC}
           });
 
  if (! $account->{errno}) {
    message('info', $_ADDED, "$_ADDED");
   }
 }
elsif($FORM{change}) {
  $account->change($FORM{chg} , { ACCOUNT_NAME => $FORM{ACCOUNT_NAME},
                   TAX_NUMBER => $FORM{TAX_NUMBER},
                   BANK_ACCOUNT => $FORM{BANK_ACCOUNT},
                   BANK_NAME => $FORM{BANK_NAME}, 
                   COR_BANK_ACCOUNT => $FORM{COR_BANK_ACCOUNT},
                   BANK_BIC => $FORM{BANK_BIC} } );

  if (! $account->{errno}) {
    message('info', $_INFO, $_CHANGED. " # $account->{ACCOUNT_NAME}");
   }

 }
elsif($FORM{chg}) {
  $account->info($FORM{chg});

  if (! $account->{errno}) {
    message('info', $_INFO, $_CHANGING. " # $_NAME: $name<br>");
    $account->{ACTION}='change';
    $account->{LNG_ACTION}=$_CHANGE;
    Abills::HTML->tpl_show(templates('form_account'), $account);
    print "<hr><a href='$SELF_URL?index=12&account_id=$FORM{chg}'>$_ADD_USER</a>";
    $FORM{account_id} = $FORM{chg};
    form_users();
   }
 }
elsif($FORM{del}) {
   $account->del( $FORM{del} );
   message('info', $_INFO, "$_DELETED # $FORM{del}");
 }
else {

  my $list = $account->list( { %LIST_PARAMS } );
  my $table = Abills::HTML->table( { width => '100%',
                                   border => 1,
                                   title => [$_NAME, $_DEPOSIT, $_REGISTRATION, $_USERS, '-', '-'],
                                   cols_align => ['left', 'right', 'right', 'center', 'center'],
                                   pages => $account->{TOTAL},
                                   qs => $pages_qs
                                  } );

  foreach my $line (@$list) {
    $table->addrow($line->[0],  $line->[1], $line->[2], "<a href='$SELF_URL?op=users&account_id=$line->[4]'>$line->[3]</a>", 
      "<a href='$SELF_URL?index=$index&chg=$line->[4]'>$_INFO</a>",  $html->button($_DEL, "index=$index&del=$line->[4]", "$_DEL ?"));
   }
  print $table->show();

  $table = Abills::HTML->table( { width => '100%',
                                cols_align => ['right', 'right'],
                                rows => [ [ "$_TOTAL:", "<b>$account->{TOTAL}</b>" ] ]
                               } );
  print $table->show();
}

  if ($account->{errno}) {
    message('info', $_ERROR, "[$account->{errno}] $err_strs{$account->{errno}}");
   }

}





#**********************************************************
# add_account()
#**********************************************************
sub add_account {
  my $account;
  $account->{ACTION}='add';
  $account->{LNG_ACTION}=$_ADD;
  Abills::HTML->tpl_show(templates('form_account'), $account);
}



#**********************************************************
# user_form()
#**********************************************************
sub user_form {
 my ($type, $user_info, $attr) = @_;

 
 
 if (! defined($user_info->{UID})) {
   my $user = Users->new($db, $admin); 
   $user_info = $user->defaults();

   if ($FORM{account_id}) {
     use Customers;	
     my $customers = Customers->new($db);
     my $account = $customers->account->info($FORM{account_id});
 	   $user_info->{ACCOUNT_ID}=$FORM{account_id};
     $user_info->{EXDATA} =  "<tr><td>$_COMPANY:</td><td>$account->{ACCOUNT_NAME}</td></tr>\n";
    }

   $user_info->{EXDATA} .= "<tr><td>$_USER:*</td><td><input type=text name=LOGIN value=''></td></tr>\n";

   use Tariffs;
   my $tariffs = Tariffs->new($db);
   my $tariffs_list = $tariffs->list();

   $user_info->{TP_NAME} = "<select name=TARIF_PLAN>";
   foreach my $line (@$tariffs_list) {
     $user_info->{TP_NAME} .= "<option value=$line->[0]";
     $user_info->{TP_NAME} .=  ">$line->[0]:$line->[1]\n";
    }
   $user_info->{TP_NAME} .= "</select>";
   $user_info->{ACTION}='add';
   $user_info->{LNG_ACTION}=$_ADD;
  }
 else {
   $user_info->{EXDATA} = "<tr><td>$_DEPOSIT:</td><td>$user_info->{DEPOSIT}</td></tr>\n".
           "<tr><td>$_COMPANY:</td><td>$user_info->{ACCOUNT_NAME}</td></tr>\n";
   $user_info->{DISABLE} = ($user_info->{DISABLE} > 0) ? 'checked' : '';
   $user_info->{ACTION}='change';
   $user_info->{LNG_ACTION}=$_CHANGE;
  } 

Abills::HTML->tpl_show(templates('form_user'), $user_info);
}


#**********************************************************
# form_groups()
#**********************************************************
sub form_groups {
	use Users;
  my $users = Users->new($db, $admin); 

if ($FORM{add}) {
  $users->group_add( { %FORM });
  if (! $users->{errno}) {
    message('info', $_ADDED, "$_ADDED $users->{GID}");
   }
}
elsif($FORM{change}){
  $users->group_change( { %FORM });
  if (! $users->{errno}) {
    message('info', $_CHANGED, "$_ADDED $users->{GID}");
   }
}
elsif($FORM{chg}){
  $users->group_info( $FORM{chg} );
  if (! $users->{errno}) {
    message('info', $_CHANGED, "$_ADDED $users->{GID}");
   }

  $users->{ACTION}='change';
  $users->{LNG_ACTION}=$_CHANGE;
  Abills::HTML->tpl_show(templates('form_groups'), $users);
}
elsif($FORM{del}){
  $users->group_del( $FORM{del} );
  if (! $users->{errno}) {
    message('info', $_DELETED, "$_DELETED $users->{GID}");
   }
}


if ($users->{errno}) {
   message('err', $_ERROR, "[$users->{errno}] $err_strs{$users->{errno}}");	
  }

my $list = $users->groups_list({ %LIST_PARAMS });
my $table = Abills::HTML->table( { width => '100%',
                                   border => 1,
                                   title => [$_ID, $_NAME, $_DESCRIBE, $_USERS, '-', '-', '-', '-'],
                                   cols_align => ['left', 'left', 'left', 'right', 'center', 'center', 'center', 'center'],
                                   qs => $pages_qs,
                                   pages => $users->{TOTAL}
                                  } );

foreach my $line (@$list) {
  my $payments = ($permissions{1}) ?  "<a href='$SELF_URL?op=payments&uid=$line->[5]'>$_PAYMENTS</a>" : ''; 

  $table->addrow("$line->[0]", "$line->[1]", "$line->[2]", "$line->[3]", 
   "<a href='$SELF_URL?index=27&gid=$line->[0]'>$_STATS</a>",
   "<a href='$SELF_URL?index=27&gid=$line->[0]'>$_STATS</a>",
   "<a href='$SELF_URL?index=27&chg=$line->[0]'>$_CHANGE</a>",
   "<a href='$SELF_URL?index=27&del=$line->[0]'>$_DEL</a>");
}
print $table->show();




$table = Abills::HTML->table( { width => '100%',
                                cols_align => ['right', 'right'],
                                rows => [ [ "$_TOTAL:", "<b>$users->{TOTAL}</b>" ] ]
                               } );
print $table->show();
}



#**********************************************************
# form_users()
#**********************************************************
sub add_groups {
  my $users;
  $users->{ACTION}='add';
  $users->{LNG_ACTION}=$_ADD;
  Abills::HTML->tpl_show(templates('form_groups'), $users); 
}

#**********************************************************
# form_users()
#**********************************************************
sub form_users {
  my $uid = $FORM{uid};
  use Users;
 
  my $users = Users->new($db, $admin); 

if($uid > 0) {
  my $user_info = $users->info( $uid );
  if ($users->{errno}) {
    message('err', $_ERROR, "[$users->{errno}] $err_strs{$users->{errno}}");	
    return 0;
   }

  print  "<table width=100% bgcolor=$_COLORS[2]><tr><td>$_USER:</td>
  <td><a href='$SELF_URL?op=users&uid=$users->{UID}'><b>$users->{LOGIN}</b></td></tr></table>\n";
  
  $LIST_PARAMS{UID}=$user_info->{UID};
  $pages_qs="&uid=$user_info->{UID}";

  # Call Sub functions
  # 2 payments
  # 3 fess
  # 22 stats
  # 40 error log
  if($index > 0 && $index != 11 && $index != 100 && $index != 13) {
  	$functions{$index}->( { USER => $user_info } );
    #form_payments({ USER => $user_info });
    return 0;
   }
  elsif ($FORM{del}) {
    $users->del();
    if ($users->{errno}) {
      message('err', $_ERROR, "[$users->{errno}] $err_strs{$users->{errno}}");	
     }
    else {
      message('info', $_DELETE, "$_DELETED");
     }
    return 0;
   }

  
  print "<table width=100% border=1 cellspacing=1 cellpadding=2><tr><td valign=top>\n";
  if($FORM{password}) {
    my $password = chg_password($index, "$uid", { UID => $uid });
    if ($password ne '0') {
      $users->change($user_info->{UID}, { PASSWORD => $password, 
                               secretkey => $conf{secretkey}  });  

      if ($users->{errno}) {
        message('err', $_ERROR, "[$users->{errno}] $err_strs{$users->{errno}}");	
       }
      else {
        message('info', $_CHANGED, "$_CHANGED");
       }
      }
  }
  elsif ($FORM{nas}) {
    allow_nass({ USER => $user_info });
   }
  elsif ($FORM{change}) {
    $user_info->change($user_info->{UID}, { 
                 EMAIL => $FORM{EMAIL},
                 FIO => $FORM{FIO},
                 PHONE => $FORM{PHONE},
                 ADDRESS => $FOMR{ADDRESS},
                 ACTIVATE => $FORM{ACTIVATE},
                 EXPIRE => $FORM{EXPIRE},
                 CREDIT => $FORM{CREDIT},
                 REDUCTION  => $FORM{REDUCTION},
                 SIMULTANEONSLY => $FORM{SIMULTANEONSLY},
                 COMMENTS => $FORM{COMMENTS},
                 ACCOUNT_ID => $FORM{ACCOUNT_ID},
                 DISABLE => $FORM{DISABLE},
                 
                 IP => $FORM{IP},
                 NETMASK => $FORM{NETMASK},
                 SPEED => $FORM{SPEED},
                  }
                );  
    
    if ($users->{errno}) {
      message('err', $_ERROR, "[$users->{errno}] $err_strs{$users->{errno}}");	
      user_form();    
      return 0;	
     }
    else {
      message('info', $_CHANGED, "$_CHANGED");
     }
   }
#Change tariff plan
  elsif ($FORM{chg_tp}) {
    form_chg_tp($user_info);
   }
  elsif ($FORM{services}) {
  	user_services($user_info);
   }
#change account
  elsif ($FORM{company}) {
    use Customers;
    my $customer = Customers->new($db);

    $user_info->{SEL_ACCOUNTS} = "<select name=ACCOUNT_ID>\n";
    $user_info->{SEL_ACCOUNTS} .= "<option value='0'>-N/S-\n";
    my ($list, $total) = $customer->account->list();
    foreach my $line (@$list) {
      $user_info->{SEL_ACCOUNTS} .= "<option value='$line->[3]'>$line->[0]\n";
    }
    $user_info->{SEL_ACCOUNTS} .= "</select>\n";
    print Abills::HTML->tpl_show(templates('chg_account'), $user_info);
   }
  else {
    @action = ('change', $_CHANGE);
    user_form('test', $user_info);
   }


print "</td><td bgcolor=$_COLORS[3] valign=top width=180>
<table width=100% border=0><tr><td>
      <li><a href='$SELF?index=22&uid=$uid'>$_STATS</a>
      <li><a href='$SELF?index=2&uid=$uid'>$_PAYMENTS</a>
      <li><a href='$SELF?index=3&uid=$uid'>$_FEES</a>
      <li><a href='$SELF?index=40&uid=$uid'>$_ERROR_LOG</a>
      <li><a href='$SELF?op=sendmsg&uid=$uid'>$_SEND_MAIL</a>
      <li><a href='$SELF?op=messages&uid=$uid'>$_MESSAGES</a>
      <li><a href='docs.cgi?docs=accts&uid=$uid'>$_ACCOUNTS</a>
</td></tr>
<tr><td> 
      <br><b>$_CHANGE</b>
      <li><a href='$SELF_URL?op=changes&uid=$uid'>$_LOG</a>\n";

my %menus = ('password' => $_PASSWD,
             'chg_tp' =>   $_TARIF_PLAN,
             'company' =>  $_COMPANY,
             'nas' => $_NAS,
             'services' => $_SERVICES
 );
 

while(my($k, $v)=each (%menus) ) {
  print "<li><a href='$SELF_URL?index=11&&uid=$uid&$k=y'>$v</a>\n";
}


print "<li><a href='$SELF?op=users&del=y&uid=$uid' onclick=\"return confirmLink(this, '$_USER: $user_info->{LOGIN} / $user_info->{UID} ')\">$_DEL</a>
</td></tr>
</table>
</td></tr></table>\n";
  return 0;
}
elsif ($FORM{add}) {
  my $user_info = $users->add({ LOGIN => $FORM{LOGIN},
                 EMAIL => $FORM{EMAIL},
                 FIO => $FORM{FIO},
                 PHONE => $FORM{PHONE},
                 ADDRESS => $FORM{ADDRESS},
                 ACTIVATE => $FORM{ACTIVATE},
                 EXPIRE => $FORM{EXPIRE},
                 CREDIT => $FORM{CREDIT},
                 REDUCTION  => $FORM{REDUCTION},
                 SIMULTANEONSLY => $FORM{SIMULTANEONSLY},
                 COMMENTS => $FORM{COMMENTS},
                 ACCOUNT_ID => $FORM{ACCOUNT_ID}, 
                 DISABLE => $FORM{DISABLE},
                 
                 TARIF_PLAN => $FORM{TARIF_PLAN},
                 IP => $FORM{IP},
                 NETMASK => $FORM{NETMASK},
                 SPEED => $FORM{SPEED},
                 FILTER_ID => $FORM{FILTER_ID},
                 CID => $FORM{CID}
               }
              );  

  if ($users->{errno}) {
    message('err', $_ERROR, "[$users->{errno}] $err_strs{$users->{errno}}");	
    user_form();    
    return 0;	
   }
  else {
    message('info', $_ADDED, "$_ADDED '$user_info->{LOGIN}' / [$user_info->{UID}]");
    $user_info = $users->info( $user_info->{UID} );
    Abills::HTML->tpl_show(templates('user_info'), $user_info);
    $LIST_PARAMS{UID}=$user_info->{UID};
    form_payments({ USER => $user_info });
    return 0;
   }
}


if ($FORM{account_id}) {
  print "<p><b>$_ACCOUNT:</b> $FORM{account_id}</p>\n";
  $pages_qs .= "&account_id=$FORM{account_id}";
  $LIST_PARAMS{ACCOUNT_ID} = $FORM{account_id};
 }  

if ($FORM{debs}) {
  print "<p>$_DEBETERS</p>\n";
  $pages_qs .= "&debs=$FORM{debs}";
  $LIST_PARAMS{DEBETERS} = 'y';
 }  

if ($FORM{tp}) {
  print "<p>$_VARIANT: $FORM{variant}</p>\n"; 
  $pages_qs .= "&tp=$FORM{tp}";
  $LIST_PARAMS{TP} = $FORM{tp};
 }

my $letters = "<a href='$SELF?op=users'>All</a> ::";
for (my $i=97; $i<123; $i++) {
  my $l = chr($i);
  if ($FORM{letter} eq $l) {
     $letters .= "<b>$l </b>";
    }
  else {
     #$pages_qs = '';
     $letters .= "<a href='$SELF?op=users&letter=$l$pages_qs'>$l</a> ";
   }
 }

 if ($FORM{letter}) {
   $LIST_PARAMS{FIRST_LETTER} = $FORM{letter};
   $pages_qs .= "&letter=$FORM{letter}";
  } 

my $list = $users->list( { %LIST_PARAMS } );

if ($users->{TOTAL} == 1) {
	$FORM{uid}=$list->[0]->[5];
	form_users();
	return 0;
}

print $letters;
my $table = Abills::HTML->table( { width => '100%',
                                   border => 1,
                                   title => [$_LOGIN, $_FIO, $_DEPOSIT, $_CREDIT, $_TARIF_PLANS, '-', '-'],
                                   cols_align => ['left', 'left', 'right', 'right', 'left', 'center', 'center', 'center', 'center'],
                                   qs => $pages_qs,
                                   pages => $users->{TOTAL}
                                  } );

foreach my $line (@$list) {
  my $payments = ($permissions{1}) ?  "<a href='$SELF_URL?op=payments&uid=$line->[5]'>$_PAYMENTS</a>" : ''; 

  $table->addrow("<a href='$SELF_URL?op=users&uid=$line->[5]'>$line->[0]</a>", "$line->[1]",
   "$line->[2]", "$line->[3]", "$line->[4]", $payments, "<a href='$SELF_URL?op=stats&uid=$line->[5]'>$_STATS</a>");
}
print $table->show();

$table = Abills::HTML->table( { width => '100%',
                                cols_align => ['right', 'right'],
                                rows => [ [ "$_TOTAL:", "<b>$users->{TOTAL}</b>" ] ]
                               } );
print $table->show();



}

#**********************************************************
# user_services
#**********************************************************
sub user_services {
  my ($user) = @_;
if ($FORM{add}) {
	
}


 use Tariffs;
 my $tariffs = Tariffs->new($db);
 my $variant_out = '';
 
 my $tariffs_list = $tariffs->list();
 $variant_out = "<select name=servise>";

 foreach my $line (@$tariffs_list) {
     $variant_out .= "<option value=$line->[0]";
#     $variant_out .= ' selected' if ($line->[0] == $user_info->{TARIF_PLAN});
     $variant_out .=  ">$line->[0]:$line->[1]\n";
    }
  $variant_out .= "</select>";



print << "[END]";
<FORM action=$SELF_URL>
<input type=hidden name=uid value=$user->{UID}>
<input type=hidden name=op value=users>
<input type=hidden name=services value=y>
<table>
<tr><td>$_SERVICES:</td><td>$variant_out</td></tr>
<tr><td>$_DESCRIBE:</td><td><input type=text name=S_DESCRIBE value="%S_DESCRIBE%"></td></tr>
</table>
<input type=submit name=%ACTION% value='%LNG_ACTION%'>
</form>
[END]


my $table = Abills::HTML->table( { width => '100%',
                                   border => 1,
                                   title => [$_SERVISE, $_DATE, $_DESCRIBE, '-', '-'],
                                   cols_align => ['left', 'right', 'left', 'center', 'center'],
                                   qs => $pages_qs,
                                   pages => $users->{TOTAL}
                                  } );

print $table->show();



}


#*******************************************************************
# Users and Variant NAS Servers
# allow_nass()
#*******************************************************************
sub allow_nass {
 my ($attr) = @_;
 my @allow = split(/, /, $FORM{ids});
 my $pages_qs = '';
 my %allow_nas = (); 
 my $op = '';

if ($attr->{USER}) {
  my $user = $attr->{USER};
  $pages_qs = "&uid=$user->{UID}&nas=y";
  if ($FORM{change}) {
    $user->nas_add(\@allow);
    if (! $user->{errno}) {
      message('info', $_INFO, "$_ALLOW $_NAS: $FORM{ids}");
     }
   }
  elsif($FORM{default}) {
    $user->nas_del();
    if (! $user->{errno}) {
      message('info', $_NAS, "$_CHANGED");
     }
   }

  if ($user->{errno}) {
    message('err', $_ERROR, "[$user->{errno}] $err_strs{$user->{errno}}");	
   }

  my ($nas_servers, $total) = $user->nas_list();
  foreach my $nas_id (@$nas_servers) {
     $allow_nas{$nas_id}='test';
   }
  $op = "<input type=hidden name=index  value=$index>
   <input type=hidden name=nas  value=y>
   <input type=hidden name=uid  value='$user->{UID}'>\n";
 }
elsif ($FORM{uid}) {
  $FORM{nas}='y';
  form_users();
  return 0;
 }
elsif($attr->{TP}) {
  my $tarif_plan = $attr->{TP};

  if ($FORM{change}) {
    $tarif_plan->nas_add(\@allow);
    if ($tarif_plan->{errno}) {
      message('err', $_ERROR, "[$tarif_plan->{errno}] $err_strs{$tarif_plan->{errno}}");	
     }
    else {
      message('info', $_INFO, "$_ALLOW $_NAS: $FORM{ids}");
     }
   }
  
  my $list = $tarif_plan->nas_list();
  foreach my $nas_id (@$list) {
     $allow_nas{$nas_id->[0]}='y';
   }

  $op = "<input type=hidden name=vid  value='$tarif_plan->{VID}'>
  <input type=hidden name=index  value='$FORM{index}'>\n";
}
elsif ($FORM{vid}) {
  $FORM{chg}=$FORM{vid};
  form_tp();
  return 0;
 }

my $nas = Nas->new($db);
my $out = "<form action='$SELF_URL'>
$op";

my $table = Abills::HTML->table( { width => '100%',
                                   border => 1,
                                   title => ["$_ALLOW", "ID", "$_NAME", "IP", "$_TYPE", "$_AUTH"],
                                   cols_align => ['center', 'left', 'left', 'right', 'left', 'left'],
                                   qs => $pages_qs,
                                  } );

my $list = $nas->list();

foreach my $line (@$list) {
  my $checked = (defined($allow_nas{$line->[0]}) || $allow_nas{all}) ? ' checked ' :  '';    
  $table->addrow("<input type=checkbox name=ids value=$line->[0] $checked>", $line->[2], $line->[1], 
    $line->[4], $line->[5], $auth_types[$line->[6]]);
}

$out .= $table->show();
$out .= "<p><input type=submit name=change value=$_CHANGE> <input type=submit name=default value='$_DEFAULT'>
</form>\n";

print $out;
}


#*******************************************************************
# Change user variant form
# form_chg_vid()
#*******************************************************************
sub form_chg_tp {
 my ($user) = @_;

 my $TARIF_PLAN = $FORM{tarif_plan} || $_DEFAULT_VARIANT;
 my $period = $FORM{period} || 0;

 use Shedule;
 $shedule = Shedule->new($db, $admin);

if ($FORM{set}) {
  if ($period == 1) {
    $FORM{date_m}++;
    $shedule->add( {UID => $user->{UID},
                   TYPE => 'tp',
                   ACTION => $TARIF_PLAN,
    	             D => $FORM{date_d},
                   M => $FORM{date_m},
                   Y => $FORM{date_y},
                   DEWCRIBE => "$message<br>
                   $_FROM: '$FORM{date_y}-$FORM{date_m}-$FORM{date_d}'"
                    });

    if ($shedule->{errno}) {
      message('err', $_ERROR, "[$shedule->{errno}] $err_strs{$shedule->{errno}}");	
     }
    else {
      message('info', $_CHANGED, "$_CHANGED");
      $user->info($user->{UID});
    }
   }
  else {
    $user->change($user->{UID}, {
                 TARIF_PLAN => $TARIF_PLAN
                    }
               );
    if ($users->{errno}) {
      message('err', $_ERROR, "[$users->{errno}] $err_strs{$users->{errno}}");	
     }
    else {
      message('info', $_CHANGED, "$_CHANGED");
      $user->info($user->{UID});
    }

  }
}
elsif($FORM{del}) {
  shedule('del', { uid => $user->{UID},
   	           id  => $FORM{del}  } );
# $q = $db->do("DELETE FROM shedule WHERE id='$FORM{del}' and uid='$uid';") || die $db->strerr;
}

use Tariffs;
my $tariffs = Tariffs->new($db);
my $variant_out = '';
 
 my $tariffs_list = $tariffs->list();
 foreach my $line (@$tariffs_list) {
   $variant_out .= "<option value=$line->[0]";
   $variant_out .= ' selected' if ($line->[0] == $user->{TARIF_PLAN});
   $variant_out .=  ">$line->[0]:$line->[1]\n";
  }


 my $params='';
 $q = $db->prepare("SELECT id, CONCAT(y, '-', m, '-', d), action FROM shedule WHERE type='tp' and uid='$uid';") || die $db->strerr;
 $q ->execute();
 
 $params .= "<tr><td>$_TO:</td><td><select name=tarif_plan>$variant_out</select></td></tr>";
 $params .= form_period($period);
 $params .= "</table><input type=submit name=set value=\"$_CHANGE\">\n";


my $result = "<form action=$SELF_URL>
<input type=hidden name=uid value='$user->{UID}'>
<input type=hidden name=chg_tp value=y>
<input type=hidden name=index value=11>
<table width=400 border=0>
<tr><td>$_FROM:</td><td bgcolor=$_BG2>$user->{TARIF_PLAN} $user->{TP_NAME} [<a href='$SELF?op=tp&chg=$user->{TARIF_PLAN}' title='$_VARIANTS'>$_VARIANTS</a>]</td></tr>
$params
</form>\n";

 print $result;
}



#**********************************************************
# form_changes();
#**********************************************************
sub form_changes {
 my ($attr) = @_; 
 my $pages_qs = '';
 
 
if (defined($attr->{USER})) { 
  $pages_qs = "&uid=$attr->{USER}->{UID}";
 }
elsif ($FORM{uid}) {
	form_users();
	return 0;
 }
elsif (defined($attr->{ADMIN})) { 
  $pages_qs = "&aid=$attr->{ADMIN}->{AID}";
 }
elsif ($FORM{aid}) {
	form_admins();
	return 0;
 }



if ($FORM{del} && $FORM{is_js_confirmed}) {
	$admin->action_del( $FORM{del} );
  if ($admins->{errno}) {
    message('err', $_ERROR, "[$admins->{errno}] $err_strs{$admins->{errno}}");	
   }
  else {
    message('info', $_DELETED, "$_DELETED [$FORM{del}]");
   }
 }

 	

#u.id, aa.datetime, aa.actions, a.name, INET_NTOA(aa.ip),  aa.uid, aa.aid, aa.id
 	
my $list = $admin->action_list( { %LIST_PARAMS } );
my $table = Abills::HTML->table( { width => '100%',
                                   border => 1,
                                   title => ['#', 'UID',  $_DATE,  $_CHANGE,  $_ADMIN,   'IP', '-'],
                                   cols_align => ['right', 'left', 'right', 'left', 'left', 'right', 'center'],
                                   qs => $pages_qs,
                                   pages => $admin->{TOTAL}
                                   
                                  } );
foreach my $line (@$list) {
  my $delete = $html->button($_DEL, "op=changes$pages_qs&del=$line->[0]", "$_DEL ?"); 
  $table->addrow("<b>$line->[0]</b>", "<a href='$SELF_URL?op=users&uid=$line->[6]'>$line->[1]</a>", $line->[2], $line->[3], 
   $line->[4], $line->[5], $delete);
}

print $table->show();
$table = Abills::HTML->table( { width => '100%',
                                cols_align => ['right', 'right'],
                                rows => [ [ "$_TOTAL:", "<b>$admin->{TOTAL}</b>" ] ]
                               } );
print $table->show();
}




#**********************************************************
# templates
#**********************************************************
sub templates {
  my ($tpl_name) = @_;

if ($tpl_name eq 'form_user') {
return qq{
<form action=$SELF_URL method=post>
<input type=hidden name=index value=11>
<input type=hidden name=account_id value='%ACCOUNT_ID%'>
<input type=hidden name=uid value="%UID%">
<table width=420 cellspacing=0 cellpadding=3>

%EXDATA%

<tr><td>$_FIO:*</td><td><input type=text name=FIO value="%FIO%"></td></tr>
<tr><td>$_PHONE:</td><td><input type=text name=PHONE value="%PHONE%"></td></tr>
<tr><td>$_ADDRESS:</td><td><input type=text name=ADDRESS value="%ADDRESS%"></td></tr>
<tr><td>E-mail:</td><td><input type=text name=EMAIL value="%EMAIL%"></td></tr>
<tr><td colspan=2>&nbsp;</td></tr>
<tr><td>$_TARIF_PLAN:</td><td valign=center>%TP_NAME%</td></tr>
<tr><td>$_CREDIT:</td><td><input type=text name=CREDIT value='%CREDIT%'></td></tr>
<tr><td>$_SIMULTANEOUSLY:</td><td><input type=text name=SIMULTANEONSLY value='%SIMULTANEONSLY%'></td></tr>
<tr><td>$_ACTIVATE:</td><td><input type=text name=ACTIVATE value='%ACTIVATE%'></td></tr>
<tr><td>$_EXPIRE:</td><td><input type=text name=EXPIRE value='%EXPIRE%'></td></tr>
<tr><td>$_REDUCTION (%):</td><td><input type=text name=REDUCTION value='%REDUCTION%'></td></tr>
<tr><td>IP:</td><td><input type=text name=IP value='%IP%'></td></tr>
<tr><td>Netmask:</td><td><input type=text name=NETMASK value='%NETMASK%'></td></tr>
<tr><td>$_SPEED (kb):</td><td><input type=text name=SPEED value='%SPEED%'></td></tr>
<tr><td>$_FILTERS:</td><td><input type=text name=FILTER_ID value='%FILTER_ID%'></td></tr>
<tr><td><b>CID:</b><br></td><td><input title='MAC: [00:40:f4:85:76:f0]
IP: [10.0.1.1]
PHONE: [805057395959]' type=text name=CID value='%CID%'></td></tr>
<tr><td>$_DISABLE:</td><td><input type=checkbox name=DISABLE value='1' %DISABLE%></td></tr>
<tr><th colspan=2>:$_COMMENTS:</th></tr>
<tr><th colspan=2><textarea name=COMMENTS rows=5 cols=45>%COMMENTS%</textarea></th></tr>
</table>
<p>
<input type=submit name='%ACTION%' value='%LNG_ACTION%'>
</form>
};

}
elsif ($tpl_name eq 'user_info') {
return qq{
<table width=100%>
<tr><td>$_LOGIN:</td><td>%LOGIN%</td></tr>
<tr><td>UID:</td><td>%UID%</td></tr>
<tr><td>$_FIO:</td><td>%FIO%</td></tr>
<tr><td>$_PHONE:</td><td>%PHONE%</td></tr>
<tr><td>$_ADDRESS:</td><td>%ADDRESS%</td></tr>
<tr><td>E-mail:</td><td>%EMAIL%</td></tr>
<tr><td>$_TARIF_PLAN:</td><td>%TARIF_PLAN%</td></tr>
<tr><td>$_CREDIT:</td><td>%CREDIT%</td></tr>
<tr><td>$_REDUCTION</td><td>%REDUICTION% %</td></tr>
<tr><td>$_SIMULTANEOUSLY:</td><td>%SIMULTANEONSLY%</td></tr>
<tr><td>$_ACTIVATE:</td><td>%ACTIVATE%</td></tr>
<tr><td>$_EXPIRE:</td><td>%EXPIRE%</td></tr>
<tr><td>IP:</td><td>%IP%</td></tr>
<tr><td>NETMASK:</td><td>%NETMASK%</td></tr>
<tr><td>$_SPEED (Kb)</td><td>%SPEED%</td></tr>
<tr><td>$_FILTERS</td><td>%FILTER_ID%</td></tr>
<tr><td>CID:</td><td>%CID%</td></tr>
<tr><th colspan=2>:$_COMMENTS:</th></tr>
<tr><th colspan=2>%COMMENTS%</th></tr>
</table>};
 }
elsif ($tpl_name eq 'form_payments') {
return qq{
<form action=$SELF_URL>
<input type=hidden name=op value=payments>
<input type=hidden name=uid value=%UID%>
<table>
<tr><td>$_SUM:</td><td><input type=text name=SUM></td></tr>
<tr><td>$_DESCRIBE:</td><td><input type=text name=DESCRIBE></td></tr>
<tr><td>$_PAYMENT_METHOD:</td><td>%SEL_METHOD%</td></tr>
<tr><td>$_EXCHANGE_RATE:</td><td>%SEL_ER%</td></tr>
</table>
<input type=submit name=add value='$_ADD'>
</form>
};
}
elsif ($tpl_name eq 'tp') {
return qq{
<form action=$SELF_URL METHOD=POST>
<input type=hidden name=index value=70>
<input type=hidden name=chg value='%VID%'>
<table border=0>
  <tr><th>#</th><td><input type=text name=VID value='%VID%'></td></tr>
  <tr><td>$_NAME:</td><td><input type=text name=NAME value='%NAME%'></td></tr>
  <tr><td>$_UPLIMIT:</td><td><input type=text name=ALERT value='%ALERT%'></td></tr>
  <tr><td>$_BEGIN:</td><td><input type=text name=BEGIN value='%BEGIN%'></td></tr>
  <tr><td>$_END:</td><td><input type=text name=END value='%END%'></td></tr>
  <tr><td>$_DAY_FEE:</td><td><input type=text name=DAY_FEE value='%DAY_FEE%'></td></tr>
  <tr><td>$_MONTH_FEE:</td><td><input type=text name=MONTH_FEE value='%MONTH_FEE%'></td></tr>
  <tr><td>$_SIMULTANEOUSLY:</td><td><input type=text name=SIMULTANEOUSLY value='%SIMULTANEOUSLY%'></td></tr>
  <tr><td>$_HOUR_TARIF (1 Hour):</td><td><input type=text name=TIME_TARIF value='%TIME_TARIF%'></td></tr>
  <tr><th colspan=2 bgcolor=$_COLORS[0]>$_TIME_LIMIT (sec)</th></tr> 
  <tr><td>$_DAY</td><td><input type=text name=DAY_TIME_LIMIT value='%DAY_TIME_LIMIT%'></td></tr> 
  <tr><td>$_WEEK</td><td><input type=text name=WEEK_TIME_LIMIT value='%WEEK_TIME_LIMIT%'></td></tr>
  <tr><td>$_MONTH</td><td><input type=text name=MONTH_TIME_LIMIT value='%MONTH_TIME_LIMIT%'></td></tr>
  <tr><th colspan=2 bgcolor=$_COLORS[0]>$_TRAF_LIMIT (Mb)</th></tr>
  <tr><td>$_DAY</td><td><input type=text name=DAY_TRAF_LIMIT value='%DAY_TRAF_LIMIT%'></td></tr>
  <tr><td>$_WEEK</td><td><input type=text name=WEEK_TRAF_LIMIT value='%WEEK_TRAF_LIMIT%'></td></tr>
  <tr><td>$_MONTH</td><td><input type=text name=MONTH_TRAF_LIMIT value='%MONTH_TRAF_LIMIT%'></td></tr>
  <tr><td>$_OCTETS_DIRECTION</td><td>%SEL_OCTETS_DIRECTION%</td></tr>
  <tr><th colspan=2 bgcolor=$_COLORS[0]>$_OTHER</th></tr>
  <tr><td>$_ACTIVATE:</td><td><input type=text name=ACTIV_PRICE value='%ACTIV_PRICE%'></td></tr>
  <tr><td>$_CHANGE:</td><td><input type=text name=CHANGE_PRICE value='%CHANGE_PRICE%'></td></tr>
  <tr><td>$_CREDIT_TRESSHOLD:</td><td><input type=text name=CREDIT_TRESSHOLD value='%CREDIT_TRESSHOLD%'></td></tr>
  <tr><td>$_AGE ($_DAYS):</td><td><input type=text name=AGE value='%AGE%'></td></tr>
</table>
<input type=submit name='%ACTION%' value='%LNG_ACTION%'>
</form>
};
}
elsif($tpl_name eq 'tt') {
return qq{ <form action=$SELF_URL method=POST>
<input type=hidden name=index value='74'>
<input type=hidden name=vid value='%VID%'>
<table BORDER=0 CELLSPACING=1 CELLPADDING=0>
<tr bgcolor=$_COLORS[0]><th>#</th><th>$_BYTE_TARIF IN (1 Mb)</th><th>$_BYTE_TARIF OUT (1 Mb)</th><th>$_PREPAID (Mb)</th><th>$_SPEED (Kbits)</th><th>$_DESCRIBE</th><th>NETS</th></tr>
<tr><td bgcolor=$_COLORS[0]>0</td>
<td valign=top><input type=text name='TT_PRICE_IN_0' value='%TT_PRICE_IN_0%'></td>
<td valign=top><input type=text name='TT_PRICE_OUT_0' value='%TT_PRICE_OUT_0%'></td>
<td valign=top><input type=text name='TT_PREPAID_0' value='%TT_PREPAID_0%'></td>
<td valign=top><input type=text name='TT_SPEED_0' value='%TT_SPEED_0%'></td>
<td valign=top><input type=text name='TT_DESCRIBE_0' value='%TT_DESCRIBE_0%'></td>
<td><textarea cols=20 rows=4 name='TT_NETS_0'>%TT_NETS_0%</textarea></td></tr>

<tr><td bgcolor=$_COLORS[0]>1</td>
<td valign=top><input type=text name='TT_PRICE_IN_1' value='%TT_PRICE_IN_1%'></td>
<td valign=top><input type=text name='TT_PRICE_OUT_1' value='%TT_PRICE_OUT_1%'></td>
<td valign=top><input type=text name='TT_PREPAID_1' value='%TT_PREPAID_1%'></td>
<td valign=top><input type=text name='TT_SPEED_1' value='%TT_SPEED_1%'></td>
<td valign=top><input type=text name='TT_DESCRIBE_1' value='%TT_DESCRIBE_1%'></td>
<td><textarea cols=20 rows=4 name='TT_NETS_1'>%TT_NETS_1%</textarea></td></tr>

<tr><td bgcolor=$_COLORS[0]>2</td>
<td valign=top>&nbsp;</td>
<td valign=top>&nbsp;</td>
<td valign=top>&nbsp;</td>
<td valign=top><input type=text name='TT_SPEED_2' value='%TT_SPEED_2%'></td>
<td valign=top><input type=text name='TT_DESCRIBE_2' value='%TT_DESCRIBE_2%'></td>
<td><textarea cols=20 rows=4 name='TT_NETS_2'>%TT_NETS_2%</textarea></td></tr>

</table>
<input type=submit name='change' value='$_CHANGE'>
</form>\n};
}
elsif ($tpl_name eq 'ti') {
return qq{<form action=$SELF_URL>
<input type=hidden name=index value=73>
<input type=hidden name=vid value='%VID%'>
 <TABLE width=400 cellspacing=1 cellpadding=0 border=0>
 <tr><td>$_DAY:</td><td><select name=TI_DAY>%SEL_DAYS%</select></td></tr>
 <tr><td>$_BEGIN:</td><td><input type=text name=TI_BEGIN value='%TI_BEGIN%'></td></tr>
 <tr><td>$_END:</td><td><input type=text name=TI_END value='%TI_END%'></td></tr>
 <tr><td>$_HOUR_TARIF<br>(0.00 / 0%):</td><td><input type=text name=TI_TARIF value='%TI_TARIF%'></td></tr>
</table>
<input type=submit name=add value='$_ADD'>
</form>
};
}
elsif ($tpl_name eq 'form_admin') {
return qq{<form action=$SELF_URL>
<input type=hidden name=index value=50>
<input type=hidden name=aid value='%AID%'>
<table>
<tr><td>ID:</td><td><input type=text name=A_LOGIN value="%A_LOGIN%"></td></tr>
<tr><td>$_FIO:</td><td><input type=text name=A_FIO value="%A_FIO%"></td></tr>
<tr><td>$_DISABLE:</td><td><input type=checkbox name=DISABLE value='1' %DISABLE%></td></tr>
<tr><td>$_PHONE:</td><td><input type=text name=A_PHONE value='%A_PHONE%'></td></tr>
<!-- <tr><td>$_GROUPS:</td><td><input type=text name=name value="$name"></td></tr> -->
</table>
<input type=submit name='%ACTION%' value='%LNG_ACTION%'>
</form>
};
}
elsif ($tpl_name eq 'form_nas') {
return qq{
<form action=$SELF_URL METHOD=post>
<input type=hidden name=index value=60>
<input type=hidden name=nid value=%NID%>
<table>
<tr><td>ID</td><td>%NID%</td></tr>
<tr><td>IP</td><td><input type=text name=NAS_IP value='%NAS_IP%'></td></tr>
<tr><td>$_NAME:</td><td><input type=text name=NAS_NAME value="%NAS_NAME%"></td></tr>
<tr><td>Radius NAS-Identifier:</td><td><input type=text name=NAS_INDENTIFIER value="%NAS_INDENTIFIER%"></td></tr>
<tr><td>$_DESCRIBE:</td><td><input type=text name=NAS_DESCRIBE value="%NAS_DESCRIBE%"></td></tr>
<tr><td>$_TYPE:</td><td><select name=NAS_TYPE>%SEL_TYPE%</select></td></tr>
<tr><td>$_AUTH:</td><td><select name=NAS_AUTH_TYPE>%SEL_AUTH_TYPE%</select></td></tr>
<tr><th colspan=2>:$_MANAGE:</th></tr>
<tr><td>IP:PORT:</td><td><input type=text name=NAS_MNG_IP_PORT value="%NAS_MNG_IP_PORT%"></td></tr>
<tr><td>$_USER:</td><td><input type=text name=NAS_MNG_USER value="%NAS_MNG_USER%"></td></tr>
<tr><td>$_PASSWD:</td><td><input type=password name=NAS_MNG_PASSWORD value=""></td></tr>
<tr><th colspan=2>RADIUS $_PARAMS (,)</th></tr>
<tr><th colspan=2><textarea cols=50 rows=4 name=NAS_RAD_PAIRS>%NAS_RAD_PAIRS%</textarea></th></tr>
</table>
<input type=submit name=%ACTION% value='%LNG_ACTION%'>
</form>
};

}
elsif ($tpl_name eq 'form_account') {
return qq{	
<form action=$SELF_URL METHOD=POST>
<input type=hidden name=index value='13'>
<input type=hidden name=chg value='%ACCOUNT_ID%'>
<Table>
<tr><td>$_NAME:</td><td><input type=text name=ACCOUNT_NAME value="%ACCOUNT_NAME%"></td></tr>
<tr bgcolor=$_BG1><td>$_DEPOSIT:</td><td>%DEPOSIT%</td></tr>
<tr bgcolor=$_BG1><td>$_TAX_NUMBER:</td><td><input type=text name=TAX_NUMBER value='%TAX_NUMBER%' size=60></td></tr>
<tr bgcolor=$_BG1><td>$_ACCOUNT:</td><td><input type=text name=BANK_ACCOUNT value='%BANK_ACCOUNT%' size=60></td></tr>
<tr bgcolor=$_BG1><td>$_BANK_NAME:</td><td><input type=text name=BANK_NAME value='%BANK_NAME%' size=60></td></tr>
<tr bgcolor=$_BG1><td>$_COR_BANK_ACCOUNT:</td><td><input type=text name=COR_BANK_ACCOUNT value='%COR_BANK_ACCOUNT%' size=60></td></tr>
<tr bgcolor=$_BG1><td>$_BANK_BIC:</td><td><input type=text name=BANK_BIC value='%BANK_BIC%' size=60></td></tr>
</table>
<input type=submit name='%ACTION%' value='%LNG_ACTION%'>
</form>
}
}
elsif ($tpl_name eq 'chg_account') {
return qq{
<form action=$SELF_URL>
<input type=hidden name=index value=11>
<input type=hidden name=uid value=%UID%>
<input type=hidden name=company value=y>
<Table>
<tr><td>$_ACCOUNT:</td><td>%ACCOUNT_NAME%</td></tr>
<tr><td>$_TO:</td><td>%SEL_ACCOUNTS%</td></tr>
</table>
<input type=submit name=change value=$_CHANGE>
</form>
}
}
elsif ($tpl_name eq 'form_search') {
return qq{
<form action=$SELF_URL>
<input type=hidden name=index value=100>
<table>
<tr><td>$_NAME:</td><td><input type=text name=LOGIN_EXPR value='%LOGIN_EXPR%'></td></tr>
<tr><td>WHERE:</td><td>$SEL_TYPE</td></tr>
<tr><td>$_PERIOD:</td><td>
<table width=100%>
<tr><td>$_FROM: </td><td>%FROM_DATE%</td></tr>
<tr><td>$_TO:</td><td>%TO_DATE%</td></tr>
</table>
</td></tr>
%SEARCH_FORM%
</table>
<input type=submit name=search value=$_SEARCH>
</form>
};
	
}
elsif ($tpl_name eq 'form_ip_pools') {
return qq{
<form action=$SELF_URL METHOD=post>
<input type=hidden name=index value=61>
<input type=hidden name=nid value=%NID%>
<table>
<tr><td>FIRST IP:</td><td><input type=text name=NAS_IP_SIP value='%NAS_IP_SIP%'></td></tr>
<tr><td>COUNT:</td><td><input type=text name=NAS_IP_COUNT value='%NAS_IP_COUNT%'></td></tr>
</table>
<input type=submit name=add value="$_ADD">
</form>
};
}
elsif ($tpl_name eq 'form_groups') {
return qq{
<form action=$SELF_URL METHOD=post>
<input type=hidden name=index value=27>
<input type=hidden name=chg value=%GID%>
<table>
<tr><td>GID:</td><td><input type=text name=GID value='%GID%'></td></tr>
<tr><td>$_NAME:</td><td><input type=text name=NAME value='%NAME%'></td></tr>
<tr><td>$_DESCRIBE:</td><td><input type=text name=DESCRIBE value='%DESCRIBE%'></td></tr>
</table>
<input type=submit name=%ACTION% value="%LNG_ACTION%">
</form>
};
}



return 'No such template [$tpl_name]';
	
}


#**********************************************************
# Time intervals
# form_time_intervals()
#**********************************************************
sub form_time_intervals {
  my ($attr) = @_;
  my $pages_qs = "&vid=$FORM{vid}";
  @DAY_NAMES = ("$_ALL", 'Mon', 'Tue', 'Wen', 'The', 'Fri', 'Sat', 'Sun', "$_HOLIDAYS");
  my $tarif_plan;

if($attr->{TP}) {
  $tarif_plan = $attr->{TP};

  if ($FORM{add}) {
    $tarif_plan->ti_add( { VID => $FORM{VID},
    	                     TI_DAY => $FORM{TI_DAY},
    	                     TI_BEGIN => $FORM{TI_BEGIN},
    	                     TI_END => $FORM{TI_END},
    	                     TI_TARIF => $FORM{TI_TARIF}
   	 });

    if (! $tarif_plan->{errno}) {
      message('info', $_INFO, "$_INTERVALS");
     }
   }
  elsif($FORM{del} && $FORM{is_js_confirmed}) {
    $tarif_plan->ti_del($FORM{del});
    if (! $tarif_plan->{errno}) {
      message('info', $_DELETED, "$_DELETED $FORM{del}");
     }
   }

 	$tarif_plan->ti_defaults();

  my $list = $tarif_plan->ti_list($FORM{ti});
  my $table = Abills::HTML->table( { width => '100%',
                                   border => 1,
                                   title => ['#', $_DAYS, $_BEGIN, $_END, $_HOUR_TARIF, '-',  '-'],
                                   cols_align => ['right', 'left', 'right', 'right', 'right', 'center', 'center'],
                                   qs => $pages_qs,
                                  } );

  foreach my $line (@$list) {
    my $delete = $html->button($_DEL, "index=73$pages_qs&del=$line->[5]", "$line->[5]  $_DEL ?"); 
    $table->addrow("$line->[0]", $DAY_NAMES[$line->[1]], $line->[2], $line->[3], 
     $line->[4], '', $delete);
   };
  print $table->show();
  
 }
elsif ($FORM{vid}) {
  $FORM{chg}=$FORM{vid};
  form_tp();
  return 0;
 }

if ($tarif_plan->{errno}) {
   message('err', $_ERROR, "[$tarif_plan->{errno}] $err_strs{$tarif_plan->{errno}}");	
 }



my $i=0;
foreach $line (@DAY_NAMES) {
  $tarif_plan->{SEL_DAYS} .= "<option value=$i";
  $tarif_plan->{SEL_DAYS} .= " selected" if ($FORM{day} == $i);
  $tarif_plan->{SEL_DAYS} .= ">$line\n";
  $i++;
}

Abills::HTML->tpl_show(templates('ti'), $tarif_plan);
}


#**********************************************************
# form_traf_tarifs()
#**********************************************************
sub form_traf_tarifs {
  my ($attr) = @_;
  my $tarif_plan;

  
if($attr->{TP}) {
  $tarif_plan = $attr->{TP};
  $tarif_plan->tt_defaults();

  if ($FORM{change}) {
    $tarif_plan->tt_change( { 
    	TT_DESCRIBE_0 => $FORM{TT_DESCRIBE_0},
      TT_PRICE_IN_0 => $FORM{TT_PRICE_IN_0},
      TT_PRICE_OUT_0 => $FORM{TT_PRICE_OUT_0},
      TT_NETS_0 => $FORM{TT_NETS_0},
      TT_PREPAID_0 => $FORM{TT_PREPAID_0},
      TT_SPEED_0 => $FORM{TT_SPEED_0},

      TT_DESCRIBE_1 => $FORM{'TT_DESCRIBE_1'},
      TT_PRICE_IN_1 => $FORM{TT_PRICE_IN_1},
      TT_PRICE_OUT_1 => $FORM{TT_PRICE_OUT_1},
      TT_NETS_1 => $FORM{TT_NETS_1},
      TT_PREPAID_1 => $FORM{TT_PREPAID_1},
      TT_SPEED_1 => $FORM{TT_SPEED_1},

      TT_DESCRIBE_2 => $FORM{TT_DESCRIBE_2},
      TT_NETS_2 => $FORM{TT_NETS_2},
      TT_SPEED_2 => $FORM{TT_SPEED_2},
      EX_FILE_PATH => "$conf{netsfilespath}"
    });

    if ($tarif_plan->{errno}) {
      message('err', $_ERROR, "[$tarif_plan->{errno}] $err_strs{$tarif_plan->{errno}}");	
     }
    else {
      message('info', $_INFO, "$_INTERVALS");
     }
   }

   my $list = $tarif_plan->tt_list($FORM{ti});
 }
elsif ($FORM{vid}) {
  $FORM{chg}=$FORM{vid};
  form_tp();
  return 0;
 }


Abills::HTML->tpl_show(templates('tt'), $tarif_plan);
	
}


#**********************************************************
# Tarif plans
# form_tp
#**********************************************************
sub form_tp {
 use Tariffs;
 my $tariffs = Tariffs->new($db);
 my $tarif_info;
 my @Octets_Direction = ("$_RECV + $_SEND", $_RECV, $_SEND);
 
 $tarif_info = $tariffs->defaults();
 $tarif_info->{LNG_ACTION}=$_ADD;
 $tarif_info->{ACTION}='add';

 
if ($FORM{chg}) {
  $tarif_info = $tariffs->info( $FORM{chg} );

  if ($tariffs->{errno}) {
    message('err', $_ERROR, "[$tariffs->{errno}] $err_strs{$tariffs->{errno}}");	
    return 0;
   }

print "
<Table width=100% bgcolor=$_COLORS[2]>
<tr><td>$_NAME: <b>$tariffs->{NAME}</b></td></tr>
<tr><td>ID: $tariffs->{VID}</td></tr>
<tr bgcolor=$_COLORS[3]><td>
:: <a href='$SELF_URL?index=70&chg=$tariffs->{VID}'>$_INFO</a> 
:: <a href='$SELF_URL?index=74&vid=$tariffs->{VID}'>$_TRAFIC_TARIFS</a> 
:: <a href='$SELF_URL?index=73&vid=$tariffs->{VID}'>$_INTERVALS</a>
:: <a href='$SELF_URL?index=72&vid=$tariffs->{VID}'>$_NAS</a>
:: <a href='$SELF_URL?index=11&chg=$tariffs->{VID}'>$_USERS</a>
</td></tr>
</table>\n";

  if ($index == 72) {
	  allow_nass( {TP => $tariffs });
    return 0;
   }
  elsif($index == 73) {
	  form_time_intervals( {TP => $tariffs });
    return 0;
   } 
  elsif($index == 74) {
	  form_traf_tarifs( {TP => $tariffs });
    return 0;
   } 
  elsif($FORM{change}) {
    $tariffs->change( $FORM{chg}, { %FORM  } );  
    if (! $tariffs->{errno}) {
       message('info', $_CHANGED, "$_CHANGED $tariffs->{VID}");
     }
   }

  $tarif_info->{LNG_ACTION}=$_CHANGE;
  $tarif_info->{ACTION}='change';
 }
elsif($FORM{add}) {
  $tariffs->add( { %FORM });
  if (! $tariffs->{errno}) {
    message('info', $_ADDED, "$_ADDED $tariffs->{VID}");
   }
}
elsif($FORM{del} && $FORM{is_js_confirmed}) {
  $tariffs->del($FORM{del});

  if (! $tariffs->{errno}) {
    message('info', $_DELETE, "$_DELETED $FORM{del}");
   }
}


if ($tariffs->{errno}) {
    message('err', $_ERROR, "[$tariffs->{errno}] $err_strs{$tariffs->{errno}}");	
 }

my $i=0;
$tarif_info->{SEL_OCTETS_DIRECTION} = "<select name=OCTETS_DIRECTION>\n";
foreach my $line (@Octets_Direction) {
  $tarif_info->{SEL_OCTETS_DIRECTION} .= "<option value=$i";
  $tarif_info->{SEL_OCTETS_DIRECTION} .= ' selected' if ($tarif_info->{OCTETS_DIRECTION} eq $i);
  $tarif_info->{SEL_OCTETS_DIRECTION} .= ">$Octets_Direction[$i]\n";
  $i++;
}
$tarif_info->{SEL_OCTETS_DIRECTION} .= "</select>\n";

Abills::HTML->tpl_show(templates('tp'), $tarif_info);


my $list = $tariffs->list({ %LIST_PARAMS });	
# Time tariff Name Begin END Day fee Month fee Simultaneously - - - 
my $table = Abills::HTML->table( { width => '100%',
                                   border => 1,
                                   title => ['#', $_NAME,  $_BEGIN,  $_END, $_HOUR_TARIF, $_TRAFIC_TARIFS, $_DAY_FEE, $_MONTH_FEE, $_SIMULTANEOUSLY, $_AGE,
                                     '-', '-', '-', '-'],
                                   cols_align => ['right', 'left', 'right', 'right', 'right', 'right', 'right', 'right', 'right', 'right', 'center', 'center', 'center', 'center'],
                                  } );
                                  
                                  
my ($delete, $change);
foreach my $line (@$list) {
  if ($permissions{4}{1}) {
    $delete = $html->button($_DEL, "index=70&del=$line->[0]", "$_DEL ?"); 
    $change = "<a href='$SELF_URL?index=70&chg=$line->[0]'>$_CHANGE</a>";
   }

  $table->addrow("<b>$line->[0]</b>", "<a href='$SELF_URL?index=70&chg=$line->[0]'>$line->[1]</a>", $line->[2], $line->[3], 
   $line->[4], $line->[5], $line->[6], $line->[7], $line->[8], $line->[9], 
   "<a href='$SELF_URL?index=70&tt=$line->[0]'>$_TRAFIC_TARIFS</a>",
   "<a href='$SELF_URL?index=70&ti=$line->[0]'>$_INTERVALS</a>",
   $change,
   $delete);
}

print $table->show();

$table = Abills::HTML->table( { width => '100%',
                                cols_align => ['right', 'right'],
                                rows => [ [ "$_TOTAL:", "<b>$tariffs->{TOTAL}</b>" ] ]
                               } );
print $table->show();

	
}

#**********************************************************
# form_hollidays
#**********************************************************
sub form_holidays {
	my $holidays = Tariffs->new($db);
	
  my %holiday = ();

if ($FORM{add}) {
  my($add_month, $add_day)=split(/-/, $FORM{add});
  $add_month++;

  $holidays->holidays_add({MONTH => $add_month, 
  	              DAY => $add_day
  	             });
  if (! $holidays->{errno}) {
    message('info', $_INFO, "$_ADDED");	
  }
}
elsif($FORM{del}){
  $holidays->holidays_del($FORM{del});

  if (! $holidays->{errno}) {
    message('info', $_INFO, "$_DELETED");	
  }
}

if ($holidays->{errno}) {
    message('err', $_ERROR, "[$holidays->{errno}] $err_strs{$holidays->{errno}}");	
 }


my $list = $holidays->holidays_list( { %LIST_PARAMS });
my $table = Abills::HTML->table( { width => '640',
                                   title => [$_DAY,  $_DESCRIBE, '-'],
                                   cols_align => ['left', 'left', 'center'],
                                  } );
my ($delete); 
foreach my $line (@$list) {
	my ($m, $d)=split(/-/, $line->[0]);
	$m--;
  $delete = $html->button($_DEL, "index=75&del=$line->[0]", "$_DEL ?"); 
  $table->addrow("$d $MONTHES[$m]", $line->[1], $delete);
  $hollidays{$m}{$d}='y';
}

print $table->show();

$table = Abills::HTML->table( { width => '640',
                                cols_align => ['right', 'right'],
                                rows => [ [ "$_TOTAL:", "<b>$holidays->{TOTAL}</b>" ] ]
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
#print  "($sec,$min,$hour,$mday,$mon,$gyear,$gwday,$yday,$isdst)<br>";

print "<p><TABLE width=400 cellspacing=0 cellpadding=0 border=0>
<tr><TD bgcolor=$_COLORS[4]>
<TABLE width=100% cellspacing=1 cellpadding=0 border=0>
<tr bgcolor=$_COLORS[0]><th><a href='$SELF_URL?index=75&month=$p_month&year=$p_year'> << </a></th><th colspan=5>$MONTHES[$month] $year</th><th><a href='$SELF_URL?index=75&month=$n_month&year=$n_year'> >> </a></th></tr>
<tr bgcolor=$_COLORS[0]><th>$WEEKDAYS[1]</th><th>$WEEKDAYS[2]</th><th>$WEEKDAYS[3]</th>
<th>$WEEKDAYS[4]</th><th>$WEEKDAYS[5]</th>
<th><font color=red>$WEEKDAYS[6]</font></th><th><font color=red>$WEEKDAYS[7]</font></th></tr>\n";



my $day = 1;
my $month_days = 31;
while($day < $month_days) {
  print "<tr bgcolor=$_COLORS[1]>";
  for($wday=0; $wday < 7 and $day < $month_days; $wday++) {
     if ($day == 1 && $gwday != $wday) { 
       print "<td>&nbsp</td>";
       if ($wday == 7) {
       	 print "$day == 1 && $gwday != $wday";
       	 return 0;
       	}
      }
     else {
       my $bg = '';
       if ($wday > 4) {
       	  $bg = "bgcolor=$_COLORS[2]";
       	}

       if (defined($holiday{$month}{$day})) {
         print "<th bgcolor=$_COLORS[0]>$day</th>";
        }
       else {
         print "<td align=right $bg><a href='$SELF_URL?index=75&add=$month-$day'>$day</a></td>";
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

my $admin_form = Admins->new($db);
$admin_form->{ACTION}='add';
$admin_form->{LNG_ACTION}=$_ADD;

if ($FORM{aid}) {
  $admin_form->info($FORM{aid});

print "
<Table width=100% bgcolor=$_COLORS[2]>
<tr><td>$_NAME: <b>$admin_form->{A_LOGIN}</b></td></tr>
<tr><td>ID: $admin_form->{AID}</td></tr>
<tr bgcolor=$_COLORS[3]><td>
:: <a href='$SELF_URL?index=50&permissions=y&aid=$admin_form->{AID}'>$_PERMISSION</a> 
:: <a href='$SELF_URL?index=51&aid=$admin_form->{AID}'>$_LOG</a>
:: <a href='$SELF_URL?index=50&password=y&aid=$admin_form->{AID}'>$_PASSWD</a>
:: <a href='$SELF_URL?index=50&aid=$admin_form->{AID}'>$_CHANGE</a>
</td></tr>
</table>\n";

  if ($FORM{permissions}) {
    admin_permissions($admin_form);	
    return 0;
   }
  elsif ($FORM{password}) {
    my $password = chg_password($index, "$FORM{aid}", { AID => $admin_form->{AID}  });
    if ($password ne '0') {
      $admin_form->password($password, { secretkey => $conf{secretkey} } ); 
      if (! $admin_form->{errno}) {
        message('info', $_INFO, "$_ADMINS: $admin_form->{NAME}<br>$_PASSWD $_CHANGED");
      }
     }
    return 0;
   }
  elsif($index == 51) {
    $LIST_PARAMS{AID}=$admin_form->{AID};  	
  	form_changes( { ADMIN => $admin_form } );
  	return 0;
   }
  elsif($FORM{change}) {
    $admin_form->change({
      A_LOGIN => $FORM{A_LOGIN},
      A_FIO   => $FORM{A_FIO},
      DISABLE => $FORM{DISABLE},
      A_PHONE => $FORM{A_PHONE}	
 	  });
 	 }
  else {
    if (! $admin_form->{errno}) {
      message('info', $_INFO, "$_CHANGING [$admin_form->{AID}]");
    }
   }

  $admin_form->{ACTION}='change';
  $admin_form->{LNG_ACTION}=$_CHANGE;
 }
elsif ($FORM{add}) {
  $admin_form->add( {
    A_LOGIN => $FORM{A_LOGIN},
    A_FIO   => $FORM{A_FIO},
    DISABLE => $FORM{DISABLE},
    A_PHONE => $FORM{A_PHONE}	
    } 
  );

  if (! $admin_form->{errno}) {
     message('info', $_INFO, "$_ADDED");	
   }

}
elsif($FORM{del}) {
  $admin_form->del($FORM{del});
  if (! $admin_form->{errno}) {
     message('info', $_DELETE, "$_DELETED");	
   }
}


if ($admin_form->{errno}) {
     message('err', $_ERROR, $err_strs{$admin_form->{errno}});	
 }


$admin_form->{DISABLE} = ($admin_form->{DISABLE} > 0) ? 'checked' : '';
Abills::HTML->tpl_show(templates('form_admin'), $admin_form);

my $table = Abills::HTML->table( { width => '100%',
                                   border => 1,
                                   title => ['ID', $_NAME, $_FIO, $_CREATE, $_GROUPS, '-', '-', '-', '-', '-', '-'],
                                   cols_align => ['right', 'left', 'left', 'right', 'left', 'center', 'center', 'center', 'center', 'center', 'center'],
                                  } );

my $list = $admin_form->list();
foreach my $line (@$list) {
  $table->addrow(@$line, "<a href='$SELF_URL?index=$index&permissions=y&aid=$line->[0]'>$_PERMISSION</a>", 
   "<a href='$SELF_URL?op=changes&aid=$line->[0]'>$_LOG</a>",
   "<a href='$SELF_URL?index=$index&password=y&aid=$line->[0]'>$_PASSWD</a>",
   "<a href='$SELF_URL?index=$index&aid=$line->[0]'>$_CHANGE</a>", $html->button($_DEL, "index=$index&del=$line->[0]", "$_DEL ?"));
}
print $table->show();

$table = Abills::HTML->table( { width => '100%',
                                cols_align => ['right', 'right'],
                                rows => [ [ "$_TOTAL:", "<b>$admin_form->{TOTAL}</b>" ] ]
                               } );
print $table->show();


}







#**********************************************************
# permissions();
#**********************************************************
sub admin_permissions {
 my ($admin) = @_;
 my %permits = ();

 if (defined($FORM{set})) {
   while(my($k, $v)=each(%FORM)) {
     if ($v eq 'yes') {
       my($section_index, $action_index)=split(/_/, $k);
       $permits{$section_index}{$action_index}='y';
      }
    }
   $admin->set_permissions(\%permits);

   if ($admin->{errno}) {
     message('err', $_ERROR, "$err_strs{$admin->{errno}}");
    }
   else {
     message('info', $_INFO, "$_CHANGED");
    }
  }

 my $p = $admin->get_permissions();
 if ($admin->{errno}) {
    message('err', $_ERROR, "$err_strs{$admin->{errno}}");
    return 0;
  }
 my %permits = %$p;
 
print "<form action=$SELF_URL METHOD=POST>
 <input type=hidden name=index value=50>
 <input type=hidden name=aid value='$FORM{aid}'>
 <input type=hidden name=permissions value=set>
 <table width=640>\n";

while(my($k, $v) = each %menu_items ) {
  if (defined($menu_items{$k}{0})) {
    print "<tr bgcolor=$_COLORS[0]><td colspan=3>$k: <b>$menu_items{$k}{0}</b></td></tr>\n";
    $k--;
    my $actions_list = $actions[$k];
    my $action_index = 0;
    foreach my $action (@$actions_list) {
      my $checked = (defined($permits{$k}{$action_index})) ? 'checked' : '';
      print "<tr><td align=right>$action_index</td><td>$action</td><td><input type=checkbox name='$k". "_$action_index' value='yes' $checked></td></tr>\n";
      $action_index++;
     }
   }
 }
  
print "<table>
 <input type=submit name='set' value=\"$_SET\">
</form>\n";
}




#*******************************************************************
# 
# profile()
#*******************************************************************
sub admin_profile {
 my ($admin) = @_;

 my @colors_descr = ('# 0 TH', 
                     '# 1 TD.1',
                     '# 2 TD.2',
                     '# 3 TH.sum, TD.sum',
                     '# 4 border',
                     '# 5',
                     '# 6',
                     '# 7 vlink',
                     '# 8 link',
                     '# 9 Text',
                     '#10 background'
                    );
print "$FORM{colors}";

print "
<form action=$SELF_URL>
<input type=hidden name=index value=$index>
<TABLE width=640 cellspacing=0 cellpadding=0 border=0>
<tr><TD bgcolor=$_BG4>
<TABLE width=100% cellspacing=1 cellpadding=0 border=0>
<tr bgcolor=$_BG1><td colspan=2>$_LANGUAGE:</td>
<td><select name=language>\n";
while(my($k, $v) = each %LANG) {
  print "<option value='$k'";
  print ' selected' if ($k eq $language);
  print ">$v\n";	
}

print "</select></td></tr>
<tr bgcolor=$_BG1><th colspan=3>&nbsp;</th></tr>
<tr bgcolor=$_BG0><th colspan=2>$_PARAMS</th><th>$_VALUE</th></tr>\n";

 for($i=0; $i<=10; $i++) {
   print "<tr bgcolor=FFFFFF><td width=30% bgcolor=$_COLORS[$i]>$i</td><td>$colors_descr[$i]</td><td><input type=text name=colors value='$_COLORS[$i]'></td></tr>\n";
  } 
 
print "</table>
</td></tr></table>
<p><input type=submit name=set value='$_SET'> 
<input type=submit name=default value='$_DEFAULT'>
</form>\n";
   
my %profiles = ();
$profiles{'Black'} = "#333333, #000000, #444444, #555555, #777777, #FFFFFF, #FFFFFF, #BBBBBB, #FFFFFF, #EEEEEE, #000000";
$profiles{'Green'} = "#33AA44, #FFFFFF, #eeeeee, #dddddd, #E1E1E1, #FFFFFF, #FFFFFF, #000088, #0000A0, #000000, #FFFFFF";
$profiles{'НУ'} = "#FCBB43, #FFFFFF, #eeeeee, #dddddd, #E1E1E1, #FFFFFF, #FFFFFF, #000088, #0000A0, #000000, #FFFFFF";
$profiles{'Cisco'} = "#99CCCC, #FFFFFF, #FFFFFF, #669999, #669999, #FFFFFF, #FFFFFF, #003399, #003399, #000000, #FFFFFF";

while(my($thema, $colors)=each %profiles ) {
  print "<a href='$SELF?op=profile&set=set";
  my @c = split(/, /, $colors);
  foreach my $line (@c) {
      $line =~ s/#/%23/ig;
      print "&colors=$line";
    }
  print "'>$thema</a> ::";
}

 return 0;
}


#**********************************************************
# form_nas
#**********************************************************
sub form_nas {
  my $nas = Nas->new($db);	
  $nas->{ACTION}='add';
  $nas->{LNG_ACTION}=$_ADD;


if($FORM{nid}) {
  $nas->info($FORM{nid}, { SECRETKEY => $conf{secretkey} });

print "<Table width=100% bgcolor=$_COLORS[2]>
<tr><td>$_NAME: <b>$nas->{NAS_NAME}</b></td></tr>
<tr><td>ID: $nas->{NID}</td></tr>
<tr bgcolor=$_COLORS[3]><td>
:: <a href='$SELF_URL?index=61&nid=$nas->{NID}'>IP POOLs</a> 
:: <a href='$SELF_URL?index=60&nid=$nas->{NID}'>$_CHANGE</a>
</td></tr>
</table>\n";

  if ($index == 61) {
     form_ip_pools({ NAS => $nas });
     return 0;  	
   }
  elsif ($FORM{change}) {
  	$nas->change({
      NAS_NAME => $FORM{NAS_NAME}, 
      NAS_INDENTIFIER => $FORM{NAS_INDENTIFIER}, 
      NAS_DESCRIBE => $FORM{NAS_DESCRIBE}, 
      NAS_IP => $FORM{NAS_IP}, 
      NAS_TYPE => $FORM{NAS_TYPE}, 
      NAS_AUTH_TYPE => $FORM{NAS_AUTH_TYPE}, 
      NAS_MNG_IP_PORT => $FORM{NAS_MNG_IP_PORT}, 
      NAS_MNG_USER => $FORM{NAS_MNG_USER}, 
      NAS_MNG_PASSWORD => $FORM{NAS_MNG_PASSWORD}, 
      NAS_RAD_PAIRS => $FORM{NAS_RAD_PAIRS},
      SECRETKEY => $conf{secretkey}
  		});
    if (! $nas->{errno}) {
      message('info', $_INFO, "$_CHANGED '$nas->{NAS_NAME}' [$nas->{NID}]");
     }
   }

  $nas->{ACTION}='change';
  $nas->{LNG_ACTION}=$_CHANGE;
 }
elsif ($FORM{add}) {
  $nas->add({
      NAS_NAME => $FORM{NAS_NAME}, 
      NAS_INDENTIFIER => $FORM{NAS_INDENTIFIER}, 
      NAS_DESCRIBE => $FORM{NAS_DESCRIBE}, 
      NAS_IP => $FORM{NAS_IP}, 
      NAS_TYPE => $FORM{NAS_TYPE}, 
      NAS_AUTH_TYPE => $FORM{NAS_AUTH_TYPE}, 
      NAS_MNG_IP_PORT => $FORM{NAS_MNG_IP_PORT}, 
      NAS_MNG_USER => $FORM{NAS_MNG_USER}, 
      NAS_MNG_PASSWORD => $FORM{NAS_MNG_PASSWORD}, 
      NAS_RAD_PAIRS => $FORM{NAS_RAD_PAIRS},
      SECRETKEY => $conf{secretkey}
  		});
 
  if (! $nas->{errno}) {
    message('info', $_INFO, "$_ADDED '$FORM{NAS_IP}'");
   }
 }
elsif ($FORM{del} && $FORM{is_js_confirmed}) {
  $nas->del($FORM{del});
  if (! $nas->{errno}) {
    message('info', $_INFO, "$_DELETED [$FORM{del}]");
   }

}

if ($nas->{errno}) {
  message('err', $_ERROR, "$err_strs{$nas->{errno}}");
 }

 my @nas_types = ('other', 'usr', 'pm25', 'ppp', 'exppp', 'radpppd', 'expppd', 'pppd', 'dslmax', 'mpd');
 my %nas_descr = ('usr' => "USR Netserver 8/16",
  'pm25' => 'LIVINGSTON portmaster 25',
  'ppp' => 'FreeBSD ppp demon',
  'exppp' => 'FreeBSD ppp demon with extended futures',
  'dslmax' => 'ASCEND DSLMax',
  'expppd' => 'pppd deamon with extended futures',
  'radpppd' => 'pppd version 2.3 patch level 5.radius.cbcp',
  'mpd' => 'MPD ',
  'ipcad' => 'IP accounting daemon with Cisco-like ip accounting export',
  'pppd' => 'pppd + RADIUS plugin (Linux)',
  'other' => 'Other nas server');

  foreach my $nt (@nas_types) {
     $nas->{SEL_TYPE} .= "<option value=$nt";
     $nas->{SEL_TYPE} .= ' selected' if ($nas->{NAS_TYPE} eq $nt);
     $nas->{SEL_TYPE} .= ">$nt ($nas_descr{$nt})\n";
   }

  my $i = 0;
  foreach my $at (@auth_types) {
     $nas->{SEL_AUTH_TYPE} .= "<option value=$i";
     $nas->{SEL_AUTH_TYPE} .= ' selected' if ($nas->{NAS_AUTH_TYPE} eq $i);
     $nas->{SEL_AUTH_TYPE} .= ">$at\n";
     $i++;
   }

Abills::HTML->tpl_show(templates('form_nas'), $nas);

    
my $table = Abills::HTML->table( { width => '100%',
                                   border => 1,
                                   title => ["ID", "$_NAME", "NAS-Identifier", "IP", "$_TYPE", "$_AUTH", '-', '-', '-'],
                                   cols_align => ['center', 'left', 'left', 'right', 'left', 'left'],
                                  } );

my $list = $nas->list({ %LIST_PARAMS });

foreach my $line (@$list) {
  my $delete = $html->button($_DEL, "index=60&del=$line->[0]", "$_DEL NAS $line->[2]?"); 
  $table->addrow($line->[0], $line->[2], $line->[1], 
    $line->[4], $line->[5], $auth_types[$line->[6]], 
    "<a href='$SELF_URL?index=61&nid=$line->[0]'>IP POOLs</a>",
    "<a href='$SELF_URL?index=60&nid=$line->[0]'>$_CHANGE</a>",
    $delete);
}
print $table->show();

$table = Abills::HTML->table( { width => '100%',
                                cols_align => ['right', 'right'],
                                rows => [ [ "$_TOTAL:", "<b>$nas->{TOTAL}</b>" ] ]
                               } );
print $table->show();
}

#**********************************************************
# form_ip_pools()
#**********************************************************
sub form_ip_pools {
	my ($attr) = @_;
	my $nas;
  my ($pages_qs);
  
if ($attr->{NAS}) {
	$nas = $attr->{NAS};
  if ($FORM{add}) {
    $nas->ip_pools_add( {
       NAS_IP_SIP => $FORM{NAS_IP_SIP},
       NAS_IP_COUNT => $FORM{NAS_IP_COUNT}
     });

    if (! $nas->{errno}) {
       message('info', $_INFO, "$_ADDED");
     }
   }
  elsif($FORM{del}) {
    $nas->ip_pools_del( $FORM{del} );

    if (! $nas->{errno}) {
       message('info', $_INFO, "$_DELETED");
     }
   }
  $pages_qs = "&nid=$nas->{NID}";

  Abills::HTML->tpl_show(templates('form_ip_pools'), $nas);
 }
elsif($FORM{nid}) {
  form_nas();
  return 0;
}
else {
  $nas = Nas->new($db);	
}

if ($nas->{errno}) {
  message('err', $_ERROR, "$err_strs{$nas->{errno}}");
 }



    
my $table = Abills::HTML->table( { width => '100%',
                                   border => 1,
                                   title => ["NAS", "$_BEGIN", "$_END", "$_COUNT", '-'],
                                   cols_align => ['left', 'right', 'right', 'right', 'center'],
                                   qs => $pages_qs              
                                  } );

my $list = $nas->ip_pools_list({ %LIST_PARAMS });	

foreach my $line (@$list) {
  my $delete = $html->button($_DEL, "index=61$pages_qs&del=$line->[6]", "$_DEL NAS $line->[4]?"); 
  $table->addrow("<a href='$SELF_URL?index=60&nid=$line->[7]'>$line->[0]</a>", $line->[4], $line->[5], 
    $line->[3],  $delete);
}
print $table->show();
}

#**********************************************************
# form_nas_stats()
#**********************************************************
sub form_nas_stats {
my $nas = Nas->new($db);	

my $table = Abills::HTML->table( { width => '100%',
                                   border => 1,
                                   title => ["NAS", "NAS_PORT", "$_SESSIONS", "$_LAST_LOGIN", "$_AVG", "$_MIN", "$_MAX"],
                                   cols_align => ['left', 'right', 'right', 'right', 'right', 'right', 'right'],
                                  } );
my $list = $nas->stats({ %LIST_PARAMS });	

foreach my $line (@$list) {
  $table->addrow("<a href='$SELF_URL?index=60&nid=$line->[7]'>$line->[0]</a>", 
     $line->[1], $line->[2],  $line->[3],  $line->[4], $line->[5], $line->[6] );
}

print $table->show();
}


#**********************************************************
# stats
#**********************************************************
sub form_stats {
	my ($attr) = @_;
	my $pages_qs;
  my $uid;
 
if (defined($attr->{USER}))	{
	my $user = $attr->{USER};
	$pages_qs = "&uid=$user->{UID}";
	$uid = $user->{UID};
	$LIST_PARAMS{LOGIN} = $user->{LOGIN};
	if (! defined($FORM{sort})) {
	  $LIST_PARAMS{SORT}=2;
	  $LIST_PARAMS{DESC}=DESC;
   }
}
elsif($FORM{uid}) {
	form_users();
	return 0;
}	
	
use Sessions;
my $sessions = Sessions->new($db);


if ($FORM{rows}) {
  $LIST_PARAMS{PAGE_ROWS}=$FORM{rows};
  $conf{list_max_recs}=$FORM{rows};
  $pages_qs .= "&rows=$conf{list_max_recs}";
 }


#PEriods totals
my $list = $sessions->periods_totals({ %LIST_PARAMS });
my $table = Abills::HTML->table( { width => '100%',
                                   title_plain => ["$_PERIOD", "$_DURATION", "$_SEND", "$_RECV", "$_SUM"],
                                   cols_align => ['left', 'right', 'right', 'right', 'right'],
                                   rowcolor => $_COLORS[1]
                                  } );
for(my $i = 0; $i < 5; $i++) {
	  $table->addrow("<a href='$SELF_URL?index=$index&period=$i$pages_qs'>$PERIODS[$i]</a>", "$sessions->{'duration_'. $i}",
	  int2byte($sessions->{'sent_'. $i}), int2byte($sessions->{'recv_'. $i}), int2byte($sessions->{'sum_'. $i}));
 }
print $table->show();


print "<form action=$SELF_URL>
<input type=hidden name=index value='$index'>
<input type=hidden name=uid value='$uid'>\n";

my $table = Abills::HTML->table( { width => '640',
	                                 rowcolor => $_COLORS[0],
                                   title_plain => [ "$_FROM: ", Abills::HTML->date_fld('from', { MONTHES => \@MONTHES} ),
                                   "$_TO: ", Abills::HTML->date_fld('to', { MONTHES => \@MONTHES } ),
                                   "$_ROWS: ",  "<input type=text name=rows value='$conf{list_max_recs}' size=4>",
                                   "<input type=submit name=show value=$_SHOW>"
                                    ],                                   
                                  } );
print $table->show();
print "</form>\n";

stats_calculation($sessions);

if (defined($FORM{show})) {
  $pages_qs .= "&show=y&fromd=$FORM{fromd}&fromm=$FORM{fromm}&fromy=$FORM{fromy}&tod=$FORM{tod}&tom=$FORM{tom}&toy=$FORM{toy}";
  $FORM{fromm}++;
  $FORM{tom}++;
  $FORM{fromm} = sprintf("%.2d", $FORM{fromm}++);
  $FORM{tom} = sprintf("%.2d", $FORM{tom}++);
  $LIST_PARAMS{INTERVAL} = "$FORM{fromy}-$FORM{fromm}-$FORM{fromd}/$FORM{toy}-$FORM{tom}-$FORM{tod}";
 }
elsif ($FORM{period}) {
	$LIST_PARAMS{PERIOD} = $FORM{period}; 
	$pages_qs .= "&period=$FORM{period}";
}

if (! defined($FORM{sort})) {
  $LIST_PARAMS{SORT}=2;
  $LIST_PARAMS{DESC}=DESC;
 }

#Session List
my $list = $sessions->list({ %LIST_PARAMS });	

$table = Abills::HTML->table( { width => '640',
	                              rowcolor => $_COLORS[1],
                                title => ["$_SESSIONS", "$_DURATION", "$_TRAFFIC", "$_SUM"],
                                cols_align => ['right', 'right', 'right', 'right'],
                                rows => [ [ $sessions->{TOTAL}, $sessions->{DURATION}, int2byte($sessions->{TRAFFIC}), $sessions->{SUM} ] ],
                               } );
print $table->show();

show_sessions($list, $sessions);
}


#**********************************************************
# Whow sessions from log
# show_sessions()
#**********************************************************
sub show_sessions {
 my ($list, $sessions) = @_;
#Session List

if (! $list) {
  if (! defined($FORM{sort})) {
	  $LIST_PARAMS{SORT} = 2;
	  $LIST_PARAMS{DESC} = 'DESC';
  }
  use Sessions;
  $sessions = Sessions->new($db);
  $list = $sessions->list({ %LIST_PARAMS });	
}



my $table = Abills::HTML->table( { width => '100%',
                                border => 1,
                                title => ["$_USER", "$_START", "$_DURATION", "$_TARIF_PLAN", "$_SENT", "$_RECV", 
                                "CID", "NAS", "IP", "$_SUM", "-", "-"],
                                cols_align => ['left', 'right', 'right', 'left', 'right', 'right', 'right', 'right', 'right', 'right', 'center'],
                                qs => $pages_qs,
                                pages => $sessions->{TOTAL},
                                recs_on_page => $LIST_PARAMS{PAGE_ROWS}
                               } );
my $delete = '';
foreach my $line (@$list) {
  $delete = '';
  $table->addrow("<a href='$SELF_URL?index=11&login=$line->[0]'>$line->[0]</a>", 
     $line->[1], $line->[2],  $line->[3],  int2byte($line->[4]), int2byte($line->[5]), $line->[6],
     $line->[7], $line->[10], $line->[9], 
     "(<a href=$SELF_URL?index=23&uid=$user->{UID}&sid=$line->[11] title='Session Detail'>D</a>)", $delete);
}
print $table->show();
}


#*******************************************************************
#
#*******************************************************************
sub form_last {
	
	
}

#*******************************************************************
# WHERE period
# base_state($where, $period);
#*******************************************************************
sub stats_calculation  {
 my ($sessions) = @_;

$sessions->calculation({ %LIST_PARAMS }); 
my $table = Abills::HTML->table( { width => '640',
	                              rowcolor => $_COLORS[1],
                                title_plain => ["-", "$_MIN", "$_MAX", "$_AVG"],
                                cols_align => ['left', 'right', 'right', 'right'],
                                rows => [ [ $_DURATION,  $sessions->{min_dur}, $sessions->{max_dur}, $sessions->{avg_dur} ],
                                          [ "$_TRAFFIC $_RECV", int2byte($sessions->{min_recv}), int2byte($sessions->{max_recv}), int2byte($sessions->{avg_recv}) ],
                                          [ "$_TRAFFIC $_SENT", int2byte($sessions->{min_sent}), int2byte($sessions->{max_sent}), int2byte($sessions->{avg_sent}) ],
                                          [ "$_TRAFFIC $_SUM",  int2byte($sessions->{min_sum}),  int2byte($sessions->{max_sum}),  int2byte($sessions->{avg_sum}) ]
                                        ]
                               } );
print $table->show();
}

#**********************************************************
# session_detail
#**********************************************************
sub session_detail {
	my ($attr) = @_;
	my $pages_qs;
 
if (defined($attr->{USER}))	{
	my $user = $attr->{USER};
	$pages_qs = "&uid=$user->{UID}";
	
}
elsif($FORM{uid}) {
	form_users();
	return 0;
}	

	
}


#**********************************************************
# Reports
#**********************************************************
sub reports {
	
}

#**********************************************************
# form_error
#**********************************************************
sub form_error {
	my ($attr) = @_;
  my $rows = 100;
  my $logfile = "/usr/abills/var/log/abills.log";
  my $login  = ''; 
  my $log_type = $FORM{log_type} || '';

if ($attr->{USER}) {
  my $user = $attr->{USER};
  $login = $user->{LOGIN};
}
elsif($FORM{uid}) {
  form_users();
  return 0;
}

my ($list, $types, $totals) = show_log("$login", $log_type, "$logfile", $rows);
my $table = Abills::HTML->table( { width => '100%' } );
foreach my $line (@$list) {
  if ($line =~ m/LOG_WARNING/i) {
    $line = "<font color=red>$line</font>";
   }
  
  $table->addrow($line);
}
print $table->show();


my $table = Abills::HTML->table( { width => '100%' } );
foreach my $line (@$list) {
  if ($line =~ m/LOG_WARNING/i) {
    $line = "<font color=red>$line</font>";
   }
  $table->addrow($line);
}
print $table->show(). "<p>\n";


$table = Abills::HTML->table( { width => '100%',
	                              cols_align => ['right', 'right'] } );

$table->addrow("<a href='$SELF_URL?index=40&$pages_qs'>$_TOTAL:</a>", $totals);
while(my($k,$v)=each %$types) {
  $table->addrow("<a href='$SELF_URL?index=40&log_type=$k&$pages_qs'>$k</a>", $v);
}
print $table->show();



}


#**********************************************************
# chg_password($op, $id)
#**********************************************************
sub chg_password {
 my ($index, $id, $attr)=@_;
 print "<h3>$_CHANGE_PASSWD</h3>\n";
 my $hidden_inputs;
 
 $hidden_inputs = (defined($attr->{AID})) ? "<input type=hidden name=aid value='$attr->{AID}'>" : '';

 if (defined($attr->{UID})) {
	 $hidden_inputs = "<input type=hidden name=uid value='$attr->{UID}'>";
 }

if ($FORM{newpassword} eq '') {

}
elsif (length($FORM{newpassword}) < $conf{passwd_length}) {
  message('err', $_ERROR, $err_strs{6});
}
elsif ($FORM{newpassword} eq $FORM{confirm}) {
  return $FORM{newpassword};
}
elsif($FORM{newpassword} ne $FORM{confirm}) {
  message('err', $_ERROR, $err_strs{5});
}

use Abills::Base;
my $gen_password=mk_unique_value(8);

print << "[END]";
<form action=$SELF_URL >
<input type=hidden name=index value=$index>
<input type=hidden name=password value=$id>
$hidden_inputs
<table>
<tr><td>$_GENERED_PARRWORD:</td><td>$gen_password</td></tr>
<tr><td>$_PASSWD:</td><td><input type=password name=newpassword value='$gen_password'></td></tr>
<tr><td>$_CONFIRM_PASSWD:</td><td><input type=password name=confirm value='$gen_password'></td></tr>
</table>
<input type=submit name=change value="$_CHANGE">
</form>
[END]

 return 0;
}



#**********************************************************
# mk_navigator()
#**********************************************************
sub mk_navigator  {
 my $menu_navigator = "";


# ID:PARENT:NAME:FUNCTION:SHOW SUBMENU:OP:

my @m = ("1:0:$_CUSTOMERS:form_customers:0:customers:",
 "11:1:$_USERS:form_users:1:users:",
 "12:11:$_ADD:user_form:1::",
 "13:1:$_COMPANY:form_accounts:1::",
 "14:13:$_ADD:add_account:1::",
 
 "15:11:$_LOG:form_changes:0:changes:",
 "16:11:$_TARIF_PLAN:form_chg_tp:0::",
 "17:11:$_PASSWD:password:0:password:",
 "18:11:$_NAS:allow_nass:0::",
 "20:11:$_SEVICES:user_services:0::",
 "21:11:$_COMPANY:form_users:0::",
 "22:11:$_STATS:form_stats:1::",
 "23:11:$_DEATAIL:session_detail:0::",
 "27:1:$_GROUPS:form_groups:1::",
 "28:27:$_ADD:add_groups:1::",
 "29:27:$_LIST:form_groups:1::",

 "2:0:$_PAYMENTS:form_payments:1:payments:",
 "3:0:$_FEES:form_fees:1:fees:",
 "4:0:$_REPORTS:reports:1:reports:",
 "40:4:$_ERROR:form_error:1::",
 "41:4:$_LAST:show_sessions:1::",

 "5:0:$_SYSTEM:system:1:system:",
 "50:5:$_ADMINS:form_admins:1::",
 "51:5:$_LOG:form_changes:1::",
 "52:50:$_PERMISSION:admin_permisions:0::",
 "53:5:$_PROFILE:admin_profile:1::",
 
 "60:5:$_NAS:form_nas:1::",
 "61:60:IP POOLs:form_ip_pools:1::",
 "62:60:$_NAS_STATISTIC:form_nas_stats:1::",

 "65:5:$_EXCHANGE_RATE:exchange_rate:1::",
 "70:5:$_TARIF_PLANS:form_tp:1::",
 "71:70:$_ADD:form_tp:1::",
 "72:70:$_NASS:allow_nass:0::",
 "73:70:$_INTERVALS:form_time_intervals:0::",
 "74:70:$_TRAFIC_TARIFS:form_traf_tarifs:0::",
 "75:5:$_HOLIDAYS:form_holidays:0::",

 
 "85:5:$_SHEDULE:form_shedule:1::",
 "99:5:$_FUNCTIONS_LIST:flist:1::",
 "100:5:$_SEARCH:form_search:1::",
 
 "6:0:$_MODULES:modules:1:modules:",
 "999:6:$_TEST:test:1:test:",
 "1000:6:$_DOCS ::1:test:",
 "1001:6:Postfix::1:test:",
 "1002:6:SQL_COMMANDER::1:test:",
 "8:0:Profile::1:test:"
 
 );


foreach my $line (@m) {
	my ($ID, $PARENT, $NAME, $FUNTION_NAME, $SHOW_SUBMENU, $OP)=split(/:/, $line);
  $menu_items{$ID}{$PARENT}=$NAME;
  $functions{$ID}=\&$FUNTION_NAME if ($FUNTION_NAME  ne '');
  $show_submenu{$ID}='y' if ($SHOW_SUBMENU == 1);
  $op_names{$ID}=$OP if ($OP ne '');
}
my $root_index = 0;
if ($index == 0 && $OP ne '') {
   my %functions_index = reverse(%op_names);
   $index = $functions_index{$OP};
 }	

# make navigate line 
if ($index > 0) {
  my $h;
  $root_index = $index;	

  $h = $menu_items{$root_index};
  while(my ($par_key, $name) = each ( %$h )) {
    $menu_navigator =  " <a href='$SELF_URL?index=$root_index'>$name</a> /" . $menu_navigator;
    if ($par_key > 0) {
      $root_index = $par_key;
      $h = $menu_items{$par_key};
     }
  }
}

if (defined($FORM{op}) && $FORM{op} eq '') {
   $OP = $op_names{$root_index};
  }
$FORM{op} = $op_names{$root_index};

if ($root_index > 0) {
  my $ri = $root_index-1;
  if (! defined($permissions{$ri})) {
	  message('err', $_ERROR, "Access deny");
#	  exit 0;
   }
}

my %main_menu = ();
my %submenu = ();

while(my($section, $v)=each %permissions) {
  $section++;
  $main_menu{$section.'::'. $op_names{$section} .':'.$section} = $menu_items{$section}{0};

  if ($root_index == $section) {
    while(my($id, $v)=each %menu_items) {
	    while(my($k, $v)=each %$v) {
	 	    if ($k == $root_index) {
	 	      $submenu{$id}=$v ;
	 	     }
	    }
     }
    $main_menu{$section.'::'. $op_names{$section} .':'.$section}{sm}=\%submenu;
   }
}

return  \%main_menu, \%submenu, "/".$menu_navigator;
}























#**********************************************************
#
#**********************************************************
sub flist {

my  %new_hash = ();
while((my($findex, $hash)=each(%menu_items))) {
  while(my($k, $val)=each %$hash) {
    $new_hash{$k}{$findex}=$val;
   }
}

my $h = $new_hash{0};
my @last_array = ();

my @menu_sorted = sort {
   $h->{$b} <=> $h->{$a}
     ||
   length($a) <=> length($b)
     ||
   $a cmp $b
} keys %$h;

my $out;

foreach my $parent (@menu_sorted) { 
  my $val = $h->{$parent};
  my $level = 0;
  my $prefix = '';

  $val = ($index eq $parent) ?  "<b>$val</b>" : $val;
  $out .= "$level: <a href='$SELF?index=$parent'>$val</a><br>\n";

  if (defined($new_hash{$parent})) {
    $level++;
    $prefix .= "&nbsp;&nbsp;&nbsp;";
    label:
      my $mi = $new_hash{$parent};

      while(my($k, $val)=each %$mi) {
      	$val = ($index eq $k) ?  "<b>$val</b>" : $val;
        $out .= "<input type=checkbox name=qm_item value=$k> $prefix $level: <a href='$SELF_URL?index=$k'>$val</a><br>\n";
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
#      print "POP/$#last_array/$parent/<br>\n";
      $level--;
      
      $prefix = substr($prefix, 0, $level * 6 * 3);
      goto label;
    }
    delete($new_hash{0}{$parent});
   }
}
print "<table width=100%><tr><td>\n
$out
</td></tr></table>\n";
}


#**********************************************************
# sub_menu($root_index)
#
#**********************************************************
sub sub_menu {
  my $root_index = shift;
  
  return 0 if ($root_index < 1);
  
print "<br><hr>\n";
my %new_hash = ();
my %sub_menus = ();
while((my($findex, $hash)=sort each(%menu_items))) {
  while(my($k, $val)=each %$hash) {
    $new_hash{$k}{$findex}=$val;
   }
}

  if (defined($new_hash{$root_index})) {
    $level++;
    $prefix .= "&nbsp;&nbsp;&nbsp;";
    label:
      my $mi = $new_hash{$root_index};

      while(my($k, $val)=each %$mi) {
      	$val = ($index eq $k) ?  "<b>$val</b>" : $val;
        print "$prefix $level: <a href='$SELF_URL?index=$k'>$val</a><br>\n";
        
        $sub_menus{$k}="$val" if (defined($show_submenu{$k}) && $level  == 1);

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
#      print "POP/$#last_array/$parent/<br>\n";
      $level--;
      
      $prefix = substr($prefix, 0, $level * 6 * 3);
      goto label;
    }
    delete($new_hash{0}{$parent});
   }


	return \%sub_menus;
}


#**********************************************************
# form_payments
#**********************************************************
sub form_payments () {
 my ($attr) = @_; 
 use Finance;
 my $payments = Finance->payments($db, $admin);

if (defined($attr->{USER})) { 
  my $user = $attr->{USER};
  $payments->{UID} = $user->{UID};

  if ($FORM{add} && $FORM{SUM})	{
    my $er = $payments->exchange_info($FORM{ER});
    $FORM{ER} = $er->{EX_RATE};
    $payments->add($user, { %FORM } );  

    if ($payments->{errno}) {
      message('err', $_ERROR, "[$payments->{errno}] $err_strs{$payments->{errno}}");	
     }
    else {
      message('info', $_PAYMENTS, "$_ADDED");
     }
   }
  elsif($FORM{del} && $FORM{is_js_confirmed}) {
  	if (! defined($permissions{1}{3})) {
      message('err', $_ERROR, "[13] $err_strs{13}");
      return 0;		
	   }

	  $payments->del($user, $FORM{del});
    if ($payments->{errno}) {
      message('err', $_ERROR, "[$payments->{errno}] $err_strs{$payments->{errno}}");	
     }
    else {
      message('info', $_PAYMENTS, "$_DELETED");
     }
   }

#exchange rate sel

my ($er, $total) = $payments->exchange_list();
$payments->{SEL_ER} = "<select name=ER>\n";
foreach my $line (@$er) {
  $payments->{SEL_ER} .= "<option value=$line->[4]";
  $payments->{SEL_ER} .= ">$line->[1] : $line->[2]\n";
}
$payments->{SEL_ER} .= "</select>\n";


my $i=0;

$payments->{SEL_METHOD} = "<select name=METHOD>\n";
foreach my $line (@PAYMENT_METHODS) {
  $payments->{SEL_METHOD} .= "<option value=$i";
  $payments->{SEL_METHOD} .= ">$line\n";
  $i++;
}
$payments->{SEL_METHOD} .= "</select>\n";


Abills::HTML->tpl_show(templates('form_payments'), $payments);
}
elsif ($FORM{uid}) {
	 form_users();
	 return 0;
 }



if (! defined($permissions{1}{2})) {
  return 0;
}

	if (! defined($FORM{sort})) {
	  $LIST_PARAMS{SORT}=1;
	  $LIST_PARAMS{DESC}=DESC;
   }


my $list = $payments->list( { %LIST_PARAMS } );
my $table = Abills::HTML->table( { width => '100%',
                                   border => 1,
                                   title => ['ID', $_LOGIN, $_DATE, $_SUM, $_DESCRIBE, $_ADMINS, 'IP',  $_DEPOSIT, $_PAYMENT_METHOD, '-'],
                                   cols_align => ['right', 'left', 'right', 'right', 'left', 'left', 'right', 'right', 'left', 'center'],
                                   qs => $pages_qs,
                                   pages => $payments->{TOTAL}
                                  } );


foreach my $line (@$list) {
  my $delete = ($permissions{1}{3}) ?  $html->button($_DEL, "op=payments&del=$line->[0]&uid=$line->[9]", "$_DEL ?") : ''; 
  $table->addrow("<b>$line->[0]</b>", "<a href='$SELF_URL?op=users&uid=$line->[8]'>$line->[1]</a>", $line->[2], 
   $line->[3], $line->[4],  "$line->[5]", "$line->[6]", "$line->[7]", $PAYMENT_METHODS[$line->[8]], $delete);
}

print $table->show();

$table = Abills::HTML->table( { width => '100%',
                                cols_align => ['right', 'right', 'right', 'right'],
                                rows => [ [ "$_TOTAL:", "<b>$payments->{TOTAL}</b>", "$_SUM", "<b>$payments->{SUM}</b>" ] ],
                                rowcolor => $_COLORS[2]
                               } );
print $table->show();
}

#*******************************************************************
# exchange_rate
#*******************************************************************
sub exchange_rate {
 my @action = ('add', "$_ADD");
 my $short_name = $FORM{short_name} || '-';
 my $money = $FORM{money} || '-';
 my $rate  = $FORM{rate} || '0.0000';
 
 
 use Finance;
 my $finance = Finance->new($db, $admin);


if ($FORM{add}) {
	$finance->exchange_add($money, $short_name, $rate);
  if ($finance->{errno}) {
    message('err', $_ERROR, "[$finance->{errno}] $err_strs{$finance->{errno}}");	
   }
  else {
    message('info', $_EXCHANGE_RATE, "$_ADDED");
   }
}
elsif($FORM{change}) {
	$finance->exchange_change("$FORM{chg}", $money, $short_name, $rate);
  if ($finance->{errno}) {
    message('err', $_ERROR, "[$finance->{errno}] $err_strs{$finance->{errno}}");	
   }
  else {
    message('info', $_EXCHANGE_RATE, "$_CHANGED");

   }
}
elsif($FORM{chg}) {
	$finance->exchange_info("$FORM{chg}");
  if ($finance->{errno}) {
    message('err', $_ERROR, "[$finance->{errno}] $err_strs{$finance->{errno}}");	
   }
  else {
  	@action = ('change', $_CHANGE);
    message('info', $_EXCHANGE_RATE, "$_CHANGING");
   }
}
elsif($FORM{del}) {
	$finance->exchange_del("$FORM{del}");
  if ($finance->{errno}) {
    message('err', $_ERROR, "[$finance->{errno}] $err_strs{$finance->{errno}}");	
   }
  else {
    message('info', $_EXCHANGE_RATE, "$_DELETED");
   }

}
	
print << "[END]";
<form action=$SELF_URL>
<input type=hidden name=op   value=er>
<input type=hidden name=chg   value="$FORM{chg}"> 
<table>
<tr><td>$_MONEY:</td><td><input type=text name=money value='$finance->{MU_NAME}'></td></tr>
<tr><td>$_SHORT_NAME:</td><td><input type=text name=short_name value='$finance->{MU_SHORT_NAME}'></td></tr>
<tr><td>$_EXCHANGE_RATE:</td><td><input type=text name=rate value='$finance->{EX_RATE}'></td></tr>
</table>
<input type=submit name=$action[0] value='$action[1]'>
</form>
[END]

my $table = Abills::HTML->table( { width => '640',
                                   title => ["$_MONEY", "$_SHORT_NAME", "$_EXCHANGE_RATE (1 unit =)", "$_CHANGED", '-', '-'],
                                   cols_align => ['left', 'left', 'right', 'center', 'center'],
                                  } );

my ($list, $total) = $finance->exchange_list( {%LIST_PARAMS} );
foreach my $line (@$list) {
  $table->addrow($line->[0], $line->[1], $line->[2], $line->[3], "<a href='$SELF_URL?op=er&chg=$line->[4]'>$_CHANGE</a>", 
     $html->button($_DEL, "op=er&del=$line->[4]", "$_DEL ?"));
}
print $table->show();
}



#*******************************************************************
# form_fees
#*******************************************************************
sub form_fees  {
 my ($attr) = @_;
 my $period = $FORM{period} || 0;
 
 use Finance;
 my $fees = Finance->fees($db, $admin);

if (defined($attr->{USER})) {
  my $user = $attr->{USER};

  if ($FORM{get} && $FORM{sum}) {
    # add to shedule
    if ($period == 1) {
      use Shedule;
      $FORM{date_m}++;
      my $shedule = Shedule->new($db, $admin); 
      $shedule->add( { DESCRIBE => $FORM{DESCR}, 
      	               D => $FORM{date_d},
      	               M => $FORM{date_m},
      	               Y => $FORM{date_y},
                       UID => $user->{UID},
                       TYEP => 'fees',
                       ACTION => "$FORM{sum}:$FORM{descr}"
                      } );
     }
    #Add now
    else {
      $fees->get($user, $FORM{sum}, { DESCRIBE => $FORM{descr} } );  
      if ($fees->{errno}) {
        message('err', $_ERROR, "[$fees->{errno}] $err_strs{$fees->{errno}}");	
       }
      else {
        message('info', $_PAYMENTS, "$_ADDED");
       }
    }
   }
  elsif ($FORM{del} && $FORM{is_js_confirmed}) {
  	if (! defined($permissions{2}{3})) {
      message('err', $_ERROR, "[13] $err_strs{13}");
      return 0;		
	   }

	  $fees->del($user,  $FORM{del});
    if ($fees->{errno}) {
      message('err', $_ERROR, "[$fees->{errno}] $err_strs{$fees->{errno}}");
     }
    else {
      message('info', $_DELETED, "$_DELETED [$FORM{del}]");
    }
   }


my $period_form=form_period($period);
print << "[END]";
<form action=$SELF_URL>
<input type=hidden name=uid value='$user->{UID}'>
<input type=hidden name=op value='fees'>
<table>
<tr><td>$_SUM:</td><td><input type=text name=sum></td></tr>
<tr><td>$_DESCRIBE:</td><td><input type=text name=descr></td></tr>
$period_form
</table>
<input type=submit name=get value='$_GET'>
</form>
[END]
}	
elsif ($FORM{uid}) {
	form_users();
	return 0;
 }



if (! defined($permissions{2}{2})) {
  return 0;
}


my ($list) = $fees->list( { %LIST_PARAMS } );
my $table = Abills::HTML->table( { width => '100%',
                                   border => 1,
                                   title => ['ID', $_LOGIN, $_DATE, $_SUM, $_DESCRIBE, $_ADMINS, 'IP',  $_DEPOSIT, '-'],
                                   cols_align => ['right', 'left', 'right', 'right', 'left', 'left', 'right', 'right', 'center'],
                                   qs => $pages_qs,
                                   pages => $fees->{TOTAL}
                                  } );
foreach my $line (@$list) {
  my $delete = ($permissions{1}{3}) ?  $html->button($_DEL, "op=fees&del=$line->[0]&uid=$line->[8]", "$_DEL ?") : ''; 

  $table->addrow("<b>$line->[0]</b>", "<a href='$SELF_URL?op=users&uid=$line->[8]'>$line->[1]</a>", $line->[2], 
   $line->[3], $line->[4],  "$line->[5]", "$line->[6]", "$line->[7]", $delete);
}

print $table->show();

$table = Abills::HTML->table( { width => '100%',
                                   cols_align => ['right', 'right', 'right', 'right'],
                                   rows => [ [ "$_TOTAL:", "<b>$fees->{TOTAL}</b>", "$_SUM:", "<b>$fees->{SUM}</b>" ] ],
                                   rowcolor => $_COLORS[2]
                                  } );
print $table->show();


}




#*******************************************************************
# Search form
#*******************************************************************
sub form_search {
  my ($attr) = @_;

my %SEARCH_DATA = $admin->get_data(\%FORM);  

my $i=0;
my $SEL_METHOD = "<select name=METHOD>\n";
  $SEL_METHOD .= "<option value=''>$_ALL\n";
foreach my $line (@PAYMENT_METHODS) {
  $SEL_METHOD .= "<option value=$i";
	$SEL_METHOD .= ' selected' if ($FORM{METHOD} eq $i);
  $SEL_METHOD .= ">$line\n";
  $i++;
}
$SEL_METHOD .= "</select>\n";

my $nas = Nas->new($db);
my $list = $nas->list({ %LIST_PARAMS });
my $SEL_NAS = "<select name=NAS>\n";
  $SEL_NAS .= "<option value=''>$_ALL\n";
foreach my $line (@$list) {
	$SEL_NAS .= "<option value='$line->[0]'";
	$SEL_NAS .= ' selected' if ($FORM{NAS} eq $line->[0]);
	$SEL_NAS .= ">$line->[1]\n";
}
$SEL_NAS .= "</select>\n";


my %search_form = ( 
2 => "
<!-- PAYMENTS -->
<tr><td colspan=2><hr></td></tr>
<tr><td>$_OPERATOR:</td><td><input type=text name=A_LOGIN value='%A_LOGIN%'></td></tr>
<tr><td>$_DESCRIBE (*):</td><td><input type=text name=DESCRIBE value='%DESCRIBE%'></td></tr>
<tr><td>$_SUM (<,>):</td><td><input type=text name=SUM value='%SUM%'></td></tr>
<tr><td>$_PAYMENT_METHOD:</td><td>$SEL_METHOD</td></tr>\n",

3 => "
<!-- FEES -->
<tr><td colspan=2><hr></td></tr>
<tr><td>$_OPERATOR (*):</td><td><input type=text name=A_LOGIN value='%A_LOGIN%'></td></tr>
<tr><td>$_DESCRIBE (*):</td><td><input type=text name=DESCRIBE value='%DESCRIBE%'></td></tr>
<tr><td>$_SUM (<,>):</td><td><input type=text name=SUM value='%SUM%'></td></tr>\n",

11 => "
<!-- USERS -->
<tr><td colspan=2><hr></td></tr>
<tr><td>IP (>, <, *):</td><td><input type=text name=IP value='%IP%' title='Examples:\n 192.168.101.1\n >192.168.0\n 192.168.*.*'></td></tr>
<tr><td>$_SPEED (>, <):</td><td><input type=text name=SPEED value='%SPEED%'></td></tr>
<tr><td>CID</td><td><input type=text name=CID value='%CID%'></td></tr>
<tr><td>$_FIO (*):</td><td><input type=text name=FIO value='%FIO%'></td></tr>
<tr><td>$_PHONE (>, <, *):</td><td><input type=text name=PHONE value='%PHONE%'></td></tr>
<tr><td>$_COMMENTS (*):</td><td><input type=text name=COMMENTS value='%COMMENTS%'></td></tr>\n",

41 => "
<!-- last SESSION -->
<tr><td colspan=2><hr></td></tr>
<tr><td>IP (>,<)</td><td><input type=text name=IP value='%IP%'></td></tr>
<tr><td>CID</td><td><input type=text name=CID value='%CID%'></td></tr>
<tr><td>NAS</td><td>$SEL_NAS</td></tr>
<tr><td>NAS Port</td><td><input type=text name=NAS_PORT value='%NAS_PORT%'></td></tr>\n"
);

$SEARCH_DATA{SEARCH_FORM}=$search_form{$FORM{type}};
$SEARCH_DATA{FROM_DATE} = Abills::HTML->date_fld('from_', { MONTHES => \@MONTHES });
$SEARCH_DATA{TO_DATE} = Abills::HTML->date_fld('to_', { MONTHES => \@MONTHES} );

Abills::HTML->tpl_show(templates('form_search'), \%SEARCH_DATA);

if ($FORM{type}) {

	$LIST_PARAMS{LOGIN_EXPR}=$FORM{LOGIN_EXPR};
  $pages_qs = "&type=$FORM{type}";
	
	while(my($k, $v)=each %FORM) {
		if ($k =~ /([A-Z0-9]+)/ && $v ne '') {
		  print "$k, $v<br>";
		  $LIST_PARAMS{$k}=$v;
	    $pages_qs .= "&$k=$v";
		 }
	 }


  if ($FORM{type}) {
    $functions{$FORM{type}}->();
   }
}





}


#*******************************************************************
# form_shedule()
#*******************************************************************
sub form_shedule {

use Shedule;
my $shedule = Shedule->new($db, $admin);

if ($FORM{del} && $FORM{is_js_confirmed}) {
  $shedule->del($FORM{del});
  if ($admins->{errno}) {
    message('err', $_ERROR, "[$fees->{errno}] $err_strs{$fees->{errno}}");
   }
  else {
    message('info', $_DELETED, "$_DELETED [$FORM{del}]");
   }
}


my $list = $shedule->list( { %LIST_PARAMS } );
my $table = Abills::HTML->table( { width => '100%',
                                   border => 1,
                                   title => ["$_HOURS", "$_DAY", "$_MONTH", "$_YEAR", "$_COUNT", "$_USER", "$_VALUE", "$_ADMINS", "$_CREATED", "-"],
                                   cols_align => ['right', 'right', 'right', 'right', 'right', 'left', 'right', 'right', 'right', 'center'],
                                   qs => $pages_qs,
                                   pages => $shedule->{TOTAL}
                                  } );

foreach my $line (@$list) {
  my $delete = ($permissions{1}{3}) ?  $html->button($_DEL, "op=shedule&del=$line->[11]&uid=$line->[10]", "$_DEL ?") : ''; 
  $table->addrow("<b>$line->[0]</b>", $line->[1], $line->[2], 
    $line->[3],  $line->[4],  "<a href='$SELF_URL?op=users&uid=$line->[10]'>$line->[5]</a>", "$line->[6]", "$line->[7]", "$line->[8]", $delete);
}

print $table->show();

$table = Abills::HTML->table( { width => '100%',
                                cols_align => ['right', 'right', 'right', 'right'],
                                rows => [ [ "$_TOTAL:", "<b>$shedule->{TOTAL}</b>" ] ]
                               } );
print $table->show();





}





























#**********************************************************
# sql()
#**********************************************************
sub sql {

print << "[END]";
<a href='$SELF_URL?index=81'>SQL Commander</a> :: 
<a href='$SELF_URL?index=82'>SQL Backup</a>
[END]


}


#**********************************************************
# sql_cmd()
#**********************************************************
sub sql_cmd {

print << "[END]";
[END]


}


#**********************************************************
# sql_backup()
#**********************************************************
sub sql_backup {

print << "[END]";
[END]


}



#**********************************************************
# test
#**********************************************************
sub test {
  while(my($k, $v)=each %ENV) {
    print "$k - $v<br>\n";	
   }
}





#*******************************************************************
# form_period
#*******************************************************************
sub form_period () {
 my $period = shift;
 my @periods = ("$PERIODS[0]", "$_OTHER");
 my $date_fld = $html->date_fld('date_', { MONTHES => \@MONTHES });
 my $form_period='';


 $form_period .= "<tr><td>$_DATE:</td><td>";

 my $i=0;
 foreach my $t (@periods) {
   $form_period .= "<br><br><input type=radio name=period value=$i";
   $form_period .= " checked" if ($i eq $period);
   $form_period .= "> $t\n";	
   $i++;
 }
 $form_period .= "$_DATE: $date_fld</td></tr>\n";


 return $form_period;	
}








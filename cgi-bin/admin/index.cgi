#!/usr/bin/perl

BEGIN {
 $sql_type='mysql';
 unshift(@INC, "Abills/$sql_type/")
}

use Abills::SQL;
use Abills::HTML;
use Nas;
use Admins;
#use Users;

my $html = Abills::HTML->new();
my $sql = Abills::SQL->connect('mysql', 'localhost', 'abills', 'asm', 'test1r');
my $db = $sql->{db};
my $admins = Admins->new($db);
$conf{secretkey}="test12345678901234567890";
$conf{passwd_length}=6;
$conf{username_length}=15;




require "../../language/$html->{language}.pl";
my %err_strs = (
  1 => $_ERROR,
  2 => ERROR_NOT_EXIST,
  3 => $ERR_SQL,
  4 => ERROR_WRONG_PASSWORD,
  5 => ERROR_WRONG_CONFIRM,     
  6 => ERROR_SHORT_PASSWORD,
  7 => ERROR_DUBLICATE,
  8 => ERROR_ENTER_NAME,
  9 => ERROR_LONG_USERNAME,
  10 => ERROR_WRONG_NAME,
  11 => ERROR_WRONG_EMAIL
);



if (defined($FORM{colors})) {
  my $cook_colors = (defined($FORM{default})) ?  '' : $FORM{colors};
  $html->setCookie('colors', '$cook_colors', "Fri, 1-Jan-2038 00:00:01", $web_path, $domain, $secure);
 }
#$html->setCookie('language', '$FORM{language}', "Fri, 1-Jan-2038 00:00:01", $web_path, $domain, $secure) if (defined($FORM{language}));
#$html->setCookie('opid', "$FORM{opid}", "Fri, 1-Jan-2038 00:00:01", $web_path, $domain, $secure);

print $html->header();

my %permissions = ();
if (check_permissions('asm', 'test123') == 1) {
   exit;
 }

 my @sections = ($_USERS, 
                 _FINANCES, 
                 $_FEES, 
                 $_REPORTS,
                 $_SYSTEM,
                 $_MODULES 
                );

 my @actions = ([$_SA_ONLY, $_ADD, $_LIST, $_PASSWD, $_CHANGE, $_DEL, $_ALL],  # Users
                [$_PAYMENTS, $_FEES, $_LIST, $_DEL, $_ALL],                # Payments
                [$_LIST, $_ADD, $_DEL, $_ALL],                                 # Fees
                [$_ALL],                                                       # reports view
                [$_ALL, 'tarif_plans'],                                        # system magment
                [$_ALL, 'users']                                               # Modules managments
               );

my @action = ('add', $_ADD);

my %op_names = ();
my %menu_items = ();
my %functions = ();
my $index = $FORM{index} || 0;
my $root_index = 0;

my %main_menu = ();
my $navigat_menu = mk_navigator();




######################################
print "<table border=1>\n";
while(my($k, $v)=each %FORM) {
  print "<tr><td>$k</td><td>$v</td></tr>\n";	
}
print "<tr bgcolor=$_COLORS[2]><td>index</td><td>$index</td></tr>\n";	
print "<tr bgcolor=$_COLORS[2]><td>OP</td><td>$OP</td></tr>\n";	
print "</table>\n";
######################################









print "<table border=0 width=100%><tr><td valign=top width=200 bgcolor=$_COLORS[2] rowspan=2><p>\n";
print $html->menu(1, 'op', "", \%main_menu);
sub_menu($index);
print "</td><td bgcolor=$_COLORS[0]>$navigat_menu";
print "</td></tr><tr><td>";

if ($functions{$index}) {
  $OP = $op_names{$index};
  $functions{$index}->();
}
else {
  print "hello $index / $root_index";	
}

print "</td></tr></table>\n";

#**********************************************************
#
# check_permissions()
#**********************************************************
sub check_permissions {
  my ($login, $password)=@_;

  my $admin = Admins->info(0, {login => "$login", 
                               password => "$password",
                               secretkey => $conf{secretkey}
                               }
                           );

  if ($admin->{errno}) {
    message('err', $_ERROR, "$err_strs{$admin->{errno}}");
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
                                   cols_align => [left, left, right, right, left, center, center, center, center],
                                  } );


print $html->pages($total, "op=users$pages_qs");
print $table->show();
print $html->pages($total, "op=users$pages_qs");
}

#**********************************************************
# account_info
#**********************************************************
sub account_info {

print << "[END]";
<form action=$SELF_URL METHOD=POST>
<input type=hidden name=op value='accounts'>
<input type=hidden name=chg value='$FORM{chg}'>
<Table>
<tr><td>$_NAME:</td><td><input type=text name=name value="$name"></td></tr>
<tr bgcolor=$_BG1><td>$_DEPOSIT:</td><td>$deposit</td></tr>
<tr bgcolor=$_BG1><td>$_TAX_NUMBER:</td><td><input type=text name=tax_number value='$tax_number' size=60></td></tr>
<tr bgcolor=$_BG1><td>$_ACCOUNT:</td><td><input type=text name=bank_account value='$bank_account' size=60></td></tr>
<tr bgcolor=$_BG1><td>$_BANK_NAME:</td><td><input type=text name=bank_name value='$bank_name' size=60></td></tr>
<tr bgcolor=$_BG1><td>$_COR_BANK_ACCOUNT:</td><td><input type=text name=cor_bank_account value='$cor_bank_account' size=60></td></tr>
<tr bgcolor=$_BG1><td>$_BANK_BIC:</td><td><input type=text name=bank_bic value='$bank_bic' size=60></td></tr>
</table>
<input type=submit name=$action[0] value='$action[1]'>
</form>
<a href='$SELF_URL?index=11&account_id=$FORM{chg}'>_ADD_USER</a>
[END]
}

#**********************************************************
# form_customers
#**********************************************************
sub form_accounts {
  $name = $FORM{name};
  $deposit = $FORM{deposit};
  $tax_number = $FORM{tax_number};
  $bank_account = $FORM{bank_account};
  $bank_name = $FORM{bank_name}; 
  $cor_bank_account = $FORM{cor_bank_account}; 
  $bank_bic = $FORM{cor_bank_account};

  use Customers;	
  my $customer = Customers->new($db);


  @action = ('add', $_ADD);

if ($FORM{add}) {
  my $account =  $customer->account->add({ NAME => $name,
                     TAX_NUMBER => $tax_number,
                     BANK_ACCOUNT => $bank_account,
                     BANK_NAME => $bank_name, 
                     COR_BANK_ACCOUNT => $cor_bank_account,
                     BANK_BIC => $bank_bic
           });
 
  if ($account->{errno}) {
    message('err', $_ERROR, "[$account->{errno}] $err_strs{$account->{errno}}");
   }
  else {
    message('info', $_ADDED, "$_ADDED");
   }
 }
elsif($FORM{change}) {
  $customer->account->change($FORM{chg} , { NAME => $name,
                     TAX_NUMBER => $tax_number,
                     BANK_ACCOUNT => $bank_account,
                     BANK_NAME => $bank_name, 
                     COR_BANK_ACCOUNT => $cor_bank_account,
                     BANK_BIC => $bank_bic } );

  if ($account->{errno}) {
    message('info', $_ERROR, "[$account->{errno}] $err_strs{$account->{errno}}");
   }
  else {
    message('info', $_INFO, $_CHANGED. " # $name<br>");
   }
 }
elsif($FORM{chg}) {
  $account = $customer->account->info($FORM{chg});

  if ($account->{errno}) {
    message('info', $_ERROR, "[$account->{errno}] $err_strs{$account->{errno}}");
   }
  else {
    $name = $account->{name};
    $deposit = $account->{deposit};
    $tax_number = $account->{tax_number};
    $bank_account = $account->{bank_account};
    $bank_name = $account->{bank_name}; 
    $cor_bank_account = $account->{cor_bank_account}; 
    $bank_bic = $account->{cor_bank_account};

    message('info', $_INFO, $_CHANGING. " # $_NAME: $name<br>");
    account_info();
   }

  @action = ('change', $_CHANGE);
 }
elsif($FORM{del}) {
   $customer->account->del( $FORM{del} );
   message('info', $_INFO, "$_DELETED # $FORM{del}");
 }
else {
 account_info();
}





 my %PARAMS = ( SORT => $SORT,
	       DESC => $DESC,
	       PG => $PG,
	       PAGE_ROWS => $PAGE_ROWS,
	      );

my $table = Abills::HTML->table( { width => '100%',
                                   border => 1,
                                   title => [$_NAME, $_DEPOSIT, $_USERS, '-', '-'],
                                   cols_align => [left, right, right, center, center],
                                  } );

my ($accounts_list, $total) = $customer->account->list( { %PARAMS } );
foreach my $line (@$accounts_list) {
  $table->addrow($line->[0],  $line->[1], $line->[2], 
    "<a href='$SELF_URL?op=accounts&chg=$line->[3]'>$_CHANGE</a>", $html->button($_DEL, "op=accounts&del=$line->[3]", "$_DEL ?"));
}

 

print $html->pages($total, "op=users$pages_qs");
print $table->show();
print $html->pages($total, "op=users$pages_qs");

}


#**********************************************************
# add_customer
#**********************************************************
sub add_customer {


print "<form action=$SELF_URL>\n
<input type=hidden name= value=>
</form>\n";
 	
}
#**********************************************************
# form_users()
#**********************************************************
sub user_form {
 my ($type, $user_info) = @_;
 my $tpl_form;


if ($type eq 'info') {


$tpl_form = qq{<table width=100%>
       <tr><td>$_LOGIN:</td><td>$login</td></tr>
       <tr><td>UID:</td><td>$uid</td></tr>
       <tr><td>$_FIO:</td><td>$fio</td></tr>
       <tr><td>$_PHONE:</td><td>$phone</td></tr>
       <tr><td>$_ADDRESS:</td><td>$address</td></tr>
       <tr><td>E-mail:</td><td>$email</td></tr>
       <tr><td>$_VARIANT:</td><td>$variant</td></tr>
       <tr><td>$_CREDIT:</td><td>$credit</td></tr>
       <tr><td>$_REDUCTION</td><td>$reduction %</td></tr>
       <tr><td>$_SIMULTANEOUSLY:</td><td>$simultaneously</td></tr>
       <tr><td>$_ACTIVATE:</td><td>$activate</td></tr>
       <tr><td>$_EXPIRE:</td><td>$expire</td></tr>
       <tr><td>$_NAS:</td><td>$NAS_SERVERS{'nas'}</td></tr>
       <tr><td>IP:</td><td>$ip</td></tr>
       <tr><td>NETMASK:</td><td>$netmask</td></tr>
       <tr><td>$_SPEED (Kb)</td><td>$speed</td></tr>
       <tr><td>$_FILTERS</td><td>$filter_id</td></tr>
       <tr><td>CID:</td><td>$cid</td></tr>
<tr><th colspan=2>:$_COMMENTS:</th></tr>
<tr><th colspan=2>:$comments:</th></tr>
</table>};
}
else { 
 use Tariffs;
 my $tariffs = Tariffs->new($db);

 if (! $info) {
   $info = "<tr><td>$_USER:*</td><td><input type=text name=login value='$user_info->{LOGIN}'></td></tr>\n";
   my $tariffs_list = $tariffs->list();
   $variant_out = "<select name=variant>";

   foreach my $line (@$tariffs_list) {
     $variant_out .= "<option value=$line->[0]";
     $variant_out .= ' selected' if ($line->[0] == $variant);
     $variant_out .=  ">$line->[0]:$line->[1]\n";
    }
   $variant_out .= "</select>";
  }


$tpl_form = qq{
<form action=$SELF_URL method=post>
<input type=hidden name=index value=14>
<input type=hidden name=account_id value='$user_info->{ACCOUNT_ID}'>
<input type=hidden name=uid value="$user_info->{UID}">
<table width=420 cellspacing=0 cellpadding=3>
$info
<tr><td>$_ACCOUNT:</td><td>$user_info->{ACCOUNT_NAME}</td></tr>
<tr><td>$_FIO:*</td><td><input type=text name=fio value="$user_info->{FIO}"></td></tr>
<tr><td>$_PHONE:</td><td><input type=text name=phone value="$user_info->{PHONE}"></td></tr>
<tr><td>$_ADDRESS:</td><td><input type=text name=address value="$user_info->{ADDRESS}"></td></tr>
<tr><td>E-mail:</td><td><input type=text name=email value="$user_info->{EMAIL}"></td></tr>
<tr><td colspan=2>&nbsp;</td></tr>
<tr><td>$_TARIF_PLAN:</td><td valign=center>$variant_out</td></tr>
<tr><td>$_CREDIT:</td><td><input type=text name=credit value='$user_info->{CREDIT}'></td></tr>
<tr><td>$_SIMULTANEOUSLY:</td><td><input type=text name=simultaneously value='$user_info->{SIMULTANEONSLY}'></td></tr>
<tr><td>$_ACTIVATE:</td><td><input type=text name=activate value='$user_info->{ACTIVATE}'></td></tr>
<tr><td>$_EXPIRE:</td><td><input type=text name=expire value='$user_info->{EXPIRE}'></td></tr>
<tr><td>$_REDUCTION (%):</td><td><input type=text name=reduction value='$user_info->{REDUCTION}'></td></tr>
<tr><td>IP:</td><td><input type=text name=ip value='$user_info->{IP}'></td></tr>
<tr><td>Netmask:</td><td><input type=text name=netmask value='$user_info->{NETMASK}'></td></tr>
<tr><td>$_SPEED (kb):</td><td><input type=text name=speed value='$user_info->{SPEED}'></td></tr>
<tr><td>$_FILTERS:</td><td><input type=text name=filter_id value='$user_info->{FILTER_ID}'></td></tr>
<tr><td><b>CID:</b><br></td><td><input title='MAC: [00:40:f4:85:76:f0]
IP: [10.0.1.1]
PHONE: [805057395959]' type=text name=cid value='$user_info->{CID}'></td></tr>
<tr><td>$_DISABLE:</td><td><input type=checkbox name=disable value='yes' $disable></td></tr>
<tr><th colspan=2>:$_COMMENTS:</th></tr>
<tr><th colspan=2><textarea name=comments rows=5 cols=45>$comments</textarea></th></tr>
</table>
<p>
<input type=submit name=$action[0] value='$action[1]'>
</form>
};

if ($uid) {
$tpl_form = qq{<table width=600 border=1 cellspacing=1 cellpadding=2><tr><td>
$tpl_form
</td><td bgcolor=$_COLORS[3] valign=top width=180>

<table width=100% border=0><tr><td>
      <li><a href='$SELF?op=stats&uid=$uid'>$_STATS</a>
      <li><a href='$SELF?op=payments&uid=$uid'>$_PAYMENTS</a>
      <li><a href='$SELF?op=fees&uid=$uid'>$_FEES</a>
      <li><a href='$SELF?op=errlog&uid=$uid'>$_ERROR_LOG</a>
      <li><a href='$SELF?op=sendmsg&uid=$uid'>$_SEND_MAIL</a>
      <li><a href='$SELF?op=messages&uid=$uid'>$_MESSAGES</a>
      <li><a href='docs.cgi?docs=accts&uid=$uid'>$_ACCOUNTS</a>
</td></tr>
<tr><td> 
      <br><b>$_CHANGE</b>
      <li><a href='$SELF?op=users&uid=$uid&password=chg'>$_PASSWD</a>
      <li><a href='$SELF?op=chg_uvariant&uid=$uid'>$_VARIANT</a>
      <li><a href='$SELF?op=account&uid=$uid'>$_ACCOUNT</a>
      <li><a href='$SELF?op=allow_nass&uid=$uid'>$_NASS</a>
      <li><a href='$SELF?op=bank_info&uid=$uid'>$_BANK_INFO</a>
      <li><a href='$SELF?op=changes&uid=$uid'>$_LOG</a>
</td></tr>
</table>
</td></tr></table>
};
	
}


}


#return 
print $tpl_form;

}


#**********************************************************
# form_users()
#**********************************************************
sub form_users {

my $LOGIN = $FORM{login} || '';
my  $EMAIL = $FORM{email} || '';
my  $FIO = $FORM{fio} || '';
my  $PHONE = $FORM{phone} || '';
my  $ADDRESS = $FORM{address} || '';
my  $ACTIVATE = $FORM{activate} || '0000-00-00';
my  $EXPIRE = $FORM{expire} || '0000-00-00';
my  $CREDIT = $FORM{credit} || 0;
my  $REDUCTION = $FORM{reduction} || 0;
my  $SIMULTANEONSLY = $FORM{simultaneously} || 0;
my  $COMMENTS  = $FORM{comments} || '';

my  $ACCOUNT_ID = $FORM{account_id} || 0;

$uid = $FORM{uid};

 use Users;
 my $users = Users->new($db); 

if ($FORM{add}) {
  $users->add( { LOGIN => $LOGIN,
                 EMAIL => $EMAIL,
                 FIO => $FIO,
                 PHONE => $PHONE,
                 ADDRESS => $ADDRESS,
                 ACTIVATE => $ACTIVATE,
                 EXPIRE => $EXPIRE,
                 CREDIT => $CREDIT,
                 REDUCTION  => $REDUCTION,
                 SIMULTANEONSLY => $SIMULTANEONSLY,
                 COMMENTS => $COMMENTS,
                 ACCOUNT_ID => $ACCOUNT_ID }
                );  

#  my $TARIF_PLAN = (defined($attr->{TARIF_PLAN})) ? $attr->{TARIF_PLAN} : '';
#  my $IP = (defined($attr->{IP})) ? $attr->{IP} : '0.0.0.0';
#  my $NETMASK  = (defined($attr->{NETMASK})) ? $attr->{NETMASK} : '255.255.255.255';
#  my $SPEED = (defined($attr->{SPEED})) ? $attr->{SPEED} : 0;
#  my $FILTER_ID = (defined($attr->{FILTER_ID})) ? $attr->{FILTER_ID} : '';
#  my $CID = (defined($attr->{CID})) ? $attr->{CID} : '';);

  if ($users->{errno}) {
    message('err', $_ERROR, "[$users->{errno}] $err_strs{$users->{errno}}");	
    user_form();    
    return 0;	
   }
  else {
    message('info', $_ADDED, "$_ADDED");
   }
}
#Change tariff plan
elsif ($FORM{chg_tp}) {
  my $change_tp = '';
  return 0;
}
elsif($FORM{password}) {
  my $password = chg_password('users', "$uid");
  return 0;
}
elsif ($FORM{change}) {
  $users->change("$uid", { LOGIN => $LOGIN,
                 EMAIL => $EMAIL,
                 FIO => $FIO,
                 PHONE => $PHONE,
                 ADDRESS => $ADDRESS,
                 ACTIVATE => $ACTIVATE,
                 EXPIRE => $EXPIRE,
                 CREDIT => $CREDIT,
                 REDUCTION  => $REDUCTION,
                 SIMULTANEONSLY => $SIMULTANEONSLY,
                 COMMENTS => $COMMENTS,
                 ACCOUNT_ID => $ACCOUNT_ID,
                   }
                );  

#  my $TARIF_PLAN = (defined($attr->{TARIF_PLAN})) ? $attr->{TARIF_PLAN} : '';
#  my $IP = (defined($attr->{IP})) ? $attr->{IP} : '0.0.0.0';
#  my $NETMASK  = (defined($attr->{NETMASK})) ? $attr->{NETMASK} : '255.255.255.255';
#  my $SPEED = (defined($attr->{SPEED})) ? $attr->{SPEED} : 0;
#  my $FILTER_ID = (defined($attr->{FILTER_ID})) ? $attr->{FILTER_ID} : '';
#  my $CID = (defined($attr->{CID})) ? $attr->{CID} : '';);

  if ($users->{errno}) {
    message('err', $_ERROR, "[$users->{errno}] $err_strs{$users->{errno}}");	
    user_form();    
    return 0;	
   }
  else {
    message('info', $_CHANGED, "$_CHANGED");
   }
}

if($uid > 0) {
  my $user_info = $users->info( $uid );  
  @action = ('change', $_CHANGE);
  user_form('test', $user_info);
  return 0;
}

my $table = Abills::HTML->table( { width => '100%',
                                   border => 1,
                                   title => [$_LOGIN, $_FIO, $_DEPOSIT, $_CREDIT, $_TARIF_PLANS, '-', '-'],
                                   cols_align => [left, left, right, right, left, center, center, center, center],
                                  } );
my %PARAMS = ( SORT => $SORT,
	       DESC => $DESC,
	       PG => $PG,
	       PAGE_ROWS => $PAGE_ROWS,
	      );

my $pages_qs = '';

if ($FORM{debs}) {
  print "<p>$_DEBETERS</p>\n";
  $pages_qs .= "&debs=$FORM{debs}";
  $PARAMS{DEBETERS} = 'y';
 }  

if ($FORM{tp}) {
  print "<p>$_VARIANT: $FORM{variant}</p>\n"; 
  $pages_qs .= "&tp=$FORM{tp}";
  $PARAMS{TP} = $FORM{tp};
 }

print "<a href='$SELF?op=users'>All</a> ::";
for (my $i=97; $i<123; $i++) {
  my $l = chr($i);
  if ($FORM{letter} eq $l) {
     print "<b>$l </b>";
    }
  else {
     $pages_qs = '';
     print "<a href='$SELF?op=users&letter=$l$pages_qs'>$l</a> ";
   }
 }

 if ($FORM{letter}) {
   $PARAMS{FIRST_LETTER} = $FORM{letter};
   $pages_qs .= "&letter=$FORM{letter}";
  } 

my ($users_list, $total) = $users->list( { %PARAMS } );
foreach my $line (@$users_list) {
  my $payments = ($permissions{1}) ?  "<a href='$SELF_URL?op=payments&uid=$line->[5]'>$_PAYMENTS</a>" : ''; 

  $table->addrow("<a href='$SELF_URL?op=users&uid=$line->[5]'>$line->[0]</a>", "$line->[1]",
   "$line->[2]", "$line->[3]", "$line->[4]", $payments, "<a href='$SELF_URL?op=stats&uid=$line->[5]'>$_STATS</a>");
}


print "<p>$_TOTAL: $total</p>\n";
print $html->pages($total, "op=users$pages_qs");
print $table->show();
print $html->pages($total, "op=users$pages_qs");
}

#**********************************************************
# form_admins()
#**********************************************************
sub form_admins {
 print "<h3>$_ADMINS</h3>\n";

my @action = ('add', $_ADD);

 
if ($FORM{add}) {
  $admin->add();
  if ($admin->{errno}) {
     message('err', $_ERROR, $admin->{errstr});	
   }
}
elsif ($FORM{permissions}) {
   admin_permissions($FORM{aid});	
   return 0;
 }
elsif ($FORM{password}) {
  $admin = Admins->info($FORM{password});

  my $password = chg_password('admins', "$FORM{aid}");
  if ($password ne '0') {
    $admin->password($password, { secretkey => $conf{secretkey} } ); 
    if (! $admin->{errno}) {
       message('info', $_INFO, "$_ADMINS: $admin->{name}<br>$_PASSWD $_CHANGED");
     }
   }

 return 0;
 }
elsif($FORM{chg}) {
  $admin = $admins->info($FORM{chg});

  if ($admin->{errno}) {
     message('err', $_ERROR, $err_strs{$admin->{errno}});	
   }
}
elsif($FORM{del}) {
  $admin_info = $admin->del();

  if ($admin->{errno}) {
     message('err', $_ERROR, $err_strs{$admin->{errno}});	
   }
}

print << "[END]";
<form action=$SELF_URL>
<input type=hidden name=op value=admins>
<input type=hidden name=chg value='$FORM{chg}'>
<table>
<tr><td>ID:</td><td><input type=text name=id value="$id"></td></tr>
<tr><td>$_FIO:</td><td><input type=text name=name value="$name"></td></tr>
<tr><td>$_GROUPS:</td><td><input type=text name=name value="$name"></td></tr>
</table>
<input type=submit name=$action[0] value='$action[1]'>
</form>
[END]


my $table = Abills::HTML->table( { width => '640',
                                   border => 1,
                                   title => ['ID', $_NAME, $_FIO, $_CREATE, $_GROUPS, '-', '-', '-', '-'],
                                   cols_align => [right, left, left, right, left, center, center, center, center],
                                  } );

my $admins_list = $admins->list();
foreach my $line (@$admins_list) {
  $table->addrow(@$line, "<a href='$SELF_URL?op=admins&permissions=y&aid=$line->[0]'>$_PERMISSION</a>", "<a href='$SELF_URL?op=admins&password=y&aid=$line->[0]'>$_PASSWD</a>",
   "<a href='$SELF_URL?op=admins&chg=$line->[0]'>$_CHANGE</a>", $html->button($_DEL, "op=admins&del=$line->[0]", "$_DEL ?"));
}
print $table->show();
}







#**********************************************************
# permissions();
#**********************************************************
sub admin_permissions {
 my ($aid) = @_;

 print "<h3>$_PERMISSION</h3>\n";


 $admin = Admins->info($aid);
 
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

 %permits = %$p;
 
 print "<form action=$SELF_URL METHOD=POST>
 <input type=hidden name=op value=admins>
 <input type=hidden name=aid value='$FORM{aid}'>
 <input type=hidden name=permissions value=set>
 <table width=640>\n";
 $section_index = 0;
 foreach my $s (@sections) {
   print "<tr bgcolor=$_COLORS[0]><td colspan=3>$section_index: <b>$s</b></td></tr>\n";
   my $actions_list = @actions[$section_index];
   my $action_index = 0;
   foreach my $action (@$actions_list) {
      my $checked = (defined($permits{$section_index}{$action_index})) ? 'checked' : '';
      print "<tr><td align=right>$action_index</td><td>$action</td><td><input type=checkbox name='$section_index". "_$action_index' value='yes' $checked></td></tr>\n";
      $action_index++;
    }
  
   $section_index++;
  }
  
print "<table>
 <input type=submit name='set' value=\"$_SET\">
</form>\n";
	
}

#**********************************************************
# chg_password($op, $id)
#**********************************************************
sub chg_password {
 my ($op, $id)=@_;
 print "<h3>$_CHANGE_PASSWD</h3>\n";

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
<input type=hidden name=op value=$op>
<input type=hidden name=password value=$id>
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

# name # parent
# Users
$menu_items{1}{0}=$_CUSTOMERS;
$op_names{1}='customers';
$functions{1}=\&form_customers;


$menu_items{11}{1}=$_ADD;
$op_names{11}='';
$functions{11}=\&user_form;


$menu_items{13}{1}=$_ACCOUNTS;
$op_names{13}='accounts';
$functions{13}=\&form_accounts;

$menu_items{14}{1}=$_USERS;
$op_names{14}='users';
$functions{14}=\&form_users;






=comments
$menu_items{14}{1}=$_FEES;
$op_names{14}='users';
$functions{14}=\&form_users;

$menu_items{15}{1}=$_LIST;
$op_names{15}='users';
$functions{15}=\&form_users;

$menu_items{11}{1}=$_PAYMENTS;
$op_names{11}='payments';
$functions{11}=\&form_users;
=cut


#Payments
$menu_items{2}{0}=$_PAYMENTS;
$op_names{2}='payments';

# Fees
$menu_items{3}{0}=$_FEES;
$op_names{3}='fees';

#Reports
$menu_items{4}{0}=$_REPORTS;
$op_names{4}='reports';


$menu_items{31}{4}=$_LAST;
$menu_items{32}{4}=$_PAYMENTS;
$menu_items{33}{4}=$_FEES;
$menu_items{34}{4}=$_INPAYMENTS;

$menu_items{5}{0}=$_SYSTEM;
$op_names{5}='system';

$menu_items{50}{5}=$_ADMINS;
$op_names{50}='admins';
$functions{50}=\&form_admins;

#$menu_items{51}{50}=$_ADD;
#$functions{51}=\&form_admins;
#$menu_items{52}{50}=$_LIST;
#$functions{52}=\&form_admins;
#$menu_items{53}{50}=$_PASSWD;
#$functions{53}=\&form_admins;
#$menu_items{54}{50}=$_PERMISSION;
#$functions{54}=\&form_admins;

$menu_items{60}{5}=$_NAS;
$op_names{60}='nas';
$menu_items{61}{60}="IP POOLs";
$menu_items{62}{60}=$_NAS_STATISTIC;

$menu_items{70}{5}=$_TARIF_PLANS;
$menu_items{71}{70}=$_LIST;

$menu_items{80}{5}='SQL';
$op_names{80}=sql_browser;
$menu_items{81}{80}='SQL Browser';
$menu_items{82}{80}='SQL Backup';


$menu_items{99}{5}=_FUNCTIONS_LIST;
$op_names{99}='flist';

$menu_items{6}{0}=$_MODULES;
$op_names{6}='modules';

$menu_items{101}{6}=_DOCS;
$menu_items{102}{6}=_MAIL;
$menu_items{103}{6}=_VoIP;
$menu_items{104}{6}=_DOCSIS;

while(my($section, $v)=each %permissions) {
  $section++;
  $main_menu{$section.'::'. $op_names{$section} .':'.$section} = $menu_items{$section}{0};
 }

#flist();
# make navigate line 
if ($OP ne '' || $index > 0) {
  my $h;

  if ($OP ne '') {
    my %functions_index = reverse(%op_names);
    $root_index = $functions_index{$OP};
    $index = $functions_index{$OP};
   }
  else {
    $root_index = $index;	
   }

  $h = $menu_items{$root_index};
  while(my ($par_key, $name) = each ( %$h )) {
    $menu_navigator =  " <a href='$SELF_URL?index=$root_index'>$name</a> /" . $menu_navigator;
    if ($par_key > 0) {
      $root_index = $par_key;
      $h = $menu_items{$par_key};
     }
  }
}


 if ($FORM{op} eq '') {
   $OP = $op_names{$root_index};
  }
 $FORM{op} = $op_names{$root_index};

 return  "/".$menu_navigator;
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


foreach my $parent (@menu_sorted) { 
  my $val = $h->{$parent};
  my $level = 0;
  my $prefix = '';

  $val = ($index eq $parent) ?  "<b>$val</b>" : $val;
  print "$level: <a href='$SELF?index=$parent'>$val</a><br>\n";

  if (defined($new_hash{$parent})) {
    $level++;
    $prefix .= "&nbsp;&nbsp;&nbsp;";
    label:
      my $mi = $new_hash{$parent};

      while(my($k, $val)=each %$mi) {
      	$val = ($index eq $k) ?  "<b>$val</b>" : $val;
        print "$prefix $level: <a href='$SELF_URL?index=$k'>$val</a><br>\n";
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

}



sub sub_menu {
  my $root_index = shift;

  print "<br><hr>\n";
my  %new_hash = ();
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







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

use Abills::SQL;
use Abills::HTML;
use Nas;
use Admins;




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


my $domain = '';
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
                [$_LIST, $_ADD, $_DEL, $_ALL],                # Payments
                [$_LIST, $_ADD, $_DEL, $_ALL],                                 # Fees
                [$_ALL],                                                       # reports view
                [$_ALL, 'tarif_plans'],                                        # system magment
                [$_ALL, 'users']                                               # Modules managments
               );

my %LIST_PARAMS = ( SORT => $SORT,
	       DESC => $DESC,
	       PG => $PG,
	       PAGE_ROWS => $PAGE_ROWS,
	      );

my @action = ('add', $_ADD);

my %op_names = ();
my %menu_items = ();
my %functions = ();
my $index = $FORM{index} || 0;
my $root_index = 0;

#my %main_menu = ();
my ($main_menu, $sub_menu, $navigat_menu) = mk_navigator();





print "<table border=0 width=100%><tr><td valign=top width=200 bgcolor=$_COLORS[2] rowspan=2><p>\n";
print $html->menu(1, 'op', "", $main_menu, $sub_menu);
sub_menu($index);


######################################
print "<table border=1>
<tr><td>index</td><td>$index</td></td>\n";

  while(my($k, $v)=each %FORM) {
    print "<tr><td>$k</td><td>$v</td></tr>\n";	
  }

print "<tr bgcolor=$_COLORS[2]><td>index</td><td>$index</td></tr>\n";	
print "<tr bgcolor=$_COLORS[2]><td>OP</td><td>$OP</td></tr>\n";	
print "</table>\n";
######################################
print "</td><td bgcolor=$_COLORS[0]>$navigat_menu";
print "</td></tr><tr><td valign=top>";

if ($functions{$index}) {
  $OP = $op_names{$index};
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

  $admin = Admins->info(0, {LOGIN => "$login", 
                            PASSWORD => "$password",
                            SECRETKEY => $conf{secretkey},
                            IP => $SESSION_IP
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
  my ($aacount) = @_;

print << "[END]";
<form action=$SELF_URL METHOD=POST>
<input type=hidden name=op value='accounts'>
<input type=hidden name=chg value='$FORM{chg}'>
<Table>
<tr><td>$_NAME:</td><td><input type=text name=name value="$account->{ACCOUNT_NAME}"></td></tr>
<tr bgcolor=$_BG1><td>$_DEPOSIT:</td><td>$account->{DEPOSIT}</td></tr>
<tr bgcolor=$_BG1><td>$_TAX_NUMBER:</td><td><input type=text name=tax_number value='$account->{TAX_NUMBER}' size=60></td></tr>
<tr bgcolor=$_BG1><td>$_ACCOUNT:</td><td><input type=text name=bank_account value='$account->{BANK_ACCOUNT}' size=60></td></tr>
<tr bgcolor=$_BG1><td>$_BANK_NAME:</td><td><input type=text name=bank_name value='$account->{BANK_NAME}' size=60></td></tr>
<tr bgcolor=$_BG1><td>$_COR_BANK_ACCOUNT:</td><td><input type=text name=cor_bank_account value='$account->{COR_BANK_ACCOUNT}' size=60></td></tr>
<tr bgcolor=$_BG1><td>$_BANK_BIC:</td><td><input type=text name=bank_bic value='$account->{BANK_BIC}' size=60></td></tr>
</table>
<input type=submit name=$action[0] value='$action[1]'>
</form>
<hr>
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
    message('info', $_INFO, $_CHANGING. " # $_NAME: $name<br>");
    @action = ('change', $_CHANGE);
    account_info($account);
    print "<a href='$SELF_URL?index=11&account_id=$FORM{chg}'>$_ADD_USER</a>";
    $FORM{account_id} = $FORM{chg};
    form_users();
   }
 }
elsif($FORM{del}) {
   $customer->account->del( $FORM{del} );
   message('info', $_INFO, "$_DELETED # $FORM{del}");
 }
else {
 account_info();

my $table = Abills::HTML->table( { width => '100%',
                                   border => 1,
                                   title => [$_NAME, $_DEPOSIT, $_USERS, '-', '-'],
                                   cols_align => [left, right, right, center, center],
                                  } );

my ($accounts_list, $total) = $customer->account->list( { %LIST_PARAMS } );
foreach my $line (@$accounts_list) {
  $table->addrow($line->[0],  $line->[1], "<a href='$SELF_URL?op=users&account_id=$line->[3]'>$line->[2]</a>", 
    "<a href='$SELF_URL?op=accounts&chg=$line->[3]'>$_INFO</a>", $html->button($_DEL, "op=accounts&del=$line->[3]", "$_DEL ?"));
}

print $html->pages($total, "op=users$pages_qs");
print $table->show();
print $html->pages($total, "op=users$pages_qs");

}



}



#**********************************************************
# chg_account
#**********************************************************
sub chg_account {
  my ($user) =@_;

if ($FORM{change})  {

  if ($user->{errno}) {
    message('info', $_ERROR, "[$account->{errno}] $err_strs{$account->{errno}}");
   }
  else {
    message('info', $_ACCOUNT, $_CHANGED. " # $name<br>");
   }
}

use Customers;	
my $customer = Customers->new($db);


my $acct_sel = "<select name=account_id>\n";
$acct_sel .= "<option value='0'>-N/S-\n";

my ($list, $total) = $customer->account->list();
foreach my $line (@$list) {
  $acct_sel .= "<option value='$line->[3]'>$line->[0]\n";
}
$acct_sel .= "</select>\n";

my $result = qq {
<form action=$SELF_URL>
<input type=hidden name=op value=users>
<input type=hidden name=uid value=$user->{UID}>
<input type=hidden name=account value=y>
<Table>
<tr><td>$_ACCOUNT:</td><td>$user->{ACCOUNT_NAME}</td></tr>
<tr><td>$_TO:</td><td>$acct_sel</td></tr>
</table>
<input type=submit name=change value=$_CHANGE>
</form> };


return $result;
}


#**********************************************************
# form_users()
#**********************************************************
sub user_form {
 my ($type, $user_info, $attr) = @_;
 my $tpl_form;


if ($type eq 'info') {

$tpl_form = qq{<table width=100%>
       <tr><td>$_LOGIN:</td><td>$user_info->{LOGIN}</td></tr>
       <tr><td>UID:</td><td>$user_info->{UID}</td></tr>
       <tr><td>$_FIO:</td><td>$user_info->{FIO}</td></tr>
       <tr><td>$_PHONE:</td><td>$user_info->{PHONE}</td></tr>
       <tr><td>$_ADDRESS:</td><td>$user_info->{ADDRESS}</td></tr>
       <tr><td>E-mail:</td><td>$user_info->{EMAIL}</td></tr>
       <tr><td>$_TARIF_PLAN:</td><td>$user_info->{TARIF_PLAN}</td></tr>
       <tr><td>$_CREDIT:</td><td>$user_info->{CREDIT}</td></tr>
       <tr><td>$_REDUCTION</td><td>$user_info->{REDUICTION} %</td></tr>
      <tr><td>$_SIMULTANEOUSLY:</td><td>$user_info->{SIMULTANEONSLY}</td></tr>
       <tr><td>$_ACTIVATE:</td><td>$user_info->{ACTIVATE}</td></tr>
       <tr><td>$_EXPIRE:</td><td>$user_info->{EXPIRE}</td></tr>
       <tr><td>IP:</td><td>$user_info->{IP}</td></tr>
       <tr><td>NETMASK:</td><td>$user_info->{NETMASK}</td></tr>
       <tr><td>$_SPEED (Kb)</td><td>$user_info->{SPEED}</td></tr>
       <tr><td>$_FILTERS</td><td>$user_info->{FILTER_ID}</td></tr>
       <tr><td>CID:</td><td>$user_info->{CID}</td></tr>
<tr><th colspan=2>:$_COMMENTS:</th></tr>
<tr><th colspan=2>$user_info->{COMMENTS}</th></tr>
</table>};
}
else { 
 use Tariffs;
 my $tariffs = Tariffs->new($db);
 my $info;
 my $variant_out = '';
 
 if (! defined($user_info->{UID})) {
   my $tariffs_list = $tariffs->list();
   $variant_out = "<select name=tarif_plan>";

  use Customers;	
  my $customers = Customers->new($db);
  my $account = $customers->account->info($FORM{account_id});

   $info = "<tr><td>$_COMPANY:</td><td>$account->{ACCOUNT_NAME}</td></tr>\n".
           "<tr><td>$_USER:*</td><td><input type=text name=login value=''></td></tr>\n";

   foreach my $line (@$tariffs_list) {
     $variant_out .= "<option value=$line->[0]";
     $variant_out .= ' selected' if ($line->[0] == $user_info->{TARIF_PLAN});
     $variant_out .=  ">$line->[0]:$line->[1]\n";
    }
   $variant_out .= "</select>";
  }
 else {
   $variant_out .= $user_info->{TP_NAME};
   $info = "<tr><td>$_DEPOSIT:</td><td>$user_info->{DEPOSIT}</td></tr>\n".
           "<tr><td>$_COMPANY:</td><td>$user_info->{ACCOUNT_NAME}</td></tr>\n";
  } 

my $disable = ($user_info->{DISABLE} > 0) ? 'checked' : '';

$tpl_form = qq{
<form action=$SELF_URL method=post>
<input type=hidden name=index value=14>
<input type=hidden name=account_id value='$FORM{account_id}'>
<input type=hidden name=uid value="$user_info->{UID}">
<table width=420 cellspacing=0 cellpadding=3>
$info

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
<tr><td>$_DISABLE:</td><td><input type=checkbox name=disable value='1' $disable></td></tr>
<tr><th colspan=2>:$_COMMENTS:</th></tr>
<tr><th colspan=2><textarea name=comments rows=5 cols=45>$user_info->{COMMENTS}</textarea></th></tr>
</table>
<p>
<input type=submit name=$action[0] value='$action[1]'>
</form>
};



}

print $tpl_form;

#return $tpl_form;

}


#**********************************************************
# form_users()
#**********************************************************
sub form_users {

my $LOGIN = $FORM{login} || '';
my $EMAIL = $FORM{email} || '';
my $FIO = $FORM{fio} || '';
my $PHONE = $FORM{phone} || 0;
my $ADDRESS = $FORM{address} || '';
my $ACTIVATE = $FORM{activate} || '0000-00-00';
my $EXPIRE = $FORM{expire} || '0000-00-00';
my $CREDIT = $FORM{credit} || '0.00';
my $REDUCTION = $FORM{reduction} || '0.00';
my $SIMULTANEONSLY = $FORM{simultaneously} || 0;
my $COMMENTS  = $FORM{comments} || '';
my $DISABLE = $FORM{disable} || 0;

my  $ACCOUNT_ID = $FORM{account_id} || 0;

my $IP = $FORM{ip} || '0.0.0.0';
my $NETMASK = $FORM{netmask} || '255.255.255.255';
my $TARIF_PLAN = $FORM{tarif_plan} || 0;
my $SPEED = $FORM{speed} || 0;
my $CID = $FORM{cid} || 0;
my $FILTER_ID = $FORM{FILTER_ID};

$uid = $FORM{uid};

 use Users;
 my $users = Users->new($db, $admin); 
	 
	 




if($uid > 0) {
  my $user_info = $users->info( $uid );
  if ($users->{errno}) {
    message('err', $_ERROR, "$uid  --[$users->{errno}] $err_strs{$users->{errno}}");	
    return 0;
   }

  print  "<table width=100% bgcolor=$_COLORS[2]><tr><td>$_USER:</td>
  <td><a href='$SELF_URL?op=users&uid=$users->{UID}'><b>$users->{LOGIN}</b></td></tr></table>\n";
  
  $LIST_PARAMS{UID}=$user_info->{UID};

  if($OP eq 'payments') {
    form_payments({ USER => $user_info });
    return 0;
   }
  elsif($OP eq 'fees') {
    form_fees({ USER => $user_info });
    return 0;
   }
  elsif($OP eq 'changes') {
    form_changes({ USER => $user_info });
    return 0;
   }
  

  print "<table width=100% border=1 cellspacing=1 cellpadding=2><tr><td valign=top>\n";
  if($FORM{password}) {
    my $password = chg_password('users', "$uid", { UID => $uid});
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
                 DISABLE => $DISABLE,
                 
                 IP => $IP,
                 NETMASK => $NETMASK,
                 SPEED => $SPEED,
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
    print form_chg_tp($user_info);
   }
  elsif ($FORM{account}) {
    print chg_account($user_info);
   }
  elsif ($FORM{del}) {
    $users->del();
    if ($users->{errno}) {
      message('err', $_ERROR, "[$users->{errno}] $err_strs{$users->{errno}}");	
     }
    else {
      message('info', $_DELETE, "$_DELETED");
     }
   }
  else {
    @action = ('change', $_CHANGE);
    user_form('test', $user_info);
   }


print "</td><td bgcolor=$_COLORS[3] valign=top width=180>
<table width=100% border=0><tr><td>
      <li><a href='$SELF?op=users&uid=$uid'>$_USER</a>
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
      <li><a href='$SELF_URL?op=changes&uid=$uid'>$_LOG</a>\n";

my %menus = ('password' => $_PASSWD,
             'chg_tp' =>   $_TARIF_PLAN,
             'account' =>  $_ACCOUNT,
             'nas' => $_NAS,
             'bank_info' => $_BANK_INFO,
 );
 

while(my($k, $v)=each (%menus) ) {
  print "<li><a href='$SELF_URL?op=users&uid=$uid&$k=y'>$v</a>\n";
}


print "<li><a href='$SELF?op=users&del=y&uid=$uid' onclick=\"return confirmLink(this, '$_USER: $user_info->{LOGIN} / $user_info->{UID} ')\">$_DEL</a>
</td></tr>
</table>
</td></tr></table>\n";
  return 0;
}
elsif ($FORM{add}) {
  my $user_info = $users->add({ LOGIN => $LOGIN,
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
                 DISABLE => $DISABLE,
                 
                 TARIF_PLAN => $TARIF_PLAN,
                 IP => $IP,
                 NETMASK => $NETMASK,
                 SPEED => $SPEED,
                 FILTER_ID => $FILTER_ID,
                 CID => $CID
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
    form_payments({ USER => $user_info });
    return 0;
   }
}


my $pages_qs = '';

if ($FORM{account_id}) {
  print "<p><b>$_ACCOUNT:</b> $FORM{account_id}</p>\n";
  $pages_qs .= "&account_id=$FORM{account_id}";
  $PARAMS{ACCOUNT_ID} = $FORM{account_id};
 }  

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

my $list = $users->list( { %LIST_PARAMS } );
my $table = Abills::HTML->table( { width => '100%',
                                   border => 1,
                                   title => [$_LOGIN, $_FIO, $_DEPOSIT, $_CREDIT, $_TARIF_PLANS, '-', '-'],
                                   cols_align => [left, left, right, right, left, center, center, center, center],
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
                                cols_align => [right, right],
                                rows => [ [ "$_TOTAL:", "<b>$users->{TOTAL}</b>" ] ]
                               } );
print $table->show();



}



#*******************************************************************
# Users and Variant NAS Servers
# allow_nass()
#*******************************************************************
sub allow_nass {
 my ($attr) = @_;
 
 my $vid = $FORM{vid} || 0;
 my @allow = split(/, /, $FORM{ids});
 my $qs = '';
 my %allow_nas = (); 

if ($attr->{USER}) {
  my $user = $attr->{USER};

  if ($FORM{change}) {
    $user->nas_add(\@allow);
    if ($user->{errno}) {
      message('err', $_ERROR, "[$user->{errno}] $err_strs{$user->{errno}}");	
     }
    else {
      message('info', $_INFO, "$_ALLOW $_NAS: $FORM{ids}");
     }
   }
  elsif($FORM{default}) {
    $user->nas_del();
    if ($user->{errno}) {
      message('err', $_ERROR, "[$user->{errno}] $err_strs{$user->{errno}}");	
     }
    else {
      message('info', $_NAS, "$_CHANGED");
     }
   }

  my ($nas_servers, $total) = $user->nas_list();
  foreach my $nas_id (@$nas_servers) {
     $allow_nas{$nas_id}='test';
   }

 }
elsif ($FORM{uid}) {
  $FORM{nas}='y';
  form_users();
  return 0;
 }
elsif($vid > 0) {

  print "$_VARIANT: [ <a href='$SELF?op=variants&chg=$vid'>$vid</a> ]";
  if ($FORM{change}) {
    $sql = "DELETE FROM vid_nas WHERE vid='$vid';";	
    $q = $db->do($sql) || die $db->errstr;
 
    foreach my $line (@allow) {
      $sql = "INSERT INTO vid_nas (nas_id, vid)
        VALUES ('$line', '$vid');";	
      $html->log_print('LOG_SQL', "$sql");
      $q = $db->do($sql) || die $db->errstr;
     }
    message('info', $_INFO, "$_ALLOW $_NAS: $FORM{ids}");
   }
  elsif($FORM{allow_all}) {
    $tarif->del();    
    message('info', $_INFO, "$_ALLOW $_NASS: $_ALL");	
   }

  $sql="SELECT nas_id FROM vid_nas WHERE vid='$vid';";
  $q = $db->prepare($sql) || die $db->strerr;
  $q ->execute();

  if ($q->rows > 0) {
    while(my($nas_id)=$q->fetchrow()) {
       $allow_nas{$nas_id}='test';
      }
   }
  else {
     $allow_nas{all}='test';	
   }
  $qs = "vid=$vid";  
}


my $nas = Nas->new($db);

my $out = "<form action='$SELF'>
<input type=hidden name=op  value=allow_nass>
<input type=hidden name=uid  value='$uid'>
<input type=hidden name=vid  value='$vid'>";

my $table = Abills::HTML->table( { width => '100%',
                                   border => 1,
                                   title => ["$_ALLOW", "ID", "$_NAME", "IP", "$_TYPE", "$_AUTH"],
                                   cols_align => [center, left, left, right, left, left]
                                  } );

my ($list, $total) = $nas->list();
my @auth_types = ('SQL', 'System');

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
 
# if ($q->rows > 0) {
#   my($id, $date, $new_variant) = $q -> fetchrow();
#   
#   $params = "<tr><th colspan=2 bgcolor=$_BG0>$_SHEDULE</th></tr>
#              <tr><td>$_DATE:</td><td>$date</td></tr>
#              <tr><td>$_CHANGE:</td><td>$new_variant:$vnames{$new_variant}</td></tr>
#              </table>
#              <input type=hidden name=del value='$id'>
#              <input type=submit name=delete value='$_DEL'>\n";
#  }
# else {
    $params .= "<tr><td>$_TO:</td><td><select name=tarif_plan>$variant_out</select></td></tr>";
    $params .= form_period($period);
    $params .= "</table><input type=submit name=set value=\"$_CHANGE\">\n";

#  }




my $result = "<form action=$SELF_URL>
<input type=hidden name=uid value='$user->{UID}'>
<input type=hidden name=chg_tp value=y>
<input type=hidden name=op value=users>
<table width=400 border=0>
<tr><td>$_FROM:</td><td bgcolor=$_BG2>$user->{TARIF_PLAN} $user->{TP_NAME} [<a href='$SELF?op=tp&chg=$user->{TARIF_PLAN}' title='$_VARIANTS'>$_VARIANTS</a>]</td></tr>
$params
</form>\n";



 return $result;
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
	$admins->action_del( $FORM{del} );
  if ($admins->{errno}) {
    message('err', $_ERROR, "[$admins->{errno}] $err_strs{$admins->{errno}}");	
   }
  else {
    message('info', $_DELETED, "$_DELETED [$FORM{del}]");
   }
 }

 	

#u.id, aa.datetime, aa.actions, a.name, INET_NTOA(aa.ip),  aa.uid, aa.aid, aa.id
 	
my $list = $admins->action_list( { %LIST_PARAMS } );
my $table = Abills::HTML->table( { width => '100%',
                                   border => 1,
                                   title => ['#', 'UID',  $_DATE,  $_CHANGE,  $_ADMIN,   'IP', '-'],
                                   cols_align => [right, left, right, left, left, right, center],
                                   qs => $pages_qs,
                                   pages => $admins->{TOTAL}
                                   
                                  } );
foreach my $line (@$list) {
  my $delete = $html->button($_DEL, "op=changes$pages_qs&del=$line->[0]", "$_DEL ?"); 
  $table->addrow("<b>$line->[0]</b>", "<a href='$SELF_URL?op=users&uid=$line->[6]'>$line->[1]</a>", $line->[2], $line->[3], 
   $line->[4], $line->[5], $delete);
}

print $table->show();
$table = Abills::HTML->table( { width => '100%',
                                cols_align => [right, right],
                                rows => [ [ "$_TOTAL:", "<b>$admins->{TOTAL}</b>" ] ]
                               } );
print $table->show();


}



#**********************************************************
# form_admins()
#**********************************************************
sub form_admins {

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
       message('info', $_INFO, "$_ADMINS: $admin->{NAME}<br>$_PASSWD $_CHANGED");
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
elsif($FORM{aid}) {
  my $admin = $admins->info($FORM{aid});
	
  my $table = Abills::HTML->table( { width => '100%',
                                     rows => [ [ "$_ADMIN:", "<b>$admin->{NAME}</b>" ] ],
                                     rowcolor => $_COLORS[2]
                                  } );
  print $table->show();
  $LIST_PARAMS{AID} = $admin->{AID};

	if ($OP eq 'changes') {
		 form_changes({ ADMIN => $admin });
	 }
	
	return 0;
}
elsif($FORM{del}) {
  $admin->del($FORM{del});
  if ($admin->{errno}) {
     message('err', $_ERROR, $err_strs{$admin->{errno}});	
   }
}



my $disable = ($admin->{DISABLE} > 0) ? 'checked' : '';

print << "[END]";
<form action=$SELF_URL>
<input type=hidden name=op value=admins>
<input type=hidden name=chg value='$FORM{chg}'>
<table>
<tr><td>ID:</td><td><input type=text name=id value="$admin->{AID}"></td></tr>
<tr><td>$_FIO:</td><td><input type=text name=name value="$admin->{NAME}"></td></tr>
<tr><td>$_DISABLE:</td><td><input type=checkbox name=disable value='1' $disable></td></tr>
<!-- <tr><td>$_GROUPS:</td><td><input type=text name=name value="$name"></td></tr> -->
</table>
<input type=submit name=$action[0] value='$action[1]'>
</form>
[END]


my $table = Abills::HTML->table( { width => '100%',
                                   border => 1,
                                   title => ['ID', $_NAME, $_FIO, $_CREATE, $_GROUPS, '-', '-', '-', '-', '-', '-'],
                                   cols_align => [right, left, left, right, left, center, center, center, center, center, center],
                                  } );

my $list = $admins->list();
foreach my $line (@$list) {
  $table->addrow(@$line, "<a href='$SELF_URL?op=admins&permissions=y&aid=$line->[0]'>$_PERMISSION</a>", 
   "<a href='$SELF_URL?op=changes&aid=$line->[0]'>$_LOG</a>",
   "<a href='$SELF_URL?op=admins&password=y&aid=$line->[0]'>$_PASSWD</a>",
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
 my ($op, $id, $attr)=@_;
 print "<h3>$_CHANGE_PASSWD</h3>\n";

 my $hidden_inputs = ($attr->{UID}) ? "<input type=hidden name=uid value='$attr->{UID}'>": '';

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

$menu_items{15}{14}=$_LOG;
$op_names{15}='changes';
$functions{15}=\&form_changes;

$menu_items{16}{14}=$_TARIF_PLAN;
$op_names{16}='chg_tp';
$functions{16}=\&form_chg_tp;

$menu_items{17}{14}=$_PASSWD;
$op_names{17}='password';
$functions{17}=\&password;

$menu_items{18}{14}=$_NAS;
$op_names{18}='allow_nass';
$functions{18}=\&allow_nass;

$menu_items{19}{14}=$_STATS;
$op_names{19}='';
$functions{19}=\&user_stats;

#Payments
$menu_items{2}{0}=$_PAYMENTS;
$op_names{2}='payments';
$functions{2}=\&form_payments;

# Fees
$menu_items{3}{0}=$_FEES;
$op_names{3}='fees';
$functions{3}=\&form_fees;

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

$menu_items{60}{5}=$_NAS;
$op_names{60}='nas';
$menu_items{61}{60}="IP POOLs";
$menu_items{62}{60}=$_NAS_STATISTIC;

#exchange_rate
$menu_items{65}{5}=$_EXCHANGE_RATE;
$op_names{65}='er';
$functions{65}=\&exchange_rate;


$menu_items{70}{5}=$_TARIF_PLANS;
$menu_items{71}{70}=$_LIST;

$menu_items{80}{5}='SQL';
$op_names{80}=sql_browser;
$menu_items{81}{80}='SQL Browser';
$menu_items{82}{80}='SQL Backup';

$menu_items{85}{5}=$_SHEDULE;
$op_names{85}='shedule';
$functions{85}=\&form_shedule;


$menu_items{99}{5}=_FUNCTIONS_LIST;
$op_names{99}='flist';
$functions{99}=\&flist;

$menu_items{6}{0}=$_MODULES;
$op_names{6}='modules';

$menu_items{101}{6}=_DOCS;
$menu_items{102}{6}=_MAIL;
$menu_items{103}{6}=_VoIP;
$menu_items{104}{6}=_DOCSIS;

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

#print "$index $root_index<br>";
if ($root_index > 0) {
  my $ri = $root_index-1;
  if (! defined($permissions{$ri})) {
	  message('err', $_ERROR, "Access deny");
	  exit 0;
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
  
  return 0 if ($root_index < 1);

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


#**********************************************************
# form_payments
#**********************************************************
sub form_payments () {
 my ($attr) = @_; 
 
 my $DESCRIBE = $FORM{descr} || '';
 my $MU = $FORM{er} || 1;
 my $pages_qs = '';

 use Finance;
 my $payments = Finance->payments($db, $admin);

if (defined($attr->{USER})) { 
  my $user = $attr->{USER};
  $pages_qs = "&uid=$user->{UID}";

  if ($FORM{add} && $FORM{sum})	{
    my $er = $payments->exchange_info($MU);

    $payments->add($user, $FORM{sum}, { DESCRIBE => $DESCRIBE,
    	                            ER => $er->{EX_RATE} }  );  

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
my $er_sel = "<select name=er>\n";
foreach my $line (@$er) {
  $er_sel .= "<option value=$line->[4]";
  $er_sel .= ">$line->[1] : $line->[2]\n";
}
$er_sel .= "</select>\n";

print << "[END]";	
<form action=$SELF_URL>
<input type=hidden name=op value=payments>
<input type=hidden name=uid value=$user->{UID}>
<table>
<tr><td>$_SUM:</td><td><input type=text name=sum></td></tr>
<tr><td>$_DESCRIBE:</td><td><input type=text name=descr></td></tr>
<tr><td>$_EXCHANGE_RATE:</td><td>$er_sel</td></tr>
</table>
<input type=submit name=add value='$_ADD'>
</form>
[END]


}
elsif ($FORM{uid}) {
	 form_users();
	 return 0;
 }



if (! defined($permissions{1}{2})) {
  return 0;
}


my $list = $payments->list( { %LIST_PARAMS } );
my $table = Abills::HTML->table( { width => '100%',
                                   border => 1,
                                   title => ['ID', $_LOGIN, $_DATE, $_SUM, $_DESCRIBE, $_ADMINS, 'IP',  $_DEPOSIT, '-'],
                                   cols_align => [right, left, right, right, left, left, right, right, center],
                                   qs => $pages_qs,
                                   pages => $payments->{TOTAL}
                                  } );


foreach my $line (@$list) {
  my $delete = ($permissions{1}{3}) ?  $html->button($_DEL, "op=payments&del=$line->[0]&uid=$line->[8]", "$_DEL ?") : ''; 
  $table->addrow("<b>$line->[0]</b>", "<a href='$SELF_URL?op=users&uid=$line->[8]'>$line->[1]</a>", $line->[2], 
   $line->[3], $line->[4],  "$line->[5]", "$line->[6]", "$line->[7]", $delete);
}

print $table->show();

$table = Abills::HTML->table( { width => '100%',
                                cols_align => [right, right, right, right],
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
                                   cols_align => [left, left, right, center, center],
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
  $pages_qs = "&uid=$user->{UID}";

  if ($FORM{get} && $FORM{sum}) {
    # add to shedule
    if ($period == 1) {
      use Shedule;
      $FORM{date_m}++;
      my $shedule = Shedule->new($db, $admin); 
      $shedule->add( { DESCRIBE => $DORM{DESCR}, 
      	               D => $FROM{date_d},
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
    if ($admins->{errno}) {
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
<tr><td>$_SUM:</td><td><input type=text name=sum value='$sum'></td></tr>
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
                                   cols_align => [right, left, right, right, left, left, right, right, center],
                                   qs => $pages_qs,
                                   pages => $fees->{TOTAL}
                                  } );
foreach my $line (@$list) {
  my $delete = ($permissions{1}{3}) ?  $html->button($_DEL, "op=fees&del=$line->[0]&uid=$line->[8]", "$_DEL ?") : ''; 

  $table->addrow("<b>$line->[0]</b>", "<a href='$SELF_URL?op=users&uid=$line->[8]'>$line->[1]</a>", $line->[2], 
   $line->[3], $line->[4],  "$line->[5]", "$line->[6]", "$line->[7]", $delete);
}

print $table->show();

my $table = Abills::HTML->table( { width => '100%',
                                   cols_align => [right, right, right, right],
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

my %SEARCH_TYPES = ('users' => $_USERS,
                    'payments' => $_PAYMENTS,
                    'fees' => $_FEES,
                    'last' => $_LAST_LOGIN,

                    'IP' => 'IP',
                    'CID' => 'CID',
                    'FIO' => $_FIO
);

my $type_select = "<select type=type>\n";
$type_select = "</select>\n";

my $tpl_form = qq{
<form action=$SELF_URL>
<table>
<tr><td>UID:</td><td><input type=text name=uid value='$FORM{UID}'></td></tr>
<tr><td>$_TYPE:</td><td>$type_select</td></tr>
<tr><td>$_DATE:</td><td>
<table width=100%>
<tr><td>$_FROM: </td><td>$from_date</td></tr>
<tr><td>$_TO</td><td>$to_date</td></tr>
</table>
</td></tr>
</table>
<input type=submit name=search value=$_SEARCH>
</form>
};

 print $tpl_form;	
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
                                   cols_align => [right, right, right, right, right, left, right, right, right, center],
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
                                cols_align => [right, right, right, right],
                                rows => [ [ "$_TOTAL:", "<b>$shedule->{TOTAL}</b>" ] ]
                               } );
print $table->show();





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

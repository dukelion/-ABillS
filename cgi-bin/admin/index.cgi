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
my $sql = Abills::SQL->connect('mysql', 'localhost', 'stats', 'asm', 'test1r');
my $db = $sql->{db};
my $admins = Admins->new($db);
$conf{secretkey}="test12345678901234567890";
$conf{passwd_length}=6;
$conf{username_length}=15;



require "../../language/$html->{language}.pl";
my %err_strs = (
  1 => $_ERROR,
  2 => $_NOT_EXIST,
  3 => $ERR_SQL,
  4 => ERROR_WRONG_PASSWORD,
  5 => ERROR_WRONG_CONFIRM,     
  6 => ERROR_SHORT_PASSWORD
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
                 $_PAYMENTS, 
                 $_FEES, 
                 $_REPORTS,
                 $_SYSTEM,
                 $_MODULES 
                );

 my @actions = ([$_SA_ONLY, $_ADD, $_LIST, $_PASSWD, $_CHANGE, $_DEL, $_ALL],  # Users
                [$_LIST, $_ADD, $_EXCHANGE_RATE, $_DEL, $_ALL],                # Payments
                [$_LIST, $_ADD, $_DEL, $_ALL],                                 # Fees
                [$_ALL],                                                       # reports view
                [$_ALL, 'tarif_plans'],                                        # system magment
                [$_ALL, 'users']                                               # Modules managments
               );


my %op_names = ();
my %menu_items = ();
my %functions = ();
my $index = $FORM{index} || 0;
my $root_index = 0;

my %main_menu = ();
my $navigat_menu = mk_navigator();

print "<table border=0 width=100%><tr><td valign=top width=200 bgcolor=$_COLORS[2] rowspan=2><p>\n";
print $html->menu(1, 'op', "", \%main_menu);
sub_menu($index);
print "</td><td bgcolor=$_COLORS[0]>$navigat_menu";
print "</td></tr><tr><td>";

if ($functions{$index}) {
  $functions{$index}->();
}
else {
  print "hello $index / $root_index";	
}

#if ($OP eq 'admins') { form_admins(); }
#if ($OP eq 'system') { system_cfg(); }
#else {
# form_admins();
#}

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
# form_users()
#**********************************************************
sub form_users {

 use Users;
 my $users = Users->new($db); 


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
$menu_items{1}{0}=$_USERS;
$op_names{1}='users';
$functions{1}=\&form_users;

$menu_items{12}{1}=$_ADD;
$op_names{12}='users';
$functions{12}=\&form_users;

$menu_items{13}{1}=$_FEES;
$op_names{13}='users';
$functions{13}=\&form_users;

$menu_items{14}{1}=$_LIST;
$op_names{14}='users';
$functions{14}=\&form_users;

$menu_items{11}{1}=$_PAYMENTS;
$op_names{11}='payments';
$functions{11}=\&form_users;


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
   $OP = $op_names{$FORM{$root_index}};
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







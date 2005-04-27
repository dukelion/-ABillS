#!/usr/bin/perl
# Web interface for accounting system
# ~AsmodeuS~ (2004-12-05)
# asm@asmodeus.com.ua

use vars qw($begin_time);
BEGIN {
#Check the Time::HiRes module (available from CPAN)
 eval { require Time::HiRes; };
 if (! $@) {
    Time::HiRes->import(qw(gettimeofday));
    $begin_time = gettimeofday();
   }
 else {
    $begin_time = 0;
  }
}

require 'config.pl';
#$foreground=1;
use Abwconf;
$db=$Abwconf::db;
use Base; # Modul with base tools
require 'messages.pl';

$logfile = 'abills.log';
$logdebug = 'abills.debug';
$debug = 1;

my $web_path='/billing/admin/';
my $domain = $ENV{SERVER_NAME};

$conf{passwd_length}=6;
$conf{username_length}=15;


print "Content-Type: text/html\n";

if (defined($FORM{colors})) {
  my $cook_colors = (defined($FORM{default})) ?  '' : $FORM{colors};
  print "Set-Cookie: colors=$cook_colors; path=$web_path; domain=$domain; expires=\"Fri, 1-Jan-2038 00:00:01\";\n";
 }


if (defined($FORM{language})) {
  print "Set-Cookie: language=$FORM{language}; path=$web_path; domain=$domain; expires=\"Fri, 1-Jan-2038 00:00:01\";\n";
 }

print "Set-Cookie: opid=$FORM{opid}; path=$web_path; domain=$domain;\n\n";


header();
$conf{ex_trafic}='yes';
my $uid = 0;
my $login = '';

if ($FORM{uid}) {
  $uid = $FORM{uid};
  $login = get_login($uid);
  $login_link = "<a href=\"$SELF?op=users&chg=$uid\">$login</a>";
}


require "../../language/$language.pl";
%main_menu = ('1::users', $_USERS,
              '2::payments', $_PAYMENTS,
              '3::stats', $_STATS, 
              '4::variants', $_VARIANTS,
              '5::inp', $_INPAYMENTS,
              '6::sql_online', 'Online',
              '7::last', $_LAST,
              '8::search', $_SEARCH,
              '9::other', $_OTHER
             );


$aid=check_permits("$admin_name");
#if ($aid == 0) {
#print "<center>\n";
#  message('err', $_ERROR, 'Access denied');
#print "</center>\n";
#  return 0;	
#}


print "<table width=100% border=0 cellspacing=0 cellpadding=0>
<tr><td bgcolor=$_COLORS[9]>
<table width=100% border=0 cellspacing=1 cellpadding=1>
<tr><td bgcolor=$_COLORS[3]>&nbsp;<b>$_DATE:</b> $DATE $TIME /<b>Admin:</b> <a href='$SELF?op=profile' title='$_PROFILE'>$admin_name</a> <i>($admin_ip)</i>/\n";
get_online();
report_new();




print "</td></tr>
<tr><td bgcolor=$_COLORS[10]>
<table width=100%><tr bgcolor=$_COLORS[0]>\n";

show_menu(0, 'op', "", \%main_menu);

print "</tr></table>
</td></tr></table>
</td></tr></table>
<center>\n";



%shedule_type = ('tp' => $_VARIANT, 
                 'fees' => $_FEES,
                 'message' => $_MESSAGES
 );


if ($op eq 'stats')      { stats();       }
elsif ($op eq 'users')   { users();       }
elsif ($op eq 'payments'){ form_payments();    }
elsif ($op eq 'variants'){ variants();    }
elsif ($op eq 'fees')    { form_fees();   }
elsif ($op eq 'inp')     { inpayments();  }
elsif ($op eq 'options') { options();     }
elsif ($op eq 'bm')      { back_money();  }
elsif ($op eq 'sendmsg') { send_mail_form(); }
elsif ($op eq 'other')   { other();       }
elsif ($op eq 'nas_stats'){ nas_stats();  }
elsif ($op eq 'sql_backup') { sql_backup(); }
elsif ($op eq 'search')  { search();      }
elsif ($op eq 'admins')  { form_admins(); }
elsif ($op eq 'online')  { online();      }
elsif ($op eq 'changes') { changes();     }
elsif ($op eq 'adduser') { form_user_info(); }
elsif ($op eq 'cor')     { cor();         }
elsif ($op eq 'last')    { last_logins(); }
elsif ($op eq 'filters') { filters();     }
elsif ($op eq 'chg_uvariant') { form_chg_vid();   }
elsif ($op eq 'errlog')	 { errlog();      }
elsif ($op eq 'bank_info'){ bank_info();  }
elsif ($op eq 'nas')     { nas();  }
elsif ($op eq 'sql_online')  { sql_online();  }
elsif ($op eq 'allow_nass')  { allow_nass();      }
elsif ($op eq 'messages'){ msgs_admin();  }
elsif ($op eq 'trafic_tarifs'){ trafic_tarifs(); }
elsif ($op eq 'groups')  { groups();      }
elsif ($op eq 'docs' || defined($FORM{docs}))  { $path='../';
	                                         require "docs.cgi";    }
elsif ($op eq 'sdetail') { sdetail("$FORM{uid}", "$FORM{sid}"); }
elsif ($op eq 'icards')  { icards();      }
elsif ($op eq 'dunes')   { require "../win_dunes.cgi"; }
elsif ($op eq 'test')    { test(); }
elsif ($op eq 'er')      { exchange_rate();     }
elsif ($op eq 'admin_perms')  { admin_perms();  }
elsif ($op eq 'holidays'){ holidays();    }
elsif ($op eq 'profile') { profile();     }
elsif ($op eq 'shedule') { form_shedule();}
elsif ($op eq 'templates'){templates();   }
elsif ($op eq 'sql_cmd') { sql_cmd();     }
#elsif ($op eq 'graffic') { profile();   }
elsif ($op eq 'not_ended') { not_ended(); }
else  { sql_online(); }

if ($begin_time > 0) {
  my $end_time = gettimeofday;
  my $gen_time = $end_time - $begin_time;
  $conf{version} .= " (Generation time: $gen_time)";
}
footer("v. $conf{version}");
#my $rc  = $db->disconnect;







#*******************************************************************
# Manager  and  Admin groups
# groups()
#*******************************************************************
sub groups  {
  print '<h3>'. $_GROUPS .'</h3>';

my $id = $FORM{id} || 0;
my $describe = $FORM{describe} || '';
my $name = $FORM{name} || '';

$action = ('add', _ADD);

if ($FORM{add}) {
  $q = $db->do("INSERT INTO groups (id, name, describe) VALUES
    ('$id', '$name', '$describe');") || die $db->errstr;

  if ($db->err == 5) {
    message('err', $_ERROR, "$_EXIST");
     }
  elsif($db->err > 0) {
    message('err', $_ERROR, $db->errstr);
     }
  else {
    message('info', $_INFO, $_ADDED);
   }
}
elsif($FORM{change}) {
  $sql = "";

  if($db->err > 0) {
    message('err', $_ERROR, $db->errstr);
     }
  else {
    message('info', $_INFO, $_CHANGED);
   }
}
elsif($FORM{chg}) {


  if($db->err > 0) {
    message('err', $_ERROR, $db->errstr);
     }
  else {
    message('info', $_INFO, $_CHANGING);
   }
  $action = ('change', _CHANGE);
}
elsif($FORM{del}) {

  if($db->err > 0) {
    message('err', $_ERROR, $db->errstr);
     }
  else {
    message('info', $_INFO, $_DELETED . "# $params");
   }
  $action = ('change', _CHANGE);
}

print << "[END]";
<form action=$SELF>
<input type=hidden name=op value=groups>
<table>
<tr><td>ID:</td><td><input type=text name=name value='$id'></td></tr>
<tr><td>$_NAME:</td><td><input type=text name=name value='$name'></td></tr>
<tr><td>$_DESCRIBE:</td><td><input type=text name=name value='$describe'></td></tr>
</table>
<input type=submit name=$action[0] value=$action[1]>
</form>
[END]

}



#********************************************************************
# Search
# search()
#********************************************************************
sub search {
 print "<h3>". $_SEARCH ."</h3>";

$word=$FORM{word};
$type=$FORM{type};
$ip = $FORM{ip} || '0.0.0.0';

%types = ('fio'   => $_FIO,
          'phone' => $_PHONE,
          'registration' => $_REGISTRATION, 
          'ip'    => 'IP',
          'speed' => $_SPEED,
          'id' => $_LOGIN,
          'CID' => 'cid');

my $types_array = '';
while( ($key, $val)= each(%types)) {
  $types_array .= "<option value='$key'";
  $types_array .= ' selected' if ($type eq $key);
  $types_array .= "> $val\n";	
}

print << "[END]";
<hr>
$_USERS
<form action="$SELF">
<input type=hidden name=op value="search">
<table border=1>
<tr><td>$_TEXT (&lt;, &gt;, *): </td><td><input type=text name=word value='$word'></td></tr>
<tr><td>$_TYPE:</td><td><select name=type>
$types_array
</select></td></tr>
<tr><td></td><td></td></tr>
</table>

<input type=submit name=search value="$_SEARCH">
</form>
[END]

if ($FORM{word}) {

  $WHERE='WHERE ';

  if (($type eq 'id') || ($type eq 'fio') 
        || ($type eq 'registration')
        || ($type eq 'CID')) {
    $word =~ s/\*/\%/g;
    $WHERE .= "$type LIKE '$word'";
   }
  elsif (($type eq 'ip')) {

    if ($word =~ s/^(<)|^(>)//) {
       $word = $word;
       $par = $1 || $2;
     }
    else {
       $par = '=';
     } 

    $WHERE .= "$type $par INET_ATON('$word')";
    # ="INET_NTOA($type)";

   }
  elsif (($type eq 'speed') || ($type eq 'phone')) {
    if ($word =~ s/^(<)|^(>)//) {
      $word = $word;
      $par = $1 || $2;
     }
    else {
      $par = '=';
     } 
    $WHERE .= "$type $par $word";
   } 

  $word = $FORM{word};
  my $column = '-';
  
  if ($type eq 'ip') {
     $column = "INET_NTOA($type)";
   }
  else {
     $column = "$type";
   }
 
  $sql="SELECT uid, id, $column FROM users $WHERE ORDER BY 2 LIMIT $pg, $max_recs;";
  log_print('LOG_SQL', $sql);
  %pages = pages('id', 'users', "$WHERE", "op=search&type=$type&word=$word", "$pg");  

print "<b>$_RESULT:</b><br> <b>$_TOTAL:</b> $pages{count}<hr width=600>\n";	
print "<Table width=400>\n".
"<tr bgcolor=$_BG0><th>$_LOGIN</th><th>". $types{"$type"} ."</th></tr>\n";

  $q = $db->prepare($sql) || die $db->strerr;
  $q ->execute();

while(my($uid, $login, $val)=$q -> fetchrow()) {
  $bg=($bg eq $_BG1)? $_BG2 : $_BG1 ;
  print "<tr bgcolor=$bg><td><a href='$SELF?op=users&chg=$uid'>$login</a></td><td>$val</td></tr>\n";
}

print "</table>\n";

print $pages{pages};
}




}

#*******************************************************************
# Set filters for clients
# filters()
#*******************************************************************
sub filters {
  print "<h3>$_FILTERS</h3>\n";
  my $descr = $FORM{descr} || '';
  my $filter = $FORM{filter} || '';
  my @action = ('add', "$_ADD");

if ($FORM{add}) {
  $sql = "INSERT INTO filters (filter, descr) VALUES ('$filter', \"$descr\");";

  log_print('LOG_SQL', "$sql");
    my $q = $db->prepare("$sql") || die $db->strerr;
    $q -> execute ();

    if ($db->err == 1062) {
       message('err', "$_ERROR", "$ip $_EXIST");
      }
    elsif($db->err > 0) {
       message('err', "$_ERROR", $db->errstr . " - N:". $db->err);
      }
    else {
       message('info', "$_INFO", "$_ADDED");
      }
}
elsif($FORM{change}) {
  $sql="UPDATE filters SET
    filter='$filter',
    descr='$descr'
   WHERE id='$FORM{chg}';";
  print $sql;
  
  log_print('LOG_SQL', "$sql");
  $q = $db->do($sql) || die $db->strerr;
  message('info', "$_INFO", "$_CHANGED [$FORM{chg}]");
 }
elsif($FORM{chg}) {
  $sql="SELECT filter, descr  FROM filters WHERE id='$FORM{chg}';";
  log_print('LOG_SQL', "$sql");
  $q = $db->prepare($sql) || die $db->strerr;
  $q ->execute();
  ($filter, $descr)=$q->fetchrow();
  message('info', "$_INFO", "$_CHANGING [$FORM{chg}]");
  @action = ('change', "$_CHANGE");
 }
elsif($FORM{del}) {
   $sql = "DELETE FROM filters WHERE id='$FORM{del}'";
   log_print('LOG_SQL', "$sql");
   my $q = $db->do("$sql") || die $db->strerr;
   message('info', "$_ERROR", "$_DELETED ID: $FORM{del}");
}


print << "[END]";
<form action=$SELF>
<input type=hidden name=op value='filters'>
<input type=hidden name=chg value='$FORM{chg}'>
<table>
<tr><td>ID:</td><td>$FORM{chg}</td></tr>
<tr><td>$_DESCRIBE:</td><td><input type=text name=descr value='$descr'></td></tr>
<tr><td>FILTER:</td><td><input type=text length=50 name=filter value='$filter'></td></tr>
</table>
<input type=submit name=$action[0] value='$action[1]'>
</form>
[END]


  $sql="SELECT id, filter, descr  FROM filters;";
  log_print('LOG_SQL', "$sql");

#%pages = pages('id', 'users', "$WHERE", "op=search&type=$type&word=$word", "$pg");  
  $q = $db->prepare($sql) || die $db->strerr;
  $q ->execute();

print "<table width=640>\n";
 @caption = ("ID", "FILTER", "$_DESCRIBE", "-", "-");
 show_title($sort, $desc, "$pg", "$op", \@caption);

while(($id, $filter, $descr)=$q->fetchrow()) {
   $bg = ($bg eq $_BG1) ? $_BG2 : $_BG1;
   $button = "<A href='$SELF?op=filters&del=$id'
        onclick=\"return confirmLink(this, 'FILTER: $descr ($id):')\">$_DEL</a>";
  
   print "<tr bgcolor=$bg><td align=right>$id</td><td>$filter</td><td>$descr</td>".
    "<td><a href='$SELF?op=filters&chg=$id'>$_CHANGE</a></td><td>$button</td></tr>\n";
}

print "</table>\n";
}

#*******************************************************************
#show error log
# errlog
#*******************************************************************
sub errlog {
  print "<h3>$_ERROR_LOG</h3>\n";

  print "<table><tr><td>";

  my $logfile = "/usr/abills/var/log/abills.log";
if ($uid) {
  print "<br><b>$_USER:</b> $login_link<br>
  <pre>";
  show_log("$login", "", "$logfile", 100);
#  radius_log($uid);
  print '</pre>';
}
else {
  $rad_rows=1000;
  print "<pre>";
  show_log("", "", "$logfile", 100);
#  radius_log("");
  print '</pre>';
}


print "</td></tr></table>\n";
}

#*******************************************************************
#
# ippool()
#*******************************************************************
sub ippools {

 print "<h3>IP POOLS</h3>\n";

 my $counts = $FORM{counts} || 0;
 my $sip  = $FORM{sip} || '0.0.0.0';
 
if ($FORM{add}) {
  $sql = "INSERT INTO ippools (nas, ip, counts) VALUES ('$FORM{ippools}', INET_ATON('$sip'), '$counts');";
  log_print('LOG_SQL', "$sql");
    my $q = $db->prepare("$sql") || die $db->strerr;
    $q -> execute ();

    if ($db->err == 1062) {
       message('err', "$_ERROR", "$ip $_EXIST");
      }
    elsif($db->err > 0) {
       message('err', "$_ERROR", $db->errstr . " - N:". $db->err);
      }
    else {
       message('info', "$_INFO", "$_ADDED");
      }
}
elsif($FORM{del}) {
   $sql = "DELETE FROM ippools WHERE id='$FORM{del}'";
   log_print('LOG_SQL', "$sql");
   my $q = $db->prepare("$sql") || die $db->strerr;
   $q -> execute();
   message('err', "$_ERROR", "$_DELETED ID: $FORM{del}");
}

if ($FORM{ippools} > 0) {
print << "[END]";
<a href='$SELF?op=nas&chg=$FORM{ippools}'>NAS SERVERS</a>
<form action=$SELF>
<input type=hidden name=op value=nas>
<input type=hidden name=ippools value=$FORM{ippools}>
<table>
<tr><td>NAS:</td><td>$FORM{ippools}</td></tr>
<tr><td>FIRST IP:</td><td><input type=text name=sip value='$sip'></td></tr>
<tr><td>COUNT:</td><td><input type=text name=counts value='$counts'></td></tr>
</table>
<input type=submit name=add value="add">
</form>
<hr>
<a href='$SELF?op=nas&ippools=-1'>$_SHOW_ALL</a>
<hr>
[END]
$WHERE = " and nas.id='$FORM{ippools}'";
print "NAS: $FORM{ippools}";
}

  $sql="SELECT pool.id, nas.nas_identifier, INET_NTOA(pool.ip), INET_NTOA(pool.ip + pool.counts), pool.counts, nas.id
    FROM ippools pool, nas
    WHERE pool.nas=nas.id $WHERE;";

  log_print('LOG_SQL', "$sql");

#%pages = pages('id', 'users', "$WHERE", "op=search&type=$type&word=$word", "$pg");  

  $q = $db->prepare($sql) || die $db->strerr;
  $q ->execute();


print "<TABLE width=640 cellspacing=0 cellpadding=0 border=0><TR><TD bgcolor=$_BG4>
<TABLE width=100% cellspacing=1 cellpadding=0 border=0>
    <tr bgcolor=$_BG0><th>NAS</th><th>FIRST</th><th>LAST</th><th>$_COUNT</th><th>-</th></tr>
    <COLGROUP>
    <COL align=left span=1>
    <COL align=right span=3>
  </COLGROUP>\n";

while(($id, $nas, $first, $last, $counts, $nas_id)=$q->fetchrow()) {
   $bg = ($bg eq $_BG1) ? $_BG2 : $_BG1;
   $button = "<A href='$SELF?op=nas&ippools=$FORM{ippools}&&del=$id'
        onclick=\"return confirmLink(this, 'IP POOLS FROM $ip TO $last ($_COUNT: count)')\">$_DEL</a>";
   print "<tr bgcolor=$bg><td><a href='$SELF?op=nas&chg=$nas_id'>$nas</a></td><td>$first</td><td>$last</td><td>$counts</td><td>$button</td></tr>\n";
}

print "</table></td></tr></table>\n";

}


#*******************************************************************
# Users and Variant NAS Servers
# allow_nass()
#*******************************************************************
sub allow_nass {
 print "<h3>$_NASS</h3>\n";
 my $vid = $FORM{vid} || 0;
 my @allow = split(/, /, $FORM{ids});
 my $qs = '';
 my %allow_nas = (); 

if ($uid > 0) {
  print "$_USER: $login_link\n";
  if ($FORM{change}) {
  
    $sql = "DELETE FROM users_nas WHERE uid='$uid';";	
    $q = $db->do($sql) || die $db->errstr;
 
    foreach my $line (@allow) {
      $sql = "INSERT INTO users_nas (nas_id, uid)
        VALUES ('$line', '$uid');";	
      log_print('LOG_SQL', "$sql");
      $q = $db->do($sql) || die $db->errstr;
     }
    message('info', $_INFO, "$_ALLOW $_NAS: $FORM{ids}");
   }
  elsif($FORM{default}) {
    $sql = "DELETE FROM users_nas WHERE uid='$uid';";	
    log_print('LOG_SQL', "$sql");
    $q = $db->do($sql) || die $db->errstr;
    message('info', $_INFO, "$_ALLOW $_NASS: $_ALL");	
   }
  $qs = "uid=$uid";
  $sql="SELECT nas_id FROM users_nas WHERE uid='$uid';";
  $q = $db->prepare($sql) || die $db->strerr;
  $q ->execute();

  if ($q->rows > 0) {
    while(my($nas_id)=$q->fetchrow()) {
       $allow_nas{$nas_id}='test';
      }
   }
  else {
    $sql="SELECT variant FROM users WHERE uid='$uid';";
    $q = $db->prepare($sql) || die $db->strerr;
    $q ->execute();
    my ($uvid)=$q->fetchrow();
    $sql="SELECT nas_id FROM vid_nas WHERE vid='$uvid';";
    $q = $db->prepare($sql) || die $db->strerr;
    $q ->execute();
    if ($q->rows > 0) {
      while(my($nas_id)=$q->fetchrow()) {
        $allow_nas{$nas_id}='test';
       }
     }
   }
}
elsif($vid > 0) {
  print "$_VARIANT: [ <a href='$SELF?op=variants&chg=$vid'>$vid</a> ]";
  if ($FORM{change}) {
    $sql = "DELETE FROM vid_nas WHERE vid='$vid';";	
    $q = $db->do($sql) || die $db->errstr;
 
    foreach my $line (@allow) {
      $sql = "INSERT INTO vid_nas (nas_id, vid)
        VALUES ('$line', '$vid');";	
      log_print('LOG_SQL', "$sql");
      $q = $db->do($sql) || die $db->errstr;
     }
    message('info', $_INFO, "$_ALLOW $_NAS: $FORM{ids}");
   }
  elsif($FORM{allow_all}) {
    $sql = "DELETE FROM vid_nas WHERE vid='$vid';";	
    log_print('LOG_SQL', "$sql");
    $q = $db->do($sql) || die $db->errstr;
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

 	
 $sql="SELECT 
   n.ip, n.id, n.name, INET_ATON(n.ip), n.nas_type, n.auth_type, INET_ATON(n.ip)
  FROM nas n
  ORDER BY $sort $desc;";
 log_print('LOG_SQL', "$sql");

print "
<form action='$SELF'>
<input type=hidden name=op  value=allow_nass>
<input type=hidden name=uid  value='$uid'>
<input type=hidden name=vid  value='$vid'>
<TABLE width=640 cellspacing=0 cellpadding=0 border=0><TR><TD bgcolor=$_BG4>
<TABLE width=100% cellspacing=1 cellpadding=0 border=0>
  <COLGROUP>
    <COL align=center span=1>
    <COL align=right span=1>
    <COL align=left span=1>
    <COL align=right span=1>
    <COL align=left span=1>
  </COLGROUP>\n";

 @caption = ("$_ALLOW", "ID", "$_NAME", "IP", "$_TYPE", "$_AUTH");
 show_title($sort, $desc, "$pg", "$op&$qs", \@caption);

 $q = $db->prepare($sql) || die $db->strerr;
 $q ->execute();

while(my($ip, $id, $name, $ip_int, $type, $auth, $ip_num, $allow)=$q->fetchrow()) {
    $bg = ($bg eq $_BG1) ? $_BG2 : $_BG1;

    my $checked = (defined($allow_nas{$id}) || $allow_nas{all}) ? ' checked ' :  '';    
    print "<tr bgcolor=$bg><td><input type=checkbox name=ids value=$id $checked>".
     "</td><td>$id</td><td>$name</td><td>$ip</td><td>$type</td><td>$auth_types[$auth]</td></tr>\n";
}


print "</table></td></tr></table>
<p><input type=submit name=change value=$_CHANGE> <input type=submit name=default value='$_DEFAULT'>
</form>\n";
}



#*******************************************************************
#configure nas servers
# nas()
#*******************************************************************
sub nas {
 print "<h3>$_NAS_CONFIG</h3>\n";

 my $name = $FORM{name} || '';
 my $nas_identifier = $FORM{nas_identifier} || '';
 my $describe = $FORM{describe};
 my $ip = $FORM{ip} || '0.0.0.0';
 my $auth_type = $FORM{auth_type} || 0;
 my $nas_type = $FORM{nas_type} || 'other';
 my $mng_ip_port = $FORM{mng_ip_port} || '0.0.0.0:0';
 my $mng_user = $FORM{mng_user} || '';
 my $mng_password =  $FORM{mng_password} || '';
 my $rad_pairs = $FORM{rad_pairs} || '';
 
 my @action = ('add', "$_ADD");

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

if ($FORM{ippools}) {
   ippools($FORM{ippools});
   return 0;
 }  
elsif ($FORM{add}) {
    $sql = "INSERT INTO nas (name, nas_identifier, descr, ip, nas_type, auth_type,
                   mng_host_port, mng_user, mng_password, rad_pairs)
             values (\"$name\", \"$nas_identifier\", \"$describe\", '$ip', '$nas_type', '$auth_type',
              '$mng_ip_port', '$mng_user', ENCODE('$mng_password', '$conf{secretkey}'), '$rad_pairs');";
 


    log_print('LOG_SQL', "$sql");
    my $q = $db->prepare("$sql") || die $db->strerr;
    $q -> execute ();

 
    if ($db->err == 1062) {
       message('err', "$_ERROR", "$ip $_EXIST");
      }
    elsif($db->err > 0) {
       message('err', "$_ERROR", $db->errstr . " - N:". $db->err);
      }
    else {
       message('info', "$_INFO", "$_ADDED");
       return 0;
      }
}
elsif (defined($FORM{change})) {
  $sql = "UPDATE nas SET
    name=\"$name\", 
    nas_identifier=\"$nas_identifier\", 
    descr=\"$describe\", 
    ip='$ip', 
    nas_type='$nas_type', 
    auth_type='$auth_type',
    mng_host_port='$mng_ip_port', 
    mng_user='$mng_user', 
    rad_pairs='$rad_pairs',
    mng_password=ENCODE('$mng_password', '$conf{secretkey}')
   WHERE id='$FORM{chg}';";

    log_print('LOG_SQL', "$sql");
    
    my $q = $db->do("$sql") || die $db->errstr;
    message('info', $_INFO, "$_CHANGED");
}
elsif ($FORM{chg}) {
    $sql = "SELECT name, nas_identifier, descr, ip, nas_type, auth_type, mng_host_port, mng_user, rad_pairs 
      FROM nas WHERE id='$FORM{chg}';";
             
    log_print('LOG_SQL', "$sql");
    my $q = $db->prepare("$sql") || die $db->strerr;
    $q -> execute();
    ($name, $nas_identifier, $describe, $ip, $nas_type, $auth_type, $mng_ip_port, 
        $mng_user, $rad_pairs)=$q->fetchrow();

  @action = ('change', "$_CHANGING");
  message('info', $_INFO, "$_CHANGING");
}
elsif ($FORM{del}) {
  $sql = "DELETE from nas WHERE id='$FORM{del}';";
  my $q = $db->do("$sql") || die $db->strerr;
  message('info', $_INFO, "$_DELETED");
}

 

print  << "[END]";
<form action=$SELF MATHOD=post>
<input type=hidden name=op value=nas>
<input type=hidden name=chg value=$FORM{chg}>
<table>
<tr><td>ID</td><td>$id</td></tr>
<tr><td>IP</td><td><input type=text name=ip value='$ip'></td></tr>
<tr><td>$_NAME:</td><td><input type=text name=name value="$name"></td></tr>
<tr><td>Radius NAS-Identifier:</td><td><input type=text name=nas_identifier value="$nas_identifier"></td></tr>
<tr><td>$_DESCRIBE:</td><td><input type=text name=describe value="$describe"></td></tr>
<tr><td>$_TYPE:</td><td><select name=nas_type>
[END]


  foreach my $nt (@nas_types) {
     print "<option value=$nt";
     print " selected" if ($nas_type eq $nt);
     print ">$nt ($nas_descr{$nt})\n";
   }


print "</select></td></tr>
<tr><td>$_AUTH:</td><td><select name=auth_type>\n";
 
  my $i = 0;
  foreach my $at (@auth_types) {
     print "<option value=$i";
     print " selected" if ($auth_type eq $i);
     print ">$at\n";
     $i++;
   }

print << "[END]";
</select></td></tr>
<tr><th colspan=2>:$_MANAGE:</th></tr>
<tr><td>IP:PORT:</td><td><input type=text name=mng_ip_port value="$mng_ip_port"></td></tr>
<tr><td>$_USER:</td><td><input type=text name=mng_user value="$mng_user"></td></tr>
<tr><td>$_PASSWD:</td><td><input type=password name=mng_password value=""></td></tr>
<tr><th colspan=2>RADIUS $_PARAMS (,)</th></tr>
<tr><th colspan=2><textarea cols=50 rows=4 name=rad_pairs>$rad_pairs</textarea></th></tr>
</table>
<input type=submit name=$action[0] value='$action[1]'>
</form>
[END]




print "<TABLE width=640 cellspacing=0 cellpadding=0 border=0>
  <TR><TD bgcolor=$_BG4>
  <TABLE width=100% cellspacing=1 cellpadding=0 border=0>
  <COLGROUP>
    <COL align=right span=1>
    <COL align=left span=1>
    <COL align=right span=3>
  </COLGROUP>\n";

 @caption = ("ID", "$_NAME", "NAS-Identifier", "IP", "$_TYPE", "$_AUTH", "-", "-", "-");
 show_title($sort, $desc, "$pg", "$op", \@caption);

  $sql="SELECT id, name, nas_identifier, INET_ATON(ip), nas_type, auth_type, ip FROM nas ORDER BY $sort $desc;";
  log_print('LOG_SQL', $sql);

#%pages = pages('id', 'users', "$WHERE", "op=search&type=$type&word=$word", "$pg");  

  $q = $db->prepare($sql) || die $db->strerr;
  $q ->execute();

while(($id, $name, $nas_identifier, $ip_int, $type, $auth, $ip)=$q->fetchrow()) {
    $bg = ($bg eq $_BG1) ? $_BG2 : $_BG1;
        $button = "<A href='$SELF?op=nas&del=$id'
        onclick=\"return confirmLink(this, 'NAS ID: $id, $_NAME: $name, IP: $ip')\">$_DEL</a>";

    print "<tr bgcolor=$bg><td>$id</td><td>$name</td><td>$nas_identifier</td><td>$ip</td><td>$type</td><td>$auth_types[$auth]</td>".
     "<th><a href='$SELF?op=nas&ippools=$id'>IP POOL</a></th><th><a href='$SELF?op=nas&chg=$id'>$_CHANGE</a></th>".
     "<th>$button</th></tr>\n";
}


print "</table></td></td></table>\n";
}



#*******************************************************************
#Last changes with users account
# changes()
#*******************************************************************
sub changes {
print "<h3>$_CHANGE</h3>\n";	
 
 if (! defined($FORM{sort})) {
    $sort = 7;
    $desc = 'DESC';
   }
 
 if ($uid) {
   print "<table><tr><td>UID:</td><td>$login_link</td></tr></table>\n";
   $WHERE="WHERE ul.uid='$uid'";
   $params="&uid=$uid";
  }

my $sql="SELECT u.id, ul.date, ul.log, a.id, INET_NTOA(ul.ip), ul.uid, ul.id
  FROM userlog ul 
  LEFT JOIN users u ON (u.uid=ul.uid)
  LEFT JOIN admins a ON (a.aid=ul.aid)
  $WHERE 
  ORDER BY $sort $desc LIMIT $pg, $max_recs;";

%pages = pages('uid', 'userlog ul', "$WHERE", "op=changes&uid=$uid&sort=$sort&desc=$desc", "$pg");  
log_print('LOG_SQL', "$sql");
  
$q = $db->prepare($sql) || die $db->strerr;
$q ->execute();

print "<TABLE width=99% cellspacing=0 cellpadding=0 border=0>
  <TR><TD bgcolor=$_BG4>
  <TABLE width=100% cellspacing=1 cellpadding=0 border=0>\n";

my @caption = ('#', "$_DATE", "$_CHANGE", "$_ADMINS", 'IP');
show_title($sort, "$desc", "$pg", "$op$params", \@caption);

while(my($login, $date, $log,  $admin, $ip, $uid) = $q->fetchrow()) {
   $bg = ($bg eq $_BG1) ? $_BG2 : $_BG1;
   print "<tr bgcolor=$bg><td><a href='$SELF?op=users&uid=$uid'>$login</a></td><td>$date</td><td>$log</td><td>$admin</td><td>$ip</td></tr>\n";
 }
print "</table></td></table>\n".
      $pages{pages};	
}


#********************************************************************
# other()
#********************************************************************
sub other () {
print "
<table><tr><td>
 <a href='$SELF?op=icards'>$_ICARDS</a><br>
 <a href='$SELF?op=nas_stats'>$_NAS_STATISTIC</a><br>
 <a href='$SELF?op=shedule'>$_SHEDULE</a><br>
 <a href='$SELF?op=sql_backup'>$_SQL_BACKUP</a><br>
 <a href='$SELF?op=admins'>$_ADMINS</a><br>
 <a href='$SELF?op=groups'>$_GROUPS</a><br>
 <a href='docs.cgi'>$_DOCS</a><br>
 <a href='$SELF?op=fees'>$_FEES</a><br>
 <a href='$SELF?op=changes'>$_CHANGE</a><br>
 <a href='$SELF?op=nas'>$_NAS_CONFIG</a><br>
 <a href='$SELF?op=errlog'>$_ERROR_LOG</a><br>
<!-- <a href='$SELF?op=docs'>$_DOCS</a><br> -->
 <a href='$SELF?op=filters'>$_FILTERS</a><br>
 <a href='$SELF?op=dunes'>$_DUNES</a><br>\n
 <a href='$SELF?op=holidays'>$_HOLIDAYS</a><br>\n
 <a href='$SELF?op=er'>$_EXCHANGE_RATE</a><br>\n
 <a href='$SELF?op=messages'>$_MESSAGES</a><br>\n
 <a href='$SELF?op=profile'>$_PROFILE</a><br>\n
 <a href='$SELF?op=not_ended'>Not ended</a><br>\n
 <a href='$SELF?op=templates'>$_TEMPLATES</a><br>\n
 <br>
 <a href='networks.cgi'>$_NETWORKS</a><br>\n
 <a href='postfix.cgi'>Postfix</a><br>\n
 <a href='$SELF?op=sql_cmd'>SQL commander</a><br>\n
 <a href='spamassassin.cgi'>Spamassassin</a><br>\n
</td></tr></table>
";
}


#*******************************************************************
# Task sheduler
# shedule()
#*******************************************************************
sub form_shedule () {
  print "<h3>$_SHEDULE</h3>\n";

if ($FORM{del}){
  shedule('del', { id => $FORM{del} });
}


print "<p><table width=90%>
<COLGROUP>
  <COL align=right span=5>
  <COL align=left span=3>
  <COL align=right span=2>
  <COL align=center span=1>
</COLGROUP>\n";
my @caption = ("$_HOURS", "$_DAY", "$_MONTH", "$_YEAR", "$_COUNT", "$_USER", "$_VALUE", "$_ADMINS", "$_CREATED", "-");  
show_title($sort, "$desc", "$pg", "$op", \@caption);


while(my($k, $v)=each( %shedule_type )){
  $sql = "SELECT s.h, s.d, s.m, s.y, s.counts, u.id, s.action, a.id, s.date, a.aid, s.uid, s.id  
    FROM shedule s
    LEFT JOIN users u ON (u.uid=s.uid)
    LEFT JOIN admins a ON (a.aid=s.aid)
    WHERE s.type='$k';";

  $q = $db->prepare($sql) || die $db->errstr;
  $q ->execute(); 
  print "<tr bgcolor=$_BG0><th colspan=10>$v</th></tr>\n";
  while(my($h, $d, $m, $y, $counts, $login, $action,  $admin_name, $date, $admin_id, $uid, $shedule_id)=$q->fetchrow()) {
     my $button = "<A href='$SELF?op=shedule&del=$shedule_id' onclick=\"return confirmLink(this, '$_SHEDULE: $_USER: $login,  $_DATE: $date, $_VALUE: $action')\">$_DEL</a>";
     $bg = ($bg eq $_BG1) ? $_BG2 : $_BG1;
     print "<tr bgcolor=$bg><td>$h</td><td>$d</td><td>$m</td><td>$y</td><td>$counts</td>".
     "<td><a href='$SELF?op=users&chg=$uid'>$login</a></td><td>$action</td>".
     "<td><a href='$SELF?op=admins&chg=$admin_id'>$admin_name</a></td><td>$date</td><td>$button</td></tr>\n";
   }

}

  print "</table></p>\n";

}


#*******************************************************************
#
# sql_backup()
#*******************************************************************
sub sql_backup {
 print "<h3>$_SQL_BACKUP</h3>\n".
 "<a href='$SELF?op=sql_backup&mk_backup=y'>$_MAKE_BACKAUP</a><br>\n";
 
  if ($FORM{mk_backup}) {
    $res = `$MYSQLDUMP --host=$conf{dbhost} --user="$conf{dbuser}" --password="$conf{dbpasswd}" $conf{dbname} | $GZIP > $BACKUP_DIR/stats-$DATE.sql.gz`;
    print "Backup created: $res ($BACKUP_DIR/stats-$DATE.sql.gz)";
   }
  elsif($FORM{del}) {
    $status = unlink <"$BACKUP_DIR/$FORM{del}">;
    print "$_DELETED : $FORM{del} [$status]\n";
   }

 opendir DIR, $BACKUP_DIR or print "Can't open dir '$BACKUP_DIR' $!\n";
  my @contents = grep  !/^\.\.?$/  , readdir DIR;
 closedir DIR;
 
 print "<TABLE width=640 cellspacing=0 cellpadding=0 border=0><TR><TD bgcolor=$_BG4>
  <TABLE width=100% cellspacing=1 cellpadding=0 border=0>
  <tr bgcolor=$_BG0><th>$_NAME</a></th><th>$_DATE</th><th>$_SIZE</th><th>-</th></tr>\n";

 use POSIX qw(strftime); 
 foreach my $filename (@contents) {
   my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks)=stat("$BACKUP_DIR/$filename");
   $date = strftime "%Y-%m-%d %H:%M:%S", localtime($mtime);
   $bg = ($bg eq $_BG1) ? $_BG2 : $_BG1;
   print "<tr bgcolor=$bg><th align=left>$filename</th><td align=right>$date</td><td align=right>$size</td>".
    "<td><a href='$SELF?op=sql_backup&del=$filename'>$_DEL</a></td></tr>\n";
  }
 print "</table></td></tr></table>\n";
}




#*******************************************************************
# admins();
#*******************************************************************
sub form_admins  {
 @permissions = ('ReadOnly', 'ReadWrite', 'FullAccess');
 
 my $aid=$FORM{aid} || 0;
 my $id=$FORM{id};
 my $name = $FORM{name} || '';
 my $permit = $FORM{permit} || '';


 #$group = $FORM{'group'} || 0;
 print "<h3>$_ADMINS</h3>\n";
 my @action = ('add', "$_ADD");
 my  %permissions = ('add' => "$_ADD", 
                     'change' => "$_CHANGING",
                     'del' => "$_DEL",
                     'activ' => "$_ACTIV",
                     'get' => "$_GET"
                     );



if ($FORM{add}) {
  $sql = "INSERT INTO admins (id, name, regdate, permissions) VALUES
     ('$id', '$FORM{name}', now(), '$permit');";
  $q = $db->do($sql);

  if ($db->err == 5) {
    message('err', $_ERROR, "$_USER_EXIST");
     }
  elsif($db->err > 0) {
    message('err', $_ERROR, $db->errstr);
     }
  else {
    message('info', $_INFO, $_ADDED);
   }
 }
elsif($FORM{change}) {
  $sql = "UPDATE admins SET
    id='$id', 
    name='$name', 
    permissions='$permit'
    WHERE aid='$FORM{chg}';";
  log_print('LOG_SQL', "$sql");
  $q = $db->do($sql) || die $db->errstr;
  message('info', $_INFO, "$_CHANGED [$aid]");
 }
elsif($FORM{chg}) {
  $sql = "SELECT id, name, permissions FROM admins WHERE aid='$FORM{chg}';";
  $q = $db->prepare($sql) || die $db->errstr;
  $q ->execute(); 
  ($id, $name, $permit)= $q->fetchrow();
  @action = ('change', "$_CHANGE");
  message('info', $_INFO, "$_CHANGING '$id'");
 }
elsif ($FORM{passwd}) {
  print "$_CHANGE_PASSWD<p>\n";
   if($FORM{change}) {
      print $_CHANGED;
    }
   else {
     print "<form action=$SELF method=post>
     <input type=hidden name=op value=admins>
     <input type=hidden name=passwd value=y>
     <table>
     <tr><td>ID</td><td>$id</td></tr>
     <tr><td>$_PASSWD:</td><td><input type=password name=password></td></tr>
     <tr><td>$_CONFIRM_PASSWD:</td><td><input type=password name=confirm></td></tr>
     </table>
     <input type=submit name=change value='$_CHANGE'>
     </form>";
    }
 } 
elsif ($FORM{del}) {
  $q = $db->do("DELETE FROM admins WHERE aid='$FORM{del}';") || die $db->errstr;
  message('info', $_INFO, "$_DELETED '$del'");
}
#else {
print "<form action='$SELF' METHOD=POST>
<input type=hidden name=op value=admins>
<input type=hidden name=chg value=$FORM{chg}>
<table>
<tr><td>ID:</td><td><input type=text name=id value=$id></td></tr>
<tr><td>$_FIO:</td><td><input type=text name=name value=\"$name\"></td></tr>
<tr><th colspan=2>$_PERMISSION</th></tr>\n";

  my @p = split(/, /, $permit);
  
  my %permits = ();
  foreach my $line (@p) {
    $permits{$line}='yes';
   }


  while(my($key, $val)=each %permissions ){
     print "<tr bgcolor=$_BG1><th><input type=checkbox name=permit value=$key";
     print ' checked' if (defined($permits{$key}));
     print "></th><td>$val</td></tr>\n";
   }

print "</table>
<input type=submit name=$action[0] value='$action[1]'>
</form>\n";

print "<TABLE width=640 cellspacing=0 cellpadding=0 border=0><TR><TD bgcolor=$_BG4>
<TABLE width=100% cellspacing=1 cellpadding=0 border=0>
 <tr bgcolor=$_BG0><th>ID</th><th>$_NAME</th><th>$_REGISTRATION</th><th>$_PERMISSION</th><th>-</th><th>-</th></tr>\n";

 $q = $db->prepare("select aid, id, name, regdate, permissions FROM admins;") || die $db->errstr;
 $q ->execute(); 

while(($aid, $id, $name, $regdate, $permit)= $q->fetchrow()) {
    $bg = ($bg eq $_BG1) ? $_BG2 : $_BG1;
    my @p = split(/, /, $permit);
    $permit='';
    foreach my $line (@p) {
       $permit .= $permissions{$line}. '<br>';
     }

    print "<tr bgcolor=$bg><td><a href='$SELF?op=admins&chg=$aid'>$id</a></td><td>$name</td><td>$regdate</td>".
     "<td>$permit</td><td><a href='$SELF?op=admins&id=$id&passwd=y'>$_PASSWD</a></td>".
     "<td><a href='$SELF?op=admins&id=$id&del=$aid'>$_DEL</a></td></tr>\n";
  }
print "</table>\n</td></tr></table>\n";

#}

}



#*******************************************************************
# NAS server statistic
# nas_stats()
#*******************************************************************
sub nas_stats {

  print "<h3>$_NAS_STATISTIC</h3>\n";


print "<TABLE width=640 cellspacing=0 cellpadding=0 border=0><TR><TD bgcolor=$_BG4>
  <TABLE width=100% cellspacing=1 cellpadding=0 border=0>";
  my @caption = ("NAS", "NAS_PORT", "$_SESSIONS", "$_LAST_LOGIN", "$_AVG", "$_MIN", "$_MAX");  
  show_title($sort, "$desc", "$pg", "$op", \@caption);
  my $sort=($sort==2) ? '1,2' : "$sort" ;

  my $sql = "select nas_id, port_id, count(*), 
   if(date_format(max(login), '%Y-%m-%d')=curdate(), date_format(max(login), '%H-%i-%s'), max(login)), 
   SEC_TO_TIME(avg(duration)), SEC_TO_TIME(min(duration)), SEC_TO_TIME(max(duration))
    FROM log 
    WHERE date_format(login, '%Y-%m')=date_format(curdate(), '%Y-%m')
    GROUP BY nas_id, port_id ORDER BY $sort $desc;";
  log_print('LOG_SQL', "$sql"); 
  my $q = $db -> prepare($sql) || die $db->strerr;
  $q ->execute();

  my $NAS_INFO = nas_params();
  %NAS_IDS = reverse %$NAS_INFO;

  while(($nas_id, $port_id, $up_count, $last_up, $avg, $min, $max) = $q->fetchrow()) {
     
     $ip = $NAS_IDS{$nas_id};
     if ($NAS_INFO->{nt}{$nas_id} ne "ppp") {
       $bg = ($bg eq $_BG1) ? $_BG2 : $_BG1;
       print "<tr bgcolor=$bg><td><a href='$SELF?op=last&nas=$nas_id'>$NAS_INFO->{name}{$nas_id}</a></td><td align=right>$port_id</td>".
       "<td align=right>$up_count</td><td align=right>$last_up</td>".
       "<td align=right>$avg</td><td align=right>$min</td><td align=right>$max</td></tr>\n";
      }
    }
  print "</table>\n</td></tr></table>\n";
  
} 

#*******************************************************************
# back payments
# back_money()
#*******************************************************************
sub back_money  {
 my $sum = $FORM{sum} || 0;
 my $id = $FORM{id} || 0;

print "<h3>$_BACK_MONEY</h3>\n";

# Delete from fees table
if ($FORM{del} eq 'fees') {
  $sql = "select f.id, f.sum, f.dsc, u.id
   FROM fees f
   LEFT JOIN users u ON (u.uid=f.uid)
   WHERE f.id='$id' and f.uid='$uid';";
  $q = $db -> prepare($sql) || die $db->strerr;
  $q -> execute();

  if ($q->rows > 0) {
    ($id, $sum, $describe, $login) = $q -> fetchrow();
    $sql = "DELETE from fees WHERE id='$id' and uid='$uid';";
    log_print('LOG_SQL', "$sql");
    $q = $db->do($sql);
    message('info', $_DEL,  "$_FEES<br>ID: $id<br>$_LOGIN: '$login'<br>$_SUM: $sum<br>$_DESCRIBE: '$describe'");
   }
  else {
     message('info', "$_INFO", "$_NO_RECORD");
     return 0;
   }
}
# Delete from log table
elsif ($FORM{del} eq 'log') {
  $sql = "DELETE FROM log WHERE id='$FORM{login}' and login='$FORM{ltime}' and duration='$FORM{duration}';";
  log_print('LOG_SQL', "$sql");
  $q = $db->do($sql) || die $db->strerr;
  $uid = get_uid("$FORM{login}");

$message = "
<TABLE width=100%>
<tr bgcolor=$_BG1><td>$_USER:</td><td><a href='$SELF?op=users&chg=$uid'>$FORM{login}</a></td></tr>
<tr bgcolor=$_BG1><td>$_LOGIN:</td><td>$FORM{ltime}</td></tr>
<tr bgcolor=$_BG1><td>$_DURATION:</td><td>$FORM{duration}</td></tr>
<tr bgcolor=$_BG1><td>$_SUM:</td><td>$sum</td></tr>
</table>\n";

message('info', $_DELETED, "$message");

print << "[END]";
<form action=$SELF>
<input type=hidden name=op value=bm>
<input type=hidden name=uid value='$uid'>
<input type=hidden name=sum value='$sum'>
<input type=submit name=bf_log value='$_BACK_MONEY ?'>
</form>
[END]
return 0;	
}
#delete from payments
elsif ($FORM{del} eq 'payment') {
  $sql = "DELETE FROM payment WHERE uid='$uid' and id='$id' and sum='$sum';";
  log_print('LOG_SQL', "$sql");
  #$q = $db->do($sql) || die $db->strerr;
  $sum = $sum - 2  * $sum;


$message = "<table>
<tr bgcolor=$_BG0><th colspan=2>$_DELETED $_PAYMENTS</th></tr>
<tr><td>$_USER:</td><td>$login_link<td></tr>
<tr><td>Payment ID:</td><td>$id</td></tr>
<tr><td>$_SUM:</td><td>$sum</td></tr>
</table>\n";

message('info', $_INFO, "$message");

print << "[END]";
<form action=$SELF>
<input type=hidden name=op value=bm>
<input type=hidden name=uid value='$uid'>
<input type=hidden name=sum value='$sum'>
<input type=submit name=bf_log value='$_BACK_MONEY ?'>
</form>
[END]

#print "/$sum/";
return 0;	
}

if ($sum > 0) {
  $sql = "UPDATE users set deposit=deposit+$sum WHERE uid='$uid';";
  log_print('LOG_SQL', "$sql");
  $q = $db->do($sql) || die $db->strerr;
  message('info', "$_ADDED", "<table width=100%>
    <tr><td>$_USER:</td><td>$login_link</td></tr>
    <tr><td>$_SUM:</td><td>$sum</td></tr>
    </table>\n");
}

}




#********************************************************************
# options()
#********************************************************************
sub options () {
 print "<h3>$_OPTIONS</h3>".
 "<a href=''>$_PAYMENT_TYPE</a> ";

=comments 
if ($FORM{m} eq 'pt') {
 
 print "<Table>
  <tr bgcolor=$_BG3><th>$_NAME</th><td></td><td></td></tr>\n";
 open(FILE, "< ../../libexec/payment_type.txt")	|| die "Can't open file $!";
  while(<FILE>) {
     ($name, $v, $v2)=split(/ /);
     print "<tr><td>$name<td><td></td><td></td></tr>\n";
    }
 close(FILE);
 print "</table>\n";
}
=cut
	
}


#*******************************************************************
# Get money
# form_fees();
#*******************************************************************
sub form_fees {
 print "<h3>$_FEES</h3>\n";

 my $sum = $FORM{sum} || 0;
 my $describe = $FORM{descr} || '';
 my $period = $FORM{period} || 0;
 my $message = '';

if ($FORM{get}) {
  if ($sum==0) {
    message('err', $_ERROR, "$_NO_SUM");	
   }
  else {
    if ($period == 1) {
      $FORM{date_m}++;
      shedule('add', { 
      	               uid => $uid,
                       type => 'fees',
                       action => "$sum:$describe",
    	               d => $FORM{date_d},
                       m => $FORM{date_m},
                       y => $FORM{date_y},
                       descr => "$_TYPE: $shedule_type{fees}<br>\n
                                 $_SUM: $sum<br>\n
                                 $_DESCRIBE: $describe<br>\n
                                 $_DATE: '$FORM{date_d}-$FORM{date_m}-$FORM{date_y}'"
                     }
             );
      
     }
    else {
       if(get_fees("$uid", "$sum", "$describe") ==1) {
         foreach my $line(@f_message) {
       	   $message .= "$line<br>";
         }
         message('info', $_INFO, "$message");
       }
     }
   }
}

my $period_form=form_period($period);
print << "[END]";
<form action=$SELF>
<input type=hidden name=uid value='$uid'>
<input type=hidden name=op value='fees'>
<table>
<tr><td>$_USER:</td><td>$login_link</td></tr>
<tr><td>$_SUM:</td><td><input type=text name=sum value='$sum'></td></tr>
<tr><td>$_DESCRIBE:</td><td><input type=text name=descr></td></tr>
$period_form
</table>
<input type=submit name=get value='$_GET'>
</form>
[END]

if ($uid) { $WHERE = "WHERE f.uid=\"$uid\" "; }


%pages = pages('f.uid', 'fees f', "$WHERE", "op=$op&uid=$uid", "$pg");  
print $pages{pages};

print "<TABLE width=98% cellspacing=0 cellpadding=0 border=0><TR><TD bgcolor=$_BG4>
  <TABLE width=100% cellspacing=1 cellpadding=0 border=0>
  <COLGROUP>
    <COL align=right span=1>
    <COL align=left span=1>
    <COL align=right span=1>
    <COL align=left span=2>
    <COL align=right span=3>
    <COL align=center span=1>
  </COLGROUP>\n";

 $sql = "SELECT f.id, u.id, f.date, f.dsc, f.ww, f.ip, f.last_deposit, f.sum, f.uid, INET_NTOA(f.ip)
   FROM fees f 
   LEFT JOIN users u ON (u.uid=f.uid)
   $WHERE 
   ORDER by $sort $desc
   LIMIT $pg, $max_recs;";
 log_print('LOG_SQL', $sql);
 
 my @caption = ('ID', $_USER, $_DATE, $_DESCRIBE, $_ADMINS, 'IP', $_DEPOSIT, "$_SUM", '-');
 show_title($sort, $desc, "$pg", "$op&uid=$uid", \@caption);

 $q = $db -> prepare($sql) || die $db->strerr;
 $q -> execute ();
 my $total = 0;

while(my($id, $login, $date, $describe, $admin, $admin_ipn, $last_deposit, $sum, $uid, $admin_ip)=$q->fetchrow()) {
  $button = "<A href='$SELF?op=bm&del=fees&uid=$uid&id=$id' onclick=\"return confirmLink(this, '$_USER: $login | $_SUM: $sum | $_DATE: $date')\">$_DEL</a>";
  $total += $sum;
  $bg = ($bg eq $_BG1) ? $_BG2 : $_BG1; 	
  print "<tr bgcolor=$bg><td>$id</td><td><a href='$SELF?op=users&uid=$uid'>$login</a></td><td>$date</td><th>$describe</th>".
   "<th>$admin</th><th>$admin_ip</th><th>$last_deposit</th><th>$sum</th><th>$button</th></tr>\n";	
}

print "<tr bgcolor=$_BG3><th colspan=5>$_TOTAL:</th><th colspan=5>$total</th></tr>";
print "</table></td></tr></table>\n";
print $pages{pages};

}




#*******************************************************************
# inpayments
# inpayments()
#*******************************************************************
sub inpayments {

print "<h3>$_INPAYMENTS</h3>\n";
 
 my $assign_count = 0;
 my $assign_sum = 0;
 my @caption = ();


#Daily statistic
if (defined($FORM{d})) {

   my ($y, $m, $d)=split(/-/, $FORM{d}, 3);
   for ($i=1; $i<=31; $i++) {
       $days .= ($d == $i) ? "<b>$i </b>" : sprintf("<a href='$SELF?op=inp&d=%d-%02.f-%02.f'>%d</a> ", $y, $m, $i, $i);
     }
   $m--;
   
   print "<b>$_YEAR:</b> $y <b>$_MONTH:</b> $MONTHES[$m]<br>\n$days\n";
   $op = $op . "&d=$FORM{d}";

   my $sql="select l.id, count(l.id), sum(l.sent + l.recv), sum(l.sent2 + l.recv2), sec_to_time(sum(l.duration)), sum(l.sum), u.uid
    FROM log l
    LEFT JOIN users u ON (u.id=l.id)
    WHERE date_format(l.login, '%Y-%m-%d')='$FORM{d}'
    GROUP BY l.id 
    ORDER BY $sort $desc;";
   my $q = $db -> prepare($sql) || die $db->strerr;
   $q -> execute ();

   @caption = ("$_USERS", "$_SESSIONS", "$_TRAFFIC", "$_TRAFFIC 2", "$_DURATION", "$_SUM");  
   $output .= "  <COLGROUP>
    <COL align=left span=1>
    <COL align=right span=5>
  </COLGROUP>\n";

   while(my($login, $sessions, $trafic, $trafic2, $duration, $sum, $uid) = $q -> fetchrow()) {
     $bg = ($bg eq $_BG1) ? $_BG2 : $_BG1;
     $trafic = int2byte($trafic);
     $trafic2 = int2byte($trafic2);
     $money_sum += $sum;
     $output .= "<tr bgcolor=$bg><td><a href='$SELF?op=stats&uid=$uid&period=5&login=$FORM{d}'>$login</a></td><td>$sessions</td><td>$trafic</td><td>$trafic2</td><td>$duration</td><td>$sum</td></tr>\n";
    }
   $output .= "</table>\n</td></tr></table>\n";

   $output .= "<h3>$_FEES</h3>\n";
   $sql = "SELECT f.id, u.id, f.dsc, f.ww, f.sum, f.uid
     FROM fees f
     LEFT JOIN users u ON (u.uid=f.uid)
     WHERE date_format(date, '%Y-%m-%d')='$FORM{d}';";
   log_print('LOG_SQL', "$sql");
   $q = $db -> prepare($sql) || die $db->strerr;
   $q -> execute ();

   $output .= "<TABLE width=640 cellspacing=0 cellpadding=0 border=0>
     <TR><TD bgcolor=$_BG4>
     <TABLE width=100% cellspacing=1 cellpadding=0 border=0>
     <tr bgcolor=$_BG0><th>#</th><th>$_USER</th><th>$_DESCRIBE</th><th>$_OPERATOR</th><th>$_SUM</th><th>-</th></tr>\n";

   while(my($id, $login, $dsc, $ww, $sum, $uid) = $q -> fetchrow()) {
      $bg = ($bg eq $_BG1) ? $_BG2 : $_BG1;
      $button = "<A href='$SELF?op=bm&del=fees&uid=$uid&id=$id' onclick=\"return confirmLink(this, '$_USER: $uid | $_SUM: $sum | $_DATE: $date')\">$_DEL</a>";
      $output .= "<tr><tr bgcolor=$bg><td>$id</td><td><a href='$SELF?op=users&uid=$uid'>$login</a></td><td>$dsc</td><td>$ww</td>".
       "<td align=right>$sum</td><td>$button</td></tr>\n";
     
      $assign_count += $count;
      $assign_sum += $sum;
    }
   $output .= "<tr bgcolor=$_BG3><th>$_SUM</th><th align=right>$assign_count</th><th align=right colspan=3>$assign_sum</th><td>&nbsp;</td></tr>\n".
     "</table>\n".
     "</td></tr></table>\n";
 }
else {
#  $output .= "<table width=640>\n";
  my $url_params = "";

   if ($FORM{m} eq 'y') {
     $sql = "SELECT date_format(login, '%Y-%m'), count(DISTINCT id), sum(sent + recv), sum(sent2 + recv2), sec_to_time(sum(duration)), 
       sum(sum), count(id)
       from log 
       GROUP BY 1 ORDER by $sort $desc;";
     $uparam = 'm';
     $op .= "&m=$FORM{m}";
    }
   else {
     $month = (defined($FORM{m})) ?  "'$FORM{m}'" : "date_format(curdate(), '%Y-%m')";

     $sql = "select date_format(l.login, '%Y-%m-%d'), count(DISTINCT l.id), sum(l.sent + l.recv), sum(l.sent2 + l.recv2),
      sec_to_time(sum(l.duration)), sum(l.sum), DAYOFMONTH(l.login), count(l.id)
       FROM log l
       WHERE date_format(l.login, '%Y-%m')=$month
       GROUP BY 1 ORDER by $sort $desc;";
       $uparam = 'd';
     }
   
  log_print('LOG_SQL', "$sql");
  $q = $db -> prepare($sql) || die $db->strerr;
  $q -> execute ();

  my $max_sum=1;
  my $max_sessions=1;
  my $max_users=1;
   
  @caption = ("$_DATE", "$_USERS / $_LOGINS", "$_TRAFFIC", "$_TRAFFIC 2", "$_DURATION", "$_SUM");
  $output = " <COLGROUP>
    <COL align=left span=1>
    <COL align=right span=5>
  </COLGROUP>\n";
  
  while(my($date, $users, $trafic, $trafic2, $duration, $sum, $day, $logins, $uid) = $q -> fetchrow()) {
    $trafic_sum += $trafic;
    $trafic = int2byte($trafic);
    $trafic2 = int2byte($trafic2);
    $money_sum += $sum;
    $logins_sum += $logins; 
    $bg = ($bg eq $_BG1) ? $_BG2 : $_BG1;     
    $output .= "<tr bgcolor=$bg><td><a href='$SELF?op=inp&". $uparam ."=$date'>$date</a></td><td>$users / $logins</td><td>$trafic</td><td>$trafic2</td><td>$duration</td><td>$sum</td>\n";
     
    $max_sum=$sum if($max_sum < $sum);
    $max_sessions=$logins if($max_sessions < $logins);
    $max_users=$users if($max_users < $users);

    $graffic{$day}{sum}=$sum;
    $graffic{$day}{sessions}=$logins;
    $graffic{$day}{users}=$users;
   }

  $trafic_sum = int2byte($trafic_sum);
  $output .= "<tr bgcolor=$_BG3><th>$_SUM</th><td align=right>$logins_sum</td><th align=right>$trafic_sum</th><td align=right>-</td><td></td><th align=right>$money_sum</th>\n". 
    "</table>\n".
    "</td></tr></table>\n";

  $output .= "<table border=0 height=210 width=100% valign=top><tr>\n";

  my $midl_sessions = 200 / $max_sessions;
  my $midl_sum = 200 / $max_sum if ($max_sum > 0);
  my $midl_users = 200 / $max_users;

  for($i=1; $i<32; $i++) {
    $output .= "<td valign=bottom>";
    if (defined($graffic{$i}{sessions})) {
      $sessions = int($graffic{$i}{sessions} * $midl_sessions);
      $sum = int($graffic{$i}{sum} * $midl_sum);
      $users = int($graffic{$i}{users} * $midl_users);

      $output .= "<img src='$img_path" . "vertgreen.gif' width=6 height=$users>". 
         "<img src='$img_path". "vertyellow.gif' width=6 height=$sessions>". 
         "<img src='$img_path". "vertred.gif' width=7 height=$sum><br>";
     }
    else { 
      print '&nbsp;'; 
     }
 
    $output .= "$i</td>\n";
   }

  $output .= "</tr>
    </table>
    <img src='$img_path" . "vertgreen.gif' width=6 height=8> - $_USERS 
    <img src='$img_path" . "vertyellow.gif' width=6 height=8> - $_LOGINS
    <img src='$img_path" . "vertred.gif' width=6 height=8> - $_SUM\n";

  $output .= "<h3>$_FEES</h3>\n";
#$debug =10;
  if ($month) {
    $sql = "SELECT date_format(f.date, '%Y-%m-%d'), count(*), sum(f.sum) 
      FROM fees f
      WHERE date_format(f.date, '%Y-%m')=$month GROUP BY 1;";
   }
 else {
    $sql = "SELECT date_format(date, '%Y-%m'), count(*), sum(sum) FROM fees GROUP BY 1;";
   } 
 
  log_print('LOG_SQL', "$sql");
  $q = $db -> prepare($sql) || die $db->errstr;
  $q -> execute ();

  $output .= "<TABLE width=400 cellspacing=0 cellpadding=0 border=0>
   <TR><TD bgcolor=$_BG4>
   <TABLE width=100% cellspacing=1 cellpadding=0 border=0>
   <tr bgcolor=$_BG0><th>$_DATE</th><th>$_COUNT</th><th>$_SUM</th></tr>\n";

  while(my($date, $count, $sum) = $q -> fetchrow()) {
    $bg = ($bg eq $_BG1) ? $_BG2 : $_BG1;
    $output .= "<tr><tr bgcolor=$bg><td><a href='$SELF?op=inp&". $uparam ."=$date''>$date</a></td><td align=right>$count</td><td align=right>$sum</td></tr>\n";
    $assign_count += $count;
    $assign_sum += $sum;
   }
  $output .= "<tr bgcolor=$_BG3><th>$_SUM</th><th align=right>$assign_count</th><th align=right>$assign_sum</th></tr>\n".
    "</table></td></tr></table>\n";
 }

$total_sum = $assign_sum + $money_sum;

print "<table border=0><tr><td>\n".
      "<a href='$SELF?op=inp&m=y'>$_PER_MONTH</a>
       <TABLE width=100% cellspacing=0 cellpadding=0 border=0><TR><TD bgcolor=$_BG4>
       <TABLE width=100% cellspacing=1 cellpadding=0 border=0>\n";

      show_title($sort, "$desc", "$pg", "$op$qs", \@caption);

print $output .
      "</td><td valign=top width=200 bgcolor=$_BG2>".
      "<Table width=100%>\n".
      "<tr><th colspan=2>$_TOTAL:</th></tr>".
      "<tr><td>$_SUM:</td><td align=right>$total_sum</td></tr>".
      "</table>".
      "</td>".
      "</tr></table>\n";
}



#*******************************************************************
# users()
#*******************************************************************
sub users  {
 @action = ('add', $_ADD);
 $variant=$FORM{variant} || $_DEFAULT_VARIANT;
 $fio = $FORM{fio} || '-';
 $credit=$FORM{credit} || 0;
 $phone=$FORM{phone} || 0;
 $simultaneously=$FORM{simultaneously} || 0;
 $uid = $FORM{uid} || $FORM{chg};
 $expire = $FORM{expire} || '0000-00-00';
 $activate = $FORM{activate} || '0000-00-00';
 $reduction = $FORM{reduction} || 0;
 $nas = $FORM{nas} || 0;
 $ip = $FORM{ip} || '0.0.0.0';
 $netmask = $FORM{netmask} || '255.255.255.255';
 $speed = $FORM{speed} || 0;
 $filter_id = $FORM{filter_id} || '';
 $usernameregexp = "^[a-z0-9_][a-z0-9_-]*\$"; # configurable
 $cid = $FORM{cid} || '';
 $email = $FORM{email} || '';
 $address = $FORM{address} || '';
 $comments = $FORM{comments} || '';



 
 $login = $FORM{login} || '';
 
print "<h3>$_USERS</h3>\n";


 if ($FORM{qshow}) {
    $uid = get_uid("$FORM{qshow}");
    if ($uid < 1) {
       message('info', $_INFO, "$_NOT_EXIST '$FORM{qshow}'");
     }
   }


if (defined($FORM{vid})) {
  $q = $db->prepare("select u.variant, v.name,  count(*), 
     sum(if(deposit < 0, u.deposit, 0)), sum(if(deposit > 0, u.deposit, 0))
    FROM users u, variant v
    WHERE u.variant=v.vrnt
     GROUP by u.variant;")
    || die $db->strerr;
  $q -> execute ();

  print "<TABLE width=640 cellspacing=0 cellpadding=0 border=0>
  <TR><TD bgcolor=$_BG4>
  <TABLE width=100% cellspacing=1 cellpadding=0 border=0>
  <tr bgcolor=$_BG0><th>$_VARIANT</th><th>$_NAME</th><th>$_COUNT</th><th>$_SUM</th><th>$_CREDITORS</th></tr>\n";
  while(($variant, $name,  $count, $debeters, $sum) = $q -> fetchrow()) {
    if ($variant == $FORM{vid}) {
        $bg = $_BG0;
     }
    else {
    	$bg = ($bg eq $_BG1) ? $_BG2 : $_BG1;
     }
    print "<tr bgcolor=$bg><td align=right>$variant</td><td><a href='$SELF?op=users&vid=$variant'>$name</a></td>".
     "<td align=right>$count</td><td align=right>$sum</td><th align=right><a href='$SELF?op=users&debs=$variant'>$debeters</th></tr>\n";
   }
  print "</table>\n</td></tr></table>\n";
}


if ($FORM{userform}) {
  form_user_info();
}
elsif ($FORM{add}) {
    
    if ($login eq '') {
    	 message('err', "$_ERROR", $ERR_ENTER_USER_NAME);
    	 form_user_info();
    	 return 0;
      }
    elsif (length($login) > $conf{username_length}) {
    	 message('err', "$_ERROR", "$ERR_NAME_TOOLONG (max: $conf{username_length})");
    	 form_user_info();
    	 return 0;
      }
    elsif($login !~ /$usernameregexp/) {
    	 message('err', "$_ERROR", "$ERR_WRONG_NAME '$login'");
    	 form_user_info();
    	 return 0;
      }
    elsif($email ne '') {
      if ($email !~ /^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/) {    	 
         message('err', "$_ERROR", "$_WRONG_EMAIL '$email'");
      	 form_user_info();
    	 return 0;
       }
     }
    
    $sql = "INSERT INTO users (id, fio, phone, address, email, activate, expire, credit, reduction, 
            variant, logins, registration, ip, netmask, speed, filter_id, cid, comments)
           VALUES ('$login', '$fio', '$phone', \"$address\", '$email', '$activate', '$expire', '$credit', '$reduction', 
            '$variant', '$simultaneously', now(), INET_ATON('$ip'), INET_ATON('$netmask'), '$speed', '$filter_id', LOWER('$cid'), '$comments');";
    $q = $db->do($sql);
    
    if ($db->err == 1062) {
       message('err', "$_ERROR", "'$login' $_USER_EXIST");
       form_user_info();
       return 0;
      }
    elsif($db->err > 0) {
       message('err', "$_ERROR", $db->errstr . " - N:". $db->err);
      }
    else {
    	
      $msg = "<table width=100%>
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
       <tr><th colspan=2>:$_COMMNETS:</th></tr>
       <tr><th colspan=2>:$comments:</th></tr>
       </table>\n";
       message('info', "$_ADDED", "$msg");

      $uid = $db->{'mysql_insertid'};

      $q = $db -> prepare("SELECT activate_price FROM variant WHERE vrnt=\"$variant\";") || die $db->strerr;
      $q -> execute();

      ($activate_price) = $q -> fetchrow();
      if ($activate_price  > 0) {
   	get_fees("$login", "$activate_price", "$_ACTIVATE");
       }

      $q = $db->do("INSERT INTO userlog (log, date, ww, ip, uid, aid) 
         VALUES ('$_ADDED, $_VARIANT #$variant, $_CREDIT $credit', now(), '$admin_name', 
            INET_ATON('$admin_ip'), '$uid', '$aid');")  || die $db->strerr;
      form_payments();
#      goto CHANGE_USER_INFO;
     }
  }
elsif($FORM{passwd}) {
   passwd($uid);
   return 0;
 }
elsif($FORM{change}) {

   $q = $db -> prepare("SELECT fio, credit, phone, address, email, logins, activate, expire, reduction, 
     INET_NTOA(ip), INET_NTOA(netmask), speed, filter_id, cid, comments
     FROM users  WHERE uid=\"$uid\";") || die $db->strerr;
   $q -> execute ();

   ($old_fio, $old_credit, $old_phone, $old_address, $old_email, $old_simultaneously, $old_activate, $old_expire,  
      $old_reduction, $old_ip, $old_netmask, $old_speed, $old_filter_id, $old_cid, $old_comments) = $q -> fetchrow();
   
   $changed .= " $_FIO: $fio" if ($old_fio ne $fio);

   $changed .= " $_CREDIT: $credit" if ($old_credit ne $credit); 
   $changed .= " $_PHONE: $phone" if ($old_phone ne $phone);
   $changed .= " $_SIMULTANEOUSLY: $simultaneously" if ($old_simultaneously ne $simultaneously);
   $changed .= " $_EXPIRE: $expire" if ($old_expire ne $expire);
   $changed .= " $_REDUCTION: $reduction" if ($old_reduction ne $reduction);
   #$changed .= " $_NAS: $nas" if ($old_nas ne $nas);
   $changed .= " $_ACTIVATE: $activate" if ($old_activate ne $activate);
   $changed .= " IP: $ip" if ($old_ip ne $ip);
   $changed .= " NetMask: $netmask" if ($old_netmask ne $netmask);
   $changed .= " $_SPEED: $speed" if ($old_speed ne $speed);
   $changed .= " $_FILTERS: $filter_id" if ($old_filter_id ne $filter_id);
   $changed .= " CID: $cid" if ($old_cid ne $cid);
   $changed .= " $_ADDRESS: $address" if ($old_address ne $address);
   $changed .= " E-mail: $email" if ($old_email ne $email);
   $changed .= " $_COMMENTS: $comments" if ($old_comments ne $comments);
#   $changed .= " $_LOGIN: $login" if ($old_login ne $login);
   
   if (length($changed) > 1) {
     $changed = "$_CHANGE " .  $changed;
     $sql = "UPDATE users SET 
       fio='$fio',
       credit='$credit',
       phone='$phone',
       address='$address',
       email='$email',
       logins='$simultaneously',
       activate='$activate',
       expire='$expire',
       reduction='$reduction',
       ip=INET_ATON('$ip'),
       netmask=INET_ATON('$netmask'),
       speed='$speed',
       filter_id='$filter_id',
       comments='$comments',
       cid=LOWER('$cid')
       WHERE uid=\"$uid\";";

     log_print('LOG_SQL', "$sql"); 
     $q = $db->do($sql) || die $db->errstr;

     $sql = "INSERT INTO userlog (log, date, ww, ip, uid, aid) 
       VALUES ('$changed', now(), '$admin_name', INET_ATON('$admin_ip'), '$uid', '$aid');";
     log_print('LOG_SQL', "$sql");
     $q = $db->do($sql) || die $db->strerr;

     message('info', "$_CHANGED", "<br><pre>$changed</pre>");
    }
    goto CHANGE_USER_INFO;
  }
elsif($FORM{del}) {
   $login = get_login($uid);
   $msg = "<table border=0 width=100%><tr><td>$_USER:</td><td><b>$login [$uid]</b></td></tr>\n".
          "<tr><td colspan=2>$_FROM:</td></tr>\n".
          "<tr><td colspan=2>&nbsp;&nbsp;log</td></tr>\n";

   my @clear_db = ('userlog', 
                   'fees', 
                   'payment', 
                   'users_nas', 
                   'messages',
                   'docs_acct',
                   'users');

   foreach my $table (@clear_db) {
     $sql = "DELETE from $table WHERE uid='$uid';";
     $q = $db->do($sql) || die $db->errstr;
     $msg .= "<tr><td colspan=2>&nbsp;&nbsp;$table</td></tr>\n";
    }

   $sql = "DELETE from log WHERE id='$login';";
   $q = $db->do($sql) || die $db->errstr;
   message('info', "$_DELETED", "$msg</table>");
   return 0;
  }
elsif($uid > 0) {
 CHANGE_USER_INFO:
   $sql = "SELECT u.id, u.fio, u.address, u.email, u.registration, u.variant, u.credit, u.deposit, u.phone, 
       u.logins, u.activate, u.expire, max(login), reduction, INET_NTOA(u.ip), INET_NTOA(netmask), u.speed, 
       u.filter_id, u.cid, u.comments
     FROM users u 
     LEFT join log l ON(u.id=l.id) 
     WHERE u.uid='$uid'
     GROUP by u.id;";
   
   $q = $db -> prepare($sql) || die $db->strerr;
   $q -> execute ();

   if ($q->rows < 1) {
       $login = get_login($uid);
       message('err', "$_ERROR", "$_NOT_EXIST [$uid]");
       return 0;
     };
   
   ($login, $fio, $address, $email, $registartion, $variant, $credit, $deposit, $phone, $simultaneously, $activate, $expire, 
      $last_login, $reduction, $ip, $netmask, $speed, $filter_id, $cid, $comments) = $q -> fetchrow();
   #$name = $FORM{chg};

    @action = ('change', $_CHANGE);
    require 'mail.pl';
    my $mbox_size = int2byte(mbox_size($login));

    $q = $db->prepare("SELECT name  FROM variant WHERE vrnt='$variant';") || die $db->strerr;
    $q ->execute();
    my($vname) = $q -> fetchrow();
    $variant_out = "<b>$variant:$vname</b> <a href='$SELF?op=chg_uvariant&uid=$uid' title='$_VARIANTS'>>></a>";
    
    $info = "<tr  bgcolor=$_BG2><td>$_USER:</td><td><b>$login</b></td></tr>\n".
     "<tr><td>UID:</td><td><b>$uid</b></td></tr>\n".
     "<tr><td>$_DEPOSIT:</td><td><b>$deposit</b></td></tr>\n".
     "<tr><td>$_REGISTRATION:</td><td><b>$registartion</b></td></tr>\n".
     "<tr><td>$_MAIL_BOX:</td><td>$mails ($mbox_size)</td></tr>\n".
     "<tr><td>$_LAST_LOGIN:</td><td>$last_login</td></tr>\n" ;
    print "<table width=600 border=1 cellspacing=1 cellpadding=2><tr><td>";
     form_user_info();
    print "</td><td bgcolor=$_BG3 valign=top width=180>
     <table width=100%><tr><td>
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
      <li><a href='$SELF?op=users&uid=$uid&passwd=chg'>$_PASSWD</a>
      <li><a href='$SELF?op=chg_uvariant&uid=$uid'>$_VARIANT</a>
      <li><a href='$SELF?op=allow_nass&uid=$uid'>$_NASS</a>
      <li><a href='$SELF?op=bank_info&uid=$uid'>$_BANK_INFO</a>
      <li><a href='$SELF?op=changes&uid=$uid'>$_LOG</a>
     </td></tr>
     </table>

     </td></tr></table>";
    
   }
 else {

   my $qs = "";
   if ($FORM{debs}) {
     print "<p>$_DEBETERS</p>";
     $qs .= "&debs=$FORM{debs}";
    }  

   if ($FORM{vid}) {
     print "<p>$_VARIANT: $FORM{variant}</p>"; 
     $WHERE = ($WHERE) ?  " and u.variant='$FORM{vid}' " : "WHERE u.variant='$FORM{vid}' ";
     $qs .= "&vid=$FORM{vid}";
    }

   print "<a href='$SELF?op=users'>All</a> ::";
   for ($i=97; $i<123; $i++) {
     $l = chr($i);
     if ($FORM{letter} eq $l) {
        print "<b>$l </b>"
      }
     else {
        print "<a href='$SELF?op=users&letter=$l$qs'>$l</a> ";
      }
    }

   if ($FORM{letter}) {
      $WHERE = ($WHERE) ?  " and u.id LIKE '$FORM{letter}%' " : "WHERE u.id LIKE '$FORM{letter}%' ";
      $qs .= "&letter=$FORM{letter}";
    }
  
  
   %pages = pages('u.id', 'users u', "$WHERE", "op=users&sort=$sort$qs", "$pg");
   print "<p><b>$_TOTAL:</b> $pages{count}</p>";
   print $pages{pages};

   $sql = "SELECT u.id, u.fio, u.deposit, u.credit, v.name, u.uid 
     FROM users u
     LEFT JOIN  variant v ON  (v.vrnt=u.variant) 
     $WHERE ORDER BY $sort $desc LIMIT $pg, $max_recs;";

   $q = $db -> prepare($sql)  || die $db->strerr;
   $q -> execute();


   print "<form action=$SELF>
   $_LOGIN: <input type=hidden  name=op value=users>
   <input type=text name=qshow value='$FORM{qshow}'>
   <input type=submit name=go value='$_SHOW'>
   </forM>
   <a href='$SELF?op=users&userform=y'>$_ADD</a>";


print "<TABLE width=640 cellspacing=0 cellpadding=0 border=0>
<TR><TD bgcolor=$_BG4>
<TABLE width=100% cellspacing=1 cellpadding=0 border=0>
<COLGROUP>
    <COL align=left span=2>
    <COL align=right span=2>
    <COL align=left span=1>
</COLGROUP>
\n";
my @caption = ("$_LOGIN", "$_USER", "$_SUM", "$_CREDIT", "$_VARIANT",  '-', '-');
show_title($sort, "$desc", "$pg", "$op$qs", \@caption);

   while(($login, $fio, $deposit, $credit, $tp_name,  $uid) = $q -> fetchrow()) {
     $bg = ($bg eq $_BG1) ? $_BG2 : $_BG1;
     print "<tr bgcolor=$bg><td><a href='$SELF?op=users&chg=$uid'>$login</a></td><td>$fio</td><td>$deposit</td><td>$credit</td><td>$tp_name</td>".
       "<td><a href='$SELF?op=payments&uid=$uid'>$_PAYMENTS</a></td>".
       "<td><a href='$SELF?op=stats&uid=$uid'>$_STATS</a></td></tr>\n";
    }
print "</table>
</td></tr></table>\n";
}


}


#*******************************************************************
# Bank info
# bank_info()
#*******************************************************************
sub bank_info {
 print "<h3>". $_BANK_INFO ."</h3>\n";

if ($FORM{change}) {
  $sql = "UPDATE users SET
   tax_number='$FORM{tax_number}', 
   bank_account='$FORM{bank_account}', 
   bank_name='$FORM{bank_name}', 
   cor_bank_account='$FORM{cor_bank_account}', 
   bank_bic='$FORM{bank_bic}'
  WHERE uid='$uid';";
  log_print('LOG_SQL', "$sql");
  $q = $db->do($sql) || die $db->strerr;
  message('info', $_INFO, "$_CHANGED");	
}


$sql = "SELECT  tax_number, bank_account, bank_name, cor_bank_account, bank_bic
   FROM users WHERE uid='$uid'";
log_print('LOG_SQL', "$sql");
$q = $db->prepare($sql) || die $db->strerr;
$q ->execute();

my ($tax_number, $bank_account, $bank_name, $cor_bank_account, $bank_bic)=$q->fetchrow();


print << "[END]";
<form action=$SELF>
<input type=hidden name=op value=bank_info>
<input type=hidden name=uid value=$uid>
<TABLE width=640 cellspacing=0 cellpadding=0 border=0>
  <TR><TD bgcolor=$_BG4>
  <TABLE width=100% cellspacing=1 cellpadding=0 border=0>
<tr bgcolor=$_BG1><td>$_USER:</td><td>$login_link</td></tr>
<tr bgcolor=$_BG1><td>$_TAX_NUMBER:</td><td><input type=text name=tax_number value='$tax_number' size=60></td></tr>
<tr bgcolor=$_BG1><td>$_ACCOUNT:</td><td><input type=text name=bank_account value='$bank_account' size=60></td></tr>
<tr bgcolor=$_BG1><td>$_BANK_NAME:</td><td><input type=text name=bank_name value='$bank_name' size=60></td></tr>
<tr bgcolor=$_BG1><td>$_COR_BANK_ACCOUNT:</td><td><input type=text name=cor_bank_account value='$cor_bank_account' size=60></td></tr>
<tr bgcolor=$_BG1><td>$_BANK_BIC:</td><td><input type=text name=bank_bic value='$bank_bic' size=60></td></tr>
</table>
</td></tr></table>
<p>
<input type=submit name=change value='$_CHANGE'>
</form>
[END]

}



#*******************************************************************
# Change user variant form
# form_chg_vid()
#*******************************************************************
sub form_chg_vid () {
 
# my $date = "$FORM{date_y}-$FORM{date_m}-$FORM{date_d}";
 my $new_variant = $FORM{new_variant} || $_DEFAULT_VARIANT;
 my $period = $FORM{period} || 0;

 my $variants=''; 
 my %vnames = ();
 
 print "<h3>$_VARIANT</h3>\n";

   $q = $db->prepare("SELECT variant FROM users WHERE uid='$uid';") || die $db->strerr;
   $q ->execute();
   if ($q->rows == 0) {
      message('err', $_ERROR, "$_USER $_NOT_EXIST");
      return 0;
    }
   my($old_variant) = $q -> fetchrow();

   $q = $db->prepare("SELECT vrnt, name FROM variant;") || die $db->strerr;
   $q ->execute();
   while(my($vid, $name) = $q -> fetchrow()) {
      $variants .= "<option value=$vid";
      $variants .= ' selected' if ($vid == $new_variant);
      $variants .= ">$vid:$name\n";
      $vnames{$vid}="$name";
    }

if ($FORM{change}) {
  my $message = "$_VARIANT: [$old_variant] $vnames{$old_variant} -> [$new_variant] $vnames{$new_variant}";
  if ($period == 1) {
    $FORM{date_m}++;

    shedule('add', {uid => $uid,
                    type => 'tp',
                    action => $new_variant,
    	            d => $FORM{date_d},
                    m => $FORM{date_m},
                    y => $FORM{date_y},
                    descr => "$message<br>
                    $_FROM: '$FORM{date_y}-$FORM{date_m}-$FORM{date_d}'"
                    })
   }
  else {
    if(chg_uvariant($uid, $old_variant, $new_variant) == 1) {
      message('info', $_CHANGED, "$message"); 	
      $old_variant=$new_variant;
     } 
    else {
      message('err', $_ERROR, "Exist ");
     }
  }
}
elsif($FORM{del}) {
 
  shedule('del', { uid => $uid,
   	              id  => $FORM{del}  } );
  

# $q = $db->do("DELETE FROM shedule WHERE id='$FORM{del}' and uid='$uid';") || die $db->strerr;
}


 my $params='';

 $q = $db->prepare("SELECT id, CONCAT(y, '-', m, '-', d), action FROM shedule WHERE type='tp' and uid='$uid';") || die $db->strerr;
 $q ->execute();
 
 if ($q->rows > 0) {
   my($id, $date, $new_variant) = $q -> fetchrow();
   
   $params = "<tr><th colspan=2 bgcolor=$_BG0>$_SHEDULE</th></tr>
              <tr><td>$_DATE:</td><td>$date</td></tr>
              <tr><td>$_CHANGE:</td><td>$new_variant:$vnames{$new_variant}</td></tr>
              </table>
              <input type=hidden name=del value='$id'>
              <input type=submit name=delete value='$_DEL'>\n";

  }
 else {

    $params .= "<tr><td>$_TO:</td><td><select name=new_variant>$variants</select></td></tr>";
    $params .= form_period($period);
    $params .= "</table><input type=submit name=change value=\"$_CHANGE\">\n";

  }




print << "[END]";
<form action=$SELF>
<input type=hidden name=uid value='$uid'>
<input type=hidden name=op value=chg_uvariant>
<table width=400 border=0>
<tr><td>$_USER:</td><td><a href='$SELF?op=users&chg=$uid'>$login</a></td></tr>
<tr><td>$_FROM:</td><td bgcolor=$_BG2>$old_variant $vnames{$old_variant} [<a href='$SELF?op=variants&chg=$old_variant' title='$_VARIANTS'>$_VARIANTS</a>]</td></tr>
$params
</form>
[END]
}



#*******************************************************************
# form_period
#*******************************************************************
sub form_period () {
 my $period = shift;
 my @periods = ("$PERIODS[0]", "$_OTHER");
 my $date_fld = date_fld('date_');
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


#*******************************************************************
#
# passwd($uid)
#*******************************************************************
sub passwd  {
  my $uid = shift;

if ($FORM{change}) {

  if (length($FORM{password}) < $conf{passwd_length}) {
     message('err', $_ERROR, "$ERR_SHORT_PASSWD");
   }
  elsif ($FORM{password} ne $FORM{confirm}) {
     message('err', $_ERROR, "$ERR_WRONG_CONFIRM");
   }
  else {
    my $sql = "UPDATE users SET password=ENCODE('$FORM{password}', '$conf{secretkey}')
       WHERE uid='$uid';";
    log_print('LOG_SQL', $sql);
     $q = $db->do($sql)  || die $db->strerr;
    message('info', $_CHANGE_PASSWD, "$_CHANGED");
   }
  return 0;	
}

=commnets
 $sql = "SELECT DECODE(password, '$conf{secretkey}') FROM users WHERE uid='$uid';";
 $q = $db -> prepare($sql)  || die $db->strerr;
 $q -> execute();
 ($passwd)=$q -> fetchrow();
 print "----- $passwd $sql";
=cut


my $gen_passwd = mk_unique_value(8);

print << "[END]";
<Table border=0 cellspacing="1" cellpadding="1">
<td><td bgcolor=000000>
<Table border=0 cellspacing="0" cellpadding="0">
<td><td bgcolor=FFFFFF>
<form ACTION=$SELF>
<input type=hidden name=op value=users>
<input type=hidden name=uid value=$uid>
<input type=hidden name=passwd value=chg>
<table>
<tr><th colspan=2 bgcolor=$_BG0>$_CHANGE_PASSWD</th></tr>
<tr><td>UID:</td><td>$login_link</td></tr>
<tr><td>$_GEN_PASSWD:</td><td>$gen_passwd</td></tr>
<tr><td>$_PASSWD:</td><td><input type=password name=password value='$gen_passwd'></td></tr>
<tr><td>$_CONFIRM:</td><td><input type=password name=confirm value='$gen_passwd'></td></tr>
</table>
<center><input type=submit name=change value="$_CHANGE">
</form>

</td></tr>
</table>
</td></tr>
</table>
[END]

}

#*******************************************************************
#
# form_user_info();
#*******************************************************************
sub form_user_info  {

 if (! $info) {
   $info = "<tr><td>$_USER:</td><td><input type=text name=login value='$login'></td></tr>\n";
   $q = $db->prepare("SELECT vrnt, name  FROM variant;") || die $db->strerr;
   $q ->execute();


   $variant_out = "<select name=variant>";
   while(($vid, $name) = $q -> fetchrow()) {
     $variant_out .= "<option value=$vid";
     $variant_out .= ' selected' if ($vid == $variant);
     $variant_out .=  ">$vid:$name\n";
    }
   $variant_out .= "</select>";
  }

print << "[END]";
<form action=$SELF method=post>
<input type=hidden name=op value=users>
<input type=hidden name=chg value="$uid">
<table width=420 cellspacing=0 cellpadding=3>
$info
<tr><td>$_FIO:</td><td><input type=text name=fio value="$fio"></td></tr>
<tr><td>$_PHONE:</td><td><input type=text name=phone value="$phone"></td></tr>
<tr><td>$_ADDRESS:</td><td><input type=text name=address value="$address"></td></tr>
<tr><td>E-mail:</td><td><input type=text name=email value="$email"></td></tr>
<tr><td colspan=2>&nbsp;</td></tr>
<tr><td>$_VARIANT:</td><td valign=center>$variant_out</td></tr>
<tr><td>$_CREDIT:</td><td><input type=text name=credit value='$credit'></td></tr>
<tr><td>$_SIMULTANEOUSLY:</td><td><input type=text name=simultaneously value='$simultaneously'></td></tr>
<tr><td>$_ACTIVATE:</td><td><input type=text name=activate value='$activate'></td></tr>
<tr><td>$_EXPIRE:</td><td><input type=text name=expire value='$expire'></td></tr>
<tr><td>$_REDUCTION (%):</td><td><input type=text name=reduction value='$reduction'></td></tr>
<tr><td>IP:</td><td><input type=text name=ip value='$ip'></td></tr>
<tr><td>Netmask:</td><td><input type=text name=netmask value='$netmask'></td></tr>
<tr><td>$_SPEED (kb):</td><td><input type=text name=speed value='$speed'></td></tr>
<tr><td>$_FILTERS:</td><td><input type=text name=filter_id value='$filter_id'></td></tr>
<tr><td><b>CID:</b><br>
MAC: [00:40:f4:85:76:f0]<br>
IP: [10.0.1.1]<br>
PHONE: [805057395959]</td><td><input type=text name=cid value='$cid'></td></tr>
<tr><th colspan=2>:$_COMMENTS:</th></tr>
<tr><th colspan=2><textarea name=comments rows=5 cols=45>$comments</textarea></th></tr>
</table>
<p>
<input type=submit name=$action[0] value='$action[1]'>
<input type=submit name=del value='$_DELETE_USER'  onclick="return confirmLink(this, '$_DELETE_USER ID: $uid')">
</form>
[END]
	
}

#*******************************************************************
# User payments
# form_payments()
#*******************************************************************

sub form_payments {
 my @action = ('add', $_ADD);
 my $sum = $FORM{sum} || 0;
 my $mu = $FORM{mu} || '';
 my $qs = '';

 if (! defined($FORM{sort})) {
   $sort = 1;
   $desc = 'DESC';
  }

 print "<h3>$_PAYMENTS</h3>\n".
       "<a href='$SELF?op=payments&m=y'>$_PER_MONTH</a><br>\n";

 my $uniq_str = mk_unique_value(16);

if (defined($FORM{m})) {
  if ($FORM{m} ne 'y') {
    $WHERE = "WHERE date_format(p.date, '%Y-%m')='$FORM{m}'";
    $date = "date_format(p.date, '%Y-%m-%d')";
    $period = 'd';
   }
  else {
    $date = "date_format(p.date, '%Y-%m')";
    $period = 'm';
   }

 
 $sql = "SELECT $date, count(p.id), sum(p.sum) FROM payment p
   $WHERE GROUP BY 1;";
 
 $q = $db -> prepare($sql) || die $db->errstr;
 $q -> execute();

 print "
  <TABLE width=640 cellspacing=0 cellpadding=0 border=0><TR><TD bgcolor=$_BG4>
  <TABLE width=100% cellspacing=1 cellpadding=0 border=0>\n\n";

  my $sum_total = 0;
  while(my($date, $users, $sum) = $q -> fetchrow()) {
    $bg = ($bg eq $_BG1) ? $_BG2 : $_BG1;
    print "<tr bgcolor=$bg><td align=right><a href='$SELF?op=payments&$period=$date'>$date</a></td><td align=right>$users</td>".
      "<td align=right>$sum</td></tr>\n";
    $sum_total += $sum;
   }

 print "<tr bgcolor=$_BG3><th>$_TOTAL:</th><th colspan=2 align=right>$sum_total</th></tr>\n".
  "</table>\n".
  "</td></tr></table>\n";
 return 0;
}
   
if ($uid > 0) {
  $qs = "&uid=$uid";
  if (defined($FORM{add}) && ($sum > 0)) {
    if ($FORM{opid} ne  $cookies{opid}) {
      $q = $db -> prepare("SELECT deposit FROM users WHERE uid='$uid';") || die $db->errstr;
      $q -> execute();
      if ($q->rows == 1) {
        my ($deposit)=$q -> fetchrow();

        if ($mu ne '') {
       	   $sum = $sum / $mu;
         }

        $db ->do("UPDATE users SET deposit=deposit+$sum WHERE uid='$uid';") or
          die $db->errstr;
        #$admin_host
        $sql = "INSERT INTO payment (uid, date, sum, dsc, ww, ip, last_deposit, aid) 
           values ('$uid', now(), $sum, '$FORM{describe}', '$admin_name', INET_ATON('$admin_ip'), '$deposit', '$aid');";
        $db -> do ($sql) or die $db->errstr;
     
        message('info', "$_PAYMENT_ADDED", 
          "<table><tr><td>$_USER:</td><td><b>$login</b></td>\n".
          "<tr><td>$_SUM:</td><td><b>$sum</b></td>\n".
          "<tr><td>$_DESCRIBE:</td><td><b>$FORM{describe}</b></td></tr>\n".
          "</table>\n");
       }
      else {
        message('err', "$_ERROR", $_USER_NOT_EXIST);
       }
     }   
   else {
     message('err', "$_ERROR", "$_EXIST");
    }
 }
elsif($FORM{del}) {
   
    $sql = "SELECT sum, date FROM payment WHERE uid='$uid' and id='$FORM{del}';";
    log_print('LOG_SQL', '$sql');
    $q = $db->prepare($sql) || die $db->errstr;
    $q -> execute();

    if ($q->rows == 1) {
      my ($sum, $date) = $q -> fetchrow();

      $sql="DELETE FROM payment WHERE uid='$uid' and id='$FORM{del}';";
      log_print('LOG_SQL', '$sql'); 

      $db -> do ($sql) or die $db->errstr;
      
      $sql = "UPDATE users SET deposit=deposit-$sum WHERE uid='$uid';";
      log_print('LOG_SQL', '$sql'); 
      
      $db -> do ($sql) or die $db->errstr;

      message('info', "$_PAYMENT_DELETED", "<table width=100%>
        <tr><td>$_USER:</td><td><b>$login</b></td></tr>
        <tr><td>Payment ID:</td><td><b>$FORM{del}</b></td></tr>
        <tr><td>$_SUM:</td><td><b>$sum</b></td></tr>
        </table>\n");
      $sum=0;
     }
    else {
      message('err', "$_ERROR", "$_PAYMENT_NOTEXIST  UID: [$uid] id: [$FORM{del}]");
   }
 }
 
 
$sql = "SELECT short_name, rate FROM exchange_rate";
$q = $db->prepare($sql) || die $db->errstr;
$q -> execute();

if ($q->rows > 0) {
   $mu = "<tr><td>$_MONETARY_UNIT:</td><td><select name=mu>
   <option value=>\n";
   while(my ($monetary_unit, $rate) = $q -> fetchrow()) {
      $mu .= "<option value=\"$rate\">$monetary_unit ($rate)\n";
    }
   $mu .= "</select></td></tr>\n";
}
 
 my $opid = mk_unique_value(12);
 
print << "[END]";
<form action=$SELF>
<input type=hidden name=op value=payments>
<input type=hidden name=uid value=$uid>
<input type=hidden name=opid value="$opid">
<table>
<tr><td>$_NAME:</td><td><b><a href='$SELF?op=users&chg=$uid'>$login</a></b></td></tr>
<tr><td>$_SUM:</td><td><input type=text name=sum value='$sum'></td></tr>
$mu
<tr><td>$_DESCRIBE:</td><td><input type=text name=describe value='$describe'></td></tr>
</table>
<input type=submit name=$action[0] value='$action[1]'>
</form>
[END]

  $WHERE = "WHERE p.uid='$uid'";
}
elsif (defined($FORM{d})) {
  $WHERE = "WHERE date_format(date, '%Y-%m-%d')='$FORM{d}'";
}
else {
  my $from_date = date_fld('from');
  my $to_date = date_fld('to');


print << "[END]";
<form action=$SELF>
<input type=hidden name=op value=payments>
<input type=hidden name=uid value='$uid'>
<table>
<tr><td colspan=2><hr></td></tr>
<tr><td>$_USER:</td><td><input type=text name=name value='$FORM{name}'></td></tr>
<tr><td>$_DATE:</td><td>
<table width=100%>
<tr><td>$_FROM: </td><td>$from_date</td></tr>
<tr><td>$_TO</td><td>$to_date</td></tr>
</table>
</td></tr>
<tr><td>$_SUM:</td><td><input type=text name=sum value='$sum'></td></tr>
<tr><td>$_DESCRIBE:</td><td><input type=text name=descr value='$FORM{descr}'></td></tr>
<tr><td>$_OPERATOR:</td><td><input type=text name=oper value='$FORM{oper}'></td></tr>
</table>
<input type=submit name=search value='$_SEARCH'>
</form>
[END]
 

if ($FORM{search}) {
  
  print "Result.....";
  
  $pgs = "&search=y&fromd=$FORM{fromd}&fromm=$FORM{fromm}&fromy=$FORM{fromy}&tod=$FORM{tod}&tom=$FORM{tom}&toy=$FORM{toy}";
  $FORM{fromm}++;
  $FORM{tom}++;
  $FORM{fromm} = sprintf("%.2d", $FORM{fromm}++);
  $FORM{tom} = sprintf("%.2d", $FORM{tom}++);
  $WHERE .= "WHERE date_format(date, '%Y-%m-%d')>='$FORM{fromy}-$FORM{fromm}-$FORM{fromd}' and date_format(date, '%Y-%m-%d')<='$FORM{toy}-$FORM{tom}-$FORM{tod}'";
  
  if ($FORM{name}) {
    $FORM{name} =~ s/\*/\%/gi;
    #$uid = get_uid($FORM{'name'});
    $WHERE .= " and u.id LIKE '$FORM{name}'";
    $pgs .= "&name=$FORM{name}";
   }

  if ($FORM{descr}) {
    $descr = $FORM{descr};
    $descr =~ s/\*/\%/gi;
    $WHERE .= " and dsc LIKE '$descr'";
    $pgs .= "&descr=$FORM{descr}";
   }

  if ($FORM{oper}) {
    $WHERE .= " and ww='$FORM{oper}'";
    $pgs .= "&oper=$FORM{name}";
   }

  if ($FORM{sum}) {
    if ($sum =~ s/^>//) {
       $param='>';
      }
    elsif($sum =~ s/^<//) {
       $param='<';
     }
    else {
       $param='=';
     }
    $WHERE .= " and sum$param'$sum'";
    $pgs .= "&sum=$FORM{sum}";
   }
}
	
}



if (defined($FORM{m})) {
  $WHERE .= "DATE_FORMAT(p.date, '%Y-%m')='$FORM{m}'";
  $GROUP = "GROUP BY DATE_FORMAT(p.date, '%Y-%m-%d')";
 }

  %pages = pages('p.id', 'payment p LEFT JOIN users u ON (u.uid=p.uid)', "$WHERE", "op=payments&uid=$uid$pgs&sort=$sort&desc=$desc", "$pg");
  print $pages{pages};

  $sql = "SELECT p.id, u.id, p.date, p.sum, p.dsc, p.ww, INET_NTOA(p.ip), p.last_deposit, p.uid 
    FROM payment p
    LEFT JOIN users u ON (u.uid=p.uid)
    $WHERE 
    $GROUP 
    ORDER BY $sort $desc 
    LIMIT $pg, $max_recs;";

  #print $sql;
  log_print('LOG_SQL', "$sql");

  $q = $db -> prepare($sql) || die $db->strerr;
  $q -> execute();

  print "<TABLE width=99% cellspacing=0 cellpadding=0 border=0>".
        "<TR><TD bgcolor=$_BG4>".
        "<TABLE width=100% cellspacing=1 cellpadding=0 border=0>\n".
        "<COLGROUP>
           <COL align=right span=1>
           <COL align=left span=1>
           <COL align=right span=2>
           <COL align=left span=2>
           <COL align=right span=2>
           <COL align=center span=1>
        </COLGROUP>\n";

  my @caption = ("$_NUM", "$_USER", "$_DATE", "$_SUM", "$_DESCRIBE", "$_OPERATOR", "IP", "$_DEPOSIT", "-");

  show_title($sort, "$desc", "$pg", "$op$qs$pgs", \@caption);

  $sum_total = 0;
  while(my($id, $login, $date,  $sum, $dsc, $ww, $adm_ip, $last_deposit, $uid) = $q -> fetchrow()) {
    $bg = ($bg eq $_BG1) ? $_BG2 : $_BG1;
    $button = "<A href='$SELF?op=payments&uid=$uid&del=$id&sum=$sum' onclick=\"return confirmLink(this, '$_USER: $login | $_SUM: $sum | $_DATE: $date | $_NUM: $id')\">$_DEL</a>";
    print "<tr bgcolor=$bg><td>$id</td><td><a href='$SELF?op=users&chg=$uid'>$login</a></td><td>$date</td>".
      "<td>$sum</td><td>$dsc</td><td>$ww</td><td>$adm_ip</td><td>$last_deposit</td><td>$button</td></tr>\n";
    $sum_total += $sum;
   }  
 print "<tr bgcolor=$_BG3><th>$_TOTAL:</th><th colspan=6 align=right>$sum_total</th><td colspan=2>&nbsp</td></tr>\n".
 "</table>\n".
 "</td></tr></table>";
}



#*******************************************************************
#show session detalization
# s_detail($uid, $sid)
#*******************************************************************
sub sdetail {
  my ($uid, $sid) = @_; 	
 $login=get_login($uid);

 $sql = "SELECT l.login as begin, l.login + INTERVAL l.duration SECOND as end, SEC_TO_TIME(l.duration), 
 l.variant, v.name,
 l.sent, l.recv, l.sent2, l.recv2,
 INET_NTOA(l.ip), 
 l.CID,
 l.nas_id,
 l.port_id,
 l.sum,
 u.uid
 FROM log l, variant v
 LEFT JOIN users u ON (u.id=l.id)
 WHERE l.variant=v.vrnt and
  l.id='$login' and l.acct_session_id='$sid';";
 
 log_print('LOG_SQL', "Func: $op SQL:");

 $q = $db -> prepare($sql) || die $db->strerr;
 $q -> execute ();


if ($q->rows < 1) {
   message('err', $_ERROR, "$_NOT_EXIST<br>UID: $uid<br>$_SESSION_ID: $sid");
   return 0;	
 }

 my ($begin, $end, $duration, $variant, $v_name, $sent, $recv, $sent2, $recv2,
  $ip, $CID, $nas_id, $port_id, $sum, $uid) = $q -> fetchrow();

 $sent = int2byte($sent); 
 $recv = int2byte($recv);  
 $sent2 = int2byte($sent2);  
 $recv2 = int2byte($recv2); 

print "<h3>$_SDETAIL</h3>\n";

  my $NAS_INFO = nas_params();
  my %NAS_IDS = reverse %$NAS_INFO;
  $ip = $NAS_IDS{$nas_id};

print << "[END]";
<TABLE width=600 cellspacing=0 cellpadding=0 border=0>
<TR><TD bgcolor=$_BG4>
<table border=0 cellspacing=1 cellpadding=0 width=100%>
<tr bgcolor=$_BG0><th align=left>UID:</th><th align=left>$login_link</th></tr>
<tr bgcolor=$_BG1><td>$_SESSION_ID:</td><td>$sid</td></tr>
<tr bgcolor=$_BG1><td>$_BEGIN:</td><td>$begin</td></tr>
<tr bgcolor=$_BG1><td>$_END:</td><td>$end</td></tr>
<tr bgcolor=$_BG1><td>$_DURATION:</td><td>$duration</td></tr>
<tr bgcolor=$_BG1><td>$_VARIANT:</td><td>$variant (<a href='$SELF?op=variants&chg=$variant'>$v_name</a>)</td></tr>
<tr><th bgcolor=$_BG3 colspan=2>$_TRAFFIC 1</th></tr>
<tr bgcolor=$_BG1><td>$_SENT:</td><td align=right>$sent</td></tr>
<tr bgcolor=$_BG1><td>$_RECV:</td><td align=right>$recv</td></tr>
<tr bgcolor=$_BG3><th colspan=2>$_TRAFFIC 2</th></tr>
<tr bgcolor=$_BG1><td>$_SENT:</td><td align=right>$sent2</td></tr>
<tr bgcolor=$_BG1><td>$_RECV:</td><td align=right>$recv2</td></tr>
<tr bgcolor=$_BG1><th colspan=2>&nbsp;</th></tr>
<tr bgcolor=$_BG1><td>NAS:</td><td>ID: $nas_id<br>IP: $ip<br>TYPE: $NAS_INFO->{nt}{$nas_id}</td></tr>
<tr bgcolor=$_BG1><td>NAS_PORT:</td><td>$port_id</td></tr>
<tr bgcolor=$_BG1><td>IP:</td><td>$ip</td></tr>
<tr bgcolor=$_BG1><td>CID:</td><td>$CID</td></tr>
<tr bgcolor=$_BG0><th align=left>$_SUM:</th><th align=right>$sum</th></tr>
</table>
</td></tr></table></P>
[END]


# Session details


if ($FORM{period} eq 'days') {
  $lupdate = "DATE_FORMAT(FROM_UNIXTIME(last_update), '%Y-%m-%d')";	
}
elsif($FORM{period} eq 'hours') {
  $lupdate = "DATE_FORMAT(FROM_UNIXTIME(last_update), '%Y-%m-%d %H')";	
}
else {
  $lupdate = "FROM_UNIXTIME(last_update)";
}


my %periods = ('days' => "$_DAYS", 
   'hours' => "$_HOURS", 
   'all' => "$_ALL");


my %pages = pages("DISTINCT $lupdate", 's_detail', "WHERE uid='$login' GROUP BY uid", "op=sdetail&uid=$uid&period=$FORM{period}", "$pg");

if (! defined($FORM{sort})) {
  $sort = 1;
  $desc = 'DESC';	
}

$sid = ($FORM{sid}) ? "and acct_session_id='$FORM{sid}'": '';
   

$sql = "SELECT $lupdate, acct_session_id, nas_id, 
   sum(sent1), sum(recv1), sum(sent2), sum(recv2) 
  FROM s_detail 
  WHERE uid='$login' $sid
  GROUP BY 1 
  ORDER BY $sort $desc
  LIMIT $pg, $max_recs;";
 log_print('LOG_SQL', "Func: $op - $sql:");


 $q = $db -> prepare($sql) || die $db->strerr;
 $q -> execute ();

if ($q->rows < 1) {
   return 0;	
 }

 while(my($k, $v)=each %periods) {
   if ($FORM{period} eq $k) {
     print "<b>$v</b> :: ";
     $params = "&period=$k";
    }
   else  {
     print "<a href='$SELF?op=sdetail&sid=$FORM{sid}&uid=$uid&period=$k'>$v</a> :: ";	
    }
  }
 print "<p>$pages{pages}</p><TABLE width=99% cellspacing=0 cellpadding=0 border=0>
  <TR><TD bgcolor=$_BG4>
  <TABLE width=100% cellspacing=1 cellpadding=0 border=0>\n";
 my @caption = ("LAST_UPDATE", "$_SESSION_ID", "NAS_ID", "SENT", "RECV", "SENT2", "RECV2");
 show_title("$sort", "$desc", "$pg", "$op&sid=$FORM{sid}&uid=$FORM{uid}$params", \@caption);

 print "<COLGROUP>
    <COL align=left span=1>
    <COL align=left span=1>
    <COL align=right span=7>
  </COLGROUP>\n";

 while(my ($last_update, $acct_session_id, $nas_id, 
  $sent1, $recv1, $sent2, $recv2) = $q -> fetchrow()) {
   $bg = ($bg eq $_BG1) ? $_BG2 : $_BG1;
   $sent1 = int2byte($sent1);
   $recv1 = int2byte($recv1); 
   $sent2 = int2byte($sent2); 
   $recv2 = int2byte($recv2);
   my $bgt = $_BG2 if ($FORM{sid} eq $acct_session_id);
   print "<tr bgcolor=$bg><td bgcolor=$bgt>$last_update</td><td><a href='grapher.cgi?session_id=$acct_session_id'>$acct_session_id</a></td><td>$nas_id</td>
    <td>$sent1</td><td>$recv1</td><td>$sent2</td><td>$recv2</td></tr>\n";
  }
 print "</table>
 </td></tr></table>
 <p>$pages{pages}</p>\n";
}



#*******************************************************************
#show stats
# stats()
#*******************************************************************
sub stats  {
  my $login = get_login($uid);  
  my $WHERE = '';
  my $GROUP = '';
  


if ($login ne '') {
  $WHERE = "WHERE id='$login' ";
  $GROUP = "GROUP BY id";
 }

 $max_recs = $FORM{rows} if (defined($FORM{rows}));

 $q = $db -> prepare("SELECT  
   sum(if(date_format(login, '%Y-%m-%d')=curdate(), sent, 0)), 
   sum(if(date_format(login, '%Y-%m-%d')=curdate(), recv, 0)), 
   SEC_TO_TIME(sum(if(date_format(login, '%Y-%m-%d')=curdate(), duration, 0))), 

   sum(if(TO_DAYS(curdate()) - TO_DAYS(login) = 1, sent, 0)),
   sum(if(TO_DAYS(curdate()) - TO_DAYS(login) = 1, recv, 0)),
   SEC_TO_TIME(sum(if(TO_DAYS(curdate()) - TO_DAYS(login) = 1, duration, 0))),

   sum(if((YEAR(curdate())=YEAR(login)) and (WEEK(curdate()) = WEEK(login)), sent, 0)),
   sum(if((YEAR(curdate())=YEAR(login)) and  WEEK(curdate()) = WEEK(login), recv, 0)),
   SEC_TO_TIME(sum(if((YEAR(curdate())=YEAR(login)) and WEEK(curdate()) = WEEK(login), duration, 0))),

   sum(if(date_format(login, '%Y-%m')=date_format(curdate(), '%Y-%m'), sent, 0)), 
   sum(if(date_format(login, '%Y-%m')=date_format(curdate(), '%Y-%m'), recv, 0)), 
   SEC_TO_TIME(sum(if(date_format(login, '%Y-%m')=date_format(curdate(), '%Y-%m'), duration, 0))),
  
   sum(sent), sum(recv), SEC_TO_TIME(sum(duration))
   FROM log $WHERE;") || die $db->strerr;
  $q -> execute ();

  if ($q->rows == 0) {
      message('err', "$_ERROR ", "$_NOT_EXIST $_USER: '$login'");
      return 0;	
    }

  my $today_sum = 0;
  my $yesterday_sum = 0;
  my $week_sum = 0;
  my $month_sum = 0;
  my $all_sum = 0;

  my ($today_sent, $today_recv, $today_duration, $yesterday_sent, $yesterday_recv, $yesterday_duration,
  $week_sent, $week_recv, $week_duration, $month_sent, $month_recv, $month_duration, $all_sent, $all_recv, $all_duration) = $q -> fetchrow();
  
  $today_sum = int2byte($today_sent + $today_recv);
  $yesterday_sum = int2byte($yesterday_sent + $yesterday_recv);
  $week_sum = int2byte($week_sent + $week_recv);
  $month_sum = int2byte($month_sent + $month_recv);
  $all_sum = int2byte($all_sent + $all_recv);

  $today_sent = int2byte($today_sent);
  $today_recv = int2byte($today_recv);
  $yesterday_sent = int2byte($yesterday_sent); 
  $yesterday_recv = int2byte($yesterday_recv);
  $week_sent = int2byte($week_sent);
  $week_recv = int2byte($week_recv);
  $month_sent = int2byte($month_sent);
  $month_recv = int2byte($month_recv);
  $all_sent = int2byte($all_sent);
  $all_recv = int2byte($all_recv);

 
print "<TABLE width=640 cellspacing=0 cellpadding=0 border=0>
  <tr><TD bgcolor=$_BG4>
  <TABLE width=100% cellspacing=1 cellpadding=0 border=0>
  <COLGROUP>
    <COL align=left span=1>
    <COL align=right span=4>
  </COLGROUP>
  <tr bgcolor=$_BG1><th align=left>$_USER</th><td colspan=4><a href='$SELF?op=users&chg=$uid'>$login</a></td></tr>
  <tr bgcolor=$_BG0><th>$_PERIOD</th><th>$_DURATION</th><th>$_SENT</th><th>$_RECV</th><th>$_SUM</th></tr>
  <tr bgcolor=$_BG1><th align=left><a href='$SELF?op=stats&uid=$uid&period=0'>$PERIODS[0]</a></th><td>$today_duration</td><td>$today_sent</td><td>$today_recv</td><th>$today_sum</th></tr>
  <tr bgcolor=$_BG1><th align=left><a href='$SELF?op=stats&uid=$uid&period=1'>$PERIODS[1]</a></th><td>$yesterday_duration</td><td>$yesterday_sent</td><td>$yesterday_recv</td><th>$yesterday_sum</th></tr>
  <tr bgcolor=$_BG1><th align=left><a href='$SELF?op=stats&uid=$uid&period=2'>$PERIODS[2]</a></th><td>$week_duration</td><td>$week_sent</td><td>$week_recv</td><th>$week_sum</th></tr>
  <tr bgcolor=$_BG1><th align=left><a href='$SELF?op=stats&uid=$uid&period=3'>$PERIODS[3]</a></th><td>$month_duration</td><td>$month_sent</td><td>$month_recv</td><th>$month_sum</td></tr>
  <tr bgcolor=$_BG1><th align=left><a href='$SELF?op=stats&uid=$uid&period=4'>$PERIODS[4]</a></th><td>$all_duration</td><td>$all_sent</td><td>$all_recv</td><th>$all_sum</th></tr>
  <tr bgcolor=$_BG1><th align=left><a href='$SELF?op=stats&uid=$uid&period=5'>$PERIODS[5]</a></th><td>$act_duration</td><td>$act_sent</td><td>$act_recv</td><th>$act_sum</th></tr>
  </table>
  </td></tr></table>\n";

$q -> finish ();

my $from_date = date_fld('from');
my $to_date = date_fld('to');

print "<form action=$SELF>
 <input type=hidden name=op value='stats'>
 <input type=hidden name=uid value='$uid'>
 <table bgcolor=$_BG0><tr><th>$_FROM:</th><td>$from_date</td><th>$_TO:</th><td>$to_date</td>
 <th>$_ROWS: <input type=text name=rows value='$max_recs' size=4></th><td><input type=submit name=show value=$_SHOW></td></tr></table>
 </form>\n";

my $period = $FORM{period} || 0;
if ($period == 4) {  $WHERE .= '';}
elsif ($uid > 0) {
  $WHERE .= ' and '; 
 }
else  { 
  $WHERE .= 'WHERE ';       
 }


if (defined($FORM{show})) {
  
  $show = "&show=y&rows=$max_recs&fromd=$FORM{fromd}&fromm=$FORM{fromm}&fromy=$FORM{fromy}&tod=$FORM{tod}&tom=$FORM{tom}&toy=$FORM{toy}";

  $FORM{fromm}++;
  $FORM{tom}++;
  $FORM{fromm} = sprintf("%.2d", $FORM{fromm}++);
  $FORM{tom} = sprintf("%.2d", $FORM{tom}++);
  $WHERE .= "date_format(login, '%Y-%m-%d')>='$FORM{fromy}-$FORM{fromm}-$FORM{fromd}' and date_format(login, '%Y-%m-%d')<='$FORM{toy}-$FORM{tom}-$FORM{tod}'";
 }
elsif($period == 0) { $WHERE .= "date_format(login, '%Y-%m-%d')=curdate() "; }
elsif($period == 1) { $WHERE .= "TO_DAYS(curdate()) - TO_DAYS(login) = 1 ";  }
elsif($period == 2) { $WHERE .= "YEAR(curdate()) = YEAR(login) and (WEEK(curdate()) = WEEK(login)) ";  }
elsif($period == 3) { $WHERE .= "date_format(login, '%Y-%m')=date_format(curdate(), '%Y-%m') "; }
elsif($period == 4) { $WHERE .= ''; }
elsif($period == 5) { $WHERE .= "date_format(login, '%Y-%m-%d')='$FORM{login}' "; }
else {$WHERE .= "date_format(login, '%Y-%m-%d')=curdate() "; }

 if ($FORM{show}) { 
    print "<b>$_FROM:</b> $FORM{fromy}-$FORM{fromm}-$FORM{fromd} <b>$_TO:</b> $FORM{toy}-$FORM{tom}-$FORM{tod}";
   }
 else { 
    print  $PERIODS[$period];   
  }


 print "<TABLE width=640 cellspacing=0 cellpadding=0 border=0>
  <TR><TD bgcolor=$_BG4>
  <TABLE width=100% cellspacing=1 cellpadding=0 border=0>
  <tr bgcolor=$_BG0><th>$_LOGINS</td><th>$_DURATION</th><Th>$_TRAFFIC</th><th>$_SUM</th></tr>\n";


 $sql = "SELECT count(login), SEC_TO_TIME(sum(duration)), sum(sent + recv), sum(sum) FROM log $WHERE $GROUP;";
 log_print('LOG_SQL', $sql);

 $q = $db -> prepare($sql) || die $db->strerr;
 $q -> execute();
 my ($logins, $duration, $trafic, $sum) = $q -> fetchrow();
 
 $trafic = int2byte($trafic);

 print "<tr bgcolor=$_BG1><td align=right>$logins</td><td align=right>$duration</td>".
       "<TD align=right>$trafic</td><th align=right>$sum</th></tr>\n".
       "</table>\n</td></tr></table><p>\n";

if ($login ne '') {
# Averange 
 
 base_state();
 
 print "<TABLE width=99% cellspacing=0 cellpadding=0 border=0>
  <TR><TD bgcolor=$_BG4>
  <TABLE width=100% cellspacing=1 cellpadding=0 border=0>
  <tr bgcolor=$_BG0><th>$_LOGIN</td><th>$_DURATION</th><th>$_VARIANT</th><Th>$_SENT</Th><Th>$_RECV</th><th>CID</th><th>IP</th><th>$_SUM</th><th>-</th><th>-</th></tr>\n".
  "<colgroup align=right span=9>";

 $sql = "SELECT  login, UNIX_TIMESTAMP(login), variant, SEC_TO_TIME(duration), duration, 
  sent, recv, INET_NTOA(ip), CID, sum, acct_session_id
  FROM log $WHERE ORDER by login DESC LIMIT $pg, $max_recs;";

 log_print('LOG_SQL', "$sql");
 $q = $db->prepare($sql) || die $db->strerr;
 $q -> execute();
 
  while(my($ltime, $s_begin, $variant, $duration, $uduration, $sent, $recv, $ip, $CID, $sum, $sid) = $q -> fetchrow()) {
    $sent = int2byte($sent);
    $recv = int2byte($recv);

    $s_end = $s_begin + $uduration;
    %s_intervals = session_spliter($s_begin, $s_end, $variant);
    
    $rows=0;
    $s_sum=0;

    while(($key, $val) = each(%s_intervals)) {
      $rows++;
    }
    
    $bg = ($bg eq $_BG1) ? $_BG2 : $_BG1;
    $button = "<A href='$SELF?op=bm&del=log&login=$login&ltime=$ltime&sum=$sum&duration=$uduration'
        onclick=\"return confirmLink(this, '$_USER: $login | $_LOGIN: $ltime | $_SUM: $sum | $_DURATION: $duration')\">$_DEL</a>";

    $out_tr = "<tr bgcolor=$bg><td>$ltime ($rows)</td><td>$duration</td><td>$variant</td>
        <TD>$sent</TD><TD>$recv</td><td>$CID</td><td>$ip</td><th>$sum</th><th>(<a href='$SELF?op=sdetail&sid=$sid&uid=$uid' title='Session detalization'>D</a>)</th><td>$button</td></tr>\n";

    print "$out_tr";
   }
  print "</table>\n</td></tr></table>\n";

  %pages = pages('id', 'log', "$WHERE", "op=stats&uid=$uid&period=$period$show", "$pg");
  print $pages{pages};
 
 }
else  {
  my $i = 0;
  foreach $line (@periods) {
     print "<a href='$SELF?op=stats&period=$i'>$line</a> :: ";
     $i++;
   }
  $qs = "$ENV{QUERY_STRING}";
  $qs =~ s/&s=\d//g;

  print "<TABLE width=98% cellspacing=0 cellpadding=0 border=0><TR><TD bgcolor=$_BG4>
  <TABLE width=100% cellspacing=1 cellpadding=0 border=0>
  <caption>$period[$FORM{period}]</caption>
  <COLGROUP width=20>
    <COL align=left span=1>
    <COL align=right span=7>
  </COLGROUP>\n";


  my @caption = ("$_USER", "$_DURATION", "$_SENT", "$_RECV", "$_SUM", "$_SENT 2", "$_RECV 2", "$_SUM 2");
  show_title($sort, $desc, "$pg", "stats&period=$period$show", \@caption);

  $sql = "SELECT u.id, SEC_TO_TIME(sum(l.duration)), sum(l.sent), sum(l.recv), sum(l.sent + l.recv), sum(l.sent2), sum(l.recv2), sum(l.sent2 + l.recv2), u.uid
    FROM log l
    LEFT JOIN users u ON (u.id=l.id)
    $WHERE 
    GROUP BY l.id 
    ORDER By $sort $desc;";

  $q = $db -> prepare($sql) || die $db->strerr;
  log_print('LOG_SQL', $sql);
  $q -> execute();
  my ($total_sent, $total_recv, $total_sum, $total_sent2, $total_recv2,  $total_sum2);

  while(my ($login, $duration, $sent, $recv, $traff_sum, $sent2, $recv2, $traff_sum2, $uid) = $q -> fetchrow()) {

     $bg = ($bg eq $_BG1) ? $_BG2 : $_BG1;
     $total_sent += $sent;
     $total_recv += $recv;
     $total_sum += $traff_sum;
     $total_sent2 += $sent2;
     $total_recv2 += $recv2;
     $total_sum2 += $traff_sum2;

     $sent = int2byte($sent);
     $recv = int2byte($recv);
     $traff_sum = int2byte($traff_sum);

     $sent2 = int2byte($sent2);
     $recv2 = int2byte($recv2);
     $traff_sum2 = int2byte($traff_sum2);

     print "<tr bgcolor=$bg><td><a href='$SELF?op=stats&uid=$uid'>$login</a></td><td>$duration</td>".
      "<td>$sent</td><td>$recv</td><th>$traff_sum</th><td>$sent2</td><td>$recv2</td><th>$traff_sum2</th></tr>\n";
    }

   $total_recv=int2byte($total_recv);
   $total_sent=int2byte($total_sent);
   $total_sum=int2byte($total_sum);
   $total_sum2=int2byte($total_recv2 + $total_sent2);
   $total_recv2=int2byte($total_recv2);
   $total_sent2=int2byte($total_sent2);



   print "<tr bgcolor=$_BG3><th>Total</th><th>-</th><td>$total_sent</td><td>$total_recv</td><th>$total_sum</th>".
   "<td>$total_sent2</td><td>$total_recv2</td><th>$total_sum2</th></tr>\n";

  $q -> finish ();
  print "</table></td></tr></table>\n";
  }
}

#*******************************************************************
# tarifs
# variants()
#*******************************************************************

sub variants  {

print "<h3>$_VARIANTS</h3>\n";
my @action = ('add', "$_ADD");
my $logins = $FORM{logins} || 0;
my $month_pay = $FORM{month_pay} || 0,
my $day_pay = $FORM{day_pay} || 0;
my $uplimit = $FORM{uplimit} || 0;
my $hour_tarif=$FORM{hour_tarif} || 0;
#my $traf_tarif=$FORM{traf_tarif} || 0;
my $end=$FORM{end} || '24:00:00';
my $begin=$FORM{begin} || '00:00:00';

my $day_time_limit = $FORM{day_time_limit} || '0'; 
my $week_time_limit = $FORM{week_time_limit} || '0';
my $month_time_limit = $FORM{month_time_limit} || '0';
my $day_traf_limit = $FORM{day_traf_limit} || '0';
my $week_traf_limit = $FORM{week_traf_limit} || '0';
my $month_traf_limit = $FORM{month_traf_limit} || '0';

my $activate_price = $FORM{activate_price} || '0.00';
my $change_price = $FORM{change_price} || '0.00';
my $prepaid_trafic = $FORM{prepaid_trafic} || '0';
my $credit_tresshold = $FORM{credit_tresshold} || '0.00';

if(exists $FORM{intervals}) {
   intervals();	
   return 0;
 }
elsif ($FORM{add}) {
    $sql = "INSERT INTO variant (vrnt, hourp, uplimit, name, ut, dt, abon, df, logins,
     day_time_limit, week_time_limit,  month_time_limit, day_traf_limit, week_traf_limit,  month_traf_limit,
     activate_price, change_price, prepaid_trafic, credit_tresshold)
      VALUES ('$FORM{vrnt}', '$hour_tarif', '$uplimit', \"$FORM{name}\", 
        '$end', '$begin', '$month_pay', '$day_pay', '$logins', 
        '$day_time_limit', '$week_time_limit',  '$month_time_limit', '$day_traf_limit', '$week_traf_limit',  '$month_traf_limit',
        '$activate_price', '$change_price', '$prepaid_trafic', '$credit_tresshold');";

    $q = $db->do($sql);

    if ($db->err == 5) {
       message('err', "$_ERROR", $_EXIST);
      }
    elsif($db->err > 0) {
       message('err', "$_ERROR", $db->errstr);
      }
    else {
      message('info', "$_ADDED", "#: [$FORM{vrnt}]<br>$_NAME: '$FORM{name}'");
     }
 }
elsif ($FORM{change}) {
  $sql = "UPDATE variant SET  
   hourp='$hour_tarif',
   uplimit='$uplimit',
   name=\"$FORM{name}\",
   ut='$end',
   dt='$begin',
   abon='$month_pay',
   df='$day_pay',
   logins='$logins',
   day_time_limit='$day_time_limit', 
   week_time_limit='$week_time_limit',  
   month_time_limit='$month_time_limit', 
   day_traf_limit='$day_traf_limit',
   week_traf_limit='$week_traf_limit',
   month_traf_limit='$month_traf_limit',
   activate_price='$activate_price', 
   change_price='$change_price', 
   prepaid_trafic='$prepaid_trafic',
   vrnt='$FORM{vrnt}',
   credit_tresshold='$credit_tresshold'
  WHERE vrnt='$FORM{chg}';";

  $db ->do($sql) or die $db->errstr;
  
  if ($FORM{vrnt} ne $FORM{chg}) {
     $db ->do("UPDATE intervals SET
       vid='$FORM{vrnt}'
       WHERE vid='$FORM{chg}';") or die $db->errstr;
     message('info', "$_CHANGED", "$_INTERVALS");

     $db ->do("UPDATE trafic_tarifs SET
       vid='$FORM{vrnt}'
       WHERE vid='$FORM{chg}';") or die $db->errstr;
     message('info', "$_CHANGED", "$_TRAFIC_TARIFS");
     
     $db ->do("UPDATE vid_nas SET
       vid='$FORM{vrnt}'
       WHERE vid='$FORM{chg}';") or die $db->errstr;
     message('info', "$_CHANGED", "NAS SERVERS");

   }
  
  message('info', "$_CHANGED", "$_CHANGED # $FORM{vrnt}");
 }
elsif ($FORM{chg}) {
   $sql = "SELECT vrnt, hourp, abon, uplimit, name, df, ut, dt, logins, 
     day_time_limit, week_time_limit,  month_time_limit, day_traf_limit, week_traf_limit,  month_traf_limit,
     activate_price, change_price, prepaid_trafic, credit_tresshold
     FROM variant 
    WHERE vrnt='$FORM{chg}';";
  
   $q = $db->prepare($sql) || die $db->errstr;
   $q -> execute ();
   ($vrnt, $hour_tarif, $month_pay, $uplimit, $name, $day_pay, $end, $begin, $logins,
     $day_time_limit, $week_time_limit, $month_time_limit, $day_traf_limit, $week_traf_limit,  $month_traf_limit,
     $activate_price, $change_price, $prepaid_trafic, $credit_tresshold) = $q -> fetchrow();

   @action = ('change', "$_CHANGE");
   message('info', "$_CHANGING",  "#: [$FORM{chg}]<br>$_NAME: '$name'");
   print "<a href='$SELF?op=variants&intervals=$FORM{chg}'>$_INTERVALS</a> :: " if ($hour_tarif > 0);
   print "<a href='$SELF?op=trafic_tarifs&vid=$FORM{chg}'>$_TRAFIC_TARIFS</a> \n".
   ":: <a href='$PHP_SELF?op=users&vid=$FORM{chg}'>$_USERS</a>\n".
   ":: <a href='$PHP_SELF?op=allow_nass&vid=$FORM{chg}'>$_NASS</a>";
 }
elsif ($FORM{del}) {
   $db ->do("DELETE FROM variant WHERE vrnt='$FORM{del}';") or die $db->errstr;
   $db ->do("DELETE FROM intervals WHERE vid='$FORM{del}';") or die $db->errstr;
   message('info', "$_DELETED", "$_DELETED # '$FORM{del}'");
 }


print "<form action=$SELF METHOD=POST>
<input type=hidden name=op value=variants>
<input type=hidden name=chg value=$FORM{chg}>
<table>
  <tr><th>#</th><td><input type=text name=vrnt value='$vrnt'></td></tr>
  <tr><td>$_HOUR_TARIF (1 Hour):</td><td><input type=text name=hour_tarif value='$hour_tarif'></td></tr>
<!--  <tr><td>$_BYTE_TARIF (1 Mb):</td><td><input type=text name=traf_tarif value='$traf_tarif'></td></tr> -->
  <tr><td>$_UPLIMIT:</td><td><input type=text name=uplimit value='$uplimit'></td></tr>
  <tr><td>$_NAME:</td><td><input type=text name=name value='$name'></td></tr>
  <tr><td>$_BEGIN:</td><td><input type=text name=begin value='$begin'></td></tr>
  <tr><td>$_END:</td><td><input type=text name=end value='$end'></td></tr>
  <tr><td>$_DAY_FEE:</td><td><input type=text name=day_pay value='$day_pay'></td></tr>
  <tr><td>$_MONTH_FEE:</td><td><input type=text name=month_pay value='$month_pay'></td></tr>
  <tr><td>$_SIMULTANEOUSLY:</td><td><input type=text name=logins value='$logins'></td></tr>
  <tr><th colspan=2 bgcolor=$_BG0>$_TIME_LIMIT (sec)</th></tr> 
  <tr><td>$_DAY</td><td><input type=text name=day_time_limit value='$day_time_limit'></td></tr> 
  <tr><td>$_WEEK</td><td><input type=text name=week_time_limit value='$week_time_limit'></td></tr>
  <tr><td>$_MONTH</td><td><input type=text name=month_time_limit value='$month_time_limit'></td></tr>
  <tr><th colspan=2 bgcolor=$_BG0>$_TRAF_LIMIT (Mb)</th></tr> 
  <tr><td>$_DAY</td><td><input type=text name=day_traf_limit value='$day_traf_limit'></td></tr>
  <tr><td>$_WEEK</td><td><input type=text name=week_traf_limit value='$week_traf_limit'></td></tr>
  <tr><td>$_MONTH</td><td><input type=text name=month_traf_limit value='$month_traf_limit'></td></tr>
  <tr><th bgcolor=$_BG0 colspan=2>$_OTHER</th></tr>
  <tr><td>$_ACTIVATE:</td><td><input type=text name=activate_price value='$activate_price'></td></tr>
  <tr><td>$_CHANGE:</td><td><input type=text name=change_price value='$change_price'></td></tr>
  <tr><td>$_CREDIT_TRESSHOLD:</td><td><input type=text name=credit_tresshold value='$credit_tresshold'></td></tr>
<!--  <tr><td>$_PREPAID (Mb):</td><td><input type=text name=prepaid_trafic value='$prepaid_trafic'></td></tr> -->
</table>
<input type=submit name='$action[0]' value='$action[1]'>
</form>\n";


$sql = "SELECT vid, begin, end, tarif FROM intervals;";
$q = $db -> prepare ($sql)  || die $db->errstr;
  $q -> execute ();

while(my($vid, $begin, $end, $tarif) = $q -> fetchrow()) {
  $inc{$vid}++;
  $intevals{$vid}{$inc{$vid}}="$begin $end $tarif";
}



print "<TABLE width=90% cellspacing=0 cellpadding=0 border=0>
<tr><TD bgcolor=$_BG4>
<TABLE width=100% cellspacing=1 cellpadding=0 border=0>
<tr bgcolor=$_BG0><th>#</th><th>$_HOUR_TARIF</th><th>$_NAME</th><th>$_BEGIN</th><th>$_END</th>
<th>$_DAY_FEE</th><th>$_MONTH_FEE</th><th>$_SIMULTANEOUSLY</th><th>-</th><th>-</th><th>-</th></tr>\n";

 $sql = "SELECT v.vrnt, v.hourp, v.abon, if(tt.id=0, tt.price, 0), 
    v.name, v.df, v.ut, v.dt, v.logins, count(*)
    FROM variant v
    LEFT JOIN trafic_tarifs tt ON (tt.vid=v.vrnt)
    GROUP BY v.vrnt
    ORDER BY 1;";

  $q = $db -> prepare ($sql) || die $db->errstr;
  $q -> execute ();

while(my ($vid, $hour_tarif, $month_pay, $traf_tarif, $name, $day_pay, $end, $begin, $logins) = $q -> fetchrow()) {
   if ($FORM{chg} eq $vid) {
     $bg = $_BG0;
    }
   else {
     $bg = ($bg eq $_BG1) ? $_BG2 : $_BG1;
    }

   $int = ($hour_tarif > 0) ? "<a href='$SELF?op=variants&intervals=$vid'>$_INTERVALS</a>" : '-';
   
   print "<tr bgcolor=$bg><td><a href='$SELF?op=variants&chg=$vid'>$vid</a></td><td align=right>$hour_tarif</td>".
    "<td><a href='$SELF?op=variants&chg=$vid'>$name</a></td><td>$begin</td><td>$end</td><td align=right>$day_pay</td><td align=right>$month_pay</td><td align=right>$logins</td>".
    "<td><a href='$SELF?op=variants&del=$vid'>$_DEL</a></td><td>$int</td></td><td><a href='$SELF?op=trafic_tarifs&vid=$vid'>$_TRAFFIC</a></td></tr>\n";
       if (defined($intevals{$vid})) {
       	 print "<tr bgcolor=$_BG3><th colspan=4>$_INTERVALS</th><th colspan=2>$_FROM</th><th colspan=2>$_TO</td><th colspan=2>$_SUM</th><td>&nbsp;</td></tr>";
         $ints = \$intevals{$vid};
         foreach $line (keys %{$$ints}) {
       	  ($begin, $end, $tarif)=split(/ /, $intevals{$vid}{$line});
          print "<tr bgcolor=$bg><th colspan=4 align=right>$line</td><td colspan=2 align=right>$begin</td><td colspan=2 align=right>$end</td>".
            "<td colspan=2 align=right>$tarif</td><td></tr>\n";
          
          }
        }
    print "<tr><td colspan=11 bgcolor=000000 height=1 class=small></td></tr>\n";
 }
print "</table>
</td></tr></table>\n"; 
}



#*******************************************************************
# Create nets file
# create_tt_file($path, $file_name, $body)
#*******************************************************************
sub create_tt_file {
 my ($path, $file_name, $body) = @_;
 
 open(FILE, ">$path/$file_name") || die "Can't create file '$path/$file_name' $!\n";
   print FILE "$body";
 close(FILE);

message('info', $_INFO, "<b>Nets file created</b><br>$path/$file_name<pre>==============\n$body\n==============</pre>");
}

#*******************************************************************
# Trafic tarifs and networks
# trafic_tarifs()
#*******************************************************************
sub trafic_tarifs {

  print "<h3>$_TRAFIC_TARIFS</h3>\n";
  my %tarifs = ();
  my %netss = ();
  my %prepaid = ();
  my %speeds = ();

  $tarifs{in}{0} = $FORM{tarif_in0} || '0.00000';
  $tarifs{in}{1} = $FORM{tarif_in1} || '0.00000';
  $tarifs{in}{2} = $FORM{tarif_in2} || '0.00000';
  
  $tarifs{out}{0} = $FORM{tarif_out0} || '0.00000';
  $tarifs{out}{1} = $FORM{tarif_out1} || '0.00000';
  $tarifs{out}{2} = $FORM{tarif_out2} || '0.00000';
  
  $netss{0} = $FORM{nets0} || '0.0.0.0/0';
  $netss{1} = $FORM{nets1};
  $netss{2} = $FORM{nets2};
  
  $prepaid{0} = $FORM{prepaid0} || 0 ;
  $prepaid{1} = $FORM{prepaid1} || 0 ;

  $speeds{0} = $FORM{speed0} || 0;
  $speeds{1} = $FORM{speed1} || 0;
  $speeds{2} = $FORM{speed2} || 0;

  my @action = ('change', $_CHANGE);   


if(! $FORM{vid}) {
  message('err', $_ERROR, "$ERR_SELECT_VARIANT");
  return 0;	
}
elsif ($FORM{change}) {

 $sql = "REPLACE trafic_tarifs SET 
    id='0',
    descr='$FORM{describe0}', 
    in_price='$tarifs{in}{0}',
    out_price='$tarifs{out}{0}',
    nets='$netss{0}',
    prepaid='$prepaid{0}',
    speed='$speeds{0}',
    vid='$FORM{vid}';";
 $db ->do($sql) or die $db->errstr;

 
 $sql = "REPLACE INTO trafic_tarifs SET 
    id='1',
    descr='$FORM{describe1}', 
    in_price='$tarifs{in}{1}',
    out_price='$tarifs{out}{1}',
    nets='$netss{1}',
    prepaid='$prepaid{1}',
    speed='$speeds{1}',
    vid='$FORM{vid}';";

# print $sql;

 $db ->do($sql) or die $db->errstr;

 $sql = "REPLACE trafic_tarifs SET 
    id='2',
    descr='$FORM{describe2}', 
    nets='$netss{2}',
    prepaid='$prepaid{2}',
    speed='$speeds{2}',
    vid='$FORM{vid}';";
 $db ->do($sql) or die $db->errstr;
 my $body = "";

my @n = ();
$/ = chr(0x0d);
for(my $i=0; $i<3; $i++) {
  if ($netss{$i} ne '') {
     @n = split(/\n|;/, $netss{$i});
     foreach my $line (@n) {
       chomp($line);
       next if ($line eq "");
       $body .= "$line $i\n";
     }
   }
}

  create_tt_file("$conf{netsfilespath}", "$FORM{vid}.nets", "$body");
  message("info", "$_CHANGED", "$_CHANGED");
}

$q = $db -> prepare ("SELECT id, in_price, out_price, descr, prepaid, nets, speed
  FROM trafic_tarifs WHERE vid='$FORM{vid}';")  || die $db->errstr;
  $q -> execute ();

if ($q->rows > 0) {
  while(my($id, $tarif_in, $tarif_out, $describe, $prepaid, $nets, $speed) = $q -> fetchrow()) {
    $tarifs{in}{$id}=$tarif_in;
    $tarifs{out}{$id}=$tarif_out;
    $describes{$id}=$describe;
    $netss{$id}=$nets;
    $prepaid{$id}=$prepaid;
    $speeds{$id}=$speed;
  }
}


print "<form action=$SELF method=POST>
<input type=hidden name=op value='trafic_tarifs'>
<input type=hidden name=vid value='$FORM{vid}'>
$_VARIANT: [ <a href='$SELF?op=variants&chg=$FORM{vid}'>$FORM{vid}</a> ]
<table BORDER=0 CELLSPACING=1 CELLPADDING=0>
<tr bgcolor=$_BG0><th>#</th><th>$_BYTE_TARIF IN (1 Mb)</th><th>$_BYTE_TARIF OUT (1 Mb)</th><th>$_PREPAID (Mb)</th><th>$_SPEED (Kbits)</th><th>$_DESCRIBE</th><th>NETS</th></tr>
<tr><td bgcolor=$_BG0>0</td>
<td valign=top><input type=text name='tarif_in0' value='$tarifs{in}{0}'></td>
<td valign=top><input type=text name='tarif_out0' value='$tarifs{out}{0}'></td>
<td valign=top><input type=text name='prepaid0' value='$prepaid{0}'></td>
<td valign=top><input type=text name='speed0' value='$speeds{0}'></td>
<td valign=top><input type=text name='describe0' value='$describes{0}'></td>
<td><textarea cols=20 rows=4 name='nets0'>$netss{0}</textarea></td></tr>

<tr><td bgcolor=$_BG0>1</td>
<td valign=top><input type=text name='tarif_in1' value='$tarifs{in}{1}'></td>
<td valign=top><input type=text name='tarif_out1' value='$tarifs{out}{1}'></td>
<td valign=top><input type=text name='prepaid1' value='$prepaid{1}'></td>
<td valign=top><input type=text name='speed1' value='$speeds{1}'></td>
<td valign=top><input type=text name='describe1' value='$describes{1}'></td>
<td><textarea cols=20 rows=4 name='nets1'>$netss{1}</textarea></td></tr>

<tr><td bgcolor=$_BG0>2</td>
<td valign=top><!-- <input type=text name='tarif2' value='$tarifs{2}'> --></td>
<td valign=top><!-- <input type=text name='tarif2' value='$tarifs{2}'> --></td>
<td valign=top><!-- <input type=text name='prepaid2' value='$prepaid{2}'> --></td>
<td valign=top><input type=text name='speed2' value='$speeds{2}'></td>
<td valign=top><input type=text name='describe2' value='$describes{2}'></td>
<td><textarea cols=20 rows=4 name='nets2'>$netss{2}</textarea></td></tr>

</table>
<input type=submit name='$action[0]' value='$action[1]'>
</form>\n";


}




#***********************************************************
# bin2hex()
#***********************************************************
sub bin2hex ($) {
 my $bin = shift;
 my $hex = '';
 
 
 for my $c (unpack("H*",$bin)){
   $hex .= $c;
 }
 return $hex;
}



#*******************************************************************
# Time intervals
# intervals()
#*******************************************************************
sub intervals {

my $intervals = $FORM{intervals};
my $begin=$FORM{begin} || '00:00:00';
my $end=$FORM{end} || '24:00:00';
my $tarif=$FORM{tarif} || '0.00';
my $day=$FORM{day} || 0;

print "<h3>$_INTERVALS</h3>\n";


if ($FORM{add}) {
    $sql = "INSERT INTO intervals (vid, day, begin, end, tarif)
     values ('$intervals', '$day', '$begin', '$end', '$tarif');";
    
    $db->do($sql) || print $db->errstr;
    if ($db->err == 5) {
       message('err', "$_ERROR", "$_EXIST");
      }
    elsif($db->err > 0) {
       message('err', "$_ERROR", "$db->errstr");
      }
    else {
      message('info', "$_ADDED", "");
     }
}
elsif($FORM{del}) {
  my ($begin, $tarif)=split(/ /, $FORM{del});
  $db->do("DELETE FROM intervals WHERE vid='$intervals' and begin='$begin' and tarif='$tarif';") || print $db->errstr; 
  message('info', "$_DELETED", "$_DELETED # $begin, $tarif");
}

@DAY_NAMES = ("$_ALL", 'Mon', 'Tue', 'Wen', 'The', 'Fri', 'Sat', 'Sun', "$_HOLIDAYS");

my $i=0;
my $days = '';
foreach $line (@DAY_NAMES) {
  $days .= "<option value=$i";
  $days .= " selected" if ($day == $i);
  $days .= ">$line\n";
  $i++;
}

print << "[END]";
<form action=$SELF>
<input type=hidden name=op value=variants>
<input type=hidden name=intervals value='$intervals'>
 <TABLE width=400 cellspacing=1 cellpadding=0 border=0>
 <tr><td>$_VARIANT:</td><td>$intervals</td></tr>
 <tr><td>$_DAY:</td><td><select name=day>$days</select></td></tr>
 <tr><td>$_BEGIN:</td><td><input type=text name=begin value='$begin'></td></tr>
 <tr><td>$_END:</td><td><input type=text name=end value='$end'></td></tr>
 <tr><td>$_HOUR_TARIF<br>(0.00 / 0%):</td><td><input type=text name=tarif value='$tarif'></td></tr>
</table>

<input type=submit name=add value='$_ADD'>
</form>
[END]

my %intervals = ();

print "<TABLE width=640 cellspacing=0 cellpadding=0 border=0>
  <TR><TD bgcolor=$_BG4>
  <TABLE width=100% cellspacing=1 cellpadding=0 border=0>
  <tr bgcolor=$_BG0><th>#</th><th>$_DAYS</th><th>$_BEGIN</th><th>$_END</th><th>$_HOUR_TARIF</th><th>-</th><th>-</th></tr>\n";

  $sql = "SELECT vid, day, begin, end, tarif, TIME_TO_SEC(begin), TIME_TO_SEC(end)
    FROM intervals WHERE vid='$intervals';";
  $q = $db -> prepare ($sql) || die $db->errstr;
  $q -> execute ();

while(my($vid, $day, $begin, $end, $tarif, $begin_ut, $end_ut) = $q -> fetchrow()) {
  print "<tr bgcolor=$_BG1><td>$vid</td><td>$DAY_NAMES[$day]</td><td align=right>$begin</td>".
    "<td align=right>$end</td><td align=right>$tarif</td><td>&nbsp</td><td><a href='$SELF?op=variants&intervals=$intervals&del=$begin+$tarif'>$_DEL</a></td></tr>\n";
  $intervals{$day}{$begin_ut}=$end_ut;
}
print "</table>\n</td></tr></table>\n";


print "<hr><TABLE width=640 cellspacing=0 cellpadding=0 border=0>
  <TR><TD bgcolor=$_BG4>
  <TABLE width=100% cellspacing=1 cellpadding=0 border=0>
  <tr bgcolor=$_BG0><th width=64>$_DAYS</th>\n";

  for($i=0; $i<=23; $i++) {
     print "<th width=24>$i</th>";
  }
print "</tr>\n";


my $i=0;
my $tarif_day = 0;
my $div = 100 / 86400;

foreach my $line (@DAY_NAMES) {
  print "<tr bgcolor=$_BG1><td>$line</td><td valign=center colspan=24>";
  my $color = '000000';
  my $last_value = 0;

  if (defined($intervals{$i})) {
     $tarif_day = $i;
    }
  else {
     $tarif_day = 0;
   }
   my $width = 0;
   my $cur_int = $intervals{$tarif_day};
   print "<table width=100%><tr>\n";          
   while(my($int_begin, $int_end)=each %$cur_int) {
      if ($int_begin > $last_value) {
          $width = ($int_begin - $last_value) * $div;
      	  print "<td bgcolor=FFFFFF width=$width% height=5></td>";
        }
      $width = ($int_end -  $int_begin) * $div;
      print "<td bgcolor=$color width=$width% height=5></td>";
      $last_value =  $int_end;
    }
  print "</tr></table>\n";
  print "</td></tr>\n";
  $i++;
}
print "</table>\n</td></tr></table>\n";
}

sub action_log() {
 my $admin =  shift; # admin name
 my $type = shift;   # type of action (add del change)
 my $action = shift; # action 
 
 open(FILE, ">>$ACTION_LOG") || die "Can't opne file $!";
   print "$admin	$type	$action\n";
 close(FILE);
}

#*******************************************************************
# Send mail 
# send_mail__form()
#*******************************************************************
sub send_mail_form {
 my $subject = $FORM{subject};
 my $message = $FORM{message};
 my $email = '';
 print "<h3>$_SEND_MAIL</h3>\n";

 $q = $db -> prepare("SELECT email FROM users WHERE uid='$uid' and email<>'';")   || die $db->strerr;
 $q -> execute ();
 if ($q->rows() > 0) {
   ($email) = $q -> fetchrow();
  } 
 else {
   $email = "$login\@$conf{USERS_MAIL_DOMAIN}";
  }
 
if(defined($FORM{send})) {
   sendmail("$conf{ADMIN_MAIL}", "$email", "$subject", "$message", "$conf{MAIL_CHARSET}", "");
   print "<Table width=600>".
   "<tr><th colspan=2 bgcolor=$_BG0>$_SENDED</th></tr>".
   "<tr><td bgcolor=$_BG3>$_USER:</td><td>$login_link ($email)</td></tr>".
   "<tr><td bgcolor=$_BG3>$_SUBJECT:</td><td>$subject</td></tr>".
   "<tr><td colspan=2 bgcolor=$_BG2><pre>$message</pre></td></tr></table>\n";
  } 
 else {
  print << "[END]";
   <form action=$SELF METHOD=POST>
   <input type=hidden name=op value=sendmsg>
   <input type=hidden name=uid value='$uid'>
   <table>
   <tr><td>$_TO_USER:</td><td>$login_link ($email) </td></tr>
   <tr><td>$_SUBJECT:</td><td><input type=text name=subject value='$subject'></td></tr>
   <tr bgcolor=$_BG3><th colspan=2>$_MESSAGE</th></tr>
   <tr><th colspan=2><textarea name=message cols=50 rows=10></textarea></th></tr>
   <tr><th colspan=2><input type=submit name=send value='$_SEND_MAIL'></th></tr>
   </table>
   </FORM>
[END]
}

}




#*******************************************************************
# Admin authentification
# auth()
#*******************************************************************
sub auth {
print "Status: 401\r\n",
      "WWW-Authenticate: Basic realm=\"-Billing system\"\r\n",
      "Content-type: text/plain\r\n\r\n",
      "Authorization required!\r\n";

#print "<pre>";
# while(($k, $v)=each(%ENV)) {
#   print  "$k - $v<br>";
#  }
#print "</pre>teststststst";


$q = $db -> prepare("SELECT id, password   FROM admins WHERE id='$id' and password='$password';")   || die $db->strerr;
$q -> execute ();
my ($id, $password) = $q -> fetchrow();


	
}


#*******************************************************************
# last_logins()
#*******************************************************************
sub last_logins {

print "<h3>Last logins</h3>\n";

my $from_date = date_fld('from');
my $to_date = date_fld('to');
my $ip = $FORM{ip} || '0.0.0.0';
my $name=$FORM{name};
my $nas=$FORM{nas};
my $nas_port=$FORM{nas_port};
my $NAS_INFO = nas_params();

print << "[END]";
<form action=$SELF>
<input type=hidden name=op value=last>
<table border=0>
<tr><td>$_USER:</td><td><input type=text name=name value='$name'></td></tr>
<tr><td>IP:</td><td><input type=text name=ip value='$ip'></td></tr>
<tr><td>$_PERIOD:</td><td>
<table border=0  width=100%>
<tr><td>$_FROM:</td><td>$from_date</td></tr>
<tr><td>$_TO:</td><td>$to_date</td></tr>
</table>
</td></tr>
<tr><td>NAS:</td><td><select  name=nas>
<option value=''></options>
[END]

 my $names = $NAS_INFO->{name};
 my %NAS_IDS = reverse %$NAS_INFO;
 while(my($k, $v)=each(%$names)) {
     print "<option value=$k";
     print ' selected' if ($v == $nas);
     print ">$k:$v ($NAS_INFO->{nt}{$k}) $NAS_IDS{$k} \n";
   }

print << "[END]";
</select></td></tr>
<tr><td>NAS_PORT:</td><td><input type=text name=nas_port value='$nas_port'></td></tr>
</table>
<input type=submit name=search value='$_SEARCH'>
</form>
[END]

if ($FORM{search}) {
  $pgs = "search=y&fromd=$FORM{fromd}&fromm=$FORM{fromm}&fromy=$FORM{fromy}&tod=$FORM{tod}&tom=$FORM{tom}&toy=$FORM{toy}";
  $FORM{fromm}++;
  $FORM{tom}++;
  $FORM{fromm} = sprintf("%.2d", $FORM{fromm}++);
  $FORM{tom} = sprintf("%.2d", $FORM{tom}++);
  $WHERE .= "WHERE date_format(login, '%Y-%m-%d')>='$FORM{fromy}-$FORM{fromm}-$FORM{fromd}' and date_format(login, '%Y-%m-%d')<='$FORM{toy}-$FORM{tom}-$FORM{tod}'";

  if ($FORM{ip} ne '0.0.0.0') {
    $WHERE .= " and l.ip=INET_ATON('$FORM{ip}')";
    $pgs .= "&ip=$FORM{ip}";
   }

  if ($FORM{name} ne '') {
    $WHERE .= " and l.id='$FORM{name}'";
    $pgs .= "&name=$FORM{name}";
   }

  if ($FORM{nas}) {
    $WHERE .= " and l.nas_id='$FORM{nas}'";
    $pgs .= "&nas=$FORM{nas}";
   }

  if ($FORM{nas_port}) {
    $WHERE .= " and l.port_id='$FORM{nas_port}'";
    $pgs .= "&nas_port=$FORM{nas_port}";
   }
} elsif ($FORM{nas}) {
  $WHERE .= "WHERE l.nas_id='$FORM{nas}'";
  $pgs .= "&nas=$FORM{nas}";
  %NAS_IP = reverse %NAS_SERVERS;
  print "NAS: $NAS_IP{$FORM{nas}}<br>";  
}

 my %pages = pages('id', 'log l', "$WHERE", "op=last&$pgs", "$pg"); 
 print "$_TOTAL: $pages{count}<br>";
 
 $sql = "SELECT l.id, l.login, UNIX_TIMESTAMP(l.login), l.variant, 
    SEC_TO_TIME(l.duration), l.duration, 
    l.sent, l.recv, l.CID, l.nas_id, INET_NTOA(l.ip), l.sum, UNIX_TIMESTAMP(l.login), u.uid,
    l.acct_session_id, l.sent2, l.recv2
   FROM log l
   LEFT JOIN users u ON (u.id=l.id)
   $WHERE
   ORDER by l.login DESC LIMIT $pg, $max_recs;";
 
 log_print('LOG_SQL', "$sql");
 $q = $db -> prepare($sql)   || die $db->strerr;
 $q -> execute();
 
  my %time_intervals = ();

  print "<TABLE width=100% cellspacing=0 cellpadding=0 border=0>
         <TR><TD bgcolor=$_BG4>
         <TABLE width=100% cellspacing=1 cellpadding=0 border=0>
         <tr bgcolor=$_BG0><th>$_USER</td><th>$_LOGIN</td><th>$_DURATION</th><th>$_VARIANT</th><Th>$_SENT</Th><Th>$_RECV</th><th>CID</th><th>NAS</th><th>IP</th><th>$_SUM</th><th>-</th><th>-</th></tr>\n";

  my %ACCT_INFO = ();

  while(my($login, $session_start, $session_start_u, $variant, $duration, $duration_sec,  $sent, $recv, $CID, $nas_id, $ip,  
      $sum, $start, $uid, $sid, $sent2, $recv2) = $q -> fetchrow()) {
    
    
    $ACCT_INFO{INBYTE}  = $recv|| 0;
    $ACCT_INFO{OUTBYTE} = $sent || 0;
    $ACCT_INFO{INBYTE2}  = $recv2|| 0;
    $ACCT_INFO{OUTBYTE2} = $sent2 || 0;

    $sent = int2byte($sent);
    $recv = int2byte($recv);
    $s_end = $s_begin + $duration_sec;

    $rows=0;
    $s_sum=0;

    $bg = ($bg eq $_BG1) ? $_BG2 : $_BG1;
        $button = "<A href='$SELF?op=bm&del=log&login=$login&ltime=$session_start&sum=$sum&duration=$duration_sec'
        onclick=\"return confirmLink(this, '$_USER: $login | $_LOGIN: $start_session | $_SUM: $sum | $_DURATION: $duration')\">$_DEL</a>";

#    if ($rows > 1) {
#      $out_tr = "<tr bgcolor=$bg><td><a href='$SELF?op=users&uid=$uid'>$uid</a></td><td align=right rowspan=$rows>$ltime ($rows)</td><td align=right>$uduration</td><td rowspan=$rows align=right>$variant</td>
#        <TD align=right rowspan=$rows>$sent</TD><TD align=right rowspan=$rows>$recv</td><td>$phone</td><td rowspan=$rows>$nas</td><td>$ip</td><th align=right rowspan=$rows>$sum</th><td rowspan=$rows>$button</td></tr>\n";
#      for($i=2; $i<=$rows; $i++) {
#         $out_tr .= "<tr><td calspan=5>$s_intervals{$i} - $i</td></tr>\n";
#      	}
#     }
#    else {
     $out = ($rows > 1) ? "<a href='$SELF?op=show_int&b=$session_start_u&e=$s_end'>$session_start</a>" : "$session_start";
     print "<tr bgcolor=$bg><td><a href='$SELF?op=users&uid=$uid'>$login</td> <td align=right>";

#     $sss = "<pre>";
#        my ($ssum, $vid, $time_tarif, $trafic_tarif) = session_sum("$login", "$session_start_u", $duration_sec, \%ACCT_INFO);
#        $sss .= "$login, $session_start_u, $duration_sec / $ssum, $vid, $time_tarif, $trafic_tarif</pre>";
        
     print "$out</td><td align=right>$duration</td><td align=right>$variant</td>
        <TD align=right>$sent</TD><TD align=right>$recv</td><td>$CID</td><td>$NAS_INFO->{name}{$nas_id}</td><td>$ip</td><th align=right>
        $sss
        $sum</th><th>(<a href='$SELF?op=sdetail&sid=$sid&uid=$uid' title='Session detalization'>D</a>)</th><td>$button</td></tr>\n";
#      }

    print "$out_tr";

    }
  print "</table></td></tr></table>\n";

  print $pages{pages};
}

#*******************************************************************
# WHERE period
# base_state($where, $period);
#*******************************************************************
sub base_state  {
 my ($where,  $period) = @_;

 $login = get_login($uid);
 $sql = "SELECT SEC_TO_TIME(min(duration)), SEC_TO_TIME(max(duration)), SEC_TO_TIME(avg(duration)),
  min(sent), max(sent), avg(sent),
  min(recv), max(recv), avg(recv),
  min(recv+sent), max(recv+sent), avg(recv+sent)
 FROM log
 WHERE id='$login';";
 
 
 
 $q = $db->prepare($sql)   || die $db->errstr;
 $q ->execute();
 
 my ($min_dur, $max_dur, $avg_dur, $min_sent, $max_sent, $avg_sent,
 $min_recv, $max_recv, $avg_recv, $min_sum, $max_sum, $avg_sum) = $q->fetchrow();

$min_sent = int2byte($min_sent);
$max_sent = int2byte($max_sent);
$avg_sent = int2byte($avg_sent);
$min_recv = int2byte($min_recv);
$max_recv = int2byte($max_recv);
$avg_recv = int2byte($avg_recv);
$min_sum  = int2byte($min_sum);
$max_sum  = int2byte($max_sum);
$avg_sum  = int2byte($avg_sum);

print << "[END]"; 
<TABLE width=640 cellspacing=0 cellpadding=0 border=0>
<TR><TD bgcolor=$_BG4>
<TABLE width=100% cellspacing=1 cellpadding=0 border=0>
<tr bgcolor=$_BG0><th>-</td><th>$_MIN</th><th>$_MAX</th><th>$_AVG</th></tr>
<tr bgcolor=$_BG1><td>$_DURATION</td><td align=right>$min_dur</td><td align=right>$max_dur</td><td align=right>$avg_dur</td></tr>
<tr bgcolor=$_BG1><td>$_TRAFFIC $_RECV</td><td align=right>$min_sent</td><td align=right>$max_sent</td><td align=right>$avg_sent</td></tr>
<tr bgcolor=$_BG1><td>$_TRAFFIC $_SENT</td><td align=right>$min_recv</td><td align=right>$max_recv</td><td align=right>$avg_recv</td></tr>
<tr bgcolor=$_BG1><td>$_TRAFFIC $_SUM</td><td align=right>$min_sum</td><td align=right>$max_sum</td><td align=right>$avg_sum</td></tr>
</table>
</td></tr></table>
<p>
[END]
}


#********************************************************************
#
#********************************************************************
sub cor  {
if ($FORM{del}) {
print "Deleted<br>";
#$q = $db -> do("DELETE FROM log WHERE id='$FORM{del}' and login='$FORM{ltime}' and duration=$FORM{duration};") || die $db->strerr;
#$q = $db->do("UPDATE bill set sum=sum+$FORM{sum} WHERE id='$FORM{del}';") || die $db->strerr;
}

 print "<h3>Dublicats</h3><table width=100% border=1>
 <tr bgcolor=$_BG0><th>$_COUNT</th><th>$_USER</td><th>$_LOGIN</td><th>$_DURATION</th><th>$_VARIANT</th><Th>$_SENT</Th><Th>$_RECV</th><th>Minp</th><th>$_TRAFFIC</th><th>IP</th><th>$_SUM</th><th>-</th></tr>\n";

 $q = $db->prepare("SELECT count(*), id, max(login), UNIX_TIMESTAMP(login), variant, SEC_TO_TIME(duration), duration, sent, recv, minp, kb, INET_NTOA(ip), sum, login as l
     FROM log 
     GROUP by id,variant,ip,duration
     HAVING (count(*) > 1) and (l > '2003-10-17 00:00:00')
     ORDER by 1 DESC;")   || die $db->errstr;
 $q ->execute();
 # ,sent,recv 
  while(($count, $uid, $ltime, $s_begin, $variant, $duration, $uduration, $sent, $recv, $minp, $kb, $ip, $sum) = $q->fetchrow()) {
    $sent = int2byte($sent);
    $recv = int2byte($recv);

    $bg = ($bg eq $_BG1) ? $_BG2 : $_BG1;
    $button = "<A href='$SELF?op=cor&del=$uid&ltime=$ltime&sum=$sum&duration=$uduration'>$_DEL</a>";
      print "<tr bgcolor=$bg><th align=right>$count</th><td>$uid<td align=right>$ltime</td><td align=right>$duration</td><td>$variant</td>
          <TD align=right>$sent</TD><TD align=right>$recv</td><td>$minp</td><td>$kb</td><th>$ip</th><th align=right>$sum</th><td>$button</td></tr>\n";
    }
  print "</table>\n";

}


#*******************************************************************
# Session calculation
# session_calc()
#*******************************************************************
sub session_calc {
 my ($nas_ip_address, $nas_port_id, $acct_session_id) = @_;

  $sql = "SELECT  user_name, started, acct_session_time, 
     acct_input_octets,
     acct_output_octets,
     lupdated,
     ex_input_octets,
     ex_output_octets
    FROM calls 
      WHERE nas_ip_address=INET_ATON('$nas_ip_address')
      and nas_port_id='$nas_port_id' and acct_session_id='$acct_session_id';";

 log_print('LOG_SQL', "$sql");
 print $sql;
 $q = $db->prepare($sql)   || die $db->errstr;
 $q ->execute();
 
   my ($user_name, $started, $acct_session_time, 
     $acct_input_octets,
     $acct_output_octets,
     $lupdated,
     $ex_input_octets,
     $ex_output_octets) = $q->fetchrow();
 
 print "$user_name, $started, $acct_session_time, 
     $acct_input_octets,
     $acct_output_octets,
     $lupdated,
     $ex_input_octets,
     $ex_output_octets\n";
 
 my %ACCT_INFO = ();
 
 $ACCT_INFO{INBYTE}  = $acct_input_octets || 0;
 $ACCT_INFO{OUTBYTE} = $acct_output_octets || 0;
 $ACCT_INFO{INBYTE2}  = $ex_input_octets || 0;
 $ACCT_INFO{OUTBYTE2} = $ex_output_octets || 0;
 
# my ($sum, $vid, $time_tarif, $trafic_tarif) = session_sum("$user_name", $started, $acct_session_time, \%ACCT_INFO);

# print "($sum, $vid, $time_tarif, $trafic_tarif)\n";
 
}


#*******************************************************************
# Show online users
# sql_online()
#*******************************************************************
sub sql_online {
 print "<h3>". $_ONLINE ."</h3>\n";	
 my $year = strftime("%Y", localtime(time));
 
 my $NAS_INFO = nas_params();
 if ($FORM{ping}) {
    my $res = `ping -c 5 $FORM{ping}`;
    message('info', $_INFO,  "Ping  $FORM{ping}<br>Result:<br><pre>$res</pre>");
   }
 elsif ($FORM{hangup}) {
     my ($nas_ip_address, $nas_port_id, $acct_session_id) = split(/ /, $FORM{hangup}, 3);

     require "nas.pl";
     my $ret = hangup("$nas_ip_address", "$nas_port_id", "", "$acct_session_id");
     
     if ($ret == 0) {
        $msg = "<table width=100%>\n".
         "<tr><th colspan=2 align=left>$_HANGUPED</th></tr>".
         "<tr><td>$_NAS:</td><td>$nas_ip_address</td></tr>".
         "<tr><td>$_PORT:</td><td>$nas_port_id</td></tr>".
         "<tr><td>SESSION_ID:</td><td>$acct_session_id</td></tr>".
         "</table>\n";
         sleep 3;
      }
     elsif ($ret == 1) {
     	$msg = 'NOT supported yet';
      }
     message('info', $_INFO, "$msg");
   }
  elsif ($FORM{zap}) {
     ($nas_ip_address, $nas_port_id, $acct_session_id)=split(/ /, $FORM{zap}, 3);
     $sql = "UPDATE calls SET status=2 
       WHERE nas_ip_address=INET_ATON('$nas_ip_address')
       and nas_port_id='$nas_port_id' and acct_session_id='$acct_session_id';";

     log_print('LOG_SQL', "$sql");
     $q = $db->do($sql) || die $db->errstr;
     $message = "<table width=100%>\n".
     "<tr><th colspan=2 align=left>$_CLOSED</th></tr>".
     "<tr><td>$_NAS:</td><td>$nas_ip_address</td></tr>".
     "<tr><td>$_PORT:</td><td>$nas_port_id</td></tr>".
     "<tr><td>SESSION_ID:</td><td>$acct_session_id</td></tr>".
     "</table>\n";

     my $nas_id = $NAS_INFO->{"$nas_ip_address"};
     $sql = "SELECT id FROM log WHERE acct_session_id='$acct_session_id'
       and port_id='$nas_port_id' and nas_id='$nas_id';";

     log_print('LOG_SQL', "$sql");
     $q = $db->prepare($sql) || die $db->errstr;
     $q ->execute();
     if ($q->rows() < 1) {
        $message .= "<p align=center>[<a href='$SELF?op=sql_online&tolog=$acct_session_id&nas_ip_address=$nas_ip_address&nas_port_id=$nas_port_id'>add to log</a>]
           [<a href='$SELF?op=sql_online&del=y&tolog=$acct_session_id&nas_ip_address=$nas_ip_address&nas_port_id=$nas_port_id'>$_DEL</a>]</p>";
       }
     else {
     	my($sid)=$q->fetchrow();
        print "$sid \n";
        #my ($sum, $variant, $time_t, $traf_t) = session_sum("$RAD{USER_NAME}", $ACCT_INFO{LOGIN}, $ACCT_INFO{ACCT_SESSION_TIME}, \%ACCT_INFO);
       }

     message('info', $_INFO, $message);
   }
 elsif($FORM{tolog}) {
   $sql = "SELECT user_name, UNIX_TIMESTAMP(started), acct_session_time, 
   acct_input_octets,
   acct_output_octets,
   ex_input_octets,
   ex_output_octets,
   connect_term_reason,
   INET_NTOA(framed_ip_address),
   lupdated,
   nas_port_id,
   INET_NTOA(nas_ip_address),
      CID
      FROM calls 
      WHERE nas_ip_address=INET_ATON('$FORM{nas_ip_address}')
       and nas_port_id='$FORM{nas_port_id}' and acct_session_id='$FORM{tolog}';";


   log_print('LOG_SQL', "$sql");
   $q = $db->prepare($sql) || die $db->errstr;
   $q ->execute();
   if ($q -> rows() < 1) {
        message('err', $_ERROR, 'NO records');
       }
   else {
      if(! defined($FORM{del})) {
     	my $ACCT_INFO = ();
     	my($username, $started, $duration,  $input_octets, $output_octets,  
     	  $ex_input_octets, $ex_output_octets,  $connect_term_reason, $framed_ip_address, $lupdated,
  	  $nas_port_id, $nas_ip_address, $CID)=$q->fetchrow();


          $ACCT_INFO{INBYTE} = $input_octets || 0;
          $ACCT_INFO{OUTBYTE} = $output_octets || 0;
          $ACCT_INFO{INBYTE2} = $ex_input_octets || 0;
          $ACCT_INFO{OUTBYTE2} =  $ex_output_octets || 0;
          $ACCT_INFO{ACCT_SESSION_TIME}  = $lupdated - $started;
          
        my ($sum, $variant, $time_t, $traf_t) = session_sum("$username", $started, $ACCT_INFO{ACCT_SESSION_TIME}, \%ACCT_INFO);
        #print "$sum, $variant, $time_t, $traf_t // $login, $started, $duration,  $input_octets, $output_octets,  
     	# $ex_input_octets, $ex_output_octets,  $connect_term_reason, $framed_ip_address, $lupdated";

        log_print('LOG_SQL', "$sql");
        $nas_num = $NAS_INFO->{$nas_ip_address};
        $sql = "INSERT INTO log (id, login, variant, duration, sent, recv, minp, kb,  sum, nas_id, port_id, ".
          "ip, CID, sent2, recv2, acct_session_id) VALUES ('$username', FROM_UNIXTIME($started), ".
          "'$variant', '$RAD{ACCT_SESSION_TIME}', '$ACCT_INFO{OUTBYTE}', '$ACCT_INFO{INBYTE}', ".
          "'$time_t', '$traf_t', '$sum', '$nas_num', ".
          "'$nas_port_id', INET_ATON('$framed_ip_address'), '$CID', ".
          "'$ACCT_INFO{OUTBYTE2}', '$ACCT_INFO{INBYTE2}',  \"$FORM{tolog}\");";

        log_print('LOG_SQL', "$sql");
        $q = $db->do($sql) || die $db->errstr;
       }

     	$sql = "DELETE FROM calls WHERE nas_ip_address=INET_ATON('$FORM{nas_ip_address}')
            and nas_port_id='$FORM{nas_port_id}' and acct_session_id='$FORM{tolog}'";
        log_print('LOG_SQL', "$sql");
        $q = $db->do($sql) || die $db->errstr;
      }

    $message = 'added';
    message('info', $_INFO, $message);
  }
 $sql = "SELECT c.user_name, if(date_format(c.started, '%Y-%m-%d')=curdate(), date_format(c.started, '%H:%i:%s'), c.started),
 INET_NTOA(c.nas_ip_address),
 c.nas_port_id, c.acct_session_id, SEC_TO_TIME(UNIX_TIMESTAMP() - UNIX_TIMESTAMP(c.started)),
 c.acct_input_octets, c.acct_output_octets, c.ex_input_octets, c.ex_output_octets,
 INET_NTOA(c.framed_ip_address), c.status,
 u.fio, u.phone, u.variant, u.deposit, u.credit, u.speed, u.uid, c.CID, c.CONNECT_INFO
 FROM calls c
  LEFT JOIN users u ON u.id=user_name
 WHERE c.status=1 or c.status>=3
 ORDER BY c.nas_ip_address, c.nas_port_id;";

 log_print('LOG_SQL', "$sql");

 $q = $db->prepare($sql)   || die $db->errstr;
 $q ->execute();
 
 $total = $q->rows;
 my %dub_logins = ();
 my %dub_ports = ();
 
  while(my($user_name, $started, $nas_ip_address, $nas_port_id, $acct_session_id, $acct_session_time,
     $acct_input_octets, $acct_output_octets, $ex_input_octets, $ex_output_octets, $framed_ip_address, 
     $status,
     $fio, $phone, $variant, $deposit, $credit, $speed, $uid, $CID, $CONNECT_INFO) = $q->fetchrow()) {
     $acct_input_octets = int2byte($acct_input_octets);
     $acct_output_octets = int2byte($acct_output_octets);

    if (defined($dub_logins{"$user_name"})) {
      $bg='#FFFF00';
       }
    elsif (defined($dub_ports{$nas_ip_address}{$nas_port_id}) && $nas_port_id != 0) {
       $bg='#00FF40';
      }
    elsif ($status > 3) {
       $bg='#FF0000';
      }
    else {
      $bg = ($bg eq $_BG1) ? $_BG2 : $_BG1;
     }
    
     $dub_ports{$nas_ip_address}{$nas_port_id}=$user_name;
     $dub_logins{"$user_name"}++;

     $nas{$nas_ip_address} .= "<tr bgcolor=$bg><td><a href='$SELF?op=users&uid=$uid' ".
     "title='$_FIO: $fio\n$_PHONE: $phone\n$_VARIANT: $variant\n$_DEPOSIT: $deposit\n".
     "$_CREDIT: $credit\n$_SPEED: $speed\nSESSION_ID: $acct_session_id\nCID: $CID\nCONNECT_INFO: $CONNECT_INFO'>$user_name</a></td>
     <td>$fio</td>
     <td>$nas_port_id</td>
     <td>$framed_ip_address</td>
     <td>$acct_session_time</td><td>$acct_input_octets</td><td>$acct_output_octets</td>".
     "<!-- <td>$acct_session_id</td>-->";
    
      if ($conf{ex_trafic} eq 'yes') {
         $ex_input_octets = int2byte($ex_input_octets);
         $ex_output_octets = int2byte($ex_output_octets);
         $nas{$nas_ip_address} .= "<td>$ex_input_octets</td><td>$ex_output_octets</td>";
       }
    
     my $zap_button = "<a href='$SELF?op=sql_online&zap=$nas_ip_address+$nas_port_id+$acct_session_id' title='Radzap $user_name'>Z</a>";
     $nas{$nas_ip_address} .= "<th>(<a href='$SELF?op=sql_online&ping=$framed_ip_address' title='ping'>P</a>)</th>".
      "<th>($zap_button)</th>".
      "<th>(<a href='$SELF?op=sql_online&hangup=$nas_ip_address+$nas_port_id+$acct_session_id' title='hangup'>H</a>)</th></tr>\n";
     $users_count{$nas_ip_address}++ ; # = (defined($users{$nas_ip_address})) ? $users_count{$nas_ip_address}+1 : 1;
    }

print "$_TOTAL: $total<br>
 <TABLE width=95% cellspacing=0 cellpadding=0 border=0>
 <TR><TD bgcolor=$_BG4>
 <TABLE width=100% cellspacing=1 cellpadding=0 border=0>
 <tr bgcolor=$_BG0><th>$_LOGIN</th><th>$_FIO</th><th>PORT</th><th>IPs</th><th>$_DURATION</th><th width=50>IN</th><th width=50>OUT</th>";

     if ($conf{ex_trafic} eq 'yes') {
       print "<th>exIN</th><th>exOUT</th>";
       $colspan = 9;
       $align=7;
      }
    else {
       $colspan = 7;
       $align=5;
     }
print "<!-- <th>SID</th> --><th>-</th><th>-</th><th>-</th></tr>\n".
 "<COLGROUP width=20>
    <COL align=left span=2>
    <COL align=right span=$align>
    <COL align=center span=3>
  </COLGROUP>\n";

my $names = $NAS_INFO->{name};
my %NAS_IDS = reverse %$NAS_INFO;

while(($k, $v)=each %$names) {
   print  "<tr><th align=left class=small colspan=$colspan bgcolor=$_BG0>&nbsp; $k:$NAS_INFO->{name}{$k} / $NAS_IDS{$k} / $NAS_INFO->{nt}{$k} / $users_count{$NAS_IDS{$k}}</th></tr>\n".
       "$nas{$NAS_IDS{$k}}\n";
 }

 print "</table></td></tr></table>\n";

print << "[END]";
<table>
<tr><td bgcolor=#FF0000 width=16>&nbsp;</td><td>Suspicion session</td></tr>
<tr><td bgcolor=#00FF00 width=16>&nbsp;</td><td>Dublicate ports</td></tr>
<tr><td bgcolor=#FFFF00 width=16>&nbsp;</td><td>Simultaneously logins</td></tr>
</table> 
[END]

}

#*******************************************************************
# Internet card manager
# icards()
#*******************************************************************

sub icards {
print "<h3>$_ICARDS</h3>\n";

my $count = $FORM{count} || 0;
my $nominal =   $FORM{nominal} || 0;
my $prefix = $FORM{prefix} || 'A';
my $variant = $FORM{variant} || $_DEFAULT_VARIANT;
my $period = $FORM{period} || 0;
my $change = $FORM{change} || 0;

if ($FORM{add}) {
  my $cards = "<table border=1 width=100%>\n<tr bgcolor=$_BG0><th>ID</th><th>$_SUM</th><th>$_VARIANT</th><th>$_PASSWD</th></tr>";
  for (my $i=0; $i<=$count; $i++) {
    my $password = mk_unique_value(12);
    $sql = "INSERT INTO icards (prefix, nominal, variant, period, changes, password)
       VALUE ('$prefix', '$nominal', '$variant', '$period', '$change', '$password');";
    
    log_print('LOG_SQL', "$sql");
    if ($db->err == 1062) {
       message('err', "$_ERROR", "'$prefix.$id' $_EXIST");
     }
    elsif($db->err > 0) {
       message('err', "$_ERROR", $db->errstr . " - N:". $db->err);
     }
    else {    
       $cards .= "<tr><td>$prefix.$id</td><td>$nominal</td><td>$variant</td><td>$password</td></tr>";
     }
   }

   message('info', "$_INFO", "$_CREATED: $cards</table><hr>");
 }
elsif($FORM{block}){
   my($prefix, $id)=split(/\./, $FROM{del});
   $sql = "UPDATE icards set state=1 WHERE id='$id' and prefix='$prefix';";
   message('info', "$_INFO", "$_BLOKED: $FORM{del}");
}
elsif($FORM{unblock}){
   my($prefix, $id)=split(/\./, $FROM{del});
   $sql = "UPDATE icards set state=0 WHERE id='$id' and prefix='$prefix';";
   message('info', "$_INFO", "$_UNBLOKED: $FORM{del}");
}
elsif($FORM{del}){
   my($prefix, $id)=split(/\./, $FROM{del});
   $sql = "DELETE FROM icards WHERE id='$id' and prefix='$prefix';";
   message('info', "$_INFO", "$_DELETED: $FORM{del}");
}
elsif($FORM{search}){
	
}

print << "[END]";
<form action=$SELF>
<input type=hidden name=op value=icards>
<table>
<tr><td>$_COUNT:</td><td><input type=text name=count value='$count'></td></tr>
<tr><td>$_SUM:</td><td><input type=text name=nominal value='$nominal'></td></tr>
<tr><td>$_PREFIX:</td><td><input type=text name=prefix value='$prefix'></td></tr>
<tr><td>$_VARIANT:</td><td><select name=variant>
[END]


 $q = $db->prepare("SELECT vrnt, name  FROM variant;") || die $db->strerr;
 $q ->execute();

 while(($vid, $name) = $q -> fetchrow()) {
    print "<option value=$vid";
    print ' selected' if ($vid == $variant);
    print ">$name\n";
   }

print << "[END]";
</select></td></tr>
<tr><td>$_PERIOD ($_DAYS):</td><td><input type=text name=period value='$period'></td></tr>
<tr><td>$_CHANGE:</td><td><input type=text name=change value='$change'></td></tr>
</table>
<input type=submit name=add value="$_ADD">
</form>	
<hr>
[END]

print << "[END]";
<form action=$SELF>
<input type=hidden name=op value=icards>
<table>
<tr><th colspan=2>$_SEARCH</th></tr>
<tr><td>ID:</td><td><input type=text name=text></td></tr>
</table>
<input type=submit name=go value="$_SEARCH">
</form>
<table>
[END]

print "<TABLE width=99% cellspacing=0 cellpadding=0 border=0>
  <TR><TD bgcolor=$_BG4>
  <TABLE width=100% cellspacing=1 cellpadding=0 border=0>";

 my @caption = ("ID", "$_SUM", "$_VARIANT", "$_ACTIVATE", "$_STATE", "-", "-", "-");
 show_title($sort, $desc, "$pg", "$op", \@caption);

print "</table>\n</td></tr></table>\n";
}



#*******************************************************************
#
# test()
#*******************************************************************
sub test {

 print "test";	
 my %trafic = ();

 $trafic{OUTBYTE}=$FORM{sent} || 0;
 $trafic{INBYTE}=$FORM{recv} || 0;
 $trafic{OUTBYTE2}=$FORM{sent2} || 0;
 $trafic{INBYTE2}=$FORM{recv2} || 0;
 
 my $duration = $FORM{duration} || 0;
 my $login = $FORM{login} || time;
 
 #41ter
 
 $test="=%D1%80%D0%B5%D1%84%D0%B5%D1%80%D0%B0%D1%82 %D0%A3%D0%BA%D1%80%D0%B0%D1%97%D0%BD%D1%81%D1%8C%D0%BA%D0%B0 %D0%BB%D1%96%D1%82%D0%B5%D"; 
 $test="www.google.com.ru/search?q=%D0%B2%D0%B7%D0%BB%D0%BE%D0%BC cookies&ie=UTF-8&oe=UTF-8&hl=ru&btnG=%D0%9F%D0%BE%D0%B8%D1%81%D0%BA %D0%B2 Google&lr=";
 $test="hghltd.yandex.ru/yandbtm%3Furl%3Dhttp%3A//light.index.org.ua/cool.php%253Fpage%253D16%2526type%253Dvisit%2526u_sort%253Duptime%2526u_order%253Ddesc%26text%3D%25EF%25F0%25EE%25E4%25E0%25E6%25E0 %25E0%25E2%25F2%25EE %25EE%25E1%25FA%25FF%25E2%25EB%25E5%";
 $test =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
 $test =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
 print "$test";
 
if ($FORM{go}) {
  my($sum, $vid, $time_tarif, $traf_price) = session_sum("$uid", $login, $duration, \%trafic);
print << "[END]";
<table>
<tr><td>UID:</td><td>$uid</td></tr>
<tr><td>LOGIN:</td><td>$login</td></tr>
<tr><td>DURATION:</td><td>$duration</td></tr>
<tr><td>SENT:</td><td>$trafic{OUTBYTE}</td></tr>
<tr><td>RECV:</td><td>$trafic{INBYTE}</td></tr>
<tr><td>SENT2:</td><td>$trafic{OUTBYTE2}</td></tr>
<tr><td>RECV2:</td><td>$trafic{OUTBYTE2}</td></tr>
<tr><td>VARIANT:</td><td>$vid</td></tr>
<tr><td>SUM:</td><td>$sum</td></tr>
</table>
[END]
    
 }

print << "[END]";
<form action=$SELF>
<input type=hidden name=op value=test>
<table>
<tr><td>Uid:</td><td><input type=text name=uid value='$FORM{uid}'></td></tr>
<tr><td>Login:</td><td><input type=text name=login value='$login'></td></tr>
<tr><td>Duration:</td><td><input type=text name=duration  value='$duration'></td></tr>
<tr><td>Sent:</td><td><input type=text name=sent value='$FORM{sent}'></td></tr>
<tr><td>Recv:</td><td><input type=text name=recv value='$FORM{recv}'></td></tr>
<tr><td>Sent2:</td><td><input type=text name=sent2 value='$FORM{sent2}'></td></tr>
<tr><td>Recv2:</td><td><input type=text name=recv2 value='$FORM{recv2}'></td></tr>
</table>
<input type=submit name=go value=calculate>
</forM>
[END]

while(my($k, $v)=each %ENV) {
  print "$k - $v<br>\n";	
}
}


#*******************************************************************
# Rate of exchange
# exchange_rate()
#*******************************************************************

sub exchange_rate {
 print "<h3>$_EXCHANGE_RATE</h3>\n";
 my @action = ('add', "$_ADD");

 my $short_name = $FORM{short_name} || '-';
 my $money = $FORM{money} || '-';
 my $rate  = $FORM{rate} || '0.0000';



if ($FORM{add}) {
  $sql = "INSERT INTO exchange_rate (money, short_name, rate, changed) 
   values ('$money', '$short_name', '$rate', now());";

  $q  = $db->do($sql);
  
    if ($db->err == 1062) {
       message('err', "$_ERROR", "'$money', '$short_name' $_EXIST");
       return 0;
      }
    elsif($db->err > 0) {
       message('err', "$_ERROR", $db->errstr . " - N:". $db->err);
      }
    else {
      message('info', "$_ADDED", "$_ADDED");
     }
}
elsif ($FORM{change})  {
  $sql = "UPDATE exchange_rate SET
    money='$money', 
    short_name='$short_name', 
    rate='$rate',
    changed=now()
   WHERE short_name='$FORM{chg}';";
  $q  = $db->do($sql);
  message('info', "$_INFO", "$_CHANGED $FORM{chg}");
}
elsif ($FORM{chg})  {
  $sql = "SELECT money, short_name, rate FROM exchange_rate WHERE short_name='$FORM{chg}';";
  $q  = $db->prepare($sql);
  $q -> execute();
  ($money, $short_name, $rate)=$q->fetchrow();
  message('info', "$_INFO", "$_CHANGING '$FORM{chg}'");
  @action = ('change', "$_CHANGE");
}
elsif ($FORM{del})  {
  $sql = "DELETE FROM exchange_rate WHERE short_name='$FORM{del}';";
  $q  = $db->do($sql);
  message('info', "$_INFO", "$_DELETED $FORM{del}");
}


print << "[END]";
<form action=$SELF>
<input type=hidden name=op   value=er> 
<input type=hidden name=chg   value="$FORM{chg}"> 
<table>
<tr><td>$_MONEY:</td><td><input type=text name=money value='$money'></td></tr>
<tr><td>$_SHORT_NAME:</td><td><input type=text name=short_name value='$short_name'></td></tr>
<tr><td>$_EXCHANGE_RATE:</td><td><input type=text name=rate value='$rate'></td></tr>
</table>
<input type=submit name=$action[0] value='$action[1]'>
</form>
[END]

print "<TABLE width=640 cellspacing=0 cellpadding=0 border=0>
<tr><TD bgcolor=$_BG4>
<TABLE width=100% cellspacing=1 cellpadding=0 border=0>\n";

 @caption = ("#", "$_MONEY", "$_SHORT_NAME", "$_EXCHANGE_RATE (1 unit =)", "$_CHANGED", "-", "-");
 show_title($sort, $desc, "$pg", "$op", \@caption);

 print "<COLGROUP width=20>
    <COL align=left span=4>
  </COLGROUP>\n";


 $sql = "SELECT money, short_name, rate, changed FROM exchange_rate;";
 log_print('LOG_SQL', "$sql");
 $q = $db->prepare($sql)   || die $db->errstr;
 $q ->execute();

while(my($money, $short_name, $rate, $changed)=$q->fetchrow()) {
  $bg = ($bg eq $_BG1) ? $_BG2 : $_BG1;  	
  $button = "<A href='$SELF?op=er&del=$short_name'
        onclick=\"return confirmLink(this, '$money')\">$_DEL</a>";

  print "<tr bgcolor=$bg><td>&nbsp;</td><td>$money</td><td>$short_name</td><td>$rate</td>".
   "<td>$changed</td><td><a href='$SELF?op=er&chg=$short_name'>$_CHANGE</a></td><td>$button</td></tr>\n";
}

print "</table>\n</td></tr></table>\n";
}


#*******************************************************************
#
# holidays()
#*******************************************************************
sub holidays {
 print "<h3>$_HOLIDAYS</h3>\n"; 	

if ($FORM{add}) {
    my($add_month, $add_day)=split(/-/, $FORM{add});
    $add_month++;

    $sql = "INSERT INTO holidays (day)
       VALUES ('$add_month-$add_day');";
    
    $q = $db->do($sql);
    
    if ($db->err == 1062) {
       message('err', "$_ERROR", "$_EXIST");
      }
    elsif($db->err > 0) {
       message('err', "$_ERROR", $db->errstr . " - N:". $db->err);
      }
    else {
      $add_month--;
      message('info', $_INFO, "$_ADDED '$add_day $MONTHES[$add_month]'");
     }
	
}
elsif($FORM{del}) {
 $sql = "DELETE from holidays WHERE day='$FORM{del}';";
 $q = $db->do($sql);
 my($del_month, $del_day)=split(/-/, $FORM{del});
 $del_month--;
 message('info', $_INFO, "$_DELETED '$del_day $MONTHES[$del_month]'");
}

my $hollidays = ();


 $sql = "SELECT day, descr FROM holidays;";
 log_print('LOG_SQL', "$sql");
 $q = $db->prepare($sql)   || die $db->errstr;
 $q ->execute();

print "<TABLE width=400 cellspacing=0 cellpadding=0 border=0>
<tr><TD bgcolor=$_BG4>
<TABLE width=100% cellspacing=1 cellpadding=0 border=0>
<tr bgcolor=$_BG0><th>$_DAY</th><th>$_DESCRIBE</th><th>-</th></tr>\n";


while(my($date, $describe)=$q->fetchrow()) {
  my($smonth, $sday)=split(/-/, $date);
  $smonth--;
  $bg = ($bg eq $_BG1) ? $_BG2 : $_BG1;
  print "<tr bgcolor=$bg><td>$sday $MONTHES[$smonth]</td><td>$describe</td><td><a href='$SELF?op=holidays&del=$date'>$_DEL</a></td></tr>\n";
  $hollidays{$smonth}{$sday}='y';
}

print "</table>\n</td></tr></table>\n";

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

($sec,$min,$hour,$mday,$mon, $gyear,$gwday,$yday,$isdst) = gmtime($curtime);
#print  "($sec,$min,$hour,$mday,$mon,$gyear,$gwday,$yday,$isdst)<br>";

print "<p><TABLE width=400 cellspacing=0 cellpadding=0 border=0>
<tr><TD bgcolor=$_BG4>
<TABLE width=100% cellspacing=1 cellpadding=0 border=0>
<tr bgcolor=$_BG0><th><a href='$SELF?op=holidays&month=$p_month&year=$p_year'> << </a></th><th colspan=5>$MONTHES[$month] $year</th><th><a href='$SELF?op=holidays&month=$n_month&year=$n_year'> >> </a></th></tr>
<tr bgcolor=$_BG0><th>$WEEKDAYS[1]</th><th>$WEEKDAYS[2]</th><th>$WEEKDAYS[3]</th>
<th>$WEEKDAYS[4]</th><th>$WEEKDAYS[5]</th>
<th><font color=red>$WEEKDAYS[6]</font></th><th><font color=red>$WEEKDAYS[7]</font></th></tr>\n";



my $day = 1;
my $month_days = 31;
while($day < $month_days) {
  print "<tr bgcolor=$_BG1>";
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
       	  $bg = "bgcolor=$_BG2";
       	}

       if (defined($hollidays{$month}{$day})) {
         print "<th bgcolor=$_BG0>$day</th>";
        }
       else {
         print "<td align=right $bg><a href='$SELF?op=holidays&add=$month-$day'>$day</a></td>";
        }
       $day++;
      }
    }
  print "</tr>\n";
}


print "</table>\n</td></tr></table>\n";

}


#*******************************************************************
# Check admin permits get online users
# check_permits($admin);
#*******************************************************************
sub check_permits {
 my ($admin) = @_;
 
my $sql = "SELECT aid, name, permissions FROM admins WHERE id='$admin';";
$q = $db->prepare($sql) || die $db->errstr;
$q ->execute(); 
my ($aid, $name, $permit)= $q->fetchrow();

my @p = split(/, /, $permit);
  
my %permits = ();
foreach my $line (@p) {
  $permits{$line}='yes';
 }

if(! defined($permits{activ})) {
  return 0;
}

 my  %permissions = ('add' => "$_ADD", 
                     'change' => "$_CHANGING",
                     'del' => "$_DEL",
                     'activ' => "$_ACTIV",
                     'get' => "$_GET"
                     );

 while(my($key, $val)=each %permissions) {
     if (defined($FORM{$key}) && ! defined($permits{$key})) {
     	 return 0;
       }
   }

 return $aid;
}

#*******************************************************************
# 
# profile()
#*******************************************************************
sub profile {
 my ($admin) = @_;
 print "<h3>$_PROFILE</h3>\n";

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
<form action=$SELF>
<input type=hidden name=op value=profile>
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
$profiles{'мс'} = "#FCBB43, #FFFFFF, #eeeeee, #dddddd, #E1E1E1, #FFFFFF, #FFFFFF, #000088, #0000A0, #000000, #FFFFFF";
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

#*******************************************************************
# templates()
#*******************************************************************
sub templates () {
 print "<h3>$_TEMPLATES</h3>\n";	
	
}

#*******************************************************************
#
# allow_ip
#*******************************************************************
sub allow_ip {
	
	
 return 0;
}




































#*******************************************************************
# returns
# 1 variant changed
# 0 variant equal
# chg_uvariant($uid, $old_variant, $new_variant, $admin)
#*******************************************************************
sub chg_uvariant {
 my ($uid, $old_variant, $new_variant)=@_;

 if ($old_variant eq $new_variant) {
   return 0;
 } 

my $q = $db -> prepare("SELECT change_price FROM variant WHERE vrnt='$new_variant';") || die $db->strerr;
$q -> execute ();
my ($change_price) = $q -> fetchrow();

if ($change_price  > 0) {
  get_fees("$uid", "$change_price", "$_CHANGE $_VARIANT");
 }


my $changed = "$_VARIANT: $old_variant->$new_variant";
my $sql = "INSERT INTO userlog (log, date, ww, ip, uid, aid) 
   VALUES ('$changed', now(), '$admin_name', INET_ATON('$admin_ip'), '$uid', '$aid');";

log_print('LOG_SQL', "$sql");
$q = $db->do($sql) || die $db->strerr;
$sql = "UPDATE users SET variant='$new_variant' WHERE uid='$uid';";
log_print('LOG_SQL', "$sql");
$q = $db->do($sql) || die $db->strerr;

return 1;
}


#*******************************************************************
# fees manage
# fees()
# attributes
#     login
#     describe
#     id
#
#*******************************************************************
sub fees {
 my ($action, $uid, $sum, $attr) = @_;

 my $login = defined($attr->{login}) ? $attr->{login}: '';
 my $describe = defined($attr->{describe}) ? $attr->{describe}: '';

if($action eq 'get') {

  @f_message = ("$_USER_NOT_EXIST UID [$uid]");
 }
elsif($action eq 'del') {
  my $id = int($attr->{id});
  my $sql = "DELETE FROM fees WHERE id='$id';";
  my $q = $db->do($sql) || die $db->strerr;
}

 return 1;
}

#*******************************************************************
# get fees 
# get_fees($uid, $sum, $describe)
#*******************************************************************
sub get_fees {
 my ($uid, $sum, $describe, $attr) = @_;
 
 my $deposit = 0;
 my $login = defined($attr->{login}) ? $attr->{login}: '';
 
 if (! defined($attr->{deposit}) ) { 
   my $sql = "SELECT id, deposit FROM users WHERE uid='$uid';";
   log_print('LOG_SQL', "$sql");

   my $q = $db -> prepare($sql) || die $db->errstr;
   $q -> execute();

   if ($q->rows == 0) {
     @f_message = ("$_USER_NOT_EXIST UID [$uid]");
     return -1;
    }
   ($login, $deposit)=$q -> fetchrow();
  } 
 else {
   $deposut = $attr->{deposit};
  }


 $sql = "UPDATE users set deposit=deposit-$sum WHERE uid='$uid';";
 log_print('LOG_SQL', "$sql");
 $db -> do ($sql) || die $db->errstr;

 $sql = "INSERT INTO fees (uid, date, sum, dsc, ww, ip, last_deposit, aid)
   values ('$uid', NOW(), '$sum', '$describe', '$admin_name', INET_ATON('$admin_ip'), '$deposit', '$aid');";
 log_print('LOG_SQL', "$sql");
 $db -> do ($sql) || die $db->errstr;

 @f_message = ("$_USER: $login",
               "$_SUM: $sum",
               "$_DESCRIBE: $describe");


 return 1;
}



#*******************************************************************
# Shedule actions
# shedule
#*******************************************************************
sub shedule {
  my ($action, $attr) = @_;

 my $descr=(defined($attr->{descr})) ? $attr->{descr} : '';

if ($action eq 'add') {
  my $h=(defined($attr->{h})) ? $attr->{h} : '*';
  my $d=(defined($attr->{d})) ? $attr->{d} : '*';
  my $m=(defined($attr->{m})) ? $attr->{m} : '*';
  my $y=(defined($attr->{y})) ? $attr->{y} : '*';
  my $count=(defined($attr->{count})) ? int($attr->{count}): 0;
  my $uid=(defined($attr->{uid})) ? int($attr->{uid}) : 0;
  my $type=(defined($attr->{type})) ? $attr->{type} : '';
  my $action=(defined($attr->{action})) ? $attr->{action} : '';
  
  $sql = "INSERT INTO shedule (h, d, m, y, uid, type, action, aid, date) 
        VALUES ('$h', '$d', '$m', '$y', '$uid', '$type', '$action', '$aid', now());";
  log_print('LOG_SQL', "$sql");
  $q = $db->do($sql) || die $db->strerr;
  message('info', $_INFO, "$descr");
}
elsif($action eq 'del') {
  my $id = int($attr->{id});
  my $sql = "DELETE FROM shedule WHERE id='$id';";
  my $q = $db->do($sql) || die $db->strerr;
  message('info', $_INFO, "$_DELETED [$id]");	
}

return 0;
#$hour, $day, $month, $year, $count, $uid, $type, $action, $admin)=@_;
}

#*******************************************************************
# SQL commander
# sql_comd()
#*******************************************************************
sub sql_cmd {
 my $query = $FORM{query} || '';
 my $rows = $FORM{rows} || 0;
 print "<h3>SQL Commander</h3>\n";
 
print << "[END]";
<form action=$SELF METHOD=POST>
<input type=hidden name=op value=sql_cmd>
<table><tr><td>
<textarea name=query rows=5 cols=60>$query</textarea>
</td></tr>
<tr><td>$_ROWS: <input type=text name=rows value='$rows'></td></tr>
</table>
<input type=submit name=show value="$_SHOW">
</form>
[END]


if ($FORM{query}) {
 my $limit = "";

 if ($sort > 1 && $query !~ /ORDER/ig) {
   if ($query =~ /LIMIT/gi) {
     $query =~ s/LIMIT/ ORDER BY $sort $desc LIMIT/i;
    }   
   else {
     $query .= " ORDER BY $sort $desc";
    }
  }

 if ($query !~ /LIMIT/ig) {
   if ($rows > 0) {
     $query =~ s/;//g;
     $query .= " LIMIT $rows";
    }
   else {
     $query .= " LIMIT $max_recs";
    }
 }
 
 print "<Table width=640><tr bgcolor=$_BG3><td>
 $query</td></tr></table>\n";	

 $q = $db->prepare($query) || die $db->errstr;
 $q ->execute(); 
 print $_COUNT .": ". $q ->rows();
 print "<table width=99%>\n";
 show_title($sort, $desc, "$pg", "$op&query=$query", $q ->{NAME});

 while(my @query_fields = $q->fetchrow()) {
    $bg = ($bg eq $_BG1) ? $_BG2 : $_BG1;
    print "<tr bgcolor=$bg>";
    foreach my $field (@query_fields) {
      print "<td>$field</td>";
     }
    print "</tr>\n";
  }

 print "</table>\n";



}

}


#**********************************************************
# Not ended
#**********************************************************

sub not_ended {

print "<h3>No Ended</h3>\n";
print "<Table width=99%>\n";

 my $sql = "SELECT c.user_name, if(date_format(c.started, '%Y-%m-%d')=curdate(), date_format(c.started, '%H:%i:%s'), c.started),
 INET_NTOA(c.nas_ip_address),
 c.nas_port_id, c.acct_session_id, SEC_TO_TIME(UNIX_TIMESTAMP() - UNIX_TIMESTAMP(c.started)),
 c.acct_input_octets, c.acct_output_octets, c.ex_input_octets, c.ex_output_octets,
 INET_NTOA(c.framed_ip_address), c.status,
 u.fio, u.phone, u.variant, u.deposit, u.credit, u.speed, u.uid, c.CID, c.CONNECT_INFO
 FROM calls c
  LEFT JOIN users u ON u.id=user_name
 WHERE c.status=2
 ORDER BY c.nas_ip_address, c.nas_port_id;";
 log_print('LOG_SQL', "$sql");

 $q = $db->prepare($sql)   || die $db->errstr;
 $q ->execute();
 my $total = $q->rows;
 
  while(my($user_name, $started, $nas_ip_address, $nas_port_id, $acct_session_id, $acct_session_time,
     $acct_input_octets, $acct_output_octets, $ex_input_octets, $ex_output_octets, $framed_ip_address, 
     $status,
     $fio, $phone, $variant, $deposit, $credit, $speed, $uid, $CID, $CONNECT_INFO) = $q->fetchrow()) {

     $acct_input_octets = int2byte($acct_input_octets);
     $acct_output_octets = int2byte($acct_output_octets);
     $ex_input_octets = int2byte($ex_input_octets);
     $ex_output_octets = int2byte($ex_output_octets);

     $bg = ($bg eq $_BG1) ? $_BG2 : $_BG1;
     print "<tr bgcolor=$bg><td><a href='$SELF?op=users&uid=$uid' ".
     "title='$_FIO: $fio\n$_PHONE: $phone\n$_VARIANT: $variant\n$_DEPOSIT: $deposit\n".
     "$_CREDIT: $credit\n$_SPEED: $speed\nSESSION_ID: $acct_session_id\nCID: $CID\nCONNECT_INFO: $CONNECT_INFO'>$user_name</a></td>
     <td>$fio</td>
     <td>$nas_port_id</td>
     <td>$framed_ip_address</td>
     <td>$acct_session_time</td><td>$acct_input_octets</td><td>$acct_output_octets</td>
     <td>$ex_input_octets</td><td>$ex_output_octets</td>";
    
     my $zap_button = "<a href='$SELF?op=sql_online&zap=$nas_ip_address+$nas_port_id+$acct_session_id' title='Radzap $user_name'>Z</a>";
     print "<th>(<a href='$SELF?op=sql_online&ping=$framed_ip_address' title='ping'>P</a>)</th>".
      "<th>($zap_button)</th>".
      "<th>(<a href='$SELF?op=sql_online&hangup=$nas_ip_address+$nas_port_id+$acct_session_id' title='hangup'>H</a>)</th></tr>\n";
    }


print "</table>\n";
}
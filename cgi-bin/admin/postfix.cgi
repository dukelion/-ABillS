#!/usr/bin/perl
#
# POstfix admin interface 
# ~AsmodeuS~ 2005
#


use Abwconf;
my $db=$Abwconf::db;
print "Content-Type: text/html\n\n";
header();
print "<center>";
require "../../language/$language.pl";
my @scolors = ("#C0C0C0", "#00FF00", "#AAAAFF");

my %menu = ('1::', $_MAILBOXES,
         '2::aliases', $_ALIASES,
         '3::domains',  $_DOMAINS,
         '5::filters',  $_FILTERS,
         '6::access',  $_ACCESS,
         '7::transport',  $_TRANSPORT,
         '8::forward', _FORWARD, 
         '9:users.cgi:',  $_BILLING,
        );
show_menu(0, 'op', "", \%menu);


if ($op eq 'aliases')    {  aliases();    }
elsif($op eq 'domains')  {  domains();    }
elsif($op eq 'filters')  {  filters();    }
elsif($op eq 'access')   {  access();     }
elsif($op eq 'transport'){  transport();  }
else { mboxes(); }




#*******************************************************************
# access()
#*******************************************************************
sub access {
 print "<h3>$_ACCESS</h3>\n";
 my $pattern = $FORM{pattern} || '';
 my $maction = $FORM{maction} || 0;
 my $code = $FORM{code} || '';
 my $message = $FORM{message} || '';
 my @access_actions = (OK, REJECT, DISCARD, ERROR);
 my $faction = '';

  if ($maction == 3) {
  	 $faction = "$access_actions[$maction]:$code $message";
    }
  else {
  	 $faction = $access_actions[$maction];
    }


@action = ('add', $_ADD);
if ($FORM{add}) {

  $sql = "INSERT INTO mail_access (pattern, action)
           VALUES ('$pattern', '$faction');";

  $q = $db->do($sql);

  if ($db->err == 1062) {
    message('err', "$_ERROR", "'$pattern' $_EXIST");
   }
  elsif($db->err > 0) {
    message('err', "$_ERROR", $db->errstr . " - N:". $db->err);
   }
  else {
    message('info', $_INFO, $_ADDED);
  }

}	
elsif($FORM{change}) {
  $sql = "UPDATE mail_access SET 
     pattern='$pattern', 
     action='$faction' 
    WHERE id='$FORM{chg}';";
  $q = $db->do($sql);

  message('info', $_INFO, $_CHANGED);
}
elsif($FORM{chg}){
  $sql = "SELECT pattern, action FROM mail_access WHERE id=$FORM{chg};";
  $q = $db -> prepare($sql) || die $db->strerr;
  $q -> execute();

  ($pattern, $faction) = $q -> fetchrow();

  ($faction, $code, $message)=split(/:| /, $faction, 3);

  print "$faction, $code, $message-";

  message('info', $_INFO, $_CHANGING);
  @action = ('change', $_CHANGE);
}
elsif($FORM{del}){
  $sql = "DELETE FROM mail_access WHERE id='$FORM{del}';";
  $q = $db->do($sql);
  message('info', $_INFO, $_DELETED);
}


print << "[END]";
<form action=$SELF>
<input type=hidden name=op value=access>
<input type=hidden name=chg value=$FORM{chg}>
<table>
<tr><td>$_VALUE:</td><td><input type=text name=pattern value='$pattern'></td></tr>
<tr><td>$_PARAMS:</td><td>
[END]

my $i=0;
foreach my $t (@access_actions) {
 print "<br><input type=radio name=maction value=$i";
 print " checked" if ($t eq $faction);
 print "> $t\n";	
 $i++;
}



print << "[END]";
$_ERROR:<input type=text name=code value="$code" size=4> $_MESSAGE:<input type=text name=message value="$message"></td></tr>
</table>
<input type=submit name=$action[0] value="$action[1]">
</form>
[END]



$sql = "SELECT pattern, action, id FROM mail_access  ORDER BY $sort $desc;";

my $q = $db->prepare("$sql");
$q->execute();
my $total = $q->rows;

print "<p>$_TOTAL: $total<br>
<TABLE width=49% cellspacing=0 cellpadding=0 border=0><TR><TD bgcolor=$_BG4>
<TABLE width=100% cellspacing=1 cellpadding=0 border=0>
  <COLGROUP>
    <COL align=left span=2>
    <COL align=center span=2>
  </COLGROUP>\n";

 my @caption = ("$_VALUE", "$_PARAMS", "-", "-");
 show_title($sort, $desc, "$pg", "$op&$qs", \@caption);

while(($pattern, $action, $id) = $q->fetchrow_array()) {
  $bg = ($bg eq $_BG1) ? $_BG2 : $_BG1;
  my $del_button = "<A href='$SELF?op=access&del=$id'
        onclick=\"return confirmLink(this, '$_DELETE \\'$pattern $action\\' ?')\">$_DEL</a>";
  print "<tr bgcolor=$bg><td>$pattern</td><td>$action</td><td><a href='$SELF?op=access&chg=$id'>$_CHANGE</a></td><td>$del_button</td></tr>\n";
}

print "</table>
</td></tr></table>
</p>\n";




 
}



#*******************************************************************
# transport()
#*******************************************************************
sub transport {
 my $domain = $FORM{domain} || '';
 my $transport = $FORM{transport} || '';
 
 print "<h3>$_TRANSPORT</h3>\n";

@action = ('add', $_ADD);
if ($FORM{add}) {
  $sql = "INSERT INTO mail_transport (domain, transport) 
   VALUE ('$domain', '$transport');";
  $q = $db->do($sql);

  if ($db->err == 1062) {
    message('err', "$_ERROR", "'$domain' $_EXIST");
   }
  elsif($db->err > 0) {
    message('err', "$_ERROR", $db->errstr . " - N:". $db->err);
   }
  else {
    message('info', $_INFO, $_ADDED);
   }

}	
elsif($FORM{change}) {
  $sql = "UPDATE mail_transport SET
   domain='$domain',
   transport='$transport'
  WHERE domain='$FORM{chg}';";
  $q = $db->do($sql);
  message('info', $_INFO, $_CHANGED);
}
elsif($FORM{chg}){
  $sql = "SELECT domain, transport FROM mail_transport WHERE domain='$FORM{chg}';";
  my $q = $db->prepare("$sql") || die $db->errstr;
  $q -> execute();
  my($domain, $transport) = $q -> fetchrow();
  message('info', $_INFO, $_CHANGING);
  @action = ('change', $_CHANGE);
}
elsif($FORM{del}){
  $sql = "DELETE FROM mail_transport WHERE domain='$FORM{domain}'";
  $q = $db->do($sql);
  message('info', $_INFO, $_DELETED);
}

print << "[END]";
<form action=$SELF>
<input type=hidden name=op value=transport>
<input type=hidden name=chg value=$FORM{chg}>
<table><tr><td>$_DOMAIN:</td><td>
[END]

domains_select();

print << "[END]";
<tr><td>$_TRANSPORT:</td><td><input type=text name= value='transport'></td></tr>
</table>
<input type=submit name=$action[0] value="$action[1]">
</form>
[END]

$sql = "SELECT domain, transport
        FROM mail_transport
        ORDER BY $sort $desc;";
my $q = $db->prepare("$sql");
$q->execute();
my $total = $q->rows;


print "<p>$_TOTAL: $total<br>
<TABLE width=640 cellspacing=0 cellpadding=0 border=0><TR><TD bgcolor=$_BG4>
<TABLE width=100% cellspacing=1 cellpadding=0 border=0>\n";
 my @caption = ("$_DOMAINS", "$_TRANSPORT",  "-", "-");
 show_title($sort, $desc, "$pg", "$op&$qs", \@caption);

while(($domain, $transport) = $q->fetchrow_array()) {
  $bg = ($bg eq $_BG1) ? $_BG2 : $_BG1;
  my $del_button = "<A href='$SELF?op=transport&del=$id'
        onclick=\"return confirmLink(this, '$_DELETE \\'$domain -> $tarnsport\\' ?')\">$_DEL</a>";
  print "<tr bgcolor=$bg><td>$domain</td><td>$transport</td><td><a href='$SELF?op=transport&chg=$id'>$_CHANGE</a></td><td>$del_button</td></tr>\n";
}

print "</table>
</td></tr></table>
</p>\n";


	
}

#*******************************************************************
# domains()
#*******************************************************************
sub domains {
my $domain = $FORM{domain} || ''; 
my $descr = $FORM{descr} || ''; 
my $status = $FORM{status} || 0;

print "<h3>$_DOMAINS</h3>\n";

@action = ('add', $_ADD);
if ($FORM{add}) {

  $sql = "INSERT INTO mail_domains (domain, descr, create_date, change_date, status)
           VALUES ('$domain', '$descr', now(), now(), '$status');";

  $q = $db->do($sql);

  if ($db->err == 1062) {
    message('err', "$_ERROR", "'$name' $_EXIST");
    return 0;
   }
  elsif($db->err > 0) {
    message('err', "$_ERROR", $db->errstr . " - N:". $db->err);
   }
  else {
    message('info', $_INFO, $_ADDED);
  }

}	
elsif($FORM{change}) {
  $sql = "UPDATE mail_domains SET 
     domain='$domain', 
     descr='$descr', 
     change_date=now(), 
     status='$status')
    WHERE id='$FORM{chg}';";

  $q = $db->do($sql);

 message('info', $_INFO, $_CHANGED);
}
elsif($FORM{chg}){
  $sql = "SELECT domain, descr, status FROM mail_domains WHERE id=$FORM{chg};";
  $q = $db -> prepare($sql) || die $db->strerr;
  $q -> execute();

  ($domain, $descr, $status) = $q -> fetchrow();

  message('info', $_INFO, $_CHANGING);
  @action = ('change', $_CHANGE);
}
elsif($FORM{del}){

  message('info', $_INFO, $_DELETED);
}


print << "[END]";
<form action=$SELF>
<input type=hidden name=op value=domains>
<input type=hidden name=chg value=$FORM{chg}>
<table>
<tr><td>$_DOMAIN:</td><td><input type=text name=domain value='$domain'></td></tr>
<tr><td>$_STATE:</td><td><select name=status>
[END]

my $i=0;
foreach my $t (@status_types) {
 print "<option value=$i";
 print " selected" if ($i == $status);
 print ">$t\n";	
 $i++;
}

print << "[END]";
</select></td></tr>
<tr><th colspan=2>$_DESCRIBE:</th><tr>
<tr><th colspan=2><textarea name=descr cols=40 rows=5>$descr</textarea></th><tr>
</table>
<input type=submit name=$action[0] value="$action[1]">
</form>
[END]



$sql = "SELECT domain, descr, status, create_date, change_date, id
        FROM mail_domains
        ORDER BY $sort $desc;";


my $q = $db->prepare("$sql");
$q->execute();
my $total = $q->rows;

print "<p>$_TOTAL: $total<br>
<TABLE width=98% cellspacing=0 cellpadding=0 border=0><TR><TD bgcolor=$_BG4>
<TABLE width=100% cellspacing=1 cellpadding=0 border=0>
  <COLGROUP>
    <COL align=left span=2>
    <COL align=center span=1>
    <COL align=right span=2>
    <COL align=center span=2>
  </COLGROUP>\n";

 my @caption = ("$_DOMAINS", "$_DESCRIBE", "$_STATUS", "$_REGISTRATION", "$_CHANGED",  "-", "-");
 show_title($sort, $desc, "$pg", "$op&$qs", \@caption);

while(($domain, $descr, $status, $create_date, $change_date, $id) = $q->fetchrow_array()) {
  $bg = ($bg eq $_BG1) ? $_BG2 : $_BG1;
  my $del_button = "<A href='$SELF?op=domains&del=$id'
        onclick=\"return confirmLink(this, '$_DELETE \\'$domain\\' ?')\">$_DEL</a>";
  print "<tr bgcolor=$bg><td>$domain</td><td>$descr</td><td bgcolor=$scolors[$status]>$status_types[$status]</td>".
   "<td>$create_date</td><td>$change_date</td><td><a href='$SELF?op=domains&chg=$id'>$_CHANGE</a></td><td>$del_button</td></tr>\n";
}

print "</table>
</td></tr></table>
</p>\n";
}


#*******************************************************************
# select_domains
#*******************************************************************
sub domains_select {
 my $selected = shift;

my $sql = "SELECT domain FROM mail_domains  ORDER BY $sort $desc;";

my $q = $db->prepare("$sql");
$q->execute();
print "<select name=domain>\n<option value=''>\n";
while(($domain) = $q->fetchrow_array()) {
  print "<option value='\@$domain'";
  print ' selected' if ($selected eq '@' . $domain);
  print ">$domain\n";
}

print "</select>\n";
}

#*******************************************************************
# aliases
#*******************************************************************
sub aliases {
my $address=$FORM{address} || '';
my $goto=$FORM{goto} || '';  
my $status=$FORM{status} || 0;

print "<h3>$_ALIASES</h3>\n";

@action = ('add', $_ADD);
if ($FORM{add}) {

  $sql = "INSERT INTO mail_aliases (address, goto,  create_date, change_date, status)
   VALUES ('$address', '$goto', now(), now(), '$status');";

 $q = $db->do($sql);

 if ($db->err == 1062) {
   message('err', "$_ERROR", "'$name' $_EXIST");
   return 0;
  }
 elsif($db->err > 0) {
   message('err', "$_ERROR", $db->errstr . " - N:". $db->err);
  }
 else {
    message('info', $_INFO, $_ADDED);
  }

}	
elsif($FORM{change}) {
  $sql = "UPDATE mail_aliases SET 
   address='$address', 
   goto='$goto',  
   change_date=now(), 
   status='$status'
   WHERE id='$FORM{chg}';";

print $sql;

  $q = $db->do($sql);
  message('info', $_INFO, $_CHANGED);
}
elsif($FORM{chg}){
  $sql="SELECT address, goto, status FROM mail_aliases
     WHERE id='$FORM{chg}';";
 
  $q = $db -> prepare($sql) || die $db->errstr;
  $q -> execute();

  ($address, $goto, $status) = $q -> fetchrow();

  message('info', $_INFO, $_CHANGING);
  @action = ('change', $_CHANGE);
}
elsif($FORM{del}){
  $sql = "DELETE FROM mail_aliases  WHERE id='$FORM{del}';";
  $q = $db->do($sql);
  message('info', $_INFO, $_DELETED);
}

print << "[END]";
<form action=$SELF>
<input type=hidden name=op value=aliases>
<input type=hidden name=chg value='$FORM{chg}'>
<table>
<tr><td>$_ADDRESS:</td><td><input type=text name=address value='$address'></td></tr>
<tr><td>GOTO:</td><td><input type=text name=goto value='$goto'></td></tr>
<tr><td>$_STATE:</td><td><select name=state>
[END]

my $i=0;
foreach my $t (@status_types) {
 print "<option value=$i";
 print " selected" if ($i == $status);
 print ">$t\n";	
 $i++;
}

print << "[END]";
</select>
</td></tr>
</table>
<input type=submit name=$action[0] value="$action[1]">
</form>
[END]


$sql = "SELECT address, goto, status, create_date, change_date, id FROM mail_aliases
        ORDER BY $sort $desc;";

my $q = $db->prepare("$sql");
$q->execute();
my $total = $q->rows;


print "<p>$_TOTAL: $total<br>
<TABLE width=98% cellspacing=0 cellpadding=0 border=0><TR><TD bgcolor=$_BG4>
<TABLE width=100% cellspacing=1 cellpadding=0 border=0>
  <COLGROUP>
    <COL align=left span=2>
    <COL align=center span=1>
    <COL align=right span=2>
    <COL align=center span=2>
  </COLGROUP>\n";


 my @caption = ("$_ADDRESS", "GOTO", "$_STATUS", "$_REGISTRATION", "$_CHANGED", "-", "-");
 show_title($sort, $desc, "$pg", "$op&$qs", \@caption);

while(($address, $goto, $status, $create_date, $change_date, $id) = $q->fetchrow_array()) {
  $bg = ($bg eq $_BG1) ? $_BG2 : $_BG1;
  my $del_button = "<A href='$SELF?op=aliases&del=$id'
        onclick=\"return confirmLink(this, '$_DELETE \\'$address -> $goto\\'?')\">$_DEL</a>";
  print "<tr bgcolor=$bg><td>$address</td><td>$goto</td><td bgcolor=$scolors[$status]>$status_types[$status]</td>".
   "<td>$create_date</td><td>$change_date</td><td><a href='$SELF?op=aliases&chg=$id'>$_CHANGE</a></td><td>$del_button</td></tr>\n";
}

print "</table>
</td></tr></table>
</p>\n";
}

#*******************************************************************
# mailboxes
#*******************************************************************
sub mboxes {
my $username = $FORM{username} || '';
my $domain = $FORM{domain} || ''; 
my $password = $FORM{password} || ''; 
my $descr = $FORM{descr} || ''; 
my $maildir = $FORM{maildir} || ''; 
my $mails_limit = $FORM{mails_limit} || 0;
my $box_size = $FORM{box_size} || 0;
my $status = $FORM{status} || 0; 
my $bill_id = $FORM{bill_id} || 0;
my $antivirus = $FORM{antivirus} || 0;
my $antispam = $FORM{antispam} || 0;
my $expire = $FORM{expire} || '0000-00-00';

print "<h3>". $_MAILBOXES . "</h3>\n";


@action = ('add', $_ADD);
if ($FORM{add}) {
 $sql = "INSERT INTO mail_boxes 
    (username,  descr, maildir, create_date, change_date, quota, status, bill_id, antivirus, antispam) values
    ('$username',  '$descr', '$maildir', now(), now(), '$mails_limit". "C,$box_size". "S', '$status', '$bill_id', '$antivirus', '$antispam');";

 $q = $db->do($sql);
 
 if ($db->err == 1062) {
   message('err', "$_ERROR", "'$username' $_EXIST");
  }
 elsif($db->err > 0) {
   message('err', "$_ERROR", $db->errstr . " - N:". $db->err);
  }
 else {
    message('info', $_INFO, $_ADDED);
  }

}	
elsif($FORM{change}) {
 $sql = "UPDATE mail_boxes SET
    username='$username',  
    domain='$domain',
    descr='$descr', 
    maildir='$maildir', 
    change_date=now(), 
    quota='$mails_limit". "C,$box_size". "S',
    status='$status', 
    antivirus='$antivirus', 
    antispam='$antispam'
   WHERE id='$FORM{chg}';";
 $q = $db->do($sql);



print $sql;

 message('info', $_INFO, $_CHANGED);
}
elsif($FORM{chg}){
  $sql="SELECT username,  domain, descr, maildir, create_date, change_date, quota, status, bill_id,
   antivirus, antispam
   FROM mail_boxes WHERE id='$FORM{chg}';";

  $q = $db -> prepare($sql) || die $db->errstr;
  $q -> execute();

  ($username, $domain, $descr, $maildir, $create_date, $change_date, $quota, $status, $bill_id, 
    $antivirus, $antispam)=$q->fetchrow();

  $quota =~ s/C|S//g;
  ($mails_limit, $box_size) = split(/,/, $quota);
  message('info', $_INFO, $_CHANGING);
  @action = ('change', $_CHANGE);
}
elsif($FORM{del}){
  $sql="DELETE FROM mail_boxes WHERE id='$FORM{del}';";
  $q = $db->do($sql) || die $db->errstr;
  message('info', $_INFO, "$_DELETED [$id]");
}

my $antivirus_check = ($antivirus == 1) ? 'checked' : '';
my $antispam_check = ($antispam == 1) ? 'checked' : '';

print << "[END]";
<form action=$SELF>
<input type=hidden name=op value=mailboxes>
<input type=hidden name=chg value=$FORM{chg}>
<table>
<tr><td>Email:</td><td><input type=text name=username value='$username'> <b>@</b> 
[END]
domains_select("$domain");
print << "[END]";
</td></tr>
<tr><td>$_DESCRIBE:</td><td><input type=text name=descr value='$descr'></td></tr>
<tr><td>E-mail $_FOLDER:</td><td><input type=text name=maildir value='$maildir'></td></tr>
<tr><td>$_LIMIT:</td><td>$_COUNT: <input type=text name=mails_limit value='$mails_limit' size=7> $_SIZE: <input type=text name=box_size size=7 value='$box_size'></td></tr>
<tr><td>$_ANTIVIRUS:</td><td><input type=checkbox name=antivirus value='1' $antivirus_check></td></tr>
<tr><td>$_ANTISPAM:</td><td><input type=checkbox name=antispam value='1' $antispam_check></td></tr>
<tr><td>$_STATE:</td><td><select name=status>
[END]

my $i=0;
foreach my $t (@status_types) {
 print "<option value=$i";
 print " selected" if ($i == $status);
 print ">$t\n";	
 $i++;
}

print << "[END]";
</select>
</td></tr>
<tr><td>$_EXPIRE</td><td><input type=text name=expire value='$expire'></td></tr>
<tr><td>$_REGISTRATION:</td><td>$registartion</td></tr>
<tr><td>$_CHANGED:</td><td>$changed</td></tr>
</table>
<input type=submit name=$action[0] value="$action[1]">
</form>
[END]



$sql = "SELECT username, domain, descr, quota, antivirus, antispam, status, create_date, change_date, maildir, bill_id, id
        FROM mail_boxes
        ORDER BY $sort $desc;";

my $q = $db->prepare("$sql");
$q->execute();
my $total = $q->rows;


print "<p>$_TOTAL: $total<br>
<TABLE width=98% cellspacing=0 cellpadding=0 border=0><TR><TD bgcolor=$_BG4>
<TABLE width=100% cellspacing=1 cellpadding=0 border=0>
  <COLGROUP>
    <COL align=left span=3>
    <COL align=right span=1>
    <COL align=center span=3>
    <COL align=right span=2>
  </COLGROUP>\n";

 my @caption = ("E-mail", "$_DOMAINS", "$_DESCRIBE", "$_LIMIT", "$_ANTIVIRUS", "$_ANTISPAM", "$_STATUS", "$_REGISTRATION", "$_CHANGED", "E-mail $_FOLDER", "", "-", "-");
 show_title($sort, $desc, "$pg", "$op&$qs", \@caption);

while(($username, $domain, $descr, $quota, $antivirus, $antispam, $status, $create_date, $change_date, 
  $maildir, $bill_id, $id) = $q->fetchrow_array()) {
   	
  $bg = ($bg eq $_BG1) ? $_BG2 : $_BG1;
  my $del_button = "<A href='$SELF?op=mailboxes&del=$id'
        onclick=\"return confirmLink(this, '$_DELETE \\'$username\\'?')\">$_DEL</a>";
  print "<tr bgcolor=$bg><td>$username</td><td>$domain</td><td>$descr</td><td>$quota</td>".
   "<td bgcolor=$scolors[$antivirus]>$status_types[$antivirus]</td><td bgcolor=$scolors[$antispam]>$status_types[$antispam]</td>".
   "<td bgcolor=$scolors[$status]>$status_types[$status]</td><td>$create_date</td><td>$change_date</td><td>$maildir</td>".
   "<td>$bill_id</td><td><a href='$SELF?op=networks&chg=$id'>$_CHANGE</a></td><td>$del_button</td></tr>\n";
}


print "</table>
</td></tr></table>
</p>\n";


}


#Message system
#
#print "<h3>$_MESSAGES</h3>\n";
#print "Under construction";

$debug = 1;
use Abwconf;


#*******************************************************************
# show admin messages
# msgs_new($uid);
#*******************************************************************
sub msgs_new {
 my ($uid) = @_;
 my $count = 0;
 
 my $sql = "select count(id) FROM messages 
  WHERE uid='$uid' and state=0 and reply IS not NULL;";
 

 $q = $db->prepare($sql) || die $db->strerr;
 $q ->execute();
 
 ($count)=$q -> fetchrow();
 if ($count > 0) {
    print "(<img src='img/email-g.gif'><a href='$SELF?op=msgs'>$_MESSAGES $count</a>)";
  }
}


#*******************************************************************
# show admin messages
# report_new();
#*******************************************************************
sub report_new {
 my $count = 0;
 
 my $sql = "select count(id) FROM messages WHERE reply IS NULL;";
 
 $q = $db->prepare($sql) || die $db->strerr;
 $q ->execute();
 
 ($count)=$q -> fetchrow();
 if ($count > 0) {
    print "<img src='../img/email-g.gif'><a href='$SELF?op=messages'>$_MESSAGES $count</a>";
  }
}


#*******************************************************************
# message admin
# msgs_admin();
#*******************************************************************
sub msgs_admin {
 my $sort = $FORM{sort} || 1; 
 my $desc = $FORM{desc} || '';

 print "<h3>$_MESSAGES</h3>\n";	

 if ($FORM{sub} eq 'groups') {
    msgs_groups();
    return 0
   }

if ($FORM{uid}) {
  print "$_USER: <a href='$SELF?op=users&uid=$FORM{uid}'>$login</a><br>";
  #msgs_create($FORM{uid});
  $WHERE = " WHERE m.uid='$FORM{uid}'";
 }
else {
  print "<a href='$SELF?op=messages&sub=groups'>$_GROUPS</a> ::\n";
}

if ($FORM{add}) {
   $sql = "UPDATE messages  set 
     reply='$FORM{message}',
     admin='$admin_name'
   WHERE id='$FORM{reply}';";
  
   $q = $db->do($sql);

   message('info', "$_INFO", "$_ADDED");
 }
elsif ($FORM{del}) {
   $sql = "DELETE FROM messages WHERE id='$FORM{reply}';";
   $q = $db->do($sql);
   message('info', "$_INFO", "$_DELETED ID: [$FORM{reply}]");
 }
elsif ($FORM{reply}) {

  $sql = "select date, u.id, mt.name, message, admin, reply, m.uid
     FROM messages m
     LEFT join message_types mt ON(m.type=mt.id)
     LEFT JOIN users u ON (u.uid=m.uid)
    WHERE m.id='$FORM{reply}'";
  
  $q = $db->prepare($sql) || die $db->strerr;
  $q ->execute();
 
  my($date, $login, $type, $message, $admin, $reply, $uid)=$q -> fetchrow();


print << "[END]";
<form action=$SELF METHOD=post>
<input type=hidden name=op value=messages>
<input type=hidden name=reply value=$FORM{reply}>
<TABLE width=640 cellspacing=0 cellpadding=0 border=0>
  <tr><TD bgcolor=$_BG4>
  <TABLE width=100% cellspacing=1 cellpadding=0 border=0>
<tr bgcolor=$_BG1><td>$_USER:</td><td>$login</td></tr>
<tr bgcolor=$_BG1><td>$_DATE:</td><td>$date</td></tr>
<tr bgcolor=$_BG1><td>$_TYPE:</td><td>$type</td></tr>
<tr bgcolor=$_BG1><td>$_OPERATOR:</td><td>$admin</td></tr>
<tr><th bgcolor=$_BG0 colspan=2>$_MESSAGE</th></tr>
<tr bgcolor=$_BG1><td colspan=2>$message</td></tr>
<tr><th bgcolor=$_BG0 colspan=2>$_REPLY</th></tr>
<tr bgcolor=$_BG1><th colspan=2><textarea name=message cols=60 rows=12>$reply</textarea></th></tr>
</table>
</td></tr></table>
<input type=submit name=add value='$_ADD'>
<input type=submit name=del value='$_DEL'>
</form>
[END]

}



 
 print "<TABLE width=640 cellspacing=0 cellpadding=0 border=0>
  <tr><TD bgcolor=$_BG4>
  <TABLE width=100% cellspacing=1 cellpadding=0 border=0>\n";
 my @caption = ("ID", "$_DATE", "$_USER", "-", "-");
 show_title($sort, $desc, "0", "messages", \@caption);


 $sql = "select m.id, m.par, m.date, u.id, m.type, m.message, m.admin, 
   if(m.reply is NULL, '', m.reply), m.uid
  FROM messages m
  LEFT JOIN users u ON (m.uid=u.uid)
  $WHERE ORDER by $sort $desc";

 log_print('LOG_SQL', "$sql");

 $q = $db->prepare($sql) || die $db->strerr;
 $q ->execute();
 

 while(my($id, $par, $date, $login, $type, $message, $admin, $reply, $uid)=$q -> fetchrow()) {
   $bg = ($bg eq $_BG1) ? $_BG2 : $_BG1;

   my $state = '<img src="../img/red_dot.gif">' if ($reply eq '');
     print "<tr bgcolor=$bg><td>$id</td><td>$date</td><td><a href='$SELF?op=users&uid=$uid'>$login</a></td>".
      "<th>$state</th><td><a href='$SELF?op=messages&reply=$id'>$_REPLY</a></td></tr>\n";
  }
 
 print "</table>\n</td></tr></table>\n";


}

#*******************************************************************
# message admin
# msgs_groups()
#*******************************************************************
sub msgs_groups {
  print "<h3>$_GROUPS</h3>\n";
  my $name = $FORM{name} || '';
  my @action = ('add', "$_ADD");

if ($FORM{add}) {
    $sql = "INSERT INTO message_types (name)  VALUES ('$name');";
    $q = $db->do($sql);
    
    if ($db->err == 1062) {
       message('err', "$_ERROR", "'$name' $_EXIST");
       return 0;
      }
    elsif($db->err > 0) {
       message('err', "$_ERROR", $db->errstr . " - N:". $db->err);
      }
    else {
       message('info', "$_ADDED", "$_ADDED '$name'");
     }

}
elsif($FORM{change}){
  $sql = "UPDATE message_types SET 
   name='$name'
   WHERE id='$FORM{chg}';";
  $q = $db->do($sql);
  message('info', "$_CHAHGED", "$_CHANGED [$FORM{chg}]");
}
elsif($FORM{chg}) {
  $q = $db -> prepare("SELECT name FROM message_types  WHERE id='$FORM{chg}';") || die $db->strerr;
  $q -> execute ();
  ($name) = $q -> fetchrow();
  message('info', "$_CHANGING", "$_CHANGING [$FORM{chg}]");
  @action = ('change', "$_CHANGE");
}
elsif($FORM{del}){
  $sql = "DELETE FROM message_types WHERE id='$FORM{del}';";
  $q = $db->do($sql);
  message('info', "$_DELETED", "$_DELETED [$FORM{del}]");
}

print << "[END]";
<form action=$SELF>
<input type=hidden name=op value=messages>
<input type=hidden name=sub value=groups>
<input type=hidden name=chg value=$FORM{chg}>
<table>
<tr><td>ID:</td><td>$FORM{chg}</td></tr>
<tr><td>$_NAME:</td><td><input type=text name=name value='$name'></td></tr>
</table>
<input type=submit name=$action[0] value="$action[1]">
</form>
[END]

print "<TABLE width=640 cellspacing=0 cellpadding=0 border=0>
  <tr><TD bgcolor=$_BG4>
  <TABLE width=100% cellspacing=1 cellpadding=0 border=0>\n";
 @caption = ("ID", "$_NAME", "-", "-", "-");
 show_title($sort, $desc, "0", "messages&sub=groups", \@caption);
  
  $q = $db -> prepare("SELECT id, name FROM message_types;") || die $db->strerr;
  $q -> execute ();
  while(($id, $name) = $q -> fetchrow()) {
     $bg = ($bg eq $_BG1) ? $_BG2 : $_BG1;
     $button = "<A href='$SELF?op=messages&sub=groups&del=$id'
        onclick=\"return confirmLink(this, 'FILTER: $name [$id]:')\">$_DEL</a>";
     print "<tr bgcolor=$bg><td align=right>$id</td><td>$name</td><td><a href='$SELF?op=messages&group=$id'>$_MESSAGES</a></td>".
     "<td><a href='$SELF?op=messages&sub=groups&chg=$id'>$_CHANGE</a></td><td>$button</td></tr>\n";
   }
print "</table></td></tr></table>\n";

}


#*******************************************************************
# show user messages
# msgs_user($uid);
#*******************************************************************

sub msgs_user {
 my ($uid) = @_;
 my $par = $FORM{par} || 0;
 my $type = $FORM{type} || 0;
 my $message = $FORM{text} || '';
 my $ip = $ENV{REMOTE_ADDR} || '0.0.0.0';

if ($FORM{show}) {
  $sql = "SELECT id, date, admin, message, reply  FROM messages
    WHERE uid='$uid' and id='$FORM{show}';";
  log_print('LOG_SQL', "$sql");
  $q = $db -> prepare($sql) || die $db->strerr;
  $q -> execute ();
  
  my($sid, $date, $admin, $message, $reply) = $q->fetchrow();
  
print << "[END]";
<table width=640 border=0 cellpadding="0" cellspacing="0">
<tr><td bgcolor=#00000>
<table width=100% border=0 cellpadding="2" cellspacing="1">
<tr><td bgcolor=FFFFFF>

<TABLE width=640 cellspacing=0 cellpadding=0 border=0>
  <tr><TD bgcolor=$_BG4>
  <TABLE width=100% cellspacing=1 cellpadding=0 border=0>
<tr bgcolor=$_BG1><td>#</td><td>$sid</td></tr>
<tr bgcolor=$_BG1><td>$_DATE</td><td>$date</td></tr>
<tr bgcolor=$_BG1><td>$_OPERATOR</td><td>$admin</td></tr>
<tr><th colspan=2 bgcolor=$_BG2>$_MESSAGE</th></tr>
<tr bgcolor=$_BG1><td colspan=2>$message</td></tr>
<tr><th colspan=2 bgcolor=$_BG2>$_REPLY</th></tr>
<tr bgcolor=$_BG1><td colspan=2>$reply</td></tr>
</table>
</td></tr></table>
</td></tr>
</table>
</td></tr>
</table>
<p>
[END]

  $sql = "UPDATE messages SET state=1
   WHERE id='$FORM{show}' and uid='$uid';";
  $q = $db->do($sql) || die $db->strerr;
 }
elsif (defined($FORM{send})) {
  $sql = "INSERT INTO messages (par, uid, type, message, ip, date)
   VALUES ('$par', '$uid', '$type', '$message', INET_ATON('$ip'), now());";
  $q = $db->do($sql) || die $db->strerr;
  message('info', "$_INFO", "$_SENDED");
  $login = get_login($uid);
  sendmail("$conf{ADMIN_MAIL}", "$conf{ADMIN_MAIL}", "New message", 
             "New message from '$login'", "$conf{MAIL_CHARSET}", "2 (High)");
  return 0;
}


print "<TABLE width=640 cellspacing=0 cellpadding=0 border=0>
  <tr><TD bgcolor=$_BG4>
  <TABLE width=100% cellspacing=1 cellpadding=0 border=0>
  <tr bgcolor=$_BG0><th>#</th><th>$_DATE</th><th width=20>$_REPLY</th></tr>";
  
  $sql = "SELECT id, date, if(reply IS NULL, 0, 1), state  FROM messages
    WHERE uid='$uid' ORDER BY id DESC;";
  log_print('LOG_SQL', "$sql");
  $q = $db -> prepare($sql) || die $db->strerr;
  $q -> execute ();
  
  while(my($id, $date, $reply, $status) = $q -> fetchrow()) {
     if ($id eq $sid) {
     	$bg = $_BG3;
       }
     else {
        $bg = ($bg eq $_BG1) ? $_BG2 : $_BG1;
      }
     
     if ($reply == 0) {
       $status = '';
       } 
     else {
       if ($status == 1) {
         $status = "<a href='$SELF?op=msgs&show=$id'><img border=0 src='img/msg_savebox.gif'></a>";
        }
       else {
     	 $status = "<a href='$SELF?op=msgs&show=$id'><img border=0 src='img/msg_inbox.gif'></a>";
     	}
      }
     
     print "<tr bgcolor=$bg><td align=right>$id</td><td>$date</td><th>$status</th></td></tr>\n";
   }
print "</table>\n</td></tr></table><p>\n";
 
 msgs_create($uid);
}

#*******************************************************************
# msgs_create($uid)
#*******************************************************************
sub msgs_create {
 my ($uid) = @_;

print "
<form action=$SELF METHOD=post>
<input type=hidden name=op value=msgs>
<input type=hidden name=uid value=$uid>
<table width=600>
<tr><td colspan=2>$_MESSAGES_DESCRIBE</td></tr>
<tr><td align=right>$_TYPE:</td><td><select name=type>\n";

  $q = $db -> prepare("SELECT id, name FROM message_types;") || die $db->strerr;
  $q -> execute ();
  while(my($id, $name) = $q -> fetchrow()) {
     print "<option value=$id>$name\n";
    }

print "</select></td></tr>
<tr><th colspan=2><textarea name=text rows=12 cols=60></textarea></th></tr>
</table>
<input type=submit name=send value='$_SEND'>
</form>\n";
	
}
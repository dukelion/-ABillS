#!/usr/bin/perl
# Users interface

#---------Variables------------
my $ftpserver="localhost";
#-------END_Variables----------

#my $LIB_PATH='./admin';
#push(@INC, $LIB_PATH);

use lib "./admin";
use Abwconf;
#use FindBin '$Bin';
#print $Bin;

require "Base.pm";
Base->import();
require 'config.pl';
require 'messages.pl';

$db=$Abwconf::db;



use DB_File;
my $domain = $ENV{SERVER_NAME};
my $web_path = '/billing/';
my $sessions='sessions.db';
#my $doc_id = $cookies{doc_id} || '';
$uid =  $cookies{uid};
$login = $FORM{user};
my $sid = $FORM{sid} || 0; # Session ID
my $passwd = $FORM{passwd} || '';
my $period = $FORM{period} || 0;
my $session_timeout = 1800;
my $ln = 'english';

if ((length($cookies{sid})>1) && (! $FORM{passwd})) {
  $sid = $cookies{sid};
}

if ($FORM{ln}) {
	$ln = $FORM{ln};
}
elsif($cookies{ln}) {
	$ln = $cookies{ln};
}

#$ln = $cookies{ln} if ($cookies{ln});
#my $language = $ln || 'english';

require "../language/". $ln .".pl";

print "Content-type: text/html\n";
print "Set-Cookie: uid=$uid; path=$web_path; domain=$domain;\n";
print "Set-Cookie: doc_id=$FORM{doc_id}; path=$web_path; domain=$domain;\n";
print "Set-Cookie: sid=$sid; path=$web_path; domain=$domain;\n";
print "Set-Cookie: ln=$ln; path=$web_path; domain=$domain;\n\n";

if (($FORM{docs} eq 'print')) {
  ($uid, $sid, $login) = auth("$login", "$passwd", "$sid");
  if ($uid > 0) {
    require "admin/Abdocs.pm";
    print_version("$FORM{d}");
    exit 0;
   }
}
elsif ($FORM{pre} && $uid > 0) {
  make_acct_doc();
  exit 0;	
}

$css = css();

print << "[END]";
<html>
<head>
<title>~AsmodeuS~ Billing System</title>
 <meta http-equiv=\"Content-Type\" content=\"text/html; charset=windows-1251\">
 $css
</head>
<body bgcolor=#ffffff vlink=0000FF leftmargin="0" topmargin="0" marginwidth="0" marginheight="0">
<Table width=100%><tr><td bgcolor=$_BG0>
<h3>$header_text</h3>
</td></tr>
</table>
<center>
<a href='$SELF?op=dunes' title='$_DUNES'>DUNES</a> :: 
[END]


($uid, $sid, $login) = auth("$login", "$passwd", "$sid");


if($FORM{op} eq 'dunes') {
  print "<a href='$SELF'>$_LOGIN</a> :: ";
  require "win_dunes.cgi";
 }
elsif ($uid > 0) {
  #print "// $sid, $uid, $login, $time //";
  account($uid);
 }
else {
  login_form();
 }

print "<hr size=1><a href='http://abills.sf.net'><i>~AsmodeuS~ 2005</i></a>
</body>
</html>\n";


####################################################################

#*******************************************************************
# User Account
# account()
#*******************************************************************
sub account {
 my ($uid) = @_;

 my %main_menu = (
   '4:logout', $_LOGOUT,
   '3:docs', $_ACCOUNTS,
   '2:msgs', $_MESSAGES,
   '1:stats', $_STATS
   );

 my @menu_keys = sort keys %main_menu;

 #while(my ($key, $v)=each(%main_menu)) 
 foreach my $key (@menu_keys) {
   my($n, $k)=split(/:/, $key);
   if ($k eq $op) {
       print "<a href='$SELF?op=$k&sid=$sid'><b>$main_menu{$key}</b></a>::";
     }
   else {
       print "<a href='$SELF?op=$k&sid=$sid'>$main_menu{$key}</a>:: \n";
     }
   }
  
  msgs_new("$uid");

  print "<hr size=1><center>";

  if ($op eq 'msgs') {
     msgs_user("$uid");
   }
  elsif ($op eq 'docs' || $FORM{docs}) {
      require "admin/Abdocs.pm";
      #Abdocs->import();
      if ($FORM{create}) {
      	mk_acct();
       }
      else { 
      	make_acct_doc(); 
      	show_user_accounts($uid);
       }
   }
  else {
    #$login = get_login($uid);
    user_stats($login);
   }
}



#*******************************************************************
# user_stats($uid)
#*******************************************************************
sub user_stats {
 my $uid = shift;
 my $show = '';
 
$sql = "select u.variant, u.credit, u.deposit, u.speed, v.name, u.activate, u.expire
 from users u,  variant v 
 where u.variant=v.vrnt and u.id='$uid'";

my $q = $db->prepare("$sql");
$q->execute();
my ($variant, $debt, $money, $speed, $v_name, $activate, $expire) = $q->fetchrow_array();
$q->finish;

my $q = $db->prepare("select date, sum from payment where uid='$uid' ORDER BY date DESC LIMIT 1;");
$q->execute();
my ($pdate, $psum) = $q->fetchrow_array() if ($q->rows > 0);
$q->finish;

my $speed = ($speed > 0) ? "<tr bgcolor=$_BG1><td><b>$_SPEED:</b></td><td>$speed Kbit/set</td></tr>\n" : '' ;

print "<TABLE width=400 cellspacing=0 cellpadding=0 border=0>
  <TR><TD bgcolor=$_BG4>
  <TABLE width=100% cellspacing=1 cellpadding=0 border=0>
<tr bgcolor=$_BG1><td><b>$_USER:</b></td><td>$uid</td></tr>
<tr bgcolor=$_BG1><td><b>$_CREDIT:</b></td><td align=right><!--CREDIT_BEGIN-->$debt<!--CREDIT_END--></td></tr>
<tr bgcolor=$_BG1><td><b>$_BALANCE:</b></td><td align=right><!--DEPOSIT_BEGIN-->$money<!--DEPOSIT_END--></td></tr>
<tr bgcolor=$_BG1><td><b>$_VARIANT:</b></td><td>$variant ($v_name)</td></tr>
$speed 
<tr bgcolor=$_BG1><th colspan=2 bgcolor=$_BG2>:$_LAST_PAYMENT:</th></tr>
<tr bgcolor=$_BG1><td><b>$_SUM:</b></td><td align=right>$psum</td></tr>
<tr bgcolor=$_BG1><td><b>$_DATE:</b></td><td align=right>$pdate</td></tr>
<tr bgcolor=$_BG1><th colspan=2>&nbsp;</th></tr>";

print "<tr bgcolor=$_BG1><td><b>$_ACTIVATE:</b></td><td align=right>$activate</td></tr>"; # if ($activate ne '0000-00-00'); 
print "<tr bgcolor=$_BG1><td><b>$_EXPIRE:</b></td><td align=right><!--MONTH_EXPIRE_BEGIN-->$expire<!--MONTH_EXPIRE_END--></td></tr>"; # if ($expire ne '0000-00-00'); 

print "</table>\n</td></tr></table>\n<hr size=1>\n";

# active user session
my $active_sessions = "";

$sql = "SELECT SEC_TO_TIME(acct_session_time), 
 acct_input_octets, acct_output_octets, ex_input_octets, ex_output_octets,
 INET_NTOA(framed_ip_address),
 CID
 from calls 
 WHERE user_name='$uid' and (status=1 or status>=3);";
 
$q = $db->prepare("$sql");
$q->execute();

if ($q->rows > 0) {
print "$_ACTIV:";
print "<table width=640 border=0 cellspacing=0 cellpadding=0><tr><td bgcolor=000000>
<table width=100% border=0 cellspacing=1 cellpadding=2><tr><td bgcolor=FFFFFF>
<TABLE width=640 cellspacing=0 cellpadding=0 border=0>
<tr><TD bgcolor=$_BG4>
<TABLE width=100% cellspacing=1 cellpadding=0 border=0>
<tr bgcolor=$_BG0><th>$_DURATION</th><th>$_SENT</th><th>$_RECV</th><th>$_SENT 2</th><th>$_RECV 2</th><th>IP</th><th>CID</th></tr>
<COLGROUP>
  <COL align=left span=1>
  <COL align=right span=6>
</COLGROUP>\n";

my $i=1;
while (my($duration, $sent, $recv, $sent2, $recv2, $ip, $CID) = $q->fetchrow_array()) {
  $sent = int2byte($sent);
  $recv = int2byte($recv);
  $i++;
  print "<tr bgcolor=$_BG1><td><!--CUR_SESSION_DURATION_BEGIN-->$duration<!--CUR_SESSION_DURATION_END--></td>
   <td><!--CUR_SESSION_SENT_BEGIN-->$sent<!--CUR_SESSION_SENT_END--></td><td><!--CUR_SESSION_RECV_BEGIN-->$recv<!--CUR_SESSION_RECV_EN--></td><td>$sent2</td><td>$recv2</td><td>$ip</td><td>$CID</td></tr>\n";
}
print "</table>\n</td></tr></table>\n</td></tr></table>\n</td></tr></table><p>\n";
}

#totals summary
 $q = $db -> prepare("SELECT  
  sum(if(date_format(login, '%Y-%m-%d')=curdate(), sent, 0)), 
  sum(if(date_format(login, '%Y-%m-%d')=curdate(), recv, 0)), 
  SEC_TO_TIME(sum(if(date_format(login, '%Y-%m-%d')=curdate(), duration, 0))), 

  sum(if(TO_DAYS(curdate()) - TO_DAYS(login) = 1, sent, 0)),
  sum(if(TO_DAYS(curdate()) - TO_DAYS(login) = 1, recv, 0)),
  SEC_TO_TIME(sum(if(TO_DAYS(curdate()) - TO_DAYS(login) = 1, duration, 0))),

  sum(if(TO_DAYS(curdate()) - TO_DAYS(login) < 7, sent, 0)),
  sum(if(TO_DAYS(curdate()) - TO_DAYS(login) < 7, recv, 0)),
  SEC_TO_TIME(sum(if(TO_DAYS(curdate()) - TO_DAYS(login) < 7, duration, 0))),

  sum(if(date_format(login, '%Y-%m')=date_format(curdate(), '%Y-%m'), sent, 0)), 
  sum(if(date_format(login, '%Y-%m')=date_format(curdate(), '%Y-%m'), recv, 0)), 
  SEC_TO_TIME(sum(if(date_format(login, '%Y-%m')=date_format(curdate(), '%Y-%m'), duration, 0))),
  
  sum(sent), sum(recv), SEC_TO_TIME(sum(duration))
FROM log WHERE id='$uid';") || die $db->strerr;
  $q -> execute ();
 print "<table width=640 border=0 cellspacing=0 cellpadding=0><tr><td bgcolor=000000>
 <table width=100% border=0 cellspacing=1 cellpadding=2><tr><td bgcolor=FFFFFF>\n";

  if ($q->rows == 0) {
      message('err', "$_ERROR", "$_USER_NOT_EXIST");
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
  $all_recv = int2byte($all_recv);
  $all_sent = int2byte($all_sent);
  
  $today_sent = int2byte($today_sent);
  $today_recv = int2byte($today_recv);
  $yesterday_sent = int2byte($yesterday_sent);
  $yesterday_recv = int2byte($yesterday_recv);
  $week_sent = int2byte($week_sent);
  $week_recv = int2byte($week_recv);
  $month_sent = int2byte($month_sent);
  $month_recv = int2byte($month_recv);
  
  
print "
  <TABLE width=640 cellspacing=0 cellpadding=0 border=0>
  <TR><TD bgcolor=$_BG4>
  <TABLE width=100% cellspacing=1 cellpadding=0 border=0>
  <COLGROUP>
    <COL align=left span=1>
    <COL align=right span=4>
  </COLGROUP>
  <tr bgcolor=$_BG0><th>$_PERIOD</th><th>$_DURATION</th><th>$_SENT</th><th>$_RECV</th><th>$_SUM</th></tr>
  <tr bgcolor=$_BG1><th align=left><a href='$SELF?op=log&sid=$sid&period=0'>$PERIODS[0]</a></th><td>$today_duration</td> <td>$today_sent</td><td>$today_recv</td><th>$today_sum</th></tr>
  <tr bgcolor=$_BG1><th align=left><a href='$SELF?op=log&sid=$sid&period=1'>$PERIODS[1]</a></th><td>$yesterday_duration</td> <td>$yesterday_sent</td><td>$yesterday_recv</td><th>$yesterday_sum</th></tr>
  <tr bgcolor=$_BG1><th align=left><a href='$SELF?op=log&sid=$sid&period=2'>$PERIODS[2]</a></th><td>$week_duration</td> <td>$week_sent</td><td>$week_recv</td><th>$week_sum</th></tr>
  <tr bgcolor=$_BG1><th align=left><a href='$SELF?op=log&sid=$sid&period=3'>$PERIODS[3]</a></th><td>$month_duration</td> <td><!--MONTH_SENT_BEGIN-->$month_sent<!--MONTH_SENT_BEGIN--></td><td><!--MONTH_RECV_BEGIN-->$month_recv<!--MONTH_RECV_END--></td><th><!--MONTH_SUM_BEGIN-->$month_sum<!--MONTH_SUM_END--></th></tr>
  <tr bgcolor=$_BG1><th align=left><a href='$SELF?op=log&sid=$sid&period=4'>$PERIODS[4]</a></th><td>$all_duration</td> <td>$all_sent</td><td>$all_recv</td><th>$all_sum</th></tr>
  </table>\n</td></tr></table>\n</td></tr></table>\n</td></tr></table><p>\n";
$q -> finish ();

$from_date = date_fld('from');
$to_date = date_fld('to');

print "<form action=$SELF>
 <input type=hidden name=sid value='$sid'>
 <table bgcolor=$_BG0><tr><th> $_FROM:</th><td>$from_date</td><th> $_TO:</th><td>$to_date</td>
 <td><input type=submit name=show value=$_SHOW></td></tr></table>
 </form>\n";

my $WHERE = "WHERE id='$uid' ";

if (defined($FORM{show})) {
  $show = "&show=y&rows=$max_recs&fromd=$FORM{fromd}&fromm=$FORM{fromm}&fromy=$FORM{fromy}&tod=$FORM{tod}&tom=$FORM{tom}&toy=$FORM{toy}";
  $FORM{fromm}++;
  $FORM{tom}++;
  $FORM{fromm} = sprintf("%.2d", $FORM{fromm}++);
  $FORM{tom} = sprintf("%.2d", $FORM{tom}++);
  $WHERE .= "and date_format(login, '%Y-%m-%d')>='$FORM{fromy}-$FORM{fromm}-$FORM{fromd}' and date_format(login, '%Y-%m-%d')<='$FORM{toy}-$FORM{tom}-$FORM{tod}'";
 }
elsif ($period == 0) {
   $WHERE .= "and date_format(login, '%Y-%m-%d')=curdate() ";
 }
elsif ($period == 1) {
   $WHERE .= "and TO_DAYS(curdate()) - TO_DAYS(login) = 1 ";
 }
elsif ($period == 2) {
   $WHERE .= "and TO_DAYS(curdate()) - TO_DAYS(login) < 7 ";
 }
elsif ($period == 3) {
   $WHERE .= "and date_format(login, '%Y-%m')=date_format(curdate(), '%Y-%m') ";
 }
elsif ($period == 4) {
   $WHERE .= '';
 }
else {
   $WHERE .= "and date_format(login, '%Y-%m-%d')=curdate() ";
 }


 if ($FORM{show}) { 
    print "<b>$_FROM:</b> $FORM{fromy}-$FORM{fromm}-$FORM{fromd} <b>$_TO:</b> $FORM{toy}-$FORM{tom}-$FORM{tod}"; 
  }
 else { 
    print  $PERIODS[$period]; 
  }

print "<table width=640 border=0 cellspacing=0 cellpadding=0><tr><td bgcolor=000000>
<table width=100% border=0 cellspacing=1 cellpadding=2><tr><td bgcolor=FFFFFF>
<TABLE width=640 cellspacing=0 cellpadding=0 border=0><tr><TD bgcolor=$_BG4>
<TABLE width=100% cellspacing=1 cellpadding=0 border=0>
 <tr bgcolor=$_BG0><th>$_LOGINS</td><th>$_DURATION</th><Th>$_TRAFFIC</th><Th>$_TRAFFIC 2</th><th>$_SUM</th></tr>\n";

 $sql = "SELECT  count(login), SEC_TO_TIME(sum(duration)), sum(sent + recv), sum(sent2 + recv2), sum(sum) FROM log $WHERE GROUP BY id;";
 $q = $db -> prepare($sql) || die $db->strerr;
 $q -> execute ();
 my ($logins, $duration, $trafic, $trafic2, $sum) = $q -> fetchrow();
 $trafic = int2byte($trafic);
 $trafic2 = int2byte($trafic2);
 print "<tr bgcolor=$_BG1><td  align=right>$logins</td><td align=right>$duration</td><TD align=right>$trafic</td><TD align=right>$trafic2</td><th align=right>$sum</th></tr>\n";

print "</table>\n</td></tr></table>\n</td></tr></table>\n</td></tr></table><p>\n";


print "<table width=99% border=0 cellspacing=0 cellpadding=0><tr><td bgcolor=000000>
<table width=100% border=0 cellspacing=1 cellpadding=2><tr><td bgcolor=FFFFFF>
<TABLE width=100% cellspacing=0 cellpadding=0 border=0><tr><TD bgcolor=$_BG4>
<TABLE width=100% cellspacing=1 cellpadding=0 border=0>
 <tr bgcolor=$_BG0><th>$_LOGIN</td><th>$_VARIANT</td><th>$_DURATION</th><Th>$_RECV</th><Th>$_SENT</th><Th>$_RECV 2</th><Th>$_SENT 2</th><Th>CID</th><th>$_SUM</th></tr>
<COLGROUP>
  <COL align=left span=1>
  <COL align=right span=8>
</COLGROUP> \n";

 $q = $db -> prepare("SELECT  login, variant, SEC_TO_TIME(duration), sent, recv, sent2, recv2, CID, sum FROM log $WHERE ORDER by login DESC LIMIT $pg, $max_recs;") 
   || die $db->strerr;
  $q -> execute ();
  while(($login, $variant, $duration, $sent, $recv, $sent2, $recv2, $CID, $sum) = $q -> fetchrow()) {
      $bg = ($bg eq $_BG1) ? $_BG2 : $_BG1;
      $recv = int2byte($recv);
      $sent = int2byte($sent);
      $recv2 = int2byte($recv2);
      $sent2 = int2byte($sent2);
      print "<tr bgcolor=$bg><td>$login</td><td>$variant</td><td>$duration</td>
        <TD>$recv</td><TD>$sent</td><TD>$recv2</td><TD>$sent2</td><TD>$CID</td><th>$sum</th></tr>\n";
    } 
  print "</table>\n</td></tr></table>\n</td></tr></table>\n</td></tr></table>\n";
  
  %pages = pages('id', 'log', "$WHERE", "sid=$sid&period=$period&$show", "$pg");
  print $pages{pages};

  
=comments
  if (($period) && ($logins > $max_recs)) {
     for($i=0; $i<=$logins; $i+=$max_recs) {
       if ($pg == $i) { print "<b>$i</b> " }
        else { print "<a href='$SELF?sid=$sid&period=$period&pg=$i'>$i</a>\n "; }
      }
   }
=cut
 
}

#*******************************************************************
# Authentification from SQL DB
# auth_sql($login, $password)
#*******************************************************************
sub auth_sql {
 my ($login, $password) = @_;
 my $ret = 0;

my $sql = "select uid, fio FROM users WHERE id='$login' and password=ENCODE('$password', '$conf{secretkey}');";
my $q = $db->prepare("$sql");
$q->execute();

if ($q->rows() > 0) {
  my ($uid, $name) = $q->fetchrow_array();
  $q->finish;
  $ret = $uid;
}
#else {
#  message('err', "$_ERROR", "$_WRONG_PASSWD");
#  $action = 'Error';
#  $ret = -1;
#}

 return $ret;	
}


#*******************************************************************
# FTP authentification
# auth($login, $pass)
#*******************************************************************

sub auth { 
 my ($login, $password, $sid) = @_;
 my $ftpserver = 'localhost';
 my $uid = 0;
 my $ret = 0;
 my $REMOTE_ADDR = $ENV{'REMOTE_ADDR'} || '';
 my $HTTP_X_FORWARDED_FOR = $ENV{'HTTP_X_FORWARDED_FOR'} || '';
 my $ip = "$REMOTE_ADDR/$HTTP_X_FORWARDED_FOR";

 
 tie %h, "DB_File",  "$sessions", O_RDWR|O_CREAT, 0640, $DB_HASH
         or die "Cannot open file '$sessions': $!\n";

if ($FORM{op} eq 'logout') {
  delete $h{$sid} ;
  untie %h;
  return 0;
 }
elsif (length($sid) > 1) {

  if (defined($h{$sid})) {
    ($uid, $time, $login, $ip)=split(/:/, $h{$sid});
    my $cur_time = time;
    
    if ($cur_time - $time > $session_timeout) {
      delete $h{$sid};
      message('info', "$_INFO", 'timeout');	
      return 0; 
     }
    elsif($ip ne $REMOTE_ADDR) {
      message('err', "$_ERROR", 'WRONG IP');	
      return 0; 
     }
    #print "'$uid', $time,  $ip<b>$_WELCOME</b> $uid \n";
    untie %h;
    return ($uid, $sid, $login);
   }
  else { 
    message('err', "$_ERROR", $_NOT_LOGINED);	
    return 0; 
   }
 }
else {
# print "$sid";
  return 0 if (! $login  || ! $password);
  
  $res = auth_sql("$login", "$password");
  if ($res < 1) {
    
    eval { require Net::FTP; };
    if (! $@) {
      Net::FTP->import();
      my $ftp = Net::FTP->new($ftpserver) || die "could not connect to the server '$ftpserver' $!";
      $res = $ftp->login("$login", "$password");
      $ftp->quit();
     }
    else {
      message('info', $_INFO, "Install 'libnet' module from http://cpan.org");
     }
   }
}
#Get user ip

if ($res > 0) {
  $sql = "select uid, fio FROM users WHERE id='$login';";
  my $q = $db->prepare("$sql");
  $q->execute();

  if ($q->rows() > 0) {
    ($uid, $name) = $q->fetchrow_array();
    $q->finish;
    $ret = $uid;
    $time = time;
    $sid = mk_unique_value(14);
    $h{$sid} = "$uid:$time:$login:$REMOTE_ADDR";
    untie %h;
    $action = 'Access';
   }
  else {
    message('err', "$_ERROR", "$_WRONG_PASSWD");
    $action = 'Error';
   }
 }
#elsif ($res == undef) {
#   return ($pass eq $universal_pass) ? 0 : 1;
#  }
else {
   message('err', "$_ERROR", "$_WRONG_PASSWD");
   $ret = 0;
   $action = 'Error';
 }

 open(FILE, ">>login.log") || die "can't open file $i";
   print FILE "$DATE $TIME $action:$login:$logined:$ip\n";
 close(FILE);

 return ($ret, $sid, $login);
}




#*******************************************************************
# login_form()
#*******************************************************************
sub login_form {
print "<form action=$SELF METHOD=post>
<TABLE width=400 cellspacing=0 cellpadding=0 border=0><TR><TD bgcolor=$_BG4>
<TABLE width=100% cellspacing=1 cellpadding=0 border=0><TR><TD bgcolor=$_BG1>
<TABLE width=100% cellspacing=0 cellpadding=0 border=0>
<tr><td>$_LOGIN:</td><td><input type=text name=user></td></tr>
<tr><td>$_PASSWD:</td><td><input type=password name=passwd></td></tr>
<tr><td>$_LANGUAGE:</td><td><select name=ln>\n";

while(my($k, $v) = each %LANG) {
  print "<option value='$k'";
  print ' selected' if ($k eq $language);
  print ">$v\n";	
}

print "</seelct></td></tr>
<tr><th colspan=2><input type=submit name=logined value=$_ENTER></th></tr>
</table>

</td></tr></table>
</td></tr></table>
</form>\n";
}

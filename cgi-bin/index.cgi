#!/usr/bin/perl

auth();

#---------Variables------------
my $ftpserver="localhost";
#-------END_Variables----------

my $LIB_PATH='./admin';
push(@INC, $LIB_PATH);

require "admin/Abwconf.pm";
Abwconf->import();
require "Base.pm";
Base->import();
require 'config.pl';
require 'messages.pl';
$db=$Abwconf::db;
my $language = 'ukraine';
require "../language/$language.pl";

use Net::FTP;
use DB_File;


my $domain = $ENV{SERVER_NAME};
my $web_path = '/';
#$date = "09-Nov-05 00:00:00 GMT";
#my $expDate = $date;

my $sessions='sessions.db';
%FORM = form_parse();

%cookies = getCookies();
#my $doc_id = $cookies{doc_id} || '';
$uid = $FORM{user} || $cookies{uid};
my $sid = $FORM{sid} || 0; # Session ID
my $passwd = $FORM{passwd} || '';

$pg = $FORM{pg} || 0;
$sort = $FORM{sort} || 1;
$desc = $FORM{desc} || '';

my $period = $FORM{period} || 0;
my $op = $FORM{op} || '';

if ((length($cookies{sid})>1) && (! $FORM{passwd})) {
 $sid = $cookies{sid};
}


print "Content-type: text/html\n";
print "Set-Cookie: uid=$uid; path=$web_path; domain=$domain;\n";
print "Set-Cookie: doc_id=$FORM{doc_id}; path=$web_path; domain=$domain;\n";
print "Set-Cookie: sid=$sid; path=$web_path; domain=$domain;\n\n";


if ($FORM{docs} eq 'print' && auth("$uid", "$passwd") == 1) {
  require "admin/Abdocs.pm";
  print_version("$FORM{d}");	
  exit 0;
}


print << "[END]";
<html>
<head>
<title>~AsmodeuS~ Billing system</title>
 <meta http-equiv=\"Content-Type\" content=\"text/html; charset=windows-1251\">
</head>
<body bgcolor=#ffffff vlink=0000FF leftmargin="0" topmargin="0" marginwidth="0" marginheight="0">
<Table width=100%><tr><td bgcolor=$_BG0>
<h3>$header_text</h3>
</td></tr>
</table>
<center>
<a href='$SELF?op=dunes' title='$_DUNES'>DUNES</a> :: 
[END]

#  print "-- $sid $uid $time";
if($FORM{op} eq 'dunes') {
   print "<a href='$SELF'>$_LOGIN</a> :: ";
   require "win_dunes.cgi";
 }
elsif (auth("$uid", "$passwd") == 1) {
#  print "-- $sid $uid $time";
   account();
 }
else {
  login_form();
 }


print "<hr>\n";
while(my($k, $v)=each %ENV) {
  print "$k - $v<br>\n";	
}

print "<hr size=1><a href='http://www.asmodeus.com.ua'><i>~AsmodeuS~ 2004</i></a>
</body>
</html>\n";


####################################################################

#*******************************************************************
# User Account
# account()
#*******************************************************************
sub account {
 
 %main_menu = ( 
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
    user_stats($uid);
   }
	
}

#*******************************************************************
# user_stats($uid)
#*******************************************************************
sub user_stats {
 my $uid = shift;
 my $show = '';
 
$sql = "select u.variant, u.credit, u.deposit, v.name, u.activate, u.expire
 from users u,  variant v 
 where u.variant=v.vrnt and u.id='$uid'";

my $q = $db->prepare("$sql");
$q->execute();
my ($variant, $debt, $money, $v_name, $activate, $expire) = $q->fetchrow_array();
$q->finish;

my $q = $db->prepare("select date, sum from payment where id='$uid' ORDER BY date DESC LIMIT 1;");
$q->execute();
my ($pdate, $psum) = $q->fetchrow_array() if ($q->rows > 0);
$q->finish;


print "<table>
<tr><td><b>$_USER:</b></td><td>$uid</td></tr>
<tr><td><b>$_VARIANT:</b></td><td>$variant ($v_name)</td></tr>
<tr><td><b>$_CREDIT:</b></td><td align=right>$debt</td></tr>
<tr><td><b>$_BALANCE:</b></td><td align=right>$money</td></tr>
<tr><th colspan=2 bgcolor=$_BG2>:$_LAST_PAYMENT:</th></tr>
<tr><td><b>$_SUM:</b></td><td align=right>$psum</td></tr>
<tr><td><b>$_DATE:</b></td><td align=right>$pdate</td></tr>
<tr><th colspan=2><hr></th></tr>";

print "<tr><td><b>$_ACTIVATE:</b></td><td align=right>$activate</td></tr>"; # if ($activate ne '0000-00-00'); 
print "<tr><td><b>$_EXPIRE:</b></td><td align=right>$expire</td></tr>"; # if ($expire ne '0000-00-00'); 

print "</table><hr size=1>\n";

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
FROM log WHERE id='$uid';")
  || die $db->strerr;
  $q -> execute ();
 print "<table width=640 border=0 cellspacing=0 cellpadding=0><tr><td bgcolor=000000>
 <table width=100% border=0 cellspacing=1 cellpadding=2><tr><td bgcolor=FFFFFF>
 <table width=100% border=0 cellspacing=1 cellpadding=0>\n";

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
  
  $today_sent = int2byte($today_sent);
  $today_recv = int2byte($today_recv);
  $yesterday_sent = int2byte($yesterday_sent);
  $yesterday_recv = int2byte($yesterday_recv);
  $week_sent = int2byte($week_sent);
  $week_recv = int2byte($week_recv);
  $month_sent = int2byte($month_sent);
  $month_recv = int2byte($month_recv);
  
  
print "
  <tr bgcolor=$_BG0><th>$_PERIOD</th><th>$_DURATION</th><th>$_SENT</th><th>$_RECV</th><th>$_SUM</th></tr>
  <tr><th align=left><a href='$SELF?op=log&sid=$sid&period=0'>$PERIODS[0]</a></th><td align=right>$today_duration</td> <td align=right>$today_sent</td><td align=right>$today_recv</td><th align=right>$today_sum</th></tr>
  <tr><th align=left><a href='$SELF?op=log&sid=$sid&period=1'>$PERIODS[1]</a></th><td align=right>$yesterday_duration</td> <td align=right>$yesterday_sent</td><td align=right>$yesterday_recv</td><th align=right>$yesterday_sum</th></tr>
  <tr><th align=left><a href='$SELF?op=log&sid=$sid&period=2'>$PERIODS[2]</a></th><td align=right>$week_duration</td> <td align=right>$week_sent</td><td align=right>$week_recv</td><th align=right>$week_sum</th></tr>
  <tr><th align=left><a href='$SELF?op=log&sid=$sid&period=3'>$PERIODS[3]</a></th><td align=right>$month_duration</td> <td align=right>$month_sent</td><td align=right>$month_recv</td><th align=right>$month_sum</th></tr>
  <tr><th align=left><a href='$SELF?op=log&sid=$sid&period=4'>$PERIODS[4]</a></th><td align=right>$all_duration</td> <td  align=right>$all_sent</td><td  align=right>$all_recv</td><th align=right>$all_sum</th></tr>
  </table>\n</td></tr></table>\n</td></tr></table><p>\n";
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
 <table width=100% border=0 cellspacing=1 cellpadding=0>
 <tr bgcolor=$_BG0><th>$_LOGINS</td><th>$_DURATION</th><Th>$_TRAFFIC</th><th>$_SUM</th></tr>\n";

 $sql = "SELECT  count(login), SEC_TO_TIME(sum(duration)), sum(sent + recv) / 1024, sum(sum) FROM log $WHERE GROUP BY id;";
 $q = $db -> prepare($sql) || die $db->strerr;
  $q -> execute ();
  my ($logins, $duration, $trafic, $sum) = $q -> fetchrow();
      print "<tr bgcolor=$bg><td  align=right>$logins</td><td align=right>$duration</td>
        <TD align=right>$trafic</td><th align=right>$sum</th></tr>\n";

 print "</table>\n</td></tr></table>\n</td></tr></table><p>\n";

 print "<table width=640 border=0 cellspacing=0 cellpadding=0><tr><td bgcolor=000000>
 <table width=100% border=0 cellspacing=1 cellpadding=2><tr><td bgcolor=FFFFFF>
 <table width=100% border=0 cellspacing=1 cellpadding=0>
 <tr bgcolor=$_BG0><th>$_LOGIN</td><th>$_VARIANT</td><th>$_DURATION</th><Th>$_TRAFFIC</th><th>$_SUM</th></tr>\n";

 $q = $db -> prepare("SELECT  login, variant, SEC_TO_TIME(duration), sent + recv, sum FROM log $WHERE ORDER by login DESC LIMIT $pg, $max_recs;") 
   || die $db->strerr;
  $q -> execute ();
  while(($login, $variant, $duration, $trafic, $sum) = $q -> fetchrow()) {
      $bg = ($bg eq $_BG1) ? $_BG2 : $_BG1;
      $trafic = int2byte($trafic);
      print "<tr bgcolor=$bg><td  align=right>$login</td><td align=right>$variant</td><td align=right>$duration</td>
        <TD align=right>$trafic</td><th align=right>$sum</th></tr>\n";
    } 
  print "</table>\n</td></tr></table>\n</td></tr></table>\n";
  
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
 my ($uid, $password) = @_;
 my $ret = 0;

$sql = "select fio FROM users WHERE id='$uid';";
my $q = $db->prepare("$sql");
$q->execute();

if ($q->rows() > 0) {
 my ($name) = $q->fetchrow_array();
 $q->finish;
 $ret = 1;
}
else {
   message('err', "$_ERROR", "$_WRONG_PASSWD");
   $action = 'Error';
}

 return $ret;	
}


#*******************************************************************
# FTP authentification
# auth($login, $pass)
#*******************************************************************

sub auth { 
 my ($login, $pass) = @_;
 my $ftpserver = 'localhost';

 tie %h, "DB_File", "$sessions", O_RDWR|O_CREAT, 0640, $DB_HASH
         or die "Cannot open file '$sessions': $!\n";

if ($FORM{op} eq 'logout') {
  delete $h{$sid} ;
  untie %h;
  return 0;
 }
elsif (length($sid) > 1) {
  if (defined($h{$sid})) {
    ($uid, $time)=split(/:/, $h{$sid});
    # print "'$uid', $time <b>$_WELCOME</b> $uid \n";
    untie %h;
    return 1;
   }
  else { 
    message('err', "$_ERROR", $_NOT_LOGINED);	
    return 0; 
   }
 }
else {
	
# print "$sid";
 return 0 if (! $login  || ! $pass);
 my $ftp = Net::FTP->new($ftpserver) || die "could not connect to the server $!";
 $res = $ftp->login("$login", "$pass");
 $ftp->quit();
}
#Get user ip
my $REMOTE_ADDR = $ENV{'REMOTE_ADDR'} || '';
my $HTTP_X_FORWARDED_FOR = $ENV{'HTTP_X_FORWARDED_FOR'} || '';
my $ip = "$REMOTE_ADDR/$HTTP_X_FORWARDED_FOR";
 
#Get logined name from radius
my $logined='';

#open(RAD, "$RADWHO -lHn |") || die "Cant open file '$RADWHO' $!";
#  while(<RAD>) {
#      my ($login, $session_id, $type, $port, $d_day, $d_month, $d_num, $d_time, $d_year, $nas_addr, $time, $user_ip)=split(/ +/, $_);
#      if (($ip eq $REMOTE_ADDR) || ($ip eq $HTTP_X_FORWARDED_FOR)) {
#      	   $logined = $login;
#      	   last;
#         }
#    }
#close(RAD);

if ($res > 0) {
   $time = time;
   #$sid = crypt("$pass", "time");

   $sid = mk_unique_value(14);   
#   print "--- '$sid'";
   $h{$sid} = "$uid:$time";
   untie %h;
   $ret = 1;
   $action = 'Access';
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
   print FILE "$DATE $TIME $action:$uid:$logined:$ip\n";
 close(FILE);

 return $ret;
}


#*******************************************************************
# login_form()
#*******************************************************************
sub login_form {
print "<form action=$SELF METHOD=post>
<table>
<tr><td>$_LOGIN:</td><td><input type=text name=user></td></tr>
<tr><td>$_PASSWD:</td><td><input type=password name=passwd></td></tr>
</table>
<input type=submit name=logined value=$_ENTER>
</form>\n";
}


sub auth {
print "Status: 401\r\n",
      "WWW-Authenticate: Basic realm=\"-Billing system\"\r\n",
      "Content-type: text/plain\r\n\r\n",
      "Authorization required!\r\n";

}
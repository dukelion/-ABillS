#!/usr/bin/perl
#Manager interface


use lib 'admin/';
require 'config.pl';
use Abwconf;
$db=$Abwconf::db;
use Base; # Modul with base tools
require 'messages.pl';

$logfile = '/usr/abills/var/log/abills.log';

my $web_path='/billing/';
my $domain = $ENV{SERVER_NAME};
my $admin_name = '';
$conf{passwd_length}=6;
$conf{username_length}=15;


if (defined($ENV{HTTP_CGI_AUTHORIZATION})) {
  $ENV{HTTP_CGI_AUTHORIZATION} =~ s/basic\s+//i;
  my ($REMOTE_USER,$REMOTE_PASSWD) = split(/:/, decode_base64($ENV{HTTP_CGI_AUTHORIZATION}));  
  $admin_name = $REMOTE_USER;
  if (auth("$REMOTE_USER", "$REMOTE_PASSWD") == 1) {
    print "WWW-Authenticate: Basic realm=\"Billing system\"\n";
    print "Status: 401 Unauthorized\n\n";
    message('err', 'ERROR', 'Wrong password');
    exit;
   }
}
else {
	print "Content-Type: text/html\n\n";
	print "mod_rewrite.c not configured.<br>
	       Add to config<br>
	 <textarea cols=60 rows=8>
   <IfModule mod_rewrite.c>
        RewriteEngine on
        RewriteCond %{HTTP:Authorization} ^(.*)
        RewriteRule ^(.*) - [E=HTTP_CGI_AUTHORIZATION:%1]
        Options Indexes ExecCGI SymLinksIfOwnerMatch
   </IfModule>	
	</textarea>\n";
 exit;
}


if (defined($FORM{colors})) {
  my $cook_colors = (defined($FORM{default})) ?  '' : $FORM{colors};
  print "Set-Cookie: colors=$cook_colors; path=$web_path; domain=$domain; expires=\"Fri, 1-Jan-2038 00:00:01\";\n";
 }

if (defined($FORM{language})) {
  print "Set-Cookie: language=$FORM{language}; path=$web_path; domain=$domain; expires=\"Fri, 1-Jan-2038 00:00:01\";\n";
 }
print "Set-Cookie: opid=$FORM{opid}; path=$web_path; domain=$domain;\n\n";

require "../language/$language.pl";
header();


#if (!$admin_name) {
#  if (auth("$REMOTE_USER", "$REMOTE_PASSWD") == 1) {
#    message('err', 'ERROR', 'Wrong password');
#    exit;
#   }
#  else {
#	  login_form();
#  	exit;
#	 }
#}

my $uid = 0;
my $login = '';
if ($FORM{uid}) {
  $uid = $FORM{uid};
  $login = get_login($uid);
  $login_link = "<a href=\"$SELF?op=users&chg=$uid\">$login</a>";
}

my %main_menu = ('1::users', $_USERS);

print "<table width=100% border=0 cellspacing=0 cellpadding=0>
<tr><td bgcolor=$_COLORS[9]>
<table width=100% border=0 cellspacing=1 cellpadding=1>
<tr><td bgcolor=$_COLORS[3]>&nbsp;<b>$_DATE:</b> $DATE $TIME /<b>Admin:</b> <a href='$SELF?op=profile' title='$_PROFILE'>$admin_name</a> <i>($admin_ip)</i>/\n";
get_online({ admin_name => $admin_name, dont_show => 1 });
report_new();

print "</td></tr>
<tr><td bgcolor=$_COLORS[10]>
<table width=100%><tr bgcolor=$_COLORS[0]>\n";

show_menu(0, 'op', "", \%main_menu);

print "</tr></table>
</td></tr></table>
</td></tr></table>
<center>\n";


if ($op eq 'payments') { form_payments();   }
elsif($op eq 'stats')  { stats();           }
elsif($op eq 'errlog') { errlog();      }
elsif($op eq 'chg_uvariant') { form_chg_vid();   }
elsif ($op eq 'profile') { profile();     }
else {
 users();
}










#*******************************************************************
# user_list
#*******************************************************************
sub user_list {
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
show_title($sort, "$desc", "$pg", "$op$qs", \@caption, {img_path => 'img/'});

   while(($login, $fio, $deposit, $credit, $tp_name,  $uid) = $q -> fetchrow()) {
     $bg = ($bg eq $_BG1) ? $_BG2 : $_BG1;
     print "<tr bgcolor=$bg><td><a href='$SELF?op=users&chg=$uid'>$login</a></td><td>$fio</td><td>$deposit</td><td>$credit</td><td>$tp_name</td>".
       "<td><a href='$SELF?op=payments&uid=$uid'>$_PAYMENTS</a></td>".
       "<td><a href='$SELF?op=stats&uid=$uid'>$_STATS</a></td></tr>\n";
    }
print "</table>
</td></tr></table>\n";
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

 print "<h3>$_PAYMENTS</h3>\n";

 my $uniq_str = mk_unique_value(16);

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

  my @caption = ("$_NUM", "$_USER", "$_DATE", "$_SUM", "$_DESCRIBE", "$_OPERATOR", "IP", "$_DEPOSIT");

  show_title($sort, "$desc", "$pg", "$op$qs$pgs", \@caption);

  $sum_total = 0;
  while(my($id, $login, $date,  $sum, $dsc, $ww, $adm_ip, $last_deposit, $uid) = $q -> fetchrow()) {
    $bg = ($bg eq $_BG1) ? $_BG2 : $_BG1;
    print "<tr bgcolor=$bg><td>$id</td><td><a href='$SELF?op=users&chg=$uid'>$login</a></td><td>$date</td>".
      "<td>$sum</td><td>$dsc</td><td>$ww</td><td>$adm_ip</td><td>$last_deposit</td></tr>\n";
    $sum_total += $sum;
   }  
 print "<tr bgcolor=$_BG3><th>$_TOTAL:</th><th colspan=6 align=right>$sum_total</th><td colspan=2>&nbsp</td></tr>\n".
 "</table>\n".
 "</td></tr></table>\n";
}



#*******************************************************************
#show stats
# stats()
#*******************************************************************
sub stats  {

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
  <tr bgcolor=$_BG0><th>$_LOGIN</td><th>$_DURATION</th><th>$_VARIANT</th><Th>$_SENT</Th><Th>$_RECV</th><th>CID</th><th>IP</th><th>$_SUM</th><th>-</th></tr>\n".
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

    $out_tr = "<tr bgcolor=$bg><td>$ltime ($rows)</td><td>$duration</td><td>$variant</td>
        <TD>$sent</TD><TD>$recv</td><td>$CID</td><td>$ip</td><th>$sum</th><th>(<a href='$SELF?op=sdetail&sid=$sid&uid=$uid' title='Session detalization'>D</a>)</th></tr>\n";

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
       message('err', "$_ERROR", "$_NOT_EXIST [$uid]");
       return 0;
     };
   
   ($login, $fio, $address, $email, $registartion, $variant, $credit, $deposit, $phone, $simultaneously, $activate, $expire, 
      $last_login, $reduction, $ip, $netmask, $speed, $filter_id, $cid, $comments) = $q -> fetchrow();

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
      <li><a href='$SELF?op=errlog&uid=$uid'>$_ERROR_LOG</a>
     </td></tr>
     <tr><td> 
      <br><b>$_CHANGE</b>
      <li><a href='$SELF?op=users&uid=$uid&passwd=chg'>$_PASSWD</a>
      <li><a href='$SELF?op=chg_uvariant&uid=$uid'>$_VARIANT</a>
     </td></tr>
     </table>

     </td></tr></table>\n";
    
   }
 else {
   user_list();
  }


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
#show error log
# errlog
#*******************************************************************
sub errlog {
  print "<h3>$_ERROR_LOG</h3>\n";

  print "<table><tr><td>";
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
    if(chg_uvariant($uid, $old_variant, $new_variant) == 1) {
      message('info', $_CHANGED, "$message"); 	
      $old_variant=$new_variant;
     } 
    else {
      message('err', $_ERROR, "Exist ");
     }
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
# Admin authentification
# auth()
#*******************************************************************
sub auth {
 my ($login, $password) = @_;

$q = $db -> prepare("SELECT id, password   FROM admins WHERE id='$login' and password=ENCODE('$password', '$conf{secretkey}');")   || die $db->strerr;
$q -> execute ();
if ($q->rows < 1 )  {
	return 1;
}
  my ($id, $password) = $q -> fetchrow();
	return 0;
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
<form action=$SELF METHOD=POST>
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



sub login_form {
	

print << "[END]"
<form action=$SELF_URL>
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
</form>
[END]

}
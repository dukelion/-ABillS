use Abwconf;

my $tpl_path=$path . 'templates/';
my $base_template=$path .'';

# Set type of templates
my $expire_time = 7; # Expiration time of document. Count in days.
my @units=('-', 'шт.');
my @templates_type=('account');
my @MONTHES_LIT=('січня', 'лютого', 'березня', 'квітня', 'травня', 'червня', 'липня', 'серпня', 
 'вересня', 'жовтня', 'листопада', 'грудня');
my @orders = ('Інтернет послуги');
my %TPL_INFO=();


#*******************************************************************
# Parameters
#  get_params()
#*******************************************************************
sub get_params() {
my %CONFIG=();

my $sql = "SELECT param, value FROM config;";
log_print('LOG_SQL', $sql);

my $q = $db->prepare($sql) || die $db->strerr;
$q ->execute();

while(my ($param, $value)=$q->fetchrow()) {
  $CONFIG{"$param"}="$value";
 }

}


#*******************************************************************
# Parameters
#  params()
#*******************************************************************
sub params {
if($FORM{add}) {
  my  $sql = "INSERT INTO config (param, value) VALUES (\"$FORM{param}\", \"$FORM{value}\");";
  my  $q = $db->do($sql);
    
  if ($db->err == 1062) {
    message('err', '$_ERROR', '$_EXIST');
   }
  elsif($db->err > 0) {
    message('err', "$_ERROR", $db->errstr . " - N:". $db->err);
   }
  else {
    my $msg = "<table width=100%>
       <tr><td>$_PARAM</td><td>$FORM{param}</td></tr>
       <tr><td>$_VALUE</td><td>$FORM{value}</td></tr>
       </table>\n";
    	
    message('info', "$_ADDED", "$msg");
   }
}
elsif($FORM{change}) {
  my $q = $db->do("UPDATE config SET ;") || die $db->errstr;
  message('info', "$_DELETED", "$param");
}
elsif($FORM{del}) {
   my $q = $db->do("DELETE from config WHERE param='$FORM{param}';") || die $db->errstr;
   message('info', "$_DELETED", "$param");
}

get_params();

print "<form action='$SELF'>
<input type=hidden name=docs value=params>
<table width=400 border=1>
<tr><td>$_PARAM:</td><td colspan=2><input type=text name=param value=\"$param\"></td></tr>
<tr><td>$_VALUE:</td><td colspan=2><input type=text name=value value=\"$value\"></td></tr>
<tr><td colspan=3><input type=submit name=add value=\"$_ADD\"></td></tr>\n";

while(my($k, $v)=each %CONFIG) {
  print "<tr><td>$k</td><td>$v</td>\n".
   "<td><a href='$SELF?docs=docs&del=$k'>$_DEL</a></td></tr>\n";
}

print "</table>
</form>\n";

}

#*******************************************************************
# Make account
# mk_acct()
#*******************************************************************
sub mk_acct {

if ($FORM{doc_id} eq $cookies{doc_id}) {
  message('err', "$_ERROR", "$_ACCOUNT_EXIST");
  return 0;	
 }

    my $counts = $FORM{counts} || 1;
    my $unit = $FORM{unit} || 0;
    $FORM{customer} =~ s/\^/\\\"/g;
    
    my $maked = $admin_name || $uid;
    my $uid = $FORM{uid};
    my $acct_id = 0;
    
    my $date =  ($FORM{date} ne '') ? "'$FORM{date}'" : "now()";
     
    if ($FORM{aid}) {
      $aid=$FORM{aid};	
     }
    else {
      my $sql = "SELECT aid FROM docs_acct WHERE YEAR(date)=YEAR($date) ORDER BY aid DESC LIMIT 1;";
      log_print('LOG_SQL', $sql);
      my $q = $db->prepare($sql) || die $db->strerr;
      $q ->execute();
      ($aid) = $q->fetchrow();
      $aid++;
     }

    $sql ="insert into docs_acct (aid, date, time, customer, phone, maked, uid)
      values ('$aid', $date, now(), \"$FORM{customer}\", \"$FORM{phone}\", \"$maked\", \"$uid\");";
    log_print('LOG_SQL', $sql);
 
    my $q = $db->do($sql) || die $db->errstr;
    $sql = "INSERT INTO acct_orders (aid, orders, counts, unit, price)
      values (LAST_INSERT_ID(), \"$orders[$FORM{orders}]\", '$counts', '$unit', '$FORM{sum}')";
    log_print('LOG_SQL', $sql);
    
    $q = $db->do($sql) || die $db->errstr;

    $sql = "select last_insert_id() from docs_acct;";
    log_print('LOG_SQL', $sql);
    my $q = $db->prepare($sql) || die $db->strerr;
    $q ->execute();
    my($did) = $q->fetchrow();
    message('info', "$_INFO", "$_CREATED <a href='$SELF?docs=print&d=account&id=$did' target=_new>$_PRINT</a>");
}

#*******************************************************************
#accounts
# accounts($uid)
#*******************************************************************
sub accounts  {
 my ($uid, $login) = @_;
 my $WHERE = '';

 print "<h3>$_ACCOUNTS</h3>\n";

 if ($FORM{create}) {
   if ($FORM{sum} < 0.01) {
     message('err', "$_ERROR", "Вкажіть суму");
    }
   elsif(! $FORM{uid}) {
     message('err', "$_ERROR", "$_SELECT_USER");
    }
   elsif(! $FORM{customer}) {
     message('err', "$_ERROR", "Подайте назву організації");
    }
   else {
     mk_acct();
    }
  }
 elsif($FORM{del}) {
   my $sql = "DELETE FROM acct_orders WHERE aid='$FORM{del}'";
   log_print('LOG_SQL', $sql);
   my $q = $db->do($sql) || die $db->errstr;

   $sql = "DELETE FROM docs_acct WHERE id='$FORM{del}'";
   log_print('LOG_SQL', $sql);
   $q = $db->do($sql) || die $db->errstr;
   message('info', "$_INFO", "$_DELETED N: [$FORM{del}]");
  }

  make_acct_doc();

  if ($uid > 0) {
    $WHERE = " and d.uid='$FORM{uid}'";
    print "$_USER: <a href='users.cgi?op=users&uid=$uid'>$login</a><br>";
   }

  my %pages = pages('d.id', 'docs_acct d, acct_orders o', "WHERE d.id=o.aid $WHERE", "docs=accts");  

  print "$_TOTAL: $pages{count}<br>\n";
  
  $sql = "SELECT d.aid, d.id, d.date, d.customer,  sum(o.price * o.counts), u.id, d.maked, d.time, d.uid
    FROM docs_acct d, acct_orders o
    LEFT JOIN users u ON (d.uid=u.uid)
    WHERE d.id=o.aid $WHERE
    GROUP BY d.id 
    ORDER BY $sort $desc;";

  log_print('LOG_SQL', $sql);

  my $q = $db->prepare($sql) || die $db->strerr;
  $q ->execute();

  print "<TABLE width=99% cellspacing=0 cellpadding=0 border=0>
  <tr><TD bgcolor=$_BG4>
  <TABLE width=100% cellspacing=1 cellpadding=0 border=0>\n";
  my @caption = ("#", "$_DATE", "$_CUSTOMER", "$_SUM", "$_USER", "$_ADMINS", "$_TIME", "-", "-");  
  show_title($sort, $desc, "$pg", "&docs=accts&uid=$uid", \@caption);
 
#          d.id, d.date, d.customer,  sum(o.price * o.counts), d.user, d.maked, d.time
   my $bg = '';
   while(my($aid, $id, $date, $customer,  $sum, $login, $creator, $time, $uid) = $q->fetchrow()) {
      $bg = ($bg eq $_BG1) ? $_BG2 : $_BG1;
      print "<tr bgcolor=$bg><td>$aid</td><td>$date</td>
       <td>$customer</td><td align=right>$sum</td><td><a href='users.cgi?op=users&uid=$uid'>$login</a></td>
       <td>$creator</td><td>$time</td><td><a href='$SELF?docs=accts&del=$id'>$_DEL</a></td><td><a href='docs.cgi?docs=print&d=account&id=$id' target=_new>$_PRINT</a></td></tr>\n";
     }

 print "</table></td></tr></table>\n";
 print $pages{pages};
}

#*******************************************************************
# show user accounts
# show_user_accounts($uid)
#*******************************************************************
sub show_user_accounts {
 my $uid = shift;

  my %pages = pages('d.id', 'docs_acct d, acct_orders o', "WHERE d.id=o.aid and user='$uid'", "docs=accts");  

  print "$_TOTAL: $pages{count}<br>\n";
  
  $sql = "SELECT d.aid, d.id, d.date, d.customer,  sum(o.price * o.counts)  
    FROM docs_acct d, acct_orders o
    WHERE d.id=o.aid and d.uid='$uid'
    GROUP BY d.id 
    ORDER BY $sort $desc;";
 
  log_print('LOG_SQL', "$sql");
  my $q = $db->prepare($sql) || die $db->strerr;
  $q ->execute();

  print "<TABLE width=640 cellspacing=0 cellpadding=0 border=0>
  <tr><TD bgcolor=$_BG4>
  <TABLE width=100% cellspacing=1 cellpadding=0 border=0>\n";

  my @caption = ("#", "$_DATE", "$_CUSTOMER", "$_SUM", '-');
  show_title($sort, $desc, "$pg", "&docs=accts", \@caption);

  my $bg = '';
  while(my($acct_id, $id, $date, $customer,  $sum, $time) = $q->fetchrow()) {
    $bg = ($bg eq $_BG1) ? $_BG2 : $_BG1;
    print "<tr bgcolor=$bg><td>$acct_id</td><td>$date</td><td>$customer</td><td align=right>$sum</td>".
      "<th><a href='$SELF?docs=print&d=account&id=$id' target=_new>$_PRINT</th></tr>\n";
   }
 print "</table>\n</td></tr></table>\n";
 print $pages{pages};
}

#*******************************************************************
# make account docs
# make_acct_doc()
#*******************************************************************
sub make_acct_doc {

if ($FORM{pre}) {
  if ($FORM{sum} < 0.01) {
    message('err', "$_ERROR", "Вкажіть суму");
   }
  elsif(! $FORM{uid}) {
    message('err', "$_ERROR", "$_SELECT_USER");
   }
  elsif(! $FORM{customer}) {
    message('err', "$_ERROR", "Подайте назву організації");
   }
  else {
    my $count = $FORM{count} || 1;
    my $unit = $FORM{unit} || '-';
    my $date = $FORM{date} || strftime("%Y-%m-%d", localtime(time));
    $TPL_INFO{NUM}=$FORM{aid} if ($FORM{aid});

    use POSIX qw(strftime);
#  my %TPL_INFO = ();
    $TPL_INFO{CUSTOMER}=$FORM{customer};
    $TPL_INFO{PHONE}=$FORM{phone};
    $TPL_INFO{SUM}=$FORM{sum};
  
    $TPL_INFO{DATE}=$date;
    $TPL_INFO{ORDER}= "<tr><td align=right>1</td><td>$orders[$FORM{orders}]</td><td align=center>$unit</td><td align=right>$count</td><td  align=right>$FORM{sum}</td><td  align=right>$FORM{sum}</td></tr>".
                   "<tr><td align=right colspan=2 rowspan=3>&nbsp;</td><td colspan=2>Разом без ПДВ</td><td  colspan=2 align=right>$FORM{sum}</td></tr>".
                   "<td colspan=2>ПДВ:</td><td  colspan=2 align=right>-</td></tr>".
                   "<td colspan=2>Всього з ПДВ:</td><td colspan=2 align=right>$FORM{sum}</td></tr>";

    $TPL_INFO{EXPIRE_DATE}=strftime("%d.%m.%Y", localtime(time  + 86400 * $expire_time ));
    $mn = strftime("%m", localtime(time)) -1;
    my $date_lit = strftime "%d ". @MONTHES_LIT[$mn] ." %Y р.", localtime(time);
    $TPL_INFO{FROM_LIT_DATE}="$date_lit";
#  require "i2s.pl";
    $TPL_INFO{SUM_LITERAL} = int2ml("$FORM{sum}");
    $document = get_template('account');
    print "<table border=0><tr><td>";
    print $document;
    print "</td></tr></table>";
  
    $FORM{customer} =~ s/"/^/g;
    # "<input type=hidden name=doc_id value='$FORM{doc_id}'>\n".  
    print "<form action=$SELF target=_blank>\n".
        "<table width=640><tr><td bgcolor=$_BG0 align=center>\n".
        "<input type=hidden name=docs value=accts>\n".
        "<input type=hidden name=aid value='$FORM{aid}'>\n".
        "<input type=hidden name=date value='$date'>\n".
        "<input type=hidden name=uid value=$uid>\n".
        "<input type=hidden name=customer value=\"$FORM{customer}\">\n".
        "<input type=hidden name=phone value=$FORM{phone}>\n".
        "<input type=hidden name=orders value=$FORM{orders}>\n".
        "<input type=hidden name=sum value=$FORM{sum}>\n".
        "<input type=submit name=create value=\"$_CREATE\">\n".
        "</td></tr></table>\n".
        "</form>\n";
  }
}
else {
  my $doc_id=mk_unique_value(15);

print << "[END]";
<form action=$SELF method=post>
<input type=hidden name=docs value=accts>
<input type=hidden name=uid value=$uid>
<input type=hidden name=doc_id value="$doc_id">
<Table>
[END]

  if (defined($admin_name)) {
     my $sql = "SELECT count(*), max(aid) FROM docs_acct WHERE date=YEAR(curdate());";
     my $q = $db->prepare($sql) || die $db->strerr;
     $q ->execute();
     my ($last_acct_num, $total_acct) = $q->fetchrow();
     print "<tr><td>$_TO_USER:</td><td>$login</td></tr>\n".
       "<tr><td>N:</td><td><input type=text name=aid value='$acct_aid'></td></tr>\n".
       "<tr><td>$_DATE:</td><td><input type=text name=date value='$date'></td></tr>\n";
   }

print << "[END]";
<tr><td>$_CUSTOMER:</td><td><input type=text name=customer></td></tr>
<tr><td>$_PHONE:</td><td><input type=text name=phone></td></tr>
<tr><td>$_ORDER:</td><td><select name=order>
[END]

  my $i=0;
  foreach my $line (@orders) {
    print "<option value=$i>$line\n";
    $i++;
   }

print << "[END]";
</select></td></tr>
<tr><td>$_SUM:</td><td><input type=text name=sum value='$sum'></td></tr>
</table>
<!-- <input type=submit name=pre value="$_PRE">  -->
<input type=submit name=create value="$_CREATE">
</form>
[END]

}

}

#*******************************************************************
# TEMPLATE creation
# templates($type)
#*******************************************************************
sub templates  {
  my ($attr) = @_;
  
  my $tpl_path = ($attr->{PATH}) ? $attr->{PATH} . $tpl_path  : $tpl_path;
  
  my $template = '';
  
  
  print "<h3>$_TEMPLATES</h3>\n";

if ($FORM{add}) {
  open(FILE, ">$tpl_path/$FORM{show}.tpl") || "Can't open file '$tpl_path/$FORM{show}.tpl' $!\n";
   print FILE "$FORM{template}\n";
  close(FILE);
}
elsif($FORM{show}) {
 if ( -e "$tpl_path/$FORM{show}.tpl" ) {
    print "<p><b>$_FILE:</b> $tpl_path$FORM{show}.tpl";
    
    open(FILE, "<$tpl_path/$FORM{show}.tpl") || "Can't open file '$tpl_path/$FORM{show}.tpl' $!\n";
      while (<FILE>) {
          $template .= $_;
       }
    close(FILE);
  }
 else {
    message('info', _INFO, "$_NOT_EXIST '$tpl_path/$FORM{show}.tpl'");
   }
}


print "<FORM action=$SELF METHOD=POST>
<input type=hidden name=show value=$FORM{show}>
<input type=hidden name=docs value=templates>
<table border=1>
<tr><th bgcolor=$_BG0>$FORM{show}</th></tr>
<tr><td><textarea name=template cols=100 rows=24>$template</textarea></td></tr>
</table>
<input type=submit name=add value=\"$_ADD\">
</form>\n";


print "<Table width=400 border=0>\n".
  "<tr bgcolor=$_BG0><th>$_NAME</th><th>$_FILE</th><th>$_SIZE</th><th>$_DATE</th></tr>\n";

  use POSIX qw(strftime);
  my $filename = '';
  foreach my $line (@templates_type) {
    $filename = "$tpl_path/$line.tpl";

    if ( -e $filename ) {
      ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks)=stat("$filename");
      $date = strftime "%Y-%m-%d %H:%M:%S", localtime($mtime);
     }
    else {
      my $size = 0;
      my $date = '-';
     }

    my $bg = ($bg eq $_BG1) ? $_BG2 : $_BG3;
    $size = int2byte($size);
    print "<tr><td><a href='$SELF?docs=templates&show=$line'>$line</a></td>".
      "<td>$filename</td><td align=right>$size</td><td>$date</td></tr>\n";
   }
print "</table>\n";

}

#*******************************************************************
# Template parser
# get_template($template_name)
#*******************************************************************
sub get_template  {
 my $template_name = shift;

# if (! -e $tpl_path.$template_name.".tpl") {
#    message('err', "$_ERROR", "$_NOT_EXIST");	
#    return 0;
#  }

 my $document = '';
 open(FILE, "<".$tpl_path.$template_name.".tpl") || die "Can't openfile " .$tpl_path.$template_name;
  while(<FILE>)  {
     $document .= $_;
   }
 close(FILE);

 while(($k, $v)=each %TPL_INFO) {
    $document =~ s/\%$k\%/$v/g;
  }
 return $document;
}


#*******************************************************************
# Print version
# print_version($doc)
#*******************************************************************
sub print_version  {
  my $doc = shift;
  if($doc eq 'account') {

  my $sql = "SELECT d.aid, d.customer, d.phone, DAYOFMONTH(d.date), MONTH(d.date), YEAR(d.date), 
     DATE_FORMAT(DATE_ADD(d.date, INTERVAL $expire_time DAY), '%d.%m.%Y'), d.maked, sum(o.price * o.counts), counts, o.unit, o.orders
    FROM docs_acct d, acct_orders o
    WHERE d.id=o.aid and d.id=$FORM{id}
    GROUP BY d.id;";
  log_print('LOG_SQL', $sql);
  
  my $q = $db->prepare($sql) || die $db->strerr;
  $q ->execute();
  
  my ($acct_id, $customer, $phone, $day, $month, $year, $expire, $maker, $sum, $count, $unit, $order) = $q->fetchrow();

#  my %TPL_INFO=();
  $TPL_INFO{NUM}=$acct_aid;
  $TPL_INFO{CUSTOMER}=$customer;
  $TPL_INFO{PHONE}=$phone;
  $TPL_INFO{SUM}=$sum;
  $TPL_INFO{DATE}=sprintf("%.2d-%.2d-%d", $day, $month, $year);
  $TPL_INFO{ORDER}="<tr><td align=right>1</td><td>$order</td><td align=center>$units[$unit]</td><td align=right>$count</td><td  align=right>$sum</td><td  align=right>$sum</td></tr>".
                   "<tr><td align=right colspan=2 rowspan=3>&nbsp;</td><td colspan=2>Разом без ПДВ</td><td  colspan=2 align=right>$sum</td></tr>".
                   "<td colspan=2>ПДВ:</td><td  colspan=2 align=right>-</td></tr>".
                   "<td colspan=2>Всього з ПДВ:</td><td colspan=2 align=right>$sum</td></tr>";
  $TPL_INFO{EXPIRE_DATE}=$expire;
  $month--;
  my $date = "$day ". @MONTHES_LIT[$month] ." $year р.", localtime(time);
  $TPL_INFO{FROM_LIT_DATE}="$date";
#  require "i2s.pl";
  $TPL_INFO{SUM_LITERAL} = int2ml("$sum");
  $TPL_INFO{SIGNATURE} = "$path". "img.cgi?signature";
  $TPL_INFO{STAMP} = "$path". "img.cgi?stamp";

    $document = &get_template("$doc");
   }
  print $document;
}


#*******************************************************************
# form parser without teg conversion
# form_parse2()
#*******************************************************************
sub form_parse2  {
 my $buffer = '';
if ($ENV{'REQUEST_METHOD'} eq "GET") {
  $buffer= $ENV{'QUERY_STRING'};
 } elsif ($ENV{'REQUEST_METHOD'} eq "POST") {
  read(STDIN, $buffer, $ENV{'CONTENT_LENGTH'});
 }

my @pairs = split(/&/, $buffer);
foreach my $pair (@pairs) {
   my ($side, $value) = split(/=/, $pair);
   $value =~ tr/+/ /;
   $value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
#   $value =~ s/<!--(.|\n)*-->//g;
#   $value =~ s/<([^>]|\n)*>//g;
   $FORM{$side} = $value;
 }
 return %FORM;
}



=commnets
%SIGNATURE%
<p class=MsoNormal style='margin-left:50.4pt'><span style='position:absolute;
z-index:-1;left:0px;margin-left:549px;margin-top:-50px;width:85px;height:85px'><img
width=85 height=85 src="%SIGNATURE%"></span></p>

%STAMP%
<span style='position:absolute;z-index:-2;left:0px;margin-left:450px;margin-top:10px;width:124px;height:124px'>
<img width=124 height=124 src="%STAMP%">
</span>


=cut

1;
#!/usr/bin/perl
#Windows Dialup Error codes and solution

my $err_id = $FORM{err_id};

print "<h3>$_DUNES</h3>\n";

win_dunes();

if ($err_id > 0) {
   show_solution($err_id);
 } 
else {
   quick_show();  
 }


#*******************************************************************
# win_dunes()
#*******************************************************************
sub win_dunes {
 my $err_id=$FORM{err_id};

#if ($FORM{add}) {
#  $sql= '';
#}
#elsif(FORM{change}) {
#  $sql='';	
#}

print "<FORM ACTION=$SELF>
<input type=hidden name=op value=dunes>
<table>
<tr><td>$_ERROR</td><td><input type=text name=err_id value='$err_id'></td></tr>
</table>
<input type=submit name='$_SHOW'>
</form>\n";

}

#*******************************************************************
# show_solution($err_id)
#*******************************************************************
sub show_solution {
  my $err_id = shift;

  $sql="SELECT err_id, win_err_handle, translate, error_text, solution 
     FROM dunes WHERE err_id='$err_id';";
  log_print('LOG_SQL', "$sql");

  $q = $db->prepare($sql) || die $db->strerr;
  $q ->execute();
  
  if ($q->rows == 0) {
     message('err', "$_ERROR", "$_NOT_EXIST");
     return 0;
   }
  
  my ($err_id, $win_err_handle, $translate, $error_text, $solution)=$q -> fetchrow();

print << "[END]";
<table width=400 border=0 cellpadding="0" cellspacing="0">
<tr><td bgcolor=#00000>
<table width=100% border=0 cellpadding="2" cellspacing="1">
<tr><td bgcolor=FFFFFF>

<table width=100%>
<tr><th bgcolor=$_BG0><b>($err_id)</b> $error_text<hr size=1>$translate</th></tr>
<tr><td bgcolor=FFFFFF>$en_err</td></tr>
<tr><td bgcolor=FFFFFF>$solution</td></tr>
</table>

</td></tr>
</table>
</td></tr>
</table>
[END]
}


#*******************************************************************
# quick_show()
#*******************************************************************
sub quick_show {
  $sql="SELECT err_id, win_err_handle, translate, error_text, solution  FROM dunes;";
  log_print('LOG_SQL', $sql);

  print "<TABLE width=640 cellspacing=0 cellpadding=0 border=0>
   <tr><TD bgcolor=$_BG4>
   <TABLE width=100% cellspacing=1 cellpadding=0 border=0>\n";
  $q = $db->prepare($sql) || die $db->strerr;
  $q ->execute();
  while(my ($err_id, $win_err_handle, $translate, $error_text, $solution)=$q -> fetchrow()) {
     $bg=($bg eq $_BG1)? $_BG2 : $_BG1;
     print "<tr bgcolor=$bg><td><a href='$SELF?op=dunes&err_id=$err_id'>$err_id</a></td><td>$error_text</td><td>$translate</td></tr>\n";
    }
  print "</table>\n</td></tr></table>\n";
}



1
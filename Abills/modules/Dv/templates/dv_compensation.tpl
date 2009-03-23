<form action='$SELF_URL' method='post'>
<input type=hidden name='index' value='$index'>
<input type=hidden name='UID' value='$FORM{UID}'>
<table width=420 cellspacing='0' cellpadding='3'>
<tr><th colspan=2 bgcolor=$_COLORS[0] align=right>$_COMPENSATION</th></tr>
<tr><td>$_FROM:</td><td>%FROM_DATE%</td></tr>
<tr><td>$_TO:</td><td>%TO_DATE%</td></tr>
<tr><td>$_DESCRIBE:</td><td><input type='text' name='DESCRIBE'  value='%DESCRIBE%' size=50>
<tr><td>$_INNER $_DESCRIBE:</td><td><input type='text' name='INNER_DESCRIBE' value='%INNER_DESCRIBE%' size=50>
</table>
<input type=submit name='add' value='$_COMPENSATION' class='noprint'>
</form>

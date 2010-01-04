<form action=$SELF_URL METHOD=GET name=holdup>
<input type=hidden name=index value=$index>
<input type=hidden name=sid value=$sid>
<input type=hidden name=UID value=$FORM{UID}>
<table width=300>
<tr><th colspan=2 class=table_title align=right>$_HOLD_UP</th></tr>
<tr><td>$_FROM:</td><td>%DATE_FROM%</td></tr>
<tr><td>$_TO:</td><td>%DATE_TO%</td></tr>
</table>
<input type=submit value='$_HOLD_UP' name='add'>
</form>
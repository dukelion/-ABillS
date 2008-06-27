<form action='$SELF_URL' METHOD='POST' TARGET=New>
<input type='hidden' name='qindex' value='$index'>
<input type='hidden' name='UID' value='$FORM{UID}'>
<input type='hidden' name='sid' value='$sid'>
<table width=600>
<tr bgcolor='$_COLORS[0]'><th colspan=2 align=right>$_ICARDS</th></tr>
<tr><td>$_COUNT:</td><td><input type='text' name='COUNT' value='%COUNT%'></td></tr>
<tr><td>$_SUM:</td><td><input type='text' name='SUM' value='%SUM%'></td></tr>
<!-- <tr><td>$_PASSWD:</td><td><input type='password' name='PASSWORD'</td></tr> --!>
</table>
<input type='submit' name='add' value='$_ADD'>
</form>

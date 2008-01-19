<form action='$SELF_URL' METHOD='POST'>
<input type='hidden' name='sid' value='$FORM{sid}'>
<input type='hidden' name='index' value='$index'>
<input type='hidden' name='UID' value='$FORM{UID}'>
<table>
<tr><th bgcolor='$_COLORS[0]' colspan='2'>$_ICARDS</th></tr>
<tr><td>$_SERIAL:</td><td><input type='text' name='SERIAL' value='%SERIAL%'></td></tr>
<tr><td>PIN:</td><td><input type='text' name='PIN'></td></tr>
</table>
<input type='submit' name='add' value='$_ADD'>
</form>

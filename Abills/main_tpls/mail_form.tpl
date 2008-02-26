<form action='$SELF_URL' METHOD='post'>
<input type='hidden' name='index' value='$index'>
<input type='hidden' name='UID' value='$FORM{UID}'>
<table>
%EXTRA%
<tr><td>$_SUBJECT:</td><td><input type='text' name='SUBJECT' value='%SUBJECT%' size='40'></td></tr>
<tr><td>$_FROM:</td><td><input type='text' name='FROM' value='%FROM%' size='40'></td></tr>
<tr><th colspan='2' bgcolor='$_COLORS[0]'>$_MESSAGE</th></tr>
<tr><th colspan='2'><textarea name='TEXT' rows='15' cols='80'></textarea></th></tr>
<tr><td>PRIORITY:</td><td>%PRIORITY_SEL%</td></tr>
%PERIOD_FORM%
%EXTRA2%
</table>
<input type='submit' name='sent' value='$_SEND'>
</form>

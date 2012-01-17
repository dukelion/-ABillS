<form action='$SELF_URL' METHOD='POST' ENCTYPE='multipart/form-data'>
<input type='hidden' name='index' value='$index'>

<table>
<tr bgcolor='$_COLORS[0]'><th colspan=2>$_SERIAL:</th></tr>
<tr><td>$_SERIAL:</td><td><input type='text' name='SERIAL' value='%SERIAL%'></td></tr>
<tr><td>$_BEGIN:</td><td><input type=text name='BEGIN' value='%BEGIN%'></td></tr>
<tr><td>$_COUNT:</td><td><input type=text name='COUNT' value='%COUNT%'></td></tr>

<!-- Card type payment or service -->
%CARDS_TYPE%
<!-- Card type payment or service end -->

<tr bgcolor='$_COLORS[0]'><th colspan=2>$_PASSWD / PIN</th></tr>
<tr><td>$_SYMBOLS:</td><td><input type='text' name='PASSWD_SYMBOLS' value='%PASSWD_SYMBOLS%'></td></tr>
<tr><td>$_SIZE:</td><td><input type='text' name='PASSWD_LENGTH' value='%PASSWD_LENGTH%'></td></tr>
<tr><td colspan=2>&nbsp;
%EXPARAMS%
</td></tr>
<tr bgcolor='$_COLORS[0]'><th colspan=2>&nbsp;</th></tr>
<tr><td>$_EXPIRE:</td><td><input type='text' name='EXPIRE' value='%EXPIRE%'> Text<br>
<tr bgcolor='$_COLORS[0]'><th colspan=2>$_EXPORT:</th></tr>
<tr><td colspan='2'><input type='radio' name='EXPORT' value='TEXT'> Text<br>
<input type='radio' name='EXPORT' value='XML'> XML<br>
</td></tr>
<tr bgcolor='$_COLORS[0]'><th colspan=2>-</th></tr>
<tr><td>$_DILLERS:</td><td>%DILLERS_SEL%</td></tr>
</table>
<input type='submit' name='create' value='$_CREATE'>
</form>

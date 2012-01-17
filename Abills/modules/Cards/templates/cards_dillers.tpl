<form action='$SELF_URL' METHOD='POST'>
<input type='hidden' name='index' value='$index'>
<input type='hidden' name='chg' value='$FORM{chg}'>
<table>
<tr><td>$_NAME:</td><td><input type='text' name='NAME' value='%NAME%'></td></tr>
<tr><td>$_ADDRESS:</td><td><input type='text' name='ADDRESS' value='%ADDRESS%'></td></tr>
<tr><td>$_PHONE:</td><td><input type='text' name='PHONE' value='%PHONE%'></td></tr>
<tr><td>E-Mail:</td><td><input type='text' name='EMAIL' value='%EMAIL%'></td></tr>
<tr><td>$_PERCENTAGE:</td><td><input type='text' name='PERCENTAGE' value='%PERCENTAGE%'></td></tr>
<tr><td>$_DISABLE:</td><td><input type='checkbox' name='DISABLE' value='1' %DISABLE%></td></tr>
<tr><th colspan='2'>$_COMMENTS</th></tr>
<tr><th colspan='2'><textarea name='COMMENTS' cols='60' rows='6'>%COMMENTS%</textarea></th></tr>
</table>
<input type='submit' name='%ACTION%' value='%LNG_ACTION%'>
</form>

<FORM action='$SELF_URL' METHOD='POST'>
<input type='hidden' name='index' value='$index'>
<input type='hidden' name='ID' value='$FORM{ID}'>
<table>
<tr><td>$_NAME</td><td><input type='text' name='NAME' value='%NAME%'></td></tr>
<tr><td>$_ORIGIN_NAME</td><td><input type='text' name='ORIGIN_NAME' value='%ORIGIN_NAME%'></td></tr>
<tr><th colspan=2>$_BIO</th></tr>
<tr><th colspan=2><textarea cols='60' rows='6' name='BIO'>%BIO%</textarea></th></tr>
</table>
<input type='submit' name='%ACTION%' value='%LNG_ACTION%'>
</FORM>

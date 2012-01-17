<form action='$SELF_URL' method='post' name='docs_user'>
<input type=hidden name=index value=$index>
<input type=hidden name='UID' value='$FORM{UID}'>
<input type=hidden name='sid' value='$FORM{sid}'>
<table>
<tr><th align=right class='form_title' colspan=2>$_DOCS</th></tr>
<tr><td>$_MONTH $_DOCS:</td><td><input type=checkbox name=PERIODIC_CREATE_DOCS value=1 %PERIODIC_CREATE_DOCS%></td></tr>
<tr><td>$_SEND:</td><td><input type=checkbox name=SEND_DOCS value=1 %SEND_DOCS%></td></tr>
<tr><td>E-mail:</td><td><input type=text name=EMAIL value='%EMAIL%'></td></tr>
<tr><th colspan=2>$_COMMENTS</th></tr>
<tr><td colspan=2><textarea name=COMMENTS rows=6 cols=60>%COMMENTS%</textarea></td></tr>
</table>
<input type=submit name=%ACTION% value='%LNG_ACTION%'>
</form>

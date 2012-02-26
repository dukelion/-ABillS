<form action='$SELF_URL' METHOD='POST'>
<input type=hidden name=index value=$index>
<input type=hidden name=MAIL_DOMAIN_ID value=%MAIL_DOMAIN_ID%>
<table class=form>
<tr><th class=form_title colspan=2>E-mail domains</th></tr>
<tr><td>$_DOMAIN:</td><td><input type=text name=DOMAIN value='%DOMAIN%' size=40></td></tr>
<tr><td>$_TRANSPORT:</td><td>%TRANSPORT_SEL%</td></tr>
<tr><td>Backup MX:</td><td><input type=checkbox name=BACKUP_MX value='1' %BACKUP_MX%></td></tr>
<tr><td>$_DISABLE:</td><td><input type=checkbox name=DISABLE value='1' %DISABLE%></td></tr>
<tr><th colspan=2>:$_COMMENTS:</th></tr>
<tr><th colspan=2><textarea name=COMMENTS cols=40 rows=5>%COMMENTS%</textarea></th></tr>
<tr><th class=even colspan=2><input type=submit name=%ACTION% value='%LNG_ACTION%'></th></tr>
</table>

</form>

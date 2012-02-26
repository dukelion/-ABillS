
<form action='$SELF_URL' METHOD='POST'>
<input type=hidden name='index' value='$index'>
<input type=hidden name='MAIL_ALIAS_ID' value='%MAIL_ALIAS_ID%'>
<table class=form>
<tr><td>$_ADDRESS:</td><td><input type=text name=ADDRESS value='%ADDRESS%'></td></tr>
<tr><td>GOTO:</td><td><input type=text name=GOTO value='%GOTO%'></td></tr>
<tr><td>$_DISABLE:</td><td><input type=checkbox name=DISABLE value='1' %DISABLE%></td></tr>
<tr><th colspan=2>$_COMMENTS:</th></tr>
<tr><th colspan=2><textarea name=COMMENTS cols=40 rows=5>%COMMENTS%</textarea></th></tr>
<tr><th class=even colspan=2><input type=submit name=%ACTION% value='%LNG_ACTION%'></th></tr>
</table>

</form>

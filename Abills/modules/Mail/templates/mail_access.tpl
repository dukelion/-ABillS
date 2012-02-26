<form action='$SELF_URL'>
<input type=hidden name='index' value='$index'>
<input type=hidden name=MAIL_ACCESS_ID value=%MAIL_ACCESS_ID%>
<table class=form>
<tr><td>$_VALUE:</td><td><input type=text name=PATTERN value='%PATTERN%'></td></tr>
<tr><td>$_PARAMS:</td><td>%ACCESS_ACTIONS%
$_ERROR:<input type=text name=CODE value='%CODE%' size=4> $_MESSAGE:<input type=text name=MESSAGE value='%MESSAGE%'></td></tr>
<tr><td>$_DISABLE:</td><td><input type=checkbox name=DISABLE value='1' %DISABLE%></td></tr>
<tr><th colspan=2>$_COMMENTS:</th></tr>
<tr><th colspan=2><textarea name=COMMENTS cols=40 rows=5>%COMMENTS%</textarea></th></tr>
<tr><th class=even colspan=2><input type=submit name=%ACTION% value='%LNG_ACTION%'></th></tr>
</table>
</form>

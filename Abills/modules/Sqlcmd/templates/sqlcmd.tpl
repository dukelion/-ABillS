<form action='$SELF_URL' METHOD=POST>
<input type=hidden name=index value=$index>
<table>
<tr><th colspan=2>SQL QUERY:</th><tr>
<tr><th colspan=2><textarea name='QUERY' cols=70 rows=10>%QUERY%</textarea></th><tr>
<tr><td>$_ROWS:</td><td><input type=text name='ROWS' value='%ROWS%'></td></tr>
<tr><td>XML:</td><td><input type=checkbox name='xml' value='1'></td></tr>
</table>
<input type=submit name=show value='QUERY'>
</form>

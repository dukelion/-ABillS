<form action='$SELF_URL' METHOD=POST>
<input type=hidden name=index value=$index>
<input type=hidden name=HOST_ID value='$FORM{HOST_ID}'>
<table width=95% class=form>
<tr><th colspan=2>SQL QUERY:</th><th>QUERIES</th><tr>
<tr><th colspan=2 align=left valign=top><textarea name='QUERY' cols=70 rows=10 onkeydown='keyDown(event)' onkeyup='keyUp(event)'>%QUERY%</textarea></th><td valign=top rowspan=8 bgcolor=$_COLORS[2]>%SQL_HISTORY%</td><tr>
<tr><td>$_ROWS:</td><td><input type=text name='ROWS' value='%ROWS%'></td></tr>
<tr bgcolor=$_COLORS[2]><td>$_SAVE:</td><td><input type=checkbox name='HISTORY' value='1'></td></tr>
<tr bgcolor=$_COLORS[2]><td>$_COMMENTS:</td><td><input type=text name='COMMENTS' value='%COMMENTS%' size=40></td></tr>
<tr><td>XML:</td><td><input type=checkbox name='xml' value='1'></td></tr>
<tr><td colspan=2 align=center><input type=submit name=show value='QUERY' id='go' title='Ctrl+C'></td></tr>
<tr><td colspan=2 align=center>&nbsp;</td></tr>
</table>
</form>

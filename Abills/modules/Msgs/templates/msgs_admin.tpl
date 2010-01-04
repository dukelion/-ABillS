<FORM action=$SELF_URL METHOD=POST> 
<input type=hidden name=index value=$index>
<input type=hidden name=AID value=$FORM{chg}>
<table width=600>
<tr><td>$_ADMIN</td><td>%ADMIN%</td></tr>

<tr bgcolor='$_COLORS[0]'><th colspan=2>$_CHAPTERS</th></tr>
<tr><th colspan=2>%CHAPTERS%</th></tr>

</table>
<input type=submit name=change value=$_CHANGE>
</FORM>

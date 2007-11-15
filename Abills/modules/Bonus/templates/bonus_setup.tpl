<form action='$SELF_URL'>
<input type=hidden name=index value=$index>
<input type=hidden name=ID value=$FORM{chg}>
<input type=hidden name=TP_ID value=$FORM{TP_ID}>
<table>
<tr><td>$_TARIF_PLAN:</td><td>$FORM{TP_ID}</td></tr>
<tr><td>$_PERIOD ($_DAYS):</td><td><input type=text name='PERIOD' value='%PERIOD%'></td></tr>
<tr><td>$_FROM:</td><td><input type=text name='RANGE_BEGIN' value='%RANGE_BEGIN%'></td></tr>
<tr><td>$_TO:</td><td><input type=text name='RANGE_END' value='%RANGE_END%'></td></tr>
<tr><td>$_SUM:</td><td><input type=text name='SUM' value='%SUM%'></td></tr>
<tr><th bgcolor='$_COLORS[0]' colspan='2'>$_COMMENTS</th></tr>
<tr><th colspan='2'><textarea name='COMMENTS' rows='5' cols='40'>%COMMENTS%</textarea></th></tr>
</table>
<input type=submit name=%ACTION% value='%LNG_ACTION%'>
</form>

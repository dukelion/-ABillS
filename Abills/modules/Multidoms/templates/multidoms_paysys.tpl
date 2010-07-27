<form action=$SELF_URL METHOD=POST>
<input type=hidden name=index value=$index>
<input type=hidden name=sid value=$sid>

<table width=450>
<tr><th colspan=2 class=form_title>$_PAY_SYSTEM: Ukrapays</th></tr>
<tr><td>ID:</td><td><input type=text name=UKRPAYS_ID value='%UKRPAYS_ID%' size=10></td></tr>
<tr><td>Key:</td><td><input type=text name=UKRPAYS_KEY value='%UKRPAYS_KEY%' size=60></td></tr>
</table>
<input type=submit name='%ACTION%' value='%LNG_ACTION%'>
</form>

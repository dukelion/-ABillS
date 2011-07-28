<form action='$SELF_URL' METHOD='POST'>
<input type=hidden name='index' value='$index'>
<input type=hidden name='chg'   value='$FORM{chg}'> 
<table>
<tr><th colspan=2 class=form_title>$_EXCHANGE_RATE</th></tr>
<tr><td>$_EXCHANGE_RATE:</td><td><input type=text name=VOIP_ER value='%VOIP_ER%'></td></tr>
<tr><td>$_COMMENTS:</td><td><input type=text name=VOIP_ER_NAME value='%VOIP_ER_NAME%'></td></tr>
<tr><td>$_CHANGED:</td><td>%VOIP_ER_CHANGED%</td></tr>
</table>
<input type=submit name='%ACTION%' value='%LNG_ACTION%'>
</form>

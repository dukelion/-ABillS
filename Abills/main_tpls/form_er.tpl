<form action='$SELF_URL' METHOD='POST'>
<input type=hidden name='index' value='$index'>
<input type=hidden name='op'    value='er'>
<input type=hidden name='chg'   value='$FORM{chg}'> 
<table>
<tr><td>$_MONEY:</td><td><input type=text name=ER_NAME value='%ER_NAME%'></td></tr>
<tr><td>$_SHORT_NAME:</td><td><input type=text name=ER_SHORT_NAME value='%ER_SHORT_NAME%'></td></tr>
<tr><td>$_EXCHANGE_RATE:</td><td><input type=text name=ER_RATE value='%ER_RATE%'></td></tr>
</table>
<input type=submit name='%ACTION%' value='%LNG_ACTION%'>
</form>

<form action='$SELF_URL' METHOD='POST'>
<input type=hidden name='index' value='$index'>
<input type=hidden name='chg'   value='$FORM{chg}'> 
<table>
<tr><th colspan=2 class=form_title>$_EXCHANGE_RATE</th></tr>
<tr><td>$_MONEY:</td><td><input type=text name=ER_NAME value='%ER_NAME%'></td></tr>
<tr><td>$_SHORT_NAME:</td><td><input type=text name=ER_SHORT_NAME value='%ER_SHORT_NAME%'></td></tr>
<tr><td>ISO:</td><td><input type=text name=ISO value='%ISO%'></td></tr>
<tr><td>$_EXCHANGE_RATE:</td><td><input type=text name=ER_RATE value='%ER_RATE%'></td></tr>
<tr><td>$_CHANGED:</td><td>%CHANGED%</td></tr>
<tr><th colspan=2 class=even><input type=submit name='%ACTION%' value='%LNG_ACTION%'></th></tr>
</table>

</form>

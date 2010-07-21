<form method='POST' action='$SELF_URL'>
<input type='hidden' name='index' value='$index'>
<input type='hidden' name='sid' value='$FORM{sid}'>
<input type='hidden' name='OPERATION_ID' value='%OPERATION_ID%'>
<input type='hidden' name='SUM' value='%SUM%'>
<input type='hidden' name='DESCRIBE' value='Hotspot'>
<input type='hidden' name='BUY_CARDS' value='1'>
<input type='hidden' name='TP_ID' value='$FORM{TP_ID}'>
<input type='hidden' name='UID' value='%UID%'>
<table width=300>
<tr bgcolor=$_COLORS[0]><th colspan='2' class=form_title>$_BALANCE_RECHARCHE</th></tr>
<tr><td>ID:</td><td>%OPERATION_ID%</td></tr>
<tr><td>$_SUM:</td><td>%SUM%</td></tr>
<tr><td>$_DESCRIBE:</td><td></td></tr>
<tr><td>$_PAY_SYSTEM:</td><td><select name=PAYMENT_SYSTEM  ID=PAYMENT_SYSTEM>
<option value='45'>Portmone
<option value='48'>Privat Bank (Visa/Master Cards)
<option value='54'>Privat Bank - Privat 24
<option value='46'>Ukrpays
<option value='41'>Webmoney
</select>
</td></tr>
</table>
<input type='submit' name=pre value='$_ADD'>
</form>

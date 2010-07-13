<form method='POST' action='$SELF_URL'>
<input type='hidden' name='SUM' value='$FORM{SUM}' />
<input type='hidden' name='sid' value='$FORM{sid}'/>
<input type='hidden' name='UID' value='$LIST_PARAMS{UID}'/>
<input type='hidden' name='index' value='$index' />
<input type='hidden' name='PAYMENT_SYSTEM' value='$FORM{PAYMENT_SYSTEM}' />
<input type='hidden' name='OPERATION_ID' value='$FORM{OPERATION_ID}' />

<table width=400 border=0>

<tr bgcolor=$_COLORS[0]><th colspan=2>Qiwi</th></tr>
<tr><td>Operation ID:</td><td>$FORM{OPERATION_ID}</td></tr>
<tr><td>$_SUM:</td><td>$FORM{SUM}</td></tr>
<tr><td>$_PHONE:</td><td><input type='input' name='PHONE' value='%PHONE%' /></td></tr>

<tr><th colspan=2><input type=submit value='$_GET_INVOICE' name=send_invoice>

</th></tr>
</table>
</form>

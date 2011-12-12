<form id=pay name=pay method='POST' action='https://api.sandbox.ipay.ua/simple/'>


<input type='hidden' name='good' value='https://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}$ENV{REQUEST_URI}?index=$index&PAYMENT_SYSTEM=$FORM{PAYMENT_SYSTEM}&ipay_transaction=%IPAY_PAYMENT_NO%'>
<input type='hidden' name='bad' value='https://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}$ENV{REQUEST_URI}?index=$index&PAYMENT_SYSTEM=$FORM{PAYMENT_SYSTEM}&ipay_transaction=FALSE&trans_num=%IPAY_PAYMENT_NO%'>
<input type='hidden' name='IPAY_PAYMENT_NO' value='%IPAY_PAYMENT_NO%'>
<input type='hidden' name='UID' value='$LIST_PARAMS{UID}'>
<input type='hidden' name='sid' value='$FORM{sid}'>
<input type='hidden' name='IP' value='$ENV{REMOTE_ADDR}'>
<input type='hidden' name='index' value='$index'>
<input type='hidden' name='id' value='$conf{PAYSYS_IPAY_MERCHANT_ID}'>
<input type='hidden' name='amount' value='%amount%'>
<input type='hidden' name='desc' value='%desc%'>
<table width=300>
<tr><th colspan='2' class='form_title'>Ipay</th></tr>
<tr>
	<td>ID:</td>
	<td>%IPAY_PAYMENT_NO%</td>
</tr>
<tr>
	<td>$_SUM:</td>
	<td>%amount_with_point%</td>
</tr>
<tr>
	<td>$_DESCRIBE:</td>
	<td>%desc%</td>
</tr>
<tr>
	<td>&nbsp;</td>
	<td>&nbsp;</td>
</tr>
</table>
<input type='submit' value='$_ADD'>
</form>

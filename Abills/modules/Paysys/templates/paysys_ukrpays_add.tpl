<FORM ACTION='$conf{PAYSYS_UKRPAYS_URL}' method='POST'>
<INPUT TYPE='HIDDEN' NAME='OPERATION_ID' VALUE='$FORM{OPERATION_ID}'>

<input type='hidden' name='order' value='%UID%'>
<input type='hidden' name='login' value='%UID%'>
<input type='hidden' name='sus_url' value='https://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}$ENV{REQUEST_URI}?TRUE=1&amp;index=$index&PAYMENT_SYSTEM=46&OPERATION_ID=$FORM{OPERATION_ID}'>
<input type='hidden' name='lang' value='%LANG%'>
<input type='hidden' name='service_id' value='$conf{PAYSYS_UKRPAYS_SERVICE_ID}'>

<TABLE width='400'cellspacing='0' cellpadding='0' border='0'><TR><TD bgcolor='#E1E1E1'>
<TABLE width='100%' cellspacing='1' cellpadding='0' border='0'>
<tr><td bgcolor=$_COLORS[1]>

<table width=100%>


<tr><th align=right bgcolor=$_COLORS[0] colspan=2>Visa / Mastercard (Ukrpays)</th></tr>
<tr><th colspan=2><img src='https://ukrpays.com/img/logo.gif'></th></tr>
<tr><td>$_SUM:</td><td>%AMOUNT%<input type='hidden' name='amount' value='%AMOUNT%'></td></tr>
<tr><th colspan=2><input type='submit' name='pay' value='$_ADD'>
<!--  <input type='submit' name='pay' value='$_CANCEL'> -->

</th></tr>
</table>


<td></tr></table>
<td></tr></table>

</FORM>
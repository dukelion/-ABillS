<!-- UKRPAYS START -->

<FORM ACTION='$conf{PAYSYS_UKRPAYS_URL}' method='POST'>
<INPUT TYPE='HIDDEN' NAME='OPERATION_ID' VALUE='$FORM{OPERATION_ID}'>

<input type='hidden' name='order' value='%UID%'>
<input type='hidden' name='login' value='%UID%'>
<input type='hidden' name='sus_url' value='https://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}$ENV{REQUEST_URI}?TRUE=1&index=$index&PAYMENT_SYSTEM=46&OPERATION_ID=$FORM{OPERATION_ID}&TP_ID=$FORM{TP_ID}&DOMAIN_ID=$FORM{DOMAIN_ID}'>
<input type='hidden' name='lang' value='%LANG%'>
<input type='hidden' name='note' value='$FORM{OPERATION_ID}'>
<input type='hidden' name='service_id' value='$conf{PAYSYS_UKRPAYS_SERVICE_ID}'>

<TABLE width='500' class=form>

<tr><th class='form_title' colspan=2>Visa / Mastercard (Ukrpays)</th></tr>
<tr><th colspan=2><img src='https://ukrpays.com/img/logo.gif'></th></tr>
<tr><td>$_SUM:</td><td>%AMOUNT%<input type='hidden' name='amount' value='%AMOUNT%'></td></tr>
<tr><th colspan=2><input type='submit' name='pay' value='$_PAY'>
<!--  <input type='submit' name='pay' value='$_CANCEL'> -->

<tr><th colspan=2 align=center>
<a href='https://secure.privatbank.ua/help/verified_by_visa.html'
<img src='/img/v-visa.gif' width=140 height=75 border=0></a>
<a href='http://www.mastercard.com/ru/personal/ru/cardholderservices/securecode/mastercard_securecode.html'>
<img src='/img/mastercard-sc.gif' width=140 height=75 border=0>
</a>
</td></tr>

</table>

</FORM>

<!-- UKRPAYS END -->

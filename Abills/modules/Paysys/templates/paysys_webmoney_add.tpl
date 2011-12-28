<form id=pay name=pay method='POST' action='https://merchant.webmoney.ru/lmi/payment.asp'>

<input type='hidden' name='LMI_RESULT_URL' value='$conf{PAYSYS_LMI_RESULT_URL}'>
<input type='hidden' name='LMI_SUCCESS_URL' value='https://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}$ENV{REQUEST_URI}?TRUE=1'>
<input type='hidden' name='LMI_SUCCESS_METHOD' value='0'>

<input type='hidden' name='LMI_FAIL_URL' value='https://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}$ENV{REQUEST_URI}?FALSE=1&LMI_PAYMENT_NO=%LMI_PAYMENT_NO%&PAYMENT_SYSTEM=$FORM{PAYMENT_SYSTEM}&index=$index'>
<input type='hidden' name='LMI_FAIL_METHOD' value='2'>
<input type='hidden' name='LMI_PAYMENT_NO' value='%LMI_PAYMENT_NO%'>


<input type='hidden' name='UID' value='$LIST_PARAMS{UID}'>
<input type='hidden' name='sid' value='$FORM{sid}'>
<input type='hidden' name='IP' value='$ENV{REMOTE_ADDR}'>
<input type='hidden' name='index' value='$index'>
<input type='hidden' name='PAYMENT_SYSTEM' value='$FORM{PAYMENT_SYSTEM}'>
%TEST_MODE%
<table width=400 class=form>
<tr><th colspan='2' class='form_title'>Webmoney</th></tr>
<tr><td>ID:</td><td>%LMI_PAYMENT_NO%</td></tr>
<tr><td>$_SUM:</td><td><input type='text' name='LMI_PAYMENT_AMOUNT' value='%LMI_PAYMENT_AMOUNT%'></td></tr>
<tr><td>$_DESCRIBE:</td><td>%DESCRIBE%
<input type='hidden' name='LMI_PAYMENT_DESC' value='%LMI_PAYMENT_DESC%'></td></tr>
<tr><td>$_ACCOUNT:</td><td>%ACCOUNTS_SEL%</td></tr>
<tr><th colspan='2' class='even'><input type='submit' value='$_ADD'></th></tr>
</table>

</form>

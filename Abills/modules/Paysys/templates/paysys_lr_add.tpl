<form method='post' action='https://sci.libertyreserve.com'>
  <input type='hidden' name='lr_acc' value='$conf{PAYSYS_LR_ACCOUNT_NUMBER}'>
  <input type='hidden' name='lr_store' value='$conf{PAYSYS_LR_STORE_NAME}'>
  <input type='hidden' name='lr_amnt' value='$FORM{SUM}'>      
  <input type='hidden' name='lr_currency' value='LRUSD'>
  <input type='hidden' name='lr_comments' value='Balance recharge'>
  <input type='hidden' name='lr_merchant_ref' value='$FORM{OPERATION_ID}'>

<!-- urls are taken from  SCIstore settings in your account -->
  <input type='hidden' name='lr_status_url' value='https://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}/paysys_check.cgi'>
  <input type='hidden' name='lr_status_url_method' value='POST'>

  <input type='hidden' name='lr_success_url' value='https://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}/index.cgi?TRUE=1&index=$index&OPERATION_ID=$FORM{OPERATION_ID}&PAYMENT_SYSTEM=$FORM{PAYMENT_SYSTEM}'>
  <input type='hidden' name='lr_success_url_method' value='LINK'>
  <input type='hidden' name='lr_fail_url' value='https://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}/index.cgi?FALSE=1&index=$index&OPERATION_ID=$FORM{OPERATION_ID}&PAYMENT_SYSTEM=$FORM{PAYMENT_SYSTEM}'>
  <input type='hidden' name='lr_fail_url_method' value='LINK'>
<!-- baggage fields -->
  <input type='hidden' name='UID' value='$LIST_PARAMS{UID}'>
  <input type='hidden' name='OPERATION_ID' value='$FORM{OPERATION_ID}'>
  <input type='hidden' name='PAYMENT_SYSTEM' value='$FORM{PAYMENT_SYSTEM}'>
  <input type='hidden' name='IP' value='$ENV{REMOTE_ADDR}'>

<table width=400>
<tr><th class='form_title' colspan=2>LIberty Reserve</th></tr>
<tr><td>Operation ID:</td><td>$FORM{OPERATION_ID}</td></tr>
<tr><td>$_SUM:</td><td>$FORM{SUM}</td></tr>
<tr><th colspan=2><input type='submit' value='$_ADD'/></th></tr>
</table>

</form>

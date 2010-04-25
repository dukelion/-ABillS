<form method='post' action='https://sci.libertyreserve.com'>
      <input type='hidden' name='lr_acc' value='$conf{PAYSYS_LR_ACCOUNT_NUMBER}'>
      <input type='hidden' name='lr_store' value='$conf{PAYSYS_LR_STORE_NAME}'>
      <input type='hidden' name='lr_amnt' value='$FORM{SUM}'>      
      <input type='hidden' name='lr_currency' value='LRUSD'>
      <input type='hidden' name='lr_comments' value='Balance recharge'>
      <input type='hidden' name='lr_merchant_ref' value='$FORM{OPERATION_ID}'>
      <!-- urls are taken from  SCIstore settings in your account -->     

<!-- baggage fields -->
  <input type='hidden' name='UID' value='$LIST_PARAMS{UID}'>
  <input type='hidden' name='OPERATION_ID' value='$FORM{OPERATION_ID}'>
  <input type='hidden' name='PAYMENT_SYSTEM' value='$FORM{PAYMENT_SYSTEM}'>

<table width=400>
<tr bgcolor=$_COLORS[0]><th colspan=2>LIberty Reserve</th></tr>
<tr><td>Operation ID:</td><td>$FORM{OPERATION_ID}</td></tr>
<tr><td>$_SUM:</td><td>$FORM{SUM}</td></tr>
<tr><th colspan=2><input type='submit' value='$_ADD'/></th></tr>
</table>

</form>

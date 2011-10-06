<a href='http://rupay.com/guarante.php?id=$conf{PAYSYS_RUPAY_ID}' target='_blank'>
<img src='http://rupay.com/images/guarante_rupay.gif' border='0'>
</a> 
<form action='http://www.rupay.com/rupay/pay/index.php' name='pay' method='POST'>
<input type='hidden' name='user_field_index' value='$index'> 
<input type='hidden' name='user_field_UID' value='$LIST_PARAMS{UID}'> 
<input type='hidden' name='user_field_sid' value='$FORM{sid}'>
<input type='hidden' name='user_field_IP' value='$ENV{REMOTE_ADDR}'> 

<input type='hidden' name='pay_id' value='$conf{PAYSYS_RUPAY_ID}'>
<input type='hidden' name='order_id' value='%OPERATION_ID%'>
<input type='hidden' name='success_url' value='http://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}$ENV{REQUEST_URI}?UID=$LIST_PARAMS{UID}&index=$index&sid=$FORM{sid}&OPERATION_ID=%OPERATION_ID%&PAYMENT_SYSTEM=2&TRUE=1'>
<input type='hidden' name='fail_url' value='http://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}$ENV{REQUEST_URI}?UID=$LIST_PARAMS{UID}&index=$index&sid=$FORM{sid}&FALSE=1&OPERATION_ID=%OPERATION_ID%&PAYMENT_SYSTEM=2&FALSE=1'>
<table>
<tr><th colspan='2' class='form_title'>RUpay</th></tr>
<tr><td>$_MONEY:</td><td>%SUM_VAL_SEL%</td></tr>
<tr><td>$_SUM:</td><td><input type='text' name='sum_pol' value='%SUM%'></td></tr>
<tr><td>$_DESCRIBE:</td><td><input type='text' name='name_service' value='%DESCRIBE%'></td></tr>
</table>
<input type='submit' name='button' value=' оплатить ' style='font-family:Verdana, Arial, sans-serif; font-size : 11px;'>
</form>

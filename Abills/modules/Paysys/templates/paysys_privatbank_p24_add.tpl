<form method='POST' action='https://api.privatbank.ua:9083/p24api/ishop'>
Operation ID: $FORM{OPERATION_ID} <input type='input' name='amt' value='0.00' />
<input type='hidden' name='UID' value='$LIST_PARAMS{UID}'>

<input type='hidden' name='ccy' value='USD' />
<input type='hidden' name='merchant' value='$conf{PAYSYS_P24_MERCHANT_ID}' />
<input type='hidden' name='order' value='$FORM{OPERATION_ID}' />
<input type='hidden' name='details' value='Account Rechards' />
<input type='hidden' name='ext_details' value='Account Rechards' />
<input type='hidden' name='pay_way' value='privat24' />
<input type='hidden' name='return_url' value='https://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}/paysys_check.cgi' />
<input type='hidden' name='server_url' value='https://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}/paysys_check.cgi' />
<button type='submit'><img src='https://privat24.privatbank.ua/p24/img/buttons/api_logo_2.jpg' border='0' /></button>
</form>
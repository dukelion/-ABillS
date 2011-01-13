
<form action='https://liqpay.com/?do=clickNbuy' method='POST' accept-charset='utf-8'>
    <input type='hidden' name='version' value='1.2' />
    <input type='hidden' name='merchant_id' value='$conf{PAYSYS_LIQPAY_MERCHANT_ID}' />
    <input type='hidden' name='amount' value='$FORM{SUM}' />
    <input type='hidden' name='currency' value='UAH' />
    <input type='hidden' name='description' value='Payments ID: $FORM{OPERATION_ID}' />
    <input type='hidden' name='order_id'  value='$FORM{OPERATION_ID}' />
    <input type='hidden' name='result_url' value='https://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}/index.cgi?TRUE=1&index=$index&OPERATION_ID=$FORM{OPERATION_ID}&PAYMENT_SYSTEM=$FORM{PAYMENT_SYSTEM}' />
    <input type='hidden' name='server_url' value='https://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}/paysys_check.cgi' />


<table width=400 border=0>
<tr bgcolor=$_COLORS[0]><th colspan=2>LiqPAY</th></tr>
<tr><td colspan=2 align=center><img src='https://www.liqpay.com/images/logo_liqpay.png'></td></tr>
<tr><td>Operation ID:</td><td>$FORM{OPERATION_ID}</td></tr>
<tr><td>$_SUM:</td><td>$FORM{SUM}</td></tr>
<!-- <tr><td>$_PAY_WAY:</td><td>%PAY_WAY_SEL%</td></tr> -->

<tr><th colspan=2><input type=submit name=add value='$_PAY'>
</table>
</form>


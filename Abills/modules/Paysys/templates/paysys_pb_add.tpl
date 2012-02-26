<table width=300>
<tr><th class='form_title'>PrivatBank</th></tr>
<tr><td>

<TABLE width='500'cellspacing='0' cellpadding='0' border='0'><TR><TD bgcolor='#E1E1E1'>
<TABLE width='100%' cellspacing='1' cellpadding='0' border='0'>
<tr><td class='title_color'>



<table width=100%>
<tr><td>$_ORDER:</td><td>%OPERATION_ID%</td></tr>
<tr><td>$_SUM:</td><td>$FORM{SUM}</td></tr>

<tr><th colspan=2 align=center>
<a href='https://secure.privatbank.ua/help/verified_by_visa.html'
<img src='/img/v-visa.gif' width=140 height=75 border=0></a>
<a href='http://www.mastercard.com/ru/personal/ru/cardholderservices/securecode/mastercard_securecode.html'>
<img src='/img/mastercard-sc.gif' width=140 height=75 border=0>
</a>
</td></tr>

</table>


<td></tr></table>
<td></tr></table>

<FORM id='checkout' name='checkout' method=post action='https://ecommerce.liqpay.com/ecommerce/CheckOutPagen'>

<input id='Version'             type='hidden' name='Version' value='1.0.0'>
	<input id='MerID'             type='hidden' value='$conf{PAYSYS_PB_MERID}' name='MerID'>
	<input id='AcqID'             type='hidden' value='414963' name='AcqID'>
	<input id='MerRespURL'        type='hidden' value='https://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}/paysys_check.cgi'  name='MerRespURL'>
	
	<input id='MerRespURL2'        type='hidden' value='https://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}/paysys_check.cgi'  name='MerRespURL2'>
	
	<input id='PurchaseAmt'       type='hidden' value='%AMOUNT%' name='PurchaseAmt'>
	<input id='PurchaseCurrency'  type='hidden' value='980' name='PurchaseCurrency'>

  <input id='PurchaseAmt2'      type='hidden' value='%AMOUNT2%' name='PurchaseAmt2'>
	<input id='PurchaseCurrency2' type='hidden' value='840' name='PurchaseCurrency2'>

	<input id='PurchaseCurrencyExponent' type='hidden' value='2' name='PurchaseCurrencyExponent'>
	<input id='OrderID'           type='hidden' value='%OPERATION_ID%' name='OrderID'>
	<input id='SignatureMethod'   type='hidden' value='%SignatureMethod%' name='SignatureMethod'>
	<input id='Signature' type='hidden' value ='%HASH%' name='Signature'>
	<input id='CaptureFlag'       type='hidden' value='A' name='CaptureFlag'>

  <input id='AdditionalData' type=hidden value='%AdditionalData%' name='AdditionalData'>

  
<script>
document.getElementById('checkout').submit();
</script>
</FORM>


</td></tr>
</table>




<div class='noprint'>
<form action='$SELF_URL' method='POST'>
<input type=hidden name='index' value='$index'>
<input type=hidden name='TP_ID' value='$FORM{TP_ID}'>
<input type=hidden name='tt' value='%TI_ID%'>
<table>
<tr><td>$_TARIF ID:</td><td>%SEL_TT_ID%</td></tr>
<tr><td>$_NAME:</td><td><input type=text name='NAME' value='%NAME%'></td></tr>
<tr><td>$_EXTRA_TRAFIC:</td><td><input type=text name='QUANTITY' value='%QUANTITY%'></td></tr>
<tr><td>$_SUM:</td><td><input type=text name='PRICE' value='%PRICE%'></td></tr>


</table>
<input type=submit name='%ACTION%' value='%LNG_ACTION%'>
</form>
</div>

<form method='POST' action='$SELF_URL'>
<input type='hidden' name='index' value='$index'>
<input type='hidden' name='sid' value='$FORM{sid}'>

<input type='hidden' name='OPERATION_ID' value='%OPERATION_ID%'>
<table width=300 class=form>
<tr><th colspan='2' class=form_title>$_BALANCE_RECHARCHE</th></tr>
<tr><td>$_TRANSACTION #:</td><td>%OPERATION_ID%</td></tr>
<tr><td>$_SUM:</td><td><input type='text' name='SUM' value='$FORM{SUM}'></td></tr>
<tr><td>$_DESCRIBE:</td><td><input type='text' name='DESCRIBE' value='Пополнение счёта'></td></tr>
<tr><td>$_PAY_SYSTEM:</td><td>%PAY_SYSTEM_SEL%</td></tr>
<tr><th colspan='2' class=even><input type='submit' name=pre value='$_ADD'></th></tr>
</table>

</form>

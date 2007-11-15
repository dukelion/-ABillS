<form method='POST' action='$SELF_URL'>
<input type='hidden' name='index' value='$index'>
<input type='hidden' name='sid' value='$FORM{sid}'>

<input type='hidden' name='OPERATION_ID' value='%OPERATION_ID%'>
<table width=300>
<tr bgcolor=$_COLORS[0]><th colspan='2' align=right>Paysys</th></tr>
<tr><td>ID:</td><td>%OPERATION_ID%</td></tr>
<tr><td>$_SUM:</td><td><input type='text' name='SUM' value=''></td></tr>
<tr><td>$_DESCRIBE:</td><td><input type='text' name='DESCRIBE' value='Пополнение счёта'></td></tr>
<tr><td>$_PAY_SYSTEM:</td><td>%PAY_SYSTEM_SEL%</td></tr>
</table>
<input type='submit' value='$_ADD'>
</form>

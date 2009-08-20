<FORM action='$SELF_URL' METHOD='POST'>
<INPUT type='hidden' name='index' value='$index'>
<INPUT type='hidden' name='ABON_ID' value='$FORM{ABON_ID}'>
<table>
<tr><th colspan=2 class=form_title>%ACTION_LNG% $_ABON</th></tr>
<tr><td>$_NAME:</td><td><input type='text' name='NAME' value='%NAME%' size=45></td></tr>
<tr><td>$_SUM:</td><td><input type='text' name='SUM' value='%SUM%' size=10></td></tr>
<tr><td>$_PERIOD:</td><td>%PERIOD_SEL%</td></tr>
<tr><td>$_PAYMENT_TYPE:</td><td>%PAYMENT_TYPE_SEL%</td></tr>
<tr><td>$_NONFIX_PERIOD:</td><td><input type='checkbox' name='NONFIX_PERIOD' value='1' %NONFIX_PERIOD%></td></tr>

<tr><td>$_MONTH_ALIGNMENT:</td><td><input type=checkbox name=PERIOD_ALIGNMENT value=1 %PERIOD_ALIGNMENT%></td></tr>

<tr><td>$_EXTRA $_BILL:</td><td><input type='checkbox' name='EXT_BILL_ACCOUNT' value='1' %EXT_BILL_ACCOUNT%></td></tr>


<!-- <tr><td>$_DATE:</td><td></td></tr> -->
</table>

<INPUT type='submit' name='%ACTION%' value='%ACTION_LNG%'>
</FORM>

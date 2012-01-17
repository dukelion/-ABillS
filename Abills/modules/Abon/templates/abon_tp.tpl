<FORM action='$SELF_URL' METHOD='POST'>
<INPUT type='hidden' name='index' value='$index'>
<INPUT type='hidden' name='ABON_ID' value='$FORM{ABON_ID}'>
<table>
<tr><th colspan=3 class=form_title>%ACTION_LNG% $_ABON</th></tr>
<tr><td>$_NAME:</td><td colspan=2><input type='text' name='NAME' value='%NAME%' size=45></td></tr>
<tr><td>$_SUM:</td><td colspan=2><input type='text' name='SUM' value='%SUM%' size=10></td></tr>
<tr><td>$_PERIOD:</td><td colspan=2>%PERIOD_SEL%</td></tr>
<tr><td>$_PAYMENT_TYPE:</td><td colspan=2>%PAYMENT_TYPE_SEL%</td></tr>
<tr><td>$_NONFIX_PERIOD:</td><td colspan=2><input type='checkbox' name='NONFIX_PERIOD' value='1' %NONFIX_PERIOD%></td></tr>

<tr><td>$_MONTH_ALIGNMENT:</td><td colspan=2><input type=checkbox name=PERIOD_ALIGNMENT value=1 %PERIOD_ALIGNMENT%></td></tr>
<tr><td>$_REDUCTION:</td><td colspan=2><input type=checkbox name=DISCOUNT value=1 %DISCOUNT%></td></tr>
<tr><td>$_PRIORITY:</td><td colspan=2>%PRIORITY%</td></tr>
<!-- <tr><td>$_ACCOUNT $_FEES:</td><td>%ACCOUNT_SEL%</td></tr> -->

%EXT_BILL_ACCOUNT%


<tr><th colspan=3 >&nbsp;</th></tr>
<tr><td>$_FEES $_TYPE:</td><td colspan=2>%FEES_TYPES_SEL%</td></tr>

<tr><td>$_CREATE, $_SEND_ACCOUNT:</td><td colspan=2><input type=checkbox name=CREATE_ACCOUNT value='1' %CREATE_ACCOUNT%></td></tr>
<tr><td>$_VAT_INCLUDE:</td><td colspan=2><input type=checkbox name=VAT value='1' %VAT%></td></tr>


<tr><td>$_SERVICE_ACTIVATE_NOTIFICATION</td><td colspan=2><input type=checkbox name=ACTIVATE_NOTIFICATION value='1' %ACTIVATE_NOTIFICATION%></td></tr>
<tr><th colspan=3 class=form_title>$_NOTIFICATION (E-mail)</th></tr>
<tr><td> 1: $_DAYS_TO_END:</td><td ><input type=text name=NOTIFICATION1 value='%NOTIFICATION1%' size=6> </td><td>$_CREATE, $_SEND_ACCOUNT: <input type=checkbox name=NOTIFICATION_ACCOUNT value='1' %NOTIFICATION_ACCOUNT% size=6></td></tr>
<tr><td> 2: $_DAYS_TO_END:</td><td colspan=2><input type=text name=NOTIFICATION2 value='%NOTIFICATION2%' size=6></td></tr>
<tr><td> 3: $_ENDED:</td><td><input type=checkbox name=ALERT value='1' %ALERT% size=6> </td><td>$_SEND_ACCOUNT: <input type=checkbox name=ALERT_ACCOUNT value='1' %ALERT_ACCOUNT% size=6></td></tr>


<tr><td>$_EXT_CMD:</td><td colspan=2><input type=text size=60 name=EXT_CMD value='%EXT_CMD%'></td></tr>
<!-- <tr><td>$_DATE:</td><td></td></tr> -->
</table>

<INPUT type='submit' name='%ACTION%' value='%ACTION_LNG%'>
</FORM>

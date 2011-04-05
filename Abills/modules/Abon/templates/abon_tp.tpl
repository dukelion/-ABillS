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
<tr><td>$_PRIORITY:</td><td>%PRIORITY%</td></tr>
<!-- <tr><td>$_ACCOUNT $_FEES:</td><td>%ACCOUNT_SEL%</td></tr> -->

%EXT_BILL_ACCOUNT%


<tr><th colspan=2 >&nbsp;</th></tr>
<tr><td>$_FEES $_TYPE:</td><td>%FEES_TYPES_SEL%</td></tr>

<tr><td>$_SEND_ACCOUNT:</td><td><input type=checkbox name=CREATE_ACCOUNT value='1' %CREATE_ACCOUNT%></td></tr>

<tr><th colspan=2 class=form_title>$_NOTIFICATION (E-mail)</th></tr>
<tr><td> 1: $_DAYS_TO_END:</td><td><input type=text name=NOTIFICATION1 value='%NOTIFICATION1%' size=6> $_SEND_ACCOUNT: <input type=checkbox name=NOTIFICATION_ACCOUNT value='1' %NOTIFICATION_ACCOUNT% size=6></td></tr>
<tr><td> 2: $_DAYS_TO_END:</td><td><input type=text name=NOTIFICATION2 value='%NOTIFICATION2%' size=6></td></tr>
<tr><td> 3: $_ENDED:</td><td><input type=checkbox name=ALERT value='1' %ALERT% size=6> $_SEND_ACCOUNT: <input type=checkbox name=ALERT_ACCOUNT value='1' %ALERT_ACCOUNT% size=6></td></tr>


<tr><td>$_EXT_CMD:</td><td><input type=text size=60 name=EXT_CMD value='%EXT_CMD%'></td></tr>
<!-- <tr><td>$_DATE:</td><td></td></tr> -->
</table>

<INPUT type='submit' name='%ACTION%' value='%ACTION_LNG%'>
</FORM>

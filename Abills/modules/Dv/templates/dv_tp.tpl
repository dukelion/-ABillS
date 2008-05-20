<div class='noprint'>
<form action='$SELF_URL' METHOD='POST'>
<input type=hidden name='index' value='$index'>
<input type=hidden name='TP_ID' value='%TP_ID%'>
<table border='0'>
  <tr><th>#</th><td><input type='text' name='CHG_TP_ID' value='%TP_ID%'></td></tr>
  <tr><td>$_NAME:</td><td><input type=text name=NAME value='%NAME%'></td></tr>

  <tr><td>$_GROUP:</td><td>%GROUPS_SEL%</td></tr>

  <tr><td>$_UPLIMIT:</td><td><input type=text name=ALERT value='%ALERT%'></td></tr>
  <tr><td>$_SIMULTANEOUSLY:</td><td><input type=text name=SIMULTANEOUSLY value='%SIMULTANEOUSLY%'></td></tr>
<!--
  <tr><td>$_BEGIN:</td><td><input type=text name=BEGIN value='%BEGIN%'></td></tr>
  <tr><td>$_END:</td><td><input type=text name=END value='%END%'></td></tr>
-->
  <tr><th colspan=2 bgcolor=$_COLORS[0]>$_ABON</th></tr> 
  <tr><td>$_DAY_FEE:</td><td><input type=text name=DAY_FEE value='%DAY_FEE%'></td></tr>
  <tr><td>$_MONTH_FEE:</td><td><input type=text name=MONTH_FEE value='%MONTH_FEE%'></td></tr>
  <tr><td>$_MONTH_ALIGNMENT:</td><td><input type=checkbox name='PERIOD_ALIGNMENT' value='1' %PERIOD_ALIGNMENT%></td></tr>

  <tr><td>$_REDUCTION:</td><td><input type=checkbox name=REDUCTION_FEE value=1 %REDUCTION_FEE%></td></tr>
  <tr><td>$_POSTPAID:</td><td><input type=checkbox name=POSTPAID_FEE value=1 %POSTPAID_FEE%></td></tr>
  
  %EXT_BILL_ACCOUNT%
  
<!--   <tr><td>$_GROUP:</td><td>%GROUP_SEL%</td></tr> -->
<!--  <tr><td>$_HOUR_TARIF (1 Hour):</td><td><input type=text name=TIME_TARIF value='%TIME_TARIF%'></td></tr> -->
  <tr><th colspan=2 bgcolor=$_COLORS[0]>$_TIME_LIMIT (sec)</th></tr> 
  <tr><td>$_DAY</td><td><input type=text name=DAY_TIME_LIMIT value='%DAY_TIME_LIMIT%'></td></tr> 
  <tr><td>$_WEEK</td><td><input type=text name=WEEK_TIME_LIMIT value='%WEEK_TIME_LIMIT%'></td></tr>
  <tr><td>$_MONTH</td><td><input type=text name=MONTH_TIME_LIMIT value='%MONTH_TIME_LIMIT%'></td></tr>
  <tr><th colspan=2 bgcolor=$_COLORS[0]>$_TRAF_LIMIT (Mb)</th></tr>
  <tr><td>$_DAY</td><td><input type=text name=DAY_TRAF_LIMIT value='%DAY_TRAF_LIMIT%'></td></tr>
  <tr><td>$_WEEK</td><td><input type=text name=WEEK_TRAF_LIMIT value='%WEEK_TRAF_LIMIT%'></td></tr>
  <tr><td>$_MONTH</td><td><input type=text name=MONTH_TRAF_LIMIT value='%MONTH_TRAF_LIMIT%'></td></tr>
  <tr><td>$_OCTETS_DIRECTION</td><td>%SEL_OCTETS_DIRECTION%</td></tr>
  <tr><th colspan=2 bgcolor=$_COLORS[0]>$_OTHER</th></tr>
  <tr><td>$_ACTIVATE:</td><td><input type=text name=ACTIV_PRICE value='%ACTIV_PRICE%'></td></tr>
  <tr><td>$_CHANGE:</td><td><input type=text name=CHANGE_PRICE value='%CHANGE_PRICE%'></td></tr>
  <tr><td>$_CREDIT_TRESSHOLD:</td><td><input type=text name=CREDIT_TRESSHOLD value='%CREDIT_TRESSHOLD%'></td></tr>
  <tr><td>$_CREDIT:</td><td><input type=text name=CREDIT value='%CREDIT%'></td></tr>
  <tr><td>$_MAX_SESSION_DURATION (sec.):</td><td><input type=text name=MAX_SESSION_DURATION value='%MAX_SESSION_DURATION%'></td></tr>
  <tr><td>$_FILTERS:</td><td><input type=text name=FILTER_ID value='%FILTER_ID%'></td></tr>
  <tr><td>$_AGE ($_DAYS):</td><td><input type=text name=AGE value='%AGE%'></td></tr>
  <tr><td>$_PAYMENT_TYPE:</td><td>%PAYMENT_TYPE_SEL%</td></tr>
  <tr><td>$_MIN_SESSION_COST:</td><td><input type=text name=MIN_SESSION_COST value='%MIN_SESSION_COST%'></td></tr>
  <tr><td>$_MIN_USE:</td><td><input type=text name=MIN_USE value='%MIN_USE%'></td></tr>

  <tr><td>$_TRAFFIC_TRANSFER_PERIOD:</td><td><input type=text name=TRAFFIC_TRANSFER_PERIOD value='%TRAFFIC_TRANSFER_PERIOD%'></td></tr>
  <tr><td>$_NEG_DEPOSIT_FILTER_ID:</td><td><input type=text name=NEG_DEPOSIT_FILTER_ID value='%NEG_DEPOSIT_FILTER_ID%'></td></tr>
  <tr><td>IP Pool:</td><td>%IP_POOLS_SEL%</td></tr>
  <tr><th colspan=2>RADIUS Parameters (,)</th></tr>
  <tr><th colspan=2><textarea cols=50 rows=4 name=RAD_PAIRS>%RAD_PAIRS%</textarea></th></tr>
</table>
<input type=submit name='%ACTION%' value='%LNG_ACTION%'>
</form>
</div>

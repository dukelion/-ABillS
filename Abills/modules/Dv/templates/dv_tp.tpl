<div class='noprint' name='FORM_TP'>
<form action='$SELF_URL' METHOD='POST'>
<input type=hidden name='index' value='$index'>
<input type=hidden name='TP_ID' value='%TP_ID%'>
<table border='0' width=600 class=form>
  <tr><th colspan='2' class=form_title>$_TARIF_PLAN</th></tr>
  <tr><th align='left'>#</th><td><input type='text' name='ID' value='%ID%'></td></tr>
  <tr><td>$_NAME:</td><td><input type=text name=NAME value='%NAME%'></td></tr>

  <tr><td>$_GROUP:</td><td>%GROUPS_SEL%</td></tr>

  <tr><td>$_UPLIMIT:</td><td><input type=text name=ALERT value='%ALERT%'></td></tr>
  <tr><td>$_SIMULTANEOUSLY:</td><td><input type=text name=SIMULTANEOUSLY value='%SIMULTANEOUSLY%'></td></tr>
  <tr><th colspan=2 class='title_color'>$_ABON</th></tr> 
  <tr><td>$_DAY_FEE:</td><td><input type=text name=DAY_FEE value='%DAY_FEE%'></td></tr>
  <tr><td>$_ACTIVE_DAY_FEE:</td><td><input type=checkbox name='ACTIVE_DAY_FEE' value='1' %ACTIVE_DAY_FEE%></td></tr>  
  <tr><td>$_DAY_FEE $_POSTPAID:</td><td><input type=checkbox name=POSTPAID_DAY_FEE value=1 %POSTPAID_DAY_FEE%></td></tr>
  
  <tr class='even'><td>$_MONTH_FEE:</td><td><input type=text name=MONTH_FEE value='%MONTH_FEE%'></td></tr>
  <tr class='even'><td>$_MONTH_FEE $_POSTPAID:</td><td><input type=checkbox name=POSTPAID_MONTH_FEE value=1 %POSTPAID_MONTH_FEE%></td></tr>
  <tr class='even'><td>$_MONTH_ALIGNMENT:</td><td><input type=checkbox name='PERIOD_ALIGNMENT' value='1' %PERIOD_ALIGNMENT%></td></tr>
  <tr class='even'><td>$_ABON_DISTRIBUTION:</td><td><input type=checkbox name='ABON_DISTRIBUTION' value='1' %ABON_DISTRIBUTION%></td></tr>
  <tr class='even'><td>$_SMALL_DEPOSIT_ACTION:</td><td>%SMALL_DEPOSIT_ACTION_SEL%</td></tr>
  <tr><td>$_REDUCTION:</td><td><input type=checkbox name=REDUCTION_FEE value=1 %REDUCTION_FEE%></td></tr>
  <tr><td>$_FEES $_METHOD:</td><td>%SEL_METHOD%</td></tr>
  
  
  %EXT_BILL_ACCOUNT%
  
 <tr><th colspan=2 class='title_class'>$_TIME_LIMIT (sec)</th></tr> 
  <tr><td>$_DAY</td><td><input type=text name=DAY_TIME_LIMIT value='%DAY_TIME_LIMIT%'></td></tr> 
  <tr><td>$_WEEK</td><td><input type=text name=WEEK_TIME_LIMIT value='%WEEK_TIME_LIMIT%'></td></tr>
  <tr><td>$_MONTH</td><td><input type=text name=MONTH_TIME_LIMIT value='%MONTH_TIME_LIMIT%'></td></tr>
  <tr><td>$_TOTAL</td><td><input type=text name=TOTAL_TIME_LIMIT value='%TOTAL_TIME_LIMIT%'></td></tr>
 <tr><th colspan=2 class='title_color'>$_TRAF_LIMIT (Mb)</th></tr>
  <tr><td>$_DAY</td><td><input type=text name=DAY_TRAF_LIMIT value='%DAY_TRAF_LIMIT%'></td></tr>
  <tr><td>$_WEEK</td><td><input type=text name=WEEK_TRAF_LIMIT value='%WEEK_TRAF_LIMIT%'></td></tr>
  <tr><td>$_MONTH</td><td><input type=text name=MONTH_TRAF_LIMIT value='%MONTH_TRAF_LIMIT%'></td></tr>
  <tr><td>$_TOTAL</td><td><input type=text name=TOTAL_TRAF_LIMIT value='%TOTAL_TRAF_LIMIT%'></td></tr>

  <tr><td>$_OCTETS_DIRECTION</td><td>%SEL_OCTETS_DIRECTION%</td></tr>
  <tr><th colspan=2 class='title_color'>$_OTHER</th></tr>
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
  <tr class='even'><td>$_NEG_DEPOSIT_FILTER_ID:</td><td><input type=text name=NEG_DEPOSIT_FILTER_ID value='%NEG_DEPOSIT_FILTER_ID%'></td></tr>
  <tr class='even'><td>$_NEG_DEPOSIT_IP_POOL:</td><td>%NEG_DEPOSIT_IPPOOL_SEL%</td></tr>
  
  
  <tr><td>IP Pool:</td><td>%IP_POOLS_SEL%</td></tr>
  <tr><td>$_PRIORITY:</td><td><input type=text name=PRIORITY value='%PRIORITY%' size=5></td></tr>
  <tr><td>$_FINE:</td><td><input type=text name=FINE value='%FINE%' size=5></td></tr>
  <tr><td>$_TARIF_PLAN $_NEXT_PERIOD:</td><td>%NEXT_TARIF_PLAN_SEL%</td></tr>
                 
  


  %BONUS%
  <tr><th colspan=2 class='even'>RADIUS Parameters (,)</th></tr>
  <tr><th colspan=2><textarea cols=55 rows=5 name=RAD_PAIRS>%RAD_PAIRS%</textarea></th></tr>
  <tr><th colspan=2 class='even'>$_DESCRIBE</th></tr>
  <tr><th colspan=2><textarea cols=55 rows=5 name=COMMENTS>%COMMENTS%</textarea></th></tr>
  <tr><th colspan=2 class='even'><input type=submit name='%ACTION%' value='%LNG_ACTION%'></th></tr>
</table>

</form>
</div>


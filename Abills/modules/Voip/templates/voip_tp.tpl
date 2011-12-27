<div class='noprint'>
<form action=$SELF_URL METHOD=POST>
<input type=hidden name=index value=$index>
<input type=hidden name=TP_ID value=%TP_ID%>
<table class=form>
  <tr><th>#</th><td><input type=text name=ID value='%ID%'></td></tr>
  <tr><td>$_NAME:</td><td><input type=text name=NAME value='%NAME%'></td></tr>
  <tr><td>$_UPLIMIT:</td><td><input type=text name=ALERT value='%ALERT%'></td></tr>

  <tr><td>$_DAY_FEE:</td><td><input type=text name=DAY_FEE value='%DAY_FEE%'></td></tr>
  <tr><td>$_MONTH_FEE:</td><td><input type=text name=MONTH_FEE value='%MONTH_FEE%'></td></tr>
  <tr><td>$_SIMULTANEOUSLY:</td><td><input type=text name=SIMULTANEOUSLY value='%SIMULTANEOUSLY%'></td></tr>
<!--   <tr><td>$_HOUR_TARIF (1 Hour):</td><td><input type=text name=TIME_TARIF value='%TIME_TARIF%'></td></tr> -->
  <tr><th colspan=2 class='title_color'>$_TIME_LIMIT (sec)</th></tr> 
  <tr><td>$_DAY</td><td><input type=text name=DAY_TIME_LIMIT value='%DAY_TIME_LIMIT%'></td></tr> 
  <tr><td>$_WEEK</td><td><input type=text name=WEEK_TIME_LIMIT value='%WEEK_TIME_LIMIT%'></td></tr>
  <tr><td>$_MONTH</td><td><input type=text name=MONTH_TIME_LIMIT value='%MONTH_TIME_LIMIT%'></td></tr>
  <tr><th colspan=2 class='title_color'>-</th></tr> 
  <tr><td>$_ACTIVATE:</td><td><input type=text name=ACTIV_PRICE value='%ACTIV_PRICE%'></td></tr>
    <tr><td>$_CHANGE:</td><td><input type=text name=CHANGE_PRICE value='%CHANGE_PRICE%'></td></tr>
  <tr><td>$_CREDIT_TRESSHOLD:</td><td><input type=text name=CREDIT_TRESSHOLD value='%CREDIT_TRESSHOLD%'></td></tr>
  <tr><td>$_MAX_SESSION_DURATION (sec.):</td><td><input type=text name=MAX_SESSION_DURATION value='%MAX_SESSION_DURATION%'></td></tr>
  <tr><td>$_AGE ($_DAYS):</td><td><input type=text name=AGE value='%AGE%'></td></tr>
  <tr><td>$_PAYMENT_TYPE:</td><td>%PAYMENT_TYPE_SEL%</td></tr>
  <tr><td>$_MIN_SESSION_COST:</td><td><input type='text' name='MIN_SESSION_COST' value='%MIN_SESSION_COST%'></td></tr>
  <tr><th colspan=2 class='title_color'>-</th></tr> 
  <tr><td>$_FREE_TIME:</td><td><input type=text name=FREE_TIME value='%FREE_TIME%'></td></tr>
  <tr><td>$_FIRST_PERIOD:</td><td><input type=text name=FIRST_PERIOD value='%FIRST_PERIOD%'></td></tr>
  <tr><td>$_FIRST_PERIOD_STEP:</td><td><input type=text name=FIRST_PERIOD_STEP value='%FIRST_PERIOD_STEP%'></td></tr>
  <tr><td>$_NEXT_PERIOD:</td><td><input type=text name=NEXT_PERIOD value='%NEXT_PERIOD%'></td></tr>
  <tr><td>$_NEXT_PERIOD_STEP:</td><td><input type=text name=NEXT_PERIOD_STEP value='%NEXT_PERIOD_STEP%'></td></tr>
  <tr><td>$_TIME_DIVISION ($_SECONDS .):</td><td><input type=text name=TIME_DIVISION value='%TIME_DIVISION%'></td></tr>
  <tr><th colspan=2 class='even'><input type=submit name='%ACTION%' value='%LNG_ACTION%'></th></tr> 
</table>

</form>
</div>


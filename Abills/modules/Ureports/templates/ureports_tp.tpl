<div class='noprint'>
<form action='$SELF_URL' METHOD='POST'>
<input type=hidden name='index' value='$index'>
<input type=hidden name='TP_ID' value='%TP_ID%'>
<table border='0'>
  <tr><th>#</th><td><input type='text' name='CHG_TP_ID' value='%TP_ID%'></td></tr>
  <tr><td>$_NAME:</td><td><input type=text name=NAME value='%NAME%'></td></tr>

    <tr><td>$_MSG_PRICE:</td><td><input type=text name=MSG_PRICE value='%MSG_PRICE%'></td></tr>
  <tr><th colspan=2 bgcolor=$_COLORS[0]>$_ABON</th></tr> 
  <!-- 
  <tr><td>$_DAY_FEE:</td><td><input type=text name=DAY_FEE value='%DAY_FEE%'></td></tr>
  <tr><td>$_POSTPAID:</td><td><input type=checkbox name=POSTPAID_DAY_FEE value=1 %POSTPAID_DAY_FEE%></td></tr>
  -->
  <tr bgcolor=$_COLORS[2]><td>$_MONTH_FEE:</td><td><input type=text name=MONTH_FEE value='%MONTH_FEE%'></td></tr>
  <tr bgcolor=$_COLORS[2]><td>$_POSTPAID:</td><td><input type=checkbox name=POSTPAID_MONTH_FEE value=1 %POSTPAID_MONTH_FEE%></td></tr>
  <!--
  <tr bgcolor=$_COLORS[2]><td>$_MONTH_ALIGNMENT:</td><td><input type=checkbox name='PERIOD_ALIGNMENT' value='1' %PERIOD_ALIGNMENT%></td></tr>
  <tr bgcolor=$_COLORS[2]><td>$_ABON_DISTRIBUTION:</td><td><input type=checkbox name='ABON_DISTRIBUTION' value='1' %ABON_DISTRIBUTION%></td></tr>
  -->

  <tr><td>$_REDUCTION:</td><td><input type=checkbox name=REDUCTION_FEE value=1 %REDUCTION_FEE%></td></tr>
  
  
  %EXT_BILL_ACCOUNT%
  
  <tr><th colspan=2 bgcolor=$_COLORS[0]>$_OTHER</th></tr>
  <tr><td>$_ACTIVATE:</td><td><input type=text name=ACTIV_PRICE value='%ACTIV_PRICE%'></td></tr>
  <tr><td>$_CHANGE:</td><td><input type=text name=CHANGE_PRICE value='%CHANGE_PRICE%'></td></tr>
  <tr><td>$_CREDIT:</td><td><input type=text name=CREDIT value='%CREDIT%'></td></tr>
  <tr><td>$_AGE ($_DAYS):</td><td><input type=text name=AGE value='%AGE%'></td></tr>
  <tr><td>$_MIN_USE:</td><td><input type=text name=MIN_USE value='%MIN_USE%'></td></tr>

</table>
<input type=submit name='%ACTION%' value='%LNG_ACTION%'>
</form>
</div>

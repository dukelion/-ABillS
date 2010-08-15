<div class='noprint'>
<form action='$SELF_URL' METHOD='POST'>
<input type=hidden name='index' value='$index'>
<input type=hidden name='ID' value='%ID%'>
<table border='0'>
<tr><th colspan=2 bgcolor=$_COLORS[0]>$_TARIF_PLANS</th></tr>
<!--  <tr><th>#</th><td><input type='text' name='ID' value='%ID%'></td></tr> -->
  <tr><td>$_NAME:</td><td><input type=text name=NAME value='%NAME%'></td></tr>



  <tr><td>$_PERCENTAGE:</td><td><input type=text name=PERCENTAGE value='%PERCENTAGE%'></td></tr>
  <tr><td>$_OPERATION_PAYMENT:</td><td><input type=text name=OPERATION_PAYMENT value='%OPERATION_PAYMENT%'></td></tr>
  <tr><td>$_OPERATION_PAYMENT $_EXPRASSION:<br>(COUNT>10=PRICE:100;<br>TOTAL_SUM>100=PRICE:20;)</td><td><textarea name=PAYMENT_EXPR cols=20 rows=5>%PAYMENT_EXPR%</textarea></td></tr>
  <tr><td>$_PAYMENT_TYPE:</td><td>%PAYMENT_TYPE_SEL%</td></tr>
  <tr><td>$_ACTIVATE:</td><td><input type=text name=ACTIVATE_PRICE value='%ACTIVATE_PRICE%'></td></tr>
  <tr><td>$_CHANGE:</td><td><input type=text name=CHANGE_PRICE value='%CHANGE_PRICE%'></td></tr>
  <tr><td>$_CREDIT:</td><td><input type=text name=CREDIT value='%CREDIT%'></td></tr>
  <tr><td>$_MIN_USE:</td><td><input type=text name=MIN_USE value='%MIN_USE%'></td></tr>
  <tr><td>$_NAS:</td><td><input type=checkbox name=NAS_TP value='1' %NAS_TP%></td></tr>
  <tr><td>$_BONUS $_CARDS:</td><td><input type=text name=BONUS_CARDS value='%BONUS_CARDS%'></td></tr>

<tr><th colspan=2>$_COMMENTS</th></tr>
<tr><th colspan=2><textarea cols=60 rows=6 name=COMMENTS>%COMMENTS%</textarea></th></tr>

</table>
<input type=submit name='%ACTION%' value='%LNG_ACTION%'>
</form>
</div>

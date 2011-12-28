<div class='noprint'>
<form action='$SELF_URL' method='POST'>
<input type=hidden name='index' value='$index'>
<input type=hidden name='TP_ID' value='%TP_ID%'>
<input type=hidden name='tt' value='%TI_ID%'>
<table class=form>
<tr><th colspan=3 class='form_title'>$_TRAFIC_TARIFS</th></tr>
<tr><td colspan=2>$_INTERVALS:</td><td class='even'>%TI_ID%</td></tr>
<tr><td colspan=2>$_TARIF ID:</td><td>%SEL_TT_ID%</td></tr>
<tr><td rowspan=2>$_TRAFIC_TARIFS (1 Mb):</td><td>IN</td><td><input type=text name='TT_PRICE_IN' value='%TT_PRICE_IN%'></td></tr>
<tr><td>OUT:</td><td><input type=text name='TT_PRICE_OUT' value='%TT_PRICE_OUT%'></td></tr>
<tr><td colspan=2>$_PREPAID (Mb):</td><td><input type=text size=12 name='TT_PREPAID' value='%TT_PREPAID%'></td></tr>
<tr><td rowspan=2>$_SPEED (Kbits):</td><td>IN</td><td><input type=text size=12 name='TT_SPEED_IN' value='%TT_SPEED_IN%'></td></tr>
<tr><td>OUT</td><td><input type=text size=12 name='TT_SPEED_OUT' value='%TT_SPEED_OUT%'></td></tr>
<tr><td colspan=2>$_DESCRIBE:</td><td><input type=text name='TT_DESCRIBE' value='%TT_DESCRIBE%'></td></tr>
<tr><td colspan=2>$_EXPRASSION:</td><td><textarea name='TT_EXPRASSION' cols=40 rows=8>%TT_EXPRASSION%</textarea></td></tr>

<tr><td colspan=2>NETS</td><td>%NETS_SEL%</td></tr>
<tr><th colspan=3>%DV_EXPPP_NETFILES%</th></tr>
<tr><th colspan=3 class='even'><input type=submit name='%ACTION%' value='%LNG_ACTION%'></th></tr>
</table>

</form>
</div>

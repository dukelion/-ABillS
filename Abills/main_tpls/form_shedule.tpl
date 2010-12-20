<form action=$SELF_URL>
<input type=hidden name=index value=$index>
<table width=400>
<tr><th class=form_title colspan=2>$_SHEDULE</th></tr>
<tr><td>$_DAY:</td><td>%SEL_D%</td></tr>
<tr><td>$_MONTH:</td><td>%SEL_M%</td></tr>
<tr><td>$_YEAR:</td><td>%SEL_Y%</td></tr>
<tr><td>$_COUNT:</td><td><input type=text name=COUNT value='%COUNT%'></td></tr>
<tr><td>$_TYPE:</td><td>%SEL_TYPE%</td></tr>
<tr><th colspan=2>$_ACTION:</td></tr>
<tr><th colspan=2><textarea cols=60 rows=10 name=ACTION>%ACTION%</textarea></td></tr>
<tr><th colspan=2>$_COMMENTS:</td></tr>
<tr><th colspan=2><textarea cols=60 rows=3 name=COMMENTS>%COMMENTS%</textarea></td></tr>

</table>
<input type=submit name=add value=$_ADD>
</form>

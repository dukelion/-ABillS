<div class='noprint'>
<form action='$SELF_URL' method='post'>
<input type=hidden name='index' value='$index'>
<input type=hidden name=chg value='%ROUTE_ID%'>
<input type=hidden name=PARENT_ID value='%PARENT_ID%'>
<input type=hidden name=ROUTE_ID value='$FORM{ROUTE_ID}'>
<table width=420 cellspacing=0 cellpadding=3>
<TR><TH colspan='2' class='form_title'>$_ROUTE</TH></TR>
<!-- <tr><td>$_PARENT:</td><td>%PARENT%</td></tr> -->
<tr><td>$_PREFIX:</td><td><input type=text name=ROUTE_PREFIX value='%ROUTE_PREFIX%'></td></tr>
<tr><td>$_NAME:</td><td><input type=text name=ROUTE_NAME value='%ROUTE_NAME%'></td></tr>
<tr><td>$_DISABLE:</td><td><input type=checkbox name=DISABLE value='1' %DISABLE%></td></tr>
<tr><td>$_DESCRIBE:</td><td><input type=text name=DESCRIBE value='%DESCRIBE%'></td></tr>
<!-- <tr><td>$_GATEWAY:</td><td>%GATWAY_SEL%</td></tr> -->
</table>
<input type=submit name='%ACTION%' value='%LNG_ACTION%'>
</form>
</div>

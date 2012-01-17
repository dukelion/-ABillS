<form action='$SELF_URL' method='post'>
<input type=hidden name='index' value='$index'>
<input type=hidden name='UID' value='$FORM{UID}'>
<table width=420 cellspacing='0' cellpadding='3'>
<tr><td>$_TARIF_PLAN:</td><th  align='left' valign='middle'>[%TP_ID%] %TP_NAME% %CHANGE_TP_BUTTON%</th></tr>
<tr><td>$_SIMULTANEOUSLY:</td><td><input type=text name=SIMULTANEONSLY value='%SIMULTANEONSLY%'></td></tr>
<tr><td>IP:</td><td><input type=text name=IP value='%IP%'></td></tr>
<tr><td>Netmask:</td><td><input type=text name=NETMASK value='%NETMASK%'></td></tr>
<tr><td>$_SPEED (kb):</td><td><input type=text name=SPEED value='%SPEED%'></td></tr>
<tr><td>$_FILTERS:</td><td><input type=text name=FILTER_ID value='%FILTER_ID%'></td></tr>
<tr><td>CID:</td><td><input type=text name='CID' value='%CID%'>
<tr><td>$_PORT:</td><td><input type=text name='PORT' value='%PORT%'>
<tr><td>Callback:</td><td><input type='checkbox' name='CALLBACK' value='1' %CALLBACK%>
<tr><td>$_DISABLE:</td><td><input type='checkbox' name='DISABLE' value='1' %DISABLE%></td></tr>
</table>
<input type=submit name='%ACTION%' value='%LNG_ACTION%' class='noprint'>
</form>

%ONLINE_TABLE%
<br>
<form action='$SELF_URL' method='post'>
<input type=hidden name='index' value='$index'>
<input type=hidden name='UID' value='$FORM{UID}'>
<table cellspacing='0' cellpadding='3' width=450>
<tr bgcolor=$_COLORS[2]><td>$_TARIF_PLAN:</td><th  align='left' valign='middle'>[%TP_ID%] %TP_NAME% %CHANGE_TP_BUTTON%</th></tr>
%JOIN_SERVICE%
<tr><td>$_SIMULTANEOUSLY:</td><td><input type=text name=SIMULTANEONSLY value='%SIMULTANEONSLY%'></td></tr>
<tr><td>IP:</td><td><input type=text name=IP value='%IP%'> Static IP Pool: %STATIC_IP_POOL%</td></tr>
<tr><td>Netmask:</td><td bgcolor='%NETMASK_COLOR%'><input type=text name=NETMASK value='%NETMASK%'></td></tr>
<tr><td>$_SPEED (kb):</td><td><input type=text name=SPEED value='%SPEED%'></td></tr>
<tr><td>$_FILTERS:</td><td><input type=text name=FILTER_ID value='%FILTER_ID%'></td></tr>
<tr><td>CID:</td><td><input type=text name='CID' value='%CID%'>
<tr><td>$_PORT:</td><td><input type=text name='PORT' value='%PORT%'>
<tr><td>Callback:</td><td><input type='checkbox' name='CALLBACK' value='1' %CALLBACK%>
<tr><td>$_STATUS:</td><td bgcolor=%STATUS_COLOR%>%STATUS_SEL% <span style='background:$_COLORS[1]'>&nbsp; %SHEDULE% &nbsp;</span>
</td></tr>
<tr><td>TURBO:</td><td>%TURBO_MODE_SEL%</td></tr>
<tr><td>$_ABON:</td><td>%ABON_DATE%</td></tr>
<tr><td colspan='2'>%REGISTRATION_INFO%  %REGISTRATION_INFO_PDF%</td></tr>
</table>
<input type=submit name='%ACTION%' value='%LNG_ACTION%' class='noprint'>
</form>

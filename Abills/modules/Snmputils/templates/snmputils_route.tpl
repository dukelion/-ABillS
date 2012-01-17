<FORM action='$SELF_URL' METHOD='POST'>
<input type='hidden' name='index' value='$index'>
<input type='hidden' name='NAS_ID' value='$FORM{NAS_ID}'>
<input type='hidden' name='SNMP_HOST' value='$FORM{SNMP_HOST}'>
<input type='hidden' name='SNMP_COMMUNITY' value='$FORM{SNMP_COMMUNITY}'>
<table>
<tr><td>ipRouteDest:</td><td><input type='text' name='ipRouteDest' value='%ipRouteDest%'></td></tr>
<tr><td>ipRouteMask:</td><td><input type='text' name='ipRouteMask' value='%ipRouteMask%'></td></tr>
<tr><td>ipRouteNextHop:</td><td><input type='text' name='ipRouteNextHop' value='%ipRouteNextHop%'></td></tr>
<tr><td>ipRouteIfIndex :</td><td><input type='text' name='ipRouteIfIndex' value='%ipRouteIfIndex%'></td></tr>
<tr><td>ipRouteMetric1:</td><td><input type='text' name='ipRouteMetric1' value='%ipRouteMetric1%'></td></tr>
<tr><td>ipRouteAge:</td><td><input type='text' name='ipRouteAge' value='%ipRouteAge%'></td></tr>
<tr><td>ipRouteType:</td><td><input type='text' name='ipRouteType' value='%ipRouteType%'></td></tr>
</table>
<input type='submit' name='%ACTION%' value='%ACTION_LNG%'>
</FORM>

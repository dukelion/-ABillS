<form action='$SELF_URL' METHOD=POST>
<input type=hidden name=index value=$index>
<input type=hidden name=ID value='$FORM{chg}'>
<table>
<tr><th align=right colspan=3 bgcolor='$_COLORS[0]'>Network:</th><tr>
<tr><td>$_HOSTS_NETWORKS_NAME:</td><td colspan=2><input type=text name='NAME' value='%NAME%'></td></tr>
<tr><td>$_COMMENTS:</td><td colspan=2><input type=text name='COMMENTS' value='%COMMENTS%' size=50></td></tr>
<tr><td>$_HOSTS_NETWORKS_NET:</td><td><input type=text name='NETWORK' value='%NETWORK%'></td><td>NETMASK: <input type=text name='MASK' value='%MASK%'></td></tr>
<tr><td>$_DEFAULT_ROUTER:</td><td colspan=2><input type=text name='ROUTERS' value='%ROUTERS%'></td></tr>
<tr><td>IP RANGE:</td><td colspan=2><input type=text name='IP_RANGE_FIRST' value='%IP_RANGE_FIRST%'> - <input type=text name='IP_RANGE_LAST' value='%IP_RANGE_LAST%'></td></tr>
<tr><td>DNS (,):</td><td colspan=2><input type=text name='DNS' value='%DNS%'></td></tr>
<tr><td>DOMAINNAME:</td><td colspan=2><input type=text name='DOMAINNAME' value='%DOMAINNAME%'></td></tr>

<tr><td>$_DENY_UNKNOWN_CLIENTS:</td><td colspan=2><input type=checkbox value=1 name='DENY_UNKNOWN_CLIENTS' %DENY_UNKNOWN_CLIENTS%></td></tr>
<tr><td>$_AUTHORITATIVE:</td><td colspan=2><input type=checkbox name='AUTHORITATIVE' value=1 %AUTHORITATIVE%></td></tr>


<tr><td>$_HOSTS_NETWORKS_COORDINATOR:</td><td colspan=2><input type=text name='COORDINATOR' value='%COORDINATOR%'></td></tr>
<tr><td>$_HOSTS_NETWORKS_COORDINATOR_PHONE:</td><td colspan=2><input type=text name='PHONE' value='%PHONE%'></td></tr>
<tr><td>$_DISABLE:</td><td colspan=2><input type=checkbox name='DISABLE' value=1 %DISABLE%></td></tr>
</table>
<input type=submit name=%ACTION% value='%ACTION_LNG%'>
</form>

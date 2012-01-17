<form action='$SELF_URL' METHOD=POST>
<input type=hidden name=index value=$index>
<input type=hidden name=ID value='$FORM{chg}'>
<table>
<tr><th class=form_title colspan=3>$_NETWORKS</th><tr>
<tr><td>$_HOSTS_NETWORKS_NAME:</td><td colspan=2><input type=text name='NAME' value='%NAME%'></td></tr>
<tr><td>$_COMMENTS:</td><td colspan=2><input type=text name='COMMENTS' value='%COMMENTS%' size=50></td></tr>
<tr><td>$_HOSTS_NETWORKS_NET:</td><td><input type=text name='NETWORK' value='%NETWORK%'></td><td>NETMASK: <input type=text name='MASK' value='%MASK%'></td></tr>
<tr><td>$_DEFAULT_ROUTER:</td><td colspan=2><input type=text name='ROUTERS' value='%ROUTERS%'></td></tr>
<tr><td>IP RANGE:</td><td colspan=2><input type=text name='IP_RANGE_FIRST' value='%IP_RANGE_FIRST%'>-<input type=text name='IP_RANGE_LAST' value='%IP_RANGE_LAST%' size=14> $_STATIC:<input type=checkbox name=STATIC value=1 %STATIC%></td></tr>
<tr><td>DNS:</td><td colspan=2><input type=text name='DNS' value='%DNS%'></td></tr>
<tr><td>DNS:</td><td colspan=2><input type=text name='DNS2' value='%DNS2%'></td></tr>
<tr><td>NTP:</td><td colspan=2><input type=text name='NTP' value='%NTP%'></td></tr>
<tr><td>DOMAINNAME:</td><td colspan=2><input type=text name='DOMAINNAME' value='%DOMAINNAME%'></td></tr>

<tr><td>$_DENY_UNKNOWN_CLIENTS:</td><td colspan=2><input type=checkbox value=1 name='DENY_UNKNOWN_CLIENTS' %DENY_UNKNOWN_CLIENTS%></td></tr>
<tr><td>$_AUTHORITATIVE:</td><td colspan=2><input type=checkbox name='AUTHORITATIVE' value=1 %AUTHORITATIVE%></td></tr>


<tr><td>$_HOSTS_NETWORKS_COORDINATOR:</td><td colspan=2><input type=text name='COORDINATOR' value='%COORDINATOR%'></td></tr>
<tr><td>$_HOSTS_NETWORKS_COORDINATOR_PHONE:</td><td colspan=2><input type=text name='PHONE' value='%PHONE%'></td></tr>
<tr><td>$_DISABLE:</td><td colspan=2><input type=checkbox name='DISABLE' value=1 %DISABLE%></td></tr>
<tr><td>$_TYPE:</td><td colspan=2>%PARENT_SEL%</td></tr>
<tr><td>GUEST VLAN:</td><td colspan=2><input type=text name='GUEST_VLAN' value='%GUEST_VLAN%'></td></tr>
</table>
<input type=submit name=%ACTION% value='%ACTION_LNG%'>
</form>

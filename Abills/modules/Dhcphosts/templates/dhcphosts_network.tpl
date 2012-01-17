<form action='$SELF_URL' METHOD=POST>
<input type=hidden name=index value=$index>
<input type=hidden name=ID value='$FORM{chg}'>
<table>
<tr><th colspan=4>New Network:</th><tr>
<tr><td colspan=2>$_HOSTS_NETWORKS_NAME:</td><td colspan=2><input type=text name='NAME' value='%NAME%'></td></tr>
<tr><td>$_HOSTS_NETWORKS_NET:</td><td colspan=2><input type=text name='NETWORK' value='%NETWORK%'></td><td>NETMASK:</td><td><input type=text name='MASK' value='%MASK%'></td></tr>
<tr><td colspan=2>$_DEFAULT_ROUTER:</td><td colspan=2><input type=text name='ROUTERS' value='%ROUTERS%'></td></tr>
<tr><td colspan=2>$_HOSTS_NETWORKS_COORDINATOR:</td><td colspan=2><input type=text name='COORDINATOR' value='%COORDINATOR%'></td></tr>
<tr><td colspan=2>$_HOSTS_NETWORKS_COORDINATOR_PHONE:</td><td colspan=2><input type=text name='PHONE' value='%PHONE%'></td></tr>
<tr><td colspan=2>DNS:</td><td colspan=2><input type=text name='DNS' value='%DNS%'></td></tr>
<tr><td colspan=2>DOMAINNAME:</td><td colspan=2><input type=text name='DOMAINNAME' value='%DOMAINNAME%'></td></tr>
<tr><td colspan=2>$_DISABLE:</td><td colspan=2><input type=checkbox name='DISABLE' %DISABLE%></td></tr>
</table>
<input type=submit name=%ACTION% value='%ACTION_LNG%'>
</form>

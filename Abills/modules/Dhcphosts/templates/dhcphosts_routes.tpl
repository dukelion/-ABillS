<form action='$SELF_URL' METHOD=POST>
<input type=hidden name=index value=$index>
<input type=hidden name=NET_ID value='$FORM{NET_ID}'>
<input type=hidden name=ID value='$FORM{chg}'>
<table border=0>
<tr><th colspan=2>Route:</th><tr>
<tr><td>$_HOSTS_SRC:</td><td colspan=2><input type=text name='SRC' value='%SRC%'></td></tr>
<tr><td>NETMASK:</td><td><input type=text name='MASK' value='%MASK%'></td></tr>
<tr><td>$_HOSTS_ROUTER:</td><td><input type=text name='ROUTER' value='%ROUTER%'></td></tr>
</table>
<input type=submit name=%ACTION% value='%ACTION_LNG%'>
</form>

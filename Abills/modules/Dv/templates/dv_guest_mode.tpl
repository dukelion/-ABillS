<form action=$SELF_URL>
<input type=hidden name=index value=$index>
<input type=hidden name=sid value=$sid>
<input type=hidden name=CID value='%DHCP_LEASES_MAC%'>

<table width=500>
<tr><th colspan=2 bgcolor=$_COLORS[0]>$_GUEST_MODE</th></tr>
<tr><td>MAC: %DHCP_LEASES_MAC%</td><td><input type=submit name=discovery value='$_REGISTRATION'></td></tr>
</table>
</form>
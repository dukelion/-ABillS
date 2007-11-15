<form action='$SELF_URL' method='post'>
<input type=hidden name='index' value='$index'>
<input type=hidden name='UID' value='$FORM{UID}'>

<table width=420 cellspacing='0' cellpadding='3'>
<tr><td>VLAN ID:</td><td><input type=text name=VLAN_ID value='%VLAN_ID%'></td></tr>
<tr><td>$_INTERFACE IP:</td><td><input type=text name=IP value='%IP%'></td></tr>
<tr><td>Netmask:</td><td><input type=text name=NETMASK value='%NETMASK%'></td></tr>
<tr><td>IP $_RANGE:</td><td>%IP_RANGE%</td></tr>
<tr><td>$_NAS:</td><td>%NAS_LIST%</td></tr>
<tr><td>DHCP:</td><td><input type='checkbox' name='DHCP' value='1' %DHCP%></td></tr>
<tr><td>PPPoE:</td><td><input type='checkbox' name='PPPOE' value='1' %PPPOE%></td></tr>

<tr><td>$_DISABLE:</td><td><input type='checkbox' name='DISABLE' value='1' %DISABLE%></td></tr>
</table>
<input type=submit name='%ACTION%' value='%LNG_ACTION%' class='noprint'>
</form>

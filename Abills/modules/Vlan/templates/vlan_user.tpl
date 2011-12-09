<form action='$SELF_URL' method='post'>
<input type=hidden name='index' value='$index'>
<input type=hidden name='UID' value='$FORM{UID}'>

<table cellspacing='0' cellpadding='3'>
<tr><td>VLAN ID:</td><td><input type=text name=VLAN_ID value='%VLAN_ID%' size=8></td></tr>
<tr><td>UNNUMBERED IP:</td><td><input type='text' name='UNNUMBERED_IP' value='%UNNUMBERED_IP%'></td></tr>
<tr><td>$_INTERFACE IP:</td><td><input type=text name=IP value='%IP%'></td></tr>
<tr><td>Netmask:</td><td><input type=text name=NETMASK value='%NETMASK%'></td></tr>
<tr><td>IP $_RANGE:</td><td>%IP_RANGE%</td></tr>
<tr><td>IP $_COUNT:</td><td>%CLIENT_IPS_COUNT%</td></tr>
<tr><td>$_NAS:</td><td>%NAS_LIST%</td></tr>
<tr><td>DHCP:</td><td><input type='checkbox' name='DHCP' value='1' %DHCP%></td></tr>
<tr><td>PPPoE:</td><td><input type='checkbox' name='PPPOE' value='1' %PPPOE%></td></tr>

<tr><td>$_DISABLE:</td><td><input type='checkbox' name='DISABLE' value='1' %DISABLE%></td></tr>

<tr class=even><td>$_DEL $_CONFIRM:</td><td><input name='is_js_confirmed' value='1' type=checkbox class='noprint'></td></tr>

<tr><td align=left class=even>
<input type=submit name='del' value='$_DEL' class='noprint'>
</td><td align=right><input type=submit name='%ACTION%' value='%LNG_ACTION%' class='noprint'>
</td></tr>
</table>



</form>

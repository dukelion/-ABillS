<FORM action=$SELF_URL MATHOD=POST>
<input type=hidden name=index value=$index>
<input type='hidden' name='NAS_ID' value='$FORM{NAS_ID}'>
<input type='hidden' name='TYPE' value='$FORM{TYPE}'>
<input type='hidden' name='SHOW' value='1'>
<input type='hidden' name='SNMP_HOST' value='$FORM{SNMP_HOST}'>
<input type='hidden' name='SNMP_COMMUNITY' value='$FORM{SNMP_COMMUNITY}'>

<table>
<tr><td>$_PORT:</td><td>%PORT_SEL%</td></tr>
<tr><td>IP:</td><td><input type=text name=IP value='%IP%'></td></tr>
<tr><td>MAC:</td><td><input type=text name=MAC value='%MAC%'></td></tr>
<tr><td>ACL_IP_MAC:</td><td><input type=checkbox name=ACL_IP_MAC value='1' %ACL_IP_MAC%></td></tr>
</table>
<input type='submit' name='add' value='$_ADD'>
</FORM>

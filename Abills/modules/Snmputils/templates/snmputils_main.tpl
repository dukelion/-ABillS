<FORM action='$SELF_URL'>
<input type='hidden' name='index' value='$index'>
<table>
<tr><td>SNMP Host:</td><td><input type='text' name='SNMP_HOST' value='%SNMP_HOST%'></td></tr>
<tr><td>SNMP Community:</td><td><input type='text' name='SNMP_COMMUNITY' value='%SNMP_COMMUNITY%'></td></tr>
<tr><td>$_NAS:</td><td>%NAS_SEL%</td></tr>
<tr><td>SNMP OID:</td><td><input type='text' name='SNMP_OID' value='%SNMP_OID%'></td></tr>
<tr><td>$_TYPE:</td><td>%TYPE_SEL%</td></tr>
<tr><td>MIBS:</td><td>%MIBS%</td></tr>
</table>
<input type='submit' name='SHOW' value='$_SHOW'>
</FORM>

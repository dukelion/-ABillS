<FORM action=$SELF_URL METHOD=POST>
<input type=hidden name=index value='$index'>
<input type=hidden name=ID value='$FORM{chg}'>
<table>
<tr><td>VOIP $_PROVIDER</td><td><input type=text name=PROVIDER_NAME value='%PROVIDER_NAME%'></td></tr>
<tr><td>$_NAME</td><td><input type=text name=NAME value='%NAME%'></td></tr> 	
<tr><td>$_DEL $_PREFIX</td><td><input type=text name=REMOVE_PREFIX value='%REMOVE_PREFIX%'></td></tr> 	
<tr><td>$_ADD $_PREFIX</td><td><input type=text name=ADD_PREFIX value='%ADD_PREFIX%'></td></tr> 	
<tr><td>$_PROTOCOL</td><td>%PROTOCOL_SEL%</td></tr> 	
<tr><td>$_PROVIDER IP</td><td><input type=text name=PROVIDER_IP value='%PROVIDER_IP%'></td></tr> 	
<tr><td>$_EXTRA $_PARAMS</td><td><input type=text name=EXT_PARAMS value='%EXT_PARAMS%'></td></tr> 	
<tr><td>$_FAILOVER_TRUNK</td><td>%FAILOVER_TRUNK_SEL%</td></tr> 	

</table>
<input type=submit name=%ACTION% value='%LNG_ACTION%'>
</FORM>
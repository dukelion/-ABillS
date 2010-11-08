<form action='$SELF_URL' METHOD='post'>
<input type='hidden' name='index' value='%INDEX%'/>
<input type='hidden' name='NAS_ID' value='%NAS_ID%'/>
<input type='hidden' name='IP_POOLS' value='1'/>
<input type='hidden' name='chg' value='$FORM{chg}'/>
<TABLE>
<TR><TH COLSPAN='2' BGCOLOR='$_COLORS[0]' align='right'>IP POOLS</TH></TR>
<TR><TD>$_NAME:</TD><TD><input type='text' name='POOL_NAME' value='%POOL_NAME%'/></TD></TR>
<TR><TD>FIRST IP:</TD><TD><input type='text' name='NAS_IP_SIP' value='%NAS_IP_SIP%'/></TD></TR>
<TR><TD>$_COUNT:</TD><TD><input type='text' name='NAS_IP_COUNT' value='%NAS_IP_COUNT%'/></TD></TR>
<TR><TD>$_PRIORITY:</TD><TD><input type='text' name='POOL_PRIORITY' value='%POOL_PRIORITY%' size='5'/></TD></TR>
<TR><TD>$_STATIC:</TD><TD><input type='checkbox' name='STATIC' value='1' %STATIC%/></TD></TR>
<TR><TD>$_SPEED:</TD><TD><input type='text' name='POOL_SPEED' value='%POOL_SPEED%' size='5'/></TD></TR>
</TABLE>
<input type='submit' name='%ACTION%' value='%LNG_ACTION%' class='button'/>
</form>

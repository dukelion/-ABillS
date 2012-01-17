<FORM action=$SELF_URL METHOD=POST>
<input type=hidden name=index value=$index>
<input type='hidden' name='NAS_ID' value='$FORM{NAS_ID}'>
<input type='hidden' name='TYPE' value='$FORM{TYPE}'>
<input type='hidden' name='SHOW' value='1'>
<input type='hidden' name='SNMP_HOST' value='$FORM{SNMP_HOST}'>
<input type='hidden' name='SNMP_COMMUNITY' value='$FORM{SNMP_COMMUNITY}'>
<TABLE>
  <TBODY>
  <TR>
    <TH bgcolor=$_COLORS[0] colspan=2 align=right>Static MAC Forwarding</TH>
  </TR>
  <TR>
    <TD>MAC Address (HEX)</TD> <TD><INPUT maxLength=2 size=2 name=MAC_1 value=%MAC_1%><STRONG>:</STRONG> 
     <INPUT maxLength=2 size=2 name=MAC_2 value=%MAC_2%> <STRONG>:</STRONG> 
     <INPUT maxLength=2 size=2 name=MAC_3 value=%MAC_3%> <STRONG>: </STRONG>
     <INPUT maxLength=2 size=2 name=MAC_4 value=%MAC_4%> <STRONG>: </STRONG>
     <INPUT maxLength=2 size=2 name=MAC_5 value=%MAC_5%> <STRONG>: </STRONG>
     <INPUT maxLength=2 size=2 name=MAC_6 value=%MAC_6%> </TD>
    </TR>
  <TR>
    <TD>Port</TD><TD><INPUT maxLength=4 size=4 name=PORT value='%PORT%'> </TD>
  </TR>
  <TR>
    <TD colSpan=2><input type=submit name=%ACTION% value='%ACTION_LNG%'></TD>
  </TR>
</TBODY>
</TABLE>
</FORM>
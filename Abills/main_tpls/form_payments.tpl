<div class='noprint'>
<form action='$SELF_URL' METHOD='POST'>
<input type=hidden name=index value=$index>
<input type=hidden name=subf value=$FORM{subf}>
<input type=hidden name=OP_SID value=%OP_SID%>
<input type=hidden name=UID value=%UID%>
<TABLE>
<TR><TD>$_SUM:</TD><TD><input type=text name=SUM></TD></TR>
<TR><TD>$_DESCRIBE:</TD><TD><input type=text name=DESCRIBE></TD></TR>
<TR><TD>$_EXCHANGE_RATE:</TD><TD>%SEL_ER%</TD></TR>
<TR><TD colspan=2><hr size=1></TD></TR>
<TR><TD>$_PAYMENT_METHOD:</TD><TD>%SEL_METHOD%</TD></TR>
<TR><TD>ID:</TD><TD><input type=text name='EXT_ID' value='%EXT_ID%'></TD></TR>
%EXT_DATA%
</TABLE>
<input type=submit name=add value='$_ADD'>
</form>
</div>

<div class='noprint'>
<form action='$SELF_URL' METHOD='POST'>
<input type=hidden name=index value=$index>
<input type=hidden name=subf value=$FORM{subf}>
<input type=hidden name=OP_SID value=%OP_SID%>
<input type=hidden name=UID value=%UID%>

<TABLE>
<TR><TH align=right colspan=3 bgcolor=$_COLORS[0]>$_PAYMENTS</TH></TR>
<TR><TD colspan=2>$_SUM:</TD><TD><input type=text name=SUM></TD></TR>
<TR><TD rowspan=2>$_DESCRIBE:</TD><TD>$_USER:</TD><TD><input type=text name=DESCRIBE value='%DESCRIBE%' size=40></TD></TR>
<TR> <TD>$_INNER:</TD><TD><input type=text name=INNER_DESCRIBE size=40></TD></TR>
<TR><TD colspan=2>$_EXCHANGE_RATE:</TD><TD>%SEL_ER%</TD></TR>
<TR><TD colspan=3><hr size=1></TD></TR>
<TR><TD colspan=2>$_PAYMENT_METHOD:</TD><TD>%SEL_METHOD%</TD></TR>
<TR><TD colspan=2>EXT ID:</TD><TD><input type=text name='EXT_ID' value='%EXT_ID%'></TD></TR>
%EXT_DATA%
%DATE%
</TABLE>
<input type=submit name=add value='$_ADD'>
</form>
</div>

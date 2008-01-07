<div class='noprint'>
<form action='$SELF_URL' METHOD='POST'>
<input type=hidden name='index' value='$index'>
<input type=hidden name='OP_SID' value='%OP_SID%'>
<input type=hidden name='UID' value='$FORM{UID}'>
<TABLE>
<TR><TD>$_SUM:</TD><TD><input type=text name='SUM' value='%SUM%'></TD></TR>
<TR><TD>$_DESCRIBE:</TD><TD><input type=text name=DESCRIBE value='%DESCRIBE%'></TD></TR>
<TR><TD>$_TYPE:</TD><TD>%TYPE_SEL%</TD></TR>
<TR><TD>$_STATUS:</TD><TD>%STATUS_SEL%</TD></TR>
<TR><TD colspan=2><hr size=1></TD></TR>
<TR><TD>ID:</TD><TD><input type=text name=EXT_ID value='%EXT_ID%'></TD></TR>
</TABLE>
<input type=submit name=add value='$_ADD'>
</form>
</div>

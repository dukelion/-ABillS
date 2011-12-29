<div class='noprint'>
<form action='$SELF_URL' METHOD='POST'>
<input type=hidden name='index' value='$index'>
<input type=hidden name='OP_SID' value='%OP_SID%'>
<input type=hidden name='UID' value='$FORM{UID}'>
<input type=hidden name='ID' value='$FORM{chg}'>
<TABLE class=form width=500>
<TR><TD>$_SUM:</TD><TD><input type=text name='SUM' value='%SUM%'></TD></TR>
<TR><TD>$_DESCRIBE:</TD><TD><input type=text name=DESCRIBE value='%DESCRIBE%'></TD></TR>
<TR><TD>$_TYPE:</TD><TD>%TYPE_SEL%</TD></TR>
<TR><TD>$_ACCOUNT:</TD><TD>%MACCOUNT_SEL%</TD></TR>
<TR><TD>$_DATE:</TD><TD>%DATE_LIST%</TD></TR>
<TR><TD>$_CLOSED:</TD><TD><input type=checkbox name=STATUS value=1 %STATUS%></TD></TR>
<TR><TD colspan=2><hr size=1></TD></TR>
<TR><TD>EXT ID:</TD><TD><input type=text name=EXT_ID value='%EXT_ID%'></TD></TR>
<TR><TH colspan=2 class=even><input type=submit name=%ACTION% value='%ACTION_LNG%'></TH></TR>
</TABLE>

</form>
</div>

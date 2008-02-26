<form action='$SELF_URL' METHOD='POST'>
<input type=hidden name='index' value='50'>
<input type=hidden name='AID' value='%AID%'>
<TABLE>
<TR><TD>ID:</TD><TD><input type=text name=A_LOGIN value='%A_LOGIN%'></TD></TR>
<TR><TD>$_FIO:</TD><TD><input type=text name=A_FIO value='%A_FIO%'></TD></TR>
<TR><TD>$_DISABLE:</TD><TD><input type=checkbox name=DISABLE value='1' %DISABLE%></TD></TR>
<TR><TD>$_PHONE:</TD><TD><input type=text name=A_PHONE value='%A_PHONE%'></TD></TR>
<TR><TD>E-Mail</TD><TD><input type=text name=EMAIL value='%EMAIL%'></TD></TR>
<tr><TD>$_GROUPS:</TD><TD>%GROUP_SEL%</TD></TR>
</TABLE>
<input type=submit name='%ACTION%' value='%LNG_ACTION%'>
</form>

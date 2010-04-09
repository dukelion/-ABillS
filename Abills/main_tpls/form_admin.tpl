<form action='$SELF_URL' METHOD='POST'>
<input type=hidden name='index' value='50'>
<input type=hidden name='AID' value='%AID%'>
<TABLE>
<TR><TD>$_LOGIN:</TD><TD><input type=text name=A_LOGIN value='%A_LOGIN%'></TD></TR>
<TR><TD>$_FIO:</TD><TD><input type=text name=A_FIO value='%A_FIO%'></TD></TR>
<TR><TD>$_DISABLE:</TD><TD><input type=checkbox name=DISABLE value='1' %DISABLE%></TD></TR>
<TR><TD>$_PHONE:</TD><TD><input type=text name=A_PHONE value='%A_PHONE%'></TD></TR>
<TR><TD>E-Mail</TD><TD><input type=text name=EMAIL value='%EMAIL%'></TD></TR>
<tr><TD>$_GROUPS:</TD><TD>%GROUP_SEL%</TD></TR>
<tr><TD>Domain:</TD><TD>%DOMAIN_SEL%</TD></TR>
<tr><TH colspan=2 bgcolor=$_COLORS[0]>$_COMMENTS</TH></tr>
<tr><TH colspan=2><textarea name=A_COMMENTS cols=40 rows=4>%A_COMMENTS%</textarea></TH></tr>
<tr><th colspan=2 bgcolor=$_COLORS[0]>$_OTHER</th></tr>
<TR><TD>$_MAX_ROWS:</TD><TD><input type=text name=MAX_ROWS value='%MAX_ROWS%'></TD></TR>
<TR><TD>$_MIN_SEARCH_CHARS</TD><TD><input type=text name=MIN_SEARCH_CHARS value='%MIN_SEARCH_CHARS%'></TD></TR>
</TABLE>
<input type=submit name='%ACTION%' value='%LNG_ACTION%'>
</form>


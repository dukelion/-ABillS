<form action='$SELF_URL' METHOD='POST' name=admin_form>
<input type=hidden name='index' value='50'>
<input type=hidden name='AID' value='%AID%'>
<TABLE class=form>
<TR><TD>$_LOGIN:</TD><TD><input type=text name=A_LOGIN value='%A_LOGIN%'></TD></TR>
<TR><TD>$_FIO:</TD><TD><input type=text name=A_FIO value='%A_FIO%'></TD></TR>
<TR><TD>$_DISABLE:</TD><TD><input type=checkbox name=DISABLE value='1' %DISABLE%></TD></TR>
<TR><TD>$_PHONE:</TD><TD><input type=text name=A_PHONE value='%A_PHONE%'></TD></TR>
<TR><TD>$_CELL_PHONE:</TD><TD><input type=text name=CELL_PHONE value='%CELL_PHONE%'></TD></TR>
<TR><TD>E-Mail</TD><TD><input type=text name=EMAIL value='%EMAIL%'></TD></TR>
<TR><TD>$_ADDRESS:</TD><TD><input type=text name=ADDRESS value='%ADDRESS%'></TD></TR>
<TR><TH colspan='2' class='even'>$_PASPORT</TH></TR>
<TR><TD>$_NUM:</TD><TD><input type=text name=PASPORT_NUM value='%PASPORT_NUM%'> $_DATE: %PASPORT_DATE%</TD></TR>
 </TD></TR>
<TR><TD>$_GRANT:</TD><TD><textarea name=PASPORT_GRANT rows=3 cols=45>%PASPORT_GRANT%</textarea></TD></TR>
<TR><TD>$_INN:</TD><TD><input type=text name=INN value='%INN%'></TD></TR>
<TR><TD>$_BIRTHDAY:</TD><TD><input type=text name=BIRTHDAY value='%BIRTHDAY%'></TD></TR>
<tr><TD colspan=2 class=small></TD></TR>
<tr><TD>$_USERS $_GROUPS:</TD><TD>%GROUP_SEL%</TD></TR>
<tr><TD>Domain:</TD><TD>%DOMAIN_SEL%</TD></TR>
<tr><TH colspan=2 class='title_color'>$_COMMENTS</TH></tr>
<tr><TH colspan=2><textarea name=A_COMMENTS cols=40 rows=4>%A_COMMENTS%</textarea></TH></tr>
<tr><th colspan=2 class='title_color'>$_OTHER</th></tr>
<TR><TD>$_MAX_ROWS:</TD><TD><input type=text name=MAX_ROWS value='%MAX_ROWS%'></TD></TR>
<TR><TD>$_MIN_SEARCH_CHARS</TD><TD><input type=text name=MIN_SEARCH_CHARS value='%MIN_SEARCH_CHARS%'></TD></TR>
<tr><th colspan=2 class='even'><input type=submit name='%ACTION%' value='%LNG_ACTION%'></th></tr>
</TABLE>

</form>


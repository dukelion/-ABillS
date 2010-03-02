<TABLE width='100%'>
<tr bgcolor='$_COLORS[0]'><TH align='right'>$_USER_INFO</TH></tr>
</TABLE>
<form action='$SELF_URL' method='post' name='users_pi'>


<input type=hidden name=index value=$index>
<input type=hidden name=UID value='%UID%'>
<TABLE width=450 cellspacing=0 cellpadding=3>
<TR><TD>$_FIO:*</TD><TD><textarea name='FIO' rows=2 cols=45>%FIO%</textarea>
<TR><TD>$_ACCEPT_RULES:</TD><TD>%ACCEPT_RULES%</TD></TR>
<TR><TD>$_PHONE:</TD><TD><input type=text name=PHONE value='%PHONE%'></TD></TR>
%ADDRESS_TPL%
<TR><TD>E-mail:</TD><TD><input type=text name=EMAIL value='%EMAIL%' size=45></TD></TR>
<TR><TD>$_CONTRACT_ID:</TD><TD><input type=text name=CONTRACT_ID value='%CONTRACT_ID%' size=10>%CONTRACT_SUFIX% $_DATE: 
%CONTRACT_DATE% <br>%CONTRACT_TYPE% %PRINT_CONTRACT%</TD></TR>
<TR><TH colspan='2' bgcolor='$_COLORS[2]'>$_PASPORT</TH></TR>
<TR><TD>$_NUM:</TD><TD><input type=text name=PASPORT_NUM value='%PASPORT_NUM%'> $_DATE: %PASPORT_DATE%</TD></TR>
 </TD></TR>
<TR><TD>$_GRANT:</TD><TD><textarea name=PASPORT_GRANT rows=3 cols=45>%PASPORT_GRANT%</textarea></TD></TR>
%INFO_FIELDS%

<TR><th colspan=2  bgcolor='$_COLORS[2]'>:$_COMMENTS:</th></TR>
<TR><th colspan=2><textarea name=COMMENTS rows=5 cols=60>%COMMENTS%</textarea></th></TR>

</TABLE>


<input type=submit name='%ACTION%' value='%LNG_ACTION%'>
</form>

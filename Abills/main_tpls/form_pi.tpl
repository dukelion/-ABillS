<TABLE width='100%'>
<tr bgcolor='$_COLORS[0]'><TH align='right'>$_USER_INFO</TH></tr>
</TABLE>
<form action='$SELF_URL' method='post'>
<input type=hidden name=index value=$index>
<input type=hidden name=UID value='%UID%'>
<TABLE width=420 cellspacing=0 cellpadding=3>
<TR><TD>$_FIO:*</TD><TD><textarea name='FIO' rows=2 cols=45>%FIO%</textarea>
<TR><TD>$_PHONE:</TD><TD><input type=text name=PHONE value='%PHONE%'></TD></TR>
<TR><TD>$_ADDRESS_STREET:</TD><TD><input type=text name=ADDRESS_STREET value='%ADDRESS_STREET%'></TD></TR>
<TR><TD>$_ADDRESS_BUILD:</TD><TD><input type=text name=ADDRESS_BUILD value='%ADDRESS_BUILD%'> $_ADDRESS_FLAT:<input type=text name=ADDRESS_FLAT value='%ADDRESS_FLAT%' size=8></TD></TR>
<TR><TD>$_CITY:</TD><TD><input type=text name=CITY value='%CITY%'> $_ZIP: <input type=text name=ZIP value='%ZIP%' size=8></TD></TR>
<TR><TD>E-mail:</TD><TD><input type=text name=EMAIL value='%EMAIL%'></TD></TR>
<TR><TD>$_CONTRACT_ID:</TD><TD><input type=text name=CONTRACT_ID value='%CONTRACT_ID%'></TD></TR>
<TR><TH colspan='2' bgcolor='$_COLORS[2]'>$_PASPORT</TH></TR>
<TR><TD>$_NUM:</TD><TD><input type=text name=PASPORT_NUM value='%PASPORT_NUM%'></TD></TR>
<TR><TD>$_DATE:</TD><TD><input type=text name=PASPORT_DATE value='%PASPORT_DATE%'></TD></TR>
<TR><TD>$_GRANT:</TD><TD><textarea name=PASPORT_GRANT rows=3 cols=45>%PASPORT_GRANT%</textarea></TD></TR>
<TR><th colspan=2>:$_COMMENTS:</th></TR>
<TR><th colspan=2><textarea name=COMMENTS rows=5 cols=45>%COMMENTS%</textarea></th></TR>
</TABLE>
<input type=submit name='%ACTION%' value='%LNG_ACTION%'>
</form>

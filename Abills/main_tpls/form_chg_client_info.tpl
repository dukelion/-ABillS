<form action='$SELF_URL' method='post'>
<input type=hidden name=index value=$index>
<input type=hidden name=sid value='$sid'>
<TABLE width=600 class='form'>
<TR><TD>$_FIO:*</TD><TD><textarea name='FIO' rows=2 cols=45>%FIO%</textarea></TD></TR>
<TR><TD>$_PHONE:</TD><TD><input type=text name=PHONE value='%PHONE%'></TD></TR>
<TR><TD>$_ADDRESS_STREET:</TD><TD><input type=text name=ADDRESS_STREET value='%ADDRESS_STREET%'></TD></TR>
<TR><TD>$_ADDRESS_BUILD:</TD><TD><input type=text name=ADDRESS_BUILD value='%ADDRESS_BUILD%'></TD></TR>
<TR><TD>$_ADDRESS_FLAT:</TD><TD><input type=text name=ADDRESS_FLAT value='%ADDRESS_FLAT%'></TD></TR>
<TR><TD>$_CITY:</TD><TD><input type=text name=CITY value='%CITY%'> $_ZIP: <input type=text name=ZIP value='%ZIP%' size=8></TD></TR>
<TR><TD>E-mail:</TD><TD><input type=text name=EMAIL value='%EMAIL%'></TD></TR>
<TR><TH colspan=2 class=even><input type=submit name='%ACTION%' value='%LNG_ACTION%'></TH></TR>
</TABLE>

</form>

<TABLE border='0' width=100%>

<TR><TD>
<b>$_DELIGATE: </b><a class=link_button href='$SELF_URL?index=$index&deligate=$FORM{chg}&level=%DELIGATED_DOWN%'>$_DOWN (%DELIGATED_DOWN%) </a>&nbsp;
<a class=link_button href='$SELF_URL?index=$index&deligate=$FORM{chg}&level=%DELIGATED%'>$_UP (%DELIGATED%)</a>
</TD></TR>

<TR><TD><b>$_USER:</b> </TD></TR>
<TR><TD>%USER_READ%</TD></TR>
<TR><TD><b>$_ADMIN:</b> </TD></TR>
<TR><TD>%ADMIN_READ%</TD></TR>

<TR><TD>&nbsp;</TD></TR>

<TR><TD><b>$_RESPOSIBLE:</b></td></tr>
<TR><TD>%RESPOSIBLE%</TD></TR>
<TR><TD><b>$_INNER:</b> %INNER_MSG%</TD></TR>
<TR><TD><b>$_PHONE:</b> %PHONE%</TD></TR>

<TR><TD>&nbsp;</TD></TR>
<TR><TD><b>$_STATE:</b> </TD></TR>
<TR><TD>%STATE_NAME%</TD></TR>
<TR><TD><b>$_PRIORITY:</b> </TD></TR>
<TR><TD>%PRIORITY_SEL%</TD></TR>
<TR><TD><b>$_DISPATCH:</b> </TD></TR>
<TR><TD>%DISPATCH_SEL%</TD></TR>
<TR><TD><b>$_EXECUTION:</b></TD></TR>
<TR><TD>$_DATE: %PLAN_DATE%</TD></TR>
<TR><TD>$_TIME: <input type=text value='%PLAN_TIME%' name='PLAN_TIME'></TD></TR>
<TR><TD><b>$_CLOSED:</b> %CLOSED_DATE%</TD></TR>
<TR><TD><b>$_DONE:</b> %DONE_DATE%</TD></TR>


<TR><TD align=center><input type=submit name=change value='$_CHANGE' class='noprint'></TD></TR>
</TABLE>

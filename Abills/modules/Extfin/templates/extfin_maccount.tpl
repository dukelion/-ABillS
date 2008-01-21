<div class='noprint'>
<form action='$SELF_URL' METHOD='POST'>
<input type=hidden name=index value=$index>
<input type=hidden name=ID value=%ID%>
<TABLE>
<TR><TD>ID:</TD><TD>%ID%</TD></TR>
<TR><TD>$_DATE:</TD><TD>%DATE%</TD></TR>
<TR><TD>$_NAME:</TD><TD><input type=text name=NAME value='%NAME%'></TD></TR>
<TR><TD>$_EXPIRE:</TD><TD><input type=text name=EXPIRE value='%EXPIRE%'></TD></TR>
<TR bgcolor='$_COLORS[0]'><TH colspan='2'>$_COMMENTS</TH></TR>
<TR><TH colspan='2'><textarea cols='50' rows='5' name='COMMENTS'>%COMMENTS%</textarea></TH></TR>
</TABLE>
<input type=submit name=%ACTION% value='%ACTION_LNG%'>
</form>
</div>

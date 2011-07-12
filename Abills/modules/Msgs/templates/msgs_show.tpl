<FORM action='$SELF_URL' METHOD='POST'  enctype='multipart/form-data' name=add_message>
<input type='hidden' name='index' value='$index'/>
<input type='hidden' name='UID' value='$FORM{UID}'/>
<input type='hidden' name='ID' value='%ID%'/>
<input type='hidden' name='PARENT' value='%PARENT%'/>
<input type='hidden' name='CHAPTER' value='%CHAPTER%'/>
<input type='hidden' name='INNER_MSG' value='%INNER_MSG%'/>


<TABLE width='100%' cellspacing='0' cellpadding='0' border='0'><TR><TD bgcolor='#E1E1E1' valign='top'>
<TABLE width='100%' cellspacing='1' cellpadding='0' border='0' style='height: 100%'>
<!-- <tr bgcolor=$_COLORS[1]><TD>%THREADS%</td></tr> -->

<tr><th colspan=4 align=left bgcolor=$_COLORS[2]> > %SUBJECT%</th></tr>
<tr><td colspan=4>

<table cellspacing='1' cellpadding='0' border='0' width=100%>
<tr><td  bgcolor=$_COLORS[1]>ID:</td><td  bgcolor=$_COLORS[1]>%ID%</td><td  bgcolor=$_COLORS[1]>$_CHAPTERS:</td><td  bgcolor=$_COLORS[1]>%CHAPTER_NAME%</td></tr>
<tr><td  bgcolor=$_COLORS[1]>$_STATUS:</td><td  bgcolor=$_COLORS[1]>%STATE_NAME%</td><td  bgcolor=$_COLORS[1]>$_PRIORITY:</td><td  bgcolor=$_COLORS[1]>%PRIORITY_TEXT%</td></tr>
<tr><td  bgcolor=$_COLORS[1]>$_CREATED:</td><td  bgcolor=$_COLORS[1]>%DATE%</td><td  bgcolor=$_COLORS[1]>$_UPDATED:</td><td  bgcolor=$_COLORS[1]>%UPDATED%</td></tr>
</table>

</th></tr>
<tr><th colspan=4 align=left bgcolor=$_COLORS[1]>&nbsp;</th></tr>
<tr bgcolor=$_COLORS[3]><td colspan=4> 
<table cellspacing='1' cellpadding='0' border='0' width=100%>
<tr><th align=left  bgcolor=$_COLORS[0]> %LOGIN% </th></tr>
<tr><td class=medium align=left>$_ADDED: %DATE%</td></tr>
</table>
</td></tr>
<tr><td bgcolor='$_COLORS[1]' colspan='4'>%MESSAGE%</td></tr>
<tr><td class=medium  colspan='4'>%ATTACHMENT%</td></tr>
<tr><td colspan='4' bgcolor='$_COLORS[1]'>%REPLY%</td></tr>
</TABLE>

</TD><td width='200' valign='top' bgcolor='$_COLORS[2]'>
<TABLE width='100%' cellspacing='1' cellpadding='0' border='0'>
<tr><td>


%EXT_INFO%

</td></tr>
</TABLE>
</td>
</TR>
</TABLE>

</form>

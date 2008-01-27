<FORM action='$SELF_URL' METHOD='POST'  enctype='multipart/form-data'>
<input type='hidden' name='index' value='$index'/>
<input type='hidden' name='UID' value='$FORM{UID}'/>
<input type='hidden' name='ID' value='%ID%'/>
<input type='hidden' name='PARENT' value='%PARENT%'/>

<TABLE width='99%' cellspacing='0' cellpadding='0' border='0'><TR><TD bgcolor='#E1E1E1' valign='top'>
<TABLE width='100%' cellspacing='1' cellpadding='0' border='0' style='height: 100%'>
<!-- <tr bgcolor=$_COLORS[1]><TD>%THREADS%</td></tr> -->

<tr bgcolor=$_COLORS[3]><td colspan='4'># %ID%: <b>%SUBJECT%</b></td></tr>
<tr bgcolor=$_COLORS[1]><td>$_DATE:</td><td>%DATE%</td><td>$_CHAPTERS:</td><td>%CHAPTER_NAME%</td></tr>

<tr><td bgcolor='$_COLORS[1]' colspan='4'>%MESSAGE%</td></tr>
<tr><td bgcolor='$_COLORS[2]' colspan='4'>%ATTACHMENT%</td></tr>
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

<FORM action='$SELF_URL' METHOD='POST'  enctype='multipart/form-data'>
<input type='hidden' name='qindex' value='$index'/>
<input type='hidden' name='UID' value='$FORM{UID}'/>
<input type='hidden' name='ID' value='%ID%'/>
<input type='hidden' name='PARENT' value='%PARENT%'/>

<TABLE width='100%' cellspacing='0' cellpadding='0' border='0'><TR><TD bgcolor='#E1E1E1' valign='top'>
<TABLE width='100%' cellspacing='1' cellpadding='0' border='0' style='height: 100%'>
<!-- <tr bgcolor=$_COLORS[1]><TD>%THREADS%</td></tr> -->

<tr><th colspan=4 align=left bgcolor=$_COLORS[2]> > %SUBJECT%</th></tr>
<tr><td colspan=4>

<table cellspacing='1' cellpadding='0' border='0' width=100%>
<tr><td  bgcolor=$_COLORS[1]>ID:</td><td  bgcolor=$_COLORS[1]>%ID%</td><td  bgcolor=$_COLORS[1]>$_CHAPTERS:</td><td  bgcolor=$_COLORS[1]>%CHAPTER%</td></tr>
<tr><td  bgcolor=$_COLORS[1]>$_STATUS:</td><td  bgcolor=$_COLORS[1]>%STATE_SEL%</td><td  bgcolor=$_COLORS[1]>$_PRIORITY:</td><td  bgcolor=$_COLORS[1]>%PRIORITY_SEL%</td></tr>
<tr><td  bgcolor=$_COLORS[1]>$_CREATED:</td><td  bgcolor=$_COLORS[1]>%DATETIME%</td><td  bgcolor=$_COLORS[1]>$_CLOSED:</td><td  bgcolor=$_COLORS[1]>%CLOSED_DATE%</td></tr>
</table>

</th></tr>
<tr><th colspan=4 align=left bgcolor=$_COLORS[1]>&nbsp;</th></tr>
<tr bgcolor=$_COLORS[3]><td colspan=4> 
<table cellspacing='1' cellpadding='0' border='0' width=100%>
<tr><th align=left bgcolor='$_COLORS[1]'>$_FIO:</th><th align=left  bgcolor=$_COLORS[1]> %FIO% </th></tr>
<tr><th align=left bgcolor='$_COLORS[1]'>$_COMPANY:</th><td bgcolor='$_COLORS[1]'> %COMPANY%</td></tr>
<tr><th align=left bgcolor='$_COLORS[1]'>$_PHONE:</th><td bgcolor='$_COLORS[1]'> %PHONE% </td></tr>
<tr><th align=left bgcolor='$_COLORS[1]'>$_ADDRESS:</th><td bgcolor='$_COLORS[1]'> %ADDRESS_STREET%  %ADDRESS_BUILD% %ADDRESS_FLAT%</td></tr>
<tr><th align=left bgcolor='$_COLORS[1]'>E-mail:</th><td bgcolor='$_COLORS[1]'> %EMAIL%</td></tr>
</table>
</td></tr>
<tr><td bgcolor='$_COLORS[1]' colspan='4'>&nbsp; %REQUEST%</td></tr>
<tr><td bgcolor='$_COLORS[2]' colspan='4' class=small></td></tr>
<tr><td colspan='4' bgcolor='$_COLORS[2]' align=center><textarea cols=65 rows=20 name=COMMENTS>%COMMENTS%</textarea></td></tr>
<tr><td colspan='4' bgcolor='$_COLORS[1]' align=center><input type=submit name=change value=$_CHANGE></td></tr>
</TABLE>

</TD>
</TR>
</TABLE>
</form>

<div class='noprint' align=center>
<p>
<a href=\"javascript:window.print();\" class=linkm1><b>$_PRINT</b></a> :: 
<a href=\"javascript:window.close();\" class=linkm1><b>$_CLOSE</b></a>
</p>
</div>

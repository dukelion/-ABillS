

<FORM action='$SELF_URL' METHOD='POST'  enctype='multipart/form-data'>
<input type='hidden' name='index' value='$index'/>
<input type='hidden' name='UID' value='$FORM{UID}'/>
<input type='hidden' name='ID' value='%ID%'/>
<input type='hidden' name='PARENT' value='%PARENT%'/>

<table>
<tr><td>$_DATE:</td><td>%DATE%</td></tr>
<tr><td>$_CHAPTERS:</td><td>%CHAPTER_SEL%</td></tr>
<tr><td>$_SUBJECT:</td><td><input type='text' name='SUBJECT' value='%SUBJECT%' size='50'/></td></tr>

<tr><th bgcolor='$_COLORS[0]' colspan='2'>$_MESSAGE</th></tr>
<tr><th colspan='2'><textarea name='MESSAGE' cols='70' rows='9'>%MESSAGE%</textarea></th></tr>
<tr><td>$_FIO:</td><td><input type='text' name='FIO' value='%FIO%' size='45'/></td></tr>
<tr><td>$_PHONE:</td><td><input type='text' name='PHONE' value='%PHONE%' size='45'/></td></tr>

%ADDRESS_TPL%

<tr><td>$_STATE:</td><td>%STATE_SEL%</td></tr>  
<tr><td>$_PRIORITY:</td><td>%PRIORITY_SEL%</td></tr>
<TR><TD>$_RESPOSIBLE:</TD><TD>%RESPOSIBLE%</TD></TR>
</table>
<input type='submit' name='%ACTION%' value='%ACTION_LNG%'/>
</FORM>

<FORM action='$SELF_URL' METHOD='POST'  enctype='multipart/form-data'>
<input type='hidden' name='index' value='$index'/>
<input type='hidden' name='UID' value='$FORM{UID}'/>
<input type='hidden' name='ID' value='%ID%'/>
<input type='hidden' name='PARENT' value='%PARENT%'/>

<table>
<tr><td>$_DATE:</td><td>%DATE%</td></tr>
<tr><td>$_CHAPTERS:</td><td>%CHAPTER_SEL%</td></tr>
<tr><td>$_SUBJECT:</td><td><input type='text' name='SUBJECT' value='%SUBJECT%' size='50'/></td></tr>

<tr><td>$_INNER</td><td><input type=checkbox name=INNER_MSG value=1 %INNER_MSG%></td></tr>

<tr><td>$_LOGIN / $_GROUP:</td><td>%USER%</td></tr>
<tr><th bgcolor='$_COLORS[0]' colspan='2'>$_MESSAGE</th></tr>
<tr><th colspan='2'><textarea name='MESSAGE' cols='70' rows='9'>%MESSAGE%</textarea></th></tr>

%ATTACHMENT%
<tr><td>$_ATTACHMENT:</td><td><input name='FILE_UPLOAD' type='file' size='40' class='fixed'>
                  <input class='button' type='submit' name='AttachmentUpload' value='$_ADD'></td></tr>  
<tr><td>$_STATE:</td><td>%STATE_SEL%</td></tr>  
<tr><td>$_PRIORITY:</td><td>%PRIORITY_SEL%</td></tr>
<TR><TD>$_RESPOSIBLE:</TD><TD>%RESPOSIBLE%</TD></TR>
<TR><TD>$_EXECUTION $_DATE:</TD><TD><input type=text value='%PLAN_DATE%' name='PLAN_DATE'> $_TIME: <input type=text value='%PLAN_TIME%' name='PLAN_TIME'></TD></TR>

<tr><td>$_LOCK:</td><td><input type=checkbox name=LOCK value=1 %LOCK%></td></tr>
%SEND_EMAIL%
</table>
<input type='submit' name='%ACTION%' value='%ACTION_LNG%'/>
</FORM>

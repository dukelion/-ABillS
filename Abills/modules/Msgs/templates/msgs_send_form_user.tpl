<FORM action='$SELF_URL' METHOD='POST'  enctype='multipart/form-data'>
<input type='hidden' name='index' value='$index'/>
<input type='hidden' name='sid' value='$sid'/>
<input type='hidden' name='ID' value='%ID%'/>
<table>
<tr><td>$_SUBJECT:</td><td><input type='text' name='SUBJECT' value='%SUBJECT%' size='50'/></td></tr>
<tr><td>$_CHAPTERS:</td><td>%CHAPTER_SEL%</td></tr>
<tr><th bgcolor='$_COLORS[0]' colspan='2'>$_MESSAGE</th></tr>
<tr><th colspan='2'><textarea name='MESSAGE' cols='70' rows='9'>%MESSAGE%</textarea></th></tr>


%ATTACHMENT%
<tr><td>$_ATTACHMENT:</td><td><input name='FILE_UPLOAD' type='file' size='40' class='fixed'>
                  <input class='button' type='submit' name='AttachmentUpload' value='$_ADD'></td></tr>  
<tr><td>$_STATE:</td><td>%STATE_SEL%</td></tr>  
<tr><td>$_PRIORITY:</td><td>%PRIORITY_SEL%</td></tr>

</table>
<input type='submit' name='send' value='$_SEND'/>
</FORM>

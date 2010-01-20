</div class=noprint id=form_msg_add>
<FORM action='$SELF_URL' METHOD='POST'  enctype='multipart/form-data'>
<input type='hidden' name='index' value='$index'/>
<input type='hidden' name='sid' value='$sid'/>
<input type='hidden' name='ID' value='%ID%'/>
<TABLE width=500 cellspacing=0 cellpadding=0 border=0>
<TR><TD bgcolor=#E1E1E1>
<TABLE width=100% cellspacing=1 cellpadding=0 border=0>
<TR><TD bgcolor=#FFFFFF>

<table width=100%>
<tr><td>$_SUBJECT:</td><td><input type='text' name='SUBJECT' value='%SUBJECT%' size='50'/></td></tr>
<tr><td>$_CHAPTERS:</td><td>%CHAPTER_SEL%</td></tr>
<tr><th bgcolor='$_COLORS[0]' colspan='2'>$_MESSAGE</th></tr>
<tr><th colspan='2'><textarea name='MESSAGE' cols='70' rows='9'>%MESSAGE%</textarea></th></tr>


%ATTACHMENT%
<tr><td>$_ATTACHMENT:</td><td><input name='FILE_UPLOAD' type='file' size='40' class='fixed'>
                  <!-- <input class='button' type='submit' name='AttachmentUpload' value='$_ADD'> --></td></tr>  
<tr><td>$_STATE:</td><td>%STATE_SEL%</td></tr>  
<tr><td>$_PRIORITY:</td><td>%PRIORITY_SEL%</td></tr>
<tr><th colspan=2><input type='submit' name='send' value='$_SEND'/></th></tr>
</table>
</td></tr></table>
</td></tr></table>


</FORM>

</div>

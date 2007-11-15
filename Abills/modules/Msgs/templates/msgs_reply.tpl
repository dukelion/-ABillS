<div class='noprint'>
<table width=100%>
<tr><th bgcolor='$_COLORS[0]' colspan='2'>$_REPLY</th></tr>
<tr><td>$_SUBJECT:</td><td><input type='text' name='REPLY_SUBJECT' value='%REPLY_SUBJECT%' size=40/></td></tr>
<tr><th colspan='2'><textarea name='REPLY_TEXT' cols='70' rows='9'>%REPLY_TEXT%</textarea></th></tr>

%ATTACHMENT%
<tr><td>$_ATTACHMENT:</td><td><input name='FILE_UPLOAD' type='file' size='40' class='fixed'>
   <input class='button' type='submit' name='AttachmentUpload' value='$_ADD'></td></tr>  
</table>
<input type='hidden' name='sid' value='$sid'/>
<input type='submit' name='%ACTION%' value='  %ACTION_LNG%  '/>
<br>
<br>
</div>

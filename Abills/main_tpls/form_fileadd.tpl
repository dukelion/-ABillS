
<div class='noprint' align=center>
<FORM action='$SELF_URL' METHOD='POST'  enctype='multipart/form-data'>
<input type='hidden' name='index' value='$index'>
<input type='hidden' name='NAS_GID' value='$FORM{NAS_GID}'>
<table width=600>
<tr><th colspan=2 align='right' bgcolor=$_COLORS[0]>$_ADD $_FILE</th></tr>
<tr><td>$_FILE:</td><td><input name='FILE_UPLOAD' type='file' size='40' class='fixed'>
   <input class='button' type='submit' name='UPLOAD' value='$_ADD'></td></tr>  
</table>
</FORM>
</div>

<form action='$SELF_URL' METHOD='post' enctype='multipart/form-data' name=add_district>
<input type='hidden' name='index' value='$index'/>
<input type='hidden' name='ID' value='%ID%'/>
<TABLE class='form'>
<TR><TH class='form_title' colspan='2'>$_DISTRICTS</TH></TR>
<TR><TD>$_NAME:</TD><TD><input type='text' name='NAME' value='%NAME%'/></TD></TR>
<TR><TD>$_COUNTRY:</TD><TD>%COUNTRY_SEL%</TD></TR>
<TR><TD>$_CITY:</TD><TD><input type='text' name='CITY' value='%CITY%'/></TD></TR>
<TR><TD>$_ZIP:</TD><TD><input type='text' name='ZIP' value='%ZIP%'/></TD></TR>
<tr><td>$_MAP (*.jpg, *.gif, *.png):</td><td><input name='FILE_UPLOAD' type='file' class='fixed'>
<TR><TH colspan=2>$_COMMENTS</TH></TD></TR>
<TR><TH colspan=2><textarea name=COMMENTS rows=4 cols=50>%COMMENTS%</textarea></TH></TD></TR>
<TR><TH colspan=2 class='even'><input type='submit' name='%ACTION%' value='%LNG_ACTION%' class='button'/></TH></TD></TR>
</TABLE>

</form>

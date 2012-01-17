<form action='$SELF_URL' METHOD='post'>
<input type='hidden' name='index' value='$index'/>
<input type='hidden' name='ID' value='$FORM{chg}'/>
<TABLE class=form>
<TR><TD>$_NAME: </TD><TD><input type='text' name='NAME' value='%NAME%'/></TD></TR>
<TR><TD>$_DISABLE: </TD><TD><input type='checkbox' name='DISABLE' value='1' %DISABLE% ></TD></TR>
<TR><TH colspan=2>$_COMMENTS</TH></TR>
<TR><TH colspan=2><textarea cols=50 name=COMMENTS rows=10>%COMMENTS%</textarea></TH></TR>
<TR><TH colspan=2><input type='submit' name='%ACTION%' value='%LNG_ACTION%' class='button'/></th></tr>
</TABLE>
</form>

<form action='$SELF_URL' METHOD='post'>
<input type='hidden' name='index' value='27'/>
<input type='hidden' name='chg' value='%GID%'/>
<TABLE>
<TR><TD>GID:</TD><TD><input type='text' name='GID' value='%GID%'/></TD></TR>
<TR><TD>$_NAME:</TD><TD><input type='text' name='G_NAME' value='%G_NAME%'/></TD></TR>
<TR><TD>$_DESCRIBE:</TD><TD><input type='text' name='G_DESCRIBE' value='%G_DESCRIBE%'></TD></TR>
<TR><TD>$_DOCS:</TD><TD><input type='checkbox' name='SEPARATE_DOCS' value='1' %SEPARATE_DOCS%></TD></TR>
</TABLE>
<input type='submit' name='%ACTION%' value='%LNG_ACTION%' class='button'/>
</form>

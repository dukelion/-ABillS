<form action='$SELF_URL' METHOD='post'>
<input type='hidden' name='index' value='$index'/>
<input type='hidden' name='ID' value='%GID%'/>
<TABLE>
<TR><TD>GID:</TD><TD><input type='text' name='GID' value='%GID%'/></TD></TR>
<TR><TD>$_NAME:</TD><TD><input type='text' name='NAME' value='%NAME%'/></TD></TR>
<TR><TD>$_USER_CHG_TP:</TD><TD><input type='checkbox' name='USER_CHG_TP' value='1' %USER_CHG_TP%></TD></TR>
</TABLE>
<input type='submit' name='%ACTION%' value='%LNG_ACTION%' class='button'/>
</form>

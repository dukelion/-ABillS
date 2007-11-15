<FORM action=$SELF_URL METHOD=POST>
<input type=hidden name=index value=$index>
<input type=hidden name=ID value='$FORM{chg}'>
<input type=hidden name=UID value='$FORM{UID}'>
<TABLE>
<TR><TD>ID:</TD><TD><input type=text name=BINDING value='%BINDING%'></TD></TR>
<TR><TD>$_PARAMS:</TD><TD><input type=text name=PARAMS value='%PARAMS%'></TD></TR>
<TR><TD>$_COMMENTS:</TD><TD><input type=text name=COMMENTS value='%COMMENTS%'></TD></TR>
</TABLE>
<input type='submit' name='%ACTION%' value='%ACTION_LNG%' class='button'/>
</FORM>

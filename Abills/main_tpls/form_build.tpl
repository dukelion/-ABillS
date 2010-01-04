<form action='$SELF_URL' METHOD='post'>
<input type='hidden' name='index' value='$index'/>
<input type='hidden' name='ID' value='%ID%'/>
<input type='hidden' name='BUILDS' value='$FORM{BUILDS}'/>
<input type='hidden' name='STREET_ID' value='$FORM{BUILDS}'/>
<TABLE>
<TR><TH class='form_title' colspan='2'>$_ADDRESS_BUILD</TH></TR>
<TR><TD>$_NUM:</TD><TD><input type='text' name='NUMBER' value='%NUMBER%' size=6 /></TD></TR>
<TR><TD>$_ADDRESS_STREET:</TD><TD>%STREET_SEL%</TD></TR>
<TR><TD>$_FLORS:</TD><TD><input type='text' name='FLORS' value='%FLORS%' size=6 /></TD></TR>
<TR><TD>$_ENTRANCES:</TD><TD><input type='text' name='ENTRANCES' value='%ENTRANCES%' size=6  /></TD></TR>
<TR><TD>$_MAP:</TD><TD>X: <input type='text' name='MAP_X' value='%MAP_X%' size=6 /> Y: <input type='text' name='MAP_Y' value='%MAP_Y%' size=6/></TD></TR>
<TR><TD>$_ADDED:</TD><TD>%ADDED%</TD></TR>
</TABLE>
<input type='submit' name='%ACTION%' value='%LNG_ACTION%' class='button'/>
</form>

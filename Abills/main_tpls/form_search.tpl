<div class='noprint'>

<form action='$SELF_URL' METHOD='POST'>
<input type='hidden' name='index' value='$index'>
%HIDDEN_FIELDS%
<TABLE>

<TR bgcolor='$_COLORS[0]'><TH colspan='2' align='right'>$_SEARCH</TH></TR>
%SEL_TYPE%
<TR><TD>$_LOGIN:</TD><TD><input tabindex=1 type='text' name='LOGIN_EXPR' value='%LOGIN_EXPR%'></TD></TR>
<tr><TD>$_PERIOD:</TD><TD>
<TABLE width='100%'>
<TR><TD>$_FROM: </TD><TD>%FROM_DATE%</TD></TR>
<TR><TD>$_TO:</TD><TD>%TO_DATE%</TD></TR>
</TABLE>
</TD></TR>
<TR><TD colspan=2>&nbsp;</TD></TR>
<TR><TD>$_ROWS:</TD><TD><input tabindex=2 type='text' name='PAGE_ROWS' value='$PAGE_ROWS'></TD></TR>
%SEARCH_FORM%
</TABLE>
<input type='submit' name='search' value='$_SEARCH'>
</form>
</div>
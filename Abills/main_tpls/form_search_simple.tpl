<form action='$SELF_URL' METHOD='POST'>
<input type=hidden name='index' value='$index'>
%HIDDEN_FIELDS%
<TABLE>
<TR bgcolor='$_COLORS[0]'><TH colspan='2' align='right'>$_SEARCH</TH></TR>
%SEARCH_FORM%
<TR><TD>$_ROWS:</TD><TD><input type='text' name='PAGE_ROWS' value='$PAGE_ROWS'></TD></TR>
</TABLE>
<input type=submit name='search' value='$_SEARCH' class='button'>
</form>

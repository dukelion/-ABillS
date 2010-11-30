<div class='noprint'>

<form action='$SELF_URL' METHOD='POST' name='form_search'>
<input type='hidden' name='index' value='$index'>
%HIDDEN_FIELDS%
<TABLE>

<TR bgcolor='$_COLORS[0]'><TH colspan='2' align='right'>$_SEARCH</TH></TR>
%SEL_TYPE%
<TR><TD>$_LOGIN (*,):</TD><TD><input tabindex=1 type='text' name='LOGIN_EXPR' value='%LOGIN_EXPR%'></TD></TR>
<TR><TD>$_PERIOD:</TD><TD>$_FROM: %FROM_DATE% $_TO: %TO_DATE% </TD></TR>
<TR><TD>$_ROWS:</TD><TD><input tabindex=2 type='text' name='PAGE_ROWS' value='$PAGE_ROWS' size=8></TD></TR>
%SEARCH_FORM%
</TABLE>
<input type='submit' name='search' value='$_SEARCH'>
</form>
</div>
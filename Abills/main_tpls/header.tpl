<tr class='HEADER' bgcolor='$_COLORS[3]'><td colspan='2'>
<div class='header'>
<form action='$SELF_URL'>
<table width='100%' border='0'>
  <tr><th align='left'>$_DATE: %DATE% %TIME% Admin: <a href='$SELF_URL?index=53'>$admin->{A_LOGIN}</a> / Online: <abbr title=\"%ONLINE_USERS%\"><a href='$SELF_URL?index=50' title='%ONLINE_USERS%'>Online: %ONLINE_COUNT%</a></abbr></th>  <th align='right'><input type='hidden' name='index' value='7'/><input type='hidden' name='search' value='1'/>
  $_SEARCH: %SEL_TYPE% <input type='text' name='LOGIN_EXPR' value=''/> 
  (<b><a href='#' onclick=\"window.open('help.cgi?index=$index&amp;FUNCTION=$functions{$index}','help',
    'height=550,width=450,resizable=0,scrollbars=yes,menubar=no, status=yes');\">?</a></b>)</th></tr>
</table>
</form>
</div>
</td></tr>
%TECHWORK%

<form action=$SELF_URL>
<input type=hidden name=index value=$index>
<table border=1 width=300>
<TR><TH class='form_title' colspan='2'>$_STREETS $_SEARCH</TH></TR>
<tr><td>$_ADDRESS_STREET:</td><td>%STREET_SEL%</td></tr>
<tr><td>$_SEARCH:</td><td><input type=text name=index name='NAME' value='%NAME%'></td></tr>
<tr><th colspan=2>$_BUILDS</th></tr>
<tr><td colspan=2>%BUILDS%</td></tr>
<tr><th colspan=2><input type=submit name=search value='$_SEARCH'></th></tr>
</table>
</form>
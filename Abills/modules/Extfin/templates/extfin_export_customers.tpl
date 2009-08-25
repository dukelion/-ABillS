<FORM action=$SELF_URL METHOD=POST > 
<input type=hidden name=qindex value=$index>
<table width=500 border=0>
<tr><td>$_GROUP:</td><td>%GROUP_SEL%</td></tr>
<tr><td>$_DATE:</td><td><TABLE width=100%>
<tr><td>$_FROM:</td><td>%DATE_FROM%</td></tr> 
<tr><td>TO:</td><td>%DATE_TO%</td></tr>
</table>

</td></tr>
<tr><td>$_REPORT $_TYPE:</td><td>%TYPE_SEL%</td></tr>

<tr><td>$_USER $_TYPE:</td><td>%USER_TYPE_SEL%</td></tr>

<tr><td>$_INFO_FIELDS:</td><td>%INFO_FIELDS%</td></tr>

<tr><td>XML:</td><td><input type=checkbox name=xml value=1></td></tr>
<tr><td>$_ROWS:</td><td><input type=text name=PAGE_ROWS value='$PAGE_ROWS'></td></tr>
</table>
<input type=submit name=%ACTION% value=%ACTION_LNG%>
</FORM>

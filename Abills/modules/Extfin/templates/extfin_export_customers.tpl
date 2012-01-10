<FORM action=$SELF_URL METHOD=POST name='extfin'> 
<input type=hidden name=index value=$index>
<table class=form>
<tr><th colspan=2 class=form_title>$_EXPORT : $_USERS</th></tr>
<tr><td>$_GROUP:</td><td>%GROUP_SEL%</td></tr>
<tr><td>$_DATE:</td><td><TABLE width=100%>
<tr><td>$_FROM:</td><td>%FROM_DATE%</td></tr> 
<tr><td>$_TO:</td><td>%TO_DATE%</td></tr>
</table>

</td></tr>
<tr><td>$_REPORT $_TYPE:</td><td>%TYPE_SEL%</td></tr>

<tr class=even><td>$_USER $_TYPE:</td><td>%USER_TYPE_SEL%</td></tr>
<tr class=even><td>$_TOTAL:</td><td><input type=checkbox name=TOTAL_ONLY value=1></td></tr>

<tr><td>$_INFO_FIELDS <br>($_USERS):</td><td>%INFO_FIELDS%</td></tr>
<tr class=even><td>$_INFO_FIELDS <br>($_COMPANIES):</td><td>%INFO_FIELDS_COMPANIES%</td></tr>

<tr><td>$_ROWS:</td><td><input type=text name=PAGE_ROWS value='$PAGE_ROWS'></td></tr>
<tr><th colspan=2 class=even><input type=submit name=%ACTION% value=%ACTION_LNG%></th></tr>
</table>

</FORM>

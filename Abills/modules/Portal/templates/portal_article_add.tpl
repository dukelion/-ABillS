<form action=$SELF_URL name=\"portal_form\" method=POST>
<input type=hidden name=index value=$index>
<input type=hidden name=ID value=%ID%>
<table border=\"0\">
	<tr>
	<th colspan=2 class=\"table_title\" align=%ALIGN%>%TITLE_NAME%</th>
	</tr>  
	 <tr>
    	<td align=%ALIGN% >$_DATE_PUBLICATE:</td>
    	<td>
    		%DATE%
    	</td>
  	</tr>
  	<tr>
    	<td align=%ALIGN%>$_MENU:</td>
    	<td>%PORTAL_MENU_ID%</td>
  	</tr>
  	
  	
  <tr>
    <td align=%ALIGN%>$_TITLE:</td>
    <td><input name=\"TITLE\" type=\"text\" value=\"%TITLE%\" size=90 align=%ALIGN% /></td>
  </tr>
  <tr>
    <td align=%ALIGN%>$_SHORT_DESCRIPTION:</td>
    <td><textarea name=\"SHORT_DESCRIPTION\" cols=90 rows=5>%SHORT_DESCRIPTION%</textarea></td>
  </tr>  
  <tr>
    <td align=%ALIGN%>$_TEXT:</td>
    <td><textarea name=\"CONTENT\" cols=90 rows=21>%CONTENT%</textarea></td>
  </tr>
  <tr>
    <td align=%ALIGN% >$_SHOW:</td>
    <td>
    	<input type=\"radio\" name=\"STATUS\" value=1 %SHOWED%>$_SHOW
    	<br />
    	<input type=\"radio\" name=\"STATUS\" value=0 %HIDDEN%>$_HIDE 
    </td>
  </tr>
  <tr>
    <td align=%ALIGN%>&nbsp;</td>
    <td>
    	<input type=\"checkbox\" name=\"ON_MAIN_PAGE\" value=\'1\' %ON_MAIN_PAGE_CHECKED% >$_ON_MAIN_PAGE
    </td>
  </tr>
</table>
<br />
<input type=submit name=%ACTION% value=%ACTION_LNG%>
</form>

<form action=$SELF_URL name=\"depot_form_types\" method=POST>
<input type=hidden name=index value=$index>
<input type=hidden name=ID value=%ID%>
<table border=\"0\">
	<tr>
	<th colspan=2 class=\"table_title\">%TITLE_NAME%</th>
	</tr>  
  <tr>
    <td>$_NAME:</td>
    <td><input name=\"NAME\" type=\"text\" value=\"%NAME%\"/></td>
  </tr>
  <tr>
    <td>URL:</td>
    <td><input name=\"URL\" type=\"text\" value=\"%URL%\"/></td>
  </tr>
  <tr>
    <td>$_MENU:</td>
    <td>
    	<input type=\"radio\" name=\"STATUS\" value=1 %SHOWED%>$_SHOW
    	<br />
    	<input type=\"radio\" name=\"STATUS\" value=0 %HIDDEN%>$_HIDE 
    </td>
  </tr>

</table>
<br />
<input type=submit name=%ACTION% value=%ACTION_LNG%>
</form>

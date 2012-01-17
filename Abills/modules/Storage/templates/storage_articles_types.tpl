<form action=$SELF_URL name=\"depot_form_types\" method=POST>
<input type=hidden name=index value=$index>
<input type=hidden name=ID value=%ID%>
<table border=\"0\">
 
  <tr>
    <td>$_TYPE:</td>
    <td><input name=\"NAME\" type=\"text\" value=\"%NAME%\"/></td>
  </tr>
    <tr>
    <td>$_COMMENTS:</td>
    <td><textarea name=\"COMMENTS\">%COMMENTS%</textarea></td>
  </tr>
</table>
<br />
<input type=submit name=%ACTION% value=%ACTION_LNG%>
</form>

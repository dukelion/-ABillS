<form action=$SELF_URL name=\"storage_form_discard\" method=POST>
<input type=hidden name=index value=$index>
<input type=hidden name=ID value=%ID%>
<table border=\"0\" >
  <tr>
    <td>$_COUNT:</td>
    <td><input name=\"COUNT\" type=\"text\" value=\"%COUNT%\" /></td>
  </tr>
  <tr>
    <td>$_COMMENTS</td>
    <td><textarea name=\"COMMENTS\">%COMMENTS%</textarea></td>
  </tr>
</table>
<input type=submit name=%ACTION% value=%ACTION_LNG%>
</form>
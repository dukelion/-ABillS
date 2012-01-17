<form action=$SELF_URL name=\"depot_form\" method=POST>
<input type=hidden name=index value=$index>
<input type=hidden name=ID value=%ID%>
<table border=\"0\" >
  <tr>
    <td>$_NAME:</td>
    <td><input name=\"NAME\" type=\"text\" value=\"%NAME%\" /></td>
  </tr>
  <tr>
    <td>$_TYPE:</td>
    <td>%ARTICLE_TYPES%</td>
  </tr>
  <tr>
    <td>$_MEASURE:</td>
    <td><input name=\"MEASURE\" type=\"text\" value=\"%MEASURE%\" /></td>
  </tr>
  <tr>
    <td>$_DATE:</td>
    <td><input name=\"ADD_DATE\" type=\"text\" value=\"%ADD_DATE%\" /></td>
  </tr>
  <tr>
    <td>$_COMMENTS</td>
    <td><textarea name=\"COMMENTS\">%COMMENTS%</textarea></td>
  </tr>
</table>
<input type=submit name=%ACTION% value=%ACTION_LNG%>
</form>
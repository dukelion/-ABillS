<br />
<form action=$SELF_URL name=\"storage_form_subreport\" method=POST>
<input type=hidden name=index value=$index>
<input type=hidden name=ID value=%ID%>
<input type=hidden name=STORAGE_INCOMING_ARTICLES_ID value=$FORM{reserve} />
<table border=\"0\" >
  <tr>
    <td>$_RESERVED:</td>
    <td>%AID%</td>
  </tr>
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
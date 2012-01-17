<form action=$SELF_URL ID=mapAddRoute name=mapAddRoute align=center>
<input type=hidden name=index value=$index>
<input type=hidden name=ID value=$FORM{chg_route}>
<table border=\"0\" >
  <tr>
    <td>$_NAME:</td>
    <td><input name=\"NAME\" type=\"text\" value=\"%NAME%\" /></td>
  </tr>
  <tr>
    <td>$_TYPE:</td>
    <td>%TYPES%</td>
  </tr>
  <tr>
    <td>$_DESCRIBE:</td>
    <td><textarea name=\"DESCR\">%DESCR%</textarea></td>
  </tr>
   <tr>
    <td>NAS1: </td>
    <td><input name=\"NAS1\" type=\"text\" value=\"%NAS1%\" /></td>
  </tr>
  <tr>
    <td>NAS2: </td>
    <td><input name=\"NAS2\" type=\"text\" value=\"%NAS2%\"  /></td>
  </tr>
    <tr>
    <td>NAS1 port: </td>
    <td><input name=\"NAS1_PORT\" type=\"text\" value=\"%NAS1_PORT%\" /></td>
  </tr>
    <tr>
    <td>NAS2 port: </td>
    <td><input name=\"NAS2_PORT\" type=\"text\" value=\"%NAS2_PORT%\" /></td>
  </tr>  
    <tr>
    <td>$_LENGTH: </td>
    <td><input name=\"LENGTH\" type=\"text\" value=\"%LENGTH%\" /></td>
  </tr>
</table>
<br />
<input type=submit name=%ACTION% value=%ACTION_LNG%>
</form>
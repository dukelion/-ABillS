<br />
<form action=$SELF_URL name=\"storage_filter_installation\" method=POST>
<input type=hidden name=index value=$index>
<input type=hidden name=ID value=%ID%>
<table border=\"0\" >
  <tr>
    <td>$_ADMIN: </td>
    <td>%AID%</td>
  </tr>
  <tr>
    <td align=right>$_DISTRICT: </td>
    <td>%DISTRICTS%</td>
  </tr>
  <tr>
    <td align=right>$_STREET: </td>
    <td>%STREETS%</td>
  </tr>
</table>
<input type=submit name=show_installation value=$_SHOW>
</form>
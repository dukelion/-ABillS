<br />
<form action=$SELF_URL name=\"storage_filter_installation\" method=POST>
<input type=hidden name=index value=$index>
<input type=hidden name=ID value=%ID%>
<table class=form >
  <tr>
    <td>$_ADMIN:</td>
    <td>%AID%</td>
  </tr>
  <tr>
    <td>$_DISTRICT:</td>
    <td>%DISTRICTS%</td>
  </tr>
  <tr>
    <td>$_STREET</td>
    <td>%STREETS%</td>
  </tr>

  <tr>
    <th colspan=2 class=even><input type=submit name=show_installation value=$_SHOW></th>
  </tr>

</table>

</form>
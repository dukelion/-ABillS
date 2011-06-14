
<form action=$SELF_URL name=\"notepad_form\" method=POST>
<input type=hidden name=index value=$index>
<input type=hidden name=inventory_main value=1>
<input type=hidden name=ID value=$FORM{chg}>

<table border=\"0\"   >

  <tr>
    <td align=%ALIGN%>$_DATE/$_TIME:</td>
    <td>
    	<input type=text name=NOTIFIED value=\"%NOTIFIED%\" size=25 />
    </td>
  </tr>
  <tr>
    <td align=%ALIGN%>$_STATUS:</td>
    <td>
		%STATUS%
    	
    </td>
  </tr>
  <tr>
    <td align=%ALIGN%>$_SUBJECT:</td>
    <td>
    	<input type=text name=SUBJECT value=\"%SUBJECT%\" size=25 />
    </td>
  </tr>
  <tr>
    <td align=%ALIGN%>$_TEXT:</td>
    <td>
    	<textarea name=TEXT cols=50 rows=11 >%TEXT%</textarea>
    </td>
  </tr>

<tr>
<td colspan=2 align=center><input type=submit name=%ACTION% value=%ACTION_LNG%></td>
</tr>   
</table>
<br />

</form>
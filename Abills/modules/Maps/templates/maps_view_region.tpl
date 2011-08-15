<form action=\"$SELF_URL\" name=\"region_view\">
<input type=hidden name=index value=$index>

<table border=0>
%DISTRICTS_TABLE%
<td></td>
<tr>
	
 <td><input type=CHECKBOX name=SHOW_USERS %SHOW_USERS% value=1 /> $_USER </td>
 <td><input type=CHECKBOX name=SHOW_NAS %SHOW_NAS%   value=1 /> $_NAS</td>
</tr>
</table>
<br /> 
<input type=submit name=SHOW value=$_SHOW />
</form>
<br />
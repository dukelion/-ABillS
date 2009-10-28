<form action='$SELF_URL' METHOD='POST'>
<input type='hidden' name='index' value='$index'>
<input type='hidden' name='tpl_name' value='%TPL_NAME%'>
<input type='hidden' name='NAS_GID' value='$FORM{NAS_GID}'>
<table>
<tr bgcolor='$_COLORS[0]'><th>$_TEMPLATES</th></tr>
<tr bgcolor='$_COLORS[0]'><td>%TPL_NAME%</td></tr>
<tr><td>
   <textarea cols='100' rows='30' name='template'>%TEMPLATE%</textarea>
</td></tr>
<tr><td>%TPL_DIR%</td></tr>
</table>
<input type='submit' name='change' value='%ACTION_LNG%'>
</form>

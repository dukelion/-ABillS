<script language=\"JavaScript\">
	function autoReload()	{ 	
        document.storage_logs.submit();
	}	
</script>
<form action=$SELF_URL?index=$index\&add_order=1  name=\"storage_logs\" method=POST >
<input type=hidden name=index value=$index>
<input type=hidden name=ID value=%ID%>
<input type=hidden name=INCOMING_ID value=%INCOMING_ID%>
<input type=hidden name=\"type\" value=\"prihod2\">
<input type=hidden name=\"add_order\" value=\"1\">
%CHG%
<table border=\"0\" >
  <tr>
    <td>$_TYPE:</td>
    <td>%ARTICLE_TYPES%</td>
  </tr>
  <tr>
    <td>$_NAME:</td>
    <td>%ARTICLE_ID%</td>
  </tr>
   <tr>
    <td>Кол-во товара:</td>
    <td><input name=\"COUNT\" type=\"text\" value=\"%COUNT%\" %DISABLED% /></td>
  </tr>
    <tr>
    <td>$_COMMENTS</td>
    <td><textarea name=\"COMMENTS\">%COMMENTS%</textarea></td>
  </tr>
</table>
<br />
<input type=submit name=%ACTION% value=%ACTION_LNG%>
</form>
<script language=\"JavaScript\">
	function autoReload()	{ 	
    	document.depot_form.type.value='prihod';
        document.depot_form.submit();
		}	
</script>
<form action=$SELF_URL?index=$index\&add_article=1  name=\"depot_form\" method=POST >
<input type=hidden name=index value=$index>
<input type=hidden name=ID value=%ID%>
<input type=hidden name=INCOMING_ID value=%INCOMING_ID%>
<input type=hidden name=\"type\" value=\"prihod2\">
<input type=hidden name=\"add_article\" value=\"1\">
<table border=\"0\" >
  <tr>
    <td>$_TYPE:</td>
    <td>
 %ARTICLE_TYPES%
    </td>
  </tr>
  <tr>
    <td>$_NAME:</td>
    <td>%ARTICLE_ID%
    </td>
  </tr>
  <tr>
    <td>$_SUPPLIERS:</td>
    <td>%SUPPLIER_ID%
    </td>
  </tr>
  <tr>
    <td>$_DATE:</td>
    <td><input name=\"DATE\" type=\"text\" value=\"%DATE%\" /></td>
  </tr>
   <tr>
    <td>$_QUANTITY_OF_GOODS: </td>
    <td><input name=\"COUNT\" type=\"text\" value=\"%COUNT%\" %DISABLED% /></td>
  </tr>
  <tr>
    <td>$_SUM: </td>
    <td><input name=\"SUM\" type=\"text\" value=\"%SUM%\"  %DISABLED% /></td>
  </tr>
  <tr>
    <td>$_DEPOT_NUM: </td>
    <td>%STORAGE_STORAGES%
</td>
  </tr>
    <tr>
    <td>SN: </td>
    <td><input name=\"SN\" type=\"%INPUT_TYPE%\" value=\"%SN%\" /></td>
  </tr>
    <tr>
    <td>$_COMMENTS</td>
    <td><textarea name=\"COMMENTS\">%COMMENTS%</textarea></td>
  </tr>
</table>
<br />
<input type=submit name=%ACTION% value=%ACTION_LNG%>
</form>
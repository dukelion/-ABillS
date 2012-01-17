<script language=\"JavaScript\">
	function autoReload()	{ 	
    	document.depot_form.type.value='prihod';
        document.depot_form.submit();
		}	
</script>
<form action=$SELF_URL?index=$index\&storage_status=1  name=\"depot_form\" method=POST >
<input type=hidden name=index value=$index>
<input type=hidden name=ID value=$FORM{chg}>
<input type=hidden name=INCOMING_ID value=%INCOMING_ID%>
<input type=hidden name=\"type\" value=\"prihod2\">
<input type=hidden name=\"storage_status\" value=\"1\">
<table border=\"0\" >
  <tr>
    <td align=right>$_TYPE:</td>
    <td>%ARTICLE_TYPES%</td>
  </tr>
  <tr>
    <td align=right>$_NAME:</td>
    <td>%ARTICLE_ID%
    </td>
  </tr>
  <tr>
    <td align=right>$_SUPPLIERS:</td>
    <td>%SUPPLIER_ID%
    </td>
  </tr>
  <tr>
    <td align=right>$_STORAGE:</td>
    <td>%STORAGE_STORAGES%
    </td>
  </tr>
</table>
<input type=submit name=storage_status value=$_SHOW>
</form>
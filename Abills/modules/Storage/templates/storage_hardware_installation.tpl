<script language=\"JavaScript\">
	function autoReload()	{ 	
    	document.storage_hardware_form.type.value='prihod';
        document.storage_hardware_form.submit();
		}	
</script>

<form action=$SELF_URL  name=\"storage_hardware_form\" method=POST>
<input type=hidden name=index value=$index>
<input type=hidden name=ID value=%ID%>
<input type=hidden name=\"type\" value=\"prihod2\">
<input type=hidden name=ajax_index value=$index>
<input type=hidden name=UID value=$FORM{UID}>
<input type=hidden name=OLD_MAC value=%OLD_MAC%>
<input type=hidden name=COUNT1 value=%COUNT1%>
<input type=hidden name=ARTICLE_ID1 value=%ARTICLE_ID1%>
<table class=form >
  <tr>
    <td>$_TYPE:</td>
    <td>%ARTICLE_TYPES%</td>
  </tr>
  <tr>
    <td>$_NAME:</td>
    <td>%ARTICLE_ID%</td>
  </tr>
  <tr>
    <td>$_COUNT:</td>
    <td><input name=\"COUNT\" type=\"text\" value=\"%COUNT%\" %DISABLE%/></td>
  </tr>
  <tr>
    <td>$_STATUS:</td>
    <td>%STATUS%</td>
  </tr>  
  <tr>
    <th colspan=\"2\" class=\"table_title\">&nbsp;</th>
  </tr>
  <tr>
  	<td>$_HOSTS_HOSTNAME:</td>
  	<td><input type=text name=HOSTNAME value='%HOSTNAME%'></td>
  </tr>			
  <tr>
  	<td>$_HOSTS_NETWORKS:</td>
  	<td>%NETWORKS_SEL% %NETWORK_BUTTON%</td>
  </tr>
  <tr>
  	<td>IP:</td>
  	<td><input type=text name=IP value='%IP%' size=15> $_AUTO: <input type=checkbox name=AUTO_IP value=1></td>
  </tr>			
  <tr>
  	<td>$_HOSTS_MAC:<BR>(00:00:00:00:00:00)</td>
  	<td><input type=text name=MAC value='%MAC%'></td>
  </tr> 
  <tr>
    <th colspan=\"2\" class=\"table_title\">&nbsp;</th>
  </tr>
  <tr>
    <td>$_SERIAL</td>
    <td><textarea name=\"SERIAL\">%SERIAL%</textarea></td>
  </tr>
  <tr>
    <td>Grounds:</td>
    <td><input name=\"GROUNDS\" type=\"text\" value=\"%GROUNDS%\" /></td>
  </tr>
  <tr>
    <td>$_COMMENTS:</td>
    <td><input name=\"COMMENTS\" type=\"text\" value=\"%COMMENTS%\" /></td>
  </tr>

  <tr>
    <th colspan=2 class=even><input type=submit name=%ACTION% value=%ACTION_LNG%></td>
  </tr>

</table>

</form>
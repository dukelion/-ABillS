<div class='noprint'>
<FORM action='$SELF_URL' METHOD='POST'>
<input type='hidden' name='index' value='$index'>
<input type='hidden' name='IP_NUM' value='%IP_NUM%'>
<table width='400' class=form>
<tr><td>IP:  </td><td><input type='text' name='IP' value='%IP%'></td></tr>
<tr><td>NETMASK:</td><td><input type='text' name='NETMASK' value='%NETMASK%'></td></tr>
<tr><td>HOSTNAME:</td><td><input type='text' name='HOSTNAME' value='%HOSTNAME%'></td></tr>
<tr><td>$_DESCRIBE:</td><td><input type='text' name='DESCR' value='%DESCR%'></td></tr>
<tr><td>$_GROUP: </td><td>%GROUP_SEL%</td></tr>
<tr><td>$_STATE:   </td><td>%STATE_SEL%</td></tr>
<tr><td>$_PHONE:   </td><td><input type='text' name='PHONE' value='%PHONE%'></td></tr>
<tr><td>E-Mail:</td><td><input type='text' name='EMAIL' value='%EMAIL%'></td></tr>
<tr><th colspan='2' class=title_color>$_COMMENTS: </th></tr>
<tr><th colspan='2'><textarea name='COMMENTS' rows='6' cols='60'>%COMMENTS%</textarea></th></tr>
<tr><th colspan='2' class=even><input type='submit' name='%ACTION%' value='%ACTION_LNG%'></th></tr>
</table>

</FORM>
</div>

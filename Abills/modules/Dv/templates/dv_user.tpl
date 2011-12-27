
<script language=\"JavaScript\" type=\"text/javascript\">
<!--
function check_status(object, text) {
    var status       = '%STATUS%';
    var status_days  = '%STATUS_DAYS%';
    var reactive_sum = '%REACTIVE_SUM%';
    var new_status = document.getElementById('STATUS').value;
    
    if (status == 3 && new_status == 0 && status_days > 0) {
      return confirmLink(object, '$_SUM $_ACTIVATE: ' + reactive_sum, '  ');
     }

    return ;
}
-->
</script>


%ONLINE_TABLE%
<br>
<form action='$SELF_URL' method='post'>
<input type=hidden name='index' value='$index'>
<input type=hidden name='UID' value='$FORM{UID}'>
<input type=hidden name='STATUS_DAYS' value='%STATUS_DAYS%'>
<input type=hidden name='step' value='$FORM{step}'>
<table cellspacing='0' cellpadding='3' width=450 class='form'>
<tr class='even'><td>$_TARIF_PLAN:</td><th  align='left' valign='middle'>[%TP_ID%] %TP_NAME% 
%CHANGE_TP_BUTTON% <a href='$SELF?index=$index&UID=$FORM{UID}&pay_to=1' class='payments rightAlignText' title='$_PAY_TO'>$_PAY_TO</a></th></tr>
%JOIN_SERVICE%
<tr><td>IP:</td><td><input type=text name=IP value='%IP%'> <br>Static IP Pool:<br>%STATIC_IP_POOL%</td></tr>
<tr><td>Netmask:</td><td bgcolor='%NETMASK_COLOR%'><input type=text name=NETMASK value='%NETMASK%'></td></tr>
<tr><td>CID:</td><td><input type=text name='CID' value='%CID%'>
<tr><td>$_SPEED (kb):</td><td><input type=text name=SPEED value='%SPEED%' size=10>
 &nbsp; $_SIMULTANEOUSLY:<input type=text name=SIMULTANEONSLY value='%SIMULTANEONSLY%' size=10> </td></tr>
<tr><td>$_FILTERS:</td><td><input type=text name=FILTER_ID value='%FILTER_ID%' size=45></td></tr>
<tr><td>$_PORT:</td><td><input type=text name='PORT' value='%PORT%'>
<tr><td>Callback:</td><td><input type='checkbox' name='CALLBACK' value='1' %CALLBACK%>
<tr><td>$_STATUS:</td><td bgcolor=%STATUS_COLOR%>%STATUS_SEL% <span style='background:$_COLORS[1]'>&nbsp; %SHEDULE% &nbsp;<br><i>%STATUS_INFO%</i></span>
</td></tr>
<tr><td>TURBO:</td><td>%TURBO_MODE_SEL%</td></tr>
<tr><td>$_ABON:</td><td>%ABON_DATE%</td></tr>
<tr><td colspan='2'>%REGISTRATION_INFO%  %REGISTRATION_INFO_PDF%</td></tr>
<tr><th colspan='2' class=even>%BACK_BUTTON%
<input type=submit name='%ACTION%' value='%LNG_ACTION%' class='noprint' onclick=\"return check_status(this, '$_DELETE ?')\">
</th></tr>
</table>
</form>

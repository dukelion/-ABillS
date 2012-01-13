<script type=\"text/JavaScript\">

<!--
function Process(version, INTERNAL_SUBNET, wds, SSID){
	var commandbegin='%PARAM1%';
	var commandend = '%PARAM2%';

	if (version == 'v24') {
		var commandversion = '\\\\&version=v24';
  	} else if (version == 'coova') { 
		var commandversion = '\\\\&version=coova'; 
	} else if (version == 'freebsd') {
              var commandversion = '\\\\&version=freebsd';
              commandbegin = commandbegin.replace('wget -O', '/usr/bin/fetch -o')
        } else { 
		var commandversion = ''; 
	}

	
	
	if (document.FORM_NAS.LAN_IP.value != '') {
    var commandsubnet = '\\\\&LAN_IP='+document.FORM_NAS.LAN_IP.value;
	 }
	else {
	  if (INTERNAL_SUBNET != '20') {
		  var commandsubnet = '\\\\&INTERNAL_SUBNET='+INTERNAL_SUBNET;
     } 
    else { 
		  var commandsubnet = ''; 
	   }
	 }

	if (wds != '0') {
		var commandwds = '\\\\&wds='+wds;
   } 
  else { 
		var commandwds = ''; 
	 }

	if (SSID != '') {
		var commandsid = '\\\\&SSID='+SSID;
   } 
  else {
		var commandsid = ''; 
	 }

	
	document.FORM_NAS.tbox.value = commandbegin+ commandversion + commandsid + commandsubnet + commandwds + commandend;
}

function data_change(field) {
          var check = true;
          var value = field.value; //get characters
          //check that all characters are digits, ., -, or \"\"
          for(var i=0;i < field.value.length; ++i)
          {
               var new_key = value.charAt(i); //cycle through characters
               if(((new_key < \"0\") || (new_key > \"9\")) &&
                    !(new_key == \"\"))
               {
                    check = false;
                    break;
               }
          }
          //apply appropriate colour based on value
          if(!check)
          {
               field.style.backgroundColor = \"red\";
          }
          else
          {
               field.style.backgroundColor = \"white\";
          }
     }

function disableEnterKey(e)
{
	 var key;
     if(window.event)
          key = window.event.keyCode;     //IE
     else
          key = e.which;     //firefox
     if(key == 13)
          return false;
     else
          return true;
}
//-->
</script>

<input type=hidden name=wds id=wds class=\"selectinput\" value=\"0\">


<table width=100% class=form>
<tr><th class=table_title colspan=2>Hotspot $_SETTINGS</th></tr>
<tr><td>Firmware Version:</td><td>
             <select name=\"version\" class=\"selectinput\" id=\"version\"  onchange=\"Process(this.form.version.value, this.form.INTERNAL_SUBNET.value, this.form.wds.value, this.form.CUSTOM_SID.value)\" onKeyPress=\"return disableEnterKey(event)\">
                                 <option value=\"v24\">DD-WRT v24 NoKaid/Standard/Mega/Special</option>
                                 <option value=\"v23\">DD-WRT v23 Standard</option>
                                 <option value=\"coova\">CoovaAP</option>
                                 <option value=\"freebsd\">FreeBSD</option>
                               </select>
 </td>
                           </tr>

<tr><td>Set router's internal IP to:</td><td>
                             192.168. <input name=\"INTERNAL_SUBNET\" class=\"forminput\" type=\"text\"  id=\"INTERNAL_SUBNET\" value=\"20\" size=\"3\" maxlength=\"3\"  
                            onchange=\"Process(this.form.version.value, this.form.INTERNAL_SUBNET.value, this.form.wds.value, this.form.CUSTOM_SID.value)\" onkeyup=\"data_change(this)\"
                            onsubmit=\"Process(this.form.version.value, this.form.INTERNAL_SUBNET.value, this.form.wds.value, this.form.CUSTOM_SID.value)\"  
                            onKeyPress=\"Process(this.form.version.value, this.form.INTERNAL_SUBNET.value, this.form.wds.value, this.form.CUSTOM_SID.value); return disableEnterKey(event)\" />
                               .1

<!--
<br>
Custom Network: <input name=\"LAN_IP\" class=\"forminput\" type=\"text\"  id=\"LAN_IP\" value=\"\" size=\"16\" maxlength=\"16\"  
                            onchange=\"Process(this.form.version.value, this.form.INTERNAL_SUBNET.value, this.form.wds.value, this.form.CUSTOM_SID.value)\" 
                            onsubmit=\"Process(this.form.version.value, this.form.INTERNAL_SUBNET.value, this.form.wds.value, this.form.CUSTOM_SID.value)\"  
                            onKeyPress=\"Process(this.form.version.value, this.form.INTERNAL_SUBNET.value, this.form.wds.value, this.form.CUSTOM_SID.value); return disableEnterKey(event)\" />
-->                               
                               
                               </td>
</tr>
<tr><td>SSID:</td><td> <input name=\"CUSTOM_SID\" class=\"forminput\" type=\"text\"  id=\"CUSTOM_SID\" value=\"wifi\" size=\"18\" maxlength=\"14\"  
                            onchange=\"Process(this.form.version.value, this.form.INTERNAL_SUBNET.value, this.form.wds.value, this.form.CUSTOM_SID.value)\" onkeyup=\"\"
                            onsubmit=\"Process(this.form.version.value, this.form.INTERNAL_SUBNET.value, this.form.wds.value, this.form.CUSTOM_SID.value)\"  
                            onKeyPress=\"Process(this.form.version.value, this.form.INTERNAL_SUBNET.value, this.form.wds.value, this.form.CUSTOM_SID.value); return disableEnterKey(event)\" /></td>
</tr>

<tr><td align=center colspan=2><textarea name=tbox rows=4 id=tbox cols=50>%CONFIGURE_DATE%</textarea></td></tr>
</table>

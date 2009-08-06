<script type=\"text/JavaScript\">

<!--
function Process(version, INTERNAL_SUBNET, wds){
	
	var commandbegin='%PARAM1%';
	var commandend = '%PARAM2%';
	
	if (version == 'v24') {
		var commandversion = '\\&version=v24';
  	} else if (version == 'coova') { 
		var commandversion = '\\&version=coova'; 
	} else { 
		var commandversion = ''; 
	}
	
	if (INTERNAL_SUBNET != '20') {
		var commandsubnet = '\\&INTERNAL_SUBNET='+INTERNAL_SUBNET;
  	} else { 
		var commandsubnet = ''; 
	}
	
	if (wds != '0') {
		var commandwds = '\\&wds='+wds;
  	} else { 
		var commandwds = ''; 
	}
	
	document.FORM_NAS.tbox.value = commandbegin+ commandversion + commandsubnet + commandwds + commandend;

}

function data_change(field)
     {
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


<table width=100%>
<tr><th class=table_title colspan=2>$_SETTINGS</th></tr>
<tr><td>Firmware Version:</td><td>
             <select name=\"version\" class=\"selectinput\" id=\"version\"  onchange=\"Process(this.form.version.value, this.form.INTERNAL_SUBNET.value, this.form.wds.value)\" onKeyPress=\"return disableEnterKey(event)\">
                                 <option value=\"v24\">DD-WRT v24 NoKaid/Standard/Mega/Special</option>
                                 <option value=\"v23\">DD-WRT v23 Standard</option>
                                 <option value=\"coova\">CoovaAP</option>
                               </select>
 </td>
                           </tr>

<tr><td>Set router's internal IP to:
                                   </td><td>
                             192.168. <input name=\"INTERNAL_SUBNET\" class=\"forminput\" type=\"text\"  id=\"INTERNAL_SUBNET\" value=\"20\" size=\"3\" maxlength=\"3\"  
                             onchange=\"Process(this.form.version.value, this.form.INTERNAL_SUBNET.value, this.form.wds.value)\" onkeyup=\"data_change(this)\"
                            
                            onsubmit=\"Process(this.form.version.value, this.form.INTERNAL_SUBNET.value, this.form.wds.value)\"  
                            
                            onKeyPress=\"Process(this.form.version.value, this.form.INTERNAL_SUBNET.value, this.form.wds.value); return disableEnterKey(event)\" />
                               .1</td>
</tr>
<tr><td align=center colspan=2><textarea name=tbox rows=4 id=tbox cols=50>%CONFIGURE_DATE%</textarea></td></tr>
</table>
<SCRIPT TYPE=\"text/javascript\">
<!-- 

function add_comments () {


if (document.add_message.DISPATCH_CREATE.checked) {
  document.add_message.DISPATCH_CREATE.checked=false;
  Q=prompt('$_COMMENTS','');

	var new_dispatch  = document.getElementById('new_dispatch');
  var dispatch_list = document.getElementById('dispatch_list'); 
 
  if (Q == '' || Q == null) {
  	alert('Enter comments');
  	document.add_message.DISPATCH_CREATE.checked=false;
  	new_dispatch.style.display = 'none';
  	dispatch_list.style.display='block';
   }
  else {
  	document.add_message.DISPATCH_CREATE.checked=true;
    document.add_message.DISPATCH_COMMENTS.value=Q;
    new_dispatch.style.display = 'block';
    dispatch_list.style.display='none';
   }
 }
else {
	document.add_message.DISPATCH_CREATE.checked=false;
	document.add_message.DISPATCH_COMMENTS.value='';
	new_dispatch.style.display = 'none';
	dispatch_list.style.display='block';
 } 
}


-->
</SCRIPT>

<FORM action='$SELF_URL' METHOD='POST'  enctype='multipart/form-data' name=add_message>
<input type='hidden' name='index' value='$index'/>
<input type='hidden' name='UID' value='$FORM{UID}'/>
<input type='hidden' name='ID' value='%ID%'/>
<input type='hidden' name='PARENT' value='%PARENT%'/>

<table>
<tr><td>$_DATE:</td><td>%DATE%</td></tr>
<tr><td>$_CHAPTERS:</td><td>%CHAPTER_SEL%</td></tr>
<tr><td>$_SUBJECT:</td><td><input type='text' name='SUBJECT' value='%SUBJECT%' size='50'/></td></tr>

<tr><td>$_INNER</td><td><input type=checkbox name=INNER_MSG value=1 %INNER_MSG%></td></tr>

<tr><td>$_LOGIN / $_GROUP:</td><td>%USER%</td></tr>
<tr><th bgcolor='$_COLORS[0]' colspan='2'>$_MESSAGE</th></tr>
<tr><th colspan='2'><textarea name='MESSAGE' cols='70' rows='9'>%MESSAGE%</textarea></th></tr>
<tr><td>$_PHONE:</td><td><input type='text' name='PHONE' value='%PHONE%' size='30'/></td></tr>
%ATTACHMENT%
<tr><td>$_ATTACHMENT:</td><td><input name='FILE_UPLOAD' type='file' size='40' class='fixed'>
                  <!-- <input class='button' type='submit' name='AttachmentUpload' value='$_ADD'> --> </td></tr>  
<tr><td>$_STATE:</td><td>%STATE_SEL%</td></tr>  
<tr><td>$_PRIORITY:</td><td>%PRIORITY_SEL%</td></tr>
<TR><TD>$_RESPOSIBLE:</TD><TD>%RESPOSIBLE%</TD></TR>
<TR><TD>$_EXECUTION $_DATE:</TD><TD>%PLAN_DATE% $_TIME: <input type=text value='%PLAN_TIME%' name='PLAN_TIME'></TD></TR>

<TR bgcolor=$_COLORS[2]><TD>$_DISPATCH:</TD><TD><div id=dispatch_list style='display: block'>%DISPATCH_SEL%</div> <input type=checkbox name=DISPATCH_CREATE value=1 onClick=\"add_comments();\"> $_CREATE $_DISPATCH

<br>

<div id=new_dispatch style='display: none'>
<input type=text name=DISPATCH_COMMENTS value='%DISPATCH_COMMENTS%'  size=30> $_DATE: %DISPATCH_PLAN_DATE%
</div>

</TD></TR>
<tr><td>$_LOCK:</td><td><input type=checkbox name=LOCK value=1 %LOCK%></td></tr>
%SEND_EMAIL%
</table>
<input type='submit' name='%ACTION%' value='%ACTION_LNG%'/>
</FORM>

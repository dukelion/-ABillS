<SCRIPT type='text/javascript'>
<!--
function samechanged(what) {
  if ( what.value == 2 ) {
    what.form.RUN_TIME.disabled = false;
    what.form.RUN_TIME.style.backgroundColor = '$_COLORS[2]';
  } else {
    what.form.RUN_TIME.disabled = true;
    what.form.RUN_TIME.style.backgroundColor = '$_COLORS[3]';
  }
}
samechanged('STATE');

-->
</SCRIPT>
<input type='hidden' name='MAIN_INNER_MESSAGE' value='%MAIN_INNER_MSG%'/>
<div class='noprint'>
<table width=100% class=form>
<tr><th class=form_title colspan='2'>$_REPLY</th></tr>
<input type='hidden' name='SUBJECT' value='%SUBJECT%' size=50/>
<tr><td>$_SUBJECT:</td><td><input type='text' name='REPLY_SUBJECT' value='%REPLY_SUBJECT%' size=50/></td></tr>
<tr><th colspan='2'><textarea name='REPLY_TEXT' cols='90' rows='11' onkeydown='keyDown(event)' onkeyup='keyUp(event)'>%QUOTING% %REPLY_TEXT%</textarea></th></tr>

%ATTACHMENT%
<tr><td>$_ATTACHMENT:</td><td><input name='FILE_UPLOAD' type='file' size='40' class='fixed'>
<!--   <input class='button' type='submit' name='AttachmentUpload' value='$_ADD'>--></td></tr>  
<tr><td>$_STATUS:</td><td>%STATE_SEL% %RUN_TIME%</td></tr>
<tr><td>$_CHANGE $_CHAPTERS:</td><td>%CHAPTERS_SEL%</td></tr>
<tr><td>$_INNER:</td><td><input type=checkbox name=REPLY_INNER_MSG value=1 %INNER_MSG%></td></tr>
<tr><td>$_SURVEY:</td><td>%SURVEY_SEL%</td></tr>
</table>
<input type='hidden' name='sid' value='$sid'/>
<input type='submit' name='%ACTION%' value='  %LNG_ACTION%  ' id='go' title='Ctrl+C'/>
<br>
<br>
</div>

<SCRIPT type='text/javascript'>

function samechanged(what) {
  if ( what.value == 3 ) {
    what.form.RESPOSIBLE.disabled = false;
    what.form.RESPOSIBLE.style.backgroundColor = '$_COLORS[2]';
  } else {
    what.form.RESPOSIBLE.disabled = true;
    what.form.RESPOSIBLE.style.backgroundColor = '$_COLORS[3]';
  }
}

samechanged('RESPOSIBLE');

</SCRIPT>


<FORM action='$SELF_URL' METHOD='POST'  >
<input type='hidden' name='index' value='$index'/>
<input type='hidden' name='ID' value='%ID%'/>

<TABLE>
<tr><th colspan=2 class='title_color' align=right>$_DISPATCH:</th></tr>
<tr><td>$_EXECUTION:</td><td><input type=text name=PLAN_DATE value='%PLAN_DATE%'></td></tr>
<tr><th colspan=2 class='title_color'>$_COMMENTS:</th></tr>
<tr><th colspan=2><textarea name=COMMENTS rows=8 cols=50>%COMMENTS%</textarea></td></tr>
<tr><td>$_STATUS:</td><td>%STATE_SEL%</td></tr>
<tr><td>$_RESPOSIBLE:</td><td>%RESPOSIBLE_SEL%</td></tr>
</TABLE>

<input type=submit name='%ACTION%' value='%ACTION_LNG%'>

</form>

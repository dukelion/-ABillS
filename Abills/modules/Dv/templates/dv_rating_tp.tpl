<div class='noprint' name='FORM_TP'>
<form action='$SELF_URL' METHOD='POST'>
<input type=hidden name='index' value='$index'>
<input type=hidden name='TP_ID' value='$FORM{TP_ID}'>
<table border='0' width=600>
  <tr><th colspan='2' class=form_title>$_RATING</th></tr>
  <tr><td>$_RATING:</td><td>$_FROM: <input type=input size=5 name=RATING_FROM value=%RATING_FROM%> $_TO: <input type=input size=5 name=RATING_TO value=%RATING_TO%></td></tr>
  <tr><td>$_ACTION:</td><td>%RATING_ACTION_SEL%</td></tr>
  <tr><th colspan=2>$_COMMENTS</th></tr>
  <tr><th colspan=2><textarea cols=50 rows=5 name=COMMENTS>%COMMENTS%</textarea></th></tr>
</table>
<input type=submit name='%ACTION%' value='%LNG_ACTION%'>
</form>
</div>


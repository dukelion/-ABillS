<form action=$SELF_URL>
<input type=hidden name=index value=$index>
<input type=hidden name=UID value=%UID%>
<input type=hidden name=sid value=$FORM{sid}>

<table width=400 class=form>
<tr><th colspan=2 class=form_title>$_RATING</th></tr>
<tr><td>$_RATING:</td><td>%RATING_PER%</td></tr>
<tr><td>$_UP_RATING:</td><td><input type=text name='UP_RATING' value='%UP_RATING%' size=7> ( 1\% = %ONE_PERCENT_SUM%)</td></tr>
<tr><th colspan=2 class=even><input type=submit name=UP_RATING_PRE value='$_UP_RATING'></th></tr>
</table>


</form>
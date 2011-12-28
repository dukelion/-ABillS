<form action=$SELF_URL method=post>
<input type=hidden name=index value=$index>
<input type=hidden name=UID value=%UID%>
<input type=hidden name=sid value=$FORM{sid}>
<input type=hidden name='UP_RATING' value='%UP_RATING%'>

<table width=400 class=form>
<tr><th colspan=2 class=form_title>$_RATING</th></tr>
<tr><td colspan=2>

$_OPERATION_FEES: %NEED_SUM%<br>
$_CONTINUE ?


 </td></tr>
<tr><th colspan=2 class=even><input type=submit name=UP value='$_UP_RATING'></th></tr>
</table>


</form>
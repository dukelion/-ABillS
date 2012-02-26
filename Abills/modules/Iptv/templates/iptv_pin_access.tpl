<form action=$SELF_URL METHOD=POST>
<input type=hidden name=qindex value=$index>
<input type=hidden name=sid value=$sid>
<input type=hidden name=VOD value=$FORM{VOD}>
<table width=400 class=form>
<tr><td>Enter PIN For media access</td></tr>
<tr><td><input type=password name=PIN> <input type=submit name=ACCESS value=$_ENTER></td></tr>
</table>
</form>

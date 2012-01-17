<script type=\"text/javascript\">
	function showLoading() {
		var shadow = document.getElementById('shadow');
		var loading = document.getElementById('load');
		shadow.style.display = 'block';
		loading.style.display = 'block';	
	}	   
</script>

<form action='$SELF_URL' METHOD='POST' name='form_card_add'>
<input type='hidden' name='sid' value='$FORM{sid}'>
<input type='hidden' name='index' value='$index'>
<input type='hidden' name='UID' value='$FORM{UID}'>
<table class=form>
<tr><th class='form_title' colspan='2'>$_ICARDS</th></tr>
<tr><td>$_SERIAL:</td><td><input type='text' name='SERIAL' value='%SERIAL%'></td></tr>
<tr><td>PIN:</td><td><input type='text' name='PIN'></td></tr>
<tr><th class='even' colspan='2'><input type='submit' name='add' value='$_ADD' ID='submitButton' onClick='showLoading()'></th></tr>
</table>


</form>

<div style='display: none;' id='shadow'></div>
<div style='display: none;' id='load' class='top_result_baloon'><span id='loading'>$_BALANCE_RECHARCHE ...</span></div>
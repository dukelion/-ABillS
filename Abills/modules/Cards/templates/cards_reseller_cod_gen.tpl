<script language=\"JavaScript\" type=\"text/javascript\">
<!--


function samechanged(what) {
  if ( what.value == 1 ) {
    what.form.TP_ID.disabled = false;
    what.form.TP_ID.style.backgroundColor = '#eeeeee';
  } else {
    what.form.TP_ID.disabled = true;
    what.form.TP_ID.style.backgroundColor = '#dddddd';
  }
}

samechanged('STATE');





function make_unique() {
    var pwchars = \"abcdefhjmnpqrstuvwxyz23456789ABCDEFGHJKLMNPQRSTUVWYXZ.,:\";
    var passwordlength = 8;    // do we want that to be dynamic?  no, keep it simple :)
    var passwd = document.getElementById('OP_SID');

    passwd.value = '';

    for ( i = 0; i < passwordlength; i++ ) {
        passwd.value += pwchars.charAt( Math.floor( Math.random() * pwchars.length ) )
    }
    return passwd.value;

}
-->
</script>

<form action='$SELF_URL' METHOD='POST' TARGET=New>

<input type='hidden' name='qindex' value='$index'>
<input type='hidden' name='UID' value='$FORM{UID}'>
<input type='hidden' name='OP_SID' value='%OP_SID%' ID=OP_SID>
<input type='hidden' name='sid' value='$sid'>
<table width=600>
<tr bgcolor='$_COLORS[0]'><th colspan=2 align=right>$_ICARDS</th></tr>
<tr><td>$_COUNT:</td><td><input type='text' name='COUNT' value='%COUNT%'></td></tr>
<tr><td>$_SUM:</td><td><input type='text' name='SUM' value='%SUM%'></td></tr>

<tr><td class=small colspan=2 bgcolor=$_COLORS[9]></td></tr>


<tr><td>$_TYPE:</td><td>%TYPE_SEL%</td></tr>
<tr><td>$_TARIF_PLAN:</td><td>%TP_SEL%</td></tr>


</table>

<input type='submit' name='add' value='$_ADD' onclick=\"make_unique(this.form)\">
</form>


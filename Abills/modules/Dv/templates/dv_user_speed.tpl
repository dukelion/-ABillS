
<FORM action=$SELF_URL METHOD=POST>
 <input type=hidden name=index value=$index>
 <input type=hidden name=CID value=$Dv->{ISG_CID_CUR}>
 <input type=hidden name=sid value='$sid'>
<TABLE width='500' cellspacing='0' cellpadding='0' border='0'>
<TR><TD bgcolor='#E1E1E1'>

<TABLE width='100%' cellspacing='1' cellpadding='0' border='0'>
<tr bgcolor='$_COLORS[0]'><th align=right colspan=2>TURBO $_MODE</th></tr>
<tr bgcolor='$_COLORS[1]'><td>$_SPEED (kb):</td><td>%SPEED_SEL% 
 <input type=submit name=change value='$_CHANGE'></td></tr>
</table>

</td></tr>
</table>

</FORM>
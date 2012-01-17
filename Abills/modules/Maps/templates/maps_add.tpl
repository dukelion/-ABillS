<script type=\"text/javascript\" src=\"../ajax/maps/coords.js\"></script>
<table>
<form action=$SELF_URL ID=mapForm name=adress align=center>
<input type=hidden name=index value=$index>

%ADDRESS_TPL%
<table align=center border =0>

<tr>
<td>$_ANGLE 1:</td>
<td><INPUT id=hx1 size=4 name=MAP_X></td>
<td><INPUT id=hy1 size=4 name=MAP_Y></td>
</tr>
<tr>
<td>$_ANGLE 2:</td>
<td><INPUT id=hx2 size=4 name=MAP_X2></td>
<td><INPUT id=hy2 size=4 name=MAP_Y2></td>
</tr>
<tr>
<td>$_ANGLE 3:</td>
<td><INPUT id=hx3 size=4 name=MAP_X3></td>
<td><INPUT id=hy3 size=4 name=MAP_Y3></td>
</tr>
<tr>
<td>$_ANGLE 4:</td>
<td><INPUT id=hx4 size=4 name=MAP_X4></td>
<td><INPUT id=hy4 size=4 name=MAP_Y4></td>
</tr>

</table>
<br />
<input type=submit name=change value=$_CHANGE>
<INPUT type=button onClick=javascript:coordsClear(); value=$_CLEAR />
<br />
<table align=left >
<tr>
<td>X :<label for=coordX> </label><input type=text name=coordX size=4 /> Y:<label for=coordY> </label><input type=text name=coordY size=4 /></td>
</tr>
<table>
</form>
<br />
<br />



<form action=$SELF_URL>
<input type=hidden name=index value=$index>
<input type=hidden name=TABLE_INFO value=$FORM{TABLE_INFO}>
<input type=hidden name=FIELD value=$FORM{FIELD}>

<table width=300>
<tr><th class=form_title colspan=2>$FORM{TABLE_INFO}.$FORM{FIELD}</th></tr>
<tr><td>$_NAME:  	</td><td><input type=text name=NAME value='%NAME%'></td></tr>
<tr><td>$_TYPE: </td><td>%COLUMN_TYPE_SEL%</td></tr>
<tr><td>$_LENGTH: 	</td><td><input type=text name=COLUMN_LENGTH value='%COLUMN_LENGTH%'></td></tr>
<tr><td>$_DEFAULT: 	</td><td>%DEFAULT_SEL% <BR> <input type=text name=DEFAULT value='%DEFAULT%'></td></tr>
<tr><td>Сравнение: 	</td><td>%COLLATION_SEL%</td></tr>
<tr><td>Атрибуты: 	</td><td>%ATTRIBUTE_TYPE_SEL%</td></tr>
<tr><td>Null: 	 </td><td><input type=checkbox name=NULL value='%NULL%'></td></tr>
<tr><td>AUTO_INCREMENT: 	</td><td><input type=checkbox name=AUTO_INCREMENT value='1' %AUTO_INCREMENT%></td></tr>
<tr><td>$_COMMENTS: </td><td><input type=text name=COMMENTS value='%COMMENTS%'></td></tr>
</table>

<input type=submit name=change value=$_CHANGE>
</form>
<script src=\"/ajax/lib/JsHttpRequest/JsHttpRequest.js\"></script>
<style>
div.timeline
{
	height: 20px;
	display: inline-table;
	vertical-align: middle;
}
div.lists
{
	position: absolute;
	display: none;
	background-color: #ffffff;
	/*border: 1px solid #000000;*/
}
div
{
	margin: 1px 1px 1px 1px;
	font-family: Verdana, Tahoma, Arial;
	font-size: 12px;
}
input.input,div.lists
{
	width: 200px;
}
div.fix
{
	postion: fixed;
}
div.spisok
{
	padding: 1px 1px 1px 1px;
	border: 1px dotted #000000;
}
div.spisok:hover
{
	border: 1px solid #000000;
}
</style>


<script language=\"JavaScript\" type=\"text/javascript\">

window.onload = function () {
    district('0');
}

function openwindow(params) {
  window.open(params, \"calendar\", \"width=400,height=500,status=yes\");
 }

function time_line(state) {
	if (state == 1) {
		document.getElementById(\"time\").innerHTML = \"<img src='/img/progbar.gif'>\";
	}
	if (state == 4)	{	
		document.getElementById(\"time\").innerHTML = \"\";
	}
}

function insert (id) {
	var arr = id.value.split(\"|\");
	var teg = arr[\"0\"];
	var value = arr[\"1\"];
	var hide_teg = arr[\"2\"];
	var key = arr[\"3\"];

	document.getElementById(teg).value = value;
	document.getElementById(hide_teg).style.display = \"\";

	if (teg == 'p1') {
		document.getElementById('p2').value = \"\";
		document.getElementById('p3').value = \"\";
		document.getElementById('DISTRICT_ID').value = key;
		street('0');
	}
	if (teg == 'p2') {
		document.getElementById('STREET_ID').value = key;
		document.getElementById('LOCATION_ID').value = key;
		build('0');
	}
	if (teg == 'p3') {
		document.getElementById('LOCATION_ID').value = key;
		build('0');
	}
}

function hide_unhide (teg) {
	if (document.getElementById(teg).innerHTML != \"\") {
		if (document.getElementById(teg).style.display == \"\") {
			document.getElementById(teg).style.display = \"block\";
		 }
		else {
			document.getElementById(teg).style.display = \"\";
		}
	}
}

function district(go) {
  if (go == 1) {
	  document.getElementById(\"p1\").value = document.getElementById(\"p2\").value = document.getElementById(\"p3\").value = \"\";
	 }

	go = go || '1';

	if (document.getElementById(\"p1\").value.length > 0 || go == 0) {
		JsHttpRequest.query	(
			\"$SELF_URL\",
			{
				\"go\": go,
				\"qindex\": 30,
				\"address\": 1,
			},
			function(result, errors) {
				document.getElementById(\"debug\").innerHTML = errors;
				if (result[\"list\"] != \"\")
				{
					document.getElementById(\"l1\").innerHTML = result[\"list\"];
					if (go == 1)
					{
						document.getElementById(\"l1\").style.display = \"block\";
					}
				}
			},
			true,
			function (state) 
			{
				time_line(state);
			}
		);
	}
	else {
		document.getElementById(\"l1\").innerHTML = \"\";
		document.getElementById(\"l1\").style.display = \"\";
	}
}

function street(go) {
	go = go || '1';
	if (document.getElementById(\"p2\").value.length > 0 || go == 0)
	{
		JsHttpRequest.query
		(
			\"$SELF_URL\",
			{
				\"go\": go,
				\"qindex\": 30,
				\"address\": 1,
				\"DISTRICT_ID\": document.getElementById(\"DISTRICT_ID\").value,
			},
			function(result, errors) 
			{
				document.getElementById(\"debug\").innerHTML = errors;
				if (result[\"list\"] != \"\")
				{
					document.getElementById(\"l2\").innerHTML = result[\"list\"];
					if (go == 1)
					{
						document.getElementById(\"l2\").style.display = \"block\";
					}
				}
			},
			true,
			function (state) 
			{
				time_line(state);
			}
		);
	}
	else
	{
		document.getElementById(\"l2\").innerHTML = \"\";
		document.getElementById(\"l2\").style.display = \"\";
	}
}

function build (go) {
	go = go || '1';
	if (document.getElementById(\"p3\").value.length > 0 || go == 0)
	{
		JsHttpRequest.query
		(
      \"$SELF_URL\",
			{
				\"go\": go,
				\"qindex\": 30,
				\"address\": 1,
				\"STREET\": document.getElementById(\"STREET_ID\").value,
			},			
	  function(result, errors) {
				document.getElementById(\"debug\").innerHTML = errors;
				if (result[\"list\"] != \"\")	{
					document.getElementById(\"l3\").innerHTML = result[\"list\"];
					if (go == 1) {
						document.getElementById(\"l3\").style.display = \"block\";
					}
				}
			},
			true,
			function (state) {
				time_line(state);
			}
		);
	}
	else
	{
		document.getElementById(\"l3\").innerHTML = \"\";
		document.getElementById(\"l3\").style.display = \"\";
	}
}


// individual template parameters can be modified via the calendar variable
o_cal.a_tpl.yearscroll = false;
o_cal.a_tpl.weekstart  = 1;
o_cal.a_tpl.months     = ['Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь', 'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь'];
o_cal.a_tpl.weekdays   = ['Вс', 'Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Суб'];

 
</script>

<div class=\"timeline\"><div id=\"time\" class=\"fix\"></div></div>
<div id=\"debug\"></div>




<FORM ACTION=$SELF_URL METHOD=POST NAME=marketing_report2>
<input type=hidden name=index value=$index>

<input type=hidden name=STREET_ID value='%STREET_ID%' ID='STREET_ID'>
<input type=hidden name=LOCATION_ID value='%LOCATION_ID%' ID='LOCATION_ID'>
<input type=hidden name=DISTRICT_ID value='%DISTRICT_ID%' ID='DISTRICT_ID'>


<TABLE>
<tr>
  <td>$_REQUEST_DATE:</td><td><input type=text name=REQUEST_DATE value='%REQUEST_DATE%' size=12>
  <script language='JavaScript'>var o_cal = new tcal ({	'formname': 'marketing_report2',	'controlname': 'REQUEST_DATE'	});</script>
  </td>
  <td>$_REGISTRATION:</td><td><input type=text name=REGISTRATION value='%REGISTRATION%' size=12>
  <script language='JavaScript'>var o_cal = new tcal ({	'formname': 'marketing_report2',	'controlname': 'REGISTRATION'	});</script>
  </td>
</tr>

<tr><th colspan=4 class=form_title align=right>$_ADDRESS <input type=checkbox name=ADDRESS value=1 checked></th></tr>
<tr>
  <td>$_LOCATION:</td><td><input type=text name=_LOCATION value='%LOCATION%'></td>
  <td>$_DISTRICT:</td><td><!-- %DISTRICT_SEL% -->
  <!-- <input type=text name=DISTRICT value='%DISTRICT%'> -->
  <div><input name=\"ADDRESS_DISTRICT\" id=\"p1\" type=\"text\" class=\"input\" value=\"%ADDRESS_DISTRICT%\" onkeyup=\"district()\" onclick=\"hide_unhide('l1')\"> 
 </div>
 <div id=\"l1\" class=\"lists\"></div>
  
  </td>
</tr>

<tr>
  <td>$_ADDRESS_STREET:</td><td><!-- %ADDRESS_STREET_SEL% -->
  <!-- <input type=text name=ADDRESS_STREET value='%ADDRESS_STREET%'> -->
  <div><input name=\"ADDRESS_STREET\" id=\"p2\" type=\"text\" class=\"input\" value=\"%ADDRESS_STREET%\" onkeyup=\"street()\" onclick=\"hide_unhide('l2')\"></div>
  <div id=\"l2\" class=\"lists\"></div>
  </td>
  <td>$_ADDRESS_BUILD:</td><td><!-- %ADDRESS_BUILD_SEL% -->
  <div><input id=\"p3\" type=\"text\" class=\"input\" value=\"%ADDRESS_BUILD%\" onkeyup=\"build()\" onclick=\"hide_unhide('l3')\"> 
  <!-- <a href=\"javascript:openwindow('$SELF_URL?qindex=68&header=1')\"  class=link_button>$_ADD</a> --> </div> 
  <div id=\"l3\" class=\"lists\"></div>
	
  <!-- <input type=text name=ADDRESS_BUILD value='%ADDRESS_BUILD%'> -->
  </td>
</tr>

<tr>
  <td>$_ENTRANCE:</td><td><input type=text name='ENTRANCE' value='%ENTRANCE%' size=7> $FLOR: <input type=text name='FLOR' value='%FLOR%' size=7></td>
  <td>$_ADDRESS_FLAT:</td><td><input type=text name=ADDRESS_FLAT value='%ADDRESS_FLAT%'></td>
</tr>

<tr><th colspan=4 class=form_title>Internet <input type=checkbox name=INTERNET value=1 checked></th></tr>

<tr><td colspan=2>$_TARIF_PLAN:</td><td colspan=2>%TP_ID_SEL% </td></tr>
<tr><td colspan=2>$_PRE_TP: </td><td colspan=2>%PRE_TP_ID_SEL%</td></tr>

<tr> <td colspan=2 colspan=2>$_TARIF_PLAN $_CHANGED:</td><td colspan=2><input type=text name=TARIF_PLAN_CHANGED value='%TARIF_PLAN_CHANGED%' size=12>
  <script language='JavaScript'>var o_cal = new tcal ({	'formname': 'marketing_report2',	'controlname': 'TARIF_PLAN_CHANGED'	});</script>
</td></tr>

<tr><th colspan=4 class=form_title>$_PAYMENTS <input type=checkbox name=PAYMENTS value=1 checked></th></tr>
<tr>
  <td>$_LAST_PAYMENT:</td><td><input type=text name=LAST_PAYMENT_DATE value='%LAST_PAYMENT_DATE%' size=12>
  <script language='JavaScript'>var o_cal = new tcal ({	'formname': 'marketing_report2',	'controlname': 'LAST_PAYMENT_DATE'	});</script>
  </td>
  <td>$_PAYMENTS $_TYPE:</td><td>%LAST_PAYMENT_METHOD_SEL%</td>
</tr>

<tr>
  <td>$_SUM:</td><td><input type=text name=LAST_PAYMENT_SUM value='%LAST_PAYMENT_SUM%'></td>
  <td>$_PAYMENT_TO_DATE:</td><td><input type=text name=PAYMENT_TO_DATE value='%PAYMENT_TO_DATE%' size=12>
  <script language='JavaScript'>var o_cal = new tcal ({	'formname': 'marketing_report2',	'controlname': 'PAYMENT_TO_DATE'	});</script>
  </td>
</tr>


<tr>
  <td>$_DEBTS_DAYS:</td><td><input type=text name=DEBTS_DAYS value='%DEBTS_DAYS%'></td>
  <td></td><td></td>
</tr>


<tr><th colspan=4 class=form_title>$_OTHER <input type=checkbox name=OTHER value=1 checked></th></tr>
<tr>
  <td>$_STATUS:</td><td>%STATUS_SEL%</td>
  <td></td><td></td>
</tr>

<tr>
  <td>$_FORUM_ACTIVITY:</td><td><input type=text name=FORUM value='%FORUM%'></td>
  <td></td><td></td>
</tr>

<tr>
  <td>$_BONUS:</td><td><input type=text name=BONUS value='%BONUS%'></td>
  <td></td><td></td>
</tr>



<tr>
  <td>$_DISABLE $_DATE:</td><td><input type=text name=DISABLE_DATE value='%DISABLE_DATE%' size=12>
  <script language='JavaScript'>var o_cal = new tcal ({	'formname': 'marketing_report2',	'controlname': 'DISABLE_DATE'	});</script>
  </td>
  <td>$_DISABLE $_COMMENTS:</td><td><input type=text name=DISABLE_REASON value='%DISABLE_REASON%'></td>
</tr>


<tr bgcolor=$_COLORS[2]>
  <td>$_ROWS:</td><td><input type=text name=PAGE_ROWS value='$LIST_PARAMS{PAGE_ROWS}'></td>
  <td> </td><td> </td>
</tr>
</TABLE>

<input type=submit name=search value=$_SEARCH>
</FORM>
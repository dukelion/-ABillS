<script src="/ajax/lib/JsHttpRequest/JsHttpRequest.js"></script>
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


<script language="JavaScript" type="text/javascript">

window.onload = function () {
    district('0');
}

function openwindow(params) {
  window.open(params, "calendar", "width=400,height=500,status=yes");
 }

function time_line(state) {
	if (state == 1) {
		document.getElementById("time").innerHTML = "<img src='/img/progbar.gif'>";
	}
	if (state == 4)	{	
		document.getElementById("time").innerHTML = "";
	}
}

function insert (id) {
	var arr = id.value.split("|");
	var teg = arr["0"];
	var value = arr["1"];
	var hide_teg = arr["2"];
	var key = arr["3"];

	document.getElementById(teg).value = value;
	document.getElementById(hide_teg).style.display = "";

	if (teg == 'p1') {
		document.getElementById('p2').value = "";
		document.getElementById('p3').value = "";
		document.getElementById('DISTRICT_ID').value = key;
		street('0');
	}
	if (teg == 'p2') {
		document.getElementById('STREET_ID').value = key;
		//document.getElementById('LOCATION_ID').value = key;
		build('0');
	}
	if (teg == 'p3') {
		document.getElementById('LOCATION_ID').value = key;
		build('0');
	}
}

function hide_unhide (teg) {
	if (document.getElementById(teg).innerHTML != "") {
		if (document.getElementById(teg).style.display == "") {
			document.getElementById(teg).style.display = "block";
		 }
		else {
			document.getElementById(teg).style.display = "";
		}
	}
}

function district(go) {
  if (go == 1) {
	  document.getElementById("p1").value = document.getElementById("p2").value = document.getElementById("p3").value = "";
	 }

	go = go || '1';

	if (document.getElementById("p1").value.length > 0 || go == 0) {
		JsHttpRequest.query	(
			"$SELF_URL",
			{
				"go": go,
				"qindex": 30,
				"address": 1,
			},
			function(result, errors) {
				document.getElementById("debug").innerHTML = errors;
				if (result["list"] != "")
				{
					document.getElementById("l1").innerHTML = result["list"];
					if (go == 1)
					{
						document.getElementById("l1").style.display = "block";
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
		document.getElementById("l1").innerHTML = "";
		document.getElementById("l1").style.display = "";
	}
}

function street(go) {
	go = go || '1';
	if (document.getElementById("p2").value.length > 0 || go == 0)
	{
		JsHttpRequest.query
		(
			"$SELF_URL",
			{
				"go": go,
				"qindex": 30,
				"address": 1,
				"DISTRICT_ID": document.getElementById("DISTRICT_ID").value,
			},
			function(result, errors) 
			{
				document.getElementById("debug").innerHTML = errors;
				if (result["list"] != "")
				{
					document.getElementById("l2").innerHTML = result["list"];
					if (go == 1)
					{
						document.getElementById("l2").style.display = "block";
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
		document.getElementById("l2").innerHTML = "";
		document.getElementById("l2").style.display = "";
	}
}

function build (go) {
	go = go || '1';
	if (document.getElementById("p3").value.length > 0 || go == 0)
	{
		JsHttpRequest.query
		(
      "$SELF_URL",
			{
				"go": go,
				"qindex": 30,
				"address": 1,
				"STREET": document.getElementById("STREET_ID").value,
			},			
	  function(result, errors) {
				document.getElementById("debug").innerHTML = errors;
				if (result["list"] != "")	{
					document.getElementById("l3").innerHTML = result["list"];
					if (go == 1) {
						document.getElementById("l3").style.display = "block";
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
		document.getElementById("l3").innerHTML = "";
		document.getElementById("l3").style.display = "";
	}
}
 
</script>

<div class="timeline"><div id="time" class="fix"></div></div>
<div id="debug"></div>

<input type=hidden name=STREET_ID value='%STREET_ID%' ID='STREET_ID'>
<input type=hidden name=LOCATION_ID value='%LOCATION_ID%' ID='LOCATION_ID'>
<input type=hidden name=DISTRICT_ID value='%DISTRICT_ID%' ID='DISTRICT_ID'>

<TR><TH colspan=2 class=form_title>$_ADDRESS</TH></TR>
<TR bgcolor='$_COLORS[2]'><TD>$_DISTRICTS:</TD><TD>
<div><input name="ADDRESS_DISTRICT" id="p1" type="text" class="input" value="%ADDRESS_DISTRICT%" onkeyup="district()" onclick="hide_unhide('l1')"> 
</div>
<div id="l1" class="lists"></div>
</TD></TR>

<TR bgcolor='$_COLORS[2]'><TD>$_ADDRESS_STREET:</TD><TD>
<div><input name="ADDRESS_STREET" id="p2" type="text" class="input" value="%ADDRESS_STREET%" onkeyup="street()" onclick="hide_unhide('l2')"></div>
<div id="l2" class="lists"></div>
</TD></TR>

<TR bgcolor='$_COLORS[2]'><TD>$_ADDRESS_BUILD:</TD><TD>
<div><input id="p3" type="text" class="input" value="%ADDRESS_BUILD%" onkeyup="build()" onclick="hide_unhide('l3')"> 
<!-- <a href="javascript:openwindow('$SELF_URL?qindex=68&header=1')"  class=link_button>$_ADD</a> --> </div> 
<div id="l3" class="lists"></div>
</TD></TR> 
<TR bgcolor='$_COLORS[2]'><TD>$_ADDRESS_FLAT:</TD><TD><input type=text name=ADDRESS_FLAT value='%ADDRESS_FLAT%' size=8></TD></TR>
<TR bgcolor='$_COLORS[2]'><TD colspan=2 align=right>%ADD_ADDRESS_LINK%</TD></TR>


<!-- <input type=submit name='' value='$_CHANGE' onclick="javascript:returnDate('Zone ID');"> -->
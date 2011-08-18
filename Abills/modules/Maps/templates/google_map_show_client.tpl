

  <head>

    <script src=\"http://maps.google.com/maps?file=api&amp;v=2&amp;key=ABQIAAAA-O3c-Om9OcvXMOJXreXHAxQGj0PqsCtxKvarsoS-iqLdqZSKfxS27kJqGZajBjvuzOBLizi931BUow\"
      type=\"text/javascript\"></script>
 
    <script type=\"text/javascript\">
var COLORS = [[\"red\", \"#ff0000\"], [\"orange\", \"#ff8800\"], [\"green\",\"#008000\"],
              [\"blue\", \"#000080\"], [\"purple\", \"#800080\"]];
var options = {};
var lineCounter_ = 0;
var shapeCounter_ = 0;
var markerCounter_ = 0;
var colorIndex_ = 0;
var featureTable_;
var map;
var lastPosX;
var lastPosY;
var lastZoom;






function getIcon(color) {
  var icon = new GIcon();
  icon.image = \"/img/google_map/\" + color + \".png\";
  icon.iconSize = new GSize(32, 32);
  icon.iconAnchor = new GPoint(15, 32);
  return icon;
}


 function createMarker(latlng, message, color) {
      var marker = new GMarker(latlng, getIcon(color));
      
      GEvent.addListener(marker,\"click\", function() {
        var myHtml = \"\" + message + \"<br/>\";
        map.openInfoWindowHtml(latlng, myHtml);
      });
      return marker;
  }


function initialize(x, y, zoom ) {
  if (GBrowserIsCompatible()) {
    map = new GMap2(document.getElementById(\"map\"));
    
    if (x == undefined && y == undefined && zoom == undefined) {
    map.setCenter(new GLatLng(50.43185060963318, 30.47607421875),5);
	} else {
	map.setCenter(new GLatLng(y,x ),zoom);
	}
    
    map.addControl(new GLargeMapControl());
    map.addControl(new GMapTypeControl());
              
 	%OBJECTS%  

  }
}

function chgposition (x, y , zoom) {
		map.setCenter(new GLatLng(y, x), zoom);
		lastPosX = x;
		lastPosY = y;
		lastZoom = zoom;
		
	}


	//chgposition(%MAPSETCENTER%);
    </script>

  </head>
<body onload=\"initialize(%MAPSETCENTER%)\" onunload=\"GUnload\">

<br />


<table><tr style=\"vertical-align:top\">
  <td style=\"width:15em;\" id=\"districts\" >

    <input type=\"hidden\" id=\"featuredetails\" rows=2>

    </input>

     <table id =\"featuretable\">
     <tbody id=\"featuretbody\"></tbody>
    </table>

    <br />
    <div align=center >%DISTRICTS%<br></div>
  </td>
  <td>
    <!-- The frame used to measure the screen size -->
    <div id=\"frame\"></div>

    <div id=\"map\" style=\"width:600px; height:300px\" ></div>
  </td>
</tr></table>

</body>
</html>

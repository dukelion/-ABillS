

  <head>

    <script src=\"http://maps.google.com/maps?file=api&amp;v=2&amp;key=ABQIAAAA-O3c-Om9OcvXMOJXreXHAxQGj0PqsCtxKvarsoS-iqLdqZSKfxS27kJqGZajBjvuzOBLizi931BUow\"
      type=\"text/javascript\"></script>
   <style type=\"text/css\">
body {
  font-family: Arial, sans serif;
  font-size: 11px;
}
#hand_b {
  width:31px;
  height:31px;
  background-image: url(/img/google_map/Bsu.png);
}
#hand_b.selected {
  background-image: url(/img/google_map/Bsd.png);
}

#placemark_b {
  width:31px;
  height:31px;
  background-image: url(/img/google_map/Bmu.png);
}
#placemark_b.selected {
  background-image: url(/img/google_map/Bmd.png);
}


#placeroute_b {
  width:31px;
  height:31px;
  background-image: url(/img/google_map/Blu.png);
}
#placeroute_b.selected {
  background-image: url(/img/google_map/Bld.png);
}


#line_b {
  width:31px;
  height:31px;
  background-image: url(/img/google_map/Blu.png);
}
#line_b.selected {
  background-image: url(/img/google_map/Bld.png);
}




#placedistrict {
  width:31px;
  height:31px;
  background-image: url(/img/google_map/Bpu.png);
}
#placedistrict.selected {
  background-image: url(/img/google_map/Bpd.png);
}

#addroute {
  width:31px;
  height:31px;
  background-image: url(/img/google_map/addr.png);
}
#addroute:hover {
  width:31px;
  height:31px;
  background-image: url(/img/google_map/addrh.png);
}


</style>
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

function select(buttonId) {
  document.getElementById(\"hand_b\").className=\"unselected\";
  document.getElementById(\"placedistrict\").className=\"unselected\";
  document.getElementById(\"line_b\").className=\"unselected\";
  document.getElementById(\"placemark_b\").className=\"unselected\";
  document.getElementById(\"placeroute_b\").className=\"unselected\";
  document.getElementById(buttonId).className=\"selected\";
}

function stopEditing() {
  select(\"hand_b\");
}

function getColor(named) {
  return COLORS[(colorIndex_++) % COLORS.length][named ? 0 : 1];
}

function getIcon(color) {
  var icon = new GIcon();
  icon.image = \"/img/google_map/\" + color + \".png\";
  icon.iconSize = new GSize(32, 32);
  icon.iconAnchor = new GPoint(15, 32);
  return icon;
}

function createMarker(latlng, message, color, title) {
  var marker = new GMarker(latlng, {title:title, icon:getIcon(color)});
 
  GEvent.addListener(marker,\"click\", function() {
    var myHtml = \"\" + message + \"<br/>\";
    map.openInfoWindowHtml(latlng, myHtml);
  });


  return marker;
}


function startShape() {
  select(\"shape_b\");
  var color = getColor(false);
  var polygon = new GPolygon([], color, 2, 0.7, color, 0.2);
  startDrawing(polygon, \"Фигура \" + (++shapeCounter_), function() {
    var cell = this;
    var area = polygon.getArea();
    cell.innerHTML = (Math.round(area / 10000) / 100) + \"km<sup>2</sup>\";
  }, color);
}

function startLine() {
  select(\"line_b\");
  var color = getColor(false);
  var line = new GPolyline([], color);
  startDrawing(line, \"Линия \" + (++lineCounter_), function() {
    var cell = this;
    
    var len = line.getLength();
    cell.innerHTML = (Math.round(len / 10) / 100) + \"km\";
  }, color);
}

function addFeatureEntry(name, color) {
  currentRow_ = document.createElement(\"tr\");
  var colorCell = document.createElement(\"td\");
  currentRow_.appendChild(colorCell);
  colorCell.style.backgroundColor = color;
  colorCell.style.width = \"1em\";
  var nameCell = document.createElement(\"td\");
  currentRow_.appendChild(nameCell);
  nameCell.innerHTML = name;
  var descriptionCell = document.createElement(\"td\");
  currentRow_.appendChild(descriptionCell);
  featureTable_.appendChild(currentRow_);
  return {desc: descriptionCell, color: colorCell};
}

function startDrawing(poly, name, onUpdate, color) {
  map.addOverlay(poly);
  poly.enableDrawing(options);
  poly.enableEditing({onEvent: \"mouseover\"});
  poly.disableEditing({onEvent: \"mouseout\"});
  GEvent.addListener(poly, \"endline\", function() {
    select(\"hand_b\");
    var cells = addFeatureEntry(name, color);
    GEvent.bind(poly, \"lineupdated\", cells.desc, onUpdate);
    GEvent.addListener(poly, \"click\", function(latlng, index) {
      if (typeof index == \"number\") {
        poly.deleteVertex(index);
      } else {
        var newColor = getColor(false);
        cells.color.style.backgroundColor = newColor
        poly.setStrokeStyle({color: newColor, weight: 4});
      }
    });
  });
}

function placeMarker() {
  select(\"placemark_b\");
  var listener = GEvent.addListener(map, \"click\", function(overlay, latlng) {
    if (latlng) {
      select(\"hand_b\");
      GEvent.removeListener(listener);
      var color = getColor(true);
      var marker = new GMarker(latlng, {icon: getIcon(color), draggable: false});
      map.addOverlay(marker);
      var coordx = latlng.x;
      var coordy = latlng.y;
      var cells = addFeatureEntry(\"<a href=index.cgi?index=$index&coordx=\" + coordx + \"&coordy=\" + coordy + \" > $_BUILD \" + (++markerCounter_) + \"</a>\", color);
      updateMarker(marker, cells);
      GEvent.addListener(marker, \"dragend\", function() {
        updateMarker(marker, cells);
        
      });
      GEvent.addListener(marker, \"click\", function() {
        updateMarker(marker, cells, true);
      });
    }
  });
}





function placeRoute() {
  select(\"placeroute_b\");
  var listener = GEvent.addListener(map, \"click\", function(overlay, latlng) {
    if (latlng) {
      select(\"hand_b\");
      GEvent.removeListener(listener);
      var color = getColor(true);
      var marker = new GMarker(latlng, {icon: getIcon('orange'), draggable: false});
      map.addOverlay(marker);
      var coordx = latlng.x;
      var coordy = latlng.y;
      var cells = addFeatureEntry(\"<a href=index.cgi?index=$index&coordlx=\" + coordx + \"&coordly=\" + coordy + \" > $_LINE \" + (++markerCounter_) + \"</a>\", color);
      updateMarker(marker, cells);
      GEvent.addListener(marker, \"dragend\", function() {
        updateMarker(marker, cells);
        
      });
      GEvent.addListener(marker, \"click\", function() {
        updateMarker(marker, cells, true);
      });
    }
  });
}







function placedistrict() {
  select(\"placedistrict\");
  var listener = GEvent.addListener(map, \"click\", function(overlay, latlng) {
    if (latlng) {
      select(\"hand_b\");
      GEvent.removeListener(listener);
      var color = getColor(true);
      var marker = new GMarker(latlng, {icon: getIcon('green'), draggable: false});
      var zoom = map.getZoom();
      map.addOverlay(marker);
      var coordx = latlng.x;
      var coordy = latlng.y;
      
      
      var cells = addFeatureEntry(\"<a href=index.cgi?index=$index&DCOORDX=\" + coordx + \"&DCOORDY=\" + coordy + \"&ZOOM=\"+ zoom + \" > $_DISTRICT \" + (++markerCounter_) + \"</a>\", color);
      updateMarker(marker, cells);
      GEvent.addListener(marker, \"dragend\", function() {
        updateMarker(marker, cells);
        
      });
      GEvent.addListener(marker, \"click\", function() {
        updateMarker(marker, cells, true);
      });
    }
  });
}


function updateMarker(marker, cells, opt_changeColor) {
  if (opt_changeColor) {
    var color = getColor(true);
    marker.setImage(getIcon(color).image);
    cells.color.style.backgroundColor = color;
  }
  var latlng = marker.getPoint();
  cells.desc.innerHTML = \" ( \" + Math.round(latlng.y * 100) / 100 + \", \" +
  Math.round(latlng.x * 100) / 100 + \")\";

	

}


function initialize(x,y, zoom) {
  if (GBrowserIsCompatible()) {
    map = new GMap2(document.getElementById(\"map\"));
   	if (x == undefined && y == undefined && zoom == undefined) {
   		map.setCenter(new GLatLng(50.43185060963318, 30.47607421875),5);
    } else {
    	map.setCenter(new GLatLng(y, x), zoom);
    }
	
	%ROUTES%
	
	
    
    map.addControl(new GLargeMapControl());
    map.addControl(new GMapTypeControl());
    map.enableGoogleBar();
    map.clearOverlays();
    featureTable_ = document.getElementById(\"featuretbody\");
    select(\"hand_b\");
  

  
  
  }
}
function chgposition (x, y , zoom) {
		map.setCenter(new GLatLng(y, x), zoom);
	}
    </script>

  </head>
<body onload=\"initialize(%MAPSETCENTER%)\" onunload=\"GUnload\">

<table><tr style=\"vertical-align:top\">
  <td style=\"width:15em\">

<table><tr>
<td><div id=\"hand_b\"
	 onclick=\"stopEditing()\"/ ></td>

<td><div id=\"placemark_b\"
	 onclick=\"placeMarker()\"/ title=\"$_ADD_HOUSE\"></td>

 <td><div  id=\"line_b\" style=\"display:none\"
	 onclick=\"startLine()\"/></td> 

<td><div id=\"placedistrict\"
	onclick=\"placedistrict()\" title=\"$_ADD_DISTRICT\"/></td>

<td><div id=\"placeroute_b\"
	onclick=\"placeRoute()\" title=\"$_ADD_ROUTE\"/></td>

<td><div id=\"addroute\"
	onclick=\"location.href='index.cgi?index=$index&route=add' \" title=\"$_CREATE_EDIT_ROUTE\"/></td>	
</tr></table>

    <input type=\"hidden\" id=\"featuredetails\" rows=2>

    </input>
<p>
</p>
     <table id =\"featuretable\">
     <tbody id=\"featuretbody\"></tbody>
    </table>
    <hr />
    <br />
    <div align=center>%DISTRICTS%</div>
  </td>
  <td>
    <!-- The frame used to measure the screen size -->
    <div id=\"frame\"></div>

    <div id=\"map\" style=\"width: 800px; height: 500px\"></div>
  </td>
</tr></table>
</body>
</html>

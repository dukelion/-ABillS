

  <head>
     <style type=\"text/css\">
       .context {
         font-family:Arial, sans-serif;
         text-decoration:none;
         color:#4444ff;
         font-size:small;
       }

       a:hover div {
         background:#eee;
       }       
     </style>

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
var clickedPixel; 
var clickedOverlay;
var delCoordX;
var delCoordY;
var markerId;

function select(buttonId) {
  document.getElementById(\"hand_b\").className=\"unselected\";
  document.getElementById(\"shape_b\").className=\"unselected\";
  document.getElementById(\"line_b\").className=\"unselected\";
  document.getElementById(\"placemark_b\").className=\"unselected\";
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

	GEvent.addListener(map, 'singlerightclick', function(pixel,tile, overlay) {
    if(marker)
    	alert('123');
        });


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
    



 	%NAS%
      
          
 	%OBJECTS%  
 

	%ROUTES%
    
      // === create the context menu div ===
      
      var contextmenu = document.createElement(\"div\");
      contextmenu.style.visibility=\"hidden\";
      contextmenu.style.background=\"#ffffff\";
      contextmenu.style.border=\"1px solid #8888FF\";
      map.getContainer().appendChild(contextmenu);
      contextmenu.id = \"menus\";


      // ===context menu HTML for varioys situations ===





      // === listen for singlerightclick ===
      GEvent.addListener(map,\"singlerightclick\",function(pixel,tile,overlay) {
        // store the \"pixel\" info in case we need it later
        // adjust the context menu location if near an egde
        // create a GControlPosition
        clickedPixel = pixel;
        var x=pixel.x;
        var y=pixel.y;
        if (x > map.getSize().width - 120) { x = map.getSize().width - 120 }
        if (y > map.getSize().height - 100) { y = map.getSize().height - 100 }
        var pos = new GControlPosition(G_ANCHOR_TOP_LEFT, new GSize(x,y));
          
        // == was the click on the map? ==
        if (!overlay) {
          // insert the map HTMP, apply the position to the context menu, and make it visible 
          contextmenu.innerHTML = mapContextHtml;
          pos.apply(contextmenu);
          contextmenu.style.visibility = \"visible\";
        } else {
        
          // == was the click on a GMarker? ==
          if (overlay instanceof GMarker) {
          	if (overlay.getTitle() != 'NAS') {
            	// insert the marker HTML, apply the position to the ovelay context menu, and make it visible 
            	contextmenu.innerHTML = '<a class=\"context\" href=\"index.cgi?index=$index&dcoordx=' + overlay.getLatLng().x + '&dcoordy='+ overlay.getLatLng().y + '\"><div >&nbsp;&nbsp;Удалить маркер&nbsp;&nbsp;<\/div><\/a>';
            	pos.apply(contextmenu);
            	contextmenu.style.visibility = \"visible\";
            	clickedOverlay = overlay;
            }
            
            
          }          
        
          // == was the click on a GPolyline? ==
          if (overlay instanceof GPolyline) {
            // insert the polyline HTML, apply the position to the ovelay context menu, and make it visible 
            contextmenu.innerHTML = polylineContextHtml;
            pos.apply(contextmenu);
            contextmenu.style.visibility = \"visible\";
            clickedOverlay = overlay;
          }          
        }
        
        
        
        

      });





      



      // === If the user clicks on aything, close the context menus ===
      GEvent.addListener(map, \"click\", function() {
        contextmenu.style.visibility=\"hidden\";
      });

  
  
  
  }
  
  	mapContextHtml = '<a class=\"context\" href=\"javascript:zoomIn()\"><div >&nbsp;&nbsp;$_ZOOM_IN&nbsp;&nbsp;<\/div><\/a>'
	 + '<a class=\"context\" href=\"javascript:zoomOut()\"><div >&nbsp;&nbsp;$_ZOOM_OUT&nbsp;&nbsp;<\/div><\/a>'
	 + '<a class=\"context\" href=\"javascript:zoomInHere()\"><div >&nbsp;&nbsp;$_ZOOOM_IN_HERE&nbsp;&nbsp;<\/div><\/a>'
	 + '<a class=\"context\" href=\"javascript:zoomOutHere()\"><div >&nbsp;&nbsp;$_ZOOOM_OUT_HERE&nbsp;&nbsp;<\/div><\/a>'
	 + '<a class=\"context\" href=\"javascript:centreMapHere()\"><div >&nbsp;&nbsp;$_CENTER_MAP_HERE&nbsp;&nbsp;<\/div><\/a>';
	
	//markerContextHtml =;	
  
}





function chgposition (x, y , zoom) {
		map.setCenter(new GLatLng(y, x), zoom);
		lastPosX = x;
		lastPosY = y;
		lastZoom = zoom;
		
	}


function hideShowDistrict () 
{
	
	if (document.getElementById('districts').style.display == 'none') {
		document.getElementById('districts').style.display = 'block';
		document.getElementById('districtButton').firstChild.nodeValue = '$_HIDE_DISTRICTS';
	} else {
		document.getElementById('districts').style.display = 'none';
		document.getElementById('districtButton').firstChild.nodeValue = '$_SHOW_DISTRICTS';
		
		
	}
	if (document.getElementById('districts').style.display == 'none') {		
		
		var height = window.innerHeight;
		var width = window.innerWidth;
		//var height = height  - ((height /100) * 10);
		//var width = width  - ((width /100) * 10);  
		
		
		document.getElementById('map').style.width=width+'px';
		document.getElementById('map').style.height=height+ 'px';
		
		if (lastPosX == undefined, lastPosY == undefined, lastZoom == undefined) {
			initialize(%MAPSETCENTER%);
		} else {
			initialize(lastPosX, lastPosY+0.002, lastZoom);
		}
	} else {
		document.getElementById('map').style.width='800px';
		document.getElementById('map').style.height='500px';
		
		if (lastPosX == undefined, lastPosY == undefined, lastZoom == undefined) {
			initialize(%MAPSETCENTER%);
			
		} else {
			initialize(lastPosX, lastPosY, lastZoom);
		}
	}
	
	


	
	
}

function fullScreenDistrict() 
	{
				var height = window.innerHeight;
		var width = window.innerWidth;
		newWindow = window.open(\"/admin/index.cgi?qindex=$index&header=1\",\"new\", \" 'width=' + width + ',height=' + height \")
		newWindow.focus();
		//newWindow.document.writeln('<h1>Popup Test!</h1>');
		//newWindow.document.getElementById('featuretable').style.display = 'none';
		newWindow.document.getElementById('districtButton').style.display = 'none';
		

	}

      // === functions that implement the context menu options ===
      function zoomIn() {
        // perform the requested operation
        map.zoomIn();
        // hide the context menu now that it has been used
        //contextmenu.style.visibility=\"hidden\";
        document.getElementById('menus').style.visibility=\"hidden\";
      }      
      function zoomOut() {
        // perform the requested operation
        map.zoomOut();
        // hide the context menu now that it has been used
        //contextmenu.style.visibility=\"hidden\";
      	document.getElementById('menus').style.visibility=\"hidden\";
      }      
      function zoomInHere() {
        // perform the requested operation
        var point = map.fromContainerPixelToLatLng(clickedPixel)
        map.zoomIn(point,true);
        // hide the context menu now that it has been used
        //contextmenu.style.visibility=\"hidden\";
      	document.getElementById('menus').style.visibility=\"hidden\";
      }      
      function zoomOutHere() {
        // perform the requested operation
        var point = map.fromContainerPixelToLatLng(clickedPixel)
        map.setCenter(point,map.getZoom()-1); // There is no map.zoomOut() equivalent
        // hide the context menu now that it has been used
        //contextmenu.style.visibility=\"hidden\";
      	document.getElementById('menus').style.visibility=\"hidden\";
      }      
      function centreMapHere() {
        // perform the requested operation
        var point = map.fromContainerPixelToLatLng(clickedPixel)
        map.setCenter(point);
        // hide the context menu now that it has been used
        //contextmenu.style.visibility=\"hidden\";
      	document.getElementById('menus').style.visibility=\"hidden\";
      }
      
      function deleteoverlay() {
        //map.removeOverlay(clickedOverlay);
        // hide the context menu now that it has been used
        //contextmenu.style.visibility=\"hidden\";
        document.getElementById('menus').style.visibility=\"hidden\";
        
      }
      
      function redline() {
        clickedOverlay.setStrokeStyle({color:\"#FF0000\"});
        // hide the context menu now that it has been used
        //contextmenu.style.visibility=\"hidden\";
      	document.getElementById('menus').style.visibility=\"hidden\";
      }
      
      function greenline() {
        clickedOverlay.setStrokeStyle({color:\"#00FF00\"});
        // hide the context menu now that it has been used
        //contextmenu.style.visibility=\"hidden\";
      	document.getElementById('menus').style.visibility=\"hidden\";
      }
      
      function blueline() {
        clickedOverlay.setStrokeStyle({color:\"#0000FF\"});
        // hide the context menu now that it has been used
        //contextmenu.style.visibility=\"hidden\";
      	document.getElementById('menus').style.visibility=\"hidden\";
      }


	//chgposition(%MAPSETCENTER%);
    </script>

  </head>
<body onload=\"initialize(%MAPSETCENTER%)\" onunload=\"GUnload\">

<br />
<a  class='link_button' id=\"districtButton\" onclick=javascript:hideShowDistrict()>$_HIDE_DISTRICTS</a>
<a  class='link_button' id=\"districtButton\" onclick=javascript:fullScreenDistrict()>$_IN_NEW_WINDOW</a>

<table><tr style=\"vertical-align:top\">
  <td style=\"width:15em;\" id=\"districts\" >



    <input type=\"hidden\" id=\"featuredetails\" rows=2>

    </input>

     <table id =\"featuretable\">
     <tbody id=\"featuretbody\"></tbody>
    </table>

    <br />
    <div align=center >%DISTRICTS%  %DELDISTRICT%</div>
     
  </td>
  <td>
    <!-- The frame used to measure the screen size -->
    <div id=\"frame\"></div>

    <div id=\"map\" style=\"width:800px; height:500px\" ></div>
  </td>
</tr></table>

 

</body>
</html>

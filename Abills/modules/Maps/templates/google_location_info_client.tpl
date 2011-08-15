
 
	var latlng = new GLatLng(%MAP_Y%, %MAP_X% );
	var Mcolor;
	var thOnline;
	Mcolor = 'green';

	map.addOverlay(createMarker(latlng, '<strong>$_STREET: </strong>%STREET_ID%<br /><strong>$_BUILD: </strong>%NUMBER%<br /><strong>', Mcolor)); 
	    
<?php
	require('../../admin/incl/index_prefix.php');
	$wms_url = 'WMS_URL';
	if(str_starts_with($wms_url, '/mproxy/')){
		$proto = empty($_SERVER['HTTPS']) ? 'http' : 'https';
		$content = file_get_contents($proto.'://'.$_SERVER['HTTP_HOST'].'/admin/action/authorize.php?secret_key=SECRET_KEY&ip='.$_SERVER['REMOTE_ADDR']);
		$auth = json_decode($content);
		$wms_url .= '?access_key='.$auth->access_key;
	}
?>
<!DOCTYPE html>
<html lang="en">
<head>
	<base target="_top">
	<meta charset="utf-8">
	<meta name="viewport" content="width=device-width, initial-scale=1">
	
	<title><?=urlencode(implode(',', QGIS_LAYERS))?></title>
	
	<link rel="shortcut icon" type="image/x-icon" href="docs/images/favicon.ico" />
	<link rel="stylesheet" href="https://unpkg.com/leaflet/dist/leaflet.css"/>
	<script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
	<script src="../../assets/dist/js/leaflet.browser.print.min.js"></script>
	<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/leaflet.draw/0.4.2/leaflet.draw.css"/>

	<link rel="stylesheet" href="../../assets/dist/css/Control.MiniMap.css"/>
	<link rel="stylesheet" href="../../assets/dist/css/leaflet.measurecontrol.css"/>
	<link rel="stylesheet" href="../../assets/dist/css/L.Control.Opacity.css"/>

	<script src="https://cdnjs.cloudflare.com/ajax/libs/leaflet.draw/0.4.2/leaflet.draw.js"></script>
	<script src="https://code.jquery.com/jquery-3.7.1.min.js"></script>
	<script src="../../assets/dist/js/L.BetterWMS.js"></script>
	<script src="../../assets/dist/js/Control.MiniMap.js"></script>
	<script src="../../assets/dist/js/leaflet.measurecontrol.js"></script>
	<script src="../../assets/dist/js/L.Control.Opacity.js"></script>


<style type="text/css">
html, body, #map {
	margin: 0px;
  height: 100%;
  width: 100%;
}  
.leaflet-clickable {
	cursor: pointer !important;
}
.leaflet-container {
	cursor: pointer !important;
}
 .leaflet-popup-content {
    max-width: 600px;
    height: 400px;
    overflow-y: scroll;
}
</style>
</head>
<body>

<div id='map'></div>

<script type="text/javascript">

	const map = L.map('map', {
		center: [0, 0],
		zoom: 16
	});

	// Basemaps

	var osm = L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
            maxZoom: 19,
            attribution: '&copy; <a href="http://www.openstreetmap.org/copyright">OpenStreetMap</a>'
        }).addTo(map);

	var carto = L.tileLayer('https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png', {
            maxZoom: 19,
            attribution: '&copy; <a href="https://carto.com/attributions">CARTO</a>Carto</a>'
        }).addTo(map);

	var esri = L.tileLayer('https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}.png', {
            maxZoom: 19,
            attribution: '&copy; <a href="http://www.esri.com">ESRI</a>'
        }).addTo(map);

      // WMS Layer

	const wmsLayer = L.tileLayer.betterWms('<?=$wms_url?>', {
		layers: 'WMS_LAYERS',
		transparent: 'true',
  		format: 'image/png'
	}).addTo(map);

	map.fitBounds(BOUNDING_BOX);

	// Group overlays and basemaps

	var overlayMap = {
	'<?=implode(',', QGIS_LAYERS)?>' :wmsLayer
	};

	var baseMap = {
	"OpenStreetMap" :osm,
	"ESRI Satellite" :esri,
	"CartoLight" :carto,
	};

	// Layer Selector

	L.control.layers(baseMap, overlayMap,{collapsed:false}).addTo(map);

	L.control
	.opacity(overlayMap, {
        label: 'Layers Opacity',
	})
    	.addTo(map);

	// Legend

	var legend = L.control({position: 'bottomleft'}); 
	legend.onAdd = function (map) {        
    	var div = L.DomUtil.create('div', 'info legend');
    	div.innerHTML = '<img src="proxy_qgis.php?SERVICE=WMS&REQUEST=GetLegendGraphic&LAYERS=<?=urlencode(implode(',', QGIS_LAYERS))?>&FORMAT=image/png">';     
    	return div;
	};      
	legend.addTo(map);

	// Broswer Print

	L.control.browserPrint({
			title: '<?=implode(',', QGIS_LAYERS)?>',
			documentTitle: 'My Leaflet Map',
			printLayer: L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
					attribution: 'Map tiles by <a href="http://openstreetmap.com">OpenStreetMap</a>',
					subdomains: 'abcd',
					minZoom: 1,
					maxZoom: 16,
					ext: 'png'
				}),
		closePopupsOnPrint: false,
		printModes: [
            	L.BrowserPrint.Mode.Landscape(),
            	"Portrait",
            	L.BrowserPrint.Mode.Auto("B4",{title: "Auto"}),
            	L.BrowserPrint.Mode.Custom("B5",{title:"Select area"})
			],
			manualMode: false
		}).addTo(map);

	// Draw

	var drawnItems = new L.FeatureGroup();
        	map.addLayer(drawnItems);

        var drawControl = new L.Control.Draw({
            edit: {
                featureGroup: drawnItems
            }
        	});
        	map.addControl(drawControl);

        	map.on('draw:created', function (e) {
            	var type = e.layerType,
                	layer = e.layer;
            	drawnItems.addLayer(layer);
        	});

	// Measure

	L.Control.measureControl().addTo(map);

	// Minimap
	var osmUrl='http://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png';
	var osmAttrib='Map data &copy; OpenStreetMap contributors';

	var osmMini = new L.TileLayer(osmUrl, {minZoom: 0, maxZoom: 13, attribution: osmAttrib });
	var miniMap = new L.Control.MiniMap(osmMini, { toggleDisplay: true }).addTo(map);
</script>

</body>
</html>

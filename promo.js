mapboxgl.accessToken = 'pk.eyJ1IjoibGF1cmVuc3ZlcnNsdWlzIiwiYSI6ImNqaTFwOWVuMTB4aXUzb3JucHJlaGszbXEifQ.0veXMDDvMnMYG29i-HvNZQ';

var map = new mapboxgl.Map({
    container: 'map',
   style: 'mapbox://styles/mapbox/streets-v9',
    // style: 'mapbox://styles/laurensversluis/cjiw2nfgt97zz2sq8ennhpm7h',
    center: [5.001128, 52.008653],
    zoom: 10,
    pitch: 60
});
// Adding navigation
var nav = new mapboxgl.NavigationControl();
map.addControl(nav, 'top-left');


// Adding layers and layer toggle
var layers = [
    {'PTAL': 'ptal_500m_grid'},
    {'PTAL extruded': 'ptal_500m_grid_extruded'},
    {'PT stops': 'ptal_stops'},
    {'PT network': 'ptal_network2'}
    ];

map.on('load', function() {

    for (var i = 0; i < layers.length; i++) {
        // Getting layer information
        var layer_dict = layers[i];
        var layer_ref = Object.keys(layer_dict)[0];
        var layer_source = layer_dict[layer_ref];

        // Make only the first layer visible
        if (i === 0) {
            map.setLayoutProperty(layer_source, 'visibility', 'visible');
        } else {
            map.setLayoutProperty(layer_source, 'visibility', 'none');
        }

        // Generate toggle menu
        var link = document.createElement('a') ;
        link.href = '#';
        // link.className = 'active';
        link.textContent = layer_ref;
        link.source = layer_source;

        // Implement toggling
        link.onclick = function (e) {
            var layer_source = this.source;
            e.preventDefault();
            e.stopPropagation();

            var visibility = map.getLayoutProperty(layer_source, 'visibility');
            if (visibility === 'visible') {
                map.setLayoutProperty(layer_source, 'visibility', 'none');
                this.className = '';
            } else {
                this.className = 'active';
                map.setLayoutProperty(layer_source, 'visibility', 'visible');
            }
        };

    var menu = document.getElementById('menu');
    menu.appendChild(link);
    }

    // Adding logo
    var mapControlsContainer = document.getElementsByClassName("mapboxgl-control-container")[0];
    var logo = document.getElementById("logo_container");
    mapControlsContainer.appendChild(logo);


});


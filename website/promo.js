mapboxgl.accessToken = 'pk.eyJ1IjoibGF1cmVuc3ZlcnNsdWlzIiwiYSI6ImNqaTFwOWVuMTB4aXUzb3JucHJlaGszbXEifQ.0veXMDDvMnMYG29i-HvNZQ';

var map = new mapboxgl.Map({
    container: 'map',
   // style: 'mapbox://styles/mapbox/streets-v9',
    style: 'mapbox://styles/laurensversluis/cjiw2nfgt97zz2sq8ennhpm7h',
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

var legend = document.getElementById('legend');

var legend_elements = {
    'PTAL':{
        ranges: [
            '1a very poor',
            '1b very poor',
            '2 poor',
            '3 moderate',
            '4 good',
            '5 very good',
            '6a excellent',
            '6b most excellent'],
        colors: ['#1e038c', '#1d59d3', '#00dada', '#96ec62', '#fbeb00', '#fdca30', '#ff3300', '#bd0900']
    },
    'PT Network': {
        ranges: [
            'train',
            'metro',
            'tram',
            'bus',
            'ferry'
        ],
        colors: ['#ea2a2a', '#f07c0f', '#c7f63c', '#401ff9', '#eb37d3']
    }
};

map.on('load', function() {

    // Adding layers to map and toggle menu
    for (var i = 0; i < layers.length; i++) {
        // Getting layer information
        var layer_dict = layers[i];
        var layer_ref = Object.keys(layer_dict)[0];
        var layer_source = layer_dict[layer_ref];

        // Generate toggle menu
        var link = document.createElement('a') ;
        link.href = '#';
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

        // Update toggle menu to initial state
        var visibility = map.getLayoutProperty(layer_source, 'visibility');
        if (visibility === 'visible') {
            link.className = 'active';
        } else {
            link.className = '';
        }


    var menu = document.getElementById('menu');
    menu.appendChild(link);
    }

    // Adding legend
    for (l = 0; l < Object.keys(legend_elements).length; l++) {

        // Read layer symbology
        var layer = Object.keys(legend_elements)[l];
        var layer_info = legend_elements[layer];
        var ranges = layer_info['ranges'];
        var colors = layer_info['colors'];

        // Create legend container for each layer
        var container = document.createElement('div');
        container.className = 'legend-container';
        var title = document.createElement('span');
        title.innerHTML = layer;
        title.className = 'legend-title';
        container.appendChild(title);

        for (i = 0; i < ranges.length; i++) {
            var range = ranges[i];
            var color = colors[i];
            var item = document.createElement('div');

            // Create symbol
            var key = document.createElement('span');
            key.className = 'legend-key';
            key.style.backgroundColor = color;
            item.appendChild(key);

            // Create label
            var value = document.createElement('span');
            value.innerHTML = range;
            item.appendChild(key);
            item.appendChild(value);

            container.appendChild(item);
        }
        legend.appendChild(container);
    }

    // Adding logo
    var mapControlsContainer = document.getElementsByClassName("mapboxgl-control-container")[0];
    var logo = document.getElementById("logo_container");
    mapControlsContainer.appendChild(logo);


});


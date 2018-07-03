mapboxgl.accessToken = 'pk.eyJ1IjoibGF1cmVuc3ZlcnNsdWlzIiwiYSI6ImNqaTFwOWVuMTB4aXUzb3JucHJlaGszbXEifQ.0veXMDDvMnMYG29i-HvNZQ';

var map = new mapboxgl.Map({
    container: 'map',
    style: 'mapbox://styles/laurensversluis/cjiw2nfgt97zz2sq8ennhpm7h',
    center: [5.001128, 52.008653],
    zoom: 9.2
});

map.on('load', function() {
  map.addLayer({
    id: 'laurensversluis.326iwqo1',
    type: 'fill',
    source: {
      type: 'vector',
      url: 'mapbox://styles/laurensversluis/cji1q65d504h52snbn5b9shqq'
    },
    'source-layer': 'laurensversluis.326iwqo1'
  });
});
var token = mapboxgl.accessToken = 'pk.eyJ1IjoibGF1cmVuc3ZlcnNsdWlzIiwiYSI6ImNqaTFwOWVuMTB4aXUzb3JucHJlaGszbXEifQ.0veXMDDvMnMYG29i-HvNZQ';

var map = new mapboxgl.Map({
    container: 'map', // container id
    style: 'mapbox://styles/laurensversluis/cji1paw4m1yco2rmqz05g0qcj', // stylesheet location-->
    center: [5.001128, 52.008653], // starting position [lng, lat]-->
    zoom: 9, // starting zoom-->
    minZoom: 9
});









// var mb_token = 'pk.eyJ1IjoibGF1cmVuc3ZlcnNsdWlzIiwiYSI6ImNqaTFwOWVuMTB4aXUzb3JucHJlaGszbXEifQ.0veXMDDvMnMYG29i-HvNZQ';
// var access_token = L.mapbox.accessToken = 'pk.eyJ1IjoibGF1cmVuc3ZlcnNsdWlzIiwiYSI6ImNqaTFwOWVuMTB4aXUzb3JucHJlaGszbXEifQ.0veXMDDvMnMYG29i-HvNZQ';
// // var dark = L.tileLayer('https://api.mapbox.com/styles/v4/laurensversluis/cji1paw4m1yco2rmqz05g0qcj/tiles/256/{z}/{x}/{y}?access_token=' + mb_token, {
// //     attribution: 'Map data &copy; <a href="http://openstreetmap.org">OpenStreetMap</a> contributors, <a href="http://creativecommons.org/licenses/by-sa/2.0/">CC-BY-SA</a>, Imagery © <a href="http://mapbox.com">Mapbox</a>'
// // });
//
// var dark = L.tileLayer('https://api.mapbox.com/v4/{tilesetId}/{z}/{x}/{y}.png?access_token={accessToken}', {
//     attribution: 'Map data &copy; <a href="http://openstreetmap.org">OpenStreetMap</a> contributors, <a href="http://creativecommons.org/licenses/by-sa/2.0/">CC-BY-SA</a>, Imagery © <a href="http://mapbox.com">Mapbox</a>',
//     tilesetId: 'laurensversluis/cji1q65d504h52snbn5b9shqq',
//     accessToken: 'pk.eyJ1IjoibGF1cmVuc3ZlcnNsdWlzIiwiYSI6ImNqaTFwOWVuMTB4aXUzb3JucHJlaGszbXEifQ.0veXMDDvMnMYG29i-HvNZQ',
//     minZoom: 9
// });
//
//
// var basemap = L.tileLayer('https://api.mapbox.com/styles/v4/laurensversluis/cjiru4uj04age2rmnpxqlp0t5/tiles/256/{z}/{x}/{y}?access_token=' + mb_token, {});
// //
// // var ptal = L.mapbox.tileLayer('https://api.mapbox.com/styles/v1/laurensversluis/cjiru4uj04age2rmnpxqlp0t5/tiles/256/{z}/{x}/{y}?access_token=pk.eyJ1IjoibGF1cmVuc3ZlcnNsdWlzIiwiYSI6ImNqaTFwOWVuMTB4aXUzb3JucHJlaGszbXEifQ.0veXMDDvMnMYG29i-HvNZQ', {
// //     zoomOffset: -1
// // });
//
// var mbAttr = 'Map data &copy; <a href="https://www.openstreetmap.org/">OpenStreetMap</a> contributors, ' +
//         '<a href="https://creativecommons.org/licenses/by-sa/2.0/">CC-BY-SA</a>, ' +
//         'Imagery © <a href="https://www.mapbox.com/">Mapbox</a>',
//     mbUrl = 'https://api.tiles.mapbox.com/v4/{id}/{z}/{x}/{y}.png?access_token=pk.eyJ1IjoibGF1cmVuc3ZlcnNsdWlzIiwiYSI6ImNqaTFwOWVuMTB4aXUzb3JucHJlaGszbXEifQ.0veXMDDvMnMYG29i-HvNZQ';
//
// var grayscale   = L.tileLayer(mbUrl, {id: 'mapbox.light', attribution: mbAttr}),
//     streets  = L.tileLayer(mbUrl, {id: 'mapbox.streets',   attribution: mbAttr});
//     // satellite = L.tileLayer(mbUrl, id: 'mapbox.sa')
//     // ptal = L.tileLayer(mbUrl, {id: 'laurensversluis.cji1q65d504h52snbn5b9shqq'});
//
//
// var ptal = L.mapbox.styleLayer('mapbox://styles/laurensversluis/cji1q65d504h52snbn5b9shqq');
//
// var map = L.map('map', {
//     center: [52.008653, 5.001128], // starting position [lng, lat]
//     zoom: 10,
//     layers: [ptal]
// });
//
// // var baseMaps = {
// //     "Grayscale": grayscale,
// //     "Color": streets
// // };
//
// var overlayMaps = {
//     "PTAL": ptal
// };
//
// L.control.layers(overlayMaps).addTo(map);
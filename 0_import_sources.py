import urllib3
import json
from shapely.geometry import shape
import csv
import lxml.etree as et
import math

# url = "https://geodata.nationaalgeoregister.nl/bag/wfs?&version=1.0.0&request=GetFeature&service=WFS&typeName=bag:verblijfsobject&filter=%3CFilter%3E%3CPropertyIsEqualTo%3E%3CPropertyName%3Ewoonplaats%3C/PropertyName%3E%3CLiteral%3EUtrecht%3C/Literal%3E%3C/PropertyIsEqualTo%3E%3C/Filter%3E&outputFormat=application/json&count=10000000"

# Create WFS data request
wfs = "https://geodata.nationaalgeoregister.nl/bag/wfs?"
req = "&version=2.0.0&request=GetFeature&service=WFS"
name = "&typeName=" + "bag:verblijfsobject"
filter = "&filter=" + "%3CFilter%3E%3CPropertyIsEqualTo%3E%3CPropertyName%3Ewoonplaats%3C/PropertyName%3E%3CLiteral%3E" + "Utrecht" + "%3C/Literal%3E%3C/PropertyIsEqualTo%3E%3C/Filter%3E"
count = 1000
count_url = "&count=" + str(count)
properties = "&propertyName=" + "identificatie,pandidentificatie,pandgeometrie"
data_format = "&outputFormat=" + "application/json"
hits = "&resulttype=hits"

def get_data_by_url(url: str):
    http = urllib3.PoolManager()
    req = http.request('GET', url)
    return req.data

def get_xml_attribute(element_tree: et, attribute: str) -> int:
    return et.fromstring(data).attrib[attribute]

def write_dict_list(file_name, fieldnames: list, rows: list):
    with open(file_name, 'w', newline='') as csvfile:
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)
        csvfile.close()

# Get number of records
amount_url = wfs + req + name + filter + data_format + hits
data = get_data_by_url(amount_url)
record_count = int(get_xml_attribute(data, 'numberMatched'))
batch_count = int(math.ceil(record_count/count))

# Get WFS data and select fields
output_headers = ['address_id', 'building_id', 'geom']
output_file = 'building_list.csv'
addresses = []
for b in range(0, batch_count):
    print(b)
    start_index = "&startIndex=" + str(b * count)
    data_url = wfs + req + name + data_format + count_url + filter + start_index
    data = json.loads(get_data_by_url(data_url).decode('utf-8'))
    for a in data['features']:
        address_id = str(a['properties']['identificatie'])
        building_id = str(a['properties']['pandidentificatie'])
        geom = shape(a['properties']['pandgeometrie']).wkt # use Shapely shape to convert geojson to wkt
        address = {'address_id': address_id, 'building_id': building_id, 'geom': geom}
        addresses.append(address)

# Write data
write_dict_list(output_file, output_headers, addresses)




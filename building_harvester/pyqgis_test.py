from qgis.core import QgsApplication, QgsVectorLayer
from PyQt5.QtGui import QGuiApplication

app = QGuiApplication([])
QgsApplication.setPrefixPath("C:/OSGeo4W64/apps/qgis", True)
QgsApplication.initQgis()


wfs = "https://geodata.nationaalgeoregister.nl/bag/wfs?"
req = "&version=2.0.0&request=GetFeature&service=WFS"
name = "&typeName=" + "bag:verblijfsobject"
filter = "&filter=" + "%3CFilter%3E%3CPropertyIsEqualTo%3E%3CPropertyName%3Ewoonplaats%3C/PropertyName%3E%3CLiteral%3E" + "Utrecht" + "%3C/Literal%3E%3C/PropertyIsEqualTo%3E%3C/Filter%3E"
count = 10
count_url = "&count=" + str(count)
uri = wfs + req + name + count_url

shape = "C:\\Users\laurens.versluis\\Documents\\VIBER\\ForeFreedom.shp"

layer = QgsVectorLayer(uri, "wfs_test", "WFS")
for f in layer.getFeatures():
    print(f)
print(layer.isValid())

# app.exitQgis()

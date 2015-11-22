prefix = "'"
layer = iface.activeLayer()
attr = layer.rendererV2().classAttribute()
attrColor = 'color' # Name of the field to store colors
fieldIndex = layer.dataProvider().fieldNameIndex(attrColor)
attrFeatMap = {}

for cat in layer.rendererV2().categories(): 
  expr = "\""+attr+"\"="+prefix+unicode(cat.value())+prefix
  for f in layer.getFeatures(QgsFeatureRequest(QgsExpression(expr))):
    attrMap = { fieldIndex : cat.symbol().color().name()}
    attrFeatMap[ f.id() ] = attrMap

layer.dataProvider().changeAttributeValues( attrFeatMap )
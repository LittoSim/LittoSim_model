<!DOCTYPE qgis PUBLIC 'http://mrcc.com/qgis.dtd' 'SYSTEM'>
<qgis maxScale="0" version="3.16.6-Hannover" hasScaleBasedVisibilityFlag="0" minScale="1e+08" styleCategories="AllStyleCategories">
  <flags>
    <Identifiable>1</Identifiable>
    <Removable>1</Removable>
    <Searchable>1</Searchable>
  </flags>
  <temporal mode="0" enabled="0" fetchMode="0">
    <fixedRange>
      <start></start>
      <end></end>
    </fixedRange>
  </temporal>
  <customproperties>
    <property key="WMSBackgroundLayer" value="false"/>
    <property key="WMSPublishDataSourceUrl" value="false"/>
    <property key="embeddedWidgets/count" value="0"/>
    <property key="identify/format" value="Value"/>
  </customproperties>
  <pipe>
    <provider>
      <resampling zoomedInResamplingMethod="nearestNeighbour" enabled="false" maxOversampling="2" zoomedOutResamplingMethod="nearestNeighbour"/>
    </provider>
    <rasterrenderer classificationMin="0" opacity="1" classificationMax="17" nodataColor="" band="1" alphaBand="-1" type="singlebandpseudocolor">
      <rasterTransparency/>
      <minMaxOrigin>
        <limits>None</limits>
        <extent>WholeRaster</extent>
        <statAccuracy>Estimated</statAccuracy>
        <cumulativeCutLower>0.02</cumulativeCutLower>
        <cumulativeCutUpper>0.98</cumulativeCutUpper>
        <stdDevFactor>2</stdDevFactor>
      </minMaxOrigin>
      <rastershader>
        <colorrampshader colorRampType="INTERPOLATED" clip="0" labelPrecision="6" minimumValue="0" maximumValue="17" classificationMode="1">
          <colorramp name="[source]" type="gradient">
            <prop k="color1" v="27,24,215,255"/>
            <prop k="color2" v="186,119,43,255"/>
            <prop k="discrete" v="0"/>
            <prop k="rampType" v="gradient"/>
            <prop k="stops" v="0.0360577;255,255,191,255:0.205529;229,232,137,255:0.609375;253,174,97,255"/>
          </colorramp>
          <item alpha="255" color="#1818d7" label="&lt;0" value="0"/>
          <item alpha="255" color="#ffffd4" label="0" value="0"/>
          <item alpha="255" color="#e3d1a3" label="1" value="1"/>
          <item alpha="255" color="#ebb36e" label="3" value="3"/>
          <item alpha="255" color="#ba772b" label="5" value="5"/>
          <item alpha="255" color="#845a00" label="8" value="8"/>
          <item alpha="255" color="#5e4000" label="12" value="12"/>
          <item alpha="255" color="#4a3200" label="17" value="17"/>
        </colorrampshader>
      </rastershader>
    </rasterrenderer>
    <brightnesscontrast gamma="1" brightness="0" contrast="0"/>
    <huesaturation saturation="0" colorizeOn="0" colorizeGreen="128" colorizeStrength="100" colorizeRed="255" colorizeBlue="128" grayscaleMode="0"/>
    <rasterresampler maxOversampling="2"/>
    <resamplingStage>resamplingFilter</resamplingStage>
  </pipe>
  <blendMode>0</blendMode>
</qgis>

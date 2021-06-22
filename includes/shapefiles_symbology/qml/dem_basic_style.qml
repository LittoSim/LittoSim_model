<!DOCTYPE qgis PUBLIC 'http://mrcc.com/qgis.dtd' 'SYSTEM'>
<qgis minScale="1e+08" version="3.10.4-A Coruña" maxScale="0" styleCategories="AllStyleCategories" hasScaleBasedVisibilityFlag="0">
  <flags>
    <Identifiable>1</Identifiable>
    <Removable>1</Removable>
    <Searchable>1</Searchable>
  </flags>
  <customproperties>
    <property value="false" key="WMSBackgroundLayer"/>
    <property value="false" key="WMSPublishDataSourceUrl"/>
    <property value="0" key="embeddedWidgets/count"/>
    <property value="Value" key="identify/format"/>
  </customproperties>
  <pipe>
    <rasterrenderer classificationMin="0" alphaBand="-1" band="1" opacity="1" classificationMax="5" type="singlebandpseudocolor">
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
        <colorrampshader clip="0" classificationMode="1" colorRampType="INTERPOLATED">
          <colorramp name="[source]" type="gradient">
            <prop v="27,24,215,255" k="color1"/>
            <prop v="186,119,43,255" k="color2"/>
            <prop v="0" k="discrete"/>
            <prop v="gradient" k="rampType"/>
            <prop v="0.0360577;255,255,191,255:0.205529;229,232,137,255:0.609375;253,174,97,255" k="stops"/>
          </colorramp>
          <item value="0" alpha="255" color="#1818d7" label="&lt;0"/>
          <item value="0" alpha="255" color="#ffffd4" label="0"/>
          <item value="1" alpha="255" color="#e3d1a3" label="1"/>
          <item value="3" alpha="255" color="#ebb36e" label="3"/>
          <item value="5" alpha="255" color="#ba772b" label="5"/>
        </colorrampshader>
      </rastershader>
    </rasterrenderer>
    <brightnesscontrast contrast="0" brightness="0"/>
    <huesaturation colorizeBlue="128" grayscaleMode="0" colorizeGreen="128" colorizeStrength="100" saturation="0" colorizeOn="0" colorizeRed="255"/>
    <rasterresampler maxOversampling="2"/>
  </pipe>
  <blendMode>0</blendMode>
</qgis>

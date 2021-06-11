<!DOCTYPE qgis PUBLIC 'http://mrcc.com/qgis.dtd' 'SYSTEM'>
<qgis styleCategories="AllStyleCategories" maxScale="0" hasScaleBasedVisibilityFlag="1" version="3.10.2-A Coruña" minScale="1e+08">
  <flags>
    <Identifiable>1</Identifiable>
    <Removable>1</Removable>
    <Searchable>1</Searchable>
  </flags>
  <customproperties>
    <property key="WMSBackgroundLayer" value="false"/>
    <property key="WMSPublishDataSourceUrl" value="false"/>
    <property key="embeddedWidgets/count" value="0"/>
    <property key="identify/format" value="Value"/>
  </customproperties>
  <pipe>
    <rasterrenderer opacity="1" classificationMin="-10" classificationMax="inf" band="1" alphaBand="-1" type="singlebandpseudocolor">
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
        <colorrampshader classificationMode="3" colorRampType="DISCRETE" clip="0">
          <colorramp type="gradient" name="[source]">
            <prop v="27,24,215,255" k="color1"/>
            <prop v="186,119,43,255" k="color2"/>
            <prop v="0" k="discrete"/>
            <prop v="gradient" k="rampType"/>
            <prop v="0.0360577;255,255,191,255:0.205529;229,232,137,255:0.609375;253,174,97,255" k="stops"/>
          </colorramp>
          <item color="#1407c9" label="&lt;= -10" alpha="255" value="-10"/>
          <item color="#2f24d5" label="-10 - -6.738963" alpha="255" value="-5"/>
          <item color="#534ad5" label="-6.738963 - -2.519391" alpha="255" value="-2"/>
          <item color="#6e65d5" label="-2 - 0" alpha="255" value="0"/>
          <item color="#ffffd4" label="0 - 10" alpha="255" value="10"/>
          <item color="#fed98e" label="10 - 17" alpha="255" value="17"/>
          <item color="#fe9929" label="17 - 26" alpha="255" value="26"/>
          <item color="#d95f0e" label="> 26" alpha="255" value="inf"/>
        </colorrampshader>
      </rastershader>
    </rasterrenderer>
    <brightnesscontrast contrast="0" brightness="0"/>
    <huesaturation colorizeBlue="128" colorizeGreen="128" grayscaleMode="0" colorizeOn="0" colorizeRed="255" colorizeStrength="100" saturation="0"/>
    <rasterresampler maxOversampling="2"/>
  </pipe>
  <blendMode>0</blendMode>
</qgis>

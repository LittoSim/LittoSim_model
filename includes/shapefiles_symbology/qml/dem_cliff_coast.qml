<!DOCTYPE qgis PUBLIC 'http://mrcc.com/qgis.dtd' 'SYSTEM'>
<qgis styleCategories="AllStyleCategories" maxScale="0" hasScaleBasedVisibilityFlag="0" version="3.10.2-A Coruña" minScale="1e+08">
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
    <rasterrenderer opacity="1" classificationMin="-8.96945" classificationMax="121" band="1" alphaBand="-1" type="singlebandpseudocolor">
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
            <prop v="8,48,107,255" k="color1"/>
            <prop v="247,251,255,255" k="color2"/>
            <prop v="0" k="discrete"/>
            <prop v="gradient" k="rampType"/>
            <prop v="0.1;8,81,156,255:0.22;33,113,181,255:0.35;66,146,198,255:0.48;107,174,214,255:0.61;158,202,225,255:0.74;198,219,239,255:0.87;222,235,247,255" k="stops"/>
          </colorramp>
          <item color="#0a1f8b" label="&lt;= -8.969448385239" alpha="255" value="-8.969448385239"/>
          <item color="#105ca5" label="-8.969448385239 - -6.36942152023353" alpha="255" value="-6.36942152023353"/>
          <item color="#1d63bd" label="-6.36942152023353 - 0" alpha="255" value="0"/>
          <item color="#ffffd4" label="0 - 24" alpha="255" value="24"/>
          <item color="#fed98e" label="24 - 48" alpha="255" value="48"/>
          <item color="#fe9929" label="48 - 73" alpha="255" value="73"/>
          <item color="#d95f0e" label="73 - 100" alpha="255" value="100"/>
          <item color="#993404" label="73-121" alpha="255" value="121"/>
        </colorrampshader>
      </rastershader>
    </rasterrenderer>
    <brightnesscontrast contrast="0" brightness="0"/>
    <huesaturation colorizeBlue="128" colorizeGreen="128" grayscaleMode="0" colorizeOn="0" colorizeRed="255" colorizeStrength="100" saturation="0"/>
    <rasterresampler maxOversampling="2"/>
  </pipe>
  <blendMode>0</blendMode>
</qgis>

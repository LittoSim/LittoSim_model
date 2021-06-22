<!DOCTYPE qgis PUBLIC 'http://mrcc.com/qgis.dtd' 'SYSTEM'>
<qgis hasScaleBasedVisibilityFlag="0" maxScale="0" styleCategories="AllStyleCategories" minScale="1e+08" version="3.10.2-A Coruña">
  <flags>
    <Identifiable>1</Identifiable>
    <Removable>1</Removable>
    <Searchable>1</Searchable>
  </flags>
  <customproperties>
    <property value="Value" key="identify/format"/>
  </customproperties>
  <pipe>
    <rasterrenderer opacity="1" alphaBand="-1" classificationMin="-16.233" band="1" type="singlebandpseudocolor" classificationMax="10">
      <minMaxOrigin>
        <limits>None</limits>
        <extent>WholeRaster</extent>
        <statAccuracy>Estimated</statAccuracy>
        <cumulativeCutLower>0.02</cumulativeCutLower>
        <cumulativeCutUpper>0.98</cumulativeCutUpper>
        <stdDevFactor>2</stdDevFactor>
      </minMaxOrigin>
      <rastershader>
        <colorrampshader classificationMode="1" colorRampType="DISCRETE" clip="0">
          <colorramp name="[source]" type="preset">
            <prop v="0,38,114,255" k="preset_color_0"/>
            <prop v="0,38,114,255" k="preset_color_1"/>
            <prop v="242,135,59,255" k="preset_color_10"/>
            <prop v="0,38,114,255" k="preset_color_2"/>
            <prop v="0,44,125,255" k="preset_color_3"/>
            <prop v="0,59,146,255" k="preset_color_4"/>
            <prop v="0,75,168,255" k="preset_color_5"/>
            <prop v="0,89,202,255" k="preset_color_6"/>
            <prop v="0,169,230,255" k="preset_color_7"/>
            <prop v="255,255,190,255" k="preset_color_8"/>
            <prop v="255,211,127,255" k="preset_color_9"/>
            <prop v="#002672" k="preset_color_name_0"/>
            <prop v="#002672" k="preset_color_name_1"/>
            <prop v="#f2873b" k="preset_color_name_10"/>
            <prop v="#002672" k="preset_color_name_2"/>
            <prop v="#002c7d" k="preset_color_name_3"/>
            <prop v="#003b92" k="preset_color_name_4"/>
            <prop v="#004ba8" k="preset_color_name_5"/>
            <prop v="#0059ca" k="preset_color_name_6"/>
            <prop v="#00a9e6" k="preset_color_name_7"/>
            <prop v="#ffffbe" k="preset_color_name_8"/>
            <prop v="#ffd37f" k="preset_color_name_9"/>
            <prop v="preset" k="rampType"/>
          </colorramp>
          <item color="#002672" label="≤ -16,138296" value="-16.138295831232725" alpha="255"/>
          <item color="#002672" label="≤ -10" value="-10" alpha="255"/>
          <item color="#002672" label="≤ -8" value="-8" alpha="255"/>
          <item color="#002c7d" label="≤ -6" value="-6" alpha="255"/>
          <item color="#003b92" label="≤ -4" value="-4" alpha="255"/>
          <item color="#004ba8" label="≤ -2" value="-2" alpha="255"/>
          <item color="#0059ca" label="≤ -1" value="-1" alpha="255"/>
          <item color="#00a9e6" label="≤ 0" value="0" alpha="255"/>
          <item color="#ffffbe" label="≤ 4" value="4" alpha="255"/>
          <item color="#ffd37f" label="≤ 7" value="7" alpha="255"/>
          <item color="#f2873b" label="≤10" value="10" alpha="255"/>
        </colorrampshader>
      </rastershader>
    </rasterrenderer>
    <brightnesscontrast brightness="0" contrast="0"/>
    <huesaturation colorizeRed="255" colorizeStrength="100" colorizeGreen="128" grayscaleMode="0" colorizeBlue="128" saturation="0" colorizeOn="0"/>
    <rasterresampler maxOversampling="2"/>
  </pipe>
  <blendMode>0</blendMode>
</qgis>

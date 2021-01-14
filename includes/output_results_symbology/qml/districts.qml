<!DOCTYPE qgis PUBLIC 'http://mrcc.com/qgis.dtd' 'SYSTEM'>
<qgis styleCategories="AllStyleCategories" readOnly="0" simplifyLocal="1" maxScale="0" simplifyMaxScale="1" simplifyDrawingHints="1" hasScaleBasedVisibilityFlag="0" simplifyAlgorithm="0" labelsEnabled="0" version="3.10.2-A Coruña" simplifyDrawingTol="1" minScale="1e+08">
  <flags>
    <Identifiable>1</Identifiable>
    <Removable>1</Removable>
    <Searchable>1</Searchable>
  </flags>
  <renderer-v2 forceraster="0" symbollevels="0" enableorderby="0" type="singleSymbol">
    <symbols>
      <symbol force_rhr="0" clip_to_extent="1" alpha="1" type="fill" name="0">
        <layer locked="0" enabled="1" pass="0" class="SimpleFill">
          <prop v="3x:0,0,0,0,0,0" k="border_width_map_unit_scale"/>
          <prop v="255,255,255,64" k="color"/>
          <prop v="bevel" k="joinstyle"/>
          <prop v="0,0" k="offset"/>
          <prop v="3x:0,0,0,0,0,0" k="offset_map_unit_scale"/>
          <prop v="MM" k="offset_unit"/>
          <prop v="0,0,0,255" k="outline_color"/>
          <prop v="solid" k="outline_style"/>
          <prop v="0.26" k="outline_width"/>
          <prop v="MM" k="outline_width_unit"/>
          <prop v="solid" k="style"/>
          <data_defined_properties>
            <Option type="Map">
              <Option value="" type="QString" name="name"/>
              <Option name="properties"/>
              <Option value="collection" type="QString" name="type"/>
            </Option>
          </data_defined_properties>
        </layer>
      </symbol>
    </symbols>
    <rotation/>
    <sizescale/>
  </renderer-v2>
  <customproperties>
    <property key="embeddedWidgets/count" value="0"/>
    <property key="variableNames"/>
    <property key="variableValues"/>
  </customproperties>
  <blendMode>0</blendMode>
  <featureBlendMode>0</featureBlendMode>
  <layerOpacity>1</layerOpacity>
  <SingleCategoryDiagramRenderer diagramType="Histogram" attributeLegend="1">
    <DiagramCategory scaleDependency="Area" rotationOffset="270" lineSizeScale="3x:0,0,0,0,0,0" sizeScale="3x:0,0,0,0,0,0" backgroundColor="#ffffff" backgroundAlpha="255" barWidth="5" height="15" diagramOrientation="Up" sizeType="MM" minScaleDenominator="0" penColor="#000000" enabled="0" penWidth="0" maxScaleDenominator="1e+08" opacity="1" width="15" lineSizeType="MM" labelPlacementMethod="XHeight" minimumSize="0" penAlpha="255" scaleBasedVisibility="0">
      <fontProperties description="MS Shell Dlg 2,8.25,-1,5,50,0,0,0,0,0" style=""/>
    </DiagramCategory>
  </SingleCategoryDiagramRenderer>
  <DiagramLayerSettings linePlacementFlags="18" zIndex="0" dist="0" showAll="1" placement="1" priority="0" obstacle="0">
    <properties>
      <Option type="Map">
        <Option value="" type="QString" name="name"/>
        <Option name="properties"/>
        <Option value="collection" type="QString" name="type"/>
      </Option>
    </properties>
  </DiagramLayerSettings>
  <geometryOptions removeDuplicateNodes="0" geometryPrecision="0">
    <activeChecks/>
    <checkConfiguration type="Map">
      <Option type="Map" name="QgsGeometryGapCheck">
        <Option value="0" type="double" name="allowedGapsBuffer"/>
        <Option value="false" type="bool" name="allowedGapsEnabled"/>
        <Option value="" type="QString" name="allowedGapsLayer"/>
      </Option>
    </checkConfiguration>
  </geometryOptions>
  <fieldConfiguration>
    <field name="dist_lname">
      <editWidget type="TextEdit">
        <config>
          <Option/>
        </config>
      </editWidget>
    </field>
    <field name="dist_code">
      <editWidget type="TextEdit">
        <config>
          <Option/>
        </config>
      </editWidget>
    </field>
    <field name="dist_pop">
      <editWidget type="TextEdit">
        <config>
          <Option/>
        </config>
      </editWidget>
    </field>
    <field name="dist_sname">
      <editWidget type="TextEdit">
        <config>
          <Option/>
        </config>
      </editWidget>
    </field>
    <field name="player_id">
      <editWidget type="Range">
        <config>
          <Option/>
        </config>
      </editWidget>
    </field>
    <field name="ID">
      <editWidget type="Range">
        <config>
          <Option/>
        </config>
      </editWidget>
    </field>
  </fieldConfiguration>
  <aliases>
    <alias field="dist_lname" index="0" name=""/>
    <alias field="dist_code" index="1" name=""/>
    <alias field="dist_pop" index="2" name=""/>
    <alias field="dist_sname" index="3" name=""/>
    <alias field="player_id" index="4" name=""/>
    <alias field="ID" index="5" name=""/>
  </aliases>
  <excludeAttributesWMS/>
  <excludeAttributesWFS/>
  <defaults>
    <default expression="" field="dist_lname" applyOnUpdate="0"/>
    <default expression="" field="dist_code" applyOnUpdate="0"/>
    <default expression="" field="dist_pop" applyOnUpdate="0"/>
    <default expression="" field="dist_sname" applyOnUpdate="0"/>
    <default expression="" field="player_id" applyOnUpdate="0"/>
    <default expression="" field="ID" applyOnUpdate="0"/>
  </defaults>
  <constraints>
    <constraint unique_strength="0" constraints="0" exp_strength="0" field="dist_lname" notnull_strength="0"/>
    <constraint unique_strength="0" constraints="0" exp_strength="0" field="dist_code" notnull_strength="0"/>
    <constraint unique_strength="0" constraints="0" exp_strength="0" field="dist_pop" notnull_strength="0"/>
    <constraint unique_strength="0" constraints="0" exp_strength="0" field="dist_sname" notnull_strength="0"/>
    <constraint unique_strength="0" constraints="0" exp_strength="0" field="player_id" notnull_strength="0"/>
    <constraint unique_strength="0" constraints="0" exp_strength="0" field="ID" notnull_strength="0"/>
  </constraints>
  <constraintExpressions>
    <constraint exp="" desc="" field="dist_lname"/>
    <constraint exp="" desc="" field="dist_code"/>
    <constraint exp="" desc="" field="dist_pop"/>
    <constraint exp="" desc="" field="dist_sname"/>
    <constraint exp="" desc="" field="player_id"/>
    <constraint exp="" desc="" field="ID"/>
  </constraintExpressions>
  <expressionfields/>
  <attributeactions>
    <defaultAction key="Canvas" value="{00000000-0000-0000-0000-000000000000}"/>
  </attributeactions>
  <attributetableconfig sortExpression="" sortOrder="0" actionWidgetStyle="dropDown">
    <columns>
      <column width="-1" hidden="0" type="field" name="dist_lname"/>
      <column width="-1" hidden="0" type="field" name="dist_code"/>
      <column width="-1" hidden="0" type="field" name="dist_pop"/>
      <column width="-1" hidden="0" type="field" name="dist_sname"/>
      <column width="-1" hidden="0" type="field" name="player_id"/>
      <column width="-1" hidden="0" type="field" name="ID"/>
      <column width="-1" hidden="1" type="actions"/>
    </columns>
  </attributetableconfig>
  <conditionalstyles>
    <rowstyles/>
    <fieldstyles/>
  </conditionalstyles>
  <storedexpressions/>
  <editform tolerant="1"></editform>
  <editforminit/>
  <editforminitcodesource>0</editforminitcodesource>
  <editforminitfilepath></editforminitfilepath>
  <editforminitcode><![CDATA[# -*- coding: utf-8 -*-
"""
Les formulaires QGIS peuvent avoir une fonction Python qui sera appelée à l'ouverture du formulaire.

Utilisez cette fonction pour ajouter plus de fonctionnalités à vos formulaires.

Entrez le nom de la fonction dans le champ "Fonction d'initialisation Python".
Voici un exemple à suivre:
"""
from qgis.PyQt.QtWidgets import QWidget

def my_form_open(dialog, layer, feature):
    geom = feature.geometry()
    control = dialog.findChild(QWidget, "MyLineEdit")

]]></editforminitcode>
  <featformsuppress>0</featformsuppress>
  <editorlayout>generatedlayout</editorlayout>
  <editable>
    <field editable="1" name="ID"/>
    <field editable="1" name="dist_code"/>
    <field editable="1" name="dist_lname"/>
    <field editable="1" name="dist_pop"/>
    <field editable="1" name="dist_sname"/>
    <field editable="1" name="player_id"/>
  </editable>
  <labelOnTop>
    <field labelOnTop="0" name="ID"/>
    <field labelOnTop="0" name="dist_code"/>
    <field labelOnTop="0" name="dist_lname"/>
    <field labelOnTop="0" name="dist_pop"/>
    <field labelOnTop="0" name="dist_sname"/>
    <field labelOnTop="0" name="player_id"/>
  </labelOnTop>
  <widgets/>
  <previewExpression>dist_lname</previewExpression>
  <mapTip></mapTip>
  <layerGeometryType>2</layerGeometryType>
</qgis>

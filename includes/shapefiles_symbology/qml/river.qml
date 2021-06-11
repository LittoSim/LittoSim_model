<!DOCTYPE qgis PUBLIC 'http://mrcc.com/qgis.dtd' 'SYSTEM'>
<qgis styleCategories="AllStyleCategories" readOnly="0" simplifyLocal="1" maxScale="0" simplifyMaxScale="1" simplifyDrawingHints="1" hasScaleBasedVisibilityFlag="0" simplifyAlgorithm="0" labelsEnabled="0" version="3.10.2-A Coruña" simplifyDrawingTol="1" minScale="1e+08">
  <flags>
    <Identifiable>1</Identifiable>
    <Removable>1</Removable>
    <Searchable>1</Searchable>
  </flags>
  <renderer-v2 forceraster="0" symbollevels="0" enableorderby="0" type="singleSymbol">
    <symbols>
      <symbol force_rhr="0" clip_to_extent="1" alpha="1" type="line" name="0">
        <layer locked="0" enabled="1" pass="0" class="SimpleLine">
          <prop v="square" k="capstyle"/>
          <prop v="5;2" k="customdash"/>
          <prop v="3x:0,0,0,0,0,0" k="customdash_map_unit_scale"/>
          <prop v="MM" k="customdash_unit"/>
          <prop v="0" k="draw_inside_polygon"/>
          <prop v="bevel" k="joinstyle"/>
          <prop v="23,62,232,255" k="line_color"/>
          <prop v="solid" k="line_style"/>
          <prop v="0.26" k="line_width"/>
          <prop v="MM" k="line_width_unit"/>
          <prop v="0" k="offset"/>
          <prop v="3x:0,0,0,0,0,0" k="offset_map_unit_scale"/>
          <prop v="MM" k="offset_unit"/>
          <prop v="0" k="ring_filter"/>
          <prop v="0" k="use_custom_dash"/>
          <prop v="3x:0,0,0,0,0,0" k="width_map_unit_scale"/>
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
  <DiagramLayerSettings linePlacementFlags="18" zIndex="0" dist="0" showAll="1" placement="2" priority="0" obstacle="0">
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
    <checkConfiguration/>
  </geometryOptions>
  <fieldConfiguration>
    <field name="ID">
      <editWidget type="TextEdit">
        <config>
          <Option/>
        </config>
      </editWidget>
    </field>
    <field name="PREC_PLANI">
      <editWidget type="TextEdit">
        <config>
          <Option/>
        </config>
      </editWidget>
    </field>
    <field name="PREC_ALTI">
      <editWidget type="TextEdit">
        <config>
          <Option/>
        </config>
      </editWidget>
    </field>
    <field name="ARTIF">
      <editWidget type="TextEdit">
        <config>
          <Option/>
        </config>
      </editWidget>
    </field>
    <field name="FICTIF">
      <editWidget type="TextEdit">
        <config>
          <Option/>
        </config>
      </editWidget>
    </field>
    <field name="FRANCHISST">
      <editWidget type="TextEdit">
        <config>
          <Option/>
        </config>
      </editWidget>
    </field>
    <field name="NOM">
      <editWidget type="TextEdit">
        <config>
          <Option/>
        </config>
      </editWidget>
    </field>
    <field name="POS_SOL">
      <editWidget type="Range">
        <config>
          <Option/>
        </config>
      </editWidget>
    </field>
    <field name="REGIME">
      <editWidget type="TextEdit">
        <config>
          <Option/>
        </config>
      </editWidget>
    </field>
    <field name="Z_INI">
      <editWidget type="TextEdit">
        <config>
          <Option/>
        </config>
      </editWidget>
    </field>
    <field name="Z_FIN">
      <editWidget type="TextEdit">
        <config>
          <Option/>
        </config>
      </editWidget>
    </field>
    <field name="Shape_Leng">
      <editWidget type="TextEdit">
        <config>
          <Option/>
        </config>
      </editWidget>
    </field>
  </fieldConfiguration>
  <aliases>
    <alias field="ID" index="0" name=""/>
    <alias field="PREC_PLANI" index="1" name=""/>
    <alias field="PREC_ALTI" index="2" name=""/>
    <alias field="ARTIF" index="3" name=""/>
    <alias field="FICTIF" index="4" name=""/>
    <alias field="FRANCHISST" index="5" name=""/>
    <alias field="NOM" index="6" name=""/>
    <alias field="POS_SOL" index="7" name=""/>
    <alias field="REGIME" index="8" name=""/>
    <alias field="Z_INI" index="9" name=""/>
    <alias field="Z_FIN" index="10" name=""/>
    <alias field="Shape_Leng" index="11" name=""/>
  </aliases>
  <excludeAttributesWMS/>
  <excludeAttributesWFS/>
  <defaults>
    <default expression="" field="ID" applyOnUpdate="0"/>
    <default expression="" field="PREC_PLANI" applyOnUpdate="0"/>
    <default expression="" field="PREC_ALTI" applyOnUpdate="0"/>
    <default expression="" field="ARTIF" applyOnUpdate="0"/>
    <default expression="" field="FICTIF" applyOnUpdate="0"/>
    <default expression="" field="FRANCHISST" applyOnUpdate="0"/>
    <default expression="" field="NOM" applyOnUpdate="0"/>
    <default expression="" field="POS_SOL" applyOnUpdate="0"/>
    <default expression="" field="REGIME" applyOnUpdate="0"/>
    <default expression="" field="Z_INI" applyOnUpdate="0"/>
    <default expression="" field="Z_FIN" applyOnUpdate="0"/>
    <default expression="" field="Shape_Leng" applyOnUpdate="0"/>
  </defaults>
  <constraints>
    <constraint unique_strength="0" constraints="0" exp_strength="0" field="ID" notnull_strength="0"/>
    <constraint unique_strength="0" constraints="0" exp_strength="0" field="PREC_PLANI" notnull_strength="0"/>
    <constraint unique_strength="0" constraints="0" exp_strength="0" field="PREC_ALTI" notnull_strength="0"/>
    <constraint unique_strength="0" constraints="0" exp_strength="0" field="ARTIF" notnull_strength="0"/>
    <constraint unique_strength="0" constraints="0" exp_strength="0" field="FICTIF" notnull_strength="0"/>
    <constraint unique_strength="0" constraints="0" exp_strength="0" field="FRANCHISST" notnull_strength="0"/>
    <constraint unique_strength="0" constraints="0" exp_strength="0" field="NOM" notnull_strength="0"/>
    <constraint unique_strength="0" constraints="0" exp_strength="0" field="POS_SOL" notnull_strength="0"/>
    <constraint unique_strength="0" constraints="0" exp_strength="0" field="REGIME" notnull_strength="0"/>
    <constraint unique_strength="0" constraints="0" exp_strength="0" field="Z_INI" notnull_strength="0"/>
    <constraint unique_strength="0" constraints="0" exp_strength="0" field="Z_FIN" notnull_strength="0"/>
    <constraint unique_strength="0" constraints="0" exp_strength="0" field="Shape_Leng" notnull_strength="0"/>
  </constraints>
  <constraintExpressions>
    <constraint exp="" desc="" field="ID"/>
    <constraint exp="" desc="" field="PREC_PLANI"/>
    <constraint exp="" desc="" field="PREC_ALTI"/>
    <constraint exp="" desc="" field="ARTIF"/>
    <constraint exp="" desc="" field="FICTIF"/>
    <constraint exp="" desc="" field="FRANCHISST"/>
    <constraint exp="" desc="" field="NOM"/>
    <constraint exp="" desc="" field="POS_SOL"/>
    <constraint exp="" desc="" field="REGIME"/>
    <constraint exp="" desc="" field="Z_INI"/>
    <constraint exp="" desc="" field="Z_FIN"/>
    <constraint exp="" desc="" field="Shape_Leng"/>
  </constraintExpressions>
  <expressionfields/>
  <attributeactions>
    <defaultAction key="Canvas" value="{00000000-0000-0000-0000-000000000000}"/>
  </attributeactions>
  <attributetableconfig sortExpression="" sortOrder="0" actionWidgetStyle="dropDown">
    <columns>
      <column width="-1" hidden="0" type="field" name="ID"/>
      <column width="-1" hidden="0" type="field" name="PREC_PLANI"/>
      <column width="-1" hidden="0" type="field" name="PREC_ALTI"/>
      <column width="-1" hidden="0" type="field" name="ARTIF"/>
      <column width="-1" hidden="0" type="field" name="FICTIF"/>
      <column width="-1" hidden="0" type="field" name="FRANCHISST"/>
      <column width="-1" hidden="0" type="field" name="NOM"/>
      <column width="-1" hidden="0" type="field" name="POS_SOL"/>
      <column width="-1" hidden="0" type="field" name="REGIME"/>
      <column width="-1" hidden="0" type="field" name="Z_INI"/>
      <column width="-1" hidden="0" type="field" name="Z_FIN"/>
      <column width="-1" hidden="0" type="field" name="Shape_Leng"/>
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
    <field editable="1" name="ARTIF"/>
    <field editable="1" name="FICTIF"/>
    <field editable="1" name="FRANCHISST"/>
    <field editable="1" name="ID"/>
    <field editable="1" name="NOM"/>
    <field editable="1" name="POS_SOL"/>
    <field editable="1" name="PREC_ALTI"/>
    <field editable="1" name="PREC_PLANI"/>
    <field editable="1" name="REGIME"/>
    <field editable="1" name="Shape_Leng"/>
    <field editable="1" name="Z_FIN"/>
    <field editable="1" name="Z_INI"/>
  </editable>
  <labelOnTop>
    <field labelOnTop="0" name="ARTIF"/>
    <field labelOnTop="0" name="FICTIF"/>
    <field labelOnTop="0" name="FRANCHISST"/>
    <field labelOnTop="0" name="ID"/>
    <field labelOnTop="0" name="NOM"/>
    <field labelOnTop="0" name="POS_SOL"/>
    <field labelOnTop="0" name="PREC_ALTI"/>
    <field labelOnTop="0" name="PREC_PLANI"/>
    <field labelOnTop="0" name="REGIME"/>
    <field labelOnTop="0" name="Shape_Leng"/>
    <field labelOnTop="0" name="Z_FIN"/>
    <field labelOnTop="0" name="Z_INI"/>
  </labelOnTop>
  <widgets/>
  <previewExpression>NOM</previewExpression>
  <mapTip></mapTip>
  <layerGeometryType>1</layerGeometryType>
</qgis>

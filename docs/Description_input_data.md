**Description of input data**

All the data created have the same coordinate reference system. The vector files will be in shapefiles format and the grids in ASCII format.

The input data necessary for LittoSIM is of several types :



**I – Raw data**

  *1.1. – Essential data*

- The administrative boundaries of the study area

_type polygon, with a feature code (i.e : insee code)_

_Necessary attribute : id (integer), code (string, i.e : insee code), name\_district (, population (interger,_ number of inhabitants)_, shape\_area (m²)_

_Example source :_ [_https://www.data.gouv.fr/fr/_](https://www.data.gouv.fr/fr/)

- The linear of the coastal\_defenses (dikes and dunes).

_type polyline. The entities will be divided by the district boundary._

_Necessary attribute : type (dike or dune), dist\_code (i.e : insee code), statut (good, medium, bad), altitude, height_

- Urban plan which corresponds to rules urban planning,

_type polygon_

_Necessary attribute : code (urban type)_

_Example source:_ the local urban plan (PLU: Plan Local d&#39;Urbanisme) specifying the town planning

- Buildings, only buildings for residential use,

_type polygon_

_Necessary attribute : type, shape\_area (m²)_

_Example source: the OpenStreetMap opendata files_ [_http://download.geofabrik.de/_](http://download.geofabrik.de/)

- The environnemental protected areas

_type polygon_

_Example source :  [Birds Directive (Special Protection Areas or SPAs)](http://ec.europa.eu/environment/nature/legislation/birdsdirective/index_en.htm) and the [Habitats Directive (Sites of Community Importance or SCIs, and Special Areas of Conservation or SACs)](http://ec.europa.eu/environment/nature/legislation/habitatsdirective/index_en.htm)._ _-_ [_European database Natura 2000_](https://www.eea.europa.eu/data-and-maps/data/natura-11)

- Floodable areas defined in a develppement plan

_type polygon_

_Example source :_ _risk prevention plan_

  1.2. – Display data (optional)

Rivers representing principal rivers, t_ype polyline or polygon_

Roads representing principal roads, t_ype polyline or polygon_

Coastline representing the coast, t_ype polyline or polygon_

Theses are the shapefiles to improve the understanding of the map.


**II –**  **Data to be pre-processed**

2.1 – Study area / bounding box

First, a rectangular enveloping of the study area must be defined, including the topographic part (the 4 communes played) and the bathymetric part.

This boundingbox will be composed of a simple shapefile, of polygon type and defined with acoordinate reference system, for example, in Lambert 93 (epsg 2154, for metropolitan France). It will be used to clip or to generate DEM and grid rugosity.

2.2. - DEM

LittoSIM requires an altimetry database as input a Digital Elevation Model (DEM) including a geographic continuum between the topographic part and the bathymetric part. This DEM will be a type ASCII, with 20 m resolution. This resolution is suitable for a study area less than or equal to 100 km², beyond the Lisflood calculation times are considered too long.

The type of coast implies the choice of the resolution of the bathymetry and the spatial extent.

If this database is not available in the study area (example Litto3D® IGN), it&#39;s possible to generate it, by merging the topographic and bathymetric part and by defining the same altimetric system (example in metropolitan France: NGF/IGN69, which is the &quot;zero level&quot; of reference in France and determined by the Marseille tide gauge).
Note that the quality of the input data will strongly influence the results of the submersion simulations.

Two Gama scripts ([LittoSIM\_modele/scripts/pre\_processing/](https://github.com/LittoSim/LittoSim_model/tree/LittoDev/scripts/pre_processing)DEM\_Baty.gaml and rugosity.gaml) and the document &#39;Generate\_DEM\_rugosity\_grid&#39; ([LittoSim\_model/docs](https://github.com/LittoSim/LittoSim_model/tree/LittoDev/docs)/) presents data processing to create the DEM and rugosity grid.

2.3. – Land cover/ Rugosity

Like the DEM, a roughness grid is essential for the LisFlood model. This grid will have the same bounding geometry (same row and columns), the same coordinate reference system and the same resolution as DEM.

This grid can be generated from the land use vector layer, like _European Corine Land Cover (CLC) :_ [_https://land.copernicus.eu/pan-european/corine-land-cover_](https://land.copernicus.eu/pan-european/corine-land-cover)


**III –**  **The data processed and ready to be used in**  **LittoSIM**

The data described in the first two parts will be stored in a folder, which will be named &#39;input&#39;.

The files &#39;mapping.xml&#39; and the script R &#39;data_compiler.R&#39 (LittoSim_model/scripts/pre_processing/); allow to generate and format data, in order to make them conform to LittoSIM.

The script allows several types of processing : creates new spatial objects, aggregate attributes, replace values, rename files, coordinate reference system ….

The generated will be automatically stored in a folder &#39;output&#39; :

3.1. - Shapefiles

- Buffer\_in\_100m
- Buildings
- Coastal\_defenses
- Coastline
- convex\_hull
- Districts
- Land\_cover
- land\_use
- roads
- rpp
- spa
- Urban\_plan
- water


3.2. - files .asc

- dem.asc (topographic and bathymetric grid merged)
- rugosity.asc (math code CLC with Manning rugosity coefficents)
- start.asc # empty grid

**IV –Lisflood parameter**

The two configuration files .bci and .bdy are text format. The grid exchange between the LittoSIM (GAMA platform) and model LISFLOOD that calculates the flood propagation based on theses files :

- .bci : geographical boundaries of the domain contains landmarks with their coordinates
- .bdy : a time series of the water elevation scenario. It defines water elevations for several landmarks (geographical boundaries) over the study area.

_LittoSIM_

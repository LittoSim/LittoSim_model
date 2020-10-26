**Generate DEM and rugosity grid**

This document presents GIS geoprocessing to create the DEM and rugosity grid.

Two Gama scripts can automatically generate a DEM (land-sea continuum) and a rugosity grid : DEM\_Baty.gaml ; rugosity.gaml ([LittoSIM\_modele/scripts/pre\_processing/](https://github.com/LittoSim/LittoSim_model/tree/LittoDev/scripts/pre_processing)).

**1 . DEM**

Here is presented a case where the bathymetric zone is available in the form of measurement points and the topographic zone a grid.

- Clip the grid from the file Study area / bounding box
- Resample this topographic grid with a 20m step
- From bathymetric points, choose a method interpolation (eg : IDW), with the BoundingBox like Extend in the environment setting. This grid will have the same bounding geometry (same row and columns), the same coordinate reference system and the same resolution as DEM.
- Recalculate the grid to convert bathymetric values to NGF values (0 NFG is below average the mean sea level). Example, 0 NGF is about 0.42 m lower than the MSL on the island of Aix).
- Create a mask with the bathymetric grid (no bathy=NoData)
- Extraction the interpolation with the mask
- Calculate a grid DEM with an expression using Python syntax : _Con(IsNull(&quot;bathy&quot;), &quot;topo&quot;,&quot;bathy&quot;)_
- Export to format .ascii. The decimal values expressed by a point.

**2. Grid Rugosity**

- Clip the vector files CORINE Land Cover (CLC) from the file Study area / bounding box
- Create a field named &#39;code&#39; , type integer to collect the codes of the level nomenclature 3 (e.g; 313 Mixed forest).
- Convert polygon to raster with the field &#39;code&#39;, with the same resolution as the DEM (20m).
- Export to format .ascii. The decimal values expressed by a point.

The two grids must be have the same bounding geometry (same row and columns), the same coordinate reference system and the same resolution.

_LittoSIM_
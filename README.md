# File structure

```
LittoSIM-GEN
  ├── images
  │     ├── icons
  │     │    └── *.png
  │     └── ihm
  │          └── *.png
  ├── includes
  │     ├── config
  │     │     ├── langs.conf
  │     │     └── littosim.com
  │     ├── cliff_coast
  │     │     ├── floodfiles
  │     │     │     ├── inputs
  │     │     │     │     ├── cliff_coast_dem_RN_tX.XXXXXXXXXXXX.asc
  │     │     │     │     ├── cliff_coast_rug_RN_tX.XXXXXXXXXXXX.asc
  │     │     │     │     └── cliff_coast_par_RN_tX.XXXXXXXXXXXX.par
  │     │     │     ├── results
  │     │     │     │     ├── res.dem
  │     │     │     │     ├── res.max
  │     │     │     │     ├── res.mass
  │     │     │     │     ├── res-00**.wd
  │     │     │     │     ├── res-00**.wdfp
  │     │     │     │     ├── ruptures.txt
  │     │     │     │     └── submersion_type.txt
  │     │     │     ├── results_RN_tX.XXXXXXXXXXXX
  │     │     │     ├── cliff_coast.bci
  │     │     │     ├── cliff_coast.bdy
  │     │     │     ├── cliff_coast.param
  │     │     │     ├── cliff_coast.start
  │     │     │     ├── cliff_coast+24cm.bdy
  │     │     │     └── cliff_coast+80cm.bdy
  │     │     ├── shapefiles
  │     │     │     ├── *.shp
  │     │     │     └── *.asc
  │     │     ├── actions.conf
  │     │     ├── levers.conf
  │     │     └── study_area.conf
  │     ├── esturay_coast
  │     ├── overflow_coast_h
  │     └── overflow_coast_v
  └── models
        ├── params_models
        │     ├── params_all.gaml
        │     ├── params_leader.gaml
        │     ├── params_manager.gaml
        │     └── params_player.gaml
        ├── LittoSIM-GEN_Leader.gaml
        ├── LittoSIM-GEN_Manager.gaml
        └── LittoSIM-GEN_Player.gaml
```

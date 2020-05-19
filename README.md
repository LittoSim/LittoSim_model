# LittoSIM-GEN

## File structure

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
  │     │     │     │     ├── cliff_coast_dem_RN_tX.xxxxxxxxxxxxx.asc
  │     │     │     │     ├── cliff_coast_rug_RN_tX.xxxxxxxxxxxxx.asc
  │     │     │     │     └── cliff_coast_par_RN_tX.xxxxxxxxxxxxx.par
  │     │     │     ├── results
  │     │     │     │     ├── res.dem
  │     │     │     │     ├── res.max
  │     │     │     │     ├── res.mass
  │     │     │     │     ├── res-00[00-14].wd
  │     │     │     │     ├── res-00[00-14].wdfp
  │     │     │     │     ├── ruptures.txt
  │     │     │     │     └── submersion_type.txt
  │     │     │     ├── results_RN_tX.xxxxxxxxxxxxx
  │     │     │     ├── cliff_coast.bci
  │     │     │     ├── cliff_coast.bdy
  │     │     │     ├── cliff_coast.param
  │     │     │     ├── cliff_coast.start
  │     │     │     ├── cliff_coast+24cm.bdy
  │     │     │     └── cliff_coast+80cm.bdy
  │     │     ├── leader_data-X.xxxxxxxxxxxxx
  │     │     │     ├── activated_levers_roundN.csv
  │     │     │     ├── all_levers_roundN.csv
  │     │     │     ├── leader_activities_roundN.txt
  │     │     │     └── player_actions_roundN.csv
  │     │     ├── manager_data-X.xxxxxxxxxxxxx
  │     │     │     ├── csvs
  │     │     │     │     ├── district1.csv
  │     │     │     │     ├── district2.csv
  │     │     │     │     ├── district3.csv
  │     │     │     │     └── district4.csv
  │     │     │     ├── flood_results
  │     │     │     │     ├── flooding-X.xxxxxxxxxxxxx-RN.txt
  │     │     │     │     └── sub-RN.csv
  │     │     │     └── shapes
  │     │     │           ├── Coastal_Defense_N.shp
  │     │     │           └── Land_Use_N.shp
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
- **images** : this folder has two subdirectories that contain images related to actions (icons) and to the interface (ihm).

- **includes** : this folder contains the configuration of the model and the files of different case studies.
  - ***config*** :
    - *langs.conf* : supported languages configuration file.
    - *littosim.cong* : general settings of LittoSIM-GEN (server address, default language, paths towards study area files).
    
  - ***cliff_coast*** : study area folder of the cliff coast case study.
  
  - ***esturay_coast*** : study area folder of the estuary coast case study.
  - ***overflow_coast_h*** : study area folder of the horizontal overflow coast case study.
  - ***overflow_coast_v*** : study area folder of the vertical overflow coast case study.
  
- **models** :
  - ***params_models*** : this folder contain 4 param files englobing general parameters (params_all) and other parameters specific to each module (params_leader, params_manager, params_player).
  - ***LittoSIM-GEN_Leader*** : model file to execute the Leader.
  - ***LittoSIM-GEN_Manager*** : model file to execute the Manager.
  - ***LittoSIM-GEN_Player*** : model file to execute the Player.

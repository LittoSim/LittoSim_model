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
    - *floodfiles* :
      - `inputs` : input files generated by LittoSIM-GEN when launching a submersion event.
        - `cliff_coast_dem_RN_tX.xxxxxxxxxxxxx.asc` : the DEM file representing the current state of the territory.
        - `cliff_coast_rug_RN_tX.xxxxxxxxxxxxx.asc` : the rugosity file representing the current state of the territory.
        - `cliff_coast_par_RN_tX.xxxxxxxxxxxxx.par` : parameters file containing all necessary data to LISFLOOD.
      - `results` : this folder contain all result files related to the initial submersion (0).
        - `res-00[00-14].wd` : 14 grid files used to display the evolution of the submersion.
        - `ruptures.txt` : a text file containing IDs of coastal defenses with ruptures.
        - `submersion_type.txt` : a text file storing the submersion type (low, medium, high).
      - `results_RN_tX.xxxxxxxxxxxxx` : results folder of another submersion. Its structure is similar to "results".
      - `cliff_coast.bci` : domain boundaries file (LISFLOOD)
      - `cliff_coast*.bdyv : timeseries files representing different submersion events (LISFLOOD).
      - `cliff_coast.param` : additional parameters required to run LISFLOOD.
      - `cliff_coast.start` : an empty (0) raster grid representing the initial state of the territory.
      
    - *shapefiles* : this folder contains the shapefiles [districts, coastal defenses, ...] (.shp) and rasters [dem and rugosity] (.asc) related to the study area.
    
    - *study_area.conf* : this file contains paths towards shaepfiles and all specific parameters to the case study.
    - *actions.conf* : this file lists all actions related to the case study.
    - *levers.conf* : this file lists all levers related to the case study.

    - *leader_data-X.xxxxxxxxxxxxx* :
      - `activated_levers_roundN.csv` : for each round N, this file contains the activated levers applied on player actions.
      - `all_levers_roundN.csv` : contains all levers available during round N.
      - `leader_activities_roundN.txt` : sotres leader actions of round N (validating/canceling levers, sending messages, giving/taking money).
      - `player_actions_roundN.csv` : contains player actions excuted during round N.
    
    - *manager_data-X.xxxxxxxxxxxxx* :
      - `csvs` : contains 4 csv files, each one corresponding to a district. These files store the state of the study area at each round.
      - `flood_results` : for each flooding event, this folder will contain two files : a txt file (`flooding-X.xxxxxxxxxxxxx-RN.txt`) corresponding to textual results of the submersion of round N, and a csv file (`sub-RN.csv`) storing the same result as a csv table.
      - `shapes` : for each round N, this folder will contain two shape files representing the current state of coastal defenses and land use grid (`Coastal_Defense_N.shp` and `Land_Use_N.shp`).
  
  - ***esturay_coast*** : study area folder of the estuary coast case study.
  - ***overflow_coast_h*** : study area folder of the horizontal overflow coast case study.
  - ***overflow_coast_v*** : study area folder of the vertical overflow coast case study.
  
- **models** :
  - ***params_models*** : this folder contain 4 param files englobing general parameters (`params_all`) and other parameters specific to each module (`params_leader`, `params_manager`, `params_player`).
  - ***LittoSIM-GEN_Leader*** : model file to execute the Leader.
  - ***LittoSIM-GEN_Manager*** : model file to execute the Manager.
  - ***LittoSIM-GEN_Player*** : model file to execute the Player.

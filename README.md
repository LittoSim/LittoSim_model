# LittoSIM-GEN

This file describes the file structure of LittoSIM repository 

The repository includes 5 folders


- **docs** : this folder contains files describing the functionning of different aspects of LittoSIM
- **images** : this folder has two subdirectories that contain images related to actions (icons) and to the interface (ihm).

- **includes** : this folder contains the configuration of the model and the files of different case studies.
  - ***config*** :
    - *langs.conf* : supported languages configuration file.
    - *littosim.cong* : general settings of LittoSIM-GEN (server address, default language, paths towards study area files).
    
  - ***cliff_coast*** : study area folder of the cliff coast case study.
    - *floodfiles* : groups all files related flooding events. 
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
      
    - *shapefiles* : this folder contains the shapefiles {districts, coastal defenses, ...} (.shp) and rasters {dem and rugosity} (.asc) related to the study area.
    
    - *study_area.conf* : this file contains paths towards shaepfiles and all specific parameters to the case study.
    - *actions.conf* : this file lists all actions related to the case study.
    - *levers.conf* : this file lists all levers related to the case study.

    - *leader_data-X.xxxxxxxxxxxxx* : collected data on leader machine.
      - `activated_levers_roundN.csv` : for each round N, this file contains the activated levers applied on player actions.
      - `all_levers_roundN.csv` : contains all levers available during round N.
      - `leader_activities_roundN.txt` : sotres leader actions of round N (validating/canceling levers, sending messages, giving/taking money).
      - `player_actions_roundN.csv` : contains player actions excuted during round N.
    
    - *manager_data-X.xxxxxxxxxxxxx* : collected data on manager machine.
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

- **Rscripts** :
  - ***pre_processing*** : contains two R script files used to generate graphs based on data collected data by LittoSIM-GEN during workshops.
  	- *leader_data.R* : uses data of *leader_data-X.xxxxxxxxxxxxx* to analyse and create graphs of results.
  	- *manager_data.R*: uses data of *manager_data-X.xxxxxxxxxxxxx* to analyse and create maps and graphs of results.
  - ***post_processing*** : contains an R and XML file used to prepare input data for LittoSIM-GEN.
  	- *data_compiler.R* : this R scripts takes raw data and transforms it to the structure required by LittoSIM-GEN.
  	- *data_mapping.xml* : this XML file contains the mapping between raw data as collected from different sources, and the input data structure of LittoSIM-GEN.

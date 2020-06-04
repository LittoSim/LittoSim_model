/**
 *  LittoSIM_GEN
 *  Authors: Ahmed, Benoit, Brice, Cécilia, Elise, Etienne, Fredéric, Marion, Nicolas B, Nicolas M, Xavier 
 * 
 *  Description : LittoSIM_GEN is a participatory simulation platform implementing a serious playing-game for local authorities.
 * 				  The project aims at modeling effects of coastal flooding on urban areas and at enabling the transfer of scientific
 * 				  findings to risk managers, as well as awareness of those concerned by the risk of coastal flooding.
 * 
 * params_manager : this file contains parameters related to manager model.
 */
model paramsmanager

import "params_all.gaml"

global{
	/*
	 * Simulation states
	 */
	string SIM_NOT_STARTED 				<- 'NOT_STARTED';
	string SIM_GAME 					<- 'GAME';
	string SIM_EXEC_LISFLOOD 			<- 'EXECUTING_LISFLOOD';
	string SIM_SHOWING_LISFLOOD 		<- 'SHOWING_LISFLOOD';
	string SIM_CALCULATING_FLOOD_STATS 	<- 'CALCULATING_FLOOD_STATS';
	string SIM_SHOWING_FLOOD_STATS 		<- 'SHOWING_FLOOD_STATS';
	string INITIAL_SUBMERSION			<- '0';
	/*
	 * LISFLOOD simulation parameters
	 */
	 string lisfloodPath <- littosim_def["LISFLOOD_PATH"]; // absolute path to Lisflood ex: "C:/littosim/lisflood"
	string lisflood_bat_file 	<- "LittoSIM_GEN_Lisflood.bat";// the Lisflood executable that will be run by DOS/SH
	string my_flooding_path <- "includes/" + application_name + "/floodfiles/";
	bool IS_OSX <- bool(littosim_def["IS_OSX"]); // wether the manager is running on MAC OSX or Windows
	/*
	 * file defining additional LISFLOOD parameters (*.param in floodfiles folder)
	 */
	map<string,string> lisflood_param_def <- read_configuration_file("../../" + study_area_def["LISFLOOD_PARAMS"]);
	// four parameters of *.param file. These params differ between case studies
	int LISFLOOD_SIM_TIME 		<- int(lisflood_param_def["LISFLOOD_SIM_TIME"]);
	int LISFLOOD_INIT_TSTEP  	<- int(lisflood_param_def["LISFLOOD_INIT_TSTEP"]);
	int LISFLOOD_MASSINT		<- int(lisflood_param_def["LISFLOOD_MASSINT"]);
	int LISFLOOD_SAVEINT		<- int(lisflood_param_def["LISFLOOD_SAVEINT"]);
	/*
	 * Manager networking commands
	 */
	string NEW_ROUND 				<- "NEW_ROUND";
	string LOCK_USERS 				<- "LOCK_USERS";
	string UNLOCK_USERS 			<- "UNLOCK_USERS";
	string HIGH_FLOODING 			<- "HIGH_FLOODING";
	string MEDIUM_FLOODING 			<- "MEDIUM_FLOODING";
	string LOW_FLOODING 			<- "LOW_FLOODING";
	string REPLAY_FLOODING			<- "REPLAY_FLOODING";
	string SHOW_LU_GRID				<- "SHOW_LU_GRID";
	string SHOW_MAX_WATER_HEIGHT	<- "SHOW_MAX_WATER_HEIGHT";
	string SHOW_RUPTURE				<- "SHOW_RUPTURE";
	string ONE_STEP					<- "ONE_STEP";
	string SHOW_PREVIOUS_FLOODING	<- "SHOW_PREVIOUS_FLOODING";
	string ACTION_DISPLAY_PROTECTED_AREA <- "ACTION_DISPLAY_PROTECTED_AREA";
	string ACTION_DISPLAY_FLOODED_AREA <- "ACTION_DISPLAY_FLOODED_AREA";
	string ACTION_DISPLAY_RIVER_FLOOD <- "ACTION_DISPLAY_RIVER_FLOOD";
	/*
	 * icons of three types of flooding events
	 */
	map<string, string> flooding_icons <- [HIGH_FLOODING::"high_event.png", MEDIUM_FLOODING::"medium_event.png", LOW_FLOODING::"low_event.png"];
	/*
	 * Coastal defenses (dikes and dunes) evolution parameters
	 */
	float H_MAX_GANIVELLE 				<- float(study_area_def["H_MAX_GANIVELLE"]); 	// The maximum height added by a ganivelle
	float H_DELTA_GANIVELLE 			<- float(study_area_def["H_DELTA_GANIVELLE"]); 	// The height by which a ganivelle can raise a dune
	int STEPS_DEGRAD_STATUS_DIKE	 	<- int  (study_area_def["STEPS_DEGRADE_STATUS_DIKE"]);	// Number of years for a dike to change status
	int STEPS_DEGRAD_STATUS_DUNE 		<- int  (study_area_def["STEPS_DEGRADE_STATUS_DUNE"]); 	// Number of years for a dune to change down status
	int STEPS_REGAIN_STATUS_GANIVELLE   <- int  (study_area_def["STEPS_UPGRADE_STATUS_DUNE"]); // Number of years for a dune to change up status
	int NB_SLICES_CORD_STATUS_BAD 		<- int  (study_area_def["NB_SLICES_CORD_BAD"]); // Number of slices for a cord to become bad
	int NB_SLICES_CORD_STATUS_MEDIUM	<- int  (study_area_def["NB_SLICES_CORD_MEDIUM"]); 	// Number of slices for a cord to become medium
	int NB_SLICES_LOST_PER_ROUND		<- int  (study_area_def["NB_SLICES_LOST_PER_ROUND"]); // Number of lost slices at each round 
	int STEPS_FOR_AU_TO_U 				<- int  (study_area_def["STEPS_FOR_AU_TO_U"]);		  // Number of years to change from AU to U
	/*
	 * Coastal defenses rupture parameters
	 */
	int PROBA_RUPTURE_DIKE_STATUS_BAD 		<- int(study_area_def["PROBA_RUPTURE_DIKE_BAD"]);
	int PROBA_RUPTURE_DIKE_STATUS_MEDIUM 	<- int(study_area_def["PROBA_RUPTURE_DIKE_MEDIUM"]);
	int PROBA_RUPTURE_DIKE_STATUS_GOOD 		<- int(study_area_def["PROBA_RUPTURE_DIKE_GOOD"]); // 0 = never
	int PROBA_RUPTURE_DUNE_STATUS_BAD 		<- int(study_area_def["PROBA_RUPTURE_DUNE_BAD"]);
	int PROBA_RUPTURE_DUNE_STATUS_MEDIUM 	<- int(study_area_def["PROBA_RUPTURE_DUNE_MEDIUM"]);
	int PROBA_RUPTURE_DUNE_STATUS_GOOD 		<- int(study_area_def["PROBA_RUPTURE_DUNE_GOOD"]); 	// 0 = never
	int RADIUS_RUPTURE 						<- int(study_area_def["RADIUS_RUPTURE"]); // the extent of ruptures in #m
	/*
	 * Demographic parameters
	 */
	int POP_FOR_NEW_U 			<- int(study_area_def["POP_FOR_NEW_U"]) ; 	// initial population for cells passing from AU to U
	int POP_FOR_U_DENSIFICATION <- int(study_area_def["POP_FOR_U_DENSIFICATION"]) ; // new population for densified cells
	int POP_FOR_U_STANDARD 		<- int(study_area_def["POP_FOR_U_STANDARD"]) ; 	// new population for other cells types
	float ANNUAL_POP_GROWTH_RATE<- float(eval_gaml(study_area_def["ANNUAL_POP_GROWTH_RATE"]));
	int ANNUAL_POP_IMMIGRATION_IF_DENSIFICATION<- int(eval_gaml(study_area_def["POP_IMMIGRATION_IF_DENSIF"])); //counter population decreasing by densification (case of Dieppe-Criel)
	/*
	 * Reading manager shapes and rasters
	 */
	string dem_file 	<- "../" + study_area_def["DEM_FILE"]; // dem.asc
	string rugosity_file <- "../" + study_area_def["RUGOSITY_FILE"]; // rugosity.asc
	file buffer_in_100m_shape 	<- file("../" + study_area_def["BUFFER_IN100M_SHAPE"]);
	/*
	 * Additional shpaes for cliff_coast only
	 */
	file river_flood_shape 		<- file("../" + study_area_def["RIVER_FLOOD_SHAPE"]);
	file river_flood_shape_1m 	<- file("../" + study_area_def["RIVER_FLOOD_SHAPE_1M"]);
	/*
	 * Rugosity coefficients
	 */
	float RUGOSITY_N 	<- float(study_area_def["RUGOSITY_N"]); 	
	float RUGOSITY_U 	<- float(study_area_def["RUGOSITY_U"]);
	float RUGOSITY_AU 	<- float(study_area_def["RUGOSITY_AU"]);
	float RUGOSITY_A 	<- float(study_area_def["RUGOSITY_A"]);
	float RUGOSITY_AUs 	<- float(study_area_def["RUGOSITY_AUs"]);
	float RUGOSITY_Us 	<- float(study_area_def["RUGOSITY_Us"]);
	/*
	 * Grids and cells parameters
	 */
	int GRID_NB_COLS 	  <- int(study_area_def["GRID_NB_COLS"]);
	int GRID_NB_ROWS 	  <- int(study_area_def["GRID_NB_ROWS"]);
	int GRID_CELL_SIZE;
	float GRID_XLLCORNER;
	float GRID_YLLCORNER;
	/*
	 * Coloring the dem (flooding display)
	 */
	float land_max_height;
	float cells_max_depth;
	list<rgb> land_colors <- [rgb(255,255,212), rgb(254,217,142), rgb(254,153,41), rgb(217,95,14), rgb(153,52,4)];
	float land_color_interval;
	/* 
	 * User interface params (legends and fonts)
	 */
	int LEGEND_POSITION_X <- int(study_area_def["LEGEND_POSITION_X"]);
	int LEGEND_POSITION_Y <- int(study_area_def["LEGEND_POSITION_Y"]);
	int LEGEND_SIZE 	   <- int(study_area_def["LEGEND_SIZE"]);
	int font_size 		   <- int(shape.height/30); 	
	int font_interleave    <- int(shape.width/60);
	/*
	 * repetitive translated messages
	 */
	string MSG_SUBMERSION;
	string MSG_WATER_HEIGHTS;
	string MSG_NEW_ROUND;
	string MSG_GAME_DONE;
	string MSG_LENGTH;
	string MSG_MEAN_ALT;
	string MSG_GOOD;
	string MSG_MEDIUM;
	string MSG_BAD;
	string MSG_DENSE;
	string MSG_AREA;
	string MSG_COMMUNE;
	string MSG_POPULATION;
	string MSG_CYCLE;
	string MSG_ALL_AREAS;
	string LDR_LASTE;	
}
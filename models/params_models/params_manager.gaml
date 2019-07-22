/**
* Name: params_manager
* Author: 
*/

model paramsmanager

import "params_all.gaml"

global{
	string my_language;
	// Simulation states
	string SIM_NOT_STARTED 				<- 'NOT_STARTED';
	string SIM_GAME 					<- 'GAME';
	string SIM_EXEC_LISFLOOD 			<- 'EXECUTING_LISFLOOD';
	string SIM_SHOWING_LISFLOOD 		<- 'SHOWING_LISFLOOD';
	string SIM_CALCULATING_FLOOD_STATS 	<- 'CALCULATING_FLOOD_STATS';
	string SIM_SHOWING_FLOOD_STATS 		<- 'SHOWING_FLOOD_STATS';
	string INITIAL_SUBMERSION			<- '0';
	
	// Network round manager & commands
	string NEW_ROUND 				<- "NEW_ROUND";
	string LOCK_USERS 				<- "LOCK_USERS";
	string UNLOCK_USERS 			<- "UNLOCK_USERS";
	string HIGH_FLOODING 			<- "HIGH_FLOODING";
	string LOW_FLOODING 			<- "LOW_FLOODING";
	string REPLAY_FLOODING			<- "REPLAY_FLOODING";
	string SHOW_LU_GRID				<- "SHOW_LU_GRID";
	string SHOW_MAX_WATER_HEIGHT	<- "SHOW_MAX_WATER_HEIGHT";
	string ONE_STEP					<- "ONE_STEP";
	string SHOW_PREVIOUS_FLOODING	<- "SHOW_PREVIOUS_FLOODING";
	
	// Coastal defenses (dikes and dunes) evolution parameters
	float H_MAX_GANIVELLE 				<- float(study_area_def["H_MAX_GANIVELLE"]); 				// A dune cannot exceed this height
	float H_DELTA_GANIVELLE 			<- float(study_area_def["H_DELTA_GANIVELLE"]); 				// The height by which a ganivelle can raise a dune
	int STEPS_DEGRAD_STATUS_DIKE	 	<- int  (study_area_def["STEPS_DEGRAD_STATUS_DIKE"]);	    // Number of years for a dike to change status
	int STEPS_DEGRAD_STATUS_DUNE 		<- int  (study_area_def["STEPS_DEGRAD_STATUS_DUNE"]); 		// Number of years for a dune to change status
	int STEPS_REGAIN_STATUS_GANIVELLE   <- int  (study_area_def["STEPS_REGAIN_STATUS_GANIVELLE"]); 	// With a ganivelle, a dune regenerates 2 times fatser than it degrades
	int NB_SLICES_CORD_STATUS_BAD 		<- int  (study_area_def["NB_SLICES_CORD_STATUS_BAD"]); 		// Number of slices for a cord to become bad
	int NB_SLICES_CORD_STATUS_MEDIUM	<- int  (study_area_def["NB_SLICES_CORD_STATUS_MEDIUM"]); 	// Number of slices for a cord to become bad
	int STEPS_FOR_AU_TO_U 				<- int  (study_area_def["STEPS_FOR_AU_TO_U"]);		    	// 2 years to change from AU to U)
	
	// Coastal defenses rupture parameters
	int PROBA_RUPTURE_DIKE_STATUS_BAD 		<- int(study_area_def["PROBA_RUPTURE_DIGUE_ETAT_MAUVAIS"]);
	int PROBA_RUPTURE_DIKE_STATUS_MEDIUM 	<- int(study_area_def["PROBA_RUPTURE_DIGUE_ETAT_MOYEN"]);
	int PROBA_RUPTURE_DIKE_STATUS_GOOD 		<- int(study_area_def["PROBA_RUPTURE_DIGUE_ETAT_BON"]); 		// -1 = never
	int PROBA_RUPTURE_DUNE_STATUS_BAD 		<- int(study_area_def["PROBA_RUPTURE_DUNE_ETAT_MAUVAIS"]);
	int PROBA_RUPTURE_DUNE_STATUS_MEDIUM 	<- int(study_area_def["PROBA_RUPTURE_DUNE_ETAT_MOYEN"]);
	int PROBA_RUPTURE_DUNE_STATUS_GOOD 		<- int(study_area_def["PROBA_RUPTURE_DUNE_ETAT_BON"]); 			// -1 = never
	int RADIUS_RUPTURE 						<- int(study_area_def["RADIUS_RUPTURE"]); 						// the extent of rupture in #m

	//  Demographic parameters
	int POP_FOR_NEW_U 			<- int(study_area_def["POP_FOR_NEW_U"]) ; 						// initial population for cells passing from AU to U
	int POP_FOR_U_DENSIFICATION <- int(study_area_def["POP_FOR_U_DENSIFICATION"]) ; 			// new population for densified cells
	int POP_FOR_U_STANDARD 		<- int(study_area_def["POP_FOR_U_STANDARD"]) ; 					// new population for other cells types
	float ANNUAL_POP_GROWTH_RATE<- float(eval_gaml(study_area_def["ANNUAL_POP_GROWTH_RATE"]));
	int ANNUAL_POP_IMMIGRATION_IF_DENSIFICATION<- int(eval_gaml(study_area_def["ANNUAL_POP_IMMIGRATION_IF_DENSIFICATION"])); //counter population decreasing by densification (case of Dieppe-Criel)
	
	// Rugosity parameters
	float RUGOSITY_N 			<- float(study_area_def["RUGOSITY_N"]); 	
	float RUGOSITY_U 			<- float(study_area_def["RUGOSITY_U"]);
	float RUGOSITY_AU 			<- float(study_area_def["RUGOSITY_AU"]);
	float RUGOSITY_A 			<- float(study_area_def["RUGOSITY_A"]);
	float RUGOSITY_AUs 			<- float(study_area_def["RUGOSITY_AUs"]);
	float RUGOSITY_Us 			<- float(study_area_def["RUGOSITY_Us"]);
	string RUGOSITY_DEFAULT  	<- study_area_def["RUGOSITY_FILE"];
	
	// DEM and cells parameters
	int DEM_NB_COLS <- int(study_area_def["DEM_NB_COLS"]);
	int DEM_NB_ROWS <- int(study_area_def["DEM_NB_ROWS"]);
	int DEM_CELL_SIZE;
	float DEM_XLLCORNER;
	float DEM_YLLCORNER;

	float land_max_height;
	float cells_max_depth;
	list<rgb> land_colors <- [rgb(255,255,212), rgb(254,217,142), rgb(254,153,41), rgb(217,95,14), rgb(153,52,4)];
	float land_color_interval;
	
	float coastBorderBuffer <- float(eval_gaml(study_area_def["COAST_BORDER_BUFFER"])); 	// width of littoral area from the coast line (<400m)	
	// User interface params
	string LEGEND_POSITION <- study_area_def["LEGEND_POSITION"];
	float button_size 		<- float(configuration_file["BUTTON_SIZE"]); 				// 2000#m;
	int font_size 			<- int(shape.height/30); 	
	int font_interleave 	<- int(shape.width/60);
	
	string get_message(string code_msg){
		return langs_def at code_msg at my_language;
	}	
}
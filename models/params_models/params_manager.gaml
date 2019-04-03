/**
* Name: paramsmain
* Author: 
*/

model paramsmain

import "params_all.gaml"

global{
	
	// Simulation states
	string SIM_NOT_STARTED 				<- 'NOT_STARTED';
	string SIM_GAME 					<- 'GAME';
	string SIM_EXEC_LISFLOOD 			<- 'EXECUTING_LISFLOOD';
	string SIM_SHOWING_LISFLOOD 		<- 'SHOWING_LISFLOOD';
	string SIM_CALCULATING_FLOOD_STATS 	<- 'CALCULATING_FLOOD_STATS';
	string SIM_SHOWING_FLOOD_STATS 		<- 'SHOWING_FLOOD_STATS';
	
	// Messages to display in multi-languages
	string MSG_NEW_ROUND 			<- langs_def at 'MSG_NEW_ROUND' at configuration_file["LANGUAGE"];
	string MSG_GAME_DONE 			<- langs_def at 'MSG_GAME_DONE' at configuration_file["LANGUAGE"];
	string MSG_LOG_USER_ACTION 		<- langs_def at 'MSG_LOG_USER_ACTION' at configuration_file["LANGUAGE"];
	string MSG_CONNECT_ACTIVMQ 		<- langs_def at 'MSG_LOG_USER_ACTION' at configuration_file["LANGUAGE"];
	string MSG_NO_FLOOD_FILE_EVENT  <- langs_def at 'MSG_NO_FLOOD_FILE_EVENT' at configuration_file["LANGUAGE"];
	string MSG_OK_CONTINUE 			<- langs_def at 'MSG_OK_CONTINUE' at configuration_file["LANGUAGE"];
	string MSG_SUBMERSION_NUMBER 	<- langs_def at 'MSG_SUBMERSION_NUMBER' at configuration_file["LANGUAGE"];
	string MSG_NUMBER 				<- langs_def at 'MSG_NUMBER' at configuration_file["LANGUAGE"];
	
	// Network
	string GAME_LEADER 		        <- "GAME_LEADER";
	string UPDATE_ACTION_DONE       <- "UPDATE_ACTION_DONE";
	string OBSERVER_MESSAGE_COMMAND <- "COMMAND_OBSERVER";
	
	// pop density
	string POP_EMPTY 		  <- "EMPTY";
	string POP_FEW_DENSITY 	  <- "FEW_DENSITY";
	string POP_MEDIUM_DENSITY <- "MEDIUM_DENSITY";
	string POP_DENSE 		  <- "DENSE";	
	
	// // Building and raising dikes parameters
	float BUILT_DIKE_HEIGHT <- float(shapes_def["BUILT_DIKE_HEIGHT"]);
	float RAISE_DIKE_HEIGHT <- float(shapes_def["RAISE_DIKE_HEIGHT"]); // 1#m by default
	
	// Coastal defenses (dikes and dunes) evolution parameters
	float H_MAX_GANIVELLE 				<- float(shapes_def["H_MAX_GANIVELLE"]); // A dune cannot exceed this height
	float H_DELTA_GANIVELLE 			<- float(shapes_def["H_DELTA_GANIVELLE"]); // The height by which a ganivelle can raise a dune
	int STEPS_DEGRAD_STATUS_OUVRAGE 	<- int(shapes_def["STEPS_DEGRAD_STATUS_OUVRAGE"]); // Number of years for a dike to change status
	int STEPS_DEGRAD_STATUS_DUNE 		<-int(shapes_def["STEPS_DEGRAD_STATUS_DUNE"]); // Number of years for a dune to change status
	int STEPS_REGAIN_STATUS_GANIVELLE   <-int(shapes_def["STEPS_REGAIN_STATUS_GANIVELLE"]); // With a ganivelle, a dune regenerates 2 times fatser than it degrades

	// Coastal defenses rupture parameters
	int PROBA_RUPTURE_DIKE_STATUS_BAD 		<- int(shapes_def["PROBA_RUPTURE_DIGUE_ETAT_MAUVAIS"]);
	int PROBA_RUPTURE_DIKE_STATUS_MEDIUM 	<- int(shapes_def["PROBA_RUPTURE_DIGUE_ETAT_MOYEN"]);
	int PROBA_RUPTURE_DIKE_STATUS_GOOD 		<- int(shapes_def["PROBA_RUPTURE_DIGUE_ETAT_BON"]); // -1 = never
	int PROBA_RUPTURE_DUNE_STATUS_BAD 		<- int(shapes_def["PROBA_RUPTURE_DUNE_ETAT_MAUVAIS"]);
	int PROBA_RUPTURE_DUNE_STATUS_MEDIUM 	<- int(shapes_def["PROBA_RUPTURE_DUNE_ETAT_MOYEN"]);
	int PROBA_RUPTURE_DUNE_STATUS_GOOD 		<- int(shapes_def["PROBA_RUPTURE_DUNE_ETAT_BON"]); // -1 = never
	int RADIUS_RUPTURE 						<- int(shapes_def["RADIUS_RUPTURE"]); // the extent of rupture in #m

	//  Demographic parameters
	int POP_FOR_NEW_U 			<- int(shapes_def["POP_FOR_NEW_U"]) ; // initial population for cells passing from AU to U
	int POP_FOR_U_DENSIFICATION <- int(shapes_def["POP_FOR_U_DENSIFICATION"]) ; // new population for densified cells
	int POP_FOR_U_STANDARD 		<- int(shapes_def["POP_FOR_U_STANDARD"]) ; // new population for other cells types
	float ANNUAL_POP_GROWTH_RATE<- float(eval_gaml(shapes_def["ANNUAL_POP_GROWTH_RATE"]));
	int minPopUArea 			<- int(eval_gaml(shapes_def["MIN_POPU_AREA"]));
	
	// Rugosity parameters
	float RUGOSITY_N 			<- float(shapes_def["RUGOSITY_N"]); 	
	float RUGOSITY_U 			<-float(shapes_def["RUGOSITY_U"]);
	float RUGOSITY_AU 			<- float(shapes_def["RUGOSITY_AU"]);
	float RUGOSITY_A 			<- float(shapes_def["RUGOSITY_A"]);
	float RUGOSITY_AUs 			<- float(shapes_def["RUGOSITY_AUs"]);
	float RUGOSITY_Us 			<- float(shapes_def["RUGOSITY_Us"]);
	string RUGOSITE_PAR_DEFAUT  <- shapes_def["RUGOSITE_PAR_DEFAUT"];
		
	// Costs of actions
	int ACTION_COST_LAND_COVER_TO_A 			<- int(data_action at 'ACTION_MODIFY_LAND_COVER_A' at 'cost');
	int ACTION_COST_LAND_COVER_TO_AU 			<- int(data_action at 'ACTION_MODIFY_LAND_COVER_AU' at 'cost');
	int ACTION_COST_LAND_COVER_FROM_AU_TO_N		<- int(data_action at 'ACTON_MODIFY_LAND_COVER_FROM_AU_TO_N' at 'cost');
	int ACTION_COST_LAND_COVER_FROM_A_TO_N 		<- int(data_action at 'ACTON_MODIFY_LAND_COVER_FROM_A_TO_N' at 'cost');
	int ACTION_COST_DIKE_CREATE 				<- int(data_action at 'ACTION_CREATE_DIKE' at 'cost');
	int ACTION_COST_DIKE_REPAIR 				<- int(data_action at 'ACTION_REPAIR_DIKE' at 'cost');
	int ACTION_COST_DIKE_DESTROY 				<- int(data_action at 'ACTION_DESTROY_DIKE' at 'cost');
	int ACTION_COST_DIKE_RAISE 					<- int(data_action at 'ACTION_RAISE_DIKE' at 'cost');
	float ACTION_COST_INSTALL_GANIVELLE 		<- float(data_action at 'ACTION_INSTALL_GANIVELLE' at 'cost'); 
	int ACTION_COST_LAND_COVER_TO_AUs	 		<- int(data_action at 'ACTION_MODIFY_LAND_COVER_AUs' at 'cost');
	int ACTION_COST_LAND_COVER_TO_Us 			<- int(data_action at 'ACTION_MODIFY_LAND_COVER_Us' at 'cost');
	int ACTION_COST_LAND_COVER_TO_Ui 			<- int(data_action at 'ACTION_MODIFY_LAND_COVER_Ui' at 'cost');
	int ACTION_COST_LAND_COVER_TO_AUs_SUBSIDY 	<- int(data_action at 'ACTION_MODIFY_LAND_COVER_AUs_SUBSIDY' at 'cost');
	int ACTION_COST_LAND_COVER_TO_Us_SUBSIDY 	<- int(data_action at 'ACTION_MODIFY_LAND_COVER_Us_SUBSIDY' at 'cost');
	
	map tax_unit_table 	<- eval_gaml(shapes_def["IMPOT_UNIT_TABLE"]); // received tax in Boyard for each inhabitant of the district 	
	int pctBudgetInit 	<- int(eval_gaml(shapes_def["PCT_BUDGET_TABLE"])); // at initialization, each district has a budget equal to an annual tax + %
	
	float coastBorderBuffer <- float(eval_gaml(shapes_def["COAST_BORDER_BUFFER"])); // width of littoral area from the coast line (<400m)	
	
	// Logging user actions
	bool log_user_action 	<- bool(configuration_file["LOG_USER_ACTION"]);
	// Saving results as shapefile. If true, at each round, water height and level are saved for all cells
	bool save_shp 			<- bool(configuration_file["SAVE_SHP"]);
	// Start simulation without ACTIVEMQ
	bool activemq_connect 	<- bool(configuration_file["ACTIVEMQ_CONNECT"]);
	// User interface params
	float button_size 		<- float(configuration_file["BUTTON_SIZE"]); //2000#m;
	int font_size 			<- int(shape.height/30); 	
	int font_interleave 	<- int(shape.width/60);
}


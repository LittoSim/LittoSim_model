/**
 *  LittoSIM_GEN
 *  Authors: Ahmed, Benoit, Brice, Cécilia, Elise, Etienne, Fredéric, Marion, Nicolas B, Nicolas M, Xavier 
 * 
 *  Description : LittoSIM_GEN is a participatory simulation platform implementing a serious playing-game for local authorities.
 * 				  The project aims at modeling effects of coastal flooding on urban areas and at enabling the transfer of scientific
 * 				  findings to risk managers, as well as awareness of those concerned by the risk of coastal flooding.
 * 
 * params_all : this file groups general and shared parameters between different models.
 */

model paramsall

global{
	/*
	 *  The main file (littosim.conf) that point to other files
	 */
	map<string,string> littosim_def <- read_configuration_file("../includes/config/littosim.conf");
	/*
	 * The study area file (study_area.conf) of the case study specified in littosim.conf
	 * This file stores hapefiles, data, and parameters specific to the study area
	 */
	map<string,string> study_area_def <- read_configuration_file("../" + littosim_def["STUDY_AREA_FILE"]);
	/*
	 *  Languages' file (langs.conf)
	 */
	map<string,map> langs_def <- store_csv_data_into_map_of_map("../" + littosim_def["LANGUAGE_FILE"]);
	/*
	 * This map represents data from actions file (actions.conf)
	 * To use this map : data_action at ACTION_NAME at parameter
	 * Example: data_action at 'ACTON_CREATE_DIKE' at 'cost'
	 */
	map<string,map> data_action <- store_csv_data_into_map_of_map("../" + study_area_def["ACTIONS_FILE"]);
	/*
	 * General parameters
	 */
	string default_lang 	<- littosim_def["LANGUAGE"]; // the default selected language
	// the name of the case study is the second part of the study area file path : includes/xxxxxxxx/study_area.conf
	string application_name <- littosim_def["STUDY_AREA_FILE"] split_with "/" at 1;
	/*
	 * Network names used to connect and communicate between models
	 */
	string SERVER <- littosim_def["SERVER_ADDRESS"]; // address where the manager is running 
	string GAME_MANAGER <- "GAME_MANAGER";
	string GAME_LEADER	<- "GAME_LEADER";
	string LISTENER_TO_LEADER<- "LISTENER_TO_LEADER";
	/*
	 * Object types sent over network : OBJECT_TYPE
	 */
	string OBJECT_TYPE_ACTIVATED_LEVER 	<- "ACTIVATED_LEVER";
	string OBJECT_TYPE_PLAYER_ACTION	<- "PLAYER_ACTION";
	string OBJECT_TYPE_COASTAL_DEFENSE	<- "COASTAL_DEFENSE";
	string OBJECT_TYPE_LAND_USE			<- "LAND_USE";
	string OBJECT_TYPE_WINDOW_LOCKER	<- "WINDOW_LOCKER";
	string OBJECT_TYPE_FLOOD_MARK		<- "FLOOD_MARK";
	/*
	 * Manager-Leader command names for network communications
	 * 
	 */
	string LEADER_COMMAND   	<- "LEADER_COMMAND";
	string RESPONSE_TO_LEADER 	<- "RESPONSE_TO_LEADER";
	
	string TAKE_MONEY_FROM 		<- 'TAKE_MONEY_FROM';
	string GIVE_MONEY_TO		<- 'GIVE_MONEY_TO';
	string SEND_MESSAGE_TO		<- 'SEND_MESSAGE_TO';
	string EXCHANGE_MONEY		<- 'EXCHANGE_MONEY';
	
	string ASK_NUM_ROUND 		<- "LEADER_ASKS_FOR_ROUND_NUMBER";
	string NUM_ROUND 			<- "ROUND_NUMBER";
	string ASK_INDICATORS_T0	<- "LEADER_ASKS_FOR_T0_IDICATORS";
	string INDICATORS_T0 		<- "INDICATORS_AT_T0";
	string ASK_ACTION_STATE 	<- "LEADER_ASKS_FOR_ACTION_STATE";
	string ACTION_STATE 		<- "ACTION_STATE";
	
	string AMOUNT 				<- "AMOUNT";
	string BUDGET 				<- "BUDGET";
	string POPULATION			<- "POPULATION";
	string DISTRICT_CODE 		<- "DISTRICT_CODE";
	
	string PLAYER_ACTION_ID 	<- "PLAYER_ACTION_ID";
	string NEW_ACTIVATED_LEVER	<- "NEW_ACTIVATED_LEVER";
	string NEW_REQUESTED_ACTION	<- "NEW_REQUESTED_ACTION";
	string STRATEGY_PROFILE		<- "STRATEGY_PROFILE";
	string ACTION_SHOULD_WAIT_LEVER_TO_ACTIVATE <- "ACTION_SHOULD_WAIT_LEVER_TO_ACTIVATE";
	/*
	 * Manager-Player command names for network communications
	 */
	string PLAYER_ACTION			 <- "PLAYER_ACTION";
	string NEW_COAST_DEF_ALT		 <- "NEW_COAST_DEF_ALT";
	string MSG_TO_PLAYER 			 <- "MSG_TO_PLAYER";
	string PLAYER_ACTION_IS_APPLIED  <- 'PLAYER_ACTION_IS_APPLIED';
	string INFORM_NEW_ROUND 		 <- 'INFORM_NEW_ROUND';
	string INFORM_CURRENT_ROUND		 <- 'INFORM_CURRENT_ROUND';
	string DATA_RETRIEVE 			 <- 'DATA_RETRIEVE';
	// Actions to acknowledge client requests
	string ACTION_COAST_DEF_UPDATED  <- "ACTION_COAST_DEF_UPDATED";
	string ACTION_COAST_DEF_CREATED  <- "ACTION_COAST_DEF_CREATED";
	string ACTION_COAST_DEF_DROPPED  <- "ACTION_COAST_DEF_DROPPED";
	string ACTION_LAND_COVER_UPDATED <- "ACTION_LAND_COVER_UPDATED";
	int REFRESH_ALL 			     <- 20;
	int CONNECTION_MESSAGE 			 <- 23;
	/*
	 * Player_Leader shared params
	 * 
	 */
	int PLAYER_MINIMAL_BUDGET  <- int(study_area_def['PLAYER_MINIMAL_BUDGET']);
	// strategies
	string BUILDER 		<- "BUILDER";
	string SOFT_DEFENSE <- "SOFT_DEFENSE";
	string WITHDRAWAL 	<- "WITHDRAWAL";
	string OTHER 		<- "OTHER";
	/*
	 * List of all possible actions to send over network. Any new action should be added here
	 */
	list<int> ACTION_LIST <- [CONNECTION_MESSAGE, REFRESH_ALL, ACTION_REPAIR_DIKE, ACTION_CREATE_DIKE, ACTION_DESTROY_DIKE, ACTION_RAISE_DIKE, ACTION_CREATE_DUNE,
							ACTION_INSTALL_GANIVELLE, ACTION_ENHANCE_NATURAL_ACCR, ACTION_MAINTAIN_DUNE, ACTION_LOAD_PEBBLES_CORD, ACTION_CLOSE_OPEN_GATES, 
							ACTION_MODIFY_LAND_COVER_AU, ACTION_MODIFY_LAND_COVER_AUs, ACTION_MODIFY_LAND_COVER_A, ACTION_MODIFY_LAND_COVER_Us, 
							ACTION_MODIFY_LAND_COVER_Ui, ACTION_MODIFY_LAND_COVER_N];
	/*
	 * List of actions with their parameters : reading the actions.conf file
	 * 
	 */
	int ACTION_REPAIR_DIKE 			 <- data_action at 'ACTION_REPAIR_DIKE' 		 != nil ? int(data_action at 'ACTION_REPAIR_DIKE' 			at 'action_code') : 0;
	int ACTION_CREATE_DIKE 			 <- data_action at 'ACTION_CREATE_DIKE' 		 != nil ? int(data_action at 'ACTION_CREATE_DIKE' 			at 'action_code') : 0;
	int ACTION_DESTROY_DIKE 		 <- data_action at 'ACTION_DESTROY_DIKE' 		 != nil ? int(data_action at 'ACTION_DESTROY_DIKE' 			at 'action_code') : 0;
	int ACTION_RAISE_DIKE 			 <- data_action at 'ACTION_RAISE_DIKE' 			 != nil ? int(data_action at 'ACTION_RAISE_DIKE' 			at 'action_code') : 0;
	int ACTION_INSTALL_GANIVELLE 	 <- data_action at 'ACTION_INSTALL_GANIVELLE' 	 != nil ? int(data_action at 'ACTION_INSTALL_GANIVELLE' 	at 'action_code') : 0;
	int ACTION_ENHANCE_NATURAL_ACCR	 <- data_action at 'ACTION_ENHANCE_NATURAL_ACCR' != nil ? int(data_action at 'ACTION_ENHANCE_NATURAL_ACCR' 	at 'action_code') : 0;
	int ACTION_LOAD_PEBBLES_CORD 	 <- data_action at 'ACTION_LOAD_PEBBLES_CORD' 	 != nil ? int(data_action at 'ACTION_LOAD_PEBBLES_CORD' 	at 'action_code') : 0;
	int ACTION_CREATE_DUNE 			 <- data_action at 'ACTION_CREATE_DUNE' 		 != nil ? int(data_action at 'ACTION_CREATE_DUNE' 			at 'action_code') : 0;
	int ACTION_MAINTAIN_DUNE 		 <- data_action at 'ACTION_MAINTAIN_DUNE' 		 != nil ? int(data_action at 'ACTION_MAINTAIN_DUNE' 		at 'action_code') : 0;
	int ACTION_MODIFY_LAND_COVER_AU  <- data_action at 'ACTION_MODIFY_LAND_COVER_AU' != nil ? int(data_action at 'ACTION_MODIFY_LAND_COVER_AU'	at 'action_code') : 0;
	int ACTION_MODIFY_LAND_COVER_A 	 <- data_action at 'ACTION_MODIFY_LAND_COVER_A'  != nil ? int(data_action at 'ACTION_MODIFY_LAND_COVER_A' 	at 'action_code') : 0;
	int ACTION_MODIFY_LAND_COVER_N 	 <- data_action at 'ACTION_MODIFY_LAND_COVER_N'  != nil ? int(data_action at 'ACTION_MODIFY_LAND_COVER_N' 	at 'action_code') : 0;
	int ACTION_MODIFY_LAND_COVER_AUs <- data_action at 'ACTION_MODIFY_LAND_COVER_AUs'!= nil ? int(data_action at 'ACTION_MODIFY_LAND_COVER_AUs' at 'action_code') : 0;	
	int ACTION_MODIFY_LAND_COVER_Us	 <- data_action at 'ACTION_MODIFY_LAND_COVER_Us' != nil ? int(data_action at 'ACTION_MODIFY_LAND_COVER_Us' 	at 'action_code') : 0;
	int ACTION_MODIFY_LAND_COVER_Ui  <- data_action at 'ACTION_MODIFY_LAND_COVER_Ui' != nil ? int(data_action at 'ACTION_MODIFY_LAND_COVER_Ui' 	at 'action_code') : 0;
	int ACTION_EXPROPRIATION 		 <- data_action at 'ACTION_EXPROPRIATION'		 != nil ? int(data_action at 'ACTION_EXPROPRIATION' 		at 'action_code') : 0;
	int ACTON_MODIFY_LAND_COVER_FROM_AU_TO_N  <- data_action at 'ACTON_MODIFY_LAND_COVER_FROM_AU_TO_N' != nil ? int(data_action at 'ACTON_MODIFY_LAND_COVER_FROM_AU_TO_N' at 'action_code') : 0;
	int ACTON_MODIFY_LAND_COVER_FROM_A_TO_N  <- data_action at 'ACTON_MODIFY_LAND_COVER_FROM_A_TO_N' != nil ? int(data_action at 'ACTON_MODIFY_LAND_COVER_FROM_A_TO_N' at 'action_code') : 0;
	int ACTION_CLOSE_OPEN_GATES	 <- data_action at 'ACTION_CLOSE_OPEN_GATES'	 != nil ? int(data_action at 'ACTION_CLOSE_OPEN_GATES' 		at 'action_code') : 0;
	int ACTION_CLOSE_OPEN_DIEPPE_GATE<- data_action at 'ACTION_CLOSE_OPEN_DIEPPE_GATE' != nil ? int(data_action at 'ACTION_CLOSE_OPEN_DIEPPE_GATE' at 'action_code') : 0;
	/*
	 * Constant variable values
	 */
	string PLAYER_ACTION_TYPE_LU		<- "PLAYER_ACTION_TYPE_LU";
	string PLAYER_ACTION_TYPE_COAST_DEF	<- "PLAYER_ACTION_TYPE_COAST_DEF";
	string COAST_DEF_TYPE_DIKE 			<- "DIKE";
	string COAST_DEF_TYPE_DUNE 			<- "DUNE";
	string COAST_DEF_TYPE_CORD 			<- "CORD";
	string WATER_GATE 					<- "GATE";
	string STATUS_GOOD 					<- "GOOD";
	string STATUS_MEDIUM				<- "MEDIUM";
	string STATUS_BAD 					<- "BAD";
	/*
	 * Population density and parameters
	 */
	string POP_EMPTY 		   <- "EMPTY";
	string POP_VERY_LOW_DENSITY<- "POP_VERY_LOW_DENSITY";
	string POP_LOW_DENSITY 	   <- "LOW_DENSITY";
	string POP_MEDIUM_DENSITY  <- "MEDIUM_DENSITY";
	string POP_DENSE 		   <- "DENSE";
	int    POP_LOW_NUMBER 	   <- int(eval_gaml(study_area_def["POP_LOW_NUMBER"]));
	int    POP_MEDIUM_NUMBER   <- int(eval_gaml(study_area_def["POP_MEDIUM_NUMBER"]));
	int    POP_HIGH_NUMBER     <- int(eval_gaml(study_area_def["POP_HIGH_NUMBER"]));
	int    MIN_POP_AREA 	   <- int(eval_gaml(study_area_def["MIN_POPU_AREA"]));
	int    EXP_COST_IF_EMPTY   <- int(eval_gaml(study_area_def["EXP_COST_IF_EMPTY"]));
	/*
	 * Coastal defenses parameters
	 */
	float BUILT_DIKE_HEIGHT 		<- float(study_area_def["BUILT_DIKE_HEIGHT"]);
	float RAISE_DIKE_HEIGHT 		<- float(study_area_def["RAISE_DIKE_HEIGHT"]);
	string BUILT_DIKE_STATUS		<- STATUS_GOOD;
	float MIN_HEIGHT_DIKE 			<- float (eval_gaml(study_area_def["MIN_HEIGHT_DIKE"]));
	float DUNE_TYPE_DISTANCE_COAST  <- float(study_area_def["DUNE_TYPE_DISTANCE_COAST"]);
	bool DUNES_TYPE2 				<- bool(study_area_def["DUNES_TYPE2"]);
	float BUILT_DUNE_TYPE1_HEIGHT <- float(study_area_def["BUILT_DUNE_TYPE1_HEIGHT"]);
	float BUILT_DUNE_TYPE2_HEIGHT <- float(study_area_def["BUILT_DUNE_TYPE2_HEIGHT"]);
	int MAINTAIN_STATUS_DUNE_STEPS	<- int(study_area_def["MAINTAIN_STATUS_DUNE_STEPS"]);
	/*
	 * Land use parameters
	 */
	float coastBorderBuffer <- float(eval_gaml(study_area_def["COAST_BORDER_BUFFER"])); // width of littoral area from the coast line (ex: 400m)
	bool AU_AND_AUs_TO_N	<- bool (study_area_def["AU_AND_AUs_TO_N"]); // should we replace AU and AUs by N ?
	int STANDARD_LU_AREA <- int(study_area_def["STANDARD_LU_AREA"]); // area of a standard cell to manage costs and populations
	/*
	 * Different types of a land use unit : Natural, Urbanized, Authorized for Urbanization, Agricultural, Urbanized Special (adapted),
	 * 										Authorized for Urbanization Special (adapted)
	 *			 lu_code		   [0	1	2	3	 4	  5	  6	    7  ]
	 */
    list<string> lu_type_names 	<- ["","N","U","Ui","AU","A","Us","AUs"];
    int LU_TYPE_N  <- 1;
    int LU_TYPE_U  <- 2;
    int LU_TYPE_Ui <- 3;
    int LU_TYPE_AU <- 4;
    int LU_TYPE_A  <- 5;
    int LU_TYPE_Us <- 6;
    int LU_TYPE_AUs<- 7;
	/*
	 * Loading GIS data (shapefiles and rasters)
	 */
	file districts_shape 		<- file("../" + study_area_def["DISTRICTS_SHAPE"]);
	file roads_shape 			<- file("../" + study_area_def["ROADS_SHAPE"]);
	file protected_areas_shape 	<- file("../" + study_area_def["SPA_SHAPE"]);
	file river_shape 			<- file("../" + study_area_def["RIVER_SHAPE"]);
	file rpp_area_shape 		<- file("../" + study_area_def["RPP_SHAPE"]);
	file coastline_shape 		<- file("../" + study_area_def["COASTLINE_SHAPE"]);
	file coastal_defenses_shape <- file("../" + study_area_def["COASTAL_DEFENSES_SHAPE"]);
	file land_use_shape 		<- file("../" + study_area_def["LAND_USE_SHAPE"]);	
	file convex_hull_shape 		<- file("../" + study_area_def["CONVEX_HULL_SHAPE"]);
	file isolines_shape 		<- file("../" + study_area_def["ISOLINES_SHAPE"]);
	/*
	 * tables of district names (short and long names)
	 */
	map dist_code_lname_correspondance_table	<- eval_gaml(study_area_def["MAP_DIST_LNAMES"]);
	map dist_code_sname_correspondance_table 	<- eval_gaml(study_area_def["MAP_DIST_SNAMES"]);
	int number_of_districts <- length(dist_code_sname_correspondance_table);
	/*
	 * Taxes and budgets
	 */
	map tax_unit_table 		<- eval_gaml(study_area_def["IMPOT_UNIT_TABLE"]); 			// received tax in Boyard for each inhabitant of the district 	
	int initial_budget 		<- int(eval_gaml(study_area_def["INITIAL_BUDGET_BONUS"])); 	// at initialization, each district has a budget equal to an annual tax + %
	/* 
	 * methods to load configuration files into maps
	 */
	// used to the read configuration files : littosim.conf + study_area.conf
	map<string, string> read_configuration_file(string fileName){
		map<string, string> res <- map<string, string>([]);
		string line <- "";
		loop line over:text_file(fileName){
			if first(line) != "#" and line contains(";"){
				list<string> data <- line split_with(";");
				add data[1] at:data[0] to:res;	
			}				
		}
		return res;
	}
	// used to read ";" separated values files : langs.conf + actions.conf + levers.conf
	map<string, map> store_csv_data_into_map_of_map(string fileName){
		map<string, map> res ;
		string line <- "";
		list<string> col_labels <- [];
		loop line over: text_file(fileName){
			if first(line) != "#" and line contains(";"){
				list<string> data <- line split_with(";");
				if empty(col_labels) {
					col_labels <- data ;
				} 
				else{
					map  sub_res <- map([]);
					loop i from: 1 to: ((length(col_labels))-1) {
						add data[i] at: col_labels[i] to: sub_res ;
					}
					add sub_res at: data[0] to:res ;
				}	
			}
		}
		return res;
	}
	/*
	 * gets the name of an action from its code (from actions.conf)
	 */
	string name_of_action (int act_code){
		loop act_name over: data_action.keys{
			if int(data_action at act_name at 'action_code') = act_code{
				return act_name; // action name
			}
		}
		return "";
	}
	/*
	 * gets the label of an action from its code
	 */
	string label_of_action (int act_code){
		return get_message(name_of_action(act_code));
	}
	/*
	 * gets the delay of an action from its code
	 */
	int delay_of_action (int act_code){
		return int(data_action at name_of_action(act_code) at 'delay');
	}
	/*
	 * gets the cost of an action from its name
	 */
	float cost_of_action (string act_name){
		return float(data_action at act_name at 'cost');
	}
	
	/*
	 * gets the corresponding LU type of a command
	 */
	string lu_name_of_command (int command) {
		switch command {
			match ACTION_MODIFY_LAND_COVER_AU 	{	return "AU" ;	}
			match ACTION_MODIFY_LAND_COVER_A 	{	return "A"  ;	}
			match ACTION_MODIFY_LAND_COVER_N 	{	return "N"  ;	}
			match ACTION_MODIFY_LAND_COVER_AUs 	{	return "AUs";	}
			match ACTION_MODIFY_LAND_COVER_Us 	{	return "Us" ;	}
			match ACTION_MODIFY_LAND_COVER_Ui 	{	return "Ui" ;	}
			match ACTION_EXPROPRIATION 			{	return "N"  ;	}
		}
	}
	/*
	 * a method to get the corresponding text from languages' file (langs.conf)
	 */ 
	string get_message(string code_msg){
		return code_msg = nil or code_msg = 'na' ? '' : (langs_def at code_msg != nil ? langs_def at code_msg at default_lang : '');
	}
	/*
	 * replaces a regex "#s" with the corresponding text from the list given as parameter
	 */
	string replace_strings(string s, list<string> lisa){
		s <- get_message (s);
		loop i from:0 to: length(lisa)-1{
			s <- replace(s,'#s'+(i+1), lisa[i]);
		}
		return s;
	}
	/*
	 * Colors or labels and districts to show in graphs
	 */
	list<rgb> color_lbls <- [#moccasin,#lightgreen,#deepskyblue,#darkgray,#darkgreen,#darkblue];
	list<rgb> dist_colors <- [#red, #blue, #green, #orange];
	
	/*
	 * colors and classes of water heights levels
	 */
	list<rgb> colors_of_water_height <- [rgb(200,200,255),rgb(115,115,255),rgb(65,65,255),rgb(30,30,255)];
	int class_of_water_height (float w_height){
		if 		w_height  	<= 0.5	{	return 0;	}
		else if w_height  	<= 1  	{	return 1;	}
		else if w_height	<= 2  	{	return 2;	}
		else 						{	return 3;	}
	}
	
	/*
	 * player button states shared between Leader and Manager
	 */
	int B_HIDDEN <- 2;
	int B_DEACTIVATED <- 1;
	int B_ACTIVATED	<- 0;
	/*
	 * repetitive translated messages shared bteween different modules
	 */
	string MSG_ROUND;
	string LDR_TOTAL;
	string LEV_MSG_ACTIONS;
	string MSG_TAXES;
	string LDR_GIVEN;
	string LDR_TAKEN;
	string LDR_TRANSFERRED;
	string MSG_LEVERS;
	string MSG_BUILDER;
	string MSG_SOFT_DEF;
	string MSG_WITHDRAWAL;
	string MSG_OTHER;
	string LEV_DIKES;
	string LEV_DUNES;
}
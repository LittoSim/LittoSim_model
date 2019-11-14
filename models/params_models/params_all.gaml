/**
* Name: params_all
*/

model paramsall

global{
	// Configuration files
	string config_file_name 				<- "../includes/config/littosim.conf"; 
	map<string,string> configuration_file 	<- read_configuration_file(config_file_name,";"); // main file pointing to others
	map<string,string> study_area_def		<- read_configuration_file(configuration_file["STUDY_AREA_FILE"],";"); // Shapefiles data
	map<string,map> langs_def 				<- store_csv_data_into_map_of_map(configuration_file["LANGUAGES_FILE"],";"); // Languages
	map<string,map> data_action 			<- store_csv_data_into_map_of_map(study_area_def["ACTIONS_FILE"],";"); // Actions: to use this map : data_action at ACTION_NAME at parameter (Example: data_action at 'ACTON_CREATE_DIKE' at 'cost')
	
	string application_name <- study_area_def["APPLICATION_NAME"];
	bool IS_OSX <- bool(configuration_file["IS_OSX"]);
	// Network 
	string SERVER 			<- configuration_file["SERVER_ADDRESS"]; 
	string GAME_MANAGER 	<- "GAME_MANAGER";
	string GAME_LEADER	    <- "GAME_LEADER";
	string LISTENER_TO_LEADER<- "LISTENER_TO_LEADER";
	
	// Object types sent over network : OBJECT_TYPE
	string OBJECT_TYPE_ACTIVATED_LEVER 	<- "ACTIVATED_LEVER";
	string OBJECT_TYPE_PLAYER_ACTION	<- "PLAYER_ACTION";
	string OBJECT_TYPE_COASTAL_DEFENSE	<- "COASTAL_DEFENSE";
	string OBJECT_TYPE_LAND_USE			<- "LAND_USE";
	string OBJECT_TYPE_WINDOW_LOCKER	<- "WINDOW_LOCKER";

	// Main-Leader network communication
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
	
	// Manager-Player network communication
	string PLAYER_ACTION			 <- "PLAYER_ACTION";
	string NEW_COAST_DEF_ALT		 <- "NEW_COAST_DEF_ALT";
	string MSG_TO_PLAYER 			 <- "MSG_TO_PLAYER";
	string PLAYER_ACTION_IS_APPLIED  <- 'PLAYER_ACTION_IS_APPLIED';
	string INFORM_NEW_ROUND 		 <- 'INFORM_NEW_ROUND';
	string INFORM_CURRENT_ROUND		 <- 'INFORM_CURRENT_ROUND';
	string DATA_RETRIEVE 			 <- 'DATA_RETRIEVE';
	// Actions to acknowledge client requests
	string ACTION_COAST_DEF_UPDATED   <- "ACTION_COAST_DEF_UPDATED";
	string ACTION_COAST_DEF_CREATED  <- "ACTION_COAST_DEF_CREATED";
	string ACTION_COAST_DEF_DROPPED  <- "ACTION_COAST_DEF_DROPPED";
	string ACTION_LAND_COVER_UPDATED <- "ACTION_LAND_COVER_UPDATED";
	int REFRESH_ALL 			<- 20;
	int CONNECTION_MESSAGE 		<- 23;
	
	int PLAYER_MINIMAL_BUDGET  <- int(study_area_def['PLAYER_MINIMAL_BUDGET']);
	
	// strategies
	string BUILDER 		<- "BUILDER";
	string SOFT_DEFENSE <- "SOFT_DEFENSE";
	string WITHDRAWAL 	<- "WITHDRAWAL";
	string OTHER 		<- "OTHER";
	
		// List of all possible actions to send over network
	list<int> ACTION_LIST <- [CONNECTION_MESSAGE, REFRESH_ALL, ACTION_REPAIR_DIKE, ACTION_CREATE_DIKE, ACTION_DESTROY_DIKE, ACTION_RAISE_DIKE, ACTION_CREATE_DUNE,
							ACTION_INSTALL_GANIVELLE, ACTION_ENHANCE_NATURAL_ACCR, ACTION_MAINTAIN_DUNE, ACTION_LOAD_PEBBLES_CORD, ACTION_CLOSE_OPEN_GATES, 
							ACTION_MODIFY_LAND_COVER_AU, ACTION_MODIFY_LAND_COVER_AUs, ACTION_MODIFY_LAND_COVER_A, ACTION_MODIFY_LAND_COVER_Us, 
							ACTION_MODIFY_LAND_COVER_Ui, ACTION_MODIFY_LAND_COVER_N];
	
	// List of actions with their parameters
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
	int ACTION_CLOSE_OPEN_GATES	 	 <- data_action at 'ACTION_CLOSE_OPEN_GATES'	 != nil ? int(data_action at 'ACTION_CLOSE_OPEN_GATES' 		at 'action_code') : 0;
	int ACTION_CLOSE_OPEN_DIEPPE_GATE<- data_action at 'ACTION_CLOSE_OPEN_DIEPPE_GATE' != nil ? int(data_action at 'ACTION_CLOSE_OPEN_DIEPPE_GATE' at 'action_code') : 0;
	
	// Constant vars
	string PLAYER_ACTION_TYPE_LU		<- "PLAYER_ACTION_TYPE_LU";
	string PLAYER_ACTION_TYPE_COAST_DEF	<- "PLAYER_ACTION_TYPE_COAST_DEF";
	string COAST_DEF_TYPE_DIKE 			<- "DIKE";
	string COAST_DEF_TYPE_DUNE 			<- "DUNE";
	string COAST_DEF_TYPE_CORD 			<- "CORD";
	string WATER_GATE 					<- "GATE";
	string STATUS_GOOD 					<- "GOOD";
	string STATUS_MEDIUM				<- "MEDIUM";
	string STATUS_BAD 					<- "BAD";
	
	// Population density
	string POP_EMPTY 		  <- "EMPTY";
	string POP_VERY_LOW_DENSITY<- "POP_VERY_LOW_DENSITY";
	string POP_LOW_DENSITY 	  <- "LOW_DENSITY";
	string POP_MEDIUM_DENSITY <- "MEDIUM_DENSITY";
	string POP_DENSE 		  <- "DENSE";
	int    POP_LOW_NUMBER 	  <- int(eval_gaml(study_area_def["POP_LOW_NUMBER"]));
	int    POP_MEDIUM_NUMBER  <- int(eval_gaml(study_area_def["POP_MEDIUM_NUMBER"]));
	int    POP_HIGH_NUMBER    <- int(eval_gaml(study_area_def["POP_HIGH_NUMBER"]));
	int    MIN_POP_AREA 	  <- int(eval_gaml(study_area_def["MIN_POPU_AREA"]));
	
	// Building and raising dikes parameters
	float BUILT_DIKE_HEIGHT <- float(study_area_def["BUILT_DIKE_HEIGHT"]);
	float RAISE_DIKE_HEIGHT <- float(study_area_def["RAISE_DIKE_HEIGHT"]);
	string BUILT_DIKE_STATUS<- study_area_def["BUILT_DIKE_STATUS"];
	float MIN_HEIGHT_DIKE 	<- float (eval_gaml(study_area_def["MIN_HEIGHT_DIKE"]));
	float DUNE_TYPE_DISTANCE_COAST  <- float(study_area_def["DUNE_TYPE_DISTANCE_COAST"]);
	float BUILT_DUNE_TYPE1_HEIGHT <- float(study_area_def["BUILT_DUNE_TYPE1_HEIGHT"]);
	float BUILT_DUNE_TYPE2_HEIGHT <- float(study_area_def["BUILT_DUNE_TYPE2_HEIGHT"]);
	int MAINTAIN_STATUS_DUNE_STEPS	<- int(study_area_def["MAINTAIN_STATUS_DUNE_STEPS"]);
	
	// Loading GIS data
	file districts_shape 		<- file(study_area_def["DISTRICTS_SHAPE"]);
	file roads_shape 			<- file(study_area_def["ROADS_SHAPE"]);
	file isolines_shape 		<- file(study_area_def["ISOLINES_SHAPE"]);
	file protected_areas_shape 	<- file(study_area_def["SPA_SHAPE"]);
	file water_shape 			<- file(study_area_def["WATER_SHAPE"]);
	file river_flood_shape 		<- file(study_area_def["RIVER_FLOOD_SHAPE"]);
	file river_flood_shape_1m 	<- file(study_area_def["RIVER_FLOOD_SHAPE_1M"]);
	file rpp_area_shape 		<- file(study_area_def["RPP_SHAPE"]);
	file coastline_shape 		<- file(study_area_def["COASTLINES_SHAPE"]);
	file coastal_defenses_shape <- file(study_area_def["COASTAL_DEFENSES_SHAPE"]);
	file land_use_shape 		<- file(study_area_def["LAND_USE_SHAPE"]);	
	file convex_hull_shape 		<- file(study_area_def["CONVEX_HULL_SHAPE"]); 
	file dem_file 				<- file(study_area_def["DEM_FILE"]);
	file buffer_in_100m_shape 	<- file(study_area_def["BUFFER_IN100M_SHAPE"]);
	map dist_code_lname_correspondance_table	<- eval_gaml(study_area_def["MAP_DIST_CODE_LONG_NAME"]);
	map dist_code_sname_correspondance_table 	<- eval_gaml(study_area_def["MAP_DIST_CODE_SHORT_NAME"]);
	float coastBorderBuffer <- float(eval_gaml(study_area_def["COAST_BORDER_BUFFER"])); // width of littoral area from the coast line (<400m)
	
	bool AU_AND_AUs_TO_N	<- bool (study_area_def["AU_AND_AUs_TO_N"]); // should we replace AU and AUs by N ?
	int STANDARD_LU_AREA <- int(study_area_def["STANDARD_LU_AREA"]); // area of a standard cell to manage costs and populations
		
	// Taxes
	map tax_unit_table 		<- eval_gaml(study_area_def["IMPOT_UNIT_TABLE"]); 				// received tax in Boyard for each inhabitant of the district 	
	int initial_budget 		<- int(eval_gaml(study_area_def["INITIAL_BUDGET_BONUS"])); 			// at initialization, each district has a budget equal to an annual tax + %
		
	//------------------------------ Shared methods to load configuration files into maps -------------------------------//
	map<string, string> read_configuration_file(string fileName,string separator){
		map<string, string> res <- map<string, string>([]);
		string line <- "";
		loop line over:text_file(fileName){
			if(line contains(separator)){
				list<string> data <- line split_with(separator);
				add data[1] at:data[0] to:res;	
			}				
		}
		return res;
	}
	
	map<string, map> store_csv_data_into_map_of_map(string fileName, string separator){
		map<string, map> res ;
		string line <- "";
		list<string> col_labels <- [];
		loop line over: text_file(fileName){
			if(line contains(separator)){
				list<string> data <- line split_with(separator);
				if empty(col_labels) {
					col_labels <- data ;
				} 
				else{
					map  sub_res <- map([]);
					loop i from: 1 to: ((length(col_labels))-1) {
						add data[i] at: col_labels[i] to: sub_res ;
					}
					add sub_res at:data[0] to:res ;
				}	
			}
		}
		return res;
	}
	
	string label_of_action (int act_code){
		string rslt <- "";
		loop act_name over: data_action.keys{
			if int(data_action at act_name at 'action_code') = act_code{
				rslt <- get_message(act_name);    // action label
			}
		}
		return rslt;
	}
	
	int delay_of_action (int action_code){
		int rst <- 0;
		loop act_name over: data_action.keys{
			if int(data_action at act_name at 'action_code') = action_code{
				rst <- int(data_action at act_name at 'delay');
			}			
		}
		return rst;
	}
	
	float cost_of_action (string act_name){
		return float(data_action at act_name at 'cost');
	}
	
	// Natural, Urbanized, Authorized Urbanization, Agricultural, Urbanized subsidized, Authorized Urbanization subsidized
	//			 lu_code			0	1	2	3	4	5	6	  7
    list<string> lu_type_names 	<- ["","N","U","","AU","A","Us","AUs"];
    int LU_TYPE_N <- 1;
    int LU_TYPE_U <- 2;
    int LU_TYPE_AU <- 4;
    int LU_TYPE_A <- 5;
    int LU_TYPE_Us <- 6;
    int LU_TYPE_AUs <- 7;
	
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
	
	rgb color_of_water_height (float w_height){
		if 		w_height  	<= 0.5	{	return rgb(200,200,255);	}
		else if w_height  	<= 1  	{	return rgb(115,115,255);	}
		else if w_height	<= 2  	{	return rgb(65,65,255);		}
		else 						{	return rgb(30,30,255);		}
	}
	
	string get_message(string code_msg){
		return code_msg = nil or code_msg = 'na' ? "" : (langs_def at code_msg != nil ? langs_def at code_msg at configuration_file["LANGUAGE"] : ''); // getting the right message from languages file
	}
	
	string replace_strings(string s, list<string> lisa){
		s <- get_message (s);
		loop i from:0 to: length(lisa)-1{
			s <- replace(s,'#s'+(i+1), lisa[i]);
		}
		return s;
	}
	//------------------------------ End of methods -------------------------------//
	list<rgb> color_lbls <- [#moccasin,#lightgreen,#deepskyblue,#darkgray,#darkgreen,#darkblue];
	list<rgb> dist_colors <- [#red, #blue, #green, #orange];
	
	// player button states
	int B_HIDDEN <- 2;
	int B_DEACTIVATED <- 1;
	int B_ACTIVATED	<- 0;
	
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
}
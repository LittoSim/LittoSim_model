/**
* Name: params_all
*/

model paramsall

global{
	list<string> languages_list <- ['fr', 'en'];
	// Configuration files
	string config_file_name 				<- "../includes/config/littosim.conf"; 
	map<string,string> configuration_file 	<- read_configuration_file(config_file_name,";"); // main file pointing to others
	map<string,string> shapes_def 			<- read_configuration_file(configuration_file["SHAPES_FILE"],";"); // Shapefiles data
	map<string,string> flooding_def 		<- read_configuration_file(configuration_file["FLOODING_FILE"],";"); // Flooding model
	matrix<string> actions_def 				<- matrix<string>(csv_file(configuration_file["ACTIONS_FILE"],";"));	// Actions, costs and delays
	map<string,map> langs_def 				<- store_csv_data_into_map_of_map(configuration_file["LANGUAGES_FILE"],";"); // Languages
	map<string,map> data_action 			<- store_csv_data_into_map_of_map(configuration_file["ACTIONS_FILE"],";"); // Actions: to use this map : data_action at ACTION_NAME at parameter (Example: data_action at 'ACTON_CREATE_DIKE' at 'cost')
		
	// Network 
	string SERVER 					<- configuration_file["SERVER_ADDRESS"]; 
	string GAME_MANAGER 			<- "GAME_MANAGER";
	string GAME_LEADER	     	 	<- "GAME_LEADER";
	string LISTENER_TO_LEADER	 	<- "LISTENER_TO_LEADER";
	
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
	
	string ASK_NUM_ROUND 		<- "LEADER_ASKS_FOR_ROUND_NUMBER";
	string NUM_ROUND 			<- "ROUND_NUMBER";
	string ASK_INDICATORS_T0	<- "LEADER_ASKS_FOR_T0_IDICATORS";
	string INDICATORS_T0 		<- "INDICATORS_AT_T0";
	string ASK_ACTION_STATE 	<- "LEADER_ASKS_FOR_ACTION_STATE";
	string ACTION_STATE 		<- "ACTION_STATE";
	
	string AMOUNT 				<- "AMOUNT";
	string BUDGET 				<- "BUDGET";
	string DISTRICT_CODE 		<- "DISTRICT_CODE";
	
	string PLAYER_ACTION_ID 	<- "PLAYER_ACTION_ID";
	string NEW_ACTIVATED_LEVER	<- "NEW_ACTIVATED_LEVER";
	string NEW_REQUESTED_ACTION	<- "NEW_REQUESTED_ACTION";
	string STRATEGY_PROFILE		<- "STRATEGY_PROFILE";
	string ACTION_SHOULD_WAIT_LEVER_TO_ACTIVATE <- "ACTION_SHOULD_WAIT_LEVER_TO_ACTIVATE";
	
	// Manager-Player network communication
	string PLAYER_ACTION			<- "PLAYER_ACTION";
	string NEW_DIKE_ALT				<- "NEW_DIKE_ALT";
	string MSG_TO_PLAYER 			<- "MSG_TO_PLAYER";
	string PLAYER_ACTION_IS_APPLIED <- 'PLAYER_ACTION_IS_APPLIED';
	string DISTRICT_BUDGET_UPDATE 	<- 'DISTRICT_BUDGET_UPDATE';
	string INFORM_NEW_ROUND 		<- 'INFORM_NEW_ROUND';
	string INFORM_LU_ALTS			<- 'INFORM_LU_ALTS';
	string INFORM_CURRENT_ROUND		<- 'INFORM_CURRENT_ROUND';
	string DATA_RETRIEVE 			<- 'DATA_RETRIEVE';
	// Actions to acknowledge client requests
	string ACTION_DIKE_UPDATE   <- "ACTION_DIKE_UPDATE";
	string ACTION_DIKE_CREATED 	<- "ACTION_DIKE_CREATED";
	string ACTION_DIKE_DROPPED 	<- "ACTION_DIKE_DROPPED";
	string ACTION_LAND_COVER_UPDATE <- "ACTION_LAND_COVER_UPDATE";
	int REFRESH_ALL 			<- 20;
	int CONNECTION_MESSAGE 		<- 23;
	
	// strategies
	string BUILDER 		<- "BUILDER";
	string SOFT_DEFENSE <- "SOFT_DEFENSE";
	string WITHDRAWAL 	<- "WITHDRAWAL";
	string NEUTRAL 	<- "NEUTRAL";
	
		// List of all possible actions to send over network
	list<int> ACTION_LIST <- [CONNECTION_MESSAGE, REFRESH_ALL, ACTION_REPAIR_DIKE, ACTION_CREATE_DIKE, ACTION_DESTROY_DIKE, ACTION_RAISE_DIKE,
							ACTION_INSTALL_GANIVELLE, ACTION_MODIFY_LAND_COVER_AU, ACTION_MODIFY_LAND_COVER_AUs, ACTION_MODIFY_LAND_COVER_A,
							ACTION_MODIFY_LAND_COVER_U, ACTION_MODIFY_LAND_COVER_Us, ACTION_MODIFY_LAND_COVER_Ui, ACTION_MODIFY_LAND_COVER_N];
	
	// List of actions with their parameters
	int ACTION_REPAIR_DIKE 			 <- int(data_action at 'ACTION_REPAIR_DIKE' 			at 'action_code');
	int ACTION_CREATE_DIKE 			 <- int(data_action at 'ACTION_CREATE_DIKE' 			at 'action_code');
	int ACTION_DESTROY_DIKE 		 <- int(data_action at 'ACTION_DESTROY_DIKE' 			at 'action_code');
	int ACTION_RAISE_DIKE 			 <- int(data_action at 'ACTION_RAISE_DIKE' 				at 'action_code');
	int ACTION_INSTALL_GANIVELLE 	 <- int(data_action at 'ACTION_INSTALL_GANIVELLE' 		at 'action_code');
	int ACTION_MODIFY_LAND_COVER_AU  <- int(data_action at 'ACTION_MODIFY_LAND_COVER_AU'	at 'action_code');
	int ACTION_MODIFY_LAND_COVER_A 	 <- int(data_action at 'ACTION_MODIFY_LAND_COVER_A' 	at 'action_code');
	int ACTION_MODIFY_LAND_COVER_U 	 <- int(data_action at 'ACTION_MODIFY_LAND_COVER_U' 	at 'action_code');
	int ACTION_MODIFY_LAND_COVER_N 	 <- int(data_action at 'ACTION_MODIFY_LAND_COVER_N' 	at 'action_code');
	int ACTION_MODIFY_LAND_COVER_AUs <- int(data_action at 'ACTION_MODIFY_LAND_COVER_AUs'	at 'action_code');	
	int ACTION_MODIFY_LAND_COVER_Us	 <- int(data_action at 'ACTION_MODIFY_LAND_COVER_Us' 	at 'action_code');
	int ACTION_MODIFY_LAND_COVER_Ui  <- int(data_action at 'ACTION_MODIFY_LAND_COVER_Ui' 	at 'action_code');
	int ACTION_EXPROPRIATION 		 <- int(data_action at 'ACTION_EXPROPRIATION' 			at 'action_code');
	
	// Constant vars
	string PLAYER_ACTION_TYPE_LU		<- "PLAYER_ACTION_TYPE_LU";
	string PLAYER_ACTION_TYPE_COAST_DEF	<- "PLAYER_ACTION_TYPE_COAST_DEF";
	string COAST_DEF_TYPE_DIKE 			<- "Dike";
	string COAST_DEF_TYPE_DUNE 			<- "Dune";
	string STATUS_GOOD 					<- "Good";
	string STATUS_MEDIUM				<- "Medium";
	string STATUS_BAD 					<- "Bad";
	
	// Population density
	string POP_EMPTY 		  <- "EMPTY";
	string POP_LOW_DENSITY 	  <- "LOW_DENSITY";
	string POP_MEDIUM_DENSITY <- "MEDIUM_DENSITY";
	string POP_DENSE 		  <- "DENSE";
	int    POP_LOW_NUMBER 	  <- 40;
	int    POP_MEDIUM_NUMBER  <- 80;
	int    MIN_POP_AREA 	  <- int (eval_gaml(shapes_def["MIN_POPU_AREA"]));
	
	// Building and raising dikes parameters
	float BUILT_DIKE_HEIGHT <- float(shapes_def["BUILT_DIKE_HEIGHT"]);
	float RAISE_DIKE_HEIGHT <- float(shapes_def["RAISE_DIKE_HEIGHT"]); // 1#m by default
	string BUILT_DIKE_STATUS 	<- shapes_def["BUILT_DIKE_STATUS"];
	float  MIN_HEIGHT_DIKE 		<- float (eval_gaml(shapes_def["MIN_HEIGHT_DIKE"]));
	
	// Loading GIS data
	file districts_shape 		<- file(shapes_def["DISTRICTS_SHAPE"]);
	file roads_shape 			<- file(shapes_def["ROADS_SHAPE"]);
	file isolines_shape 		<- file(shapes_def["ISOLINES_SHAPE"]);
	file protected_areas_shape 	<- file(shapes_def["SPA_SHAPE"]);
	file water_shape 			<- file(shapes_def["WATER_SHAPE"]);
	file rpp_area_shape 		<- file(shapes_def["RPP_SHAPE"]);
	file coastline_shape 		<- file(shapes_def["COASTLINES_SHAPE"]);
	file coastal_defenses_shape <- file(shapes_def["COASTAL_DEFENSES_SHAPE"]);
	file land_use_shape 		<- file(shapes_def["LAND_USE_SHAPE"]);	
	file convex_hull_shape 		<- file(shapes_def["CONVEX_HULL_SHAPE"]); 
	file dem_file 				<- file(shapes_def["DEM_FILE"]);
	file hillshade_file 		<- file(shapes_def["HILLSHADE"]);
	file buffer_in_100m_shape 	<- file(shapes_def["BUFFER_IN100M_SHAPE"]);
	map dist_code_lname_correspondance_table	<- eval_gaml(shapes_def["MAP_DIST_CODE_LONG_NAME"]);
	map dist_code_sname_correspondance_table 	<- eval_gaml(shapes_def["MAP_DIST_CODE_SHORT_NAME"]);
	
	// Taxes
	map tax_unit_table 		<- eval_gaml(shapes_def["IMPOT_UNIT_TABLE"]); 				// received tax in Boyard for each inhabitant of the district 	
	int pctBudgetInit 		<- int(eval_gaml(shapes_def["PCT_BUDGET_TABLE"])); 			// at initialization, each district has a budget equal to an annual tax + %
		
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
    list<string> lu_type_names 	<- ["","N","U","","AU","A","Us","AUs"];
	
	string lu_name_of_command (int command) {
		switch command {
			match ACTION_MODIFY_LAND_COVER_AU 	{	return "AU" ;	}
			match ACTION_MODIFY_LAND_COVER_A 	{	return "A"  ;	}
			match ACTION_MODIFY_LAND_COVER_U 	{	return "U"  ;	}
			match ACTION_MODIFY_LAND_COVER_N 	{	return "N"  ;	}
			match ACTION_MODIFY_LAND_COVER_AUs 	{	return "AUs";	}
			match ACTION_MODIFY_LAND_COVER_Us 	{	return "Us" ;	}
			match ACTION_MODIFY_LAND_COVER_Ui 	{	return "Ui" ;	}
			match ACTION_EXPROPRIATION 			{	return "N"  ;	}
		}
	}
	
	string get_message(string code_msg){
		return langs_def at code_msg at configuration_file["LANGUAGE"]; // getting the right message from languages file
	}
	//------------------------------ End of methods -------------------------------//
}
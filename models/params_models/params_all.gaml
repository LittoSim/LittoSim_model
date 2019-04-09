/**
* Name: params_all
*/

model paramsall

global{
	
	// Configuration files
	string config_file_name 				<- "../includes/config/littosim.csv"; 
	map<string,string> configuration_file 	<- read_configuration_file(config_file_name,";"); // main file pointing to others
	map<string,string> shapes_def 			<- read_configuration_file(configuration_file["SHAPE_DEF_FILE"],";"); // Shapefiles data
	map<string,string> flooding_def 		<- read_configuration_file(configuration_file["FLOODING_DEF_FILE"],";"); // Flooding model
	matrix<string> actions_def 				<- matrix<string>(csv_file(configuration_file["ACTION_DEF_FILE"],";"));	// Actions, costs and delays
	map<string,map> langs_def 				<- store_csv_data_into_map_of_map(configuration_file["LANG_DEF_FILE"],";"); // Languages
	map<string,map> data_action 			<- store_csv_data_into_map_of_map(configuration_file["ACTION_DEF_FILE"],";"); // Actions: to use this map : data_action at ACTION_NAME at parameter (Example: data_action at 'ACTON_CREATE_DIKE' at 'cost')
		
	// Network 
	string SERVER 					<- configuration_file["SERVER_ADDRESS"]; 
	string COMMAND_SEPARATOR 		<- ":";
	string GAME_MANAGER 			<- "GAME_MANAGER";
	string GAME_LEADER	     	 	<- "GAME_LEADER";
	string LISTENER_TO_LEADER	 	<- "LISTENER_TO_LEADER";
	string UPDATE_PLAYER_ACTION   	<- "UPDATE_PLAYER_ACTION";
	string OBSERVER_MESSAGE_COMMAND <- "COMMAND_OBSERVER";
	
	// Main-Leader network communication
	string COLLECT_REC 				<- "COLLECT_RECETTE";
	string SUBSIDIZE 				<- "SUBSIDIZE";
	string LEADER_COMMAND   		<- "LEADER_COMMAND";
	string AMOUNT 					<- "AMOUNT";
	string BUDGET 					<- "BUDGET";
	string DISTRICT_CODE 			<- "DISTRICT_CODE";
	string ASK_NUM_ROUND 			<- "LEADER_ASKS_FOR_ROUND_NUMBER";
	string NUM_ROUND 				<- "ROUND_NUMBER";
	string ASK_INDICATORS_T0		<- "LEADER_ASKS_FOR_T0_IDICATORS";
	string INDICATORS_T0 			<- "INDICATORS_AT_T0";
	string RETREIVE_ACTION_STATE 	<- "RETREIVE_ACTION_STATE";
	string PLAYER_ACTION_ID 		<- "PLAYER_ACTION_ID";
	string NEW_ACTIVATED_LEVER		<- "NEW_ACTIVATED_LEVER";
	string ACTION_SHOULD_WAIT_LEVER_TO_ACTIVATE <- "ACTION_SHOULD_WAIT_LEVER_TO_ACTIVATE";
	
	// Manager-Player network communication
	string PLAYER_ACTION_IS_APPLIED <- "PLAYER_ACTION_IS_APPLIED";
	
	//50#m : surface of considered area when mouse is clicked (to retrieve which button has been clicked) 
	float MOUSE_BUFFER <-float(configuration_file["MOUSE_BUFFER"]);
	
	// Constant vars
	string LU				<- "LU";
	string COAST_DEF		<- "COAST_DEF";
	string DIKE 			<- "Dike";
	string DUNE 			<- "Dune";
	string STATUS_GOOD 		<- "Good";
	string STATUS_MEDIUM	<- "Medium";
	string STATUS_BAD 		<- "Bad";
	
	// Building dikes parameters
	string BUILT_DIKE_TYPE 		<- "New Dike";
	string BUILT_DIKE_STATUS 	<- shapes_def["BUILT_DIKE_STATUS"];
	
	// Loading GIS data
	file districts_shape 		<- file(shapes_def["COMMUNE_SHAPE"]);
	file roads_shape 			<- file(shapes_def["ROAD_SHAPE"]);
	file protected_areas_shape 	<- file(shapes_def["ZONES_PROTEGEES_SHAPE"]);
	file rpp_area_shape 		<- file(shapes_def["ZONES_PPR_SHAPE"]);
	file coastline_shape 		<- file(shapes_def["COASTLINES_SHAPE"]);
	file coastal_defenses_shape <- file(shapes_def["DEFENSES_COTES_SHAPE"]);
	file land_use_shape 		<- file(shapes_def["UNAM_SHAPE"]);	
	file emprise_shape 			<- file(shapes_def["EMPRISE_SHAPE"]); 
	file dem_file 				<- file(shapes_def["DEM_FILE"]) ;
	file contour_neg_100m_shape <- file(shapes_def["CONTOUR_ILE_INF_100M"]);
	int nb_cols 				<- int(shapes_def["DEM_NB_COLS"]);
	int nb_rows 				<- int(shapes_def["DEM_NB_ROWS"]);
	map table_correspondance_insee_com_nom 		<- eval_gaml(shapes_def["CORRESPONDANCE_INSEE_COM_NOM"]);
	map table_correspondance_insee_com_nom_rac 	<- eval_gaml(shapes_def["CORRESPONDANCE_INSEE_COM_NOM_RAC"]);
	
	// List of all possible actions to send over network
	list<int> ACTION_LIST <- [CONNECTION_MESSAGE,REFRESH_ALL,ACTION_REPAIR_DIKE,ACTION_CREATE_DIKE,ACTION_DESTROY_DIKE,ACTION_RAISE_DIKE,
							ACTION_INSTALL_GANIVELLE,ACTION_MODIFY_LAND_COVER_AU,ACTION_MODIFY_LAND_COVER_AUs,ACTION_MODIFY_LAND_COVER_A,
							ACTION_MODIFY_LAND_COVER_U,ACTION_MODIFY_LAND_COVER_Us,ACTION_MODIFY_LAND_COVER_Ui,ACTION_MODIFY_LAND_COVER_N];
	
	int ACTION_ACTION_LIST 						<- 211;
	int ACTION_DONE_APPLICATION_ACKNOWLEDGEMENT <- 51;
	int ACTION_LAND_COVER_UPDATE   				<-9;
	int ACTION_DIKE_UPDATE		   				<-10;
	int INFORM_ROUND 			   				<-34;
	int ENTITY_TYPE_CODE_COAST_DEF 				<-36;
	int ENTITY_TYPE_CODE_LU		   				<-37;
	
	// List of actions with their parameters
	int ACTION_REPAIR_DIKE 			 <- int(data_action at 'ACTION_REPAIR_DIKE' at 'action code');
	int ACTION_CREATE_DIKE 			 <- int(data_action at 'ACTION_CREATE_DIKE' at 'action code');
	int ACTION_DESTROY_DIKE 		 <- int(data_action at 'ACTION_DESTROY_DIKE' at 'action code');
	int ACTION_RAISE_DIKE 			 <- int(data_action at 'ACTION_REPAIR_DIKE' at 'action code');
	int ACTION_INSTALL_GANIVELLE 	 <- int(data_action at 'ACTION_INSTALL_GANIVELLE' at 'action code');
	int ACTION_MODIFY_LAND_COVER_AU  <- int(data_action at 'ACTION_MODIFY_LAND_COVER_AU' at 'action code');
	int ACTION_MODIFY_LAND_COVER_A 	 <- int(data_action at 'ACTION_MODIFY_LAND_COVER_A' at 'action code');
	int ACTION_MODIFY_LAND_COVER_U 	 <- int(data_action at 'ACTION_MODIFY_LAND_COVER_U' at 'action code');
	int ACTION_MODIFY_LAND_COVER_N 	 <- int(data_action at 'ACTION_MODIFY_LAND_COVER_N' at 'action code');
	int ACTION_MODIFY_LAND_COVER_AUs <- int(data_action at 'ACTION_MODIFY_LAND_COVER_AUs' at 'action code');	
	int ACTION_MODIFY_LAND_COVER_Us	 <- int(data_action at 'ACTION_MODIFY_LAND_COVER_Us' at 'action code');
	int ACTION_MODIFY_LAND_COVER_Ui  <- int(data_action at 'ACTION_MODIFY_LAND_COVER_Ui' at 'action code');
	int ACTION_EXPROPRIATION 		 <- int(data_action at 'ACTION_EXPROPRIATION' at 'action code');
	
	// Actions to acknowledge client requests
	int ACTION_DIKE_CREATED 	<- 16;
	int ACTION_DIKE_DROPPED 	<- 17;
	int UPDATE_BUDGET 			<- 19;
	int REFRESH_ALL 			<- 20;
	int ACTION_DIKE_LIST 		<- 21;
	int CONNECTION_MESSAGE 		<- 23;
	int INFORM_TAX_GAIN 		<- 24;
	int INFORM_GRANT_RECEIVED 	<- 27;
	int INFORM_FINE_RECEIVED 	<- 28;
	
	//------------------------------ Shared methods to load configuration files into maps -------------------------------//
	map<string, string> read_configuration_file(string fileName,string separator){
		map<string, string> res <- map<string, string>([]);
		string line <-"";
		loop line over:text_file(fileName){
			if(line contains(separator)){
				list<string> data <- line split_with(separator);
				add data[1] at:data[0] to:res;	
			}				
		}
		return res;
	}
	
	map<string, map> store_csv_data_into_map_of_map(string fileName,string separator){
		map<string, map> res ;
		string line <-"";
		list<string> col_labels <- [];
		loop line over:text_file(fileName){
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
	
	string label_of_action (int action_code){
		string rslt <- "";
		loop i from:0 to: (length(actions_def) /3) - 1 {
			if ((int(actions_def at {1,i})) = action_code){
				rslt <- actions_def at {0,i}; // action name
				rslt <- get_message(rslt); // action label
			}
		}
		return rslt;
	}
	
	string get_message(string code_msg){
		return langs_def at code_msg at configuration_file["LANGUAGE"]; // getting the right message from languages file
	}
	//------------------------------ End of methods -------------------------------//
}
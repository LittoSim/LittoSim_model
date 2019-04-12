/**
* Name: params_leader
* Author: 
*/

model paramsleader

import "params_all.gaml"

global{
	
	map<string,map> levers_def <- store_csv_data_into_map_of_map(configuration_file["LEVERS_DEF_FILE"], ";");		// levers configuration file

	int game_round <- 0;
	point MOUSE_LOC;
	
	// strategies
	string BUILDER 		<- "BUILDER";
	string SOFT_DEFENSE <- "SOFT_DEFENSE";
	string WITHDRAWAL 	<- "WITHDRAWAL";
	
	//actions to acknwoledge client requests.
	string MSG_TO_PLAYER 			<- "MSG_TO_PLAYER";

	string SUBSIDIZE_GANIVELLE 			<- "SUBSIDIZE_GANIVELLE";
	string SUBSIDIZE_ADAPTED_HABITAT 	<- "SUBSIDIZE_ADAPTED_HABITAT";
	
	// messages to display in multi-langs
	string MSG_CHOOSE_MSG_TO_SEND;	
	string MSG_TYPE_CUSTOMIZED_MSG;
	string MSG_TO_CANCEL; 			
	string MSG_AMOUNT;			
	string MSG_123_OR_CUSTOMIZED;
	string BTN_GET_REVENUE_MSG2;
	
	string get_lever_name(string lever_id){
		return levers_def at lever_id at configuration_file["LANGUAGE"];
	}
	string get_lever_type(string lever_id){
		return levers_def at lever_id at 'type';
	}	
}


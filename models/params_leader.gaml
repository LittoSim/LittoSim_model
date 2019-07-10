/**
* Name: params_leader
* Author: 
*/

model paramsleader

import "params_all.gaml"

global{
	string my_language;
	map<string,map> levers_def <- store_csv_data_into_map_of_map(configuration_file["LEVERS_FILE"], ";");	// levers configuration file

	int game_round <- 0;
	point MOUSE_LOC;
	
	// messages to display in multi-langs
	string MSG_CHOOSE_MSG_TO_SEND;	
	string MSG_TYPE_CUSTOMIZED_MSG;
	string MSG_TO_CANCEL; 			
	string MSG_AMOUNT;			
	string MSG_123_OR_CUSTOMIZED;
	string BTN_GET_REVENUE_MSG2;
	
	string records_folder <- "../includes/"+ application_name +"/leader_records/";
	
	string get_lever_name(string lever_id){
		return levers_def at lever_id at my_language;
	}
	
	string get_lever_type(string lever_id){
		return levers_def at lever_id at 'type';
	}
	
	string get_message(string code_msg){
		return langs_def at code_msg at my_language;
	}
}


/**
* Name: params_leader
* Author: 
*/

model paramsleader

import "params_all.gaml"

global{
	string my_language;
	map<string,map> levers_def <- store_csv_data_into_map_of_map(study_area_def["LEVERS_FILE"], ";");	// levers configuration file

	int game_round <- 0;
	point MOUSE_LOC;
	
	int GRID_W <- 4;
	int GRID_H <- 11 + int((length(levers_def) - 17)/2);
	
	// messages to display in multi-langs
	string MSG_CHOOSE_MSG_TO_SEND;	
	string MSG_TYPE_CUSTOMIZED_MSG;
	string MSG_TO_CANCEL; 			
	string MSG_AMOUNT;
	string MSG_COMMUNE;		
	string MSG_123_OR_CUSTOMIZED;
	string MSG_EXPROPRIATION;
	string LEV_MAX;
	string LEV_AT;
	string LDR_MSG_ROUNDS;
	string LEV_MSG_LEVER_HELP;
	string LDR_LAST;
	
	float PROFILING_THRESHOLD <- 0.3;
	
	string records_folder <- "../includes/"+ application_name +"/";
	
	string get_lever_name(string lever_id){
		return levers_def at lever_id at my_language;
	}
	
	string get_lever_type(string lever_id){
		return levers_def at lever_id at 'type';
	}
	
	float get_lever_threshold(string lever_id){
		return float(levers_def at lever_id at 'threshold');
	}
	
	float get_lever_cost(string lever_id){
		return float(levers_def at lever_id at 'cost');
	}
	
	int get_lever_delay(string lever_id){
		return float(levers_def at lever_id at 'delay');
	}
	
	string get_message(string code_msg){
		return code_msg = nil or code_msg = 'na'? "" : (langs_def at code_msg != nil ? langs_def at code_msg at my_language : '');
	}
}


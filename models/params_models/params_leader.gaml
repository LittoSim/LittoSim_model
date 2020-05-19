/**
* Name: params_leader
* Author: 
*/

model paramsleader

import "params_all.gaml"

global{
	string my_language; // language specific to leader interface
	map<string,map> levers_def <- store_csv_data_into_map_of_map(study_area_def["LEVERS_FILE"], ";");	// levers configuration file

	// specific parameters to leader
	int game_round <- 0;
	point MOUSE_LOC;
	// interface table dimensions (for showing levers and buttons)
	int GRID_W <- 4; // number of colomns
	// number of lines depends on the number of levers in levers.conf : this formula is correct of the current case studies
	int GRID_H <- 11 + int((length(levers_def) - 17)/2); 
	
	// repetitice messages to display in multi-langs
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
	
	// the threshold of profiling : a player is considered Builder is he has 30% of builder actions
	float PROFILING_THRESHOLD <- 0.3;
	
	// folder of saving leader data
	string records_folder <- "../includes/"+ application_name +"/";
	
	// methods to get lever information
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
	
	// gets translated messages from langs.conf
	string get_message(string code_msg){
		return code_msg = nil or code_msg = 'na'? "" : (langs_def at code_msg != nil ? langs_def at code_msg at my_language : '');
	}
}


/**
 *  LittoSIM_GEN
 *  Authors: Ahmed, Benoit, Brice, Cécilia, Elise, Etienne, Fredéric, Marion, Nicolas B, Nicolas M, Xavier 
 * 
 *  Description : LittoSIM_GEN is a participatory simulation platform implementing a serious playing-game for local authorities.
 * 				  The project aims at modeling effects of coastal flooding on urban areas and at enabling the transfer of scientific
 * 				  findings to risk managers, as well as awareness of those concerned by the risk of coastal flooding.
 * 
 * params_leader : this file contains parameters related to leader model.
 */

model paramsleader

import "params_all.gaml"

global{
	/*
	 * Reading the levers configuration file (levers.conf) to a map
	 */
	map<string,map> levers_def <- store_csv_data_into_map_of_map("../" + study_area_def["LEVERS_FILE"]);

	/*
	 * specific parameters to leader
	 */
	int game_round <- 0;
	string records_folder <- "../includes/"+ application_name +"/"; // folder of saving leader data

	/*
	 * Interface grid dimensions (for showing levers and buttons)
	 */
	int GRID_W <- 4; // number of colomns
	// number of lines depends on the number of levers in levers.conf : this formula is correct of the current case studies
	int GRID_H <- 11 + int((length(levers_def) - 17)/2); 
	
	/*
	 * the threshold of profiling : a player is considered Builder if he has 30% of builder actions
	 */
	float PROFILING_THRESHOLD <- 0.3;
	/*
	 * get lever information for its ID
	 */
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
	/*
	 * repetitice messages to display in leader
	 */
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
}


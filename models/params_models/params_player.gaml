/**
* Name: paramsmain
* Author: 
*/

model paramsmain

import "params_all.gaml"

global{
		
	string DISPLAY_FONT_NAME <- "Helvetica Neue";
	int DISPLAY_FONT_SIZE <- 16;
	
	map table_correspondance_nom_rac_insee_com <- reverse(table_correspondance_insee_com_nom_rac);
		
	// Player actions
	int ACTION_DISPLAY_PROTECTED_AREA <- int(data_action at 'ACTION_DISPLAY_PROTECTED_AREA' at 'action code');
	int ACTION_DISPLAY_FLOODED_AREA <- int(data_action at 'ACTION_DISPLAY_FLOODED_AREA' at 'action code');
	int ACTION_INSPECT_DIKE  <- int(data_action at 'ACTION_INSPECT_DIKE' at 'action code');
	int ACTION_INSPECT_LAND_USE  <- int(data_action at 'ACTION_INSPECT_LAND_USE' at 'action code');
	
	// Leviers from leader
	int SUBVENTIONNER_GANIVELLE <- 1101;
	int SUBVENTIONNER_HABITAT_ADAPTE <- 1102;
	int SANCTION_ELECTORALE <- 1103;
	int HAUSSE_COUT_DIGUE <- 1104;
	int HAUSSE_REHAUSSEMENT_DIGUE <- 1105;
	int HAUSSE_RENOVATION_DIGUE <- 1106;
	int HAUSSE_COUT_BATI <- 1107;
	
	string ACTION_ID <- "action_id";
	string DATA <- "data";
	string PLAYER_MSG <-"player_msg";
	string UNAM_DISPLAY <- "UnAm";

	// User messages
	string MSG_POSSIBLE_REGLEMENTATION_DELAY <- get_message('MSG_POSSIBLE_REGLEMENTATION_DELAY');
	string INFORMATION_MESSAGE <- "INFORMATION_MESSAGE";
	string BUDGET_MESSAGE <- "BUDGET_MESSAGE";
	string POPULATION_MESSAGE <- "POPULATION_MESSAGE";
	
	string LEGEND_UNAM <- get_message('LEGEND_UNAM');
	string LEGEND_DYKE <- get_message('LEGEND_DYKE');
	
	int BASKET_MAX_SIZE <- 7;
	
	int MAX_HISTORY_VIEW_SIZE <- 10;
	
	point INFORMATION_BOX_SIZE <- {200,80};
	
	string DIKE_DISPLAY <- "sloap";
	string BOTH_DISPLAY <- "both";
	
	// Messages à affichier en multilangues
	string MSG_WARNING <- get_message('MSG_WARNING');
}


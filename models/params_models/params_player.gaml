/**
* Name: paramsmain
* Author: 
*/

model paramsmain

import "params_all.gaml"

global{
		
	string DISPLAY_FONT_NAME <- "Helvetica Neue";
	int DISPLAY_FONT_SIZE 	 <- 16;
	
	// Player actions
	int ACTION_DISPLAY_PROTECTED_AREA 	<- int(data_action at 'ACTION_DISPLAY_PROTECTED_AREA' 	at 'action code');
	int ACTION_DISPLAY_FLOODED_AREA 	<- int(data_action at 'ACTION_DISPLAY_FLOODED_AREA' 	at 'action code');
	int ACTION_INSPECT_DIKE  			<- int(data_action at 'ACTION_INSPECT_DIKE' 			at 'action code');
	int ACTION_INSPECT_LAND_USE  		<- int(data_action at 'ACTION_INSPECT_LAND_USE' 		at 'action code');
	
	string PLAYER_MSG 	<- "PLAYER_MSG";
	
	// Levers from leader
	int SUBVENTIONNER_GANIVELLE 		<- 1101;
	int SUBVENTIONNER_HABITAT_ADAPTE 	<- 1102;
	int SANCTION_ELECTORALE 			<- 1103;
	int HAUSSE_COUT_DIGUE 				<- 1104;
	int HAUSSE_REHAUSSEMENT_DIGUE 		<- 1105;
	int HAUSSE_RENOVATION_DIGUE 		<- 1106;
	int HAUSSE_COUT_BATI 				<- 1107;
	
	// Displays
	string PLU_DISPLAY 	<- "PLU";
	string DIKE_DISPLAY <- "DIKE";
	string BOTH_DISPLAY <- "BOTH";

	// Received user messages type
	string INFORMATION_MESSAGE 	<- "INFORMATION_MESSAGE";
	string BUDGET_MESSAGE 		<- "BUDGET_MESSAGE";
	string POPULATION_MESSAGE 	<- "POPULATION_MESSAGE";
	
	int BASKET_MAX_SIZE 		<- 7;
	int MAX_HISTORY_VIEW_SIZE 	<- 10;
	point INFORMATION_BOX_SIZE 	<- {200,80};	

	// Multi-langs
	string LEGEND_PLU_NAME;
	string LEGEND_DYKE_NAME;
	string MSG_WARNING;
	string MSG_POSSIBLE_REGLEMENTATION_DELAY;
	string MSG_SIM_NOT_STARTED;
	
}


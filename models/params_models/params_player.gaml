/**
* Name: paramsmain
* Author: 
*/

model paramsmain

import "params_all.gaml"

global{
	string my_language;
	string DISTRICT_AT_TOP 	 <- string(shapes_def["DISTRICT_AT_TOP"]);
	string DISPLAY_FONT_NAME <- "Helvetica Neue";
	int DISPLAY_FONT_SIZE 	 <- 16;
	
	// Player actions
	int ACTION_DISPLAY_PROTECTED_AREA 	<- int(data_action at 'ACTION_DISPLAY_PROTECTED_AREA' at 'action_code');
	int ACTION_DISPLAY_FLOODED_AREA 	<- int(data_action at 'ACTION_DISPLAY_FLOODED_AREA'   at 'action_code');
	int ACTION_DISPLAY_FLOODING 		<- int(data_action at 'ACTION_DISPLAY_FLOODING' 	  at 'action_code');
	int ACTION_INSPECT		  			<- int(data_action at 'ACTION_INSPECT' 		  		  at 'action_code');
	
	// map tab displays
	string LU_DISPLAY 		 <- "LU_DISPLAY";
	string COAST_DEF_DISPLAY <- "COAST_DEF_DISPLAY";
	string BOTH_DISPLAYS 	 <- "BOTH_DISPLAYS";
	// gama displays
	string GAMA_BASKET_DISPLAY 	<- "Basket";
	string GAMA_MAP_DISPLAY		<- "Map";
	string GAMA_HISTORY_DISPLAY <- "History";
	string GAMA_MESSAGES_DISPLAY<- "Messages";

	// Received user messages type
	string INFORMATION_MESSAGE 	<- "INFORMATION_MESSAGE";
	string BUDGET_MESSAGE 		<- "BUDGET_MESSAGE";
	string POPULATION_MESSAGE 	<- "POPULATION_MESSAGE";
	
	int BASKET_MAX_SIZE 		<- 15;
	int MAX_HISTORY_VIEW_SIZE 	<- 10;
	point INFORMATION_BOX_SIZE 	<- {200,80};

	// Multi-langs
	string MSG_WARNING;
	
	string get_message(string code_msg){
		return code_msg = 'na' ? "" : langs_def at code_msg at my_language;
	}
	
}


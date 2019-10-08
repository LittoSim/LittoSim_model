/**
* Name: paramsmain
* Author: 
*/

model paramsmain

import "params_all.gaml"

global{
	string my_language;
	string DISTRICT_AT_TOP 	 <- study_area_def["DISTRICT_AT_TOP"];
	string DISPLAY_FONT_NAME <- "Helvetica Neue";
	int DISPLAY_FONT_SIZE 	 <- 16;
	
	// Player actions
	int ACTION_DISPLAY_PROTECTED_AREA 	<- int(data_action at 'ACTION_DISPLAY_PROTECTED_AREA' at 'action_code');
	int ACTION_DISPLAY_FLOODED_AREA 	<- int(data_action at 'ACTION_DISPLAY_FLOODED_AREA'   at 'action_code');
	int ACTION_DISPLAY_FLOODING 		<- int(data_action at 'ACTION_DISPLAY_FLOODING' 	  at 'action_code');
	int ACTION_INSPECT		  			<- int(data_action at 'ACTION_INSPECT' 		  		  at 'action_code');
	int ACTION_HISTORY		  			<- int(data_action at 'ACTION_HISTORY' 		  		  at 'action_code');
	
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
	string PLY_MSG_INFO_AB;
	string PLY_MSG_LENGTH;
	string PLY_MSG_ALTITUDE;
	string PLY_MSG_HEIGHT;
	string PLY_MSG_STATE;
	string PLY_MSG_SLICES;
	string MSG_RUPTURE;
	string MSG_BREACH;
	string MSG_NO;
	string MSG_YES;
	string MSG_DIKE;
	string MSG_DUNE;
	string MSG_CORD;
	string PLY_MSG_HIST_AB;
	string PLY_MSG_LAND_USE;
	string PLY_MSG_STATE_CHANGE;
	string MSG_POPULATION;
	string MSG_EXPROPRIATION;
	string MSG_TYPE_N;
	string MSG_TYPE_U;
	string MSG_TYPE_AU;
	string MSG_TYPE_A;
	string MSG_TYPE_Us;
	string MSG_TYPE_AUs;
	string PLY_MSG_APP_ROUND;
	string MSG_COST_EXPROPRIATION;
	string MSG_COST_ACTION;
	string PLY_MSG_GOOD;
	string PLY_MSG_BAD;
	string PLY_MSG_MEDIUM;
	string MSG_COST_APPLIED_PARCEL;
	string PLY_MSG_WATER_H;
	string PLY_MSG_WATER_M;
	string MSG_YOUR_BUDGET;
	string PLR_VALIDATE_BASKET;
	string PLR_CHECK_BOX_VALIDATE;
	string MSG_HAS_STARTED;
	string MSG_DISTRICT_RECEIVE;
	string MSG_DISTRICT_LOSE;
	string MSG_NEW_COMERS;
	string MSG_DISTRICT_POPULATION;
	string MSG_INHABITANTS;
	
	string get_message(string code_msg){
		return code_msg = nil or code_msg = 'na'? "" : (langs_def at code_msg != nil ? langs_def at code_msg at my_language : '');
	}
	
}


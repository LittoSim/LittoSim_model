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
	int ACTION_MESSAGE 	<- 22;
	
	string MSG_TO_PLAYER 			<- "MSG_TO_PLAYER";

	string REORGANISATION_AFFICHAGE <- "Réorganiser l'affichage";
	string ABROGER 					<- "Abroger";
	string RETARDER 				<- "Retarder";
	string RETARD_1_AN 				<- "Retarder pour 1 an";
	string RETARD_2_ANS 			<- "Retarder pour 2 ans";
	string RETARD_3_ANS	 			<- "Retarder pour 3 ans";
	string LEVER_RETARD 			<- "Lever les retards";
	string DELAY 					<- "delay";
	string ACTION_ID 				<- "action_id";
	string DATA 					<- "data";
	
	
	string SUBSIDIZE_GANIVELLE 		<- "SUBSIDIZE_GANIVELLE";
	string SUBSIDIZE_ADAPTED_HABITAT 	<- "SUBSIDIZE_ADAPTED_HABITAT";

	int SUBVENTIONNER_GANIVELLE 		<- 1101;
	int SUBVENTIONNER_HABITAT_ADAPTE 	<- 1102;
	int SANCTION_ELECTORALE 			<- 1103;
	int HAUSSE_COUT_DIGUE 				<- 1104;
	int HAUSSE_REHAUSSEMENT_DIGUE 		<- 1105;
	int HAUSSE_RENOVATION_DIGUE 		<- 1106;
	int HAUSSE_COUT_BATI 				<- 1107;
	
	// messages to display in multi-langs
	string MSG_CHOOSE_MSG_TO_SEND;	
	string MSG_TYPE_CUSTOMIZED_MSG;
	string MSG_TO_CANCEL; 			
	string MSG_AMOUNT;			
	string MSG_123_OR_CUSTOMIZED;
	string BTN_GET_REVENUE_MSG2;
}


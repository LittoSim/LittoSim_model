/**
* Name: paramsleader
* Author: 
*/

model paramsleader

import "params_all.gaml"

global{	
	point MOUSE_LOC ;
	
	//le fichier de configuration des leviers
	map<string,map> levers_def <- store_csv_data_into_map_of_map(configuration_file["LEVERS_DEF_FILE"],";");

	bool log_user_action <- true;
	bool activemq_connect <- true;
	int round<-0;
	
	string BATISSEUR <- "builder";
	string DEFENSE_DOUCE <- "soft defense";
	string RETRAIT <- "withdrawal";
	
	//actions to acknwoledge client requests.
	int ACTION_MESSAGE <- 22;

	string REORGANISATION_AFFICHAGE <- "Réorganiser l'affichage";
	string ABROGER <- "Abroger";
	string PRELEVER <- "Percevoir Recette";
	string CREDITER <- "Subventionner";
	string RETARDER <- "Retarder";
	string RETARD_1_AN <- "Retarder pour 1 an";
	string RETARD_2_ANS <- "Retarder pour 2 ans";
	string RETARD_3_ANS <- "Retarder pour 3 ans";
	string LEVER_RETARD <- "Lever les retards";
	string DELAY <- "delay";
	string ACTION_ID <- "action_id";
	string DATA <- "data";
	string PLAYER_MSG <-"player_msg";
	string MSG_TO_PLAYER <-"Message au joueur";
	string COMMUNE <- "COMMUNE_ID";

	//	string LEVER_DIKE_CREATION <- "Construit des digues";
	//	string LEVER_RAISE_DIKE <- "Rehausse les digues";
	//	string LEVER_REPAIR_DIKE <- "Renove les digues";
	//	string LEVER_AUorUi_inCoastBorderArea <- "Construit ou densifie non adapté en ZL";
	//	string LEVER_AUorUi_inRiskArea <- "Construit ou densifie en ZI";
	//	string LEVER_GANIVELLE <- "Construit des ganivelles";
	//	string LEVER_Us_outCoastBorderOrRiskArea <- "Habitat adapté hors ZL et ZI";
	//	string LEVER_Us_inCoastBorderArea <- "Habitat adapté en ZL";

	int SUBVENTIONNER_GANIVELLE <- 1101;
	int SUBVENTIONNER_HABITAT_ADAPTE <- 1102;
	int SANCTION_ELECTORALE <- 1103;
	int HAUSSE_COUT_DIGUE <- 1104;
	int HAUSSE_REHAUSSEMENT_DIGUE <- 1105;
	int HAUSSE_RENOVATION_DIGUE <- 1106;
	int HAUSSE_COUT_BATI <- 1107;
	string SUBVENTIONNER_GANIVELLE_NAME <- "Subventionner ganivelle";
	string SUBVENTIONNER_HABITAT_ADAPTE_NAME <- "Subventionner habitat adapté";
	/*string SANCTION_ELECTORALE <- "Appliquer une sanction électorale";
	string HAUSSE_COUT_DIGUE <- "Hausse du coût de construction des digues";
	string HAUSSE_REHAUSSEMENT_DIGUE <- "Hausse du coût de réhaussement des digues";
	string HAUSSE_RENOVATION_DIGUE <- "Hausse du coût de rénovation des digues";
	string HAUSSE_COUT_BATI <- "Hausse du coût de construction du bâti";*/
	
	// messages to display in multi-lang
	string MSG_CHOOSE_MSG_TO_SEND 	<- get_message('MSG_CHOOSE_MSG_TO_SEND');
	string MSG_TYPE_CUSTOMIZED_MSG 	<- get_message('MSG_TYPE_CUSTOMIZED_MSG');
	string MSG_TO_CANCEL 			<- get_message('MSG_TO_CANCEL');
	string MSG_AMOUNT 				<- get_message('MSG_AMOUNT');
	string MSG_123_OR_CUSTOMIZED 	<- get_message('MSG_123_OR_CUSTOMIZED');
	string BTN_GET_REVENUE_MSG2		<- get_message('BTN_GET_REVENUE_MSG2');
	
}


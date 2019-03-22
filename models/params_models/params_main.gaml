/**
* Name: paramsmain
* Author: 
*/

model paramsmain

import "params_all.gaml"

global{
	
	////////// LES MESSAGES A AFFICHER EN MULTILANGUES //////////
	string MSG_NEW_ROUND <- langs_def at 'MSG_NEW_ROUND' at configuration_file["LANGUAGE"];
	string MSG_GAME_DONE <- langs_def at 'MSG_GAME_DONE' at configuration_file["LANGUAGE"];
	string MSG_LOG_USER_ACTION <- langs_def at 'MSG_LOG_USER_ACTION' at configuration_file["LANGUAGE"];
	string MSG_CONNECT_ACTIVMQ <- langs_def at 'MSG_LOG_USER_ACTION' at configuration_file["LANGUAGE"];
	string MSG_NO_FLOOD_FILE_EVENT <- langs_def at 'MSG_NO_FLOOD_FILE_EVENT' at configuration_file["LANGUAGE"];
	string MSG_OK_CONTINUE <- langs_def at 'MSG_OK_CONTINUE' at configuration_file["LANGUAGE"];
	string MSG_SUBMERSION_NUMBER <- langs_def at 'MSG_SUBMERSION_NUMBER' at configuration_file["LANGUAGE"];
	string MSG_NUMBER <- langs_def at 'MSG_NUMBER' at configuration_file["LANGUAGE"];
	
	////////// CONFIGURATION LITTOSIM_GEN //////////
	// Paramètres de Communication Network 
	string GAME_LEADER <- "GAME_LEADER";
	string UPDATE_ACTION_DONE <- "update_action_done";
	string OBSERVER_MESSAGE_COMMAND <- "observer_command";
	
	////////// PARAMETRES DES MODULES //////////
	// Paramètres des actions de construction et de réhaussement de digues
	float BUILT_DIKE_HEIGHT <- float(shapes_def["BUILT_DIKE_HEIGHT"]); ////// hauteur d'une nouvelle digue	
	float RAISE_DIKE_HEIGHT <- float(shapes_def["RAISE_DIKE_HEIGHT"]); // le réhaussement d'ouvrage est par défaut de 1 mètre. Il ne peut pas être changé en cours de simulation
	
	// Paramètres de la dynamique d'évolution des défenses côtes (défense côte = digues et dunes)
	float H_MAX_GANIVELLE <- float(shapes_def["H_MAX_GANIVELLE"]); // ganivelle  d'une hauteur de 1.2 metres  -> fixe le maximum d'augmentation de hauteur de la dune
	float H_DELTA_GANIVELLE <- float(shapes_def["H_DELTA_GANIVELLE"]); // une ganivelle  augmente de 5 cm par an la hauteur du cordon dunaire
	int STEPS_DEGRAD_STATUS_OUVRAGE <- int(shapes_def["STEPS_DEGRAD_STATUS_OUVRAGE"]); // Sur les ouvrages il faut 8 ans pour que ça change de statut
	int STEPS_DEGRAD_STATUS_DUNE <-int(shapes_def["STEPS_DEGRAD_STATUS_DUNE"]); // Sur les dunes, sans ganivelle,  il faut 6 ans pour que ça change de statut
	int STEPS_REGAIN_STATUS_GANIVELLE  <-int(shapes_def["STEPS_REGAIN_STATUS_GANIVELLE"]); // Avec une ganivelle ça se régénère 2 fois plus vite que ça ne se dégrade

	// Paramètres de rupture des défenses côtes
	int PROBA_RUPTURE_DIGUE_ETAT_MAUVAIS <- int(shapes_def["PROBA_RUPTURE_DIGUE_ETAT_MAUVAIS"]);
	int PROBA_RUPTURE_DIGUE_ETAT_MOYEN <- int(shapes_def["PROBA_RUPTURE_DIGUE_ETAT_MOYEN"]);
	int PROBA_RUPTURE_DIGUE_ETAT_BON <- int(shapes_def["PROBA_RUPTURE_DIGUE_ETAT_BON"]); // si -1, alors  impossible
	int PROBA_RUPTURE_DUNE_ETAT_MAUVAIS <- int(shapes_def["PROBA_RUPTURE_DUNE_ETAT_MAUVAIS"]);
	int PROBA_RUPTURE_DUNE_ETAT_MOYEN <- int(shapes_def["PROBA_RUPTURE_DUNE_ETAT_MOYEN"]);
	int PROBA_RUPTURE_DUNE_ETAT_BON <- int(shapes_def["PROBA_RUPTURE_DUNE_ETAT_BON"]); // si -1, alors  impossible
	int RADIUS_RUPTURE <- int(shapes_def["RADIUS_RUPTURE"]); // en mètres. Etendu de la rupture sur les éléments

	//  Paramètres démographiques
	int POP_FOR_NEW_U <- int(shapes_def["POP_FOR_NEW_U"]) ; // Nb initial d'habitants pour les cases qui viennent de passer de AU à U
	int POP_FOR_U_DENSIFICATION <- int(shapes_def["POP_FOR_U_DENSIFICATION"]) ; // Nb de nouveaux habitants par tour pour les cases qui ont une action densification
	int POP_FOR_U_STANDARD <- int(shapes_def["POP_FOR_U_STANDARD"]) ; // Nb de nouveaux habitants par tour pour les autres cases
	float ANNUAL_POP_GROWTH_RATE <- float(eval_gaml(shapes_def["ANNUAL_POP_GROWTH_RATE"])); // la croissance démographique
	// Ajustement des données de population
	int minPopUArea <- int(eval_gaml(shapes_def["MIN_POPU_AREA"])); // Unit = abs pop. In case the population of a UA of type U (Urban area) is equal at zero at initialization (due to a mismatch between the unAm_shape file and the population data), the pop of the UA is rewrite to the minPopUArea value
	
	// Paramètres de rugosité des Unités d'Aménagement (UA)
	float RUGOSITY_N <- float(shapes_def["RUGOSITY_N"]); 	//  Ds la V1 c'était 0.05 mais selon MA et NB ce n'était pas cohérent car N est sensé freiner l'inondation. Selon MA et NB c'est  0.11
	float RUGOSITY_U <-float(shapes_def["RUGOSITY_U"]);	//  Ds la V1 c'était 0.12 mais selon MA et NB ce n'était pas cohérent car U est sensé faire glisser l'eau. Selon MA et NB c'est 0.05
	float RUGOSITY_AU <- float(shapes_def["RUGOSITY_AU"]); 	//  Ds la V1 c'était 0.1 mais selon MA et NB ce n'était pas cohérent car AU n'est pas sensé freiner autant l'eau que N. Selon MA et NB c'est 0.09							->selon MA et NB  0.09
	float RUGOSITY_A <- float(shapes_def["RUGOSITY_A"]);	// Ds la V1 c'était 0.06 mais selon MA et NB ce n'était pas cohérent car le A d'oélron correspond plus à Landes (code CLC 322) ou Vignes (code CLC 221) qui font 0.07, et pas vraiement à Prairies (code CLC 241)  qui fait 0.04. Selon MA et NB c'est 0.07
	float RUGOSITY_AUs <- float(shapes_def["RUGOSITY_AUs"]);  // Selon MA et NB et la CdC, l'habitat adapté va freiner un peu l'inondation. Donc 0.09
	float RUGOSITY_Us <- float(shapes_def["RUGOSITY_Us"]);   // Selon MA et NB et la Cd
	string RUGOSITE_PAR_DEFAUT <- shapes_def["RUGOSITE_PAR_DEFAUT"];
	
	////////// CONFIGURATION DE LA ZONE D'ETUDE //////////
	// Budgets des communes	
	map impot_unit_table <- eval_gaml(shapes_def["IMPOT_UNIT_TABLE"]); // impot_unit correspond au montant en Boyard (monnaie du jeu) reçu pour chaque habitant de la population d'une commune. 
	// La valeur de impot unit est de 0.42 par défaut.  0.42 Boyard /hab correspond à  21 € / hab   // Le taux entre le Boyard et l'Euros est de 50. Ce taux a été estimé à partir du cout de construction d'un mètre linéaire de digue. Dans le jeu ça vaut 20 alors que dans la réalité ça vaut 1000 € (donc facteur 50 / impot_unit = 21/50= 0.42) 
	// Ajustement pour réduire un peu les écarts -> 0.42 de base et 0.38 pour stpierre et 0.9 pour sttrojan		
	int pctBudgetInit <- int(eval_gaml(shapes_def["PCT_BUDGET_TABLE"])); ///Unit = int in %. During the initialization phase, each commune initiate with a budget equal to an annual tax +  % here 20%
	//Définition de la largeur de la zone littoral (à des conséquences sur le déclenchement des leviers par le modèle Leader
	float coastBorderBuffer <- float(eval_gaml(shapes_def["COAST_BORDER_BUFFER"])); //  Largeur de la zone littorale (<400m) à partir du trait de cote
		
	// Récupération des couts
	int ACTION_COST_LAND_COVER_TO_A <- int(data_action at 'ACTION_MODIFY_LAND_COVER_A' at 'cost');
	int ACTION_COST_LAND_COVER_TO_AU <- int(data_action at 'ACTION_MODIFY_LAND_COVER_AU' at 'cost');
	int ACTION_COST_LAND_COVER_FROM_AU_TO_N <- int(data_action at 'ACTON_MODIFY_LAND_COVER_FROM_AU_TO_N' at 'cost');
	int ACTION_COST_LAND_COVER_FROM_A_TO_N <- int(data_action at 'ACTON_MODIFY_LAND_COVER_FROM_A_TO_N' at 'cost');
	int ACTION_COST_DIKE_CREATE <- int(data_action at 'ACTION_CREATE_DIKE' at 'cost');
	int ACTION_COST_DIKE_REPAIR <- int(data_action at 'ACTION_REPAIR_DIKE' at 'cost');
	int ACTION_COST_DIKE_DESTROY <- int(data_action at 'ACTION_DESTROY_DIKE' at 'cost');
	int ACTION_COST_DIKE_RAISE <- int(data_action at 'ACTION_RAISE_DIKE' at 'cost');
	float ACTION_COST_INSTALL_GANIVELLE <- float(data_action at 'ACTION_INSTALL_GANIVELLE' at 'cost'); 
	int ACTION_COST_LAND_COVER_TO_AUs <- int(data_action at 'ACTION_MODIFY_LAND_COVER_AUs' at 'cost');
	int ACTION_COST_LAND_COVER_TO_Us <- int(data_action at 'ACTION_MODIFY_LAND_COVER_Us' at 'cost');
	int ACTION_COST_LAND_COVER_TO_Ui <- int(data_action at 'ACTION_MODIFY_LAND_COVER_Ui' at 'cost');
	int ACTION_COST_LAND_COVER_TO_AUs_SUBSIDY <- int(data_action at 'ACTION_MODIFY_LAND_COVER_AUs_SUBSIDY' at 'cost');
	int ACTION_COST_LAND_COVER_TO_Us_SUBSIDY <- int(data_action at 'ACTION_MODIFY_LAND_COVER_Us_SUBSIDY' at 'cost');
	
	////////// PARAMETRES UTILISATEUR //////////
	// Sauvegarde des logs des joueurs : OUI / NON
	bool log_user_action <- bool(configuration_file["LOG_USER_ACTION"]);
	// Sauvegarde des résultats au format SHP : OUI / NON
	bool sauver_shp <- bool(configuration_file["SAVE_SHP"]); // si vrai on sauvegarde  à chaque tour, un shapefile avec l'élevation et le niveau d'eau de toutes les cells 
	// Paramètre utilisé pour une tentative infructueuse de permettre à l'utilisateur de lancer la simulation sans activemq : OUI / NON
	bool activemq_connect <- bool(configuration_file["ACTIVEMQ_CONNECT"]);
	// Paramètres des interfaces utilisateur
	float button_size <- float(configuration_file["BUTTON_SIZE"]); //2000#m;
	int font_size <- int(shape.height/30); 	// Police de caractère de l'interface de suivi des actions
	int font_interleave <- int(shape.width/60);  // Police de caractère de l'interface de suivi des actions
}


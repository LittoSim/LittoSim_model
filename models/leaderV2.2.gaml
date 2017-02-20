/**
* Name: leader
* Author: nicolas
* Description: 
* Tags: Tag1, Tag2, TagN
*/

model leader





global
{
	
	string SERVER <- "localhost";
	float MOUSE_BUFFER <- 50#m;
	string COMMAND_SEPARATOR <- ":";
	string OBSERVER_NAME <- "model_observer";
	string GAME_LEADER_MANAGER <- "GAME_LEADER_MANAGER";
	string GROUP_NAME <- "Oleron";  
	string BUILT_DIKE_TYPE <- "nouvelle digue"; // Type de nouvelle digue
	float  STANDARD_DIKE_SIZE <- 1.5#m; ////// hauteur d'une nouvelle digue	
	string BUILT_DIKE_STATUS <- "bon"; // status de nouvelle digue
	string LOG_FILE_NAME <- "log_"+machine_time+"csv";
	float START_LOG <- machine_time; 
	bool log_user_action <- true;
	bool activemq_connect <- true;
	int round<-0;		
		
	string UPDATE_ACTION_DONE <- "update_action_done";
	string OBSERVER_MESSAGE_COMMAND <- "observer_command";
	
		
	int ACTION_REPAIR_DIKE <- 5;
	int ACTION_CREATE_DIKE <- 6;
	int ACTION_DESTROY_DIKE <- 7;
	int ACTION_RAISE_DIKE <- 8;
	int ACTION_INSTALL_GANIVELLE <- 29;

	int ACTION_MODIFY_LAND_COVER_AU <- 1;
	int ACTION_MODIFY_LAND_COVER_A <- 2;
	int ACTION_MODIFY_LAND_COVER_U <- 3;
	int ACTION_MODIFY_LAND_COVER_N <- 4;
	int ACTION_MODIFY_LAND_COVER_AUs <-31;	
	int ACTION_MODIFY_LAND_COVER_Us <-32;
	int ACTION_MODIFY_LAND_COVER_Ui <-311;
	int ACTION_EXPROPRIATION <- 9999; // codification spéciale car en fait le code n'est utilisé que pour aller chercher le delai d'exection dans le fichier csv
	list<int> ACTION_LIST <- [CONNECTION_MESSAGE,ACTION_MESSAGE,REFRESH_ALL,ACTION_REPAIR_DIKE,ACTION_CREATE_DIKE,ACTION_DESTROY_DIKE,ACTION_RAISE_DIKE,ACTION_INSTALL_GANIVELLE,ACTION_MODIFY_LAND_COVER_AU,ACTION_MODIFY_LAND_COVER_AUs,ACTION_MODIFY_LAND_COVER_A,ACTION_MODIFY_LAND_COVER_U,ACTION_MODIFY_LAND_COVER_Us,ACTION_MODIFY_LAND_COVER_N];
	
			
	int ACTION_LAND_COVER_UPDATE<-9;
	int ACTION_DIKE_UPDATE<-10;
	int INFORM_ROUND <-34;
	int NOTIFY_DELAY <-35;
	int ENTITY_TYPE_CODE_DEF_COTE <-36;
	int ENTITY_TYPE_CODE_UA <-37;
	
	
	//action to acknwoledge client requests.
//	int ACTION_DIKE_REPAIRED <- 15;
	int ACTION_DIKE_CREATED <- 16;
	int ACTION_DIKE_DROPPED <- 17;
//	int ACTION_DIKE_RAISED <- 18;
	int UPDATE_BUDGET <- 19;
	int REFRESH_ALL <- 20;
	int ACTION_DIKE_LIST <- 21;
	int ACTION_MESSAGE <- 22;
	int CONNECTION_MESSAGE <- 23;
	int INFORM_TAX_GAIN <-24;
	int INFORM_GRANT_RECEIVED <-27;
	int INFORM_FINE_RECEIVED <-28;
	/*int ACTION_CLOSE_PENDING_REQUEST <- 30;*/

	int VALIDATION_ACTION_MODIFY_LAND_COVER_AU <- 11; // Not used. Should detele ?
	int VALIDATION_ACTION_MODIFY_LAND_COVER_A <- 12;// Not used. Should detele ?
	int VALIDATION_ACTION_MODIFY_LAND_COVER_U <- 13;// Not used. Should detele ?
	int VALIDATION_ACTION_MODIFY_LAND_COVER_N <- 14;// Not used. Should detele ?
	
	
	file communes_shape <- file("../includes/zone_etude/communes.shp");
	matrix<string> actions_def <- matrix<string>(csv_file("../includes/actions_def.csv",";"));	
	
	
	commune selected_commune <- nil;
	action_button selected_action <- nil;
	action_done selection_action_done;
	
	
	string current_selected_action -> {selected_action!= nil? selected_action.displayName:"NAN"};
	
	string REORGANISATION_AFFICHAGE <- "Réorganiser l'affichage";
	string ABROGER <- "Abroger";
	string RECETTE <- "Percevoir Recette";
	string SUBVENTIONNER <- "Subventionner";
	string RETARDER <- "Retarder";
	string RETARD_1_AN <- "Retarder pour 1 an";
	string RETARD_2_ANS <- "Retarder pour 2 ans";
	string RETARD_3_ANS <- "Retarder pour 3 ans";
	string LEVER_RETARD <- "Lever les retards";
	string LEADER_COMMAND <- "leader_command";
	string AMOUNT <- "amount";
	string DELAY <- "delay";
	string ACTION_ID <- "action_id";
	string DATA <- "data";
	string PLAYER_MSG <-"player_msg";
	string COMMUNE <- "COMMUNE_ID";
	string ASK_NUM_ROUND <- "Leader demande numero du tour";
	string NUM_ROUND <- "Numero du tour";
	string ASK_INDICATORS_T0 <- "Leader demande Indicateurs a t0";
	string INDICATORS_T0 <- 'Indicateurs a t0';
	string LEVER_DIKE_CREATION <- "Construit des digues";
	string LEVER_RAISE_DIKE <- "Rehausse les digues";
	string LEVER_REPAIR_DIKE <- "Renove les digues";
	string LEVER_AUorUi_inCoastBorderArea <- "Construit ou densifie non adapté en ZL";
	string LEVER_AUorUi_inRiskArea <- "Construit ou densifie en ZI";
	string LEVER_GANIVELLE <- "Construit des ganivelles";
	string LEVER_Us_outCoastBorderOrRiskArea <- "Habitat adapté hors ZL et ZI";
	
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
	

	
	bool reorganisation_affichage -> {selected_action!= nil and selected_action.displayName= "Réorganiser l'affichage"};
	bool imposer -> {selected_action!= nil and selected_action.displayName= "Imposer"};
	bool subventionner -> {selected_action!= nil and selected_action.displayName= "Subventionner"};
	bool lever_retard -> {selected_action!= nil and selected_action.displayName= "Lever les retards"}; 
	bool subventionner_ganivelle -> {selected_action!= nil and selected_action.displayName= "Subventionner ganivelle"};
	bool subventionner_habitat_adapte -> {selected_action!= nil and selected_action.displayName= "Subventionner habitat adapté"};
	
	geometry shape <- square(100#m);
	
	string BATISSEUR <- "batisseur";
	string DEFENSE_DOUCE <- "défense douce";
	string RETRAIT <- "retrait";
	
	
	
	map<string,list<map<string,int>>> profils<-[];
	
	action write_profile
	{
		int i <- 0;

		string cm<-"";
		loop cm over:profils.keys
		{
			list<map<string,int>> data_commune <- profils[cm];
			
			write "commune : "+ cm;
			loop while:length(data_commune)>i
			{
				map<string,int> state <- data_commune[i];
				write "tour["+i +"] " + BATISSEUR+": "+state[BATISSEUR]+" ; "+DEFENSE_DOUCE+": "+state[DEFENSE_DOUCE]+" ; "+RETRAIT+": "+state[RETRAIT];
				i<-i+1;
			}
				
		}

	}
	
	
	action add_action_done_to_profile(action_done act_dn, int act_round)
	{
		list<map<string,int>> profil_commune<- profils[act_dn.commune_name];
		loop while:length(profil_commune)<=act_round
		{
			map<string,int> state <- [];
			put 0 key:BATISSEUR in: state;
			put 0 key:DEFENSE_DOUCE in: state;
			put 0 key:RETRAIT in: state;
			add state to:profil_commune;
		}
		map<string,int> chosen_round <- profil_commune[act_round];
	//	write "action de type "+ act_dn.tracked_profil + " : "+ chosen_round[act_dn.tracked_profil]; // ToDO NM A voir si il n'y a pas un bug ici
		put chosen_round[act_dn.tracked_profil] +1 key:act_dn.tracked_profil in: chosen_round;
	}
	
	
	string UA_name_of_command (int act) {
		switch act {
			match ACTION_MODIFY_LAND_COVER_AU {return "AU";}
			match ACTION_MODIFY_LAND_COVER_A {return "A";}
			match ACTION_MODIFY_LAND_COVER_U {return "U";}
			match ACTION_MODIFY_LAND_COVER_N {return "N";}
			match ACTION_MODIFY_LAND_COVER_AUs {return "AUs";}
			match ACTION_MODIFY_LAND_COVER_Us {return "Us";}
			match ACTION_MODIFY_LAND_COVER_Ui {return "Ui";}
			match ACTION_EXPROPRIATION {return "N";}
			}
	}
	
	string dike_label_of_command (int act) {
		switch act {
			match ACTION_REPAIR_DIKE {return "Rénover";}
			match ACTION_CREATE_DIKE {return "Nvl Digue";}
			match ACTION_DESTROY_DIKE {return "Nvl Digue";}
			match ACTION_RAISE_DIKE {return "Réhausser";}
			match ACTION_INSTALL_GANIVELLE {return "Ganivelle";}
		}
	}
	
	network_leader network_agent <- nil;
	init
	{
		create network_leader number:1;
		network_agent <- first(network_leader);
		do create_commune; 
		do create_button;

		ask commune
		{
			put [] key:self.commune_name in:profils;
		}

		//pour les test
		int i <- 0;

		create action_done number:0
		{
			location <- any_location_in(polygon([{0,0}, {20,0},{20,100},{0,100},{0,0}]));
			id <-i ;
			commune_name<-"dolus";
			i<- i+1;
		}
	}
	
	action generate_historique_profils {
		ask commune {
			write "<<"+commune_name+">>";
			write world.generate_historique_profils_for(commune_name);
		}
	}
	
	action generate_historique_profils_for (string aCommune) {
		
		loop prof over: ["batisseur","defense douce", "retrait"]
		{
			list<int> aSerie;
			list<action_done> lad <- action_done where (each.commune_name = aCommune and each.tracked_profil = prof);
			
			
			loop i from: 1 to:round {
				add (length (lad where (each.command_round = i))) to: aSerie ;
			}	
			write prof + " : " +aSerie;
		}
	}
	reflex drag_drop when: selection_action_done != nil and  current_selected_action = REORGANISATION_AFFICHAGE
	{
			selection_action_done.shape <- rectangle(10#m,5#m);
			selection_action_done.location	<-	#user_location;	
	}
	
	action button_commune 
	{
		point loc <- #user_location;
		selected_commune <- (commune first_with (each overlaps loc ));
	}
	
	action button_action
	{	
		point loc <- #user_location;
		selected_action <- (action_button first_with (each overlaps loc ));
		if selected_action = nil {return;} 
		switch(selected_action.displayName)
				{
					match RECETTE {
						if(selected_commune != nil)
						{
							do percevoir_recette( selected_commune);
							selected_action<-nil; // désélection pour etre sur de ne pas appliquer 2 fois la meme action 
						}
					}
					match SUBVENTIONNER {
						if(selected_commune != nil)
						{
							do subventionner( selected_commune);
							selected_action<-nil; // désélection pour etre sur de ne pas appliquer 2 fois la meme action 
						}
					}
					match SUBVENTIONNER_GANIVELLE_NAME {
						if(selected_commune != nil)
						{
							do subventionner_ganivelle();
							write "SUBVENTIONNER_GANIVELLE Cliqué";
						}
					}	
					match SUBVENTIONNER_HABITAT_ADAPTE_NAME {
						if(selected_commune != nil)
						{
							do subventionner_habitat_adapte();
							write "SUBVENTIONNER_HABITAT_ADAPTE Cliqué";
						}
					}					
				}
	}
	
	action button_action_done
	{
		point loc <- #user_location;
		
		write "selection_action " + current_selected_action;
		
		action_done local_selection <- (action_done first_with (each overlaps loc ));
		switch(current_selected_action)
				{
					match REORGANISATION_AFFICHAGE {
						if(selection_action_done = nil)
						{
							selection_action_done <- local_selection;
						}
						else
						{
							selection_action_done <- nil;
						}
						
					}
//					match RETARD_1_AN
//					{
//						if(local_selection != nil)
//						{
//							do retarder_action(local_selection,1);
//							selected_action<-nil; // désélection pour etre sur de ne pas appliquer 2 fois la meme action 
//						}	
//					}
//					match RETARD_2_ANS
//					{
//						if(local_selection != nil)
//						{
//							do retarder_action(local_selection,2);
//							selected_action<-nil; // désélection pour etre sur de ne pas appliquer 2 fois la meme action
//						}	
//					}
//					match RETARD_3_ANS
//					{
//						if(local_selection != nil)
//						{
//							do retarder_action(local_selection,3);
//							selected_action<-nil; // désélection pour etre sur de ne pas appliquer 2 fois la meme action
//						}	
//					}
//					match ABROGER
//					{
//						if(local_selection != nil)
//						{
//							do retarder_action(local_selection,3000);
//							selected_action<-nil; // désélection pour etre sur de ne pas appliquer 2 fois la meme action
//						}	
//					}
				}
	}
	
	action percevoir_recette(commune com)
	{
		string answere <- "Montant de la recette : ";
		map values <- user_input("Vous allez prélever une recette en provenance de " +com.com_large_name+"\nMettre un montan de 0 pour annuler",["Montant de la recette : " :: "2000"]);
		map<string, unknown> msg <-[];//LEADER_COMMAND::RECETTE,AMOUNT::int(values[answere]),COMMUNE::com.com_id];
		if int(values[answere])=0 {return;}// permet d'annuler l'action si le leader change d'avis ou est arriver la par hazard
		put RECETTE key: LEADER_COMMAND in: msg;
		put int(values[answere]) key: AMOUNT in: msg;
		put com.com_id key: COMMUNE in: msg;
		do send_message(msg);	
	}

	action subventionner(commune com)
	{
		string answere <- "montant de la subvention : ";
		map values <- user_input("Vous allez subventionner la commune de " +com.com_large_name+"\nMettre un montan de 0 pour annuler",[ "montant de la subvention : " :: "2000"]);
		map<string, unknown> msg <-[]; //LEADER_COMMAND::SUBVENTIONNER,AMOUNT::int(values[answere]),COMMUNE::com.com_id];
		if int(values[answere])=0 {return;}// permet d'annuler l'action si le leader change d'avis ou est arriver la par hazard
		put SUBVENTIONNER key: LEADER_COMMAND in: msg;
		put int(values[answere]) key: AMOUNT in: msg;
		put com.com_id key: COMMUNE in: msg;
		do send_message(msg);	
	}
	action subventionner_ganivelle
	{
		string msg <- ""+SUBVENTIONNER_GANIVELLE+COMMAND_SEPARATOR+999/*pour un mettre un action_id bidon */;
		do send_message_to_commune(msg,selected_commune.commune_name);	
	}
	action subventionner_habitat_adapte
	{	
		string msg <- ""+SUBVENTIONNER_HABITAT_ADAPTE+COMMAND_SEPARATOR+999/*pour un mettre un action_id bidon */;
		do send_message_to_commune(msg,selected_commune.commune_name);	
	}
	
//	action retarder_action(action_done act_dn, int duree)
//	{
//		map<string, unknown> msg <-[]; //LEADER_COMMAND::RETARDER,DELAY::duree, ACTION_ID::act_dn.id];
//		put RETARDER key: LEADER_COMMAND in: msg;
//		put int(duree) key: DELAY in: msg;
//		put act_dn.id key: ACTION_ID in: msg;
//		do send_message(msg);
//		act_dn.round_delay <- act_dn.round_delay + duree;
//		act_dn.application_round <- act_dn.application_round + duree;	
//	}
//	
//	action lever_retard_action(action_done act_dn)
//	{
//		map<string, unknown> msg <-[]; //LEADER_COMMAND::LEVER_RETARD,ACTION_ID::act_dn.id];
//		put LEVER_RETARD key: LEADER_COMMAND in: msg;
//		put act_dn.id key: ACTION_ID in: msg;
//		
//		do send_message(msg);	
//	}
	
	action send_message(map<string,unknown> msg)
	{
		ask network_agent
		{
			do send to:GAME_LEADER_MANAGER contents:msg;
		}		
	}
	
	action send_message_lever (activated_lever lev)
	{
		
		ask network_agent
		{
			do send to: "activated_lever" contents:lev.build_map_from_attribute();
		}	
	}
	action send_message_to_commune(string msg, string acommune_name)
	{
		ask network_agent
		{
			do send to:acommune_name contents:msg;
		}		
	}
	
	action button_action_move
	{
		if(selection_action_done != nil and  current_selected_action = REORGANISATION_AFFICHAGE)
		{
			selection_action_done.shape <- rectangle(10#m,5#m);
			selection_action_done.location	<-	#user_location;	
		}
	}
			
	action create_button
	{
		int i <- 0;
		create action_button number:1
		{
			displayName <- RETARD_1_AN;	
			location <- {5, i*10 + 10};
			i <- i +1;
		}
		
		create action_button number:1
		{
			displayName <- RETARD_2_ANS;
			location <- {5, i*10 + 10};
			i <- i +1;
		}
		
		create action_button number:1
		{
			displayName <- RETARD_3_ANS;
			location <- {5, i*10 + 10};
			i <- i +1;
			
		}
		
		create action_button number:1
		{
			displayName <- ABROGER;
			location <- {5, i*10 + 10};
			i <- i +1;
		}
		
		create action_button number:1
		{
			displayName <- LEVER_RETARD;
			location <- {5, i*10 + 10};
			i <- i +1;
		}
		
		create action_button number:1
		{
			displayName <- SUBVENTIONNER;
			location <- {5, i*10 + 10};
			i <- i +1;
		}
		
		create action_button number:1
		{
			displayName <- RECETTE;
			location <- {5, i*10 + 10};
			i <- i +1;
		}
		
		create action_button number:1
		{
			displayName <- REORGANISATION_AFFICHAGE;
			location <- {5, i*10 + 10};
			i <- i +1;
		}
		
		create action_button number:1
		{
			displayName <- SUBVENTIONNER_GANIVELLE_NAME;
			location <- {5, i*10 + 10};
			i <- i +1;
		}
		create action_button number:1
		{
			displayName <- SUBVENTIONNER_HABITAT_ADAPTE_NAME;
			location <- {5, i*10 + 10};
			i <- i +1;
		}
	}
	
	action create_commune
	{
		int i <- 0;
		create commune from:communes_shape with: [commune_name::string(read("NOM_RAC")),com_id::int(read("id_jeu")),com_large_name::string(read("NOM"))]
		{
			if(com_id = 0)
			{
				do die;
			}
				
			write " commune " + commune_name + " "+com_id;
			location <- {5, i*20 + 10};
			i <- i +1;
		
   			create lever_raise_dike number:1 {	my_commune <- myself;}
   			create lever_dike_creation number:1 {my_commune <- myself;}
   			create lever_repair_dike number:1 {my_commune <- myself;}	
	 		create lever_AUorUi_inCoastBorderArea number:1 {my_commune <- myself;}
	 		create lever_AUorUi_inRiskArea number:1 {my_commune <- myself;}
	 		create lever_ganivelle number:1 {my_commune <- myself;}
	 		create lever_Us_outCoastBorderOrRiskArea number:1 {my_commune <- myself;}
		}
		ask lever_dike_creation+lever_raise_dike+lever_repair_dike+lever_AUorUi_inCoastBorderArea+lever_AUorUi_inRiskArea
				+lever_ganivelle+lever_Us_outCoastBorderOrRiskArea
		{
			add self to: my_commune.levers ;
			switch my_commune.commune_name
		 	{
				match "stpierre" {vertical_position <- 5;}
		 		match "dolus" {vertical_position <- 20;}
		 		match "lechateau" {vertical_position <- 35;}
				match "sttrojan" {vertical_position <- 50;}
			}
			location <- point(horizontal_position, vertical_position);
	 	}
	}
	
	
	string labelOfAction (int action_code){
	string rslt <- "";
	loop i from:0 to: 30 {
		if ((int(actions_def at {1,i})) = action_code)
		 {rslt <- actions_def at {3,i};}
	}
	return rslt;
	}
	
}


species action_done schedules:[]
{
	string id;
	int element_id;
	string commune_name<-"";
	//string command_group <- "";
	int command <- -1 on_change: {label <- world.labelOfAction(command);};
	string label <- "no name";
	int cost <- 0;	
	bool is_applied  ->{round >= initial_application_round} ;
	int initial_application_round <- -1;
	int command_round <- -1;
	int round_delay -> {activated_levers sum_of (each.nb_rounds_delay)} ; // nb rounds of delay
	bool is_delayed ->{round_delay>0};
	//string action_type <- "dike" ; //can be "dike" or "PLU"
	// en attendant que action type soit réparé
	string action_type <-"";//-> {(command in [ACTION_CREATE_DIKE,ACTION_REPAIR_DIKE,ACTION_DESTROY_DIKE])?"dike":"PLU"};
	string previous_ua_name <-"";  // for PLU action
	bool isExpropriation <- false; // for PLU action
	bool inProtectedArea <- false; // for dike action
	bool inCoastBorderArea <- false; // for PLU action // c'est la bande des 400 m par rapport au trait de cote
	bool inRiskArea <- false; // for PLU action / Ca correspond à la zone PPR qui est un shp chargé
	bool isInlandDike <- false; // for dike action // ce sont les rétro-digues
	string tracked_profil <-"";
	geometry element_shape;
	float lever_activation_time;
	list<activated_lever> activated_levers <-[];
	
	reflex save_data
	{
		
		ask world { save action_done to:"/tmp/action_done2.shp" type:"shp" crs: "EPSG:2154" with:[id::"id",cost::"cost",command_round::"cround", initial_application_round::"around", round_delay::"rdelay",is_delayed::"is_delayed", element_id::"chosenId",commune_name::"commune_name",command::"command",label::"label", tracked_profil::"tracked_profil", isInlandDike::"isInlandDike", inRiskArea::"inRiskArea",inCoastBorderArea::"inCoastBorderArea",inProtectedArea::"inProtectedArea",isExpropriation::"isExpropriation", previous_ua_name::"previous_ua_name",action_type::"action_type" ] ; }
	}
	
	init
	{
		 shape <- rectangle(10#m,5#m);
	}
	
	string full_label {
		string res ;
		switch action_type {
				match "dike" {
					if isInlandDike {res <- "Nvl RetroDigue";}
					else {res <- world.dike_label_of_command(command);} 
				}
				match "PLU" {
					res <-previous_ua_name + " -> "+(world.UA_name_of_command(command));
				}
				default {res <-"error";}
				}
		return (res+ " "+(is_applied?("(à T"+initial_application_round+")"):("("+(initial_application_round-round)+")"+(is_delayed?"+"+round_delay:""))));
	}
	
	
	geometry custom_shape {
		if is_applied {return circle(5#m);}
		else {return rectangle(10#m,5#m);} 
	}
	bool requestAttention {
		if action_type = 'dike' and command in [ACTION_CREATE_DIKE, ACTION_RAISE_DIKE] and inProtectedArea
			{return true;}
		/*if action_type = "PLU" and command in [ACTION_MODIFY_LAND_COVER_AU, ACTION_MODIFY_LAND_COVER_U] and inCoastBorderArea
			{return true;}
		if action_type = "PLU" and command in [ACTION_MODIFY_LAND_COVER_AU, ACTION_MODIFY_LAND_COVER_U] and inRiskArea
			{return true;}
		if action_type = "dike" and command in [ACTION_INSTALL_GANIVELLE] 
			{return true;}
		if action_type = "dike" and isInlandDike 
			{return true;}
		if action_type = "PLU" and command in [ACTION_MODIFY_LAND_COVER_AUs, ACTION_MODIFY_LAND_COVER_Us] 
			{return true;}
		if action_type = "dike" and command in [ACTION_DESTROY_DIKE] 
			{return true;}
		if action_type = "PLU" and isExpropriation
			{return true;}*/
		return false;
		
	/*
	 ACTION_REPAIR_DIKE
	ACTION_CREATE_DIKE
	ACTION_DESTROY_DIKE
	ACTION_RAISE_DIKE
	ACTION_INSTALL_GANIVELLE
	ACTION_MODIFY_LAND_COVER_AU
	ACTION_MODIFY_LAND_COVER_A
	ACTION_MODIFY_LAND_COVER_U
	ACTION_MODIFY_LAND_COVER_N
	ACTION_MODIFY_LAND_COVER_AUs	
	ACTION_MODIFY_LAND_COVER_Us
	ACTION_MODIFY_LAND_COVER_Ui
	ACTION_EXPROPRIATION 
	isExpropriation
	inProtectedArea
	inCoastBorderArea
	inRiskArea
	isInlandDike
	*/ 
	}
	string track_profil {
		// profil batisseur
		if action_type = 'dike' and command in [ACTION_CREATE_DIKE, ACTION_RAISE_DIKE]
			{return "batisseur";}
		if action_type = "PLU" and command in [ACTION_MODIFY_LAND_COVER_AU, ACTION_MODIFY_LAND_COVER_U] and inCoastBorderArea
			{return "batisseur";}
		if action_type = "PLU" and command in [ACTION_MODIFY_LAND_COVER_AU, ACTION_MODIFY_LAND_COVER_U] and inRiskArea
			{return "batisseur";}
		// profil def douce
		if action_type = "dike" and command in [ACTION_INSTALL_GANIVELLE] 
			{return "défense douce";}
		if action_type = "dike" and isInlandDike 
			{return "défense douce";}
		if action_type = "PLU" and command in [ACTION_MODIFY_LAND_COVER_AUs, ACTION_MODIFY_LAND_COVER_Us] 
			{return "défense douce";}

		if action_type = "dike" and command in [ACTION_DESTROY_DIKE] 
			{return "retrait";}
		if action_type = "PLU" and isExpropriation
			{return "retrait";}
		return "";
		}
	
	action init_from_map(map<string, string> a )
	{
		self.id <- string(a at "id");
		self.element_id <- int(a at "element_id");
		self.commune_name <- a at "commune_name";
		self.command <- int(a at "command");
		self.label <- a at "label";
		self.cost <- float(a at "cost");
		//self.should_be_applied <- bool(a at "should_be_applied");  Pas besoin. on le recalcul localement 
		self.initial_application_round <- int(a at "initial_application_round");
		self.action_type <- string(a at "action_type"); // Pour l'instant ca marche pas. je sais pas pourquoi
		self.previous_ua_name <- string(a at "previous_ua_name");
		self.isExpropriation <- bool(a at "isExpropriation");
		self.inProtectedArea <- bool(a at "inProtectedArea");
		self.inCoastBorderArea <- bool(a at "inCoastBorderArea");
		self.inRiskArea <- bool(a at "inRiskArea");
		self.isInlandDike <- bool(a at "isInlandDike");
		self.command_round <-int(a at "command_round");
		self.tracked_profil <- track_profil();
		self.element_shape <- geometry(a at "shape");
//		if action_type = 'dike'
//		{
//			geometry tt <- a at "shape";
//			write tt;
//			write tt.points;
//			write geometry(tt.points[0]);
//						write tt.points[1];
////			list<point> ltt ;
////			loop aa over: tt.points {
////				write "eee  "+aa;
////				write "rrr "+geometry(aa);
////				write {float(aa.x),float(aa.y),0};
////				add point([float(aa.x),float(aa.y),0]) to: ltt;
////			} 
////			self.element_shape <- polyline (ltt,0.1);
////			write element_shape;
////			write (a at "shape")[0];
//			
////		point ori <- {float(data[9]),float(data[10])};
////					point des <- {float(data[11]),float(data[12])};
////					point loc <- {float(data[13]),float(data[14])}; 
////					shape <- polyline([ori,des]);
//		self.element_shape <- geometry(a at "shape");}
//		else
//		{
//			self.element_shape <- geometry(a at "shape");
//		} 		
	}
	
	map<string,string> build_map_from_attribute
	{
		map<string,string> res <- [
			"OBJECT_TYPE"::"action_done",
			"id"::string(id),
			"element_id"::string(element_id),
			"commune_name"::string(commune_name),
			"command"::string(command),
			"label"::string(label),
			"cost"::string(cost),
			"initial_application_round"::string(initial_application_round),
			"action_type"::string(action_type),
			"previous_ua_name"::string(previous_ua_name),
			"isExpropriation"::bool(isExpropriation),
			"inProtectedArea"::bool(inProtectedArea),
			"inCoastBorderArea"::bool(inCoastBorderArea),
			"inRiskArea"::bool(inRiskArea),
			"isInlandDike"::bool(isInlandDike),
			"command_round"::string(command_round)
			]	;
			
	return res;
	
	}
	
	
	rgb color_action_type
	{
		switch(command)
		{
			 match ACTION_CREATE_DIKE { return #blue;}
			 match ACTION_REPAIR_DIKE {return #green;}
			 match ACTION_DESTROY_DIKE {return #brown;}
			 match ACTION_MODIFY_LAND_COVER_A { return #brown;}
			 match ACTION_MODIFY_LAND_COVER_AU {return #orange;}
			 match ACTION_MODIFY_LAND_COVER_N {return #green;}
		}
		return #darkgrey;
	}
	
	rgb color_get_attention
	{
		if requestAttention() {return #red;}
		return #black;
	}
	
	rgb color_tracked_profil
	{
		switch tracked_profil
		{
			match "batisseur" {return #deepskyblue;}
			match "défense douce" {return #lightgreen;}
			match "retrait" {return #moccasin;}
			match "" {return #darkgrey;}
			default {return #red;}
		}	
	}	
	
	aspect base
	{
		if(selected_commune.commune_name = commune_name)
		{
			if !is_applied and requestAttention() {draw custom_shape()+0.5#m color: #red;}
			draw custom_shape() color:selection_action_done=self? #lightyellow:color_tracked_profil() border:#black;
			draw full_label() at:{location.x - 4.5#m, location.y} font: font("Arial", 14 , #bold) color:#black;
	
			switch action_type {
				match "dike" {
					int x <-2;
					draw ("Coût " +string(cost) /*+ " / Longueur "+22 Mettre le shape.perimeter de l'ouvrage*/) at:{location.x - 4#m, location.y+x} font: font("Arial", 14 , #plain) color:#black;
					
					if inProtectedArea {
						x<-x+2;
						draw "En zone protégée" at:{location.x - 4#m, location.y+x} font: font("Arial", 14 , #plain) color:#black;
					}
					if isInlandDike {
						x<-x+2;
						draw "Est une rétro-digue"  at:{location.x - 4#m, location.y+x} font: font("Arial", 14 , #plain) color:#black;
					}
				}
				match "PLU" {
					int x <-2;
					draw "Coût " +string(cost) at:{location.x - 4#m, location.y+x} font: font("Arial", 14 , #plain) color:#black;
					if inProtectedArea {
						x<-x+2;
						draw "En zone protégée" at:{location.x - 4#m, location.y+x} font: font("Arial", 14 , #plain) color:#black;
					}
					if inCoastBorderArea {
						x<-x+2;
						draw "Dans les 400m litroal"  at:{location.x - 4#m, location.y+x} font: font("Arial", 14 , #plain) color:#black;
					}
					if inRiskArea {
						draw "Dans zone à risque" at:{location.x - 4#m, location.y+2+x} font: font("Arial", 14 , #plain) color:#black;
						x<-x+2;
					}
				}
			}
	/*
	 * Dike
	 
	 * inProtectedArea <- false; // for dike action
	 * isInlandDike <- false; // for dike action // ce sont les rétro-digues
	 */			
		}
	}

}



species action_button
{	
	string displayName;
	int commande;
	geometry shape <- rectangle(50#m,5#m);
	bool is_selected -> {selected_action = self};
	
	aspect base
	{
		draw shape color:is_selected ? #green:#blue;
		draw displayName at:{location.x - 4.5#m, location.y} color:#white;
	}
	
}


species commune
{
	string commune_name;
	string com_large_name;
	string budget;
	int com_id;
	bool not_updated <- false;
	geometry shape <- rectangle(50#m,10#m);
	bool is_selected -> {selected_commune = self};
	list<lever> levers ;
	
	// Indicateurs calculés par le Modèle à l’initialisation. Lorsque Leader se connecte, le Modèle lui renvoie la valeur de ces indicateurs en même temps	
	int length_dikes_t0 <- 0#m; //linéaire de digues existant / commune
	int length_dunes_t0 <- 0#m; //linéaire de dune existant / commune
	int count_UA_urban_t0 <-0; //nombre de cellules de bâtis (U , AU), Us et AUs)
	int count_UA_UandAU_inCoastBorderArea_t0 <-0; //nombre de cellules de bâtis (non adapté) en zone littoral (<400m) ZL
	int count_UA_urban_infloodRiskArea_t0 <-0; //nombre de cellules de bâtis en zone inondable (ZI)
	int count_UA_urban_dense_infloodRiskArea_t0 <-0; //nombre de cellules denses en ZI
	int count_UA_urban_dense_inCoastBorderArea_t0 <-0; //nombre de cellules denses en ZL (zone littoral)
	int count_UA_A_t0 <-0; // nombre de cellule A
	int count_UA_N_t0 <- 0; // nombre de cellul N 
	int count_UA_AU_t0 <- 0; // nombre de cellul AU
	int count_UA_U_t0 <- 0; // nombre de cellul U
	
	//Indicateurs actualisés par Leader à chaque fois qu’il reçoit une nouvelle action_done
	int length_dike_created <- 0;//linéaire de digue construit
	int length_dike_raised <- 0; //Linéaires de digue ayant eu une opération de rehaussement.
	int length_dike_repaired <- 0;//Linéaires de digue ayant eu une opération de rénovation 
	int count_AUorUi_inCoastBorderArea <- 0; //nombre d’opérations de construction non adaptée (passage en AU) ou d’opérations de densification en zone littorale (<400m)
	int count_AUorUi_inRiskArea <- 0; //	nombre d’opérations de construction (passage en AU, ou AUs) / ou d’opérations de densification en zone inondable
	int length_ganivelle_created <- 0; //linéaire de ganivelles
	int count_Us <- 0; //nombre d’opérations de construction en habitat adapté 
	int count_Us_outCoastBorderOrRiskArea <- 0; //nombre d’opérations de construction en habitat adapté hors ZL ou ZI
	int count_Us_inCoastBorderArea <- 0; //nombre d’opérations de construction en habitat adapté en zone littoral
	int count_Us_inRiskArea <- 0; //nombre d’opérations de construction en habitat adapté en zone inondable

//linéaire de rétro-digue construit (au delà de XXm)
//linéaire de digues démantelées
//n° du tour de la dernière construction de digue
//n° du tour du dernier rehaussement de digue
//n° du tour de la dernière rénovation de digue
//nombre d’opérations de densification hors ZL/ZI
//nombre d’opérations d’expropriation
//nombre d’opérations de construction

//nombre de cellule A qui passe en N

	
	
	action update_indicators_with (action_done act)
	{	if act.is_applied {write "gros problème. le traitement se fait trop tard";}
		if act.command = ACTION_CREATE_DIKE
			{	//write ""+polyline(act.element_shape );
				//write  act.element_shape.perimeter;
				length_dike_created <- length_dike_created + act.element_shape.perimeter;
				ask lever_dike_creation where(each.my_commune = self) {
					do register_and_check_activation(act);
				}
			}
		if act.command = ACTION_RAISE_DIKE
			{
				length_dike_raised <- length_dike_raised + act.element_shape.perimeter;
				ask lever_raise_dike where(each.my_commune = self) {
					do register_and_check_activation(act);
				}
			}
		if act.command = ACTION_REPAIR_DIKE
			{
				length_dike_repaired <- length_dike_repaired + act.element_shape.perimeter;
				ask lever_repair_dike where(each.my_commune = self) {
					do register_and_check_activation(act);
				}
			}	
		if  act.inCoastBorderArea and act.command in [ACTION_MODIFY_LAND_COVER_Ui,ACTION_MODIFY_LAND_COVER_AU] and act.previous_ua_name != "Us"
		{
			count_AUorUi_inCoastBorderArea <- count_AUorUi_inCoastBorderArea+1;
			ask lever_AUorUi_inCoastBorderArea where(each.my_commune = self) {
					do register_and_check_activation(act);
				}
		}
		if  act.inRiskArea and act.command in [ACTION_MODIFY_LAND_COVER_Ui,ACTION_MODIFY_LAND_COVER_AU]
		{
			count_AUorUi_inRiskArea <- count_AUorUi_inRiskArea+1;
			ask lever_AUorUi_inRiskArea where(each.my_commune = self) {
					do register_and_check_activation(act);
				}
		}
		if act.command = ACTION_INSTALL_GANIVELLE
		{
			length_ganivelle_created <- length_ganivelle_created + act.element_shape.perimeter;
			ask lever_ganivelle where(each.my_commune = self) {
				do register_and_check_activation(act);
			}
		}
		if act.command = ACTION_MODIFY_LAND_COVER_Us
		{
			count_Us <- count_Us +1;
			if act.inCoastBorderArea {
				count_Us_inCoastBorderArea <- count_Us_inCoastBorderArea +1;
				}
			if act.inRiskArea {
				count_Us_inRiskArea <- count_Us_inRiskArea +1;
			}
			if (!act.inRiskArea) and (!act.inCoastBorderArea) {
				count_Us_outCoastBorderOrRiskArea <- count_Us_outCoastBorderOrRiskArea +1;
				ask lever_Us_outCoastBorderOrRiskArea where(each.my_commune = self) {
						do register_and_check_activation(act);
					}
			} 
		}
	}
	
//	FINALLELENT LE REGSITER EST INTERGRE DS L UPDATE_INDICATORS
// action register_action_in_levers (action_done act_done)
//	{
//		ask levers {do register_and_check_activation(act_done);}
//		 
//	}
//		//le joueur construit des digues
//		if length_dike_created / length_dikes_t0 > 0.2 
//			{
//			//appliquer le levier correspondant
//			write "le joueur construit des digues-> appliquer le levier correspondant";
//			}
//	}
	
	aspect base
	{
		draw shape color:is_selected ? #green:#blue;
		draw com_large_name at:{location.x - 4.5#m, location.y} color:#white;
	}
}


species activated_lever 
{
	action_done act_done;
	float activation_time;
	bool applied <- false;
	
	//attributes sent through network
	int id <- length(activated_lever);
	string commune_name;
	string lever_type;
	string lever_explanation <- "";
	string act_done_id <- "";
	int nb_rounds_delay <-0;
	int added_cost <- 0;
	
	action init_from_map(map<string, string> m )
	{
		id <- int(m["id"]);
		lever_type <- m["lever_type"];
		commune_name <- m["commune_name"];
		act_done_id <- m["act_done_id"];
		added_cost <- int(m["added_cost"]);
		nb_rounds_delay <- int(m["nb_rounds_delay"]);
		lever_explanation <- m["lever_explanation"];
	}
	
	map<string,string> build_map_from_attribute
	{
		map<string,string> res <- [
			"OBJECT_TYPE"::"activated_lever",
			"id"::id,
			"lever_type"::lever_type,
			"commune_name"::commune_name,
			"act_done_id"::string(act_done_id),
			"added_cost"::string(added_cost),
			"nb_rounds_delay"::int(nb_rounds_delay),
			"lever_explanation"::lever_explanation
			 ]	;
		return res;
	}
}

////////////////////////////////////////////////////////////////////////////////////////////
//////////					LEVER 
//////////////////////////////////////////////////////////////

species lever 
{
	commune my_commune ;
	bool status_on <- true  ;// can be on or off . If off then the checkLeverActivation is not performed
	float threshold;
	float indicator;
	bool should_be_activated -> {indicator > threshold };
	bool threshold_reached <- false;
	bool timer_activated -> {!empty(activation_queue)};
	bool has_activated_levers -> {!empty(activated_levers)};
	float timer_duration <- 5000;// 1 minute = 60000 milliseconds
	list<action_done> associated_actions;
	list<activated_lever> activation_queue;
	list<activated_lever> activated_levers;
	string profile_name<-"";
	string lever_type <-"";
	string progression_bar<-"";
	string help_lever_msg <-"";
	string player_msg;
	int horizontal_position<-0;
	int vertical_position ;
	string activation_label_L1<-"";
	string activation_label_L2<-"";
	geometry shape <- rectangle (9,3);
	point origin -> { location - {4.2,0.9} } ;
	
	action register_and_check_activation (action_done act_done)
	{
		add act_done to: associated_actions;
		if  status_on
		{
			if should_be_activated
			{
				threshold_reached <- true;
				do queue_activated_lever(act_done);
			}
			else {threshold_reached <- false;}	
		}
	} 
	
	
	action apply_lever(activated_lever lev){}
	string info_of_next_activated_lever {return"";}
	
	action queue_activated_lever( action_done a_act_done)
	{
		create activated_lever number: 1 
		{
			lever_type <- myself.lever_type;
			commune_name <- myself.my_commune.commune_name;
			self.act_done <- a_act_done;
			act_done_id <- a_act_done.id;
			activation_time <-  machine_time + myself.timer_duration ;
			add self to: myself.activation_queue;
		}
	}

	action toogle_status 
	{
		status_on <- !status_on ;
		if !status_on {
			activation_queue <-[];
		}
	}
	user_command "activer/désactiver le levier"action: toogle_status;
	
	float activation_time
	{
		return activation_queue[0].activation_time;
	}
	
	reflex check_timer when: timer_activated
	{
		if machine_time > activation_time()
		{
			activated_lever act_lever <- activation_queue[0];
			remove index: 0 from: activation_queue ;
			add act_lever to: activated_levers;
			do apply_lever(act_lever);
		}
	}
	
	int remaining_seconds 
	{
		return (int((activation_time() -machine_time) / 1000));
	}
	
	int tot_lever_amont 
	{
		return activated_levers sum_of (each.added_cost);
	}
	
	action cancel_next_activated_action
	{		
			remove index: 0 from: activation_queue ;
	}

	user_command "Annuler la prochaine application du levier"action: cancel_next_activated_action;	

	rgb color_profile
	{
		switch profile_name
		{
			match "batisseur" {return #deepskyblue;}
			match "défense douce" {return #lightgreen;}
			match "retrait" {return #moccasin;}
			match "" {return #darkgrey;}
			default {return #red;}
		}	
	}
	aspect base
	{
		if timer_activated {draw shape+0.2#m color: #red;}
		draw shape color: color_profile() border:#black;
		draw lever_type +' ('+length(associated_actions)+')' at:{origin.x, origin.y} font: font("Arial", 14 , #bold) color:#black;
		float v_pos <-0.5;
		draw progression_bar at:{origin.x , origin.y+v_pos} font: font("Arial", 14 , #plain) color: threshold_reached?#red:#black;
		v_pos<-v_pos+0.4;
		if timer_activated {
				draw string(remaining_seconds())+" sec "+(length(activation_queue)=1?"":"("+length(activation_queue)+")")+"-> " + info_of_next_activated_lever() at:{origin.x, origin.y+v_pos} font: font("Arial", 14 , #plain) color:#black;
			}
		v_pos<-v_pos+0.4;
		if has_activated_levers {
				draw activation_label_L1 at:{origin.x, origin.y+v_pos} font: font("Arial", 14 , #plain) color:#black;
				v_pos<-v_pos+0.4;
				draw activation_label_L2 at:{origin.x, origin.y+v_pos} font: font("Arial", 14 , #plain) color:#black;
			}
		if !status_on {draw shape+0.1#m color: rgb(200,200,200,160) ;}
	}
}


species cost_lever parent: lever
{
	float added_cost_percentage;
	int last_lever_amount <-0; 
	
	string info_of_next_activated_lever 
	{
		return ""+int(activation_queue[0].act_done.element_shape.perimeter) + " m. (" + int(activation_queue[0].act_done.cost * added_cost_percentage) + ' Bs.)';
	}
	
	action apply_lever(activated_lever lev)
	{
		lev.applied <- true;
		write help_lever_msg;
		lev.lever_explanation <- player_msg;
		lev.added_cost <- int(lev.act_done.cost * added_cost_percentage);
		
		ask world {do send_message_lever(lev) ;}
		
		last_lever_amount <-lev.added_cost;
		activation_label_L1 <- "Dernier prélevement : "+last_lever_amount+ ' Bs.';
		activation_label_L2 <- 'total prélevé : '+string(tot_lever_amont())+' Bs';
	}
}

species lever_dike_creation parent: cost_lever
{
	float indicator -> {my_commune.length_dike_created / my_commune.length_dikes_t0};
	string progression_bar -> {""+my_commune.length_dike_created+ " m. construits  / "+ my_commune.length_dikes_t0+" m. à t0"};
	
	init
		{
		horizontal_position <- 5;
		lever_type <- LEVER_DIKE_CREATION;
		profile_name<-"batisseur";
		threshold <- 0.2;
		added_cost_percentage <- 0.25 ;
		help_lever_msg <-"prélevement de la commune au prorata du linéaire construit : "+int(100*added_cost_percentage)+"% du prix de construction";
		player_msg <- "Les autorites reorientent leur politique : vos actions vous coutent plus cher que prevu";	
		}
}

species lever_raise_dike parent: cost_lever
{
	float indicator -> {my_commune.length_dike_raised / my_commune.length_dikes_t0};
	string progression_bar -> {""+my_commune.length_dike_raised+ " m. réhaussés / "+ my_commune.length_dikes_t0+" m. à t0"};
	init
		{
		horizontal_position <- 15;
		lever_type <- LEVER_RAISE_DIKE;
		profile_name<-"batisseur";
		threshold <- 0.2;
		added_cost_percentage <- 0.25 ;
		help_lever_msg <-"prélevement de la commune au prorata du linéaire réhaussé : "+int(100*added_cost_percentage)+"% du prix de réhaussement";
		player_msg <- "Les autorites reorientent leur politique : vos actions vous coutent plus cher que prevu";
		}
}

species lever_repair_dike parent: cost_lever
{
	float indicator -> {my_commune.length_dike_repaired / my_commune.length_dikes_t0};
	bool should_be_activated -> {indicator > threshold and (my_commune.length_dike_created != 0 or my_commune.length_dike_raised != 0)};
	string progression_bar -> {""+my_commune.length_dike_repaired+ " m. réparés / "+ my_commune.length_dikes_t0+" m. à t0"};
	
	init
		{
		horizontal_position <- 25;
		lever_type <- LEVER_REPAIR_DIKE;
		profile_name<-"batisseur";
		threshold <- 0.2;
		added_cost_percentage <- 0.25 ;
		help_lever_msg <-"prélevement de la commune au prorata du linéaire rénové : "+int(100*added_cost_percentage)+"% du prix de rénovation ; si a aussi construit ou réhaussé";
		player_msg <- "Les coûts dans les BTP augmentent considérablement";
		}
}

species lever_AUorUi_inCoastBorderArea parent: lever
{
	int rounds_delay_added <- 2;
	
	string progression_bar -> {""+indicator + " actions / "+ int(threshold) + " max"};
	int indicator -> {my_commune.count_AUorUi_inCoastBorderArea};
	
	init
		{
		horizontal_position <- 35;
		lever_type <- LEVER_AUorUi_inCoastBorderArea;
		profile_name<-"batisseur";
		threshold <- 2;
		help_lever_msg <-"Retard de "+rounds_delay_added+" tours";
		player_msg <- "Un renforcement de la loi Littoral retarde vos projets";	
		}
		
	string info_of_next_activated_lever 
	{
		switch activation_queue[0].act_done.command 
		{
			match ACTION_MODIFY_LAND_COVER_AU {return "Prochaine action : Construction";}
			match ACTION_MODIFY_LAND_COVER_Ui {return "Prochaine action : Densification";}
		} 
	}
	
	action apply_lever(activated_lever lev)
	{
		lev.applied <- true;
		write help_lever_msg;
		lev.lever_explanation <- player_msg;
		lev.nb_rounds_delay <- rounds_delay_added;
		
		ask world {do send_message_lever(lev) ;}
		
		activation_label_L1 <- "Cas de construction : "+length(activated_levers where(each.act_done.command = ACTION_MODIFY_LAND_COVER_AU) );
		activation_label_L2 <- "Cas de densification : "+length(activated_levers where(each.act_done.command = ACTION_MODIFY_LAND_COVER_Ui) );
	}
}

species lever_AUorUi_inRiskArea parent: cost_lever
{
	string progression_bar -> {""+indicator + " actions / "+ int(threshold) + " max"};
	int indicator -> {my_commune.count_AUorUi_inRiskArea};
	
	init
		{
		horizontal_position <- 45;
		lever_type <- LEVER_AUorUi_inRiskArea;
		profile_name<-"batisseur";
		threshold <- 2;
		added_cost_percentage <- 0.5 ;
		help_lever_msg <-"prélevement de la commune à hauteur de "+int(100*added_cost_percentage)+"% du coût de construction";
		player_msg <- "Les coûts dans les BTP augmentent considérablement";	
		}
		
	string info_of_next_activated_lever 
	{
		switch activation_queue[0].act_done.command 
		{
			match ACTION_MODIFY_LAND_COVER_AU {return "Prochaine action : Construction";}
			match ACTION_MODIFY_LAND_COVER_Ui {return "Prochaine action : Densification";}
		} 
	}
}

species lever_ganivelle parent: cost_lever
{
	string progression_bar -> {""+my_commune.length_ganivelle_created+ " m. ganivelles / "+ my_commune.length_dunes_t0+" m. dunes"};
	int indicator -> {my_commune.length_ganivelle_created / my_commune.length_dunes_t0};
	
	init
		{
		horizontal_position <- 55;
		lever_type <- LEVER_GANIVELLE;
		profile_name<-"défense douce";
		threshold <- 0.1;
		added_cost_percentage <- -0.25 ;
		help_lever_msg <-"Versement à la commune à hauteur de "+int(100*added_cost_percentage)+"% du coût de ganivelle/m";
		player_msg <- "Le gouvernement encourage les pratiques vertueuses de gestion intégrée des risques";
		}
}

species lever_Us_outCoastBorderOrRiskArea parent: cost_lever
{
	string progression_bar -> {""+indicator + " actions / "+ int(threshold) + " max"};
	int indicator -> {my_commune.count_Us_outCoastBorderOrRiskArea};
	int rounds_delay_added <- -2;
	
	init
		{
		horizontal_position <- 65;
		lever_type <- LEVER_Us_outCoastBorderOrRiskArea;
		profile_name<-"défense douce";
		threshold <- 2;
		added_cost_percentage <- -0.25 ;
		help_lever_msg <-"Versement à la commune à hauteur de "+int(100*added_cost_percentage)+"% du coût d'adaptation ET avance de "+rounds_delay_added+" tours le dossier";
		player_msg <- "Le gouvernement encourage les pratiques vertueuses de gestion intégrée des risques";
		}
	
	string info_of_next_activated_lever 
	{
		switch activation_queue[0].act_done.command 
		{
			match ACTION_MODIFY_LAND_COVER_AU {return "Prochaine action : Construction";}
			match ACTION_MODIFY_LAND_COVER_Ui {return "Prochaine action : Densification";}
		} 
	}
	action apply_lever(activated_lever lev)
	{
		lev.applied <- true;
		write help_lever_msg;
		lev.lever_explanation <- player_msg;
		lev.added_cost <- int(lev.act_done.cost * added_cost_percentage);
		lev.nb_rounds_delay <- rounds_delay_added;
		
		ask world {do send_message_lever(lev) ;}
		
		last_lever_amount <-lev.added_cost;
		activation_label_L1 <- "Dernier versement : "+(-1*last_lever_amount)+ ' Bs.';
		activation_label_L2 <- 'Total versé : '+string((-1*tot_lever_amont()))+' Bs';
	}
}

///////////////////////////////////////


species network_leader skills:[network]
{
	init
	{
		 do connect to: SERVER with_name:OBSERVER_NAME;
		 
		map<string, unknown> msg <-[]; //LEADER_COMMAND::RETARDER,DELAY::duree, ACTION_ID::act_dn.id];
		put ASK_NUM_ROUND key: LEADER_COMMAND in: msg;
		do send to:GAME_LEADER_MANAGER contents:msg;
		map<string, unknown> msg <-[]; 
		put ASK_INDICATORS_T0 key: LEADER_COMMAND in: msg;
		do send to:GAME_LEADER_MANAGER contents:msg;
		map<string, unknown> msg <-[]; 
		put "RETREIVE_ACTION_DONE" key: LEADER_COMMAND in: msg;
		do send to:GAME_LEADER_MANAGER contents:msg;
	}
	
	
	reflex wait_message
	{
		
		loop while:has_more_message()
		{
			message msg <- fetch_message();
			string m_sender <- msg.sender;
			map<string, string> m_contents <- msg.contents;
			string cmd <- m_contents[OBSERVER_MESSAGE_COMMAND];
			string data <- m_contents[OBSERVER_MESSAGE_COMMAND]; // Q à NM -> Pourquoi cette ligne ? C'est bizarre non ?
			switch(cmd)
			{
				match UPDATE_ACTION_DONE { do update_action(m_contents); }
				match NUM_ROUND
					{	round<-int(m_contents['num tour']);
						ask world { do write_profile; }
					}
				match INDICATORS_T0
					{ write m_contents;
						ask commune where (each.commune_name = m_contents['commune_name']) 
						{ 	length_dikes_t0 <- float (m_contents['length_dikes_t0']);
							length_dunes_t0 <- float (m_contents['length_dunes_t0']);
							count_UA_urban_t0 <- int (m_contents['count_UA_urban_t0']);
							count_UA_UandAU_inCoastBorderArea_t0 <- int (m_contents['count_UA_UandAU_inCoastBorderArea_t0']);
							count_UA_urban_infloodRiskArea_t0 <- int (m_contents['count_UA_urban_infloodRiskArea_t0']);
							count_UA_urban_dense_infloodRiskArea_t0 <- int (m_contents['count_UA_urban_dense_infloodRiskArea_t0']);
							count_UA_urban_dense_inCoastBorderArea_t0<- int (m_contents['count_UA_urban_dense_inCoastBorderArea_t0']);
							count_UA_A_t0 <- int (m_contents['count_UA_A_t0']);
							count_UA_N_t0 <- int (m_contents['count_UA_N_t0']);
							count_UA_AU_t0 <- int (m_contents['count_UA_AU_t0']);
							count_UA_U_t0 <- int (m_contents['count_UA_U_t0']);		
						}
					}
			}
			
		}	
	}
	
	action update_action(map<string,string> msg)
	{
		string m_id <- (msg at "id");
		list<action_done> act_done <- action_done where(each.id = (msg at "id"));
		//write "action correspondant à id '"+m_id+"' : " +act_done;
		
		if(act_done = nil or length(act_done) = 0)
		// Il s'agit d'une nouvelle action commandé par un joueur
		// Lors de l'arrivée d'une nouvelle action venant d'être commandé, les indicateurs sont mis à jour et les seuils de déclenchement de leviers sont testés
		{
			create action_done number:1
			{
				location <- any_location_in(polygon([{0,0}, {20,0},{20,100},{0,100},{0,0}]));
				do init_from_map(msg);
				ask world
				{
					do add_action_done_to_profile(myself,round);	
				}
				ask commune first_with (each.commune_name = commune_name) {
					do update_indicators_with (myself);
					//  do register_action_in_levers (myself);  FINLALEMENT INTERGER DSN LE UPDATE_INDCIATORS
				}
			}
			
		}
		else
		// Il s'agit d'une mise à jour d'une action qui avait été préalablement commandé par un joueur
		{
			ask first(act_done) 
			{
				do init_from_map(msg);
			}
		}
	}
	
}



experiment lead_the_game
{
	float minimum_cycle_duration <- 0.5;
	output
	{
		display commune_control
		{
			species commune aspect:base;
			event [mouse_down] action: button_commune;
		}
		
		display action_control
		{
			species action_button aspect:base;
			event [mouse_down] action: button_action;
		}
		display alive_action_commune
		{
			graphics "agile" position:{0,0} 
			{
				draw rectangle(20#m,100#m) color:#gray at:{10#m,50#m};
				draw "A traiter" color:#white at:{5#m,10#m} size:12#px;
				draw rectangle(40#m,100#m) color:#yellow at:{40#m,50#m};
				draw "Tour "+string(round) color:#black font: font("Arial", 16 , #bold) at:{35#m,3#m};
				draw "Encours" color:#black at:{35#m,10#m};
				draw rectangle(40#m,100#m) color:#green at:{80#m,50#m};
				draw "Achevé" color:#white at:{75#m,10#m};
			}
			species action_done aspect:base;
			event [mouse_down] action: button_action_done;
			event mouse_move action: button_action_move;
			
		}
		display levers 
		{
			graphics "leviers" position:{0,0} 
			{
			}
			species lever_dike_creation aspect:base;
			species lever_AUorUi_inCoastBorderArea aspect: base;
			species lever_AUorUi_inRiskArea aspect: base;
			species lever_raise_dike aspect: base;
			species lever_repair_dike aspect: base;
			species lever_ganivelle aspect: base;
			species lever_Us_outCoastBorderOrRiskArea aspect: base;
		}
	}

}
/**
* Name: leader
* Author: nicolas
* Description: 
* Tags: Tag1, Tag2, TagN
*/

model leader





global
{
	
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
	string COMMUNE <- "COMMUNE_ID";
	string ASK_NUM_ROUND <- "Leader demande numero du tour";
	string NUM_ROUND <- "Numero du tour";
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
	
	
	action add_action_done_to_profile(action_done dd, int act_round)
	{
		list<map<string,int>> profil_commune<- profils[dd.doer];
		loop while:length(profil_commune)<=act_round
		{
			map<string,int> state <- [];
			put 0 key:BATISSEUR in: state;
			put 0 key:DEFENSE_DOUCE in: state;
			put 0 key:RETRAIT in: state;
			add state to:profil_commune;
		}
		map<string,int> chosen_round <- profil_commune[act_round];
		write "profile "+ dd.tracked_profil + "  "+ chosen_round[dd.tracked_profil];
		put chosen_round[dd.tracked_profil] +1 key:dd.tracked_profil in: chosen_round;
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
	
	game_controller network_agent <- nil;
	init
	{
		create game_controller number:1;
		network_agent <- first(game_controller);
		do create_commune;
		do create_button;

		ask commune
		{
			put [] key:self.com_name in:profils;
		}

		//pour les test
		int i <- 0;

		create action_done number:0
		{
			location <- any_location_in(polygon([{0,0}, {20,0},{20,100},{0,100},{0,0}]));
			id <-i ;
			doer<-"dolus";
			i<- i+1;
		}
	}
	
	action generate_historique_profils {
		ask commune {
			write "<<"+com_name+">>";
			write world.generate_historique_profils_for(com_name);
		}
	}
	
	action generate_historique_profils_for (string aCommune) {
		
		loop prof over: ["batisseur","defense douce", "retrait"]
		{
			list<int> aSerie;
			list<action_done> lad <- action_done where (each.doer = aCommune and each.tracked_profil = prof);
			
			
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
					match RETARD_1_AN
					{
						if(local_selection != nil)
						{
							do retarder_action(local_selection,1);
							selected_action<-nil; // désélection pour etre sur de ne pas appliquer 2 fois la meme action 
						}	
					}
					match RETARD_2_ANS
					{
						if(local_selection != nil)
						{
							do retarder_action(local_selection,2);
							selected_action<-nil; // désélection pour etre sur de ne pas appliquer 2 fois la meme action
						}	
					}
					match RETARD_3_ANS
					{
						if(local_selection != nil)
						{
							do retarder_action(local_selection,3);
							selected_action<-nil; // désélection pour etre sur de ne pas appliquer 2 fois la meme action
						}	
					}
					match ABROGER
					{
						if(local_selection != nil)
						{
							do retarder_action(local_selection,3000);
							selected_action<-nil; // désélection pour etre sur de ne pas appliquer 2 fois la meme action
						}	
					}
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
		do send_message_to_commune(msg,selected_commune.com_name);	
	}
	action subventionner_habitat_adapte
	{	
		string msg <- ""+SUBVENTIONNER_HABITAT_ADAPTE+COMMAND_SEPARATOR+999/*pour un mettre un action_id bidon */;
		do send_message_to_commune(msg,selected_commune.com_name);	
	}
	
	action retarder_action(action_done act_dn, int duree)
	{
		map<string, unknown> msg <-[]; //LEADER_COMMAND::RETARDER,DELAY::duree, ACTION_ID::act_dn.id];
		put RETARDER key: LEADER_COMMAND in: msg;
		put int(duree) key: DELAY in: msg;
		put act_dn.id key: ACTION_ID in: msg;
		do send_message(msg);
		act_dn.round_delay <- act_dn.round_delay + duree;
		act_dn.application_round <- act_dn.application_round + duree;	
	}
	
	action lever_retard_action(action_done act_dn)
	{
		map<string, unknown> msg <-[]; //LEADER_COMMAND::LEVER_RETARD,ACTION_ID::act_dn.id];
		put LEVER_RETARD key: LEADER_COMMAND in: msg;
		put act_dn.id key: ACTION_ID in: msg;
		
		do send_message(msg);	
	}
	
	action send_message(map<string,unknown> msg)
	{
		ask network_agent
		{
			do send to:GAME_LEADER_MANAGER contents:msg;
		}		
	}
	action send_message_to_commune(string msg, string aDoer)
	{
		ask network_agent
		{
			do send to:aDoer contents:msg;
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
		create commune from:communes_shape with: [com_name::string(read("NOM_RAC")),com_id::int(read("id_jeu")),com_large_name::string(read("NOM"))]
		{
			if(com_id = 0)
			{
				do die;
			}
				
			write " commune " + com_name + " "+com_id;
			location <- {5, i*20 + 10};
			i <- i +1;
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
	int id;
	int chosen_element_id;
	string doer<-"";
	//string command_group <- "";
	int command <- -1 on_change: {label <- world.labelOfAction(command);};
	string label <- "no name";
	int cost <- 0;	
	bool is_applied  ->{round >= application_round} ;
	int application_round <- -1;
	int command_round <- -1;
	int round_delay <- 0 ; // nb rounds of delay
	bool is_delayed ->{round_delay>0} ;
	list<string> my_message <-[];
	//string action_type <- "dike" ; //can be "dike" or "PLU"
	// en attendant que action type soit réparé
	string action_type <-"";//-> {(command in [ACTION_CREATE_DIKE,ACTION_REPAIR_DIKE,ACTION_DESTROY_DIKE])?"dike":"PLU"};
	string previous_ua_name <-"";  // for PLU action
	bool isExpropriation <- false; // for PLU action
	bool inProtectedArea <- false; // for dike action
	bool inLittoralArea <- false; // for PLU action // c'est la bande des 400 m par rapport au trait de cote
	bool inRiskArea <- false; // for PLU action / Ca correspond à la zone PPR qui est un shp chargé
	bool isInlandDike <- false; // for dike action // ce sont les rétro-digues
	string tracked_profil <-"";
	
	reflex save_data
	{
		
		ask world { save action_done to:"/tmp/action_done2.shp" type:"shp" crs: "EPSG:2154" with:[id::"id",cost::"cost",command_round::"cround", application_round::"around", round_delay::"rdelay",is_delayed::"is_delayed", chosen_element_id::"chosenId",doer::"doer",command::"command",label::"label", tracked_profil::"tracked_profil", isInlandDike::"isInlandDike", inRiskArea::"inRiskArea",inLittoralArea::"inLittoralArea",inProtectedArea::"inProtectedArea",isExpropriation::"isExpropriation", previous_ua_name::"previous_ua_name",action_type::"action_type" ] ; }
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
		return (res+ " "+(is_applied?("(à T"+application_round+")"):("("+(application_round-round)+")"+(is_delayed?"+"+round_delay:""))));
	}
	
	
	geometry custom_shape {
		if is_applied {return circle(5#m);}
		else {return rectangle(10#m,5#m);} 
	}
	bool requestAttention {
		if action_type = 'dike' and command in [ACTION_CREATE_DIKE, ACTION_RAISE_DIKE] and inProtectedArea
			{return true;}
		/*if action_type = "PLU" and command in [ACTION_MODIFY_LAND_COVER_AU, ACTION_MODIFY_LAND_COVER_U] and inLittoralArea
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
	inLittoralArea
	inRiskArea
	isInlandDike
	*/ 
	}
	string track_profil {
		// profil batisseur
		if action_type = 'dike' and command in [ACTION_CREATE_DIKE, ACTION_RAISE_DIKE]
			{return "batisseur";}
		if action_type = "PLU" and command in [ACTION_MODIFY_LAND_COVER_AU, ACTION_MODIFY_LAND_COVER_U] and inLittoralArea
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
		self.id <- int(a at "id");
		self.chosen_element_id <- int(a at "chosen_element_id");
		self.doer <- a at "doer";
		self.command <- int(a at "command");
		self.label <- a at "label";
		self.cost <- float(a at "cost");
		//self.should_be_applied <- bool(a at "should_be_applied");  Pas besoin. on le recalcul localement 
		self.application_round <- int(a at "application_round");
		self.round_delay <- int(a at "round_delay");
		self.action_type <- string(a at "action_type"); // Pour l'instant ca marche pas. je sais pas pourquoi
		self.previous_ua_name <- string(a at "previous_ua_name");
		self.isExpropriation <- bool(a at "isExpropriation");
		self.inProtectedArea <- bool(a at "inProtectedArea");
		self.inLittoralArea <- bool(a at "inLittoralArea");
		self.inRiskArea <- bool(a at "inRiskArea");
		self.isInlandDike <- bool(a at "isInlandDike");
		self.command_round <-int(a at "command_round");
		self.tracked_profil <- track_profil();
		
		
	}
	
	map<string,string> build_map_from_attribute
	{
		map<string,string> res <- ["id"::string(id),
			"chosen_element_id"::string(chosen_element_id),
			"doer"::string(doer),
			"command"::string(command),
			"label"::string(label),
			"cost"::string(cost),
			"application_round"::string(application_round),
			"round_delay"::string(round_delay), 
			"action_type"::string(action_type),
			"previous_ua_name"::string(previous_ua_name),
			"isExpropriation"::bool(isExpropriation),
			"inProtectedArea"::bool(inProtectedArea),
			"inLittoralArea"::bool(inLittoralArea),
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
		if(selected_commune.com_name = doer)
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
					if inLittoralArea {
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

species action_done_by_commune
{
	
}

species commune
{
	string com_name;
	string com_large_name;
	string budget;
	int com_id;
	bool not_updated <- false;
	geometry shape <- rectangle(50#m,10#m);
	bool is_selected -> {selected_commune = self};
	aspect base
	{
		draw shape color:is_selected ? #green:#blue;
		draw com_large_name at:{location.x - 4.5#m, location.y} color:#white;
	}
}


species game_controller skills:[network]
{
	init
	{
		 do connect to:"localhost" with_name:OBSERVER_NAME;
		 
		map<string, unknown> msg <-[]; //LEADER_COMMAND::RETARDER,DELAY::duree, ACTION_ID::act_dn.id];
		put ASK_NUM_ROUND key: LEADER_COMMAND in: msg;
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
			string data <- m_contents[OBSERVER_MESSAGE_COMMAND];
			switch(cmd)
			{
				match UPDATE_ACTION_DONE { do update_action(m_contents); }
				match NUM_ROUND
					{ round<-int(m_contents['num tour']);
						ask world
						{
							do write_profile;
							
						}
					}
			}
			
		}	
	}
	
	action update_action(map<string,string> msg)
	{
		int m_id <- int(msg at "id");
		
		list<action_done> act_done <- action_done where(each.id = m_id);
		
		if(act_done = nil or length(act_done) = 0)
		{
			create action_done number:1
			{
				location <- any_location_in(polygon([{0,0}, {20,0},{20,100},{0,100},{0,0}]));
				do init_from_map(msg);
				ask world
				{
					do add_action_done_to_profile(myself,round);
					
				}
			
			}
		}
		else
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
		display triangle
		{
			
		}
	}

}
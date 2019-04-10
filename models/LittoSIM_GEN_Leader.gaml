/**
* Name: leader
* Author: nicolas
* Description: 
* Tags: Tag1, Tag2, TagN
*/

model Leader

import "params_models/params_leader.gaml"

global{
	
	float sim_id;
	Lever explored_lever;
	list<string> leader_activities;	
	Player_Action selection_player_action;
	District selected_district					<- nil;
	geometry shape 								<- square(100#m);
	map<string,list<map<string,int>>> profiles	<-[];
	
	list<string> levers_names <- ['LEVER_CREATE_DIKE', 'LEVER_RAISE_DIKE', 'LEVER_REPAIR_DIKE', 'LEVER_AU_Ui_COAST_BORDER_AREA', 'LEVER_AU_Ui_RISK_AREA',
								  'LEVER_GANIVELLE', 'LEVER_Us_COAST_BORDER_RISK_AREA', 'LEVER_Us_COAST_BORDER_AREA', 'LEVER_Us_RISK_AREA', 'LEVER_INLAND_DIKE',
								  'LEVER_NO_DIKE_CREATION', 'LEVER_NO_DIKE_RAISE', 'LEVER_NO_DIKE_REPAIR', 'LEVER_A_N_COAST_BORDER_RISK_AREA',
								  'LEVER_DENSIFICATION_COAST_BORDER_RISK_AREA', 'LEVER_EXPROPRIATION', 'LEVER_DESTROY_DIKE'];

	list<species<Lever>> all_levers <- [];
	
	init{
		all_levers <- [lever_create_dike, lever_raise_dike, lever_repair_dike, lever_AUorUi_inCoastBorderArea, lever_AUorUi_inRiskArea,
				lever_ganivelle, lever_Us_outCoastBorderOrRiskArea, lever_Us_inCoastBorderArea, lever_Us_inRiskArea, lever_inland_dike,
				lever_no_dike_creation, lever_no_dike_raise, lever_no_dike_repair, lever_AtoN_inCoastBorderOrRiskArea,
				lever_densification_outCoastBorderAndRiskArea, lever_expropriation, Lever_Destroy_Dike];

		MSG_CHOOSE_MSG_TO_SEND 	<- get_message('MSG_CHOOSE_MSG_TO_SEND');
		MSG_TYPE_CUSTOMIZED_MSG <- get_message('MSG_TYPE_CUSTOMIZED_MSG');
		MSG_TO_CANCEL 			<- get_message('MSG_TO_CANCEL');
		MSG_AMOUNT 				<- get_message('MSG_AMOUNT');
		MSG_123_OR_CUSTOMIZED 	<- get_message('MSG_123_OR_CUSTOMIZED');
		BTN_GET_REVENUE_MSG2	<- get_message('BTN_GET_REVENUE_MSG2');
		
		sim_id <- machine_time;
		create Network_Leader;
		do create_districts; 
		do create_District_Action_Buttons;

		ask District {	put [] key: self.district_code in:profiles; }

		loop i from: 0 to: 3 {
			create District_Name {
				display_name <- District[i].district_name;
				location	 <- (Grille grid_at {i,0}).location - {1,-1};
			}
		}
	}
	//------------------------------ end of init -------------------------------//
	
	action create_District_Action_Buttons{
		loop i from: 0 to: 3 {
			create District_Action_Button {
				command 	 <- GIVE_MONEY_TO;
				display_name <- world.get_message("LDR_MSG_SEND_MONEY");
				location	 <- (Grille[i,1]).location - {0,5};
				my_district  <- District[i];
			}
			create District_Action_Button {
				command 	 <- TAKE_MONEY_FROM;
				display_name <- world.get_message("LDR_MSG_WITHDRAW_MONEY");
				location	 <- (Grille[i,1]).location - {0,1.5};
				my_district  <- District[i];
			}
			create District_Action_Button {
				command 	 <- SEND_MESSAGE_TO;
				display_name <- world.get_message("LDR_MSG_SEND_MSG");
				location	 <- (Grille[i,1]).location + {0,2};
				my_district  <- District[i];
			}
		}
	}
	
	string dike_label_of_command (int act) {
		switch act {
			match ACTION_REPAIR_DIKE 		{ return "Repair";	 }
			match ACTION_CREATE_DIKE 		{ return "New Dike"; }
			match ACTION_DESTROY_DIKE 		{ return "Dstr Dike";}
			match ACTION_RAISE_DIKE 		{ return "Raise";	 }
			match ACTION_INSTALL_GANIVELLE 	{ return "Ganivelle";}
		}
	}
	
	action record_leader_activity (string msg_type, string d, string msg){
		string aText <- "<" + string (current_date.hour) + ":" + current_date.minute + ">" + msg_type + " " + d + " -> " + msg;
		write aText;
		add ("<" + machine_time + ">" + aText) to: leader_activities;
	}
	
	action save_leader_records{
		loop a over: leader_activities {
			save a to: "leader_records-" + sim_id + "/leader_activities_Tour" + game_round + ".txt" type: "text" rewrite:false;
		}
		save Player_Action   to: "leader_records-" + sim_id + "/player_action_Tour"   + game_round + ".csv" type: "csv";
		save Activated_Lever to: "leader_records-" + sim_id + "/activated_lever_Tour" + game_round + ".csv" type: "csv"; 
		loop a over: all_levers{
			save a.population to: "leader_records-" + sim_id + "/all_levers_Tour" + game_round + ".csv"  type:"csv" rewrite:false;
		}
	}
	
	action add_player_action_to_profile (Player_Action act, int act_round){
		list<map<string,int>> district_profile <- profiles [act.district_code];
		loop while: length(district_profile) <= act_round {
			map<string,int> state <- [];
			put 0 key: BUILDER 		in: state;
			put 0 key: SOFT_DEFENSE in: state;
			put 0 key: WITHDRAWAL 	in: state;
			add state to: district_profile;
		}
		map<string,int> chosen_round <- district_profile[act_round];
		put chosen_round [act.tracked_profile] +1 key:act.tracked_profile in: chosen_round;
	}
	

	
	action generate_historique_profils {
		ask District {
			write "<<"+district_name+">>";
			write world.generate_historique_profils_for(district_name);
		}
	}
	
	action generate_historique_profils_for (string aCommune) {
		loop prof over: ["builder","soft defense", "withdrawal"]{
			list<int> aSerie;
			list<Player_Action> lad <- Player_Action where (each.district_name = aCommune and each.tracked_profile = prof);
			loop i from: 1 to:game_round {
				add (length (lad where (each.command_round = i))) to: aSerie ;
			}	
			write prof + " : " +aSerie;
		}
	}
	
	action user_click{
		point loc <- #user_location;
		unknown aButtonT <- ((District_Action_Button) first_with (each overlaps loc ));
		if aButtonT != nil { 
			if aButtonT in District_Action_Button{
				ask District_Action_Button where (each = aButtonT){
					write command;
					do button_cliked();
				}
			}	
		}
	}
	
	action percevoir_recette(District com){
		string answere 	<- world.get_message('LDR_MSG_AMOUNT_REVENUE') + " : ";
		string msg1		<- world.get_message('BTN_GET_REVENUE_MSG1');
		string msg3		<- world.get_message('BTN_GET_REVENUE_MSG3');
		map values 		<- user_input(msg1 +com.district_long_name+"\n"+BTN_GET_REVENUE_MSG2,[msg3+" : " :: "2000"]);
		map<string, unknown> msg <-[];//LEADER_COMMAND::RECETTE,AMOUNT::int(values[answere]),COMMUNE::com.dist_id];
		if int(values[answere])=0 {return;}// permet d'annuler l'action si le leader change d'avis ou est arriver la par hazard
		put TAKE_MONEY_FROM key: LEADER_COMMAND in: msg;
		put int(values[answere]) key: AMOUNT in: msg;
		put com.dist_id key: DISTRICT_CODE in: msg;
		do send_message_from_leader(msg);	
	}

	action subventionner(District com){
		string answer <- world.get_message('LDR_MSG_AMOUNT_SUBSIDY') + " : ";
		string msg1<- world.get_message('BTN_SUBSIDIZE_MSG1');
		string msg3<- world.get_message('BTN_SUBSIDIZE_MSG3');
		map values <- user_input(msg1 +com.district_long_name+"\n"+BTN_GET_REVENUE_MSG2,[ msg3 + " : " :: "2000"]);
		map<string, unknown> msg <-[]; 
		if int(values[answer])=0 {return;}// permet d'annuler l'action si le leader change d'avis ou est arriver la par hazard
		put GIVE_MONEY_TO key: LEADER_COMMAND in: msg;
		put int(values[answer]) key: AMOUNT in: msg;
		put com.dist_id key: DISTRICT_CODE in: msg;
		do send_message_from_leader(msg);	
	}
	
	action subventionner_ganivelle{
		string msg <- ""+SUBVENTIONNER_GANIVELLE+COMMAND_SEPARATOR+999/*pour un mettre un action_id bidon */;
		do send_message_to_commune(msg, selected_district.district_name);	
	}
	
	action subventionner_habitat_adapte{	
		string msg <- ""+SUBVENTIONNER_HABITAT_ADAPTE+COMMAND_SEPARATOR+999/*pour un mettre un action_id bidon */;
		do send_message_to_commune(msg, selected_district.district_name);	
	}
	
	action send_message_from_leader(map<string,unknown> msg){
		ask Network_Leader { do send to: LISTENER_TO_LEADER contents:msg; }		
	}
	
	action send_message_lever (Activated_Lever lev){
		ask Network_Leader{
			do send to: "activated_lever" contents:lev.build_map_from_attributes();
		}	
	}
	action send_message_to_commune(string msg, string adistrict_name){
		ask Network_Leader{
			do send to: adistrict_name contents:msg;
		}		
	}
			
	action create_districts{
		
		create District from: districts_shape with: [district_name::string(read("dist_sname")), district_code::string(read("dist_code")),
			dist_id::int(read("player_id")), district_long_name::string(read("dist_lname"))]{
			if(dist_id = 0) {	do die;	}
		}
		
		do create_lever_buttons;
		int nb_comm <- length(District);
		int nb_lev_comm <- int(length(all_levers accumulate each.population) / nb_comm); // nb de leviers par commune
		int nb_rows_comm <- 2 ; // nb de rangées de leviers par commune
		int width_screen_view <- 100;
		int height_screen_view <- 40;
		int nbr_rows <- nb_rows_comm * nb_comm;
		int nb_levs_row <- int(ceil(nb_lev_comm / nb_rows_comm));
		float row_spacing <- (height_screen_view / nbr_rows) *0.9;
		float column_spacing <- width_screen_view / (nb_lev_comm / nb_rows_comm) *0.9;
		
		int pos <-0;
		int num_column <-0;
		float num_row <-0.0;
		string previous_comm_name<-"";
		
		loop lev over: all_levers{
			ask lev.population {
				add self to: my_district.levers ;
				pos <-pos +1;
				num_column <- num_column +1;
				if previous_comm_name != my_district.district_name{
					num_column <-1;
					num_row <- num_row+1;
				}
				if num_column > nb_levs_row{
					num_column <-1;
					num_row <- num_row+0.7;
				}
				previous_comm_name <- my_district.district_name;
			}
		}
	}
	
	action create_lever_buttons {
		loop i from: 0 to: 3{
			loop j from: 0 to: length(all_levers) - 1{
				if levers_def at levers_names[j] at 'active' = 'yes'{
					create all_levers[j]{
						my_district <- District[i];
						location	<- (Grille[i, int(j/2) + 2]).location - {0, 3 + (-4.5 * j mod 2)};
					}
				}
			}
		}
	}
    
    user_command "Cancel the application of all activated levers" action: cancel_all_activated_levers;
    
	action cancel_all_activated_levers{
		loop lev over: all_levers{
			ask lev.population { activation_queue <-[]; }
		}
	}
}
//------------------------------ end of global -------------------------------//

species Player_Action schedules:[]{
	string id;
	int element_id;
	string district_code;
	string district_name 			<- "";
	int command 		 			<- -1 on_change: { label <- world.label_of_action(command); };
	string label 		 			<- "no name";
	int cost 			 			<- 0;
	int initial_application_round 	<- -1;
	int command_round 				<- -1;	
	bool is_applied -> { game_round >= initial_application_round };
	int round_delay	-> { activated_levers sum_of (each.nb_rounds_delay) } ; // number rounds of delay
	bool is_delayed -> { round_delay > 0 };
	
	string action_type 		<- ""; 					// COAST_DEF or LU
	string previous_ua_name <- "";  				// for LU action
	bool isExpropriation 	<- false; 				// for LU action
	bool inProtectedArea 	<- false; 				// for COAST_DEF action
	bool inCoastBorderArea 	<- false; 
	bool inRiskArea 		<- false; 				// for LU action
	bool isInlandDike 		<- false; 				// for COAST_DEF (retro dikes)
	string tracked_profile 	<- "";
	geometry element_shape;
	float lever_activation_time;
	int length_def_cote;
	list<Activated_Lever> activated_levers 	<-[];
	bool shouldWaitLeaderToActivate 		<- false;
	bool a_lever_has_been_applied			<- false;
	
	init {	shape <- rectangle(10#m,5#m);	}
	
	reflex save_data{
		ask world {
			save Player_Action to: "/tmp/player_action2.shp" type:"shp" crs: "EPSG:2154" with:[id::"id", cost::"cost", command_round::"cround",
					initial_application_round::"around", round_delay::"rdelay", is_delayed::"is_delayed", element_id::"chosenId",
					district_name::"district_name", command::"command", label::"label", tracked_profile::"tracked_profile", isInlandDike::"isInlandDike",
					inRiskArea::"inRiskArea", inCoastBorderArea::"inCoastBorderArea", inProtectedArea::"inProtectedArea", isExpropriation::"isExpropriation",
					previous_ua_name::"previous_ua_name", action_type::"action_type"];
		}
	}
	
	string track_profile {
		if(action_type = COAST_DEF){
			if isInlandDike { return SOFT_DEFENSE; }
			else{
				switch command {
					match_one  [ACTION_CREATE_DIKE, ACTION_RAISE_DIKE] 	{ return BUILDER; 		}
					match 		ACTION_INSTALL_GANIVELLE 				{ return SOFT_DEFENSE;  }
					match 		ACTION_DESTROY_DIKE						{ return WITHDRAWAL;	}
				}
			}
		}else {
			if isExpropriation { return WITHDRAWAL; }
			else {
				switch command {
					match_one [ACTION_MODIFY_LAND_COVER_AU, ACTION_MODIFY_LAND_COVER_U]   { return BUILDER; 	 }
					match_one [ACTION_MODIFY_LAND_COVER_AUs, ACTION_MODIFY_LAND_COVER_Us] { return SOFT_DEFENSE; }
				}
			}
		}
	}
	
	action init_from_map (map<string, string> a ){
		self.id 						<- a at "id";
		self.element_id 				<- int(a at "element_id");
		self.district_name 				<- a at "district_name";
		self.command 					<- int(a at "command");
		self.label 						<- a at "label";
		self.cost 						<- int(a at "cost");
		self.initial_application_round 	<- int(a at "initial_application_round");
		self.action_type 				<- a at "action_type"; // Pour l'instant ca marche pas. je sais pas pourquoi
		self.previous_ua_name 			<- a at "previous_ua_name";
		self.isExpropriation 			<- bool(a at "isExpropriation");
		self.inProtectedArea 			<- bool(a at "inProtectedArea");
		self.inCoastBorderArea 			<- bool(a at "inCoastBorderArea");
		self.inRiskArea 				<- bool(a at "inRiskArea");
		self.isInlandDike 				<- bool(a at "isInlandDike");
		self.command_round 				<- int(a at "command_round");
		self.tracked_profile 			<- track_profile ();
		self.element_shape 				<- geometry(a at "element_shape");
		self.length_def_cote 			<- int(a at "length_def_cote");
		self.a_lever_has_been_applied 	<- bool(a at "a_lever_has_been_applied");		
	}
	
	map<string,string> build_map_from_attributes{
		map<string,string> res <- [
			"OBJECT_TYPE"::"player_action",
			"id"::id,
			"element_id"::string(element_id),
			"district_name"::district_name,
			"command"::string(command),
			"label"::label,
			"cost"::string(cost),
			"initial_application_round"::string(initial_application_round),
			"action_type"::action_type,
			"previous_ua_name"::previous_ua_name,
			"isExpropriation"::isExpropriation,
			"inProtectedArea"::inProtectedArea,
			"inCoastBorderArea"::inCoastBorderArea,
			"inRiskArea"::inRiskArea,
			"isInlandDike"::isInlandDike,
			"command_round"::command_round]	;	
		return res;
	}
}
//------------------------------ End of Player_Action -------------------------------//

species District{
	int dist_id;
	string district_code;
	string district_name;
	string district_long_name;
	string budget;
	bool not_updated <- false;
	bool is_selected -> {selected_district = self};
	list<Lever> levers ;
	
	// indicators for leader
	int length_dikes_t0 								<- int(0#m);
	int length_dunes_t0 								<- int(0#m); 
	int count_LU_urban_t0 								<- 0;
	int count_LU_U_and_AU_is_in_coast_border_area_t0 		<- 0;
	int count_LU_urban_in_flood_risk_area_t0 			<- 0;
	int count_LU_urban_dense_in_flood_risk_area_t0 		<- 0;
	int count_LU_urban_dense_is_in_coast_border_area_t0 <- 0;
	int count_LU_A_t0 									<- 0; 
	int count_LU_N_t0 									<- 0; 
	int count_LU_AU_t0 									<- 0;
	int count_LU_U_t0 									<- 0;
	
	// updated indicators by Leader each time he receives a player action
	int length_created_dikes 								<- 0;
	int length_raised_dikes 								<- 0;
	int length_repaired_dikes 								<- 0;
	int length_destroyed_dikes 								<-0 ;
	int length_inland_dikes									<- 0;
	int length_created_ganivelles 							<- 0;
	int count_Us 											<- 0;
	int count_expropriation									<- 0;
	int count_Us_in_risk_area								<- 0;
	int count_AU_or_Ui_in_coast_border_area 				<- 0;
	int count_AU_or_Ui_in_risk_area 						<- 0;
	int count_Us_out_coast_border_or_risk_area				<- 0;
	int count_Us_in_coast_border_area						<- 0;					
	int count_A_to_N_in_coast_border_or_risk_area			<-0;
	int count_densification_out_coast_border_and_risk_area	<- 0;
	
	action update_indicators_and_register_player_action (Player_Action act){
		if act.is_applied {
			write world.get_message('LDR_MSG_ACTION_RECEIVED') + " : " + act.id + " -> " + world.get_message('LDR_MSG_ALREADY_VALIDATED');
		}
		if act.isExpropriation {	
			count_expropriation <- count_expropriation + 1;
			ask lever_expropriation where(each.my_district = self) { do register_and_check_activation(act); }
		}
		
		switch (act.command){
			match ACTION_CREATE_DIKE {
				if(act.isInlandDike){
					length_inland_dikes <- length_inland_dikes + act.length_def_cote;
					ask lever_inland_dike where(each.my_district = self) { do register_and_check_activation(act); }
				}else{
					length_created_dikes <- length_created_dikes + act.length_def_cote;
					ask lever_create_dike 		where(each.my_district = self) { do register_and_check_activation(act);	}
					ask lever_no_dike_creation 	where(each.my_district = self) { do register(act);						}
				}
			}
			match ACTION_RAISE_DIKE {
				length_raised_dikes <- length_raised_dikes + act.length_def_cote;
				ask lever_raise_dike 	where(each.my_district = self) { do register_and_check_activation(act); }
				ask lever_no_dike_raise where(each.my_district = self) { do register(act);						}
			}
			match ACTION_REPAIR_DIKE {
				length_repaired_dikes <- length_repaired_dikes + act.length_def_cote;
				ask lever_repair_dike 	 where(each.my_district = self) { do register_and_check_activation(act);}
				ask lever_no_dike_repair where(each.my_district = self) { do register(act);						}
			}
			match ACTION_DESTROY_DIKE{
				length_destroyed_dikes <- length_destroyed_dikes + act.length_def_cote;
				ask Lever_Destroy_Dike where(each.my_district = self) { do register_and_check_activation(act); }
			}
			match ACTION_INSTALL_GANIVELLE {
				length_created_ganivelles <- length_created_ganivelles + act.length_def_cote;
				ask lever_ganivelle where(each.my_district = self) { do register_and_check_activation(act); }
			}
			match ACTION_MODIFY_LAND_COVER_Us {
				count_Us <- count_Us +1;
				if !act.inRiskArea and !act.inCoastBorderArea {
					count_Us_out_coast_border_or_risk_area <- count_Us_out_coast_border_or_risk_area +1;
					ask lever_Us_outCoastBorderOrRiskArea where(each.my_district = self) { do register_and_check_activation(act); }
				} else{
					if act.inCoastBorderArea {
					count_Us_in_coast_border_area <- count_Us_in_coast_border_area +1;
					ask lever_Us_inCoastBorderArea where(each.my_district = self) { do register_and_check_activation(act); }
					}
					if act.inRiskArea {
						count_Us_in_risk_area <- count_Us_in_risk_area +1;
						ask lever_Us_inRiskArea where(each.my_district = self) { do register_and_check_activation(act); }
					}
				}
			}
			match ACTION_MODIFY_LAND_COVER_N {
				if act.previous_ua_name = "A" and (act.inCoastBorderArea or act.inRiskArea) {
					count_A_to_N_in_coast_border_or_risk_area <- count_A_to_N_in_coast_border_or_risk_area + 1;
					ask lever_AtoN_inCoastBorderOrRiskArea where(each.my_district = self) {
						do register (act);
						do checkActivation_andImpactOnFirstElementOf (myself.actions_densification_out_coast_border_and_risk_area());
					}
				}
			}
			match_one [ACTION_MODIFY_LAND_COVER_Ui, ACTION_MODIFY_LAND_COVER_AU] {
				if act.command = ACTION_MODIFY_LAND_COVER_Ui and !act.inCoastBorderArea and !act.inRiskArea {	
					count_densification_out_coast_border_and_risk_area <- count_densification_out_coast_border_and_risk_area + 1;
					ask lever_densification_outCoastBorderAndRiskArea where(each.my_district = self) { do register_and_check_activation (act); }
				}
				else{
					if act.inCoastBorderArea and act.previous_ua_name != "Us"{
						count_AU_or_Ui_in_coast_border_area <- count_AU_or_Ui_in_coast_border_area + 1;
						ask lever_AUorUi_inCoastBorderArea where(each.my_district = self) {	do register_and_check_activation(act); }
					}
					if act.inRiskArea {
						count_AU_or_Ui_in_risk_area <- count_AU_or_Ui_in_risk_area + 1;
						ask lever_AUorUi_inRiskArea where(each.my_district = self) { do register_and_check_activation(act); }
					}	
				}
			}
		}
	}
	
	list<Player_Action> actions_install_ganivelle {
		return ( (lever_ganivelle first_with (each.my_district = self)).associated_actions sort_by (-each.command_round) );
	}
	
	list<Player_Action> actions_densification_out_coast_border_and_risk_area{
		return ( (lever_densification_outCoastBorderAndRiskArea first_with(each.my_district = self)).associated_actions sort_by(-each.command_round) );
	}
	
	list<Player_Action> actions_expropriation{
		return ( (lever_expropriation first_with(each.my_district = self)).associated_actions sort_by(-each.command_round) );
	}
}
//------------------------------ End of District -------------------------------//

species Activated_Lever {
	Player_Action p_action;
	float activation_time;
	bool applied <- false;
	//attributes sent through network
	int id 					 <- length(Activated_Lever);
	string district_code;
	string lever_name;
	string lever_explanation <- "";
	string p_action_id 		 <- "";
	int nb_rounds_delay 	 <- 0;
	int added_cost 			 <- 0;
	int round_creation;
	int round_application;
	
	action init_from_map(map<string, string> m ){
		id 					<- int(m["id"]);
		lever_name 			<- m["lever_name"];
		district_code 		<- m["district_code"];
		p_action_id 		<- m["p_action_id"];
		added_cost 			<- int(m["added_cost"]);
		nb_rounds_delay 	<- int(m["nb_rounds_delay"]);
		lever_explanation 	<- m["lever_explanation"];
		round_creation 		<- int(m["round_creation"]);
		round_application	<- int(m["round_application"]);
	}
	
	map<string,string> build_map_from_attributes{
		map<string,string> res <- [
			"OBJECT_TYPE"::"Activated_Lever",
			"id"::id,
			"lever_name"::lever_name,
			"district_code"::district_code,
			"p_action_id"::p_action_id,
			"added_cost"::string(added_cost),
			"nb_rounds_delay"::nb_rounds_delay,
			"lever_explanation"::lever_explanation,
			"round_creation"::round_creation,
			"round_application"::round_application]	;
		return res;
	}
}
//------------------------------ End of Activated_Lever -------------------------------//

species Lever {
	
	user_command "Change the treshold value of this lever" 				action: change_lever_threshold_value;
	user_command "Change the message sent to the player"  				action: change_lever_player_msg;
	user_command "Cancel the next application of this lever" 			action: cancel_next_activated_action when: status_on;
	user_command "Validate the next application of this lever" 			action: accept_next_activated_action when: status_on;
	user_command "Validate all current applications of this lever" 		action: accept_all_activated_action  when: status_on;
	user_command "Activate/Deactivate this lever" 						action: toggle_status;
	user_command "How this lever works ?" 								action: write_help_lever_msg;
	
	District my_district;
	float threshold;
	float indicator;
	bool status_on 			 	<- true;							// can be on or off . If off then the checkLeverActivation is not performed
	bool should_be_activated 	-> { indicator > threshold };
	bool threshold_reached 	 	<- false;
	bool timer_activated 	 	-> { !empty(activation_queue) };
	bool has_activated_levers	-> { !empty(activated_levers) };
	int timer_duration 		 	<- 240000;							// 1 minute = 60000 milliseconds //   4 mn = 240000
	string lever_type		 	<-	"";
	string lever_name		 	<-	"";
	string box_title 		 	-> {lever_name +' ('+length(associated_actions)+')'};
	string progression_bar		<-	"";
	string help_lever_msg 	 	<-	"";
	string activation_label_L1	<-	"";
	string activation_label_L2	<-	"";
	string player_msg;
	list<Player_Action>   associated_actions;
	list<Activated_Lever> activation_queue;
	list<Activated_Lever> activated_levers;
	
	init { shape <- rectangle (20,4); }
	
	aspect default{
		if timer_activated {draw shape+0.2#m color: #red;}
		draw shape color: color_profile() border:#black at:location;
		draw box_title at: location -{length(box_title)/4,0.75} font: font("Arial", 12 , #bold) color:#black;
		//float v_pos <-0.5;
		draw progression_bar at:location + {-length(progression_bar)/4,0.5} font: font("Arial", 12 , #plain) color: threshold_reached?#red:#black;
		//v_pos<-v_pos+0.5;
		if timer_activated {
			draw string(remaining_seconds())+" sec "+(length(activation_queue)=1?"":"("+length(activation_queue)+")")+"-> " + info_of_next_activated_lever() at:location + {-9,1.5} font: font("Arial", 12 , #plain) color:#black;
		}
		//*v_pos<-v_pos+0.5;
		if has_activated_levers {
			draw activation_label_L1 at:location+{0,2.5} font: font("Arial", 12 , #plain) color:#black;
			//v_pos<-v_pos+0.5;
			draw activation_label_L2 at:location+{0,3} font: font("Arial", 12 , #plain) color:#black;
		}
		if !status_on{
			draw shape+0.1#m color: rgb(200,200,200,160) ;
		}
	}
    
	action register_and_check_activation (Player_Action p_action){
		do register(p_action);
		do checkActivation_andImpactOn(p_action);
	}
	
	action register (Player_Action p_action){
		add p_action to: associated_actions;	
	}
	action checkActivation_andImpactOn (Player_Action p_action){
		if  status_on{ //and !p_action.is_applied 
			if should_be_activated{ //and !p_action.a_lever_has_been_applied
				threshold_reached <- true;
				do queue_activated_lever(p_action);
			}
			else{	threshold_reached <- false;	}	
		}
	}
	
	action apply_lever(Activated_Lever lev);
	
	string info_of_next_activated_lever { return ""; }
	
	action check_activation_at_new_round;
	
	action cancel_lever(Activated_Lever lev);
	
	action checkActivation_andImpactOnFirstElementOf (list<Player_Action> list_p_action){
		if !empty(list_p_action){
			do checkActivation_andImpactOn(list_p_action[0]);
		}
	}
	
	action queue_activated_lever( Player_Action a_p_action){
		create Activated_Lever number: 1 {
			lever_name <- myself.lever_name;
			district_code <- myself.my_district.district_code;
			self.p_action <- a_p_action;
			p_action_id <- a_p_action.id;
			activation_time <-  machine_time + myself.timer_duration ;
			round_creation <- game_round;
			add self to: myself.activation_queue;
		}
		ask world {do record_leader_activity("Levier "+myself.lever_name+" programmé à ", myself.my_district.district_name, a_p_action.label +"("+a_p_action+")");}
	}

	action toggle_status {
		status_on <- !status_on ;
		if !status_on { activation_queue <-[]; }
	}
	
	action write_help_lever_msg {
		map values <- user_input("Explication du levier",[help_lever_msg+"\nValeur seuil : "+threshold:: ""]);
	}
	
	string texte_infobulle {
		return "" + help_lever_msg + " / " + world.get_message('LEV_THRESHOLD_VALUE') + " : " + threshold;
	}
	
	action change_lever_player_msg {
		map values <- user_input("Message envoyé au joueur lorsque le levier se déclenche",
			["Message :":: player_msg]);
		player_msg <- string(values["Message :"]);
		ask world {do record_leader_activity("Changer levier "+myself.lever_name+" à ", myself.my_district.district_name, "-> Le nouveau message envoyé au joueur est : "+ myself.player_msg);}
	}
	action change_lever_threshold_value{
		map values <- user_input(("Le seuil actuel du levier "+lever_name+"\nest de "+string(threshold)),["Entrer la nouvelle valeur seuil du levier :":: threshold]);
		float n_val  <- float(values["Entrer la nouvelle valeur seuil du levier :"]);
		threshold <- n_val ;
		
		ask world {do record_leader_activity("Changer levier "+myself.lever_name+" à ", myself.my_district.district_name, "-> La nouvelle valeur seuil est : "+string(myself.threshold));}	
	}
	
	float activation_time{
		return activation_queue[0].activation_time;
	}
	
	reflex check_timer when: timer_activated{
		if machine_time > activation_time(){
			Activated_Lever act_lever <- activation_queue[0];
			remove index: 0 from: activation_queue ;
			add act_lever to: activated_levers;
			do apply_lever(act_lever);
		}
	}
	
	int remaining_seconds {
		return (int((activation_time() -machine_time) / 1000));
	}
	
	action cancel_next_activated_action{		
		if !empty(activation_queue){
			do cancel_lever(activation_queue[0]);
			ask world {do record_leader_activity("Levier "+myself.lever_name+" annulé à ", myself.my_district.district_name,  " Annulation de " +myself.activation_queue[0].p_action);}
			remove index: 0 from: activation_queue ;	
		}
	}

	action accept_next_activated_action{		
		if !empty(activation_queue){
			activation_queue[0].activation_time <- machine_time ;
		} 	
	}

	action accept_all_activated_action{	
		loop aa over: activation_queue{
			aa.activation_time <- machine_time ;
		} 	
	}
	
	rgb color_profile{
		switch lever_type{
			match "builder" {return #deepskyblue;}
			match "soft defense" {return #lightgreen;}
			match "withdrawal" {return #moccasin;}
			match "" {return #darkgrey;}
			default {return #red;}
		}
	}
}
//------------------------------ End of Lever -------------------------------//

species cost_lever parent: Lever{ 
	
	user_command "Change the % impact on the price" action: change_lever_added_cost_percentage;
	
	float added_cost_percentage;
	int last_lever_amount <-0;
	
	action change_lever_added_cost_percentage{
		map values <- user_input(("Le % actuel par rapport au cout du levier "+lever_name+"\nest de "+string(added_cost_percentage)),["Entrer le nouveau % :":: added_cost_percentage]);
		float n_val <- float(values["Entrer le nouveau % :"]);
		added_cost_percentage <- n_val;
		
		ask world {
			do record_leader_activity("Changer levier "+myself.lever_name+" à ", myself.my_district.district_name, "-> Le nouveau % du levier est : "+string(myself.added_cost_percentage));
		}
	}
	
	string info_of_next_activated_lever {
		return ""+ activation_queue[0].p_action.length_def_cote + " m. (" + int(activation_queue[0].p_action.cost * added_cost_percentage) + ' By.)';
	}
	
	action apply_lever(Activated_Lever lev){
		lev.applied <- true;
		lev.round_application <- game_round;
		lev.lever_explanation <- player_msg;
		lev.added_cost <- int(lev.p_action.cost * added_cost_percentage);
		
		ask world {do send_message_lever(lev) ;}
		
		last_lever_amount <-lev.added_cost;
		activation_label_L1 <- "Dernier "+(last_lever_amount>=0?"prélevement":"versement")+" : "+abs(last_lever_amount)+ ' By.';
		activation_label_L2 <- "Total "+(last_lever_amount>=0?"prélevé":"versé")+" : "+string(abs(tot_lever_amont()))+' By';
		
		ask world {do record_leader_activity("Levier "+myself.lever_name+" validé à ", myself.my_district.district_name, myself.help_lever_msg + " : "+(lev.added_cost)+"By"+"("+lev.p_action+")");}
	}
	
	int tot_lever_amont {
		return activated_levers sum_of (each.added_cost);
	}
}

species delay_lever parent: Lever{

	user_command "Change the % impact on the delay" action: change_lever_rounds_delay_added;
	
	int rounds_delay_added;

	action change_lever_rounds_delay_added{
		map values <- user_input(("Le nb de tours de délai actuel du levier "+lever_name+"\nest de "+string(rounds_delay_added)),["Entrer le nouveau nb :":: rounds_delay_added]);
		int n_val <- int(values["Entrer le nouveau nb :"]);
		rounds_delay_added <- n_val;
		
		ask world {do record_leader_activity("Changer levier "+myself.lever_name+" à ", myself.my_district.district_name, "-> Le nouveau nb de tours du levier est : "+string(myself.rounds_delay_added));}
	}
	
	action checkActivation_andImpactOn (Player_Action p_action){
		if  status_on{ //and !p_action.is_applied
			if should_be_activated{ //and !p_action.a_lever_has_been_applied
				threshold_reached <- true;
				do queue_activated_lever(p_action);
				p_action.shouldWaitLeaderToActivate <- true;
				do inform_network_should_wait_lever_to_activate(p_action);
			}
			else {threshold_reached <- false;}	
		}
	} 
	
	action apply_lever(Activated_Lever lev){
		lev.applied <- true;
		lev.lever_explanation <- player_msg;
		lev.nb_rounds_delay <- rounds_delay_added;
		
		ask world {do send_message_lever(lev) ;}
		
		int aTot <- tot_lever_delay();
		if aTot < 0 {
			activation_label_L1 <- "Avance total: "+string(abs(tot_lever_delay()))+' tours';
		}
		else{
			activation_label_L1 <- "Retard total: "+string(abs(tot_lever_delay()))+' tours';
		}
		
		lev.p_action.shouldWaitLeaderToActivate <- false;
		do inform_network_should_wait_lever_to_activate(lev.p_action);
		
		ask world {do record_leader_activity(myself.lever_name+" déclenché à ", myself.my_district.district_name, myself.help_lever_msg + " : "+(lev.nb_rounds_delay)+" tours"+"("+lev.p_action+")");}
	}
	
	action cancel_lever(Activated_Lever lev){
		lev.p_action.shouldWaitLeaderToActivate <- false;
		do inform_network_should_wait_lever_to_activate(lev.p_action);
	}
	
	int tot_lever_delay {
		return activated_levers sum_of (each.nb_rounds_delay);
	}
	
	action inform_network_should_wait_lever_to_activate(Player_Action p_action){
		map<string, unknown> msg <-[];
		put ACTION_SHOULD_WAIT_LEVER_TO_ACTIVATE key: LEADER_COMMAND 						in: msg;
		put my_district.district_code 			 key: DISTRICT_CODE  						in: msg;
		put p_action.id 						 key: PLAYER_ACTION_ID 						in: msg;
		put p_action.shouldWaitLeaderToActivate  key: ACTION_SHOULD_WAIT_LEVER_TO_ACTIVATE 	in: msg;
		ask world { do send_message_from_leader(msg); }
	}
}

species lever_create_dike parent: cost_lever{
	float indicator -> {my_district.length_created_dikes / my_district.length_dikes_t0};
	string progression_bar -> {""+my_district.length_created_dikes+ " m. / "+threshold+" * "+ my_district.length_dikes_t0+" m. à t0"};
	
	init{
		lever_name <- world.get_lever_name('LEVER_CREATE_DIKE');
		lever_type<- world.get_lever_type('LEVER_CREATE_DIKE');
		threshold <- 0.2;
		added_cost_percentage <- 0.25 ;
		help_lever_msg <-"prélevement de la commune au prorata du linéaire construit : "+int(100*added_cost_percentage)+"% du prix de construction";
		player_msg <- "Les autorites reorientent leur politique : vos actions vous coutent plus cher que prevu";	
	}
}

species lever_raise_dike parent: cost_lever{
	float indicator -> {my_district.length_raised_dikes / my_district.length_dikes_t0};
	string progression_bar -> {""+my_district.length_raised_dikes+ " m. / "+threshold+" * "+ my_district.length_dikes_t0+" m. à t0"};
	init{
		lever_name <- world.get_lever_name('LEVER_RAISE_DIKE');
		lever_type<- world.get_lever_type('LEVER_RAISE_DIKE');
		threshold <- 0.2;
		added_cost_percentage <- 0.25 ;
		help_lever_msg <-"prélevement de la commune au prorata du linéaire réhaussé : "+int(100*added_cost_percentage)+"% du prix de réhaussement";
		player_msg <- "Les autorites reorientent leur politique : vos actions vous coutent plus cher que prevu";
	}
}

species lever_repair_dike parent: cost_lever{
	float indicator -> {my_district.length_repaired_dikes / my_district.length_dikes_t0};
	bool should_be_activated -> {indicator > threshold and (my_district.length_created_dikes != 0 or my_district.length_raised_dikes != 0)};
	string progression_bar -> {""+my_district.length_repaired_dikes+ " m. / "+threshold+" * "+ my_district.length_dikes_t0+" m. à t0"};
	
	init{
		lever_name <- world.get_lever_name('LEVER_REPAIR_DIKE');
		lever_type<- world.get_lever_type('LEVER_REPAIR_DIKE');
		threshold <- 0.2;
		added_cost_percentage <- 0.25 ;
		help_lever_msg <-"prélevement de la commune au prorata du linéaire rénové : "+int(100*added_cost_percentage)+"% du prix de rénovation ; si a aussi construit ou réhaussé";
		player_msg <- "Les coûts dans les BTP augmentent considérablement";
	}
}


species lever_AUorUi_inCoastBorderArea parent: delay_lever{
	string progression_bar -> {""+indicator + " actions / "+ int(threshold) + " max"};
	int indicator -> {my_district.count_AU_or_Ui_in_coast_border_area};
	
	init{
		lever_name <- world.get_lever_name('LEVER_AU_Ui_COAST_BORDER_AREA');
		lever_type<- world.get_lever_type('LEVER_AU_Ui_COAST_BORDER_AREA');
		rounds_delay_added <- 2;
		threshold <- 2.0;
		help_lever_msg <-"Retard de "+rounds_delay_added+" tours";
		player_msg <- "Un renforcement de la loi Littoral retarde vos projets";	
	}
		
	string info_of_next_activated_lever {
		switch activation_queue[0].p_action.command {
			match ACTION_MODIFY_LAND_COVER_AU {return "Construction: +"+rounds_delay_added+ " tours";}
			match ACTION_MODIFY_LAND_COVER_Ui {return "Densification: +"+ rounds_delay_added+ " tours";}
		} 
	}
}

species lever_AUorUi_inRiskArea parent: cost_lever{
	string progression_bar -> {""+indicator + " actions / "+ int(threshold) + " max"};
	int indicator -> {my_district.count_AU_or_Ui_in_risk_area};
	
	init{
		lever_name <- world.get_lever_name('LEVER_AU_Ui_RISK_AREA');
		lever_type<- world.get_lever_type('LEVER_AU_Ui_RISK_AREA');
		threshold <- 1.0;
		added_cost_percentage <- 0.5 ;
		help_lever_msg <-"prélevement de la commune à hauteur de "+int(100*added_cost_percentage)+"% du coût de construction";
		player_msg <- "Les coûts dans les BTP augmentent considérablement";	
	}
		
	string info_of_next_activated_lever {
		switch activation_queue[0].p_action.command {
			match ACTION_MODIFY_LAND_COVER_AU {return "-"+ int(activation_queue[0].p_action.cost * added_cost_percentage) +" By sur la prochaine construction";}
			match ACTION_MODIFY_LAND_COVER_Ui {return "-"+ int(activation_queue[0].p_action.cost * added_cost_percentage) +" By sur la prochaine densification";}
		} 
	}
}

species lever_ganivelle parent: cost_lever{
	string progression_bar -> {""+my_district.length_created_ganivelles+ " m. / "+threshold+" * "+ my_district.length_dunes_t0+" m. dunes"};
	int indicator -> {int(my_district.length_created_ganivelles / my_district.length_dunes_t0)};
	
	init{
		lever_name <- world.get_lever_name('LEVER_GANIVELLE');
		lever_type<- world.get_lever_type('LEVER_GANIVELLE');
		threshold <- 0.1;
		added_cost_percentage <- -0.25 ;
		help_lever_msg <-"Versement à la commune à hauteur de "+int(100*added_cost_percentage)+"% du coût de ganivelle/m";
		player_msg <- "Le gouvernement encourage les pratiques vertueuses de gestion intégrée des risques";
	}
}

species lever_Us_outCoastBorderOrRiskArea parent: cost_lever{
	string progression_bar -> {""+indicator + " actions / "+ int(threshold) + " max"};
	int indicator -> {my_district.count_Us_out_coast_border_or_risk_area};
	int rounds_delay_added <- 0; //    -2;    ANNULE POUR L INSTANT CAR INCOHERENT
	
	init{
		lever_name <- world.get_lever_name('LEVER_Us_COAST_BORDER_RISK_AREA');
		lever_type<- world.get_lever_type('LEVER_Us_COAST_BORDER_RISK_AREA');
		threshold <- 2.0;
		added_cost_percentage <- -0.25 ;
		help_lever_msg <-"Versement à la commune à hauteur de "+int(100*added_cost_percentage)+"% du coût d'adaptation"; // ET avance de "+rounds_delay_added+" tours le dossier" ;
		player_msg <- "Le gouvernement encourage les pratiques vertueuses de gestion intégrée des risques";
	}
	
	string info_of_next_activated_lever {
		return "+"+ abs(int(activation_queue[0].p_action.cost * added_cost_percentage)) +" By pour la prochaine adaptation";
	}
	
	action apply_lever(Activated_Lever lev){
		lev.applied <- true;
		lev.lever_explanation <- player_msg;
		lev.added_cost <- int(lev.p_action.cost * added_cost_percentage);
		lev.nb_rounds_delay <- rounds_delay_added;
		
		ask world {do send_message_lever(lev) ;}
		
		last_lever_amount <-lev.added_cost;
		activation_label_L1 <- "Dernier versement : "+(-1*last_lever_amount)+ ' By';
		activation_label_L2 <- 'Total versé : '+string((-1*tot_lever_amont()))+' By';
		
		ask world {do record_leader_activity(myself.lever_name+" déclenché à ", myself.my_district.district_name, myself.help_lever_msg + " : "+lev.added_cost+"Ny : "+lev.nb_rounds_delay+" tours"+"("+lev.p_action+")");}
			
	}
}

species lever_Us_inCoastBorderArea parent: cost_lever{
	string progression_bar -> {""+my_district.count_Us_in_coast_border_area + " actions / " + int(threshold) +" max"};
	int indicator -> {my_district.count_Us_in_coast_border_area };
	
	init{
		lever_name <- world.get_lever_name('LEVER_Us_COAST_BORDER_AREA');
		lever_type<- world.get_lever_type('LEVER_Us_COAST_BORDER_AREA');
		threshold <- 2.0;
		added_cost_percentage <- -0.5 ;
		help_lever_msg <-"Versement à la commune à hauteur de "+int(100*added_cost_percentage)+"% du coût d'adaptation";
		player_msg <- "L'Etat encourage les stratégies de réduction de la vulnérabilité";
	}
		
	string info_of_next_activated_lever{
		return "+"+ abs(int(activation_queue[0].p_action.cost * added_cost_percentage)) +" By pour la prochaine adaptation";
	}		
}

species lever_Us_inRiskArea parent: cost_lever{
	string progression_bar -> {""+my_district.count_Us_in_risk_area + " actions / " + int(threshold) +" max"};
	int indicator -> {my_district.count_Us_in_risk_area };
	
	init{
		lever_name <- world.get_lever_name('LEVER_Us_RISK_AREA');
		lever_type<- world.get_lever_type('LEVER_Us_RISK_AREA');
		threshold <- 2.0;
		added_cost_percentage <- -0.5 ;
		help_lever_msg <-"Versement à la commune à hauteur de "+int(100*added_cost_percentage)+"% du coût d'adaptation";
		player_msg <- "L'Etat encourage les stratégies de réduction de la vulnérabilité";
	}

	string info_of_next_activated_lever{
		return "+"+ abs(int(activation_queue[0].p_action.cost * added_cost_percentage)) +" By pour la prochaine adaptation";
	}		
}

species lever_inland_dike parent: delay_lever{
	float indicator -> {my_district.length_inland_dikes / my_district.length_dikes_t0};
	string progression_bar -> {""+my_district.length_inland_dikes+ " m. / "+threshold+" * "+ my_district.length_dikes_t0+" m. digues à t0"};
	init{
		lever_name <- world.get_lever_name('LEVER_INLAND_DIKE');
		lever_type<- world.get_lever_type('LEVER_INLAND_DIKE');
		rounds_delay_added <- -1;
		threshold <- 0.01;
		help_lever_msg <-"Avance de "+abs(rounds_delay_added)+" tour"+(abs(rounds_delay_added)>1?"s":"");
		player_msg <- "Des aides existent de la part du gouvernement pour renforcer la gestion intégrée des risques";	
	}
		
	string info_of_next_activated_lever {
		return "Rétrodigue ("+int(activation_queue[0].p_action.length_def_cote) + " m.): -"+abs(rounds_delay_added)+ " tours";
	}
}

species cost_lever_if_no_associatedActionA_for_N_rounds_with_impacted_on_actionB parent: cost_lever {
	int nb_rounds_before_activation;
	int nb_activations <-0;
	string box_title -> {lever_name +' ('+nb_activations+')'};
	bool should_be_activated -> { (nb_rounds_before_activation  <0) and !empty(listOfImpactedAction)};
	list<Player_Action> listOfImpactedAction;
	
	action register (Player_Action p_action){
		add p_action to: associated_actions;
		nb_rounds_before_activation <- int(threshold);	
	}	

	action check_activation_at_new_round{
		if game_round > 1{
			nb_rounds_before_activation <- nb_rounds_before_activation - 1;
			do checkActivation_andImpactOnFirstElementOf(listOfImpactedAction);
		}
	}
	
	string progression_bar -> {""+int(threshold-nb_rounds_before_activation) + " tours / "+int(threshold)+" max"};
	
	action apply_lever(Activated_Lever lev){
		lev.applied <- true;
		lev.lever_explanation <- player_msg;
		lev.added_cost <- int(lev.p_action.cost * added_cost_percentage);
		
		ask world {do send_message_lever(lev) ;}
		
		last_lever_amount <-lev.added_cost;
		activation_label_L1 <- "Dernier "+(last_lever_amount>=0?"prélevement":"versement")+" : "+abs(last_lever_amount)+ ' By.';
		activation_label_L2 <- "Total "+(last_lever_amount>=0?"prélevé":"versé")+" : "+string(abs(tot_lever_amont()))+' By';
		
		nb_rounds_before_activation <- int(threshold);
		nb_activations <- nb_activations +1;
		
		ask world {do record_leader_activity(myself.lever_name+" déclenché à ", myself.my_district.district_name, myself.help_lever_msg + " : "+(lev.added_cost)+"By"+"("+lev.p_action+")");}
	}
}

species lever_no_action_on_dike parent: cost_lever_if_no_associatedActionA_for_N_rounds_with_impacted_on_actionB{
	list<Player_Action> listOfImpactedAction -> {my_district.actions_install_ganivelle()};
	init{
		threshold <- 2.0; // tours
		nb_rounds_before_activation <- int(threshold);
		added_cost_percentage <- -0.5 ;
		player_msg <- "Le gouvernement encourage les pratiques vertueuses de gestion intégrée des risques";
	}
		
	string info_of_next_activated_lever {
		return "Dernière ganivelle -" + abs(int(activation_queue[0].p_action.cost * added_cost_percentage)) + ' By';
	}	
}

species lever_no_dike_creation parent: lever_no_action_on_dike{
	init{
		lever_name <- world.get_lever_name('LEVER_NO_DIKE_CREATION');
		lever_type<- world.get_lever_type('LEVER_NO_DIKE_CREATION');
		help_lever_msg <-"Durant "+threshold+" tours consécutifs le joueur ne contruit pas de digue.\nVersement à la commune à hauteur de "+int(100*added_cost_percentage)+"% du coût de Ganivelle/m";
	}	
}

species lever_no_dike_raise parent: lever_no_action_on_dike{
	init{
		lever_name <- world.get_lever_name('LEVER_NO_DIKE_RAISE');
		lever_type<- world.get_lever_type('LEVER_NO_DIKE_RAISE');
		help_lever_msg <-"Durant "+threshold+" tours consécutifs le joueur ne réhausse pas de digue.\nVersement à la commune à hauteur de "+int(100*added_cost_percentage)+"% du coût de Ganivelle/m";
	}
}

species lever_no_dike_repair parent: lever_no_action_on_dike{
	init{
		lever_name <- world.get_lever_name('LEVER_NO_DIKE_REPAIR');
		lever_type<- world.get_lever_type('LEVER_NO_DIKE_REPAIR');
		help_lever_msg <-"Durant "+threshold+" tours consécutifs le joueur ne rénove pas de digue.\nVersement à la commune à hauteur de "+int(100*added_cost_percentage)+"% du coût de Ganivelle/m";
	}
}

species lever_AtoN_inCoastBorderOrRiskArea parent: cost_lever{
	string progression_bar -> {""+my_district.count_A_to_N_in_coast_border_or_risk_area + " actions / " + int(threshold) +" max"};
	bool should_be_activated -> {indicator > threshold and !empty(my_district.actions_densification_out_coast_border_and_risk_area())};
	int indicator -> {my_district.count_A_to_N_in_coast_border_or_risk_area };
	
	init{
		lever_name <- world.get_lever_name('LEVER_A_N_COAST_BORDER_RISK_AREA');
		lever_type<- world.get_lever_type('LEVER_A_N_COAST_BORDER_RISK_AREA');
		threshold <- 2.0;
		added_cost_percentage <- -0.5 ;
		help_lever_msg <-"Versement à la commune à hauteur de "+int(100*added_cost_percentage)+"% du coût d'une densification préalablement réalisée hors ZL et ZI";
		player_msg <- "Le gouvernement encourage les pratiques vertueuses de gestion intégrée des risques";
	}

	string info_of_next_activated_lever {
		return "+" + abs(int(activation_queue[0].p_action.cost * added_cost_percentage)) + ' By sur la dernière densification hors ZL&ZI';
	}	
}

species lever_densification_outCoastBorderAndRiskArea parent: cost_lever{
	string progression_bar -> {""+my_district.count_densification_out_coast_border_and_risk_area + " actions / " + int(threshold) +" max"};
	int indicator -> {my_district.count_densification_out_coast_border_and_risk_area };
	
	init{
		lever_name <- world.get_lever_name('LEVER_DENSIFICATION_COAST_BORDER_RISK_AREA');
		lever_type<- world.get_lever_type('LEVER_DENSIFICATION_COAST_BORDER_RISK_AREA');
		threshold <- 2.0;
		added_cost_percentage <- -0.25 ;
		help_lever_msg <-"Versement à la commune à hauteur de "+int(100*added_cost_percentage)+"% du coût de densification";
		player_msg <- "Le gouvernement encourage les pratiques vertueuses de gestion intégrée des risques";
	}
	
	string info_of_next_activated_lever {
		return "+" + abs(int(activation_queue[0].p_action.cost * added_cost_percentage)) + ' By sur la dernière densification hors ZL&ZI';
	}			
}

species lever_expropriation parent: cost_lever{
	string progression_bar -> {""+my_district.count_expropriation + " expropriation / " + int(threshold) +" max"};
	int indicator -> {my_district.count_expropriation };
	
	init{
		lever_name <- world.get_lever_name('LEVER_EXPROPRIATION');
		lever_type<- world.get_lever_type('LEVER_EXPROPRIATION');
		threshold <- 1.0;
		added_cost_percentage <- -0.25 ;
		help_lever_msg <-"Versement à la commune à hauteur de "+int(100*added_cost_percentage)+"% du coût d'expropriation";
		player_msg <- "Une aide spéciale est versée aux communes engagées dans une stratégie de recul stratégique";
	}	
		
	string info_of_next_activated_lever {
		return "+" + abs(int(activation_queue[0].p_action.cost * added_cost_percentage)) + ' By sur la dernière expropriation';
	}		
}

species Lever_Destroy_Dike parent: cost_lever{
	float indicator -> {my_district.length_destroyed_dikes / my_district.length_dikes_t0};
	bool should_be_activated -> {indicator > threshold and !empty(my_district.actions_expropriation())};
	string progression_bar -> {""+my_district.length_destroyed_dikes+ " m. / "+threshold+" * "+ my_district.length_dikes_t0+" m. à t0"};
	
	init{
		lever_name <- world.get_lever_name('LEVER_DESTROY_DIKE');
		lever_type <- world.get_lever_type('LEVER_DESTROY_DIKE');
		threshold <- 0.01;
		added_cost_percentage <- -0.5 ;
		help_lever_msg <-"Versement à la commune à hauteur de "+int(100*added_cost_percentage)+"% du coût de démantellement ; si a aussi exproprié";
		player_msg <- "Une aide spéciale est versée aux communes engagées dans une stratégie de recul stratégique";	
	}
		
	string info_of_next_activated_lever {
		return "+" + abs(int(activation_queue[0].p_action.cost * added_cost_percentage)) + ' By sur le dernier démantellement';
	}	
}
//------------------------------ end of Lever_Destroy_Dike -------------------------------//

species Network_Leader skills:[network] {
	
	init{
		do connect to: SERVER with_name: GAME_LEADER;
		map<string, unknown> msg <-[];
		put ASK_NUM_ROUND	  		key: LEADER_COMMAND 		in: msg;
		do  send 			  		to:  LISTENER_TO_LEADER 	contents: msg;
		put ASK_ACTION_STATE 		key: LEADER_COMMAND 		in: msg;
		do  send 					to:  LISTENER_TO_LEADER 	contents: msg;
		put ASK_INDICATORS_T0 		key: LEADER_COMMAND 		in: msg;
		do 	send 			  		to:  LISTENER_TO_LEADER 	contents: msg;
	}
	
	reflex wait_message{
		loop while:has_more_message(){
			message msg 					<- fetch_message();
			string m_sender 				<- msg.sender;
			map<string, string> m_contents 	<- msg.contents;
			
			switch(m_contents[RESPONSE_TO_LEADER]) {
				match NUM_ROUND				{
					game_round <-int (m_contents[NUM_ROUND]);
					write world.get_message("MSG_ROUND") + " " + game_round;
					loop lev over: all_levers{
						ask lev.population { do check_activation_at_new_round(); }	
					}
					ask world { do save_leader_records;	}
				}
				
				match ACTION_STATE { do update_action (m_contents); }

				match INDICATORS_T0 		{
					ask District where (each.district_code = m_contents[DISTRICT_CODE]) {
						length_dikes_t0 								<- int (m_contents['length_dikes_t0']);
						length_dunes_t0 								<- int (m_contents['length_dunes_t0']);
						count_LU_urban_t0 								<- int (m_contents['count_LU_urban_t0']);
						count_LU_U_and_AU_is_in_coast_border_area_t0 	<- int (m_contents['count_LU_U_and_AU_is_in_coast_border_area_t0']);
						count_LU_urban_in_flood_risk_area_t0 			<- int (m_contents['count_LU_urban_in_flood_risk_area_t0']);
						count_LU_urban_dense_in_flood_risk_area_t0 		<- int (m_contents['count_LU_urban_dense_in_flood_risk_area_t0']);
						count_LU_urban_dense_is_in_coast_border_area_t0	<- int (m_contents['count_LU_urban_dense_is_in_coast_border_area_t0']);
						count_LU_A_t0 									<- int (m_contents['count_LU_A_t0']);
						count_LU_N_t0 									<- int (m_contents['count_LU_N_t0']);
						count_LU_AU_t0 									<- int (m_contents['count_LU_AU_t0']);
						count_LU_U_t0									<- int (m_contents['count_LU_U_t0']);		
					}
				}
			}
		}	
	}	
	
	action update_action (map<string,string> msg){
		list<Player_Action> p_act <- Player_Action where(each.id = (msg at "id"));
		if(p_act = nil or length(p_act) = 0){ 											// new action commanded by a player : indicators are updated and levers triggering tresholds are tested
			create Player_Action{
				//location <- any_location_in(polygon([{0,0}, {20,0},{20,100},{0,100},{0,0}]));
				do init_from_map(msg);
				ask world {
					do add_player_action_to_profile(myself, game_round);
				}
				ask District first_with (each.district_code = district_code) {
					do update_indicators_and_register_player_action (myself);
				}
			}
		}
		else{ 																			// an update of an action already commanded
			ask first(p_act) {	do init_from_map(msg);	}
		}
	}
}
//------------------------------ end of Network_Leader -------------------------------//

grid Grille width: 4 height: 11 {
	init { color <- #white ; }
}
//------------------------------ end of Grille -------------------------------//

species District_Action_Button parent: District_Name{
	string command;
	District my_district;
	
	init { shape <- rectangle(17,3); }

	aspect default{
		draw shape color: rgb(176,97,188) border: #black;
		draw "" + display_name color: #white at: location - {length(display_name)/3, -0.5};
	}
	
	action button_cliked {
		string msg_player 			<- "";
		list<string> msg_activity 	<- ["",""];
		map<string, unknown> msg 	<-[];
		
		put my_district.district_code	key: DISTRICT_CODE 		in: msg;
		
		switch(command){
			match TAKE_MONEY_FROM {			
				string msg1 <- world.get_message('BTN_TAKE_MONEY_MSG1');
				string msg2 <- world.get_message('BTN_TAKE_MONEY_MSG2');
				string msg3 <- world.get_message('BTN_TAKE_MONEY_MSG3');
				string msg4 <- world.get_message('BTN_TAKE_MONEY_MSG4');
				map values  <- user_input(msg4 + " " + my_district.district_long_name + "\n(0 "+ MSG_TO_CANCEL+ ")\n" + MSG_CHOOSE_MSG_TO_SEND +
										"\n1 : " + msg1 + "\n2 : " + msg2 + "\n3 : " + msg3 + "\n" + MSG_TYPE_CUSTOMIZED_MSG,
										[MSG_AMOUNT + " :" :: "2000", (MSG_123_OR_CUSTOMIZED) :: "1"]);
				int amount_value <- int(values[MSG_AMOUNT + " :"]);
				if  amount_value != 0 {
					
					switch int(values[MSG_123_OR_CUSTOMIZED]) {
						match 1 { msg_player <- msg1; }
						match 2 { msg_player <- msg2; }
						match 3 { msg_player <- msg3; }
						default { msg_player <- (values[MSG_123_OR_CUSTOMIZED]); }
					}
					put TAKE_MONEY_FROM 			key: LEADER_COMMAND 	in: msg;
					put amount_value			 	key: AMOUNT 			in: msg;
					put msg_player 					key: MSG_TO_PLAYER 		in: msg;
					
					msg_activity[0] <- world.get_message('LDR_MSG_TAKE_MONEY_FROM');
					msg_activity[1] <- string(msg at MSG_TO_PLAYER) + " : " + string(msg at AMOUNT) + "By";
				}
			}
			match GIVE_MONEY_TO {
				string msg1 <- world.get_message('BTN_GIVE_MONEY_MSG1');
				string msg2 <- world.get_message('BTN_GIVE_MONEY_MSG2');
				string msg3 <- world.get_message('BTN_GIVE_MONEY_MSG3');
				string msg4 <- world.get_message('BTN_GIVE_MONEY_MSG4');
				map values 	<- user_input(msg4 + " " + my_district.district_long_name + "\n(0 " + MSG_TO_CANCEL+")\n" + MSG_CHOOSE_MSG_TO_SEND +
										"\n1 : " + msg1 + "\n2 : " + msg2 + "\n3 : " + msg3 + "\n" + MSG_TYPE_CUSTOMIZED_MSG,
										[MSG_AMOUNT + " :" :: "2000", (MSG_123_OR_CUSTOMIZED) :: "1"]);
				int amount_value <- int(values[MSG_AMOUNT+ " :"]);			
				if amount_value != 0 {
					switch int(values[MSG_123_OR_CUSTOMIZED]) {
						match 1 { msg_player <- msg1; }
						match 2 { msg_player <- msg2; }
						match 3 { msg_player <- msg3; }
						default { msg_player <- (values[MSG_123_OR_CUSTOMIZED]); }
					}
					put GIVE_MONEY_TO 			 	key: LEADER_COMMAND in: msg;
					put amount_value 				key: AMOUNT 		in: msg;
					put msg_player 					key: MSG_TO_PLAYER 	in:msg;
					
					msg_activity[0] <- world.get_message('LDR_MSG_SEND_MONEY_TO');
					msg_activity[1] <- string(msg at MSG_TO_PLAYER) + " : " + string(msg at AMOUNT) + "By";
				}						
			}
			match SEND_MESSAGE_TO {
				string msg0 <- world.get_message('BTN_SEND_MSG_MSG0');
				string msg1 <- world.get_message('BTN_SEND_MSG_MSG1');
				string msg2 <- world.get_message('BTN_SEND_MSG_MSG2');
				string msg3 <- world.get_message('BTN_SEND_MSG_MSG3');
				string msg4 <- world.get_message('BTN_SEND_MSG_MSG4');
				string msg5 <- world.get_message('BTN_EMPTY_MSG_TO_CANCEL');
				map values <- user_input(msg0 + " " + my_district.district_long_name + "\n(" + msg5 + ")\n" + MSG_CHOOSE_MSG_TO_SEND +
										"\n1 : " + msg1 + "\n2 : " + msg2 + "\n3 : " + msg3 + "\n4 : " + msg4 + "\n" + MSG_TYPE_CUSTOMIZED_MSG,
										[(MSG_123_OR_CUSTOMIZED) :: "1"]);
				string custom_msg <- values[MSG_123_OR_CUSTOMIZED];
				if (custom_msg !="") {
					switch int(custom_msg) {
						match 1 { msg_player <- msg1; 		}
						match 2 { msg_player <- msg2; 		}
						match 3 { msg_player <- msg3; 		}
						match 4 { msg_player <- msg4; 		}
						default { msg_player <- custom_msg;	}
					}
					put SEND_MESSAGE_TO				key: LEADER_COMMAND in: msg;
					put msg_player 					key: MSG_TO_PLAYER 	in: msg;
					
					msg_activity[0] <- world.get_message('LDR_MSG_SEND_MSG_TO');
					msg_activity[1] <- msg at MSG_TO_PLAYER;		
				}	
			}	
		}
		selected_district <- my_district;
		ask world {
			do send_message_from_leader(msg);
			do record_leader_activity  (msg_activity[0], myself.my_district.district_name, msg_activity[1]);
		}
	}
}
//------------------------------ end of District_Action_Button -------------------------------//

species District_Name {
	string display_name;
	
	aspect default{
		draw "" + display_name color:#black font: font("Arial", 20 , #bold) at: location - {length(display_name)/2, 0};
	}
}
//------------------------------ end of District_Name -------------------------------//

experiment LittoSIM_GEN_Leader {
	init { minimum_cycle_duration <- 0.5; }
	
	output{
		display levers{
			graphics "Round" {
				string msg_round <- world.get_message('MSG_ROUND');
				draw  (msg_round + " : " + game_round)  at: {45,3} font: font("Arial", 20 , #bold) color: #red ;
			}
			species District_Name;
			species District_Action_Button;
			species lever_create_dike;
			species lever_AUorUi_inCoastBorderArea;
			species lever_AUorUi_inRiskArea;
			species lever_raise_dike;
			species lever_repair_dike;
			species lever_ganivelle ;
			species lever_Us_outCoastBorderOrRiskArea ;
			species lever_Us_inCoastBorderArea;
			species lever_Us_inRiskArea;
			species lever_inland_dike ;
			species lever_no_dike_creation;
			species lever_no_dike_raise;
			species lever_no_dike_repair;
			species lever_AtoN_inCoastBorderOrRiskArea ;
			species lever_densification_outCoastBorderAndRiskArea ;
			species lever_expropriation;
			species Lever_Destroy_Dike;
			
			event [mouse_down] action: user_click;
			
			graphics "Lever tooltip" transparency:0.4{
				if(explored_lever != nil and MOUSE_LOC !=nil){
					geometry rec <- rectangle(20,0.7);
					draw explored_lever.texte_infobulle()  at: (MOUSE_LOC /*-{9.8,0}*/) font: font("Arial", 12 , #bold) color: #red;
				}
			}
		}
	}
}
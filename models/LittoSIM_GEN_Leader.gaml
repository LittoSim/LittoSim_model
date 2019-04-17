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
	list<string> leader_activities;	
	Player_Action selection_player_action;
	District selected_district					<- nil;
	geometry shape 								<- square(100#m);
	list<species<Lever>> all_levers 			<- [];
	
	list<string> levers_names <- ['LEVER_CREATE_DIKE', 'LEVER_RAISE_DIKE', 'LEVER_REPAIR_DIKE', 'LEVER_AU_Ui_COAST_BORDER_AREA', 'LEVER_AU_Ui_RISK_AREA',
								  'LEVER_GANIVELLE', 'LEVER_Us_COAST_BORDER_RISK_AREA', 'LEVER_Us_COAST_BORDER_AREA', 'LEVER_Us_RISK_AREA', 'LEVER_INLAND_DIKE',
								  'LEVER_NO_DIKE_CREATION', 'LEVER_NO_DIKE_RAISE', 'LEVER_NO_DIKE_REPAIR', 'LEVER_A_N_COAST_BORDER_RISK_AREA',
								  'LEVER_DENSIFICATION_COAST_BORDER_RISK_AREA', 'LEVER_EXPROPRIATION', 'LEVER_DESTROY_DIKE'];
	
	init{
		all_levers <- [Create_Dike_Lever, Raise_Dike_Lever, Repair_Dike_Lever, AU_or_Ui_in_Coast_Border_Area_Lever, AU_or_Ui_in_Risk_Area_Lever,
				Ganivelle_Lever, Us_out_Coast_Border_or_Risk_Area_Lever, Us_in_Coast_Border_Area_Lever, Us_in_Risk_Area_Lever, Inland_Dike_Lever,
				No_Dike_Creation_Lever, No_Dike_Raise_Lever, No_Dike_Repair_Lever, A_to_N_in_Coast_Border_or_Risk_Area_Lever,
				Densification_out_Coast_Border_and_Risk_Area_Lever, Expropriation_Lever, Destroy_Dike_Lever];

		MSG_CHOOSE_MSG_TO_SEND 	<- get_message('MSG_CHOOSE_MSG_TO_SEND');
		MSG_TYPE_CUSTOMIZED_MSG <- get_message('MSG_TYPE_CUSTOMIZED_MSG');
		MSG_TO_CANCEL 			<- get_message('MSG_TO_CANCEL');
		MSG_AMOUNT 				<- get_message('MSG_AMOUNT');
		MSG_123_OR_CUSTOMIZED 	<- get_message('MSG_123_OR_CUSTOMIZED');
		BTN_GET_REVENUE_MSG2	<- get_message('BTN_GET_REVENUE_MSG2');
		
		sim_id <- machine_time;

		create District from: districts_shape with: [district_name::string(read("dist_sname")), district_code::string(read("dist_code")),
			dist_id::int(read("player_id")), district_long_name::string(read("dist_lname"))]{
			if(dist_id = 0) { do die; }
		}
		do create_district_buttons_names;
		do create_levers;		
		create Network_Leader; 
	}
	//------------------------------ end of init -------------------------------//
	
	action create_district_buttons_names{
		loop i from: 0 to: 3 {
			create District_Name {
				display_name <- District[i].district_name;
				location	 <- (Grille grid_at {i,0}).location - {1,-1};
			}
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
	
	action create_levers {
		loop i from: 0 to: 3{
			loop j from: 0 to: length(all_levers) - 1{
				if levers_def at levers_names[j] at 'active' = 'yes'{
					create all_levers[j]{
						my_district <- District[i];
						location	<- (Grille[i, int(j/2 + 2)]).location - {0, 3 + (-4.5 * j mod 2)};
						add self to: my_district.levers;
					}
				}
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
	
	action send_message_from_leader (map<string,unknown> msg){
		ask Network_Leader { do send to: LISTENER_TO_LEADER contents:msg; }		
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
	int length_coast_def;
	list<Activated_Lever> activated_levers 	<-[];
	bool should_wait_lever_to_activate 		<- false;
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
		if(action_type = PLAYER_ACTION_TYPE_COAST_DEF){
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
		self.length_coast_def 			<- int(a at "length_coast_def");
		self.a_lever_has_been_applied 	<- bool(a at "a_lever_has_been_applied");		
	}
	
	map<string,string> build_map_from_attributes{
		map<string,string> res <- [
			"OBJECT_TYPE"::OBJECT_TYPE_PLAYER_ACTION,
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
			"command_round"::command_round];	
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
			ask Expropriation_Lever where(each.my_district = self) { do register_and_check_activation(act); }
		}
		
		switch (act.command){
			match ACTION_CREATE_DIKE {
				if(act.isInlandDike){
					length_inland_dikes <- length_inland_dikes + act.length_coast_def;
					ask Inland_Dike_Lever where(each.my_district = self) { do register_and_check_activation(act); }
				}else{
					length_created_dikes <- length_created_dikes + act.length_coast_def;
					ask Create_Dike_Lever 		where(each.my_district = self) { do register_and_check_activation(act);	}
					ask No_Dike_Creation_Lever 	where(each.my_district = self) { do register(act);						}
				}
			}
			match ACTION_RAISE_DIKE {
				length_raised_dikes <- length_raised_dikes + act.length_coast_def;
				ask Raise_Dike_Lever 	where(each.my_district = self) { do register_and_check_activation(act); }
				ask No_Dike_Raise_Lever where(each.my_district = self) { do register(act);						}
			}
			match ACTION_REPAIR_DIKE {
				length_repaired_dikes <- length_repaired_dikes + act.length_coast_def;
				ask Repair_Dike_Lever 	 where(each.my_district = self) { do register_and_check_activation(act);}
				ask No_Dike_Repair_Lever where(each.my_district = self) { do register(act);						}
			}
			match ACTION_DESTROY_DIKE{
				length_destroyed_dikes <- length_destroyed_dikes + act.length_coast_def;
				ask Destroy_Dike_Lever where(each.my_district = self) { do register_and_check_activation(act); }
			}
			match ACTION_INSTALL_GANIVELLE {
				length_created_ganivelles <- length_created_ganivelles + act.length_coast_def;
				ask Ganivelle_Lever where(each.my_district = self) { do register_and_check_activation(act); }
			}
			match ACTION_MODIFY_LAND_COVER_Us {
				count_Us <- count_Us +1;
				if !act.inRiskArea and !act.inCoastBorderArea {
					count_Us_out_coast_border_or_risk_area <- count_Us_out_coast_border_or_risk_area +1;
					ask Us_out_Coast_Border_or_Risk_Area_Lever where(each.my_district = self) { do register_and_check_activation(act); }
				} else{
					if act.inCoastBorderArea {
					count_Us_in_coast_border_area <- count_Us_in_coast_border_area +1;
					ask Us_in_Coast_Border_Area_Lever where(each.my_district = self) { do register_and_check_activation(act); }
					}
					if act.inRiskArea {
						count_Us_in_risk_area <- count_Us_in_risk_area +1;
						ask Us_in_Risk_Area_Lever where(each.my_district = self) { do register_and_check_activation(act); }
					}
				}
			}
			match ACTION_MODIFY_LAND_COVER_N {
				if act.previous_ua_name = "A" and (act.inCoastBorderArea or act.inRiskArea) {
					count_A_to_N_in_coast_border_or_risk_area <- count_A_to_N_in_coast_border_or_risk_area + 1;
					ask A_to_N_in_Coast_Border_or_Risk_Area_Lever where(each.my_district = self) {
						do register (act);
						do check_activation_and_impact_on_first_element_of (myself.actions_densification_out_coast_border_and_risk_area());
					}
				}
			}
			match_one [ACTION_MODIFY_LAND_COVER_Ui, ACTION_MODIFY_LAND_COVER_AU] {
				if act.command = ACTION_MODIFY_LAND_COVER_Ui and !act.inCoastBorderArea and !act.inRiskArea {	
					count_densification_out_coast_border_and_risk_area <- count_densification_out_coast_border_and_risk_area + 1;
					ask Densification_out_Coast_Border_and_Risk_Area_Lever where(each.my_district = self) { do register_and_check_activation (act); }
				}
				else{
					if act.inCoastBorderArea and act.previous_ua_name != "Us"{
						count_AU_or_Ui_in_coast_border_area <- count_AU_or_Ui_in_coast_border_area + 1;
						ask AU_or_Ui_in_Coast_Border_Area_Lever where(each.my_district = self) {	do register_and_check_activation(act); }
					}
					if act.inRiskArea {
						count_AU_or_Ui_in_risk_area <- count_AU_or_Ui_in_risk_area + 1;
						ask AU_or_Ui_in_Risk_Area_Lever where(each.my_district = self) { do register_and_check_activation(act); }
					}	
				}
			}
		}
	}
	
	list<Player_Action> actions_install_ganivelle {
		return ( (Ganivelle_Lever first_with (each.my_district = self)).associated_actions sort_by (-each.command_round) );
	}
	
	list<Player_Action> actions_densification_out_coast_border_and_risk_area{
		return ( (Densification_out_Coast_Border_and_Risk_Area_Lever first_with(each.my_district = self)).associated_actions sort_by(-each.command_round) );
	}
	
	list<Player_Action> actions_expropriation{
		return ( (Expropriation_Lever first_with(each.my_district = self)).associated_actions sort_by(-each.command_round) );
	}
}
//------------------------------ End of District -------------------------------//

species Activated_Lever {
	Player_Action p_action;
	float activation_time;
	bool applied <- false;
	
	//attributes sent through network
	int id <- length(Activated_Lever);
	string district_code;
	string lever_name;
	string lever_explanation <- "";
	string p_action_id 		 <- "";
	int nb_rounds_delay 	 <- 0;
	int added_cost 			 <- 0;
	int round_creation;
	int round_application;
	
	action init_from_map (map<string, string> m ){
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
			"OBJECT_TYPE"::OBJECT_TYPE_ACTIVATED_LEVER,
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
	user_command "Validate all current applications of this lever" 		action: accept_all_activated_actions  when: status_on;
	user_command "Activate/Deactivate this lever" 						action: toggle_status;
	user_command "How this lever works ?" 								action: write_help_lever_msg;
	
	District my_district;
	float indicator;
	float threshold 			<- 0.2;
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
	
	init { shape <- rectangle (24, 4); }
	
	aspect default{
		if timer_activated { draw shape+0.2#m color: #red; }
		draw shape color: color_profile() border: #black at: location;
		
		draw box_title at: location - {length(box_title) / 4, 0.75} font: font("Arial", 12 , #bold) color: #black;
		draw progression_bar at:location + {-length(progression_bar)/4, 0.5} font: font("Arial", 12 , #plain) color: threshold_reached ? #red : #black;
		
		if timer_activated {
			draw string(remaining_seconds()) + " sec " + (length(activation_queue)=1? "" : "(" + length(activation_queue) + ")") + "-> " + info_of_next_activated_lever() at: location + {-9,1.5} font: font("Arial", 12 , #plain) color:#black;
		}
		
		if has_activated_levers {
			draw activation_label_L1 at:location + {0,2.5} font: font("Arial", 12 , #plain) color:#black;
			draw activation_label_L2 at:location + {0,3}   font: font("Arial", 12 , #plain) color:#black;
		}
		
		if !status_on{ draw shape+0.1#m color: rgb(200,200,200,160); }
	}
	    
	action register_and_check_activation (Player_Action p_action){
		do register(p_action);
		do check_activation_and_impact_on (p_action);
	}
	
	action register (Player_Action p_action){
		add p_action to: associated_actions;	
	}
	
	action check_activation_and_impact_on (Player_Action p_action){
		if status_on {
			if should_be_activated {
				threshold_reached <- true;
				do queue_activated_lever (p_action);
			}
			else{ threshold_reached <- false; }	
		}
	}	
	
	action check_activation_and_impact_on_first_element_of (list<Player_Action> list_p_action){
		if !empty(list_p_action){
			do check_activation_and_impact_on (list_p_action[0]);
		}
	}
	
	action queue_activated_lever( Player_Action a_p_action){
		create Activated_Lever {
			lever_name 		<- myself.lever_name;
			district_code 	<- myself.my_district.district_code;
			self.p_action 	<- a_p_action;
			p_action_id 	<- a_p_action.id;
			activation_time <- machine_time + myself.timer_duration ;
			round_creation 	<- game_round;
			add self to: myself.activation_queue;
		}
		ask world {
			do record_leader_activity("Lever " + myself.lever_name + " programmed at ", myself.my_district.district_name, a_p_action.label + "(" + a_p_action + ")");
		}
	}

	action toggle_status {
		status_on <- !status_on ;
		if !status_on { activation_queue <-[]; }
	}
	
	action write_help_lever_msg {
		map values <- user_input(world.get_message('LEV_MSG_LEVER_HELP'),[help_lever_msg + "\n" + world.get_message('LEV_THRESHOLD_VALUE') + " : " + threshold:: ""]);
	}
	
	action change_lever_player_msg {
		map values <- user_input(world.get_message('LEV_MSG_SENT_TRIGGER_LEVER'), [world.get_message('LEV_MESSAGE'):: player_msg]);
		player_msg <- values at values.keys[0];
		ask world {
			do record_leader_activity("Change lever " + myself.lever_name + " at", myself.my_district.district_name, "The new message sent to the player is : " + myself.player_msg);
		}
	}
	
	action change_lever_threshold_value{
		map values <- user_input((world.get_message('LEV_CURRENT_THRESHOLD_LEVER') + " " + lever_name + " " + world.get_message('LEV_MSG_IS_ABOUT') + " "
			+ string(threshold)), [world.get_message('LEV_NEW_THRESHOLD_VALUE') + " : ":: threshold]); 
		threshold <- float(values at values.keys[0]);
		ask world {
			do record_leader_activity("Change lever " + myself.lever_name + " at", myself.my_district.district_name, "The new threshold value is : " + myself.threshold);
		}	
	}
	
	reflex check_timer when: timer_activated {
		if machine_time > activation_queue[0].activation_time {
			Activated_Lever act_lever <- activation_queue[0];
			remove index: 0 from: activation_queue ;
			add act_lever   to: activated_levers;
			do apply_lever (act_lever);
		}
	}
	
	int remaining_seconds {
		return (int((activation_queue[0].activation_time - machine_time) / 1000));
	}
	
	action cancel_next_activated_action {		
		if !empty(activation_queue){
			do cancel_lever(activation_queue[0]);
			ask world {
				do record_leader_activity("Lever " + myself.lever_name + " canceled at", myself.my_district.district_name, "Cancel of " + myself.activation_queue[0].p_action);
			}
			remove index: 0 from: activation_queue ;	
		}
	}
	
	action cancel_lever(Activated_Lever lev){
		lev.p_action.should_wait_lever_to_activate <- false;
		do inform_network_should_wait_lever_to_activate(lev.p_action);
	}

	action accept_next_activated_action{		
		if !empty(activation_queue){
			activation_queue[0].activation_time <- machine_time ;
		} 	
	}

	action accept_all_activated_actions{	
		loop aa over: activation_queue {
			aa.activation_time <- machine_time ;
		} 	
	}
	
	action inform_network_should_wait_lever_to_activate(Player_Action p_action){
		map<string, unknown> msg <-[];
		put ACTION_SHOULD_WAIT_LEVER_TO_ACTIVATE 	key: LEADER_COMMAND 						in: msg;
		put my_district.district_code 			 	key: DISTRICT_CODE  						in: msg;
		put p_action.id 						 	key: PLAYER_ACTION_ID 						in: msg;
		put p_action.should_wait_lever_to_activate  key: ACTION_SHOULD_WAIT_LEVER_TO_ACTIVATE 	in: msg;
		ask world { do send_message_from_leader(msg); }
	}
	
	action send_lever_message (Activated_Lever lev) {
		map<string, unknown> msg <- lev.build_map_from_attributes();
		put NEW_ACTIVATED_LEVER 	key: LEADER_COMMAND in: msg;
		ask world { do send_message_from_leader(msg); }
	}
	
	rgb color_profile {
		switch lever_type {
			match BUILDER 		{ return #deepskyblue;}
			match SOFT_DEFENSE	{ return #lightgreen; }
			match WITHDRAWAL	{ return #moccasin;	  }
			match "" 			{ return #darkgrey;	  }
			default 			{ return #red;		  }
		}
	}
	
	// virtual actions
	action apply_lever(Activated_Lever lev);
	string info_of_next_activated_lever { return ""; }
	action check_activation_at_new_round;
}
//------------------------------ End of Lever -------------------------------//

species Cost_Lever parent: Lever { 
	
	user_command "Change the % impact on the cost" action: change_lever_cost;
	
	float added_cost		<- 0.25;
	int last_lever_cost 	<- 0;
	
	action change_lever_cost{
		map values <- user_input((world.get_message('LEV_ACTUAL_PERCENTAGE_COST') + " " + lever_name + " " + world.get_message('LEV_MSG_IS_ABOUT') + " " + added_cost),
			[world.get_message('LEV_ENTER_THE_NEW') + " :":: added_cost]
		);
		float n_val <- float(values at values.keys[0]);
		added_cost <- n_val;
		
		ask world {
			do record_leader_activity("Change lever " + myself.lever_name + " at", myself.my_district.district_name, "-> The new cost of the lever is : " + myself.added_cost);
		}
	}
	
	string info_of_next_activated_lever {
		return "" + activation_queue[0].p_action.length_coast_def + " m. (" + int(activation_queue[0].p_action.cost * added_cost) + ' By.)';
	}
	
	action apply_lever(Activated_Lever lev){
		lev.applied 		  <- true;
		lev.round_application <- game_round;
		lev.lever_explanation <- player_msg;
		lev.added_cost 		  <- int(lev.p_action.cost * added_cost);
		do send_lever_message(lev);
		
		last_lever_cost 	<- lev.added_cost;
		activation_label_L1 <- "Last "   + (last_lever_cost >= 0 ? "levy"  : "payment") + " : " + abs(last_lever_cost) + ' By';
		activation_label_L2 <- "Total "  + (last_lever_cost >= 0 ? "taken" : "given"  ) + " : " + abs(total_lever_cost()) + ' By';
		ask world {
			do record_leader_activity("Lever " + myself.lever_name + " validated at", myself.my_district.district_name, myself.help_lever_msg + " : " + lev.added_cost + "By" + "(" + lev.p_action + ")");
		}
	}
	
	int total_lever_cost {
		return activated_levers sum_of (each.added_cost);
	}
}
//------------------------------ End of Cost_Lever -------------------------------//

species Delay_Lever parent: Lever{

	user_command "Change the % impact on the delay" action: change_lever_delay;
	
	int added_delay <- 2;

	action change_lever_delay {
		map values <- user_input((world.get_message('LEV_ACTUAL_DELAY') + " " + lever_name + " " + world.get_message('LEV_MSG_IS_ABOUT') + " " + added_delay),
			[world.get_message('LEV_ENTER_THE_NEW') + " :":: added_delay]
		);
		int n_val <- int(values at values.keys[0]);
		added_delay <- n_val;
		
		ask world {
			do record_leader_activity("Change lever " + myself.lever_name + " at", myself.my_district.district_name, "-> The new rounds number of the lever is : " + myself.added_delay);
		}
	}
	
	action check_activation_and_impact_on (Player_Action p_action){
		if status_on{ 
			if should_be_activated {
				threshold_reached <- true;
				do queue_activated_lever (p_action);
				p_action.should_wait_lever_to_activate <- true;
				do inform_network_should_wait_lever_to_activate(p_action);
			}
			else { threshold_reached <- false; }	
		}
	}	
	
	action apply_lever (Activated_Lever lev){
		lev.applied <- true;
		lev.lever_explanation <- player_msg;
		lev.nb_rounds_delay <- added_delay;
		do send_lever_message;
		
		activation_label_L1 <- (total_lever_delay() < 0 ? "Total Advance: " : "Total Delay: ") + abs(total_lever_delay()) + ' rounds';
		lev.p_action.should_wait_lever_to_activate <- false;
		do inform_network_should_wait_lever_to_activate(lev.p_action);
		
		ask world {
			do record_leader_activity(myself.lever_name + " triggered at", myself.my_district.district_name, myself.help_lever_msg + " : " + lev.nb_rounds_delay + " rounds" + "(" + lev.p_action + ")");
		}
	}
	
	int total_lever_delay {
		return activated_levers sum_of (each.nb_rounds_delay);
	}
}
//------------------------------ End of Delay_Lever -------------------------------//

species Create_Dike_Lever parent: Cost_Lever {
	float indicator 		-> { my_district.length_created_dikes / my_district.length_dikes_t0 };
	string progression_bar  -> { "" + my_district.length_created_dikes + " m. / " + threshold + " * " + my_district.length_dikes_t0 + " m. at t0"};
	
	init{
		lever_name 		<- world.get_lever_name('LEVER_CREATE_DIKE');
		lever_type		<- world.get_lever_type('LEVER_CREATE_DIKE');
		help_lever_msg 	<- world.get_message('LEV_CREATE_DIKE_HELPER1') + " : " + int(100*added_cost) + "% " + world.get_message('LEV_CREATE_DIKE_HELPER2');
		player_msg 		<- world.get_message('LEV_CREATE_DIKE_PLAYER');	
	}
}
//------------------------------ End of Create_Dike_Lever -------------------------------//

species Raise_Dike_Lever parent: Cost_Lever {
	float indicator 		-> { my_district.length_raised_dikes / my_district.length_dikes_t0 };
	string progression_bar 	-> { "" + my_district.length_raised_dikes + " m. / " + threshold + " * " + my_district.length_dikes_t0 + " m. at t0"};
	init{
		lever_name 		<- world.get_lever_name('LEVER_RAISE_DIKE');
		lever_type		<- world.get_lever_type('LEVER_RAISE_DIKE');
		help_lever_msg 	<- world.get_message('LEV_CREATE_DIKE_HELPER1') + " : " + int(100*added_cost) + "% " + world.get_message('LEV_CREATE_DIKE_HELPER2');
		player_msg 		<- world.get_message('LEV_CREATE_DIKE_PLAYER');
	}
}
//------------------------------ End of Raise_Dike_Lever -------------------------------//

species Repair_Dike_Lever parent: Cost_Lever{
	float indicator 			-> { my_district.length_repaired_dikes / my_district.length_dikes_t0 };
	bool should_be_activated 	-> { indicator > threshold and (my_district.length_created_dikes != 0 or my_district.length_raised_dikes != 0)};
	string progression_bar 		-> { "" + my_district.length_repaired_dikes + " m. / " + threshold + " * " + my_district.length_dikes_t0 + " m. at t0"};
	
	init{
		lever_name 		<- world.get_lever_name('LEVER_REPAIR_DIKE');
		lever_type		<- world.get_lever_type('LEVER_REPAIR_DIKE');
		help_lever_msg 	<- world.get_message('LEV_CREATE_DIKE_HELPER1') + " : " + int(100*added_cost) + "% " + world.get_message('LEV_CREATE_DIKE_HELPER2');
		player_msg 		<- world.get_message('LEV_REPAIR_DIKE_PLAYER');
	}
}
//------------------------------ End of Repair_Dike_Lever -------------------------------//

species AU_or_Ui_in_Coast_Border_Area_Lever parent: Delay_Lever{
	int indicator 			-> { my_district.count_AU_or_Ui_in_coast_border_area};
	string progression_bar 	-> { "" + indicator + " actions / " + int(threshold) + " max"};
	
	init{
		lever_name 	<- world.get_lever_name('LEVER_AU_Ui_COAST_BORDER_AREA');
		lever_type	<- world.get_lever_type('LEVER_AU_Ui_COAST_BORDER_AREA');
		threshold 	<- 2.0;
		help_lever_msg 	<- world.get_message('LEV_COAST_BORDER_AREA_HELPER1') + " " + added_delay + " " + world.get_message('MSG_ROUND');
		player_msg 		<- world.get_message('LEV_COAST_BORDER_AREA_PLAYER');	
	}
		
	string info_of_next_activated_lever {
		switch activation_queue[0].p_action.command {
			match ACTION_MODIFY_LAND_COVER_AU { return "Construction: "  + added_delay + " rounds"; }
			match ACTION_MODIFY_LAND_COVER_Ui { return "Densification: " + added_delay + " rounds"; }
		} 
	}
}
//------------------------------ End of AU_or_Ui_in_Coast_Border_Area_Lever -------------------------------//

species AU_or_Ui_in_Risk_Area_Lever parent: Cost_Lever{
	int indicator 			-> { my_district.count_AU_or_Ui_in_risk_area };
	string progression_bar 	-> { "" + indicator + " actions / "+ int(threshold) + " max" };
	
	init{
		lever_name 	<- world.get_lever_name('LEVER_AU_Ui_RISK_AREA');
		lever_type	<- world.get_lever_type('LEVER_AU_Ui_RISK_AREA');
		threshold 	<- 1.0;
		added_cost 	<- 0.5 ;
		help_lever_msg 	<- world.get_message('LEV_CREATE_DIKE_HELPER1') + " " + int(100*added_cost) + "% " + world.get_message('LEV_CREATE_DIKE_HELPER2');
		player_msg 		<- world.get_message('LEV_REPAIR_DIKE_PLAYER');	
	}
		
	string info_of_next_activated_lever {
		switch activation_queue[0].p_action.command {
			match ACTION_MODIFY_LAND_COVER_AU { return "-" + int(activation_queue[0].p_action.cost * added_cost) + " By on the next construction"; }
			match ACTION_MODIFY_LAND_COVER_Ui { return "-" + int(activation_queue[0].p_action.cost * added_cost) + " By on the next densification";}
		} 
	}
}
//------------------------------ End of AU_or_Ui_in_Risk_Area_Lever -------------------------------//

species Ganivelle_Lever parent: Cost_Lever {
		int indicator 			-> { int(my_district.length_created_ganivelles / my_district.length_dunes_t0) };
		string progression_bar 	-> { "" + my_district.length_created_ganivelles + " m. / " + threshold + " * " + my_district.length_dunes_t0 + " m. dunes" };
	
	init{
		lever_name	<- world.get_lever_name('LEVER_GANIVELLE');
		lever_type	<- world.get_lever_type('LEVER_GANIVELLE');
		threshold 	<- 0.1;
		added_cost 	<- -0.25 ;
		help_lever_msg 	<- world.get_message('LEV_GANIVELLE_HELPER1') + " " + int(100*added_cost) + "% " + world.get_message('LEV_GANIVELLE_HELPER2') + "/m";
		player_msg 		<- world.get_message('LEV_GANIVELLE_PLAYER');
	}
}
//------------------------------ End of Ganivelle_Lever -------------------------------//

species Us_out_Coast_Border_or_Risk_Area_Lever parent: Cost_Lever{
	int indicator 			-> { my_district.count_Us_out_coast_border_or_risk_area };
	string progression_bar 	-> { "" + indicator + " actions / " + int(threshold) + " max" };
	
	init{
		lever_name 	<- world.get_lever_name('LEVER_Us_COAST_BORDER_RISK_AREA');
		lever_type	<- world.get_lever_type('LEVER_Us_COAST_BORDER_RISK_AREA');
		threshold 	<- 2.0;
		added_cost 	<- -0.25 ;
		help_lever_msg 	<- world.get_message('LEV_GANIVELLE_HELPER1') + " " + int(100*added_cost) + "% " + world.get_message('LEV_GANIVELLE_HELPER2');
		player_msg 		<- world.get_message('LEV_GANIVELLE_PLAYER');
	}
	
	string info_of_next_activated_lever {
		return '+' + abs(int(activation_queue[0].p_action.cost * added_cost)) + " By " + world.get_message('LEV_ADAPTATION_HELPER1');
	}
	
	action apply_lever(Activated_Lever lev){
		lev.applied <- true;
		lev.lever_explanation 	<- player_msg;
		lev.added_cost 			<- int(lev.p_action.cost * added_cost);
		lev.nb_rounds_delay 	<- 0;
		do send_lever_message (lev);
		
		last_lever_cost 	<- lev.added_cost;
		activation_label_L1 <- "Last payment : " + (-1 * last_lever_cost) + ' By';
		activation_label_L2 <- 'Total paid : '  + (-1 * total_lever_cost()) + ' By';
		
		ask world {
			do record_leader_activity(myself.lever_name + " triggered at", myself.my_district.district_name, myself.help_lever_msg + " : " + lev.added_cost + "By : " + lev.nb_rounds_delay + " rounds" + "(" + lev.p_action + ")");
		}
	}
}
//------------------------------ End of Us_out_Coast_Border_or_Risk_Area_Lever -------------------------------//

species Us_in_Coast_Border_Area_Lever parent: Cost_Lever{
	int indicator 			-> { my_district.count_Us_in_coast_border_area };
	string progression_bar 	-> { "" + my_district.count_Us_in_coast_border_area + " actions / " + int(threshold) +" max" };
	
	init{
		lever_name 	<- world.get_lever_name('LEVER_Us_COAST_BORDER_AREA');
		lever_type	<- world.get_lever_type('LEVER_Us_COAST_BORDER_AREA');
		threshold 	<- 2.0;
		added_cost 	<- -0.5 ;
		help_lever_msg 	<- world.get_message('LEV_GANIVELLE_HELPER1') + " " + int(100*added_cost) + "% "+ world.get_message('LEV_ADAPTATION_HELPER2');
		player_msg 		<- world.get_message('LEV_ADAPTATION_PLAYER');
	}
		
	string info_of_next_activated_lever{
		return "+" + abs(int(activation_queue[0].p_action.cost * added_cost)) + " By " + world.get_message('LEV_ADAPTATION_HELPER1');
	}		
}
//------------------------------ End of Us_in_Coast_Border_Area_Lever -------------------------------//

species Us_in_Risk_Area_Lever parent: Cost_Lever{
	int indicator 			-> { my_district.count_Us_in_risk_area };
	string progression_bar 	-> { "" + my_district.count_Us_in_risk_area + " actions / " + int(threshold) + " max" };
	
	init{
		lever_name 	<- world.get_lever_name('LEVER_Us_RISK_AREA');
		lever_type	<- world.get_lever_type('LEVER_Us_RISK_AREA');
		threshold 	<- 2.0;
		added_cost 	<- -0.5 ;
		help_lever_msg 	<- world.get_message('LEV_GANIVELLE_HELPER1') + " " + int(100*added_cost) + "% "+ world.get_message('LEV_ADAPTATION_HELPER2');
		player_msg 		<- world.get_message('LEV_ADAPTATION_PLAYER');
	}

	string info_of_next_activated_lever{
		return "+" + abs(int(activation_queue[0].p_action.cost * added_cost)) + " By " + world.get_message('LEV_ADAPTATION_HELPER1');
	}		
}
//------------------------------ End of Us_in_Risk_Area_Lever -------------------------------//

species Inland_Dike_Lever parent: Delay_Lever {
	float indicator 		-> { my_district.length_inland_dikes / my_district.length_dikes_t0 };
	string progression_bar 	-> { "" + my_district.length_inland_dikes + " m. / " + threshold + " * " + my_district.length_dikes_t0 + " m. dikes at t0"};
	
	init{
		lever_name 	<- world.get_lever_name('LEVER_INLAND_DIKE');
		lever_type	<- world.get_lever_type('LEVER_INLAND_DIKE');
		added_delay <- -1;
		threshold 	<- 0.01;
		help_lever_msg 	<- world.get_message('LEV_INLAND_HELPER1') + " " + abs(added_delay) + " " + world.get_message('MSG_ROUND') + (abs(added_delay) > 1 ? "s" : "");
		player_msg 		<- world.get_message('LEV_INLAND_PLAYER');	
	}
		
	string info_of_next_activated_lever {
		return "Retrodike (" + int(activation_queue[0].p_action.length_coast_def) + " m.): -" + abs(added_delay) + " rounds";
	}
}
//------------------------------ End of Inland_Dike_Lever -------------------------------//

species No_Action_On_Dike_Lever parent: Cost_Lever {
	string progression_bar 	-> { "" + int(threshold - nb_rounds_before_activation) + " rounds / " + int(threshold) + " max" };
	int nb_activations 		<-0;
	string box_title 		-> { lever_name + ' (' + nb_activations +')' };
	
	bool should_be_activated-> { (nb_rounds_before_activation  <0) and !empty(list_of_impacted_actions)};
	int nb_rounds_before_activation;
	list<Player_Action> list_of_impacted_actions -> {my_district.actions_install_ganivelle()};
	
	init{
		threshold 					<- 2.0;
		nb_rounds_before_activation <- int(threshold);
		added_cost 					<- -0.5 ;
		player_msg 					<- world.get_message('LEV_GANIVELLE_PLAYER');
	}
		
	string info_of_next_activated_lever {
		return "Last ganivelle - " + abs(int(activation_queue[0].p_action.cost * added_cost)) + ' By';
	}	
	
	action register (Player_Action p_action){
		add p_action to: associated_actions;
		nb_rounds_before_activation <- int(threshold);	
	}	

	action check_activation_at_new_round{
		if game_round > 1{
			nb_rounds_before_activation <- nb_rounds_before_activation - 1;
			do check_activation_and_impact_on_first_element_of(list_of_impacted_actions);
		}
	}

	action apply_lever(Activated_Lever lev){
		lev.applied <- true;
		lev.lever_explanation <- player_msg;
		lev.added_cost <- int(lev.p_action.cost * added_cost);
		do send_lever_message(lev);
		
		last_lever_cost 	<-lev.added_cost;
		activation_label_L1 <- "Last "  + (last_lever_cost >= 0 ? "levy" : "payment") + " : " + abs(last_lever_cost)   + ' By.';
		activation_label_L2 <- "Total " + (last_lever_cost >= 0 ? "taken": "given"  ) + " : " + abs(total_lever_cost())+ ' By';
		
		nb_rounds_before_activation <- int(threshold);
		nb_activations 				<- nb_activations +1;
		
		ask world {
			do record_leader_activity(myself.lever_name + " triggered at", myself.my_district.district_name, myself.help_lever_msg + " : " + (lev.added_cost) + "By" + "(" + lev.p_action + ")");
		}
	}
}
//------------------------------ end of No_Action_On_Dike_Lever -------------------------------//

species No_Dike_Creation_Lever parent: No_Action_On_Dike_Lever{
	init{
		lever_name 		<- world.get_lever_name('LEVER_NO_DIKE_CREATION');
		lever_type		<- world.get_lever_type('LEVER_NO_DIKE_CREATION');
		help_lever_msg 	<- world.get_lever_type('LEV_DURING_MSG') + " " + threshold + " " + world.get_lever_type('LEV_NO_DIKE_CREATION_HELP') + ".\n" + world.get_message('LEV_GANIVELLE_HELPER1') + " " + int(100*added_cost)+"% " + world.get_message('LEV_GANIVELLE_HELPER2') + "/m";
	}	
}
//------------------------------ end of No_Dike_Creation_Lever -------------------------------//

species No_Dike_Raise_Lever parent: No_Action_On_Dike_Lever{
	init{
		lever_name 		<- world.get_lever_name('LEVER_NO_DIKE_RAISE');
		lever_type		<- world.get_lever_type('LEVER_NO_DIKE_RAISE');
		help_lever_msg 	<- world.get_lever_type('LEV_DURING_MSG') + " " + threshold + " " + world.get_lever_type('LEV_NO_DIKE_RAISE_HELP') + ".\n" + world.get_message('LEV_GANIVELLE_HELPER1') + " " + int(100*added_cost)+"% " + world.get_message('LEV_GANIVELLE_HELPER2') + "/m";
	}
}
//------------------------------ end of No_Dike_Raise_Lever -------------------------------//

species No_Dike_Repair_Lever parent: No_Action_On_Dike_Lever{
	init{
		lever_name		<- world.get_lever_name('LEVER_NO_DIKE_REPAIR');
		lever_type		<- world.get_lever_type('LEVER_NO_DIKE_REPAIR');
		help_lever_msg 	<- world.get_lever_type('LEV_DURING_MSG') + " " + threshold + " " + world.get_lever_type('LEV_NO_DIKE_REPAIR_HELP') + ".\n" + world.get_message('LEV_GANIVELLE_HELPER1') + " " + int(100*added_cost)+"% " + world.get_message('LEV_GANIVELLE_HELPER2') + "/m";
	}
}
//------------------------------ end of No_Dike_Repair_Lever -------------------------------//

species A_to_N_in_Coast_Border_or_Risk_Area_Lever parent: Cost_Lever{
	int indicator 				-> { my_district.count_A_to_N_in_coast_border_or_risk_area };
	string progression_bar 		-> { "" + my_district.count_A_to_N_in_coast_border_or_risk_area + " actions / " + int(threshold) + " max" };
	bool should_be_activated 	-> { indicator > threshold and !empty(my_district.actions_densification_out_coast_border_and_risk_area()) };
	
	init{
		lever_name 	<- world.get_lever_name('LEVER_A_N_COAST_BORDER_RISK_AREA');
		lever_type	<- world.get_lever_type('LEVER_A_N_COAST_BORDER_RISK_AREA');
		threshold 	<- 2.0;
		added_cost 	<- -0.5 ;
		help_lever_msg 	<- world.get_message('LEV_GANIVELLE_HELPER1') + " " + int(100*added_cost) + "% du coût d'une densification préalablement réalisée hors ZL et ZI";
		player_msg 		<- world.get_message('LEV_GANIVELLE_PLAYER');
	}

	string info_of_next_activated_lever {
		return "+" + abs(int(activation_queue[0].p_action.cost * added_cost)) + ' By ' + world.get_message('LEV_DENSIFICATION_HELPER3');
	}	
}
//------------------------------ end of A_to_N_in_Coast_Border_or_Risk_Area_Lever -------------------------------//

species Densification_out_Coast_Border_and_Risk_Area_Lever parent: Cost_Lever{
	int indicator 			-> { my_district.count_densification_out_coast_border_and_risk_area };
	string progression_bar 	-> { "" + my_district.count_densification_out_coast_border_and_risk_area + " actions / " + int(threshold) +" max" };
	
	init{
		lever_name 	<- world.get_lever_name('LEVER_DENSIFICATION_COAST_BORDER_RISK_AREA');
		lever_type	<- world.get_lever_type('LEVER_DENSIFICATION_COAST_BORDER_RISK_AREA');
		threshold 	<- 2.0;
		added_cost 	<- -0.25 ;
		help_lever_msg 	<- world.get_message('LEV_GANIVELLE_HELPER1') + " " + int(100*added_cost) + "% " + world.get_message('LEV_DENSIFICATION_HELPER2');
		player_msg 		<- world.get_message('LEV_GANIVELLE_PLAYER');
	}
	
	string info_of_next_activated_lever {
		return "+" + abs(int(activation_queue[0].p_action.cost * added_cost)) + ' By on the last densification out of LA&FA';
	}			
}
//------------------------------ end of Densification_out_Coast_Border_and_Risk_Area_Lever -------------------------------//

species Expropriation_Lever parent: Cost_Lever{
	int indicator 			-> { my_district.count_expropriation };
	string progression_bar 	-> { "" + my_district.count_expropriation + " expropriation / " + int(threshold) +" max" };
	
	init{
		lever_name 	<- world.get_lever_name('LEVER_EXPROPRIATION');
		lever_type	<- world.get_lever_type('LEVER_EXPROPRIATION');
		threshold 	<- 1.0;
		added_cost 	<- -0.25 ;
		help_lever_msg 	<- world.get_message('LEV_GANIVELLE_HELPER1') + " " + int(100*added_cost) + "% "+ world.get_message('LEV_EXPROPRIATION_HELPER2');
		player_msg 		<- world.get_message('LEV_WITHDRAWAL_PLAYER');
	}	
		
	string info_of_next_activated_lever {
		return "+" + abs(int(activation_queue[0].p_action.cost * added_cost)) + ' By on the last expropriation';
	}		
}
//------------------------------ end of Expropriation_Lever -------------------------------//

species Destroy_Dike_Lever parent: Cost_Lever{
	float indicator 		 -> { my_district.length_destroyed_dikes / my_district.length_dikes_t0 };
	bool should_be_activated -> { indicator > threshold and !empty(my_district.actions_expropriation()) };
	string progression_bar 	 -> { "" + my_district.length_destroyed_dikes + " m. / " + threshold + " * " + my_district.length_dikes_t0 + " m. at t0"};
	
	init{
		lever_name 	<- world.get_lever_name('LEVER_DESTROY_DIKE');
		lever_type 	<- world.get_lever_type('LEVER_DESTROY_DIKE');
		threshold 	<- 0.01;
		added_cost 	<- -0.5 ;
		help_lever_msg 	<- world.get_message('LEV_GANIVELLE_HELPER1') + " " + int(100*added_cost) + "% du coût de démantellement ; si a aussi exproprié";
		player_msg 		<- world.get_message('LEV_WITHDRAWAL_PLAYER');
	}
		
	string info_of_next_activated_lever {
		return "+" + abs(int(activation_queue[0].p_action.cost * added_cost)) + ' By on the last destroy';
	}	
}
//------------------------------ end of Destroy_Dike_Lever -------------------------------//

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
				do init_from_map(msg);
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
				int amount_value <- int(values at values.keys[0]);
				if  amount_value != 0 {
					
					switch int(values at values.keys[1]) {
						match 1 { msg_player <- msg1; }
						match 2 { msg_player <- msg2; }
						match 3 { msg_player <- msg3; }
						default { msg_player <- values at values.keys[1]; }
					}
					put TAKE_MONEY_FROM 			key: LEADER_COMMAND 	in: msg;
					put amount_value			 	key: AMOUNT 			in: msg;
					put msg_player 					key: MSG_TO_PLAYER 		in: msg;
					
					msg_activity[0] <- world.get_message('LDR_MSG_TAKE_MONEY_FROM');
					msg_activity[1] <- msg_player + " : " + amount_value + "By";
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
				int amount_value <- int(values at values.keys[0]);			
				if amount_value != 0 {
					switch int(values at values.keys[1]) {
						match 1 { msg_player <- msg1; }
						match 2 { msg_player <- msg2; }
						match 3 { msg_player <- msg3; }
						default { msg_player <- values at values.keys[1]; }
					}
					put GIVE_MONEY_TO 			 	key: LEADER_COMMAND in: msg;
					put amount_value 				key: AMOUNT 		in: msg;
					put msg_player 					key: MSG_TO_PLAYER 	in:msg;
					
					msg_activity[0] <- world.get_message('LDR_MSG_SEND_MONEY_TO');
					msg_activity[1] <- msg_player + " : " + amount_value + "By";
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
				string custom_msg <- values at values.keys[0];
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
					msg_activity[1] <- msg_player;		
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
	string default_language <- first(text_file("../includes/config/littosim.csv").contents where (each contains 'LANGUAGE')) split_with ';' at 1;
	
	init { minimum_cycle_duration <- 0.5; }
	
	parameter "Language choice : " var: my_language	 <- default_language  among: languages_list;
	
	output{
		display levers{
			graphics "Round" {
				string msg_round <- world.get_message('MSG_ROUND');
				draw  (msg_round + " : " + game_round)  at: {45,3} font: font("Arial", 20 , #bold) color: #red ;
			}
			species District_Name;
			species District_Action_Button;
			species Create_Dike_Lever;
			species Raise_Dike_Lever;
			species Repair_Dike_Lever;
			species AU_or_Ui_in_Coast_Border_Area_Lever;
			species AU_or_Ui_in_Risk_Area_Lever;
			species Ganivelle_Lever;
			species Us_out_Coast_Border_or_Risk_Area_Lever;
			species Us_in_Coast_Border_Area_Lever;
			species Us_in_Risk_Area_Lever;
			species Inland_Dike_Lever;
			species No_Dike_Creation_Lever;
			species No_Dike_Raise_Lever;
			species No_Dike_Repair_Lever;
			species A_to_N_in_Coast_Border_or_Risk_Area_Lever ;
			species Densification_out_Coast_Border_and_Risk_Area_Lever ;
			species Expropriation_Lever;
			species Destroy_Dike_Lever;
			
			event [mouse_down] action: user_click;
		}
	}
}
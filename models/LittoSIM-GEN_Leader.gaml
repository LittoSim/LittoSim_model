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
	list<string> leader_activities <- [];
	list<Player_Action> player_actions <- [];
	list<Activated_Lever> activated_levers <- [];	
	District selected_district <- nil;
	geometry shape <- square(100#m);
	Lever selected_lever;
	Lever explored_lever;
	list<species<Lever>> all_levers <- [];
	
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

		create District from: districts_shape with: [district_code::string(read("dist_code")), dist_id::int(read("player_id"))] {
			if(dist_id = 0) {
				do die;
			}
			district_name <- world.dist_code_sname_correspondance_table at district_code;
			district_long_name <- world.dist_code_lname_correspondance_table at district_code;
		}
		
		do create_district_buttons_names;
		do create_levers;
		create Network_Leader;
		
		create Lever_Window_Info;
		create Lever_Window_Actions;
	}
	//------------------------------ end of init -------------------------------//
	
	action create_district_buttons_names{
		loop i from: 0 to: 3 {
			create District_Name {
				display_name <- District[i].district_long_name;
				location	 <- (Grille grid_at {i,0}).location;
			}
			create District_Action_Button {
				command 	 <- EXCHANGE_MONEY;
				display_name <- world.get_message("LDR_EXCHANGE_MONEY");
				location	 <- (Grille[i,1]).location - {0,6.5};
				my_district  <- District[i];
			}
			create District_Action_Button {
				command 	 <- GIVE_MONEY_TO;
				display_name <- world.get_message("LDR_MSG_SEND_MONEY");
				location	 <- (Grille[i,1]).location - {0,3.5};
				my_district  <- District[i];
			}
			create District_Action_Button {
				command 	 <- TAKE_MONEY_FROM;
				display_name <- world.get_message("LDR_MSG_WITHDRAW_MONEY");
				location	 <- (Grille[i,1]).location - {0,0.5};
				my_district  <- District[i];
			}
			create District_Action_Button {
				command 	 <- SEND_MESSAGE_TO;
				display_name <- world.get_message("LDR_MSG_SEND_MSG");
				location	 <- (Grille[i,1]).location + {0,2.5};
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
						col_index <- i;
						row_index <- int(j/2 + 2);
						location	<- (Grille[col_index, row_index]).location - {0, 3 + (-4.5 * j mod 2)};
						add self to: my_district.levers;
					}
				}
			}
		}
	}
	
	action record_leader_activity (string msg_type, string d, string msg){
		string aText <- "<" + string (current_date.hour) + ":" + current_date.minute + ">" + msg_type + " " + d + " -> " + msg;
		write aText;
		add ("<" + machine_time + ">" + aText) to: leader_activities;
	}
	
	action save_leader_data{
		string folder_name <- "leader_data-" + sim_id;
		int num_round <- game_round;
		if length(leader_activities) > 0 {
			loop a over: leader_activities {
				save a to: records_folder + folder_name + "/leader_activities_round" + num_round + ".txt" type: "text";
			}
			leader_activities <- [];
		}
		if length(player_actions) > 0 {
			loop pa over: player_actions {
				save pa to: records_folder + folder_name + "/player_actions_round" + num_round + ".csv" type: "csv";
			}
			player_actions <- [];
		}
		if length(activated_levers) > 0 {
			loop al over: activated_levers {
				save al to: records_folder + folder_name + "/activated_levers_round" + num_round + ".csv" type: "csv";
			}
			activated_levers <- [];
		} 
		loop a over: (all_levers accumulate (each.population) sort_by (each.my_district.dist_id)) {
			save a to: records_folder + folder_name + "/all_levers_round" + num_round + ".csv"  type: "csv" rewrite: false;
		}
	}

	action user_click{
		point loc <- #user_location;
		if selected_lever != nil {
			Lever_Window_Button but <- (Lever_Window_Button) first_with (each overlaps loc);
			if but != nil {
				switch but.command {
					match 0 {
						if species(selected_lever).parent = Delay_Lever {
							ask Delay_Lever(selected_lever) { do change_lever_delay; }
						} else{
							ask Cost_Lever(selected_lever) { do change_lever_cost; }
						}
						selected_lever <- nil;
					}
					match 1 {
						ask selected_lever { do change_lever_threshold_value; }
						selected_lever <- nil;
					}
					match 2 {
						ask selected_lever { do change_lever_player_msg; }
						selected_lever <- nil;
					}
					match 3 {
						if selected_lever.status_on and selected_lever.timer_activated {
							ask selected_lever { do cancel_next_activated_action; }
							selected_lever <- nil;
						}
					}
					match 4 {
						if selected_lever.status_on and selected_lever.timer_activated {
							ask selected_lever { do cancel_all_activated_actions; }
							selected_lever <- nil;
						}
					}
					match 5 {
						if selected_lever.status_on and selected_lever.timer_activated{
							ask selected_lever { do accept_next_activated_action; }
							selected_lever <- nil;
						}
					}
					match 6 {
						if selected_lever.status_on and selected_lever.timer_activated {
							ask selected_lever { do accept_all_activated_actions; }
							selected_lever <- nil;
						}
					}
					match 7 {
						ask selected_lever { do toggle_status; }
						selected_lever <- nil;
					}
					match 8 {
						ask selected_lever { do write_help_lever_msg; }
						selected_lever <- nil;
					}
					match 9 {
						selected_lever <- nil;
					}
				}
				
			}
			
		} else {
			District_Action_Button but <- (District_Action_Button) first_with (each overlaps loc);
			if but != nil { 
				ask District_Action_Button where (each = but){
					do district_button_cliked();
				}
			}else{
				selected_lever <- Lever(first(all_levers accumulate (each.population) first_with (each overlaps loc)));
				if selected_lever != nil {
					 string code_msg <- species(selected_lever).parent = Delay_Lever ? 'LEV_CHANGE_IMPACT_DELAY' : 'LEV_CHANGE_IMPACT_COST';
					 Lever_Window_Button[0].text <- world.get_message(code_msg);
				}
			}	
		}
	}
	
	action user_move {
		if selected_lever != nil {
			explored_lever <- nil;
			return;
		}
		point loc <- #user_location;
		explored_lever <- Lever(first(all_levers accumulate (each.population) first_with (each overlaps loc)));

		if explored_lever != nil {
			Lever my_lev <- explored_lever;
			ask Lever_Window_Info{
				loca <- my_lev.location;
				if my_lev.col_index = 0 {
					loca <- loca + {5,0};
				}else if my_lev.col_index = 3 {
					loca <- loca - {5,0};
				}
				if my_lev.row_index = 10 {
					loca <- loca - {0,2.5};
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
	int command 		 			<- -1 on_change: { label <- world.label_of_action(command); };
	string label 		 			<- "";
	int cost 			 			<- 0;
	int initial_application_round 	<- -1;
	int command_round 				<- -1;	
	bool is_applied -> { game_round >= initial_application_round };
	int round_delay	-> { activated_levers sum_of (each.added_delay) } ; // number rounds of delay
	bool is_delayed -> { round_delay > 0 };
	
	string action_type 		<- ""; 					// COAST_DEF or LU
	string previous_lu_name <- "";  				// for LU action
	bool is_expropriation 	<- false; 				// for LU action
	bool is_in_protected_area 	<- false; 			// for COAST_DEF action
	bool is_in_coast_border_area 	<- false; 
	bool is_in_risk_area 	<- false; 				// for LU action
	bool is_inland_dike 	<- false; 				// for COAST_DEF (retro dikes)
	string strategy_profile	<- "";
	float lever_activation_time;
	int length_coast_def;
	list<Activated_Lever> activated_levers 	<-[];
	bool should_wait_lever_to_activate 		<- false;
	bool a_lever_has_been_applied			<- false;
	
	string get_strategy_profile {
		if(action_type = PLAYER_ACTION_TYPE_COAST_DEF){
			if is_inland_dike { return SOFT_DEFENSE; }
			else{
				switch command {
					match_one [ACTION_CREATE_DIKE, ACTION_RAISE_DIKE, ACTION_REPAIR_DIKE] { return BUILDER; }
					match_one [ACTION_CREATE_DUNE, ACTION_INSTALL_GANIVELLE] { return SOFT_DEFENSE; }
					match ACTION_DESTROY_DIKE	{ return WITHDRAWAL;	}
				}
			}
		}else {
			if is_expropriation { return WITHDRAWAL; }
			else {
				switch command {
					match_one [ACTION_MODIFY_LAND_COVER_AU, ACTION_MODIFY_LAND_COVER_U]   { return BUILDER;	 }
					match_one [ACTION_MODIFY_LAND_COVER_AUs, ACTION_MODIFY_LAND_COVER_Us] { return SOFT_DEFENSE; }
					match ACTION_MODIFY_LAND_COVER_A {
						if previous_lu_name = 'N' and is_in_risk_area { return BUILDER;}
					}
					match ACTION_MODIFY_LAND_COVER_N {
						if previous_lu_name = 'A'{
							return is_in_risk_area ? WITHDRAWAL :SOFT_DEFENSE;						
						} else if previous_lu_name = 'AU'{
							return WITHDRAWAL;
						}
					}
				}
			}
		}
		return NEUTRAL;
	}
	
	action init_from_map (map<string, string> a ){
		self.id 						<- a at "id";
		self.element_id 				<- int(a at "element_id");
		self.district_code 				<- a at DISTRICT_CODE;
		self.command 					<- int(a at "command");
		self.label 						<- world.label_of_action(command);
		self.cost 						<- int(a at "cost");
		self.initial_application_round 	<- int(a at "initial_application_round");
		self.action_type 				<- a at "action_type";
		self.previous_lu_name 			<- a at "previous_lu_name";
		self.is_expropriation 			<- bool(a at "is_expropriation");
		self.is_in_protected_area 		<- bool(a at "is_in_protected_area");
		self.is_in_coast_border_area 	<- bool(a at "is_in_coast_border_area");
		self.is_in_risk_area 			<- bool(a at "is_in_risk_area");
		self.is_inland_dike 			<- bool(a at "is_inland_dike");
		self.command_round 				<- int(a at "command_round");
		self.strategy_profile 			<- get_strategy_profile();
		self.length_coast_def 			<- int(a at "length_coast_def");
		self.a_lever_has_been_applied 	<- bool(a at "a_lever_has_been_applied");			
	}
	
	map<string,string> build_map_from_attributes{
		map<string,string> res <- [
			"OBJECT_TYPE"::OBJECT_TYPE_PLAYER_ACTION,
			"id"::id,
			"element_id"::string(element_id),
			(DISTRICT_CODE)::district_code,
			"command"::string(command),
			"label"::label,
			"cost"::string(cost),
			"initial_application_round"::string(initial_application_round),
			"action_type"::action_type,
			"previous_lu_name"::previous_lu_name,
			"is_expropriation"::is_expropriation,
			"is_in_protected_area"::is_in_protected_area,
			"is_in_coast_border_area"::is_in_coast_border_area,
			"is_in_risk_area"::is_in_risk_area,
			"is_inland_dike"::is_inland_dike,
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
	float budget;
	bool not_updated <- false;
	bool is_selected -> {selected_district = self};
	list<Lever> levers ;
	
	// indicators for leader
	int length_dikes_t0 								<- int(0#m);
	int length_dunes_t0 								<- int(0#m); 
	int count_LU_urban_t0 								<- 0;
	int count_LU_U_and_AU_is_in_coast_border_area_t0 	<- 0;
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
	int count_A_to_N_in_coast_border_or_risk_area			<- 0;
	int count_densification_out_coast_border_and_risk_area	<- 0;
	
	action update_indicators_and_register_player_action (Player_Action act){
		if act.is_applied {
			write world.replace_strings('LDR_MSG_ACTION_RECEIVED_VALIDATED', [act.id]);
		}
		if act.is_expropriation {	
			count_expropriation <- count_expropriation + 1;
			ask Expropriation_Lever where(each.my_district = self) { do register_and_check_activation(act); }
		}
		
		switch act.command {
			match ACTION_CREATE_DIKE {
				if act.is_inland_dike {
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
				if !act.is_in_risk_area and !act.is_in_coast_border_area {
					count_Us_out_coast_border_or_risk_area <- count_Us_out_coast_border_or_risk_area +1;
					ask Us_out_Coast_Border_or_Risk_Area_Lever where(each.my_district = self) { do register_and_check_activation(act); }
				} else{
					if act.is_in_coast_border_area {
					count_Us_in_coast_border_area <- count_Us_in_coast_border_area +1;
					ask Us_in_Coast_Border_Area_Lever where(each.my_district = self) { do register_and_check_activation(act); }
					}
					if act.is_in_risk_area {
						count_Us_in_risk_area <- count_Us_in_risk_area +1;
						ask Us_in_Risk_Area_Lever where(each.my_district = self) { do register_and_check_activation(act); }
					}
				}
			}
			match ACTION_MODIFY_LAND_COVER_N {
				if act.previous_lu_name = "A" and (act.is_in_coast_border_area or act.is_in_risk_area) {
					count_A_to_N_in_coast_border_or_risk_area <- count_A_to_N_in_coast_border_or_risk_area + 1;
					ask A_to_N_in_Coast_Border_or_Risk_Area_Lever where(each.my_district = self) {
						do register (act);
						do check_activation_and_impact_on_first_element_of (myself.actions_densification_out_coast_border_and_risk_area());
					}
				}
			}
			match_one [ACTION_MODIFY_LAND_COVER_Ui, ACTION_MODIFY_LAND_COVER_AU] {
				if act.command = ACTION_MODIFY_LAND_COVER_Ui and !act.is_in_coast_border_area and !act.is_in_risk_area {	
					count_densification_out_coast_border_and_risk_area <- count_densification_out_coast_border_and_risk_area + 1;
					ask Densification_out_Coast_Border_and_Risk_Area_Lever where(each.my_district = self) { do register_and_check_activation (act); }
				}
				else{
					if act.is_in_coast_border_area and act.previous_lu_name != "Us"{
						count_AU_or_Ui_in_coast_border_area <- count_AU_or_Ui_in_coast_border_area + 1;
						ask AU_or_Ui_in_Coast_Border_Area_Lever where(each.my_district = self) { do register_and_check_activation(act); }
					}
					if act.is_in_risk_area {
						count_AU_or_Ui_in_risk_area <- count_AU_or_Ui_in_risk_area + 1;
						ask AU_or_Ui_in_Risk_Area_Lever where(each.my_district = self) { do register_and_check_activation(act); }
					}	
				}
			}
		}
	}
	
	list<Player_Action> actions_install_ganivelle {
		return ((Ganivelle_Lever first_with (each.my_district = self)).associated_actions sort_by (-each.command_round));
	}
	
	list<Player_Action> actions_densification_out_coast_border_and_risk_area{
		return ((Densification_out_Coast_Border_and_Risk_Area_Lever first_with(each.my_district = self)).associated_actions sort_by(-each.command_round));
	}
	
	list<Player_Action> actions_expropriation{
		return ((Expropriation_Lever first_with(each.my_district = self)).associated_actions sort_by(-each.command_round));
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
	int added_delay <- 0;
	int added_cost 	<- 0;
	int round_creation;
	int round_application;
	
	action init_from_map (map<string, string> m ){
		id 					<- int(m["id"]);
		lever_name 			<- m["lever_name"];
		district_code 		<- m[DISTRICT_CODE];
		p_action_id 		<- m["p_action_id"];
		added_cost 			<- int(m["added_cost"]);
		added_delay 		<- int(m["added_delay"]);
		lever_explanation 	<- m["lever_explanation"];
		round_creation 		<- int(m["round_creation"]);
		round_application	<- int(m["round_application"]);
	}
	
	map<string,string> build_map_from_attributes{
		map<string,string> res <- [
			"OBJECT_TYPE"::OBJECT_TYPE_ACTIVATED_LEVER,
			"id"::id,
			"lever_name"::lever_name,
			(DISTRICT_CODE)::district_code,
			"p_action_id"::p_action_id,
			"added_cost"::added_cost,
			"added_delay"::added_delay,
			"lever_explanation"::lever_explanation,
			"round_creation"::round_creation,
			"round_application"::round_application]	;
		return res;
	}
}
//------------------------------ End of Activated_Lever -------------------------------//

species Lever_Window_Info {
	point loca;
	geometry shape <- rectangle(30#m,15#m);
	
	aspect {
		if explored_lever != nil {
			Lever my_lever <- explored_lever;
			draw shape color: my_lever.color_profile() at: loca;
			draw 0.5 around shape color: #black;
			
			if my_lever.timer_activated {
				draw shape+0.2#m color: #red;
			}
			
			draw my_lever.box_title at: loca - {0,4} anchor: #center font: font("Arial", 12 , #bold) color: #black;
			draw my_lever.progression_bar at: loca - {0, 2} anchor: #center font: font("Arial", 12 , #plain) color: my_lever.threshold_reached ? #red : #black;
			
			if my_lever.timer_activated {
				draw string(my_lever.remaining_seconds()) + " s " + (length(my_lever.activation_queue)=1? "" : "(" + 
					length(my_lever.activation_queue) + ")") + "-> " + my_lever.info_of_next_activated_lever()
						at: loca anchor: #center font: font("Arial", 12 , #plain) color:#black;
			}
			if my_lever.has_activated_levers {
				draw my_lever.activation_label_L1 at: loca + {0,2} anchor: #center font: font("Arial", 12 , #plain) color:#black;
				draw my_lever.activation_label_L2 at: loca + {0,4} anchor: #center font: font("Arial", 12 , #plain) color:#black;
			}
			
			if !my_lever.status_on { draw shape+0.1#m color: rgb(200,200,200,160); }
		}
	}
}

species Lever_Window_Actions {
	point loca <- world.location;
	geometry shape <- rectangle(30#m, 60#m);
	
	list<string> text_buttons <- ['','LEV_CHANGE_TRESHOLD','LEV_CHANGE_PLAYER_MSG','LEV_CANCEL_NEXT_APP','LEV_CANCEL_ALL_APPS',
				'LEV_VALIDATE_NEXT_APP','LEV_VALIDATE_ALL_APPS','LEV_ACTIVE_DEACTIVE','LEV_HOW_WORKS','LEV_CLOSE_WINDOW'];
	
	init {
		point lo <- loca - {15, 30};
		loop i from: 0 to: 9 {
			create Lever_Window_Button {
				command <- i ;
				if myself.text_buttons [i] != "" {
					text <- world.get_message(myself.text_buttons [i]);	
				}
				loca <- lo + {15, 7 + (i * 5.5)};
				if i = 9 {	col <- #red; }
			}
		}
	}
	
	aspect {
		if selected_lever != nil {
			draw shape color: #white border: #black at: loca;
			draw selected_lever.box_title at: loca - {0,27.5} anchor: #center font: font("Arial", 13 , #bold) color: #darkblue;
		}
	}
}

species Lever_Window_Button {
	int command;
	string text;
	point loca;
	rgb col <- #yellow;
	geometry shape <- rectangle(25#m, 5#m);
	
	aspect {
		if selected_lever != nil {
			draw shape color: col border: #black at: loca;
			draw text font: font("Arial", 12 , #bold) color: #darkblue at: loca anchor: #center;
			if command in [3,4,5,6] and (!selected_lever.status_on or !selected_lever.timer_activated){
				draw shape+0.1#m color: rgb(200,200,200,160);
			}
		}
	}
}

//------------------------------ End of Lever_Windows -------------------------------//

species Lever {
	
	District my_district;
	float indicator;
	float threshold 			<- 0.2;
	bool status_on 			 	<- true; // can be on or off . If off then the checkLeverActivation is not performed
	bool should_be_activated 	-> { indicator > threshold };
	bool threshold_reached 	 	<- false;
	bool timer_activated 	 	-> { !empty(activation_queue) };
	bool has_activated_levers	-> { !empty(activated_levers) };
	int timer_duration 		 	<- 240000;	// 1 minute = 60000 milliseconds //   4 mn = 240000
	string lever_type		 	<-	"";
	string lever_name		 	<-	"";
	string box_title 		 	-> {lever_name +' ('+length(associated_actions)+')'};
	string progression_bar		<-	"";
	string help_lever_msg 	 	<-	"";
	string activation_label_L1	<-	"";
	string activation_label_L2	<-	"";
	string player_msg;
	int row_index;
	int col_index;
	list<Player_Action>   associated_actions;
	list<Activated_Lever> activation_queue;
	list<Activated_Lever> activated_levers;
	
	init {
		shape <- rectangle (24.5, 4.25);
	}
	
	aspect default{
		if timer_activated {
			draw shape+0.2#m color: #red;
		}
		
		draw shape color: color_profile() border: #black at: location;
		draw lever_name +' ('+length(associated_actions)+')' at: location -{0,1.5} anchor: #center font: font("Arial", 12 , #bold) color: #black;
		draw progression_bar at: location anchor: #center font: font("Arial", 12 , #plain) color: threshold_reached ? #red : #black;
		
		if timer_activated and length(activation_queue) > 0{
			draw string(remaining_seconds()) + " s " + (length(activation_queue)=1? "" : "(" + length(activation_queue) + ")") + "->" + info_of_next_activated_lever()
					at: location + {0,1.5} anchor: #center font: font("Arial", 12 , #plain) color:#black;
		}
		
		if !status_on { draw shape+0.1#m color: rgb(200,200,200,160); } // activate|deactivate
		if explored_lever != nil and explored_lever = self {
			draw shape+0.1#m empty: true color: #black;
		}
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
	
	action queue_activated_lever(Player_Action a_p_action){
		create Activated_Lever {
			lever_name 		<- myself.lever_name;
			district_code 	<- myself.my_district.district_code;
			self.p_action 	<- a_p_action;
			p_action_id 	<- a_p_action.id;
			activation_time <- machine_time + myself.timer_duration ;
			round_creation 	<- game_round;
			add self to: myself.activation_queue;
			add self to: activated_levers;
		}
		ask world {
			do record_leader_activity("Lever " + myself.lever_name + " programmed at", myself.my_district.district_name, a_p_action.label + "(" + a_p_action + ")");
		}
	}

	action toggle_status {
		status_on <- !status_on ;
		if !status_on { activation_queue <-[]; }
	}
	
	action write_help_lever_msg {
		map values <- user_input(world.get_message('LEV_MSG_LEVER_HELP'),[help_lever_msg + "\n" + world.get_message('LEV_THRESHOLD_VALUE') + " : " + threshold::true]);
	}
	
	action change_lever_player_msg {
		map values <- user_input(world.get_message('LEV_MSG_SENT_TRIGGER_LEVER'), [world.get_message('LEV_MESSAGE'):: player_msg]);
		player_msg <- values at values.keys[0];
		ask world {
			do record_leader_activity("Change lever " + myself.lever_name + " at", myself.my_district.district_name, "The new message sent to the player is : " + myself.player_msg);
		}
	}
	
	action change_lever_threshold_value{
		map values <- user_input(world.replace_strings('LEV_CURRENT_THRESHOLD_LEVER', [lever_name, string(threshold)]), [world.get_message('LEV_NEW_THRESHOLD_VALUE') + " : ":: threshold]); 
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
			remove index: 0 from: activation_queue;	
		}
	}
	
	action cancel_all_activated_actions {
		loop aa over: activation_queue {
			do cancel_lever(aa);
		}
		activation_queue <- [];
	}
	
	action cancel_lever(Activated_Lever lev){
		lev.p_action.should_wait_lever_to_activate <- false;
		do inform_network_should_wait_lever_to_activate(lev.p_action);
		ask world {
			do record_leader_activity("Lever " + myself.lever_name + " canceled at", myself.my_district.district_name, "Cancel of " + myself.activation_queue[0].p_action);
		}
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
	float added_cost		<- 0.25;
	int last_lever_cost 	<- 0;
	
	action change_lever_cost{
		map values <- user_input(world.replace_strings('LEV_ACTUAL_PERCENTAGE_COST', [lever_name, string(added_cost)]), [world.get_message('LEV_ENTER_THE_NEW') + " :":: added_cost]);
		float n_val <- float(values at values.keys[0]);
		added_cost <- n_val;
		
		ask world {
			do record_leader_activity("Change lever " + myself.lever_name + " at", myself.my_district.district_name, "-> The new cost of the lever is : " + myself.added_cost);
		}
	}
	
	string info_of_next_activated_lever {
		return "" + activation_queue[0].p_action.length_coast_def + " m (" + int(activation_queue[0].p_action.cost * added_cost) + ' By)';
	}
	
	action apply_lever(Activated_Lever lev){
		lev.applied 		  <- true;
		lev.round_application <- game_round;
		lev.lever_explanation <- player_msg;
		lev.added_cost 		  <- int(lev.p_action.cost * added_cost);
		do send_lever_message(lev);
		
		last_lever_cost 	<- lev.added_cost;
		activation_label_L1 <- world.get_message('LDR_LAST') + " "   + (last_lever_cost >= 0 ? world.get_message('LDR_LEVY') : world.get_message('LDR_PAYMENT')) + " : " + abs(last_lever_cost) + ' By';
		activation_label_L2 <- world.get_message('LDR_TOTAL') + " "  + (last_lever_cost >= 0 ? world.get_message('LDR_TAKEN') : world.get_message('LDR_GIVEN')) + " : " + abs(total_lever_cost()) + ' By';
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
	int added_delay <- 2;

	action change_lever_delay {
		map values <- user_input(world.replace_strings('LEV_ACTUAL_DELAY', [lever_name, string(added_delay)]), [world.get_message('LEV_ENTER_THE_NEW') + " :":: added_delay]);
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
		lev.added_delay <- added_delay;
		do send_lever_message;
		
		activation_label_L1 <- (total_lever_delay() < 0 ? world.get_message('LDR_TOTAL_ADVANCE') + ": " : world.get_message('LDR_TOTAL_DELAY') + ": ") + abs(total_lever_delay()) + ' ' + world.get_message('LDR_MSG_ROUNDS');
		lev.p_action.should_wait_lever_to_activate <- false;
		do inform_network_should_wait_lever_to_activate(lev.p_action);
		
		ask world {
			do record_leader_activity(myself.lever_name + " triggered at", myself.my_district.district_name, myself.help_lever_msg + " : " + lev.added_delay + " rounds" + "(" + lev.p_action + ")");
		}
	}
	
	int total_lever_delay {
		return activated_levers sum_of (each.added_delay);
	}
}
//------------------------------ End of Delay_Lever -------------------------------//

species Create_Dike_Lever parent: Cost_Lever {
	float indicator 		-> { my_district.length_dikes_t0 = 0 ? 0.0 : my_district.length_created_dikes / my_district.length_dikes_t0 };
	string progression_bar  -> { "" + my_district.length_created_dikes + " m / " + threshold + " * " + my_district.length_dikes_t0 + " m " +world.get_message('LEV_AT')+ " t0"};
	
	init{
		lever_name 		<- world.get_lever_name('LEVER_CREATE_DIKE');
		lever_type		<- world.get_lever_type('LEVER_CREATE_DIKE');
		help_lever_msg 	<- world.replace_strings('LEV_CREATE_DIKE_HELPER', [string(int(100*added_cost))]);
		player_msg 		<- world.get_message('LEV_CREATE_DIKE_PLAYER');	
	}
}
//------------------------------ End of Create_Dike_Lever -------------------------------//

species Raise_Dike_Lever parent: Cost_Lever {
	float indicator 		-> { my_district.length_dikes_t0 = 0 ? 0.0 : my_district.length_raised_dikes / my_district.length_dikes_t0 };
	string progression_bar 	-> { "" + my_district.length_raised_dikes + " m / " + threshold + " * " + my_district.length_dikes_t0 + " m " +world.get_message('LEV_AT')+ " t0"};
	init{
		lever_name 		<- world.get_lever_name('LEVER_RAISE_DIKE');
		lever_type		<- world.get_lever_type('LEVER_RAISE_DIKE');
		help_lever_msg 	<- world.replace_strings('LEV_CREATE_DIKE_HELPER', [string(int(100*added_cost))]);
		player_msg 		<- world.get_message('LEV_CREATE_DIKE_PLAYER');
	}
}
//------------------------------ End of Raise_Dike_Lever -------------------------------//

species Repair_Dike_Lever parent: Cost_Lever{
	float indicator 			-> { my_district.length_dikes_t0 = 0 ? 0.0 : my_district.length_repaired_dikes / my_district.length_dikes_t0 };
	bool should_be_activated 	-> { indicator > threshold and (my_district.length_created_dikes != 0 or my_district.length_raised_dikes != 0)};
	string progression_bar 		-> { "" + my_district.length_repaired_dikes + " m / " + threshold + " * " + my_district.length_dikes_t0 + " m " +world.get_message('LEV_AT')+ " t0"};
	
	init{
		lever_name 		<- world.get_lever_name('LEVER_REPAIR_DIKE');
		lever_type		<- world.get_lever_type('LEVER_REPAIR_DIKE');
		help_lever_msg 	<- world.replace_strings('LEV_CREATE_DIKE_HELPER', [string(int(100*added_cost))]);
		player_msg 		<- world.get_message('LEV_REPAIR_DIKE_PLAYER');
	}
}
//------------------------------ End of Repair_Dike_Lever -------------------------------//

species AU_or_Ui_in_Coast_Border_Area_Lever parent: Delay_Lever{
	int indicator 			-> { my_district.count_AU_or_Ui_in_coast_border_area};
	string progression_bar 	-> { "" + indicator + " " + world.get_message('LEV_MSG_ACTIONS') + " / " + int(threshold) + " " + world.get_message('LEV_MAX')};
	
	init{
		lever_name 	<- world.get_lever_name('LEVER_AU_Ui_COAST_BORDER_AREA');
		lever_type	<- world.get_lever_type('LEVER_AU_Ui_COAST_BORDER_AREA');
		threshold 	<- 2.0;
		help_lever_msg 	<- world.replace_strings('LEV_COAST_BORDER_AREA_HELPER1', [string(added_delay)]);
		player_msg 		<- world.get_message('LEV_COAST_BORDER_AREA_PLAYER');	
	}
		
	string info_of_next_activated_lever {
		switch activation_queue[0].p_action.command {
			match ACTION_MODIFY_LAND_COVER_AU { return world.replace_strings('LEV_CONSTRUCTION', [string(added_delay)]);}
			match ACTION_MODIFY_LAND_COVER_Ui { return world.replace_strings('LEV_DENSIFICATION', [string(added_delay)]);}
		} 
	}
}
//------------------------------ End of AU_or_Ui_in_Coast_Border_Area_Lever -------------------------------//

species AU_or_Ui_in_Risk_Area_Lever parent: Cost_Lever{
	int indicator 			-> { my_district.count_AU_or_Ui_in_risk_area };
	string progression_bar 	-> { "" + indicator + " " + world.get_message('LEV_MSG_ACTIONS') + " / "+ int(threshold) + " " + world.get_message('LEV_MAX') };
	
	init{
		lever_name 	<- world.get_lever_name('LEVER_AU_Ui_RISK_AREA');
		lever_type	<- world.get_lever_type('LEVER_AU_Ui_RISK_AREA');
		threshold 	<- 1.0;
		added_cost 	<- 0.5 ;
		help_lever_msg 	<- world.replace_strings('LEV_CREATE_DIKE_HELPER', [string(int(100*added_cost))]);
		player_msg 		<- world.get_message('LEV_REPAIR_DIKE_PLAYER');	
	}
		
	string info_of_next_activated_lever {
		switch activation_queue[0].p_action.command {
			match ACTION_MODIFY_LAND_COVER_AU { return "-" + int(activation_queue[0].p_action.cost * added_cost) + " By " + world.get_message('LEV_NEXT_CONSTRUCTION'); }
			match ACTION_MODIFY_LAND_COVER_Ui { return "-" + int(activation_queue[0].p_action.cost * added_cost) + " By " + world.get_message('LEV_NEXT_DENSIFICATION');}
		} 
	}
}
//------------------------------ End of AU_or_Ui_in_Risk_Area_Lever -------------------------------//

species Ganivelle_Lever parent: Cost_Lever {
		int indicator 			-> { my_district.length_dunes_t0 = 0 ? 0 : int(my_district.length_created_ganivelles / my_district.length_dunes_t0) };
		string progression_bar 	-> { "" + my_district.length_created_ganivelles + " m / " + threshold + " * " + my_district.length_dunes_t0 + " m " + world.get_message('LEV_DUNES') };
	
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
	string progression_bar 	-> { "" + indicator + " " + world.get_message('LEV_MSG_ACTIONS') + " / " + int(threshold) + " " + world.get_message('LEV_MAX') };
	
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
		lev.added_delay 	<- 0;
		do send_lever_message (lev);
		
		last_lever_cost 	<- lev.added_cost;
		activation_label_L1 <- "Last payment : " + (-1 * last_lever_cost) + ' By';
		activation_label_L2 <- 'Total paid : '  + (-1 * total_lever_cost()) + ' By';
		
		ask world {
			do record_leader_activity(myself.lever_name + " triggered at", myself.my_district.district_name, myself.help_lever_msg + " : " + lev.added_cost + "By : " + lev.added_delay + " rounds" + "(" + lev.p_action + ")");
		}
	}
}
//------------------------------ End of Us_out_Coast_Border_or_Risk_Area_Lever -------------------------------//

species Us_in_Coast_Border_Area_Lever parent: Cost_Lever{
	int indicator 			-> { my_district.count_Us_in_coast_border_area };
	string progression_bar 	-> { "" + my_district.count_Us_in_coast_border_area + " " + world.get_message('LEV_MSG_ACTIONS') + " / " + int(threshold) +" " + world.get_message('LEV_MAX')};
	
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
	string progression_bar 	-> { "" + my_district.count_Us_in_risk_area + " " + world.get_message('LEV_MSG_ACTIONS') + " / " + int(threshold) + " " + world.get_message('LEV_MAX') };
	
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
	float indicator 		-> { my_district.length_dikes_t0 = 0 ? 0.0 : my_district.length_inland_dikes / my_district.length_dikes_t0 };
	string progression_bar 	-> { "" + my_district.length_inland_dikes + " m / " + threshold + " * " + my_district.length_dikes_t0 + " m " + world.get_message('LEV_DIKES') + " " + world.get_message('LEV_AT') + " t0"};
	
	init{
		lever_name 	<- world.get_lever_name('LEVER_INLAND_DIKE');
		lever_type	<- world.get_lever_type('LEVER_INLAND_DIKE');
		added_delay <- -1;
		threshold 	<- 0.01;
		help_lever_msg 	<- world.get_message('LEV_INLAND_HELPER1') + " " + abs(added_delay) + " " + world.get_message('MSG_ROUND') + (abs(added_delay) > 1 ? "s" : "");
		player_msg 		<- world.get_message('LEV_INLAND_PLAYER');	
	}
		
	string info_of_next_activated_lever {
		return world.get_message('LDR_MSG_RETRODIKE') + " (" + int(activation_queue[0].p_action.length_coast_def) + " m): -" + abs(added_delay) + " " + world.get_message('LDR_MSG_ROUNDS');
	}
}
//------------------------------ End of Inland_Dike_Lever -------------------------------//

species No_Action_On_Dike_Lever parent: Cost_Lever {
	string progression_bar 	-> { "" + int(threshold - nb_rounds_before_activation) + " " + world.get_message('LDR_MSG_ROUNDS') +" / " + int(threshold) + " " + world.get_message('LEV_MAX') };
	int nb_activations 		<- 0;
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
		return world.get_message('LDR_LAST_GANIVELLE') + " - " + abs(int(activation_queue[0].p_action.cost * added_cost)) + ' By';
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
		activation_label_L1 <- world.get_message('LDR_LAST') + " "  + (last_lever_cost >= 0 ? world.get_message('LDR_LEVY') : 
						world.get_message('LDR_PAYMENT')) + " : " + abs(last_lever_cost)   + ' By.';
		activation_label_L2 <- world.get_message('LDR_TOTAL') + " " + (last_lever_cost >= 0 ? world.get_message('LDR_TAKEN'):
						world.get_message('LDR_GIVEN')) + " : " + abs(total_lever_cost())+ ' By.';
		
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
		help_lever_msg 	<- world.get_message('LEV_DURING_MSG') + " " + threshold + " " + world.get_message('LEV_NO_DIKE_CREATION_HELP') + ". " + world.get_message('LEV_GANIVELLE_HELPER1') + " " + int(100*added_cost)+"% " + world.get_message('LEV_GANIVELLE_HELPER2') + "/m";
	}	
}
//------------------------------ end of No_Dike_Creation_Lever -------------------------------//

species No_Dike_Raise_Lever parent: No_Action_On_Dike_Lever{
	init{
		lever_name 		<- world.get_lever_name('LEVER_NO_DIKE_RAISE');
		lever_type		<- world.get_lever_type('LEVER_NO_DIKE_RAISE');
		help_lever_msg 	<- world.get_message('LEV_DURING_MSG') + " " + threshold + " " + world.get_message('LEV_NO_DIKE_RAISE_HELP') + ". " + world.get_message('LEV_GANIVELLE_HELPER1') + " " + int(100*added_cost)+"% " + world.get_message('LEV_GANIVELLE_HELPER2') + "/m";
	}
}
//------------------------------ end of No_Dike_Raise_Lever -------------------------------//

species No_Dike_Repair_Lever parent: No_Action_On_Dike_Lever{
	init{
		lever_name		<- world.get_lever_name('LEVER_NO_DIKE_REPAIR');
		lever_type		<- world.get_lever_type('LEVER_NO_DIKE_REPAIR');
		help_lever_msg 	<- world.get_message('LEV_DURING_MSG') + " " + threshold + " " + world.get_message('LEV_NO_DIKE_REPAIR_HELP') + ". " + world.get_message('LEV_GANIVELLE_HELPER1') + " " + int(100*added_cost)+"% " + world.get_message('LEV_GANIVELLE_HELPER2') + "/m";
	}
}
//------------------------------ end of No_Dike_Repair_Lever -------------------------------//

species A_to_N_in_Coast_Border_or_Risk_Area_Lever parent: Cost_Lever{
	int indicator 				-> { my_district.count_A_to_N_in_coast_border_or_risk_area };
	string progression_bar 		-> { "" + my_district.count_A_to_N_in_coast_border_or_risk_area + " " + world.get_message('LEV_MSG_ACTIONS') + " / " + int(threshold) + " " + world.get_message('LEV_MAX') };
	bool should_be_activated 	-> { indicator > threshold and !empty(my_district.actions_densification_out_coast_border_and_risk_area()) };
	
	init{
		lever_name 	<- world.get_lever_name('LEVER_A_N_COAST_BORDER_RISK_AREA');
		lever_type	<- world.get_lever_type('LEVER_A_N_COAST_BORDER_RISK_AREA');
		threshold 	<- 2.0;
		added_cost 	<- -0.5 ;
		help_lever_msg 	<- world.get_message('LEV_GANIVELLE_HELPER1') + " " + int(100*added_cost) + "% " + world.get_message('LEV_DENSIFICATION_LA_FA');
		player_msg 		<- world.get_message('LEV_GANIVELLE_PLAYER');
	}

	string info_of_next_activated_lever {
		return "+" + abs(int(activation_queue[0].p_action.cost * added_cost)) + ' By ' + world.get_message('LEV_DENSIFICATION_HELPER3');
	}	
}
//------------------------------ end of A_to_N_in_Coast_Border_or_Risk_Area_Lever -------------------------------//

species Densification_out_Coast_Border_and_Risk_Area_Lever parent: Cost_Lever{
	int indicator 			-> { my_district.count_densification_out_coast_border_and_risk_area };
	string progression_bar 	-> { "" + my_district.count_densification_out_coast_border_and_risk_area + " " + world.get_message('LEV_MSG_ACTIONS') + " / " + int(threshold) +" " + world.get_message('LEV_MAX') };
	
	init{
		lever_name 	<- world.get_lever_name('LEVER_DENSIFICATION_COAST_BORDER_RISK_AREA');
		lever_type	<- world.get_lever_type('LEVER_DENSIFICATION_COAST_BORDER_RISK_AREA');
		threshold 	<- 2.0;
		added_cost 	<- -0.25 ;
		help_lever_msg 	<- world.get_message('LEV_GANIVELLE_HELPER1') + " " + int(100*added_cost) + "% " + world.get_message('LEV_DENSIFICATION_HELPER2');
		player_msg 		<- world.get_message('LEV_GANIVELLE_PLAYER');
	}
	
	string info_of_next_activated_lever {
		return "+" + abs(int(activation_queue[0].p_action.cost * added_cost)) + ' By ' + world.get_message('LEV_LAST_DENSIFICATION');
	}			
}
//------------------------------ end of Densification_out_Coast_Border_and_Risk_Area_Lever -------------------------------//

species Expropriation_Lever parent: Cost_Lever{
	int indicator 			-> { my_district.count_expropriation };
	string progression_bar 	-> { "" + my_district.count_expropriation + " " + world.get_message('MSG_EXPROPRIATION') + " / " + int(threshold) + " " + world.get_message('LEV_MAX') };
	
	init{
		lever_name 	<- world.get_lever_name('LEVER_EXPROPRIATION');
		lever_type	<- world.get_lever_type('LEVER_EXPROPRIATION');
		threshold 	<- 1.0;
		added_cost 	<- -0.25 ;
		help_lever_msg 	<- world.get_message('LEV_GANIVELLE_HELPER1') + " " + int(100*added_cost) + "% "+ world.get_message('LEV_EXPROPRIATION_HELPER2');
		player_msg 		<- world.get_message('LEV_WITHDRAWAL_PLAYER');
	}	
		
	string info_of_next_activated_lever {
		return "+" + abs(int(activation_queue[0].p_action.cost * added_cost)) + ' By ' + world.get_message("LEV_LAST_EXPROPRIATION");
	}		
}
//------------------------------ end of Expropriation_Lever -------------------------------//

species Destroy_Dike_Lever parent: Cost_Lever{
	float indicator 		 -> { my_district.length_dikes_t0 = 0 ? 0.0 : my_district.length_destroyed_dikes / my_district.length_dikes_t0 };
	bool should_be_activated -> { indicator > threshold and !empty(my_district.actions_expropriation()) };
	string progression_bar 	 -> { "" + my_district.length_destroyed_dikes + " m / " + threshold + " * " + my_district.length_dikes_t0 + " m " + world.get_message('LEV_AT') + " t0"};
	
	init{
		lever_name 	<- world.get_lever_name('LEVER_DESTROY_DIKE');
		lever_type 	<- world.get_lever_type('LEVER_DESTROY_DIKE');
		threshold 	<- 0.01;
		added_cost 	<- -0.5 ;
		help_lever_msg 	<- world.get_message('LEV_GANIVELLE_HELPER1') + " " + int(100*added_cost) + "% " + world.get_message('LEV_DESTROY_EXPROPR');
		player_msg 		<- world.get_message('LEV_WITHDRAWAL_PLAYER');
	}
		
	string info_of_next_activated_lever {
		return "+" + abs(int(activation_queue[0].p_action.cost * added_cost)) + ' By ' + world.get_message('LEV_LAST_DESTROY');
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
		loop while: has_more_message(){
			message msg 					<- fetch_message();
			string m_sender 				<- msg.sender;
			map<string, string> m_contents 	<- msg.contents;
			switch(m_contents[RESPONSE_TO_LEADER]) {
				match NUM_ROUND	{
					ask world { do save_leader_data; }
					game_round <-int (m_contents[NUM_ROUND]);
					write world.get_message("MSG_ROUND") + " " + game_round;
					ask District{
						string bud <- m_contents[district_code];
						if bud != nil {
							budget <- float(bud);
						}
					}
					loop lev over: all_levers{
						ask lev.population { do check_activation_at_new_round(); }	
					}
				}
				match ACTION_STATE {
					do update_action (m_contents);
				}
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
		Player_Action p_act <- first(Player_Action where(each.id = (msg at "id")));
		if(p_act = nil){ // new action commanded by a player : indicators are updated and levers triggering tresholds are tested
			create Player_Action{
				do init_from_map(msg);
				ask District first_with (each.district_code = district_code) {
					do update_indicators_and_register_player_action (myself);
				}
				map<string, string> mpp <- [(LEADER_COMMAND)::NEW_REQUESTED_ACTION,(DISTRICT_CODE)::district_code,
					(STRATEGY_PROFILE)::strategy_profile,"cost"::cost];
				ask world { do send_message_from_leader(mpp); }
				add self to: player_actions;
			}
		}
		else{ // an update of an action already commanded
			ask first(p_act) {
				do init_from_map(msg);
			}
		}
	}
}
//------------------------------ end of Network_Leader -------------------------------//

grid Grille width: 4 height: 11 {
	init {
		color <- #white ;
	}
}
//------------------------------ end of Grille -------------------------------//

species District_Action_Button parent: District_Name{
	string command;
	District my_district;
	
	init {
		shape <- rectangle(17,2.5);
	}

	aspect default{
		draw shape color: rgb(176,97,188) border: #black;
		draw display_name color: #white font: font("Arial", 12, #bold) at: location anchor: #center;
	}
	
	action district_button_cliked {
		string msg_player 			<- "";
		list<string> msg_activity 	<- ["",""];
		map<string, unknown> msg 	<-[];
		put my_district.district_code	key: DISTRICT_CODE in: msg;
		
		switch(command){
			match EXCHANGE_MONEY {
				list<District> dists <- District - my_district;
				map values 	<- user_input(world.get_message("LDR_TRANSFERT1") + " : \n(0 " + MSG_TO_CANCEL+")\n"
						 + "1 : " + dists[0].district_long_name +
						 "\n2 : " + dists[1].district_long_name +
						 "\n3 : " + dists[2].district_long_name,
										[MSG_AMOUNT + " :" :: "2000", world.get_message('MSG_COMMUNE') :: "0"]);
				int amount_value <- int(values at values.keys[0]);
				int ddist <- int(values at values.keys[1]);
				if amount_value != 0 and ddist in [1,2,3] {
					if my_district.budget - amount_value < PLAYER_MINIMAL_BUDGET {
						map vimp <- user_input(world.get_message('MSG_WARNING'), world.get_message('LDR_TRANSFERT2')::true);
					}else {
						my_district.budget <- my_district.budget - amount_value;
						msg_player <- world.get_message('LDR_TRANSFERT3');
						
						put EXCHANGE_MONEY 		key: LEADER_COMMAND 	in: msg;
						put amount_value		key: AMOUNT 			in: msg;
						put dists[ddist-1].district_code key: "TARGET_DIST" in: msg;
						put msg_player 			key: MSG_TO_PLAYER 	in: msg;
						
						msg_activity[0] <- world.get_message('LDR_EXCHANGE_MONEY');
						msg_activity[1] <- msg_player + " : " + dists[ddist-1].district_name + " (" + amount_value + "By)";
					}
				}
			}
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
		if msg_player != "" {
			ask world {
				do send_message_from_leader(msg);
				do record_leader_activity (msg_activity[0], myself.my_district.district_name, msg_activity[1]);
			}	
		}
	}
}
//------------------------------ end of District_Action_Button -------------------------------//

species District_Name {
	string display_name;
	
	aspect default{
		draw "" + display_name color:#black font: font("Arial", 17.5 , #bold) at: location anchor:#center;
	}
}
//------------------------------ end of District_Name -------------------------------//

experiment LittoSIM_GEN_Leader {
	string default_language <- first(text_file("../includes/config/littosim.conf").contents where (each contains 'LANGUAGE')) split_with ';' at 1;
	list<string> languages_list <- first(text_file("../includes/config/littosim.conf").contents where (each contains 'LANGUAGE_LIST')) split_with ';' at 1 split_with ',';
	
	init {
		minimum_cycle_duration <- 0.5;
	}
	
	parameter "Language choice : " var: my_language	 <- default_language  among: languages_list;
	
	output{
		display levers{
			graphics "Round" {
				string msg_round <- world.get_message('MSG_ROUND');
				draw  (msg_round + " : " + game_round)  at: {world.shape.width/2,2} font: font("Arial", 20 , #bold) color: #red anchor: #center;
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
			species Lever_Window_Info;
			species Lever_Window_Actions;
			species Lever_Window_Button;
			
			event [mouse_down] action: user_click;
			event [mouse_move] action: user_move;
		}
	}
}
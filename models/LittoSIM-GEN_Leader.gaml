/**
 *  LittoSIM_GEN
 *  Authors: Ahmed, Benoit, Brice, Cécilia, Elise, Etienne, Fredéric, Marion, Nicolas B, Nicolas M, Xavier 
 * 
 *  Description : LittoSIM_GEN is a participatory simulation platform implementing a serious playing-game for local authorities.
 * 				  The project aims at modeling effects of coastal flooding on urban areas and at enabling the transfer of scientific
 * 				  findings to risk managers, as well as awareness of those concerned by the risk of coastal flooding.
 * 
 * LittoSIM_GEN_Leader : this module reprsents the game leader.
 */

model Leader

import "params_models/params_leader.gaml"

global{
	
	float sim_id;
	list<string> leader_activities <- [];
	list<Player_Action> player_actions <- [];
	list<Activated_Lever> activated_levers <- [];	
	District selected_district <- nil;
	list<District> districts <- nil;
	geometry shape <- square(100#m);
	Lever selected_lever;
	Player_Button clicked_pButton;
	Lever explored_lever;
	list<species<Lever>> all_levers <- []; // levers in all_levers and levers_names should be in the same order
	list<string> levers_names <- ['LEVER_CREATE_DIKE', 'LEVER_RAISE_DIKE', 'LEVER_REPAIR_DIKE', 'LEVER_AU_Ui_in_COAST_AREA', 'LEVER_AU_Ui_in_RISK_AREA',
								  'LEVER_GANIVELLE', 'LEVER_ENHANCE_NAT_ACCR', 'LEVER_CREATE_DUNE', 'LEVER_MAINTAIN_DUNE', 'LEVER_Us_out_COAST_and_RISK_AREA',
								  'LEVER_Us_in_COAST_AREA', 'LEVER_Us_in_RISK_AREA', 'LEVER_INLAND_DIKE',
								  'LEVER_NO_DIKE_CREATION', 'LEVER_NO_DIKE_RAISE', 'LEVER_NO_DIKE_REPAIR', 'LEVER_A_to_N_in_COAST_or_RISK_AREA',
								  'LEVER_DENSIFICATION_out_COAST_and_RISK_AREA', 'LEVER_EXPROPRIATION', 'LEVER_DESTROY_DIKE','LEVER_GIVE_PEBBLES'];
	bool save_data <- false; // whether save or not data logs 
	
	list<list<int>> districts_budgets <- [[],[],[],[]];
	list<list<int>> districts_populations <- [[],[],[],[]];
	Action_Name last_updated <- nil;
	
	int plan_project_duration <- 5;
	float plan_risk_agency_rate <- 0.3;
	int plan_current_partition_index <- 0;
	list<float> plan_current_partition<- [0.25,0.25,0.25,0.25];
	list<int> plan_project_amounts <- [2000,2000,2000,2000];
	list<int> plan_contributions <- [0,0,0,0];
	list<int> plan_finances <- [0,0,0,0];
	list<int> plan_balances <- [0,0,0,0];
	bool send_my_plan <- false;
	
	init{
		MSG_CHOOSE_MSG_TO_SEND 	<- get_message('MSG_CHOOSE_MSG_TO_SEND');
		MSG_TYPE_CUSTOMIZED_MSG <- get_message('MSG_TYPE_CUSTOMIZED_MSG');
		MSG_TO_CANCEL 			<- get_message('MSG_TO_CANCEL');
		MSG_AMOUNT 				<- get_message('MSG_AMOUNT');
		MSG_COMMUNE				<- get_message('MSG_COMMUNE');
		MSG_123_OR_CUSTOMIZED 	<- get_message('MSG_123_OR_CUSTOMIZED');
		MSG_EXPROPRIATION		<- get_message('MSG_EXPROPRIATION');
		LEV_MAX					<- get_message('LEV_MAX');
		LEV_AT					<- get_message('LEV_AT');
		LEV_MSG_ACTIONS			<- get_message('LEV_MSG_ACTIONS');
		LDR_MSG_ROUNDS			<- get_message('LDR_MSG_ROUNDS');
		LEV_DUNES				<- get_message('LEV_DUNES');
		LEV_DIKES				<- get_message('LEV_DIKES');
		MSG_ROUND				<- get_message('MSG_ROUND');
		LEV_MSG_LEVER_HELP 		<- get_message('LEV_MSG_LEVER_HELP');
		LDR_TOTAL				<- get_message('LDR_TOTAL');
		MSG_TAXES				<- get_message("MSG_TAXES");
		LDR_GIVEN				<- get_message("LDR_GIVEN");
		LDR_TAKEN				<- get_message("LDR_TAKEN");
		LDR_TRANSFERRED			<- get_message("LDR_TRANSFERRED");
		LEV_MSG_ACTIONS			<- get_message("LEV_MSG_ACTIONS");
		MSG_LEVERS				<- get_message("MSG_LEVERS");
		MSG_BUILDER				<- get_message('MSG_BUILDER');
		MSG_SOFT_DEF			<- get_message('MSG_SOFT_DEF');
		MSG_WITHDRAWAL			<- get_message('MSG_WITHDRAWAL');
		MSG_OTHER				<- get_message("MSG_OTHER");
		LDR_LAST				<- get_message('LDR_LAST');
		
		all_levers <- [Create_Dike_Lever, Raise_Dike_Lever, Repair_Dike_Lever, AU_or_Ui_in_Coast_Area_Lever, AU_or_Ui_in_Risk_Area_Lever,
				Ganivelle_Lever, Enhance_Natural_Accr_Lever, Create_Dune_Lever, Maintain_Dune_Lever, Us_out_Coast_and_Risk_Area_Lever,
				Us_in_Coast_Area_Lever, Us_in_Risk_Area_Lever, Inland_Dike_Lever,
				No_Dike_Creation_Lever, No_Dike_Raise_Lever, No_Dike_Repair_Lever, A_to_N_in_Coast_or_Risk_Area_Lever,
				Densification_out_Coast_and_Risk_Area_Lever, Expropriation_Lever, Destroy_Dike_Lever, Give_Pebbles_Lever];
		
		sim_id <- machine_time;
		create District from: districts_shape with: [district_code::string(read("dist_code")), dist_id::int(read("player_id"))] {
			if dist_id = 0 {
				do die;
			}
			district_name <- dist_code_sname_correspondance_table at district_code;
			district_long_name <- dist_code_lname_correspondance_table at district_code;
			surface <- round(shape.area / 10000);
		}
		int idx <- 1;
		loop kk over: dist_code_sname_correspondance_table.keys {
			add first(District where (each.district_code = kk)) to: districts;
			last(districts).dist_id <- idx;
			idx <- idx + 1;
		}
		 
		do create_district_buttons_names;
		do create_levers;
		do create_player_buttons;
		do create_actions_counters;
		create Network_Leader;
		create Lever_Window_Info;
		create Lever_Window_Actions;
		create Player_Button_Actions;
		do create_financial_plan;
	}
	//------------------------------ end of init -------------------------------//
	
	action create_district_buttons_names{
		loop i from: 0 to: 3 {
			create District_Name {
				display_name <- districts[i].district_long_name;
				location	 <- (Grille grid_at {i,0}).location - {0,1.5};
			}
			create District_Action_Button {
				command 	 <- EXCHANGE_MONEY;
				display_name <- world.get_message("LDR_EXCHANGE_MONEY");
				location	 <- (Grille[i,1]).location - {0,7.25};
				my_district  <- districts[i];
			}
			create District_Action_Button {
				command 	 <- GIVE_MONEY_TO;
				display_name <- world.get_message("LDR_MSG_SEND_MONEY");
				location	 <- (Grille[i,1]).location - {0,4.25};
				my_district  <- districts[i];
			}
			create District_Action_Button {
				command 	 <- TAKE_MONEY_FROM;
				display_name <- world.get_message("LDR_MSG_WITHDRAW_MONEY");
				location	 <- (Grille[i,1]).location - {0,1.25};
				my_district  <- districts[i];
			}
			create District_Action_Button {
				command 	 <- SEND_MESSAGE_TO;
				display_name <- world.get_message("LDR_MSG_SEND_MSG");
				location	 <- (Grille[i,1]).location + {0,1.75};
				my_district  <- districts[i];
			}
		}
	}
	
	action create_levers {
		int filter <- GRID_H - 11;
		loop i from: 0 to: 3{
			loop j from: 0 to: length(levers_def) - 1{
				if (string((levers_def.values[j]) at 'active') at i) = '1'{ // the lever is activated on this district
					create all_levers at (levers_names index_of levers_def.keys[j]){
						my_district <- districts[i];
						col_index <- i;
						row_index <- int(j/2 + 2);
						location <- (Grille[col_index, row_index]).location - {0, 3 + (-4.5 * j mod 2) + (0.33 * filter * j mod 2)};
						add self to: my_district.levers;
					}
				}
			}
		}
	}
	
	action create_actions_counters {
		string act;
		int lu_index;
		int codef_index;
		list<string> all_actions <- [];
		loop i from: 0 to: length(data_action) - 1 {
			act <- data_action.keys[i];
			lu_index <- int(data_action at act at 'lu_index');
			codef_index <- int(data_action at act at 'coast_def_index');
			if codef_index >= 0 or  lu_index >= 0 {
				int act_code <- int(data_action at act at 'action_code');
				create Action_Name {
					action_code	<- act_code;
					action_name <- world.label_of_action(act_code);
					col <- string(data_action at act at 'entity') = "COAST_DEF" ? #lightgray : #whitesmoke;
					origi_color <- col;
					location <- (Grille2[0, 1]).location + {1.5, 5.25 * i};
				}
				ask districts {
					create District_Name2 {
						display_name <- myself.district_name;
						location <- (Grille2[myself.dist_id, 0]).location  - {0,1.5};
					}					
					if (string(data_action at act at 'active') at (dist_id-1)) = '1'{
						create Action_Counter {
							my_district <- myself;
							location <- (Grille2[my_district.dist_id, 1]).location + {2, 5.25 * i};
							action_code	<- act_code;
						}	
					}
				}
			} 
		}
		last_updated <- first(Action_Name);
	}
	
	action create_player_buttons {
		string act_name;
		int lu_index;
		int codef_index;
		map<int,string> codef_actions <- [];
		map<int,string> lu_actions <- [];
		loop i from: 0 to: length(data_action) - 1 {
			act_name <- data_action.keys[i];
			lu_index <- int(data_action at act_name at 'lu_index') - 1;
			codef_index <- int(data_action at act_name at 'coast_def_index') - 1;
			if codef_index >= 0 {
				put act_name in: codef_actions key: codef_index;
			} else if lu_index >= 0 {
				put act_name in: lu_actions key: lu_index;
			}
		}
		// saving the same order of buttons as in the player interface
		list<string> all_actions <- codef_actions.values + lu_actions.values;
		loop j from: 0 to: length(codef_actions)-1 {
			all_actions[codef_actions.keys[j]] <- codef_actions at codef_actions.keys[j];
		}
		int cda <- length(codef_actions);
		loop j from: cda to: length(all_actions)-1 {
			all_actions[lu_actions.keys[j-cda]+cda] <- lu_actions at lu_actions.keys[j-cda];
		}
		int i <- 0;
		loop ac over: all_actions {
			ask districts {
				if (string(data_action at ac at 'active') at (dist_id-1)) = '1'{
					create Player_Button {
						my_district <- myself;
						action_name  <- ac;
						location <- (Grille[my_district.dist_id - 1, 1]).location + {0, 6 * i};
						command	<- int(data_action at action_name at 'action_code');
						label <- world.label_of_action(command);
						my_icon <- image_file(data_action at action_name at 'button_icon_file') ;
					}	
				}
			}
			i <- i + 1;
		}
	}
	
	action record_leader_activity (string msg_type, string d, string msg){
		string aText <- "<" + string (current_date.hour) + ":" + current_date.minute + ">" + msg_type + " " + d + " -> " + msg;
		write aText;
		add ("<" + machine_time + ">" + aText) to: leader_activities;
	}
	
	action save_leader_data{
		int num_round <- game_round;
		if length(leader_activities) > 0 {
			loop a over: leader_activities {
				save a to: records_folder + "leader_data-" + sim_id + "/leader_activities_round" + num_round + ".txt" type: "text" rewrite: false;
			}
			leader_activities <- [];
		}
		if length(player_actions) > 0 {
			loop pa over: player_actions {
				save pa to: records_folder + "leader_data-" + sim_id + "/player_actions_round" + num_round + ".csv" type: "csv" rewrite: false;
			}
			player_actions <- [];
		}
		if length(activated_levers) > 0 {
			loop al over: activated_levers {
				save al to: records_folder + "leader_data-" + sim_id + "/activated_levers_round" + num_round + ".csv" type: "csv" rewrite: false;
			}
			activated_levers <- [];
		} 
		loop a over: (all_levers accumulate (each.population) sort_by (each.my_district.dist_id)) {
			save a to: records_folder + "leader_data-" + sim_id + "/all_levers_round" + num_round + ".csv"  type: "csv" rewrite: false;
		}
	}

	action user_buttons_click{
		point loc <- #user_location;
		Player_Button but <- (Player_Button) first_with (each overlaps loc);
		if but != nil and clicked_pButton = nil {
			clicked_pButton <- but;
		} else {
			Player_Button_Button but <- (Player_Button_Button) first_with (each overlaps loc);
			if but != nil {
				switch but.command {
					match clicked_pButton.state { // clicked button has already that state
						return; 
					}
					match 3 {
						clicked_pButton <- nil;
					}
					default {
						ask clicked_pButton {
							state <- but.command;
							map<string, unknown> msg <-[];
							put 'TOGGLE_BUTTON' 	key: LEADER_COMMAND in: msg;
							put my_district.district_code	key: DISTRICT_CODE 	in: msg;
							put command				key: "COMMAND"	 	in: msg;
							put state				key: "STATE"	 	in: msg;
							ask world {
								do send_message_from_leader(msg);
								do record_leader_activity("Button " + myself.label + (myself.state = B_ACTIVATED ? " enabled" : (myself.state = B_DEACTIVATED ? " disabled" : " invisible")) + " at", myself.my_district.district_name, " at round " + game_round);
							}
						}
						clicked_pButton <- nil;
					}		
				}	
			}
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
						if species(selected_lever) != Give_Pebbles_Lever {
							ask selected_lever { do change_lever_threshold_value; }
							selected_lever <- nil;
						}
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
	
	rgb color_profile (string prof){
		switch prof {
			match BUILDER 		{ return #deepskyblue;}
			match SOFT_DEFENSE	{ return #lightgreen; }
			match WITHDRAWAL	{ return #moccasin;	  }
			default 			{ return #red;		  }
		}
	}
	
	string color_profile_num (int num){
		return num = 0 ? BUILDER : (num = 1 ? SOFT_DEFENSE : WITHDRAWAL);
	}
	
	action create_financial_plan {
		loop i from: 0 to: 3 {
			F_Plan_Grid[i+1,0].col <- #deepskyblue;
			F_Plan_Grid[i+1,0].text <- districts[i].district_name + " :";
		}
		F_Plan_Grid[0,1].text <- world.get_message("MSG_POPULATION") + " :";
		F_Plan_Grid[0,2].text <- world.get_message("MSG_BUDGETS") + " :";
		F_Plan_Grid[0,3].text <- world.get_message("MSG_SURFACE") + " :";
		
		F_Plan_Grid[0,6].text <-  world.get_message("PLAN_CHOSEN_R") + " :";
		loop i from: 0 to: 3 {
			F_Plan_Grid[i+1,6].col <- #moccasin;
			F_Plan_Grid[i+1,6].text <- "25%";
		}
		
		F_Plan_Grid[0,8].text <- world.get_message("PLAN_AMOUNT_P") + " :";
		loop i from: 0 to: 3 {
			F_Plan_Grid[i+1,8].col <- #moccasin;
			F_Plan_Grid[i+1,8].text <- ""+plan_project_amounts[i];
		}
		
		F_Plan_Grid[0,11].text <- world.get_message("PLAN_DURATION_P") + " :";
		F_Plan_Grid[1,11].text <- ""+plan_project_duration;
		F_Plan_Grid[1,11].col <- #moccasin;
		F_Plan_Grid[2,11].text <- world.get_message("PLAN_PER100_LEADER") + " :";
		F_Plan_Grid[3,11].text <- "" + plan_risk_agency_rate * 100 + "%";
		F_Plan_Grid[3,11].col <- #moccasin;
		F_Plan_Grid[0,13].text <- world.get_message("PLAN_ANNUAL_C") + " :";
		loop i from: 1 to: 4 {
			F_Plan_Grid[i,13].text <- ""+plan_contributions[i-1];
		}
		F_Plan_Grid[0,14].text <- world.get_message("PLAN_ANNUAL_F") + " :";
		loop i from: 1 to: 4 {
			F_Plan_Grid[i,14].text <- ""+plan_finances[i-1];
		}
		F_Plan_Grid[0,15].text <- world.get_message("PLAN_ANNUAL_S") + " :";
		loop i from: 1 to: 4 {
			F_Plan_Grid[i,15].text <- ""+plan_balances[i-1];
			F_Plan_Grid[i,15].col <- #lightgreen;
		}
		
		create plan_Button {
			command <- 0;
			_name <- world.get_message("PLAN_EGAL");
			loc <- F_Plan_Grid[1,5].location;
		}
		create plan_Button {
			command <- 1;
			_name <- world.get_message("PLAN_POPUL");
			loc <- F_Plan_Grid[2,5].location;
		}
		create plan_Button {
			command <- 2;
			_name <- world.get_message("PLAN_BUDGET");
			loc <- F_Plan_Grid[3,5].location;
		}
		create plan_Button {
			command <- 3;
			_name <- world.get_message("PLAN_SURFACE");
			loc <- F_Plan_Grid[4,5].location;
		}
		
		create plan_Button {
			command <- 4;
			_name <- world.get_message("PLAN_AMOUNTS");
			loc <- F_Plan_Grid[2,9].location;
		}
		create plan_Button {
			col <- #orange;
			command <- 5;
			_name <- world.get_message('PLAN_TIME_PER100');
			loc <- F_Plan_Grid[4,11].location; 
		}
		create plan_Button {
			command <- 6;
			col <- #lightgreen;
			_name <- world.get_message("PLAN_VALIDATE");
			loc <- F_Plan_Grid[2,17].location; 
		}
		
		loop i from: 0 to: 3 {
			F_Plan_Grid[i+1,3].text <- ""+ districts[i].surface;
		}
	}
	
	action init_plan_budget {
		loop i from: 0 to: 3 {
			districts[i].initial_budget <- first(districts_budgets[i]);
			F_Plan_Grid[i+1,2].text <- "" + districts[i].initial_budget;
		}
	}
	
	action update_paritionning (int ix) {
		ask plan_Button where (each.command = plan_current_partition_index) { col <- #yellow; }
		ask plan_Button where (each.command = ix) { col <- #red; }
		plan_current_partition_index <- ix;
		loop i from: 0 to: 3 {
			F_Plan_Grid[i+1,6].text <- ""+ 100 * plan_current_partition[i] + "%";
		}
		do update_plan;
	}
	
	action update_plan{
		float paid_by_ditrict <- (sum (plan_project_amounts) * (1 - plan_risk_agency_rate)) / max([plan_project_duration,1]);
		loop i from: 0 to: 3 {
			plan_contributions [i] <- paid_by_ditrict * plan_current_partition [i];
			plan_finances [i] <- plan_project_amounts [i] / max([plan_project_duration,1]);
			plan_balances [i] <- plan_finances[i] - plan_contributions[i];
			
			F_Plan_Grid[i+1,13].text <- ""+plan_contributions[i];
			F_Plan_Grid[i+1,14].text <- ""+plan_finances[i];
			F_Plan_Grid[i+1,15].text <- ""+plan_balances[i];
		}
	}
	
	action update_plan_populations {
		loop i from: 0 to: 3 {
			F_Plan_Grid[i+1,1].text <- "" + districts[i].population;
		}
	}
	
	action send_one_year_plan {
		if plan_project_duration > 0 {
			plan_project_duration <- plan_project_duration - 1;
			map<string, unknown> msg 	<-[];
			string msg_player <- "";
			int amount_value <- 0;
			loop i from: 0 to: 3 {
				amount_value <- plan_balances [i];
				put districts[i].district_code	key: DISTRICT_CODE in: msg;
				if amount_value < 0 { // prélever
					amount_value <- abs(amount_value);
					put TAKE_MONEY_FROM 	key: LEADER_COMMAND 	in: msg;
					msg_player <- LDR_TAKEN;
					districts[i].taken_money <- districts[i].taken_money - amount_value;
				} else { // donner
					put GIVE_MONEY_TO 	key: LEADER_COMMAND 	in: msg;
					msg_player <- LDR_GIVEN;
					districts[i].given_money <- districts[i].given_money + amount_value;
				}
				put amount_value	key: AMOUNT		in: msg;
				put world.get_message("PLAN_PLAN") + " / " + msg_player	key: MSG_TO_PLAYER	in: msg;
				do send_message_from_leader(msg);
				do record_leader_activity ("Interdistrict financial plan", districts[i].district_name, msg_player + " : " + amount_value + " By");
			}
		}else {
			send_my_plan <- false;
		}
	}
	
	action plan_buttons_click{
		if send_my_plan { return; }
		point loc <- #user_location;
		plan_Button but <- (plan_Button) first_with (each overlaps loc);
		if but != nil {
			switch but.command {
				match 0 {
					loop i from: 0 to: 3 {
						plan_current_partition [i] <- 0.25;
					}
					do update_paritionning (0);
				}
				match 1 {
					loop i from: 0 to: 3 {
						plan_current_partition [i] <- (districts[i].population / max([1, districts sum_of (each.population)])) with_precision 2;
					}
					do update_paritionning (1);
				}
				match 2 {
					loop i from: 0 to: 3 {
						plan_current_partition [i]  <- (districts[i].initial_budget / max([1, districts sum_of (each.initial_budget)])) with_precision 2;
					}
					do update_paritionning (2);
				}
				match 3 {
					loop i from: 0 to: 3 {
						plan_current_partition [i] <-  (districts[i].surface / max([1, districts sum_of (each.surface)])) with_precision 2;
					}
					do update_paritionning (3);
				}
				match 4 {
					map mpp <- user_input(world.get_message("PLAN_AMOUNT_P") + " :",
					[districts[0].district_name::plan_project_amounts [0], districts[1].district_name::plan_project_amounts [1],
							districts[2].district_name::plan_project_amounts [2], districts[3].district_name::plan_project_amounts [3]]);
					loop ix from: 0 to: 3 {
						plan_project_amounts [ix] <- int(mpp at districts[ix].district_name);
						F_Plan_Grid[ix+1,8].text <- ""+plan_project_amounts[ix];
					}
					do update_plan;	
				}
				match 5 {
					map mpp <- user_input(world.get_message("PLAN_DURATION_P") + " + " + world.get_message("PLAN_PER100_LEADER") + " :",
					["Durée"::plan_project_duration, "Contribution"::plan_risk_agency_rate]);
					plan_project_duration <- int(mpp at "Durée");
					plan_risk_agency_rate <- float(mpp at "Contribution");
					F_Plan_Grid[1,11].text <- ""+plan_project_duration;
					F_Plan_Grid[3,11].text <- ""+plan_risk_agency_rate  * 100 + "%";
					do update_plan;	
				}
				match 6 {
					map<string,bool> vmap <- map<string,bool>(user_input(world.get_message("MSG_WARNING"), world.get_message("PLAN_CONFIRM") + " ?"::false));
					if(vmap at vmap.keys[0]){
						send_my_plan <- true;
						do send_one_year_plan;
					}
				}
			}
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
	
	string action_type 		<- ""; 					// COAST_DEF or LU
	string previous_lu_name <- "";  				// for LU action
	bool is_expropriation 	<- false; 				// for LU action
	bool is_in_protected_area 	<- false; 			// for COAST_DEF action
	bool is_in_coast_area 	<- false; 
	bool is_in_risk_area 	<- false; 				// for LU action
	bool is_inland_dike 	<- false; 				// for COAST_DEF (retro dikes)
	string strategy_profile	<- "";
	int length_coast_def;
	list<Activated_Lever> activated_levers 	<-[];
	bool should_wait_lever_to_activate 		<- false;
	bool a_lever_has_been_applied			<- false;
	list<int> previous_activated_levers <- [];
	bool already_impacted <- false; // to prevent that an action be impacted by two levers
	
	string get_strategy_profile {
		District dd <- first(District where(each.district_code = self.district_code));
		if action_type = PLAYER_ACTION_TYPE_COAST_DEF {
			if is_inland_dike {
				return dd.is_builder ? SOFT_DEFENSE : WITHDRAWAL;
			}
			else{
				switch command {
					match_one [ACTION_CREATE_DIKE, ACTION_RAISE_DIKE, ACTION_REPAIR_DIKE] { return BUILDER; }
					match_one [ACTION_CREATE_DUNE, ACTION_ENHANCE_NATURAL_ACCR, ACTION_MAINTAIN_DUNE,
								ACTION_INSTALL_GANIVELLE, ACTION_LOAD_PEBBLES_CORD] { return SOFT_DEFENSE; }
					match ACTION_DESTROY_DIKE	{ return WITHDRAWAL; }
				}
			}
		}else {
			if is_expropriation { return WITHDRAWAL; }
			else {
				switch command {
					match_one [ACTION_MODIFY_LAND_COVER_AU, ACTION_MODIFY_LAND_COVER_Ui]   {
						if is_in_coast_area or is_in_risk_area {
							return BUILDER;	
						} else if dd.is_withdrawal { return WITHDRAWAL; }
					}
					match_one [ACTION_MODIFY_LAND_COVER_AUs, ACTION_MODIFY_LAND_COVER_Us] {
						return SOFT_DEFENSE;
					}
					match ACTION_MODIFY_LAND_COVER_A {
						if previous_lu_name = 'N' and is_in_risk_area { return BUILDER; }
					}
					match ACTION_MODIFY_LAND_COVER_N {
						if previous_lu_name = 'A'{
							if is_in_risk_area or (is_in_coast_area and dd.is_withdrawal) {
								return WITHDRAWAL;
							} else {
								return SOFT_DEFENSE;
							}			
						} else if previous_lu_name = 'AU'{
							return WITHDRAWAL;
						}
					}
				}
			}
		}
		return OTHER;
	}
	
	action init_action_from_map (map<string, string> a ){
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
		self.is_in_coast_area 	<- bool(a at "is_in_coast_border_area");
		self.is_in_risk_area 			<- bool(a at "is_in_risk_area");
		self.is_inland_dike 			<- bool(a at "is_inland_dike");
		self.command_round 				<- int(a at "command_round");
		self.strategy_profile 			<- a at STRATEGY_PROFILE;
		self.length_coast_def 			<- int(a at "length_coast_def");
		self.a_lever_has_been_applied 	<- bool(a at "a_lever_has_been_applied");
		
		self.previous_activated_levers <- eval_gaml(a["activ_levs"]);
	}
}
//------------------------------ End of Player_Action -------------------------------//

species District{
	int dist_id;
	string district_code;
	string district_name;
	string district_long_name;
	int initial_budget <- 0;
	int budget <- -1;
	int population <- 0;
	int surface <- 0;
	bool is_builder -> {builder_score >= PROFILING_THRESHOLD};
	bool is_soft_def -> {soft_def_score >= PROFILING_THRESHOLD};
	bool is_withdrawal -> {withdrawal_score >= PROFILING_THRESHOLD};
	list<Lever> levers;
	list<Player_Button> buttons;
	
	float builder_score <- 0.0;
	float soft_def_score <- 0.0;
	float withdrawal_score <- 0.0;
		
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
	int length_created_dikes 						<- 0;
	int length_created_dunes 						<- 0;
	int length_raised_dikes 						<- 0;
	int length_repaired_dikes 						<- 0;
	int length_destroyed_dikes 						<-0 ;
	int length_inland_dikes							<- 0;
	int length_created_ganivelles 					<- 0;
	int length_enhanced_accretion 					<- 0;
	int length_maintained_dunes 					<- 0;
	int count_Us 									<- 0;
	int count_expropriation							<- 0;
	int count_Us_in_risk_area						<- 0;
	int count_AU_or_Ui_in_coast_area 				<- 0;
	int count_AU_or_Ui_in_risk_area 				<- 0;
	int count_Us_out_coast_or_risk_area				<- 0;
	int count_Us_in_coast_area						<- 0;					
	int count_A_to_N_in_coast_or_risk_area			<- 0;
	int count_densification_out_coast_and_risk_area	<- 0;
	
	int received_tax <- 0;
	int actions_cost <- 0;
	int given_money  <- 0;
	int taken_money  <- 0;
	int levers_cost  <- 0;
	int transferred_money <- 0;
		
	int build_cost 	<- 0;
	int soft_cost 	<- 0;
	int withdraw_cost <- 0;
	int other_cost  <- 0;
	
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
			match ACTION_ENHANCE_NATURAL_ACCR {
				length_enhanced_accretion <- length_enhanced_accretion + act.length_coast_def;
				ask Enhance_Natural_Accr_Lever where(each.my_district = self) { do register_and_check_activation(act); }
			}
			match ACTION_CREATE_DUNE {
				length_created_dunes <- length_created_dunes + act.length_coast_def;
				ask Create_Dune_Lever where(each.my_district = self) { do register_and_check_activation(act);	}
			}
			match ACTION_MAINTAIN_DUNE {
				length_maintained_dunes <- length_maintained_dunes + act.length_coast_def;
				ask Maintain_Dune_Lever where(each.my_district = self) { do register_and_check_activation(act); }
			}
			match_one [ACTION_MODIFY_LAND_COVER_Us, ACTION_MODIFY_LAND_COVER_AUs] {
				count_Us <- count_Us +1;
				if !act.is_in_risk_area and !act.is_in_coast_area {
					count_Us_out_coast_or_risk_area <- count_Us_out_coast_or_risk_area +1;
					ask Us_out_Coast_and_Risk_Area_Lever where(each.my_district = self) { do register_and_check_activation(act); }
				} else{
					if act.is_in_coast_area {
					count_Us_in_coast_area <- count_Us_in_coast_area +1;
					ask Us_in_Coast_Area_Lever where(each.my_district = self) { do register_and_check_activation(act); }
					}
					if act.is_in_risk_area {
						count_Us_in_risk_area <- count_Us_in_risk_area +1;
						ask Us_in_Risk_Area_Lever where(each.my_district = self) { do register_and_check_activation(act); }
					}
				}
			}
			match ACTION_MODIFY_LAND_COVER_N {
				if act.previous_lu_name = "A" and (act.is_in_coast_area or act.is_in_risk_area) {
					count_A_to_N_in_coast_or_risk_area <- count_A_to_N_in_coast_or_risk_area + 1;
					ask A_to_N_in_Coast_or_Risk_Area_Lever where(each.my_district = self) {
						do check_activation_and_impact_on_first_element_of(myself.get_impacted_actions_by_profile(act.strategy_profile));
						do register (act);
					}
				}
			}
			match_one [ACTION_MODIFY_LAND_COVER_Ui, ACTION_MODIFY_LAND_COVER_AU] {
				if act.command = ACTION_MODIFY_LAND_COVER_Ui and !act.is_in_coast_area and !act.is_in_risk_area {
					if is_withdrawal {
						count_densification_out_coast_and_risk_area <- count_densification_out_coast_and_risk_area + 1;
						ask Densification_out_Coast_and_Risk_Area_Lever where(each.my_district = self) { do register_and_check_activation (act); }	
					}
				}
				else{
					if act.is_in_coast_area and act.previous_lu_name != "Us"{
						count_AU_or_Ui_in_coast_area <- count_AU_or_Ui_in_coast_area + 1;
						ask AU_or_Ui_in_Coast_Area_Lever where(each.my_district = self) { do register_and_check_activation(act); }
					}
					if act.is_in_risk_area {
						count_AU_or_Ui_in_risk_area <- count_AU_or_Ui_in_risk_area + 1;
						ask AU_or_Ui_in_Risk_Area_Lever where(each.my_district = self) { do register_and_check_activation(act); }
					}	
				}
			}
		}
	}
	
	action calculate_scores (int ref_round) {
		// updating player profile scores : only player actions of current and previous rounds
		list<Player_Action> pacts <- Player_Action where (each.district_code = district_code and each.command_round in [ref_round, ref_round-1]);
		builder_score <- float(sum(pacts where (each.strategy_profile = BUILDER) collect (each.cost)));
		soft_def_score <- float(sum(pacts where (each.strategy_profile = SOFT_DEFENSE) collect (each.cost)));
		withdrawal_score <- float(sum(pacts where (each.strategy_profile = WITHDRAWAL) collect (each.cost)));
		float tot_score <- max([1,builder_score + soft_def_score + withdrawal_score]);
		builder_score <- (builder_score / tot_score) with_precision 2;
		soft_def_score <- (soft_def_score / tot_score) with_precision 2;
		withdrawal_score <- (withdrawal_score / tot_score) with_precision 2;
	}
	
	list<Player_Action> get_impacted_actions_by_profile (string prof) {
		if (prof = WITHDRAWAL and !is_withdrawal) or (prof = SOFT_DEFENSE and !is_soft_def) { return [];}
		list<Lever> levs <- all_levers accumulate each.population where (each.my_district = self);
		if length(levs) > 0 {
			return distinct(levs accumulate each.associated_actions where (each.strategy_profile = prof and !each.already_impacted)) sort_by (-each.command_round);
		}
		return [];
	}
	
	list<Player_Action> get_impacted_soft_def_withraw_actions {
		list<Player_Action> impactions <- [];
		if !is_builder {
			impactions <- get_impacted_actions_by_profile(SOFT_DEFENSE);
			impactions <- impactions + get_impacted_actions_by_profile(WITHDRAWAL);
		}
		return impactions sort_by (-each.command_round);
	}
}
//------------------------------ End of District -------------------------------//

species Activated_Lever {
	Player_Action p_action;
	float activation_time;
	bool applied <- false;
	
	//attributes sent through network
	string name <- "";
	int id <- length(Activated_Lever);
	string district_code <- "";
	string lever_name <- "";
	string lever_explanation <- "";
	int added_delay <- 0;
	float added_cost <- 0.0;
	int round_creation <- 0;
	int round_application <- 0;
	
	map<string,string> build_lev_map_from_attributes{
		map<string,string> res <- [
			"OBJECT_TYPE"::OBJECT_TYPE_ACTIVATED_LEVER,
			"id"::id,
			"name"::name,
			"lever_name"::lever_name,
			(DISTRICT_CODE)::district_code,
			"p_action_id"::p_action.id,
			"added_cost"::added_cost,
			"added_delay"::added_delay,
			"lever_explanation"::lever_explanation,
			"round_creation"::round_creation,
			"round_application"::round_application,
			"applied"::applied];
		return res;
	}
}
//------------------------------ End of Activated_Lever -------------------------------//

species Player_Button {
	string action_name;
	geometry shape <- rectangle (20, 5);
	int command;
	string label;
	image_file my_icon;
	int state <- B_ACTIVATED;
	District my_district;
	
	aspect {
		draw shape color: state = B_ACTIVATED ? #lightblue : (state = B_DEACTIVATED ? #indianred : #gray) border: #black;
		draw my_icon size: {4,4} at: location - {10,0};
		draw label at: location anchor: #center font: font("Arial", 12 , #bold) color: #black;
	}
	
}

species Player_Button_Actions {
	point loca <- world.location;
	geometry shape <- rectangle(25, 27);
	
	list<string> text_buttons <- ['LDR_ACTIVATE','LDR_DEACTIVATE','LDR_HIDE','LEV_CLOSE_WINDOW'];
	
	init {
		point lo <- loca - {1, 7.5};
		loop i from: 0 to: 3 {
			create Player_Button_Button {
				command <- i ;
				text <- world.get_message(myself.text_buttons[i]);	
				loca <- lo + {1, 1 + (i * 5.5)};
				if i = 3 {	col <- #red; }
			}
		}
	}
	
	aspect {
		if clicked_pButton != nil {
			draw shape color: #white border: #black at: loca;
			draw clicked_pButton.label at: loca - {0,11} anchor: #center font: font("Arial", 13 , #bold) color: #darkblue;
		}
	}
}

species Player_Button_Button {
	int command;
	string text;
	point loca;
	rgb col <- #yellow;
	geometry shape <- rectangle(15#m, 5#m);
	
	aspect {
		if clicked_pButton != nil {
			draw shape color: col border: #black at: loca;
			draw text font: font("Arial", 12 , #bold) color: #darkblue at: loca anchor: #center;
		}
	}
}

species Action_Name {
	int action_code;
	string action_name;
	geometry shape <- rectangle (22, 5);
	rgb col;
	rgb origi_color;
	
	aspect {
		draw shape color: col border: #black;
		draw action_name at: location anchor: #center font: font("Arial", 12 , #bold) color: #black;
	}
	
}

species Action_Counter {
	int action_code;
	list<int> action_count_by_profile <- [0,0,0];
	geometry shape <- rectangle (15, 5);
	District my_district;
	rgb col <- #whitesmoke;
	
	action add_one(string prof) {
		int ix <- prof = BUILDER ? 0 : (prof = SOFT_DEFENSE ? 1 : 2);
		action_count_by_profile[ix] <- action_count_by_profile[ix] + 1;
		col <- world.color_profile(world.color_profile_num(action_count_by_profile index_of max(action_count_by_profile)));
		ask last_updated {
			col <- origi_color;
		}
		ask first(Action_Name where(each.action_code = action_code)){
			col <- #red;
			last_updated <- self;	
		}
	}
	
	aspect {
		draw shape color: col border: #black;
		draw ""+action_count_by_profile at: location anchor: #center font: font("Arial", 15 , #bold) color: #black;
	}
	
}
//------------------------------ End of Player_Button -------------------------------//

species Lever_Window_Info {
	point loca;
	geometry shape <- rectangle(30#m,15#m);
	
	aspect {
		if explored_lever != nil {
			Lever my_lever <- explored_lever;
			draw shape color: world.color_profile(my_lever.lever_type) at: loca;
			draw 0.5 around shape color: #black;
			
			if my_lever.timer_activated {
				draw shape+0.2#m color: #red;
			}
			
			draw my_lever.box_title at: loca - {0,4} anchor: #center font: font("Arial", 12 , #bold) color: #black;
			draw my_lever.progression_bar at: loca - {0, 2} anchor: #center font: font("Arial", 12 , #plain) color: my_lever.threshold_reached ? #red : #black;
			
			if my_lever.timer_activated {
				draw string(my_lever.remaining_seconds()) + " s " + (length(my_lever.activation_queue) = 1 ? "" : "(" + 
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
			Lever selev <- selected_lever;
			draw shape color: #white border: #black at: loca;
			draw selev.box_title at: loca - {0,27.5} anchor: #center font: font("Arial", 13 , #bold) color: #darkblue;
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
			Lever selev <- selected_lever;
			draw shape color: col border: #black at: loca;
			draw text font: font("Arial", 12 , #bold) color: #darkblue at: loca anchor: #center;
			if command in [3,4,5,6] and (!selev.status_on or !selev.timer_activated) or
			   (species(selev) = Give_Pebbles_Lever and command in [1,3,4,5,6])
			{
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
	int timer_duration 		 	<- 120000;	// 1 minute = 60000 milliseconds //   2 mn = 120000
	string lever_type		 	<-	"";
	string lever_name		 	<-	"";
	string box_title 		 	-> {lever_name + ' (' + length(associated_actions) + ')'};
	string progression_bar		<-	"";
	string lever_help_msg 	 	<-	"";
	string activation_label_L1	<-	"";
	string activation_label_L2	<-	"";
	string player_msg;
	int row_index;
	int col_index;
	list<Player_Action>   associated_actions;
	list<Activated_Lever> activation_queue;
	list<Activated_Lever> activated_levers;
	
	init {
		shape <- rectangle (24.5, 4.25 - (0.3 * (GRID_H - 11)));
	}
	
	aspect default{
		if timer_activated {
			draw shape+0.2#m color: #red;
		}
		
		draw shape color: world.color_profile(lever_type) border: #black at: location;
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
				p_action.already_impacted <- true;
				do queue_activated_lever (p_action);
			}
			else{ threshold_reached <- false; }	
		}
	}	
	
	action check_activation_and_impact_on_first_element_of (list<Player_Action> list_p_action){
		if list_p_action = nil { return; }
		if !empty(list_p_action){
			do check_activation_and_impact_on (list_p_action[0]);
		}
	}
	
	action queue_activated_lever(Player_Action a_p_action){
		create Activated_Lever returns: act_levs{
			lever_name 		<- myself.lever_name;
			district_code 	<- myself.my_district.district_code;
			self.p_action 	<- a_p_action;
			activation_time <- machine_time + myself.timer_duration ;
			round_creation 	<- game_round;
			add self to: activated_levers;
		}
		ask first(act_levs) {
			if id in a_p_action.previous_activated_levers { // Leader restarted, this lever is already applied
				applied <- true;
			} else {
				if added_delay != 0 {
					p_action.should_wait_lever_to_activate <- true;
					ask myself {
						do inform_network_should_wait_lever_to_activate(a_p_action, myself);
					}
				}
				add self to: myself.activation_queue;
				string diss <- myself.my_district.district_name;
				ask world {
					do record_leader_activity("Lever " + myself.lever_name + " programmed at", diss, a_p_action.label + "(" + a_p_action + ")");
				}
			}
		}
	}

	action toggle_status {
		status_on <- !status_on ;
		if !status_on { activation_queue <-[]; }
		if species(selected_lever) = Give_Pebbles_Lever {
			map<string, unknown> msg <-[];
			put 'DIEPPE_CRIEL_PEBBLES' 	key: LEADER_COMMAND in: msg;
			put '76192'					key: DISTRICT_CODE 	in: msg; //  to Criel
			put status_on				key: "ALLOWED"	 	in: msg;
			if status_on {
				put (1 + first(Give_Pebbles_Lever).added_cost)		key: "DISCOUNT"		in: msg; 
				create Player_Action returns: pacts {
					add self to: myself.associated_actions;
				}
			}
			ask world { do send_message_from_leader(msg); }
			put '76217'	key: DISTRICT_CODE 	in: msg; // to Dieppe
			ask world {
				do send_message_from_leader(msg);
				do record_leader_activity ("Authorizing Dieppe-Criel pebbles:", "" + myself.status_on, "Transaction number: " + length(myself.associated_actions));		
			}
		}
	}
	
	string get_lever_help_msg {
		return lever_help_msg;
	}
	
	action write_help_lever_msg {
		map values <- user_input(LEV_MSG_LEVER_HELP,
					[get_lever_help_msg()::true, world.get_message('LEV_THRESHOLD_VALUE') + " : " + threshold::true]);
	}
	
	action change_lever_player_msg {
		map values <- user_input(world.get_message('LEV_MSG_SENT_TRIGGER_LEVER'), [world.get_message('LEV_MESSAGE'):: player_msg]);
		string new_msg <- values at values.keys[0];
		if new_msg != "" and new_msg != player_msg {
			player_msg <- new_msg;
			ask world {
				do record_leader_activity("Change lever " + myself.lever_name + " at", myself.my_district.district_name, "The new message sent to the player is : " + myself.player_msg);
			}
		}
	}
	
	action change_lever_threshold_value{
		map values <- user_input(world.replace_strings('LEV_CURRENT_THRESHOLD_LEVER', [lever_name, string(threshold)]), [world.get_message('LEV_NEW_THRESHOLD_VALUE') + " : ":: threshold]); 
		float new_thresh <- float(values at values.keys[0]);
		if new_thresh != threshold {
			threshold <- new_thresh;
			ask world {
				do record_leader_activity("Change lever " + myself.lever_name + " at", myself.my_district.district_name, "The new threshold value is : " + myself.threshold);
			}
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
		do inform_network_should_wait_lever_to_activate(lev.p_action, lev);
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
	
	action inform_network_should_wait_lever_to_activate(Player_Action p_action, Activated_Lever al){
		map<string, unknown> msg <-[];
		put ACTION_SHOULD_WAIT_LEVER_TO_ACTIVATE 	key: LEADER_COMMAND 						in: msg;
		put my_district.district_code 			 	key: DISTRICT_CODE  						in: msg;
		put p_action.id 						 	key: PLAYER_ACTION_ID 						in: msg;
		put al.id 						 			key: "lever_id"		 						in: msg;
		put p_action.should_wait_lever_to_activate  key: ACTION_SHOULD_WAIT_LEVER_TO_ACTIVATE 	in: msg;
		ask world { do send_message_from_leader(msg); }
	}
	
	action send_lever_message (Activated_Lever lev) {
		map<string, unknown> msg <- lev.build_lev_map_from_attributes();
		put NEW_ACTIVATED_LEVER 	key: LEADER_COMMAND in: msg;
		ask world { do send_message_from_leader(msg); }
		int money <- int(msg["added_cost"]);
		ask districts first_with (each.district_code = msg[DISTRICT_CODE]) {
			levers_cost <- levers_cost - money;
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
	float last_lever_cost 	<- 0.0;
	
	action change_lever_cost{
		map values <- user_input(world.replace_strings('LEV_ACTUAL_PERCENTAGE_COST', [lever_name, string(added_cost)]), [world.get_message('LEV_ENTER_THE_NEW') + " :":: added_cost]);
		float n_val <- float(values at values.keys[0]);
		if n_val != added_cost {
			added_cost <- n_val;
			ask world {
				do record_leader_activity("Change lever " + myself.lever_name + " at", myself.my_district.district_name, " The new cost of the lever is : " + myself.added_cost);
			}
		}
	}
	
	string info_of_next_activated_lever {
		return "" + activation_queue[0].p_action.length_coast_def + " m (" + int(activation_queue[0].p_action.cost * added_cost) + ' By)';
	}
	
	action apply_lever(Activated_Lever lev){
		lev.applied 		  <- true;
		lev.round_application <- game_round;
		lev.lever_explanation <- player_msg;
		lev.added_cost 		  <- float(lev.p_action.cost * added_cost);
		do send_lever_message(lev);
		
		last_lever_cost 	<- lev.added_cost;
		activation_label_L1 <- LDR_LAST + " "   + (last_lever_cost >= 0 ? world.get_message('LDR_LEVY') : world.get_message('LDR_PAYMENT')) + " : " + abs(last_lever_cost) + ' By';
		activation_label_L2 <- world.get_message('LDR_TOTAL') + " "  + (last_lever_cost >= 0 ? world.get_message('LDR_TAKEN') : world.get_message('LDR_GIVEN')) + " : " + abs(total_lever_cost()) + ' By';
		ask world {
			do record_leader_activity("Lever " + myself.lever_name + " validated at", myself.my_district.district_name, myself.lever_help_msg + " : " + lev.added_cost + "By" + "(" + lev.p_action + ")");
		}
	}
	
	string get_lever_help_msg {
		return world.replace_strings('LEV_CREATE_DIKE_HELPER', [string(int(100*added_cost))]);
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
		
		if n_val != added_delay {
			added_delay <- n_val;
			ask world {
				do record_leader_activity("Change lever " + myself.lever_name + " at", myself.my_district.district_name, "-> The new rounds number of the lever is : " + myself.added_delay);
			}
		}
	}	
	
	action apply_lever (Activated_Lever lev){
		lev.applied <- true;
		lev.lever_explanation <- player_msg;
		lev.added_delay <- added_delay;
		do send_lever_message;
		
		activation_label_L1 <- (total_lever_delay() < 0 ? world.get_message('LDR_TOTAL_ADVANCE') + ": " : world.get_message('LDR_TOTAL_DELAY') + ": ") + abs(total_lever_delay()) + ' ' + LDR_MSG_ROUNDS;
		lev.p_action.should_wait_lever_to_activate <- false;
		do inform_network_should_wait_lever_to_activate(lev.p_action, lev);
		
		ask world {
			do record_leader_activity(myself.lever_name + " triggered at", myself.my_district.district_name, myself.lever_help_msg + " : " + lev.added_delay + " rounds" + "(" + lev.p_action + ")");
		}
	}
	
	int total_lever_delay {
		return activated_levers sum_of (each.added_delay);
	}
}
//------------------------------ End of Delay_Lever -------------------------------//

species Create_Dike_Lever parent: Cost_Lever {
	float indicator 		-> { my_district.length_dikes_t0 = 0 ? 0.0 : my_district.length_created_dikes / my_district.length_dikes_t0 };
	string progression_bar  -> { "" + my_district.length_created_dikes + " m / " + threshold + " * " + my_district.length_dikes_t0 + " m " +LEV_AT+ " t0"};
	
	init{
		lever_name 		<- world.get_lever_name('LEVER_CREATE_DIKE');
		lever_type		<- world.get_lever_type('LEVER_CREATE_DIKE');
		threshold		<- world.get_lever_threshold('LEVER_CREATE_DIKE');
		added_cost		<- world.get_lever_cost('LEVER_CREATE_DIKE');
		player_msg 		<- world.get_message('LEV_CREATE_DIKE_PLAYER');	
	}
}
//------------------------------ End of Create_Dike_Lever -------------------------------//

species Raise_Dike_Lever parent: Cost_Lever {
	float indicator 		-> { my_district.length_dikes_t0 = 0 ? 0.0 : my_district.length_raised_dikes / my_district.length_dikes_t0 };
	string progression_bar 	-> { "" + my_district.length_raised_dikes + " m / " + threshold + " * " + my_district.length_dikes_t0 + " m " +LEV_AT+ " t0"};
	init{
		lever_name 		<- world.get_lever_name('LEVER_RAISE_DIKE');
		lever_type		<- world.get_lever_type('LEVER_RAISE_DIKE');
		threshold		<- world.get_lever_threshold('LEVER_RAISE_DIKE');
		added_cost		<- world.get_lever_cost('LEVER_RAISE_DIKE');
		player_msg 		<- world.get_message('LEV_CREATE_DIKE_PLAYER');
	}
}
//------------------------------ End of Raise_Dike_Lever -------------------------------//

species Repair_Dike_Lever parent: Cost_Lever{
	float indicator 			-> { my_district.length_dikes_t0 = 0 ? 0.0 : my_district.length_repaired_dikes / my_district.length_dikes_t0 };
	bool should_be_activated 	-> { indicator > threshold and (my_district.length_created_dikes != 0 or my_district.length_raised_dikes != 0)};
	string progression_bar 		-> { "" + my_district.length_repaired_dikes + " m / " + threshold + " * " + my_district.length_dikes_t0 + " m " +LEV_AT+ " t0"};
	
	init{
		lever_name 		<- world.get_lever_name('LEVER_REPAIR_DIKE');
		lever_type		<- world.get_lever_type('LEVER_REPAIR_DIKE');
		threshold		<- world.get_lever_threshold('LEVER_REPAIR_DIKE');
		added_cost		<- world.get_lever_cost('LEVER_REPAIR_DIKE');
		player_msg 		<- world.get_message('LEV_REPAIR_DIKE_PLAYER');
	}
}
//------------------------------ End of Repair_Dike_Lever -------------------------------//

species AU_or_Ui_in_Coast_Area_Lever parent: Delay_Lever{
	int indicator 			-> { my_district.count_AU_or_Ui_in_coast_area};
	string progression_bar 	-> { "" + indicator + " " + LEV_MSG_ACTIONS + " / " + int(threshold) + " " + LEV_MAX};
	
	init{
		lever_name 	<- world.get_lever_name('LEVER_AU_Ui_in_COAST_AREA');
		lever_type	<- world.get_lever_type('LEVER_AU_Ui_in_COAST_AREA');
		threshold	<- world.get_lever_threshold('LEVER_AU_Ui_in_COAST_AREA');
		added_delay	<- world.get_lever_delay('LEVER_AU_Ui_in_COAST_AREA');
		player_msg 	<- world.get_message('LEV_COAST_BORDER_AREA_PLAYER');	
	}
	
	string get_lever_help_msg {
		return world.replace_strings('LEV_COAST_BORDER_AREA_HELPER1', [string(added_delay)]);
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
	string progression_bar 	-> { "" + indicator + " " + LEV_MSG_ACTIONS + " / "+ int(threshold) + " " + LEV_MAX };
	
	init{
		lever_name 	<- world.get_lever_name('LEVER_AU_Ui_in_RISK_AREA');
		lever_type	<- world.get_lever_type('LEVER_AU_Ui_in_RISK_AREA');
		threshold	<- world.get_lever_threshold('LEVER_AU_Ui_in_RISK_AREA');
		added_cost 	<- world.get_lever_cost('LEVER_AU_Ui_in_RISK_AREA');
		player_msg 	<- world.get_message('LEV_REPAIR_DIKE_PLAYER');	
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
		float indicator 			-> { my_district.length_dunes_t0 = 0 ? 0 : my_district.length_created_ganivelles / my_district.length_dunes_t0 };
		string progression_bar 	-> { "" + my_district.length_created_ganivelles + " m / " + threshold + " * " + my_district.length_dunes_t0 + " m " + LEV_DUNES };
	
	init{
		lever_name	<- world.get_lever_name('LEVER_GANIVELLE');
		lever_type	<- world.get_lever_type('LEVER_GANIVELLE');
		threshold	<- world.get_lever_threshold('LEVER_GANIVELLE');
		added_cost 	<- world.get_lever_cost('LEVER_GANIVELLE');
		player_msg 	<- world.get_message('LEV_GANIVELLE_PLAYER');
	}
	
	string get_lever_help_msg {
		return world.get_message('LEV_GANIVELLE_HELPER1') + " " + int(100*added_cost) + "% " + world.get_message('LEV_GANIVELLE_HELPER2') + "/m";
	}
}
//------------------------------ End of Ganivelle_Lever -------------------------------//

species Enhance_Natural_Accr_Lever parent: Cost_Lever {
	float indicator 			-> { my_district.length_dunes_t0 = 0 ? 0 : my_district.length_enhanced_accretion / my_district.length_dunes_t0 };
	string progression_bar 	-> { "" + my_district.length_enhanced_accretion + " m / " + threshold + " * " + my_district.length_dunes_t0 + " m " + LEV_DUNES };
	
	init{
		lever_name	<- world.get_lever_name('LEVER_ENHANCE_NAT_ACCR');
		lever_type	<- world.get_lever_type('LEVER_ENHANCE_NAT_ACCR');
		threshold	<- world.get_lever_threshold('LEVER_ENHANCE_NAT_ACCR');
		added_cost 	<- world.get_lever_cost('LEVER_ENHANCE_NAT_ACCR');
		player_msg 	<- world.get_message('LEV_GANIVELLE_PLAYER');
	}
	
	string get_lever_help_msg {
		return world.get_message('LEV_GANIVELLE_HELPER1') + " " + int(100*added_cost) + "% " + world.get_message('LEV_ACCRETION_HELPER') + "/m";
	}
}
//------------------------------ End of Enhance_Natural_Accr_Lever -------------------------------//

species Create_Dune_Lever parent: Cost_Lever {
	float indicator 		-> { my_district.length_dunes_t0 = 0 ? 0.0 : my_district.length_created_dunes / my_district.length_dunes_t0 };
	string progression_bar  -> { "" + my_district.length_created_dunes + " m / " + threshold + " * " + my_district.length_dunes_t0 + " m " +LEV_AT+ " t0"};
	
	init{
		lever_name 	<- world.get_lever_name('LEVER_CREATE_DUNE');
		lever_type	<- world.get_lever_type('LEVER_CREATE_DUNE');
		player_msg 	<- world.get_message('LEV_GANIVELLE_PLAYER');
		threshold	<- world.get_lever_threshold('LEVER_CREATE_DUNE');
		added_cost 	<- world.get_lever_cost('LEVER_CREATE_DUNE');
	}
	
	string get_lever_help_msg {
		return world.get_message('LEV_GANIVELLE_HELPER1') + " " + int(100*added_cost) + "% " + world.get_message('LEV_DUNE_HELPER') + "/m";
	}
}

//------------------------------ End of Create_Dune_Lever -------------------------------//

species Maintain_Dune_Lever parent: Cost_Lever {
	float indicator 			-> { my_district.length_dunes_t0 = 0 ? 0 :  my_district.length_maintained_dunes / my_district.length_dunes_t0 };
	string progression_bar 	-> { "" + my_district.length_maintained_dunes + " m / " + threshold + " * " + my_district.length_dunes_t0 + " m " + LEV_DUNES };
	
	init{
		lever_name	<- world.get_lever_name('LEVER_MAINTAIN_DUNE');
		lever_type	<- world.get_lever_type('LEVER_MAINTAIN_DUNE');
		threshold	<- world.get_lever_threshold('LEVER_MAINTAIN_DUNE');
		added_cost 	<- world.get_lever_cost('LEVER_MAINTAIN_DUNE');
		player_msg 		<- world.get_message('LEV_GANIVELLE_PLAYER');
	}
	
	string get_lever_help_msg {
		return world.get_message('LEV_GANIVELLE_HELPER1') + " " + int(100*added_cost) + "% " + world.get_message('LEV_MAINTAIN_HELPER') + "/m";
	}
}
//------------------------------ End of Maintain_Dune_Lever -------------------------------//

species Us_out_Coast_and_Risk_Area_Lever parent: Cost_Lever{
	int indicator 			-> { my_district.count_Us_out_coast_or_risk_area };
	string progression_bar 	-> { "" + indicator + " " + LEV_MSG_ACTIONS + " / " + int(threshold) + " " + LEV_MAX };
	
	init{
		lever_name 	<- world.get_lever_name('LEVER_Us_out_COAST_and_RISK_AREA');
		lever_type	<- world.get_lever_type('LEVER_Us_out_COAST_and_RISK_AREA');
		threshold	<- world.get_lever_threshold('LEVER_Us_out_COAST_and_RISK_AREA');
		added_cost 	<- world.get_lever_cost('LEVER_Us_out_COAST_and_RISK_AREA');
		player_msg 		<- world.get_message('LEV_GANIVELLE_PLAYER');
	}
	
	string get_lever_help_msg {
		return world.get_message('LEV_GANIVELLE_HELPER1') + " " + int(100*added_cost) + "% " + world.get_message('LEV_ADAPTATION_HELPER2');
	}
	
	string info_of_next_activated_lever {
		return '+' + abs(int(activation_queue[0].p_action.cost * added_cost)) + " By " + world.get_message('LEV_ADAPTATION_HELPER1');
	}
	
	action apply_lever(Activated_Lever lev){
		lev.applied <- true;
		lev.lever_explanation <- player_msg;
		lev.added_cost 		<- float(lev.p_action.cost * added_cost);
		lev.added_delay 	<- 0;
		do send_lever_message (lev);
		
		last_lever_cost 	<- lev.added_cost;
		activation_label_L1 <- "Last payment : " + (-1 * last_lever_cost) + ' By';
		activation_label_L2 <- 'Total paid : '  + (-1 * total_lever_cost()) + ' By';
		
		ask world {
			do record_leader_activity(myself.lever_name + " triggered at", myself.my_district.district_name, myself.lever_help_msg + " : " + lev.added_cost + "By : " + lev.added_delay + " rounds" + "(" + lev.p_action + ")");
		}
	}
}
//------------------------------ End of Us_out_Coast_Border_or_Risk_Area_Lever -------------------------------//

species Us_in_Coast_Area_Lever parent: Cost_Lever{
	int indicator 			-> { my_district.count_Us_in_coast_area };
	string progression_bar 	-> { "" + my_district.count_Us_in_coast_area + " " + LEV_MSG_ACTIONS + " / " + int(threshold) +" " + LEV_MAX};
	
	init{
		lever_name 	<- world.get_lever_name('LEVER_Us_in_COAST_AREA');
		lever_type	<- world.get_lever_type('LEVER_Us_in_COAST_AREA');
		threshold	<- world.get_lever_threshold('LEVER_Us_in_COAST_AREA');
		added_cost 	<- world.get_lever_cost('LEVER_Us_in_COAST_AREA');
		player_msg 	<- world.get_message('LEV_ADAPTATION_PLAYER');
	}
	
	string get_lever_help_msg {
		return world.get_message('LEV_GANIVELLE_HELPER1') + " " + int(100*added_cost) + "% "+ world.get_message('LEV_ADAPTATION_HELPER2');
	}
		
	string info_of_next_activated_lever{
		return "+" + abs(int(activation_queue[0].p_action.cost * added_cost)) + " By " + world.get_message('LEV_ADAPTATION_HELPER1');
	}		
}
//------------------------------ End of Us_in_Coast_Border_Area_Lever -------------------------------//

species Us_in_Risk_Area_Lever parent: Cost_Lever{
	int indicator 			-> { my_district.count_Us_in_risk_area };
	string progression_bar 	-> { "" + my_district.count_Us_in_risk_area + " " + LEV_MSG_ACTIONS + " / " + int(threshold) + " " + LEV_MAX };
	
	init{
		lever_name 	<- world.get_lever_name('LEVER_Us_in_RISK_AREA');
		lever_type	<- world.get_lever_type('LEVER_Us_in_RISK_AREA');
		threshold	<- world.get_lever_threshold('LEVER_Us_in_RISK_AREA');
		added_cost 	<- world.get_lever_cost('LEVER_Us_in_RISK_AREA');
		player_msg 	<- world.get_message('LEV_ADAPTATION_PLAYER');
	}
	
	string get_lever_help_msg {
		return world.get_message('LEV_GANIVELLE_HELPER1') + " " + int(100*added_cost) + "% "+ world.get_message('LEV_ADAPTATION_HELPER2');
	}

	string info_of_next_activated_lever{
		return "+" + abs(int(activation_queue[0].p_action.cost * added_cost)) + " By " + world.get_message('LEV_ADAPTATION_HELPER1');
	}		
}
//------------------------------ End of Us_in_Risk_Area_Lever -------------------------------//

species Inland_Dike_Lever parent: Delay_Lever {
	float indicator 		-> { my_district.length_dikes_t0 = 0 ? 0.0 : my_district.length_inland_dikes / my_district.length_dikes_t0 };
	string progression_bar 	-> { "" + my_district.length_inland_dikes + " m / " + threshold + " * " + my_district.length_dikes_t0 + " m " + LEV_DIKES + " " + LEV_AT + " t0"};
	
	init{
		lever_name 	<- world.get_lever_name('LEVER_INLAND_DIKE');
		lever_type	<- world.get_lever_type('LEVER_INLAND_DIKE');
		added_delay <- world.get_lever_delay('LEVER_INLAND_DIKE');
		threshold	<- world.get_lever_threshold('LEVER_INLAND_DIKE');
		player_msg 	<- world.get_message('LEV_INLAND_PLAYER');	
	}
	
	string get_lever_help_msg {
		return world.get_message('LEV_INLAND_HELPER1') + " " + abs(added_delay) + " " + MSG_ROUND + (abs(added_delay) > 1 ? "s" : "");
	}
		
	string info_of_next_activated_lever {
		return world.get_message('LDR_MSG_RETRODIKE') + " (" + int(activation_queue[0].p_action.length_coast_def) + " m): -" + abs(added_delay) + " " + LDR_MSG_ROUNDS;
	}
}
//------------------------------ End of Inland_Dike_Lever -------------------------------//

species No_Action_On_Dike_Lever parent: Cost_Lever {
	string progression_bar 	-> { "" + int(threshold - nb_rounds_before_activation) + " " + LDR_MSG_ROUNDS +" / " + int(threshold) + " " + LEV_MAX };
	int nb_activations 		<- 0;
	string box_title 		-> { lever_name + ' (' + nb_activations +')' };
	
	bool should_be_activated-> { nb_rounds_before_activation < 0 and !empty(list_of_impacted_actions)};
	int nb_rounds_before_activation;
	list<Player_Action> list_of_impacted_actions -> {my_district.get_impacted_soft_def_withraw_actions()};
	
	init{
		player_msg <- world.get_message('LEV_GANIVELLE_PLAYER');
	}
		
	string info_of_next_activated_lever {
		return world.get_message('LEV_ACTION_SOFTDEF_WITH') + " - " + abs(int(activation_queue[0].p_action.cost * added_cost)) + ' By';
	}	
	
	action register (Player_Action p_action){
		add p_action to: associated_actions;
		nb_rounds_before_activation <- int(threshold);
	}	

	action check_activation_at_new_round {
		if game_round > 1 {
			nb_rounds_before_activation <- nb_rounds_before_activation - 1;
			do check_activation_and_impact_on_first_element_of(list_of_impacted_actions);
		}
	}

	action apply_lever(Activated_Lever lev){
		lev.applied <- true;
		lev.lever_explanation <- player_msg;
		lev.added_cost <- float(lev.p_action.cost * added_cost);
		do send_lever_message(lev);
		
		last_lever_cost 	<- lev.added_cost;
		activation_label_L1 <- LDR_LAST + " "  + (last_lever_cost >= 0 ? world.get_message('LDR_LEVY') : 
						world.get_message('LDR_PAYMENT')) + " : " + abs(last_lever_cost)   + ' By.';
		activation_label_L2 <- world.get_message('LDR_TOTAL') + " " + (last_lever_cost >= 0 ? world.get_message('LDR_TAKEN'):
						world.get_message('LDR_GIVEN')) + " : " + abs(total_lever_cost())+ ' By.';
		
		nb_rounds_before_activation <- int(threshold);
		nb_activations 	<- nb_activations +1;
		
		ask world {
			do record_leader_activity(myself.lever_name + " triggered at", myself.my_district.district_name, myself.lever_help_msg + " : " + (lev.added_cost) + "By" + "(" + lev.p_action + ")");
		}
	}
}
//------------------------------ end of No_Action_On_Dike_Lever -------------------------------//

species No_Dike_Creation_Lever parent: No_Action_On_Dike_Lever{
	init{
		lever_name 	<- world.get_lever_name('LEVER_NO_DIKE_CREATION');
		lever_type	<- world.get_lever_type('LEVER_NO_DIKE_CREATION');
		threshold	<- world.get_lever_threshold('LEVER_NO_DIKE_CREATION');
		added_cost	<- world.get_lever_cost('LEVER_NO_DIKE_CREATION');
		nb_rounds_before_activation <- int(threshold);
	}
	
	string get_lever_help_msg {
		return world.get_message('LEV_DURING_MSG') + " " + threshold + " " + world.get_message('LEV_NO_DIKE_CREATION_HELP') + ". " + world.get_message('LEV_GANIVELLE_HELPER1') + " " + int(100*added_cost)+"% " + world.get_message('LEV_ACTION_SOFTDEF_WITH') + "/m";
	}
}
//------------------------------ end of No_Dike_Creation_Lever -------------------------------//

species No_Dike_Raise_Lever parent: No_Action_On_Dike_Lever{
	init{
		lever_name 	<- world.get_lever_name('LEVER_NO_DIKE_RAISE');
		lever_type	<- world.get_lever_type('LEVER_NO_DIKE_RAISE');
		threshold	<- world.get_lever_threshold('LEVER_NO_DIKE_RAISE');
		added_cost	<- world.get_lever_cost('LEVER_NO_DIKE_RAISE');
		nb_rounds_before_activation <- int(threshold);
	}
	
	string get_lever_help_msg {
		return world.get_message('LEV_DURING_MSG') + " " + threshold + " " + world.get_message('LEV_NO_DIKE_RAISE_HELP') + ". " + world.get_message('LEV_GANIVELLE_HELPER1') + " " + int(100*added_cost)+"% " + world.get_message('LEV_ACTION_SOFTDEF_WITH') + "/m";
	}
}
//------------------------------ end of No_Dike_Raise_Lever -------------------------------//

species No_Dike_Repair_Lever parent: No_Action_On_Dike_Lever{
	init{
		lever_name	<- world.get_lever_name('LEVER_NO_DIKE_REPAIR');
		lever_type	<- world.get_lever_type('LEVER_NO_DIKE_REPAIR');
		threshold	<- world.get_lever_threshold('LEVER_NO_DIKE_REPAIR');
		added_cost	<- world.get_lever_cost('LEVER_NO_DIKE_REPAIR');
		nb_rounds_before_activation <- int(threshold);
	}
	
	string get_lever_help_msg {
		return world.get_message('LEV_DURING_MSG') + " " + threshold + " " + world.get_message('LEV_NO_DIKE_REPAIR_HELP') + ". " + world.get_message('LEV_GANIVELLE_HELPER1') + " " + int(100*added_cost)+"% " + world.get_message('LEV_ACTION_SOFTDEF_WITH') + "/m";

	}
}
//------------------------------ end of No_Dike_Repair_Lever -------------------------------//

species A_to_N_in_Coast_or_Risk_Area_Lever parent: Cost_Lever{
	int indicator 				-> { my_district.count_A_to_N_in_coast_or_risk_area };
	string progression_bar 		-> { "" + my_district.count_A_to_N_in_coast_or_risk_area + " " + LEV_MSG_ACTIONS + " / " + int(threshold) + " " + LEV_MAX };
	bool should_be_activated 	-> { indicator > threshold and (my_district.is_withdrawal or my_district.is_soft_def)};
	
	init{
		lever_name 	<- world.get_lever_name('LEVER_A_to_N_in_COAST_or_RISK_AREA');
		lever_type	<- world.get_lever_type('LEVER_A_to_N_in_COAST_or_RISK_AREA');
		threshold	<- world.get_lever_threshold('LEVER_A_to_N_in_COAST_or_RISK_AREA');
		added_cost 	<- world.get_lever_cost('LEVER_A_to_N_in_COAST_or_RISK_AREA');
		player_msg 	<- world.get_message('LEV_GANIVELLE_PLAYER');
	}
	
	string get_lever_help_msg {
		return world.get_message('LEV_GANIVELLE_HELPER1') + " " + int(100*added_cost) + "% " + world.get_message('LEV_ACTION_SOFTDEF_WITH');
	}

	string info_of_next_activated_lever {
		return "+" + abs(int(activation_queue[0].p_action.cost * added_cost)) + ' By ' + world.get_message('LEV_ACTION_SOFTDEF_WITH');
	}	
}
//------------------------------ end of A_to_N_in_Coast_Border_or_Risk_Area_Lever -------------------------------//

species Densification_out_Coast_and_Risk_Area_Lever parent: Cost_Lever{
	int indicator 			-> { my_district.count_densification_out_coast_and_risk_area };
	string progression_bar 	-> { "" + my_district.count_densification_out_coast_and_risk_area + " " + LEV_MSG_ACTIONS + " / " + int(threshold) +" " + LEV_MAX };
	
	init{
		lever_name 	<- world.get_lever_name('LEVER_DENSIFICATION_out_COAST_and_RISK_AREA');
		lever_type	<- world.get_lever_type('LEVER_DENSIFICATION_out_COAST_and_RISK_AREA');
		threshold	<- world.get_lever_threshold('LEVER_DENSIFICATION_out_COAST_and_RISK_AREA');
		added_cost 	<- world.get_lever_cost('LEVER_DENSIFICATION_out_COAST_and_RISK_AREA');
		player_msg 	<- world.get_message('LEV_GANIVELLE_PLAYER');
	}
	
	string get_lever_help_msg {
		return world.get_message('LEV_GANIVELLE_HELPER1') + " " + int(100*added_cost) + "% " + world.get_message('LEV_DENSIFICATION_HELPER2');
	}
	
	string info_of_next_activated_lever {
		return "+" + abs(int(activation_queue[0].p_action.cost * added_cost)) + ' By ' + world.get_message('LEV_LAST_DENSIFICATION');
	}			
}
//------------------------------ end of Densification_out_Coast_Border_and_Risk_Area_Lever -------------------------------//

species Expropriation_Lever parent: Cost_Lever{
	int indicator 			-> { my_district.count_expropriation };
	string progression_bar 	-> { "" + my_district.count_expropriation + " " + MSG_EXPROPRIATION + " / " + int(threshold) + " " + LEV_MAX };
	
	init{
		lever_name 	<- world.get_lever_name('LEVER_EXPROPRIATION');
		lever_type	<- world.get_lever_type('LEVER_EXPROPRIATION');
		threshold	<- world.get_lever_threshold('LEVER_EXPROPRIATION');
		added_cost 	<- world.get_lever_cost('LEVER_EXPROPRIATION');
		player_msg 	<- world.get_message('LEV_WITHDRAWAL_PLAYER');
	}
	
	string get_lever_help_msg {
		return world.get_message('LEV_GANIVELLE_HELPER1') + " " + int(100*added_cost) + "% "+ world.get_message('LEV_EXPROPRIATION_HELPER2');
	}
		
	string info_of_next_activated_lever {
		return "+" + abs(int(activation_queue[0].p_action.cost * added_cost)) + ' By ' + world.get_message("LEV_LAST_EXPROPRIATION");
	}		
}
//------------------------------ end of Expropriation_Lever -------------------------------//

species Destroy_Dike_Lever parent: Cost_Lever{
	float indicator 		 -> { my_district.length_dikes_t0 = 0 ? 0.0 : my_district.length_destroyed_dikes / my_district.length_dikes_t0 };
	bool should_be_activated -> { indicator > threshold and my_district.is_withdrawal};
	string progression_bar 	 -> { "" + my_district.length_destroyed_dikes + " m / " + threshold + " * " + my_district.length_dikes_t0 + " m " + LEV_AT + " t0"};
	
	init{
		lever_name 	<- world.get_lever_name('LEVER_DESTROY_DIKE');
		lever_type 	<- world.get_lever_type('LEVER_DESTROY_DIKE');
		threshold	<- world.get_lever_threshold('LEVER_DESTROY_DIKE');
		added_cost 	<- world.get_lever_cost('LEVER_DESTROY_DIKE');
		player_msg 	<- world.get_message('LEV_WITHDRAWAL_PLAYER');
	}
	
	string get_lever_help_msg {
		return world.get_message('LEV_GANIVELLE_HELPER1') + " " + int(100*added_cost) + "% " + world.get_message('LEV_DESTROY_WITHDRAW');
	}
		
	string info_of_next_activated_lever {
		return "+" + abs(int(activation_queue[0].p_action.cost * added_cost)) + ' By ' + world.get_message('LEV_LAST_DESTROY');
	}	
}
//------------------------------ end of Destroy_Dike_Lever -------------------------------//

species Give_Pebbles_Lever parent: Cost_Lever{
	string progression_bar <- "Levier manuel (Activer/Désactiver)";
	init{
		lever_name 	<- world.get_lever_name('LEVER_GIVE_PEBBLES');
		lever_type	<- world.get_lever_type('LEVER_GIVE_PEBBLES');
		threshold	<- world.get_lever_threshold('LEVER_GIVE_PEBBLES');
		added_cost 	<- world.get_lever_cost('LEVER_GIVE_PEBBLES');
		player_msg 	<- world.get_message('LEV_PEBBLES_GIVEN');
		status_on <- false;
	}
	
	string get_lever_help_msg {
		return world.get_message('LEV_PEBBLES_HELPER') + " " + int(100*added_cost) + "% ";
	}
}
//------------------------------ end of Give_Pebbles_Lever -------------------------------//

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
			switch m_contents[RESPONSE_TO_LEADER] {
				match NUM_ROUND	{
					if save_data {
						ask world { do save_leader_data; }
					}
					if send_my_plan {
						ask world { do send_one_year_plan; }
					}
					game_round <-int (m_contents[NUM_ROUND]);
					write MSG_ROUND + " " + game_round;
					ask districts {
						if game_round > 0 {
							string bud <- m_contents[district_code+"_bud"];
							string pop <- m_contents[district_code+"_pop"];
							if bud != nil {
								budget <- int(bud);
								if game_round = 1{
									received_tax <- budget;
								}
								if game_round >= 1{
									add budget to: districts_budgets[dist_id-1]; 
								}
							}
							if pop != nil and game_round > 0{
								population <- int(pop);
								add population to: districts_populations[dist_id-1]; 
							}
							do calculate_scores(game_round);
						}
					}
					if game_round = 1 {
						ask world { do init_plan_budget; }
					}
					ask world { do update_plan_populations; }
					
					loop lev over: all_levers{
						ask lev.population { 
							do check_activation_at_new_round();
						}	
					}
				}
				match ACTION_STATE {
					do update_action (m_contents);
				}
				match "ACTIVATED_LEVER_ON_ACTION" {
					
				}
				match INDICATORS_T0 		{
					ask districts where (each.district_code = m_contents[DISTRICT_CODE]) {
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
						if game_round > 0 {
							ask Player_Button where (each.my_district = self){
								string stat <- m_contents ["button_"+command];
								if stat != nil {
									state <- int(stat);
								}
							}
						}
						if game_round > 1 {
							districts_budgets[dist_id-1] <- [];
							loop i from: 0 to: game_round - 2 {
								add int(m_contents ["budget_round"+i]) to: districts_budgets[dist_id-1];
							}
							add budget to: districts_budgets[dist_id-1];
							
							districts_populations[dist_id-1] <- [];
							loop i from: 0 to: game_round - 1 {
								add int(m_contents ["pop_round"+i]) to: districts_populations[dist_id-1];
							}
							population <- last (districts_populations[dist_id-1]);
							received_tax <- int(m_contents ["TAXES"]);
							actions_cost <- int(m_contents ["ACTIONS"]);
							given_money <- int(m_contents ["GIVEN"]);
							taken_money <- int(m_contents ["TAKEN"]);
							levers_cost <- int(m_contents ["LEVERS"]);
							transferred_money <- int(m_contents ["TRANSFER"]);
							
							ask world {
								do init_plan_budget;
								do update_plan_populations;
							}
						}	
					}
				}
				match "STATS" {
					ask districts where (each.district_code = m_contents[DISTRICT_CODE]) {
						received_tax <- received_tax + int(m_contents['TAX']);
						actions_cost <- actions_cost + int(m_contents['ACTIONS']); 			
					}
				}
			}
		}	
	}
	
	action update_action (map<string,string> msg){
		Player_Action p_act <- first(Player_Action where(each.id = (msg at "id")));
		if p_act = nil { // new action commanded by a player : indicators are updated and levers triggering tresholds are tested
			create Player_Action{
				do init_action_from_map(msg);
				bool profile_this_action <- false;
				int ref_round <- command_round;
				if strategy_profile = "" {
					strategy_profile <- get_strategy_profile();
					profile_this_action <- true;
					ref_round <- game_round;
				}
				string act_prof <- strategy_profile;
				ask districts first_with (each.district_code = district_code) {
					if act_prof != OTHER { // only if the action is profiled
						int act_code <- myself.command;
						if myself.command = ACTION_MODIFY_LAND_COVER_N{
							ask Action_Counter where (each.my_district = self and each.action_code = act_code) {
								do add_one(act_prof);
							}
							if myself.is_expropriation { act_code <- ACTION_EXPROPRIATION;}
							else {
								if myself.previous_lu_name = 'A' {
									act_code <- ACTON_MODIFY_LAND_COVER_FROM_A_TO_N;
								} else if myself.previous_lu_name = 'AU' {
									act_code <- ACTON_MODIFY_LAND_COVER_FROM_AU_TO_N;
								}	
							}
						} else if myself.command = ACTION_MODIFY_LAND_COVER_AUs and myself.previous_lu_name = 'U' {
							act_code <- ACTION_MODIFY_LAND_COVER_Us;
						}
						
						ask Action_Counter where (each.my_district = self and each.action_code = act_code) {
							do add_one(act_prof);
						}	
					}
					// classifying this action
					switch myself.strategy_profile{
						match BUILDER 		{
							build_cost <- build_cost + myself.cost;
						}
						match SOFT_DEFENSE 	{
							soft_cost <- soft_cost + myself.cost;
						}
						match WITHDRAWAL 	{
							withdraw_cost <- withdraw_cost + myself.cost;
						}
						match OTHER 		{
							other_cost <- other_cost + myself.cost;
						}
					}
					do calculate_scores (ref_round);
					do update_indicators_and_register_player_action (myself);
					if profile_this_action {
						map<string, string> mpp <- [(LEADER_COMMAND)::NEW_REQUESTED_ACTION,(DISTRICT_CODE)::district_code,
						(STRATEGY_PROFILE)::myself.strategy_profile,"cost"::myself.cost,PLAYER_ACTION_ID::myself.id];
						ask world { do send_message_from_leader(mpp); }
					}	
				}
				add self to: player_actions;
			}
		}
		else{ // an update of an action already commanded
			ask first(p_act) {
				do init_action_from_map(msg);
			}
		}
	}
}
//------------------------------ end of Network_Leader -------------------------------//

grid Grille width: GRID_W height: GRID_H {
	init {
		color <- #white ;
	}
}

grid Grille2 width: GRID_W+1 height: GRID_H+1 {
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
		
		switch command {
			match EXCHANGE_MONEY {
				list<District> dists <- districts - my_district;
				map values 	<- user_input(world.get_message("LDR_TRANSFERT1") + " : \n(0 " + MSG_TO_CANCEL+")\n"
						 + "1 : " + dists[0].district_long_name +
						 "\n2 : " + dists[1].district_long_name +
						 "\n3 : " + dists[2].district_long_name,
										[MSG_AMOUNT :: "2000", MSG_COMMUNE :: "0"]);
				int amount_value <- int(values at MSG_AMOUNT);
				int ddist <- int(values at MSG_COMMUNE);
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
						msg_activity[1] <- msg_player + " : " + dists[ddist-1].district_name + " (" + amount_value + " By)";
						
						my_district.transferred_money <- my_district.transferred_money - amount_value;
						dists[ddist-1].transferred_money <- dists[ddist-1].transferred_money + amount_value;
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
										[MSG_AMOUNT :: "2000", (MSG_123_OR_CUSTOMIZED) :: "1"]);
				int amount_value <- int(values at MSG_AMOUNT);
				if  amount_value != 0 {
					switch int(values at MSG_123_OR_CUSTOMIZED) {
						match 1 { msg_player <- msg1; }
						match 2 { msg_player <- msg2; }
						match 3 { msg_player <- msg3; }
						default { msg_player <- values at MSG_123_OR_CUSTOMIZED; }
					}
					put TAKE_MONEY_FROM 			key: LEADER_COMMAND 	in: msg;
					put amount_value			 	key: AMOUNT 			in: msg;
					put msg_player 					key: MSG_TO_PLAYER 		in: msg;
					
					msg_activity[0] <- world.get_message('LDR_MSG_TAKE_MONEY_FROM');
					msg_activity[1] <- msg_player + " : " + amount_value + "By";
					
					my_district.taken_money <- my_district.taken_money - amount_value;
				}
			}
			match GIVE_MONEY_TO {
				string msg1 <- world.get_message('BTN_GIVE_MONEY_MSG1');
				string msg2 <- world.get_message('BTN_GIVE_MONEY_MSG2');
				string msg3 <- world.get_message('BTN_GIVE_MONEY_MSG3');
				string msg4 <- world.get_message('BTN_GIVE_MONEY_MSG4');
				map values 	<- user_input(msg4 + " " + my_district.district_long_name + "\n(0 " + MSG_TO_CANCEL+")\n" + MSG_CHOOSE_MSG_TO_SEND +
										"\n1 : " + msg1 + "\n2 : " + msg2 + "\n3 : " + msg3 + "\n" + MSG_TYPE_CUSTOMIZED_MSG,
										[MSG_AMOUNT :: "2000", (MSG_123_OR_CUSTOMIZED) :: "1"]);
				int amount_value <- int(values at MSG_AMOUNT);			
				if amount_value != 0 {
					switch int(values at MSG_123_OR_CUSTOMIZED) {
						match 1 { msg_player <- msg1; }
						match 2 { msg_player <- msg2; }
						match 3 { msg_player <- msg3; }
						default { msg_player <- values at MSG_123_OR_CUSTOMIZED; }
					}
					put GIVE_MONEY_TO 			 	key: LEADER_COMMAND in: msg;
					put amount_value 				key: AMOUNT 		in: msg;
					put msg_player 					key: MSG_TO_PLAYER 	in:msg;
					
					msg_activity[0] <- world.get_message('LDR_MSG_SEND_MONEY_TO');
					msg_activity[1] <- msg_player + " : " + amount_value + "By";
					
					my_district.given_money <- my_district.given_money + amount_value;
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
				string custom_msg <- values at MSG_123_OR_CUSTOMIZED;
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

species District_Name2 parent: District_Name {}
//------------------------------ end of District_Name -------------------------------//

species plan_Button {
	int command;
	string _name;
	geometry shape <- first(F_Plan_Grid).shape * 0.9;
	rgb col;
	point loc;
	
	init { col <- #yellow; }
	
	aspect {
		draw shape color: (send_my_plan ? #lightgray : col) border: #black at: loc;
		draw _name at: loc anchor: #center font: font("Arial", 12 , #bold) color: #black;
	}
}

grid F_Plan_Grid width: 5 height: 20 schedules:[] {
	string text;
	rgb col <- #whitesmoke;
		
	aspect {
		draw shape color: col;// border: #black;
		draw text at: location anchor: #center font: font("Arial", 12 , #bold) color: #black;
	}
}
//------------------------------ end of Pot -------------------------------//

experiment LittoSIM_GEN_Leader {
	string default_language <- first(text_file("../includes/config/littosim.conf").contents where (each contains 'LANGUAGE')) split_with ';' at 1;
	list<string> languages_list <- first(text_file("../includes/config/littosim.conf").contents where (each contains 'LANGUAGE_LIST')) split_with ';' at 1 split_with ',';
	
	init {
		minimum_cycle_duration <- 0.5;
	}
	
	parameter "Language choice : " var: my_language	 <- default_language  among: languages_list;
	parameter "Save data : " var: save_data <- false;
	
	output{
		display Levers{
			graphics "Round" {
				draw  (MSG_ROUND + " : " + game_round)  at: {world.shape.width/2,1} font: font("Arial", 20 , #bold) color: #red anchor: #center;
			}
			species District_Name;
			species District_Action_Button;
			species Create_Dike_Lever;
			species Raise_Dike_Lever;
			species Repair_Dike_Lever;
			species AU_or_Ui_in_Coast_Area_Lever;
			species AU_or_Ui_in_Risk_Area_Lever;
			species Ganivelle_Lever;
			species Enhance_Natural_Accr_Lever;
			species Create_Dune_Lever;
			species Maintain_Dune_Lever;
			species Us_out_Coast_and_Risk_Area_Lever;
			species Us_in_Coast_Area_Lever;
			species Us_in_Risk_Area_Lever;
			species Inland_Dike_Lever;
			species No_Dike_Creation_Lever;
			species No_Dike_Raise_Lever;
			species No_Dike_Repair_Lever;
			species A_to_N_in_Coast_or_Risk_Area_Lever ;
			species Densification_out_Coast_and_Risk_Area_Lever ;
			species Expropriation_Lever;
			species Destroy_Dike_Lever;
			species Give_Pebbles_Lever;
			species Lever_Window_Info;
			species Lever_Window_Actions;
			species Lever_Window_Button;
			
			event [mouse_down] action: user_click;
			event [mouse_move] action: user_move;
		}
		
		display Actions {
			species District_Name2;
			species Action_Name;
			species Action_Counter;
			
		}
		
		display Statistics {
			chart world.get_message('MSG_POPULATION') type: series size: {0.33,0.48} position: {0.0,0.01} x_range:[0,16] 
					x_label: MSG_ROUND x_tick_line_visible: false{
				loop i from: 0 to: 3{
					data districts[i].district_name value: districts_populations[i] color: dist_colors[i] marker_shape: marker_circle;
				}		
			}
			
			chart world.get_message('MSG_BUDGETS') type: series size: {0.33,0.48} position: {0.34,0.01} x_range:[0,16] 
					x_label: MSG_ROUND x_tick_line_visible: false{
				loop i from: 0 to: 3{
					data districts[i].district_name value: districts_budgets[i] color: dist_colors[i] marker_shape: marker_circle;
				}		
			}
			
			chart LDR_TOTAL type: histogram size: {0.33,0.48} position: {0.67,0.01} style:stack
				x_serie_labels: districts collect each.district_name series_label_position: xaxis x_tick_line_visible: false {
			 	data MSG_TAXES value: districts collect each.received_tax collect sum(each) color: color_lbls[0];
			 	data LDR_GIVEN value: districts collect each.given_money collect sum(each) color: color_lbls[1];
			 	data LDR_TAKEN value: districts collect each.taken_money collect sum(each) color: color_lbls[2];
				data LDR_TRANSFERRED value: districts collect each.transferred_money collect sum(each) color: color_lbls[5];
			 	data LEV_MSG_ACTIONS value: districts collect each.actions_cost collect sum(each) color: color_lbls[3];
			 	data MSG_LEVERS value: districts collect each.levers_cost collect sum(each) color: color_lbls[4];		
			}
			
			chart world.get_message('MSG_COST_ACTIONS') + " ("+ LDR_TOTAL +")" type: histogram size: {0.48,0.48} position: {0.01,0.51}
				x_serie_labels: districts collect (each.district_name) style:stack {
			 	data MSG_BUILDER value: districts collect (each.build_cost) color: color_lbls[2];
			 	data MSG_SOFT_DEF value: districts collect (each.soft_cost) color: color_lbls[1];
			 	data MSG_WITHDRAWAL value: districts collect (each.withdraw_cost) color: color_lbls[0];
			 	data MSG_OTHER value: districts collect (each.other_cost) color: color_lbls[3];
			}
			chart "% " + world.get_message('MSG_COST_ACTIONS') + " (2 " + LDR_LAST + " " + LDR_MSG_ROUNDS + ")" type: histogram size: {0.48,0.48} position: {0.51,0.51}
				x_serie_labels: districts collect (each.district_name) style:stack {
			 	data MSG_BUILDER value: districts collect (each.builder_score * 100) color: color_lbls[2];
			 	data MSG_SOFT_DEF value: districts collect (each.soft_def_score * 100) color: color_lbls[1];
			 	data MSG_WITHDRAWAL value: districts collect (each.withdrawal_score * 100) color: color_lbls[0];
			}
		}
		
		display Financial_Plan {
			species F_Plan_Grid;
			species plan_Button;
			
			event [mouse_down] action: plan_buttons_click;
		}
		
		display Player_Buttons {
			species District_Name;
			species Player_Button;
			species Player_Button_Actions;
			species Player_Button_Button;
			
			event [mouse_down] action: user_buttons_click;
		}
	}
}

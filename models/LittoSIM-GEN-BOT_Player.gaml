/***
* Name: NewModel
* Author: Laatabi
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model Player_BOT
import "LittoSIM-GEN_Player.gaml"


experiment _Player_BOT_ type: gui parent: LittoSIM_GEN_Player {
	int BOT_ACTION_TYPE <- 0;
	int BOT_ACTION_CODE <- 1;
	int BOT_ACTION_PROBA <- 2;
	int BOT_ACTION_ELEMENT <- 3;
	int BOT_ACTION_OUT_RISK_COAST <- 4;
	int BOT_ACTION_IN_RISK <- 5;
	int BOT_ACTION_IN_COAST <- 6;
	
	string scenario <- "builder100";
	int current_read_round <- 0;
	int current_exec_round <- 0;
	int pause_cycles <- 5;
	list<list<string>> actions_to_exec <- [];
	
	action _init_ {
		create simulation with:[active_district_name::districts[1], my_language::default_language];
		minimum_cycle_duration <- 0.5;
	}
	
	reflex read_scen when: current_read_round = game_round {
		string f_scen <- "../includes/config/scenarios/" + scenario + "/player.scen";
		actions_to_exec <- [];
		if file_exists (f_scen) {
			loop line over: text_file(f_scen){
				add line split_with(";") to: actions_to_exec;
			}
			remove from: actions_to_exec index: 0; // remove header
		}
		current_read_round <- game_round + 1;
	}
	
	reflex play_act when: current_exec_round = game_round and (cycle mod pause_cycles = 0) {
		list<string> data <- actions_to_exec [rnd(length(actions_to_exec)-1)];
		int comm <- int(eval_gaml(data[BOT_ACTION_CODE]));

		if flip(float(data[BOT_ACTION_PROBA])) {
			// action on land use
			if data[BOT_ACTION_TYPE] = PLAYER_ACTION_TYPE_LU {
				list<Land_Use> lus <- [];
				
				// land units of type BOT_ACTION_ELEMENT with no current player actions
				lus <- Land_Use where (each.lu_code = eval_gaml(data[BOT_ACTION_ELEMENT]));
				ask lus {
					if length(my_basket where(each.element_id = id)) > 0 { 
						remove self from: lus;
					}
				} 
				
				// conditions on action
				if comm = ACTION_MODIFY_LAND_COVER_Ui {
					lus <- lus where (each.density_class != POP_DENSE);
				} else if comm in [ACTION_MODIFY_LAND_COVER_AU, ACTION_MODIFY_LAND_COVER_AUs]{
					ask lus {
						if empty(Land_Use at_distance 100 where (each.is_urban_type)) { remove self from: lus; }
					} 
				}
				
				// conditions on element
				 if flip(float(data[BOT_ACTION_OUT_RISK_COAST])){ // out risk and coast areas
					lus <- lus where (!(each.shape intersects union(Coastal_Border_Area)) and !(each.shape intersects union(Flood_Risk_Area)));
				} else {
					if flip(float(data[BOT_ACTION_IN_RISK])) { // in risk area
						lus <- lus where (each.shape intersects union(Flood_Risk_Area));
					} else if flip(float(data[BOT_ACTION_IN_COAST])) { // in coast area
						lus <- lus where (each.shape intersects union(Coastal_Border_Area));
					}
				}
				if length(lus) > 0 {
					ask world {
						do create_land_use_action (one_of(lus), Button first_with (each.command = comm));
					}
				}
			}
			// action on coast def
			else if data[BOT_ACTION_TYPE] = PLAYER_ACTION_TYPE_COAST_DEF {
				if comm = ACTION_CREATE_DIKE {
					previous_clicked_point <- any_location_in(local_shape inter union(Coastal_Border_Area));
					point loca <- previous_clicked_point + 200#m;
					ask world {
						do create_new_coast_def_action (Button first_with (each.command = comm), loca);
					}
				} else {
					list<Coastal_Defense> codefs <- Coastal_Defense where (each.type = eval_gaml(data[BOT_ACTION_ELEMENT]));
					ask codefs {
						if length(my_basket where(each.element_id = coast_def_id)) > 0 { 
							remove self from: codefs;
						}
					} 
					
					if flip(float(data[BOT_ACTION_OUT_RISK_COAST])){ // out risk and coast areas
						codefs <- codefs where (!(each.shape intersects union(Coastal_Border_Area)) and !(each.shape intersects union(Flood_Risk_Area)));
					} else {
						if flip(float(data[BOT_ACTION_IN_RISK])) { // in risk area
							codefs <- codefs where (each.shape intersects union(Flood_Risk_Area));
						} else if flip(float(data[BOT_ACTION_IN_COAST])) { // in coast area
							codefs <- codefs where (each.shape intersects union(Coastal_Border_Area));
						}
					}
					if length(codefs) > 0 {
						ask world {
							//do create_coastal_def_action (one_of(codefs), Button first_with (each.command = comm));
						}
					}	
				}
			}
		}
		
		ask game_basket {
			if final_budget < -2000 {
				ask Basket_Element(last(elements)) {
					do remove_action;
				}
			} else if final_budget <= -1900 {
				myself.current_exec_round <- game_round + 1;
				ask Network_Player{
					do send_basket;
				}
			}
		}
	}
}
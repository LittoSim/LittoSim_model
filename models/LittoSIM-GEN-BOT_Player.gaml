/***
* Name: NewModel
* Author: Laatabi
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model Player_BOT
import "LittoSIM-GEN_Player.gaml"


experiment _Player_BOT_ type: gui parent: LittoSIM_GEN_Player {
	string scenario <- "builder100";
	int current_read_round <- 0;
	int current_exec_round <- 0;
	int pause_cycles <- 1;
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
		int comm <- int(eval_gaml(data[1]));

		if flip(float(data[2])) {
			// action on land use
			if data[0] = PLAYER_ACTION_TYPE_LU {
				list<Land_Use> lus <- [];
				
				// land units of type data[3] with no current player actions
				lus <- Land_Use where (each.lu_code = eval_gaml(data[3]) and length(Player_Action collect(each.element_id = each.id)) = 0);
				
				// conditions on action
				if comm = ACTION_MODIFY_LAND_COVER_Ui {
					lus <- lus where (each.density_class != POP_DENSE);
				} else if comm in [ACTION_MODIFY_LAND_COVER_AU, ACTION_MODIFY_LAND_COVER_AUs]{
					ask lus {
						if empty(Land_Use at_distance 100 where (each.is_urban_type)) { remove self from: lus; }
					} 
				}
				
				// conditions on element
				if flip(float(data[4])) { // in risk area
					lus <- lus where (each.shape intersects all_flood_risk_area);
				} else {
					if flip(float(data[5])) { // in coast area
						lus <- lus where (each.shape intersects all_coastal_area);
					} else if flip(float(data[6])){ // out risk and coast areas
						lus <- lus where (!(each.shape intersects all_coastal_area) and !(each.shape intersects all_flood_risk_area));
					}
				}
				
				if length(lus) > 0 {
					ask world {
						do create_land_use_action (one_of(lus), Button first_with (each.command = comm));
					}
				}
			}
			// action on coast def
			else if data[0] = PLAYER_ACTION_TYPE_COAST_DEF {
				if comm = ACTION_CREATE_DIKE {
					previous_clicked_point <- any_location_in(local_shape inter all_coastal_area);
					point loca <- previous_clicked_point + 200#m;
					ask world {
						do create_new_coast_def_action (Button first_with (each.command = comm), loca);
					}
				} else {
					list<Coastal_Defense> codefs <- Coastal_Defense where (each.type = eval_gaml(data[3]) and length(my_basket where(each.element_id = each.id)) = 0);
					
					if flip(float(data[4])) { // in risk area
						codefs <- codefs where (each.shape intersects all_flood_risk_area);
					} else {
						if flip(float(data[5])) { // in coast area
							codefs <- codefs where (each.shape intersects all_coastal_area);
						} else if flip(float(data[6])){ // out risk and coast areas
							codefs <- codefs where (!(each.shape intersects all_coastal_area) and !(each.shape intersects all_flood_risk_area));
						}
					}
					if length(codefs) > 0 {
						ask world {
							do create_coastal_def_action (one_of(codefs), Button first_with (each.command = comm));
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
			}
		}
	}
}
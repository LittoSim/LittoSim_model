/***
* Name: NewModel
* Author: Laatabi
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model Manager_BOT
import "../LittoSIM-GEN_Manager.gaml"


experiment _Manager_BOT_ type: gui parent: LittoSIM_GEN_Manager {

	//string f_scen <- "../includes/config/scenarios/manager.scen";
	
	//int current_read_round <- 0;
	//int current_exec_round <- 0;
	int round_cycles <- 10;
	//list<list<string>> actions_to_exec <- [];
	
	action _init_ {
		create simulation;
		minimum_cycle_duration <- 0.5;
	}
	
	/*reflex read_scen when: current_read_round = game_round {
		
		actions_to_exec <- [];
		if file_exists (f_scen) {
			loop line over: text_file(f_scen){
				add line split_with(";") to: actions_to_exec;
			}
			remove from: actions_to_exec index: 0; // remove header
		}
		current_read_round <- game_round + 1;
	}
	*/
	
	reflex manage when: cycle mod round_cycles = 0 {
		ask world {
			do new_round;
		}
	}
}
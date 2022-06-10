/***
* Name: Test
* Author: flavi
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model Test


import "../LittoSIM-GEN_Player.gaml"


experiment _Player_BOT_ type: gui parent: LittoSIM_GEN_Player {
	list<Land_Use> urbans <- [];
	int nb_action;
	int current_exec_round <- 1;
	int pause_cycles <- 5;
	

	
	
	
 	reflex play when: (current_exec_round = game_round) and (cycle mod pause_cycles = 0){
		nb_action <- 0;
		
		loop while:nb_action < 5 {
		urbans <- Land_Use where (each.is_urban_type);
		ask world {
						do create_land_use_action (one_of(myself.urbans), Button first_with (each.command = 311));
					}
		
		nb_action <- nb_action +1;
		
		}
		current_exec_round <- current_exec_round +1;
		ask Network_Player{
			do send_basket;
		}
		
	}

}

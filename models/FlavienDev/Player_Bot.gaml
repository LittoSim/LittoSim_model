/***
* Name: StatePaternTest
* Author: flavi
* Description: 
* Tags: Tag1, Tag2, TagN
***/



model StatePaternTest

import "../LittoSIM-GEN_Player.gaml"

import "Etat.gaml"

import "Actions.gaml"


global {
	
	int budget_seuil;
	int current_round <- 0;
	
	/*DEBUG DATA*/
	int nb_action_ <-0;
	float test_data;
	
	
	init{		
		create bot_contexte;//create the contexte of the simulation
	}
	
}





species bot_contexte {		//species that represent the current context of the simulation it will allow to have information such as the current turn, the level of flood if needed
	state_ current_state;	//Curent state at the begining of the turn
	state_ estimated_state; //state estimated by the bot after each action
	init{
		create state0 returns:etat0;
		current_state <- etat0[0];
		estimated_state <- current_state;

	}
	/*action change_etat{
		current_state <- current_state.change();
	}*/
	
	action calculate_state{ //calcule the current state at the begining of each turn
		int emergency;
		
		
		//TODO calculate emergency:
		emergency <- rnd(0,4);
		
		switch (emergency){
			match 0 {if budget > budget_seuil {self.current_state <- listeEtat[0];} else {self.current_state <- listeEtat[1];}}
			match 1 {if budget > budget_seuil {self.current_state <- listeEtat[2];} else {self.current_state <- listeEtat[3];}}
//			match 2 {if budget > budget_seuil {self.current_state <- listeEtat[4];} else {self.current_state <- listeEtat[5];}}
//			match 3 {if budget > budget_seuil {self.current_state <- listeEtat[6];} else {self.current_state <- listeEtat[7];}}
//			match 4 {if budget > budget_seuil {self.current_state <- listeEtat[8];} else {self.current_state <- listeEtat[9];}}
		}
	}
	
	action etimate_next_state (int num_action){ //estimate the the state after each action
		/*estimate emergency :
		 * 					0, only N inondé
		 * 					1, pas de U inondé mais des A
		 * 					2, U innondé - d'1m
		 * 					3, U inondé + d'1m
		 *                  4, Udense innondé et/ou beaucoup de U + d'1m */
		 
		int estimate_budget;
		int estimate_urgence;
		
		estimate_urgence <- rnd(0,4);
		estimate_budget<- rnd(-5,5); 
		
		//TODO estimate budget and emergency depending on the action performed
		//use floodData to obtain flood data
		
		/*switch(num_action){
			match 0{estimate_budget <- 0; estimate_urgence <- 0;}
		}*/
		
		switch (estimate_urgence){
			match 0 {if estimate_budget >= 0 {self.current_state <- listeEtat[0];} else {self.current_state <- listeEtat[1];}}
			match 1 {if estimate_budget >= 0 {self.current_state <- listeEtat[2];} else {self.current_state <- listeEtat[3];}}
//			match 2 {if estimate_budget > 0 {self.current_state <- listeEtat[4];} else {self.current_state <- listeEtat[5];}}
//			match 3 {if estimate_budget > 0 {self.current_state <- listeEtat[6];} else {self.current_state <- listeEtat[7];}}
//			match 4 {if estimate_budget > 0 {self.current_state <- listeEtat[8];} else {self.current_state <- listeEtat[9];}}
		}
		
		
	}
	
	reflex behaviour when:game_round = current_round{  //when the game round of the player is equal to the current round of the bot
		int i;
		int n <- 0;
		int starting_emergency;
		
		do calculate_state;					//calcule the current state
		estimated_state <- current_state;	//the estimated state is the current state for the first action of the turn
		starting_emergency <- current_state.state_emergency;

		
		loop while: current_state.state_emergency>=starting_emergency and n<5{ 			//TODO add budget information to the end of turn
			nb_action_ <- nb_action_+1;
			i <- estimated_state.select_action();	//get the pointer to the action to execut from the current estimated state
			ask action_list[i]{ do behaviour;}		//ask the coresponding action to do his behaviour
			do etimate_next_state(i);				//estimate the next state depending on the current state and the action performed
			n<-n+1;
		}
		current_round <- current_round +1;		//at the end of his turn the bot wait for the nexte round
	}
	
}
 



experiment _Player_BOT_  parent: LittoSIM_GEN_Player {
	init{}
	output{
		display action_ratio{
				chart "action ration" type: histogram{	
					data "nb_action_"	value: nb_action_;	
					data "action_heavl" value: action_heavl;
					data "action_hardl" value: action_hardl;
					data "action_ml" value: action_ml;
					data "action_sl" value: action_sl;
					data "action_hb" value: action_hb;
					
				}
				
			}
		
		display nb_msg_receive{
				chart "nb_msg_receive" type: histogram{	
					data "nb_msg_receive"	value:nb_msg_receive;
					
				}
				
		}
	}
}

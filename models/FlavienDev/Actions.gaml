/***
* Name: Actions
* Author: flavien
* Description: 
*
***/

model Actions

global{
	//DEBUG DATA
	int action_heavl;
	int action_hardl;
	int action_ml;
	int action_sl;
	int action_hb;
	//--------------//
	
	
	list<bot_action> action_list ;		//liste des actions réalisable par le bot.
	
	init{
		
		//Creation des actions 
		create heavy_litoral_security returns: action0;
		create hard_litoral_security returns: action1;
		create medium_litoral_security returns: action2;
		create soft_litoral_security returns: action3;
		create hard_land_budget returns: action4;
		
		//ajout des actions dans la liste
		action_list <- [action0[0],action1[0],action2[0],action3[0],action4[0]];
	
	}
}


//espece parent des actions utilise 
species bot_action{
	int pointer; 				//pointer indiquant la place de l'action dans la liste


	action set_pointer(int i){	//action permettant de modifier le pointeur de l'action
		self.pointer <- i;
	}
	

	action behaviour{ } 		//action a modifier dans chaque classe enfant afin de definir son comportement
}

species heavy_litoral_security parent:bot_action{ //action used when the emmergency of flood is the highest
	init {do set_pointer(0);}
	action behaviour {
		/*TODO*/
		//add function create a dike
		action_heavl <- action_heavl+1 ;
		

	}
}
species hard_litoral_security parent:bot_action{ //actions used when the emmergency of flood is high	
	init {do set_pointer(1);}
	action behaviour {
		/*
*/
		//add functions raise_dike, create_dune & change_to_us
		action_hardl <- action_hardl+1;
		
	}
}
species medium_litoral_security parent:bot_action{ //actions used when the player think he is quite safe
	init {do set_pointer(2);}
	action behaviour {
		/*TODO*/
		//add functions load_pebbles repair_dike & install_send_fences
		action_ml <- action_ml+1;
		
	}
}
species soft_litoral_security parent:bot_action{ //actions used when the player think he is safe 
	init {do set_pointer(3);}
	action behaviour {
		/*TODO*/
		//add maintain_dune
		action_sl <- action_sl+1;
	}
}

species hard_land_budget parent:bot_action{ //action used when the budget is low and ther is no big emergency of flooding
	init {do set_pointer(4);}
	action behaviour {
		/*TODO*/
		//
		action_hb <- action_hb+1;
	}
}

experiment test{}
/* Insert your model definition here */


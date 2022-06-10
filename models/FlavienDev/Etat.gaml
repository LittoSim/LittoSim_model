/***
* Name: Etat
* Author: flavien
* Description: 
* 
***/


model Etat

global{
	
	int nb_state<-4;		//nombre d'etat possible pour le bot. nombre de ligne dans la matrice
	int nb_action<-5;		// nombre d'action possible pour le bot. nombre de colonne dans la matrice 
	
	float get_proba(int num_action, state_ etat){
		return etat.probas[num_action];
	}
	
	//DEBUG DATA//
	int etat_1;
	int etat_2;
	int etat_3;
	int etat_4;
	//-------------//
	
	list<state_> listeEtat;														//liste des etats possibles pour le bot
	list<list<float>> matrice <- nb_state list_with (nb_action list_with 0);	//matrice de probabilité d'action pour chacun des états
	
	
	init{
		
		/*temporary variable declaration */
		csv_file Matrice_test <- csv_file("Matrice_test.csv",";",true); //read the source files
		list<string> list_of_string <- list(Matrice_test); 				//list of strings in the file
		list<list> tmp;													//tempopary list of list used to split strings
		/*********************************/
		
		/*Fill variable to avoid null pointer exception */
		tmp <- nb_state list_with [];
		//matrice 
		/************************************************/
		
		/*Converting CSV_file into lists of string */
		int i <-0;
		loop line over:list_of_string{
			tmp[i] <- line split_with ",";							//split the list of string with ,
			i <- i+1;
		}
		/*******************************************/
		
		
		//nb_state <-length(tmp);
		//nb_action <- length(tmp[0])-1;
		
		/*Converting lists of string into list of float */
		loop i from:0 to:nb_state-1{					    //from 0 to nb of state possible
			loop j from:1 to:nb_action{					//from 1 to nb of action possible (+1 to avoid the name of the state)
				matrice[i][j-1]<-float(tmp[i][j]);
			}	
		}
	
		//create all the state
		create highUrgenceAndGoodIncome returns:etat1;
		create highUrgenceAndLowIncome returns:etat2;
		create urgenceAndGoodIncome returns:etat3;
		create urgenceAndLowIncome returns:etat4;
		//TODO add states
		
		//add state to the liste
		listeEtat <- [etat1[0],etat2[0],etat3[0],etat4[0]];

		}
}

//Parent species for all the state
species state_{
	list<float> probas;	//List of probabilities for each action
	int rank;			//rank of the state in the state list
	int state_emergency;
	
	
	
	init {
	}
	
	float get_my_proba(int num_action){
		return probas[num_action];
	}
	
	int select_action{						//this action return a int coresponding to the action to execute
		float dice <- rnd(0.0,1.0);			//select a random value between 0 and 1
		
		float sum <-0.0;					//this variable is the sum of each probabilities already check
		loop i from:0 to:length(probas)-1{	//loop over all the probabilities
			sum <- sum+probas[i];			//add the current probabilitie to the sum
			if (sum>=dice){					//if the sum is superior to the dice value, the algorithm stop 
				return  i;					//and return the value off the current pointer wich is the rank of the action to perform
			}
		}
	}
}

//state 0 is the starting state of the bot. This state could be modified to fit more precisly to players habbit
species state0 parent:state_{ // Etat initiale de la simulation

	init{
		rank <- 0;
		probas <- matrice[rank];
		state_emergency <- 0;
		
	}
}

species highUrgenceAndGoodIncome parent:state_{

	
	init{
		rank <- 0;
		probas <- matrice[rank];
		state_emergency <- 4;
	}
}

species highUrgenceAndLowIncome parent:state_{

	init{
		rank <- 1;
		probas <- matrice[rank];
		state_emergency <- 4;
	}
}

species urgenceAndGoodIncome parent:state_{
	init{
		rank <- 2;
		probas <- matrice[rank];
		state_emergency <- 3;
	}
}

species urgenceAndLowIncome parent:state_{

	init{
		rank <- 3;
		probas <- matrice[rank];
		state_emergency <- 3;
	}
}

//TODO change this state and add others.
species lowEmergencylowBudget parent:state_{
	init{
		rank <- 4;
		probas <- matrice[rank];
		state_emergency <- 2;
	}
}


experiment test{}
/* Insert your model definition here */


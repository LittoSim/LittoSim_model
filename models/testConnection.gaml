/**
* Name: testConnection
* Author: nicolas
* Description: Describe here the model and its experiments
* Tags: Tag1, Tag2, TagN
*/

model testConnection

global {
	string GAME_LEADER_MANAGER <- "GAME_LEADER_MANAGER";
	
	init
	{
		create game_leader number:1;
	}
	/** Insert the global definitions, variables and actions here */
}

species game_leader skills:[network]
{
	string ABROGER <- "Abroger";
	string RECETTE <- "Percevoir Recette";
	string SUBVENTIONNER <- "Subventionner";
	string RETARDER <- "Retarder";
	string LEVER_RETARD <- "Lever les retards";
	string LEADER_COMMAND <- "leader_command";
	string AMOUNT <- "amount";
	string DELAY <- "delay";
	string ACTION_ID <- "action_id";
	string COMMUNE <- "COMMUNE_ID";
	
	
	init
	{
		 do connect to:"localhost" with_name:GAME_LEADER_MANAGER;
		 write "coucou";
	}
	
	
	reflex  wait_message 
	{
		write "coucou"+ has_more_message();
		loop while:has_more_message()
		{
			message msg <- fetch_message();
			map<string, unknown> m_contents <- msg.contents;
			
			string cmd <- m_contents[LEADER_COMMAND];
			
			write "command " + cmd;
			write "montant" + m_contents[AMOUNT];
			write "action_id" + m_contents[ACTION_ID];
			write "DELAY" + m_contents[DELAY];
			write "COMMUNE" + m_contents[COMMUNE];
			
			
		}
		
	}
	
}

experiment testConnection type: gui {
	float minimum_cycle_duration <- 0.5;
	
	/** Insert here the definition of the input and output of the model */
	output {
	}
}

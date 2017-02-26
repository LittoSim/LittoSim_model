
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
		create test_remote_ui number:1;
	}
}



/// code important....

species test_remote_ui skills:[remoteGUI]
{
	list<string> mtitle <- ["mon titre 1","mon titre 2"];
	list<string> mfile <- ["mon chemin fichier 1","mon chemin fichier 2"];
	string selected_action;
	string choix_simu;
	int round;
	 
	init
	{
		//connection du au serveur
		do connect to:"localhost";
		
		do expose variables:["mtitle","mfile"] with_name:"listdata";
		do expose variables:["round"] with_name:"current_round";
		do listen with_name:"simu_choisie" store_to:"choix_simu";
		do listen with_name:"littosim_command" store_to:"selected_action";
	}
	reflex selected_action when:selected_action != nil
	{
		write "action_choisie" + selected_action;
		switch(selected_action)
		{
			match "NEW_ROUND" { do new_round; }
			match "LOCK_USERS" { do add_element("xsqxq"+cycle,"cdsc dfds "+cycle);  }
			match "UNLOCK_USERS" {   }
			match "HIGH_FLOODING" {   }
			match "LOW_FLOODING" {   }
		}
		selected_action <- nil;
	}
	
	reflex show_submersion when: choix_simu!=nil
	{
		write "choix de la simulation" + choix_simu;
		choix_simu <- nil;
	}

	action new_round
	{
		write "new round";
		round <- round + 1;
	}
	
	action add_element(string file_tile, string file_name)
	{
		mtitle <- mtitle + (" simu " + cycle );
		mfile <- mfile +  ("fichier "+ cycle);
	}
	
}
/// code fin important....

experiment testConnection type: gui {
	float minimum_cycle_duration <- 0.5;
	
	/** Insert here the definition of the input and output of the model */
	output {
	}
}

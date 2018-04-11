//
/**
 *  Commune
 *  Author: nicolas
 *  Description: 
 */
model Commune



global
{
	string SERVER <- "localhost";//"192.168.1.100"
	
	string DISPLAY_FONT_NAME <- "Helvetica Neue";
	int DISPLAY_FONT_SIZE <- 16;
	
	string LEGEND_UNAM <- "Aménagement, PLU et habitat";
	string LEGEND_DYKE <- "Défense des côtes";
	
	
	string commune_name <- "dolus";
	string GAME_MANAGER <- "GAME_MANAGER";
	string MSG_FROM_LEADER <- "MSG_FROM_LEADER";
	string log_file_name <- "log_"+machine_time+"csv";
	int round <- 0;
	
	float MOUSE_BUFFER <- 50#m;
	
	file emprise <- file("../includes/zone_etude/emprise_ZE_littoSIM.shp"); 
	file communes_shape <- file("../includes/zone_etude/communes.shp");
	string commune_name_shpfile;
	file communes_UnAm_shape <- file("../includes/zone_etude/zones241115.shp");	
	file defense_shape <- file("../includes/zone_etude/defense_cote_littoSIM-05122015.shp");
	file road_shape <- file("../includes/zone_etude/routesdepzone.shp");
	file zone_protegee_shape <- file("../includes/zone_etude/zps_sic.shp");
	file zone_PPR_shape <- file("../includes/zone_etude/PPR_extract.shp");
	file sites_non_classes_area_shape <- file("../includes/zone_etude/sites_non_classes.shp");
	matrix<string> all_action_cost <- matrix<string>(csv_file("../includes/cout_action.csv",";"));
	matrix<string> all_action_delay <- matrix<string>(csv_file("../includes/delai_action.csv",";"));

	//récupération des couts du fichier cout_action	
	int ACTION_COST_LAND_COVER_TO_A <- int(all_action_cost at {2,0});
	int ACTION_COST_LAND_COVER_TO_AU <- int(all_action_cost at {2,1});
	int ACTION_COST_LAND_COVER_FROM_AU_TO_N <- int(all_action_cost at {2,2});
	int ACTION_COST_LAND_COVER_FROM_A_TO_N <- int(all_action_cost at {2,7});
	int ACTION_COST_DIKE_CREATE <- int(all_action_cost at {2,3});
	int ACTION_COST_DIKE_REPAIR <- int(all_action_cost at {2,4});
	int ACTION_COST_DIKE_DESTROY <- int(all_action_cost at {2,5});
	int ACTION_COST_DIKE_RAISE <- int(all_action_cost at {2,6});
	float ACTION_COST_INSTALL_GANIVELLE <- float(all_action_cost at {2,8}); 
	float ACTION_COST_INSTALL_GANIVELLE_SUBSIDY <- float(all_action_cost at {2,14}); 
	int ACTION_COST_LAND_COVER_TO_AUs <- int(all_action_cost at {2,9});
	int ACTION_COST_LAND_COVER_TO_Us <- int(all_action_cost at {2,10});
	int ACTION_COST_LAND_COVER_TO_Ui <- int(all_action_cost at {2,13});
	int ACTION_COST_LAND_COVER_TO_AUs_SUBSIDY <- int(all_action_cost at {2,11});
	int ACTION_COST_LAND_COVER_TO_Us_SUBSIDY <- int(all_action_cost at {2,12});

	int ACTION_REPAIR_DIKE <- 5;
	int ACTION_CREATE_DIKE <- 6;
	int ACTION_DESTROY_DIKE <- 7;
	int ACTION_RAISE_DIKE <- 8;
	int ACTION_INSTALL_GANIVELLE <- 29;
	
	int ACTION_MODIFY_LAND_COVER_AU <- 1;
	int ACTION_MODIFY_LAND_COVER_A <- 2;
	int ACTION_MODIFY_LAND_COVER_U <- 3;
	int ACTION_MODIFY_LAND_COVER_N <- 4;
	int ACTION_MODIFY_LAND_COVER_AUs <-31;	
	int ACTION_MODIFY_LAND_COVER_Us <-32;
	int ACTION_MODIFY_LAND_COVER_Ui <-311;
	int ACTION_EXPROPRIATION <- 9999; // codification spéciale car en fait le code n'est utilisé que pour aller chercher le delai d'exection dans le fichier csv
	int ACTION_ACTION_DONE_UPDATE<- 101;
	int ACTION_ACTION_LIST <- 211;
	int ACTION_DONE_APPLICATION_ACKNOWLEDGEMENT <- 51;
	
	bool is_shown_protected_area <- false;
	bool is_shown_flooded_area <- false;
	
	int ACTION_LAND_COVER_UPDATE<-9;
	int ACTION_DIKE_UPDATE<-10;
	int INFORM_ROUND <-34;
	int NOTIFY_DELAY <-35;
	int ENTITY_TYPE_CODE_DEF_COTE <-36;
	int ENTITY_TYPE_CODE_UA <-37;
	
	//action to acknwoledge client requests.
	int ACTION_DIKE_CREATED <- 16;
	int ACTION_DIKE_DROPPED <- 17;
	int UPDATE_BUDGET <- 19;
	int REFRESH_ALL <- 20;
	int ACTION_DIKE_LIST <- 21;
	int CONNECTION_MESSAGE <- 23;
	int INFORM_TAX_GAIN <-24;
	int ACTION_INSPECT_DIKE <- 25;
	int ACTION_INSPECT_LAND_USE <-26;
	int INFORM_GRANT_RECEIVED <-27;
	int INFORM_FINE_RECEIVED <-28;
	
	// Leviers from leader
	int SUBVENTIONNER_GANIVELLE <- 1101;
	int SUBVENTIONNER_HABITAT_ADAPTE <- 1102;
	int SANCTION_ELECTORALE <- 1103;
	int HAUSSE_COUT_DIGUE <- 1104;
	int HAUSSE_REHAUSSEMENT_DIGUE <- 1105;
	int HAUSSE_RENOVATION_DIGUE <- 1106;
	int HAUSSE_COUT_BATI <- 1107;
	string ACTION_ID <- "action_id";
	string LEADER_COMMAND <- "leader_command";
	string DATA <- "data";
	string PLAYER_MSG <-"player_msg";
	
	//// action display map layers
	int ACTION_DISPLAY_PROTECTED_AREA <- 33;
	int ACTION_DISPLAY_FLOODED_AREA <- 38;
	
	// User messages
	string MSG_POSSIBLE_REGLEMENTATION_DELAY <- "La zone de travaux est soumise à des contraintes réglementaires.\nLe dossier est susceptible d’être retardé.\nSouhaitez vous poursuivre ?";
	string INFORMATION_MESSAGE <- "INFORMATION_MESSAGE";
	string BUDGET_MESSAGE <- "BUDGET_MESSAGE";
	string POPULATION_MESSAGE <- "POPULATION_MESSAGE";
	
	
	geometry shape <- envelope(emprise);// 1000#m around envelope(communes_UnAm_shape)  ;
	geometry local_shape <- nil; // envelope(emprise_local);
	
	string COMMAND_SEPARATOR <- ":";
	string GROUP_NAME <- "Oleron";
	
	list<float> basket_location <- [];
	
	int BASKET_MAX_SIZE <- 7;
	
	string UNAM_DISPLAY <- "UnAm";
	string DIKE_DISPLAY <- "sloap";
	string BOTH_DISPLAY <- "both";
	bool is_active_gui <-true;

	int MAX_HISTORY_VIEW_SIZE <- 10;
	
	
	string active_display <- UNAM_DISPLAY;
	action_done current_action <- nil;
	point previous_clicked_point <- nil;
	
	float button_size <- 500#m;
	
	float widX;
	float widY;
	
	
	float a <- 1000 update: a+100;// a priori on peut enlever cette declaration car a est declare a nouveau dan la methode où c est utilisé
	
	//  Attributes of the Commune
	int budget <- 0;
	int minimal_budget <- -2000;
	int impot_recu <- 0;
	// 0.42 correspond à  21 € / hab convertit au taux de la monnaie du jeu (le taux est de 50)   // comme construire une digue dans le jeu vaut 20 alors que ds la réalité ça vaut 1000 , -> facteur 50  -> le impot_unit = 21/50= 0.42 
	// Ajustement pour réduire un peu les écarts -> 0.42 de base et 0.38 pour stpierre et 0.9 pour sttrojan
	float impot_unit <- commune_name="stpierre"?0.38:(commune_name="sttrojan"?0.9:0.42);
	bool subvention_habitat_adapte <- false;
	bool subvention_ganivelle <- false;
	int previous_population;
	int current_population -> {UA sum_of (each.population)};
	list<action_done> my_basket<-[];
	
	UA explored_cell <- nil;
	def_cote explored_dike <- nil;
	action_UA explored_action_UA<- nil;
		
	buttons explored_buttons <- nil;
	
	geometry population_area <- nil;
	
	commune my_commune <- nil;

	network_player game_manager <-nil;
	point INFORMATION_BOX_SIZE <- {200,80};
	geometry dike_shape_space <- nil;
	geometry unam_shape_space <- nil;
	
	list<action_done> ordered_action <- nil;
	list<action_done> my_history<-[] update: ordered_action where(each.is_sent); //reverse((action_UA where(each.is_sent) + action_def_cote where(each.is_sent) ) sort_by(each.id));
	
	basket game_basket <-nil;
	console game_console <-nil;
	work_in_progress_list game_history <- nil; 

	action_done highlight_action;
	
	init
	{
		/*
		 * ajout 
		 * 
		 */
		 is_active_gui <- true;
		create work_in_progress_left_icon number:1
		{
			point p <- {0.075,0.5};
			do lock_agent_at ui_location:p display_name:"Dossiers" ui_width:0.15 ui_height:1.0 ; // OU 0.1
		}
		create console_left_icon number:1
		{
			point p <- {0.075,0.5};
			do lock_agent_at ui_location:p display_name:"Messages" ui_width:0.15 ui_height:1.0 ;
		}
		
		create basket number:1 returns:lbsk;
		game_basket <- first(lbsk);
		create console number:1 returns:lcons;
		game_console <- first(lcons);
		create work_in_progress_list number:1 returns:workInPro;
		game_history <- first(workInPro);
		
		
		create data_retrieve number:1;
		create network_activated_lever number:1;
		do init_background;
		do implementation_tests;
		my_commune <-  commune first_with(each.commune_name = commune_name);
		create network_player number:1 returns:net;
		game_manager <- first(net);
		create network_player_new number:1 ;
		create network_listen_to_leader number:1;
		create commune from: communes_shape with:[commune_name::string(read("NOM_RAC"))];
		my_commune <- commune first_with(each.commune_name = commune_name);
		local_shape <-envelope(my_commune);
		do init_buttons;
		create def_cote from:defense_shape with:[dike_id::int(read("OBJECTID")),type::string(read("Type_de_de")),status::string(read("Etat_ouvr")), alt::float(read("alt")), height::float(get("hauteur")) , commune_name_shpfile::string(read("Commune"))];
		create road from:road_shape;
		create protected_area from: zone_protegee_shape with: [name::string(read("SITENAME"))];
		create flood_risk_area from: zone_PPR_shape;
		create sites_non_classes_area from: sites_non_classes_area_shape;
		switch (commune_name)
			{
			match "lechateau" {commune_name_shpfile <-"Le-Chateau-d'Oleron";}
			match "dolus" {commune_name_shpfile <-"Dolus-d'Oleron";}
			match "sttrojan" {commune_name_shpfile <-"Saint-Trojan-Les-Bains";}
			match "stpierre" {commune_name_shpfile <-"Saint-Pierre-d'Oleron";}
			} 
		ask def_cote where(each.commune_name_shpfile != commune_name_shpfile)
			{ do die; }
		ask def_cote {do init_dike;}
		create UA from: communes_UnAm_shape with: [id::int(read("FID_1")),ua_code::int(read("grid_code")), population:: int(get("Avg_ind_c"))/*, cout_expro:: int(get("coutexpr"))*/]
		{
			ua_name <- nameOfUAcode(ua_code);
			//cout_expro <- (round (cout_expro /2000 /50))*100; //50= tx de conversion Euros->Boyard on divise par 2 la valeur du cout expro car elle semble surévaluée
			if ua_name = "U" and population = 0 {
					population <- 10;}
			my_color <- cell_color(); 
			
		}
		ask UA where(!(each overlaps my_commune))
		{
			do die;
		}
		//buffer(a_geometry,a_float)
		//population_area <- smooth(union((cell_UnAm where(each.land_cover = "U" or each.land_cover = "AU")) collect (buffer(each.shape,100#m))),0.1);
		population_area <- union(UA where(each.ua_name = "U" or each.ua_name = "AU"));
		
		previous_population <- current_population();
		
		list<geometry> tmp <- buttons collect(each.shape) accumulate my_commune.shape;
		dike_shape_space <- envelope(tmp);
		
	//	population_area <- smooth(union(cell_UnAm where(each.land_cover = "U" or each.land_cover = "AU")),0.001); 
	}	
	user_command "Refresh all the map"
	{
		write "start refresh all";
		
		ask data_retrieve
		{
			do clear_simulation();
		}
		string msg <- ""+REFRESH_ALL+COMMAND_SEPARATOR+world.get_action_id()+COMMAND_SEPARATOR+commune_name;
		ask game_manager 
		{
			map<string,string> data <- ["stringContents"::msg];
			do send to:GAME_MANAGER contents:data;
		}
	}
	
	point button_box_location(point my_button, int box_width)
	{
		if(world.shape.width*0.6>my_button.x)
		{
			
			return point({min([my_button.x+box_width,world.shape.width-10#px]),my_button.y});
		}

		return my_button;
	}
	
	
//	action change_subvention_habitat_adapte_with (bool newValue) {
//		subvention_habitat_adapte <- newValue;
//		if subvention_habitat_adapte {
//			ask buttons where (each.command = ACTION_MODIFY_LAND_COVER_AUs)
//				{	action_cost <- ACTION_COST_LAND_COVER_TO_AUs_SUBSIDY;
//					label <- "Changer en zone urbanisée adaptée (Subventionné).";
//				}
//			ask world {do user_msg("L'habitat adapté est à présent subventionné : "+ACTION_COST_LAND_COVER_TO_AUs_SUBSIDY+ " au lieu de "+ACTION_COST_LAND_COVER_TO_AUs);}
//		}
//		else {
//			ask buttons where (each.command = ACTION_MODIFY_LAND_COVER_AUs)
//				{	action_cost <- ACTION_COST_LAND_COVER_TO_AUs;
//					label <- "Changer en zone urbanisée adaptée.";
//				}
//			ask world {do user_msg("L'habitat adapté n'est plus subventionné : "+ACTION_COST_LAND_COVER_TO_AUs+ " au lieu de "+ACTION_COST_LAND_COVER_TO_AUs_SUBSIDY);}
//		}	
//	}
//	
//	action change_subvention_ganivelle_with (bool newValue) {
//		subvention_ganivelle <- newValue;
//		if subvention_ganivelle {
//			ask buttons where (each.command = ACTION_INSTALL_GANIVELLE)
//				{	action_cost <- ACTION_COST_INSTALL_GANIVELLE_SUBSIDY;
//					label <- "Installer des ganivelles (Subventionné).";
//				}
//			ask world {do user_msg("L'installation de ganivelles est à présent subventionné : "+ACTION_COST_INSTALL_GANIVELLE_SUBSIDY+ " au lieu de "+ACTION_COST_INSTALL_GANIVELLE);}
//		}
//		else {
//			ask buttons where (each.command = ACTION_INSTALL_GANIVELLE)
//				{	action_cost <- ACTION_COST_INSTALL_GANIVELLE;
//					label <- "Installer des ganivelles.";
//				}
//			ask world {do user_msg("L'installation de ganivelles n'est plus subventionné : "+ACTION_COST_INSTALL_GANIVELLE+ " au lieu de "+ACTION_COST_INSTALL_GANIVELLE_SUBSIDY);}
//		}	
//	}
	
	int id_number_of_action_id (string act_id)
	{
		if act_id = "" {return 0;}
		else {return int((act_id split_with "_")[1]);}
		
	}
	

	
	string get_action_id
	{
		list<int> x1 <- action_def_cote collect(id_number_of_action_id(each.id));
		list<int> x2 <- action_UA collect(id_number_of_action_id(each.id));
		return commune_name + "_"+(max(x1 + x2) + 1);
	}

	int delayOfAction (int action_code){
		//peut-etre convertir en map.... A modifier mais plus tard
		int rslt <- 9999;
		loop i from:0 to: length(all_action_delay)/3 {
			if ((int(all_action_delay at {1,i})) = action_code)
			 {rslt <- int(all_action_delay at {2,i});}
		}
		return rslt;
	}	
	
	int current_population {
		return sum(UA accumulate (each.population));
	}
	

	action implementation_tests {
		 if (int(all_action_cost at {0,0}) != 0 or (int(all_action_cost at {0,5}) != 5)) {
		 		write "BUG: Probleme lecture du fichier cout_action";
		 		write ""+all_action_cost;
		 }
	}
	
	
	image_file chooseActionIcone(int cmd)
	{
		
		switch(cmd)
		{
			match ACTION_MODIFY_LAND_COVER_A { return image_file("../images/ihm/S_agricole.png");}
			match ACTION_MODIFY_LAND_COVER_AU { return image_file("../images/ihm/S_urbanise.png");}
			match ACTION_MODIFY_LAND_COVER_AUs { return image_file("../images/ihm/S_urbanise_adapte.png");}
			match ACTION_MODIFY_LAND_COVER_Us { return image_file("../images/ihm/S_urbanise_adapte.png");}
			match ACTION_MODIFY_LAND_COVER_Ui { return image_file("../images/ihm/S_urbanise_intensifie.png");}
			match ACTION_MODIFY_LAND_COVER_N { return image_file("../images/ihm/S_naturel.png");}
			match ACTION_CREATE_DIKE { return image_file("../images/ihm/S_creation_digue.png");}
			match ACTION_REPAIR_DIKE { return image_file("../images/ihm/S_reparation_digue.png");}
			match ACTION_RAISE_DIKE { return image_file("../images/ihm/S_elevation_digue.png");}
			match ACTION_DESTROY_DIKE { return image_file("../images/ihm/S_suppression_digue.png");}
			match ACTION_INSTALL_GANIVELLE { return image_file("../images/ihm/S_ganivelle.png");}
		}
		return nil;
	}
	
	image_file au_icone(UA mc)
	{
		string val<-"";
		if(mc.isEnDensification)
		{
			return image_file("../images/icones/urban_intensifie.png");
		}
		
		switch(mc.ua_code)
		{
			match 1 {return image_file("../images/icones/tree_nature.png");}
			match 2 {return image_file("../images/icones/urban.png");}
			match 4 {return image_file("../images/icones/urban.png");}
			match 5 {return image_file("../images/icones/agriculture.png");}
			match 6 {return image_file("../images/icones/urban_adapte2.png");}
			match 7 {return image_file("../images/icones/urban_adapte2.png");}
		}
		return nil;
	}
	
	action init_background
	{
		float increment <- "stpierre" = commune_name ? 0.8:0.0;
		
		create onglet number:1
		{
			point p <- {0.25,increment+0.03};
			legend_name <- LEGEND_DYKE;
			display_name <- DIKE_DISPLAY;
			do lock_agent_at ui_location:p display_name:"Carte" ui_width:0.5 ui_height: (0.06);
		}
		create onglet number:1
		{
			point p <- {0.75,increment+0.03};
			legend_name <-LEGEND_UNAM;
			display_name <- UNAM_DISPLAY;
			do lock_agent_at ui_location:p display_name:"Carte" ui_width:0.5 ui_height: ( 0.06);
		}	
		
		create background_agent number:1
		{
			point p <- {0.0,0};
			do lock_agent_at ui_location:p display_name:"Carte" ui_width:1 ui_height:1;
		}
	}
	
	action init_buttons
	{
		float interleave <- world.local_shape.height / 20;
		float button_s <- world.local_shape.height / 10;
		
		string uaHelpMessage <- "Cliquez sur la cellule à modifier.";
		string dikeHelpMessage <- "Cliquez sur la digue à modifier.";
		float increment <- "stpierre" = commune_name ? 0.8:0.0;
			
		create buttons number: 1
		{
			command <- ACTION_MODIFY_LAND_COVER_A;
			label <- "Changer en zone agricole";
			action_cost <- ACTION_COST_LAND_COVER_TO_A;
			display_name <- UNAM_DISPLAY;
			my_help <- uaHelpMessage;
			point p <- {0.40,increment+0.13};
			do lock_agent_at ui_location:p display_name:"Carte" ui_width:0.1 ui_height:0.1;
			shape <- square(button_size);
			location <- { world.local_shape.location.x+ (world.local_shape.width /2) + world.local_shape.width/5, world.local_shape.location.y - (world.local_shape.height /2) +interleave}; // + world.local_shape.width - 500#m,world.local_shape.location.y + 350#m };
			my_icon <- image_file("../images/ihm/I_agricole.png");
		}

		create buttons number: 1
		{
			command <- ACTION_MODIFY_LAND_COVER_AU;
			label <- "Changer en zone à urbaniser";
			action_cost <- ACTION_COST_LAND_COVER_TO_AU;
			shape <- square(button_size);
			display_name <- UNAM_DISPLAY;
			my_help <- uaHelpMessage;
			point p <- {0.05,increment+0.13};
			do lock_agent_at ui_location:p display_name:"Carte" ui_width:0.1 ui_height:0.1;
			location <- { world.local_shape.location.x+ (world.local_shape.width /2) + world.local_shape.width/5, world.local_shape.location.y - (world.local_shape.height /2) +interleave + interleave+ button_size }; //{  world.local_shape.location.x + world.local_shape.width - 500#m,world.local_shape.location.y + 350#m + 600#m };
			my_icon <- image_file("../images/ihm/I_urbanise.png");
		}
		
		create buttons number: 1
		{
			command <- ACTION_MODIFY_LAND_COVER_AUs;
			label <- "Changer en zone urbanisée adaptée";
			action_cost <- ACTION_COST_LAND_COVER_TO_AUs;
			my_help <- uaHelpMessage;
			shape <- square(button_size);
			display_name <- UNAM_DISPLAY;
			point p <- {0.15,increment+0.13};
			do lock_agent_at ui_location:p display_name:"Carte" ui_width:0.1 ui_height:0.1;
			
			location <- { world.local_shape.location.x+ (world.local_shape.width /2) + world.local_shape.width/5 + 2*interleave, world.local_shape.location.y - (world.local_shape.height /2) +2*interleave + button_size }; //{  world.local_shape.location.x + world.local_shape.width - 500#m,world.local_shape.location.y + 350#m + 600#m };
			my_icon <- image_file("../images/ihm/I_urbanise_adapte.png");
		}
		
		create buttons number: 1
		{
			command <- ACTION_MODIFY_LAND_COVER_Ui;
			label <- "Inciter à la densification";
			action_cost <- ACTION_COST_LAND_COVER_TO_Ui;
			my_help <- uaHelpMessage;
			shape <- square(button_size);
			display_name <- UNAM_DISPLAY;
			point p <- {0.25,increment+0.13};
			do lock_agent_at ui_location:p display_name:"Carte" ui_width:0.1 ui_height:0.1;
			
			location <- { world.local_shape.location.x+ (world.local_shape.width /2) + world.local_shape.width/5 + 4*interleave, world.local_shape.location.y - (world.local_shape.height /2) +2*interleave + button_size }; //{  world.local_shape.location.x + world.local_shape.width - 500#m,world.local_shape.location.y + 350#m + 600#m };
			my_icon <- image_file("../images/ihm/I_urbanise_intensifie.png");
		}
		
		
		create buttons number: 1
		{
			command <- ACTION_MODIFY_LAND_COVER_N;
			label <- "Changer en zone naturelle";
			action_cost <- ACTION_COST_LAND_COVER_FROM_AU_TO_N;
			shape <- square(button_size);
			display_name <- UNAM_DISPLAY;
			my_help <- uaHelpMessage;
			point p <- {0.50,increment+0.13};
			do lock_agent_at ui_location:p display_name:"Carte" ui_width:0.1 ui_height:0.1;
			location <- { world.local_shape.location.x+ (world.local_shape.width /2) + world.local_shape.width/5, world.local_shape.location.y - (world.local_shape.height /2) +interleave +2* (interleave+ button_size) };
			my_icon <- image_file("../images/ihm/I_naturel.png");
			
		}
		create buttons number: 1
		{
			command <- ACTION_INSPECT_LAND_USE;
			label <- "Inspecter une unité d'aménagement";
			action_cost <- 0;
			my_help <- "Glissez le pointeur sur les cellules à inspecter.";
			shape <- square(button_size);
			display_name <- UNAM_DISPLAY;
			point p <- {0.70,increment+0.13};
			do lock_agent_at ui_location:p display_name:"Carte" ui_width:0.1 ui_height:0.1;
			location <- { world.local_shape.location.x+ (world.local_shape.width /2) + world.local_shape.width/5, world.local_shape.location.y - (world.local_shape.height /2) +interleave +3* (interleave+ button_size) };
			my_icon <- image_file("../images/ihm/I_info.png");
			
		}
		
		create buttons number: 1
		{
			command <- ACTION_CREATE_DIKE;
			label <- "Construire une digue";
			action_cost <- ACTION_COST_DIKE_CREATE;
			shape <- square(button_size);
			display_name <- DIKE_DISPLAY;
			my_help <- "Cliquez aux deux extrémités du linéaire de digue.";
			point p <- {0.05,increment+0.13};
			do lock_agent_at ui_location:p display_name:"Carte" ui_width:0.1 ui_height:0.1;
			location <- { world.local_shape.location.x+ (world.local_shape.width /2) + world.local_shape.width/5, world.local_shape.location.y - (world.local_shape.height /2) +interleave  }; // + world.local_shape.width - 500#m,world.local_shape.location.y + 350#m };
			my_icon <- image_file("../images/ihm/i_creation_digue.png");
		}

		create buttons number: 1
		{
			command <- ACTION_REPAIR_DIKE;
			label <- "Rénover une digue";
			action_cost <- ACTION_COST_DIKE_REPAIR;
			shape <- square(button_size);
			my_help <- dikeHelpMessage;
			display_name <- DIKE_DISPLAY;
			point p <- {0.15,increment+0.13};
			do lock_agent_at ui_location:p display_name:"Carte" ui_width:0.1 ui_height:0.1;
			location <- { world.local_shape.location.x+ (world.local_shape.width /2) + world.local_shape.width/5, world.local_shape.location.y - (world.local_shape.height /2) +interleave + 2*(interleave+ button_size) }; //{  world.local_shape.location.x + world.local_shape.width - 500#m,world.local_shape.location.y + 350#m + 600#m };
			my_icon <- image_file("../images/ihm/I_reparation_digue.png");
			
		}

		create buttons number: 1
		{
			command <- ACTION_DESTROY_DIKE;
			label <- "Démenteler une digue";
			action_cost <- ACTION_COST_DIKE_DESTROY;
			shape <- square(button_size);
			my_help <- dikeHelpMessage;
			display_name <- DIKE_DISPLAY;
		//	my_help <- "Cliquer sur la digue à supprimer";	
			point p <- {0.35,increment+0.13};
			do lock_agent_at ui_location:p display_name:"Carte" ui_width:0.1 ui_height:0.1;
			
			location <- { world.local_shape.location.x+ (world.local_shape.width /2) + world.local_shape.width/5, world.local_shape.location.y - (world.local_shape.height /2) +interleave +3* (interleave+ button_size) };
			my_icon <- image_file("../images/ihm/I_suppression_digue.png");
			
		}
		
		create buttons number: 1
		{
			command <- ACTION_RAISE_DIKE;
			label <- "Réhausser une digue";
			action_cost <- ACTION_COST_DIKE_RAISE;
			shape <- square(button_size);
			my_help <- dikeHelpMessage;
			display_name <- DIKE_DISPLAY;
		//	my_help <- "Cliquer sur la digue à réhausser";
			point p <- {0.25,increment+0.13};
			do lock_agent_at ui_location:p display_name:"Carte" ui_width:0.1 ui_height:0.1;
			location <- { world.local_shape.location.x+ (world.local_shape.width /2) + world.local_shape.width/5, world.local_shape.location.y - (world.local_shape.height /2) +interleave +1* (interleave+ button_size) };
			my_icon <- image_file("../images/ihm/I_elevation_digue.png");
			
		}
		
		create buttons number: 1
		{
			command <- ACTION_INSTALL_GANIVELLE;
			label <- "Installer des ganivelles";
			action_cost <- ACTION_COST_INSTALL_GANIVELLE;
			shape <- square(button_size);
			display_name <- DIKE_DISPLAY;
			my_help <- "Cliquez sur la dune pour installer une ganivelle.";
			point p <- {0.45,increment+0.13};
			do lock_agent_at ui_location:p display_name:"Carte" ui_width:0.1 ui_height:0.1;
			location <- { world.local_shape.location.x+ (world.local_shape.width /2) + world.local_shape.width/5, world.local_shape.location.y - (world.local_shape.height /2) +interleave+4* (interleave+ button_size)};
			my_icon <- image_file("../images/ihm/I_ganivelle.png");
		}
		
		create buttons number: 1
		{
			command <- ACTION_INSPECT_DIKE;
			label <- "Inspecter un ouvrage de défense";
			action_cost <- 0;
			shape <- square(button_size);
			my_help <- "Glissez le pointeur sur les digues et dunes.";
			display_name <- DIKE_DISPLAY;
			point p <- {0.70,increment+0.13};
			do lock_agent_at ui_location:p display_name:"Carte" ui_width:0.1 ui_height:0.1;
			location <- { world.local_shape.location.x+ (world.local_shape.width /2) + world.local_shape.width/5, world.local_shape.location.y - (world.local_shape.height /2) +interleave +5* (interleave+ button_size) };
			my_icon <- image_file("../images/ihm/I_info.png");
			
		}

		create buttons_map number: 1
		{
			command <- ACTION_DISPLAY_PROTECTED_AREA;
			label <- "Afficher les zones proétégées";
			display_name <-BOTH_DISPLAY;
			shape <- square(850);
			location <- { 1000,8000 };
			point p <- {0.80,increment+0.13};
			do lock_agent_at ui_location:p display_name:"Carte" ui_width:0.1 ui_height:0.1;
			
			my_icon <- image_file("../images/ihm/I_afficher_zone_protegee.png");
			is_selected <- false;
		}	
		create buttons_map number: 1
		{
			command <- ACTION_DISPLAY_FLOODED_AREA;
			label <- "Afficher les zones innondées";
			display_name <-BOTH_DISPLAY;
			
			shape <- square(850);
			location <- { 1000,9000 };
			point p <- {0.90,increment+0.13};
			do lock_agent_at ui_location:p display_name:"Carte" ui_width:0.1 ui_height:0.1;
			
			my_icon <- image_file("../images/ihm/I_afficher_PPR.png");
			is_selected <- false;
		}
	}
	
	


	bool basket_overflow
	{
		if(BASKET_MAX_SIZE = length(my_basket))
		{
			map<string,unknown> values2 <- user_input("Avertissement","Vous avez atteint la capacité maximum de votre panier, veuillez valider votre panier avant de continuer"::true);
			return true;
		}
		return false;
	}
	
	action button_click_general
	{
		point loc <- #user_location;
		list<onglet> clicked_onglet_button <- (onglet overlapping loc);
		
		
		if(length(clicked_onglet_button)>0)
		{
			active_display <- first(clicked_onglet_button).display_name;
			do clear_selected_button;
			explored_buttons <- nil;
			explored_cell <- nil;
			explored_dike <- nil;
			explored_action_UA<- nil;
			current_action <- nil;
		}
		
		if(!show_hide_maps_click())
		{
			if(active_display = UNAM_DISPLAY)
			{
				do button_click_UnAM;
			}
			else
			{
				do button_click_dike;
			}
				
		}
		
		
	}
	bool show_hide_maps_click
	{
		point loc <- #user_location;
		list<buttons> cliked_button <- (buttons where(each.display_name=BOTH_DISPLAY )) overlapping loc   ;
		if(length(cliked_button)>0)
		{
			buttons a_map_buton <- first(cliked_button);
			is_shown_protected_area <- false;
			is_shown_flooded_area <- false;
	
			switch a_map_buton.command {
						match ACTION_DISPLAY_PROTECTED_AREA {
							is_shown_protected_area <- true;
						}
						match ACTION_DISPLAY_FLOODED_AREA {
							is_shown_flooded_area <- false;
						}
					}			
			return true;
		}
		return false;
		
	}
	
	
	
	action mouse_move_general
	{
		switch(active_display)
		{
			match UNAM_DISPLAY { do mouse_move_UnAM; }
			match DIKE_DISPLAY {do mouse_move_dike;}
		}
	}
	
	action mouse_move_UnAM //(point loc, list selected_agents)
	{
		do mouse_move_buttons_unam();
		point loc <- #user_location;
		list<buttons> current_active_button <- buttons where (each.is_selected);
		if (length (current_active_button) = 1 and first (current_active_button).command = ACTION_INSPECT_LAND_USE)
		{
			list<action_UA> selected_explored_action_UA <- action_UA overlapping loc;
			
			if(length(selected_explored_action_UA)>0)
			{
				explored_action_UA <-first(selected_explored_action_UA);
			}
			else
			{
				explored_action_UA <-nil;
			}
			
			
			list<UA> selectedUnams <- UA overlapping loc; // of_species cell_UnAm;
			if (length(selectedUnams)> 0) 
			{
				explored_cell <- first(selectedUnams);
			}
			else
			{
				explored_cell <- nil;
			}
		}
		else
		{
			explored_cell <- nil;
		}
	}

	action mouse_move_dike//(point loc, list selected_agents)
	{
		do mouse_move_buttons_dyke();
		point loc <- #user_location;
		
		list<buttons> current_active_button <- buttons where (each.is_selected);
		if (length (current_active_button) = 1 and first (current_active_button).command = ACTION_INSPECT_DIKE)
		{
			list<def_cote> selected_dike <- def_cote overlapping (loc buffer(100#m)); //selected_agents of_species dike ; // of_species cell_UnAm;
			if (length(selected_dike)> 0) 
			{
				explored_dike <- first(selected_dike);
			}
			else
			{
				explored_dike <- nil;
			}
		}
		else
		{
			explored_dike <- nil;
		}
	}


	action mouse_move_buttons_dyke
	{
		point loc <- #user_location;
		explored_buttons <- buttons first_with (each overlaps loc and each.display_name=DIKE_DISPLAY);
	}
	
	action mouse_move_buttons_unam
	{
		point loc <- #user_location;
		explored_buttons <- buttons first_with (each overlaps loc and each.display_name!=DIKE_DISPLAY);
	}
	
	action change_dike// (point loc, list selected_agents)
	{
		point loc <- #user_location;
		
		list<def_cote> selected_dike <-   def_cote where (each distance_to loc < MOUSE_BUFFER); // agts of_species dike;
		
		if(basket_overflow())
		{
			return;
		}
		buttons selected_button <- buttons first_with(each.is_selected);
		if(selected_button != nil)
		{
			switch(selected_button.command)
			{
				match ACTION_CREATE_DIKE { do create_new_dike(loc,selected_button);}
				match ACTION_INSPECT_DIKE {/*NE RIEN FAIRE do inspect_dike(loc,selected_dike,selected_button);*/}
				default {
					do modify_dike(loc, selected_dike,selected_button);
				}
			}
		}
	}
	action modify_dike(point mloc, list<def_cote> agts, buttons but)
	{
		list<def_cote> selected_dike <- agts ;
		
		if(length(selected_dike)>0)
		{
			def_cote dk<- selected_dike closest_to mloc;
			if(dk.type ="Naturel" and but.command in [ ACTION_REPAIR_DIKE , ACTION_CREATE_DIKE , ACTION_DESTROY_DIKE , ACTION_RAISE_DIKE])
				{	// Action incohérente -> NE RIEN FAIRE 
					return;		
				}
			if(dk.type != "Naturel" and but.command in [ ACTION_INSTALL_GANIVELLE ])
				{	// Action incohérente -> NE RIEN FAIRE 
					return;
				}
			create action_def_cote number:1 returns:action_list
			 {
				
				id <- world.get_action_id();
				self.label <- but.label;
				element_id <- dk.dike_id;
				self.command <- but.command;
				self.initial_application_round <- round  + (world.delayOfAction(self.command));
				element_shape <- dk.shape;
				shape <- element_shape+shape_width;//shape_width around element_shape;
				cost <- but.action_cost*shape.perimeter;
			 }
			previous_clicked_point <- nil;
			current_action<- first(action_list);
			if but.command = ACTION_RAISE_DIKE {
				if  !empty(protected_area where (each intersects current_action.shape))
				{
					current_action.inProtectedArea <- true;
					string chain <- MSG_POSSIBLE_REGLEMENTATION_DELAY;
					map<string,bool> values2 <- user_input(chain::true);
					if (!(values2 at chain)) {
						ask current_action{do die;}
						return;
					}
				}
			}
			my_basket <- my_basket + current_action; 
			ordered_action <- ordered_action + current_action;
			ask(game_basket)
			{
				do  add_action_in_basket(current_action);
			}	
		}
	}
	
	action create_new_dike(point loc,buttons but)
	{
		if(previous_clicked_point = nil)
		{
			previous_clicked_point <- loc;
		}
		else
		{
				create action_def_cote number:1 returns:action_list
				{
					id <- world.get_action_id();
					self.label <- but.label;
					element_id <- -1;
					self.command <- ACTION_CREATE_DIKE;
					self.initial_application_round <- round  + (world.delayOfAction(self.command));
					element_shape <- polyline([previous_clicked_point,loc]);
					shape <-  element_shape+shape_width;//shape_width around element_shape;
					cost <- but.action_cost*shape.perimeter; 
				}
				previous_clicked_point <- nil;
				current_action<- first(action_list);
				if  !empty(protected_area overlapping (current_action.shape))
				{
					current_action.inProtectedArea <- true;
					string chain <- MSG_POSSIBLE_REGLEMENTATION_DELAY;
					map<string,bool> values2 <- user_input(chain::true);
					if (!(values2 at chain)) {
						ask current_action{do die;}
						do clear_selected_button;
						return;
					}
				}
				my_basket <- my_basket + current_action; 
				ordered_action <- ordered_action + current_action;
				ask(game_basket)
				{
					do  add_action_in_basket(current_action);
				}	
				do clear_selected_button;
		}
		
	}


	action change_plu 
	{
		point loc <- #user_location;
		if(basket_overflow())
		{
			return;
		}
		buttons selected_button <- buttons first_with(each.is_selected);
		if(selected_button != nil)
		{
			list<UA> selected_UnAm <- UA where (each distance_to loc < MOUSE_BUFFER); //selected_agents of_species cell_UnAm;
			UA cell_tmp <- selected_UnAm closest_to loc;
			ask (cell_tmp)
			{
				if(selected_button.command = ACTION_INSPECT_LAND_USE)
				{	//NE RIEN FAIRE SI ON CLIC AVEC L'OUTIL LOUPE
					return;		
				}
				if((ua_name ="N" and selected_button.command = ACTION_MODIFY_LAND_COVER_N)
					or (ua_name ="A" and selected_button.command = ACTION_MODIFY_LAND_COVER_A)
					or (ua_name in["U","AU"] and selected_button.command = ACTION_MODIFY_LAND_COVER_AU)
					or (ua_name in["A", "N", "AUs","Us"] and selected_button.command = ACTION_MODIFY_LAND_COVER_AUs)
					or (ua_name in ["A", "N", "AU","AUs"] and selected_button.command = ACTION_MODIFY_LAND_COVER_Ui)
					or (length((action_done collect(each.location)) inside cell_tmp)>0  ))
				{	// Action incohérente -> la case est déjà dans l'état souhaité
					return;
				}
			
				if(ua_name in ["U","Us"] and selected_button.command = ACTION_MODIFY_LAND_COVER_A)
				{
					bool res<-false;
					string chain <- "Transformer une zone urbaine en zone agricole n'est pas autorisé.\nVous pouvez la transformer en zone naturelle.";
					map<string,unknown> values2 <- user_input("Avertissement",chain::"");		
					
					return;
				}
				if(ua_name in ["U","Us"] and selected_button.command = ACTION_MODIFY_LAND_COVER_N)
				{
					bool res <- false;
					string chain <- "Vous allez entamer une procédure d'expropriation.\nSouhaitez-vous continuer ?";
					map<string,unknown> values2 <- user_input("Avertissement",chain:: res);		
					if(values2 at chain = false)
					{
						return;
					}
				}
				if(ua_name in ["AUs","Us"] and selected_button.command = ACTION_MODIFY_LAND_COVER_AU)
				{
					bool res<-false;
					string chain <- "Impossible de supprimer un habitat adapté";
					map<string,unknown> values2 <- user_input("Avertissement",chain::"");		
					
					return;
				}
				if (ua_name in ["A","N"] and selected_button.command in [ACTION_MODIFY_LAND_COVER_AU, ACTION_MODIFY_LAND_COVER_AUs])
				{
					if empty(UA at_distance 100 where (each.isUrbanType))
					{	string chain <- "Impossible de construire en dehors d'une périphérie urbaine";
						map<string,unknown> values2 <- user_input("Avertissement",chain::"");
						return;
					}
					if (!empty(protected_area where (each intersects (circle(10,shape.centroid)))))
					{	string chain <- "Construire en zone protégée n'est pas autorisé par la législation";
						map<string,unknown> values2 <- user_input("Avertissement",chain::"");
						return;
					}
					if (empty(sites_non_classes_area where (each intersects (circle(10,shape.centroid)))))
					{	string chain <- "Cette parcelle est en dehors de la limite d'expansion urbaine autorisée par les sites classés.";
						map<string,unknown> values2 <- user_input("Avertissement",chain::"");
						return;
					}
				}
				if(ua_name = "N" and selected_button.command in [ACTION_MODIFY_LAND_COVER_AU, ACTION_MODIFY_LAND_COVER_AUs])
				{
					bool res <- false;
					string chain <- "Transformer une zone naturelle en zone à urbaniser est soumis à des contraintes réglementaire.\nLe dossier est susceptible d’être retardé.\nSouhaitez vous poursuivre ?";
					map<string,unknown> values2 <- user_input("Avertissement",chain:: res);		
					if(values2 at chain = false)
					{
						return;
					}
				}
				
				if ((ua_name in ["U","Us"] and classe_densite = "dense") and (selected_button.command = ACTION_MODIFY_LAND_COVER_Ui))
				{	string chain <- "Cette unité urbaine est déjà à son niveau de densification maximum";
					map<string,unknown> values2 <- user_input("Avertissement",chain::"");
					return;	
				}
				
				create action_UA number:1 returns:action_list
				{
					id <- world.get_action_id();
					element_id <- myself.id;
					command <- selected_button.command;
					element_shape <- myself.shape;
					shape <- element_shape;
					initial_application_round <- round  + (world.delayOfAction(command));
					previous_ua_name <- myself.ua_name;
					label <- selected_button.label;
					cost <- selected_button.action_cost;
					// Overwrites in case action d'expropriation (delai d'execution et Cost)
					if command = ACTION_MODIFY_LAND_COVER_N and previous_ua_name in ["U","Us"] { 
							initial_application_round <- round + world.delayOfAction(ACTION_EXPROPRIATION);
							cost <- myself.cout_expro;
							isExpropriation <- true;} 
					//overwrite Cost in case A to N
					if(command = ACTION_MODIFY_LAND_COVER_N  and (previous_ua_name = "A")) 
						{cost <- ACTION_COST_LAND_COVER_FROM_A_TO_N;}
					//Check overwrites in case transform to AUs
					if (command = ACTION_MODIFY_LAND_COVER_AUs and (previous_ua_name = "U")) 
					{// overwrite command, label and cost in case transforming a U to Us
									command <-ACTION_MODIFY_LAND_COVER_Us;
									label <- "Changer en zone urbaine adaptée"+(subvention_habitat_adapte?"(Subventionné)":"");
									cost <- subvention_habitat_adapte?ACTION_COST_LAND_COVER_TO_Us_SUBSIDY:ACTION_COST_LAND_COVER_TO_Us;
					}
				}
				current_action<- first(action_list);
				my_basket <- my_basket + current_action; 
				ordered_action <- ordered_action + current_action;
				ask(game_basket)
				{
					do  add_action_in_basket(current_action);
				}	
			}
		}
	}
	

	action button_click_UnAM 
	{
		point loc <- #user_location;
		
		
		
		if(active_display != UNAM_DISPLAY)
		{
			current_action <- nil;
			active_display <- UNAM_DISPLAY;
			do clear_selected_button;
			//return;
		}
		list<buttons> cliked_UnAm_button <- (buttons where (each distance_to loc < MOUSE_BUFFER)) where(each.display_name=active_display );
		
		if(length(cliked_UnAm_button)>0)
		{
			list<buttons> current_active_button <- buttons where (each.is_selected);
			bool clic_deselect <- false;
			if length (current_active_button) > 1 {write "BUG: Problème -> deux boutons sélectionnés en même temps";}
			if length (current_active_button) = 1 
				{if (first (current_active_button)).command = (first(cliked_UnAm_button)).command
					{clic_deselect <-true;}}
			do clear_selected_button;
			if !clic_deselect 
				{ask (first(cliked_UnAm_button))
					{
					is_selected <- true;
					}
				}
			return;
		}
		else
		{ 	buttons_map a_MAP_button <- first (buttons_map where (each distance_to loc < MOUSE_BUFFER));
			if a_MAP_button != nil {
				ask a_MAP_button {
					is_selected <- not(is_selected);
					switch command {
						match ACTION_DISPLAY_PROTECTED_AREA {my_icon <-  !is_selected ? image_file("../images/ihm/I_desafficher_zone_protegee.png") :  image_file("../images/ihm/I_afficher_zone_protegee.png");}
						match ACTION_DISPLAY_FLOODED_AREA {my_icon <-  !is_selected ? image_file("../images/ihm/I_desafficher_PPR.png") :  image_file("../images/ihm/I_afficher_PPR.png");}
					}			
				}
			}
			else {do change_plu;}
			
		}
	}
	
	action button_click_dike 
	{
		point loc <- #user_location;
		if(active_display != DIKE_DISPLAY)
		{
			current_action <- nil;
			active_display <- DIKE_DISPLAY;
			do clear_selected_button;
			//return;
		}
		
		list<buttons> cliked_dike_button <- ( buttons where (each distance_to loc < MOUSE_BUFFER)) where(each.display_name=active_display );
	
		if( length(cliked_dike_button) > 0)
		{
			list<buttons> current_active_button <- buttons where (each.is_selected);
			do clear_selected_button;
			
			if (length (current_active_button) = 1 and (first (current_active_button)).command != (first(cliked_dike_button)).command) or length (current_active_button) = 0
			{
				ask (first(cliked_dike_button))
				{
					is_selected <- true;
				}
			}
		}
		else
		{	
			buttons_map a_MAP_button <- first (buttons_map where (each distance_to loc < MOUSE_BUFFER));
			if a_MAP_button != nil {
				ask a_MAP_button {
					is_selected <- not(is_selected);
					switch command {
						match ACTION_DISPLAY_PROTECTED_AREA {my_icon <-  is_selected ? image_file("../images/ihm/I_afficher_zone_protegee.png") :  image_file("../images/ihm/I_desafficher_zone_protegee.png");}
						match ACTION_DISPLAY_FLOODED_AREA {my_icon <-  is_selected ? image_file("../images/ihm/I_afficher_PPR.png") :  image_file("../images/ihm/I_desafficher_PPR.png");}
					}			
				}
			}
			else {
				do change_dike;
			}
		}

	}
	
	action clear_selected_button
	{
		previous_clicked_point <- nil;
		ask buttons
		{
			self.is_selected <- false;
		}
	}
	
	string separateur_milliers (int a_value)
	{
		string txt <- ""+a_value;
		if length(txt)>3
			{string a <- copy_between(txt,0,length(txt)-3);
			string b <- copy_between(txt,length(txt)-3,length(txt));
			txt <- a +"."+b;
			}
		return txt;
	}
	
	action user_msg (string msg, string type_msg) {
		write "USER MSG: "+msg;
		ask game_console{
			do write_message(msg, type_msg );
		}
		
	}
	
	/**
	 * Nouvelle action de l'interface V2
	 */
	bool basket_event <- false update:false;
	action move_down_event
	{
		if(basket_event)
		{
			return;
		}
		basket_event<- true;
		ask basket
		{
			do move_down_event;
		}
	}
	action move_down_event_dossier
	{
		ask work_in_progress_list
		{
			do move_down_event;
		}
	}	
	action move_down_event_console
	{
		ask console
		{
			do move_down_event;
		}
	}
	
}

/**
 * 
 * Espèce de l'interface V2
 * 
 */
species displayed_list skills:[UI_location] schedules:[]
{
	int max_size <- 7;
	int font_size <- 12;
	bool over_sized -> {length(elements)> max_size};
	float header_height <- 0.2;
	float element_height <- 0.08;
	
	string legend_name <- "ma légende";
	int budget <- 2000;
	int start_index <- 0;
	list<displayed_list_element> elements <- [];
	system_list_element up_item <- nil;
	system_list_element down_item <- nil;
	string display_name <-"Panier";
	bool show_header <- true;
	
	action move_down_event
	{
		if(up_item.is_displayed)
		{
			ask up_item
			{
				do move_down_event;
				
			}
			ask down_item
			{
				do move_down_event;
			}
			
		}
		
		ask elements where(each.is_displayed = true)
		{
			if(move_down_event())
			{
				return;
			}
		}
		do on_mouse_down;
	}
	action on_mouse_down;
	
	action add_item(displayed_list_element bsk_el)
	{
		int index <- length(elements) ;
		elements <- elements + bsk_el;
		point p <- get_location(index); //{0.5,index *element_height + header_height+element_height/2 };
		ask(bsk_el)
		{
			is_displayed <- true;
			my_parent <- myself; 
			//do move_agent_at ui_location:p;
			do lock_agent_at ui_location:p display_name:myself.display_name ui_width:myself.locked_ui_width ui_height:myself.element_height ;
			shape <- rectangle(ui_width, ui_height);
		
		}
		if(length(elements) > max_size)
		{
			do go_to_end;
			up_item.is_displayed <- true;
			down_item.is_displayed <-true;
		}
		else
		{
			up_item.is_displayed <- false;
			down_item.is_displayed <-false;
		}
		
	}
	
	point get_location(int idx)
	{
		float header_size <- show_header?header_height:0.0;
		idx <- min([idx,max_size-1]);
		point p <- {locked_location.x+locked_ui_width/2,idx *element_height + header_size+element_height/2 };
		return p;
	}
	
	action go_to_end
	{
		start_index <- length(elements)-max_size+2;
		do change_start_index(start_index);
	}
	action change_start_index(int idx)
	{
		displayed_list_element ele <- nil;
		int i <- 0;
		int j <- 1;
		loop ele over:elements
		{
			if(i>=idx and i < idx+ max_size-2)
			{
				point p <- get_location(j); //{0.5,index *element_height + header_height+element_height/2 };
				j <- j + 1;
				ask(ele)
				{
					do move_agent_at ui_location:p;
					is_displayed <- true;
				}
			}
			else
			{
				ele.is_displayed <- false;
			}	
			i <- i+1;
		}
		
	}
	action change_location_to_all
	{
		int i <- 0;
		start_index <- 0;
		loop ele over:elements
		{
			point p <- get_location(i); //{0.5,index *element_height + header_height+element_height/2 };
				i <- i + 1;
				ask(ele)
				{
					do move_agent_at ui_location:p;
					is_displayed <- true;
				}
		}
		up_item.is_displayed <- false;
		down_item.is_displayed <-false;
	}
	
	action change_location
	{
		if(length(elements)<= max_size)
		{
			do change_location_to_all;
		}
		else
		{
			do change_start_index(start_index);
		}
		
	}
	
	action navigation_item
	{
		create system_list_element number:1
		{
			label <- "<< Précédent";
			point p <- myself.get_location(0);
			do lock_agent_at ui_location:p display_name:myself.display_name ui_width:myself.locked_ui_width ui_height:myself.element_height ;
			myself.up_item <- self;
			self.is_displayed <- false;
			direction <- 1;
			my_parent <- myself;
		}
		create system_list_element number:1
		{
			label <- "                 Suivant >>";
			point p <- myself.get_location(myself.max_size-1);
			do lock_agent_at ui_location:p display_name:myself.display_name ui_width:myself.locked_ui_width ui_height:myself.element_height ;
			myself.down_item <- self;
			self.is_displayed <- false;
			direction <- 2;
			
			my_parent <- myself;
		}
		 
	}
	
	action go_up
	{
		start_index <- min([length(elements)-max_size+2,start_index + 1]);	
		do change_start_index(start_index);
	}
	
	action go_down
	{
		start_index <- max([0,start_index - 1]);	
		do change_start_index(start_index);	
	}
	
	action draw_my_header
	{
		geometry rec2 <- polygon([{0,0}, {0,ui_height*header_height}, {ui_width,ui_height*header_height},{ui_width,0},{0,0}]);
		point loc2  <- {location.x+ui_width/2,location.y+ui_height*header_height/2};
		draw  rec2 at:loc2 color:rgb(219,219,219);
		float gem_height <- ui_height*header_height/2;
		float gem_width <- ui_width;
		shape <- rectangle(gem_width,gem_height);
		float x <- location.x; // - ui_width/2;
		float y <- location.y; // - ui_height/2 ;
		geometry rec3 <- polygon([{x,y}, {x,y+gem_height}, {x+gem_width*0.2,y+gem_height}, {x+gem_width*0.25,y+gem_height*1.2},{x+gem_width*0.3,y+gem_height},{x+gem_width,y+gem_height},{x+gem_width,y},{x,y}]);
		draw rec3 color:rgb(59,124,58);
		font var0 <- font ('Helvetica Neue',DISPLAY_FONT_SIZE, #bold ); 
		draw legend_name at:{location.x + gem_width /2 - (length(legend_name)*6#px/2), location.y + gem_height/2 + 4#px} color:#white font:var0;
	}
	
	action draw_list
	{
		point loc1 <- {location.x+ui_width/2,location.y+ui_height/2};
		geometry rec1 <- polygon([{0,0}, {0,ui_height}, {ui_width,ui_height},{ui_width,0},{0,0}]);
		draw rec1 at:loc1 color:#white;
		if(show_header = true)
		{
			do draw_my_header;
		}
	}
	action remove_all_elements
	{
		ask(elements)
		{
			do die;
		}
		elements <- [];
		up_item.is_displayed <- false;
		down_item.is_displayed <- false;
	}
	action remove_element(displayed_list_element ele)
	{
		remove ele from:elements;
		do change_location;
	}
	
	aspect base
	{
		do draw_list;
	}
}

species basket parent:displayed_list 
{
	int my_font_size <- DISPLAY_FONT_SIZE - 14;
	int budget -> {world.budget};
	float final_budget -> {world.budget - sum(elements collect((basket_element(each).current_action).actual_cost))};
	
	point validation_button_size <- {0,0};
	
	init
	{
		show_header <- true;
		legend_name <- "€   Actions envisagées";
		point p <- {0.0,0.0};
		display_name <- "Panier";
		do lock_agent_at ui_location:p display_name:display_name ui_width:1.0 ui_height:1.0 ;
		do navigation_item;
	}
	
	action add_action_in_basket(action_done act)
	{
	  	create basket_element number:1 returns:ele
		{
			label <- act.label;
			
			icone <- world.chooseActionIcone(act.command);
			current_action <- act;
		}
		do add_item(first(ele));
	}
	
	action draw_budget
	{
		float gem_height <- ui_height*header_height/2;
		float gem_width <- ui_width;
		int mfont_size <- DISPLAY_FONT_SIZE - 2;
		font font0 <- font ('Helvetica Neue',DISPLAY_FONT_SIZE-4, #plain ); 
		draw "Budget initial" font:font0 color:rgb(101,101,101)  at:{location.x + ui_width - 150#px,location.y+ui_height*0.15+(mfont_size/2)#px};//at; {location.x + ui_width*0.5,location.y+ui_height*0.15};
		font font1 <- font ('Helvetica Neue',DISPLAY_FONT_SIZE, #bold ); 
		draw ""+world.separateur_milliers(int(budget)) font:font1 color:rgb(101,101,101) at:{location.x + ui_width - 70#px,location.y+ui_height*0.15+(mfont_size/2)#px};//at; {location.x + ui_width*0.5,location.y+ui_height*0.15};
	}
	
	action draw_foot
	{
		point loc1 <- {location.x+ui_width/2,location.y+ui_height-header_height/4*ui_height};
		geometry rec1 <- polygon([{0,0}, {0,0.1*ui_height}, {ui_width,header_height/2*ui_height},{ui_width,0},{0,0}]);
		draw rec1 at:loc1 color:rgb(219,219,219);
		int mfont_size <- my_font_size - 2;
		font font0 <- font ('Helvetica Neue',DISPLAY_FONT_SIZE-4, #plain ); 
		draw "Budget restant" font:font0 color:rgb(101,101,101) at:{location.x + ui_width - 170#px,location.y+ui_height-ui_height*header_height/4+(mfont_size/2)#px};//at; {location.x + ui_width*0.5,location.y+ui_height*0.15};
		font font1 <- font ('Helvetica Neue',DISPLAY_FONT_SIZE, #bold ); 
		draw ""+world.separateur_milliers(int(final_budget)) font:font1 color:#black at:{location.x + ui_width - 80#px,location.y+ui_height-ui_height*header_height/4+(mfont_size/2)#px};//at; {location.x + ui_width*0.5,location.y+ui_height*0.15};
	}
	
	point validation_button_location
	{
		int index <- min([length(elements),max_size]) ;
		float sz <- element_height*ui_height;
		
		point p <- {ui_width-sz*0.75,location.y+(index *sz) + (header_height*ui_height)+ (0.75*element_height*ui_height) };
		return p;
	}
	
	action draw_valid_button
	{
		point pt <- validation_button_location();
		float sz <- element_height*ui_height;
		image_file icone <- file("../images/ihm/I_valider.png");
		validation_button_size <- {sz*0.8,sz*0.8};
		draw icone at:pt size:validation_button_size;
		int mfont <- DISPLAY_FONT_SIZE - 2;
		int mfont2 <- DISPLAY_FONT_SIZE - 4;
		font font1 <- font ('Helvetica Neue',mfont, #plain ); 
		font font2 <- font ('Helvetica Neue',mfont2, #plain ); 
		draw "Valider" at:{location.x + ui_width - 140#px,pt.y+(mfont2/2)#px} size:{sz*0.8,sz*0.8} font:font2 color:#black;
		draw " "+world.separateur_milliers( int(budget - final_budget)) at:{location.x + ui_width - 90#px,pt.y+(mfont/2)#px} size:{sz*0.8,sz*0.8} font:font1 color:#black;
	}
	
	
	action validation_panier
	{
			if round = 0
			{
				map<string,unknown> res <- user_input("Avertissement", "La simulation n'a pas encore commencée"::"" );
				return;
			}
			if empty(game_basket.elements)
			{
				map<string,unknown> res <- user_input("Avertissement", "Votre panier est vide"::"" );
				return;
			}
			if(   minimal_budget >(budget - round(sum(my_basket collect(each.cost)))))
			{
				string budget_display <- "Vous ne disposez pas du budget suffisant pour réaliser toutes ces actions";
				ask world {do user_msg (budget_display,INFORMATION_MESSAGE);}
				map<string,unknown> res <- user_input("Avertissement", budget_display::"" );//[budget_display:: false]);
				return;
			}
			string ask_display <- "Vous êtes sur le point de valider votre panier \n"+/*action_delayed+*/" Cocher la case, pour accepter le panier et valider";
			map<string,bool> res <- user_input("Avertissement", ask_display::false);
			if(res at ask_display )
			{
				ask game_manager
				{
					do send_basket;
				}
			}
	}
	action on_mouse_down
	{
		if(validation_button_location() distance_to #user_location < validation_button_size.x)
		{
			do validation_panier;
		}
	}
	aspect base
	{
		do draw_list;
		do draw_valid_button;
		do draw_budget;
		do draw_foot;
	}
}


species system_list_element parent:displayed_list_element
{
	int direction <- 0;
	
	bool move_down_event
	{
		point loc <- #user_location;
		if ! (self overlaps loc)
		{
			return false;
		}
		switch (direction)
		{
			match 2 {
				ask my_parent
				{
					do go_up;
				}
			}
			match 1
			{
				ask my_parent
				{
					do go_down;
				}
			}		
		}
		return true;
	}
	action draw_element
	{
		
	}
	
	aspect dossier
	{
		if(is_displayed = true and my_parent.display_name = "Dossiers")
		{
			do draw_item;
			do draw_element;
		}
	}
	aspect basket
	{
		if(is_displayed = true and my_parent.display_name = "Panier")
		{
			do draw_item;
			do draw_element;
		}
	}
	aspect console
	{
		if(is_displayed = true and my_parent.display_name = "Messages")
		{
			do draw_item;
			do draw_element;
		}
	}	
}

species displayed_list_element skills:[UI_location] schedules:[]
{
	int font_size <- DISPLAY_FONT_SIZE - 4;
	
	bool event <- false update:false;
	string label <- "my label";
	displayed_list my_parent;
	bool is_displayed;
	int display_index;
	image_file icone <- nil; //file("../images/ihm/I_arbre.png");
	
	action draw_item
	{
		int mfont <- font_size;
		font var0 <- font ('Helvetica Neue',mfont, #bold); 
		point pt <- location;
		geometry rec2 <-  polyline([{0,0}, {ui_width,0}]);
		
		geometry rec <-  polygon([{0,0}, {0,ui_height}, {ui_width,ui_height},{ui_width,0},{0,0}]);
		shape <- rec;
		location <- pt;
		draw rec  at:{location.x,location.y} color:rgb(233,233,233);
		draw rec2  at:{location.x,location.y+ui_height/2} color:#black;
		draw label at:{location.x - ui_width/2+ 2*ui_height , location.y + (mfont/2)#px} font:var0 color:#black;
		if( icone !=nil)
		{
			draw icone at:{location.x-ui_width/2+ui_height,location.y} size:{ui_height*0.8,ui_height*0.8};
		}
	}
	
	bool move_down_event
	{
		point loc <- #user_location;
		if self overlaps loc and is_displayed
		{
			do on_mouse_down;
			return true;
		}
		
		return false;
	}
	
	action on_mouse_down;
	action draw_element;
	aspect base
	{
		if(is_displayed = true)
		{
			do draw_item;
			do draw_element;
		}
	}
}	

species work_in_progress_list parent:displayed_list schedules:[]
{
	init{
		max_size <- 10;
		show_header <- false;
		display_name <- "Dossiers";
		point p <- {0.15,0.0};
		do lock_agent_at ui_location:p display_name:display_name ui_width:0.85 ui_height:1.0 ;//0U 0.9
		do navigation_item;
		
	}
	
	action add_action_in_history(action_done act)
	{
	  	create work_in_progress_element number:1 returns:ele
		{
			label <- act.label;
			icone <- world.chooseActionIcone(act.command);
			current_action <- act;
		}
		do add_item(first(ele));
	}
	
} 


species console parent:displayed_list schedules:[]
{
	init{
		font_size <- 11;
		max_size <- 10;
		show_header <- false;
		display_name <- "Messages";
		point p <- {0.15,0.0};
		do lock_agent_at ui_location:p display_name:display_name ui_width:0.85 ui_height:1.0 ;
		do navigation_item;
	}
	
	image_file choose_icone(string message_type)
	{
		switch(message_type)
		{
			match INFORMATION_MESSAGE { return file("../images/ihm/I_quote.png"); }
			match POPULATION_MESSAGE { return file("../images/ihm/I_population.png"); }
			match BUDGET_MESSAGE { return file("../images/ihm/I_BY.png"); }
		}
		return file("../images/ihm/I_quote.png");
	}
	
	action write_message(string msg, string type )
	{
		create console_element number:1 returns:ele
		{
			label <- msg;
			icone <- myself.choose_icone(type);
		}
		do add_item(first(ele));
	}	
}
species console_element parent:displayed_list_element schedules:[]
{}

species work_in_progress_left_icon skills:[UI_location] 
{
	image_file directory_icon <- file("../images/ihm/I_dossier.png");
	aspect base
	{
		geometry rec <- polygon([{0,0},{0,ui_height},{ui_width,ui_height},{ui_width,0},{0,0}]);
		draw rec color:rgb(59,124,58) at:location;
		draw directory_icon at:{location.x,location.y-ui_height/4} size:{0.7*ui_width,0.7*ui_width};
	}
}
species console_left_icon skills:[UI_location] 
{
	image_file directory_icon <- file("../images/ihm/I_quote.png");
	aspect base
	{
		geometry rec <- polygon([{0,0},{0,ui_height},{ui_width,ui_height},{ui_width,0},{0,0}]);
		draw rec color:rgb(59,124,58) at:location;
		draw directory_icon at:{location.x,location.y-ui_height/4} size:{0.7*ui_width,0.7*ui_width};
	}
}



species work_in_progress_element parent:displayed_list_element schedules:[]
{
	int font_size <- 12;
		
	int delay ->{current_action.round_delay};
	int rounds_before_application ->{current_action.nb_rounds_before_activation_and_waitingLeaderToActivate()};
	
	float final_price ->{current_action.actual_cost};
	float initialx_price ->{float(current_action.cost)};
	
	point bullet_size -> {point({ui_height*0.6,ui_height*0.6})};
	
	point delay_location -> {point({location.x+2*ui_width/5,location.y})};
	point round_apply_location -> {point({location.x+1.3*ui_width/5,location.y})};
	point price_location -> {point({location.x+ui_width/2-40#px,location.y})};
	action_done current_action;
	
	action on_mouse_down
	{
		if(highlight_action =current_action )
		{
			highlight_action <- nil;
		}
		else
		{
			highlight_action <- current_action;
		}
	}
	
	
	action draw_element
	{
		int mfont <- font_size;
		font font1 <- font ('Helvetica Neue',mfont, #italic ); 
		
		if(!current_action.is_applied)
		{
			if(delay != 0)
			{
				draw circle(bullet_size.x/2) at:delay_location color:rgb(235,33,46);
				draw ""+delay at:{delay_location.x -(mfont/6)#px ,delay_location.y +(mfont/3)#px } color:#white font:font1;
			}
			draw circle(bullet_size.x/2) at:round_apply_location color:rgb(87,87,87);
			draw ""+rounds_before_application at:{round_apply_location.x -(mfont/6)#px ,round_apply_location.y +(mfont/3)#px } color:#white font:font1;
		}
		else
		{
			image_file micone <- file("../images/ihm/I_valider.png");
			draw micone at:round_apply_location size:bullet_size color:rgb(87,87,87);
		}

		rgb mc <- (final_price = initialx_price) ? rgb(87,87,87): rgb(235,33,46);
		draw ""+int(final_price) at:{price_location.x ,price_location.y +(mfont/3)#px } color:mc font:font1;
			
		
		
		if(highlight_action = current_action)
		{
			
			geometry rec <-  polygon([{0,0}, {0,ui_height}, {ui_width,ui_height},{ui_width,0},{0,0}]);
			draw rec  at:{location.x,location.y}  empty:true border:#red;
		}
	}
	
} 

species basket_element parent:displayed_list_element
{
	int font_size <- 12;
	point button_size -> {point({ui_height*0.6,ui_height*0.6})};
	point button_location -> {point({location.x+ui_width/2- (button_size.x),location.y})};
	action_done current_action <- nil;
	image_file close_button <- file("../images/ihm/I_close.png");
	point bullet_size -> {point({ui_height*0.6,ui_height*0.6})};
	point round_apply_location -> {point({location.x+1.3*ui_width/5,location.y})};
	
	action remove_action
	{
		ask my_parent
		{
			do remove_element(myself);
			
		}
	}
	
	action on_mouse_down
	{
		if(button_location distance_to #user_location <= button_size.x)
		{
			// Le joueur vient de cliquer sur le bouton pour supprimer l'action_done de la liste du panier
			remove current_action from:my_basket;
			remove current_action from: ordered_action;
			do remove_action;
			ask current_action
			{
				do die;
			}
			do die;
		}
		else
		{
			if(highlight_action =current_action )
			{
				highlight_action <- nil;
			}
			else
			{
				highlight_action <- current_action;
			}
		}
	}
	
	
	action draw_element
	{
		draw close_button at:button_location size:button_size ;
		int mfont <- font_size;
		font font1 <- font ('Helvetica Neue',mfont, #bold ); 
		
		draw ""+world.separateur_milliers(int(current_action.cost))  at:{button_location.x - 50#px, button_location.y+(mfont/2)#px}  color:#black font:font1;
		
		draw circle(bullet_size.x/2) at:round_apply_location color:rgb(87,87,87);
		draw ""+(world.delayOfAction(current_action.command)) at:{round_apply_location.x -(mfont/6)#px ,round_apply_location.y +(mfont/3)#px } color:#white font:font1;
	
		if(highlight_action = current_action)
		{
			
			geometry rec <-  polygon([{0,0}, {0,ui_height}, {ui_width,ui_height},{ui_width,0},{0,0}]);
			draw rec  at:{location.x,location.y}  empty:true border:#red;
		}
	}
}



species activated_lever 
{
	action_done act_done;
	float activation_time;
	bool applied <- false;
	
	//attributes sent through network
	int id;
	string commune_name;
	string lever_type;
	string lever_explanation <- "";
	string act_done_id <- "";
	int nb_rounds_delay <-0;
	int added_cost <- 0;
	
	action init_from_map(map<string, string> m )
	{
		id <- int(m["id"]);
		lever_type <- m["lever_type"];
		commune_name <- m["commune_name"];
		act_done_id <- m["act_done_id"];
		added_cost <- int(m["added_cost"]);
		nb_rounds_delay <- int(m["nb_rounds_delay"]);
		lever_explanation <- m["lever_explanation"];
	}
	
	map<string,string> build_map_from_attribute
	{
		map<string,string> res <- [
			"OBJECT_TYPE"::"activated_lever",
			"id"::id,
			"lever_type"::lever_type,
			"commune_name"::commune_name,
			"act_done_id"::string(act_done_id),
			"added_cost"::string(added_cost),
			"nb_rounds_delay"::int(nb_rounds_delay),
			"lever_explanation"::lever_explanation
			 ]	;
		return res;
	}
}

species network_activated_lever skills:[network]
{
	init
	{
		do connect to:SERVER with_name:"activated_lever";	
	}

	reflex wait_message
	{
		loop while:has_more_message()
		{
			message msg <- fetch_message();
			string m_sender <- msg.sender;
			map<string, string> m_contents <- msg.contents;
			if string(m_contents["commune_name"]) = commune_name and empty(activated_lever where (each.id = int(m_contents["id"])))
			{
				create activated_lever number:1
				{
					do init_from_map(m_contents);
					act_done <- (action_UA + action_def_cote) first_with (each.id = act_done_id);
					ask world
					{
						do user_msg (myself.lever_explanation, INFORMATION_MESSAGE);
					}
					if added_cost != 0
					{
						budget <- budget - added_cost;
						ask world
						{
							do user_msg ("Vous avez été "+(myself.added_cost>0?"prélevé":"approvisionné")+" de "+abs(myself.added_cost)+ " By pour le dossier '"+myself.act_done.label+"'", BUDGET_MESSAGE);
						}	
					}
					if nb_rounds_delay != 0
					{
						ask world
						{
							do user_msg ("Le dossier '"+myself.act_done.label+ "' a été "+(myself.nb_rounds_delay>=0?"retardé":"avancé")+" de "+ abs(myself.nb_rounds_delay) + " tour"+(abs(myself.nb_rounds_delay)<=1?"":"s"), INFORMATION_MESSAGE);
						}
						act_done.shouldWaitLeaderToActivate <- false;
					}
					add self to: act_done.activated_levers;
				}	
			}
		}	
	}
}

species data_retrieve skills:[network]
{
	init
	{
		do connect to:SERVER with_name:commune_name+"_retreive";
	}
	
	action clear_simulation
	{
		ask UA
		{
			do die;
		}
		ask def_cote
		{
			do die;
		}
		ask action_done
		{
			do die;
		}
	}
	
	reflex getData
	{
		loop while:has_more_message()
		{
			message m <- fetch_message();
			map<string, unknown> mc <- m.contents;
			
			
			switch(mc["OBJECT_TYPE"])
			{
				match "lock_unlock"
				{
					
					if(mc["WINDOW_STATUS"] = "LOCKED")
					{
						world.is_active_gui <- false;
					}
					else
					{
						world.is_active_gui <- true;
					}
				}
				
				match "action_done"
				{
					if(mc["action_type"]="dike")
					{
						action_def_cote tmp <- action_def_cote first_with(each.id =mc["id"] );
						
						if(tmp = nil)
						{
							create action_def_cote number:1
							{
								id <- mc["id"];
							}
							tmp<- action_def_cote first_with(each.id =mc["id"] );
							ask tmp {do init_from_map(mc);}	
							ask(game_history) {	do add_action_in_history(tmp);} 
						}
						else {
							ask tmp {do init_from_map(mc);}
						}	
					}
					else
					{
						if mc["action_type"]!="PLU" {write "PROBLEME";}
						action_UA tmp <- action_UA first_with(each.id =mc["id"] );
						
						if(tmp = nil)
						{
							create action_UA number:1
							{
								id <- mc["id"];
							}
							tmp<- action_UA first_with(each.id =mc["id"] );
							ask tmp {do init_from_map(mc);}	
							ask(game_history) {	do add_action_in_history(tmp);} 
						}
						else {
							ask tmp {do init_from_map(mc);}
						}	
					}
						
				}
				match "def_cote"
				{
					
					def_cote tmp <- def_cote first_with(each.dike_id= int(mc["id_ouvrage"]));
					
					if(tmp = nil)
						{
							create def_cote number:1
							{
								dike_id<- int(mc["id_ouvrage"]);
							}
							tmp<-  def_cote first_with(each.dike_id= int(mc["id_ouvrage"]));
						}
					ask tmp
						{
							
							do init_from_map(mc);
						}	
				}
				match("UA")
				{
					UA tmp <- UA first_with(each.id= int(mc["id"]));
					if(tmp = nil)
						{
							create UA number:1
							{
								id <-  int(mc["id"]);
							}
							tmp<-  UA first_with(each.id= int(mc["id"]));
						}
						
						ask tmp
						{
							do init_from_map(mc);
						}	
					
				}
				match("activated_lever")
				{
					create activated_lever number:1
					{
						do init_from_map(mc);
						act_done <- (action_UA + action_def_cote) first_with (each.id = act_done_id);
						add self to: act_done.activated_levers;
					}				
				}
			
			}
			
		}
	}
}

species action_done
{
	string id <-"";
	int element_id<-0;
	geometry element_shape;
	float shape_width <-35#m;
	//string command_group <- "";
	int command <- -1;
	string label <- "no name";
	int initial_application_round <- -1;
	int round_delay -> {activated_levers sum_of (each.nb_rounds_delay)} ; // nb rounds of delay
	int actual_application_round -> {initial_application_round+round_delay};
	bool is_delayed ->{round_delay>0} ;
	float cost <- 0.0;
	int added_cost -> {activated_levers sum_of (each.added_cost)} ;
	float actual_cost -> {cost+added_cost};
	bool has_added_cost ->{added_cost>0} ;
	bool has_diminished_cost ->{added_cost<0} ;
	bool is_sent <- false;
	bool is_applied <- false;
	bool is_highlighted <- false;
	// attributs ajouté par NB dans la specie action_done (modèle oleronV2.gaml) pour avoir les infos en plus sur les actions réalisés, nécessaires pour que le leader puisse applique des leviers
	string action_type <- "dike" ; //can be "dike" or "PLU"
	string previous_ua_name <-"nil";  // for PLU action
	bool isExpropriation <- false; // for PLU action
	bool inProtectedArea <- false; // for dike action
	bool inCoastBorderArea <- false; // for PLU action // c'est la bande des 400 m par rapport au trait de cote
	bool inRiskArea <- false; // for PLU action / Ca correspond à la zone PPR qui est un shp chargé
	bool isInlandDike <- false; // for dike action // ce sont les rétro-digues
	bool has_activated_levers -> {!empty(activated_levers)};
	list<activated_lever> activated_levers <-[];
	bool shouldWaitLeaderToActivate <- false;
	
	init 
	{
		//ordered_action <- ordered_action + self;
	}
	
	
	action init_from_map(map<string, unknown> a )
	{
		self.id <- string(a at "id");
		self.element_id <- int(a at "element_id");
		self.command <- int(a at "command");
		self.label <- string(a at "label");
		self.cost <- float(a at "cost");
		self.initial_application_round <- int(a at "initial_application_round");
		self.isInlandDike <- bool(a at "isInlandDike");
		self.inRiskArea <- bool(a at "inRiskArea");
		self.inCoastBorderArea <- bool(a at "inCoastBorderArea");
		self.isExpropriation <- bool(a at "isExpropriation");
		self.inProtectedArea <- bool(a at "inProtectedArea");
		self.previous_ua_name <- string(a at "previous_ua_name");
		self.action_type <- string(a at "action_type");
		self.is_applied<- bool(a at "is_applied");
		self.is_sent<- bool(a at "is_sent");
		
		point pp<-{float(a at "locationx"), float(a at "locationy")};
		point mpp <- pp;
		int i <- 0;
		list<point> all_points <- [];
		loop while: (pp!=nil)
		{
			string xd <- a at ("locationx"+i);
			if(xd != nil)
			{
				pp <- {float(xd), float(a at ("locationy"+i))  };
				all_points <- all_points + pp;
			}
			else
			{
				pp<-nil;
			}
			i<- i + 1;
		}
		if(self.action_type="dike")
		{
			element_shape <- polyline(all_points);
			shape <-  element_shape+shape_width; //shape_width around element_shape;
		}
		else
		{
			element_shape <- polygon(all_points);
			shape <- element_shape;
		}
		location <-mpp;
	}
	
	map<string,string> build_map_from_attribute
	{
		map<string,string> res <- [
			"OBJECT_TYPE"::"action_done",
			"id"::string(id),
			"element_id"::string(element_id),
			"commune_name"::string(commune_name),
			"command"::string(command),
			"label"::string(label),
			"cost"::string(cost),
			"initial_application_round"::string(initial_application_round),
			"action_type"::string(action_type),
			"previous_ua_name"::string(previous_ua_name),
			"isExpropriation"::string(isExpropriation),
			"isInlandDike"::string(isInlandDike),
			"inRiskArea"::string(inRiskArea),
			"inCoastBorderArea"::string(inCoastBorderArea),
			"inProtectedArea"::string(inProtectedArea),
			"is_applied"::string(is_applied),
			"is_sent"::string(is_sent),
			"shape"::string(shape)
			 ]	;
		return res;
	}
	
	int nb_rounds_before_activation 
	{
		return actual_application_round - world.round ;
	}
	
	int nb_rounds_before_activation_and_waitingLeaderToActivate
	{
		int aV <- actual_application_round - world.round ;
		if aV <= 0
		 {
		 	if shouldWaitLeaderToActivate {
		 		// En attente du leader pour l'activation
		 			return 0;
		 	}
		 	else {
		 		write "délai d'activation pas normal";
		 	}
		 }
		return aV;
	}
	
	action apply;
	
	string serialize_command
	{
		string result <-"";
		result <- ""+
		command+COMMAND_SEPARATOR+  //0
		id+COMMAND_SEPARATOR+
		initial_application_round+COMMAND_SEPARATOR+
		element_id+COMMAND_SEPARATOR+			//3
		action_type +COMMAND_SEPARATOR+
		inProtectedArea+COMMAND_SEPARATOR+		//5
		previous_ua_name+COMMAND_SEPARATOR+
		isExpropriation+COMMAND_SEPARATOR+					//7
		int(cost)	;					//8
		
		if command = ACTION_CREATE_DIKE  {
				point end <- last(element_shape.points);
				point origin <- first(element_shape.points);
				result <- result+
					COMMAND_SEPARATOR+( origin.x)+	//9
					COMMAND_SEPARATOR+(origin.y) +
					COMMAND_SEPARATOR+(end.x)+		//11
					COMMAND_SEPARATOR+(end.y)+
					COMMAND_SEPARATOR+location.x+	//13
					COMMAND_SEPARATOR+location.y;
					
					
		}
			
		
		return result;	
	}
	
	
		

	
}

species network_player_new skills:[network]
{
	init
	{
		do connect to:SERVER with_name:world.commune_name+"_map_msg";
	}
	
	reflex wait_message
	{
		loop while:has_more_message()
		{
			message msg <- fetch_message();
			string m_sender <- msg.sender;
			map<string, string> m_contents <- msg.contents;
			if string(m_contents["commune_name"]) = commune_name
			{
				switch m_contents["TOPIC"]
				{
					match "action_done is_applied" // remplace ancien ACTION_DONE_APPLICATION_ACKNOWLEDGEMENT
					{
						string act_done_id <- m_contents["id"];
						action_done app <- ((action_def_cote + action_UA) first_with (each.id = act_done_id));
						ask app
						{
							is_applied <- true;
							shouldWaitLeaderToActivate <- false;
							do apply	;
						}
					}
					match "INFORM_NEW_ROUND" // a new round just has pass
					{
						round<- round +1;
						ask action_UA where (not(each.is_sent)) {initial_application_round<-initial_application_round+1;}
						ask action_def_cote where (not(each.is_sent)) {initial_application_round<-initial_application_round+1;}
						switch round {
							match 1 {ask world {do user_msg("La simulation démarre. C'est le tour 1", INFORMATION_MESSAGE);}}
							default {
								ask world {do user_msg("Le tour "+ round+" a commencé", INFORMATION_MESSAGE);}
								int currentPop <- world.current_population();
								ask world {do user_msg(""+((previous_population=currentPop)?"":("Votre commune accueille "+(currentPop-previous_population) + " nouveaux arrivants. "))+"La population de votre commune est de "+currentPop+" habitants.", POPULATION_MESSAGE);}	
								previous_population <- currentPop;
								impot_recu <- int(world.current_population * impot_unit);
								budget <- budget + impot_recu;
								ask world {do user_msg ("Vous avez perçu des impôts de "+ world.separateur_milliers(impot_recu) +' By', BUDGET_MESSAGE);}
							}
						}							
					
					}
					match "INFORM_CURRENT_ROUND" // After connecting, the player is informed of the current round by the model
					{
						round <- int(m_contents["round"]);
						if round != 0 { ask world {do user_msg("C'est le tour "+round, INFORMATION_MESSAGE);} }
					}
					match "COMMUNE_UPDATE" //  USED WHEN A COMMUNE CONNECTS TO GIVE THE CURRENT STATE OF THE COMMNUNE
					{
						budget <- int(m_contents["budget"]);
					}
				}
			}
		}
	}
}

species network_listen_to_leader skills:[network]
{
	string PRELEVER <- "Percevoir Recette";
	string CREDITER <- "Subventionner";
	string MSG_TO_PLAYER <-"Message au joueur";
	string LEADER_COMMAND <- "leader_command";
	string AMOUNT <- "amount";
	string COMMUNE <- "COMMUNE_ID";
	string ASK_NUM_ROUND <- "Leader demande numero du tour";
	string NUM_ROUND <- "Numero du tour";
	string ASK_INDICATORS_T0 <- "Leader demande Indicateurs a t0";
	string INDICATORS_T0 <- 'Indicateurs a t0';
	
	init
	{
		 do connect to:SERVER with_name:MSG_FROM_LEADER;
	}
	
	
	reflex  wait_message 
	{
		loop while:has_more_message()
		{
			message msg <- fetch_message();
			map<string, unknown> m_contents <- msg.contents;
			if m_contents[COMMUNE] =commune_name
			{
				switch(m_contents[LEADER_COMMAND])
				{
					match CREDITER
					{
						int amount <- m_contents[AMOUNT];
						budget <- budget + amount;
						ask world {do user_msg(string(m_contents[PLAYER_MSG])+amount+ ' By',BUDGET_MESSAGE);}
					}
					match PRELEVER
					{
						int amount <- m_contents[AMOUNT];
						budget <- budget - amount;
						ask world {do user_msg(string(m_contents[PLAYER_MSG])+amount+ ' By',BUDGET_MESSAGE);}
					}
					match MSG_TO_PLAYER
					{
						ask world {do user_msg(string(m_contents[PLAYER_MSG]),INFORMATION_MESSAGE);}
					}
					match "action_done shouldWaitLeaderToActivate" {
						bool shouldWait <- bool(m_contents["action_done shouldWaitLeaderToActivate"]);
						if shouldWait {
							action_done aAct <-(action_UA+action_def_cote) first_with (each.id = string(m_contents["action_done id"]));
							aAct.shouldWaitLeaderToActivate <- bool(m_contents["action_done shouldWaitLeaderToActivate"]);
						}
						//Dans le cas où le message est de ne pas attendre, alors il ne fait pas acutalisare l'action done, car c'est l'application de l'action_done qui va  mettre shouldWaitLeaderToActivate à false	
					}
				}
			}
			
		}
		
	} 
	
	
}	
species network_player skills:[network]
{
	init {
		
		do connect to:SERVER with_name:world.commune_name;	
		string mm<- ""+CONNECTION_MESSAGE+COMMAND_SEPARATOR+world.commune_name;
			map<string,string> data <- ["stringContents"::mm];
			do send to:GAME_MANAGER contents:data;
		
	//	do send to:MANAGER_NAME contents:data;
	}
	
	reflex receive_message 
	{
		loop while:has_more_message()
		{
			message msg <- fetch_message();
			string my_msg <- msg.contents;
			list<string> data <- my_msg split_with COMMAND_SEPARATOR;
			int command <- int(data[0]);
			int msg_id <- int(data[1]);
			switch(int(data[0]))
				{
		
//		 			match INFORM_ROUND
//					{
//						round<-int(data[2]);
//						ask action_UA where (not(each.is_sent)) {initial_application_round<-initial_application_round+1;}
//						ask action_def_cote where (not(each.is_sent)) {initial_application_round<-initial_application_round+1;}
//						switch round {
//							match 1 {ask world {do user_msg("La simulation démarre. C'est le tour 1", INFORMATION_MESSAGE);}}
//							match 0 {}
//							default {
//								ask world {do user_msg("Le tour "+ round+" a commencé", INFORMATION_MESSAGE);}
//								int tmp <- copy(previous_population);
//								previous_population <- world.current_population();
//								ask world {do user_msg(""+((previous_population-tmp)=0?"":("Votre commune accueille "+(previous_population-tmp) + " nouveaux arrivants. "))+"La population de votre commune est de "+previous_population+" habitants.", POPULATION_MESSAGE);}
//								
//								impot_recu <- int(world.current_population * impot_unit);
//								budget <- budget + impot_recu;
//								ask world {do user_msg ("Vous avez perçu des impôts de "+ world.separateur_milliers(impot_recu) +' By', BUDGET_MESSAGE);}
//							}
//						}							
//					}
//					match SUBVENTIONNER_GANIVELLE
//					{
//						ask world {do change_subvention_ganivelle_with(!subvention_ganivelle);}
//					}
//					match SUBVENTIONNER_HABITAT_ADAPTE
//					{
//						ask world {do change_subvention_habitat_adapte_with(!subvention_habitat_adapte);}
//					}
//					match NOTIFY_DELAY
//					{
//						int entityTypeCode<- int(data[2]);
//						int id <- int(data[3]);
//						int nb <- int(data[4]);
//						//write ""+entityTypeCode+" "+id + " " +nb;
//						switch entityTypeCode {
//							match ENTITY_TYPE_CODE_DEF_COTE {do action_def_cote_delay_acknowledgment(id, nb);} 
//							match ENTITY_TYPE_CODE_UA {do action_UA_delay_acknowledgment(id, nb);} 
//							default {write "BUG: probleme: entityTypeCode pas reconnu : " + entityTypeCode;}
//						}
//					}
//					
//					match INFORM_TAX_GAIN
//					{	impot_recu <- int(data[2]);
//						round <-int(data[3])+1;
//						ask world {do user_msg ("Vous avez perçu des impôts de "+ world.separateur_milliers(int(data[2]))+ " pour le tour "+data[3], BUDGET_MESSAGE);}
//					}	
					
//					match INFORM_GRANT_RECEIVED
//					{
//						ask world {do user_msg ("Vous avez reçu une subvention d'un montant de "+ world.separateur_milliers(int(data[2])));}
//		
//					}	
//					match INFORM_FINE_RECEIVED
//					{
//						ask world {do user_msg ("Vous avez reçu une amende d'un montant de "+ world.separateur_milliers(int(data[2])));}
//		
//					}	
					match UPDATE_BUDGET
					{
						budget <- int(data[2]);
						
					}
					match ACTION_DIKE_LIST
					{
						do check_dike(data );
					}
					
					match ACTION_ACTION_LIST
					{
						do check_action_done_list(data );
					}
					
					match ACTION_ACTION_DONE_UPDATE
					{
				//		do update_action_done(data);
					}
					
					match ACTION_DONE_APPLICATION_ACKNOWLEDGEMENT
					{
						string action_id <- string(data[2]);
						((action_def_cote + action_UA) first_with (each.id = action_id)).is_applied <- true;
					}
					match ACTION_DIKE_CREATED
					{
						do dike_create_action(data);
					}
					match ACTION_DIKE_UPDATE {
						int d_id <- int(data[2]);
						if(length(def_cote where(each.dike_id =d_id ))=0)
						{
							do dike_create_action(data);
						}
						ask def_cote where(each.dike_id =d_id )
						{
							ganivelle <-bool(data[10]);
							alt <-float(data[11]);
							status <-data[9];
							type <- data[8];
							height <-float(data[7]);
						}
						//do action_def_cote_application_acknowledgment(action_id);	
					}
					match ACTION_DIKE_DROPPED {
						int d_id <- int(data[2]);
//						int action_id <- int(data[3]);
//						do action_def_cote_application_acknowledgment(action_id);	
						ask def_cote where(each.dike_id =d_id )
						{
							do die;
						}
					}
					match ACTION_LAND_COVER_UPDATE {
						int UA_id <- int(data[2]);	
					//	action_done act <- first( action_done overlapping self);
					//	do action_UA_application_acknowledgment(UA_id);
							
						ask UA where(each.id = UA_id)
						{
							ua_code <-int(data[3]);
							ua_name <- nameOfUAcode(ua_code);
							population <-int(data[4]);
							isEnDensification <-bool(data[5]);
						}
					}
				}
			}
	}
	
	action check_dike(list<string> mdata)
	{
		list<int> idata<- mdata collect (int(each));
		ask(def_cote)
		{
			//write "compare : "+dike_id+" ---> "+ mdata;
			if( !( idata contains dike_id) )
			{
				do die;
			}
		}
	}
	
	action check_action_done_list(list<string> mdata)
	{
		list<int> idata<- mdata collect (int(each));
		ask(action_done)
		{
			//write "compare : "+dike_id+" ---> "+ mdata;
			if( !( idata contains id) )
			{
				do die;
			}
		}
	}
	
	action update_action_done(list<string> mdata)
	{
		action_done act <- action_done first_with(each.id = mdata[2]);
		if(act = nil) {
			create action_done number:1
			{
				id<-  int(mdata[2]);
			}
			act <- action_done first_with(each.id = mdata[2]);
		}
		
		string xx <- "";
		int i <- 0;
		loop xx over: mdata
		{
			
			//write "["+i+"] -> "+ xx;
			i <- i + 1;
		}
		
		/////////////  PARSING A CHANGER!!
		act.element_id <- int(mdata[3]);
		act.command <- int(mdata[5]);
		act.label <- mdata[6];
		act.cost <- float(mdata[7]);
		act.initial_application_round <- int(mdata[8]);
		//act.round_delay <- int(mdata[9]);////   VA FALLOIR EENLEVER CA
		act.isInlandDike <- bool(mdata[10]);
		act.inRiskArea <- bool(mdata[11]);
		act.inCoastBorderArea <- bool(mdata[12]);
		act.isExpropriation <- bool(mdata[13]);
		act.inProtectedArea <- bool(mdata[14]);
		act.previous_ua_name <- string(mdata[15]);
		act.action_type <- string(mdata[16]);
		string go <- string(mdata[17]);
		act.element_shape <- geometry(go);
		//write "go "+ go;
//		write "shape go "+ act.shape; 
	}
	
	action dike_create_action(list<string> msg)
	{
		int d_id <- int(msg[2]);
		float x1 <- float(msg[3]);
		float y1 <- float(msg[4]);
		float x2 <- float(msg[5]);
		float y2 <- float(msg[6]);
		float hg <- float(msg[7]);
		string tp <- string(msg[8]);
		string st <- msg[9];
		float a_alt <- msg[10];
		string action_id  <- msg[11];
		float x3  <- float(msg[12]);
		float y3  <- float(msg[13]);
		geometry pli <- polyline([{x1,y1},{x2,y2}]);
		create def_cote number:1 returns: dikes
		{
			shape <- pli;
			location <- point({x3,y3});
			length_def_cote<- int(shape.perimeter);

			dike_id <- d_id;
			type<-tp;
			height<- hg;
			status<-st;
			alt <- a_alt;
			ask action_def_cote first_with(each.id =action_id) {element_id <- d_id;}
		}	
		
		//do action_def_cote_application_acknowledgment(action_id);			
	}
	
//	action action_def_cote_application_acknowledgment(int a_action_def_cote_id)
//	{//write "UPDATE dike " + m_action_id;
//		ask action_def_cote where(each.id  = a_action_def_cote_id)
//		{ self.is_applied <- true;
//		}
//	}
	
//	action action_UA_application_acknowledgment(int UA_id)
//	{//write "UPDATE UA " + m_action_id;
//		ask action_UA where(each.element_id = UA_id)
//		{ 
//			self.is_applied <- true;
//		}
//	}
	 
	 
//	action action_def_cote_delay_acknowledgment(int m_action_id, int nb)
//	{
//		ask action_def_cote where(each.id  = m_action_id)
//		{ 	
//			if nb = 3000 {ask world {do user_msg("Le dossier travaux de "+myself.type_def_cote+" n°"+m_action_id+" a été abrogé pour non conformité réglementaire.");}}
//			else {ask world {do user_msg("Le dossier travaux de "+myself.type_def_cote+" n°"+m_action_id+" a été retardé de "+nb+" tour"+(nb=1?"":"s")+" en raison de contraintes réglementaires.");}}
//		}
//	}
//	
//	action action_UA_delay_acknowledgment(int m_action_id, int nb)
//	{
//		ask action_UA where(each.id  = m_action_id)
//		{  
//			if nb = 3000 {ask world {do user_msg("Le dossier 'aménagement (PLU ou Habitat) n°"+m_action_id+" a été abrogé pour non conformité réglementaire.");}}
//			else {ask world {do user_msg("Le dossier d'aménagement (PLU ou Habitat) n°"+m_action_id+" a été retardé de "+nb+" tour"+(nb=1?"":"s")+" en raison de contraintes réglementaires.");}}
//		}
//	}
	
	
	action send_basket
	{
		basket_element bsk_el <- nil;
		action_done act <-nil;
		
		loop bsk_el over:game_basket.elements //my_basket
		{
			act <- basket_element(bsk_el).current_action;
			string val <- act.serialize_command();
			act.is_sent <- true;
			ask(game_history)
			{
				do add_action_in_history(act);
			} 
			//ajout à l'historique
			
			map<string,string> data <- ["stringContents"::val];
			do send to:GAME_MANAGER contents:data;
			budget <- budget - act.cost;
		}
		ask game_basket
		{
			do remove_all_elements;
		}
		my_basket <- [];
	}

			
	
}



species action_def_cote parent:action_done
{
	string action_type <- "dike";
	string type_def_cote -> {command = ACTION_INSTALL_GANIVELLE?"dune":"digue"};
	float shape_width -> {type_def_cote = "digue"?35#m:65#m};	
	rgb define_color
	{
		switch(command)
		{
			 match ACTION_CREATE_DIKE { return #black;}
			 match ACTION_REPAIR_DIKE {return #green;}
			 match ACTION_DESTROY_DIKE {return #orange;}
			 match ACTION_RAISE_DIKE {return #blue;}
			 match ACTION_INSTALL_GANIVELLE {return #indigo;}
		} 
		return #grey;
	}
	action draw_display
	{
		bool highlighted <- self = highlight_action;
		if !is_applied {
			draw shape color:highlighted?#red:((is_sent)?define_color():#black);
		}
	}
	aspect carte
	{
		if(active_display = DIKE_DISPLAY)
		{
			do draw_display;
		}
	}
	aspect base
	{
		do draw_display;	
	}
	

	action apply
	{
		//creer une digue
	}
}


species action_UA parent:action_done
{
	int choosen_cell;
	string action_type <- "PLU";
	
	rgb define_color
	{
		switch(command)
		{
			 match ACTION_MODIFY_LAND_COVER_A { return rgb(245,147,49);}
			 match_one [ACTION_MODIFY_LAND_COVER_AU,ACTION_MODIFY_LAND_COVER_AUs,ACTION_MODIFY_LAND_COVER_Us, ACTION_MODIFY_LAND_COVER_Ui] {return rgb(0,129,161);}
			 match ACTION_MODIFY_LAND_COVER_N {return rgb(11,103,59);}
		} 
		return #grey;
	}
	action apply
	{
		//creer une digue
	}
	action draw_display
	{
		if ( !is_applied) {
			
			bool highlighted <- self = highlight_action;
			
			geometry triangle <- polygon([shape.points[3],shape.points[1],shape.points[0],shape.points[3] ]);
			
			draw triangle  color:(define_color()) border:define_color() ;
			draw shape at:location empty:true border:highlighted?#red:((is_sent)?define_color():#black) ;
			
			if(ACTION_MODIFY_LAND_COVER_Ui = command)
			{
				draw file("../images/icones/crowd.png") size:self.shape.width;
			}

		
			if [ACTION_MODIFY_LAND_COVER_AUs,ACTION_MODIFY_LAND_COVER_Us] contains command {draw file("../images/icones/wave.png") size:self.shape.width;}

		}
	}
	aspect carte
	{
		if (active_display = UNAM_DISPLAY ) {
			
			do draw_display;
		}
	}
	aspect base
	{
		do draw_display;
	}

	
}

species buttons skills:[UI_location]
{
	int command <- -1;
	string display_name <- "no name";
	string label <- "no name";
	float action_cost<-0;
	bool is_selected <- false;
	geometry shape <- square(500#m);
	image_file my_icon;
	
	string my_help;
	
	string help
	{
		return my_help;
	}
	string name
	{
		return label;
	}
	
	string cost
	{
		return ""+action_cost;
	}
	
	aspect UnAm
	{
		if( display_name = UNAM_DISPLAY)
		{
			draw shape color:#white border: is_selected ? # red : # white;
			draw my_icon size:button_size-50#m ;
		}
	}
	aspect dike
	{
		if( display_name = DIKE_DISPLAY)
		{
			draw shape color:#white border: is_selected ? # red : # white;
			draw my_icon size:button_size-50#m ;
		}
	}
	aspect carte
	{
		float select_size <- min([ui_width,ui_height]);
		shape <- rectangle(select_size, select_size);
		if(display_name = active_display or display_name = BOTH_DISPLAY)
		{
			draw my_icon size:{select_size, select_size};
			if(is_selected = true)
			{
				draw shape empty:true border: # red ;
			}
			
		}

		
	}
}

species buttons_map parent:buttons
{
	aspect base
	{
		draw shape color:#white border: is_selected ? # red : # white;
		draw my_icon size:800#m ;
	}
}

species commune
{
	string commune_name <-"";
	aspect base
	{
		draw shape  color: self=my_commune?rgb(202,170,145):#lightgray;
	}

}

species road
{
	aspect base
	{
		draw shape color:#gray;
	}
	
}

species protected_area {
	string name;
	
	aspect base 
	{
		if (buttons_map first_with(each.command =ACTION_DISPLAY_PROTECTED_AREA)).is_selected
		{
		 draw shape color: rgb (185, 255, 185,120) border:#black;
		}
	}
}

species flood_risk_area {
	
	aspect base 
	{
		if (buttons_map first_with(each.command =ACTION_DISPLAY_FLOODED_AREA)).is_selected
		{
		 draw shape color: rgb (20, 200, 255,120) border:#black;
		}
	}
}

species sites_non_classes_area {
	string name;
	
	aspect base 
	{
		/*if (buttons_map first_with(each.command =ACTION_DISPLAY_PROTECTED_AREA)).is_selected
		{*/
		 draw shape color: rgb (185, 255, 185,120) border:#black;
		/*}*/
	}
}

species UA
{
	string ua_name <- "";
	int id;
	int ua_code <- 0;
	rgb my_color <- cell_color() update: cell_color();
	int population ;
	string classe_densite -> {population =0?"vide":(population <40?"peu dense":(population <80?"densité intermédiaire":"dense"))};
	int cout_expro -> {round( population * 400* population ^ (-0.5))};
	bool isUrbanType -> {["U","Us","AU","AUs"] contains ua_name};
	bool isAdapte -> {["Us","AUs"] contains ua_name};
	bool isEnDensification <- false;



	action init_from_map(map<string, unknown> a )
	{
		self.id <- int(a at "id");
		self.ua_code <- int(a at "ua_code");
		self.ua_name <- string(a at "ua_name");
		self.population <- int(a at "population");
		self.isEnDensification <- bool(a at "isEnDensification");
		point pp<-{float(a at "locationx"), float(a at "locationy")};
		point mpp <- pp;
		int i <- 0;
		list<point> all_points <- [];
		loop while: (pp!=nil)
		{
			string xd <- a at ("locationx"+i);
			if(xd != nil)
			{
				pp <- {float(xd), float(a at ("locationy"+i))  };
				all_points <- all_points + pp;
			}
			else
			{
				pp<-nil;
			}
			i<- i + 1;
		}
		shape <- polygon(all_points);
		location <-mpp;
		
		
	}
	
	string nameOfUAcode (int a_ua_code) 
		{ string val <- "" ;
			switch (a_ua_code)
			{
				match 1 {val <- "N";}
				match 2 {val <- "U";}
				match 4 {val <- "AU";}
				match 5 {val <- "A";}
				match 6 {val <- "Us";}
				match 7 {val <- "AUs";}
					}
		return val;}
		
	int codeOfUAname (string a_ua_name) 
		{ int val <- 0 ;
			switch (a_ua_name)
			{
				match "N" {val <- 1;}
				match "U" {val <- 2;}
				match "AU" {val <- 4;}
				match "A" {val <- 5;}
				match "Us" {val <- 6;}
				match "AUs" {val <- 7;}
					}
		return val;}

		
	string fullNameOfUAname
	{string result <- "";
		switch (ua_name)
		{
			match "N" {result <- "Naturel";}
			match "U" {result <- "Urbanisé";}
			match "AU" {result <- "A urbaniser";}
			match "A" {result <- "Agricole";}
			match "Us" {result <- "Urbanisé adapté";}
			match "AUs" {result <- "A urbaniser adapté";}
		}
		return result;
	}
	rgb cell_color
	{
		rgb res <- nil;
		switch (ua_name)
		{
			match "N" {res <-rgb(11,103,59);} // naturel
			match_one ["U","Us"] { //  urbanisé
				switch classe_densite {
					match "vide" {res <- # red; } // Problème
					match "peu dense" {res <-  rgb( 0, 171, 214 ); }
					match "densité intermédiaire" {res <- rgb( 0, 129, 161 ) ;}
					match "dense" {res <- rgb( 0,77,97 ) ;}
				}
			} 
			match_one ["AU","AUs"] {res <- # yellow;} // à urbaniser
			match "A" {res <- rgb (245,147,49);} // agricole
		}
		return res;
	}
	
	action draw_display
	{
			draw shape color: my_color;
			if(isAdapte)
				{
					draw file("../images/icones/wave.png") size:self.shape.width;
				}
			if(isEnDensification)
			{
					draw file("../images/icones/crowd.png") size:self.shape.width;
			}	
	}
	
	aspect carte
	{
		if(active_display = UNAM_DISPLAY )
		{
			do draw_display;	
		}			
	}
	aspect base
	{
		do draw_display;		
//		if isAdapte {draw "A" color:#black;}
//		if isEnDensification {draw "D" color:#black;}
	}	

}

species def_cote
{
	int dike_id;
	string type;
	string commune_name_shpfile;
	rgb color <- # pink;
	float height;
	bool ganivelle <- false;
	float alt <- 0.0;
	string status;	//  "bon" "moyen" "mauvais" 
	int length_def_cote;
	
	action init_from_map(map<string, unknown> a )
	{
		self.dike_id <- int(a at "dike_id");
		self.type <- string(a at "type");
		self.status <- string(a at "status");
		self.height <- float(a at "height");
		self.alt <- float(a at "alt");
		self.ganivelle <- bool(a at "ganivelle");
	//	self.shape <- geometry(a at "shape");
	//	self.location <- point(a at "location");
		
		point pp<-{float(a at "locationx"), float(a at "locationy")};
		point mpp <- pp;
		int i <- 0;
		list<point> all_points <- [];
		loop while: (pp!=nil)
		{
			string xd <- a at ("locationx"+i);
			if(xd != nil)
			{
				pp <- {float(xd), float(a at ("locationy"+i))  };
				all_points <- all_points + pp;
			}
			else
			{
				pp<-nil;
			}
			i<- i + 1;
		}
		
		shape <- polyline(all_points);
		length_def_cote <- int(shape.perimeter);
		location <-mpp;
		
		
	}
	
	
	action init_dike {
		if status = "" {status <- "bon";} 
		if type ='' {type <- "inconnu";}
		if status = '' {status <- "bon";} 
		if status = "tres bon" {status <- "bon";} 
		if status = "tres mauvais" {status <- "mauvais";} 
		if height = 0.0 {height  <- 1.5;}////////  Les ouvrages de défense qui n'ont pas de hauteur sont mis d'office à 1.5 mètre
		length_def_cote <- int(shape.perimeter);
		}
	
	string type_ouvrage
	{
		if type = "Naturel" {return "la dune";}
		else {return  "la digue";}		
	}
	
	action draw_display
	{
			if type != 'Naturel'
			{switch status {
				match  "bon" {color <- # green;}
				match "moyen" {color <-  rgb (231, 189, 24,255);} 
				match "mauvais" {color <- # red;} 
				default { /*"casse" {color <- # yellow;}*/write "BUG: probleee status dike";}
				}
			draw 20#m around shape color: color size:300#m;
			draw shape color: #black;
				}
		else {switch status {
				match  "bon" {color <- # green;}
				match "moyen" {color <-  rgb (231, 189, 24,255);} 
				match "mauvais" {color <- # red;} 
				default { /*"casse" {color <- # yellow;}*/write "BUG: probleee status dike";}
				}
			draw 50#m around shape color: color;
			if ganivelle {loop i over: points_on(shape, 40#m) {draw circle(10,i) color: #black;}} 
		}		
	}
	
	
	aspect carte
	{
		if(active_display = DIKE_DISPLAY )
		{
			do draw_display;
		}
	}
	aspect base
	{  
		
		do draw_display;
	}	
}

species cell schedules:[]
{
	int cell_type <- 0 ; 
	int cell_id<-0;
	float water_height  <- 0.0;
	float soil_height <- 0.0;
	float rugosity;
	rgb color <- #white;
	bool inside_commune <- false;
	aspect elevation_eau 
	{
		draw shape color:self.color border:self.color bitmap:true;
	}	
}

species background_agent skills:[UI_location]
{
	aspect base
	{
		float increment <- "stpierre" = commune_name ? 0.8:0.0;
		
		geometry rec1 <- polygon([{0,0}, {0,ui_height*0.06}, {ui_width,ui_height*0.06},{ui_width,0},{0,0}]);
		geometry rec2 <- polygon([{0,0}, {0,ui_height*0.2}, {ui_width,ui_height*0.2},{ui_width,0},{0,0}]);
		point loc1  <- {location.x+ui_width/2,location.y+ui_height*(increment+0.03)};
		point loc2  <- {location.x+ui_width/2,location.y+ui_height*(increment+0.1)};
		draw  rec2 at:loc2 color:rgb(219,219,219);
		draw  rec1 at:loc1 color:rgb(148,148,148);
	}
}

species onglet skills:[UI_location]
{
	string display_name;
	string legend_name <- nil;
	
	aspect base
	{
		
			float gem_height <- ui_height;
			float gem_width <- ui_width;
			float x <- location.x - ui_width/2;
			float y <- location.y - ui_height/2 ;
			shape <- polygon([{x,y}, {x,y+gem_height}, {x+gem_width,y+gem_height},{x+gem_width,y},{x,y}]);
			
			
		if(active_display = display_name)
		{
			
			geometry rec2 <- polygon([{x,y}, {x,y+gem_height}, {x+gem_width*0.2,y+gem_height}, {x+gem_width*0.225,y+gem_height*1.2},{x+gem_width*0.25,y+gem_height},{x+gem_width,y+gem_height},{x+gem_width,y},{x,y}]);
			draw rec2 color:rgb(59,124,58);
		}
			font var0 <- font (DISPLAY_FONT_NAME,DISPLAY_FONT_SIZE, #bold + #italic); 
			draw legend_name at:{location.x  - (length(legend_name)*(DISPLAY_FONT_SIZE/2)#px/2), location.y + DISPLAY_FONT_SIZE/3#px} color:#white font:var0;
	}
}


experiment game type: gui
{
	font regular <- font("Helvetica", 14, # bold);
	geometry zone <- circle(1000#m);
	float minimum_cycle_duration <- 0.5;
	parameter "choix de la commune : " var:commune_name <- "dolus" among:["lechateau","dolus","sttrojan", "stpierre"];
	output
		{
	
		display "Panier" background:#black
		{
			species displayed_list aspect:base;
			species displayed_list_element aspect:base;
		}
		
		display "Carte" background:rgb(0, 188,196)  focus:my_commune
		{
			species commune aspect: base;
			graphics population {
			draw population_area color:rgb( 120, 120, 120 ) ;				
			}
			species UA aspect:carte;
			species action_UA aspect:carte;
			
			species action_def_cote aspect:carte;
			species def_cote aspect:carte;
		
			species road aspect:base;
			species protected_area aspect:base;
			species flood_risk_area aspect:base;

			species background_agent aspect:base;
			species onglet aspect:base;
			species buttons aspect:carte;
			species buttons_map aspect:carte;
			

			graphics "Full target dike" transparency:0.3
			{
				if (explored_dike != nil)
				{
					point target <- {explored_dike.location.x  ,explored_dike.location.y };
					point target2 <- {explored_dike.location.x + 1*(INFORMATION_BOX_SIZE.x#px),explored_dike.location.y + 1*(INFORMATION_BOX_SIZE.y#px+20#px)};
					
					draw rectangle(target,target2)   empty: false border: false color: #black ; //transparency:0.5;
					draw "Information sur "+explored_dike.type_ouvrage() at: target + { 5#px, 15#px } font: regular color: #white;
					int xpx <-0;
					draw "Longueur "+string(explored_dike.length_def_cote)+"m" at: target + { 30#px, xpx#px +35#px } font: regular color: # white;
					xpx <- xpx+20;
					if explored_dike.type_ouvrage() = "la digue" {
						draw "Hauteur "+string(round(100*explored_dike.height)/100.0)+"m" at: target + { 30#px, xpx#px +35#px } font: regular color: # white;
						xpx <- xpx+20;
					}
					draw "Altitude "+string(round(100*explored_dike.alt)/100.0)+"m" at: target + { 30#px, xpx#px +35#px } font: regular color: # white;
					draw "Etat "+string(explored_dike.status) at: target + { 30#px, xpx#px +55#px} font: regular color: # white;
				}
				
				
			}
			graphics "explore_dike_icone" 
			{
				if (explored_dike != nil )
				{if explored_dike.status != "bon" {
					point image_loc <- {explored_dike.location.x + 1*(INFORMATION_BOX_SIZE.x#px) - 50#px , explored_dike.location.y + 50#px  };
					string to_draw <- nil;
					switch(explored_dike.status)
					{
						//match "bon" { draw file("../images/icones/conforme.png") at:image_loc size:50#px; }
						match "moyen" { draw file("../images/icones/danger.png") at:image_loc size:50#px; }
						match "mauvais" { draw file("../images/icones/rupture.png") at:image_loc size:50#px; }
					}	
				  }
				}
			}
			
			graphics "Dike Button information" transparency:0.5
			{
				if (active_display = DIKE_DISPLAY and explored_buttons != nil  and explored_cell= nil and explored_dike = nil and explored_action_UA = nil)
				{
					float increment <- "stpierre" = commune_name ? (-2*INFORMATION_BOX_SIZE.y#px):0.0;
					point loc <- world.button_box_location(explored_buttons.location,2*(INFORMATION_BOX_SIZE.x#px));
					point target <-loc;
					point target2 <- {loc.x - 2*(INFORMATION_BOX_SIZE.x#px),loc.y+increment};
					point target3 <- {loc.x ,  loc.y + 2*(INFORMATION_BOX_SIZE.y#px)+increment};
					point target4 <- {target3.x,target2.y - 15#px+increment };
					draw rectangle(target2,target3)   empty: false border: false color: #black ; //transparency:0.5;
					draw explored_buttons.name() at: target2 + { 5#px, 15#px } font: regular color: #white;
					draw explored_buttons.help() at: target2 + { 30#px, 35#px } font: regular color: # white;
					if explored_buttons.command != ACTION_INSPECT_DIKE {draw "Coût de l'action : "+explored_buttons.action_cost +"/mètre" at: target2 + { 30#px, 55#px} font: regular color: # white;}
				}
			}
// LEGENDE AMENAGEMENT

			graphics "Full target UNAM" transparency:0.5
			{
				if (explored_cell != nil and explored_action_UA = nil)
				{
					point target <- {explored_cell.location.x  ,explored_cell.location.y };
					point target2 <- {explored_cell.location.x + 1*(INFORMATION_BOX_SIZE.x#px),explored_cell.location.y + 1*(INFORMATION_BOX_SIZE.y#px)};
					draw rectangle(target,target2)   empty: false border: false color: #black ; //transparency:0.5;
					draw "Zonage PLU" at: target + { 0#px, 15#px } font: regular color: # white;
					draw string(explored_cell.fullNameOfUAname()) at: target + { 30#px, 35#px } font: regular color: # white;
					if explored_cell.ua_name in ["U","Us"]{
							draw "population : "+string(explored_cell.population) at: target + { 30#px, 55#px} font: regular color: # white;
							draw "expropriation : "+string(explored_cell.cout_expro) at: target + { 30#px, 75#px} font: regular color: # white;
							}
				}
			}
			
			graphics "Action Full target UNAM" transparency:0.3
			{
				//int size <- length(moved_agents);
				if(explored_action_UA !=nil and explored_action_UA.is_applied=false)
				{
					
					UA mcell <- UA first_with(each.id = explored_action_UA.element_id);
					point target <- {mcell.location.x  ,mcell.location.y };
					point target2 <- {mcell.location.x + 1*(INFORMATION_BOX_SIZE.x#px),mcell.location.y + 1*(INFORMATION_BOX_SIZE.y#px)};
					draw rectangle(target,target2)   empty: false border: false color: #black ; //transparency:0.5;
					draw "Changement d'occupation" at: target + { 0#px, 15#px } font: regular color: # white;
					
					draw file("../images/icones/fleche.png") at: {mcell.location.x + 0.5*(INFORMATION_BOX_SIZE.x#px), target.y + 50#px}  size:50#px;
					draw ""+ (explored_action_UA.actual_application_round)   at: {mcell.location.x + 0.5*(INFORMATION_BOX_SIZE.x#px), target.y + 50#px} size:20#px; 
					draw world.chooseActionIcone(explored_action_UA.command) at:  { target2.x - 50#px, target.y +50#px} size:50#px;
					draw world.au_icone(mcell) at:  { target.x +50#px,target.y + 50#px} size:50#px;
				}
			}
			
			
			graphics "Button information UNAM" transparency:0.5
			{
				if (active_display = UNAM_DISPLAY and explored_buttons != nil and explored_cell= nil and explored_dike = nil and explored_action_UA = nil)
				{
					float increment <- "stpierre" = commune_name ? (-2*INFORMATION_BOX_SIZE.y#px):0.0;
					
					point loc <- world.button_box_location(explored_buttons.location,2*(INFORMATION_BOX_SIZE.x#px));
					point target <-loc;
					point target2 <- {loc.x - 2*(INFORMATION_BOX_SIZE.x#px),loc.y+increment};
					point target3 <- {loc.x ,  loc.y + 2*(INFORMATION_BOX_SIZE.y#px)+increment};
					draw rectangle(target2,target3)   empty: false border: false color: #black ; //transparency:0.5;
					draw explored_buttons.name() at: target2 + { 5#px, 15#px } font: regular color: # white;
					draw explored_buttons.help() at: target2 + { 30#px, 35#px } font: regular color: # white;
					if explored_buttons.command != ACTION_INSPECT_LAND_USE {
							switch explored_buttons.command {
								default {draw "Coût de l'action : "+explored_buttons.action_cost at: target2 + { 30#px, 55#px} font: regular color: # white;}
								match ACTION_MODIFY_LAND_COVER_N {
									draw "Coût si appliqué à une parcelle A : "+ACTION_COST_LAND_COVER_FROM_A_TO_N  at: target2 + { 30#px, 55#px} font: regular color: # white;
									draw "Coût si appliqué à une parcelle AU : "+ACTION_COST_LAND_COVER_FROM_AU_TO_N  at: target2 + { 30#px, 75#px} font: regular color: # white;
									draw "Coût si appliqué à une parcelle U : coût d'expropriation"  at: target2 + { 30#px, 95#px} font: regular color: # white;
								}
								match ACTION_MODIFY_LAND_COVER_AUs {
									draw "Coût si appliqué à une parcelle AU : "+explored_buttons.action_cost  at: target2 + { 30#px, 55#px} font: regular color: # white;
									draw "Coût si appliqué à une parcelle U : "+(subvention_habitat_adapte?ACTION_COST_LAND_COVER_TO_Us_SUBSIDY:ACTION_COST_LAND_COVER_TO_Us) at: target2 + { 30#px, 75#px} font: regular color: # white;
								}
							
							}
					}
				}
				
				
			}
			
			graphics "Hide everything" transparency:0.3
			{
				if(!is_active_gui)
				{
					point loc <- {world.shape.width/2,world.shape.height/2};
					geometry rec <- rectangle(world.shape.width,world.shape.height);
					draw rec at:loc color:#black;
					float msize <- min([world.shape.width/2,world.shape.height/2]);
					draw image_file("../images/ihm/logo.png") at:loc size:{msize,msize};
				}
			}
			
			
			event [mouse_down] action: button_click_general;
			event mouse_move action: mouse_move_general;
			
		}
//		display "Aménagement, PLU et habitat" focus:my_commune //camera_pos:my_commune
//		{
//			image 'background' file:"../images/fond/fnt.png"; 
//			species commune aspect: base;
//			species UA aspect: base;
//			species action_UA aspect:base;
//			species road aspect:base;
//			species protected_area aspect:base;
//			species flood_risk_area aspect:base;
//			species buttons aspect:UnAm;
//			species buttons_map aspect:base;
//			//species sites_non_classes_area aspect:base;
//			
//			graphics "Full target" transparency:0.5
//			{
//				//int size <- length(moved_agents);
//				if (explored_cell != nil and explored_action_UA = nil)
//				{
//					point target <- {explored_cell.location.x  ,explored_cell.location.y };
//					point target2 <- {explored_cell.location.x + 1*(INFORMATION_BOX_SIZE.x#px),explored_cell.location.y + 1*(INFORMATION_BOX_SIZE.y#px)};
//					draw rectangle(target,target2)   empty: false border: false color: #black ; 
//					draw "Zonage PLU" at: target + { 0#px, 15#px } font: regular color: # white;
//					draw string(explored_cell.fullNameOfUAname()) at: target + { 30#px, 35#px } font: regular color: # white;
//					if explored_cell.ua_name in ["U","Us"]{
//							draw "population : "+string(explored_cell.population) at: target + { 30#px, 55#px} font: regular color: # white;
//							draw "expropriation : "+string(explored_cell.cout_expro) at: target + { 30#px, 75#px} font: regular color: # white;
//							}
//				}
//			}
//			
//			graphics "Action Full target" transparency:0.3
//			{
//				//int size <- length(moved_agents);
//				if(explored_action_UA !=nil and explored_action_UA.is_applied=false)
//				{
//					
//					UA mcell <- UA first_with(each.id = explored_action_UA.element_id);
//					point target <- {mcell.location.x  ,mcell.location.y };
//					point target2 <- {mcell.location.x + 1*(INFORMATION_BOX_SIZE.x#px),mcell.location.y + 1*(INFORMATION_BOX_SIZE.y#px)};
//					draw rectangle(target,target2)   empty: false border: false color: #black ; 
//					draw "Changement d'occupation" at: target + { 0#px, 15#px } font: regular color: # white;
//					
//					draw file("../images/icones/fleche.png") at: {mcell.location.x + 0.5*(INFORMATION_BOX_SIZE.x#px), target.y + 50#px}  size:50#px;
//					draw ""+ (explored_action_UA.initial_application_round)   at: {mcell.location.x + 0.5*(INFORMATION_BOX_SIZE.x#px), target.y + 50#px} size:20#px; 
//					draw world.chooseActionIcone(explored_action_UA.command) at:  { target2.x - 50#px, target.y +50#px} size:50#px;
//					draw world.au_icone(mcell) at:  { target.x +50#px,target.y + 50#px} size:50#px;
//				}
//			}
//			
//			
//			graphics "Button information" transparency:0.5
//			{
//				if (explored_buttons != nil)
//				{
//					point target <- {explored_buttons.location.x  ,explored_buttons.location.y };
//					point target2 <- {explored_buttons.location.x - 2*(INFORMATION_BOX_SIZE.x#px),explored_buttons.location.y};
//					point target3 <- {explored_buttons.location.x ,  explored_buttons.location.y + 2*(INFORMATION_BOX_SIZE.y#px)};
//					draw rectangle(target2,target3)   empty: false border: false color: #black ; 
//					draw explored_buttons.name() at: target2 + { 5#px, 15#px } font: regular color: # white;
//					draw explored_buttons.help() at: target2 + { 30#px, 35#px } font: regular color: # white;
//					if explored_buttons.command != ACTION_INSPECT_LAND_USE {
//							switch explored_buttons.command {
//								default {draw "Coût de l'action : "+explored_buttons.action_cost at: target2 + { 30#px, 55#px} font: regular color: # white;}
//								match ACTION_MODIFY_LAND_COVER_N {
//									draw "Coût si appliqué à une parcelle A : "+ACTION_COST_LAND_COVER_FROM_A_TO_N  at: target2 + { 30#px, 55#px} font: regular color: # white;
//									draw "Coût si appliqué à une parcelle AU : "+ACTION_COST_LAND_COVER_FROM_AU_TO_N  at: target2 + { 30#px, 75#px} font: regular color: # white;
//									draw "Coût si appliqué à une parcelle U : coût d'expropriation"  at: target2 + { 30#px, 95#px} font: regular color: # white;
//								}
//								match ACTION_MODIFY_LAND_COVER_AUs {
//									draw "Coût si appliqué à une parcelle AU : "+explored_buttons.action_cost  at: target2 + { 30#px, 55#px} font: regular color: # white;
//									draw "Coût si appliqué à une parcelle U : "+(subvention_habitat_adapte?ACTION_COST_LAND_COVER_TO_Us_SUBSIDY:ACTION_COST_LAND_COVER_TO_Us) at: target2 + { 30#px, 75#px} font: regular color: # white;
//								}
//							
//							}
//					}
//				}
//				
//				
//			}
//			event mouse_down action: button_click_UnAM;
//			event mouse_move action: mouse_move_UnAM;
//		}
//		
//		display "Défense des côtes" focus:my_commune //camera_pos:my_commune
//		{
//			image 'background' file:"../images/fond/fnt.png"; 
//			species commune aspect:base;
//			graphics population {
//			draw population_area color:rgb( 120, 120, 120 ) ;				
//			}
//			//species cell_mnt aspect:elevation_eau;
//			species def_cote aspect:base;
//			species action_def_cote aspect:base;
//			species road aspect:base;
//			species protected_area aspect:base;
//			species flood_risk_area aspect:base;
//			species buttons aspect:dike;
//			species buttons_map aspect:base;
//			
//			graphics "Full target" transparency:0.3
//			{
//				if (explored_dike != nil)
//				{
//					point target <- {explored_dike.location.x  ,explored_dike.location.y };
//					point target2 <- {explored_dike.location.x + 1*(INFORMATION_BOX_SIZE.x#px),explored_dike.location.y + 1*(INFORMATION_BOX_SIZE.y#px)};
//					
//					draw rectangle(target,target2)   empty: false border: false color: #black ; 
//					draw "Information sur "+explored_dike.type_ouvrage() at: target + { 5#px, 15#px } font: regular color: #white;
//					int xpx <-0;
//					if explored_dike.type_ouvrage() = "la digue" {
//						draw "Hauteur"+string(round(100*explored_dike.height)/100.0)+"m" at: target + { 30#px, 35#px } font: regular color: # white;
//						xpx <- xpx+20;
//					}
//					draw "Altitude "+string(round(100*explored_dike.alt)/100.0)+"m" at: target + { 30#px, xpx#px +35#px } font: regular color: # white;
//					draw "Etat "+string(explored_dike.status) at: target + { 30#px, xpx#px +55#px} font: regular color: # white;
//				}
//				
//				
//			}
//			
//			graphics "explore_dike_icone" 
//			{
//				if (explored_dike != nil)
//				{if explored_dike.status != "bon" {
//					point image_loc <- {explored_dike.location.x + 1*(INFORMATION_BOX_SIZE.x#px) - 50#px , explored_dike.location.y + 50#px  };
//					string to_draw <- nil;
//					switch(explored_dike.status)
//					{
//						//match "bon" { draw file("../images/icones/conforme.png") at:image_loc size:50#px; }
//						match "moyen" { draw file("../images/icones/danger.png") at:image_loc size:50#px; }
//						match "mauvais" { draw file("../images/icones/rupture.png") at:image_loc size:50#px; }
//					}	
//				  }
//				}
//			}
//			
//			graphics "Dike Button information" transparency:0.5
//			{
//				if (explored_buttons != nil)
//				{
//					point target <- {explored_buttons.location.x  , explored_buttons.location.y };
//					point target2 <- {explored_buttons.location.x - 2*(INFORMATION_BOX_SIZE.x#px),explored_buttons.location.y};
//					point target3 <- {explored_buttons.location.x ,  explored_buttons.location.y + 2*(INFORMATION_BOX_SIZE.y#px)};
//					point target4 <- {target3.x,target2.y - 15#px };
//					draw rectangle(target2,target3)   empty: false border: false color: #black ; 
//					draw explored_buttons.name() at: target2 + { 5#px, 15#px } font: regular color: #white;
//					draw explored_buttons.help() at: target2 + { 30#px, 35#px } font: regular color: # white;
//					if explored_buttons.command != ACTION_INSPECT_DIKE {draw "Coût de l'action : "+explored_buttons.action_cost +"/mètre" at: target2 + { 30#px, 55#px} font: regular color: # white;}
//				}
//			}
//			
//			
//			event [mouse_down] action: button_click_dike;
//			event mouse_move action: mouse_move_dike;			
//		}
		
		/**
		 * 
		 * 
		 * ajout V2
		 */
	
		display "Panier" background:#black
		{
			species basket aspect:base;
			species basket_element aspect:base;
			species system_list_element aspect:basket;
			
			graphics "Hide everything" transparency:0.3
			{
				if(!is_active_gui)
				{
					point loc <- {world.shape.width/2,world.shape.height/2};
					geometry rec <- rectangle(world.shape.width,world.shape.height);
					draw rec at:loc color:#black;
					float msize <- min([world.shape.width/2,world.shape.height/2]);
					draw image_file("../images/ihm/logo.png") at:loc size:{msize,msize};
				}
			}		
			event mouse_down action:move_down_event;
			
		}
		
		display "Dossiers" background:#black
		{
			species work_in_progress_left_icon aspect:base;
			species work_in_progress_list aspect:base;
			species work_in_progress_element aspect:base;
			species system_list_element aspect:dossier;
			//species hideSimulationAgent aspect:Dossier
			
			graphics "Hide everything" transparency:0.3
			{
				if(!is_active_gui)
				{
					point loc <- {world.shape.width/2,world.shape.height/2};
					geometry rec <- rectangle(world.shape.width,world.shape.height);
					draw rec at:loc color:#black;
					float msize <- min([world.shape.width/2,world.shape.height/2]);
					draw image_file("../images/ihm/logo.png") at:loc size:{msize,msize};
				}
			}
			
			event mouse_down action:move_down_event_dossier;
			
		}
		
		display "Messages" background:#black
		{
			species console_left_icon aspect:base;
			species console aspect:base;
			species console_element aspect:base;
			species system_list_element aspect:console;
			
			graphics "Hide everything" transparency:0.3
			{
				if(!is_active_gui)
				{
					point loc <- {world.shape.width/2,world.shape.height/2};
					geometry rec <- rectangle(world.shape.width,world.shape.height);
					draw rec at:loc color:#black;
					float msize <- min([world.shape.width/2,world.shape.height/2]);
					draw image_file("../images/ihm/logo.png") at:loc size:{msize,msize};
				}
			}
			
			event mouse_down action:move_down_event_console;
		
		}
		
		
 	}
}

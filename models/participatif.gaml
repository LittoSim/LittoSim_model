//
/**
 *  Commune
 *  Author: nicolas
 *  Description: 
 */
model Commune



global
{
	string SERVER <- "localhost";
	
	
	string commune_name <- "dolus";
	string MANAGER_NAME <- "model_manager";
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
	file sites_non_classes_area_shape <- file("../includes/zone_etude/sites_non_classes.shp"); /// ATTENTION, SHAPE A CHANGER
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
	int ACTION_MESSAGE <- 22;
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
	
	//// action display map layers
	int ACTION_DISPLAY_PROTECTED_AREA <- 33;
	int ACTION_DISPLAY_FLOODED_AREA <- 38;
	
	// User messages
	string MSG_POSSIBLE_REGLEMENTATION_DELAY <- "La zone de travaux est soumise à des contraintes réglementaires.\nLe dossier est susceptible d’être retardé.\nSouhaitez vous poursuivre ?";
	
	geometry shape <- envelope(emprise);// 1000#m around envelope(communes_UnAm_shape)  ;
	geometry local_shape <- nil; // envelope(emprise_local);
	
	string COMMAND_SEPARATOR <- ":";
	string GROUP_NAME <- "Oleron";
	
	list<float> basket_location <- [];
	list<del_basket_button> del_buttons <-[];
	
	int basket_max_size <- 15;
	int font_size <- int(shape.height/30);
	int font_interleave <- int(shape.width/60);
	
	string UNAM_DISPLAY <- "UnAm";
	string DIKE_DISPLAY <- "sloap";
	

	int MAX_HISTORY_VIEW_SIZE <- 10;
	
	
	string active_display <- nil;
	action_done current_action <- nil;
	point previous_clicked_point <- nil;
	int action_id <- 0;
	
	float button_size <- 500#m;
	
	float widX;
	float widY;
	
	
	float a <- 1000 update: a+100;// a priori on peut enlever cette declaration car a est declare a nouveau dan la methode où c est utilisé
	
	//  Attributes of the Commune
	int budget <- 0;
	int minimal_budget <- -2000;
	int impot_recu <- 0;
	bool subvention_habitat_adapte <- false;
	bool subvention_ganivelle <- false;
	int previous_population;
	
	list<action_done> my_basket<-[];
	
	
	list<action_done> my_history<-[] update: reverse((action_UA where(each.is_sent) + action_def_cote where(each.is_sent) ) sort_by(each.id));
	list<float> history_location <- [];
	
	UA explored_cell <- nil;
	def_cote explored_dike <- nil;
	action_UA explored_action_UA<- nil;
		
	buttons explored_buttons <- nil;
	
	geometry population_area <- nil;
	
	commune my_commune <- nil;

	Network_agent game_manager <-nil;
	point INFORMATION_BOX_SIZE <- {200,80};
	geometry dike_shape_space <- nil;
	geometry unam_shape_space <- nil;
	

	
	
	init
	{
		create retrieve_date number:1;
		do implementation_tests;
		my_commune <-  commune first_with(each.nom_raccourci = commune_name);
		create Network_agent number:1 returns:net;
		game_manager <- first(net);
		create commune from: communes_shape with:[nom_raccourci::string(read("NOM_RAC"))];
		my_commune <- commune first_with(each.nom_raccourci = commune_name);
		local_shape <-envelope(my_commune);
		do init_basket;
		do init_buttons;
		do init_pending_request_button;
		create def_cote from:defense_shape with:[dike_id::int(read("OBJECTID")),type::string(read("Type_de_de")),status::string(read("Etat_ouvr")), elevation::float(read("alt")), height::float(get("hauteur")) , commune::string(read("Commune"))]
		{
			name <- "défence numéro "+ self.dike_id;
		}
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
		ask def_cote where(each.commune != commune_name_shpfile)
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
		
		ask retrieve_date
		{
			do clear_simulation();
		}
		string msg <- ""+REFRESH_ALL+COMMAND_SEPARATOR+world.get_action_id()+COMMAND_SEPARATOR+commune_name;
		ask game_manager 
		{
			map<string,string> data <- ["stringContents"::msg];
			do send to:MANAGER_NAME contents:data;
		}
	}
	
	action change_subvention_habitat_adapte_with (bool newValue) {
		subvention_habitat_adapte <- newValue;
		if subvention_habitat_adapte {
			ask buttons where (each.command = ACTION_MODIFY_LAND_COVER_AUs)
				{	action_cost <- ACTION_COST_LAND_COVER_TO_AUs_SUBSIDY;
					label <- "Changer en zone urbanisée adaptée (Subventionné).";
				}
			ask world {do user_msg("L'habitat adapté est à présent subventionné : "+ACTION_COST_LAND_COVER_TO_AUs_SUBSIDY+ " au lieu de "+ACTION_COST_LAND_COVER_TO_AUs);}
		}
		else {
			ask buttons where (each.command = ACTION_MODIFY_LAND_COVER_AUs)
				{	action_cost <- ACTION_COST_LAND_COVER_TO_AUs;
					label <- "Changer en zone urbanisée adaptée.";
				}
			ask world {do user_msg("L'habitat adapté n'est plus subventionné : "+ACTION_COST_LAND_COVER_TO_AUs+ " au lieu de "+ACTION_COST_LAND_COVER_TO_AUs_SUBSIDY);}
		}	
	}
	
	action change_subvention_ganivelle_with (bool newValue) {
		subvention_ganivelle <- newValue;
		if subvention_ganivelle {
			ask buttons where (each.command = ACTION_INSTALL_GANIVELLE)
				{	action_cost <- ACTION_COST_INSTALL_GANIVELLE_SUBSIDY;
					label <- "Installer des ganivelles (Subventionné).";
				}
			ask world {do user_msg("L'installation de ganivelles est à présent subventionné : "+ACTION_COST_INSTALL_GANIVELLE_SUBSIDY+ " au lieu de "+ACTION_COST_INSTALL_GANIVELLE);}
		}
		else {
			ask buttons where (each.command = ACTION_INSTALL_GANIVELLE)
				{	action_cost <- ACTION_COST_INSTALL_GANIVELLE;
					label <- "Installer des ganivelles.";
				}
			ask world {do user_msg("L'installation de ganivelles n'est plus subventionné : "+ACTION_COST_INSTALL_GANIVELLE+ " au lieu de "+ACTION_COST_INSTALL_GANIVELLE_SUBSIDY);}
		}	
	}
	int get_action_id
	{
		list<int> x1 <- action_def_cote collect(each.id);
		list<int> x2 <- action_UA collect(each.id);
		action_id <- max( x1 accumulate x2);
		//action_id <-// max((action_def_cote + action_UA) collect (each.id)) + 1;
		return action_id;
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
	
	action remove_selection
	{
		ask(highlight_action_button where(each.my_action != nil))
		{
			self.my_action.is_highlighted <- false;	
		}
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
			match ACTION_MODIFY_LAND_COVER_A { return image_file("../images/icones/agriculture.png");}
			match ACTION_MODIFY_LAND_COVER_AU { return image_file("../images/icones/urban.png");}
			match ACTION_MODIFY_LAND_COVER_AUs { return image_file("../images/icones/urban_adapte2.png");}
			match ACTION_MODIFY_LAND_COVER_Ui { return image_file("../images/icones/urban_intensifie.png");}
			match ACTION_MODIFY_LAND_COVER_N { return image_file("../images/icones/tree_nature.png");}
			match ACTION_CREATE_DIKE { return image_file("../images/icones/digue_validation.png");}
			match ACTION_REPAIR_DIKE { return image_file("../images/icones/digue_entretien.png");}
			match ACTION_RAISE_DIKE { return image_file("../images/icones/digue_rehausse_plus.png");}
			match ACTION_DESTROY_DIKE { return image_file("../images/icones/tree_nature.png");}
			match ACTION_INSTALL_GANIVELLE { return image_file("../images/icones/ganivelle.png");}
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
	
	action init_buttons
	{
		float interleave <- world.local_shape.height / 20;
		float button_s <- world.local_shape.height / 10;
		
		string uaHelpMessage <- "Cliquez sur la cellule à modifier.";
		string dikeHelpMessage <- "Cliquez sur la digue à modifier.";
		
		create buttons number: 1
		{
			command <- ACTION_MODIFY_LAND_COVER_A;
			label <- "Changer en zone agricole";
			action_cost <- ACTION_COST_LAND_COVER_TO_A;
			shape <- square(button_size);
			display_name <- UNAM_DISPLAY;
			my_help <- uaHelpMessage;
			location <- { world.local_shape.location.x+ (world.local_shape.width /2) + world.local_shape.width/5, world.local_shape.location.y - (world.local_shape.height /2) +interleave}; // + world.local_shape.width - 500#m,world.local_shape.location.y + 350#m };
			my_icon <- image_file("../images/icones/agriculture.png");
		}

		create buttons number: 1
		{
			command <- ACTION_MODIFY_LAND_COVER_AU;
			label <- "Changer en zone à urbaniser";
			action_cost <- ACTION_COST_LAND_COVER_TO_AU;
			shape <- square(button_size);
			display_name <- UNAM_DISPLAY;
			my_help <- uaHelpMessage;
			location <- { world.local_shape.location.x+ (world.local_shape.width /2) + world.local_shape.width/5, world.local_shape.location.y - (world.local_shape.height /2) +interleave + interleave+ button_size }; //{  world.local_shape.location.x + world.local_shape.width - 500#m,world.local_shape.location.y + 350#m + 600#m };
			my_icon <- image_file("../images/icones/urban.png");
		}
		
		create buttons number: 1
		{
			command <- ACTION_MODIFY_LAND_COVER_AUs;
			label <- "Changer en zone urbanisée adaptée";
			action_cost <- ACTION_COST_LAND_COVER_TO_AUs;
			my_help <- uaHelpMessage;
			shape <- square(button_size);
			display_name <- UNAM_DISPLAY;
			location <- { world.local_shape.location.x+ (world.local_shape.width /2) + world.local_shape.width/5 + 2*interleave, world.local_shape.location.y - (world.local_shape.height /2) +2*interleave + button_size }; //{  world.local_shape.location.x + world.local_shape.width - 500#m,world.local_shape.location.y + 350#m + 600#m };
			my_icon <- image_file("../images/icones/urban_adapte2.png");
		}
		
		create buttons number: 1
		{
			command <- ACTION_MODIFY_LAND_COVER_Ui;
			label <- "Inciter à la densification";
			action_cost <- ACTION_COST_LAND_COVER_TO_Ui;
			my_help <- uaHelpMessage;
			shape <- square(button_size);
			display_name <- UNAM_DISPLAY;
			location <- { world.local_shape.location.x+ (world.local_shape.width /2) + world.local_shape.width/5 + 4*interleave, world.local_shape.location.y - (world.local_shape.height /2) +2*interleave + button_size }; //{  world.local_shape.location.x + world.local_shape.width - 500#m,world.local_shape.location.y + 350#m + 600#m };
			my_icon <- image_file("../images/icones/urban_intensifie.png");
		}
		
		
		create buttons number: 1
		{
			command <- ACTION_MODIFY_LAND_COVER_N;
			label <- "Changer en zone naturelle";
			action_cost <- ACTION_COST_LAND_COVER_FROM_AU_TO_N;
			shape <- square(button_size);
			display_name <- UNAM_DISPLAY;
			my_help <- uaHelpMessage;
			location <- { world.local_shape.location.x+ (world.local_shape.width /2) + world.local_shape.width/5, world.local_shape.location.y - (world.local_shape.height /2) +interleave +2* (interleave+ button_size) };
			my_icon <- image_file("../images/icones/tree_nature.png");
			
		}
		create buttons number: 1
		{
			command <- ACTION_INSPECT_LAND_USE;
			label <- "Inspecter une unité d'aménagement";
			action_cost <- 0;
			my_help <- "Glissez le pointeur sur les cellules à inspecter.";
			shape <- square(button_size);
			display_name <- UNAM_DISPLAY;
			location <- { world.local_shape.location.x+ (world.local_shape.width /2) + world.local_shape.width/5, world.local_shape.location.y - (world.local_shape.height /2) +interleave +3* (interleave+ button_size) };
			my_icon <- image_file("../images/icones/Loupe.png");
			
		}
		
		create buttons number: 1
		{
			command <- ACTION_CREATE_DIKE;
			label <- "Construire une digue";
			action_cost <- ACTION_COST_DIKE_CREATE;
			shape <- square(button_size);
			display_name <- DIKE_DISPLAY;
			my_help <- "Cliquez aux deux extrémités du linéaire de digue.";
			location <- { world.local_shape.location.x+ (world.local_shape.width /2) + world.local_shape.width/5, world.local_shape.location.y - (world.local_shape.height /2) +interleave  }; // + world.local_shape.width - 500#m,world.local_shape.location.y + 350#m };
			my_icon <- image_file("../images/icones/digue_validation.png");
		}

		create buttons number: 1
		{
			command <- ACTION_REPAIR_DIKE;
			label <- "Rénover une digue";
			action_cost <- ACTION_COST_DIKE_REPAIR;
			shape <- square(button_size);
			my_help <- dikeHelpMessage;
			display_name <- DIKE_DISPLAY;
		//	my_help <- "Cliquez sur la digue à réparer";
			location <- { world.local_shape.location.x+ (world.local_shape.width /2) + world.local_shape.width/5, world.local_shape.location.y - (world.local_shape.height /2) +interleave + 2*(interleave+ button_size) }; //{  world.local_shape.location.x + world.local_shape.width - 500#m,world.local_shape.location.y + 350#m + 600#m };
			my_icon <- image_file("../images/icones/digue_entretien.png");
			
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
			location <- { world.local_shape.location.x+ (world.local_shape.width /2) + world.local_shape.width/5, world.local_shape.location.y - (world.local_shape.height /2) +interleave +3* (interleave+ button_size) };
			my_icon <- image_file("../images/icones/digue_suppression.png");
			
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
			location <- { world.local_shape.location.x+ (world.local_shape.width /2) + world.local_shape.width/5, world.local_shape.location.y - (world.local_shape.height /2) +interleave +1* (interleave+ button_size) };
			my_icon <- image_file("../images/icones/digue_rehausse_plus.png");
			
		}
		
		create buttons number: 1
		{
			command <- ACTION_INSTALL_GANIVELLE;
			label <- "Installer des ganivelles";
			action_cost <- ACTION_COST_INSTALL_GANIVELLE;
			shape <- square(button_size);
			display_name <- DIKE_DISPLAY;
			my_help <- "Cliquez sur la dune pour installer une ganivelle.";	
			location <- { world.local_shape.location.x+ (world.local_shape.width /2) + world.local_shape.width/5, world.local_shape.location.y - (world.local_shape.height /2) +interleave+4* (interleave+ button_size)};
			my_icon <- image_file("../images/icones/ganivelle.png");
		}
		
		create buttons number: 1
		{
			command <- ACTION_INSPECT_DIKE;
			label <- "Inspecter un ouvrage de défense";
			action_cost <- 0;
			shape <- square(button_size);
			my_help <- "Glissez le pointeur sur les digues et dunes.";
			display_name <- DIKE_DISPLAY;
			location <- { world.local_shape.location.x+ (world.local_shape.width /2) + world.local_shape.width/5, world.local_shape.location.y - (world.local_shape.height /2) +interleave +5* (interleave+ button_size) };
			my_icon <- image_file("../images/icones/Loupe.png");
			
		}

		//////////   Boutons d'affichage de couches d'infos	
		create buttons_map number: 1
		{
			command <- ACTION_DISPLAY_PROTECTED_AREA;
			label <- "Afficher les zones proétégées";
			shape <- square(850);
			location <- { 1000,8000 };
			my_icon <- image_file("../images/icones/sans_zones_protegees.png");
			is_selected <- false;
		}	
		create buttons_map number: 1
		{
			command <- ACTION_DISPLAY_FLOODED_AREA;
			label <- "Afficher les zones innondées";
			shape <- square(850);
			location <- { 1000,9000 };
			my_icon <- image_file("../images/icones/sans_zones_innondees.png");
			is_selected <- false;
		}
	}
	
	action init_basket
	{
		int i <- 0;
		loop while: (i< basket_max_size)
		{
			float y_location <- font_size+ font_interleave/2 + i* (font_size + font_interleave);
			basket_location <- basket_location + y_location;
			create del_basket_button number:1 returns:mb
			{
				location <- {font_interleave+ font_size/2,y_location};
				my_index<- i;
			}
			
			i<-i+1;
		}
		
		create basket_validation number:1;
		}


	action init_pending_request_button
	{
		int i <- 0;
		loop while: (i< 	MAX_HISTORY_VIEW_SIZE )
		{
			float y_location <- font_size+ font_interleave/2 + i* (font_size);
			//basket_location <- basket_location + y_location;
			create highlight_action_button number:1 returns:mb
			{
				location <- {font_interleave+ font_size/2,y_location};
				my_index<- i;
			}
			i<-i+1;
		}
		
	}
	bool basket_overflow
	{
		if(basket_max_size = length(my_basket))
		{
			map<string,unknown> values2 <- user_input("Avertissement","Vous avez atteint la capacité maximum de votre panier, veuillez valider votre panier avant de continuer"::true);
			return true;
		}
		return false;
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
	
	action history_click //(point loc, list selected_agents)
	{
		point loc <- #user_location;
		
		do remove_selection;
		list<highlight_action_button> bsk <-  highlight_action_button overlapping loc; // agts of_species dike;
		
		if(length(bsk)>0)
		{
			highlight_action_button but <- first(bsk);
			but.my_action.is_highlighted<-true;
		}
	}
	
	action basket_click //(point loc, list selected_agents)
	{
		point loc <- #user_location;
		
		do remove_selection;
		list<del_basket_button> bsk_del <-  del_basket_button overlapping loc; // agts of_species dike;
		
		if(length(bsk_del)>0)
		{
			del_basket_button but<-first(bsk_del);
			action_done act <- my_basket at but.my_index;
			ask act
			{
				do die;
			}
			remove act from:my_basket;
		}
		list<basket_validation> bsk_validation <-  basket_validation  overlapping loc;
		
		basket_validation btt <- first(basket_validation);
		bool valid <-  btt overlaps loc;
		if(valid)
		{	if round = 0
			{
				map<string,unknown> res <- user_input("Avertissement", "La simulation n'a pas encore commencée"::"" );
				return;
			}
			if(   minimal_budget >(budget - round(sum(my_basket collect(each.cost)))))
			{
				string budget_display <- "Vous ne disposez pas du budget suffisant pour réaliser toutes ces actions";
				ask world {do user_msg (budget_display);}
				map<string,unknown> res <- user_input("Avertissement", budget_display::"" );//[budget_display:: false]);
				return;
			}
			/* Ce n'est pas delayOfAction qui permet de savoir si une action peut etre retardé plus que prévu 
			 * delayOfAction se refère au délai normal de mise en oeuvre de l'action
			 * Par ailleurs l'avertissement sur un délai supplémentaire possible se fait avant, lorsque le joeur click sur l'éléments où appliquer l'action
			 * Donc, on retire ce bout de code, et on implémente ces messages d'avertisseement dans les actions change_dike et change_plu  
			 int nb_delayed <- my_basket count(delayOfAction(each.command) > 0);
			string action_delayed <- nb_delayed = 0 ? "":"Attention, une ou plusieurs de vos réalisations risquent de faire l'objet d'un retard\n";*/
			
			string ask_display <- "Vous êtes sur le point de valider votre panier \n"+/*action_delayed+*/" Cocher la case, pour accepter le panier et valider";
			map<string,bool> res <- user_input("Avertissement", ask_display::false);
			if(res at ask_display )
			{
				ask first(bsk_validation)
				{
					do send_basket;
				}
			}
		}
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
				default {do modify_dike(loc, selected_dike,selected_button);}
			}
		}
	}
	
	action inspect_UNAM//(point mloc, list agts, buttons but)
	{
		point mloc <- #user_location;
		
		list<def_cote> selected_dike <-   def_cote where (each distance_to mloc < MOUSE_BUFFER); // agts of_species dike;
		
		if(length(selected_dike)>0)
		{
			def_cote dk<- selected_dike closest_to mloc;
			create action_def_cote number:1 returns:action_list
			 {
				id <- 0;
				shape <- dk.shape;
				chosen_element_id <- dk.dike_id;
			 }
			 action_def_cote tmp <- first(action_list);
			 string chain <- "Caractéristiques de la digue \n Type :"+ dk.type+" \n Etat général : "+dk.status+"\n Hauteur : "+ dk.height+"m";
			 map<string,unknown> values2 <- user_input("Inspecteur de digue",chain::"");		
			ask(tmp)
			{
				do die;
			}
		}
	}
	
	action inspect_dike(point mloc, list<def_cote> agts, buttons but)
	{
		list<def_cote> selected_dike <- agts ;
		
		if(length(selected_dike)>0)
		{
			def_cote dk<- selected_dike closest_to mloc;
			create action_def_cote number:1 returns:action_list
			 {
				id <- 0;
				shape <- dk.shape;
				chosen_element_id <- dk.dike_id;
			 }
			 action_def_cote tmp <- first(action_list);
			 string chain <- "Caractéristiques de la digue \n Type :"+ dk.type+" \n Etat général : "+dk.status+"\n Hauteur : "+ dk.height+"m";
			 map<string,unknown> values2 <- user_input("Inspecteur de digue",chain::string(dk.dike_id));		
			ask(tmp)
			{
				do die;
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
				chosen_element_id <- dk.dike_id;
				self.command <- but.command;
				self.application_round <- round  + (world.delayOfAction(self.command));
				shape <- dk.shape;
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
					chosen_element_id <- -1;
					self.command <- ACTION_CREATE_DIKE;
					self.application_round <- round  + (world.delayOfAction(self.command));
					shape <- polyline([previous_clicked_point,loc]);
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
					or (ua_name ="U" and selected_button.command = ACTION_MODIFY_LAND_COVER_AU)
					or (ua_name ="AU" and selected_button.command = ACTION_MODIFY_LAND_COVER_AU)
					or (ua_name ="AUs" and selected_button.command = ACTION_MODIFY_LAND_COVER_AUs)
					or (ua_name ="Us" and selected_button.command = ACTION_MODIFY_LAND_COVER_AUs)
					or (ua_name ="A" and selected_button.command = ACTION_MODIFY_LAND_COVER_A)
					or (ua_name in ["A", "N", "AU","AUs"] and selected_button.command = ACTION_MODIFY_LAND_COVER_Ui)
					or (length((action_done collect(each.location)) inside cell_tmp)>0  ))
				{	// Action incohérente -> la case est déjà dans l'état souhaité
					return;
				}
				/* Contrairement à la V1, ds cette version c'est autorisé. Cf mail de Marianne Rulier du 5-12-2016
				 if(((ua_name ="N") and selected_button.command = ACTION_MODIFY_LAND_COVER_A))
				{
					bool res<-false;
					string chain <- "Transformer une zone naturelle en zone agricole est interdit par la législation";
					map<string,unknown> values2 <- user_input("Avertissement",chain::"");		
					
					return;
				}*/
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
					ask game_manager
					{
						do send_information(chain+"\n response: "+(values2 at chain ));
					}
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
					chosen_element_id <- myself.id;
					command <- selected_button.command;
					shape <- myself.shape;
					application_round <- round  + (world.delayOfAction(command));
					previous_ua_name <- myself.ua_name;
					label <- selected_button.label;
					cost <- selected_button.action_cost;
					// Overwrites in case action d'expropriation (delai d'execution et Cost)
					if command = ACTION_MODIFY_LAND_COVER_N and previous_ua_name in ["U","Us"] { 
							application_round <- round + world.delayOfAction(ACTION_EXPROPRIATION);
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
						match ACTION_DISPLAY_PROTECTED_AREA {my_icon <-  is_selected ? image_file("../images/icones/avec_zones_protegees.png") :  image_file("../images/icones/sans_zones_protegees.png");}
						match ACTION_DISPLAY_FLOODED_AREA {my_icon <-  is_selected ? image_file("../images/icones/avec_zones_innondees.png") :  image_file("../images/icones/sans_zones_innondees.png");}
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
			bool clic_deselect <- false;
			if length (current_active_button) > 1 {write "BUG: Problème -> deux boutons sélectionnés en même temps";}
			if length (current_active_button) = 1 
				{if (first (current_active_button)).command = (first(cliked_dike_button)).command
					{clic_deselect <-true;}}
			do clear_selected_button;
			if !clic_deselect 
				{ask (first(cliked_dike_button))
					{
					is_selected <- true;
					}
				}
		}
		else
		{	buttons_map a_MAP_button <- first (buttons_map where (each distance_to loc < MOUSE_BUFFER));
			if a_MAP_button != nil {
				ask a_MAP_button {
					is_selected <- not(is_selected);
					switch command {
						match ACTION_DISPLAY_PROTECTED_AREA {my_icon <-  is_selected ? image_file("../images/icones/avec_zones_protegees.png") :  image_file("../images/icones/sans_zones_protegees.png");}
						match ACTION_DISPLAY_FLOODED_AREA {my_icon <-  is_selected ? image_file("../images/icones/avec_zones_innondees.png") :  image_file("../images/icones/sans_zones_innondees.png");}
					}			
				}
			}
			else {do change_dike;}
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
	
	action user_msg (string msg) {
		//soit on envoie le msg par un pop UP
		//map<string,unknown> tmp <- user_input(msg::"");
		//soit on l'écrit ds la console avec une entete ou pas
		write "USER MSG: "+msg;
	}
	
	/*reflex test {
		if !subvention_ganivelle {
			do change_subvention_ganivelle_with(true);
		}
	}*/
}

species del_basket_button
{
	int my_index <- 0;
	init
	{
		shape <- square(font_size);
	}
	
	action del_action
	{
		
	}
	
	aspect base
	{
		if(my_index < length(my_basket))
		{
			draw image_file("../images/icones/suppression.png") size:font_size;
		}
		
	}
}

species highlight_action_button
{
	int my_index <- 0;
	action_done my_action -> {my_index<length(my_history)? my_history[my_index]:nil};
	init
	{
		shape <- square(font_size);
	}
	aspect base
	{
		if(my_index < min([MAX_HISTORY_VIEW_SIZE,length(my_history)]))
		{
			draw image_file("../images/icones/Loupe.png") size:font_size/2;
		}
		
	}
	
}


species retrieve_date skills:[network]
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
				match "action_done"
				{
					write "receive message from " +  m.sender+ " " + mc["action_type"];
					if(mc["action_type"]="dike")
					{
						write "receive message from " + m.sender+ " "+ mc["id"] ;
			
						action_def_cote tmp <- action_def_cote first_with(each.id =int(mc["id"]) );
						
						if(tmp = nil)
						{
							create action_def_cote number:1
							{
								id <- int(mc["id"]);
							}
							tmp<- action_def_cote first_with(each.id =int(mc["id"]) );
						}
						
						ask tmp
						{
							do init_from_map(mc);
						}
					}
					else
					{
						action_UA tmp <- action_UA first_with(each.id =int(mc["id"]) );
						
						if(tmp = nil)
						{
							create action_UA number:1
							{
								id <- int(mc["id"]);
							}
							tmp<- action_UA first_with(each.id =int(mc["id"]) );
						}
						
						ask tmp
						{
							do init_from_map(mc);
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
			
			}
			
		}
	}
}

species action_done
{
	int id;
	int chosen_element_id<-0;
	//string command_group <- "";
	int command <- -1;
	string label <- "no name";
	float cost <- 0.0;
	int application_round <- -1;
	int round_delay <- 0 ; // nb rounds of delay
	bool is_delayed ->{round_delay>0} ;
	bool is_sent <- false;
	bool is_applied <- false;
	bool is_highlighted <- false;
	// attributs ajouté par NB dans la specie action_done (modèle oleronV2.gaml) pour avoir les infos en plus sur les actions réalisés, nécessaires pour que le leader puisse applique des leviers
	string action_type <- "dike" ; //can be "dike" or "PLU"
	string previous_ua_name <-"nil";  // for PLU action
	bool isExpropriation <- false; // for PLU action
	bool inProtectedArea <- false; // for dike action
	bool inLittoralArea <- false; // for PLU action // c'est la bande des 400 m par rapport au trait de cote
	bool inRiskArea <- false; // for PLU action / Ca correspond à la zone PPR qui est un shp chargé
	bool isInlandDike <- false; // for dike action // ce sont les rétro-digues
	
	
	action init_from_map(map<string, unknown> a )
	{
		self.id <- int(a at "id");
		self.chosen_element_id <- int(a at "chosen_element_id");
		self.command <- int(a at "command");
		self.label <- a at "label";
		self.cost <- float(a at "cost");
		self.application_round <- int(a at "application_round");
		self.round_delay <- int(a at "round_delay");
		self.isInlandDike <- bool(a at "isInlandDike");
		self.inRiskArea <- bool(a at "inRiskArea");
		self.inLittoralArea <- bool(a at "inLittoralArea");
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
			shape <- polyline(all_points);
			
		}
		else
		{
			shape <- polygon(all_points);
		}
		location <-mpp;
		write "load location "+ location + " shape " + shape;
		
		
		
	}
	
	action apply;
	
	string serialize_command
	{
		string result <-"";
		//write "pout poute "+ chosen_element_id;
		
	result <- ""+
		command+COMMAND_SEPARATOR+  //0
		id+COMMAND_SEPARATOR+
		application_round+COMMAND_SEPARATOR+
		chosen_element_id+COMMAND_SEPARATOR+			//3
		action_type +COMMAND_SEPARATOR+
		inProtectedArea+COMMAND_SEPARATOR+		//5
		previous_ua_name+COMMAND_SEPARATOR+
		isExpropriation+COMMAND_SEPARATOR+					//7
		int(cost)	;					//8
		
	if command = ACTION_CREATE_DIKE  {
				point end <- last(shape.points);
				point origin <- first(shape.points);
				result <- result+
					COMMAND_SEPARATOR+( origin.x)+	//9
					COMMAND_SEPARATOR+(origin.y) +
					COMMAND_SEPARATOR+(end.x)+		//11
					COMMAND_SEPARATOR+(end.y)+
					COMMAND_SEPARATOR+location.x+	//13
					COMMAND_SEPARATOR+location.y;
		}
			
	/*switch(command)
		{
			match ACTION_CREATE_DIKE  {
				point end <- last(shape.points);
				point origin <- first(shape.points);
				result <- ""+command+COMMAND_SEPARATOR+id+COMMAND_SEPARATOR+application_round+COMMAND_SEPARATOR+( origin.x)+COMMAND_SEPARATOR+(origin.y) +COMMAND_SEPARATOR+(end.x)+COMMAND_SEPARATOR+(end.y)+COMMAND_SEPARATOR+location.x+COMMAND_SEPARATOR+location.y;
			}
			
			default {
				result <- ""+command+COMMAND_SEPARATOR+id+COMMAND_SEPARATOR+application_round+COMMAND_SEPARATOR+chosen_element_id;
			}
		}*/
		
		return result;	
	}
	
	
	action draw_action
	{
		if(!is_sent)
		{
			int indx <- my_basket index_of self;
			float y_loc <- basket_location[indx];
			float x_loc <- font_interleave + 12* (font_size+font_interleave);
			
			draw label +" ("+string(application_round-round)+")" at:{font_size+2*font_interleave,y_loc+font_size/2} size:font_size#m color:#black;
			draw "    "+ round(cost) at:{x_loc,y_loc+font_size/2} size:font_size#m color:#black;
			if((indx +1) = length(my_basket))
			{
				string text<- "---------------";
				draw text at: {x_loc,font_size+ font_interleave/2 + (indx +1)* (font_size + font_interleave)} size:font_size color:#black;
				draw "    "+round(sum(my_basket collect(each.cost))) at: {x_loc,font_size+ font_interleave/2 + (indx +2)* (font_size + font_interleave)} size:font_size color:#black;
			}
		}
	}
	
	action draw_history
	{
		if(is_sent)
		{
		//	write "history length "+ length(history);
			int indx <- my_history index_of self;
			float y_loc <- (indx +1)  * font_size ; //basket_location[indx];
			float x_loc <- font_interleave + 12* (font_size+font_interleave);
			float x_loc2 <- font_interleave + 20* (font_size+font_interleave);
			if(self.is_highlighted)
			{
				draw rectangle({font_size+2*font_interleave,y_loc},{x_loc2,y_loc+font_size/2} ) color:#yellow;
			}
			string txt <- label;
			if !self.is_applied {txt <- txt +" ("+string(application_round-round)+")"+(self.is_delayed?" (+"+string(round_delay)+")":""); }
			draw txt at:{font_size+2*font_interleave,y_loc+font_size/2} size:font_size#m color:self.is_applied?#black:(self.is_delayed?#red:#orange);
			draw "    "+ round(cost) at:{x_loc,y_loc+font_size/2} size:font_size#m color:self.is_applied?#black:(self.is_delayed?#red:#orange);
		}
	}
	
}

species Network_agent skills:[network]
{
	init {
		
		do connect to:SERVER with_name:world.commune_name;	
		string mm<- ""+CONNECTION_MESSAGE+COMMAND_SEPARATOR+world.commune_name;
			map<string,string> data <- ["stringContents"::mm];
			do send to:MANAGER_NAME contents:data;
		
	//	do send to:MANAGER_NAME contents:data;
	}
	
	reflex receive_message 
	{
		loop while:has_more_message()
		{
			message msg <- fetch_message();
			//write msg.contents;
			string my_msg <- msg.contents;
			list<string> data <- my_msg split_with COMMAND_SEPARATOR;
			int command <- int(data[0]);
			int action_id <- int(data[1]);
			switch(int(data[0]))
				{
		
		 			match INFORM_ROUND
					{
						round<-int(data[2]);
						ask action_UA where (not(each.is_sent)) {application_round<-application_round+1;}
						ask action_def_cote where (not(each.is_sent)) {application_round<-application_round+1;}
						switch round {
							match 1 {ask world {do user_msg("La simulation démarre. C'est le tour 1");}}
							match 0 {}
							default {
								ask world {do user_msg("Le tour "+ round+" a commencé");}
								int tmp <- copy(previous_population);
								previous_population <- world.current_population();
								ask world {do user_msg(""+((previous_population-tmp)=0?"":("Votre commune accueille "+(previous_population-tmp) + " nouveaux arrivants.\n"))+"La population de votre commune est de "+previous_population+" habitants.");}
							}
							}							
					}
					match SUBVENTIONNER_GANIVELLE
					{
						ask world {do change_subvention_ganivelle_with(!subvention_ganivelle);}
					}
					match SUBVENTIONNER_HABITAT_ADAPTE
					{
						ask world {do change_subvention_habitat_adapte_with(!subvention_habitat_adapte);}
					}
					match NOTIFY_DELAY
					{
						int entityTypeCode<- int(data[2]);
						int id <- int(data[3]);
						int nb <- int(data[4]);
						//write ""+entityTypeCode+" "+id + " " +nb;
						switch entityTypeCode {
							match ENTITY_TYPE_CODE_DEF_COTE {do action_def_cote_delay_acknowledgment(id, nb);} 
							match ENTITY_TYPE_CODE_UA {do action_UA_delay_acknowledgment(id, nb);} 
							default {write "BUG: probleme: entityTypeCode pas reconnu : " + entityTypeCode;}
						}
					}
					
					match INFORM_TAX_GAIN
					{	impot_recu <- int(data[2]);
						round <-int(data[3])+1;
						ask world {do user_msg ("Vous avez perçu des impôts de "+ world.separateur_milliers(int(data[2]))+ " pour le tour "+data[3]);}
					}	
					
					match INFORM_GRANT_RECEIVED
					{
						ask world {do user_msg ("Vous avez reçu une subvention d'un montant de "+ world.separateur_milliers(int(data[2])));}
		
					}	
					match INFORM_FINE_RECEIVED
					{
						ask world {do user_msg ("Vous avez reçu une amende d'un montant de "+ world.separateur_milliers(int(data[2])));}
		
					}	
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
							elevation <-float(data[11]);
							status <-data[9];
							type <- data[8];
							height <-float(data[7]);
						}
						do action_dike_application_acknowledgment(d_id);	
					}
					match ACTION_DIKE_DROPPED {
						int d_id <- int(data[2]);
						do action_dike_application_acknowledgment(d_id);	
						ask def_cote where(each.dike_id =d_id )
						{
							do die;
						}
					}
					match ACTION_LAND_COVER_UPDATE {
						int d_id <- int(data[2]);	
					//	action_done act <- first( action_done overlapping self);
						do action_land_cover_application_acknowledgment(d_id);
							
						ask UA where(each.id = d_id)
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
		
		
		act.chosen_element_id <- int(mdata[3]);
		act.command <- int(mdata[5]);
		act.label <- mdata[6];
		act.cost <- float(mdata[7]);
		act.application_round <- int(mdata[8]);
		act.round_delay <- int(mdata[9]);
		act.isInlandDike <- bool(mdata[10]);
		act.inRiskArea <- bool(mdata[11]);
		act.inLittoralArea <- bool(mdata[12]);
		act.isExpropriation <- bool(mdata[13]);
		act.inProtectedArea <- bool(mdata[14]);
		act.previous_ua_name <- string(mdata[15]);
		act.action_type <- string(mdata[16]);
		string go <- string(mdata[17]);
		act.shape <- geometry(go);
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
		float elev <- msg[10];
		geometry pli <- polyline([{x1,y1},{x2,y2}]);
		int df_id <- 0;
		create def_cote number:1 returns: dikes
		{
			shape <- pli;
			dike_id <- d_id;
			type<-tp;
			height<- hg;
			status<-st;
			elevation <- elev;
			ask first(action_def_cote overlapping self) {chosen_element_id <- d_id;
			}
		}	
		
		do action_dike_application_acknowledgment(d_id);			
	}
	
	action action_dike_application_acknowledgment(int m_action_id)
	{//write "UPDATE dike " + m_action_id;
		ask action_def_cote where(each.chosen_element_id  = m_action_id)
		{ self.is_applied <- true;
		}
	}
	
	action action_land_cover_application_acknowledgment(int m_action_id)
	{//write "UPDATE UA " + m_action_id;
		ask action_UA where(each.chosen_element_id = m_action_id)
		{ 
			self.is_applied <- true;
		}
	}
	 
	 
	action action_def_cote_delay_acknowledgment(int m_action_id, int nb)
	{ 
		ask action_def_cote where(each.id  = m_action_id)
		{ 	write nb;
			if nb = 3000 {ask world {do user_msg("Le dossier travaux de "+myself.type_def_cote+" n°"+m_action_id+" a été abrogé pour non conformité réglementaire.");}}
			else {ask world {do user_msg("Le dossier travaux de "+myself.type_def_cote+" n°"+m_action_id+" a été retardé de "+nb+" tour"+(nb=1?"":"s")+" en raison de contraintes réglementaires.");}}
			round_delay <- round_delay + nb;
			application_round <- application_round + nb;
		}
	}
	
	action action_UA_delay_acknowledgment(int m_action_id, int nb)
	{ 
		ask action_UA where(each.id  = m_action_id)
		{  
			if nb = 3000 {ask world {do user_msg("Le dossier 'aménagement (PLU ou Habitat) n°"+m_action_id+" a été abrogé pour non conformité réglementaire.");}}
			else {ask world {do user_msg("Le dossier d'aménagement (PLU ou Habitat) n°"+m_action_id+" a été retardé de "+nb+" tour"+(nb=1?"":"s")+" en raison de contraintes réglementaires.");}}
			round_delay <- round_delay + nb;
			application_round <- application_round + nb;
		}
	}
	
	action send_information(string msg)
	{
		string val <-""+ ACTION_MESSAGE + COMMAND_SEPARATOR+world.get_action_id()+ COMMAND_SEPARATOR+msg;
		map<string,string> data <- ["stringContents"::msg];
		do send to:MANAGER_NAME contents:data;
		
	}
	
	action send_basket
	{
		action_done act <-nil;
		loop act over:my_basket
		{
			string val <- act.serialize_command();
			act.is_sent <- true;
			map<string,string> data <- ["stringContents"::val];
			do send to:MANAGER_NAME contents:data;
			//my_history <- []+act +  my_history;
			
		}
		my_basket<-[];
	}
	
}

species history
{
	point location <- {0,0} update:{font_interleave + 12* (font_size + font_interleave),font_size+ font_interleave/2 + (length(my_basket) +2)* (font_size + font_interleave)};
	list<action_done> all_action;
	init {
		shape <- square(button_size);
		all_action <- [];
	}
}


species basket_validation
{
	
	reflex update_loc
	{
		location <-  {font_interleave + 12* (font_size + font_interleave),font_size+ font_interleave/2 + (length(my_basket) +2)* (font_size + font_interleave)};
		shape <- square(world.shape.width/8);
	}
	init {
		shape <- square(world.shape.width/8);
	}
	
	action send_basket
	{
		ask game_manager
		{
			do send_basket;
		}
	}
	aspect base
	{
		float x_loc <- font_interleave + 12* (font_size + font_interleave);
		float y_loc <- font_size+ font_interleave/2 + (length(my_basket) +2)* (font_size + font_interleave);
	//	location <- {font_interleave + 12* (font_size + font_interleave),font_size+ font_interleave/2 + (length(my_basket) +2)* (font_size + font_interleave)};
	
		if(length(my_basket) = 0)
		{
			draw "Aucune action enregistrée" size:font_size color:#black at:{0 , y_loc };
		}
		else
		{
			draw image_file("../images/icones/validation.png") at:location size:world.shape.width/8 ;
		}
		
		//draw "Budget : "+ budget color:#black size:font_size at:{0 , font_size+ font_interleave/2 + (length(my_basket) +4)* (font_size + font_interleave) } ;
		//draw "Budget restant : " + (budget - round(sum(my_basket collect(each.cost)))) color:#black  size:font_size at:{0 , font_size+ font_interleave/2 + (length(my_basket) +5)* (font_size + font_interleave) } ;
	}
}

species action_def_cote parent:action_done
{
	string action_type <- "dike";
	string type_def_cote -> {command = ACTION_INSTALL_GANIVELLE?"dune":"digue"};
	
	rgb define_color
	{
		switch(command)
		{
			 match ACTION_CREATE_DIKE { return #blue;}
			 match ACTION_REPAIR_DIKE {return #green;}
			 match ACTION_DESTROY_DIKE {return #brown;}
			 match ACTION_RAISE_DIKE {return #yellow;}
			 match ACTION_INSTALL_GANIVELLE {return #indigo;}
		} 
		return #grey;
	}
	
	aspect base
	{
		if !is_applied {draw  20#m around shape color:is_highlighted?#yellow:((is_sent)?#orange:define_color()) border:is_highlighted?#yellow:((is_sent)?#orange:#red);}
	}
	
	aspect basket
	{
		do draw_action;
	}
	
	aspect history
	{
		do draw_history;
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
			 match ACTION_MODIFY_LAND_COVER_A { return #brown;}
			 match_one [ACTION_MODIFY_LAND_COVER_AU,ACTION_MODIFY_LAND_COVER_AUs,ACTION_MODIFY_LAND_COVER_Us, ACTION_MODIFY_LAND_COVER_Ui] {return #black;}
			 match ACTION_MODIFY_LAND_COVER_N {return #green;}
		} 
		return #grey;
	}
	action apply
	{
		//creer une digue
	}
	aspect base
	{
		if !is_applied {
			
			draw shape  color:is_highlighted?#yellow:((is_sent)?#orange:define_color()) border:is_highlighted?#yellow:((is_sent)?#orange:#red) ;

			if(ACTION_MODIFY_LAND_COVER_Ui = command)
			{
				draw file("../images/icones/crowd.png") size:self.shape.width;
			}

		
			if [ACTION_MODIFY_LAND_COVER_AUs,ACTION_MODIFY_LAND_COVER_Us] contains command {draw file("../images/icones/wave.png") size:self.shape.width;}

		}
		
	}
	aspect basket
	{
		do draw_action;
	}
	
	aspect history
	{
		do draw_history;
	}
	
	
}

species buttons
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
	string nom_raccourci <-"";
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
			match "N" {res <- # palegreen;} // naturel
			match_one ["U","Us"] { //  urbanisé
				switch classe_densite {
					match "vide" {res <- # red; } // Problème
					match "peu dense" {res <-  rgb( 150, 150, 150 ); }
					match "densité intermédiaire" {res <- rgb( 120, 120, 120 ) ;}
					match "dense" {res <- rgb( 80,80,80 ) ;}
				}
			} 
			match_one ["AU","AUs"] {res <- # yellow;} // à urbaniser
			match "A" {res <- rgb (225, 165,0);} // agricole
		}
		return res;
	}
	
	aspect base
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
		
//		if isAdapte {draw "A" color:#black;}
//		if isEnDensification {draw "D" color:#black;}
	}

}

species def_cote
{
	int dike_id;
	string type;
	string commune;
	rgb color <- # pink;
	float height;
	bool ganivelle <- false;
	float elevation <- 0.0;
	string status;	//  "bon" "moyen" "mauvais" 
	
	action init_from_map(map<string, unknown> a )
	{
		self.dike_id <- int(a at "id_ouvrage");
		self.type <- string(a at "type");
		self.status <- string(a at "status");
		self.height <- float(a at "height");
		self.elevation <- float(a at "alt");
		self.ganivelle <- bool(a at "ganivelle");
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
		location <-mpp;
		
		write "shape " + mpp+ " "+shape;

	}
	
	
	action init_dike {
		if status = "" {status <- "bon";} 
		if type ='' {type <- "inconnu";}
		if status = '' {status <- "bon";} 
		if status = "tres bon" {status <- "bon";} 
		if status = "tres mauvais" {status <- "mauvais";} 
		if height = 0.0 {height  <- 1.5;}////////  Les ouvrages de défense qui n'ont pas de hauteur sont mis d'office à 1.5 mètre
		}
	
	string type_ouvrage
	{
		if type = "Naturel" {return "la dune";}
		else {return  "la digue";}		
	}
	
	aspect base
	{  	if type != 'Naturel'
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
	/*AVANT CHGT CODE COULEUR 
	 * aspect base
	{  	if type != 'Naturel'
			{switch status {
				match  "bon" {color <- # green;}
				match "moyen" {color <-  rgb (255,102,0);} 
				match "mauvais" {color <- # red;} 
				default { write "BUG: probleee status dike";}
				}
			draw 20#m around shape color: color size:300#m;
			draw shape color: #black;
				}
		else {switch status {
				match  "bon" {color <- rgb (222, 134, 14,255);}
				match "moyen" {color <-  rgb (231, 189, 24,255);} 
				match "mauvais" {color <- rgb (241, 230, 14,255);} 
				default { write "BUG: probleme status dune";}
				}
			draw 50#m around shape color: color;
			if ganivelle {loop i over: points_on(shape, 40#m) {draw circle(10,i) color: #black;}} 
		}		
	}*/	
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

experiment game type: gui
{
	font regular <- font("Helvetica", 14, # bold);
	geometry zone <- circle(1000#m);
	float minimum_cycle_duration <- 0.5;
	parameter "choix de la commune : " var:commune_name <- "dolus" among:["lechateau","dolus","sttrojan", "stpierre"];
	output
		{
		display "Aménagement, PLU et habitat" focus:my_commune //camera_pos:my_commune
		{
			image 'background' file:"../images/fond/fnt.png"; 
			species commune aspect: base;
			species UA aspect: base;
			species action_UA aspect:base;
			species road aspect:base;
			species protected_area aspect:base;
			species flood_risk_area aspect:base;
			species buttons aspect:UnAm;
			species buttons_map aspect:base;
			//species sites_non_classes_area aspect:base;
			
			graphics "Full target" transparency:0.5
			{
				//int size <- length(moved_agents);
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
			
			graphics "Action Full target" transparency:0.3
			{
				//int size <- length(moved_agents);
				if(explored_action_UA !=nil and explored_action_UA.is_applied=false)
				{
					
					UA mcell <- UA first_with(each.id = explored_action_UA.chosen_element_id);
					point target <- {mcell.location.x  ,mcell.location.y };
					point target2 <- {mcell.location.x + 1*(INFORMATION_BOX_SIZE.x#px),mcell.location.y + 1*(INFORMATION_BOX_SIZE.y#px)};
					draw rectangle(target,target2)   empty: false border: false color: #black ; //transparency:0.5;
					draw "Changement d'occupation" at: target + { 0#px, 15#px } font: regular color: # white;
					
					draw file("../images/icones/fleche.png") at: {mcell.location.x + 0.5*(INFORMATION_BOX_SIZE.x#px), target.y + 50#px}  size:50#px;
					draw ""+ (explored_action_UA.application_round)   at: {mcell.location.x + 0.5*(INFORMATION_BOX_SIZE.x#px), target.y + 50#px} size:20#px; 
					draw world.chooseActionIcone(explored_action_UA.command) at:  { target2.x - 50#px, target.y +50#px} size:50#px;
					draw world.au_icone(mcell) at:  { target.x +50#px,target.y + 50#px} size:50#px;
				}
			}
			
			
			graphics "Button information" transparency:0.5
			{
				if (explored_buttons != nil)
				{
					point target <- {explored_buttons.location.x  ,explored_buttons.location.y };
					point target2 <- {explored_buttons.location.x - 2*(INFORMATION_BOX_SIZE.x#px),explored_buttons.location.y};
					point target3 <- {explored_buttons.location.x ,  explored_buttons.location.y + 2*(INFORMATION_BOX_SIZE.y#px)};
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
			event mouse_down action: button_click_UnAM;
			event mouse_move action: mouse_move_UnAM;
		}
		
		display "Défense des côtes" focus:my_commune //camera_pos:my_commune
		{
			image 'background' file:"../images/fond/fnt.png"; 
			species commune aspect:base;
			graphics population {
			draw population_area color:rgb( 120, 120, 120 ) ;				
			}
			//species cell_mnt aspect:elevation_eau;
			species def_cote aspect:base;
			species action_def_cote aspect:base;
			species road aspect:base;
			species protected_area aspect:base;
			species flood_risk_area aspect:base;
			species buttons aspect:dike;
			species buttons_map aspect:base;
			
			graphics "Full target" transparency:0.3
			{
				if (explored_dike != nil)
				{
					point target <- {explored_dike.location.x  ,explored_dike.location.y };
					point target2 <- {explored_dike.location.x + 1*(INFORMATION_BOX_SIZE.x#px),explored_dike.location.y + 1*(INFORMATION_BOX_SIZE.y#px)};
					
					draw rectangle(target,target2)   empty: false border: false color: #black ; //transparency:0.5;
					draw "Information sur "+explored_dike.type_ouvrage() at: target + { 5#px, 15#px } font: regular color: #white;
					int xpx <-0;
					if explored_dike.type_ouvrage() = "la digue" {
						draw "Hauteur"+string(round(100*explored_dike.height)/100.0)+"m" at: target + { 30#px, 35#px } font: regular color: # white;
						xpx <- xpx+20;
					}
					draw "Altitude "+string(round(100*explored_dike.elevation)/100.0)+"m" at: target + { 30#px, xpx#px +35#px } font: regular color: # white;
					draw "Etat "+string(explored_dike.status) at: target + { 30#px, xpx#px +55#px} font: regular color: # white;
				}
				
				
			}
			
			graphics "explore_dike_icone" 
			{
				if (explored_dike != nil)
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
				if (explored_buttons != nil)
				{
					point target <- {explored_buttons.location.x  , explored_buttons.location.y };
					point target2 <- {explored_buttons.location.x - 2*(INFORMATION_BOX_SIZE.x#px),explored_buttons.location.y};
					point target3 <- {explored_buttons.location.x ,  explored_buttons.location.y + 2*(INFORMATION_BOX_SIZE.y#px)};
					point target4 <- {target3.x,target2.y - 15#px };
					draw rectangle(target2,target3)   empty: false border: false color: #black ; //transparency:0.5;
				//	draw rectangle(target2,target4)   empty: false border: false color: #red ; //transparency:0.5;
					draw explored_buttons.name() at: target2 + { 5#px, 15#px } font: regular color: #white;
					draw explored_buttons.help() at: target2 + { 30#px, 35#px } font: regular color: # white;
					if explored_buttons.command != ACTION_INSPECT_DIKE {draw "Coût de l'action : "+explored_buttons.action_cost +"/mètre" at: target2 + { 30#px, 55#px} font: regular color: # white;}
				}
			}
			
			
			event [mouse_down] action: button_click_dike;
			event mouse_move action: mouse_move_dike;			
		}
		
		display Panier
		{
			species action_def_cote aspect:basket;
			species action_UA aspect:basket;
			species del_basket_button aspect:base;
			species basket_validation aspect:base;
			graphics budget position:{0 , font_size+ font_interleave/2 + (length(my_basket) +4)* (font_size + font_interleave) }
			{
				draw "Budget : "+ world.separateur_milliers(budget) color:#black size:font_size  ;
				draw "Budget restant : " +  world.separateur_milliers(budget - round(sum(my_basket collect(each.cost)))) color:#black  size:font_size at:{0 , font_size+ font_interleave/2 } ;// + (length(my_basket) +5)* (font_size + font_interleave)	
			}
			event [mouse_down] action: basket_click;
		}
 
 		display Dossiers
		{
			species action_def_cote aspect:history;
			species action_UA aspect:history;
			species highlight_action_button aspect:base;
			event [mouse_down] action: history_click;

		}
 	}
}

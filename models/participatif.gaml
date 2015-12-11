//
/**
 *  lechateau
 *  Author: nicolas
 *  Description: 
 */
model lechateau


global
{
	string commune_name <- "lechateau";
	string MANAGER_NAME <- "model_manager";
	string log_file_name <- "log_"+machine_time+"csv";
	
	//file emprise <- file("../includes/participatif/emprise/"+commune_name+".shp");
	file emprise <- file("../includes/zone_etude/emprise_ZE_littoSIM.shp"); 
		
	//file emprise_local <- file("../includes/participatif/emprise/"+commune_name+".shp"); 
	
	
	file communes_shape <- file("../includes/zone_etude/communes.shp");
	file communes_UnAm_shape <- file("../includes/zone_etude/zones241115.shp");	
	file defense_shape <- file("../includes/zone_etude/defense_cote_littoSIM-05122015.shp");
	file road_shape <- file("../includes/zone_etude/routesdepzone.shp");
	//file mnt_shape <- file("../includes/zone_etude/all_cell_20m.shp");  CE fichier n'existe pas
	matrix<string> all_action_cost <- matrix<string>(csv_file("../includes/cout_action.csv",";"));

	//récupération des couts du fichier cout_action
	int ACTION_COST_LAND_COVER_TO_A <- int(all_action_cost at {2,1});
	int ACTION_COST_LAND_COVER_TO_AU <- int(all_action_cost at {2,2});
	int ACTION_COST_LAND_COVER_FROM_AU_TO_N <- int(all_action_cost at {2,3});
	int ACTION_COST_LAND_COVER_FROM_A_TO_N <- int(all_action_cost at {2,8});
	int ACTION_COST_DYKE_CREATE <- int(all_action_cost at {2,4});
	int ACTION_COST_DYKE_REPAIR <- int(all_action_cost at {2,5});
	int ACTION_COST_DYKE_DESTROY <- int(all_action_cost at {2,6});
	int ACTION_COST_DYKE_RAISE <- int(all_action_cost at {2,7});	
	
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
	string DYKE_DISPLAY <- "sloap";
	
	
	string active_display <- nil;
	action_done current_action <- nil;
	point previous_clicked_point <- nil;
	int action_id <- 0;
	
	float button_size <- 500#m;
	
	int ACTION_REPAIR_DYKE <- 5;
	int ACTION_CREATE_DYKE <- 6;
	int ACTION_DESTROY_DYKE <- 7;
	int ACTION_RAISE_DYKE <- 8;
	
	int ACTION_MODIFY_LAND_COVER_AU <- 1;
	int ACTION_MODIFY_LAND_COVER_A <- 2;
	int ACTION_MODIFY_LAND_COVER_U <- 3;
	int ACTION_MODIFY_LAND_COVER_N <- 4;
	
	int ACTION_LAND_COVER_UPDATE<-9;
	int ACTION_DYKE_UPDATE<-10;

	//action to acknwoledge client requests.
	int ACTION_DYKE_CREATED <- 16;
	int ACTION_DYKE_DROPPED <- 17;
	int ACTION_DYKE_LIST <- 21;
	int UPDATE_BUDGET <- 19;
	int REFRESH_ALL <- 20;
	int ACTION_MESSAGE <- 22;
	int CONNECTION_MESSAGE <- 23;
	int INFORM_TAX_GAIN <-24;
	int ACTION_INSPECT_DYKE <- 25;
	int ACTION_INSPECT_LAND_USE <-26;
	
	float widX;
	float widY;
	float minimal_budget <- -5000;
	
	
	float budget <- 20000.0;
	float impot <- impot;
	list<action_done> my_basket<-[];
	commune my_commune <- nil;
	Network_agent game_manager <-nil;
	
	init
	{
		create Network_agent number:1 returns:net;
		game_manager <- first(net);
		create commune from: communes_shape with:[nom_raccourci::string(read("NOM_RAC"))];
		my_commune <- commune first_with(each.nom_raccourci = commune_name);
		local_shape <-envelope(my_commune);
		//write "commune "+ my_commune;
		/*ask(commune where(each != my_commune))
		{
			do die;
		}*/
		do init_basket;
		do init_buttons;
		
		create dyke from:defense_shape with:[dyke_id::int(read("OBJECTID")),type::string(read("Type_de_de")),status::string(read("Etat_ouvr")), alt::float(read("alt")), height::float(get("hauteur")) ];
		create road from:road_shape; 
		ask dyke where(!(each overlaps my_commune))
		{
			do die;
		}
		ask dyke {do init_dyke;}
		create cell_UnAm from: communes_UnAm_shape with: [id::int(read("FID_1")),land_cover_code::int(read("grid_code")), cout_expro:: int(get("coutexpr"))]
		{
			switch (land_cover_code)
			{
				match 1 {land_cover <- "N";}
				match 2 {land_cover <- "U";}
				match 4 {land_cover <- "AU";}
				match 5 {land_cover <- "A";}
			}
			my_color <- cell_color();
		}
		ask cell_UnAm where(!(each overlaps my_commune))
		{
			do die;
		}
		
	}
	
	user_command "Refresh all the map"
	{
		string msg <- ""+REFRESH_ALL+COMMAND_SEPARATOR+world.get_action_id()+COMMAND_SEPARATOR+commune_name;
		ask game_manager 
		{
			do sendMessage dest:"all" content:msg;
		}
	}
	
	int get_action_id
	{
		action_id <- action_id + 1;
		return action_id;
	}
	
	action init_buttons
	{
		float interleave <- world.local_shape.height / 20;
		float button_s <- world.local_shape.height / 10;
		create buttons number: 1
		{
			command <- ACTION_MODIFY_LAND_COVER_A;
			label <- "Transformer en zone agricole";
			action_cost <- ACTION_COST_LAND_COVER_TO_A;
			shape <- square(button_size);
			display_name <- UNAM_DISPLAY;
			location <- { world.local_shape.location.x+ (world.local_shape.width /2) + world.local_shape.width/10, world.local_shape.location.y - (world.local_shape.height /2) +interleave}; // + world.local_shape.width - 500#m,world.local_shape.location.y + 350#m };
			my_icon <- image_file("../images/icones/agriculture.png");
		}

		create buttons number: 1
		{
			command <- ACTION_MODIFY_LAND_COVER_AU;
			label <- "Transformer en zone à urbaniser";
			action_cost <- ACTION_COST_LAND_COVER_TO_AU;
			shape <- square(button_size);
			display_name <- UNAM_DISPLAY;
			location <- { world.local_shape.location.x+ (world.local_shape.width /2) + world.local_shape.width/10, world.local_shape.location.y - (world.local_shape.height /2) +interleave + interleave+ button_size }; //{  world.local_shape.location.x + world.local_shape.width - 500#m,world.local_shape.location.y + 350#m + 600#m };
			my_icon <- image_file("../images/icones/urban.png");
		}

		create buttons number: 1
		{
			command <- ACTION_MODIFY_LAND_COVER_N;
			label <- "Transformer en zone naturelle";
			action_cost <- ACTION_COST_LAND_COVER_FROM_AU_TO_N;
			shape <- square(button_size);
			display_name <- UNAM_DISPLAY;
			location <- { world.local_shape.location.x+ (world.local_shape.width /2) + world.local_shape.width/10, world.local_shape.location.y - (world.local_shape.height /2) +interleave +2* (interleave+ button_size) };
			my_icon <- image_file("../images/icones/tree_nature.png");
			
		}
		create buttons number: 1
		{
			command <- ACTION_INSPECT_LAND_USE;
			label <- "Transformer en zone naturelle";
			action_cost <- 0;
			shape <- square(button_size);
			display_name <- UNAM_DISPLAY;
			location <- { world.local_shape.location.x+ (world.local_shape.width /2) + world.local_shape.width/10, world.local_shape.location.y - (world.local_shape.height /2) +interleave +3* (interleave+ button_size) };
			my_icon <- image_file("../images/icones/Loupe.png");
			
		}
		
		create buttons number: 1
		{
			command <- ACTION_CREATE_DYKE;
			label <- "Construire une digue";
			action_cost <- ACTION_COST_DYKE_CREATE;
			shape <- square(button_size);
			display_name <- DYKE_DISPLAY;
			location <- { world.local_shape.location.x+ (world.local_shape.width /2) + world.local_shape.width/10, world.local_shape.location.y - (world.local_shape.height /2) +interleave  }; // + world.local_shape.width - 500#m,world.local_shape.location.y + 350#m };
			my_icon <- image_file("../images/icones/digue_validation.png");
		}

		create buttons number: 1
		{
			command <- ACTION_REPAIR_DYKE;
			label <- "Réparer une digue";
			action_cost <- ACTION_COST_DYKE_REPAIR;
			shape <- square(button_size);
			display_name <- DYKE_DISPLAY;
			location <- { world.local_shape.location.x+ (world.local_shape.width /2) + world.local_shape.width/10, world.local_shape.location.y - (world.local_shape.height /2) +interleave + 2*(interleave+ button_size) }; //{  world.local_shape.location.x + world.local_shape.width - 500#m,world.local_shape.location.y + 350#m + 600#m };
			my_icon <- image_file("../images/icones/digue_entretien.png");
			
		}

		create buttons number: 1
		{
			command <- ACTION_DESTROY_DYKE;
			label <- "Démenteler une digue";
			action_cost <- ACTION_COST_DYKE_DESTROY;
			shape <- square(button_size);
			display_name <- DYKE_DISPLAY;
			location <- { world.local_shape.location.x+ (world.local_shape.width /2) + world.local_shape.width/10, world.local_shape.location.y - (world.local_shape.height /2) +interleave +3* (interleave+ button_size) };
			my_icon <- image_file("../images/icones/digue_suppression.png");
			
		}
		
		create buttons number: 1
		{
			command <- ACTION_RAISE_DYKE;
			label <- "Réhausser une digue";
			action_cost <- ACTION_COST_DYKE_RAISE;
			shape <- square(button_size);
			display_name <- DYKE_DISPLAY;
			location <- { world.local_shape.location.x+ (world.local_shape.width /2) + world.local_shape.width/10, world.local_shape.location.y - (world.local_shape.height /2) +interleave +1* (interleave+ button_size) };
			my_icon <- image_file("../images/icones/digue_rehausse_plus.png");
			
		}
		
		create buttons number: 1
		{
			command <- ACTION_INSPECT_DYKE;
			label <- "Transformer en zone naturelle";
			action_cost <- 0;
			shape <- square(button_size);
			display_name <- DYKE_DISPLAY;
			location <- { world.local_shape.location.x+ (world.local_shape.width /2) + world.local_shape.width/10, world.local_shape.location.y - (world.local_shape.height /2) +interleave +4* (interleave+ button_size) };
			my_icon <- image_file("../images/icones/Loupe.png");
			
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

	bool basket_overflow
	{
		if(basket_max_size = length(my_basket))
		{
			map<string,unknown> values2 <- user_input("Avertissement","Vous avez atteint la capacité maximum de votre panier, veuiller supprimer des action avant de continuer");
			return true;
		}
		return false;
	}
	
	action basket_click(point loc, list selected_agents)
	{
		list<del_basket_button> bsk_del <- selected_agents of_species del_basket_button;
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
		list<basket_validation> bsk_validation <- selected_agents of_species basket_validation;
		if(length(bsk_validation)>0)
		{
			if(   minimal_budget >(budget - round(sum(my_basket collect(each.cost)))))
			{
				string budget_display <- "Vous ne disposez pas du budget suffisant pour réaliser toutes ces actions";
				map<string,unknown> res <- user_input("Avertissement",[budget_display:: false]);
				return;
			
			}
			
			
			bool choice <- false;
			string ask_display <- "Vous êtes sur le point de valider votre panier \n Cocher la case, pour accepter le panier et valider";
			map<string,unknown> res <- user_input("Avertissement",[ask_display:: choice]);
			if(res at ask_display )
			{
				ask first(bsk_validation)
				{
					do send_basket;
				}
			}
		}
	}
	
	action change_dyke (point loc, list selected_agents)
	{
		if(basket_overflow())
		{
			return;
		}
		buttons selected_button <- buttons first_with(each.is_selected);
		if(selected_button != nil)
		{
			switch(selected_button.command)
			{
				match ACTION_CREATE_DYKE { do create_new_dyke(loc,selected_button);}
				match ACTION_INSPECT_DYKE { do inspect_dyke(loc,selected_agents,selected_button); do clear_selected_button;
			}
				default {do modify_dyke(loc, selected_agents,selected_button); do clear_selected_button;
			}
			}
		}
	}
	
	action inspect_UNAM(point mloc, list agts, buttons but)
	{
		list<dyke> selected_dyke <- agts of_species dyke;
		
		if(length(selected_dyke)>0)
		{
			dyke dk<- selected_dyke closest_to mloc;
			create action_dyke number:1 returns:action_list
			 {
				id <- 0;
				shape <- dk.shape;
				chosen_element_id <- dk.dyke_id;
			 }
			 action_dyke tmp <- first(action_list);
			 string chain <- "Caractéristiques de la digue \n Type :"+ dk.type+" \n Etat général : "+dk.status+"\n Hauteur : "+ dk.height+"m";
			 map<string,unknown> values2 <- user_input("Inspecteur de digue",[chain::""]);		
			ask(tmp)
			{
				do die;
			}
		}
	}
	
	action inspect_dyke(point mloc, list agts, buttons but)
	{
		list<dyke> selected_dyke <- agts of_species dyke;
		
		if(length(selected_dyke)>0)
		{
			dyke dk<- selected_dyke closest_to mloc;
			create action_dyke number:1 returns:action_list
			 {
				id <- 0;
				shape <- dk.shape;
				chosen_element_id <- dk.dyke_id;
			 }
			 action_dyke tmp <- first(action_list);
			 string chain <- "Caractéristiques de la digue \n Type :"+ dk.type+" \n Etat général : "+dk.status+"\n Hauteur : "+ dk.height+"m";
			 map<string,unknown> values2 <- user_input("Inspecteur de digue",[chain::""]);		
			ask(tmp)
			{
				do die;
			}
		}
	}
	action modify_dyke(point mloc, list agts, buttons but)
	{
		list<dyke> selected_dyke <- agts of_species dyke;
		
		if(length(selected_dyke)>0)
		{
			dyke dk<- selected_dyke closest_to mloc;
			create action_dyke number:1 returns:action_list
			 {
				id <- world.get_action_id();
				self.command <- but.command;
				cost <- but.action_cost*dk.shape.perimeter; 
				self.label <- but.label;
				shape <- dk.shape;
				chosen_element_id <- dk.dyke_id;
			 }
			previous_clicked_point <- nil;
			current_action<- first(action_list);
			my_basket <- my_basket + current_action; 
		}
	}
	
	action create_new_dyke(point loc,buttons but)
	{
		if(previous_clicked_point = nil)
		{
			previous_clicked_point <- loc;
		}
		else
		{
				create action_dyke number:1 returns:action_list
				{
					id <- world.get_action_id();
					self.label <- but.label;
					chosen_element_id <- -1;
					self.command <- ACTION_CREATE_DYKE;
					shape <- polyline([previous_clicked_point,loc]);
					cost <- but.action_cost*shape.perimeter; 
				}
				previous_clicked_point <- nil;
				current_action<- first(action_list);
				my_basket <- my_basket + current_action; 
				do clear_selected_button;
			
		}
		
	}


	action change_plu (point loc, list selected_agents)
	{
		if(basket_overflow())
		{
			return;
		}
		buttons selected_button <- buttons first_with(each.is_selected);
		if(selected_button != nil)
		{
			list<cell_UnAm> selected_UnAm <- selected_agents of_species cell_UnAm;
			cell_UnAm cell_tmp <- selected_UnAm closest_to loc;
			ask (cell_tmp)
			{
				if(selected_button.command = ACTION_INSPECT_LAND_USE)
				{
					bool res <- false;
					
					list<cell_mnt> cls <- cell_mnt overlapping self;
					
				//	float rg <- mean(cls collect(each.rugosity));
				//	float hg <- mean(cls collect(each.soil_height));
					
					string chain <- "Caractéristiques de l'unité d'aménagement \n Occupation : "+ land_cover+ "\n cout d'expropriation : "+cout_expro; // + " \n "+"Elévation : "+ hg+"\n rugosité : " + rg;
					map<string,unknown> values2 <- user_input("Inspecteur",[chain::""]);		
					return;	
					
				}
				if((cell_tmp.land_cover_code=1 and selected_button.command = ACTION_MODIFY_LAND_COVER_N) 
					or (cell_tmp.land_cover_code=4 and selected_button.command = ACTION_MODIFY_LAND_COVER_AU)
					or (cell_tmp.land_cover_code=5 and selected_button.command = ACTION_MODIFY_LAND_COVER_A)
					or (length((action_done collect(each.location)) inside cell_tmp)>0  ))
				{
					//string chain <- "action incohérente";
					//map<string,unknown> values2 <- user_input("Avertissement",[chain::""]);		
					return;
				}
				if(((cell_tmp.land_cover_code=2 or cell_tmp.land_cover_code=4) and selected_button.command = ACTION_MODIFY_LAND_COVER_A))
				{
					bool res<-false;
					string chain <- "Transformer une zone urbaine en zone agricole est interdit par la législation";
					map<string,unknown> values2 <- user_input("Avertissement",[chain::""]);		
					
					return;
				}
				
				if(selected_button.command = ACTION_MODIFY_LAND_COVER_N  and (land_cover_code= 2)  )
				{
					bool res <- false;
					string chain <- "Vous êtes sur le point d'exproprier des habitants. Souhaitez vous continuer ?";
					map<string,unknown> values2 <- user_input("Avertissement",[chain:: res]);		
					if(values2 at chain = false)
					{
						return;
					}
					
				}
				if(selected_button.command = ACTION_MODIFY_LAND_COVER_AU  and (land_cover_code= 1)  )
				{
					bool res <- false;
					string chain <- "Cette action fait l'objet d'une demande en préfecture. L'avez vous fait ? \n Souhaitez vous continuer la transformation de cette parcelle ?";
					map<string,unknown> values2 <- user_input("Avertissement",[chain:: res]);		
					ask game_manager
					{
						do send_information(chain+"\n response: "+(values2 at chain ));
					}
					if(values2 at chain = false)
					{
						return;
					}
					
				}
				
				
				create action_land_cover number:1 returns:action_list
				{
					id <- world.get_action_id();
					chosen_element_id <- myself.id;
					self.command <- selected_button.command;
					if(selected_button.command = ACTION_MODIFY_LAND_COVER_N  and (myself.land_cover_code= 5)) 
						{cost <- ACTION_COST_LAND_COVER_FROM_A_TO_N;} 
					if(selected_button.command = ACTION_MODIFY_LAND_COVER_N  and (myself.land_cover_code= 2)) 
						{cost <- myself.cout_expro;} 						
					else {cost <- selected_button.action_cost;}
					self.label <- selected_button.label;
					shape <- myself.shape;
				}
				current_action<- first(action_list);
				my_basket <- my_basket + current_action; 
			}
		}
	}
	

	action button_click_UnAM (point loc, list selected_agents)
	{
		if(active_display != UNAM_DISPLAY)
		{
			current_action <- nil;
			active_display <- UNAM_DISPLAY;
			do clear_selected_button;
			//return;
		}
		list<buttons> selected_UnAm <- (selected_agents of_species buttons) where(each.display_name=active_display );
		
		if(length(selected_UnAm)>0)
		{
			do clear_selected_button;
			ask (first(selected_UnAm))
			{
				is_selected <- true;
			}
			return;
		}
		else
		{
			do change_plu(loc,selected_agents);
			do  clear_selected_button;
		}
		
	
	}
	
	action button_click_Dyke (point loc, list selected_agents)
	{
		if(active_display != DYKE_DISPLAY)
		{
			current_action <- nil;
			active_display <- DYKE_DISPLAY;
			do clear_selected_button;
			//return;
		}
		
		list<buttons> selected_Dyke <- (selected_agents of_species buttons) where(each.display_name=active_display );
	
		if( length(selected_Dyke) > 0)
		{
			do clear_selected_button;
			ask (first(selected_Dyke))
			{
				is_selected <- true;
			}
			
		}
		else
		{
			do change_dyke ( loc,  selected_agents);
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
			draw image:"../images/icones/suppression.png" size:font_size;
		}
		
	}
}

species action_done
{
	int id;
	int chosen_element_id;
	//string command_group <- "";
	int command <- -1;
	string label <- "no name";
	float cost <- 0.0;
	action apply;
	
	string serialize_command
	{
		string result <-"";
		//write "pout poute "+ chosen_element_id;
		
		switch(command)
		{
			match ACTION_CREATE_DYKE  {
				point end <- last(shape.points);
				point origin <- first(shape.points);
				result <- ""+command+COMMAND_SEPARATOR+id+COMMAND_SEPARATOR+( origin.x)+COMMAND_SEPARATOR+(origin.y) +COMMAND_SEPARATOR+(end.x)+COMMAND_SEPARATOR+(end.y)+COMMAND_SEPARATOR+location.x+COMMAND_SEPARATOR+location.y;
			}
			
			default {
				result <- ""+command+COMMAND_SEPARATOR+id+COMMAND_SEPARATOR+chosen_element_id;
			}
		}
		
		return result;	
	}
	
	action draw_action
	{
		int indx <- my_basket index_of self;
		float y_loc <- basket_location[indx];
		float x_loc <- font_interleave + 12* (font_size+font_interleave);
		
		draw label at:{font_size+2*font_interleave,y_loc+font_size/2} size:font_size#m color:#black;
		draw "    "+ round(cost) at:{x_loc,y_loc+font_size/2} size:font_size#m color:#black;
		if((indx +1) = length(my_basket))
		{
			string text<- "---------------";
			draw text at: {x_loc,font_size+ font_interleave/2 + (indx +1)* (font_size + font_interleave)} size:font_size color:#black;
			draw "    "+round(sum(my_basket collect(each.cost))) at: {x_loc,font_size+ font_interleave/2 + (indx +2)* (font_size + font_interleave)} size:font_size color:#black;
		}

	}
}

species Network_agent skills:[network]
{
	init{
		
		do connectMessenger to:GROUP_NAME at:"localhost" withName:world.commune_name;	
		string mm<- ""+CONNECTION_MESSAGE+COMMAND_SEPARATOR+world.commune_name;
		do sendMessage dest:"all" content:mm;
	}
	
	reflex receive_message 
	{
		loop while:!emptyMessageBox()
		{
			map<string,string> msg <- fetchMessage();
			string dest <- msg["dest"]; 
			write "message " + msg;
			if(dest="all" or dest contains world.commune_name)
			{
				//do read_action(msg["content"],msg["sender"]);	
				string my_msg <- msg["content"]; 
				list<string> data <- my_msg split_with COMMAND_SEPARATOR;
				//write "coucou  msg "+msg["content"];
				int command <- int(data[0]);
				int action_id <- int(data[1]);
				switch(int(data[0]))
					{
						match INFORM_TAX_GAIN
						{
							map<string,unknown> values2 <- user_input("Avertissement","Vous avez reçu une subvention de "+ data[2]+ " B \n issues de l'imposition"::"");
			
						}	//string msg <- ""+INFORM_TAX_GAIN+COMMAND_SEPARATOR+impotRecus;
						
						match UPDATE_BUDGET
						{
							budget <- float(data[2]);
							impot <- float(data[3]);
							
						}
						match ACTION_DYKE_LIST
						{
							list<string> all_dyke <-   copy_between(data,3,length(data)-1); 
							do check_dyke(data );
						}
						match ACTION_DYKE_CREATED
						{
							do dyke_create_action(data);
						}
						match ACTION_DYKE_UPDATE {
							int d_id <- int(data[2]);
							if(length(dyke where(each.dyke_id =d_id ))=0)
							{
								do dyke_create_action(data);
							}
							ask dyke where(each.dyke_id =d_id )
							{
								status <-data[9];
								type <- int(data[8]);
								height <-float(data[7]);
							}
						}
						match ACTION_DYKE_DROPPED {
							int d_id <- int(data[2]);
							ask dyke where(each.dyke_id =d_id )
							{
								do die;
							}
						}
						
						match ACTION_LAND_COVER_UPDATE {
							int d_id <- int(data[2]);
							ask cell_UnAm where(each.id = d_id)
							{
								land_cover_code <-int(data[3]); 
								switch (land_cover_code)
								{
										match 1 {land_cover <- "N";}
										match 2 {land_cover <- "U";}
										match 4 {land_cover <- "AU";}
										match 5 {land_cover <- "A";}
								}
								//land_cover <- "AU";
		
							}
						}
					}
			}
		}
	}
	
	action check_dyke(list<string> mdata)
	{
		list<int> idata<- mdata collect (int(each));
		ask(dyke)
		{
			//write "compare : "+dyke_id+" ---> "+ mdata;
			if( !( idata contains dyke_id) )
			{
				do die;
			}
		}
	}
	
	action dyke_create_action(list<string> msg)
	{
		int d_id <- int(msg[2]);
		float x1 <- float(msg[3]);
		float y1 <- float(msg[4]);
		float x2 <- float(msg[5]);
		float y2 <- float(msg[6]);
		float hg <- float(msg[7]);
		string tp <- string(msg[8]);
		string st <- msg[9];
		geometry pli <- polyline([{x1,y1},{x2,y2}]);
		create dyke number:1
		{
			shape <- pli;
			dyke_id <- d_id;
			type<-tp;
			height<- hg;
			status<-st;
		}				
	}
	action send_information(string msg)
	{
		string val <-""+ ACTION_MESSAGE + COMMAND_SEPARATOR+world.get_action_id()+ COMMAND_SEPARATOR+msg;
		do sendMessage  dest:"all" content:""+val;
	}
	action send_basket
	{
		action_done act <-nil;
		loop act over:my_basket
		{
			string val <- act.serialize_command();
		//	write "message " + val;
			do sendMessage  dest:"all" content:""+val;	/*MANAGER_NAME*/
		}
		ask my_basket
		{
			do die;
		}
		my_basket<-[];
		
	}
	
}


species basket_validation skills:[network]
{
	point location <- {0,0} update:{font_interleave + 12* (font_size + font_interleave),font_size+ font_interleave/2 + (length(my_basket) +2)* (font_size + font_interleave)};
	init{
		shape <- square(button_size);
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
		if(length(my_basket) = 0)
		{
			draw "Aucune action enregistrée" size:font_size color:#black at:{0 , y_loc };
		}
		else
		{
			draw image:"../images/icones/validation.png" size:world.shape.width/8;
		}
		
		//draw "Budget : "+ budget color:#black size:font_size at:{0 , font_size+ font_interleave/2 + (length(my_basket) +4)* (font_size + font_interleave) } ;
		//draw "Budget restant : " + (budget - round(sum(my_basket collect(each.cost)))) color:#black  size:font_size at:{0 , font_size+ font_interleave/2 + (length(my_basket) +5)* (font_size + font_interleave) } ;
		
	}
	
}

species action_dyke parent:action_done
{
	rgb define_color
	{
		switch(command)
		{
			 match ACTION_CREATE_DYKE { return #blue;}
			 match ACTION_REPAIR_DYKE {return #green;}
			 match ACTION_DESTROY_DYKE {return #brown;}
			 match ACTION_RAISE_DYKE {return #yellow;}
		} 
		return #grey;
	}
	
	
	
	aspect base
	{
		draw  20#m around shape color:define_color() border:#red;
	}
	
	aspect basket
	{
		do draw_action;
	}
	
	action apply
	{
		//creer une digue
	}
}


species action_land_cover parent:action_done
{
	int choosen_cell;
	rgb define_color
	{
		switch(command)
		{
			 match ACTION_MODIFY_LAND_COVER_A { return #brown;}
			 match ACTION_MODIFY_LAND_COVER_AU {return #black;}
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
		draw shape color:define_color() border:#red;
	}
	
	aspect basket
	{
		do draw_action;
	}
	
}

species buttons
{
	int command <- -1;
	string display_name <- "no name";
	string label <- "no name";
	int action_cost<-0;
	bool is_selected <- false;
	geometry shape <- square(500#m);
	file my_icon;
	aspect UnAm
	{
		if( display_name = UNAM_DISPLAY)
		{
			draw shape color:#white border: is_selected ? # red : # white;
			draw my_icon size:button_size-50#m ;
			
		}
	}
	aspect dyke
	{
		
		if( display_name = DYKE_DISPLAY)
		{
			draw shape color:#white border: is_selected ? # red : # white;
			draw my_icon size:button_size-50#m ;
			
		}
	}
}


species commune
{
	string nom_raccourci <-"";
	aspect base
	{
		draw shape  color: self=my_commune?rgb(202,170,145):#gray;
	}

}

species road
{
	aspect base
	{
		draw shape color:#gray;
	}
	
}

species cell_UnAm
{
	string land_cover <- "";
	int id;
	int land_cover_code <- 0;
	int cout_expro ;
	rgb my_color <- cell_color() update: cell_color();

	init {cout_expro <- (round (cout_expro /2000 /50))*100;} //50= tx de conversion Euros->Boyard on divise par 2 la valeur du cout expro car elle semble surévaluée
	
	action modify_land_cover
	{
		switch (land_cover)
		{
			match "AU"
			{
				land_cover_code <- 1;
			}

			match "A"
			{
				land_cover_code <- 2;
			}

			match "U"
			{
				land_cover_code <- 3;
			}

			match "N"
			{
				land_cover_code <- 4;
			}
		}
	}

	rgb cell_color
	{
		rgb res <- nil;
		switch (land_cover_code)
		{
			match 1 {res <- # palegreen;} // naturel
			match 2 {res <- rgb (110, 100,100);} //  urbanisé
			match 4 {res <- # yellow;} // à urbaniser
			match 5 {res <- rgb (225, 165,0);} // agricole
		}
		return res;
	}

	aspect base
	{
		draw shape color: my_color;
	}

}

species dyke
{
	int dyke_id;
	string type;
	rgb color <- # pink;
	float height;
	string status;	// "tres bon" "bon" "moyen" "mauvais" "tres mauvais" 
	
	action init_dyke {
		if status = "" {status <- "bon";} 
		if type ='' {type <- "inconnu";}
		if status = '' {status <- "bon";} 
		if height = 0.0 {height  <- 1.5;}////////  Les ouvrages de défense qui n'ont pas de hauteur sont mis d'office à 1.5 mètre
	}
	
	aspect base
	{  	
		if status = "tres bon" {color <- # green;} 
		if status = "bon" {color <- rgb (239,204,51);} 
		if status = "moyen" {color <-  rgb (255,102,0);} 
		if status = "mauvais" {color <- # red;} 
		if status = "tres mauvais" {color <- # black;}
		if status = "casse" {color <- # yellow;} 
		draw 20#m around shape color: color size:300#m;
	}
	
}

species cell_mnt schedules:[]
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
	float minimum_cycle_duration <- 0.5;
	parameter "choix de la commune : " var:commune_name <- "dolus" among:["lechateau","dolus","sttrojan", "stpierre"];
	output
		{
		display UnAm focus:my_commune
		{
			species commune aspect: base;
			species cell_UnAm aspect: base;
			species action_land_cover aspect:base;
			species road aspect:base;
			
			species buttons aspect:UnAm;
			event [mouse_down] action: button_click_UnAM;
		}
		
		display "Dyke managment" focus:my_commune
		{
			image 'background' file:"../images/fond/fnt.png"; 
			species commune aspect:base;
			//species cell_mnt aspect:elevation_eau;
			species dyke aspect:base;
			species action_dyke aspect:base;
			species road aspect:base;
			species buttons aspect:dyke;
			
			event [mouse_down] action: button_click_Dyke;
		}
		display Basket
		{
			species action_dyke aspect:basket;
			species action_land_cover aspect:basket;
			species del_basket_button aspect:base;
			species basket_validation aspect:base;
			text "Budget : "+ budget color:#black size:font_size position:{0 , font_size+ font_interleave/2 + (length(my_basket) +4)* (font_size + font_interleave) } ;
			text "Budget restant : " + (budget - round(sum(my_basket collect(each.cost)))) color:#black  size:font_size position:{0 , font_size+ font_interleave/2 + (length(my_basket) +5)* (font_size + font_interleave) } ;
			
			event [mouse_down] action: basket_click;

		}

	}

}

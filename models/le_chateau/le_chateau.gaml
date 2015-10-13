/**
 *  lechateau
 *  Author: nicolas
 *  Description: 
 */
model lechateau


global
{
	file emprise <- file("../../includes/cadre.shp");
	file communes_shape <- file("../../includes/communes.shp");
	file communes_UnAm_shape <- file("../../includes/le_chateau/chatok.shp");
	string UNAM_ACTIVE_COMMAND_GROUP <- "UnAm";
	string SLOAP_ACTIVE_COMMAND_GROUP <- "sloap";
	geometry shape <- envelope(emprise);
	string active_display <- ""; //UNAM_ACTIVE_COMMAND_GROUP;
	int current_action <- -1;
	
	init
	{
		do init_buttons;
		do init_information_agents;
		create commune from: communes_shape;
		create cell_UnAm from: communes_UnAm_shape with: [land_cover::string(read("TYPEZONE"))]
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

			my_color <- cell_color();
		}

	}
	
	action init_information_agents
	{
		create information_agent number:1
		{
			display_command_group <- UNAM_ACTIVE_COMMAND_GROUP;
		}
		create information_agent number:1
		{
			display_command_group <- SLOAP_ACTIVE_COMMAND_GROUP;
			
		}
	}
	action init_buttons
	{
		float button_size <- world.shape.width / 4;
		float start_x <- world.shape.width / 6;
		
		//boutons de gestion des milieux
		
		create buttons number: 1
		{
			color <- # brown;
			command <- 2;
			label <- "Agriculture";
			shape <- square(button_size);
			display_name <- UNAM_ACTIVE_COMMAND_GROUP;
			location <- { start_x, world.shape.width / 2 - button_size / 2 };
			text_location <- { shape.location.x - shape.width / 4, shape.location.y };
		}

		create buttons number: 1
		{
			color <- # orange;
			command <- 1;
			label <- "Urbanisation";
			shape <- square(button_size);
			display_name <- UNAM_ACTIVE_COMMAND_GROUP;
			location <- { start_x + world.shape.width / 3, world.shape.width / 2 - button_size / 2 };
			text_location <- { shape.location.x - shape.width / 4, shape.location.y };
		}

		create buttons number: 1
		{
			color <- # green;
			command <- 4;
			label <- "Naturelle";
			shape <- square(button_size);
			display_name <- UNAM_ACTIVE_COMMAND_GROUP;
			location <- { start_x + 2 * world.shape.width / 3, world.shape.width / 2 - button_size / 2 };
			text_location <- { shape.location.x - shape.width / 4, shape.location.y };
		}
		
		//bouton de gestion des digues
		create buttons number: 1
		{
			color <- # brown;
			command <- 5;
			label <- "Construire";
			shape <- square(button_size);
			display_name <- SLOAP_ACTIVE_COMMAND_GROUP;
			location <- { start_x, world.shape.width / 2 - button_size / 2 };
			text_location <- { shape.location.x - shape.width / 4, shape.location.y };
		}

		create buttons number: 1
		{
			color <- # orange;
			command <- 6;
			label <- "Reparer";
			shape <- square(button_size);
			display_name <- SLOAP_ACTIVE_COMMAND_GROUP;
			location <- { start_x + world.shape.width / 3, world.shape.width / 2 - button_size / 2 };
			text_location <- { shape.location.x - shape.width / 4, shape.location.y };
		}

		create buttons number: 1
		{
			color <- # green;
			command <- 7;
			label <- "Démentler";
			shape <- square(button_size);
			display_name <- SLOAP_ACTIVE_COMMAND_GROUP;
			location <- { start_x + 2 * world.shape.width / 3, world.shape.width / 2 - button_size / 2 };
			text_location <- { shape.location.x - shape.width / 4, shape.location.y };
		}
		
	}


	action change_sloap (point loc, list selected_agents)
	{
		if(active_display != SLOAP_ACTIVE_COMMAND_GROUP)
		{
			active_display <- SLOAP_ACTIVE_COMMAND_GROUP;
			world.current_action <- -1;
		}
		do clear_information_agents;
		
		
	}

	action change_plu (point loc, list selected_agents)
	{
		if(active_display != UNAM_ACTIVE_COMMAND_GROUP)
		{
			active_display <- UNAM_ACTIVE_COMMAND_GROUP;
			world.current_action <- -1;
		}
		do clear_information_agents;
		
		if(world.current_action != -1 )
		{
			list<cell_UnAm> selected_UnAm <- selected_agents of_species cell_UnAm;
			ask (selected_UnAm closest_to loc)
			{
				land_cover_code <- world.current_action;
			}
		}
	}
	
	action clear_information_agents
	{
		ask information_agent where(each.display_command_group=active_display)
		{
			self.label <- "";
		}
	}
	action button_click (point loc, list selected_agents)
	{
		list<buttons> selected_UnAm <- (selected_agents of_species buttons) where(each.display_name=active_display );
		ask (first(selected_UnAm))
		{
			current_action <- command;
		}

	}

}

species action_done
{
	string command_group <- "";
	int command <- -1;
	string label <- "no name";
	float cost <- 0;
}

species information_agent
{
	string label <- " Click here to\nstart ";
	string display_command_group <- "";
	
	reflex display_error when:display_command_group = nil or display_command_group != active_display  
	{
		label <- " Click here to \n start";
	}
	
	aspect base_UnAM
	{
		if(length(label) != 0 and display_command_group =  UNAM_ACTIVE_COMMAND_GROUP )
		{
			draw string(label) font: "times" size: world.shape.width / 10 color: °blue at:{  shape.width / 6, world.shape.location.y};
			draw world.shape color:°gray at: world.shape.location ;
		}
	}
	aspect base_SLOAP
	{
		if(length(label) != 0  and display_command_group =  SLOAP_ACTIVE_COMMAND_GROUP)
		{
			draw string(label) font: "times" size: shape.width / 10 color: °white at:{ shape.width / 6, world.shape.location.y};
			draw world.shape color:°gray at: world.shape.location ;
		}
	}
	
}

species buttons
{
	rgb color <- °black;
	int command <- -1;
	string display_name <- "no name";
	string label <- "no name";
	bool is_selected <- false;
	geometry shape <- world.shape;
	point text_location <- { 0, world.shape.location.y };
	aspect base
	{
		if( display_name = active_display)
		{
			draw shape color: color border: is_selected ? # red : # white;
			draw string(label) font: "times" size: shape.width / 10 color: °black at: text_location;
			
		}
	}

}

species commune
{
	aspect base
	{
		draw shape color: # gray;
	}

}

species cell_UnAm
{
	string land_cover <- "";
	int land_cover_code <- 0;
	rgb my_color <- cell_color() update: cell_color();
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
			match 1
			{
				res <- # orange;
			} // à urbainiser
			match 2
			{
				res <- # brown;
			} // agricole
			match 3
			{
				res <- # red;
			} // urbanisé
			match 4
			{
				res <- # green;
			} // naturel
		}

		return res;
	}

	aspect base
	{
		draw shape color: my_color;
	}

}

experiment lechateau type: gui
{
/** Insert here the definition of the input and output of the model */
	output
	{
		display UnAm
		{
			species commune aspect: base;
			species cell_UnAm aspect: base;
			species information_agent aspect:base_UnAM transparency: 0.5;
			event [mouse_down] action: change_plu;
		}
		
		display Sloap
		{
			species commune aspect: base;
			species information_agent aspect:base_SLOAP transparency: 0.5;
			event [mouse_down] action: change_sloap;
		}
		
		
		display commands
		{
			species buttons aspect: base transparency: 0.5;
			event [mouse_down] action: button_click;
			
		}

	}

}

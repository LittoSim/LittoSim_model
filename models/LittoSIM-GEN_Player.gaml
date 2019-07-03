//
/**
 *  Commune
 *  Author: nicolas
 *  Description: 
 */
model Player

import "params_models/params_player.gaml"

global{
	string active_district_name <- "";
	string active_district_code <- dist_code_sname_correspondance_table index_of active_district_name;
	District active_district	<- nil;
	
	string log_file_name 		 <- "log_" + machine_time + "csv";
	int game_round 		 		 <- 0;
	
	geometry shape 		 <- envelope(convex_hull_shape);
	geometry local_shape <- nil;
	
	// GUI
	list<float> basket_location <- [];
	bool is_active_gui 			<- true;
	string active_display 		<- LU_DISPLAY;
	point previous_clicked_point<- nil;
	float button_size 			<- 500#m;
	float widX;
	float widY;
		
	// tax attributes
	int budget 			<- 0;
	int minimal_budget  <- -2000;
	int received_tax	<- 0;
	float tax_unit  	<- 0.0;
	
	bool subsidized_adapted_habitat <- false;
	bool subsidize_ganivelle 		<- false;
	int previous_population;
	int current_population -> {Land_Use sum_of (each.population)};
	list<Player_Action> my_basket <-[];
	
	
	Button explored_button <- nil;
	geometry population_area <- nil;
	Coastal_Defense explored_coast_def <- nil;
	Land_Use explored_lu <- nil;
	Land_Use hovered_lu <- nil;
	Land_Use_Action explored_land_use_action<- nil;
	Coastal_Defense_Action explored_coast_def_action<- nil;
	
	list<Player_Action> ordered_action 	<- nil;
	list<Player_Action> my_history	 	<- [] update: ordered_action where(each.is_sent);
	
	Basket game_basket 			<-nil;
	Message_Console game_console<-nil;
	History game_history 		<- nil; 
	Player_Action highlighted_action;
	Player_Action current_action 	<- nil;
	
	font f0 <- font('Helvetica Neue', DISPLAY_FONT_SIZE - 4, #plain);
	font f1 <- font('Helvetica Neue', DISPLAY_FONT_SIZE, #bold);
	
	int flooded_cells <- 0;
	int cell_width;
	int cell_height;
	
	init{		
		create District from: districts_shape with:[district_code::string(read("dist_code")), district_name::string(read("dist_sname"))];
		active_district <- District first_with (each.district_code = active_district_code);
		local_shape 	<- envelope(active_district);
		tax_unit  		<- float(tax_unit_table at active_district_name); 
		
		create History_Left_Icon {
			do lock_agent_at ui_location: {0.075,0.5} display_name: GAMA_HISTORY_DISPLAY ui_width: 0.15 ui_height: 1.0;
		}
		create Message_Left_Icon {
			do lock_agent_at ui_location: {0.075,0.5} display_name: GAMA_MESSAGES_DISPLAY ui_width: 0.15 ui_height: 1.0;
		}
		
		create Basket  				{game_basket  <- self;}
		create History				{game_history <- self;}
		create Message_Console 		{game_console <- self;}

		do create_tabs;
		create Network_Player;
		create Network_Listener_To_Leader;
		
		do create_buttons;	
										
		create Coastal_Defense from: coastal_defenses_shape with: [coast_def_id::int(read("ID")),type::string(read("type")),
			status::string(read("status")), alt::float(read("alt")), height::float(get("height")), district_code::string(read("dist_code"))]{
			if district_code = active_district_code {
				do init_coastal_def;
			} else {
				do die;
			}
		}
		create Protected_Area from: protected_areas_shape;
		create Road from: roads_shape;
		if water_shape != nil {
			create Water from: water_shape;
		}
		create Flood_Risk_Area from: rpp_area_shape;
		
		create Land_Use from: land_use_shape with: [id::int(read("ID")), dist_code::string(read("dist_code")), lu_code::int(read("unit_code")), population::int(get("unit_pop"))]{
			if (self.dist_code = active_district_code){
				lu_name <- lu_type_names [lu_code];
				if lu_name = "U" and population = 0 {population <- MIN_POP_AREA;}
				my_color <- cell_color();
			} else {do die;}
		}

		population_area 	<- union(Land_Use where(each.lu_name = "U" or each.lu_name = "AU"));
		previous_population <- current_population();
		MSG_WARNING 		<- get_message('MSG_WARNING');
		create Legend_Flood;
	}
	//------------------------------ End of init -------------------------------//
	
	user_command "Refresh all the map" {
		write "Refresh all";
		do refresh_all;
	}
	
	action refresh_all{
		ask Land_Use + Coastal_Defense + Player_Action {
			do die;
		}
		map<string, string> mp <- ["REQUEST"::string(REFRESH_ALL)];
		ask Network_Player {
			do send to: GAME_MANAGER contents: mp;
		}
	}
	
	point button_box_location (point my_button, int box_width){
		if(world.shape.width * 0.6 > my_button.x){
			return {min([my_button.x + box_width, world.shape.width - 10#px]), my_button.y};
		}
		return my_button;
	}
	
	int id_number_of_action_id (string act_id){
		return act_id = "" ? 0 : int ((act_id split_with "_")[1]);
	}
	
	string get_action_id {
		list<int> ids1 <- Coastal_Defense_Action collect(id_number_of_action_id (each.id));
		list<int> ids2 <- Land_Use_Action 		 collect(id_number_of_action_id (each.id));
		return active_district_code + "_" + (max(ids1 + ids2) + 1);
	}
	
	int current_population{
		return sum (Land_Use accumulate (each.population));
	}
		
	image_file get_action_icon (int cmd){
		switch(cmd){
			match ACTION_MODIFY_LAND_COVER_A 	{return image_file("../images/ihm/S_agricole.png"); 			}
			match ACTION_MODIFY_LAND_COVER_AU 	{return image_file("../images/ihm/S_urbanise.png");			}
			match ACTION_MODIFY_LAND_COVER_AUs 	{return image_file("../images/ihm/S_urbanise_adapte.png");		}
			match ACTION_MODIFY_LAND_COVER_Us 	{return image_file("../images/ihm/S_urbanise_adapte.png");		}
			match ACTION_MODIFY_LAND_COVER_Ui 	{return image_file("../images/ihm/S_urbanise_intensifie.png");	}
			match ACTION_MODIFY_LAND_COVER_N 	{return image_file("../images/ihm/S_naturel.png");				}
			match ACTION_CREATE_DIKE 			{return image_file("../images/ihm/S_creation_digue.png");		}
			match ACTION_REPAIR_DIKE 			{return image_file("../images/ihm/S_reparation_digue.png");	}
			match ACTION_RAISE_DIKE 			{return image_file("../images/ihm/S_elevation_digue.png");		}
			match ACTION_DESTROY_DIKE			{return image_file("../images/ihm/S_suppression_digue.png");	}
			match ACTION_INSTALL_GANIVELLE 		{return image_file("../images/ihm/S_ganivelle.png");			}
			match ACTION_CREATE_DUNE 			{return image_file("../images/ihm/S_creation_digue.png");		}
		}
		return nil;
	}
	
	image_file get_lu_icon (Land_Use lu){
		if(lu.is_in_densification){
			return image_file("../images/icons/urban_intensifie.png");
		}
		switch(lu.lu_code){
			match 1 {return image_file("../images/icons/tree_nature.png");  }
			match 2 {return image_file("../images/icons/urban.png");		 }
			match 4 {return image_file("../images/icons/urban.png"); 		 }
			match 5 {return image_file("../images/icons/agriculture.png");	 }
			match 6 {return image_file("../images/icons/urban_adapte2.png");}
			match 7 {return image_file("../images/icons/urban_adapte2.png");}
		}
		return nil;
	}
	
	action create_tabs {
		float increment <- active_district_name = DISTRICT_AT_TOP ? 0.8 : 0.0;
		
		create Tab {
			point p 		<- {0.25, increment + 0.03};
			legend_name 	<- world.get_message('LEGEND_DYKE');
			display_name 	<- COAST_DEF_DISPLAY;
			do lock_agent_at ui_location: p display_name: GAMA_MAP_DISPLAY ui_width: 0.5 ui_height: 0.06;
		}
		
		create Tab {
			point p 		<- {0.75,increment + 0.03};
			legend_name 	<- world.get_message('LEGEND_PLU');
			display_name 	<- LU_DISPLAY;
			do lock_agent_at ui_location: p display_name: GAMA_MAP_DISPLAY ui_width: 0.5 ui_height: 0.06;
		}	
		
		create Tab_Background {
			point p <- {0.0, 0};
			do lock_agent_at ui_location: p display_name: GAMA_MAP_DISPLAY ui_width: 1.0 ui_height: 1.0;
		}
	}
	
	action lock_window {
		point loc 	<- {world.shape.width/2, world.shape.height/2};
		geometry rec<- rectangle(world.shape.width, world.shape.height);
		draw rec at: loc color: #black;
		float msize <- min([world.shape.width/2, world.shape.height/2]);
		draw image_file("../images/ihm/logo.png") at: loc size: {msize, msize};
	}
	
	action create_buttons {
		float increment <- active_district_name = DISTRICT_AT_TOP ? 0.8:0.0;
		string act_name;
		int lu_index;
		int codef_index;
		loop i from: 0 to: length(data_action)-1{
			act_name <- data_action.keys[i];
			lu_index <- int(data_action at act_name at 'lu_index') - 1;
			codef_index <- int(data_action at act_name at 'coast_def_index') - 1;
			if lu_index >= 0 {
				create Button {
					action_name  <- act_name; 
					display_name <- LU_DISPLAY;
					p <- {0.05 + (lu_index*0.1), increment + 0.13};
				}
			} else if codef_index >= 0 {
				create Button {
					action_name  <- act_name; 
					display_name <- COAST_DEF_DISPLAY;
					p <- {0.05 + (codef_index*0.1), increment + 0.13};
				}
			}
		}
		
		create Button {
			action_name  <- 'ACTION_INSPECT';
			display_name <- BOTH_DISPLAYS;
			p 			 <- {0.65, increment + 0.13};
		}
		create Button_Map {
			action_name  <- 'ACTION_DISPLAY_FLOODING';
			display_name <- BOTH_DISPLAYS;
			location 	 <- {1000, 7000};
			p 			 <- {0.75, increment + 0.13};
		}
		create Button_Map {
			action_name  <- 'ACTION_DISPLAY_FLOODED_AREA';
			display_name <- BOTH_DISPLAYS;
			location 	 <- {1000,8000};
			p 			 <- {0.85, increment + 0.13};
		}
		create Button_Map {
			action_name  <- 'ACTION_DISPLAY_PROTECTED_AREA';
			display_name <- BOTH_DISPLAYS;
			location 	 <- {1000,9000};
			p 			 <- {0.95, increment + 0.13};
		}

		ask Button + Button_Map	{
			do lock_agent_at ui_location: p display_name: GAMA_MAP_DISPLAY ui_width: 0.1 ui_height: 0.1;
			do init_button;
		}
	}
	
	action button_click_general {
		point loc <- #user_location;
		list<Tab> clicked_tab_button <- (Tab overlapping loc);
		if(length(clicked_tab_button) > 0){							// changing tab
			active_display <- first(clicked_tab_button).display_name;
			do clear_selected_button;
			explored_button 		 <- nil;
			explored_lu 	 		 <- nil;
			explored_coast_def 	 	 <- nil;
			explored_land_use_action <- nil;
			explored_coast_def_action<- nil;
			current_action 	 		 <- nil;
		}
		else{
			if(active_display = LU_DISPLAY){do button_click_lu; 	  }
			else						   {do button_click_coast_def;}	
		}	
	}
	
	action button_click_lu {
		point loc <- #user_location;	
		if(active_display != LU_DISPLAY){
			current_action <- nil;
			active_display <- LU_DISPLAY;
			do clear_selected_button;
		}
		list<Button> clicked_lu_button <- (Button where (each overlaps loc and each.display_name != COAST_DEF_DISPLAY));
		if(length(clicked_lu_button) > 0){
			list<Button> current_active_button <- Button where (each.is_selected);
			do clear_selected_button;
			if ((length (current_active_button) = 1 and first(current_active_button).command != (first(clicked_lu_button)).command)) or length (current_active_button) = 0 {
				ask (first(clicked_lu_button)){
					is_selected <- true;
				}
			}
		} else{	
			Button_Map a_MAP_button <- first (Button_Map where (each overlaps loc));
			if a_MAP_button != nil {
				ask a_MAP_button {
					is_selected <- !is_selected;
					switch command {
						match ACTION_DISPLAY_PROTECTED_AREA {my_icon <-  is_selected ? image_file("../images/ihm/I_desafficher_zone_protegee.png") :  image_file("../images/ihm/I_afficher_zone_protegee.png");}
						match ACTION_DISPLAY_FLOODED_AREA   {my_icon <-  is_selected ? image_file("../images/ihm/I_desafficher_PPR.png") 			 :  image_file("../images/ihm/I_afficher_PPR.png");}
					}		
				}
			}
			else {do change_plu;}
		}
	}
	
	action button_click_coast_def {
		point loc <- #user_location;
		if active_display != COAST_DEF_DISPLAY{
			current_action <- nil;
			active_display <- COAST_DEF_DISPLAY;
			do clear_selected_button;
		}
		
		Button clicked_coast_def_button <- first(Button where (each overlaps loc and each.display_name != LU_DISPLAY));
		if clicked_coast_def_button != nil {
			Button current_active_button <- first(Button where (each.is_selected));
			do clear_selected_button;
			
			if (current_active_button != nil and current_active_button.command != clicked_coast_def_button.command) or current_active_button = nil {
				ask clicked_coast_def_button { is_selected <- true; }
			}
		}
		else{
			Button_Map a_MAP_button <- first (Button_Map where (each overlaps loc));
			if a_MAP_button != nil {
				ask a_MAP_button {
					is_selected <- ! is_selected;
					switch command {
						match ACTION_DISPLAY_PROTECTED_AREA {my_icon <-  is_selected ? image_file("../images/ihm/I_afficher_zone_protegee.png") :  image_file("../images/ihm/I_desafficher_zone_protegee.png");}
						match ACTION_DISPLAY_FLOODED_AREA 	{my_icon <-  is_selected ? image_file("../images/ihm/I_afficher_PPR.png") 			 :  image_file("../images/ihm/I_desafficher_PPR.png");}
					}			
				}
			}
			else {	do change_dike; }
		}
	}
	
	action clear_selected_button {
		previous_clicked_point <- nil;
		ask Button {
			self.is_selected <- false;
		}
	}

	action mouse_move_general {
		switch(active_display){
			match LU_DISPLAY  		{do mouse_move_lu;}
			match COAST_DEF_DISPLAY {do mouse_move_coast_def;}
		}
	}
	
	action mouse_move_lu {
		point loc 		<- #user_location;
		explored_button <- (Button + Button_Map) first_with (each overlaps loc and each.display_name != COAST_DEF_DISPLAY); // for inspect
		
		Button current_active_button <- first(Button where (each.is_selected));
		if current_active_button != nil  {
			if hovered_lu != nil {
				hovered_lu.focus_on_me <- false;
			}
			hovered_lu <- first(Land_Use overlapping loc);
			if hovered_lu != nil {
				hovered_lu.focus_on_me <- true;
			}
			// inspect
			if current_active_button.command = ACTION_INSPECT {
				explored_land_use_action <- first(Land_Use_Action overlapping loc);
				explored_lu <- first(Land_Use overlapping loc);
			}
			else{
				explored_land_use_action <- nil;
				explored_lu <- nil;
			}
		}
	}

	action mouse_move_coast_def {
		point loc <- #user_location;
		explored_button <- (Button + Button_Map) first_with (each overlaps loc and each.display_name != LU_DISPLAY); // for inspect
		Button current_active_button <- first(Button where (each.is_selected));
		if current_active_button != nil and current_active_button.command = ACTION_INSPECT {
			explored_coast_def_action <- first(Coastal_Defense_Action overlapping (loc buffer(20#m)));
			explored_coast_def <- first(Coastal_Defense overlapping (loc buffer(10#m)));
		}
		else{
			explored_coast_def_action <- nil;
			explored_coast_def <- nil;
		}
	}
	
	action change_dike {
		point loc <- #user_location;
		Coastal_Defense selected_dike <- first(Coastal_Defense where ((20#m around each.shape) overlaps loc));
		Button selected_button <- Button first_with(each.is_selected);
		if(selected_button != nil){
			if selected_button.command = ACTION_INSPECT {
				return;
			}else if selected_button.command in [ACTION_CREATE_DIKE, ACTION_CREATE_DUNE] {
				if basket_overflow() {return;}
				do create_new_dike(loc, selected_button, selected_button.command);
			}else {
				if selected_dike = nil {return;}
				if basket_overflow() {return;}
				do modify_dike(selected_dike, selected_button);
			}
		}
	}
	
	action modify_dike (Coastal_Defense dk, Button but){
		if dk != nil{
			ask my_basket { // an action on the same dike is already in the basket
				if element_id = dk.coast_def_id {
					return;
				}
			}
			if dk.type = COAST_DEF_TYPE_DUNE and but.command != ACTION_INSTALL_GANIVELLE {return;} // nothing to do
			if dk.type = COAST_DEF_TYPE_DIKE and but.command  = ACTION_INSTALL_GANIVELLE  {return;} // nothing to do
			
			create Coastal_Defense_Action returns: action_list{
				id 			<- world.get_action_id();
				self.label 	<- but.label;
				element_id 	<- dk.coast_def_id;
				self.command<- but.command;
				self.coast_def_type <- dk.type;
				self.initial_application_round <- game_round  + world.delay_of_action(self.command);
				element_shape 	<- dk.shape;
				shape 			<- element_shape + 20#m;
				cost 			<- but.action_cost * dk.length_coast_def;
			}
			previous_clicked_point <- nil;
			current_action <- first(action_list);
			if but.command = ACTION_RAISE_DIKE {
				if !empty(Protected_Area where (each intersects current_action.shape)){
					current_action.is_in_protected_area <- true;
					map<string,bool> vmap <- map<string,bool>(user_input(world.get_message('MSG_POSSIBLE_REGLEMENTATION_DELAY')::true));
					if (!(vmap at vmap.keys[0])) {
						ask current_action {
							do die;
						}
						return;
					}
				}
			}
			my_basket <- my_basket + current_action; 
			ordered_action <- ordered_action + current_action;
			ask(game_basket) {
				do add_action_to_basket(current_action);
			}	
		}
	}
	
	action create_new_dike (point loc, Button but, int comm){
		if(previous_clicked_point = nil){
			previous_clicked_point <- loc;
		}
		else{
			create Coastal_Defense_Action returns: action_list {
				id 			<- world.get_action_id();
				self.label 	<- but.label;
				element_id 	<- -1;
				self.command<- comm;
				self.coast_def_type <- comm = ACTION_CREATE_DIKE ? COAST_DEF_TYPE_DIKE : COAST_DEF_TYPE_DUNE;
				self.initial_application_round <- game_round  + world.delay_of_action(self.command);
				element_shape <- polyline([previous_clicked_point, loc]);
				shape 		 <- element_shape;
				cost 		 <- but.action_cost * shape.perimeter;
				// requesting the altitude of this future dike
				map<string,string> mp <- ["REQUEST"::NEW_DIKE_ALT];
				point end <- last (element_shape.points);
				point origin <- first(element_shape.points);
				put string(origin.x) at: "origin.x" in: mp;
				put string(origin.y) at: "origin.y" in: mp;
				put string(end.x) 	 at: "end.x" in: mp;
				put string(end.y) 	 at: "end.y" in: mp;	
				put id at: "act_id" in: mp;
				ask Network_Player{
					do send to: GAME_MANAGER contents: mp;
				}
			}
			previous_clicked_point <- nil;
			current_action<- first(action_list);
			if !empty(Protected_Area overlapping (current_action.shape)){
				current_action.is_in_protected_area <- true;
				map<string,bool> vmap <- map<string,bool>(user_input(world.get_message('MSG_POSSIBLE_REGLEMENTATION_DELAY')::true));
				if (!(vmap at vmap.keys[0])) {
					ask current_action {
						do die;
					}
					do clear_selected_button;
					return;
				}
			}
			my_basket <- my_basket + current_action; 
			ordered_action <- ordered_action + current_action;
			ask(game_basket) {
				do add_action_to_basket(current_action);
			}	
			do clear_selected_button;
		}
	}

	action change_plu {
		point loc <- #user_location;
		Button selected_button <- Button first_with(each.is_selected);
		if(selected_button != nil){
			Land_Use cell_tmp <- first(Land_Use where (each overlaps loc));
			if cell_tmp = nil {return;}
			if basket_overflow() {return;}
			ask (cell_tmp){
				loop p_act over: my_basket { // an action is already triggered on the same cell
					if p_act.element_id = self.id {
						return;
					}
				}
				if selected_button.command = ACTION_INSPECT	   {return;}	// inspect : do nothing
				if length((Player_Action collect(each.location)) inside cell_tmp) > 0  {return;}
				if(		(lu_name = "N" 		   and selected_button.command = ACTION_MODIFY_LAND_COVER_N)
					 or (lu_name = "A" 		   and selected_button.command = ACTION_MODIFY_LAND_COVER_A)
					 or (lu_name in ["U","AU"] and selected_button.command = ACTION_MODIFY_LAND_COVER_AU)
					 or (lu_name in ["AUs","Us"] and selected_button.command = ACTION_MODIFY_LAND_COVER_AUs)
					 or (lu_name in ["A","N","AU","AUs"] and selected_button.command = ACTION_MODIFY_LAND_COVER_Ui)){
						return; // the cell has already the selected action, do nothing
				}
				if(lu_name in ["U","Us"]){
					switch  selected_button.command {
						match ACTION_MODIFY_LAND_COVER_A {
							map<string,unknown> vmap <- user_input(MSG_WARNING, world.get_message('PLY_MSG_WARNING_U_N')::true);							
							return;	
						}
						match ACTION_MODIFY_LAND_COVER_N {
							map<string,unknown> vmap <- user_input(MSG_WARNING, world.get_message('MSG_EXPROPRIATION_PROCEDURE')::false);		
							if(vmap at vmap.keys[0] = false) {return;}
						}
						match ACTION_MODIFY_LAND_COVER_Ui {
							if density_class = POP_DENSE {
								map<string,unknown> vmap <- user_input(MSG_WARNING, world.get_message('PLY_MSG_WARNING_DENSE')::true);
								return;	
							}
						}
					}
				}
				if(lu_name in ["AUs","Us"] and selected_button.command = ACTION_MODIFY_LAND_COVER_AU){
					map<string,unknown> vmap <- user_input(MSG_WARNING, world.get_message('MSG_IMPOSSIBLE_DELETE_ADAPTED')::true);		
					return;
				}
				if(lu_name in ["A","N"] and selected_button.command in [ACTION_MODIFY_LAND_COVER_AU, ACTION_MODIFY_LAND_COVER_AUs]){
					if empty(Land_Use at_distance 100 where (each.is_urban_type)){	
						map<string,unknown> vmap <- user_input(MSG_WARNING, world.get_message('PLY_MSG_WARNING_OUTSIDE_U')::true);
						return;
					}					
					if (!empty(Protected_Area where (each intersects (circle(10, shape.centroid))))){	
						map<string,unknown> vmap <- user_input(MSG_WARNING, world.get_message('PLY_MSG_WARNING_PROTECTED_U')::true);
						return;
					}
					if(lu_name = "N"){
						map<string,unknown> vmap <- user_input(MSG_WARNING, world.get_message('PLY_MSG_WARNING_N_TO_URBANIZED')::false);		
						if(vmap at vmap.keys[0] = false) {return;}
					}
				}
				
				create Land_Use_Action returns: actions_list{
					id 				<- world.get_action_id();
					element_id 		<- myself.id;
					command 		<- selected_button.command;
					element_shape 	<- myself.shape;
					shape 			<- element_shape;
					previous_lu_name<- myself.lu_name;
					label 			<- selected_button.label;
					cost 			<- selected_button.action_cost;
					initial_application_round <- game_round  + world.delay_of_action(command);
					
					// Overwrites
					if command = ACTION_MODIFY_LAND_COVER_N {
						if previous_lu_name in ["U","Us"] {
							initial_application_round <- game_round + world.delay_of_action(ACTION_EXPROPRIATION);
							cost <- float(myself.expro_cost);
							is_expropriation <- true;
						} else if previous_lu_name = "A" {
							cost <- world.cost_of_action ('ACTON_MODIFY_LAND_COVER_FROM_A_TO_N');
						}
					} 
					else if command = ACTION_MODIFY_LAND_COVER_AUs {
						if previous_lu_name = "U" {
							command <- ACTION_MODIFY_LAND_COVER_Us;
							label 	<- "Change to urban adapted area " + (subsidized_adapted_habitat ? "(Subsidized)":"");
							cost 	<- subsidized_adapted_habitat ? world.cost_of_action('ACTION_MODIFY_LAND_COVER_Us_SUBSIDY') : world.cost_of_action('ACTION_MODIFY_LAND_COVER_Us');	
						}
					}
				}
				current_action  <- first(actions_list);
				my_basket 		<- my_basket + current_action; 
				ordered_action  <- ordered_action + current_action;
				ask(game_basket){
					do add_action_to_basket(current_action);
				}	
			}
		}
	}
	
	string thousands_separator (int a_value){
		string txt <- "" + a_value;
		if length(txt) > 3 {
			txt <- copy_between(txt, 0, length(txt) -3) + "." + copy_between(txt, length(txt) - 3, length(txt));
		}
		return txt;
	}
	
	action user_msg (string msg, string type_msg) {
		write "USER MSG : " + msg;
		ask game_console{
			do write_message(msg, type_msg);
		}
	}
	
	bool basket_overflow {
		if(length(my_basket) = BASKET_MAX_SIZE){
			map vmap <- user_input(MSG_WARNING, world.get_message('PLR_OVERFLOW_WARNING')::true);
			return true;
		}
		return false;
	}
	
	bool basket_event <- false update: false;
	
	action move_down_event_basket{
		if(basket_event) {
			return;
		}
		basket_event <- true;
		ask Basket {
			do move_down_event;
		}
	}
	
	action move_down_event_dossier{
		ask History {
			do move_down_event;
		}
	}
	
	action move_down_event_console{
		ask Message_Console {
			do move_down_event;
		}
	}
}
//------------------------------ End of global -------------------------------//

species Displayed_List_Element skills: [UI_location] schedules: [] {
	int font_size 	<- DISPLAY_FONT_SIZE - 4;
	//bool event <- false update: false;
	string label 	<- "";
	Displayed_List my_parent;
	bool is_displayed;
	int display_index;
	image_file icon <- nil;
	
	action draw_item{
		point pt 	<- location;
		geometry rec2 <- polyline([{0,0}, {ui_width,0}]);		
		geometry rec  <- polygon([{0,0}, {0,ui_height}, {ui_width,ui_height},{ui_width,0},{0,0}]);
		shape 		<- rec;
		location 	<- pt;
		draw rec   at: {location.x, location.y} color: rgb(233,233,233);
		draw rec2  at: {location.x, location.y + ui_height / 2} color: #black;
		draw label at: {location.x - ui_width / 2 + 2 * ui_height, location.y + (font_size/ 2) #px} font: font('Helvetica Neue', font_size, #bold) color: #black;
		if( icon != nil){
			draw icon at: {location.x - ui_width / 2 + ui_height, location.y} size: {ui_height * 0.8, ui_height * 0.8};
		}
	}
	
	bool move_down_event{
		point loc <- #user_location;
		if self overlaps loc and is_displayed {
			do on_mouse_down;
			return true;
		}
		return false;
	}
	
	action on_mouse_down;
	action draw_element;
	
	aspect base{
		if(is_displayed){
			do draw_item;
			do draw_element;
		}
	}
}
//------------------------------ End of Displayed_List_Element -------------------------------//

species List_of_Elements parent: Displayed_List_Element {
	int direction <- 0;
	
	bool move_down_event{
		point loc <- #user_location;
		if ! (self overlaps loc){return false;}
		switch (direction){
			match 2 {
				ask my_parent {
					do go_up;
				}
			}
			match 1 {
				ask my_parent {
					do go_down;
				}
			}		
		}
		return true;
	}
	
	aspect dossier {
		if(is_displayed and my_parent.display_name = GAMA_HISTORY_DISPLAY){
			do draw_item;
			do draw_element;
		}
	}
	
	aspect basket {
		if(is_displayed and my_parent.display_name = GAMA_BASKET_DISPLAY){
			do draw_item;
			do draw_element;
		}
	}
	
	aspect message {
		if(is_displayed and my_parent.display_name = GAMA_MESSAGES_DISPLAY){
			do draw_item;
			do draw_element;
		}
	}	
}
//------------------------------ End of System_List_Element -------------------------------//

species Message_Element parent: Displayed_List_Element schedules:[] {}

//------------------------------ End of Message_Console_Element -------------------------------//

species Displayed_List skills: [UI_location] schedules: []{
	int max_size 	<- 7;
	int font_size 	<- 12;
	float header_height 	<- 0.2;
	float element_height 	<- 0.08;
	string legend_name 		<- "";
	int start_index 		<- 0;
	list<Displayed_List_Element> elements <- [];
	List_of_Elements up_item 	<- nil;
	List_of_Elements down_item 	<- nil;
	string display_name <- "";
	bool show_header 	<- true;
	
	action move_down_event {
		if up_item.is_displayed {
			ask up_item   {do move_down_event;}
			ask down_item {do move_down_event;}
		}
		ask elements where (each.is_displayed){
			if(move_down_event()){return;}
		}
		do on_mouse_down;
	}
	
	action on_mouse_down;
	
	action add_item (Displayed_List_Element list_elem){
		int index 	<- length(elements);
		elements 	<- elements + list_elem;
		point p 	<- get_location(index);
		ask(list_elem){
			is_displayed <- true;
			my_parent 	 <- myself; 
			do lock_agent_at ui_location: p display_name: myself.display_name ui_width: myself.locked_ui_width ui_height: myself.element_height ;
			shape <- rectangle(ui_width, ui_height);
		}
		if length(elements) > max_size{
			do go_to_end;
			up_item.is_displayed 	<- true;
			down_item.is_displayed 	<- true;
		}
		else{
			up_item.is_displayed 	<- false;
			down_item.is_displayed 	<- false;
		}
	}
	
	point get_location (int idx) {
		float header_size <- show_header ? header_height : 0.0;
		idx <- min([idx, max_size - 1]);
		return {locked_location.x + locked_ui_width / 2, idx * element_height + header_size + element_height / 2};
	}
	
	action go_to_end {
		start_index <- length(elements) - max_size + 2;
		do change_start_index (start_index);
	}
	
	action change_start_index (int idx){
		int i <- 0;
		int j <- 1;
		loop elem over: elements{
			if(i >= idx and i < idx + max_size - 2){
				point p <- get_location(j);
				j <- j + 1;
				ask(elem){
					do move_agent_at ui_location: p;
					is_displayed <- true;
				}
			}
			else{elem.is_displayed <- false;}	
			i <- i+1;
		}
	}
		
	action create_navigation_items {
		create List_of_Elements {
			label 	<- "<< Previous";
			point p <- myself.get_location(0);
			do lock_agent_at ui_location: p display_name: myself.display_name ui_width: myself.locked_ui_width ui_height: myself.element_height;
			myself.up_item 		<- self;
			self.is_displayed 	<- false;
			direction 			<- 1;
			my_parent 			<- myself;
		}
		create List_of_Elements {
			label 	<- "                 Next >>";
			point p <- myself.get_location(myself.max_size - 1);
			do lock_agent_at ui_location: p display_name: myself.display_name ui_width: myself.locked_ui_width ui_height: myself.element_height;
			myself.down_item 	<- self;
			self.is_displayed 	<- false;
			direction 			<- 2;
			my_parent 			<- myself;
		}
		 
	}
	
	action go_up {
		start_index <- min([length(elements) - max_size + 2, start_index + 1]);	
		do change_start_index(start_index);
	}
	
	action go_down {
		start_index <- max([0, start_index - 1]);	
		do change_start_index(start_index);	
	}
		
	action remove_all_elements {
		ask(elements){
			do die;
		}
		elements <- [];
		up_item.is_displayed 	<- false;
		down_item.is_displayed 	<- false;
	}
	
	action remove_element (Displayed_List_Element el){
		remove el from: elements;
		if(length(elements) <= max_size) {
			int i 		<- 0;
			start_index <- 0;
			loop elem over: elements{
				point p <- get_location(i);
				i <- i + 1;
				ask(elem){
					do move_agent_at ui_location: p;
					is_displayed <- true;
				}
			}
			up_item.is_displayed <- false;
			down_item.is_displayed <-false;
		}
		else {
			do change_start_index (start_index);
		}
	}
	
	aspect base{
		do draw_list;
	}
	
	action draw_list{
		draw polygon([{0, 0}, {0, ui_height}, {ui_width, ui_height}, {ui_width, 0}, {0, 0}]) at: {location.x + ui_width / 2, location.y + ui_height / 2} color: #white;
		if show_header {do draw_my_header;}
	}
	
	action draw_my_header{
		geometry rec2 	<- polygon([{0,0}, {0,ui_height*header_height}, {ui_width,ui_height*header_height}, {ui_width,0}, {0,0}]);
		point loc2  	<- {location.x + ui_width / 2, location.y + ui_height * header_height / 2};
		draw  rec2 at: loc2 color: rgb(219,219,219);
		
		float gem_height <- ui_height * header_height / 2;
		float gem_width  <- ui_width;
		shape 			 <- rectangle(gem_width, gem_height);
		float x 		 <- location.x;
		float y 		 <- location.y;
		
		geometry rec3 <- polygon([{x,y}, {x,y+gem_height}, {x+gem_width*0.2,y+gem_height}, {x+gem_width*0.25,y+gem_height*1.2}, {x+gem_width*0.3,y+gem_height}, {x+gem_width,y+gem_height}, {x+gem_width,y}, {x,y}]);
		draw rec3 color: rgb(59,124,58);
		draw legend_name at: {location.x + gem_width /2 - (length(legend_name)*6#px/ 2), location.y + gem_height/2 + 4#px} color: #white font: f1;
	}
}
//------------------------------ End of Displayed_List -------------------------------//

species Basket parent: Displayed_List {
	string display_name <- GAMA_BASKET_DISPLAY;
	int budget 		   -> {world.budget};
	float final_budget -> {world.budget - sum(elements collect((Basket_Element(each).current_action).actual_cost))};
	
	point validation_button_size <- {0, 0};
	
	init{
		legend_name <- world.get_message('LEGEND_NAME_ACTIONS');
		point p 	<- {0.0, 0.0};
		do lock_agent_at ui_location: p display_name: display_name ui_width: 1.0 ui_height: 1.0 ;
		do create_navigation_items;
	}
	
	action add_action_to_basket (Player_Action act){
	  	create Basket_Element returns: elem {
			label 	<- act.label;
			if act.is_applied or !(act.command in [ACTION_CREATE_DIKE, ACTION_CREATE_DUNE]) {
				label <- label + " (" + act.element_id +")";	
			}
			icon 	<- world.get_action_icon (act.command);
			current_action <- act;
		}
		do add_item(first(elem));
	}
	
	action draw_budget {
		float gem_height <- ui_height * header_height / 2;
		float gem_width  <- ui_width;
		int mfont_size	 <- DISPLAY_FONT_SIZE - 2;
		draw world.get_message('MSG_INITIAL_BUDGET') font: f0
					color: rgb(101,101,101) at: {location.x + ui_width - 150#px, location.y + ui_height * 0.15 + (mfont_size / 2)#px};
		draw "" + world.thousands_separator(budget) font: f1 color: rgb(101,101,101)
						at: {location.x + ui_width - 70#px, location.y + ui_height * 0.15 + (mfont_size / 2)#px};
	}
	
	action draw_foot {
		draw polygon([{0,0}, {0,0.1*ui_height}, {ui_width,header_height/2*ui_height}, {ui_width,0}, {0,0}]) 
				at: {location.x + ui_width / 2, location.y + ui_height- header_height / 4 * ui_height} color: rgb(219,219,219);
		
		draw world.get_message('MSG_INITIAL_BUDGET') font: f0 color:rgb(101,101,101)
						at: {location.x + ui_width - 170#px,location.y+ui_height-ui_height*header_height/4 #px};
		draw "" + world.thousands_separator(int(final_budget)) font: f1 color:#black
						at: {location.x + ui_width - 80#px,location.y+ui_height-ui_height*header_height/4 #px};
	}
	
	point validation_button_location{
		int index 	<- min([length(elements), max_size]) ;
		float sz 	<- element_height * ui_height;
		point p 	<- {ui_width - sz * 0.75, location.y + (index * sz) + (header_height * ui_height) + (0.75 * element_height * ui_height)};
		return p;
	}
	
	action draw_valid_button {
		point pt 		 <- validation_button_location();
		float sz 		 <- element_height*ui_height;
		image_file icone <- file("../images/ihm/I_valider.png");
		validation_button_size <- {sz * 0.8, sz * 0.8};
		draw icone at: pt size: validation_button_size;
		
		int mfont <- DISPLAY_FONT_SIZE - 2;
		font font1 <- font ('Helvetica Neue', mfont, #plain ); 
		draw world.get_message('PLY_MSG_VALIDATE') at: {location.x + ui_width - 140#px, pt.y + ((DISPLAY_FONT_SIZE - 4) / 2)#px} size: {sz*0.8, sz*0.8} font: f0 color: #black;
		draw " " + world.thousands_separator(int(budget - final_budget)) at: {location.x + ui_width - 90#px, pt.y + (mfont / 2)#px} size: {sz*0.8, sz*0.8} font: font1 color: #black;
	}
	
	action on_mouse_down {
		if(validation_button_location() distance_to #user_location < validation_button_size.x){
			if game_round = 0 {
				map<string,unknown> res <- user_input(MSG_WARNING, world.get_message('MSG_SIM_NOT_STARTED')::true);
				return;
			}
			if empty(game_basket.elements){
				string msg <- world.get_message('PLR_EMPTY_BASKET');
				map<string,unknown> res <- user_input(MSG_WARNING, msg::true);
				return;
			}
			if(budget - round(sum(my_basket collect(each.cost))) < minimal_budget){
				string budget_display <- world.get_message('PLR_INSUFFICIENT_BUDGET');
				ask world {
					do user_msg (budget_display,INFORMATION_MESSAGE);
				}
				map<string,unknown> res <- user_input(MSG_WARNING, budget_display::true);
				return;
			}
			map<string,bool> vmap <- map<string,bool>(user_input(MSG_WARNING, world.get_message('PLR_VALIDATE_BASKET') +
									"\n" + world.get_message('PLR_CHECK_BOX_VALIDATE')::false));
			if(vmap at vmap.keys[0]){
				ask Network_Player{
					do send_basket;
				}
			}
		}
	}
	
	aspect base{
		do draw_list;
		do draw_valid_button;
		do draw_budget;
		do draw_foot;
	}
}
//------------------------------ End of Basket -------------------------------//

species History parent: Displayed_List schedules:[]{
	init{
		max_size 	<- 10;
		show_header <- false;
		display_name<- GAMA_HISTORY_DISPLAY;
		point p 	<- {0.15,0.0};
		do lock_agent_at ui_location: p display_name: display_name ui_width: 0.85 ui_height: 1.0 ;
		do create_navigation_items;
	}
	
	action add_action_to_history(Player_Action act){
	  	create History_Element returns: elem {
			label <- act.label;
			if act.is_applied or !(act.command in [ACTION_CREATE_DIKE, ACTION_CREATE_DUNE]) {
				label <- label + " (" + act.element_id +")";	
			}
			icon <- world.get_action_icon(act.command);
			act.my_hist_elem <- self;
			current_action <- act;
		}
		do add_item(first(elem));
	}
} 
//------------------------------ End of History -------------------------------//

species Message_Console parent: Displayed_List schedules:[]{
	init{
		font_size 	<- 11;
		max_size 	<- 10;
		show_header <- false;
		display_name<- GAMA_MESSAGES_DISPLAY;
		point p 	<- {0.15,0.0};
		do lock_agent_at ui_location: p display_name: display_name ui_width: 0.85 ui_height: 1.0;
		do create_navigation_items;
	}
	
	image_file get_message_icon(string message_type){
		switch(message_type){
			match INFORMATION_MESSAGE {return file("../images/ihm/I_quote.png");}
			match POPULATION_MESSAGE  {return file("../images/ihm/I_population.png");}
			match BUDGET_MESSAGE 	  {return file("../images/ihm/I_BY.png");}
		}
		return file("../images/ihm/I_quote.png");
	}
	
	action write_message (string msg, string type){
		create Message_Element returns: elem {
			label <- msg;
			icon <- myself.get_message_icon(type);
		}
		do add_item(first(elem));
	}
}
//------------------------------ End of Message_Console -------------------------------//

species History_Left_Icon skills:[UI_location]{
	image_file directory_icon <- file("../images/ihm/I_dossier.png");
	aspect base{
		geometry rec <- polygon([{0,0}, {0,ui_height}, {ui_width,ui_height}, {ui_width,0}, {0,0}]);
		draw rec color: rgb(59, 124, 58) at: location;
		draw directory_icon at: {location.x, location.y - ui_height / 4} size: {0.7 * ui_width, 0.7 * ui_width};
	}
}
//------------------------------ End of History_Left_Icon -------------------------------//

species Message_Left_Icon parent: History_Left_Icon {
	image_file directory_icon <- file("../images/ihm/I_quote.png");
}
//------------------------------ End of Message_Left_Icon -------------------------------//

species History_Element parent: Displayed_List_Element schedules:[]{
	int font_size <- 12;
	int delay -> {current_action.added_delay};
	float final_price   -> {current_action.actual_cost};
	float initial_price -> {current_action.cost};
	point bullet_size   -> {ui_height*0.6, ui_height*0.6};
	
	point delay_location 		-> {location.x + 2 * ui_width / 5, location.y};
	point round_apply_location 	-> {location.x + 1.3 * ui_width / 5, location.y};
	point price_location 		-> {location.x + ui_width / 2 - 40#px, location.y};
	Player_Action current_action;
	
	action on_mouse_down{
		if(highlighted_action = current_action){
			highlighted_action <- nil;
		}
		else {highlighted_action <- current_action;}
	}
	
	action draw_element{
		font font1 <- font ('Helvetica Neue', font_size, #italic); 
		
		if(!current_action.is_applied) {
			if(delay != 0){
				draw circle(bullet_size.x / 2) at: delay_location color: rgb(235,33,46);
				draw "" + delay at: {delay_location.x - (font_size / 6)#px , delay_location.y + (font_size / 3)#px} color: #white font: font1;
			}
			draw circle(bullet_size.x / 2) at: round_apply_location color: rgb(87,87,87);
			draw "" + current_action.nb_rounds_before_activation_and_waiting_for_lever_to_activate() at: {round_apply_location.x -(font_size/6)#px , round_apply_location.y + (font_size/3)#px} color: #white font: font1;
		}
		else {
			draw file("../images/ihm/I_valider.png") at: round_apply_location size: bullet_size color: rgb(87,87,87);
		}

		rgb mc <- (final_price = initial_price) ? rgb(87,87,87): rgb(235,33,46);
		draw "" + int(final_price) at: {price_location.x , price_location.y + (font_size / 3)#px} color: mc font: font1;
		
		if(highlighted_action = current_action){
			geometry rec <- polygon([{0,0}, {0,ui_height}, {ui_width,ui_height}, {ui_width,0}, {0,0}]);
			draw rec at: {location.x, location.y} empty: true border: #red;
		}
	}
} 
//------------------------------ End of History_Element -------------------------------//

species Basket_Element parent: Displayed_List_Element {
	int font_size 			<- 12;
	point button_size 		-> {ui_height * 0.6, ui_height * 0.6};
	point button_location 	-> {location.x + ui_width / 2 - (button_size.x), location.y};
	Player_Action current_action <- nil;
	image_file close_button <- file("../images/ihm/I_close.png");
	point bullet_size 			-> {ui_height*0.6, ui_height*0.6};
	point round_apply_location  -> {location.x + 1.3 * ui_width / 5, location.y};
	
	action remove_action{
		ask my_parent{
			do remove_element(myself);
		}
	}
	
	action on_mouse_down {
		if button_location distance_to #user_location <= button_size.x {// Player wants to delete an action from the basket
			remove current_action from: my_basket;
			remove current_action from: ordered_action;
			do remove_action;
			ask current_action {
				do die;
			}
			ask my_parent {
				if length(elements) > max_size {
					do go_up;	
				}
			}
			do die;
		} else {
			if highlighted_action = current_action {
				highlighted_action <- nil;
			}
			else {
				highlighted_action <- current_action;
			}
		}
	}
	
	action draw_element{
		draw close_button at: button_location size: button_size ;
		font font1 <- font ('Helvetica Neue', font_size, #bold ); 
		
		draw "" + world.thousands_separator(int(current_action.cost))  at: {button_location.x - 50#px, button_location.y + (font_size/ 2)#px}  color: #black font: font1;
		draw circle(bullet_size.x / 2) at: round_apply_location color: rgb(87,87,87);
		draw "" + world.delay_of_action(current_action.command) at: {round_apply_location.x - (font_size / 6)#px , round_apply_location.y + (font_size / 3)#px} color: #white font: font1;
	
		if(highlighted_action = current_action){
			geometry rec <- polygon([{0, 0}, {0, ui_height}, {ui_width, ui_height}, {ui_width, 0},{0, 0}]);
			draw rec at: {location.x, location.y} empty: true border: #red;
		}
	}
}
//------------------------------ End of Basket_Element -------------------------------//

species Activated_Lever {
	Player_Action ply_act;
	map<string, string> my_map <- []; // contains attributes sent through network
	
	action init_activ_lever_from_map(map<string, string> m ){
		my_map <- m;
		put OBJECT_TYPE_ACTIVATED_LEVER at: "OBJECT_TYPE" in: my_map;
	}
}
//------------------------------ End of Activated_Lever -------------------------------//

species Network_Listener_To_Leader skills: [network] {
	
	init{do connect to: SERVER with_name: LISTENER_TO_LEADER;}
	
	reflex  wait_message {
		loop while:has_more_message(){
			message msg <- fetch_message();
			map<string, unknown> m_contents <- msg.contents;
			if m_contents[DISTRICT_CODE] = active_district_code {
				switch(m_contents[LEADER_COMMAND]){
					match GIVE_MONEY_TO {
						int amount 	<- int(m_contents[AMOUNT]);
						budget 		<- budget + amount;
						ask world {
							do user_msg(string(m_contents[MSG_TO_PLAYER]) + " " + amount + ' By', BUDGET_MESSAGE);
						}
					}
					match TAKE_MONEY_FROM {
						int amount 	<- int(m_contents[AMOUNT]);
						budget 		<- budget - amount;
						ask world {
							do user_msg(string(m_contents[MSG_TO_PLAYER]) + " " + amount + ' By', BUDGET_MESSAGE);
						}
					}
					match SEND_MESSAGE_TO {
						ask world {
							do user_msg(string(m_contents[MSG_TO_PLAYER]), INFORMATION_MESSAGE);
						}
					}
					match ACTION_SHOULD_WAIT_LEVER_TO_ACTIVATE {
						bool shouldWait <- bool(m_contents[ACTION_SHOULD_WAIT_LEVER_TO_ACTIVATE]);
						if shouldWait {
							Player_Action aAct <- (Land_Use_Action + Coastal_Defense_Action) first_with (each.id = m_contents[PLAYER_ACTION_ID]);
							if aAct != nil {
								aAct.should_wait_lever_to_activate <- bool(m_contents[ACTION_SHOULD_WAIT_LEVER_TO_ACTIVATE]);	
							}
						}
					}
					match NEW_ACTIVATED_LEVER {
						if empty(Activated_Lever where (each.my_map["id"] = int(m_contents["id"]))){
							create Activated_Lever {
								do init_activ_lever_from_map (m_contents);
								ply_act <- (Land_Use_Action + Coastal_Defense_Action) first_with (each.id = my_map["p_action_id"]);
								if ply_act = nil {
									do die;
									return;
								}
								ask world {
									do user_msg (myself. my_map["lever_explanation"], INFORMATION_MESSAGE);
								}
								int added_cost <- int(my_map["added_cost"]);
								if added_cost != 0 {
									budget <- budget - added_cost;
									ask world{
										do user_msg ("You have been " + (added_cost > 0 ? "preleved":"given") + " " + abs(added_cost)+ " By for the dossier '" + myself.ply_act.label + "'", BUDGET_MESSAGE);
									}	
								}
								int added_delay <- int(my_map["added_delay"]);
								if  added_delay != 0{
									ask world{
										do user_msg (world.get_message('PLY_THE_DOSSIER') + " '" + myself.ply_act.label + '(' + myself.ply_act.element_id + ")' " +
											world.get_message("PLY_HAS_BEEN") + " " + (added_delay >= 0 ? world.get_message('PLY_DELAYED'):world.get_message('PLY_ADVANCED')) +
											" " + world.get_message("PLY_BY") + " " + abs(added_delay) + " " + world.get_message('MSG_THE_ROUND') + (abs(added_delay) <=1 ? "" : "s"), INFORMATION_MESSAGE);
									}
									ply_act.should_wait_lever_to_activate <- false;
								}
								add self to: ply_act.activated_levers;
							}
						}
					}
				}
			}
		}
	}	
}
//------------------------------ End of Network_Listener_To_Leader -------------------------------//

species Network_Player skills:[network]{
	init{
		do connect to: SERVER with_name: active_district_code;
		map<string,string> mp <- ["REQUEST"::string(CONNECTION_MESSAGE)];
		do send to: GAME_MANAGER contents: mp;
	}
	
	reflex wait_message{
		loop while:has_more_message(){
			message msg <- fetch_message();
			map<string, string> m_contents <- msg.contents;
			switch m_contents["TOPIC"]{
				match PLAYER_ACTION_IS_APPLIED {
					string act_id <- m_contents["id"];
					ask (Coastal_Defense_Action + Land_Use_Action) first_with (each.id = act_id){
						is_applied <- true;
						my_hist_elem.label <- label + " (" + element_id +")";
						should_wait_lever_to_activate <- false;
					}
				}
				match INFORM_NEW_ROUND {
					game_round	<- game_round + 1;
					ask (Land_Use_Action + Coastal_Defense_Action) where (!each.is_sent) {
						initial_application_round <- initial_application_round + 1;
					}
					switch game_round {
						match 1 {
							ask world {
								do user_msg (world.get_message('MSG_SIM_STARTED_ROUND1'), INFORMATION_MESSAGE);
							}
						}
						default {
							ask world {do user_msg(world.get_message('MSG_THE_ROUND') + " " + game_round + " " + world.get_message('MSG_HAS_STARTED'), INFORMATION_MESSAGE);}
							int current_pop <- world.current_population();
							ask world {
								do user_msg("" + ((previous_population = current_pop) ? "" : (world.get_message('MSG_DISTRICT_RECEIVE') +" " + 
											(current_pop - previous_population) + " " + world.get_message('MSG_NEW_COMERS') +". ")) +
											world.get_message('MSG_DISTRICT_POPULATION') + " " + current_pop + " " +
											world.get_message('MSG_INHABITANTS') + ".", POPULATION_MESSAGE);
							}	
							previous_population <- current_pop;
							received_tax <- int(world.current_population * tax_unit);
							budget <- budget + received_tax;
							ask world {
								do user_msg (world.get_message('MSG_TAXES_RECEIVED_FROM') +" "+ world.thousands_separator(received_tax) +' By', BUDGET_MESSAGE);
							}
						}
					}
				}
				match INFORM_CURRENT_ROUND {
					game_round <- int(m_contents[NUM_ROUND]);
					is_active_gui <- ! bool(m_contents["GAME_PAUSED"]);
					if game_round != 0 {
						ask world {
							do refresh_all;
							do user_msg(world.get_message('MSG_ITS_ROUND') + " " + game_round, INFORMATION_MESSAGE);
						}
					}
				}
				match DISTRICT_BUDGET_UPDATE {
					budget <- int(m_contents[BUDGET]);
				}
				match INFORM_LU_ALTS {
					ask Land_Use where (each.id = int(m_contents["id"])){
						mean_alt <- float(m_contents["mean_alt"]);
					}
				}
				match ACTION_DIKE_CREATED{
					do dike_create_action(m_contents);
				}
				match NEW_DIKE_ALT {
					ask Coastal_Defense_Action where (each.id = m_contents["act_id"]){
						altit <- float(m_contents["altit"]);
					}
				}
				match ACTION_DIKE_UPDATE {
					if length(Coastal_Defense where(each.coast_def_id = int(m_contents["coast_def_id"]))) = 0{
						do dike_create_action(m_contents);
					}
					ask Coastal_Defense where(each.coast_def_id = int(m_contents["coast_def_id"])){
						ganivelle 	<- bool(m_contents["ganivelle"]);
						alt			<- float(m_contents["alt"]);
						status 		<- m_contents["status"];
						type 		<- m_contents["type"];
						height 		<- float(m_contents["height"]);
					}
				}
				match ACTION_DIKE_DROPPED {
					ask Coastal_Defense where (each.coast_def_id = int(m_contents["coast_def_id"])) {
						do die;
					}
				}
				match ACTION_LAND_COVER_UPDATE {	
					ask Land_Use where(each.id = int(m_contents["id"])){
						lu_code 	<- int(m_contents["lu_code"]);
						lu_name 	<- lu_type_names[lu_code];
						population 	<-int(m_contents["population"]);
						is_in_densification <- bool(m_contents["is_in_densification"]);
					}
				}
				match DATA_RETRIEVE {
					switch(m_contents["OBJECT_TYPE"]){
						match OBJECT_TYPE_WINDOW_LOCKER {
							write "Lock unlock request : " + m_contents["LOCK_REQUEST"];
							is_active_gui <- m_contents["LOCK_REQUEST"] = "UNLOCK";
						}
						match OBJECT_TYPE_PLAYER_ACTION {
							
							if(m_contents["action_type"] = PLAYER_ACTION_TYPE_COAST_DEF){
								create Coastal_Defense_Action {
									do init_action_from_map(m_contents);
									ask (game_history){
										do add_action_to_history(myself);
									}
								}
							}
							else if m_contents["action_type"] = PLAYER_ACTION_TYPE_LU {
								create Land_Use_Action {
									do init_action_from_map(m_contents);
									ask(game_history) {
										do add_action_to_history(myself);
									} 
								}
							}
						}
						match OBJECT_TYPE_COASTAL_DEFENSE {
							create Coastal_Defense {
								do init_coastal_def_from_map(m_contents);
							}	
						}
						match OBJECT_TYPE_LAND_USE {
							create Land_Use {
								do init_lu_from_map(m_contents);
							}	
						}
						match OBJECT_TYPE_ACTIVATED_LEVER{
							create Activated_Lever {
								do init_activ_lever_from_map(m_contents);
								ply_act <- (Land_Use_Action + Coastal_Defense_Action) first_with (each.id = my_map["p_action_id"] );
								if ply_act != nil {
									add self to: ply_act.activated_levers;	
								}
							}				
						}
					}
				}
				match "NEW_SUBMERSION_EVENT" {
					flooded_cells <- int(m_contents["flooded_cells"]);
					cell_width <- int(m_contents["cell_width"]);
					cell_height <- int(m_contents["cell_height"]);
					ask Cell { do die; }
				}
				match "NEW_FLOODED_CELLS" {
					loop i from: 0 to: flooded_cells - 1{
						create Cell{
							loc <- point(float(m_contents["cell_location_x"+i]), float(m_contents["cell_location_y"+i]));
							col <- world.color_of_water_height (float(m_contents["water_height"+i]));
						}
					}
				}
			}
		}
	}
	
	action dike_create_action(map<string, string> msg){
		create Coastal_Defense {
			coast_def_id <- int(msg at "coast_def_id");
			shape <- polyline([{float(msg at "p1.x"),float(msg at "p1.y")}, {float(msg at "p2.x"),float(msg at "p2.y")}]);
			location <- {float(msg at "location.x"), float(msg at "location.y")};
			length_coast_def <- int(shape.perimeter);
			type <- msg at "type";
			height <- float(msg at "height");
			status <- msg at "status";
			alt <- float(msg at "alt");
			ask Coastal_Defense_Action first_with(each.id = msg at "action_id") {
				element_id <- myself.coast_def_id;
			}
		}			
	}
	
	action send_basket{
		Player_Action act <-nil;
		loop bsk_el over: game_basket.elements {
			act <- Basket_Element(bsk_el).current_action;
			act.is_sent <- true;
			ask(game_history) {
				do add_action_to_history (act);
			}
			map<string, string> mp <- act.build_data_map();
			put PLAYER_ACTION at: "REQUEST" in: mp;
			do send to: GAME_MANAGER contents: mp;
			budget <- int(budget - act.cost);
		}
		ask game_basket{
			do remove_all_elements;
		}
		my_basket <- [];
	}
}
//------------------------------ End of Network_Player -------------------------------//

species Player_Action {
	string id 		<- "";
	int element_id	<- 0;
	geometry element_shape;
	int command 		<- -1;
	string label 		<- "";
	int initial_application_round <- -1; // round where the action is supposed to be executed
	int added_delay -> {activated_levers sum_of int(each.my_map["added_delay"])};
	int effective_application_round -> {initial_application_round + added_delay};
	bool is_delayed -> {added_delay > 0} ;
	float cost 		<- 0.0;
	int added_cost 		-> {activated_levers sum_of int(each.my_map["added_cost"])};
	float actual_cost 	-> {cost + added_cost};
	bool has_added_cost -> {added_cost > 0} ;
	bool has_diminished_cost -> {added_cost < 0};
	bool is_sent 		<- false;
	bool is_applied 	<- false;
	bool is_highlighted <- false;
	History_Element my_hist_elem <- nil;
	
	string action_type 		<- PLAYER_ACTION_TYPE_COAST_DEF ;
	string previous_lu_name <- nil;
	bool is_expropriation 	<- false;
	bool is_in_protected_area 	<- false;
	bool is_in_coast_border_area 	<- false;
	bool is_in_risk_area 		<- false; 
	bool is_inland_dike 		<- false;
	bool has_activated_levers 				-> {!empty(activated_levers)};
	list<Activated_Lever> activated_levers 	<-[];
	bool should_wait_lever_to_activate 		<- false;
	
	action init_action_from_map(map<string, unknown> mp){
		self.id			 	<- string(mp at "id");
		self.element_id 	<- int(mp at "element_id");
		self.command 		<- int(mp at "command");
		self.label 			<- world.label_of_action(command);
		self.cost 			<- float(mp at "cost");
		self.initial_application_round <- int(mp at "initial_application_round");
		self.is_inland_dike 	<- bool(mp at "is_inland_dike");
		self.is_in_risk_area 	<- bool(mp at "is_in_risk_area");
		self.is_in_coast_border_area 	<- bool(mp at "is_in_coast_border_area");
		self.is_expropriation 	<- bool(mp at "is_expropriation");
		self.is_in_protected_area 	<- bool(mp at "is_in_protected_area");
		self.previous_lu_name 	<- string(mp at "previous_lu_name");
		self.action_type 	<- string(mp at "action_type");
		self.is_applied		<- bool(mp at "is_applied");
		self.is_sent		<- bool(mp at "is_sent");
		
		location <- {float(mp at "locationx"), float(mp at "locationy")};
		bool loop_again <- true;
		int i <- 0;
		list<point> all_points <- [];
		loop while: loop_again{
			string xd <- mp at ("locationx" + i);
			if xd != nil {
				all_points <- all_points + {float(xd), float(mp at ("locationy" + i))};
				i <- i + 1;
			} else {
				loop_again <- false;
			}
		}
		if(self.action_type = PLAYER_ACTION_TYPE_COAST_DEF){
			element_shape <- polyline(all_points);
			shape 		  <-  element_shape;// + shape_width; //shape_width around element_shape;
		}
		else{
			element_shape <- polygon(all_points);
			shape <- element_shape;
		}
	}
	
	map<string,string> build_map_from_attribute{
		map<string,string> res <- [
			"OBJECT_TYPE"::OBJECT_TYPE_PLAYER_ACTION,
			"id"::id,
			"element_id"::string(element_id),
			(DISTRICT_CODE)::active_district_code,
			"command"::string(command),
			"label"::label,
			"cost"::string(cost),
			"initial_application_round"::string(initial_application_round),
			"action_type"::action_type,
			"previous_lu_name"::previous_lu_name,
			"is_expropriation"::string(is_expropriation),
			"is_inland_dike"::string(is_inland_dike),
			"is_in_risk_area"::string(is_in_risk_area),
			"is_in_coast_border_area"::string(is_in_coast_border_area),
			"is_in_protected_area"::string(is_in_protected_area),
			"is_applied"::string(is_applied),
			"is_sent"::string(is_sent),
			"shape"::string(shape)];
		return res;
	}
	
	int nb_rounds_before_activation_and_waiting_for_lever_to_activate {
		int nb_rounds <- effective_application_round - world.game_round;
		if nb_rounds < 0 {
		 	if should_wait_lever_to_activate {return 0;}
		 	else {
		 		write "Activation delay is anormal !";
		 	}
		}
		return nb_rounds;
	}
	
	map<string,string> build_data_map {
		map<string,string> mp <- ["command"::command,"id"::id,
			"initial_application_round"::initial_application_round,
			"element_id"::element_id, "action_type"::action_type,
			"is_in_protected_area"::is_in_protected_area, "previous_lu_name"::previous_lu_name,
			"is_expropriation"::is_expropriation, "cost"::int(cost)];
		
		if command in [ACTION_CREATE_DIKE, ACTION_CREATE_DUNE]  {
				point end <- last (element_shape.points);
				point origin <- first(element_shape.points);
				put string(origin.x) at: "origin.x" in: mp;
				put string(origin.y) at: "origin.y" in: mp;
				put string(end.x) 	 at: "end.x" in: mp;
				put string(end.y) 	 at: "end.y" in: mp;
				put string(location.x) at: "location.x" in: mp;
				put string(location.y) at: "location.y" in: mp;				
		}
		return mp;
	}	
}
//------------------------------ End of Player_Action -------------------------------//

species Coastal_Defense_Action parent: Player_Action {
	string action_type 	<- PLAYER_ACTION_TYPE_COAST_DEF;
	string coast_def_type;
	float altit <- 0.0;
		
	rgb define_color {
		switch(command){
			 match ACTION_CREATE_DIKE 		{return #black; }
			 match ACTION_REPAIR_DIKE 		{return #green; }
			 match ACTION_DESTROY_DIKE 		{return #orange;}
			 match ACTION_RAISE_DIKE 		{return #blue;  }
			 match ACTION_INSTALL_GANIVELLE {return #indigo;}
			 match ACTION_CREATE_DUNE		{return #gold; }
		} 
		return #grey;
	}
	
	aspect map {
		if active_display = COAST_DEF_DISPLAY and !is_applied {
			draw 20#m around shape color: self = highlighted_action ? #red : (is_sent ? define_color() : #black);
		}
	}
}
//------------------------------ End of Coastal_Defense_Action -------------------------------//

species Land_Use_Action parent: Player_Action {
	string action_type <- PLAYER_ACTION_TYPE_LU;
	
	rgb define_color {
		switch(command){
			 match ACTION_MODIFY_LAND_COVER_A {return rgb(245,147,49);}
			 match ACTION_MODIFY_LAND_COVER_N {return rgb(11,103,59); }
			 match_one [ACTION_MODIFY_LAND_COVER_AU,
			 			ACTION_MODIFY_LAND_COVER_AUs,
			 			ACTION_MODIFY_LAND_COVER_Us,
			 			ACTION_MODIFY_LAND_COVER_Ui] {return rgb(0,129,161);}
		} 
		return #grey;
	}
	
	aspect map {
		if active_display = LU_DISPLAY and !is_applied {
			list<geometry> trs <- to_triangles(shape);
			draw first(trs where (each.area = max(trs collect (each.area)))) color: define_color() border: define_color();
			draw shape at: location empty: true border: (self = highlighted_action) ? #red: (is_sent ? define_color() : #black) ;
			
			if(command = ACTION_MODIFY_LAND_COVER_Ui){
				geometry sq <- first(to_squares(shape, 1, false));
				draw file("../images/icons/crowd.png") size: sq.width at: sq.location;
			}
			else if command in [ACTION_MODIFY_LAND_COVER_AUs, ACTION_MODIFY_LAND_COVER_Us]{
				geometry sq <- first(to_squares(shape, 1, false));
				draw file("../images/icons/wave.png") size: sq.width at: sq.location;
			}
		}
	}
}
//------------------------------ End of Land_Use_Action -------------------------------//

species Button skills:[UI_location] {
	string action_name;
	int command;
	string display_name;
	string label;
	float action_cost;
	bool is_selected  	<- false;
	geometry shape 		<- square(button_size);
	point p;
	image_file my_icon;
	string help_msg;
		
	action init_button {
		command 	<- int(data_action at action_name at 'action_code');
		label 		<- world.label_of_action(command);
		action_cost <- world.cost_of_action(action_name);
		help_msg 	<- world.get_message((data_action at action_name at 'button_help_message'));
		my_icon 	<-  image_file(data_action at action_name at 'button_icon_file') ;
	}
	
	aspect map{
		float select_size <- min([ui_width,ui_height]);
		shape <- rectangle(select_size, select_size);
		if(display_name = active_display or display_name = BOTH_DISPLAYS){
			draw my_icon size: {select_size, select_size};
			if(is_selected){
				draw shape empty: true border: # red ;
			}
		}
	}
}
//------------------------------ End of Button -------------------------------//

species Button_Map parent: Button {
	geometry shape <- square(850#m);
	
	aspect base{
		draw shape color: #white border: is_selected ? # red : # white;
		draw my_icon size: 800#m ;
	}
}
//------------------------------ End of Button_Map -------------------------------//

species District {
	string district_name <- "";
	string district_code <- "";
	aspect base{
		draw shape color: self = active_district ? rgb (202,170,145) : #whitesmoke border: #gray;
	}
}
//------------------------------ End of District -------------------------------//

species Land_Use {
	int id;
	string lu_name 	<- "";
	int lu_code 	<- 0;
	string dist_code<- "";
	rgb my_color 	<- cell_color() update: cell_color();
	int population;
	float mean_alt;
	string density_class -> {population = 0 ? POP_EMPTY : (population < POP_LOW_NUMBER ? POP_LOW_DENSITY: (population < POP_MEDIUM_NUMBER ? POP_MEDIUM_DENSITY : POP_DENSE))};
	int expro_cost 		 -> {round (population * 400* population ^ (-0.5))};
	bool is_urban_type 	 -> {lu_name in ["U","Us","AU","AUs"]};
	bool is_adapted_type -> {lu_name in ["Us","AUs"]};
	bool is_in_densification <- false;
	bool focus_on_me <- false;

	action init_lu_from_map(map<string, unknown> a ){
		self.id 				 <- int   (a at "id");
		self.lu_code 			 <- int   (a at "lu_code");
		self.lu_name 			 <- lu_type_names[lu_code];
		self.population 		 <- int   (a at "population");
		self.mean_alt			 <- float (a at "mean_alt");
		self.is_in_densification <- bool  (a at "is_in_densification");
		point pp  				 <- {float(a at "locationx"), float(a at "locationy")};
		point mpp <- pp;
		int i 	  <- 0;
		list<point> all_points <- [];
		loop while: (pp != nil){
			string xd <- a at ("locationx" + i);
			if(xd != nil){
				pp <- {float(xd), float(a at ("locationy" + i))};
				all_points <- all_points + pp;
			}
			else{pp<-nil;}
			i <- i + 1;
		}
		shape  	 <- polygon(all_points);
		location <- mpp;
	}
	
	rgb cell_color{
		switch (lu_name){
			match	  	"N" 				 {return #green;		} // natural
			match	  	"A" 				 {return #orange;		} // agricultural
			match_one ["AU","AUs"]  		 {return #yellow;		} // to urbanize
			match_one ["U","Us"] {									  // urbanised
				switch density_class 		 {
					match POP_EMPTY 		 {return rgb(245,245,245);	}
					match POP_LOW_DENSITY	 {return rgb(220,220,220);	}
					match POP_MEDIUM_DENSITY {return rgb(192,192,192);	}
					match POP_DENSE 		 {return rgb(169,169,169);	}
					default 				 {write "Density class problem !";}
				}
			}			
		}
		return #black;
	}

	aspect map {
		if(active_display = LU_DISPLAY){
			draw shape color: my_color;	
			if(is_adapted_type)		{draw file("../images/icons/wave.png") size: self.shape.width;}
			if(is_in_densification)	{draw file("../images/icons/crowd.png") size: self.shape.width;}
			if focus_on_me {
				draw shape empty: true border: #black;
			}
		}			
	}
}
//------------------------------ End of Land_Use -------------------------------//

species Coastal_Defense {
	int coast_def_id;
	string type;
	string district_code;
	rgb color <- #pink;
	float height;
	bool ganivelle <- false;
	float alt <- 0.0;
	string status;	
	int length_coast_def;
	
	action init_coastal_def_from_map(map<string, unknown> a ){
		self.coast_def_id<- int(a at "coast_def_id");
		self.type 		<- string(a at "type");
		self.status 	<- string(a at "status");
		self.height 	<- float(a at "height");
		self.alt 		<- float(a at "alt");
		self.ganivelle 	<- bool(a at "ganivelle");		
		self.location	<- {float(a at "locationx"), float(a at "locationy")};
		
		int tot_points	<- int(a at "tot_points");
		point pp;
		list<point> all_points <- [];
		loop i from: 0 to: tot_points - 1 {
			pp <- {float(a at ("locationx"+i)), float(a at ("locationy"+i))};
			add pp to: all_points;
		}
		shape <- polyline(all_points);
		length_coast_def <- int(shape.perimeter);
	}
	
	action init_coastal_def {
		if status = ""  {status <- STATUS_GOOD;	    } 
		if type = '' 	{type 	 <- COAST_DEF_TYPE_DIKE;}
		if height = 0.0 {height <- MIN_HEIGHT_DIKE;    }
		length_coast_def <- int(shape.perimeter);
	}
	
	aspect map {
		if(active_display = COAST_DEF_DISPLAY) {
			switch status {
				match STATUS_GOOD   {color <- #green;}
				match STATUS_MEDIUM {color <- #orange;} 
				match STATUS_BAD 	{color <- #red;  } 
				default 			{
					color <- #black;
					write "" + coast_def_id + " Coast Def status problem ! " + status;
				}
			}
			if type = COAST_DEF_TYPE_DIKE {
				draw 20#m around shape color: color;
				draw shape color: #black;
			}
			else{
				draw 50#m around shape color: color;
				draw shape color: #black;
				if ganivelle {
					loop i over: points_on(shape, 40#m) {
						draw circle(10,i) color: #black;
					}
				} 
			}
		}
	}
}
//------------------------------ End of Coastal_Defense -------------------------------//

species Tab_Background skills: [UI_location]{
	aspect base{
		float increment 	<- active_district_name = DISTRICT_AT_TOP ? 0.8 : 0.0;
		geometry rec1 		<- polygon([{0, 0}, {0, ui_height * 0.06}, {ui_width, ui_height * 0.06}, {ui_width, 0}, {0, 0}]);
		geometry rec2 		<- polygon([{0, 0}, {0, ui_height * 0.2}, {ui_width, ui_height * 0.2}, {ui_width, 0}, {0, 0}]);
		point loc1  		<- {location.x + ui_width / 2, location.y + ui_height * (increment + 0.03)};
		point loc2  		<- {location.x + ui_width / 2, location.y + ui_height * (increment + 0.1)};
		draw rec2 at: loc2 color: rgb(219,219,219);
		draw rec1 at: loc1 color: rgb(148,148,148);
	}
}
//------------------------------ End of Tab_Background -------------------------------//

species Tab skills: [UI_location]{
	string display_name;
	string legend_name;
	
	aspect base{
		float gem_height <- ui_height;
		float gem_width  <- ui_width;
		float x 		 <- location.x - ui_width / 2;
		float y 		 <- location.y - ui_height / 2;
		shape <- polygon([{x, y}, {x, y + gem_height}, {x + gem_width, y + gem_height}, {x + gem_width, y}, {x, y}]);
		
		if(active_display = display_name){	
			geometry rec2 <- polygon([{x, y}, {x, y + gem_height}, {x + gem_width * 0.2, y + gem_height}, {x + gem_width * 0.225, y + gem_height * 1.2},
					{x + gem_width * 0.25, y + gem_height}, {x + gem_width, y + gem_height}, {x + gem_width, y}, {x, y}]);
			draw rec2 color: rgb(59,124,58);
		}
		font font0 <- font(DISPLAY_FONT_NAME, DISPLAY_FONT_SIZE, #bold + #italic); 
		draw legend_name at: {location.x - (length(legend_name) * (DISPLAY_FONT_SIZE / 2) #px / 2), location.y + DISPLAY_FONT_SIZE / 3 #px} color: #white font: font0;
	}
}
//------------------------------ End of Tab -------------------------------//

species Road {
	aspect base {
		draw shape color:#gray;
	}
}

species Water {
	aspect base {
		draw shape color:#blue;
	}
}

species Cell{
	point loc;
	rgb col;
	aspect base{
		if (Button_Map first_with (each.command = ACTION_DISPLAY_FLOODING)).is_selected {
			draw rectangle(cell_width,cell_height) color: col at: loc;	
		}
	}
}

species Protected_Area {
	aspect base {
		if (Button_Map first_with (each.command = ACTION_DISPLAY_PROTECTED_AREA)).is_selected {
			draw shape color: rgb (185, 255, 185, 120) border:#black;
		}
	}
}

species Flood_Risk_Area{
	aspect base {
		if (Button_Map first_with(each.command = ACTION_DISPLAY_FLOODED_AREA)).is_selected {
			draw shape color: rgb (160, 32, 240, 120) border:#black;
		}
	}
}

species Legend_Flood{
	list<rgb> colors <- [];
	list<string> texts <- [];
	point start_location;
	point rect_size <- {300, 300};
	rgb text_color  <- #yellow;
	
	init{
		texts <- ["<0.5","",">1.0"];
		colors<- [rgb(200,200,255),rgb(115,115,255),rgb(65,65,255)];
	}
	
	aspect {
		if (Button_Map first_with (each.command = ACTION_DISPLAY_FLOODING)).is_selected {
			start_location <- (Button_Map first_with (each.command = ACTION_DISPLAY_FLOODING)).location + {-300,500};
			loop i from: 0 to: length(texts){
				draw rectangle(rect_size) at: start_location + {i * rect_size.x,0} color: colors[i] border: #black;
				draw texts[i] at: start_location + {(i * rect_size.x) - 120, 50} color: text_color size: rect_size.y;
			}
		}
	}
}
//---------------------------- Experiment definiton -----------------------------//

experiment LittoSIM_GEN_Player type: gui{
	font regular 			<- font("Helvetica", 14, # bold);
	list<string> districts 	<- map(eval_gaml(first(text_file(first(text_file("../includes/config/littosim.conf").contents where (each contains 'SHAPES_FILE')) split_with ';' at 1).contents where (each contains 'MAP_DIST_CODE_SHORT_NAME')) split_with ';' at 1)).values;
	string default_language <- first(text_file("../includes/config/littosim.conf").contents where (each contains 'LANGUAGE')) split_with ';' at 1;

	parameter "District choice : " var: active_district_name <- districts[1] among: districts;
	parameter "Language choice : " var: my_language	 <- default_language  among: languages_list;
	
	init {minimum_cycle_duration <- 0.5;}
	
	layout horizontal([vertical([0::75,1::25])::70, vertical([2::50,3::50])::30]) tabs: false toolbars: false;
	
	output{
		
		display "Map" background: #black focus: active_district{
			graphics "World" {
				draw shape color: rgb(0,188,196);
				if application_name = "camargue" {
					draw rectangle(2*world.shape.width, world.shape.height) at: {0,0} color: #black;
				}
			}
			species District aspect: base;
			graphics "Population" {
				draw population_area color: rgb(105,105,105) ;
			}
			species Land_Use 				aspect: map;
			species Cell					aspect: base;
			species Land_Use_Action 		aspect: map;
			species Coastal_Defense_Action 	aspect: map;
			species Coastal_Defense 		aspect: map;
			species Road 					aspect:	base;
			species Water					aspect: base;
			species Protected_Area 			aspect: base;
			species Flood_Risk_Area 		aspect: base;
			species Tab_Background 			aspect: base;
			species Tab 					aspect: base;
			species Button 					aspect: map;
			species Button_Map				aspect: map;
			species Legend_Flood;
			
			graphics "Coast Def Info" transparency: 0.3 {
				if explored_coast_def != nil {
					point target <- {explored_coast_def.location.x  ,explored_coast_def.location.y};
					point target2 <- {explored_coast_def.location.x + 1 *(INFORMATION_BOX_SIZE.x#px),explored_coast_def.location.y + 1*(INFORMATION_BOX_SIZE.y#px+40#px)};
					draw rectangle(target,target2) border: false color: #black ;
					
					draw world.get_message('PLY_MSG_INFO_AB') + " : " + world.get_message('MSG_' + explored_coast_def.type) at: target + {5#px, 15#px} font: regular color: #white;
					int xpx <-0;
					draw world.get_message('PLY_MSG_LENGTH') + " : " + string(round(100*explored_coast_def.length_coast_def)/100) + "m" at: target + {30#px, xpx#px + 35#px} font: regular color: # white;
					xpx <- xpx+20;
					draw world.get_message('PLY_MSG_ALTITUDE') + " : " + string(round(100*explored_coast_def.alt)/100) + "m" at: target + {30#px, xpx#px + 35#px} font: regular color: # white;
					xpx <- xpx+20;
					if explored_coast_def.type = COAST_DEF_TYPE_DIKE {
						draw world.get_message('PLY_MSG_HEIGHT') + " : " + string(round(100*explored_coast_def.height)/100) + "m" at: target + {30#px, xpx#px + 35#px} font: regular color: # white;
						xpx <- xpx+20;
					}
					draw world.get_message('PLY_MSG_STATE') + " : " + world.get_message('PLY_MSG_' + explored_coast_def.status) at: target + {30#px, xpx#px + 35#px} font: regular color: # white;
					draw "ID : "+ string(explored_coast_def.coast_def_id) at: target + {30#px, xpx#px + 55#px} font: regular color: # white;
					
					if explored_coast_def.status != STATUS_GOOD {
						point image_loc <- {explored_coast_def.location.x + 1*(INFORMATION_BOX_SIZE.x#px) - 40#px, explored_coast_def.location.y + 80#px};
						switch(explored_coast_def.status){
							match STATUS_MEDIUM {draw file("../images/icons/danger.png")  at: image_loc size: 50#px;}
							match STATUS_BAD 	{draw file("../images/icons/rupture.png") at: image_loc size: 50#px;}
						}	
					}
				}
			}
		
			graphics "Coast Def Action" transparency: 0.3 {// explore coast def action 
				if explored_coast_def_action != nil and !explored_coast_def_action.is_applied and explored_coast_def_action.command in [ACTION_CREATE_DIKE, ACTION_CREATE_DUNE] {
					point target <- {explored_coast_def_action.location.x  ,explored_coast_def_action.location.y};
					point target2 <- {explored_coast_def_action.location.x + 1 *(INFORMATION_BOX_SIZE.x#px),explored_coast_def_action.location.y + 1*(INFORMATION_BOX_SIZE.y#px+40#px)};
					draw rectangle(target,target2) border: false color: #black ;
					
					draw world.get_message('PLY_MSG_INFO_AB') + " : " + world.get_message('MSG_' + explored_coast_def_action.coast_def_type)  at: target + {5#px, 15#px} font: regular color: #white;
					int xpx <-0;
					draw world.get_message('PLY_MSG_LENGTH') + " : " + string(round(100*explored_coast_def_action.shape.perimeter)/100) + "m" at: target + {30#px, xpx#px + 35#px} font: regular color: # white;
					xpx <- xpx+20;
					if explored_coast_def_action.coast_def_type = COAST_DEF_TYPE_DIKE {
						draw world.get_message('PLY_MSG_ALTITUDE') + " : " + string(round(100*explored_coast_def_action.altit)/100) + "m" at: target + {30#px, xpx#px +35#px} font: regular color: # white;
						xpx <- xpx+20;
					}
					draw world.get_message('PLY_MSG_HEIGHT') + " : " + string(round(100*BUILT_DIKE_HEIGHT)/100.0) + "m" at: target + {30#px, xpx#px +35#px} font: regular color: # white;
					xpx <- xpx+20;
					draw world.get_message('PLY_MSG_STATE') + " : " + world.get_message('PLY_MSG_GOOD') at: target + {30#px, xpx#px +35#px} font: regular color: # white;
					draw world.get_message('PLY_MSG_APP_ROUND') + " : " + string(explored_coast_def_action.initial_application_round) at: target + {30#px, xpx#px +55#px} font: regular color: # white;
				}
			}
			
			graphics "Button Info" transparency: 0.5 {
				if explored_button != nil {
					float increment <- active_district_name = DISTRICT_AT_TOP ? (-2 * INFORMATION_BOX_SIZE.y #px) : 0.0;
					point target 	<- world.button_box_location(explored_button.location, int(2 * (INFORMATION_BOX_SIZE.x #px)));
					point target2 	<- {target.x - 2 * (INFORMATION_BOX_SIZE.x #px), target.y + increment};
					float xxx <- active_display = COAST_DEF_DISPLAY ? 1.0 : 1.25; 
					point target3 <- {target.x , target.y + xxx * (INFORMATION_BOX_SIZE.y #px) + increment};
					
					draw rectangle(target2,target3) border: false color: #black ;
					draw explored_button.label    at: target2 + {5#px, 15#px} font: regular color: # white;
					draw explored_button.help_msg at: target2 + {30#px, 35#px} font: regular color: # white;

					if !(explored_button.command in [ACTION_INSPECT,ACTION_DISPLAY_PROTECTED_AREA, ACTION_DISPLAY_FLOODED_AREA, ACTION_DISPLAY_FLOODING]) {
						string txtt;
						if active_display = LU_DISPLAY { txtt <- world.get_message('MSG_COST_APPLIED_PARCEL'); }
						switch explored_button.command {	
							match ACTION_MODIFY_LAND_COVER_N {
								draw txtt + " A : "  + world.cost_of_action('ACTON_MODIFY_LAND_COVER_FROM_A_TO_N') at:   target2 + {30#px, 55#px} font: regular color: # white; 
								draw txtt + " AU : " + world.cost_of_action('ACTON_MODIFY_LAND_COVER_FROM_AU_TO_N') at: target2 + {30#px, 75#px} font: regular color: # white; 
								draw txtt + " U : "  + world.get_message('MSG_COST_EXPROPRIATION') at: target2 + {30#px, 95#px} font: regular color: # white;
							}
							match ACTION_MODIFY_LAND_COVER_AUs{
								draw txtt + " AU : " + explored_button.action_cost  at: target2 + {30#px, 55#px} font: regular color: # white;
								draw txtt + " U : "  + (subsidized_adapted_habitat ? world.cost_of_action('ACTION_MODIFY_LAND_COVER_Us_SUBSIDY') : world.cost_of_action('ACTION_MODIFY_LAND_COVER_Us')) at: target2 + {30#px, 75#px} font: regular color: # white; 
							}
							default {
								txtt <- active_display = COAST_DEF_DISPLAY ? "/m" : ""; 
								draw world.get_message('MSG_COST_ACTION') + " : " + explored_button.action_cost + txtt at: target2 + {30#px, 55#px} font: regular color: # white;
							}
						}
					}
				}
			}
			
			// Inspect LU info
			graphics "LU Info" transparency: 0.5 {
				if explored_lu != nil and (explored_land_use_action = nil or explored_land_use_action.is_applied) {
					point target  <- {explored_lu.location.x, explored_lu.location.y};
					point target2 <- {explored_lu.location.x + 1 * (INFORMATION_BOX_SIZE.x#px), explored_lu.location.y + 1 * (INFORMATION_BOX_SIZE.y#px + 40#px)};
					int xpx <- 15;
					draw rectangle(target,target2)  color: #black ;
					draw world.get_message('PLY_MSG_INFO_AB') + " : " + world.get_message('PLY_MSG_LAND_USE') at: target + {0#px, xpx#px}  font: regular color: # white;
					xpx <- xpx + 20;
					draw world.get_message('MSG_TYPE_' + explored_lu.lu_name) at: target + {30#px, xpx#px} font: regular color: # white;
					xpx <- xpx + 20;
					draw world.get_message('PLY_MSG_ALTITUDE') + " : " + string(round(100*explored_lu.mean_alt)/100) + "m" at: target + {30#px, xpx#px} font: regular color: # white;
					xpx <- xpx + 20;
					if explored_lu.lu_name in ["U","Us"]{
						draw world.get_message('MSG_POPULATION') + " : " + explored_lu.population at: target + {30#px, xpx#px} font: regular color: # white;
						xpx <- xpx + 20;
						draw world.get_message('MSG_EXPROPRIATION') + " : " + explored_lu.expro_cost at: target + {30#px, xpx#px} font: regular color: # white;
						xpx <- xpx + 20;
					}
					draw "ID : "+ string(explored_lu.id) at: target + {30#px, xpx#px} font: regular color: # white;
				}
			}
			
			// Inspect LU info when the action is not applied yet
			graphics "LU Action Info" transparency: 0.3 {
				if explored_land_use_action !=nil and !explored_land_use_action.is_applied {
					Land_Use mcell 	<- Land_Use first_with(each.id = explored_land_use_action.element_id);
					point target 	<- {mcell.location.x , mcell.location.y};
					point target2 	<- {mcell.location.x + 1 * (INFORMATION_BOX_SIZE.x#px), mcell.location.y + 1 * (INFORMATION_BOX_SIZE.y#px)};
					
					draw rectangle(target, target2) border: false color: #black;
					draw world.get_message('PLY_MSG_STATE_CHANGE') at: target + {0#px, 15#px} font: regular color: #white;
					draw file("../images/icons/fleche.png") at: {mcell.location.x + 0.5 * (INFORMATION_BOX_SIZE.x #px), target.y + 50#px} size:50#px;
					draw "" + (explored_land_use_action.effective_application_round) at: {mcell.location.x + 0.5 * (INFORMATION_BOX_SIZE.x#px), target.y + 50#px} size: 20#px;
					draw world.get_action_icon(explored_land_use_action.command) at: {target2.x - 50#px, target.y +50#px} size: 50#px;
					draw world.get_lu_icon(mcell) at: {target.x + 50#px, target.y + 50#px} size: 50#px;
				}
			}
			
			graphics "Lock Window" transparency: 0.3 {// lock user interface
				if(!is_active_gui){
					ask world{do lock_window;}
				}
			}			
			event mouse_down 	action: button_click_general;
			event mouse_move 	action: mouse_move_general;
		}
		// end of "Map" display
		display "Messages" background:#black {
			species Message_Left_Icon 		aspect: base;
			species Message_Console 		aspect: base;
			species Message_Element 		aspect: base;
			species List_of_Elements 		aspect: message;
			
			graphics "Lock Window" transparency: 0.3 {
				if(!is_active_gui){
					ask world{do lock_window;}
				}
			}
			event mouse_down action: move_down_event_console;
		}
		
		display "Basket" background:#black {
			species Basket 					aspect: base;
			species Basket_Element  		aspect: base;
			species List_of_Elements 		aspect: basket;
					
			graphics "Lock Window" transparency: 0.3 {
				if(!is_active_gui){
					ask world {do lock_window;}
				}
			}		
			event mouse_down action: move_down_event_basket;
		}
		
		display "History" background:#black {
			species History_Left_Icon aspect: base;
			species History 				   aspect: base;
			species History_Element   		   aspect: base;
			species List_of_Elements	 	   aspect: dossier;
				
			graphics "Lock Window" transparency: 0.3 {
				if(!is_active_gui){
					ask world{do lock_window;}
				}
			}
			event mouse_down action: move_down_event_dossier;
		}
 	}
}

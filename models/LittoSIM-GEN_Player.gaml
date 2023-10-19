/**
 *  LittoSIM_GEN
 *  Authors: Ahmed, Benoit, Brice, Cécilia, Elise, Etienne, Fredéric, Marion, Nicolas B, Nicolas M, Xavier 
 * 
 *  Description : LittoSIM_GEN is a participatory simulation platform implementing a serious playing-game for local authorities.
 * 				  The project aims at modeling effects of coastal flooding on urban areas and at enabling the transfer of scientific
 * 				  findings to risk managers, as well as awareness of those concerned by the risk of coastal flooding.
 * 
 * LittoSIM_GEN_Player : this module reprsents the game player.
 */
 
model Player

import "params_models/params_player.gaml"

global{
	// the active district
	string active_district_name <- "";
	string active_district_code <- dist_code_sname_correspondance_table index_of active_district_name;
	string active_district_lname <- dist_code_lname_correspondance_table at active_district_code;
	District active_district <- nil;
	
	int game_round <- 0;
	
	geometry shape <- envelope(convex_hull_shape); // shape of the world
	geometry local_shape <- nil; // shape of the current district 
	
	// GUI components
	bool is_active_gui 			<- true; // to boolean to disable user events when the game is paused
	string active_display 		<- LU_DISPLAY;
	point previous_clicked_point<- nil;
	float button_size 	<- 500#m;
	
	bool cursor_taken <- false; // to make the interface modal : prevent mouse click when a confirmation window (user_input) is open
	bool validate_clicked <- false; // prevent double click on validate button
	bool validate_allow_click <- true;
		
	// tax attributes
	int budget <- 0;
	int received_tax <- 0;
	float tax_unit  <- 0.0;
	
	int previous_population	<- 0;
	int current_population 	<- 0;
	geometry population_area <- nil; // to color the geometry of urban areas in CODEF tab
	
	list<Player_Action> my_basket <-[];
	list<Player_Action> my_history	<- [];
	Basket game_basket 			<-nil;
	Messages game_console<-nil;
	History game_history 		<- nil; 
	
	// managing clicks and mouse actions
	Button explored_button <- nil;
	Coastal_Defense explored_coast_def <- nil;
	Land_Use explored_lu <- nil;
	Land_Use hovered_lu <- nil;
	Flood_Mark explored_flood_mark <- nil;
	Land_Use_Action explored_land_use_action<- nil;
	Coastal_Defense_Action explored_coast_def_action<- nil;
	Player_Action highlighted_action<- nil;
	Player_Action current_action 	<- nil;
	
	font f0 <- font('Helvetica Neue', DISPLAY_FONT_SIZE - 4, #plain);
	font f1 <- font('Helvetica Neue', DISPLAY_FONT_SIZE, #bold);
	font regular <- font("Helvetica", 14, # bold);
	
	// to manage pebbles lever in the cliff_coast case study
	bool dieppe_pebbles_allowed <- false;
	float dieppe_pebbles_discount <- 1.0;
	
	
	// image for dike and dunes
	image_file dike_symbol_img <- image_file("../images/system_icons/player/gray_dike_symbol.png");
	image_file dune_symbol_img <- image_file("../images/system_icons/player/gray_dune_symbol.png");
	
	image_file bad_cord_symbol <- image_file("../images/system_icons/player/bad_cord_symbol.png");
	image_file medium_cord_symbol <- image_file("../images/system_icons/player/medium_cord_symbol.png");
	image_file normal_cord_symbol <- image_file("../images/system_icons/player/normal_cord_symbol.png");
	
	//icones for action trigger on land use
	file modif_land_cover_ui <- file("../images/system_icons/player/house.png");
	file modif_land_cover_ui_preload <- file("../images/system_icons/player/house_preload.png");
	file modif_land_cover_auNus <- file("../images/system_icons/player/trait.png");
	
	init{
		// reading repetitive messages to display in the interface
		MSG_WARNING 	<- get_message('MSG_WARNING');
		MSG_ROUND		<- get_message('MSG_ROUND');
		PLY_MSG_INFO_AB <- get_message('PLY_MSG_INFO_AB');
		PLY_MSG_LENGTH 	<- get_message('PLY_MSG_LENGTH');
		PLY_MSG_ALTITUDE<- get_message('PLY_MSG_ALTITUDE');
		PLY_MSG_HEIGHT 	<- get_message('PLY_MSG_HEIGHT');
		PLY_MSG_STATE 	<- get_message('PLY_MSG_STATE');
		PLY_MSG_SLICES 	<- get_message('PLY_MSG_SLICES');
		MSG_RUPTURE 	<- get_message('MSG_RUPTURE');
		MSG_BREACH	 	<- get_message('MSG_BREACH');
		MSG_NO 			<- get_message('MSG_NO');
		MSG_YES 		<- get_message('MSG_YES');
		MSG_DIKE 		<- get_message('MSG_DIKE');
		MSG_DUNE 		<- get_message('MSG_DUNE');
		MSG_CORD 		<- get_message('MSG_CORD');
		PLY_MSG_HIST_AB <- get_message('PLY_MSG_HIST_AB');
		PLY_MSG_LAND_USE<- get_message('PLY_MSG_LAND_USE');
		PLY_MSG_STATE_CHANGE <- get_message('PLY_MSG_STATE_CHANGE');
		MSG_POPULATION  <- get_message('MSG_POPULATION');
		MSG_EXPROPRIATION	 <- get_message('MSG_EXPROPRIATION');
		MSG_TYPE_N 		<- get_message('MSG_TYPE_N');
		MSG_TYPE_U 		<- get_message('MSG_TYPE_U');
		MSG_TYPE_AU 	<- get_message('MSG_TYPE_AU');
		MSG_TYPE_A 		<- get_message('MSG_TYPE_A');
		MSG_TYPE_Us 	<- get_message('MSG_TYPE_Us');
		MSG_TYPE_AUs 	<- get_message('MSG_TYPE_AUs');
		PLY_MSG_APP_ROUND<- get_message('PLY_MSG_APP_ROUND');
		MSG_COST_EXPROPRIATION <- get_message('MSG_COST_EXPROPRIATION');
		MSG_COST_ACTION <- get_message('MSG_COST_ACTION');
		PLY_MSG_GOOD <- get_message('PLY_MSG_GOOD');
		PLY_MSG_BAD <- get_message('PLY_MSG_BAD');
		PLY_MSG_MEDIUM <- get_message('PLY_MSG_MEDIUM');
		MSG_COST_APPLIED_PARCEL <- get_message('MSG_COST_APPLIED_PARCEL');
		PLY_MSG_WATER_H <- get_message('PLY_MSG_WATER_H');
		PLY_MSG_WATER_M <- get_message('PLY_MSG_WATER_M');
		MSG_YOUR_BUDGET <- get_message('MSG_YOUR_BUDGET');
		PLR_VALIDATE_BASKET <- get_message('PLR_VALIDATE_BASKET');
		PLR_CHECK_BOX_VALIDATE <- get_message('PLR_CHECK_BOX_VALIDATE');
		MSG_HAS_STARTED <- get_message('MSG_HAS_STARTED');
		MSG_DISTRICT_RECEIVE <- get_message('MSG_DISTRICT_RECEIVE');
		MSG_DISTRICT_LOSE <- get_message('MSG_DISTRICT_LOSE');
		MSG_NEW_COMERS <- get_message('MSG_NEW_COMERS');
		MSG_DISTRICT_POPULATION <- get_message('MSG_DISTRICT_POPULATION');
		MSG_INHABITANTS <- get_message('MSG_INHABITANTS');
		PLY_MSG_DOSSIER <- get_message('PLY_MSG_DOSSIER');
		MSG_ADAPTATION <- world.get_message('ACTION_MODIFY_LAND_COVER_Us');
		
		// creating districts and focusing on the active district
		create District from: districts_shape with:[district_code::string(read("dist_code"))]{
			district_name <- world.dist_code_sname_correspondance_table at district_code;
			district_long_name <- dist_code_lname_correspondance_table at district_code;
			district_id <- 1 + world.dist_code_sname_correspondance_table.keys index_of district_code;
		}
		active_district <- District first_with (each.district_code = active_district_code);
		local_shape 	<- envelope(active_district);
		tax_unit  		<- float(tax_unit_table at active_district_name); 
		
		// other components of the interface
		create History_Left_Icon {
			do lock_agent_at ui_location: {0.075,0.5} display_name: HISTORY_DISPLAY ui_width: 0.15 ui_height: 1.0;
		}
		create Message_Left_Icon {
			do lock_agent_at ui_location: {0.075,0.5} display_name: MESSAGES_DISPLAY ui_width: 0.15 ui_height: 1.0;
		}
		
		create Basket  	{game_basket  <- self;}
		create History	{game_history <- self;}
		create Messages {game_console <- self;}

		do create_tabs;		
		do create_buttons;	
			
		create Coastal_Defense from: coastal_defenses_shape with: [coast_def_id::int(read("ID")),type::string(read("type")),
			status::string(read("status")), alt::float(read("alt")), height::float(get("height")), district_code::string(read("dist_code"))]{
			if district_code = active_district_code {
				if type in [COAST_DEF_TYPE_DIKE, COAST_DEF_TYPE_DUNE, COAST_DEF_TYPE_CORD, COAST_DEF_TYPE_CHANEL, COAST_DEF_TYPE_VALVE]{
				//if type in [COAST_DEF_TYPE_DIKE] {
					do init_coastal_def;
				} else if type = WATER_GATE { // if the coastal defense is a port gate (cliff_coast/Normandie)
					create Water_Gate {
						id <- myself.coast_def_id;
						shape <- myself.shape;
					}
					do die;
				}
			} else {
				do die;
			}
		}
		
		create Flood_Risk_Area from: rpp_area_shape;
		create Protected_Area from: protected_areas_shape;
		create Road from: roads_shape;
		
		create Coastal_Border_Area from: coastline_shape {
			line_shape <- shape;
			shape <-  shape + coastBorderBuffer#m;
		}
		create Sea from: convex_hull_shape {
			shape <- shape - (union(District) + 200#m); // creating the see zone 
		}
		if file_exists(river_shape.path) {
			create River from: river_shape;
		}
		if file_exists(isolines_shape.path) {
			create Isoline from: isolines_shape;
		}
		
		create Land_Use from: land_use_shape with: [id::int(read("ID")), dist_code::string(read("dist_code")), lu_code::int(read("unit_code")), population::round(float(get("unit_pop")))]{
			if self.dist_code = active_district_code {
				lu_name <- lu_type_names [lu_code];
				if AU_AND_AUs_TO_N and lu_code in [LU_TYPE_AU, LU_TYPE_AUs] {  // if true, convert all AU and AUs to N
					lu_name <- "N";
					lu_code <- lu_type_names index_of lu_name;
				}
				my_color <- cell_color();
			} else { do die; }
		}
		population_area <- union(Land_Use where(each.lu_code = LU_TYPE_U or each.lu_code = LU_TYPE_AU));
		/*
		 * Create network agents
		 * The use of try/catch allows to start the model without ActiveMQ. An error message is displayed.
		 */
		try {
			create Network_Player;
			create Network_Listener_To_Leader;
		} catch {
			write "Error connecting to the server. This may be caused by:";
			write "   - Apache Active MQ is not running.";
			write "   - The server address is wrong.";
			write "Start ActiveMQ, check the servers address in littosim.conf, and then restart LittoSIM-GEN_Player.";
		}
	}
	//------------------------------ End of init -------------------------------//
	
	// these two actions are relevant in the cliff_coast only
	action close_or_open_dieppe_water_gate (bool close){ 
		ask first(Water_Gate where (each.id = 9999)) {
			display_me <- close;
		}
		map<string, string> mp <- ["REQUEST"::"WATER_GATE", "CLOSE"::close];
		ask Network_Player {
			do send to: GAME_MANAGER contents: mp;
		}
	}
	action close_or_open_dieppe_flood_gates (bool close){
		ask Water_Gate where (each.id != 9999) {
			display_me <- close;
		}
		map<string, string> mp <- ["REQUEST"::"FLOOD_GATES", "CLOSE"::close];
		ask Network_Player {
			do send to: GAME_MANAGER contents: mp;
		}
	}
	
	// pausing the game by locking interfaces of players
	action lock_window {
		geometry geom <- world.shape;
		point loc 	<- {geom.width/2, geom.height/2};
		geometry rec<- rectangle(geom.width, geom.height);
		draw rec at: loc color: #black;
		float msize <- min([geom.width/2, geom.height/2]);
		draw image_file("../images/system_icons/common/logo.png") at: loc size: {msize, msize};
	}
	
	// refreshing (reloading from the server) all agents
	user_command "Refresh All" {
		write "Refreshing all...";
		do refresh_all;
	}
	
	action refresh_all{
		game_history.elements <- [];
		ask Coastal_Defense { do die; }
		ask Player_Action   { do die; }
		ask History_Element { do die; }
		ask Land_Use        { do die; }
		map<string, string> mp <- ["REQUEST"::string(REFRESH_ALL)];
		ask Network_Player {
			do send to: GAME_MANAGER contents: mp;
		}
	}
	// information box to explore buttons
	point button_box_location (point my_button, int box_width){
		if my_button.x < first(Tab_Background).location.x + (first(Tab_Background).ui_width*0.55)  {
			return {my_button.x + box_width, my_button.y};
		}
		return my_button;
	}
	
	// create an ID for the new player action
	string get_action_id {
		list<int> ids1 <- Coastal_Defense_Action collect(id_number_of_action_id (each.id));
		list<int> ids2 <- Land_Use_Action 		 collect(id_number_of_action_id (each.id));
		return active_district_code + "_" + (max(ids1 + ids2) + 1);
	}
	int id_number_of_action_id (string act_id){
		return act_id = "" ? 0 : int ((act_id split_with "_")[1]);
	}
	
	image_file get_action_icon (int cmd){
		switch cmd {
			match ACTION_MODIFY_LAND_COVER_A 	{return image_file("../images/system_icons/player/agricultural.png"); 		}
			match ACTION_MODIFY_LAND_COVER_AU 	{return image_file("../images/system_icons/player/urban.png");				}
			match_one[ACTION_MODIFY_LAND_COVER_Us,
						ACTION_MODIFY_LAND_COVER_AUs]{return image_file("../images/system_icons/player/urban_adapted.png");	}
			match ACTION_MODIFY_LAND_COVER_Ui 	{return image_file("../images/system_icons/player/urban_dense.png");		}
			match ACTION_MODIFY_LAND_COVER_N 	{return image_file("../images/system_icons/player/natural.png");			}
			match ACTION_CREATE_DIKE 			{return image_file("../images/system_icons/player/dike_creation.png");		}
			match ACTION_REPAIR_DIKE 			{return image_file("../images/system_icons/player/dike_repair.png");		}
			match ACTION_RAISE_DIKE 			{return image_file("../images/system_icons/player/dike_raise.png");			}
			match ACTION_DESTROY_DIKE			{return image_file("../images/system_icons/player/dike_remove.png");		}
			match_one [ACTION_INSTALL_GANIVELLE,
					ACTION_ENHANCE_NATURAL_ACCR]{return image_file("../images/system_icons/player/ganivelle.png");			}
			match ACTION_CREATE_DUNE 			{return image_file("../images/system_icons/player/dune.png");				}
			match ACTION_MAINTAIN_DUNE			{return image_file("../images/system_icons/player/dune_maintain.png");		}
			match ACTION_LOAD_PEBBLES_CORD		{return image_file("../images/system_icons/player/pebbles.png");			}	
			match ACTION_SENSITIZE				{return image_file("../images/system_icons/player/icon_sensitize.png");		}			
			match ACTION_CREATE_CLAPET		    {return image_file("../images/system_icons/player/icon_open_close_clapet.png");	}			
			match ACTION_CLEAN					{return image_file("../images/system_icons/player/icon_clean.png");			}			
					
		}
		return nil;
	}
	
	image_file get_lu_icon (Land_Use lu){
		if lu.is_in_densification {
			return image_file("../images/system_icons/player/urban_dense.png");
		}
		switch lu.lu_code {
			match 1 { return image_file("../images/system_icons/player/natural.png");   			}
			match 5 { return image_file("../images/system_icons/player/agricultural.png");	 		}
			match_one [2,4] { return image_file("../images/system_icons/player/urban.png");	 		}
			match_one[6,7] { return image_file("../images/system_icons/player/urban_adapted.png"); 	}
		}
		return nil;
	}
	
	image_file get_flag_icon (int im) { // flooding marks icons. S_flagN.png is used for the Nth submersion
		switch im {
			match 0 {return image_file("../images/system_icons/player/flag0.png");  }
			match 1 {return image_file("../images/system_icons/player/flag1.png");  }
			match 2 {return image_file("../images/system_icons/player/flag2.png");  }
			match 3 {return image_file("../images/system_icons/player/flag3.png");  }
			match 4 {return image_file("../images/system_icons/player/flag4.png");  }
		}
		return nil;
	}
	
	// creating the two tabs : coastal defenses and land use management
	action create_tabs {
		float increment <- active_district_name = DISTRICT_AT_TOP ? 0.8 : 0.0;
		
		create Tab {
			point p 		<- {0.25, increment + 0.03};
			legend_name 	<- world.get_message('LEGEND_DYKE');
			display_name 	<- COAST_DEF_DISPLAY;
			do lock_agent_at ui_location: p display_name: MAP_DISPLAY ui_width: 0.5 ui_height: 0.06;
		}
		
		create Tab {
			point p 		<- {0.75,increment + 0.03};
			legend_name 	<- world.get_message('LEGEND_PLU');
			display_name 	<- LU_DISPLAY;
			do lock_agent_at ui_location: p display_name: MAP_DISPLAY ui_width: 0.5 ui_height: 0.06;
		}	
		
		create Tab_Background {
			point p <- {0.0, 0};
			do lock_agent_at ui_location: p display_name: MAP_DISPLAY ui_width: 1.0 ui_height: 1.0;
		}
	}
	// creating buttons on tabs
	action create_buttons {
		float increment <- active_district_name = DISTRICT_AT_TOP ? 0.8:0.0;
		string act_name;
		int lu_index;
		int codef_index;
		loop i from: 0 to: length(data_action) - 1 { // all player actions in the file actions.conf
			act_name <- data_action.keys[i];
			if (string(data_action at act_name at 'active') at (active_district.district_id-1)) = '1'{ // if the button is activated on this district
				// reading the corresponding index in the two tabs. If an action is a lu action, its index on lu tab will be its order of display.
				// And its index on the codef tab will be -1 (not displayed).
				lu_index <- int(data_action at act_name at 'lu_index') - 1;
				codef_index <- int(data_action at act_name at 'coast_def_index') - 1;
				if lu_index >= 0 {
					create Button {
						action_name  <- act_name; 
						display_name <- LU_DISPLAY;
						p <- {0.05 + (lu_index*0.1) - (lu_index*0.025), increment + 0.13};
					}
				} else if codef_index >= 0 {
					if(act_name in ['ACTION_CLOSE_OPEN_GATES','ACTION_CLOSE_OPEN_DIEPPE_GATE']){
						create Button_Map {
							action_name  <- act_name;
							display_name <- COAST_DEF_DISPLAY;
							location 	 <- {1000, 3000};
							p <- {0.05 + (codef_index*0.1) - (codef_index*0.025), increment + 0.13};
						}
					}else{
						create Button {
							action_name  <- act_name; 
							display_name <- COAST_DEF_DISPLAY;
							p <- {0.05 + (codef_index*0.1) - (codef_index*0.025), increment + 0.13};
						}
					}
					
				}	
			}
		}
		// shared buttons between the two tabs
		create Button {
			action_name  <- 'ACTION_INSPECT';
			display_name <- BOTH_DISPLAYS;
			p 			 <- {0.65, increment + 0.13};
		}
		create Button {
			action_name  <- 'ACTION_HISTORY';
			display_name <- BOTH_DISPLAYS;
			p 			 <- {0.725, increment + 0.13};
		}
		create Button_Map {
			action_name  <- 'ACTION_DISPLAY_FLOODING';
			display_name <- BOTH_DISPLAYS;
			location 	 <- {1000, 7000};
			p 			 <- {0.8, increment + 0.13};
		}
		create Button_Map {
			action_name  <- 'ACTION_DISPLAY_FLOODED_AREA';
			display_name <- BOTH_DISPLAYS;
			location 	 <- {1000,8000};
			p 			 <- {0.875, increment + 0.13};
		}
		create Button_Map {
			action_name  <- 'ACTION_DISPLAY_PROTECTED_AREA';
			display_name <- BOTH_DISPLAYS;
			location 	 <- {1000,9000};
			p 			 <- {0.95, increment + 0.13};
		}
		
		
		// locking buttons to the map display (
		ask Button + Button_Map	{
			do lock_agent_at ui_location: p display_name: MAP_DISPLAY ui_width: 0.1 ui_height: 0.1;
			do init_button;
		}
	}
	
	// a general mouse click
	action button_click_general {
		if cursor_taken   { return; } // if an action is waiting a confirmation (user_input) 
		if !is_active_gui { return; } // if the game is paused
		
		point loc <- #user_location;
		list<Tab> clicked_tab_button <- (Tab overlapping loc);
		if(length(clicked_tab_button) > 0){	// if a tab is clicked, go to the clicked tab
			active_display <- first(clicked_tab_button).display_name;
			do clear_selected_button; // unselect selected buttons
			explored_button 		 <- nil;
			explored_lu 	 		 <- nil;
			explored_coast_def 	 	 <- nil;
			explored_land_use_action <- nil;
			explored_coast_def_action<- nil;
			current_action 	 		 <- nil;
			explored_flood_mark		 <- nil;
		}
		else{ // the click was not on a tab, we redirect the event according to the active display (tab)
			if active_display = LU_DISPLAY {do button_click_lu; 	  }
			else						   {do button_click_coast_def;}	
		}	
	}
	
	// a click on a component of the LU tab
	action button_click_lu {
		point loc <- #user_location;	
		// getting the clicked button
		list<Button> clicked_lu_button <- (Button where (each overlaps loc and each.display_name != COAST_DEF_DISPLAY));
		if(length(clicked_lu_button) > 0){
			list<Button> current_active_button <- Button where (each.is_selected);
			do clear_selected_button;
			if length (current_active_button) = 0 or last(current_active_button).command != (first(clicked_lu_button)).command {
				ask first(clicked_lu_button) {
					if state = B_DEACTIVATED { return; } // if the button is disabled by the leader
					is_selected <- true;
				}
			}
		} else{	// the click is not on a lu action button
			if button_map_clicked (loc) = nil { // the click is not on a button map 
				do change_plu; // the click is on a lu object
			}
		}
	}
	
	action button_click_coast_def {
		point loc <- #user_location;
		// getting the clicked button
		Button clicked_coast_def_button <- first(Button where (each overlaps loc and each.display_name != LU_DISPLAY));
		if clicked_coast_def_button != nil {
			Button current_active_button <- first(Button where (each.is_selected));
			do clear_selected_button;
			if (current_active_button != nil and current_active_button.command != clicked_coast_def_button.command) or current_active_button = nil {
				ask clicked_coast_def_button {
					if state = B_DEACTIVATED { return; }
					is_selected <- true;
				}
			}	
			
		}
		else{
			if button_map_clicked (loc) = nil {	// the click is not on a button map
				do change_coast_def; // the click is on a coastal defense object
			}
		}
	}
	
	Button_Map button_map_clicked (point loc) { // getting the click map button
		Button_Map a_MAP_button <- first (Button_Map where (each overlaps loc));
		if a_MAP_button != nil {
			if(a_MAP_button.command in [ACTION_CLOSE_OPEN_GATES,ACTION_CLOSE_OPEN_DIEPPE_GATE]){
				a_MAP_button.is_selected <- ! a_MAP_button.is_selected;
				if a_MAP_button.command = ACTION_CLOSE_OPEN_GATES {
					do close_or_open_dieppe_flood_gates (a_MAP_button.is_selected);	
				} else {
					do close_or_open_dieppe_water_gate (a_MAP_button.is_selected);	
				}
			}
			ask a_MAP_button {
				switch command {
					match ACTION_DISPLAY_PROTECTED_AREA {my_icon <-  is_selected ? image_file("../images/developer_icons/act_display_protected.png") :  image_file("../images/developer_icons/act_hide_protected.png");}
					match ACTION_DISPLAY_FLOODED_AREA 	{my_icon <-  is_selected ? image_file("../images/developer_icons/act_hide_ppr.png") :  image_file("../images/developer_icons/act_display_ppr.png");}
					
					//for openning and closing gates
					match ACTION_CLOSE_OPEN_GATES 	{my_icon <-  is_selected ? image_file("../images/developer_icons/act_flow_gates_closed.png") :  image_file("../images/developer_icons/act_flow_gates_opened.png");}
					match ACTION_CLOSE_OPEN_DIEPPE_GATE	{my_icon <-  is_selected ? image_file("../images/developer_icons/act_port_gate_closed.png") :  image_file("../images/developer_icons/act_port_gate_opened.png");}
				}			
			}
			
		}
		return a_MAP_button;
	}
	
	action clear_selected_button {
		previous_clicked_point <- nil;
		ask Button {
			// unselect all buttons except the two buttons for opening/closing gates
			if !(command in [ACTION_CLOSE_OPEN_GATES, ACTION_CLOSE_OPEN_DIEPPE_GATE]) {
				self.is_selected <- false;	
			}
		}
	}

	action mouse_move_general {
		if !is_active_gui {// if the game is paused, no action on the moving mouse
			return;
		}
		switch active_display { // reorient the move depending on the active display
			match LU_DISPLAY  		{ do mouse_move_lu; }
			match COAST_DEF_DISPLAY { do mouse_move_coast_def; }
		}
	}
	
	action mouse_move_lu {
		point loc 		<- #user_location;
		explored_button <- (Button + Button_Map) first_with (each overlaps loc and each.display_name != COAST_DEF_DISPLAY); // if a button is being inspected
		
		// getting the selected button
		Button current_active_button <- first(Button where (!(each.command in [ACTION_CLOSE_OPEN_GATES, ACTION_CLOSE_OPEN_DIEPPE_GATE]) and each.is_selected));
		if current_active_button != nil  {
			if hovered_lu != nil {
				hovered_lu.focus_on_me <- false; // unframing the previous hovered lu cell
			}
			hovered_lu <- first(Land_Use overlapping loc);
			if hovered_lu != nil {
				hovered_lu.focus_on_me <- true; // framing the current hovered lu cell
			}
			// inspect/history lu cells
			if current_active_button.command in [ACTION_INSPECT, ACTION_HISTORY] { // if the selected button is inspect or history
				explored_lu <- first(Land_Use overlapping loc);
				if current_active_button.command = ACTION_INSPECT {
					explored_land_use_action <- first(Land_Use_Action overlapping loc);	// displaying lu cell info
				}
			} // another button is selected -> no exploration
			else{
				explored_land_use_action <- nil;
				explored_lu <- nil;
			}
		}
	}

	action mouse_move_coast_def {
		point loc <- #user_location;
		explored_button <- (Button + Button_Map) first_with (each overlaps loc and each.display_name != LU_DISPLAY); // for inspect
		
		// the selected button
		Button current_active_button <- first(Button where (!(each.command in [ACTION_CLOSE_OPEN_GATES, ACTION_CLOSE_OPEN_DIEPPE_GATE]) and each.is_selected));
		if current_active_button != nil and current_active_button.command in [ACTION_INSPECT, ACTION_HISTORY] { // inspect or history
			explored_coast_def <- first(Coastal_Defense overlapping (loc buffer(15#m))); // the mouse is on a coast def object
			if current_active_button.command = ACTION_INSPECT {
				explored_coast_def_action <- first(Coastal_Defense_Action overlapping (loc buffer(20#m)));
				explored_flood_mark <- first(Flood_Mark overlapping (loc buffer(20#m)));
			}
		}
		else{ // the selected button is codef action button
			explored_coast_def_action <- nil;
			explored_coast_def <- nil;
			explored_flood_mark <- nil;
		}
	}
	
	action change_coast_def {
		// Click codef
		point loc <- #user_location;
		Coastal_Defense selected_codef <- first(Coastal_Defense where ((20#m around each.shape) overlaps loc));
		Button selected_button <- Button first_with(each.is_selected);
		if selected_button != nil {
			if selected_button.command in [ACTION_INSPECT, ACTION_HISTORY] { // nothing to do
				return;
			}else if selected_button.command in [ACTION_CREATE_DIKE, ACTION_CREATE_DUNE, ACTION_CREATE_CLAPET] { // new codef object
				if basket_overflow() {return;} // the basket is full
				do create_new_codef(loc, selected_button);
			}else {
				if selected_codef = nil {return;}
				if basket_overflow() {return;}
				do modify_coast_def(selected_codef, selected_button); // action on an existing codef
			}
		}
	}
	
	action modify_coast_def (Coastal_Defense codef, Button but){
		if codef != nil{
			ask my_basket { // an action on the same dike is already in the basket. Two simultaneous actions on the same object are not allowed
				if codef.type in [COAST_DEF_TYPE_DIKE,COAST_DEF_TYPE_DUNE, COAST_DEF_TYPE_CHANEL] and element_id = codef.coast_def_id { return; } 
			}
			ask my_history where !each.is_applied { // a not applied action on the same dike is already in the history
				if codef.type in [COAST_DEF_TYPE_DIKE,COAST_DEF_TYPE_DUNE, COAST_DEF_TYPE_CHANEL] and element_id = codef.coast_def_id { return; } 
			}
			// if the action is on a pebble cord 
			if codef.type = COAST_DEF_TYPE_CORD and (codef.slices +
				length(my_basket where (each.action_type = PLAYER_ACTION_TYPE_COAST_DEF and each.element_id = codef.coast_def_id)) +
				length(my_history where (each.action_type = PLAYER_ACTION_TYPE_COAST_DEF and each.element_id = codef.coast_def_id and !each.is_applied))) = 10{
				cursor_taken <- true;
				map<string,unknown> vmap <- user_input(MSG_WARNING, world.get_message('PLY_PEBBLES_CORD')::true);
				cursor_taken <- false;						
				return;	 // the pebble cord has already the maximum number of slices (number of slices = 10)
			}
			if codef.type = COAST_DEF_TYPE_DUNE and !(but.command in
							[ACTION_INSTALL_GANIVELLE,ACTION_ENHANCE_NATURAL_ACCR,ACTION_MAINTAIN_DUNE]) {return;} // nothing to do
			if codef.type = COAST_DEF_TYPE_CORD and but.command != ACTION_LOAD_PEBBLES_CORD {return;} // nothing to do
			if codef.type = COAST_DEF_TYPE_DIKE and but.command in
							[ACTION_INSTALL_GANIVELLE, ACTION_LOAD_PEBBLES_CORD, ACTION_ENHANCE_NATURAL_ACCR, ACTION_MAINTAIN_DUNE] {return;} // nothing to do4
			
			if ((but.command = ACTION_CLEAN) xor (codef.type = COAST_DEF_TYPE_CHANEL)) { return;}
			
			// ACTION and TYPE -> XOR
			// clean		chanel		ok
			// clean		!chanel		no
			// !clean		chanel		no
			// !clean		!chanel		ok
			
			if but.command in [ACTION_RAISE_DIKE, ACTION_LOAD_PEBBLES_CORD, ACTION_ENHANCE_NATURAL_ACCR, ACTION_CLEAN] { // only these 3 actions can cause a delay, it's 4 now
				if !empty(Protected_Area where (each intersects codef.shape)){
					cursor_taken <- true;
					map<string,bool> vmap <- map<string,bool>(user_input(world.get_message('MSG_POSSIBLE_REGLEMENTATION_DELAY')::true)); // delay warning
					cursor_taken <- false;
					if (!(vmap at vmap.keys[0])) { return; }
				}	
			}
			
			do create_coastal_def_modify_action (codef, but);	// all is good, creating the action
		}
	}
	// creating a coastal defense action for modification of existing objects
	action create_coastal_def_modify_action (Coastal_Defense codef, Button mybut){
		int action_delay;
		create Coastal_Defense_Action returns: action_list{
			id 	<- world.get_action_id();
			self.label 	<- mybut.label;
			element_id 	<- codef.coast_def_id;
			self.command<- mybut.command;
			self.coast_def_type <- codef.type;
			element_shape <- codef.shape;
			shape <- element_shape + 15#m; // a buffer around the line to better visualize objects
			draw_around <- codef.draw_around;
			float price <- mybut.action_cost;
			if command = ACTION_LOAD_PEBBLES_CORD and dieppe_pebbles_allowed { // if sharing pebbles is allowed, discounting the cost
				price <- price * dieppe_pebbles_discount;
			}
			cost <- price * codef.length_coast_def;
			action_delay <- world.delay_of_action(self.command);
		}
		previous_clicked_point <- nil;
		current_action <- first(action_list);
		if mybut.command in [ACTION_RAISE_DIKE, ACTION_LOAD_PEBBLES_CORD, ACTION_ENHANCE_NATURAL_ACCR, ACTION_CLEAN] {
			if !empty(Protected_Area where (each intersects current_action.shape)){ // the action in protected areas
				current_action.is_in_protected_area <- true;
				// if dunes of the 2nd range are activated (Camargue/overflow_coast_h), the delay of enhancinf accretion is doubled
				if DUNES_TYPE2 and current_action.command = ACTION_ENHANCE_NATURAL_ACCR {
					action_delay <- action_delay * 2;
				}
			}
		}
		current_action.initial_application_round <- game_round  + action_delay;
		my_basket <- my_basket + current_action;
		ask game_basket  {
			do add_action_to_basket(current_action);
		}
	}
	// creating a new coastal defense object
	action create_new_codef (point loc, Button but){
		if previous_clicked_point = nil { // getting the first point
			if but.command = ACTION_CREATE_CLAPET {
				do create_new_coast_def_action (but, loc);
				// todo : limit the position to in duke
			}else{
				previous_clicked_point <- loc;
			}
		}
		else{ // the second point is clicked
			if !empty(Protected_Area overlapping (polyline([previous_clicked_point, loc]))){
				cursor_taken <- true;
				map<string,bool> vmap <- map<string,bool>(user_input(world.get_message('MSG_POSSIBLE_REGLEMENTATION_DELAY')::true));
				cursor_taken <- false;
				if (!(vmap at vmap.keys[0])) {
					do clear_selected_button;
					return;
				}
			}
			do create_new_coast_def_action (but, loc);
		}
	}
	// creating a coastal def action for new created objects
	action create_new_coast_def_action (Button mybut, point loc){
		int action_delay;
		create Coastal_Defense_Action returns: action_list {
			id 			<- world.get_action_id();
			self.label 	<- mybut.label;
			element_id 	<- -1;
			self.command<- mybut.command;
			self.coast_def_type <- command = ACTION_CREATE_DIKE ? COAST_DEF_TYPE_DIKE : COAST_DEF_TYPE_DUNE;
			if command = ACTION_CREATE_CLAPET {
				self.coast_def_type <-COAST_DEF_TYPE_VALVE;
				self.element_shape <- point(loc);
			}else{
				self.element_shape <- polyline([previous_clicked_point, loc]);
			}
			self.shape <- element_shape;
			float price <- mybut.action_cost;
			draw_around <- 15; // by default, a thin line = 15 for dikes 
			if coast_def_type = COAST_DEF_TYPE_DUNE { // if it's a dune, draw a thick line = 45
				draw_around <- 45;
				if DUNES_TYPE2 {// if 2nd range dunes are activated
					geometry my_line <- line (centroid(element_shape), (first(Sea).shape.points) closest_to (self));
					ask Coastal_Defense {
						if self overlaps my_line { // a codef intersect the line between the dune and the sea, so it's a dune of 2nd range
							myself.draw_around <- 30; // dune of second range : thinner line
							price <- price / 2; // half of cost
						}
					}
				}
			}
			self.cost <- price * shape.perimeter; // todo : verify price and height
			self.height <- coast_def_type = COAST_DEF_TYPE_DIKE ? BUILT_DIKE_HEIGHT : (draw_around = 45 ? BUILT_DUNE_TYPE1_HEIGHT : BUILT_DUNE_TYPE2_HEIGHT);
			action_delay <- world.delay_of_action(self.command);
			// requesting the server for the altitude of this future codef
			map<string,string> mp <- ["REQUEST"::NEW_COAST_DEF_ALT];
			point end <- last (element_shape.points);
			point origin <- first(element_shape.points);
			put string(origin.x) at: "origin.x" in: mp;
			put string(origin.y) at: "origin.y" in: mp;
			put string(end.x) 	 at: "end.x" in: mp;
			put string(end.y) 	 at: "end.y" in: mp;	
			put id at: "act_id" in: mp;
			put string(height) at: "height" in: mp;
			ask Network_Player{
				do send to: GAME_MANAGER contents: mp;
			}
		}
		previous_clicked_point <- nil;
		current_action<- first(action_list);
		if !empty(Protected_Area overlapping (current_action.shape)){
			current_action.is_in_protected_area <- true;
			if DUNES_TYPE2 and current_action.command = ACTION_CREATE_DUNE { // if in protected area for dunes 2, we double the delay
				action_delay <- action_delay * 2;
			}
		}
		current_action.initial_application_round <- game_round  + action_delay;
		my_basket <- my_basket + current_action; 
		ask game_basket {
			do add_action_to_basket(current_action);
		}	
		do clear_selected_button;
	}

	// modifying a land use cell
	action change_plu {
		point loc <- #user_location;
		Button selected_button <- Button first_with(each.is_selected);
		
		if selected_button != nil {
//			Click sur boutton
			Land_Use cell_tmp <- first(Land_Use where (each overlaps loc)); // the clicked lu cell
			if cell_tmp = nil {return;}
			if basket_overflow() {return;}
			ask cell_tmp {
				// inspect, history or gates buttons : do nothing
				if selected_button.command in [ACTION_INSPECT, ACTION_HISTORY, ACTION_CLOSE_OPEN_GATES, ACTION_CLOSE_OPEN_DIEPPE_GATE, ACTION_CLEAN, ACTION_CREATE_CLAPET] {return;}
				// the cell is already the selected action, do nothing
				if(		(lu_code = LU_TYPE_N 		   and selected_button.command = ACTION_MODIFY_LAND_COVER_N)
					 or (lu_code = LU_TYPE_A 		   and selected_button.command = ACTION_MODIFY_LAND_COVER_A)
					 or (lu_code in [LU_TYPE_U,LU_TYPE_AU] and selected_button.command = ACTION_MODIFY_LAND_COVER_AU)
					 or (lu_code in [LU_TYPE_AUs,LU_TYPE_Us] and selected_button.command = ACTION_MODIFY_LAND_COVER_AUs)
					 or (lu_code in [LU_TYPE_A,LU_TYPE_N,LU_TYPE_AU,LU_TYPE_AUs] and selected_button.command = ACTION_MODIFY_LAND_COVER_Ui)){
						return;
				}
				
				ask my_basket { // an action is already triggered on the same cell
					if element_id = myself.id { return; }
				}
				ask my_history where (!each.is_applied) { // a not applied action on the same cell is already in the history
					if element_id = myself.id { return; } 
				}
				
				if lu_code in [LU_TYPE_U,LU_TYPE_Us] { // urbanization or adaptation
					switch selected_button.command {
						match ACTION_MODIFY_LAND_COVER_A { // from A
							cursor_taken <- true;
							map<string,unknown> vmap <- user_input(MSG_WARNING, world.get_message('PLY_MSG_WARNING_U_N')::true);
							cursor_taken <- false;					
							return;	
						}
						match ACTION_MODIFY_LAND_COVER_N { // from N
							cursor_taken <- true;
							map<string,unknown> vmap <- user_input(MSG_WARNING, world.get_message('MSG_EXPROPRIATION_PROCEDURE')::false);
							cursor_taken <- false;
							if vmap at vmap.keys[0] = false {return;}
						}
						match ACTION_MODIFY_LAND_COVER_Ui { // densification
							if density_class = POP_DENSE {
								cursor_taken <- true;
								map<string,unknown> vmap <- user_input(MSG_WARNING, world.get_message('PLY_MSG_WARNING_DENSE')::true);
								cursor_taken <- false;
								return;	
							}
						}
					}
				}
				if lu_code in [LU_TYPE_AUs,LU_TYPE_Us] and selected_button.command = ACTION_MODIFY_LAND_COVER_AU {
					cursor_taken <- true;
					map<string,unknown> vmap <- user_input(MSG_WARNING, world.get_message('MSG_IMPOSSIBLE_DELETE_ADAPTED')::true);
					cursor_taken <- false;		
					return;
				}
				
				if lu_code in [LU_TYPE_A,LU_TYPE_N] and selected_button.command in [ACTION_MODIFY_LAND_COVER_AU, ACTION_MODIFY_LAND_COVER_AUs] {
					/*
					 * If an urban ring (neighborhood) is specified, then we cannot urbanize out of it
					 */
					if URBAN_RING != 0 {
						if empty(Land_Use at_distance URBAN_RING where (each.is_urban_type)){
							cursor_taken <- true;
							map<string,unknown> vmap <- user_input(MSG_WARNING, world.get_message('PLY_MSG_WARNING_OUTSIDE_U')::true);
							cursor_taken <- false;
							return;
						}	
					}
					/*
					 * Cannot urbanize in protected areas
					 */		
					if NO_URBANIZING_SPA and !empty(Protected_Area where (each intersects (circle(10, shape.centroid)))) {
						cursor_taken <- true;
						map<string,unknown> vmap <- user_input(MSG_WARNING, world.get_message('PLY_MSG_WARNING_PROTECTED_U')::true);
						cursor_taken <- false;
						return;
					}
					if lu_code = LU_TYPE_N {
						cursor_taken <- true;
						map<string,unknown> vmap <- user_input(MSG_WARNING, world.get_message('PLY_MSG_WARNING_N_TO_URBANIZED')::false);
						cursor_taken <- false;		
						if vmap at vmap.keys[0] = false {return;}
					}
				}
				ask world {
					do create_land_use_action (myself, selected_button);
				}
			}
		}
	}
	
	action create_land_use_action (Land_Use mylu, Button mybut) {
		create Land_Use_Action returns: actions_list {
			id 				<- world.get_action_id();
			element_id 		<- mylu.id;
			command 		<- mybut.command;
			element_shape 	<- mylu.shape;
			shape 			<- element_shape;
			previous_lu_name<- mylu.lu_name;
			label 			<- mybut.label;
			// the cost is proportional to the lu area
			cost 			<- mybut.action_cost * element_shape.area / STANDARD_LU_AREA;
			initial_application_round <- game_round  + world.delay_of_action(command);
			
			if command = ACTION_MODIFY_LAND_COVER_N {
				if previous_lu_name in ["U","Us"] { // if it's expropriation
					initial_application_round <- game_round + world.delay_of_action(ACTION_EXPROPRIATION);
					cost <- float(mylu.expro_cost) * element_shape.area / STANDARD_LU_AREA;
					is_expropriation <- true;
					label <- world.get_message("MSG_EXPROPRIATION");
				}
				else if previous_lu_name = "A" { // if it's A to N
					cost <- world.cost_of_action ('ACTON_MODIFY_LAND_COVER_FROM_A_TO_N') * element_shape.area / STANDARD_LU_AREA;
					// if its Camargue/overflow_coast_h and the LU is not yet flooded twice
					if DUNES_TYPE2 and mylu.flooded_times < 2 {
						// if the LU is not in a protected area, and not in risk, and not in coast
						if empty(Protected_Area where (each intersects (circle(10, shape.centroid))))
							and empty(Flood_Risk_Area where (each intersects (circle(10, shape.centroid))))
								and empty(Coastal_Border_Area where (each intersects (circle(10, shape.centroid)))){
							// we double cost and delay
							cost <- cost * 2;
							initial_application_round <- game_round  + (world.delay_of_action(command) * 2);	
						}
					}
				}
			} 
			else if command = ACTION_MODIFY_LAND_COVER_AUs {
				if previous_lu_name = "U" { // if adapting an urbanized cell
					command <- ACTION_MODIFY_LAND_COVER_Us;
					label <- MSG_ADAPTATION;
					cost <- element_shape.area / STANDARD_LU_AREA * world.cost_of_action('ACTION_MODIFY_LAND_COVER_Us');	
				}
			}
			mylu.my_cols[0] <- mylu.my_color;
		}
		current_action  <- first(actions_list);
		my_basket 		<- my_basket + current_action; 
		ask game_basket {
			do add_action_to_basket(current_action);
		}	
	}
	 // the basket is on its maximum size
	bool basket_overflow {
		if length(my_basket) = BASKET_MAX_SIZE {
			cursor_taken <- true;
			map vmap <- user_input(MSG_WARNING, world.get_message('PLR_OVERFLOW_WARNING')::true);
			cursor_taken <- false;
			return true;
		}
		return false;
	}
	// general mouse events
	action move_down_event_basket{
		if !is_active_gui {
			return;
		}
		ask Basket {
			do move_down_event;
		}
	}
	
	action move_down_event_history{
		if !is_active_gui {
			return;
		}
		ask History {
			do move_down_event;
		}
	}
	
	action move_down_event_messages{
		if !is_active_gui {
			return;
		}
		ask Messages {
			do move_down_event;
		}
	}
	// printing a message to the game console
	action user_msg (string msg, string type_msg) {
		ask game_console{
			do write_message(msg, type_msg);
		}
	}
	// adding a dot (.) to number as a thousands separator
	string thousands_separator (int a_value){
		string txt <- "" + a_value;
		bool separate1000 <- a_value >= 0 ? length(txt) > 3 : length(txt) > 4;
		if separate1000 {
			txt <- copy_between(txt, 0, length(txt) -3) + "." + copy_between(txt, length(txt) - 3, length(txt));
		}
		return txt;
	}
}
//------------------------------ End of global -------------------------------//

// one list item of basket/messages or history (one player_action element, one message element, or one history element) 
species List_Element skills: [UI_location] {
	int font_size 	<- DISPLAY_FONT_SIZE - 4;
	string label 	<- "";
	Displayed_List my_parent;
	bool is_displayed;
	int display_index;
	image_file icon <- nil;
	geometry my_line;
	geometry my_rect;
	
	reflex update{
		 my_line <- polyline([{0,0}, {ui_width,0}]);		
		 my_rect  <- polygon([{0,0}, {0,ui_height}, {ui_width,ui_height},{ui_width,0},{0,0}]);
		do refresh_me;
	}
	// drawing an item
	action draw_item {
		draw my_rect   at: {location.x, location.y} color: rgb(233,233,233);
		draw my_line  at: {location.x, location.y + ui_height / 2} color: #black;
		draw label at: {location.x - ui_width / 2 + 2 * ui_height, location.y + (font_size/ 2) #px} font: font('Helvetica Neue', font_size, #bold) color: #black;
		if icon != nil {
			draw icon at: {location.x - ui_width / 2 + ui_height, location.y} size: {ui_height * 0.8, ui_height * 0.8};
		}
	}
	// move action when an item is clicked
	action move_down_event{
		point loc <- #user_location;
		if self overlaps loc and is_displayed {
			do on_mouse_down;
		}
	}
	
	action on_mouse_down;
	action draw_element;
	
	aspect base{
		if is_displayed{
			do draw_item;
			do draw_element;
		}
	}
}
//------------------------------ End of Displayed_List_Element -------------------------------//

species Message_Element parent: List_Element{
	int font_size 	<- DISPLAY_FONT_SIZE - 2; // bigger font size than the generic List_Llement
}

//------------------------------ End of Message_Element -------------------------------//

species History_Element parent: List_Element {
	int font_size <- 12;
	int addelay -> {current_action.added_delay};
	float final_price   -> {current_action.actual_cost};
	float initial_price -> {current_action.cost};
	point bullet_size   <- point(0,0) update: {ui_height*0.6, ui_height*0.6};

	point delay_location <- point(0,0) update: {location.x + ui_width / 4 + 350#px, location.y}; // display delay
	point round_apply_location<- point(0,0)	update: {location.x + ui_width / 5 + 200#px, location.y}; // display round of app
	point price_location <- point(0,0) update: {location.x + ui_width / 3 + 400#px, location.y}; // display the cost
	
	Player_Action current_action;
	
	rgb std_color <- rgb(87,87,87);
	
	// highlight a non applied action when it is clicked in history
	action on_mouse_down {
		highlighted_action <-  highlighted_action = current_action ? nil : (current_action.is_applied ? nil : current_action);
	}
	
	action draw_element{
		// temporal variable is mandatory to correctly display the price ! displaying "final_price" directly doesn't work !!
		int prix <- int(final_price);
		font font1 <- font ('Helvetica Neue', font_size, #italic); 
		if !current_action.is_applied {
			if addelay != 0 { // display the added delay by a lever
				int ddl <- addelay;
				draw circle(bullet_size.x / 2) at: delay_location color: addelay < 0 ? #green : #red;
				draw ""  + ddl at: delay_location anchor:#center color: #white font: font1;
			}
			// the display the remaining delay to apply the action
			draw circle(bullet_size.x / 2) at: round_apply_location color: std_color;
			draw "" + current_action.nb_rounds_before_activation_and_waiting_for_lever_to_activate() at: round_apply_location anchor: #center color: #white font: font1;
		}
		else { // if the action is validated
			draw file("../images/system_icons/player/validate.png") at: round_apply_location size: bullet_size color: std_color;
		}
		// display the fination cost of the action
		rgb mc <- final_price = initial_price ? std_color : (final_price > initial_price ? #red : #green);
		draw "" + prix at: price_location anchor: #center color: mc font: font1;
		
		// draw a red rectangle around the clicked action
		if highlighted_action = current_action {
			geometry recx <- polygon([{0,0}, {0,ui_height}, {ui_width,ui_height}, {ui_width,0}, {0,0}]);
			draw recx at: {location.x, location.y} empty: true border: #red;
		}
	}
} 
//------------------------------ End of History_Element -------------------------------//

species Basket_Element parent: List_Element {
	int font_size 			<- 12;
	point button_size 		<- point(0,0) update: {ui_height * 0.6, ui_height * 0.6};
	point button_location 	<- point(0,0) update: {location.x + ui_width / 2 - (button_size.x), location.y};
	Player_Action current_action <- nil;
	image_file close_button <- file("../images/system_icons/player/close.png"); // delete the action button
	
	point bullet_size 			<- point(0,0) update: {ui_height*0.6, ui_height*0.6};
	point round_apply_location  <- point(0,0) update: {location.x + 1.3 * ui_width / 5, location.y};
	
	
	// highlight or delete an action when it is clicked
	action on_mouse_down {
		if button_location distance_to #user_location <= button_size.x {// Player wants to delete an action from the basket
			highlighted_action <- nil;
			do remove_action;
		} else {
			highlighted_action <-  highlighted_action = current_action  ? nil : current_action;
		}
	}
	
	// delete an action from the basket
	action remove_action{
		ask my_parent{
			do remove_element(myself);
		}
		remove current_action from: my_basket;
		ask current_action {
			do die;
		}
		ask my_parent {
			if length(elements) > max_size {
				do go_up;	
			}
		}
		validate_allow_click <- false;
		do die;
	}
	
	action draw_element{
		draw close_button at: button_location size: button_size ;
		font font1 <- font ('Helvetica Neue', font_size, #bold ); 
		
		draw "" + world.thousands_separator(int(current_action.cost))  at: {round(button_location.x) - 50#px, round(button_location.y) + (font_size/ 2)#px}  color: #black font: font1;
		draw circle(bullet_size.x / 2) at: round_apply_location color: rgb(87,87,87);
		draw "" + (current_action.initial_application_round - game_round) at: {round(round_apply_location.x) - (font_size / 6)#px , round(round_apply_location.y) + (font_size / 3)#px} color: #white font: font1;
	
		if location != nil and highlighted_action = current_action {
			geometry recx <- polygon([{0, 0}, {0, ui_height}, {ui_width, ui_height}, {ui_width, 0},{0, 0}]);
			draw recx at: {location.x, location.y} empty: true border: #red;
		}
	}
}
//------------------------------ End of Basket_Element -------------------------------//

// the list of elements used by the basket, the history, or the messages console
species List_of_Elements parent: List_Element {
	int direction <- 0;
	
	// to move up or down the list
	bool move_down_event{
		point loc <- #user_location;
		if ! (self.my_rect overlaps loc){
			return false;
		}
		switch direction {
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
	
	aspect asp_history {
		if is_displayed and my_parent.display_name = HISTORY_DISPLAY {
			do draw_item;
			do draw_element;
		}
	}
	
	aspect asp_basket {
		if is_displayed and my_parent.display_name = BASKET_DISPLAY {
			do draw_item;
			do draw_element;
		}
	}
	
	aspect asp_messages {
		if is_displayed and my_parent.display_name = MESSAGES_DISPLAY {
			do draw_item;
			do draw_element;
		}
	}	
}
//------------------------------ End of System_List_Element -------------------------------//

// the displayed list (basket/messages/history) in the interface with graphical components
species Displayed_List skills: [UI_location] {
	int max_size 	<- 7;
	int font_size 	<- 12;
	float header_height 	<- 0.2;
	float element_height 	<- 0.08;
	string legend_name 		<- "";
	int start_index 		<- 0;
	list<List_Element> elements <- [];
	List_of_Elements up_item 	<- nil;
	List_of_Elements down_item 	<- nil;
	string display_name <- "";
	bool show_header 	<- true;
	float gem_height <- 0.0 update: ui_height * header_height / 2;
	float gem_width  <- 0.0 update: ui_width;
		
	reflex update{
		shape <- rectangle(gem_width, gem_height);
		do refresh_me;
	}
	
	action move_down_event {
		if up_item.is_displayed {
			ask up_item   { do move_down_event; }
			ask down_item { do move_down_event; }
		}
		ask elements where each.is_displayed {
			do move_down_event;
		}
		do on_mouse_down;
	}
	
	action on_mouse_down;
	
	// adding a new item to the list
	action add_item (List_Element list_elem){
		int index 	<- length(elements);
		elements 	<- elements + list_elem;
		point p 	<- get_location(index);
		ask list_elem {
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
			if i >= idx and i < idx + max_size - 2{
				point p <- get_location(j);
				j <- j + 1;
				ask elem {
					do move_agent_at ui_location: p;
					is_displayed <- true;
				}
			}
			else { elem.is_displayed <- false; }	
			i <- i+1;
		}
	}
	
	// creating "<< previous" and "next >>" navigation items
	action create_navigation_items {
		create List_of_Elements {
			label 	<- "<< " + world.get_message('PLY_MSG_PREVIOUS');
			point p <- myself.get_location(0);
			do lock_agent_at ui_location: p display_name: myself.display_name ui_width: myself.locked_ui_width ui_height: myself.element_height;
			myself.up_item 		<- self;
			self.is_displayed 	<- false;
			direction 			<- 1;
			my_parent 			<- myself;
		}
		create List_of_Elements {
			label 	<- "                 "+ world.get_message('PLY_MSG_NEXT') +" >>";
			point p <- myself.get_location(myself.max_size - 1);
			do lock_agent_at ui_location: p display_name: myself.display_name ui_width: myself.locked_ui_width ui_height: myself.element_height;
			myself.down_item 	<- self;
			self.is_displayed 	<- false;
			direction 			<- 2;
			my_parent 			<- myself;
		}
	}
	
	// the list goes up when we click "next >>"
	action go_up {
		start_index <- min([length(elements) - max_size + 2, start_index + 1]);	
		do change_start_index(start_index);
	}
	// the list goes down when we click "<< previous"
	action go_down {
		start_index <- max([0, start_index - 1]);	
		do change_start_index(start_index);	
	}
	
	// remove all elements of the list (when we send the basket)
	action remove_all_elements {
		ask elements {
			do die;
		}
		elements <- [];
		up_item.is_displayed 	<- false;
		down_item.is_displayed 	<- false;
	}
	// remove one element from the list : when we delete an action from the basket
	action remove_element (List_Element el){
		remove el from: elements;
		if(length(elements) <= max_size) {
			int i 		<- 0;
			start_index <- 0;
			loop elem over: elements{
				point p <- get_location(i);
				i <- i + 1;
				ask elem {
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
	
	aspect base {
		do draw_list;
	}
	
	action draw_list{
		draw polygon([{0, 0}, {0, ui_height}, {ui_width, ui_height}, {ui_width, 0}, {0, 0}]) at: {location.x + ui_width / 2, location.y + ui_height / 2} color: #white;
		if show_header {
			do draw_my_header;
		}
	}
	
	action draw_my_header {
		geometry rec2 	<- polygon([{0,0}, {0,ui_height*header_height}, {ui_width,ui_height*header_height}, {ui_width,0}, {0,0}]);
		point loc2  	<- {location.x + ui_width / 2, location.y + ui_height * header_height / 2};
		draw  rec2 at: loc2 color: rgb(219,219,219);
		
		float x <- location.x;
		float y <- location.y;
		
		geometry rec3 <- polygon([{x,y}, {x,y+gem_height}, {x+gem_width*0.2,y+gem_height}, {x+gem_width*0.25,y+gem_height*1.2}, {x+gem_width*0.3,y+gem_height}, {x+gem_width,y+gem_height}, {x+gem_width,y}, {x,y}]);
		draw rec3 color: rgb(59,124,58);
		draw legend_name at: {location.x + gem_width /2 - (length(legend_name)*6#px/ 2), location.y + gem_height/2 + 4#px} color: #white font: f1;
	}
}
//------------------------------ End of Displayed_List -------------------------------//

species Basket parent: Displayed_List {
	string display_name <- BASKET_DISPLAY;
	int budget 		   -> {world.budget};
	float final_budget -> {world.budget - sum(elements collect((Basket_Element(each).current_action).actual_cost))};
	string init_budget_label;
	string solde_label;
	string district_label;
	string round_label;
	string validate_label;
	
	point validation_button_size <- {0, 0};
	
	init{
		legend_name <- world.get_message('LEGEND_NAME_ACTIONS');
		do lock_agent_at ui_location: {0.0, 0.0} display_name: display_name ui_width: 1.0 ui_height: 1.0 ;
		do create_navigation_items;
		init_budget_label <- world.get_message('MSG_INITIAL_BUDGET');
		solde_label <- world.get_message('MSG_SOLDE');
		district_label <- world.get_message('MSG_COMMUNE');
		round_label <- world.get_message('MSG_ROUND');
		validate_label <- world.get_message('PLY_MSG_VALIDATE');
	}
	
	action add_action_to_basket (Player_Action act){
	  	create Basket_Element returns: elem {
			label <- act.label;
			if act.is_applied or !(act.command in [ACTION_CREATE_DIKE, ACTION_CREATE_DUNE]) {
				label <- label + " (" + act.element_id +")";	
			}
			if act.command = ACTION_CREATE_DUNE and act.draw_around = 30{
				label <- label + " " + world.get_message('MSG_2ND_RANG');
			}
			icon <- world.get_action_icon (act.command);
			current_action <- act;
		}
		do add_item(first(elem));
	}
	
	action draw_budget {
		gem_height <- ui_height * header_height / 2;
		gem_width  <- ui_width;
		int mfont_size	 <- DISPLAY_FONT_SIZE - 2;
		draw init_budget_label font: f0 color: rgb(101,101,101) at: {location.x + ui_width - 170#px, location.y + ui_height * 0.15 + (mfont_size / 2)#px};
		draw " : " + world.thousands_separator(budget) font: f1 color: rgb(101,101,101)
						at: {location.x + ui_width - 100#px, location.y + ui_height * 0.15 + (mfont_size / 2)#px};
	}
	
	action draw_foot {
		draw polygon([{0,0}, {0,0.1*ui_height}, {ui_width,header_height/2*ui_height}, {ui_width,0}, {0,0}]) 
				at: {location.x + ui_width / 2, location.y + ui_height- header_height / 4 * ui_height} color: rgb(219,219,219);
		
		draw district_label + " : " font: f0 color: rgb(101,101,101) at: {location.x + 10#px, location.y+ui_height-ui_height*header_height/4 - 0.25 #px};
		draw active_district_lname font: f1 color:#black at: {location.x + 80#px,location.y+ui_height-ui_height*header_height/4 - 0.25 #px};
		
		draw round_label + " : " font: f0 color: rgb(101,101,101) at: {location.x + ui_width/2, location.y+ui_height-ui_height*header_height/4 - 0.25 #px};
		draw "" + game_round font: f1 color: #black at: {location.x + ui_width/2 + 50#px, location.y+ui_height-ui_height*header_height/4 - 0.25 #px};
		
		draw solde_label + " : " font: f0 color: rgb(101,101,101) at: {location.x + ui_width - 100#px, location.y+ui_height-ui_height*header_height/4 - 0.25 #px};
		draw world.thousands_separator(int(final_budget)) font: f1 color:#black
						at: {location.x + ui_width - 55#px,location.y+ui_height-ui_height*header_height/4 - 0.25 #px};
	}
	
	point validation_button_location (float msz){
		int index <- min([length(elements), max_size]) ;
		float mx <- first(Basket collect(each.location.x)) + ui_width - 20#px;
		float sz 	<- element_height * ui_height;
		point p 	<- {mx, location.y + (index * sz) + (header_height * ui_height) + (0.75 * element_height * ui_height)};
		return p;
	}
	
	action draw_validate_button {
		float sz 		 <- element_height*ui_height;
		validation_button_size <- {sz * 0.8, sz * 0.8};
		point pt 		 <- validation_button_location(validation_button_size.x);
		image_file icone <- file("../images/system_icons/player/validate.png");
		draw icone at: pt size: validation_button_size;
		
		int mfont <- DISPLAY_FONT_SIZE - 2;
		font font1 <- font ('Helvetica Neue', mfont, #plain ); 
		draw validate_label at: {location.x + ui_width - 140#px, pt.y + ((DISPLAY_FONT_SIZE - 4) / 2)#px} size: {sz*0.8, sz*0.8} font: f0 color: #black;
		draw " " + world.thousands_separator(int(budget - final_budget)) at: {location.x + ui_width - 90#px, pt.y + (mfont / 2)#px} size: {sz*0.8, sz*0.8} font: font1 color: #black;
	}
	
	action on_mouse_down {
		if !validate_allow_click {
			validate_allow_click <- true;
			return;
		}
		if !validate_clicked and validation_button_location(validation_button_size.x) distance_to #user_location < validation_button_size.x +100#px {
			validate_clicked <- true;
			if game_round = 0 {
				cursor_taken <- true;
				map<string,unknown> res <- user_input(MSG_WARNING, world.get_message('MSG_SIM_NOT_STARTED')::true);
				cursor_taken <- false;
				validate_clicked <- false;
				return;
			}
			if empty(game_basket.elements){
				string msg <- world.get_message('PLR_EMPTY_BASKET');
				cursor_taken <- true;
				map<string,unknown> res <- user_input(MSG_WARNING, msg::true);
				cursor_taken <- false;
				validate_clicked <- false;
				return;
			}
			if(budget - round(sum(my_basket collect(each.cost))) < PLAYER_MINIMAL_BUDGET){
				string budget_display <- world.get_message('PLR_INSUFFICIENT_BUDGET');
				ask world {
					do user_msg (budget_display,INFORMATION_MESSAGE);
				}
				cursor_taken <- true;
				map<string,unknown> res <- user_input(MSG_WARNING, budget_display::true);
				cursor_taken <- false;
				validate_clicked <- false;
				return;
			}
			cursor_taken <- true;
			map<string,bool> vmap <- map<string,bool>(user_input(MSG_WARNING, PLR_VALIDATE_BASKET + "\n" + PLR_CHECK_BOX_VALIDATE::false));
			cursor_taken <- false;
			validate_clicked <- false;
			if(vmap at vmap.keys[0]){
				ask Network_Player{
					do send_basket;
				}
			}
		}
	}
	
	aspect base{
		do draw_list;
		do draw_validate_button;
		do draw_budget;
		do draw_foot;
	}
}
//------------------------------ End of Basket -------------------------------//

species History parent: Displayed_List {
	init{
		max_size 	<- 12;
		show_header <- false;
		display_name<- HISTORY_DISPLAY;
		do lock_agent_at ui_location: {0.15,0.0} display_name: display_name ui_width: 0.85 ui_height: 1.0 ;
		do create_navigation_items;
	}
	
	action add_action_to_history(Player_Action act){
		add act to: my_history;
	  	create History_Element returns: elem {
			label <- act.label;
			if act.is_applied or !(act.command in [ACTION_CREATE_DIKE, ACTION_CREATE_DUNE]) {
				label <- label + " (" + act.element_id +")";	
			}
			if act.command = ACTION_CREATE_DUNE and act.draw_around = 30{
				label <- label + " " + world.get_message('MSG_2ND_RANG');
			}
			icon <- world.get_action_icon(act.command);
			act.my_hist_elem <- self;
			current_action <- act;
		}
		
		do add_item(first(elem));
		// add action to the historical display on the map (when we click history button)
		if act.action_type = PLAYER_ACTION_TYPE_COAST_DEF {
			Coastal_Defense cd <- first(Coastal_Defense where (each.coast_def_id = act.element_id));
			if cd != nil {
				add act to: cd.actions_on_me;
				cd.actions_on_me <- cd.actions_on_me sort_by (each.initial_application_round);
			}
		} else {
			ask first(Land_Use where (each.id = act.element_id)) {
				add act to: actions_on_me;
				actions_on_me <- actions_on_me sort_by (each.initial_application_round);
			}
			
		}
	}
} 
//------------------------------ End of History -------------------------------//

species Messages parent: Displayed_List { //schedules:[]{
	init{
		font_size 	<- 11;
		max_size 	<- 12;
		show_header <- false;
		display_name<- MESSAGES_DISPLAY;
		do lock_agent_at ui_location: {0.15,0.0} display_name: display_name ui_width: 0.85 ui_height: 1.0;
		do create_navigation_items;
	}
	
	image_file get_message_icon(string message_type){
		switch(message_type){
			match INFORMATION_MESSAGE {return file("../images/system_icons/player/quote.png");}
			match POPULATION_MESSAGE  {return file("../images/system_icons/player/population.png");}
			match BUDGET_MESSAGE 	  {return file("../images/system_icons/player/BY.png");}
		}
		return file("../images/system_icons/player/quote.png");
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
	image_file directory_icon <- file("../images/system_icons/player/dossier.png");
	float lui_width <- 0.0 update: ui_width;
	float lui_height <- 0.0 update: ui_height;
	
	reflex update{
		do refresh_me;
	}
	
	aspect base{
		geometry rec <- polygon([{0,0}, {0,lui_height}, {lui_width,lui_height}, {lui_width,0}, {0,0}]);
		draw rec color: rgb(59, 124, 58) at: location;
		draw directory_icon at: {location.x, location.y - lui_height / 4} size: {0.7 * lui_width, 0.7 * ui_width};
	}
}
//------------------------------ End of History_Left_Icon -------------------------------//

species Message_Left_Icon parent: History_Left_Icon {
	image_file directory_icon <- file("../images/system_icons/player/quote.png");
}
//------------------------------ End of Message_Left_Icon -------------------------------//

// activated levers by leader
species Activated_Lever {
	Player_Action ply_act;
	map<string, string> my_map <- []; // contains attributes sent through network
	
	action init_activ_lever_from_map(map<string, string> m ){
		my_map <- m;
		put OBJECT_TYPE_ACTIVATED_LEVER at: "OBJECT_TYPE" in: my_map;
	}
}
//------------------------------ End of Activated_Lever -------------------------------//

// receives messages and financial transactions from the leader
species Network_Listener_To_Leader skills: [network] {
	
	init{ do connect to: SERVER with_name: LISTENER_TO_LEADER; }
	
	reflex wait_message {
		loop while: has_more_message(){
			message msg <- fetch_message();
			map<string, unknown> m_contents <- msg.contents;
			if m_contents['TARGET_DIST'] = active_district_code { // I am a target of money transfer
				int amount 	<- int(m_contents[AMOUNT]);
				string sender_dist <- (District first_with(each.district_code = m_contents[DISTRICT_CODE])).district_name;
				budget 	<- budget + amount;
				ask world {
					do user_msg(get_message('LDR_TRANSFERT4') + " : " + sender_dist + " ("+ amount + ' By)', BUDGET_MESSAGE);
				}
			}
			else if m_contents[DISTRICT_CODE] = active_district_code {
				switch m_contents[LEADER_COMMAND] {
					match EXCHANGE_MONEY { // I will make a money transfer to another district
						int amount 	<- int(m_contents[AMOUNT]);
						string target_dist <- (District first_with(each.district_code = m_contents['TARGET_DIST'])).district_name;
						budget 		<- budget - amount;
						ask world {
							do user_msg(string(m_contents[MSG_TO_PLAYER]) + " : " + target_dist + " ("+ amount + ' By)', BUDGET_MESSAGE);
						}
						
					}
					match GIVE_MONEY_TO {
						int amount 	<- int(m_contents[AMOUNT]);
						budget 		<- budget + amount;
						ask world {
							do user_msg(string(m_contents[MSG_TO_PLAYER]) + " : " + amount + ' By', BUDGET_MESSAGE);
						}
					}
					match TAKE_MONEY_FROM {
						int amount 	<- int(m_contents[AMOUNT]);
						budget 		<- budget - amount;
						ask world {
							do user_msg(string(m_contents[MSG_TO_PLAYER]) + " : " + amount + ' By', BUDGET_MESSAGE);
						}
					}
					match SEND_MESSAGE_TO {
						ask world {
							do user_msg(string(m_contents[MSG_TO_PLAYER]), INFORMATION_MESSAGE);
						}
					}
					// a lever has been canceled on the action
					match ACTION_SHOULD_WAIT_LEVER_TO_ACTIVATE {
						Player_Action aAct <- (Land_Use_Action + Coastal_Defense_Action) first_with (each.id = m_contents[PLAYER_ACTION_ID]);
						if aAct != nil {
							aAct.should_wait_lever_to_activate <- bool(m_contents[ACTION_SHOULD_WAIT_LEVER_TO_ACTIVATE]);
						}
					}
					match NEW_ACTIVATED_LEVER {
						Activated_Lever al <- Activated_Lever first_with (each.my_map["id"] = int(m_contents["id"]));
						// a new lever has been activated on an action
						if al = nil {
							create Activated_Lever {
								do init_activ_lever_from_map (m_contents);
								ply_act <- (Land_Use_Action + Coastal_Defense_Action) first_with (each.id = my_map["p_action_id"]);
								if ply_act = nil {
									do die;
								}else {
									ask world {
										do user_msg (myself.my_map["lever_explanation"], INFORMATION_MESSAGE);
									}
									int added_cost <- int(my_map["added_cost"]);
									if added_cost != 0 {
										budget <- budget - added_cost;
										ask world{
											do user_msg (get_message('PLY_MSG_BEEN')+" " + (added_cost > 0 ? get_message('LDR_TAKEN'): get_message('LDR_GIVEN')) + " " +
												abs(added_cost)+ " By "+ PLY_MSG_DOSSIER +" '" + myself.ply_act.label + (myself.ply_act.command in [ACTION_CREATE_DIKE, 
														ACTION_CREATE_DUNE ] ? "" : ' (' + myself.ply_act.element_id + ")")+ "'", BUDGET_MESSAGE);
										}	
									}
									int added_delay <- int(my_map["added_delay"]);
									if added_delay != 0{
										ask world{
											do user_msg (PLY_MSG_DOSSIER + " '" + myself.ply_act.label + 
												(myself.ply_act.command in [ACTION_CREATE_DIKE, ACTION_CREATE_DUNE] ? "" : ' (' + myself.ply_act.element_id + ")")+"' " +
												get_message("PLY_HAS_BEEN") + " " + (added_delay >= 0 ? get_message('PLY_DELAYED'): get_message('PLY_ADVANCED')) +
												" " + get_message("PLY_BY") + " " + abs(added_delay) + " " + MSG_ROUND + (abs(added_delay) <=1 ? "" : "s"), INFORMATION_MESSAGE);
										}
									}
									ply_act.should_wait_lever_to_activate <- false;
									add self to: ply_act.activated_levers;	
								}
							}
						}
						// a lever has been applied
						else {
							ask al.ply_act {
								should_wait_lever_to_activate <- false;
							}
						}
					}
					// exchange pebbles between districts (cliff_coast)
					match 'DIEPPE_CRIEL_PEBBLES' {
						dieppe_pebbles_allowed <- bool(m_contents['ALLOWED']);
						ask world {
							if dieppe_pebbles_allowed {
								do user_msg (get_message("LEV_PEBBLES_GIVEN"), INFORMATION_MESSAGE);
								dieppe_pebbles_discount <- float (m_contents['DISCOUNT']);
							} else {
								do user_msg ("L'authorisation à Criel de charger les galets de Dieppe est terminée", INFORMATION_MESSAGE);
							}	
						}
					}
					// a player button has been activated/deactivated of hidded
					match 'TOGGLE_BUTTON' {
						ask Button where (each.command = int(m_contents['COMMAND'])) {
							do toggle (int(m_contents["STATE"]));
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
	// messages received from the manager
	reflex wait_message {
		loop while:has_more_message() {
			message msg <- fetch_message();
			map<string, string> m_contents <- msg.contents;
			switch m_contents["TOPIC"]{
				// a player action has been applied
				match PLAYER_ACTION_IS_APPLIED {
					string act_id <- m_contents["id"];
					ask (Coastal_Defense_Action + Land_Use_Action) first_with (each.id = act_id){
						is_applied <- true;
						my_hist_elem.label <- label + " (" + element_id +")";
						should_wait_lever_to_activate <- false;
					}
				}
				// the manager has launched a new round
				match INFORM_NEW_ROUND {
					game_round	<- game_round + 1;
					previous_population <- current_population;
					current_population <- int(m_contents[POPULATION]);
					budget <- int(m_contents[BUDGET]);
					// update the round of actions not yet sent/validated
					ask (Land_Use_Action + Coastal_Defense_Action) where (!each.is_sent) {
						initial_application_round <- initial_application_round + 1;
					}
					switch game_round {
						match 1 {
							ask world {
								do user_msg (get_message('MSG_SIM_STARTED_ROUND1'), INFORMATION_MESSAGE);
								do user_msg (MSG_DISTRICT_POPULATION + " " + current_population, INFORMATION_MESSAGE);
								do user_msg (MSG_YOUR_BUDGET + " " + thousands_separator(budget) + ' By', BUDGET_MESSAGE);
							}
						}
						// if round > 1
						default {
							ask world {
								do user_msg(MSG_ROUND + " " + game_round + " " + MSG_HAS_STARTED, INFORMATION_MESSAGE);
								do user_msg("" + ((previous_population = current_population) ? "" : ((previous_population < current_population) ?							
									MSG_DISTRICT_RECEIVE + " " + (current_population - previous_population) :
									MSG_DISTRICT_LOSE + " " + (previous_population - current_population))
									+ " " + MSG_NEW_COMERS + ". ") + MSG_DISTRICT_POPULATION + " " +
									current_population + " " + MSG_INHABITANTS + ".", POPULATION_MESSAGE);
								received_tax <- int(current_population * tax_unit);
								do user_msg (get_message('MSG_TAXES_RECEIVED_FROM') +" "+ thousands_separator(received_tax) + ' By. '
									+ MSG_YOUR_BUDGET + " : " + thousands_separator(budget) + ' By', BUDGET_MESSAGE);
							}
						}
					}
				}
				// if a player (re)connect, it is informed with the state of the game
				match INFORM_CURRENT_ROUND {
					game_round <- int(m_contents[NUM_ROUND]);
					current_population <- int(m_contents[POPULATION]);
					budget <- int(m_contents[BUDGET]);
					is_active_gui <- ! bool(m_contents["GAME_PAUSED"]);
										
					ask world {
						do refresh_all;
						if game_round != 0 {
							do user_msg(get_message('MSG_ITS_ROUND') + " " + game_round, INFORMATION_MESSAGE);
							do user_msg (get_message('MSG_DISTRICT_POPULATION') + " " + current_population, INFORMATION_MESSAGE);
							do user_msg (MSG_YOUR_BUDGET + " " + thousands_separator(budget) + ' By', BUDGET_MESSAGE);
						}
					}
					if game_round = 0 {
						// receives the list of buttons activated for this player
						list<int> buts <- [];
						ask Button where (each.display_name != BOTH_DISPLAYS) {
							add command to: buts;
						}
						map<string,string> mp <- ["REQUEST"::"MY_BUTTONS","buts"::buts];
						do send to: GAME_MANAGER contents: mp;
					}
					else {
						// receives the state of buttons
						ask Button where (each.display_name != BOTH_DISPLAYS) {
							string etat <- m_contents ["button_"+command];
							if etat != nil {
								state <- int(etat);
							}
						}
					}
				}
				match ACTION_COAST_DEF_CREATED { // a codef has been applied/created by manager
					do coast_def_create_action(m_contents);
				}
				match NEW_COAST_DEF_ALT { // getting the altitude of a newly created codef
					ask Coastal_Defense_Action where (each.id = m_contents["act_id"]){
						altit <- float(m_contents["altit"]);
					}
				}
				match ACTION_COAST_DEF_UPDATED { // a coastal defense has been updated
					if length(Coastal_Defense where(each.coast_def_id = int(m_contents["coast_def_id"]))) = 0{
						do coast_def_create_action(m_contents);
					}
					ask Coastal_Defense where(each.coast_def_id = int(m_contents["coast_def_id"])){
						ganivelle 	<- bool(m_contents["ganivelle"]);
						alt			<- float(m_contents["alt"]);
						status 		<- m_contents["status"];
						type 		<- m_contents["type"];
						height 		<- float(m_contents["height"]);
						slices		<- int(m_contents["slices"]);
						maintained	<- bool(m_contents["maintained"]);
					}
				}
				match ACTION_COAST_DEF_DROPPED { // a coastl defense has been dismanteled
					ask Coastal_Defense where (each.coast_def_id = int(m_contents["coast_def_id"])) {
						do die;
					}
				}
				match ACTION_LAND_COVER_UPDATED {// a LU cell has been changed
					ask Land_Use where(each.id = int(m_contents["id"])){
						lu_code 	<- int(m_contents["lu_code"]);
						lu_name 	<- lu_type_names[lu_code];
						population 	<-int(m_contents["population"]);
						education_level 	<- int(m_contents["education_level"]);
						is_in_densification <- bool(m_contents["is_in_densification"]);
					}
				}
				// getting data from manager
				match DATA_RETRIEVE {
					switch m_contents["OBJECT_TYPE"] {
						match OBJECT_TYPE_WINDOW_LOCKER {
							write "Lock unlock request : " + m_contents["LOCK_REQUEST"];
							is_active_gui <- m_contents["LOCK_REQUEST"] = "UNLOCK";
						}
						match OBJECT_TYPE_PLAYER_ACTION {
							if m_contents["action_type"] = PLAYER_ACTION_TYPE_COAST_DEF {
								create Coastal_Defense_Action {
									do init_action_from_map(m_contents);
									ask game_history {
										do add_action_to_history(myself);
									}
								}
							}
							else if m_contents["action_type"] = PLAYER_ACTION_TYPE_LU {
								create Land_Use_Action {
									do init_action_from_map(m_contents);
									ask game_history {
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
						match OBJECT_TYPE_FLOOD_MARK {
							Land_Use mylu <- Land_Use first_with (each.id = int(m_contents['mylu']));
							if mylu != nil {
								do create_flood_mark (mylu, m_contents["sub_num"], m_contents["max_w_h"], m_contents["mean_w_h"], m_contents["max_w_h_per_cent"]);
							}
						}
					}
				}
				// receiving results of the flood events : land marks
				match "NEW_SUBMERSION_EVENT" {
					ask Coastal_Defense where (each.district_code = active_district_code) {
						rupture <- false;
					}
					ask Land_Use where (each.dist_code = active_district_code) {
						int ftimes <- int(m_contents["ftimes"+id]);
						if ftimes > 0 {
							flooded_times <- ftimes;	
						}
					}
					loop i from: 0 to: 4 {
						Land_Use lu <- first(Land_Use where (each.id = int(m_contents["lu_id"+i])));
						if lu != nil and lu.mark = nil {
							do create_flood_mark (lu, m_contents["submersion_number"], m_contents["max_w_h"+i], m_contents["mean_w_h"+i], m_contents["max_w_h_per_cent"+i]);
						}
					}
				}
				// receiving ruptures of codefs due to the last event
				match "NEW_RUPTURES" {
					ask Coastal_Defense where (each.district_code = active_district_code) {
						bool is_ruptured <- bool (m_contents[string(coast_def_id)]);
						rupture <- is_ruptured != nil ? is_ruptured : rupture;
					}
				}
				// the manager request openning Dieppe gates (cliff_coast)
				match 'OPEN_DIEPPE_GATES' {
					ask Water_Gate {
						display_me <- false;
					}
					ask Button where (each.command in [ACTION_CLOSE_OPEN_GATES, ACTION_CLOSE_OPEN_DIEPPE_GATE]) {
						is_selected <- false;
					}
					write "Les portes de Dieppe ont été ouvertes!";	
				}
			}
		}
	}
	// creating flood marks of the submersion
	action create_flood_mark (Land_Use lulu, string sub_num, string maxwh, string meanwh, string maxwhpercent) {
		float fmax_w_h	<- float(maxwh);
		if fmax_w_h > 0 {
			create Flood_Mark {
				icon <- world.get_flag_icon(int(sub_num));
				location <- lulu.location - {0,150#m};
				max_w_h	<- fmax_w_h;
				max_w_h_per_cent <- float(maxwhpercent);
				mean_w_h <- float(meanwh);
				floo1 <- PLY_MSG_WATER_H + " : " + string(max_w_h) + "m ("+ max_w_h_per_cent + "%)";
				floo2 <- PLY_MSG_WATER_M + " : " + string(mean_w_h) + "m";
				lulu.mark <- self;
			}
		}
	}
	// a coastal defense has been created by the manager Santatra
	action coast_def_create_action(map<string, string> msg){
		create Coastal_Defense {
			coast_def_id <- int(msg at "coast_def_id");
			shape <- polyline([{float(msg at "p1.x"),float(msg at "p1.y")}, {float(msg at "p2.x"),float(msg at "p2.y")}]);
			location <- {float(msg at "location.x"), float(msg at "location.y")};
			length_coast_def <- int(shape.perimeter);
			type <- msg at "type";
			height <- float(msg at "height");
			status <- msg at "status";
			alt <- float(msg at "alt");
			dune_type <- int(msg at "dune_type");
			draw_around <- type = COAST_DEF_TYPE_DUNE ? (dune_type = 2 ? 30 : 45) : 15;
			ask Coastal_Defense_Action first_with(each.id = msg at "action_id") {
				element_id <- myself.coast_def_id;
				add self to: myself.actions_on_me;
				myself.actions_on_me <- myself.actions_on_me sort_by (each.initial_application_round);
			}
		}			
	}
	// send the content of the basket to the manager
	action send_basket {
		Player_Action act <-nil;
		loop bsk_el over: game_basket.elements {
			act <- Basket_Element(bsk_el).current_action;
			act.is_sent <- true;
			ask game_history {
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
	string id 	<- "";
	int element_id	<- 0;
	geometry element_shape;
	int command <- -1;
	string label <- "";
	int initial_application_round <- -1; // round where the action is supposed to be executed
	int added_delay -> {activated_levers sum_of int(each.my_map["added_delay"])};
	// the real application round after applying levers
	int effective_application_round -> {initial_application_round + added_delay};
	float cost 		<- 0.0;
	int added_cost 		-> {activated_levers sum_of int(each.my_map["added_cost"])};
	float actual_cost 	-> {max([cost + added_cost,0])};
	bool is_sent 		<- false;
	bool is_applied 	<- false;
	History_Element my_hist_elem <- nil;
	
	string action_type 		<- PLAYER_ACTION_TYPE_COAST_DEF ;
	string previous_lu_name <- nil;
	bool is_expropriation 	<- false;
	bool is_in_protected_area <- false;
	bool is_in_coast_border_area <- false;
	bool is_in_risk_area <- false; 
	bool is_inland_dike <- false;
	bool has_activated_levers -> {!empty(activated_levers)};
	list<Activated_Lever> activated_levers 	<-[];
	bool should_wait_lever_to_activate 		<- false;
	
	// variables used for codefs
	float altit <- 0.0; // altitude of a coastal defense
	string coast_def_type;
	float height;
	int draw_around <- 15; // thickness of the coastl defense
	
	
	// creating a player action from the received map
	action init_action_from_map(map<string, unknown> mp){
		self.id			 	<- string(mp at "id");
		self.element_id 	<- int(mp at "element_id");
		self.command 		<- int(mp at "command");
		self.label 			<- world.label_of_action(command);
		self.cost 			<- float(mp at "cost");
		self.initial_application_round <- int(mp at "initial_application_round");
		self.is_inland_dike 	<- bool(mp at "is_inland_dike");
		self.is_in_risk_area 	<- bool(mp at "is_in_risk_area");
		self.is_in_coast_border_area <- bool(mp at "is_in_coast_border_area");
		self.is_expropriation 	<- bool(mp at "is_expropriation");
		self.is_in_protected_area 	<- bool(mp at "is_in_protected_area");
		self.previous_lu_name 	<- string(mp at "previous_lu_name");
		self.action_type 	<- string(mp at "action_type");
		self.is_applied		<- bool(mp at "is_applied");
		self.is_sent		<- bool(mp at "is_sent");

		location <- {float(mp at "locationx"), float(mp at "locationy")};
		bool loop_again <- true;
		int i <- 0;
		// shape of the object
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
		// if it is a codef
		if self.action_type = PLAYER_ACTION_TYPE_COAST_DEF {
			self.draw_around <- int (mp at "draw_around");
			self.altit	<- float (mp at "altit");
			element_shape <- polyline(all_points);
			if command in [ACTION_CREATE_DIKE, ACTION_CREATE_DUNE] {
				self.coast_def_type <- command = ACTION_CREATE_DIKE ? COAST_DEF_TYPE_DIKE : COAST_DEF_TYPE_DUNE;
				self.height <- coast_def_type = COAST_DEF_TYPE_DIKE ? BUILT_DIKE_HEIGHT : (draw_around = 45 ? BUILT_DUNE_TYPE1_HEIGHT : BUILT_DUNE_TYPE2_HEIGHT);
				shape  <-  element_shape;
			} else {
				shape <- element_shape + 15;
			}
		}
		// if it is a LU cell
		else{
			element_shape <- polygon(all_points);
			shape <- element_shape;
		}
	}
	// number of remaining rounds to be applied
	int nb_rounds_before_activation_and_waiting_for_lever_to_activate {
		int nb_rounds <- effective_application_round - game_round;
		if nb_rounds < 0 {
		 	if should_wait_lever_to_activate {return 0;}
		 	else {
		 		write "Activation delay is anormal !";
		 		return 0;
		 	}
		}
		return nb_rounds;
	}
	// build a map from the player action to send it over the network
	map<string,string> build_data_map {
		map<string,string> mp <- ["command"::command,"id"::id,
			"initial_application_round"::initial_application_round,
			"element_id"::element_id, "action_type"::action_type,
			"previous_lu_name"::previous_lu_name, "draw_around"::draw_around,
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
				put string(altit)	at: "altit" in: mp;		
		}
		return mp;
	}	
}
//------------------------------ End of Player_Action -------------------------------//

species Coastal_Defense_Action parent: Player_Action {
	string action_type 	<- PLAYER_ACTION_TYPE_COAST_DEF;
	
	rgb define_color {
		Coastal_Defense current_def <- Coastal_Defense first_with(each.coast_def_id = self.element_id);
		
		if (command in [ACTION_REPAIR_DIKE, ACTION_RAISE_DIKE, ACTION_MAINTAIN_DUNE, ACTION_ENHANCE_NATURAL_ACCR]){
			ask current_def{
				return get_higher_status_color();
			}
		}else if(command in[ACTION_DESTROY_DIKE]){
			ask current_def{
				return get_lower_status_color();
			}
		} 
		return #grey;
	}
	
	aspect map {
		if active_display = COAST_DEF_DISPLAY and !is_applied and !(Button first_with (each.command = ACTION_HISTORY)).is_selected {
			//draw draw_around#m around shape color: self = highlighted_action ? #red : (is_sent ? define_color() : #black);
			draw draw_around#m around shape color: self = highlighted_action ? #red : #black;
			if(is_sent){
				draw shape color:define_color();
				list<point> pebbles <- points_on(shape,10);
					int point_number <- length(pebbles)-1;
					loop i from: 0 to: point_number - 1{
						point p1 <- pebbles[i];
						point p2 <- pebbles[point_number - i];
						//point p2 <- pebbles[abs(point_number - (i + point_number/2))];
						draw line([p1,p2]) color:#white size:self.shape.width;
					}
				
		}
		}
	}
}
//------------------------------ End of Coastal_Defense_Action -------------------------------//

species Land_Use_Action parent: Player_Action {
	string action_type <- PLAYER_ACTION_TYPE_LU;
	
	rgb define_color {
		switch command {
			 match ACTION_MODIFY_LAND_COVER_A {return rgb(245,147,49);}
			 match ACTION_MODIFY_LAND_COVER_N {return rgb(11,103,59); }
			
			 match ACTION_MODIFY_LAND_COVER_AU {return rgb(250,250,250);}
			 
			 match_one [ACTION_MODIFY_LAND_COVER_AUs,ACTION_MODIFY_LAND_COVER_Us,ACTION_MODIFY_LAND_COVER_Ui]{
			 
				 Land_Use current_lu <- Land_Use first_with(each.id = self.element_id);
				 
				 ask current_lu {
				 	do next_density_color();
				 }	
			}
		}	 	 			
		//return #red;
	}
	
	aspect map {
		// showing land use actions if the hitory button is not selected
		if active_display = LU_DISPLAY and !is_applied and !(Button first_with (each.command = ACTION_HISTORY)).is_selected{
			
			//Hachure instead of triangles
			if command = ACTION_MODIFY_LAND_COVER_Ui {
				geometry sq <- first(to_squares(shape, 1, false));
				list<geometry> trs <- to_triangles(shape);
				draw last(trs where (each.area = max(trs collect (each.area)))) color: define_color() border: define_color();
				//draw modif_land_cover_auNus size: self.shape.width;
				//draw shape at: location color:define_color() border: (self = highlighted_action) ? #red: (is_sent ? define_color() : #black) ;
			}
			else if command in [ACTION_MODIFY_LAND_COVER_AUs, ACTION_MODIFY_LAND_COVER_Us]{
					draw modif_land_cover_ui_preload size: self.shape.width;
			}else{
				list<geometry> trs <- to_triangles(shape);
				draw last(trs where (each.area = max(trs collect (each.area)))) color: define_color() border: define_color();
				draw shape at: location empty: true border: (self = highlighted_action) ? #red: (is_sent ? define_color() : #black) ;
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
	bool is_selected <- false;
	geometry shape 	<- square(button_size);
	point p;
	image_file my_icon;
	string help_msg;
	float select_size <- 0.0 update: min([ui_width,ui_height]);
	int state <- B_ACTIVATED; // buttons are activated by default
	
	reflex update{
		shape <- rectangle(select_size, select_size);
		do refresh_me;
	}
	
	// init buttons from the actions.conf file
	action init_button {
		command 	<- int(data_action at action_name at 'action_code');
		label 		<- world.label_of_action(command);
		action_cost <- world.cost_of_action(action_name);
 		help_msg 	<- world.get_message((data_action at action_name at 'button_help_message'));
		my_icon 	<-  image_file("../images/developer_icons/" + data_action at action_name at 'button_icon_file') ;
	}
	
	// changing the state of a button (by the leader)
	action toggle (int etat) {
		state <- etat;
		if state = B_ACTIVATED {
			ask world {
				do user_msg (replace_strings('MSG_BUTTON_ENABLED', [myself.label]), INFORMATION_MESSAGE);
			}
		} else if state = B_DEACTIVATED {
			if !(command in [ACTION_CLOSE_OPEN_GATES, ACTION_CLOSE_OPEN_DIEPPE_GATE]) {
				is_selected <- false;
			}
			ask world {
				do user_msg (replace_strings('MSG_BUTTON_DISABLED', [myself.label]), INFORMATION_MESSAGE);
			}
		}
	}
	
	aspect map{
		if state != B_HIDDEN and (display_name = active_display or display_name = BOTH_DISPLAYS) {
			draw my_icon size: {select_size, select_size};
			if is_selected {
				draw shape empty: true border: # red;
			}
			if state = B_DEACTIVATED {
				draw TRANSPARENT size: {select_size, select_size};
			}
		}
	}
}
//------------------------------ End of Button -------------------------------//

// right buttons shared between both displays (show ppr, inspect, ..)
species Button_Map parent: Button {
	geometry shape <- square(850#m);
	
	aspect base{
		draw shape color: #white border: is_selected ? # red : #white;
		draw my_icon size: 800#m ;
	}
}
//------------------------------ End of Button_Map -------------------------------//

species District {
	int district_id <- 0;
	string district_name <- "";
	string district_long_name <- "";
	string district_code <- "";
	aspect base{
		draw shape color: self = active_district ? rgb (202,170,145) : rgb(255,255,212) border: #black;
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
	int education_level <- 0;
	float mean_alt;
	string density_class-> {population = 0 ? POP_EMPTY : (population < POP_LOW_NUMBER ? POP_VERY_LOW_DENSITY : (population < POP_MEDIUM_NUMBER ? POP_LOW_DENSITY : 
								(population < POP_HIGH_NUMBER ? POP_MEDIUM_DENSITY : POP_DENSE)))};
	int expro_cost 		 -> {population = 0 ? EXP_COST_IF_EMPTY : round (population *400* population ^ (-0.5))};
	bool is_urban_type 	 -> {lu_code in [LU_TYPE_U,LU_TYPE_Us,LU_TYPE_AU,LU_TYPE_AUs]};
	bool is_adapted_type -> {lu_code in [LU_TYPE_Us,LU_TYPE_AUs]};
	bool is_in_densification <- false;
	
	bool focus_on_me <- false; // the highlighted land use cell
	Flood_Mark mark <- nil;
	list<Player_Action> actions_on_me <- []; // the list a previous actions done on this land use (history)
	int flooded_times <- 0; // the number of times that the cell has been flooded
	list<rgb> my_cols <- [#gray, #gray]; // list of two colors to draw transitive states (AU, AUs)

	// initialize the land use cell from the received map
	action init_lu_from_map(map<string, unknown> a ){
		self.id 				 <- int   (a at "id");
		self.lu_code 			 <- int   (a at "lu_code");
		self.dist_code	 		 <- active_district_code;
		self.lu_name 			 <- lu_type_names[lu_code];
		self.population 		 <- int   (a at "population");
		self.education_level     <- int   (a at "education_level");
		self.mean_alt			 <- float (a at "mean_alt");
		self.is_in_densification <- bool  (a at "is_in_densification");
		self.flooded_times		 <- int   (a at "flooded_times");
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
	
	rgb cell_color {
		switch lu_code{
			match	  	LU_TYPE_N			 {return #green; } // natural
			match	  	LU_TYPE_A 			 {return #orange;} // agricultural
			match_one [LU_TYPE_AU,LU_TYPE_AUs]{return #yellow;} // to urbanize
			match_one [LU_TYPE_U,LU_TYPE_Us] {				  // urbanised
				switch density_class 		  {	// grayscale
					match POP_EMPTY 		  { return rgb(250,250,250);}
					match POP_VERY_LOW_DENSITY{ return rgb(225,225,225);}
					match POP_LOW_DENSITY	  { return rgb(190,190,190);}
					match POP_MEDIUM_DENSITY  { return rgb(150,150,150);}
					match POP_DENSE 		  { return rgb(120,120,120);}
					default 				  { write "Density class problem !";}
				}
			}			
		}
		return #black;
	}
	
	rgb next_density_color{
		switch density_class 		  {	// grayscale
			match POP_EMPTY 		  { return rgb(225,225,225);}
			match POP_VERY_LOW_DENSITY{ return rgb(190,190,190);}
			match POP_LOW_DENSITY	  { return rgb(150,150,150);}
			match POP_MEDIUM_DENSITY  { return rgb(120,120,120);}
			default 				  { write "Density class problem !";}
		}
	}
	
	// the normal aspect of land use (colored by PLU type)
	aspect map {
		if active_display = LU_DISPLAY and !(Button first_with (each.command = ACTION_HISTORY)).is_selected {
			
			if(lu_code in [LU_TYPE_AU,LU_TYPE_AUs]){
				draw shape at: location color:next_density_color();
				draw modif_land_cover_auNus size: self.shape.width;
			}else{
				draw shape color: my_color; 
			}
			
			if is_adapted_type		{draw modif_land_cover_ui size: self.shape.width;}
			
			if is_in_densification	{
				geometry sq <- first(to_squares(shape, 1, false));
				list<geometry> trs <- to_triangles(shape);
				draw last(trs where (each.area = max(trs collect (each.area)))) color: next_density_color();
				//draw shape at: location color:next_density_color();
				//draw modif_land_cover_auNus size: self.shape.width;
			}
			if focus_on_me {
				draw shape empty: true border: #black;
			}
			if(education_level !=0){
				draw EDUCATIONAL_ICON at:location size:(13 + 8*education_level)#px ;
			}
		}			
	}
	// the historical aspect, when the button history is selected
	aspect historical {
		if (Button first_with (each.command = ACTION_HISTORY)).is_selected {
			if active_display = LU_DISPLAY {
				draw shape color: #lightgray;
				int acts <- length(actions_on_me); // showing previous player actions on the cell
				if acts > 0 {
					draw shape color: #gray border: #gold;
					draw ""+acts font: f1 color: #yellow anchor:#center;
				}
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
	bool maintained	<- false; // for DUNES (Camargue)
	bool chanel <- false; // for canal à Mahajunga
	int slices <- 4;
	float alt <- 0.0;
	string status;
	int dune_type <- 1;
	int length_coast_def;
	bool rupture <- false;
	list<Player_Action> actions_on_me <- [];
	int draw_around;
	
	//var for form modification
	int outer_shape_layer <- 2;
	rgb outer_layer_color;
	
	int symbol_size <- 100;
	image_file symbol_form;
	list<point> symbol_place;
	
	// initialize the codef from the received map
	action init_coastal_def_from_map(map<string, unknown> a ){
		self.coast_def_id<- int(a at "coast_def_id");
		self.type 		<- string(a at "type");
		self.status 	<- string(a at "status");
		self.height 	<- float(a at "height");
		self.alt 		<- float(a at "alt");
		self.ganivelle 	<- bool(a at "ganivelle");
		self.maintained	<- bool(a at "maintained");
		self.chanel     <- bool(a at "chanel");
		self.dune_type  <- int(a at "dune_type");
		self.rupture	<- bool(a at "rupture");	
		self.location	<- {float(a at "locationx"), float(a at "locationy")};
		self.district_code <- active_district_code;
		self.slices <-  int(a at "slices");
		int tot_points	<- int(a at "tot_points");
		point pp;
		list<point> all_points <- [];
		loop i from: 0 to: tot_points - 1{
			pp <- {float(a at ("locationx"+i)), float(a at ("locationy"+i))};
			add pp to: all_points;
		}
		
		shape <- polyline(all_points);
		length_coast_def <- int(shape.perimeter);
		draw_around <- type = COAST_DEF_TYPE_DUNE ? (dune_type = 2 ? 30 : 45) : 15;
	}
	
	action init_coastal_def { // init a new codef
		if status = ""  {status <- STATUS_GOOD;	    } 
		if type = '' 	{type 	 <- COAST_DEF_TYPE_DIKE;}
		if height = 0.0 {height <- MIN_HEIGHT_DIKE;    }
		length_coast_def <- int(shape.perimeter);
		// drawn line depends on the codef type : dike (15), dune1 (45), dune2 (30)
		draw_around <- type = COAST_DEF_TYPE_DUNE ? (dune_type = 2 ? 30 : 45) : 15;
	}
	
	//define angle of a segment
	float define_angle(point p1, point p2){
		return atan((p2.y - p1.y) / (p2.x - p1.x));
	}
	
	//draw symbol inside defenses
	action draw_symbols(image_file symbol){		

		list<point> pebbles <- points_on(shape, 100#m);
		int point_number <- length(pebbles);
		loop i from: 0 to: point_number - 1{
			point p1 <- pebbles[i];
			point p2 <- i = point_number -1 ? pebbles[i - 1] : pebbles[i+1];
			draw symbol size:symbol_size rotate: define_angle(p1,p2) at: pebbles[i];
		}
	}
	
	//get cord symbol according to state
	image_file get_cord_aspect{
		switch status {
				match STATUS_GOOD   {return normal_cord_symbol;}
				match STATUS_MEDIUM {return medium_cord_symbol;}
				match STATUS_BAD 	{return bad_cord_symbol;}
				default {
					write "Density class problem !";
				}	
		}
	}
	
	action get_higher_status_color{
		switch status {
				match STATUS_GOOD   {color <- #green;}
				match STATUS_MEDIUM {color <- #green;} 
				match STATUS_BAD 	{color <- #orange;  } 
				default 			{
					color <- #black;
					write "" + coast_def_id + " Coast Def status problem ! " + status;
				}
			}
		return color;
	}
	
	action get_lower_status_color{
		switch status {
				match STATUS_GOOD   {color <- #orange;}
				match STATUS_MEDIUM {color <- #red;} 
				match STATUS_BAD 	{color <- #red;  } 
				default 			{
					color <- #black;
					write "" + coast_def_id + " Coast Def status problem ! " + status;
				}
			}
		return color;
	}
	
	aspect map {
		if active_display = COAST_DEF_DISPLAY {
			switch status {
				match STATUS_GOOD   {color <- #green;}
				match STATUS_MEDIUM {color <- #orange;} 
				match STATUS_BAD 	{color <- #red;  } 
				default 			{
					color <- #black;
					write "" + coast_def_id + " Coast Def status problem ! " + status;
				}
			}
//			draw draw_around#m around shape color: color;
			//draw shape color: #black;
					
			
			if type = COAST_DEF_TYPE_DUNE{
				outer_layer_color <- #yellow;
				draw draw_around#m around shape color: color border:outer_layer_color ;
				do draw_symbols(dune_symbol_img);
				 
				if maintained { // if the dune is mantained we draw white line inside of it
					draw shape+15#m color: #whitesmoke;
				}
				if ganivelle { // if it's on ganivelle (accretion), we draw black points inside of it
					loop i over: points_on(shape, 30#m) {
						draw circle(10,i) color: #black;
					}
				}
			}
			else if type = COAST_DEF_TYPE_CORD { // if it's a pebble dike, we draw slices as squares
				draw shape+ 4.5#m color: #darkgray;
				do draw_symbols(get_cord_aspect());
			}
			//add symboles inside the aspect of a dike
			else if type = COAST_DEF_TYPE_DIKE {
				outer_layer_color <- #grey;
				draw draw_around#m around shape color: color border:outer_layer_color;
				do draw_symbols(dike_symbol_img);
			}
			else if type = COAST_DEF_TYPE_CHANEL {
				outer_layer_color <- #green;
				draw draw_around#m around shape color: #blue border:outer_layer_color;
			}
			
//			if(!(Button first_with (each.command = ACTION_HISTORY)).is_selected ){
//				rgb next_color<- #gold;
//				draw draw_around#m around shape color: next_color border:outer_layer_color;
//				//texture:modif_land_cover_auNus
//			}
		}
	}
	// the historical aspect showing last player actions
	aspect historical {
		if (Button first_with (each.command = ACTION_HISTORY)).is_selected {
			if(active_display = COAST_DEF_DISPLAY) {
				int wid <- type = COAST_DEF_TYPE_DUNE ? (dune_type = 1 ? 45 : 30) : 15;
				int acts <- length(actions_on_me);
				if acts > 0 {
					draw wid#m around shape color: #yellow;
				} else{
					draw wid#m around shape color: #lightgray;
				}
				draw shape color: #black;
				if acts > 0 {
					draw circle (40) color: #gray border: #black;
					draw circle (30) empty: true color: #gold;
					draw ""+acts font: f1 color: #yellow anchor:#center;
				}
			}
		}
	}
}
//------------------------------ End of Coastal_Defense -------------------------------//

species Tab_Background skills: [UI_location]{
	reflex update{
		do refresh_me;
	}
	
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
	float gem_height <- 0.0 update: ui_height;
	float gem_width <- 0.0 update: ui_width;
	float x 		 <- 0.0 update: location.x - ui_width / 2;
	float y 		 <- 0.0 update: location.y - ui_height / 2;
	
	reflex update{
		shape <- polygon([{x, y}, {x, y + gem_height}, {x + gem_width, y + gem_height}, {x + gem_width, y}, {x, y}]);
		do refresh_me;
	}
	
	aspect base{
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

species Isoline {
	aspect base {
		if active_display = COAST_DEF_DISPLAY {
			draw shape color: #gray;
		}
	}
}
//species River {
//	aspect base {
//		draw shape color:#blue;
//	}
//}
species River {
	int id <- 0;
	int profondeurMaximal <- 10;
	int profondeurActuel <- 4;
	
	aspect base {
		rgb color<-#blue;
		int boue <- profondeurMaximal - profondeurActuel;		
		if(boue > 4){
			color <- #green;
		}else if (boue > 2){
			color <- #red;
		}
		draw shape color:color;
	}
}
species Sea {}

species Protected_Area {
	aspect base {
		if (Button_Map first_with (each.command = ACTION_DISPLAY_PROTECTED_AREA)).is_selected {
			draw shape color: rgb (185, 255, 185, 120) border:#black;
		}
	}
}

species Flood_Risk_Area {
	aspect base {
		if (Button_Map first_with(each.command = ACTION_DISPLAY_FLOODED_AREA)).is_selected {
			draw shape color: rgb (20, 200, 255,120)border:#black;
		}
	}
}

species Coastal_Border_Area {
	geometry line_shape;
}

species Flood_Mark {
	float max_w_h;
	float max_w_h_per_cent;
	float mean_w_h;
	string floo1 <- "";
	string floo2 <- "";
	image_file icon <- nil;
	geometry shape <- rectangle(150#m,300#m);
	aspect base {
		if (Button_Map first_with (each.command = ACTION_DISPLAY_FLOODING)).is_selected {
			draw icon size: 300#m at: location;
		}
	}
}

species Water_Gate {
	int id;
	bool display_me <- false;
	aspect base {
		if display_me {
			draw 15#m around shape color: #black;
			draw shape color: #white;
		}
	}
}

//---------------------------- Experiment definiton -----------------------------//
experiment District1 type: gui parent: LittoSIM_GEN_Player {
	action _init_ {
		create simulation with:[active_district_name::districts[0]];
		minimum_cycle_duration <- 0.5;
	}
}

experiment District2 type: gui parent: LittoSIM_GEN_Player {
	action _init_ {
		create simulation with:[active_district_name::districts[1]];
		minimum_cycle_duration <- 0.5;
	}
}

experiment District3 type: gui parent: LittoSIM_GEN_Player {
	action _init_ {
		/*
		 * get the number of districts to prevent executing a non-existing district
		 */
		int n_dists <- length(map(eval_gaml(first(text_file("../" + first(text_file("../includes/config/littosim.conf").contents
			where (!(each contains '#') and (each contains 'STUDY_AREA_FILE')))
			split_with ';' at 1).contents where (!(each contains '#') and (each contains 'MAP_DIST_SNAMES'))) split_with ';' at 1)));
		if n_dists > 2 {
			create simulation with:[active_district_name::districts[2]];
			minimum_cycle_duration <- 0.5;	
		}
	}
}

experiment District4 type: gui parent: LittoSIM_GEN_Player {
	action _init_ {
		int n_dists <- length(map(eval_gaml(first(text_file("../" + first(text_file("../includes/config/littosim.conf").contents
			where (!(each contains '#') and (each contains 'STUDY_AREA_FILE')))
			split_with ';' at 1).contents where (!(each contains '#') and (each contains 'MAP_DIST_SNAMES'))) split_with ';' at 1)));
		if n_dists > 3 {
			create simulation with:[active_district_name::districts[3]];
			minimum_cycle_duration <- 0.5;	
		}
	}
}

experiment LittoSIM_GEN_Player type: gui{
	// read the list of districts of study_area.conf
	list<string> districts 	<- map(eval_gaml(first(text_file("../" + first(text_file("../includes/config/littosim.conf").contents
			where (!(each contains '#') and (each contains 'STUDY_AREA_FILE')))
			split_with ';' at 1).contents where (!(each contains '#') and (each contains 'MAP_DIST_SNAMES'))) split_with ';' at 1)).values;

	parameter "District choice : " var: active_district_name <- districts[0] among: districts;
	
	init {
		minimum_cycle_duration <- 0.5;
	}
	
	output{
		// organizing the interface
		layout horizontal([vertical([0::6750,1::3250])::6500, vertical([2::5000,3::5000])::3500])
				tabs: false parameters: false consoles: false navigator: false toolbars: false tray: false;
		
		// MAP_DISPLAY
		display "Map" background: #black focus: active_district{
			graphics "World" {
				draw shape color: rgb(0,188,196);
				if application_name = "overflow_coast_h" { // draw black background for Camargue (hide the north sea)
					draw rectangle(2*world.shape.width, world.shape.height) at: {0,0} color: #black;
				}
			}
			species District aspect: base ;
			graphics "Population" { // population geometry is colored in the codef tab
				draw population_area color: rgb(105,105,105) ;
			}
			species Land_Use 				aspect: map;
			species Land_Use 				aspect: historical;
			species Land_Use_Action 		aspect: map;
			
			species Coastal_Defense 		aspect: map;
			species Coastal_Defense_Action 	aspect: map;
			species Coastal_Defense 		aspect: historical;
			species Road 					aspect:	base;
			species River					aspect: base;
			species Water_Gate				aspect: base;
			species Protected_Area 			aspect: base;
			species Flood_Risk_Area 		aspect: base;
			species Flood_Mark				aspect: base;
			species Tab_Background 			aspect: base;
			species Tab 					aspect: base;
			species Button 					aspect: map;
			species Button_Map				aspect: map;
			
			// showing information box on a codef when it is ispected
			graphics "Coast Def Info" {
				if explored_coast_def != nil and (Button first_with (each.command = ACTION_INSPECT)).is_selected and explored_button = nil
							and (!(Button_Map first_with (each.command = ACTION_DISPLAY_FLOODING)).is_selected or explored_flood_mark = nil) {
					Coastal_Defense my_codef <- explored_coast_def;
					point target <- {my_codef.location.x , my_codef.location.y};
					point target2 <- {my_codef.location.x + 1 *(INFORMATION_BOX_SIZE.x#px),my_codef.location.y + 1*(INFORMATION_BOX_SIZE.y#px + 60#px)};
					draw rectangle(target,target2) border: #gold color: #gray ;
					
					draw PLY_MSG_INFO_AB + " : " + eval_gaml('MSG_' + my_codef.type) at: target + {3#px, 15#px} font: regular color: #yellow;
					int xpx <-0;
					draw PLY_MSG_LENGTH + " : " + string(round(100*my_codef.length_coast_def)/100) + "m" at: target + {10#px, xpx#px + 35#px} font: regular color: #white;
					xpx <- xpx+20;
					draw PLY_MSG_ALTITUDE + " : " + string(round(100*my_codef.alt)/100) + "m" at: target + {10#px, xpx#px + 35#px} font: regular color: #white;
					xpx <- xpx+20;
					draw PLY_MSG_HEIGHT + " : " + string(round(100*my_codef.height)/100) + "m" at: target + {10#px, xpx#px + 35#px} font: regular color: #white;
					xpx <- xpx+20;
					draw PLY_MSG_STATE + " : " + eval_gaml('PLY_MSG_' + my_codef.status) at: target + {10#px, xpx#px + 35#px} font: regular color: #white;
					draw "ID : "+ string(my_codef.coast_def_id) at: target + {10#px, xpx#px + 55#px} font: regular color: #white;
					xpx <- xpx+20;
					if my_codef.type = COAST_DEF_TYPE_CORD {
						draw PLY_MSG_SLICES + " : " + string(my_codef.slices) at: target + {10#px, xpx#px + 55#px} font: regular color: #white;
					} else {
						draw (my_codef.type = COAST_DEF_TYPE_DIKE ? MSG_RUPTURE : MSG_BREACH) + " : " + (my_codef.rupture ? MSG_YES : MSG_NO)  at: target + {10#px, xpx#px + 55#px} font: regular color: #white;
					}
					if my_codef.status != STATUS_GOOD {
						point image_loc <- {my_codef.location.x + 1*(INFORMATION_BOX_SIZE.x#px) - 40#px, my_codef.location.y + 80#px};
						switch(my_codef.status){
							match STATUS_MEDIUM {draw file("../images/system_icons/player/danger.png")  at: image_loc size: 50#px;}
							match STATUS_BAD 	{draw file("../images/system_icons/common/rupture.png") at: image_loc size: 50#px;}
						}	
					}
				}
			}
			// showing information box on a codef in the history mode
			graphics "Coast Def History" {
				if explored_coast_def != nil and (Button first_with (each.command = ACTION_HISTORY)).is_selected {
					Coastal_Defense my_codef <- explored_coast_def;
					int xxsize <- length(my_codef.actions_on_me);
					if xxsize > 0 {
						point target  <- {my_codef.location.x, my_codef.location.y};
						point target2 <- {my_codef.location.x + 1 * (INFORMATION_BOX_SIZE.x#px + 20#px), my_codef.location.y + 1 * (INFORMATION_BOX_SIZE.y#px -60#px + (xxsize*20)#px)};
						int xpx <- 15;
						draw rectangle(target,target2) border: #gold color: #gray ;
						draw PLY_MSG_HIST_AB + " : " + eval_gaml('MSG_' + my_codef.type) + " ("+string(my_codef.coast_def_id)+")" at: target + {3#px, xpx#px} font: regular color: #yellow;
						loop acta over: my_codef.actions_on_me {
							xpx <- xpx + 20;
							draw string(acta.effective_application_round) + " : " +	world.label_of_action(acta.command) at: target + {5#px, xpx#px} font: regular color: #white;
						}
					}
				}
			}
			// showing information box on a codef when there is a player action in process
			graphics "Coast Def Action" { 
				if explored_coast_def_action != nil and !explored_coast_def_action.is_applied and explored_coast_def_action.command in [ACTION_CREATE_DIKE, ACTION_CREATE_DUNE] {
					Coastal_Defense_Action my_codef_action <- explored_coast_def_action;
					point target <- {my_codef_action.location.x  ,my_codef_action.location.y};
					point target2 <- {my_codef_action.location.x + 1 *(INFORMATION_BOX_SIZE.x#px),my_codef_action.location.y + 1*(INFORMATION_BOX_SIZE.y#px+40#px)};
					draw rectangle(target,target2) border: #gold color: #gray ;
					
					draw PLY_MSG_INFO_AB + " : " + eval_gaml('MSG_' + my_codef_action.coast_def_type) at: target + {5#px, 15#px} font: regular color: #yellow;
					int xpx <-0;
					draw PLY_MSG_LENGTH + " : " + string(round(100*my_codef_action.shape.perimeter)/100) + "m" at: target + {10#px, xpx#px + 35#px} font: regular color: #white;
					xpx <- xpx+20;
					draw PLY_MSG_ALTITUDE + " : " + string(round(100*my_codef_action.altit)/100) + "m" at: target + {10#px, xpx#px +35#px} font: regular color: #white;
					xpx <- xpx+20;
					draw PLY_MSG_HEIGHT + " : " + string(round(100*my_codef_action.height)/100.0) + "m" at: target + {10#px, xpx#px +35#px} font: regular color: #white;
					xpx <- xpx+20;
					draw PLY_MSG_STATE + " : " + PLY_MSG_GOOD at: target + {10#px, xpx#px +35#px} font: regular color: #white;
					draw PLY_MSG_APP_ROUND + " : " + string(my_codef_action.initial_application_round) at: target + {10#px, xpx#px +55#px} font: regular color: #white;
				}
			}
			// showing information box on a flood mark
			graphics "Flood Mark Info" {
				if explored_flood_mark != nil and (Button_Map first_with (each.command = ACTION_DISPLAY_FLOODING)).is_selected and explored_button = nil{
					Flood_Mark fm <- explored_flood_mark;
					point target <- {fm.location.x  ,fm.location.y};
					point target2 <- {fm.location.x + 1 *(INFORMATION_BOX_SIZE.x#px),fm.location.y + 1*(INFORMATION_BOX_SIZE.y#px-40#px)};
					draw rectangle(target,target2) border: #gold color: #lightblue ;
					draw fm.floo1 at: target + {10#px, 15#px} font: regular color: #black;
					draw fm.floo2 at: target + {10#px, 35#px} font: regular color: #black;
				}
			}
			// showing information box on a button when it is hovered
			graphics "Button Info" {
				if explored_button != nil and explored_button.state != B_HIDDEN {
					Button my_button <- explored_button;
					float increment <- active_district_name = DISTRICT_AT_TOP ? (-INFORMATION_BOX_SIZE.y #px) : 0.0;
					point target 	<- world.button_box_location(my_button.location, int(2 * (INFORMATION_BOX_SIZE.x #px)));
					point target2 	<- {target.x - 2 * (INFORMATION_BOX_SIZE.x #px), target.y + increment};
					float xxx <- active_display = COAST_DEF_DISPLAY ? 1.0 : 1.25;
					int xmax <- DUNES_TYPE2 ? 20 : 0;
					point target3 <- {target.x , target.y + xxx * (INFORMATION_BOX_SIZE.y #px + xmax#px) + increment};
					
					draw rectangle(target2,target3) border: #gold color: #gray ;
					draw my_button.label    at: target2 + {5#px, 15#px} font: regular color: #yellow;
					draw my_button.help_msg at: target2 + {10#px, 35#px} font: regular color: #whitesmoke;

					if !(my_button.command in [ACTION_INSPECT, ACTION_HISTORY,ACTION_DISPLAY_PROTECTED_AREA, ACTION_DISPLAY_FLOODED_AREA,
							ACTION_DISPLAY_FLOODING,ACTION_CLOSE_OPEN_GATES,ACTION_CLOSE_OPEN_DIEPPE_GATE]) {
						string txtt;
						if active_display = LU_DISPLAY { txtt <- MSG_COST_APPLIED_PARCEL; }
						int xpx <- 55;
						switch my_button.command {	
							match ACTION_MODIFY_LAND_COVER_N {
								if DUNES_TYPE2 {
									draw txtt + " A : "  + world.cost_of_action('ACTON_MODIFY_LAND_COVER_FROM_A_TO_N') * 2 at:   target2 + {10#px, xpx#px} font: regular color: #white;
									xpx <- xpx + 20; 
									draw txtt + " A vulnérable : "  + world.cost_of_action('ACTON_MODIFY_LAND_COVER_FROM_A_TO_N') at:   target2 + {10#px, xpx#px} font: regular color: #white; 
								} else {
									draw txtt + " A : "  + world.cost_of_action('ACTON_MODIFY_LAND_COVER_FROM_A_TO_N') at:   target2 + {10#px, xpx#px} font: regular color: #white;	
								}
								xpx <- xpx + 20; 
								draw txtt + " AU : " + world.cost_of_action('ACTON_MODIFY_LAND_COVER_FROM_AU_TO_N') at: target2 + {10#px, xpx#px} font: regular color: #white; 
								xpx <- xpx + 20; 
								draw txtt + " U : "  + MSG_COST_EXPROPRIATION at: target2 + {10#px, xpx#px} font: regular color: #white;
							}
							match ACTION_MODIFY_LAND_COVER_AUs{
								draw txtt + " AU : " + my_button.action_cost  at: target2 + {10#px, 55#px} font: regular color: #white;
								draw txtt + " U : "  + world.cost_of_action('ACTION_MODIFY_LAND_COVER_Us') at: target2 + {10#px, 75#px} font: regular color: #white; 
							}
							default {
								txtt <- active_display = COAST_DEF_DISPLAY ? "/m" : ""; 
								draw MSG_COST_ACTION + " : " + my_button.action_cost + txtt at: target2 + {10#px, 55#px} font: regular color: #white;
							}
						}
					}
				}
			}
			// showing information box on a lu cell when it is ispected
			graphics "LU Info" {
				if explored_lu != nil and (explored_land_use_action = nil or explored_land_use_action.is_applied) and
						(Button first_with (each.command = ACTION_INSPECT)).is_selected and explored_button = nil{
					Land_Use my_lu <- explored_lu;
					int xxsize <- my_lu.lu_code in [LU_TYPE_U, LU_TYPE_Us] ? 40 : 0;
					bool marked <- (Button_Map first_with (each.command = ACTION_DISPLAY_FLOODING)).is_selected and my_lu.mark != nil;
					if marked {
						xxsize <- xxsize + 40;
					}
					point target  <- {my_lu.location.x, my_lu.location.y};
					point target2 <- {my_lu.location.x + 1 * (INFORMATION_BOX_SIZE.x#px), my_lu.location.y + 1 * (INFORMATION_BOX_SIZE.y#px + xxsize#px)};
					int xpx <- 15;
					draw rectangle(target,target2) border: #gold color: #gray ;
					draw PLY_MSG_INFO_AB + " : " + PLY_MSG_LAND_USE at: target + {3#px, xpx#px}  font: regular color: #yellow;
					xpx <- xpx + 20;
					draw "" + eval_gaml('MSG_TYPE_' + my_lu.lu_name) at: target + {10#px, xpx#px} font: regular color: #white;
					xpx <- xpx + 20;
					draw PLY_MSG_ALTITUDE + " : " + string(round(100*my_lu.mean_alt)/100) + "m" at: target + {10#px, xpx#px} font: regular color: #white;
					xpx <- xpx + 20;
					if my_lu.lu_code in [LU_TYPE_U, LU_TYPE_Us]{
						draw MSG_POPULATION + " : " + my_lu.population at: target + {10#px, xpx#px} font: regular color: #white;
						xpx <- xpx + 20;
						draw MSG_EXPROPRIATION + " : " + my_lu.expro_cost at: target + {10#px, xpx#px} font: regular color: #white;
						xpx <- xpx + 20;
					}
					draw "ID : "+ string(my_lu.id) at: target + {10#px, xpx#px} font: regular color: #white;
					if marked {
						xpx <- xpx + 20;
						draw my_lu.mark.floo1 at: target + {10#px, xpx#px} font: regular color: #lightblue;
						xpx <- xpx + 20;
						draw my_lu.mark.floo2 at: target + {10#px, xpx#px} font: regular color: #lightblue;
					}
				}
			}
			
			// Inspect LU info when the action is not applied yet
			graphics "LU Action Info" {
				if explored_land_use_action !=nil and !explored_land_use_action.is_applied {
					Land_Use_Action my_lu_action <- explored_land_use_action;
					Land_Use mcell 	<- Land_Use first_with(each.id = my_lu_action.element_id);
					point target 	<- {mcell.location.x , mcell.location.y};
					point target2 	<- {mcell.location.x + 1 * (INFORMATION_BOX_SIZE.x#px), mcell.location.y + 1 * (INFORMATION_BOX_SIZE.y#px)};
					
					draw rectangle(target, target2) border: #gold color: #gray;
					draw PLY_MSG_STATE_CHANGE + " (" + mcell.id + ")" at: target + {3#px, 15#px} font: regular color: #yellow;
					draw file("../images/system_icons/player/arrow.png") at: {mcell.location.x + 0.5 * (INFORMATION_BOX_SIZE.x #px), target.y + 50#px} size:50#px;
					draw "" + (my_lu_action.effective_application_round) at: {mcell.location.x + 0.5 * (INFORMATION_BOX_SIZE.x#px), target.y + 55#px} font: regular;
					draw world.get_action_icon(my_lu_action.command) at: {target2.x - 50#px, target.y +50#px} size: 50#px;
					draw world.get_lu_icon(mcell) at: {target.x + 50#px, target.y + 50#px} size: 50#px;
				}
			}
			
			// Display LU history 
			graphics "LU History" {
				if explored_lu != nil and (Button first_with (each.command = ACTION_HISTORY)).is_selected {
					Land_Use my_lu <- explored_lu;
					int xxsize <- length(my_lu.actions_on_me);
					if xxsize > 0 {
						point target  <- {my_lu.location.x, my_lu.location.y};
						point target2 <- {my_lu.location.x + 1 * (INFORMATION_BOX_SIZE.x#px + 80#px), my_lu.location.y + 1 * (INFORMATION_BOX_SIZE.y#px -60#px + (xxsize*20)#px)};
						int xpx <- 15;
						draw rectangle(target,target2) border: #gold color: #gray ;
						draw PLY_MSG_HIST_AB + " : " + PLY_MSG_LAND_USE + " ("+string(my_lu.id)+")" at: target + {3#px, xpx#px} font: regular color: #yellow;
						loop acta over: my_lu.actions_on_me {
							xpx <- xpx + 20;
							draw string(acta.effective_application_round) + " : " +	world.label_of_action(acta.command) at: target + {5#px, xpx#px} font: regular color: #white;
						}
					}
				}
			}
			// locking user interface
			graphics "Lock Window" transparency: 0.3 {
				if(!is_active_gui){
					ask world{do lock_window;}
				}
			}			
			event mouse_down 	action: button_click_general;
			event mouse_move 	action: mouse_move_general;
		}
		// end of "Map" display
		
		display "Messages" background:#black {
			species Message_Left_Icon 	aspect: base;
			species Messages 			aspect: base;
			species Message_Element 	aspect: base;
			species List_of_Elements 	aspect: asp_messages;
			
			graphics "Lock Window" transparency: 0.3 {
				if(!is_active_gui){
					ask world{do lock_window;}
				}
			}
			event mouse_down action: move_down_event_messages;
		}
		
		display "Basket" background:#black {
			species Basket 					aspect: base;
			species Basket_Element  		aspect: base;
			species List_of_Elements 		aspect: asp_basket;
					
			graphics "Lock Window" transparency: 0.3 {
				if(!is_active_gui){
					ask world {do lock_window;}
				}
			}		
			event mouse_down action: move_down_event_basket;
		}
		
		display "History" background:#black {
			species History_Left_Icon 	aspect: base;
			species History 			aspect: base;
			species History_Element  	aspect: base;
			species List_of_Elements	aspect: asp_history;
				
			graphics "Lock Window" transparency: 0.3 {
				if(!is_active_gui){
					ask world{do lock_window;}
				}
			}
			event mouse_down action: move_down_event_history;
		}
 	}
}

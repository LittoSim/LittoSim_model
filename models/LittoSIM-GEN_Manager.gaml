/**
 *  LittoSIM_GEN
 *  Authors: Brice, Cécilia, Elise, Etienne, Fredéric, Marion, Nicolas B, Nicolas M, Xavier 
 * 
 *  Description : LittoSIM_GEN is a participatory simulation platform implementing a serious playing-game for local authorities.
 * 				  The project aims at modeling effects of coastal flooding on urban areas and at enabling the transfer of scientific
 * 				  findings to risk managers, as well as awareness of those concerned by the risk of coastal flooding.
 * 
 * LittoSIM_GEN_Manager : this module reprsents the game manager.
 */

model Manager

import "params_models/params_manager.gaml"

global {
	
	// sea heights file sent to Lisflood
	string my_flooding_path <- "../../includes/" + application_name + "/floodfiles/";
	string lisflood_start_file	<- shapes_def["LISFLOOD_START_FILE"];
	string lisflood_bci_file	<- shapes_def["LISFLOOD_BCI_FILE"];
	string lisflood_bdy_file 	->{floodEventType = HIGH_FLOODING? shapes_def ["LISFLOOD_BDY_HIGH_FILENAME"] // scenario1 : HIGH 
								:(floodEventType  = LOW_FLOODING ? shapes_def ["LISFLOOD_BDY_LOW_FILENAME" ] // scenario2 : LOW
		  						:get_message('MSG_FLOODING_TYPE_PROBLEM'))};
	// paths to Lisflood
	string lisfloodPath 			<- configuration_file["LISFLOOD_PATH"]; 										// absolute path to Lisflood : "C:/lisflood-fp-604/"
	string results_lisflood_rep 	<- "../includes/" + application_name + "/floodfiles/results"; 								// Lisflood results folder
	string lisflood_par_file 		-> {"../includes/" + application_name + "/floodfiles/inputs/" + application_name + "_par" + timestamp + ".par"};   // parameter file
	string lisflood_DEM_file 		-> {"../includes/" + application_name + "/floodfiles/inputs/" + application_name + "_dem" + timestamp + ".asc"}; 					  // DEM file 
	string lisflood_rugosity_file 	-> {"../includes/" + application_name + "/floodfiles/inputs/" + application_name + "_rug" + timestamp + ".asc"}; 					  // rugosity file
	string lisflood_bat_file 		<- "LittoSIM_GEN_Lisflood.bat";												       		  // Lisflood executable
	
	// variables for Lisflood calculs 
	map<string,string> list_flooding_events;  			// list of submersions of a round
	string floodEventType;
	int lisfloodReadingStep <- 9999999; 				// to indicate to which step of Lisflood results, the current cycle corresponds // lisfloodReadingStep = 9999999 it means that there is no Lisflood result corresponding to the current cycle 
	string timestamp 		<- ""; 						// used to specify a unique name to the folder of flooding results
	string flood_results 	<- "";   					// text of flood results per district // saved as a txt file
	list<int> submersions;
	int sub_event <- 0;
	
	// parameters for saving submersion results
	string results_rep 			<- "../includes/"+ application_name +"/floodfiles/stats" + EXPERIMENT_START_TIME; 		// folder to save main model results
	string shape_export_filePath -> {results_rep + "/SHP_Round" + game_round + ".shp"}; 		// shapefile to save cells
	string log_export_filePath 	<- results_rep + "/log_" + machine_time + ".csv"; 					// file to save user actions (main model and players actions)  
	
	// operation variables
	geometry shape <- envelope(convex_hull_shape);	// world geometry
	float EXPERIMENT_START_TIME <- machine_time; 	// machine time at simulation initialization
	int messageID <- 0; 							// network communication
	geometry all_flood_risk_area; 					// geometry agrregating risked area polygons
	geometry all_protected_area; 					// geometry agrregating protected area polygons	
	geometry all_coastal_border_area;				// geometry aggregating coastal border areas
	// budget tables to draw evolution graphs
	list<list<int>> districts_budgets <- [[],[],[],[]];	
	list<list<int>> districts_taxes <- [[],[],[],[]];
	list<list<int>> districts_given_money 	<- [[0],[0],[0],[0]];
	list<list<int>> districts_taken_money 	<- [[0],[0],[0],[0]];
	list<list<int>> districts_transferred_money 	<- [[0],[0],[0],[0]];
	list<list<int>> districts_actions_costs <- [[0],[0],[0],[0]];
	list<list<int>> districts_levers_costs 	<- [[0],[0],[0],[0]];
	// Strategy profiles actions
	list<list<int>> districts_build_strategies 	<- [[0],[0],[0],[0]];
	list<list<int>> districts_soft_strategies 	<- [[0],[0],[0],[0]];
	list<list<int>> districts_withdraw_strategies<- [[0],[0],[0],[0]];
	list<list<int>> districts_neutral_strategies <- [[0],[0],[0],[0]];

	list<list<float>> districts_build_costs 	<- [[0],[0],[0],[0]];
	list<list<float>> districts_soft_costs 	<- [[0],[0],[0],[0]];
	list<list<float>> districts_withdraw_costs<- [[0],[0],[0],[0]];
	list<list<float>> districts_neutral_costs <- [[0],[0],[0],[0]];

	int new_comers_still_to_dispatch <- 0;	// population dynamics
	// other variables 
	bool show_max_water_height	<- false;			// defines if the water_height displayed on the map should be the max one or the current one
	string stateSimPhase 		<- SIM_NOT_STARTED; // state variable of current simulation state 
	int game_round 				<- 0;
	bool game_paused			<- false;
	point play_b;
	point pause_b;
	list<District> districts_in_game;
	bool submersion_is_running <- false;
	
	init{
		// Create GIS agents
		create District from: districts_shape with: [district_code::string(read("dist_code")), dist_id::int(read("player_id"))]; 
		districts_in_game <- (District where (each.dist_id > 0)) sort_by (each.dist_id);
		
		create Coastal_Defense from: coastal_defenses_shape with: [
									coast_def_id::int(read("ID")),type::string(read("type")), status::string(read("status")),
									alt::float(get("alt")), height::float(get("height")), district_code::string(read("dist_code"))];
		
		create Protected_Area from: protected_areas_shape;
		all_protected_area <- union(Protected_Area);
		create Inland_Dike_Area from: buffer_in_100m_shape;
		create Flood_Risk_Area from: rpp_area_shape;
		all_flood_risk_area <- union(Flood_Risk_Area);
		create Road from: roads_shape;
		if isolines_shape != nil {
			create Isoline from: isolines_shape;
		}
		if water_shape != nil {
			create Water from: water_shape;
		}
		
		create Coastal_Border_Area from: coastline_shape { shape <-  shape + coastBorderBuffer#m; }
		all_coastal_border_area <- union(Coastal_Border_Area);
		
		create Land_Use from: land_use_shape with: [id::int(read("ID")), lu_code::int(read("unit_code")), dist_code::string(read("dist_code")), population::int(get("unit_pop"))]{
			lu_name <- lu_type_names[lu_code];
			if lu_name = "U" and population < MIN_POP_AREA {
				population <- MIN_POP_AREA;
			}
			if lu_name in ["AU","AUs"] { // if true, convert all AU and AUs to N
				if AU_AND_AUs_TO_N {
					lu_name <- "N";
					lu_code <- lu_type_names index_of lu_name;
				} else {
					if lu_name = "AU" {
						AU_to_U_counter <- flip(0.5) ? 1 : 0;
						not_updated <- true;
					}
				}
			}
			if lu_name in ['N','A'] { // delete populations of Natural and Agricultural cells
				population <- 0;
			}
			my_color <- cell_color();
		}
		do load_dem_and_rugosity;
		ask Coastal_Defense {
			do init_coastal_def;
		}
		ask Land_Use {
			cells <- Cell overlapping self;
			mean_alt <- cells mean_of(each.soil_height);
		}
		ask districts_in_game{
			district_name <- world.dist_code_sname_correspondance_table at district_code;
			district_long_name <- world.dist_code_lname_correspondance_table at district_code;
			LUs 	<- Land_Use where (each.dist_code = self.district_code);
			cells 	<- LUs accumulate (each.cells);
			tax_unit  <- float(tax_unit_table at district_name);
			budget 	<- int(self.current_population() * tax_unit * (1 + initial_budget));
			write world.get_message('MSG_COMMUNE') + " " + district_name + " (" + district_code + ") " + dist_id + " " + world.get_message('MSG_INITIAL_BUDGET') + ": " + budget;
			do calculate_indicators_t0;
		}
		
		do init_buttons;
		stateSimPhase <- SIM_NOT_STARTED;
		do add_element_in_list_flooding_events (INITIAL_SUBMERSION, results_lisflood_rep);

		create Legend_Planning;
		create Legend_Population;
		create Legend_Map;
		create Legend_Flood;
		create Network_Game_Manager;
		create Network_Listener_To_Leader;
		create Network_Control_Manager;
	}
	//------------------------------ End of init -------------------------------//
	
	action save_user_actions {
		write log_user_action;
	}
	 	
	int getMessageID{
 		messageID <- messageID +1;
 		return messageID;
 	} 
	
	int new_comers_to_dispatch 	 {
		return round(sum(districts_in_game accumulate (each.current_population())) * ANNUAL_POP_GROWTH_RATE);
	}

	action new_round {
		if save_shp  {	do save_cells_as_shp_file;	}
		write get_message('MSG_NEW_ROUND') + " : " + (game_round + 1);
		
		if game_round = 0 { // round 0
			ask districts_in_game{
				add budget to: districts_taxes[dist_id-1];
			}
			stateSimPhase <- SIM_GAME;
			write stateSimPhase;
		}
		else {
			new_comers_still_to_dispatch <- new_comers_to_dispatch();
			ask shuffle(Land_Use){ pop_updated <- false; do evolve_AU_to_U; }
			ask shuffle(Land_Use){ do evolve_pop_U_densification; 			}
			ask shuffle(Land_Use){ do evolve_pop_U_standard; 				} 
			ask districts_in_game{
				// each districts evolves its own coastal defenses
				ask Coastal_Defense where (each.district_code = district_code and each.type = COAST_DEF_TYPE_DIKE) {  do degrade_dike_status; }
		   		ask Coastal_Defense where (each.district_code = district_code and each.type = COAST_DEF_TYPE_DUNE) {  do evolve_dune_status;  }
				
				do calculate_taxes;
				add received_tax to: districts_taxes[dist_id-1];
				
				add round_actions_cost to: districts_actions_costs[dist_id-1];
				add round_given_money to: districts_given_money[dist_id-1];
				add round_taken_money to: districts_taken_money[dist_id-1];
				add round_transferred_money to: districts_transferred_money[dist_id-1];
				add round_levers_cost to: districts_levers_costs[dist_id-1];
				round_actions_cost <- 0.0;
				round_taken_money  <- 0.0;
				round_transferred_money <- 0.0;
				round_given_money  <- 0.0;
				round_levers_cost  <- 0.0;
				
				add round_build_actions to: districts_build_strategies[dist_id-1];
				add round_soft_actions to: districts_soft_strategies[dist_id-1];
				add round_withdraw_actions to: districts_withdraw_strategies[dist_id-1];
				add round_neutral_actions to: districts_neutral_strategies[dist_id-1];
				sum_buil_sof_wit_actions <- sum_buil_sof_wit_actions + round_build_actions
							+ round_soft_actions + round_withdraw_actions;
				round_build_actions <- 0;
				round_soft_actions <- 0;
				round_withdraw_actions <- 0;
				round_neutral_actions <- 0;
				
				add round_build_cost to: districts_build_costs[dist_id-1];
				add round_soft_cost to: districts_soft_costs[dist_id-1];
				add round_withdraw_cost to: districts_withdraw_costs[dist_id-1];
				add round_neutral_cost to: districts_neutral_costs[dist_id-1];
				round_build_cost <- 0.0;
				round_soft_cost <- 0.0;
				round_withdraw_cost <- 0.0;
				round_neutral_cost <- 0.0;
			}
		}
		game_round <- game_round + 1;
		ask Network_Listener_To_Leader {
			do inform_leader_round_number;
		}
		ask districts_in_game{
			do inform_new_round;
			add budget to: districts_budgets[dist_id-1];
		}
		add sub_event to: submersions;
		sub_event <- 0;
		write get_message('MSG_GAME_DONE') + " !";
	} 	
	
	int district_id (string dist_code){
		District d <- first(District first_with (each.district_code = dist_code));
		return d != nil ? d.dist_id : 0;
	}

	reflex show_flood_stats when: stateSimPhase = SIM_SHOWING_FLOOD_STATS {			// end of flooding
		write flood_results;
		save flood_results to: results_rep + "/flood_results-" + machine_time + "-R" + game_round + ".txt" type: "text";
		
		ask Cell {
			water_height <- 0.0; // reset water heights
		} 				
		ask Coastal_Defense {
			if rupture = 1 {
				do remove_rupture; // when want we show ruptures ? (when to remove) !
			}
		}
		do send_flooding_results (nil); // to districts
		stateSimPhase <- SIM_GAME;
		write stateSimPhase + " - " + get_message('MSG_ROUND') + " " + game_round;
	}
	
	reflex calculate_flood_stats when: stateSimPhase = SIM_CALCULATING_FLOOD_STATS{			// end of a flooding event
		do calculate_districts_results; 													// calculating results
		stateSimPhase <- SIM_SHOWING_FLOOD_STATS;
		write stateSimPhase;
	}
	
	reflex show_lisflood when: stateSimPhase = SIM_SHOWING_LISFLOOD{
		do read_lisflood_step_file;  // reading flooding files
	} 
	
	action replay_flood_event (int fe) {
		if fe >= length(list_flooding_events) {
			write "trying to replay a non existing event";
			return;
		}
		string replayed_flooding_event  <- (list_flooding_events.keys)[fe];
		write replayed_flooding_event;
		ask Cell {
			max_water_height <- 0.0;
		} // reset of max_water_height
		lisfloodReadingStep <- 0;
		results_lisflood_rep <- list_flooding_events at replayed_flooding_event;
		stateSimPhase <- SIM_SHOWING_LISFLOOD;
		write stateSimPhase;
	}
		
	action launchFlood_event{
		if game_round = 0 {
			map values <- user_input([(get_message('MSG_SIM_NOT_STARTED'))::true]);
	     	write stateSimPhase;
		}
		else{	// excuting Lisflood
			do new_round;
			ask Cell {
				max_water_height <- 0.0;
			} // reset of max_water_height
			ask Coastal_Defense {
				do calculate_rupture;
			}
			stateSimPhase <- SIM_EXEC_LISFLOOD;
			write stateSimPhase;
			do execute_lisflood;
			lisfloodReadingStep <- 0;
			stateSimPhase 		<- SIM_SHOWING_LISFLOOD;
			write stateSimPhase;
		}
	}

	action add_element_in_list_flooding_events (string sub_name, string sub_rep){
		put sub_rep key: sub_name in: list_flooding_events;
		ask Network_Control_Manager{
			do update_submersion_list;
		}
	}
		
	action execute_lisflood{
		submersion_is_running <- true;
		ask districts_in_game{
			ask Network_Game_Manager { do lock_user (myself, true); }
		}
		timestamp <- "_R" + game_round + "_t" + machine_time;
		results_lisflood_rep <- "../includes/" + application_name + "/floodfiles/results" + timestamp;
		do save_dem_and_rugosity;
		do save_lf_launch_files;
		do add_element_in_list_flooding_events("Submersion round " + game_round , results_lisflood_rep);
		save "Directory created by LittoSIM GAMA model" to: results_lisflood_rep + "/readme.txt" type: "text";// need to create the lisflood results directory because lisflood cannot create it by himself
		ask Network_Game_Manager {
			do execute command: "cmd /c start " + lisfloodPath + lisflood_bat_file;
		}
		submersion_is_running <- false;
		ask districts_in_game{
			ask Network_Game_Manager { do lock_user (myself, false); }
		}
 	}
 		
	action save_lf_launch_files {
		save ("DEMfile         ../" + lisflood_DEM_file + 
				"\nresroot         res\ndirroot         results\nsim_time        52200\ninitial_tstep   10.0\nmassint         100.0\nsaveint         3600.0\nmanningfile     ../" + lisflood_rugosity_file +
				"\nbcifile         " + my_flooding_path + lisflood_bci_file + "\nbdyfile         " + my_flooding_path + lisflood_bdy_file + "\nstartfile       " + my_flooding_path + lisflood_start_file +
				"\nstartelev\nelevoff\nSGC_enable\n") rewrite: true to: lisflood_par_file type: "text";
		
		save ("cd " + lisfloodPath + "\nlisflood.exe -dir " + "../"+ results_lisflood_rep + " ../" + lisflood_par_file + "\nexit") rewrite: true to: lisfloodPath+lisflood_bat_file type: "text";
	}
	
	action load_dem_and_rugosity {
		list<string> dem_data <- [];
		list<string> rug_data <- [];
		//list<string> hill_data <- [];
		file dem_grid <- text_file(dem_file);
		file rug_grid <- text_file(RUGOSITY_DEFAULT);
		//file hill_grid<- text_file(hillshade_file);
		
		DEM_XLLCORNER <- float((dem_grid[2] split_with " ")[1]);
		DEM_YLLCORNER <- float((dem_grid[3] split_with " ")[1]);
		DEM_CELL_SIZE <- int((dem_grid[4] split_with " ")[1]);
		float no_data_value <- float((dem_grid [5] split_with " ")[1]);
		
		loop rw from: 0 to: DEM_NB_ROWS - 1 {
			dem_data <- dem_grid [rw+6] split_with " ";
			rug_data <- rug_grid [rw+6] split_with " ";
			//hill_data <- hill_grid[rw+6] split_with " ";
			loop cl from: 0 to: DEM_NB_COLS - 1 {
				Cell[cl, rw].soil_height <- float(dem_data[cl]);
				Cell[cl, rw].rugosity <- float(rug_data[cl]);
				//Cell[cl, rw].hillshade <- int(hill_data[cl]);
			}
		}
		ask Cell {
			if soil_height > 0 {
				cell_type <-1; //  1 -> land
			} else if soil_height = -9999 {
				cell_type <- -1; // NODATA
				soil_color <- #black;
			}
		}
		land_max_height <- Cell max_of(each.soil_height);
		land_color_interval <- land_max_height / 5;
		cells_max_depth <- abs(min(Cell where (each.cell_type = 0 and each.soil_height != no_data_value) collect each.soil_height));
		ask Cell {
			do init_cell_color;
		}
	}    

	action save_dem_and_rugosity {
		string dem_filename <- lisflood_DEM_file;
		string rug_filename <- lisflood_rugosity_file;
		
		string h_txt <- 'ncols         ' + DEM_NB_COLS + '\nnrows         ' + DEM_NB_ROWS + '\nxllcorner     ' + DEM_XLLCORNER +
						'\nyllcorner     ' + DEM_YLLCORNER + '\ncellsize      ' + DEM_CELL_SIZE + '\nNODATA_value  -9999';
		
		save h_txt rewrite: true to: dem_filename type: "text";
		save h_txt rewrite: true to: rug_filename type: "text";
		string dem_data;
		string rug_data;
		loop rw from: 0 to: DEM_NB_ROWS - 1 {
			dem_data <- "";
			rug_data <- "";
			loop cl from: 0 to: DEM_NB_COLS - 1 {
				dem_data <- dem_data + " " + Cell[cl,rw].soil_height;
				rug_data <- rug_data + " " + Cell[cl,rw].rugosity;
			}
			save dem_data to: dem_filename rewrite: false;
			save rug_data to: rug_filename rewrite: false;
		}
	}
	
	action save_cells_as_shp_file {
		save Cell type:"shp" to: shape_export_filePath with: [soil_height::"SOIL_HEIGHT", water_height::"WATER_HEIGHT"];
	}
	   
	action read_lisflood_step_file {
	 	string nb <- string(lisfloodReadingStep);
		loop i from: 0 to: 3 - length(nb) {
			nb <- "0" + nb;
		}
		string fileName <- results_lisflood_rep + "/res-" + nb + ".wd";
		write "nb " + nb;
		if file_exists (fileName){
			write fileName;
			file lfdata <- text_file(fileName);
			loop r from: 0 to: DEM_NB_ROWS - 1 {
				list<string> res <- lfdata[r+6] split_with "\t";
				loop c from: 0 to: DEM_NB_COLS - 1 {
					float w <- float(res[c]);
					if Cell[c, r].max_water_height < w {
						Cell[c, r].max_water_height <- w;
					}
					Cell[c, r].water_height <- w;
				}
			}	
	        lisfloodReadingStep <- lisfloodReadingStep + 1;
	     }
	     else{ // end of flooding
     		lisfloodReadingStep <-  9999999;
     		if nb = "0000" {
     			map values <- user_input([(get_message('MSG_NO_FLOOD_FILE_EVENT')) :: ""]);
     			stateSimPhase <- SIM_GAME;
     			write stateSimPhase + " - "+ get_message('MSG_ROUND') +" "+ game_round;
     		}
     		else {
     			stateSimPhase <- SIM_CALCULATING_FLOOD_STATS;
     			write stateSimPhase;
     			sub_event <- max(districts_budgets accumulate each);
     		}
     	}
	}
	
	// sending flood results to players
	action send_flooding_results (District d){
		write "Sending flood results to players ...";
		if d != nil {
			do send_flooding_results_to_district(d);
		} else{
			loop dd over: districts_in_game{
     			do send_flooding_results_to_district (dd);
     		}
		}
     	write "Flooding results sent!";
	}
	
	action send_flooding_results_to_district (District d){
		map<string,string> nmap <- ["TOPIC"::"NEW_SUBMERSION_EVENT"];
		map<string,string> mp <- ["TOPIC"::"NEW_FLOODED_CELLS"];
		string my_district <- d.district_code;
		
		list<Cell> my_flooded_cells <- d.cells where(each.max_water_height > 0);
		add string(length(my_flooded_cells)) at: "flooded_cells" to: nmap;
		add string(Cell[0].shape.width) at: "cell_width" to: nmap;
 		add string(Cell[0].shape.height) at: "cell_height" to: nmap;
 		ask Network_Game_Manager{
			do send to: my_district contents: nmap;
		}
		int i <- 0;
 		ask my_flooded_cells {
			add string(shape.location.x) at: "cell_location_x"+i to: mp;
			add string(shape.location.y) at: "cell_location_y"+i to: mp;
			add string(max_water_height) at: "water_height"+i to: mp;
			i <- i + 1;
 		}
 		ask Network_Game_Manager{
			do send to: my_district contents: mp;
		}
	}
	
	action calculate_districts_results {
		string text <- "";
			ask districts_in_game {
				int tot <- length(cells);
				int myid <-  self.dist_id; 
				int U_0_5 <-0;		int U_1 <-0;		int U_max <-0;
				int Us_0_5 <-0;		int Us_1 <-0;		int Us_max <-0;
				int Udense_0_5 <-0;	int Udense_1 <-0;	int Udense_max <-0;
				int AU_0_5 <-0;		int AU_1 <-0;		int AU_max <-0;
				int A_0_5 <-0;		int A_1 <-0;		int A_max <-0;
				int N_0_5 <-0;		int N_1 <-0;		int N_max <-0;
				
				ask LUs{
					ask cells where (each.max_water_height > 0) {
						switch myself.lu_name{ //"U","Us","AU","N","A"    -> but not  "AUs"
							match "AUs" {
								write "STOP :  AUs " + world.get_message('MSG_IMPOSSIBLE_NORMALLY');
							}
							match "U" {
								if max_water_height <= 0.5 {
									U_0_5 <- U_0_5 +1;
									if myself.density_class = POP_DENSE { Udense_0_5 <- Udense_0_5 +1; }
								}
								else if between (max_water_height ,0.5, 1.0) {
									U_1 <- U_1 +1;
									if myself.density_class = POP_DENSE { Udense_1 <- Udense_1 +1; }
								}
								else{
									U_max <- U_max +1;
									if myself.density_class = POP_DENSE { Udense_0_5 <- Udense_0_5 +1; }
								}
							}
							match "Us" {
								if max_water_height <= 0.5 { Us_0_5 <- Us_0_5 +1; }
								else if between (max_water_height ,0.5, 1.0) { Us_1 <- Us_1 +1; }
								else { Us_max <- Us_max +1; }
							}
							match "AU" {
								if max_water_height <= 0.5 { AU_0_5 <- AU_0_5 +1; }
								else if between (max_water_height ,0.5, 1.0) { AU_1 <- AU_1 +1; }
								else { AU_max <- AU_max +1; }
							}
							match "N"  {
								if max_water_height <= 0.5 { N_0_5 <- N_0_5 +1; }
								else if between (max_water_height ,0.5, 1.0) { N_1 <- N_1 +1; }
								else { N_max <- N_max +1; }
							}
							match "A" {
								if max_water_height <= 0.5 { A_0_5 <- A_0_5 +1; }
								else if between (max_water_height ,0.5, 1.0) { A_1 <- A_1 +1; }
								else { A_max <- A_max +1; }
							}
						}
					}
				}
				
				prev_U_0_5c <- U_0_5c;
				prev_U_1c <- U_1c;
				prev_U_maxc <- U_maxc;
				prev_Us_0_5c <- Us_0_5c;
				prev_Us_1c <- Us_1c;
				prev_Us_maxc <- Us_maxc;
				prev_Udense_0_5c <- Udense_0_5c;
				prev_Udense_1c <- Udense_1c;
				prev_Udense_maxc <- Udense_maxc;
				prev_AU_0_5c <- AU_0_5c;
				prev_AU_1c <- AU_1c;
				prev_AU_maxc <- AU_maxc;
				prev_A_0_5c <- A_0_5c;
				prev_A_1c <- A_1c;
				prev_A_maxc <- A_maxc;
				prev_N_0_5c <- N_0_5c;
				prev_N_1c <- N_1c;
				prev_N_maxc <- N_maxc;
				
				U_0_5c <- U_0_5 * 0.04;
				U_1c <- U_1 * 0.04;
				U_maxc <- U_max * 0.04;
				Us_0_5c <- Us_0_5 * 0.04;
				Us_1c <- Us_1 * 0.04;
				Us_maxc <- Us_max * 0.04;
				Udense_0_5c <- Udense_0_5 * 0.04;
				Udense_1c <- Udense_1 * 0.04;
				Udense_maxc <- Udense_max * 0.04;
				AU_0_5c <- AU_0_5 * 0.04;
				AU_1c <- AU_1 * 0.04;
				AU_maxc <- AU_max * 0.04;
				A_0_5c <- A_0_5 * 0.04;
				A_1c <- A_1 * 0.04;
				A_maxc <- A_max * 0.04;
				N_0_5c <- N_0_5 * 0.04;
				N_1c <- N_1 * 0.04;
				N_maxc <- N_max * 0.04;
				text <- text + "Results for district : " + district_name +"
Flooded U : < 50cm " + ((U_0_5c) with_precision 1) +" ha ("+ ((U_0_5 / tot * 100) with_precision 1) +"%) | between 50cm and 1m " + ((U_1c) with_precision 1) +" ha ("+ ((U_1 / tot * 100) with_precision 1) +"%) | > 1m " + ((U_maxc) with_precision 1) +" ha ("+ ((U_max / tot * 100) with_precision 1) +"%) 
Flooded Us : < 50cm " + ((Us_0_5c) with_precision 1) +" ha ("+ ((Us_0_5 / tot * 100) with_precision 1) +"%) | between 50cm and 1m " + ((Us_1c) with_precision 1) +" ha ("+ ((Us_1 / tot * 100) with_precision 1) +"%) | > 1m " + ((Us_maxc) with_precision 1) +" ha ("+ ((Us_max / tot * 100) with_precision 1) +"%) 
Flooded Udense : < 50cm " + ((Udense_0_5c) with_precision 1) +" ha ("+ ((Udense_0_5 / tot * 100) with_precision 1) +"%) | between 50cm and 1m " + ((Udense_1 * 0.04) with_precision 1) +" ha ("+ ((Udense_1 / tot * 100) with_precision 1) +"%) | > 1m " + ((Udense_max * 0.04) with_precision 1) +" ha ("+ ((Udense_max / tot * 100) with_precision 1) +"%) 
Flooded AU : < 50cm " + ((AU_0_5c) with_precision 1) +" ha ("+ ((AU_0_5 / tot * 100) with_precision 1) +"%) | between 50cm and 1m " + ((AU_1c) with_precision 1) +" ha ("+ ((AU_1 / tot * 100) with_precision 1) +"%) | > 1m " + ((AU_maxc) with_precision 1) +" ha ("+ ((AU_max / tot * 100) with_precision 1) +"%) 
Flooded A : < 50cm " + ((A_0_5c) with_precision 1) +" ha ("+ ((A_0_5 / tot * 100) with_precision 1) +"%) | between 50cm and 1m " + ((A_1c) with_precision 1) +" ha ("+ ((A_1 / tot * 100) with_precision 1) +"%) | > 1m " + ((A_maxc) with_precision 1) +" ha ("+ ((A_max / tot * 100) with_precision 1) +"%) 
Flooded N : < 50cm " + ((N_0_5c) with_precision 1) +" ha ("+ ((N_0_5 / tot * 100) with_precision 1) +"%) | between 50cm and 1m " + ((N_1c) with_precision 1) +" ha ("+ ((N_1 / tot * 100) with_precision 1) +"%) | > 1m " + ((N_maxc) with_precision 1) +" ha ("+ ((N_max / tot * 100) with_precision 1) +"%) 
--------------------------------------------------------------------------------------------------------------------
";	
			}
			flood_results <-  text;
				
			write get_message('MSG_FLOODED_AREA_DISTRICT');
			ask districts_in_game {
				flooded_area <- (U_0_5c + U_1c + U_maxc + Us_0_5c + Us_1c + Us_maxc + AU_0_5c + AU_1c + AU_maxc + N_0_5c + N_1c + N_maxc + A_0_5c + A_1c + A_maxc) with_precision 1;
				add flooded_area to: data_flooded_area; 
				write ""+ district_name + " : " + flooded_area +" ha";

				totU <- (U_0_5c + U_1c + U_maxc) with_precision 1;
				totUs <- (Us_0_5c + Us_1c + Us_maxc ) with_precision 1;
				totUdense <- (Udense_0_5c + Udense_1c + Udense_maxc) with_precision 1;
				totAU <- (AU_0_5c + AU_1c + AU_maxc) with_precision 1;
				totN <- (N_0_5c + N_1c + N_maxc) with_precision 1;
				totA <-  (A_0_5c + A_1c + A_maxc) with_precision 1;	
				add totU to: data_totU;
				add totUs to: data_totUs;
				add totUdense to: data_totUdense;
				add totAU to: data_totAU;
				add totN to: data_totN;
				add totA to: data_totA;	
			}
	}
	
	// creating buttons
 	action init_buttons{
		create Button{
			nb_button 	<- 0;
			command  	<- ONE_STEP;
			location 	<- {1000, 1000};
			my_icon 	<- image_file("../images/icons/one_step.png");
			display_text <- world.get_message('MSG_NEW_ROUND');
		}
		create Button{
			nb_button 	<- 1;
			command  	<- LOCK_USERS;
			location 	<- {1000, 3000};
			my_icon 	<- image_file("../images/icons/pause.png");
			display_text <- world.get_message('MSG_PAUSE_GAME');
			pause_b <- self.location;
		}
		create Button{
			nb_button 	<- 2;
			command  	<- UNLOCK_USERS;
			location 	<- { 1000, 5000 };
			my_icon 	<- image_file("../images/icons/play.png");
			display_text <- world.get_message('MSG_RESUME_GAME');
			play_b <- self.location;
		}
		create Button{
			nb_button 	<- 3;
			command	 	<- HIGH_FLOODING;
			location 	<- {4500, 1000};
			my_icon 	<- image_file("../images/icons/launch_lisflood.png");
			display_text <- world.get_message('MSG_HIGH_FLOODING');
		}
		create Button{
			nb_button 	<- 5;
			command	 	<- LOW_FLOODING;
			location 	<- {7500, 1000};
			my_icon 	<- image_file("../images/icons/launch_lisflood_small.png");
			display_text <- world.get_message('MSG_LOW_FLOODING');
		}
		create Button{
			nb_button 	<- 6;
			command  	<- "0";
			location 	<- {11000, 1000};
			my_icon 	<- image_file("../images/icons/0.png");
			display_text <- world.get_message('MSG_REPLY_SUBMERSION') + " " + command;
		}
		create Button{
			nb_button 	<- 6;
			command  	<- "1";
			location 	<- {11000, 3000};
			my_icon 	<- image_file("../images/icons/1.png");
			display_text <- world.get_message('MSG_REPLY_SUBMERSION') + " " + command;
		}
		create Button {
			nb_button 	<- 6;
			command  	<- "2";
			location 	<- {11000, 5000};
			my_icon 	<- image_file("../images/icons/2.png");
			display_text <- world.get_message('MSG_REPLY_SUBMERSION') + " " + command;
		}
		create Button{
			nb_button 	<- 6;
			command  	<- "3";
			location 	<- {11000, 7000};
			my_icon 	<- image_file("../images/icons/3.png");
			display_text <- world.get_message('MSG_REPLY_SUBMERSION') + " " + command;
		}
		create Button{
			nb_button 	<- 6;
			command  	<- "4";
			location 	<- {11000, 9000};
			my_icon 	<- image_file("../images/icons/4.png");
			display_text <- world.get_message('MSG_REPLY_SUBMERSION') + " " + command;
		}
		
		create Button{
			nb_button 	<- 4;
			command  	<- SHOW_LU_GRID;
			shape 		<- square(800);
			my_icon 	<- image_file("../images/icons/avec_quadrillage.png");
			is_selected <- false;
			location <- LEGEND_POSITION = 'topleft' ? {800, 800} : {800, 13800};
		}
		create Button{
			nb_button 	<- 7;
			command	 	<- SHOW_MAX_WATER_HEIGHT;
			shape 		<- square(800);
			my_icon 	<- image_file("../images/icons/max_water_height.png");
			is_selected <- false;
			location 	<- LEGEND_POSITION = 'topleft' ? {1800, 800} : {1800, 13800};
		}
	}
	
	// the four buttons of game master control display 
    action button_click_master_control{
		point loc <- #user_location;
		list<Button> buttonsMaster <- (Button where (each.nb_button in [0,1,2,3,5,6] and each overlaps loc));
		if(length(buttonsMaster) > 0){
			ask Button { self.is_selected <- false;	}
			ask(buttonsMaster){
				is_selected <- true;
				switch nb_button 	{
					match 0   		{
						is_selected <- true;
						ask world {	do new_round; }
					}
					match 1			{
						if !game_paused {
							ask Network_Control_Manager{ do lock_user_window(true);  }
							write "Locking users request sent!";
							game_paused <- true;
							is_selected <- true;
						}
					}
					match 2	{
						if game_paused {	
							ask Network_Control_Manager{ do lock_user_window(false);  }
							write "Unlocking users request sent!";
							game_paused <- false;
							is_selected <- true;
						}
					}
					match_one [3, 5]{
						is_selected <- true;
						floodEventType <- command;
						ask world   { do launchFlood_event; }
					}
					match 6			{
						if int(command) < length(list_flooding_events) {
							is_selected <- true;
							ask world { do replay_flood_event(int(myself.command));}
						}
					}
				}
			}
		}
	}
	
	// the two buttons of the first map display
	action button_click_map {
		point loc <- #user_location;
		Button a_button <- first((Button where (each.nb_button in [4,7] and each overlaps loc)));
		if a_button != nil{
			ask a_button {
				is_selected <- !is_selected;
				if(a_button.nb_button = 4){
					my_icon	<-  is_selected ? image_file("../images/icons/sans_quadrillage.png") : image_file("../images/icons/avec_quadrillage.png");
				}else if(a_button.nb_button = 7){
					show_max_water_height <- is_selected;
				}
			}
		}
	}
}
//------------------------------ End of world global -------------------------------//

species Network_Game_Manager skills: [network]{
	
	init{
		write world.get_message('MSG_START_SENDER');
		do connect to: SERVER with_name: GAME_MANAGER;
	}
	
	reflex wait_message {
		loop while: has_more_message(){
			message msg <- fetch_message();
			string m_sender <- msg.sender;
			map<string, unknown> m_contents <- msg.contents;
			if m_sender != GAME_MANAGER {
				int id_dist <- world.district_id (m_sender);
				switch m_contents["REQUEST"] {
				match string(REFRESH_ALL){
					// a player asks to refresh his GUI
					write "Refreshing ALL ! " + id_dist + " " + m_sender;
					do send_data_to_district(first(District where(each.dist_id = id_dist)));
				}
				match string(CONNECTION_MESSAGE) { // a client district wants to connect
					ask(District where(each.dist_id = id_dist)){
						do inform_current_round;
						do inform_budget_update;
						do inform_LU_alts;
						write world.get_message('MSG_CONNECTION_FROM') + " " + m_sender + " " + district_name + " (" + id_dist + ")";
					}
				}
				match NEW_DIKE_ALT {
					geometry new_tmp_dike <- polyline([{float(m_contents["origin.x"]), float(m_contents["origin.y"])},
															{float(m_contents["end.x"]), float(m_contents["end.y"])}]);
					//float altit <- (Cell overlapping new_tmp_dike) max_of(each.soil_height);
					float altit <- (Cell overlapping new_tmp_dike) mean_of(each.soil_height);
					ask Network_Game_Manager{
						map<string,string> mpp <- ["TOPIC"::NEW_DIKE_ALT];
						put string(altit)  		at: "altit" 	in: mpp;
						put m_contents["act_id"] at: "act_id" in: mpp;
						do send to: m_sender contents: mpp;
					}
				}
				match PLAYER_ACTION {  // another player action
				if(game_round > 0) {
					write world.get_message('MSG_READ_ACTION') + " : " + m_contents;
					if(int(m_contents["command"]) in ACTION_LIST) {
						create Player_Action {
							self.command 					<- int(m_contents["command"]);
							self.command_round  			<- game_round; 
							self.act_id 						<- m_contents["id"];
							self.initial_application_round 	<- int(m_contents["initial_application_round"]);
							self.district_code 				<- m_sender;
							self.element_id 				<- int(m_contents["element_id"]);
							self.action_type 				<- m_contents["action_type"];
							self.is_in_protected_area 		<- bool(m_contents["is_in_protected_area"]);
							self.previous_lu_name 			<- m_contents["previous_lu_name"];
							self.is_expropriation 			<- bool(m_contents["is_expropriation"]);
							self.cost 						<- float(m_contents["cost"]);
							if command in [ACTION_CREATE_DIKE, ACTION_CREATE_DUNE] { 
								element_shape 	 <- polyline([{float(m_contents["origin.x"]), float(m_contents["origin.y"])},
															{float(m_contents["end.x"]), float(m_contents["end.y"])}]);
								shape 			 <- element_shape;
								length_coast_def <- int(element_shape.perimeter);
								location 		 <- {float(m_contents["location.x"]),float(m_contents["location.y"])}; 
							}
							else{
								if is_expropriation { write world.get_message('MSG_EXPROPRIATION_TRIGGERED') + " " + self.act_id; }
								switch self.action_type {
									match PLAYER_ACTION_TYPE_LU {
										Land_Use tmp  	<- Land_Use first_with (each.id = self.element_id);
										element_shape 	<- tmp.shape;
										location 		<- tmp.location;
									}
									match PLAYER_ACTION_TYPE_COAST_DEF {
										element_shape 	 <- (Coastal_Defense first_with(each.coast_def_id = self.element_id)).shape;
										length_coast_def <- int(element_shape.perimeter);
									}
									default { write world.get_message('MSG_ERROR_PLAYER_ACTION'); }
								}
							}
							if  self.element_shape intersects all_flood_risk_area 		 {	is_in_risk_area 		<- true;	}
							if  self.element_shape intersects all_coastal_border_area    {	is_in_coast_border_area <- true;	}
							if  self.element_shape intersects all_protected_area 		 {	is_in_protected_area 	<- true;	}
							if command = ACTION_CREATE_DIKE and (self.element_shape.centroid overlaps first(Inland_Dike_Area))	{	is_inland_dike <- true;	}
							if(log_user_action){
								save ([string(machine_time - EXPERIMENT_START_TIME), self.district_code] + m_contents.values) to: log_export_filePath rewrite: false type:"csv";
							}
							ask districts_in_game first_with(each.dist_id = world.district_id (self.district_code)) {
								budget <- int(budget - myself.cost);	// updating players payment (server side)
								round_actions_cost <- round_actions_cost - myself.cost;
							}
						} // end of create Player_Action
					}
				}
				}
				}			
			}				
		}
	}

	reflex apply_player_action when: length(Player_Action where (each.is_alive)) > 0{
		ask Player_Action where (each.is_alive){
			if self.should_be_applied and !self.should_wait_lever_to_activate {
				int id_dist <- world.district_id (district_code);
				bool acknowledge <- false;
				switch command {
					match_one [ACTION_CREATE_DIKE, ACTION_CREATE_DUNE]{	
						ask create_dike (self, command) {
							do build_coast_def;
							acknowledge <- true;
						}
					}
					match ACTION_REPAIR_DIKE {
						Coastal_Defense cd <- Coastal_Defense first_with(each.coast_def_id = element_id);
						if cd != nil {
							ask cd {
								do repaire_dike;
								not_updated <- true;
								acknowledge <- true;
							}
						}
						
					}
				 	match ACTION_DESTROY_DIKE {
				 		Coastal_Defense cd <- Coastal_Defense first_with(each.coast_def_id = element_id);
						if cd != nil {
							ask cd {
								not_updated <- true;
								acknowledge <- true;
								do destroy_coast_def;
							
							}
						}		
					}
				 	match ACTION_RAISE_DIKE {
				 		Coastal_Defense cd <- Coastal_Defense first_with(each.coast_def_id = element_id);
						if cd != nil {
							ask cd {
								do raise_dike;
								not_updated <- true;
								acknowledge <- true;	
							}
						}
					}
					match ACTION_INSTALL_GANIVELLE {
					 	Coastal_Defense cd <- Coastal_Defense first_with(each.coast_def_id = element_id);
						if cd != nil {
							ask cd {
								do install_ganivelle;
								not_updated <- true;
								acknowledge <- true;
								
							}
						}
					}
					match_one [ACTION_MODIFY_LAND_COVER_A, ACTION_MODIFY_LAND_COVER_AU, ACTION_MODIFY_LAND_COVER_N,
								ACTION_MODIFY_LAND_COVER_Us, ACTION_MODIFY_LAND_COVER_AUs] {
						Land_Use luse <- Land_Use first_with(each.id = element_id);
						if luse != nil {
							ask luse {
					 			do modify_LU (world.lu_name_of_command(myself.command));
					 		  	not_updated <- true;
					 		  	acknowledge <- true;
					 		  	
					 		}
				 		}
					}
				 	match ACTION_MODIFY_LAND_COVER_Ui {
				 		Land_Use luse <- Land_Use first_with(each.id = element_id);
						if luse != nil {
							ask luse {
					 			is_in_densification <- true;
					 		 	not_updated <- true;
					 		 	acknowledge <- true;	
					 		 }
				 		 }
				 	 }
				}
				if acknowledge {
					ask Network_Game_Manager { do acknowledge_application_of_player_action(myself); }
				}
				is_alive 	<- false; 
				is_applied 	<- true;
			}
		}		
	}
	
	action acknowledge_application_of_player_action (Player_Action act){
		map<string,string> msg <- ["TOPIC"::PLAYER_ACTION_IS_APPLIED,"id"::act.act_id];
		do send to: act.district_code contents: msg;
	}
	
	reflex update_LU when: length (Land_Use where(each.not_updated)) > 0 {
		string msg <- "";
		ask Land_Use where(each.not_updated) {
			map<string,string> msg <- ["TOPIC"::ACTION_LAND_COVER_UPDATE, "id"::id, "lu_code"::lu_code,
							"population"::population, "is_in_densification"::is_in_densification];
			not_updated <- false;
			ask myself {
				do send to: myself.dist_code contents: msg;
			}
		}
	}
	
	reflex update_coast_def when: length (Coastal_Defense where(each.not_updated)) > 0 {
		map<string,string> msg;
		point p1	<- nil;
		point p2	<- nil;
		ask Coastal_Defense where(each.not_updated){
			p1 	<- first(self.shape.points);
			p2 	<- last(self.shape.points);
			msg <- ["TOPIC"::ACTION_DIKE_UPDATE, "coast_def_id"::coast_def_id,
				 "p1.x"::p1.x, "p1.y"::p1.y, "p2.x"::p2.x, "p2.y"::p2.y,
				 "height"::height, "type"::type, "status"::status,
				 "ganivelle"::ganivelle, "alt"::alt];
			not_updated <- false;
			ask myself{
				do send to: myself.district_code contents: msg;
			}
		}
	}
	
	action send_data_to_district (District d){
		write world.get_message('MSG_SEND_DATA_TO') + " " + d.district_code;
		ask d {
			do inform_budget_update();
		}
		loop tmp over: Coastal_Defense where(each.district_code = d.district_code){
			map<string, string> mp <- tmp.build_map_from_coast_def_attributes();
			put DATA_RETRIEVE at: "TOPIC" in: mp;
			do send to: d.district_code contents: mp;
		}
		loop tmp over: d.LUs{
			map<string, string> mp <- tmp.build_map_from_lu_attributes();
			put DATA_RETRIEVE at: "TOPIC" in: mp;
			do send to: d.district_code contents: mp;
		}
		loop tmp over: Player_Action where(each.district_code = d.district_code){
			map<string, string> mp <- tmp.build_map_from_action_attributes();
			put DATA_RETRIEVE at: "TOPIC" in: mp;
			do send to: d.district_code contents: mp;
		}
		loop tmp over: Activated_Lever where(each.my_map[DISTRICT_CODE] = d.district_code) {
			map<string, string> mp <- tmp.my_map;
			put DATA_RETRIEVE at: "TOPIC" in: mp;
			do send to: d.district_code contents: mp;
		}
		if flood_results != "" {
			ask world{
				do send_flooding_results (d);	
			}
		}
		
	}
	
	action lock_user (District d, bool lock){ // lock or unlock the player GUI
		string val <- lock = true? "LOCK":"UNLOCK";
		map<string,string> mp <- ["OBJECT_TYPE" ::OBJECT_TYPE_WINDOW_LOCKER,
								  "LOCK_REQUEST"::val, "TOPIC"::DATA_RETRIEVE];
		do send to: d.district_code contents: mp;
	}
}
//------------------------------ End of Network_Game_Manager -------------------------------//

species Network_Control_Manager skills:[remoteGUI]{
	list<string> mtitle 	 <- list_flooding_events.keys;
	list<string> mfile 		 <- [];
	string chosen_simu_temp  <- nil;
	string choice_simulation <- INITIAL_SUBMERSION;
	int mround 				 <- 0 update: world.game_round;
	string selected_action;
	 
	init{
		do connect to: SERVER;
		do expose variables: ["mtitle","mfile"] with_name:	"listdata";
		do expose variables: ["mround"] 		with_name:	"current_round";
		do listen with_name: "chosen_simu" 		store_to:	"chosen_simu_temp";
		do listen with_name: "littosim_command" store_to:	"selected_action";
		do update_submersion_list;
	}
	
	action update_submersion_list {
		loop a over: list_flooding_events.keys{
			mtitle 	<- mtitle + a;
			mfile 	<- mfile + (list_flooding_events at a);
		}
	}
	
	reflex selected_action when: selected_action != nil{
		write "Network_Control_Manager " + selected_action;
		switch(selected_action){
			match NEW_ROUND 	{ ask world { do new_round;}	}
			match LOCK_USERS 	{ do lock_user_window(true);  }
			match UNLOCK_USERS 	{ do lock_user_window(false); }
			match_one [HIGH_FLOODING, LOW_FLOODING] {
				floodEventType <- selected_action;
				ask world {	do launchFlood_event;	}
			}
		}
		selected_action <- nil;
	}
	
	reflex show_submersion when: chosen_simu_temp != nil{
		write "Network_Control_Manager : " + world.get_message('MSG_SIMULATION_CHOICE') + " " + chosen_simu_temp;
		choice_simulation 	<- chosen_simu_temp;
		chosen_simu_temp 	<-nil;
	}
	
	action lock_user_window (bool value){
		ask District{
			ask Network_Game_Manager { do lock_user (myself, value); }
		}
	}
}
//------------------------------ End of Network_Control_Manager -------------------------------//

species Network_Listener_To_Leader skills:[network]{
	
	init{	do connect to: SERVER with_name: LISTENER_TO_LEADER;	}
	
	reflex wait_message {
		loop while: has_more_message(){
			message msg <- fetch_message();
			map<string, unknown> m_contents <- msg.contents;
			string cmd <- m_contents[LEADER_COMMAND];
			write "Leader command : " + cmd;
			switch cmd {
				match EXCHANGE_MONEY {
					int money <- int(m_contents[AMOUNT]);
					ask districts_in_game first_with(each.district_code = m_contents[DISTRICT_CODE]) {
						budget 	<- budget - money;
						round_transferred_money <- round_transferred_money - money;
					}
					ask districts_in_game first_with(each.district_code = m_contents["TARGET_DIST"]) {
						budget 	<- budget + money;
						round_transferred_money <- round_transferred_money + money;
					}
				}
				match GIVE_MONEY_TO {
					int money <- int(m_contents[AMOUNT]);
					ask districts_in_game first_with(each.district_code = m_contents[DISTRICT_CODE]) {
						budget 	<- budget + money;
						round_given_money <- round_given_money + money;
					}
				}
				match TAKE_MONEY_FROM {
					int money <- int(m_contents[AMOUNT]);
					ask districts_in_game first_with(each.district_code = m_contents[DISTRICT_CODE]){
						budget <- budget - money;
						round_taken_money <- round_taken_money - money;
					}
				}
				match ASK_NUM_ROUND 		 {	do inform_leader_round_number;	}
				match ASK_INDICATORS_T0 	 {	do inform_leader_indicators_t0;	}
				match ASK_ACTION_STATE  	 {
					ask Player_Action { is_sent_to_leader <- false; }
				}
				match ACTION_SHOULD_WAIT_LEVER_TO_ACTIVATE {
					Player_Action act <- Player_Action first_with (each.act_id = string(m_contents[PLAYER_ACTION_ID]));
					write "Action : " + act;
					if act!= nil {
						act.should_wait_lever_to_activate <- bool (m_contents[ACTION_SHOULD_WAIT_LEVER_TO_ACTIVATE]);
						write "Waiting for a lever : " + act.should_wait_lever_to_activate;	
					}	
				}
				match NEW_ACTIVATED_LEVER {
					if empty(Activated_Lever where (int(each.my_map["id"]) = int(m_contents["id"]))){
						create Activated_Lever{
							do init_activ_lever_from_map (m_contents);
							int money <- int(my_map["added_cost"]);
							ask districts_in_game first_with (each.district_code = my_map[DISTRICT_CODE]) {
								budget <- budget - money;
								round_levers_cost <- round_levers_cost - money;
							}
							ply_action <- Player_Action first_with (each.act_id = my_map["p_action_id"]);
							if ply_action != nil {
								add self to: ply_action.activated_levers;
								ply_action.a_lever_has_been_applied <- true;
							}
						}
					}
				}
				match NEW_REQUESTED_ACTION {
					ask districts_in_game first_with(each.district_code = m_contents[DISTRICT_CODE]){
						float money <- float(m_contents["cost"]);
						switch m_contents[STRATEGY_PROFILE]{
							match BUILDER 		{
								round_build_actions <- round_build_actions + 1;
								round_build_cost <- round_build_cost + money;
							}
							match SOFT_DEFENSE 	{
								round_soft_actions <- round_soft_actions + 1;
								round_soft_cost <- round_soft_cost + money;
							}
							match WITHDRAWAL 	{
								round_withdraw_actions <- round_withdraw_actions + 1;
								round_withdraw_cost <- round_withdraw_cost + money;
							}
							match NEUTRAL 		{
								round_neutral_actions <- round_neutral_actions + 1;
								round_neutral_cost <- round_neutral_cost + money;
							}
						}
					}
				}
			}	
		}
	}
	
	reflex inform_leader_action_state when: cycle mod 10 = 0 {
		loop act over: Player_Action where (!each.is_sent_to_leader){
			map<string,string> msg <- act.build_map_from_action_attributes();
			put ACTION_STATE 			key: RESPONSE_TO_LEADER in: msg;
			do send to: GAME_LEADER 	contents: msg;
			act.is_sent_to_leader <- true;
			write "" + world.get_message('MSG_SEND_TO_LEADER') + " : " + msg;
		}
	}
	
	action inform_leader_round_number {
		map<string,string> msg <- [];
		put NUM_ROUND 			key: RESPONSE_TO_LEADER in: msg;
		put string(game_round) 	key: NUM_ROUND in: msg;
		ask districts_in_game {
			put string(budget)  key: district_code	in: msg;
		}
		do send to: GAME_LEADER contents: msg;
	}
				
	action inform_leader_indicators_t0  {
		ask districts_in_game {
			map<string,string> msg <- self.my_indicators_t0;
			put INDICATORS_T0 		key: RESPONSE_TO_LEADER 	in: msg;
			put district_code 		key: DISTRICT_CODE 			in: msg;
			ask myself {
				do send to: GAME_LEADER contents: msg;
			}
		}		
	}
}
//------------------------------ End of Network_Listener_To_Leader -------------------------------//

species Activated_Lever {
	Player_Action ply_action;
	map<string, string> my_map <- []; // contains attributes sent through network
	
	action init_activ_lever_from_map (map<string, string> m ){
		my_map <- m;
		put OBJECT_TYPE_ACTIVATED_LEVER at: "OBJECT_TYPE" in: my_map;
	}
}
//------------------------------ End of Activated_lever -------------------------------//

species Player_Action schedules:[]{
	string act_id;
	int element_id;
	geometry element_shape;
	int length_coast_def	<-0;
	string district_code 	<- "";
	int command 			<- -1 on_change: { label <- world.label_of_action(command); };
	int command_round		<- 	-1;
	string label 			<- "";
	int initial_application_round <- -1;
	int round_delay 			  -> {activated_levers sum_of int (each.my_map["added_delay"])};
	int actual_application_round  -> {initial_application_round + round_delay};
	bool is_delayed 			  -> { round_delay >0 };
	float cost 			<- 0.0;
	int added_cost  	-> {activated_levers sum_of int(each.my_map["added_cost"])};
	float actual_cost 	-> {cost + added_cost};
	bool has_added_cost -> {added_cost > 0};
	bool is_sent 			<- true;
	bool is_sent_to_leader 	<- false;
	bool is_applied 		<- false;
	bool should_be_applied	-> {game_round >= actual_application_round};
	string action_type 		<- PLAYER_ACTION_TYPE_COAST_DEF;	// can be "COAST_DEF" or "LU"
	string previous_lu_name <-"";  								// for LU action
	bool is_expropriation 				<- false; 				// for LU action
	bool is_in_protected_area 			<- false; 				// for COAST_DEF action
	bool is_in_coast_border_area	 	<- false; 				// for LU action  // 400m to coast line
	bool is_in_risk_area 				<- false; 				// for LU action  // risk read = rpp.shp
	bool is_inland_dike					<- false; 				// for COAST_DEF action // retro dikes
	bool is_alive 						<- true;
	bool should_wait_lever_to_activate  <- false;
	bool a_lever_has_been_applied		<- false;
	list<Activated_Lever> activated_levers <-[];

	map<string,string> build_map_from_action_attributes{
		map<string,string> res <- [
			"OBJECT_TYPE"::OBJECT_TYPE_PLAYER_ACTION,
			"id"::act_id,
			"element_id"::string(element_id),
			"command"::string(command),
			"cost"::string(cost),
			"initial_application_round"::string(initial_application_round),
			"is_inland_dike"::string(is_inland_dike),
			"is_in_risk_area"::string(is_in_risk_area),
			"is_in_coast_border_area"::string(is_in_coast_border_area),
			"is_expropriation"::string(is_expropriation),
			"is_in_protected_area"::string(is_in_protected_area),
			"previous_lu_name"::previous_lu_name,
			"action_type"::action_type,
			"is_applied"::string(is_applied),
			"is_sent"::string(is_sent),
			"locationx"::string(location.x),
			"locationy"::string(location.y),
			"command_round"::string(command_round),
			"length_coast_def"::string(length_coast_def),
			"a_lever_has_been_applied"::string(a_lever_has_been_applied)];
			
			put district_code at: DISTRICT_CODE in: res;
			int i <- 0;
			loop pp over: element_shape.points {
				put string(pp.x) key: "locationx"+i in: res;
				put string(pp.y) key: "locationy"+i in: res;
				i <- i + 1;
			}
		return res;
	}
	
	Coastal_Defense create_dike (Player_Action act, int comm){
		int next_coast_def_id <- max(Coastal_Defense collect(each.coast_def_id)) +1;
		create Coastal_Defense returns: tmp_dike{
			coast_def_id <- next_coast_def_id;
			district_code<- act.district_code;
			shape 	<- act.element_shape;
			location <- act.location;
			type 	<- comm = ACTION_CREATE_DIKE ? COAST_DEF_TYPE_DIKE : COAST_DEF_TYPE_DUNE;
			status 	<- BUILT_DIKE_STATUS;
			height 	<- BUILT_DIKE_HEIGHT;	
			cells 	<- Cell overlapping self;
			//alt 	<- cells max_of(each.soil_height);
			alt 	<- cells mean_of(each.soil_height);
		}
		Coastal_Defense new_dike <- first (tmp_dike);
		act.element_id 		<-  new_dike.coast_def_id;
		ask Network_Game_Manager {
			new_dike.shape  <- myself.element_shape;
			point p1 		<- first(myself.element_shape.points);
			point p2 		<- last(myself.element_shape.points);
			map<string,string> msg <- ["TOPIC"::ACTION_DIKE_CREATED,
				 "coast_def_id"::new_dike.coast_def_id,"action_id"::myself.act_id,
				 "p1.x"::p1.x, "p1.y"::p1.y, "p2.x"::p2.x, "p2.y"::p2.y,
				 "height"::new_dike.height, "type"::new_dike.type, "status"::new_dike.status,
				 "alt"::new_dike.alt, "location.x"::new_dike.location.x, "location.y"::new_dike.location.y];
			do send to: new_dike.district_code contents: msg;	
		}
		return new_dike;
	}
}
//------------------------------ End of Player_Action -------------------------------//

species Coastal_Defense {	
	int coast_def_id;
	string district_code;
	string type;     // DIKE or DUNE
	string status;	//  "GOOD" "MEDIUM" "BAD"  
	float height;
	float alt; 
	rgb color 			 <- #pink;
	int counter_status	 <- 0;
	int rupture			 <- 0;
	geometry rupture_area<- nil;
	bool not_updated 	 <- false;
	bool ganivelle 		 <- false;
	float height_before_ganivelle;
	list<Cell> cells;
	
	map<string,unknown> build_map_from_coast_def_attributes{
		map<string,unknown> res <- [
			"OBJECT_TYPE"::OBJECT_TYPE_COASTAL_DEFENSE,
			"coast_def_id"::string(coast_def_id),
			"type"::type,
			"status"::status,
			"height"::string(height),
			"alt"::string(alt),
			"ganivelle"::string(ganivelle),
			"locationx"::string(location.x),
			"locationy"::string(location.y)];
		int i <- 0;
		loop pp over: shape.points{
			add string(pp.x) at: "locationx"+i to: res;
			add string(pp.y) at: "locationy"+i to: res;
			i <- i + 1;
		}
		add string(i) at: "tot_points" to: res;
		return res;
	}
	
	action init_coastal_def {
		if status = ""  { status <- STATUS_GOOD; } 
		if type = '' 	{ type 	<- "Unknown"; }
		if height = 0.0 { height <- MIN_HEIGHT_DIKE; }
		counter_status 	<- type = COAST_DEF_TYPE_DUNE ? rnd (STEPS_DEGRAD_STATUS_DUNE - 1) : rnd (STEPS_DEGRAD_STATUS_DIKE - 1);
		cells 			<- Cell where (each overlaps self);
		if type = COAST_DEF_TYPE_DUNE  {
			height_before_ganivelle <- height;
		}
		do build_coast_def;
	}
	
	action build_coast_def {
		// a dike raises soil around the highest cell
		//alt <- cells mean_of (each.soil_height);
		ask cells  {
			soil_height <- myself.alt;// + myself.height;
			soil_height_before_broken <- soil_height;
			do init_cell_color();
		}
	}
	
	action repaire_dike {
		status <- STATUS_GOOD;
		counter_status <- 0;
	}

	action raise_dike {
		do repaire_dike;
		height 	<- height + RAISE_DIKE_HEIGHT; 
		alt 	<- alt + RAISE_DIKE_HEIGHT; 
		ask cells {
			soil_height <- soil_height + RAISE_DIKE_HEIGHT;
			soil_height_before_broken <- soil_height;
			do init_cell_color();
		}
	}
	
	action destroy_coast_def {
		ask Network_Game_Manager {
			map<string,string> msg <- ["TOPIC"::ACTION_DIKE_DROPPED, "coast_def_id"::myself.coast_def_id];
			loop dist over: District where (each.district_code = myself.district_code) {
				do send to: dist.district_code contents: msg;
			}	
		}
		ask cells {
			soil_height <- soil_height - myself.height;
			soil_height_before_broken <- soil_height;
			do init_cell_color();
		}
		do die;
	}
	
	action degrade_dike_status {
		counter_status <- counter_status + 1;
		if counter_status > STEPS_DEGRAD_STATUS_DIKE {
			counter_status <- 0;
			if status = STATUS_MEDIUM 	{ status <- STATUS_BAD;	  }
			if status = STATUS_GOOD 	{ status <- STATUS_MEDIUM;}
			not_updated <- true;
		}
	}

	action evolve_dune_status {
		if ganivelle { // a dune with a ganivelle
			counter_status <- counter_status + 1;
			if counter_status > STEPS_REGAIN_STATUS_GANIVELLE {
				counter_status <- 0;
				if status = STATUS_MEDIUM 	{ status <- STATUS_GOOD;  }
				if status = STATUS_BAD 		{ status <- STATUS_MEDIUM;}
			}
			if height < height_before_ganivelle + H_MAX_GANIVELLE {
				height 	<- height + H_DELTA_GANIVELLE;  // the dune raises by H_DELTA_GANIVELLE until it reaches H_MAX_GANIVELLE
				alt 	<- alt + H_DELTA_GANIVELLE;
				ask cells {
					soil_height <- soil_height + H_DELTA_GANIVELLE;
					soil_height_before_broken <- soil_height;
					do init_cell_color();
				}
			} else { ganivelle <- false;	} // if the dune covers all the ganivelle we reset the ganivelle
			not_updated<- true;
		}
		else { // a dune without a ganivelle
			counter_status <- counter_status +1;
			if counter_status > STEPS_DEGRAD_STATUS_DUNE {
				counter_status   <- 0;
				if status = STATUS_MEDIUM { status <- STATUS_BAD;   }
				if status = STATUS_GOOD   { status <- STATUS_MEDIUM;}
				not_updated <- true;
			}
		}
	}
		
	action calculate_rupture {
		int p <- 0;
		if type = COAST_DEF_TYPE_DIKE {
			if 		 status = STATUS_BAD	{ p <- PROBA_RUPTURE_DIKE_STATUS_BAD;	 }
			else if  status = STATUS_MEDIUM	{ p <- PROBA_RUPTURE_DIKE_STATUS_MEDIUM; }
			else 							{ p <- PROBA_RUPTURE_DIKE_STATUS_GOOD;	 }	
		}
		else if type = COAST_DEF_TYPE_DUNE  {
			if      status = STATUS_BAD 	{ p <- PROBA_RUPTURE_DUNE_STATUS_BAD;	 }
			else if status = STATUS_MEDIUM 	{ p <- PROBA_RUPTURE_DUNE_STATUS_MEDIUM; }
			else 						 	{ p <- PROBA_RUPTURE_DUNE_STATUS_GOOD;	 }	
		}
		if rnd (100) <= p {
			rupture <- 1;
			// the rupture is applied in the middle
			int cIndex <- int(length(cells) / 2);
			// rupture area is about RADIUS_RUPTURE m arount rupture point 
			rupture_area <- circle(RADIUS_RUPTURE#m,(cells[cIndex]).location);
			// rupture is applied on relevant area cells
			ask cells overlapping rupture_area {
				if soil_height >= 0 {
					soil_height <- max([0, soil_height - myself.height]);
				}
			}
			write "rupture " + type + " n°" + coast_def_id + "(" + world.dist_code_sname_correspondance_table at district_code + ", status " + status + ", height " + height + ", alt " + alt + ")";
		}
	}
	
	action remove_rupture {
		rupture <- 0;
		ask cells overlapping rupture_area {
			if soil_height >= 0 {
				soil_height <- soil_height_before_broken;
			}
		}
		rupture_area <- nil;
	}
	
	action install_ganivelle {
		if status = STATUS_BAD {	counter_status <- 2;	}
		else				   {	counter_status <- 0; 	}		
		ganivelle <- true;
		write "" + world.get_message('MSG_INSTALL_GANIVELLE');
	}
	
	aspect base {
		switch status {
			match STATUS_GOOD	{ color <- #green;  }
			match STATUS_MEDIUM { color <- #orange; } 
			match STATUS_BAD 	{ color <- #red;	}
			default				{
				color <- #black;
				write "Coast Def status problem !";
			}
		}
		if type = COAST_DEF_TYPE_DUNE {
			draw 50#m around shape color: color;
			if ganivelle {
				loop i over: points_on (shape, 40#m) {
					draw circle(10,i) color: #black;
				}
			} 
		}else{
			draw 20#m around shape color: color;// size: 300#m;
		}
		if(rupture = 1){
			list<point> pts <- shape.points;
			point tmp <- length(pts) > 2? pts[int(length(pts)/2)] : shape.centroid;
			draw image_file("../images/icons/rupture.png") at: tmp size: 30#px;
		}	
	}
}
//------------------------------ End of Coastal defense -------------------------------//

grid Cell width: DEM_NB_COLS height: DEM_NB_ROWS schedules:[] neighbors: 8 {	
	int cell_type 					<- 0; // 0 = sea
	float water_height  			<- 0.0;
	float max_water_height  		<- 0.0;
	float soil_height 				<- 0.0;
	float rugosity					<- 0.0;
	float soil_height_before_broken <- soil_height;
	rgb soil_color <- rgb(255,255,255);
	//int hillshade <- 0;
	
	action init_cell_color {		
		if cell_type = 0 { // sea
			float tmp  <- ((soil_height  / cells_max_depth) with_precision 1) * - 170;
			soil_color <- rgb(80, 80 , int(255 - tmp));
		}else if cell_type = 1{ // land
			soil_color <- land_colors [min(int(soil_height/land_color_interval),4)];
		}
	}
	
	aspect water_or_max_water_height {
		if cell_type = 0 or (show_max_water_height? max_water_height = 0 : water_height = 0){ // if sea and water level = 0
			color <- soil_color;
		}else if cell_type = 1{ // if land 
			if show_max_water_height {	color <- world.color_of_water_height(max_water_height);	}
			else					 {	color <- world.color_of_water_height(water_height);		}
		}
	}
}
//------------------------------ End of grid -------------------------------//

species Land_Use {
	int id;
	string lu_name;
	int lu_code;
	string dist_code;
	rgb my_color 		<- cell_color() update: cell_color();
	int AU_to_U_counter <- 0;
	string density_class-> {population = 0? POP_EMPTY :(population < POP_LOW_NUMBER ? POP_LOW_DENSITY: (population < POP_MEDIUM_NUMBER ? POP_MEDIUM_DENSITY : POP_DENSE))};
	int exp_cost 		-> {round (population * 400 * population ^ (-0.5))};
	bool isUrbanType 	-> {lu_name in ["U","Us","AU","AUs"]};
	bool is_adapted 	-> {lu_name in ["Us","AUs"]};
	bool is_in_densification<- false;
	bool not_updated 		<- false;
	bool pop_updated 		<- false;
	int population;
	list<Cell> cells;
	float mean_alt <- 0.0;
	
	map<string,unknown> build_map_from_lu_attributes {
		map<string,string> res <- [
			"OBJECT_TYPE"::OBJECT_TYPE_LAND_USE,
			"id"::string(id),
			"lu_code"::string(lu_code),
			"mean_alt"::string(mean_alt),
			"population"::string(population),
			"is_in_densification"::string(is_in_densification),
			"locationx"::string(location.x),
			"locationy"::string(location.y)];
			int i <- 0;
			loop pp over:shape.points{
				put string(pp.x) key:"locationx"+i in: res;
				put string(pp.y) key:"locationy"+i in: res;
				i<-i+1;
		}
		return res;
	}
		
	action modify_LU (string new_lu_name) {
		if (lu_name in ["U","Us"]) and new_lu_name = "N" {
			population <-0; //expropriation
		} 
		lu_name <- new_lu_name;
		lu_code <-  lu_type_names index_of lu_name;
		// updating rugosity of related cells
		float rug <- float((eval_gaml("RUGOSITY_" + lu_name)));
		ask cells { rugosity <- rug; } 	
	}
	
	action evolve_AU_to_U {
		if lu_name in ["AU","AUs"]{
			AU_to_U_counter <- AU_to_U_counter + 1;
			if AU_to_U_counter = STEPS_FOR_AU_TO_U {
				AU_to_U_counter <- 0;
				lu_name <- lu_name = "AU" ? "U" : "Us";
				lu_code <- lu_type_names index_of lu_name;
				not_updated <- true;
				do assign_population (POP_FOR_NEW_U);
			}
		}	
	}
	
	action evolve_pop_U_densification {
		if !pop_updated and is_in_densification and lu_name in ["U","Us"]{
			string previous_d_class <- density_class; 
			do assign_population (POP_FOR_U_DENSIFICATION);
			if previous_d_class != density_class {
				is_in_densification <- false;
			}
		}
	}
		
	action evolve_pop_U_standard { 
		if !pop_updated and !is_in_densification and lu_name in ["U","Us"]{
			do assign_population (POP_FOR_U_STANDARD);
		}
	}
	
	action assign_population (int nbPop) {
		if new_comers_still_to_dispatch > 0 {
			population 					 <- population + nbPop;
			new_comers_still_to_dispatch <- new_comers_still_to_dispatch - nbPop;
			not_updated 				 <- true;
			pop_updated 				 <- true;
		}
	}

	aspect base {
		draw shape color: my_color;
		if is_adapted		  {	draw "A" color:#black;	}
		if is_in_densification{	draw "D" color:#black;	}
	}

	aspect population_density {
		rgb acolor <- nil;
		switch density_class {
			match POP_EMPTY 		{acolor <- rgb(245,245,245); }
			match POP_LOW_DENSITY 	{acolor <- rgb(220,220,220); } 
			match POP_MEDIUM_DENSITY{acolor <- rgb(192,192,192); }
			match POP_DENSE 		{acolor <- rgb(169,169,169); }
			default 				{write "Density class problem !"; }
		}
		draw shape color: acolor;
	}
	
	aspect conditional_outline {
		if (Button first_with (each.nb_button = 4)).is_selected {	draw shape empty: true border:#black;	}
	}
	
	rgb cell_color{
		rgb res <- nil;
		switch (lu_name){
			match	  	"N" 				 {res <- #palegreen;		} // natural
			match	  	"A" 				 {res <- rgb(225, 165, 0);	} // agricultural
			match_one ["AU","AUs"]  		 {res <- #yellow;		 	} // to urbanize
			match_one ["U","Us"] { 								 	    // urbanised
				switch density_class 		 {
					match POP_EMPTY 		 { return rgb(245,245,245);	}
					match POP_LOW_DENSITY	 { return rgb(220,220,220);	}
					match POP_MEDIUM_DENSITY { return rgb(192,192,192);	}
					match POP_DENSE 		 { return rgb(169,169,169);	}
				}
			}			
		}
		return res;
	}
}
//------------------------------ End of Land_Use -------------------------------//

species District {	
	int dist_id <- 0;
	string district_code; 
	string district_name;
	string district_long_name;
	list<Land_Use> LUs;
	list<Cell> cells;
	 
	int budget;
	float tax_unit;
	int received_tax <-0;
	float round_actions_cost <- 0.0;
	float round_given_money  <- 0.0;
	float round_taken_money  <- 0.0;
	float round_levers_cost  <- 0.0;
	float round_transferred_money <- 0.0;
	
	int round_build_actions <- 0;
	int round_soft_actions <- 0;
	int round_withdraw_actions <- 0;
	int round_neutral_actions <- 0;
	int sum_buil_sof_wit_actions <- 1;
	
	float round_build_cost <- 0.0;
	float round_soft_cost <- 0.0;
	float round_withdraw_cost <- 0.0;
	float round_neutral_cost <- 0.0;
	
	// init water heights
	float U_0_5c  	  <-0.0;		float U_1c 		<-0.0;		float U_maxc 	  <-0.0;
	float Us_0_5c 	  <-0.0;		float Us_1c 	<-0.0;		float Us_maxc 	  <-0.0;
	float Udense_0_5c <-0.0;		float Udense_1c <-0.0;		float Udense_maxc <-0.0;
	float AU_0_5c 	  <-0.0; 		float AU_1c 	<-0.0;		float AU_maxc 	  <-0.0;
	float A_0_5c 	  <-0.0;		float A_1c 		<-0.0;		float A_maxc      <-0.0;
	float N_0_5c 	  <-0.0;		float N_1c 		<-0.0;		float N_maxc 	  <-0.0;
	
	float prev_U_0_5c  	  <-0.0;		float prev_U_1c 		<-0.0;		float prev_U_maxc 	  <-0.0;
	float prev_Us_0_5c 	  <-0.0;		float prev_Us_1c 	<-0.0;		float prev_Us_maxc 	  <-0.0;
	float prev_Udense_0_5c <-0.0;		float prev_Udense_1c <-0.0;		float prev_Udense_maxc <-0.0;
	float prev_AU_0_5c 	  <-0.0; 		float prev_AU_1c 	<-0.0;		float prev_AU_maxc 	  <-0.0;
	float prev_A_0_5c 	  <-0.0;		float prev_A_1c 		<-0.0;		float prev_A_maxc      <-0.0;
	float prev_N_0_5c 	  <-0.0;		float prev_N_1c 		<-0.0;		float prev_N_maxc 	  <-0.0;
	
	float flooded_area <- 0.0;	list<float> data_flooded_area<- [];
	float totU 		   <- 0.0;	list<float> data_totU 		 <- [];
	float totUs 	   <- 0.0;	list<float> data_totUs 		 <- [];
	float totUdense	   <- 0.0;	list<float> data_totUdense 	 <- [];
	float totAU 	   <- 0.0;	list<float> data_totAU 		 <- [];
	float totN 		   <- 0.0;	list<float> data_totN 		 <- [];
	float totA 		   <- 0.0;	list<float> data_totA 		 <- [];

	// Indicators calculated at initialization, and sent to Leader when he connects
	map<string,string> my_indicators_t0 <- [];
	
	aspect flooding { draw shape color: rgb (0,0,0,0) border:#black; }
	aspect planning { draw shape color:#whitesmoke border: #black; }
	aspect population { draw shape color: rgb(240,186,112) border:#black; }
	
	int current_population {  return sum(LUs accumulate (each.population));	}
	
	action inform_new_round {// inform about a new round
		ask Network_Game_Manager{
			map<string,string> msg <- ["TOPIC"::INFORM_NEW_ROUND];
			do send to: myself.district_code contents: msg;
		}
	}
	
	action inform_current_round {// inform about the current round (when the player side district reconnects)
		ask Network_Game_Manager{
			map<string,string> msg <- ["TOPIC"::INFORM_CURRENT_ROUND];
			put string(game_round) 		  	at: NUM_ROUND		in: msg;
			put string(game_paused) 		at: "GAME_PAUSED"	in: msg;
			do send to: myself.district_code contents: msg;
		}
	}

	action inform_budget_update {// inform about the budget (when the player side district reconnects)
		ask Network_Game_Manager{
			map<string,string> msg <- ["TOPIC"::DISTRICT_BUDGET_UPDATE];
			put string(myself.budget) at: BUDGET in: msg;
			do send to: myself.district_code contents: msg;
		}
	}
	
	action inform_LU_alts{
		map<string,string> msg <- ["TOPIC"::INFORM_LU_ALTS];
		loop lu over: LUs{
			put string(lu.id) 		at: "id" 		in: msg;
			put string(lu.mean_alt) at: "mean_alt"  in: msg;
			ask Network_Game_Manager{
				do send to: myself.district_code contents: msg;
			}
		}
	}
	
	action calculate_taxes {
		received_tax <- int(self.current_population() * tax_unit);
		budget <- budget + received_tax;
		write district_name + " -> tax: " + received_tax + "; budget: "+ budget;
	}
	
	action calculate_indicators_t0 {
		list<Coastal_Defense> my_coast_def <- Coastal_Defense where (each.district_code = district_code);
		put string(my_coast_def where (each.type = COAST_DEF_TYPE_DIKE) sum_of (each.shape.perimeter)) key: "length_dikes_t0" in: my_indicators_t0;
		put string(my_coast_def where (each.type = COAST_DEF_TYPE_DUNE) sum_of (each.shape.perimeter)) key: "length_dunes_t0" in: my_indicators_t0;
		put string(length(LUs where (each.isUrbanType))) key: "count_LU_urban_t0" in: my_indicators_t0; // built cells (U , AU, Us and AUs)
		put string(length(LUs where (each.isUrbanType and not(each.is_adapted) and each intersects all_coastal_border_area))) key: "count_LU_U_and_AU_is_in_coast_border_area_t0" in: my_indicators_t0; // non adapted built cells in littoral area (<400m)
		put string(length(LUs where (each.isUrbanType and each intersects all_flood_risk_area))) key: "count_LU_urban_in_flood_risk_area_t0" in: my_indicators_t0; // built cells in flooded area
		put string(length(LUs where (each.isUrbanType and each.density_class = POP_DENSE and each intersects all_flood_risk_area))) key: "count_LU_urban_dense_in_flood_risk_area_t0" in: my_indicators_t0; // dense cells in risk area
		put string(length(LUs where (each.isUrbanType and each.density_class = POP_DENSE and each intersects all_coastal_border_area))) key: "count_LU_urban_dense_is_in_coast_border_area_t0" in: my_indicators_t0; //dense cells in littoral area
		put string(length(LUs where (each.lu_name = 'A'))) 	key: "count_LU_A_t0" 	in: my_indicators_t0; // count cells of type A
		put string(length(LUs where (each.lu_name = 'N'))) 	key: "count_LU_N_t0" 	in: my_indicators_t0; // count cells of type N
		put string(length(LUs where (each.lu_name = 'AU'))) key: "count_LU_AU_t0" 	in: my_indicators_t0; // count cells of type AU
		put string(length(LUs where (each.lu_name = 'U'))) 	key: "count_LU_U_t0" 	in: my_indicators_t0; // count cells of type U
	}				
}
//------------------------------ End of District -------------------------------//
	
// generic buttons
species Button{
	int nb_button 	 <- 0;
	string command 	 <- "";
	string display_text;
	bool is_selected <- false;
	geometry shape 	 <- square(button_size);
	image_file my_icon;
	
	aspect buttons_master {
		if(nb_button in [0,1,2,3,5]){
			if(nb_button in [0,3,5]){
				draw shape color: #white border: is_selected ? #red : #white;
			}else if(nb_button = 1) {
				draw shape color: #white border: game_paused ? #white : #blue;
			}else if (nb_button = 2){
				draw shape color: #white border: game_paused ? #blue : #white;	
			}
			draw display_text color: #black at: location + {0,shape.height*0.66} anchor: #center;
			draw my_icon size: button_size-50#m;
		} else if(nb_button = 6){
			if (int(command) < length(list_flooding_events)){
				draw shape color: #white border: is_selected ? #red : #white;
				draw display_text color: #black at: location + {0, shape.height*0.66} anchor: #center;
				draw my_icon size: button_size-50#m;
			}
		}	
	}
	
	aspect buttons_map {
		if(nb_button in [4,7]){
			draw shape color: #white border: is_selected? # red : # white;
			draw my_icon size:  800#m;
		}
	}
}

species Legend_Planning{
	list<rgb> colors <- [];
	list<string> texts <- [];
	point start_location;
	point rect_size <- {300, 400};
	rgb text_color  <- #black;
	
	init{
		texts <- ["N","A","AU, AUs","U empty", "U low","U medium","U dense"];
		colors<- [#palegreen,rgb(225,165,0),#yellow,rgb(245,245,245),rgb(220,220,220),rgb(192,192,192),rgb(169,169,169)];
		start_location <- LEGEND_POSITION = 'topleft' ? {700, 750} : {700, 15000};		
	}
	
	aspect {
		loop i from: 0 to: length(texts) - 1 {
			draw rectangle(rect_size) at: start_location + {0, i * rect_size.y} color: colors[i] border: #black;
			draw texts[i] at: start_location + {rect_size.x, (i * rect_size.y) + 50} color: text_color size: rect_size.y;
		}
	}
}

species Legend_Population parent: Legend_Planning {
	init{
		texts <- ["High density","Medium density","Low density","Empty"];
		colors<- [rgb(169,169,169),rgb(192,192,192),rgb(220,220,220),rgb(245,245,245)];
	}
}

species Legend_Map parent: Legend_Planning {
	init {
		start_location <- LEGEND_POSITION = 'topleft' ? {700, 1500} : {700, 15750};
		text_color <- #white;
		int t1 <- int(land_color_interval);
		int t2 <- int(land_color_interval*2);
		int t3 <- int(land_color_interval*3);
		texts <- [''+int(land_max_height)+' m',''+t3+' m',''+t2+' m',''+t1+' m','0 m'];
		colors <- reverse(land_colors); 
	}
}

species Legend_Flood parent: Legend_Planning {
	init{
		text_color <- #white;
		texts <- [">1.0 m","","<0.5 m"];
		colors<- [rgb(65,65,255),rgb(115,115,255),rgb(200,200,255)];
	}
	
	aspect {
		if show_max_water_height {
			start_location <- LEGEND_POSITION = 'topleft' ? {2000, 1500} : {2000, 15750};
			loop i from: 0 to: length(texts) - 1 {
				draw rectangle(rect_size) at: start_location + {0,i * rect_size.y} color: colors[i] border: #black;
				draw texts[i] at: start_location + {rect_size.x, (i * rect_size.y)+75} color: text_color size: rect_size.y;
			}
		}
	}
}

species Road {	aspect base { draw shape color: rgb (125,113,53); } }

species Isoline {	aspect base { draw shape color: #gray; } }

species Water { aspect base { draw shape color: #blue; } }

species Protected_Area { aspect base { draw shape color: rgb (185, 255, 185,120) border:#black;} }

species Flood_Risk_Area { aspect base { draw shape color: rgb (20, 200, 255,120) border:#black; } }
// 400 m littoral area
species Coastal_Border_Area { aspect base { draw shape color: rgb (20, 100, 205,120) border:#black; } }
//100 m coastline inland area to identify retro dikes
species Inland_Dike_Area { aspect base { draw shape color: rgb (100, 100, 205,120) border:#black;} }

//---------------------------- Experiment definiton -----------------------------//

experiment LittoSIM_GEN_Manager type: gui schedules:[]{
	
	string default_language <- first(text_file("../includes/config/littosim.conf").contents where (each contains 'LANGUAGE')) split_with ';' at 1;
	list<string> languages_list <- first(text_file("../includes/config/littosim.conf").contents where (each contains 'LANGUAGE_LIST')) split_with ';' at 1 split_with ',';
	
	list<rgb> color_lbls <- [#moccasin,#lightgreen,#deepskyblue,#darkgray,#darkgreen,#darkblue];
	list<rgb> dist_colors <- [#red, #blue, #green, #orange];
	
	init {
		minimum_cycle_duration <- 0.5;
	}
	
	parameter "Language choice : " var: my_language	 <- default_language  among: languages_list;
	parameter "Log User Actions" 	var: log_user_action <- false on_change: {ask world{do save_user_actions;}};
	
	output {
		display "Flooding" background: #black{
			grid Cell;
			species Cell 			aspect: water_or_max_water_height;
			species District 		aspect: flooding;
			species Isoline			aspect: base;
			species Road 			aspect: base;
			species Water			aspect: base;
			species Coastal_Defense aspect: base;
			species Land_Use 		aspect: conditional_outline;
			species Button 			aspect: buttons_map;
			species Legend_Map;
			species Legend_Flood;
			event mouse_down 		action: button_click_map;
		}
		
		display "Game control"{	
			graphics "Master" {
				draw shape color: #lightgray;
			}
			species Button  aspect: buttons_master;
			
			graphics "Control Panel"{
				point loc 	<- {world.shape.width/2, world.shape.height/2};
				float msize <- min([loc.x, loc.y]);
				draw image_file("../images/ihm/logo.png") at: loc size: {msize, msize};
				draw rectangle(msize,1500) at: loc + {0,msize*0.66} color: #lightgray border: #black anchor:#center;
				draw world.get_message("MSG_THE_ROUND") + " : " + game_round color: #blue font: font('Helvetica Neue', 20, #bold) at: loc + {0,msize*0.66} anchor:#center;
			}
			graphics "Play_pause" transparency: 0.5{
				draw square(button_size) at: game_paused ? pause_b : play_b color: #gray ;
			}
			graphics "A submersion is running" {
				if submersion_is_running {
					point loc 	<- {world.shape.width/2, world.shape.height/2};
					draw image_file("../images/ihm/tempete.jpg") at: loc size: {world.shape.width, world.shape.height};
				}
			}
			
			event mouse_down action: button_click_master_control;
		}
		
		display "Planning and population" background: #black{
			graphics "World" { draw shape color: rgb(230,251,255); }
			species District 		aspect: planning size: {0.48,0.48} position: {0.01,0.01};
			species Land_Use 		aspect: base size: {0.48,0.48} position: {0.01,0.01};
			species Road 	 		aspect: base size: {0.48,0.48} position: {0.01,0.01};
			species Water			aspect: base size: {0.48,0.48} position: {0.01,0.01};
			species Coastal_Defense aspect: base size: {0.48,0.48} position: {0.01,0.01};
			species Legend_Planning size: {0.48,0.48} position: {0.01,0.01};
		
			species District aspect: population size: {0.48,0.48} position: {0.51,0.01};
			species Land_Use aspect: population_density size: {0.48,0.48} position: {0.51,0.01};
			species Road 	 aspect: base size: {0.48,0.48} position: {0.51,0.01};
			species Water	 aspect: base size: {0.48,0.48} position: {0.51,0.01};
			species Legend_Population size: {0.48,0.48} position: {0.51,0.01};
			
			chart world.get_message('MSG_BUDGETS') type: series size: {0.48,0.48} position: {0.01,0.51} x_range:[0,15] 
					x_label: world.get_message('MSG_THE_ROUND') background: #white axes: #black y_tick_line_visible: false x_tick_line_visible: false
			{
				data "" value: submersions color: #black style: bar;
				loop i from: 0 to: 3{
					data districts_in_game[i].district_name value: districts_budgets[i] color: dist_colors[i] marker_shape: marker_circle;
				}		
			}			
			chart world.get_message('MSG_ACTIONS') type: histogram size: {0.48,0.48} position: {0.51,0.51} 
					x_serie_labels: districts_in_game collect each.district_name style:stack {
				data world.get_message("MSG_BUILDER") value: districts_build_strategies collect sum(each) color: color_lbls[2];
			 	data world.get_message("MSG_SOFT_DEF") value: districts_soft_strategies collect sum(each) color: color_lbls[1];
			 	data world.get_message("MSG_WITHDRAWAL") value: districts_withdraw_strategies collect sum(each) color: color_lbls[0];
			 	data world.get_message("MSG_NEUTRAL") value: districts_neutral_strategies collect sum(each) color: color_lbls[3];
			}
		}
		
		display "Budgets" {
			chart world.get_message('LDR_TOTAL') type: histogram size: {0.33,0.48} position: {0.0,0.0}  {
				loop i from: 0 to: 3{
					data districts_in_game[i].district_name value: last(districts_budgets[i]) color: dist_colors[i];
				}			
			}
			//-----
			chart districts_in_game[0].district_name type: pie size: {0.33,0.24} position: {0.34,0.0}
				style: stack x_range:[0,15] x_label: world.get_message('MSG_THE_ROUND'){
			 	data world.get_message('MSG_TAXES') value: sum(districts_taxes[0]) color: color_lbls[0];
			 	data world.get_message('LDR_GIVEN') value: sum(districts_given_money[0]) color: color_lbls[1];
			 	data world.get_message('LDR_TAKEN') value: sum(districts_taken_money[0] collect abs(each)) color: color_lbls[2];
			 	data world.get_message('LDR_TRANSFERRED') value: sum(districts_transferred_money[0] collect abs(each)) color: color_lbls[5];
			 	data world.get_message('LEV_MSG_ACTIONS') value: sum(districts_actions_costs[0] collect abs(each)) color: color_lbls[3];
			 	data world.get_message("MSG_LEVERS") value: sum(districts_levers_costs[0]) color: color_lbls[4];		
			}
			chart districts_in_game[1].district_name type: pie size: {0.33,0.24} position: {0.67,0.0}
				style: stack x_range:[0,15] x_label: world.get_message('MSG_THE_ROUND'){
			 	data world.get_message('MSG_TAXES') value: sum(districts_taxes[1]) color: color_lbls[0];
			 	data world.get_message('LDR_GIVEN') value: sum(districts_given_money[1]) color: color_lbls[1];
			 	data world.get_message('LDR_TAKEN') value: sum(districts_taken_money[1] collect abs(each)) color: color_lbls[2];
			 	data world.get_message('LDR_TRANSFERRED') value: sum(districts_transferred_money[1] collect abs(each)) color: color_lbls[5];
			 	data world.get_message('LEV_MSG_ACTIONS') value: sum(districts_actions_costs[1] collect abs(each)) color: color_lbls[3];
			 	data world.get_message("MSG_LEVERS") value: sum(districts_levers_costs[1]) color: color_lbls[4];		
			}
			chart districts_in_game[2].district_name type: pie size: {0.33,0.24} position: {0.34,0.25}
				style: stack x_range:[0,15] x_label: world.get_message('MSG_THE_ROUND'){
			 	data world.get_message('MSG_TAXES') value: sum(districts_taxes[2]) color: color_lbls[0];
			 	data world.get_message('LDR_GIVEN') value: sum(districts_given_money[2]) color: color_lbls[1];
			 	data world.get_message('LDR_TAKEN') value: sum(districts_taken_money[2] collect abs(each)) color: color_lbls[2];
			 	data world.get_message('LDR_TRANSFERRED') value: sum(districts_transferred_money[2] collect abs(each)) color: color_lbls[5];
			 	data world.get_message('LEV_MSG_ACTIONS') value: sum(districts_actions_costs[2] collect abs(each)) color: color_lbls[3];
			 	data world.get_message("MSG_LEVERS") value: sum(districts_levers_costs[2]) color: color_lbls[4];		
			}
			chart districts_in_game[3].district_name type: pie size: {0.33,0.24} position: {0.67,0.25}
				style: stack x_range:[0,15] x_label: world.get_message('MSG_THE_ROUND'){
			 	data world.get_message('MSG_TAXES') value: sum(districts_taxes[3]) color: color_lbls[0];
			 	data world.get_message('LDR_GIVEN') value: sum(districts_given_money[3]) color: color_lbls[1];
			 	data world.get_message('LDR_TAKEN') value: sum(districts_taken_money[3] collect abs(each)) color: color_lbls[2];
			 	data world.get_message('LDR_TRANSFERRED') value: sum(districts_transferred_money[3] collect abs(each)) color: color_lbls[5];
			 	data world.get_message('LEV_MSG_ACTIONS') value: sum(districts_actions_costs[3] collect abs(each)) color: color_lbls[3];
			 	data world.get_message("MSG_LEVERS") value: sum(districts_levers_costs[3]) color: color_lbls[4];		
			}			
			//-------
			chart world.get_message('LDR_TOTAL') type: histogram size: {0.33,0.48} position: {0.0,0.5} style:stack
				x_serie_labels: districts_in_game collect each.district_name series_label_position: xaxis {
			 	data world.get_message('MSG_TAXES') value: districts_taxes collect sum(each) color: color_lbls[0];
			 	data world.get_message('LDR_GIVEN') value: districts_given_money collect sum(each) color: color_lbls[1];
			 	data world.get_message('LDR_TAKEN') value: districts_taken_money collect sum(each) color: color_lbls[2];
				data world.get_message('LDR_TRANSFERRED') value: districts_transferred_money collect sum(each) color: color_lbls[5];
			 	data world.get_message('LEV_MSG_ACTIONS') value: districts_actions_costs collect sum(each) color: color_lbls[3];
			 	data world.get_message("MSG_LEVERS") value: districts_levers_costs collect sum(each) color: color_lbls[4];		
			}
						
			chart districts_in_game[0].district_name type: histogram size: {0.33,0.24} position: {0.34,0.5}
				style: stack x_range:[0,15] x_label: world.get_message('MSG_THE_ROUND'){
			 	data world.get_message('MSG_TAXES') value: districts_taxes[0] color: color_lbls[0];
			 	data world.get_message('LDR_GIVEN') value: districts_given_money[0] color: color_lbls[1];
			 	data world.get_message('LDR_TAKEN') value: districts_taken_money[0] color: color_lbls[2];
			 	data world.get_message('LDR_TRANSFERRED') value: districts_transferred_money[0] color: color_lbls[5];
			 	data world.get_message('LEV_MSG_ACTIONS') value: districts_actions_costs[0] color: color_lbls[3];
			 	data world.get_message("MSG_LEVERS") value: districts_levers_costs[0] color: color_lbls[4];		
			}
			chart districts_in_game[1].district_name type: histogram size: {0.33,0.24} position: {0.67,0.5}
				style: stack x_range:[0,15] x_label: world.get_message('MSG_THE_ROUND'){
			 	data world.get_message('MSG_TAXES') value: districts_taxes[1] color: color_lbls[0];
			 	data world.get_message('LDR_GIVEN') value: districts_given_money[1] color: color_lbls[1];
			 	data world.get_message('LDR_TAKEN') value: districts_taken_money[1] color: color_lbls[2];
			 	data world.get_message('LDR_TRANSFERRED') value: districts_transferred_money[1] color: color_lbls[5];
			 	data world.get_message('LEV_MSG_ACTIONS') value: districts_actions_costs[1] color: color_lbls[3];
			 	data world.get_message("MSG_LEVERS") value: districts_levers_costs[1] color: color_lbls[4];		
			}
			chart districts_in_game[2].district_name type: histogram size: {0.33,0.24} position: {0.34,0.75}
				style: stack x_range:[0,15] x_label: world.get_message('MSG_THE_ROUND'){
			 	data world.get_message('MSG_TAXES') value: districts_taxes[2] color: color_lbls[0];
			 	data world.get_message('LDR_GIVEN') value: districts_given_money[2] color: color_lbls[1];
			 	data world.get_message('LDR_TAKEN') value: districts_taken_money[2] color: color_lbls[2];
			 	data world.get_message('LDR_TRANSFERRED') value: districts_transferred_money[2] color: color_lbls[5];
			 	data world.get_message('LEV_MSG_ACTIONS') value: districts_actions_costs[2] color: color_lbls[3];
			 	data world.get_message("MSG_LEVERS") value: districts_levers_costs[2] color: color_lbls[4];		
			}
			chart districts_in_game[3].district_name type: histogram size: {0.33,0.24} position: {0.67,0.75}
				style: stack x_range:[0,15] x_label: world.get_message('MSG_THE_ROUND'){
			 	data world.get_message('MSG_TAXES') value: districts_taxes[3] color: color_lbls[0];
			 	data world.get_message('LDR_GIVEN') value: districts_given_money[3] color: color_lbls[1];
			 	data world.get_message('LDR_TAKEN') value: districts_taken_money[3] color: color_lbls[2];
			 	data world.get_message('LDR_TRANSFERRED') value: districts_transferred_money[3] color: color_lbls[5];
			 	data world.get_message('LEV_MSG_ACTIONS') value: districts_actions_costs[3] color: color_lbls[3];
			 	data world.get_message("MSG_LEVERS") value: districts_levers_costs[3] color: color_lbls[4];		
			}
		}
		
		display "Actions & Strategies" {
			chart world.get_message('MSG_NUMBER_ACTIONS') type: histogram size: {0.33,0.48} position: {0.01,0.01}
				x_serie_labels: districts_in_game collect (each.district_name) style:stack {
			 	data world.get_message("MSG_BUILDER") value: districts_build_strategies collect sum(each) color: color_lbls[2];
			 	data world.get_message("MSG_SOFT_DEF") value: districts_soft_strategies collect sum(each) color: color_lbls[1];
			 	data world.get_message("MSG_WITHDRAWAL") value: districts_withdraw_strategies collect sum(each) color: color_lbls[0];
			 	data world.get_message("MSG_NEUTRAL") value: districts_neutral_strategies collect sum(each) color: color_lbls[3];
			}
			chart world.get_message('MSG_COST_ACTIONS') type: histogram size: {0.33,0.48} position: {0.34,0.01}
				x_serie_labels: districts_in_game collect (each.district_name) style:stack {
			 	data world.get_message("MSG_BUILDER") value: districts_build_costs collect sum(each) color: color_lbls[2];
			 	data world.get_message("MSG_SOFT_DEF") value: districts_soft_costs collect sum(each) color: color_lbls[1];
			 	data world.get_message("MSG_WITHDRAWAL") value: districts_withdraw_costs collect sum(each) color: color_lbls[0];
			 	data world.get_message("MSG_NEUTRAL") value: districts_neutral_costs collect sum(each) color: color_lbls[3];
			}
			chart world.get_message('MSG_PROFILES') type: radar size: {0.33,0.48} position: {0.67,0.01} 
					x_serie_labels: [world.get_message("MSG_BUILDER"),world.get_message("MSG_SOFT_DEF"), world.get_message("MSG_WITHDRAWAL")] {
				loop i from: 0 to: 3{
					data districts_in_game[i].district_name value: game_round = 0? [0.75,0.75,0.75] : [
						sum(districts_build_strategies[i])/districts_in_game[i].sum_buil_sof_wit_actions,
						sum(districts_soft_strategies[i])/districts_in_game[i].sum_buil_sof_wit_actions,
						sum(districts_withdraw_strategies[i])/districts_in_game[i].sum_buil_sof_wit_actions] color: dist_colors[i];
				}		
			}
			//-------					
			chart districts_in_game[0].district_name type: histogram size: {0.48,0.24} position: {0.01,0.5}
				style: stack x_range:[0,15] x_label: world.get_message('MSG_THE_ROUND'){
			 	data world.get_message("MSG_BUILDER") value: districts_build_strategies[0] color: color_lbls[2];
			 	data world.get_message("MSG_SOFT_DEF") value: districts_soft_strategies[0] color: color_lbls[1];
			 	data world.get_message("MSG_WITHDRAWAL") value: districts_withdraw_strategies[0] color: color_lbls[0];
			 	data world.get_message("MSG_NEUTRAL") value: districts_neutral_strategies[0] color: color_lbls[3];
			}
			chart districts_in_game[1].district_name type: histogram size: {0.48,0.24} position: {0.5,0.5}
				style: stack x_range:[0,15] x_label: world.get_message('MSG_THE_ROUND'){
			 	data world.get_message("MSG_BUILDER") value: districts_build_strategies[1] color: color_lbls[2];
			 	data world.get_message("MSG_SOFT_DEF") value: districts_soft_strategies[1] color: color_lbls[1];
			 	data world.get_message("MSG_WITHDRAWAL") value: districts_withdraw_strategies[1] color: color_lbls[0];
			 	data world.get_message("MSG_NEUTRAL") value: districts_neutral_strategies[1] color: color_lbls[3];
			}
			chart districts_in_game[2].district_name type: histogram size: {0.48,0.24} position: {0.01,0.75}
				style: stack x_range:[0,15] x_label: world.get_message('MSG_THE_ROUND'){
			 	data world.get_message("MSG_BUILDER") value: districts_build_strategies[2] color: color_lbls[2];
			 	data world.get_message("MSG_SOFT_DEF") value: districts_soft_strategies[2] color: color_lbls[1];
			 	data world.get_message("MSG_WITHDRAWAL") value: districts_withdraw_strategies[2] color: color_lbls[0];
			 	data world.get_message("MSG_NEUTRAL") value: districts_neutral_strategies[2] color: color_lbls[3];
			}
			chart districts_in_game[3].district_name type: histogram size: {0.48,0.24} position: {0.5,0.75}
				style: stack x_range:[0,15] x_label: world.get_message('MSG_THE_ROUND'){
			 	data world.get_message("MSG_BUILDER") value: districts_build_strategies[3] color: color_lbls[2];
			 	data world.get_message("MSG_SOFT_DEF") value: districts_soft_strategies[3] color: color_lbls[1];
			 	data world.get_message("MSG_WITHDRAWAL") value: districts_withdraw_strategies[3] color: color_lbls[0];
			 	data world.get_message("MSG_NEUTRAL") value: districts_neutral_strategies[3] color: color_lbls[3];
			}
		}
		
		/*display "Land Use" {
			
		}
		
		display "Coastal defenses" {
			
		}*/
		
		display "Flooded depth per area"{
			chart world.get_message('MSG_AREA')+" U" type: histogram style: stack background: rgb("white") size: {0.24,0.48} position: {0, 0}
				x_serie_labels: districts_in_game collect each.district_name {
				data "0.5" value: districts_in_game collect each.U_0_5c color: world.color_of_water_height(0.5);
				data "1" value: districts_in_game collect each.U_1c color: world.color_of_water_height(0.9); 
				data ">1" value: districts_in_game collect each.U_maxc color: world.color_of_water_height(1.9); 
			}
			chart world.get_message('MSG_AREA')+" U "+ world.get_message('MSG_DENSE') type: histogram style: stack background: rgb("white") size: {0.24,0.48} position: {0.25, 0}
				x_serie_labels: districts_in_game collect each.district_name {
				data "0.5" value:(districts_in_game collect each.Udense_0_5c) color: world.color_of_water_height(0.5);
				data "1" value:(districts_in_game collect each.Udense_1c) color: world.color_of_water_height(0.9); 
				data ">1" value:(districts_in_game collect each.Udense_maxc) color: world.color_of_water_height(1.9); 
			}
			chart world.get_message('MSG_AREA')+" Us" type: histogram style: stack background: rgb("white") size: {0.24,0.48} position: {0.51, 0}
				x_serie_labels: districts_in_game collect each.district_name {
				data "0.5" value:(districts_in_game collect each.Us_0_5c) color: world.color_of_water_height(0.5);
				data "1" value:(districts_in_game collect each.Us_1c) color: world.color_of_water_height(0.9); 
				data ">1" value:(districts_in_game collect each.Us_maxc) color: world.color_of_water_height(1.9); 
			}
			chart world.get_message('MSG_AREA')+" AU" type: histogram style: stack background: rgb("white") size: {0.24,0.48} position: {0.76, 0}
				x_serie_labels: districts_in_game collect each.district_name {
				data "0.5" value:(districts_in_game collect each.AU_0_5c) color: world.color_of_water_height(0.5);
				data "1" value:(districts_in_game collect each.AU_1c) color: world.color_of_water_height(0.9); 
				data ">1" value:(districts_in_game collect each.AU_maxc) color: world.color_of_water_height(1.9); 
			}
			
			chart world.get_message('MSG_AREA')+" A" type: histogram style: stack background: rgb("white") size: {0.33,0.48} position: {0.165, 0.5}
				x_serie_labels: districts_in_game collect each.district_name reverse_axes: true {
				data "0.5" value:(districts_in_game collect each.A_0_5c) color: world.color_of_water_height(0.5);
				data "1" value:(districts_in_game collect each.A_1c) color: world.color_of_water_height(0.9); 
				data ">1" value:(districts_in_game collect each.A_maxc) color: world.color_of_water_height(1.9); 
			}
			chart world.get_message('MSG_AREA')+" N" type: histogram style: stack background: rgb("white") size: {0.33,0.48} position: {0.495, 0.5}
				x_serie_labels: districts_in_game collect each.district_name reverse_axes: true{
				data "0.5" value:(districts_in_game collect each.N_0_5c) color: world.color_of_water_height(0.5);
				data "1" value:(districts_in_game collect each.N_1c) color: world.color_of_water_height(0.9); 
				data ">1" value:(districts_in_game collect each.N_maxc) color: world.color_of_water_height(1.9); 
			}
		}
		
		display "Previous flooded depth per area"{
			chart world.get_message('MSG_AREA')+" U" type: histogram style: stack background: rgb("lightgray") size: {0.24,0.48} position: {0, 0}
				x_serie_labels: districts_in_game collect each.district_name {
				data "0.5" value: districts_in_game collect each.prev_U_0_5c color: world.color_of_water_height(0.5);
				data "1" value: districts_in_game collect each.prev_U_1c color: world.color_of_water_height(0.9); 
				data ">1" value: districts_in_game collect each.prev_U_maxc color: world.color_of_water_height(1.9); 
			}
			chart world.get_message('MSG_AREA')+" U "+ world.get_message('MSG_DENSE') type: histogram style: stack background: rgb("lightgray") size: {0.24,0.48} position: {0.25, 0}
				x_serie_labels: districts_in_game collect each.district_name {
				data "0.5" value:(districts_in_game collect each.prev_Udense_0_5c) color: world.color_of_water_height(0.5);
				data "1" value:(districts_in_game collect each.prev_Udense_1c) color: world.color_of_water_height(0.9); 
				data ">1" value:(districts_in_game collect each.prev_Udense_maxc) color: world.color_of_water_height(1.9); 
			}
			chart world.get_message('MSG_AREA')+" Us" type: histogram style: stack background: rgb("lightgray") size: {0.24,0.48} position: {0.51, 0}
				x_serie_labels: districts_in_game collect each.district_name {
				data "0.5" value:(districts_in_game collect each.prev_Us_0_5c) color: world.color_of_water_height(0.5);
				data "1" value:(districts_in_game collect each.prev_Us_1c) color: world.color_of_water_height(0.9); 
				data ">1" value:(districts_in_game collect each.prev_Us_maxc) color: world.color_of_water_height(1.9); 
			}
			chart world.get_message('MSG_AREA')+" AU" type: histogram style: stack background: rgb("lightgray") size: {0.24,0.48} position: {0.76, 0}
				x_serie_labels: districts_in_game collect each.district_name {
				data "0.5" value:(districts_in_game collect each.prev_AU_0_5c) color: world.color_of_water_height(0.5);
				data "1" value:(districts_in_game collect each.prev_AU_1c) color: world.color_of_water_height(0.9); 
				data ">1" value:(districts_in_game collect each.prev_AU_maxc) color: world.color_of_water_height(1.9); 
			}
			
			chart world.get_message('MSG_AREA')+" A" type: histogram style: stack background: rgb("lightgray") size: {0.33,0.48} position: {0.165, 0.5}
				x_serie_labels: districts_in_game collect each.district_name reverse_axes: true {
				data "0.5" value:(districts_in_game collect each.prev_A_0_5c) color: world.color_of_water_height(0.5);
				data "1" value:(districts_in_game collect each.prev_A_1c) color: world.color_of_water_height(0.9); 
				data ">1" value:(districts_in_game collect each.prev_A_maxc) color: world.color_of_water_height(1.9); 
			}
			chart world.get_message('MSG_AREA')+" N" type: histogram style: stack background: rgb("lightgray") size: {0.33,0.48} position: {0.495, 0.5}
				x_serie_labels: districts_in_game collect each.district_name reverse_axes: true{
				data "0.5" value:(districts_in_game collect each.prev_N_0_5c) color: world.color_of_water_height(0.5);
				data "1" value:(districts_in_game collect each.prev_N_1c) color: world.color_of_water_height(0.9); 
				data ">1" value:(districts_in_game collect each.prev_N_maxc) color: world.color_of_water_height(1.9); 
			}
		}
		
		display "Flooded area per district"{
			chart world.get_message("MSG_ALL_AREAS") type: series size: {0.48,0.45} position: {0, 0} x_range:[0,5] x_label: world.get_message('MSG_SUBMERSION'){
				loop i from: 0 to: 3{
					data districts_in_game[i].district_name value: districts_in_game[i].data_flooded_area color: dist_colors[i];
				}			
			}
			chart world.get_message('MSG_AREA')+" U" type: series size: {0.24,0.45} position: {0.5, 0} x_range:[0,5] x_label: world.get_message('MSG_SUBMERSION'){
				loop i from: 0 to: 3{
					data districts_in_game[i].district_name value: districts_in_game[i].data_totU color: dist_colors[i];
				}			
			}
			chart world.get_message('MSG_AREA')+" U "+ world.get_message('MSG_DENSE') type: series size: {0.24,0.45} position: {0.75, 0} 
					x_label: world.get_message('MSG_SUBMERSION') x_range:[0,5]{
				loop i from: 0 to: 3{
					data districts_in_game[i].district_name value: districts_in_game[i].data_totUdense color: dist_colors[i];
				}			
			}
			chart world.get_message('MSG_AREA')+" Us" type: series size: {0.24,0.45} position: {0, 0.5} x_range:[0,5] x_label: world.get_message('MSG_SUBMERSION'){
				loop i from: 0 to: 3{
					data districts_in_game[i].district_name value: districts_in_game[i].data_totUs color: dist_colors[i];
				} 			
			}
			chart world.get_message('MSG_AREA')+" AU" type: series size: {0.24,0.45} position: {0.25, 0.5} x_range:[0,5] x_label: world.get_message('MSG_SUBMERSION'){
				loop i from: 0 to: 3{
					data districts_in_game[i].district_name value: districts_in_game[i].data_totAU color: dist_colors[i];
				}			
			}
			
			chart world.get_message('MSG_AREA')+" N" type: series size: {0.24,0.45} position: {0.50, 0.5} x_range:[0,5] x_label: world.get_message('MSG_SUBMERSION'){
				loop i from: 0 to: 3{
					data districts_in_game[i].district_name value: districts_in_game[i].data_totN color: dist_colors[i];
				} 			
			}
			chart world.get_message('MSG_AREA')+" A" type: series size: {0.24,0.45} position: {0.75, 0.5} x_range:[0,5] x_label: world.get_message('MSG_SUBMERSION'){
				loop i from: 0 to: 3{
					data districts_in_game[i].district_name value: districts_in_game[i].data_totA color: dist_colors[i];
				}			
			}
		}
	}
}
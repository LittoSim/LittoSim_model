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

	// Lisflood configuration for the study area
	string application_name 	<- shapes_def["APPLICATION_NAME"]; 											// used to name exported files
	// sea heights file sent to Lisflood
	string lisflood_start_file	<- shapes_def["LISFLOOD_START_FILE"];
	string lisflood_bci_file	<- shapes_def["LISFLOOD_BCI_FILE"];
	string lisflood_bdy_file 	->{floodEventType = HIGH_FLOODING? shapes_def ["LISFLOOD_BDY_HIGH_FILENAME"] // scenario1 : HIGH 
								:(floodEventType  = LOW_FLOODING ? shapes_def ["LISFLOOD_BDY_LOW_FILENAME" ] // scenario2 : LOW
		  						:get_message('MSG_FLOODING_TYPE_PROBLEM'))};
	// paths to Lisflood
	string lisfloodPath 			<- flooding_def["LISFLOOD_PATH"]; 										// absolute path to Lisflood : "C:/lisflood-fp-604/"
	string lisfloodRelativePath 	<- flooding_def["LISFLOOD_RELATIVE_PATH"]; 								// Lisflood folder relatife path 
	string results_lisflood_rep 	<- flooding_def["RESULTS_LISFLOOD_REP"]; 								// Lisflood results folder
	string lisflood_par_file 		-> {"inputs/" + "LittoSIM_GEN_" + application_name + "_config_" + floodEventType + timestamp + ".par"};   // parameter file
	string lisflood_DEM_file 		-> {"inputs/" + "LittoSIM_GEN_" + application_name + "_DEM"     + timestamp + ".asc"}; 					  // DEM file 
	string lisflood_rugosity_file 	-> {"inputs/" + "LittoSIM_GEN_" + application_name + "_n"       + timestamp + ".asc"}; 					  // rugosity file
	string lisflood_bat_file 		<- flooding_def["LISFLOOD_BAT_FILE"];												       		  // Lisflood executable
	
	// variables for Lisflood calculs 
	map<string,string> list_flooding_events;  			// list of submersions of a round
	string floodEventType;
	int lisfloodReadingStep <- 9999999; 				// to indicate to which step of Lisflood results, the current cycle corresponds // lisfloodReadingStep = 9999999 it means that there is no Lisflood result corresponding to the current cycle 
	string timestamp 		<- ""; 						// used to specify a unique name to the folder of flooding results
	string flood_results 	<- "";   					// text of flood results per district // saved as a txt file
	
	// parameters for saving submersion results
	string results_rep 			<- results_lisflood_rep + "/results" + EXPERIMENT_START_TIME; 		// folder to save main model results
	string shape_export_filePath -> {results_rep + "/results_SHP_Tour" + game_round + ".shp"}; 		// shapefile to save cells
	string log_export_filePath 	<- results_rep + "/log_" + machine_time + ".csv"; 					// file to save user actions (main model and players actions)  
	
	// operation variables
	geometry shape 				<- envelope(convex_hull_shape);				// world geometry
	float EXPERIMENT_START_TIME <- machine_time; 							// machine time at simulation initialization
	int messageID 				<- 0; 										// network communication
	geometry all_flood_risk_area; 											// geometry agrregating risked area polygons
	geometry all_protected_area; 											// geometry agrregating protected area polygons	
	
	list<list<int>> districts_budgets <- [[],[],[],[]];						// budget tables to draw evolution graphs
	int new_comers_still_to_dispatch <- 0;									// population dynamics
	
	// other variables 
	bool show_max_water_height	<- false;						// defines if the water_height displayed on the map should be the max one or the current one
	string stateSimPhase 		<- SIM_NOT_STARTED; 			// state variable of current simulation state 
	int game_round 				<- 0;
	bool game_paused			<- false;
	point play_b;
	point pause_b;
	list<District> districts_in_game;
	District dieppe;
	District criel;
	
	init{
		// Create GIS agents
		create District from: districts_shape with: [district_code::string(read("dist_code")),
													 district_name::string(read("dist_sname")),
													 dist_id::int(read("player_id"))];
													 
		districts_in_game <- (District where (each.dist_id > 0)) sort_by (each.dist_id);
		dieppe <- first(District where (each.district_name = "dieppe"));
		criel  <- first(District where (each.district_name = "criel"));
		
		create Coastal_Defense from: coastal_defenses_shape with: [
									coast_def_id::int(read("ID")),type::string(read("type")), status::string(read("status")),
									alt::float(get("alt")), height::float(get("height")), district_code::string(read("dist_code"))];
		
		create Protected_Area from: protected_areas_shape;
		all_protected_area <- union(Protected_Area);
		
		create Road from: roads_shape;
		create Water from: water_shape;
		
		create Flood_Risk_Area from: rpp_area_shape;
		all_flood_risk_area <- union(Flood_Risk_Area);
		
		create Coastal_Border_Area from: coastline_shape { shape <-  shape + coastBorderBuffer#m; }
		create Inland_Dike_Area from: buffer_in_100m_shape;
		
		create Land_Use from: land_use_shape with: [id::int(read("ID")), lu_code::int(read("unit_code")),
													dist_code::string(read("dist_code")), population::int(get("unit_pop"))]{
			lu_name 	<- lu_type_names[lu_code];
			my_color 	<- cell_color();
			if lu_name = "U"  and population = 0 {
				population <- MIN_POP_AREA;
			}
			if lu_name = "AU" {
				AU_to_U_counter <- flip(0.5)?1:0;
				not_updated <- true;
			}
		}
		
		ask Land_Use { cells <- Cell overlapping self;	}
		ask districts_in_game{
			LUs 	<- Land_Use where (each.dist_code = self.district_code);
			cells 	<- LUs accumulate (each.cells);
			budget 	<- int(self.current_population() * tax_unit * (1 +  pctBudgetInit / 100));
			write world.get_message('MSG_COMMUNE') + " " + district_name + " (" + district_code + ") " + dist_id + " " + world.get_message('MSG_INITIAL_BUDGET') + ": " + budget;
			do calculate_indicators_t0;
		}
		
		do load_dem_and_rugosity;
		ask Coastal_Defense {
			do init_coastal_def;
		}
		do init_buttons;
		stateSimPhase <- SIM_NOT_STARTED;
		do add_element_in_list_flooding_events (INITIAL_SUBMERSION, "results");
		
		// Create Network agents
		if activemq_connect {
			create Network_Control_Manager;
			create Network_Listener_To_Leader;
			create Network_Game_Manager;
		}
		create Legend_Planning;
		create Legend_Population;
		create Legend_Map;
	}
	//------------------------------ End of init -------------------------------//
	 	
	int getMessageID{
 		messageID <- messageID +1;
 		return messageID;
 	} 
	
	int new_comers_to_dispatch 	 {
		return round(sum(District where (each.dist_id > 0) accumulate (each.current_population())) * ANNUAL_POP_GROWTH_RATE);
	}

	action new_round {
		if save_shp  {	do save_cells_as_shp_file;	}
		write get_message('MSG_NEW_ROUND') + " : " + (game_round + 1);
		if game_round != 0 {
			ask Coastal_Defense where (each.type = COAST_DEF_TYPE_DIKE) {  do degrade_dike_status; }
		   	ask Coastal_Defense where (each.type = COAST_DEF_TYPE_DUNE) {  do evolve_dune_status;  }
			new_comers_still_to_dispatch <- new_comers_to_dispatch();
			ask shuffle(Land_Use) 			 { pop_updated <- false; do evolve_AU_to_U;  }
			ask shuffle(Land_Use) 			 { do evolve_U_densification; 				 }
			ask shuffle(Land_Use) 			 { do evolve_U_standard; 					 } 
			ask districts_in_game			 { do calculate_taxes;						 }
		}
		else {
			stateSimPhase <- SIM_GAME;
			write stateSimPhase;
		}
		game_round <- game_round + 1;
		ask District 				 	{	do inform_new_round;			} 
		ask Network_Listener_To_Leader  {	do inform_leader_round_number;	}
		do save_budget_data;
		write get_message('MSG_GAME_DONE') + " !";
	} 	
	
	int district_id (string dist_code){
		District d <- first(District first_with (each.district_code = dist_code));
		return d != nil ? d.dist_id : 0;
	}

	reflex show_flood_stats when: stateSimPhase = SIM_SHOWING_FLOOD_STATS {			// end of flooding
		write flood_results;
		save flood_results to: lisfloodRelativePath + results_rep + "/flood_results-" + machine_time + "-Tour" + game_round + ".txt" type: "text";
		ask Cell { water_height <- 0.0; } // reset water heights						
		ask Coastal_Defense {
			if rupture = 1 { do remove_rupture; }
		}
		if game_round = 0{		// restarting the game
			stateSimPhase <- SIM_NOT_STARTED;
			write stateSimPhase;
		}
		else{
			stateSimPhase <- SIM_GAME;
			write stateSimPhase + " - " + get_message('MSG_ROUND') + " " + game_round;
		}
	}
	
	reflex calculate_flood_stats when: stateSimPhase = SIM_CALCULATING_FLOOD_STATS{			// end of a flooding event
		do calculate_districts_results; 													// calculating results
		stateSimPhase <- SIM_SHOWING_FLOOD_STATS;
		write stateSimPhase;
	}
	
	reflex show_lisflood when: stateSimPhase = SIM_SHOWING_LISFLOOD	{	do read_lisflood;	} // reading flooding files
	
	action replay_flood_event (int fe) {
		string replayed_flooding_event  <- (list_flooding_events.keys)[fe];
		write replayed_flooding_event;
		ask Cell { max_water_height <- 0.0;	} // reset of max_water_height
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
		else{											// excuting Lisflood
			do new_round;
			ask Cell { max_water_height <- 0.0;	} // reset of max_water_height
			ask Coastal_Defense {	do calculate_rupture;		}
			stateSimPhase <- SIM_EXEC_LISFLOOD;
			write stateSimPhase;
			do execute_lisflood;
		} 
		lisfloodReadingStep <- 0;
		stateSimPhase 		<- SIM_SHOWING_LISFLOOD;
		write stateSimPhase;
	}

	action add_element_in_list_flooding_events (string sub_name, string sub_rep){
		put sub_rep key: sub_name in: list_flooding_events;
		ask Network_Control_Manager{
			do update_submersion_list;
		}
	}
		
	action execute_lisflood{
		timestamp <- "_R" + game_round + "_t" + machine_time;
		results_lisflood_rep <- "results" + timestamp;
		do save_dem_and_rugosity;
		do save_lf_launch_files;
		do add_element_in_list_flooding_events("Submersion round " + game_round , results_lisflood_rep);
		save "Directory created by LittoSIM GAMA model" to: lisfloodRelativePath + results_lisflood_rep + "/readme.txt" type: "text";// need to create the lisflood results directory because lisflood cannot create it by himself
		ask Network_Game_Manager {
			do execute command: "cmd /c start " + lisfloodPath + lisflood_bat_file;
		}
 	}
 		
	action save_lf_launch_files {
		save ("DEMfile         " + lisfloodPath + lisflood_DEM_file + 
				"\nresroot         res\ndirroot         results\nsim_time        52200\ninitial_tstep   10.0\nmassint         100.0\nsaveint         3600.0\nmanningfile     " +
				lisfloodPath+lisflood_rugosity_file + "\nbcifile         " + lisfloodPath + lisflood_bci_file + "\nbdyfile         " + lisfloodPath + lisflood_bdy_file + 
				"\nstartfile       " + lisfloodPath + lisflood_start_file +"\nstartelev\nelevoff\nSGC_enable\n") rewrite: true to: lisfloodRelativePath + lisflood_par_file type: "text";
		
		save (lisfloodPath + "lisflood.exe -dir " + lisfloodPath + results_lisflood_rep + " " + (lisfloodPath + lisflood_par_file)) rewrite: true to: lisfloodRelativePath + lisflood_bat_file type: "text";
	}       

	action save_dem_and_rugosity {
		string dem_filename <- lisfloodRelativePath + lisflood_DEM_file;
		string rug_filename <- lisfloodRelativePath + lisflood_rugosity_file;
		
		string h_txt <- 'ncols         ' + DEM_NB_COLS + '\nnrows         ' + DEM_NB_ROWS + '\nxllcorner     ' + DEM_XLLCORNER +
						'\nyllcorner     ' + DEM_YLLCORNER + '\ncellsize      ' + DEM_CELL_SIZE + '\nNODATA_value  -9999';
		
		save h_txt rewrite: true to: dem_filename type: "text";
		save h_txt rewrite: true to: rug_filename type: "text";
		string dem_data;
		string rug_data;
		loop i from: 0 to: DEM_NB_ROWS - 1 {
			dem_data <- "";
			rug_data <- "";
			loop j from: 0 to: DEM_NB_COLS - 1 {
				dem_data <- dem_data + " " + Cell[j,i].soil_height;
				rug_data <- rug_data + " " + Cell[j,i].rugosity;
			}
			save dem_data to: dem_filename rewrite: false;
			save rug_data to: rug_filename rewrite: false;
		}
	}
	
	action save_cells_as_shp_file {
		save Cell type:"shp" to: shape_export_filePath with: [soil_height::"SOIL_HEIGHT", water_height::"WATER_HEIGHT"];
	}
	
	action save_budget_data {
		loop ix from: 1 to: 4 {
			add (District first_with(each.dist_id = ix)).budget to: districts_budgets[ix-1];
		}
	}	
	   
	action read_lisflood {  
	 	string nb <- string(lisfloodReadingStep);
		loop i from: 0 to: 3 - length(nb) {
			nb <- "0" + nb;
		}
		string fileName <- lisfloodRelativePath + results_lisflood_rep + "/res-" + nb + ".wd";
		write "lisfloodRelativePath " + lisfloodRelativePath;
		write "results_lisflood_rep " + results_lisflood_rep;
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
     		}
     	}
	}
	
	action load_dem_and_rugosity {
		list<string> dem_data <- [];
		list<string> rug_data <- [];
		file dem_grid <- text_file(dem_file);
		file rug_grid <- text_file(RUGOSITY_DEFAULT);
		
		DEM_XLLCORNER <- float((dem_grid [2] split_with " ")[1]);
		DEM_YLLCORNER <- float((dem_grid [3] split_with " ")[1]);
		DEM_CELL_SIZE <- int((dem_grid [4] split_with " ")[1]);
		float no_data_value <- float((dem_grid [5] split_with " ")[1]);
		
		loop rw from: 0 to: DEM_NB_ROWS - 1 {
			dem_data <- dem_grid [rw+6] split_with " ";
			rug_data <- rug_grid [rw+6] split_with " ";
			loop cl from: 0 to: DEM_NB_COLS - 1 {
				Cell[cl, rw].soil_height <- float(dem_data[cl]);
				Cell[cl, rw].rugosity <- float(rug_data[cl]);
			}
		}
		ask Cell {
			if soil_height > 0 {
				cell_type <-1; //  1 -> land
			}  
		}
		
		land_min_height <- min(Cell where (each.cell_type = 1 and each.soil_height != no_data_value) collect each.soil_height);
		land_max_height <- max(Cell where (each.cell_type = 1 and each.soil_height != no_data_value) collect each.soil_height);
		land_range_height <- land_max_height - land_min_height;
		cells_max_depth <- abs(min(Cell where (each.cell_type = 0 and each.soil_height != no_data_value) collect each.soil_height));
		ask Cell {
			do init_cell_color;
		}
	}
	
	action calculate_districts_results {
		string text <- "";
			ask ((District where (each.dist_id > 0)) sort_by (each.dist_id)){
				int tot <- length(cells);
				int myid <-  self.dist_id; 
				int U_0_5 <-0;		int U_1 <-0;		int U_max <-0;
				int Us_0_5 <-0;		int Us_1 <-0;		int Us_max <-0;
				int Udense_0_5 <-0;	int Udense_1 <-0;	int Udense_max <-0;
				int AU_0_5 <-0;		int AU_1 <-0;		int AU_max <-0;
				int A_0_5 <-0;		int A_1 <-0;		int A_max <-0;
				int N_0_5 <-0;		int N_1 <-0;		int N_max <-0;
				
				ask LUs{
					ask cells {
						if max_water_height > 0{
							switch myself.lu_name{ //"U","Us","AU","N","A"    -> but not  "AUs"
								match "AUs" {
									write "STOP :  AUs " + world.get_message('MSG_IMPOSSIBLE_NORMALLY');
								}
								match "U" {
									if max_water_height <= 0.5 					{
										U_0_5 <- U_0_5 +1;
										if myself.density_class = POP_DENSE 	{	Udense_0_5 <- Udense_0_5 +1;	}
									}
									if between (max_water_height ,0.5, 1.0) 	{
										U_1 <- U_1 +1;
										if myself.density_class = POP_DENSE 	{	Udense_1 <- Udense_1 +1;		}
									}
									if max_water_height >= 1					{
										U_max <- U_max +1;
										if myself.density_class = POP_DENSE 	{	Udense_0_5 <- Udense_0_5 +1;	}
									}
								}
								match "Us" {
									if max_water_height <= 0.5 				{	Us_0_5 <- Us_0_5 +1;			}
									if between (max_water_height ,0.5, 1.0) {	Us_1 <- Us_1 +1;				}
									if max_water_height >= 1				{	Us_max <- Us_max +1;			}
								}
								match "AU" {
									if max_water_height <= 0.5 				{	AU_0_5 <- AU_0_5 +1;			}
									if between (max_water_height ,0.5, 1.0) {	AU_1 <- AU_1 +1;				}
									if max_water_height >= 1.0 				{	AU_max <- AU_max +1;			}
								}
								match "N"  {
									if max_water_height <= 0.5 				{	N_0_5 <- N_0_5 +1;				}
									if between (max_water_height ,0.5, 1.0) {	N_1 <- N_1 +1;					}
									if max_water_height >= 1.0 				{	N_max <- N_max +1;				}
								}
								match "A" {
									if max_water_height <= 0.5 				{	A_0_5 <- A_0_5 +1;				}
									if between (max_water_height ,0.5, 1.0) {	A_1 <- A_1 +1;					}
									if max_water_height >= 1.0 				{	A_max <- A_max +1;				}
								}	
							}
						}
					}
				}
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
				text <- text + "Résultats commune " + district_name +"
Surface U innondée : moins de 50cm " + ((U_0_5c) with_precision 1) +" ha ("+ ((U_0_5 / tot * 100) with_precision 1) +"%) | entre 50cm et 1m " + ((U_1c) with_precision 1) +" ha ("+ ((U_1 / tot * 100) with_precision 1) +"%) | plus de 1m " + ((U_maxc) with_precision 1) +" ha ("+ ((U_max / tot * 100) with_precision 1) +"%) 
Surface Us innondée : moins de 50cm " + ((Us_0_5c) with_precision 1) +" ha ("+ ((Us_0_5 / tot * 100) with_precision 1) +"%) | entre 50cm et 1m " + ((Us_1c) with_precision 1) +" ha ("+ ((Us_1 / tot * 100) with_precision 1) +"%) | plus de 1m " + ((Us_maxc) with_precision 1) +" ha ("+ ((Us_max / tot * 100) with_precision 1) +"%) 
Surface Udense innondée : moins de 50cm " + ((Udense_0_5c) with_precision 1) +" ha ("+ ((Udense_0_5 / tot * 100) with_precision 1) +"%) | entre 50cm et 1m " + ((Udense_1 * 0.04) with_precision 1) +" ha ("+ ((Udense_1 / tot * 100) with_precision 1) +"%) | plus de 1m " + ((Udense_max * 0.04) with_precision 1) +" ha ("+ ((Udense_max / tot * 100) with_precision 1) +"%) 
Surface AU innondée : moins de 50cm " + ((AU_0_5c) with_precision 1) +" ha ("+ ((AU_0_5 / tot * 100) with_precision 1) +"%) | entre 50cm et 1m " + ((AU_1c) with_precision 1) +" ha ("+ ((AU_1 / tot * 100) with_precision 1) +"%) | plus de 1m " + ((AU_maxc) with_precision 1) +" ha ("+ ((AU_max / tot * 100) with_precision 1) +"%) 
Surface A innondée : moins de 50cm " + ((A_0_5c) with_precision 1) +" ha ("+ ((A_0_5 / tot * 100) with_precision 1) +"%) | entre 50cm et 1m " + ((A_1c) with_precision 1) +" ha ("+ ((A_1 / tot * 100) with_precision 1) +"%) | plus de 1m " + ((A_maxc) with_precision 1) +" ha ("+ ((A_max / tot * 100) with_precision 1) +"%) 
Surface N innondée : moins de 50cm " + ((N_0_5c) with_precision 1) +" ha ("+ ((N_0_5 / tot * 100) with_precision 1) +"%) | entre 50cm et 1m " + ((N_1c) with_precision 1) +" ha ("+ ((N_1 / tot * 100) with_precision 1) +"%) | plus de 1m " + ((N_maxc) with_precision 1) +" ha ("+ ((N_max / tot * 100) with_precision 1) +"%) 
--------------------------------------------------------------------------------------------------------------------
";	
			}
			flood_results <-  text;
				
			write get_message('MSG_FLOODED_AREA_DISTRICT');
			ask ((District where (each.dist_id > 0)) sort_by (each.dist_id)){
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
			location 	<- { 1000, 1000 };
			my_icon 	<- image_file("../images/icons/one_step.png");
			display_text <- world.get_message('MSG_NEW_ROUND');
		}
		create Button{
			nb_button 	<- 1;
			command  	<- LOCK_USERS;
			location 	<- { 1000, 3000 };
			my_icon 	<- image_file("../images/icons/pause.png");
			display_text <- "Pause game";
			pause_b <- self.location;
		}
		create Button{
			nb_button 	<- 2;
			command  	<- UNLOCK_USERS;
			location 	<- { 1000, 5000 };
			my_icon 	<- image_file("../images/icons/play.png");
			display_text <- "Resume game";
			play_b <- self.location;
		}
		create Button{
			nb_button 	<- 3;
			command	 	<- HIGH_FLOODING;
			location 	<- {5000, 1000};
			my_icon 	<- image_file("../images/icons/launch_lisflood.png");
			display_text <- "High flooding";
		}
		create Button{
			nb_button 	<- 5;
			command	 	<- LOW_FLOODING;
			location 	<- {7000, 1000};
			my_icon 	<- image_file("../images/icons/launch_lisflood_small.png");
			display_text <- "Low flooding";
		}
		create Button{
			nb_button 	<- 6;
			command  	<- "0";
			location 	<- {11000, 1000};
			my_icon 	<- image_file("../images/icons/0.png");
			display_text <- "Replay initial submersion";
		}
		create Button{
			nb_button 	<- 6;
			command  	<- "1";
			location 	<- {11000, 3000};
			my_icon 	<- image_file("../images/icons/1.png");
			display_text <- "Replay submersion 1";
		}
		create Button {
			nb_button 	<- 6;
			command  	<- "2";
			location 	<- {11000, 5000};
			my_icon 	<- image_file("../images/icons/2.png");
			display_text <- "Replay submersion 2";
		}
		create Button{
			nb_button 	<- 6;
			command  	<- "3";
			location 	<- {11000, 7000};
			my_icon 	<- image_file("../images/icons/3.png");
			display_text <- "Replay submersion 3";
		}
		create Button{
			nb_button 	<- 6;
			command  	<- "4";
			location 	<- { 11000, 9000 };
			my_icon 	<- image_file("../images/icons/4.png");
			display_text <- "Replay submersion 4";
		}
		
		create Button{
			nb_button 	<- 4;
			command  	<- SHOW_LU_GRID;
			shape 		<- square(800);
			location 	<- { 800, 800 };
			my_icon 	<- image_file("../images/icons/avec_quadrillage.png");
			is_selected <- false;
		}
		create Button{
			nb_button 	<- 7;
			command	 	<- SHOW_MAX_WATER_HEIGHT;
			shape 		<- square(800);
			location 	<- { 1800, 800 };
			my_icon 	<- image_file("../images/icons/max_water_height.png");
			is_selected <- false;
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
						is_selected <- true;
						ask world { do replay_flood_event(int(myself.command));}
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
	
	rgb color_of_water_height (float aWaterHeight){
		if 		aWaterHeight  	<= 0.5	{	return rgb (200,200,255);	}
		else if aWaterHeight  	<= 1  	{	return rgb (115,115,255);	}
		else if aWaterHeight	<= 2  	{	return rgb (65,65,255);		}
		else 							{	return rgb (30,30,255);		}
	}
}
//------------------------------ End of world global -------------------------------//

species Network_Game_Manager skills: [network]{
	
	init{
		write world.get_message('MSG_START_SENDER');
		do connect to: SERVER with_name: GAME_MANAGER;
	}
	
	reflex wait_message when: activemq_connect{
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
					}
					write world.get_message('MSG_CONNECTION_FROM') + " " + m_sender + " " + id_dist;
				}
				match PLAYER_ACTION {  // another player action
				if(game_round > 0) {
					write world.get_message('MSG_READ_ACTION') + " : " + m_contents;
					if(int(m_contents["command"]) in ACTION_LIST) {
						create Player_Action {
							self.command 					<- int(m_contents["command"]);
							self.command_round  			<- game_round; 
							self.id 						<- m_contents["id"];
							self.initial_application_round 	<- int(m_contents["initial_application_round"]);
							self.district_code 				<- m_sender;
							self.element_id 				<- int(m_contents["element_id"]);
							self.action_type 				<- m_contents["action_type"];
							self.is_in_protected_area 		<- bool(m_contents["inProtectedArea"]);
							self.previous_lu_name 			<- m_contents["previous_lu_name"];
							self.is_expropriation 			<- bool(m_contents["is_expropriation"]);
							self.cost 						<- float(m_contents["cost"]);
							if command = ACTION_CREATE_DIKE { 
								element_shape 	 <- polyline([{float(m_contents["origin.x"]), float(m_contents["origin.y"])},
															{float(m_contents["end.x"]), float(m_contents["end.y"])}]);
								shape 			 <- element_shape;
								length_coast_def <- int(element_shape.perimeter);
								location 		 <- {float(m_contents["location.x"]),float(m_contents["location.y"])}; 
							}
							else{
								if is_expropriation { write world.get_message('MSG_EXPROPRIATION_TRIGGERED') + " " + self.id; }
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
							if  self.element_shape intersects first(Coastal_Border_Area) {	is_in_coast_border_area <- true;	}
							if  self.element_shape intersects all_protected_area 		 {	is_in_protected_area 	<- true;	}
							if command = ACTION_CREATE_DIKE and (self.element_shape.centroid overlaps first(Inland_Dike_Area))	{	is_inland_dike <- true;	}
							if(log_user_action){
								save ([string(machine_time - EXPERIMENT_START_TIME), self.district_code] + m_contents.values) to: log_export_filePath rewrite: false type:"csv";
							}
							ask District first_with(each.dist_id = world.district_id (self.district_code)) {
								budget <- int(budget - myself.cost);					// updating players payment (server side)
							}
						} // end of create Player_Action
					}
				}
				}
				}			
			}				
		}
	}

	reflex apply_player_action when: length (Player_Action where (each.is_alive)) > 0{
		ask Player_Action where (each.is_alive and each.should_be_applied and !each.should_wait_lever_to_activate) {
			int id_dist <- world.district_id (district_code);
			bool acknowledge <- false;
			switch(command){
				match ACTION_CREATE_DIKE{	
					ask(create_dike (self)) {
						do build_dike;
						acknowledge <- true;
					}
				}
				match ACTION_REPAIR_DIKE {
					ask(Coastal_Defense first_with(each.coast_def_id = element_id)){
						do repaire_dike;
						not_updated <- true;
						acknowledge <- true;
					}
				}
			 	match ACTION_DESTROY_DIKE {
			 		ask(Coastal_Defense first_with(each.coast_def_id = element_id)){
						not_updated <- true;
						acknowledge <- true;
						do destroy_dike;
					}		
				}
			 	match ACTION_RAISE_DIKE {
			 		ask(Coastal_Defense first_with(each.coast_def_id = element_id)){
						do raise_dike;
						not_updated <- true;
						acknowledge <- true;
					}
				}
				match ACTION_INSTALL_GANIVELLE {
				 	ask(Coastal_Defense first_with(each.coast_def_id = element_id)){
						do install_ganivelle;
						not_updated <- true;
						acknowledge <- true;
					}
				}
				match_one [ACTION_MODIFY_LAND_COVER_A, ACTION_MODIFY_LAND_COVER_AU, ACTION_MODIFY_LAND_COVER_N,
							ACTION_MODIFY_LAND_COVER_Us, ACTION_MODIFY_LAND_COVER_AUs] {
					ask Land_Use first_with(each.id = element_id){
			 			do modify_LU (world.lu_name_of_command(myself.command));
			 		  	not_updated <- true;
			 		  	acknowledge <- true;
			 		}
				}
			 	match ACTION_MODIFY_LAND_COVER_Ui {
			 		ask Land_Use first_with(each.id = element_id){
			 			isInDensification <- true;
			 		 	not_updated <- true;
			 		 	acknowledge <- true;
			 		 }
			 	 }
			}
			if(acknowledge) {
				ask Network_Game_Manager { do acknowledge_application_of_player_action(myself); }
			}
			is_alive 	<- false; 
			is_applied 	<- true;
		}		
	}
	
	action acknowledge_application_of_player_action (Player_Action act){
		map<string,string> msg <- ["TOPIC"::PLAYER_ACTION_IS_APPLIED,"id"::act.id];
		put act.district_code  at: DISTRICT_CODE   in:		 msg;
		do send to: act.district_code contents: msg;
	}
	
	reflex update_LU when: length (Land_Use where(each.not_updated)) > 0 {
		string msg <- "";
		ask Land_Use where(each.not_updated) {
			map<string,string> msg <- ["TOPIC"::ACTION_LAND_COVER_UPDATE, "id"::id, "lu_code"::lu_code,
							"population"::population, "isInDensification"::isInDensification];
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
			map<string, string> mp <- tmp.build_map_from_attributes();
			put DATA_RETRIEVE at: "TOPIC" in: mp;
			do send to: d.district_code contents: mp;
		}
		loop tmp over: d.LUs{
			map<string, string> mp <- tmp.build_map_from_attributes();
			put DATA_RETRIEVE at: "TOPIC" in: mp;
			do send to: d.district_code contents: mp;
		}
		loop tmp over: Player_Action where(each.district_code = d.district_code){
			map<string, string> mp <- tmp.build_map_from_attributes();
			put DATA_RETRIEVE at: "TOPIC" in: mp;
			do send to: d.district_code contents: mp;
		}
		loop tmp over: Activated_Lever where(each.my_map[DISTRICT_CODE] = d.district_code) {
			map<string, string> mp <- tmp.my_map;
			put DATA_RETRIEVE at: "TOPIC" in: mp;
			do send to: d.district_code contents: mp;
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
			switch(cmd){
				match GIVE_MONEY_TO {
					string dist_code 	 <- m_contents[DISTRICT_CODE];
					int amount 			 <- int(m_contents[AMOUNT]);
					District d 			 <- District first_with(each.district_code = dist_code);
					d.budget 			 <- d.budget + amount;
				}
				match TAKE_MONEY_FROM {
					string dist_code 	 <- m_contents[DISTRICT_CODE];
					int amount 			 <- int(m_contents[AMOUNT]); 
					District d 			 <- District first_with(each.district_code = dist_code);
					d.budget 			 <- d.budget - amount;
				}
				match ASK_NUM_ROUND 		 {	do inform_leader_round_number;	}
				match ASK_INDICATORS_T0 	 {	do inform_leader_indicators_t0;	}
				match ASK_ACTION_STATE  	 {
					ask Player_Action { is_sent_to_leader <- false; }
				}
				match ACTION_SHOULD_WAIT_LEVER_TO_ACTIVATE {
					Player_Action act <- Player_Action first_with (each.id = string(m_contents[PLAYER_ACTION_ID]));
					write "Action : " + act;
					act.should_wait_lever_to_activate <- bool (m_contents[ACTION_SHOULD_WAIT_LEVER_TO_ACTIVATE]);
					write "Should wait ? " + act.should_wait_lever_to_activate;
				}
				match NEW_ACTIVATED_LEVER {
					if empty(Activated_Lever where (int(each.my_map["id"]) = int(m_contents["id"]))){
						create Activated_Lever{
							do init_from_map (m_contents);
							ply_action	<- Player_Action first_with (each.id 			= my_map["p_action_id"]);
							District d 	<- District 	 first_with (each.district_code = my_map["district_code"]);
							d.budget 	<- d.budget  -  int(my_map["added_cost"]); 
							add self to: ply_action.activated_levers;
							ply_action.a_lever_has_been_applied <- true;
						}
					}
				}
			}	
		}
	}
	
	reflex inform_leader_action_state when: cycle mod 10 = 0 {
		loop act over: Player_Action where (!each.is_sent_to_leader){
			map<string,string> msg <- act.build_map_from_attributes();
			put ACTION_STATE 			key: RESPONSE_TO_LEADER in: msg;
			do send to: GAME_LEADER 	contents: msg;
			act.is_sent_to_leader <- true;
			write "" + world.get_message('MSG_SEND_TO_LEADER') + " : " + msg;
		}
	}
	
	action inform_leader_round_number {
		map<string,string> msg <- [];
		put NUM_ROUND 			key: RESPONSE_TO_LEADER 	in: msg;
		put string(game_round) 	key: NUM_ROUND 				in: msg;
		do send to: GAME_LEADER contents: msg;
	}
				
	action inform_leader_indicators_t0  {
		ask District where (each.dist_id > 0) {
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
	
	action init_from_map (map<string, string> m ){
		my_map <- m;
		put OBJECT_TYPE_ACTIVATED_LEVER at: "OBJECT_TYPE" in: my_map;
	}
}
//------------------------------ End of Activated_lever -------------------------------//

species Player_Action schedules:[]{
	string id;
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

	map<string,string> build_map_from_attributes{
		map<string,string> res <- [
			"OBJECT_TYPE"::OBJECT_TYPE_PLAYER_ACTION,
			"id"::id,
			"element_id"::string(element_id),
			"command"::string(command),
			"label"::label,
			"cost"::string(cost),
			"initial_application_round"::string(initial_application_round),
			"is_inland_dike"::string(is_inland_dike),
			"is_in_risk_area"::string(is_in_risk_area),
			"is_in_coast_border_area"::string(is_in_coast_border_area),
			"is_expropriation"::string(is_expropriation),
			"is_in_protected_area"::string(is_in_protected_area),
			"previous_lu_name"::previous_lu_name,
			"action_type"::action_type,
			"locationx"::string(location.x),
			"locationy"::string(location.y),
			"is_applied"::string(is_applied),
			"is_sent"::string(is_sent),
			"command_round"::string(command_round),
			"element_shape"::string(element_shape),
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
	
	Coastal_Defense create_dike (Player_Action act){
		int next_coast_def_id <- max(Coastal_Defense collect(each.coast_def_id)) +1;
		create Coastal_Defense returns: tmp_dike{
			coast_def_id <- next_coast_def_id;
			district_code<- act.district_code;
			shape 		<- act.element_shape;
			location 	<- act.location;
			type 		<- COAST_DEF_TYPE_DIKE;
			status 		<- BUILT_DIKE_STATUS;
			height 		<- BUILT_DIKE_HEIGHT;	
			cells 		<- Cell overlapping self;
			alt 		<- min(cells collect(each.soil_height));
		}
		Coastal_Defense new_dike <- first (tmp_dike);
		act.element_id 		<-  new_dike.coast_def_id;
		ask Network_Game_Manager {
			new_dike.shape  <- myself.element_shape;
			point p1 		<- first(myself.element_shape.points);
			point p2 		<- last(myself.element_shape.points);
			map<string,string> msg <- ["TOPIC"::ACTION_DIKE_CREATED,
				 "coast_def_id"::new_dike.coast_def_id,"action_id"::myself.id,
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
	string type;     // Dike or Dune
	string status;	//  "Good" "Medium" "Bad"  
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
	
	map<string,unknown> build_map_from_attributes{
		map<string,unknown> res <- [
			"OBJECT_TYPE"::OBJECT_TYPE_COASTAL_DEFENSE,
			"coast_def_id"::string(coast_def_id),
			"type"::type, "status"::status,
			"height"::string(height),
			"alt"::string(alt),
			"rupture"::string(rupture),
			"rupture_area"::rupture_area,
			"not_updated"::string(not_updated),
			"ganivelle"::string(ganivelle),
			"height_before_ganivelle"::string(height_before_ganivelle),
			"locationx"::string(location.x),
			"locationy"::string(location.y)];
			int i <- 0;
			loop pp over:shape.points{
				put string(pp.x) key:"locationx"+i in: res;
				put string(pp.y) key:"locationy"+i in: res;
				i <- i+ 1;
			}
		return res;
	}
	
	action init_coastal_def {
		if status = ""  { status <- STATUS_GOOD; 			 } 
		if type = '' 	{ type 	<- "Unknown";				 }
		if height = 0.0 { height <- MIN_HEIGHT_DIKE;		 }
		counter_status 	<- type = COAST_DEF_TYPE_DUNE ? rnd (STEPS_DEGRAD_STATUS_DUNE - 1) : rnd (STEPS_DEGRAD_STATUS_DIKE - 1);
		cells 			<- Cell overlapping self;
		if type = COAST_DEF_TYPE_DUNE  {
			height_before_ganivelle <- height;
		}
		do build_dike;
	}
	
	action build_dike {
		// a dike raises soil around the highest cell
		float h <- cells max_of (each.soil_height);
		alt 	<- h + height;
		ask cells  {
			soil_height <- h + myself.height;
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
		alt 	<- alt 	  + RAISE_DIKE_HEIGHT;
		ask cells {
			soil_height <- soil_height + RAISE_DIKE_HEIGHT;
			soil_height_before_broken <- soil_height;
			do init_cell_color();
		}
	}
	
	action destroy_dike {
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
					soil_height 			  <- soil_height + H_DELTA_GANIVELLE;
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
		else if type = COAST_DEF_TYPE_DUNE {
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
				if soil_height >= 0 {	soil_height <- max([0, soil_height - myself.height]);	}
			}
			write "rupture " + type + " n°" + coast_def_id + "(" + ", status " + status + ", height " + height + ", alt " + alt + ")";
			write "rupture " + type + " n°" + coast_def_id + "(" + world.dist_code_sname_correspondance_table at (district_code)+ ", status " + status + ", height " + height + ", alt " + alt + ")";
		}
	}
	
	action remove_rupture {
		rupture <- 0;
		ask cells overlapping rupture_area { if soil_height >= 0 { soil_height <- soil_height_before_broken; } }
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
	int hillshade <- 0;
	
	action init_cell_color {		
		if cell_type = 0 { // sea
			float tmp  <- ((soil_height  / cells_max_depth) with_precision 1) * - 170;
			soil_color <- rgb(80, 80 , int(255 - tmp));
		}else{ // land
			float tmp  <- (((soil_height - land_min_height)  / land_range_height) with_precision 1) * 255;
			soil_color <- rgb(int(255 - tmp), int(180 - tmp) , 0);
		}
	}
	
	aspect water_or_max_water_elevation {
		if cell_type = 0 or (show_max_water_height? max_water_height = 0 : water_height = 0){ // if sea and water level = 0
			color <- soil_color;
		}else{ // if land 
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
	rgb my_color 			<- cell_color() update: cell_color();
	int AU_to_U_counter 	<- 0;
	string density_class 	-> {population = 0? POP_EMPTY :(population < POP_LOW_NUMBER ? POP_LOW_DENSITY: (population < POP_MEDIUM_NUMBER ? POP_MEDIUM_DENSITY : POP_DENSE))};
	int exp_cost 			-> {round (population * 400* population ^ (-0.5))};
	bool isUrbanType 		-> {lu_name in ["U","Us","AU","AUs"]};
	bool isAdapted 			-> {lu_name in ["Us","AUs"]};
	bool isInDensification 	<- false;
	bool not_updated 		<- false;
	bool pop_updated 		<- false;
	int population;
	list<Cell> cells;
	
	map<string,unknown> build_map_from_attributes {
		map<string,string> res <- [
			"OBJECT_TYPE"::OBJECT_TYPE_LAND_USE,
			"id"::string(id),
			"lu_name"::lu_name,
			"lu_code"::string(lu_code),
			"STEPS_FOR_AU_TO_U"::string(STEPS_FOR_AU_TO_U),
			"AU_to_U_counter"::string(AU_to_U_counter),
			"population"::string(population),
			"isInDensification"::string(isInDensification),
			"not_updated"::string(not_updated),
			"pop_updated"::string(pop_updated),
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
	
	action evolve_U_densification {
		if !pop_updated and isInDensification and (lu_name in ["U","Us"]){
			string previous_d_class <- density_class; 
			do assign_population (POP_FOR_U_DENSIFICATION);
			if previous_d_class != density_class { isInDensification <- false; }
		}
	}
		
	action evolve_U_standard {
		if !pop_updated and (lu_name in ["U","Us"]){
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
		if isAdapted		 {	draw "A" color:#black;	}
		if isInDensification {	draw "D" color:#black;	}
	}

	aspect population_density {
		rgb acolor <- nil;
		switch density_class {
			match POP_EMPTY 		{acolor <- rgb(245,245,245); }
			match POP_LOW_DENSITY 	{acolor <- rgb(220,220,220); } 
			match POP_MEDIUM_DENSITY{acolor <- rgb(192,192,192); }
			match POP_DENSE 		{acolor <- rgb(169,169,169); }
			default 				{acolor <- # yellow;		 }
		}
		draw shape color: acolor;
	}
	
	aspect conditional_outline {
		if (Button first_with (each.nb_button = 4)).is_selected {	draw shape color: rgb (0,0,0,0) border:#black;	}
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
	int budget;
	int received_tax <-0;
	list<Land_Use> LUs;
	list<Cell> cells;
	float tax_unit  <- float(tax_unit_table at district_name); 
	// init water heights
	float U_0_5c  	  <-0.0;		float U_1c 		<-0.0;		float U_maxc 	  <-0.0;
	float Us_0_5c 	  <-0.0;		float Us_1c 	<-0.0;		float Us_maxc 	  <-0.0;
	float Udense_0_5c <-0.0;		float Udense_1c <-0.0;		float Udense_maxc <-0.0;
	float AU_0_5c 	  <-0.0; 		float AU_1c 	<-0.0;		float AU_maxc 	  <-0.0;
	float A_0_5c 	  <-0.0;		float A_1c 		<-0.0;		float A_maxc      <-0.0;
	float N_0_5c 	  <-0.0;		float N_1c 		<-0.0;		float N_maxc 	  <-0.0;
	
	float flooded_area <- 0.0;	list<float> data_flooded_area<- [];
	float totU 		   <- 0.0;	list<float> data_totU 		 <- [];
	float totUs 	   <- 0.0;	list<float> data_totUs 		 <- [];
	float totUdense	   <- 0.0;	list<float> data_totUdense 	 <- [];
	float totAU 	   <- 0.0;	list<float> data_totAU 		 <- [];
	float totN 		   <- 0.0;	list<float> data_totN 		 <- [];
	float totA 		   <- 0.0;	list<float> data_totA 		 <- [];

	// Indicators calculated at initialization, and sent to Leader when he connects
	map<string,string> my_indicators_t0 <- [];

	aspect base	  {	draw shape  color:#whitesmoke;					}
	aspect outline{	draw shape  color: rgb (0,0,0,0) border:#black;	}
	aspect pop_den{	draw shape  color: #lightgray border:#black;	}
	aspect dieppe {
		draw dieppe color: rgb (0,0,0,0) border:#black;
	}
	aspect criel  { draw criel  color: rgb (0,0,0,0) border:#black; }
	
	int current_population {  return sum(LUs accumulate (each.population));	}
	
	action inform_new_round {// inform about a new round
		ask Network_Game_Manager{
			map<string,string> msg <- ["TOPIC"::INFORM_NEW_ROUND];
			put myself.district_code at: DISTRICT_CODE in: msg;
			do send to: myself.district_code contents: msg;
		}
	}
	
	action inform_current_round {// inform about the current round (when the player side district reconnects)
		ask Network_Game_Manager{
			map<string,string> msg <- ["TOPIC"::INFORM_CURRENT_ROUND];
			put myself.district_code  		at: DISTRICT_CODE 	in: msg;
			put string(game_round) 		  	at: NUM_ROUND		in: msg;
			put string(game_paused) 		at: "GAME_PAUSED"	in: msg;
			do send to: myself.district_code contents: msg;
		}
	}

	action inform_budget_update {// inform about the budget (when the player side district reconnects)
		ask Network_Game_Manager{
			map<string,string> msg <- ["TOPIC"::DISTRICT_BUDGET_UPDATE];
			put myself.district_code  	at: DISTRICT_CODE 	in: msg;
			put string(myself.budget) 	at: BUDGET			in: msg;
			do send to: myself.district_code contents: msg;
		}
	}
	
	action calculate_taxes {
		received_tax <- int(self.current_population() * tax_unit);
		budget <- budget + received_tax;
		write district_name + "-> tax " + received_tax + "; budget "+ budget;
	}
	
	action calculate_indicators_t0 {
		list<Coastal_Defense> my_coast_def <- Coastal_Defense where (each.district_code = district_code);
		put string(my_coast_def where (each.type = COAST_DEF_TYPE_DIKE) sum_of (each.shape.perimeter)) key: "length_dikes_t0" in: my_indicators_t0;
		put string(my_coast_def where (each.type = COAST_DEF_TYPE_DUNE) sum_of (each.shape.perimeter)) key: "length_dunes_t0" in: my_indicators_t0;
		put string(length(LUs where (each.isUrbanType))) key: "count_LU_urban_t0" in: my_indicators_t0; // built cells (U , AU, Us and AUs)
		put string(length(LUs where (each.isUrbanType and not(each.isAdapted) and each intersects first(Coastal_Border_Area)))) key: "count_LU_U_and_AU_is_in_coast_border_area_t0" in: my_indicators_t0; // non adapted built cells in littoral area (<400m)
		put string(length(LUs where (each.isUrbanType and each intersects all_flood_risk_area))) key: "count_LU_urban_in_flood_risk_area_t0" in: my_indicators_t0; // built cells in flooded area
		put string(length(LUs where (each.isUrbanType and each.density_class = POP_DENSE and each intersects all_flood_risk_area))) key: "count_LU_urban_dense_in_flood_risk_area_t0" in: my_indicators_t0; // dense cells in risk area
		put string(length(LUs where (each.isUrbanType and each.density_class = POP_DENSE and each intersects union(Coastal_Border_Area)))) key: "count_LU_urban_dense_is_in_coast_border_area_t0" in: my_indicators_t0; //dense cells in littoral area
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
			draw display_text color: #black at: {location.x - (shape.width*0.33), location.y + (shape.height*0.66)};
			draw my_icon size: button_size-50#m;
		} else if(nb_button = 6){
			if (int(command) < length(list_flooding_events)){
				draw shape color: #white border: is_selected ? #red : #white;
				draw list_flooding_events.keys[int(command)] color: #black at: {location.x - (shape.width*0.33), location.y + (shape.height*0.66)};
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
	point start_location <- {700, 750};
	point rect_size <- {300, 400};
	rgb text_color  <- #black;
	
	init{
		texts <- ["N","A","AU, AUs","U empty", "U low","U medium","U dense"];
		colors<- [#palegreen,rgb(225,165,0),#yellow,rgb(245,245,245),rgb(220,220,220),rgb(192,192,192),rgb(169,169,169)];
	}
	
	aspect {
		loop i from: 0 to: length(texts){
			draw rectangle(rect_size) at: start_location + {0, i * rect_size.y} color: colors[i] border: #black;
			draw texts[i] at: start_location + {rect_size.x, i * rect_size.y} color: text_color size: rect_size.y;
		}
	}
}

species Legend_Population parent: Legend_Planning{
	init{
		texts <- ["High density","Medium density","Low density","Empty"];
		colors<- [rgb(169,169,169),rgb(192,192,192),rgb(220,220,220),rgb(245,245,245)];
	}
}

species Legend_Map parent: Legend_Planning{
	init {
		start_location <- {700, 1500};
		text_color <- #white;
		int t1 <- int(land_range_height*0.25);
		int t2 <- int(land_range_height*0.5);
		int t3 <- int(land_range_height*0.75);
		texts <- [''+int(land_max_height)+' m',''+t3+' m',''+t2+' m',''+t1+' m',''+int(land_min_height)+' m'];

		float c1  <- (((t1 - land_min_height)  / land_range_height) with_precision 1) * 255;
		float c2  <- (((t2 - land_min_height)  / land_range_height) with_precision 1) * 255;
		float c3  <- (((t3 - land_min_height)  / land_range_height) with_precision 1) * 255;

		colors<- [rgb(0,0,0), rgb(int(255 - c3), int(180 - c3), 0), rgb(int(255 - c2), int(180 - c2), 0), rgb(int(255 - c1), int(180 - c1), 0), rgb(255,180,0)];
	}
}

species Road {	aspect base { draw shape color: rgb (125,113,53); } }

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
	init { minimum_cycle_duration <- 0.5; }
	
	parameter "Language choice : " var: my_language	 <- default_language  among: languages_list;
	parameter "Log User Actions" 	var: log_user_action <- true;
	parameter "Connect to ActiveMQ" var: activemq_connect<- true;
	
	output {
		display "Map" background: #black{
			grid Cell;
			species Cell 			aspect: water_or_max_water_elevation;
			species District 		aspect: outline;
			species Road 			aspect: base;
			species Water			aspect: base;
			species Coastal_Defense aspect: base;
			species Land_Use 		aspect: conditional_outline;
			species Button 		aspect: buttons_map;
			species Legend_Map;
			event mouse_down 		action: button_click_map;
		}
		/*display "Dieppe" focus: dieppe toolbar: false parent: "Map" keystone:[{0,0.5},{0.5,0.5},{0,1},{0.5,1}] {
			grid Cell;
			species Cell 			aspect: water_or_max_water_elevation;
			species District 		aspect: outline;
			species Road 			aspect: base;
			species Coastal_Defense aspect: base;
		}
		display "Criel" focus: criel toolbar: false parent: "Map" keystone:[{0.5,0.5},{1,0.5},{0.5,1},{1,1}] {
			grid Cell;
			species Cell 			aspect: water_or_max_water_elevation;
			species District 		aspect: outline;
			species Road 			aspect: base;
			species Coastal_Defense aspect: base;
		}*/
		
		display "Planning" background: #black{
			graphics "World" { draw shape color: rgb(230,251,255); }
			species District 		aspect: base;
			species Land_Use 		aspect: base;
			species Road 	 		aspect: base;
			species Water			aspect: base;
			species Coastal_Defense aspect: base;
			species Legend_Planning;
		}
		display "Population density" background: #black{
			graphics "World" { draw shape color: rgb(230,251,255); }
			species District aspect: pop_den;
			species Land_Use aspect: population_density;
			species Road 	 aspect: base;
			species Water	 aspect: base;
			species Legend_Population;		
		}
		display "Game control"{	
			species Button  aspect: buttons_master;
			
			graphics "Control Panel"{
				point loc 	<- { world.shape.width/2, world.shape.height/2};
				float msize <- min([world.shape.width/2, world.shape.height/2]);
				draw image_file("../images/ihm/logo.png") at: loc size: {msize, msize};
				draw rectangle(msize,1500) at: loc + {0,msize*0.66} color: #lightgray border: #black;
				draw world.get_message("MSG_THE_ROUND") + " : " + game_round color: #blue font: font('Helvetica Neue', 20, #bold) at: loc + {-550,msize*0.66};
			}
			graphics "Play_pause" transparency: 0.5{
				draw square(button_size) at: game_paused ? pause_b : play_b color: #gray ;
			}
			
			event mouse_down action: button_click_master_control;
		}			
		display "Budgets" {
			chart "Districts' budgets" type: series {
			 	data (District first_with(each.dist_id =1)).district_name value:districts_budgets[0] color:#red;
			 	data (District first_with(each.dist_id =2)).district_name value:districts_budgets[1] color:#blue;
			 	data (District first_with(each.dist_id =3)).district_name value:districts_budgets[2] color:#green;
			 	data (District first_with(each.dist_id =4)).district_name value:districts_budgets[3] color:#black;			
			}
		}
		display "Barplots"{
			chart "U Area" type: histogram background: rgb("white") size: {0.31,0.4} position: {0, 0}{
				data "0.5" value:(districts_in_game collect each.U_0_5c) style:stack color: world.color_of_water_height(0.5);
				data  "1"  value:(districts_in_game collect each.U_1c) 	 style:stack color: world.color_of_water_height(0.9); 
				data ">1"  value:(districts_in_game collect each.U_maxc) style:stack color: world.color_of_water_height(1.9); 
			}
			chart "Us Area" type: histogram background: rgb("white") size: {0.31,0.4} position: {0.33, 0}{
				data "0.5" value:(districts_in_game collect each.Us_0_5c) style:stack color: world.color_of_water_height(0.5);
				data  "1"  value:(districts_in_game collect each.Us_1c)   style:stack color: world.color_of_water_height(0.9); 
				data ">1"  value:(districts_in_game collect each.Us_maxc) style:stack color: world.color_of_water_height(1.9); 
			}
			chart "Ui Area" type: histogram background: rgb("white") size: {0.31,0.4} position: {0.66, 0}{
				data "0.5" value:(districts_in_game collect each.Udense_0_5c) style:stack color: world.color_of_water_height(0.5);
				data  "1"  value:(districts_in_game collect each.Udense_1c)   style:stack color: world.color_of_water_height(0.9); 
				data ">1"  value:(districts_in_game collect each.Udense_maxc) style:stack color: world.color_of_water_height(1.9); 
			}
			chart "AU Area" type: histogram background: rgb("white") size: {0.31,0.4} position: {0, 0.5}{
				data "0.5" value:(districts_in_game collect each.AU_0_5c) style:stack color: world.color_of_water_height(0.5);
				data  "1"  value:(districts_in_game collect each.AU_1c)   style:stack color: world.color_of_water_height(0.9); 
				data ">1"  value:(districts_in_game collect each.AU_maxc) style:stack color: world.color_of_water_height(1.9); 
			}
			chart "A Area" type: histogram background: rgb("white") size: {0.31,0.4} position: {0.33, 0.5}{
				data "0.5" value:(districts_in_game collect each.A_0_5c) style:stack color: world.color_of_water_height(0.5);
				data  "1"  value:(districts_in_game collect each.A_1c)   style:stack color: world.color_of_water_height(0.9); 
				data ">1"  value:(districts_in_game collect each.A_maxc) style:stack color: world.color_of_water_height(1.9); 
			}
			chart "N Area" type: histogram background: rgb("white") size: {0.31,0.4} position: {0.66, 0.5}{
				data "0.5" value:(districts_in_game collect each.N_0_5c) style:stack color: world.color_of_water_height(0.5);
				data  "1"  value:(districts_in_game collect each.N_1c)   style:stack color: world.color_of_water_height(0.9); 
				data ">1"  value:(districts_in_game collect each.N_maxc) style:stack color: world.color_of_water_height(1.9); 
			}
		}
		display "Flooded area per district"{
			chart "All areas" type: series size: {0.48,0.45} position: {0, 0}{
				datalist value: length(District)= 0 ? [0,0,0,0]:[((District first_with(each.dist_id = 1)).data_flooded_area),
																 ((District first_with(each.dist_id = 2)).data_flooded_area),
																 ((District first_with(each.dist_id = 3)).data_flooded_area),
																 ((District first_with(each.dist_id = 4)).data_flooded_area)]
						color:[#red,#blue,#green,#black] legend: (((District where (each.dist_id > 0)) sort_by (each.dist_id)) collect each.district_name); 			
			}
		

			chart "U area" type: series size: {0.24,0.45} position: {0.5, 0}{
				datalist value:length(District) = 0 ? [0,0,0,0]:[((District first_with(each.dist_id = 1)).data_totU),
																 ((District first_with(each.dist_id = 2)).data_totU),
																 ((District first_with(each.dist_id = 3)).data_totU),
																 ((District first_with(each.dist_id = 4)).data_totU)]
						color:[#red,#blue,#green,#black] legend: (((District where (each.dist_id > 0)) sort_by (each.dist_id)) collect each.district_name); 			
			}

			chart "Us area" type: series size: {0.24,0.45} position: {0.75, 0}{
				datalist value:length(District) = 0 ? [0,0,0,0]:[((District first_with(each.dist_id = 1)).data_totUs),
																 ((District first_with(each.dist_id = 2)).data_totUs),
																 ((District first_with(each.dist_id = 3)).data_totUs),
																 ((District first_with(each.dist_id = 4)).data_totUs)]
						color:[#red,#blue,#green,#black] legend: (((District where (each.dist_id > 0)) sort_by (each.dist_id)) collect each.district_name); 			
			}

			chart "Ui area" type: series size: {0.24,0.45} position: {0, 0.5}{
				datalist value:length(District) = 0 ? [0,0,0,0]:[((District first_with(each.dist_id = 1)).data_totUdense),
																 ((District first_with(each.dist_id = 2)).data_totUdense),
																 ((District first_with(each.dist_id = 3)).data_totUdense),
																 ((District first_with(each.dist_id = 4)).data_totUdense)]
						color:[#red,#blue,#green,#black] legend: (((District where (each.dist_id > 0)) sort_by (each.dist_id)) collect each.district_name); 			
			}

			chart "AU area" type: series size: {0.24,0.45} position: {0.25, 0.5}{
				datalist value:length(District) = 0 ? [0,0,0,0]:[((District first_with(each.dist_id = 1)).data_totAU),
																 ((District first_with(each.dist_id = 2)).data_totAU),
																 ((District first_with(each.dist_id = 3)).data_totAU),
																 ((District first_with(each.dist_id = 4)).data_totAU)]
						color:[#red,#blue,#green,#black] legend: (((District where (each.dist_id > 0)) sort_by (each.dist_id)) collect each.district_name); 			
			}
			chart "N area" type: series size: {0.24,0.45} position: {0.50, 0.5}{
				datalist value:length(District) = 0 ? [0,0,0,0]:[((District first_with(each.dist_id = 1)).data_totN),
																 ((District first_with(each.dist_id = 2)).data_totN),
																 ((District first_with(each.dist_id = 3)).data_totN),
																 ((District first_with(each.dist_id = 4)).data_totN)]
						color:[#red,#blue,#green,#black] legend: (((District where (each.dist_id > 0)) sort_by (each.dist_id)) collect each.district_name); 			
			}

			chart "A area" type: series size: {0.24,0.45} position: {0.75, 0.5}{
				datalist value:length(District) = 0 ? [0,0,0,0]:[((District first_with(each.dist_id = 1)).data_totA),
																 ((District first_with(each.dist_id = 2)).data_totA),
																 ((District first_with(each.dist_id = 3)).data_totA),
																 ((District first_with(each.dist_id = 4)).data_totA)]
						color:[#red,#blue,#green,#black] legend: (((District where (each.dist_id > 0)) sort_by (each.dist_id)) collect each.district_name); 			
			}
		}
	}
}
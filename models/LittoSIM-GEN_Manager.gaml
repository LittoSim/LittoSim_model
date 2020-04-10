/**
 *  LittoSIM_GEN
 *  Authors: Ahmed, Benoit, Brice, Cécilia, Elise, Etienne, Fredéric, Marion, Nicolas B, Nicolas M, Xavier 
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
	
	// files sent to LISFLOOD
	string lisflood_start_file	<- study_area_def["LISFLOOD_START"];
	string lisflood_bci_file	<- study_area_def["LISFLOOD_BCI"];
	string lisflood_bdy_file 	->{floodEventType = HIGH_FLOODING   ? study_area_def ["LISFLOOD_BDY_HIGH"]   // scenario1 : HIGH 
								 :(floodEventType = LOW_FLOODING    ? study_area_def ["LISFLOOD_BDY_LOW"]    // scenario2 : LOW
		  						 :(floodEventType = MEDIUM_FLOODING ? study_area_def ["LISFLOOD_BDY_MEDIUM"] // scenario3 : MEDIUM
		  						 :get_message('MSG_FLOODING_TYPE_PROBLEM')))};
	// paths to Lisflood
	string lisfloodPath;		// absolute path to Lisflood ex: "C:/littosim/lisflood"
	string results_lisflood_rep 	<- my_flooding_path + "results"; 			// Lisflood results folder
	string lisflood_par_file 		-> {my_flooding_path + "inputs/" + application_name + "_par" + timestamp + ".par"};   // parameter file
	string lisflood_DEM_file 		-> {my_flooding_path + "inputs/" + application_name + "_dem" + timestamp + ".asc"};   // DEM file 
	string lisflood_rugosity_file 	-> {my_flooding_path + "inputs/" + application_name + "_rug" + timestamp + ".asc"};   // rugosity file
	string lisflood_bat_file 		<- "LittoSIM_GEN_Lisflood.bat";	  // Lisflood executable
	
	// variables for Lisflood calculs 
	map<string,string> list_flooding_events;  // list of submersions of a round
	string floodEventType <- LOW_FLOODING;
	int lisfloodReadingStep <- 9999; 		// to indicate to which step of Lisflood results, the current cycle corresponds 
	int last_played_event <- -1;
	string timestamp 		<- ""; 			// used to specify a unique name to the folder of flooding results
	string flood_results 	<- "";   		// text of flood results per district // saved as a txt file
	list<int> submersions;
	int sub_event <- 0;
	
	// parameters for saving submersion results
	string output_data_rep 	  <- "../includes/"+ application_name +"/manager_data-" + EXPERIMENT_START_TIME; 	// folder to save main model results
	string shapes_export_path <- output_data_rep + "/shapes/"; // shapefiles to save
	string csvs_export_path <- output_data_rep + "/csvs/"; // shapefiles to save
	
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
	list<list<int>> districts_transferred_money <- [[0],[0],[0],[0]];
	list<list<int>> districts_actions_costs <- [[0],[0],[0],[0]];
	list<list<int>> districts_levers_costs 	<- [[0],[0],[0],[0]];
	// Strategy profiles actions
	list<list<int>> districts_build_strategies 	<- [[0],[0],[0],[0]];
	list<list<int>> districts_soft_strategies 	<- [[0],[0],[0],[0]];
	list<list<int>> districts_withdraw_strategies<- [[0],[0],[0],[0]];
	list<list<int>> districts_other_strategies <- [[0],[0],[0],[0]];

	list<list<float>> districts_build_costs 	<- [[0],[0],[0],[0]];
	list<list<float>> districts_soft_costs 	<- [[0],[0],[0],[0]];
	list<list<float>> districts_withdraw_costs<- [[0],[0],[0],[0]];
	list<list<float>> districts_other_costs <- [[0],[0],[0],[0]];

	int population_still_to_dispatch <- 0;	// population dynamics
	// other variables 
	bool show_max_water_height	<- false;			// defines if the water_height displayed on the map should be the max one or the current one
	bool show_protected_areas	<- false;
	int show_river_flooded_area <- 0;
	bool show_risked_areas	<- false;
	bool show_grid <- false;
	string stateSimPhase 		<- SIM_NOT_STARTED; // state variable of current simulation state 
	int game_round 				<- 0;
	bool game_paused			<- false;
	point play_b;
	point pause_b;
	list<District> districts_in_game;
	bool save_data <- false; // whether save or not data logs
	bool display_ruptures <- false; // display or not ruptures
	int event_ruptures <- 0;
	bool submersion_ok <- false;
	bool send_flood_results <- true;
	point button_size;

	font bold20 <- font('Helvetica Neue', 20, #bold);
	font bold40 <- font('Helvetica Neue', 40, #bold);
	
	init{
		MSG_SUBMERSION 	<- get_message('MSG_SUBMERSION');
		MSG_ROUND 		<- get_message('MSG_ROUND');
		MSG_BUILDER		<- get_message('MSG_BUILDER');
		MSG_SOFT_DEF	<- get_message('MSG_SOFT_DEF');
		MSG_WITHDRAWAL	<- get_message('MSG_WITHDRAWAL');
		MSG_OTHER		<- get_message("MSG_OTHER");
		MSG_NEW_ROUND	<- get_message('MSG_NEW_ROUND');
		MSG_GAME_DONE	<- get_message('MSG_GAME_DONE');
		MSG_LENGTH		<- get_message('PLY_MSG_LENGTH');
		MSG_MEAN_ALT	<- get_message('MSG_MEAN_ALT');
		MSG_GOOD		<- get_message('PLY_MSG_GOOD');
		MSG_MEDIUM		<- get_message('PLY_MSG_MEDIUM');
		MSG_BAD			<- get_message('PLY_MSG_BAD');
		MSG_DENSE		<- get_message('MSG_DENSE');
		MSG_AREA		<- get_message('MSG_AREA');
		MSG_TAXES		<- get_message("MSG_TAXES");
		LDR_GIVEN		<- get_message("LDR_GIVEN");
		LDR_TAKEN		<- get_message("LDR_TAKEN");
		LDR_TRANSFERRED	<- get_message("LDR_TRANSFERRED");
		LEV_MSG_ACTIONS	<- get_message("LEV_MSG_ACTIONS");
		MSG_LEVERS		<- get_message("MSG_LEVERS");
		LDR_TOTAL		<- get_message('LDR_TOTAL');
		MSG_COMMUNE		<- get_message('MSG_COMMUNE');
		MSG_POPULATION	<- get_message('MSG_POPULATION');
		MSG_WATER_HEIGHTS<- get_message('MSG_WATER_HEIGHTS');
		MSG_CYCLE 		<- get_message("MSG_CYCLE");
		MSG_ALL_AREAS 	<- get_message("MSG_ALL_AREAS");
		LDR_LASTE 		<- get_message("LDR_LASTE");
		LEV_DUNES		<- get_message('LEV_DUNES');
		LEV_DIKES		<- get_message('LEV_DIKES');
		
		lisfloodPath <- IS_OSX ? littosim_def["LISFLOOD_PATH_OSX"] : littosim_def["LISFLOOD_PATH_WIN"];
		
		// Create GIS agents
		create District from: districts_shape with: [district_code::string(read("dist_code"))];
		int idx <- 1;
		loop kk over: dist_code_sname_correspondance_table.keys {
			add first(District where (each.district_code = kk)) to: districts_in_game;
			last(districts_in_game).dist_id <- idx;
			idx <- idx + 1;
		}
				
		create Coastal_Defense from: coastal_defenses_shape with: [
			coast_def_id::int(read("ID")),type::string(read("type")), status::string(read("status")),
			alt::float(get("alt")), height::float(get("height")), district_code::string(read("dist_code"))] {
				if type = WATER_GATE {
					create Water_Gate {
						id <- myself.coast_def_id;
						shape <- myself.shape;
						alt <- myself.alt;
						cells <- Cell where (each overlaps self);
					}
					do die;
				}							
		}
		
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
		create Coastal_Border_Area from: coastline_shape {
			line_shape <- shape;
			shape <-  shape + coastBorderBuffer#m;
		}
		all_coastal_border_area <- union(Coastal_Border_Area);
		
		create Land_Use from: land_use_shape with: [id::int(read("ID")), lu_code::int(read("unit_code")), dist_code::string(read("dist_code")), population::round(float(get("unit_pop")))]{
			lu_name <- lu_type_names[lu_code];
			if lu_code in [LU_TYPE_AU,LU_TYPE_AUs] { // if true, convert all AU and AUs to N (AU should not be imposed to players !)
				if AU_AND_AUs_TO_N {
					lu_name <- "N";
					lu_code <- LU_TYPE_N;
				} else {
					if lu_code = LU_TYPE_AU {
						AU_to_U_counter <- flip(0.5) ? 1 : 0;
						not_updated <- true;
					}
				}
			}
			my_color <- cell_color();
		}
		
		// fix populations issues
		ask Land_Use where (each.lu_code in [LU_TYPE_N,LU_TYPE_A] and each.population > 0) { // move populations of Natural and Agricultural cells
			loop i from: 1 to: population {
				ask one_of(Land_Use where (each.dist_code = self.dist_code and each.lu_name = "U")){
					population <- population + 1;
				}
			}
			population <- 0;
		}
		ask Land_Use where (each.lu_code = LU_TYPE_U and each.population < MIN_POP_AREA) { // each U should have a min pop
			population <- MIN_POP_AREA;
		}
		if river_flood_shape != nil {
			create River_Flood_Cell from: river_flood_shape with: [water_h::float(read("water_h"))] {
				col <- colors_of_water_height[world.class_of_water_height(water_h)];
			}
		}
		if river_flood_shape_1m != nil {
			create River_Flood_Cell_1m from: river_flood_shape_1m with: [water_h::float(read("water_h"))] {
				col <- colors_of_water_height[world.class_of_water_height(water_h)];
			}
		}
		//*****
		do load_dem_and_rugosity;
		ask Coastal_Defense {
			do init_coastal_def;
		}
		ask Land_Use {
			cells <- Cell overlapping self;
			mean_alt <- cells mean_of(each.soil_height);
		}
		if river_flood_shape != nil {
			ask Land_Use {
				ask River_Flood_Cell inside self {
					lu_type <- myself.lu_code;
					if lu_type = LU_TYPE_U and myself.density_class = POP_DENSE {
						lu_type <- LU_TYPE_Ui;
					} else if lu_type = LU_TYPE_AUs {
						lu_type <- LU_TYPE_Us;
					}
				}
			
				ask River_Flood_Cell_1m inside self {
					lu_type <- myself.lu_code;
					if lu_type = LU_TYPE_U and myself.density_class = POP_DENSE {
						lu_type <- LU_TYPE_Ui;
					} else if lu_type = LU_TYPE_AUs {
						lu_type <- LU_TYPE_Us;
					}
				}
			}
		}
		
		ask districts_in_game{
			district_name <- world.dist_code_sname_correspondance_table at district_code;
			district_long_name <- world.dist_code_lname_correspondance_table at district_code;
			LUs 	<- Land_Use where (each.dist_code = self.district_code);
			cells 	<- LUs accumulate (each.cells);
			tax_unit  <- float(tax_unit_table at district_name);
			budget 	<- int(self.current_population() * tax_unit * (1 + initial_budget));
			write MSG_COMMUNE + " " + district_name + " (" + district_code + ") " + MSG_POPULATION + ": " + current_population() + " " + world.get_message('MSG_INITIAL_BUDGET') + ": " + budget;
			do calculate_indicators_t0;
			
			if river_flood_shape != nil {
				do calculate_river_flood_results;
			}
		}
		
		do init_buttons;
		stateSimPhase <- SIM_NOT_STARTED;
		do read_lisflood_files (true);
		do add_element_in_list_flooding_events (INITIAL_SUBMERSION, results_lisflood_rep);
		last_played_event <- 0;

		create Legend_Planning;
		create Legend_Map;
		create Legend_Flood_Map;
		create Legend_Flood_Plan;
		create Network_Game_Manager;
		create Network_Listener_To_Leader;
		create Network_Control_Manager;
	}
	//------------------------------ End of init -------------------------------//
	
	int getMessageID{
 		messageID <- messageID +1;
 		return messageID;
 	} 
	
	int population_to_dispatch {
		return round(sum(districts_in_game accumulate (each.current_population())) * ANNUAL_POP_GROWTH_RATE) +
					(length(Land_Use where(each.is_in_densification)) * ANNUAL_POP_IMMIGRATION_IF_DENSIFICATION);
	}

	action new_round {
		write MSG_NEW_ROUND + " : " + (game_round + 1);
		do clear_map;
		if game_round = 0 { // round 0
			ask districts_in_game{
				add budget to: districts_taxes[dist_id-1];
				
				add 0 to: surface_N_diff;
				add 0 to: surface_U_diff;
				add 0 to: surface_Udense_diff;
				add 0 to: surface_A_diff;
				add 0 to: surface_Us_diff;
				add 0 to: surface_Usdense_diff;
				
				if save_data {
					save ["dist_id","district_code","district_name","round","budget","received_tax","population","N_area","U_area","Udense_area","AU_area","A_area","Us_area",
						"Usdense_area","AUs_area","length_dikes_all","length_dikes_good","length_dikes_medium","length_dikes_bad","mean_alt_dikes_all","mean_alt_dikes_good",
						"mean_alt_dikes_medium","mean_alt_dikes_bad","min_alt_dikes_all","min_alt_dikes_good","min_alt_dikes_medium","min_alt_dikes_bad","length_dunes_all",
						"length_dunes_good","length_dunes_medium","length_dunes_bad","mean_alt_dunes_all","mean_alt_dunes_good","mean_alt_dunes_medium","mean_alt_dunes_bad",
						"min_alt_dunes_all","min_alt_dunes_good","min_alt_dunes_medium","min_alt_dunes_bad","actions_cost","given_money","taken_money","transferred_money",
						"levers_cost"] to: csvs_export_path + district_name + ".csv" type:"csv" rewrite: false;		
				}
			}
			stateSimPhase <- SIM_GAME;
			write stateSimPhase;
		}
		else {
			population_still_to_dispatch <- population_to_dispatch();
			ask shuffle(Land_Use){ pop_updated <- false; do evolve_AU_to_U; }
			ask shuffle(Land_Use){ do evolve_pop_U_densification; 			}
			ask shuffle(Land_Use){ do evolve_pop_U_standard; 				}
			ask Coastal_Defense where (each.rupture){
				do remove_rupture;
			}
			ask districts_in_game{
				// each districts evolves its own coastal defenses
				ask Coastal_Defense where (each.district_code = district_code and each.type = COAST_DEF_TYPE_DIKE) {  do degrade_dike_status; }
		   		ask Coastal_Defense where (each.district_code = district_code and each.type = COAST_DEF_TYPE_DUNE) {  do evolve_dune_status;  }
		   		ask Coastal_Defense where (each.district_code = district_code and each.type = COAST_DEF_TYPE_CORD) {  do degrade_cord_status; }				
				
				do calculate_taxes;
				do inform_leader_stats;
				
				add received_tax to: districts_taxes[dist_id-1];
				add round_actions_cost to: districts_actions_costs[dist_id-1];
				add round_given_money to: districts_given_money[dist_id-1];
				add round_taken_money to: districts_taken_money[dist_id-1];
				add round_transferred_money to: districts_transferred_money[dist_id-1];
				add round_levers_cost to: districts_levers_costs[dist_id-1];
				
				round_actions_cost <- 0;
				round_taken_money  <- 0;
				round_transferred_money <- 0;
				round_given_money  <- 0;
				round_levers_cost  <- 0;
				
				add round_build_actions to: districts_build_strategies[dist_id-1];
				add round_soft_actions to: districts_soft_strategies[dist_id-1];
				add round_withdraw_actions to: districts_withdraw_strategies[dist_id-1];
				add round_other_actions to: districts_other_strategies[dist_id-1];
				round_build_actions <- 0;
				round_soft_actions <- 0;
				round_withdraw_actions <- 0;
				round_other_actions <- 0;
				
				add round_build_cost to: districts_build_costs[dist_id-1];
				add round_soft_cost to: districts_soft_costs[dist_id-1];
				add round_withdraw_cost to: districts_withdraw_costs[dist_id-1];
				add round_other_cost to: districts_other_costs[dist_id-1];
				round_build_cost <- 0.0;
				round_soft_cost <- 0.0;
				round_withdraw_cost <- 0.0;
				round_other_cost <- 0.0;
			}
		}
		do calculate_lu_coast_def_data;
		if save_data {
			do save_round_data;	
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
		write MSG_GAME_DONE + " !";
	}
	
	action clear_map {
		ask Button where (each.nb_button in [7,8]) {
			self.is_selected <- false;
		}
		show_max_water_height <- false;
		display_ruptures <- false;
		ask Cell where (each.cell_type = 1){ // reset water heights
			water_height <- 0.0; 
		}
	}
	
	action calculate_lu_coast_def_data{
		ask districts_in_game{
			add current_population() to: round_population;
			/****************** LUs */
			add sum(LUs where(each.lu_code = 1) accumulate each.shape.area) /10000 to: surface_N;
			add sum(LUs where(each.lu_code = 2) accumulate each.shape.area) /10000 to: surface_U;
			add sum(LUs where(each.lu_code = 2 and each.density_class = POP_DENSE) accumulate each.shape.area)/10000 to: surface_Udense;
			add sum(LUs where(each.lu_code = 4) accumulate each.shape.area)/10000 to: surface_AU;
			add sum(LUs where(each.lu_code = 5) accumulate each.shape.area)/10000 to: surface_A;
			add sum(LUs where(each.lu_code = 6) accumulate each.shape.area)/10000 to: surface_Us;
			add sum(LUs where(each.lu_code = 6 and each.density_class = POP_DENSE) accumulate each.shape.area)/10000 to: surface_Usdense;
			add sum(LUs where(each.lu_code = 7) accumulate each.shape.area)/10000 to: surface_AUs;
			
			if game_round != 0 {
				add surface_N[game_round] - surface_N[game_round-1] + surface_N_diff[game_round-1] to: surface_N_diff;
				add surface_U[game_round] - surface_U[game_round-1] + surface_U_diff[game_round-1] to: surface_U_diff;
				add surface_Udense[game_round] - surface_Udense[game_round-1] + surface_Udense_diff[game_round-1] to: surface_Udense_diff;
				add surface_A[game_round] - surface_A[game_round-1] + surface_A_diff[game_round-1] to: surface_A_diff;
				add surface_Us[game_round] - surface_Us[game_round-1] + surface_Us_diff[game_round-1] to: surface_Us_diff;
				add surface_Usdense[game_round] - surface_Usdense[game_round-1] + surface_Usdense_diff[game_round-1] to: surface_Usdense_diff;
			}
			/**************** coastal defenses */
			list<Coastal_Defense> my_dikes <- Coastal_Defense where (each.district_code=district_code and each.type=COAST_DEF_TYPE_DIKE);
			add length(my_dikes) > 0 ? my_dikes sum_of (each.shape.perimeter) : 0 to: length_dikes_all;
			add length(my_dikes) > 0 ? my_dikes where (each.status=STATUS_GOOD) sum_of (each.shape.perimeter) : 0 to: length_dikes_good;
			add length(my_dikes) > 0 ? my_dikes where (each.status=STATUS_MEDIUM) sum_of (each.shape.perimeter) : 0 to: length_dikes_medium;
			add length(my_dikes) > 0 ? my_dikes where (each.status=STATUS_BAD) sum_of (each.shape.perimeter) : 0 to: length_dikes_bad;
			add length(my_dikes) > 0 ? my_dikes mean_of(each.alt) : 0 to: mean_alt_dikes_all;
			add length(my_dikes) > 0 ? my_dikes where (each.status=STATUS_GOOD) mean_of(each.alt) : 0 to: mean_alt_dikes_good;
			add length(my_dikes) > 0 ? my_dikes where (each.status=STATUS_MEDIUM) mean_of(each.alt) : 0 to: mean_alt_dikes_medium;
			add length(my_dikes) > 0 ? my_dikes where (each.status=STATUS_BAD) mean_of(each.alt) : 0 to: mean_alt_dikes_bad;
			add length(my_dikes) > 0 ? my_dikes min_of(each.alt) : 0 to: min_alt_dikes_all;
			add length(my_dikes) > 0 ? my_dikes where (each.status=STATUS_GOOD) min_of(each.alt) : 0 to: min_alt_dikes_good;
			add length(my_dikes) > 0 ? my_dikes where (each.status=STATUS_MEDIUM) min_of(each.alt) : 0 to: min_alt_dikes_medium;
			add length(my_dikes) > 0 ? my_dikes where (each.status=STATUS_BAD) min_of(each.alt) : 0 to: min_alt_dikes_bad;
			
			list<Coastal_Defense> my_dunes <- Coastal_Defense where (each.district_code=district_code and each.type=COAST_DEF_TYPE_DUNE);
			add length(my_dunes) > 0 ? my_dunes sum_of (each.shape.perimeter) : 0 to: length_dunes_all;
			add length(my_dunes) > 0 ? my_dunes where (each.status=STATUS_GOOD) sum_of (each.shape.perimeter) : 0 to: length_dunes_good;
			add length(my_dunes) > 0 ? my_dunes where (each.status=STATUS_MEDIUM) sum_of (each.shape.perimeter) : 0 to: length_dunes_medium;
			add length(my_dunes) > 0 ? my_dunes where (each.status=STATUS_BAD) sum_of (each.shape.perimeter) : 0 to: length_dunes_bad;
			add length(my_dunes) > 0 ? my_dunes mean_of(each.alt) : 0 to: mean_alt_dunes_all;
			add length(my_dunes) > 0 ? my_dunes where (each.status=STATUS_GOOD) mean_of(each.alt) : 0 to: mean_alt_dunes_good;
			add length(my_dunes) > 0 ? my_dunes where (each.status=STATUS_MEDIUM) mean_of(each.alt) : 0 to: mean_alt_dunes_medium;
			add length(my_dunes) > 0 ? my_dunes where (each.status=STATUS_BAD) mean_of(each.alt) : 0 to: mean_alt_dunes_bad;
			add length(my_dunes) > 0 ? my_dunes min_of(each.alt) : 0 to: min_alt_dunes_all;
			add length(my_dunes) > 0 ? my_dunes where (each.status=STATUS_GOOD) min_of(each.alt) : 0 to: min_alt_dunes_good;
			add length(my_dunes) > 0 ? my_dunes where (each.status=STATUS_MEDIUM) min_of(each.alt) : 0 to: min_alt_dunes_medium;
			add length(my_dunes) > 0 ? my_dunes where (each.status=STATUS_BAD) min_of(each.alt) : 0 to: min_alt_dunes_bad;
			
			add length(my_dikes) > 0 ? (length_dikes_good[game_round] * mean_alt_dikes_good[game_round]) / (
				(length_dikes_good[game_round] * mean_alt_dikes_good[game_round]) +
				(length_dikes_medium[game_round] * mean_alt_dikes_medium[game_round]) +
				(length_dikes_bad[game_round] * mean_alt_dikes_bad[game_round]) ) : 0 to: stat_dikes_good;

			add length(my_dunes) > 0 ? (length_dunes_good[game_round] * mean_alt_dunes_good[game_round]) / (
				(length_dunes_good[game_round] * mean_alt_dunes_good[game_round]) +
				(length_dunes_medium[game_round] * mean_alt_dunes_medium[game_round]) +
				(length_dunes_bad[game_round] * mean_alt_dunes_bad[game_round]) ) : 0 to: stat_dunes_good;
		}
	}
	
	int district_id (string dist_code){
		District d <- first(District first_with (each.district_code = dist_code));
		return d != nil ? d.dist_id : 0;
	}

	reflex show_flood_stats when: stateSimPhase != nil and stateSimPhase = SIM_SHOWING_FLOOD_STATS {			// end of flooding
		write flood_results;
		if save_data {
			save flood_results to: output_data_rep + "/flood_results/flooding-" + machine_time + "-R" + game_round + ".txt" type: "text";
		}
		if send_flood_results {
			do send_flooding_results (nil); // to districts
			send_flood_results <- false;
		}
		stateSimPhase <- SIM_GAME;
		write stateSimPhase + " - " + MSG_ROUND + " " + game_round;
	}
	
	reflex calculate_flood_stats when: stateSimPhase != nil and stateSimPhase = SIM_CALCULATING_FLOOD_STATS{			// end of a flooding event
		do calculate_districts_results; 													// calculating results
		stateSimPhase <- SIM_SHOWING_FLOOD_STATS;
		write stateSimPhase;
	}
	
	reflex show_lisflood when: stateSimPhase != nil and stateSimPhase = SIM_SHOWING_LISFLOOD {
		if !submersion_ok or length(one_of(Cell where (each.cell_type = 1)).water_heights) < 14 {
			write "Error in submersion process!";
			remove key: ""+game_round from: list_flooding_events;
			stateSimPhase <- SIM_GAME;
			write stateSimPhase;
			return;
		}
		ask Cell where (each.cell_type = 1){
			water_height <- water_heights[lisfloodReadingStep];
		}
		write "Step " + lisfloodReadingStep;
		if lisfloodReadingStep < 14 {
			lisfloodReadingStep <- lisfloodReadingStep + 1;
		}
		else{
     		stateSimPhase <- SIM_CALCULATING_FLOOD_STATS;
     		write stateSimPhase;
     		display_ruptures <- true;
     		first(Button where (each.nb_button = 8)).is_selected <- true;
     	}
	} 
	
	action replay_flood_event (int fe) {
		if fe >= length(list_flooding_events) {
			write "Trying to replay a non existing event!";
			return;
		}
		do clear_map;
		if last_played_event != fe {
			last_played_event <- fe;
			results_lisflood_rep <- list_flooding_events at list_flooding_events.keys[fe];
			ask Cell {
				max_water_height <- 0.0; // reset of max_water_height
			} 
			do read_lisflood_files (true);
			send_flood_results <- true;
		}
		lisfloodReadingStep <- 0;
		stateSimPhase <- SIM_SHOWING_LISFLOOD;
		write stateSimPhase;
	}
		
	action launchFlood_event{
		if game_round = 0 {
			map values <- user_input(get_message('MSG_WARNING'), get_message('MSG_SIM_NOT_STARTED')::true);
	     	write stateSimPhase;
		}
		else{	// excuting Lisflood
			do new_round;
			ask Cell where (each.cell_type = 1) {
				max_water_height <- 0.0; // reset of max_water_height
			}
			ask Coastal_Defense {
				do calculate_rupture;
			}
			//********* for Criel case only *//////////////*******
			ask Coastal_Defense where (each.type = COAST_DEF_TYPE_CORD) {
				if status = STATUS_BAD {
					list<Coastal_Defense> cordies <- Coastal_Defense where (each.is_protected_by_cord and !each.rupture);
					if length(cordies) = 3 {
						ask one_of(cordies) {
							rupture <- true;
						}
					}
				}
			}
			/************* */
			stateSimPhase <- SIM_EXEC_LISFLOOD;
			write stateSimPhase;
			do execute_lisflood;
			do read_lisflood_files (false);
			lisfloodReadingStep <- 0;
			last_played_event <- length(list_flooding_events.keys) - 1;
			event_ruptures <- last_played_event;
			send_flood_results <- true;
			map<string,unknown> vmap <- user_input("OK", world.get_message('MSG_SIM_FINISHED')::true);
			sub_event <- 1;
			stateSimPhase <- SIM_SHOWING_LISFLOOD;
			write stateSimPhase;
			ask districts_in_game{
				ask Network_Game_Manager { do lock_user (myself, false); }
			}
			game_paused <- false;
		}
	}

	action add_element_in_list_flooding_events (string sub_name, string sub_rep){
		put sub_rep key: sub_name in: list_flooding_events;
		// updating the button that displays this submersion
		ask Button where (each.nb_button = 6 and int(each.command) = length(list_flooding_events)-1){
			my_icon <- image_file("../images/icons/" + flooding_icons at floodEventType);
			display_text <- world.get_message('MSG_REPLY_SUBMERSION') + " (" + sub_name + ")";
		}

		ask Network_Control_Manager{
			do update_submersion_list;
		}
	}
		
	action execute_lisflood{
		ask districts_in_game{
			ask Network_Game_Manager { do lock_user (myself, true); }
		}
		game_paused <- true;
		timestamp <- "_R" + game_round + "_t" + machine_time;
		results_lisflood_rep <- "includes/" + application_name + "/floodfiles/results" + timestamp;
		do save_dem_and_rugosity;
		do save_lf_launch_files;
		do add_element_in_list_flooding_events("" + game_round , results_lisflood_rep);
		save floodEventType to: "../"+results_lisflood_rep + "/submersion_type.txt" type: "text";// need to create the lisflood results directory because lisflood cannot create it by itself
		ask Network_Game_Manager {
			if IS_OSX {
				do execute command: "sh " + lisfloodPath + lisflood_bat_file;
			}
			else{
				do execute command: "cmd /c start " + lisfloodPath + lisflood_bat_file;
			}
		}
 	}
 		
	action save_lf_launch_files {
		save ("DEMfile         ../workspace/LittoSIM-GEN/" + lisflood_DEM_file + 
				"\nresroot         res\ndirroot         results\nsim_time        " + LISFLOOD_SIM_TIME + "\ninitial_tstep   " + LISFLOOD_INIT_TSTEP + 
				"\nmassint         " + LISFLOOD_MASSINT + "\nsaveint         " + LISFLOOD_SAVEINT + "\nmanningfile     ../workspace/LittoSIM-GEN/"
				+ lisflood_rugosity_file + "\nbcifile         ../workspace/LittoSIM-GEN/" + my_flooding_path + lisflood_bci_file + 
				"\nbdyfile         ../workspace/LittoSIM-GEN/" + my_flooding_path + lisflood_bdy_file + "\nstartfile       ../workspace/LittoSIM-GEN/"
				+ my_flooding_path + lisflood_start_file + "\nstartelev\nelevoff\nacceleration\nSGC_enable\n") rewrite: true to: "../"+lisflood_par_file type: "text";

		if IS_OSX {
			save ("cd " + lisfloodPath + ";\n./lisflood -dir " + "../workspace/LittoSIM-GEN/"+ results_lisflood_rep + " ../workspace/LittoSIM-GEN/"+ lisflood_par_file + ";\nexit") rewrite: true to: lisfloodPath+lisflood_bat_file type: "text";
		}
		else {
			save ("cd " + lisfloodPath + "\nlisflood.exe -dir " + "../workspace/LittoSIM-GEN/"+ results_lisflood_rep + " ../workspace/LittoSIM-GEN/"+ lisflood_par_file + "\nexit") rewrite: true to: lisfloodPath+lisflood_bat_file type: "text";
		}		
	}
	
	action load_dem_and_rugosity {
		list<string> dem_data <- [];
		list<string> rug_data <- [];
		file dem_grid <- text_file(dem_file);
		file rug_grid <- text_file(RUGOSITY_DEFAULT);
		
		GRID_XLLCORNER <- float((dem_grid[2] split_with " ")[1]);
		GRID_YLLCORNER <- float((dem_grid[3] split_with " ")[1]);
		GRID_CELL_SIZE <- int((dem_grid[4] split_with " ")[1]);
		float no_data_value <- float((dem_grid [5] split_with " ")[1]);
		
		loop rw from: 0 to: GRID_NB_ROWS - 1 {
			dem_data <- dem_grid [rw+6] split_with " ";
			rug_data <- rug_grid [rw+6] split_with " ";
			loop cl from: 0 to: GRID_NB_COLS - 1 {
				Cell[cl, rw].soil_height <- float(dem_data[cl]);
				Cell[cl, rw].rugosity <- float(rug_data[cl]);
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
		land_color_interval <- land_max_height / LEGEND_SIZE;
		cells_max_depth <- abs(min(Cell where (each.cell_type = 0 and each.soil_height != no_data_value) collect each.soil_height));
		ask Cell {
			do init_cell_color;
		}
	}    

	action save_dem_and_rugosity {
		string dem_filename <- "../"+lisflood_DEM_file;
		string rug_filename <- "../"+lisflood_rugosity_file;
		string h_txt <- 'ncols         ' + GRID_NB_COLS + '\nnrows         ' + GRID_NB_ROWS + '\nxllcorner     ' + GRID_XLLCORNER
							+ '\nyllcorner     ' + GRID_YLLCORNER + '\ncellsize      ' + GRID_CELL_SIZE + '\nNODATA_value  -9999';
		
		save h_txt rewrite: true to: dem_filename type: "text";
		save h_txt rewrite: true to: rug_filename type: "text";
		string dem_data;
		string rug_data;
		loop rw from: 0 to: GRID_NB_ROWS - 1 {
			dem_data <- "";
			rug_data <- "";
			loop cl from: 0 to: GRID_NB_COLS - 1 {
				dem_data <- dem_data + " " + Cell[cl, rw].soil_height;
				rug_data <- rug_data + " " + Cell[cl, rw].rugosity;
			}
			save dem_data to: dem_filename rewrite: false;
			save rug_data to: rug_filename rewrite: false;
		}
	}
	
	action save_round_data {
		int num_round <- game_round;
		save Land_Use type:"shp" to: shapes_export_path+"Land_Use_" + num_round + ".shp"
				attributes: ['id'::id, 'lu_code'::lu_code, 'dist_code'::dist_code, 'density_class'::density_class, 'population'::population];
		save Coastal_Defense type: "shp" to: shapes_export_path+"Coastal_Defense_" + num_round + ".shp"
				attributes: ['id'::coast_def_id, 'dist_code'::district_code, 'type'::type, 'status'::status, 'height'::height, 'alt'::alt];

		ask districts_in_game {
			int popul <- round_population[num_round];
			float N_area <- surface_N[num_round];
			float U_area <- surface_U[num_round];
			float Udense_area <- surface_Udense[num_round];
			float AU_area <- surface_AU[num_round];
			float A_area <- surface_A[num_round];
			float Us_area <- surface_Us[num_round];
			float Usdense_area <- surface_Usdense[num_round];
			float AUs_area <- surface_AUs[num_round];
			
			float min_alt_all_dikes <- min_alt_dikes_all[num_round];
			float mean_alt_all_dikes <- mean_alt_dikes_all[num_round];
			float min_alt_all_dunes <- 0.0;
			float mean_alt_all_dunes <- 0.0;
			if length(min_alt_dunes_all) > 0 {
				float min_alt_all_dunes <- min_alt_dunes_all[num_round];
				float mean_alt_all_dunes <- mean_alt_dunes_all[num_round];
			}
			
			int actions_cost <- districts_actions_costs[dist_id-1][num_round];
			int given_money <- districts_given_money[dist_id-1][num_round];
			int taken_money <- districts_taken_money[dist_id-1][num_round];
			int transferred_money <- districts_transferred_money[dist_id-1][num_round];
			int levers_costs <- districts_levers_costs[dist_id-1][num_round];
			
			save [dist_id,district_code,district_name,num_round,budget,received_tax,popul,N_area,U_area,Udense_area,AU_area,A_area,Us_area,Usdense_area,AUs_area,
				last(length_dikes_all),last(length_dikes_good),last(length_dikes_medium),last(length_dikes_bad),last(mean_alt_all_dikes),last(mean_alt_dikes_good),
				last(mean_alt_dikes_medium),last(mean_alt_dikes_bad),last(min_alt_all_dikes),last(min_alt_dikes_good),last(min_alt_dikes_medium),last(min_alt_dikes_bad),
				last(length_dunes_all),last(length_dunes_good), last(length_dunes_medium),last(length_dunes_bad),last(mean_alt_all_dunes),last(mean_alt_dunes_good),
				last(mean_alt_dunes_medium),last(mean_alt_dunes_bad), last(min_alt_all_dunes),last(min_alt_dunes_good),last(min_alt_dunes_medium),last(min_alt_dunes_bad),
				actions_cost,given_money,taken_money,transferred_money,levers_costs]
						to: csvs_export_path + district_name + ".csv" type:"csv" rewrite: false;
		}
	}
	   
	action read_lisflood_files (bool read_also_ruptures){
		write "reading flood files ...";
		ask Cell where (each.cell_type = 1){ // reset water heights
			water_heights <- [];
		}
		string fileName <- "../" + results_lisflood_rep + "/submersion_type.txt";
		if file_exists (fileName){
			loop line over: text_file(fileName){
				if line contains 'FLOODING' {
					floodEventType <- line;
				}
			}
		}
		
		list<string> data <- [];
		string nb <- "";
		loop i from: 0 to: 14 {
			nb <- "0000" + i;
			nb <- copy_between (nb, length(nb)-4, length(nb));
			fileName <- "../" + results_lisflood_rep + "/res-" + nb + ".wd";
			if file_exists (fileName){
				file lfdata <- text_file(fileName);
				loop r from: 0 to: GRID_NB_ROWS - 1 {
					data <- lfdata[r+6] split_with "\t";
					loop c from: 0 to: GRID_NB_COLS - 1 {
						float w <- float(data[c]);
						add w to: Cell[c, r].water_heights;
					}
				}
	     	}
		}
		// all submersion files are read and ok to show
		submersion_ok <- nb = "0014";
		ask Cell where (each.cell_type = 1){
			max_water_height <- max (water_heights);
		}
		ask Polycell { do die; }
		ask districts_in_game{
			ask cells where(each.max_water_height > 0){
				create Polycell{
					loc <- myself.shape.location;
					col <- colors_of_water_height[world.class_of_water_height(myself.max_water_height)];
				}
			}
		}
		if read_also_ruptures {
			// reading ruptures file
			fileName <- "../" + results_lisflood_rep + "/ruptures.txt";
			if file_exists (fileName){
				write "reading ruptures file ...";
				loop line over: text_file(fileName){
					if line contains ',' {
						data <- line split_with(",");
						ask Coastal_Defense where (each.coast_def_id = int(data[0])) {
							if int(data[1]) = 1 {
								rupture <- true;
								flooded <- true;
							} else {
								rupture <- false;
							}
						}
					}	
				}
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
		map<string,string> nmap <- ["TOPIC"::"NEW_SUBMERSION_EVENT","submersion_number"::last_played_event];
		string my_district <- d.district_code;
 		
 		string flooded_cells <- "";
		ask d.LUs {
			add string(flooded_times) at: "ftimes"+self.id to: nmap;
		}
		list<Land_Use> luss <- d.LUs where (each.nb_watered_cells > 0 and !each.marked);
		int i <- 0;
 		int n_cells <- min([5, length(luss)]);
 		ask n_cells among (shuffle(luss)) {
 			if flip(nb_watered_cells/length(cells)) {
	 			add string(self.id) at: "lu_id"+i to: nmap;				
				create Flood_Mark {
					self.sub_num <- last_played_event;
					self.mylu <- myself;
					self.max_w_h <- myself.cells max_of(each.max_water_height);
					self.mean_w_h <- myself.cells mean_of(each.max_water_height) with_precision 1;
					self.max_w_h_per_cent <- ((length(myself.cells where (each.max_water_height >= int(max_w_h*10)/10)) / length(myself.cells)) * 100) with_precision 2;
					add self to: d.flood_marks;
					self.mylu.marked <- true;
					add string(max_w_h with_precision 1) at: "max_w_h"+i to: nmap;
					add string(max_w_h_per_cent) at: "max_w_h_per_cent"+i to: nmap;
					add string(mean_w_h) at: "mean_w_h"+i to: nmap;
				}
				i <- i + 1;
			}
 		}
 		ask Network_Game_Manager{
			do send to: my_district contents: nmap;
		}
		nmap <- ["TOPIC"::"NEW_RUPTURES"];
		ask Coastal_Defense where (each.district_code = my_district) {
			add string(rupture and flooded) at: string(coast_def_id) to: nmap;
		}
		ask Network_Game_Manager{
			do send to: my_district contents: nmap;
		}
	}
	
	action calculate_districts_results {
		string text <- "";
		string subs_csv <- "round;dist;sub_level;uu;us;udense;au;aa;nn\n";
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
				nb_watered_cells <- 0;
				ask cells where (each.max_water_height > 0) {
					switch myself.lu_code{
						match LU_TYPE_U {
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
						match_one [LU_TYPE_Us, LU_TYPE_AUs] {
							if max_water_height <= 0.5 { Us_0_5 <- Us_0_5 +1; }
							else if between (max_water_height ,0.5, 1.0) { Us_1 <- Us_1 +1; }
							else { Us_max <- Us_max +1; }
						}
						match LU_TYPE_AU {
							if max_water_height <= 0.5 { AU_0_5 <- AU_0_5 +1; }
							else if between (max_water_height ,0.5, 1.0) { AU_1 <- AU_1 +1; }
							else { AU_max <- AU_max +1; }
						}
						match LU_TYPE_N  {
							if max_water_height <= 0.5 { N_0_5 <- N_0_5 +1; }
							else if between (max_water_height ,0.5, 1.0) { N_1 <- N_1 +1; }
							else { N_max <- N_max +1; }
						}
						match LU_TYPE_A {
							if max_water_height <= 0.5 { A_0_5 <- A_0_5 +1; }
							else if between (max_water_height ,0.5, 1.0) { A_1 <- A_1 +1; }
							else { A_max <- A_max +1; }
						}
					}
					myself.nb_watered_cells <- myself.nb_watered_cells + 1;
				}
				if nb_watered_cells > 0 {
					flooded_times <- flooded_times + 1;
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
			prev_tot_0_5c <- tot_0_5c;
			prev_tot_1c <- tot_1c;
			prev_tot_maxc <- tot_maxc;
			
			float to_hectar <- GRID_CELL_SIZE * GRID_CELL_SIZE / 10000; // transform m2 to hectar
			U_0_5c 	<- (U_0_5 * to_hectar) 	with_precision 1; 
			U_1c 	<- (U_1 * to_hectar) 	with_precision 1;
			U_maxc 	<- (U_max * to_hectar) 	with_precision 1;
			
			Us_0_5c <- (Us_0_5 * to_hectar) with_precision 1;
			Us_1c 	<- (Us_1 * to_hectar) 	with_precision 1;
			Us_maxc <- (Us_max * to_hectar) with_precision 1;
			
			Udense_0_5c <- (Udense_0_5 * to_hectar) with_precision 1;
			Udense_1c 	<- (Udense_1 * to_hectar) 	with_precision 1;
			Udense_maxc <- (Udense_max * to_hectar) with_precision 1;
			
			AU_0_5c <- (AU_0_5 * to_hectar) with_precision 1;
			AU_1c 	<- (AU_1 * to_hectar) 	with_precision 1;
			AU_maxc <- (AU_max * to_hectar) with_precision 1;
			
			A_0_5c 	<- (A_0_5 * to_hectar) 	with_precision 1;
			A_1c 	<- (A_1 * to_hectar) 	with_precision 1;
			A_maxc 	<- (A_max * to_hectar) 	with_precision 1;
			
			N_0_5c 	<- (N_0_5 * to_hectar) 	with_precision 1;
			N_1c 	<- (N_1 * to_hectar) 	with_precision 1;
			N_maxc 	<- (N_max * to_hectar) 	with_precision 1;
			
			tot_0_5c<- (U_0_5c + Us_0_5c + AU_0_5c + A_0_5c + N_0_5c) 	with_precision 1;
			tot_1c 	<- (U_1c + Us_1c + AU_1c + A_1c + N_1c) 			with_precision 1;
			tot_maxc<- (U_maxc + Us_maxc + AU_maxc + A_maxc + N_maxc) 	with_precision 1;
			
			// csv structure file : game round;district;submersion_level;U;Us;Udense;AU;A;N\n
			subs_csv <- subs_csv + game_round + ";" + district_name + ";1;" + U_0_5c + ";" + Us_0_5c + ";" + Udense_0_5c + ";" + AU_0_5c + ";" + A_0_5c + ";" + N_0_5c + "\n";
			subs_csv <- subs_csv + game_round + ";" + district_name + ";2;" + U_1c + ";" + Us_1c + ";" + Udense_1c + ";" + AU_1c + ";" +  A_1c + ";" + N_1c + "\n";
			subs_csv <- subs_csv + game_round + ";" + district_name + ";3;" + U_maxc + ";" + Us_maxc + ";" + Udense_maxc + ";" + AU_maxc + ";" + A_maxc + ";" + N_maxc + "\n";
			
			
			text <- text + "Results for district : " + district_name +"
Flooded U : < 50cm " + U_0_5c + " ha ("+ ((U_0_5 / tot * 100) with_precision 1) + "%) | between 50cm and 1m " + U_1c + " ha ("+ ((U_1 / tot * 100) with_precision 1) +"%) | > 1m " + U_maxc  + " ha (" + ((U_max / tot * 100) with_precision 1) +"%) 
Flooded Us : < 50cm " + Us_0_5c + " ha ("+ ((Us_0_5 / tot * 100) with_precision 1) + "%) | between 50cm and 1m " + Us_1c  + " ha ("+ ((Us_1 / tot * 100) with_precision 1) +"%) | > 1m " + Us_maxc + " ha (" + ((Us_max / tot * 100) with_precision 1) +"%) 
Flooded Udense : < 50cm " + Udense_0_5c +" ha ("+ ((Udense_0_5 / tot * 100) with_precision 1) + "%) | between 50cm and 1m " + Udense_1c + " ha ("+ ((Udense_1 / tot * 100) with_precision 1) + "%) | > 1m " + Udense_maxc  + " ha ("+ ((Udense_max / tot * 100) with_precision 1) +"%) 
Flooded AU : < 50cm " + AU_0_5c +" ha ("+ ((AU_0_5 / tot * 100) with_precision 1) + "%) | between 50cm and 1m " + AU_1c  + " ha (" + ((AU_1 / tot * 100) with_precision 1) +"%) | > 1m " + AU_maxc+ " ha (" + ((AU_max / tot * 100) with_precision 1) +"%) 
Flooded A : < 50cm " + A_0_5c +" ha ("+ ((A_0_5 / tot * 100) with_precision 1) + "%) | between 50cm and 1m " + A_1c  + " ha (" + ((A_1 / tot * 100) with_precision 1) +"%) | > 1m " + A_maxc + " ha (" + ((A_max / tot * 100) with_precision 1) +"%) 
Flooded N : < 50cm " + N_0_5c +" ha ("+ ((N_0_5 / tot * 100) with_precision 1) + "%) | between 50cm and 1m " + N_1c + " ha (" + ((N_1 / tot * 100) with_precision 1) +"%) | > 1m " + N_maxc + " ha (" + ((N_max / tot * 100) with_precision 1) +"%) 
--------------------------------------------------------------------------------------------------------------------
";	
		}
		flood_results <-  text;
		if save_data {
			save subs_csv to: output_data_rep + "/flood_results/sub-" + game_round + ".csv" type: "text" rewrite: true;	
		}
			
		write get_message('MSG_FLOODED_AREA_DISTRICT') + " :";
		ask districts_in_game {
			flooded_area <- (U_0_5c + U_1c + U_maxc + Us_0_5c + Us_1c + Us_maxc + AU_0_5c + AU_1c + AU_maxc + N_0_5c + N_1c + N_maxc + A_0_5c + A_1c + A_maxc) with_precision 1;  
			write ""+ district_name + " : " + flooded_area +" ha";

			totU <- (U_0_5c + U_1c + U_maxc) with_precision 1;
			totUs <- (Us_0_5c + Us_1c + Us_maxc ) with_precision 1;
			totUdense <- (Udense_0_5c + Udense_1c + Udense_maxc) with_precision 1;
			totAU <- (AU_0_5c + AU_1c + AU_maxc) with_precision 1;
			totN <- (N_0_5c + N_1c + N_maxc) with_precision 1;
			totA <-  (A_0_5c + A_1c + A_maxc) with_precision 1;
			
			if length(data_flooded_area) < length (list_flooding_events) {
				add flooded_area to: data_flooded_area;
				add totU to: data_totU;
				add totUs to: data_totUs;
				add totUdense to: data_totUdense;
				add totAU to: data_totAU;
				add totN to: data_totN;
				add totA to: data_totA;
			}
			if river_flood_shape != nil {
				do calculate_river_flood_results;
			}
		}
		
		string rupt <- "";
		ask Coastal_Defense {
			if length(cells where (each.max_water_height > 0)) > 0 {
				flooded <- true;
			}
			rupt <- rupt + ""+ coast_def_id +","+ int(rupture and flooded) +"\n";
		}
		// saving ruptures file
		if sub_event = 1 {
			save rupt to: "../" +results_lisflood_rep + "/ruptures.txt" type: "text";
		}
	}
	
	// creating buttons
 	action init_buttons{
 		button_size <- {world.shape.width/7.75,world.shape.height/6.5};
		create Button{
			nb_button 	<- 0;
			command  	<- ONE_STEP;
			location 	<- {button_size.x*0.75, button_size.y*0.75};
			my_icon 	<- image_file("../images/icons/one_step.png");
			display_text <- MSG_NEW_ROUND;
		}
		create Button{
			nb_button 	<- 1;
			command  	<- LOCK_USERS;
			location 	<- {button_size.x*0.75, button_size.y*2};
			my_icon 	<- image_file("../images/icons/pause.png");
			display_text <- world.get_message('MSG_PAUSE_GAME');
			pause_b <- self.location;
		}
		create Button{
			nb_button 	<- 2;
			command  	<- UNLOCK_USERS;
			location 	<- {button_size.x*0.75, button_size.y*3.25};
			my_icon 	<- image_file("../images/icons/play.png");
			display_text <- world.get_message('MSG_RESUME_GAME');
			play_b <- self.location;
		}
		create Button{
			nb_button 	<- 5;
			command	 	<- LOW_FLOODING;
			location 	<- {button_size.x*2.55, button_size.y*0.75};
			my_icon 	<- image_file("../images/icons/low_event.png");
			string text_label <- world.get_message('MSG_LOW_FLOODING');
			display_text <- text_label split_with ' ' at 0;
			display_text2 <- text_label split_with ' ' at 1;
		}
		if study_area_def ["LISFLOOD_BDY_MEDIUM_FILENAME"] != nil {
			create Button{
				nb_button 	<- 55;
				command	 	<- MEDIUM_FLOODING;
				location 	<- {button_size.x*3.75, button_size.y*0.75};
				my_icon 	<- image_file("../images/icons/medium_event.png");
				string text_label <- world.get_message('MSG_MEDIUM_FLOODING');
				display_text <- text_label split_with ' ' at 0;
				display_text2 <- text_label split_with ' ' at 1;
			}	
		} else if first(Water_Gate) != nil {
			create Button{
				nb_button 	<- 57;
				command	 	<- "OPEN_DIEPPE_GATES";
				location 	<- {button_size.x*3.75, button_size.y*0.75};
				my_icon 	<- image_file("../images/icons/open_gates.png");
				string text_label <- "Ouvrir les#portes de Dieppe";
				display_text <- text_label split_with '#' at 0;
				display_text2 <- text_label split_with '#' at 1;
			}
		}
		create Button{
			nb_button 	<- 3;
			command	 	<- HIGH_FLOODING;
			location 	<- {button_size.x*5, button_size.y*0.75};
			my_icon 	<- image_file("../images/icons/high_event.png");
			string text_label <- world.get_message('MSG_HIGH_FLOODING');
			display_text <- text_label split_with ' ' at 0;
			display_text2 <- text_label split_with ' ' at 1;
		}
		
		loop i from: 0 to: 4 {
			create Button{
				nb_button 	<- 6;
				command  	<- ""+i;
				location 	<- {button_size.x*6.75, button_size.y*(0.75 + (i*1.25))};
			}
		}
		
		create Button{
			nb_button 	<- 4;
			command  	<- SHOW_LU_GRID;
			shape 		<- square(800);
			my_icon 	<- image_file("../images/icons/avec_quadrillage.png");
			location <- {LEGEND_POSITION_X-1200, LEGEND_POSITION_Y-1000};
		}
		create Button{
			nb_button 	<- 7;
			command	 	<- SHOW_MAX_WATER_HEIGHT;
			my_icon 	<- image_file("../images/icons/max_water_height.png");
			location 	<- {button_size.x*2,  world.shape.height - button_size.y*0.75};
		}
		create Button{
			nb_button 	<- 8;
			command	 	<- SHOW_RUPTURE;
			my_icon 	<- image_file("../images/icons/rupture2.png");
			location 	<-  {button_size.x*3.25,  world.shape.height - button_size.y*0.75};
		}
		create Button{
			nb_button 	<- 911;
			command	 	<- ACTION_DISPLAY_FLOODED_AREA;
			my_icon 	<- image_file("../images/icons/display_ppr.png");
			location 	<- {button_size.x*4.5,  world.shape.height - button_size.y*0.75};
		}
		create Button{
			nb_button 	<- 912;
			command	 	<- ACTION_DISPLAY_PROTECTED_AREA;
			my_icon 	<- image_file("../images/icons/display_protected.png");
			location 	<-  {button_size.x*5.75,  world.shape.height - button_size.y*0.75};
		}
		if river_flood_shape != nil {
			create Button{
				nb_button 	<- 913;
				command	 	<- ACTION_DISPLAY_RIVER_FLOOD;
				my_icon 	<- image_file("../images/icons/river_flood0.jpg");
				location 	<- {button_size.x*0.75, world.shape.height - button_size.y*0.75};
			}
			create Button{
				nb_button 	<- 914;
				command	 	<- ACTION_DISPLAY_RIVER_FLOOD;
				my_icon 	<- image_file("../images/icons/river_flood1.jpg");
				location 	<- {button_size.x*0.75, world.shape.height - button_size.y*2};
			}
		}
	}
	
	// the four buttons of game master control display 
    action button_click_master_control{
		point loc <- #user_location;
		Button button_master <- first(Button where (each.nb_button in [0,1,2,3,5,6,7,8,55,57,911,912,913,914] and each overlaps loc));
		if button_master != nil {
			ask Button where !(each.nb_button in [4,7,8,911,912,913,914]) {
				self.is_selected <- false;
			}
			ask button_master {
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
					match_one [3, 5, 55]{
						is_selected <- true;
						floodEventType <- command;
						ask world   { do launchFlood_event; }
					}
					match 57 {
						is_selected <- true;
						ask Water_Gate {
							display_me <- false;
							do close_open;
						}
						write "Les portes de Dieppe ont été ouvertes!";
						map<string, string> mp <- ["TOPIC"::"OPEN_DIEPPE_GATES"];
						ask Network_Game_Manager {
							do send to: "76217" contents: mp;
						}
					}
					match 6	{
						if int(command) < length(list_flooding_events) {
							is_selected <- true;
							ask world { do replay_flood_event(int(myself.command));}
						}
					}
					match 7 {
						is_selected <- !is_selected;
						show_max_water_height <- is_selected;
					}
					match 8 {
						is_selected <- !is_selected;
						display_ruptures <- is_selected;
					}
					match 911 {
						is_selected <- !is_selected;
						show_risked_areas <- is_selected;
					}
					match 912 {
						is_selected <- !is_selected;
						show_protected_areas <- is_selected;
					}
					match 913 {
						is_selected <- !is_selected;
						show_river_flooded_area <- is_selected ? 1 : 0;
						first(Button where (each.nb_button = 914)).is_selected <- false;	 
					}
					match 914 {
						is_selected <- !is_selected;
						show_river_flooded_area <- is_selected ? 2 : 0;
						first(Button where (each.nb_button = 913)).is_selected <- false;
					}
				}
			}
		}
	}
	
	// the two buttons of the first map display
	action button_click_map {
		point loc <- #user_location;
		Button a_button <- first((Button where (each.nb_button = 4 and each overlaps loc)));
		if a_button != nil{
			ask a_button {
				is_selected <- !is_selected;
				show_grid <- is_selected;
				my_icon	<-  is_selected ? image_file("../images/icons/sans_quadrillage.png") : image_file("../images/icons/avec_quadrillage.png");
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
				match "WATER_GATE" {
					if first(Water_Gate where (each.id = 9999)) != nil {
						ask first(Water_Gate where (each.id = 9999)) {
							display_me <- bool(m_contents["CLOSE"]);
							do close_open;
							if display_me {
								write "La porte de Dieppe a été fermée!";
							} else {
								write "La porte de Dieppe a été ouverte!";
							}
						}	
					}
				}
				match "FLOOD_GATES" {
					if first(Water_Gate where (each.id != 9999)) != nil {
						bool close_gates <- bool(m_contents["CLOSE"]);
						ask Water_Gate where (each.id != 9999) {
							display_me <- close_gates;
							do close_open;
						}
						if close_gates {
							write "Les portes-à-flot du bassin de Dieppe ont été fermées!";
						} else {
							write "Les portes-à-flot du bassin de Dieppe ont été ouvertes!";
						}
					}
				}
				match "MY_BUTTONS" { // a client declares its buttons
					ask District where(each.dist_id = id_dist) {
						list<int> lisa <- eval_gaml(string(m_contents["buts"]));
						loop bt over: lisa {
							put B_ACTIVATED in: buttons_states key: bt;
						}
					}
				}
				match string(CONNECTION_MESSAGE) { // a client district wants to connect
					ask District where(each.dist_id = id_dist) {
						do inform_current_round;
						write world.get_message('MSG_CONNECTION_FROM') + " " + m_sender + " " + district_name + " (" + id_dist + ")";
					}
				}
				match NEW_COAST_DEF_ALT {
					geometry new_tmp_dike <- polyline([{float(m_contents["origin.x"]), float(m_contents["origin.y"])},
															{float(m_contents["end.x"]), float(m_contents["end.y"])}]);
					float altit <- (Cell overlapping new_tmp_dike) max_of(each.soil_height) + float(m_contents["height"]);
					ask Network_Game_Manager{
						map<string,string> mpp <- ["TOPIC"::NEW_COAST_DEF_ALT];
						put string(altit)  		at: "altit" 	in: mpp;
						put m_contents["act_id"] at: "act_id" in: mpp;
						do send to: m_sender contents: mpp;
					}
				}
				match PLAYER_ACTION {  // another player action
				if(game_round > 0) {
					if(int(m_contents["command"]) in ACTION_LIST) {
						create Player_Action {
							self.command 					<- int(m_contents["command"]);
							self.command_round  			<- game_round; 
							self.act_id 					<- m_contents["id"];
							self.initial_application_round 	<- int(m_contents["initial_application_round"]);
							self.district_code 				<- m_sender;
							self.element_id 				<- int(m_contents["element_id"]);
							self.action_type 				<- m_contents["action_type"];
							self.previous_lu_name 			<- m_contents["previous_lu_name"];
							self.is_expropriation 			<- bool(m_contents["is_expropriation"]);
							self.cost 						<- float(m_contents["cost"]);
							self.draw_around				<- int (m_contents["draw_around"]);
							if command in [ACTION_CREATE_DIKE, ACTION_CREATE_DUNE] {
								self.altit	<- float (m_contents["altit"]);
								element_shape <- polyline([{float(m_contents["origin.x"]), float(m_contents["origin.y"])},
															{float(m_contents["end.x"]), float(m_contents["end.y"])}]);
								shape 			 <- element_shape;
								length_coast_def <- int(element_shape.perimeter);
								location 		 <- {float(m_contents["location.x"]),float(m_contents["location.y"])}; 
							}
							else{
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
							if command in [ACTION_CREATE_DIKE,ACTION_REPAIR_DIKE,ACTION_RAISE_DIKE] 
								and (self.element_shape.centroid overlaps first(Inland_Dike_Area))	{	is_inland_dike <- true;	}
							ask districts_in_game first_with(each.dist_id = world.district_id (self.district_code)) {
								budget <- int(budget - myself.cost);	// updating players payment (server side)
								round_actions_cost <- int(round_actions_cost - myself.cost);
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
						ask create_coast_def (self, command) {
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
					match_one [ACTION_INSTALL_GANIVELLE, ACTION_ENHANCE_NATURAL_ACCR] {
					 	Coastal_Defense cd <- Coastal_Defense first_with(each.coast_def_id = element_id);
						if cd != nil {
							ask cd {
								do install_ganivelle;
								not_updated <- true;
								acknowledge <- true;
							}
						}
					}
					match ACTION_MAINTAIN_DUNE {
					 	Coastal_Defense cd <- Coastal_Defense first_with(each.coast_def_id = element_id);
						if cd != nil {
							ask cd {
								do maintain_dune;
								not_updated <- true;
								acknowledge <- true;
							}
						}
					}
					match ACTION_LOAD_PEBBLES_CORD {
					 	Coastal_Defense cd <- Coastal_Defense first_with(each.coast_def_id = element_id);
						if cd != nil {
							ask cd {
								do install_new_slice;
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
			map<string,string> msg <- ["TOPIC"::ACTION_LAND_COVER_UPDATED, "id"::id, "lu_code"::lu_code,
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
			msg <- ["TOPIC"::ACTION_COAST_DEF_UPDATED, "coast_def_id"::coast_def_id,
				 "p1.x"::p1.x, "p1.y"::p1.y, "p2.x"::p2.x, "p2.y"::p2.y,
				 "height"::height, "type"::type, "status"::status, "slices"::slices,
				 "ganivelle"::ganivelle, "alt"::alt, "maintained"::maintained];
			not_updated <- false;
			ask myself{
				do send to: myself.district_code contents: msg;
			}
		}
	}
	
	action send_data_to_district (District d){
		write world.get_message('MSG_SEND_DATA_TO') + " " + d.district_code;
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
		int xx <- 0;
		loop tmp over: d.flood_marks {
			map<string, string> mp <- tmp.build_map_from_fm_attributes();
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
			match_one [HIGH_FLOODING, MEDIUM_FLOODING, LOW_FLOODING] {
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
			switch m_contents[LEADER_COMMAND] {
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
					if act!= nil {
						act.should_wait_lever_to_activate <- bool (m_contents[ACTION_SHOULD_WAIT_LEVER_TO_ACTIVATE]);
						int idd <- int(m_contents["lever_id"]);
						if !(idd in act.id_applied_levers) {
							add idd to: act.id_applied_levers;
						}
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
								int idd <- int(m_contents["id"]);
								if !(idd in ply_action.id_applied_levers) {
									add idd to: ply_action.id_applied_levers;
								}
							}
						}
					}
				}
				
				match NEW_REQUESTED_ACTION {
					ask districts_in_game first_with(each.district_code = m_contents[DISTRICT_CODE]){
						ask Player_Action first_with (each.act_id = m_contents[PLAYER_ACTION_ID]) {
							strategy_profile <- m_contents[STRATEGY_PROFILE];
							float money <- float(m_contents["cost"]);
							switch m_contents[STRATEGY_PROFILE]{
								match BUILDER 		{
									myself.round_build_actions <- myself.round_build_actions + 1;
									myself.round_build_cost <- myself.round_build_cost + money;
								}
								match SOFT_DEFENSE 	{
									myself.round_soft_actions <- myself.round_soft_actions + 1;
									myself.round_soft_cost <- myself.round_soft_cost + money;
								}
								match WITHDRAWAL 	{
									myself.round_withdraw_actions <- myself.round_withdraw_actions + 1;
									myself.round_withdraw_cost <- myself.round_withdraw_cost + money;
								}
								match OTHER 		{
									myself.round_other_actions <- myself.round_other_actions + 1;
									myself.round_other_cost <- myself.round_other_cost + money;
								}
							}
						}
					}
				}
				
				match "TOGGLE_BUTTON" {
					ask districts_in_game first_with(each.district_code = m_contents[DISTRICT_CODE]){
						put int(m_contents["STATE"]) in: buttons_states at: int(m_contents["COMMAND"]);
					}
				}
			}	
		}
	}
	
	reflex inform_leader_action_state when: cycle mod 10 = 0 {
		loop act over: Player_Action where (!each.is_sent_to_leader){
			map<string,string> msg <- act.build_map_from_action_attributes();
			put ACTION_STATE 			key: RESPONSE_TO_LEADER in: msg;
			put string(act.id_applied_levers) at: "activ_levs" in: msg;
			do send to: GAME_LEADER 	contents: msg;
			act.is_sent_to_leader <- true;
		}
	}
	
	action inform_leader_round_number {
		map<string,string> msg <- [];
		put NUM_ROUND 			key: RESPONSE_TO_LEADER in: msg;
		put string(game_round) 	key: NUM_ROUND in: msg;
		ask districts_in_game {
			put string(budget)  key: district_code+"_bud"	in: msg;
			put string(current_population()) key: district_code+"_pop"  in: msg;
		}
		do send to: GAME_LEADER contents: msg;
	}
				
	action inform_leader_indicators_t0  {
		ask districts_in_game {
			map<string,string> msg <- self.my_indicators_t0;
			put INDICATORS_T0 		key: RESPONSE_TO_LEADER 	in: msg;
			put district_code 		key: DISTRICT_CODE 			in: msg;
			put string(sum(districts_taxes[dist_id-1]))		key: "TAXES"	in: msg;
			put string(sum(districts_given_money[dist_id-1]))		key: "GIVEN"	in: msg;
			put string(sum(districts_taken_money[dist_id-1]))		key: "TAKEN"	in: msg;
			put string(sum(districts_transferred_money[dist_id-1]))	key: "TRANSFER"	in: msg;
			put string(sum(districts_actions_costs[dist_id-1]))		key: "ACTIONS"	in: msg;
			put string(sum(districts_levers_costs[dist_id-1]))		key: "LEVERS"	in: msg;
			
			if game_round > 0 {
				if length(buttons_states) > 0 {
					loop ix from: 0 to: length(buttons_states) - 1{
						put string(buttons_states at buttons_states.keys[ix]) key: "button_"+buttons_states.keys[ix] in: msg;
					}
				}
			}
			if game_round > 1 {
				loop ixx from: 0 to: game_round - 2 {
					put string(districts_budgets[dist_id-1][ixx]) key: "budget_round"+ixx   in: msg;
				}
				loop ixx from: 0 to: game_round - 1 {
					put string(round_population[ixx]) key: "pop_round"+ixx   in: msg;
				}		
			}
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
	string strategy_profile <- "";
	int initial_application_round <- -1;
	int round_delay 			  -> {activated_levers sum_of int (each.my_map["added_delay"])};
	int actual_application_round  -> {initial_application_round + round_delay};
	bool is_delayed 			  -> { round_delay > 0 };
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
	list<Activated_Lever> activated_levers <-[]; // activated and validated levers
	list<int> id_applied_levers <- []; // this list contains ids of all triggered levers (validated or canceled)
	int draw_around;
	float altit;

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
			"a_lever_has_been_applied"::string(a_lever_has_been_applied),
			"draw_around"::string(draw_around),
			STRATEGY_PROFILE::strategy_profile,
			"altit"::string(altit)];
			put district_code at: DISTRICT_CODE in: res;
			int i <- 0;
			if element_shape != nil {
				loop pp over: element_shape.points {
					put string(pp.x) key: "locationx"+i in: res;
					put string(pp.y) key: "locationy"+i in: res;
					i <- i + 1;
				}
			}
		return res;
	}
	
	Coastal_Defense create_coast_def (Player_Action act, int comm){
		int next_coast_def_id <- max(Coastal_Defense collect(each.coast_def_id)) +1;
		create Coastal_Defense returns: tmp_coast_def{
			coast_def_id <- next_coast_def_id;
			district_code <- act.district_code;
			shape 	<- act.element_shape;
			location <- act.location;
			type 	<- comm = ACTION_CREATE_DIKE ? COAST_DEF_TYPE_DIKE : COAST_DEF_TYPE_DUNE;
			status 	<- BUILT_DIKE_STATUS;
			height 	<- type = COAST_DEF_TYPE_DIKE ? BUILT_DIKE_HEIGHT : BUILT_DUNE_TYPE1_HEIGHT;	
			cells 	<- Cell overlapping self;
			if act.draw_around = 30 {
				dune_type <- 2;
				height <- BUILT_DUNE_TYPE2_HEIGHT;
				draw_around <- 35;
			} 
			alt <- cells max_of(each.soil_height) + height;
			if type = COAST_DEF_TYPE_DUNE  {
				height_before_ganivelle <- height;
			}
		}
		Coastal_Defense new_coast_def <- first (tmp_coast_def);
		act.element_id 		<-  new_coast_def.coast_def_id;
		ask Network_Game_Manager {
			new_coast_def.shape  <- myself.element_shape;
			point p1 		<- first(myself.element_shape.points);
			point p2 		<- last(myself.element_shape.points);
			map<string,string> msg <- ["TOPIC"::ACTION_COAST_DEF_CREATED,
				 "coast_def_id"::new_coast_def.coast_def_id,"action_id"::myself.act_id,
				 "p1.x"::p1.x, "p1.y"::p1.y, "p2.x"::p2.x, "p2.y"::p2.y, "dune_type"::new_coast_def.dune_type,
				 "height"::new_coast_def.height, "type"::new_coast_def.type, "status"::new_coast_def.status,
				 "alt"::new_coast_def.alt, "location.x"::new_coast_def.location.x, "location.y"::new_coast_def.location.y];
			do send to: new_coast_def.district_code contents: msg;	
		}
		return new_coast_def;
	}
}
//------------------------------ End of Player_Action -------------------------------//

species Coastal_Defense {	
	int coast_def_id;
	string district_code;
	string type;     // DIKE or DUNE ord CORD
	string status;	//  "GOOD" "MEDIUM" "BAD"  
	float height;
	float alt; 
	rgb color 			 <- #pink;
	int counter_status	 <- 0;
	bool rupture		 <- false;
	geometry rupture_area<- nil;
	bool not_updated 	 <- false;
	bool ganivelle 		 <- false; // if DUNE
	int dune_type 		 <- 1; 	   // if DUNE
	bool maintained		 <- false; // if DUNE
	int maintain_status  <- 0;
	int slices 			 <- 4;  // if CORD
	float height_before_ganivelle;
	bool is_protected_by_cord <- false;
	list<Cell> cells;
	int draw_around <- 50;
	bool flooded <- false;
	
	map<string,unknown> build_map_from_coast_def_attributes{
		map<string,unknown> res <- [
			"OBJECT_TYPE"::OBJECT_TYPE_COASTAL_DEFENSE,
			"coast_def_id"::string(coast_def_id),
			"type"::type,
			"status"::status,
			"height"::string(height),
			"alt"::string(alt),
			"ganivelle"::string(ganivelle),
			"maintained"::string(maintained),
			"dune_type"::string(dune_type),
			"rupture"::string(rupture),
			"slices"::string(slices),
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
		counter_status 	<- type = COAST_DEF_TYPE_DUNE ? rnd(STEPS_DEGRAD_STATUS_DUNE - 1) : rnd(STEPS_DEGRAD_STATUS_DIKE - 1);
		cells 			<- Cell where (each overlaps self);
		if type = COAST_DEF_TYPE_DUNE  {
			height_before_ganivelle <- height;
		}
		if !empty(Coastal_Defense at_distance 30 where (each.type=COAST_DEF_TYPE_CORD)) {
			is_protected_by_cord <- true;
		}
		if type != COAST_DEF_TYPE_CORD {
			do build_coast_def;
		}
	}
	
	action build_coast_def {
		ask cells  {
			soil_height <- myself.alt;
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
			map<string,string> msg <- ["TOPIC"::ACTION_COAST_DEF_DROPPED, "coast_def_id"::myself.coast_def_id];
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
	
	action degrade_cord_status {
		if slices > 1 {
			slices <- slices - NB_SLICES_LOST_PER_ROUND;
			if slices <= NB_SLICES_CORD_STATUS_BAD {
				status <- STATUS_BAD;
			}
			else if slices <= NB_SLICES_CORD_STATUS_MEDIUM {
				status <- STATUS_MEDIUM;
			}
			not_updated <- true;
		}
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
				height 	<- height + H_DELTA_GANIVELLE;  // the dune raises by H_DELTA_GANIVELLE until it reaches +H_MAX_GANIVELLE
				alt 	<- alt + H_DELTA_GANIVELLE;
				ask cells {
					soil_height <- soil_height + H_DELTA_GANIVELLE;
					soil_height_before_broken <- soil_height;
					do init_cell_color();
				}
			} else { ganivelle <- false; } // if the dune covers all the ganivelle we reset the ganivelle
			not_updated<- true;
		}
		else { // a dune without a ganivelle
			if maintained {
				maintain_status <- maintain_status - 1;
				if maintain_status = 0 {
					maintained <- false;
					not_updated <- true;
				}
			} else {
				counter_status <- counter_status + 1;
				if counter_status > (dune_type = 1 ? STEPS_DEGRAD_STATUS_DUNE : STEPS_DEGRAD_STATUS_DUNE + 2) {
					counter_status   <- 0;
					if status = STATUS_MEDIUM { status <- STATUS_BAD;   }
					if status = STATUS_GOOD   { status <- STATUS_MEDIUM;}
					not_updated <- true;
				}	
			}
		}
	}
		
	action calculate_rupture {
		int p <- 0;
		if type = COAST_DEF_TYPE_DIKE {
			if 		 status = STATUS_BAD	{ p <- PROBA_RUPTURE_DIKE_STATUS_BAD;	 }
			else if  status = STATUS_MEDIUM	{ p <- PROBA_RUPTURE_DIKE_STATUS_MEDIUM; }
			else 							{ p <- PROBA_RUPTURE_DIKE_STATUS_GOOD;	 }
			
			if is_protected_by_cord { // there is a pebble cord protecting the dike
				map<string, int> probas_good <-[STATUS_GOOD::0,  STATUS_MEDIUM::30, STATUS_BAD::60];
				map<string, int> probas_med <- [STATUS_GOOD::60, STATUS_MEDIUM::75, STATUS_BAD::90];
				map<string, int> probas_bad <- [STATUS_GOOD::90, STATUS_MEDIUM::95, STATUS_BAD::100];
				
				ask Coastal_Defense where (each.type = COAST_DEF_TYPE_CORD) closest_to self {
					if status = STATUS_GOOD {
						p <- probas_good at myself.status;
					} else if  status = STATUS_MEDIUM	{
						p <- probas_med at myself.status;
					} else if status = STATUS_BAD {
						p <- probas_bad at myself.status;
					}  
				}
			}
		}
		else if type = COAST_DEF_TYPE_DUNE  {
			if status = STATUS_BAD 	{
				p <- PROBA_RUPTURE_DUNE_STATUS_BAD;
				if dune_type = 2 { p <- p*2; }	
			}
			else if status = STATUS_MEDIUM 	{
				p <- PROBA_RUPTURE_DUNE_STATUS_MEDIUM;
				if dune_type = 2 { p <- int(p*1.5); }	
			}
			else { p <- PROBA_RUPTURE_DUNE_STATUS_GOOD;	 }
		}
		if flip(p / 100) {
			rupture <- true;
			// the rupture is applied in the middle
			int cIndex <- int(length(cells) / 2);
			// rupture area is about RADIUS_RUPTURE m arount rupture point.
			// if the dike is protected by a pebble cord, the radius is multiplied by 2
			int rupture_radius <- is_protected_by_cord ? RADIUS_RUPTURE * 2 : RADIUS_RUPTURE; 
			rupture_area <- circle(rupture_radius#m,(cells[cIndex]).location);
			// rupture is applied on relevant area cells : circle of radius_rupture
			float soil_height_after_rupture <- max([0, self.alt - self.height]);
			ask Cell where(each.soil_height > 0) overlapping rupture_area {
				soil_height <- min([soil_height, soil_height_after_rupture]);
			}
			write "rupture " + type + " n°" + coast_def_id + "(" + world.dist_code_sname_correspondance_table at district_code + ", status " + status + ", height " + height + ", alt " + alt + ")";
		}
	}
	
	action remove_rupture {
		rupture <- false;
		flooded <- false;
		ask cells overlapping rupture_area {
			if soil_height >= 0 {
				soil_height <- soil_height_before_broken;
			}
		}
		rupture_area <- nil;
	}
	
	action install_ganivelle {
		if status = STATUS_BAD { counter_status <- STEPS_REGAIN_STATUS_GANIVELLE - 1; }
		else				   { counter_status <- 0; 	}		
		ganivelle <- true;
	}
	
	action maintain_dune {
		self.maintained <- true;
		maintain_status <- MAINTAIN_STATUS_DUNE_STEPS;
	}
	
	action install_new_slice{
		slices <- slices + 1;
		if slices > NB_SLICES_CORD_STATUS_MEDIUM {
			status <- STATUS_GOOD;
		}
		else if slices > NB_SLICES_CORD_STATUS_BAD {
			status <- STATUS_MEDIUM;
		}
	}
	
	aspect base {
		switch status {
			match STATUS_GOOD	{ color <- #green;  }
			match STATUS_MEDIUM { color <- #orange; } 
			match STATUS_BAD 	{ color <- #red;	}
			default				{
				color <- #black;
				write "coast def status problem !";
			}
		}
		if type = COAST_DEF_TYPE_DUNE {
			draw draw_around#m around shape color: color;
			if maintained {
					draw shape+10#m color: #whitesmoke;
				}
			if ganivelle {
				loop i over: points_on (shape, 40#m) {
					draw circle(10,i) color: #black;
				}
			} 
		}else if type = COAST_DEF_TYPE_DIKE{
			draw 20#m around shape color: color;// size: 300#m;
		}else {
			draw 20#m around shape color: color;
			list<point> pebbles <- points_on(shape, 10#m);
			float ix <- length(pebbles)/11;
			loop i from: 1 to: slices {
				draw square(20) at: pebbles[int(i*ix)] color: #darkgray;
			}
		}
		if display_ruptures and rupture and flooded {
			list<point> pts <- shape.points;
			point tmp <- length(pts) > 2 ? pts[int(length(pts)/2)] : shape.centroid;
			draw image_file("../images/icons/rupture.png") at: tmp size: 30#px;
		}	
	}
}
//------------------------------ End of Coastal defense -------------------------------//

grid Cell width: GRID_NB_COLS height: GRID_NB_ROWS schedules:[] neighbors: 8 {	
	int cell_type 					<- 0; // 0 = sea
	float water_height  			<- 0.0;
	float max_water_height  		<- 0.0;
	float soil_height 				<- 0.0;
	float rugosity					<- 0.0;
	float soil_height_before_broken <- soil_height;
	rgb soil_color;
	list<float> water_heights <- [];
	
	action init_cell_color {		
		if cell_type = 0 { // sea
			float tmp  <- ((soil_height  / cells_max_depth) with_precision 1) * - 170;
			soil_color <- rgb(80, 80 , int(255 - tmp));
		}else if cell_type = 1{ // land
			soil_color <- land_colors [min(int(soil_height/land_color_interval),LEGEND_SIZE-1)];
		}
	}
	
	aspect water_or_max_water_height {
		if cell_type = 0 or (show_max_water_height? max_water_height = 0 : water_height = 0){ // if sea and water level = 0
			color <- soil_color;
		}else {
			if show_max_water_height { color <- colors_of_water_height[world.class_of_water_height(max_water_height)];	}
			else					 { color <- colors_of_water_height[world.class_of_water_height(water_height)];		}
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
	string density_class-> {population = 0 ? POP_EMPTY : (population < POP_LOW_NUMBER ? POP_VERY_LOW_DENSITY : (population < POP_MEDIUM_NUMBER ? POP_LOW_DENSITY : 
								(population < POP_HIGH_NUMBER ? POP_MEDIUM_DENSITY : POP_DENSE)))};
	int exp_cost 		-> {round (population * 400 * population ^ (-0.5))};
	bool isUrbanType 	-> {lu_code in [LU_TYPE_U,LU_TYPE_Us,LU_TYPE_AU,LU_TYPE_AUs]};
	bool is_adapted 	-> {lu_code in [LU_TYPE_Us,LU_TYPE_AUs]};
	bool is_in_densification<- false;
	bool not_updated 		<- false;
	bool pop_updated 		<- false;
	int population;
	list<Cell> cells;
	float mean_alt <- 0.0;
	int nb_watered_cells;
	int flooded_times <- 0;
	bool marked <- false;
	
	map<string,unknown> build_map_from_lu_attributes {
		map<string,string> res <- [
			"OBJECT_TYPE"::OBJECT_TYPE_LAND_USE,
			"id"::string(id),
			"lu_code"::string(lu_code),
			"mean_alt"::string(mean_alt),
			"population"::string(population),
			"is_in_densification"::string(is_in_densification),
			"locationx"::string(location.x),
			"locationy"::string(location.y),
			"flooded_times"::string(flooded_times)];
			int i <- 0;
			loop pp over:shape.points{
				put string(pp.x) key:"locationx"+i in: res;
				put string(pp.y) key:"locationy"+i in: res;
				i<-i+1;
		}
		return res;
	}
		
	action modify_LU (string new_lu_name) {
		if (lu_code in [LU_TYPE_U,LU_TYPE_Us]) and new_lu_name = "N" {
			population <- 0; //expropriation
		} 
		lu_name <- new_lu_name;
		lu_code <-  lu_type_names index_of lu_name;
		// updating rugosity of related cells
		float rug <- float((eval_gaml("RUGOSITY_" + lu_name)));
		ask cells { rugosity <- rug; }
		if river_flood_shape != nil {
			ask River_Flood_Cell inside self {
				lu_type <- myself.lu_code;
			}
			ask River_Flood_Cell_1m inside self {
				lu_type <- myself.lu_code;
			}
		}
	}
	
	action evolve_AU_to_U {
		if lu_code in [LU_TYPE_AU,LU_TYPE_AUs]{
			AU_to_U_counter <- AU_to_U_counter + 1;
			if AU_to_U_counter = STEPS_FOR_AU_TO_U {
				AU_to_U_counter <- 0;
				lu_name <- lu_code = LU_TYPE_AU ? "U" : "Us";
				lu_code <- lu_type_names index_of lu_name;
				not_updated <- true;
				do assign_population (int(POP_FOR_NEW_U * self.shape.area / STANDARD_LU_AREA), true);
			}
		}	
	}
	
	action evolve_pop_U_densification {
		if !pop_updated and is_in_densification and lu_code in [LU_TYPE_U,LU_TYPE_Us]{
			string previous_d_class <- density_class;
			do assign_population (int(POP_FOR_U_DENSIFICATION * self.shape.area / STANDARD_LU_AREA), true);
			if previous_d_class != density_class {
				is_in_densification <- false;
			}
		}
	}
		
	action evolve_pop_U_standard { 
		if !pop_updated and !is_in_densification and lu_code in [LU_TYPE_U,LU_TYPE_Us]{
			if population_still_to_dispatch > 0 {
				do assign_population (int(POP_FOR_U_STANDARD * self.shape.area / STANDARD_LU_AREA), false);
			}
			if population_still_to_dispatch < 0 {
				do withdraw_population (int(POP_FOR_U_STANDARD * self.shape.area / STANDARD_LU_AREA));
			}
		}
	}
	
	action assign_population(int nb_pop, bool assign_anyway) {
		if population_still_to_dispatch > 0 {
			int pop_to_assign <- min (nb_pop, population_still_to_dispatch);
			population <- population + pop_to_assign;
			population_still_to_dispatch <- population_still_to_dispatch - pop_to_assign;
			not_updated <- true;
			pop_updated <- true;
		}else{
			if assign_anyway {
				population <- population + nb_pop;
				not_updated <- true;
				pop_updated <- true;
			}
		}
	}
	
	action withdraw_population (int nb_pop) {
		if population_still_to_dispatch < 0 {
			int pop_to_withdraw <- min (nb_pop, abs(population_still_to_dispatch));
			int pop_after_withdraw <- population - pop_to_withdraw;
			if pop_after_withdraw >= 0 {
				population <- pop_after_withdraw;
				population_still_to_dispatch <- population_still_to_dispatch + pop_to_withdraw;
				not_updated <- true;
				pop_updated <- true;
			}		
		}
	}
	
	aspect base {
		draw shape color: my_color;
		if is_adapted		  {	draw "A" color:#black anchor: #center;	}
		if is_in_densification{	draw "D" color:#black anchor: #center;  }
	}

	aspect population_density {
		draw shape color: get_color_density();
	}
	
	aspect conditional_outline {
		if show_grid {	draw shape empty: true border:#black;	}
	}
	
	rgb get_color_density {
		switch density_class 		  {
			match POP_EMPTY 		  { return rgb(250,250,250);	}
			match POP_VERY_LOW_DENSITY{ return rgb(225,225,225);}
			match POP_LOW_DENSITY	  { return rgb(190,190,190);	}
			match POP_MEDIUM_DENSITY  { return rgb(150,150,150);	}
			match POP_DENSE 		  { return rgb(120,120,120);	}
		}
	}
	
	rgb cell_color{
		rgb res <- nil;
		switch lu_code{
			match	  LU_TYPE_N				 {res <- #palegreen;		} // natural
			match	  LU_TYPE_A				 {res <- rgb(225, 165, 0);	} // agricultural
			match_one [LU_TYPE_AU,LU_TYPE_AUs]{res <- #yellow;		 	} // to urbanize
			match_one [LU_TYPE_U,LU_TYPE_Us] {					 	    // urbanised
				return get_color_density();
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
	map<int, int> buttons_states <- [];
	list<Flood_Mark> flood_marks <- [];
	
	int budget;
	float tax_unit;
	int received_tax <-0;
	int round_actions_cost <- 0;
	int round_given_money  <- 0;
	int round_taken_money  <- 0;
	int round_levers_cost  <- 0;
	int round_transferred_money <- 0;
	
	int round_build_actions <- 0;
	int round_soft_actions <- 0;
	int round_withdraw_actions <- 0;
	int round_other_actions <- 0;
	
	float round_build_cost <- 0.0;
	float round_soft_cost <- 0.0;
	float round_withdraw_cost <- 0.0;
	float round_other_cost <- 0.0;
	
	// init water heights
	float tot_0_5c	  <-0.0;		float tot_1c 	<-0.0;		float tot_maxc 	  <-0.0;
	float U_0_5c  	  <-0.0;		float U_1c 		<-0.0;		float U_maxc 	  <-0.0;
	float Us_0_5c 	  <-0.0;		float Us_1c 	<-0.0;		float Us_maxc 	  <-0.0;
	float Udense_0_5c <-0.0;		float Udense_1c <-0.0;		float Udense_maxc <-0.0;
	float AU_0_5c 	  <-0.0; 		float AU_1c 	<-0.0;		float AU_maxc 	  <-0.0;
	float A_0_5c 	  <-0.0;		float A_1c 		<-0.0;		float A_maxc      <-0.0;
	float N_0_5c 	  <-0.0;		float N_1c 		<-0.0;		float N_maxc 	  <-0.0;
	
	float prev_tot_0_5c	  <-0.0;		float prev_tot_1c 	<-0.0;		float prev_tot_maxc 	  <-0.0;
	float prev_U_0_5c  	  <-0.0;		float prev_U_1c 	<-0.0;		float prev_U_maxc 	  <-0.0;
	float prev_Us_0_5c 	  <-0.0;		float prev_Us_1c 	<-0.0;		float prev_Us_maxc 	  <-0.0;
	float prev_Udense_0_5c <-0.0;		float prev_Udense_1c <-0.0;		float prev_Udense_maxc <-0.0;
	float prev_AU_0_5c 	  <-0.0; 		float prev_AU_1c 	<-0.0;		float prev_AU_maxc 	  <-0.0;
	float prev_A_0_5c 	  <-0.0;		float prev_A_1c 	<-0.0;		float prev_A_maxc      <-0.0;
	float prev_N_0_5c 	  <-0.0;		float prev_N_1c 	<-0.0;		float prev_N_maxc 	  <-0.0;
	
	float flooded_area <- 0.0;	list<float> data_flooded_area<- [];
	float totU 		   <- 0.0;	list<float> data_totU 		 <- [];
	float totUs 	   <- 0.0;	list<float> data_totUs 		 <- [];
	float totUdense	   <- 0.0;	list<float> data_totUdense 	 <- [];
	float totAU 	   <- 0.0;	list<float> data_totAU 		 <- [];
	float totN 		   <- 0.0;	list<float> data_totN 		 <- [];
	float totA 		   <- 0.0;	list<float> data_totA 		 <- [];
	
	// river flood | 0 : total | 1-7: lu_type
	list<float> loth_0_5c <- [0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0];
	list<float> loth_1c <- [0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0];
	list<float> loth_maxc <- [0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0];
	
	list<float> loth1m_0_5c <- [0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0];
	list<float> loth1m_1c <- [0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0];
	list<float> loth1m_maxc <- [0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0];
	
	list<int> round_population <- [];
	list<float> surface_N <- [];
	list<float> surface_N_diff <- [];
	list<float> surface_U <- [];
	list<float> surface_U_diff <- [];
	list<float> surface_Udense <- [];
	list<float> surface_Udense_diff <- [];
	list<float> surface_AU <- [];
	list<float> surface_A <- [];
	list<float> surface_A_diff <- [];
	list<float> surface_Us <- [];
	list<float> surface_Us_diff <- [];
	list<float> surface_Usdense <- [];
	list<float> surface_Usdense_diff <- [];
	list<float> surface_AUs <- [];
	
	list<float> length_dikes_all <- [];
	list<float> length_dikes_good <- [];
	list<float> length_dikes_medium <- [];
	list<float> length_dikes_bad <- [];
	list<float> stat_dikes_good <- [];
	
	list<float> mean_alt_dikes_all <- [];
	list<float> mean_alt_dikes_good <- [];
	list<float> mean_alt_dikes_medium <- [];
	list<float> mean_alt_dikes_bad <- [];
				
	list<float> min_alt_dikes_all <- [];
	list<float> min_alt_dikes_good <- [];
	list<float> min_alt_dikes_medium <- [];
	list<float> min_alt_dikes_bad <- [];
	
	list<float> length_dunes_all <- [];
	list<float> length_dunes_good <- [];
	list<float> length_dunes_medium <- [];
	list<float> length_dunes_bad <- [];
	list<float> stat_dunes_good <- [];
				
	list<float> mean_alt_dunes_all <- [];
	list<float> mean_alt_dunes_good <- [];
	list<float> mean_alt_dunes_medium <- [];
	list<float> mean_alt_dunes_bad <- [];
				
	list<float> min_alt_dunes_all <- [];
	list<float> min_alt_dunes_good <- [];
	list<float> min_alt_dunes_medium <- [];
	list<float> min_alt_dunes_bad <- [];

	// Indicators calculated at initialization, and sent to Leader when he connects
	map<string,string> my_indicators_t0 <- [];
	// My dikes ruptures during last submersion
	list<int> ruptures <- [];
	
	aspect flooding { draw shape color: rgb (0,0,0,0) border:#black; }
	aspect planning { draw shape color: rgb(255,255,212) border: #black; }
	
	int current_population {  return sum(LUs accumulate (each.population));	}
	
	action inform_new_round {// inform about a new round
		map<string,string> msg <- ["TOPIC"::INFORM_NEW_ROUND];
		put string(current_population()) at: POPULATION in: msg;
		put string(budget) at: BUDGET in: msg;
		ask Network_Game_Manager{
			do send to: myself.district_code contents: msg;
		}
	}
	
	action inform_leader_stats {
		map<string,string> msg <- [RESPONSE_TO_LEADER::"STATS"];
		put district_code  key: DISTRICT_CODE	in: msg;
		put string(received_tax) 			key: "TAX"		in: msg;
		put string(round_actions_cost) 		key: "ACTIONS"	in: msg;
		ask Network_Listener_To_Leader{
			do send to: GAME_LEADER contents: msg;
		}
	}
	
	action inform_current_round {// inform about the current round (when the player side district (re)connects)
		map<string,string> msg <- ["TOPIC"::INFORM_CURRENT_ROUND];
		put string(game_round) 		  	at: NUM_ROUND		in: msg;
		put string(game_paused) 		at: "GAME_PAUSED"	in: msg;
		put string(current_population()) at: POPULATION in: msg;
		put string(budget) 				at: BUDGET 	   in: msg;
		if game_round > 0 and length(buttons_states) > 0 {
			loop ix from: 0 to: length(buttons_states) - 1{
				put string(buttons_states at buttons_states.keys[ix]) key: "button_"+buttons_states.keys[ix] in: msg;
			}
		}
		ask Network_Game_Manager{
			do send to: myself.district_code contents: msg;
		}
	}
	
	action calculate_taxes {
		received_tax <- int(self.current_population() * tax_unit);
		budget <- budget + received_tax;
		write district_name + " -> population: " + self.current_population() + "| tax: " + received_tax + "| budget: "+ budget;
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
		put string(length(LUs where (each.lu_code = LU_TYPE_A))) 	key: "count_LU_A_t0"   in: my_indicators_t0; // count cells of type A
		put string(length(LUs where (each.lu_code = LU_TYPE_N))) 	key: "count_LU_N_t0"   in: my_indicators_t0; // count cells of type N
		put string(length(LUs where (each.lu_code = LU_TYPE_AU)))   key: "count_LU_AU_t0"  in: my_indicators_t0; // count cells of type AU
		put string(length(LUs where (each.lu_code = LU_TYPE_U))) 	key: "count_LU_U_t0"   in: my_indicators_t0; // count cells of type U
	}
	
	action calculate_river_flood_results { // for Normandie
		float my_area <- 0.0;
		loop i from: 0 to: 6 { // init tables
			loth_0_5c [i] <- 0.0; 	loth_1c [i] <- 0.0;	loth_maxc [i] <- 0.0;
			loth1m_0_5c [i] <- 0.0;	loth1m_1c [i] <- 0.0;	loth1m_maxc [i] <- 0.0;
		}
		
		ask River_Flood_Cell where (each intersects self) {
			if lu_type != -1 {
				my_area <- self.shape.area / 10000;
				if water_h <= 0.5 { // flooded area by river inundation
					myself.loth_0_5c[0] <- myself.loth_0_5c[0] + my_area;
					myself.loth_0_5c[lu_type] <- myself.loth_0_5c[lu_type] + my_area;
				} else if between (water_h ,0.5, 1.0) {
					myself.loth_1c[0] <- myself.loth_1c[0] + my_area;
					myself.loth_1c[lu_type] <- myself.loth_1c[lu_type] + my_area;
				} else{
					myself.loth_maxc[0] <- myself.loth_maxc[0] + my_area;
					myself.loth_maxc[lu_type] <- myself.loth_maxc[lu_type] + my_area;
				}
			}
		}

		ask River_Flood_Cell_1m where (each intersects self) {
			if lu_type != -1 {
				my_area <- self.shape.area / 10000;
				if water_h <= 0.5 { // flooded area by river inundation
					myself.loth1m_0_5c[0] <- myself.loth1m_0_5c[0] + my_area;
					myself.loth1m_0_5c[lu_type] <- myself.loth1m_0_5c[lu_type] + my_area;
				} else if between (water_h ,0.5, 1.0) {
					myself.loth1m_1c[0] <- myself.loth1m_1c[0] + my_area;
					myself.loth1m_1c[lu_type] <- myself.loth1m_1c[lu_type] + my_area;
				} else{
					myself.loth1m_maxc[0] <- myself.loth1m_maxc[0] + my_area;
					myself.loth1m_maxc[lu_type] <- myself.loth1m_maxc[lu_type] + my_area;
				}	
			}
		}
	}			
}
//------------------------------ End of District -------------------------------//

species Polycell{
	point loc;
	rgb col;
	aspect base{
		if show_max_water_height {
			draw rectangle(GRID_CELL_SIZE, GRID_CELL_SIZE) color: col at: loc;	
		}
	}
}
//------------------------------ End of Polycell -------------------------------//	
// generic buttons
species Button{
	int nb_button 	 <- 0;
	string command 	 <- "";
	string display_text;
	string display_text2 <- '';
	bool is_selected <- false;
	geometry shape 	 <- square(min(button_size.x,button_size.y));
	image_file my_icon;
	
	aspect buttons_master {
		if nb_button in [0,1,2,3,5,7,8,55,57,911,912,913,914] {
			draw shape color: #white border: is_selected ? #red : #black;
			draw display_text color: #black at: location + {0,shape.height*0.55} anchor: #center;
			draw display_text2 color: #black at: location + {0,shape.height*0.75} anchor: #center;
			draw my_icon size: shape.width-50#m;
		} else if nb_button = 6 {
			if int(command) < length(list_flooding_events) {
				draw shape color: #white border: is_selected ? #red : #black;
				draw display_text color: #black at: location + {0, shape.height*0.55} anchor: #center;
				draw my_icon size: shape.width-50#m;
				draw ""+command color: #black font: bold40 at: location - {40,40} anchor: #center;
			}
		}	
	}
	
	aspect buttons_map {
		if nb_button = 4 {
			draw shape color: #white border: is_selected? # red : # black;
			draw my_icon size: 800#m;
		}
	}
}

species Legend_Planning{
	list<rgb> colors <- [];
	list<string> texts <- [];
	point start_location;
	point rect_size <- {300, 400};
	rgb text_color  <- application_name = "camargue" ? #white : #black;
	
	init{
		texts <- ["N","A","AU, AUs","U empty", "U low","U medium","U dense"];
		colors<- [#palegreen,rgb(225,165,0),#yellow,rgb(245,245,245),rgb(220,220,220),rgb(192,192,192),rgb(169,169,169)];
		start_location <- {LEGEND_POSITION_X/3, LEGEND_POSITION_Y-750};		
	}
	
	aspect {
		loop i from: 0 to: length(texts) - 1 {
			draw rectangle(rect_size) at: start_location + {0, i * rect_size.y} color: colors[i] border: #black;
			draw texts[i] at: start_location + {rect_size.x - 50, (i * rect_size.y) + 200} color: text_color size: rect_size.y;
		}
	}
}

species Legend_Map parent: Legend_Planning {
	init {
		start_location <- {LEGEND_POSITION_X/3, LEGEND_POSITION_Y};
		text_color <- #white;
		int t1 <- int(land_color_interval);
		int t2 <- int(land_color_interval*2);
		int t3 <- int(land_color_interval*3);
		if LEGEND_SIZE = 5 {
			texts <- [''+int(land_max_height)+' m',''+t3+' m',''+t2+' m',''+t1+' m','0 m'];
			colors <- reverse(land_colors);
		} else if LEGEND_SIZE = 4 {
			texts <- [''+int(land_max_height)+' m',''+t3+' m',''+t2+' m','0 m'];
			colors <- reverse(copy_between(land_colors,0,4));
		} else if LEGEND_SIZE = 3 {
			texts <- [''+int(land_max_height)+' m',''+t2+' m','0 m'];
			colors <- reverse(copy_between(land_colors,0,3));
		}
	}
}

species Legend_Flood_Map parent: Legend_Planning {
	init{
		text_color <- #white;
		texts <- [">1.0 m","","<0.5 m"];
		colors<- [rgb(65,65,255),rgb(115,115,255),rgb(200,200,255)];
		start_location <- {LEGEND_POSITION_X, LEGEND_POSITION_Y};
	}
	
	aspect {
		if show_max_water_height {
			loop i from: 0 to: length(texts) - 1 {
				draw rectangle(rect_size) at: start_location + {0,i * rect_size.y} color: colors[i] border: #black;
				draw texts[i] at: start_location + {rect_size.x, (i * rect_size.y)+75} color: text_color size: rect_size.y;
			}
		}
	}
}

species Legend_Flood_Plan parent: Legend_Flood_Map {
	init{
		text_color <- application_name = "camargue" ? #white : #black;
		start_location <- {LEGEND_POSITION_X + 350, LEGEND_POSITION_Y};
	}
	
	aspect {
		if show_max_water_height {
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

species Protected_Area {
	aspect base {
		if show_protected_areas {
			draw shape color: rgb (185, 255, 185,120) border:#black;	
		}
	}
}

species Flood_Risk_Area {
	aspect base {
		if show_risked_areas {
			draw shape color: rgb (20, 200, 255,120) border:#black;
		}
	}
}
// 400 m littoral area
species Coastal_Border_Area {
	geometry line_shape;
}

//100 m coastline inland area to identify retro dikes
species Inland_Dike_Area { aspect base { draw shape color: rgb (100, 100, 205,120) border:#black;} }

species Water_Gate { // a water gate for the case of Dieppe
	int id;
	float alt;
	list<Cell> cells;
	bool display_me <- false;
	aspect base {
		if display_me {
			draw 15#m around shape color: #black;
			draw shape color: #white;
		}
	}
	
	action close_open {
		if display_me { // close
			ask cells {
				soil_height <- myself.alt;
			}
		} else {
			ask cells {
				soil_height <- soil_height_before_broken;
			}
		}
	}
}

species Flood_Mark {
	float max_w_h;
	float max_w_h_per_cent;
	float mean_w_h;
	int sub_num <- 0;
	Land_Use mylu <- nil;
	
	map<string,unknown> build_map_from_fm_attributes {
		map<string,string> res <- [
			"OBJECT_TYPE"::OBJECT_TYPE_FLOOD_MARK,
			"max_w_h"::string(max_w_h with_precision 1),
			"max_w_h_per_cent"::string(max_w_h_per_cent),
			"mean_w_h"::string(mean_w_h),
			"sub_num"::string(sub_num),
			"mylu"::string(mylu.id)];
		return res;
	}
}

// river flood shapefile for dieppe
species River_Flood_Cell {
	float water_h;
	int lu_type <- -1;
	rgb col;
	int display_me <- 1;
	aspect base {
		if show_river_flooded_area = display_me {
			draw shape color: col border:#transparent;	
		}
	}
}

species River_Flood_Cell_1m parent: River_Flood_Cell {
	int display_me <- 2;
}
//---------------------------- Experiment definiton -----------------------------//

experiment LittoSIM_GEN_Manager type: gui schedules:[]{
	
	string default_language <- first(text_file("../includes/config/littosim.conf").contents where (each contains 'LANGUAGE')) split_with ';' at 1;
	list<string> languages_list <- first(text_file("../includes/config/littosim.conf").contents where (each contains 'LANGUAGE_LIST')) split_with ';' at 1 split_with ',';
	
	init {
		minimum_cycle_duration <- 0.5;
	}
	
	parameter "Language choice : " var: my_language	 <- default_language  among: languages_list;
	parameter "Save data : " var: save_data <- false;
	
	output {
		
		display "Game control"{	
			graphics "Master" {
				draw shape color: #lightgray border: #black;
			}
			species Button  aspect: buttons_master;
			graphics "Play_pause" transparency: 0.5{
				draw square(min(button_size.x, button_size.y)) at: game_paused ? pause_b : play_b color: #lightgray ;
			}
			graphics "Control Panel"{
				point loc 	<- {world.shape.width/2, world.shape.height/2};
				float msize <- min([loc.x*2/3, loc.y*2/3]);
				draw image_file("../images/ihm/logo.png") at: loc size: {msize, msize};
				draw rectangle(msize,1500) at: loc + {0,msize*0.66} color: #lightgray border: #gray anchor:#center;
				draw MSG_ROUND + " : " + game_round color: #black font: bold20 at: loc + {0,msize*0.66} anchor:#center;
			}	
			event mouse_down action: button_click_master_control;
		}
		
		display "Flooding" background: #black{
			grid Cell;
			species Cell 			aspect: water_or_max_water_height;
			species District 		aspect: flooding;
			species Isoline			aspect: base;
			species Road 			aspect: base;
			species Water			aspect: base;
			species River_Flood_Cell aspect: base;
			species River_Flood_Cell_1m aspect: base;
			species Coastal_Defense aspect: base;
			species Land_Use 		aspect: conditional_outline;
			species Water_Gate		aspect: base;
			species Protected_Area 	aspect: base;
			species Flood_Risk_Area aspect: base;
			species Button 			aspect: buttons_map;
			species Legend_Map;
			species Legend_Flood_Map;
			
			event mouse_down 		action: button_click_map;
		}
		
		display "Planning" background: #black{
			graphics "World" {
				draw shape color: rgb(230,251,255);
				if application_name = "camargue" {
					draw rectangle(2*world.shape.width, world.shape.height) at: {0,0} color: #black;
				}
			}
			species District 		aspect: planning;
			species Land_Use 		aspect: base;
			species Road 	 		aspect: base;
			species Water			aspect: base;
			species Coastal_Defense aspect: base;
			species Polycell		aspect: base;
			species River_Flood_Cell aspect: base;
			species River_Flood_Cell_1m aspect: base;	
			species Water_Gate		aspect: base;
			species Protected_Area 	aspect: base;
			species Flood_Risk_Area aspect: base;
			species Legend_Planning;
			species Legend_Flood_Plan;
		}
		
		display "Population & Budgets" {
			chart MSG_POPULATION type: series size: {0.33,0.48} position: {0.01,0.01} x_range:[0,12] 
					x_label: MSG_ROUND x_tick_line_visible: false{
				data "" value: submersions collect (each * max(districts_in_game accumulate each.round_population)) color: #black style: bar;
				loop i from: 0 to: 3{
					data districts_in_game[i].district_name value: districts_in_game[i].round_population color: dist_colors[i] marker_shape: marker_circle;
				}
			}
			chart world.get_message('MSG_BUDGETS') type: series size: {0.33,0.48} position: {0.34,0.01} x_range:[0,12] 
					x_label: MSG_ROUND x_tick_line_visible: false{
				data "" value: submersions collect (each * max(districts_budgets accumulate each)) color: #black style: bar;
				loop i from: 0 to: 3{
					data districts_in_game[i].district_name value: districts_budgets[i] color: dist_colors[i] marker_shape: marker_circle;
				}		
			}
			chart LDR_TOTAL type: histogram size: {0.33,0.48} position: {0.67,0.01} style:stack
				x_serie_labels: districts_in_game collect each.district_name series_label_position: xaxis x_tick_line_visible: false {
			 	data MSG_TAXES value: districts_taxes collect sum(each) color: color_lbls[0];
			 	data LDR_GIVEN value: districts_given_money collect sum(each) color: color_lbls[1];
			 	data LDR_TAKEN value: districts_taken_money collect sum(each) color: color_lbls[2];
				data LDR_TRANSFERRED value: districts_transferred_money collect sum(each) color: color_lbls[5];
			 	data LEV_MSG_ACTIONS value: districts_actions_costs collect sum(each) color: color_lbls[3];
			 	data MSG_LEVERS value: districts_levers_costs collect sum(each) color: color_lbls[4];		
			}
			//-----	
			chart districts_in_game[0].district_long_name type: histogram size: {0.48,0.24} position: {0.01,0.5}
				style: stack x_range:[0,12] x_label: MSG_ROUND{
			 	data MSG_TAXES value: districts_taxes[0] color: color_lbls[0];
			 	data LDR_GIVEN value: districts_given_money[0] color: color_lbls[1];
			 	data LDR_TAKEN value: districts_taken_money[0] color: color_lbls[2];
			 	data LDR_TRANSFERRED value: districts_transferred_money[0] color: color_lbls[5];
			 	data LEV_MSG_ACTIONS value: districts_actions_costs[0] color: color_lbls[3];
			 	data MSG_LEVERS value: districts_levers_costs[0] color: color_lbls[4];		
			}
			chart districts_in_game[1].district_long_name type: histogram size: {0.48,0.24} position: {0.5,0.5}
				style: stack x_range:[0,12] x_label: MSG_ROUND{
			 	data MSG_TAXES value: districts_taxes[1] color: color_lbls[0];
			 	data LDR_GIVEN value: districts_given_money[1] color: color_lbls[1];
			 	data LDR_TAKEN value: districts_taken_money[1] color: color_lbls[2];
			 	data LDR_TRANSFERRED value: districts_transferred_money[1] color: color_lbls[5];
			 	data LEV_MSG_ACTIONS value: districts_actions_costs[1] color: color_lbls[3];
			 	data MSG_LEVERS value: districts_levers_costs[1] color: color_lbls[4];		
			}
			chart districts_in_game[2].district_long_name type: histogram size: {0.48,0.24} position: {0.01,0.75}
				style: stack x_range:[0,12] x_label: MSG_ROUND{
			 	data MSG_TAXES value: districts_taxes[2] color: color_lbls[0];
			 	data LDR_GIVEN value: districts_given_money[2] color: color_lbls[1];
			 	data LDR_TAKEN value: districts_taken_money[2] color: color_lbls[2];
			 	data LDR_TRANSFERRED value: districts_transferred_money[2] color: color_lbls[5];
			 	data LEV_MSG_ACTIONS value: districts_actions_costs[2] color: color_lbls[3];
			 	data MSG_LEVERS value: districts_levers_costs[2] color: color_lbls[4];		
			}
			chart districts_in_game[3].district_long_name type: histogram size: {0.48,0.24} position: {0.5,0.75}
				style: stack x_range:[0,12] x_label: MSG_ROUND{
			 	data MSG_TAXES value: districts_taxes[3] color: color_lbls[0];
			 	data LDR_GIVEN value: districts_given_money[3] color: color_lbls[1];
			 	data LDR_TAKEN value: districts_taken_money[3] color: color_lbls[2];
			 	data LDR_TRANSFERRED value: districts_transferred_money[3] color: color_lbls[5];
			 	data LEV_MSG_ACTIONS value: districts_actions_costs[3] color: color_lbls[3];
			 	data MSG_LEVERS value: districts_levers_costs[3] color: color_lbls[4];		
			}
		}
		
		display "Actions & Strategies" {
			chart world.get_message('MSG_NUMBER_ACTIONS') type: histogram size: {0.48,0.48} position: {0.01,0.01}
				x_serie_labels: districts_in_game collect (each.district_name) style:stack {
			 	data MSG_BUILDER value: districts_build_strategies collect sum(each) color: color_lbls[2];
			 	data MSG_SOFT_DEF value: districts_soft_strategies collect sum(each) color: color_lbls[1];
			 	data MSG_WITHDRAWAL value: districts_withdraw_strategies collect sum(each) color: color_lbls[0];
			 	data MSG_OTHER value: districts_other_strategies collect sum(each) color: color_lbls[3];
			}
			chart world.get_message('MSG_COST_ACTIONS') type: histogram size: {0.48,0.48} position: {0.51,0.01}
				x_serie_labels: districts_in_game collect (each.district_name) style:stack {
			 	data MSG_BUILDER value: districts_build_costs collect sum(each) color: color_lbls[2];
			 	data MSG_SOFT_DEF value: districts_soft_costs collect sum(each) color: color_lbls[1];
			 	data MSG_WITHDRAWAL value: districts_withdraw_costs collect sum(each) color: color_lbls[0];
			 	data MSG_OTHER value: districts_other_costs collect sum(each) color: color_lbls[3];
			}
			//-------					
			chart districts_in_game[0].district_long_name type: histogram size: {0.48,0.24} position: {0.01,0.5}
				style: stack x_range:[0,12] x_label: MSG_ROUND{
			 	data MSG_BUILDER value: districts_build_costs[0] color: color_lbls[2];
			 	data MSG_SOFT_DEF value: districts_soft_costs[0] color: color_lbls[1];
			 	data MSG_WITHDRAWAL value: districts_withdraw_costs[0] color: color_lbls[0];
			 	data MSG_OTHER value: districts_other_costs[0] color: color_lbls[3];
			}
			chart districts_in_game[1].district_long_name type: histogram size: {0.48,0.24} position: {0.5,0.5}
				style: stack x_range:[0,12] x_label: MSG_ROUND{
			 	data MSG_BUILDER value: districts_build_costs[1] color: color_lbls[2];
			 	data MSG_SOFT_DEF value: districts_soft_costs[1] color: color_lbls[1];
			 	data MSG_WITHDRAWAL value: districts_withdraw_costs[1] color: color_lbls[0];
			 	data MSG_OTHER value: districts_other_costs[1] color: color_lbls[3];
			}
			chart districts_in_game[2].district_long_name type: histogram size: {0.48,0.24} position: {0.01,0.75}
				style: stack x_range:[0,12] x_label: MSG_ROUND{
			 	data MSG_BUILDER value: districts_build_costs[2] color: color_lbls[2];
			 	data MSG_SOFT_DEF value: districts_soft_costs[2] color: color_lbls[1];
			 	data MSG_WITHDRAWAL value: districts_withdraw_costs[2] color: color_lbls[0];
			 	data MSG_OTHER value: districts_other_costs[2] color: color_lbls[3];
			}
			chart districts_in_game[3].district_long_name type: histogram size: {0.48,0.24} position: {0.5,0.75}
				style: stack x_range:[0,12] x_label: MSG_ROUND{
			 	data MSG_BUILDER value: districts_build_costs[3] color: color_lbls[2];
			 	data MSG_SOFT_DEF value: districts_soft_costs[3] color: color_lbls[1];
			 	data MSG_WITHDRAWAL value: districts_withdraw_costs[3] color: color_lbls[0];
			 	data MSG_OTHER value: districts_other_costs[3] color: color_lbls[3];
			}
		}
				
		display "LU & CODEF" {
			chart districts_in_game[0].district_long_name type: series size: {0.24,0.48} position: {0.0,0.01}
				x_tick_line_visible: false x_range:[0,12] x_label: MSG_ROUND{
					data "N" value: districts_in_game[0].surface_N_diff color: #green marker_shape: marker_circle;
					data "U" value: districts_in_game[0].surface_U_diff color: #gray marker_shape: marker_circle;
					data "U"+MSG_DENSE value: districts_in_game[0].surface_Udense_diff color: #black marker_shape: marker_circle;
					data "A" value: districts_in_game[0].surface_A_diff color: #orange marker_shape: marker_circle;
					data "Us" value: districts_in_game[0].surface_Us_diff color: #blue marker_shape: marker_circle;
					data "Us"+MSG_DENSE value: districts_in_game[0].surface_Usdense_diff color: #darkblue marker_shape: marker_circle;
			}
			chart districts_in_game[1].district_long_name type: series size: {0.24,0.48} position: {0.25,0.01}
				x_tick_line_visible: false x_range:[0,12] x_label: MSG_ROUND{
					data "N" value: districts_in_game[1].surface_N_diff color: #green marker_shape: marker_circle;
					data "U" value: districts_in_game[1].surface_U_diff color: #gray marker_shape: marker_circle;
					data "U"+MSG_DENSE value: districts_in_game[1].surface_Udense_diff color: #black marker_shape: marker_circle;
					data "A" value: districts_in_game[1].surface_A_diff color: #orange marker_shape: marker_circle;
					data "Us" value: districts_in_game[1].surface_Us_diff color: #blue marker_shape: marker_circle;
					data "Us"+MSG_DENSE value: districts_in_game[1].surface_Usdense_diff color: #darkblue marker_shape: marker_circle;
			}
			chart districts_in_game[2].district_long_name type: series size: {0.24,0.48} position: {0.50,0.01}
				x_tick_line_visible: false x_range:[0,12] x_label: MSG_ROUND{
					data "N" value: districts_in_game[2].surface_N_diff color: #green marker_shape: marker_circle;
					data "U" value: districts_in_game[2].surface_U_diff color: #gray marker_shape: marker_circle;
					data "U"+MSG_DENSE value: districts_in_game[2].surface_Udense_diff color: #black marker_shape: marker_circle;
					data "A" value: districts_in_game[2].surface_A_diff color: #orange marker_shape: marker_circle;
					data "Us" value: districts_in_game[2].surface_Us_diff color: #blue marker_shape: marker_circle;
					data "Us"+MSG_DENSE value: districts_in_game[2].surface_Usdense_diff color: #darkblue marker_shape: marker_circle;
			}
			chart districts_in_game[3].district_long_name type: series size: {0.24,0.48} position: {0.75,0.01}
				x_tick_line_visible: false x_range:[0,12] x_label: MSG_ROUND{
					data "N" value: districts_in_game[3].surface_N_diff color: #green marker_shape: marker_circle;
					data "U" value: districts_in_game[3].surface_U_diff color: #gray marker_shape: marker_circle;
					data "U"+MSG_DENSE value: districts_in_game[3].surface_Udense_diff color: #black marker_shape: marker_circle;
					data "A" value: districts_in_game[3].surface_A_diff color: #orange marker_shape: marker_circle;
					data "Us" value: districts_in_game[3].surface_Us_diff color: #blue marker_shape: marker_circle;
					data "Us"+MSG_DENSE value: districts_in_game[3].surface_Usdense_diff color: #darkblue marker_shape: marker_circle;
			}
			/****************************************//****************************************/		
			chart LEV_DIKES type: series size: {0.48,0.48} position: {0.01,0.51} x_range:[0,12] 
					x_label: MSG_ROUND x_tick_line_visible: false {
				loop i from: 0 to: 3{
					data districts_in_game[i].district_name value: districts_in_game[i].stat_dikes_good color: dist_colors[i] marker_shape: marker_circle;
				}		
			}
			/****************************************//****************************************/
			chart LEV_DUNES type: series size: {0.48,0.48} position: {0.51,0.51} x_range:[0,12] 
					x_label: MSG_ROUND x_tick_line_visible: false{
				loop i from: 0 to: 3{
					data districts_in_game[i].district_name value: districts_in_game[i].stat_dunes_good color: dist_colors[i] marker_shape: marker_circle;
				}		
			}
		}
		
		display "Flooded depth per area"{
			chart MSG_AREA+" U" type: histogram style: stack background: rgb("white") size: {0.24,0.48} position: {0, 0}
				x_serie_labels: districts_in_game collect each.district_name {
				data "0.5" value: districts_in_game collect (each.U_0_5c + (show_river_flooded_area = 0 ? 0 : (show_river_flooded_area = 1 ?
							each.loth_0_5c[LU_TYPE_U] : each.loth1m_0_5c[LU_TYPE_U]))) color: colors_of_water_height[0];
				data "1" value: districts_in_game collect (each.U_1c + (show_river_flooded_area = 0 ? 0 : (show_river_flooded_area = 1 ?
							each.loth_1c[LU_TYPE_U] : each.loth1m_1c[LU_TYPE_U]))) color: colors_of_water_height[1];
				data ">1" value: districts_in_game collect (each.U_maxc + (show_river_flooded_area = 0 ? 0 : (show_river_flooded_area = 1 ?
							each.loth_maxc[LU_TYPE_U] : each.loth1m_maxc[LU_TYPE_U]))) color: colors_of_water_height[2];
			}
			chart MSG_AREA+" U "+ MSG_DENSE type: histogram style: stack background: rgb("white") size: {0.24,0.48} position: {0.25, 0}
				x_serie_labels: districts_in_game collect each.district_name {
				data "0.5" value: districts_in_game collect (each.Udense_0_5c + (show_river_flooded_area = 0 ? 0 : (show_river_flooded_area = 1 ?
							each.loth_0_5c[LU_TYPE_Ui] : each.loth1m_0_5c[LU_TYPE_Ui]))) color: colors_of_water_height[0];
				data "1" value: districts_in_game collect (each.Udense_1c + (show_river_flooded_area = 0 ? 0 : (show_river_flooded_area = 1 ?
							each.loth_1c[LU_TYPE_Ui] : each.loth1m_1c[LU_TYPE_Ui]))) color: colors_of_water_height[1];
				data ">1" value: districts_in_game collect (each.Udense_maxc + (show_river_flooded_area = 0 ? 0 : (show_river_flooded_area = 1 ?
							each.loth_maxc[LU_TYPE_Ui] : each.loth1m_maxc[LU_TYPE_Ui]))) color: colors_of_water_height[2];
			}
			chart MSG_AREA+" Us" type: histogram style: stack background: rgb("white") size: {0.24,0.48} position: {0.51, 0}
				x_serie_labels: districts_in_game collect each.district_name {
				data "0.5" value: districts_in_game collect (each.Us_0_5c + (show_river_flooded_area = 0 ? 0 : (show_river_flooded_area = 1 ?
							each.loth_0_5c[LU_TYPE_Us] : each.loth1m_0_5c[LU_TYPE_Us]))) color: colors_of_water_height[0];
				data "1" value: districts_in_game collect (each.Us_1c + (show_river_flooded_area = 0 ? 0 : (show_river_flooded_area = 1 ?
							each.loth_1c[LU_TYPE_Us] : each.loth1m_1c[LU_TYPE_Us]))) color: colors_of_water_height[1];
				data ">1" value: districts_in_game collect (each.Us_maxc + (show_river_flooded_area = 0 ? 0 : (show_river_flooded_area = 1 ?
							each.loth_maxc[LU_TYPE_Us] : each.loth1m_maxc[LU_TYPE_Us]))) color: colors_of_water_height[2];
			}
			chart MSG_AREA+" AU" type: histogram style: stack background: rgb("white") size: {0.24,0.48} position: {0.76, 0}
				x_serie_labels: districts_in_game collect each.district_name {
				data "0.5" value: districts_in_game collect (each.AU_0_5c + (show_river_flooded_area = 0 ? 0 : (show_river_flooded_area = 1 ?
							each.loth_0_5c[LU_TYPE_AU] : each.loth1m_0_5c[LU_TYPE_AU]))) color: colors_of_water_height[0];
				data "1" value: districts_in_game collect (each.AU_1c + (show_river_flooded_area = 0 ? 0 : (show_river_flooded_area = 1 ?
							each.loth_1c[LU_TYPE_AU] : each.loth1m_1c[LU_TYPE_AU]))) color: colors_of_water_height[1];
				data ">1" value: districts_in_game collect (each.AU_maxc + (show_river_flooded_area = 0 ? 0 : (show_river_flooded_area = 1 ?
							each.loth_maxc[LU_TYPE_AU] : each.loth1m_maxc[LU_TYPE_AU]))) color: colors_of_water_height[2];
			}
			
			chart MSG_AREA+" A" type: histogram style: stack background: rgb("white") size: {0.33,0.48} position: {0.01, 0.5}
				x_serie_labels: districts_in_game collect each.district_name {
				data "0.5" value: districts_in_game collect (each.A_0_5c + (show_river_flooded_area = 0 ? 0 : (show_river_flooded_area = 1 ?
							each.loth_0_5c[LU_TYPE_A] : each.loth1m_0_5c[LU_TYPE_A]))) color: colors_of_water_height[0];
				data "1" value: districts_in_game collect (each.A_1c + (show_river_flooded_area = 0 ? 0 : (show_river_flooded_area = 1 ?
							each.loth_1c[LU_TYPE_A] : each.loth1m_1c[LU_TYPE_A]))) color: colors_of_water_height[1];
				data ">1" value: districts_in_game collect (each.A_maxc + (show_river_flooded_area = 0 ? 0 : (show_river_flooded_area = 1 ?
							each.loth_maxc[LU_TYPE_A] : each.loth1m_maxc[LU_TYPE_A]))) color: colors_of_water_height[2];
			}
			chart MSG_AREA+" N" type: histogram style: stack background: rgb("white") size: {0.33,0.48} position: {0.34, 0.5}
				x_serie_labels: districts_in_game collect each.district_name {
				data "0.5" value: districts_in_game collect (each.N_0_5c + (show_river_flooded_area = 0 ? 0 : (show_river_flooded_area = 1 ?
							each.loth_0_5c[LU_TYPE_N] : each.loth1m_0_5c[LU_TYPE_N]))) color: colors_of_water_height[0];
				data "1" value: districts_in_game collect (each.N_1c + (show_river_flooded_area = 0 ? 0 : (show_river_flooded_area = 1 ?
							each.loth_1c[LU_TYPE_N] : each.loth1m_1c[LU_TYPE_N]))) color: colors_of_water_height[1];
				data ">1" value: districts_in_game collect (each.N_maxc + (show_river_flooded_area = 0 ? 0 : (show_river_flooded_area = 1 ?
							each.loth_maxc[LU_TYPE_N] : each.loth1m_maxc[LU_TYPE_N]))) color: colors_of_water_height[2];
			}
			chart LDR_TOTAL type: histogram style: stack background: rgb("white") size: {0.33,0.48} position: {0.67, 0.5}
				x_serie_labels: districts_in_game collect each.district_name {
				data "0.5" value: districts_in_game collect (each.tot_0_5c + (show_river_flooded_area = 0 ? 0 : (show_river_flooded_area = 1 ?
							each.loth_0_5c[0] : each.loth1m_0_5c[0]))) color: colors_of_water_height[0];
				data "1" value: districts_in_game collect (each.tot_1c + (show_river_flooded_area = 0 ? 0 : (show_river_flooded_area = 1 ?
							each.loth_1c[0] : each.loth1m_1c[0]))) color: colors_of_water_height[1]; 
				data ">1" value: districts_in_game collect (each.tot_maxc + (show_river_flooded_area = 0 ? 0 : (show_river_flooded_area = 1 ?
							each.loth_maxc[0] : each.loth1m_maxc[0]))) color: colors_of_water_height[2];
			}
		}
		
		display "Previous flooded depth per area"{
			chart MSG_AREA+" U" type: histogram style: stack background: rgb("whitesmoke") size: {0.24,0.48} position: {0, 0}
				x_serie_labels: districts_in_game collect each.district_name {
				data "0.5" value: districts_in_game collect (each.prev_U_0_5c + (show_river_flooded_area = 0 ? 0 : (show_river_flooded_area = 1 ?
							each.loth_0_5c[LU_TYPE_U] : each.loth1m_0_5c[LU_TYPE_U]))) color: colors_of_water_height[0];
				data "1" value: districts_in_game collect (each.prev_U_1c + (show_river_flooded_area = 0 ? 0 : (show_river_flooded_area = 1 ?
							each.loth_1c[LU_TYPE_U] : each.loth1m_1c[LU_TYPE_U]))) color: colors_of_water_height[1];
				data ">1" value: districts_in_game collect (each.prev_U_maxc + (show_river_flooded_area = 0 ? 0 : (show_river_flooded_area = 1 ?
							each.loth_maxc[LU_TYPE_U] : each.loth1m_maxc[LU_TYPE_U]))) color: colors_of_water_height[2];
			}
			chart MSG_AREA+" U "+ MSG_DENSE type: histogram style: stack background: rgb("whitesmoke") size: {0.24,0.48} position: {0.25, 0}
				x_serie_labels: districts_in_game collect each.district_name {
				data "0.5" value: districts_in_game collect (each.prev_Udense_0_5c + (show_river_flooded_area = 0 ? 0 : (show_river_flooded_area = 1 ?
							each.loth_0_5c[LU_TYPE_Ui] : each.loth1m_0_5c[LU_TYPE_Ui]))) color: colors_of_water_height[0];
				data "1" value: districts_in_game collect (each.prev_Udense_1c + (show_river_flooded_area = 0 ? 0 : (show_river_flooded_area = 1 ?
							each.loth_1c[LU_TYPE_Ui] : each.loth1m_1c[LU_TYPE_Ui]))) color: colors_of_water_height[1];
				data ">1" value: districts_in_game collect (each.prev_Udense_maxc + (show_river_flooded_area = 0 ? 0 : (show_river_flooded_area = 1 ?
							each.loth_maxc[LU_TYPE_Ui] : each.loth1m_maxc[LU_TYPE_Ui]))) color: colors_of_water_height[2];
			}
			chart MSG_AREA+" Us" type: histogram style: stack background: rgb("whitesmoke") size: {0.24,0.48} position: {0.51, 0}
				x_serie_labels: districts_in_game collect each.district_name {
				data "0.5" value: districts_in_game collect (each.prev_Us_0_5c + (show_river_flooded_area = 0 ? 0 : (show_river_flooded_area = 1 ?
							each.loth_0_5c[LU_TYPE_Us] : each.loth1m_0_5c[LU_TYPE_Us]))) color: colors_of_water_height[0];
				data "1" value: districts_in_game collect (each.prev_Us_1c + (show_river_flooded_area = 0 ? 0 : (show_river_flooded_area = 1 ?
							each.loth_1c[LU_TYPE_Us] : each.loth1m_1c[LU_TYPE_Us]))) color: colors_of_water_height[1];
				data ">1" value: districts_in_game collect (each.prev_Us_maxc + (show_river_flooded_area = 0 ? 0 : (show_river_flooded_area = 1 ?
							each.loth_maxc[LU_TYPE_Us] : each.loth1m_maxc[LU_TYPE_Us]))) color: colors_of_water_height[2];
			}
			chart MSG_AREA+" AU" type: histogram style: stack background: rgb("whitesmoke") size: {0.24,0.48} position: {0.76, 0}
				x_serie_labels: districts_in_game collect each.district_name {
				data "0.5" value: districts_in_game collect (each.prev_AU_0_5c + (show_river_flooded_area = 0 ? 0 : (show_river_flooded_area = 1 ?
							each.loth_0_5c[LU_TYPE_AU] : each.loth1m_0_5c[LU_TYPE_AU]))) color: colors_of_water_height[0];
				data "1" value: districts_in_game collect (each.prev_AU_1c + (show_river_flooded_area = 0 ? 0 : (show_river_flooded_area = 1 ?
							each.loth_1c[LU_TYPE_AU] : each.loth1m_1c[LU_TYPE_AU]))) color: colors_of_water_height[1];
				data ">1" value: districts_in_game collect (each.prev_AU_maxc + (show_river_flooded_area = 0 ? 0 : (show_river_flooded_area = 1 ?
							each.loth_maxc[LU_TYPE_AU] : each.loth1m_maxc[LU_TYPE_AU]))) color: colors_of_water_height[2];
			}
			
			chart MSG_AREA+" A" type: histogram style: stack background: rgb("whitesmoke") size: {0.33,0.48} position: {0.01, 0.5}
				x_serie_labels: districts_in_game collect each.district_name {
				data "0.5" value: districts_in_game collect (each.prev_A_0_5c + (show_river_flooded_area = 0 ? 0 : (show_river_flooded_area = 1 ?
							each.loth_0_5c[LU_TYPE_A] : each.loth1m_0_5c[LU_TYPE_A]))) color: colors_of_water_height[0];
				data "1" value: districts_in_game collect (each.prev_A_1c + (show_river_flooded_area = 0 ? 0 : (show_river_flooded_area = 1 ?
							each.loth_1c[LU_TYPE_A] : each.loth1m_1c[LU_TYPE_A]))) color: colors_of_water_height[1];
				data ">1" value: districts_in_game collect (each.prev_A_maxc + (show_river_flooded_area = 0 ? 0 : (show_river_flooded_area = 1 ?
							each.loth_maxc[LU_TYPE_A] : each.loth1m_maxc[LU_TYPE_A]))) color: colors_of_water_height[2];
			}
			chart MSG_AREA+" N" type: histogram style: stack background: rgb("whitesmoke") size: {0.33,0.48} position: {0.34, 0.5}
				x_serie_labels: districts_in_game collect each.district_name {
				data "0.5" value: districts_in_game collect (each.prev_N_0_5c + (show_river_flooded_area = 0 ? 0 : (show_river_flooded_area = 1 ?
							each.loth_0_5c[LU_TYPE_N] : each.loth1m_0_5c[LU_TYPE_N]))) color: colors_of_water_height[0];
				data "1" value: districts_in_game collect (each.prev_N_1c + (show_river_flooded_area = 0 ? 0 : (show_river_flooded_area = 1 ?
							each.loth_1c[LU_TYPE_N] : each.loth1m_1c[LU_TYPE_N]))) color: colors_of_water_height[1];
				data ">1" value: districts_in_game collect (each.prev_N_maxc + (show_river_flooded_area = 0 ? 0 : (show_river_flooded_area = 1 ?
							each.loth_maxc[LU_TYPE_N] : each.loth1m_maxc[LU_TYPE_N]))) color: colors_of_water_height[2];
			}
			chart LDR_TOTAL type: histogram style: stack background: rgb("whitesmoke") size: {0.33,0.48} position: {0.67, 0.5}
				x_serie_labels: districts_in_game collect each.district_name {
				data "0.5" value: districts_in_game collect (each.prev_tot_0_5c + (show_river_flooded_area = 0 ? 0 : (show_river_flooded_area = 1 ?
							each.loth_0_5c[0] : each.loth1m_0_5c[0]))) color: colors_of_water_height[0];
				data "1" value: districts_in_game collect (each.prev_tot_1c + (show_river_flooded_area = 0 ? 0 : (show_river_flooded_area = 1 ?
							each.loth_1c[0] : each.loth1m_1c[0]))) color: colors_of_water_height[1]; 
				data ">1" value: districts_in_game collect (each.prev_tot_maxc + (show_river_flooded_area = 0 ? 0 : (show_river_flooded_area = 1 ?
							each.loth_maxc[0] : each.loth1m_maxc[0]))) color: colors_of_water_height[2];
			}
		}
		
		display "Flooded area per district"{
			chart MSG_ALL_AREAS type: series size: {0.48,0.45} position: {0, 0} x_tick_line_visible: false x_range:[0,5] x_label: MSG_SUBMERSION{
				loop i from: 0 to: 3{
					data districts_in_game[i].district_name value: districts_in_game[i].data_flooded_area color: dist_colors[i] marker_shape: marker_circle;
				}			
			}
			chart MSG_AREA+" U" type: series size: {0.24,0.45} position: {0.5, 0} x_tick_line_visible: false x_range:[0,5] x_label: MSG_SUBMERSION{
				loop i from: 0 to: 3{
					data districts_in_game[i].district_name value: districts_in_game[i].data_totU color: dist_colors[i] marker_shape: marker_circle;
				}			
			}
			chart MSG_AREA+" U "+ MSG_DENSE type: series x_tick_line_visible: false size: {0.24,0.45} position: {0.75, 0} 
					x_label: MSG_SUBMERSION x_range:[0,5]{
				loop i from: 0 to: 3{
					data districts_in_game[i].district_name value: districts_in_game[i].data_totUdense color: dist_colors[i] marker_shape: marker_circle;
				}			
			}
			chart MSG_AREA+" Us" type: series size: {0.24,0.45} position: {0, 0.5} x_tick_line_visible: false x_range:[0,5] x_label: MSG_SUBMERSION{
				loop i from: 0 to: 3{
					data districts_in_game[i].district_name value: districts_in_game[i].data_totUs color: dist_colors[i] marker_shape: marker_circle;
				} 			
			}
			chart MSG_AREA+" AU" type: series size: {0.24,0.45} position: {0.25, 0.5} x_tick_line_visible: false x_range:[0,5] x_label: MSG_SUBMERSION{
				loop i from: 0 to: 3{
					data districts_in_game[i].district_name value: districts_in_game[i].data_totAU color: dist_colors[i] marker_shape: marker_circle;
				}			
			}
			chart MSG_AREA+" N" type: series size: {0.24,0.45} position: {0.50, 0.5} x_tick_line_visible: false x_range:[0,5] x_label: MSG_SUBMERSION{
				loop i from: 0 to: 3{
					data districts_in_game[i].district_name value: districts_in_game[i].data_totN color: dist_colors[i] marker_shape: marker_circle;
				} 			
			}
			chart MSG_AREA+" A" type: series size: {0.24,0.45} position: {0.75, 0.5} x_tick_line_visible: false x_range:[0,5] x_label: MSG_SUBMERSION{
				loop i from: 0 to: 3{
					data districts_in_game[i].district_name value: districts_in_game[i].data_totA color: dist_colors[i] marker_shape: marker_circle;
				}			
			}
		}
	}
}
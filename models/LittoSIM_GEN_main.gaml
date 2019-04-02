/**
 *  littoSIM_GEN
 *  Authors: Brice, Cécilia, Elise, Etienne, Fredéric, Marion, Nicolas B, Nicolas M, Xavier 
 * 
 *  Description : LittoSim est un jeu sérieux qui se présente sous la forme d’une simulation intégrant à la fois 
 *  un modèle de submersion marine, la modélisation de différents rôles d’acteurs agissant sur le territoire 
 *  et la possibilité de mettre en place différents scénarios de prévention des submersions qui seront contrôlés
 *  par les utilisateurs de la simulation en fonction de leur rôle. 
 */

model LittoSIM_GEN

import "params_models/params_main.gaml"

global {

	// Lisflood configuration for the study area
	string application_name <- shapes_def["APPLICATION_NAME"]; // used to name exported files
	// sea heights file sent to Lisflood
	string lisflood_bdy_file ->{floodEventType ="HIGH_FLOODING"?flooding_def["LISFLOOD_BDY_HIGH_FILENAME"]   // "oleron2016_Xynthia.bdy" 
								:(floodEventType ="LOW_FLOODING"?flooding_def["LISFLOOD_BDY_LOW_FILENAME"] // "oleron2016_Xynthia-50.bdy" : Xynthia - 50 cm 
		  						:langs_def at 'MSG_FLOODING_TYPE_PROBLEM' at configuration_file["LANGUAGE"])};
	// paths to Lisflood
	string lisfloodPath <- flooding_def["LISFLOOD_PATH"]; // absolute path to Lisflood : "C:/lisflood-fp-604/"
	string lisfloodRelativePath <- flooding_def["LISFLOOD_RELATIVE_PATH"]; // Lisflood folder relatife path 
	string results_lisflood_rep <- flooding_def["RESULTS_LISFLOOD_REP"]; // Lisflood results folder
	string lisflood_par_file -> {"inputs/"+"LittoSIM_GEN_"+application_name+"_config_"+floodEventType+timestamp+".par"}; // parameter file
	string lisflood_DEM_file -> {"inputs/"+"LittoSIM_GEN_"+application_name+"_DEM"+ timestamp + ".asc"}  ; // DEM file 
	string lisflood_rugosityGrid_file -> {"inputs/"+"LittoSIM_GEN_"+application_name+"_n" + timestamp + ".asc"}; // rugosity file
	string lisflood_bat_file <- flooding_def["LISFLOOD_BAT_FILE"] ; //  Lisflood executable
	
	// variables for Lisflood calculs 
	map<string,string> list_flooding_events ;  // list of submersions of a round
	int lisfloodReadingStep <- 9999999; // to indicate to which step of Lisflood results, the current cycle corresponds // lisfloodReadingStep = 9999999 it means that there is no Lisflood result corresponding to the current cycle 
	string timestamp <- ""; // used to specify a unique name to the folder of flooding results
	string flood_results <- "";   //  text of flood results per district // saved as a txt file
	string floodEventType ;
	
	// parameters for saving submersion results
	string results_rep <- results_lisflood_rep+ "/results"+EXPERIMENT_START_TIME; // folder to save main model results
	string shape_export_filePath -> {results_rep+"/results_SHP_Tour"+round+".shp"}; //	shapefile to save cells
	string log_export_filePath <- results_rep+"/log_"+machine_time+".csv"; 	// file to save user actions (main model and players actions)  
	
	// operation variables
	geometry shape <- envelope(emprise_shape); // world geometry
	float EXPERIMENT_START_TIME <- machine_time; // machine time at simulation initialization 
	geometry all_flood_risk_area; // geometry agrregating risked area polygons
	geometry all_protected_area; // geometry agrregating protected area polygons
	int messageID <- 0; // network communication	
	
	// budget tables to draw evolution graphs
	list<list<int>> districts_budgets <- [[],[],[],[]];
	
	// population dynamics
	int new_comers_still_to_dispatch <- 0;
    
	// other variables
	bool show_max_water_height<- false ;// defines if the water_height displayed on the map should be the max one or the current one
	string stateSimPhase <- SIM_NOT_STARTED; // state variable of current simulation state 
	int round <- 0;
	list<District> districts_in_game;
	list<rgb> listC <- brewer_colors("YlOrRd", 8);
	
	init{
		create Data_retreive;
		// Create GIS agents
		create District from: districts_shape with: [district_code::string(read("dist_code")),
													 district_name::string(read("dist_sname")),
													id::int(read("player_id"))]{
			write "" + langs_def at 'MSG_COMMUNE' at configuration_file["LANGUAGE"] + " " + district_name + "("+district_code+")" + " "+id;
		}
		districts_in_game <- (District where (each.id > 0)) sort_by (each.id);
		
		create Coastal_defense from: coastal_defenses_shape with: [dike_id::int(read("object_id")),
										type::string(read("type")), status::string(read("status")),
										alt::float(get("alt")), height::float(get("height")), district_code::string(read("dist_code"))];
		
		create Protected_area from: protected_areas_shape with: [name::string(read("site_code"))];
		all_protected_area <- union(Protected_area);
		create Road from: roads_shape;
		create Flood_risk_area from: rpp_area_shape;
		all_flood_risk_area <- union(Flood_risk_area);
		create Coast_border_area from: coastline_shape { shape <-  shape + coastBorderBuffer #m; }
		create Inland_dike_area from: contour_neg_100m_shape;
		
		create Land_use from: land_use_shape with: [id::int(read("unit_id")), lu_code::int(read("unit_code")),
													population::int(get("unit_pop")), cout_expro:: int(get("exp_cost"))]{
			lu_name <- nameOfUAcode(lu_code);
			my_color <- cell_color();
			if lu_name = "U" and population = 0 { population <- minPopUArea;	}
			if lu_name = "AU" {	AU_to_U_counter <- flip(0.5)?1:0;	not_updated <- true;	}
		}
		
		// Create Network agents
		if activemq_connect {
			create Network_round_manager;
			create Network_listener_to_leader;
			create Network_player;
			create Network_activated_lever;
		}
		
		loop i from: 0 to: (length(listC)-1) {	listC[i] <- blend (listC[i], #red , 0.9);	}
		do init_buttons;
		stateSimPhase <- SIM_NOT_STARTED;
		do addElementIn_list_flooding_events ("Submersion initiale","results");
		
		do load_rugosity;
		ask Land_use {	cells <- cell overlapping self;	}
		ask districts_in_game{
			UAs <- Land_use overlapping self;
			cells <- cell overlapping self;
			budget <- int(current_population(self) * impot_unit * (1 +  pctBudgetInit/100));
			write district_name +" "+ langs_def at 'MSG_INITIAL_BUDGET' at configuration_file["LANGUAGE"] + " : " + budget;
			do calculate_indicators_t0;
		}
		ask Coastal_defense {	do init_dike;	}

	}
	//------------------------------ End of init -------------------------------//
	 	
	int getMessageID{
 		messageID<- messageID +1;
 		return messageID;
 	} 	
	 	
	int delayOfAction (int action_code){
		int rslt <- 9999;
		loop i from:0 to: (length(actions_def) /3) - 1 {
			if ((int(actions_def at {1,i})) = action_code)
			 {rslt <- int(actions_def at {2,i});}
		}
		return rslt;
	}
	 
	int entityTypeCodeOfAction (int action_code){
		string rslt <- "";
		loop i from:0 to: (length(actions_def) /3) - 1 {
			if ((int(actions_def at {1,i})) = action_code)
			 {rslt <- actions_def at {4,i};}
		}
		switch rslt {
			match "COAST_DEF" {return ENTITY_TYPE_CODE_COAST_DEF; }
			match "LU" 		  {return ENTITY_TYPE_CODE_LU;		  }
			default 		  {return 0;						  }
		}
	} 
		 
	int current_total_population {	return sum(District where (each.id > 0) accumulate (each.current_population(each)));	}
	
	int new_comers_to_dispatch 	 {	return round(current_total_population() * ANNUAL_POP_GROWTH_RATE);	}

	action new_round{
		if save_shp {	do save_cells_as_shp_file;	}
		write MSG_NEW_ROUND + " " + (round +1);
		if round != 0 {
			ask Coastal_defense where (each.type != DUNE) {  do evolveStatus_ouvrage;}
		   	ask Coastal_defense where (each.type  = DUNE) {  do evolve_dune;		 }
			new_comers_still_to_dispatch <- new_comers_to_dispatch() ;
			ask shuffle(Land_use) 			 { pop_updated <- false; do evolve_AU_to_U ; }
			ask shuffle(Land_use) 			 { do evolve_U_densification ; 				 }
			ask shuffle(Land_use) 			 { do evolve_U_standard ; 					 } 
			ask District where (each.id > 0) { do calcul_taxes;							 }
		}
		else {
			stateSimPhase <- SIM_GAME;
			write stateSimPhase;
		}
		round <- round + 1;
		ask District 				 	{	do inform_new_round;			} 
		ask Network_listener_to_leader  {	do informLeader_round_number;	}
		do save_budget_data;
		write MSG_GAME_DONE + " !";
	} 	
	
	int district_id(string xx){ // FIXME quoi ?!!
		District m <- District first_with (each.network_name = xx);
		if(m = nil){
			m <- (District first_with (xx contains each.district_code));
			m.network_name <- xx;
		}
		return m.id;
	}

	reflex show_flood_stats when: stateSimPhase = SIM_SHOWING_FLOOD_STATS {// fin innondation
		// affichage des résultats 
		write flood_results;
		save flood_results to: lisfloodRelativePath+results_rep+"/flood_results-"+machine_time+"-Tour"+round+".txt" type: "text";

		map values <- user_input([(MSG_OK_CONTINUE):: ""]);
		
		// remise à zero des hauteurs d'eau
		loop r from: 0 to: nb_rows -1{	loop c from:0 to: nb_cols -1 {cell[c,r].water_height <- 0.0;}}
		
		// cancel dikes ruptures				
		ask Coastal_defense {	if rupture = 1 {	do removeRupture;	}	}
		// redémarage du jeu
		if round = 0{
			stateSimPhase <- SIM_NOT_STARTED;
			write stateSimPhase;
		}
		else{
			stateSimPhase <- SIM_GAME;
			write stateSimPhase + " - "+ langs_def at 'MSG_ROUND' at configuration_file["LANGUAGE"] +" "+round;
		}
	}
	
	reflex calculate_flood_stats when: stateSimPhase = SIM_CALCULATING_FLOOD_STATS{// end of an inundation
		do calculate_districts_results; // calculating results
		stateSimPhase <- SIM_SHOWING_FLOOD_STATS;
		write stateSimPhase;
	}
	
	// reading inundation files
	reflex show_lisflood when: stateSimPhase = SIM_SHOWING_LISFLOOD	{	do readLisflood;	}
	
	action replay_flood_event{
		string txt;
		int i <-1;
		loop aK over: list_flooding_events.keys{
			txt<- txt + "\n"+i+" :"+aK;
			i <-i +1;
		}
		map values <- user_input((MSG_SUBMERSION_NUMBER) + " " + txt,[(MSG_NUMBER)+ " :" :: "0"]);
		map<string, unknown> msg <-[];
		i <- int(values[(MSG_NUMBER)+ " :"]);
		if i=0 or i > length(list_flooding_events.keys){return;}
				
		string replayed_flooding_event  <- (list_flooding_events.keys)[i-1] ;
		write replayed_flooding_event;
		loop r from: 0 to: nb_rows -1  { loop c from:0 to: nb_cols -1 {cell[c,r].max_water_height <- 0.0; } } // remise à zero de max_water_height
		set lisfloodReadingStep <- 0;
		results_lisflood_rep <- list_flooding_events at replayed_flooding_event;
		stateSimPhase <- SIM_SHOWING_LISFLOOD; write stateSimPhase;
	}
		
	action launchFlood_event{
		if round = 0 {
			map values <- user_input([(MSG_SIM_NOT_STARTED) :: ""]);
	     	write stateSimPhase;
		}
		// excuting Lisflood
		if round != 0 {
			do new_round;
			loop r from: 0 to: nb_rows -1  {
				loop c from:0 to: nb_cols -1 {
					cell[c,r].max_water_height <- 0.0;  // reset of max_water_height
				}
			}
			ask Coastal_defense {	do calcRupture;		}
			stateSimPhase <- SIM_EXEC_LISFLOOD;
			write stateSimPhase;
			do executeLisflood;
		} 
		lisfloodReadingStep <- 0;
		stateSimPhase <- SIM_SHOWING_LISFLOOD;
		write stateSimPhase;
	}

	action addElementIn_list_flooding_events (string sub_name, string sub_rep){
		put sub_rep key: sub_name in: list_flooding_events;
		ask Network_round_manager{
			do add_element(sub_name,sub_rep);
		}
	}
		
	action executeLisflood{
		timestamp <- "_R"+round+"_t"+machine_time ;
		results_lisflood_rep <- "results"+timestamp;
		do save_dem;  
		do save_rugosityGrid;
		do save_lf_launch_files;
		do addElementIn_list_flooding_events("Submersion Tour "+round,results_lisflood_rep);
		save "directory created by littoSIM Gama model" to: lisfloodRelativePath+results_lisflood_rep+"/readme.txt" type: "text";// need to create the lisflood results directory because lisflood cannot create it buy himself
		ask Network_listener_to_leader{
			do execute command:"cmd /c start "+lisfloodPath+lisflood_bat_file; }
 	}
 		
	action save_lf_launch_files {
		save ("DEMfile         "+lisfloodPath+lisflood_DEM_file+"\nresroot         res\ndirroot         results\nsim_time        52200\ninitial_tstep   10.0\nmassint         100.0\nsaveint         3600.0\n#checkpoint     0.00001\n#overpass       100000.0\n#fpfric         0.06\n#infiltration   0.000001\n#overpassfile   buscot.opts\nmanningfile     "+lisfloodPath+lisflood_rugosityGrid_file+"\n#riverfile      buscot.river\nbcifile         "+lisfloodPath+"oleron2016.bci\nbdyfile         "+lisfloodPath+lisflood_bdy_file+"\n#weirfile       buscot.weir\nstartfile       "+lisfloodPath+"oleron.start\nstartelev\n#stagefile      buscot.stage\nelevoff\n#depthoff\n#adaptoff\n#qoutput\n#chainageoff\nSGC_enable\n") rewrite: true to: lisfloodRelativePath+lisflood_par_file type: "text"  ;
		save (lisfloodPath+"lisflood.exe -dir "+ lisfloodPath+results_lisflood_rep +" "+(lisfloodPath+lisflood_par_file)) rewrite: true  to: lisfloodRelativePath+lisflood_bat_file type: "text" ;
	}       

	action save_dem {	save cell to: lisfloodRelativePath + lisflood_DEM_file type: "asc";	}
	action save_cells_as_shp_file {	save cell type:"shp" to: shape_export_filePath with: [soil_height::"SOIL_HEIGHT", water_height::"WATER_HEIGHT"];	}
	action save_budget_data{
		loop ix from: 1 to: 4 {	add (District first_with(each.id = ix)).budget to: districts_budgets[ix-1];	}
	}	

	action save_rugosityGrid {
		string filename <- lisfloodRelativePath+lisflood_rugosityGrid_file;
		save 'ncols         631\nnrows         906\nxllcorner     364927.14666668\nyllcorner     6531972.5655556\ncellsize      20\nNODATA_value  -9999' rewrite: true to: filename type:"text";
		loop j from: 0 to: nb_rows- 1 {
			string text <- "";
			loop i from: 0 to: nb_cols - 1 {	text <- text + " "+ cell[i,j].rugosity;	}
			save text to: filename rewrite: false ;
		}
	}
	   
	action readLisflood{  
	 	string nb <- string(lisfloodReadingStep);
		loop i from: 0 to: 3-length(nb) { nb <- "0"+nb; }
		string fileName <- lisfloodRelativePath+results_lisflood_rep+"/res-"+ nb +".wd";
		write "lisfloodRelativePath " + lisfloodRelativePath;
		write "results_lisflood_rep " + results_lisflood_rep;
		write "nb  " + nb;
		if file_exists (fileName){
			write fileName;
			file lfdata <- text_file(fileName) ;
			loop r from: 6 to: length(lfdata) -1 {
				string l <- lfdata[r];
				list<string> res <- l split_with "\t";
				loop c from: 0 to: length(res) - 1{
					float w <- float(res[c]);
					if w > cell[c,r-6].max_water_height {cell[c,r-6].max_water_height <-w;}
					cell[c,r-6].water_height <- w;}}	
	        lisfloodReadingStep <- lisfloodReadingStep +1;
	     }
	     else{ // end of flooding
     		lisfloodReadingStep <-  9999999;
     		if nb = "0000" {
     			map values <- user_input([(MSG_NO_FLOOD_FILE_EVENT) :: ""]);
     			stateSimPhase <- SIM_GAME;
     			write stateSimPhase + " - "+langs_def at 'MSG_ROUND' at configuration_file["LANGUAGE"]+" "+round;
     		}
     		else{	stateSimPhase <- SIM_CALCULATING_FLOOD_STATS; write stateSimPhase; }	}
	}
	
	action load_rugosity{
		file rug_data <- text_file(RUGOSITE_PAR_DEFAUT) ;
		loop r from: 6 to: length(rug_data) -1 {
			string l <- rug_data[r];
			list<string> res <- l split_with " ";
			loop c from: 0 to: length(res) - 1 { cell[c,r-6].rugosity <- float(res[c]);} }	
	}
	
	action calculate_districts_results{
		string text <- "";
			ask ((District where (each.id > 0)) sort_by (each.id)){
				int tot <- length(cells) ;
				int myid <-  self.id; 
				int U_0_5 <-0;		int U_1 <-0;		int U_max <-0;
				int Us_0_5 <-0;		int Us_1 <-0;		int Us_max <-0;
				int Udense_0_5 <-0;	int Udense_1 <-0;	int Udense_max <-0;
				int AU_0_5 <-0;		int AU_1 <-0;		int AU_max <-0;
				int A_0_5 <-0;		int A_1 <-0;		int A_max <-0;
				int N_0_5 <-0;		int N_1 <-0;		int N_max <-0;
				
				ask UAs{
					ask cells {
						if max_water_height > 0{
							switch myself.lu_name{ //"U","Us","AU","N","A"    -> et  "AUs" impossible normallement
								match "AUs" {
									write "STOP :  AUs " + langs_def at 'MSG_IMPOSSIBLE_NORMALLY' at configuration_file["LANGUAGE"];
								}
								match "U" {
									if max_water_height <= 0.5 				{
										U_0_5 <- U_0_5 +1;
										if myself.classe_densite = POP_DENSE 	{	Udense_0_5 <- Udense_0_5 +1;	}
									}
									if between (max_water_height ,0.5, 1.0) {
										U_1 <- U_1 +1;
										if myself.classe_densite = POP_DENSE 	{	Udense_1 <- Udense_1 +1;		}
									}
									if max_water_height >= 1				{
										U_max <- U_max +1 ;
										if myself.classe_densite = POP_DENSE 	{	Udense_0_5 <- Udense_0_5 +1;	}
									}
								}
								match "Us" {
									if max_water_height <= 0.5 				{	Us_0_5 <- Us_0_5 +1;			}
									if between (max_water_height ,0.5, 1.0) {	Us_1 <- Us_1 +1;				}
									if max_water_height >= 1				{	Us_max <- Us_max +1 ;			}
								}
								match "AU" {
									if max_water_height <= 0.5 				{	AU_0_5 <- AU_0_5 +1;			}
									if between (max_water_height ,0.5, 1.0) {	AU_1 <- AU_1 +1;				}
									if max_water_height >= 1.0 				{	AU_max <- AU_max +1 ;			}
								}
								match "N"  {
									if max_water_height <= 0.5 				{	N_0_5 <- N_0_5 +1;				}
									if between (max_water_height ,0.5, 1.0) {	N_1 <- N_1 +1;					}
									if max_water_height >= 1.0 				{	N_max <- N_max +1 ;				}
								}
								match "A" {
									if max_water_height <= 0.5 				{	A_0_5 <- A_0_5 +1;				}
									if between (max_water_height ,0.5, 1.0) {	A_1 <- A_1 +1;					}
									if max_water_height >= 1.0 				{	A_max <- A_max +1 ;				}
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
" ;	
			}
			flood_results <-  text;
				
			write langs_def at 'MSG_FLOODED_AREA_DISTRICT' at configuration_file["LANGUAGE"];
			ask ((District where (each.id > 0)) sort_by (each.id)){
				surface_inondee <- (U_0_5c + U_1c + U_maxc + Us_0_5c + Us_1c + Us_maxc + AU_0_5c + AU_1c + AU_maxc + N_0_5c + N_1c + N_maxc + A_0_5c + A_1c + A_maxc) with_precision 1 ;
					add surface_inondee to: data_surface_inondee; 
					write ""+ district_name + " : " + surface_inondee +" ha";

					totU <- (U_0_5c + U_1c + U_maxc) with_precision 1 ;
					totUs <- (Us_0_5c + Us_1c + Us_maxc ) with_precision 1 ;
					totUdense <- (Udense_0_5c + Udense_1c + Udense_maxc) with_precision 1 ;
					totAU <- (AU_0_5c + AU_1c + AU_maxc) with_precision 1 ;
					totN <- (N_0_5c + N_1c + N_maxc) with_precision 1 ;
					totA <-  (A_0_5c + A_1c + A_maxc) with_precision 1 ;	
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
		create Buttons{
			nb_button <- 0;					label 	 <- "One step";
			shape <- square(button_size);	location <- { 1000,1000 };
			my_icon <- image_file("../images/icones/one_step.png");
		}
		create Buttons{
			nb_button <- 3; 				label	 <- "HIGH_FLOODING";
			shape <- square(button_size);	location <- { 5000,1000 };
			my_icon <- image_file("../images/icones/launch_lisflood.png");
		}
		create Buttons{
			nb_button <- 5;					label	 <- "LOW_FLOODING";
			shape <- square(button_size);	location <- { 7000,1000 };
			my_icon <- image_file("../images/icones/launch_lisflood_small.png");
		}
		create Buttons{
			nb_button <- 6;					label 	 <- "Replay flooding";
			shape <- square(button_size);	location <- { 9000,1000 };
			my_icon <- image_file("../images/icones/replay_flooding.png");
		}
		create Buttons{
			nb_button <- 4;					label 	 <- "Show UA grid";
			shape <- square(850);			location <- { 800,14000 };
			my_icon <- image_file("../images/icones/sans_quadrillage.png");
			is_selected <- false;
		}
		create Buttons{
			nb_button <- 7;					label	 <- "Show max water height";
			shape <- square(850);			location <- { 1800,14000 };
			my_icon <- image_file("../images/icones/max_water_height.png");
			is_selected <- false;
		}
	}
	
	//clearing buttons selection
    action clear_selected_button{	ask Buttons{	self.is_selected <- false;	}	}
	
	// the four buttons of game master control display 
    action button_click_master_control{
		point loc <- #user_location;
		list<Buttons> buttonsMaster <- ( Buttons where (each distance_to loc < MOUSE_BUFFER));
		if(length(buttonsMaster) > 0){
			do clear_selected_button;
			ask(buttonsMaster){
				is_selected <- true;
				switch nb_button 	{
					match 		0   { 							ask world {	do new_round;		    } }
					match_one [3, 5]{ floodEventType <- label;	ask world { do launchFlood_event;   } }
					match 6			{ 							ask world { do replay_flood_event();} }
				}
			}
		}
	}
	
	// the two buttons of the first map display
	action button_click_map {
		point loc <- #user_location;
		Buttons a_button <- first((Buttons where (each distance_to loc < MOUSE_BUFFER)));
		if a_button != nil{
			ask a_button{
				is_selected <- not(is_selected);
				if(a_button.nb_button = 4){
					my_icon		<-  is_selected ? image_file("../images/icones/avec_quadrillage.png") : image_file("../images/icones/sans_quadrillage.png");
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
//------------------------------ End of global -------------------------------//

//---------------------------- Species definiton -----------------------------//
 
species Data_retreive skills:[network] schedules:[] { // Receiving and applying players actions
	init {
		write langs_def at 'MSG_START_SENDER' at configuration_file["LANGUAGE"];
		do connect to:SERVER with_name:GAME_MANAGER+"_retreive";
	}
	
	action send_data_to_district (District m){
		write "" + langs_def at 'MSG_SEND_DATA_TO' at configuration_file["LANGUAGE"] +" "+ m.network_name;
		ask m {	do send_player_district_update(); }
		do retreive_coastal_defense(m);
		do retreive_LU(m);
		do retreive_action_done(m);
		do retreive_activated_lever(m);
	}
	
	action retreive_coastal_defense(District m){	
		loop tmp over: Coastal_defense where(each.district_code = m.district_code){
			write "" + langs_def at 'MSG_SEND_TO' at configuration_file["LANGUAGE"] +" "+ m.network_name + "_retreive " + tmp.build_map_from_attributes();
			do send to: m.network_name+"_retreive" contents: tmp.build_map_from_attributes();
		}
	}
	
	action retreive_LU(District m){
		loop tmp over: m.UAs{
			write "" + langs_def at 'MSG_SEND_TO' at configuration_file["LANGUAGE"] + " " + m.network_name + "_retreive " + tmp.build_map_from_attributes();
			do send to: m.network_name+"_retreive" contents: tmp.build_map_from_attributes();
		}
	}

	action retreive_action_done(District m){
		loop tmp over: Action_done where(each.district_code = m.district_code){
			write "" + langs_def at 'MSG_SEND_TO' at configuration_file["LANGUAGE"] + " " + m.network_name+ "_retreive " + tmp.build_map_from_attributes();
			do send to: m.network_name+"_retreive" contents: tmp.build_map_from_attributes();
		}
	}
	
	action retreive_activated_lever(District m){
		loop tmp over: Activated_lever where(each.district_code = m.district_code) {
			write "" + langs_def at 'MSG_SEND_TO' at configuration_file["LANGUAGE"] + " " + m.network_name + "_retreive " + tmp.build_map_from_attributes();
			do send to: m.network_name+"_retreive" contents: tmp.build_map_from_attributes();
		}
	}
	
	action lock_window(District m, bool are_allowed){
		string val <- are_allowed=true?"UN_LOCKED":"LOCKED";
		map<string,string> me <- ["OBJECT_TYPE"::"lock_unlock",
								  "WINDOW_STATUS"::val];
		do send to: m.network_name+"_retreive" contents: me;
	}
}
//------------------------------ End of Data_retrieve -------------------------------//

species Action_done schedules:[]{
	string id;
	int element_id;
	geometry element_shape;
	string district_code<-"";
	bool not_updated <- false;
	int command <- -1 on_change: {label <- world.labelOfAction(command);};
	int command_round<- -1;
	string label <- "no name";
	int initial_application_round <- -1;
	int round_delay -> {activated_levers sum_of (each.nb_rounds_delay)} ; // nb rounds of delay
	int actual_application_round -> {initial_application_round+round_delay};
	bool is_delayed ->{round_delay>0} ;
	float cost <- 0.0;
	int added_cost -> {activated_levers sum_of (each.added_cost)} ;
	float actual_cost -> {cost+added_cost};
	bool has_added_cost ->{added_cost>0} ;
	bool is_sent <-true;
	bool is_sent_to_leader <-false;
	bool is_applied <- false;
	bool should_be_applied ->{round >= actual_application_round} ;
	string action_type <- DIKE ; //can be "dike" or "PLU"
	string previous_lu_name <-"";  // for PLU action
	bool isExpropriation <- false; // for PLU action
	bool inProtectedArea <- false; // for dike action
	bool inCoastBorderArea <- false; // for PLU action // c'est la bande des 400 m par rapport au trait de cote
	bool inRiskArea <- false; // for PLU action / Ca correspond à la zone PPR qui est un shp chargé
	bool isInlandDike <- false; // for dike action // ce sont les rétro-digues
	bool is_alive <- true;
	list<Activated_lever> activated_levers <-[];
	bool shouldWaitLeaderToActivate <- false;
	int length_def_cote<-0;
	bool a_lever_has_been_applied<- false;
	
	
	map<string,string> build_map_from_attributes{
		map<string,string> res <- ["OBJECT_TYPE"::"action_done", "id"::id, "element_id"::string(element_id),
			"district_code"::district_code, "command"::string(command), "label"::label, "cost"::string(cost),
			"initial_application_round"::string(initial_application_round), "isInlandDike"::string(isInlandDike),
			"inRiskArea"::string(inRiskArea), "inCoastBorderArea"::string(inCoastBorderArea), "isExpropriation"::string(isExpropriation),
			"inProtectedArea"::string(inProtectedArea), "previous_lu_name"::previous_lu_name, "action_type"::action_type,
			"locationx"::string(location.x), "locationy"::string(location.y), "is_applied"::string(is_applied), "is_sent"::string(is_sent),
			"command_round"::string(command_round), "element_shape"::string(element_shape), "length_def_cote"::string(length_def_cote),
			"a_lever_has_been_applied"::string(a_lever_has_been_applied)];
			int i <- 0;
			loop pp over:element_shape.points{
				put string(pp.x) key: "locationx"+i in: res;
				put string(pp.y) key: "locationy"+i in: res;
				i <- i + 1;
			}
		return res;
	}
	
	aspect base{
		int indx <- Action_done index_of self;
		float y_loc <- float((indx +1)  * font_size) ;
		float x_loc <- float(font_interleave + 12* (font_size+font_interleave));
		float x_loc2 <- float(font_interleave + 20* (font_size+font_interleave));
		shape <- rectangle({font_size+2*font_interleave,y_loc},{x_loc2,y_loc+font_size/2} );
		draw shape color:#white;
		string txt <-  ""+world.table_correspondance_insee_com_nom_rac at (district_code)+": "+ label;
		txt <- txt +" ("+string(initial_application_round-round)+")"; 
		draw txt at:{font_size+2*font_interleave,y_loc+font_size/2} size:font_size#m color:#black;
		draw "    "+ round(cost) at:{x_loc,y_loc+font_size/2} size:font_size#m color:#black;	
	}
	
	Coastal_defense create_dike(Action_done act){
		int next_dike_id <- max(Coastal_defense collect(each.dike_id))+1;
		create Coastal_defense number:1 returns:new_dikes{
			dike_id <- next_dike_id;
			district_code <- act.district_code;
			shape <- act.element_shape;
			location <- act.location;
			type <- BUILT_DIKE_TYPE ;
			status <- BUILT_DIKE_STATUS;
			height <- BUILT_DIKE_HEIGHT;	
			cells <- cell overlapping self;
		}
		act.element_id <- first(new_dikes).dike_id;
		return first(new_dikes);
	}
}
//------------------------------ End of Action_done -------------------------------//

species Network_player skills:[network]{
	
	init{	do connect to: SERVER with_name: GAME_MANAGER;	}
	
	reflex wait_message when: activemq_connect{
		loop while: has_more_message(){
			message msg <- fetch_message();
			string m_sender <- msg.sender;
			map<string, unknown> m_contents <- msg.contents;
			if(m_sender!= GAME_MANAGER ){
				if(m_contents["stringContents"] != nil){
					write "" +langs_def at 'MSG_READ_MESSAGE' at configuration_file["LANGUAGE"] + " : " + m_contents["stringContents"];
					list<string> data <- string(m_contents["stringContents"]) split_with COMMAND_SEPARATOR;
					if(int(data[0]) = CONNECTION_MESSAGE){
						int idCom <- world.district_id (m_sender);
						ask(District where(each.id = idCom)){
							do inform_current_round;
							do send_player_district_update;
						}
						write "" + langs_def at 'MSG_CONNECTION_FROM' at configuration_file["LANGUAGE"] + " " + m_sender + " " + idCom;
					}
					else{
						if(int(data[0]) = REFRESH_ALL){
							int idCom <- world.district_id(m_sender);
							write " Update ALL !!!! " + idCom + " ";
							District cm <- first(District where(each.id=idCom));
							ask first(Data_retreive) {
								do send_data_to_district(cm);
							}
						}
						else{
							if(round > 0) {
								write "" + langs_def at 'MSG_READ_ACTION' at configuration_file["LANGUAGE"]+ " " + m_contents["stringContents"];
								do read_action(string(m_contents["stringContents"]),m_sender);
							}
						}
					}
				}
				else{	map<string,unknown> data <- m_contents["objectContent"];	}				
			}					
		}
	}
		
	action read_action(string act, string sender){
		list<string> data <- act split_with COMMAND_SEPARATOR;
		
		if(! (int(data[0]) in ACTION_LIST) ){	return;	}
		
		create Action_done returns: tmp_agent_list;
		Action_done new_action <- first(tmp_agent_list);
		ask(new_action){
			self.command <- int(data[0]);
			self.command_round <-round; 
			self.id <- data[1];
			self.initial_application_round <- int(data[2]);
			self.district_code <- sender;
			if !(self.command in [REFRESH_ALL]){
				self.element_id <- int(data[3]);
				self.action_type <- data[4];
				self.inProtectedArea <- bool(data[5]);
				self.previous_lu_name <- data[6];
				self.isExpropriation <- bool(data[7]);
				self.cost <- float(data[8]);
				if command = ACTION_CREATE_DIKE{
					point ori <- {float(data[9]),float(data[10])};
					point des <- {float(data[11]),float(data[12])};
					point loc <- {float(data[13]),float(data[14])}; 
					shape <- polyline([ori,des]);
					element_shape <- polyline([ori,des]);
					length_def_cote <- int(element_shape.perimeter);
					location <- loc; 
				}
				else {
					if isExpropriation {	write "" + langs_def at 'MSG_EXPROPRIATION_TRIGGERED' at configuration_file["LANGUAGE"]+" "+self.id;	}
					switch self.action_type {
						match "PLU" {
							Land_use tmp <- (Land_use first_with(each.id = self.element_id));
							element_shape <- tmp.shape;
							location <- tmp.location;
						}
						match DIKE {
							element_shape <- (Coastal_defense first_with(each.dike_id = self.element_id)).shape;
							length_def_cote <- int(element_shape.perimeter);
						}
						default {	write ""+langs_def at 'MSG_ERROR_ACTION_DONE' at configuration_file["LANGUAGE"];	}
					}
				}
				// calcul des attributs qui n'ont pas été calculé au niveau de Participatif et qui ne sont donc pas encore renseigné
				//inCoastBorderArea  // for PLU action // c'est la bande des 400 m par rapport au trait de cote
				//inRiskArea  // for PLU action / Ca correspond à la zone PPR qui est un shp chargé
				//isInlandDike  // for dike action // ce sont les rétro-digues
				if  self.element_shape intersects all_flood_risk_area {	inRiskArea <- true;	}
				if  self.element_shape intersects first(Coast_border_area) {	inCoastBorderArea <- true;	}
				if command = ACTION_CREATE_DIKE and (self.element_shape.centroid overlaps first(Inland_dike_area))	{	isInlandDike <- true;	}
				// finallement on recalcul aussi inProtectedArea meme si ca a été calculé au niveau de participatif, car en fait ce n'est pas calculé pour toutes les actions 
				if  self.element_shape intersects all_protected_area {	inProtectedArea <- true;	}
				if(log_user_action){ save ([string(machine_time-EXPERIMENT_START_TIME),self.district_code]+data) to:log_export_filePath rewrite: false type:"csv"; }
			}
		}
		//  le paiement est déjà fait coté commune, lorsque le joueur a validé le panier. On renregistre ici le paiement pour garder les comptes à jour coté serveur
		int idCom <- world.district_id(new_action.district_code);
		ask District first_with(each.id = idCom) {	do record_payment_for_action_done(new_action);	}
	}
	
	reflex update_UA  when:length(Land_use where(each.not_updated))>0 {
		list<string> update_messages <-[];
		list<Land_use> updated_UA <- [];
		ask Land_use where(each.not_updated){
			string msg <- ""+ACTION_LAND_COVER_UPDATE+COMMAND_SEPARATOR+world.getMessageID() +COMMAND_SEPARATOR+id+COMMAND_SEPARATOR+self.lu_code+COMMAND_SEPARATOR+self.population+COMMAND_SEPARATOR+self.isEnDensification;
			update_messages <- update_messages + msg;	
			not_updated <- false;
			updated_UA <- updated_UA + self;
		}
		int i <- 0;
		loop while: i< length(update_messages){
			string msg <- update_messages at i;
			list<District> cms <- District overlapping (updated_UA at i);
			loop cm over:cms{	do send to:cm.network_name contents:msg;	}
			i <- i + 1;
		}
	}
	
	action send_destroy_dike_message(Coastal_defense a_dike){
		string msg <- ""+ACTION_DIKE_DROPPED+COMMAND_SEPARATOR+world.getMessageID() +COMMAND_SEPARATOR+a_dike.dike_id;
		list<District> cms <- District overlapping a_dike;
		loop cm over:cms{	do send to:cm.network_name contents:msg;	}
	}
	
	action send_created_dike(Coastal_defense new_dike, Action_done act){
		new_dike.shape <- act.element_shape;
		point p1 <- first(act.element_shape.points);
		point p2 <- last(act.element_shape.points);
		string msg <- ""+ACTION_DIKE_CREATED+COMMAND_SEPARATOR+world.getMessageID() +
		COMMAND_SEPARATOR+new_dike.dike_id+
		COMMAND_SEPARATOR+p1.x+COMMAND_SEPARATOR+p1.y+
		COMMAND_SEPARATOR+p2.x+COMMAND_SEPARATOR+p2.y+
		COMMAND_SEPARATOR+new_dike.height+
		COMMAND_SEPARATOR+new_dike.type+
		COMMAND_SEPARATOR+new_dike.status+ 
		COMMAND_SEPARATOR+min_dike_elevation(new_dike)+
		COMMAND_SEPARATOR+act.id+
		COMMAND_SEPARATOR+new_dike.location.x+
		COMMAND_SEPARATOR+new_dike.location.y;
		list<District> cms <- District overlapping new_dike;
		loop cm over:cms{
			do send  to:cm.network_name contents:msg;
		}
	}
	
	action acknowledge_application_of_action_done (Action_done act){
		map<string,string> msg <- ["TOPIC"::"action_done is_applied",
			"district_code"::act.district_code, "id"::act.id];
		do send to: act.district_code + "_map_msg" contents:msg;
	}
	
	float min_dike_elevation(Coastal_defense ovg){	return min(cell overlapping ovg collect(each.soil_height));	}
	
	reflex update_dike when: length(Coastal_defense where(each.not_updated)) > 0 {
		list<string> update_messages <-[]; 
		list<Coastal_defense> update_ouvrage <- [];
		ask Coastal_defense where(each.not_updated){
			point p1 <- first(self.shape.points);
			point p2 <- last(self.shape.points);
			string msg <- ""+ACTION_DIKE_UPDATE+COMMAND_SEPARATOR+world.getMessageID() +COMMAND_SEPARATOR+self.dike_id+COMMAND_SEPARATOR+p1.x+COMMAND_SEPARATOR+p1.y+COMMAND_SEPARATOR+p2.x+COMMAND_SEPARATOR+p2.y+COMMAND_SEPARATOR+self.height+COMMAND_SEPARATOR+self.type+COMMAND_SEPARATOR+self.status+COMMAND_SEPARATOR+self.ganivelle+COMMAND_SEPARATOR+myself.min_dike_elevation(self);
			update_messages <- update_messages + msg;
			update_ouvrage <- update_ouvrage + self;
			not_updated <- false;
		}
		int i <- 0;
		loop while: i< length(update_messages){
			string msg <- update_messages at i;
			list<District> cms <- District overlapping (update_ouvrage at i);
			loop cm over:cms{	do send to:cm.network_name contents:msg;	}
			i <- i + 1;
		}
	}

	reflex apply_action when: length(Action_done where (each.is_alive)) > 0{
	//	ask(action_done where(each.should_be_applied and each.is_alive and not(each.shouldWaitLeaderToActivate)))
	// Pour une raison bizarre la ligne au dessus ne fonctionne pas alors que les 2 lignes ci dessous fonctionnent. Pourtant je ne vois aucune difference
		ask Action_done {
			if should_be_applied and is_alive and !shouldWaitLeaderToActivate {
				string tmp <- self.district_code;
				int idCom <- world.district_id(tmp);
				Action_done act <- self;
				switch(command){
				match REFRESH_ALL{////  Pourquoi est ce que REFRESH_ALL est une  Action_done ??
					write " Update ALL !!!! " + idCom+ " "+  world.table_correspondance_insee_com_nom_rac at (district_code);
					string dd <- district_code;
					District cm <- first(District where(each.id=idCom));
					ask first(Data_retreive) {	do send_data_to_district(cm);	}
				}
				match ACTION_CREATE_DIKE{	
					Coastal_defense new_dike <- create_dike(act);
					ask Network_player	{
						do send_created_dike(new_dike, act);
						do acknowledge_application_of_action_done(act);
					}
					ask(new_dike){ do build_dike;	 }
				}
				match ACTION_REPAIR_DIKE {
					ask(Coastal_defense first_with(each.dike_id=element_id)){
						do repaire_dike;
						not_updated <- true;
					}
					ask Network_player{	do acknowledge_application_of_action_done(act);	}		
				}
			 	match ACTION_DESTROY_DIKE {
			 		ask(Coastal_defense first_with(each.dike_id=element_id)){
						ask Network_player{
							do send_destroy_dike_message(myself);
							do acknowledge_application_of_action_done(act);
						}
						do destroy_dike;
						not_updated <- true;
					}		
				}
			 	match ACTION_RAISE_DIKE {
			 		ask(Coastal_defense first_with(each.dike_id=element_id)){
						do raise_dike;
						not_updated <- true;
					}
					ask Network_player{	do acknowledge_application_of_action_done(act);	}
				}
				 match ACTION_INSTALL_GANIVELLE {
				 	ask(Coastal_defense first_with(each.dike_id=element_id)){
						do install_ganivelle ;
						not_updated <- true;
					}
					ask Network_player{	do acknowledge_application_of_action_done(act);	}
				}
			 	match ACTION_MODIFY_LAND_COVER_A {
			 		ask Land_use first_with(each.id=element_id){
			 		  do modify_UA (idCom, "A");
			 		  not_updated <- true;
			 		 }
			 		 ask Network_player{ do acknowledge_application_of_action_done(act); }
			 	}
			 	match ACTION_MODIFY_LAND_COVER_AU {
			 		ask Land_use first_with(each.id=element_id){
			 		 	do modify_UA (idCom, "AU");
			 		 	not_updated <- true;
			 		 }
			 		 ask Network_player{ do acknowledge_application_of_action_done(act); }
			 	}
				match ACTION_MODIFY_LAND_COVER_N {
					ask Land_use first_with(each.id=element_id){
			 		 	do modify_UA (idCom, "N");
			 		 	not_updated <- true;
			 		 }
			 		 ask Network_player{ do acknowledge_application_of_action_done(act); }
			 	}
			 	match ACTION_MODIFY_LAND_COVER_Us {
			 		ask Land_use first_with(each.id=element_id){
			 		 	do modify_UA (idCom, "Us");
			 		 	not_updated <- true;
			 		 }
			 		ask Network_player{
						do acknowledge_application_of_action_done(act);
					}
			 	 }
			 	 match ACTION_MODIFY_LAND_COVER_Ui {
			 		ask Land_use first_with(each.id=element_id){
			 		 	do apply_Densification(idCom);
			 		 	not_updated <- true;
			 		 }
			 		ask Network_player{	do acknowledge_application_of_action_done(act);	}
			 	 }
			 	match ACTION_MODIFY_LAND_COVER_AUs {
			 		ask Land_use first_with(each.id=element_id){
			 		 	do modify_UA (idCom, "AUs");
			 		 	not_updated <- true;
			 		 }
			 		ask Network_player{	do acknowledge_application_of_action_done(act);	}
			 	}
				}
			is_alive <- false; 
			is_applied <- true;
			}
		}		
	}
}
//------------------------------ End of Network player -------------------------------//

species Network_round_manager skills:[remoteGUI]{
	list<string> mtitle <- list_flooding_events.keys;
	list<string> mfile <- [];
	string selected_action;
	string choix_simu_temp <- nil;
	string choix_simulation <- "Submersion initiale";
	int mround <-0 update:world.round;
	 
	init{
		do connect to:SERVER;
		do expose variables:["mtitle","mfile"] with_name:"listdata";
		do expose variables:["mround"] with_name:"current_round";
		do listen with_name:"simu_choisie" store_to:"choix_simu_temp";
		do listen with_name:"littosim_command" store_to:"selected_action";
		do update_submersion_list;
	}
	
	action update_submersion_list{
		loop a over:list_flooding_events.keys{
			mtitle <- mtitle + a;
			mfile <- mfile + (list_flooding_events at a)	;
		}
	}
	
	reflex selected_action when:selected_action != nil{
		write "network_round_manager " + selected_action;
		switch(selected_action){
			match "NEW_ROUND" { ask world {	do new_round; }}
			match "LOCK_USERS" { do lock_unlock_window(true) ; }
			match "UNLOCK_USERS" { do lock_unlock_window(false) ;}
			match_one ["HIGH_FLOODING","LOW_FLOODING"] {
				floodEventType <- selected_action ;
				ask world {	do launchFlood_event;	}
			}
		}
		selected_action <- nil;
	}
	
	reflex show_submersion when: choix_simu_temp!=nil{
		write "network_round_manager : "+ langs_def at 'MSG_SIMULATION_CHOICE' at configuration_file["LANGUAGE"] +" " + choix_simu_temp;
		choix_simulation <- choix_simu_temp;
		choix_simu_temp <-nil;
	}
	
	action lock_unlock_window(bool value){
		Data_retreive agt <- first(Data_retreive);
		ask District{	ask agt {	do lock_window(myself,value);	}	}
	}
	
	action add_element(string nom_submersion, string path_to_see){	do update_submersion_list;	}
}
//------------------------------ End of Network_round_manager -------------------------------//

species Activated_lever {
	Action_done act_done;
	float activation_time;
	bool applied <- false;
	
	//attributes sent through network
	int id;
	string district_code;
	string lever_type;
	string lever_explanation <- "";
	string act_done_id <- "";
	int nb_rounds_delay <-0;
	int added_cost <- 0;
	int round_creation;
	int round_application;
	
	action init_from_map(map<string, string> m ){
		id <- int(m["id"]);
		lever_type <- m["lever_type"];
		district_code <- m["district_code"];
		act_done_id <- m["act_done_id"];
		added_cost <- int(m["added_cost"]);
		nb_rounds_delay <- int(m["nb_rounds_delay"]);
		lever_explanation <- m["lever_explanation"];
		round_creation <- int(m["round_creation"]);
		round_application <- int(m["round_application"]);
	}
	
	map<string,string> build_map_from_attributes{
		map<string,string> res <- [
			"OBJECT_TYPE"::"activated_lever",
			"id"::id,
			"lever_type"::lever_type,
			"district_code"::district_code,
			"act_done_id"::act_done_id,
			"added_cost"::added_cost,
			"nb_rounds_delay"::nb_rounds_delay,
			"lever_explanation"::lever_explanation,
			"round_creation"::round_creation,
			"round_application"::round_application]	;
		return res;
	}
}
//------------------------------ End of Activated_lever -------------------------------//

species Network_activated_lever skills:[network]{
	
	init{	do connect to:SERVER with_name:"activated_lever";	}
	
	reflex wait_message{
		loop while:has_more_message(){
			message msg <- fetch_message();
			string m_sender <- msg.sender;
			map<string, string> m_contents <- msg.contents;
			if empty(Activated_lever where (each.id = int(m_contents["id"]))){
				create Activated_lever{
					do init_from_map(m_contents);
					act_done <- Action_done first_with (each.id = act_done_id);
					District aCommune <- District first_with (each.district_code = district_code);
					aCommune.budget <-aCommune.budget - added_cost; 
					add self to:act_done.activated_levers;
					act_done.a_lever_has_been_applied<- true;
				}
			}			
		}	
	}
}
//------------------------------ End of Network_activated_lever -------------------------------//

species Network_listener_to_leader skills:[network]{
	string PRELEVER <- "Percevoir Recette";
	string CREDITER <- "Subventionner";
	string LEADER_COMMAND <- "leader_command";
	string AMOUNT <- "amount";
	string COMMUNE <- "COMMUNE_ID";
	string ASK_NUM_ROUND <- "Leader demande numero du tour";
	string NUM_ROUND <- "Numero du tour";
	string ASK_INDICATORS_T0 <- "Leader demande Indicateurs a t0";
	string INDICATORS_T0 <- 'Indicateurs a t0';
	string RETREIVE_ACTION_DONE <- "RETREIVE_ACTION_DONE";
	
	init{	do connect to:SERVER with_name:MSG_FROM_LEADER;	}
	
	reflex  wait_message {
		loop while:has_more_message(){
			message msg <- fetch_message();
			map<string, unknown> m_contents <- msg.contents;
			string cmd <- m_contents[LEADER_COMMAND];
			write "command " + cmd;
			switch(cmd){
				match CREDITER{
					string district_code <- m_contents[COMMUNE];
					int amount <- int(m_contents[AMOUNT]);
					District cm <- District first_with(each.district_code=district_code);
					cm.budget <- cm.budget + amount;
				}
				match PRELEVER{
					string district_code <- m_contents[COMMUNE];
					int amount <- int(m_contents[AMOUNT]); 
					District cm <- District first_with(each.district_code=district_code);
					cm.budget <- cm.budget - amount;
				}
				match ASK_NUM_ROUND 		 {	do informLeader_round_number;	}
				match ASK_INDICATORS_T0 	 {	do informLeader_Indicators_t0;	}
				match RETREIVE_ACTION_DONE	 {	ask Action_done {is_sent_to_leader <- false ;	}
				}
				match "action_done shouldWaitLeaderToActivate" {
					Action_done aAct <- Action_done first_with (each.id = string(m_contents["action_done id"]));
					write "msg shouldWait on " + aAct;
					aAct.shouldWaitLeaderToActivate <- bool(m_contents["action_done shouldWaitLeaderToActivate"]);
					write "msg shouldWait value " + aAct.shouldWaitLeaderToActivate;
				}
			}	
		}
	}
	
	action informLeader_round_number {
		map<string,string> msg <- [];
		put NUM_ROUND key: OBSERVER_MESSAGE_COMMAND in:msg ;
		put string(round) key: "num tour" in: msg;
		do send to: GAME_LEADER contents:msg;
	}
				
	action informLeader_Indicators_t0  {
		ask District where (each.id > 0) {
			map<string,string> msg <- [];
			put myself.INDICATORS_T0 key:OBSERVER_MESSAGE_COMMAND in:msg ;
			put district_code key: "district_code" in: msg;
			put string(length_dikes_t0) key: "length_dikes_t0" in: msg;
			put string(length_dunes_t0) key: "length_dunes_t0" in: msg;
			put string(count_UA_urban_t0) key: "count_UA_urban_t0" in: msg;
			put string(count_UA_UandAU_inCoastBorderArea_t0) key: "count_UA_UandAU_inCoastBorderArea_t0" in: msg;
			put string(count_UA_urban_infloodRiskArea_t0) key: "count_UA_urban_infloodRiskArea_t0" in: msg;
			put string(count_UA_urban_dense_infloodRiskArea_t0) key: "count_UA_urban_dense_infloodRiskArea_t0" in: msg;
			put string(count_UA_urban_dense_inCoastBorderArea_t0) key: "count_UA_urban_dense_inCoastBorderArea_t0" in: msg;
			put string(count_UA_A_t0) key: "count_UA_A_t0" in: msg;
			put string(count_UA_N_t0) key: "count_UA_N_t0" in: msg;
			put string(count_UA_AU_t0) key: "count_UA_AU_t0" in: msg;
			put string(count_UA_U_t0) key: "count_UA_U_t0" in: msg;
			ask myself {do send to:GAME_LEADER contents:msg;}
		}		
	}
	
	reflex send_action_state when: cycle mod 10 = 0{
		loop act_done over: Action_done where (!each.is_sent_to_leader){
			map<string,string> msg <- act_done.build_map_from_attributes();
			put UPDATE_ACTION_DONE key: OBSERVER_MESSAGE_COMMAND in: msg ;
			do send to: GAME_LEADER contents: msg;
			act_done.is_sent_to_leader <- true;
			write "" + langs_def at 'MSG_SEND_MSG_LEADER' at configuration_file["LANGUAGE"] +" : "+ msg;
		}
	}
}
//------------------------------ End of Network_listener_to_leader -------------------------------//

grid cell file: dem_file schedules:[] neighbors: 8 {	
	int cell_type <- 0 ; // 0 = land
	float water_height  <- 0.0;
	float max_water_height  <- 0.0;
	float soil_height <- grid_value;
	float soil_height_before_broken <- soil_height;
	float rugosity;
	rgb soil_color ;

	init {
		if soil_height <= 0 {	cell_type 	<-1;		}  //  1 = sea
		if soil_height = 0 	{	soil_height <- -5.0;	}
		do init_soil_color();
	}
	
	action init_soil_color{
		if cell_type = 1 {
			float tmp <-  ((soil_height  / 10) with_precision 1) * -170;
			soil_color<- rgb( 80, 80 , int(255 - tmp)) ;
		}else{
			float tmp <-  ((soil_height  / 10) with_precision 1) * 255;
			soil_color<- rgb( int(255 - tmp), int(180 - tmp) , 0) ;
		}
	}
	
	aspect water_level{
		if water_height < 0			{ color<-#red;	}
		else if water_height <= 0.01{ color<-#white;}
		else						{ color<- rgb( 0, 0 , int(255 - ( ((water_height  / 8) with_precision 1) * 255)));}
	}
	
	aspect water_elevation{
		if(cell_type != 1 and water_height != 0){ color <- world.color_of_water_height(water_height); }
		else 									{ color <- soil_color ;	}
	}
		
	aspect water_or_max_water_elevation{
		if cell_type = 1 or (show_max_water_height? (max_water_height = 0) : (water_height = 0)){
			color<- soil_color ;
		}else{
			if show_max_water_height {	color <- world.color_of_water_height(max_water_height);	}
			else					 {	color <- world.color_of_water_height(water_height);		}
		}
	}
}
//------------------------------ End of grid -------------------------------//

species Coastal_defense {	
	int dike_id;
	string district_code;
	string type;
	string status;	//  "Good" "Medium" "Bad"  
	float height;
	float alt; 
	rgb color <- # pink;
	list<cell> cells ;
	int cptStatus <-0;
	int rupture<-0;
	geometry zoneRupture<-nil;
	bool not_updated <- false;
	bool ganivelle <- false;
	float height_avant_ganivelle;
	string type_def_cote -> {type};
	
	action init_from_map(map<string, unknown> a ){
		self.dike_id <- int(a at "dike_id");
		self.type <- string(a at "type");
		self.status <- string(a at "status");
		self.height <- float(a at "height");
		self.alt <- float(a at "alt");
		self.cptStatus <- int(a at "cptStatus");
		self.rupture <- int(a at "rupture");
		self.zoneRupture <- a at "zoneRupture";
		self.not_updated <- bool(a at "not_updated");
		self.ganivelle <- bool(a at "ganivelle");
		self.height_avant_ganivelle <- float(a at "height_avant_ganivelle");
		point pp<-{float(a at "locationx"), float(a at "locationy")};
		point mpp <- pp;
		int i <- 0;
		list<point> all_points <- [];
		loop while: (pp!=nil){
			string xd <- a at ("locationx"+i);
			if(xd != nil){
				pp <- {float(xd), float(a at ("locationy"+i))  };
				all_points <- all_points + pp;
			}
			else{
				pp<-nil;
			}
			i<- i + 1;
		}
		shape <- polyline(all_points);
		location <-mpp;
	}
	
	map<string,unknown> build_map_from_attributes{
		map<string,unknown> res <- [
			"OBJECT_TYPE"::"COAST_DEF",	"dike_id"::string(dike_id),	"type"::type, "status"::status,
			"height"::string(height), "alt"::string(alt), "rupture"::string(rupture), "zoneRupture"::zoneRupture,
			"not_updated"::string(not_updated), "ganivelle"::string(ganivelle), "height_avant_ganivelle"::string(height_avant_ganivelle),
			"locationx"::string(location.x), "locationy"::string(location.y)];
			int i <- 0;
			loop pp over:shape.points{
				put string(pp.x) key:"locationx"+i in: res;
				put string(pp.y) key:"locationy"+i in: res;
				i <- i+ 1;
			}
		return res;
	}
	
	action init_dike {
		if status = ""  {status <- STATUS_GOOD; } 
		if type ='' 	{type <- "Unknown";		}
		if height = 0.0 {height  <- 1.5;		} // if no height, 1.5 m by default
		cptStatus <- type = DUNE ?rnd(STEPS_DEGRAD_STATUS_DUNE-1) : rnd(STEPS_DEGRAD_STATUS_OUVRAGE-1);
		cells <- cell overlapping self;
		if type = DUNE  {height_avant_ganivelle <- height;}
	}
	
	action evolveStatus_ouvrage {
		cptStatus <- cptStatus +1;
		if cptStatus = (STEPS_DEGRAD_STATUS_OUVRAGE + 1) {
			cptStatus <-0;
			if status = STATUS_MEDIUM {status <- STATUS_BAD;}
			if status = STATUS_GOOD {status <- STATUS_MEDIUM;}
			not_updated<-true; 
		}
	}

	action evolve_dune {
		if ganivelle {
			// a dune with a ganivelle
			cptStatus <- cptStatus +1;
			if cptStatus = (STEPS_REGAIN_STATUS_GANIVELLE + 1) {
				cptStatus <-0;
				if status = STATUS_MEDIUM {status <- STATUS_GOOD;}
				if status = STATUS_BAD {status <- STATUS_MEDIUM;}
				not_updated <- true; 
			}
			if height < height_avant_ganivelle + H_MAX_GANIVELLE {
				height <- height + H_DELTA_GANIVELLE;  // la ganivelle permet d'augmenter de 5 cm par an dans la limite de h_ganivelle
				alt <- alt + H_DELTA_GANIVELLE;
				ask cells {
					soil_height <- soil_height + H_DELTA_GANIVELLE;
					soil_height_before_broken <- soil_height ;
					do init_soil_color();
				}
				not_updated <- true;
			}
			else { // if the dune covers all the ganivelle we reset the ganivelle
				ganivelle <- false;
				not_updated<- true;
			}
		}
		else {
			// a dune without a ganivelle
			cptStatus <- cptStatus +1;
			if cptStatus = (STEPS_DEGRAD_STATUS_DUNE + 1) {
				cptStatus   <-0;
				if status = STATUS_MEDIUM {status <- STATUS_BAD;}
				if status = STATUS_GOOD   {status <- STATUS_MEDIUM;}
				not_updated <-true;  
			}
		}
	}
		
	action calcRupture {
		int p <- 0;
		if type != DUNE and status = STATUS_BAD 	{p <- PROBA_RUPTURE_DIKE_STATUS_BAD;	}
		if type != DUNE and status = STATUS_MEDIUM  {p <- PROBA_RUPTURE_DIKE_STATUS_MEDIUM; }
		if type != DUNE and status = STATUS_GOOD	{p <- PROBA_RUPTURE_DIKE_STATUS_GOOD;	}
		if type = DUNE and status = STATUS_BAD 		{p <- PROBA_RUPTURE_DUNE_STATUS_BAD;	}
		if type = DUNE and status = STATUS_MEDIUM 	{p <- PROBA_RUPTURE_DUNE_STATUS_MEDIUM; }
		if type = DUNE and status = STATUS_GOOD 	{p <- PROBA_RUPTURE_DUNE_STATUS_GOOD;	}
		if rnd (100) <= p {
			rupture <- 1;
			// the rupture is applied in the middle
			int cIndex <- int(length(cells) /2);
			// rupture area is about RADIUS_RUPTURE m arount rupture point 
			zoneRupture <- circle(RADIUS_RUPTURE#m,(cells[cIndex]).location);
			// rupture is applied on relevant area cells
			ask cells overlapping zoneRupture  {	if soil_height >= 0 {soil_height <- max([0,soil_height - myself.height]);} }
			write "rupture "+type_def_cote+" n°" + dike_id + "("+", status " + status +", height "+height+", alt "+alt +")";
			write "rupture "+type_def_cote+" n°" + dike_id + "("+ world.table_correspondance_insee_com_nom_rac at (district_code)+", status " + status +", height "+height+", alt "+alt +")";
		}
	}
	
	action removeRupture {
		rupture <- 0;
		ask cells overlapping zoneRupture {if soil_height >= 0 {soil_height <- soil_height_before_broken;}}
		zoneRupture <- nil;
	}
	
	action repaire_dike {
		status <- STATUS_GOOD;
		cptStatus <- 0;
	}

	action raise_dike {
		status <- STATUS_GOOD;
		cptStatus <- 0;
		height <- height + RAISE_DIKE_HEIGHT; // le réhaussement d'ouvrage est défini par 
		alt <- alt + RAISE_DIKE_HEIGHT;
		ask cells {
			soil_height <- soil_height + RAISE_DIKE_HEIGHT;
			soil_height_before_broken <- soil_height ;
			do init_soil_color();
		}
	}
	
	action destroy_dike {
		ask cells {
			soil_height <- soil_height - myself.height ;
			soil_height_before_broken <- soil_height ;
			do init_soil_color();
		}
		do die;
	}
	
	action build_dike {
		///  Une nouvelle digue réhausse tout le terrain à la hauteur de la cell la plus haute
		float h <- cells max_of (each.soil_height);
		alt <- h + height;
		ask cells  {
			soil_height <- h + myself.height; ///  Une nouvelle digue fait 1,5 mètre -> STANDARD_DIKE_SIZE
			soil_height_before_broken <- soil_height ;
			do init_soil_color();
		}
	}
	
	//La commune installe des ganivelles sur la dune
	action install_ganivelle{
		if status = STATUS_BAD {	cptStatus <- 2;	}
		else				   {	cptStatus <- 0; }		
		ganivelle <- true;
		write "INSTALL GANIVELLE";
	}
	
	aspect base{  	
		if type = DUNE {
			switch status {
				match STATUS_GOOD	{	color <- rgb (222, 134, 14,255);	}
				match STATUS_MEDIUM {	color <-  rgb (231, 189, 24,255);	} 
				match STATUS_BAD 	{	color <- rgb (241, 230, 14,255);	} 
				default				{	write langs_def at 'MSG_DUNE_STATUS_PROBLEM' at configuration_file["LANGUAGE"];	}
			}
			draw 50#m around shape color: color;
			if ganivelle {	loop i over: points_on(shape, 40#m) {draw circle(10,i) color: #black;}	} 
		} else{
			switch status {
				match STATUS_GOOD	{	color <- # green;			}
				match STATUS_MEDIUM {	color <-  rgb (255,102,0);	} 
				match STATUS_BAD 	{	color <- # red;				} 
				default {	write langs_def at 'MSG_DIKE_STATUS_PROBLEM' at configuration_file["LANGUAGE"];	}
			}
			draw 20#m around shape color: color size:300#m;
		}
		if(rupture = 1){
			list<point> pts <- shape.points;
			point tmp <- length(pts) > 2?pts[int(length(pts)/2)]:shape.centroid;
			draw image_file("../images/icones/rupture.png") at:tmp size:30#px;
		}	
	}
}
//------------------------------ End of Coastal defense -------------------------------//

species Land_use {
	int id;
	string lu_name;
	int lu_code;
	rgb my_color <- cell_color() update: cell_color();
	int nb_stepsForAU_toU <-1;// On doit mettre 1 pour en fait obtenir un délai de 3 ans (car il y a un tour décompté de chgt de A/N à AU et un autre de AU à U 
	int AU_to_U_counter <- 0;
	list<cell> cells ;
	int population ;
	string classe_densite -> {population =0? POP_EMPTY :(population < 40 ? POP_FEW_DENSITY:(population < 80 ? POP_MEDIUM_DENSITY : POP_DENSE))};
	int cout_expro -> {round( population * 400* population ^ (-0.5))};
	bool isUrbanType -> {lu_name in ["U","Us","AU","AUs"] };
	bool isAdapte -> {lu_name in ["Us","AUs"]};
	bool isEnDensification <- false;
	bool not_updated <- false;
	bool pop_updated <- false;
	
	action init_from_map(map<string, unknown> a ){
		self.id <- int(a at "id");
		self.lu_name <- string(a at "lu_name");
		self.nb_stepsForAU_toU <- int(a at "nb_stepsForAU_toU");
		self.AU_to_U_counter <- int(a at "AU_to_U_counter");
		self.population <- int(a at "population");
		self.isEnDensification <- bool(a at "isEnDensification");
		self.not_updated <- bool(a at "not_updated");
		self.pop_updated <- bool(a at "pop_updated");
		
		point pp<-{float(a at "locationx"), float(a at "locationy")};
		point mpp <- pp;
		int i <- 0;
		list<point> all_points <- [];
		loop while: (pp!=nil){
			string xd <- a at ("locationx"+i);
			if(xd != nil){
				pp <- {float(xd), float(a at ("locationy"+i))  };
				all_points <- all_points + pp;
			}
			else{	pp<-nil;	}
			i<- i + 1;
		}
		shape <- polygon(all_points);
		location <-mpp;
	}
	
	map<string,unknown> build_map_from_attributes{
		map<string,string> res <- [
			"OBJECT_TYPE"::"LU",		"id"::string(id),	"lu_name"::lu_name,
			"lu_code"::string(lu_code),	"nb_stepsForAU_toU"::string(nb_stepsForAU_toU),
			"AU_to_U_counter"::string(AU_to_U_counter),	"population"::string(population),
			"isEnDensification"::string(isEnDensification),	"not_updated"::string(not_updated),
			"pop_updated"::string(pop_updated), "locationx"::string(location.x), "locationy"::string(location.y)];

			int i <- 0;
			loop pp over:shape.points{
				put string(pp.x) key:"locationx"+i in: res;
				put string(pp.y) key:"locationy"+i in: res;
				i<-i+1;
		}
		return res;
	}
	
	string nameOfUAcode (int a_lu_code) {
		switch (a_lu_code){
			match 1 {return "N";  }
			match 2 {return "U";  }
			match 4 {return "AU"; }
			match 5 {return "A";  }
			match 6 {return "Us"; }
			match 7 {return "AUs";}
		}
	}
		
	int codeOfUAname (string a_lu_name) {
		switch (a_lu_name){
			match "N" 	{return 1;}
			match "U" 	{return 2;}
			match "AU" 	{return 4;}
			match "A"	{return 5;}
			match "Us" 	{return 6;}
			match "AUs" {return 7;}
		}
	}
		
	action modify_UA (int a_id_commune, string new_lu_name){
		if  (lu_name in ["U","Us"])and new_lu_name = "N" /*expropriation */ {population <-0;}
		lu_name <- new_lu_name;
		lu_code <- codeOfUAname(lu_name);
		
		//on affecte la rugosité correspondant aux cells
		float rug <- rugosityValueOfUA_name (lu_name);
		ask cells {rugosity <- rug;} 	
	}
	
	action apply_Densification (int a_id_commune) {		isEnDensification <-true;	}	
	
	action evolve_AU_to_U{
	if lu_name in ["AU","AUs"]{
		AU_to_U_counter<-AU_to_U_counter+1;
		if AU_to_U_counter = (nb_stepsForAU_toU +1){
			AU_to_U_counter<-0;
			lu_name <- lu_name="AU"?"U":"Us";
			lu_code<-codeOfUAname(lu_name);
			not_updated<-true;
			do assign_pop (POP_FOR_NEW_U);
			}
		}	
	}
	
	action evolve_U_densification {
		if !pop_updated and isEnDensification and (lu_name in ["U","Us"]){
			string previous_d_classe <- classe_densite; 
			do assign_pop (POP_FOR_U_DENSIFICATION);
			if previous_d_classe != classe_densite {isEnDensification <- false;}
		}
	}
		
	action evolve_U_standard {
		if !pop_updated and (lu_name in ["U","Us"]){	do assign_pop (POP_FOR_U_STANDARD);	}
	}	
	
	action assign_pop (int nbPop) {
		if new_comers_still_to_dispatch > 0 {
			population <- population + nbPop;
			new_comers_still_to_dispatch <- new_comers_still_to_dispatch - nbPop;
			not_updated<-true;
			pop_updated <- true;
		}
	}
	
	float rugosityValueOfUA_name (string a_lu_name) {	return float((eval_gaml("RUGOSITY_"+a_lu_name))) ;	}

	rgb cell_color{
		rgb res <- nil;
		switch (lu_name){
			match 	  "N" 					 {res <- #palegreen;} // naturel
			match_one ["U","Us"] { 								 //  urbanisé
				switch classe_densite 		 {
					match POP_EMPTY 		 {res <- #red; 				} // Problem ?
					match POP_FEW_DENSITY	 {res <-  rgb( 150, 150, 150 ); }
					match POP_MEDIUM_DENSITY {res <- rgb( 120, 120, 120 ) ; }
					match POP_DENSE 		 {res <- rgb( 80,80,80 ) ;		}
				}
			}
			match_one ["AU","AUs"]  {res <- # yellow;		 } // to urbanize
			match "A" 				{res <- rgb (225, 165,0);} // agricultural
		}
		return res;
	}

	aspect base{
		draw shape color: my_color;
		if isAdapte			 {	draw "A" color:#black;	}
		if isEnDensification {	draw "D" color:#black;	}
	}
	
	aspect population {
		rgb acolor <- nil;
		switch population {
			 match 0 					{acolor <- # white;  }
			 match_between [1 , 20]  	{acolor <- listC[2]; }
			 match_between [20 , 40]  	{acolor <- listC[3]; }
			 match_between [40 , 60]  	{acolor <- listC[4]; }
			 match_between [60 , 80]  	{acolor <- listC[5]; }
			 match_between [80 , 100] 	{acolor <- listC[6]; }
			 match_between [100 , 4000] {acolor <- listC[7]; }
			 default 					{acolor <- #yellow;  }
		}
		draw shape color: acolor;
	}

	aspect densite_pop {
		rgb acolor <- nil;
		switch classe_densite {
			match POP_EMPTY 		{acolor <- # white; }
			match POP_FEW_DENSITY 	{acolor <- listC[2];} 
			match POP_MEDIUM_DENSITY{acolor <- listC[5];}
			match POP_DENSE 		{acolor <- listC[7];}
			default 				{acolor <- # yellow;}
		}
		draw shape color: acolor;
	}
	
	aspect conditional_outline{
		if (Buttons first_with(each.nb_button=4)).is_selected{	draw shape color: rgb (0,0,0,0) border:#black;	}
	}
}
//------------------------------ End of Land_use -------------------------------//

species District{	
	int id<-0;
	string district_code; 
	string district_name;
	string network_name;
	int budget;
	int received_tax <-0;
	bool subvention_habitat_adapte <- false;
	list<Land_use> UAs ;
	list<cell> cells ;
	float impot_unit  <- float(impot_unit_table at district_name); 
	
	/* init water heights */ 
	float U_0_5c <-0.0;			float U_1c <-0.0;		float U_maxc <-0.0;
	float Us_0_5c <-0.0;		float Us_1c <-0.0;		float Us_maxc <-0.0;
	float Udense_0_5c <-0.0;	float Udense_1c <-0.0;	float Udense_maxc <-0.0;
	float AU_0_5c <-0.0; 		float AU_1c <-0.0;		float AU_maxc <-0.0;
	float A_0_5c <-0.0;			float A_1c <-0.0;		float A_maxc <-0.0;
	float N_0_5c <-0.0;			float N_1c <-0.0;		float N_maxc <-0.0;
	
	float surface_inondee <- 0.0;	list<float> data_surface_inondee <- [];
	float totU <- 0.0;				list<float> data_totU <- [];
	float totUs <- 0.0;				list<float> data_totUs <- [];
	float totUdense <- 0.0;			list<float> data_totUdense <- [];
	float totAU <- 0.0;				list<float> data_totAU <- [];
	float totN <- 0.0;				list<float> data_totN <- [];
	float totA <- 0.0;				list<float> data_totA <- [];

	// Indicateurs calculés par le Modèle à l’initialisation. Lorsque Leader se connecte, le Modèle lui renvoie la valeur de ces indicateurs en même temps
	float length_dikes_t0 <- 0#m; //linéaire de digues existant / commune
	float length_dunes_t0 <- 0#m; //linéaire de dune existant / commune
	int count_UA_urban_t0 <-0; //nombre de cellules de bâtis (U , AU), Us et AUs)
	int count_UA_UandAU_inCoastBorderArea_t0 <-0; //nombre de cellules de bâtis (non adapté) en zone littoral (<400m) ZL
	int count_UA_urban_infloodRiskArea_t0 <-0; //nombre de cellules de bâtis en zone inondable (ZI)
	int count_UA_urban_dense_infloodRiskArea_t0 <-0; //nombre de cellules denses en ZI
	int count_UA_urban_dense_inCoastBorderArea_t0 <-0; //nombre de cellules denses en ZL (zone littoral)
	int count_UA_A_t0 <-0; // nombre de cellule A
	int count_UA_N_t0 <- 0; // nombre de cellul N 
	int count_UA_AU_t0 <- 0; // nombre de cellul AU
	int count_UA_U_t0 <- 0; // nombre de cellul U

	aspect base{	draw shape color:#whitesmoke;	}
	aspect outline{	draw shape color: rgb (0,0,0,0) border:#black;	}
	
	int current_population (District aC){
		return sum(aC.UAs accumulate (each.population));
	}
	
	action inform_current_round {// informs about the current round
		ask Network_player{
			map<string,string> msg <- [
			"TOPIC"::"INFORM_CURRENT_ROUND",
			"district_code"::myself.district_code,
			"round"::round];
			do send to: myself.district_code+"_map_msg" contents: msg;
		}
	}

	action send_player_district_update{// gives the current state of the district when connected
		ask Network_player{
			map<string,string> msg <- [
			"TOPIC"::"DISTRICT_UPDATE",
			"district_code"::myself.district_code,
			"budget"::myself.budget];
			do send to: myself.district_code+"_map_msg" contents: msg;
		}
	}
	
	action inform_new_round {// informs about a new round
		ask Network_player{
			map<string,string> msg <- [
			"TOPIC"::"INFORM_NEW_ROUND",
			"district_code"::myself.district_code];
			do send to: myself.district_code+"_map_msg" contents: msg;
		}
	}
	
	action calculate_indicators_t0 {
		list<Coastal_defense> my_def_cote <- Coastal_defense where(each.district_code = district_code);
		length_dikes_t0 <- my_def_cote where (each.type_def_cote = DIKE) sum_of (each.shape.perimeter);
		length_dunes_t0 <- my_def_cote where (each.type_def_cote = DUNE) sum_of (each.shape.perimeter);
		count_UA_urban_t0 <- length (UAs where (each.isUrbanType));
		count_UA_UandAU_inCoastBorderArea_t0 <- length (UAs where (each.isUrbanType and not(each.isAdapte) and each intersects first(Coast_border_area)));
		count_UA_urban_infloodRiskArea_t0 <- length (UAs where (each.isUrbanType and each intersects all_flood_risk_area));
		count_UA_urban_dense_infloodRiskArea_t0 <- length (UAs where (each.isUrbanType and each.classe_densite = 'dense' and each intersects all_flood_risk_area));
		count_UA_urban_dense_inCoastBorderArea_t0 <- length (UAs where (each.isUrbanType and each.classe_densite = 'dense' and each intersects union(Coast_border_area)));
		count_UA_A_t0 <- length (UAs where (each.lu_name = 'A'));
		count_UA_N_t0 <- length (UAs where (each.lu_name = 'N'));
		count_UA_AU_t0 <- length (UAs where (each.lu_name = 'AU'));
		count_UA_U_t0 <- length (UAs where (each.lu_name = 'U'));
	}
	
	action calcul_taxes {
		received_tax <- int(current_population(self) * impot_unit);
		budget <- budget + received_tax;
		write district_name + "-> impot " + received_tax + " ; budget "+ budget;
	}
	
	action record_payment_for_action_done (Action_done aAction){
		budget <- int(budget - aAction.cost);
	}					
}
//------------------------------ End of District -------------------------------//
	
// generic buttons
species Buttons{
	int command <- -1;
	int nb_button <- 0;
	//string display_name <- "no name";
	string label <- "no name";
	bool is_selected <- false;
	geometry shape <- square(500#m);
	image_file my_icon;
	
	aspect buttons_master {
		if( nb_button in [0,3,5,6]){
			draw shape   color:  #white border: is_selected ? # red : # white;
			draw my_icon size:	 button_size-50#m ;
		}
	}
	
	aspect buttons_map {
		if( nb_button in [4,7]){
			draw shape   color: #white border: is_selected ? # red : # white;
			draw my_icon size:  800#m ;
		}
	}
}

species Road{				aspect base {	draw shape color: rgb (125,113,53);						}	}

species Protected_area{		aspect base {	draw shape color: rgb (185, 255, 185,120) border:#black;}	}

species Flood_risk_area{	aspect base {	draw shape color: rgb (20, 200, 255,120) border:#black;	}	}
// 400 m littoral area
species Coast_border_area{	aspect base {	draw shape color: rgb (20, 100, 205,120) border:#black;	}	}
//100 m coastline inland area to identify retro dikes
species Inland_dike_area{	aspect base {	draw shape color: rgb (100, 100, 205,120) border:#black;}	}

/*
 * ***********************************************************************************************
 *                  		      EXPERIMENT DEFINITION											 *
 * ***********************************************************************************************
 */

experiment LittoSIM_GEN type: gui{
	float minimum_cycle_duration <- 0.5;
	parameter "Log User Actions" 	var:log_user_action <- true;
	parameter "Connect to ActiveMQ" var:activemq_connect<- true;
	
	output {
		display "Map"{
			grid cell;
			species cell 			aspect: water_or_max_water_elevation;
			species District 		aspect: outline;
			species Road 			aspect: base;
			species Coastal_defense aspect: base;
			species Land_use 		aspect: conditional_outline;
			species Buttons 		aspect: buttons_map;
			event [mouse_down] 		action: button_click_map;
		}
		display "Planning"{
			species District 		aspect: base;
			species Land_use 		aspect: base;
			species Road 	 		aspect:base;
			species Coastal_defense aspect:base;
		}
		display "Population density"{	
			species Land_use aspect: densite_pop;
			species Road aspect:base;
			species District aspect: outline;			
		}
		display "Game master control"{
			species Buttons  aspect: buttons_master;
			event mouse_down action: button_click_master_control;
		}			
		display "Budgets" {
			chart "Districts' budgets" type: series {
			 	data (District first_with(each.id =1)).district_name value:districts_budgets[0] color:#red;
			 	data (District first_with(each.id =2)).district_name value:districts_budgets[1] color:#blue;
			 	data (District first_with(each.id =3)).district_name value:districts_budgets[2] color:#green;
			 	data (District first_with(each.id =4)).district_name value:districts_budgets[3] color:#black;			
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
			chart "Dense U Area" type: histogram background: rgb("white") size: {0.31,0.4} position: {0.66, 0}{
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
			chart "Flooded area per district" type: series{
				datalist value: length(District)= 0 ? [0,0,0,0]:[((District first_with(each.id = 1)).data_surface_inondee),
																((District first_with(each.id = 2)).data_surface_inondee),
																((District first_with(each.id = 3)).data_surface_inondee),
																((District first_with(each.id = 4)).data_surface_inondee)]
						color:[#red,#blue,#green,#black] legend:(((District where (each.id > 0)) sort_by (each.id)) collect each.district_name); 			
			}
		}
		display "Flooded U area per district"{
			chart "Flooded U area per district" type: series{
				datalist value:length(District) = 0 ? [0,0,0,0]:[((District first_with(each.id = 1)).data_totU),
																((District first_with(each.id = 2)).data_totU),
																((District first_with(each.id = 3)).data_totU),
																((District first_with(each.id = 4)).data_totU)]
						color:[#red,#blue,#green,#black] legend:(((District where (each.id > 0)) sort_by (each.id)) collect each.district_name); 			
			}
		}
		display "Flooded Us area per district"{
			chart "Flooded Us area per district" type: series{
				datalist value:length(District) = 0 ? [0,0,0,0]:[((District first_with(each.id = 1)).data_totUs),
																((District first_with(each.id = 2)).data_totUs),
																((District first_with(each.id = 3)).data_totUs),
																((District first_with(each.id = 4)).data_totUs)]
						color:[#red,#blue,#green,#black] legend:(((District where (each.id > 0)) sort_by (each.id)) collect each.district_name); 			
			}
		}
		display "Flooded dense U area per district"{
			chart "Flooded dense U area per district" type: series{
				datalist value:length(District) = 0 ? [0,0,0,0]:[((District first_with(each.id = 1)).data_totUdense),
																((District first_with(each.id = 2)).data_totUdense),
																((District first_with(each.id = 3)).data_totUdense),
																((District first_with(each.id = 4)).data_totUdense)]
						color:[#red,#blue,#green,#black] legend:(((District where (each.id > 0)) sort_by (each.id)) collect each.district_name); 			
			}
		}
		display "Flooded AU area per district"{
			chart "Flooded AU area per district" type: series{
				datalist value:length(District) = 0 ? [0,0,0,0]:[((District first_with(each.id = 1)).data_totAU),
																((District first_with(each.id = 2)).data_totAU),
																((District first_with(each.id = 3)).data_totAU),
																((District first_with(each.id = 4)).data_totAU)]
						color:[#red,#blue,#green,#black] legend:(((District where (each.id > 0)) sort_by (each.id)) collect each.district_name); 			
			}
		}
		display "Flooded N area per district"{
			chart "Flooded N area per district" type: series{
				datalist value:length(District) = 0 ? [0,0,0,0]:[((District first_with(each.id = 1)).data_totN),
																((District first_with(each.id = 2)).data_totN),
																((District first_with(each.id = 3)).data_totN),
																((District first_with(each.id = 4)).data_totN)]
						color:[#red,#blue,#green,#black] legend:(((District where (each.id > 0)) sort_by (each.id)) collect each.district_name); 			
			}
		}
		display "Flooded A area per district"{
			chart "Flooded A area per district" type: series{
				datalist value:length(District) = 0 ? [0,0,0,0]:[((District first_with(each.id = 1)).data_totA),
																((District first_with(each.id = 2)).data_totA),
																((District first_with(each.id = 3)).data_totA),
																((District first_with(each.id = 4)).data_totA)]
						color:[#red,#blue,#green,#black] legend:(((District where (each.id > 0)) sort_by (each.id)) collect each.district_name); 			
			}
		}
	}
}
		

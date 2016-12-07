/**
 *  oleronV2
 *  Author: Brice, Etienne, Nico B, Nico M et Fred pour l'instant
 * 
 *  Description: Le projet LittoSim vise à construire un jeu sérieux 
 *  qui se présente sous la forme d’une simulation intégrant à la fois 
 *  un modèle de submersion marine, la modélisation de différents rôles 
 *  d’acteurs agissant sur le territoire (collectivité territoriale, 
 *  association de défense, élu, services de l’Etat...) et la possibilité 
 *  de mettre en place différents scénarios de prévention des submersions
 *  qui seront contrôlés par les utilisateurs de la simulation en 
 *  fonction de leur rôle. 
 */

model oleronV2

global  {

	string SERVER <- "localhost";
	float MOUSE_BUFFER <- 50#m;
	string OBSERVER_NAME <- "model_observer";
	
	string COMMAND_SEPARATOR <- ":";
	string GAME_LEADER_MANAGER <- "GAME_LEADER_MANAGER";
	string MANAGER_NAME <- "model_manager";
	string GROUP_NAME <- "Oleron";  
	string BUILT_DIKE_TYPE <- "nouvelle digue"; // Type de nouvelle digue
	float  STANDARD_DIKE_SIZE <- 1.5#m; ////// hauteur d'une nouvelle digue	
	string BUILT_DIKE_STATUS <- "bon"; // status de nouvelle digue
	string LOG_FILE_NAME <- "log_"+machine_time+"csv";
	float START_LOG <- machine_time; 
	bool log_user_action <- true;
	bool activemq_connect <- false;
	
	string UPDATE_ACTION_DONE <- "update_action_done";
	string OBSERVER_MESSAGE_COMMAND <- "observer_command";
	
	
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
	list<int> ACTION_LIST <- [CONNECTION_MESSAGE,ACTION_MESSAGE,REFRESH_ALL,ACTION_REPAIR_DIKE,ACTION_CREATE_DIKE,ACTION_DESTROY_DIKE,ACTION_RAISE_DIKE,ACTION_INSTALL_GANIVELLE,ACTION_MODIFY_LAND_COVER_AU,ACTION_MODIFY_LAND_COVER_AUs,ACTION_MODIFY_LAND_COVER_A,ACTION_MODIFY_LAND_COVER_U,ACTION_MODIFY_LAND_COVER_Us,ACTION_MODIFY_LAND_COVER_Ui,ACTION_MODIFY_LAND_COVER_N];
	
			
	int ACTION_LAND_COVER_UPDATE<-9;
	int ACTION_DIKE_UPDATE<-10;
	int ACTION_ACTION_DONE_UPDATE<- 101;
	int ACTION_IS_APPLIED<- 1011;
	int INFORM_ROUND <-34;
	int NOTIFY_DELAY <-35;
	int ENTITY_TYPE_CODE_DEF_COTE <-36;
	int ENTITY_TYPE_CODE_UA <-37;
	
	
	//action to acknwoledge client requests.
//	int ACTION_DIKE_REPAIRED <- 15;
	int ACTION_DIKE_CREATED <- 16;
	int ACTION_DIKE_DROPPED <- 17;
//	int ACTION_DIKE_RAISED <- 18;
	int UPDATE_BUDGET <- 19;
	int REFRESH_ALL <- 20;
	int ACTION_DIKE_LIST <- 21;
	int ACTION_ACTION_LIST <- 211;
	int ACTION_MESSAGE <- 22;
	int CONNECTION_MESSAGE <- 23;
	int INFORM_TAX_GAIN <-24;
	int INFORM_GRANT_RECEIVED <-27;
	int INFORM_FINE_RECEIVED <-28;

	int VALIDATION_ACTION_MODIFY_LAND_COVER_AU <- 11; // Not used. Should detele ?
	int VALIDATION_ACTION_MODIFY_LAND_COVER_A <- 12;// Not used. Should detele ?
	int VALIDATION_ACTION_MODIFY_LAND_COVER_U <- 13;// Not used. Should detele ?
	int VALIDATION_ACTION_MODIFY_LAND_COVER_N <- 14;// Not used. Should detele ?

	
	string stateSimPhase <- 'not started'; // stateSimPhase is used to specify the currrent phase of the simulation 
	//5 possible states 'not started' 'game' 'execute lisflood' 'show lisflood' , 'calculate flood stats' and 'show flood stats' 	
	int messageID <- 0;
	bool sauver_shp <- false ; // si vrai on sauvegarde le resultat dans un shapefile
	string resultats <- "resultats.shp"; //	on sauvegarde les résultats dans ce fichier (attention, cela ecrase a chaque fois le resultat precedent)
	int cycle_sauver <- 100; //cycle à laquelle les resultats sont sauvegardés au format shp
	/* lisfloodReadingStep is used to indicate to which step of lisflood results, the current cycle corresponds */
	int lisfloodReadingStep <- 9999999; //  lisfloodReadingStep = 9999999 it means that their is no lisflood result corresponding to the current cycle
	string timestamp <- ""; // variable utilisée pour spécifier un nom unique au répertoire de sauvegarde des résultats de simulation de lisflood
	matrix<string> all_action_cost <- matrix<string>(csv_file("../includes/cout_action.csv",";"));	
	matrix<string> all_action_delay <- matrix<string>(csv_file("../includes/delai_action.csv",";"));	
	matrix<string> actions_def <- matrix<string>(csv_file("../includes/actions_def.csv",";"));	
	string flood_results <- ""; // store the text to be displayed on flood results per commune 
	
	//buttons size
	float button_size <- 2000#m;
	string UNAM_DISPLAY_c <- "UnAm";
	string active_display <- nil;
	point previous_clicked_point <- nil;
	
	action_done current_action <- nil;
	
	// interface de suivi des actions
	int font_size <- int(shape.height/30);
	int font_interleave <- int(shape.width/60);
	
	//// tableau des données de budget des communes pour tracer le graph d'évolution des budgets
	container data_budget_C1 <- [0];
	container data_budget_C2 <- [0];
	container data_budget_C3 <- [0];	
	container data_budget_C4 <- [0];
	int count_N_to_AU_C1 <-0;
	int count_N_to_AU_C2 <-0;
	int count_N_to_AU_C3 <-0;	
	int count_N_to_AU_C4 <-0;
	container data_count_N_to_AU_C1 <- [0];
	container data_count_N_to_AU_C2 <- [0];
	container data_count_N_to_AU_C3 <- [0];	
	container data_count_N_to_AU_C4 <- [0];
	
	//// Paramètres  des dynamiques des ouvrage /////
	float H_MAX_GANIVELLE <- 1.2; // ganivelle  d'une hauteur de 1.2 metres  -> fixe le maximum d'augmentation de hauteur de la dune
	float H_DELTA_GANIVELLE <- 0.05 ; // une ganivelle  augmente de 5 cm par an la hauteur du cordon dunaire
	int STEPS_DEGRAD_STATUS_OUVRAGE <- 8; // Sur les ouvrages il faut 8 ans pour que ça change de statut
	int STEPS_DEGRAD_STATUS_DUNE <-6; // Sur les dunes, sans ganivelle,  il faut 6 ans pour que ça change de statut
	int STEPS_REGAIN_STATUS_GANIVELLE  <-3; // Avec une ganivelle ça se régénère 2 fois plus vite que ça ne se dégrade
	int PROBA_RUPTURE_DIGUE_ETAT_MAUVAIS <- 13;
	int PROBA_RUPTURE_DIGUE_ETAT_MOYEN <- 6;
	int PROBA_RUPTURE_DIGUE_ETAT_BON <- -1; // si -1, alors  impossible
	int PROBA_RUPTURE_DUNE_ETAT_MAUVAIS <- 8;
	int PROBA_RUPTURE_DUNE_ETAT_MOYEN <- 4;
	int PROBA_RUPTURE_DUNE_ETAT_BON <- -1; // si -1, alors  impossible

	// Paramètres des dynamique de Population
	float ANNUAL_POP_GROWTH_RATE <- 0.009;
	int new_comers_still_to_dispatch <- 0;
	int POP_FOR_NEW_U <- 3 ; // pour les cases qui viennent de passer de AU à U
	int POP_FOR_U_DENSIFICATION <- 10 ; // pour les cases qui ont une action densification
	int POP_FOR_U_STANDARD <- 1 ; // pour les autres cases 	
	/*
	 * Chargements des données SIG
	 */
		file communes_shape <- file("../includes/zone_etude/communes.shp");
		file road_shape <- file("../includes/zone_etude/routesdepzone.shp");
		file zone_protegee_shape <- file("../includes/zone_etude/zps_sic.shp");
		file zone_PPR_shape <- file("../includes/zone_etude/PPR_extract.shp");
		file coastline_shape <- file("../includes/zone_etude/trait_cote.shp");
		file defenses_cote_shape <- file("../includes/zone_etude/defense_cote_littoSIM-05122015.shp");
		file emprise_shape <- file("../includes/zone_etude/emprise_ZE_littoSIM.shp"); 
		file dem_file <- file("../includes/zone_etude/oleron_dem2016.asc") ;
		int nb_cols <- 631;
		int nb_rows <- 906;
		
	//couches joueurs
		file unAm_shape <- file("../includes/zone_etude/zones241115.shp");	

	/* Definition de l'enveloppe SIG de travail */
	geometry shape <- envelope(emprise_shape);
	list<rgb> listC <- brewer_colors("YlOrRd",8);
	
	int round <- 0;
	list<UA> agents_to_inspect update: 10 among UA;
	game_controller network_agent <- nil;
	

init
	{
		create data_retreive number:1;
		
		loop i from: 0 to: (length(listC)-1)  {
		listC[i] <- blend (listC[i], #red , 0.9);
		}
		
		create game_leader number:1;
		
		do implementation_tests;
		/* initialisation du bouton */
		do init_buttons;
		stateSimPhase <- 'not started';
		if activemq_connect {create game_controller number:1 returns:ctl ;
			network_agent <- first(ctl); }

		/*Creation des agents a partir des données SIG */
		create def_cote from:defenses_cote_shape  with:[id_ouvrage::int(read("OBJECTID")),type::string(read("Type_de_de")), status::string(read("Etat_ouvr")), alt::float(get("alt")), height::float(get("hauteur")), nom_com::string(read("Commune")) ];
		create commune from:communes_shape with: [nom_raccourci::string(read("NOM_RAC")),id::int(read("id_jeu"))]
		{
			write " commune " + nom_raccourci + " "+id;
		}
		create road from: road_shape;
		create protected_area from: zone_protegee_shape with: [name::string(read("SITENAME"))];
		create flood_risk_area from: zone_PPR_shape;
		create coast_border_area from: coastline_shape {
			shape <-  shape + 400#m; }
		create coast_dike_area from: coastline_shape {
			shape <-  shape + 600#m; }
		create game_master number:1;
		
		create UA from: unAm_shape with: [id::int(read("FID_1")),ua_code::int(read("grid_code")), population:: int(get("Avg_ind_c"))/*, cout_expro:: int(get("coutexpr"))*/]
		{
			ua_name <- nameOfUAcode(ua_code);
			my_color <- cell_color();
			//cout_expro <- (round (cout_expro /2000 /50))*100; //50= tx de conversion Euros->Boyard on divise par 2 la valeur du cout expro car elle semble surévaluée
			if ua_name = "U" and population = 0 {
					population <- 10;}
			my_color <- cell_color();
			if ua_name = "AU"  {
				AU_to_U_counter <- flip(0.5)?1:0;
				not_updated <- true;
			}
		}
		do load_rugosity;
		ask UA {cells <- cell overlapping self;}
		ask commune where (each.id > 0)
		{
			UAs <- UA overlapping self;
			cells <- cell overlapping self;
			budget <- current_population(self) * impot_unit * 1.2; ///A l’initialisation la commune commence avec un budget équivalent aux impôts annuels perçus + 20%
			write nom_raccourci +" budget initial : " + budget;
		}
		ask def_cote {do init_dike;}
	}
	
 int getMessageID
 	{
 		messageID<- messageID +1;
 		return messageID;
 	}

action implementation_tests {
		 if (int(all_action_cost at {0,0}) != 0 or (int(all_action_cost at {0,5}) != 5)) {
		 		write "Probleme lecture du fichier cout_action";
		 		write ""+all_action_cost;
		 }
	}
	 	
	 	
int delayOfAction (int action_code){
	int rslt <- 9999;
	loop i from:0 to: length(all_action_delay)/3 {
		if ((int(all_action_delay at {1,i})) = action_code)
		 {rslt <- int(all_action_delay at {2,i});}
	}
	return rslt;
	}
	
string labelOfAction (int action_code){
	string rslt <- "";
	loop i from:0 to: 30 {
		if ((int(actions_def at {1,i})) = action_code)
		 {rslt <- actions_def at {3,i};}
	}
	return rslt;
	}
	 
int entityTypeCodeOfAction (int action_code){
	string rslt <- 0;
	loop i from:0 to: 30 {
		if ((int(actions_def at {1,i})) = action_code)
		 {rslt <- actions_def at {5,i};}
	}
	switch rslt {
		match "def_cote" {return ENTITY_TYPE_CODE_DEF_COTE;}
		match "UA" {return ENTITY_TYPE_CODE_UA;}
		default {return 0;}
		}
	}	 
	 
int current_total_population {
	return sum(commune where (each.id > 0) accumulate (each.current_population(each)));
	}
	
int new_comers_to_dispatch {
	return round(current_total_population() * ANNUAL_POP_GROWTH_RATE);
}


action nextRound{
	//do sauvegarder_resultat;
	write "new round "+ (round +1);
	if round != 0
	   {ask def_cote where (each.type != 'Naturel') {  do evolveStatus_ouvrage;}
	   	ask def_cote where (each.type = 'Naturel') { do evolve_dune;}
		new_comers_still_to_dispatch <- new_comers_to_dispatch() ;
		ask shuffle(UA) {pop_updated <- false; do evolve_AU_to_U ;}
		ask shuffle(UA) {do evolve_U_densification ;}
		ask shuffle(UA) {do evolve_U_standard ;} 
		ask commune where (each.id > 0) {
			do recevoirImpots; not_updated<-true;
			}}
	else {stateSimPhase <- 'game'; write stateSimPhase;}
	round <- round + 1;
	ask commune {do informerNumTour;}
	ask game_leader{do informerLeaderDuNumTour;}
	do save_budget_data;
	do save_N_to_AU_data;
	write "done!";
	} 	
	
int commune_id(string xx)
	{
		commune m <- commune first_with(each.network_name = xx);
		if(m = nil)
		{
			m <- (commune first_with (xx contains each.nom_raccourci ));
			m.network_name <- xx;
		}
		return	 m.id;
	}

reflex show_flood_stats when: stateSimPhase = 'show flood stats'
	{// fin innondation
		// affichage des résultats 
		//map values <- user_input([ flood_results :: ""]);	
		// remise à zero des hauteurs d'eau
		loop r from: 0 to: nb_rows -1  {
						loop c from:0 to: nb_cols -1 {cell[c,r].water_height <- 0.0;
													//cell[c,r].max_water_height <- 0.0;
						}  }
		// annulation des ruptures de digues				
		ask def_cote {if rupture = 1 {do removeRupture;}}
		// redémarage du jeu
		if round = 0 {stateSimPhase <- 'not started'; }
		else {
				stateSimPhase <- 'game';
				do nextRound;
		}
		write stateSimPhase;
		}
	
reflex calculate_flood_stats when: stateSimPhase = 'calculate flood stats'
	{// fin innondation
		// calcul des résultats 
		do calculate_communes_results;
		stateSimPhase <- 'show flood stats';
		write stateSimPhase;
		}
		
reflex show_lisflood when: stateSimPhase = 'show lisflood'
	{// lecture des fichiers innondation
	do readLisfloodInRep("results"+timestamp);
//			write  "Nb cells innondées : "+ (cell count (each.water_height !=0));
	}
		
action launchFlood_event (string eventName)
	{ // déclenchement innondation
		stateSimPhase <- 'execute lisflood';	write stateSimPhase;
		if round != 0 {
			loop r from: 0 to: nb_rows -1  { loop c from:0 to: nb_cols -1 {cell[c,r].max_water_height <- 0.0; } } // remise à zero de max_water_height
			ask def_cote {do calcRupture;} 
			do executeLisflood(eventName); // comment this line if you only want to read already existing results
		} 
		set lisfloodReadingStep <- 0;
		stateSimPhase <- 'show lisflood'; write stateSimPhase;
	}

/*reflex test_calcRupture {
	int tot <-0;
	ask def_cote where (each.type != 'Naturel') {
		int p <- 0;
		
		if status = "mauvais" {p <- PROBA_RUPTURE_DIGUE_ETAT_MAUVAIS;}
		if status = "moyen" {p <- PROBA_RUPTURE_DIGUE_ETAT_MOYEN;}
		if status = "bon" {p <- PROBA_RUPTURE_DIGUE_ETAT_BON;}
		if rnd (100) <= p {
			tot <- tot+1;
			}		
	}
	write tot;
}*/
 	
action executeLisflood (string eventName)
	{	timestamp <- machine_time ;
		do save_dem;  
		do save_rugosityGrid;
		do save_lf_launch_files(eventName);
		map values <- user_input(["Input files for flood simulation "+timestamp+" are ready.

BEFORE TO CLICK OK
-Launch '../includes/lisflood-fp-604/lisflood_oleron_current.bat' to generate outputs

WAIT UNTIL Lisflood finishes calculations to click OK (Dos command will close when finish) " :: ""]);
 		}
 		
action save_lf_launch_files (string eventName) {
	switch eventName {
		match "Xynthia" {
			save ("DEMfile         oleron_dem2016_t"+timestamp+".asc\nresroot         res\ndirroot         results\nsim_time        52200\ninitial_tstep   10.0\nmassint         100.0\nsaveint         3600.0\n#checkpoint     0.00001\n#overpass       100000.0\n#fpfric         0.06\n#infiltration   0.000001\n#overpassfile   buscot.opts\nmanningfile     oleron_n2016_t"+timestamp+".asc\n#riverfile      buscot.river\nbcifile         oleron2016.bci\nbdyfile         oleron2016.bdy\n#weirfile       buscot.weir\nstartfile      oleron.start\nstartelev\n#stagefile      buscot.stage\nelevoff\n#depthoff\n#adaptoff\n#qoutput\n#chainageoff\nSGC_enable\n") rewrite: true  to: "../includes/lisflood-fp-604/oleron2016_Xynthia_"+timestamp+".par" type: "text"  ;
			save ("lisflood -dir results"+ timestamp +" oleron2016_Xynthia_"+timestamp+".par") rewrite: true  to: "../includes/lisflood-fp-604/lisflood_oleron_current.bat" type: "text"  ;	
		}
		match "Xynthia moins 50cm" {
			save ("DEMfile         oleron_dem2016_t"+timestamp+".asc\nresroot         res\ndirroot         results\nsim_time        52200\ninitial_tstep   10.0\nmassint         100.0\nsaveint         3600.0\n#checkpoint     0.00001\n#overpass       100000.0\n#fpfric         0.06\n#infiltration   0.000001\n#overpassfile   buscot.opts\nmanningfile     oleron_n2016_t"+timestamp+".asc\n#riverfile      buscot.river\nbcifile         oleron2016.bci\nbdyfile         oleron2016_Xynthia-50.bdy\n#weirfile       buscot.weir\nstartfile      oleron.start\nstartelev\n#stagefile      buscot.stage\nelevoff\n#depthoff\n#adaptoff\n#qoutput\n#chainageoff\nSGC_enable\n") rewrite: true  to: "../includes/lisflood-fp-604/oleron2016_Xynthia-50_"+timestamp+".par" type: "text"  ;
		save ("lisflood -dir results"+ timestamp +" oleron2016_Xynthia-50_"+timestamp+".par") rewrite: true  to: "../includes/lisflood-fp-604/lisflood_oleron_current.bat" type: "text"  ;
		}
	}
}       

action save_dem {
	save cell to: "../includes/lisflood-fp-604/oleron_dem2016_t" + timestamp + ".asc" type: "asc";
	}

action save_rugosityGrid {
		string filename <- "../includes/lisflood-fp-604/oleron_n2016_t" + timestamp + ".asc";
		save 'ncols         631\nnrows         906\nxllcorner     364927.14666668\nyllcorner     6531972.5655556\ncellsize      20\nNODATA_value  -9999' rewrite: true to: filename type:"text";
		loop j from: 0 to: nb_rows- 1 {
			string text <- "";
			loop i from: 0 to: nb_cols - 1 {
				text <- text + " "+ cell[i,j].rugosity;}
			save text to: filename rewrite: false ;
			}
		}  
		
action performance_save_dem {
	float x <- machine_time;
	loop times:10 {do save_dem;}
	write (machine_time - x);
}
action performance_save_dem2 {
	float x <- machine_time;
	loop times:10 {do save_dem_old;}
	write (machine_time - x);
}
action save_dem_old {
		string filename <- "../includes/lisflood-fp-604/oleron_dem2016_t" + timestamp + ".asc";
		save 'ncols         631\nnrows         906\nxllcorner     364927.14666668\nyllcorner     6531972.5655556\ncellsize      20\nNODATA_value  -9999' rewrite: true to: filename type:"text";		
		loop j from: 0 to: nb_rows- 1 {
			string text <- "";
			loop i from: 0 to: nb_cols - 1 {
				text <- text + " "+ cell[i,j].soil_height;}
			save text to:filename rewrite:false;
			}
		}  	
	   
action readLisfloodInRep (string rep)
	 {  string nb <- lisfloodReadingStep;
		loop i from: 0 to: 3-length(nb) { nb <- "0"+nb; }
		string fileName <- "../includes/lisflood-fp-604/"+rep+"/res-"+ nb +".wd";
		if file_exists (fileName)
			{	file lfdata <- text_file(fileName) ;
		 		write "/res-"+ nb +".wd";
				loop r from: 6 to: length(lfdata) -1 {
					string l <- lfdata[r];
					list<string> res <- l split_with "\t";
					loop c from: 0 to: length(res) - 1{
						float w <- float(res[c]);
						if w > cell[c,r-6].max_water_height {cell[c,r-6].max_water_height <-w;}
						cell[c,r-6].water_height <- w;}}	
	        lisfloodReadingStep <- lisfloodReadingStep +1;
	        }
	     else { // fin innondation
	     		lisfloodReadingStep <-  9999999;
	     		if nb = "0000" {map values <- user_input(["Il n'y a pas de fichier de résultat lisflood pour cet évènement" :: 100]);}
	     		else{map values <- user_input(["L'innondation est terminée" :: 100]);
					stateSimPhase <- 'calculate flood stats'; write stateSimPhase;}   }	   
	}
	
action load_rugosity
     { file rug_data <- text_file("../includes/lisflood-fp-604/oleron.n.ascii") ;
			loop r from: 6 to: length(rug_data) -1 {
				string l <- rug_data[r];
				list<string> res <- l split_with " ";
				loop c from: 0 to: length(res) - 1{
					cell[c,r-6].rugosity <- float(res[c]);}}	
	}


action calculate_communes_results
		{	string text <- "";
			ask (commune where (each.id > 0))
			{  	int tot <- length(cells) ;
				int myid <-  self.id; 
				int U_0_5 <-0;	int U_1 <-0;	int U_max <-0;
				int AU_0_5 <-0;	int AU_1 <-0;	int AU_max <-0;
				int A_0_5 <-0;	int A_1 <-0;	int A_max <-0;
				int N_0_5 <-0;	int N_1 <-0;	int N_max <-0;
				ask UAs
					{ 
				ask cells {
						if max_water_height > 0
						{ switch myself.ua_name
							{
							match "U" {
									if max_water_height <= 0.5 {
										U_0_5 <- U_0_5 +1;
										ask commune where(each.id = myid){
											U_0_5c <- U_0_5 * 0.04;
										}
									}
									if between (max_water_height ,0.5, 1.0) {
										U_1 <- U_1 +1;
										ask commune where(each.id = myid){
											U_1c <- U_1 * 0.04;
										}
									}
									if max_water_height >= 1{
										U_max <- U_max +1 ;
										ask commune where(each.id = myid){
											U_maxc <- U_max * 0.04;
										}
									}
								}
							match "AU" {
									if max_water_height <= 0.5 {
										AU_0_5 <- AU_0_5 +1;
										ask commune where(each.id = myid){
											AU_0_5c <- AU_0_5 * 0.04;
										}
									}
									if between (max_water_height ,0.5, 1.0) {
										AU_1 <- AU_1 +1;
										ask commune where(each.id = myid){
											AU_1c <- AU_1 * 0.04;
										}
									}
									if max_water_height >= 1.0 {
										AU_max <- AU_max +1 ;
										ask commune where(each.id = myid){
											AU_maxc <- AU_max * 0.04;
										}
									}
								}
							match "N" {
									if max_water_height <= 0.5 {
										N_0_5 <- N_0_5 +1;
										ask commune where(each.id = myid){
											N_0_5c <- N_0_5 * 0.04;
										}
									}
									if between (max_water_height ,0.5, 1.0) {
										N_1 <- N_1 +1;
										ask commune where(each.id = myid){
											N_1c <- N_1 * 0.04;
										}
									}
									if max_water_height >= 1.0 {
										N_max <- N_max +1 ;
										ask commune where(each.id = myid){
											N_maxc <- N_max * 0.04;
										}
									}
								}
							match "A" {
								if max_water_height <= 0.5 {
									A_0_5 <- A_0_5 +1;
									ask commune where(each.id = myid){
											A_0_5c <- A_0_5 * 0.04;
										}
								}
								if between (max_water_height ,0.5, 1.0) {
									A_1 <- A_1 +1;
									ask commune where(each.id = myid){
											A_1c <- A_1 * 0.04;
										}
								}
								if max_water_height >= 1.0 {
									A_max <- A_max +1 ;
									ask commune where(each.id = myid){
											A_maxc <- A_max * 0.04;
										}
								}
								}	
							}
							
							}
					}
					}
				text <- text + "Résultats commune " + nom_raccourci +"
Surface U innondée : moins de 50cm " + ((U_0_5 * 0.04) with_precision 1) +" ha ("+ ((U_0_5 / tot * 100) with_precision 1) +"%) | entre 50cm et 1m" + ((U_1 * 0.04) with_precision 1) +" ha ("+ ((U_1 / tot * 100) with_precision 1) +"%) | plus de 1m " + ((U_max * 0.04) with_precision 1) +" ha ("+ ((U_max / tot * 100) with_precision 1) +"%) 
Surface AU innondée : moins de 50cm " + ((AU_0_5 * 0.04) with_precision 1) +" ha ("+ ((AU_0_5 / tot * 100) with_precision 1) +"%) | entre 50cm et 1m" + ((AU_1 * 0.04) with_precision 1) +" ha ("+ ((AU_1 / tot * 100) with_precision 1) +"%) | plus de 1m " + ((AU_max * 0.04) with_precision 1) +" ha ("+ ((AU_max / tot * 100) with_precision 1) +"%) 
Surface A innondée : moins de 50cm " + ((A_0_5 * 0.04) with_precision 1) +" ha ("+ ((A_0_5 / tot * 100) with_precision 1) +"%) | entre 50cm et 1m" + ((A_1 * 0.04) with_precision 1) +" ha ("+ ((A_1 / tot * 100) with_precision 1) +"%) | plus de 1m " + ((A_max * 0.04) with_precision 1) +" ha ("+ ((A_max / tot * 100) with_precision 1) +"%) 
Surface N innondée : moins de 50cm " + ((N_0_5 * 0.04) with_precision 1) +" ha ("+ ((N_0_5 / tot * 100) with_precision 1) +"%) | entre 50cm et 1m" + ((N_1 * 0.04) with_precision 1) +" ha ("+ ((N_1 / tot * 100) with_precision 1) +"%) | plus de 1m " + ((N_max * 0.04) with_precision 1) +" ha ("+ ((N_max / tot * 100) with_precision 1) +"%) 
--------------------------------------------------------------------------------------------------------------------
" ;	
			}
			flood_results <-  text;
			write "Surface inondée par commune";
			ask (commune where (each.id > 0))
				{ 	surface_inondee <- (U_0_5c + U_1c + U_maxc + AU_0_5c + AU_1c + AU_maxc + N_0_5c + N_1c + N_maxc + A_0_5c + A_1c + A_maxc) with_precision 1 ; 
					add surface_inondee to: data_surface_inondee; 
					write ""+ nom_raccourci + " : " + surface_inondee +" ha";
				}
		}

 /* pour la sauvegarde des données en format shape */
action sauvegarder_resultat //when: sauver_shp and cycle = cycle_sauver
	{										 
		save cell type:"shp" to: resultats with: [soil_height::"SOIL_HEIGHT", water_height::"WATER_HEIGHT"];
	}

/*
 * ***********************************************************************************************
 *                        RECEPTION ET APPLICATION DES ACTIONS DES JOUEURS 
 *  **********************************************************************************************
 */


species data_retreive skills:[network] schedules:[]
{
	init 
	{
		write "start sender ";
		 do connect to:SERVER with_name:GAME_LEADER_MANAGER+"_retreive";
	}
	action send_data_to_commune(commune m)
	{
		write "send data.... to "+ m.network_name;
		do init_dikes(m);
		do init_cells(m);
		do init_action(m);
	}
	
	action init_dikes(commune m)
	{
		string commune_name_shpfile<- nil;
		switch (m.nom_raccourci)
			{
			match "lechateau" {commune_name_shpfile <-"Le-Chateau-d'Oleron";}
			match "dolus" {commune_name_shpfile <-"Dolus-d'Oleron";}
			match "sttrojan" {commune_name_shpfile <-"Saint-Trojan-Les-Bains";}
			match "stpierre" {commune_name_shpfile <-"Saint-Pierre-d'Oleron";}
			}  
		
		list<def_cote> def_list <- def_cote where(each.nom_com = commune_name_shpfile);
		def_cote tmp;
		loop tmp over:def_list
		{
			write "send to "+ m.network_name+"_retreive" + " "+tmp.build_map_from_attribute();
			do send 	to:m.network_name+"_retreive" contents:tmp.build_map_from_attribute();
		}
		
	}
	
	action init_cells(commune m)
	{
		UA tmp<- nil;
		loop tmp over:m.UAs
		{
			write "send to "+ m.network_name+"_retreive" + " "+tmp.build_map_from_attribute();
			do send 	to:m.network_name+"_retreive" contents:tmp.build_map_from_attribute();
		}
	}

	action init_action(commune m)
	{
		list<action_done> action_list <- action_done where(each.doer = m.nom_raccourci);
		action_done tmp<- nil;
		loop tmp over:action_list 	
		{
			write "send to "+ m.network_name+"_retreive" + " "+tmp.build_map_from_attribute();
			do send 	to:m.network_name+"_retreive" contents:tmp.build_map_from_attribute();
		}
	}
}


species action_done schedules:[]
{
	int id;
	int chosen_element_id;
	string doer<-"";
	bool not_updated <- false;
	bool is_applied <- false;
	bool is_sent <-true;
	//string command_group <- "";
	int command <- -1 on_change: {label <- world.labelOfAction(command);};
	int command_round<--1;
	string label <- "no name";
	float cost <- 0.0;	
	bool should_be_applied ->{round >= application_round} ;
	int application_round <- -1;
	int round_delay <- 0 ; // nb rounds of delay
	bool is_delayed ->{round_delay>0} ;
	list<string> my_message <-[];
	// attributs ajouté par NB dans la specie action_done (modèle oleronV2.gaml) pour avoir les infos en plus sur les actions réalisés, nécessaires pour que le leader puisse applique des leviers
	string action_type <- "dike" ; //can be "dike" or "PLU"
	string previous_ua_name <-"";  // for PLU action
	bool isExpropriation <- false; // for PLU action
	bool inProtectedArea <- false; // for dike action
	bool inLittoralArea <- false; // for PLU action // c'est la bande des 400 m par rapport au trait de cote
	bool inRiskArea <- false; // for PLU action / Ca correspond à la zone PPR qui est un shp chargé
	bool isInlandDike <- false; // for dike action // ce sont les rétro-digues
	bool is_alive <- true;
	
	action init_from_map(map<string, string> a )
	{
		self.id <- int(a at "id");
		self.chosen_element_id <- int(a at "chosen_element_id");
		self.doer <- a at "doer";
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
		self.command_round <-int(a at "command_round"); 
		
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
	
	map<string,string> build_map_from_attribute
	{
		map<string,string> res <- [
			"OBJECT_TYPE"::"action_done",
			"id"::string(id),
			"chosen_element_id"::string(chosen_element_id),
			"doer"::string(doer),
			"command"::string(command),
			"label"::string(label),
			"cost"::string(cost),
			"application_round"::string(application_round),
			"round_delay"::string(round_delay),
			"isInlandDike"::string(isInlandDike),
			"inRiskArea"::string(inRiskArea),
			"inLittoralArea"::string(inLittoralArea),
			"isExpropriation"::string(isExpropriation),
			"inProtectedArea"::string(inProtectedArea),
			"previous_ua_name"::string(previous_ua_name),
			"action_type"::string(action_type),
			"locationx"::string(location.x),
			"locationy"::string(location.y),
			"is_applied"::string(is_applied),
			"is_sent"::string(is_sent),
			"command_round"::string(command_round)
			 ]	;
			point pp<-nil;
			int i <- 0;
			loop pp over:shape.points
			{
				put string(pp.x) key:"locationx"+i in: res;
				put string(pp.y) key:"locationy"+i in: res;
				i <- i + 1;
			}
	return res;
	}
	
	
	// NB pas utilisé il me semble
	/*rgb define_color
	{
		switch(command)
		{
			 match ACTION_CREATE_DIKE { return #blue;}
			 match ACTION_REPAIR_DIKE {return #green;}
			 match ACTION_DESTROY_DIKE {return #brown;}
			 match ACTION_MODIFY_LAND_COVER_A { return #brown;}
			 match ACTION_MODIFY_LAND_COVER_AU {return #orange;}
			 match ACTION_MODIFY_LAND_COVER_N {return #green;}
		} 
		return #grey;
	}*/
	// Pas utilisé car remplacé par l'interface Leader
	action assign_delay(int nb) 
	{
		round_delay <- round_delay + nb;
		application_round <- application_round + nb; 
		commune cm <-commune first_with (each.nom_raccourci = doer);
		ask network_agent
							{
							string msg <- ""+NOTIFY_DELAY+COMMAND_SEPARATOR+world.getMessageID()+COMMAND_SEPARATOR+world.entityTypeCodeOfAction(myself.command)+COMMAND_SEPARATOR+myself.id+COMMAND_SEPARATOR+nb;
							do send to:cm.network_name contents:msg;
							}
	}
	
	aspect base
	{
		
		
			int indx <- action_done index_of self;
			float y_loc <- (indx +1)  * font_size ;
			float x_loc <- font_interleave + 12* (font_size+font_interleave);
			float x_loc2 <- font_interleave + 20* (font_size+font_interleave);
			shape <- rectangle({font_size+2*font_interleave,y_loc},{x_loc2,y_loc+font_size/2} );
			draw shape color:#white;
			string txt <- doer+": "+ label;
			txt <- txt +" ("+string(application_round-round)+")"; 
			draw txt at:{font_size+2*font_interleave,y_loc+font_size/2} size:font_size#m color:#black;
			draw "    "+ round(cost) at:{x_loc,y_loc+font_size/2} size:font_size#m color:#black;
		
	}

	

	
	def_cote create_dike(action_done act)
	{
		int id_ov <- max(def_cote collect(each.id_ouvrage))+1;
		create def_cote number:1 returns:ovgs
		{
			id_ouvrage <- id_ov;
			shape <- act.shape;
			type <- BUILT_DIKE_TYPE ;
			status <- BUILT_DIKE_STATUS;
			height <- STANDARD_DIKE_SIZE;	
			cells <- cell overlapping self;
		}
		return first(ovgs);
	}
	
}

species game_master // c'est le game master qui va mettre en place les leviers pour inciter les joueurs à changer de stratégie
{
	action  monitor_new_action (action_done new_action)
	{
		// Cette première mesure n'est pas un levier incitatif a proprpement parlé mais plutot une contrainte réglementaire qui s'applique automatiqmeent 
		// Ce n'est pas au modèle OleronV2 de faire ça mais c'est au leader/
		// Par ailleurs il n'y a plus besoi  d'interroger le shape à ce niveau. L'attribut inProtectedArea qui a été rensigné par Participatif.gaml indique si les travaux sont ds une zone protégée
		// En attendat le basculement , je remet le code ici  // et en dessous il y a l'ancien code qui recalculé l'overlap du shape
		if new_action.command in [ACTION_CREATE_DIKE , ACTION_RAISE_DIKE ] and new_action.inProtectedArea 
				{ ask new_action {do assign_delay(1);} }
		/*if new_action.command in [ACTION_CREATE_DIKE , ACTION_RAISE_DIKE ]
			{
				geometry a_shape ;
				switch new_action.command {
					match ACTION_RAISE_DIKE{ a_shape <- (def_cote first_with(each.id_ouvrage=new_action.chosen_element_id)).shape ;}
					match ACTION_CREATE_DIKE{ a_shape <- new_action.shape ;}
					}
				if a_shape = nil {write "PROBLEME  switch new.action.command";
					}
					// si dans une zone protégée --> un an de retard
			if !empty(protected_area overlapping (a_shape)) 
				{
					ask new_action {do assign_delay(1);}
				}
		}*/
	}
}  

species game_leader skills:[network]
{
	string ABROGER <- "Abroger";
	string RECETTE <- "Percevoir Recette";
	string SUBVENTIONNER <- "Subventionner";
	string RETARDER <- "Retarder";
	string LEVER_RETARD <- "Lever les retards";
	string LEADER_COMMAND <- "leader_command";
	string AMOUNT <- "amount";
	string DELAY <- "delay";
	string ACTION_ID <- "action_id";
	string COMMUNE <- "COMMUNE_ID";
	string ASK_NUM_ROUND <- "Leader demande numéro du tour";
	string NUM_ROUND <- "Numéro du tour";
	
	
	init
	{
		 do connect to:SERVER with_name:GAME_LEADER_MANAGER;
	}
	
	
	reflex  wait_message 
	{
		loop while:has_more_message()
		{
			message msg <- fetch_message();
			map<string, unknown> m_contents <- msg.contents;
			
			string cmd <- m_contents[LEADER_COMMAND];
			
			write "command " + cmd;
			switch(cmd)
			{
				match RETARDER
				{
					int id_action <- m_contents[ACTION_ID];
					int delais <- m_contents[DELAY];
					action_done dd <- action_done first_with(each.id=id_action);
					do retarder_action(dd,delais);
				}
				match SUBVENTIONNER
				{
					int id_commune <- m_contents[COMMUNE];
					int amount <- m_contents[AMOUNT];
					write "commune " + m_contents[COMMUNE];
					commune com <- commune first_with(each.id=id_commune);
					write "commune found " + com;

					do subventionner(com,amount);

				}
				match RECETTE
				{
					int id_commune <- m_contents[COMMUNE];
					int amount <- m_contents[AMOUNT]; 
					commune com <- commune first_with(each.id=id_commune);
					do percevoir(com,amount);
				}
				match LEVER_RETARD
				{
					int id_action <- m_contents[ACTION_ID];
					action_done dd <- action_done first_with(each.id=id_action);
					
					do appliquer_action(dd);
				}
				
				match ASK_NUM_ROUND {
					do informerLeaderDuNumTour;
				}

			}
			
		}
		
	}
	
	action informerLeaderDuNumTour  {
					map<string,string> msg <- [];
					put NUM_ROUND key:OBSERVER_MESSAGE_COMMAND in:msg ;
					put string(round) key: "num tour" in: msg;
					do send to:OBSERVER_NAME contents:msg;
				}
	
	action retarder_action(action_done act, int duree)
	{
		ask act
		{
			round_delay <- round_delay + duree;
			application_round <- application_round + duree; 
			commune cm <-commune first_with (each.nom_raccourci = doer);
			ask network_agent
				{
				string msg <- ""+NOTIFY_DELAY+COMMAND_SEPARATOR+world.getMessageID()+COMMAND_SEPARATOR+world.entityTypeCodeOfAction(myself.command)+COMMAND_SEPARATOR+myself.id+COMMAND_SEPARATOR+duree;
				do send to:cm.network_name contents:msg;
				}
		}
		
	}
	action appliquer_action(action_done act)
	{
		ask act
			{
				int tmp <- application_round - round;
				round_delay <- round_delay - tmp;
				application_round <- round; 
				commune cm <-commune first_with (each.nom_raccourci = doer);
				ask network_agent
				{
					string msg <- ""+NOTIFY_DELAY+COMMAND_SEPARATOR+world.getMessageID()+COMMAND_SEPARATOR+world.entityTypeCodeOfAction(myself.command)+COMMAND_SEPARATOR+myself.id+COMMAND_SEPARATOR+tmp;
					do send to:cm.network_name contents:msg;
				}
		}
		
	}
	action subventionner(commune cm, int montant)
	{
		cm.budget <- cm.budget + montant;
		ask network_agent
			{
			string msg <- ""+INFORM_GRANT_RECEIVED+COMMAND_SEPARATOR+world.getMessageID()+COMMAND_SEPARATOR+int(montant);
			do send to:cm.network_name contents:msg;
			}
		cm.not_updated <- true;
	}
	
	action percevoir(commune cm, int montant)
	{
		cm.budget <- cm.budget - montant;
		ask network_agent
		{
			string msg <- ""+INFORM_FINE_RECEIVED+COMMAND_SEPARATOR+world.getMessageID()+COMMAND_SEPARATOR+int(montant);
			do send to:cm.network_name contents:msg;
		}
		cm.not_updated <- true;
	}
	
	reflex send_action_state when: cycle mod 10 = 0
	{
		loop act_done over: action_done
		{
			map<string,string> msg <- act_done.build_map_from_attribute();
			put UPDATE_ACTION_DONE key:OBSERVER_MESSAGE_COMMAND in:msg ;
			do send to:OBSERVER_NAME contents:msg;
			write "send message to leader "+ msg;
			
		}
	}
	
}

species game_controller skills:[network]
{
	init
	{
		 do connect to:"localhost" with_name:MANAGER_NAME;
	}
	
	reflex wait_message when: activemq_connect
	{
		loop while:has_more_message()
		{
			message msg <- fetch_message();
			string m_sender <- msg.sender;
			map<string, unknown> m_contents <- msg.contents;
			if(m_sender!=MANAGER_NAME )
			{
				
				if(m_contents["stringContents"]!= nil)
				{
					write"read message: " + m_contents["stringContents"];
					list<string> data <- string(m_contents["stringContents"]) split_with COMMAND_SEPARATOR;
					if(CONNECTION_MESSAGE = int(data[0]))
					{
							int idCom <-world.commune_id(m_sender);
							ask(commune where(each.id= idCom))
							{
								not_updated <- true;
								do informerNumTour;
							}
								write "connexion de "+ m_sender + " "+ idCom;
						
					}
					else
						{
							if(REFRESH_ALL = int(data[0]))
							{
								int idCom <-world.commune_id(m_sender);
								write " Update ALL !!!! " + idCom+ " ";
								commune cm <- first(commune where(each.id=idCom));
								ask first(data_retreive) 
								{
									do send_data_to_commune(cm);
								}
							} 
							else
							{
								if(round>0) 
								{
									write "read action " + m_contents["stringContents"];
									do read_action(string(m_contents["stringContents"]),m_sender);
								}
								
							}
						}
				}
				else
				{
					map<string,unknown> data <- m_contents["objectContent"];
					
				}
				
			}
			
					
		}
	}
	
	action apply_data_message(map<string, unknown> data)
	{
		
	}
	
	reflex apply_action when:length(action_done where(each.is_alive))>0 
	{
		ask(action_done where(each.should_be_applied and each.is_alive))
		{
			string tmp <- self.doer;
			int idCom <-world.commune_id(tmp);
			action_done act <- self;
			if(log_user_action)
			{
				list<string> data <- [string(machine_time-START_LOG),tmp]+self.my_message;
				save data to:LOG_FILE_NAME type:"csv";
			}
			switch(command)
			{
				match ACTION_MESSAGE
				{
					write self.doer +" -> "+my_message;
				}
				match REFRESH_ALL
				{
					write " Update ALL !!!! " + idCom+ " "+ doer;
					string dd <- doer;
					commune cm <- first(commune where(each.id=idCom));
					ask first(data_retreive) 
					{
						do send_data_to_commune(cm);
					}
					/*
					ask def_cote overlapping cm { not_updated <- true;}
				//	ask action_done where(each.doer=dd)  { not_updated <- true;}
					ask UA overlapping cm { not_updated <- true;}
					ask cm {not_updated <- true;}
					ask game_controller
					{
						do send_dike_list(idCom);
					//	do send_action_list(idCom);
					}
					
					*/
				}
				
				match ACTION_CREATE_DIKE
				{	
					def_cote ovg <-  create_dike(self);
					ask network_agent
					{
						do send_create_dike_message(ovg, act);
					}
					ask(ovg) {do new_dike_by_commune (idCom) ;
					}
				}
				match ACTION_REPAIR_DIKE {
					ask(def_cote first_with(each.id_ouvrage=chosen_element_id))
					{
						do repair_by_commune(idCom);
						not_updated <- true;
					}		
				}
			 	match ACTION_DESTROY_DIKE 
			 	 {
			 		ask(def_cote first_with(each.id_ouvrage=chosen_element_id))
					{
						ask network_agent
						{
							do send_destroy_dike_message(myself,act);
						}
						do destroy_by_commune (idCom) ;
						not_updated <- true;
					}		
				}
			 	match ACTION_RAISE_DIKE {
			 		ask(def_cote first_with(each.id_ouvrage=chosen_element_id))
					{
						do increase_height_by_commune (idCom) ;
						not_updated <- true;
					}
				}
				 match ACTION_INSTALL_GANIVELLE {
				 	ask(def_cote first_with(each.id_ouvrage=chosen_element_id))
					{
						do install_ganivelle_by_commune (idCom) ;
						not_updated <- true;
					}
				}
			 	match ACTION_MODIFY_LAND_COVER_A {
			 		ask UA first_with(each.id=chosen_element_id)
			 		 {
			 		  do modify_UA (idCom, "A");
			 		  not_updated <- true;
			 		 }
			 	}
			 	match ACTION_MODIFY_LAND_COVER_AU {
			 		ask UA first_with(each.id=chosen_element_id)
			 		 {
			 		 	do modify_UA (idCom, "AU");
			 		 	not_updated <- true;
			 		 }
			 	}
				match ACTION_MODIFY_LAND_COVER_N {
					ask UA first_with(each.id=chosen_element_id)
			 		 {
			 		 	do modify_UA (idCom, "N");
			 		 	not_updated <- true;
			 		 }
			 	}
			 	match ACTION_MODIFY_LAND_COVER_Us {
			 		ask UA first_with(each.id=chosen_element_id)
			 		 {
			 		 	do modify_UA (idCom, "Us");
			 		 	not_updated <- true;
			 		 }
			 	 }
			 	 match ACTION_MODIFY_LAND_COVER_Ui {
			 		ask UA first_with(each.id=chosen_element_id)
			 		 {
			 		 	do apply_Densification(idCom);
			 		 	not_updated <- true;
			 		 }
			 	 }
			 	match ACTION_MODIFY_LAND_COVER_AUs {
			 		ask UA first_with(each.id=chosen_element_id)
			 		 {
			 		 	do modify_UA (idCom, "AUs");
			 		 	not_updated <- true;
			 		 }
			 	}
			}

		/* 	ask network_agent
			{
				do action_is_applied(act);
			}*/
			
			is_alive <- false; 
			is_applied <- true;
			//do die;
		}
		
		
	}
	
	action action_is_applied(action_done act)
	{
		string msg <-""+ ACTION_IS_APPLIED+ COMMAND_SEPARATOR+world.getMessageID() +COMMAND_SEPARATOR+act.id;
		commune cm <- commune first_with(each.nom_raccourci = act.doer);
		ask network_agent
		{
			do send to:cm.network_name contents:msg;
		}
	}
	
		
	action read_action(string act, string sender)
	{
		list<string> data <- act split_with COMMAND_SEPARATOR;
		
		if(! (int(data[0]) in ACTION_LIST ) )
		{
			return;
		}
		
		action_done new_action <- nil;
		create action_done number:1 returns:tmp_agent_list;
		new_action <- first(tmp_agent_list);
		ask(new_action)
		{
			self.command <- int(data[0]);
			self.command_round <-round; 
			self.id <- int(data[1]);
			self.application_round <- int(data[2]);
			self.doer <- sender;
			self.my_message <- data;
			if !(self.command in [ACTION_MESSAGE,REFRESH_ALL]) {
				self.chosen_element_id <- int(data[3]);
				self.action_type <- string(data[4]);
				self.inProtectedArea <- bool(data[5]);
				self.previous_ua_name <- string(data[6]);
				self.isExpropriation <- bool(data[7]);
				self.cost <- float(data[8]);
				if command = ACTION_CREATE_DIKE
				{
					point ori <- {float(data[9]),float(data[10])};
					point des <- {float(data[11]),float(data[12])};
					point loc <- {float(data[13]),float(data[14])}; 
					shape <- polyline([ori,des]);
					location <- loc; 
				}
				else {
					if isExpropriation {write "Procédure d'expropriation declenchée pour l'UA "+self.id;}
					switch self.action_type {
						match "PLU" {shape <- (UA first_with(each.id = self.chosen_element_id)).shape; }
						match "dike" {shape <- (def_cote first_with(each.id_ouvrage = self.chosen_element_id)).shape; }
						default {write "problème reconnaissance du type de action_done";}
					}
				}
				// calcul des attributs qui n'ont pas été calculé au niveau de Participatif et qui ne sont donc pas encore renseigné
				//inLittoralArea  // for PLU action // c'est la bande des 400 m par rapport au trait de cote
				//inRiskArea  // for PLU action / Ca correspond à la zone PPR qui est un shp chargé
				//isInlandDike  // for dike action // ce sont les rétro-digues
				if  !empty(flood_risk_area where (each intersects self.shape))
					{inRiskArea <- true;}
				if  !empty(coast_border_area where (each intersects self.shape))
					{inLittoralArea <- true;}	
				if command = ACTION_CREATE_DIKE {
					if  empty(coast_dike_area where (each intersects self.shape))
						{isInlandDike <- true;}}
				// finallement on recalcul aussi inProtectedArea meme si ca a été calculé au niveau de participatif, car en fait ce n'est pas calculé pour toute les actions 
				if  !empty(protected_area where (each intersects self.shape))
					{inProtectedArea <- true;}
				  
			}
			/*  ANCIEN CODE QUI PERMETTAT DE VERIFIER QUE LE DELAI POUR LES ACTION DE Expropriatipon était correct
			 * if self.application_round != (round  + (world.delayOfAction(self.command)))
			{	if self.command = ACTION_MODIFY_LAND_COVER_N { // c'est possible que ce soit une action d'expropriation; auquel cas il fait appliquer un delai d'execution
					if (UA first_with(each.id=id)).ua_name in ["U","Us"] {///   ATTENTION, c'est possible qu il y ai une erreur car on interroge id alors qu'on devrait interroger chosen_element_id
							write "Procédure d'expropriation declenchée pour l'UA "+self.id;
							if self.application_round != (round  + (world.delayOfAction(ACTION_EXPROPRIATION)))
								{write "PROBELEME avec la valeur de l'application round récupéré du client >> self.application_round : "+ self.application_round + " ; round  + (world.delayOfAction(self.command)) : " +(round  + (world.delayOfAction(self.command)));
								//self.application_round <- round  + (world.delayOfAction(ACTION_EXPROPRIATION));
							}
					}
					else{	write "PROBELEME avec la valeur de l'application round récupéré du client >> self.application_round : "+ self.application_round + " ; round  + (world.delayOfAction(self.command)) : " +(round  + (world.delayOfAction(self.command)));
							self.application_round <- round  + (world.delayOfAction(self.command));
					}
				}
				else{	write "PROBELEME avec la valeur de l'application round récupéré du client >> self.application_round : "+ self.application_round + " ; round  + (world.delayOfAction(self.command)) : " +(round  + (world.delayOfAction(self.command)));
						self.application_round <- round  + (world.delayOfAction(self.command));
				}
			}*/	
		}
		//   On enlève le monitoring par le game_master car on ne souhait plus que des retards soient apploqués systématqiuement 
		//ask game_master {do monitor_new_action( new_action);}
		//  le paiement se fait au niveau de cette méthode pour que la commune paye au moment de la reception de l'action, et non pas au moment de son applicatiion
		int idCom <-world.commune_id(new_action.doer);
		ask commune first_with(each.id = idCom) {do pay_for_action_done(new_action);}
	}
	
	
	
	reflex send_space_update
	{
		do update_UA;
		do update_dike;
	//	do update_action_done_func();
		do update_commune;
	}
	
	action update_UA
	{
		list<string> update_messages <-[];
		list<UA> updated_UA <- [];
		ask UA where(each.not_updated)
		{
			string msg <- ""+ACTION_LAND_COVER_UPDATE+COMMAND_SEPARATOR+world.getMessageID() +COMMAND_SEPARATOR+id+COMMAND_SEPARATOR+self.ua_code+COMMAND_SEPARATOR+self.population+COMMAND_SEPARATOR+self.isEnDensification;
			update_messages <- update_messages + msg;	
			not_updated <- false;
			updated_UA <- updated_UA + self;
		}
		int i <- 0;
		loop while: i< length(update_messages)
		{
			string msg <- update_messages at i;
			list<commune> cms <- commune overlapping (updated_UA at i);
			loop cm over:cms
			{ do send to:cm.network_name contents:msg;
			}
			i <- i + 1;
			
		}
	}
	
	action send_destroy_dike_message(def_cote ovg, action_done act)
	{
		string msg <- ""+ACTION_DIKE_DROPPED+COMMAND_SEPARATOR+world.getMessageID() +COMMAND_SEPARATOR+ovg.id_ouvrage+ COMMAND_SEPARATOR+act.id;
		
		list<commune> cms <- commune overlapping ovg;
		loop cm over:cms
			{
				do send to:cm.network_name contents:msg;
			}
	//	do sendMessage  dest:"all" content:msg;	
	
	}
	
	action send_create_dike_message(def_cote ovg, action_done act)
	{
		point p1 <- first(ovg.shape.points);
		point p2 <- last(ovg.shape.points);
		
		
		string msg <- ""+ACTION_DIKE_CREATED+COMMAND_SEPARATOR+world.getMessageID() +COMMAND_SEPARATOR+ovg.id_ouvrage+COMMAND_SEPARATOR+p1.x+COMMAND_SEPARATOR+p1.y+COMMAND_SEPARATOR+p2.x+COMMAND_SEPARATOR+p2.y+COMMAND_SEPARATOR+ovg.height+COMMAND_SEPARATOR+ovg.type+COMMAND_SEPARATOR+ovg.status+ COMMAND_SEPARATOR+min_dike_elevation(ovg)+ COMMAND_SEPARATOR+act.id;
		list<commune> cms <- commune overlapping ovg;
			loop cm over:cms
			{
				do send  to:cm.network_name contents:msg;
			}

	//	do sendMessage  dest:"all" content:msg;	
	}
	
	float min_dike_elevation(def_cote ovg)
	{
		return min(cell overlapping ovg collect(each.soil_height));
	}
	action send_dike_list(int m_commune)
	{
		string tmp<-"";
		commune m <- commune first_with(each.id=m_commune);
		ask def_cote overlapping m
		{
			tmp <- tmp +  COMMAND_SEPARATOR+id_ouvrage;
		}
		
		string msg <- ""+ACTION_DIKE_LIST+COMMAND_SEPARATOR+world.getMessageID() +COMMAND_SEPARATOR +m.nom_raccourci+tmp;
		do send to:m.network_name contents:msg;	
	}
	
	action send_action_list(int m_commune)
	{
		string tmp<-"";
		commune m <- commune first_with(each.id=m_commune);
		ask action_done where(each.doer = m.nom_raccourci )
		{
			tmp <- tmp +  COMMAND_SEPARATOR+id; //XXXX
		}
		
		string msg <- ""+ACTION_ACTION_LIST+COMMAND_SEPARATOR+world.getMessageID() +COMMAND_SEPARATOR +m.nom_raccourci+tmp;
		do send to:m.network_name contents:msg;	
	}
	
	
	action update_dike
	{
		list<string> update_messages <-[]; 
		list<def_cote> update_ouvrage <- [];
		ask def_cote where(each.not_updated)
		{
			point p1 <- first(self.shape.points);
			point p2 <- last(self.shape.points);
			string msg <- ""+ACTION_DIKE_UPDATE+COMMAND_SEPARATOR+world.getMessageID() +COMMAND_SEPARATOR+self.id_ouvrage+COMMAND_SEPARATOR+p1.x+COMMAND_SEPARATOR+p1.y+COMMAND_SEPARATOR+p2.x+COMMAND_SEPARATOR+p2.y+COMMAND_SEPARATOR+self.height+COMMAND_SEPARATOR+self.type+COMMAND_SEPARATOR+self.status+COMMAND_SEPARATOR+self.ganivelle+COMMAND_SEPARATOR+myself.min_dike_elevation(self);
			update_messages <- update_messages + msg;
			update_ouvrage <- update_ouvrage + self;
			not_updated <- false;
		}
		int i <- 0;
		loop while: i< length(update_messages)
		{
			string msg <- update_messages at i;
			list<commune> cms <- commune overlapping (update_ouvrage at i);
			loop cm over:cms
			{
				write "message to send "+ msg;
				do send to:cm.network_name contents:msg;
			}
			i <- i + 1;
			
		}
	}
	
	action update_action_done_func
	{
		list<string> update_messages <-[]; 
		list<action_done> update_action_done <- [];
		ask action_done where(each.not_updated)
		{
			point p1 <- first(self.shape.points);
			point p2 <- last(self.shape.points);
			string msg <- ""+ACTION_ACTION_DONE_UPDATE+COMMAND_SEPARATOR+world.getMessageID() +
			COMMAND_SEPARATOR+self.id+
			COMMAND_SEPARATOR + self.chosen_element_id +
			COMMAND_SEPARATOR + self.doer+
			COMMAND_SEPARATOR + 	self.command +
			COMMAND_SEPARATOR + self.label+
			COMMAND_SEPARATOR + self.cost+
			COMMAND_SEPARATOR + self.application_round +
			COMMAND_SEPARATOR + self.round_delay +
			COMMAND_SEPARATOR + self.isInlandDike +
			COMMAND_SEPARATOR + self.inRiskArea +
			COMMAND_SEPARATOR + self.inLittoralArea +
			COMMAND_SEPARATOR + self.isExpropriation +
			COMMAND_SEPARATOR + self.inProtectedArea +
			COMMAND_SEPARATOR + self.previous_ua_name +

			COMMAND_SEPARATOR + self.action_type+
			COMMAND_SEPARATOR + string(self.shape);

			
			update_messages <- update_messages + msg;
			update_action_done <- update_action_done + self;
			not_updated <- false;
		}
		int i <- 0;
		loop while: i< length(update_messages)
		{
			string msg <- update_messages at i;
			list<commune> cms <- commune where(each.nom_raccourci = (update_action_done at i).doer);
			loop cm over:cms
			{
				write "message to send "+ msg;
				do send to:cm.network_name contents:msg;
			}
			i <- i + 1;
			
		}
	}
	action update_commune
	{
		list<string> update_messages <-[]; 
		ask commune where(each.not_updated)
		{
			string msg <- ""+UPDATE_BUDGET+COMMAND_SEPARATOR+world.getMessageID() +COMMAND_SEPARATOR+ budget;
			not_updated <- false;
			ask first(game_controller)
			{
				do send  to:myself.network_name contents:msg;
				
			}
		}
	}
	
	
	
	
}
	

	
	
/*
 * ***********************************************************************************************
 *                                       LES BOUTONS  
 *  **********************************************************************************************
 */
 action init_buttons
	{
		create buttons number: 1
		{
			nb_button <- 0;
			label <- "One step";
			shape <- square(button_size);
			location <- { 1000,1000 };
			my_icon <- image_file("../images/icones/one_step.png");
			display_name <- UNAM_DISPLAY_c;
		}
		create buttons number: 1
		{
			nb_button <- 3;
			label <- "Lisflood Xynthia";
			shape <- square(button_size);
			location <- { 5000,1000 };
			my_icon <- image_file("../images/icones/launch_lisflood.png");
			display_name <- UNAM_DISPLAY_c;
		}
		
		create buttons number: 1
		{
			nb_button <- 5;
			label <- "Lisflood Xynthia - 50cm";
			shape <- square(button_size);
			location <- { 7000,1000 };
			my_icon <- image_file("../images/icones/launch_lisflood_small.png");
			display_name <- UNAM_DISPLAY_c;
		}
		
		// NB Pas utilisé car remplacé par l'interface Leader
		/*create buttons number: 1
		{
			nb_button <- 1;
			label <- "subvention";
			shape <- square(button_size);
			location <- { 1000 , 4000};
			my_icon <- image_file("../images/icones/subvention.png");
			display_name <- UNAM_DISPLAY_c;
		}
		
		create buttons number: 1
		{
			nb_button <- 2;
			label <- "taxe";
			shape <- square(button_size);
			location <- { 1000, 6000 };
			my_icon <- image_file("../images/icones/taxe.png");
			display_name <- UNAM_DISPLAY_c;
		}*/
		create buttons number: 1
		{
			nb_button <- 4;
			label <- "Show UA grid";
			shape <- square(850);
			location <- { 800,14000 };
			my_icon <- image_file("../images/icones/sans_quadrillage.png");
			is_selected <- false;
		}
	}
	
	
    //Action Général appel action particulière 
    action button_click_C_mdj //(point loc, list selected_agents)
	{
		
		point loc <- #user_location;
		if(active_display != UNAM_DISPLAY_c)
		{
			current_action <- nil;
			active_display <- UNAM_DISPLAY_c;
			do clear_selected_button;
			//return;
		}
		
		list<buttons> selected_UnAm_c <- ( buttons where (each distance_to loc < MOUSE_BUFFER)) where(each.display_name=active_display );
		ask ( buttons where (each distance_to loc < MOUSE_BUFFER)) where(each.display_name=active_display )
		{
			if (nb_button = 0){
				ask world {do nextRound;}
			}
			if (nb_button = 3){
				ask world {do launchFlood_event("Xynthia");}
			}
			if (nb_button = 5){
				ask world {do launchFlood_event("Xynthia moins 50cm");}
			}
			
			/*	// NB Pas utilisé car remplacé par l'interface Leader
			 * if (nb_button = 1){
				//Bouton Subvention
				map values <- user_input("Vous allez octroyer une subvention à une commune.
Choisissez le numéro de la commune :
1 -> "+ (commune first_with (each.id =1)).nom_raccourci+"
2 -> "+ (commune first_with (each.id =2)).nom_raccourci+"
3 -> "+ (commune first_with (each.id =3)).nom_raccourci+"
4 -> "+ (commune first_with (each.id =4)).nom_raccourci +"

Et le montant octroyé. ",["id_commune":: 4, "amount" :: 10000]);
				if  between(int(values at "id_commune"),0,5) and int(values at "amount") > 0
				{
					commune cm <-commune first_with (each.id = int(values at "id_commune"));
					ask cm 
					{
						budget <- budget + int(values at "amount");
						ask network_agent
							{
							string msg <- ""+INFORM_GRANT_RECEIVED+COMMAND_SEPARATOR+world.getMessageID()+COMMAND_SEPARATOR+int(values at "amount");
							do send to:cm.network_name contents:msg;
							}
						not_updated <- true;
					}
				}
				}*/

			
/*if (nb_button = 2){
				// Bouton Amende
				map values <- user_input("Vous allez mettre une amende à une commune.
Choisissez le numéro de la commune :
1 -> "+ (commune first_with (each.id =1)).nom_raccourci+"
2 -> "+ (commune first_with (each.id =2)).nom_raccourci+"
3 -> "+ (commune first_with (each.id =3)).nom_raccourci+"
4 -> "+ (commune first_with (each.id =4)).nom_raccourci +"

Et le montant de l'amende. ",["id_commune":: 4, "amount" :: 10000]);
				if  between(int(values at "id_commune"),0,5) and int(values at "amount") > 0
				{
					commune cm <-commune first_with (each.id = int(values at "id_commune"));
					ask cm  {
				 		budget <- budget - int(values at "amount");
				 		ask network_agent
							{
							string msg <- ""+INFORM_FINE_RECEIVED+COMMAND_SEPARATOR+world.getMessageID()+COMMAND_SEPARATOR+int(values at "amount");
							do send to:cm.network_name contents:msg;
							}
				 		not_updated <- true;
				 }
				 
				}
				}*/
		}
		
		if(length(selected_UnAm_c)>0)
		{
			do clear_selected_button;
			ask (first(selected_UnAm_c))
			{
				is_selected <- true;
			}
			return;
		}
		
	}
	
	action button_click_carte_oleron 
	{
		point loc <- #user_location;
		buttons a_button <- first((buttons where (each distance_to loc < MOUSE_BUFFER)) where(each.nb_button = 4));
		if a_button != nil
		{
			ask a_button
			{
				is_selected <- not(is_selected);
				my_icon <-  is_selected ? image_file("../images/icones/avec_quadrillage.png") :  image_file("../images/icones/sans_quadrillage.png");
			}
		}
	}
	
	// NB Pas utilisé car remplacé par l'interface Leader
	/*action button_click_action
	{
		point loc <- #user_location;
		list<action_done> list_act <-  action_done overlapping loc; // agts of_species dike;
		
		if(length(list_act)>0)
		{
			map values <- user_input("Assigner un retard à cette action.
Nombre de tours de retard assigner ?",["nb":: 1]);
			ask first(list_act) {do assign_delay(int(values at "nb"));}
		}
	}*/
    
    //destruction de la sélection
    action clear_selected_button
	{
		previous_clicked_point <- nil;
		ask buttons
		{
			self.is_selected <- false;
		}
	}
	action save_budget_data
	{	add (commune first_with(each.id =1)).budget to: data_budget_C1  ;
		add (commune first_with(each.id =2)).budget to: data_budget_C2  ;
		add (commune first_with(each.id =3)).budget to: data_budget_C3  ;
		add (commune first_with(each.id =4)).budget to: data_budget_C4  ;
	}	
	
	action save_N_to_AU_data
	{	add count_N_to_AU_C1 to: data_count_N_to_AU_C1  ;
		add count_N_to_AU_C2 to: data_count_N_to_AU_C2  ;
		add count_N_to_AU_C3 to: data_count_N_to_AU_C3  ;
		add count_N_to_AU_C4 to: data_count_N_to_AU_C4  ;
		count_N_to_AU_C1 <-0;
		count_N_to_AU_C2 <-0  ;
		count_N_to_AU_C3 <-0  ;
		count_N_to_AU_C4 <-0;
	}	
	
	
}

/*
 * ***********************************************************************************************
 *                        ZONE de description des species
 *  **********************************************************************************************
 */

grid cell file: dem_file schedules:[] neighbours: 8 {	
		int cell_type <- 0 ; // 0 -> terre
		float water_height  <- 0.0;
		float max_water_height  <- 0.0;
		float soil_height <- grid_value;
		float soil_height_before_broken <- 0.0;
		float rugosity;
	
		init {
			if soil_height <= 0 {cell_type <-1;}  //  1 -> mer
			if soil_height = 0 {soil_height <- -5.0;}
			soil_height_before_broken <- soil_height;
			}
		aspect niveau_eau
		{
			if water_height < 0
			 {color<-#red;}
			if water_height >= 0 and water_height <= 0.01
			 {color<-#white;}
			if water_height > 0.01
			 { color<- rgb( 0, 0 , 255 - ( ((water_height  / 8) with_precision 1) * 255)) /* hsb(0.66,1.0,((water_height +1) / 8)) */;}
		}
		aspect elevation_eau
		{
			if cell_type = 1 
				{float tmp <-  ((soil_height  / 10) with_precision 1) * -170;
					color<- rgb( 80, 80 , 255 - tmp) ; }
			 else{
				if water_height = 0			
				{float tmp <-  ((soil_height  / 10) with_precision 1) * 255;
					color<- rgb( 255 - tmp, 180 - tmp , 0) ; }
				else
				 {float tmp <-  min([(water_height  / 5) * 255,200]);
				 	color<- rgb( 200 - tmp, 200 - tmp , 255) /* hsb(0.66,1.0,((water_height +1) / 8)) */; }
				 }
			}
		aspect elevation_eau_max
		{
			if cell_type = 1 
				{float tmp <-  ((soil_height  / 10) with_precision 1) * -170;
					color<- rgb( 80, 80 , 255 - tmp) ; }
			 else{
				if max_water_height = 0			
				{float tmp <-  ((soil_height  / 10) with_precision 1) * 255;
					color<- rgb( 255 - tmp, 180 - tmp , 0) ; }
				else
				 {float tmp <-  min([(max_water_height  / 5) * 255,200]);
				 	color<- rgb( 200 - tmp, 200 - tmp , 255) /* hsb(0.66,1.0,((water_height +1) / 8)) */; }
				 }
		}	
			
	}


species def_cote
{	
	int id_ouvrage;
	string nom_com;
	string type;
	string status;	//  "bon" "moyen" "mauvais"  
	float height;  // height au pied en mètre
	float alt;     // altitude de la crete de la digue
	rgb color <- # pink;
	list<cell> cells ;
	int cptStatus <-0;
	int rupture<-0;
	geometry zoneRupture<-nil;
	bool not_updated <- false;
	bool ganivelle <- false;
	float height_avant_ganivelle;
	string type_def_cote -> {type = 'Naturel'?"dune":"digue"};
	
	action init_from_map(map<string, unknown> a )
	{
		self.id_ouvrage <- int(a at "id_ouvrage");
		self.type <- string(a at "type");
		self.status <- string(a at "status");
		self.height <- float(a at "height");
		self.alt <- float(a at "alt");
		self.cptStatus <- int(a at "cptStatus");
		self.rupture <- int(a at "rupture");
		self.zoneRupture <- a at "zoneRupture";
		self.not_updated <- bool(a at "not_updated");
		self.ganivelle <- bool(a at "ganivelle");
		self.height_avant_ganivelle <- a at "height_avant_ganivelle";
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
	
	map<string,unknown> build_map_from_attribute
	{
		map<string,unknown> res <- [
			"OBJECT_TYPE"::"def_cote",
			"id_ouvrage"::string(id_ouvrage),
			"type"::string(type),
			"status"::string(status),
			"height"::string(height),
			"alt"::string(alt),
			"rupture"::string(rupture),
			"zoneRupture"::zoneRupture,
			"not_updated"::string(not_updated),
			"ganivelle"::string(ganivelle),
			"height_avant_ganivelle"::string(height_avant_ganivelle),
			"locationx"::string(location.x),
			"locationy"::string(location.y),
			"locationx1"::string(shape.points[0].x),   
			"locationy1"::string(shape.points[0].y),
			"locationx2"::string(shape.points[1].x),
			"locationy2"::string(shape.points[1].y)
			];
			point pp<-nil;
			int i <- 0;
			loop pp over:shape.points
			{
				put string(pp.x) key:"locationx"+i in: res;
				put string(pp.y) key:"locationy"+i in: res;
				i <- i+ 1;
			}
		return res;
	}
	
	
	
	
	action init_dike {
		if status = "" {status <- "bon";} 
		if type ='' {type <- "inconnu";}
		if status = '' {status <- "bon";} 
		if status = "tres bon" {status <- "bon";} 
		if status = "tres mauvais" {status <- "mauvais";} 
		if height = 0.0 {height  <- 1.5;}////////  Les ouvrages de défense qui n'ont pas de hauteur sont mis d'office à 1.5 mètre
		cptStatus <- type = 'Naturel'?rnd(STEPS_DEGRAD_STATUS_DUNE-1):rnd(STEPS_DEGRAD_STATUS_OUVRAGE-1);
		cells <- cell overlapping self;
		if type = 'Naturel' {height_avant_ganivelle <- height;}
	}
	
	action evolveStatus_ouvrage {
		cptStatus <- cptStatus +1;
		if cptStatus = (STEPS_DEGRAD_STATUS_OUVRAGE + 1) {
			cptStatus <-0;
			if status = "moyen" {status <- "mauvais";}
			if status = "bon" {status <- "moyen";}
			not_updated<-true; 
		}
	}

	action evolve_dune {
		if ganivelle {
			//Dynamique de la dune avec ganivelle 
			cptStatus <- cptStatus +1;
			if cptStatus = (STEPS_REGAIN_STATUS_GANIVELLE + 1) {
				cptStatus <-0;
				if status = "moyen" {status <- "bon";}
				if status = "mauvais" {status <- "moyen";}
				not_updated <- true; 
			}
			if height < height_avant_ganivelle + H_MAX_GANIVELLE {
				height <- height + H_DELTA_GANIVELLE;  // la ganivelle permet d'augmenter de 5 cm par an dans la limite de h_ganivelle
				alt <- alt + H_DELTA_GANIVELLE;
				ask cells {
					soil_height <- soil_height + H_DELTA_GANIVELLE;
					soil_height_before_broken <- soil_height ;
					}
				not_updated <- true;
			}
			else {//la dune a recouvert toute la hauteur de la ganivelle. On remet a zero le processus Ganivelle
				ganivelle <- false;
				not_updated<- true;}
			
		}
		else {
			//Dynamique de la dune sans ganivelle 
			cptStatus <- cptStatus +1;
			if cptStatus = (STEPS_DEGRAD_STATUS_DUNE + 1) {
				cptStatus <-0;
				if status = "moyen" {status <- "mauvais";}
				if status = "bon" {status <- "moyen";}
				not_updated<-true;  
			}
		}
	}
		
	action calcRupture {
		int p <- 0;
		if type != 'Naturel' and status = "mauvais" {p <- PROBA_RUPTURE_DIGUE_ETAT_MAUVAIS;}
		if type != 'Naturel' and status = "moyen" {p <- PROBA_RUPTURE_DIGUE_ETAT_MOYEN;}
		if type != 'Naturel' and status = "bon" {p <- PROBA_RUPTURE_DIGUE_ETAT_BON;}
		if type = 'Naturel' and status = "mauvais" {p <- PROBA_RUPTURE_DUNE_ETAT_MAUVAIS;}
		if type = 'Naturel' and status = "moyen" {p <- PROBA_RUPTURE_DUNE_ETAT_MOYEN;}
		if type = 'Naturel' and status = "bon" {p <- PROBA_RUPTURE_DUNE_ETAT_BON;}
		if rnd (100) <= p {
				set rupture <- 1;
				// on applique la rupture a peu pres au milieu du linéaire
				int cIndex <- int(length(cells) /2);
				// on défini la zone de rupture ds un rayon de 30 mètre autour du point de rupture 
				zoneRupture <- circle(30#m,(cells[cIndex]).location);
				// on applique la rupture sur les cells de cette zone
				ask cells overlapping zoneRupture  {
							if soil_height >= 0 {soil_height <-   max([0,soil_height - myself.height]);}
				}
				write "rupture "+type_def_cote+" n°" + id_ouvrage + "("+first((commune overlapping self)).nom_raccourci +", état " + status +", hauteur "+height+", alt "+alt +")"; 
		}
	}
	
	action removeRupture {
		rupture <- 0;
		ask cells overlapping zoneRupture {if soil_height >= 0 {soil_height <-   soil_height_before_broken;}}
		zoneRupture <- nil;
	}

	//La commune répare la digue
	action repair_by_commune (int a_commune_id) {
		status <- "bon";
		cptStatus <- 0;
		//ask commune first_with(each.id = a_commune_id) {do payerReparationOuvrage (myself);}
	}
	
	//La commune relève la digue
	action increase_height_by_commune (int a_commune_id) {
		status <- "bon";
		cptStatus <- 0;
		height <- height + 1; // le réhaussement d'ouvrage est forcément de 1 mètre / ds la V1 c'etait 50  centimètres
		alt <- alt + 1;
		ask cells {
			soil_height <- soil_height + 1;
			soil_height_before_broken <- soil_height ;
			}
		//ask commune first_with(each.id = a_commune_id) {do payerRehaussementOuvrage (myself);}
	}
	
	//la commune détruit la digue
	action destroy_by_commune (int a_commune_id) {
		ask cells {	soil_height <- soil_height - myself.height ;}
		//ask commune first_with(each.id = a_commune_id) {do payerDestructionOuvrage (myself);}
		do die;
	}
	
	//La commune construit une digue
	action new_dike_by_commune (int a_commune_id) {
		///  Une nouvelle digue réhausse tout le terrain à la hauteur de la cell la plus haute
		float h <- cells max_of (each.soil_height);
		alt <- h + height;
		ask cells  {
			soil_height <- h + myself.height; ///  Une nouvelle digue fait 1,5 mètre -> STANDARD_DIKE_SIZE
			soil_height_before_broken <- soil_height ;
		}
		//ask commune first_with(each.id = a_commune_id) {do payerConstructionOuvrage (myself);}
	}
	
	//La commune installe des ganivelles sur la dune
	action install_ganivelle_by_commune (int a_commune_id) {
		cptStatus <- 0;
		ganivelle <- true;
		write "INSTALL GANIVELLE";
		//ask commune first_with(each.id = a_commune_id) {do payerGanivelle (myself);}
	}
	
	
	aspect base
	{  	if type != 'Naturel'
			{switch status {
				match  "bon" {color <- # green;}
				match "moyen" {color <-  rgb (255,102,0);} 
				match "mauvais" {color <- # red;} 
				default { /*"casse" {color <- # yellow;}*/write "probleee status dike";}
				}
			draw 20#m around shape color: color size:300#m;
				}
		else {switch status {
				match  "bon" {color <- rgb (222, 134, 14,255);}
				match "moyen" {color <-  rgb (231, 189, 24,255);} 
				match "mauvais" {color <- rgb (241, 230, 14,255);} 
				default { write "probleee status dune";}
				}
			draw 50#m around shape color: color;
			if ganivelle {loop i over: points_on(shape, 40#m) {draw circle(10,i) color: #black;}} 
		}		
			
		if rupture  = 1 {draw (zoneRupture +70#m) color:rgb(240,20,20,200);} 	
	}
}



species road
{
	aspect base
	{
		draw shape color: rgb (125,113,53);
	}
}

species protected_area {
	string name;
	aspect base 
	{
		/*if (buttons_map first_with(each.command =ACTION_DISPLAY_PROTECTED_AREA)).is_selected
		{*/
		 draw shape color: rgb (185, 255, 185,120) border:#black;
		/*}*/
	}
}
species flood_risk_area {
	
	aspect base 
	{
		/*if (buttons_map first_with(each.command =ACTION_DISPLAY_FLOODED_AREA)).is_selected
		{*/
		 draw shape color: rgb (20, 200, 255,120) border:#black;
		/*}*/
	}
}

species coast_border_area {// zone des 400m littoral 
	
	aspect base 
	{
		 draw shape color: rgb (20, 100, 205,120) border:#black;
	}
}

species coast_dike_area {// zone pour identifier les rétro digues // celles qui ne sont pas ds la coast_dike_area  // on retien à 600m de bord de mer
	
	aspect base 
	{
		 draw shape color: rgb (100, 100, 205,120) border:#black;
	}
}

species UA
{
	string ua_name;
	int id;
	int ua_code;
	rgb my_color <- cell_color() update: cell_color();
	int nb_stepsForAU_toU <-1;// On doit mettre 1 pour en fait obtenir un délai de 3 ans (car il y a un tour décompté de chgt de A/N à AU et un autre de AU à U 
	int AU_to_U_counter <- 0;
	list<cell> cells ;
	int population ;
	string classe_densite -> {population =0?"vide":(population <40?"peu dense":(population <80?"densité intermédiaire":"dense"))};
	int cout_expro -> {round( population * 400* population ^ (-0.5))};
	bool isUrbanType -> {ua_name in ["U","Us","AU","AUs"] };
	bool isAdapte -> {ua_name in ["Us","AUs"]};
	bool isEnDensification <- false;
	bool not_updated <- false;
	bool pop_updated <- false;
	
	action init_from_map(map<string, unknown> a )
	{
		self.id <- int(a at "id");
		self.ua_name <- string(a at "ua_name");
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
	
	map<string,unknown> build_map_from_attribute
	{
		map<string,string> res <- [
			"OBJECT_TYPE"::"UA",
			"id"::string(id),
			"ua_name"::string(ua_name),
			"ua_code"::string(ua_code),
			"nb_stepsForAU_toU"::string(nb_stepsForAU_toU),
			"AU_to_U_counter"::string(AU_to_U_counter),
			"population"::string(population),
			"isEnDensification"::string(isEnDensification),
			"not_updated"::string(not_updated),
			"pop_updated"::string(pop_updated),
			"locationx"::string(location.x),
			"locationy"::string(location.y)
			];
			
			point pp<-nil;
			int i <- 0;
			loop pp over:shape.points
			{
				put string(pp.x) key:"locationx"+i in: res;
				put string(pp.y) key:"locationy"+i in: res;
				i<-i+1;
			}

		return res;
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
		
		
	action modify_UA (int a_id_commune, string new_ua_name)
	{	if  (ua_name in ["U","Us"])and new_ua_name = "N" /*expropriation */
				{	//ask commune first_with (each.id = a_id_commune) {do payerExpropriationPour (myself);}
					population <-0;
				}
		else {	//ask commune first_with (each.id = a_id_commune) {do payerModifUA (myself, new_ua_name);}
				if  ua_name = "N" and (new_ua_name in ["AU","AUs"]) /*dénaturalisation -> requière autorosation du prefet */
					{switch a_id_commune
					{	match 1 {world.count_N_to_AU_C1 <-world.count_N_to_AU_C1 +1;}
						match 2 {world.count_N_to_AU_C2 <-world.count_N_to_AU_C2 +1;}
						match 3 {world.count_N_to_AU_C3 <-world.count_N_to_AU_C3 +1;}
						match 4 {world.count_N_to_AU_C4 <-world.count_N_to_AU_C4 +1;}
					}
				}
		}
		ua_name <- new_ua_name;
		ua_code <- codeOfUAname(ua_name);
		
		//on affecte la rugosité correspondant aux cells
		float rug <- rugosityValueOfUA_name (ua_name);
		ask cells {rugosity <- rug;} 	
	}
	action apply_Densification (int a_id_commune) {
		//ask commune first_with (each.id = a_id_commune) {do payerModifUA (myself, "densification");}
		isEnDensification <-true;
	}	
	
	action evolve_AU_to_U
		{if ua_name in ["AU","AUs"]
			{AU_to_U_counter<-AU_to_U_counter+1;
			if AU_to_U_counter = (nb_stepsForAU_toU +1)
				{	AU_to_U_counter<-0;
					ua_name <- ua_name="AU"?"U":"Us";
					ua_code<-codeOfUAname(ua_name);
					not_updated<-true;
					do assign_pop (POP_FOR_NEW_U);
				}
			}	
		}
	action evolve_U_densification {
		if !pop_updated and isEnDensification and (ua_name in ["U","Us"]){
			string previous_d_classe <- classe_densite; 
			do assign_pop (POP_FOR_U_DENSIFICATION);
			if previous_d_classe != classe_densite {isEnDensification <- false;}
				}
	}
		
	action evolve_U_standard {
		if !pop_updated and (ua_name in ["U","Us"]){
			do assign_pop (POP_FOR_U_STANDARD);
			}
	}	
	
	action assign_pop (int nbPop) 
	{ if new_comers_still_to_dispatch > 0 {
			population <- population + nbPop;
			new_comers_still_to_dispatch <- new_comers_still_to_dispatch - nbPop;
			not_updated<-true;
			pop_updated <- true;
		}
	}
	
	float rugosityValueOfUA_name (string a_ua_name) 
		{float val <- 0.0;
		 switch (a_ua_name)
			{
				match "N" {val <- 0.11;}	//  Ds la V1 c'était 0.05 mais selon MA et NB ce n'était pas cohérent car N est sensé freiner l'inondation. Selon MA et NB c'est  0.11
				match "U" {val <- 0.05;}	//  Ds la V1 c'était 0.12 mais selon MA et NB ce n'était pas cohérent car U est sensé faire glisser l'eau. Selon MA et NB c'est 0.05
				match "AU" {val <- 0.09;} 	//  Ds la V1 c'était 0.1 mais selon MA et NB ce n'était pas cohérent car AU n'est pas sensé freiner autant l'eau que N. Selon MA et NB c'est 0.09							->selon MA et NB  0.09
				match "A" {val <- 0.07;}	// Ds la V1 c'était 0.06 mais selon MA et NB ce n'était pas cohérent car le A d'oélron correspond plus à Landes (code CLC 322) ou Vignes (code CLC 221) qui font 0.07, et pas vraiement à Prairies (code CLC 241)  qui fait 0.04. Selon MA et NB c'est 0.07
				match "AUs" {val <- 0.09;}  // Selon MA et NB et la CdC, l'habitat adapté va freiner un peu l'inondation. Donc 0.09
				match "Us" {val <- 0.09;}   // Selon MA et NB et la CdC, l'habitat adapté va freiner un peu l'inondation. Donc 0.09
			}
		return val;}

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
		if isAdapte {draw "A" color:#black;}
		if isEnDensification {draw "D" color:#black;}
	}
	aspect population 
	{
		rgb acolor <- nil;
		switch population {
			 match 0 {acolor <- # white; }
	/*match_between [1 , 20] {acolor <- listC[0]; }
			 match_between [20 , 40] {acolor <- listC[1]; }*/
			 match_between [1 , 20] {acolor <- listC[2]; }
			 match_between [20 , 40] {acolor <- listC[3]; }
			 match_between [40 , 60] {acolor <- listC[4]; }
			 match_between [60 , 80] {acolor <- listC[5]; }
			 match_between [80 , 100] {acolor <- listC[6]; }
			 match_between [100 , 4000] {acolor <- listC[7]; }
			 default {acolor <- #yellow; }
		}
		draw shape color: acolor;
		
	}

	aspect densite_pop 
	{
		rgb acolor <- nil;
		switch classe_densite {
			match "vide" {acolor <- # white; }
			match "peu dense" {acolor <-  rgb( 253, 189, 131 ); }
			match "densité intermédiaire" {acolor <- rgb( 238, 101, 16 ) ;}
			match "dense" {acolor <- rgb( 127, 39, 4 ) ;}
			default "peu dense" {acolor <- # yellow; }
			}
		draw shape color: acolor;
		
	}
	aspect conditional_outline
	{
		if (buttons first_with(each.nb_button=4)).is_selected
		{
		 draw shape color: rgb (0,0,0,0) border:#black;
		}
	}
}


species commune
{	
	int id<-0;
	bool not_updated<- true;
	string nom_raccourci;
	string network_name;
	int budget;
	int impot_recu <-0;
	bool subvention_habitat_adapte <- false;
	list<UA> UAs ;
	list<cell> cells ;
	float impot_unit <- 0.42; // 0.42 correspond à  21 € / hab convertit au taux de la monnaie du jeu (le taux est de 50)   // comme construire une digue dans le jeu vaut 20 alors que ds la réalité ça vaut 1000 , -> facteur 50  -> le impot_unit = 21/50= 0.42 
	
	/* initialisation des hauteurs d'eau */ 
	float U_0_5c <-0.0;	float U_1c <-0.0;	float U_maxc <-0.0;
	float AU_0_5c <-0.0; float AU_1c <-0.0; float AU_maxc <-0.0;
	float A_0_5c <-0.0;	float A_1c <-0.0;	float A_maxc <-0.0;
	float N_0_5c <-0.0;	float N_1c <-0.0;	float N_maxc <-0.0;
	float surface_inondee <- 0.0;
	list<float> data_surface_inondee <- [];

	aspect base
	{
		draw shape color:#whitesmoke;
	}
	
	aspect outline
	{
		draw shape color: rgb (0,0,0,0) border:#black;
	}
	
	int current_population (commune aC){
		return sum(aC.UAs accumulate (each.population));
	}
	
	action informerNumTour {
		ask network_agent
		{
			string msg <- ""+INFORM_ROUND+COMMAND_SEPARATOR+world.getMessageID()+COMMAND_SEPARATOR+round;
			do send to:myself.network_name contents:msg;
		}
	}
	
	action recevoirImpots {
		impot_recu <- current_population(self) * impot_unit;
		budget <- budget + impot_recu;
		write nom_raccourci + "->" + budget;
		ask network_agent
		{
			string msg <- ""+INFORM_TAX_GAIN+COMMAND_SEPARATOR+world.getMessageID()+COMMAND_SEPARATOR+myself.impot_recu+COMMAND_SEPARATOR+round;
			do send to:myself.network_name contents:msg;
		}
		not_updated <- true;
	}
	
	action pay_for_action_done (action_done aAction)
			{
				budget <- budget - aAction.cost;
				not_updated <- true;
	}
				
	/*action payerExpropriationPour (UA a_UA)
			{
				budget <- budget - a_UA.cout_expro;
				not_updated <- true;
			}
			
	action payerModifUA (UA a_UA, string new_ua_name)
			{
				int cost<-0; 
				switch (new_ua_name)
					{
						match "A" {cost <-ACTION_COST_LAND_COVER_TO_A;}
						match "AU" {cost <-ACTION_COST_LAND_COVER_TO_AU;}
						match "N" {	
							if a_UA.ua_name = "AU" {cost <-ACTION_COST_LAND_COVER_FROM_AU_TO_N;}
							if a_UA.ua_name = "A" {cost <-ACTION_COST_LAND_COVER_FROM_A_TO_N;}	}
						match "Us" {cost <-ACTION_COST_LAND_COVER_TO_Us;}
						match "AUs" {cost <-a_UA.ua_name = "AU"?ACTION_COST_LAND_COVER_TO_Us:ACTION_COST_LAND_COVER_TO_AUs;}
						match "densification" {cost <-ACTION_COST_LAND_COVER_TO_Ui;}
					}
				if cost = 0 {write "Problème cout change UA : cout de 0 ; passade de "+  a_UA.ua_name + " à "+new_ua_name;}
				budget <- budget - cost;
				not_updated <- true;
			}
 
			
	action payerReparationOuvrage (def_cote dk)
			{
				budget <- budget - (int(dk.shape.perimeter) * ACTION_COST_DIKE_REPAIR);
				not_updated <- true;
			}
			
	action payerRehaussementOuvrage (def_cote dk)
			{
				budget <- budget - (int(dk.shape.perimeter) * ACTION_COST_DIKE_RAISE);
				not_updated <- true;
			}

	action payerDestructionOuvrage (def_cote dk)
			{
				budget <- budget - (int(dk.shape.perimeter) * ACTION_COST_DIKE_DESTROY);
				not_updated <- true;
			}	
					
	action payerConstructionOuvrage (def_cote dk)
			{
				budget <- budget - (int(dk.shape.perimeter) * ACTION_COST_DIKE_CREATE);
				not_updated <- true;
			}	
			
	action payerGanivelle (def_cote dk)
			{
				budget <- budget - ((int(dk.shape.perimeter)) * ACTION_COST_INSTALL_GANIVELLE);
				not_updated <- true;
			}*/					
}

// Definition des boutons générique
species buttons
{
	int command <- -1;
	int nb_button <- nil;
	string display_name <- "no name";
	string label <- "no name";
	bool is_selected <- false;
	geometry shape <- square(500#m);
	image_file my_icon;
	aspect buttons_C_mdj
	{
		if( display_name = UNAM_DISPLAY_c)
		{
			draw shape color:#white border: is_selected ? # red : # white;
			draw my_icon size:button_size-50#m ;
		}
	}
	aspect buttons_carte_oleron
	{
		if( nb_button = 4)
		{
			draw shape color:#white border: is_selected ? # red : # white;
			draw my_icon size:800#m ;
		}
	}
}



/*
 * ***********************************************************************************************
 *                        EXPERIMENT DEFINITION
 *  **********************************************************************************************
 */

experiment oleronV2 type: gui {
	float minimum_cycle_duration <- 0.5;
	parameter "Log user action" var:log_user_action<- true;
	parameter "Connect ActiveMQ" var:activemq_connect<- true;
	output {
		inspect world;
		
		display carte_oleron //autosave : true
		{
			grid cell ;
			species cell aspect:elevation_eau;
			species commune aspect:outline;
			species road aspect:base;
			species def_cote aspect:base;
			species UA aspect: conditional_outline;
			 // Les boutons et le clique
			species buttons aspect:buttons_carte_oleron;
			event [mouse_down] action: button_click_carte_oleron;
		}
		display Amenagement
		{
			species commune aspect: base;
			species UA aspect: base;
			species road aspect:base;
			species def_cote aspect:base;
			species coast_dike_area aspect: base;
			species coast_border_area aspect: base;		
		}
		display carte_oleron_water_max
		{
			grid cell ;
			species cell aspect:elevation_eau_max;
			species commune aspect:outline;
			species road aspect:base;
			species def_cote aspect:base;
			
		}
		display Population
		{	
			species UA aspect: population;
			species road aspect:base;
			species commune aspect: outline;			
		}
		
		display "Densité de population"
		{	
			species UA aspect: densite_pop;
			species road aspect:base;
			species commune aspect: outline;			
		}
		display "Controle MdJ"
		{    // Les boutons et le clique
			species buttons aspect:buttons_C_mdj;
			event mouse_down action: button_click_C_mdj;
			}
			
		display graph_budget {
				chart "Graphe des budgets" type: series {
					datalist value:[data_budget_C1,data_budget_C2,data_budget_C3,data_budget_C4] color:[#red,#blue,#green,#black] legend:((commune where (each.id > 0)) sort_by (each.id)) collect each.nom_raccourci; 			
				}
			}
			
		display "Chgt de N à AU" {
				chart "Changement de N à AU" type: series {
					datalist value:[data_count_N_to_AU_C1,data_count_N_to_AU_C2,data_count_N_to_AU_C3,data_count_N_to_AU_C4] color:[#red,#blue,#green,#black] legend:((commune where (each.id > 0)) sort_by (each.id)) collect each.nom_raccourci; 			
				}
			}
		display Barplots {
                
/*				chart "Zone U" type: histogram background: rgb("white") size: {0.5,0.4} position: {0, 0} {
					datalist value:[(((commune where (each.id > 0)) sort_by (each.id)) collect each.U_0_5c),(((commune where (each.id > 0)) sort_by (each.id)) collect each.U_1c),(((commune where (each.id > 0)) sort_by (each.id)) collect each.U_maxc)] 
						style:stack legend:[" < 0.5m","0.5 - 1m","+1m"] categoriesnames:(((commune where (each.id > 0)) sort_by (each.id)) collect each.nom_raccourci); 	
						
				}
				chart "Zone AU" type: histogram background: rgb("white") size: {0.5,0.4} position: {0.5, 0} {
					datalist value:[(((commune where (each.id > 0)) sort_by (each.id)) collect each.AU_0_5c),(((commune where (each.id > 0)) sort_by (each.id)) collect each.AU_1c),(((commune where (each.id > 0)) sort_by (each.id)) collect each.AU_maxc)] 
						style:stack legend:[" < 0.5m","0.5 - 1m","+1m"] categoriesnames:(((commune where (each.id > 0)) sort_by (each.id)) collect each.nom_raccourci); 	
						
				}
				chart "Zone A" type: histogram background: rgb("white") size: {0.5,0.4} position: {0, 0.5} {
					datalist value:[(((commune where (each.id > 0)) sort_by (each.id)) collect each.A_0_5c),(((commune where (each.id > 0)) sort_by (each.id)) collect each.A_1c),(((commune where (each.id > 0)) sort_by (each.id)) collect each.A_maxc)] 
						style:stack legend:[" < 0.5m","0.5 - 1m","+1m"] categoriesnames:(((commune where (each.id > 0)) sort_by (each.id)) collect each.nom_raccourci); 	
						
				}
				chart "Zone N" type: histogram background: rgb("white") size: {0.5,0.4} position: {0.5, 0.5} {
					datalist value:[(((commune where (each.id > 0)) sort_by (each.id)) collect each.N_0_5c),(((commune where (each.id > 0)) sort_by (each.id)) collect each.N_1c),(((commune where (each.id > 0)) sort_by (each.id)) collect each.N_maxc)] 
						style:stack legend:[" < 0.5m","0.5 - 1m","+1m"] categoriesnames:(((commune where (each.id > 0)) sort_by (each.id)) collect each.nom_raccourci); 	
						
				}
				 */
			}
			
		display "VIDE"
		{
			
		}	
		display "Surface inondée par commune" {
				chart "Surface inondée par commune" type: series {
					datalist value:length(commune) = 0 ? [0,0,0,0]:[((commune first_with(each.id = 1)).data_surface_inondee),((commune first_with(each.id = 2)).data_surface_inondee),((commune first_with(each.id = 3)).data_surface_inondee),((commune first_with(each.id = 4)).data_surface_inondee)] color:[#red,#blue,#green,#black]  legend:(((commune where (each.id > 0)) sort_by (each.id)) collect each.nom_raccourci); 			
				}
			}
			
		// NB Pas utilsé car remplacé par l'interface Leader
		/*display "Liste Actions"
		{
			species action_done aspect: base;
			//species highlight_action_button aspect:base;
			event [mouse_down] action: button_click_action ;

		}*/
			}}
		

/**
 *  littoSIM_GEN
 *  Author: Brice, Cécilia, Elise, Etienne, Fredéric, Marion, Nicolas B, Nicolas M, Xavier 
 * 
 *  Description : LittoSim est  un jeu sérieux qui se présente sous la forme d’une simulation intégrant à la fois 
 *  un modèle de submersion marine, la modélisation de différents rôles d’acteurs agissant sur le territoire 
 *  et la possibilité de mettre en place différents scénarios de prévention des submersions qui seront contrôlés
 *  par les utilisateurs de la simulation en fonction de leur rôle. 
 */

model littoSIM_GEN



global  {
	
//////// CONFIG OLERON
	// Prix des actions et durée de mis en oeuvre des actions
	matrix<string> all_action_cost <- matrix<string>(csv_file("../includes/cout_action.csv",";"));	
	matrix<string> all_action_delay <- matrix<string>(csv_file("../includes/delai_action.csv",";"));	
	matrix<string> actions_def <- matrix<string>(csv_file("../includes/actions_def.csv",";"));	
	
	// Chargements des données SIG
	file communes_shape <- file("../includes/zone_etude/communes.shp");
	file road_shape <- file("../includes/zone_etude/routesdepzone.shp");
	file zone_protegee_shape <- file("../includes/zone_etude/zps_sic.shp");
	file zone_PPR_shape <- file("../includes/zone_etude/PPR_extract.shp");
	file coastline_shape <- file("../includes/zone_etude/trait_cote.shp");
	file defenses_cote_shape <- file("../includes/zone_etude/defense_cote_littoSIM-05122015.shp");
	file unAm_shape <- file("../includes/zone_etude/zones241115.shp");	
	file emprise_shape <- file("../includes/zone_etude/emprise_ZE_littoSIM.shp"); 
	file dem_file <- file("../includes/zone_etude/oleron_dem2016.asc") ;
	file contour_ile_moins_100m_shape <- file("../includes/zone_etude/contour_ile_moins_100m.shp");
	int nb_cols <- 631;
	int nb_rows <- 906;
	
	// Paramètres des dynamique de Population
	float ANNUAL_POP_GROWTH_RATE <- 0.009;
	
	
//////// PARAMETRES DES MODULES  
  ////  Module Digues
	// Paramètres des actions de construction et réhaussement de digue
	string BUILT_DIKE_STATUS <- "bon"; // status de nouvelle digue
	float  STANDARD_DIKE_SIZE <- 1.5#m; ////// hauteur d'une nouvelle digue	
	
	// Paramètres  de la dynamique d'évolution des défenses côtes (défense côte = digues et dunees)
	float H_MAX_GANIVELLE <- 1.2; // ganivelle  d'une hauteur de 1.2 metres  -> fixe le maximum d'augmentation de hauteur de la dune
	float H_DELTA_GANIVELLE <- 0.05 ; // une ganivelle  augmente de 5 cm par an la hauteur du cordon dunaire
	int STEPS_DEGRAD_STATUS_OUVRAGE <- 8; // Sur les ouvrages il faut 8 ans pour que ça change de statut
	int STEPS_DEGRAD_STATUS_DUNE <-6; // Sur les dunes, sans ganivelle,  il faut 6 ans pour que ça change de statut
	int STEPS_REGAIN_STATUS_GANIVELLE  <-3; // Avec une ganivelle ça se régénère 2 fois plus vite que ça ne se dégrade

	// Paramètres des ruptures des défenses côtes
	int PROBA_RUPTURE_DIGUE_ETAT_MAUVAIS <- 13;
	int PROBA_RUPTURE_DIGUE_ETAT_MOYEN <- 6;
	int PROBA_RUPTURE_DIGUE_ETAT_BON <- -1; // si -1, alors  impossible
	int PROBA_RUPTURE_DUNE_ETAT_MAUVAIS <- 8;
	int PROBA_RUPTURE_DUNE_ETAT_MOYEN <- 4;
	int PROBA_RUPTURE_DUNE_ETAT_BON <- -1; // si -1, alors  impossible
	int radius_rupture <- 30; // en mètres. Etendu de la rupture sur l'éléments

  ////  Module Croissance démographique
	int POP_FOR_NEW_U <- 3 ; // Nb initial d'habitants pour les cases qui viennent de passer de AU à U
	int POP_FOR_U_DENSIFICATION <- 10 ; // Nb de nouveaux habitants par tour pour les cases qui ont une action densification
	int POP_FOR_U_STANDARD <- 1 ; // Nb de nouveaux habitants par tour pour les autres cases 	
	
	
//////// CONFIG LITTOSIM_GEN
	// Paramètres de Communication Network 
	string SERVER <- "localhost"; 
	string COMMAND_SEPARATOR <- ":";
	string GAME_LEADER <- "GAME_LEADER";
	string GAME_MANAGER <- "GAME_MANAGER";
	string MSG_FROM_LEADER <- "MSG_FROM_LEADER";
	string GROUP_NAME <- "Oleron";
	string UPDATE_ACTION_DONE <- "update_action_done";
	string OBSERVER_MESSAGE_COMMAND <- "observer_command";

	// Chemin d'accès a lisflood sur la machine
	string lisfloodPath <- "C:/lisflood-fp-604/"; // chemin absolu du répertoire lisflood sur la machine  
	string lisfloodRelativePath <- "../../../../../../lisflood-fp-604/"; // chemin relatif (par rapport au fichier gaml) de répertoire lisflood sur la machine 
	string current_lisflood_rep <- "results"; // nom du répertoire de sauvegarde des résultats de simu de lisflood
	string lisflood_bat <- "lisflood_oleron_current.bat" ; // Nom de l'executable lisflood
	string conf_Xynthia_listflood <- "oleron2016_Xynthia"+timestamp+".par";

	// Paramètres des interfaces utilisateur
	float button_size <- 2000#m;
	float MOUSE_BUFFER <- 50#m; // zone considéré autour de l'endroit où l'on clic pour repérer si un bouton de l'interface a été cliqué 
	int font_size <- int(shape.height/30); 	// Police de caractère de l'interface de suivi des actions
	int font_interleave <- int(shape.width/60);  // Police de caractère de l'interface de suivi des actions
	 
	//  Sauvegarde des résultats dans un fichier SIG au format SHP
	string resultats <- "resultats.shp"; //	nom du fichier de de sauvegarde des résultats en format shp (attention, cela ecrase a chaque fois le resultat precedent)
	int cycle_sauver <- 100; //cycle à laquelle les resultats sont sauvegardés au format shp

	// Paramètres pour la sauvegarde des logs (permet de définir les noms des fichiers de sauvegarde)
	string LOG_FILE_NAME <- "log_"+machine_time+"csv";
	float START_LOG <- machine_time;
	string atelierDEM <- "oleron_dem2016" ; //Nom du fichier d'altirtude envoyer a lisflood pour submersion 
	string atelier_rugosityGrid <- lisfloodRelativePath+"oleron_n2016" + timestamp + ".asc";
	// Divers paramètres
	string BUILT_DIKE_TYPE <- "nouvelle digue"; // Type de nouvelle digue


//////// PARAMETRES UTILISATEURS
	// Sauvegarde des logs des joueurs : OUI / NON
	bool log_user_action <- true;

	// Sauvegarde des résultats au format SHP : OUI / NON
	bool sauver_shp <- false ; // si vrai on sauvegarde le resultat dans un shapefile de manière récurrente.  La  récurrence est réglée par la paramètre 'cycle_sauver

	// Paramètre utilisé pour une tentative infructueuse de permettre à l'utilisateur de lancer la simulation sans activemq : OUI / NON
	bool activemq_connect <- false; 

	
//////// VARIABLES D'OPERATION
	// Definition de l'enveloppe SIG de travail
	geometry shape <- envelope(emprise_shape);
	
	// Définition de géométries agrégeant  plusieurs polygones   
	geometry all_flood_risk_area;
	geometry all_protected_area;	

	// Variables d'opération de Communication Network 
	int messageID <- 0;
		
	// Variables d'état de l'étape en cours de la simulation 	
	string stateSimPhase <- 'not started'; // stateSimPhase defines the currrent phase of the simulation {'not started' 'game' 'execute lisflood' 'show lisflood' , 'calculate flood stats' and 'show flood stats'} 
	
	// Codification des actions pour Communication Network 
	//Liste de l'ensemble des messages possibles à envoyer via Communication Network
	list<int> ACTION_LIST <- [CONNECTION_MESSAGE,REFRESH_ALL,ACTION_REPAIR_DIKE,ACTION_CREATE_DIKE,ACTION_DESTROY_DIKE,ACTION_RAISE_DIKE,ACTION_INSTALL_GANIVELLE,ACTION_MODIFY_LAND_COVER_AU,ACTION_MODIFY_LAND_COVER_AUs,ACTION_MODIFY_LAND_COVER_A,ACTION_MODIFY_LAND_COVER_U,ACTION_MODIFY_LAND_COVER_Us,ACTION_MODIFY_LAND_COVER_Ui,ACTION_MODIFY_LAND_COVER_N];int ACTION_REPAIR_DIKE <- 5;
	// Liste des actions avec leur code correspondant
	int ACTION_MODIFY_LAND_COVER_AU <- 1;
	int ACTION_MODIFY_LAND_COVER_A <- 2;
	int ACTION_MODIFY_LAND_COVER_U <- 3;
	int ACTION_MODIFY_LAND_COVER_N <- 4;
	int ACTION_CREATE_DIKE <- 6;
	int ACTION_DESTROY_DIKE <- 7;
	int ACTION_RAISE_DIKE <- 8;
	int ACTION_LAND_COVER_UPDATE<-9;
	int ACTION_DIKE_UPDATE<-10;
	int VALIDATION_ACTION_MODIFY_LAND_COVER_AU <- 11; // Not used. Should detele ?
	int VALIDATION_ACTION_MODIFY_LAND_COVER_A <- 12;// Not used. Should detele ?
	int VALIDATION_ACTION_MODIFY_LAND_COVER_U <- 13;// Not used. Should detele ?
	int VALIDATION_ACTION_MODIFY_LAND_COVER_N <- 14;// Not used. Should detele ?
	int ACTION_DIKE_CREATED <- 16;
	int ACTION_DIKE_DROPPED <- 17;
	int UPDATE_BUDGET <- 19;
	int REFRESH_ALL <- 20;
	int ACTION_DIKE_LIST <- 21;
	int CONNECTION_MESSAGE <- 23;
	int INFORM_TAX_GAIN <-24;
	int INFORM_GRANT_RECEIVED <-27;
	int INFORM_FINE_RECEIVED <-28;
	int ACTION_INSTALL_GANIVELLE <- 29;
	int ACTION_MODIFY_LAND_COVER_AUs <-31;	
	int ACTION_MODIFY_LAND_COVER_Us <-32;
	int INFORM_ROUND <-34;
	int NOTIFY_DELAY <-35;
	int ENTITY_TYPE_CODE_DEF_COTE <-36;
	int ENTITY_TYPE_CODE_UA <-37;
	int ACTION_DONE_APPLICATION_ACKNOWLEDGEMENT <- 51;
	int ACTION_ACTION_DONE_UPDATE<- 101;
	int ACTION_ACTION_LIST <- 211;
	int ACTION_MODIFY_LAND_COVER_Ui <-311;
	int ACTION_EXPROPRIATION <- 9999; // codification spéciale car en fait le code n'est utilisé que pour aller chercher le delai d'exection dans le fichier csv

	// Récupération des couts du fichier cout_action dans des variables 	
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
	
	// Tableau des données de budget des communes pour tracer le graph d'évolution des budgets
	list<int> data_budget_C1 <- [];
	list<int> data_budget_C2 <- [];
	list<int> data_budget_C3 <- [];	
	list<int> data_budget_C4 <- [];
	int count_N_to_AU_C1 <-0;
	int count_N_to_AU_C2 <-0;
	int count_N_to_AU_C3 <-0;	
	int count_N_to_AU_C4 <-0;

	// Variable de calcul de la dynamique de Pop
	int new_comers_still_to_dispatch <- 0;

	// Variables de calcul pour la sauvegarde et lecture des simulations de lisflood 
	map<string,string> list_flooding_events ;  // listing des répertoires des innondations de la partie
	int lisfloodReadingStep <- 9999999; // lisfloodReadingStep is used to indicate to which step of lisflood results, the current cycle corresponds //  lisfloodReadingStep = 9999999 it means that their is no lisflood result corresponding to the current cycle 
	string timestamp <- ""; // variable utilisée pour spécifier un nom unique au répertoire de sauvegarde des résultats de simulation de lisflood
	string flood_results <- "";   //  text of flood results per commune   // la variable flood_results est sauvegardé sous forme de fichier txt

    // Variables d'opérations des interfaces
    string UNAM_DISPLAY_c <- "UnAm";
	string active_display <- nil;
	point previous_clicked_point <- nil;
    bool show_max_water_height<- false ;// defines if the water_height displayed on the map should be the max one or the current one
    
	// Divers variables de calcul
	int round <- 0;
	list<commune> communes_en_jeu;
	list<rgb> listC <- brewer_colors("YlOrRd",8);
	action_done current_action <- nil; // Check if it is really used or not
	
	
//////// NON CLASSE	
	list<UA> agents_to_inspect update: 10 among UA;	 // // Not used. Should detele ?
	int borderBuffer <- 400; // Unit =  meter. It's buffer distance add to the costal border to "see the sea."
	int minPopUArea <- 10; // Unit = abs pop. This is a trick to cancel an error made by a division by zero
	int pctBudgetInit <- 20; ///Unit = int in %. During the initialization phase, each commune initiate with a budget equal to an annual tax +  % here 20%
	float rehaussement <- 1.0; // en mètres ? le réhaussement d'ouvrage est forcément de 1 mètre / ds la V1 c'etait 50  centimètres
	
	
/////////////////////////////////////////////////////////////////////////////////////////////////////


init
	{
		create data_retreive number:1;
		
		loop i from: 0 to: (length(listC)-1)  {
		listC[i] <- blend (listC[i], #red , 0.9);
		}
		
		if activemq_connect {
			create network_round_manager number:1;
			create network_listen_to_leader number:1;
			create network_player number:1 ;
			create network_activated_lever number: 1;
		}
		
		do implementation_tests;
		/* initialisation du bouton */
		do init_buttons;
		stateSimPhase <- 'not started';
		do addElementIn_list_flooding_events ("Submersion initiale","results");
		/*Creation des agents a partir des données SIG */
		create def_cote from:defenses_cote_shape  with:[dike_id::int(read("OBJECTID")),type::string(read("Type_de_de")), status::string(read("Etat_ouvr")), alt::float(get("alt")), height::float(get("hauteur")), commune_name_shpfile::string(read("Commune"))
		];
		
		create commune from:communes_shape with: [commune_name::string(read("NOM_RAC")),id::int(read("id_jeu"))]
		{
			write " commune " + commune_name + " "+id;
		}
		create road from: road_shape;
		create protected_area from: zone_protegee_shape with: [name::string(read("SITENAME"))];
		all_protected_area <- union(protected_area);
		create flood_risk_area from: zone_PPR_shape;
		all_flood_risk_area <- union(flood_risk_area);
		create coast_border_area from: coastline_shape {
			shape <-  shape + borderBuffer #m; }
		create inland_dike_area from: contour_ile_moins_100m_shape;
		
		create UA from: unAm_shape with: [id::int(read("FID_1")),ua_code::int(read("grid_code")), population:: int(get("Avg_ind_c"))/*, cout_expro:: int(get("coutexpr"))*/]
		{
			ua_name <- nameOfUAcode(ua_code);
			my_color <- cell_color();
			if ua_name = "U" and population = 0 {
					population <- minPopUArea;}
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
			budget <- current_population(self) * impot_unit * (1 +  pctBudgetInit/100);
			write commune_name +" budget initial : " + budget;
			do calculate_indicators_t0;
		}
		ask def_cote {do init_dike;}
		
		communes_en_jeu <- (commune where (each.id > 0)) sort_by (each.id);
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
	
string commune_name_shpfile_of_commune_name (string a_commune_name)
{
		switch (a_commune_name)
			{
			match "lechateau" {return "Le-Chateau-d'Oleron";}
			match "dolus" {return "Dolus-d'Oleron";}
			match "sttrojan" { return "Saint-Trojan-Les-Bains";}
			match "stpierre" {return "Saint-Pierre-d'Oleron";}
			default {return "";}
			}
}  
		 
	 
int current_total_population {
	return sum(commune where (each.id > 0) accumulate (each.current_population(each)));
	}
	
int new_comers_to_dispatch {
	return round(current_total_population() * ANNUAL_POP_GROWTH_RATE);
}


action new_round{
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
			do calcul_impots;
			}}
	else {stateSimPhase <- 'game'; write stateSimPhase;}
	round <- round + 1;
	ask commune {do inform_new_round;} 
	ask network_listen_to_leader{do informLeader_round_number;}
	do save_budget_data;
	write "done!";
	} 	
	
int commune_id(string xx)
	{
		commune m <- commune first_with(each.network_name = xx);
		if(m = nil)
		{
			m <- (commune first_with (xx contains each.commune_name ));
			m.network_name <- xx;
		}
		return	 m.id;
	}

reflex show_flood_stats when: stateSimPhase = 'show flood stats'
	{// fin innondation
		// affichage des résultats 
		write flood_results;
		save flood_results to: "flood_results-"+machine_time+"-Tour"+round+".txt" type: "text";

		map values <- user_input(["Cliquez sur OK pour continuer" :: ""]);
		
		// remise à zero des hauteurs d'eau
		loop r from: 0 to: nb_rows -1  {
						loop c from:0 to: nb_cols -1 {cell[c,r].water_height <- 0.0;} 
						}
		// annulation des ruptures de digues				
		ask def_cote {if rupture = 1 {do removeRupture;}}
		// redémarage du jeu
		if round = 0
		{
			stateSimPhase <- 'not started';
			write stateSimPhase;
		}
		else
		{
			stateSimPhase <- 'game';
			write stateSimPhase + " - Tour "+round;
		}
	}
	
reflex calculate_flood_stats when: stateSimPhase = 'calculate flood stats'
	{// fin innondation
		// calcul des résultats 
		do calculate_communes_results;
		stateSimPhase <- 'show flood stats';
		write stateSimPhase;
		}
		
reflex show_lisflood when: stateSimPhase = 'show lisflood'
	{
		// lecture des fichiers innondation
		do readLisflood;
		
	}

action replay_flood_event
{
	string txt;
	int i <-1;
	loop aK over: list_flooding_events.keys
	{
		txt<- txt + "\n"+i+" :"+aK;
		i <-i +1;
	}
	map values <- user_input("Indiquer le numéro de la submersion que vous voulez réafficher" +txt,
						[	"Numéro :" :: "0"]);
	map<string, unknown> msg <-[];
	i <- int(values["Numéro :"]);
	if i=0 or i > length(list_flooding_events.keys){return;}
	
				
	string replayed_flooding_event  <- (list_flooding_events.keys)[i-1] ;
	write replayed_flooding_event;
	loop r from: 0 to: nb_rows -1  { loop c from:0 to: nb_cols -1 {cell[c,r].max_water_height <- 0.0; } } // remise à zero de max_water_height
	set lisfloodReadingStep <- 0;
	current_lisflood_rep <- list_flooding_events at replayed_flooding_event;
	stateSimPhase <- 'show lisflood'; write stateSimPhase;
	do readLisflood;
}		
action launchFlood_event (string eventName)
	{
		if round = 0 
		{
			map values <- user_input(["La simulation n'a pas encore commencée" :: ""]);
	     			write stateSimPhase;
		}
		// faire un tour juste avant de déclencher l'innondation
		// l'innondation à lieu en Janvier (début d'année), juste après le changement d'année civile (le tour change au 31 déc)
		if round != 0 {	do new_round; }
		// déclenchement innondation
		stateSimPhase <- 'execute lisflood';	write stateSimPhase;
		if round != 0 {
			loop r from: 0 to: nb_rows -1  { loop c from:0 to: nb_cols -1 {cell[c,r].max_water_height <- 0.0; } } // remise à zero de max_water_height
			ask def_cote {do calcRupture;} 
			do executeLisflood(eventName); // comment this line if you only want to read already existing results
		} 
		set lisfloodReadingStep <- 0;
		stateSimPhase <- 'show lisflood'; write stateSimPhase;
	}

action addElementIn_list_flooding_events (string sub_name, string sub_rep)
	{
		put sub_rep key: sub_name in: list_flooding_events;
		ask network_round_manager
		{
			do add_element(sub_name,sub_rep);
		}
	}	
action executeLisflood (string eventName)
	{	timestamp <- "_R"+round+"_t"+machine_time ;
		current_lisflood_rep <- "results"+timestamp;
		do save_dem;  
		do save_rugosityGrid;
		do save_lf_launch_files(eventName);
		do addElementIn_list_flooding_events("Submersion Tour "+round,current_lisflood_rep);
		
		save "dir created by littoSIM" to: lisfloodRelativePath+current_lisflood_rep+"/bidon.txt" type: "text";// need to create the lisflood results directory because lisflood cannot create it buy himself
		 ask network_listen_to_leader{
			do execute command:"cmd /c start "+lisfloodPath+lisflood_bat; }
 	}
 		
action save_lf_launch_files (string eventName) {
	switch eventName {
		match "Xynthia" {
			save ("DEMfile         "+lisfloodPath+atelierDEM+timestamp+".asc\nresroot         res\ndirroot         results\nsim_time        52200\ninitial_tstep   10.0\nmassint         100.0\nsaveint         3600.0\n#checkpoint     0.00001\n#overpass       100000.0\n#fpfric         0.06\n#infiltration   0.000001\n#overpassfile   buscot.opts\nmanningfile     "+lisfloodPath+"oleron_n2016"+timestamp+".asc\n#riverfile      buscot.river\nbcifile         "+lisfloodPath+"oleron2016.bci\nbdyfile         "+lisfloodPath+"oleron2016.bdy\n#weirfile       buscot.weir\nstartfile       "+lisfloodPath+"oleron.start\nstartelev\n#stagefile      buscot.stage\nelevoff\n#depthoff\n#adaptoff\n#qoutput\n#chainageoff\nSGC_enable\n") rewrite: true  to: lisfloodRelativePath+conf_Xynthia_listflood type: "text"  ;
			save (lisfloodPath+"lisflood.exe -dir "+ lisfloodPath+current_lisflood_rep +" "+lisfloodPath+conf_Xynthia_listflood) rewrite: true  to: lisfloodRelativePath+lisflood_bat type: "text" ;	
		}
		match "Xynthia moins 50cm" {
			save ("DEMfile         "+lisfloodPath+atelierDEM+timestamp+".asc\nresroot         res\ndirroot         results\nsim_time        52200\ninitial_tstep   10.0\nmassint         100.0\nsaveint         3600.0\n#checkpoint     0.00001\n#overpass       100000.0\n#fpfric         0.06\n#infiltration   0.000001\n#overpassfile   buscot.opts\nmanningfile     "+lisfloodPath+"oleron_n2016"+timestamp+".asc\n#riverfile      buscot.river\nbcifile         "+lisfloodPath+"oleron2016.bci\nbdyfile         "+lisfloodPath+"oleron2016_Xynthia-50.bdy\n#weirfile       buscot.weir\nstartfile       "+lisfloodPath+"oleron.start\nstartelev\n#stagefile      buscot.stage\nelevoff\n#depthoff\n#adaptoff\n#qoutput\n#chainageoff\nSGC_enable\n") rewrite: true  to: lisfloodRelativePath+"oleron2016_Xynthia-50"+timestamp+".par" type: "text"  ;
		save (lisfloodPath+"lisflood.exe -dir "+ lisfloodPath+current_lisflood_rep +" "+lisfloodPath+conf_Xynthia_listflood) rewrite: true  to: lisfloodRelativePath+lisflood_bat type: "text" ;
		}
	}
}       

action save_dem {
	save cell to: lisfloodRelativePath + atelierDEM + timestamp + ".asc" type: "asc";
	}

action save_rugosityGrid {
		string filename <- atelier_rugosityGrid;
		save 'ncols         631\nnrows         906\nxllcorner     364927.14666668\nyllcorner     6531972.5655556\ncellsize      20\nNODATA_value  -9999' rewrite: true to: filename type:"text";
		loop j from: 0 to: nb_rows- 1 {
			string text <- "";
			loop i from: 0 to: nb_cols - 1 {
				text <- text + " "+ cell[i,j].rugosity;}
			save text to: filename rewrite: false ;
			}
		}
	   
action readLisflood
	 {  
	 	string nb <- lisfloodReadingStep;
		loop i from: 0 to: 3-length(nb) { nb <- "0"+nb; }
		string fileName <- lisfloodRelativePath+current_lisflood_rep+"/res-"+ nb +".wd";
		if file_exists (fileName)
			{
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
	     else { // fin innondation
	     		lisfloodReadingStep <-  9999999;
	     		if nb = "0000" {
	     			map values <- user_input(["Il n'y a pas de fichier de résultat lisflood pour cet évènement" :: ""]);
	     			stateSimPhase <- 'game';
	     			write stateSimPhase + " - Tour "+round;
	     		}
	     		else{
					stateSimPhase <- 'calculate flood stats'; write stateSimPhase;}   }	   
	}
	
action load_rugosity
     { file rug_data <- text_file("../includes/zone_etude/oleron.n.ascii") ;
			loop r from: 6 to: length(rug_data) -1 {
				string l <- rug_data[r];
				list<string> res <- l split_with " ";
				loop c from: 0 to: length(res) - 1{
					cell[c,r-6].rugosity <- float(res[c]);}}	
	}


action calculate_communes_results
		{	string text <- "";
			ask ((commune where (each.id > 0)) sort_by (each.id))
			{  	int tot <- length(cells) ;
				int myid <-  self.id; 
				int U_0_5 <-0;	int U_1 <-0;	int U_max <-0;
				int Us_0_5 <-0;	int Us_1 <-0;	int Us_max <-0;
				int Udense_0_5 <-0;	int Udense_1 <-0;	int Udense_max <-0;
				int AU_0_5 <-0;	int AU_1 <-0;	int AU_max <-0;
				int A_0_5 <-0;	int A_1 <-0;	int A_max <-0;
				int N_0_5 <-0;	int N_1 <-0;	int N_max <-0;
				ask UAs
					{
					ask cells {
						if max_water_height > 0
						{ switch myself.ua_name //"U","Us","AU","N","A"    -> et  "AUs" impossible normallement
							{
							match "AUs" {
								write "STOP :  AUs impossible normallement";
							}
								match "U" {
									if max_water_height <= 0.5 {
										U_0_5 <- U_0_5 +1;
										if myself.classe_densite = "dense" {
											Udense_0_5 <- Udense_0_5 +1;
										}
									}
									if between (max_water_height ,0.5, 1.0) {
										U_1 <- U_1 +1;
										if myself.classe_densite = "dense" {
											Udense_1 <- Udense_1 +1;
										}
									}
									if max_water_height >= 1{
										U_max <- U_max +1 ;
										if myself.classe_densite = "dense" {
											Udense_0_5 <- Udense_0_5 +1;
										}
									}
								}
							match "Us" {
									if max_water_height <= 0.5 {
										Us_0_5 <- Us_0_5 +1;
									}
									if between (max_water_height ,0.5, 1.0) {
										Us_1 <- Us_1 +1;
									}
									if max_water_height >= 1{
										Us_max <- Us_max +1 ;
									}
								}
							match "AU" {
									if max_water_height <= 0.5 {
										AU_0_5 <- AU_0_5 +1;
									}
									if between (max_water_height ,0.5, 1.0) {
										AU_1 <- AU_1 +1;
									}
									if max_water_height >= 1.0 {
										AU_max <- AU_max +1 ;
									}
								}
							match "N" {
									if max_water_height <= 0.5 {
										N_0_5 <- N_0_5 +1;
									}
									if between (max_water_height ,0.5, 1.0) {
										N_1 <- N_1 +1;
									}
									if max_water_height >= 1.0 {
										N_max <- N_max +1 ;
									}
								}
							match "A" {
								if max_water_height <= 0.5 {
									A_0_5 <- A_0_5 +1;
								}
								if between (max_water_height ,0.5, 1.0) {
									A_1 <- A_1 +1;
								}
								if max_water_height >= 1.0 {
									A_max <- A_max +1 ;
								}
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
				text <- text + "Résultats commune " + commune_name +"
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
				
			write "Surface inondée par commune";
			ask ((commune where (each.id > 0)) sort_by (each.id))
				{ 	surface_inondee <- (U_0_5c + U_1c + U_maxc + Us_0_5c + Us_1c + Us_maxc + AU_0_5c + AU_1c + AU_maxc + N_0_5c + N_1c + N_maxc + A_0_5c + A_1c + A_maxc) with_precision 1 ;
					add surface_inondee to: data_surface_inondee; 
					write ""+ commune_name + " : " + surface_inondee +" ha";

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
		 do connect to:SERVER with_name:GAME_MANAGER+"_retreive";
	}
	action send_data_to_commune(commune m)
	{
		write "send data.... to "+ m.network_name;
		ask m {do send_player_commune_update();}
		do retreive_def_cote(m);
		do retreive_UA(m);
		do retreive_action_done(m);
		do retreive_activated_lever(m);
	}
	
	action retreive_def_cote(commune aCommune)
	{	
		list<def_cote> def_list <- def_cote where(each.commune_name_shpfile = world.commune_name_shpfile_of_commune_name(aCommune.commune_name));
		def_cote tmp;
		loop tmp over:def_list
		{
			write "send to "+ aCommune.network_name+"_retreive" + " "+tmp.build_map_from_attribute();
			do send 	to:aCommune.network_name+"_retreive" contents:tmp.build_map_from_attribute();
		}
		
	}
	
	action retreive_UA(commune m)
	{
		UA tmp<- nil;
		loop tmp over:m.UAs
		{
			write "send to "+ m.network_name+"_retreive" + " "+tmp.build_map_from_attribute();
			do send 	to:m.network_name+"_retreive" contents:tmp.build_map_from_attribute();
		}
	}

	action retreive_action_done(commune m)
	{
		list<action_done> action_list <- action_done where(each.commune_name = m.commune_name);
		action_done tmp<- nil;
		loop tmp over:action_list 	
		{
			write "send to "+ m.network_name+"_retreive" + " "+tmp.build_map_from_attribute();
			do send 	to:m.network_name+"_retreive" contents:tmp.build_map_from_attribute();
		}
	}
	
	
	action lock_window(commune m, bool are_allowed)
	{
		string val <- are_allowed=true?"UN_LOCKED":"LOCKED";
		map<string,string> me <- [
			"OBJECT_TYPE"::"lock_unlock",
			"WINDOW_STATUS"::val
			];
		do send 	to:m.network_name+"_retreive" contents:me;
	}
	
	
	action retreive_activated_lever(commune m)
	{
		list<activated_lever> lever_list <- activated_lever where(each.commune_name = m.commune_name);
		activated_lever tmp<- nil;
		loop tmp over:lever_list 	
		{
			write "send to "+ m.network_name+"_retreive" + " "+tmp.build_map_from_attribute();
			do send 	to:m.network_name+"_retreive" contents:tmp.build_map_from_attribute();
		}
	}
	
		
}


species action_done schedules:[]
{
	string id;
	int element_id;
	geometry element_shape;
	string commune_name<-"";
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
	string action_type <- "dike" ; //can be "dike" or "PLU"
	string previous_ua_name <-"";  // for PLU action
	bool isExpropriation <- false; // for PLU action
	bool inProtectedArea <- false; // for dike action
	bool inCoastBorderArea <- false; // for PLU action // c'est la bande des 400 m par rapport au trait de cote
	bool inRiskArea <- false; // for PLU action / Ca correspond à la zone PPR qui est un shp chargé
	bool isInlandDike <- false; // for dike action // ce sont les rétro-digues
	bool is_alive <- true;
	list<activated_lever> activated_levers <-[];
	bool shouldWaitLeaderToActivate <- false;
	int length_def_cote<-0;
	bool a_lever_has_been_applied<- false;
	
	
	map<string,string> build_map_from_attribute
	{
		map<string,string> res <- [
			"OBJECT_TYPE"::"action_done",
			"id"::string(id),
			"element_id"::string(element_id),
			"commune_name"::string(commune_name),
			"command"::string(command),
			"label"::string(label),
			"cost"::string(cost),
			"initial_application_round"::string(initial_application_round),
			"isInlandDike"::string(isInlandDike),
			"inRiskArea"::string(inRiskArea),
			"inCoastBorderArea"::string(inCoastBorderArea),
			"isExpropriation"::string(isExpropriation),
			"inProtectedArea"::string(inProtectedArea),
			"previous_ua_name"::string(previous_ua_name),
			"action_type"::string(action_type),
			"locationx"::string(location.x),
			"locationy"::string(location.y),
			"is_applied"::string(is_applied),
			"is_sent"::string(is_sent),
			"command_round"::string(command_round),
			"element_shape"::string(element_shape),
			"length_def_cote"::string(length_def_cote),
			"a_lever_has_been_applied"::string(a_lever_has_been_applied)
			 ]	;
			point pp<-nil;
			int i <- 0;
			loop pp over:element_shape.points
			{
				put string(pp.x) key:"locationx"+i in: res;
				put string(pp.y) key:"locationy"+i in: res;
				i <- i + 1;
			}
	return res;
	}
	
	aspect base
	{
		
		
			int indx <- action_done index_of self;
			float y_loc <- (indx +1)  * font_size ;
			float x_loc <- font_interleave + 12* (font_size+font_interleave);
			float x_loc2 <- font_interleave + 20* (font_size+font_interleave);
			shape <- rectangle({font_size+2*font_interleave,y_loc},{x_loc2,y_loc+font_size/2} );
			draw shape color:#white;
			string txt <- commune_name+": "+ label;
			txt <- txt +" ("+string(initial_application_round-round)+")"; 
			draw txt at:{font_size+2*font_interleave,y_loc+font_size/2} size:font_size#m color:#black;
			draw "    "+ round(cost) at:{x_loc,y_loc+font_size/2} size:font_size#m color:#black;
		
	}

	

	
	def_cote create_dike(action_done act)
	{
		int next_dike_id <- max(def_cote collect(each.dike_id))+1;
		create def_cote number:1 returns:new_dikes
		{
			dike_id <- next_dike_id;
			commune_name_shpfile <- world.commune_name_shpfile_of_commune_name(act.commune_name);
			shape <- act.element_shape;
			location <- act.location;
			type <- BUILT_DIKE_TYPE ;
			status <- BUILT_DIKE_STATUS;
			height <- STANDARD_DIKE_SIZE;	
			cells <- cell overlapping self;
		}
		act.element_id <- first(new_dikes).dike_id;
		return first(new_dikes);
	}
	
}


species network_round_manager skills:[remoteGUI]
{
	list<string> mtitle <- list_flooding_events.keys;
	list<string> mfile <- [];
	string selected_action;
	string choix_simu_temp <- nil;
	string choix_simulation <- "Submersion initiale";
	int mround <-0 update:world.round;
	 
	init
	{
		//connection du au serveur
		do connect to:SERVER;
		
		do expose variables:["mtitle","mfile"] with_name:"listdata";
		do expose variables:["mround"] with_name:"current_round";
		do listen with_name:"simu_choisie" store_to:"choix_simu_temp";
		do listen with_name:"littosim_command" store_to:"selected_action";
		
		do update_submersion_list;
	}
	
	action update_submersion_list
	{
		loop a over:list_flooding_events.keys
		{
			mtitle <- mtitle + a;
			mfile <- mfile + (list_flooding_events at a)	;
		}
	}
	
	reflex selected_action when:selected_action != nil
	{
		write "network_round_manager " + selected_action;
		switch(selected_action)
		{
			match "NEW_ROUND" { ask world {	do new_round; }}
			match "START_VISUALISATION" { do start_visualisation_submersion ; }
			match "LOCK_USERS" { do lock_unlock_window(true) ; }
			match "UNLOCK_USERS" { do lock_unlock_window(false) ;}
			match "HIGH_FLOODING" { ask world {do launchFlood_event("Xynthia");} }
			match "LOW_FLOODING" {	ask world {do launchFlood_event("Xynthia moins 50cm");}}
		}
		selected_action <- nil;
	}
	
	
	reflex show_submersion when: choix_simu_temp!=nil
	{
		write "network_round_manager : choix simulation " + choix_simu_temp;
		choix_simulation <- choix_simu_temp;
		choix_simu_temp <-nil;
	}
	
	
	action lock_unlock_window(bool value)
	{
		data_retreive agt <- first(data_retreive);
		
		ask commune
		{
			ask agt {
				do lock_window(myself,value);
			}
		}
	}
	
	action start_visualisation_submersion
	{
		
		//démarer la visualisation avec la submerssion "choix simulaiton"
		//quelle méthode doit il être utilisé?
		loop a over:list_flooding_events.keys
		{
			write "coucou "+ a+ " " +(list_flooding_events at a);
		}
		write "chouis "+choix_simulation;
		
		loop r from: 0 to: nb_rows -1  { loop c from:0 to: nb_cols -1 {cell[c,r].max_water_height <- 0.0; } } // remise à zero de max_water_height
		set lisfloodReadingStep <- 0;
		current_lisflood_rep <- list_flooding_events at choix_simulation;
		stateSimPhase <- 'show lisflood'; write stateSimPhase;
		ask world{
			do readLisflood;
		}
		
	}
	
	action add_element(string nom_submersion, string path_to_see)
	{
		do update_submersion_list;
	}
}

species activated_lever 
{
	action_done act_done;
	float activation_time;
	bool applied <- false;
	
	//attributes sent through network
	int id;
	string commune_name;
	string lever_type;
	string lever_explanation <- "";
	string act_done_id <- "";
	int nb_rounds_delay <-0;
	int added_cost <- 0;
	int round_creation;
	int round_application;
	
	action init_from_map(map<string, string> m )
	{
		id <- int(m["id"]);
		lever_type <- m["lever_type"];
		commune_name <- m["commune_name"];
		act_done_id <- m["act_done_id"];
		added_cost <- int(m["added_cost"]);
		nb_rounds_delay <- int(m["nb_rounds_delay"]);
		lever_explanation <- m["lever_explanation"];
		round_creation <- int(m["round_creation"]);
		round_application <- int(m["round_application"]);
	}
	
	map<string,string> build_map_from_attribute
	{
		map<string,string> res <- [
			"OBJECT_TYPE"::"activated_lever",
			"id"::id,
			"lever_type"::lever_type,
			"commune_name"::commune_name,
			"act_done_id"::string(act_done_id),
			"added_cost"::string(added_cost),
			"nb_rounds_delay"::int(nb_rounds_delay),
			"lever_explanation"::lever_explanation,
			"round_creation"::round_creation,
			"round_application"::round_application
			 ]	;
		return res;
	}
}

species network_activated_lever skills:[network]
{
	init
	{
		do connect to:SERVER with_name:"activated_lever";	
	}
	
	reflex wait_message
	{
		loop while:has_more_message()
		{
			message msg <- fetch_message();
			string m_sender <- msg.sender;
			map<string, string> m_contents <- msg.contents;
			if empty(activated_lever where (each.id = int(m_contents["id"])))
			{
				create activated_lever number:1
				{
					do init_from_map(m_contents);
					act_done <- action_done first_with (each.id = act_done_id);
					commune aCommune <- commune first_with (each.commune_name = commune_name);
					aCommune.budget <-aCommune.budget - added_cost; 
					add self to:act_done.activated_levers;
					act_done.a_lever_has_been_applied<- true;
				}
			}			
		}	
	}
}
species network_listen_to_leader skills:[network]
{
	string PRELEVER <- "Percevoir Recette";
	string CREDITER <- "Subventionner";
	string LEADER_COMMAND <- "leader_command";
	string AMOUNT <- "amount";
	string COMMUNE <- "COMMUNE_ID";
	string ASK_NUM_ROUND <- "Leader demande numero du tour";
	string NUM_ROUND <- "Numero du tour";
	string ASK_INDICATORS_T0 <- "Leader demande Indicateurs a t0";
	string INDICATORS_T0 <- 'Indicateurs a t0';
	
	init
	{
		 do connect to:SERVER with_name:MSG_FROM_LEADER;
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
				match CREDITER
				{
					string commune_name <- m_contents[COMMUNE];
					int amount <- m_contents[AMOUNT];
					commune cm <- commune first_with(each.commune_name=commune_name);
					cm.budget <- cm.budget + amount;
				}
				match PRELEVER
				{
					string commune_name <- m_contents[COMMUNE];
					int amount <- m_contents[AMOUNT]; 
					commune cm <- commune first_with(each.commune_name=commune_name);
					cm.budget <- cm.budget - amount;
				}
				
				match ASK_NUM_ROUND {
					do informLeader_round_number;
				}

				match ASK_INDICATORS_T0 {
					do informLeader_Indicators_t0;
				}
				match "RETREIVE_ACTION_DONE" {
					ask action_done {is_sent_to_leader <- false ;}
				}
				match "action_done shouldWaitLeaderToActivate" {
					action_done aAct <-action_done first_with (each.id = string(m_contents["action_done id"]));
					write "msg shouldWait on "+aAct;
					aAct.shouldWaitLeaderToActivate <- bool(m_contents["action_done shouldWaitLeaderToActivate"]);
					write "msg shouldWait value "+aAct.shouldWaitLeaderToActivate;
				}
			}
			
		}
		
	}
	
	action informLeader_round_number  {
					map<string,string> msg <- [];
					put NUM_ROUND key:OBSERVER_MESSAGE_COMMAND in:msg ;
					put string(round) key: "num tour" in: msg;
					do send to:GAME_LEADER contents:msg;
				}
				
	action informLeader_Indicators_t0  {
		ask commune where (each.id > 0) {
					map<string,string> msg <- [];
					put myself.INDICATORS_T0 key:OBSERVER_MESSAGE_COMMAND in:msg ;
					put commune_name key: 'commune_name' in: msg;
					put length_dikes_t0 key: "length_dikes_t0" in: msg;
					put length_dunes_t0 key: "length_dunes_t0" in: msg;
					put count_UA_urban_t0 key: "count_UA_urban_t0" in: msg;
					put count_UA_UandAU_inCoastBorderArea_t0 key: "count_UA_UandAU_inCoastBorderArea_t0" in: msg;
					put count_UA_urban_infloodRiskArea_t0 key: "count_UA_urban_infloodRiskArea_t0" in: msg;
					put count_UA_urban_dense_infloodRiskArea_t0 key: "count_UA_urban_dense_infloodRiskArea_t0" in: msg;
					put count_UA_urban_dense_inCoastBorderArea_t0 key: "count_UA_urban_dense_inCoastBorderArea_t0" in: msg;
					put count_UA_A_t0 key: "count_UA_A_t0" in: msg;
					put count_UA_N_t0 key: "count_UA_N_t0" in: msg;
					put count_UA_AU_t0 key: "count_UA_AU_t0" in: msg;
					put count_UA_U_t0 key: "count_UA_U_t0" in: msg;
					ask myself {do send to:GAME_LEADER contents:msg;}
					}		
				}
	
	
	reflex send_action_state when: cycle mod 10 = 0
	{
		loop act_done over: action_done where (!each.is_sent_to_leader)
		{
			map<string,string> msg <- act_done.build_map_from_attribute();
			put UPDATE_ACTION_DONE key:OBSERVER_MESSAGE_COMMAND in:msg ;
			do send to:GAME_LEADER contents:msg;
			act_done.is_sent_to_leader <- true;
			write "send message to leader "+ msg;
			
		}
	}
	
}

species network_player skills:[network]
{
	init
	{
		 do connect to: SERVER with_name:GAME_MANAGER;
	}
	
	reflex wait_message when: activemq_connect
	{
		loop while:has_more_message()
		{
			message msg <- fetch_message();
			string m_sender <- msg.sender;
			map<string, unknown> m_contents <- msg.contents;
			if(m_sender!=GAME_MANAGER )
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
								do inform_current_round;
								do send_player_commune_update;
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
			self.id <- string(data[1]);
			self.initial_application_round <- int(data[2]);
			self.commune_name <- sender;
			if !(self.command in [REFRESH_ALL])
			{
				self.element_id <- int(data[3]);
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
					element_shape <- polyline([ori,des]);
					length_def_cote <- int(element_shape.perimeter);
					location <- loc; 
				}
				else {
					if isExpropriation {write "Procédure d'expropriation declenchée pour l'UA "+self.id;}
					switch self.action_type {
						match "PLU" {
							UA tmp <- (UA first_with(each.id = self.element_id));
							element_shape <- tmp.shape;
							location <- tmp.location;
						}
						match "dike" {element_shape <- (def_cote first_with(each.dike_id = self.element_id)).shape;
									length_def_cote <- int(element_shape.perimeter);
						}
						default {write "problème reconnaissance du type de action_done";}
					}
				}
				// calcul des attributs qui n'ont pas été calculé au niveau de Participatif et qui ne sont donc pas encore renseigné
				//inCoastBorderArea  // for PLU action // c'est la bande des 400 m par rapport au trait de cote
				//inRiskArea  // for PLU action / Ca correspond à la zone PPR qui est un shp chargé
				//isInlandDike  // for dike action // ce sont les rétro-digues
				if  self.element_shape intersects all_flood_risk_area 
					{inRiskArea <- true;}
				if  self.element_shape intersects first(coast_border_area)
					{inCoastBorderArea <- true;}	
				if command = ACTION_CREATE_DIKE and (self.element_shape.centroid overlaps first(inland_dike_area))
						{isInlandDike <- true;}
				// finallement on recalcul aussi inProtectedArea meme si ca a été calculé au niveau de participatif, car en fait ce n'est pas calculé pour toutes les actions 
				if  self.element_shape intersects all_protected_area
					{inProtectedArea <- true;}
					
				if(log_user_action)
				{
					save ([string(machine_time-START_LOG),self.commune_name]+data) to:LOG_FILE_NAME type:"csv";
				}
			}
		}
		//  le paiement est déjà fait coté commune, lorsque le joueur a validé le panier. On renregistre ici le paiement pour garder les comptes à jour coté serveur
		int idCom <-world.commune_id(new_action.commune_name);
		ask commune first_with(each.id = idCom) {do record_payment_for_action_done(new_action);}
	}
	
	
	
	reflex update_UA  when:length(UA where(each.not_updated))>0 
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
	
	action send_destroy_dike_message(def_cote a_dike)
	{
		string msg <- ""+ACTION_DIKE_DROPPED+COMMAND_SEPARATOR+world.getMessageID() +COMMAND_SEPARATOR+a_dike.dike_id;
		
		list<commune> cms <- commune overlapping a_dike;
		loop cm over:cms
			{
				do send to:cm.network_name contents:msg;
			}
	}
	
	action send_created_dike(def_cote new_dike,action_done act)
	{
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
		list<commune> cms <- commune overlapping new_dike;
			loop cm over:cms
			{
				do send  to:cm.network_name contents:msg;
			}

	
	}
	
	action acknowledge_application_of_action_done (action_done act)
	{
		map<string,string> msg <- [
			"TOPIC"::"action_done is_applied",
			"commune_name"::act.commune_name,
			"id"::act.id
			];
		do send  to:act.commune_name+"_map_msg" contents:msg;
	}
	
	float min_dike_elevation(def_cote ovg)
	{
		return min(cell overlapping ovg collect(each.soil_height));
	}
	
	
	reflex update_dike  when:length(def_cote where(each.not_updated))>0 
	{
		list<string> update_messages <-[]; 
		list<def_cote> update_ouvrage <- [];
		ask def_cote where(each.not_updated)
		{
			point p1 <- first(self.shape.points);
			point p2 <- last(self.shape.points);
			string msg <- ""+ACTION_DIKE_UPDATE+COMMAND_SEPARATOR+world.getMessageID() +COMMAND_SEPARATOR+self.dike_id+COMMAND_SEPARATOR+p1.x+COMMAND_SEPARATOR+p1.y+COMMAND_SEPARATOR+p2.x+COMMAND_SEPARATOR+p2.y+COMMAND_SEPARATOR+self.height+COMMAND_SEPARATOR+self.type+COMMAND_SEPARATOR+self.status+COMMAND_SEPARATOR+self.ganivelle+COMMAND_SEPARATOR+myself.min_dike_elevation(self);
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

				do send to:cm.network_name contents:msg;
			}
			i <- i + 1;
			
		}
	}

	reflex apply_action when:length(action_done where(each.is_alive))>0
	{
	//	ask(action_done where(each.should_be_applied and each.is_alive and not(each.shouldWaitLeaderToActivate)))
	// Pour une raison bizarre la ligne au dessus ne fonctionne pas alors que les 2 lignes ci dessous fonctionnent. Pourtant je ne vois aucune difference
		ask action_done {
			if should_be_applied and is_alive and !shouldWaitLeaderToActivate
			
		{
			string tmp <- self.commune_name;
			int idCom <-world.commune_id(tmp);
			action_done act <- self;
			switch(command)
			{
				match REFRESH_ALL
				{////  Pourquoi est ce que REFRESH_ALL est une  Action_done ??
					write " Update ALL !!!! " + idCom+ " "+ commune_name;
					string dd <- commune_name;
					commune cm <- first(commune where(each.id=idCom));
					ask first(data_retreive) 
					{
						do send_data_to_commune(cm);
					}
					
				}
				
				match ACTION_CREATE_DIKE
				{	
					def_cote new_dike <-  create_dike(act);
					ask network_player
					{
						do send_created_dike(new_dike, act);
						do acknowledge_application_of_action_done(act);
					}
					ask(new_dike) {do new_dike_by_commune (idCom) ;
					}
				}
				match ACTION_REPAIR_DIKE {
					ask(def_cote first_with(each.dike_id=element_id))
					{
						do repair_by_commune(idCom);
						not_updated <- true;
					}
					ask network_player
					{
						do acknowledge_application_of_action_done(act);
					}		
				}
			 	match ACTION_DESTROY_DIKE 
			 	 {
			 		ask(def_cote first_with(each.dike_id=element_id))
					{
						ask network_player
						{
							do send_destroy_dike_message(myself);
							do acknowledge_application_of_action_done(act);
						}
						do destroy_by_commune (idCom) ;
						not_updated <- true;
					}		
				}
			 	match ACTION_RAISE_DIKE {
			 		ask(def_cote first_with(each.dike_id=element_id))
					{
						do increase_height_by_commune (idCom) ;
						not_updated <- true;
					}
					ask network_player
					{
						do acknowledge_application_of_action_done(act);
					}
				}
				 match ACTION_INSTALL_GANIVELLE {
				 	ask(def_cote first_with(each.dike_id=element_id))
					{
						do install_ganivelle_by_commune (idCom) ;
						not_updated <- true;
					}
					ask network_player
					{
						do acknowledge_application_of_action_done(act);
					}
				}
			 	match ACTION_MODIFY_LAND_COVER_A {
			 		ask UA first_with(each.id=element_id)
			 		 {
			 		  do modify_UA (idCom, "A");
			 		  not_updated <- true;
			 		 }
			 		 ask network_player
					{
						do acknowledge_application_of_action_done(act);
					}
			 	}
			 	match ACTION_MODIFY_LAND_COVER_AU {
			 		ask UA first_with(each.id=element_id)
			 		 {
			 		 	do modify_UA (idCom, "AU");
			 		 	not_updated <- true;
			 		 }
			 		 ask network_player
					{
						do acknowledge_application_of_action_done(act);
					}
			 	}
				match ACTION_MODIFY_LAND_COVER_N {
					ask UA first_with(each.id=element_id)
			 		 {
			 		 	do modify_UA (idCom, "N");
			 		 	not_updated <- true;
			 		 }
			 		 ask network_player
					{
						do acknowledge_application_of_action_done(act);
					}
			 	}
			 	match ACTION_MODIFY_LAND_COVER_Us {
			 		ask UA first_with(each.id=element_id)
			 		 {
			 		 	do modify_UA (idCom, "Us");
			 		 	not_updated <- true;
			 		 }
			 		 ask network_player
					{
						do acknowledge_application_of_action_done(act);
					}
			 	 }
			 	 match ACTION_MODIFY_LAND_COVER_Ui {
			 		ask UA first_with(each.id=element_id)
			 		 {
			 		 	do apply_Densification(idCom);
			 		 	not_updated <- true;
			 		 }
			 		 ask network_player
					{
						do acknowledge_application_of_action_done(act);
					}
			 	 }
			 	match ACTION_MODIFY_LAND_COVER_AUs {
			 		ask UA first_with(each.id=element_id)
			 		 {
			 		 	do modify_UA (idCom, "AUs");
			 		 	not_updated <- true;
			 		 }
			 		 ask network_player
					{
						do acknowledge_application_of_action_done(act);
					}
			 	}
			}
			is_alive <- false; 
			is_applied <- true;
		}}		
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
		
		create buttons number: 1
		{
			nb_button <- 4;
			label <- "Show UA grid";
			shape <- square(850);
			location <- { 800,14000 };
			my_icon <- image_file("../images/icones/sans_quadrillage.png");
			is_selected <- false;
		}
		create buttons number: 1
		{
			nb_button <- 6;
			label <- "Replay flooding";
			shape <- square(button_size);
			location <- { 9000,1000 };
			my_icon <- image_file("../images/icones/replay_flooding.png");
			display_name <- UNAM_DISPLAY_c;
		}
		create buttons number: 1
		{
			nb_button <- 7;
			label <- "Show max water height";
			shape <- square(850);
			location <- { 1800,14000 };
			my_icon <- image_file("../images/icones/max_water_height.png");
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
				ask world {do new_round;}
			}
			if (nb_button = 3){
				ask world {do launchFlood_event("Xynthia");}
			}
			if (nb_button = 5){
				ask world {do launchFlood_event("Xynthia moins 50cm");}
			}
			if (nb_button = 6){
				ask world {do replay_flood_event();}
			}
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
		buttons a_button <- first((buttons where (each distance_to loc < MOUSE_BUFFER)) where(each.nb_button = 7));
		if a_button != nil
		{
			ask a_button
			{
				is_selected <- not(is_selected);
				show_max_water_height <-is_selected;
			}
		}
	}
	
    
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
		
	
	rgb color_of_water_height (float aWaterHeight)
	{
		if aWaterHeight  <= 0.5 {return rgb (200,200,255);}
		if aWaterHeight  > 0.5 and aWaterHeight  <= 1 {return rgb (115,115,255);}
		if aWaterHeight  > 1 and aWaterHeight  <= 2 {return rgb (65,65,255);}
		return rgb (30,30,255);
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
		rgb soil_color ;
	
		init {
			if soil_height <= 0 {cell_type <-1;}  //  1 -> mer
			if soil_height = 0 {soil_height <- -5.0;}
			soil_height_before_broken <- soil_height;
			do init_soil_color();
			}
		action init_soil_color
		{
			if cell_type = 1 
				{float tmp <-  ((soil_height  / 10) with_precision 1) * -170;
					soil_color<- rgb( 80, 80 , 255 - tmp) ; }
			 else{
				float tmp <-  ((soil_height  / 10) with_precision 1) * 255;
					soil_color<- rgb( 255 - tmp, 180 - tmp , 0) ; }
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
				{color<- soil_color ; }
			else
			{
				if water_height = 0			
				{color<- soil_color;}
				else
				{
					color <- world.color_of_water_height(water_height);
				}
			}
		}
		aspect elevation_eau_max
		{
			if cell_type = 1 
				{color<- soil_color ; }
			else
			{
				if water_height = 0			
				{color<- soil_color;}
				else
				{
					color <- world.color_of_water_height(max_water_height);
				}
			}
		}		
		aspect elevation_eau_ou_eau_max
		{
			if cell_type = 1 or (show_max_water_height?(max_water_height = 0):(water_height = 0))
				{color<- soil_color ; }
			else
			{
				if show_max_water_height
				{
					color <- world.color_of_water_height(max_water_height);
				 }
				else
				{
					color <- world.color_of_water_height(water_height);
				}
			}
		}
	}


species def_cote
{	
	int dike_id;
	string commune_name_shpfile;
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
		shape <- polyline(all_points);
		location <-mpp;
	}
	
	map<string,unknown> build_map_from_attribute
	{
		map<string,unknown> res <- [
			"OBJECT_TYPE"::"def_cote",
			"dike_id"::string(dike_id),
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
			"locationy"::string(location.y)
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
					do init_soil_color();
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
				rupture <- 1;
				// on applique la rupture a peu pres au milieu du linéaire
				int cIndex <- int(length(cells) /2);
				// on défini la zone de rupture ds un rayon de 30 mètre autour du point de rupture 
				zoneRupture <- circle(radius_rupture#m,(cells[cIndex]).location);
				// on applique la rupture sur les cells de cette zone
				ask cells overlapping zoneRupture  {
							if soil_height >= 0 {soil_height <-   max([0,soil_height - myself.height]);}
				}
				write "rupture "+type_def_cote+" n°" + dike_id + "("+", état " + status +", hauteur "+height+", alt "+alt +")";
				write "rupture "+type_def_cote+" n°" + dike_id + "("+ commune_name_shpfile+", état " + status +", hauteur "+height+", alt "+alt +")";
				
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
	}
	
	//La commune relève la digue
	action increase_height_by_commune (int a_commune_id) {
		status <- "bon";
		cptStatus <- 0;
		height <- height + rehaussement; // le réhaussement d'ouvrage est forcément de 1 mètre / ds la V1 c'etait 50  centimètres
		alt <- alt + 1;
		ask cells {
			soil_height <- soil_height + 1;
			soil_height_before_broken <- soil_height ;
			do init_soil_color();
			}
	}
	
	//la commune détruit la digue
	action destroy_by_commune (int a_commune_id) {
		ask cells {
			soil_height <- soil_height - myself.height ;
			soil_height_before_broken <- soil_height ;
			do init_soil_color();
		}
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
			do init_soil_color();
		}
	}
	
	//La commune installe des ganivelles sur la dune
	action install_ganivelle_by_commune (int a_commune_id) {
		if status = "mauvais"
		{
			cptStatus <- 2;
		}
		else
		{				
			cptStatus <- 0;
		}		
		ganivelle <- true;
		write "INSTALL GANIVELLE";
	}
	
	
	aspect base
	{  	if type != 'Naturel'
			{switch status {
				match  "bon" {color <- # green;}
				match "moyen" {color <-  rgb (255,102,0);} 
				match "mauvais" {color <- # red;} 
				default { /*"casse" {color <- # yellow;}*/write "probleme status dike";}
				}
			draw 20#m around shape color: color size:300#m;
				}
		else {switch status {
				match  "bon" {color <- rgb (222, 134, 14,255);}
				match "moyen" {color <-  rgb (231, 189, 24,255);} 
				match "mauvais" {color <- rgb (241, 230, 14,255);} 
				default { write "probleme status dune";}
				}
			draw 50#m around shape color: color;
			if ganivelle {loop i over: points_on(shape, 40#m) {draw circle(10,i) color: #black;}} 
		}		
		if(rupture = 1)
		{
			list<point> pts <- shape.points;
			point tmp <- length(pts) > 2?pts[int(length(pts)/2)]:shape.centroid;
			draw image_file("../images/icones/rupture.png") at:tmp size:30#px;
			
		}	
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
		 draw shape color: rgb (185, 255, 185,120) border:#black;	
	}
}
species flood_risk_area {
	
	aspect base 
	{
		 draw shape color: rgb (20, 200, 255,120) border:#black;
	}
}

species coast_border_area {// zone des 400m littoral 
	
	aspect base 
	{
		 draw shape color: rgb (20, 100, 205,120) border:#black;
	}
}

species inland_dike_area {// zone au delà des 100 m par rapport au trait de cote, à l'intérieur des terres // zone pour identifier les rétro digues 
	
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
	{	if  (ua_name in ["U","Us"])and new_ua_name = "N" /*expropriation */ {population <-0;}
		ua_name <- new_ua_name;
		ua_code <- codeOfUAname(ua_name);
		
		//on affecte la rugosité correspondant aux cells
		float rug <- rugosityValueOfUA_name (ua_name);
		ask cells {rugosity <- rug;} 	
	}
	action apply_Densification (int a_id_commune) {
		
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
			match "peu dense" {acolor <- listC[2];} 
			match "densité intermédiaire" {acolor <- listC[5];}
			match "dense" {acolor <- listC[7];}
			default {acolor <- # yellow; }
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
	string commune_name; //["stpierre", "dolus","sttrojan","lechateau"]
	string network_name;
	int budget;
	int impot_recu <-0;
	bool subvention_habitat_adapte <- false;
	list<UA> UAs ;
	list<cell> cells ;
	
	// 0.42 correspond à  21 € / hab convertit au taux de la monnaie du jeu (le taux est de 50)   // comme construire une digue dans le jeu vaut 20 alors que ds la réalité ça vaut 1000 , -> facteur 50  -> le impot_unit = 21/50= 0.42 
	// Ajustement pour réduire un peu les écarts -> 0.42 de base et 0.38 pour stpierre et 0.9 pour sttrojan
	float impot_unit <- commune_name="stpierre"?0.38:(commune_name="sttrojan"?0.9:0.42); 
	
	/* initialisation des hauteurs d'eau */ 
	float U_0_5c <-0.0;	float U_1c <-0.0;	float U_maxc <-0.0;
	float Us_0_5c <-0.0;	float Us_1c <-0.0;	float Us_maxc <-0.0;
	float Udense_0_5c <-0.0;	float Udense_1c <-0.0;	float Udense_maxc <-0.0;
	float AU_0_5c <-0.0; float AU_1c <-0.0; float AU_maxc <-0.0;
	float A_0_5c <-0.0;	float A_1c <-0.0;	float A_maxc <-0.0;
	float N_0_5c <-0.0;	float N_1c <-0.0;	float N_maxc <-0.0;
	float surface_inondee <- 0.0;
	list<float> data_surface_inondee <- [];
	float totU <- 0.0;
	list<float> data_totU <- [];
	float totUs <- 0.0;
	list<float> data_totUs <- [];
	float totUdense <- 0.0;
	list<float> data_totUdense <- [];
	float totAU <- 0.0;
	list<float> data_totAU <- [];
	float totN <- 0.0;
	list<float> data_totN <- [];
	float totA <- 0.0;
	list<float> data_totA <- [];

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
	
	action inform_current_round {  //  USED WHEN A COMMUNE CONNECTS TO INFORM IT WHICH ROUND IT IS
		ask network_player
		{
			map<string,string> msg <- [
			"TOPIC"::"INFORM_CURRENT_ROUND",
			"commune_name"::myself.commune_name,
			"round"::round
			];
			do send  to:myself.commune_name+"_map_msg" contents:msg;
		}
	}

	action send_player_commune_update  //  USED WHEN A COMMUNE CONNECTS TO GIVE THE CURRENT STATE OF THE COMMNUNE
	{
		ask network_player
		{
			map<string,string> msg <- [
			"TOPIC"::"COMMUNE_UPDATE",
			"commune_name"::myself.commune_name,
			"budget"::myself.budget
			];
			do send  to:myself.commune_name+"_map_msg" contents:msg;
		}
	}
	action inform_new_round {  // INFORM THAT A NEW ROUND HAS PASS
		ask network_player
		{
			map<string,string> msg <- [
			"TOPIC"::"INFORM_NEW_ROUND",
			"commune_name"::myself.commune_name
			];
			do send  to:myself.commune_name+"_map_msg" contents:msg;
		}
	}
	
	action calculate_indicators_t0 
	{
			list<def_cote> my_def_cote <- def_cote where(each.commune_name_shpfile = world.commune_name_shpfile_of_commune_name(commune_name));
			length_dikes_t0 <- my_def_cote where (each.type_def_cote = 'digue') sum_of (each.shape.perimeter);
			length_dunes_t0 <- my_def_cote where (each.type_def_cote = 'dune') sum_of (each.shape.perimeter);
			count_UA_urban_t0 <- length (UAs where (each.isUrbanType));
			count_UA_UandAU_inCoastBorderArea_t0 <- length (UAs where (each.isUrbanType and not(each.isAdapte) and each intersects first(coast_border_area)));
			count_UA_urban_infloodRiskArea_t0 <- length (UAs where (each.isUrbanType and each intersects all_flood_risk_area));
			count_UA_urban_dense_infloodRiskArea_t0 <- length (UAs where (each.isUrbanType and each.classe_densite = 'dense' and each intersects all_flood_risk_area));
			count_UA_urban_dense_inCoastBorderArea_t0 <- length (UAs where (each.isUrbanType and each.classe_densite = 'dense' and each intersects union(coast_border_area)));
			count_UA_A_t0 <- length (UAs where (each.ua_name = 'A'));
			count_UA_N_t0 <- length (UAs where (each.ua_name = 'N'));
			count_UA_AU_t0 <- length (UAs where (each.ua_name = 'AU'));
			count_UA_U_t0 <- length (UAs where (each.ua_name = 'U'));
	
	}
	action calcul_impots {
		impot_recu <- current_population(self) * impot_unit;
		budget <- budget + impot_recu;
		write commune_name + "-> impot " + impot_recu + " ; budget "+ budget;
	}
	
	action record_payment_for_action_done (action_done aAction)
			{
				budget <- budget - aAction.cost;
	}
							
}

species indicators
// Indicateurs calculés par le Modèle à l’initialisation. Lorsque Leader se connecte, le Modèle lui renvoie la valeur de ces indicateurs en même temps
{
	
	int lineaire_cote_stpierre <- 0#m;
	int lineaire_cote_dolus <- 0#m;
	int lineaire_cote_lechateau <- 0#m;
	int lineaire_cote_sttrojan <- 0#m;
	int lineaire_digue_stpierre <- 0#m;
	int lineaire_digue_dolus <- 0#m;
	int lineaire_digue_lechateau <- 0#m;
	int lineaire_digue_sttrojan <- 0#m;
	int lineaire_dune_stpierre <- 0#m;
	int lineaire_dune_dolus <- 0#m;
	int lineaire_dune_lechateau <- 0#m;
	int lineaire_dune_sttrojan <- 0#m;
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
		if( nb_button = 7)
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
		display carte_oleron //autosave : true
		{
			grid cell ;
			species cell aspect: elevation_eau_ou_eau_max; //elevation_eau;
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
//			species inland_dike_area aspect: base;
//			species coast_border_area aspect: base;		
//			species flood_risk_area aspect: base;
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
			
		display "Budgets" {
				chart "Budget des communes" type: series {
				 	data "St Pierre"
					value:data_budget_C1
				 	color:#red;
				 	data "Dolus"
					value:data_budget_C2
				 	color:#blue;
				 	data "Le Chateau"
					value:data_budget_C3
				 	color:#green;
				 	data "St Trojan"
					value:data_budget_C4
				 	color:#black;			
				}
			}
		
		display Barplots
			{
				chart "Zone U" type: histogram background: rgb("white") size: {0.31,0.4} position: {0, 0}
				{
					data "0.5" 
						value:(communes_en_jeu collect each.U_0_5c)
						style:stack
						color: world.color_of_water_height(0.5);
					data  "1"
						value:(communes_en_jeu collect each.U_1c)
						style:stack
						color: world.color_of_water_height(0.9); 
					data ">1" 
						value:(communes_en_jeu collect each.U_maxc)
						style:stack
						color: world.color_of_water_height(1.9); 
				}
				chart "Zone Us" type: histogram background: rgb("white") size: {0.31,0.4} position: {0.33, 0}
				{
					data "0.5" 
						value:(communes_en_jeu collect each.Us_0_5c)
						style:stack
						color: world.color_of_water_height(0.5);
					data  "1"
						value:(communes_en_jeu collect each.Us_1c)
						style:stack
						color: world.color_of_water_height(0.9); 
					data ">1" 
						value:(communes_en_jeu collect each.Us_maxc)
						style:stack
						color: world.color_of_water_height(1.9); 
				}
				chart "Zone U dense" type: histogram background: rgb("white") size: {0.31,0.4} position: {0.66, 0}
				{
					data "0.5" 
						value:(communes_en_jeu collect each.Udense_0_5c)
						style:stack
						color: world.color_of_water_height(0.5);
					data  "1"
						value:(communes_en_jeu collect each.Udense_1c)
						style:stack
						color: world.color_of_water_height(0.9); 
					data ">1" 
						value:(communes_en_jeu collect each.Udense_maxc)
						style:stack
						color: world.color_of_water_height(1.9); 
				}
				chart "Zone AU" type: histogram background: rgb("white") size: {0.31,0.4} position: {0, 0.5}
				{
					data "0.5" 
						value:(communes_en_jeu collect each.AU_0_5c)
						style:stack
						color: world.color_of_water_height(0.5);
					data  "1"
						value:(communes_en_jeu collect each.AU_1c)
						style:stack
						color: world.color_of_water_height(0.9); 
					data ">1" 
						value:(communes_en_jeu collect each.AU_maxc)
						style:stack
						color: world.color_of_water_height(1.9); 
				}
				chart "Zone A" type: histogram background: rgb("white") size: {0.31,0.4} position: {0.33, 0.5}
				{
					data "0.5" 
						value:(communes_en_jeu collect each.A_0_5c)
						style:stack
						color: world.color_of_water_height(0.5);
					data  "1"
						value:(communes_en_jeu collect each.A_1c)
						style:stack
						color: world.color_of_water_height(0.9); 
					data ">1" 
						value:(communes_en_jeu collect each.A_maxc)
						style:stack
						color: world.color_of_water_height(1.9); 
				}
				chart "Zone N" type: histogram background: rgb("white") size: {0.31,0.4} position: {0.66, 0.5}
				{
					data "0.5" 
						value:(communes_en_jeu collect each.N_0_5c)
						style:stack
						color: world.color_of_water_height(0.5);
					data  "1"
						value:(communes_en_jeu collect each.N_1c)
						style:stack
						color: world.color_of_water_height(0.9); 
					data ">1" 
						value:(communes_en_jeu collect each.N_maxc)
						style:stack
						color: world.color_of_water_height(1.9); 
				}
			}
				
		display "VIDE"
		{
			
		}	
		display "Surface inondée par commune"
		{
			chart "Surface inondée par commune" type: series
			{
				datalist value:length(commune) = 0 ? [0,0,0,0]:[((commune first_with(each.id = 1)).data_surface_inondee),((commune first_with(each.id = 2)).data_surface_inondee),((commune first_with(each.id = 3)).data_surface_inondee),((commune first_with(each.id = 4)).data_surface_inondee)] color:[#red,#blue,#green,#black]  legend:(((commune where (each.id > 0)) sort_by (each.id)) collect each.commune_name); 			
			}
		}
		display "Surface U inondée par commune"
		{
			chart "Surface U inondée par commune" type: series
			{
				datalist value:length(commune) = 0 ? [0,0,0,0]:[((commune first_with(each.id = 1)).data_totU),((commune first_with(each.id = 2)).data_totU),((commune first_with(each.id = 3)).data_totU),((commune first_with(each.id = 4)).data_totU)] color:[#red,#blue,#green,#black]  legend:(((commune where (each.id > 0)) sort_by (each.id)) collect each.commune_name); 			
			}
		}
		display "Surface Us inondée par commune"
		{
			chart "Surface Us inondée par commune" type: series
			{
				datalist value:length(commune) = 0 ? [0,0,0,0]:[((commune first_with(each.id = 1)).data_totUs),((commune first_with(each.id = 2)).data_totUs),((commune first_with(each.id = 3)).data_totUs),((commune first_with(each.id = 4)).data_totUs)] color:[#red,#blue,#green,#black]  legend:(((commune where (each.id > 0)) sort_by (each.id)) collect each.commune_name); 			
			}
		}
		display "Surface Udense inondée par commune"
		{
			chart "Surface Udense inondée par commune" type: series
			{
				datalist value:length(commune) = 0 ? [0,0,0,0]:[((commune first_with(each.id = 1)).data_totUdense),((commune first_with(each.id = 2)).data_totUdense),((commune first_with(each.id = 3)).data_totUdense),((commune first_with(each.id = 4)).data_totUdense)] color:[#red,#blue,#green,#black]  legend:(((commune where (each.id > 0)) sort_by (each.id)) collect each.commune_name); 			
			}
		}
		display "Surface AU inondée par commune"
		{
			chart "Surface AU inondée par commune" type: series
			{
				datalist value:length(commune) = 0 ? [0,0,0,0]:[((commune first_with(each.id = 1)).data_totAU),((commune first_with(each.id = 2)).data_totAU),((commune first_with(each.id = 3)).data_totAU),((commune first_with(each.id = 4)).data_totAU)] color:[#red,#blue,#green,#black]  legend:(((commune where (each.id > 0)) sort_by (each.id)) collect each.commune_name); 			
			}
		}
		display "Surface N inondée par commune"
		{
			chart "Surface N inondée par commune" type: series
			{
				datalist value:length(commune) = 0 ? [0,0,0,0]:[((commune first_with(each.id = 1)).data_totN),((commune first_with(each.id = 2)).data_totN),((commune first_with(each.id = 3)).data_totN),((commune first_with(each.id = 4)).data_totN)] color:[#red,#blue,#green,#black]  legend:(((commune where (each.id > 0)) sort_by (each.id)) collect each.commune_name); 			
			}
		}
		display "Surface A inondée par commune"
		{
			chart "Surface A inondée par commune" type: series
			{
				datalist value:length(commune) = 0 ? [0,0,0,0]:[((commune first_with(each.id = 1)).data_totA),((commune first_with(each.id = 2)).data_totA),((commune first_with(each.id = 3)).data_totA),((commune first_with(each.id = 4)).data_totA)] color:[#red,#blue,#green,#black]  legend:(((commune where (each.id > 0)) sort_by (each.id)) collect each.commune_name); 			
			}
		}
	}
}
		

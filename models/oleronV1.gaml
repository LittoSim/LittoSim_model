/**
 *  oleronV1
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

model oleronV1

global  {

	string COMMAND_SEPARATOR <- ":";
	string MANAGER_NAME <- "model_manager";
	string GROUP_NAME <- "Oleron";  
	string BUILT_DYKE_TYPE <- "nouvelle digue"; // Type de nouvelle digue
	float  STANDARD_DYKE_SIZE <- 1.5#m; ////// hauteur d'une nouvelle digue	
	string BUILT_DYKE_STATUS <- "tres bon"; // status de nouvelle digue
	
	//récupération des couts du fichier cout_action
	int ACTION_COST_LAND_COVER_TO_A <- int(all_action_cost at {2,1});
	int ACTION_COST_LAND_COVER_TO_AU <- int(all_action_cost at {2,2});
	int ACTION_COST_LAND_COVER_FROM_AU_TO_N <- int(all_action_cost at {2,3});
	int ACTION_COST_LAND_COVER_FROM_A_TO_N <- int(all_action_cost at {2,8});
	int ACTION_COST_DYKE_CREATE <- int(all_action_cost at {2,4});
	int ACTION_COST_DYKE_REPAIR <- int(all_action_cost at {2,5});
	int ACTION_COST_DYKE_DESTROY <- int(all_action_cost at {2,6});
	int ACTION_COST_DYKE_RAISE <- int(all_action_cost at {2,7});
	
	int ACTION_REPAIR_DYKE <- 5;
	int ACTION_CREATE_DYKE <- 6;
	int ACTION_DESTROY_DYKE <- 7;
	int ACTION_RAISE_DYKE <- 8;
	//int ACTION_DYKE_LIST <- 21;

	int ACTION_MODIFY_LAND_COVER_AU <- 1;
	int ACTION_MODIFY_LAND_COVER_A <- 2;
	int ACTION_MODIFY_LAND_COVER_U <- 3;
	int ACTION_MODIFY_LAND_COVER_N <- 4;
	list<int> ACTION_LIST <- [CONNECTION_MESSAGE,ACTION_MESSAGE,REFRESH_ALL,ACTION_REPAIR_DYKE,ACTION_CREATE_DYKE,ACTION_DESTROY_DYKE,ACTION_RAISE_DYKE,ACTION_MODIFY_LAND_COVER_AU,ACTION_MODIFY_LAND_COVER_A,ACTION_MODIFY_LAND_COVER_U,ACTION_MODIFY_LAND_COVER_N];
	
			
	int ACTION_LAND_COVER_UPDATE<-9;
	int ACTION_DYKE_UPDATE<-10;
	//action to acknwoledge client requests.
//	int ACTION_DYKE_REPAIRED <- 15;
	int ACTION_DYKE_CREATED <- 16;
	int ACTION_DYKE_DROPPED <- 17;
//	int ACTION_DYKE_RAISED <- 18;
	int UPDATE_BUDGET <- 19;
	int REFRESH_ALL <- 20;
	int ACTION_MESSAGE <- 22;
	int CONNECTION_MESSAGE <- 23;
	

	int VALIDATION_ACTION_MODIFY_LAND_COVER_AU <- 11;
	int VALIDATION_ACTION_MODIFY_LAND_COVER_A <- 12;
	int VALIDATION_ACTION_MODIFY_LAND_COVER_U <- 13;
	int VALIDATION_ACTION_MODIFY_LAND_COVER_N <- 14;
	int ACTION_DYKE_LIST <- 21;
	
	string stateSimPhase <- 'not started'; // stateSimPhase is used to specify the currrent phase of the simulation 
	//5 possible states 'not started' 'game' 'execute lisflood' 'show lisflood' and 'flood stats' 	
	int messageID <- 0;
	bool sauver_shp <- false ; // si vrai on sauvegarde le resultat dans un shapefile
	string resultats <- "resultats.shp"; //	on sauvegarde les résultats dans ce fichier (attention, cela ecrase a chaque fois le resultat precedent)
	int cycle_sauver <- 100; //cycle à laquelle les resultats sont sauvegardés au format shp
	/* lisfloodReadingStep is used to indicate to which step of lisflood results, the current cycle corresponds */
	int lisfloodReadingStep <- 9999999; //  lisfloodReadingStep = 9999999 it means that their is no lisflood result corresponding to the current cycle
	string timestamp <- ""; // variable utilisée pour spécifier un nom unique au répertoire de sauvegarde des résultats de simulation de lisflood
	matrix<string> all_action_cost <- matrix<string>(csv_file("../includes/cout_action.csv",";"));	
	
	//buttons size
	float button_size <- 2000#m;
	int step_button <- 1;
	int subvention_b <- 1;
	int taxe_b <- 1;
	string UNAM_DISPLAY_c <- "UnAm";
	string active_display <- nil;
	point previous_clicked_point <- nil;
	
	action_done current_action <- nil;

	//// tableau des données de budget des communes pour tracer le graph d'évaolution des budgets
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
	
		/*
	 * Chargements des données SIG
	 */
		file communes_shape <- file("../includes/zone_etude/communes.shp");
		file road_shape <- file("../includes/zone_etude/routesdepzone.shp");
		file defenses_cote_shape <- file("../includes/zone_etude/defense_cote_littoSIM-05122015.shp");
		// OPTION 1 -> Zone d'étude
		file emprise_shape <- file("../includes/zone_etude/emprise_ZE_littoSIM.shp"); 
		file dem_file <- file("../includes/zone_etude/mnt_corrige.asc") ;
		int nb_cols <- 631;
		int nb_rows <- 906;
		// OPTION 2 -> Zone restreinte
		/*file emprise_shape <- file("../includes/zone_restreinte/cadre.shp");
		file coastline_shape <- file("../includes/zone_restreinte/contour.shp");
		file dem_file <- file("../includes/zone_restreinte/mnt.asc") ;
		int nb_cols <- 250;
		int nb_rows <- 175;	*/
		
	//couches joueurs
		file unAm_shape <- file("../includes/zone_etude/zones241115.shp");	

	/* Definition de l'enveloppe SIG de travail */
		geometry shape <- envelope(emprise_shape);
	
	
	int round <- 0;
	list<UA> agents_to_inspect update: 10 among UA;
	game_controller network_agent <- nil;

init
	{
		/*Les actions contenu dans le bloque init sonr exécuté à l'initialisation du modele*/
		/* initialisation du bouton */
		do init_buttons;
		create game_controller number:1 returns:ctl ;
		stateSimPhase <- 'not started';
		network_agent <- first(ctl);
		/*Creation des agents a partir des données SIG */
		create ouvrage from:defenses_cote_shape  with:[id_ouvrage::int(read("OBJECTID")),type::string(read("Type_de_de")), status::string(read("Etat_ouvr")), alt::float(get("alt")), height::float(get("hauteur")) ];
		create commune from:communes_shape with: [nom_raccourci::string(read("NOM_RAC")),id::int(read("id_jeu"))]
		{
			write " commune " + nom_raccourci + " "+id;
		}
		create road from: road_shape;
		create UA from: unAm_shape with: [id::int(read("FID_1")),ua_code::int(read("grid_code")), population:: int(get("Avg_ind_c")), cout_expro:: int(get("coutexpr"))]
		{
			switch (ua_code)
			{
				match 1 {ua_name <- "N";}
				match 2 {ua_name <- "U";}
				match 4 {ua_name <- "AU";}
				match 5 {ua_name <- "A";}
			}
			my_color <- cell_color();
		}
		do load_rugosity;
		ask UA {cells <- cell overlapping self;}
		ask commune {UAs <- UA overlapping self;}
		ask commune {cells <- cell overlapping self;}
		ask ouvrage {cells <- cell overlapping self;}
	}


// reflex affiche_budget {
// 	ask commune {write "budget "+ nom_raccourci +" : " + budget;}
// 	}
 
 	
 int getMessageID
 	{
 		messageID<- messageID +1;
 		return messageID;
 	}
 	
action tourDeJeu{
	//do sauvegarder_resultat;
	write "new round "+ (round +1);
	if round != 0
	   {ask ouvrage {do evolveStatus;}
		ask UA {do evolveUA;}
		ask commune where (each.id > 0) {
			do recevoirImpots; not_updated<-true;
			}}
	else {stateSimPhase <- 'game'; write stateSimPhase;}
	round <- round + 1;
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


reflex flood_stats when: stateSimPhase = 'flood stats'
	{// fin innondation
		// affichage des résultats 
		do display_communes_results;
		// remise à zero des hauteurs d'eau
		loop r from: 0 to: nb_rows -1  {
						loop c from:0 to: nb_cols -1 {cell[c,r].water_height <- 0.0;
													cell[c,r].max_water_height <- 0.0;
						}  }
		// annulation des ruptures de digues				
		ask ouvrage {if rupture = 1 {do removeRupture;}}
		// redémarage du jeu
		if round = 0 {stateSimPhase <- 'not started'; } else {stateSimPhase <- 'game';}
		write stateSimPhase;
		}
		
reflex show_lisflood when: stateSimPhase = 'show lisflood'
	{// lecture des fichiers innondation
	do readLisfloodInRep("results"+timestamp);
	}
		
action launchFloodPhase 
	{ // déclenchement innondation
		stateSimPhase <- 'execute lisflood';	write stateSimPhase;
		if round != 0 {
			ask ouvrage {do calcRupture;} 
			do executeLisflood; // comment this line if you only want to read already existing results
		} 
		set lisfloodReadingStep <- 0;
		stateSimPhase <- 'show lisflood'; write stateSimPhase;
	}

 	
action executeLisflood
	{	timestamp <- machine_time ;
		do save_dem;  
		do save_rugosityGrid;
		do save_lf_launch_files;
		map values <- user_input(["Input files for flood simulation "+timestamp+" are ready.

BEFORE TO CLICK OK
-Launch '../includes/lisflood-fp-604/lisflood_oleron_current.bat' to generate outputs

WAIT UNTIL Lisflood finishes calculations to click OK (Dos command will close when finish) " :: 100]);
 		}
 		
action save_lf_launch_files {
		save ("DEMfile         oleron_dem_t"+timestamp+".asc\nresroot         res\ndirroot         results\nsim_time        43400.0\ninitial_tstep   10.0\nmassint         100.0\nsaveint         3600.0\n#checkpoint     0.00001\n#overpass       100000.0\n#fpfric         0.06\n#infiltration   0.000001\n#overpassfile   buscot.opts\nmanningfile     oleron_n_t"+timestamp+".asc\n#roadfile      buscot.road\nbcifile         oleron.bci\nbdyfile         oleron.bdy\n#weirfile       buscot.weir\nstartfile      oleron.start\nstartelev\n#stagefile      buscot.stage\nelevoff\n#depthoff\n#adaptoff\n#qoutput\n#chainageoff\nSGC_enable\n") rewrite: true  to: "../includes/lisflood-fp-604/oleron_"+timestamp+".par" type: "text"  ;
		save ("lisflood -dir results"+ timestamp +" oleron_"+timestamp+".par") rewrite: true  to: "../includes/lisflood-fp-604/lisflood_oleron_current.bat" type: "text"  ;  
		}       

action save_dem {
		string filename <- "../includes/lisflood-fp-604/oleron_dem_t" + timestamp + ".asc";
		//OPTION 1 -> Zone d'étude
		save 'ncols         631\nnrows         906\nxllcorner     364927.14666668\nyllcorner     6531972.5655556\ncellsize      20\nNODATA_value  -9999' rewrite: true to: filename type:"text";
		//OPTION 2 -> Zone restreinte
		//save 'ncols        250\nnrows        175\nxllcorner    368987.146666680000\nyllcorner    6545012.565555600400\ncellsize     20.000000000000\nNODATA_value  -9999' to: filename;			
		loop j from: 0 to: nb_rows- 1 {
			string text <- "";
			loop i from: 0 to: nb_cols - 1 {
				text <- text + " "+ cell[i,j].soil_height;}
			save text to:filename;
			}
		}  
		
action save_rugosityGrid {
		string filename <- "../includes/lisflood-fp-604/oleron_n_t" + timestamp + ".asc";
		//OPTION 1 -> Zone d'étude
		save 'ncols         631\nnrows         906\nxllcorner     364927.14666668\nyllcorner     6531972.5655556\ncellsize      20\nNODATA_value  -9999' rewrite: true to: filename type:"text";
		//OPTION 2 -> Zone restreinte
		//save 'ncols        250\nnrows        175\nxllcorner    368987.146666680000\nyllcorner    6545012.565555600400\ncellsize     20.000000000000\nNODATA_value  -9999' to: filename;			
		loop j from: 0 to: nb_rows- 1 {
			string text <- "";
			loop i from: 0 to: nb_cols - 1 {
				text <- text + " "+ cell[i,j].rugosity;}
			save text to:filename;
			}
		}  
		
	   
action readLisfloodInRep (string rep)
	 {  string nb <- lisfloodReadingStep;
		loop i from: 0 to: 3-length(nb) { nb <- "0"+nb; }
		 file lfdata <- text_file("../includes/lisflood-fp-604/"+rep+"/res-"+ nb +".wd") ;
		 write "/res-"+ nb +".wd";
		 if lfdata.exists
			{
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
					stateSimPhase <- 'flood stats'; write stateSimPhase;}   }	   
	}
	
action load_rugosity
     { file rug_data <- text_file("../includes/lisflood-fp-604/oleron.n.ascii") ;
			loop r from: 6 to: length(rug_data) -1 {
				string l <- rug_data[r];
				list<string> res <- l split_with " ";
				loop c from: 0 to: length(res) - 1{
					cell[c,r-6].rugosity <- float(res[c]);}}	
	}


action display_communes_results
		{	string text <- "";
			ask commune where (each.id >0)
			{  	int tot <- length(cells) ; 
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
								if max_water_height <= 0.5 {U_0_5 <- U_0_5 +1;}
								if between (max_water_height ,0.5, 1) {U_1 <- U_1 +1;}
								if max_water_height >= 1 {U_max <- U_max +1 ;}
								}
							match "AU" {
								if max_water_height <= 0.5 {AU_0_5 <- AU_0_5 +1;}
								if between (max_water_height ,0.5, 1) {AU_1 <- AU_1 +1;}
								if max_water_height >= 1 {AU_max <- AU_max +1 ;}
								}
							match "N" {
								if max_water_height <= 0.5 {N_0_5 <- N_0_5 +1;}
								if between (max_water_height ,0.5, 1) {N_1 <- N_1 +1;}
								if max_water_height >= 1 {N_max <- N_max +1 ;}
								}
							match "A" {
								if max_water_height <= 0.5 {A_0_5 <- A_0_5 +1;}
								if between (max_water_height ,0.5, 1) {A_1 <- A_1 +1;}
								if max_water_height >= 1 {A_max <- A_max +1 ;}
								}	
							}
							
							}
					}
					}
				text <- text + "Résultats commune " + nom_raccourci +"
Surface U innondée : moins de 50cm " + ((U_0_5 * 0.04) with_precision 1) +"ha ("+ ((U_0_5 / tot * 100) with_precision 1) +"%) | entre 50cm et 1m" + ((U_1 * 0.04) with_precision 1) +"ha ("+ ((U_1 / tot * 100) with_precision 1) +"%) | plus de 1m " + ((U_max * 0.04) with_precision 1) +"ha ("+ ((U_max / tot * 100) with_precision 1) +"%) 
Surface AU innondée : moins de 50cm " + ((AU_0_5 * 0.04) with_precision 1) +"ha ("+ ((AU_0_5 / tot * 100) with_precision 1) +"%) | entre 50cm et 1m" + ((AU_1 * 0.04) with_precision 1) +"ha ("+ ((AU_1 / tot * 100) with_precision 1) +"%) | plus de 1m " + ((AU_max * 0.04) with_precision 1) +"ha ("+ ((AU_max / tot * 100) with_precision 1) +"%) 
Surface A innondée : moins de 50cm " + ((A_0_5 * 0.04) with_precision 1) +"ha ("+ ((A_0_5 / tot * 100) with_precision 1) +"%) | entre 50cm et 1m" + ((A_1 * 0.04) with_precision 1) +"ha ("+ ((A_1 / tot * 100) with_precision 1) +"%) | plus de 1m " + ((A_max * 0.04) with_precision 1) +"ha ("+ ((A_max / tot * 100) with_precision 1) +"%) 
Surface N innondée : moins de 50cm " + ((N_0_5 * 0.04) with_precision 1) +"ha ("+ ((N_0_5 / tot * 100) with_precision 1) +"%) | entre 50cm et 1m" + ((N_1 * 0.04) with_precision 1) +"ha ("+ ((N_1 / tot * 100) with_precision 1) +"%) | plus de 1m " + ((N_max * 0.04) with_precision 1) +"ha ("+ ((N_max / tot * 100) with_precision 1) +"%) 
--------------------------------------------------------------------------------------------------------------------
" ;	
			}
		map values <- user_input([ text :: 100]);	
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


species action_done schedules:[]
{
	string id;
	int chosen_element_id;
	string doer<-"";
	//string command_group <- "";
	int command <- -1;
	string label <- "no name";
	float cost <- 0.0;	
	list<string> my_message <-[];
	rgb define_color
	{
		switch(command)
		{
			 match ACTION_CREATE_DYKE { return #blue;}
			 match ACTION_REPAIR_DYKE {return #green;}
			 match ACTION_DESTROY_DYKE {return #brown;}
			 match ACTION_MODIFY_LAND_COVER_A { return #brown;}
			 match ACTION_MODIFY_LAND_COVER_AU {return #orange;}
			 match ACTION_MODIFY_LAND_COVER_N {return #green;}
		} 
		return #grey;
	}
	
	
	
	aspect base
	{
		draw  20#m around shape color:define_color() border:#red;
	}

	
	aspect base
	{
		draw shape color:define_color();
	}
	
	ouvrage create_dyke(action_done act)
	{
		int id_ov <- max(ouvrage collect(each.id_ouvrage))+1;
		create ouvrage number:1 returns:ovgs
		{
			id_ouvrage <- id_ov;
			shape <- act.shape;
			type <- BUILT_DYKE_TYPE ;
			status <- BUILT_DYKE_STATUS;
			height <- STANDARD_DYKE_SIZE;	
			cells <- cell overlapping self;
		}
		return first(ovgs);
	}
	
}


species game_controller skills:[network]
{
	init
	{
		do connectMessenger to:GROUP_NAME at:"localhost" withName:MANAGER_NAME;
	}
	
	reflex wait_message 
	{
		loop while:!emptyMessageBox()
		{
			map msg <- fetchMessage();
			if(msg["sender"]!=MANAGER_NAME )
			{
				write msg;
				list<string> data <- string(msg["content"]) split_with COMMAND_SEPARATOR;
		
				if(CONNECTION_MESSAGE = int(data[0]))
				{
					int idCom <-world.commune_id(msg["sender"]);
					write "connexion de "+ msg["sender"] + " "+ idCom;
					return;
				}
		
				if(round>0) 
				{
					do read_action(msg["content"],msg["sender"]);
					
				}
			}
			
					
		}
	}
	
	reflex apply_action when:length(action_done)>0 
	{
		ask(action_done)
		{
			string tmp <- self.doer;
			int idCom <-world.commune_id(tmp);
			switch(command)
			{
				match ACTION_MESSAGE
				{
					write self.doer +" -> "+my_message;
				}
				match REFRESH_ALL
				{
					write " Update ALL !!!! " + idCom+ " "+ doer;
					commune cm <- first(commune where(each.id=idCom));
					ask ouvrage overlapping cm { not_updated <- true;}
					ask UA overlapping cm { not_updated <- true;}
					ask cm {not_updated <- true;}
					ask game_controller
					{
						do send_dyke_list(idCom);
					}
				}
				
				match ACTION_CREATE_DYKE
				{	
					ouvrage ovg <-  create_dyke(self);
					ask network_agent
					{
						do send_create_dyke_message(ovg);
					}
					ask(ovg) {do new_dyke_by_commune (idCom) ;
					}
				}
				match ACTION_REPAIR_DYKE {
					ask(ouvrage first_with(each.id_ouvrage=chosen_element_id))
					{
						do repair_by_commune(idCom);
						not_updated <- true;
					}		
				}
			 	match ACTION_DESTROY_DYKE 
			 	 {
			 		ask(ouvrage first_with(each.id_ouvrage=chosen_element_id))
					{
						ask network_agent
						{
							do send_destroy_dyke_message(myself);
						}
						do destroy_by_commune (idCom) ;
						not_updated <- true;
					}		
				}
			 	match ACTION_RAISE_DYKE {
			 		ask(ouvrage first_with(each.id_ouvrage=chosen_element_id))
					{
						do increase_height_by_commune (idCom) ;
						not_updated <- true;
					}
				}
			 	match ACTION_MODIFY_LAND_COVER_A {
			 		ask UA first_with(each.id=chosen_element_id)
			 		 {
			 		  do modify_UA (idCom, 5);
			 		  not_updated <- true;
			 		 }
			 	}
			 	match ACTION_MODIFY_LAND_COVER_AU {
			 		ask UA first_with(each.id=chosen_element_id)
			 		 {
			 		 	do modify_UA (idCom, 4);
			 		 	not_updated <- true;
			 		 }
			 	}
				match ACTION_MODIFY_LAND_COVER_N {
					ask UA first_with(each.id=chosen_element_id)
			 		 {
			 		 	do modify_UA (idCom, 1);
			 		 	not_updated <- true;
			 		 }
			 	}
			}
			do die;
		}
	}
	
	action read_action(string act, string sender)
	{
		list<string> data <- act split_with COMMAND_SEPARATOR;
		
		if(! (ACTION_LIST contains int(data[0])) )
		{
			return;
		}
		
		action_done tmp_agent <- nil;
		create action_done number:1 returns:tmp_agent_list;
		tmp_agent <- first(tmp_agent_list);
		ask(tmp_agent)
		{
			self.command <- int(data[0]);
			self.id <- int(data[1]);
			self.doer <- sender;
			self.my_message <- data;
			
			switch(self.command)
			{
				match ACTION_CREATE_DYKE
				{
					point ori <- {float(data[2]),float(data[3])};
					point des <- {float(data[4]),float(data[5])};
					point loc <- {float(data[6]),float(data[7])}; 
					shape <- polyline([ori,des]);
					location <- loc; 
				}
				match ACTION_MESSAGE {}
				match REFRESH_ALL {}
				default {
					self.chosen_element_id <- int(data[2]);
				}
				
			}	
		}
		
	}
	
	
	
	reflex send_space_update
	{
		do update_UA;
		do update_dyke;
		do update_commune;
	}
	
	action update_UA
	{
		list<string> update_messages <-[];
		list<UA> updated_UA <- [];
		ask UA where(each.not_updated)
		{
			string msg <- ""+ACTION_LAND_COVER_UPDATE+COMMAND_SEPARATOR+world.getMessageID() +COMMAND_SEPARATOR+id+COMMAND_SEPARATOR+self.ua_code;
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
			{
				do sendMessage  dest:cm.network_name content:msg;
			}
			i <- i + 1;
			
		}
	}
	
	action send_destroy_dyke_message(ouvrage ovg)
	{
		string msg <- ""+ACTION_DYKE_DROPPED+COMMAND_SEPARATOR+world.getMessageID() +COMMAND_SEPARATOR+ovg.id_ouvrage;
		
		list<commune> cms <- commune overlapping ovg;
		loop cm over:cms
			{
				do sendMessage  dest:cm.network_name content:msg;
			}
	//	do sendMessage  dest:"all" content:msg;	
	
	}
	
	action send_create_dyke_message(ouvrage ovg)
	{
		point p1 <- first(ovg.shape.points);
		point p2 <- last(ovg.shape.points);
		string msg <- ""+ACTION_DYKE_CREATED+COMMAND_SEPARATOR+world.getMessageID() +COMMAND_SEPARATOR+ovg.id_ouvrage+COMMAND_SEPARATOR+p1.x+COMMAND_SEPARATOR+p1.y+COMMAND_SEPARATOR+p2.x+COMMAND_SEPARATOR+p2.y+COMMAND_SEPARATOR+ovg.height+COMMAND_SEPARATOR+ovg.type+COMMAND_SEPARATOR+ovg.status;
		list<commune> cms <- commune overlapping ovg;
			loop cm over:cms
			{
				do sendMessage  dest:cm.network_name content:msg;
			}

	//	do sendMessage  dest:"all" content:msg;	
	}
	
	action send_dyke_list(int m_commune)
	{
		string tmp<-"";
		commune m <- commune first_with(each.id=m_commune);
		ask ouvrage overlapping m
		{
			tmp <- tmp +  COMMAND_SEPARATOR+id_ouvrage;
		}
		
		string msg <- ""+ACTION_DYKE_LIST+COMMAND_SEPARATOR+world.getMessageID() +COMMAND_SEPARATOR +m.nom_raccourci+tmp;
		do sendMessage  dest:m.network_name content:msg;	
//		ACTION_DYKE_LIST
	}
	
	action update_dyke
	{
		list<string> update_messages <-[]; 
		list<ouvrage> update_ouvrage <- [];
		ask ouvrage where(each.not_updated)
		{
			point p1 <- first(self.shape.points);
			point p2 <- last(self.shape.points);
			string msg <- ""+ACTION_DYKE_UPDATE+COMMAND_SEPARATOR+world.getMessageID() +COMMAND_SEPARATOR+self.id_ouvrage+COMMAND_SEPARATOR+p1.x+COMMAND_SEPARATOR+p1.y+COMMAND_SEPARATOR+p2.x+COMMAND_SEPARATOR+p2.y+COMMAND_SEPARATOR+self.height+COMMAND_SEPARATOR+self.type+COMMAND_SEPARATOR+self.status;
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
				do sendMessage  dest:cm.network_name content:msg;
			}
			i <- i + 1;
			
		}
	}
	
	
	action update_commune
	{
		list<string> update_messages <-[]; 
		ask commune where(each.not_updated)
		{
			string msg <- ""+UPDATE_BUDGET+COMMAND_SEPARATOR+world.getMessageID() +COMMAND_SEPARATOR+ budget+COMMAND_SEPARATOR+impot_unit;
			not_updated <- false;
			ask first(game_controller)
			{
				do sendMessage  dest:myself.network_name content:msg;
				
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
			command <- step_button;
			nb_button <- 0;
			label <- "One step";
			shape <- square(button_size);
			location <- { 1000,1000 };
			my_icon <- image_file("../images/icones/one_step.png");
			display_name <- UNAM_DISPLAY_c;
		}
		create buttons number: 1
		{
			command <- step_button;
			nb_button <- 3;
			label <- "Launch Lisflood";
			shape <- square(button_size);
			location <- { 5000,1000 };
			my_icon <- image_file("../images/icones/launch_lisflood.png");
			display_name <- UNAM_DISPLAY_c;
		}
		
		create buttons number: 1
		{
			command <- subvention_b;
			nb_button <- 1;
			label <- "subvention";
			shape <- square(button_size);
			location <- { 1000 , 4000};
			my_icon <- image_file("../images/icones/subvention.png");
			display_name <- UNAM_DISPLAY_c;
		}
		
		create buttons number: 1
		{
			command <- taxe_b;
			nb_button <- 2;
			label <- "taxe";
			shape <- square(button_size);
			location <- { 1000, 6000 };
			my_icon <- image_file("../images/icones/taxe.png");
			display_name <- UNAM_DISPLAY_c;
		}
		
	}
	
	
    //Action Général appel action particulière 
    action button_click_C (point loc, list selected_agents)
	{
		
		if(active_display != UNAM_DISPLAY_c)
		{
			current_action <- nil;
			active_display <- UNAM_DISPLAY_c;
			do clear_selected_button;
			//return;
		}
		
		list<buttons> selected_UnAm_c <- (selected_agents of_species buttons) where(each.display_name=active_display );
		ask (selected_agents of_species buttons) where(each.display_name=active_display ){
			if (nb_button = 0){
				ask world {do tourDeJeu;}
			}
			if (nb_button = 3){
				ask world {do launchFloodPhase;}
			}
			
			if (nb_button = 1){
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
					ask commune first_with (each.id = int(values at "id_commune")) {budget <- budget + int(values at "amount");
					not_updated <- true;
					}
				}
				}

			
			if (nb_button = 2){
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
				 ask commune first_with (each.id = int(values at "id_commune")) {
				 	budget <- budget - int(values at "amount");
				 	not_updated <- true;
				 }
				 
				}
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
			 //
		}
		aspect elevation_eau
			{if cell_type = 1 
				{color<-#white;}
			 else{
				if water_height = 0			
				{float tmp <-  ((soil_height  / 10) with_precision 1) * 255;
					color<- rgb( 255 - tmp, 180 - tmp , 0) ; }
				else
				 {float tmp <-  min([(water_height  / 5) * 255,200]);
				 	color<- rgb( 200 - tmp, 200 - tmp , 255) /* hsb(0.66,1.0,((water_height +1) / 8)) */; }
				 }
			}	
	}


species ouvrage
{	
	int id_ouvrage;
	string type;
	string status;	// "tres bon" "bon" "moyen" "mauvais" "tres mauvais" 
	float height;  // height au pied en mètre
	float alt;
	rgb color <- # pink;
	list<cell> cells ;
	int cptStatus <-0;
	int nb_stepsForDegradStatus <-4;
	int rupture<-0;
	bool not_updated <- false;
	
	init {
		if type ='' {type <- "inconnu";}
		if status = '' {status <- "bon";} 
		if height = 0.0 {height  <- 1.5;}////////  Les ouvrages de défense qui n'ont pas de hauteur sont mis d'office à 1.5 mètre
		cells <- cell overlapping self;
	}
	
	action evolveStatus { 
		cptStatus <- cptStatus +1;
		if cptStatus = (nb_stepsForDegradStatus+1) {
			cptStatus <-0;

			if status = "mauvais" {status <- "tres mauvais";}
			if status = "moyen" {status <- "mauvais";}
			if status = "bon" {status <- "moyen";}
			if status = "tres bon" {status <- "bon";}
			not_updated<-true; 
		}
	}
	
	action calcRupture {
		int p <- 0;
		if status = "tres mauvais" {p <- 15;}
		if status = "mauvais" {p <- 10;}
		if status = "moyen" {p <- 5;}
		if status = "bon" {p <- 2;}
		if status = "tres bon" {p <- -1;}
		if rnd (100) <= p {
				set rupture <- 1;
				// apply Rupture On Cells
				ask cells  {/// todo : a changer: ne pas appliquer sur toutes les cells de l'ouvrage mais que sur une portion
							if soil_height >= 0 {soil_height <-   max([0,soil_height - myself.height]);}
				}
				write "rupture digue n°" + id_ouvrage + "(état " + status +", type "+type +", hauteur "+height+", commune "+first((commune overlapping self)).nom_raccourci +")"; 
		}
	}
	
	action removeRupture {
		rupture <- 0;
		ask cells  {if soil_height >= 0 {soil_height <-   soil_height_before_broken;}}
	}

	//La commune répare la digue
	action repair_by_commune (int a_commune_id) {
		status <- "tres bon";
		cptStatus <- 0;
		ask commune first_with(each.id = a_commune_id) {do payerReparationOuvrage (myself);}
	}
	
	//La commune relève la digue
	action increase_height_by_commune (int a_commune_id) {
		status <- "tres bon";
		cptStatus <- 0;
		height <- height + 0.5; // le réhaussement d'ouvrage est forcément de 50 centimètres
		alt <- alt + 0.5;
		ask cells {
			soil_height <- soil_height + 0.5;
			soil_height_before_broken <- soil_height ;
			}
		ask commune first_with(each.id = a_commune_id) {do payerRehaussementOuvrage (myself);}
	}
	
	//la commune détruit la digue
	action destroy_by_commune (int a_commune_id) {
		ask cells {	soil_height <- soil_height - myself.height ;}
		ask commune first_with(each.id = a_commune_id) {do payerDestructionOuvrage (myself);}
		do die;
	}
	
	//La commune construit une digue
	action new_dyke_by_commune (int a_commune_id) {
		///  Une nouvelle digue réhausse tout le terrain à la hauteur de la cell la plus haute
		float h <- cells max_of (each.soil_height);
		alt <- h + height;
		ask cells  {
			soil_height <- h + myself.height; ///  Une nouvelle digue fait 1,5 mètre -> STANDARD_DYKE_SIZE
			soil_height_before_broken <- soil_height ;
		}
		ask commune first_with(each.id = a_commune_id) {do payerConstructionOuvrage (myself);}
	}
	
	aspect base
	{  
		if status = "tres bon" {color <- # green;} 
		if status = "bon" {color <- rgb (239,204,51);} 
		if status = "moyen" {color <-  rgb (255,102,0);} 
		if status = "mauvais" {color <- # red;} 
		if status = "tres mauvais" {color <- # black;}
		if rupture  = 1 {draw circle(100) color:#red;} 
		draw 30#m around shape color: color /*size:1500#m*/;
	}
}



species road
{
	aspect base
	{
		draw shape color: rgb (125,113,53);
	}
}


species UA
{
	string ua_name;
	int id;
	int ua_code;
	rgb my_color <- cell_color() update: cell_color();
	int nb_stepsForAU_toU <-3;
	int AU_to_U_counter <- 0;
	list<cell> cells ;
	int population ;
	int cout_expro ;
	bool not_updated <- false;
	
	init {cout_expro <- (round (cout_expro /2000 /50 ))*100;} // on divise par 2 la valeur du cout expro car elle semble surévaluée 
	
	
	action modify_UA (int a_id_commune, int new_ua_code)
	{	string new_ua_name <-  nameOfUAcode(new_ua_code);
		if  ua_name = "U" and new_ua_name = "N" /*expropriation */
				{ask commune first_with (each.id = a_id_commune) {do payerExpropriationPour (myself);}}
		else {ask commune first_with (each.id = a_id_commune) {do payerModifUA (myself, new_ua_name);}
			if  ua_name = "N" and new_ua_name = "AU" /*dénaturalisation -> requière autorosation du prefet */
				{switch a_id_commune
					{	match 1 {world.count_N_to_AU_C1 <-world.count_N_to_AU_C1 +1;}
						match 2 {world.count_N_to_AU_C2 <-world.count_N_to_AU_C2 +1;}
						match 3 {world.count_N_to_AU_C3 <-world.count_N_to_AU_C3 +1;}
						match 4 {world.count_N_to_AU_C4 <-world.count_N_to_AU_C4 +1;}
					}
					
				}
		}
		ua_code <- new_ua_code;
		ua_name <- new_ua_name;
		//on affecte la rugosité correspondant aux cells
		float rug <- rugosityValueOfUA (new_ua_code);
		ask cells {rugosity <- rug;} 	
	}
	
	
	action evolveUA
		{if ua_name ="AU"
			{AU_to_U_counter<-AU_to_U_counter+1;
			if AU_to_U_counter = (nb_stepsForAU_toU +1)
				{AU_to_U_counter<-0;
				ua_name <- "U";
				ua_code<-codeOfUAname("U");
				not_updated<-true; }
			}	
		if (ua_name = "U" and population < 1000){
			population <- population + 3;}// avant c'était 10 mais après des tests c recalibré à 3
		}
		
	
		
	string nameOfUAcode (int a_ua_code) 
		{ string val <- "" ;
			switch (a_ua_code)
			{
				match 1 {val <- "N";}
				match 2 {val <- "U";}
				match 4 {val <- "AU";}
				match 5 {val <- "A";}
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
					}
		return val;}
	
	float rugosityValueOfUA (int a_ua_code) 
		{float val <- 0.0;
		 switch (a_ua_code)
			{
/* Valeur rugosité fournies par Brice
Urbain (codes CLC 112,123,142) : 			0.12	->U
Vignes (code CLC 221) : 					0.07	->A
Prairies (code CLC 241) : 					0.04	->N
Parcelles agricoles (codes CLC 211,242,243):0.06	->A
Forêt feuillus (code CLC 311) : 			0.15
Forêt conifères (code CLC 312) : 			0.16
Forêt mixte (code CLC 313) : 				0.17
Landes (code CLC 322) : 					0.07	->N
Forêt + arbustes (code CLC 324) : 			0.14
Plage - dune (code CLC 331) : 				0.03
Marais intérieur (code CLC 411) : 			0.055
Marais maritime (code CLC 421) : 			0.05
Zone intertidale (code CLC 423) : 			0.025
Mer (code CLC 523) : 						0.02				*/
				match 1 {val <- 0.05;}//N (entre 0.04 et 0.07 -> 0.05)
				match 2 {val <- 0.12;}//U
				match 4 {val <- 0.1;}//AU
				match 5 {val <- 0.06;}//A
			}
		return val;}

	rgb cell_color
	{
		rgb res <- nil;
		switch (ua_code)
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
	aspect population {
		rgb acolor <- nil;
		if population = 0 {acolor <- # white; }
		 else {acolor <- rgb(255-(population),0,0);}
		draw shape color: acolor;
		
		}
}


species commune
{	
	int id<-0;
	bool not_updated<- true;
	string nom_raccourci;
	string network_name;
	int budget <-20000;
	list<UA> UAs ;
	list<cell> cells ;
	int impot_unit <- 2;

	aspect base
	{
		draw shape color:#whitesmoke;
	}
	
	aspect outline
	{
		draw shape color: rgb (0,0,0,0) border:#black;
	}
	
	action recevoirImpots {
		int nb_impose <- sum(UAs accumulate (each.population));
		int impotRecus <- nb_impose * impot_unit;
		budget <- budget + impotRecus;
		}
		
	action payerExpropriationPour (UA a_UA)
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
					}
				if cost = 0 {write "Problème cout change UA : cout de 0 ; passade de "+  a_UA.ua_name + " à "+new_ua_name;}
				budget <- budget - cost;
				not_updated <- true;
			}
 
			
	action payerReparationOuvrage (ouvrage dk)
			{
				budget <- budget - (int(dk.shape.perimeter) * ACTION_COST_DYKE_REPAIR);
				not_updated <- true;
				
			}
			
	action payerRehaussementOuvrage (ouvrage dk)
			{
				budget <- budget - (int(dk.shape.perimeter) * ACTION_COST_DYKE_RAISE);
				not_updated <- true;
			}

	action payerDestructionOuvrage (ouvrage dk)
			{
				budget <- budget - (int(dk.shape.perimeter) * ACTION_COST_DYKE_DESTROY);
				not_updated <- true;
				
			}	
					
	action payerConstructionOuvrage (ouvrage dk)
			{
				budget <- budget - (int(dk.shape.perimeter) * ACTION_COST_DYKE_CREATE);
				not_updated <- true;
			}
						
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
	file my_icon;
	aspect base
	{
			//draw shape color:#white border: is_selected ? # red : # white;
			//draw my_icon size:button_size-50#m ;
		if( display_name = UNAM_DISPLAY_c)
		{
			draw shape color:#white border: is_selected ? # red : # white;
			draw my_icon size:button_size-50#m ;
			
		}
	}
}



/*
 * ***********************************************************************************************
 *                        EXPERIMENT DEFINITION
 *  **********************************************************************************************
 */

experiment oleronV1 type: gui {
	float minimum_cycle_duration <- 0.5;
	output {
		inspect world;
		
		display carte_oleron //autosave : true
		{
			
			grid cell ;
			species cell aspect:elevation_eau;
			species commune aspect:outline;
			species road aspect:base;
			species ouvrage aspect:base;
		}
		display Amenagement
		{
			species commune aspect: base;
			species UA aspect: base;
			species road aspect:base;
			species ouvrage aspect:base;		
		}		
		display Population
		{	
			species commune aspect: base;
			species UA aspect: population;
			species road aspect:base;			
		}
		display "Controle MdJ"
		{    // Les boutons et le clique
			species buttons aspect:base;
			event [mouse_down] action: button_click_C;
			}
			
		display graph_budget {
				chart "Series" type: series {
					datalist value:[data_budget_C1,data_budget_C2,data_budget_C3,data_budget_C4] color:[#red,#blue,#green,#black] legend:["stpierre","lechateau","dolus","sttrojan"]; 			
				}
			}
			
		display "Chgt de N à AU" {
				chart "Series" type: series {
					datalist value:[data_count_N_to_AU_C1,data_count_N_to_AU_C2,data_count_N_to_AU_C3,data_count_N_to_AU_C4] color:[#red,#blue,#green,#black] legend:["stpierre","lechateau","dolus","sttrojan"]; 			
				}
			}	
			
			}}
		

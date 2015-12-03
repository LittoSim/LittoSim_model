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
	bool sauver_shp <- false ; // si vrai on sauvegarde le resultat dans un shapefile
	string resultats <- "resultats.shp"; //	on sauvegarde les résultats dans ce fichier (attention, cela ecrase a chaque fois le resultat precedent)
	int cycle_sauver <- 100; //cycle à laquelle les resultats sont sauvegardés au format shp
	int cycle_launchLisflood <- 10; // cycle_launchLisflood specifies the cycle at which lisflood is launched
	/* lisfloodReadingStep is used to indicate to which step of lisflood results, the current cycle corresponds */
	int lisfloodReadingStep <- 9999999; //  lisfloodReadingStep = 9999999 it means that their is no lisflood result corresponding to the current cycle 
	string timestamp <- ""; // variable utilisée pour spécifier un nom unique au répertoire de sauvegarde des résultats de simulation de lisflood
	
	
	//bottum size
	float button_size <- 2000#m;
	int step_button <- 1;
	int subvention_b <- 1;
	int taxe_b <- 1;
	string UNAM_DISPLAY_c <- "UnAm";
	string active_display <- nil;
	point previous_clicked_point <- nil;
	
	action_done current_action <- nil;
	
	/*
	 * Chargements des données SIG
	 */
		file communes_shape <- file("../includes/zone_etude/communes.shp");
		file road_shape <- file("../includes/zone_etude/routesdepzone.shp");
		file defenses_cote_shape <- file("../includes/zone_etude/defense_cote_littoSIM-nb-25-11-15.shp");
		// OPTION 1 Fichiers SIG Grande Carte
		file emprise_shape <- file("../includes/zone_etude/emprise_ZE_littoSIM.shp"); 
		file dem_file <- file("../includes/zone_etude/mnt_recalcule_alti_v2.asc") ;
	//	file dem_file <- file("../includes/lisflood-fp-604/oleron_dem_t0.asc") ;	bizarrement le chargement de ce fichier là est beaucoup plus long que le chargement de celui du dessus
		int nb_cols <- 631;
		int nb_rows <- 906;
		// OPTION 2 Fichiers SIG Petite Carte
		/*file emprise_shape <- file("../includes/zone_restreinte/cadre.shp");
		file coastline_shape <- file("../includes/zone_restreinte/contour.shp");
		file dem_file <- file("../includes/zone_restreinte/mnt.asc") ;
		int nb_cols <- 250;
		int nb_rows <- 175;	*/
		
	//couches joueurs
		file unAm_shape <- file("../includes/zone_etude/zones241115.shp"
		);	

	/* Definition de l'enveloppe SIG de travail */
		geometry shape <- envelope(emprise_shape);
	

	init
	{
		/*Les actions contenu dans le bloque init sonr exécuté à l'initialisation du modele*/
		/* initialisation du bouton */
		do init_buttons;
		
		/*Creation des agents a partir des données SIG */
		create ouvrage from:defenses_cote_shape  with:[type::string(read("TYPE")), etat::string(read("Etat_Ouvra")), height::float(get("hauteur")) ];
		create commune from:communes_shape with: [id::int(get("id_jeu"))];
		create road from: road_shape;
		create UA from: unAm_shape with: [ua_code::int(read("grid_code")), population:: int(get("Avg_ind_c")), cout_expro:: int(get("coutexpr"))]
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
		ask ouvrage {cells <- cell overlapping self;}
	}
 	
	
reflex runLisflood
	{ // déclenchement innondation
	  if cycle = cycle_launchLisflood {
	  		do launchLisflood; // comment this line if you only want to read already existing results
	  		set lisfloodReadingStep <- 0;
	  		ask ouvrage {do calcRupture;} }
	  // en cours d'innondation
	  if lisfloodReadingStep !=  9999999
		{ do readLisfloodInRep("results_"+timestamp);}
	  // fin innondation
	  else {ask ouvrage {if rupture = 1 {do removeRupture;}}
	  }}

 /* pour la sauvegarde des données en format shape */
reflex sauvegarder_resultat when: sauver_shp and cycle = cycle_sauver
	{										 
		save cell type:"shp" to: resultats with: [soil_height::"SOIL_HEIGHT", water_height::"WATER_HEIGHT"];
	}
 	   
	   	
action launchLisflood
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
		save ("DEMfile         oleron_dem_t"+timestamp+".asc\nresroot         res\ndirroot         results\nsim_time        43400.0\ninitial_tstep   10.0\nmassint         100.0\nsaveint         3600.0\n#checkpoint     0.00001\n#overpass       100000.0\n#fpfric         0.06\n#infiltration   0.000001\n#overpassfile   buscot.opts\nmanningfile     oleron_dem_t"+timestamp+".asc\n#roadfile      buscot.road\nbcifile         oleron.bci\nbdyfile         oleron.bdy\n#weirfile       buscot.weir\nstartfile      oleron.start\nstartelev\n#stagefile      buscot.stage\nelevoff\n#depthoff\n#adaptoff\n#qoutput\n#chainageoff\nSGC_enable\n") rewrite: true  to: "../includes/lisflood-fp-604/oleron_"+timestamp+".par" type: "text"  ;
		save ("lisflood -dir results_"+ timestamp +" oleron_"+timestamp+".par") rewrite: true  to: "../includes/lisflood-fp-604/lisflood_oleron_current.bat" type: "text"  ;  
		}       

action save_dem {
		string filename <- "../includes/lisflood-fp-604/oleron_dem_t" + timestamp + ".asc";
		//OPTION 1 Big map
		save 'ncols         631\nnrows         906\nxllcorner     364927.14666668\nyllcorner     6531972.5655556\ncellsize      20\nNODATA_value  -9999' rewrite: true to: filename type:"text";
		//OPTION 2 Small map
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
		//OPTION 1 Big map
		save 'ncols         631\nnrows         906\nxllcorner     364927.14666668\nyllcorner     6531972.5655556\ncellsize      20\nNODATA_value  -9999' rewrite: true to: filename type:"text";
		//OPTION 2 Small map
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
		 if lfdata.exists
			{
			loop r from: 6 to: length(lfdata) -1 {
				string l <- lfdata[r];
				list<string> res <- l split_with "\t";
				loop c from: 0 to: length(res) - 1{
					cell[c,r-6].water_height <- float(res[c]);}}	
	        lisfloodReadingStep <- lisfloodReadingStep +1;
	        }
	     else { lisfloodReadingStep <-  9999999;
	     		if nb = "0000" {map values <- user_input(["Il n'y a pas de fichier de résultat lisflood pour cet évènement" :: 100]);}
	     		else{map values <- user_input(["L'innondation est terminée. Au prochain pas de temps les hauteurs d'eau seront remise à zéro" :: 100]);
					 loop r from: 0 to: nb_rows -1  {
						loop c from:0 to: nb_cols -1 {cell[c,r].water_height <- 0.0;}  }}   }	   
	}
	
action load_rugosity
     { file rug_data <- text_file("../includes/lisflood-fp-604/oleron.n.ascii") ;
			loop r from: 6 to: length(rug_data) -1 {
				string l <- rug_data[r];
				list<string> res <- l split_with " ";
				loop c from: 0 to: length(res) - 1{
					cell[c,r-6].rugosity <- float(res[c]);}}	
	}


/*
 * ***********************************************************************************************
 *                        RECEPTION ET APPLICATION DES ACTIONS DES JOUEURS 
 *  **********************************************************************************************
 */

////////     Méthode utilisée pour appliquer les actions des joueurs coté "modèle Joueur"
//action button_click (point loc, list selected_agents)
//	{
//		list<buttons> selected_UnAm <- (selected_agents of_species buttons) where(each.display_name=active_display );
//		ask (first(selected_UnAm))
//		{
//			current_action <- command;
//		}
//	}
////////    On part donc du principe que le modèle joueur va envoyer au modèle Central 4 éléments : a_joueur_id selected_UnAm, current_action et command
reflex simJoueurs //////désactiver lorsque c'est le moment de la submersion // au moment de l'innondation -> lisfloodReadingStep !=  9999999
	{
		do changeUA (1 , one_of(UA) , 1 );//1->N
		do changeUA (1 , UA first_with (each.ua_code = 2) , 1 );//1->N
		do changeUA (2 , one_of(UA), 2 );//2->U
		do changeUA (3 , one_of(UA), 4 );//4->AU
		do changeUA (4 , one_of(UA), 4 );//4->AU
		do changeUA (1 , one_of(UA), 4 );//4->AU
		do changeUA (2 , one_of(UA), 5 );//5->A
		do changeUA (2 , one_of(UA), 5 );//5->A
		
		do repairOuvrage(1,ouvrage first_with(each.etat = "mauvais"));
		do increaseHeightOuvrage(4,ouvrage first_with(each.height > 1));
		do destroyOuvrage(3,ouvrage first_with(each.etat = "tres mauvais"));
		write ""+length(commune) + " " + length(ouvrage);
	}

action changeUA (int a_commune_id, UA a_cell_UA, int a_ua_code)
	{ask a_cell_UA {do modify_UA (a_commune_id, a_ua_code);}
	}

action repairOuvrage (int a_commune_id, ouvrage a_ouvrage) {
	ask a_ouvrage {do repair_by_commune (a_commune_id) ;}
	}
	
action increaseHeightOuvrage (int a_commune_id, ouvrage a_ouvrage) {
	ask a_ouvrage {do increase_height_by_commune (a_commune_id) ;}
	}

action destroyOuvrage (int a_commune_id, ouvrage a_ouvrage) {
	ask a_ouvrage {do destroy_by_commune (a_commune_id) ;}
	}
	
/*
 * ***********************************************************************************************
 *                                       LE BOUTON STEP 
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
			location <- { world.shape.width - 1000#m, 1000#m };
			my_icon <- image_file("../images/icones/one_step.png");
			display_name <- UNAM_DISPLAY_c;
		}
		create buttons number: 1
		{
			command <- subvention_b;
			nb_button <- 1;
			label <- "subvention";
			shape <- square(button_size);
			location <- { world.shape.width - 1000#m, 1000#m + 2200#m };
			my_icon <- image_file("../images/icones/subvention.png");
			display_name <- UNAM_DISPLAY_c;
			
		}
		create buttons number: 1
		{
			command <- taxe_b;
			nb_button <- 2;
			label <- "taxe";
			shape <- square(button_size);
			location <- { world.shape.width - 1000#m, 1000#m + 4200#m };
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
				write "step";
			}
			
			if (nb_button = 1){
				write "Subvention";
			}
			
			if (nb_button = 2){
				write "taxe";
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
	
    
    //destruction de la selrction
    action clear_selected_button
	{
		previous_clicked_point <- nil;
		ask buttons
		{
			self.is_selected <- false;
		}
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
{	string type;
	string etat;	// "tres bon" "bon" "moyen" "mauvais" "tres mauvais" 
	float height;  // height au pied en mètre
	int length <- 0; // longueur de l'ouvrage en mètre 
	list<cell> cells ;
	int cptEtat <-0;
	int nb_stepsForDegradEtat <-4;
	int rupture<-0;
	
	init {
		if etat = 'inconnu' {etat <- "bon";}
		if height = 0.0 {height  <- 1.0;}
		else {height <- height / 100;} // CONVERSION: la table du shp est en centimètre, alors que dans lisflood ainsi que dans le modèle gama on est en mètre.
		if length = 0 {length <- (max([1,(length(cells) - 1)]) * 20);} // ESTIMATION Longueur : 20 mètre fois le nb de cells traversés moins une.
		///  vérifier que length renvoie bien le nb de cells
	}
	
	reflex evolEtat { ////  ne pas déclencher lorsqu'on est en innondation
		cptEtat <- cptEtat +1;
		if cptEtat = (nb_stepsForDegradEtat+1) {
			cptEtat <-0;

			if etat = "mauvais" {etat <- "tres mauvais";}
			if etat = "moyen" {etat <- "mauvais";}
			if etat = "bon" {etat <- "moyen";}
			if etat = "tres bon" {etat <- "bon";}
		}
	}
	
	action calcRupture {
		float p <- 0.0;
		if etat = "tres mauvais" {p <- 0.5;}
		if etat = "mauvais" {p <- 0.3;}
		if etat = "moyen" {p <- 0.2;}
		if etat = "bon" {p <- 0.1;}
		if etat = "tres bon" {p <- 0.0;}
		if rnd (1) / 1 < p {
				set rupture <- 1;
				// apply Rupture On Cells
				ask cells  {/// todo : a changer: ne pas appliquer sur toutes les cells de l'ouvrage mais que sur une portion
							if soil_height >= 0 {soil_height <-   max([0,soil_height - myself.height]);}
				}
		}
	}
	
	action removeRupture {
		set rupture <- 0;
		ask cells  {if soil_height >= 0 {soil_height <-   soil_height_before_broken;}}
	}

	action repair_by_commune (int a_commune_id) {
		set etat <- "tres bon";
		set cptEtat <- 0;
		ask commune first_with(each.id = a_commune_id) {do payerReparationOuvrage_longueur (myself.length);}
	}

	action increase_height_by_commune (int a_commune_id) {
		set etat <- "tres bon";
		set cptEtat <- 0;
		height <- height + 0.5; // le réhaussement d'ouvrage est forcément de 50 centimètres
		ask cells {	soil_height <- soil_height + 0.5;
					soil_height_before_broken <- soil_height ;
		}
		ask commune first_with(each.id = a_commune_id) {do payerRehaussementOuvrage_longueur (myself.length);}
	}
	
	action destroy_by_commune (int a_commune_id) {
		ask cells {	soil_height <- soil_height - myself.height ;}
		ask commune first_with(each.id = a_commune_id) {do payerDestructionOuvrage_longueur (myself.length);}
		do die;
	}
	
	aspect base
	{	rgb color <- # pink;
		if etat = "tres bon" {color <- rgb (0,175,0);} 
		if etat = "bon" {color <- rgb (0,216,100);} 
		if etat = "moyen " {color <-  rgb (206,213,0);} 
		if etat = "mauvais" {color <- rgb(255,51,102);} 
		if etat = "tres mauvais" {color <- # red;}
		if etat = "casse" {color <- # red;} 
		draw shape color: color ;
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
	int ua_code;
	rgb my_color <- cell_color() update: cell_color();
	int nb_stepsForAU_toU <-3;
	int AU_to_U_counter <- 0;
	list<cell> cells ;
	int population ;
	int cout_expro ;
	
	init {cout_expro <- (round (cout_expro /2000))*1000;} // on divise par 2 la valeur du cout expro car elle semble surévaluée 
	
	
	action modify_UA (int a_id_commune, int a_ua_code)
	{
		if  ua_name = "U" and nameOfUAcode(a_ua_code) = "N" /*expropriation */
				{ask commune first_with (each.id = a_id_commune) {do payerExpropriationPour (myself);}}
		ua_code <- a_ua_code;
		ua_name <- nameOfUAcode(a_ua_code);
		//on affecte la rugosité correspondant aux cells
		float rug <- rugosityValueOfUA (a_ua_code);
		ask cells {rugosity <- rug;} 	
	}
	
	
	reflex evolveUA
		{if ua_name ="AU"
			{AU_to_U_counter<-AU_to_U_counter+1;
			if AU_to_U_counter = (nb_stepsForAU_toU +1)
				{AU_to_U_counter<-0;
				ua_name <- "U";
				ua_code<-codeOfUAname("U");}
			}	
		if (ua_name = "U" and population < 1000){
			population <- population + 10;}
		}
		
//	reflex bidon
//	{if rnd (1) / 1 < 0.1 {write "c"+ cout_expro;
//		write "p" + population;
//	}}
		
		
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
{	int id<-0;
	int budget <-10000;
	list<UA> UAs ;
	int impot_unit <- 1000;
	aspect base
	{
		draw shape color:#whitesmoke;
	}
	
	reflex recevoirImpots {
		int nb_impose <- sum(UAs accumulate (each.population));
		int impotRecus <- nb_impose * impot_unit;
		budget <- budget + impotRecus;
		}
		
	action payerExpropriationPour (UA a_UA)
			{
				budget <- budget - a_UA.cout_expro;
			}
			
	action payerReparationOuvrage_longueur (int length)
			{
				budget <- budget - (length * 100); // mettre les bonnes valeurs
			}
			
	action payerRehaussementOuvrage_longueur (int length)
			{
				budget <- budget - (length * 500); // mettre les bonnes valeurs
			}

	action payerDestructionOuvrage_longueur (int length)
			{
				budget <- budget - (length * 600); // mettre les bonnes valeurs
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

species action_done
{
	int id;
	//string command_group <- "";
	int command <- -1;
	string label <- "no name";
	float cost <- 0.0;
	action apply;
	
	
}

/*
 * ***********************************************************************************************
 *                        EXPERIMENT DEFINITION
 *  **********************************************************************************************
 */

experiment oleronV1 type: gui {
	output {
		
		display carte_oleron //autosave : true
		{
			grid cell ;
			species cell aspect:elevation_eau;
			//species commune aspect:base;
			species road aspect:base;
			species ouvrage aspect:base;
		}
		display Amenagement
		{
			species commune aspect: base;
			species UA aspect: base;
			species road aspect:base;
			species ouvrage aspect:base;
			
		}		display Population
		{
			// Les boutons et le clique
			species buttons aspect:base;
			event [mouse_down] action: button_click_C;
			//event [mouse_down] action: subvention_action;
			//event [mouse_down] action: taxe_action;
			species commune aspect: base;
			species UA aspect: population;
			species road aspect:base;
			
			
		}
		display graph_budget {
				chart "Series" type: series {
					data "budget" value: (commune collect each.budget)  color: #red;				
				}
			}
			}}
		

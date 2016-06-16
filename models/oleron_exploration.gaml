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

	string timestamp <- ""; // variable utilisée pour spécifier un nom unique au répertoire de sauvegarde des résultats de simulation de lisflood
	string directory <- "sim1";
	string 	STATUS_TRES_MAUVAIS<- "tres mauvais";
	string 	STATUS_MAUVAIS<- "mauvais";
	string 	STATUS_MOYEN<-  "moyen";
	string 	STATUS_BON<- "bon";
	string	STATUS_TRES_BON<-"tres bon";
	
	string TYPE_OUVRAGE_DIGUE <- "Ouvrage transversal";
	string TYPE_OUVRAGE_NATUREL <- "Naturel";
	float ALT_INC_PAR_ANNEE <- 10#cm;
	
	
	
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
		geometry shape <- envelope(emprise_shape);
		int round <- 0;
		
		float MAX_HEIGHT <- 3.60#m;
		float MAX_HEIGHT_GANNIVELE <- 0.7#m;

init
	{
		/*Creation des agents a partir des données SIG */
		create ouvrage from:defenses_cote_shape  with:[id_ouvrage::int(read("OBJECTID")),type::string(read("Type_de_de")), status::string(read("Etat_ouvr")), alt::float(get("alt")), height::float(get("hauteur")) ]
		{
			ori_type <- type;
			ori_status <- status;
			ori_alt <- alt;
		}
		
		create commune from:communes_shape with: [nom_raccourci::string(read("NOM_RAC")),id::int(read("id_jeu"))]
		{
			write " commune " + nom_raccourci + " "+id;
		}
		do load_rugosity;
		ask ouvrage {cells <- cell overlapping self;}
		do initialize;
	}
	
	action initialize
	{
		ask ouvrage
		{
			type <- ori_type;
			status <- ori_status ;
			alt <- ori_alt ;
			gannivelle <- false;
		}
	}
	
	reflex exp when: cycle = 1
	{
		do explore;
	}
	action explore
	{
		
		int i <- 0;
		loop while:i<=10
		{
			int j <- 0;
			loop while:j<=10
			{
				int k <- 0;
				loop while:k<=10
				{
					do initialize;
					do explore_dyke(i/10,j/10,k/10);
					do executeLisflood(i,j,k);
					write "i="+ i+" j="+j+" k="+k;
					k <- k + 1;
				}
				j <- j + 1;
			}
			i <- i + 1;
		}
		
		
		
	}
	
	action explore_dyke(float solid_dyke_rate,float gannivelle, float no_do)
	{
		if(solid_dyke_rate >= 0.5)
		{
			do transforme_dune((solid_dyke_rate-0.5)*2);
		}
		
		if(gannivelle >=0.5)
		{
			do installer_gannivelle(1.0);
			do transforme_digue(gannivelle);
		}
		else
		{
			do installer_gannivelle(gannivelle*2);
		}
		
		int i <- 0;
		float entretien <- solid_dyke_rate > 0.5? 1:solid_dyke_rate*2; 
		loop while:i < 15
		{
			do jouer_annee(entretien);
			i <- i+1;
		}
		//do executeLisflood(int(solid_dyke_rate*10),int(gannivelle*10),int(no_do*10));
			
	}

	action jouer_annee(float entretien_digue)
	{
		do entretenir_digue(entretien_digue);
		do sensabler;
	}
	
	action transforme_digue(float mrate)
	{
		list<ouvrage> digues <- shuffle(ouvrage where(each.type = TYPE_OUVRAGE_DIGUE));
		int nb_ouvrage <- round(length(digues) * mrate);
		int i <- 0;
		
		loop while:i<nb_ouvrage
		{
			ouvrage tmp <- digues[i];
			tmp.type <- TYPE_OUVRAGE_NATUREL;
			tmp.gannivelle <-true;
			tmp.alt <- MAX_HEIGHT_GANNIVELE;
			tmp.status <- STATUS_TRES_BON;
			i <- i + 1;
		}
		
	}
	
	action installer_gannivelle(float mrate)
	{
		list<ouvrage> dunes <- shuffle(ouvrage where(each.type = TYPE_OUVRAGE_NATUREL));
		int nb_ouvrage <- round(length(dunes) * mrate);
				int i <- 0;
		loop while:i<nb_ouvrage
		{
			ouvrage tmp <- dunes[i];
			tmp.gannivelle <- true;
			i <- i + 1;
		}
	}
	
	action transforme_dune(float mrate)
	{
		list<ouvrage> dunes <- shuffle(ouvrage where(each.type = TYPE_OUVRAGE_NATUREL));
		int nb_ouvrage <- round(length(dunes) * mrate);
		
		int i <- 0;
		loop while:i<nb_ouvrage
		{
			ouvrage tmp <- dunes[i];
			tmp.type <- TYPE_OUVRAGE_DIGUE;
			tmp.alt <- MAX_HEIGHT;
			tmp.status <- STATUS_TRES_BON;
			i <- i + 1;
		}
	}
	
	action grandir_digue(float mrate)
	{
		list<ouvrage> tout_ouvrage <- shuffle(ouvrage where(each.ori_type = TYPE_OUVRAGE_DIGUE));
		int nb_ouvrage_grandir <- round(length(tout_ouvrage) * mrate);
		int i <- 0;
		loop while: i<nb_ouvrage_grandir
		{
			ouvrage tmp <- tout_ouvrage[i];
			tmp.alt <- MAX_HEIGHT;
			tmp.status <- STATUS_TRES_BON;
			i <- i  + 1;	
		}
	}

	action entretenir_digue(float mrate)
	{
		list<ouvrage> tout_ouvrage <- shuffle(ouvrage where(each.ori_type = TYPE_OUVRAGE_DIGUE and each.status= STATUS_TRES_MAUVAIS ));
		tout_ouvrage <- tout_ouvrage accumulate shuffle(ouvrage where(each.ori_type = TYPE_OUVRAGE_DIGUE and each.status= STATUS_MAUVAIS ));
		tout_ouvrage <- tout_ouvrage accumulate shuffle(ouvrage where(each.ori_type = TYPE_OUVRAGE_DIGUE and each.status= STATUS_MOYEN ));
		tout_ouvrage <- tout_ouvrage accumulate shuffle(ouvrage where(each.ori_type = TYPE_OUVRAGE_DIGUE and each.status= STATUS_BON ));
		
		int nb_ouvrage_entretien<- round(length(tout_ouvrage) * mrate);
		int i <- 0;
		loop while: i<nb_ouvrage_entretien
		{
			ouvrage tmp <- tout_ouvrage[i];
			tmp.status <-STATUS_TRES_BON;
			i <- i  + 1;	
		}
	}
	
	action sensabler
	{
		ask(ouvrage where(each.gannivelle))
		{
			alt <- alt + ALT_INC_PAR_ANNEE;
		}
	}


	action executeLisflood(int x,int y,int z)
	{	
		do save_dem(x,y,z);  
		do save_rugosityGrid(x,y,z);
	//	do save_lf_launch_files;
 	}
 		
/*	action save_lf_launch_files {
		save ("DEMfile         oleron_dem_t"+timestamp+".asc\nresroot         res\ndirroot         results\nsim_time        43400.0\ninitial_tstep   10.0\nmassint         100.0\nsaveint         3600.0\n#checkpoint     0.00001\n#overpass       100000.0\n#fpfric         0.06\n#infiltration   0.000001\n#overpassfile   buscot.opts\nmanningfile     oleron_n_t"+timestamp+".asc\n#roadfile      buscot.road\nbcifile         oleron.bci\nbdyfile         oleron.bdy\n#weirfile       buscot.weir\nstartfile      oleron.start\nstartelev\n#stagefile      buscot.stage\nelevoff\n#depthoff\n#adaptoff\n#qoutput\n#chainageoff\nSGC_enable\n") rewrite: true  to: "../includes/lisflood-fp-604/oleron_"+x+"_"+y+"_"+z+"_" +timestamp+".par" type: "text"  ;
		save ("lisflood -dir results"+ timestamp +" oleron_"+timestamp+".par") rewrite: true  to: "../includes/lisflood-fp-604/lisflood_oleron_current.bat" type: "text"  ;  
		}       
 */
 
	action save_dem(int x,int y,int z) {
		string filename <- "resultats/"+directory+"/oleron_dem_t_"+x+"_"+y+"_"+z+"_" + timestamp + ".asc";
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
		
	action save_rugosityGrid(int x,int y,int z) {
		string filename <- "resultats/"+directory+"/oleron_n_t_" +x+"_"+y+"_"+z+"_" + timestamp + ".asc";
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
		
	
	action load_rugosity
     { file rug_data <- text_file("../includes/lisflood-fp-604/oleron.n.ascii") ;
			loop r from: 6 to: length(rug_data) -1 {
				string l <- rug_data[r];
				list<string> res <- l split_with " ";
				loop c from: 0 to: length(res) - 1{
					cell[c,r-6].rugosity <- float(res[c]);}}	
	}


}
/*
 * ***********************************************************************************************
 *                        ZONE de description des species
 *  **********************************************************************************************
 */

grid cell file: dem_file schedules:[] neighbours: 8 {	
		int cell_type <- 0 ; // 0 -> terre
		ouvrage my_dyke <- nil;
		float water_height  <- 0.0;
		float max_water_height  <- 0.0;
		float cell_height <- grid_value;
		float soil_height -> {my_dyke=nil?cell_height:my_dyke.alt};
		float rugosity;
	}

species ouvrage
{	
	int id_ouvrage;
	string ori_type;
	string ori_status;	// "tres bon" "bon" "moyen" "mauvais" "tres mauvais" 
	float ori_alt;
	
	string type;
	string status;	// "tres bon" "bon" "moyen" "mauvais" "tres mauvais" 
	float height;  // height au pied en mètre
	bool gannivelle <- false;
	float alt;
	rgb color <- # pink;
	list<cell> cells ;
	int cptStatus <-0;
	int nb_stepsForDegradStatus <-4;

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
		}
	}
	
	


	aspect base
	{	
		draw 30#m around shape color: color /*size:1500#m*/;
	}
}


species commune
{	
	int id<-0;
	bool not_updated<- true;
	string nom_raccourci;
	string network_name;
	int budget <-10000;

	aspect base
	{
		draw shape color:#whitesmoke;
	}
		
}


/*
 * ***********************************************************************************************
 *                        EXPERIMENT DEFINITION
 *  **********************************************************************************************
 */

experiment oleronExploration type: gui {
	output {
		display Amenagement
		{
			grid cell ;
			species commune aspect: base;
			species ouvrage aspect:base;		
		}	
		
	}	
}
		

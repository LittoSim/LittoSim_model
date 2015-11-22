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
	int cycle_launchLisflood <- 5; // cycle_launchLisflood specifies the cycle at which lisflood is launched
	/* lisfloodReadingStep is used to indicate to which step of lisflood results, the current cycle corresponds */
	int lisfloodReadingStep <- 9999999; //  lisfloodReadingStep = 9999999 it means that their is no lisflood result corresponding to the current cycle 
	string timestamp <- ""; // variable utilisée pour spécifier un nom unique au répertoire de sauvegarde des résultats de simulation de lisflood
	
	/*
	 * Chargements des données SIG
	 */
		file communes_shape <- file("../includes/zone_etude/communes.shp");
		file defenses_cote <- file("../includes/zone_etude/defense_cote_littoSIM.shp");
		// OPTION 1 Fichiers SIG Grande Carte
		file emprise <- file("../includes/zone_etude/emprise_ZE_littoSIM.shp"); 
		file dem_file <- file("../includes/zone_etude/mnt_recalcule_alti_v2.asc") ;
	//	file dem_file <- file("../includes/lisflood-fp-604/oleron_dem_t0.asc") ;	bizarrement le chargement de ce fichier là est beaucoup plus long que le chargement de celui du dessus
		int nb_cols <- 631;
		int nb_rows <- 906;

/*
ncols         631
nrows         906
xllcorner     364927,14666668
yllcorner     6531972,5655556
cellsize      20
NODATA_value  -9999
*/
		// OPTION 2 Fichiers SIG Petite Carte
		/*file emprise <- file("../includes/zone_restreinte/cadre.shp");
		file coastline_shape <- file("../includes/zone_restreinte/contour.shp");
		file dem_file <- file("../includes/zone_restreinte/mnt.asc") ;
		int nb_cols <- 250;
		int nb_rows <- 175;	*/
/*
 * ncols        250
nrows        175
xllcorner    368987.146666680000
yllcorner    6545012.565555600400
cellsize     20.000000000000
NODATA_value  -9999 */

		


	/* Definition de l'enveloppe SIG de travail */
		geometry shape <- envelope(emprise);
	


	init
	{
		/*Les actions contenu dans le bloque init sonr exécuté à l'initialisation du modele*/
		
		/*Creation des agents a partir des données SIG */
		create defense_cote from:defenses_cote;
		create commune from:communes_shape; 
	
	}
 	
 
/* pour la sauvegarde des données en format shape */
reflex sauvegarder_resultat when: sauver_shp and cycle = cycle_sauver
	{										 
		save cell type:"shp" to: resultats with: [soil_height::"SOIL_HEIGHT", water_height::"WATER_HEIGHT"];
	}
	
reflex runLisflood
	{ 
	  if cycle = cycle_launchLisflood {do launchLisflood;} // comment this line if you only want to read already existing results
	  if cycle = cycle_launchLisflood {lisfloodReadingStep <- 0;}
	  if lisfloodReadingStep !=  9999999
	   {do readLisfloodInRep("results_"+timestamp);}}
	   
	   	
action launchLisflood
	{	timestamp <- machine_time ;
		do save_dem;  
		do save_lf_launch_files;
		map values <- user_input(["Input files for flood simulation "+timestamp+" are ready.

BEFORE TO CLICK OK
-Launch '../includes/lisflood-fp-604/lisflood_oleron_current.bat' to generate outputs

WAIT UNTIL Lisflood finishes calculations to click OK (Dos command will close when finish) " :: 100]);
 		}
action save_lf_launch_files {
		save ("DEMfile         oleron_dem_t"+timestamp+".asc\nresroot         res\ndirroot         results\nsim_time        43400.0\ninitial_tstep   10.0\nmassint         100.0\nsaveint         3600.0\n#checkpoint     0.00001\n#overpass       100000.0\n#fpfric         0.06\n#infiltration   0.000001\n#overpassfile   buscot.opts\nmanningfile     oleron.n.ascii\n#riverfile      buscot.river\nbcifile         oleron.bci\nbdyfile         oleron.bdy\n#weirfile       buscot.weir\nstartfile      oleron.start\nstartelev\n#stagefile      buscot.stage\nelevoff\n#depthoff\n#adaptoff\n#qoutput\n#chainageoff\nSGC_enable\n") rewrite: true  to: "../includes/lisflood-fp-604/oleron_"+timestamp+".par" type: "text"  ;
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
		float temp_received;
	
		init {
			if soil_height <= 0 {cell_type <-1;}  //  1 -> mer
			if soil_height = 0 {soil_height <- -5.0;}
			//color<- int(grid_value*10) = 0 ? rgb('black'): rgb('white');	
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



species land_cover
{
	aspect base
	{
		draw shape /*color:#yellow*/;
	}
}

species defense_cote
{
	aspect base
	{
		draw shape /*color:#yellow*/;
	}
}

species commune
{
	
	aspect base
	{
		draw shape color:#red;
	}
}



experiment oleronV1 type: gui {
	output {
		
		display carte_oleron //autosave : true
		{
			grid cell ;
			species cell aspect:elevation_eau;
			//species commune aspect:base;
			species defense_cote aspect:base;
		}}}
		

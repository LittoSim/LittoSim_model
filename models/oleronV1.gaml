/**
 *  oleronV1
 *  Author: Brice, Etienne, Nico B et Nico M pour l'instant
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

global {
	/*
	 * Chargements des données SIG
	 */
	//file emprise <- file("../includes/rectangleempriset.shp");
		file emprise <- file("../includes/cadre.shp");
		file communes_shape <- file("../includes/communes.shp");
		file sea_area <- file("../includes/la_mer_cadree.shp");
		file coastline_shape <- file("../includes/contour.shp");
		file measure_station <- file("../includes/water_height_station.shp");
		file ouvrage_defenses2014lienss <- file("../includes/ouvragedefenses2014lienss.shp");
		file mnt_file <- file("../includes/MNT20m_cadre.asc") ;
	/*Chargement des données de hauteur d'eau dans un variable de type matrice */
		matrix<float> hauteur_eau <- matrix<float>(csv_file("../includes/Hauteur_Eau.csv",";"));
	/* Definition de l'enveloppe SIG de travail */
		geometry shape <- envelope(emprise);
	
		float water_height_mesure_step <- 10#mn;
		int mesure_id <- compute_measure_id() update:compute_measure_id();	
		
		/* NB-> varaiable test */
		int tmp1Int <-0; 
		int tmp2Int <-0; 
	init
	{
		/*Les actions contenu dans le bloque init sonr exécuter 
		 * à l'initialisation du modele
		 */
		 
		/*Definiton de la durée d'une itération simulé*/
		step <- 10#mn;
		/*Initialisation de l'eau de départ */
		time <- 11#h;
		mesure_id <- compute_measure_id();
		write "index " + mesure_id;
		
		/*Creation des agents a partir des données SIG */
		create ouvrage_defenses from:ouvrage_defenses2014lienss;
		create commune from:communes_shape; 
		create water_height_measure from:measure_station with:[point_id::int(read("id"))];
		
		
		// On appel la fonction load_costline
		do load_coastline;
		
		/*On travail à partir du trait de côte. L'espace est représenté par une grille, 
		 * On demande à toutes les cellules qui ne sont pas de type = 2 et qui se 
		 * superpose avec le polygone mer de de colorer en bleu et de prendre le type 1 
		 */
		ask cell where (each.cell_type !=2) overlapping sea_area   
		{
			write "coucou " + self;
			cell_type <- 1;
			color <- #blue;
		}
		
		//On appel la fonction load_hauteur_eau
		do load_hauteur_eau;
	}
 	
 	/*La fonction load_costline va identifier les cellules de la grilles qui sont 
 	 * sous l'isoline 0 pour definir la zone d'ou vont partir les vagues 
 	 * Ces celulles sont definit comme étant de type 2. 
 	 * On charge ensuite les données de hauteurs d'eau dans les celllules pour
 	 * pouvoir être près à propager la vague. 
 	 */
 	action load_coastline
 	{
 		//variables tmp pour la ligne de cote
 		geometry tmp <- first(coastline_shape);
 		
 		//definition des attributes des celulles sous la ligne
 		ask (cell overlapping tmp)
 		{
 			cell_type <- 2;
 			create coastline_cell number:1
 			{
 				my_cell <- myself;
 				shape <- myself.shape;
 				location <- myself.location;
 				
 			}
 		}
 		
 		ask coastline_cell
 		{
 			
 			list<water_height_measure> tmpList<- water_height_measure;
 			list<float> distance_tmpList <- []; 
 			water_height_measure found1<- nil;
 			water_height_measure found2<- nil;
 		//	int i <- 0;
 			tmpList <- tmpList sort_by(each.location distance_to self);
			found1 <- tmpList at 0;
			found2 <- tmpList at 1;
			float dfound1 <- found1 distance_to self;
			float dfound2 <- found2 distance_to self;
			
			pair<water_height_measure,float> p1 <- found1::dfound1/(dfound1 + dfound2 ); // point de mesure associé à sa pondération
			pair<water_height_measure,float> p2 <- found2::dfound2/(dfound1 + dfound2 );
			
			mesure_station_rate <- [p1,p2];
			//put (found1 distance_to self) at:(tmpList at 0) to:distance_matrix
			

 		}
 	}
 	
 	/*
 	 * le blocke load_hauteru_eau va peupler la matrice ligne par ligne 
 	 * à partir des données du csv charger en init{}
 	 */
	action load_hauteur_eau
	{
		list<list<float>> col_read <- rows_list(hauteur_eau);
		
		int nb_lines <- length(col_read);
		int it <- 0;
		list<float> current_line  <- nil;
		create measure number:nb_lines returns:mesureList;

		loop while:it<nb_lines
		{
			current_line <- col_read at it;
			int day <-int( current_line at 0);
			int hour <-int( current_line at 1);
			int minute <-int( current_line at 2);
			int id <-int( current_line at 3);
			float water_height <-current_line at 4;
			measure current_measure <- mesureList at it;
			ask current_measure
			{
				date <- (day - 1) * °day + hour * °h + minute * °mn;
				height <- water_height;
			}
			
			ask water_height_measure where(each.point_id = id)
			{
				measures <- measures + current_measure;
			} 
			it <- it + 1;
		}
		ask water_height_measure
		{
			measures <- measures sort_by (each.date);
			current_height <-( measures at mesure_id).height;
			write "pan " + point_id + " "+time + " "+ current_height;
		}
		
		//list<measure> tmp_mesure <- first(water_height_measure).measures;
	}
	
	int compute_measure_id
	{
		
		return time div ( water_height_mesure_step );
	}
	
//	action load_test_data
//	{
//		emprise <- file("../includes/cadre.shp");
//		communes_shape <- file("../includes/communes.shp");
//		ouvrage_defenses2014lienss <- file("../includes/ouvragedefenses2014lienss.shp");
//		mnt_file <- file("../includes/MNT20m_cadre.asc") ;
//		shape <- envelope(emprise);
//	}
//	
//	action load_large_scale_data
//	{
//		emprise <- file("../includes/rectangleempriset.shp");
//		communes_shape <- file("../includes/communes.shp");
//		ouvrage_defenses2014lienss <- file("../includes/ouvragedefenses2014lienss.shp");
//		mnt_file <- file("../includes/DEM_20.asc") ;
//		shape <- envelope(emprise);
//		
//	}
	
	/*
	 * Le blocke refelex qui va permettre la diffusion de la vague. La diffusion se fait
	 * pour chaque cellules sur une dynamique de moore. La celulles centrale va évaluer 
	 * les hauteurs d'eau qu'elle peut deverser dans ses voisine, puis partager sa propre
	 * charge en eau dans celles-ci.
	 */
	reflex diffuse_water
	{
		ask cell
		{//NB-> on remet à 0 temp_received
			temp_received <- 0.0;}
		list<cell> cell_to_diffuse <- cell where((each.cell_type = 2 or each.cell_type = 0) and each.water_height > 0); 
		ask cell_to_diffuse
		{
			//On fait une liste des celulles voisine de 1 et qui ne sont pas ni le large, ni la ligne de cote.	
			list<cell> neighbours_cells <- self neighbours_at 1 where (each.cell_type = 2 or each.cell_type=0);

			//On récupère la hauteur du MNT + de l'eau s'il y en a
			list<float> neighbours_height <- neighbours_cells collect (each.water_height+ each.soil_height );
			//MAJ de la hauteur total : hauteur du MNT et hauteur d'eau
			float my_height <- water_height + soil_height;
			
			//on regarde le min dans mon environnement de moore
			float neighbours_minimum <- min(neighbours_height);
			
			//La hauteur qui sera diffusé représentera le delta entre ma hauteur (sol+eau) et la hauteur (sol+eau)
			//de ma plus petite voisine.
			float height_to_diffuse <- my_height - neighbours_minimum;
			/* NB-> cptage cells */
			if( height_to_diffuse <= 0)
			{tmp1Int<- tmp1Int + 1;} 
			//s'il y a quelque chose à diffuser
			if( height_to_diffuse > 0)
			{tmp2Int<- tmp2Int + 1;
			/*NB-> */color <- #green;
				//fait la liste des cellules dont la hauteur est inf a moi même
				list<cell> neighbours_below <- neighbours_cells where(each.water_height+ each.soil_height < my_height);
				//calcule la différence de hauteur pour chaque cellules 
				list<float> neighbours_below_diff <- neighbours_below collect( my_height - (each.water_height+ each.soil_height));
				//sommes des différences
				/*NB-> suivi calcul*/ // write "neighbours_below_diff : " + neighbours_below_diff;
				float sum_diff <- sum(neighbours_below_diff);
				/*NB-> suivi calcul*/ //write "sum_diff : " + sum_diff;
				
				//initialisation vide
				cell current_cell <- nil;
				int i <- 0; 
				//On recupère la plus base des cellules
				float min_diffuse <- min([height_to_diffuse,water_height]);
				/*NB-> suivi calcul*/
			//	write "min_diffuse : " + min_diffuse;
				//On boucle sur la liste des cellules autours de la cellule actuelle
				loop current_cell over:neighbours_below
				{
					//On recupère la différence de hauteur minimal sur la celluls voisine i qu'on divise par la somme des différence   
					// NB-> Débogage Nico
					float height_diffused <- (min_diffuse * (neighbours_below_diff at i) / sum_diff);
					/*NB-> suivi calcul*/  // write "height_diffused-" + i + " : " + height_diffused;
					current_cell.temp_received <- current_cell.temp_received + height_diffused;
					//on ajouter au la variable temp_received la contribution de la cellule i
					temp_received <- temp_received - height_diffused;
					//on incremente à la cellules d'après
					i <- i + 1;
				}
			}
		}
		ask cell // NB>on remet à jour sur toutes les cells. on puorrra optimiser plus tard
		{
			//en envoie la vague préparer dans le block précédent
			water_height <- water_height + temp_received;
			//on remet à 0 temp_received
			/*NB-> placé en haut de la méthode pour pouvoir suivre les étapes de calcul
			temp_received <- 0.0;*/
		}
		/* print le nb de cellule qui ne diffuse car il n'y a pas de voisins plus bas */
		write "nb cells qui diffusent pas : " + tmp1Int;
		tmp1Int <- 0;
		write "nb cells qui diffusent  : " + tmp2Int;
		tmp2Int <- 0;
	}
	reflex update_cell_color {
      ask cell {
         do update_color;
      }
   }
}

/*
 * ***********************************************************************************************
 *                        ZONE de description des species
 *  **********************************************************************************************
 */

grid cell file: mnt_file schedules:[] neighbours: 8 {	 /* NB-> voisinage 8  */

		int cell_type <- 0 ; // 0 -> terre, 1 -> mer, 2 -> front de mer
		float water_height <- 0;
		float soil_height <- grid_value;
		
		float temp_received;
	
		init {
			//color<- int(grid_value*10) = 0 ? rgb('black'): rgb('white');
		
		}
		
	 action update_color { 
         int val_water <- 0;
         val_water <- max([0, min([255, int(255 * (1 - (water_height / 12.0)))])]) ;  
         color <- rgb([val_water, val_water, 255]);
         grid_value <- water_height + soil_height;
      }
	}

species measure schedules:[]
{
	float date;
	float height;
}

species water_height_measure 
{
	int point_id;
	float current_height;
	list<measure> measures <- [];
	
	reflex change_height
	{
		current_height <- (measures at mesure_id).height;
	}
}

species land_cover
{
	aspect base
	{
		draw shape color:#yellow;
	}
}

species ouvrage_defenses
{
	aspect base
	{
		draw shape color:#yellow;
	}
}

species commune
{
	
	aspect base
	{
		draw shape color:#lightgrey;
	}
}

species coastline_cell
{
	cell my_cell;
	float current_height;
	list<pair<water_height_measure,float>> mesure_station_rate;
	
	reflex remplir
	{
		current_height <- current_water_height();
		my_cell.water_height <- current_height;
	//	write "current Water height" + my_cell neighbours_at 1 where(each.cell_type = 0);
	}
	float current_water_height
	{
		return sum(mesure_station_rate collect(each.key.current_height * each.value));	
	}
	aspect base
	{
		draw shape color:#red;
	}
}

experiment oleronV1 type: gui {
	output {
		
		display carte_oleron
		{
			grid cell ;
			//species commune aspect:base;
			species ouvrage_defenses aspect:base;
			species coastline_cell aspect:base;
			
		}
		
				
	}
}

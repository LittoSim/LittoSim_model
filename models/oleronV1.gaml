/**
 *  oleronV1
 *  Author: Brice, Etienne, Nico B et Nico M pour l'instant
 *  Description: 
 */

model oleronV1

global {
	/** Insert the global definitions, variables and actions here */
	//file emprise <- file("../includes/rectangleempriset.shp");
		file emprise <- file("../includes/cadre.shp");
		file communes_shape <- file("../includes/communes.shp");
		file sea_area <- file("../includes/la_mer_cadree.shp");
		file coastline_shape <- file("../includes/contour.shp");
		file measure_station <- file("../includes/water_height_station.shp");
		file ouvrage_defenses2014lienss <- file("../includes/ouvragedefenses2014lienss.shp");
		file mnt_file <- file("../includes/MNT20m_cadre.asc") ;
		matrix<float> hauteur_eau <- matrix<float>(csv_file("../includes/Hauteur_Eau.csv",";"));
		geometry shape <- envelope(emprise);
	
		float water_height_mesure_step <- 10#mn;
		int mesure_id <- compute_measure_id() update:compute_measure_id();	
	
	init
	{
		step <- 10#mn;
		time <- 11#h;
		mesure_id <- compute_measure_id();
		write "index " + mesure_id;
		//do load_test_data;
		create ouvrage_defenses from:ouvrage_defenses2014lienss;
		create commune from:communes_shape; 
		create water_height_measure from:measure_station with:[point_id::int(read("id"))];
		
		
		do load_coastline;
		ask cell where (each.cell_type !=2) overlapping sea_area   
		{
			write "coucou " + self;
			cell_type <- 1;
			color <- #blue;
		}
		
		
		do load_hauteur_eau;
	}
 	
 	action load_coastline
 	{
 		geometry tmp <- first(coastline_shape);
 		
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
	
	action load_test_data
	{
		emprise <- file("../includes/cadre.shp");
		communes_shape <- file("../includes/communes.shp");
		ouvrage_defenses2014lienss <- file("../includes/ouvragedefenses2014lienss.shp");
		mnt_file <- file("../includes/MNT20m_cadre.asc") ;
		shape <- envelope(emprise);
	}
	
	action load_large_scale_data
	{
		emprise <- file("../includes/rectangleempriset.shp");
		communes_shape <- file("../includes/communes.shp");
		ouvrage_defenses2014lienss <- file("../includes/ouvragedefenses2014lienss.shp");
		mnt_file <- file("../includes/DEM_20.asc") ;
		shape <- envelope(emprise);
		
	}
	
	
	reflex diffuse_water
	{
		list<cell> cell_to_diffuse <- cell where(each.cell_type = 2 or each.cell_type=0); 
		ask cell_to_diffuse
		{
			list<cell> neighbours_cells <- self neighbours_at 1 where (each.cell_type = 2 or each.cell_type=0);
			list<float> neighbours_height <- neighbours_cells collect (each.water_height+ each.soil_height );
			float my_height <- water_height + soil_height;
			
			float neighbours_minimum <- min(neighbours_height);
			
			float height_to_diffuse <- my_height - neighbours_minimum;
			
			if( height_to_diffuse > 0)
			{
				list<cell> neighbours_below <- neighbours_cells where(each.water_height+ each.soil_height < my_height);
				list<float> neighbours_below_diff <- neighbours_below collect( my_height - (each.water_height+ each.soil_height));
				float sum_diff <- sum(neighbours_below_diff);
				
				cell current_cell <- nil;
				int i <- 0; 
				loop current_cell over:neighbours_below
				{
					float min_diffuse <- min([height_to_diffuse,water_height]);
					current_cell.temp_received <- current_cell.temp_received + (min_diffuse * (neighbours_below_diff at i) / sum_diff);
					temp_received <- temp_received - min_diffuse;
					i <- i + 1;
				}
			}
		}
		ask cell_to_diffuse 
		{
			water_height <- water_height + temp_received;
			temp_received <- 0.0;
		}
		
		
		
		
		
	}

}

grid cell file: mnt_file schedules:[]{
		int cell_type <- 0 ; // 0 -> terre, 1 -> mer, 2 -> front de mer
		float water_height <- 0;
		float soil_height <- grid_value;
		
		float temp_received;
	
		init {
			//color<- int(grid_value*10) = 0 ? rgb('black'): rgb('white');
		
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
		draw shape color:#blue;
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
			species commune aspect:base;
			species ouvrage_defenses aspect:base;
			species coastline_cell aspect:base;
			
		}
		
				
	}
}

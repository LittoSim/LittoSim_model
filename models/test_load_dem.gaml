/***
* Name: testloaddem
* Author: Laatabi
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model testloaddem

import "params_models/params_manager.gaml"


global {
	
	//file dem_file <- file('../includes/config/oleron/dem.asc') ;
	geometry shape <- envelope(square(100));
	init{
		do init_color_map;
		//create ciir number:10;
		
		write ""+get_elevation_color(100.0);
		write rgb(["r"::34, "g"::56, "b"::345]);
		
	}
	

	
	rgb get_elevation_color (float elevation){
		loop i from: 0 to: length(color_map) - 1{
			if elevation > color_map.keys[i] {
				write ""+ color_map.values[i][0] + "  " + color_map.values[i][1] + "  " + color_map.values[i][2];
				//return rgb(color_map.values[i][0], color_map.values[i][1], color_map.values[i][2]);
				return rgb(["r"::34, "g"::56, "b"::345]);
			}
		}
		return rgb(255,255,255);
	}
	
/*	init {
		do load_dem;
		
		write Cell[0,0].value;
		write Cell[10,99].value;
		write length(Cell);
	}

	action load_dem{
		file dem_grid <- text_file('../includes/config/oleron/dem.asc') ;
		loop rw from: 6 to: length (dem_grid) - 1 {
			list<string> res <- dem_grid [rw] split_with "	";
			loop cl from: 0 to: length(res) - 1 {
				Cell[cl, rw-6].value <- float(res[cl]);
			}
		}
	}
	
}

grid Cell /file: dem_file *width: nb_cols height: 906 schedules:[] neighbors: 8 {
	float value <- grid_value;
}*/

species ciir{
	aspect{
		//draw circle(10) color: world.getred(0);
	}
}

}
experiment testloaddem type: gui {
	/** Insert here the definition of the input and output of the model */
	output {
		
		display laylay{
			species ciir;
		}
	}
}

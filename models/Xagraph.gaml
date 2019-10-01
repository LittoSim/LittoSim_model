/***
* Name: Xagraph
* Author: Laatabi
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model Xagraph

global {
	
	string fileName <- "";
	string lisflood_rep <- "includes/" + "caen" + "/floodfiles/results/";
	string dem_rep <- "includes/" + "caen" + "/shapefiles/";
	
	int GRID_NB_ROWS <- 968;
	int GRID_NB_COLS <- 1294;
	
	
	int MY_CELL <- 215150;
	
	
	//list<float> depths <- [];
	list<float> results1 <- [];
	list<float> results2 <- [];
	list<float> results3 <- [];
	list<float> results4 <- [];	
	
	init {
		results1 <- draw_me(215150);
		results2 <- draw_me(303433);
		results3 <- draw_me(315963);
		results4 <- draw_me(366477);
	}
	
	list<float> draw_me(int p) {
		list<float> results <- [];
		int my_cell_row <- (p mod GRID_NB_ROWS) - 1;
		int my_cell_col <- int(p / GRID_NB_ROWS);
		//write "row " + my_cell_row;
		//write "col " + my_cell_col;
		
		float ngf_val <- 0.0;
		fileName <- "../" + dem_rep + "dem.asc";
		if file_exists (fileName){
			file lfdata <- text_file(fileName);
			loop r from: 0 to: GRID_NB_ROWS - 1 {
				if r = my_cell_row {
					list<string> res <- lfdata[r+6] split_with " ";
					loop c from: 0 to: GRID_NB_COLS - 1 {
						 if c = my_cell_col {
						 	ngf_val <- float(res[c]);
						 	break;
						 }
					}
				}
			}
     	}
     	//write "dem_val : " + ngf_val;
     	
     	string nb <- "";
		loop i from: 0 to: 14 {
			nb <- "0000" + i;
			nb <- copy_between (nb, length(nb)-4, length(nb));
			fileName <- "../" + lisflood_rep + "res-" + nb + ".wd";
			if file_exists (fileName){
				file lfdata <- text_file(fileName);
				loop r from: 0 to: GRID_NB_ROWS - 1 {
					if r = my_cell_row {
						list<string> res <- lfdata[r+6] split_with "\t";
						loop c from: 0 to: GRID_NB_COLS - 1 {
							 if c = my_cell_col {
							 	//add float(res[c]) with_precision 2 to: depths;
							 	add (float(res[c]) + ngf_val) with_precision 2 to: results;
							 	break;
							 }
						}
					}
				}
	     	}
		}
		return results;
	}
}

experiment Xagraph type: gui {
	
	parameter "Cell : " var: MY_CELL <- MY_CELL;
	
	output {
		display "graph" {
			chart "Water depths (lisflood) + DEM"{
				data "1" value: results1 color: #red;
				data "2" value: results2 color: #green;
				data "3" value: results3 color: #blue;
				data "4" value: results4 color: #black;
			}
		}
	}
}

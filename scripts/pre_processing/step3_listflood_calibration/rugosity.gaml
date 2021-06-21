/***
* Name: rugosity
* Author: nicolas
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model rugosity

global {
	/** Insert the global definitions, variables and actions here */
	csv_file my_csv_file <- csv_file("clc_color.csv",";");
	shape_file boundaries <- shape_file("../../includes/raw_files/convex_hull.shp");
	shape_file land_cover <- shape_file("../../includes/estuary_coast/shapefiles/land_cover.shp");
	string output_file <- "./output_file/rugosity.ASC";
	

	
	geometry shape <- envelope(boundaries);

	map<int,rgb> color_data<-map([]);

	int stage <- 0;
	init
	{
		write "loading files";
		
		matrix data <- matrix(my_csv_file);
		loop i from: 1 to: data.rows -1{
			//loop on the matrix columns
			loop j from: 0 to: data.columns -1{
				add rgb(data[3,i],data[4,i],data[5,i]) at:int(data[0,i]) to:color_data;
			}	
		}
		
		create clc_plot from:land_cover with:[code::int(read("cover_type"))]
		{
			color <- color_data[code];
		}
		
		stage <- 1;
		
	} 
	
	
	reflex analysing when:stage = 1
	{
		write "analysing data";
		
		ask mnt
		{
			clc_plot tmp <- first(clc_plot overlapping self.location);
			if(tmp!=nil)
			{
				self.code <- tmp.code;
				self.color <- tmp.color;
			}
			else
			{
				write "there is an error";
			}	
		}
		
		stage <- 2;
		
	}
	
	reflex exporting when:stage = 2
	{
		write "exporting new data";
		ask( mnt)
		{
			self.grid_value <- code;
		}
		stage <- 3;
		
	}
	
	reflex saving when:stage = 3
	{
		write "saving the file";
		save mnt to:output_file type:"asc";
		write "file saved";
		stage <- 4;
		
	}
	reflex achieved when: stage = 4
	{
		write "processing achieved";
		do pause;
	}	

	
	
}


species clc_plot
{
	int code;
	rgb color;
	
	aspect default
	{
		draw shape color:color;
	}
}


grid mnt cell_width:20#m cell_height:20#m schedules:[]  parallel:true
{
	rgb color <- #black;
	int code <- -1;
	
}

experiment rugosity type: gui {
	/** Insert here the definition of the input and output of the model */
	parameter "Corine land cover file (shape)" var:land_cover;
	parameter "bounding box (shape file)" var:boundaries;
	parameter "output files" var:output_file;
	
	output {
		display map type: opengl {
			species clc_plot;
		}
		
		display generated_grid type: opengl {
				grid mnt  text: true triangulation: true elevation: true;
			}
		
	}
}

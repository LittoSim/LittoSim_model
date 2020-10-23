/***
* Name: DEMBaty
* Author: nicolas
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model DEMBaty

global {
	
	grid_file grid_top <-grid_file("../includes/raw_files/rge_alti_20m_clip.tif");
	shape_file trait_cote <- shape_file("../includes/raw_files/tdc_clip.shp");
	grid_file grid_bathy <- grid_file("../includes/raw_files/idw_clip.tif");
	shape_file convex_hull0_shape_file <- shape_file("../includes/raw_files/convex_hull.shp");

	
	geometry shape <- envelope(convex_hull0_shape_file);

	int stage <- 0;
	list<mnt> mnt_to_execute<-[];
	init
	{
		
		
		write("largeur  " + length(mnt));
		write("largeur 2  " + length(bathy));
		write("largeur 3  " + length(topo));
		
		create cote from: trait_cote;
		
		ask topo {
			float r;
			float g;
			float b;
			if (grid_value < 20) {
				r <- 76 + (26 * (grid_value - 7) / 13);
				g <- 153 - (51 * (grid_value - 7) / 13);
				b <- 0.0;
			} else {
				r <- 102 + (122 * (grid_value - 20) / 19);
				g <- 51 + (173 * (grid_value - 20) / 19);
				b <- 224 * (grid_value - 20) / 19;
			}

			self.color <- rgb(r, g, b);
		}
		ask bathy {
			float r;
			float g;
			float b;
			if (grid_value < 20) {
				r <- 76 + (26 * (grid_value - 7) / 13);
				g <- 153 - (51 * (grid_value - 7) / 13);
				b <- 0.0;
			} else {
				r <- 102 + (122 * (grid_value - 20) / 19);
				g <- 51 + (173 * (grid_value - 20) / 19);
				b <- 224 * (grid_value - 20) / 19;
			}

			self.color <- rgb(r, g, b);
		}
		ask bathy with_min_of(each.grid_value)
		{
			ask mnt where (each.location overlaps self)
			{
				write "coucou";
				color <- #red;	
			}
			
		}
	}
	reflex to_execute 
	{
		switch(stage)
		{
			match 0 
			{ 
				

				// mnt_to_execute app(each.neighbors);
				mnt_to_execute <- mnt where(each.color = #red and each.computed = false); 
				if(length(mnt_to_execute) = 0)
				{
					write "finnnnnnnnnnnn";
					stage <- 1;	
				}
				
			}
			match 1
			{ 
				int i<-0;
				ask( mnt where (each.color = #red)) parallel:true
				{
					if(i mod 1000 = 0)
					{
						write "helleo "+i;
					}
					 	
				 	
				 	bathy tmp <- bathy[self.grid_x, self.grid_y]; //first_with(each.location = self.location);
				 	self.elevation <- tmp.grid_value;
				 	i <- i+1;	
				}
				stage <- 2;
			}
			match 2
			{
				int i<-0;
					
				ask( mnt where (each.color = #black))  parallel:true
					{
						
						if(i mod 1000 = 0)
						{
							write "helleo "+i;
						}
						 	
					 	
					 	topo tmp <- topo[self.grid_x, self.grid_y]; //first_with(each.location = self.location);
					 	self.elevation <- tmp.grid_value;
					 	i <- i+1;	
					}
				stage <- 3;
			}
			match 3
			{
				ask( mnt)
				{
					self.grid_value <- elevation;
				}
				stage <- 4;
				write "fin elevation";
				
			}
			
			match 4
			{
				write "file saved";
				save mnt to:"../results/dem.asc" type:"asc";
				write "file saved";
				stage <- 5;
				do pause;
			}
						
		}
	}
	

	
	reflex combine_bathy when: stage = 5
	{
		do pause;
	}	
}

species cote
{
	aspect default
	{
		draw shape;
	}
}

//grid final_mnt cell_width:20#m cell_height:20#m;

grid mnt cell_width:20#m cell_height:20#m schedules:mnt_to_execute  parallel:true
{
	rgb color<- #black;
	
	bool computed<-false;
	
	float elevation;
	
	
	reflex color_self when: computed = false and color = #red
	{
		list<mnt> voisin <- neighbors where(each.color != #red );
		ask voisin where (length(cote overlapping each)= 0) //neighbors where(each.color = #red ) > 0 and length(cote overlapping self) = 0)
		{
			color <- #red;
		
		}
		computed<-true;
	}
	//float level;
}


grid topo file:grid_top schedules:[]
{
	//float level;
}


grid bathy file:grid_bathy schedules:[]
{
	rgb color;

}




experiment DEMBaty type: gui {
	parameter "Fichier de DEM (grid en TIF)" var:grid_top;
	parameter "Fichier de bathymétrie (grid en TIF) - attention il doit être en NGF" var:grid_bathy;
	parameter "Fichier de délimitation (ex. trait de cote) (shape file)" var:trait_cote;
	parameter "bounding box (shape file)" var:convex_hull0_shape_file;
	
	output {
		display gridTextured type: opengl {
				grid mnt  text: true triangulation: true elevation: true;
				species cote;
			}
		
	}
}

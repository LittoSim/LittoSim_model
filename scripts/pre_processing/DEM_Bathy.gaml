/***
* Name: DEMBaty
* Author: nicolas
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model DEMBaty

global {
	
	//grid_file dem0_grid_file <- grid_file("includes/raw_files/dem.asc");

//	shape_file convex_hull0_shape_file <- shape_file("includes/raw_files/convex_hull.shp");

	//shape_file coastal_defenses0_shape_file <- shape_file("includes/raw_files/coastal_defenses.shp");

	
	int CELL_SIZE <- 20#m; // for archetypes overflow_coast this value is 20#m  
	//int CELL_SIZE <- 10#m; // for archetype cliff_coast this value is 10#m   
	
	grid_file grid_top <-grid_file("includes/raw_files/dem.asc");
	string strait_cote <- "../../includes/raw_files/coastline.shp";
	string sgrid_bathy <- "../../includes/raw_files/idw_clip.tif";
	
	shape_file trait_cote <- nil;
	grid_file grid_bathy <- nil;
	shape_file convex_hull0_shape_file <- shape_file("includes/raw_files/convex_hull.shp");
	shape_file coastal_defenses_file <-shape_file("includes/raw_files/coastal_defenses.shp");
	string output_file <- "./output_file/gathered_MNT_Bathy.asc";
	bool manage_coastal_defenses <- true;
	bool manage_baty_MNT <- true;
	geometry shape <- envelope(convex_hull0_shape_file);

	int stage <- 0;
	list<mnt> mnt_to_execute<-[];
	
	
	init
	{
		
		
		if(manage_baty_MNT)
		{
			trait_cote <- shape_file(strait_cote);
		 //	grid_bathy <- grid_file(sgrid_bathy);
		 	write("size MNT file " + length(topo));
			write("size bathymetric file " + length(bathy));
			
			if(length(topo) != length(bathy))
			{
				write "****************************\n* files has not the same   *\n* size. Check them         *\n****************************";
			}
			else
			{
				write "****************************\n* compatibility analysis   *\n* achieved                 *\n****************************";
			}
			create cote from: trait_cote;

		}	
		else
		{
			stage <- 2;
		}
		
		if(manage_coastal_defenses)
		{	
			create coastal_defense from:coastal_defenses_file;
		}

		ask topo {
			float r;
			float g;
			float b;
			if (grid_value < CELL_SIZE) {
				r <- 76 + (26 * (grid_value - 7) / 13);
				g <- 153 - (51 * (grid_value - 7) / 13);
				b <- 0.0;
			} else {
				r <- 102 + (122 * (grid_value - CELL_SIZE) / 19);
				g <- 51 + (173 * (grid_value - CELL_SIZE) / 19);
				b <- 224 * (grid_value - CELL_SIZE) / 19;
			}

			self.color <- rgb(r, g, b);
		}
		ask bathy {
			float r;
			float g;
			float b;
			if (grid_value < CELL_SIZE) {
				r <- 76 + (26 * (grid_value - 7) / 13);
				g <- 153 - (51 * (grid_value - 7) / 13);
				b <- 0.0;
			} else {
				r <- 102 + (122 * (grid_value - CELL_SIZE) / 19);
				g <- 51 + (173 * (grid_value - CELL_SIZE) / 19);
				b <- 224 * (grid_value - CELL_SIZE) / 19;
			}

			self.color <- rgb(r, g, b);
		}
		ask bathy with_min_of(each.grid_value)
		{
			ask mnt where (each.location overlaps self)
			{
				color <- #red;	
			}
			
		}
	}
	
	reflex to_execute when: cycle > 1
	{
		switch(stage)
		{
			match 0 
			{ 
				

				// mnt_to_execute app(each.neighbors);
				mnt_to_execute <- mnt where(each.color = #red and each.computed = false); 
				if(length(mnt_to_execute) = 0)
				{
					write "end stage : clipping";
					stage <- 1;	
				}
				
			}
			match 1
			{ 
				int i<-0;
				ask( mnt where (each.color = #red)) parallel:true
				{
				 	bathy tmp <- bathy[self.grid_x, self.grid_y]; //first_with(each.location = self.location);
				 	self.elevation <- tmp.grid_value;
				 	i <- i+1;	
				}
				write "end stage : bathymetric gathering";
				stage <- 2;
			}
			match 2
			{
				int i<-0;
					
				ask( mnt where (each.color = #black))  parallel:true
					{
						
					 	topo tmp <- topo[self.grid_x, self.grid_y]; //first_with(each.location = self.location);
					 	self.elevation <- tmp.grid_value;
					 	i <- i+1;	
					}
				write "end stage : MNT gathering";
				if(manage_coastal_defenses)
					{
						stage <- 3;
					}
					else
					{
						stage <- 4;
					}
			}
			
			match 3
			{
				do erase_coastal_defenses;
				stage <-4;
				write "end stage :remove coast defenses";
			}

			
			match 4
			{
				ask( mnt)
				{
					self.grid_value <- elevation;
				}
				stage <- 5;
				write "end stage : data exportation";
				
			}
			

			match 5
			{
				save mnt to:output_file type:"asc";
				write "file saved";
				write "\n**************************\n*     Process completed   *\n**************************";
				stage <- 6;
				do pause;
					
			}

						
		}
	}
	
	action erase_coastal_defenses
	{
		ask  coastal_defense 
		{
			ask mnt where(each.is_overlap_by_defense = false) overlapping self
			{
				is_overlap_by_defense <- true;
			}
		}
		ask mnt where(each.is_overlap_by_defense)
		{
			list<mnt> tmp <-self.neighbors;
			elevation <- mean((tmp where(each.is_overlap_by_defense = false) collect(each.elevation)));
		}
	}

	
	reflex combine_bathy when: stage = 6
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

species coastal_defense
{
	aspect default
	{
		draw shape color:#red;
	}
}

//grid final_mnt cell_width and cell_height are 20#m for some archtypes and 10#m for other archetypes ; this value value can be changed withe global paaramter CELL_SIZE 

grid mnt cell_width: CELL_SIZE cell_height: CELL_SIZE schedules:mnt_to_execute  parallel:true neighbors:8
{
	rgb color<- #black;
	
	bool computed<-false;
	
	float elevation;
	
	bool is_overlap_by_defense <- false;
	
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


grid bathy file:manage_baty_MNT?grid_file(sgrid_bathy):nil schedules:[]
{
	rgb color;

}




experiment DEM_Bathy type: gui {
	parameter "Fichier de DEM (grid en TIF)" var:grid_top;
	parameter "bounding box (shape file)" var:convex_hull0_shape_file;
	parameter "Fusion bathymetrie et MNT " var:manage_baty_MNT;
	parameter "Fichier de bathymétrie (grid en TIF) - attention il doit être en NGF" var:sgrid_bathy;
	parameter "Fichier de délimitation (ex. trait de cote) (shape file)" var:strait_cote;
	parameter "suppression des digues du mnt " var:manage_coastal_defenses;
	parameter "Fichier de digues" var:coastal_defenses_file;
	
	parameter "output files" var:output_file;
	
	
	output {
		display map type: opengl {
				grid mnt  text: true triangulation: true elevation: true;
				species coastal_defense;
				species cote;
			}
		
	}
}


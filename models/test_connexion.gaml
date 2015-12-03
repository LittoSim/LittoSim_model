/**
 *  testconnexion
 *  Author: nicolas
 *  Description: 
 */

model testconnexion

global {
	file communes_shape <- file("../includes/zone_etude/communes.shp");
	file mnt_shape <- file("../includes/zone_etude/all_cell_20m.shp");
	
	string COMMAND_SEPARATOR <- ":";
	string MANAGER_NAME <- "model_manager";
	string GROUP_NAME <- "Oleron";
		
	
	int ACTION_REPAIR_DYKE <- 5;
	int ACTION_CREATE_DYKE <- 6;
	int ACTION_DESTROY_DYKE <- 7;
	int ACTION_RAISE_DYKE <- 8;
	

	int ACTION_MODIFY_LAND_COVER_AU <- 1;
	int ACTION_MODIFY_LAND_COVER_A <- 2;
	int ACTION_MODIFY_LAND_COVER_U <- 3;
	int ACTION_MODIFY_LAND_COVER_N <- 4;
	
	list<int> ACTION_LIST <- [ACTION_REPAIR_DYKE,ACTION_CREATE_DYKE,ACTION_DESTROY_DYKE,ACTION_RAISE_DYKE,ACTION_MODIFY_LAND_COVER_AU,ACTION_MODIFY_LAND_COVER_A,ACTION_MODIFY_LAND_COVER_U,ACTION_MODIFY_LAND_COVER_N];
	file unAm_shape <- file("../includes/zone_etude/zones241115.shp");	
	
	
	geometry shape <- envelope(communes_shape);
	init
	{
		create game_controller number:1;
		create commune from:communes_shape with:[nom_raccourci::string(read("NOM_RAC"))];
		create cell_UnAm from: unAm_shape with: [id::int(read("FID_1")),land_cover_code::string(read("grid_code"))]
		{
			switch (land_cover_code)
			{
				match 1 {land_cover <- "N";}
				match 2 {land_cover <- "U";}
				match 4 {land_cover <- "AU";}
				match 5 {land_cover <- "A";}
			}
			my_color <- cell_color();
		}
		
		create cell_mnt from:mnt_shape with:[cell_id::int(read("ID")),soil_height::float(read("soil_heigh"))]
		{
			float tmp <-  ((soil_height  / 10) with_precision 1) * 255;
			color<- rgb( 255 - tmp, 180 - tmp , 0) ;
		}
		
		ask cell_mnt overlapping envelope(world.shape)
		{
			inside_commune <- true;
		}
		
		ask cell_mnt where(each.inside_commune = false)
		{
			 do die;
		} 
	}
	
}

species cell_mnt schedules:[]
{
	int cell_type <- 0 ; 
	int cell_id<-0;
	float water_height  <- 0.0;
	float soil_height <- 0.0;
	float rugosity;
	rgb color <- #white;
	
	bool inside_commune <- false;
	
	aspect elevation_eau
	{
		draw shape color:self.color border:self.color bitmap:true;
	}	
	
}


species game_controller skills:[network]
{
	init
	{
		do connectMessenger to:GROUP_NAME at:"localhost" withName:MANAGER_NAME;
	}
	
	reflex wait_message
	{
		loop while:!emptyMessageBox()
		{
			map msg <- fetchMessage();
			do read_action(msg["content"],msg["sender"]);
					
		}
	}
	
	action read_action(string act, string sender)
	{
		list<string> data <- act split_with COMMAND_SEPARATOR;
		write "message " + act;
		if(! (ACTION_LIST contains int(data[0])) )
		{
			return;
		}
		action_done tmp_agent <- nil;
		create action_done number:1 returns:tmp_agent_list;
		tmp_agent <- first(tmp_agent_list);
		ask(tmp_agent)
		{
			write "coucou " + act;
			self.command <- int(data[0]);
			self.id <- (data[1] + sender);
			if(self.command = ACTION_CREATE_DYKE)
			{
			/*	point ori <- {float(data[2]),float(data[3])};
				point des <- {float(data[4]),float(data[5])};
				point loc <- {float(data[6]),float(data[7])}; */
				write "sdffdsqfq "+ cell_mnt first_with(each.cell_id = data[2]) + " " + length(cell_mnt);
				point ori <- (cell_mnt first_with(each.cell_id = int(data[2]))).location;
				point des <- (cell_mnt first_with(each.cell_id = int(data[3]))).location;
				shape <- polyline([ori,des]);
				//location <- loc; 
			}
			else
			{
				chosen_element_id <- int(data[2]);
				cell_UnAm tempCell <- cell_UnAm first_with(each.id=chosen_element_id);
				self.location <- tempCell.location;
				self.shape <- tempCell.shape;
				
			}	
		}
		
	}
}
	
species action_done
{
	string id;
	int chosen_element_id;
	//string command_group <- "";
	int command <- -1;
	string label <- "no name";
	float cost <- 0.0;	
	rgb define_color
	{
		switch(command)
		{
			 match ACTION_CREATE_DYKE { return #blue;}
			 match ACTION_REPAIR_DYKE {return #green;}
			 match ACTION_DESTROY_DYKE {return #brown;}
			 match ACTION_MODIFY_LAND_COVER_A { return #brown;}
			 match ACTION_MODIFY_LAND_COVER_AU {return #orange;}
			 match ACTION_MODIFY_LAND_COVER_N {return #green;}
		} 
		return #grey;
	}
	
	
	
	aspect base
	{
		draw  20#m around shape color:define_color() border:#red;
	}

	
	aspect base
	{
		draw shape color:define_color();
	}
	
}



species commune
{	int id<-0;
	string nom_raccourci <-"";
	int budget <-10000;
	int impot_unit <- 1000;
	aspect base
	{
		draw shape color:#whitesmoke;
	}		
}

species cell_UnAm
{
	string land_cover <- "";
	int id;
	int land_cover_code <- 0;
	rgb my_color <- cell_color() update: cell_color();


	rgb cell_color
	{
		rgb res <- nil;
		switch (land_cover_code)
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

}
















experiment testconnexion type: gui {
	/** Insert here the definition of the input and output of the model */
	output {
		display test {
			species commune aspect:base;
			species cell_UnAm aspect:base;
			species action_done aspect:base;
		}
	}
}

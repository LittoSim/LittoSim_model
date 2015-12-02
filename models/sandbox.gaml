/**
 *  oleronV1
 *  Author: Brice, Etienne, Nico B, Nico M et Fred pour l'instant
 * 
 *  Description: Cette sandbox permet de tester la levé de l'impot et faciliter l'intégration dans le projet littoSim
 */

model oleronV1

global  { 
	float impot_unit <- 1000.0;
	
	/*
	 * Chargements des données SIG
	 */
		file communes_shape <- file("../includes/zone_etude/communes.shp");
		file plu_shp <- file("../includes/zone_etude/zones211115.shp");
		file defenses_cote <- file("../includes/zone_etude/defense_cote_littoSIM.shp");

	/* Definition de l'enveloppe SIG de travail */
		geometry shape <- envelope(plu_shp);
	
	int step_button <- 1;
	float button_size <- 2000#m;
	
	init
	{	
		do init_buttons;
		/*Les actions contenu dans le bloque init sonr exécuté à l'initialisation du modele*/
		
		/*Creation des agents a partir des données SIG */
		create defense_cote from:defenses_cote;
		create player_commune from: communes_shape;
		create generic_plu from: plu_shp with:[ID::string(read ("NOM")),type_zone::int(get("grid_code")), 
			prix_m2::float(get("prix_m2")), population::float(get("Avg_ind_c"))
		];
		
		ask player_commune {
			myPLU <- generic_plu overlapping self;
		}
	
	}
	
	action init_buttons
	{
		create buttons number: 1
		{
			command <- step_button;
			label <- "One step";
			shape <- square(button_size);
			location <- { world.shape.width - 1000#m, 1000#m };
			my_icon <- image_file("../images/icones/one_step.png");
		}
	}
	
	action run_one_step (point loc, list selected_agents)
    {
       ask selected_agents {
      	write "plop";
      }
    }
	
 	
 }
	
 

/*
 * ***********************************************************************************************
 *                        ZONE de description des species
 *  **********************************************************************************************
 */

species buttons
{
	int command <- -1;
	string display_name <- "no name";
	string label <- "no name";
	float action_cost<-0;
	bool is_selected <- false;
	geometry shape <- square(500#m);
	file my_icon;
	aspect base
	{
			draw shape color:#white border: is_selected ? # red : # white;
			draw my_icon size:button_size-50#m ;
			
	}
}

species defense_cote
{
	aspect base
	{
		draw shape /*color:#yellow*/;
	}
}

species generic_plu {
	string ID;
	int type_zone;
	float prix_m2;
	float population;
	int time_zone init: 0 update: time_zone + 1;
	
	// Ce reflex change les zone AU en zone U au bout de 3 itérations
	// et si la zone est U fait acroitre la population 
	reflex up_pop {
		if (type_zone = 4 and time_zone >= 3){
			type_zone <- 2;
			time_zone <- 0;
		}
		if (type_zone = 2 and population < 1000){
			population <- population + 10;
		}
	}
	
	aspect base {
		//draw shape color: rgb(color_u);
		draw shape color: rgb(255,0,population);
	}
}

species player_commune {
	int id <- rnd(5);
	list<generic_plu> myPLU ;
	float budget init: 10000.0;
	
	reflex impotsition {
		float nb_impose <- sum(myPLU accumulate (each.population));
		budget <- budget + nb_impose * impot_unit;
	}
	
	// un reflex pour tester l'urbanisation
	reflex urabnisation {
		ask 10 among generic_plu where(each.type_zone = 5){
			type_zone <- 4;
		}
	}
	
	aspect base {
		draw shape color: #gray;
	}
}


experiment oleronV1 type: gui {
	output {
			display carte_oleron type: opengl {
				//species commune aspect:base;
				species buttons aspect:base;
				species player_commune aspect:base;
				species defense_cote aspect:base;
				species generic_plu aspect:base;
				//species player_commune aspect:base;
				event [mouse_down] action: run_one_step;
				
				}
			display graph_budjet {
				chart "Series" type: series {
					data "budget" value: (player_commune collect each.budget)  color: #red;				
				}
			}
			display graph_plots {
				chart "Series" type: histogram background: rgb("white"){
					loop ag over:  player_commune {           
      								 data "com"+ag.name value: length(ag.myPLU) color: #orange;                          
                                }			
				}
			}
	}
}
		

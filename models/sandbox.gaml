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
		file plu_shp <- file("../includes/le_chateau/chatok_pop.shp");
		file defenses_cote <- file("../includes/zone_etude/defense_cote_littoSIM.shp");

	/* Definition de l'enveloppe SIG de travail */
		geometry shape <- envelope(plu_shp);
	


	init
	{
		/*Les actions contenu dans le bloque init sonr exécuté à l'initialisation du modele*/
		
		/*Creation des agents a partir des données SIG */
		create defense_cote from:defenses_cote;
		create player_commune from: communes_shape;
		create generic_plu from: plu_shp with:[ID::int(read ("OBJECTID")),type_zone::string(read("TYPEZONE")), 
			shape_area::float(get("Shape_Area")), color_u::string(read("color")), population::float(get("pop"))
		];
		
		ask player_commune {
			myPLU <- generic_plu overlapping self;
		}
	
	}
	
 	
 }
	
 

/*
 * ***********************************************************************************************
 *                        ZONE de description des species
 *  **********************************************************************************************
 */


species defense_cote
{
	aspect base
	{
		draw shape /*color:#yellow*/;
	}
}

species generic_plu {
	int ID;
	string type_zone;
	float shape_area;
	string color_u;
	float population;
	aspect base {
		draw shape color: rgb(color_u);
	}
}

species player_commune {
	list<generic_plu> myPLU ;
	float budget init: 10000.0;
	
	reflex impotsition {
		float nb_impose <- sum(myPLU accumulate (each.population));
		budget <- budget + nb_impose * impot_unit;
	}
	
	aspect base {
		draw shape color: #gray;
	}
}


experiment oleronV1 type: gui {
	output {
			display carte_oleron type: opengl {
				//species commune aspect:base;
				species defense_cote aspect:base;
				species generic_plu aspect:base;
				species player_commune aspect:base;
				}
			display graph_budjet {
				chart "Series" type: series {
					data "budget" value: (player_commune collect each.budget)  color: #red;				
				}
			}
	}
}
		

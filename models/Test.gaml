/***
* Name: Test
* Author: jean2
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model Test

/* Insert your model definition here */
global{
	image_file dike_symbol_img <- image_file("../images/system_icons/player/normal_dune_symbol.png");
	
	init{
		create dike number: 1;
	}
}

species dike{
	string name;
	
	aspect basic{
		draw dike_symbol_img size:10;
	}
}

experiment mainExp type:gui{
	output{
		display mainDisplay {
			species dike aspect:basic;
		}
	}
}
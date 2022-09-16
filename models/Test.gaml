/***
* Name: Test
* Author: jean2
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model Test

/* Insert your model definition here */
global{
	image_file textures <- image_file("../images/system_icons/player/trait.png");
	init{
		create dike number: 10;
	}
}

species dike{
	string name;
	
	aspect basic{
		draw square(15) size:10 color: #black empty:true texture:"../images/system_icons/player/trait.png";
	}
}

experiment mainExp type:gui{
	output{
		display mainDisplay {
			species dike aspect:basic;
		}
	}
}
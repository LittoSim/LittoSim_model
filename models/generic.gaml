/***
* Name: generic
* Author: atelier
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model generic

global {

	map<string,map> levers <- store_csv_data_into_map_of_map("../includes/estuary_coast/levers.conf", ";");
		
	init {

		loop lev over: levers.keys {
			create Lever {
				code <- lev;
				name <- levers at lev at 'fr';
				type <- levers at lev at 'type';
				threshold  <- float(levers at lev at 'threshold');
				added_cost <- float(levers at lev at 'cost');
				player_msg <- '';
			}
		}
		
		ask Lever {
			write ""+code+" : " + name + " : " + type + " : " + threshold + " : " + added_cost;
		}
		
	}
	
	
	map<string, map> store_csv_data_into_map_of_map(string fileName, string separator){
		map<string, map> res ;
		string line <- "";
		list<string> col_labels <- [];
		loop line over: text_file(fileName){
			if(line contains(separator)){
				list<string> data <- line split_with(separator);
				if empty(col_labels) {
					col_labels <- data ;
				} 
				else{
					map  sub_res <- map([]);
					loop i from: 1 to: ((length(col_labels))-1) {
						add data[i] at: col_labels[i] to: sub_res ;
					}
					add sub_res at:data[0] to:res ;
				}	
			}
		}
		return res;
	}
}


species Lever {
	string code;
	string name;
	string type;
	float threshold;
	float added_cost;
	string player_msg;
	//float indicator 		-> { my_district.length_dikes_t0 = 0 ? 0.0 : my_district.length_created_dikes / my_district.length_dikes_t0 };
	//string progression_bar  -> { "" + my_district.length_created_dikes + " m / " + threshold + " * " + my_district.length_dikes_t0 + " m " +LEV_AT+ " t0"};
	
	init{
	}
}

experiment generic type: gui {
	output {
	}
}

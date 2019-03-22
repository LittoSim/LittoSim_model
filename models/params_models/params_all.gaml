/**
* Name: paramsleader
* Author: 
*/

model paramsall

global{
	
	////////// CONFIGURATION LITTOSIM_GEN //////////
	// Paramètres de Communication Network 
	string SERVER <- configuration_file["SERVER_ADDRESS"]; 
	string COMMAND_SEPARATOR <- ":";
	string GAME_MANAGER <- "GAME_MANAGER";
	string MSG_FROM_LEADER <- "MSG_FROM_LEADER";
	
	// common parameters
	string UNAM_DISPLAY <- "UnAm";
	string LEADER_COMMAND <- "leader_command";
	
	// Codification des actions pour Communication Network 
	//Liste de l'ensemble des messages possibles à envoyer via Communication Network
	list<int> ACTION_LIST <- [CONNECTION_MESSAGE,REFRESH_ALL,ACTION_REPAIR_DIKE,ACTION_CREATE_DIKE,ACTION_DESTROY_DIKE,ACTION_RAISE_DIKE,ACTION_INSTALL_GANIVELLE,ACTION_MODIFY_LAND_COVER_AU,ACTION_MODIFY_LAND_COVER_AUs,ACTION_MODIFY_LAND_COVER_A,ACTION_MODIFY_LAND_COVER_U,ACTION_MODIFY_LAND_COVER_Us,ACTION_MODIFY_LAND_COVER_Ui,ACTION_MODIFY_LAND_COVER_N];
	
	float MOUSE_BUFFER <-float(configuration_file["MOUSE_BUFFER"]); // 50#m; // zone considéré autour de l'endroit où l'on clic pour repérer si un bouton de l'interface a été cliqué 
	
	////////// PARAMETRES DES MODULES //////////
	// Paramètres des actions de construction et de réhaussement de digues
	string BUILT_DIKE_TYPE <- "nouvelle digue"; // type de nouvelle digue
	string BUILT_DIKE_STATUS <- shapes_def["BUILT_DIKE_STATUS"]; // status de nouvelle digue
	
	////////// CHARGEMENT DES FICHIERS //////////
	// le fichier de configuration principale
	string config_file_name <- "../includes/config/littosim.csv";
	map<string,string> configuration_file <- read_configuration_file(config_file_name,";");
	// le fichier de configuration des données shape
	map<string,string> shapes_def <- read_configuration_file(configuration_file["SHAPE_DEF_FILE"],";");
	// le fichier de configuration du modèle de flooding
	map<string,string> flooding_def <- read_configuration_file(configuration_file["FLOODING_DEF_FILE"],";");
	// le fichier de configuration des actions, des couts et des délais
	matrix<string> actions_def <- matrix<string>(csv_file(configuration_file["ACTION_DEF_FILE"],";"));	
	//le fichier de configuration des langues
	map<string,map> langs_def <- store_csv_data_into_map_of_map(configuration_file["LANG_DEF_FILE"],";");
	// Chargement des paramètres des actions 
	// Pour utiliser la map data_action, utiliser la syntaxe data_action at NOM_ACTION at nom_du_paramètre (action code, delay, cost ou entity). Exemple data_action at 'ACTON_MODIFY_LAND_COVER_FROM_A_TO_N' at 'cost'; 
	map<string,map> data_action <- store_csv_data_into_map_of_map(configuration_file["ACTION_DEF_FILE"],";");
	
	
	////////// CONFIGURATION DE LA ZONE D'ETUDE //////////
	// Chargements des données SIG	
	file communes_shape <- file(shapes_def["COMMUNE_SHAPE"]);
	file road_shape <- file(shapes_def["ROAD_SHAPE"]);
	file zone_protegee_shape <- file(shapes_def["ZONES_PROTEGEES_SHAPE"]);
	file zone_PPR_shape <- file(shapes_def["ZONES_PPR_SHAPE"]);
	file coastline_shape <- file(shapes_def["COASTLINES_SHAPE"]);
	file defenses_cotes_shape <- file(shapes_def["DEFENSES_COTES_SHAPE"]);
	file unAm_shape <- file(shapes_def["UNAM_SHAPE"]);	
	file emprise_shape <- file(shapes_def["EMPRISE_SHAPE"]); 
	file dem_file <- file(shapes_def["DEM_FILE"]) ;
	file contour_ile_moins_100m_shape <- file(shapes_def["CONTOUR_ILE_INF_100M"]);
	int nb_cols <- int(shapes_def["DEM_NB_COLS"]);
	int nb_rows <- int(shapes_def["DEM_NB_ROWS"]);
	map table_correspondance_insee_com_nom <- eval_gaml(shapes_def["CORRESPONDANCE_INSEE_COM_NOM"]);
	map table_correspondance_insee_com_nom_rac <- eval_gaml(shapes_def["CORRESPONDANCE_INSEE_COM_NOM_RAC"]);
	
	// Liste des actions avec leur code correspondant
	int ACTION_REPAIR_DIKE <- int(data_action at 'ACTION_REPAIR_DIKE' at 'action code');
	int ACTION_CREATE_DIKE <- int(data_action at 'ACTION_CREATE_DIKE' at 'action code');
	int ACTION_DESTROY_DIKE <- int(data_action at 'ACTION_DESTROY_DIKE' at 'action code');
	int ACTION_RAISE_DIKE <- int(data_action at 'ACTION_REPAIR_DIKE' at 'action code');
	int ACTION_INSTALL_GANIVELLE <- int(data_action at 'ACTION_INSTALL_GANIVELLE' at 'action code');
	int ACTION_MODIFY_LAND_COVER_AU <- int(data_action at 'ACTION_MODIFY_LAND_COVER_AU' at 'action code');
	int ACTION_MODIFY_LAND_COVER_A <- int(data_action at 'ACTION_MODIFY_LAND_COVER_A' at 'action code');
	int ACTION_MODIFY_LAND_COVER_U <- int(data_action at 'ACTION_MODIFY_LAND_COVER_U' at 'action code');
	int ACTION_MODIFY_LAND_COVER_N <- int(data_action at 'ACTION_MODIFY_LAND_COVER_N' at 'action code');
	int ACTION_MODIFY_LAND_COVER_AUs <- int(data_action at 'ACTION_MODIFY_LAND_COVER_AUs' at 'action code');	
	int ACTION_MODIFY_LAND_COVER_Us <- int(data_action at 'ACTION_MODIFY_LAND_COVER_Us' at 'action code');
	int ACTION_MODIFY_LAND_COVER_Ui <- int(data_action at 'ACTION_MODIFY_LAND_COVER_Ui' at 'action code');
	int ACTION_EXPROPRIATION <- int(data_action at 'ACTION_EXPROPRIATION' at 'action code');
	
	int ACTION_ACTION_DONE_UPDATE<- 101;
	int ACTION_ACTION_LIST <- 211;
	int ACTION_DONE_APPLICATION_ACKNOWLEDGEMENT <- 51;
	int ACTION_LAND_COVER_UPDATE<-9;
	int ACTION_DIKE_UPDATE<-10;
	int INFORM_ROUND <-34;
	int NOTIFY_DELAY <-35;
	int ENTITY_TYPE_CODE_DEF_COTE <-36;
	int ENTITY_TYPE_CODE_UA <-37;
	
	// Actions to acknowledge client requests.
	int ACTION_DIKE_CREATED <- 16;
	int ACTION_DIKE_DROPPED <- 17;
	int UPDATE_BUDGET <- 19;
	int REFRESH_ALL <- 20;
	int ACTION_DIKE_LIST <- 21;
	int CONNECTION_MESSAGE <- 23;
	int INFORM_TAX_GAIN <-24;
	int INFORM_GRANT_RECEIVED <-27;
	int INFORM_FINE_RECEIVED <-28;
	
	// Messages à afficher en multilangues
	string MSG_SIM_NOT_STARTED <- langs_def at 'MSG_SIM_NOT_STARTED' at configuration_file["LANGUAGE"];
		
	////////// FONCTIONS POUR LA LECTURE DES FICHIERS DE CONFIGURATION //////////
	map<string, string> read_configuration_file(string fileName,string separator){
		map<string, string> res <- map<string, string>([]);
		string line <-"";
		loop line over:text_file(fileName){
			if(line contains(separator)){
				list<string> data <- line split_with(separator);
				add data[1] at:data[0] to:res;	
			}				
		}
		return res;
	}
	
	map<string, map> store_csv_data_into_map_of_map(string fileName,string separator){
		map<string, map> res ;
		string line <-"";
		list<string> col_labels <- [];
		loop line over:text_file(fileName){
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
	
	// on récupère d'abord l'action name, puis on récupère le label approprié à partir du fichier de langues
	string labelOfAction (int action_code){
		string rslt <- "";
		loop i from:0 to: (length(actions_def) /3) - 1 {
			if ((int(actions_def at {1,i})) = action_code){
				rslt <- actions_def at {0,i}; // action name
				rslt <- langs_def at rslt at configuration_file["LANGUAGE"]; // action label
			}
		}
		return rslt;
	}
}


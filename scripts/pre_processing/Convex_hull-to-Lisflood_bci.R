#############################################################################
# R script for generating data to the LittoSIM model						#
# @Authors: Ahmed Laatabi													#
# @Description: this script generates the bci file for Lisflood model		#
# by reading the convex_hull and districts shapefiles and parameters from 	#
# the XML input configuration file:
# It also generates the following files:									#
#	+ 															#
#############################################################################
library('XML')
library('methods')
library('rgdal')
library('rgeos')
library('sp')
library('stringr')

# reading the configuration file
config_file <- xmlTreeParse(file = 'convex_hull_to_bci.xml', useInternalNodes = TRUE);
config_node <- xmlRoot(config_file);

# reading processed input files
input_folder <- xmlValue(xmlElementsByTagName(el = config_node, 'input-files')[[1]]);
if(!file.exists(input_folder)){
	stop(paste(input_folder,': input files folder does not exist!'));
}

# reading parameters : the number and the direction of BCI segments
app_name 	<- xmlValue(xmlElementsByTagName(el = config_node, 'app-name')[[1]]);
lista 		<- xmlElementsByTagName(el = config_node, 'direction');
directions 	<- c(xmlValue(lista[[1]]), xmlValue(lista[[2]]));
lista 		<- xmlElementsByTagName(el = config_node, 'segments');
my_segments <- as.integer(c(xmlValue(lista[[1]]), xmlValue(lista[[2]])));

# shapefiles 
convex_hull <- readOGR(dsn = input_folder, layer = 'convex_hull', verbose=FALSE);
districts <- readOGR(dsn = input_folder, layer = 'districts', verbose=FALSE);

bounds <- convex_hull@bbox;

if (directions[1] == 'E'){
	my_bound1 <- c(bounds[1,2],bounds[2,1]);
	my_bound2 <- c(bounds[1,2],bounds[2,2]);
	if (directions[2] == 'S'){
		my_bound3 <- c(bounds[1,1],bounds[2,1]);
	} else{ # N
		my_bound3 <- c(bounds[1,1],bounds[2,2]);
	}
} else{ # W
	my_bound1 <- c(bounds[1,1],bounds[2,1]);
	my_bound2 <- c(bounds[1,1],bounds[2,2]);
	if (directions[2] == 'S'){
		my_bound3 <- c(bounds[1,2],bounds[2,1]);
	} else{ # N
		my_bound3 <- c(bounds[1,2],bounds[2,2]);
	}
}

coords 		<- matrix(c(my_bound1,my_bound2,my_bound3,my_bound1), ncol = 2, byrow=TRUE);
spoly 		<- SpatialPolygons(list(Polygons(list(Polygon(coords)), ID = "a")), proj4string= CRS(proj4string(convex_hull)));
my_shapes 	<- disaggregate (raster::intersect(spoly, convex_hull - districts));
my_shp 		<- my_shapes[1,];

for (ix in (2:length(my_shapes))){
	if(my_shapes@polygons[[ix]]@area > my_shp@polygons[[1]]@area){
		my_shp <- my_shapes[ix,];
	}
}

bounds <- my_shp@bbox;
xinterv <- (bounds[1,2] - bounds[1,1]) / my_segments[2]; # S or N
yinterv <- (bounds[2,2] - bounds[2,1]) / my_segments[1]; # E or W

str_to_save <- "";
bnd <- bounds[2,2];
for (ix in(1:my_segments[1])){
	str_to_save <- paste(str_to_save, directions[1], '\t\t', as.integer(bnd), '\t\t', as.integer(bnd - yinterv), '\t\tHVAR', '\t\t', directions[1] , '_', app_name, ix, '\n', sep='');
	bnd <- bnd - yinterv;
}
bnd <- bounds[1,2];
for (ix in(1:my_segments[2])){
	str_to_save <- paste(str_to_save, directions[2], '\t\t', as.integer(bnd), '\t\t', as.integer(bnd - xinterv), '\t\tHVAR', '\t\t', directions[2] , '_', app_name, ix, '\n', sep=''); 
	bnd <- bnd - xinterv;
}

writeLines(str_to_save, paste(app_name,".bci",sep=''));

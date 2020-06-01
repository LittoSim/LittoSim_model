#############################################################################
# R script for generating data to the LittoSIM model						            #
# @Authors: Ahmed Laatabi												                          	#
# @Description: this script processes input files to adapt fields 		    	#
# and parameters to required form based on the XML input configuration file.#
# It also generates the following files:								                  	#
#	+ land_use.shp													 	                              	#
#	+ convex_hull.shp												                              		#
#	+ buffer_in_100m.shp									                            				#
#	+ rugosity.asc											                              				#
#	+ {app_name}_start.asc										                    						#
#############################################################################

library('XML')
library('methods')
library('rgdal')
library('rgeos')
library('sp')
library('stringr')
library('raster')

#setwd("~/Desktop/formaLG")

# installed_packages <- row.names(installed.packages())
# if (! "XML" %in% installed_packages) install.packages("XML")
# library('XML')
# if (! "methods" %in% installed_packages) install.packages("methods")
# library('methods')
# if (! "rgdal" %in% installed_packages) install.packages("rgdal")
# library('rgdal')
# if (! "rgeos" %in% installed_packages) install.packages("rgeos")
# library('rgeos')
# if (! "sp" %in% installed_packages) install.packages("sp")
# library('sp')
# if (! "stringr" %in% installed_packages) install.packages("stringr")
# library('stringr')
# if (! "raster" %in% installed_packages) install.packages("raster")
# library('raster')

# reading the mapping configuration file
mapping_file <- xmlTreeParse(file = 'mapping_rochefort.xml', useInternalNodes = TRUE);
mapping_node <- xmlRoot(mapping_file);
app_name 	 <- xmlValue(xmlElementsByTagName(el = mapping_node, 'app-name')[[1]]);

# input and output folders
if(length(xmlElementsByTagName(el = mapping_node, 'input-files')) == 0){
	stop('input-files folder is not specified in the mapping file!');
}
input_folder <- xmlValue(xmlElementsByTagName(el = mapping_node, 'input-files')[[1]]);
if(!file.exists(input_folder)){
	stop(paste(input_folder,': input files folder does not exist!'));
}
output_folder <- xmlValue(xmlElementsByTagName(el = mapping_node, 'output-files')[[1]]);
if(!file.exists(output_folder)){
	dir.create(output_folder);
}

# list of files in the mapping configuration file
listOfFiles = xmlElementsByTagName(el = mapping_node, 'file');

if(length(listOfFiles) == 0){
	stop('No files in the mapping configuration file');
}

#for each file that needs transformation
for(i in(1:length(listOfFiles))){
	input_file_name <- xmlGetAttr(listOfFiles[[i]],'input-name');
	output_file_name <- xmlGetAttr(listOfFiles[[i]],'output-name');
			
	# checking if the file exists
	if(file.exists(paste(input_folder, input_file_name, sep='/'))){
		###########################
		# the file is a shapefile #
		###########################
		if(grepl('.shp', input_file_name)){
			print(paste('file',input_file_name,'..... OK (shapefile)'));
			# getting file name without extension
			input_file_without_ext <- substr(input_file_name,1,str_locate(input_file_name,'.shp')[1,1]-1);
			
			# reading the shape file
			shape_file <- readOGR(dsn = input_folder, layer = input_file_without_ext, verbose=FALSE);
			# correcting projection to Lambert-93 (epsg:2154) (<<Topology>>)
			if(is.na(proj4string(shape_file))){
				proj4string(shape_file) <- CRS('+init=epsg:2154');
			}else{
				shape_file <- spTransform(shape_file, CRS('+init=epsg:2154'));
			}

			# processing attributes of the shapefile 
			processed_atts <- c(); # list of processed attributes
			
			# list of relevant (LittoSIM) attributes in the file
			listOfAttributes = xmlElementsByTagName(el = listOfFiles[[i]], 'attribute');
			# if no attributes, we omit this code block
			if(length(listOfAttributes) != 0){
				for(j in(1:length(listOfAttributes))){
					# getting attribute parameters 
					attribute_input_name <- xmlValue(listOfAttributes[[j]][['input-name']]);
					attribute_output_name <- xmlGetAttr(listOfAttributes[[j]],'output-name');
					
					# if a new attribute is to be created (<<Generate>>)
					if(attribute_input_name == 'na'){
						attribute_generator <- xmlValue(listOfAttributes[[j]][['generate']]);
						if(attribute_generator == 'ID'){
							#generating the attribute as an ID
							shape_file$new_attribute_id  <- 1:length(shape_file);
							names(shape_file)[names(shape_file) == 'new_attribute_id'] <- attribute_output_name;
							# add this attribute to list of processed attributes
							processed_atts <- c(processed_atts, attribute_output_name);
							print(paste('attribute',attribute_output_name,'has been created'));
						}
					}
					# if the is not to be created, we check that it exists in the shapefile
					else if(attribute_input_name %in% names(shape_file)){
					
						# converting the attribute to the required output name and format (integer, double, or string)
						names(shape_file)[names(shape_file) == attribute_input_name] <- attribute_output_name; # (<<Rename>>)
						attribute_type <- xmlGetAttr(listOfAttributes[[j]],'type'); # (<<Convert>>)
						switch(attribute_type,
							'integer'={
								shape_file@data[attribute_output_name][[1]] <- as.integer(shape_file@data[attribute_output_name][[1]]);
								print(paste('attribute',attribute_input_name,'converted to',attribute_output_name,'(integer)'));
							},
							'double'={
								shape_file@data[attribute_output_name][[1]] <- as.double(shape_file@data[attribute_output_name][[1]]);
								print(paste('attribute',attribute_input_name,'converted to',attribute_output_name,'(double)'));
							},
							'string'={
								shape_file@data[attribute_output_name][[1]] <- as.character(shape_file@data[attribute_output_name][[1]]);
								print(paste('attribute',attribute_input_name,'converted to',attribute_output_name,'(string)'));
							},
						);
												
						# processing attribute values to replace with LittoSIM data (<<Replace>>) 
						listOfReplacements <- xmlElementsByTagName(el = listOfAttributes[[j]], 'replace');
						if(length(listOfReplacements) > 0){
							already_replaced_values <- c(); # to manage the generic replacement (*)
							for(k in(1:length(listOfReplacements))){
								value_to_replace <- xmlGetAttr(listOfReplacements[[k]],'value');
								new_value <-  xmlValue(listOfReplacements[[k]]);
								# generic replacement (ATTENTION: "*" must be the last <replace> tag in the configuration file)
								if(value_to_replace == '*'){
									if(class(shape_file@data[attribute_output_name][[1]]) == 'factor'){
									levels(shape_file@data[attribute_output_name][[1]])[!levels(shape_file@data[attribute_output_name][[1]]) %in% already_replaced_values] <- new_value; 
									} else{
										shape_file@data[attribute_output_name][[1]][!shape_file@data[attribute_output_name][[1]] %in% already_replaced_values] <- new_value;
									}
								}
								# replacement of a specific value
								else{
									if(class(shape_file@data[attribute_output_name][[1]]) == 'factor'){
									levels(shape_file@data[attribute_output_name][[1]])[levels(shape_file@data[attribute_output_name][[1]]) == value_to_replace] <- new_value; 
									} else{
										shape_file@data[attribute_output_name][[1]][shape_file@data[attribute_output_name][[1]] %in% value_to_replace] <- new_value;
									}
								}
								print(paste(value_to_replace,'replaced by',new_value));
								# to avoid replacing already replaced values
								already_replaced_values <- c(already_replaced_values,new_value);
							}
						}
						# add this attribute to list of processed atts
						processed_atts <- c(processed_atts, attribute_output_name);
					}
					else{
						warning(paste('attribute',attribute_input_name,'does not exist in',input_file_name));
					}
				}
			}
			# removing non required attributes from shapefiles
			for(att_to_remove in names(shape_file)){
				if(!att_to_remove %in% processed_atts){ # attribute not processed, remove it !
					shape_file@data[att_to_remove][[1]] <- NULL;
					print(paste('attribute',att_to_remove,'has been removed.'));
				}
			}
			######## end of textual features processing ########
			####################################################
			########### spatial features processing ############
			
			# creating an ID for shapefile objects
			shape_file$ID <- 1:length(shape_file); # (<<Generate>>)
			output_file_without_ext <- substr(output_file_name,1,str_locate(output_file_name,'.shp')[1,1]-1);
			# customized processing of shapefiles
			
			if(output_file_without_ext == 'rpp'){ # unifying rpp polygons (<<Merge>>)
				print('Unifying rpp file');
			  unified_rpp <- gBuffer(shape_file, byid=TRUE, width=0)
				unified_rpp = gUnaryUnion(spgeom = unified_rpp);
				shape_file <- SpatialPolygonsDataFrame(unified_rpp, data.frame(ID=1:length(unified_rpp)), match.ID=FALSE);
			}
			else if(output_file_without_ext == 'spa'){ # unifying spa polygons (<<Merge>>)
				print('Unifying spa file');
			  unified_spa <- gBuffer(shape_file, byid=TRUE, width=0)
				unified_spa = gUnaryUnion(spgeom = unified_spa);
				shape_file <- SpatialPolygonsDataFrame(unified_spa, data.frame(ID=1:length(unified_spa)), match.ID=FALSE);
			}
			else if(output_file_without_ext == 'buildings'){ # filtering residential buildings only
				buildings <- shape_file[shape_file$bld_type == 'Residential',];
			}
			else if(output_file_without_ext == 'urban_plan'){ # keeping the urban plan file for further processing (generate land_use)
				urban_plan <- shape_file;
			}
			else if(output_file_without_ext == 'land_cover'){ ## keeping the land cover file for further processing (generate rugosity)
				land_cover <- shape_file;
				######################################################
				# generating the raster file : rugosity.asc			 # (<<Generate Raster>>)
				# and also an empty raster start.asc for LISFLOOD-FP #
				######################################################
				rugosity <- xmlElementsByTagName(el = mapping_node, 'rugosity')[[1]];
				nrows <- as.integer(xmlValue(xmlElementsByTagName(el = rugosity, 'nrows')[[1]]))
				ncols <- as.integer(xmlValue(xmlElementsByTagName(el = rugosity, 'ncols')[[1]]))
				resolution <- as.integer(xmlValue(xmlElementsByTagName(el = rugosity, 'resolution')[[1]]))
				ras <- raster(nrow= nrows, ncol= ncols, crs=projection(land_cover), ext=extent(land_cover), res=resolution)
				
				# {app_name}_start.asc : the start grid (a grid of 0 values) for LISFLOOD
				strt <- rasterize(land_cover, ras, field=0)
				strt[is.na(strt)] <- 0
				start_file_name <- paste(app_name, "_start", sep="");
				writeRaster(strt, paste(output_folder, start_file_name, sep="/"), format = "ascii", overwrite=TRUE);
				
				# the rugosity grid with values of land_cover
				rugo <- rasterize(land_cover, ras, field='ID');
				ids <- as.vector(as.numeric(as.character(land_cover$ID)))
				vals <- as.vector(as.numeric(as.character(land_cover$cover_type)))
				for(i in(1:length(ids))){
				  rugo[rugo == ids[i]] <- vals[i]
				}
				# replacing land cover values with manning coefficients()
				mannings <- xmlElementsByTagName(el = rugosity, 'manning');
				for(xman in(1:length(mannings))){
					rugo[rugo == as.double(xmlGetAttr(mannings[[xman]],'value'))] <- as.double(xmlValue(mannings[[xman]]));
				}
				writeRaster(rugo, paste(output_folder,"rugosity",sep="/"), format = "ascii", overwrite=TRUE);
				print(paste('files rugosity.asc and start.asc have been created in',output_folder));
				print('-------------------------');
			}
			
			else if(output_file_without_ext == 'districts'){ # selecting active districts only
				active_districts <- xmlElementsByTagName(el = listOfFiles[[i]], 'active-districts');
				listOfActiveDistricts <- xmlElementsByTagName(el = active_districts[[1]], 'district');
				list_dists <- c();
				for(ad in(1:length(listOfActiveDistricts))){
					list_dists <- c(list_dists, xmlValue(listOfActiveDistricts[[ad]]));
				}
				active_shape_file <- shape_file[shape_file$dist_code %in% list_dists,];
				
				######################################################
				# generating the envelope file : convex_hull.shp     # (<<Generate Polygon>>)
				# This convex_hull is used to generate the
				#		land_use grid. The final convex_hull used in the 	 #
				#		simulation is generated based on the dem file#
				#		at the end of this script.					 #
				######################################################
				emprisesp <- as(raster::extent(shape_file@bbox[1,1], shape_file@bbox[1,2],
								shape_file@bbox[2,1], shape_file@bbox[2,2]), "SpatialPolygons");
				proj4string(emprisesp) = shape_file@proj4string;
				convex_hull <- SpatialPolygonsDataFrame(emprisesp, data.frame(ID=1:length(emprisesp)), match.ID=FALSE);
				
				######################################################
				# generating the buffer file : buffer_in_100m.shp 	 # (<<Generate Polygon>>)
				######################################################
				unified_shape_file = gUnaryUnion(spgeom = active_shape_file);
				buffer_in_100msp <- gBuffer(spgeom = unified_shape_file, width=-100);
				buffer_in_100m <- SpatialPolygonsDataFrame(buffer_in_100msp, data.frame(ID=1:length(buffer_in_100msp)), match.ID=FALSE);
				writeOGR(buffer_in_100m, layer='buffer_in_100m', output_folder, driver='ESRI Shapefile', overwrite_layer=TRUE);
				print(paste('file buffer_in_100m.shp has been created in',output_folder));
				print('-------------------------');
				
				######################################################
				# generating the grid file : land_use.shp 			 # (<<Generate Grid>>)
				######################################################
				grid_cell_size <- as.integer(xmlValue(xmlElementsByTagName(el = mapping_node, 'grid-cell-size')[[1]]));
				grid_cell_min_area <- (grid_cell_size * grid_cell_size) / 2;
				print('Generating the grid');
				mygrid <- makegrid(convex_hull, cellsize = grid_cell_size);
				mygridspoints <- SpatialPoints(mygrid, proj4string = CRS(proj4string(convex_hull)));
				mygridspixels <- SpatialPixels(mygridspoints[convex_hull,]);
				mygridspolygons <- as(mygridspixels, 'SpatialPolygons');
				mygridspolygons <- raster::intersect(mygridspolygons, active_shape_file);
				mygridshp <- disaggregate(mygridspolygons);
				mygridspolygons <- as(mygridshp, 'SpatialPolygons');
				
				# generating an ID for each land_use cell
				mygridshp$unit_id <- seq.int(nrow(mygridshp));
				##### complex function to return neighbouring cells #####
				get_my_first_father <- function(x){
					if(list_of_my_father[x] == x){	return (x);	}
					else{	return (get_my_first_father(list_of_my_father[x]));	}
				}
				
				# for each cell, we look for other cells who are supposed to merge with it (children)
				list_of_my_children <- vector("list", length(mygridspolygons));
				list_of_my_father <- seq.int(length(mygridspolygons));
				
				for(ix in(1:length(mygridspolygons))){	# process all land_use cells				
					#for each cell smaller than grid_cell_min_area, we merge it to its neighbor of the same district
					# grid_cell_min_area = 1/2 of a standard cell (grid_cell_size)
					if(mygridshp@polygons[[ix]]@area < grid_cell_min_area){
						my_district <- mygridshp@data[ix,'dist_code'];
						# all cells of my district
						my_district_cells <- mygridshp[mygridshp@data$dist_code == my_district,];
						# who are my neighbors (list of TRUE/FALSE)
						neighbor_cells <- gTouches(mygridspolygons[ix], my_district_cells, byid=TRUE);
						my_district_cells@data$is_neighbor = as.vector(neighbor_cells);
						# getting my neighbor cells
						my_neighbor_cells <- my_district_cells[my_district_cells@data$is_neighbor == TRUE,];
						# who are not already my children (supposed to be merged with me)
						my_neighbor_cells <- my_neighbor_cells[!my_neighbor_cells$unit_id %in% 
											unlist(lapply(list_of_my_children[[ix]], function(e) e$unit_id)),];
						# for each neighbor cell, we calculate the length of the boundaries
						if(length(my_neighbor_cells) > 0){
							line_length <- 0;
							for(lx in(1:length(my_neighbor_cells))){
								my_line <- rgeos::gIntersection(mygridshp[ix,], my_neighbor_cells[lx,], byid = TRUE);
								if(class(my_line) == 'SpatialLines'){
									new_line_length <- SpatialLinesLengths(my_line);
									if(new_line_length > line_length){
										selected_neighbor <- my_neighbor_cells[lx,];
										line_length <- new_line_length;
									}
								}
							}
							# getting the big father = the neighbor cell with the logest boundary
							my_father <- get_my_first_father(selected_neighbor$unit_id);
							# updating hierarchy lists to control who is to be merged with who
							list_of_my_father[ix] <- my_father;
							list_of_my_children[[my_father]] <- c(list_of_my_children[[my_father]], mygridshp[ix,]);
							# if I have children, they also goes to my father (we will be both be merged with my father)
							if(length(list_of_my_children[[mygridshp[ix,]$unit_id]]) > 0){
								list_of_my_children[[my_father]] <- c(list_of_my_children[[my_father]], 
																	  list_of_my_children[[mygridshp[ix,]$unit_id]]);
								list_of_my_children[mygridshp[ix,]$unit_id] <- list(NULL);
							}
						}					
					}
				}
				# merge appropriate spatial polygons (each cell with its father) (<<Merge>>)
				my_new_grid <- mygridshp[1,]; # to avoid raster::bind NULL issue (bind throws an error if one of the binded polygonSDF is empty)
				for(ix in(1:length(list_of_my_children))){
					if(length(list_of_my_children[[ix]]) > 0){
						new_polysp <- as(mygridshp[ix,], 'SpatialPolygons');
						for(lx in(1:length(list_of_my_children[[ix]]))){
							new_polysp <- gUnaryUnion(spgeom=union(new_polysp,list_of_my_children[[ix]][[lx]]));
						}
						new_polyspdf <- SpatialPolygonsDataFrame(new_polysp, mygridshp[ix,]@data, match.ID=FALSE);
						my_new_grid <- raster::bind(my_new_grid, new_polyspdf);	
					}
					else if(mygridshp@polygons[[ix]]@area >= grid_cell_min_area){
						my_new_grid <- raster::bind(my_new_grid, mygridshp[ix,]);
					}
				}
				mygridshp <- my_new_grid[-1,]; # to avoid raster::bind NULL issue // deleting the first (dummy) SDF
				mygridspolygons <- as(mygridshp, 'SpatialPolygons');
				
				# recreating unit_code (Natural, Urban, ...) for new cells (<<Intersect>>)
				#  N = 1, U = 2, AU = 4, A = 5, Us = 6, AUs = 7
				mygridshp$unit_code <- rep(0,nrow(mygridshp));
				mygridshp$unit_intersec <- rep(0,nrow(mygridshp));
				pluspolygons <- as(urban_plan, 'SpatialPolygons');
				for(ix in(1:length(pluspolygons))){
				  ppoly <- gBuffer(pluspolygons[ix], byid=TRUE, width=0)
					my_cells <- raster::intersect(mygridshp, ppoly) # my cells intersecting with each PLU polygon
					if (!is.null(my_cells)) {
						for(dx in(1:length(my_cells))){
							intersec_area <- area(my_cells[dx,]); # intersecting area between the cell and the polygon
							if(intersec_area > my_cells[dx,]$unit_intersec){ # if the current cells intersects more with another
																			# then update its unit_code (<<Topology>>)
								mygridshp@data[mygridshp@data$unit_id == my_cells[dx,]$unit_id, 'unit_intersec'] <- intersec_area;
								mygridshp@data[mygridshp@data$unit_id == my_cells[dx,]$unit_id, 'unit_code'] <- urban_plan[ix,]$unit_code;
							}
						}
					}
				}
				# unit_pop (calculating each cell population) (<<Aggregate>>)
				mygridshp$unit_pop <- rep(0,nrow(mygridshp));
				for(indx in(1:length(active_shape_file))){
					dist_gridshp <- raster::intersect(mygridshp, active_shape_file[indx,]);
					dist_blds <- raster::intersect(buildings, active_shape_file[indx,]);
					if(!is.null(dist_blds)){
						dist_total_area <- sum(area(dist_blds));
						dist_population <- as.integer(active_shape_file[indx,]$dist_pop);
						dist_gridshp_polys <- as(dist_gridshp, 'SpatialPolygons');
						for(ix in(1:length(dist_gridshp_polys))){
							cell_blds <- raster::intersect(dist_gridshp_polys[ix], dist_blds);
							if(!is.null(cell_blds) && length(cell_blds) > 0){
								cell_total_area <- sum(area(cell_blds));
								mygridshp@data[mygridshp@data$unit_id == dist_gridshp[ix,]$unit_id, 'unit_pop'] <-
												(cell_total_area / dist_total_area) * dist_population;
							}
						}
					}
				}
				# renaming and cleaning land_use attributes
				mygridshp@data$ID <- mygridshp@data$unit_id;
				mygridshp@data$unit_pop <- as.double(mygridshp@data$unit_pop);
				mygridshp@data$unit_code <- as.integer(mygridshp@data$unit_code);
				processed_atts <- c('ID','unit_code','dist_code','unit_pop');
				for(att_to_remove in names(mygridshp)){
					if(!att_to_remove %in% processed_atts){
						mygridshp@data[att_to_remove][[1]] <- NULL;
					}
				}
				# saving the grid to the shapefile
				writeOGR(mygridshp, layer='land_use', output_folder, driver='ESRI Shapefile', overwrite_layer=TRUE);
				print(paste('file land_use.shp has been created in',output_folder));
				print('-------------------------');
			}
			# saving the shape file
			writeOGR(shape_file, layer=output_file_without_ext, output_folder, driver='ESRI Shapefile', layer_options='RESIZE=YES', overwrite_layer=TRUE);
			print(paste('file',output_file_name,'has been created in',output_folder));
			print('-------------------------');
		}
		#############################
		# the file is an ascii file #
		#############################
		else if(grepl('.asc', input_file_name)){ # (<<Rename>>)
			print(paste(input_file_name,'..... OK (asc file)'));
			file.copy(paste(input_folder, input_file_name, sep='/'), paste(output_folder, output_file_name, sep='/'), overwrite=TRUE);
			print(paste(output_file_name,'has been created in',output_folder));
			print('-------------------------');
			# creating the convex_hull as the extent of the dem file
			if (output_file_name == "dem.asc") {
				emprisesp <- as(raster::extent(raster(paste(output_folder, "dem.asc", sep='/'))), "SpatialPolygons");
				proj4string(emprisesp) <- CRS('+init=epsg:2154');
				# fenerating and saving the convex_hull shapefile 
				convex_hull <- SpatialPolygonsDataFrame(emprisesp, data.frame(ID=1:length(emprisesp)), match.ID=FALSE);
				writeOGR(convex_hull, layer='convex_hull', output_folder, driver='ESRI Shapefile', overwrite_layer=TRUE);
				print(paste('file convex_hull.shp has been created in',output_folder));
				print('-------------------------');
			}
		}
	}else{ # the file does not exist in input_files folder
		warning(paste(input_file_name, '..... not found'));
	}
}

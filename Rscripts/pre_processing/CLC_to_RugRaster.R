
library('methods')
library('rgdal')
library('rgeos')
library('sp')
library('stringr')
library('raster')


shape_file <- readOGR(dsn = "rochefort_output_files", layer = "land_cover", verbose=FALSE);
ras <- raster(nrow=730, ncol=472, crs=projection(shape_file), ext=extent(shape_file), res=20)

strt <- rasterize(shape_file, ras, field=0)
strt[is.na(strt)] <- 0
writeRaster(strt, "start", format = "ascii", overwrite=TRUE);

# rug <- rasterize(shape_file, ras, field='ID');
# ids <- as.vector(as.numeric(as.character(shape_file$ID)))
# vals <- as.vector(as.numeric(as.character(shape_file$cover_type)))
# for(i in(1:length(ids))){
#   rug[rug == ids[i]] <- vals[i]
# }
# 
# rug[rug == 111]  <- 0.12
# rug[rug == 112]  <- 0.12
# rug[rug == 121]  <- 0.12
# rug[rug == 122]  <- 0.12
# rug[rug == 123]  <- 0.12
# rug[rug ==124]  <- 0.12
# rug[rug ==131]  <- 0.04
# rug[rug ==132]  <- 0.04
# rug[rug ==133]  <- 0.04
# rug[rug ==141]  <- 0.042
# rug[rug ==142]  <- 0.03
# rug[rug ==211]  <- 0.032
# rug[rug ==212]  <- 0.032
# rug[rug ==213]  <- 0.035
# rug[rug ==221]  <- 0.07
# rug[rug ==222]  <- 0.1
# rug[rug ==223]  <- 0.05
# rug[rug ==231]  <- 0.04
# rug[rug ==241]  <- 0.035
# rug[rug ==242]  <- 0.06
# rug[rug ==243]  <- 0.04
# rug[rug ==244]  <- 0.14
# rug[rug ==311]  <- 0.15
# rug[rug ==312]  <- 0.16
# rug[rug ==313]  <- 0.17
# rug[rug ==321]  <- 0.03
# rug[rug ==322]  <- 0.07
# rug[rug ==323]  <- 0.07
# rug[rug ==324]  <- 0.14
# rug[rug ==331]  <- 0.03
# rug[rug ==332]  <- 0.104
# rug[rug ==333]  <- 0.104
# rug[rug ==334]  <- 0.104
# rug[rug ==335]  <- 	0
# rug[rug ==411]  <- 0.055
# rug[rug ==412]  <- 0.08
# rug[rug ==421]  <- 0.055
# rug[rug ==422]  <- 0.055
# rug[rug ==423]  <- 0.025
# rug[rug ==511]  <- 0.025
# rug[rug ==512]  <- 0.025
# rug[rug ==521]  <- 0.025
# rug[rug ==522]  <- 0.025
# rug[rug ==523]  <- 0.02
# 
# 
# writeRaster(rug, "rugosity", format = "ascii", overwrite=TRUE)
# 

##ventiller la population dans les carreau SHP du modèle LittoSim
#Données INSEE sont disponible ici pour la france : https://frama.link/-77VPuLv
# Auteur : Etienne DELAY (unilim)

# note : ATTENTION FONCTIONNE POUR UNE COMMUNE, MAIS DOIT ËTRE RETRAVAILLER POUR +
rm(list = ls())

require("rgdal")

setwd("~/github/LittoSim_model/")

#Ouverture des données spatiale grace a gdal
plu_shp <- readOGR(dsn = "./includes/le_chateau/", layer = "chatok")
com_number <- as.numeric(as.character(unique(plu_shp@data$INSEE))) #un vecteur avec les numero de commune en temps que numeric

#Manipulation des données INSEE
insee <- read.csv("includes/insee/base-ic-evol-struct-pop-2012.csv",sep = ",",header = TRUE, skip = 5) ##Lecture des données INSEE
sel <- insee$COM %in% com_number #vecteur booleen qui conserve les communes présentes dans le shp
insee <- insee[sel,] #creation du data.frame avec les communes du shp
insee <- subset(insee, select = c("COM","LIBCOM","P12_POP")) #simplicitation du data frame avec 3 colonne

plu_shp@data$pop <- NULL
for( i in 1:length(com_number)){
  num_comi <- com_number[i]
  sel <- as.numeric(as.character(plu_shp@data$INSEE)) ==  num_comi & as.character(plu_shp@data$TYPEZONE) == "U"
  zone_u <- plu_shp[sel,]
  surf <- sum(plu_shp@data$Shape_Area)
  for(j in 1:length(plu_shp@data$OBJECTID)){
    if(as.character(plu_shp@data$TYPEZONE[j]) == "U"){
      plu_shp@data$pop[j] <- round(insee$P12_POP * plu_shp@data$Shape_Area[j] /surf, digits = 0)
    }else{
      plu_shp@data$pop[j] <- 0
    }
  }
}

writeOGR(plu_shp, dsn = "./includes/le_chateau/", layer = "chatok_pop", driver = "ESRI Shapefile")


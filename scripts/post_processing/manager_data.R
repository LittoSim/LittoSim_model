################################################
# LittoSIM - manager_data version du 17/06/2021
# @Authors: Ahmed Laatabi et compl�ments : C�cilia Pignon-Mussaud, Nicolas Marilleau
# This script allows you to generate different diagrams to analyze the results of a LittoSIM simulation/game session, after the workshop.
# This script is tested, and works for R version 3.5.3. et 3.6.3/ Ce script est testé, et fonctionne bien sous R, version 3.5.3. et 3.6.3


 
#################################################
# Le codage "utf-8" pour supporter les caractères de la langue française
options(encoding = "utf-8")

# Les packages nécessaires pour l'exécution du script manager
# Les packages sont installés s'ils le sont pas déjà
if (!require('ggplot2'))  { install.packages('ggplot2') }
if (!require('reshape2')) { install.packages('reshape2')}
if (!require('readr')) { install.packages('readr')}
if (!require('dplyr')) { install.packages('dplyr')}
if (!require('rgdal')) { install.packages('rgdal')} # gestion projections cartographiques
if (!require('raster')) { install.packages('raster')}
if (!require('sp')) { install.packages('sp')} # objets spatiaux
if (!require('scales')) { install.packages('scales')}
if (!require('ggspatial')) { install.packages('ggspatial')}
if (!require('sf')) { install.packages('sf')}
if (!require('cartography')) { install.packages('cartography')}
if (!require('rgeos')) { install.packages('rgeos')}
#if (!require('rgeos')) { install.packages("stringi")}
library(ggplot2)
library(reshape2)
library(readr)
library(dplyr)
library(rgdal)
library(raster)
library(sp)
library(scales)
library(ggspatial)
library(sf)
library(maptools)
library(cartography)
library(rgeos)
#library(stringi)

################################################################################################
#
#
#  CONFIGURATIONS
#
#
#
################################################################################################
# Les répertoires des fichiers (sorties de GAMA) à utiliser
# Le répertoire manager_data-X.xxxxxx généré pendant l'atelier, à récupérer de workspace/LittoSIM-GEN/includes/XXXXXX/, côté serveur.
# Le XXXXXX représente le nom de l'étude de cas
MANAGER_DATA <- "/Users/nicolas/Desktop/littosim/Camargue_Amelie/manager_data-1.575987155598E12/"
# Le répertoire des fichiers SHAPEFILES au lancement de LittoSIM
SHAPEFILES <- "/Users/nicolas/git/littosim_dev/LittoSim_model/includes/overflow_coast_h/shapefiles"





# La liste des noms (short names) et des codes INSEE des communes dans le même ordre
coms <- c("com-A","com-B","com-C","com-D")
insees <- c('17411','17093','17140','17385')
# Les noms des communes à afficher sur les graphes (dans le même ordre)
noms_communes <- c("com-A","com-B","com-C","com-D")


# Vérifier si le MANAGER_DATA existe ou non
if (!dir.exists(MANAGER_DATA)){
  stop(paste("Le répertoire des données d'entrée n'existe pas :", MANAGER_DATA))
}

# Vérifier si le SHAPEFILES existe ou non
if (!dir.exists(SHAPEFILES)){
  stop(paste("Le répertoire des données d'entrée n'existe pas :", SHAPEFILES))
}


# Créer le répertoire des graphs à générer: le dossier graphs_manager sera dans l'espace du travail
# Si le répertoire existe déjà, on le supprime (Sous Windows, R ne remplace pas les fichiers existants !)
unlink("graphs_manager/", recursive=T)
dir.create("graphs_manager", showWarnings = FALSE)
print(paste("Les graphes seront enregistrés dans le répertoire ",getwd(),"/graphs_manager",sep=""))

# Créer un répertoire pour les exports .csv
unlink("exports_csv/", recursive=T)
dir.create("exports_csv", showWarnings = FALSE)
print(paste("Les dataframe seront enregistrés dans le répertoire ",getwd(),"/exports_csv",sep=""))

################################################################################################
# Paramètres généraux
# Éviter de prendre les champs de type chaine de caractère comme des facteurs
options(stringsAsFactors = FALSE)
# Un tableau pour récupérer toutes les données des 4 communes
dd = data.frame()

# Lire les données de toutes les communes à partir du répertoire "csvs" du MANADER_DATA
# Les fichiers lus sont nommés d'après les 4 communes : NOMCOMMUNE.csv
# Le contenu des quatre fichiers est combiné dans une même table (data frame) "dd"
for (com in coms) {
  data <- read.csv(paste(MANAGER_DATA,"csvs/",com,".csv", sep=""), sep= ",", header=T)
  dd = rbind (dd, data)
}

# Remplacer les codes des communes par leur noms pour plus de visibilité
dd$district_code <- coms[match(dd$district_code, insees)]
dd$name_district <- noms_communes[match(dd$district_code, coms)]

# Factoriser les données numériques qui doivent être pris commes de facteurs et non pas comme des nombres
dd$num_round <- as.factor(dd$num_round)

# Generate a cvs file including all the evolutions of the game's actions /Générer un fichier cvs incluant tous les évolutions des actions du jeu 
write.csv(dd, "exports_csv/actions_game.csv", row.names =TRUE)

# Extraire le numéro du dernier tour qui est le numéro de la dernière ligne - 1 (on commence à partir du tour 0)
# La table dd contient les données des quatres communes, d'où la division sur 4 pour ne prendre que les données d'une commune
last_round <- (nrow(dd) / 4) - 1

################################################################################################
# Les tableaux des populations et des budgets à T0 (premier tour) (affichés à la console)
#
d0 <- dd[dd$num_round==0,]

print ("Population à T0:")
print(rbind(d0$district_code, d0$popul, paste(round(prop.table(d0$popul),3)*100,"%")))
print("---------------------------------------------")

print ("Budgets à T0:")
print(rbind(d0$district_code, d0$budget, paste(round(prop.table(d0$budget),3)*100,"%")))
print("---------------------------------------------")

################################################################################################
# Les tableaux d’évolution des populations et des budgets entre T0 et la fin de l’atelier (affichés à la console)
#
dlast <- dd[dd$num_round==last_round,]

print ("Taux d'évolution de la population à la fin du jeu:")
print(rbind(d0$district_code,paste(round((dlast$popul - d0$popul) / d0$popul,3)*100,"%")))
print("---------------------------------------------")

print ("Taux d'évolution du budget à la fin du jeu:")
print(rbind(d0$district_code,paste(round((dlast$budget - d0$budget) / d0$budget,3)*100,"%")))
print("---------------------------------------------")

write.csv(d0, "exports_csv/population_budgets_T0_end.csv", row.names =TRUE)

################################################################################################

# Les graphes d'évolution enregistrés sous format png dans le répertoire "graphs_manager"
# La résolution et les dimensions des graphs peuvent être modifiés en changent les paramètres
# width, height et res de png()
################################################################################################
#ajouter lignes verticales pour présenter les tours où une submersion a eu lieu 
list_submersion <- list.files(path = paste(MANAGER_DATA, "flood_results",sep=""), pattern = "sub-R.*\\.csv$", full.names = F)
library(stringr)
round_submersion <- str_match(list_submersion, "sub-R\\s*(.*?)\\s*.csv")
#colnames(rsub)[2] = "round_submersion"
rsub=data.frame(round_submersion)
round_submersion<-sort(as.numeric(rsub[,2])) 
round_submersion <- ordered(round_submersion,
                            levels = round_submersion ); 									 													

# Création du graph avec les numéros de tours sur l'axe des X, la population sur l'axe des Y,
# puis grouper et colorer selon la commune

df_95ci <- data.frame(y_values=round_submersion )
maxX <- max(as.numeric(rsub[,2]))
seqind <- as.character(seq(0,maxX,1))


p1 <- ggplot(data=dd, mapping=aes(x=num_round, y=popul,color=name_district, group=district_name))  +
  geom_line(mapping=aes(colour=district_name),size=2) +   scale_color_discrete(name = "Communes") +
  geom_vline(data= df_95ci, mapping=aes(xintercept=y_values, size= "0.5"),  linetype="dashed", colour = "blue") +
  scale_color_hue("Communes", guide=guide_legend(order=1)) +
  scale_size_manual("Etapes", values=rep(1,4),
                    guide=guide_legend(override.aes = list(colour=c("blue"),order=2)),
                    labels=c("Submersion")) +
  labs(x = "Tour", y = "Population") + scale_x_discrete(name ="Tour", limits=seqind )
  
  png("graphs_manager/populations.png", width = 1000, height = 800, res=144)
print(p1)
# fermer la redirection de la sortie pour enregistrer l'image
dev.off()

#
# De même, on crée le graph de l'evolution des budgets
#
p2 <- ggplot(data=dd, mapping=aes(x=num_round, y=budget,color=name_district, group=district_name))  +
  geom_line(mapping=aes(colour=district_name),size=2) +   scale_color_discrete(name = "Communes") +
  geom_vline(data= df_95ci, mapping=aes(xintercept=y_values, size= "0.5"),  linetype="dashed", colour = "blue") +
  # geom_vline(data= df_99ci, mapping=aes(xintercept=y_values, size= "99% CI"), colour="darkred") +
  scale_color_hue("Communes", guide=guide_legend(order=1)) +
  scale_size_manual("Etapes", values=rep(1,4),
                    guide=guide_legend(override.aes = list(colour=c("blue"),order=2)),
                    labels=c("Submersion", "CI of 99%")) +
  labs(x = "Tour", y = "Budget") + scale_x_discrete(name ="Tour", limits=seqind ) 
png("graphs_manager/budgets.png", width = 1000, height = 800, res=144)
print(p2)
dev.off()


################################################################################################
# Composition des budgets en total et par tour
#
# les colonnes à considérer 
buds <- dd[,c("name_district", "num_round", "received_tax","actions_cost","given_money",
              "taken_money", "transferred_money","levers_costs")]

# On enlève le tour 0 où il n'y a jamais de transactions
# ligne à ajouter ci-dessous, si on veut supprimer le 0 où il n'y a jamais de transactions
#buds <- buds[buds$num_round != 0,]

# construire une tableau long à base du couple "nom commune" et "numéro de tour"
buds <- melt(buds, id = c("name_district","num_round"))

# les labels et les couleurs à utiliser sur les graphes
budget_labels <- c("Impôts reçus","Montants des actions","Subventions de l’Agence du risque",
                   "Prélevements de l’Agence du risque","Transfert entre communes","Leviers automatiques")
budget_colors <- c("received_tax"="gold","actions_cost"="darkgray","given_money"=
                     "darkgreen","taken_money"="darkred","transferred_money"="darkblue", "levers_costs"="purple")

# Générer un fichier cvs incluant les budgets par tour
write.csv(buds, "exports_csv/budgets_round.csv", row.names =TRUE)

# Composition du budget par tour
# les bars sont remplis selon la variable "variable" générée par melt
p3 <- ggplot(data=buds, mapping=aes(x=num_round, y=value, fill=variable))  +
  geom_bar(stat="identity",  position=position_stack(reverse = TRUE))  +
  facet_wrap(~name_district, scales="free") +
  geom_vline(data= df_95ci, mapping=aes(xintercept=y_values, size= "0.5"),  linetype="dashed", colour = "blue") +
  scale_color_hue("Communes", guide=guide_legend(order=1)) +
  scale_size_manual("Etapes", values=rep(1,4),
                    guide=guide_legend(override.aes = list(colour=c("blue"),order=2)),
                    labels=c("Submersion")) +
  labs(x = "Tour", y = "Budget") + scale_x_discrete(name ="Tour", limits=seqind ) +
  png("graphs_manager/budget_round.png", width = 1200, height = 800, res=144)
print(p3)
dev.off()

#
# Composition du budget par tour en pourcentage
p4 <- ggplot(buds, aes(x=num_round, y=value, fill=variable)) + 
  geom_bar(stat="identity",  position=position_fill(reverse = TRUE))  +
  facet_wrap(~name_district, scales="free") + scale_y_continuous(labels = scales::percent) +
  geom_vline(data= df_95ci, mapping=aes(xintercept=y_values, size= "0.5"),  linetype="dashed", colour = "blue") +
  scale_color_hue("Communes", guide=guide_legend(order=1)) +
  scale_size_manual("Etapes", values=rep(1,4),
                    guide=guide_legend(override.aes = list(colour=c("blue"),order=2)),
                    labels=c("Submersion")) +
  scale_fill_manual("Transaction", values=budget_colors,
                    labels=budget_labels) + labs(x = "Tour", y = "Montant en pourcentage") + scale_x_discrete(name ="Tour", limits=seqind ) +
  png("graphs_manager/budget_round_percent.png", width = 1200, height = 800, res=144)
print(p4)
dev.off()
#
# Composition du budget total
# calculer la somme des budgets selon le type de transaction pour chaque commune
buds <- aggregate(buds$value, by=list(buds$name_district,buds$variable), FUN=sum)
names(buds) <- c("name_district", "transaction","amount")
p5 <- ggplot(buds, aes(x=name_district, y=amount, fill=transaction)) +
  geom_bar(stat='identity', position=position_stack(reverse = TRUE))  +
  scale_fill_manual("Transaction", values=budget_colors, labels=budget_labels) +
  labs(x = "Commune", y = "Montant") +
  # forcer ggplot à afficher le nombre en entier au lieu de la notation scientifique
  #scale_y_continuous(labels = scales::comma)
  scale_y_continuous(labels = scales::unit_format(
  unit = "", 
  #scale = 1e-3,
  accuracy = 1))

png("graphs_manager/budget_total.png", width = 1000, height = 800, res=144)
print(p5)
dev.off()

#
# Composition du budget total en pourcentage
p6 <- ggplot(buds, aes(x=name_district, y=amount, fill=transaction)) +
  geom_bar(stat='identity', position=position_fill(reverse = TRUE))  +
  scale_fill_manual("Transaction", values=budget_colors, labels=budget_labels) +
  labs(x = "Commune", y = "Montant en pourcentage") +
  scale_y_continuous(labels = scales::percent)

png("graphs_manager/budget_total_percent.png", width = 1000, height = 800, res=144)
print(p6)
dev.off()

################################################################################################
# Évolution des défenses côtières (digues et dunes)
#

# dikes / digues
codef <- data.frame()
for (ix in (1:nrow(dd))) {
  # calculate the proportion of dikes in good condition in relation to all dikes / Calculer la proportion des digues en bon état par rapport à toutes les digues
  val <- round(( (dd$last.length_dikes_good.[ix] * dd$last.mean_alt_dikes_good.[ix]) / (
    (dd$last.length_dikes_good.[ix] * dd$last.mean_alt_dikes_good.[ix])+
      (dd$last.length_dikes_medium.[ix] * dd$last.mean_alt_dikes_medium.[ix]) +
      (dd$last.length_dikes_bad.[ix] * dd$last.mean_alt_dikes_bad.[ix]) )) ,2)
  # si val est nulle (pas de digues pour la commune), mettre la valeur à 0
  val <- ifelse(is.nan(val), 0, val)
  codef = rbind (codef, c(dd[ix,]$name_district,as.character(dd[ix,]$num_round), val))
}

names(codef) <- c("district","round","val")
codef$round <- as.factor(codef$round)
codef$val <- as.double(codef$val)

# Generate a cvs file including dikes / Générer un fichier cvs incluant les digues
write.csv(codef, "exports_csv/dikes.csv", row.names =TRUE)

# Order the table by turn number / ordonner la table selon le numéro de tour
codef = codef[order(codef$round),]

p7 <- ggplot(codef, aes(x=round, y=val, color=district, group=district)) +
  geom_line(size=2) + scale_y_continuous(labels = scales::percent) +
  geom_vline(data= df_95ci, mapping=aes(xintercept=y_values, size= "0.5"),  linetype="dashed", colour = "blue") +
  scale_color_hue("Communes", guide=guide_legend(order=1)) +
  scale_size_manual("Etapes", values=rep(1,4),
                    guide=guide_legend(override.aes = list(colour=c("blue"),order=2)),
                    labels=c("Submersion")) +
   labs(x = "Tour", y = "Pourcentage de digues en bon état") +
  scale_x_discrete(name ="Tour", limits=seqind ) +
png("graphs_manager/dikes.png", width = 1000, height = 800, res=144)
print(p7)
dev.off()

#
#
# dunes
#
codef <- data.frame()
for (ix in (1:nrow(dd))) {
  # Calculer la proportion des dunes en bon état par rapport à toutes les dunes
  val <- round(( (dd$last.length_dunes_good.[ix] * dd$last.mean_alt_dunes_good.[ix]) / (
    (dd$last.length_dunes_good.[ix] * dd$last.mean_alt_dunes_good.[ix])+
      (dd$last.length_dunes_medium.[ix] * dd$last.mean_alt_dunes_medium.[ix]) +
      (dd$last.length_dunes_bad.[ix] * dd$last.mean_alt_dunes_bad.[ix]) )) ,2)
  # si val est nulle (pas de dunes pour la commune), mettre la valeur à 0
  val <- ifelse(is.nan(val), 0, val)
  codef = rbind (codef, c(dd[ix,]$name_district,as.character(dd[ix,]$num_round), val))
}

names(codef) <- c("district","round","val")
codef$round <- as.factor(codef$round)
codef$val <- as.double(codef$val)

# Generate a cvs file including dunes / Générer un fichier cvs incluant les dunes
write.csv(codef, "exports_csv/dunes.csv", row.names =TRUE)

# ordonner la table selon le numéro de tour
codef = codef[order(codef$round),]

p8 <- ggplot(codef, aes(x=round, y=val, color=district, group=district)) +
  geom_line(size=2) + scale_y_continuous(labels = scales::percent) +
  geom_vline(data= df_95ci, mapping=aes(xintercept=y_values, size= "0.5"),  linetype="dashed", colour = "blue") +
  scale_color_hue("Communes", guide=guide_legend(order=1)) +
  scale_size_manual("Etapes", values=rep(1,4),
                    guide=guide_legend(override.aes = list(colour=c("blue"),order=2)),
                    labels=c("Submersion")) +
  labs(x = "Tour", y = "Pourcentage de dunes en bon état") +
  scale_x_discrete(name ="Tour", limits=seqind ) +
  png("graphs_manager/dunes.png", width = 1000, height = 800, res=144)
print(p8)
dev.off()


################################################################################################
# Évolution de l’utilisation du sol
#

lus <- data.frame(matrix(ncol = 8, nrow = 0)) 
for (com in coms){
  data <- dd[dd$district_code==com,]
  # l'évolution de l'utilisation du sol est à 0 au tour 0
  vec <- c(0,0,0,0,0,0,0)
  lus <-  rbind (lus, c(com,vec))
  # pour chaque tour, on calcule le différentiel de la surface de chaque type LU par rapport au
  # tour précédent
  for (ix in (2:nrow(data))){
    vec[1] <- vec[1] + data$N_area[ix] - data$N_area[ix-1]
    vec[2] <- vec[2] + data$U_area[ix] - data$U_area[ix-1]
    vec[3] <- vec[3] + data$Udense_area[ix] - data$Udense_area[ix-1]
    vec[4] <- vec[4] + data$Us_area[ix] - data$Us_area[ix-1]
    vec[5] <- vec[5] + data$Usdense_area[ix] - data$Usdense_area[ix-1]
    vec[6] <- vec[6] + data$A_area[ix] - data$A_area[ix-1]
    lus <- rbind (lus, c(com,as.character(data[ix,]$num_round),vec))
  }
}
# nommer les colonnes
colnames(lus) <- c("district_name","num_round","nn","uu","udense","us","usdense","aa")
# convertir les colonnes de 3 à 8 au type numérique
lus[,3:8] <- lapply(lus[,3:8], as.integer)
lus <- melt (lus, id = c("district_name","num_round"))

lus$district_name <- noms_communes[match(lus$district_name, coms)]

# Generate a cvs file including evolution of land use / Générer un fichier cvs incluant l'évolution de l'occupation du sol
write.csv(lus, "exports_csv/landuse.csv", row.names =TRUE)


p9 <- ggplot(lus) +
  geom_line(aes(x=num_round, y = value, group=variable, color=variable), size=1.25) +
  facet_wrap(~district_name, scales = "free_y") +
  scale_color_manual(values=c("nn"="darkgreen","uu"="darkgray","udense"="black","us"="blue",
                              "usdense"="darkblue","aa"="orange"),
                     labels= c("Naturel", "Urbain", "Urbain dense","Urbain adapté","Urbain adapté dense","Agricole")) +
  geom_vline(data= df_95ci, mapping=aes(xintercept=y_values, size= "0.5"),  linetype="dashed", colour = "blue") +
  scale_color_hue("Communes", guide=guide_legend(order=1)) +
  scale_size_manual("Etapes", values=rep(1,4),
                    guide=guide_legend(override.aes = list(colour=c("blue"),order=2)),
                    labels=c("Submersion")) +
  labs(x = "Tour", y = "évolution du landuse en %") +
  scale_x_discrete(name ="Tour", limits=seqind ) +
png("graphs_manager/landuse.png", width = 1000, height = 800, res=144)
print(p9)
dev.off()


## evolution landuse en anglais
p9b <- ggplot(lus) +
 # geom_line(aes(x=num_round, y = value, group=variable, color=variable), size=1.25) +
  geom_line(aes(x=num_round, y = value, group=variable, color=variable), size=1.25) +
  
  facet_wrap(~district_name, scales = "free_y") +
  scale_color_manual(values=c("nn"="darkgreen","uu"="darkgray","udense"="black","us"="blue",
                              "usdense"="darkblue","aa"="orange"),
                     labels= c("Natural area", " Urban area", "Dense urban area","Urban adapted","Dense urban adapted","Agricultural area")) +
  geom_vline(data= df_95ci, mapping=aes(xintercept=y_values, size= "0.5"),  linetype="dashed", colour = "blue") +
  scale_color_hue("Communes", guide=guide_legend(order=1)) +
  scale_size_manual("Etapes", values=rep(1,4),
                    guide=guide_legend(override.aes = list(colour=c("blue"),order=2)),
                    labels=c("Submersion")) +
  labs(x = "Game rounds", y = "Land use evolution (in ha)", color="Type")+
  scale_x_discrete(name ="Tour", limits=seqind ) +
  png("graphs_manager/landuse_en.png", width = 1000, height = 800, res=144)
print(p9b)
dev.off()

################################################################################################
# Graphs de submersion
# Un graph compilant, hectares submergés par commune, par type PLU et  par tour de submersion
data = data.frame()

# lire tous les fichiers sub-RX.csv du repertoire flood_results
# ces fichiers contient les résultats des submersions par tour, type PLU, et par niveau
csvs <- list.files(path = paste(MANAGER_DATA,"flood_results",sep=""), pattern = "sub-R.*\\.csv$", full.names = T)
for (fichier in csvs) {
  d <- read.csv(fichier, sep= ";", header=T)
  data = rbind (data, d)
}
names(data) <- c("num_round","district_name","sub_level","uu","us","udense","au","aa","nn")

# on choisit les colonnes à utiliser, ici on va omettre le type AU "au"
data <- data[,c("num_round","district_name","sub_level","uu","us","udense","aa","nn")]

data$num_round <- as.factor(data$num_round)
data$sub_level <- as.factor(data$sub_level)

# calculer le total pour les colonnes en question
data$tt <- rowSums(data[,c("uu","us","udense","aa","nn")])

# renseigner le/les nom/noms de/des la commune(s) à afficher, ou commenter la ligne pour afficher toutes les communes
#data <- subset(data, district_name %in% c("com-A","com-B"))

data <- melt(data, id = c("num_round","district_name","sub_level"))
data$sub_level = factor(data$sub_level,levels(data$sub_level)[c(3,2,1)])

# renommer les labels de la légende, on commente le AU
plu_types <- as_labeller(c("uu"="Urbain","us"="Urbain adapté","udense"="Urbain dense",
                           #"au"="Autorized U",
                           "aa"="Agricole","nn"="Naturel","tt"="Total"))

data$district_name <- noms_communes[match(data$district_name, coms)]

## graph avec axe y variable/free
p <- ggplot(data, aes(fill=sub_level, y=value, x=num_round))+
  geom_bar(stat="identity") +
  facet_wrap(variable~district_name, scales = 'free', ncol= 4,
             labeller = labeller(variable = plu_types)) +
  scale_fill_manual("Level", values=c("1"="lightblue","2"="blue","3"="darkblue"),
                    labels=c("> 1m","[0.5,1m]","< 0.5m")) +
  labs(x = "Tour", y = "", fill="Hauteur d'eau")

png("graphs_manager/graph_flood_1.png", width = 2500, height = 2000, res = 300)
print(p)
dev.off()
  


##################################
## Un graph par commune (courbes) 
## exemple pour Com-A
p10b <- ggplot(data[data$district_name=="com-A",], aes(x=num_round, y=value, color=sub_level, group=sub_level)) +
  geom_line(size=1) +
  facet_wrap(district_name~variable, scales = "free",
             labeller = labeller(variable = plu_types)) +
  scale_color_manual("Hauteurs d'eau", values=c("1"="lightblue","2"="blue","3"="darkblue"),
                     labels=c("> 1m","[0.5,1m]","< 0.5m")) +
  labs(x = "Tour de submersion", y = "", fill="Hauteurs d'eau")
png("graphs_manager/graph_sub_com-A.png", width = 2500, height = 2000, res = 300)
print(p10b)
dev.off()

################################################################################################
# Carte de submersion
#

# paramètres d'affichage de la carte Land_Use
lu_names <- c("N","U","Ui","AU","A","Us","AUs");
# dans le même ordre que lu_names
lu_colors <- c("darkgreen","gray","","yellow","orange","magenta","purple")

# codef_colors et codef_status dans le même ordre
codef_colors <- c("green","gold","red")
codef_status <- c("GOOD","MEDIUM","BAD")

# pop_class et pop_colors dans le même ordre
pop_class <- c("EMPTY","POP_VERY_LOW_DENSITY","LOW_DENSITY","MEDIUM_DENSITY","DENSE")
pop_colors <- c("white",rev(gray.colors(4)))
flood_cols <- c("lightblue","blue","darkblue")


# lire les fichiers de submersion et les shapefiles du tour N
# changer le numéro du tour selon la submersion voulue. Pour chaque submersion, le dossier est nommé
# avec le numéro du tour correspondant N results_RN_xxxxxxxxn
# 
#  
num_round <- 4

# le fichier res-R8.max représente le fichier .max (lisflood) de la 3ème submersion correspondant au tour 7 du jeu
# à copier dans le dossier flood_results à partir du répertoire correspondant à la submersion en question 
# les résultats des submersions sont dans includes/XXXX/floodfiles/results_RN_xxxxx. Ne pas oublier de renommer les fichiers
# copiés (res.max --> res-R8.max)
subm <- raster(paste(MANAGER_DATA,"flood_results/res-R5.max",sep=""))
crs(subm) <- '+init=epsg:2154';


# lire les fichiers land use et defenses côtes du tour indiqué : "num_round"
# la lecture des deux fichiers engendrent deux warnings (Z-dimension), mais c'est à negliger car ils n'affectent pas les données
#land_use <- readOGR(dsn = paste(MANAGER_DATA,"shapes",sep=""), layer = paste("Land_Use_",num_round,sep=""), verbose=FALSE);
land_use <- spTransform(land_use, CRS('+init=epsg:2154'));
#codefs <- readOGR(dsn = paste(MANAGER_DATA,"shapes",sep=""), layer = paste("Coastal_Defense_",num_round,sep=""), verbose=FALSE);
codefs <- spTransform(codefs, CRS('+init=epsg:2154'));

# replacement de valeurs type par l'épaisseur voulu
codefs[codefs$type == "DIKE","type"] <- 2
codefs[codefs$type == "DUNE","type"] <- 4
codefs$type <- as.integer(codefs$type)

# prendre uniquement la submersion dans les zones en jeu
flood <- raster::intersect(subm, land_use)
flood <- mask(flood, land_use)
flood[flood==0] <- NA

# afficher les districts
districts <- shapefile(file.path(SHAPEFILES,"districts.shp"))
#districts <- readOGR(file.path(SHAPEFILES,"districts.shp"))
districts <- spTransform(districts, CRS('+init=epsg:2154'));


# La carte sans la submersion
png("graphs_manager/map_no_sub.png", width = 1000, height = 1000, res=144)
# spécifier une marge de 7 en bas (bottom)
par(oma = c(7, 0, 0, 0))
# on fait un premier plot du raster pour prendre son emprise
# on affiche le raster sans le cadre, sans les axes (coordonnées) et sans la légende par défaut
plot(flood,axes=F,box=F,legend=F)

# afficher les cellules non urbaines avec les couleurs 
noturbs <- land_use[land_use$lu_code != 2,]
plot(noturbs, col=lu_colors[noturbs$lu_code], add=T)

# afficher les cellules urbaines colorées selon la densité de population
urbs <- land_use[land_use$lu_code == 2,]
plot(urbs, col=pop_colors[match(urbs$density_cl,pop_class)], add=T)

# afficher les districts
districts4 <- districts[districts$player_id != 0,]
districts4 <- spTransform(districts4, CRS('+init=epsg:2154'))
plot(districts4, border="grey", lty=1, lwd=2, add=TRUE)

# afficher les défenses cotières colorés selon l'état avec un épaisseur (lwd) selon le type
plot(codefs, lwd= codefs$type, col=codef_colors[match(codefs$status,codef_status)], add=T)

# ajouter les légendes
par(xpd=TRUE) # autoriser l'affichage des légendes en dehors du graphe
legend("bottomleft", legend="districts", col="grey", lwd=2, horiz=TRUE, inset=c(0,-0.13), bty="n")
legend("bottom", legend=c("Digue","Dune"), lwd=c(2,4), inset=c(0,-0.17), bty="n")
legend("bottomright", legend=c("Bon","Moyen","Dégradé"), col=codef_colors, lwd=2, inset=c(0,-0.21), bty="n")
legend("bottom", legend=c("N","U","AU","A","Us","AUs"), fill=c("darkgreen","gray","yellow","orange","blue","magenta"),
       horiz=TRUE, inset=c(0,-0.31), bty="n")
# Ajout des titres, sources , north
layoutLayer(title = "Map without submersion", 
            #author = "LittoSIM ©", 
            sources = "Sources : LittoSIM ©", frame = TRUE, col = NA, 
            scale = NULL,coltitle = "black",
            north = TRUE) 
# Ajout des étiquettes : ATTENTION à bien vérifier l'ordre des étiquettes
districts4$label_names <- c("com-A","com-D","com-C", "com-B")
labelLayer(x = districts4, txt = "label_names", col= "black", cex = 0.7, font = 4,halo = TRUE, bg = "white", r = 0.1,overlap = FALSE, show.lines = FALSE)
# échelle
barscale(size=1,lwd = 1.5,cex = 0.6,pos = "bottomright",style = "pretty",unit = "km")
dev.off()

#
# La carte avec la submersion
#
png("graphs_manager/map_sub.png", width = 1000, height = 1000, res=144)
par(oma = c(7, 0, 0, 0))

# on fait un premier plot du raster pour prendre son emprise
# on affiche le raster sans le cadre, sans les axes (coordonnées) et sans la légende par défaut
plot(flood, alpha=0.4, axes=F,box=F,legend=F)

# afficher les cellules non urbaines avec les couleurs 
noturbs <- land_use[land_use$lu_code != 2,]
plot(noturbs, col=lu_colors[noturbs$lu_code], add=T)

# afficher les cellules urbaines colorées selon la densité de population
urbs <- land_use[land_use$lu_code == 2,]
plot(urbs, col=pop_colors[match(urbs$density_cl,pop_class)], add=T)

# afficher les districts
districts4 <- districts[districts$player_id != 0,]
plot(districts4, border="grey", lty=1, lwd=2, add=TRUE)

# paramètrer la légende : 0, 0.5, 1
breakpoints <- c(0,0.5,1,round(max(flood[!is.na(flood)]),2))
# afficher la légende bleue
plot(flood,breaks=breakpoints,col=flood_cols, legend=F, add=T)

# afficher les défenses cotières colorés selon l'état avec un épaisseur (lwd) selon le type
plot(codefs, lwd= codefs$type, col=codef_colors[match(codefs$status,codef_status)], add=T)

# ajouter les légendes
par(xpd=TRUE)
legend("bottomleft", legend="districts", col="grey", lwd=2, horiz=TRUE, inset=c(0.4,-0.21), bty="n")
legend("bottomleft", legend=c("< 0.5m","0.5-1m","> 1m"), fill=flood_cols, inset=c(0,-0.21),bty="n")
legend("bottom", legend=c("Digue","Dune"), lwd=c(2,4), inset=c(0,-0.17), bty="n")
legend("bottomright", legend=c("Bon","Moyen","Dégradé"), col=codef_colors, lwd=2, inset=c(0,-0.21), bty="n")
legend("bottom", legend=c("N","U","AU","A","Us","AUs"), fill=c("darkgreen","gray","yellow","orange","blue","magenta"),
       horiz=TRUE, inset=c(0,-0.31), bty="n")
# Ajout des titres, sources , north
layoutLayer(title = "Map with submersion", 
            #author = "LittoSIM ©", 
            sources = "Sources : LittoSIM ©", frame = TRUE, col = NA, 
            scale = NULL,coltitle = "black",
            north = TRUE) 
# Ajout des étiquettes : ATTENTION à bien vérifier l'ordre des étiquettes
districts4$label_names <- c("com-A","com-D","com-C", "com-B")
labelLayer(x = districts4, txt = "label_names", col= "black", cex = 0.7, font = 4,halo = TRUE, bg = "white", r = 0.1,overlap = FALSE, show.lines = FALSE)
# échelle
barscale(size=1,lwd = 1.5,cex = 0.6,pos = "bottomright",style = "pretty",unit = "km")
dev.off()

###############################################
## La carte landuse au démarrage, intial 
png("graphs_manager/map_landuse_init_en.png", width = 1000, height = 830, res=144)
par(oma = c(7, 0, 0, 0))

# paramètres d'affichage de la carte Land_Use
lu_names <- c("N","U","Ui","AU","A","Us","AUs");
# dans le même ordre que lu_names
lu_colors <- c("darkgreen","gray","","yellow","orange","magenta","purple")

# codef_colors et codef_status dans le même ordre
codef_colors <- c("green","gold","red")
codef_status <- c("GOOD","MEDIUM","BAD")

# pop_class et pop_colors dans le même ordre
pop_class <- c("EMPTY","POP_VERY_LOW_DENSITY","LOW_DENSITY","MEDIUM_DENSITY","DENSE")
pop_colors <- c("white",rev(gray.colors(4)))

# lire les fichiers land use 0 (état initial)
# la lecture du fichier engendre un warning (Z-dimension), mais c'est à negliger car il n'affecte pas les données
num_round <- 0 

land_use <- readOGR(dsn = paste(MANAGER_DATA,"shapes",sep=""), layer = paste("Land_Use_",num_round,sep=""), verbose=FALSE);
land_use <- spTransform(land_use, CRS('+init=epsg:2154'));

plot(land_use,axes=F,box=F,legend=F)

# afficher les cellules non urbaines avec les couleurs 
noturbs <- land_use[land_use$lu_code != 2,]
plot(noturbs, col=lu_colors[noturbs$lu_code], add=T)

# afficher les cellules urbaines colorées selon la densité de population
urbs <- land_use[land_use$lu_code == 2,]
plot(urbs, col=pop_colors[match(urbs$density_cl,pop_class)], add=T)

# afficher les districts
districts4 <- districts[districts$player_id != 0,]
plot(districts4, border="grey", lty=1, lwd=2, add=TRUE)

# afficher les défenses cotières colorés selon l'état avec un épaisseur (lwd) selon le type
plot(codefs, lwd= codefs$type, col=codef_colors[match(codefs$status,codef_status)], add=T)

# ajouter les légendes
par(xpd=TRUE) # autoriser l'affichage des légendes en dehors du graphe
legend("bottomleft", cex = 0.8, legend="Districts", col="grey", lwd=2, horiz=TRUE, inset=c(-0.1,-0.13), bty="n")
legend("bottomleft", cex = 0.8, legend=c("Dike","Dune"), lwd=c(2,4), inset=c(0.3,-0.17), bty="n")
legend("bottomright", cex = 0.8, legend=c("Good","Medium","Damaged"), col=codef_colors, lwd=2, inset=c(0.1,-0.21), bty="n")
legend("bottomleft", cex = 0.8, legend="Urban density", horiz=TRUE, inset=c(-0.1,-0.28), bty="n")
legend("bottomleft", cex = 0.8, legend=c("Very Low", "Low","Medium", "Dense"), fill=c(rev(gray.colors(4))), horiz=TRUE, inset=c(0.2,-0.28), bty="n")
#legend("bottomright", cex = 0.8, legend=c("Empty", "Very Low", "Low","Medium", "Dense"), fill=c("white",rev(gray.colors(4))), horiz=TRUE, inset=c(0,-0.27), bty="n")
#legend("bottomleft", cex = 0.8, legend="Land use", horiz=TRUE, inset=c(0.05,-0.35), bty="n")
legend("bottomleft", cex = 0.8, legend=c("N : Natural area","AU : Authorized for urbanization","A : Agricultural area"), fill=c("darkgreen","yellow","orange"), horiz=TRUE, inset=c(-0.1,-0.36), bty="n")
legend("bottomleft", cex = 0.8, legend=c("Us : adapted habitat housing","AUs : to be adapted"), fill=c("blue","magenta"), horiz=TRUE, inset=c(-0.1,-0.44), bty="n")

# Ajout des titres, sources , north
layoutLayer(title = "", 
            #author = "LittoSIM ©", 
            sources = "Sources : LittoSIM ©", frame = TRUE, col = NA, 
            scale = NULL,coltitle = "black",
            north = TRUE) 
# Ajout des étiquettes : ATTENTION à bien vérifier l'ordre des étiquettes
districts4$label_names <- c("com-A","com-D","com-C", "com-B")
labelLayer(x = districts4, txt = "label_names", col= "black", cex = 0.7, font = 4,halo = TRUE, bg = "white", r = 0.1,overlap = FALSE, show.lines = FALSE)
# échelle
barscale(size=1,lwd = 1.5,cex = 0.6,pos = "bottomright",style = "pretty",unit = "km")
dev.off()

#############################################################################
## La carte des espaces non contraints = espaces non impactés par les espaces protégés (spa) et le PPR (rpp)
## Il est à noter que R gère mal les "donuts', "trous" des entités de type polygones. Par exemple, cela peut être le cas pour le PPR.
png("graphs_manager/restricted_space.png", width = 1200, height = 1000, res=144)
par(oma = c(7, 0, 0, 0))
# paramètres d'affichage de la carte Land_Use
#lu_names <- c("N","U","Ui","AU","A","Us","AUs");
# dans le même ordre que lu_names
#lu_colors <- c("darkgreen","gray","","yellow","orange","magenta","purple")
# pop_class et pop_colors dans le même ordre
pop_class <- c("EMPTY","POP_VERY_LOW_DENSITY","LOW_DENSITY","MEDIUM_DENSITY","DENSE")
pop_colors <- c("white",rev(gray.colors(4)))
# affichage transparence ou hachures
spa_colors <- c("green")
#rpp_colors <- c("blue")
# rpp_colors <- c("blue", density = 20, angle = 45,
#                 border = 2, col = NA, lty = par("lty"))
rpp_colors <- c("blue", density = 20, angle = 45,
                border = 10, col = "blue", lty = par("lty"))


# lire les fichiers land use 0 (état initial)
# la lecture du fichier engendre un warning (Z-dimension), mais c'est à negliger car ils n'affectent pas les données
num_round <- 0
land_use <- readOGR(dsn = paste(MANAGER_DATA,"shapes",sep=""), layer = paste("Land_Use_",num_round,sep=""), verbose=FALSE);
land_use <- spTransform(land_use, CRS('+init=epsg:2154'));
plot(land_use,axes=F,box=F,legend=F)

# afficher les cellules urbaines colorées selon la densité de population
urbs <- land_use[land_use$lu_code == 2,]
plot(urbs, col=pop_colors[match(urbs$density_cl,pop_class)], add=T)

# lire les fichiers relatifs aux contraintes
# afficher les zones protégées
spa <- shapefile(file.path(SHAPEFILES,"spa.shp"))
spa <- spTransform(spa, CRS('+init=epsg:2154'))
spa <- gBuffer(spa, byid=TRUE, width=0) # Ajout
spa <- gUnaryUnion(spgeom = spa)# Ajout

# afficher le PPR
rpp <- shapefile(file.path(SHAPEFILES,"rpp.shp"))
rpp <- spTransform(rpp, CRS('+init=epsg:2154'))
rpp <- gBuffer(rpp, byid=TRUE, width=0) # Ajout
rpp <- gUnaryUnion(spgeom = rpp)# Ajout

#prendre uniquement rpp et spa dans les zones en jeu
spa_clip <- rgeos::gIntersection(districts4, spa, byid = F, drop_lower_td = F)
plot(spa_clip, col=spa_colors, density=50, angle = 90, border = "green", add=T)
rpp_clip <- rgeos::gIntersection(districts4, rpp, byid = F, drop_lower_td = F)
plot(rpp_clip, col=rpp_colors, density=20, angle = 45, border = "blue", lwd=1.5, add=T)

# afficher les cellules non urbaines avec les couleurs 
noturbs <- land_use[land_use$lu_code != 2,]
plot(noturbs, col="", add=T)# sans couleur

# afficher les districts
districts4 <- districts[districts$player_id != 0,]
plot(districts4, border="grey", lty=1, lwd=2, add=T)

# ajouter les légendes
par(xpd=T) # autoriser l'affichage des légendes en dehors du graphe
legend("bottomleft", legend=c("special protect area"), fill=c("green"), density=50, angle = 90, border = "green", 
       horiz=T, inset=c(-0.1,-0.12), bty="n") 
legend("bottomleft", legend=c("risk prevention plan"), fill=c("blue"), density=20, angle = 45, border = "blue",
       horiz=T, inset=c(0.2,-0.12), bty="n")
legend("bottomleft", legend="districts", col="grey", lwd=2, 
       horiz=T, inset=c(0.2,-0.21), bty="n")
legend("bottomleft", legend=c("no urban", "very low density","low density","medium density","high density"), fill=c("white",rev(gray.colors(4))),
       horiz=T, inset=c(-0.1,-0.30), bty="n")
# Ajout des titres, sources , north
layoutLayer(title = "Restricted space (Land_Use_0)", 
            #author = "LittoSIM ©", 
            sources = "Sources : LittoSIM ©", frame = T, col = NA, 
            scale = NULL,coltitle = "black",
            north = T) 
# Ajout des étiquettes : ATTENTION à bien vérifier l'ordre des étiquettes
districts4$label_names <- c("com-A","com-D","com-C", "com-B")
labelLayer(x = districts4, txt = "label_names", col= "black", cex = 0.7, font = 4,halo = TRUE, bg = "white", r = 0.1,overlap = FALSE, show.lines = FALSE)
# échelle
barscale(size=1,lwd = 1.5,cex = 0.6,pos = "bottomright",style = "pretty",unit = "km")

dev.off()

print("finished treatments manager")




#
# Ce script est testé, et fonctionne bien sous R, version 3.6.3
#
# Le codage "utf-8" pour supporter les caractères de la langue française
options(encoding = "utf-8")

# Les packages nécessaires pour l'exécution du script manager
# Les packages sont installés s'ils le sont pas déjà
if (!require('ggplot2'))  { install.packages('ggplot2') }
if (!require('reshape2')) { install.packages('reshape2')}
if (!require('readr')) { install.packages('readr')}
if (!require('dplyr')) { install.packages('dplyr')}
if (!require('rgdal')) { install.packages('rgdal')}
if (!require('raster')) { install.packages('raster')}
library(ggplot2)
library(reshape2)
library(readr)
library(dplyr)
library(rgdal)
library(raster)

# La liste des noms (short names) et des codes INSEE des communes dans le même ordre
coms <- c('rochefort','stlaurent','stnazaire','porbarq')
insees <- c('17299','17353','17375','17484')
# Les noms des communes à afficher sur les graphes (dans le même ordre)
noms_communes <- c("Rochefort","Saint-Laurent","Saint-Nazaire","Port-des-Barques")

################################################################################################
# Les répertoires des fichiers (sorties de GAMA) à utiliser
# Le répertoire manager_data-X.xxxxxx généré pendant l'atelier, à récupérer de workspace/LittoSIM-GEN/includes/XXXXXX/, côté serveur.
# Le XXXXXX représente le nom de l'étude de cas
MANAGER_DATA <- "/Users/atelier/Desktop/manager_data-1.587376322512E12/"

# Vérifier si le MANAGER_DATA existe ou non
if (!dir.exists(MANAGER_DATA)){
  stop(paste("Le répertoire des données d'entrée n'existe pas :", MANAGER_DATA))
}

# Créer le répertoire des graphs à générer: le dossier graphs_manager sera dans l'espace du travail
# Si le répertoire existe déjà, on le supprime (Sous Windows, R ne remplace pas les fichiers existants !)
unlink("graphs_manager/", recursive=T)
dir.create("graphs_manager", showWarnings = FALSE)
print(paste("Les graphes seront enregistrés dans le répertoire ",getwd(),"/graphs_manager",sep=""))

################################################################################################
# Paramètres générales
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
dd$nom_commune <- noms_communes[match(dd$district_code, coms)]

# Factoriser les données numériques qui doivent être pris commes de facteurs et non pas comme des nombres
dd$num_round <- as.factor(dd$num_round)

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

################################################################################################

# Les graphes d'évolution enregistrés sous format png dans le répertoire "graphs_manager"
# La résolution et les dimensions des graphs peuvent être modifiés en changent les paramètres
# width, height et res de png()

################################################################################################
# Création du graph avec les numéros de tours sur l'axe des X, la population sur l'axe des Y,
# puis grouper et colorer selon la commune

p <- ggplot(dd, aes(x=num_round, y=popul, color=nom_commune, group=district_name)) +
  # les lignes du graph auront une épaisseur de 2
  geom_line(size=2) + scale_color_discrete(name = "Commune") +
  # les labels à afficher sur le graph
  labs(x = "Tour", y = "Population")

# rediriger la sortie vers un fichier png
png("graphs_manager/populations.png", width = 1000, height = 800, res=144)
print(p)
# fermer la redirection de la sortie pour enregistrer l'image
dev.off()

#
# De même, on crée le graph de l'evolution des budgets
#
png("graphs_manager/budgets.png", width = 1000, height = 800, res=144)
p <- ggplot(dd, aes(x=num_round, y=budget, color=nom_commune, group=district_name)) +
  geom_line(size=2) + scale_color_discrete(name = "Commune") + 
  labs(x = "Tour", y = "Budget")
print(p)
dev.off()

################################################################################################
# Composition des budgets en total et par tour
#
# les colonnes à considérer 
buds <- dd[,c("nom_commune", "num_round", "received_tax","actions_cost","given_money",
              "taken_money", "transferred_money","levers_costs")]

# On vire le tour 0 où il n'y a jamais de transactions
buds <- buds[buds$num_round != 0,]
# construire une tableau long à base du couple "nom commune" et "numéro de tour"
buds <- melt(buds, id = c("nom_commune","num_round"))

# les labels et les couleurs à utiliser sur les graphes
budget_labels <- c("Impôts reçus","Montants des actions","Subventions de l’Agence du risque",
                   "Prélevements de l’Agence du risque","Transfert entre communes","Leviers automatiques")
budget_colors <- c("received_tax"="gold","actions_cost"="darkgray","given_money"=
                     "darkgreen","taken_money"="darkred","transferred_money"="darkblue", "levers_costs"="purple")

# Composition du budget par tour
# les bars sont remplis selon la variable "variable" générée par melt
p <- ggplot(buds, aes(x=num_round, y=value, fill=variable)) + 
  geom_bar(stat="identity",  position=position_stack(reverse = TRUE))  +
  facet_wrap(~nom_commune, scales="free") +
  scale_fill_manual("Transaction", values=budget_colors,
                    labels=budget_labels) + labs(x = "Tour", y = "Montant")

png("graphs_manager/budget_round.png", width = 1200, height = 800, res=144)
print(p)
dev.off()

#
# Composition du budget par tour en pourcentage
p <- ggplot(buds, aes(x=num_round, y=value, fill=variable)) + 
  geom_bar(stat="identity",  position=position_fill(reverse = TRUE))  +
  facet_wrap(~nom_commune, scales="free") + scale_y_continuous(labels = scales::percent) +
  scale_fill_manual("Transaction", values=budget_colors,
                    labels=budget_labels) + labs(x = "Tour", y = "Montant en pourcentage")

png("graphs_manager/budget_round_percent.png", width = 1200, height = 800, res=144)
print(p)
dev.off()

#
# Composition du budget total
# calculer la somme des budgets selon le type de transaction pour chaque commune
buds <- aggregate(buds$value, by=list(buds$nom_commune,buds$variable), FUN=sum)
names(buds) <- c("nom_commune", "transaction","amount")
p <- ggplot(buds, aes(x=nom_commune, y=amount, fill=transaction)) +
  geom_bar(stat='identity', position=position_stack(reverse = TRUE))  +
  scale_fill_manual("Transaction", values=budget_colors, labels=budget_labels) +
  labs(x = "Commune", y = "Montant") +
  # forcer ggplot à afficher le nombre en entier au lieu de la notation scientifique
  scale_y_continuous(labels = scales::comma)

png("graphs_manager/budget_total.png", width = 1000, height = 800, res=144)
print(p)
dev.off()

#
# Composition du budget total en pourcentage
p <- ggplot(buds, aes(x=nom_commune, y=amount, fill=transaction)) +
  geom_bar(stat='identity', position=position_fill(reverse = TRUE))  +
  scale_fill_manual("Transaction", values=budget_colors, labels=budget_labels) +
  labs(x = "Commune", y = "Montant en pourcentage") +
  scale_y_continuous(labels = scales::percent)

png("graphs_manager/budget_total_percent.png", width = 1000, height = 800, res=144)
print(p)
dev.off()

################################################################################################
# Évolution des défenses côtières (digues et dunes)
#

# digues
codef <- data.frame()
for (ix in (1:nrow(dd))) {
  # Calculer la proportion des digues en bon état par rapport à toutes les digues
  val <- round(( (dd$last.length_dikes_good.[ix] * dd$last.mean_alt_dikes_good.[ix]) / (
    (dd$last.length_dikes_good.[ix] * dd$last.mean_alt_dikes_good.[ix])+
      (dd$last.length_dikes_medium.[ix] * dd$last.mean_alt_dikes_medium.[ix]) +
      (dd$last.length_dikes_bad.[ix] * dd$last.mean_alt_dikes_bad.[ix]) )) ,2)
  # si val est nulle (pas de digues pour la commune), mettre la valeur à 0
  val <- ifelse(is.nan(val), 0, val)
  codef = rbind (codef, c(dd[ix,]$nom_commune,as.character(dd[ix,]$num_round), val))
}

names(codef) <- c("district","round","val")
codef$round <- as.factor(codef$round)
codef$val <- as.double(codef$val)
# ordonner la table selon le numéro de tour
codef = codef[order(codef$round),]

p <- ggplot(codef, aes(x=round, y=val, color=district, group=district)) +
  geom_line(size=2) + scale_y_continuous(labels = scales::percent) +
  labs(x = "Tour", y = "Pourcentage de digues en bon état", color="Commune")

png("graphs_manager/dikes.png", width = 1000, height = 800, res=144)
print(p)
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
  codef = rbind (codef, c(dd[ix,]$nom_commune,as.character(dd[ix,]$num_round), val))
}

names(codef) <- c("district","round","val")
codef$round <- as.factor(codef$round)
codef$val <- as.double(codef$val)
# ordonner la table selon le numéro de tour
codef = codef[order(codef$round),]

p <- ggplot(codef, aes(x=round, y=val, color=district, group=district)) +
  geom_line(size=2) + scale_y_continuous(labels = scales::percent) +
  labs(x = "Tour", y = "Pourcentage de dunes en bon état", color="Commune")

png("graphs_manager/dunes.png", width = 1000, height = 800, res=144)
print(p)
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

p <- ggplot(lus) +
  geom_line(aes(x=num_round, y = value, group=variable, color=variable), size=1.25) +
  facet_wrap(~district_name, scales = "free_y") +
  scale_color_manual(values=c("nn"="darkgreen","uu"="darkgray","udense"="black","us"="blue",
                              "usdense"="darkblue","aa"="orange"),
                     labels= c("Naturel", "Urbain", "Urbain dense","Urbain adapté","Urbain adapté dense","Agricole")) +
  labs(x = "Tour", y = "Utilisation du sol (ha)", color="Type PLU")

png("graphs_manager/landuse.png", width = 1000, height = 800, res=144)
print(p)
dev.off()


################################################################################################
# Graphs de submersion
#
data = data.frame()

# lire tous les fichiers sub-RX.csv du repertoire flood_results
# ces fichiers contient les résultats des submersions par tour, type PLU, et par niveau
csvs <- list.files(path = paste(MANAGER_DATA,"flood_results",sep=""), pattern = "sub-R.*\\.csv$", full.names = T)
for (fichier in csvs) {
  d <- read.csv(fichier, sep= ";", header=T)
  data = rbind (data, d)
}
names(data) <- c("num_round","district_name","sub_level","uu","us","udense","au","aa","nn")

# on choisi les colonnes à utiliser, ici on va omettre le type AU "au"
data <- data[,c("num_round","district_name","sub_level","uu","us","udense","aa","nn")]

data$num_round <- as.factor(data$num_round)
data$sub_level <- as.factor(data$sub_level)

# calculer le total pour les colonnes en question
data$tt <- rowSums(data[,c("uu","us","udense","aa","nn")])

# renseigner le/les nom/noms de/des la commune(s) à afficher, ou commenter la ligne pour afficher toutes les communes
data <- subset(data, district_name %in% c("rochefort","porbarq"))

data <- melt(data, id = c("num_round","district_name","sub_level"))
data$sub_level = factor(data$sub_level,levels(data$sub_level)[c(3,2,1)])

# renommer les labels de la légende, on commente le AU
plu_types <- as_labeller(c("uu"="Urbain","us"="Urbain adapté","udense"="Urbain dense",
                           #"au"="Autorized U",
                           "aa"="Agricole","nn"="Naturel","tt"="Total"))

data$district_name <- noms_communes[match(data$district_name, coms)]

p <- ggplot(data, aes(fill=sub_level, y=value, x=num_round))+
  geom_bar(stat="identity") +
  # le paramètre "free" permet d'avoir des axes Y indépendants pour chaque barchart
  # le paramètre ncol permet de spécifier le nombre de colonnes (nombre de graphes par lignes)
  facet_wrap(district_name~variable, scales = "free", ncol= 3,
             labeller = labeller(variable = plu_types)) +
  scale_fill_manual("Hauteur d'eau", values=c("1"="lightblue","2"="blue","3"="darkblue"),
                    labels=c("> 1m","[0.5,1m]","< 0.5m")) +
  labs(x = "Tour de la submersion", y = "Surfaces submergées (ha)")

png("graphs_manager/graph_sub.png", width = 2500, height = 2000, res = 300)
print(p)
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
# changer le numéro du tour selon la submersion voulue. Pour chque submersion, le dossier est nommé
# avec le numéro du tour correspondant N results_RN_xxxxxxxx

num_round <- 7

# le fichier res-R8.max représente le fichier .max (lisflood) de la 3ème submersion correspondant au tour 7 du jeu
# à copier dans le dossier flood_results à partir du répertoire correspondant à la submersion en question 
# les résultats des submersions sont dans includes/XXXX/floodfiles/results_RN_xxxxx. Ne pas oublier de renommer les fichiers
# copiés (res.max --> res-R8.max)
subm <- raster(paste(MANAGER_DATA,"flood_results/res-R8.max",sep=""))
crs(subm) <- '+init=epsg:2154';


# lire les fichiers land use et defenses côtes du tour indiqué : "num_round"
# la lecture des deux fichiers engendrent deux warnings (Z-dimension), mais c'est à negliger car ils n'affectent pas les données
land_use <- readOGR(dsn = paste(MANAGER_DATA,"shapes",sep=""), layer = paste("Land_Use_",num_round,sep=""), verbose=FALSE);
land_use <- spTransform(land_use, CRS('+init=epsg:2154'));
codefs <- readOGR(dsn = paste(MANAGER_DATA,"shapes",sep=""), layer = paste("Coastal_Defense_",num_round,sep=""), verbose=FALSE);
codefs <- spTransform(codefs, CRS('+init=epsg:2154'));

# replacement de valeurs type par l'épaisseur voulu
codefs[codefs$type == "DIKE","type"] <- 2
codefs[codefs$type == "DUNE","type"] <- 4
codefs$type <- as.integer(codefs$type)

# prendre uniquement la submersion dans les zones en jeu
flood <- raster::intersect(subm, land_use)
flood <- mask(flood, land_use)
flood[flood==0] <- NA

#
# La carte sans la submersion
png("graphs_manager/map_sub.png", width = 1000, height = 1000, res=144)
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

# afficher les défenses cotières colorés selon l'état avec un épaisseur (lwd) selon le type
plot(codefs, lwd= codefs$type, col=codef_colors[match(codefs$status,codef_status)], add=T)

# ajouter les légendes
par(xpd=TRUE) # autoriser l'affichage des légendes en dehors du graphe
legend("bottom", legend=c("Digue","Dune"), lwd=c(2,4), inset=c(0,-0.17), bty="n")
legend("bottomright", legend=c("Bon","Moyen","Dégradé"), col=codef_colors, lwd=2, inset=c(0,-0.21), bty="n")
legend("bottom", legend=c("N","U","AU","A","Us","AUs"), fill=c("darkgreen","gray","yellow","orange","magenta","purple"),
       horiz=TRUE, inset=c(0,-0.31), bty="n")

dev.off()

#
# La carte avec la submersion
#

png("graphs_manager/map_no_sub.png", width = 1000, height = 1000, res=144)
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

# paramètrer la légende : 0, 0.5, 1
breakpoints <- c(0,0.5,1,round(max(flood[!is.na(flood)]),2))
# afficher la légende bleue
plot(flood,breaks=breakpoints,col=flood_cols, legend=F, add=T)

# afficher les défenses cotières colorés selon l'état avec un épaisseur (lwd) selon le type
plot(codefs, lwd= codefs$type, col=codef_colors[match(codefs$status,codef_status)], add=T)

# ajouter les légendes
par(xpd=TRUE)
legend("bottomleft", legend=c("< 0.5m","[0.5,1m]","> 1m"), fill=flood_cols, inset=c(0,-0.21),bty="n")
legend("bottom", legend=c("Digue","Dune"), lwd=c(2,4), inset=c(0,-0.17), bty="n")
legend("bottomright", legend=c("Bon","Moyen","Dégradé"), col=codef_colors, lwd=2, inset=c(0,-0.21), bty="n")
legend("bottom", legend=c("N","U","AU","A","Us","AUs"), fill=c("darkgreen","gray","yellow","orange","magenta","purple"),
       horiz=TRUE, inset=c(0,-0.31), bty="n")

dev.off()

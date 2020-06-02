options(encoding = "utf-8")
# les packages nécessaires pour l'exécution du script manager
library(ggplot2)
library(reshape2)
library(readr)
library(dplyr)
library(rgdal)
library(raster)

# la liste des noms et des codes INSEE des communes dans le même ordre
coms <- c('rochefort','stlaurent','stnazaire','porbarq')
insees <- c('17299','17353','17375','17484')
# noms des communes à afficher sur les graphes
noms_communes <- c("Nicolas","Amélie","Cécilia","Benoit")

# les répertoires des fichiers à utiliser
# les shapefiles de l'étude de cas : workspace/LittoSIM-GEN/includes/XXXXXX/shapefiles (le chemin ne doit
# pas se terminer par un '/')
# c'est le dossier du projet qui contient tous les shapefiles envoyés à GAMA (districts, ppr, ...)
SHAPEFILES <- "/Applications/littosim/workspace/LittoSIM-GEN/includes/estuary_coast/shapefiles"

# le répertoire manager_data-X.xxxxxx généré pendant l'atelier, à récupérer de workspace/LittoSIM-GEN/includes/XXXXXX/, côté serveur.
MANAGER_DATA <- "manager_data-1.587376322512E12/"

# créer le répertoire des graphs à générer: le dossier graphs_manager sera dans le même emplacement que ce script
dir.create("graphs_manager", showWarnings = FALSE)

# paramètres générales
options(stringsAsFactors = FALSE)
dd = data.frame()

# lire les données de toutes les communes à partir du répertoire csvs du MANADER_DATA : NOMCOMMUNE.csv
# le contenu des quatre fichiers est combiné dans une même table (data frame)
for (com in coms) {
  data <- read.csv(paste(MANAGER_DATA,"csvs/",com,".csv", sep=""), sep= ",", header=T)
  dd = rbind (dd, data)
}

# remplacer les codes des communes par leurs noms
dd$district_code <- coms[match(dd$district_code, insees)]

# factoriser les données numériques qui doivent être pris commes de facteurs et non pas comme des nombres
dd$num_round <- as.factor(dd$num_round)

# extraire le numéro du dernier tour qui le numéro de la dernière ligne - 1 (on commence à partir du tour 0)
# la table dd contient les données des quatres communes, d'où la division sur 4
last_round <- (nrow(dd) / 4) - 1


################################################################################################
# les tableaux des populations et des budgets à T0 (premier tour)
################################################################################################
print ("Population à T0:")
pop0 <- dd[dd$num_round==0,]$popul
prop0 <- paste(round(prop.table(pop0),3)*100,"%")
print(rbind(coms,pop0,prop0))
print("---------------------------------------------")

print ("Budgets à T0:")
bud0 <- dd[dd$num_round==0,]$budget
prop0 <- paste(round(prop.table(bud0),3)*100,"%")
print(rbind(coms,bud0,prop0))
print("---------------------------------------------")

################################################################################################
# les tableaux d’évolution des populations et des budgets entre T0 et la fin de l’atelier
################################################################################################
print ("Taux d'évolution de la population à la fin du jeu:")
print(rbind(coms,paste(round((dd[dd$num_round==last_round,]$popul - pop0) / pop0,3)*100,"%")))
print("---------------------------------------------")

print ("Taux d'évolution du budget à la fin du jeu:")
print(rbind(coms,paste(round((dd[dd$num_round==last_round,]$budget - bud0) / bud0,3)*100,"%")))
print("---------------------------------------------")


################################################################################################
# les graphes d'évolution enregistrés sous format png dans le répertoire "graphs_manager"
################################################################################################
# la résolution et les dimensions des graphs peut être modifié en changent les paramètres width, height et res

#rediriger la sortie vers un fichier png
png("graphs_manager/populations.png", width = 1000, height = 800, res=144)

#création du graph avec les numéros de tours sur l'axe des X, la population sur l'axe des Y,
# puis grouper et colorer selon la commune
p <- ggplot(dd, aes(x=num_round, y=popul, color=district_name, group=district_name)) +
  # les lignes du graph auront une épaisseur de 2
  geom_line(size=2) + scale_color_discrete(name = "Commune", labels = noms_communes) +
  # les labels à afficher sur le graph, "color" est le titre de la légende
  labs(x = "Tour", y = "Population")
print(p)
# fermer la redirection de la sortie pour enregistrer l'image
dev.off()

png("graphs_manager/budgets.png", width = 1000, height = 800, res=144)
p <- ggplot(dd, aes(x=num_round, y=budget, color=district_name, group=district_name)) +
  geom_line(size=2) + scale_color_discrete(name = "Commune", labels = noms_communes) + 
  labs(x = "Tour", y = "Budget")
print(p)
dev.off()


################################################################################################
# composition des budgets et total et par tour
################################################################################################
# les colonnes à considérer 
buds <- dd[,c("district_name", "num_round", "received_tax","actions_cost","given_money",
              "taken_money", "transferred_money","levers_costs")]

# construire une tableau long à base du couple "nom commune" et "numéro de tour"
buds <- melt(buds, id = c("district_name","num_round"))

# les labels et les couleurs à utiliser sur les graphes
budget_labels <- c("Impôts","Actions","Donné","Prélevé","Transféré","Leviers")
budget_colors <- c("received_tax"="gold","actions_cost"="darkgray","given_money"=
                     "darkgreen","taken_money"="darkred","transferred_money"="darkblue", "levers_costs"="purple")

# compsition du budget par tour
# les bars sont remplis selon la variable "variable" générée par melt
p <- ggplot(buds, aes(x=num_round, y=value, fill=variable)) + 
  geom_bar(stat="identity",  position=position_stack(reverse = TRUE))  +
  facet_wrap(~district_name, scales="free") +
  scale_fill_manual("Transaction", values=budget_colors,
                    labels=budget_labels) + labs(x = "Tour", y = "Montant")

png("graphs_manager/budget_round.png", width = 1000, height = 800, res=144)
print(p)
dev.off()

# composition du budget total
# calculer la somme des budgets selon le type de transaction pour chaque commune
buds <- aggregate(buds$value, by=list(buds$district_name,buds$variable), FUN=sum)
names(buds) <- c("district_name", "transaction","amount")
p <- ggplot(buds, aes(x=district_name, y=amount, fill=transaction)) +
  geom_bar(stat='identity', position=position_stack(reverse = TRUE))  +
  scale_fill_manual("Transaction", values=budget_colors, labels=budget_labels) +
  labs(x = "Tour", y = "Montant")

png("graphs_manager/budget_total.png", width = 1000, height = 800, res=144)
print(p)
dev.off()


################################################################################################
# Évolution des défenses côtières
################################################################################################

codef <- data.frame()
for (ix in (1:nrow(dd))) {
  # calculer la proportion des défenses cotières en bon état par rapport à toutes les defcotes
  val <- round(( (dd$last.length_dikes_good.[ix] * dd$last.mean_alt_dikes_good.[ix]) / (
    (dd$last.length_dikes_good.[ix] * dd$last.mean_alt_dikes_good.[ix])+
      (dd$last.length_dikes_medium.[ix] * dd$last.mean_alt_dikes_medium.[ix]) +
      (dd$last.length_dikes_bad.[ix] * dd$last.mean_alt_dikes_bad.[ix]) )) ,2)
  # si val est nulle (par defénses côtières), mettre la valeur à 0
  val <- ifelse(is.nan(val), 0, val)
  codef = rbind (codef, c(dd[ix,]$district_code,as.character(dd[ix,]$num_round), val))
}
names(codef) <- c("district","round","val")
codef$round <- as.factor(codef$round)
codef$val <- as.double(codef$val)
# ordonner la table selon le numéro de tour
codef = codef[order(codef$round),]
p <- ggplot(codef, aes(x=round, y=val, color=district, group=district)) +
  geom_line(size=2) +
  labs(x = "Tour", y = "% de digues en bon état", color="Commune")

png("graphs_manager/defcotes.png", width = 1000, height = 800, res=144)
print(p)
dev.off()


################################################################################################
# Évolution de l’utilisation du sol
################################################################################################

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
p <- ggplot(lus) +
  geom_line(aes(x=num_round, y = value, group=variable, color = variable), size=1.25) +
  facet_wrap(~district_name, scales = "free_y") +
  scale_color_manual(values=c("nn"="darkgreen","uu"="darkgray","udense"="black","us"="blue",
                              "usdense"="darkblue","aa"="orange"),
                     labels= c("N", "U", "Udense","Us","Usdense","A")) +
  labs(x = "Tour", y = "Utilisation du sol", color="Type LU")

png("graphs_manager/landuse.png", width = 1000, height = 800, res=144)
print(p)
dev.off()


################################################################################################
# Graphs de submersion
################################################################################################
data = data.frame()

# lire tous les fichiers sub-RX.csv du repertoire flood_results
# ces fichiers contient les résultats des submersions par tour, type LU, et par niveau
csvs <- list.files(path = paste(MANAGER_DATA,"flood_results",sep=""), pattern = "sub-R.*\\.csv$", full.names = T)
for (i in 1:length(csvs)) {
  d <- read.csv(csvs[i], sep= ";", header=T)
  data = rbind (data, d)
}

names(data) <- c("num_round","district_name","sub_level","uu","us","udense","au","aa","nn")

# on choisi les colonnes à utiliser, ici on va omettre le type AU "au"
data <- data[,c("num_round","district_name","sub_level","uu","us","udense","aa","nn")]
data$num_round <- as.factor(data$num_round)
data$sub_level <- as.factor(data$sub_level)
# calculer le total pour les colonnes en question
data$tt <- rowSums(data[,c("uu","us","udense","aa","nn")])

# renseigner le nom de la commune à afficher, ou commenter la ligne pour afficher toutes les communes
#data <- data[data$district_name =="rochefort",]

data <- melt(data, id = c("num_round","district_name","sub_level"))
data$sub_level = factor(data$sub_level,levels(data$sub_level)[c(3,2,1)])

# renommer les labels de la légende, on commente le AU
plu_types <- as_labeller(c("uu"="Urbain","us"="Urbain adapté","udense"="Urbain dense",
                           #"au"="Autorized U",
                           "aa"="Agricole","nn"="Naturel","tt"="Total"))

p <- ggplot(data, aes(fill=sub_level, y=value, x=num_round))+
  geom_bar(stat="identity") +
  # le paramètre "free" permet d'avoir des axes Y indépendants pour chaque barchart
  facet_wrap(district_name~variable, scales = "free", ncol= 6,
             labeller = labeller(variable = plu_types)) +
  scale_fill_manual("Level", values=c("1"="lightblue","2"="blue","3"="darkblue"),
                    labels=c("> 1m","[0.5,1m]","< 0.5m")) +
  labs(x = "Tour", y = "", fill="Hauteur d'eau")

png("graphs_manager/graph_sub.png", width = 2500, height = 2000, res = 300)
print(p)
dev.off()

################################################################################################
# Cartes de submersion
################################################################################################

# lire le fichier districts
districts <- readOGR(dsn = SHAPEFILES, layer = "districts", verbose=FALSE);
districts <- spTransform(districts, CRS('+init=epsg:2154'));

# paramètres d'affichage de la carte Land_Use
lu_names <- c("N","U","Ui","AU","A","Us","AUs");
lu_colors <- c("darkgreen","gray","","yellow","red","magenta","purple")
codef_colors <- c("green","gold","red")
codef_status <- c("GOOD","MEDIUM","BAD")
pop_class <- c("EMPTY","POP_VERY_LOW_DENSITY","LOW_DENSITY","MEDIUM_DENSITY","DENSE")
pop_colors <- c("white",rev(gray.colors(4)))
flood_cols <- c("lightblue","blue","darkblue")

# lire les fichiers de submersion et les shapefiles du tour 7
# changer le numéro du tour selon la submersion voulue. Pour chque submersion, le dossier est nommé
# avec le numéro du tour correspondant N results_RN_xxxxxxxx
num_round <- 7

# le fichier res-R8.max représente le fichier .max (lisflood) de la 3ème submersion correspondant au tour 7 du jeu
# à copier dans le dossier flood_results à partir du répertoire correspondant à la submersion en question 
# les résultats des submersions sont dans includes/XXXX/floodfiles/resultsxxxxx. Ne pas oublier de renommer les fichiers
# copiés (res.max --> res-R8.max)
subm <- raster(paste(MANAGER_DATA,"flood_results/res-R8.max",sep=""))
crs(subm) <- '+init=epsg:2154';

#lire les fichiers land use et defenses côtes
land_use <- readOGR(dsn = paste(MANAGER_DATA,"shapes",sep=""), layer = paste("Land_Use_",num_round,sep=""), verbose=FALSE);
land_use <- spTransform(land_use, CRS('+init=epsg:2154'));
codefs <- readOGR(dsn = paste(MANAGER_DATA,"shapes",sep=""), layer = paste("Coastal_Defense_",num_round,sep=""), verbose=FALSE);
codefs <- spTransform(codefs, CRS('+init=epsg:2154'));

# replacement de valeurs type par l'épaisseur voulu
codefs[codefs$type == "DIKE","type"] <- 2
codefs[codefs$type == "DUNE","type"] <- 4
codefs$type <- as.integer(codefs$type)

png("graphs_manager/map_sub.png", width = 1000, height = 800, res=144)

# prendre uniquement la submersion dans les zones en jeu
flood <- raster::intersect(subm, land_use)
flood <- mask(flood, land_use)
flood[flood==0] <- NA
plot(flood,legend=F)

# afficher les cellules non urbaines avec les couleurs 
noturbs <- land_use[land_use$lu_code != 2,]
plot(noturbs, col=lu_colors[noturbs$lu_code], add=T)

# afficher les cellules urbaines colorées selon la densité de population
urbs <- land_use[land_use$lu_code == 2,]
plot(urbs, col=pop_colors[match(urbs$density_cl,pop_class)], add=T)

# paramètrer la légende : 0, 0.5, 1
breakpoints <- c(0,0.5,1,round(max(flood[!is.na(flood)]),2))
plot(flood,breaks=breakpoints,col=flood_cols, add=T)

# afficher les défenses cotières colorés selon l'état avec un épaisseur (lwd) selon le type
plot(codefs, lwd= codefs$type, col=codef_colors[match(codefs$status,codef_status)], add=T)
dev.off()

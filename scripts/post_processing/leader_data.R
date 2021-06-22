################################################
# LittoSIM - leader_data version du 22/06/2021
# @Authors: Ahmed Laatabi et compléments : Cécilia Pignon-Mussaud, Nicolas Marilleau
# This script allows you to generate different diagrams to analyze the results of a LittoSIM simulation/game session, after the workshop.
# Ce script est testé, et fonctionne bien sous R, version 3.6.3
# Le codage "utf-8" pour supporter les caractères de la langue française
options(encoding = "utf-8")

# Les packages nécessaires pour l'exécution du script leader
# Les packages sont installés s'ils le sont pas déjà
if (!require('ggplot2'))  { install.packages('ggplot2') }
if (!require('reshape2')) { install.packages('reshape2')}
library(ggplot2)
library(reshape2)

# La liste des noms (short names) et des codes INSEE des communes dans le même ordre
coms <- c('rochefort','stlaurent','stnazaire','porbarq')
insees <- c('17299','17353','17375','17484')
# Les noms des communes à afficher sur les graphes (dans le même ordre)
noms_communes <- c("Rochefort","Saint-Laurent","Saint-Nazaire","Port-des-Barques")

# La liste des stratégies dans l’ordre d’affichage sur les graphes
strategies <- c("BUILDER", "SOFT_DEFENSE", "WITHDRAWAL", "OTHER")
# Les noms des stratégies à afficher sur les graphes, dans le même ordre que la liste précédente "strategies"
noms_strategies <- c("Bâtisseur","Défense douce","Retrait stratégique","Autres")
strategies_colors <- c("BUILDER"="blue","SOFT_DEFENSE"="green","WITHDRAWAL"="orange","OTHER"="gray")

################################################################################################
# Les répertoires des fichiers (sorties de GAMA) à utiliser
# Le répertoire leader_data-X.xxxxxx, à récupérer de workspace/LittoSIM-GEN/includes/XXXXXX/, côté agence du risque
# Le XXXXXX représente le nom de l'étude de cas
LEADER_DATA <- "/Users/atelier/Desktop/leader_data-1.587376442452E12/"

# Vérifier si le LEADER_DATA existe ou non
if (!dir.exists(LEADER_DATA)){
  stop(paste("Le répertoire des données d'entrée n'existe pas :", LEADER_DATA))
}

# Créer le répertoire des graphs à générer: le dossier graphs_leader sera dans l'espace du travail
# Si le répertoire existe déjà, on le supprime (Sous Windows, R ne remplace pas les fichiers existants !)
unlink("graphs_leader/", recursive=T)
dir.create("graphs_leader", showWarnings = FALSE)
print(paste("Les graphes seront enregistrés dans le répertoire ",getwd(),"/graphs_leader",sep=""))

################################################################################################
# Paramètres générales
# Éviter de prendre les champs de type chaine de caractère comme des facteurs
options(stringsAsFactors = FALSE)
# Un tableau pour récupérer toutes les actions joueurs
pacts = data.frame()

# Lire les données de tous les tours du jeu à partir des fichiers leader : player_actions_roundX.csv (X = numéro de tour)
csvs <- list.files(path = LEADER_DATA, pattern = "player_actions_round.*\\.csv$", full.names = T)
for (fichier in csvs) {
  data <- read.csv(fichier, sep= ";", header=T)
  pacts = rbind (pacts, data)
}

# Remplacer les codes des communes par leur noms pour plus de visibilité
pacts$district_code <- coms[match(pacts$district_code, insees)]
pacts$nom_commune <- noms_communes[match(pacts$district_code, coms)]

# Différencier le A vers N de l'expropriation (U -> N)
# On change toutes les valeurs 4 du champ "command" des lignes ayant comme type PLU précédent "previous_lu" le type agricole "A"
# c-à-d toutes les transformations de A vers N auront un numéro de command = 4.5 au lieu de 5
# Les numéros de commande des actions sont définis dans le fichier actions.conf du répértoire de l'étude du cas
pacts[pacts$command == 4 & pacts$previous_lu == "A",]$command <- 4.5

# Factoriser les données 
pacts$strategy_profile <- factor(pacts$strategy_profile, levels= strategies)
pacts$command_round <- as.factor(pacts$command_round)
pacts$command <- as.factor(pacts$command)

# Créer un named-vector pour relier toutes les actions LittoSIM à des couleurs. Pour changer la couleur attribuée à une
# action, on change la couleur correspondante dans ce vecteur
# Un named-vector permet d'accéder au valeurs string d'un vecteur à travers des noms (string)
command_to_colors <- c("1"="yellow","2"="orange","4"="darkgreen","4.5"="yellowgreen","5"="darkred",
                       "6"="red","7"="beige","8"="darkblue","26"="lightsalmon","28"="darkkhaki","29"="lightsalmon",
                       "30"="darkorchid","31"="magenta","32"="blue","44"="pink","311"="black")

# Un named-vector pour relier toutes les actions LittoSIM aux noms d'actions à aficher sur les graphes 
command_to_names <- c("1"="Changer en AU","2"="Changer en A","4"="Expropriation","4.5"="Changer A en N",
                      "5"="Réparer une digue","6"="Construire une digue","7"="Démanteler une digue",
                      "8"="Rehausser une digue","26"="Renforcer l'accrétion","28"="Construire une dune",
                      "29"="Installer des ganivelles","30"="Maintenir une dune","31"="Changer en AUs",
                      "32"="Changer en Us","44"="Recharger en galets","311"="Densification")

################################################################################################
# Répartition totale des actions par nombre
#
p <- ggplot(pacts, aes(nom_commune, fill=command)) +
  # scale_x_discrete(drop=FALSE) permet de garder la place du barplot sur l'axe des x même s'il n'y a pas de valeurs
  # correspondantes. Exemple: la commune Toto sera affichée même si elle n'a pas fait d'actions, bien sûr avec 0 actions
  geom_bar(position = position_stack(reverse = TRUE)) + scale_x_discrete(drop=FALSE) +
  scale_fill_manual("Action", breaks=levels(pacts$command), 
                    values= command_to_colors, label=command_to_names[levels(pacts$command)]) +
  labs(x = "Commune", y = "Nombre d'actions")

# On ouvre un tunnel vers une image PNG pour y enregistrer le graph, en spécifiant les dimensions et la résolution
png("graphs_leader/actions_total_count.png", width = 1000, height = 800, res=144)
# Écriture de l'image
print(p)
# Fermuture du tunnel ouvert
dev.off()

#
# Répartition totale des actions par nombre en pourcentage
#
p <- ggplot(pacts, aes(nom_commune, fill=command)) +
  geom_bar(position = position_fill(reverse = TRUE)) + scale_x_discrete(drop=FALSE) +
  scale_fill_manual("Action", breaks=levels(pacts$command), 
                    values= command_to_colors, label=command_to_names[levels(pacts$command)]) +
  labs(x = "Commune", y = "Pourcentage du nombre d'actions") +
  # pour afficher l'axe y en pourcentage
  scale_y_continuous(labels = scales::percent)

png("graphs_leader/actions_total_count_percent.png", width = 1000, height = 800, res=144)
print(p)
dev.off()

################################################################################################
# Répartition par tour des actions par nombre
#
p <- ggplot(pacts, aes(command_round, fill=command)) +
  geom_bar(position = position_stack(reverse = TRUE)) +
  # facet_wrap permet de générer quatre graphes chacun corresponsant à une commune
  # scales="free" ordonne de créer une échelle (scale) indépendate pour chaque graphe
  # Pour avoir le même scale pour les 4 graphes, enlevez ', scales="free"'
  facet_wrap(~nom_commune, scales="free") + scale_x_discrete(drop=FALSE) +
  scale_fill_manual("Action", breaks=levels(pacts$command),
                    values=command_to_colors,label=command_to_names[levels(pacts$command)]) +
  labs(x = "Tour", y = "Nombre d'actions")

png("graphs_leader/actions_round_count.png", width = 1000, height = 800, res=144)
print(p)
dev.off()

#
# Répartition par tour des actions par nombre en pourcentage
#
p <- ggplot(pacts, aes(command_round, fill=command)) +
  geom_bar(position = position_fill(reverse = TRUE)) +
  facet_wrap(~nom_commune) + scale_x_discrete(drop=FALSE) +
  scale_fill_manual("Action", breaks=levels(pacts$command),
                    values=command_to_colors,label=command_to_names[levels(pacts$command)]) +
  labs(x = "Tour", y = "Pourcentage du nombre d'actions") + scale_y_continuous(labels = scales::percent)

png("graphs_leader/actions_round_count_percent.png", width = 1000, height = 800, res=144)
print(p)
dev.off()

################################################################################################
# Répartition totale des actions par coût
#
p <- ggplot(pacts, aes(x=nom_commune, y=cost, fill=command)) +
  geom_bar(stat="identity", position = position_stack(reverse = TRUE)) + scale_x_discrete(drop=FALSE) +
  scale_fill_manual("Action", breaks=levels(pacts$command),
                    values=command_to_colors,label=command_to_names[levels(pacts$command)]) +
  labs(x = "Commune", y = "Coût des actions")

png("graphs_leader/actions_total_cost.png", width = 1000, height = 800, res=144)
print(p)
dev.off()

#
# Répartition totale des actions par coût en pourcentage
#
p <- ggplot(pacts, aes(x=nom_commune, y=cost, fill=command)) +
  geom_bar(stat="identity", position = position_fill(reverse = TRUE)) + scale_x_discrete(drop=FALSE) +
  scale_fill_manual("Action", breaks=levels(pacts$command),
                    values=command_to_colors,label=command_to_names[levels(pacts$command)]) +
  labs(x = "Commune", y = "Pourcentage des coûts d'actions") +
  scale_y_continuous(labels = scales::percent)

png("graphs_leader/actions_total_cost_percent.png", width = 1000, height = 800, res=144)
print(p)
dev.off()

################################################################################################
# Répartition par tour des actions par coût
#
p <- ggplot(pacts, aes(x=command_round, y=cost, fill=command)) +
  geom_bar(stat="identity", position = position_stack(reverse = TRUE)) + scale_x_discrete(drop=FALSE) +
  facet_wrap(~nom_commune, scales="free") +
  scale_fill_manual("Action", breaks=levels(pacts$command),
                    values=command_to_colors,label=command_to_names[levels(pacts$command)]) +
  labs(x = "Tour", y = "Coût des actions")

png("graphs_leader/actions_round_cost.png", width = 1000, height = 800, res=144)
print(p)
dev.off()

#
# Répartition par tour des actions par coût en pourcentage
#
p <- ggplot(pacts, aes(x=command_round, y=cost, fill=command)) +
  geom_bar(stat="identity", position = position_fill(reverse = TRUE)) +
  facet_wrap(~nom_commune) + scale_x_discrete(drop=FALSE) +
  scale_fill_manual("Action", breaks=levels(pacts$command),
                    values=command_to_colors,label=command_to_names[levels(pacts$command)]) +
  labs(x = "Tour", y = "Pourcentage des coûts d'actions") + scale_y_continuous(labels = scales::percent)

png("graphs_leader/actions_round_cost_percent.png", width = 1000, height = 800, res=144)
print(p)
dev.off()

################################################################################################
# Répartition totale des stratégies par nombre
#
p <- ggplot(pacts, aes(nom_commune, fill=strategy_profile)) +
  geom_bar(position = position_stack(reverse = TRUE)) + scale_x_discrete(drop=FALSE) +
  scale_fill_manual("Stratégie", breaks=strategies,
                    values= strategies_colors, label= noms_strategies) +
  labs(x = "Commune", y = "Nombre d'actions")

png("graphs_leader/strategies_total_count.png", width = 1000, height = 800, res=144)
print(p)
dev.off()

#
# Répartition totale des stratégies par nombre en pourcentage
#
p <- ggplot(pacts, aes(nom_commune, fill=strategy_profile)) +
  geom_bar(position = position_fill(reverse = TRUE)) + scale_x_discrete(drop=FALSE) +
  scale_fill_manual("Stratégie", breaks=strategies,
                    values= strategies_colors, label= noms_strategies) +
  labs(x = "Commune", y = "Pourcentage du nombre d'actions") + scale_y_continuous(labels = scales::percent)

png("graphs_leader/strategies_total_count_percent.png", width = 1000, height = 800, res=144)
print(p)
dev.off()

################################################################################################
# Répartition totale des stratégies par coût
#
p <- ggplot(pacts, aes(x=nom_commune, y=cost, fill=strategy_profile)) +
  geom_bar(stat="identity", position = position_stack(reverse = TRUE)) + scale_x_discrete(drop=FALSE) +
  scale_fill_manual("Stratégie", breaks=strategies,
                    values=strategies_colors, label= noms_strategies)+
  labs(x = "Commune", y = "Coût des actions")

png("graphs_leader/strategies_total_cost.png", width = 1000, height = 800, res=144)
print(p)
dev.off()

#
# Répartition totale des stratégies par coût en pourcentage
#
p <- ggplot(pacts, aes(x=nom_commune, y=cost, fill=strategy_profile)) +
  geom_bar(stat="identity", position = position_fill(reverse = TRUE)) + scale_x_discrete(drop=FALSE) +
  scale_fill_manual("Stratégie", breaks=strategies,
                    values=strategies_colors, label= noms_strategies)+
  labs(x = "Commune", y = "Pourcentage des coûts d'actions") + scale_y_continuous(labels = scales::percent)

png("graphs_leader/strategies_total_cost_percent.png", width = 1000, height = 800, res=144)
print(p)
dev.off()

################################################################################################
# Répartition par tour des stratégies par nombre
#

p <- ggplot(pacts, aes(command_round, fill=strategy_profile)) +
  geom_bar(position = position_stack(reverse = TRUE)) +
  facet_wrap(~nom_commune, scales="free") + scale_x_discrete(drop=FALSE) +
  scale_fill_manual("Stratégie", breaks=levels(pacts$strategy_profile),
                    values=strategies_colors,label=noms_strategies) +
  labs(x = "Tour", y = "Nombre d'actions par stratégie")

png("graphs_leader/strategies_round_count.png", width = 1000, height = 800, res=144)
print(p)
dev.off()

#
# Répartition par tour des stratégies par nombre en pourcentage
#
p <- ggplot(pacts, aes(command_round, fill=strategy_profile)) +
  geom_bar(position = position_fill(reverse = TRUE)) +
  facet_wrap(~nom_commune) + scale_x_discrete(drop=FALSE) +
  scale_fill_manual("Stratégie", breaks=levels(pacts$strategy_profile),
                    values=strategies_colors,label=noms_strategies) +
  labs(x = "Tour", y = "Pourcentage du nombre d'actions par stratégie") + scale_y_continuous(labels = scales::percent)

png("graphs_leader/strategies_round_count_percent.png", width = 1000, height = 800, res=144)
print(p)
dev.off()

################################################################################################
# Répartition par tour des stratégies par coût
#
p <- ggplot(pacts, aes(x=command_round, y=cost, fill=strategy_profile)) +
  geom_bar(stat="identity", position = position_stack(reverse = TRUE)) +
  facet_wrap(~nom_commune, scales="free") + scale_x_discrete(drop=FALSE) +
  scale_fill_manual("Stratégie", breaks=levels(pacts$strategy_profile),
                    values=strategies_colors,label=noms_strategies) +
  labs(x = "Tour", y = "Coût des actions par stratégie")

png("graphs_leader/strategies_round_cost.png", width = 1000, height = 800, res=144)
print(p)
dev.off()

#
# Répartition par tour des stratégies par coût en pourcentage
#
p <- ggplot(pacts, aes(x=command_round, y=cost, fill=strategy_profile)) +
  geom_bar(stat="identity", position = position_fill(reverse = TRUE)) +
  facet_wrap(~nom_commune) + scale_x_discrete(drop=FALSE) +
  scale_fill_manual("Stratégie", breaks=levels(pacts$strategy_profile),
                    values=strategies_colors,label=noms_strategies) +
  labs(x = "Tour", y = "Pourcentage des coût d'actions par stratégie") + scale_y_continuous(labels = scales::percent)

png("graphs_leader/strategies_round_cost_percent.png", width = 1000, height = 800, res=144)
print(p)
dev.off()

################################################################################################
# Nombre d’actions en cours par stratégie
#
# Les actions en cours sont celles qui ne sont pas encore appliquées à la fin du jeu
# c-à-d elles ont le initial_application_round (tour d'application) supérieur au dernier tour
# ici on prend le dernier tour + 1 (last_round+1) pour parler des actions en retard
# c-à-d qu'elles ne sont pas appliquées même au tour suivant le dernier tour du jeu (retard stratégique)

# Le dernier tour c'est la valeur max du champ command_round
last_round <- max(as.numeric(as.character(pacts$command_round)))
# Toutes les actions qui ne seront pas appliquées même en dernier tour + 1
actions <- pacts[pacts$initial_application_round > last_round+1,]

# Pour garder et afficher toutes les communes même sans ayant des actions
actions$district_code <- factor(actions$district_code, levels= coms)
actions$nom_commune <- factor(actions$nom_commune, levels= noms_communes)

p <- ggplot(actions, aes(nom_commune, fill=strategy_profile)) +
  geom_bar(position = position_stack(reverse = TRUE)) + scale_x_discrete(drop=FALSE) +
  scale_fill_manual("Stratégie", breaks=strategies, drop=FALSE,
                    values=strategies_colors, label= noms_strategies) +
  labs(x = "Commune", y = "Actions en cours")

png("graphs_leader/waiting_actions_strategy.png", width = 1000, height = 800, res=144)
print(p)
dev.off()

#
# Nombre d’actions en cours par type d'action
#

p <- ggplot(actions, aes(nom_commune, fill=command)) +
  geom_bar(position = position_stack(reverse = TRUE)) + scale_x_discrete(drop=FALSE) +
  scale_fill_manual("Action", breaks=levels(actions$command), drop=FALSE,
                    values=command_to_colors,
                    label=command_to_names[levels(pacts$command)]) +
  labs(x = "Commune", y = "Actions en cours")

png("graphs_leader/waiting_actions.png", width = 1000, height = 800, res=144)
print(p)
dev.off()

################################################################################################
# Nombre d’actions en risque et en protégé
#
tots <- table(pacts$district_code)
actions <-  melt(pacts[,c("district_code","is_in_risk_area","is_in_protected_area")], id = c("district_code"))
tb <- table(actions)[,,"true"]
dd <- as.data.frame(cbind(coms,tb[,2],tb[,1],tots))
colnames(dd) <- c("district_code","protected","risked","total")
dd <- melt(dd, id="district_code")
dd$value <- as.integer(dd$value)
dd$nom_commune <- noms_communes[match(dd$district_code, coms)]

p <- ggplot(dd, aes(x=variable, y=value, fill=variable)) +
  geom_bar(stat="identity", position = position_stack(reverse = TRUE)) +
  facet_wrap(~nom_commune, scales = "free") + theme(legend.position = "none") +
  scale_x_discrete(label=c("Zone\nenvironnementale\nprotégée","Zone à risque\n(PPR)","Total"), drop=FALSE) +
  scale_fill_manual("Type de zone", values=c("protected"="green","risked"="red","total"="darkblue")) +
  labs(x = "", y = "Nombre d'actions")

png("graphs_leader/risk_protected_actions.png", width = 1000, height = 800, res=144)
print(p)
dev.off()

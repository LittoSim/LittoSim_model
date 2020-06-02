options(encoding = "utf-8")
# les packages nécessaires pour l'exécution du script manager
library(ggplot2)
library(reshape2)

# la liste des noms et des codes INSEE des communes dans le même ordre
coms <- c('rochefort','stlaurent','stnazaire','porbarq')
insees <- c('17299','17353','17375','17484')

# les répertoires des fichiers à utiliser
# le répertoire leader_data-X.xxxxxx, à récupérer de workspace/LittoSIM-GEN/includes/XXXXXX/, côté agence du risque
LEADER_DATA <- "leader_data-1.587376442452E12/"

# créer le répertoire des graphs à générer: le dossier graphs_leader sera dans le même emplacement que ce script
dir.create("graphs_leader", showWarnings = FALSE)

# paramètres générales
# éviter de prendre les champs de type chaine de caractère comme des facteurs
options(stringsAsFactors = FALSE)
# une table pour récupérer toutes les actions joueurs
pacts = data.frame()

# la liste des stratégies dans l’ordre d’affichage
strategies <- c("BUILDER", "SOFT_DEFENSE", "WITHDRAWAL", "OTHER")
noms_strategies <- c("Bâtisseur","Défense douce","Retrait stratégique","Autres")
strategies_colors <- c("BUILDER"="blue","SOFT_DEFENSE"="green","WITHDRAWAL"="orange","OTHER"="gray")

# lire les données de tous les tours du jeu à partir des fichiers leader : player_actions_roundX.csv
csvs <- list.files(path = LEADER_DATA, pattern = "player_actions_round.*\\.csv$", full.names = T)
for (i in 1:length(csvs)) {
  data <- read.csv(csvs[i], sep= ";", header=T)
  pacts = rbind (pacts, data)
}

# remplacer les codes communes par les noms
pacts$district_code <- coms[match(pacts$district_code, insees)]

# différencier le A vers N de l'expropriation (U -> N)
# on change toutes les valeurs 4 du champ "command" des lignes ayant comme type LU précédent "previous_lu" le "A"
# c-à-d toutes les transformations de A vers N auront command = 4.5 au lieu de 5
# ces numéros de commande sont définis dans le fichier /includes/actions.conf du répértoire du projet
pacts[pacts$command == 4 & pacts$previous_lu == "A",]$command <- 4.5

# factoriser les données
pacts$strategy_profile <- factor(pacts$strategy_profile, levels= strategies)
pacts$command_round <- as.factor(pacts$command_round)
pacts$command <- as.factor(pacts$command)

# un named-vector pour relier toutes les actions LittoSIM à des couleurs
# un named-vector permet d'accéder au valeurs string d'un vecteur à travers des noms (string)
command_to_colors <- c("1"="yellow","2"="orange","4"="darkgreen","4.5"="yellowgreen","5"="darkred",
                       "6"="red","7"="beige","8"="darkblue","26"="lightsalmon","28"="darkkhaki","29"="lightsalmon",
                       "30"="darkorchid","31"="magenta","32"="blue","44"="pink","311"="black")

# un named-vector pour relier toutes les actions LittoSIM à des noms
command_to_names <- c("1"="Changer en AU","2"="Changer en A","4"="Expropriation","4.5"="Changer A en N",
                      "5"="Réparer une digue","6"="Construire une digue","7"="Démanteler une digue",
                      "8"="Rehausser une digue","26"="Renforcer l'accrétion","28"="Construire une dune",
                      "29"="Installer des ganivelles","30"="Maintenir une dune","31"="Changer en AUs",
                      "32"="Changer en Us","44"="Recharger en galets","311"="Densification")

################################################################################################
# Répartition totale des actions par nombre
################################################################################################
p <- ggplot(pacts, aes(district_code, fill=command)) +
  geom_bar(position = position_stack(reverse = TRUE)) +
  scale_fill_manual("Action", breaks=levels(pacts$command),
                    values= command_to_colors, label=command_to_names[levels(pacts$command)]) +
  labs(x = "Commune", y = "Nombre d'actions")

png("graphs_leader/actions_total_count.png", width = 1000, height = 800, res=144)
print(p)
dev.off()

################################################################################################
# Répartition par tour des actions par nombre
################################################################################################
p <- ggplot(pacts, aes(command_round, fill=command)) +
  geom_bar(position = position_stack(reverse = TRUE)) +
  facet_wrap(~district_code, scales="free") + scale_x_discrete(drop=FALSE) +
  scale_fill_manual("Action", breaks=levels(pacts$command),
                    values=command_to_colors,label=command_to_names[levels(pacts$command)]) +
  labs(x = "Tour", y = "Nombre d'actions")

png("graphs_leader/actions_round_count.png", width = 1000, height = 800, res=144)
print(p)
dev.off()

################################################################################################
# Répartition totale des actions par coût
################################################################################################
p <- ggplot(pacts, aes(x=district_code, y=cost, fill=command)) +
  geom_bar(stat="identity", position = position_fill(reverse = TRUE)) +
  scale_fill_manual("Action", breaks=levels(pacts$command),
                    values=command_to_colors,label=command_to_names[levels(pacts$command)]) +
  labs(x = "Commune", y = "Coût des actions")

png("graphs_leader/actions_total_cost.png", width = 1000, height = 800, res=144)
print(p)
dev.off()

################################################################################################
# Répartition par tour des actions par coût
################################################################################################
p <- ggplot(pacts, aes(x=command_round, y=cost, fill=command)) +
  geom_bar(stat="identity", position = position_stack(reverse = TRUE)) +
  facet_wrap(~district_code) +
  scale_fill_manual("Action", breaks=levels(pacts$command),
                    values=command_to_colors,label=command_to_names[levels(pacts$command)]) +
  labs(x = "Tour", y = "Coût des actions")

png("graphs_leader/actions_round_costXXX.png", width = 1000, height = 800, res=144)
print(p)
dev.off()

################################################################################################
# Répartition totale des stratégies par nombre
################################################################################################
p <- ggplot(pacts, aes(district_code, fill=strategy_profile)) +
  geom_bar(position = position_stack(reverse = TRUE)) +
  scale_fill_manual("Stratégie", breaks=strategies,
                    values= strategies_colors, label= noms_strategies) +
  labs(x = "Commune", y = "Nombre d'actions")

png("graphs_leader/strategies_total_count.png", width = 1000, height = 800, res=144)
print(p)
dev.off()

################################################################################################
# Répartition totale des stratégies par coût
################################################################################################
p <- ggplot(pacts, aes(x=district_code, y=cost, fill=strategy_profile)) +
  geom_bar(stat="identity", position = position_fill(reverse = TRUE)) +
  scale_fill_manual("Strategy", breaks=strategies,
                    values=strategies_colors, label= noms_strategies)+
  labs(x = "Commune", y = "Coût des actions")

png("graphs_leader/strategies_total_cost.png", width = 1000, height = 800, res=144)
print(p)
dev.off()

################################################################################################
# Répartition par tour des stratégies par nombre
################################################################################################

p <- ggplot(pacts, aes(command_round, fill=strategy_profile)) +
  geom_bar(position = position_stack(reverse = TRUE)) +
  facet_wrap(~district_code, scales="free") + scale_x_discrete(drop=FALSE) +
  scale_fill_manual("Stratégie", breaks=levels(pacts$strategy_profile),
                    values=strategies_colors,label=noms_strategies) +
  labs(x = "Tour", y = "Nombre d'actions par stratégie")

png("graphs_leader/strategies_round_count.png", width = 1000, height = 800, res=144)
print(p)
dev.off()


################################################################################################
# Répartition par tour des stratégies par coût
################################################################################################
p <- ggplot(pacts, aes(x=command_round, y=cost, fill=strategy_profile)) +
  geom_bar(stat="identity", position = position_fill(reverse = TRUE)) +
  facet_wrap(~district_code) +
  scale_fill_manual("Action", breaks=levels(pacts$strategy_profile),
                    values=strategies_colors,label=noms_strategies) +
  labs(x = "Tour", y = "Coût des actions par stratégie")

png("graphs_leader/strategies_round_cost.png", width = 1000, height = 800, res=144)
print(p)
dev.off()

################################################################################################
# Nombre d’actions en cours par stratégie
################################################################################################
# les actions en cours sont celles qui ne sont pas encore appliquées à la fin du jeu
# c-à-d elles ont le initial_application_round (tour d'application) supérieur au dernier tour
# ici on prend le dernier tour + 1 (last_round+1) pour parler des actions en retard
# c-à-d qu'elles ne sont pas appliquées même au tour suivant (retard stratégique)

# le dernier tour c'est la valeur max du champ command_round
last_round <- max(as.numeric(as.character(pacts$command_round)))
# toutes les actions qui ne seront pas appliquées même en dernier tour + 1
actions <- pacts[pacts$initial_application_round > last_round+1,]
actions$district_code <- factor(actions$district_code, levels= coms)

p <- ggplot(actions, aes(district_code, fill=strategy_profile)) +
  geom_bar(position = position_stack(reverse = TRUE)) + scale_x_discrete(drop=FALSE) +
  scale_fill_manual("Stratégie", breaks=strategies, drop=FALSE,
                    values=strategies_colors, label= noms_strategies) +
  labs(x = "Commune", y = "Actions en cours")

png("graphs_leader/waiting_actions_strategy.png", width = 1000, height = 800, res=144)
print(p)
dev.off()

################################################################################################
# Nombre d’actions en cours par type
################################################################################################

# pour afficher toutes les communes même sans ayant des actions
actions$district_code <- factor(actions$district_code, levels= coms)

p <- ggplot(actions, aes(district_code, fill=command)) +
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
################################################################################################

tots <-  table(pacts$district_code)
actions <-  melt(pacts[,c("district_code","is_in_risk_area","is_in_protected_area")], id = c("district_code"))
tb <- table(actions)[,,"true"]
dd <- as.data.frame(cbind(coms,tb[,2],tb[,1],tots))
colnames(dd) <- c("district_code","protected","risked","total")
dd <- melt(dd, id="district_code")
dd$value <- as.integer(dd$value)

p <- ggplot(dd, aes(x=variable, y=value, fill=variable)) +
  geom_bar(stat="identity", position = position_stack(reverse = TRUE)) +
  facet_wrap(~district_code, scales = "free") + theme(legend.position = "none") +
  scale_x_discrete(label=c("Protégé","Risqué","Total")) +
  scale_fill_manual("Type de zone", values=c("protected"="green","risked"="red","total"="darkblue")) +
  labs(x = "", y = "Nombre d'actions")

png("graphs_leader/risk_protected_actions.png", width = 1000, height = 800, res=144)
print(p)
dev.off()
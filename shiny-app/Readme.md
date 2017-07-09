Shiny app : debrefing littoSim
=======================

# Contexte
[Shiny](https://shiny.rstudio.com/)[^1] est un package développé par [Rstudio](https://www.rstudio.com/) et qui permet de transformer un script de traitement R en une application web.

L'objectif de cette application est de permettre l'utilisation de traitement R à la partie debrefing des session de simulation participative. Le traitement doit être transparent pour les utilisateurs tout en permettant la production d'indicteurs (graphique et/ou numérique) facilitant la comprehention des dynamique de la partie.

# Installation

1. Il faut instller [R](https://cran.r-project.org/)[^2] puis [Rstudio](https://www.rstudio.com/)[^3] .
2. Lancer Rstudio et depuis Tools \ Download Package, installer le package "[Shiny](https://shiny.rstudio.com/)"
3. Dans Rstudio copier coller la ligne suivante : `install.packages(c("ggplot2","stringr","dplyr","plyr"), dependencies = T)` et valider Entrer pour installer d'autres packages.
  * Si il y a eu des erreurs lors de l'install, alors faites un chargement de chacun des packages `plyr`, `dplyr`, `stringr`, `ggplot2` l'un après l'autre directement depuis le menu Tools/Install Packages
5. Recommencer plusieurs fois le 3 si vous ne voyer pas les fenetres de Download apparaitre
6- Télécharger depuis le GitHub LIttoSIM l'appli développé pour LittoSIM appelé Shiny-app (`git clone git@github.com:LittoSim/LittoSim_model.git`)
7- Dans RStudio ouvrez les fichier `LittoSim_model/shiny-app/server.R` et `LittoSim_model/shiny-app/ui.R`
8- Puis, dans l'angle superieur droit du script, cliquez sur Run APP

[^1] le code source du package est sur github.
[^2] R est un logiciel (et un langage de programation) distribuer sous licence libre ( Licence [GNU GPL3](https://www.r-project.org/Licenses/LGPL-3))
[^3] RSudio est un logiciel gratuit dans sa version communautaire.

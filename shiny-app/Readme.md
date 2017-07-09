Shiny app : débrefing littoSim
=======================
<div style="text-align:center"><img src ="./www/ShinyLittoSim.png" /></div>

# Contexte

[Shiny](https://shiny.rstudio.com/)<sup>1</sup> est un package développé par [Rstudio](https://www.rstudio.com/) et qui permet de transformer un script de traitement R en une application web.

L'objectif de cette application est de permettre l'utilisation de traitement R à la partie débrefing des sessions de simulation participative. Le traitement doit être transparent pour les utilisateurs tout en permettant la production d'inducteurs (graphique et/ou numérique) facilitant la compréhension des dynamiques de la partie.

# Installation

1. Il faut installer [R](https://cran.r-project.org/)<sup>2</sup> puis [Rstudio](https://www.rstudio.com/)<sup>3</sup> .
2. Lancer Rstudio et depuis Tools \ Download Package, installer le package "[Shiny](https://shiny.rstudio.com/)"
3. Dans Rstudio copier coller la ligne suivante : `install.packages(c("ggplot2","stringr","dplyr","plyr"), dependencies = T)` et valider Entrer pour installer d'autres packages.
  * Si il y a eu des erreurs lors de l'install, alors faites un chargement de chacun des packages `plyr`, `dplyr`, `stringr`, `ggplot2` l'un après l'autre directement depuis le menu Tools/Install Packages
4. Recommencer plusieurs fois l'étape 3 si vous ne voyer pas les fenêtres de Download apparaitre

5- Télécharger depuis le GitHub LIttoSIM l'appli développée pour LittoSIM appelé Shiny-app (`git clone git@github.com:LittoSim/LittoSim_model.git`)

6- Dans RStudio ouvrez les fichiers `LittoSim_model/shiny-app/server.R` et `LittoSim_model/shiny-app/ui.R`

7- Puis, dans l'angle supérieur droit du script, cliquez sur Run APP

# Utilisation

Lancer l'application
![run shiny app](./www/run_app_shiny.png)

Une fenêtre type "browser" et contenant l'interface s'ouvre :
1. charger l'ensemble des fichiers `action done` en maintenant la touche `ctrl` enfoncée
2. si les phases de submersion ont changé, vous pouvez les définir ici
  * Les numéros des tours auxquels ont eu lieu les submersions sont indiqués dans le sous-répertoire "résultats Simu Lisflood" de chacun des répertoire de résultat d'atelier. Vous pouvez les trouver en lisant le nom des sous-sous-répertoire comme par ex. results_R5_t1.494336499043E12 ou results_R10_t1.494339474544E12... ce qui correspond à round(tour) R5 ou R10
  * Les submersions sont déclenchées au début du tour. Par ex, une submersion indiqué R8, correspond à une submersion déclenché par l'opérateur à la fin du Tour7. Lorsque l'opérateur a déclenché la submersion au T7, alors automatiquement le modèle à avancé d'un tour, les actions prévues pour le Tour 8, ont été executées, puis le modèle à lancé la submersion. Une fois la submersion passé, les joueurs ont repris le jeu au Tour 8.
  * Dans la fenêtre de l'appli, écrire  7.5  pour une submersion au Tour 8. Cela fera apparaître une ligne verticale (noir ou rouge), entre le Tour 7 et le Tour 8

3. Une fois les données chargées, vous aurez accès, dans les "onglets" aux différents graphes.
![](./www/ui.desc.png)

# Note
* L'application peut être ouverte dans le navigateur traditionnel en utilisant l'IP afficer en haut de l'interface. Généralement `http://127.0.0.1:5070`.
* Au besoin, les graphes générés peuvent être enregistrés par un clic droit sur les images.


<sup>1</sup> le code source du package est sur github.

<sup>2</sup> R est un logiciel (et un langage de programmation) distribuer sous licence libre ( Licence [GNU GPL3](https://www.r-project.org/Licenses/LGPL-3))

<sup>3</sup> RSudio est un logiciel gratuit dans sa version communautaire.

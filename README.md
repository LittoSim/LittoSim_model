LittoSim
=========

## Mentions légales

### License

<a rel="license" href="http://creativecommons.org/licenses/by-sa/4.0/"><img alt="Licence Creative Commons" style="border-width:0" src="https://i.creativecommons.org/l/by-sa/4.0/80x15.png" /></a><br />Ce(tte) œuvre est mise à disposition selon les termes de la <a rel="license" href="http://creativecommons.org/licenses/by-sa/4.0/">Licence Creative Commons Attribution -  Partage dans les Mêmes Conditions 4.0 International</a>.

### La Team "LittoSim"
Coordinateur du projet : Nicolas Becu


**Par ordre alphabétique** : Brice Anselme, Marion Amalric, Elise Beck , **Nicolas Becu**, Xavier Bertin , Etienne Delay, Nathalie Long, Corinne Manson, Nicolas Marilleau, Cécilia Pignon-Mussaud et Frédéric Rousseaux

## Introduction
Le projet LittoSim vise à construire un jeu sérieux qui se présente sous la forme d’une simulation intégrant à la fois un modèle de submersion marine, la modélisation de différents rôles d’acteurs agissant sur le territoire (collectivités territoriales, association de défense, élus, services de l’État...) et la possibilité de mettre en place différents scénarios de prévention des submersions qui seront contrôlés par les utilisateurs de la simulation en fonction de leur rôle.


## Matériel et méthodes
Le modèle est développé sous [GAMA plateforme](https://code.google.com/p/gama-platform/), couplé à [listflood](http://www.bristol.ac.uk/geography/research/hydrology/models/lisflood/) . Le modèle fonctionne grâce à deux modèles (l'un servant de serveur central, l'autre permettant aux acteurs d'interagir sur un espace commun).
Les deux modèles interagissent grâce à un serveur [Appach ActiveMQ](http://activemq.apache.org/) servant de "boite aux lettres" entre les modèles `participatifs` et le modèle central. On doit donc disposer de toutes ces briques logicielles pour commencer.


### Architecture des fichiers de configuration d'une zone d'étude.
Une zone d'étude est définie par plusieurs fichiers :
* oleron_config.csv
* communes.shp
* contour_neg_100m.shp
* defense_cote.shp
* emprise_ZE.shp
* mnt_2016.asc
* oleron.n.ascii
* PPR.shp
* routes.shp
* trait_cote.shp
* zones.shp
* zps_sic.shp

'oleron_config.csv' est le fichier de paramétrage permettant, entre autre, le chargement des données géographiques.

L'ensemble des autres fichiers sont des données SIG, projetées en RGF93 / Lambert-93 (epsg 2154).

## Architecture du fichier 'communes.shp'
Ce fichier comprend les communes du jeu et correspond au découpage administratif national de la base de données  ADMIN EXPRESS® de l'IGN(découpage adminsitratif) : libre téléchargement  http://professionnels.ign.fr/adminexpress#tab-3 
Deux attributs sont requis : "INSEE_COM" et "id_jeu" qui est à créer :
- "id_jeu" (integer, 1) : 0 : communes affichées, mais non jouées. Valeurs de 1 à n correspondant au numéro des joueurs.
- "INSEE_COM" (string, 5) : code INSEE des communes

## Architecture du fichier 'contour_neg_100m.shp'
Ce fichier correspond à la fusion de toutes les communes ('communes.shp'), afin de ne former qu'une entité géographique avec un buffer intérieur de 100m.
Pas d'attributs requis.

## Architecture du fichier 'defense_cote.shp'
Les attributs requis sont "OBJECTID", "Commune", "INSEE_COM", "type", "Etat_ouvr", "alt" et "hauteur" 
- "OBJECTID" (integer, 10) : identifiant unique
- "Commune" (string, 30) : nom de la commune
- "INSEE_COM" (string, 5) : code INSEE des communes
- "type" (string, 20) : type de défense, 2 types d'occurence possible, soit 'Naturel', soit 'Autre' (exemple pour Oléron : 'Ouvrage longitudinal').
L'occurence 'Naturel' indique que le linéaire est une dune. Toutes les autres occurences différentes de 'Naturel' seront considérées comme des 'Digues'. Si aucun type défini, le modèle le considère, par défaut, comme 'inconnu'.
 - "Etat_ouvr" (string, 20) : état de l'ouvrage : 3 occurences : bon, moyen, mauvais. Si aucun état est renseigné, le modèle le considère comme bon.
- "alt" (real double, 18) : altitude en m (NGF)
- "hauteur" (real double, 10) : hauteur en m de l'ouvrage de défense (de sa fondation à son sommet). Si la hauteur est nulle, alors le modele indique 1.5 m par défaut.
L'attribut facultatif "Nature_def" permet d'identifier les types de côte dans l'interface du jeu (cordon dunaire, cordon de galets, enrochements, etc...)

## Architecture du fichier 'emprise_ZE.shp'
Ce fichier correspond à l'emprise du MNT 'mnt_2016.asc'.
Pas d'attributs requis.

## Architecture du fichier 'mnt_2016.asc'
Ce fichier correspond au MNT qui a été ré-échantillonné, avec un pas de 20m et enrichi avec les données relatives à l'altitude maximum du fichier 'defense_cote_littoSIM-05122015.shp'

## Architecture du fichier 'oleron.n.ascii'
Ce fichier est une grille de pas de 20m, correspondant aux valeurs de rugosité sur la zone d'étude. Les paramètres de rugosité sont définis en fonctions des zones de PLU. Pour plus d'informations sur ces paramètres se référer au fichier 'oleron_config.csv'


## Architecture du fichier 'PPR.shp'
Ce fichier correspond aux zones d'aléa submersion du PPR (exemples : 1B2, B1, B2, R2, R2a)
Pas d'attributs requis.

## Architecture du fichier 'routes.shp'
Ce fichier correspond aux routes principales, telles que les routes départementales.
Pas d'attributs requis.

## Architecture du fichier 'trait_cote.shp'
Ce fichier permet de déterminer différentes zones, par rapport à leur distance au trait de côte (buffer), telle que la zone pour identifier les rétro digues.
Pas d'attributs requis.

## Architecture du fichier 'zones.shp'
Ce fichier correspond à un carroyage de 200x200m et qui regroupe diverses informations.
L'emprise et les limites de ce carroyage doivent se superposer parfaitement avec le MNT.
Les attributs requis sont "FID_1", "grid_code", "Avg_ind_c", "coutexpr"
- "FID_1" (integer, 10) : identifiant unique
- "grid_code" (integer, 10) : 4 occurences correspondant aux zones du PLU. 1=N, 2=U, 4=AU, 5=A.
- "Avg_ind_c" (integer, 10) : le ratio entre le nombre d’habitant dans la commune et la superficie de bâtiments sur chaque carré de 200X200. 
* calculer la superficie de tous les bâtiments sur la commune à usage d'habitation (hors bâtiments industriels, commerciaux et agricoles) correspondant à 100% de la population.
* puis pour chaque carré de 200x200, calculer la surface des bâtiments
* calculer le ratio par carré  : surface des bâtiments/nombre d'habitants
Si une cellule est en zone U, mais si 'Avg_ind_c' = 0, alors le modèle considère qu'il y a 10 habitants.
- "coutexpr" (real, 12) : coût de l'expropriation

## Architecture du fichier 'zps_sic.shp'
Ce fichier correspond aux sites Natura 2000, regroupant les Zones de Protection Spéciale (Z.P.S.) de la directive Oiseaux 79/409/CEE et les Sites d’Importance Communautaire (S.I.C.) de la directive Habitats 92/43/CEE(réseau Natura 2000).
L'attribut requis est "SITECODE" correspondant au nom du site protégé.

LittoSim
=========

## Mentions légales

### License

<a rel="license" href="http://creativecommons.org/licenses/by-sa/4.0/"><img alt="Licence Creative Commons" style="border-width:0" src="https://i.creativecommons.org/l/by-sa/4.0/80x15.png" /></a><br />Ce(tte) œuvre est mise à disposition selon les termes de la <a rel="license" href="http://creativecommons.org/licenses/by-sa/4.0/">Licence Creative Commons Attribution -  Partage dans les Mêmes Conditions 4.0 International</a>.

### La Team "LittoSim"
Coordinateur du projet : Nicolas Becu


**Par ordre alphabetique** : Brice Anselme, Marion Amalric, Elise Beck , **Nicolas Becu**, Xavier Bertin , Etienne Delay, Nathalie Long, Corinne Manson, Nicolas Marilleau, Cécilia Pignon-Mussaud et Frédéric Rousseaux

## Introduction
Le projet LittoSim vise à construire un jeu sérieux qui se présente sous la forme d’une simulation intégrant à la fois un modèle de submersion marine, la modélisation de différents rôles d’acteurs agissant sur le territoire (collectivité territoriale, association de défense, élu, services de l’État...) et la possibilité de mettre en place différents scénarios de prévention des submersions qui seront contrôlées par les utilisateurs de la simulation en fonction de leur rôle.

## Matériel et méthodes

Le modèle est développé sous [GAMA plateforme](https://code.google.com/p/gama-platform/), couplé à [listflood](http://www.bristol.ac.uk/geography/research/hydrology/models/lisflood/) . Le modèle fonctionne grâce à deux modèles (l'un servant de serveur central, l'autre permettant aux acteurs d'interagir sur un espace commun).

Les deux modèles interagissent grâce à un serveur [Appach ActiveMQ](http://activemq.apache.org/) servant de "boite aux lettres" entre les modèles `participatifs` et le modèle central. On doit donc disposer de toutes ces briques logiciel pour commencer.

### Architecture des fichiers de configuration d'une zone d'étude

Une zone d'étude est défini par plusieurs fichiers
* oleron_conf.gaml
* defense_cote_littoSIM-05122015.shp
* ....

#### Architecture du fichier defense_cote_littoSIM-05122015.shp
Les attributs requis sont "OBJECTID" "Type_de_de" "Etat_ouvr" "alt" "hauteur""Commune"
		

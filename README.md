Branche Test Couplage lisflood - LittoSim
=========

## Introduction
Le projet LittoSim vise à construire un jeu sérieux qui se présente sous la forme d’une simulation intégrant à la fois un modèle de submersion marine, la modélisation de différents rôles d’acteurs agissant sur le territoire (collectivité territoriale, association de défense, élu, services de l’Etat...) et la possibilité de mettre en place différents scénarios de prévention des submersions qui seront contrôlés par les utilisateurs de la simulation en fonction de leur rôle.

## Matériel et methodes 

Le modèle est developpé sous [GAMA plateforme](https://code.google.com/p/gama-platform/). Une fois que le téléchargement de GAMA effectué. Lancez Gama une première fois pour que le dossier `gama_workspace` se matérialise dans votre dossier utilisteur.

Une fois que vous disposez du dossier `gama_workspace` vous pouvez cloner le repo github. Pour le moment la gestion de git n'est pas facile dans gama il faudra rocéder à la main. 

```
cd gama_workspace
git clone git@github.com:LittoSim/LittoSim_model.git
```

Dans Gama, il faut mantenant créer un un nouveau projet Gama en effectuant un clique droit sur `user model` -> `new` -> `Gama project`. Cela aura pour effet de créer un nouveau dossier de travail (vide) dans `user model`. En procédant a nouveau d'un clique droit sur notre dossier de modèle vide, nous allons pouvoir importer un système de fichier : `import` -> `File system` et vous pouvez alors choisir le dossier LittoSim téléchargé sur github.

Normalement le système de fichier doit maintenant apparaitre dans le dossier `User modèle` dans l'interface de GAMA.

## Contenu du dossier

Le dépot contient 4 dossier. La documentation est rassembler dans le dossier `doc`. Toutes les données nécessaire aux fonctionnement du modèle sont dans le dossier `includes`.

```
    .
    ├── doc
    │   ├── oleronV1.html
    │   └── snapshots
    ├── images
    ├── includes
	│   ├── batiindiferentie.dbf
	│   ├── batiindiferentie.prj
	│   ├── batiindiferentie.sbn
	│   ├── batiindiferentie.sbx
	│   ├── batiindiferentie.shp
	│   ├── batiindiferentie.shp.xml
	│   ├── ...
	├── models
	│   └── oleronV1.gaml
	└── README.md
```

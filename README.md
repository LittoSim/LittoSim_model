LittoSim
=========

## Introduction
Le projet LittoSim vise à construire un jeu sérieux qui se présente sous la forme d’une simulation intégrant à la fois un modèle de submersion marine, la modélisation de différents rôles d’acteurs agissant sur le territoire (collectivité territoriale, association de défense, élu, services de l’Etat...) et la possibilité de mettre en place différents scénarios de prévention des submersions qui seront contrôlés par les utilisateurs de la simulation en fonction de leur rôle.

## Matériel et methodes 

Le modèle est developpé sous [GAMA plateforme](https://code.google.com/p/gama-platform/). Une fois que le téléchargement de GAMA effectué. Lancez Gama une première fois pour que le dossier `gama_workspace` se matérialise dans votre dossier utilisteur.

Une fois que vous disposez du dossier `gama_workspace` vous pouvez cloner le repo github à l'intérieur : 

```
cd gama_workspace
git clone git@github.com:LittoSim/LittoSim_model.git
```

Normalement le dossier doit maintenant apparaitre dans le dossier `User modèle` dans l'interface de GAMA.

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
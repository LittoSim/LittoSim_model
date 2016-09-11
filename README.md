LittoSim
=========

## License

<a rel="license" href="http://creativecommons.org/licenses/by-sa/4.0/"><img alt="Licence Creative Commons" style="border-width:0" src="https://i.creativecommons.org/l/by-sa/4.0/80x15.png" /></a><br />Ce(tte) œuvre est mise à disposition selon les termes de la <a rel="license" href="http://creativecommons.org/licenses/by-sa/4.0/">Licence Creative Commons Attribution -  Partage dans les Mêmes Conditions 4.0 International</a>.

## Introduction
Le projet LittoSim vise à construire un jeu sérieux qui se présente sous la forme d’une simulation intégrant à la fois un modèle de submersion marine, la modélisation de différents rôles d’acteurs agissant sur le territoire (collectivité territoriale, association de défense, élu, services de l’État...) et la possibilité de mettre en place différents scénarios de prévention des submersions qui seront contrôlées par les utilisateurs de la simulation en fonction de leur rôle.

## Matériel et méthodes

Le modèle est développé sous [GAMA plateforme](https://code.google.com/p/gama-platform/), couplé à [listflood](http://www.bristol.ac.uk/geography/research/hydrology/models/lisflood/) . Le modèle fonctionne grâce à deux modèles (l'un servant de serveur central, l'autre permettant aux acteurs d'interagir sur un espace commun).

Les deux modèles interagissent grâce à un serveur [Appach ActiveMQ](http://activemq.apache.org/) servant de "boite aux lettres" entre les modèles `participatifs` et le modèle central. On doit donc disposer de toutes ces briques logiciel pour commencer.

### Configuration de GAMA

Une fois que le téléchargement de GAMA effectué. Lancez Gama une première fois pour que le dossier `gama_workspace` se matérialise dans votre dossier utilisateur.

Une fois que vous disposez du dossier `gama_workspace` vous pouvez cloner le repo github. Pour le moment la gestion de git n'est pas facile dans Gama il faudra procéder à la main.

```
cd gama_workspace
git clone git@github.com:LittoSim/LittoSim_model.git
```

Dans Gama, il faut maintenant créer un un nouveau projet Gama en effectuant un clique droit sur `user model` -> `new` -> `Gama project`. Cela aura pour effet de créer un nouveau dossier de travail (vide) dans `user model`. En procédant à nouveau d'un clic droit sur notre dossier de modèle vide, nous allons pouvoir importer un système de fichier : `import` -> `File system` et vous pouvez alors choisir le dossier LittoSim téléchargé sur github.

Normalement le système de fichier doit maintenant apparaitre dans le dossier `User modèle` dans l'interface de GAMA.

On a également besoin de d'un plug-in pour permettre la communication entre les deux modèles GAMA et ActiveMQ. Pour cela il faut installer le plug-in `Communicator`. La procédure :

Dans le menu « help », il y a un sous-menu « install new software de gama », on peut alors rentrer l'adresse suivante :

```
https://gama-platform.googlecode.com/svn/update_site/
```

On choisit alors le plug-in `communicator` (attention il faut être vigilant et ne pas tout installer, car il peut y avoir des problèmes de compatibilité).
tu choisis le plug-in network et c’est tout bon

## Contenu du dossier

Le dépôt contient 4 dossiers. La documentation est rassemblée dans le dossier `doc`. Toutes les données nécessaires aux fonctionnements du modèle sont dans le dossier `includes`.

```
    .
├── README.md
├── doc
│   └── oleronV1.html
├── images
│   ├── fond
│   │   ├── fnt.png
│   │   ├── fond_ocean.jpeg
│   │   ├── fond_ocean.png
│   │   ├── terre.png
│   │   └── texture_ocean.jpg
│   ├── icones
│   │   ├── Loupe.png
│   │   ├── Loupe.svg
│   │   ├── agriculture.png
│   │   ├── agriculture.svg
│   │   ├── avec_quadrillage.png
│   │   ├── avec_quadrillage.svg
│   │   ├── digue_entretien.png
│   │   ├── digue_entretien.svg
│   │   ├── digue_rehausse.png
│   │   ├── digue_rehausse.svg
│   │   ├── digue_rehausse_plus.png
│   │   ├── digue_rehausse_plus.svg
│   │   ├── digue_suppression.jpg
│   │   ├── digue_suppression.png
│   │   ├── digue_suppression.svg
│   │   ├── digue_validation.png
│   │   ├── digue_validation.svg
│   │   ├── digueentretien.jpg
│   │   ├── digueentretien.png
│   │   ├── launch_lisflood.png
│   │   ├── one_step.png
│   │   ├── one_step.svg
│   │   ├── sans_quadrillage.png
│   │   ├── sans_quadrillage.svg
│   │   ├── subvention.png
│   │   ├── subvention.svg
│   │   ├── suppression.png
│   │   ├── taxe.png
│   │   ├── taxe.svg
│   │   ├── tree_nature.png
│   │   ├── tree_nature.svg
│   │   ├── urban.png
│   │   ├── urban.svg
│   │   └── validation.png
│   └── mnt
│       ├── dolus.jpg
│       ├── lechateau.jpg
│       ├── saintpierre.jpg
│       └── sainttrojan.jpg
├── includes
│   ├── cout_action.csv
│   ├── lisflood-fp-604
│   │   ├── LISFLOOD-FP user manual.pdf
│   │   ├── hdf5.dll
│   │   ├── hdf5_hl.dll
│   │   ├── libiomp5md.dll
│   │   ├── libmmd.dll
│   │   ├── lisflood.exe
│   │   ├── lisflood_oleron.bat
│   │   ├── msvcp100.dll
│   │   ├── msvcp120.dll
│   │   ├── msvcr100.dll
│   │   ├── msvcr120.dll
│   │   ├── netcdf.dll
│   │   ├── oleron.bci
│   │   ├── oleron.bdy
│   │   ├── oleron.n.ascii
│   │   ├── oleron.par
│   │   ├── oleron.start
│   │   ├── oleron_dem_t0.asc
│   │   ├── results
│   │   │   ├── res-0000.wd
│   │   │   ├── res-0000.wdfp
│   │   │   ├── res-0001.wd
│   │   │   ├── res-0001.wdfp
│   │   │   ├── res-0002.wd
│   │   │   ├── res-0002.wdfp
│   │   │   ├── res-0003.wd
│   │   │   ├── res-0003.wdfp
│   │   │   ├── res-0004.wd
│   │   │   ├── res-0004.wdfp
│   │   │   ├── res-0005.wd
│   │   │   ├── res-0005.wdfp
│   │   │   ├── res-0006.wd
│   │   │   ├── res-0006.wdfp
│   │   │   ├── res-0007.wd
│   │   │   ├── res-0007.wdfp
│   │   │   ├── res-0008.wd
│   │   │   ├── res-0008.wdfp
│   │   │   ├── res-0009.wd
│   │   │   ├── res-0009.wdfp
│   │   │   ├── res-0010.wd
│   │   │   ├── res-0010.wdfp
│   │   │   ├── res-0011.wd
│   │   │   ├── res-0011.wdfp
│   │   │   ├── res-0012.wd
│   │   │   ├── res-0012.wdfp
│   │   │   ├── res.dem
│   │   │   ├── res.inittm
│   │   │   ├── res.mass
│   │   │   ├── res.max
│   │   │   ├── res.maxtm
│   │   │   ├── res.mxe
│   │   │   └── res.totaltm
│   │   ├── svml_dispmd.dll
│   │   ├── vcomp120.dll
│   │   └── zlib.dll
│   ├── participatif
│   │   └── emprise
│   │       ├── dolus.dbf
│   │       ├── dolus.prj
│   │       ├── dolus.sbn
│   │       ├── dolus.sbx
│   │       ├── dolus.shp
│   │       ├── dolus.shp.xml
│   │       ├── dolus.shx
│   │       ├── lechateau.dbf
│   │       ├── lechateau.prj
│   │       ├── lechateau.sbn
│   │       ├── lechateau.sbx
│   │       ├── lechateau.shp
│   │       ├── lechateau.shp.xml
│   │       ├── lechateau.shx
│   │       ├── saintpierre.dbf
│   │       ├── saintpierre.prj
│   │       ├── saintpierre.sbn
│   │       ├── saintpierre.sbx
│   │       ├── saintpierre.shp
│   │       ├── saintpierre.shp.xml
│   │       ├── saintpierre.shx
│   │       ├── sainttrojan.dbf
│   │       ├── sainttrojan.prj
│   │       ├── sainttrojan.sbn
│   │       ├── sainttrojan.sbx
│   │       ├── sainttrojan.shp
│   │       ├── sainttrojan.shp.xml
│   │       └── sainttrojan.shx
│   ├── scripts
│   │   ├── population_shape.R
│   │   └── qgis_color_attribut.py
│   ├── zone_etude
│   │   ├── communes.dbf
│   │   ├── communes.prj
│   │   ├── communes.shp
│   │   ├── communes.shp.xml
│   │   ├── communes.shx
│   │   ├── defense_cote_littoSIM-05122015.dbf
│   │   ├── defense_cote_littoSIM-05122015.prj
│   │   ├── defense_cote_littoSIM-05122015.qpj
│   │   ├── defense_cote_littoSIM-05122015.shp
│   │   ├── defense_cote_littoSIM-05122015.shx
│   │   ├── emprise_ZE_littoSIM.dbf
│   │   ├── emprise_ZE_littoSIM.prj
│   │   ├── emprise_ZE_littoSIM.shp
│   │   ├── emprise_ZE_littoSIM.shx
│   │   ├── mnt_corrige.asc
│   │   ├── routesdepzone.prj
│   │   ├── routesdepzone.sbn
│   │   ├── routesdepzone.sbx
│   │   ├── routesdepzone.shp
│   │   ├── routesdepzone.shp.xml
│   │   ├── routesdepzone.shx
│   │   ├── zones241115.dbf
│   │   ├── zones241115.prj
│   │   ├── zones241115.sbn
│   │   ├── zones241115.sbx
│   │   ├── zones241115.shp
│   │   └── zones241115.shx
│   └── zone_restreinte
│       ├── cadre.dbf
│       ├── cadre.prj
│       ├── cadre.qpj
│       ├── cadre.shp
│       ├── cadre.shx
│       ├── contour.dbf
│       ├── contour.prj
│       ├── contour.qpj
│       ├── contour.shp
│       ├── contour.shx
│       ├── mnt.asc
│       └── mnt.prj
└── models
    ├── oleronV1.gaml
    ├── participatif.gaml
    └── results
        ├── Carte_Amenagement_t0.png
        ├── Carte_DEM_t0.png
        ├── Carte_Pop_t0.png
        ├── Carte_inondation_quadrillage_t0.png
        ├── Carte_inondation_t0.png
        ├── Stats_inondation_Barplots_t0.png
        └── Stats_inondation_texte_t0.png

```

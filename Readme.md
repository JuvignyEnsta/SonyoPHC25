# Raptalien



## CARACTERISTIQUES PHC 25

### PORTS CLAVIER

- **Fleche gauche** : port 130 devient 239 (255 - 16)
- **Fleche droite** : port 131 devient 239 (255 - 16)
- **Espace**        : port 131 devient 127 (255 - 128)
- **Espace + fleche droite** donne port 131 égal à 111 (255 - 16 - 128)
- **Entree** : port 129 devient égal à 223 (255 - 32)


## Utilitaires PHC 25

### SCan des ports pour correspondance clavier en basic :

```basic
10 FOR i=0 TO 255
20 X = INP(I)
30 IF X <> 255 THEN PRINT I " : "; X;", ";
40 NEXT I
45 PRINT
50 GOTO 10
```

### Editeur de Sprite basique

```sprite_editor.py``` est un petit éditeur de sprite en Python qui utilise la bibliothèque `pygame`. Il permet de créer et d'enregistrer des images de sprite dont le format est compatible avec le mode graphique 4 du Sonyo PHC 25. 

Pour commencer une nouvelle bibliothèque de sprite, vous pouvez rajouter des options à la ligne de commande afin de  :

- Spécifier le nom du projet : ``--filename=<nom du projet>``
- Spécifier le nombre de frames par sprite : ``--nbframes=<entier>``
- Spécifier la taille des sprites : ``--size=<largeur>x<hauteur>``
- Spécifier la palette du phc 25 à utiliser : ``--palette=[0-3]`` (quatre palettes possibles)
- Spécifier pour la génération du basic le début de ligne : ``--begline=<entier>``


A droite, vous trouverez cinq "boutons" :

- `New sprite` vous permet en cliquant dessus de créer un nouveau sprite. Chaque sprite est composé de plusieurs frames (quatre pour mon besoin)
- `Gen. Frames` permet de répliquer l'image du premier frame aux autres frames du sprite en décalant d'un pixel sur la droite l'image (afin d'avoir un déplacement horizontal fluide dans le jeu).
- `Load sprites` vous permet de charger votre dernière session de travail (nom du fichier fixé dans le script mais qu'on peut bien sûr modifié)
- `Save sprites` vous permet de sauvegarder votre session de travail
- `Gen. Data` vous permet de sauvegarder vos sprites sous forme de listing basique à l'aide de l'instruction DATA. 

En bas, on trouve différents boutons :
   - Les flèches aux extrémités permettent de passer d'un sprite (et ses frames) au sprite précédent ou suivant.
   - Les deux flèches haut et bas permettent de passer d'une frame à une autre (haut prochaine, bas précédente)
   - La flèche verte permet de lancer l'animation
   - Le carré rouge de l'arrêter.


Pour l'instant, il manque la routine permettant l'affichage du sprite mais l'organisation mémoire du PHC 25 est simple puisque linéaire avec les pixels regroupés par quatre dans chaque octets (par bloc de 2 bits par pixel).

Ainsi, pour afficher un sprite, il suffit pour chaque groupe de quatre pixel sur une même ligne d'écrire en incrémentant la mémoire et de rajouter 32 à l'adresse mémoire du premier groupe de pixel pour passer à la ligne suivante.

### Librairie pour la gestion des sprites

### API

La librairie `libsprite` permet de gérer un nombre fixe de sprites sur le PHC 25. Elle comprend les fonctions suivantes :

- ``void initSprtTab()`` : Initialise la table des sprites
- ``void undrawSprt(unsigned char i)`` : Efface le ième sprite de l'écran
- ``void undrawSprts()``: Efface tous les sprites de l'écran 
- ``void drawSprts()`` : Dessine tous les sprites actifs à l'écran 
- ``uchar addSprt(uchar kind, uchar x, uchar y)`` : Rajoute un sprite actif à la liste des sprites actifs

### Organisation mémoire

Chaque sprite dans le tableau des sprites prend quatre octets en mémoire selon l'organisation suivante (User signifie que ce bit n'a pas de rôle dans la bibliothèque et est donc à la disposition de l'utilisateur pour sa propre gestion des données du sprite):

- Premier octet :
  ----
  | bits | 7 | 6-4 | 3-0 |
  |------|---|-----|-----|
  | **Rôle** | Actif | User | n° sprite |
  ----

  Le n° de sprite étant la position indicielle des graphismes (avec les frames) du sprite dans le tableau des graphismes.


- Second et troisième octets (16 bits)
  ----
  | bits | 15 | 14-7 | 6- 2 | 1 - 0 |
  |------|----|------|-------|---------|
  | **Rôle** | User | pos Y | pos X | n° frame |
  ----

  - **pos Y** est la position verticale en pixel du sprite sur l'écran
  - **pos X** est la position horizontale en paquet de quatre pixels sur l'écran
  - **n° frame** est le numéro de la frame à afficher (0 à 3)

    **Remarque 1** : La position X est en paquet de quatre pixels pour calculer facilement l'adresse vidéo où commence le sprite. Si le n° du frame correspond à un décalage vers la droite du sprite, la position x plus le n° du frame peut donc être vu comme une position horizontale en pixel.

    **Remarque 2** : En masquant le 15 bits (à zéro) et en décalant de deux bits sur la droite ces deux octets, on obtient directement l'adresse vidéo où commence l'affichage du sprite

- Quatrième octets : A la disposition de l'utilisateur

Le choix de quatre octets pour décrire un sprite vient du fait qu'il est plus facile de trouver rapidement la position du ième sprite dans la table que si on avait utiliser trois octets, permettant un traitement plus rapide des sprites.

## Histoire

**Année 2194**. L'humanité vient de fonder une nouvelle colonie sur une planète extra-solaire, à plusieurs années-lumière de la Terre.
Malheureusement, après que la colonie ait trouvé un gisement d'un minerai très rare servant aux voyages interstellaires, le puissant 
empire Protéien a décidé d'envahir votre nouvelle colonie en enlevant les colons pour en faire des esclaves dans les nouvelles mines.

A bord de votre vaisseau spatial, vous êtes le dernier pilote pouvant défendre la colonie contre les vaisseaux Protéiens qui cherchent
à enlever les colons pour en faire leurs esclaves. Vous devez donc piloter votre vaisseau spatial et détruire autant que possible les vaisseaux ennemis
avant que ces derniers enlèvent vos colons. 

## Principe du jeux

Des vaisseaux ennemis sont générés aléatoirement en haut de l'écran et se dirigent dans un premier temps vers le bas en zigzagant parfois afin d'aller capturer un colon. Vous pouvez bien sûr les abbattre avant qu'ils ne puissent atteindre la colonie représentée par le bas de l'écran. Une fois capturer un colon, le vaisseau de part vers le haut de l'écran, mais la vie de vos colons étant très précieuses, il vous faudra éviter de détruire les vaisseaux portant des colons sous peine de se voir pénaliser dans votre score. Ces vaisseaux se reconnaissent car ils se dirigent vers le haut.

Votre canon a un nombre limité de missiles simultanés (six) traduisant le fait qu'il faut un certain temps à votre canon pour refroidir avant de pouvoir à nouveau tirer des missiles. Par ailleurs, vous disposez pour toute la session de jeu de trois bombes magnétiques qui éliminent tous les ennemis de l'écran (même ceux contenant des colons dont attention !).

Vous perdez la partie lorsque :
    - Soit vous rentrez en collision avec un vaisseau ennemi
    - Soit tous vos colons ont été enlevés par les ennemis.

Remarque : Vous commencez la partie avec 10 colons en mode facile, 5 en mode normal et 3 en mode difficile.

Les vaisseaux ennemis :

    - **Les droppers** : Vaisseaux ennemis assez primitifs qui profitent essentiellement de la gravité pour tomber tout droit lourdement sur la planète. Ils dévient rarement de leurs trajectoire afin d'économiser leur carburants.
    - **Les chasseurs** : Vaisseaux ennemis plus sophistiqués qui ont la capacité de pouvoir changer de direction bien plus fréquemment que les droppers.
    - **Les quantiums"" : Vaisseaux ennemis possédant une technologie avancée leur permettant de créer un champs quantique qui les téléporte après avoir accumulé assez d'énergie aléatoirement sur une altitude légèrement plus basse mais aléatoire quant à l'horizon (gauche à droite de l'écran).
    
## Les différents niveaux

### Premier niveau

Temps que le score est inférieur à 120, que des droppers qui augmentent en nombre au fur et à mesure que le score augmente (cinq points par droppers abbatus, le nombre de droppers présents sur l'écran est égal au score divisé par vingt + 1).

### Deuxième niveau

Tant que le score est inférieur à 500, le nombre de droppers reste constant (cinq droppers) mais des chasseurs (10 points par chasseurs abbatus) apparaissent au nombre égal à (score-120)/100.

### Troisième niveau

Le nombre de droppers et de chasseurs restent constant (cinq droppers et trois chasseurs), mais à 500 points un quantium peut apparaître à l'écran, puis deux à 750 points.

A partir de 1000 points, et tous les cinq cents points, le temps d'apparition et de disparition des quantiums diminue. (augmentation de la vitesse du jeu ?)


## Histoire

**Année 2194**. L'humanité vient de fonder une nouvelle colonie sur une planète extra-solaire, à plusieurs années-lumière de la Terre.
Malheureusement, après que la colonie ait trouvé un gisement d'un minerai très rare servant aux voyages interstellaires, le puissant 
empire Protéien a décidé d'envahir votre nouvelle colonie en enlevant les colons pour en faire des esclaves dans les nouvelles mines.

A bord de votre vaisseau spatial, vous êtes le dernier pilote pouvant défendre la colonie contre les vaisseaux Protéiens qui cherchent
à enlever les colons pour en faire leurs esclaves. Vous devez donc piloter votre vaisseau spatial et détruire autant que possible les vaisseaux ennemis
avant que ces derniers enlèvent vos colons. 

## Principe du jeux

Des vaisseaux ennemis sont générés aléatoirement en haut de l'écran et se dirigent dans un premier temps vers le bas en zigzagant parfois afin d'aller capturer un colon. Vous pouvez bien sûr les abbattre avant qu'ils ne puissent atteindre la colonie représentée par le bas de l'écran. Une fois capturer un colon, le vaisseau de part vers le haut de l'écran, mais la vie de vos colons étant très précieuses, il vous faudra éviter de détruire les vaisseaux portant des colons sous peine de se voir pénaliser dans votre score. Ces vaisseaux se reconnaissent car ils se dirigent vers le haut.

Votre canon a un nombre limité de missiles simultanés (six) traduisant le fait qu'il faut un certain temps à votre canon pour refroidir avant de pouvoir à nouveau tirer des missiles. Par ailleurs, vous disposez pour toute la session de jeu de trois bombes magnétiques qui éliminent tous les ennemis de l'écran (même ceux contenant des colons dont attention !).

Vous perdez la partie lorsque :
    - Soit vous rentrez en collision avec un vaisseau ennemi
    - Soit tous vos colons ont été enlevés par les ennemis.

Remarque : Vous commencez la partie avec 10 colons en mode facile, 5 en mode normal et 3 en mode difficile.

Les vaisseaux ennemis :

    - **Les droppers** : Vaisseaux ennemis assez primitifs qui profitent essentiellement de la gravité pour tomber tout droit lourdement sur la planète. Ils dévient rarement de leurs trajectoire afin d'économiser leur carburants.
    - **Les chasseurs** : Vaisseaux ennemis plus sophistiqués qui ont la capacité de pouvoir changer de direction bien plus fréquemment que les droppers.
    - **Les quantiums"" : Vaisseaux ennemis possédant une technologie avancée leur permettant de créer un champs quantique qui les téléporte après avoir accumulé assez d'énergie aléatoirement sur une altitude légèrement plus basse mais aléatoire quant à l'horizon (gauche à droite de l'écran).
    
## Les différents niveaux

### Premier niveau

Temps que le score est inférieur à 120, que des droppers qui augmentent en nombre au fur et à mesure que le score augmente (cinq points par droppers abbatus, le nombre de droppers présents sur l'écran est égal au score divisé par vingt + 1).

### Deuxième niveau

Tant que le score est inférieur à 500, le nombre de droppers reste constant (cinq droppers) mais des chasseurs (10 points par chasseurs abbatus) apparaissent au nombre égal à (score-120)/100.

### Troisième niveau

Le nombre de droppers et de chasseurs restent constant (cinq droppers et trois chasseurs), mais à 500 points un quantium peut apparaître à l'écran, puis deux à 750 points.

A partir de 1000 points, et tous les cinq cents points, le temps d'apparition et de disparition des quantiums diminue. (augmentation de la vitesse du jeu ?)

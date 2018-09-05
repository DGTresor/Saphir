# Modèle Saphir

Le modèle de microsimulation Saphir est un outil d’évaluation de politiques publiques. 
Il décrit les revenus des ménages de France métropolitaine et les transferts monétaires induits par les prestations sociales et les prélèvements obligatoires. 
Il permet notamment de réaliser des évaluations ex ante de réformes de la législation socio-fiscale.

Cette version du modèle est conçue pour pouvoir être représentative de l'année 2017.

En aucun cas il ne pourra être considéré que ce modèle indique la position de l'administration sur l'interprétation de la législation fiscale ou sociale ou toute autre question et lui être opposable.
En particulier, les paramètres de la législation socio-fiscale et leur application ne sauraient constituer une norme de référence sociale ou fiscale. 


# Logiciel

L'utilisation du modèle Saphir se fait à l'aide du logiciel SAS, commercialisé par SAS Institute (http://www.sas.com).


# Données

Le modèle Saphir est fondé sur l’Enquête revenus fiscaux et sociaux (ERFS) de l'Insee, accessible via le Centre d'Accès Sécurisé aux Données (CASD, https://www.casd.eu).


# Guide d'utilisation du modèle Saphir

Le fonctionnement du modèle est décrit en détail dans le document de travail de la DG Trésor intitulé « Le modèle de microsimulation Saphir ».

Les variables de base sont décrites dans la documentation de l’ERFS, disponible via le CASD.


# Utilisation du modèle

Pour faire tourner le modèle, il suffit d'exécuter le programme "Lancement.sas", qui exécute l'ensemble des programmes de Saphir. 
Chacun des programmes comporte en en-tête un descriptif des tâches effectuées.

~ Première utilisation (création du scénario de référence)

Avant de pouvoir simuler des scénarios de réforme, il est nécessaire de construire d'abord le scénario de référence correspondant à la législation en vigueur l'année de référence. 

Lors de la première utilisation, il faut au préalable :
- Renseigner les chemins des répertoires contenant les tables en entrée (tables de l'ERFS et de l'Enquête emploi), les programmes et les tables en sortie dans le programme "Lancement.sas".
- Renseigner le fichier "parametres.xls" contenant les coefficients de vieillissement des revenus, les marges de calage de l'échantillon ainsi que les cibles des foyers bénéficiaires de la prime d'activité. Par défaut, les coefficients de vieillissement sont initialisés à 0, les marges de calage sont définies de manière endogène (issues de l'ERFS) et des cibles arbitrairement élevées de bénéficiaires du RSA et de la prime d’activité sont pré-remplies (ce qui correspond à une hypothèse de plein recours). 
- Définir à 1 la macro-variable "recalcul", de manière à déterminer les recourants au RSA et à la prime d'activité.

~ Utilisations suivantes (création de variantes)

Pour simuler un scénario de modification de la législation socio-fiscale, il suffit d'exécuter les programmes 7a à 15 modifiés (inutile d'exécuter les programmes 1 à 6 relatifs à la partie socle du modèle). 

Les tables relatives au nouveau scénario seront stockées dans le répertoire associé à la librairie "scenario".

Pour comparer ce nouveau scénario au scénario de référence, il est possible d'attribuer aux individus le même comportement de recours à la prime d'activité et au RSA dans le scénario de réforme que dans le scénario de référence, en définissant la macro-variable "recalcul" à 0.
Il est alors nécessaire de définir une librairie contenant les variables de recours du scénario de référence : lorsque la macro-variable recalcul est égale à 0, le chemin de la librairie "central" doit pointer vers le dossier contenant les tables du scénario de référence.


# Résultats

Les tables de la partie socle de Saphir (issues des programmes 1 à 6) sont stockées dans le dossier "Tables Revenu brut".

Les tables de scénario de législation socio-fiscale (issues des programmes 7a à 15) sont stockées dans le dossier "Tables Revenu disponible". 


# Licence

Ce logiciel est régi par la licence CeCILL V2.1 soumise au droit français et respectant les principes de diffusion des logiciels libres. 

Vous pouvez utiliser, modifier et/ou redistribuer ce programme sous les conditions de la licence CeCILL V2.1. 

Le texte complet de la licence CeCILL V2.1 est disponible dans le fichier `LICENSE`.

Les paramètres de la législation socio-fiscale figurant dans les programmes 6, 7a et 7b sont régis par la « Licence Ouverte / Open License » Version 2.0.
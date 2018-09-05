/********************************************************************************************************************************************
************************************************* LANCEMENT DE SAPHIR 2017 ******************************************************************
********************************************************************************************************************************************/

/********************************************************************************************************************************************
******************************************** I. Definition des paramètres *******************************************************************
*********************************************************************************************************************************************/

/*Attention! Le séparateur décimal d'Excel doit être "." pour que l'interaction avec SAS fonctionne correctement.*/

/*chemins à configurer par l'utilisateur*/
%let chemin_ERFS_2013=...;	/*Répertoire contenant les tables de l'ERFS 2013 (Accessibles à partir du CASD) */
%let chemin_EEC_2013=...;	/*Répertoire contenant les tables de l'Enquête Emploi 2013 (Accessibles à partir du CASD)*/
%let chemin_Saphir_2017=...;/*Répertoire contenant les programmes, les fichiers Excel en input et les tables créées par le modèle */


/*Définition des librairies*/
libname erfs "&chemin_ERFS_2013.";
libname erfs_c "&chemin_ERFS_2013.\Tables complémentaires";
libname eec "&chemin_EEC_2013.";

libname saphir "&chemin_Saphir_2017.\Tables_Revenu_brut"; 		/*Contient les tables de la partie socle de Saphir*/
libname scenario "&chemin_Saphir_2017.\Tables_Revenu_disponible"; 	/*A changer pour chaque nouveau scénario*/




/*Définition des années de perception des revenus*/
%let aprec=12;
%let acour=13; /*Année de l'ERFS sous-jacente à cette version de Saphir*/                                                                                     
%let asuiv=14;
%let asuiv2=15;
%let asuiv3=16;
%let asuiv4=17;


/*Macro définissant les marges de calage*/
/* 0 : l'utilisateur renseigne lui-même les marges de calage dans le fichier parametres.xls  */
/* 1 : les marges sont définies par défaut de manière endogène */
%let calage_par_defaut=1;

/*Macro définissant le mode de calcul du recours à la prime et au RSA  */ 
/* 0 : récupération des variables de recours dans un scénario de référence, stocké dans la librairie "central"  */
/* 1 : recalcul du recours dans la variante (option par défaut à utiliser notamment en première utilisation du modèle)  */
%let recalcul=1 ; 	
libname central "&chemin_Saphir_2017.\Tables_Revenu_disponible"; /*Librairie contenant la table "non_recours" du scénario de référence,
	utilisée uniquement si recalcul=0 (chemin à modifier le cas échéant)
	(permet de conserver, dans le programme 14, les mêmes recourants à la prime d'activité et au RSA que dans le scénario de référence)*/


/********************************************************************************************************************************************
*********************************************** II. Execution du modèle *********************************************************************
*********************************************************************************************************************************************/



/*A lancer pour la construction de Saphir (partie socle)*/
%include "&chemin_Saphir_2017.\Programmes\1-Correction_donnees_et_variables_auxiliaires.sas";
%include "&chemin_Saphir_2017.\Programmes\2-Vieillissement_revenus.sas";
%include "&chemin_Saphir_2017.\Programmes\3-Calage_sociodemo.sas";
%include "&chemin_Saphir_2017.\Programmes\4-Calendrier_professionnel.sas";
%include "&chemin_Saphir_2017.\Programmes\5-Mise_en_commun_infos_indiv_et_menage.sas";
%include "&chemin_Saphir_2017.\Programmes\6-Definition_revenus_bruts.sas";


/*A lancer pour la construction du revenu disponible (application de la législation socio-fiscale)*/

dm log 'clear' editor;
%include "&chemin_Saphir_2017.\Programmes\7a-Legislation_sociale.sas";
%include "&chemin_Saphir_2017.\Programmes\7b-Legislation_IR.sas";

dm log 'clear' editor;
%include "&chemin_Saphir_2017.\Programmes\8a-Calcul_CSG_CRDS_cotis_2015_2016.sas";
%include "&chemin_Saphir_2017.\Programmes\8b-Calcul_de_l'impot_sur_le_revenu_2016.sas";

dm log 'clear' editor;
%include "&chemin_Saphir_2017.\Programmes\9a-Calcul_CSG_CRDS_cotis_2017.sas";
%include "&chemin_Saphir_2017.\Programmes\9b-Calcul_de_l'impot_sur_le_revenu_2017.sas";
%include "&chemin_Saphir_2017.\Programmes\10-Calcul_de_l'impot_simplifie_2017.sas";

dm log 'clear' editor;
%include "&chemin_Saphir_2017.\Programmes\11-Prestations_21ans_(CF,forfait,AL).sas";
%include "&chemin_Saphir_2017.\Programmes\12-Prestations_20ans.sas";
%include "&chemin_Saphir_2017.\Programmes\13-RSA_PA.sas";

dm log 'clear' editor;
%include "&chemin_Saphir_2017.\Programmes\14-Non_recours_RSA_PA.sas"; 	
%include "&chemin_Saphir_2017.\Programmes\15-Mise_en_commun.sas";


/*Pour nettoyer la work et libérer de l'espace*/
proc datasets kill; quit;


/********************************************************************************************************************************************
*********************************************************************************************************************************************

Ce logiciel est régi par la licence CeCILL V2.1 soumise au droit français et respectant les principes de diffusion des logiciels libres. 

Vous pouvez utiliser, modifier et/ou redistribuer ce programme sous les conditions de la licence CeCILL V2.1. 

Le texte complet de la licence CeCILL V2.1 est dans le fichier `LICENSE`.

Les paramètres de la législation socio-fiscale figurant dans les programmes 6, 7a et 7b sont régis par la « Licence Ouverte / Open License » Version 2.0.
********************************************************************************************************************************************
********************************************************************************************************************************************/

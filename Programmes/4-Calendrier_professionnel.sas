

/**************************************************************************************************************************************************************/
/*                              									  SAPHIR E2013 L2017                                  							          */
/*                                     									  PROGRAMME 4                                         			     			      */
/*                           							Reconstruction des trajectoires professionnelles													  */
/**************************************************************************************************************************************************************/

/**************************************************************************************************************************************************************/
/* Afin de pouvoir calculer le niveau des prestations d’un ménage, il est nécessaire de connaître au niveau mensuel le statut d’activité de ses membres et	  */
/* leur temps de travail. En effet, certaines prestations dépendent de la quotité travaillée et de la répartition mensuelle des revenus. 					  */
/* Un calendrier rétrospectif d’activité mensuel est donc construit à partir des données de l’ERFS dans ce programme. 										  */
/*																																							  */
/* Les informations utilisées sont celles qui sont disponibles dans l’EEC selon le rang d’interrogation. On dispose d’une information mensuelle uniquement sur*/ 
/* le statut d’activité des 12 mois précédent la première interrogation de l’EEC. On complète cette information mensuelle grâce à l’information trimestrielle,*/ 
/* recueillie lors de chaque interrogation. 																												  */
/* Ce fichier est composé de deux parties :																													  */
/*		- la première partie contruit une variable de temps de travail hebdomadaire redressé et imputé														  */
/*		- la seconde partie contruit un calendrier d'activité mensuel (mois travaillés ou non)																  */
/**************************************************************************************************************************************************************/



/**************************************************************************************************************************************************************/
/**************************************************************************************************************************************************************/
/*                       								I. Redressement et imputation du temps de travail	                 							      */
/**************************************************************************************************************************************************************/
/**************************************************************************************************************************************************************/

/**************************************************************************************************************************************************************/
/* Construction de la variable nbheur_prev : temps de travail hebdomadaire habituel redressé et imputé									                      */
/**************************************************************************************************************************************************************/


/**************************************************************************************************************************************************************/
/*				1- Homogénéisation des variables										                 												      */
/**************************************************************************************************************************************************************/

/*Données par année : taux de cotisation, Smic, plafond de la Sécurité Sociale*/
/*		2012						2013						2014		  */
%let TCSS_12 =21.56 ; 		%let TCSS_13 =21.7 ; 		%let TCSS_14 =21.91 ;
%let TCSS_P3P_12 =20.01 ; 	%let TCSS_P3P_13 =20.01 ; 	%let TCSS_P3P_14 =20.2 ;
%let TCSS_3P4P_12 =11.01 ; 	%let TCSS_3P4P_13 =11.11 ; 	%let TCSS_3P4P_14 =11.3 ; 
%let TCSS_4P_12 =8.61 ; 	%let TCSS_4P_13 =8.71 ; 	%let TCSS_4P_14 =8.71 ; 

%let TCSC_12 =21.59 ; 		%let TCSC_13 =21.82 ; 		%let TCSC_14 =21.9 ; 
%let TCSC_P3P_12 =19.76 ; 	%let TCSC_P3P_13 =19.8 ; 	%let TCSC_P3P_14 =19.9 ; 
%let TCSC_3P4P_12 =19.76 ; 	%let TCSC_3P4P_13 =19.8 ; 	%let TCSC_3P4P_14 =19.9 ;
%let TCSC_4P_12 =16.42 ; 	%let TCSC_4P_13 =16.42 ; 	%let TCSC_4P_14 =16.42 ;

%let Smic_121 =9.22 ; %let Smic_122 =9.4 ;/*moyenne annuelle*/; %let Smic_12 =9.31 ;
							%let Smic_13 =9.43 ; 		%let Smic_14 =9.53 ;
%let Smic_h_net_12=7.29; 	%let Smic_h_net_13=7.39;
%let Plafond_SS_12 = 3031 ; %let Plafond_SS_13 =3086 ; 	%let Plafond_SS_14 =3129 ;

/*On récupère les variables utilisées, qui sont homogénéisées entre 2012 et 2013*/
/*QUART : date du trimestre de référence en nombre de trimestres depuis 1960, pour empiler les trimestres dans une même database*/

%macro hdata(a= ,t=, listvar=, bibli=); 

%if &a.=%sysevalf(&acour.) and &t.= 4 %then %let tabin=irf&acour.e&a.t&t. ;
%else %let tabin=icomprf&acour.e&a.t&t. ;

data pass_&a.t&t. (keep=ident&acour. noi &listvar.);
set &bibli..&tabin. ; 

year = &a. ; quart = %eval(159+4*&a.+&t.) ; /*année et trimestre de la base de données d'origine*/

%if &a. <=12 %then %do ; 									
	nbjtrref = jtrref ; nafg = nafg38n ; typmen = typmen15 ; txtppred=txtppb ;
	if nbsalb='0' then nbsalb=' ' ; if nbsalb='5' then nbsalb='4' ; if nbsalb in ('6', '7') then nbsalb='5' ; 
	if nbsalb in ('8', '9') then nbsalb='6' ; if nbsalb='99' then nbsalb=' ' ;  
	if retrai ='1' then do ; ret ='1' ; preret ='2' ; end ; if retrai ='2' then do ; ret ='2' ; preret ='1' ; end ; 
	if retrai ='3' then do ; ret ='2' ; preret ='2' ; end ;
	hhc = 		int(hhc) + (hhc-int(hhc))*100/60 ; 
	empnbh = 	int(empnbh) + (empnbh-int(empnbh))*100/60 ;
	totnbh = 	int(totnbh) + (totnbh-int(totnbh))*100/60 ;
	emphnh = 	int(emphnh) + (emphnh-int(emphnh))*100/60 ;
	emphre = 	int(emphre) + (emphre-int(emphre))*100/60 ;
	hhchsup = emphnh ;
	if empafc ne ' ' 	then empafc = 	(substr(empafc, length(empafc), 1) ='H')*input(substr(empafc, 1, length(empafc)-1), 2.) + 7.5*(substr(empafc, length(empafc), 1) ='J')*input(substr(empafc, 1, length(empafc)-1), 1.) ;
	if empafg ne ' ' 	then empafg = 	(substr(empafg, length(empafg), 1) ='H')*input(substr(empafg, 1, length(empafg)-1), 2.) + 7.5*(substr(empafg, length(empafg), 1) ='J')*input(substr(empafg, 1, length(empafg)-1), 1.) ;
	if empafa ne ' ' 	then empafa = 	(substr(empafa, length(empafa), 1) ='H')*input(substr(empafa, 1, length(empafa)-1), 2.) + 7.5*(substr(empafa, length(empafa), 1) ='J')*input(substr(empafa, 1, length(empafa)-1), 1.) ;
	if empco ne ' ' 	then empco = 	(substr(empco, length(empco), 1) ='H')*input(substr(empco, 1, length(empco)-1), 2.) + 7.5*(substr(empco, length(empco), 1) ='J')*input(substr(empco, 1, length(empco)-1), 1.) ;
	if empce ne ' ' 	then empce = 	(substr(empce, length(empce), 1) ='H')*input(substr(empce, 1, length(empce)-1), 2.) + 7.5*(substr(empce, length(empce), 1) ='J')*input(substr(empce, 1, length(empce)-1), 1.) ;
	if empjf ne ' ' 	then empjf = 	(substr(empjf, length(empjf), 1) ='H')*input(substr(empjf, 1, length(empjf)-1), 2.) + 7.5*(substr(empjf, length(empjf), 1) ='J')*input(substr(empjf, 1, length(empjf)-1), 1.) ;
	if emppa ne ' ' 	then emppa = 	(substr(emppa, length(emppa), 1) ='H')*input(substr(emppa, 1, length(emppa)-1), 2.) + 7.5*(substr(emppa, length(emppa), 1) ='J')*input(substr(emppa, 1, length(emppa)-1), 1.) ;
	if emprtt ne ' ' 	then emprtt = 	(substr(emprtt, length(emprtt), 1) ='H')*input(substr(emprtt, 1, length(emprtt)-1), 2.) + 7.5*(substr(emprtt, length(emprtt), 1) ='J')*input(substr(emprtt, 1, length(emprtt)-1), 1.) ;
	if empafp ne ' ' 	then empafp = 	(substr(empafp, length(empafp), 1) ='H')*input(substr(empafp, 1, length(empafp)-1), 2.) + 7.5*(substr(empafp, length(empafp), 1) ='J')*input(substr(empafp, 1, length(empafp)-1), 1.) ;
	if empcp ne ' ' 	then empcp = 	(substr(empcp, length(empcp), 1) ='H')*input(substr(empcp, 1, length(empcp)-1), 2.) + 7.5*(substr(empcp, length(empcp), 1) ='J')*input(substr(empcp, 1, length(empcp)-1), 1.) ;
	if empanh ne ' ' 	then empanh = 	(substr(empanh, length(empanh), 1) ='H')*input(substr(empanh, 1, length(empanh)-1), 2.) + 7.5*(substr(empanh, length(empanh), 1) ='J')*input(substr(empanh, 1, length(empanh)-1), 1.) ;
	if ancchomm =. then ancchomm = ancinatm ; 

	if empaff='1' then empaffm1='1';
	if empaff='2' then empaffm2='1';
	if empaff='3' then empaffm3='1';
	if empaff='4' then empaffm4='1';

	nbtot=.;

	datqi=datcoll;

%end ;

%else %if &a. >12 %then %do ;
	nafn = nafun ; nafg = nafg038n ; 
	if nbsalb in ('1', '2', '3', '4') then nbsalb='2' ; 
	if nbsalb='0' then nbsalb='1' ; if nbsalb in ('5', '6', '7', '8', '9') then nbsalb='3' ; if nbsalb='10' then nbsalb='4' ; 
	if nbsalb='11' then nbsalb='5' ; if nbsalb='12' then nbsalb='6' ; if nbsalb in ('13', '99') then nbsalb=' ' ;
	if statutr ='9' then statutr=. ; if statoep='99' then statoep=. ; if stat2 ='9' then stat2 =. ; if txtppred ='9' then txtppred =. ;
	typmen = typmen21 ; if typmen in ('61', '91') then typmen='51' ; if typmen in ('62', '92') then typmen='52' ; 
	if typmen in ('63', '93') then typmen='53' ; if typmen='11' then typmen='10' ; if typmen='12' then typmen='11' ; 
	if valprie in ('9999998', '9999999') then valprie =' ' ; 
	if valpre in ('9999998', '9999999') then valpre =' ' ; if valpre >0 then tempri ='1' ; 
	if prim ='9' then prim ='.' ; if prims ='9' then prims='.' ;
	if chpub='1' then chpub2='6' ; if chpub in ('2', '6') then chpub2='5' ; if chpub='3' then chpub2='1' ; 
	if chpub='4' then chpub2='2' ; if chpub='5' then chpub2='3' ; if chpub='7' then chpub2='4' ; chpub=chpub2 ;
	if pub3fp='3' then pub3fp='2' ; if pub3fp='4' then pub3fp='5' ; if chpub='6' then pub3fp='3' ; if chpub='2' then pub3fp='4' ; pubea=pub3fp ; 
	if empafg ne ' ' then empafg = 7.5*empafg ; if empce ne ' ' then empce = 7.5*empce ; if emppa ne ' ' then emppa = 7.5*emppa ;
	if empafp ne ' ' then empafp = 7.5*empafp ; if empcp ne ' ' then empcp = 7.5*empcp ; if empco ne ' ' then empco = 7.5*empco ;
	if empanh ne ' ' then empanh = 7.5*empanh ; if empjf ne ' ' then empjf = 7.5*empjf ; if empafc ne ' ' then empafc = 7.5*empafc ;
	if ancchomm =. then ancchomm = ancinatm ; 
%end ;

run ;
%mend;

%hdata(a=&aprec.,t=4, listvar= year quart datdeb datqi salred ag5 reg hhc empnbh hhchsup nbtot totnbh tppred txtppred horaic 
       chpub titc pub3fp pubea valpre valprie prim prims jourtr nbjtrref ancentr ancinatm ancchomm acteu stat2 statoep statutr ret preret nafg nafn 
       nbsalb cstot cstotr typmen tempri typp typps sexe dip emphnh emphre empafc empafa empafg empco empce empjf emppa emprtt empafp empcp empanh
       empaffm1 empaffm2 empaffm3 empaffm4 empcon empabs SP00 SP01 SP02 SP03 SP04 SP05 SP06 SP07 SP08 SP09 SP10 SP11 rabs, bibli=erfs_c) ;
%hdata(a=&acour.,t=1, listvar= year quart datdeb datqi salred ag5 reg hhc empnbh hhchsup nbtot totnbh tppred txtppred horaic 
       chpub titc pub3fp pubea valpre valprie prim prims jourtr nbjtrref ancentr ancinatm ancchomm acteu stat2 statoep statutr ret preret nafg nafn 
       nbsalb cstot cstotr typmen tempri sexe dip emphnh emphre empafc empafg empco empce empjf emppa empafp empcp empanh
       empaffm1 empaffm2 empaffm3 empaffm4 empcon empabs SP00 SP01 SP02 SP03 SP04 SP05 SP06 SP07 SP08 SP09 SP10 SP11 rabs, bibli=erfs_c) ;
%hdata(a=&acour.,t=2, listvar= year quart datdeb datqi salred ag5 reg hhc empnbh hhchsup nbtot totnbh tppred txtppred horaic
       chpub titc pub3fp pubea valpre valprie prim prims jourtr nbjtrref ancentr ancinatm ancchomm acteu stat2 statoep statutr ret preret nafg nafn
       nbsalb cstot cstotr typmen tempri sexe dip emphnh emphre empafc empafg empco empce empjf emppa 
       empaffm1 empaffm2 empaffm3 empaffm4 empcon empabs SP00 SP01 SP02 SP03 SP04 SP05 SP06 SP07 SP08 SP09 SP10 SP11 rabs, bibli=erfs_c) ;
%hdata(a=&acour.,t=3, listvar= year quart datdeb datqi salred ag5 reg hhc empnbh hhchsup nbtot totnbh tppred txtppred horaic 
       chpub titc pub3fp pubea valpre valprie prim prims jourtr nbjtrref ancentr ancinatm ancchomm acteu stat2 statoep statutr ret preret nafg nafn 
       nbsalb cstot cstotr typmen tempri sexe dip emphnh emphre empafc empafg empco empce empjf emppa empafp empcp empanh
       empaffm1 empaffm2 empaffm3 empaffm4 empcon empabs SP00 SP01 SP02 SP03 SP04 SP05 SP06 SP07 SP08 SP09 SP10 SP11 rabs, bibli=erfs_c) ;
%hdata(a=&acour.,t=4, listvar= year quart datdeb datqi salred ag5 reg hhc empnbh hhchsup nbtot totnbh tppred txtppred horaic 
       chpub titc pub3fp pubea valpre valprie prim prims jourtr nbjtrref ancentr ancinatm ancchomm acteu stat2 statoep statutr ret preret nafg nafn 
       nbsalb cstot cstotr typmen tempri sexe dip emphnh emphre empafc empafg empco empce empjf emppa empafp empcp empanh
       empaffm1 empaffm2 empaffm3 empaffm4 empcon empabs SP00 SP01 SP02 SP03 SP04 SP05 SP06 SP07 SP08 SP09 SP10 SP11 rabs, bibli=erfs) ;
 %hdata(a=&asuiv.,t=1, listvar= year quart datdeb datqi salred ag5 reg hhc empnbh hhchsup nbtot totnbh tppred txtppred horaic 
       chpub titc pub3fp pubea valpre valprie prim prims jourtr nbjtrref ancentr ancinatm ancchomm acteu stat2 statoep statutr ret preret nafg nafn
       nbsalb cstot cstotr typmen tempri sexe dip emphnh emphre empafc empafg empco empce empjf emppa empafp empcp empanh
       empaffm1 empaffm2 empaffm3 empaffm4 empcon empabs SP00 SP01 SP02 SP03 SP04 SP05 SP06 SP07 SP08 SP09 SP10 SP11 rabs, bibli=erfs_c) ;

/*A partir de 2013 : convertir les variables en numérique*/
%macro num(a=, t=) ;
%if &a. >12 %then %do ;
	data pass_&a.t&t. (rename=(hhcnum=hhc empnbhnum=empnbh emphnhnum=emphnh hhchsupnum=hhchsup emphrenum=emphre ancentrnum=ancentr valprenum=valpre valprienum=valprie ancchommnum=ancchomm ancinatmnum=ancinatm salrednum=salred nbtotnum=nbtot)
								drop=hhc empnbh emphnh hhchsup emphre ancentr valpre valprie ancchomm ancinatm salred nbtot) ;
	   set pass_&a.t&t. ;
	   hhcnum=input(hhc, 4.) ; empnbhnum=input(empnbh, 4.) ; emphnhnum=input(emphnh, 4.) ; hhchsupnum=input(hhchsup, 4.) ; emphrenum=input(emphre, 4.) ; 
	   ancentrnum=input(ancentr, 3.) ; valprenum=input(valpre, 7.) ; valprienum=input(valprie, 7.) ;
	   ancchommnum=input(ancentr, 3.) ; ancinatmnum=input(ancinatm, 3.) ;salrednum=input(salred, 10.) ; nbtotnum=input(nbtot, 4.); 
	run ;
%end ;
%mend ;
 
%num(a=&aprec., t=4) ;
%num(a=&acour., t=1) ; %num(a=&acour., t=2) ; %num(a=&acour., t=3) ; %num(a=&acour., t=4) ; 
%num(a=&asuiv., t=1) ; 


/**************************************************************************************************************************************************************/
/*				2- Redressement et imputation des temps de travail des salariés 																		      */
/**************************************************************************************************************************************************************/

	/**Traitement isolé des salariés, pour qui on redresse les temps de travail**/
%macro salaries(a=, t=) ;
data salaries_&a.t&t. nonsal_&a.t&t. ;
	set pass_&a.t&t. ;
	select (stat2) ; 
	when ('2') output salaries_&a.t&t. ; otherwise output nonsal_&a.t&t. ; end ; 
run ; 
%mend ; 

%salaries(a=&aprec., t=4) ;
%salaries(a=&acour., t=1) ; %salaries(a=&acour., t=2) ; %salaries(a=&acour., t=3) ; %salaries(a=&acour., t=4) ;
%salaries(a=&asuiv., t=1) ; 

data salaries ;length dip $ 3;set salaries_&aprec.t4 salaries_&acour.t1 salaries_&acour.t2 salaries_&acour.t3 salaries_&acour.t4 salaries_&asuiv.t1 ; run ;
data nonsal;length dip $ 3 ; set nonsal_&aprec.t4 nonsal_&acour.t1 nonsal_&acour.t2 nonsal_&acour.t3 nonsal_&acour.t4 nonsal_&asuiv.t1 ; run ;

	/**Correction de la variable temps de travail pendant la semaine de référence**/
data heures ; set salaries ;
sexenum = input(sexe, 1.) ; 

/*Nombre d'heures conventionnel*/
hconv = 35 ;
if substr(nafn,1,3)='472'							then hconv =39 ;

/*Création des variables de nombre d'heures exceptionnellement non travaillées pendant la semaine de référence*/
if sum(empaffm1, empaffm2, empaffm3) >0 then empaf_temp = sum(empafc, empafg, empafa) ;		if empaffm4 ='1' then empaf_temp =0 ; if empaf_temp =. then empaf_temp =0 ;			
if empcon='1' then empco_temp = sum(empco, empce, empjf, emppa, empafp, empcp) ; 			else empco_temp =0 ;

/*EMPAF, EMPCONG, EMPMA : variables globales du nombre d'heures d'absence au travail pendant la semaine de référence*/
empaf = min (hconv, empaf_temp) ;
empcong = min(hconv, empco_temp) ;																
if empabs ='1' then empma = min(hconv, max(0, empanh)) ; else empma = 0 ;

/*Correction de la variable temps de travail pendant semaine de référence = nombre d'heures travaillées + nombre d'heure exceptionnellement non travaillées 
pendant la semaine de référence*/
if empnbh ne . & sum(empaf, empcong, empma) >0 then empnbh = min (hconv, sum(empnbh, empcong, empaf, empma)) ;

/*Suppression des valeurs aberrantes*/
hmax =48 ;	
if (hhc =0 		| hhc >hmax		| hhc in (' ')) 		then hhc =. ;
if (empnbh =0 	| empnbh >hmax 	| empnbh in (' ')) 		then empnbh =. ;
if (totnbh =0 	| totnbh >hmax 	| totnbh in (' ')) 		then totnbh =. ;
if (nbtot =0 	| nbtot >hmax 	| nbtot in (' ')) 		then nbtot =. ;

/*Définition des taux de temps partiel*/
if tppred =' ' then tppred ='1' ;
if tppred ='2' then txpart = 0.25*(txtppred ='1') +0.5*(txtppred ='2') +0.65*(txtppred ='3') +0.8*(txtppred ='4') +0.9*(txtppred ='5') ;
if txpart =0 then txpart =. ;

/*Soustraction des heures supplémentaires, traitées séparément*/
emphnh = max(emphnh, emphre) ;	/*correction des heures suppémentaires mal déclarées*/

hhc_red = hhc ; empnbh_red = empnbh ;
if .< hhchsup < hhc_red 	then hhc_red = hhc - hhchsup ;
if .< emphnh < empnbh_red 	then empnbh_red = empnbh - emphnh ; 

/*Durée journalière maximale légale de 12h (prise en compte des éventuelles dérogations par rapport au maximum normal de 10h)*/
if 1< jourtr <2.1 & hhc_red > 24 then hhc_red =24 ;		if 1< nbjtrref <2.1 & empnbh_red >24 then empnbh_red =24 ;
if 2< jourtr <3.1 & hhc_red > 36 then hhc_red =36 ;		if 2< nbjtrref <3.1 & empnbh_red >36 then empnbh_red =36 ; 
if 3< jourtr <4.1 & hhc_red > 48 then hhc_red =48 ;		if 3< nbjtrref <4.1 & empnbh_red >48 then empnbh_red =48 ;

if .< 1.1*empnbh_red < hhc_red & .< jourtr < 1.1*nbjtrref then hhc_red = empnbh_red ;

/*Ratio hhc/empnbh pour lisser les écarts entre hhc et empnbh*/
if empnbh_red ne . then ratio = hhc_red / empnbh_red ;

/*Retraitement pour régression : valeurs manquantes ou modalités peu nombreuses fusionnées avec d'autres*/
cstot_bis=cstot;
if cstot='00' then cstot_bis='52';
nafg_bis=nafg;
if nafg='00' or nafg='' then nafg_bis='GZ';
if nafg='CD' then nafg_bis='CE';
nbsalb_bis=nbsalb;
if nbsalb='' then nbsalb_bis='4';
dip_bis=dip;
if dip='' then dip_bis='50';
statutr_bis=statutr;
if statutr='2' then statutr_bis='3';
typmen_bis=typmen;
if typmen='23' then typmen_bis='22';
ancentr_bis=ancentr;
if ancentr=. then ancentr_bis=84;
ratio_bis=ratio;
if ratio >1.1 or ratio <0.9 then ratio_bis=.;

run ;

 
proc transreg data=heures noprint ;
   model identity(ratio_bis) = identity(sexenum ancentr_bis quart) class(cstot_bis reg nafg_bis nbsalb_bis dip_bis statutr_bis typmen_bis ag5 / zero='52' '11' 'GZ' '6' '50' '5' '42' '30') ;			
   output out=heures0 coefficients predicted adprefix= p0_ ;
   id ident&acour. noi ;
run ;

	/**Harmonisation du format des variables**/
data heures0 (drop=ident&acour._bis noi_bis);
length ident&acour. $8.;
length noi $2.;
set heures0(rename=(ident&acour.=ident&acour._bis noi=noi_bis));
ident&acour.=ident&acour._bis;noi=noi_bis;
run;


proc sort data=heures ; 	by ident&acour. noi quart ; run ;
proc sort data=heures0 ; 	by ident&acour. noi quart ; run ;



/**************************************************************************************************************************************************************/
/*				3- Redressement et imputation pour les temps complets puis les temps partiels 															      */
/**************************************************************************************************************************************************************/

/**************************************************************************************************************************************************************/
/*		a. Temps complets : Valeurs prédites du temps de travail moyen (p1_hhc_red) et de la semaine de référence (p1_empnbh_red) 		                      */
/**************************************************************************************************************************************************************/

data heures0 ; 
merge heures (in=a) heures0 (keep = ident&acour. noi quart p0_ratio_bis) ;
if a ; by ident&acour. noi quart ;

if ratio >1.1 & p0_ratio_bis ne . then hhc_red = p0_ratio_bis * empnbh_red ;
if year <13 then do ; if hhc_red ne . then hhc_red = hhc_red - 0.3 ; end ;		/*avant 2013, le questionnaire induit une surévaluation de 0.3 des heures déclarées*/
run ;

/*Regression pour prédire les valeurs manquantes de temps de travail : temps complet*/
proc transreg data=heures0 (where=(tppred ='1')) noprint ;
   model identity(hhc_red) = identity(empnbh_red  sexenum ancentr_bis quart) class(cstot_bis reg nafg_bis nbsalb_bis dip_bis statutr_bis typmen_bis ag5 / zero='52' '11' 'GZ' '6' '50' '5' '42' '30') ;			
   output out=reghhc1 coefficients predicted adprefix= p1_ ;
   id ident&acour. noi ;
run;

proc transreg data=heures0 (where=(tppred ='1')) noprint ;
   model identity(empnbh_red) = identity(sexenum ancentr_bis quart) class(cstot_bis reg nafg_bis nbsalb_bis dip_bis statutr_bis typmen_bis ag5 / zero='52' '11' 'GZ' '6' '50' '5' '42' '30') ;			
   output out=regempnbh1 coefficients predicted adprefix= p1_ ;
   id ident&acour. noi ;
run;

/*Harmonisation du format des variables*/
data reghhc1 (drop=ident&acour._bis noi_bis);
length ident&acour. $8.;
length noi $2.;
set reghhc1(rename=(ident&acour.=ident&acour._bis noi=noi_bis));
ident&acour.=ident&acour._bis;noi=noi_bis;
run;

data regempnbh1 (drop=ident&acour._bis noi_bis);
length ident&acour. $8.;
length noi $2.;
set regempnbh1(rename=(ident&acour.=ident&acour._bis noi=noi_bis));
ident&acour.=ident&acour._bis;noi=noi_bis;
run;

proc sort data=heures0 ; 	by ident&acour. noi quart ; run ;
proc sort data=reghhc1 ; 	by ident&acour. noi quart ; run ;
proc sort data=regempnbh1 ; by ident&acour. noi quart ; run ;

/*Pour les temps pleins : si la valeur de hhc_red est manquante, on attribue sa valeur prédite ou, si l'individu ne déclare pas avoir des horaires très 
variables d'une semaine à l'autre ou qu'il n'a pas pris de congés pendant la semaine de référence, la valeur de empnbh_red ou sa valeur prédite (si manquante)*/
data heures1 ; merge 	heures0 (in=a) 
						reghhc1 (keep = ident&acour. noi quart p1_hhc_red)
						regempnbh1 (keep = ident&acour. noi quart p1_empnbh_red) ; 
	if a ; by ident&acour. noi quart ;

if hhc_red =. & tppred='1' then hhc_red = p1_hhc_red ; 
if hhc_red =. & empcon ne '1' & horaic not in ('2', '3') then hhc_red = empnbh_red ;
if hhc_red =. & tppred ='1' & horaic not in ('2', '3') then hhc_red = p1_empnbh_red ;

/*Pour les temps partiels : imputation des valeurs manquantes des taux de temps partiels par tranches*/
if tppred ='2' & txpart =. then do ;
	temp = hhc/hconv ;
	if temp =. then temp = empnbh/hconv ;
end ;
if tppred = '2' then do ;
	if txpart =. & .< temp <=0.4 then txpart =0.25 ; 
	if txpart =. & 0.25< temp <=0.575 then txpart = 0.5 ;
	if txpart =. & 0.575< temp <= 0.725 then txpart = 0.65 ;
	if txpart =. & 0.725< temp <= 0.85 then txpart = 0.8 ;
	if txpart =. & temp >0.85 then txpart = 0.9 ;
end ;

if tppred ='1' then txpart =1 ;
if tppred ='1' & hhc_red =. then tppred ='2' ;	/*à ce stade si on n'a pas de temps de travail, l'observation est re-traitée avec les temps partiels*/

run ;


/**************************************************************************************************************************************************************/
/*		b. Temps partiels : Valeurs prédites du temps de travail moyen (p2_hhc_red) et de la semaine de référence (p2_empnbh_red) 		                      */
/**************************************************************************************************************************************************************/

/*Regression pour prédire les valeurs manquantes de temps de travail : temps partiel*/
proc transreg data=heures1 (where=(tppred ='2')) noprint ;
   model identity(hhc_red) = identity(empnbh_red sexenum ancentr_bis quart) class(cstot_bis reg nafg_bis nbsalb_bis dip_bis statutr_bis typmen_bis ag5 / zero='52' '11' 'GZ' '6' '50' '5' '42' '30') ;			
   output out=reghhc2 coefficients predicted adprefix= p2_ ;
   id ident&acour. noi ;
run;
proc transreg data=heures1 (where=(tppred ='2')) noprint ;
   model identity(empnbh_red) = identity(sexenum ancentr_bis quart) class(cstot_bis reg nafg_bis nbsalb_bis dip_bis statutr_bis typmen_bis ag5 / zero='52' '11' 'GZ' '6' '50' '5' '42' '30') ;			
   output out=regempnbh2 coefficients predicted adprefix= p2_ ;
   id ident&acour. noi ;
run;

/*Harmonisation du format des variables*/
data reghhc2 (drop=ident&acour._bis noi_bis);
length ident&acour. $8.;
length noi $2.;
set reghhc2(rename=(ident&acour.=ident&acour._bis noi=noi_bis));
ident&acour.=ident&acour._bis;noi=noi_bis;
run;

data regempnbh2 (drop=ident&acour._bis noi_bis);
length ident&acour. $8.;
length noi $2.;
set regempnbh2(rename=(ident&acour.=ident&acour._bis noi=noi_bis));
ident&acour.=ident&acour._bis;noi=noi_bis;
run;

proc sort data=heures1 ; 	by ident&acour. noi quart ; run ;
proc sort data=reghhc2 ; 	by ident&acour. noi quart ; run ;
proc sort data=regempnbh2 ; by ident&acour. noi quart ; run ;

data heures2 ; merge 	heures1 (in=a) 
						reghhc2 (keep = ident&acour. noi quart p2_hhc_red) 
						regempnbh2 (keep = ident&acour. noi quart p2_empnbh_red) ; 
	if a ; by ident&acour. noi quart ;

/*Pour les temps partiels : si la valeur de hhc_red est manquante, on attribue sa valeur prédite ou, si l'individu ne déclare pas avoir des horaires très 
variables d'une semaine à l'autre ou qu'il n'a pas pris de congés pendant la semaine de référence, la valeur prédite de empnbh_red*/
if tppred='2' & hhc_red =. then hhc_red = p2_hhc_red ;
if tppred ='2' & hhc_red =. & horaic not in ('2', '3') then hhc_red = p2_empnbh_red ; 
/*Le taux de temps partiel détaillé manquant à ce stade prend par défaut la valeur 3/5*/
if tppred ='2' & txpart =. then txpart =3/5 ; 
/*Le temps de travail moyen manquant à ce stage prend la valeur des autres variables de temps de travail : empnbh_red ou txpart*hconv en dernier recours*/
if hhc_red =. then hhc_red = empnbh_red ;
if hhc_red =. then hhc_red = txpart*hconv ;


/*Variables finales : NBHEUR_RED, TXPART. On garde les anciennes variables : HHC_RED, TXPART_OLD*/
if hhc_red/hconv >0.99 then tppred ='1' ;	/*=1 pour les salariés à temps complet et 0 à temps partiel*/
if tppred ='1' then txpart =1 ;	
nbheur_red = hhc_red ;						/*temps de travail hebdomadaire moyen redressé*/
txpart_old = txpart ; 						/*taux de temps partiel par tranches, non redressé après le traitement des temps de travail*/
txpart = min(1, hhc_red/hconv) ; 			/*taux de temps partiel redressé*/


/**************************************************************************************************************************************************************/
/*				4- Imputation des données sur les primes																								      */
/**************************************************************************************************************************************************************/

/*Création d'une variable indicatrice des primes, qui remplace les modalités 1/2 de la variable initiale*/
if prim ne . then prim_01 = 2-prim ;
if prims ne . then prims_01 = 2-prims ;

if ancentr =-1 then ancentr=0 ; ln_ancentr = log(1 + ancentr) ;
if salred >0 then ln_salred = log(1 + salred) ; else ln_salred =. ;
indic_effort = nbheur_red /(hconv*txpart) ; 

/*Duplication des variables explicatives*/
prev_prim01=prim_01 ; prev_prims01=prims_01 ; prev_sexe=sexe ; prev_lnsalred=ln_salred ; prev_lnancentr=ln_ancentr ; prev_effort=indic_effort ; prev_txpart=txpart ;
prev_tppred=tppred ; prev_reg=reg ; prev_nafg=nafg ; prev_nbsalb=nbsalb ; prev_dip=dip ; prev_cstot=cstot ; prev_statutr=statutr ; prev_typmen=typmen ; prev_ag5=ag5 ; 
prev_quart=quart ; 

/*Imputation des valeurs manquantes des variables expliquatives*/
if prev_dip='' then prev_dip='50';
if prev_nafg='' then prev_nafg='62';
if prev_lnsalred=. then prev_lnsalred=7.33;
if prev_lnancentr=. then prev_lnancentr=4.45;

run ;


proc mi data = heures2 out=idprim nimpute=1 noprint ;
	class prev_prim01 prev_sexe prev_reg prev_nafg prev_dip prev_cstot prev_statutr prev_typmen prev_ag5 ;
	monotone logistic (prev_prim01 = prev_quart prev_sexe prev_lnsalred prev_lnancentr prev_effort prev_txpart prev_reg prev_nafg prev_dip prev_cstot prev_statutr prev_typmen prev_ag5) ;
	var prev_quart prev_sexe prev_lnsalred prev_lnancentr prev_effort prev_txpart prev_reg prev_nafg prev_dip prev_cstot prev_statutr prev_typmen prev_ag5 prev_prim01;
run ;

/*Détermination de l'attribution de prime trimestrielle ou annuelle*/
proc mi data = heures2 out=idprims nimpute=1 noprint ;
	class prev_prims01 prev_sexe prev_reg prev_nafg  prev_dip prev_cstot prev_statutr prev_typmen prev_ag5 ;
	monotone logistic (prev_prims01 = prev_quart prev_sexe prev_lnsalred prev_lnancentr prev_effort prev_txpart prev_reg prev_nafg  prev_dip prev_cstot prev_statutr prev_typmen prev_ag5) ;
	var prev_quart prev_sexe prev_lnsalred prev_lnancentr prev_effort prev_txpart prev_reg prev_nafg  prev_dip prev_cstot prev_statutr prev_typmen prev_ag5 prev_prims01;
run ;


/*Récupération du pourcentage de primes brut/net pour l'attribution des valeurs manquantes*/
proc freq data=idprim (where=(prev_prim01=1)) ; tables typp /out=pct_typp outcum noprint ; run ;
proc freq data=idprims (where=(prev_prims01=1)) ; tables typps /out=pct_typps outcum noprint ; run ;
proc freq data=idprims (where=(prev_prims01=1)) ; tables tempri /out=pct_tempri outcum noprint ; run ;

data pct_typp ; set pct_typp (where=(typp ne ' ')) ;
typp_pct = cum_pct /100 ; suffix = put(_n_,1.) ; call symput(cats('typp_pct',suffix), typp_pct);
run ;
data pct_typps ; set pct_typps (where=(typps ne ' ')) ;
typps_pct = cum_pct /100 ; suffix = put(_n_,1.) ; call symput(cats('typps_pct',suffix), typps_pct);
run ;
data pct_tempri ; set pct_tempri (where=(tempri ne ' ')) ;
tempri_pct = cum_pct /100 ; suffix = put(_n_,1.) ; call symput(cats('tempri_pct',suffix), tempri_pct);
run ;

proc sort data=heures2 ; 	by ident&acour. noi quart ; run ;
proc sort data=idprim ; 	by ident&acour. noi quart ; run ;
proc sort data=idprims ; 	by ident&acour. noi quart ; run ;

data heures3 ; merge	heures2 (drop=prev_ :)
						idprim (keep=ident&acour. noi quart prev_prim01)
						idprims (keep=ident&acour. noi quart prev_prims01) ; 
		by ident&acour. noi quart ;

prim = prev_prim01 ; prims = prev_prims01 ;

/*Type de prime pour les primes mensuelles : brut ou net*/
random = rand('uniform') ;
if prim =1 & typp =. & random <= &typp_pct1. then typp =1 ;
if prim =1 & typp =. & random > &typp_pct1. then typp =2 ;
if prim =1 & typp =. then typp =1 ;

/*Type de prime pour les autres primes : brut ou net*/
random = rand('uniform') ;
if prims =1 & typps =. & random <= &typps_pct1. then typps =1 ;
if prims =1 & typps =. & random > &typps_pct1. then typps =2 ;
if prims =1 & typps =. then typps =1 ;

/*Fréquence d'allocation des primes non mensuelles : trimestrielle ou annuelle*/
random = rand('uniform') ;
if prims =1 & tempri=. & random <= &tempri_pct1. then tempri =1 ;
if prims =1 & tempri=. & random > &tempri_pct1. then tempri =2 ;
if prims =1 & tempri=. then tempri =1 ;


	/**Imputation du montant des primes**/

/* Fonction Publique */
if statoep in ('43', '45') & chpub ='1' & titc in ('1', '2') 	then FP =1 ; 
if statoep in ('43', '45') & chpub ='1' & titc ='3' 			then FP =2 ;
if statoep in ('43', '45') & chpub ='2' & titc in ('1', '2') 	then FP =3 ;
if statoep in ('43', '45') & chpub ='2' & titc ='3' 			then FP =4 ;
if statoep in ('43', '45') & chpub ='3' & titc in ('1', '2') 	then FP =5 ;
if statoep in ('43', '45') & chpub ='3' & titc ='3' 			then FP =6 ;
if statoep ='44' 												then FP =7 ;
if statoep >40 & FP =. 											then FP =8 ;
if FP =8 & pubea ='1' 											then FP =2 ;
if FP =8 & pubea ='2' 											then FP =4 ;
if FP in ('1', '3') & nafg ='QA' 								then FP =5 ;	/*QA : "activité pour la santé humaine"*/
if FP in ('2', '4') & nafg ='QA' 								then FP =6 ;

/*Détermination des taux de cotisation, Smic et plafond de la sécurité sociale (PSS) en fonction de la date*/
%macro donnees ; 
	%do a =&aprec. %to &asuiv. ;
		if &a. = year then do ;		TCSS = &&TCSS_&a.. ; 	TCSS_P3P = &&TCSS_P3P_&a.. ; 	TCSS_3P4P = &&TCSS_3P4P_&a.. ; 	TCSS_4P = &&TCSS_4P_&a.. ;
									TCSC = &&TCSC_&a.. ; 	TCSC_P3P = &&TCSC_P3P_&a.. ; 	TCSC_3P4P = &&TCSC_3P4P_&a.. ; 	TCSC_4P = &&TCSC_4P_&a.. ;
		if &a. =12 & quart <210 then Smic = &Smic_121. ; 
		if &a. =12 & quart >209 then Smic = &Smic_122. ; 
		if &a. ne 12 then Smic = &&Smic_&a.. ; Plafond_SS = &&Plafond_SS_&a.. ;
		end ; 
	%end ; 
%mend ; %donnees ;

TCS = 		(TCSS*(cstotr ne '3') + TCSC*(cstotr ='3')) *(FP =.) 			+ 15.9 *(FP in ('1', '3', '5')) + 18.4 *(FP in('2', '4', '6', '7', '8')) ; 
TCS_P3P = 	(TCSS_P3P*(cstotr ne '3') + TCSC_P3P*(cstotr ='3')) *(FP =.) 	+ 15.9 *(FP in ('1', '3', '5')) + 15.5 *(FP in('2', '4', '6', '7', '8')) ; 
TCS_3P4P = 	(TCSS_3P4P*(cstotr ne '3') + TCSC_3P4P*(cstotr ='3')) *(FP =.) 	+ 15.9 *(FP in ('1', '3', '5')) + 15.5 *(FP in('2', '4', '6', '7', '8')) ; 
TCS_4P = 	(TCSS_4P*(cstotr ne '3') + TCSC_4P*(cstotr ='3')) *(FP =.) 		+ 15.9 *(FP in ('1', '3', '5')) + 15.5 *(FP in('2', '4', '6', '7', '8')) ; 

/*Conversion de toutes les primes en net*/ 
/*La variable salred est en net et doit être convertie en brut pour être comparée au PSS : la conversion en brut est obtenue en divisant par (1-TCS/100)*/
if prim =1 & typp =2 & salred/(1-TCS/100) + valprie < Plafond_SS 			then valprie = valprie*(1-TCS/100) ;
if prim =1 & typp =2 & salred/(1-TCS/100) + valprie >= Plafond_SS*txpart 	then valprie = Plafond_SS*txpart*(1-TCS/100) + (valprie - Plafond_SS*txpart)*(1-TCS_P3P/100) ;
if prim =1 & typp =2 & salred/(1-TCS/100) + valprie >= 3*Plafond_SS*txpart 	then valprie = Plafond_SS*txpart*(1-TCS/100) + 2*Plafond_SS*txpart*(1-TCS_P3P/100) + (valprie - 3*Plafond_SS*txpart)*(1-TCS_3P4P/100) ;
if prim =1 & typp =2 & salred/(1-TCS/100) + valprie >= 4*Plafond_SS*txpart 	then valprie = Plafond_SS*txpart*(1-TCS/100) + 2*Plafond_SS*txpart*(1-TCS_P3P/100) + Plafond_SS*txpart*(1-TCS_3P4P/100) + (valprie - 4*Plafond_SS*txpart)*(1-TCS_4P/100) ;

if prims =1 & typps =2 & salred/(1-TCS/100) + valpre < Plafond_SS 			then valpre = valpre*(1-TCS/100) ;
if prims =1 & typps =2 & salred/(1-TCS/100) + valpre >= Plafond_SS*txpart 	then valpre = Plafond_SS*txpart*(1-TCS/100) + (valpre - Plafond_SS*txpart)*(1-TCS_P3P/100) ; 
if prims =1 & typps =2 & salred/(1-TCS/100) + valpre >= 3*Plafond_SS*txpart then valpre = Plafond_SS*txpart*(1-TCS/100) + 2*Plafond_SS*txpart*(1-TCS_P3P/100) + (valpre - 3*Plafond_SS*txpart)*(1-TCS_3P4P/100) ;
if prims =1 & typps =2 & salred/(1-TCS/100) + valpre >= 4*Plafond_SS*txpart then valpre = Plafond_SS*txpart*(1-TCS/100) + 2*Plafond_SS*txpart*(1-TCS_P3P/100) + Plafond_SS*txpart*(1-TCS_3P4P/100) + (valpre - 4*Plafond_SS*txpart)*(1-TCS_4P/100) ;

/*vprim : variable créée pour imputer le montant des primes mensuelles*/
if .< valprie < salred then r_valprie = min(1, max(0, valprie/(salred-valprie)) ) ;
if prim =1 & 0< r_valprie <0.25 then vprim = log(r_valprie/(1-r_valprie)) ;

/*vprims : variable créée pour imputer le montant des primes trimestrielles ou annuelles*/
if tempri =2 				then valpre = valpre*4 ;			/*primes trimestrielles mises sur base annuelle*/
if prims =1 & valpre =0 	then valpre =. ;
if prims =0 & valpre =. 	then valpre =0 ;
if valpre ne . & salred >0 		then r_valpre = min(2, max(0, valpre/salred) ) ;
if prims =1 & 0< r_valpre <=2 	then vprims = log(r_valpre) ;

/*Duplication des variables pour imputation*/
prev_vprim=vprim ; prev_vprims=vprims ; prev_sexe=sexe ; prev_lnsalred=ln_salred ; prev_lnancentr=ln_ancentr ; prev_effort=indic_effort ; prev_txpart=txpart ;
prev_tppred=tppred ; prev_reg=reg ; prev_nafg=nafg ; prev_nbsalb=nbsalb ; prev_dip=dip ; prev_cstot=cstot ; prev_statutr=statutr ; prev_typmen=typmen ; prev_ag5=ag5 ;
prev_quart=quart ;

/*Imputation des valeurs manquantes des variables expliquatives*/
if prev_dip='' then prev_dip='50';
if prev_nafg='' then prev_nafg='62';
if prev_lnsalred=. then prev_lnsalred=7.33;
if prev_lnancentr=. then prev_lnancentr=4.45;

run ;


/*Imputation des primes mensuelles*/

proc mi data=heures3 (where=(prim='1')) out=valprim nimpute=1 noprint ;
	class prev_sexe prev_tppred prev_reg prev_nafg  prev_dip prev_cstot prev_statutr prev_typmen prev_ag5 ;
	monotone reg (prev_vprim = prev_quart prev_sexe prev_lnsalred prev_lnancentr prev_effort prev_txpart prev_tppred prev_reg prev_nafg  prev_dip prev_cstot prev_statutr prev_typmen prev_ag5) ;
	var prev_quart prev_sexe prev_lnsalred prev_lnancentr prev_effort prev_txpart prev_tppred prev_reg prev_nafg  prev_dip prev_cstot prev_statutr prev_typmen prev_ag5 prev_vprim;
run ;

/*Imputation des autres primes*/

proc mi data=heures3 (where=(prims='1')) out=valprims nimpute=1 noprint ;
	class prev_sexe prev_tppred prev_reg prev_nafg  prev_dip prev_cstot prev_statutr prev_typmen prev_ag5 ;
	monotone reg (prev_vprims = prev_quart prev_sexe prev_lnsalred prev_lnancentr prev_effort prev_txpart prev_tppred prev_reg prev_nafg  prev_dip prev_cstot prev_statutr prev_typmen prev_ag5) ;
	var prev_quart prev_sexe prev_lnsalred prev_lnancentr prev_effort prev_txpart prev_tppred prev_reg prev_nafg  prev_dip prev_cstot prev_statutr prev_typmen prev_ag5 prev_vprims;
run ;


proc sort data=heures3 ;	by ident&acour. noi quart ; run ;
proc sort data=valprim ; 	by ident&acour. noi quart ; run ;
proc sort data=valprims ; 	by ident&acour. noi quart ; run ;
proc sort data=nonsal ; 	by ident&acour. noi quart ; run ;

%macro temps(primes=) ;
data temps_&primes. ; merge heures3 (drop=prev_ :) 
							valprim (keep=ident&acour. noi quart prev_vprim)
							valprims (keep=ident&acour. noi quart prev_vprims)
							nonsal ;										/*on réintègre les non salariés dans les données*/
		by ident&acour. noi quart ;

if stat2 ='2' then do ; 														/*appliqué uniquement aux salariés*/

/*Primes mensuelles*/
if prim =1 then prev_r_valprie = exp(prev_vprim) / (1 + exp(prev_vprim)) ;
if prim =1 & r_valprie =. 	then r_valprie = prev_r_valprie ;
if r_valprie =. or prim =2 	then r_valprie = 0 ;

valprie = salred*r_valprie /(1 + r_valprie) ;

/*Autres primes*/
if prims =1 then prev_r_valpre = exp(prev_vprims) ;
if prims =1 & r_valpre =. 	then r_valpre = min(2, max(0, prev_r_valpre)) ;
if r_valpre =. or prims =0 	then r_valpre = 0 ;

valpre = salred*r_valpre ;
if tempri =2 & valpre ne . then valpre = valpre/4 ; /*remet les primes concernées sur base trimestrielle*/


/**************************************************************************************************************************************************************/
/*				5- Création de la variable nbheur_maj : nombre d'heures travaillées majorées (heures supplémentaires)									      */
/**************************************************************************************************************************************************************/

/*Coefficient de majoration appliqué aux heures supplémentaires (pas de majoration pour les heures complémentaires)*/
maj1 = 1 + 0.25*(tppred ='1') ; if ((substr(nafn,1,2) ='55')|(substr(nafn,1,2) ='56')) then maj1 = 1 + 0.1*(tppred ='1') ;
maj2 = 1 + 0.25*(tppred ='1') ;
maj3 = 1 + 0.5*(tppred ='1') ;

/*Calcul des heures supplémentaires (corrigées des heures non-rémunérées : sous-déclaration ou récupération)*/
if tppred ='1' then hsup = min(max(0, nbheur_red - hconv), 48-hconv) ;
if tppred ='2' then hsup = min(max(0, nbheur_red - txpart*hconv), txpart*hconv/10) ;

/*Ecrétage et recalcul des heures supplémentaires*/
nbheur_red = min(nbheur_red, txpart*hconv) + hsup ;	

if tppred ='1' then hsup = min(max(0, nbheur_red - hconv), 48-hconv) ;
if tppred ='2' then hsup = min(max(0, nbheur_red - txpart_old*hconv), txpart_old*hconv/10) ;

hsup_maj = maj1*min(4, max(0, hsup)) + maj2*min(4, max(0, hsup-4)) + maj3*max(0, hsup-8) ;
nbheur_maj = max(0, nbheur_red-hsup) + hsup_maj ;


/**************************************************************************************************************************************************************/
/*				6- Création de la variable nbheur_prev : temps de travail hebdomadaire habituel redressé et imputé										      */
/**************************************************************************************************************************************************************/

/*Mensualisation des variables*/
hconvm = hconv *52/12 ; nbheur_majm = nbheur_maj *52/12 ; hsup_majm = hsup_maj *52/12 ;
Plafond_SS_h = Plafond_SS /hconvm ;

/*salnet_h : Salaire horaire net*/
/*Option 1 : pas de prise en compte des primes mensuelles dans le salaire*/ 
%if &primes. =0 %then %do ; salnet_h = salred /nbheur_majm ; %end ; 
/*Option 2 : prise en compte des primes mensualisées*/
%if &primes. =1 %then %do ; salnet_h = (salred - valprie) /nbheur_majm ; %end ;

/*salbrut_h : Salaire brut horaire (dépend de l'option retenue ci-dessus)*/
if salnet_h >0 then 	salbrut_h = min(Plafond_SS_h*(1 -TCS/100), salnet_h) / (1 -TCS/100)
				+ min(2*Plafond_SS_h*(1 -TCS_P3P/100), max(0, salnet_h - Plafond_SS_h*(1 -TCS/100))) / (1 -TCS_P3P/100)  
				+ min(Plafond_SS_h*(1 -TCS_3P4P/100), max(0, salnet_h - Plafond_SS_h*(1 -TCS/100) - 2*Plafond_SS_h*(1 -TCS_P3P/100))) / (1 -TCS_3P4P/100) 
				+ max(0, salnet_h - Plafond_SS_h*(1 -TCS/100) - 2*Plafond_SS_h*(1 -TCS_P3P/100) - Plafond_SS_h*(1 -TCS_3P4P/100)) / (1 -TCS_4P/100) ;


/*Salaire brut mensuel à partir du salaire brut horaire, avec primes annuelles*/
/*Passage des primes annuelles du net au brut*/
primes_a_&primes. = valpre / (1 - TCS/100 *(salbrut_h<=Plafond_SS_h) - TCS_P3P/100 *((salbrut_h<=3*Plafond_SS_h)&(salbrut_h>Plafond_SS_h)) - TCS_3P4P/100 *((salbrut_h<=4*Plafond_SS_h)&(salbrut_h>3*Plafond_SS_h)) - TCS_4P/100 *(salbrut_h>4*Plafond_SS_h)) ;

/*Passage des primes mensuelles du net au brut*/
primes_m_0 = 0 ;
primes_m_1 = valprie / (1 - TCS/100 *(salbrut_h<=Plafond_SS_h) - TCS_P3P/100 *((salbrut_h<=3*Plafond_SS_h)&(salbrut_h>Plafond_SS_h)) - TCS_3P4P/100 *((salbrut_h<=4*Plafond_SS_h)&(salbrut_h>3*Plafond_SS_h)) - TCS_4P/100 *(salbrut_h>4*Plafond_SS_h)) ;

/*Choix du salaire horaire redressé : prise en compte ou non des primes mensuelles (option 1 ou 2)*/	
primes_a = primes_a_&primes. ;		primes_m = primes_m_&primes. ;
		

/*salbrut_red : salaire horaire mensuel brut redressé*/ 
salbrut_red = salbrut_h ;	if .< salbrut_red <= SMIC then salbrut_red = SMIC ; 		/*observations non conformes avec le salaire minimum*/
/*salbrut : salaire brut mensuel*/
salbrut = salbrut_red*nbheur_majm + primes_m + primes_a/12 ;
	
/*Repérage des heures supplémentaires*/
i_hs = (hsup >=1) ;
tx_TEPA = (hsup_majm*salbrut_red) / (salbrut - hsup_majm*salbrut_red) *i_hs ;

/*Allègements TEPA : correction des heures supplémentaires*/	
if salred >0 then do ;
	hsup_prev = tx_TEPA * txpart * hconv ;								/*variable hebdomadaire*/
		if hsup_prev >0 then hsup_prev = min(4*maj1, hsup_prev) /maj1 + min(4*maj2, max(0, hsup_prev -4*maj1)) /maj2 + max(0, hsup_prev -4*maj1 -4*maj2) /maj3 ;
	nbheur_prev = sum(txpart*hconvm, hsup_prev*52/12) ; 				/*variable mensuelle*/
end ;

/*Pour les observations pour lesquelles le salaire de l'EEC (salred) n'est pas renseigné, on ne peut pas calculer les heures supplémentaires de cette manière, 
on récupère donc de la variable hsup*/
else if salred <=0 then do ;
	hsup_prev = hsup ; 		nbheur_prev = sum(txpart*hconvm, hsup_prev*52/12) ;
end ;

/*	- le salaire brut (salbrut_prev) et le temps de travail (nbheur_prev) sont mis en cohérence avec cette nouvelle mesure des heures supplémentaires
	- le salaire horaire de base calculé uniquement sur les données de l'EEC reste la référence et n'est pas impacté par ces corrections*/

	salbrut_prev = (txpart*hconv + maj1*min(4, max(0, hsup_prev)) + maj2*min(4, max(0, hsup_prev-4)) + maj3*max(0, hsup_prev-8)) * salbrut_red *52/12
									+ primes_m + primes_a /12 ;			/*variable mensuelle*/
end ;

drop prev_ : prim_01 prims_01 r_valpr : vprim vprims ln_ : indic_effort random temp p0_ratio_bis p1_ : p2_ : primes_m_ : primes_a_ : maj : TCS : Plafond_SS ; 

run ; 

%mend ; 
%temps(primes=0) ; %temps(primes=1) ; /*sans ou avec primes mensualisées dans le calcul du salaire horaire de l'EEC*/



/**************************************************************************************************************************************************************/
/**************************************************************************************************************************************************************/
/*                       											II. Calendrier d'activité	                 										      */
/**************************************************************************************************************************************************************/
/**************************************************************************************************************************************************************/

/**************************************************************************************************************************************************************/
/*				1- Préparation de la table avec les données des différents trimestres																		  */
/**************************************************************************************************************************************************************/

/*Création d'une table par trimestre*/
%macro split(primes=) ;
data temps_&aprec.t4 temps_&acour.t1 temps_&acour.t2 temps_&acour.t3 temps_&acour.t4 temps_&asuiv.t1 ; 
	set temps_&primes. ;
	select (quart) ; 		when (%eval(163+4*&aprec.)) output temps_&aprec.t4 ;
					 		when (%eval(160+4*&acour.)) output temps_&acour.t1 ;
							when (%eval(161+4*&acour.)) output temps_&acour.t2 ;
							when (%eval(162+4*&acour.)) output temps_&acour.t3 ; 
							when (%eval(163+4*&acour.)) output temps_&acour.t4 ; 
							when (%eval(160+4*&asuiv.)) output temps_&asuiv.t1 ;
	otherwise ; end ;
run ;
%mend ; %split(primes=0) ; 


/*Redéfinition des variables passées afin de les rassembler dans une seule table ensuite*/
%macro passe(a=, t=, listvar=); 

%let tabin = temps_&a.t&t. ;

data act_&a.t&t. ; set &tabin. ; keep ident&acour. noi &listvar. ;

if datqi ne '' then do;
	collm = max( %eval(3*&t.-2), min(%eval(3*&t.), input(substr(datqi,5,2),2.)) ) ;  /*mois semaine de reference*/
end;
else do;
	collm = max( %eval(3*&t.-2), min(%eval(3*&t.), input(substr(datdeb,5,2),2.)) ) ;  /*mois semaine de reference*/
end;

/*Correction premier point (si vide)*/
if SP00 ='' then do ; 
	if &a. <13 then do ; 	if acteu ='1' then sp00 ='1' ;
							else if acteu ='2' then sp00 ='3' ; 
							else if ret ='1' | preret ='1' then sp00 ='4' ;
							else sp00 ='6' ; 								end ;
	if &a. >12 then do ; 	if acteu ='1' then do ; if stat2='1' then sp00 ='2' ; else sp00 ='1' ; end ; 
							else if acteu ='2' then sp00 ='4' ; 
							else if ret ='1' | preret ='1' then sp00 ='5' ; 
							else sp00 ='9' ; 								end ;
end ; 

/*On renomme les variables selon le format VAR_an_Ti*/
%let i =1 ;
%do %while(%index(&listvar., %scan(&listvar., &i.)) >0) ; 
	%let var =%scan(&listvar., &i.) ;
		rename &var. = &var._&a.t&t. ;
	%let i = %eval(&i.+1) ;
%end ;


run ;

proc sort data=act_&a.t&t. ; by ident&acour. noi ; run ;

%mend ;


%passe(a=&aprec., t=4, listvar= datdeb datqi collm acteu stat2 ret preret ancentr ancchomm ancinatm tppred txpart hhc empnbh nbheur_red
	nbheur_maj nbheur_prev hsup hsup_maj hsup_prev rabs SP00 SP01 SP02 SP03 SP04 SP05 SP06 SP07 SP08 SP09 SP10 SP11 salbrut_red hconv) ; 

%passe(a=&acour., t=1, listvar= datdeb datqi collm acteu stat2 ret preret ancentr ancchomm ancinatm tppred txpart hhc empnbh nbheur_red
	nbheur_maj nbheur_prev hsup hsup_maj hsup_prev rabs SP00 SP01 SP02 SP03 SP04 SP05 SP06 SP07 SP08 SP09 SP10 SP11 hconv) ; 
%passe(a=&acour., t=2, listvar= datdeb datqi collm acteu stat2 ret preret ancentr ancchomm ancinatm tppred txpart hhc empnbh nbheur_red
	nbheur_maj nbheur_prev hsup hsup_maj hsup_prev rabs SP00 SP01 SP02 SP03 SP04 SP05 SP06 SP07 SP08 SP09 SP10 SP11 hconv) ; 
%passe(a=&acour., t=3, listvar= datdeb datqi collm acteu stat2 ret preret ancentr ancchomm ancinatm tppred txpart hhc empnbh nbheur_red
	nbheur_maj nbheur_prev hsup hsup_maj hsup_prev rabs SP00 SP01 SP02 SP03 SP04 SP05 SP06 SP07 SP08 SP09 SP10 SP11 hconv) ; 
%passe(a=&acour., t=4, listvar= datdeb datqi collm acteu stat2 ret preret ancentr ancchomm ancinatm tppred txpart hhc empnbh nbheur_red
	nbheur_maj nbheur_prev hsup hsup_maj hsup_prev rabs SP00 SP01 SP02 SP03 SP04 SP05 SP06 SP07 SP08 SP09 SP10 SP11 salbrut_red hconv) ; 

%passe(a=&asuiv., t=1, listvar= datdeb datqi collm acteu stat2 ret preret ancentr ancchomm ancinatm tppred txpart hhc empnbh nbheur_red
	nbheur_maj nbheur_prev hsup hsup_maj hsup_prev rabs SP00 SP01 SP02 SP03 SP04 SP05 SP06 SP07 SP08 SP09 SP10 SP11 hconv) ; 

proc sort data=saphir.irf&acour.e&acour.t4c ; by ident&acour. noi ; run ;
proc sort data=saphir.indivi&acour.; by ident&acour. noi ; run ;
data calendrier ;
	merge	saphir.irf&acour.e&acour.t4c
				(keep = ident&acour. noi ag sexe zsali zragi zrici zrnci zperi zchoi deces reg dip acteu cstot cstotr cspm cspp ancentr in=a) 
			act_&aprec.t4 act_&acour.t1 act_&acour.t2 act_&acour.t3 act_&acour.t4 act_&asuiv.t1 saphir.indivi&acour.(keep=ident&acour. noi csgsali);
	by ident&acour. noi ; if a ; if ag >=15 ;
run ;


/**************************************************************************************************************************************************************/
/*				2- Construction de la table de base du calendrier rétrospectif 																				  */
/**************************************************************************************************************************************************************/

%macro base(); 

data calendrier2 ; set calendrier ; 


/**************************************************************************************************************************************************************/
/*		a. Statut d'activité : exploitation des informations disponibles dans les différentes vagues de l'EEC 												  */
/**************************************************************************************************************************************************************/

/*On Récupère les heures conventionnelles*/
if hconv_&acour.t4 >0 then hconv = hconv_&acour.t4 ; else if hconv_&acour.t3 >0 then hconv = hconv_&acour.t3 ; else if hconv_&acour.t2 >0 then hconv = hconv_&acour.t2 ; else if hconv_&acour.t1 >0 then hconv = hconv_&acour.t1 ; 

/*Identification des revenus*/
revsal =(zsali >0) ; 					/*revenus salariés déclarés*/
revind =(zragi >0 | zrnci>0 | zrici>0) ;/*revenus non salariés déclarés*/
revcho =(zchoi >0) ; 					/*revenus du chômage déclarés*/
revret =(zperi >0) ;					/*retraites déclarées*/

zsal_net=zsali-csgsali ;

/*Année 2013 (acour)*/
%do j=0 %to 11 ;  %let m= %eval(12-&j.) ; %do t=1 %to 4 ;
	if collm_&acour.t&t. = %eval(&m.) then do ;

		%if &acour. <13 %then %do i=0 %to %eval(&m.-1) ;
			length info_sp%eval(&m.-&i.) $20;
			/*Recodage de l'activité*/
			%let k=%eval(&i.) ; %if &k.<=9 %then %let k=0&k.  ;				
			if sp&k._&acour.t&t. ="6" 									then do; sptot%eval(&m.-&i.) ="9" ; info_sp%eval(&m.-&i.)="origine_&acour t&t";end;
			if sp&k._&acour.t&t. ="5" 									then do; sptot%eval(&m.-&i.) ="7" ; info_sp%eval(&m.-&i.)="origine_&acour t&t";end;
			if sp&k._&acour.t&t. ="4" 									then do; sptot%eval(&m.-&i.) ="5" ; info_sp%eval(&m.-&i.)="origine_&acour t&t";end;
			if sp&k._&acour.t&t. ="3" 									then do; sptot%eval(&m.-&i.) ="4" ; info_sp%eval(&m.-&i.)="origine_&acour t&t";end;
			if sp&k._&acour.t&t. ="2" 									then do; sptot%eval(&m.-&i.) ="3" ; info_sp%eval(&m.-&i.)="origine_&acour t&t";end;
			if sp&k._&acour.t&t. ="1" 									then do; sptot%eval(&m.-&i.) ="1" ; info_sp%eval(&m.-&i.)="origine_&acour t&t";end;
			if sp&k._&acour.t&t. ="1" and rabs_&acour.t&t. ="5" 		then do; sptot%eval(&m.-&i.) ="6" ;  info_sp%eval(&m.-&i.)="origine_&acour t&t";end;  
			if sp&k._&acour.t&t. in ("1","2") & acteu_&acour.t&t. ="3" 	then do; sptot%eval(&m.-&i.) ="9" ; info_sp%eval(&m.-&i.)="origine_&acour t&t";end;
			if sp&k._&acour.t&t. ="1" & stat2_&acour.t&t. ="1" 			then do; sptot%eval(&m.-&i.) ="2" ;  info_sp%eval(&m.-&i.)="origine_&acour t&t";end;

			/*Exploitation de l'ancienneté dans l'état pour prolonger les trajectoires*/
			if sp&k._&acour.t&t.="" and put(ancentr_&acour.t&t.,16.6)  > %eval(&i.) and sp00_&acour.t&t. ="1" then do; sptot%eval(&m.-&i.)="1" ; info_sp%eval(&m.-&i.)="anciennete_&acour t&t";end;
			if sp&k._&acour.t&t.="" and put(ancentr_&acour.t&t.,16.6)  > %eval(&i.) and sp00_&acour.t&t. ="1" and stat2_&acour.t&t.="1" then do; sptot%eval(&m.-&i.)="2" ; info_sp%eval(&m.-&i.)="anciennete_&acour t&t";end;
			if sp&k._&acour.t&t.="" and put(ancinatm_&acour.t&t.,16.6) > %eval(&i.) and sp00_&acour.t&t. ="4" then do; sptot%eval(&m.-&i.)="5" ; info_sp%eval(&m.-&i.)="anciennete_&acour t&t";end;
			if sp&k._&acour.t&t.="" and put(ancchomm_&acour.t&t.,16.6) > %eval(&i.) and sp00_&acour.t&t. ="3" then do; sptot%eval(&m.-&i.)="4" ; info_sp%eval(&m.-&i.)="anciennete_&acour t&t";end;

		%end ;

		%if &acour. >12 %then %do i=0 %to %eval(&m.-1) ;
			/*Recodage de l'activité*/	
			%let k=%eval(&i.) ; %if &k.<=9 %then %let k=0&k.  ;	  
			if sp&k._&acour.t&t. ne " " then do; sptot%eval(&m.-&i.) = sp&k._&acour.t&t. ; info_sp%eval(&m.-&i.)="origine_&acour t&t";end;
			if sp&k._&acour.t&t. in ("1","2") & acteu_&acour.t&t.="3" 	then do; sptot%eval(&m.-&i.)="9" ; info_sp%eval(&m.-&i.)="origine_&acour t&t";end;
			if sp&k._&acour.t&t. ="1" & stat2_&acour.t&t. ="1" 			then do; sptot%eval(&m.-&i.)="2" ; info_sp%eval(&m.-&i.)="origine_&acour t&t";end;

			/*Exploitation de l'ancienneté dans l'état pour prolonger les trajectoires*/
			if sp&k._&acour.t&t.="" and put(ancentr_&acour.t&t.,16.6)  > %eval(&i.) and sp00_&acour.t&t. ="1" then do; sptot%eval(&m.-&i.)="1" ; info_sp%eval(&m.-&i.)="anciennete_&acour t&t";end;
			if sp&k._&acour.t&t.="" and put(ancentr_&acour.t&t.,16.6)  > %eval(&i.) and sp00_&acour.t&t. ="2" then do; sptot%eval(&m.-&i.)="2" ; info_sp%eval(&m.-&i.)="anciennete_&acour t&t";end;
			if sp&k._&acour.t&t.="" and put(ancinatm_&acour.t&t.,16.6) > %eval(&i.) and sp00_&acour.t&t. ="5" then do; sptot%eval(&m.-&i.)="5" ; info_sp%eval(&m.-&i.)="anciennete_&acour t&t";end;
			if sp&k._&acour.t&t.="" and put(ancchomm_&acour.t&t.,16.6) > %eval(&i.) and sp00_&acour.t&t. ="4" then do; sptot%eval(&m.-&i.)="4" ; info_sp%eval(&m.-&i.)="anciennete_&acour t&t";end;

		%end ;

			
	end ;
%end ; %end ;


/*Année 2014 (asuivt1)*/	
%do m=1 %to 3 ;  
	if collm_&asuiv.t1 = %eval(&m.) then do ;

		%do i=&m. %to 11 ;
			/*Recodage de l'activité*/	
			%let k=%eval(&i.) ; %if &k.<=9 %then %let k=0&k.  ;	  
			if sp&k._&asuiv.t1 ne " " then do; sptot%eval(12-(&i.-&m.)) = sp&k._&asuiv.t1 ; info_sp%eval(12-(&i.-&m.))="origine_&asuiv t1";end;
			if sp&k._&asuiv.t1 in ("1","2") & acteu_&acour.t1="3" 	then do; sptot%eval(12-(&i.-&m.))="9" ; info_sp%eval(12-(&i.-&m.))="origine_&asuiv t1";end;
			if sp&k._&asuiv.t1 ="1" & stat2_&asuiv.t1 ="1" 			then do; sptot%eval(12-(&i.-&m.))="2" ; info_sp%eval(12-(&i.-&m.))="origine_&asuiv t1";end;

			/*Exploitation de l'ancienneté dans l'état pour prolonger les trajectoires*/
			if sptot%eval(12-(&i.-&m.))=" " and put(ancentr_&asuiv.t1,16.6) >&i. and sp00_&asuiv.t1 in ("1","2","3") then do; sptot%eval(12-(&i.-&m.))= sp00_&asuiv.t1 ; info_sp%eval(12-(&i.-&m.))="anciennete_&asuiv t1";end;/*%end ;*/
			if sptot%eval(12-(&i.-&m.))=" " and put(ancinatm_&asuiv.t1,16.6) >&i. and sp00_&asuiv.t1 ="5" then do; sptot%eval(12-(&i.-&m.))="5" ; info_sp%eval(12-(&i.-&m.))="anciennete_&asuiv t1";end;
			if sptot%eval(12-(&i.-&m.))=" " and put(ancchomm_&asuiv.t1,16.6) >&i. and sp00_&asuiv.t1 ="4" then do; sptot%eval(12-(&i.-&m.))="4" ; info_sp%eval(12-(&i.-&m.))="anciennete_&asuiv t1";end;
			if sptot%eval(12-(&i.-&m.))=" " and put(ancinatm_&asuiv.t1,16.6) >&i. and rabs_&asuiv.t1 ="5" then do; sptot%eval(12-(&i.-&m.))="6" ; info_sp%eval(12-(&i.-&m.))="anciennete_&asuiv t1";end;

		%end ;
	end ;
%end ; 


/*Les retraités et certains inactifs ne sont interrogés qu'en vagues 1 et 6 : on comble les trous*/
%if &aprec. <13 %then %do i=1 %to 12 ; %let j=1 ; %if &i.>=2 %then %let j=%eval(&i.-1) ;
	if &i.>=2 and sptot&i.="" and sptot&j.="5" then do; sptot&i.=sptot&j. ; info_sp&i.="trous_inact";end;
	if sptot&i.="" and (sptot12 ="5" or sptot11="5" or sptot10="5" or sp00_&asuiv.t1="5" or sp00_&aprec.t4="4") then do;sptot&i.="5" ;	info_sp&i.="trous_inact";end;/* retraite */
	if sptot&i.="" and (sptot12 ="7" or sptot11="7" or sptot10="7" or sp00_&asuiv.t1="7" or sp00_&aprec.t4="5") then do;sptot&i.="7" ; info_sp&i.="trous_inact";end;	/* au foyer */
	if sptot&i.="" and (sptot12 ="3" or sptot11="3" or sptot10="3" or sp00_&asuiv.t1="3" or sp00_&aprec.t4="2") then do;sptot&i.="3" ;	info_sp&i.="trous_inact";end;/* études */
	if sptot&i.="" and ((sp00_&aprec.t4="6" or sptot&j.="9") and (sptot12 ="9" or sptot11="9" or sptot10="9")) then do;sptot&i.="9" ;	info_sp&i.="trous_inact";end;	/* inactivité */
	if sptot&i.="" and (sp00_&asuiv.t1 in ("6", "8", "9") and sp00_&aprec.t4="6") then do;sptot&i.=sp00_&asuiv.t1 ;info_sp&i.="trous_inact";end;
%end ;
%if &aprec. >12 %then %do i=1 %to 12 ; %let j=1 ; %if &i.>=2 %then %let j=%eval(&i.-1) ;
	if &i.>=2 and sptot&i.="" and sptot&j.="5" then do;sptot&i.=sptot&j. ; info_sp&i.="trous_inact";end;
	if sptot&i.="" and (sptot12 ="5" or sptot11="5" or sptot10="5" or sp00_&asuiv.t1="5" or sp00_&aprec.t4="5") then do;sptot&i.="5" ;	info_sp&i.="trous_inact";end;/* retraite */
	if sptot&i.="" and (sptot12 ="7" or sptot11="7" or sptot10="7" or sp00_&asuiv.t1="7" or sp00_&aprec.t4="7") then do;sptot&i.="7" ; info_sp&i.="trous_inact";end;	/* au foyer */
	if sptot&i.="" and (sptot12 ="3" or sptot11="3" or sptot10="3" or sp00_&asuiv.t1="3" or sp00_&aprec.t4="3") then do;sptot&i.="3" ;	info_sp&i.="trous_inact";end;/* études */
	if sptot&i.="" and ((sp00_&aprec.t4="9" or sptot&j.="9") and (sptot12 ="9" or sptot11="9" or sptot10="9")) then do;sptot&i.="9" ;	info_sp&i.="trous_inact";end;	/* inactivité */
	if sptot&i.="" and (sp00_&asuiv.t1 in ("6", "8", "9") and sp00_&aprec.t4 in ("6", "8", "9")) then do;sptot&i.=sp00_&asuiv.t1 ; info_sp&i.="trous_inact";end;
%end ;

/*Les individus décédés au 4ème trimestre définis comme inactifs*/
if deces =1 then do ; sptot10 ='9' ; sptot11 ='9' ; sptot12 ='9' ; end ; 

/**************************************************************************************************************************************************************/
/*		b. Quotité de travail des actifs occupés 																											  */
/**************************************************************************************************************************************************************/


	/** Taux de temps partiel **/

/*Par défault, on attribue un taux de temps partiel à tous les individus. Cela pourrait être utile en cas de redressement de la variable sptot dans la suite du 
programme*/
%do t=1 %to 4 ;
	%do m=%eval(3*&t.-2) %to %eval(3*&t.) ;
		length info_tp&m. $20;
		if txpart_&acour.t&t. ne . then do;
			txpart_&acour.m&m. = txpart_&acour.t&t. ; 
			info_tp&m.="origine_&acour t&t" ; 
			if hsup_prev_&acour.t&t. >0 then hsup_prev_&acour.m&m. = hsup_prev_&acour.t&t. ;
		end;
	%end;
%end;

%do i=1 %to 12;
	if txpart_&acour.m&i.=. and mean(txpart_&acour.t1,txpart_&acour.t2,txpart_&acour.t3,txpart_&acour.t4,txpart_&asuiv.t1)>0 then do; 
		txpart_&acour.m&i.=mean(txpart_&acour.t1,txpart_&acour.t2,txpart_&acour.t3,txpart_&acour.t4,txpart_&asuiv.t1);
		info_tp&i.="moyenne"; 
	end;
	if txpart_&acour.m&i.=. then do; 
		txpart_&acour.m&i=1;
		info_tp&i.="pardefaut"; 
	end;
%end;

/* Définition des quotités mensuelles :													
	- salariés SQUOT_Mi : taux de temps partiel + heures sup/hconv 
	- indépendants IQUOT_Mi : heures travaillées déclarées au mois considéré / nombre d'heures moyen travaillées sur l'année */

if revsal =1 or revind =1 then do ;	/*Individus avec un salaire ou un revenu non salarié déclaré*/

	/*Mois déclarés en activité salariée alors qu'il n'y a pas de salaire dans les sources fiscales, mais des revenus non salariés*/
	%do m=1 %to 12 ;
		if sptot&m. ='1' and revsal=0 then do; sptot&m.='2'; info_sp&m.='nosal'; end; 
	%end;

	%do t=1 %to 4 ; %do m=%eval(3*&t.-2) %to %eval(3*&t.) ;
		if sptot&m. ='2' then do ;
			if nbheur_prev_&acour.t&t. >0 		then nbheur_ind_&acour.m&m. = nbheur_prev_&acour.t&t. ; 
			else if hhc_&acour.t&t. >0 			then nbheur_ind_&acour.m&m. = hhc_&acour.t&t. ; 
			else if empnbh_&acour.t&t. >0 		then nbheur_ind_&acour.m&m. = empnbh_&acour.t&t. ;
		end ; 
	%end ; %end ;
	%do m=1 %to 12 ; /*s'il n'y a pas d'heures déclarées pour un mois, on prend la moyenne des heures travaillées dans l'année*/
		if sptot&m. ='2' & nbheur_ind_&acour.m&m. <=0 then nbheur_ind_&acour.m&m. = mean(of nbheur_ind_&acour.m :) ;
	%end ;
	nbheur_moy_ind = mean(of nbheur_ind_&acour.m :) ;



	nbmsp1 = (sptot1='1')+(sptot2='1')+(sptot3='1')+(sptot4='1')+(sptot5='1')+(sptot6='1')+(sptot7='1')+(sptot8='1')+(sptot9='1')+(sptot10='1')+(sptot11='1')+(sptot12='1') ;
	nbmsp2 = (sptot1='2')+(sptot2='2')+(sptot3='2')+(sptot4='2')+(sptot5='2')+(sptot6='2')+(sptot7='2')+(sptot8='2')+(sptot9='2')+(sptot10='2')+(sptot11='2')+(sptot12='2') ;

	%do m=1 %to 12 ;
		if sptot&m. ='1' then do ; squot_sal_m&m. = txpart_&acour.m&m. ; squot_m&m. =  sum(squot_sal_m&m., hsup_prev_&acour.m&m./hconv) ; end ; 
		if sptot&m. ='2' then do ; iquot_m&m. = nbheur_ind_&acour.m&m. / nbheur_moy_ind ; end ;			
	%end ; 

	squot_sal = SUM(of squot_m :) ; iquot_sal = SUM(of iquot_m :);	
	Smic = &&Smic_h_net_&acour.. ;
		
end;

/*Traitement des incohérences dans les informations relatives aux salariés (salaire horaire inférieur au Smic, salaire déclaré mais quotité égale à 0, 
faibles revenus annuels au regard des mois travaillés, etc.)*/

if revsal =1 then do;		/*si l'individu déclare un salaire*/
	aleatoire=ranuni(10);	/*définition d'une variable aléatoire, graine fixée*/
	if squot_sal =. then squot_sal=0;

/*Individus avec une quotité nulle (i.e. sans aucun mois avec sptot=1)*/
	if squot_sal<=0 then do;
		%do m=1 %to 12 ; 
			if revcho=0 and sptot&m.='4' then do;
				sptot&m.="1";
				info_sp&m.="ajout_chom";
				squot_sal_m&m.=txpart_&acour.m&m.;
				squot_m&m. =  sum(squot_sal_m&m., hsup_prev_&acour.m&m./hconv) ;
			end;

			if revind=0 and sptot&m.='2' then do;
				sptot&m.="1";
				info_sp&m.="ajout_ind";
				squot_sal_m&m.=txpart_&acour.m&m.;
				squot_m&m. =  sum(squot_sal_m&m., hsup_prev_&acour.m&m./hconv) ;
			end;

			if revret=0 and sptot&m.='5' then do;
				sptot&m.="1";
				info_sp&m.="ajout_ret";
				squot_sal_m&m.=txpart_&acour.m&m.;
				squot_m&m. =  sum(squot_sal_m&m., hsup_prev_&acour.m&m./hconv) ;
			end;
		%end;
		nbmsp1 = (sptot1='1') + (sptot2='1') + (sptot3='1') + (sptot4='1') + (sptot5='1') + (sptot6='1')
				+ (sptot7='1') + (sptot8='1') + (sptot9='1') + (sptot10='1') + (sptot11='1') + (sptot12='1') ;
		squot_sal = SUM(of squot_m :);if squot_sal =. then squot_sal=0;
	end;

	
	i_SMIC = (zsal_net / ((squot_sal+1)*151.67) < Smic) ; /*i_SMIC : indice égal à 1 si l'ajout d'un mois d'activité à temps plein fait passer le salaire 
																	 horaire au-dessous du Smic */

/*Individus dont le salaire est déjà au-dessous du Smic avec plus d'un mois d'activité : on supprime des mois d'activité jusqu'à repasser au-dessus du Smic*/
/*On enlève prioritairement les mois prolongés grâce à l'ancienneté ou ajoutés suite à une incohérence (chomage, retraitre, indep)*/
	if nbmsp1>1 & zsal_net/(squot_sal*151.67)< Smic then do ;  

		stop=0 ;
		if aleatoire>=0.5 then do;	/*pour éviter une asymétrie entre la fin et début d'année : on part aléatoirement du début ou de la fin pour supprimer 
									  les mois d'activité*/
			%do mm=1 %to 12 ;
				%let m=&mm.;
				if sptot&m.="1" and index(info_sp&m.,"origine")=0 and nbmsp1>1 and stop=0 and (zsal_net/((squot_sal-squot_m&m.)*151.67)<1.1*Smic) then do;
					sptot&m.="";
					squot_m&m.=0;squot_sal_m&m.=0;
					info_sp&m.="supprime";
					squot_sal = SUM(of squot_m :);
					nbmsp1 = (sptot1='1')+(sptot2='1')+(sptot3='1')+(sptot4='1')+(sptot5='1')+(sptot6='1')+(sptot7='1')+(sptot8='1')+(sptot9='1')+(sptot10='1')+(sptot11='1')+(sptot12='1') ;
					if zsal_net/(squot_sal*151.67)>= Smic then stop=1;
				end;
			%end ;
		end; 
		else do;
			%do mm=1 %to 12 ;
				%let m=%sysevalf(12-&mm.+1);
				if sptot&m.="1" and index(info_sp&m.,"origine")=0 and nbmsp1>1 and stop=0 and (zsal_net/((squot_sal-squot_m&m.)*151.67)<1.1*Smic)then do;
					sptot&m.="";
					squot_m&m.=0;squot_sal_m&m.=0;
					info_sp&m.="supprime";
					squot_sal = SUM(of squot_m :);
					nbmsp1 = (sptot1='1')+(sptot2='1')+(sptot3='1')+(sptot4='1')+(sptot5='1')+(sptot6='1')+(sptot7='1')+(sptot8='1')+(sptot9='1')+(sptot10='1')+(sptot11='1')+(sptot12='1') ;
					if zsal_net/(squot_sal*151.67)>= Smic then stop=1;
				end;
			%end ;
		end;
	end;

	if nbmsp1>1 & zsal_net/(squot_sal*151.67)< Smic then do ;  
		/*on diminue la quotité*/
		squot_sal=zsal_net/(Smic*151.67) ;
		%do m=1 %to 12 ;
			if sptot&m.="1" then do;
				squot_m&m.=squot_sal/nbmsp1; squot_sal_m&m.=squot_sal/nbmsp1;
				txpart_&acour.m&m.=squot_sal/nbmsp1;
				info_tp&m.="diminue";
			END;
		%end ;
	end;

/*Individus au-dessous du Smic avec un seul mois d'activité : on met ces individus au Smic par défaut*/
	if nbmsp1=1 and zsal_net/151.67 < Smic then do ;  /*on les met tous au smic horaire*/
		squot_sal=zsal_net/(Smic*151.67) ;
		%do m=1 %to 12 ; 
			if sptot&m.="1" then do;
				squot_m&m.=squot_sal; squot_sal_m&m.=squot_sal;
				txpart_&acour.m&m.=squot_sal;
				info_tp&m.="diminue";
			end;
		%end ;
	end ;

	/*On redéfinit l'indicatrice i_Smic*/
	i_SMIC = (zsal_net / ((squot_sal+1)*151.67) < Smic) ;

/* Individus au-dessus du Smic : on complète le calendrier sous condition de rester au-dessus du Smic*/

	if i_SMIC =0 then do ;						/*même information que le mois précédent */	/*cas particulier pour le lien entre aprec.t4 et acour.m1*/
		if sptot1 =' ' & SP00_&aprec.t4 ='1' then do; sptot1 ='1' ; info_sp1='prolongement1';end;
		nbmsp1 = (sptot1='1') + (sptot2='1') + (sptot3='1') + (sptot4='1') + (sptot5='1') + (sptot6='1')
				+ (sptot7='1') + (sptot8='1') + (sptot9='1') + (sptot10='1') + (sptot11='1') + (sptot12='1') ;
		if sptot1 ='1' then do ;
			if index(info_tp1,"origine")=0 & txpart_&aprec.t4 >0 then do; txpart_&acour.m1 = txpart_&aprec.t4 ; info_tp1='prolongement1';end;
			if hsup_prev_&acour.m1 =. & hsup_prev_&aprec.t4 >0 	then hsup_prev_&acour.m1 = hsup_prev_&aprec.t4 ;
			squot_sal_m1 = txpart_&acour.m1 ; squot_m1 = sum(squot_sal_m1, hsup_prev_&acour.m1/hconv) ; 
		end ;
		squot_sal = SUM(of squot_m :) ;if squot_sal =. then squot_sal=0;
		if zsal_net>0 then i_SMIC = (zsal_net / ((squot_sal+1)*151.67) < Smic) ;
	end ;
	%let m=2 ; %let j=1 ; %do %while(&m.<=12) ;  	
		if i_SMIC =0 then do ;
			if sptot&m. =' ' & sptot&j. ='1' then do; sptot&m. ='1' ;  info_sp&m.='prolongement2';end;
			nbmsp1 = (sptot1='1') + (sptot2='1') + (sptot3='1') + (sptot4='1') + (sptot5='1') + (sptot6='1')
					+ (sptot7='1') + (sptot8='1') + (sptot9='1') + (sptot10='1') + (sptot11='1') + (sptot12='1') ;
			if sptot&m. ='1' then do ;
				if index(info_tp&m.,"origine")=0 & txpart_&acour.m&j. >0 	then do; txpart_&acour.m&m. = txpart_&acour.m&j. ; info_tp&m.='prolongement2';end;
				if hsup_prev_&acour.m&m. =. & hsup_prev_&acour.m&j. >0 			then hsup_prev_&acour.m&m. = hsup_prev_&acour.m&j. ;
				squot_sal_m&m. = txpart_&acour.m&m. ; squot_m&m. = sum(squot_sal_m&m., hsup_prev_&acour.m&m./hconv) ; 
			end ;
			squot_sal = SUM(of squot_m :) ;	if squot_sal =. then squot_sal=0;
			if zsal_net>0 then i_SMIC = (zsal_net / ((squot_sal+1)*151.67) < Smic) ;
		end ;
	%let m=%eval(&m.+1) ; %let j=%eval(&j.+1) ; %end ;

	if i_SMIC =0 then do ; 							/*même info que le mois suivant*/	/*cas particulier pour le lien entre acour.m12 et asuiv.t1*/
		if sptot12 =' ' & SP00_&asuiv.t1 ='1' then do; sptot12 ='1' ;  info_sp12='prolongement3';end;
		nbmsp1 = (sptot1='1') + (sptot2='1') + (sptot3='1') + (sptot4='1') + (sptot5='1') + (sptot6='1')
				+ (sptot7='1') + (sptot8='1') + (sptot9='1') + (sptot10='1') + (sptot11='1') + (sptot12='1') ;
		if sptot12 ='1' then do ; 
			if index(info_tp12,"origine")=0 & txpart_&asuiv.t1 >0 then do; txpart_&acour.m12 = txpart_&asuiv.t1 ; info_tp12='prolongement3';end;
			if hsup_prev_&acour.m12 =. & hsup_prev_&asuiv.t1 >0 		then hsup_prev_&acour.m12 = hsup_prev_&asuiv.t1 ;
			squot_sal_m12 = txpart_&acour.m12 ; squot_m12 = sum(squot_sal_m12, hsup_prev_&acour.m12/hconv) ; 
		end ;
		squot_sal = SUM(of squot_m :) ;	if squot_sal =. then squot_sal=0;
		if zsal_net>0 then i_SMIC = (zsal_net / ((squot_sal+1)*151.67) < Smic) ;
	end ; 
	%let m=11 ; %let j=12 ; %do %while(&m.>0) ; 
		if i_SMIC =0 then do ; 
			if sptot&m. =' ' & sptot&j. ='1' then do; sptot&m. ='1' ;  info_sp&m.='prolongement4';end;
			nbmsp1 = (sptot1='1') + (sptot2='1') + (sptot3='1') + (sptot4='1') + (sptot5='1') + (sptot6='1')
					+ (sptot7='1') + (sptot8='1') + (sptot9='1') + (sptot10='1') + (sptot11='1') + (sptot12='1') ;
			if sptot&m. ='1' then do ;
				if index(info_tp&m.,"origine")=0 & txpart_&acour.m&j. >0 then do; txpart_&acour.m&m. = txpart_&acour.m&j. ; info_tp&m.='prolongement4';end;
				if hsup_prev_&acour.m&m. =. & hsup_prev_&acour.m&j. >0 			then hsup_prev_&acour.m&m. = hsup_prev_&acour.m&j. ;
				squot_sal_m&m. = txpart_&acour.m&m. ;  squot_m&m. = sum(squot_sal_m&m., hsup_prev_&acour.m&m./hconv) ; 
			end ;
			squot_sal = SUM(of squot_m :) ;	if squot_sal =. then squot_sal=0;
			if zsal_net>0 then i_SMIC = (zsal_net / ((squot_sal+1)*151.67) < Smic) ;
		end ; 
	%let m=%eval(&m.-1) ; %let j=%eval(&j.-1) ; %end ;

/*Individus qui restent sans quotité et dont le salaire annuel est supérieur à un smic mensuel*/
	if squot_sal<=0 and i_smic=0 then do;
		n_mois_ajoutes=0;
		nbm_vide = (sptot1='') + (sptot2='') + (sptot3='') + (sptot4='') + (sptot5='') + (sptot6='')
		+ (sptot7='') + (sptot8='') + (sptot9='') + (sptot10='') + (sptot11='') + (sptot12='') ;
		if 	nbm_vide=0 then do;	/*aucun mois avec sptot non renseigné*/
			%do m=1 %to 12 ;	/*on remplit prioritairement les mois pour lesquels une quotité est renseignée*/
			if index(info_tp&m.,"origine")=1 and i_Smic=0 then do;	/*on s'arrête si l'ajout d'un mois supplémentaure fait passer le salaire horaire en dessous du smic*/
				squot_m&m. = txpart_&acour.m&m. ;
				squot_sal_m&m.=squot_m&m.; 
				sptot&m. ='1';
				info_sp&m.='ajout_1';
				n_mois_ajoutes=n_mois_ajoutes+1;
			end;
			squot_sal = SUM(of squot_m :) ;	if squot_sal =. then squot_sal=0;
			nbmsp1 = (sptot1='1') + (sptot2='1') + (sptot3='1') + (sptot4='1') + (sptot5='1') + (sptot6='1')
			+ (sptot7='1') + (sptot8='1') + (sptot9='1') + (sptot10='1') + (sptot11='1') + (sptot12='1') ;
			if zsal_net>0 then i_SMIC = (zsal_net / ((squot_sal+1)*151.67) < Smic) ;
			%end;
			/*si on n'a toujours pas de mois d'activité, on ajoute les mois un par un tant que le salaire horaire est supérieur au Smic*/
			if squot_sal<=0 then do;
				%do m=1 %to 12 ;
					if i_Smic=0 then do;
						squot_m&m.=txpart_&acour.m&m.;
						squot_sal_m&m.=squot_m&m.; 
						sptot&m. ='1';
						info_sp&m.='ajout_2';
						n_mois_ajoutes=n_mois_ajoutes+1;
					end;
					squot_sal = SUM(of squot_m :) ;	if squot_sal =. then squot_sal=0;
					nbmsp1 = (sptot1='1') + (sptot2='1') + (sptot3='1') + (sptot4='1') + (sptot5='1') + (sptot6='1')
					+ (sptot7='1') + (sptot8='1') + (sptot9='1') + (sptot10='1') + (sptot11='1') + (sptot12='1') ;
					if zsal_net>0 then i_SMIC = (zsal_net / ((squot_sal+1)*151.67) < Smic) ;					
				%end;
			end;
		end;
		else do;	/*on commence par les mois avec sptot non renseigné*/
			%do m=1 %to 12 ;
			if sptot&m.='' and i_Smic=0 then do;	/*on s'arrête si l'ajout d'un mois supplémentaire fait passer le salaire horaire en dessous du smic*/
				squot_m&m. = txpart_&acour.m&m.;
				squot_sal_m&m.=squot_m&m.; 
				sptot&m. ='1';
				info_sp&m.='ajout_3';
				n_mois_ajoutes=n_mois_ajoutes+1;
			end;
			squot_sal = SUM(of squot_m :) ;	if squot_sal =. then squot_sal=0;
			nbmsp1 = (sptot1='1') + (sptot2='1') + (sptot3='1') + (sptot4='1') + (sptot5='1') + (sptot6='1')
			+ (sptot7='1') + (sptot8='1') + (sptot9='1') + (sptot10='1') + (sptot11='1') + (sptot12='1') ;
			if zsal_net>0 then i_SMIC = (zsal_net / ((squot_sal+1)*151.67) < Smic) ;
			%end;

			/*si on n'a toujours pas de mois d'activité salariale, on ajoute les mois un par un tant que le salaire horaire est supérieur au Smic*/
			if squot_sal<=0 then do;
				%do m=1 %to 12 ;
					if i_Smic=0 then do;
						squot_m&m.=txpart_&acour.m&m.;
						squot_sal_m&m.=squot_m&m.; 
						sptot&m. ='1';
						info_sp&m.='ajout_4';
						n_mois_ajoutes=n_mois_ajoutes+1;n_mois_ajoutes=n_mois_ajoutes+1;
					end;
					squot_sal = SUM(of squot_m :) ;	if squot_sal =. then squot_sal=0;
					nbmsp1 = (sptot1='1') + (sptot2='1') + (sptot3='1') + (sptot4='1') + (sptot5='1') + (sptot6='1')
					+ (sptot7='1') + (sptot8='1') + (sptot9='1') + (sptot10='1') + (sptot11='1') + (sptot12='1') ;
					if zsal_net>0 then i_SMIC = (zsal_net / ((squot_sal+1)*151.67) < Smic) ;
				%end;
			end;
		end;
	end;

/* Individus qui restent sans quotité : squot_sal<=0 and i_smic=1 : on met tout sur le premier mois où sptot est non renseigné en adaptant la quotité pour 
rester en dessous du Smic, si tous les sptot sont renseignés, on met sur le 12ème mois */
	if squot_sal<=0 then do;
		stop=0;
		%do m=1 %to 12 ;
			if sptot&m.="" and stop=0 then do;
				/*on les met tous au smic horaire*/
				squot_m&m.=zsal_net/(Smic*151.67) ;
				squot_sal_m&m.=squot_m&m.; 
				txpart_&acour.m&m.=squot_m&m.;
				squot_sal = squot_m&m.;
				sptot&m. ='1';
				info_sp&m.='ajout_5';
				stop=1;
			end;
		%end;
		if stop=0 then do;
			squot_m12=zsal_net/(Smic*151.67) ;
			squot_sal_m12=squot_m12; 
			txpart_&acour.m12=squot_m12;
			squot_sal = squot_m12;
			sptot12 ='1';
			info_sp12='ajout_6';
		end;
		squot_sal = SUM(of squot_m :) ;	if squot_sal =. then squot_sal=0;
		nbmsp1 = (sptot1='1') + (sptot2='1') + (sptot3='1') + (sptot4='1') + (sptot5='1') + (sptot6='1')
		+ (sptot7='1') + (sptot8='1') + (sptot9='1') + (sptot10='1') + (sptot11='1') + (sptot12='1') ;
		if zsal_net>0 then i_SMIC = (zsal_net / ((squot_sal+1)*151.67) < Smic) ;
	end;

	/*Correction de lignes avec des revenus faibles mais des salaires horaires trop elevés*/
	if squot_sal>0 then do;
		sal_h=0; ratio_h=0;ratio_a=0;
		sal_h=zsal_net/(squot_sal*151.67);	/*salaire horaire*/
		ratio_h=sal_h/Smic;
		ratio_a=zsal_net/(Smic*151.67*12); 
		quot_sal_moy=squot_sal/nbmsp1;		/*quotité moyenne pour les mois travaillés*/

		
		if ratio_a<2 and ratio_h>4 then do;
		/*Cas 1 : nombre de mois travaillés trop faible*/
			%do m=1 %to 12 ; 
				if i_SMIC=0 then do;
					if revcho=0 and sptot&m.='4' then do;
						sptot&m.="1";
						info_sp&m.="ajout_chom2";
						squot_sal_m&m.=txpart_&acour.m&m.;
						squot_m&m. =  sum(squot_sal_m&m., hsup_prev_&acour.m&m./hconv) ;
					end;

					if revind=0 and sptot&m.='2' then do;
						sptot&m.="1";
						info_sp&m.="ajout_ind2";
						squot_sal_m&m.=txpart_&acour.m&m.;
						squot_m&m. =  sum(squot_sal_m&m., hsup_prev_&acour.m&m./hconv) ;
					end;

					if revret=0 and sptot&m.='5' then do;
						sptot&m.="1";
						info_sp&m.="ajout_ret2";
						squot_sal_m&m.=txpart_&acour.m&m.;
						squot_m&m. =  sum(squot_sal_m&m., hsup_prev_&acour.m&m./hconv) ;
					end;

					if sptot&m. in ('6','7','8','9') or sptot&m.='' then do;
						sptot&m.="1";
						info_sp&m.="ajout_inact2";
						squot_sal_m&m.=txpart_&acour.m&m.;
						squot_m&m. =  sum(squot_sal_m&m., hsup_prev_&acour.m&m./hconv) ;
					end;
					squot_sal = SUM(of squot_m :) ;	if squot_sal =. then squot_sal=0;
					nbmsp1 = (sptot1='1') + (sptot2='1') + (sptot3='1') + (sptot4='1') + (sptot5='1') + (sptot6='1')
					+ (sptot7='1') + (sptot8='1') + (sptot9='1') + (sptot10='1') + (sptot11='1') + (sptot12='1') ;
					if zsal_net>0 then i_SMIC = (zsal_net / ((squot_sal+1)*151.67) < Smic) ;
				end;
			%end;
		end;
		sal_h=0; ratio_h=0;ratio_a=0;
		sal_h=zsal_net/(squot_sal*151.67);	/*salaire horaire*/
		ratio_h=sal_h/Smic;
		ratio_a=zsal_net/(Smic*151.67*12); 
		quot_sal_moy=squot_sal/nbmsp1;		/*quotité moyenne pour les mois travaillés*/

		/*Cas 2 : quotités trop faibles*/
		if ratio_a<2 and ratio_h>4 then do;
			if zsal_net / ((nbmsp1)*151.67) > Smic and squot_sal<nbmsp1 then do;
				%do m=1 %to 12 ;
					if sptot&m.='1' then do;
						squot_m&m.=1 ;
						squot_sal_m&m.=squot_m&m.; 
						txpart_&acour.m&m.=squot_m&m.;
						info_tp&m.='augmente';
					end;
				%end;
			end;
			else do;
				if quot_sal_moy<0.2 then do; 
					squot_sal=zsal_net/(Smic*151.67);
					%do m=1 %to 12 ;
						if sptot&m.='1' then do;
							squot_m&m.=squot_sal/nbmsp1 ;
							squot_sal_m&m.=squot_m&m.; 
							txpart_&acour.m&m.=squot_m&m.;
							info_tp&m.='augmente';
						end;
					%end;
				end;
			end;
		end;
		squot_sal = SUM(of squot_m :) ;	if squot_sal =. then squot_sal=0;
		nbmsp1 = (sptot1='1') + (sptot2='1') + (sptot3='1') + (sptot4='1') + (sptot5='1') + (sptot6='1')
		+ (sptot7='1') + (sptot8='1') + (sptot9='1') + (sptot10='1') + (sptot11='1') + (sptot12='1') ;
		if zsal_net>0 then i_SMIC = (zsal_net / ((squot_sal+1)*151.67) < Smic) ;

		sal_h=0; ratio_h=0;ratio_a=0;
		sal_h=zsal_net/(squot_sal*151.67);
		ratio_h=sal_h/Smic;
		ratio_a=zsal_net/(Smic*151.67*12); 
		quot_sal_moy=squot_sal/nbmsp1;		/*quotité moyenne pour les mois travaillés*/

	end;

	%do m=1 %to 12 ; 
		if sptot&m. =' ' then do ;	if zchoi >0 then sptot&m. ='4' ; else sptot&m. ='9' ; end ;
	%end ; 

end;

/*Sinon si pas de salaire déclaré dans les sources fiscales*/
else if zsali <=0 then do ;
	
	%do m=1 %to 12 ; 
		if sptot&m. ='1' then do ;	if zchoi >0 then sptot&m. ='4' ; else sptot&m. ='9' ; end ;
	%end ; 
/*Prolongement des trajectoires par (mois suivant/précédent) pour ceux qui n'ont pas déclaré de salaire*/
	%do i=11 %to 1 %by -1 ; %let j=%eval(&i.+1) ;	if sptot&i.='' then sptot&i.=sptot&j. ;	%end ;
	%do i=2 %to 12 ;  %let j=%eval(&i.-1) ;			if sptot&i.='' then sptot&i.=sptot&j. ;	%end ;																				
end ; 

%do m=1 %to 12;
	if squot_m&m.<=0 then do;
		txpart_&acour.m&m.=.;
		info_tp&m.='netravaillepas';
	end;
%end;
nbmsp1 = (sptot1='1')+(sptot2='1')+(sptot3='1')+(sptot4='1')+(sptot5='1')+(sptot6='1')+(sptot7='1')+(sptot8='1')+(sptot9='1')+(sptot10='1')+(sptot11='1')+(sptot12='1') ;

/*Contrôler le prolongement des mois d'activité en cas de présence de chômage ou de retraite*/
if revsal and revcho then do;
	nbmsp4 = (sptot1='4')+(sptot2='4')+(sptot3='4')+(sptot4='4')+(sptot5='4')+(sptot6='4')+(sptot7='4')+(sptot8='4')+(sptot9='4')+(sptot10='4')+(sptot11='4')+(sptot12='4') ;
	if nbmsp4 ne 0 then chom_mens=zchoi/nbmsp4;
	sal_mens=zsali/squot_sal;
	stop=0;
	if chom_mens>sal_mens then do;
		%do m=1 %to 12 ;	/*on supprime en priorité les mois prolongés*/
			if sptot&m.="1" and index(info_sp&m.,"origine")=0 and nbmsp1>1 and stop=0 then do;
				sptot&m.="4";
				squot_m&m.=0;squot_sal_m&m.=0;
				info_sp&m.="supprime->chom";
				squot_sal = SUM(of squot_m :);
				nbmsp1 = (sptot1='1')+(sptot2='1')+(sptot3='1')+(sptot4='1')+(sptot5='1')+(sptot6='1')+(sptot7='1')+(sptot8='1')+(sptot9='1')+(sptot10='1')+(sptot11='1')+(sptot12='1') ;
				nbmsp4 = (sptot1='4')+(sptot2='4')+(sptot3='4')+(sptot4='4')+(sptot5='4')+(sptot6='4')+(sptot7='4')+(sptot8='4')+(sptot9='4')+(sptot10='4')+(sptot11='4')+(sptot12='4') ;
				chom_mens=zchoi/nbmsp4;
				sal_mens=zsali/squot_sal;
				if chom_mens<sal_mens then stop=1;
			end;
		%end;

		%do m=1 %to 12 ;	/*ensuite on supprime les autres mois*/
			if sptot&m.="1" and nbmsp1>1 and stop=0 then do;
				sptot&m.="4";
				squot_m&m.=0;squot_sal_m&m.=0;
				info_sp&m.="supprime->chom";
				squot_sal = SUM(of squot_m :);
				nbmsp1 = (sptot1='1')+(sptot2='1')+(sptot3='1')+(sptot4='1')+(sptot5='1')+(sptot6='1')+(sptot7='1')+(sptot8='1')+(sptot9='1')+(sptot10='1')+(sptot11='1')+(sptot12='1') ;
				nbmsp4 = (sptot1='4')+(sptot2='4')+(sptot3='4')+(sptot4='4')+(sptot5='4')+(sptot6='4')+(sptot7='4')+(sptot8='4')+(sptot9='4')+(sptot10='4')+(sptot11='4')+(sptot12='4') ;
				chom_mens=zchoi/nbmsp4;
				sal_mens=zsali/squot_sal;
				if chom_mens<sal_mens then stop=1;
			end;
		%end;
	end;
end;
drop stop i_smic aleatoire chom_mens sal_mens n_mois_ajoutes ratio_h ratio_a quot_sal_moy sal_h nbm_vide;
run;

%mend ; %base() ;



/*************************************************************************************************************************************************************/
/*				3- Création de la table finale avec le statut d’activité et le détail du temps de travail : variables ACTST, ACTTP, ACTTPD					 */
/*************************************************************************************************************************************************************/

%macro calendrier (a=) ;

data calendrier3 ; set calendrier2 ;

/*On déduit le calendrier d'activité de l'année à partir du statut d'activité mois par mois, et le détail du temps de travail pour les non actifs occupés*/
%do m=1 %to 12 ;
	if sptot&m. = '1' then do ;		if squot_m&m. >0  & revsal >0 then 			actst_m&m. ='1' ;
									else if iquot_m&m. >0 & revind =1 then 		actst_m&m. ='2' ;
									else if revcho =1 then do ; 				actst_m&m. ='3' ; acttp_m&m. ='4' ; acttpd_m&m. ='0' ; end ;
									else do ; 									actst_m&m. ='5' ; acttp_m&m. ='5' ; acttpd_m&m. ='0' ; end ; end ; 

	if sptot&m. = '2' then do;		if squot_m&m. >0 & revsal =1 then 			actst_m&m. ='1' ;
									else if iquot_m&m. >0  & revind >0 then 	actst_m&m. ='2' ;
									else if revcho =1 then do ; 				actst_m&m. ='3' ; acttp_m&m. ='4' ; acttpd_m&m. ='0' ; end ;
									else do ; 									actst_m&m. ='5' ; acttp_m&m. ='5' ; acttpd_m&m. ='0' ; end ; end ; 
	if sptot&m. = '3' then do ; 	if squot_m&m. >0  & revsal >0 then 			actst_m&m. ='1' ;
									else if iquot_m&m. >0 & revind =1 then 		actst_m&m. ='2' ;
									else if revcho =1 then do ; 				actst_m&m. ='3' ; acttp_m&m. ='4' ; acttpd_m&m. ='0' ; end ;
									else do ; 									actst_m&m. ='5' ; acttp_m&m. ='5' ; acttpd_m&m. ='0' ; end ; end;
	if sptot&m. = '4' then do ;		if squot_m&m. >0 & revsal >0 then 			actst_m&m. ='1' ;
									if iquot_m&m. >0 & revind =1 then 			actst_m&m. ='2' ;
									else if revcho =1 then do ; 				actst_m&m. ='3' ; acttp_m&m. ='4' ; acttpd_m&m. ='0' ; end ;
									else do ; 									actst_m&m. ='5' ; acttp_m&m. ='5' ; acttpd_m&m. ='0' ; end ; end ;  
	if sptot&m. = '5' then do ;		if squot_m&m. >0 & revsal >0 then 			actst_m&m. ='1' ;
									if iquot_m&m. >0 & revind =1 then 			actst_m&m. ='2' ;
									else if revret =1 then do ; 				actst_m&m. ='4' ; acttp_m&m. ='5' ; acttpd_m&m. ='0' ; end ; 
									else do ;  									actst_m&m. ='5' ; acttp_m&m. ='5' ; acttpd_m&m. ='0' ; end ; end ; 
	if sptot&m. in ('6', '7', '8', '9') then do ; 
									if squot_m&m. >0 & revsal >0 then 			actst_m&m. ='1' ;
									else if iquot_m&m. >0 & revind =1 then 		actst_m&m. ='2' ;	
									else do ; 									actst_m&m. ='5' ; acttp_m&m. ='5' ; acttpd_m&m. ='0' ; end ; end ; 
%end ;

/*Détail du temps de travail : salariés, indépendants et étudiants qui ont un revenu*/
%do m=1 %to 12 ;

	if actst_m&m. ='1' then do;
		if 0< squot_m&m. <0.5 then do ; 			acttpd_m&m. = '1' ; acttp_m&m. = '1' ; end ;
		if squot_m&m. =0.5 then do ; 				acttpd_m&m. = '2' ; acttp_m&m. = '1' ; end ;
		if 0.5< squot_m&m. <0.8 then do ; 			acttpd_m&m. = '3' ; acttp_m&m. = '2' ; end ;
		if squot_m&m. =0.8 then do ; 				acttpd_m&m. = '4' ; acttp_m&m. = '2' ; end ;
		if 0.8< squot_m&m. <1 then do ; 			acttpd_m&m. = '5' ; acttp_m&m. = '3' ; end ;
		if squot_m&m. >=1 then do ; 				acttpd_m&m. = '6' ; acttp_m&m. = '3' ; end ;		
	end;
	if actst_m&m. = '2' then do ; 
		if 0< iquot_m&m. <0.5 then do ; 			acttpd_m&m. = '1' ; acttp_m&m. = '1' ; end ;
		if iquot_m&m. =0.5 then do ; 				acttpd_m&m. = '2' ; acttp_m&m. = '1' ; end ;
		if 0.5< iquot_m&m. <0.8 then do ; 			acttpd_m&m. = '3' ; acttp_m&m. = '2' ; end ;
		if iquot_m&m. =0.8 then do ; 				acttpd_m&m. = '4' ; acttp_m&m. = '2' ; end ;
		if 0.8< iquot_m&m. <1 then do ; 			acttpd_m&m. = '5' ; acttp_m&m. = '3' ; end ;
		if iquot_m&m. >=1 then do ; 				acttpd_m&m. = '6' ; acttp_m&m. = '3' ; end ;
	end ;

	quot_sal_m&m. = squot_m&m.;
%end ;
quot_sal=squot_sal;


/*Variables traj_var : trajectoire d'emploi*/
length traj_actst $12.; traj_actst=' ';
%do i=1 %to 12; traj_actst=compress(traj_actst!!actst_m&i.); %end;

length traj_acttp $12.; traj_acttp=' ';
%do i=1 %to 12; traj_acttp=compress(traj_acttp!!acttp_m&i.); %end;

length traj_acttpd $12.; traj_acttpd=' '; 
%do i=1 %to 12; traj_acttpd=compress(traj_acttpd!!acttpd_m&i.); %end;


run ;


%mend ; %calendrier(a=&acour.) ; 


/*Sauvegarde de la table  finale*/


data saphir.calend_prof (keep = ident&acour. noi traj_acttp traj_acttpd traj_actst actst_m: acttp_m: acttpd_m: quot_sal:);
set calendrier3;
run;


/*************************************************************************************************************************************************************/
/*************************************************************************************************************************************************************/
/*                       									III. Affectation des revenus aux trimestres	                 								     */
/*************************************************************************************************************************************************************/
/*************************************************************************************************************************************************************/

proc sort data=saphir.calend_prof; by ident&acour. noi; run;
proc sort data=saphir.indivi&acour._R&asuiv4.; by ident&acour. noi; run;
proc sort data=saphir.indivi&acour._R&asuiv3.; by ident&acour. noi; run;
proc sort data=saphir.indivi&acour._R&asuiv2.; by ident&acour. noi; run;
proc sort data=saphir.indivi&acour._R&asuiv.; by ident&acour. noi; run;
proc sort data=saphir.indivi&acour.; by ident&acour. noi; run; 
 
proc sort data=SAPHIR.IRF&acour.E&acour.T4C; by ident&acour. noi; run;


/*Fusion des informations du calendrier professionnel et des revenus vieillis*/
data saphir.trim_rev (compress=yes keep=ident&acour. noi 
zsali: zragi: zrnci: zrici: zchoi: zrsti: salaire_etr&asuiv4._t: salaire_etr&asuiv3._t: salaire_etr&asuiv2._t: 
revsal revindep revcho revretr revsal&asuiv4. revindep&asuiv4. revcho&asuiv4. revretr&asuiv4.
nbm_act: quot_sal: traj_actst  ag forter enceintep3 noienft1 acteu rabs sexe acper: alcnc: ) ;
merge saphir.calend_prof 
saphir.indivi&acour._R&asuiv4. (keep=ident&acour. noi zsali&asuiv4.  zragi&asuiv4. zrici&asuiv4. zrnci&asuiv4. zchoi&asuiv4. zrsti&asuiv4.  salaire_etr&asuiv4.)
saphir.indivi&acour._R&asuiv3. (keep=ident&acour. noi zsali&asuiv3.  zragi&asuiv3. zrici&asuiv3. zrnci&asuiv3. zchoi&asuiv3. zrsti&asuiv3.  salaire_etr&asuiv3.)
saphir.indivi&acour._R&asuiv2. (keep=ident&acour. noi zsali&asuiv2.  zragi&asuiv2. zrici&asuiv2. zrnci&asuiv2. zchoi&asuiv2. zrsti&asuiv2.  salaire_etr&asuiv2.)
saphir.indivi&acour._R&asuiv. (keep=ident&acour. noi zsali&asuiv.  zragi&asuiv. zrici&asuiv. zrnci&asuiv. zchoi&asuiv. zrsti&asuiv.  salaire_etr&asuiv.)
saphir.indivi&acour. (keep=ident&acour. noi zsali zragi zrici zrnci zchoi zrsti  salaire_etr)
saphir.irf&acour.e&acour.t4c (keep=ident&acour. noi ag forter enceintep3 noienft1  sexe acteu rabs  mcho mbjcho acper alcnc
 );
by ident&acour. noi;



/*Type de revenus perçus*/
revsal=(sum(zsali&asuiv2.,salaire_etr&asuiv2.)>0);
revindep=(zragi&asuiv2. not in(.,0) ! zrici&asuiv2. not in(.,0) ! zrnci&asuiv2. not in(.,0)); 
revcho=(zchoi&asuiv2.>0);
revretr=(zrsti&asuiv2.>0);

revsal&asuiv3.=(sum(zsali&asuiv3.,salaire_etr&asuiv3.)>0);
revindep&asuiv3.=(zragi&asuiv3. not in(.,0) ! zrici&asuiv3. not in(.,0) ! zrnci&asuiv3. not in(.,0)); 
revcho&asuiv3.=(zchoi&asuiv3.>0);
revretr&asuiv3.=(zrsti&asuiv3.>0);

revsal&asuiv4.=(sum(zsali&asuiv4.,salaire_etr&asuiv4.)>0);
revindep&asuiv4.=(zragi&asuiv4. not in(.,0) ! zrici&asuiv4. not in(.,0) ! zrnci&asuiv4. not in(.,0)); 
revcho&asuiv4.=(zchoi&asuiv4.>0);
revretr&asuiv4.=(zrsti&asuiv4.>0);


/*NBM_ACTi_Tj : nombre de mois avec l'activité i au trimestre j*/
%macro nbm ; 
%do z=1 %to 4 ; /*1=salarié*/ /*2=indep*/ /*3=chom*/ /*4=retraite*/
	nbm_act&z._t1=(actst_m1=&z.)+(actst_m2=&z.)+(actst_m3=&z.);
	nbm_act&z._t2=(actst_m4=&z.)+(actst_m5=&z.)+(actst_m6=&z.);
	nbm_act&z._t3=(actst_m7=&z.)+(actst_m8=&z.)+(actst_m9=&z.);
	nbm_act&z._t4=(actst_m10=&z.)+(actst_m11=&z.)+(actst_m12=&z.);
	nbm_act&z. =nbm_act&z._t1+nbm_act&z._t2+nbm_act&z._t3+nbm_act&z._t4;
%end ;
%mend ; %nbm ;


%macro mensualisation;

/*Mensualisation des salaires*/

if revsal=1 then do; /*si salaire déclaré*/
	%do i=1 %to 12;
		zsali_m&i.=zsali*quot_sal_m&i./quot_sal;
		salaire_etr_m&i.=salaire_etr*quot_sal_m&i./quot_sal;
		%do an=&asuiv. %to &asuiv4. ;
			zsali&an._m&i.=zsali&an.*quot_sal_m&i./quot_sal;			
			salaire_etr&an._m&i.=salaire_etr&an.*quot_sal_m&i./quot_sal;
		%end ;

	%end;
end;

/*Mensualisation des revenus du chômage et préretraites*/
if revcho=1 then do; /*si revenus de chômage déclarés*/
	%do i=1 %to 12;
		if nbm_act3>0 then do;
			zchoi_m&i.=zchoi/nbm_act3*(actst_m&i.='3');
			%do an=&asuiv. %to &asuiv4. ; zchoi&an._m&i.=zchoi&an./nbm_act3*(actst_m&i.='3'); %end ;		
		end;
		else do;
			zchoi_m&i.=zchoi/12;
			%do an=&asuiv. %to &asuiv4. ; zchoi&an._m&i.=zchoi&an./12; %end ;		
		end;
	%end;
end;
	
/*Mensualisation des pensions de retraites*/
if revretr=1 then do; /*si pension de retraite déclarée*/
	%do i=1 %to 12;
		if nbm_act4>0 then do;
			zrsti_m&i.=zrsti/nbm_act4*(actst_m&i.='4');
			%do an=&asuiv. %to &asuiv4. ; zrsti&an._m&i.=zrsti&an./nbm_act4*(actst_m&i.='4'); %end ;
		end;
		else do;
			zrsti_m&i.=zrsti/12;
			%do an=&asuiv. %to &asuiv4. ; zrsti&an._m&i.=zrsti&an./12; %end ;
		end;
	%end;
end;

/*Mensualisation des revenus d'indépendants*/
if revindep=1 then do; 		/*si revenus non salariés déclarés*/
	if nbm_act2>0 then do; 	/*si a au moins un mois d'activité indépendante*/
		%do i=1 %to 12; 	
			%do an=&asuiv. %to &asuiv4. ;
			zragi&an._m&i.=zragi&an./nbm_act2*(actst_m&i.='2');
			zrnci&an._m&i.=zrnci&an./nbm_act2*(actst_m&i.='2');
			zrici&an._m&i.=zrici&an./nbm_act2*(actst_m&i.='2');
			%end ;
			zragi_m&i.=zragi/nbm_act2*(actst_m&i.='2');
			zrnci_m&i.=zrnci/nbm_act2*(actst_m&i.='2');
			zrici_m&i.=zrici/nbm_act2*(actst_m&i.='2');
		%end;
		nbm_indep=nbm_act2;
	end;
	else if nbm_act1>0 then do; /*si a au moins un mois d'activité salariée*/
		%do i=1 %to 12;
			%do an=&asuiv. %to &asuiv4. ;
			zragi&an._m&i.=zragi&an./nbm_act1*(actst_m&i.='1');
			zrnci&an._m&i.=zrnci&an./nbm_act1*(actst_m&i.='1');
			zrici&an._m&i.=zrici&an./nbm_act1*(actst_m&i.='1');
			%end ;
			zragi_m&i.=zragi/nbm_act1*(actst_m&i.='1');
			zrnci_m&i.=zrnci/nbm_act1*(actst_m&i.='1');
			zrici_m&i.=zrici/nbm_act1*(actst_m&i.='1');
		%end;
		nbm_indep=nbm_act1;
	end;
	else do; 
		%do i=1 %to 12;
			%do an=&asuiv. %to &asuiv4. ;
			zragi&an._m&i.=zragi&an./12;
			zrnci&an._m&i.=zrnci&an./12;
			zrici&an._m&i.=zrici&an./12;
			%end ;
			zragi_m&i.=zragi/12;
			zrnci_m&i.=zrnci/12;
			zrici_m&i.=zrici/12;
		%end;
		nbm_indep=12;
	end;
end;
%mend;
%mensualisation;


/*Trimestrialisation des revenus*/
%macro trim (var=) ;
%do k=2 %to 4 ; 
	&&var&&asuiv&k.._t1=sum(&&var&&asuiv&k.._m1,&&var&&asuiv&k.._m2,&&var&&asuiv&k.._m3);
	&&var&&asuiv&k.._t2=sum(&&var&&asuiv&k.._m4,&&var&&asuiv&k.._m5,&&var&&asuiv&k.._m6);
	&&var&&asuiv&k.._t3=sum(&&var&&asuiv&k.._m7,&&var&&asuiv&k.._m8,&&var&&asuiv&k.._m9);
	&&var&&asuiv&k.._t4=sum(&&var&&asuiv&k.._m10,&&var&&asuiv&k.._m11,&&var&&asuiv&k.._m12);
%end ;
%mend ;

if revsal=1 then do;   %trim (var=zsali) ; end; /*zsali12_ti : salaire au ieme trimestre*/
if revsal=1 then do;   %trim (var=salaire_etr) ; end;
if revcho=1 then do;   %trim (var=zchoi) ; end; /*zchoi12_ti : indemnité au ieme trimestre*/
if revretr=1 then do;  %trim (var=zrsti) ; end; /*zrsti12_ti : pension au ieme trimestre*/
if revindep=1 then do; %trim (var=zragi) ;  %trim (var=zrnci) ;  %trim (var=zrici) ;  end; 

run;

/*************************************************************************************************************************************************************
**************************************************************************************************************************************************************

Ce logiciel est régi par la licence CeCILL V2.1 soumise au droit français et respectant les principes de diffusion des logiciels libres. 

Vous pouvez utiliser, modifier et/ou redistribuer ce programme sous les conditions de la licence CeCILL V2.1. 

Le texte complet de la licence CeCILL V2.1 est dans le fichier `LICENSE`.

Les paramètres de la législation socio-fiscale figurant dans les programmes 6, 7a et 7b sont régis par la « Licence Ouverte / Open License » Version 2.0.
**************************************************************************************************************************************************************
*************************************************************************************************************************************************************/

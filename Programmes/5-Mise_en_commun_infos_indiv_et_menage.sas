

/**************************************************************************************************************************************************************/
/*                              									  SAPHIR E2013 L2017                                  							          */
/*                                     									  PROGRAMME 5                                         			     			      */
/*                           									Mise en commun des informations																  */
/**************************************************************************************************************************************************************/


/**************************************************************************************************************************************************************/
/* Mise en commun du travail effectué dans les programmes précédents :  																						  */
/* 		- Tables EEC enrichies et corrigées    																												  */
/* 		- Pondérations 2013 et 2017          																											   	  */
/* 		- Revenus vieillis 2014, 2015, 2016 et 2017																											  */
/**************************************************************************************************************************************************************/


/**************************************************************************************************************************************************************/
/**************************************************************************************************************************************************************/
/*                       										I. Informations individuelles			                 								      */
/**************************************************************************************************************************************************************/
/**************************************************************************************************************************************************************/

/**************************************************************************************************************************************************************/
/*				1- Revenus individualisables											                 												      */
/**************************************************************************************************************************************************************/

/*Revenus individuels annuels 2013*/
proc sort data=saphir.indivi&acour.; by ident&acour. noi; run;

/*Revenus individuels annuels 2014*/
proc sort data=saphir.indivi&acour._r&asuiv.; by ident&acour. noi; run;

/*Revenus individuels annuels 2015*/
proc sort data=saphir.indivi&acour._r&asuiv2.; by ident&acour. noi; run;

/*Revenus individuels annuels 2016*/
proc sort data=saphir.indivi&acour._r&asuiv3.; by ident&acour. noi; run;

/*Revenus individuels annuels 2017*/
proc sort data=saphir.indivi&acour._r&asuiv4.; by ident&acour. noi; run;

/*Revenus trimestrialisés*/
proc sort data=saphir.trim_rev; by ident&acour. noi; run;


/**************************************************************************************************************************************************************/
/*				2- Ajout des revenus non individualisables									                 											      */
/**************************************************************************************************************************************************************/

/*On affecte les revenus non individualisables au déclarant de la déclaration d'impôt*/
/*Pour les produits financiers, on les attribue à la personne de référence du logement*/

/*Revenus non individualisables par individu*/
proc means data=saphir.foyer&acour._r&asuiv. noprint nway;
class ident&acour. noi;
var  ZFONf&asuiv. ZVAMf&asuiv. ZVALf&asuiv. ZETRf&asuiv. ZRACf&asuiv. ZALVf&asuiv.
	ZGLOf&asuiv. ZDIVf&asuiv. ztsaf&asuiv. zperf&asuiv.;
output out=patid (drop=_type_ _freq_) sum=  ZFONfd&asuiv. ZVAMfd&asuiv. ZVALfd&asuiv. ZETRfd&asuiv. ZRACfd&asuiv. ZALVfd&asuiv.
	ZGLOfd&asuiv. ZDIVfd&asuiv. ztsafd&asuiv. zperfd&asuiv. ;
run;

/*Revenus non individualisables par ménage*/
proc means data=saphir.foyer&acour._r&asuiv. noprint nway;
class ident&acour.;
var  ZFONf&asuiv. ZVAMf&asuiv. ZVALf&asuiv. ZETRf&asuiv. ZRACf&asuiv. ZALVf&asuiv.
	ZGLOf&asuiv. ZDIVf&asuiv. ztsaf&asuiv. zperf&asuiv.;
output out=patmen (drop=_type_ _freq_) sum=ZFONfm&asuiv. ZVAMfm&asuiv. ZVALfm&asuiv. ZETRfm&asuiv. ZRACfm&asuiv. ZALVfm&asuiv.
	ZGLOfm&asuiv. ZDIVfm&asuiv. ztsafm&asuiv. zperfm&asuiv. ;
run;

/*Calcul d'une clef de répartition par individu*/
data id_pat;
merge patid patmen;
by ident&acour.;
run;


data id_pat (keep=ident&acour. noi partZFON partZVAM partZVAL partZETR partZRAC partZALV partZGLO partZDIV);
set id_pat;
%macro calcul_part(listvar=);
%let i=1;
%do %while(%index(&listvar.,%scan(&listvar.,&i.))>0); 
	%let var=%scan(&listvar.,&i.);
		if &var.fd&asuiv.>0 then part&var.=&var.fd&asuiv./&var.fm&asuiv.;
		else part&var.=0;
	%let i=%eval(&i.+1);
%end;
%mend;
%calcul_part(listvar=ZFON ZVAM ZVAL ZETR ZRAC ZALV ZGLO ZDIV);

run;


/*Revenus non individualisables 2013*/
data revni&acour. (compress=yes keep = ident&acour.  ZFONM ZVAMM ZVALM ZETRM ZRACM ZALVM produitfin ZGLOm ZDIVm 
rename=( ZFONM=ZFONMi ZVAMM=ZVAMMi ZVALM=ZVALMi ZETRM= ZETRMi
ZRACM=ZRACMi ZALVM=ZALVMi  ZGLOM=ZGLOMi ZDIVM=ZDIVMi));
set erfs.menage&acour.;
run;

proc sort data=revni&acour.; by ident&acour.; run;
 

/*Revenus non individualisables 2014*/
data revni&asuiv. (compress=yes keep = ident&acour. ZFONM&asuiv. ZVAMM&asuiv. ZVALM&asuiv. ZETRM&asuiv. ZRACM&asuiv. ZALVM&asuiv. 
	produitfin&asuiv. ZGLOM&asuiv. ZDIVM&asuiv. rename=( ZFONM&asuiv.=ZFONM&asuiv.i ZVAMM&asuiv.=ZVAMM&asuiv.i ZVALM&asuiv.=ZVALM&asuiv.i ZETRM&asuiv.= ZETRM&asuiv.i
ZRACM&asuiv.=ZRACM&asuiv.i ZALVM&asuiv.=ZALvM&asuiv.i  ZGLOM&asuiv.=ZGLOM&asuiv.i ZDIVM&asuiv.=ZDIVM&asuiv.i));
set saphir.menage&acour._r&asuiv.;
run;

proc sort data=revni&asuiv.; by ident&acour.; run;

/*Revenus non individualisables 2015*/
data revni&asuiv2. (compress=yes keep = ident&acour.  ZFONM&asuiv2. ZVAMM&asuiv2. ZVALM&asuiv2. ZETRM&asuiv2. ZRACM&asuiv2. ZALVM&asuiv2.
	produitfin&asuiv2. ZGLOM&asuiv2. ZDIVM&asuiv2. rename=( ZFONM&asuiv2.=ZFONM&asuiv2.i ZVAMM&asuiv2.=ZVAMM&asuiv2.i ZVALM&asuiv2.=ZVALM&asuiv2.i ZETRM&asuiv2.= ZETRM&asuiv2.i
ZRACM&asuiv2.=ZRACM&asuiv2.i ZALVM&asuiv2.=ZALVM&asuiv2.i  ZGLOM&asuiv2.=ZGLOM&asuiv2.i ZDIVM&asuiv2.=ZDIVM&asuiv2.i));
set saphir.menage&acour._r&asuiv2.;
run;

proc sort data=revni&asuiv2.; by ident&acour.; run;

/*Revenus non individualisables 2016*/
data revni&asuiv3. (compress=yes keep = ident&acour.  ZFONM&asuiv3. ZVAMM&asuiv3. ZVALM&asuiv3. ZETRM&asuiv3. ZRACM&asuiv3. ZALVM&asuiv3.
	produitfin&asuiv3. ZGLOM&asuiv3. ZDIVM&asuiv3. rename=( ZFONM&asuiv3.=ZFONM&asuiv3.i ZVAMM&asuiv3.=ZVAMM&asuiv3.i ZVALM&asuiv3.=ZVALM&asuiv3.i ZETRM&asuiv3.= ZETRM&asuiv3.i
ZRACM&asuiv3.=ZRACM&asuiv3.i ZALVM&asuiv3.=ZALVM&asuiv3.i  ZGLOM&asuiv3.=ZGLOM&asuiv3.i ZDIVM&asuiv3.=ZDIVM&asuiv3.i));
set saphir.menage&acour._r&asuiv3.;
run;

proc sort data=revni&asuiv3.; by ident&acour.; run;

/*Revenus non individualisables 2017*/
data revni&asuiv4. (compress=yes keep = ident&acour.  ZFONM&asuiv4. ZVAMM&asuiv4. ZVALM&asuiv4. ZETRM&asuiv4. ZRACM&asuiv4. ZALVM&asuiv4.
	produitfin&asuiv4. ZGLOM&asuiv4. ZDIVM&asuiv4. rename=( ZFONM&asuiv4.=ZFONM&asuiv4.i ZVAMM&asuiv4.=ZVAMM&asuiv4.i ZVALM&asuiv4.=ZVALM&asuiv4.i ZETRM&asuiv4.= ZETRM&asuiv4.i
ZRACM&asuiv4.=ZRACM&asuiv4.i ZALVM&asuiv4.=ZALVM&asuiv4.i  ZGLOM&asuiv4.=ZGLOM&asuiv4.i ZDIVM&asuiv4.=ZDIVM&asuiv4.i));
set saphir.menage&acour._r&asuiv4.;
run;

proc sort data=revni&asuiv4.; by ident&acour.; run;


/**************************************************************************************************************************************************************/
/*				3- Données individuelles EEC												                 											      */
/**************************************************************************************************************************************************************/

proc sort data=saphir.irf&acour.e&acour.t4c; by ident&acour. noi; run;

/**************************************************************************************************************************************************************/
/*				4- Données du calendrier professionnel										                 											      */
/**************************************************************************************************************************************************************/

proc sort data=saphir.calend_prof; by ident&acour. noi; run;

/**************************************************************************************************************************************************************/
/*				5- Pondérations																                 											      */
/**************************************************************************************************************************************************************/

proc sort data=saphir.pond; by ident&acour.; run;

/**************************************************************************************************************************************************************/
/*				6- Mise en commun															                 											      */
/**************************************************************************************************************************************************************/

data saphir.indiv_saphir (compress = yes 
drop = datdeb datqi mvl chgm modetelvis rdqf res enfred);
length ident&acour. $8. noi $2.;
merge saphir.irf&acour.e&acour.t4c 
saphir.indivi&acour. (in=a) saphir.indivi&acour._r&asuiv. saphir.indivi&acour._r&asuiv2. saphir.indivi&acour._r&asuiv3. saphir.indivi&acour._r&asuiv4. 
saphir.trim_rev
saphir.calend_prof
id_pat; 
by ident&acour. noi;
if a;

%macro zero (liste=);
	%let i=1;
	%do %while (%index(&liste.,%scan(&liste.,&i.))>0);
		if %scan(&liste.,&i.)=. then %scan(&liste.,&i.)=0;
		%let i=%eval(&i.+1);
	%end;
%mend;

%zero(liste=
ZSALI&asuiv._t1 ZSALI&asuiv._t2 ZSALI&asuiv._t3 ZSALI&asuiv._t4 
ZRAGI&asuiv._t1 ZRAGI&asuiv._t2 ZRAGI&asuiv._t3 ZRAGI&asuiv._t4 
ZRICI&asuiv._t1 ZRICI&asuiv._t2 ZRICI&asuiv._t3 ZRICI&asuiv._t4 
ZRNCI&asuiv._t1 ZRNCI&asuiv._t2 ZRNCI&asuiv._t3 ZRNCI&asuiv._t4 
ZCHOI&asuiv._t1 ZCHOI&asuiv._t2 ZCHOI&asuiv._t3 ZCHOI&asuiv._t4 
ZRSTI&asuiv._t1 ZRSTI&asuiv._t2 ZRSTI&asuiv._t3 ZRSTI&asuiv._t4 

ZSALI&asuiv2._t1 ZSALI&asuiv2._t2 ZSALI&asuiv2._t3 ZSALI&asuiv2._t4 
ZRAGI&asuiv2._t1 ZRAGI&asuiv2._t2 ZRAGI&asuiv2._t3 ZRAGI&asuiv2._t4 
ZRICI&asuiv2._t1 ZRICI&asuiv2._t2 ZRICI&asuiv2._t3 ZRICI&asuiv2._t4 
ZRNCI&asuiv2._t1 ZRNCI&asuiv2._t2 ZRNCI&asuiv2._t3 ZRNCI&asuiv2._t4 
ZCHOI&asuiv2._t1 ZCHOI&asuiv2._t2 ZCHOI&asuiv2._t3 ZCHOI&asuiv2._t4 
ZRSTI&asuiv2._t1 ZRSTI&asuiv2._t2 ZRSTI&asuiv2._t3 ZRSTI&asuiv2._t4
 
ZSALI&asuiv3._t1 ZSALI&asuiv3._t2 ZSALI&asuiv3._t3 ZSALI&asuiv3._t4 
ZRAGI&asuiv3._t1 ZRAGI&asuiv3._t2 ZRAGI&asuiv3._t3 ZRAGI&asuiv3._t4 
ZRICI&asuiv3._t1 ZRICI&asuiv3._t2 ZRICI&asuiv3._t3 ZRICI&asuiv3._t4 
ZRNCI&asuiv3._t1 ZRNCI&asuiv3._t2 ZRNCI&asuiv3._t3 ZRNCI&asuiv3._t4 
ZCHOI&asuiv3._t1 ZCHOI&asuiv3._t2 ZCHOI&asuiv3._t3 ZCHOI&asuiv3._t4 
ZRSTI&asuiv3._t1 ZRSTI&asuiv3._t2 ZRSTI&asuiv3._t3 ZRSTI&asuiv3._t4 

ZSALI&asuiv4._t1 ZSALI&asuiv4._t2 ZSALI&asuiv4._t3 ZSALI&asuiv4._t4 
ZRAGI&asuiv4._t1 ZRAGI&asuiv4._t2 ZRAGI&asuiv4._t3 ZRAGI&asuiv4._t4 
ZRICI&asuiv4._t1 ZRICI&asuiv4._t2 ZRICI&asuiv4._t3 ZRICI&asuiv4._t4 
ZRNCI&asuiv4._t1 ZRNCI&asuiv4._t2 ZRNCI&asuiv4._t3 ZRNCI&asuiv4._t4 
ZCHOI&asuiv4._t1 ZCHOI&asuiv4._t2 ZCHOI&asuiv4._t3 ZCHOI&asuiv4._t4 
ZRSTI&asuiv4._t1 ZRSTI&asuiv4._t2 ZRSTI&asuiv4._t3 ZRSTI&asuiv4._t4 

revcho revretr);

if declar2 ne "" then do;
	noi_dec2=substr(declar2,1,2);
	if noi_dec2=noi then persfip2="vous";
	else persfip2="pac";
end;
run;

data saphir.indiv_saphir (compress=yes drop=
ZFONM&asuiv.i ZVAMM&asuiv.i ZVALM&asuiv.i ZETRM&asuiv.i ZRACM&asuiv.i ZALvM&asuiv.i  ZGLOM&asuiv.i ZDIVM&asuiv.i 
ZFONM&asuiv2.i ZVAMM&asuiv2.i ZVALM&asuiv2.i ZETRM&asuiv2.i ZRACM&asuiv2.i ZALvM&asuiv2.i  ZGLOM&asuiv2.i ZDIVM&asuiv2.i  
ZFONM&asuiv3.i ZVAMM&asuiv3.i ZVALM&asuiv3.i ZETRM&asuiv3.i ZRACM&asuiv3.i ZALvM&asuiv3.i  ZGLOM&asuiv3.i ZDIVM&asuiv3.i  
ZFONM&asuiv4.i ZVAMM&asuiv4.i ZVALM&asuiv4.i ZETRM&asuiv4.i ZRACM&asuiv4.i ZALvM&asuiv4.i  ZGLOM&asuiv4.i ZDIVM&asuiv4.i  
ZFONMi ZVAMMi ZVALMi ZETRMi ZRACMi ZALvMi  ZGLOMi ZDIVMi);
merge saphir.indiv_saphir saphir.pond revni&acour. revni&asuiv. revni&asuiv2. revni&asuiv3. revni&asuiv4.;
by ident&acour. ;

%macro affect_revpat(an,listvar);
%let i=1;
%do %while(%index(&listvar.,%scan(&listvar.,&i.))>0); 
	%let var=%scan(&listvar.,&i.);
	&var.M&an.=part&var.*&var.M&an.i;
	%let i=%eval(&i.+1);
%end;
%mend;
%affect_revpat( ,ZFON ZVAM ZVAL ZETR ZRAC ZALV ZGLO ZDIV);
%affect_revpat(&asuiv.,ZFON ZVAM ZVAL ZETR ZRAC ZALV ZGLO ZDIV);
%affect_revpat(&asuiv2.,ZFON ZVAM ZVAL ZETR ZRAC ZALV ZGLO ZDIV);
%affect_revpat(&asuiv3.,ZFON ZVAM ZVAL ZETR ZRAC ZALV ZGLO ZDIV);
%affect_revpat(&asuiv4.,ZFON ZVAM ZVAL ZETR ZRAC ZALV ZGLO ZDIV);

REVPATM=sum(ZFONM,ZVAMM,ZVALM,ZETRM,ZRACM);
REVPATM&asuiv.=sum(ZFONM&asuiv.,ZVAMM&asuiv.,ZVALM&asuiv.,ZETRM&asuiv.,ZRACM&asuiv.);
REVPATM&asuiv2.=sum(ZFONM&asuiv2.,ZVAMM&asuiv2.,ZVALM&asuiv2.,ZETRM&asuiv2.,ZRACM&asuiv2.);
REVPATM&asuiv3.=sum(ZFONM&asuiv3.,ZVAMM&asuiv3.,ZVALM&asuiv3.,ZETRM&asuiv3.,ZRACM&asuiv3.);
REVPATM&asuiv4.=sum(ZFONM&asuiv4.,ZVAMM&asuiv4.,ZVALM&asuiv4.,ZETRM&asuiv4.,ZRACM&asuiv4.);

run;

/*On supprime les doublons de la table indiv_saphir*/
proc sort data=saphir.indiv_saphir  nodupkey;
    by ident&acour. noi;
 run;

/*Nettoyage WORK*/
proc datasets library=work;
delete  revni : id_pat patid patmen;
run;
quit;

data saphir.indiv_saphir;
set saphir.indiv_saphir;

/*On met à zéro les revenus non individualisables des personnes qui ne sont pas les personnes de référence du ménage*/
if lprm ne '1' then do;
	produitfin=0;
	produitfin&asuiv.=0;
	produitfin&asuiv2.=0;
	produitfin&asuiv3.=0;
	produitfin&asuiv4.=0;
end;
run;



/**************************************************************************************************************************************************************/
/**************************************************************************************************************************************************************/
/*                       											II. Informations du ménage			                 								      */
/**************************************************************************************************************************************************************/
/**************************************************************************************************************************************************************/

proc sort data=saphir.menage&acour.; by ident&acour.; run;
proc sort data=saphir.menage&acour._r&asuiv.; by ident&acour.; run;
proc sort data=saphir.menage&acour._r&asuiv2.; by ident&acour.; run;
proc sort data=saphir.menage&acour._r&asuiv3.; by ident&acour.; run;
proc sort data=saphir.menage&acour._r&asuiv4.; by ident&acour.; run;


data saphir.menage_saphir (compress = yes drop = datdeb res chgm mvl);
length ident&acour. $8.;
merge saphir.mrf&acour.e&acour.t4c 
saphir.menage&acour. (in=a)  saphir.menage&acour._r&asuiv. saphir.menage&acour._r&asuiv2. saphir.menage&acour._r&asuiv3. saphir.menage&acour._r&asuiv4. 
saphir.pond;
by ident&acour. ;
if a;
run;

/*************************************************************************************************************************************************************
**************************************************************************************************************************************************************

Ce logiciel est régi par la licence CeCILL V2.1 soumise au droit français et respectant les principes de diffusion des logiciels libres. 

Vous pouvez utiliser, modifier et/ou redistribuer ce programme sous les conditions de la licence CeCILL V2.1. 

Le texte complet de la licence CeCILL V2.1 est dans le fichier `LICENSE`.

Les paramètres de la législation socio-fiscale figurant dans les programmes 6, 7a et 7b sont régis par la « Licence Ouverte / Open License » Version 2.0.
**************************************************************************************************************************************************************
*************************************************************************************************************************************************************/

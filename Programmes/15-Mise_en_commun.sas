
/**************************************************************************************************************************************************************/
/*                                  								 SAPHIR E2013 L2017                                    									  */
/*                                       								PROGRAMME 15                                         								  */
/*                     									 Mise en commun des données impots et prestations                      								  */
/**************************************************************************************************************************************************************/


/**************************************************************************************************************************************************************/			
/* Le revenu disponible est une variable clé de Saphir. Plusieurs niveau de revenus sont détaillés pour aboutir au revenu disponible :						  */
/*		- Le revenu primaire, qui correspond au revenu national brut (revenus d'activité super-brut et revenus du capital) ;								  */
/*		- Le revenu perçu, qui correspond aux revenus déclarés après déduction de la CSG déductible et de la CRDS (on retire également les cotisations		  */
/*		  sociales sur les revenus du capital) ;																											  */
/*		- Le revenu disponible qui comprend les revenus d'activité, les revenus du patrimoine, les transferts en provenance d'autres ménages et les			  */
/*		  prestations sociales (y compris pensions de retraite et indemnités de chômages), nets des impôts directs (IR, TH, CSG et CRDS).					  */
/* Le revenu disposible se calcule au niveau du ménage. Le concept de niveau de vie est utilisé pour comparer la situation de ménages de taille différente. Il*/
/* s'agit du revenu disponible du ménage rapporté au nombre d'unités de consommation (1 pour le premier adulte, 0,5 pour les autres adultes ou enfants de plus*/
/* de 14 ans et 0,3 pour les enfants de moins de 14 ans). 																									  */
/* 																																							  */
/* Ce programme met en commun de l'ensemble des données (revenus, impots, prestations) au niveau du ménage				  									  */
/**************************************************************************************************************************************************************/



/**************************************************************************************************************************************************************/
/**************************************************************************************************************************************************************/
/*            												 I. Mise en commun au niveau menage                    											  */
/**************************************************************************************************************************************************************/
/**************************************************************************************************************************************************************/

/**************************************************************************************************************************************************************/
/*				1- Données impots 																		 													  */
/**************************************************************************************************************************************************************/

/*** a- Impôt FIP ***/
proc means data=scenario.impot_fip_R&asuiv3. noprint; by ident&acour.;
var impot credit prel_liberatoire; output out=impot_R&asuiv._men (drop = _TYPE_ _FREQ_) sum=;
run;

/*** b- Impôt simplifié ***/
proc means data=scenario.impot_simp_R&asuiv3. noprint; by ident&acour.;
var impots; output out=impots_R&asuiv._men (drop = _TYPE_ _FREQ_) sum=;
run;

/**************************************************************************************************************************************************************/
/*				2- Données famille 21 ans 																	  												  */
/**************************************************************************************************************************************************************/

/*On récupère l'info sur le rsa pour la neutralisation des ressources dans le calcul des AL*/
proc sort data=scenario.prest_fam21; by ident&acour. noi_prpf; run; 
proc sort data=scenario.non_recours out=foy_rsa ; by ident&acour. numfoyrsa; run;
data numfoy  ; merge foy_rsa scenario.rsa (keep=ident&acour. numfoyrsa noi_prrsa) ; by ident&acour. numfoyrsa ; run ;

proc sort data=numfoy (keep=ident&acour. numfoyrsa rsa_t: noi_prrsa) ; by ident&acour. noi_prrsa; run;

data scenario.prest_fam21 ; merge scenario.prest_fam21 numfoy (rename= (noi_prrsa=noi_prpf) ); by ident&acour. noi_prpf; run ;

/*On calcule un montant d'AL qui pondère la neutralisation des ressources par le nombre de trimestres avec perception du rsa */
data scenario.prest_fam21 (drop=nb_trim_rsa) ; set scenario.prest_fam21 ; 
al_ss_neutr=al ;
nb_trim_rsa=(rsa_t1>0) + (rsa_t2>0) + (rsa_t3>0) + (rsa_t4>0) ;
if nb_trim_rsa>0 and al_loc_rsa>0 then al= (4-nb_trim_rsa)*(al_ss_neutr/4) + (nb_trim_rsa)*(al_loc_rsa/4) ; run  ;


proc means data=scenario.prest_fam21 noprint; by ident&acour.;
var al al_ss_neutr al_loc al_loc_rsa aforf ;
output out=prest21_men (drop = _TYPE_ _FREQ_) sum=;
run;

/**************************************************************************************************************************************************************/
/*				3- Données famille 20 ans 																	 												  */
/**************************************************************************************************************************************************************/
proc sort data=scenario.prest_fam20; by ident&acour.; run;

proc means data=scenario.prest_fam20 noprint; by ident&acour.;
var  asf afssmaj majaf af ab_paje pn_paje clca ars aah minvi cf cf_base;
output out=prest20_men (drop = _TYPE_ _FREQ_) sum=;
run;


/**************************************************************************************************************************************************************/
/*				4- Données RSA 																	 												  			  */
/**************************************************************************************************************************************************************/

proc sort data=scenario.rsa; by ident&acour.; run;

proc means data=scenario.rsa noprint; by ident&acour.;
var  rsa_pr_t1 rsa_pr_t2 rsa_pr_t3 rsa_pr_t4 prime_pr_t1 prime_pr_t2 prime_pr_t3 prime_pr_t4 rsa_pr prime_pr elig_cmuc elig_acs pers_cmuc pers_acs nbpers ;
output out=rsa_men (drop = _TYPE_ _FREQ_) sum=;
run;

/*** Introduction du non-recours ***/
proc means data=scenario.non_recours noprint nway;
class ident&acour.;
var rsa prime;
output out=rsa_nr_men sum=;
run;


/**************************************************************************************************************************************************************/
/*				5- Mise en commun 																	 								 			  			  */
/**************************************************************************************************************************************************************/
proc sort data=scenario.menage_prest; by ident&acour.; run;

data scenario.menage (compress = yes);
merge scenario.menage_prest impot_R&asuiv._men impots_R&asuiv._men prest21_men prest20_men rsa_men rsa_nr_men (keep=ident&acour. rsa prime)  ;
by ident&acour.;
if ident&acour.=. then delete;

/*Mise à 0 pour les menages NRT*/
%zero(liste=impot impots credit prel_liberatoire tvatot rsa_pr prime_pr rsa prime) ;

/*Les bénéficiaires au RSA socle sont éligibles à la CMUc*/
elig_cmuc_pr=elig_cmuc;
if rsa_pr>0 then do; 
    elig_cmuc_pr=1;
    pers_cmuc_pr=nbpers*elig_cmuc_pr;
end; 

if rsa>0 then do; 
    elig_cmuc=1;
    pers_cmuc=nbpers*elig_cmuc;
end; 
run;


/**************************************************************************************************************************************************************/
/**************************************************************************************************************************************************************/
/*                        											II. Calcul du revenu disponible                										  	  */
/**************************************************************************************************************************************************************/
/**************************************************************************************************************************************************************/

			/*** Calcul du revenu disponible et autres agrégats ***/

data scenario.menage;
set scenario.menage;

		/** REVDEC17 : revenu déclaré en 2017 **/
/*Somme des revenus catégoriels - pensions alimentaires versées*/
/*Revenu net de la CSG déductible*/
revdec&asuiv4.=sum(ztsam&asuiv4.,revindedm&asuiv4.,zperm&asuiv4.,
zfonm&asuiv4.,zracm&asuiv4.,zetrm&asuiv4.,zvamm&asuiv4.,-zalvm&asuiv4.,zvalm&asuiv4.);

revdec&asuiv4._pv=sum(ztsam&asuiv4.,revindedm&asuiv4.,zperm&asuiv4.,
zfonm&asuiv4.,zracm&asuiv4.,zetrm&asuiv4.,zvamm&asuiv3.,-zalvm&asuiv4.,zvalm&asuiv4., zglom&asuiv4.,zdivm&asuiv4.);

/*CSG - CRDS et prélèvements sociaux sur revenus du patrimoine et placement : payés en N pour les revenus du patrimoine de N-1, mais sur les revenus de 
placement de N*/
cot_epargne&asuiv4.=sum(PS_cap&asuiv3., PS_plac&asuiv4.);
CSG_epargne&asuiv4.=sum(CSG_cap&asuiv3., CSG_plac&asuiv4.);
CRDS_epargne&asuiv4.=sum(CRDS_cap&asuiv3., CRDS_plac&asuiv4.);

		/** REVPER17 : revenu perçu **/
/*Revenu déclaré - CSG non déductible et CRDS*/
revper&asuiv4.=sum(zsalpm&asuiv4.,zchopm&asuiv4.,revindepm&asuiv4.,zrstpm&asuiv4.,
zalrm&asuiv4.,zrtom&asuiv4.,
zfonm&asuiv4.,zracm&asuiv4.,zetrm&asuiv4.,zvamm&asuiv4.,-zalvm&asuiv4.,
-cot_epargne&asuiv4.,-CSG_epargne&asuiv4., -CRDS_epargne&asuiv4.,
produitfin&asuiv4.,zglom&asuiv4.,zdivm&asuiv4.,zvalm&asuiv4.);

		/** REVBRUT17 : revenu brut **/
revbrut&asuiv4.=sum(zsalbm&asuiv4.,zchobm&asuiv4.,zragbm&asuiv4.,zricbm&asuiv4.,zrncbm&asuiv4.,zrstbm&asuiv4.,
zalrm&asuiv4.,zrtom&asuiv4.,
zfonm&asuiv4.,zracm&asuiv4.,zetrm&asuiv4.,zvamm&asuiv4.,-zalvm&asuiv4.,produitfin&asuiv4.,zglom&asuiv4.,zdivm&asuiv4.,zvalm&asuiv4.);

		/** REVSUPERBRUT17 **/
revsuperbrut&asuiv4.=sum(revbrut&asuiv4.,css_pat&asuiv4.);

		/** Revenu primaire : super-brut hors revenus de remplacement **/
rev_primaire&asuiv4.=sum(zsalbm&asuiv4.,/*salaires*/
		zragbm&asuiv4.,zricbm&asuiv4.,zrncbm&asuiv4.,/*indépendants*/
	zalrm&asuiv4.,zrtom&asuiv4.,zfonm&asuiv4.,zracm&asuiv4.,zetrm&asuiv4.,zvamm&asuiv4.,-zalvm&asuiv4.,produitfin&asuiv4.,zglom&asuiv4.,zdivm&asuiv4.,zvalm&asuiv4.,/*autres*/
	css_pat&asuiv4.);/*Cotisations patronales*/

		/** Agrégat de cotisations sociales, CSG, CRDS, Casa **/
Cotsoc=sum(css_sal&asuiv4., css_indep&asuiv4., css_cho&asuiv4., cot_epargne&asuiv4., VIVEA&asuiv4.);
CSG=sum(CSG_act&asuiv4., CSG_remp&asuiv4., CSG_epargne&asuiv4.);
CRDS=sum(CRDS_act&asuiv4., CRDS_remp&asuiv4., CRDS_epargne&asuiv4.);
CSG_CRDS_Casa=sum(CSG, CRDS, Casa_rst&asuiv4.);
tot_cotsoc=sum(Cotsoc, CSG, CRDS, Casa_rst&asuiv4.);


		/** PF : prestations familiales **/
PF=sum(afssmaj,aforf,majaf,asf,cf,ars,ab_paje,pn_paje,clca); 

		/** MS : minima sociaux (RSA socle+AAH+MV) **/
MS_pr=sum(aah,m_caahm&asuiv4.,minvi,rsa_pr); 
MS=sum(aah,m_caahm&asuiv4.,minvi,rsa);


		/** IR_TOT: impot sur le revenu avec impôt simplifié **/
ir_tot=sum(impot,impots);


		/**REVDISP_pr : revenu disponible avec plein recour au RSA et à la prime **/
revdisp_pr=sum(revper&asuiv4.,  /*revenus perçus*/
al,                         	/*allocations logement*/
pf,                          	/*prestations familiales*/
ms_pr,                          /*minima sociaux*/
prime_pr,                    	/*prime d'activité*/
-ir_tot,                     	/*IR */
-zthabm&asuiv4.,                /*TH*/        
-prel_liberatoire);


revdisp=sum(revper&asuiv4.,     /*revenus perçus*/
al,                          	/*allocations logement*/
pf,                          	/*prestations familiales*/
ms,                      	 	/*minima sociaux*/
prime,                		 	/*prime d'activité*/
-ir_tot,                   		/*IR*/
-zthabm&asuiv4.,                /*TH*/        
-prel_liberatoire);


		/** NIVIE_RSA : niveau de vie avec plein recours **/
nivie_pr=revdisp_pr/nb_uc;

		/** NIVIE_NR : niveau de vie avec non recours **/
nivie=revdisp/nb_uc;

		/**COMPTEUR : indicatrice pour comptage **/
compteur=1;

/*Poids individuel*/
wpri&asuiv4.=wprm&asuiv4.*nbind;

/*Champ_pauvrete : indicatrice de champ à retenir pour les analyses sur la pauvreté */
champ_pauvrete=(champm=1 & revdec&asuiv4.>=0);

		/** CMUC et ACS **/ 
cmuc=(elig_cmuc>0); 
acs=(elig_acs>0);

/* Correction sur la CMUC */
if (ageprm<=21 & (nbenfa18 in (0,.))) then pers_cmuc=0;  
if (21<ageprm<26 & acteu6prm=5 & (nbenfa18 in (0,.))) then pers_cmuc=0; 
if (ageprm<=21 & (nbenfa18 in (0,.)) /*& a=0*/ ) then pers_acs=0;  
if (21<ageprm<26 & acteu6prm=5 & (nbenfa18 in (0,.))) then pers_acs=0; 


run;

/**************************************************************************************************************************************************************/
/**************************************************************************************************************************************************************/
/*													III- Nettoyage des tables MENAGE et INDIV 																  */
/**************************************************************************************************************************************************************/
/**************************************************************************************************************************************************************/

data scenario.menage;
set scenario.menage;
drop csecu_sal&asuiv3. csecu_pat&asuiv3. csecu_cho&asuiv3. csecu_rnc&asuiv3. csecu_ric&asuiv3. csecu_rag&asuiv3. css_pat&asuiv3. css_cho&asuiv3. css_indep&asuiv3. css_sal&asuiv3. csg_act&asuiv3. csg_remp&asuiv3. csg_rst&asuiv3.
crds_act&asuiv3. crds_remp&asuiv3. retr_chom_act&asuiv3. csecu_sal&asuiv4. csecu_pat&asuiv4. csecu_cho&asuiv4. 
csecu_rnc&asuiv4. csecu_ric&asuiv4. csecu_rag&asuiv4. al_loc;
run;



data scenario.indiv;
set scenario.indiv_prest;
drop aac adfdap amois  acteu ancentr lprm nbind noindiv colla collm collj naia naim rgmen noienft: naiss_futur_a naiss_futur_m naiss_futur dv_fip iso_fip sep_eec api_eec _1ai _1ak
declarant mds mariage divorce deces matri_fip enceintep3 quelfic zalri zrtoi zsali&asuiv3. zsalo&asuiv3. zchoi&asuiv3. zchoo&asuiv3. zrsti&asuiv3. zrsto&asuiv3. zragi&asuiv3. zrago&asuiv3. zrici&asuiv3. zrico&asuiv3.
zrnci&asuiv3. zrnco&asuiv3. salaire_etr&asuiv3._t: traj_acttp produitfin&asuiv3. zalvm zalvm&asuiv3. revpatm revpatm&asuiv3. zsali&asuiv2. zchoi&asuiv2. zrsti&asuiv2. zragi&asuiv2. zrici&asuiv2. zrnci&asuiv2.
zrstpi&asuiv2. zrstbi&asuiv2. zrstpi&asuiv2._t: zchopi&asuiv2. zchobi&asuiv2. zchopi&asuiv2._t:
zsalbi&asuiv2. zsalpi&asuiv2. zsalpi&asuiv2._t: zragbi&asuiv2. zragpi&asuiv2. zragpi&asuiv2._t: zricbi&asuiv2. zricpi&asuiv2. zricpi&asuiv2._t: zrncbi&asuiv2. zrncpi&asuiv2.
zrncpi&asuiv2._t: ztsai&asuiv2. zperi&asuiv2. revinded&asuiv2. revactd&asuiv2. revindep&asuiv2. revactp&asuiv2. revactp&asuiv2._t:  zrstpi&asuiv3. 
zrstbi&asuiv3. zrstpi&asuiv3._t: zchopi&asuiv3. zchobi&asuiv3. zchopi&asuiv3._t: zsalbi&asuiv3. zsalpi&asuiv3. zsalpi&asuiv3._t: zragbi&asuiv3. zragpi&asuiv3. zragpi&asuiv3._t: zricbi&asuiv3. zricpi&asuiv3. zricpi&asuiv3._t:
zrncbi&asuiv3. zrncpi&asuiv3. zrncpi&asuiv3._t: ztsai&asuiv3. zperi&asuiv3. revinded&asuiv3. revactd&asuiv3. revindep&asuiv3. revactp&asuiv3. revactp&asuiv3._t: csecu_sal&asuiv4. csecu_pat&asuiv4. csecu_rag&asuiv4. csecu_ric&asuiv4. 
csecu_rnc&asuiv4. zchopi&asuiv4._t: zrstpi&asuiv4._t: zsalpi&asuiv4._t: zragpi&asuiv4._t: zricpi&asuiv4._t: zrncpi&asuiv4._t: revactp&asuiv4._t: ;
run; 


/*Nettoyage de la work*/
proc datasets library=work; delete impot_R&asuiv._men impots_R&asuiv._men prest21_men prest20_men rsa_men rsa_nr_men; run; quit; 

/*************************************************************************************************************************************************************
**************************************************************************************************************************************************************

Ce logiciel est régi par la licence CeCILL V2.1 soumise au droit français et respectant les principes de diffusion des logiciels libres. 

Vous pouvez utiliser, modifier et/ou redistribuer ce programme sous les conditions de la licence CeCILL V2.1. 

Le texte complet de la licence CeCILL V2.1 est dans le fichier `LICENSE`.

Les paramètres de la législation socio-fiscale figurant dans les programmes 6, 7a et 7b sont régis par la « Licence Ouverte / Open License » Version 2.0.
**************************************************************************************************************************************************************
*************************************************************************************************************************************************************/

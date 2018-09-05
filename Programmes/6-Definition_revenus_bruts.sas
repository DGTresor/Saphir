

/**************************************************************************************************************************************************************/
/*                              									  SAPHIR E2013 L2017                                  							          */
/*                                     									  PROGRAMME 6                                         			     			      */
/*                     Calcul des revenus bruts à partir des revenus imposables donnés par l'ERFS 2013 - Application de la législation 2013					  */
/**************************************************************************************************************************************************************/


/**************************************************************************************************************************************************************/
/* L'ERFS ne comprend à l'origine que les revenus imposables. Les montants de CSG, CRDS et cotisations sociales sont recalculés de manière à pouvoir passer du*/
/* revenu imposable recueilli au revenu net intervenant dans le calcul du revenu disponible ou de certaines prestations. 									  */ 
/*																																							  */
/* Dans un premier temps, ce programme applique la législation 2013 sur les revenus de l'ERFS (y compris vieillis 2016 et 2017) afin d'obtenir les revenus    */
/* bruts. Ces derniers sont inchangés en cas de réforme des taux, ce qui suppose notamment qu'une hausse de cotisation sociale ou de CSG ne sera jamais captée*/
/* par l'employeur.																																			  */
/* Dans un second temps (programme 7a, 8a et 9a), les montants de cotisations sont recalculés à partir des revenus bruts définis dans ce programme. Ils		  */
/* peuvent donc différer des montants définis dans ce programme si une nouvelle législation est appliquée. Un nouveau revenu imposable est défini et un		  */
/* nouveau revenu net est calculé.																															  */ 	
/*																																							  */
/* Les revenus concernés sont les suivant :  																												  */
/* 		- Retraites (CSG, CRDS et Casa)   																												   	  */
/* 		- Chômage (CSG et CRDS)																																  */
/*		- Salaires du privé (CSG, CRDS et cotisations sociales)																								  */
/*		- Revenus des indépendants (CSG, CRDS et cotisations sociales)																						  */
/*																																							  */
/* Ce programme est conçu en deux étapes :																													  */
/*		1- Définition des macrovariables de 2013																											  */
/*		2- Définition et lancement de la macro %revbrut																										  */
/**************************************************************************************************************************************************************/


/**************************************************************************************************************************************************************/
/**************************************************************************************************************************************************************/
/*                       											I. Préparation des données	                 										      */
/**************************************************************************************************************************************************************/
/**************************************************************************************************************************************************************/

/*Le critère d'exonération/taux réduit de CSG en 2014 est comparé au RFR sur les revenus 2013 disponible dans l'ERFS 2013*/
%let seuil_exo_csg&asuiv.=10633; /*on prend l'année d'imposition correspondant aux revenus ERFS car on utilise le statut d'imposition 2014 comme proxy*/
%let seuil_exo_csg_demipart&asuiv.=2839;

%let seuil_tx_red&asuiv.=13900; 
%let seuil_tx_red_demipart&asuiv.=3711;
    
%let smic_brut=1430.22; 	/*correspond au SMIC pour l'année de l'ERFS 2013*/
%let smic_hor_brut=9.43; 	/*correspond au SMIC pour l'année de l'ERFS 2013*/


/*Informations fiscales*/
data info_fip (keep = ident&acour. declar mnrvkh natimp nbptr _1au _1bu _1cu _1du _5ta _5tb _5ua _5ub _5va _5vb _5te _5ue _5ve);
set erfs.foyer&acour.;
declar=compress(declar);
run;

proc sort data=info_fip nodupkey; by ident&acour. declar; run;
proc sort data=info_fip ; by ident&acour. declar; run;
proc sort data=saphir.indiv_saphir out=indiv_saphir (rename=(declar1=declar)); by ident&acour. declar1; run;

/*Récupération de données des EEC*/
%macro const_var(a=);
%do t=1 %to 4; 				/*travail sur les vagues trimestrielles*/
    %if &t.=4 %then %do;
        %let lib=saphir;
        %let tab=irf&a.e&a.t4c;
    %end;
    %else %do;
        %let lib=erfs_c;
        %let tab=icomprf&a.e&a.t&t.;
    %end;

    data const_var_&a.t&t. (keep = ident&a. noi stat cadre pub3fp statut statutp titc titu rc1revm1 rc1revm2 rc1revm3 rc1revm4 rc1revm5 rc1revm6 rc1revm7 rc1revm8 stc EN);
    set &lib..&tab. ;

    /*EMP_SAL : employeur pour les salariés (public / privé)*/
    if statut in('43','44','45') or pub3fp in('1','2','3') or  statutp in('43','45') then stat='1'; 		/*public*/
    else if statut in('21','22','33','34','35') or pub3fp='4' or statutp in('21','33','35')  then stat='2'; /*privé*/

    /*Entreprises nationales*/
    EN=(chpub='2');

    /*Cadre*/
    if cse in ('31','33','34','35','37','38') or csa in ('31','33','34','35','37','38') or csep in ('31','33','34','35','37','38') then cadre='1';
    else if cse ne ' ' & csa ne ' ' & csep ne ' '  then cadre='0';

    /*Contractuel/titulaire*/
    if statut='45' and titc in (1,2) or statutp='45' then titu='1';
    else if statut='43' or titc=3 or statutp in ('43', '44') then titu='0';

run;
proc sort  data=const_var_&a.t&t.  nodupkey; by ident&a. noi; run; 

%end;
%mend; %const_var(a=&acour.);

option mprint;
%macro info_trim(a=,listvar=);
%do t=1 %to 4; 				/*travail sur les vagues trimestrielles*/
data info_&a.t&t. ;
set const_var_&a.t&t.  (keep = ident&a. noi &listvar.);

    /*On renomme les variables en VAR_an_Ti */
    %let i=1;
    %do %while(%index(&listvar.,%scan(&listvar.,&i.))>0); 

        %let var =%scan(&listvar.,&i.);

        rename &var.=&var._&a.t&t.;

        %let i=%eval(&i.+1);
    %end;
    run;

    proc sort data=info_&a.t&t.; by ident&a. noi; run;
%end;

/*Mise en commun*/
data info_trim;
merge info_&a.t1 info_&a.t2 info_&a.t3 info_&a.t4 (in=a);
by ident&a. noi;
if a; 

%let i=1;
%do %while(%index(&listvar.,%scan(&listvar.,&i.))>0); 
    %let var =%scan(&listvar.,&i.);
    &var._trim=compress(&var._&a.t1 !! &var._&a.t2 !! &var._&a.t3 !! &var._&a.t4);
    %let i=%eval(&i.+1);
%end;

/*CHG_VAR : repérage si changement de statut, valeur manquante si jamais renseignée*/
%let i=1;
%do %while(%index(&listvar.,%scan(&listvar.,&i.))>0); 
    %let var =%scan(&listvar.,&i.);

    nb_&var.=(&var._&a.t1 ne ' ')+(&var._&a.t2 ne ' ')+(&var._&a.t3 ne ' ')+(&var._&a.t4 ne ' ');

    if nb_&var.>0 then do;
        chg_&var.=0;
        long_&var.=length(&var._trim)/nb_&var.;
        %do k=2 %to 4;
            if nb_&var.=&k. then do;
                %do j=2 %to &k.;
                    chg_&var.=(substr(&var._trim,1,long_&var.) ne substr(&var._trim,1+(&j.-1)*long_&var.,long_&var.));
                %end;
            end;
        %end;
    end;
    drop long_&var. nb_&var.;
    %let i=%eval(&i.+1);
%end;

run;

proc datasets library=work;delete info_&a.t: const_var: ;run;quit;
%mend;
%info_trim(a=&acour.,listvar=cadre stat titu rc1revm1 rc1revm2 rc1revm3 rc1revm4 rc1revm5 rc1revm6 rc1revm7 rc1revm8 stc EN);

proc sort data=info_trim; by ident&acour. noi; run;

/*Mise en commun*/
data saphir.cotis;
length declar $ 79;
merge indiv_saphir (keep=ident&acour. wprm&asuiv4. wprm declar declar2 noi decl1 decl2 cjdecl1 cjdecl2
crdscho: crdsrag: crdsric: crdsrnc: crdsrst: crdssal:
CHPUB CSTOT ANBSAL statut  STATUTS2 NBSALB preret
nbm_act1_t4  quot_sal_m:
zchoi zchoi&asuiv. zchoi&asuiv2. zchoi&asuiv3. zchoi&asuiv4.  zchoi_m: zchoi&asuiv._m: zchoi&asuiv2._m: zchoi&asuiv3._m: zchoi&asuiv4._m:
zsali zsali&asuiv. zsali&asuiv2. zsali&asuiv3. zsali&asuiv4.  zsali_m: zsali&asuiv._m: zsali&asuiv2._m: zsali&asuiv3._m: zsali&asuiv4._m:                     
zrsti zrsti&asuiv. zrsti&asuiv2. zrsti&asuiv3. zrsti&asuiv4.  zrsti_m: zrsti&asuiv._m: zrsti&asuiv2._m: zrsti&asuiv3._m: zrsti&asuiv4._m: 
zragi zragi&asuiv. zragi&asuiv2. zragi&asuiv3. zragi&asuiv4.  zragi_m: zragi&asuiv2._m: zragi&asuiv3._m: zragi&asuiv4._m: zragi&asuiv._m:
zrici zrici&asuiv. zrici&asuiv2. zrici&asuiv3. zrici&asuiv4.  zrici_m: zrici&asuiv2._m: zrici&asuiv3._m: zrici&asuiv4._m: zrici&asuiv._m:
zrnci zrnci&asuiv. zrnci&asuiv2. zrnci&asuiv3. zrnci&asuiv4.  zrnci_m: zrnci&asuiv2._m: zrnci&asuiv3._m: zrnci&asuiv4._m: zrnci&asuiv._m:
zalri zalri&asuiv. zalri&asuiv2. zalri&asuiv3. zalri&asuiv4.
zrtoi zrtoi&asuiv. zrtoi&asuiv2. zrtoi&asuiv3. zrtoi&asuiv4. fisc_ric fisc_rnc
hs hs&asuiv2. hs&asuiv. hs&asuiv3. hs&asuiv4. in=a) info_fip ;
by ident&acour. declar;
if a;
if nbptr ne . then part=nbptr/100;
run;

proc sort data=saphir.cotis; by ident&acour. noi; run;

data saphir.cotis;
merge saphir.cotis (in=a) info_trim;
by ident&acour. noi;
if a;

if zsali>0 then do;
    cadre_trim=(cadre_&acour.t1='1' ! cadre_&acour.t2='1' ! cadre_&acour.t3='1' ! cadre_&acour.t4='1' );
    ncadre_trim=(cadre_&acour.t1='0' ! cadre_&acour.t2='0' ! cadre_&acour.t3='0' ! cadre_&acour.t4='0' );

    public_trim=(stat_&acour.t1='1' ! stat_&acour.t2='1' ! stat_&acour.t3='1' ! stat_&acour.t4='1' );
    prive_trim=(stat_&acour.t1='2' ! stat_&acour.t2='2' ! stat_&acour.t3='2' ! stat_&acour.t4='2' );
end;

indep_trim=(stat_&acour.t1='3' ! stat_&acour.t2='3' ! stat_&acour.t3='3' ! stat_&acour.t4='3' );

/*Cadre : indicatrice du statut de cadre*/
cadre=(cadre_trim=1)*(ncadre_trim=0);

/*Privé : secteur privé*/
prive=(prive_trim=1 ! (prive_trim=0 & public_trim=0));

/*INFO_FIP : information fiscale*/
info_fip=(nbptr ne .);

/*Fonction publique titulaire/ contractuel : on retient le statut déclaré le plus fréquemment*/
/*Compteur du nombre de fois où le statut de titulaire "titu 1 ou 0" est déclaré*/
tituc= (titu_&acour.t1='1') + (titu_&acour.t2='1') + (titu_&acour.t3='1') + (titu_&acour.t4='1');
ntituc=(titu_&acour.t1='0') + (titu_&acour.t2='0') + (titu_&acour.t3='0') + (titu_&acour.t4='0');
if prive=0 then do;
    if tituc>=ntituc then titulaire=1;
    else titulaire=0;
end;

/*Entreprise publique (les salariés ne cotisent pas pour le chômage) : méthode semblable aux titulaires de la fonction publique*/
ENc= (EN_&acour.t1=1) + (EN_&acour.t2=1) + (EN_&acour.t3=1) + (EN_&acour.t4=1);
nENc=(EN_&acour.t1=0) + (EN_&acour.t2=0) + (EN_&acour.t3=0) + (EN_&acour.t4=0);
if ENc>=nENc then salarie_EN=1;
else salarie_EN=0;


/*Régime d'assujettissement à la CSG/CRDS (exonération, taux réduit, taux plein) pour les revenus de remplacement*/
/*Le taux de CSG déterminé d'après le RFR sur revenus 2013 est utilisé comme proxy du taux de CSG déterminé d'après le RFR sur revenus 2011 */

/*Retraite*/
if mnrvkh =< &&seuil_exo_csg&asuiv.. + max(part-1,0)*2*&&seuil_exo_csg_demipart&asuiv.. ! info_fip=0 then tx_ret=1; 	/*exonération de CSG*/
else do;
    if mnrvkh=<(&&seuil_tx_red&asuiv.+ max(part-1,0)*2*&&seuil_tx_red_demipart&asuiv.) then tx_ret=2;					/*taux réduit de CSG*/
    else tx_ret=3; 																										/*taux plein de CSG*/
end;

/*Chômage : critère identique à celui des retraites*/
/*Ajout d'une exonération pour les revenus du chômage inférieurs au Smic : voir plus bas dans le code*/
tx_cho=tx_ret;


/*Auto-entrepreneur*/
if (zrici&asuiv3.>0)&(fisc_ric="vous")&(sum(_5ta,_5tb)>0) then auto_ent=1;
if (zrici&asuiv3.>0)&(fisc_ric="conj")&(sum(_5ua,_5ub)>0) then auto_ent=1;
if (zrici&asuiv3.>0)&(fisc_ric="pac1")&(sum(_5va,_5vb)>0) then auto_ent=1;
if (zrnci&asuiv3.>0)&(fisc_rnc="vous")&(_5te>0) then auto_ent=1;
if (zrnci&asuiv3.>0)&(fisc_rnc="conj")&(_5ue>0) then auto_ent=1;
if (zrnci&asuiv3.>0)&(fisc_rnc="pac1")&(_5ve>0) then auto_ent=1;

/*Indépendant comme occupation principale*/
if (stc_&acour.t1="1")|(stc_&acour.t2="1")|(stc_&acour.t3="1")|(stc_&acour.t4="1") then indep_p=1;
else indep_p=0;

run;


/**************************************************************************************************************************************************************/
/**************************************************************************************************************************************************************/
/*                  		II. Taux de CSG, CRDS et cotisations sociales 2013 : macro-variables permettant de remonter au revenu brut    					  */
/**************************************************************************************************************************************************************/
/**************************************************************************************************************************************************************/

/**************************************************************************************************************************************************************/
/*				1- Montant du Smic										                 												     				  */
/**************************************************************************************************************************************************************/

/*Certains paramètres ont déjà été définis plus haut*/
%let smic_net=1120.43;   		/*151.666 heures travaillées par mois*/ 
%let smic_hor_brut13=9.43;
%let smic_hor_brut14=9.53; 
%let smic_hor_brut15=9.61; 
%let smic_hor_brut16=9.67; 
%let smic_hor_brut17=9.76;

/**************************************************************************************************************************************************************/
/*				2- Taux de CRDS 2013									                 												     				  */
/**************************************************************************************************************************************************************/

%let tx_crds&acour.=0.005;

/**************************************************************************************************************************************************************/
/*				3- Taux de CSG et Casa sur les retraites et pensions (RST) 2013									  								     				  */
/**************************************************************************************************************************************************************/

/*1,2,3 = tranches : exonérés, réduit, plein*/
/*Taux de CSG déductible */
%let tx_csgd1_rst&acour.=0;
%let tx_csgd2_rst&acour.=0.038;
%let tx_csgd3_rst&acour.=0.042;

/*Taux de CSG non déductible / imposable*/
%let tx_csgi1_rst&acour.=0;
%let tx_csgi2_rst&acour.=0;
%let tx_csgi3_rst&acour.=0.024;

/*Taux de Contribution additionnelle de solidarité pour l'autonomie*/
%let tx_casa&acour.=%sysevalf(0.003*9/12);		/*mise en place de la Casa en avril 2013*/

/**************************************************************************************************************************************************************/
/*				4- Taux de CSG sur le chômage et les préretraites (CHO) 2013															     				  */
/**************************************************************************************************************************************************************/

/*Assiette de calcul de la CSG*/
%let ass_csg_cho&acour.=0.9825;

/*1,2,3 = tranches : exonéré, réduit, plein*/
/*Taux de CSG déductible */
%let tx_csgd1_cho&acour.=0;
%let tx_csgd2_cho&acour.=0.038;
%let tx_csgd3_cho&acour.=0.038;
%let tx_csgd4_cho&acour.=0.051;

/*Taux de CSG non déductible / imposable*/
%let tx_csgi1_cho&acour.=0;
%let tx_csgi2_cho&acour.=0;
%let tx_csgi3_cho&acour.=0.024;

/*allocation journalière minimale*/
%let ajm&acour.=27.935;
%let tx_remplacement=0.574; 	/*taux pour l'année de l'ERFS minimum et valable au-delà de 1.5 smic*/

/*Cotisation retraite complémentaire sur le chômage total*/
%let tx_css_cho&acour.=0.03;


/**************************************************************************************************************************************************************/
/*				5- CSG, CRDS et cotisations sociales sur les salaires 2013								  								     				  */
/**************************************************************************************************************************************************************/

/**************************************************************************************************************************************************************/
/*		a. Plafond de la sécurité sociale (PSS) (en €/mois)																			 		                      */
/**************************************************************************************************************************************************************/

%let PSS13=3086;

/**************************************************************************************************************************************************************/
/*		b. Cotisations sociales																									 		                      */
/**************************************************************************************************************************************************************/

	/** Bornes inférieure et supérieure des tranches de cotisation **/
/*Non cadres*/
%let binf_css_nc1&acour.=0;
%let bsup_css_nc1&acour.=%eval(&&PSS&acour.);

%let binf_css_nc2&acour.=%eval(&&PSS&acour.);
%let bsup_css_nc2&acour.=%eval(3*&&PSS&acour.);

%let binf_css_nc3&acour.=%eval(3*&&PSS&acour.);
%let bsup_css_nc3&acour.=%eval(4*&&PSS&acour.);

%let binf_css_nc4&acour.=%eval(4*&&PSS&acour.);
%let bsup_css_nc4&acour.=%eval(100*&&PSS&acour.);

/*Cadres*/
%let binf_css_c1&acour.=0;
%let bsup_css_c1&acour.=%eval(&&PSS&acour.);

%let binf_css_c2&acour.=%eval(&&PSS&acour.);
%let bsup_css_c2&acour.=%eval(4*&&PSS&acour.);

%let binf_css_c3&acour.=%eval(4*&&PSS&acour.);
%let bsup_css_c3&acour.=%eval(8*&&PSS&acour.);

%let binf_css_c4&acour.=%eval(8*&&PSS&acour.);
%let bsup_css_c4&acour.=%eval(100*&&PSS&acour.);


	/** Taux **/

	/*Détails généraux */

/*Maladie, maternité, décès, invalidité*/
/*Assiette : totalité salaire*/
%let tx_css_mmdi&acour.=0.0075; 
%let tx_csp_mmdi&acour.=0.128;

/*Solidarité autonomie*/ 
/*Assiette : totalité salaire*/
%let tx_csp_solauto&acour.=0.003;

/*Vieillesse*/
/*Assiette : entre 0 et PSS*/
%let tx_css_vieil&acour.=0.0675; 
%let tx_csp_vieil&acour.=0.0840; 
/*Assiette: totalité salaire*/
%let tx_css_vieil_tot&acour. = 0.001; 
%let tx_csp_vieil_tot&acour. = 0.016; 

/*Allocations familliales*/
/*Assiette : totalité salaire*/
%let tx_csp_AF&acour.=0.054;

/*Accidents du travail : le taux retenu est un taux moyen car il est variable selon l'entreprise et la branche*/
/*Assiette : totalité salaire*/
%let tx_csp_ATMP&acour.=0.0238;

/*UNEDIC*/
/*Assiette : entre 0 et 4 PSS*/
%let tx_css_unedic&acour.=0.024; 
%let tx_csp_unedic&acour.=0.04; 

/*Fonds de garantie des salaires*/
/*Assiette : entre 1 et 4 PSS*/
%let tx_csp_AGS&acour.=0.003;

/*Fonds national d'aide au logement*/
/*Assiette : entre 0 et 1 PSS toutes entreprises : voir plus bas pour le FNAL*/ 
%let tx_csp_fnal&acour.=0.001;

/*Taxe d'apprentissage*/
/*assiette : totalité salaire*/
%let tx_csp_tap&acour.=0.0068;

/*Autres cotisations patronales fonction de la taille de l'entreprise : formation professionnelle, FNAL + 20 salariés et construction*/
/*Assiette : totalité salaire*/
%let tx_csp_m10sal&acour.=0.0055;
%let tx_csp_10a20sal&acour.=0.0105;
%let tx_csp_p20sal&acour.=0.0245;   


	/*Détails non cadres*/

/*ARRCO : retraite complémentaire*/
/*Assiette : entre 0 et 1 PSS*/
%let tx_css_ret1&acour.=0.03;
%let tx_csp_ret1&acour.=0.045; 
/*Assiette : entre 1 et 3 PSS*/
%let tx_css_ret2&acour.=0.08;
%let tx_csp_ret2&acour.=0.12; 

/*AGFF*/
/*Assiette : entre 0 et 1 PSS*/
%let tx_css_agff_nc1&acour.=0.008; 
%let tx_csp_agff_nc1&acour.=0.012; 
/*Assiette : entre 1 et 3 PSS*/
%let tx_css_agff_nc2&acour.=0.009; 
%let tx_csp_agff_nc2&acour.=0.013; 

	/*Détails cadres*/

/*ARRCO et AGIRC : retraite complémentaire*/
/*Assiette : entre 0 et 1 PSS*/
%let tx_css_retA&acour.=0.03; 
%let tx_csp_retA&acour.=0.045;
/*Assiette : entre 1 et 4 PSS*/
%let tx_css_retB&acour.=0.077; 
%let tx_csp_retB&acour.=0.126; 
/*Assiette : entre 4 et 8 PSS*/
%let tx_css_retC&acour.=0.077; 
%let tx_csp_retC&acour.=0.126;

/*Contribution exceptionnelle et temporaire*/
/*Assiette : entre 0 et 8 PSS*/
%let tx_css_cet&acour.=0.0013; 
%let tx_csp_cet&acour.=0.0022;

/*Décès*/
/*Assiette : entre 0 et 1 PSS*/
%let tx_csp_deces&acour.=0.015;

/*AGFF*/
/*Assiette : entre 0 et 1 PSS*/
%let tx_css_agff_c1&acour.=0.008; 
%let tx_csp_agff_c1&acour.=0.012;
/*Assiette : entre 1 et 4 PSS*/
%let tx_css_agff_c2&acour.=0.009; 
%let tx_csp_agff_c2&acour.=0.013;

/*APEC*/
/*Assiette : entre 1 et 4 PSS*/
%let tx_css_apec&acour.=0.00024; 
%let tx_csp_apec&acour.=0.00036; 


	/** Allègements généraux **/

%let tx_allg_m20sal&acour.=0.281;
%let tx_allg_p20sal&acour.=0.26;
%let plaf_allg&acour.=1.6;

/*Allègements heures supplémentaires*/
%let all_hp_m20sal&acour.=1;


	/** Total non cadres **/

/*Entre 0 et 1 PSS*/
%let tx_css_nc1_&acour.=%sysevalf(&&tx_css_mmdi&acour.+&&tx_css_vieil&acour.+
    &&tx_css_unedic&acour.+&&tx_css_ret1&acour.+&&tx_css_agff_nc1&acour.+&&tx_css_vieil_tot&acour. );

%let tx_csp_nc1_&acour.=%sysevalf(&&tx_csp_mmdi&acour.+&&tx_csp_solauto&acour.
+&&tx_csp_vieil&acour.+&&tx_csp_AF&acour.+&&tx_csp_ATMP&acour.+&&tx_csp_unedic&acour.+&&tx_csp_AGS&acour.
+&&tx_csp_ret1&acour.+&&tx_csp_agff_nc1&acour.+&&tx_csp_fnal&acour.+&&tx_csp_tap&acour.+&&tx_csp_vieil_tot&acour. ); 

/*Entre 1 et 3 PSS*/
%let tx_css_nc2_&acour.=%sysevalf(&&tx_css_mmdi&acour.+&&tx_css_unedic&acour.+&&tx_css_ret2&acour.+&&tx_css_agff_nc2&acour.+&&tx_css_vieil_tot&acour. ); 
%let tx_csp_nc2_&acour.=%sysevalf(&&tx_csp_mmdi&acour.+&&tx_csp_solauto&acour.+&&tx_csp_AF&acour.+
&&tx_csp_ATMP&acour.+&&tx_csp_unedic&acour.+&&tx_csp_AGS&acour.+&&tx_csp_ret2&acour.+&&tx_csp_agff_nc2&acour.+&&tx_csp_tap&acour.+&&tx_csp_vieil_tot&acour.); 

/*Entre 3 et 4 PSS*/
%let tx_css_nc3_&acour.=%sysevalf(&&tx_css_mmdi&acour.+&&tx_css_unedic&acour.+&&tx_css_vieil_tot&acour.);
%let tx_csp_nc3_&acour.=%sysevalf(&&tx_csp_mmdi&acour.+&&tx_csp_solauto&acour.+&&tx_csp_AF&acour.+&&tx_csp_ATMP&acour.
+&&tx_csp_unedic&acour.+&&tx_csp_tap&acour.+&&tx_csp_vieil_tot&acour.);

/*4 PSS ou plus*/
%let tx_css_nc4_&acour.=%sysevalf(&&tx_css_mmdi&acour.+&&tx_css_vieil_tot&acour.); 
%let tx_csp_nc4_&acour.=%sysevalf(&&tx_csp_mmdi&acour.+&&tx_csp_solauto&acour.
+&&tx_csp_AF&acour.+&&tx_csp_ATMP&acour.+&&tx_csp_tap&acour.+&&tx_csp_vieil_tot&acour.); 


	/** Total cadres **/

/*Entre 0 et 1 PSS*/
%let tx_css_c1_&acour.=%sysevalf(&&tx_css_mmdi&acour.+&&tx_css_vieil&acour.+&&tx_css_unedic&acour.
+&&tx_css_retA&acour.+&&tx_css_agff_c1&acour.+&&tx_css_cet&acour.+&&tx_css_vieil_tot&acour.); 
%let tx_csp_c1_&acour.=%sysevalf(&&tx_csp_mmdi&acour.+&&tx_csp_solauto&acour.
+&&tx_csp_vieil&acour.+&&tx_csp_AF&acour.+&&tx_csp_ATMP&acour.+&&tx_csp_unedic&acour.+&&tx_csp_AGS&acour.
+&&tx_csp_retA&acour.+&&tx_csp_agff_c1&acour.+&&tx_csp_cet&acour.+&&tx_csp_deces&acour.+&&tx_csp_fnal&acour.+&&tx_csp_tap&acour.+&&tx_csp_vieil_tot&acour.); 

/*Entre 1 et 4 PSS*/
%let tx_css_c2_&acour.=%sysevalf(&&tx_css_mmdi&acour.+&&tx_css_unedic&acour.+&&tx_css_apec&acour.
+&&tx_css_retB&acour.+&&tx_css_agff_c2&acour.+&&tx_css_cet&acour.+&&tx_css_vieil_tot&acour.); 
%let tx_csp_c2_&acour.=%sysevalf(&&tx_csp_mmdi&acour.+&&tx_csp_solauto&acour.+&&tx_csp_AF&acour.
+&&tx_csp_ATMP&acour.+&&tx_csp_unedic&acour.+&&tx_csp_AGS&acour.+&&tx_csp_apec&acour.+&&tx_csp_retB&acour.
+&&tx_csp_agff_c2&acour.+&&tx_csp_cet&acour.+&&tx_csp_tap&acour.+&&tx_csp_vieil_tot&acour.); 

/*Entre 4 et 8 PSS*/
%let tx_css_c3_&acour.=%sysevalf(&&tx_css_mmdi&acour.+&&tx_css_retC&acour.+&&tx_css_cet&acour.+&&tx_css_vieil_tot&acour.); 
%let tx_csp_c3_&acour.=%sysevalf(&&tx_csp_mmdi&acour.+&&tx_csp_solauto&acour.+&&tx_csp_AF&acour.+&&tx_csp_ATMP&acour.
+&&tx_csp_retC&acour.+&&tx_csp_cet&acour.+&&tx_csp_tap&acour.+&&tx_csp_vieil_tot&acour.);

/*8 PSS ou plus*/
%let tx_css_c4_&acour.=%sysevalf(&&tx_css_mmdi&acour.+&&tx_css_vieil_tot&acour.); 
%let tx_csp_c4_&acour.=%sysevalf(&&tx_csp_mmdi&acour.+&&tx_csp_solauto&acour.
+&&tx_csp_AF&acour.+&&tx_csp_ATMP&acour.+&&tx_csp_tap&acour.+&&tx_csp_vieil_tot&acour.); 


/**************************************************************************************************************************************************************/
/*		c. CSG et CRDS sur les salaires								 		    															                  */
/**************************************************************************************************************************************************************/

	/** CSG sur les salaires **/

/* Assiette */
%let ass_csg_sal&acour.=0.9825; 
/*CSG déductible*/
%let tx_csgd_sal&acour.=0.051;
/*CSG non déductible*/
%let tx_csgi_sal&acour.=0.024;

	/** CRDS **/
%let tx_crds_sal&acour.=0.005;                                                    



/**************************************************************************************************************************************************************/
/*				6- Cotisations des agents publics														  								     				  */
/**************************************************************************************************************************************************************/

/**************************************************************************************************************************************************************/
/*		a. Cotisations des fonctionnaires							 		    															                  */
/**************************************************************************************************************************************************************/

/*Pension civile*/
%let tx_css_pc&acour.=0.0876;
%let tx_csp_pc_etat&acour.=0.6859;
%let tx_csp_pc_apul&acour.=0.27317;
%let tx_csp_pc_mili&acour.=1.2155;

/*Retraite additionnelle de la fonction publique*/
%let tx_css_rafp&acour.=0.05;
%let tx_css_rafp_max&acour.=0.2; /*dans la limite de 20 % du traitement indiciaire brut de l'année*/

/*Solidarité*/
%let tx_css_sol&acour.=0.01;
%let min_css_sol&acour.=1430.76;

/*FNAL*/
%let tx_csp_fnal_deplaf&acour.=0.004;

/*Maladie*/
%let tx_csp_maladie_f&acour.=0.097;

/*Charge état maladie*/
%let tx_csp_CEmaladie_f&acour.=0.029;

/*Charge état accident du travail*/
%let tx_csp_CEAT&acour.=0.0009;

/*Part des primes dans la rémunération des agents titulaires*/
%let tx_prim&acour.=0.20; 	/*référence : Insee Première N 1564*/


/**************************************************************************************************************************************************************/
/*		b. Cotisations sociales des non titulaires					 		    															                  */
/**************************************************************************************************************************************************************/

/*Retraite complémentaire : ircantec*/
/*Assiette entre 0 et 1 PSS*/
%let tx_css_ircantec1&acour.=0.0245; 
%let tx_csp_ircantec1&acour.=0.0353;
/*Assiette entre 1 et 8 PSS*/
%let tx_css_ircantec2&acour.=0.0623;
%let tx_csp_ircantec2&acour.=0.1170;


	/** Total non titulaires **/

/*Entre 0 et 1 PSS*/
%let tx_css_nt1_&acour.=%sysevalf(&&tx_css_mmdi&acour.+&&tx_css_vieil&acour.+&&tx_css_ircantec1&acour.+&&tx_css_vieil_tot&acour.);
%let tx_css_rc_nt1_&acour.=%sysevalf(&&tx_css_vieil&acour.+&&tx_css_ircantec1&acour.+&&tx_css_vieil_tot&acour.); /*Retraites chômage*/

/*1 PSS ou plus*/
%let tx_css_nt2_&acour.=%sysevalf(&&tx_css_mmdi&acour.+&&tx_css_ircantec2&acour.+&&tx_css_vieil_tot&acour.); 
%let tx_css_rc_nt2_&acour.=%sysevalf(&&tx_css_ircantec2&acour.+&&tx_css_vieil_tot&acour.); /*Retraites chômage*/


/**************************************************************************************************************************************************************/
/*				7- Cotisations des non salariés agricoles												  								     				  */
/**************************************************************************************************************************************************************/

/**************************************************************************************************************************************************************/
/*		a. Assiettes minimales					 		    																				                  */
/**************************************************************************************************************************************************************/

/*En nombre de smic horaire*/
%let ass_min_amexa&acour.=800;
%let ass_min_avi&acour.=800;
%let ass_min_ava&acour.=600;
%let ass_min_rco&acour.=1820;


/**************************************************************************************************************************************************************/
/*		b. Taux de cotisations					 		    																				                  */
/**************************************************************************************************************************************************************/

/*Assurance maladie des exploitants agricoles*/
%let tx_css_amexa_princ&acour.=0.1084;
%let tx_css_amexa_sec&acour.=0.0732;
%let mt_css_amexa_sec_&acour.=44;

/*Allocation familliales*/
%let tx_css_pfa&acour.=0.054;

/*Assurance vieillesse individuelle*/
%let tx_css_avi&acour.=0.032;

/*Assurance vieillesse agricole*/
%let tx_css_ava_plaf&acour.=0.1119;
%let tx_css_ava_deplaf&acour.=0.0164;

/*Retraite complémentaire*/
%let tx_css_rco_&acour.=0.03;

/*Accident du travail*/
/*Forfaitaire suivant risque : la moyenne abcde est retenue*/
%let mt_css_atexa_cp_&acour.= 430.31;
%let mt_css_atexa_cs_&acour.= 215.54;
%let mt_css_atexa_af_&acour.= 165.18;

/*Formation professionnelle*/
            %let tx_css_vivea_&acour.=0.0049;
            %let binf_vivea_&acour.=50;
            %let bsup_vivea_&acour.=273;


/**************************************************************************************************************************************************************/
/*		c. Spécificité des aidants familiaux	 		    																				                  */
/**************************************************************************************************************************************************************/

/* Amexa*/
%let tx_css_amexa_AF&acour.=0.66;
%let plaf_amexa_AF&acour.=1819;
%let ass_min_ava_AF&acour.=400;



/**************************************************************************************************************************************************************/
/*				8- Cotisations des non salariés artisans et commerçants																	     				  */
/**************************************************************************************************************************************************************/

/**************************************************************************************************************************************************************/
/*		a. Assiettes minimales					 		    																				                  */
/**************************************************************************************************************************************************************/

/*Pour la retraite : l'assiette minimale est semblable à celle des professions libérales*/
/*Les assiettes minimales sont exprimées en PSS*/

/*Maladie-maternité*/
%let ass_min_canam&acour.=0.40; 

/*Retraite principale*/
%let ass_min_rsi&acour.=0.0525; 

/*Invalidité*/
%let ass_min_inv&acour.=0.20;

/*Indemnités journalières*/
%let ass_min_ij&acour.=0.40 ; 


/**************************************************************************************************************************************************************/
/*		b. Plafonds								 		    																				                  */
/**************************************************************************************************************************************************************/

/*Les plafonds sont exprimés en plafond de la sécurité sociale (PSS)*/
%let plaf_canam1&acour.=1;
%let plaf_canam2&acour.=5;
%let plaf_rco1_rsi&acour.=1; 	/*Premier plafond en RCI pour la retraite complémentaire des artisans commerçants  : d635-7*/
%let plaf_rco2_rsi&acour.=4; 	/*Deuxième plafond en PSS */

%let plaf_cnavpl1&acour.=0.85; 	/*Premier plafond de la retraite principale pour les libéraux*/
%let plaf_cnavpl2&acour.=5;    	/*Deuxième plafond retraite principale pour les libéraux*/

/*Seuils d'exonération de cotisations familiales : 13% du PSS (R242-15 CSS)*/
%let seuil_af&acour.=%sysevalf(13/100*12*&&PSS&acour.);
        
/*Reduction maladie maternité*/
%let seuil1_reduc_canam=0.13;
%let seuil2_reduc_canam=0.40;


/**************************************************************************************************************************************************************/
/*		c. Taux de cotisations					 		    																				                  */
/**************************************************************************************************************************************************************/

/*Assurance maladie*/
%let tx_css_maladie&acour.=0.065; 
%let tx_css_IJ&acour.=0.007; 		/* entre 0 et 5 PSS*/

/*Allocations familiales*/
%let tx_css_af_i&acour.=0.054;

/*Formation professionnelle*/
%let tx_css_fp_i&acour.=0.0025; 	/*Commerçants*/
%let tx_css_fp_art&acour.=0.0029; 	/*Artisans*/

/*Assurance vieillesse de base*/
%let tx_css_rsi1&acour.=0.1685; 	/*Entre 0 et 1 PSS : base des RIC en 2013, voir circulaire RSI 2012/011*/
%let tx_css_rsi2&acour.=0.0975; 	/*Retraite de base des PL en-dessous du 1er seuil*/
%let tx_css_rsi3&acour.=0.0181; 	/*Retraite de base des PL entre seuil 1 et seuil 2*/

/*Retraite complémentaire obligatoire*/
%let tx_css_rco_rsi&acour.=0.07; 	/*Entre 0 et 1 plafond du RCI*/
%let tx_css_rco2_rsi&acour.=0.08; 	/*Entre 1 plafond du RCI et 4 PSS*/
    
/*Invalidité décès*/
%let tx_css_inv_art&acour.=0.016; 	/*D635-15*/
%let tx_css_inv_com&acour.=0.011; 	/*D635-17*/


/**************************************************************************************************************************************************************/
/*		d. Spécificité des professions libérales				 		    																                  */
/**************************************************************************************************************************************************************/

/*Ce taux dépend de la caisse : on applique un taux moyen*/       
%let tx_css_rco_lib&acour.=0.1;
%let tx_css_inv_lib&acour.=0.01;



/**************************************************************************************************************************************************************/
/*				9- CSG, CRDS et cotisations sociales sur les revenus du patrimoine en 2013												     				  */
/**************************************************************************************************************************************************************/

/*Taux de CSG*/
%let tx_CSG_cap&acour.=0.082;

/*Taux de prélèvements sociaux*/
%let tx_PS_cap&acour.=0.068;
%let tx_PS_source&acour.=0.058;

/*Compensation de l'intégration de l'abattement de 20% au barème de l'IR sur les montants déclarés ligne GO*/
%let comp_ab20&acour. = 1.25;

/*Plafond d'exigibilité*/
%let plaf_imposable&acour.=61;



/**************************************************************************************************************************************************************/
/**************************************************************************************************************************************************************/
/*                       											III. Macro %REVBRUT                 													  */
/**************************************************************************************************************************************************************/
/**************************************************************************************************************************************************************/

/**************************************************************************************************************************************************************/
/* La macro %revbrut qui va permettre de donner les revenus bruts 2014+ à partir des revenus imposables				    									  */
/* Pour calculer les revenus bruts, on applique les taux de cotisations 2013 sur des revenus 2013 et vieillis												  */	
/**************************************************************************************************************************************************************/

%macro revbrut(an= ); 
data saphir.revbrut&an. (keep=ident&acour. noi  zrstbi&an._m: zrstbi&an._t:  zchobi&an._m: zchobi&an._t: 
zsalbi&an._m: zsalbi&an._t:   zragbi&an.  zragbi&an._m: zragbi&an._t:  zricbi&an. zricbi&an._m: zricbi&an._t:  
zrncbi&an. zrncbi&an._m: zrncbi&an._t:); 
set saphir.cotis;

/**************************************************************************************************************************************************************/
/*				1- Retraites																											     				  */
/**************************************************************************************************************************************************************/

    if zrsti>0 then do; 

        /*TX_CSGD_RST : taux de CSG déductible sur les retraites*/
        tx_CSGd_rst&acour.=&&tx_csgd1_rst&acour.*(tx_ret=1)+&&tx_csgd2_rst&acour.*(tx_ret=2)+&&tx_csgd3_rst&acour.*(tx_ret=3);

        /*TX_CSGI_RST : taux de CSG imposable sur les retraites*/
        tx_CSGi_rst&acour.=&&tx_csgi1_rst&acour.*(tx_ret=1)+&&tx_csgi2_rst&acour.*(tx_ret=2)+&&tx_csgi3_rst&acour.*(tx_ret=3);

        /*TX_CSG_RST : taux de CSG sur les retraites*/
        tx_CSG_rst&acour.=tx_CSGd_rst&acour.+tx_CSGi_rst&acour.;

        /*TX_CRDS_RST : taux de CRDS sur les retraites*/
        tx_CRDS_rst&acour.=(tx_ret in (2,3))*&&tx_crds&acour.;

		/*TX_CASA_RST : taux de CRDS sur les retraites*/
        tx_CASA_rst&acour.=(tx_ret in (3))*&&tx_casa&acour.;			

        /*ZRSTBI_Mm : retraite brute au mois m*/
        %macro mois;
        %do m=1 %to 12;
            zrstbi&an._m&m.=zrsti&an._m&m./(1-tx_csgd_rst&acour.);
        %end;
        %mend;
        %mois;

        /*ZRSTBI_Ti : retraite brute au trimestre i*/
            zrstbi&an._t1=max(0,sum(zrstbi&an._m1,zrstbi&an._m2,zrstbi&an._m3));
            zrstbi&an._t2=max(0,sum(zrstbi&an._m4,zrstbi&an._m5,zrstbi&an._m6));
            zrstbi&an._t3=max(0,sum(zrstbi&an._m7,zrstbi&an._m8,zrstbi&an._m9));
            zrstbi&an._t4=max(0,sum(zrstbi&an._m10,zrstbi&an._m11,zrstbi&an._m12));

    end; 

/**************************************************************************************************************************************************************/
/*				2- Chômage et préretraites																								     				  */
/**************************************************************************************************************************************************************/

   if zchoi>0 then do; 

        /*TX_CSGD_cho : taux de CSG déductible sur le chômage*/
        tx_CSGd_cho&acour.=(preret ne '1')*(&&tx_csgd1_cho&acour.*(tx_cho=1)+&&tx_csgd2_cho&acour.*(tx_cho=2)
            +&&tx_csgd3_cho&acour.*(tx_cho=3))+(preret= '1')*&&tx_csgd4_cho&acour.;

        /*Assiette chômage ou préretraite*/
        assiette&acour.=(1+(preret ne '1')*(&&ass_csg_cho&acour.-1));
        
        %macro mois;
            %do m=1 %to 12;
                /*Cotisations retraite complémentaire sur le chômage total*/
                tx_CSS_cho&an._m&m.=(preret ne '1' and zchoi_m&m.>(&&ajm&acour.*30))*&&tx_css_cho&acour./&tx_remplacement.;
                /*ZCHOBI_Mm : allocation brute au mois m*/
                zchobi&an._m&m.=zchoi&an._m&m./(1-assiette&acour.*tx_csgd_cho&acour. -tx_CSS_cho&an._m&m.);
            %end;
        %mend;
        %mois;

        /*zchoBI_Ti : chômage et préretraite percus au trimestre i*/
            zchobi&an._t1=max(0,sum(zchobi&an._m1,zchobi&an._m2,zchobi&an._m3));
            zchobi&an._t2=max(0,sum(zchobi&an._m4,zchobi&an._m5,zchobi&an._m6));
            zchobi&an._t3=max(0,sum(zchobi&an._m7,zchobi&an._m8,zchobi&an._m9));
            zchobi&an._t4=max(0,sum(zchobi&an._m10,zchobi&an._m11,zchobi&an._m12));
        
    end;


/**************************************************************************************************************************************************************/
/*				3- Salaires																												     				  */
/**************************************************************************************************************************************************************/

/**************************************************************************************************************************************************************/
/*		a. Cas des salariés du privé							 		    																                  */
/**************************************************************************************************************************************************************/

    if zsali>0 & prive=1 then do; 	/*salarié du privé*/

            /*Classement par taille de l'entreprise actuelle ou antérieure*/
                select (NBSALB);
                        when ('1','2','3') TailEnt='1'; 			/*moins de 10 salariés*/
                        when ('4') TailEnt='2'; 					/*entre 10 et 20 salariés*/
                        when ('5','6','7','8','9') TailEnt='3'; 	/*plus de 20 salariés*/
                        otherwise do;
                            select (ANBSAL);
                                when ('1','2','3') TailEnt='1';
                                when ('4') TailEnt='2';
                                when ('5','6','7','8','9') TailEnt='3';
                                otherwise TailEnt='2'; 				/*par défaut*/
                            end;
                        end;    
                end;
            /***/

        %macro mens;
        %do m=1 %to 12;
            
            if zsali&an._m&m.>0 then do;

                /*Cadres*/
                if cadre=1 then do; 
                /*Les salariés des entreprises publiques ne cotisent pas pour le chômage, on soustrait dont le taux de cotisation chômage (plafonné à 4 PSS) 
                du taux de cotisations total pour ces salariés. Dans la suite du code on remplace les macros variables &&tx_css par des variables */
                    tx_css_c1_&acour.=&&tx_css_c1_&acour.-&&tx_css_unedic&acour.*salarie_EN;
                    tx_css_c2_&acour.=&&tx_css_c2_&acour.-&&tx_css_unedic&acour.*salarie_EN;
                    tx_css_c3_&acour.=&&tx_css_c3_&acour.-&&tx_css_unedic&acour.*salarie_EN;

                    /*TR_CSS_Ci : tranche de cotisations pour les cadres, i=1,...,4*/ 
                    tr_css_c1_m&m.=(&&binf_css_c1&acour.*quot_sal_m&m.<=(zsali&an._m&m.)
                        /(1-&&ass_csg_sal&acour.*&&tx_csgd_sal&acour.-tx_css_c1_&acour.)<&&bsup_css_c1&acour.*quot_sal_m&m.);
                    tr_css_c2_m&m.=(&&binf_css_c2&acour.*quot_sal_m&m.<=(zsali&an._m&m.+quot_sal_m&m.*((&&bsup_css_c1&acour.-&&binf_css_c1&acour.)
                        *(tx_css_c1_&acour.+&&ass_csg_sal&acour.*&&tx_csgd_sal&acour.)-&&binf_css_c2&acour.*(tx_css_c2_&acour.+&&ass_csg_sal&acour.*&&tx_csgd_sal&acour.)))
                        /(1-&&ass_csg_sal&acour.*&&tx_csgd_sal&acour.-tx_css_c2_&acour.)<&&bsup_css_c2&acour.*quot_sal_m&m.);
                    tr_css_c3_m&m.=(&&binf_css_c3&acour.*quot_sal_m&m.<=(zsali&an._m&m.+quot_sal_m&m.*((&&bsup_css_c1&acour.-&&binf_css_c1&acour.)
                        *(tx_css_c1_&acour.+&&ass_csg_sal&acour.*&&tx_csgd_sal&acour.)+(&&bsup_css_c2&acour.-&&binf_css_c2&acour.)*(tx_css_c2_&acour.+&&ass_csg_sal&acour.*&&tx_csgd_sal&acour.)
                        -&&binf_css_c3&acour.*(tx_css_c3_&acour.+&&tx_csgd_sal&acour.)))/(1-&&tx_csgd_sal&acour.-tx_css_c3_&acour.)
                        <&&bsup_css_c3&acour.*quot_sal_m&m.);
                    tr_css_c4_m&m.=(&&binf_css_c4&acour.*quot_sal_m&m.<=(zsali&an._m&m.+quot_sal_m&m.*((&&bsup_css_c1&acour.-&&binf_css_c1&acour.)
                        *(tx_css_c1_&acour.+&&ass_csg_sal&acour.*&&tx_csgd_sal&acour.)+(&&bsup_css_c2&acour.-&&binf_css_c2&acour.)*(tx_css_c2_&acour.+&&ass_csg_sal&acour.*&&tx_csgd_sal&acour.)
                        +(&&bsup_css_c3&acour.-&&binf_css_c3&acour.)*(tx_css_c3_&acour.+&&tx_csgd_sal&acour.)-&&binf_css_c4&acour.*(&&tx_css_c4_&acour.+&&tx_csgd_sal&acour.)))
                        /(1-&&tx_csgd_sal&acour.-&&tx_css_c4_&acour.)<&&bsup_css_c4&acour.*quot_sal_m&m.);

                    /*ZSALBI_Mm : salaire brut au mois m*/
                    zsalbi&an._m&m.=(zsali&an._m&m.
                        +(tr_css_c2_m&m.+tr_css_c3_m&m.+tr_css_c4_m&m.=1)*(&&bsup_css_c1&acour.-&&binf_css_c1&acour.)*quot_sal_m&m.*(tx_css_c1_&acour.+&&ass_csg_sal&acour.*&&tx_csgd_sal&acour.)
                        +(tr_css_c3_m&m.+tr_css_c4_m&m.=1)*(&&bsup_css_c2&acour.-&&binf_css_c2&acour.)*quot_sal_m&m.*(tx_css_c2_&acour.+&&ass_csg_sal&acour.*&&tx_csgd_sal&acour.)
                        +(tr_css_c4_m&m.=1)*(&&bsup_css_c3&acour.-&&binf_css_c3&acour.)*quot_sal_m&m.*(tx_css_c3_&acour.+&&tx_csgd_sal&acour.)
                        - quot_sal_m&m.*((tr_css_c2_m&m.=1)*&&binf_css_c2&acour.*(tx_css_c2_&acour.+&&ass_csg_sal&acour.*&&tx_csgd_sal&acour.)
                        +(tr_css_c3_m&m.=1)*&&binf_css_c3&acour.*(tx_css_c3_&acour.+&&tx_csgd_sal&acour.)
                        +(tr_css_c4_m&m.=1)*&&binf_css_c4&acour.*(&&tx_css_c4_&acour.+&&tx_csgd_sal&acour.)))
                        /(1-((tr_css_c1_m&m.=1)*(tx_css_c1_&acour.+&&ass_csg_sal&acour.*&&tx_csgd_sal&acour.)+(tr_css_c2_m&m.=1)*(tx_css_c2_&acour.+&&ass_csg_sal&acour.*&&tx_csgd_sal&acour.)
                        +(tr_css_c3_m&m.=1)*(tx_css_c3_&acour.+&&tx_csgd_sal&acour.)+(tr_css_c4_m&m.=1)*(&&tx_css_c4_&acour.+&&tx_csgd_sal&acour.)));
                end;    

                /*Non cadres*/    
                if cadre=0 then do;
                /*Les salariés des entreprises publiques ne cotisent pas pour le chômage, on soustrait dont le taux de cotisation chômage (plafonné à 4 PSS) 
                du taux de cotisations total pour ces salariés. Dans la suite du code on remplace les macros variables &&tx_css par des variables */
                    tx_css_nc1_&acour.=&&tx_css_nc1_&acour.-&&tx_css_unedic&acour.*salarie_EN;
                    tx_css_nc2_&acour.=&&tx_css_nc2_&acour.-&&tx_css_unedic&acour.*salarie_EN;
                    tx_css_nc3_&acour.=&&tx_css_nc3_&acour.-&&tx_css_unedic&acour.*salarie_EN;

                    /*TR_CSS_NCi : tranche de cotisations pour les non cadres, i=1,..,4*/
                    tr_css_nc1_m&m.=(&&binf_css_nc1&acour.*quot_sal_m&m.<=(zsali&an._m&m.)
                        /(1-&&ass_csg_sal&acour.*&&tx_csgd_sal&acour.-tx_css_nc1_&acour.)<&&bsup_css_nc1&acour.*quot_sal_m&m.);
                    tr_css_nc2_m&m.=(&&binf_css_nc2&acour.*quot_sal_m&m.<=(zsali&an._m&m.+quot_sal_m&m.*((&&bsup_css_nc1&acour.-&&binf_css_nc1&acour.)
                        *(tx_css_nc1_&acour.+&&ass_csg_sal&acour.*&&tx_csgd_sal&acour.)-&&binf_css_nc2&acour.*(tx_css_nc2_&acour.+&&ass_csg_sal&acour.*&&tx_csgd_sal&acour.)))
                        /(1-&&ass_csg_sal&acour.*&&tx_csgd_sal&acour.-tx_css_nc2_&acour.)<&&bsup_css_nc2&acour.*quot_sal_m&m.);
                    tr_css_nc3_m&m.=(&&binf_css_nc3&acour.*quot_sal_m&m.<=(zsali&an._m&m.+quot_sal_m&m.*((&&bsup_css_nc1&acour.-&&binf_css_nc1&acour.)
                        *(tx_css_nc1_&acour.+&&ass_csg_sal&acour.*&&tx_csgd_sal&acour.)+(&&bsup_css_nc2&acour.-&&binf_css_nc2&acour.)*(tx_css_nc2_&acour.+&&ass_csg_sal&acour.*&&tx_csgd_sal&acour.)
                        -&&binf_css_nc3&acour.*(tx_css_nc3_&acour.+&&ass_csg_sal&acour.*&&tx_csgd_sal&acour.)))/(1-&&ass_csg_sal&acour.*&&tx_csgd_sal&acour.-tx_css_nc3_&acour.)
                        <&&bsup_css_nc3&acour.*quot_sal_m&m.);
                    tr_css_nc4_m&m.=(&&binf_css_nc4&acour.*quot_sal_m&m.<=(zsali&an._m&m.+quot_sal_m&m.*((&&bsup_css_nc1&acour.-&&binf_css_nc1&acour.)
                        *(tx_css_nc1_&acour.+&&ass_csg_sal&acour.*&&tx_csgd_sal&acour.)+(&&bsup_css_nc2&acour.-&&binf_css_nc2&acour.)*(tx_css_nc2_&acour.+&&ass_csg_sal&acour.*&&tx_csgd_sal&acour.)
                        +(&&bsup_css_nc3&acour.-&&binf_css_nc3&acour.)*(tx_css_nc3_&acour.+&&ass_csg_sal&acour.*&&tx_csgd_sal&acour.)-&&binf_css_nc4&acour.*(&&tx_css_nc4_&acour.+&&tx_csgd_sal&acour.)))
                        /(1-&&tx_csgd_sal&acour.-&&tx_css_nc4_&acour.)<&&bsup_css_nc4&acour.*quot_sal_m&m.);

                    /*ZSALBI_Mm : salaire brut au mois m*/
                    zsalbi&an._m&m.=(zsali&an._m&m.
                            +(tr_css_nc2_m&m.+tr_css_nc3_m&m.+tr_css_nc4_m&m.=1)*(&&bsup_css_nc1&acour.-&&binf_css_nc1&acour.)*quot_sal_m&m.
                            *(tx_css_nc1_&acour.+&&ass_csg_sal&acour.*&&tx_csgd_sal&acour.)
                            +(tr_css_nc3_m&m.+tr_css_nc4_m&m.=1)*(&&bsup_css_nc2&acour.-&&binf_css_nc2&acour.)*quot_sal_m&m.*(tx_css_nc2_&acour.+&&ass_csg_sal&acour.*&&tx_csgd_sal&acour.)
                            +(tr_css_nc4_m&m.=1)*(&&bsup_css_nc3&acour.-&&binf_css_nc3&acour.)*quot_sal_m&m.*(tx_css_nc3_&acour.+&&ass_csg_sal&acour.*&&tx_csgd_sal&acour.)
                            - quot_sal_m&m.*((tr_css_nc2_m&m.=1)*&&binf_css_nc2&acour.*(tx_css_nc2_&acour.+&&ass_csg_sal&acour.*&&tx_csgd_sal&acour.)
                            +(tr_css_nc3_m&m.=1)*&&binf_css_nc3&acour.*(tx_css_nc3_&acour.+&&ass_csg_sal&acour.*&&tx_csgd_sal&acour.)
                            +(tr_css_nc4_m&m.=1)*&&binf_css_nc4&acour.*(&&tx_css_nc4_&acour.+&&tx_csgd_sal&acour.)))
                            /(1-((tr_css_nc1_m&m.=1)*(tx_css_nc1_&acour.+&&ass_csg_sal&acour.*&&tx_csgd_sal&acour.)+(tr_css_nc2_m&m.=1)*(tx_css_nc2_&acour.+&&ass_csg_sal&acour.*&&tx_csgd_sal&acour.)
                            +(tr_css_nc3_m&m.=1)*(tx_css_nc3_&acour.+&&ass_csg_sal&acour.*&&tx_csgd_sal&acour.)+(tr_css_nc4_m&m.=1)*(&&tx_css_nc4_&acour.+&&tx_csgd_sal&acour.)));
                end;    
            end;            
        %end;
        %mend;
        %mens;

        /*ZSALBI_Ti : salaire brut au trimestre i*/
        zsalbi&an._t1=max(0,sum(zsalbi&an._m1,zsalbi&an._m2,zsalbi&an._m3));
        zsalbi&an._t2=max(0,sum(zsalbi&an._m4,zsalbi&an._m5,zsalbi&an._m6));
        zsalbi&an._t3=max(0,sum(zsalbi&an._m7,zsalbi&an._m8,zsalbi&an._m9));
        zsalbi&an._t4=max(0,sum(zsalbi&an._m10,zsalbi&an._m11,zsalbi&an._m12));
    end;


/**************************************************************************************************************************************************************/
/*		b. Cas des salariés du public							 		    																                  */
/**************************************************************************************************************************************************************/

    if zsali>0 & prive=0 then do; 	/*salarié du public*/
        
        /*Cas des agents titulaires, fonctionnaires*/
        if titulaire=1 then do; 
            %macro temps;
            %do m=1 %to 12;
                if zsali&an._m&m.>0 then do;
                    %let tx_css_fp&acour.=((1-&&tx_css_sol&acour.)*(&&tx_css_pc&acour.*(1-&&tx_prim&acour.)+&&tx_css_rafp&acour.*min(&&tx_prim&acour.,&&tx_css_rafp_max&acour.*(1-&&tx_prim&acour.)))+&&tx_css_sol&acour.);
                    /*Indicatrice de tranche de CSG : l'assiette est 98.25% du salaire brut jusqu'à 4 PSS, 100 % au-delà*/
                    tr_csg_fp_m&m.=zsali&an._m&m./(1-&&ass_csg_sal&acour.*&&tx_csgd_sal&acour.-&&tx_css_fp&acour.)<&&binf_css_c3&acour.*quot_sal_m&m.;
                    /*ZSALBI_Mm : salaire brut au mois m*/
                    zsalbi&an._m&m.=(zsali&an._m&m.-(tr_csg_fp_m&m.=0)*quot_sal_m&m.*&&binf_css_c3&acour.*&&tx_csgd_sal&acour.*(1-&&ass_csg_sal&acour.))
                        /(1-&&tx_css_fp&acour.-(tr_csg_fp_m&m.=1)*&&tx_csgd_sal&acour.*&&ass_csg_sal&acour.-(tr_csg_fp_m&m.=0)*&&tx_csgd_sal&acour.);
                end;
            %end;
            %mend;
            %temps;

            /*ZSALBI_Ti : salaire brut  au trimestre i*/
            zsalbi&an._t1=max(0,sum(zsalbi&an._m1,zsalbi&an._m2,zsalbi&an._m3));
            zsalbi&an._t2=max(0,sum(zsalbi&an._m4,zsalbi&an._m5,zsalbi&an._m6));
            zsalbi&an._t3=max(0,sum(zsalbi&an._m7,zsalbi&an._m8,zsalbi&an._m9));
            zsalbi&an._t4=max(0,sum(zsalbi&an._m10,zsalbi&an._m11,zsalbi&an._m12));
        end;

        /*Cas des contractuels*/
        else if titulaire=0 then do; 
        
            %macro temps2;
            %do m=1 %to 12;
                if zsali&an._m&m.>0 then do;

                    /*TR_CSS_NTi : tranche de cotisations pour les non titulaires, i=1 à 2*/
                    tr_css_nt1_m&m.=(&&binf_css_nc1&acour.*quot_sal_m&m.<=(zsali&an._m&m.)
                        /(1-&&ass_csg_sal&acour.*&&tx_csgd_sal&acour.-(1-&&tx_css_sol&acour.)*&&tx_css_nt1_&acour.-&&tx_css_sol&acour.)<&&bsup_css_nc1&acour.*quot_sal_m&m.);
                    tr_css_nt2_m&m.=(&&binf_css_nc2&acour.*quot_sal_m&m.<=(zsali&an._m&m.+quot_sal_m&m.*
                        ((&&bsup_css_nc1&acour.-&&binf_css_nc1&acour.)*((1-&&tx_css_sol&acour.)*&&tx_css_nt1_&acour.+&&tx_css_sol&acour.+&&ass_csg_sal&acour.*&&tx_csgd_sal&acour.)
                        -&&binf_css_nc2&acour.*((1-&&tx_css_sol&acour.)*&&tx_css_nt2_&acour.+&&tx_css_sol&acour.+&&ass_csg_sal&acour.*&&tx_csgd_sal&acour.)))
                        /(1-&&ass_csg_sal&acour.*&&tx_csgd_sal&acour.-(1-&&tx_css_sol&acour.)*&&tx_css_nt2_&acour.-&&tx_css_sol&acour.)<&&binf_css_c3&acour.*quot_sal_m&m.);
                    tr_css_nt3_m&m.=(zsali&an._m&m.+quot_sal_m&m.*((&&bsup_css_nc1&acour.-&&binf_css_nc1&acour.)
                        *((1-&&tx_css_sol&acour.)*&&tx_css_nt1_&acour.+&&tx_css_sol&acour.+&&ass_csg_sal&acour.*&&tx_csgd_sal&acour.)
                        +(&&binf_css_c3&acour.-&&binf_css_nc2&acour.)*((1-&&tx_css_sol&acour.)*&&tx_css_nt2_&acour.+&&tx_css_sol&acour.+&&ass_csg_sal&acour.*&&tx_csgd_sal&acour.)
                        -&&binf_css_c3&acour.*((1-&&tx_css_sol&acour.)*&&tx_css_nt2_&acour.+&&tx_css_sol&acour.+&&tx_csgd_sal&acour.)))
                        /(1-&&tx_csgd_sal&acour.-(1-&&tx_css_sol&acour.)*&&tx_css_nt2_&acour.-&&tx_css_sol&acour.)>=&&binf_css_c3&acour.*quot_sal_m&m.;
                    
                    /*ZSALBI_Mm : salaire brut au mois m*/
                    zsalbi&an._m&m.=(zsali&an._m&m.
                        +(tr_css_nt1_m&m.=0)*((1-&&tx_css_sol&acour.)*&&tx_css_nt1_&acour.+&&tx_css_sol&acour.+&&ass_csg_sal&acour.*&&tx_csgd_sal&acour.)*(&&bsup_css_nc1&acour.-&&binf_css_nc1&acour.)*quot_sal_m&m.
                        +(tr_css_nt3_m&m.=1)*((1-&&tx_css_sol&acour.)*&&tx_css_nt2_&acour.+&&tx_css_sol&acour.+&&ass_csg_sal&acour.*&&tx_csgd_sal&acour.)*(&&binf_css_c3&acour.-&&bsup_css_nc1&acour.)*quot_sal_m&m.
                        -(tr_css_nt2_m&m.=1)*((1-&&tx_css_sol&acour.)*&&tx_css_nt2_&acour.+&&tx_css_sol&acour.+&&ass_csg_sal&acour.*&&tx_csgd_sal&acour.)*&&bsup_css_nc1&acour.*quot_sal_m&m.
                        -(tr_css_nt3_m&m.=1)*((1-&&tx_css_sol&acour.)*&&tx_css_nt2_&acour.+&&tx_css_sol&acour.+&&tx_csgd_sal&acour.)*&&binf_css_c3&acour.*quot_sal_m&m.)
                            / (1-(1-&&tx_css_sol&acour.)*((tr_css_nt1_m&m.=1)*&&tx_css_nt1_&acour.+(tr_css_nt1_m&m.=0)*&&tx_css_nt2_&acour.) -&&tx_css_sol&acour.
                            -(tr_css_nt3_m&m.=0)*&&ass_csg_sal&acour.*&&tx_csgd_sal&acour.-(tr_css_nt3_m&m.=1)*&&tx_csgd_sal&acour.);

                end;
            %end;
            %mend;
            %temps2;

            /*ZSALBI_Ti : salaire brut au trimestre i*/
            zsalbi&an._t1=max(0,sum(zsalbi&an._m1,zsalbi&an._m2,zsalbi&an._m3));
            zsalbi&an._t2=max(0,sum(zsalbi&an._m4,zsalbi&an._m5,zsalbi&an._m6));
            zsalbi&an._t3=max(0,sum(zsalbi&an._m7,zsalbi&an._m8,zsalbi&an._m9));
            zsalbi&an._t4=max(0,sum(zsalbi&an._m10,zsalbi&an._m11,zsalbi&an._m12));

        end;
    end;


/*************************************************************************************************************************************************************/
/*				3- Revenus indépendants		   																						     				     */
/*************************************************************************************************************************************************************/

/*************************************************************************************************************************************************************/
/*		a. Cas des revenus agricoles							 		    																                 */
/*************************************************************************************************************************************************************/

/*************************************************************************************************************************************************************/
/* _1a : revenu agricole déclaré au niveau individuel en 2013																						         */
/*************************************************************************************************************************************************************/

    /*Assiette des cotisations en N : Revenus N-1*/
     %if &an.=&asuiv4. %then %do;
        %let suff=&asuiv3.;		/*suff = année de référence pour le calcul des cotisations*/
     %end;   
     %else %if &an.=&asuiv3. %then %do;
        %let suff=&asuiv2.;		/*suff = année de référence pour le calcul des cotisations*/
     %end;
     %else %if &an.=&asuiv2. %then %do;
        %let suff=&asuiv.;
     %end;
     %else %do;
        %let suff=;
     %end;


    /*Cas des indépendants*/
    /*Revenus des non salariés agricoles ZRAGI*/
    if (zragi&an. ne 0) then    do;
        if (CSTOT in ('11','12','13','71') and statut ne '13') then do; 		/*exploitants a titre principaux*/
            CSS_rag&an.=Max(zragi&suff.*(1-0.1*(STATUTS2='2')),&&ass_min_amexa&acour.*&&smic_hor_brut&an.)*&&tx_css_amexa_princ&acour.
                        + max(zragi&suff.,0)*&&tx_css_pfa&acour. + min(max(zragi&suff.,&&ass_min_avi&acour.*&&smic_hor_brut&an.),&&PSS&acour.*12)*&&tx_css_avi&acour.
                        + min(Max(zragi&suff.,&&ass_min_ava&acour.*&&smic_hor_brut&an.),&&PSS&acour.*12)*&&tx_css_ava_plaf&acour.
                        + Max(zragi&suff.,&&ass_min_ava&acour.*&&smic_hor_brut&an.)*&&tx_css_ava_deplaf&acour.  
                        + Max(zragi&suff.,&&ass_min_rco&acour.*&&smic_hor_brut&an.)*&&tx_css_rco_&acour.
                        + &&mt_css_atexa_cp_&acour.;
            
        end;
        else if ( STATUT = '13' or STATUTS2='3' ) then do; 						/*aides familaux*/ 
            CSS_rag&an.=min(&&tx_css_amexa_AF&acour.*&&ass_min_amexa&acour.*&&smic_hor_brut&an.*&&tx_css_amexa_princ&acour.,&&plaf_amexa_AF&acour.) /* montant minimum*/
                        + min(Max(zragi&suff.,&&ass_min_avi&acour.*&&smic_hor_brut&an.),&&PSS&acour.*12)*&&tx_css_avi&acour.
                        + min(Max(zragi&suff.,&&ass_min_ava_AF&acour.*&&smic_hor_brut&an.),&&PSS&acour.*12)*&&tx_css_ava_plaf&acour.
                        + &&mt_css_atexa_af_&acour.;
            
        end;
        else do; 																/*exploitants à titre secondaire */
            CSS_rag&an.=max(zragi&suff.,0)*&&tx_css_amexa_sec&acour. + &&mt_css_amexa_sec_&acour.
                        + max(zragi&suff.,0)*&&tx_css_pfa&acour. + min(Max(zragi&suff.,&&ass_min_avi&acour.*&&smic_hor_brut&an.),&&PSS&acour.*12)*&&tx_css_avi&acour.
                        + min(Max(zragi&suff.,&&ass_min_ava&acour.*&&smic_hor_brut&an.),&&PSS&acour.*12)*&&tx_css_ava_plaf&acour.
                        + Max(zragi&suff.,&&ass_min_ava&acour.*&&smic_hor_brut&an.)*&&tx_css_ava_deplaf&acour.  
                        + Max(zragi&suff.,&&ass_min_rco&acour.*&&smic_hor_brut&an.)*&&tx_css_rco_&acour.
                        + &&mt_css_atexa_cs_&acour.;
            
        end;

        CSGd_rag&an.=max(sum(zragi&suff.,CSS_rag&an.),0)*&&tx_csgd_sal&acour.; 	/*pas d'abattement assiette CSG pour les indépendants*/
        zragbi&an.=sum(zragi&an.,CSGd_rag&an.,CSS_rag&an.);
            
        %macro mens;            
            nbm_indep=(zragi_m1 ne 0)+(zragi_m2 ne 0)+(zragi_m3 ne 0)+(zragi_m4 ne 0)+(zragi_m5 ne 0)+(zragi_m6 ne 0)+(zragi_m7 ne 0)+(zragi_m8 ne 0)+(zragi_m9 ne 0)+(zragi_m10 ne 0)+(zragi_m11 ne 0)+(zragi_m12 ne 0);
            if nbm_indep=0 then nbm_indep=12;
            %do m=1 %to 12;
                zragbi&an._m&m.=(zragi_m&m. ne 0)*zragbi&an./nbm_indep;
            %end;
        %mend;
        %mens;


            /*ZragBI_Ti : salaire brut  au trimestre i*/
            zragbi&an._t1=max(0,sum(zragbi&an._m1,zragbi&an._m2,zragbi&an._m3));
            zragbi&an._t2=max(0,sum(zragbi&an._m4,zragbi&an._m5,zragbi&an._m6));
            zragbi&an._t3=max(0,sum(zragbi&an._m7,zragbi&an._m8,zragbi&an._m9));
            zragbi&an._t4=max(0,sum(zragbi&an._m10,zragbi&an._m11,zragbi&an._m12));


    end;

/*************************************************************************************************************************************************************/
/*		b. Cas des BIC											 		    																                 */
/*************************************************************************************************************************************************************/

/*************************************************************************************************************************************************************/
/* _1i : revenu industriels et commerciaux déclarés au niveau individuels en 2013																	         */
/*************************************************************************************************************************************************************/

/*Revenus des non salariés industriels et commerciaux ZRICI*/
if (ZRICI&suff. ne 0) then do; 		/*CS '21' artisans et '22' commerçants et assimilés*/

        if cstot='21' then do;		/*Artisans*/
            CSS_ric&an.=&&tx_css_maladie&acour..*Max(zrici&suff.,&&ass_min_canam&acour.*12*&&PSS&acour..)
                        +&&tx_css_IJ&acour..*Max(Min(zrici&suff.,&&plaf_canam2&acour.*12*&&PSS&acour..),&&ass_min_canam&acour..*12*&&PSS&acour..)
                        +&&tx_css_af_i&acour.*zrici&suff.*(zrici&suff.>=&&seuil_af&acour.)
                        +&&tx_css_fp_art&acour.*12*&&PSS&acour.
                        +&&tx_css_rsi1&acour.*Max(Min(zrici&suff.,12*&&PSS&acour.),12*&&ass_min_rsi&acour..*&&PSS&acour.)
                        +&&tx_css_rco_rsi&acour.*Max(Min(zrici&suff.,&&plaf_rco1_rsi&acour.*12*&&PSS&acour.),12*&&ass_min_rsi&acour.*&&PSS&acour.)
                        +&&tx_css_rco2_rsi&acour.*Min(Max(zrici&suff.-&&plaf_rco1_rsi&acour.*12*&&PSS&acour.,0),(&&plaf_rco2_rsi&acour.-&&plaf_rco1_rsi&acour.)*12*&&PSS&acour.)
                        +&&tx_css_inv_art&acour.*Max(zrici&suff.,12*&&ass_min_inv&acour.*&&PSS&acour.);
            
        end;
        else do; 					/*Commerçants et autres*/
                CSS_ric&an.=&&tx_css_maladie&acour.*Max(zrici&suff.,&&ass_min_canam&acour.*12*&&PSS&acour.)
                        +&&tx_css_IJ&acour.*Max(Min(zrici&suff.,&&plaf_canam2&acour.*12*&&PSS&acour.),&&ass_min_canam&acour.*12*&&PSS&acour.)
                        +&&tx_css_af_i&acour.*zrici&suff.*(zrici&suff.>=&&seuil_af&acour.)
                        +&&tx_css_fp_i&acour.*12*&&PSS&acour.
                        +&&tx_css_rsi1&acour.*Max(Min(zrici&suff.,12*&&PSS&acour.),12*&&ass_min_rsi&acour.*&&PSS&acour.)
                        +&&tx_css_rco_rsi&acour.*Max(Min(zrici&suff.,&&plaf_rco1_rsi&acour.*12*&&PSS&acour.),12*&&ass_min_rsi&acour.*&&PSS&acour.)
                        +&&tx_css_rco2_rsi&acour.*Min(Max(zrici&suff.-&&plaf_rco1_rsi&acour.*12*&&PSS&acour.,0),(&&plaf_rco2_rsi&acour.-&&plaf_rco1_rsi&acour.)*12*&&PSS&acour.)
                        +&&tx_css_inv_com&acour.*Max(zrici&suff.,12*&&ass_min_inv&acour.*&&PSS&acour.);    
        end;

        CSGd_ric&an.=max(sum(zrici&suff.,CSS_ric&an.),0)*&&tx_csgd_sal&acour.;
        zricbi&an.=sum(zrici&an.,CSGd_ric&an.,CSS_ric&an.);

        %macro mens;            
            nbm_indep=(zrici_m1 ne 0)+(zrici_m2 ne 0)+(zrici_m3 ne 0)+(zrici_m4 ne 0)+(zrici_m5 ne 0)+(zrici_m6 ne 0)+(zrici_m7 ne 0)+(zrici_m8 ne 0)+(zrici_m9 ne 0)+(zrici_m10 ne 0)+(zrici_m11 ne 0)+(zrici_m12 ne 0);
            if nbm_indep=0 then nbm_indep=12;
            %do m=1 %to 12;
                zricbi&an._m&m.=(zrici_m&m. ne 0)*zricbi&an./nbm_indep;
            %end;
        %mend;
        %mens;


        /*ZricBI_Ti : salaire brut au trimestre i*/
        zricbi&an._t1=max(0,sum(zricbi&an._m1,zricbi&an._m2,zricbi&an._m3));
        zricbi&an._t2=max(0,sum(zricbi&an._m4,zricbi&an._m5,zricbi&an._m6));
        zricbi&an._t3=max(0,sum(zricbi&an._m7,zricbi&an._m8,zricbi&an._m9));
        zricbi&an._t4=max(0,sum(zricbi&an._m10,zricbi&an._m11,zricbi&an._m12));
end; 


/*Revenus des non salariés non commerciaux ZRNCI */
if (ZRNCI&suff. ne 0) then do; /*CS '31' prof. libérales et '35' '42' '43' '46'*/

   		CSS_rnc&an.=&&tx_css_maladie&acour.*Max(zrnci&suff.,&&ass_min_canam&acour.*12*&&PSS&acour.)
                        +&&tx_css_af_i&acour.*zrnci&suff.*(zrnci&suff.>=&&seuil_af&acour.)
                        +&&tx_css_fp_i&acour.*12*&&PSS&acour.
                        +&&tx_css_rsi2&acour.*Max(Min(zrnci&suff.,&&plaf_cnavpl1&acour.*12*&&PSS&acour.),12*&&ass_min_rsi&acour.*&&PSS&acour.)
                        +&&tx_css_rsi3&acour.*Min(Max(zrnci&suff.-&&plaf_cnavpl1&acour.*12*&&PSS&acour.,0),(&&plaf_cnavpl2&acour.-&&plaf_cnavpl1&acour.)*12*&&PSS&acour.)
                        +&&tx_css_rco_lib&acour.*Max(zrnci&suff.,0)
                        +&&tx_css_inv_lib&acour.*Max(zrnci&suff.,0);

        CSGd_rnc&an.=max(sum(zrnci&suff.,CSS_rnc&an.),0)*&&tx_csgd_sal&acour.;
        zrncbi&an.=sum(zrnci&an.,CSGd_rnc&an.,CSS_rnc&an.);
   
        %macro mens;            
            nbm_indep=(zrnci_m1 ne 0)+(zrnci_m2 ne 0)+(zrnci_m3 ne 0)+(zrnci_m4 ne 0)+(zrnci_m5 ne 0)+(zrnci_m6 ne 0)+(zrnci_m7 ne 0)+(zrnci_m8 ne 0)+(zrnci_m9 ne 0)+(zrnci_m10 ne 0)+(zrnci_m11 ne 0)+(zrnci_m12 ne 0);
            if nbm_indep=0 then nbm_indep=12;
            %do m=1 %to 12;
                zrncbi&an._m&m.=(zrnci_m&m. ne 0)*zrncbi&an./nbm_indep;
            %end;
        %mend;
        %mens;


        /*ZrncBI_Ti : salaire brut  au trimestre i*/
            zrncbi&an._t1=max(0,sum(zrncbi&an._m1,zrncbi&an._m2,zrncbi&an._m3));
            zrncbi&an._t2=max(0,sum(zrncbi&an._m4,zrncbi&an._m5,zrncbi&an._m6));
            zrncbi&an._t3=max(0,sum(zrncbi&an._m7,zrncbi&an._m8,zrncbi&an._m9));
            zrncbi&an._t4=max(0,sum(zrncbi&an._m10,zrncbi&an._m11,zrncbi&an._m12));

    end; 
    
    drop tx_css_:;
run;


proc sort data=saphir.revbrut&an.; by ident&acour. noi; run; 
%mend; 

%revbrut(an=&asuiv.);  /*2014 => pour l'assiette des cotisations des indépendants*/
%revbrut(an=&asuiv2.); /*2015*/
%revbrut(an=&asuiv3.); /*2016*/
%revbrut(an=&asuiv4.); /*2017*/

/*************************************************************************************************************************************************************
**************************************************************************************************************************************************************

Ce logiciel est régi par la licence CeCILL V2.1 soumise au droit français et respectant les principes de diffusion des logiciels libres. 

Vous pouvez utiliser, modifier et/ou redistribuer ce programme sous les conditions de la licence CeCILL V2.1. 

Le texte complet de la licence CeCILL V2.1 est dans le fichier `LICENSE`.

Les paramètres de la législation socio-fiscale figurant dans les programmes 6, 7a et 7b sont régis par la « Licence Ouverte / Open License » Version 2.0.
**************************************************************************************************************************************************************
*************************************************************************************************************************************************************/

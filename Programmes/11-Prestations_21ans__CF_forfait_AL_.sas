
/**************************************************************************************************************************************************************/
/*                                   								SAPHIR E2013 L2017                                       								  */
/*                                        								PROGRAMME 11                                        								  */
/*      								Creation des familles et calcul des prestations dont l'age limite est < 21 ans        								  */
/**************************************************************************************************************************************************************/



/**************************************************************************************************************************************************************/
/* Dans l’ERFS, les informations sont fournies à différents niveaux selon les tables. Lors de l’imputation des transferts sociaux, les familles au sens de la */
/* CAF et les foyers RSA doivent être construits au début des programmes correspondant aux prestations pour lesquelles ces unités servent de référence. Ces   */
/* constructions permettent de prendre en compte les cas où il existe plusieurs familles par ménage, mais pas ceux où une famille serait éclatée dans         */
/* plusieurs ménages. 																																		  */
/*																																							  */
/* Un travail préparatoire sur les données est réalisé afin de déterminer pour chaque individu le sexe, l’âge et l’identifiant d’éventuels conjoint, parents  */
/* ou enfants. Ces informations permettent d’idenfier les personnes à charge à la date de l’enquête au sens des prestations familiales, c’est-à-dire les 	  */
/* personnes vérfiant les conditions d’âge et de revenus d’activité inférieurs à 55 % du SMIC. 																  */
/*																																							  */
/* Ce programme calcule par la suite sur barème les montants des prestations dont l'age limite est 21 ans : 												  */
/* 				- CF                                                                                														  */
/*				- allocation forfaitaire des AF                                                            													  */
/*				- allocations logement     																  													  */
/* Les macros définies servent également au calcul des montants des prestations dont l'age limite est 20 ans et qui sont calculées dans le programme 12		  */
/**************************************************************************************************************************************************************/


/**************************************************************************************************************************************************************/
/**************************************************************************************************************************************************************/
/*                										I. Creation des familles avec age limite < 21 ans                   								  */
/**************************************************************************************************************************************************************/
/**************************************************************************************************************************************************************/


/**************************************************************************************************************************************************************/
/*				1- Détermination de la famille principale 																									  */
/**************************************************************************************************************************************************************/

proc sql;  create table indiv_prest as select a.*, b.noiprmcj  from scenario.indiv_prest as a left join 
		(select ident&acour., noicon as noiprmcj from scenario.indiv_prest where (lprm='1')) as b on a.ident&acour.=b.ident&acour. ;
quit;


%macro fam (tabin= ,age=, prest=,nom_unite=);

data indiv_prest&age. (compress = yes);
set &tabin.;

/*PCPF : indicatrice qui vaut 1 si l'individu est une personne à charge au sens des prestations familiales (condition d'âge et condition de revenu)*/
if noi ne ' ' then do ;
if "&prest."="rsa" then 
 		pc&prest.&age.=(agenq<&age. & (pcpf20=1 ! noiper ne ' ' ! noimer ne ' ') &  /*à charge au sens des prestations familiales ou enfant*/	
						(noienft1=' ' & enceintep3 ne 1) &                  		/*ne pas avoir soi-même un enfant*/
						(noicon=' ')); 	                                    		/*ne pas avoir de conjoint*/

%if &age.=21  %then %do ; drop pcpf20 ; %end ;
if "&prest."="pf" then do ;
		pc&prest.&age.=((((noiper ne ' ' ! noimer ne ' ') & agenq<=&age.) ! (lprm in ('4','5','6') & agenq<=16)) &  /*on prend en compte ceux qui ont 21 ans dans l'année*/
						 (noienft1=' ') &  sum(revactp&asuiv4.,zchopi&asuiv4.)<0.55*169*&&smic_hor_brut&asuiv4.*12); end ; /*l'enfant à charge ne peut pas avoir un salaire mensuel supérieur à 169*55%*Smic horaire brut*/
	
end ;
/*NOI_pr : numero de l'allocataire référent*/
/*NOI_Cpr : numero du conjoint de l'allocataire référent*/

		/** Personnes à charge **/
	if pc&prest.&age.=1 then do;
		if (noiper ne ' ')|(noimer ne ' ') then do;
				noi_pr&prest.=put(min(noiper,noimer),2.);
					if length(compress(noi_pr&prest.))=1 then noi_pr&prest.=compress(0||noi_pr&prest.);
				noi_cpr&prest.=put(max(noiper,noimer),2.) ;
					if length(compress(noi_cpr&prest.))=1 then noi_cpr&prest.=compress(0||noi_cpr&prest.);
					if noi_cpr&prest.=noi_pr&prest. then noi_cpr&prest.=' ' ;
				end ;
		else do; /*ni pere ni mere => personne de référence du ménage*/
			noi_pr&prest.=compress(0||min(noiprm,noiprmcj)); 
			noi_cpr&prest.=compress(0||max(noiprm,noiprmcj));					
		end;
	end;

		/** Personnes qui ne sont pas à charge : la personne de référence est celle qui a le plus petit identifiant (noi) **/	
	else if pc&prest.&age.=0 then do;
		noi_pr&prest.=noi;
		if noicon ne ' ' and noicon>noi then noi_cpr&prest.=noicon; 
		else if noicon ne ' ' and noicon<noi then do ; noi_pr&prest.=noicon ; noi_cpr&prest.=noi ; end ;
	end ;
			
run;

		/** Indicatrice de conjoint de personne à charge **/
proc sql;  create table fam_prest&age. as select a.*, b.pc&prest.&age. as pc&prest.&age._conj  from indiv_prest&age. as a left join 
		(select ident&acour., pc&prest.&age., noicon from indiv_prest&age. where (pc&prest.&age.=1 and noicon ne ' ')) as b on a.ident&acour.=b.ident&acour. and a.noi=b.noicon order by ident&acour., noi_pr&prest. ;
quit;

data fam_prest&age. ;
set fam_prest&age.;

if pc&prest.&age._conj=1 then do ; noi_cpr&prest.=' ' ; noi_pr&prest.=noi; end ;
by ident&acour. noi_pr&prest.;
retain &nom_unite. 0 ;

if first.ident&acour. then &nom_unite.=0 ;
if first.noi_pr&prest. then &nom_unite.=&nom_unite.+1;

if lprm='1' then famp=1 ;

run;

		/** Nombre maximal de personnes à charge **/
%global nb_max_pc ;
proc sql noprint; select max(taille) into : nb_max_pc from (select sum(pc&prest.&age.=1) as taille from fam_prest&age. group by ident&acour.) ;  quit;

		/** Détermination de la famille principale **/
proc sql;  create table famp as select ident&acour., &nom_unite., sum (lprm = '1') as famp  from fam_prest&age. group by ident&acour., &nom_unite. ; quit;


%mend fam;
%fam (tabin=indiv_prest, age=21, prest=pf, nom_unite=numpf21); 


/**************************************************************************************************************************************************************/
/*				2- Informations sur les personnes à charge : date de naissance, en études 										  							  */
/**************************************************************************************************************************************************************/

/*Table PCPF*/
%macro pc(listvar=, age=, prest=, nom_unite=);
proc sort data=fam_prest&age.; by ident&acour. &nom_unite.; run;
	
%let i=1;
%do %while(%index(&listvar.,%scan(&listvar.,&i.))>0); 
	%let var=%scan(&listvar.,&i.);
	proc transpose data=fam_prest&age. (where=(pc&prest.&age.=1)) out=&var. (drop=_LABEL_ _NAME_) prefix=&var._pc&prest.;
	by ident&acour. &nom_unite.;
	var &var.;
	run;

	%let i=%eval(&i.+1);
%end;

data pc&prest. ;
merge &listvar.;
by ident&acour. &nom_unite.;
run;

proc datasets library=work;delete &listvar.;run;quit;
%mend;

%pc(listvar=naia naim, age=21, prest=pf, nom_unite=numpf21  );


/**************************************************************************************************************************************************************/
/*				3- Informations sur l'allocataire principal et son conjoint : enceinte, a connu une séparation, salaires... 			  					  */
/**************************************************************************************************************************************************************/

/*Table PRPF */

%macro rename(lien=,age=,liste=,nom_unite= );

data &lien. (drop =noi);
set fam_prest&age. (where=(noi=noi_&lien. ) keep = ident&acour. noi noi_&lien. &nom_unite. &liste.);
%let i=1;
%do %while(%index(&liste.,%scan(&liste.,&i.))>0); 
	rename %scan(&liste.,&i.)=%scan(&liste.,&i.)_&lien.;
	%let i=%eval(&i.+1);
%end;
run;

proc sort data=&lien.; by ident&acour. &nom_unite.; run;

%mend;


%rename (lien=prpf, age=21, nom_unite=numpf21,
liste=sexe agenq naiss_futur_a naiss_futur_m naiss_futur dv_fip ISO_FIP  acteu 
REVACTD&asuiv2. REVINDED&asuiv2. ZTSAI&asuiv2. ZCHOI&asuiv2. ZPERI&asuiv2. ZRSTI&asuiv2. ZALRI&asuiv2. ZRTOI&asuiv2.
REVPATM&asuiv2. zalvm&asuiv2. zalri&asuiv4. _1AK _1AI );

%rename (lien=cprpf, age=21, nom_unite=numpf21,
liste=sexe agenq naiss_futur_a naiss_futur_m naiss_futur acteu 
REVACTD&asuiv2. REVINDED&asuiv2. ZTSAI&asuiv2. ZCHOI&asuiv2. ZPERI&asuiv2. ZRSTI&asuiv2. ZALRI&asuiv2. ZRTOI&asuiv2. 
REVPATM&asuiv2. zalvm&asuiv2. zalri&asuiv4. _1AK _1AI);

data fam21; merge famp (in=a) pcpf prpf cprpf; by ident&acour. numpf21; if a; run;


/**************************************************************************************************************************************************************/
/*				4- Informations sur le menage  																  												  */
/**************************************************************************************************************************************************************/

/*BR_AL : pour les aides au logement (AL), la base ressources comprend les ressources de toutes les personnes du ménage*/

data BR_AL (keep = ident&acour. BR_AL BR_AL_rsa acteu6prm);
set scenario.indiv_prest;
by ident&acour.;
retain BR_AL 0 ;
retain BR_AL_rsa 0 ;

if _1ak=. then _1ak=0;
if _1ai=. then _1ai=0;

if first.ident&acour. then do;
	BR_AL=0;
	BR_AL_rsa=0;
end;

/*La base ressources des AL porte sur les ressources déclarées n-2*/	
BR_AL=max(0,sum(BR_AL,
			ztsai&asuiv2.,
			-(ztsai&asuiv2.>0)*max(min(max(min(ztsai&asuiv2.*0.1,&abat_tsal_max.),(_1ai=0)*&abat_tsal_min.+(_1ai=1)*&abat_tsal_min_cho.),ztsai&asuiv2.),_1ak),			
			zperi&asuiv2.,
			-(zperi&asuiv2.>0)*min(max(min(zperi&asuiv2.*0.1,&abat_pens_max.),&abat_pens_min.),zperi&asuiv2.),			
			revinded&asuiv2.,
			REVPATM&asuiv2.,-&micfonc_abat_taux.*zfonm&asuiv2., /*pour simplifier, on suppose que les bénéficiaires des AL sont au régime micro foncier 
																  (abattement de 30%)*/
			- zalvm&asuiv2.
		));

/*Abattement pour les allocataires du RSA : exclusion des revenus d'activité et des allocations chômage (l'abattement de 30 % pour les chômeurs n'est pas simulé
											en l'absence de leurs revenus n-2 dans Saphir; toutefois le fait de prendre en compte l'ARE plutôt que le salaire 
											conduit de facto à un abattement)*/	
 BR_AL_rsa=max(0,sum(BR_AL_rsa,
			zperi&asuiv2.,
			-(zperi&asuiv2.>0)*min(max(min(zperi&asuiv2.*0.1,&abat_pens_max.),&abat_pens_min.),zperi&asuiv2.),			
			REVPATM&asuiv2., -&micfonc_abat_taux.*zfonm&asuiv2., 		
			- zalvm&asuiv2.
		));

/*Plancher de ressources pour les étudiants ; on met à tous le plancher boursier si leur bourse est inférieure*/
if acteu6prm='5' & br_al<&planch_et. then br_al=&planch_et.; 

if last.ident&acour. then output; /*une ligne par ménage*/
run;


data fam21;
merge fam21 (in=a) br_al
saphir.menage_saphir (keep= ident&acour. logt tuu2010 collm colla collj wprm&asuiv4. m_alfm m_alsetm m_alsm m_aplm origpsoc) ;
by ident&acour.;
if a;
run;

proc datasets library=work;delete pcpf prpf cprpf famp indiv_prest21 br_al;run;quit;



/**************************************************************************************************************************************************************/
/**************************************************************************************************************************************************************/
/*		            										II. Calcul des PF où familles avec age limite < 21 ans            								  */
/**************************************************************************************************************************************************************/
/**************************************************************************************************************************************************************/

data scenario.prest_fam21 (compress = yes );
set fam21;

%macro prest_fam21;


/**************************************************************************************************************************************************************/
/*				1- Création des variables auxiliaires 																										  */
/**************************************************************************************************************************************************************/

/*AGEPCi_t : age de la ième personne à charge au tieme mois un an avant la date de collecte*/
/*AGEPCi_12 = age à la date de l'enquete*/

%do i=1 %to 12;	

	/*Determination du mois et de l'annee au ieme mois*/
	m&i.=collm+&i.;
	if m&i.>12 then m&i.=m&i.-12;
	if m&i.>collm then a&i.=colla-1;
	else a&i.=colla;

	/*Calcul de l'age*/
	%do j=1 %to &nb_max_pc.;
		if naia_pcpf&j. ne . & 
			((naia_pcpf&j.*12+naim_pcpf&j.<a&i.*12+m&i.) ! 
			(naia_pcpf&j.*12+naim_pcpf&j.=a&i.*12+m&i. & collj>15))
			then do;	/*attention : calculer les ages aux dates postérieures à la naissance*/

			/*Age de la personne à charge à chaque mois*/
			if naia_pcpf&j.=colla then do;
				if m&i.<naim_pcpf&j. then agepc&j._&i.=.;
				else if naim_pcpf&j.=m&i. then do;
					if collj>15 then agepc&j._&i.=0;
					else agepc&j._&i.=.;
				end;
				else if naim_pcpf&j.<m&i. then agepc&j._&i.=0;
			end;
			else do;
				if naim_pcpf&j.<m&i. then agepc&j._&i.=a&i.-naia_pcpf&j.;
				else if naim_pcpf&j.=m&i. then do;
					if collj>15 then agepc&j._&i.=a&i.-naia_pcpf&j.;
					else agepc&j._&i.=a&i.-naia_pcpf&j.-1;
				end;
				else if naim_pcpf&j.>m&i. then agepc&j._&i.=a&i.-naia_pcpf&j.-1;
			end;
		end;
	%end;
%end;

/*NBPCXXYY_t : Nombre de personnes à charge de XX-YY ans au mois t*/
%do i=1 %to 12;
	nbpc019_&i.=0;  /*0-19 ans*/
	nbpc020_&i.=0;  /*0-20 ans*/
	nbpc20_&i.=0;   /*20 ans*/
	nbpc320_&i.=0;  /*3-20 ans pour le CF */

	%do j=1 %to &nb_max_pc.;
		if 0<=agepc&j._&i.<=19 then nbpc019_&i.=nbpc019_&i.+1;     /*0-19 ans*/
		if 0<=agepc&j._&i.<=20 then nbpc020_&i.=nbpc020_&i.+1;     /*0-20 ans*/
		if agepc&j._&i.=20 then nbpc20_&i.=nbpc20_&i.+1;           /*20 ans*/
		if 3<=agepc&j._&i.<=20 then nbpc320_&i.=nbpc320_&i.+1;     /*3-20 ans*/
	%end;
%end;

/*PRPF, CPRPF*/
prpf=(noi_prpf ne ' ');
cprpf=(noi_cprpf ne ' ');

/*ACT_PRPF, ACT_CPRPF : Statut d'activité pour déterminer la biactivité*/
act_prpf=(revactd&asuiv2._prpf>=&seuil_biact.);
act_cprpf=(revactd&asuiv2._cprpf>=&seuil_biact.);


/**************************************************************************************************************************************************************/
/*				2- Calcul des prestations familiales 															 											  */
/**************************************************************************************************************************************************************/

/**************************************************************************************************************************************************************/
/*		a. Base ressource des prestations familiales (BR_PF)																	 		                      */
/**************************************************************************************************************************************************************/

/*On initialise la BR*/
BR_PF=0; 

array tsal (2) ztsai&asuiv2._prpf ztsai&asuiv2._cprpf ;
array ak (2) _1ak_prpf _1ak_cprpf ;
array ai (2) _1ai_prpf _1ai_cprpf ;

array rst (2) zrsti&asuiv2._prpf zrsti&asuiv2._cprpf ;
array alr (2) zalri&asuiv2._prpf zalri&asuiv2._cprpf ;
array rto (2) zrtoi&asuiv2._prpf zrtoi&asuiv2._cprpf ;

array revinded (2) revinded&asuiv2._prpf revinded&asuiv2._cprpf ;

array REVPATM (2) REVPATM&asuiv2._prpf REVPATM&asuiv2._cprpf ;

array alv (2) zalvm&asuiv2._prpf zalvm&asuiv2._cprpf ;

do i=1 to 2;
	BR_PF=sum(BR_PF,
			/*Salaires et traitement*/
			tsal(i),
			-(tsal(i)>0)*max(min(max(min(tsal(i)*0.1,&abat_tsal_max.),(ai(i)=0)*&abat_tsal_min.+(ai(i)=1)*&abat_tsal_min_cho.),tsal(i)),ak(i)),			
			/*Pensions*/
			sum(rst(i),alr(i),rto(i)),
			-(sum(rst(i),alr(i),rto(i))>0)*min(max(min(sum(rst(i),alr(i),rto(i))*0.1,&abat_pens_max.),&abat_pens_min.),sum(rst(i),alr(i),rto(i))),
			/*Revenus des indépendants*/
			revinded(i),	
			/*Revenus patrimoine*/
			REVPATM(i),	
			/*Déduction des pensions alimentaires versées*/
			- alv(i)
		);
end;

drop i;


/**************************************************************************************************************************************************************/
/*		b. Allocation forfaitaire (AFORFi)																	 		                      					  */
/**************************************************************************************************************************************************************/

/*Un enfant de 20 ans et deux autres de moins de 20 ans, strictement*/
aforf=0;
%do i=1 %to 12;	
	aforf&i.=0;
    aforf&i.= nbpc20_&i.*(nbpc019_&i.>=2)*&&bmaf&asuiv4.*(1-&&tx_crds&asuiv4.)*(
              (BR_PF<=(&borne1_AF. + nbpc019_&i.*&borne_AF_majo.))*&tauxAFORF. +
			  ((&borne1_AF. + nbpc019_&i.*&borne_AF_majo.)<BR_PF<=(&borne2_AF. + nbpc019_&i.*&borne_AF_majo.))*(&tauxAFORF./2) +
			  (BR_PF>(&borne2_AF. + nbpc019_&i.*&borne_AF_majo.))*(&tauxAFORF./4));

			/*Complément dégressif en cas de faible dépassement d'un des plafonds*/
    if (&borne2_AF. + nbpc019_&i.*&borne_AF_majo.)<BR_PF & sum(BR_PF, - (&borne2_AF. + nbpc019_&i.*&borne_AF_majo.))<12*aforf&i. 
    then aforf&i.=sum(aforf&i., sum((&borne2_AF. + nbpc019_&i.*&borne_AF_majo.),12*aforf&i. ,-BR_PF)/12);
    else if (&borne1_AF. + nbpc019_&i.*&borne_AF_majo.)<BR_PF & sum(BR_PF, - (&borne1_AF. + nbpc019_&i.*&borne_AF_majo.))<12*aforf&i.
    then aforf&i.=sum(aforf&i., sum((&borne1_AF. + nbpc019_&i.*&borne_AF_majo.),12*aforf&i. ,-BR_PF)/12);

%end;
aforf=sum(of aforf1-aforf12);


/**************************************************************************************************************************************************************/
/*		c. Complément familial (CF)																			 		                      					  */
/**************************************************************************************************************************************************************/

cf=0;
cf_base=0;
    %do i=1 %to 12;	
        cf&i.=0;
		cf_base&i.=0;
    	if nbpc320_&i.>=3 then do;
    		if prpf+cprpf=2 & act_prpf+act_cprpf<=1 then 
    		cf_base&i.=&tauxcf.*&&bmaf&asuiv4.*(1-&&tx_crds&asuiv4.)*max(0,min(1,(&plaf_cf_m3.+&plaf_cf_sup.*(nbpc020_&i.-3)+(&tauxcf.*&&bmaf&asuiv4.*(1-&&tx_crds&asuiv4.)*12)-BR_PF)/(&tauxcf.*&&bmaf&asuiv4.*(1-&&tx_crds&asuiv4.)*12)));
            if act_prpf+act_cprpf=2 ! prpf+cprpf=1 then 
    		cf_base&i.=&tauxcf.*&&bmaf&asuiv4.*(1-&&tx_crds&asuiv4.)*max(0,min(1,(&plaf_cf_3.+&plaf_cf_sup.*(nbpc020_&i.-3)+(&tauxcf.*&&bmaf&asuiv4.*(1-&&tx_crds&asuiv4.)*12)-BR_PF)/(&tauxcf.*&&bmaf&asuiv4.*(1-&&tx_crds&asuiv4.)*12)));
	/*majoration du CF*/    
    		if prpf+cprpf=2 & act_prpf+act_cprpf<=1 then 
    		cf_majo&i.=&tauxcf_majo.*&&bmaf&asuiv4.*(1-&&tx_crds&asuiv4.)*max(0,min(1,(&plaf_cf_m3_majo.+&plaf_cf_sup_majo.*(nbpc020_&i.-3)+(&tauxcf_majo.*&&bmaf&asuiv4.*(1-&&tx_crds&asuiv4.)*12)-BR_PF)/(&tauxcf_majo.*&&bmaf&asuiv4.*(1-&&tx_crds&asuiv4.)*12)));
            if act_prpf+act_cprpf=2 ! prpf+cprpf=1 then 
    		cf_majo&i.=&tauxcf_majo.*&&bmaf&asuiv4.*(1-&&tx_crds&asuiv4.)*max(0,min(1,(&plaf_cf_3_majo.+&plaf_cf_sup_majo.*(nbpc020_&i.-3)+(&tauxcf_majo.*&&bmaf&asuiv4.*(1-&&tx_crds&asuiv4.)*12)-BR_PF)/(&tauxcf_majo.*&&bmaf&asuiv4.*(1-&&tx_crds&asuiv4.)*12)));

            cf&i.=max(cf_base&i., cf_majo&i.);
    	end;
    %end;

cf=sum(of cf1-cf12);
cf_base=sum(of cf_base1-cf_base12);		/*pour le calcul de la base ressource du RSA*/


/**************************************************************************************************************************************************************/
/*				3- Calcul des allocations logement   															 											  */
/**************************************************************************************************************************************************************/

/**************************************************************************************************************************************************************/
/*AL_LOC : aides au logement sur barème, pour les seuls locataires, sous l'hypothèse qu'ils sont tous au loyer plafond										  */
/*			AL=Lplf + C - Pp																																  */
/*			Pp=P0+(TP*RP)																																	  */
/*			TP=TF+TL 																																		  */
/*			RP=R-R0																																			  */
/**************************************************************************************************************************************************************/

/*Initialisation à 0 pour tous*/
AL_loc=0; 
AL_loc_rsa=0;
if logt in('3','4','5') & famp=1 then do; /*les familles principales sont locataires*/

/*ZONE : zone géographique*/
if tuu2010='8' then zone='1';
else if tuu2010 in ('6','7') then zone='2';
else if tuu2010 in ('0','1','2','3','4','5') then zone='3';

	/*Lplf : loyer plafond*/
	%do z=1 %to 3;
		if zone="&z." then do;
			if nbpc020_12=0 then do;
				if cprpf=0 then Lplf=&&Lplfiso&z.;     	/*isolé sans personne à charge*/
				else if cprpf=1 then Lplf=&&Lplfc0&z.; 	/*couple sans personne à charge*/
			end;
			else Lplf=(nbpc020_12>=1)*&&Lplf1e&z.+(nbpc020_12-1)*&&Lplfsup&z.;  
		end;
	%end;

	/*RL : loyer plafonné divisé par le loyer de référence*/
	if nbpc020_12=0 then do;
		if cprpf=0 then RL=Lplf/&Lplfiso2.*100;     	/*isolé sans personne à charge*/
		else if cprpf=1 then RL=Lplf/&Lplfc02.*100; 	/*couple sans personne à charge*/
	end;
	else RL=Lplf/((nbpc020_12>=1)*&Lplf1e2.+(nbpc020_12-1)*&Lplfsup2.)*100;  

	/*TL : taux de participation complémentaire*/
	if 0<RL<&b_tm1. then TL=0;
	else if &b_tm1.<=RL<&b_tm2. then TL=(RL-&b_tm1.)*&tm2.;
	else if &b_tm2.<=RL then TL=(&b_tm2.-&b_tm1.)*&tm2.+(RL-&b_tm2.)*&tm3.;

	/*TP : taux de participation personnalisé = TF + TL*/
	TF=	(nbpc020_12=0)*((cprpf=0)*&TF_iso.+(cprpf=1)*&TF_C0.)
		+(nbpc020_12=1)*&TF_1pc.
		+(nbpc020_12=2)*&TF_2pc.
		+(nbpc020_12=3)*&TF_3pc.
		+(nbpc020_12>=4)*(&TF_4pc.-&TF_sup.*(nbpc020_12-4));

	TP=TF+TL;

	/*R : assiette de ressources arrondies au multiple de 100 € supérieurs*/
	R=ceil(BR_AL/100)*100;


	/*R0*/
    /*Depuis PLF2015, le R0 est indexé sur l'IPC HT et ne dépend plus du RSA et de la Bmaf*/
    R0=((nbpc020_12=0)*((cprpf=0)*&R0_iso.+(cprpf=1)*&R0_co.)
		+(nbpc020_12=1)*&R0_1pc.
		+(nbpc020_12>=2)*(&R0_2pc.+(nbpc020_12-2)*&R0_sup.)) ; 
		
	/*RP = R-R0*/
	RP=max(0,R-R0);

	/*P0 : participation minimale*/
	P0=max(&P0min.,0.085*(Lplf+(&C0pc.+nbpc020_12*&Csup.)));

	/*Pp : participation personnelle = P0+TP*RP*/
	Pp=P0+TP*RP/12;

	/*AL : montant des AL*/
	AL_LOC=max(0,Lplf+(&C0pc.+nbpc020_12*&Csup.)-Pp)*12;
	if AL_LOC<&seuilal.*12 then AL_LOC=0;

	/*AL_rsa : montant des AL pour les bénéficiaires du RSA*/
	AL_LOC_rsa=max(0,Lplf+(&C0pc.+nbpc020_12*&Csup.)-(P0+TP*max(0,(ceil(BR_AL_rsa/100)*100)-R0)/12))*12;
	if AL_LOC_rsa<&seuilal.*12 then AL_LOC_rsa=0;

end;

/*AL : AL pour tout le monde*/
AL=0;
if famp=1 then do;
	if logt='1' then AL=sum(m_alfm, m_alsetm,m_alsm,m_aplm); /*reprise des variables ERFS pour les accédants*/
	if logt in ('3','4','5') then AL=AL_LOC;
end;

%mend prest_fam21;

%prest_fam21;

ind_al=(al>0);
ind_al_loc=(al_loc>0);

run;



/**************************************************************************************************************************************************************/
/**************************************************************************************************************************************************************/
/*   						III.  Ajout des information sur les familles (avec limite d'âge des enfants de 21 ans) à la table individuelle     				  */
/**************************************************************************************************************************************************************/
/**************************************************************************************************************************************************************/

proc sort data=fam_prest21 ; by ident&acour. numpf21; run;
proc sort data=scenario.prest_fam21 out=prest (keep = ident&acour. numpf21 al al_loc nbpc020_12) ; by ident&acour. numpf21; run;

data scenario.indiv_prest (compress = yes drop=noi_prpf noi_cprpf pcpf21_conj famp); 
merge fam_prest21 prest; 
by ident&acour. numpf21; 
run;


proc datasets library=work;delete prest fam_prest21 fam21 ;run;quit ;

/*************************************************************************************************************************************************************
**************************************************************************************************************************************************************

Ce logiciel est régi par la licence CeCILL V2.1 soumise au droit français et respectant les principes de diffusion des logiciels libres. 

Vous pouvez utiliser, modifier et/ou redistribuer ce programme sous les conditions de la licence CeCILL V2.1. 

Le texte complet de la licence CeCILL V2.1 est dans le fichier `LICENSE`.

Les paramètres de la législation socio-fiscale figurant dans les programmes 6, 7a et 7b sont régis par la « Licence Ouverte / Open License » Version 2.0.
**************************************************************************************************************************************************************
*************************************************************************************************************************************************************/





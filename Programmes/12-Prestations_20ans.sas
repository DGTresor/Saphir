
/**************************************************************************************************************************************************************/
/*                                   								SAPHIR E2013 L2017                                       							  	  */
/*                                       								PROGRAMME 12                                        							  	  */
/*        								Création des familles et calcul des prestations dont l'age limite est < 20 ans      							  	  */
/*     								 		- tout sauf : CF, allocation forfaitaire des AF, allocations logement                 						  	  */                                  
/**************************************************************************************************************************************************************/


/**************************************************************************************************************************************************************/
/* Dans l’ERFS, les informations sont fournies à différents niveaux selon les tables. Lors de l’imputation des transferts sociaux, les familles au sens de la */
/* CAF et les foyers RSA doivent être construits au début des programmes correspondant aux prestations pour lesquelles ces unités servent de référence. Ces   */
/* constructions permettent de prendre en compte les cas où il existe plusieurs familles par ménage, mais pas ceux où une famille serait éclatée dans         */
/* plusieurs ménages. 																																		  */
/*																																							  */
/* Un travail préparatoire sur les données est réalisé afin de déterminer pour chaque individu le sexe, l’âge et l’identifiant d’éventuels conjoint, parents  */
/* ou enfants. Ces informations permettent d’idenfier les personnes à charge à la date de l’enquête au sens des prestations familiales, c’est-à-dire les 	  */
/* personnes vérifiant les conditions d’âge et de revenus d’activité inférieurs à 55 % du SMIC. 																  */
/*																																							  */
/* Ce programme recense les familles avec des enfants de moins de 20 ans et évalue les prestations qui leur sont accordées (évaluation des bases ressources   */
/* et des montants de prestation accordés (ensemble des prestations, exceptées celle calculées dans le programme 11).										  */
/**************************************************************************************************************************************************************/


/**************************************************************************************************************************************************************/
/**************************************************************************************************************************************************************/
/*               								 		I. Création des familles avec âge limite < 20 ans                   							  	  */
/**************************************************************************************************************************************************************/
/**************************************************************************************************************************************************************/


/**************************************************************************************************************************************************************/
/*				1- Détermination de la famille principale 																									  */
/**************************************************************************************************************************************************************/

%fam (tabin=scenario.indiv_prest, age=20, prest=pf, nom_unite=numpf20);


/**************************************************************************************************************************************************************/
/*				2- Informations sur les personnes à charge : date de naissance, en études 																	  */
/**************************************************************************************************************************************************************/

%pc(listvar=naia naim forter, age=20, prest=pf, nom_unite=numpf20);


/**************************************************************************************************************************************************************/
/*				3 - Informations sur l'allocataire principal et son conjoint : enceinte, a connu une séparation, salaires... 								  */
/**************************************************************************************************************************************************************/

%rename (lien=prpf, age=20, nom_unite=numpf20,
liste=sexe agenq quelfic acteu traj_acttp aac adfdap amois ancentr 
naiss_futur_a naiss_futur_m naiss_futur dv_fip ISO_FIP  SEP_EEC  elig_aah
REVACTD&asuiv4. ZCHOI&asuiv4. ZPERI&asuiv4. ZALRI&asuiv4. 
revpatm&asuiv4. zalvm&asuiv4. 
REVACTD&asuiv2. REVINDED&asuiv2. ZTSAI&asuiv2. ZCHOI&asuiv2. ZPERI&asuiv2. ZRSTI&asuiv2. ZALRI&asuiv2. ZRTOI&asuiv2. 
revpatm&asuiv2.  zalvm&asuiv2. _1AK _1AI ZSALBI&asuiv4. ZRAGbI&asuiv4. ZRICbI&asuiv4. ZRNCbI&asuiv4. ZCHOBI&asuiv4. ZRSTBI&asuiv4. ZRTOI&asuiv4.
nondic raistf dimtyp raisnrec raisnsou rabs	rabs);

%rename (lien=cprpf, age=20, nom_unite=numpf20,
liste=sexe agenq acteu traj_acttp aac adfdap amois ancentr 
naiss_futur_a naiss_futur_m naiss_futur elig_aah
REVACTD&asuiv4. ZCHOI&asuiv4. ZPERI&asuiv4. ZALRI&asuiv4. 
revpatm&asuiv4. zalvm&asuiv4. 
REVACTD&asuiv2. REVINDED&asuiv2. ZTSAI&asuiv2. ZCHOI&asuiv2. ZPERI&asuiv2. ZRSTI&asuiv2. ZALRI&asuiv2. ZRTOI&asuiv2. 
revpatm&asuiv2.  zalvm&asuiv2. _1AK _1AI ZSALBI&asuiv4. ZRAGbI&asuiv4. ZRICbI&asuiv4. ZRNCbI&asuiv4. ZCHOBI&asuiv4. ZRSTBI&asuiv4. ZRTOI&asuiv4. 
nondic raistf dimtyp raisnrec raisnsou rabs	rabs);


/**************************************************************************************************************************************************************/
/*				4- Ajout des prestations familiales avec un âge limite de 21 ans 																			  */
/**************************************************************************************************************************************************************/

proc sql ; create table prest21 as select a.*, b.numpf20  from scenario.prest_fam21 as a left join fam_prest20 as b
	on a.ident&acour.=b.ident&acour. and a.noi_prpf=b.noi order by ident&acour., numpf20; quit;

proc means data=prest21 noprint nway;
by ident&acour. numpf20;
var aforf aforf1-aforf12 cf cf1-cf12 cf_base cf_base1-cf_base12 ;
output out=prest21 (drop = _TYPE_ _FREQ_) sum=;
run;


data fam20; merge famp (in=a) prest21 pcpf prpf cprpf; by ident&acour. numpf20; if a; 
%zero(liste=cf cf1 cf2 cf3 cf4 cf5 cf6 cf7 cf8 cf9 cf10 cf11 cf12 
cf_base cf_base1 cf_base2 cf_base3 cf_base4 cf_base5 cf_base6 cf_base7 cf_base8 cf_base9 cf_base10 cf_base11 cf_base12 
aforf aforf1 aforf2 aforf3 aforf4 aforf5 aforf6 aforf7 aforf8 aforf9 aforf10 aforf11 aforf12);
run;

/**************************************************************************************************************************************************************/
/*				5- Ajout des informations sur le ménage  																									  */
/**************************************************************************************************************************************************************/

data fam20 (compress = yes); /*pour repérer l'AAH*/
merge fam20 (in=a) saphir.menage_saphir (keep= ident&acour. collm colla collj wprm&asuiv4. m_asfm m_afm m_naism m_pajem m_cfm m_arsm m_minvm m_clcam);
by ident&acour.;
if a;
run;

proc datasets library=work;delete famp pcpf prpf cprpf famp indiv_prest20 prest21;run;quit;



/**************************************************************************************************************************************************************/
/**************************************************************************************************************************************************************/
/*			           									II. Calcul des prestations familiales avec âge limite < 20 ans             							  */
/**************************************************************************************************************************************************************/
/**************************************************************************************************************************************************************/

data scenario.prest_fam20 (compress = yes);
set fam20;

%macro prest_fam20;


/**************************************************************************************************************************************************************/
/*				1- Création des variables auxiliaires 											 															  */
/**************************************************************************************************************************************************************/

/*agepci_t = âge de la ième personne à charge au tieme mois un an avant la date de collecte */
/*agepci_12 = âge de la ième personne à charge à la date de l'enquete*/

%do i=1 %to 12;	
	/*Détermination du mois et année au ieme mois */
	m&i.=collm+&i.;
	if m&i.>12 then m&i.=m&i.-12;
	if m&i.>collm then a&i.=colla-1;
	else a&i.=colla;

	/*Calcul de l'âge de la personne de référence*/
	%do j=1 %to &nb_max_pc.;
		if naia_pcpf&j. ne . & 
			((naia_pcpf&j.*12+naim_pcpf&j.<a&i.*12+m&i.) ! 
			(naia_pcpf&j.*12+naim_pcpf&j.=a&i.*12+m&i. & collj>15))
			then do;	/*attention : calculer les âges aux dates postérieures à la naissance*/
			/*âge de la personne de référence à chaque mois*/
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

/*NBPCxxyy_t : nombre de personnes à charge de XX-YY ans au mois t*/
%do i=1 %to 12;
	nbpc06m_&i.=0;      	/*0-6 mois pour CLCA / PreprarE*/
	nbpc02_&i.=0;       	/*0-2 ans*/
	nbpc4m2_&i.=0;      	/*4 mois-2 ans pour le RSA avec forfait majoré */
	nbpc2m2_&i.=0;      	/*2 mois-2 ans pour le RSA */
	nbpc019_&i.=0;      	/*0-19 ans*/
	nbpc618_&i.=0;      	/*6-18 ans pour ARS*/
	nbpc610_&i.=0;      	/*6-10 ans pour ARS*/
	nbpc1114_&i.=0;     	/*11-14 ans pour ARS*/
	nbpc1518_et_&i.=0;  	/*15-18 ans en études pour ARS*/
	nbpc1419_&i.=0;     	/*14-19 ans pour nouvelles majos*/
	nbpc_ap_av2014_&i.=0;   /*nombre de nés après le 1er avril 2014, pour la nouvelle AB de la Paje et la suppression de la majoration du CLCA*/
	%do j=1 %to &nb_max_pc.;
		if naia_pcpf&j. ne . then do; 
			if 0<=(a&i.*12+m&i.)-(naia_pcpf&j.*12+naim_pcpf&j.)-(collj<=15)<=6  then nbpc06m_&i.=nbpc06m_&i.+1; /*0-6 mois*/
			if 1<=(a&i.*12+m&i.)-(naia_pcpf&j.*12+naim_pcpf&j.)<3*12 then nbpc02_&i.=nbpc02_&i.+1;	/*0-2 ans, AB de la Paje versée à partir du 1er mois suivant 
																									le mois de naissance*/
			if 4<=(a&i.*12+m&i.)-(naia_pcpf&j.*12+naim_pcpf&j.)<3*12  then nbpc4m2_&i.=nbpc4m2_&i.+1; /*4 mois-2 ans pour le RSA avec forfait majoré (c'est le 
																										mois civil qui compte, peu importe le jour de naissance)*/
			if 2<=(a&i.*12+m&i.)-(naia_pcpf&j.*12+naim_pcpf&j.)<3*12 then nbpc2m2_&i.=nbpc2m2_&i.+1;  /*2 mois-2 ans pour le RSA (c'est le mois civil qui compte,
																									   peu importe le jour de naissance)*/
			if (14<=agepc&j._&i.<=19) then nbpc1419_&i.=nbpc1419_&i.+1;  /*14-19 ans pour les nouvelles majorations*/
			if 0<=agepc&j._&i.<=19 then nbpc019_&i.=nbpc019_&i.+1;     	 /*0-19 ans*/
			if 6<=agepc&j._&i.<=18 then nbpc618_&i.=nbpc618_&i.+1;     	 /*6-18 ans*/
			if 6<=agepc&j._&i.<=10 then nbpc610_&i.=nbpc610_&i.+1;     	 /*6-10 ans*/
			if 11<=agepc&j._&i.<=14 then nbpc1114_&i.=nbpc1114_&i.+1;  	 /*11-14 ans*/
			if agepc&j._&i.=15 ! (16<=agepc&j._&i.<=18 & forter_pcpf&j.='2') then nbpc1518_et_&i.=nbpc1518_et_&i.+1;  /*15-18 ans*/
			if ((naia_pcpf&j.=&annee_ref_paje. & naim_pcpf&j.>=4)|naia_pcpf&j.>&annee_ref_paje.) then nbpc_ap_av2014_&i.=nbpc_ap_av2014_&i.+1; /*nombre de nés après le 1er avril 2014, pour la nouvelle AB de la Paje*/
		end;
	%end;
%end;


/*NAIA_DER, NAIM_DER, ANCNAISS_DER : année de naissance, mois de naissance et ancienneté de la naissance de la dernière personne à charge*/
/*pour CLCA/PreparE*/
naia_der=max(of naia_pcpf:) ;
%macro der ; %do i=1 %to &nb_max_pc.; if naia_pcpf&i. = naia_der then do; naim_der&i.=naim_pcpf&i. ; end; %end; %mend ; %der ;
naim_der=max(of naim_der:) ;
ancnaiss_der=(colla*12+collm)-(naia_der*12+naim_der);



/*Naissance2_i : nombre d'enfants nés il y a 2 mois*/
 %do i=1 %to 12;	
	naissance2_&i.=0;
	if sexe_prpf='2' then do;
		%do k=1 %to &nb_max_pc.;
			if (a&i.*12+m&i.)-(naia_pcpf&k.*12+naim_pcpf&k.)-(collj<=15)=2  then naissance2_&i=naissance2_&i+1;
		%end;
		if naiss_futur_a_cprpf ne . & (a&i.*12+m&i.)-(naiss_futur_a_cprpf*12+naiss_futur_m_cprpf)-(collj<=15)=2 then naissance2_&i.=naissance2_&i.+1;
	end;
	if sexe_cprpf='2' then do;
		%do k=1 %to &nb_max_pc.;
			if (a&i.*12+m&i.)-(naia_pcpf&k.*12+naim_pcpf&k.)-(collj<=15)=2  then naissance2_&i=naissance2_&i+1;
		%end;
		if naiss_futur_a_cprpf ne . & (a&i.*12+m&i.)-(naiss_futur_a_cprpf*12+naiss_futur_m_cprpf)-(collj<=15)=2 then naissance2_&i.=naissance2_&i.+1;
	end;
%end;

/*PRPF, CPRPF*/
prpf=(noi_prpf ne ' ');
cprpf=(noi_cprpf ne ' ');

/*ACT_PRPF, ACT_CPRPF : statut d'activité pour déterminer la biactivité*/
act_prpf=(revactd&asuiv2._prpf>=&seuil_biact.);
act_cprpf=(revactd&asuiv2._cprpf>=&seuil_biact.);


/**************************************************************************************************************************************************************/
/*				2- Création de la variable BR_PF : base ressources servant au calcul des prestations familiales en annuel	 								  */
/**************************************************************************************************************************************************************/

/**************************************************************************************************************************************************************/
/* = RNC - abattements et déductions																														  */
/* Revenu net catégoriel (Rnc) = ressources nettes perçues - abattements fiscaux propres à chaque catégorie de revenus										  */
/**************************************************************************************************************************************************************/

/**************************************************************************************************************************************************************/
/* BR_PF = somme des revenus nets catégoriels après déduction :    																							  */
/* 			- des pensions alimentaires versées                            																					  */
/* 			- de la csg sur les revenus du patrimoine                      																					  */
/**************************************************************************************************************************************************************/

BR_PF=0;

array tsal (2) ztsai&asuiv2._prpf ztsai&asuiv2._cprpf ;
array ak (2) _1ak_prpf _1ak_cprpf ;
array ai (2) _1ai_prpf _1ai_cprpf ;

array rst (2) zrsti&asuiv2._prpf zrsti&asuiv2._cprpf ;
array alr (2) zalri&asuiv2._prpf zalri&asuiv2._cprpf ;
array rto (2) zrtoi&asuiv2._prpf zrtoi&asuiv2._cprpf ;

array revinded (2) revinded&asuiv2._prpf revinded&asuiv2._cprpf ;

array revpatm (2) revpatm&asuiv2._prpf revpatm&asuiv2._cprpf ;

array alv (2) zalvm&asuiv2._prpf zalvm&asuiv2._cprpf ;


do i=1 to 2;
	BR_PF=sum(BR_PF,
			/*Salaires et traitements*/
			tsal(i),
			-(tsal(i)>0)*max(min(max(min(tsal(i)*0.1,&abat_tsal_max.),(ai(i)=0)*&abat_tsal_min.+(ai(i)=1)*&abat_tsal_min_cho.),tsal(i)),ak(i)),			
			/*Pensions*/
			sum(rst(i),alr(i),rto(i)),
			-(sum(rst(i),alr(i),rto(i))>0)*min(max(min(sum(rst(i),alr(i),rto(i))*0.1,&abat_pens_max.),&abat_pens_min.),sum(rst(i),alr(i),rto(i))),
			/*Revenus non salariés*/
			revinded(i),	
			/*Revenus du patrimoine*/
			revpatm(i),	
			/*Déduction des pensions alimentaires versées*/
			- alv(i)
		);
end;

drop i;


/**************************************************************************************************************************************************************/
/*				3- Calcul des prestations familiales 																										  */
/**************************************************************************************************************************************************************/

/**************************************************************************************************************************************************************/
/*		a. Allocation de soutien familial (ASF)																					 		                      */
/**************************************************************************************************************************************************************/

/*On se restreint aux cas des personnes sans conjoint, avec enfant de moins de 20 ans et qui ont coché la case T de la déclaration fiscale*/

asf=0;

		/** Cas 1 - Pas de pensions versées **/
    if zalri&asuiv4._prpf=0 then do;
    	%do i=1 %to 12;
    		asf&i.=0;
			asf_sans_revalo&i.=0;
    		if nbpc019_&i.>0 & cprpf=0 & m_asfm>0 then do;
    			asf&i.=nbpc019_&i.*&tauxasf.*&&bmaf&asuiv4.*(1-&&tx_crds&asuiv4.);
				asf_sans_revalo&i.=nbpc019_&i.*&tauxasf_sans_revalo.*&&bmaf&asuiv4.*(1-&&tx_crds&asuiv4.);
				end;
    	%end;
    end;

 		/** Cas 2 - Pensions et ASF versées **/
    else if m_asfm>0 then do;
    	nb_asf=m_asfm/&montant_asf_erfs.;		/*nombre de mois d'ASF : on divise par le montant de l'ASF de l'année de l'ERFS*/
    	nb_enfant=sum(of nbpc019_1-nbpc019_12);	/*nombre de personnes à charge sur l'année*/
    	nb_enf_hasf=(nb_enfant-nb_asf)/12;		/*y a-t-il des enfants hors ASF sur l'année*/
    	/*Nombre d'enfants à peu près entier => X enfants à l'ASF, Y à la pension alimentaire*/
    	if (abs(nb_enf_hasf-round(nb_enf_hasf))<0.02) then do;
    		%do i=1 %to 12;
    			asf&i.=0;
				asf_sans_revalo&i.=0;
    			asf&i.=(nbpc019_&i.-nb_enf_hasf)*&tauxasf.*&&bmaf&asuiv4.*(1-&&tx_crds&asuiv4.);
    			asf_sans_revalo&i.=(nbpc019_&i.-nb_enf_hasf)*&tauxasf_sans_revalo.*&&bmaf&asuiv4.*(1-&&tx_crds&asuiv4.);
    		%end;
    	end;
    	else do;
		    %do i=1 %to 12;
    			asf&i.=nb_asf/12*&tauxasf.*&&bmaf&asuiv4.*(1-&&tx_crds&asuiv4.);
				asf_sans_revalo&i.=nb_asf/12*&tauxasf_sans_revalo.*&&bmaf&asuiv4.*(1-&&tx_crds&asuiv4.);
    		%end;
    	end;
    end;

		/** Cas 3 - Ni ASF ni pension : non éligible **/
    else do;
    	%do i=1 %to 12;
    		asf&i.=0;
            asf_sans_revalo&i.=0;
    	%end;
end;
asf=sum(of asf1-asf12);


/**************************************************************************************************************************************************************/
/*		b. Allocation familiales (AF)																							 		                      */
/**************************************************************************************************************************************************************/

/*AFSSMAJi : allocations familiales sans majoration au mois i*/
afssmaj=0;
%do i=1 %to 12;	
	afssmaj&i.=0;
	afssmaj&i.=	((BR_PF<=(&borne1_AF. + nbpc019_&i.*&borne_AF_majo.))*(nbpc019_&i.>=2)*(&tauxAF2.+(nbpc019_&i.-2)*&tauxAF_sup.)+
				((&borne1_AF. + nbpc019_&i.*&borne_AF_majo.)<BR_PF<=(&borne2_AF. + nbpc019_&i.*&borne_AF_majo.))*(nbpc019_&i.>=2)*(%sysevalf(&tauxAF2./2)+(nbpc019_&i.-2)*%sysevalf(&tauxAF_sup./2))+
				(BR_PF>(&borne2_AF. + nbpc019_&i.*&borne_AF_majo.))*(nbpc019_&i.>=2)*(%sysevalf(&tauxAF2./4)+(nbpc019_&i.-2)*%sysevalf(&tauxAF_sup./4)))
				*&&bmaf&asuiv4.*(1-&&tx_crds&asuiv4.) ;
%end;
afssmaj=sum(of afssmaj1-afssmaj12);

/*MAJAFi : majoration pour age des AF*/ 
/*NB : s'il y a 2 enfants, il n'y a pas de majoration pour le plus agé*/
majaf=0;
%do i=1 %to 12;	
	majaf&i.=0;
	majaf&i.= ((BR_PF<=(&borne1_AF. + nbpc019_&i.*&borne_AF_majo.))*((nbpc019_&i.=2)*((nbpc1419_&i.=2)*&tx_maj_1419.)+(nbpc019_&i.>2)*(nbpc1419_&i.*&tx_maj_1419.)) +
			  ((&borne1_AF. + nbpc019_&i.*&borne_AF_majo.)<BR_PF<=(&borne2_AF. + nbpc019_&i.*&borne_AF_majo.))*((nbpc019_&i.=2)*((nbpc1419_&i.=2)*&tx_maj_1419./2)+(nbpc019_&i.>2)*(nbpc1419_&i.*&tx_maj_1419./2)) +
			  (BR_PF>(&borne2_AF. + nbpc019_&i.*&borne_AF_majo.))*((nbpc019_&i.=2)*((nbpc1419_&i.=2)*&tx_maj_1419./4)+(nbpc019_&i.>2)*(nbpc1419_&i.*&tx_maj_1419./4)))
				*&&bmaf&asuiv4.*(1-&&tx_crds&asuiv4.);
%end;
majaf=sum(of majaf1-majaf12);


/*AF : allocations familiales, y compris majoration et forfait*/
%do i=1 %to 12;	
	af&i.=afssmaj&i.+majaf&i.+aforf&i.;
	   /*Complément dégressif en cas de faible dépassement d'un des plafonds*/
    if (&borne2_AF. + nbpc019_&i.*&borne_AF_majo.)<BR_PF & sum(BR_PF, - (&borne2_AF. + nbpc019_&i.*&borne_AF_majo.))<12*(afssmaj&i.+majaf&i.) 
    then af&i.=sum(af&i., sum((&borne2_AF. + nbpc019_&i.*&borne_AF_majo.),12*(afssmaj&i.+majaf&i.) ,-BR_PF)/12);
    else if (&borne1_AF. + nbpc019_&i.*&borne_AF_majo.)<BR_PF & sum(BR_PF, - (&borne1_AF. + nbpc019_&i.*&borne_AF_majo.))<12*(afssmaj&i.+majaf&i.) 
    then af&i.=sum(af&i., sum((&borne1_AF. + nbpc019_&i.*&borne_AF_majo.),12*(afssmaj&i.+majaf&i.) ,-BR_PF)/12);

%end;
af=sum(of af1-af12);


/**************************************************************************************************************************************************************/
/*		c. Prestation d'accueil du jeune enfant (PAJE)																			 		                      */
/**************************************************************************************************************************************************************/

		/** Prime de naissance de la Paje (PN_PAJE) **/

/*Versée au 2e mois après la naissance*/
/*Les enfants à naitre sont pris en compte dans l'évaluation des conditions de ressources*/
pn_paje=0;
%do i=1 %to 12;	
	pn_paje&i.=0;
	pn_paje&i.=naissance2_&i.*&taux_pnpaje.*&bmaf13.*(1-&&tx_crds&asuiv4.)* /*Gel jusqu'à convergence vers le CF */
	((prpf+cprpf=2 & act_prpf+act_cprpf<=1 & BR_PF<(&plaf_paje_m1_partiel.*((nbpc019_&i.+naissance2_&i.)=1)+&plaf_paje_m2_partiel.*((nbpc019_&i.+naissance2_&i.)>=2)+&plaf_paje_sup_partiel.*max(0,nbpc019_&i.+naissance2_&i.-2))) 
	!((act_prpf+act_cprpf=2 ! prpf+cprpf=1) & BR_PF<(&plaf_paje_1_partiel.*((nbpc019_&i.+naissance2_&i.)=1)+&plaf_paje_2_partiel.*((nbpc019_&i.+naissance2_&i.)>=2)+&plaf_paje_sup_partiel.*max(0,nbpc019_&i.+naissance2_&i.-2))));
%end;
pn_paje=sum(of pn_paje1-pn_paje12);


		/** Allocation de base de la Paje (AB_PAJE) **/

/*Versé du mois suivant la naissance au mois précédant 3 ans*/
/*Une seule prestation par famille*/
ab_paje=0;
%do i=1 %to 12;	
	ab_paje&i.=0;
	ab_paje&i.= (nbpc02_&i.>0)*&taux_abpaje.*&bmaf13.*(1-&&tx_crds&asuiv4.)* /*gel jusqu'à convergence vers le CF */
	((nbpc_ap_av2014_&i.=0)*
	((prpf+cprpf=2 & act_prpf+act_cprpf<=1 & BR_PF<(&plaf_paje_m1_old.*(nbpc019_&i.=1)+&plaf_paje_m2_old.*(nbpc019_&i.>=2)+&plaf_paje_sup_old.*(nbpc019_&i.>2)*(nbpc019_&i.-2))) 
	! ((act_prpf+act_cprpf=2 ! prpf+cprpf=1) & BR_PF<(&plaf_paje_1_old.*(nbpc019_&i.=1)+&plaf_paje_2_old.*(nbpc019_&i.>=2)+&plaf_paje_sup_old.*(nbpc019_&i.>2)*(nbpc019_&i.-2))))

	+(nbpc_ap_av2014_&i.>0)*
	((prpf+cprpf=2 & act_prpf+act_cprpf<=1 & BR_PF<(&plaf_paje_m1_partiel.*(nbpc019_&i.=1)+&plaf_paje_m2_partiel.*(nbpc019_&i.>=2)+&plaf_paje_sup_partiel.*(nbpc019_&i.>2)*(nbpc019_&i.-2)))
	! ((act_prpf+act_cprpf=2 ! prpf+cprpf=1) & BR_PF<(&plaf_paje_1_partiel.*(nbpc019_&i.=1)+&plaf_paje_2_partiel.*(nbpc019_&i.>=2)+&plaf_paje_sup_partiel.*(nbpc019_&i.>2)*(nbpc019_&i.-2))))
	*(1-0.5*((prpf+cprpf=2 & act_prpf+act_cprpf<=1 & BR_PF>(&plaf_paje_m1.*(nbpc019_&i.=1)+&plaf_paje_m2.*(nbpc019_&i.>=2)+&plaf_paje_sup.*(nbpc019_&i.>2)*(nbpc019_&i.-2))) 
	! ((act_prpf+act_cprpf=2 ! prpf+cprpf=1) & BR_PF>(&plaf_paje_1.*(nbpc019_&i.=1)+&plaf_paje_2.*(nbpc019_&i.>=2)+&plaf_paje_sup.*(nbpc019_&i.>2)*(nbpc019_&i.-2)))))
	);

%end;
ab_paje=sum(of ab_paje1-ab_paje12);

/*ab_paje_rsa : allocation de base de la Paje pour le calcul du RSA (sans le premier mois)*/
ab_paje_rsa=0;
%do i=1 %to 12;	
	ab_paje_rsa&i.=0;
	ab_paje_rsa&i.= (nbpc2m2_&i.>0)*&taux_abpaje.*&bmaf13.*(1-&&tx_crds&asuiv4.)* /*Gel jusqu'à convergence vers le CF */
	((nbpc_ap_av2014_&i.=0)*
	((prpf+cprpf=2 & act_prpf+act_cprpf<=1 & BR_PF<(&plaf_paje_m1_old.*(nbpc019_&i.=1)+&plaf_paje_m2_old.*(nbpc019_&i.>=2)+&plaf_paje_sup_old.*(nbpc019_&i.>2)*(nbpc019_&i.-2))) 
	! ((act_prpf+act_cprpf=2 ! prpf+cprpf=1) & BR_PF<(&plaf_paje_1_old.*(nbpc019_&i.=1)+&plaf_paje_2_old.*(nbpc019_&i.>=2)+&plaf_paje_sup_old.*(nbpc019_&i.>2)*(nbpc019_&i.-2))))

	+(nbpc_ap_av2014_&i.>0)*
	((prpf+cprpf=2 & act_prpf+act_cprpf<=1 & BR_PF<(&plaf_paje_m1_partiel.*(nbpc019_&i.=1)+&plaf_paje_m2_partiel.*(nbpc019_&i.>=2)+&plaf_paje_sup_partiel.*(nbpc019_&i.>2)*(nbpc019_&i.-2)))
	! ((act_prpf+act_cprpf=2 ! prpf+cprpf=1) & BR_PF<(&plaf_paje_1_partiel.*(nbpc019_&i.=1)+&plaf_paje_2_partiel.*(nbpc019_&i.>=2)+&plaf_paje_sup_partiel.*(nbpc019_&i.>2)*(nbpc019_&i.-2))))
	*(1-0.5*((prpf+cprpf=2 & act_prpf+act_cprpf<=1 & BR_PF>(&plaf_paje_m1.*(nbpc019_&i.=1)+&plaf_paje_m2.*(nbpc019_&i.>=2)+&plaf_paje_sup.*(nbpc019_&i.>2)*(nbpc019_&i.-2))) 
	! ((act_prpf+act_cprpf=2 ! prpf+cprpf=1) & BR_PF>(&plaf_paje_1.*(nbpc019_&i.=1)+&plaf_paje_2.*(nbpc019_&i.>=2)+&plaf_paje_sup.*(nbpc019_&i.>2)*(nbpc019_&i.-2)))))
	);

%end;
ab_paje_rsa=sum(of ab_paje_rsa1-ab_paje_rsa12);

/*ab_paje_rsa_maj : allocation de base de la Paje pour le calcul du RSA majoré (sans les 3 premiers mois)*/
ab_paje_rsa_maj=0;
%do i=1 %to 12;	
	ab_paje_rsa_maj&i.=0; 
	ab_paje_rsa_maj&i.= (nbpc4m2_&i.>0)*&taux_abpaje.*&bmaf13.*(1-&&tx_crds&asuiv4.)* /*gel jusqu'à convergence vers le CF */
	((nbpc_ap_av2014_&i.=0)*
	((prpf+cprpf=2 & act_prpf+act_cprpf<=1 & BR_PF<(&plaf_paje_m1_old.*(nbpc019_&i.=1)+&plaf_paje_m2_old.*(nbpc019_&i.>=2)+&plaf_paje_sup_old.*(nbpc019_&i.>2)*(nbpc019_&i.-2))) 
	! ((act_prpf+act_cprpf=2 ! prpf+cprpf=1) & BR_PF<(&plaf_paje_1_old.*(nbpc019_&i.=1)+&plaf_paje_2_old.*(nbpc019_&i.>=2)+&plaf_paje_sup_old.*(nbpc019_&i.>2)*(nbpc019_&i.-2))))

	+(nbpc_ap_av2014_&i.>0)*
	((prpf+cprpf=2 & act_prpf+act_cprpf<=1 & BR_PF<(&plaf_paje_m1_partiel.*(nbpc019_&i.=1)+&plaf_paje_m2_partiel.*(nbpc019_&i.>=2)+&plaf_paje_sup_partiel.*(nbpc019_&i.>2)*(nbpc019_&i.-2)))
	! ((act_prpf+act_cprpf=2 ! prpf+cprpf=1) & BR_PF<(&plaf_paje_1_partiel.*(nbpc019_&i.=1)+&plaf_paje_2_partiel.*(nbpc019_&i.>=2)+&plaf_paje_sup_partiel.*(nbpc019_&i.>2)*(nbpc019_&i.-2))))
	*(1-0.5*((prpf+cprpf=2 & act_prpf+act_cprpf<=1 & BR_PF>(&plaf_paje_m1.*(nbpc019_&i.=1)+&plaf_paje_m2.*(nbpc019_&i.>=2)+&plaf_paje_sup.*(nbpc019_&i.>2)*(nbpc019_&i.-2))) 
	! ((act_prpf+act_cprpf=2 ! prpf+cprpf=1) & BR_PF>(&plaf_paje_1.*(nbpc019_&i.=1)+&plaf_paje_2.*(nbpc019_&i.>=2)+&plaf_paje_sup.*(nbpc019_&i.>2)*(nbpc019_&i.-2)))))
	);

%end;
ab_paje_rsa_maj=sum(of ab_paje_rsa_maj1-ab_paje_rsa_maj12);


/**************************************************************************************************************************************************************/
/*		d. Complément libre choix d activité (CLCA)/PreparE																		 		                      */
/**************************************************************************************************************************************************************/

		/** Variables auxiliaires pour CLCA / PreparE **/

/*condact_clca : conditions de durée travaillée avant la naissance du dernier enfant */
if sexe_prpf='2' then do;
	if acteu_prpf='1' then condact_clca=(max(0,ancentr_prpf-(ancnaiss_der))>=24);

	if acteu_prpf='3' then do; 
		if nbpc019_12=1 then condact_clca=((naim_der+12*naia_der)-(adfdap_prpf*12+amois_prpf)<=0);
		if nbpc019_12=2 then condact_clca=((naim_der+12*naia_der)-(adfdap_prpf*12+amois_prpf)<=24);
		if nbpc019_12>=3 then condact_clca=((naim_der+12*naia_der)-(adfdap_prpf*12+amois_prpf)<=36);
	end;
end;
if sexe_cprpf='2' then do;
	if acteu_cprpf='1' then condact_clca=(max(0,ancentr_cprpf-(ancnaiss_der))>=24);

	if acteu_cprpf='3' then do;
		if nbpc019_12=1 then condact_clca=((naim_der+12*naia_der)-(adfdap_cprpf*12+amois_cprpf)<=0);
		if nbpc019_12=2 then condact_clca=((naim_der+12*naia_der)-(adfdap_cprpf*12+amois_cprpf)<=24);
		if nbpc019_12>=3 then condact_clca=((naim_der+12*naia_der)-(adfdap_cprpf*12+amois_cprpf)<=36);
	end;
end;

if sexe_prpf='2' then cond_supplementaire=(
	nondic_prpf='3' ! 		/*non disponibilité pour travailler dans un délai de 2 semaines pour garder des enfants*/
	raistf_prpf='2' ! 		/*temps partiel pour s'occuper des enfants ou d'une personne dépendante*/
	dimtyp_prpf='2' ! 		/*réduction d'horaires pour maternité*/
	raisnrec_prpf ='3' ! 	/*non recherche d'emploi pour garde d'enfants ou d'une personne dépendante*/
	raisnsou_prpf ='2' ! 	/*ne souhaite pas travailler car s'occupe des enfants ou d'une personne dépendante*/
	rabs_prpf ='3' ! 		/*congé maternité*/
	rabs_prpf ='5'); 		/*congé parental*/
if sexe_cprpf='2' then cond_supplementaire=(
	nondic_cprpf='3' !		/*non disponibilité pour travailler dans un délai de 2 semaines pour garder des enfants*/
	raistf_cprpf='2' ! 		/*temps partiel pour s'occuper des enfants ou d'une personne dépendante*/
	dimtyp_cprpf='2' ! 		/*réduction d'horaires pour maternité*/
	raisnrec_cprpf ='3' ! 	/*non recherche d'emploi pour garde d'enfants ou d'une personne dépendante*/
	raisnsou_cprpf ='2' ! 	/*ne souhaite pas travailler car s'occupe des enfants ou d'une personne dépendante*/
	rabs_cprpf ='3' ! 		/*congé maternité*/
	rabs_cprpf ='5'); 		/*congé parental*/

%do i=1 %to 12;
	/*CONDNAISS_CLCAi : condition sur la naissance de l'enfant au mois i*/
	/*Au moins un enfant de moins de 3 ans ou un seul enfant et moins de 6 mois*/
	condnaiss_clca&i.=((nbpc019_&i.=1 & nbpc06m_&i.=1) ! (nbpc019_&i.>=2 & nbpc02_&i.>=1)); 

	/*CONDRED_CLCAi : condition sur le fait d'avoir une activité réduite ou absente (inactivité) au mois i*/
	if sexe_prpf='2' then condred_clca&i.=(substr(traj_acttp_prpf,&i.,1) in('1','2','5'));
	if sexe_cprpf='2' then condred_clca&i.=(substr(traj_acttp_cprpf,&i.,1) in('1','2','5'));

	/*ELIG_CLCAi : éligibilité au CLCA / PreparE au mois i*/
	elig_clca&i.=(condnaiss_clca&i.=1 & (condact_clca=1 ! m_clcam>0) & condred_clca&i.=1 & cond_supplementaire);
	
	/*CLCAi : montant de CLCA / PreparE au mois i*/
	clca&i.=0;

	if elig_clca&i.=1 then do;
        if sexe_prpf='2' then do;
			if substr(traj_acttp_prpf,&i.,1)='5' then clca&i.=max(0,(&taux_clca_plein.+(ab_paje&i.=0)*(nbpc_ap_av2014_&i.=0)*&taux_ABPAJE.)*&&bmaf&asuiv4.*(1-&&tx_crds&asuiv4.)); 
			else if substr(traj_acttp_prpf,&i.,1)='1' then clca&i.=max(0,(&taux_clca_50.+(ab_paje&i.=0)*(nbpc_ap_av2014_&i.=0)*&taux_ABPAJE.)*&&bmaf&asuiv4.*(1-&&tx_crds&asuiv4.)); 
			else if substr(traj_acttp_prpf,&i.,1)='2' then clca&i.=max(0,(&taux_clca_80.+(ab_paje&i.=0)*(nbpc_ap_av2014_&i.=0)*&taux_ABPAJE.)*&&bmaf&asuiv4.*(1-&&tx_crds&asuiv4.)); 
        end;
	    if sexe_cprpf='2' then do;
			if substr(traj_acttp_cprpf,&i.,1)='5' then clca&i.=max(0,(&taux_clca_plein.+(ab_paje&i.=0)*(nbpc_ap_av2014_&i.=0)*&taux_ABPAJE.)*&&bmaf&asuiv4.*(1-&&tx_crds&asuiv4.)); 
			else if substr(traj_acttp_cprpf,&i.,1)='1' then clca&i.=max(0,(&taux_clca_50.+(ab_paje&i.=0)*(nbpc_ap_av2014_&i.=0)*&taux_ABPAJE.)*&&bmaf&asuiv4.*(1-&&tx_crds&asuiv4.)); 
			else if substr(traj_acttp_cprpf,&i.,1)='2' then clca&i.=max(0,(&taux_clca_80.+(ab_paje&i.=0)*(nbpc_ap_av2014_&i.=0)*&taux_ABPAJE.)*&&bmaf&asuiv4.*(1-&&tx_crds&asuiv4.)); 
	    end;
	end;
%end;
clca=sum(of clca1-clca12);


/**************************************************************************************************************************************************************/
/*		e. Allocation de rentrée scolaire (ARS)																					 		                      */
/**************************************************************************************************************************************************************/

ars=0;
%do i=1 %to 12;	
	if m&i.=9 then 
		ars=min(
			(nbpc610_&i.*&taux_ars_6_10.+nbpc1114_&i.*&taux_ars_11_14.+nbpc1518_et_&i.*&taux_ars_15_18.)*&&bmaf&asuiv4. *(1-&&tx_crds&asuiv4.),
			max((&plaf_ars_1.+&plaf_ars_sup.*(nbpc019_&i.-1)+ (nbpc610_&i.*&taux_ars_6_10.+nbpc1114_&i.*&taux_ars_11_14.+nbpc1518_et_&i.*&taux_ars_15_18.)*&&bmaf&asuiv4.*(1-&&tx_crds&asuiv4.) -BR_PF), 0));

%end;


/**************************************************************************************************************************************************************/
/*		f. Complément familial (CF)																					 		                     			  */
/**************************************************************************************************************************************************************/

/*Mise à 0 en cas de perception de la Paje ou du CLCA / PreparE*/
%do i=1 %to 12;	
	if ab_paje&i.>0 ! clca&i.>0 then do;
       cf_base&i.=0 ;
	   cf_majo&i.=0 ;
	   cf&i.=0;
	end;
%end;
cf=sum(of cf1-cf12);
cf_base=sum(of cf_base1-cf_base12); /*pour le calcul de la base ressource du RSA*/


/**************************************************************************************************************************************************************/
/*				3- Calcul des minima sociaux (hors RSA) 																									  */
/**************************************************************************************************************************************************************/

/*ELIG_MINVI*/
elig_minvi_prpf=(agenq_prpf>=65 ! (agenq_prpf>=62 & elig_aah_prpf=1));
elig_minvi_cprpf=(agenq_cprpf>=65 ! (agenq_cprpf>=62 & elig_aah_cprpf=1));


/**************************************************************************************************************************************************************/
/*		a. Minimum vieillesse (ASPA) (MINVI)																		 		                     			  */
/**************************************************************************************************************************************************************/

/**************************************************************************************************************************************************************/
/* BR_MINVI																																					  */
/* Base ressources : salaires bruts et des revenus des indépendants déclarés hors abattements (R815-22 et R815-24 du CSS)									  */
/* Ajout de l'abattement sur revenus professionnels																											  */
/* Suppression des pensions alimentaires versées																											  */
/**************************************************************************************************************************************************************/

abattement=0;
if cprpf=0 & elig_minvi_prpf=1 then do ; abattement=&abat_celib.;  end;
if cprpf=1 & elig_minvi_prpf=1  then do; abattement=&abat_couple.; end;

BR_MINVI=max(0,
sum(max(0,sum(zsalbi&asuiv4._prpf, zragbi&asuiv4._prpf, zricbi&asuiv4._prpf, zrncbi&asuiv4._prpf,- abattement)), 
	zchobi&asuiv4._prpf, zrstbi&asuiv4._prpf, zalri&asuiv4._prpf,zrtoi&asuiv4._prpf, revpatm&asuiv4._prpf,
	max(0,sum(zsalbi&asuiv4._cprpf, zragbi&asuiv4._cprpf, zricbi&asuiv4._cprpf, zrncbi&asuiv4._cprpf,- abattement)), 
	zchobi&asuiv4._cprpf,zrstbi&asuiv4._cprpf,zalri&asuiv4._cprpf,zrtoi&asuiv4._cprpf, revpatm&asuiv4._cprpf)); 

/*MINVI*/
minvi_prpf=0;
minvi_cprpf=0;
if cprpf=0 & elig_minvi_prpf=1 then do; /*Personne seule*/
	minvi_prpf=min(&minvi_1p.,max(0,&plaf_minvi_1p.-BR_MINVI));
end;
else if cprpf=1 then do; /*couple*/
	if elig_minvi_prpf=1 & elig_minvi_cprpf=0 then do; /*Seule PRPF eligible*/
		minvi_prpf=min(&minvi_1p.,max(0,&plaf_minvi_2p.-BR_MINVI));
	end;
	if elig_minvi_prpf=0 & elig_minvi_cprpf=1 then do; /*Seule CPRPF eligible*/
		minvi_cprpf=min(&minvi_1p.,max(0,&plaf_minvi_2p.-BR_MINVI));
	end;
	if elig_minvi_prpf=1 & elig_minvi_cprpf=1 then do; /*Les 2 eligibles*/
		minvi_prpf=min(&minvi_2p.,max(0,&plaf_minvi_2p.-BR_MINVI))/2;
		minvi_cprpf=min(&minvi_2p.,max(0,&plaf_minvi_2p.-BR_MINVI))/2;
	end;
end;
minvi=minvi_prpf+minvi_cprpf;


/**************************************************************************************************************************************************************/
/*		b. Allocation aux adultes handicapés (AAH)																	 		                     			  */
/**************************************************************************************************************************************************************/

BR_AAH=0.7*BR_PF; 
do i=1 to 2; 
BR_AAH=sum(BR_AAH,
			- rto(i) /*(supposées dans le cadre d'un contrat de "rente survie" ou d"épargne handicap" ouvrant droit à réduction d'impôt)*/
			);
end;


/*Pour l'eligibilité, on ne se base que sur les déclarations EEC*/
AAH_PRPF=0;
AAH_CPRPF=0;
if cprpf=0 & elig_aah_prpf=1 then do; 							/*personne seule*/
	aah_prpf=max(min(&aah.,max(0,(&plaf_aah_1p.+nbpc019_12*&plaf_aah_sup.)-BR_AAH))-minvi_prpf,0);
end;
else if cprpf=1 & (elig_aah_prpf=1 ! elig_aah_cprpf=1) then do;	/*couple*/
	if elig_aah_prpf=1 then aah_prpf=max(min(&aah.,max(0,(&plaf_aah_2p.+nbpc019_12*&plaf_aah_sup.)-BR_AAH))-minvi_prpf,0);
	if elig_aah_cprpf=1 then aah_cprpf=max(min(&aah.,max(0,(&plaf_aah_2p.+nbpc019_12*&plaf_aah_sup.)-BR_AAH))-minvi_cprpf,0);
end;

aah=aah_prpf+aah_cprpf;

/*Trimestrialisation des prestations familiales mensualisées*/
%let liste=(afssmaj asf asf_sans_revalo majaf clca ab_paje_rsa ab_paje_rsa_maj ab_paje cf cf_base);

%let i=1;
%do %while(%index(&liste.,%scan(&liste.,&i.))>0);
	%let var=%scan(&liste.,&i.);

	&var._t1=&var.1+&var.2+&var.3;
	&var._t2=&var.4+&var.5+&var.6;
	&var._t3=&var.7+&var.8+&var.9;
	&var._t4=&var.10+&var.11+&var.12;

	%let i=%eval(&i.+1);
%end;

%mend prest_fam20;
%prest_fam20;

run;


/**************************************************************************************************************************************************************/
/**************************************************************************************************************************************************************/
/*   					III - Ajout des informations sur les familles (avec limite d'âge des enfants de 20 ans) à la table individuelle   				 	  */
/**************************************************************************************************************************************************************/
/**************************************************************************************************************************************************************/


/**************************************************************************************************************************************************************/
/*				1- Individualisation des prestations individualisables 																						  */
/**************************************************************************************************************************************************************/

/**************************************************************************************************************************************************************/
/*		a. AAH et MINVI																								 		                     			  */
/**************************************************************************************************************************************************************/

data aah_minvi;
set scenario.prest_fam20 (keep = ident&acour. aah_prpf minvi_prpf noi_prpf rename=(aah_prpf=aah_ind  minvi_prpf=minvi_ind noi_prpf=noi))
	scenario.prest_fam20 (keep = ident&acour. aah_cprpf minvi_cprpf noi_cprpf rename=(aah_cprpf=aah_ind  minvi_cprpf=minvi_ind noi_cprpf=noi));
if noi=' ' then delete;
run;

proc sort data=aah_minvi; by ident&acour. noi; run;


/**************************************************************************************************************************************************************/
/*		b. CLCA/PreparE																								 		                     			  */
/**************************************************************************************************************************************************************/

data clca (keep = ident&acour. noi clca_ind clca12_ind );
set scenario.prest_fam20 (rename=(clca=clca_ind clca12=clca12_ind ));
if sexe_prpf='2' then noi=noi_prpf; else noi=noi_cprpf;
if noi=' ' then delete;
run;

proc sort data=clca; by ident&acour. noi; run;


/**************************************************************************************************************************************************************/
/*		c. Mise en commun																							 		                     			  */
/**************************************************************************************************************************************************************/

proc sort data=fam_prest20; by ident&acour. noi; run ;
data scenario.indiv_prest; 
merge fam_prest20 aah_minvi clca; 
by ident&acour. noi; 

if minvi_ind=. then minvi_ind=0;
if aah_ind=. then aah_ind=0;
if clca_ind=. then clca_ind=0;
if clca12_ind=. then clca12_ind=0;

run;


/**************************************************************************************************************************************************************/
/*				2- Montant de la prestation de la famille à laquelle appartient l'individu																	  */
/**************************************************************************************************************************************************************/

proc sort data=scenario.indiv_prest ; by ident&acour. numpf20; run;
proc sort data=scenario.prest_fam20 
out=prest (keep = ident&acour. numpf20 asf afssmaj majaf aforf af ab_paje pn_paje clca cf cf_base ars aah minvi) ; by ident&acour. numpf20; run;

data scenario.indiv_prest (compress = yes drop=noi_prpf noi_cprpf pcpf20_conj famp); 
merge scenario.indiv_prest prest; 
by ident&acour. numpf20; 
run;

proc datasets library=work; delete prest fam20 fam_prest20 aah_minvi clca; run; quit;

/*************************************************************************************************************************************************************
**************************************************************************************************************************************************************

Ce logiciel est régi par la licence CeCILL V2.1 soumise au droit français et respectant les principes de diffusion des logiciels libres. 

Vous pouvez utiliser, modifier et/ou redistribuer ce programme sous les conditions de la licence CeCILL V2.1. 

Le texte complet de la licence CeCILL V2.1 est dans le fichier `LICENSE`.

Les paramètres de la législation socio-fiscale figurant dans les programmes 6, 7a et 7b sont régis par la « Licence Ouverte / Open License » Version 2.0.
**************************************************************************************************************************************************************
*************************************************************************************************************************************************************/



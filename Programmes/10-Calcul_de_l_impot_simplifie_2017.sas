

/**************************************************************************************************************************************************************/
/*                                   									SAPHIR E2013 L2017                                       							  */
/*                                        									PROGRAMME 10                                        							  */
/*               									Reconstitution des déclarations fiscales quand échec appariement             							  */
/*                              									et calcul de l'impot simplifié                                							  */
/**************************************************************************************************************************************************************/


/**************************************************************************************************************************************************************/
/* Ce programme sert à calculer l'impôt en cas de revenus fiscaux manquants. Deux cas peuvent expliquer l'absence de revenus fiscaux :						  */
/* 			- les ménages pour lesquels aucune déclaration fiscale n’a été retrouvée mais qui ont été retrouvés dans les données sociales ;				  	  */
/*			- les ménages pour lesquels une partie des déclarations fiscales est manquante, soit en cas de changement situation familiale, soit lorsque le	  */  
/*			  ménage est constitué de plusieurs foyers fiscaux et que l’ensemble des déclarations n’a pas été retrouvé.										  */
/*																																							  */
/* Les principales étapes du programmes sont :																												  */
/* 			- identification des individus qui relèvent du champ de l’impôt simplifié ;																		  */
/*			- reconstruction des foyers fiscaux en incluant les personnes qui ne sont rattachées à aucune déclaration fiscale ;								  */
/*			- calcul de l'impôt dû à partir des montants de revenus imputés dans l’ERFS et d’un barème simplifié, sans crédit ni réduction d’impôt. 		  */
/**************************************************************************************************************************************************************/


/**************************************************************************************************************************************************************/
/**************************************************************************************************************************************************************/
/*                   										 I- Construction des foyers fiscaux "simplifiés"                 								  */
/**************************************************************************************************************************************************************/
/**************************************************************************************************************************************************************/


/**************************************************************************************************************************************************************/
/*				1- Sélection des individus pour lesquels il faut recontruire les déclarations fiscales   					  								  */
/**************************************************************************************************************************************************************/

/*Repérage des revenus imputés l'année des impôts*/ 
/*On repart des valeurs avant application de la légslation 2017 car non symétrique pour O et I*/
data imputation (keep=ident&acour. noi imp_revind zsalo&asuiv3. zchoi&asuiv3. zrsto&asuiv3. zrago&asuiv3. zrico&asuiv3. zrnco&asuiv3.) ; 
set saphir.indivi&acour._r&asuiv3. ;

imp_revind=(zsalI&asuiv3. ne zsalO&asuiv3. ! ZCHOO&asuiv3. ne zchoI&asuiv3. ! ZRSTO&asuiv3. ne zrstI&asuiv3. !
ZRAGO&asuiv3. ne zragI&asuiv3. ! ZRICO&asuiv3. ne zricI&asuiv3. ! ZRNCO&asuiv3. ne zrnci&asuiv3.);

run ;

data indiv_decls (keep = ident&acour. noi quelfic quelfic2 rattach mds zsalim&asuiv3. zchoim&asuiv3. zrstim&asuiv3. zragim&asuiv3. zricim&asuiv3. zrncim&asuiv3.
noimer noiper naia acteu6 sexe matri mariage deces divorce matri_fip noicon REVDEC&asuiv3. imp_revind);
merge scenario.indiv_prest imputation; by ident&acour. noi ; 

/*On supprime les individus EE_NRT car sont hors champ de l'impot simplifié (sinon, double compte)*/
if quelfic='EE_NRT' then delete; 

/*Identification des individus pour lesquels il faut imputer les données fiscales*/
quelfic2=quelfic;
if quelfic='EE&FIP' & imp_revind=1 & deces=1 then quelfic2='EE_MDS';
/*On ne les garde pas dans le champ de l'impot simplifié*/

/*Selection des individus relevant de l'impot simplifié*/
if quelfic2 in ("EE_CAF","EE","EE_MDS");

/*RATTACH : indicatrice qui vaut 1 si l'individu est un enfant rattachable*/
rattach=((noiper ne ' ' ! noimer ne ' ') & (20&acour.-naia<=21 ! (20&acour.-naia<=25 & acteu6='5'))); 	/*enfant rattachable*/

/*REVDEC : agrégat des revenus déclarés*/
zsalim&asuiv3.=sum(zsali&asuiv3.,-zsalo&asuiv3.);
zchoim&asuiv3.=sum(zchoi&asuiv3.,-zchoo&asuiv3.);
zrstim&asuiv3.=sum(zrsti&asuiv3.,-zrsto&asuiv3.);
zragim&asuiv3.=sum(zragi&asuiv3.,-zrago&asuiv3.);
zricim&asuiv3.=sum(zrici&asuiv3.,-zrico&asuiv3.);
zrncim&asuiv3.=sum(zrnci&asuiv3.,-zrnco&asuiv3.);

REVDEC&asuiv3.=sum(zsalim&asuiv3.,zchoim&asuiv3.,zrstim&asuiv3.,zragim&asuiv3.,zricim&asuiv3.,zrncim&asuiv3.);

run;

/*Nombre maximal de personnes par ménage*/
proc sql noprint; select max(taille) into : nb_max_ind from (select max(noi) as taille from indiv_decls group by ident&acour.) ;  quit;


/**************************************************************************************************************************************************************/
/*				2- Création des déclarations fiscales                          																				  */
/**************************************************************************************************************************************************************/

/**************************************************************************************************************************************************************/
/*		a. Création d'une table ménage avec une ligne contenant tous les individus du ménage                                                                  */
/**************************************************************************************************************************************************************/

options mprint;
%macro creapanel(tabin=,tabsor=,ident=, var_per=,liste_var_t=,suff=);

proc sort data=&tabin. (keep =&liste_var_t. &ident. &var_per.) out=selec ; by &ident. &var_per.; run;
proc sort data=selec out=&tabsor. (keep = &ident.) nodupkey; by &ident.; run;


%let i=1;
%do %while(%index(&liste_var_t.,%scan(&liste_var_t.,&i.))>0);
    %let var=%scan( &liste_var_t. ,&i.);
    proc transpose data=selec out=sor&i. (drop = _NAME_ _LABEL_) prefix=&var._&suff.;
    id &var_per.;
    by &ident.;
    var &var.;
    run;

    data &tabsor. (compress = yes); retain &var._01-&var._&nb_max_ind. ; 
    merge &tabsor. sor&i.;
    by &ident.;
    run;

    %let i=%eval(&i.+1);
%end;
proc datasets library=work; delete sor: selec; run; quit;
%mend;


%creapanel
(tabin=indiv_decls,
tabsor=men_decls,
ident=ident&acour., 
var_per=noi,
liste_var_t=revdec&asuiv3. rattach noimer noiper matri matri_fip noicon noi sexe quelfic2,
suff=);



		/*** Creation des foyers ***/
data men_decls; set men_decls;

%macro decl;

/*i. Mise à blanc des NOIPER, NOIMER, NOICON si le père, la mère, le conjoint n'est pas dans ceux sans déclaration*/
%do i=1 %to &nb_max_ind.; 
%if &i.<=9 %then %let i=0&i.;

    if noi_&i. ne ' ' then do;

    %macro noi (varlist); 
    %let z=1;
    %do %while(%index(&varlist., %scan(&varlist.,&z.))>0); 
        %let var = %scan(&varlist, &z); 
        %do j=1 %to &nb_max_ind.; 
            %if &j.<=9 %then %let j=0&j.;

            if noi&var._&i.="&j." then do;  /*&var_decl : personne trouvée dans la déclaration*/
                &var._decl_&i.=0;  
                %do k=1 %to &nb_max_ind.; 
                %if &k.<=9 %then %let k=0&k.;
                    if noi_&j.="&k." then &var._decl_&i.=1;
                %end;
            end;
            if noi&var._&i.="&j." & &var._decl_&i.=0 then  noi&var._&i.=' ';
        %end;

    %let z = %eval(&z + 1);
    %end;
    %mend; %noi (varlist= per mer con);
    end ;
    drop con_decl_&i. per_decl_&i. mer_decl_&i. ;
%end;


/*ii. Rattachement fiscal*/
/*noi_declsi : numero individuel du déclarant */

/*Initialisation*/
%do i=1 %to &nb_max_ind.; 
    %if &i.<=9 %then %let i=0&i.;
    if noi_&i. ne ' ' then do;
        length noi_decls&i. $2.;
        length noi_cdecls&i. $2.;
        noi_decls&i.="&i.";
    end;
%end;

			/*** Rattachement ***/

		/** Cas des conjoints **/
%do i=1 %to &nb_max_ind.; 
    %if &i.<=9 %then %let i=0&i.;

    if noi_&i. ne ' ' then do;
    %do j=1 %to &nb_max_ind.; 
        %if &j.<=9 %then %let j=0&j.;
        if noicon_&i.="&j" then do;     
        if  (quelfic2_&i. ne 'EE_MDS' & quelfic2_&j. ne 'EE_MDS') & (matri_&i.='2' & matri_&j.='2') ! /*si ne sont pas MDS et les 2 sont mariés => on les met 
																										dans la même déclaration*/
            (quelfic2_&i. =  'EE_MDS' & quelfic2_&j. =  'EE_MDS') ! 	/*veuvage après la date d'enquête (ou erreur de date) : on les met dans la même 
																		  déclaration*/
            (quelfic2_&i. =  'EE_MDS' ! quelfic2_&j. =  'EE_MDS') 		/*cas très rares*/  
        then do;; 
            if sexe_&i.='2' then do; noi_decls&i.="&j."; noi_cdecls&i.="&i."; end;
            if sexe_&i.='1' then noi_cdecls&i.="&j.";               
        end;
        end;
    %end;
    end;
%end;


		/** Cas des enfants **/
%do i=1 %to &nb_max_ind.; 
    %if &i.<=9 %then %let i=0&i.;

    if noi_&i. ne ' ' & (noiper_&i. ne ' ' ! noimer_&i. ne ' ') & rattach_&i.=1  then do;

    %do j=1 %to &nb_max_ind.; 
    %if &j.<=9 %then %let j=0&j.;
        if noiper_&i.=' ' & noimer_&i.="&j." then do; noi_decls&i.=noi_decls&j.; pac&i.=1; end; /*Si mere seule => rattaché à la mère*/
        if noimer_&i.=' ' & noiper_&i.="&j." then do; noi_decls&i.=noi_decls&j.; pac&i.=1; end; /*Si pere seul => rattaché au père*/
        if noiper_&i. ne ' ' & noimer_&i. ne ' ' then do; /* Si pere et mère => rattaché a celui qui gagne le plus (ne joue que si parents pas mariés)*/
            if noiper_&i.="&j." then do;
                %do k=1 %to &nb_max_ind.; 
                %if &k.<=9 %then %let k=0&k.;
                    if noimer_&i.="&k." then do;
                        if revdec&asuiv3._&j.>=revdec&asuiv3._&k. then do;
                                noi_decls&i.=noi_decls&j.; 
                                noi_cdecls&i.=noi_cdecls&j.; 
                        end;
                        else do;
                                noi_decls&i.=noi_decls&k.; 
                                noi_cdecls&i.=noi_cdecls&k.; 
                        end;
                        pac&i.=1;
                    end;
                %end;
            end;
        end ;
    %end;
    end ;
%end;


/*NUM_DECL : numero de la déclaration*/
%do i=1 %to &nb_max_ind.; 
    %if &i.<=9 %then %let i=0&i.;
    if noi_&i. ne ' ' then do; num_decl&i.=&i.; end; /*on débute en donnant à chacun un numéro propre*/
    %end;

%do i=1 %to &nb_max_ind.;
    %if &i.<=9 %then %let i=0&i.;
    %do j=1 %to &nb_max_ind.;
        %if &j.<=9 %then %let j=0&j.;
        if noi_decls&i.="&j."  then num_decl&i.=num_decl&j.;
    %end;               
%end;



%mend;
%decl;

run;

/**************************************************************************************************************************************************************/
/*		b. Passage à une table par individu													                                                                  */
/**************************************************************************************************************************************************************/

/*%CHGFORM permet de passer au format table individu*/
options mprint;
%macro chgform(tabin=,var=);
    proc transpose data=&tabin. out=&var. (rename=(col1=&var.));
    by ident&acour.;
    var &var.01-&var.&nb_max_ind.;
    run;

    data &var. (drop = _NAME_);
    set &var.;
    if &var.=. then delete;
    length noi $2.;
    noi=substr(_NAME_,%eval(%length(&var.)+1),2);
    run;
%mend;

/*Renumerotation foyers fiscaux*/
%chgform(tabin=men_decls,var=num_decl);

proc sort data=num_decl; by ident&acour. num_decl; run;

data num_decl (drop = num_decl);
set num_decl;
by ident&acour. num_decl;
retain num_decls 0;

/*NUM_DECLS : numero de déclaration (numéros qui se suivent)*/
if first.ident&acour. then num_decls=1;
else if first.num_decl then num_decls=num_decls+1;
else num_decls=num_decls;
run;

/*Creation d'une table individuelle : personnes à charge*/
%chgform(tabin=men_decls,var=pac);

/*Creation d'une table individuelle : noi_decls*/
%chgform(tabin=men_decls,var=noi_decls);

/*Creation d'une table individuelle : cdecls*/
%chgform(tabin=men_decls,var=noi_cdecls);


/*Mise en commun*/
proc sort data=indiv_decls; by ident&acour. noi; run;
proc sort data=noi_decls; by ident&acour. noi; run;
proc sort data=noi_cdecls; by ident&acour. noi; run;
proc sort data=num_decl; by ident&acour. noi; run;


data scenario.indiv_decls;
merge indiv_decls num_decl pac noi_decls noi_cdecls; by ident&acour. noi;
imp_simp=1;  /*Indicatrice d'impôt simplifié*/
run;


/**************************************************************************************************************************************************************/
/*		c. Passage à une table par déclaration												                                                                  */
/**************************************************************************************************************************************************************/

/*Informations sur les personnes à charge*/
%macro pac(listvar=);
proc sort data=scenario.indiv_decls; by ident&acour. num_decls; run;
    
%let i=1;
%do %while(%index(&listvar.,%scan(&listvar.,&i.))>0); 
    %let var=%scan(&listvar.,&i.);
    proc transpose data=scenario.indiv_decls (where=(pac=1)) out=&var. (drop=_LABEL_ _NAME_) prefix=&var.pac;
    by ident&acour. num_decls;
    var &var.;
    run;

    %let i=%eval(&i.+1);
%end;

data decl_pac;
merge &listvar.;
by ident&acour. num_decls;
run;

proc datasets library=work; delete &listvar.; run; quit;
%mend;

%pac(listvar=pac zsalim&asuiv3. zchoim&asuiv3. zrstim&asuiv3. zragim&asuiv3. zricim&asuiv3. zrncim&asuiv3. );

data decl_pac;
set decl_pac;
rename pacpac1=pac1 pacpac2=pac2 pacpac3=pac3 pacpac4=pac4 pacpac5=pac5 pacpac6=pac6;
run;

/*Informations sur le declarant et le conjoint*/
%macro decl_cdecl(lien=,liste= );

/*Selection des declarants/conjoints*/
data &lien. (drop =noi_&lien.s );
set scenario.indiv_decls (keep = ident&acour. num_decls noi_&lien.s &liste.);
if noi=noi_&lien.s;
run;

/*Renommage les variables*/
data &lien.; set &lien.;
rename %scan(&liste.,1)=%scan(&liste.,1)_&lien.s;
%let i=2;
%do %while(%index(&liste.,%scan(&liste.,&i.))>0); 
    rename %scan(&liste.,&i.)=%scan(&liste.,&i.)_&lien.;
    %let i=%eval(&i.+1);
%end;
run;

proc sort data=&lien.; by ident&acour. num_decls; run;

%mend;

%decl_cdecl(lien=decl,liste=noi zsalim&asuiv3. zchoim&asuiv3. zrstim&asuiv3.  zragim&asuiv3. zricim&asuiv3. zrncim&asuiv3. matri matri_fip deces divorce mariage);
%decl_cdecl(lien=cdecl,liste=noi zsalim&asuiv3. zchoim&asuiv3. zrstim&asuiv3. zragim&asuiv3. zricim&asuiv3. zrncim&asuiv3.);


/*Mise en commun*/
proc sort data=decl; by ident&acour. num_decls; run;
proc sort data=cdecl; by ident&acour. num_decls; run;
proc sort data=decl_pac; by ident&acour. num_decls; run;

data decls; merge decl cdecl decl_pac;  by ident&acour. num_decls;  run;




/**************************************************************************************************************************************************************/
/*				3. Calcul du nombre de parts et agrégation des revenus                  																	  */
/**************************************************************************************************************************************************************/

data decls (keep = ident&acour. noi_decls noi_cdecls num_decls z: nbpart );
set decls;


/**************************************************************************************************************************************************************/
/*		a. Agrégation des revenus des personnes à charge									                                                                  */
/**************************************************************************************************************************************************************/

zsalf&asuiv3._pac=sum(of zsalim&asuiv3.pac :);
zchof&asuiv3._pac=sum(of zchoim&asuiv3.pac :);
zrstf&asuiv3._pac=sum(of zrstim&asuiv3.pac :);
zragf&asuiv3._pac=sum(of zragim&asuiv3.pac :);
zricf&asuiv3._pac=sum(of zricim&asuiv3.pac :);
zrncf&asuiv3._pac=sum(of zrncim&asuiv3.pac :);

drop zsalim&asuiv3.pac : zchoim&asuiv3.pac : zrstim&asuiv3.pac :  zragim&asuiv3.pac : zricim&asuiv3.pac : zrncim&asuiv3.pac : ;
%zero(liste= zsalim&asuiv3._cdecl zchoim&asuiv3._cdecl zrstim&asuiv3._cdecl  zragim&asuiv3._cdecl zricim&asuiv3._cdecl zrncim&asuiv3._cdecl 
zsalf&asuiv3._pac zchof&asuiv3._pac zrstf&asuiv3._pac zalrf&asuiv3._pac zrtof&asuiv3._pac zragf&asuiv3._pac zricf&asuiv3._pac zrncf&asuiv3._pac );


/**************************************************************************************************************************************************************/
/*		b. Agregation des revenus au sein du foyer											                                                                  */
/**************************************************************************************************************************************************************/

zsalfs&asuiv3.=sum(zsalim&asuiv3._decl,zsalim&asuiv3._cdecl,zsalf&asuiv3._pac);
zchofs&asuiv3.=sum(zchoim&asuiv3._decl,zchoim&asuiv3._cdecl,zchof&asuiv3._pac);
zrstfs&asuiv3.=sum(zrstim&asuiv3._decl,zrstim&asuiv3._cdecl,zrstf&asuiv3._pac);
zragfs&asuiv3.=sum(zragim&asuiv3._decl,zragim&asuiv3._cdecl,zragf&asuiv3._pac);
zricfs&asuiv3.=sum(zricim&asuiv3._decl,zricim&asuiv3._cdecl,zricf&asuiv3._pac);
zrncfs&asuiv3.=sum(zrncim&asuiv3._decl,zrncim&asuiv3._cdecl,zrncf&asuiv3._pac);


/**************************************************************************************************************************************************************/
/*		c. Calcul du nombre de parts														                                                                  */
/**************************************************************************************************************************************************************/

%macro part;
    /*NBPAC : nombre de personnes à charge*/
    nbpac=0;
    %do i=1 %to 6; 		/*à actualiser chaque année en fonction du nombre maximal de personnes à charge*/
        if pac&i.=1 then nbpac=nbpac+1;
    %end;

    /*NBPART : Nombre de parts fiscales*/
    nbpart=1
    +1*(noi_cdecls ne ' ') 	/*conjoint*/
    +0.5*min(2,nbpac)+1*max(0,nbpac-2) 	/*enfants*/
    +1*((matri_decl='3' ! (matri_fip_decl='M' & deces_decl=1 & noi_cdecls=' ' & nbpac>0)) & noi_cdecls=' ' & nbpac>0); /*veuves*/

%mend ; %part;
run;


/**************************************************************************************************************************************************************/
/**************************************************************************************************************************************************************/
/*	                               								II- Calcul de l'impôt "simplifié"                      										  */ 
/**************************************************************************************************************************************************************/
/**************************************************************************************************************************************************************/

/*Calcul de l'impot*/
data scenario.impot_simp_R&asuiv3. (compress = yes
keep=ident&acour. num_decls noi_decls impots nbpart rni);
set decls;

/*Calcul d'un abattement sur les revenus salariaux (y compris revenus perçus à l'étranger)*/
AbatSal=min(max(&abat_taux.*sum(zsalfs&asuiv3.,zchofs&asuiv3.),&sal_abat_min.),&sal_abat_max.);
SAL=round(max(sum(zsalfs&asuiv3.,zchofs&asuiv3.,-AbatSal),0));

/*Calcul d'un abattement sur les pensions*/
AbatPen=min(max(&pen_abat_taux.*sum(zrstfs&asuiv3.),&pen_abat_min.),&pen_abat_max.);
PEN=round(max(sum(zrstfs&asuiv3.,-AbatPen),0));

/*Pseudo revenu imposable du foyer*/
RNI=sum(SAL,PEN,ZRAGFs&asuiv3.,ZRICFs&asuiv3.,ZRNCFs&asuiv3.);

/*Application du barème*/
QF=round(RNI/nbpart);

 %Bareme(qf = QF, rev = RNI, npart = nbpart, out_var = DS, nb_tranches = &nb_tranches);

/*Plafonnement du QF (version simplifiée)*/
if (noi_cdecls ne ' ') then do;		/*marié/ pacsé*/
    avQF=&plaf_qf_1.*2*(nbpart-2);
    nbpart_bis=2;
end;

if (noi_cdecls = ' ') then do;
    avQF=&plaf_qf_1.*2*(nbpart-1);
    nbpart_bis=1;
end;

QF_bis=round(RNI/nbpart_bis);

 %Bareme(qf = QF_bis, rev = RNI, npart = nbpart_bis, out_var = DS_bis, nb_tranches = &nb_tranches);

 if DS_bis-DS >= avQF then DS=sum(DS_bis,-avQF);

/*Décote*/
IF (noi_cdecls = ' ')  and DS<=&plaf_decote_celib.  THEN impots=max(DS-round(&pente_decote_celib.*(&plaf_decote_celib.-DS)),0);
if (noi_cdecls ne ' ') and DS<=&plaf_decote_couple. THEN impots=max(DS-round(&pente_decote_couple.*(&plaf_decote_couple.-DS)),0);
ELSE impots=DS;

/*Réduction d'impot 2017*/
if &switch_redIR. then do;
    if (noi_cdecls = ' ') then do;
        seuil1 = &seuil_redIR_1. + &seuil_redIR_dp.*max(nbpart-1,0)*2;
        seuil2=  &seuil_redIR_2. + &seuil_redIR_dp.*max(nbpart-1,0)*2;
    end;

    if (noi_cdecls ne ' ') then do;
        seuil1 = &seuil_redIR_1.*2 + &seuil_redIR_dp.*max(nbpart-2,0)*2;
        seuil2=  &seuil_redIR_2.*2 + &seuil_redIR_dp.*max(nbpart-2,0)*2;
    end;
    if RNI<=seuil1 then redIR=impots*&taux_redIR.;
    else if RNI<=seuil2 then redIR= impots*((-&taux_redIR./(seuil2-seuil1))*RNI + ((&taux_redIR.*seuil2)/(seuil2 - seuil1))) ;

    impots=sum(impots,-redIR);

end;
run;



/**************************************************************************************************************************************************************/
/**************************************************************************************************************************************************************/
/*      									III-  Ajout des informations de l'impot simplifié à la table individuelle        						  		  */
/**************************************************************************************************************************************************************/
/**************************************************************************************************************************************************************/

proc sort data=scenario.indiv_prest; by ident&acour. noi; run;


data scenario.indiv_decls ; merge scenario.indiv_decls (in=a) scenario.impot_simp_r&asuiv3. (keep = ident&acour. num_decls RNI impots ); 
by ident&acour. num_decls ; if a ; run ; 
proc sort data=scenario.indiv_decls ; by ident&acour. noi; run; 

data scenario.indiv_prest (compress = yes); 
merge scenario.indiv_prest (in=a) scenario.indiv_decls (keep = ident&acour. noi impots );  by ident&acour. noi;  if a;
if impots=. then impots=0;
run;



/**************************************************************************************************************************************************************/
/**************************************************************************************************************************************************************/
/*      												IV-  Ajout des poids ménage à la table impot                										  */
/**************************************************************************************************************************************************************/
/**************************************************************************************************************************************************************/

proc sort data=scenario.impot_simp_r&asuiv3. ; by ident&acour. ; run; 
proc sort data=scenario.menage_prest out=ident (keep = ident&acour. wprm&asuiv4.) ; by ident&acour. ; run; 

data scenario.impot_simp_r&asuiv3. ; merge scenario.impot_simp_r&asuiv3. (in=a) ident;  by ident&acour.; if a ; run; 



/*Nettoyage work*/
proc datasets library=work; delete ident decl cdecl decl_pac decls men_decls num_decl noi_decls noi_cdecls indiv_decls; run; quit;

/*************************************************************************************************************************************************************
**************************************************************************************************************************************************************

Ce logiciel est régi par la licence CeCILL V2.1 soumise au droit français et respectant les principes de diffusion des logiciels libres. 

Vous pouvez utiliser, modifier et/ou redistribuer ce programme sous les conditions de la licence CeCILL V2.1. 

Le texte complet de la licence CeCILL V2.1 est dans le fichier `LICENSE`.

Les paramètres de la législation socio-fiscale figurant dans les programmes 6, 7a et 7b sont régis par la « Licence Ouverte / Open License » Version 2.0.
**************************************************************************************************************************************************************
*************************************************************************************************************************************************************/

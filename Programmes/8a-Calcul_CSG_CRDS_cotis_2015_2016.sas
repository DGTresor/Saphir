

/**************************************************************************************************************************************************************/
/*                                									SAPHIR E2013 L2017                                         								  */
/*                                  									PROGRAMME 8 a                                             							  */
/*     								Calcul sur barème de la CSG, de la CRDS, des cotisations sociales pour 2014, 2015 et 2016								  */
/**************************************************************************************************************************************************************/


/**************************************************************************************************************************************************************/
/* L'ERFS ne comprend à l'origine que les revenus imposables. Les montants de CSG, CRDS et cotisations sociales sont recalculés de manière à pouvoir passer du*/
/* revenu imposable recueilli au revenu net intervenant dans le calcul du revenu disponible ou de certaines prestations. 									  */ 
/*																																							  */
/* Dans un premier temps, le programme 6 applique la législation 2013 sur les revenus de l'ERFS (y compris vieillis 2016 et 2017) afin d'obtenir les revenus  */
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
/* Ce programme définit les cotisations sociales, la CSG et la CRDS pour les années 2014, 2015 et 2016. Les macros définies servent également au calcul des   */
/* cotisations pour 2017 dans le programme 9a.																												  */
/**************************************************************************************************************************************************************/


data cotis;set saphir.cotis;
/*Régime d'assujettissement à la CSG/CRDS pour les revenus de remplacement : redéfinition des variables car réforme en 2015*/

tx_ret&asuiv2.=tx_ret ; 
tx_cho&asuiv2.=tx_cho ;

/*Statut d'imposition en 2013 comme proxy pour le statut d'imposition en 2015 car on ne recalcule pas l'impôt 2014*/ 

/*Retraite*/ 
if (mnrvkh=<(&&seuil_exo_csg&asuiv.+max(part-1,0)*2*&&seuil_exo_csg_demipart&asuiv.) ! info_fip=0) then tx_ret&asuiv3.=1;	/*exonération*/
else do;
    if mnrvkh=<(&&seuil_tx_red&asuiv.+max(part-1,0)*2*&&seuil_tx_red_demipart&asuiv.) then tx_ret&asuiv3.=2;				/*taux réduit*/
    else tx_ret&asuiv3.=3; 																									/*taux plein*/
end;

/*Chômage*/
tx_cho&asuiv3.=tx_ret&asuiv3.; /*Pour l'exonération spéciale ARE : voir plus bas dans le code*/
run;


/**************************************************************************************************************************************************************/
/**************************************************************************************************************************************************************/
/*                       										I. CALCUL CSG, CRDS, cotisations                 											  */
/**************************************************************************************************************************************************************/
/**************************************************************************************************************************************************************/


/**************************************************************************************************************************************************************/
/*				1 - Calcul des cotisations 2014 seulement pour les indépendants pour mettre à jour les bénéfices déclarés en 2014, utilisés dans le  		  */
/*					calcul des cotisations 2015																												  */
/**************************************************************************************************************************************************************/
%macro calculcotiz_indep(an= );
    
    %plafonds(annee=&an.); /*définition des plafonds de cotisation pour l'année considérée*/
    data cotis&an. (compress=yes keep = ident&acour. noi zrici&an. zragi&an. zrnci&an.);
    merge cotis saphir.revbrut&an.    ;
    by ident&acour. noi; 



    		/** Revenus des non salariés agricoles ZRAGI **/
    if (zragi ne 0) then do;
        if (CSTOT in ('11','12','13','71') and statut ne '13') then do; /*exploitants à titre principal*/
            CSS_rag&an.=  max(zragi,&&ass_min_amexa&an.)*&&tx_css_amexa_princ&an.
                        + max(zragi,&&ass_min_inval&an.)*&&tx_css_inval&an.
                        + max(zragi,0)*&&tx_css_pfa&an. 
                        + min(max(zragi,&&ass_min_avi&an.),&&PSS&an.*12)*&&tx_css_avi&an.
                        + min(max(zragi,&&ass_min_ava&an.),&&PSS&an.*12)*&&tx_css_ava_plaf&an.
                        + max(zragi,&&ass_min_ava&an.)*&&tx_css_ava_deplaf&an.  
                        + max(zragi,&&ass_min_rco&an.)*&&tx_css_rco_&an.
                        + &&mt_css_atexa_cp_&an.;
            csecu_rag&an.=max(zragi,&&ass_min_amexa&an.)*&&tx_css_amexa_princ&an.
                        + max(zragi,&&ass_min_inval&an.)*&&tx_css_inval&an.
                        + max(zragi,0)*&&tx_css_pfa&an. 
                        + min(max(zragi,&&ass_min_avi&an.),&&PSS&an.*12)*&&tx_css_avi&an.
                        + min(max(zragi,&&ass_min_ava&an.),&&PSS&an.*12)*&&tx_css_ava_plaf&an.
                        + max(zragi,&&ass_min_ava&an.)*&&tx_css_ava_deplaf&an.  +&&mt_css_atexa_cp_&an.;
            VIVEA&an.=min(max((zragi+CSS_rag&an.)*&&tx_css_vivea_&an.,&&binf_vivea_&an.),&&bsup_vivea_&an.);
            Retr_Chom_rag&an.=min(max(zragi,&&ass_min_avi&an.),&&PSS&an.*12)*&&tx_css_avi&an.
                        + min(max(zragi,&&ass_min_ava&an.),&&PSS&an.*12)*&&tx_css_ava_plaf&an.
                        + max(zragi,&&ass_min_ava&an.)*&&tx_css_ava_deplaf&an.  
                        + max(zragi,&&ass_min_rco&an.)*&&tx_css_rco_&an.;

	/*Allégement du taux de cotisations famille*/
                %if &an.>=15 %then %do ;
                        allg_af&an.=0;
                         if 0<zragi<=&&seuil_tx_af_red&an. then allg_af&an.=&&tx_exo_pfa_bas_revenus&an.*max(zragi,0);
                        else if &&seuil_tx_af_red&an.<zragi<=&&sortie_tx_af_red&an. then allg_af&an.=&&tx_exo_pfa_bas_revenus&an./
						(&&sortie_tx_af_red&an.-&&seuil_tx_af_red&an.)*(&&sortie_tx_af_red&an.-zragi)*max(zragi,0);
                        CSS_rag&an.=sum(CSS_rag&an.,-allg_af&an.);
                        csecu_rag&an.=sum(csecu_rag&an.,-allg_af&an.);
                %end;       
        end;

        else if (STATUT = '13' or STATUTS2='3') then do; /*aides familaux*/ 
            CSS_rag&an.=  min(&&tx_css_amexa_AF&an.*&&ass_min_amexa&an.*&&tx_css_amexa_princ&an.
                        ,&&plaf_amexa_AF&an.)
                        + min(max(zragi,&&ass_min_avi&an.),&&PSS&an.*12)*&&tx_css_avi&an.
                        + min(max(zragi,&&ass_min_ava_AF&an.),&&PSS&an.*12)*&&tx_css_ava_plaf&an.
                        + &&mt_css_atexa_af_&an.;
            csecu_rag&an.=CSS_rag&an.;
            VIVEA&an.=&&binf_vivea_&an.;
            Retr_Chom_rag&an.=min(max(zragi,&&ass_min_avi&an.),&&PSS&an.*12)*&&tx_css_avi&an.
                        + min(max(zragi,&&ass_min_ava_AF&an.),&&PSS&an.*12)*&&tx_css_ava_plaf&an.;
        end;

        else do; /*exploitants à titre secondaire*/
            CSS_rag&an.=  max(zragi,0)*&&tx_css_amexa_sec&an. 
                        + &&mt_css_amexa_sec_&an.
                        + max(zragi,0)*&&tx_css_inval&an. 
                        + max(zragi,0)*&&tx_css_pfa&an. 
                        + min(max(zragi,&&ass_min_avi&an.),&&PSS&an.*12)*&&tx_css_avi&an.
                        + min(max(zragi,&&ass_min_ava&an.),&&PSS&an.*12)*&&tx_css_ava_plaf&an.
                        + max(zragi,&&ass_min_ava&an.)*&&tx_css_ava_deplaf&an.  
                        + max(zragi,&&ass_min_rco&an.)*&&tx_css_rco_&an.
                        + &&mt_css_atexa_cs_&an.;
            csecu_rag&an.=max(zragi,0)*&&tx_css_amexa_sec&an. 
                        + &&mt_css_amexa_sec_&an.
                        + max(zragi,0)*&&tx_css_inval&an. 
                        + max(zragi,0)*&&tx_css_pfa&an. 
                        + min(max(zragi,&&ass_min_avi&an.),&&PSS&an.*12)*&&tx_css_avi&an.
                        + min(max(zragi,&&ass_min_ava&an.),&&PSS&an.*12)*&&tx_css_ava_plaf&an.
                        + max(zragi,&&ass_min_ava&an.)*&&tx_css_ava_deplaf&an.+&&mt_css_atexa_cs_&an.;
            VIVEA&an.=min(max((zragi+CSS_rag&an.)*&&tx_css_vivea_&an.,&&binf_vivea_&an.),&&bsup_vivea_&an.);
            Retr_Chom_rag&an.=max(zragi,0)*&&tx_css_pfa&an. 
                        + min(max(zragi,&&ass_min_avi&an.),&&PSS&an.*12)*&&tx_css_avi&an.
                        + min(max(zragi,&&ass_min_ava&an.),&&PSS&an.*12)*&&tx_css_ava_plaf&an.
                        + max(zragi,&&ass_min_ava&an.)*&&tx_css_ava_deplaf&an.  
                        + max(zragi,&&ass_min_rco&an.)*&&tx_css_rco_&an.;

	/*Allégement du taux de cotisations famille*/
                %if &an.>=15 %then %do ;
                        allg_af&an.=0;
                        if 0<zragi<=&&seuil_tx_af_red&an. then allg_af&an.=&&tx_exo_pfa_bas_revenus&an.*max(zragi,0);
                        else if &&seuil_tx_af_red&an.<zragi<=&&sortie_tx_af_red&an. then allg_af&an.=&&tx_exo_pfa_bas_revenus&an./
						(&&sortie_tx_af_red&an.-&&seuil_tx_af_red&an.)*(&&sortie_tx_af_red&an.-zragi)*max(zragi,0);
                        CSS_rag&an.=sum(CSS_rag&an.,-allg_af&an.);
                        csecu_rag&an.=sum(csecu_rag&an.,-allg_af&an.);
                 %end;
        end;

        CSGd_rag&an.=max(sum(zragi,CSS_rag&an.)*&&tx_csgd_sal&an.,0);
        CSGi_rag&an.=max(sum(zragi,CSS_rag&an.)*&&tx_csgi_sal&an.,0);
        CSG_rag&an.=sum(CSGd_rag&an.,CSGi_rag&an.);
        CRDS_rag&an.=max(sum(zragi,CSS_rag&an.)*&&tx_crds_sal&an.,0);

        zragi&an.=sum(zragbi&an., -CSS_rag&an., -CSGd_rag&an.); 

    end;    

    

    	/** Revenus des industriels et commerciaux **/

    /*Assiette des cotisations en N : Revenus N-1*/
    /*Revenus des non salariés industriels et commerciaux ZRICI*/
     if (ZRICI&an. ne 0) then do; /*CS '21' artisans et '22' commerçants et assimilés*/
        maladie_rsi_ic_&an.=(&&tx_css_canam1&an.-&&tx_css_canam2&an.*max(0,(1-max(zrici,0)/(&&seuil_css_canam&an.*12*&&PSS&an.)))
                            )*max(zrici, &&ass_min_canam&an.)
                            +&&tx_css_ij&an.*max(min(zrici,&&plaf_ij&an.), &&ass_min_ij&an.) ;  
    
        vieillesse_ic_&an.=&&tx_css_rco1_ic&an.*max(min(zrici,&&plaf_rco1_ic&an.),&&ass_min_rcoi&an.)
            +&&tx_css_rco2_ic&an.*min(max(zrici-&&plaf_rco1_ic&an.,0),(&&plaf_rco2_ic&an.-&&plaf_rco1_ic&an.));

        if cstot='21' then do;/*artisans*/
            CSS_ric&an.=maladie_rsi_ic_&an.
                        +&&tx_css_af_i&an.*max(zrici,0)
                        +&&tx_css_fp_art&an.*12*&&PSS&an.
                        +&&tx_css_rsi1_&an.*max(Min(zrici,12*&&PSS&an.),&&ass_min_rsi&an.)
                        +&&tx_css_rsi_deplaf&an.* max(zrici,&&ass_min_rsi&an.)
                        +vieillesse_ic_&an.
                        +&&tx_css_inv_art&an.*max(Min(zrici,12*&&PSS&an.),&&ass_min_inv&an.);
            CSecu_ric&an.=  maladie_rsi_ic_&an.
                        +&&tx_css_af_i&an.*max(zrici,0)
                        +&&tx_css_rsi1_&an.*max(Min(zrici,12*&&PSS&an.),&&ass_min_rsi&an.)
                        +&&tx_css_rsi_deplaf&an.* max(zrici, &&ass_min_rsi&an.)
                        +&&tx_css_inv_art&an.*max(Min(zrici,12*&&PSS&an.),&&ass_min_inv&an.);
            Retr_Chom_ric&an.=&&tx_css_rsi1_&an.*max(Min(zrici,12*&&PSS&an.),&&ass_min_rsi&an.)
                        +&&tx_css_rsi_deplaf&an.* max(zrici, &&ass_min_rsi&an.)
                        + vieillesse_ic_&an.;   
        end;

        else do; /*commerçants et autres*/
                CSS_ric&an.=maladie_rsi_ic_&an.
                        +&&tx_css_af_i&an.*max(zrici,0)
                        +&&tx_css_fp_i&an.*12*&&PSS&an.
                        +&&tx_css_rsi1_&an.*max(Min(zrici,12*&&PSS&an.),&&ass_min_rsi&an.)
                        +&&tx_css_rsi_deplaf&an.*max(zrici, &&ass_min_rsi&an.)
                        +vieillesse_ic_&an.
                        +&&tx_css_inv_com&an.*max(Min(zrici,12*&&PSS&an.),&&ass_min_inv&an.);   
                CSecu_ric&an.=  maladie_rsi_ic_&an.
                        +&&tx_css_af_i&an.*max(zrici,0)
                        +&&tx_css_rsi1_&an.*max(Min(zrici,12*&&PSS&an.),&&ass_min_rsi&an.)
                        +&&tx_css_rsi_deplaf&an.* max(zrici, &&ass_min_rsi&an.)
                        +&&tx_css_inv_com&an.*max(Min(zrici,12*&&PSS&an.),&&ass_min_inv&an.);
                Retr_Chom_ric&an.=&&tx_css_rsi1_&an.*max(Min(zrici,12*&&PSS&an.),&&ass_min_rsi&an.)
                        +&&tx_css_rsi_deplaf&an.* max(zrici, &&ass_min_rsi&an.)
                        +vieillesse_ic_&an.;    
        end;

	/*Allégement du taux de cotisations famille*/
             allg_af&an.=0;
             if 0<zrici<=&&seuil_tx_af_red&an. then allg_af&an.=&&tx_exo_pfa_bas_revenus&an.*max(zrici,0);
             else if &&seuil_tx_af_red&an.<zrici<=&&sortie_tx_af_red&an. then allg_af&an.=&&tx_exo_pfa_bas_revenus&an./
			(&&sortie_tx_af_red&an.-&&seuil_tx_af_red&an.)*(&&sortie_tx_af_red&an.-zrici)*max(zrici,0);
             CSS_ric&an.=sum(CSS_ric&an.,-allg_af&an.);
             CSecu_ric&an.=sum(CSecu_ric&an.,-allg_af&an.);


        CSGd_ric&an.=max(sum(zrici,CSS_ric&an.)*&&tx_csgd_sal&an.,0);
        CSGi_ric&an.=max(sum(zrici,CSS_ric&an.)*&&tx_csgi_sal&an.,0);
        CSG_ric&an. =sum(CSGd_ric&an.,CSGi_ric&an.);
        CRDS_ric&an.=max(sum(zrici,CSS_ric&an.)*&&tx_crds_sal&an.,0);

        zrici&an.=sum(zricbi&an., -CSS_ric&an., -CSGd_ric&an.);


    end; 

		/** Revenus non commerciaux **/
     

	/*Revenus des non salariés non commerciaux ZRNCI*/
    /*En cas de revenus négatifs --> montant forfaitaire*/
    if (ZRNCI ne 0) then do; /*CS '31' prof° libérales et '35' '42' '43' '46'*/
        
        CSS_rnc&an.=    (&&tx_css_canam1&an.-&&tx_css_canam2&an.*max(0,(1-max(zrnci,0)/(&&seuil_css_canam&an.*12*&&PSS&an.)))
                        )*max(zrnci, &&ass_min_canam&an.) /*les professions libérales ne cotisent pas aux IJ*/
                        +&&tx_css_af_i&an.*max(zrnci,0)
                        +&&tx_css_fp_i&an.*12*&&PSS&an.
                        +&&tx_css_rsi2_&an.*max(min(zrnci,&&plaf_cnavpl1&an.),&&ass_min_rsi&an.)
                        +&&tx_css_rsi3_&an.*max(min(zrnci,&&plaf_cnavpl2&an.),&&ass_min_rsi&an.)
                        +&&tx_css_rco_lib&an.*max(zrnci,0)
                        +&&tx_css_inv_lib&an.*max(zrnci,0);
        
        CSecu_rnc&an.=  (&&tx_css_canam1&an.-&&tx_css_canam2&an.*max(0,(1-max(zrnci,0)/(&&seuil_css_canam&an.*12*&&PSS&an.)))
                        )*max(zrnci, &&ass_min_canam&an.) /*les professions libérales ne cotisent pas aux IJ*/
                        +&&tx_css_af_i&an.*max(zrnci,0)
                        +&&tx_css_rsi2_&an.*max(min(zrnci,&&plaf_cnavpl1&an.),&&ass_min_rsi&an.)
                        +&&tx_css_rsi3_&an.*max(min(zrnci,&&plaf_cnavpl2&an.),&&ass_min_rsi&an.)
                        +&&tx_css_inv_lib&an.*max(zrnci,0);
        Retr_Chom_rnc&an.=+&&tx_css_rsi2_&an.*max(min(zrnci,&&plaf_cnavpl1&an.),&&ass_min_rsi&an.)
                        +&&tx_css_rsi3_&an.*max(min(zrnci,&&plaf_cnavpl2&an.),&&ass_min_rsi&an.)
                        + &&tx_css_rco_lib&an.*max(zrnci,0);
                            

		/*Allégement du taux de cotisations famille*/
             allg_af&an.=0;
             if 0<zrnci<=&&seuil_tx_af_red&an. then allg_af&an.=&&tx_exo_pfa_bas_revenus&an.*max(zrnci,0);
             else if &&seuil_tx_af_red&an.<zrnci<=&&sortie_tx_af_red&an. then allg_af&an.=&&tx_exo_pfa_bas_revenus&an./
			(&&sortie_tx_af_red&an.-&&seuil_tx_af_red&an.)*(&&sortie_tx_af_red&an.-zrnci)*max(zrnci,0);
             CSS_rnc&an.=sum(CSS_rnc&an.,-allg_af&an.);
             CSecu_rnc&an.=sum(CSecu_rnc&an.,-allg_af&an.);
             af_nonsal_&an.=sum(af_nonsal_&an.,-allg_af&an.);


        CSGd_rnc&an.=max(sum(zrnci,CSS_rnc&an.)*&&tx_csgd_sal&an.,0);
        CSGi_rnc&an.=max(sum(zrnci,CSS_rnc&an.)*&&tx_csgi_sal&an.,0);
        CSG_rnc&an. =sum(CSGd_rnc&an.,CSGi_rnc&an.);
        CRDS_rnc&an.=max(sum(zrnci,CSS_rnc&an.)*&&tx_crds_sal&an.,0);

        zrnci&an. = sum(zrncbi&an., - CSS_rnc&an., - CSGd_rnc&an.);

    end; 
run;
%mend;

%calculcotiz_indep(an=&asuiv.); /*2014*/


/**************************************************************************************************************************************************************/
/*				2 - Calcul des cotisations pour toutes les catégories de revenus de 2015 à 2016																  */
/**************************************************************************************************************************************************************/

%macro calculcotiz(an= );
    
    %plafonds(annee=&an.); /*définition des plafonds de cotisation pour l'année considérée*/
    data cotis&an. (compress=yes keep = ident&acour. noi revactd&an. zchoi&an. ztsai&an. zperi&an. REVINDED&an.
    revactp&an._t: zchopi&an._t: zrstpi&an._t: zsalpi&an._t: zragpi&an._t: zricpi&an._t: zrncpi&an._t:
    revindep&an. revactp&an. 
    zsali&an. zsalbi&an. zchoi&an. zrsti&an. zragi&an. zrici&an. zrnci&an.
    hs&an. zchobi&an. zrstbi&an. zragbi&an. zricbi&an. zrncbi&an.
    zsalpi&an. zchopi&an. zrstpi&an. zragpi&an. zricpi&an. zrncpi&an.
    CSG_rst&an. CSG_cho&an. CSG_sal&an. CSG_rag&an. CSG_ric&an. CSG_rnc&an.
    CSGi_rst&an. CSGi_cho&an. CSGi_sal&an. CSGi_rag&an. CSGd_rag&an.  CSGi_ric&an. CSGi_rnc&an.
    CRDS_rst&an.  CRDS_cho&an. CRDS_sal&an. CRDS_rag&an. CRDS_ric&an. CRDS_rnc&an. 
    Unedic_sal&an. CSecu_sal&an. CSS_sal&an. CSS_rag&an. CSS_ric&an. CSS_rnc&an.
    Unedic_pat&an. CSecu_pat&an. CSS_pat&an. 
    css_cho&an. CSecu_Cho&an. csecu_rnc&an. csecu_ric&an. csecu_rag&an. VIVEA&an.
    CSG_act&an. CSG_remp&an. CRDS_act&an. CRDS_remp&an. CSS_indep&an.
    statut statuts2 cstot prive 
    tx_allg&an._m: Retr_Chom_act&an.
    zsali&an._m: zsalbi&an._m: tr_css_c: CSS_sal&an._m:
    maladie_rsi_ic_&an. af_nonsal_&an. tx_ret tx_cho Casa_RST&an.
    _1s _1p _1j _1a _1i _1n declar declar2 decl1 decl2 cjdecl1 cjdecl2 tx_ret&an. tx_cho&an.);

    merge cotis (drop= zrici%sysevalf(&an.-1) zragi%sysevalf(&an.-1) zrnci%sysevalf(&an.-1))
    saphir.revbrut&an. saphir.revbrut%sysevalf(&an.-1)(keep=noi ident&acour. zricbi%sysevalf(&an.-1))
    cotis%sysevalf(&an.-1) (keep=noi ident&acour. zrici%sysevalf(&an.-1) zragi%sysevalf(&an.-1) zrnci%sysevalf(&an.-1));    by ident&acour. noi; 


/**************************************************************************************************************************************************************/
/*		a. CSG, CRDS sur les retraites 			                                                                                                              */
/**************************************************************************************************************************************************************/

    if zrsti>0 then do; 

        /*_1s : retraite déclaré au niveau individuel en 2013*/
        /* On garde le montant déclaré pour appariement avec les données fiscales*/
        _1s=zrsti&an.;

        /*TX_CSGD_RST : taux de CSG déductible sur les retraites*/
        tx_CSGd_rst=&&tx_csgd1_rst&an.*(tx_ret&an.=1)+&&tx_csgd2_rst&an.*(tx_ret&an.=2)+&&tx_csgd3_rst&an.*(tx_ret&an.=3);

        /*TX_CSGI_RST : taux de CSG imposable sur les retraites*/
        tx_CSGi_rst=&&tx_csgi1_rst&an.*(tx_ret&an.=1)+&&tx_csgi2_rst&an.*(tx_ret&an.=2)+&&tx_csgi3_rst&an.*(tx_ret&an.=3);

        /*TX_CSG_RST : taux de CSG sur les retraites*/
        tx_CSG_rst=sum(tx_CSGd_rst,tx_CSGi_rst);

        /*TX_CRDS_RST : taux de CRDS sur les retraites*/
        tx_CRDS_rst=(tx_ret&an. in (2,3))*&&tx_crds&an.;

        /*TX_Casa_RST : taux de Casa sur les retraites*/
        tx_Casa_RST=(tx_ret&an.=3)*&&tx_casa&an.;

        /*ZRST : retraite brute et perçue sur l'année*/
        zrstbi&an.=max(0,sum(of zrstbi&an._m:));
                
        /*CSG_RST : montant de CSG sur les retraites*/ 
        CSGd_rst&an.=zrstbi&an.*tx_CSGd_rst;
        CSGi_rst&an.=zrstbi&an.*tx_CSGi_rst;
        CSG_rst&an.=sum(CSGd_rst&an.,CSGi_rst&an.);

        /*CRDS_RST : montant de CRDS sur les retraites*/    
        CRDS_rst&an.=zrstbi&an.*tx_CRDS_rst;

        /*Casa_RST : montant de Casa sur les retraites*/
        Casa_RST&an.=zrstbi&an.*tx_Casa_rst;

        /*ZRSTI : pensions de retraite déclarées sur l'année (imposables)*/
        zrsti&an.=max(0,zrstbi&an.*(1-tx_csgd_rst));

        /*ZRSTPI : pensions de retraite perçues  */
        zrstpi&an.=max(0,zrstbi&an.*(1-tx_csg_rst-tx_CRDS_rst-tx_Casa_RST));

        /*ZRSTPI_Ti : pensions de retraite perçues  au trimestre i*/
        %macro trim;
        %do t=1 %to 4;
            zrstpi&an._t&t.=max(0,zrstbi&an._t&t.*(1-tx_csg_rst-tx_CRDS_rst-tx_Casa_RST));
        %end;
        %mend;
        %trim;
    end;


/**************************************************************************************************************************************************************/
/*		b. CSG, CRDS sur le chômage et les préretraites                                                                                                        */
/**************************************************************************************************************************************************************/

    if zchoi>0 then do; 

        /*_1p : chômage déclaré au niveau individuel en 2013*/
        /*On garde le montant déclaré pour appariement avec les données fiscales*/
        _1p=zchoi&an.; 

        /*TX_CSGD_cho : taux de CSG déductible sur le chômage*/
        tx_CSGd_cho=(preret ne '1')*(&&tx_csgd1_cho&an.*(tx_cho&an.=1)+&&tx_csgd2_cho&an.*(tx_cho&an.=2)+&&tx_csgd3_cho&an.*(tx_cho&an.=3))+(preret='1')*&&tx_csgd4_cho&an.;/*taux 4 pour les préretraites*/

        /*TX_CSGI_cho : taux de CSG imposable sur le chômage*/
        tx_CSGi_cho=(preret ne '1')*(&&tx_csgi1_cho&an.*(tx_cho&an.=1)+&&tx_csgi2_cho&an.*(tx_cho&an.=2)+&&tx_csgi3_cho&an.*(tx_cho&an.=3))+(preret='1')*&&tx_csgi3_cho&an.;

        /*TX_CSG_cho : taux de CSG sur le chômage*/
        tx_CSG_cho=sum(tx_CSGd_cho,tx_CSGi_cho);

        /*TX_CRDS_cho : taux de CRDS sur le chomage*/
        tx_CRDS_cho=(tx_cho&an. in (2,3))*&&tx_crds&an.;

        /*Assiette chômage ou préretraite*/
        assiette=(1+(preret ne '1')*(&&ass_csg_cho&an.-1));

        /*ZCHOBI_Mm : allocation brute au mois m*/
        %macro mois;
            %do m=1 %to 12;
                /* Cotisations retraite complémentaire sur le chômage total*/
                tx_CSS_cho&an._m&m.=(preret ne '1' and zchoi&an._m&m.>(&&ajm&an.*30))*&&tx_css_cho&an./&&tx_remplacement&an.;
                zchopi&an._m&m.=zchobi&an._m&m.*(1-assiette*(tx_csg_cho+tx_CRDS_cho)-tx_CSS_cho&an._m&m.);

                /*Exonération de CSG/CRDS pour les ARE inférieures au Smic mensuel : L.136-2 CSS*/
                if (preret ne '1') & zchobi&an._m&m.<151.67*&&Smic_hor_brut&an. & zchobi&an._m&m.>0 then do;
                zchopi&an._m&m.=zchobi&an._m&m.*(1-tx_CSS_cho&an._m&m.); 
                tx_cho&an.=1;
                tx_CSGd_cho=0;
                tx_CSGi_cho=0;
                tx_csg_cho=0;
                tx_crds_cho=0;
                exo&an.=1;
                end;

                CSS_cho&an._m&m.=zchobi&an._m&m.*tx_CSS_cho&an._m&m.;
            %end;
        %mend;
        %mois;
        
        /*zchopI_Ti : chômage et préretraite percues au trimestre i*/
            zchopi&an._t1=max(0,sum(zchopi&an._m1,zchopi&an._m2,zchopi&an._m3));
            zchopi&an._t2=max(0,sum(zchopi&an._m4,zchopi&an._m5,zchopi&an._m6));
            zchopi&an._t3=max(0,sum(zchopi&an._m7,zchopi&an._m8,zchopi&an._m9));
            zchopi&an._t4=max(0,sum(zchopi&an._m10,zchopi&an._m11,zchopi&an._m12));

        /*ZCHO : chômage et préretraite bruts de l'année*/
        zchopi&an.=max(0,sum(of zchopi&an._m:));
        zchobi&an.=max(0,sum(of zchobi&an._m:));

        /*CSG_CHO : montant de CSG sur le chomage*/ 
        CSGd_cho&an.=zchobi&an.*tx_CSGd_cho*(1+(preret ne '1')*(&&ass_csg_cho&an.-1));
        CSGi_cho&an.=zchobi&an.*tx_CSGi_cho*(1+(preret ne '1')*(&&ass_csg_cho&an.-1));
        CSG_cho&an.=sum(CSGd_cho&an.,CSGi_cho&an.);

        /*CRDS_CHO : montant de CRDS sur le chomage*/   
        CRDS_cho&an.=zchobi&an.*tx_crds_cho*(1+(preret ne '1')*(&&ass_csg_cho&an.-1));

        /*CSS_CHO : montant de cotisation retraite complémentaire sur chômage total*/
        CSS_cho&an.=sum(of CSS_cho&an._m:);
        csecu_cho&an.=CSS_cho&an.;

        /*ZCHOI : chômage déclaré*/
        zchoi&an.=max(0,zchobi&an.*(1-assiette*tx_csgd_cho));

    end;


/**************************************************************************************************************************************************************/
/*		c. CSG, CRDS, cotisations sociales salariales sur les salaires                                                                                        */
/**************************************************************************************************************************************************************/

    /*_1j : salaire déclaré au niveau individuel en 2013*/
    /*On garde le montant déclaré pour appariement avec les données fiscales*/
     _1j=zsali&an.;

    		/*** Cas des salariés du privé ***/
    if zsali>0 & prive=1 then do; /*salarié du privé*/

            	/* Classement par taille de l'entreprise actuelle ou antérieure*/
                select (NBSALB);
                        when ('0','1','2','3', '4', '5', '6', '7', '8', '9') TailEnt='1'; /*moins de 10 salariés*/
                        when ('10') TailEnt='2'; /*entre 10 et 49 salariés*/
                        when ('11','12') TailEnt='3'; /*plus de 49 salariés*/
                        otherwise do;
                            select (ANBSAL);
                                when ('0','1','2','3', '4', '5', '6', '7', '8', '9') TailEnt='1';
                                when ('10') TailEnt='2';
                                when ('11','12') TailEnt='3';
                                otherwise TailEnt='2';
                            end;
                        end;    
                end;


        %macro mens;
        %do m=1 %to 12;
            
            if zsali&an._m&m.>0 then do;

		/** Cadres **/
                if cadre=1 then do; 
                /*Les salariés des entreprises publiques ne cotisent pas pour le chômage, on soustrait donc le taux de cotisation chômage (plafonné à 4P) 
                du taux de cotisation total pour ces salariés.
                Dans la suite du code on remplace les macros variables &&tx_css par des variables*/
                    tx_css_c1_&an.=&&tx_css_c1_&an.-&&tx_css_assedic&an.*salarie_EN;
                    tx_css_c2_&an.=&&tx_css_c2_&an.-&&tx_css_assedic&an.*salarie_EN;
                    tx_css_c3_&an.=&&tx_css_c3_&an.-&&tx_css_assedic&an.*salarie_EN;

                    /*TR_CSS_Ci : tranche de cotisations pour les cadres, i=1,...,4*/
                    tr_css_c1_m&m.=(&binf_css_c1.*quot_sal_m&m.<=zsalbi&an._m&m.<&bsup_css_c1.*quot_sal_m&m.);
                    tr_css_c2_m&m.=(&binf_css_c2.*quot_sal_m&m.<=zsalbi&an._m&m.<&bsup_css_c2.*quot_sal_m&m.);
                    tr_css_c3_m&m.=(&binf_css_c3.*quot_sal_m&m.<=zsalbi&an._m&m.<&bsup_css_c3.*quot_sal_m&m.);
                    tr_css_c4_m&m.=(&binf_css_c4.*quot_sal_m&m.<=zsalbi&an._m&m.<&bsup_css_c4.*quot_sal_m&m.);

                    /*CSS_SAL_Mm : cotisations sociales salariales sur les salaires au mois m*/
                    CSS_sal&an._m&m.=(tr_css_c1_m&m.=1)*zsalbi&an._m&m.*tx_css_c1_&an.
                        +(tr_css_c2_m&m.=1)*(zsalbi&an._m&m.-quot_sal_m&m.*&binf_css_c2.)*tx_css_c2_&an.
                        +(tr_css_c3_m&m.=1)*(zsalbi&an._m&m.-quot_sal_m&m.*&binf_css_c3.)*tx_css_c3_&an.
                        +(tr_css_c4_m&m.=1)*(zsalbi&an._m&m.-quot_sal_m&m.*&binf_css_c4.)*&&tx_css_c4_&an.
                        +(tr_css_c2_m&m.+tr_css_c3_m&m.+tr_css_c4_m&m.=1)*(&bsup_css_c1.-&binf_css_c1.)*quot_sal_m&m.*tx_css_c1_&an.
                        +(tr_css_c3_m&m.+tr_css_c4_m&m.=1)*(&bsup_css_c2.-&binf_css_c2.)*quot_sal_m&m.*tx_css_c2_&an.
                        +(tr_css_c4_m&m.=1)*(&bsup_css_c3.-&binf_css_c3.)*quot_sal_m&m.*tx_css_c3_&an.;
                    CSecu_sal&an._m&m.=zsalbi&an._m&m.*(&&tx_css_mmdi&an.)
                        +min(zsalbi&an._m&m.,&bsup_css_c1.*quot_sal_m&m.)*(&&tx_css_vieil&an.+&&tx_css_vieil_tot&an.)
                        +max(zsalbi&an._m&m.-&bsup_css_c1.*quot_sal_m&m.,0)*&&tx_css_vieil_tot&an.; 
                    Unedic_sal&an._m&m.=((tr_css_c1_m&m.+tr_css_c2_m&m.=1)*zsalbi&an._m&m.*&&tx_css_assedic&an.
                        +(tr_css_c1_m&m.+tr_css_c2_m&m.=0)*&bsup_css_c2.*quot_sal_m&m.*&&tx_css_assedic&an.)*(1-salarie_EN);
                    agirc_sal&an._m&m.=(tr_css_c1_m&m.=1)*zsalbi&an._m&m.*&&tx_css_retA&an.+(tr_css_c1_m&m.=0)*&bsup_css_c1.*quot_sal_m&m.*&&tx_css_retA&an.
                        +(tr_css_c1_m&m.=0)*(tr_css_c4_m&m=0)*(zsalbi&an._m&m.-quot_sal_m&m.*&bsup_css_c1.)*&&tx_css_retB&an.
                        +(tr_css_c4_m&m=1)*quot_sal_m&m.*(&binf_css_c4.-&bsup_css_c1.)*&&tx_css_retB&an.;
                    cet_sal&an._m&m.=(tr_css_c4_m&m=0)*zsalbi&an._m&m.*&&tx_css_cet&an.
                        +(tr_css_c4_m&m=1)*quot_sal_m&m.*&binf_css_c4.*&&tx_css_cet&an.;
                    agff_sal&an._m&m.=(tr_css_c1_m&m.=1)*zsalbi&an._m&m.*&&tx_css_agff_A&an.+(tr_css_c1_m&m.=0)*&bsup_css_c1.*quot_sal_m&m.*&&tx_css_agff_A&an.
                        +(tr_css_c1_m&m.=0)*(tr_css_c2_m&m=0)*quot_sal_m&m.*(&bsup_css_c2.-&bsup_css_c1.)*&&tx_css_agff_B&an.
                        +(tr_css_c2_m&m=1)*(zsalbi&an._m&m.-quot_sal_m&m.*&bsup_css_c1.)*&&tx_css_agff_B&an.
                        +(tr_css_c1_m&m=0)*(tr_css_c2_m&m.=0)*(tr_css_c3_m&m.=0)*quot_sal_m&m.*(&bsup_css_c3.-&bsup_css_c2.)*&&tx_css_agff_C&an.
                        +(tr_css_c3_m&m.=1)*(zsalbi&an._m&m.-quot_sal_m&m.*&bsup_css_c2.)*&&tx_css_agff_C&an.;
                    apec_sal&an._m&m.=(tr_css_c1_m&m.=0)*(tr_css_c2_m&m=0)*quot_sal_m&m.*(&bsup_css_c2.-&bsup_css_c1.)*&&tx_css_apec&an.
                        +(tr_css_c2_m&m=1)*(zsalbi&an._m&m.-quot_sal_m&m.*&bsup_css_c1.)*&&tx_css_apec&an.;

                    /*CSS_PAT_Mm : cotisations sociales patronales sur les salaires au mois m*/
                    CSS_pat&an._m&m.=(tr_css_c1_m&m.=1)*zsalbi&an._m&m.*&&tx_csp_c1_&an.
                        +(tr_css_c2_m&m.=1)*(zsalbi&an._m&m.-quot_sal_m&m.*&binf_css_c2.)*&&tx_csp_c2_&an.
                        +(tr_css_c3_m&m.=1)*(zsalbi&an._m&m.-quot_sal_m&m.*&binf_css_c3.)*&&tx_csp_c3_&an.
                        +(tr_css_c4_m&m.=1)*(zsalbi&an._m&m.-quot_sal_m&m.*&binf_css_c4.)*&&tx_csp_c4_&an.
                        +(tr_css_c2_m&m.+tr_css_c3_m&m.+tr_css_c4_m&m.=1)*(&bsup_css_c1.-&binf_css_c1.)*quot_sal_m&m.*&&tx_csp_c1_&an.
                        +(tr_css_c3_m&m.+tr_css_c4_m&m.=1)*(&bsup_css_c2.-&binf_css_c2.)*quot_sal_m&m.*&&tx_csp_c2_&an.
                        +(tr_css_c4_m&m.=1)*(&bsup_css_c3.-&binf_css_c3.)*quot_sal_m&m.*&&tx_csp_c3_&an.
                        +(TailEnt='1')*(&&tx_csp_m10sal1&an.*min(zsalbi&an._m&m.,quot_sal_m&m.*&binf_css_c2.)
                                        +&&tx_csp_m10sal2&an.*max(0,zsalbi&an._m&m.-quot_sal_m&m.*&binf_css_c2.))
                        +(TailEnt ='2')*(&&tx_csp_10a20sal1&an.*min(zsalbi&an._m&m.,quot_sal_m&m.=&binf_css_c2.)
                                        +&&tx_csp_10a20sal2&an.*max(0,zsalbi&an._m&m. - quot_sal_m&m.*&binf_css_c2.))
                        +(TailEnt ='3')*&&tx_csp_p20sal&an.*zsalbi&an._m&m.;
                    CSecu_pat&an._m&m.=zsalbi&an._m&m.*(&&tx_csp_mmdi&an.+&&tx_csp_solauto&an.+&&tx_csp_AF&an.+&&tx_csp_ATMP&an.)
                        +min(zsalbi&an._m&m.,&bsup_css_c1.*quot_sal_m&m.)*(&&tx_csp_vieil&an.+&&tx_csp_vieil_tot&an.) 
                        +max(zsalbi&an._m&m.-&bsup_css_c1.*quot_sal_m&m.,0)*&&tx_csp_vieil_tot&an.; 
                    Unedic_pat&an._m&m.=((tr_css_c1_m&m.+tr_css_c2_m&m.=1)*zsalbi&an._m&m.*&&tx_csp_assedic&an.
                        +(tr_css_c1_m&m.+tr_css_c2_m&m.=0)*&bsup_css_c2.*quot_sal_m&m.*&&tx_csp_assedic&an.)*(1-salarie_EN);
                    agirc_pat&an._m&m.=(tr_css_c1_m&m.=1)*zsalbi&an._m&m.*&&tx_csp_retA&an.+(tr_css_c1_m&m.=0)*&bsup_css_c1.*quot_sal_m&m.*&&tx_csp_retA&an.
                        +(tr_css_c1_m&m.=0)*(tr_css_c4_m&m=0)*(zsalbi&an._m&m.-quot_sal_m&m.*&bsup_css_c1.)*&&tx_csp_retB&an.
                        +(tr_css_c4_m&m=1)*quot_sal_m&m.*(&binf_css_c4.-&bsup_css_c1.)*&&tx_csp_retB&an.;
                    cet_pat&an._m&m.=(tr_css_c4_m&m=0)*zsalbi&an._m&m.*&&tx_csp_cet&an.
                        +(tr_css_c4_m&m=1)*quot_sal_m&m.*&binf_css_c4.*&&tx_csp_cet&an.;                    
                    agff_pat&an._m&m.=(tr_css_c1_m&m.=1)*zsalbi&an._m&m.*&&tx_csp_agff_A&an.+(tr_css_c1_m&m.=0)*&bsup_css_c1.*quot_sal_m&m.*&&tx_csp_agff_A&an.
                        +(tr_css_c1_m&m.=0)*(tr_css_c2_m&m=0)*quot_sal_m&m.*(&bsup_css_c2.-&bsup_css_c1.)*&&tx_csp_agff_B&an.
                        +(tr_css_c2_m&m=1)*(zsalbi&an._m&m.-quot_sal_m&m.*&bsup_css_c1.)*&&tx_csp_agff_B&an.
                        +(tr_css_c1_m&m=0)*(tr_css_c2_m&m.=0)*(tr_css_c3_m&m.=0)*quot_sal_m&m.*(&bsup_css_c3.-&bsup_css_c2.)*&&tx_csp_agff_C&an.
                        +(tr_css_c3_m&m.=1)*(zsalbi&an._m&m.-quot_sal_m&m.*&bsup_css_c2.)*&&tx_csp_agff_C&an.;
                    apec_pat&an._m&m.=(tr_css_c1_m&m.=0)*(tr_css_c2_m&m=0)*quot_sal_m&m.*(&bsup_css_c2.-&bsup_css_c1.)*&&tx_csp_apec&an.
                        +(tr_css_c2_m&m=1)*(zsalbi&an._m&m.-quot_sal_m&m.*&bsup_css_c1.)*&&tx_csp_apec&an.;
                    
                    Retr_Chom_secu&an._m&m.=(tr_css_c1_m&m.=1)*zsalbi&an._m&m.*(&&tx_css_vieil&an.+&&tx_css_vieil_tot&an.)
                        +(tr_css_c1_m&m.=0)*&bsup_css_c1.*quot_sal_m&m.*(&&tx_css_vieil&an.+&&tx_css_vieil_tot&an.)
                        +min(zsalbi&an._m&m.,&bsup_css_c1.*quot_sal_m&m.)*(&&tx_csp_vieil&an.+&&tx_csp_vieil_tot&an.);
                    Retr_Chom_sal&an._m&m.= sum(Retr_Chom_secu&an._m&m.,
                        Unedic_sal&an._m&m., Unedic_pat&an._m&m., agirc_sal&an._m&m., agirc_pat&an._m&m.,
                        cet_sal&an._m&m., cet_pat&an._m&m., agff_sal&an._m&m., agff_pat&an._m&m., 
                        apec_sal&an._m&m., apec_pat&an._m&m.); 
                end;    

		/** Non cadres **/    
                if cadre=0 then do;
                /*Les salariés des entreprises publiques ne cotisent pas pour le chômage, on soustrait donc le taux de cotisation chômage (plafonné à 4P) 
                du taux de cotisation total pour ces salariés.
                Dans la suite du code on remplace les macros variables &&tx_css par des variables*/
                    tx_css_nc1_&an.=&&tx_css_nc1_&an.-&&tx_css_assedic&an.*salarie_EN;
                    tx_css_nc2_&an.=&&tx_css_nc2_&an.-&&tx_css_assedic&an.*salarie_EN;
                    tx_css_nc3_&an.=&&tx_css_nc3_&an.-&&tx_css_assedic&an.*salarie_EN;


                    /*TR_CSS_NCi : tranche de cotisations pour les non cadres, i=1,...,4 */
                    tr_css_nc1_m&m.=(&binf_css_nc1.*quot_sal_m&m.<=zsalbi&an._m&m.<&bsup_css_nc1.*quot_sal_m&m.);
                    tr_css_nc2_m&m.=(&binf_css_nc2.*quot_sal_m&m.<=zsalbi&an._m&m.<&bsup_css_nc2.*quot_sal_m&m.);
                    tr_css_nc3_m&m.=(&binf_css_nc3.*quot_sal_m&m.<=zsalbi&an._m&m.<&bsup_css_nc3.*quot_sal_m&m.);
                    tr_css_nc4_m&m.=(&binf_css_nc4.*quot_sal_m&m.<=zsalbi&an._m&m.<&bsup_css_nc4.*quot_sal_m&m.);

                    /*CSS_SAL_Mm : cotisations sociales salariales sur les salaires au mois m*/
                    CSS_sal&an._m&m.=(tr_css_nc1_m&m.=1)*zsalbi&an._m&m.*tx_css_nc1_&an.
                        +(tr_css_nc2_m&m.=1)*(zsalbi&an._m&m.-quot_sal_m&m.*&binf_css_nc2.)*tx_css_nc2_&an.
                        +(tr_css_nc3_m&m.=1)*(zsalbi&an._m&m.-quot_sal_m&m.*&binf_css_nc3.)*tx_css_nc3_&an.
                        +(tr_css_nc4_m&m.=1)*(zsalbi&an._m&m.-quot_sal_m&m.*&binf_css_nc4.)*&&tx_css_nc4_&an.
                        +(tr_css_nc2_m&m.+tr_css_nc3_m&m.+tr_css_nc4_m&m.=1)*(&bsup_css_nc1.-&binf_css_nc1.)*quot_sal_m&m.*tx_css_nc1_&an.
                        +(tr_css_nc3_m&m.+tr_css_nc4_m&m.=1)*(&bsup_css_nc2.-&binf_css_nc2.)*quot_sal_m&m.*tx_css_nc2_&an.
                        +(tr_css_nc4_m&m.=1)*(&bsup_css_nc3.-&binf_css_nc3.)*quot_sal_m&m.*tx_css_nc3_&an.;
                    CSecu_sal&an._m&m.=zsalbi&an._m&m.*(&&tx_css_mmdi&an.)+
                        min(zsalbi&an._m&m.,&bsup_css_nc1.*quot_sal_m&m.)*(&&tx_css_vieil&an.+&&tx_css_vieil_tot&an.)
                        +max(zsalbi&an._m&m.-&bsup_css_nc1.*quot_sal_m&m.,0)*&&tx_css_vieil_tot&an.; 
                    Unedic_sal&an._m&m.=((tr_css_nc1_m&m.+tr_css_nc2_m&m.=1)*zsalbi&an._m&m.*&&tx_css_assedic&an.
                        +(tr_css_nc1_m&m.+tr_css_nc2_m&m.=0)*&bsup_css_nc3.*quot_sal_m&m.*&&tx_css_assedic&an.)*(1-salarie_EN);
                    arrco_sal&an._m&m.=(tr_css_nc1_m&m.=1)*zsalbi&an._m&m.*&&tx_css_ret1&an.+(tr_css_nc1_m&m.=0)*&bsup_css_nc1.*quot_sal_m&m.*&&tx_css_ret1&an.
                        +(tr_css_nc1_m&m.=0)*(tr_css_nc2_m&m=0)*(zsalbi&an._m&m.-quot_sal_m&m.*&bsup_css_nc1.)*&&tx_css_ret2&an.
                        +(tr_css_nc2_m&m=1)*quot_sal_m&m.*(&binf_css_nc2.-&bsup_css_nc1.)*&&tx_css_ret2&an.;
                    agff_sal&an._m&m.=(tr_css_nc1_m&m.=1)*zsalbi&an._m&m.*&&tx_css_agff_nc1&an.+(tr_css_nc1_m&m.=0)*&bsup_css_nc1.*quot_sal_m&m.*&&tx_css_agff_nc1&an.
                        +(tr_css_nc1_m&m.=0)*(tr_css_nc2_m&m=0)*quot_sal_m&m.*(&bsup_css_nc2.-&bsup_css_nc1.)*&&tx_css_agff_nc2&an.
                        +(tr_css_nc2_m&m=1)*(zsalbi&an._m&m.-quot_sal_m&m.*&bsup_css_nc1.)*&&tx_css_agff_nc2&an.;

                    /*CSS_PAT_Mm : cotisations sociales patronales sur les salaires au mois m*/
                    CSS_pat&an._m&m.=(tr_css_nc1_m&m.=1)*zsalbi&an._m&m.*&&tx_csp_nc1_&an.
                        +(tr_css_nc2_m&m.=1)*(zsalbi&an._m&m.-quot_sal_m&m.*&binf_css_nc2.)*&&tx_csp_nc2_&an.
                        +(tr_css_nc3_m&m.=1)*(zsalbi&an._m&m.-quot_sal_m&m.*&binf_css_nc3.)*&&tx_csp_nc3_&an.
                        +(tr_css_nc4_m&m.=1)*(zsalbi&an._m&m.-quot_sal_m&m.*&binf_css_nc4.)*&&tx_csp_nc4_&an.
                        +(tr_css_nc2_m&m.+tr_css_nc3_m&m.+tr_css_nc4_m&m.=1)*(&bsup_css_nc1.-&binf_css_nc1.)*quot_sal_m&m.*&&tx_csp_nc1_&an.
                        +(tr_css_nc3_m&m.+tr_css_nc4_m&m.=1)*(&bsup_css_nc2.-&binf_css_nc2.)*quot_sal_m&m.*&&tx_csp_nc2_&an.
                        +(tr_css_nc4_m&m.=1)*(&bsup_css_nc3.-&binf_css_nc3.)*quot_sal_m&m.*&&tx_csp_nc3_&an.
                                                +(TailEnt='1')*(&&tx_csp_m10sal1&an.*min(zsalbi&an._m&m.,quot_sal_m&m.*&binf_css_c2.)
                                        +&&tx_csp_m10sal2&an.*max(0,zsalbi&an._m&m.-quot_sal_m&m.*&binf_css_c2.))
                        +(TailEnt ='2')*(&&tx_csp_10a20sal1&an.*min(zsalbi&an._m&m.,quot_sal_m&m.=&binf_css_c2.)
                                        +&&tx_csp_10a20sal2&an.*max(0,zsalbi&an._m&m. - quot_sal_m&m.*&binf_css_c2.))
                        +(TailEnt ='3')*&&tx_csp_p20sal&an.*zsalbi&an._m&m.;
                    CSecu_pat&an._m&m.=zsalbi&an._m&m.*(&&tx_csp_mmdi&an.+&&tx_csp_solauto&an.+&&tx_csp_AF&an.+&&tx_csp_ATMP&an.)
                        +min(zsalbi&an._m&m.,&bsup_css_nc1.*quot_sal_m&m.)*(&&tx_csp_vieil&an.+&&tx_csp_vieil_tot&an.)
                        +max(zsalbi&an._m&m.-&bsup_css_nc1.*quot_sal_m&m.,0)*&&tx_csp_vieil_tot&an.; 
                    Unedic_pat&an._m&m.=((tr_css_nc1_m&m.+tr_css_nc2_m&m.=1)*zsalbi&an._m&m.*&&tx_csp_assedic&an.
                        +(tr_css_nc1_m&m.+tr_css_nc2_m&m.=0)*&bsup_css_nc3.*quot_sal_m&m.*&&tx_csp_assedic&an.)*(1-salarie_EN);
                    arrco_pat&an._m&m.=(tr_css_nc1_m&m.=1)*zsalbi&an._m&m.*&&tx_csp_ret1&an.+(tr_css_nc1_m&m.=0)*&bsup_css_nc1.*quot_sal_m&m.*&&tx_csp_ret1&an.
                        +(tr_css_nc1_m&m.=0)*(tr_css_nc2_m&m=0)*(zsalbi&an._m&m.-quot_sal_m&m.*&bsup_css_nc1.)*&&tx_csp_ret2&an.
                        +(tr_css_nc2_m&m=1)*quot_sal_m&m.*(&binf_css_nc2.-&bsup_css_c1.)*&&tx_csp_ret2&an.;
                    agff_pat&an._m&m.=(tr_css_nc1_m&m.=1)*zsalbi&an._m&m.*&&tx_csp_agff_nc1&an.+(tr_css_nc1_m&m.=0)*&bsup_css_nc1.*quot_sal_m&m.*&&tx_csp_agff_nc1&an.
                        +(tr_css_nc1_m&m.=0)*(tr_css_nc2_m&m=0)*quot_sal_m&m.*(&bsup_css_nc2.-&bsup_css_nc1.)*&&tx_csp_agff_nc2&an.
                        +(tr_css_nc2_m&m=1)*(zsalbi&an._m&m.-quot_sal_m&m.*&bsup_css_nc1.)*&&tx_csp_agff_nc2&an.;


                    Retr_Chom_secu&an._m&m.=(tr_css_nc1_m&m.=1)*zsalbi&an._m&m.*(&&tx_css_vieil&an.+&&tx_css_vieil_tot&an.)
                        +(tr_css_nc1_m&m.=0)*&bsup_css_nc1.*quot_sal_m&m.*(&&tx_css_vieil&an.+&&tx_css_vieil_tot&an.)
                        +min(zsalbi&an._m&m.,&bsup_css_nc1.*quot_sal_m&m.)*(&&tx_csp_vieil&an.+&&tx_csp_vieil_tot&an.);
                    Retr_Chom_sal&an._m&m.=sum(Retr_Chom_secu&an._m&m.,
                        Unedic_sal&an._m&m., Unedic_pat&an._m&m., arrco_sal&an._m&m., arrco_pat&an._m&m.,
                        agff_sal&an._m&m., agff_pat&an._m&m.); 
                    end;    
                
                /*Allègements généraux*/
                if zsalbi&an._m&m.>0 then do;
                    tx_allg&an._m&m.=((TailEnt in('1','2'))*&&tx_allg_m20sal&an.+(TailEnt ='3')*&&tx_allg_p20sal&an.)
                        *min(max((&&plaf_allg&an.*&&smic_hor_brut&an.*151.7*quot_sal_m&m.)/zsalbi&an._m&m.-1,0),0.6)/(&&plaf_allg&an.-1);
                end;
                else do;
                    tx_allg&an._m&m.=0;
                end;
                CSS_pat&an._m&m.=CSS_pat&an._m&m.-(tx_allg&an._m&m.*zsalbi&an._m&m.);
                CSecu_pat&an._m&m.=CSecu_pat&an._m&m.-(tx_allg&an._m&m.*zsalbi&an._m&m.);
                Allegement&an._m&m.=(tx_allg&an._m&m.*zsalbi&an._m&m.);
               
                if (CSecu_pat&an._m&m.+CSecu_sal&an._m&m.)>0 then Retr_Chom_sal&an._m&m.=Retr_Chom_sal&an._m&m.-Allegement&an._m&m.*Retr_Chom_secu&an._m&m./(CSecu_pat&an._m&m.+CSecu_sal&an._m&m.);
                    else Retr_Chom_sal&an._m&m.=0;/*pas d'allègement dans ce cas-là*/
       
                /*Allègement du taux de cotisations famille jusqu'à 1,6 Smic*/
              	%if &an.>=15 %then %do ;
                   if 0<zsalbi&an._m&m.<=&&smic_hor_brut&an.*151.7*quot_sal_m&m.*&&plaf_af_bas_salaires&an.
                   then CSecu_pat&an._m&m.=CSecu_pat&an._m&m.-(&&tx_csp_AF&an.-&&tx_csp_AF_bas_salaires&an.)*zsalbi&an._m&m.;
              	%end;


                /*CSG et CRDS*/
                CSGd_sal&an._m&m.=min(zsalbi&an._m&m.,quot_sal_m&m.*&binf_css_c3.)*&&ass_csg_sal&an.*&&tx_csgd_sal&an.
                    +max(zsalbi&an._m&m.-quot_sal_m&m.*&binf_css_c3.,0)*&&tx_csgd_sal&an.;
                CSGi_sal&an._m&m.=min(zsalbi&an._m&m.,quot_sal_m&m.*&binf_css_c3.)*&&ass_csg_sal&an.*&&tx_csgi_sal&an.
                    +max(zsalbi&an._m&m.-quot_sal_m&m.*&binf_css_c3.,0)*&&tx_csgi_sal&an.;
                CRDS_sal&an._m&m.=min(zsalbi&an._m&m.,quot_sal_m&m.*&binf_css_c3.)*&&ass_csg_sal&an.*&&tx_crds_sal&an.
                    +max(zsalbi&an._m&m.-quot_sal_m&m.*&binf_css_c3.,0)*&&tx_crds_sal&an.;

                /*ZSALPI_Mm : salaire net perçu au mois m*/
                zsalpi&an._m&m.=sum(zsalbi&an._m&m., -CSGd_sal&an._m&m., -CSGi_sal&an._m&m., -CRDS_sal&an._m&m., -css_sal&an._m&m.);
                


            end;
        %end;
        %mend;
        %mens;

        /*ZSALPI_Ti : salaire net perçu au trimestre i*/
        zsalpi&an._t1=max(0,sum(zsalpi&an._m1,zsalpi&an._m2,zsalpi&an._m3));
        zsalpi&an._t2=max(0,sum(zsalpi&an._m4,zsalpi&an._m5,zsalpi&an._m6));
        zsalpi&an._t3=max(0,sum(zsalpi&an._m7,zsalpi&an._m8,zsalpi&an._m9));
        zsalpi&an._t4=max(0,sum(zsalpi&an._m10,zsalpi&an._m11,zsalpi&an._m12));

        zsalbi&an.=max(0,sum(of zsalbi&an._m:));
        zsalpi&an.=max(0,sum(of zsalpi&an._m:));
        CSGd_sal&an.=max(0,sum(of CSGd_sal&an._m:));
        CSGi_sal&an.=max(0,sum(of CSGi_sal&an._m:));
        CRDS_sal&an.=max(0,sum(of CRDS_sal&an._m:));
        CSG_sal&an.=sum(CSGd_sal&an.,CSGi_sal&an.);
        CSS_sal&an.=sum(of CSS_sal&an._m:);
        CSS_pat&an.=sum(of CSS_pat&an._m:);
        CSecu_sal&an.=sum(of CSecu_sal&an._m:);
        CSecu_pat&an.=sum(of CSecu_pat&an._m:);
        unedic_sal&an.=sum(of unedic_sal&an._m:);
        unedic_pat&an.=sum(of unedic_pat&an._m:);
        Retr_Chom_sal&an.=sum(of Retr_Chom_sal&an._m:);

        /*ZSALI : salaire imposable */
        zsali&an.=max(0,sum(zsalbi&an.,/*compl_sante&an.,*/-CSGd_sal&an.,-css_sal&an.)); 

    end;


    		/*** Cas des salariés du public ***/

    if zsali>0 & prive=0 then do; /*salarié du public*/

        /** Cas des agents titulaires (fonctionnaires) **/
        if titulaire=1 then do; 
            %macro temps;
            %do m=1 %to 12;
                if zsali&an._m&m.>0 then do;
                    CSS_sal&an._m&m.=zsalbi&an._m&m.*((1-&&tx_css_sol&an.)*(&&tx_css_pc&an.*(1-&&tx_prim&an.)
                        + &&tx_css_rafp&an.*min(&&tx_prim&an.,&&tx_css_rafp_max&an.*(1-&&tx_prim&an.)))+&&tx_css_sol&an.);
                    CSS_pat&an._m&m.=zsalbi&an._m&m.*(1-&&tx_prim&an.)*(&&tx_csp_af&an.+&&tx_csp_fnal_etat&an.+&&tx_csp_maladie_f&an.
                        +&&tx_csp_CEmaladie_f&an.+&&tx_css_rafp&an.*min(&&tx_prim&an./(1-&&tx_prim&an.),&&tx_css_rafp_max&an.)+(CHPUB='1' and CSTOT ne '53')*&&tx_csp_pc_etat&an.
                        +(CHPUB ne '1' and CSTOT ne '53')*&&tx_csp_pc_apul&an.+(CSTOT='53')*&&tx_csp_pc_mili&an.)
                        +min(zsalbi&an._m&m.,&bsup_css_nc1.)*( &&tx_csp_CEAT&an.);
                    CSecu_pat&an._m&m.=zsalbi&an._m&m.*(1-&&tx_prim&an.)*(&&tx_csp_af&an.+&&tx_csp_maladie_f&an.+&&tx_csp_CEmaladie_f&an.)
                        +min(zsalbi&an._m&m.,&bsup_css_nc1.)*(&&tx_csp_CEAT&an.);
                    Retr_Chom_sal&an._m&m.=zsalbi&an._m&m.*((1-&&tx_css_sol&an.)*(&&tx_css_pc&an.*(1-&&tx_prim&an.)
                        +&&tx_css_rafp&an.*min(&&tx_prim&an.,&&tx_css_rafp_max&an.*(1-&&tx_prim&an.))))
                        +zsalbi&an._m&m.*(1-&&tx_prim&an.)*(&&tx_css_rafp&an.*min(&&tx_prim&an./(1-&&tx_prim&an.),&&tx_css_rafp_max&an.)
                        +(CHPUB='1' and CSTOT ne '53')*&&tx_csp_pc_etat&an.+(CHPUB ne '1' and CSTOT ne '53')*&&tx_csp_pc_apul&an.
                        +(CSTOT='53')*&&tx_csp_pc_mili&an.) + min(zsalbi&an._m&m.,&bsup_css_nc1.)*(&&tx_csp_CEAT&an.);

                    /*CSG et CRDS*/
                    CSGd_sal&an._m&m.=min(zsalbi&an._m&m.,quot_sal_m&m.*&binf_css_c3.)*&&ass_csg_sal&an.*&&tx_csgd_sal&an.
                        +max(zsalbi&an._m&m.-quot_sal_m&m.*&binf_css_c3.,0)*&&tx_csgd_sal&an.;
                    CSGi_sal&an._m&m.=min(zsalbi&an._m&m.,quot_sal_m&m.*&binf_css_c3.)*&&ass_csg_sal&an.*&&tx_csgi_sal&an.
                        +max(zsalbi&an._m&m.-quot_sal_m&m.*&binf_css_c3.,0)*&&tx_csgi_sal&an.;
                    CRDS_sal&an._m&m.=min(zsalbi&an._m&m.,quot_sal_m&m.*&binf_css_c3.)*&&ass_csg_sal&an.*&&tx_crds_sal&an.
                        +max(zsalbi&an._m&m.-quot_sal_m&m.*&binf_css_c3.,0)*&&tx_crds_sal&an.;

					/*ZSALPI_Mm : salaire net perçu  au mois m*/
                    zsalpi&an._m&m.=sum(zsalbi&an._m&m., -CSGd_sal&an._m&m., -CSGi_sal&an._m&m., -CRDS_sal&an._m&m., -CSS_sal&an._m&m.);
                end;
            %end;
            %mend;
            %temps;

            /*ZSALPI_Ti : salaire net perçu  au trimestre i*/
            zsalpi&an._t1=max(0,sum(zsalpi&an._m1,zsalpi&an._m2,zsalpi&an._m3));
            zsalpi&an._t2=max(0,sum(zsalpi&an._m4,zsalpi&an._m5,zsalpi&an._m6));
            zsalpi&an._t3=max(0,sum(zsalpi&an._m7,zsalpi&an._m8,zsalpi&an._m9));
            zsalpi&an._t4=max(0,sum(zsalpi&an._m10,zsalpi&an._m11,zsalpi&an._m12));

            zsalbi&an.=max(0,sum(of zsalbi&an._m:));
            zsalpi&an.=max(0,sum(of zsalpi&an._m:));
            CSGd_sal&an.=max(0,sum(of CSGd_sal&an._m:));
            CSGi_sal&an.=max(0,sum(of CSGi_sal&an._m:));
            CRDS_sal&an.=max(0,sum(of CRDS_sal&an._m:));
            CSG_sal&an.=sum(CSGd_sal&an.,CSGi_sal&an.);
            CSS_sal&an.=sum(of CSS_sal&an._m:);
            CSS_pat&an.=sum(of CSS_pat&an._m:);
            CSecu_pat&an.=sum(of CSecu_pat&an._m:);
            Retr_Chom_sal&an.=sum(of Retr_Chom_sal&an._m:);

            /*ZSALI : salaire imposable */
            zsali&an.=max(0,sum(zsalbi&an.,-CSGd_sal&an.,-css_sal&an.));
        
        end;


        /** Cas des agents non titulaires (contractuels) **/

        else if titulaire=0 then do; 
            %macro temps2;
            %do m=1 %to 12;
                if zsali&an._m&m.>0 then do;

                    /*TR_CSS_NTi : tranche de cotisations pour les non titulaires, i=1 à 2*/
                    tr_css_nt1_m&m.=(&binf_css_nc1.*quot_sal_m&m.<=zsalbi&an._m&m.<&bsup_css_nc1.*quot_sal_m&m.);
                    tr_css_nt2_m&m.=(&binf_css_nc2.*quot_sal_m&m.<=zsalbi&an._m&m.<&binf_css_c3.*quot_sal_m&m.);
                    tr_css_nt3_m&m.=(zsalbi&an._m&m.>=&binf_css_c3.*quot_sal_m&m.);

                    /*CSS_SAL_Mm : cotisations sociales salariales sur les salaires au mois m*/
                    CSS_sal&an._m&m.=(1-&&tx_css_sol&an.)*((tr_css_nt1_m&m.=1)*zsalbi&an._m&m.*&&tx_css_nt1_&an.
                            +(tr_css_nt1_m&m.=0)*(zsalbi&an._m&m.-quot_sal_m&m.*&binf_css_nc2.)*&&tx_css_nt2_&an.
                            +(tr_css_nt1_m&m.=0)*(&bsup_css_nc1.-&binf_css_nc1.)*quot_sal_m&m.*&&tx_css_nt1_&an.)+&&tx_css_sol&an.*zsalbi&an._m&m.;
                    csecu_sal&an._m&m.  = zsalbi&an._m&m.*(&&tx_css_mmdi&an.)
                    +min(zsalbi&an._m&m.,&bsup_css_nc1.*quot_sal_m&m.)*(&&tx_css_vieil&an.+&&tx_css_vieil_tot&an.)
                    +max(zsalbi&an._m&m.-&bsup_css_nc1.*quot_sal_m&m.,0)*&&tx_css_vieil_tot&an.;
                    CSS_pat&an._m&m.=zsalbi&an._m&m.*(&&tx_csp_mmdi&an.+&&tx_csp_solauto&an.+&&tx_csp_AF&an.+&&tx_csp_fnal_etat&an.)
                        +min(zsalbi&an._m&m.,&bsup_css_nc1.*quot_sal_m&m.)*((&&tx_csp_vieil&an.+&&tx_csp_vieil_tot&an.)+&&tx_csp_ircantec1&an.)
                        +min(max(zsalbi&an._m&m.-&bsup_css_c1.,0),(&bsup_css_c3.-&bsup_css_c1.)*quot_sal_m&m.)*&&tx_csp_ircantec2&an.; 
                    CSecu_pat&an._m&m.=zsalbi&an._m&m.*(&&tx_csp_mmdi&an.+&&tx_csp_solauto&an.+&&tx_csp_AF&an.)
                        +min(zsalbi&an._m&m.,&bsup_css_nc1.*quot_sal_m&m.)*(&&tx_csp_vieil&an.+&&tx_csp_vieil_tot&an.) 
                        +max(zsalbi&an._m&m.-&bsup_css_nc1.*quot_sal_m&m.,0)*&&tx_csp_vieil_tot&an.; 
                    Retr_Chom_sal&an._m&m.=(1-&&tx_css_sol&an.)*((tr_css_nt1_m&m.=1)*zsalbi&an._m&m.*&&tx_css_rc_nt1_&an.
                            +(tr_css_nt1_m&m.=0)*(zsalbi&an._m&m.-quot_sal_m&m.*&binf_css_nc2.)*&&tx_css_rc_nt2_&an.
                            +(tr_css_nt1_m&m.=0)*(&bsup_css_nc1.-&binf_css_nc1.)*quot_sal_m&m.*&&tx_css_rc_nt1_&an.)
                            +min(zsalbi&an._m&m.,&bsup_css_nc1.*quot_sal_m&m.)*((&&tx_csp_vieil&an.+&&tx_csp_vieil_tot&an.)+&&tx_csp_ircantec1&an.)
                            +min(max(zsalbi&an._m&m.-&bsup_css_c1.,0),(&bsup_css_c3.-&bsup_css_c1.)*quot_sal_m&m.)*&&tx_csp_ircantec2&an.;

                    /*CSG et CRDS*/
                    CSGd_sal&an._m&m.=min(zsalbi&an._m&m.,quot_sal_m&m.*&binf_css_c3.)*&&ass_csg_sal&an.*&&tx_csgd_sal&an.
                        +max(zsalbi&an._m&m.-quot_sal_m&m.*&binf_css_c3.,0)*&&tx_csgd_sal&an.;
                    CSGi_sal&an._m&m.=min(zsalbi&an._m&m.,quot_sal_m&m.*&binf_css_c3.)*&&ass_csg_sal&an.*&&tx_csgi_sal&an.
                        +max(zsalbi&an._m&m.-quot_sal_m&m.*&binf_css_c3.,0)*&&tx_csgi_sal&an.;
                    CRDS_sal&an._m&m.=min(zsalbi&an._m&m.,quot_sal_m&m.*&binf_css_c3.)*&&ass_csg_sal&an.*&&tx_crds_sal&an.
                        +max(zsalbi&an._m&m.-quot_sal_m&m.*&binf_css_c3.,0)*&&tx_crds_sal&an.;

                    /*ZSALPI_Mm : salaire net perçu  au mois m*/
                    zsalpi&an._m&m.=sum (zsalbi&an._m&m., -CSGd_sal&an._m&m., -CSGi_sal&an._m&m., -CRDS_sal&an._m&m., -CSS_sal&an._m&m.);
                end;
            %end;
            %mend;
            %temps2;

            /*ZSALPI_Ti : salaire net perçu  au trimestre i*/
            zsalpi&an._t1=max(0,sum(zsalpi&an._m1,zsalpi&an._m2,zsalpi&an._m3));
            zsalpi&an._t2=max(0,sum(zsalpi&an._m4,zsalpi&an._m5,zsalpi&an._m6));
            zsalpi&an._t3=max(0,sum(zsalpi&an._m7,zsalpi&an._m8,zsalpi&an._m9));
            zsalpi&an._t4=max(0,sum(zsalpi&an._m10,zsalpi&an._m11,zsalpi&an._m12));

            zsalbi&an.=max(0,sum(of zsalbi&an._m:));
            zsalpi&an.=max(0,sum(of zsalpi&an._m:));
            CSGd_sal&an.=max(0,sum(of CSGd_sal&an._m:));
            CSGi_sal&an.=max(0,sum(of CSGi_sal&an._m:));
            CRDS_sal&an.=max(0,sum(of CRDS_sal&an._m:));
            CSG_sal&an.=sum(CSGd_sal&an.,CSGi_sal&an.);
            CSS_sal&an.=sum(of CSS_sal&an._m:);
            CSS_pat&an.=sum(of CSS_pat&an._m:);
            CSecu_sal&an.=sum(of CSecu_sal&an._m:);
            CSecu_pat&an.=sum(of CSecu_pat&an._m:);
            Retr_Chom_sal&an.=sum(of Retr_Chom_sal&an._m:);

            /*ZSALI : salaire imposable */
        zsali&an.=max(0,sum(zsalbi&an.,-CSGd_sal&an.,-css_sal&an.)); 
        end;
    end;

    /*_1a : revenu agricole déclaré au niveau individuel en 2013*/
    /*On garde le montant déclaré pour appariement avec les données fiscales*/
     _1a=zragi&an.;



			/*** Cas des indépendants ***/

    	/** Revenus des non salariés agricoles ZRAGI **/
    if (zragi%sysevalf(&an.-1) ne 0) then do;
        if (CSTOT in ('11','12','13','71') and statut ne '13') then do; /*exploitants à titre principaux*/
            CSS_rag&an.=  max(zragi%sysevalf(&an.-1),&&ass_min_amexa&an.)*&&tx_css_amexa_princ&an.
                        + max(zragi%sysevalf(&an.-1),&&ass_min_inval&an.)*&&tx_css_inval&an.
                        + max(zragi%sysevalf(&an.-1),0)*&&tx_css_pfa&an. 
                        + min(max(zragi%sysevalf(&an.-1),&&ass_min_avi&an.),&&PSS&an.*12)*&&tx_css_avi&an.
                        + min(max(zragi%sysevalf(&an.-1),&&ass_min_ava&an.),&&PSS&an.*12)*&&tx_css_ava_plaf&an.
                        + max(zragi%sysevalf(&an.-1),&&ass_min_ava&an.)*&&tx_css_ava_deplaf&an. 
                        + max(zragi%sysevalf(&an.-1),&&ass_min_rco&an.)*&&tx_css_rco_&an.
                        + &&mt_css_atexa_cp_&an.;
            csecu_rag&an.=max(zragi%sysevalf(&an.-1),&&ass_min_amexa&an.)*&&tx_css_amexa_princ&an.
                        + max(zragi%sysevalf(&an.-1),&&ass_min_inval&an.)*&&tx_css_inval&an.
                        + max(zragi%sysevalf(&an.-1),0)*&&tx_css_pfa&an. 
                        + min(max(zragi%sysevalf(&an.-1),&&ass_min_avi&an.),&&PSS&an.*12)*&&tx_css_avi&an.
                        + min(max(zragi%sysevalf(&an.-1),&&ass_min_ava&an.),&&PSS&an.*12)*&&tx_css_ava_plaf&an.
                        + max(zragi%sysevalf(&an.-1),&&ass_min_ava&an.)*&&tx_css_ava_deplaf&an. +&&mt_css_atexa_cp_&an.;
            VIVEA&an.=min(max((zragi%sysevalf(&an.-1)+CSS_rag&an.)*&&tx_css_vivea_&an.,&&binf_vivea_&an.),&&bsup_vivea_&an.);
            Retr_Chom_rag&an.=min(max(zragi%sysevalf(&an.-1),&&ass_min_avi&an.),&&PSS&an.*12)*&&tx_css_avi&an.
                        + min(max(zragi%sysevalf(&an.-1),&&ass_min_ava&an.),&&PSS&an.*12)*&&tx_css_ava_plaf&an.
                        + max(zragi%sysevalf(&an.-1),&&ass_min_ava&an.)*&&tx_css_ava_deplaf&an. 
                        + max(zragi%sysevalf(&an.-1),&&ass_min_rco&an.)*&&tx_css_rco_&an.;

                /*Allègement du taux de cotisations famille*/
           		%if &an.>=15 %then %do ;
             			allg_af&an.=0;
            			 if 0<zragi%sysevalf(&an.-1)<=&&seuil_tx_af_red&an. then allg_af&an.=&&tx_exo_pfa_bas_revenus&an.*max(zragi%sysevalf(&an.-1),0);
			 			else if &&seuil_tx_af_red&an.<zragi%sysevalf(&an.-1)<=&&sortie_tx_af_red&an. then allg_af&an.=&&tx_exo_pfa_bas_revenus&an./
						(&&sortie_tx_af_red&an.-&&seuil_tx_af_red&an.)*(&&sortie_tx_af_red&an.-zragi%sysevalf(&an.-1))*max(zragi%sysevalf(&an.-1),0);
             			CSS_rag&an.=sum(CSS_rag&an.,-allg_af&an.);
             			csecu_rag&an.=sum(csecu_rag&an.,-allg_af&an.);
           		%end;

        end;

        else if (STATUT = '13' or STATUTS2='3') then do; /*aides familaux*/ 
            CSS_rag&an.=  min(&&tx_css_amexa_AF&an.*&&ass_min_amexa&an.*&&tx_css_amexa_princ&an.,&&plaf_amexa_AF&an.) /*montant minimum*/
                        + min(max(zragi%sysevalf(&an.-1),&&ass_min_avi&an.),&&PSS&an.*12)*&&tx_css_avi&an.
                        + min(max(zragi%sysevalf(&an.-1),&&ass_min_ava_AF&an.),&&PSS&an.*12)*&&tx_css_ava_plaf&an.
                        + &&mt_css_atexa_af_&an.;
            csecu_rag&an.=CSS_rag&an.;
            VIVEA&an.=&&binf_vivea_&an.;
            Retr_Chom_rag&an.=min(max(zragi%sysevalf(&an.-1),&&ass_min_avi&an.),&&PSS&an.*12)*&&tx_css_avi&an.
                        + min(max(zragi%sysevalf(&an.-1),&&ass_min_ava_AF&an.),&&PSS&an.*12)*&&tx_css_ava_plaf&an.;
        end;

        else do; /*exploitants à titre secondaire */
            CSS_rag&an.=  max(zragi%sysevalf(&an.-1),0)*&&tx_css_amexa_sec&an. + &&mt_css_amexa_sec_&an.
                        + max(zragi%sysevalf(&an.-1),0)*&&tx_css_inval&an. 
                        + max(zragi%sysevalf(&an.-1),0)*&&tx_css_pfa&an. 
                        + min(max(zragi%sysevalf(&an.-1),&&ass_min_avi&an.),&&PSS&an.*12)*&&tx_css_avi&an.
                        + min(max(zragi%sysevalf(&an.-1),&&ass_min_ava&an.),&&PSS&an.*12)*&&tx_css_ava_plaf&an.
                        + max(zragi%sysevalf(&an.-1),&&ass_min_ava&an.)*&&tx_css_ava_deplaf&an. 
                        + max(zragi%sysevalf(&an.-1),&&ass_min_rco&an.)*&&tx_css_rco_&an.
                        + &&mt_css_atexa_cs_&an.;
            csecu_rag&an.=max(zragi%sysevalf(&an.-1),0)*&&tx_css_amexa_sec&an. + &&mt_css_amexa_sec_&an.
                        + max(zragi%sysevalf(&an.-1),0)*&&tx_css_inval&an. 
                        + max(zragi%sysevalf(&an.-1),0)*&&tx_css_pfa&an. 
                        + min(max(zragi%sysevalf(&an.-1),&&ass_min_avi&an.),&&PSS&an.*12)*&&tx_css_avi&an.
                        + min(max(zragi%sysevalf(&an.-1),&&ass_min_ava&an.),&&PSS&an.*12)*&&tx_css_ava_plaf&an.
                        + max(zragi%sysevalf(&an.-1),&&ass_min_ava&an.)*&&tx_css_ava_deplaf&an.+&&mt_css_atexa_cs_&an.;
            VIVEA&an.=min(max((zragi%sysevalf(&an.-1)+CSS_rag&an.)*&&tx_css_vivea_&an.,&&binf_vivea_&an.),&&bsup_vivea_&an.);
            Retr_Chom_rag&an.=max(zragi%sysevalf(&an.-1),0)*&&tx_css_pfa&an. 
                        + min(max(zragi%sysevalf(&an.-1),&&ass_min_avi&an.),&&PSS&an.*12)*&&tx_css_avi&an.
                        + min(max(zragi%sysevalf(&an.-1),&&ass_min_ava&an.),&&PSS&an.*12)*&&tx_css_ava_plaf&an.
                        + max(zragi%sysevalf(&an.-1),&&ass_min_ava&an.)*&&tx_css_ava_deplaf&an. 
                        + max(zragi%sysevalf(&an.-1),&&ass_min_rco&an.)*&&tx_css_rco_&an.;

                /*Allégement du taux de cotisations famille*/
           		%if &an.>=15 %then %do ;
            			allg_af&an.=0;
             			if 0<zragi%sysevalf(&an.-1)<=&&seuil_tx_af_red&an. then allg_af&an.=&&tx_exo_pfa_bas_revenus&an.*max(zragi%sysevalf(&an.-1),0);
			 			else if &&seuil_tx_af_red&an.<zragi%sysevalf(&an.-1)<=&&sortie_tx_af_red&an. then allg_af&an.=&&tx_exo_pfa_bas_revenus&an./
						(&&sortie_tx_af_red&an.-&&seuil_tx_af_red&an.)*(&&sortie_tx_af_red&an.-zragi%sysevalf(&an.-1))*max(zragi%sysevalf(&an.-1),0);
             			CSS_rag&an.=sum(CSS_rag&an.,-allg_af&an.);
             			csecu_rag&an.=sum(csecu_rag&an.,-allg_af&an.);
          		 %end;
        end;


        CSGd_rag&an.=max(sum(zragi%sysevalf(&an.-1),CSS_rag&an.)*&&tx_csgd_sal&an.,0);
        CSGi_rag&an.=max(sum(zragi%sysevalf(&an.-1),CSS_rag&an.)*&&tx_csgi_sal&an.,0);
        CSG_rag&an.=sum(CSGd_rag&an.,CSGi_rag&an.);
        CRDS_rag&an.=max(sum(zragi%sysevalf(&an.-1),CSS_rag&an.)*&&tx_crds_sal&an.,0);

        zragi&an.=sum(zragbi&an., -CSS_rag&an., -CSGd_rag&an.); 
        zragpi&an. = sum(zragi&an., -CSGi_rag&an., -CRDS_rag&an., - VIVEA&an.);

        %macro mens;            
            nbm_indep=(zragi_m1 ne 0)+(zragi_m2 ne 0)+(zragi_m3 ne 0)+(zragi_m4 ne 0)+(zragi_m5 ne 0)+(zragi_m6 ne 0)+(zragi_m7 ne 0)+(zragi_m8 ne 0)+(zragi_m9 ne 0)+(zragi_m10 ne 0)+(zragi_m11 ne 0)+(zragi_m12 ne 0);
            if nbm_indep=0 then nbm_indep=12;
            %do m=1 %to 12;
                zragbi&an._m&m.=(zragi_m&m. ne 0)*zragbi&an./nbm_indep;
                zragpi&an._m&m.=(zragi_m&m. ne 0)*zragpi&an./nbm_indep;
            %end;
        %mend;
        %mens;


        	/*ZragPI_Ti : salaire net perçu au trimestre i*/
            zragpi&an._t1=max(0,sum(zragpi&an._m1,zragpi&an._m2,zragpi&an._m3));
            zragpi&an._t2=max(0,sum(zragpi&an._m4,zragpi&an._m5,zragpi&an._m6));
            zragpi&an._t3=max(0,sum(zragpi&an._m7,zragpi&an._m8,zragpi&an._m9));
            zragpi&an._t4=max(0,sum(zragpi&an._m10,zragpi&an._m11,zragpi&an._m12));
    end;    

    

		/** Revenus des industriels et commerciaux **/
    /*_1i : revenus industriels et commerciaux déclarés au niveau individuel en 2013*/
    /*On garde le montant déclaré pour appariement avec les données fiscales*/
     _1i=zrici&an.; 

    /*Assiette des cotisations en N : Revenus N-1*/
    /*Revenus des non salariés industriels et commerciaux ZRICI*/


     if (ZRICI&an. ne 0) then do; 	/*CS '21' artisans et '22' commerçants et assimilés*/

        maladie_rsi_ic_&an.=(&&tx_css_canam1&an.-&&tx_css_canam2&an.*max(0,(1-max(zrici%sysevalf(&an.-1),0)/(&&seuil_css_canam&an.*12*&&PSS&an.)))
                            )*max(zrici%sysevalf(&an.-1), &&ass_min_canam&an.)
                            +&&tx_css_ij&an.*max(min(zrici%sysevalf(&an.-1),&&plaf_ij&an.), &&ass_min_ij&an.) ; 
    
        vieillesse_ic_&an.=&&tx_css_rco1_ic&an.*max(min(zrici%sysevalf(&an.-1),&&plaf_rco1_ic&an.),&&ass_min_rcoi&an.)
            +&&tx_css_rco2_ic&an.*min(max(zrici%sysevalf(&an.-1)-&&plaf_rco1_ic&an.,0),(&&plaf_rco2_ic&an.-&&plaf_rco1_ic&an.));

        if cstot='21' then do;		/*artisans*/
            CSS_ric&an.=maladie_rsi_ic_&an.
                        +&&tx_css_af_i&an.*max(zrici%sysevalf(&an.-1),0)
                        +&&tx_css_fp_art&an.*12*&&PSS&an.
                        +&&tx_css_rsi1_&an.*max(Min(zrici%sysevalf(&an.-1),12*&&PSS&an.),&&ass_min_rsi&an.)
                        +&&tx_css_rsi_deplaf&an.* max(zrici%sysevalf(&an.-1),&&ass_min_rsi&an.)
                        +vieillesse_ic_&an.
                        +&&tx_css_inv_art&an.*max(Min(zrici%sysevalf(&an.-1),12*&&PSS&an.),&&ass_min_inv&an.);
            CSecu_ric&an.=  maladie_rsi_ic_&an.
                        +&&tx_css_af_i&an.*max(zrici%sysevalf(&an.-1),0)
                        +&&tx_css_rsi1_&an.*max(Min(zrici%sysevalf(&an.-1),12*&&PSS&an.),&&ass_min_rsi&an.)
                        +&&tx_css_rsi_deplaf&an.* max(zrici%sysevalf(&an.-1), &&ass_min_rsi&an.)
                        +&&tx_css_inv_art&an.*max(Min(zrici%sysevalf(&an.-1),12*&&PSS&an.),&&ass_min_inv&an.);
            Retr_Chom_ric&an.=&&tx_css_rsi1_&an.*max(Min(zrici%sysevalf(&an.-1),12*&&PSS&an.),&&ass_min_rsi&an.)
                        +&&tx_css_rsi_deplaf&an.* max(zrici%sysevalf(&an.-1), &&ass_min_rsi&an.)
                        + vieillesse_ic_&an.;   
        end;

        else do; 	/*commerçants et autres*/
                CSS_ric&an.=maladie_rsi_ic_&an.
                        +&&tx_css_af_i&an.*max(zrici%sysevalf(&an.-1),0)
                        +&&tx_css_fp_i&an.*12*&&PSS&an.
                        +&&tx_css_rsi1_&an.*max(Min(zrici%sysevalf(&an.-1),12*&&PSS&an.),&&ass_min_rsi&an.)
                        +&&tx_css_rsi_deplaf&an.*max(zrici%sysevalf(&an.-1), &&ass_min_rsi&an.)
                        +vieillesse_ic_&an.
                        +&&tx_css_inv_com&an.*max(Min(zrici%sysevalf(&an.-1),12*&&PSS&an.),&&ass_min_inv&an.);  
                CSecu_ric&an.=  maladie_rsi_ic_&an.
                        +&&tx_css_af_i&an.*max(zrici%sysevalf(&an.-1),0)
                        +&&tx_css_rsi1_&an.*max(Min(zrici%sysevalf(&an.-1),12*&&PSS&an.),&&ass_min_rsi&an.)
                        +&&tx_css_rsi_deplaf&an.* max(zrici%sysevalf(&an.-1), &&ass_min_rsi&an.)
                        +&&tx_css_inv_com&an.*max(Min(zrici%sysevalf(&an.-1),12*&&PSS&an.),&&ass_min_inv&an.);
                Retr_Chom_ric&an.=&&tx_css_rsi1_&an.*max(Min(zrici%sysevalf(&an.-1),12*&&PSS&an.),&&ass_min_rsi&an.)
                        +&&tx_css_rsi_deplaf&an.* max(zrici%sysevalf(&an.-1), &&ass_min_rsi&an.)
                        +vieillesse_ic_&an.;    
        end;

        /*Allègement du taux de cotisations famille*/
             allg_af&an.=0;
             if 0<zrici%sysevalf(&an.-1)<=&&seuil_tx_af_red&an. then allg_af&an.=&&tx_exo_pfa_bas_revenus&an.*max(zrici%sysevalf(&an.-1),0);
             else if &&seuil_tx_af_red&an.<zrici%sysevalf(&an.-1)<=&&sortie_tx_af_red&an. then allg_af&an.=&&tx_exo_pfa_bas_revenus&an./
			(&&sortie_tx_af_red&an.-&&seuil_tx_af_red&an.)*(&&sortie_tx_af_red&an.-zrici%sysevalf(&an.-1))*max(zrici%sysevalf(&an.-1),0);
             CSS_ric&an.=sum(CSS_ric&an.,-allg_af&an.);
             CSecu_ric&an.=sum(CSecu_ric&an.,-allg_af&an.);


        CSGd_ric&an.=max(sum(zrici%sysevalf(&an.-1),CSS_ric&an.)*&&tx_csgd_sal&an.,0);
        CSGi_ric&an.=max(sum(zrici%sysevalf(&an.-1),CSS_ric&an.)*&&tx_csgi_sal&an.,0);
        CSG_ric&an. =sum(CSGd_ric&an.,CSGi_ric&an.);
        CRDS_ric&an.=max(sum(zrici%sysevalf(&an.-1),CSS_ric&an.)*&&tx_crds_sal&an.,0);

        zrici&an.=sum(zricbi&an., -CSS_ric&an., -CSGd_ric&an.);
        zricpi&an. = sum(zrici&an.,-CSGi_ric&an., -CRDS_ric&an.);

        %macro mens;            
            nbm_indep=(zrici_m1 ne 0)+(zrici_m2 ne 0)+(zrici_m3 ne 0)+(zrici_m4 ne 0)+(zrici_m5 ne 0)+(zrici_m6 ne 0)+(zrici_m7 ne 0)+(zrici_m8 ne 0)+(zrici_m9 ne 0)+(zrici_m10 ne 0)+(zrici_m11 ne 0)+(zrici_m12 ne 0);
            if nbm_indep=0 then nbm_indep=12;
            %do m=1 %to 12;
                zricbi&an._m&m.=(zrici_m&m. ne 0)*zricbi&an./nbm_indep;
                zricpi&an._m&m.=(zrici_m&m. ne 0)*zricpi&an./nbm_indep;
            %end;
        %mend;
        %mens;

        /*ZricPI_Ti : Salaire net perçu au trimestre i*/
            zricpi&an._t1=max(0,sum(zricpi&an._m1,zricpi&an._m2,zricpi&an._m3));
            zricpi&an._t2=max(0,sum(zricpi&an._m4,zricpi&an._m5,zricpi&an._m6));
            zricpi&an._t3=max(0,sum(zricpi&an._m7,zricpi&an._m8,zricpi&an._m9));
            zricpi&an._t4=max(0,sum(zricpi&an._m10,zricpi&an._m11,zricpi&an._m12));

    end; 


		/** Revenus non commerciaux **/

    /*_1n : Revenus non commerciaux déclarés au niveau individuel en 2013*/
    /*On garde le montant déclaré pour appariement avec les données fiscales*/
     _1n=zrnci&an.; 

     

     	/** Revenus des non salariés non commerciaux ZRNCI **/

    /*En cas de revenus négatifs --> montant forfaitaire*/ 
    if (ZRNCI%sysevalf(&an.-1) ne 0) then do; /*CS '31' prof° libérales et '35' '42' '43' '46'*/
      
        CSS_rnc&an.=    (&&tx_css_canam1&an.-&&tx_css_canam2&an.*max(0,(1-max(zrnci%sysevalf(&an.-1),0)/(&&seuil_css_canam&an.*12*&&PSS&an.)))
                        )*max(zrnci%sysevalf(&an.-1), &&ass_min_canam&an.) /*les professions libérales ne cotisent pas aux IJ*/
                        +&&tx_css_af_i&an.*max(zrnci%sysevalf(&an.-1),0)
                        +&&tx_css_fp_i&an.*12*&&PSS&an.
                        +&&tx_css_rsi2_&an.*max(min(zrnci%sysevalf(&an.-1),&&plaf_cnavpl1&an.),&&ass_min_rsi&an.)
                        +&&tx_css_rsi3_&an.*max(min(zrnci%sysevalf(&an.-1),&&plaf_cnavpl2&an.),&&ass_min_rsi&an.)
                        +&&tx_css_rco_lib&an.*max(zrnci%sysevalf(&an.-1),0)
                        +&&tx_css_inv_lib&an.*max(zrnci%sysevalf(&an.-1),0);
        
        CSecu_rnc&an.=  (&&tx_css_canam1&an.-&&tx_css_canam2&an.*max(0,(1-max(zrnci%sysevalf(&an.-1),0)/(&&seuil_css_canam&an.*12*&&PSS&an.)))
                        )*max(zrnci%sysevalf(&an.-1), &&ass_min_canam&an.) /*les professions libérales ne cotisent pas aux IJ*/
                        +&&tx_css_af_i&an.*max(zrnci%sysevalf(&an.-1),0)
                        +&&tx_css_rsi2_&an.*max(min(zrnci%sysevalf(&an.-1),&&plaf_cnavpl1&an.),&&ass_min_rsi&an.)
                        +&&tx_css_rsi3_&an.*max(min(zrnci%sysevalf(&an.-1),&&plaf_cnavpl2&an.),&&ass_min_rsi&an.)
                        +&&tx_css_inv_lib&an.*max(zrnci%sysevalf(&an.-1),0);
        Retr_Chom_rnc&an.=+&&tx_css_rsi2_&an.*max(min(zrnci%sysevalf(&an.-1),&&plaf_cnavpl1&an.),&&ass_min_rsi&an.)
                        +&&tx_css_rsi3_&an.*max(min(zrnci%sysevalf(&an.-1),&&plaf_cnavpl2&an.),&&ass_min_rsi&an.)
                        + &&tx_css_rco_lib&an.*max(zrnci%sysevalf(&an.-1),0);
                            

        /*Allègement du taux de cotisations famille*/
             allg_af&an.=0;
             if 0<zrnci%sysevalf(&an.-1)<=&&seuil_tx_af_red&an. then allg_af&an.=&&tx_exo_pfa_bas_revenus&an.*max(zrnci%sysevalf(&an.-1),0);
             else if &&seuil_tx_af_red&an.<zrnci%sysevalf(&an.-1)<=&&sortie_tx_af_red&an. then allg_af&an.=&&tx_exo_pfa_bas_revenus&an./
			(&&sortie_tx_af_red&an.-&&seuil_tx_af_red&an.)*(&&sortie_tx_af_red&an.-zrnci%sysevalf(&an.-1))*max(zrnci%sysevalf(&an.-1),0);
             CSS_rnc&an.=sum(CSS_rnc&an.,-allg_af&an.);
             CSecu_rnc&an.=sum(CSecu_rnc&an.,-allg_af&an.);
             af_nonsal_&an.=sum(af_nonsal_&an.,-allg_af&an.);


        CSGd_rnc&an.=max(sum(zrnci%sysevalf(&an.-1),CSS_rnc&an.)*&&tx_csgd_sal&an.,0);
        CSGi_rnc&an.=max(sum(zrnci%sysevalf(&an.-1),CSS_rnc&an.)*&&tx_csgi_sal&an.,0);
        CSG_rnc&an. =sum(CSGd_rnc&an.,CSGi_rnc&an.);
        CRDS_rnc&an.=max(sum(zrnci%sysevalf(&an.-1),CSS_rnc&an.)*&&tx_crds_sal&an.,0);

        zrnci&an. = sum(zrncbi&an., - CSS_rnc&an., - CSGd_rnc&an.);
        zrncpi&an. = sum(zrnci&an., -CSGi_rnc&an., -CRDS_rnc&an.);

        %macro mens;            
            nbm_indep=(zrnci_m1 ne 0)+(zrnci_m2 ne 0)+(zrnci_m3 ne 0)+(zrnci_m4 ne 0)+(zrnci_m5 ne 0)+(zrnci_m6 ne 0)+(zrnci_m7 ne 0)+(zrnci_m8 ne 0)+(zrnci_m9 ne 0)+(zrnci_m10 ne 0)+(zrnci_m11 ne 0)+(zrnci_m12 ne 0);
            if nbm_indep=0 then nbm_indep=12;
            %do m=1 %to 12;
                zrncbi&an._m&m.=(zrnci_m&m. ne 0)*zrncbi&an./nbm_indep;
                zrncpi&an._m&m.=(zrnci_m&m. ne 0)*zrncpi&an./nbm_indep;
            %end;
        %mend;
        %mens;

        /*ZrncPI_Ti : salaire net perçu au trimestre i*/
            zrncpi&an._t1=max(0,sum(zrncpi&an._m1,zrncpi&an._m2,zrncpi&an._m3));
            zrncpi&an._t2=max(0,sum(zrncpi&an._m4,zrncpi&an._m5,zrncpi&an._m6));
            zrncpi&an._t3=max(0,sum(zrncpi&an._m7,zrncpi&an._m8,zrncpi&an._m9));
            zrncpi&an._t4=max(0,sum(zrncpi&an._m10,zrncpi&an._m11,zrncpi&an._m12));

    end; 


/*************************************************************************************************************************************************************/
/*		d. Agrégats de revenus                                                   										                                     */
/*************************************************************************************************************************************************************/

	/*ZTSAI : traitements et salaires déclarés*/
    ztsai&an.=max(0,sum(zsali&an.,zchoi&an.));

    /*ZPERI : pensions*/
    zperi&an.=max(0,sum(zrsti&an.,zalri&an.,zrtoi&an.));

    /*REVINDED : revenus d'indépendant déclarés*/
    REVINDED&an.=sum(zragi&an.,zrici&an.,zrnci&an.,0);

    /*REVACTD : revenus d'activité déclarés*/
    REVACTD&an.=sum(zsali&an.,revinded&an.,0);

    /*REVINDEP : revenus d'indépendant perçus*/
    REVINDEP&an.=sum(zragpi&an.,zricpi&an.,zrncpi&an.,0);

    /*REVACTP : revenus d'activité perçus*/
    REVACTP&an.=sum(zsalpi&an.,revindep&an.,0);

    /*CSG*/
    CSG_act&an.=sum(CSG_sal&an.,CSG_rag&an.,CSG_ric&an.,CSG_rnc&an.);
    CSG_remp&an.=sum(CSG_rst&an.,CSG_cho&an.);

    /*CRDS*/
    CRDS_act&an.=sum(CRDS_sal&an.,CRDS_rag&an.,CRDS_ric&an.,CRDS_rnc&an.);
    CRDS_remp&an.=sum(CRDS_rst&an.,CRDS_cho&an.);

    /*CSS*/
    CSS_indep&an.=sum(CSS_rag&an.,CSS_ric&an.,CSS_rnc&an.);

    Retr_Chom_act&an.=sum(Retr_Chom_sal&an.,Retr_Chom_rag&an.,Retr_Chom_ric&an.,Retr_Chom_rnc&an.);

    /*REVACTP_Ti, REVINDEP_Ti :*/
    %macro trim;
    %do t=1 %to 4;
        revindep&an._t&t.=sum(zragpi&an._t&t.,zricpi&an._t&t.,zrncpi&an._t&t.,0);
        revactp&an._t&t.=sum(zsalpi&an._t&t.,revindep&an._t&t.,0);
    %end;
    %mend;
    %trim;

run;



/*************************************************************************************************************************************************************/
/*************************************************************************************************************************************************************/
/*                    								II. Modification des données fiscales (tables foyers)          											 */
/*************************************************************************************************************************************************************/
/*************************************************************************************************************************************************************/

/*************************************************************************************************************************************************************/
/*				1- Calcul des taux d'évolution des revenus        																							 */
/*************************************************************************************************************************************************************/

proc sort data=saphir.indivi&acour.; by ident&acour. noi; run;

	/*Première déclaration*/

data tx_evol1;
merge cotis&an. (keep = ident&acour. noi _1j zsali&an. _1p zchoi&an. _1s zrsti&an. _1a zragi&an. _1i zrici&an. _1n zrnci&an.) 
saphir.indivi&acour.(keep=ident&acour. noi declar1 fisc_sal fisc_cho fisc_rst fisc_rag fisc_ric fisc_rnc persfip in=a);
by ident&acour. noi;
if persfip="vous" then persfip="decl";
if fisc_sal="prob" then fisc_sal=persfip;
if fisc_cho="prob" then fisc_cho=persfip;
if fisc_rst="prob" then fisc_rst=persfip;
if fisc_rag="prob" then fisc_rag=persfip;
if fisc_ric="prob" then fisc_ric=persfip;
if fisc_rnc="prob" then fisc_rnc=persfip;

if fisc_sal="decl" then evol_sal_decl=zsali&an./_1j;
else if fisc_sal="conj" then evol_sal_conj=zsali&an./_1j;
else if fisc_sal="pac1" then evol_sal_pac1=zsali&an./_1j;
else if fisc_sal="pac2" then evol_sal_pac2=zsali&an./_1j;
if fisc_cho="decl" then evol_cho_decl=zchoi&an./_1p;
else if fisc_cho="conj" then evol_cho_conj=zchoi&an./_1p;
else if fisc_cho="pac1" then evol_cho_pac1=zchoi&an./_1p;
else if fisc_cho="pac2" then evol_cho_pac2=zchoi&an./_1p;
if fisc_rst="decl" then evol_rst_decl=zrsti&an./_1s;
else if fisc_rst="conj" then evol_rst_conj=zrsti&an./_1s;
else if fisc_rst="pac1" then evol_rst_pac1=zrsti&an./_1s;
else if fisc_rst="pac2" then evol_rst_pac2=zrsti&an./_1s;
if fisc_rag="decl" then evol_rag_decl=zragi&an./_1a;
else if fisc_rag="conj" then evol_rag_conj=zragi&an./_1a;
else if fisc_rag="pac1" then evol_rag_pac1=zragi&an./_1a;
if fisc_ric="decl" then evol_ric_decl=zrici&an./_1i;
else if fisc_ric="conj" then evol_ric_conj=zrici&an./_1i;
else if fisc_ric="pac1" then evol_ric_pac1=zrici&an./_1i;
if fisc_rnc="decl" then evol_rnc_decl=zrnci&an./_1n;
else if fisc_rnc="conj" then evol_rnc_conj=zrnci&an./_1n;
else if fisc_rnc="pac1" then evol_rnc_pac1=zrnci&an./_1n;
if a;
run;

proc means data=tx_evol1 noprint nway;
class declar1;
var evol_sal_decl evol_sal_conj evol_sal_pac1 evol_sal_pac2
evol_cho_decl evol_cho_conj evol_cho_pac1 evol_cho_pac2
evol_rst_decl evol_rst_conj evol_rst_pac1 evol_rst_pac2
evol_rag_decl evol_rag_conj evol_rag_pac1
evol_ric_decl evol_ric_conj evol_ric_pac1
evol_rnc_decl evol_rnc_conj evol_rnc_pac1;
output out=tx_evol1(drop=_TYPE_ _FREQ_) sum=;
run;

	/*Deuxième déclaration*/

data tx_evol2;
merge cotis&an. (keep = ident&acour. noi _1j zsali&an. _1p zchoi&an. _1s zrsti&an. _1a zragi&an. _1i zrici&an. _1n zrnci&an.) 
saphir.indivi&acour.(keep=ident&acour. noi declar2 fisc_sal2 fisc_cho2 fisc_rst2 fisc_rag2 fisc_ric2 fisc_rnc2 persfip2 in=a);
by ident&acour. noi;
if persfip2="vous" then persfip2="decl";
if fisc_sal2="prob" then fisc_sal2=persfip2;
if fisc_cho2="prob" then fisc_cho2=persfip2;
if fisc_rst2="prob" then fisc_rst2=persfip2;
if fisc_rag2="prob" then fisc_rag2=persfip2;
if fisc_ric2="prob" then fisc_ric2=persfip2;
if fisc_rnc2="prob" then fisc_rnc2=persfip2;

if fisc_sal2="decl" then evol_sal_decl=zsali&an./_1j;
else if fisc_sal2="conj" then evol_sal_conj=zsali&an./_1j;
else if fisc_sal2="pac1" then evol_sal_pac1=zsali&an./_1j;
else if fisc_sal2="pac2" then evol_sal_pac2=zsali&an./_1j;
if fisc_cho2="decl" then evol_cho_decl=zchoi&an./_1p;
else if fisc_cho2="conj" then evol_cho_conj=zchoi&an./_1p;
else if fisc_cho2="pac1" then evol_cho_pac1=zchoi&an./_1p;
else if fisc_cho2="pac2" then evol_cho_pac2=zchoi&an./_1p;
if fisc_rst2="decl" then evol_rst_decl=zrsti&an./_1s;
else if fisc_rst2="conj" then evol_rst_conj=zrsti&an./_1s;
else if fisc_rst2="pac1" then evol_rst_pac1=zrsti&an./_1s;
else if fisc_rst2="pac2" then evol_rst_pac2=zrsti&an./_1s;
if fisc_rag2="decl" then evol_rag_decl=zragi&an./_1a;
else if fisc_rag2="conj" then evol_rag_conj=zragi&an./_1a;
else if fisc_rag2="pac1" then evol_rag_pac1=zragi&an./_1a;
if fisc_ric2="decl" then evol_ric_decl=zrici&an./_1i;
else if fisc_ric2="conj" then evol_ric_conj=zrici&an./_1i;
else if fisc_ric2="pac1" then evol_ric_pac1=zrici&an./_1i;
if fisc_rnc2="decl" then evol_rnc_decl=zrnci&an./_1n;
else if fisc_rnc2="conj" then evol_rnc_conj=zrnci&an./_1n;
else if fisc_rnc2="pac1" then evol_rnc_pac1=zrnci&an./_1n;
if a;
run;

proc means data=tx_evol2 noprint nway;
class declar2;
var evol_sal_decl evol_sal_conj evol_sal_pac1 evol_sal_pac2
evol_cho_decl evol_cho_conj evol_cho_pac1 evol_cho_pac2
evol_rst_decl evol_rst_conj evol_rst_pac1 evol_rst_pac2
evol_rag_decl evol_rag_conj evol_rag_pac1
evol_ric_decl evol_ric_conj evol_ric_pac1
evol_rnc_decl evol_rnc_conj evol_rnc_pac1;
output out=tx_evol2(drop=_TYPE_ _FREQ_) sum=;
run;

%macro maj_case(var,evol);
if &evol. ne . then &var.=&var.*&evol.;
%mend;


/*************************************************************************************************************************************************************/
/*				2- Application des taux d'évolution aux tables fiscales																						 */
/*************************************************************************************************************************************************************/    

proc sort data=saphir.foyer&acour._r&an. out=foyer&acour._r&an.; by declar; run;

data foyer&acour._r&an.; set foyer&acour._r&an.; declar=compress(declar); run;

data scenario.foyer&acour._r&an. (drop = evol_sal_: evol_cho_: evol_rst_: evol_rag_: evol_ric_: evol_rnc_:);
merge foyer&acour._r&an. (in=a) tx_evol1(rename=(declar1=declar)) tx_evol2(rename=(declar2=declar));
by declar; 

/*Modification des valeurs de salaires*/
%maj_case(_1aj,evol_sal_decl);
%maj_case(_1bj,evol_sal_conj);
%maj_case(_1cj,evol_sal_pac1);
%maj_case(_1dj,evol_sal_pac2);
%maj_case(_1au,evol_sal_decl);
%maj_case(_1bu,evol_sal_conj);
%maj_case(_1cu,evol_sal_pac1);
%maj_case(_1du,evol_sal_pac2);
%maj_case(_1aq,evol_sal_decl);
%maj_case(_1bq,evol_sal_conj);
%maj_case(_8by,evol_sal_decl);
%maj_case(_8cy,evol_sal_conj);

/*Modification des valeurs de chômage*/
%maj_case(_1ap,evol_cho_decl);
%maj_case(_1bp,evol_cho_conj);
%maj_case(_1cp,evol_cho_pac1);
%maj_case(_1dp,evol_cho_pac2);

/*Modification des valeurs de retraite*/
%maj_case(_1as,evol_rst_decl);
%maj_case(_1bs,evol_rst_conj);
%maj_case(_1cs,evol_rst_pac1);
%maj_case(_1ds,evol_rst_pac2);

/*Modification des valeurs de revenus agricoles - hors forfait et auto-entrepreneur*/
%maj_case(_5hb,evol_rag_decl);
%maj_case(_5hh,evol_rag_decl);
%maj_case(_5hc,evol_rag_decl);
%maj_case(_5hi,evol_rag_decl);
%maj_case(_5hf,evol_rag_decl);
%maj_case(_5hl,evol_rag_decl);
%maj_case(_5hm,evol_rag_decl);
%maj_case(_5ib,evol_rag_conj);
%maj_case(_5ih,evol_rag_conj);
%maj_case(_5ic,evol_rag_conj);
%maj_case(_5ii,evol_rag_conj);
%maj_case(_5if,evol_rag_conj);
%maj_case(_5il,evol_rag_conj);
%maj_case(_5im,evol_rag_conj);
%maj_case(_5jb,evol_rag_pac1);
%maj_case(_5jh,evol_rag_pac1);
%maj_case(_5jc,evol_rag_pac1);
%maj_case(_5ji,evol_rag_pac1);
%maj_case(_5jf,evol_rag_pac1);
%maj_case(_5jl,evol_rag_pac1);
%maj_case(_5jm,evol_rag_pac1);

/*Modification des valeurs de revenus industriels et commerciaux - hors microentreprise et auto-entrepreneur*/
%maj_case(_5kb,evol_ric_decl);
%maj_case(_5kh,evol_ric_decl);
%maj_case(_5kc,evol_ric_decl);
%maj_case(_5ki,evol_ric_decl);
%maj_case(_5kd,evol_ric_decl);
%maj_case(_5kj,evol_ric_decl);
%maj_case(_5ha,evol_ric_decl);
%maj_case(_5ka,evol_ric_decl);
%maj_case(_5kf,evol_ric_decl);
%maj_case(_5kl,evol_ric_decl);
%maj_case(_5kg,evol_ric_decl);
%maj_case(_5km,evol_ric_decl);
%maj_case(_5qa,evol_ric_decl);
%maj_case(_5qj,evol_ric_decl);
%maj_case(_5ks,evol_ric_decl);
%maj_case(_5lb,evol_ric_conj);
%maj_case(_5lh,evol_ric_conj);
%maj_case(_5lc,evol_ric_conj);
%maj_case(_5li,evol_ric_conj);
%maj_case(_5ld,evol_ric_conj);
%maj_case(_5lj,evol_ric_conj);
%maj_case(_5ia,evol_ric_conj);
%maj_case(_5la,evol_ric_conj);
%maj_case(_5lf,evol_ric_conj);
%maj_case(_5ll,evol_ric_conj);
%maj_case(_5lg,evol_ric_conj);
%maj_case(_5lm,evol_ric_conj);
%maj_case(_5ra,evol_ric_conj);
%maj_case(_5rj,evol_ric_conj);
%maj_case(_5ls,evol_ric_conj);
%maj_case(_5mb,evol_ric_pac1);
%maj_case(_5mh,evol_ric_pac1);
%maj_case(_5mc,evol_ric_pac1);
%maj_case(_5mi,evol_ric_pac1);
%maj_case(_5md,evol_ric_pac1);
%maj_case(_5mj,evol_ric_pac1);
%maj_case(_5ja,evol_ric_pac1);
%maj_case(_5ma,evol_ric_pac1);
%maj_case(_5mf,evol_ric_pac1);
%maj_case(_5ml,evol_ric_pac1);
%maj_case(_5mg,evol_ric_pac1);
%maj_case(_5mm,evol_ric_pac1);
%maj_case(_5sa,evol_ric_pac1);
%maj_case(_5sj,evol_ric_pac1);
%maj_case(_5ms,evol_ric_pac1);

/*Modification des valeurs de revenus non commerciaux - hors autoentrepreneur et microBNC*/
%maj_case(_5qb,evol_rnc_decl);
%maj_case(_5qh,evol_rnc_decl);
%maj_case(_5qc,evol_rnc_decl);
%maj_case(_5qi,evol_rnc_decl);
%maj_case(_5qe,evol_rnc_decl);
%maj_case(_5qk,evol_rnc_decl);
%maj_case(_5ql,evol_rnc_decl);
%maj_case(_5qm,evol_rnc_decl);
%maj_case(_5tf,evol_rnc_decl);
%maj_case(_5ti,evol_rnc_decl);
%maj_case(_5rb,evol_rnc_conj);
%maj_case(_5rh,evol_rnc_conj);
%maj_case(_5rc,evol_rnc_conj);
%maj_case(_5ri,evol_rnc_conj);
%maj_case(_5re,evol_rnc_conj);
%maj_case(_5rk,evol_rnc_conj);
%maj_case(_5rl,evol_rnc_conj);
%maj_case(_5rm,evol_rnc_conj);
%maj_case(_5uf,evol_rnc_decl);
%maj_case(_5ui,evol_rnc_decl);
%maj_case(_5sb,evol_rnc_pac1);
%maj_case(_5sh,evol_rnc_pac1);
%maj_case(_5sc,evol_rnc_pac1);
%maj_case(_5si,evol_rnc_pac1);
%maj_case(_5se,evol_rnc_pac1);
%maj_case(_5sk,evol_rnc_pac1);
%maj_case(_5sl,evol_rnc_pac1);
%maj_case(_5vf,evol_rnc_decl);
%maj_case(_5vi,evol_rnc_decl);

if a;
run;

proc datasets library=work;delete tx_evol:;run;quit;
%mend;

%calculcotiz(an=&asuiv2.); /*2015*/
%calculcotiz(an=&asuiv3.); /*2016*/


/*************************************************************************************************************************************************************/
/*************************************************************************************************************************************************************/
/*              										III. Ajout des nouveaux revenus à MENAGE_PREST                        								 */
/*************************************************************************************************************************************************************/
/*************************************************************************************************************************************************************/

proc means data =cotis&asuiv3. noprint;
by ident&acour.;
var csecu_sal&asuiv3. CSecu_pat&asuiv3. CSecu_Cho&asuiv3. csecu_rnc&asuiv3. csecu_ric&asuiv3. csecu_rag&asuiv3.
CSS_pat&asuiv3. css_cho&asuiv3. CSS_indep&asuiv3. css_sal&asuiv3.
CSG_act&asuiv3. CSG_remp&asuiv3. CSG_rst&asuiv3. CRDS_act&asuiv3. CRDS_remp&asuiv3. Retr_Chom_act&asuiv3.;
output out=revi_men&asuiv3. (drop = _TYPE_ _FREQ_) 
sum(csecu_sal&asuiv3. CSecu_pat&asuiv3. CSecu_Cho&asuiv3. csecu_rnc&asuiv3. csecu_ric&asuiv3. csecu_rag&asuiv3.
CSS_pat&asuiv3. css_cho&asuiv3. CSS_indep&asuiv3. css_sal&asuiv3.
CSG_act&asuiv3. CSG_remp&asuiv3. CSG_rst&asuiv3. CRDS_act&asuiv3. CRDS_remp&asuiv3. Retr_Chom_act&asuiv3.)
=csecu_sal&asuiv3. CSecu_pat&asuiv3. CSecu_Cho&asuiv3. csecu_rnc&asuiv3. csecu_ric&asuiv3. csecu_rag&asuiv3.
CSS_pat&asuiv3. css_cho&asuiv3. CSS_indep&asuiv3. css_sal&asuiv3.
CSG_act&asuiv3. CSG_remp&asuiv3. CSG_rst&asuiv3. CRDS_act&asuiv3. CRDS_remp&asuiv3. Retr_Chom_act&asuiv3.;
run;

/*Ajout à la table MENAGE_SAPHIR*/
data scenario.menage_prest;
merge saphir.menage_saphir (keep = ident&acour. typmen21 typmen7 nb_uc acteu5pr wprm&asuiv4. zthabm&asuiv4. zsalm&asuiv4. zchom&asuiv4. zrstm&asuiv4. 
zragm&asuiv4. zricm&asuiv4. zrncm&asuiv4. zglom&asuiv4. zalrm&asuiv4. zrtom&asuiv4. zfonm&asuiv4. zvamm&asuiv4. zvalm&asuiv4. zetrm&asuiv4. zalvm&asuiv4. zracm&asuiv4. zdivm&asuiv4. zquom&asuiv4. produitfin&asuiv4. m_caahm&asuiv4. champm
acteu6prm acteu6prmcj zvamm&asuiv3. zvalm&asuiv3. m_caahm&asuiv3. nbind ageprm nbenfa18) 
revi_men&asuiv3.;
by ident&acour.;
run;



/*************************************************************************************************************************************************************/
/*************************************************************************************************************************************************************/
/*              											IV. Ajout des nouveaux revenus à INDIV_PREST              	       							     */
/*************************************************************************************************************************************************************/
/*************************************************************************************************************************************************************/

proc sort data=saphir.indiv_saphir; by ident&acour. noi; run;
proc sort data=cotis&asuiv2.; by ident&acour. noi; run;
proc sort data=cotis&asuiv3.; by ident&acour. noi; run;
data scenario.indiv_prest;
merge 
saphir.indiv_saphir (keep=ident&acour. noi noiprm age matri sexe acteu6 typmen21 noindiv persfip declar1 declar2 cs8cor
    zsali&asuiv4. zchoi&asuiv4. zrsti&asuiv4. zragi&asuiv4. zrici&asuiv4. zrnci&asuiv4. zalri&asuiv4. zrtoi&asuiv4. hs&asuiv4. quelfic mds noiper noimer naia mariage 
    deces divorce matri_fip noicon noienft: naim lprm rgmen agenq naiss_futur_a naiss_futur_m naiss_futur declarant forter acteu dv_fip sep_eec api_eec iso_fip zalri 
    zrtoi revpatm zalvm zalri&asuiv2. zrtoi&asuiv2. revpatm&asuiv2. zalvm&asuiv2. _1ak _1ai typmen7 
    colla collm collj nbind acteu6prm revpatm&asuiv4. zalvm&asuiv4. enceintep3 zsalo&asuiv3. zchoo&asuiv3. zrsto&asuiv3. zrago&asuiv3.
    zrico&asuiv3. zrnco&asuiv3. zsali&asuiv3. zchoi&asuiv3. zrsti&asuiv3. zragi&asuiv3. zrici&asuiv3. zrnci&asuiv3.
    salred agenq age5 forter revindep wprm&asuiv4. quot_sal ag cser dip11 retrai statut traj_actst traj_acttp aac adfdap amois ancentr elig_aah salaire_etr&asuiv4._t: produitfin&asuiv4. 
    salaire_etr&asuiv3._t: zalri&asuiv3. zrtoi&asuiv3. revpatm&asuiv3. zalvm&asuiv3. produitfin&asuiv3. zfonm&asuiv2. 
    nondic raistf dimtyp raisnrec raisnsou rabs rabs )
cotis&asuiv2.(keep=ident&acour. noi revactd&asuiv2. zchoi&asuiv2. ztsai&asuiv2. zperi&asuiv2. REVINDED&asuiv2.
    revactp&asuiv2._t: zchopi&asuiv2._t: zrstpi&asuiv2._t: zsalpi&asuiv2._t: zragpi&asuiv2._t: zricpi&asuiv2._t: zrncpi&asuiv2._t:
    revindep&asuiv2. revactp&asuiv2. zsali&asuiv2. zchoi&asuiv2. zrsti&asuiv2. zragi&asuiv2. zrici&asuiv2. zrnci&asuiv2.
    zsalbi&asuiv2. zchobi&asuiv2. zrstbi&asuiv2. zragbi&asuiv2. zricbi&asuiv2. zrncbi&asuiv2.
    zsalpi&asuiv2. zchopi&asuiv2. zrstpi&asuiv2. zragpi&asuiv2. zricpi&asuiv2. zrncpi&asuiv2. )
cotis&asuiv3.(keep=ident&acour. noi revactd&asuiv3. zchoi&asuiv3. ztsai&asuiv3. zperi&asuiv3. REVINDED&asuiv3.
    revactp&asuiv3._t: zchopi&asuiv3._t: zrstpi&asuiv3._t: zsalpi&asuiv3._t: zragpi&asuiv3._t: zricpi&asuiv3._t: zrncpi&asuiv3._t:
    revindep&asuiv3. revactp&asuiv3. zsali&asuiv3. zchoi&asuiv3. zrsti&asuiv3. zragi&asuiv3. zrici&asuiv3. zrnci&asuiv3.
    zsalbi&asuiv3. zchobi&asuiv3. zrstbi&asuiv3. zragbi&asuiv3. zricbi&asuiv3. zrncbi&asuiv3.
    zsalpi&asuiv3. zchopi&asuiv3. zrstpi&asuiv3. zragpi&asuiv3. zricpi&asuiv3. zrncpi&asuiv3.);
by ident&acour. noi;
run;



/*************************************************************************************************************************************************************/
/*************************************************************************************************************************************************************/
/* 												V. CSG, CRDS, Cotisations sociales sur les revenus du patrimoine 											 */
/*************************************************************************************************************************************************************/
/*************************************************************************************************************************************************************/

/* Fait en fin du programme d'impôt*/

/*************************************************************************************************************************************************************
**************************************************************************************************************************************************************

Ce logiciel est régi par la licence CeCILL V2.1 soumise au droit français et respectant les principes de diffusion des logiciels libres. 

Vous pouvez utiliser, modifier et/ou redistribuer ce programme sous les conditions de la licence CeCILL V2.1. 

Le texte complet de la licence CeCILL V2.1 est dans le fichier `LICENSE`.

Les paramètres de la législation socio-fiscale figurant dans les programmes 6, 7a et 7b sont régis par la « Licence Ouverte / Open License » Version 2.0.
**************************************************************************************************************************************************************
*************************************************************************************************************************************************************/

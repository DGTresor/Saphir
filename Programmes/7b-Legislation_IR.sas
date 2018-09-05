

/**************************************************************************************************************************************************************/
/*                              									  SAPHIR E2013 L2017                                  							          */
/*                                     									  PROGRAMME 7b                                         			     			      */
/*                     										Législation de l'impot sur le revenu															  */
/**************************************************************************************************************************************************************/


/**************************************************************************************************************************************************************/
/* Les impôts sont calculés au niveau du foyer fiscal, à partir des cases vieillies des déclarations fiscales de la table foyer. Pour les individus « non     */
/* appariés » un traitement particulier est réalisé à travers le calcul d’un impôt simplifié (programme 10).  												  */
/* L’impôt sur le revenu est calculé sur la base des déclarations d’impôt sur le revenu 2013 (ERFS 2013) en appliquant la législation en vigueur pour l’impôt */
/* sur le revenu. Les revenus considérés sont ceux de l'années N-1.																							  */
/*																																							  */
/* Contrairement aux autres transferts, l’unité de référence (foyer fiscal) n’est pas reconstruite : les foyers fiscaux retenus sont ceux qui correspondent   */	
/* aux déclarations fiscales de la DGFiP. La composition des foyers fiscaux, qui peut faire l'objet de stratégies d'optimisation, est donc celle de l'ERFS et */
/* n'est pas modifiée dans Saphir. Les déclarations fiscales contiennent des informations sur les crédits et réductions d'impôts (heures de travail, salaires */
/* versés pour les services à la personne...). Ces crédits et réductions d'impôts présents dans l'ERFS ne sont pas modifiés pour adapter les données à l'année */
/* voulue car les choix et comportement d'optimisation ne sont pas prévisibles. 																			  */
/*																																							  */
/* Ce programme définit les variables nécessaires à la reconstruction de la législation de l'impot sur le revenu 2016 sur les revenus 2015					  */
/**************************************************************************************************************************************************************/

%macro Parametres(evol_bareme);

    %global 

/**************************************************************************************************************************************************************/
/**************************************************************************************************************************************************************/
/*                       											I. Déclaration des paramètres 		                									  */
/**************************************************************************************************************************************************************/
/**************************************************************************************************************************************************************/ 

            switch_ppe
            switch_compl_sant
               
            csg_pla_ded csg_pla_ded_def
            csg_pat_ded csg_pat_ded_def
            csg_pla_nod
            csg_pat_nod

            switch_int switch_div switch_pv switch_av max_av_pfl quotient_pv creation_PFO taux_PFO_int taux_PFO_div
            
            nb_tranches  nb_enf_max
            maj_taux abat_taux pen_abat_taux
            bar_taux_1 bar_taux_2 bar_taux_3 bar_taux_4 bar_taux_5
            bar_seuil_1 bar_seuil_2 bar_seuil_3 bar_seuil_4 bar_seuil_5
            plaf_qf_1 plaf_qf_2 plaf_qf_3 plaf_qf_4 plaf_qf_5 plaf_qf_6

            demi_part_vieux  sofipeche_ded_taux

            sal_abat_max pen_abat_max sal_abat_min pen_abat_min cho_abat_min 
            auto_abat_min auto_ca_vente_plaf auto_ca_service_plaf auto_vente_abat auto_service_abat auto_nc_abat
            rcm_abat_taux rcm_abat_forf_1 rcm_abat_forf_2 av_seul_abat av_couple_abat

            ba_rev_plaf 
            pen_alim_max 
            age_frais_max
            gro_rep_plaf
            abat_spe_age_plaf_1 abat_spe_age_plaf_2 abat_spe_age_mont_1 abat_spe_age_mont_2 abat_spe_enf_marie


            plaf_decote_celib 
            plaf_decote_couple 
            pente_decote_celib
            pente_decote_couple
            sofica_plaf sofipeche_seul_plaf sofipeche_couple_plaf
            cap_pme_couple_plaf_1 cap_pme_seul_plaf_1 cap_pme_couple_plaf_2 cap_pme_seul_plaf_2
            aide_creat_reduc  aide_creat_majo_handi
            fcpi_couple_plaf fcpi_seul_plaf fip_couple_plaf fip_seul_plaf fip_couple_corse_plaf fip_seul_corse_plaf
            int_repr_couple_plaf int_repr_seul_plaf college_reduc
            lycee_reduc etab_sup_reduc diff_agri_seul_plaf 
            diff_agri_couple_plaf
            prest_divorce_plaf
            sal_dom_plaf sal_dom_enf_charge_majo sal_dom_plaf_max sal_dom_1ere_emb_plaf sal_dom_inv_plaf
            age_long_sejour_plaf
            inv_loc_01_seul_plaf inv_loc_01_couple_plaf inv_loc_0103_seul_plaf inv_loc_0103_couple_plaf inv_loc_04_seul_plaf inv_loc_04_couple_plaf
            rente_survie_plaf rente_survie_enf_charge_majo 
            foret_cot_plaf foret_acq_seul_plaf foret_trav_seul_plaf foret_contr_seul_plaf foret_acq_couple_plaf foret_trav_couple_plaf foret_contr_couple_plaf
            dons_difficult_plaf monu_hist_plaf cga_frais_adh_plaf
            inv_dom_plaf protect_nat_plaf rest_immo_plaf env_plaf 
            prev_risque_seul_plaf prev_risque_couple_plaf prev_risque_pac_majo
            div_50_seul_plaf div_50_couple_plaf
            gros_equip_seul_plaf gros_equip_couple_plaf gros_equip_majo 
            int_pret_etud_plaf int_empr_seul_plaf int_empr_charge_majo
            garde_enf_plaf garde_enf_alt_plaf
             
            seuil_perc_avt_restit 
            seuil_perc_apt_restit 
            seuil_restit 
            rv_m50_abat rv_m60_abat rv_m70_abat rv_p70_abat
            age_seuil
            micfonc_abat_taux

            InvMeuNonPro_taux1
            InvMeuNonPro_taux2
            InvMeuNonPro_taux3
            InvMeuNonPro_taux4
            InvMeuNonPro_plaf

            auto_vente_abat
            auto_service_abat
            auto_nc_abat
            age_seuil
            rv_m50_abat
            rv_m60_abat
            rv_m70_abat
            rv_p70_abat

            pv_mob_taux pv_mob_taux_entr pv_pro_taux

            pv_cap_risque_taux
            pv_dom_taux1
            pv_dom_taux2
            pv_pea_taux
            pv_titre_taux1
            pv_titre_taux2
            pv_titre_taux3

            dons_difficult_taux
            dons_utipub_taux
            dons_utipub_plaf

            cot_syndic_plaf
            cot_syndic_taux
            sal_dom_taux
            diff_agri_taux
            divorce_taux
            fcpi_taux
            fip_taux
            fip_corse_taux
            fip_dom_taux fip_couple_dom_plaf fip_seul_dom_plaf

            sofica_plaf_taux
            sofica_ded_taux1
            sofica_ded_taux2
            cap_pme_taux1 cap_pme_taux2 cap_pme_taux3
            reprise_soc_taux 
            foret_acq_taux foret_rep_taux foret_cot_taux foret_ass_taux
            age_long_sejour_taux
            rente_survie_taux
            inv_loc_taux1
            inv_loc_taux2
            inv_loc_trav_taux1 inv_loc_trav_taux2 inv_loc_trav_taux3 inv_loc_trav_taux4
            protect_nat_taux
            sofipeche_plaf_taux sofipeche_ded_taux

            monu_hist_taux

            OM_plaf
            OM_plaf2
            OM_plaf3
            OM_plaf_specif1
            OM_plaf_specif2
            OM_plaf_specif3
            OM_taux1
            OM_taux2
            OM_taux3
            OM_taux4
            OM_taux5
            OM_taux6
            OM_taux7
            OM_lim1
            OM_lim2
            OM_lim3

            qualenv_plaf

            duflot_plaf_dec
            duflot_taux1 
            duflot_taux2

            scl_plaf_dec
            scl_met_bbc_taux1
            scl_met_nonbbc_taux1
            scl_OM_taux1

            scl_met_bbc_taux2 
            scl_met_nonbbc_taux2
            scl_OM_taux2

            scl_met_bbc_taux3 
            scl_OM_taux3

            rest_immo_taux1 rest_immo_taux2 rest_immo_taux3 rest_immo_taux4 rest_immo_taux5
            pv_etrangeres_taux1 pv_etrangeres_taux2
            bien_cult_taux

            ci_qualenvir_taux1 ci_qualenvir_taux2 ci_qualenvir_taux3 ci_qualenvir_taux4 ci_qualenvir_taux5
          
            ci_aidepers_hab_taux1
            ci_aidepers_hab_taux2
            ci_aidepers_hab_taux3
            droit_bail_taux
            garde_enf_taux
            int_pret_etud_taux
            int_empr_taux1 int_empr_taux2 int_empr_taux3 int_empr_taux4 int_empr_taux5 int_empr_taux6
            assur_loy_imp_taux
            prev_risque_taux

            pfl_avi pfl_int pfl_div taux_impot_forf
            
            abat_dom_taux1 abat_dom_plaf1 abat_dom_taux2 abat_dom_plaf2

            CEHR_taux1 CEHR_taux2 CEHR_seuil1 CEHR_seuil2

            niche_plaf_fixe niche_plaf_majo niche_plaf_taux
            
            ppe_foyer1 ppe_foyer2 ppe_foyer3
            ppe_indiv1 ppe_indiv2 ppe_indiv3 ppe_indiv4 ppe_indiv5
            ppe_mono ppe_isoleENF ppe_coupleENF ppe_seuil ppe_partiel
            ppe_taux1 ppe_taux2 ppe_taux3

            cidd_tx_1 cidd_tx_2 cidd_tx_3 cidd_tx_4 cidd_tx_5 cidd_tx_6      
            cidd_tx_1_b cidd_tx_3_b  cidd_tx_4_b cidd_tx_5_b cidd_tx_6_b
            
            plafond_cidd 
            majo_cidd 

            seuil_rfr_cidd 
            tx_cidd_bouquet 
            tx_cidd_seul 
            tx_cidd_unique 

            pv_abat_exp 
            switch_pvm

            switch_calc_elast

            taux_bspce_1
            taux_bspce_2
            pv_pea_taux_1
            pv_pea_taux_2
            pfl_pens_taux 
            pfl_pens_abat
            taux_PFO_int
            taux_PFO_div
            creation_PFO
            switch_pfo
            switch_redIR 
            seuil_redIR_1
            seuil_redIR_2
            seuil_redIR_dp
            taux_redIR 
            ;



/**************************************************************************************************************************************************************/
/**************************************************************************************************************************************************************/
/*                       											II. Définition des paramètres  			               									  */
/**************************************************************************************************************************************************************/
/**************************************************************************************************************************************************************/ 

/**************************************************************************************************************************************************************/
/*				1- CSG sur les revenus du capital			                												     							  */
/**************************************************************************************************************************************************************/

/*NB: les paramètres en _def sont utilisés pour remonter aux assiettes brutes et ne doivent pas être modifiés dans les scénarios de réformes*/

    %let csg_pla_ded_def = 0.051 ; /*CSG deductible sur les revenus de placement (valeur par défaut)*/
    %let csg_pla_ded     = 0.051 ; /*CSG deductible sur les revenus de placement*/
    %let csg_pla_nod     = 0.031 ; /*CSG non deductible sur les revenus de placement*/
  
    %let csg_pat_ded_def = 0.051 ; /*CSG deductible sur les revenus du patrimoine (valeur par défaut)*/
    %let csg_pat_ded     = 0.051 ; /*CSG deductible sur les revenus du patrimoine*/
    %let csg_pat_nod     = 0.031 ; /*CSG non deductible sur les revenus du patrimoine*/


/**************************************************************************************************************************************************************/
/*				2- Prise en compte des mesures nouvelles		            												     							  */
/**************************************************************************************************************************************************************/

	/*Mesure HCAAM : suppression de l'exonération fiscale de la participation de l'employeur aux contrats collectifs de complémentaire santé*/
    %let switch_compl_sant = 1;

    /*Suppression de la PPE*/
    %let switch_ppe = 0 ;

/**************************************************************************************************************************************************************/
/*				3- Mise au barème des RCM						            												     							  */
/**************************************************************************************************************************************************************/

    /*Pour mettre les rcm au barème*/
    %let switch_int = 1 ;
    %let switch_div = 1 ;
    %let switch_pv = 0 ;
    %let switch_av = 0 ;
    %let quotient_pv = 0 ;
    %let creation_PFO = 0 ;         /*PFO obligatoire au taux actuel des PFL (21 % dividendes et 24 % intérêts)*/
    %let taux_PFO_int = 0.24 ;
    %let taux_PFO_div = 0.21 ;
    %let max_av_pfl = 1000000000;  	/*Plafond de produit d'assurance vie à passer au PFL*/

    /*Nombre de tranches du barème de l'impôt sur le revenu*/
    %let nb_tranches = 4 ;

    %let nb_enf_max = 8 ;

/**************************************************************************************************************************************************************/
/*				4- Actualisation de la législation						            												     							  */
/**************************************************************************************************************************************************************/

/**************************************************************************************************************************************************************/
/*		a. Paramètres généraux																									 		                      */
/**************************************************************************************************************************************************************/

    %let maj_taux= 1.25 ;        	/*majoration utilisée dans plusieurs cas*/
    %let abat_taux = 0.10;          /*taux abattement de 10% (ou frais rééls)*/


/**************************************************************************************************************************************************************/
/*		b. Barème de l'impot sur le revenu																						 		                      */
/**************************************************************************************************************************************************************/

    /*Taux marginaux du barème de l'impôt sur le revenu*/
    %let bar_taux_1 = 0.14 ; 
    %let bar_taux_2 = 0.30 ; 
    %let bar_taux_3 = 0.41 ;
    %let bar_taux_4 = 0.45 ;

    /*Tranches du barème de l'impôt sur le revenu*/
    %let bar_seuil_1 = %sysfunc(round(9700*&evol_bareme.));
    %let bar_seuil_2 = %sysfunc(round(26791*&evol_bareme.));
    %let bar_seuil_3 = %sysfunc(round(71826*&evol_bareme.));
    %let bar_seuil_4 = %sysfunc(round(152108*&evol_bareme.));

    /*Quotient familial*/ 
    %let plaf_qf_1 =  %sysfunc(round(1510*&evol_bareme.));        /*plafonnement quotient familial 1/2 part*/
    %let plaf_qf_2 =  %sysfunc(round(3562*&evol_bareme.));        /*plafonnement quotient familial 1/2 part supplémentaire*/
    %let plaf_qf_3 =  %sysfunc(round(902*&evol_bareme.));         /*plafonnement quotient familial 1/2 part*/ 
    %let plaf_qf_4 =  %sysfunc(round(1506*&evol_bareme.));        /*réduction complémentaire pour 1/2 part invalides*/ 
    %let plaf_qf_5 = 0 ;
    %let plaf_qf_6 = %sysfunc(round(1682*&evol_bareme.)) ;        /*réduction complémentaire pour 1/2 part veufs*/ 
 
    /*Réduction d'impôt supplémentaire en cas de plafonnement du QF accordée aux invalides, anciens combattants et personnes seules dont le dernier enfant 
	a au plus 25 ans*/
    %let demi_part_vieux = 0 ; 	/*suppression de la demi part pour personne ayant élevé des enfants vivant seule mais ne les ayant pas élevés seule*/  


/**************************************************************************************************************************************************************/
/*		c. Revenus catégoriels																									 		                      */
/**************************************************************************************************************************************************************/
 
    /*Salaires et retraites*/ 
    %let sal_abat_max =  %sysfunc(round(12169*&evol_bareme.)) ;   /*P0220 maximum abattement 10% traitements et salaires*/
    %let sal_abat_min =  %sysfunc(round(426*&evol_bareme.)) ;     /*P0240 minimum déduction 10% traitements et salaires*/
    %let cho_abat_min =  %sysfunc(round(937*&evol_bareme.)) ;     /*P0284 déduction forfait minimale pour demandeur d'emploi depuis plus d'1 an*/
    %let pen_abat_max =  %sysfunc(round(3711*&evol_bareme.)) ;    /*P0230 maximum déduction 10% pensions et retraites*/
    %let pen_abat_min =  %sysfunc(round(379*&evol_bareme.)) ;     /*P0241 minimum déduction 10% pensions*/
    %let pen_abat_taux = 0.10;

    /*Abattement sur rente viagère*/
    %let rv_m50_abat = 0.70 ;    /*fraction imposable si le bénéficiaire avait moins de 50 ans au commencement du versement de la rente*/ 
    %let rv_m60_abat = 0.50 ;    /*fraction imposable si le bénéficiaire avait moins de 60 ans au commencement du versement de la rente*/ 
    %let rv_m70_abat = 0.40 ;    /*fraction imposable si le bénéficiaire avait moins de 70 ans au commencement du versement de la rente*/ 
    %let rv_p70_abat = 0.30 ;    /*fraction imposable si le bénéficiaire avait plus  de 70 ans au commencement du versement de la rente*/ 

    /*BIC et BNC*/
    %let auto_vente_abat = 0.71 ;      /*abattement forfaitaire correspondant aux charges pour les activités d'achat et vente*/
    %let auto_service_abat = 0.50 ;    /*abattement forfaitaire correspondant aux charges pour les activités de services*/
    %let auto_nc_abat = 0.34 ;         /*abattement forfaitaire correspondant aux charges pour les activités non commerciales*/

    %let auto_abat_min = 305;                               			/*E2000 abattement minimum pour régime micro*/
    %let auto_ca_vente_plaf = %sysfunc(round(82282*&evol_bareme.)) ;    /*E2001 plafond micro entreprise avec une activite de vente de marchandises*/
    %let auto_ca_service_plaf = %sysfunc(round(32933*&evol_bareme.));   /*plafond micro entreprise avec une activité de prestation de service*/

    /*Revenus de capitaux mobiliers*/ 
    %let av_couple_abat = 9200;        	/*P0291 montant de l'abattement pour une assurance vie pour un couple*/
    %let av_seul_abat = 4600;          	/*P0290 montant de l'abattement pour une assurance vie pour une personne seule*/
    %let rcm_abat_taux = 0.4 ; 			/*taux de l'abattement sur les revenus d action au barème*/
    %let rcm_abat_forf_1 = 0; 			/*montant de l'abattement sur les revenus d actions CDV*/
    %let rcm_abat_forf_2 = 0; 			/*montant de l'abattement sur les revenus d actions MP*/

    /*Régime micro-foncier*/
    %let micfonc_abat_taux = 0.30 ; 	/*Taux d'abattement correspondant aux frais sur le régime micro foncier*/


/**************************************************************************************************************************************************************/
/*		d. Revenu brut global																									 		                      */
/**************************************************************************************************************************************************************/
 
    %let ba_rev_plaf = %sysfunc(round(107718*&evol_bareme.));        	/*P0320 plafond du revenu global pour déduction déficit BA*/

    /*Charges déductibles du revenu global  : frais d'accueil et pension alimentaire*/ 
    %let pen_alim_max = %sysfunc(round(5732*&evol_bareme.)) ;        	/*Abattement maximal sur les pensions alimentaires pour un enfant celibataire majeur*/   
    %let age_frais_max = %sysfunc(round(3406*&evol_bareme.));        	/*P0535 frais d accueil maximal pour les plus de 75 ans*/
    %let gro_rep_plaf = 25000 ; 										/*plafond des dépenses de grosses réparations des nus propriétaires*/


/**************************************************************************************************************************************************************/
/*		e. Abattements spéciaux (passage du revenu net global au revenu net imposable)											 		                      */
/**************************************************************************************************************************************************************/

    %let abat_spe_age_plaf_1 = %sysfunc(round(14725*&evol_bareme.));  	/*P0580 1 plafond de l'abattement 1 pour personnes âgées invalides*/
    %let abat_spe_age_plaf_2 = %sysfunc(round(23724*&evol_bareme.));  	/*P0600 2 plafond de l'abattement 2 pour personnes âgées invalides*/
    %let abat_spe_age_mont_1 = %sysfunc(round(2346*&evol_bareme.));   	/*P0590 1 montant de l'abattement 1 pour personnes âgées invalides*/
    %let abat_spe_age_mont_2 = %sysfunc(round(1173*&evol_bareme.));     /*P0610 2 montant de l'abattement 2 pour personnes âgées invalides*/
    %let abat_spe_enf_marie = %sysfunc(round(5732*&evol_bareme.));      /*P0620 abattement pour enfants mariés*/  

    /*Décôte*/ 
    %let plaf_decote_celib = %sysfunc(round(1554*&evol_bareme.)) ;     	/*plafond décôte*/
    %let plaf_decote_couple = %sysfunc(round(2560*&evol_bareme.)) ;     
    %let pente_decote_celib = 0.75 ;
    %let pente_decote_couple = 0.75 ;


/**************************************************************************************************************************************************************/
/*		f. Réductions d'impots (RI)																								 		                      */
/**************************************************************************************************************************************************************/

    /*RI pour dons effectués à des organismes d'aide aux personnes en difficulté*/ 
    %let dons_difficult_plaf = %sysfunc(round(527*&evol_bareme.));     	/*P0545 plafond pour dons aide aux personnes en difficulté*/
    %let dons_difficult_taux = 0.75 ;   /*taux de réduction d'impôt pour les dons à des organismes d'aide aux personnes en difficulté*/

	%let dons_utipub_plaf = 0.20 ;      /*plafond de réduction d'impôt pour les autres dons (association d'utilité publique, organismes d'intérêt général, parti politique*/
    %let dons_utipub_taux = 0.66 ;      /*taux de réduction d'impôt pour les autres dons (association d'utilité publique, organismes d'intérêt général, parti politique)*/

    /*RI Cotisations syndicales*/
    %let cot_syndic_plaf = 0.01 ;       /*plafond de réduction d'impôt pour les cotisations syndicales*/
    %let cot_syndic_taux = 0.66 ;       /*taux de réduction d'impôt pour les cotisations syndicales (proportionnel au salaire, pension, rente viagère moins cotsoc*/

    /*RI Travaux de restauration immobilière*/
    %let rest_immo_plaf  = 100000;      /*P0992 dépenses de restauration immobilière en secteur sauvegardé ou assimilé*/
    %let rest_immo_taux1 = 0.22 ;       /*taux de réduction 1 pour dépenses de restauration immobilière en secteur sauvegardé ou assimilé*/
    %let rest_immo_taux2 = 0.30 ;       /*taux de réduction 2 pour dépenses de restauration immobilière en secteur sauvegardé ou assimilé*/
    %let rest_immo_taux3 = 0.30 ;
    %let rest_immo_taux4 = 0.40 ;
    %let rest_immo_taux5 = 0.27 ;

    /*RI Dépense de protection du patrimoine naturel*/
    %let protect_nat_plaf = 10000;      /*P0991 plafond de dépenses de protection du patrimoine naturel*/
    %let protect_nat_taux = 0.18 ;      /*taux de réduction pour dépenses de protection du patrimoine naturel*/

    /*RI pour salarié à domicile*/ 
    %let sal_dom_plaf = 12000;          /*P0496a plafond des sommes versées pour emploi d'un salarie à domicile*/
    %let sal_dom_enf_charge_majo = 1500;/*P0496b majoration par enfant à charge ou rattaché, + 65 ans, APA (emploi d'un salarie à domicile)*/
    %let sal_dom_plaf_max = 15000;      /*P0496c plafond maximal (emploi d'un salarié à domicile), aussi indemnisation en cas de 1ere année d'embauche*/
    %let sal_dom_1ere_emb_plaf = 18000; /*P0496d plafond porté à 18000€ en cas de première embauche du salarié à domicile*/
    %let sal_dom_inv_plaf = 20000;      /*P0497 plafond d'emploi à domicile si la personne est invalide*/
    %let sal_dom_taux = 0.50 ;          /*taux de réduction d'impôt pour un salarié à domicile*/

    /*RI pour intérêts au titre du différé de paiement accordé aux agriculteurs*/ 
    %let diff_agri_seul_plaf = 5000;    /*P0491 plafond RI pour intérêts au titre du différé de paiement accordé aux agriculteurs : célibataires, etc. (CDV)*/
    %let diff_agri_couple_plaf = 10000; /*P0492 plafond RI pour intérêts au titre du différé de paiement accordé aux agriculteurs : couples*/
    %let diff_agri_taux = 0.50 ;        /*taux de réduction au titre du différé de paiement accordé aux agriculteurs*/

    /*RI en cas de divorce*/ 
    %let prest_divorce_plaf = 30500;    /*P0493 plafond RI prestations compensatoires versées en cas de divorce*/
    %let divorce_taux = 0.25 ;         	/*taux de réduction au titre de prestations compensatoires suite à un divorce*/

    /*RI Fonds commun de placement dans l’innovation*/
    %let fcpi_taux = 0.22 ;            	/*taux de réduction pour un investissement dans un fond commun de placement dans l'innovation*/
    %let fcpi_couple_plaf = 24000;      /*P0295b  plafond FCPI couple*/
    %let fcpi_seul_plaf  = 12000;       /*P0296b plafond FCPI CDV*/

    /*RI Fonds d’investissement de proximité*/
    %let fip_taux = 0.18 ;              /*taux de réduction pour un investissement dans un fond d'investissement de proximité*/
    %let fip_seul_plaf = 12000;         /*P0296c plafond FIP CDV*/
    %let fip_couple_plaf = 24000;    	/*P0295c plafond FIP Couple*/

    %let fip_corse_taux = 0.38 ;        /*taux de réduction pour un investissement dans un fond d'investissement de proximité (FIP) dédié aux entreprises corses*/
    %let fip_seul_corse_plaf = 12000;   /*P0296d plafond FIP célibataire etc. Corse*/
    %let fip_couple_corse_plaf  = 24000;/*P0295d Plafond FIP couple Corse*/

    %let fip_dom_taux = 0.42;
    %let fip_seul_dom_plaf     = 12000 ;
    %let fip_couple_dom_plaf = 24000 ;

    /*RI pour conservation et restauration d'objets classés monuments historiques*/ 
    %let monu_hist_plaf = 20000;     	/*P0550 plafond crédit d impôt conservation et restauration de monuments historiques*/
    %let monu_hist_taux = 0.18 ;        /*taux de réduction pour dépenses de conservation et restauration de monuments historiques*/

    /*RI SOFICA*/  
    %let sofica_plaf = 18000;      		/*P0292 plafond SOFICA 25% du RI avec plafond a 18000*/
    %let sofica_plaf_taux = 0.25 ;      /*plafond de réduction pour une souscription au capital SOFICA*/
    %let sofica_ded_taux1 = 0.30 ;      /*taux 1 de réduction pour une souscription au capital SOFICA*/
    %let sofica_ded_taux2 = 0.36 ;      /*taux 2 de réduction pour une souscription au capital SOFICA*/

    /*RI pour souscription au capital des PME*/
    %let cap_pme_couple_plaf_1 = 40000;	/*P0295 1 plafond capital des PME Couple*/
    %let cap_pme_seul_plaf_1   = 20000;	/*P0296 1 plafond capital des PME CDV*/
    %let cap_pme_couple_plaf_2 = 50000;	/*P0298 2 plafond capital des PME Couple*/
    %let cap_pme_seul_plaf_2 = 100000;	/*P0299 2 plafond capital des PME CDV*/
    %let cap_pme_taux1 = 0.18 ;         /*taux de réduction pour une souscription au capital des PME*/
    %let cap_pme_taux2 = 0.22 ;         /*taux de réduction pour une souscription au capital des PME*/
    %let cap_pme_taux3 = 0.25 ;

    /*RI pour intérêts d'emprunts pour reprise de société*/
    %let int_repr_couple_plaf = 40000; 	/*P0295e plafond intérêts reprise société Couple*/
    %let int_repr_seul_plaf = 20000;   	/*P0296e  plafond intérêts reprise société CDV*/
    %let reprise_soc_taux = 0.25 ;      /*taux de réduction pour les interets d'emprunts pour reprise de société*/
    
    /*RI pour Investissements forestiers*/  
    %let foret_acq_taux = 0.18 ;        	/*taux de réduction pour investissements forestiers*/
    %let foret_acq_seul_plaf     =  5700 ;	/*P0515a1 limite cotisations pour défense des forêts contre l'incendie : Acquisition, personne seule*/
    %let foret_acq_couple_plaf   = 11400 ;	/*P0515a2 limite cotisations pour défense des forêts contre l'incendie : Acquisition, CMP*/
    %let foret_trav_seul_plaf    =  6250 ;	/*P0515b1 limite cotisations pour défense des forêts contre l'incendie : Travaux, personne seule*/
    %let foret_trav_couple_plaf  = 12500 ;	/*P0515b2 limite cotisations pour défense des forêts contre l'incendie : Travaux, CMP*/
    %let foret_contr_seul_plaf   =  2000 ;	/*P0515c1 limite cotisations pour défense des forêts contre l'incendie : Contrat, personne seule*/
    %let foret_contr_couple_plaf =  4000 ;	/*P0515c2 limite cotisations pour défense des forêts contre l'incendie : Contrat, CMP*/
    %let foret_ass_seul_plaf =      6250 ;	/*limite cotisations pour défense des forêts contre l'incendie : Assurance,personne seule*/  
    %let foret_ass_couple_plaf = 12500   ;	/*limite cotisations pour défense des forêts contre l'incendie : Assurance, CMP*/  
    %let foret_ass_taux = 0.76;
    %let foret_rep_taux = 0.25 ;

    /*RI Défense des fôret contre l'incendie*/   
    %let foret_cot_plaf          =  1000 ;	/*P0515 limite cotisations pour défense des forêts contre l'incendie*/
    %let foret_cot_taux = 0.50 ;       		/*taux de réduction pour dépense en defense des forets contre l'incendie*/

    /*RI pour dépenses d'accueil pour personnes âgées dépendantes*/
    %let age_long_sejour_plaf = 10000; 		/*P0498 plafond établissement long sejour*/
    %let age_long_sejour_taux = 0.25 ;  	/*taux de réduction pour dépenses d'accueil pour personnes âgées dépendantes*/

    /*RI Rentes survie, contrat d'épargne handicap*/
    %let rente_survie_plaf = 1525;     		/*P0510 limite de réduction d'impôt rente survie*/
    %let rente_survie_enf_charge_majo = 300;/*P0511 majoration de réduction d'impôt rente survie par enfant à charge*/
    %let rente_survie_taux = 0.25 ;     	/*taux de réduction pour rente survie, contrat d'épargne handicap*/

    /*RI pour investissements locatifs dans le secteur touristique*/
       	/*Logements acquis ou achevés avant le 01/01/2001*/
    %let inv_loc_01_seul_plaf = 38120;  	/*P0504a limite Investissement locatif touristique dans les zones rurales pers. seule*/
    %let inv_loc_01_couple_plaf = 76240;	/*P0504b limite Investissement locatif touristique dans les zones rurales couple*/

      	/* Logements acquis ou achevés à compter du 01/01/2001 au 31/12/2003*/
    %let inv_loc_0103_seul_plaf  = 45760; 	/*P0504c limite Investissement locatif touristique dans les zones rurales pers. seule*/
    %let inv_loc_0103_couple_plaf = 91520;	/*P0504d limite Investissement locatif touristique dans les zones rurales couple*/

   		/* 1/ Logements acquis ou achevés à compter du 01/01/2004 OU
           2/ Logements acquis ou achevés entre le 01/01/2005 et le 31/12/2010 
           3/ Acquisition à compter du 01/01/2004 faisant l objet de travaux achevés entre le 01/01/2004 et le 31/12/2010
           4/ Travaux de reconstruction, etc. payés entre le 01/01/2005 et le 31/12/2010*/

    %let inv_loc_04_seul_plaf = 50000;   	/*limite Investissement locatif touristique dans les zones rurales pers. seule*/
    %let inv_loc_04_couple_plaf = 100000;  	/*limite Investissement locatif touristique dans les zones rurales couple*/


    %let inv_loc_taux1 = 0.25 ;         	/*taux de réduction 1 pour investissement locatif dans le secteur touristique*/
    %let inv_loc_taux2 = 0.20 ;         	/*taux de réduction 2 pour investissement locatif dans le secteur touristique*/
    %let inv_loc_trav_taux1 = 0.15 ;    	/*taux de réduction 1 relatif à des travaux*/
    %let inv_loc_trav_taux2 = 0.20 ;    	/*taux de réduction 2 relatif à des travaux*/
    %let inv_loc_trav_taux3 = 0.30 ;    	/*taux de réduction 3 relatif à des travaux*/
    %let inv_loc_trav_taux4 = 0.40 ;    	/*taux de réduction 4 relatif à des travaux*/

    /*RI pour investissement en Outre-mer*/ 
    %let inv_dom_plaf = 40000;         		/*P0990 plafond investissement dans les DOM*/

    /*RI pour frais de comptabilité et d'adhésion à un CGA*/ 
    %let cga_frais_adh_plaf = 915;          /*P0915 maximum pour frais de comptabilité pour l'adhésion à un CGA*/

    /*RI pour aide aux créateurs d'entreprise*/
    %let aide_creat_reduc = 1000;        	/*P0516 RI aide créateurs d'entreprise*/
    %let aide_creat_majo_handi = 400;     	/*P0517 majoration RI aide aux créateurs d'entreprise pour personne handicapée*/

    /*RI pour frais de scolarisation*/  
    %let college_reduc = 61;               	/*P0440 dans un collège*/
    %let lycee_reduc = 153;              	/*P0441 dans un lycée*/
    %let etab_sup_reduc = 183;              /*P0442 dans un établissement d'enseignement supérieur*/

    /*RI Investissement Duflot*/ 
    %let duflot_plaf_dec = 300000 ; 
    %let duflot_taux1 = 0.29 ; 
    %let duflot_taux2 = 0.18 ; 

    /*RI Investissement Scellier*/
    %let scl_plaf_dec = 300000;

    %let scl_met_bbc_taux1 = 0.13 ;    /*taux de reduction pour un investissement locatif loi Scellier réalisé à compter du 01.01.2011 en métropole logement BBC*/
    %let scl_met_bbc_taux2 = 0.22 ;    /*taux de reduction pour un investissement locatif loi Scellier réalisé à compter du 01.01.2011 en métropole logement BBC*/
    %let scl_met_bbc_taux3 = 0.25 ;    /*taux de reduction pour un investissement locatif loi Scellier réalisé ou engagé avant le 01.01.2011 en métropole logement BBC*/

    %let scl_met_nonbbc_taux1 = 0.06 ; /*taux de reduction pour un investissement locatif loi Scellier réalisé à compter du 01.01.2011 en métropole logement non BBC*/
    %let scl_met_nonbbc_taux2 = 0.15 ; /*taux de reduction pour un investissement locatif loi Scellier réalisé avant le 01.01.2011 en métropole logement non BBC*/

    %let scl_OM_taux1 = 0.24;          /*taux de reduction pour un investissement locatif loi Scellier réalisé à compter du 01.01.2011 en outre mer*/
    %let scl_OM_taux2 = 0.36 ;         /*taux de reduction pour un investissement locatif loi Scellier réalisé avant le 01.01.2011 en outre mer*/
    %let scl_OM_taux3 = 0.40 ;         /*taux de reduction pour un investissement locatif loi Scellier réalisé avant le 01.01.2011 en outre mer*/

    /*RI Location meublée non professionnelle*/
    %let InvMeuNonPro_taux1 = 0.11  ;   /*taux de réduction pour un investissement immobilier dans le secteur de la location meublee non professionnelle*/
    %let InvMeuNonPro_taux2 = 0.18  ;   /*taux de réduction pour un investissement immobilier dans le secteur de la location meublee non professionnelle*/
    %let InvMeuNonPro_taux3 = 0.20  ; 	/*taux de réduction pour un investissement immobilier dans le secteur de la location meublee non professionnelle*/
    %let InvMeuNonPro_taux4 = 0.25  ; 	/*taux de réduction pour un investissement immobilier dans le secteur de la location meublee non professionnelle*/
    %let InvMeuNonPro_plaf = 300000 ;   /*plafond de montant des cases ouvrant le droit à une réduction pour un investissement immobilier dans le secteur de la location meublee non professionnelle*/

    /*RI investissement outre-mer*/
    %let OM_plaf = 40000 ;              /*plafonnement de reduction pour investissements locatifs dans les DOM*/
    %let OM_plaf2 = 36000 ;
    %let OM_plaf3 = 30600 ;

    %let OM_plaf_specif1 = 40000 ;      /*plafonnement spécifique 1 de reduction pour investissements locatifs dans les DOM*/
    %let OM_plaf_specif2 = 60000 ;      /*plafonnement spécifique 2 de reduction pour investissements locatifs dans les DOM*/
    %let OM_plaf_specif3 = 74286 ;      /*plafonnement spécifique 3 de reduction pour investissements locatifs dans les DOM*/

    %let OM_taux1 = 0.35 ;  
    %let OM_taux2 = 0.375 ;  
    %let OM_taux3 = 0.40 ;
    %let OM_taux4 = 0.4737 ;
    %let OM_taux5 = 0.50 ;
    %let OM_taux6 = 0.60 ;
    %let OM_taux7 = 0.65 ;

    %let OM_lim1 = 0.15 ;               /*limite pour les investissements dans logement social et réalisés ou engagés avant 2011*/ 
    %let OM_lim2 = 0.13 ;               /*limite pour les investissements réalisés ou engagés en 2011*/
    %let OM_lim3 = 0.11 ;               /*limite pour les investissements réalisés ou engagés après 2012*/

    /*RI pour motifs environnementaux*/ 
    %let qualenv_plaf = 8000 ; 

    %let prev_risque_seul_plaf = 5000; 		/*P0994 plafond célibataire travaux de prévention des risques technologiques dans les logements donnés en location*/
    %let prev_risque_couple_plaf = 10000;   /*P0995 plafond couple M/P travaux de prévention des risques technologiques dans les logements donnés en location*/
    %let prev_risque_pac_majo = 400;        /*P0996 majoration du plafond pour personnes à charge (PAC) travaux de prévention des risques technologiques dans les logements donnés en location*/
    
     %let prev_risque_taux = 0.40 ;      	/*taux de réduction*/    

    /*RI du PLF 2017*/
    %let switch_redIR=0;
    %let seuil_redIR_1 = 18500;
    %let seuil_redIR_2=20500;
    %let seuil_redIR_dp = 3700;
    %let taux_redIR = 0.2;


/**************************************************************************************************************************************************************/
/*		g. Crédits d'impots (CI)																							 		                          */
/**************************************************************************************************************************************************************/

    /*CI sur les dividendes*/ 
	/*Suppression pour les revenus à partir de 2010*/
    %let div_50_seul_plaf = 115;      /*P0494  crédit d'impôt dividendes 50% plafond : seuls*/
    %let div_50_couple_plaf = 230;    /*P0494 crédit d'impôt dividendes 50% plafond : couples*/  

    /*CI développement durable / dépenses de gros équipement*/ 
    %let gros_equip_seul_plaf = 8000; 	/*P0505 plafond dépense de gros équipement*/
    %let gros_equip_couple_plaf = 16000;/*P0506 plafond dépense de gros équipement : le fait d'être en couple ne dédouble plus l'avantage*/
    %let gros_equip_majo = 400;   		/*P0507 majoration Plafond dépense de gros équipement*/

    /*CI intérêts prêt étudiant*/ 
    %let int_pret_etud_plaf = 1000;   	/*P0508 plafond Intérêts prêts étudiants*/

    /*CI pour Crédit d impôt interêt d'emprunt*/ 
    %let int_empr_seul_plaf = 3750;    	/*P0518 limite interêt d'emprunt personne seule*/
    %let int_empr_charge_majo = 500;   	/*majoration interêt d'emprunt personne à charge*/

    /*CI pour frais de garde des jeunes enfants*/
    %let garde_enf_plaf = 2300;    		/*P0480 plafond frais de garde par enfant*/
    %let garde_enf_alt_plaf = 1150;   	/*P0481 plafond frais de garde par enfant en résidence alternée*/


/**************************************************************************************************************************************************************/
/*		h. Droits																												 		                      */
/**************************************************************************************************************************************************************/

    /*Seuils de recouvrement et de restitution*/ 
    %let seuil_perc_avt_restit = 61; 	/*P0960 minimum perception (cf art. 1657-1 bis et 2)*/
    %let seuil_perc_apt_restit = 12; 	/*P0970 minimum de perception après restitutions (cf art. 1657-1 bis et 2)*/
    %let seuil_restit = 8;           	/*P0980 minimum de restitution (cf art. 1965 L)*/

    /*Age*/
    %let age_seuil = 65 ;               /*seuil à partir duquel on est considéré comme âgé*/

    /*PV mobilières*/
    %let taux_bspce_1 = 0.19;           /*taux d'imposition des plus-values sur bons de souscription de parts de créateurs d'entreprises (CGI 163 bis G)*/
    %let taux_bspce_2 = 0.30 ;          /*taux d'imposition des plus-values sur bons de souscription de parts de créateurs d'entreprises (si moins de trois ans d'exercice dans la société) (CGI 163 bis G)*/

    %let pv_mob_taux = 0.24 ;           /*taux d'imposition des plus-values à taux proportionnel*/
    %let pv_mob_taux_entr = 0.19 ;      /*taux d'imposition des plus-values à taux proportionnel*/
    %let pv_pro_taux = 0.16 ;           /*taux d'imposition des plus-values professionnelles à taux proportionnel*/
    %let pv_dom_taux1 = 0.10 ;          /*taux d'imposition des gains de cession de droits sociaux au dela du seuil de 25830 € en Guyane*/
    %let pv_dom_taux2 = 0.12 ;          /*taux d'imposition des gains de cession de droits sociaux au dela du seuil de 25830 € dans les autres DOM*/

    %let pv_pea_taux_1 = 0.19 ;         /*taxation suite à une cloture de PEA entre la 2ème et la 5ème année*/
    %let pv_pea_taux_2 = 0.225 ;        /*taxation suite à une cloture de PEA avant expiration de la deuxième année*/

    %let taux_aga_1 = 0.025;
    %let taux_aga_2 = 0.08 ;
    %let taux_aga_3 = 0.1 ;

    %let pv_titre_taux1 = 0.18 ;        /*gains de levée d'options sur titres taxables à 18%*/
    %let pv_titre_taux2 = 0.30 ;        /*gains de levée d'options sur titres taxables à 30%*/
    %let pv_titre_taux3 = 0.40 ;        /*gains de levée d'options sur titres taxables à 40%*/
    %let pv_etrangeres_taux1 = 0.16 ;   /*taux de réduction*/
    %let pv_etrangeres_taux2 = 0.18 ;   /*taux de réduction*/

    /*Prelèvements forfaitaires libératoires*/
    %let pfl_avi = 0.075 ; 				/*sur les produits d'assurances-vie*/
    %let pfl_int    = 0 ;
    %let pfl_div    = 0 ;

	/*Réductions d impôt*/
    %let sofipeche_ded_taux = 0.36 ;   
    %let env_plaf = 8000;               /*P0993 plafond dépenses en faveur de la qualité environnementale des logements donnés en location*/    
    %let bien_cult_taux = 0.40 ;        /*taux de réduction*/

    %let ci_qualenvir_taux1 = 0.13 ;  	/*crédit d'impot pour dépenses en faveur de la qualité environnementale*/
    %let ci_qualenvir_taux2 = 0.22 ;   	/*crédit d'impot pour dépenses en faveur de la qualité environnementale*/
    %let ci_qualenvir_taux3 = 0.36 ;    /*crédit d'impot pour dépenses en faveur de la qualité environnementale*/
    %let ci_qualenvir_taux4 = 0.45 ;   	/*crédit d'impot pour dépenses en faveur de la qualité environnementale*/
    %let ci_qualenvir_taux5 = 0.50 ;    /*crédit d'impot pour dépenses en faveur de la qualité environnementale photovoltaique*/
  
    %let ci_aidepers_hab_taux1 = 0.15 ; /*taux de réduction*/
    %let ci_aidepers_hab_taux2 = 0.25 ; /*taux de réduction*/
    %let ci_aidepers_hab_taux3 = 0.30 ; /*taux de réduction*/

    %let droit_bail_taux = 0.25 ;       /*taux de réduction*/
    %let garde_enf_taux = 0.50 ;        /*taux de réduction*/
    %let int_pret_etud_taux = 0.25 ;    /*taux de réduction*/
    %let int_empr_taux1 = 0.20 ;        /*taux de réduction*/
    %let int_empr_taux2 = 0.30 ;        /*taux de réduction*/
    %let int_empr_taux3 = 0.40 ;        /*taux de réduction*/
    %let int_empr_taux4 = 0.15 ;
    %let int_empr_taux5 = 0.25 ;
    %let int_empr_taux6 = 0.10 ;

    %let assur_loy_imp_taux = 0.38 ;    /*taux de réduction*/


    /*Impôt forfaitaire sur les intérêts*/
    %let taux_impot_forf = 0.24 ;
    
    /*Abattement pour résidence dans les DOM */
    %let abat_dom_taux1 = 0.30 ; 		/*taux d'abattement pour les résidents en Guadeloupe, Martique, Réunion*/
    %let abat_dom_plaf1 = 5100 ; 		/*plafond d'abattement pour les résidents en Guadeloupe, Martique, Réunion*/

    %let abat_dom_taux2 = 0.40 ; 		/*taux d'abattement pour les résidents en Guyane*/
    %let abat_dom_plaf2 = 6700 ; 		/*plafond d'abattement pour les résidents en Guyane*/

    /*Plafonnement des niches fiscales*/
    %let niche_plaf_fixe = 10000;
    %let niche_plaf_majo = 8000 ;
    %let niche_plaf_taux = 0 ;

    /*PPE*/ /*supprimée en 2016*/ 
    %let ppe_foyer1      =   16251 ;
    %let ppe_foyer2      =   32498 ;
    %let ppe_foyer3      =   4490  ;

    %let ppe_indiv1      =   3743  ;
    %let ppe_indiv2      =   12475 ;
    %let ppe_indiv3      =   17451 ;
    %let ppe_indiv4      =   24950 ;
    %let ppe_indiv5      =   26572 ;

    %let ppe_mono        =   83    ;
    %let ppe_isoleENF    =   72    ;
    %let ppe_coupleENF   =   36    ;
    %let ppe_seuil       =   30    ;

    %let ppe_partiel     =   0.85  ;

    %let ppe_taux1       =   0.077 ;
    %let ppe_taux2       =   0.193 ;
    %let ppe_taux3       =   0.051 ;

    /*Contribution exceptionnelle sur les hauts revenus (CEHR)*/
    %let CEHR_taux1 = 0.03 ;
    %let CEHR_taux2 = 0.04 ;
    %let CEHR_seuil1 = 250000 ;
    %let CEHR_seuil2 = 500000 ;

    /*Prélèvement libératoire sur pensions de retraites versées sous forme de capital*/
    %let pfl_pens_taux = 0.075 ;
    %let pfl_pens_abat = 0.1 ;
    %let tx_cidd_unique = 0.30 ;

	/*Mise en place du taux unique à 30% sur le CITE, de façon rétroactive pour les dépenses engagées à partir du 1er septembre 2014*/   
    %let cidd_tx_1 = &tx_cidd_unique.; /*0.10*/
    %let cidd_tx_2 = &tx_cidd_unique.; /*0.11*/
    %let cidd_tx_3 = &tx_cidd_unique.; /*0.15*/
    %let cidd_tx_4 = &tx_cidd_unique.; /*0.17*/
    %let cidd_tx_5 = &tx_cidd_unique.; /*0.26*/
    %let cidd_tx_6 = &tx_cidd_unique.; /*0.32*/

    %let cidd_tx_1_b = &tx_cidd_unique.; /*0.18*/
    %let cidd_tx_3_b = &tx_cidd_unique.; /*0.23*/
    %let cidd_tx_4_b = &tx_cidd_unique.; /*0.26*/
    %let cidd_tx_5_b = &tx_cidd_unique.; /*0.34*/
    %let cidd_tx_6_b = &tx_cidd_unique.; /*0.40*/

    %let plafond_cidd = 8000 ;
    %let majo_cidd = 400 ;

    %let seuil_rfr_cidd = 0 ;
    %let tx_cidd_bouquet =  0;
    %let tx_cidd_seul = 0 ;
 


    %let pv_abat_exp = 0.61 ;
    %let switch_pvm = 1 ;

    /*Paramètres à mettre à 0 lors du calcul des élasticité (pour avoir l'IR hors CI suivis en dépense)*/
    %let switch_calc_elast = 1 ;
    %let switch_pfo = 0 ;



%mend Parametres ;


/**************************************************************************************************************************************************************/
/**************************************************************************************************************************************************************/
/*                       									III. Législation 2016 sur les revenus 2015	                 									  */
/**************************************************************************************************************************************************************/
/**************************************************************************************************************************************************************/

%let evol_bareme=1; %Parametres(&evol_bareme.);


/*************************************************************************************************************************************************************
**************************************************************************************************************************************************************

Ce logiciel est régi par la licence CeCILL V2.1 soumise au droit français et respectant les principes de diffusion des logiciels libres. 

Vous pouvez utiliser, modifier et/ou redistribuer ce programme sous les conditions de la licence CeCILL V2.1. 

Le texte complet de la licence CeCILL V2.1 est dans le fichier `LICENSE`.

Les paramètres de la législation socio-fiscale figurant dans les programmes 6, 7a et 7b sont régis par la « Licence Ouverte / Open License » Version 2.0.
**************************************************************************************************************************************************************
*************************************************************************************************************************************************************/

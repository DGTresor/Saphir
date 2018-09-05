

/**************************************************************************************************************************************************************/
/*                                   								SAPHIR E2013 L2017                                     	 				       	   	      */
/*                                        								PROGRAMME 2                            				         			              */
/*                   								Vieillissement revenus ERFS en 2014, 2015, 2016 et 2017                  		     		              */
/**************************************************************************************************************************************************************/

/**************************************************************************************************************************************************************/ 
/* Entre 2013 et 2017, les revenus évoluent selon deux composantes : des éléments liés à l’évolution de la structure sociodémographique (taux de chômage,     */
/* répartition des actifs par catégorie socio-professionnelle) et des éléments liés à la dynamique des revenus (progression salariale, impact de la           */
/* conjoncture sur les bénéfices…). 																														  */
/*																																							  */ 
/* Dans l'onglet Vieillissement du fichier parametres.xls, les coefficients de vieillissement sont initialisés à 0. 										  */
/* L'utilisateur du modèle doit définir lui-même ces hypothèses en renseignant les coefficients dans le fichier Excel.										  */				
/*																																							  */
/* Pour les deux premières lignes du tableau (tx_infl et th_th) --> renseigner un taux 																		  */
/* Exemple : pour une hypothèse d'inflation de 1% : tx_infl=0.01																							  */
/*																																							  */
/* Pour les autres lignes du tableau --> renseigner des coefficents d'accroissement 																		  */
/* Exemple : pour une hypothèse d'évolution de 1% des salaires : tx_sal=1																					  */			
/**************************************************************************************************************************************************************/



/**************************************************************************************************************************************************************/
/**************************************************************************************************************************************************************/
/*                					I. Identification des salariés rémunérés au voisinage su Smic (proxy : éligibles à la PPE)                 				  */
/**************************************************************************************************************************************************************/
/**************************************************************************************************************************************************************/

data saphir.foyer&acour._r&acour. ; set saphir.foyer&acour. ; 
PPE_dec1=(MNRBVP+MNRBMV)>0;
PPE_dec2=(MNRBCQ+MNRBCI)>0;
run;

data saphir.menage&acour. ; set erfs.menage&acour. ;run; 
proc sort data=saphir.indivi&acour. out=saphir.indivi&acour._r&acour.;by declar1; run;
proc sort data=saphir.foyer&acour._r&acour.;by declar; run;

data saphir.indivi&acour._r&acour. (drop=PPE_:);
length declar1 $ 79;
merge  saphir.indivi&acour._r&acour.(in=a) 
       saphir.foyer&acour._r&acour.(rename=(declar=declar1) keep= declar PPE_:);
by declar1; if a ;

if fisc_sal="decl"      then eligible_PPE1=max(0,PPE_dec1);
else if fisc_sal="conj" then eligible_PPE1=max(0,PPE_dec2);
else eligible_PPE1=(zsali>0 & declar1 ne "") ; 					/*toutes les personnes à charge ayant des salaires sont considérées éligibles à la PPE*/

run;

proc sort data=saphir.indivi&acour._r&acour.;by declar2; run;

data saphir.indivi&acour._r&acour. (drop=PPE_: eligible_PPE1);
length declar2 $ 79;
merge saphir.indivi&acour._r&acour. (in=a) 
      saphir.foyer&acour._r&acour.(rename=(declar=declar2) keep= declar PPE_:);
by declar2; if a ;

if fisc_sal2="decl"      then eligible_PPE=max(0,eligible_PPE1,PPE_dec1);
else if fisc_sal2="conj" then eligible_PPE=max(0,eligible_PPE1,PPE_dec2);
else eligible_PPE=eligible_PPE1 ;

run;


/**************************************************************************************************************************************************************/
/**************************************************************************************************************************************************************/
/*                       										II. Calcul de masse salariale	                 										      */
/**************************************************************************************************************************************************************/
/**************************************************************************************************************************************************************/

/* Pour différencier le vieillissement des salaires : 
- les salaires des individus au voisinage du SMIC sont vieillis au même rythme que le SMIC
- les salaires des individus qui ne sont pas au SMIC sont vieillis à un taux d'accroissement c_sal_hors_smic calculé de manière à avoir un taux d'accroissement total égal à 
c_sal : coef. d'actualisation des salaires basé sur le SMPT 
Le calcul de c_sal_hors_smic fait intervenir la masse salariale en 2013 (non pondérée):
                                1) totale 
                                2) des salariés au Smic (proxy: éligibles à la PPE) 
                                3) et des salairés qui ne sont pas au Smic (proxy: non éligibles à la PPE)*/

proc means data=saphir.indivi&acour._r&acour. noprint;
   var zsali ;
   class eligible_PPE;
   output out=masse_salariale_poids&asuiv4. sum=masse_sal;
run;

proc transpose data=masse_salariale_poids&asuiv4. out=masse_salariale_poids&asuiv4. prefix=masse_sal;  var masse_sal; run;

data _null_;
  set masse_salariale_poids&asuiv4. ;
  call symput("masse_sal_tot",masse_sal1);
  call symput("masse_sal_hors_smic",masse_sal2);
  call symput("masse_sal_smic",masse_sal3);
run;


proc datasets library=work;delete temp_masse_sal pond masse_salariale_poids&asuiv4.;run;quit;


/**************************************************************************************************************************************************************/
/**************************************************************************************************************************************************************/
/*                       										III. Vieillissement des revenus	                 										      */
/**************************************************************************************************************************************************************/
/**************************************************************************************************************************************************************/


/*Définition de la macro de vieillissement*/

%macro vieillissement(annee= ,listvar=, unite=, agregat=, variable=);
%let i=1;
%do %while(%index(&listvar.,%scan(&listvar.,&i.))>0); 
    %let var=%scan(&listvar.,&i.);
    %put tx_&var.f = &&tx_&var.f ;

    %if &agregat.=1 %then %do ; 	/*le vieillissement des éléments de l'agrégat est réalisé sans changer de nom*/
        %if  &var. ne ZSAL  %then %do ; do i=1 to dim(&var.fa); &var.fa(i)=&var.fa(i)*sum(1,&&tx_&var.f); end; %end ;
        %else %if &var. = ZSAL %then %do ;  
            %if &unite. ne f %then %do ;
                do i=1 to dim(&var.fa); &var.fa(i)=&var.fa(i)*sum(1,eligible_PPE*&&tx_&var._smicf,(1-eligible_PPE)*&&tx_&var._hors_smicf ); end; 
            %end ;
            %if &unite. = f %then %do ;
            do i=1 to dim(&var.fa); /*DEC puis CONJ puis PAC : les variables de l'agrégat doivent être triées dans l'ordre des personnes déclarées*/
                if i<6 then do; &var.fa(i)=&var.fa(i)*sum(1,PPE_dec1*&&tx_&var._smicf, (1-PPE_dec1)*&&tx_&var._hors_smicf); end;
                else if (i>5 and i<10) then do; &var.fa(i)=&var.fa(i)*sum(1,PPE_dec2*&&tx_&var._smicf, (1-PPE_dec2)*&&tx_&var._hors_smicf); end;
                else do; &var.fa(i)=&var.fa(i)*sum(1,&&tx_&var._smicf); end; /*les PAC supposées sont au Smic*/
            end;
            &var.&unite.&annee.=sum(of &var.fa (*));
            %end ;
        %end ;
    %end ;

    %if &variable.=1 %then %do ;
        %if &annee.=&asuiv. and  &var. ne ZSAL  %then %do ; &var.&unite.&annee.=&var.&unite.*sum(1,&&tx_&var.f); %end ; 						/*seules les variables de la table de départ n'ont pas de suffixe*/
        %else %if &annee.=&asuiv. and  &var. = ZSAL  and &unite. ne f %then %do ; &var.&unite.&annee.=&var.&unite.*sum(1,eligible_PPE*&&tx_&var._smicf,(1-eligible_PPE)*&&tx_&var._hors_smicf); %end ;
        %else %if &annee.> &asuiv. and  &var. ne ZSAL  %then %do ; &var.&unite.&annee.=&var.&unite.%eval(&annee.-1)*sum(1,&&tx_&var.f); %end ; 	/*seules les variables de la table de départ n'ont pas de suffixe*/ 
        %else %if &annee.> &asuiv. and  &var.= ZSAL and &unite. ne f  %then %do; &var.&unite.&annee.=&var.&unite.%eval(&annee.-1)*sum(1,eligible_PPE*&&tx_&var._smicf,(1-eligible_PPE)*&&tx_&var._hors_smicf);%end ;
    %end ;

    %let i=%eval(&i.+1);
%end;
%mend;

%macro rename(oldvarlist, suffix); 	/*on remet le suffixe de l'année considérée*/
%let k=1;
%do %while(%index(&oldvarlist.,%scan(&oldvarlist.,&k.))>0); 
  %let old = %scan(&oldvarlist, &k); 
        %if &suffix.=&acour. %then %do ; rename &old. = &old.&suffix.; %end ; 
        %else %do ; rename &old.%eval(&suffix.-1) = &old.&suffix.; %end ;
    %let k = %eval(&k + 1);
%end;
%mend;



/**************************************************************************************************************************************************************/
/**************************************************************************************************************************************************************/
/*                       					IV. Vieillissement 2013-> 2014,2014->2015, 2015-->2016 et 2016-2017	                 						      */
/**************************************************************************************************************************************************************/
/**************************************************************************************************************************************************************/


/* 
Taux : 
tx_infl : 	  Taux d'inflation, moyenne annuelle IPC
tx_th : 	  Taux d'évolution de la taxe d'habitation

Coefficients d'actualisation : 
c_sal :  	  coefficient d'actualisation des salaires
c_sal_smic :  coefficient d'actualisation des salaires pour les salariés au SMIC (coefficient d'actualisation du SMIC)
c_cho :  	  coefficient d'actualisation des allocations chômage
c_ret :  	  coefficient d'actualisation des pensions hors pensions alimentaires
c_pen :  	  coefficient d'actualisation des pensions alimentaires
c_rto :  	  coefficient d'actualisation des rentes viagères à titre onéreux
c_int :  	  coefficient d'actualisation des intérêts
c_div :  	  coefficient d'actualisation des dividendes
c_fon :  	  coefficient d'actualisation des revenus fonciers
c_fon_df :    coefficient d'actualisation des revenus fonciers (déficits)
c_agr :  	  coefficient d'actualisation des bénéfices agricoles
c_agr_df :    coefficient d'actualisation des bénéfices agricoles (déficits)
c_bic :  	  coefficient d'actualisation des bénéfices industriels et commerciaux
c_bic_df :    coefficient d'actualisation des bénéfices industriels et commerciaux (déficits)
c_bnc :  	  coefficient d'actualisation des bénéfices non-commerciaux 
c_bnc_df :    coefficient d'actualisation des bénéfices non-commerciaux (déficits)
c_chd :  	  coefficient d'actualisation des charges déductibles
c_av :  	  coefficient d'actualisation de l'assurance vie
c_mv :  	  coefficient d'actualisation des moins-values
c_pvm :  	  coefficient d'actualisation des plus-values mobilières
*/


proc import datafile="&chemin_Saphir_2017.\parametres.xls" out=vieillissement dbms=xls replace;sheet="vieillissement";getnames=yes; run;

data _null_;
set vieillissement;
	/*macro variables de vieillissement entre 2013 et 2014*/
	call symput (cats(coef,&asuiv.),asuiv);
	/*macro variables de vieillissement entre 2014 et 2015*/
	call symput (cats(coef,&asuiv2.),asuiv2);
	/*macro variables de vieillissement entre 2015 et 2016*/
	call symput (cats(coef,&asuiv3.),asuiv3);
	/*macro variables de vieillissement entre 2016 et 2017*/
	call symput (cats(coef,&asuiv4.),asuiv4);
run;

/*c_sal_hors_smic : coefficient d'actualisation des salaires pour les salariés qui ne sont pas au SMIC*/
%let c_sal_hors_smic&asuiv=%sysevalf(100*(((1+&&c_sal&asuiv./100)*&masse_sal_tot.-(1+&&c_sal_smic&asuiv./100)*&masse_sal_smic.)/&masse_sal_hors_smic.-1)); 
%let c_sal_hors_smic&asuiv2.=%sysevalf(100*(((1+&&c_sal&asuiv2./100)*&masse_sal_tot.-(1+&&c_sal_smic&asuiv2./100)*&masse_sal_smic.)/&masse_sal_hors_smic.-1));
%let c_sal_hors_smic&asuiv3. =%sysevalf(100*(((1+&&c_sal&asuiv3./100)*&masse_sal_tot.-(1+&&c_sal_smic&asuiv3./100)*&masse_sal_smic.)/&masse_sal_hors_smic.-1));
%let c_sal_hors_smic&asuiv4=%sysevalf(100*(((1+&&c_sal&asuiv4./100)*&masse_sal_tot.-(1+&&c_sal_smic&asuiv4./100)*&masse_sal_smic.)/&masse_sal_hors_smic.-1));


%macro taux_evol (annee=, listvar=, listindic=) ;
%let i=1;
%do %while(%index(&listvar.,%scan(&listvar.,&i.))>0); 
    %let variable=%scan(&listvar.,&i.); 
    %let ind=%scan(&listindic.,&i.); 
    
    %global tx_&variable.f ;
    %let tx_&variable.f=%sysevalf(&&&ind&annee/100) ; 
    %if &ind. = tx_infl %then %let tx_&variable.f=&&&ind&annee ;
    %let i=%eval(&i.+1);
%end;
%mend;

/**************************************************************************************************************************************************************/
/* 				1- Vieillissement des revenus de la table FOYER13  => FOYER13_R14 FOYER13_R15 FOYER13_R16 FOYER13_R17  				     	 	 		      */
/**************************************************************************************************************************************************************/


data saphir.menage&acour._r&acour. ; set saphir.menage&acour. ; 
%rename(crdssalm csgsaldm csgsalim crdschom csgchodm csgchoim crdsrstm csgrstdm csgrstim crdsragm csgragdm csgragim crdsricm csgricdm
        csgricim crdsrncm csgrncdm csgrncim csgglom csgvalm zimpvalm produitfin assviem m_caahm, &acour.);
run ;

data saphir.indivi&acour._r&acour. ; set saphir.indivi&acour._r&acour. ; 
%rename(crdssal csgsald csgsali crdscho csgchod csgchoi crdsrst csgrstd csgrsti 
        crdsrag csgragd csgragi crdsric csgricd csgrici crdsrnc csgrncd csgrnci ZRTOi ZALRi hs salaire_etr, &acour.);
run ;


%macro vieillissement_par_an (an=);
%let anprec=%sysevalf(&an.-1); 

%taux_evol(annee= &an.,
           listvar=     ZSAL_hors_smic  zsal_smic   zsal zsalopt     ZCHO   ZRST    ZALR    ZRTO    ZRAG    ZRIC    ZRNC    ZFON    ZFONDF    ZETR    ZSALETR   ZGLO    ZMV     ZAV     ZINT    ZDIV    ZALV    ZQUO,
           listindic=  c_sal_hors_smic  c_sal_smic  c_sal c_sal      c_cho  c_ret   c_pen   c_rto   c_agr   c_bic   c_bnc   c_fon   c_fon_df   c_sal  tx_infl   c_pvm   c_mv    c_av    c_int   c_div   c_chd  tx_infl );
 
 
data saphir.foyer&acour._r&an. (compress = yes
keep = ident&acour. idec&acour. noi declar enfach _: psa sif  mnrvkh  PPE_dec1 PPE_dec2 
        ztsaf&an. zsalF&an. zchoF&an. zperf&an. ZRSTF&an. ZALRF&an. ZRTOF&an. ZRAGF&an. ZRICF&an. ZRNCF&an. 
        ZFONF&an. ZVALF&an. ZVAMF&an. ZETRF&an. ZRACF&an. ZALVF&an. ZGLOF&an. ZDIVF&an. ZQUOF&an.);

set saphir.foyer&acour._r&anprec.;



/**************************************************************************************************************************************************************/
/*		a. Vieillissement des cases par groupe                                                                                                                */
/**************************************************************************************************************************************************************/


array ZSALFa   (*) /*DEC1*/_1aj _1aq _8by _1au _1sm /*DEC2*/_1bj _1bq _8cy _1bu _1dn /*PAC1*/_1cj _1cu /*PAC2*/_1dj _1du /*PAC3*/_1ej/*PAC4*/_1fj;
array zsalopta (*) _1TV _1TW _1TX _1UV _1UW _1UX _1TT _1UT ;

array ZCHOFa (*) _1ap _1bp _1cp _1dp _1ep _1fp;
array ZRSTFa (*) _1as _1bs _1cs _1ds _1es _1fs _1at _1bt _1AH _1BH _1CH _1EH _1FH;
array ZALRFa (*) _1ao _1bo _1co _1do _1eo _1fo psa ;
array ZRTOFa (*) _1aw _1bw _1cw _1dw _1AH;


array ZRAGFa (*) _5hn _5in _5jn _5ho _5io _5jo _5hd _5id _5jd _5hb _5hh _5ib _5ih _5jb _5jh _5hc _5hi _5ic _5ii _5jc _5ji 
                 _5jf _5hm _5im _5jm  _5hz _5iz _5jz
                 _5hf _5hl _5if _5il _5jl _5QF _5QG _5QN _5QO _5QP _5QQ /*déficits*/
                 _5he _5hw _5hx _5ie _5iw _5ix _5je _5jw _5jx ; /*plus values*/
                  
array ZRICFa (*) _5ta _5ua _5tb _5ub _5va _5vb /*auto-entrepreneurs*/

                 _5kn _5ln _5mn _5ko _5lo _5mo _5kp _5lp _5mp 
                 _5kb _5kh _5lb _5lh _5mb _5mh _5kc _5ki _5lc _5li _5mc _5mi 
                 _5ha _5ka _5ia _5la _5ja _5ma
                
                 _5KE _5KQ _5KR _5KS _5KX _5KZ _5LE _5LK _5LQ _5LR _5LS _5LX _5ME _5MQ _5MR _5MS _5MX _5NE /*plus values*/
                 _5NQ _5NR _5NX _5OE _5OQ _5OR _5OX _5PE _5PQ _5PR _5PX _5HU
                 _5na _5nb _5nc _5nh _5ni _5nk _5nn _5no _5np _5oa _5op _5ob _5oc _5oh _5oi _5ok _5on _5oo _5pa _5pb _5pc _5ph /*revenus accessoires*/
                 _5pi _5pk _5pn _5po _5pp

                 _5GA _5GB _5GC _5GD _5GE _5GF _5GG _5GH _5GI _5GJ _5KF _5KL _5LF _5LL 
                 _5MF _5NF _5NL _5NY _5NZ _5OF _5OL _5OY _5OZ _5PF _5PL _5PY _5PZ _5QA 
                 _5RA _5RN _5RO _5RP _5RQ _5RR _5RW _5SA ; /*déficits*/



array ZRNCFa (*) _5ue _5te _5ve /*auto-entrepreneurs*/
                 _5hp _5ip _5jp _5hq _5iq _5jq _5qb _5qh _5rb _5rh _5sb _5sh _5qc _5qi _5rc _5ri _5sc _5si 
                 _5qe _5qk _5re _5rk _5se _5sk _5ql _5rl _5sl _5qm _5rm _5tf _5ti _5uf _5ui _5vf _5vi _5jg

                 _5hk _5ik _5jk _5kk _5ku _5lu _5mk _5mu _5ns _5os _5rf _5sf _5sn _5sv _5sw _5sx _5th _5uh _5vh /*revenus accessoires*/

                 _5HR _5HS _5HV _5IR _5IS _5IU _5IV _5JR _5JS _5JU _5JV _5KV _5KW _5KY _5LV _5LW _5LY _5MV _5MW _5MY  /*Plus values*/
                 _5NT _5OT _5QD _5RD _5SD _5SO 
                 _5IT _5JT _5KT _5LT _5ML _5MT _5NU _5OU _5QE _5QJ _5QK _5RE _5RG _5RJ _5RK _5SE _5SG _5SJ _5SK _5SP _5HT _5jj; /*déficits*/

 

array ZALVFa (*) _6gi _6gj _6gk _6gl _6el _6em _6en _6eq _6gp _6gu /*pensions alim versées*/
                 _6cb _6dd _6de _6eu _6fa _6fb _6fc _6fd _6fe _6fl _6gh _6hj _6ps _6pt _6pu 
                 _6qr _6qs _6qt _6qu _6qw _6rs _6rt _6ru _6ss _6st _6su ; 



array ZGLOFa (*)  _3SD _3SE _3SI _3SF _3VA _3VC _3VD _3VE _3VF _3VG _3VI _3VJ _3VK _3VL _3VM _3VN _3VP _3VQ _3VR  
                  _3VT _3VN_3SN _3SJ _3SK   /*plus values et gains divers*/ 
                  _3SL _3SM _3SH _3SG _3VE _3WI _3WJ; 

array ZMVFa  (*)  _3vb _3vh ;

array ZFONFa    (*) _4ba _4be  _4bf _4by _4tq ; 
array ZFONDFFa  (*) _4bb _4bc _4bd ;  

array ZETRFa    (*) _1dy _1ey ; 
array ZsalETRFa (*) _1lz _1mz _8ti _8tl _8tk ;  
                

array ZAVFa  (*) _2dh _2ch ;
array ZINTFa (*) _2ee _2tr _2fa _2ts /*2ab et 2dm non vieillies*/ ; 
array ZDIVFa (*) _2dc _2fu _2go; 
array ZQUOFa (*) _0XX;

/*Attention: mettre les éléments de listevar en Majuscule (macro variable &var dans macro vieillissement)*/
%vieillissement(annee= &an.,listvar= ZSAL ZCHO ZRST ZALR ZRTO ZRAG ZRIC ZRNC ZGLO ZALV ZQUO, unite=f, agregat=1, variable=1);
%vieillissement(annee= &an.,listvar= ZMV ZFON ZFONDF ZSALETR ZETR ZAV ZINT ZDIV, unite=f, agregat=1, variable=0); /*pas d'agrégat associé à l'array ou reconstruit plus loin*/



/**************************************************************************************************************************************************************/
/* 		b.Reconstruction de certains agrégats dont les éléments sont vieillis différemment 																      */
/**************************************************************************************************************************************************************/

ZETRF&an.= sum(_8ti,_1dy,_1ey);
ZFONF&an.= round(sum(_4ba,_4be*0.7,-_4bb,-_4bc),1);  

ZDIVF&an.=sum(_3vg,-_3vh,_3vq,-_3vr,_3se,_3vl,_3vc,_3vm, _3vp,_3vy,_3sj,_3sk,_3vt,_3we,_3wa,_3wb,_3vz,_3wh,_3sb,_3wf,_3wg,_3wd,_3vw,
_5hw,_5iw,_5jw,_5hx,_5ix,_5jx,_5he,_5ie,_5je,_5kx,_5lx,_5mx,_5kq,_5lq,_5mq,_5kr,-_5lr,-_5mr,-_5kj,-_5lj,-_5mj,_5ke,_5le,_5me,
_5nx,_5ox,_5px,_5nq,_5oq,_5pq,-_5nr,-_5or,-_5pr,-_5iu,_5ne,_5oe,_5pe,_5hv,_5iv,_5jv,_5hr,_5ir,_5jr,-_5hs,-_5is,-_5js,
-_5kz,-_5lz,-_5mz,_5qd,_5rd,_5sd,_5ky,_5ly,_5my,_5kv,_5lv,_5mv,-_5kw,-_5lw,-_5mw,-_5ju,_5so,_5nt,_5ot ) ;

ZVALFO&an.= sum(_2ee,_2dh);
ZVAMFO&an.= sum(_2dc,_2fu,_2ch,_2ts,_2go,_2tr,_2fa,_2dm,-_2ab) ;
ZVALF&an. = sum(_2ee);                          			 /* pour la table ménage : agrégat hors assurance-vie*/
ZVAMF&an. = sum(_2dc,_2fu,_2ts,_2go,_2tr,_2fa,_2dm,-_2ab) ;  /* pour la table ménage : agrégat hors assurance-vie*/ 
ZVAf&an.  = sum(ZVALFO&an.,ZVAMFO&an.);
ZGLOF&an. = sum(_1tv,_1tw,_1tx,_1uv,_1uw,_1ux,_1tt,_1ut,_3vf,_3sf,_3vi,_3si,_3vj,_3vk,_3vd,_3sd) ;

%let E2000=305;
ZACCF&an. = sum( _5nd,_5od,_5pd,_5ng,_5og,_5pg,_5nj,_5oj,_5pj,_5nn,_5on,_5pn,_5no,_5oo,_5po,_5np,_5op,_5pp,_5nb,_5nh,_5ob,_5oh,_5pb,_5ph,
                _5nc,_5ni,_5oc,_5oi,_5pc,_5pi,_5na,_5nk,_5oa,_5ok,_5pa,_5pk,_5nm,_5km,_5om,_5lm,_5pm,_5mm,- _5nf,- _5nl,- _5of,- _5ol,- _5pf,- _5pl,
                - _5ny,- _5nz,- _5oy,- _5oz,- _5py,- _5pz,_5th,_5uh,_5vh,_5ku,_5lu,_5mu,_5hk, _5ik, _5jk, _5kk, _5lk, _5mk,_5jg, _5sn, _5rf, _5ns,
                _5sf, _5os, -_5jj, - _5sp,-_5rg,- _5nu,-_5sg, - _5ou,_5tc, _5uc, _5vc,_5sv, _5sw,_5sx);
CACCF&an.=    sum(min(_5ND,max(&E2000.,_5ND*0.50)), min(_5OD,max(&E2000.,_5OD*0.50)), min(_5PD,max(&E2000.,_5PD*0.50)),
                  min(_5NG,max(&E2000.,_5NG*0.71)), min(_5OG,max(&E2000.,_5OG*0.71)), min(_5PG,max(&E2000.,_5PG*0.71)),
                  min(_5NJ,max(&E2000.,_5NJ*0.71)), min(_5OJ,max(&E2000.,_5OJ*0.71)), min(_5PJ,max(&E2000.,_5PJ*0.71)),
                  min(_5NO,max(&E2000.,_5NO*0.71)), min(_5OO,max(&E2000.,_5OO*0.71)), min(_5PO,max(&E2000.,_5PO*0.71)),
                  min(_5NP,max(&E2000.,_5NP*0.50)), min(_5OP,max(&E2000.,_5OP*0.50)), min(_5PP,max(&E2000.,_5PP*0.50)),
                  min(_5KU,max(&E2000.,_5KU*0.34)), min(_5LU,max(&E2000.,_5LU*0.34)), min(_5MU,max(&E2000.,_5MU*0.34)));
ZRACF&an.=sum(zaccf&an.,-round(CACCF&an.,1));

ZTSAf&an.=sum(zsalf&an.,zchof&an.);
ZPERf&an.=sum(zrstf&an.,zalrf&an.,zrtof&an.);


/*Vieillissement des frais réels comme l'inflation*/
_1ak=_1ak*(1+&&tx_infl&an.);
_1bk=_1bk*(1+&&tx_infl&an.);
_1ck=_1ck*(1+&&tx_infl&an.);
_1dk=_1dk*(1+&&tx_infl&an.);

run;




/**************************************************************************************************************************************************************/
/* 				2- Vieillissement des revenus de la table INDIVI13 => INDIVI13_r14 INDIVI13_r15 INDIVI13_r16 INDIVI13_r17 								      */
/**************************************************************************************************************************************************************/

data saphir.indivi&acour._r&an.(compress = yes
keep = ident&acour. noi eligible_PPE
zsali&an. zchoi&an. ZRSTi&an. ZALRi&an. ZRTOi&an. ZRAGi&an. ZRICi&an. ZRNCi&an. 
zsalo&an. zchoo&an. ZRSTo&an. ZRAGo&an. ZRICo&an. ZRNCo&an. 
crdssal&an. csgsald&an. csgsali&an. 
crdscho&an. csgchod&an. csgchoi&an.
crdsrst&an. csgrstd&an. csgrsti&an. crdsrag&an. csgragd&an. csgragi&an.
crdsric&an. csgricd&an. csgrici&an. crdsrnc&an. csgrncd&an. csgrnci&an. hs&an. salaire_etr&an. );

set saphir.indivi&acour._r&anprec.;


/*La CSG et la CRDS sont vieillies au même rythme que les revenus*/
array zsalfa (*) crdssal&anprec. csgsald&anprec. csgsali&anprec.;
array zchofa (*) crdscho&anprec. csgchod&anprec. csgchoi&anprec.;
array zrstfa (*) crdsrst&anprec. csgrstd&anprec. csgrsti&anprec.;
array zragfa (*) crdsrag&anprec. csgragd&anprec. csgragi&anprec.;
array zricfa (*) crdsric&anprec. csgricd&anprec. csgrici&anprec.;
array zrncfa (*) crdsrnc&anprec. csgrncd&anprec. csgrnci&anprec.;


%vieillissement(annee=&an.,listvar= ZSAL ZCHO ZRST ZRAG ZRIC ZRNC, unite=i, agregat=1, variable=1);
%vieillissement(annee=&an.,listvar= ZSAL ZCHO ZRST ZRAG ZRIC ZRNC, unite=o, agregat=0, variable=1);

%rename(crdssal csgsald csgsali crdscho csgchod csgchoi crdsrst csgrstd csgrsti 
        crdsrag csgragd csgragi crdsric csgricd csgrici crdsrnc csgrncd csgrnci, &an.);


/*Correction de certains agrégats*/

ZALRi&an.=ZALRi&anprec.*sum(1,&&tx_infl&an.);
ZRTOi&an.=ZRTOi&anprec.*sum(1,&&tx_infl&an.);
if eligible_PPE=1 then hs&an.=hs&anprec.*sum(1,&&c_sal_smic&an./100); else hs&an.=hs&anprec.*sum(1,&&c_sal_hors_smic&an./100); 
salaire_etr&an.=salaire_etr&anprec.*sum(1,&&tx_infl&an.);

run;




/**************************************************************************************************************************************************************/
/* 				3- Vieillissement des revenus de la table MENAGE13  => MENAGE13_r14 MENAGE13_r15 MENAGE13_r16 MENAGE13_r17                                    */
/**************************************************************************************************************************************************************/

/*Récupération des variables salaires de la table indiv (qui sont vieillies différemment pour chaque membre du ménage)*/
proc sort data=saphir.indivi&acour._r&an. ; by ident&acour. ; run ;
proc means data=saphir.indivi&acour._r&an. noprint ; var zsali&an. crdssal&an. csgsald&an. csgsali&an. ; by ident&acour. ; output out=sal_men (drop=_:) sum= ; run ;
data menage&acour._r&anprec.; merge saphir.menage&acour._r&anprec. sal_men (rename=(zsali&an.=zsalm&an. crdssal&an.=crdssalm&an. csgsald&an.=csgsaldm&an. csgsali&an.=csgsalim&an.)); by ident&acour. ;
run; 

/*Récupération des agrégat composites de la table foyer qui ne font pas (ou peu) l'objet d'imputation*/
proc sort data=saphir.foyer&acour._r&an. ; by ident&acour. ; run ;
proc means data=saphir.foyer&acour._r&an. noprint ; 
var ZETRF&an. ZDIVF&an. ZQUOF&an. ZRACF&an. ZFONF&an. ZVALF&an. ZVAMF&an. ; by ident&acour. ; output out=ag_foyer&an. (drop=_:) sum= ; run ;

data menage&acour._r&anprec.;  merge menage&acour._r&anprec.  ag_foyer&an. ;  by ident&acour. ; 
%macro agregation (var_agr=) ;
%let k=1;
%do %while(%index(&var_agr.,%scan(&var_agr.,&k.))>0); 
  %let var = %scan(&var_agr., &k);      
    &var.m&an. = &var.f&an. ; if &var.f&an.=. then &var.m&an.=0 ;
    %if &an.=&asuiv. and &var.= ZFON %then %do ; if &var.m&an.=0 and &var.m>0 then &var.m&an.=&var.m*sum(1,&&tx_&var.f) ; %end ;
    %else %if &an.>&asuiv. and &var.= ZFON %then %do ; if &var.m&an.=0 and &var.m&anprec.>0 then &var.m&an.=&var.m&anprec.*sum(1,&&tx_&var.f) ; %end ;
    %let k = %eval(&k + 1);
%end;
%mend ; %agregation  (var_agr=ZETR ZDIV ZRAC ZFON ZVAL ZVAM);run; 


data saphir.menage&acour._r&an. (compress = yes
keep = ident&acour.  produitfin&an. assviem&an. m_caahm&an.
zsalm&an. zchom&an. ZRSTm&an. ZALRm&an. ZRTOm&an. ZRAGm&an. ZRICm&an. ZRNCm&an. 
ZFONm&an. ZVALm&an. ZVAMm&an. ZETRm&an. ZRACm&an. ZALVm&an. ZGLOm&an. ZDIVm&an. ZQUOm&an. zthabm: 
crdssalm&an. csgsaldm&an. csgsalim&an. crdschom&an. csgchodm&an. csgchoim&an.
crdsrstm&an. csgrstdm&an. csgrstim&an. crdsragm&an. csgragdm&an. csgragim&an.
crdsricm&an. csgricdm&an. csgricim&an. crdsrncm&an. csgrncdm&an. csgrncim&an.
csgvalm&an. csgglom&an. zimpvalm&an.);

set menage&acour._r&anprec.;

array zchofa (*) crdschom&anprec. csgchodm&anprec. csgchoim&anprec.;
array zrstfa (*) crdsrstm&anprec. csgrstdm&anprec. csgrstim&anprec.;
array zragfa (*) crdsragm&anprec. csgragdm&anprec. csgragim&anprec.;
array zricfa (*) crdsricm&anprec. csgricdm&anprec. csgricim&anprec.;
array zrncfa (*) crdsrncm&anprec. csgrncdm&anprec. csgrncim&anprec.;
array zglofa (*) csgglom&anprec.;


%vieillissement(annee= &an., listvar= ZCHO ZRST ZRAG ZRIC ZRNC ZGLO, unite=m, agregat=1, variable=1);
%vieillissement(annee= &an., listvar= ZALR ZALV ZRTO ZQUO, unite=m, agregat=0, variable=1);

%rename(crdschom csgchodm csgchoim crdsrstm csgrstdm csgrstim 
crdsragm csgragdm csgragim crdsricm csgricdm csgricim crdsrncm csgrncdm csgrncim csgglom,&an.);


/*ZTHABM : taxe d'habitation*/
%if &an.=&asuiv. %then zthabm&an.=zthabm*sum(1,&&tx_th&asuiv.); /*dans l'ERFS 2013, zthabm désigne la TH de l'année N=2013*/
%if &an.=&asuiv2. %then zthabm&an.=zthabm&anprec.*sum(1,&&tx_th&asuiv2.);
%if &an.=&asuiv3. %then zthabm&an.=zthabm&anprec.*sum(1,&&tx_th&asuiv3.);
%else %if &an. > &asuiv3. %then zthabm&an.=zthabm&anprec.*sum(1,&&tx_th&asuiv4.);;


/*Vieillissement de la CSG et des prélèvements libératoires des valeurs mobilières*/
csgvalm&an.=csgvalm&anprec.*sum(1,&&c_int&an./100);
zimpvalm&an.=zimpvalm&anprec.*sum(1,&&c_int&an./100);

assviem&an.=assviem&anprec.*sum(1,&&c_av&an./100);
produitfin&an.=produitfin&anprec.*sum(1,&&c_av&an./100); /*on vieillit comme les assurances vie*/

m_caahm&an.=m_caahm&anprec.*sum(1,&&tx_infl&an.);

run;

%mend;

%vieillissement_par_an (an=&asuiv.);
%vieillissement_par_an (an=&asuiv2.);
%vieillissement_par_an (an=&asuiv3.);
%vieillissement_par_an (an=&asuiv4.);

proc datasets library=work;delete sal_men ag_foyer: menage:;run;quit;

/*************************************************************************************************************************************************************
**************************************************************************************************************************************************************

Ce logiciel est régi par la licence CeCILL V2.1 soumise au droit français et respectant les principes de diffusion des logiciels libres. 

Vous pouvez utiliser, modifier et/ou redistribuer ce programme sous les conditions de la licence CeCILL V2.1. 

Le texte complet de la licence CeCILL V2.1 est dans le fichier `LICENSE`.

Les paramètres de la législation socio-fiscale figurant dans les programmes 6, 7a et 7b sont régis par la « Licence Ouverte / Open License » Version 2.0.
**************************************************************************************************************************************************************
*************************************************************************************************************************************************************/

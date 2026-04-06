dm log 'clear';
dm output 'clear';

/* ================================================================
   SAE 4.EMS.01 - Mod�lisation lin�aire - PACA
   Travail en Binome : Ahmed TERIR et Zakaria CHAREF
   ================================================================ */

/* ----------------------------------------------------------------
   IMPORT
   ---------------------------------------------------------------- */
PROC IMPORT
    DATAFILE="C:\Users\264587\Downloads\27032026\27032026\etablissements-cinematographiques.csv"
    OUT=TABLE_CINEMA
    DBMS=DLM REPLACE;
    DELIMITER=';';
    GETNAMES=YES;
RUN;

/* ----------------------------------------------------------------
   RENOMMAGE (noms avec espaces conserv�s par SAS Academic)
   ---------------------------------------------------------------- */
DATA cinema_paca;
    SET TABLE_CINEMA;
    IF STRIP(region_administrative) = "PROVENCE-ALPES-COTE D'AZUR";

    /* Renommage */
    entrees_2022      = entrees_2022;
    entrees_2021      = entrees_2021;
    pop_commune       = population_de_la_commune;
    pop_uu            = population_unite_urbaine;
    semaines_activite = semaines_d_activite;
    sit_geo           = situation_geographique;
    nb_films_prog     = nombre_de_films_programmes;
    nb_films_inedits  = nombre_de_films_inedits;
    nb_films_sem1     = nombre_de_films_en_semaine_1;
    nb_films_ae       = films_Art_et_Essai;
    evol_entrees      = evolution_entrees;
    zone_commune      = zone_de_la_commune;

    KEEP nom entrees_2022 entrees_2021 pop_commune pop_uu
         semaines_activite sit_geo nb_films_prog nb_films_inedits
         nb_films_sem1 nb_films_ae evol_entrees zone_commune
         ecrans fauteuils seances multiplexe region_administrative;
RUN;

PROC FREQ DATA=cinema_paca; TABLES region_administrative; RUN;
PROC PRINT DATA=TABLE_CINEMA (OBS=3); RUN;
/* ----------------------------------------------------------------
   FILTRE PACA
   ---------------------------------------------------------------- */
DATA cinema_paca;
    SET TABLE_CINEMA;
    IF STRIP(region_administrative) = "PROVENCE-ALPES-COTE D'AZUR";
RUN;

PROC FREQ DATA=cinema_paca; TABLES region_administrative; RUN;

/* ----------------------------------------------------------------
   CREATION VARIABLES TRANSFORMEES
   ---------------------------------------------------------------- */
DATA cinema_paca_log_racine;
    SET cinema_paca;
    IF entrees_2022 > 0 AND fauteuils > 0 AND seances > 0;
    log_entrees = LOG(entrees_2022);
    racine_entrees = SQRT(entrees_2022);

RUN;


/* ================================================================
   PARTIE 1  R�GRESSION LIN�AIRE SIMPLE
   ================================================================ */

dm log 'clear';
dm output 'clear';

/* Analyse descriptive de la variable d�pendante */
TITLE "Analyse descriptive de entrees_2022 (PACA)";
PROC UNIVARIATE DATA=cinema_paca NORMAL;
    VAR entrees_2022;
    HISTOGRAM entrees_2022 / NORMAL;
    INSET N MEAN STD / POSITION=NE;
RUN;
TITLE;

/* R�gression simple : entrees_2022 = f(fauteuils) */
TITLE "R�gression lin�aire simple : entrees_2022 = f(fauteuils)";
PROC REG DATA=cinema_paca;
    MODEL entrees_2022 = fauteuils / CLB DWprob R INFLUENCE;
    OUTPUT OUT=residu_simple R=res;
RUN;
QUIT;
TITLE;

/* Normalit� des r�sidus */
TITLE "Normalit� des r�sidus - mod�le simple";
PROC UNIVARIATE DATA=WORK.residu_simple NORMAL;
    VAR res;
    QQPLOT res / NORMAL(MU=EST SIGMA=EST COLOR=RED);
RUN;
QUIT;
TITLE;

/* Suppression des observations mal reconstitu�es et influentes */
DATA cinema_paca_clean1var;
    SET residu_simple;
    IF _N_ NOT IN (1, 15, 22, 65, 68, 82, 95, 104, 127, 131, 
                   155, 166, 168, 183, 190, 199);
RUN;

/* R�gression simple apres la suppression : entrees_2022 = f(fauteuils) */
TITLE "R�gression lin�aire simple avec valeurs supprim�es : entrees_2022 = f(fauteuils)";
PROC REG DATA=cinema_paca_clean1var;
    MODEL entrees_2022 = fauteuils / CLB DWprob R INFLUENCE;
    OUTPUT OUT=residu_simple_sup R=res;
RUN;
QUIT;
TITLE;

/* Normalit� des r�sidus apres la suppression */
TITLE "Normalit� des r�sidus apres la suppression - mod�le simple";
PROC UNIVARIATE DATA=residu_simple_sup NORMAL;
    VAR res;
    QQPLOT res / NORMAL(MU=EST SIGMA=EST COLOR=RED);
RUN;
QUIT;
TITLE;

/* Test changement de variable */
/* R�gression simple apres la suppression : racine(entrees_2022) = f(fauteuils) */
TITLE "R�gression lin�aire simple avec valeurs supprim�es : racine entrees_2022 = f(fauteuils)";
PROC REG DATA=cinema_paca_log_racine;
    MODEL racine_entrees = fauteuils / CLB DWprob R INFLUENCE;
    OUTPUT OUT=residu_simple_sup R=res;
RUN;
QUIT;
TITLE;

/* Normalit� des r�sidus apres la suppression */
TITLE "Normalit� des r�sidus apres la suppression - mod�le simple";
PROC UNIVARIATE DATA=residu_simple_sup NORMAL;
    VAR res;
    QQPLOT res / NORMAL(MU=EST SIGMA=EST COLOR=RED);
RUN;
QUIT;
TITLE;


















/* ================================================================
   PARTIE 2  ReGRESSION a 2 VARIABLES
   Modéle : log(entrees_2022) = f(fauteuils, seances)
   ================================================================ */

dm log 'clear';
dm output 'clear';

/* R�gression log(entrees_2022) = f(fauteuils, seances) */
TITLE "r�gression 2 variables : log(entrees_2022) = f(fauteuils, seances)";
PROC REG DATA=cinema_paca_log_racine PLOTS(MAXPOINTS=NONE)=ALL;
    MODEL log_entrees = fauteuils seances
                        / VIF CLB DWprob R INFLUENCE SPEC;
    OUTPUT OUT=residu_2var
           PREDICTED=yhat
           RESIDUAL=res
           RSTUDENT=res_stud
           H=levier
           COOKD=cook;
RUN;
QUIT;
TITLE;

/* H2 - Normalit� des r�sidus */
TITLE "Normalit� des r�sidus - 2 variables";
PROC UNIVARIATE DATA=residu_2var NORMAL;
    VAR res;
    QQPLOT res / NORMAL(MU=EST SIGMA=EST COLOR=RED);
RUN;
QUIT;
TITLE;



/* Identification points influents */
TITLE "Points influents identifi�";
PROC PRINT DATA=residu_2var;
    WHERE ABS(res_stud) > 2 OR cook > (4/199);
    VAR nom entrees_2022 fauteuils seances res_stud levier cook;
RUN;
TITLE;

/* Suppression points influents */
DATA cinema_paca_clean;
    SET residu_2var;
    IF ABS(res_stud) <= 2 AND cook <= (4/199);
    KEEP nom entrees_2022 log_entrees fauteuils seances
         pop_commune ecrans semaines_activite
         nb_films_prog nb_films_inedits nb_films_sem1
         nb_films_ae sit_geo multiplexe;
RUN;

/* R�gression apr�s nettoyage */
TITLE "R�gression apr�s suppression points influents";
PROC REG DATA=cinema_paca_clean PLOTS(MAXPOINTS=NONE)=ALL;
    MODEL log_entrees = fauteuils seances
                        / VIF CLB DWprob R INFLUENCE SPEC;
    OUTPUT OUT=residu_clean
           PREDICTED=yhat
           RESIDUAL=res
           RSTUDENT=res_stud
           H=levier
           COOKD=cook;
RUN;
QUIT;
TITLE;

/* Normalit� apr�s nettoyage */
TITLE "Normalit� des r�sidus apr�s suppression points influents";
PROC UNIVARIATE DATA=residu_clean NORMAL;
    VAR res;
    QQPLOT res / NORMAL(MU=EST SIGMA=EST COLOR=RED);
RUN;
QUIT;
TITLE;




/* TEST R�gression : racine(entrees_2022) = f(fauteuils, seances) */

/* R�gression : racine(entrees_2022) = f(fauteuils, seances) */
TITLE "R�ression 2 variables : racine(entrees_2022) = f(fauteuils, seances)";
PROC REG DATA= cinema_paca_log_racine PLOTS(MAXPOINTS=NONE)=ALL;
    MODEL racine_entrees = fauteuils seances
                          / VIF CLB DWprob R INFLUENCE SPEC;
    OUTPUT OUT=residu_racine
           PREDICTED=yhat
           RESIDUAL=res
           RSTUDENT=res_stud
           H=levier
           COOKD=cook;
RUN;
QUIT;
TITLE;

/* Normalit� des r�sidus */
TITLE "Normalit� des r�sidus - racine(entrees_2022)";
PROC UNIVARIATE DATA=residu_racine NORMAL;
    VAR res;
    QQPLOT res / NORMAL(MU=EST SIGMA=EST COLOR=RED);
RUN;
QUIT;
TITLE;




/* TEST R�gression : log(entrees_2022) = f(fauteuils, semaines_activite) */

TITLE "r�gression 2 variables : log(entrees_2022) = f(fauteuils, semaines_activite)";
PROC REG DATA=cinema_paca_log_racine PLOTS(MAXPOINTS=NONE)=ALL CORR;
    MODEL log_entrees = fauteuils semaines_d_activite
                        / VIF CLB DWprob R INFLUENCE SPEC;
    OUTPUT OUT=residu2varfauteuil_s_a
           PREDICTED=yhat
           RESIDUAL=res
           RSTUDENT=res_stud
           H=levier
           COOKD=cook;
RUN;
QUIT;
TITLE;

/* H2 - Normalit� des r�sidus */
TITLE "Normalit� des r�sidus - 2 variables fauteuils semaines_activite";
PROC UNIVARIATE DATA=residu2varfauteuil_s_a NORMAL;
    VAR res;
    QQPLOT res / NORMAL(MU=EST SIGMA=EST COLOR=RED);
RUN;
QUIT;
TITLE;

























/* ================================================================
   PARTIE 3  R�GRESSION MULTIPLE (3 variables et plus)
   ================================================================ */

dm log 'clear';
dm output 'clear';
PROC PRINT DATA=cinema_paca_log_racine;
RUN;
/* Mod�le avec toutes les variables quantitatives */
TITLE "R�gression multiple - toutes les variables";
PROC REG DATA=cinema_paca_log_racine;
    MODEL log_entrees = fauteuils seances ecrans
                        population_de_la_commune population_unite_urbaine
                        semaines_d_activite
                        nombre_de_films_programmes nombre_de_films_inedits nombre_de_films_en_semaine_1
                        films_Art_et_Essai;
RUN;
QUIT;
TITLE;

/* Diagnostics complets VIF / DW / résidus / leviers */
TITLE "R�gression multiple compl�te - diagnostics";
PROC REG DATA=cinema_paca_log_racine CORR;
    MODEL log_entrees = fauteuils seances ecrans
                        population_de_la_commune population_unite_urbaine
                        semaines_d_activite
                        nombre_de_films_programmes nombre_de_films_inedits nombre_de_films_en_semaine_1
                        films_Art_et_Essai 
                        / VIF CLB DWprob R INFLUENCE SPEC;
    OUTPUT OUT=residu_multi R=res H=levier;
RUN;
QUIT;
TITLE;

/* On applique une methode de s�l�ction */


/* Sélection stepwise */
TITLE "Sélection stepwise ";
PROC REG DATA=cinema_paca_log_racine;
    MODEL log_entrees = fauteuils seances ecrans
                        pop_commune pop_uu
                        semaines_activite
                        nb_films_prog nb_films_inedits nb_films_sem1
                        nb_films_ae
                        / SELECTION=STEPWISE SLE=0.05 SLS=0.05 DETAILS;
RUN;
QUIT;
TITLE;

/* Diagnostics complets VIF / DW / rÃ©sidus / leviers */
TITLE "Régression multiple compléte - diagnostics";
PROC REG DATA=cinema_paca_log_racine CORR;
    MODEL log_entrees = seances
                        pop_commune
                        semaines_activite
                        nb_films_sem1
                        / VIF CLB DWprob R INFLUENCE SPEC;
    OUTPUT OUT=residu_multi R=res H=levier PREDICTED=ybar LCLM=borne_inf UCLM=borne_sup;
RUN;
QUIT;
TITLE;

TITLE "Normalité des résidus - modéle multiple";
PROC UNIVARIATE DATA=residu_multi NORMAL;
    VAR res;
    QQPLOT res / NORMAL(MU=EST SIGMA=EST COLOR=RED);
RUN;
QUIT;
TITLE;

/* Prevsions pour les 5 cinemas qu on a selectionee  */
PROC PRINT DATA=residu_multi;
    WHERE nom IN ('CINEMAUV', 'UGC CINE CITE CONFLUENCE', 
                  'CGR ALBI', 'LE PARC', 'ESPACE LUMIERE');
    VAR nom ybar borne_inf borne_sup;
RUN;

TITLE;






----------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------












/* ================================================================
   PARTIE 4 ANOVA A UN FACTEUR
   ================================================================ */

dm log 'clear';
dm output 'clear';

/* ANOVA sur sit_geo */
TITLE "ANOVA - entrees_2022 selon la situation g�ographique";
PROC ANOVA DATA=WORK.cinema_paca;
    CLASS situation_geographique;
    MODEL entrees_2022 = situation_geographique;
    MEANS situation_geographique / T CLM HOVTEST CLDIFF LINES;
RUN;
QUIT;
TITLE;

/* ANOVA GLM + rÃ©sidus */
ODS GRAPHICS ON;
TITLE "ANOVA GLM - entrees_2022 selon sit_geo";
PROC GLM DATA=WORK.cinema_paca;
    CLASS sit_geo;
    MODEL entrees_2022 = sit_geo;
    MEANS sit_geo / T CLM HOVTEST;
    OUTPUT OUT=WORK.residu_anova R=res;
RUN;
ODS GRAPHICS OFF;
TITLE;

TITLE "NormalitÃ© des rÃ©sidus - ANOVA sit_geo";
PROC UNIVARIATE DATA=WORK.residu_anova NORMAL;
    VAR res;
RUN;
QUIT;
TITLE;

/* ANOVA sur multiplexe */
ODS GRAPHICS ON;
TITLE "ANOVA GLM - entrees_2022 selon multiplexe (OUI/NON)";
PROC GLM DATA=WORK.cinema_paca;
    CLASS multiplexe;
    MODEL entrees_2022 = multiplexe;
    MEANS multiplexe / T CLM HOVTEST;
    OUTPUT OUT=WORK.residu_mult R=res2;
RUN;
ODS GRAPHICS OFF;
TITLE;

TITLE "NormalitÃ© des rÃ©sidus - ANOVA multiplexe";
PROC UNIVARIATE DATA=WORK.residu_mult NORMAL;
    VAR res2;
RUN;
QUIT;
TITLE;

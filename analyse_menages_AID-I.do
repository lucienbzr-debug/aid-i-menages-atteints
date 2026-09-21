/*==============================================================================
    PROJET AID-I (Great Lakes Accelerated Innovation Delivery Initiative)
    Composante Rikolto - Sud-Kivu, RD Congo
    Analyse des menages/participants atteints (avril 2023 - decembre 2024)

    OBJECTIF : reconstituer la base consolidee des menages/participants uniques
    touches par le projet, calculer l'evolution trimestrielle des realisations
    et produire les tableaux de bord necessaires au rapport de direction.

    Auteur : analyse automatisee - a executer avec Stata (import excel)
    Donnees source (dans le meme dossier que ce .do) :
      1) Rikolto_Project_participants_todate_08_07_without_duplicates_189 461.xlsx
         -> cumul des participants uniques, T2-2023 a T3-2024 (partiel)
      2) Rikolto_Q3_0907_3009_Number_project_participants_without_duplicates_ 18 058.xlsx
         -> lot T3-2024 (juillet-septembre 2024)
      3) Rikolto_Number_participants_Q4_2024_without_duplicates_ 54 250.xlsx
         -> lot T4-2024 (octobre-decembre 2024)
==============================================================================*/

clear all
set more off
capture log close
cd "`c(pwd)'"
log using "analyse_menages_AID-I_log.log", replace text

*-------------------------------------------------------------------------
* 1. IMPORT ET HARMONISATION DES 3 EXTRACTIONS "SANS DOUBLONS"
*-------------------------------------------------------------------------
tempfile batch1 batch2 batch3

import excel "Rikolto_Project_participants_todate_08_07_without_duplicates_189 461.xlsx", ///
    sheet("Sheet1") firstrow case(preserve) clear
gen batch = "cum_to_2024Q3"
keep ID Age Gender ParticipantType Country Province Territory District City ///
     Startdate Quarter Events Partner Partnership crop technologies_disseminated ///
     inputs_distributed batch
save `batch1'

import excel "Rikolto_Q3_0907_3009_Number_project_participants_without_duplicates_ 18 058.xlsx", ///
    sheet("Sheet1") firstrow case(preserve) clear
gen batch = "2024Q3"
keep ID Age Gender ParticipantType Country Province Territory District City ///
     Startdate Quarter Events Partner Partnership crop technologies_disseminated ///
     inputs_distributed batch
save `batch2'

import excel "Rikolto_Number_participants_Q4_2024_without_duplicates_ 54 250.xlsx", ///
    sheet("Sheet1") firstrow case(preserve) clear
gen batch = "2024Q4"
keep ID Age Gender ParticipantType Country Province Territory District City ///
     Startdate Quarter Events Partner Partnership crop technologies_disseminated ///
     inputs_distributed batch
save `batch3'

*-------------------------------------------------------------------------
* 2. EMPILEMENT + DEDUPLICATION SUR L'IDENTIFIANT MENAGE/PARTICIPANT
*-------------------------------------------------------------------------
use `batch1', clear
append using `batch2'
append using `batch3'

destring ID, replace force
duplicates tag ID, gen(dup)
duplicates drop ID, force          // conserve 1 ligne par menage/participant unique
drop dup

gen participant_type = strtrim(ParticipantType)
label var participant_type "Type de participant"

* Nombre total de menages/participants uniques atteints par le projet
count
display as result "TOTAL MENAGES/PARTICIPANTS UNIQUES ATTEINTS : " r(N)
* -> doit etre proche de 261 766 (chiffre officiel infographie AID-I, mars 2025)

save "aidi_households_master_stata.dta", replace

*-------------------------------------------------------------------------
* 3. EVOLUTION TRIMESTRIELLE DES REALISATIONS (cumul)
*-------------------------------------------------------------------------
preserve
    contract Quarter, freq(new_households)
    gsort Quarter
    gen cumulative_households = sum(new_households)
    format new_households cumulative_households %12.0fc
    list Quarter new_households cumulative_households, sep(0)
    export delimited using "evolution_trimestrielle.csv", replace
restore

*-------------------------------------------------------------------------
* 4. VENTILATIONS CLES POUR LE TABLEAU DE BORD / RAPPORT
*-------------------------------------------------------------------------
* Par genre
tab Gender, missing
* Par tranche d'age
tab Age, missing
* Croisement age x genre
tab Age Gender, missing
* Par territoire (Sud-Kivu)
tab Territory, missing sort
* Par type de participant
tab participant_type, missing sort
* Par partenaire de mise en oeuvre
tab Partner, missing sort
* Par type d'evenement (modalite de contact)
tab Events, missing sort

* Taux d'atteinte par rapport a la cible FY23-24 (245 000 exploitants agricoles)
count
scalar total_reached = r(N)
scalar target_fy2324 = 245000
scalar achievement_rate = 100 * total_reached / target_fy2324
display as result "Taux d'atteinte vs cible FY23-24 (245 000) : " %6.1f achievement_rate "%"

*-------------------------------------------------------------------------
* 5. EXPORTS POUR LE TABLEAU DE BORD (dashboard HTML) ET LE RAPPORT
*-------------------------------------------------------------------------
preserve
    contract Gender, freq(n)
    export delimited using "dash_gender.csv", replace
restore
preserve
    contract Age, freq(n)
    export delimited using "dash_age.csv", replace
restore
preserve
    contract Territory, freq(n)
    export delimited using "dash_territory.csv", replace
restore
preserve
    contract Partner, freq(n)
    export delimited using "dash_partner.csv", replace
restore

*-------------------------------------------------------------------------
* 6. ANALYSES APPROFONDIES POUR L'ARGUMENTAIRE BAILLEURS
*-------------------------------------------------------------------------
* 6.1 Effet de levier du modele d'extension (paysans relais / VBA)
count if participant_type == "Farmers"
scalar n_farmers = r(N)
count if participant_type == "Lead farmers"
scalar n_lead = r(N)
scalar leverage_ratio = n_farmers / n_lead
display as result "Effet de levier (exploitants par paysan relais) : " %5.1f leverage_ratio

* 6.2 Part des menages ayant recu un intrant tangible vs sensibilisation seule
count if !missing(inputs_distributed)
scalar n_with_input = r(N)
display as result "Menages avec intrant tangible : " %6.1f 100*n_with_input/total_reached "%"

* 6.3 Equite territoriale : part des femmes et des jeunes par territoire
preserve
    contract Territory Gender, freq(n)
    reshape wide n, i(Territory) j(Gender) string
    gen pct_female = 100*nFemale/(nFemale+nMale)
    gsort -pct_female
    list Territory pct_female, sep(0)
    export delimited using "equity_gender_territory_stata.csv", replace
restore
preserve
    contract Territory Age, freq(n)
    reshape wide n, i(Territory) j(Age) string
    gen pct_youth = 100*n15_29/(n15_29+n30plus)
    gsort -pct_youth
    export delimited using "equity_age_territory_stata.csv", replace
restore

* 6.4 Equite par partenaire : part des femmes
preserve
    contract Partner Gender, freq(n)
    reshape wide n, i(Partner) j(Gender) string
    gen pct_female = 100*nFemale/(nFemale+nMale)
    gsort -pct_female
    list Partner pct_female, sep(0)
    export delimited using "equity_gender_partner_stata.csv", replace
restore

* 6.5 Specialisation geographique des partenaires (matrice territoire x partenaire)
preserve
    contract Territory Partner, freq(n)
    reshape wide n, i(Territory) j(Partner) string
    export delimited using "partner_territory_matrix_stata.csv", replace
restore

* 6.6 Diversification culturale et profondeur technologique par menage
* (necessite le champ texte multi-valeurs crop / technologies_disseminated :
*  compter le nombre de mots distincts par observation)
gen n_crops = wordcount(crop) if !missing(crop)
gen n_tech  = wordcount(technologies_disseminated) if !missing(technologies_disseminated)
summarize n_crops if !missing(crop)
summarize n_tech if !missing(technologies_disseminated)

log close
exit

# AID-I Sud-Kivu — Suivi des ménages atteints

Analyse de suivi-évaluation du projet **AID-I** (Great Lakes Accelerated Innovation
Delivery Initiative — Feed the Future / USAID), composante mise en œuvre par
**Rikolto** dans la province du Sud-Kivu (RD Congo).

L'objectif : reconstituer, à partir des exports bruts du système de suivi des
participants, une base consolidée et dédupliquée des ménages/participants
atteints, calculer l'évolution trimestrielle des réalisations, et produire un
tableau de bord et un rapport de direction.

## Résultat clé

| Indicateur | Valeur |
|---|---|
| Ménages / participants uniques atteints (avr. 2023 – déc. 2024) | **261 765** |
| Cible FY23-24 (exploitants agricoles) | 245 000 |
| Taux d'atteinte de la cible | **106,8 %** |
| Chiffre officiel de clôture (infographie AID-I, 31 mars 2025) | 261 766 |
| Écart base consolidée vs chiffre officiel | 1 (0,0004 %) |

Le total reconstitué recoupe à **99,9996 %** le chiffre officiel de clôture du
projet, ce qui constitue une validation indépendante du résultat phare
communiqué aux bailleurs.

## Contenu du dépôt

| Fichier | Description |
|---|---|
| `Rapport_AID-I_Menages_Atteints_complet.pdf` / `Rapport_AID-I_Menages_Atteints.docx` | Rapport de direction (résumé exécutif, méthodologie, résultats, recommandations, argumentaire bailleurs) |
| `analyse_menages_AID-I.do` | Script **Stata** : import des 3 extractions sources, empilement, déduplication par identifiant, tabulations et exports |
| `aidi_menages_base_consolidee.csv` | Base consolidée et dédupliquée (261 765 lignes, champs anonymisés — voir [Données et confidentialité](#données-et-confidentialité)) |
| `aidi_menages_base_consolidee.dta` | Même base au format Stata (106 Mo — **non versionnée** dans Git, dépasse la limite de 100 Mo de GitHub ; régénérable via `analyse_menages_AID-I.do`) |
| `enhanced_metrics.json`, `equity_*.csv`, `partner_territory_matrix.csv` | Indicateurs approfondis (effet de levier, équité genre/territoire/partenaire) utilisés en section 10 du rapport |
| `aidi_synthese_resultats.json` | Synthèse chiffrée (totaux, ventilations, série trimestrielle) utilisée pour le tableau de bord |
| `AID-I_2025_Infographie achivement Y23-Y25.pdf` | Infographie officielle de clôture du projet (source USAID / Feed the Future) |
| `Rikolto_*.xlsx` | Exports bruts sources (données individuelles — **non versionnés**, voir `.gitignore`) |

Tableau de bord interactif (Artifact Claude, privé) :
`https://claude.ai/artifact/Qh9bZbjKf9YkZvHdMjBxgT`
— à partager depuis le menu « Share » de la page si des collègues doivent y accéder.

## Sources de données

Trois extractions individuelles de la base de suivi des participants Rikolto
(une ligne par personne, dédupliquée au sein de chaque fichier) :

1. `Rikolto_Project_participants_todate_08_07_without_duplicates_189 461.xlsx`
   — cumul à date, T2 2023 → T3 2024 (partiel) — 189 460 participants uniques
2. `Rikolto_Q3_0907_3009_Number_project_participants_without_duplicates_ 18 058.xlsx`
   — lot T3 2024 (juillet–septembre) — 18 057 participants uniques
3. `Rikolto_Number_participants_Q4_2024_without_duplicates_ 54 250.xlsx`
   — lot T4 2024 (octobre–décembre) — 54 249 participants uniques

Les fichiers « with duplicates » correspondants contiennent une ligne par
événement de participation (utile pour mesurer l'intensité de contact, non
utilisés pour le comptage de ménages uniques).

## Méthodologie

1. **Empilement** des 3 lots « sans doublons ».
2. **Déduplication** sur l'identifiant unique du participant (`ID`) sur
   l'ensemble empilé — un seul chevauchement détecté entre le lot cumulatif et
   le lot T3 2024, confirmant des cohortes très largement distinctes.
3. **Trimestre d'entrée** retenu = champ `Quarter` de l'enregistrement
   d'origine, ce qui permet une trajectoire trimestrielle réelle,
   indépendante du fichier source.
4. **Ventilations** calculées : genre, âge, territoire, partenaire de mise en
   œuvre, filière/culture, modalité de contact (distribution d'intrants,
   sensibilisation, formation, etc.).

Le pipeline a été exécuté avec un moteur Python (pandas/openpyxl) répliquant
fidèlement les étapes d'un traitement Stata standard. Le script
`analyse_menages_AID-I.do` fourni exécute la même séquence
(`import excel` → `append` → `duplicates drop` → `contract`/`tab`) directement
sur les fichiers sources, pour permettre de reproduire les résultats dans
Stata.

### Reproduire l'analyse

**Sous Stata** (nécessite les 3 fichiers `Rikolto_*_without_duplicates_*.xlsx`
dans le même dossier) :

```stata
do "analyse_menages_AID-I.do"
```

**Sous Python** : voir la logique équivalente — lecture des colonnes utiles via
`openpyxl` (mapping par nom de colonne, l'ordre diffère entre les fichiers),
empilement, déduplication sur `ID`, puis agrégation avec `pandas`.

## Données et confidentialité

Les exports bruts `Rikolto_*.xlsx` contiennent des **données personnelles
identifiantes** sur des ménages réels (nom, numéro de téléphone, coordonnées
GPS précises du lieu de résidence/activité) en zone rurale de RDC.

**Ces fichiers ne doivent pas être publiés sur un dépôt GitHub public.** Le
`.gitignore` fourni les exclut du suivi Git. Seule la base consolidée
`aidi_menages_base_consolidee.csv`/`.dta` (identifiant technique, âge, genre,
territoire, ville, filière — sans nom, téléphone ni géolocalisation) est
versionnable ; même dans ce cas, si le dépôt est public, évaluer le risque de
ré-identification par croisement (territoire + ville + trimestre) avant
publication, conformément aux politiques de protection des données de l'USAID
et de Rikolto.

## Limites connues

- Les données du **1er trimestre 2025** (janvier–mars) n'étaient pas
  disponibles dans les fichiers sources transmis. Le cumul arrêté à fin
  décembre 2024 (261 765) couvre néanmoins 99,9996 % du chiffre officiel à fin
  mars 2025.
- La base Rikolto ne couvre que la province du **Sud-Kivu** ; elle ne permet
  pas d'analyser la répartition par province au niveau de l'ensemble du projet
  AID-I.
- Les filières sont enregistrées en texte libre multi-valeurs : les parts par
  filière portent sur des *mentions*, pas sur des ménages mutuellement
  exclusifs.

## Sources institutionnelles

- Projet : *Great Lakes Accelerated Innovation Delivery Initiative (AID-I)*,
  Feed the Future / USAID.
- Consortium : centres CGIAR (IITA, Alliance Bioversity-CIAT, CIP, IRRI, ILRI,
  WorldVeg) ; partenaires de mise à l'échelle : Rikolto, Vétérinaires Sans
  Frontières (VSF), SARCAF.

# SAÉ 4.EMS.01 — Modélisation Statistique des Entrées Cinématographiques

![SAS](https://img.shields.io/badge/SAS-Statistical_Analysis-0076A8?style=for-the-badge&logo=sas&logoColor=white)
![Region](https://img.shields.io/badge/Région-PACA-FF6B6B?style=for-the-badge)
![Source](https://img.shields.io/badge/Source-CNC_data.gouv.fr-4CAF50?style=for-the-badge)
![Status](https://img.shields.io/badge/Status-Completed-success?style=for-the-badge)

Modélisation linéaire des entrées cinématographiques en 2022 pour la région **Provence-Alpes-Côte d'Azur (PACA)** — IUT de Roubaix site de Lille, BUT SD — 2025/2026.

**Encadrant :** *(à compléter)*  
**Binôme :** Hermann · *(NOM2)*

---

## 🎯 Problématique

> **Peut-on prédire le nombre d'entrées cinématographiques d'un établissement en 2022 à partir de ses caractéristiques (capacité, programmation, localisation) ?**

La région PACA, 2e indice de fréquentation national (2,58 entrées/habitant), constitue un terrain d'étude idéal pour la modélisation statistique des entrées cinématographiques.

---

## 📂 Structure du dépôt

```
/
├── README.md
├── data/
│   └── etablissements-cinematographiques-PACA.csv   # Données CNC filtrées PACA (nettoyées)
├── sas/
│   └── SAE_PACA_Academic.sas                        # Programme SAS complet et commenté
└── rapport/
    └── NOM1_NOM2_SAE_MODELISATION.pdf               # Rapport final PDF
```

---

## 📊 Données

- **Source :** [CNC — data.gouv.fr](https://data.culture.gouv.fr/explore/dataset/etablissements-cinematographiques/information/)
- **Périmètre :** Établissements cinématographiques actifs au 31/12/2022, région PACA
- **Observations :** ~199 établissements
- **Variable dépendante :** `entrees_2022` (nombre d'entrées cinématographiques en 2022)

### Variables utilisées

| Variable | Description | Type |
|---|---|---|
| `entrees_2022` | Nombre d'entrées en 2022 (**Y**) | Quantitative |
| `fauteuils` | Nombre de fauteuils de l'établissement | Quantitative |
| `seances` | Nombre de séances annuelles | Quantitative |
| `ecrans` | Nombre d'écrans | Quantitative |
| `semaines_d_activite` | Nombre de semaines d'activité | Quantitative |
| `population_de_la_commune` | Population de la commune | Quantitative |
| `population_unite_urbaine` | Population de l'unité urbaine | Quantitative |
| `nombre_de_films_programmes` | Nombre de films programmés | Quantitative |
| `nombre_de_films_en_semaine_1` | Films programmés en semaine 1 | Quantitative |
| `films_Art_et_Essai` | Nombre de films Art & Essai | Quantitative |
| `sit_geo` | Situation géographique | Qualitative |
| `multiplexe` | Établissement multiplexe (OUI/NON) | Qualitative |

---

## 🏗️ Architecture de l'analyse

```
Données brutes CNC
        │
        ▼
  Nettoyage & Import SAS
  (filtre PACA, renommage variables)
        │
        ▼
┌───────────────────────────────────────┐
│  PARTIE 1 — Régression linéaire simple│
│  Y = entrees_2022                     │
│  X = fauteuils                        │
│  + Changement de variable : √Y        │
└───────────────────────────────────────┘
        │
        ▼
┌───────────────────────────────────────┐
│  PARTIE 2 — Régression 2 variables    │
│  log(Y) = f(fauteuils, seances)       │
│  → nettoyage points influents         │
│  → test √Y, test semaines_activite    │
└───────────────────────────────────────┘
        │
        ▼
┌───────────────────────────────────────┐
│  PARTIE 3 — Régression multiple (11X) │
│  log(Y) = f(toutes variables)         │
│  → Sélection STEPWISE                 │
│  → Modèle final retenu                │
└───────────────────────────────────────┘
        │
        ▼
┌───────────────────────────────────────┐
│  PARTIE 4 — ANOVA                     │
│  Y ~ sit_geo                          │
│  Y ~ multiplexe                       │
└───────────────────────────────────────┘
        │
        ▼
  Prévision sur 5 cinémas hors PACA
  (régions voisines — Occitanie / AuRA)
```

---

## 📈 Résultats — Tableau comparatif des modèles

| # | Modèle | Variable(s) | Transformation | R² | Hypothèses validées |
|---|---|---|---|---|---|
| 1 | Régression simple | fauteuils | Aucune | 0,8479 | ❌ Hétéroscédasticité |
| 2 | Régression simple | fauteuils | √entrees | — | ✅ Normalité OK |
| 3 | Régression 2 var. | fauteuils + séances | log(entrees) | 0,6929 | ⚠️ Multicolinéarité VIF |
| 4 | Régression 2 var. après nettoyage | fauteuils + séances | log(entrees) | 0,7575 | ⚠️ VIF élevés |
| 5 | Régression 2 var. | fauteuils + semaines_activite | log(entrees) | 0,7867 | ✅ Toutes validées |
| 6 | Régression multiple (11 vars) | Toutes | log(entrees) | 0,8824 | ⚠️ Multicolinéarité |
| **7** | **Sélection STEPWISE** | **seances + pop_commune + semaines_activite + nb_films_sem1** | **log(entrees)** | — | **✅ Modèle retenu** |

> **Modèle final retenu :**  
> `log(entrees_2022) = β₀ + β₁·seances + β₂·population_commune + β₃·semaines_activite + β₄·nb_films_sem1`

---

## 🔍 Principales conclusions

- **Capacité physique** (fauteuils, écrans) : forte corrélation individuelle avec les entrées, mais redondance en modèle multiple (VIF > 20)
- **Intensité d'exploitation** (`semaines_activite`) : variable la plus robuste, saine en multicolinéarité (VIF ≈ 2)
- **Richesse de programmation** (`nb_films_sem1`) : impact positif significatif, non corrélée aux autres variables retenues
- **Transformation logarithmique** : indispensable pour corriger l'hétéroscédasticité
- **ANOVA** : différences significatives selon la situation géographique et le statut multiplexe

---

## 🎬 Prévision sur cinémas hors PACA

5 établissements issus des régions voisines (Occitanie, Auvergne-Rhône-Alpes) ont été sélectionnés pour tester les modèles :

| Cinéma | Région | Type | Entrées réelles 2022 | Prévision modèle | Dans l'IC ? |
|---|---|---|---|---|---|
| *(à compléter)* | | | | | |

> Les intervalles de prévision ont été calculés via l'option `CLI` de `PROC REG`.

---

## 🛠️ Programme SAS — Structure

Le fichier [`sas/SAE_PACA_Academic.sas`](sas/SAE_PACA_Academic.sas) est organisé en 4 parties :

```sas
/* PARTIE 1 — Régression linéaire simple */
/* Y = entrees_2022 = f(fauteuils) */
/* Diagnostics complets + changement de variable racine */

/* PARTIE 2 — Régression 2 variables */
/* log(Y) = f(fauteuils, seances) puis f(fauteuils, semaines_activite) */
/* Traitement multicolinéarité, nettoyage points influents */

/* PARTIE 3 — Régression multiple */
/* log(Y) = f(11 variables) → sélection STEPWISE (SLE=SLS=0.05) */

/* PARTIE 4 — ANOVA */
/* entrees_2022 ~ sit_geo et ~ multiplexe */
```

### Procédures SAS utilisées

| Procédure | Usage |
|---|---|
| `PROC IMPORT` | Import du CSV source CNC |
| `PROC UNIVARIATE` | Analyse descriptive + test normalité résidus |
| `PROC REG` | Régression linéaire (options VIF, CLB, DWprob, INFLUENCE, SPEC, CLI) |
| `PROC ANOVA` / `PROC GLM` | Analyse de variance à un facteur |
| `PROC FREQ` | Contrôle des filtres et des modalités |

---

## ▶️ Reproduire l'analyse

### Prérequis
- SAS University Edition / SAS Academic ou SAS Studio
- Fichier CSV source : [etablissements-cinematographiques.csv](https://data.culture.gouv.fr/explore/dataset/etablissements-cinematographiques/information/)

### Étapes

1. Télécharger le fichier CSV depuis data.gouv.fr
2. Adapter le chemin d'accès dans `PROC IMPORT` :
```sas
DATAFILE="C:\votre\chemin\etablissements-cinematographiques.csv"
```
3. Exécuter le programme section par section (les `dm log 'clear'` délimitent les parties)
4. Consulter les outputs SAS et les graphiques générés

---

## 📚 Contexte académique

| | |
|---|---|
| **Formation** | BUT Science des Données — IUT de Roubaix site de Lille |
| **Matière** | SAÉ 4.EMS.01 — Modélisation Statistique |
| **Compétences** | Modéliser les données · Analyser statistiquement · Valoriser une production |
| **Année** | 2025 / 2026 |

---

## 📖 Sources

- CNC — Données sur les établissements cinématographiques 2022 : [data.culture.gouv.fr](https://data.culture.gouv.fr/explore/dataset/etablissements-cinematographiques/information/)
- INSEE — Données démographiques PACA 2022
- CNC — Bilan 2022 de la fréquentation cinématographique

---

*Projet réalisé à l'IUT de Roubaix site de Lille — SAÉ 4.EMS.01 — BUT Science des Données — 2025/2026*

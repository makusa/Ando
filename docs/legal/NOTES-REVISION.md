# Politique de confidentialité — notes de révision

Accompagne le premier jet (`politique-confidentialite.md`, `privacy-policy.md`),
rédigé le 10 octobre 2026. Ces notes ne seront pas publiées.

Je ne suis pas juriste : ce qui suit prépare la relecture, il ne la remplace pas.

## Faits vérifiés dans le code (10 octobre 2026)

| Affirmation de la politique | Vérification |
|---|---|
| Liste d'attente : courriel, langue, pays, version du consentement, date | `_landing/schema.sql`, `_landing/src/index.js` (insertion) |
| Adresse IP non conservée | Aucune colonne ni journal d'IP ; le pays vient de l'en-tête `CF-IPCountry` |
| Aucun témoin, aucune mesure d'audience sur le site | Aucun `set-cookie` dans la réponse du site ; aucun script d'analytique ; aucun stockage navigateur |
| Police hébergée sur le site (plus de Google Fonts) | `_landing/public/fonts/` ; aucune référence à `googleapis`/`gstatic` dans les pages générées ; rendu identique au pixel près (comparaison de captures) |
| Aucun SDK tiers ni analytique dans l'app | Aucune dépendance de paquets ; aucun appel réseau autre que ceux listés |
| Taux de change : seule la devise de référence est envoyée | `ExchangeRateManager.swift` (`/v4/latest/{base}`) |
| Logos via notre serveur, jamais directement chez Logo.dev ; monogramme en secours | `BankLogoStore` et `BankLogoView` (`BankPicker.swift`) ; route `/api/logo/` de `_landing/src/index.js` : requête neuve sans en-tête du visiteur, domaines de l'annuaire seulement ; journaux d'invocation désactivés (`wrangler.jsonc`) |
| Reçus, catégories, récurrences calculés sur l'appareil | Vision (OCR) ; `SmartCategorizer`, `RecurrenceDetector` locaux |
| iCloud facultatif, réservé aux paliers payants, base privée | `FinTrackApp.swift` (`.private(...)`), contrôle `hasPaidTier` |
| Pas de connexion bancaire dans la bêta | `bankSyncAvailable = false` |
| Supprimer l'app efface ses données ; la politique ne promet pas davantage | **Correction du 10 octobre** : il existe un bouton « Réinitialiser toutes les données » (`SettingsView.resetAll`), mais il n'efface que comptes, transactions et catégories — voir « Correctifs avant lancement » |

## Informations fournies par Régis (10 octobre 2026)

| Élément | Valeur |
|---|---|
| Entreprise | BMSK, 5025, avenue Westmore, Montréal (Québec) H4V 1Z4 |
| Responsable de la protection des renseignements personnels | Régis Bile Masuke, gérant |
| Courriel | `confidentialite@bmsk.ca` (**à créer avant publication**) |
| Conservation de la liste d'attente | 12 mois après la fin de la bêta |
| Âge minimum | 18 ans |

## Publication (11 octobre 2026)

Publiée sur https://fintrack.bmsk.ca/confidentialite/ et
https://fintrack.bmsk.ca/en/privacy/, générées par `_landing/build.py` à partir
des fichiers Markdown de ce dossier (source unique ; les lignes « > » ne sont
pas publiées). Le build refuse de publier un texte contenant encore un
marqueur [À COMPLÉTER], [À VALIDER] ou [À VÉRIFIER]. Lien « Confidentialité »
du pied de page réparé dans les deux langues. Adresse `confidentialite@bmsk.ca`
active.

## Reste à faire

1. **Évaluation des communications hors Québec** (Loi 25), à documenter. En
   attendant, la politique publiée ne prétend pas qu'elle a été faite.
2. **Vérifier dans App Store Connect** ce qui est visible des testeurs invités
   par lien public, et préciser la section TestFlight si nécessaire.
3. **Relecture juridique**, recommandée.

## Points juridiques à faire valider

- **Évaluation des communications hors Québec** (Loi 25) : la loi exige
  d'évaluer, avant de confier des renseignements à un fournisseur situé hors du
  Québec, s'ils bénéficieront d'une protection adéquate, et de documenter
  cette évaluation. Fournisseurs concernés : Cloudflare, Apple,
  ExchangeRate-API.
- **Registre des incidents de confidentialité** : à tenir, même vide.
- **Délai de réponse de 30 jours** et **portabilité** : formulation à confirmer.
- **Courriel d'invitation et LCAP** : vérifier s'il est exempté (message
  demandé par la personne) ou s'il doit comporter un mécanisme de
  désabonnement.

## Améliorations techniques

| Amélioration | État |
|---|---|
| Police hébergée sur le site au lieu de Google Fonts | **Fait** le 10 octobre 2026 (à mettre en ligne) |
| Logos par Logo.dev via notre serveur (Clearbit a fermé en décembre 2025), monogramme en secours | **Fait** le 10 octobre 2026. Plan gratuit : mention « Logos fournis par Logo.dev » obligatoire (Réglages ▸ À propos). Aucune licence n'est accordée sur les logos, chez Logo.dev comme chez Plaid : usage d'identification, à nos risques |
| Mécanisme de retrait de la liste d'attente : le champ `desabonne_le` existe dans la base, mais rien ne le remplit | À faire : lien de retrait dans le courriel d'invitation |

## Correctifs avant lancement

- ~~« Réinitialiser toutes les données » est incomplet~~ **Corrigé le 11 octobre
  2026** (`FinTrack/Utilities/DataReset.swift`) : efface les 16 types de données,
  les reçus, le cache des logos, les préférences contenant des données
  personnelles, les données du widget, les connexions bancaires et les rappels.
  Prouvé par l'auto-test `-FTDemoMode -FTResetSelfTest` (tous les types présents
  avant, aucun après). La politique mentionne désormais ce bouton.

## Fiche App Store

Utiliser https://fintrack.bmsk.ca/confidentialite/ comme URL de politique de
confidentialité (et la version anglaise pour la localisation anglaise).

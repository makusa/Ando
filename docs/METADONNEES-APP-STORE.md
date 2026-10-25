# Métadonnées App Store — Ando 1.0

Textes prêts à coller dans App Store Connect, en français et en anglais.
Longueurs vérifiées par `scripts/verif-metadonnees.py`.

> Rédigés à partir du **code**, pas de la page de prix : voir la section
> « Écarts constatés » à la fin, qui doit être tranchée avant publication.

Trois règles ont guidé la rédaction :

- **Aucune comparaison.** La *Loi sur la concurrence* permet une action privée
  depuis juin 2025, et ce texte est permanent, lu par un public large. Rien du
  genre « les applications américaines se trompent » : on décrit ce qu'Ando
  calcule, pas ce que les autres rateraient.
- **Jamais le mot « bêta ».** L'article 2.2 d'Apple refuse une app présentée
  comme un essai ou une version de démonstration. Le site peut parler de bêta,
  la fiche non.
- **Pas d'affiliation sous-entendue** avec l'ARC ou une institution
  financière, et aucun conseil financier.

---

## Nom et sous-titre

**Nom** (30 car.) : `Ando`
→ disponibilité à vérifier dans App Store Connect au moment de créer la fiche.

**Sous-titre** (30 car.) — le nom ne dit rien de l'app, le sous-titre doit tout
porter. Deux options :

| | Français | Anglais |
|---|---|---|
| **Recommandé** | `Budget, CELI et hypothèque` | `Budget, TFSA and mortgage` |
| Variante | `Vos finances, à la canadienne` | `Your money, the Canadian way` |

La première est préférable : elle contient trois termes qu'on cherche
réellement. La seconde est plus jolie et ne se cherche pas.

---

## Mots-clés (100 car., séparés par des virgules, **sans espace après**)

Apple indexe déjà le nom et le sous-titre : les mots qui y figurent sont
retirés d'ici pour ne pas gaspiller de place. Aucune marque de concurrent —
c'est un motif de refus et un risque de marque.

**Français**
```
celiapp,reer,reee,cotisation,arc,amortissement,marge,crédit,dépenses,épargne,devise,canada
```

**Anglais**
```
fhsa,rrsp,resp,contribution,room,cra,amortization,line,credit,spending,savings,currency,canada
```

---

## Texte promotionnel (170 car.)

Le seul champ modifiable **sans nouvelle version**. À garder pour les annonces.

**Français**
```
Vos droits de cotisation CELI et CELIAPP, votre hypothèque à capitalisation semestrielle, vos marges au taux journalier. Sur votre appareil, en français et en anglais.
```

**Anglais**
```
Your TFSA and FHSA contribution room, your mortgage with semi-annual compounding, your credit lines at the daily rate. On your device, in English and in French.
```

---

## Description (4000 car.)

### Français

```
Ando est une application de finances personnelles conçue pour les règles canadiennes : droits de cotisation CELI, CELIAPP et REER, hypothèque à capitalisation semestrielle, marges de crédit au taux journalier.

VOS DROITS DE COTISATION, SANS SURPRISE
Vous saisissez une seule fois le droit indiqué dans Mon dossier de l'ARC, avec son année de référence. Ando projette ensuite chaque cotisation et chaque retrait, en respectant la règle qui piège tout le monde : un retrait du CELI ne rétablit vos droits qu'au 1er janvier suivant. Le droit est suivi par personne et partagé entre tous vos comptes du même type, comme le veut la règle — et non compte par compte.

L'HYPOTHÈQUE, AVEC LA CAPITALISATION SEMESTRIELLE
Au Canada, l'intérêt hypothécaire se compose deux fois par année, pas douze. Ando utilise le taux périodique équivalent, sépare capital et intérêts, tient compte des versements anticipés et compte les versements qui restent. Les prêts auto et personnels gardent la capitalisation mensuelle, parce que c'est ainsi qu'ils fonctionnent.

LES MARGES DE CRÉDIT, AU TAUX JOURNALIER
Une marge canadienne accumule l'intérêt chaque jour sur le solde utilisé. Ando affiche le taux journalier au dix-millième de pourcent, estime le coût du mois, suit votre taux d'utilisation et gère les trois formes de paiement minimum au lieu d'en supposer une seule.

LE QUOTIDIEN, AU COMPLET
• Comptes multidevises, avec solde global converti
• Transactions groupées par jour, recherchables, avec statut
• Transactions récurrentes, six fréquences
• Budgets par catégorie et par période
• Projets d'épargne avec date d'atteinte projetée
• Cartes de crédit : date de relevé, paiement minimum, taux
• Projection de solde, répartition des dépenses, flux mensuel estimé
• Tableau de bord réorganisable
• Widgets, quatre formats, et écran verrouillé
• Export CSV de vos transactions

VOS DONNÉES RESTENT CHEZ VOUS
Aucune inscription, aucun compte à créer, aucun serveur à nous. Les données vivent dans l'application, protégées par le chiffrement du système. La synchronisation entre vos appareils passe par votre propre compte iCloud privé. Le verrouillage par Face ID ou par code est facultatif, et se désactive sans perdre vos données.

Ando ne se connecte à aucune banque. Rien n'est importé à votre insu.

EN FRANÇAIS COMME EN ANGLAIS
Interface complète en français, en anglais, en espagnol et en portugais.

CE QUI EST GRATUIT, CE QUI NE L'EST PAS
Ando s'utilise gratuitement, sans limite de temps et sans publicité. Le nombre de budgets, de prêts, de marges, de projets d'épargne, de comptes enregistrés, de récurrences, de catégories personnalisées et de devises suivies est plafonné.

Pro lève tous les plafonds et ajoute la détection automatique des récurrences, les widgets, la synchronisation entre vos appareils et la numérisation de reçus. C'est un achat unique, pas un abonnement.

Conçu à Montréal.

Ando n'est pas affilié à l'Agence du revenu du Canada ni à aucune institution financière. Les droits de cotisation affichés sont une projection calculée à partir des montants que vous saisissez : votre relevé officiel demeure celui de Mon dossier de l'ARC. Ando ne fournit pas de conseils financiers, fiscaux ou de placement.
```

### Anglais

```
Ando is a personal finance app built for Canadian rules: TFSA, FHSA and RRSP contribution room, mortgages with semi-annual compounding, credit lines at the daily rate.

YOUR CONTRIBUTION ROOM, WITHOUT SURPRISES
You enter the room shown in CRA My Account once, with its reference year. Ando then projects every contribution and every withdrawal, honouring the rule that catches everyone out: a TFSA withdrawal only restores your room on the following January 1. Room is tracked per person and shared across all your accounts of the same type, as the rule requires — not account by account.

MORTGAGES, WITH SEMI-ANNUAL COMPOUNDING
In Canada, mortgage interest compounds twice a year, not twelve times. Ando uses the equivalent periodic rate, separates principal from interest, accounts for prepayments and counts the payments left. Car and personal loans keep monthly compounding, because that is how they work.

CREDIT LINES, AT THE DAILY RATE
A Canadian line of credit accrues interest every day on the drawn balance. Ando shows the daily rate to the ten-thousandth of a percent, estimates the month's cost, tracks your utilization and handles all three minimum payment formulas instead of assuming one.

EVERYDAY, IN FULL
• Multi-currency accounts, with a converted global balance
• Transactions grouped by day, searchable, with status
• Recurring transactions, six frequencies
• Budgets by category and by period
• Savings projects with a projected completion date
• Credit cards: statement date, minimum payment, rate
• Balance projection, spending breakdown, estimated monthly flow
• Reorderable dashboard
• Widgets in four sizes, and on the Lock Screen
• CSV export of your transactions

YOUR DATA STAYS WITH YOU
No signup, no account to create, no servers of ours. Your data lives in the app, protected by the system's encryption. Syncing between your devices goes through your own private iCloud account. Locking with Face ID or a passcode is optional, and can be turned off without losing your data.

Ando does not connect to any bank. Nothing is imported without you.

IN ENGLISH AND IN FRENCH
Full interface in English, French, Spanish and Portuguese.

WHAT IS FREE, AND WHAT IS NOT
Ando is free to use, with no time limit and no ads. The number of budgets, loans, credit lines, savings projects, registered accounts, recurring rules, custom categories and tracked currencies is capped.

Pro lifts every cap and adds automatic detection of recurring transactions, widgets, syncing between your devices and receipt scanning. It is a one-time purchase, not a subscription.

Made in Montréal.

Ando is not affiliated with the Canada Revenue Agency or any financial institution. The contribution room shown is a projection calculated from the amounts you enter: your official statement remains the one in CRA My Account. Ando does not provide financial, tax or investment advice.
```

---

## Nouveautés de cette version

**Français** : `Première version d'Ando.`
**Anglais** : `The first release of Ando.`

---

## Notes pour le relecteur d'Apple

À coller dans *App Review Information ▸ Notes*. Elles existent pour éviter le
motif de refus le plus bête : un relecteur qui ouvre une app vide et ne trouve
rien à essayer.

```
Aucun compte, aucune connexion, aucun identifiant ne sont nécessaires : Ando
fonctionne entièrement sur l'appareil et ne communique avec aucun serveur qui
nous appartienne. Il n'y a donc pas d'identifiants de test à fournir.

L'app démarre vide, par conception. Pour voir les fonctions principales :

1. Comptes ▸ + : créer un compte (par exemple Chèques, 2 000 $ CA).
2. Transactions ▸ + : ajouter quelques entrées et sorties.
3. Gérer ▸ Prêts ▸ + : créer une hypothèque (par exemple 385 000 $ CA à
   4,79 % sur 25 ans). L'amortissement affiché utilise la capitalisation
   semestrielle exigée au Canada.
4. Réglages ▸ Comptes enregistrés : saisir un droit de cotisation CELI et son
   année de référence pour voir la projection.

Achats intégrés : « Pro » est un achat unique qui lève les plafonds du palier
gratuit. Le bouton « Restaurer les achats » est présent sur les deux écrans
d'achat. Les conditions d'utilisation et la politique de confidentialité sont
liées depuis ces mêmes écrans et depuis les Réglages.

Le verrouillage par Face ID ou code est facultatif et peut être refusé au
premier lancement comme désactivé ensuite dans Réglages ▸ Sécurité.

La synchronisation entre appareils passe par CloudKit, dans le conteneur
iCloud privé de l'utilisateur.
```

---

## Les paliers, tels qu'ils sont réellement

Relevé le 25 octobre 2026 en lisant `EntitlementManager.swift`, puis **corrigé
dans le code et sur le site le jour même** : la page de prix annonçait trois
choses que le code ne faisait pas.

### Plafonds du palier gratuit (`AndoLimit`)

| Élément | Plafond gratuit |
|---|---|
| Budgets actifs | 3 |
| Prêts actifs | 2 |
| Marges de crédit actives | 1 |
| Projets d'épargne actifs | 2 |
| Comptes enregistrés (CELI/CELIAPP/REER) | 2 |
| Récurrences (actives + en pause) | 5 |
| Catégories personnalisées | 3 |
| Devises suivies | 2, dollar canadien compris |

Comptes et transactions : **sans limite**.

### Ce qui demande Pro

- Tous les plafonds ci-dessus, levés
- Détection automatique des récurrences
- Synchronisation entre vos appareils
- Widgets et écran verrouillé *(barrière posée le 25 octobre)*
- Numérisation de reçus *(barrière posée le 25 octobre)*

### Écarts corrigés

| La page annonçait | Réalité du code | Décision |
|---|---|---|
| Plafonds passés sous silence | 8 plafonds | La page les nomme |
| Droits CELI/CELIAPP/REER réservés à Pro | 2 comptes gratuits | La page le dit |
| Widgets réservés à Pro | aucune barrière | Barrière posée |
| Numérisation réservée à Pro | aucune barrière | Barrière posée |
| Synchronisation réservée à Pro | **déjà** réservée à Pro | Rien à changer |

> [!warning] Une erreur de relevé, corrigée le jour même
> La synchronisation a d'abord été rapportée comme non protégée. Elle l'est :
> `SettingsView.cloudSyncRow` n'affiche l'interrupteur que si
> `entitlements.hasPaidTier`, et `refreshEntitlements()` remet
> `ando.cloudSyncEnabled` à faux dès que le droit disparaît. La recherche
> initiale filtrait les lignes contenant `hasPaidTier` **et** « cloud » : la
> ligne de garde ne contient que le premier des deux.

### Comment les widgets connaissent l'achat

L'extension tourne dans un autre processus, sans accès à StoreKit. L'état
d'achat lui parvient par le champ `isPro` de la charge utile partagée,
recopié à chaque écriture. Sans Pro, les widgets affichent un verrou et
**aucun montant** — un widget qui barrerait la valeur nette d'un cadenas
livrerait quand même le chiffre.

`refreshEntitlements()` étant asynchrone, l'écriture faite au lancement part
avec `hasPaidTier` encore à faux. `RootView` réécrit donc la charge utile sur
`onChange(of: entitlements.hasPaidTier)`. Mesuré au simulateur : `isPro` passe
à vrai une quinzaine de secondes après le lancement, le temps que StoreKit
réponde — quasi immédiat sur un appareil réel.

# Ando — liste avant soumission à l'App Store

Audit du 17 octobre 2026, sur le commit `5eea6ce`. Chaque point a été vérifié
dans le code ; les déductions non démontrées sont signalées comme telles.

Classement par **ce que ça coûte si on ne le corrige pas**, pas par difficulté.

## Bloquants — à corriger avant de soumettre

### B1 · Les totaux multidevises sont faux quand un taux manque

`ExchangeRateManager.convert()` retourne le montant **inchangé** quand le taux
est introuvable : 1 000 $ US sont additionnés comme 1 000 $ CA, soit environ
40 % d'erreur sur le patrimoine net.

- **Quand** : premier lancement avant chargement, hors ligne au-delà du cache
  de 4 h, panne du fournisseur, devise absente de la table.
- **Pourquoi c'est bloquant** : le tableau de bord affiche un total faux **sans
  rien signaler**, et affiche même « mis à jour il y a… » dès qu'une date
  existe — ce qui rassure à tort. Seule la vignette des taux dit
  « indisponible ».
- **Où** : `Utilities/ExchangeRateManager.swift` (lignes 103-121) ;
  totaux dans `Views/Dashboard/NetWorthWidget.swift` et `DashboardView.swift`.
- **Décision à prendre** : afficher le total avec une mention « approximatif »
  (recommandé), masquer le total, ou n'additionner que les comptes
  convertibles en signalant les autres.

### B2 · Flinks contient des valeurs de remplacement

`FlinksManager.swift` contient encore `VOTRE_PROXY_URL_ICI` et
`VOTRE_API_KEY_ICI`. Sans effet tant que `activeBankSyncProvider = .plaid` et
`bankSyncAvailable = false`, mais **à ne jamais livrer activé en l'état** : la
connexion échouerait pour tous les utilisateurs.

### B3 · Schéma CloudKit à déployer en Production

L'app est en environnement **Development**. Les builds App Store utilisent
**Production** : sans déploiement du schéma, la synchronisation iCloud —
fonction payante — échouerait pour tous les acheteurs.
Action : CloudKit Console → *Deploy Schema Changes*.

### B4 · Notifications distantes réclamées sans être utilisées

`Info.plist` déclare `UIBackgroundModes: remote-notification` et les
entitlements déclarent `aps-environment: development`. Or aucune occurrence
de `registerForRemoteNotifications` n'existe dans `Ando/` : seules des
notifications **locales** sont utilisées (`NotificationManager.swift`).
Déclarer un mode d'arrière-plan inutilisé est un motif de rejet (2.5.4), et
`development` est de toute façon la mauvaise valeur pour une build App
Store. Retirer les deux.

### B5 · Reste de l'ancien nom dans `Info.plist`

`CFBundleURLName = ca.regis.ando.plaid`. Le rebranding d'août l'a manqué.

### B6 · Le paysage est déclaré, et non vérifié

`project.yml` annonce `Portrait + LandscapeLeft + LandscapeRight`. Les
relecteurs font tourner l'appareil. **Je n'ai pas vérifié que l'interface
tient en paysage.** À tester, ou à restreindre au portrait.

*(Correction : la première version de ce document affirmait « portrait et
portrait inversé ». C'était faux.)*

### B7 · Schémas d'URL Plaid actifs alors que la synchro est désactivée

`ando`, `plaidlink` et `LSApplicationQueriesSchemes` sont déclarés
pendant que `bankSyncAvailable = false`.

### B8 · `BRANCHES.md` documente de faux identifiants de produits

`ca.regis.ando.pro` à 19,99 $ et `ca.regis.ando.plaid_monthly` à
3,99 $/mois — les quatre valeurs sont fausses. Les vraies :
`ca.bmsk.ando.pro` à 24,99 $ et `ca.bmsk.ando.max` à
6,49 $/mois. Un identifiant créé de travers dans App Store Connect est
**définitif**.

### B9 · Conformité à l'exportation non déclarée

`ITSAppUsesNonExemptEncryption` absent d'`Info.plist` : App Store Connect
posera la question du chiffrement à chaque téléversement.

## Importants — à corriger si le temps le permet

### I1 · Aucun lien vers la politique de confidentialité dans l'app

L'URL figurera dans la fiche App Store (exigence satisfaite), mais les Réglages
n'y renvoient pas. Pour une app financière, et au regard de la Loi 25, un lien
dans « À propos » est attendu. Correction simple.

### I2 · Solde de relevé des cartes de crédit non calculé

`TODO` dans `Models/CreditCardProfile.swift` (ligne 165) : le montant dû à la
date de clôture n'est pas calculé. À vérifier : la fiche d'une carte
affiche-t-elle un champ vide ou trompeur ?

### I3 · Commentaire faux sur le calcul REER

`RegisteredType.reer` indique « room calc not implemented here yet » alors que
le calcul existe et est désormais couvert par 19 tests. Un futur lecteur —
humain ou IA — en tirerait une conclusion fausse.

## Mineurs — après le lancement

### M1 · Éditeur de récurrence trop dense

Corps très chargé : c'est ce qui avait provoqué le gel corrigé par `LazyView`.
Le découper éviterait une récidive.

### M2 · Moteurs sans tests

Couverts : droits, amortissement, rapprochement (43 tests). **Non couverts** :
intérêt quotidien des marges de crédit (règle R6), catégorisation, détection
de récurrences — tous liés à SwiftData.

### M3 · Statut selon l'instant plutôt que le jour

`TransactionStatus.defaultForManual` compare des instants.
**Aucun cas de défaillance n'a pu être reproduit** : le sélecteur conserve
l'heure d'ouverture, les imports arrivent à minuit, les récurrences ne se
déclenchent qu'une fois l'heure passée. Fragilité théorique, pas un bogue.

## Vérifié et conforme

| Point | État |
|---|---|
| Bouton « Restaurer les achats » (exigé par Apple) | Présent dans les deux paywalls |
| Chaînes d'usage Face ID et caméra | Présentes |
| Photothèque | `PhotosPicker` : aucune chaîne requise |
| Mode développeur et mode démo | `#if DEBUG`, absents du Release |
| Appareils | iPhone seulement — évite les rejets liés à l'iPad |
| Orientations | ⚠️ voir B6 — le paysage est déclaré |
| Liens externes dans l'app | Trois, tous valides |
| Suppression de compte utilisateur | Sans objet : l'app n'a pas de comptes |
| Réinitialisation des données | Efface tout, vérifié par auto-test |
| Reçus orphelins | Corrigé le 17 octobre, vérifié dans les deux sens |
| Modèles absents de la réinitialisation | Aucun |
| Relations non optionnelles (CloudKit) | Aucune |
| Recalcul des soldes | Les 31 points de mutation recalculent |
| Forçages et divisions par zéro | Les cas suspects sont protégés |
| États vides au premier lancement | Présents sur les écrans principaux |
| Build | Debug et Release : 0 erreur, 0 avertissement ; 43 tests, 0 échec |

## Hors code — rappel

- Produits à créer dans App Store Connect (`…epargne`, `…placement`) et accord
  « Paid Applications » à signer.
- Captures d'écran, métadonnées et étiquette de confidentialité.
- Nom « Ando » : le `:` reste à valider dans App Store Connect, et la
  proximité avec **FINTRAC** n'a jamais été tranchée.
- Relecture juridique de la politique de confidentialité et des EFVP.

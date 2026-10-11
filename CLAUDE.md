# Fin:Track — guide de référence pour le développement

Application iOS de finances personnelles pour le Canada (SwiftUI, SwiftData, iOS 17+),
développée seul par Régis (entreprise bmsk). Positionnement : la précision canadienne
— droits CELI / CELIAPP / REER ancrés sur l'ARC, capitalisation hypothécaire
semestrielle, intérêt quotidien des marges de crédit.

Ce fichier est la carte du projet. Il ne remplace pas le code.

## Règle d'or : le code et Git font foi

1. **Le code** dit ce qui est vrai maintenant. Vérifier dans le code avant d'affirmer
   quoi que ce soit sur le comportement de l'app.
2. **L'historique Git** est le journal des modifications. Les messages de commit
   expliquent la cause, la correction et la vérification. `git log`, `git show <hash>`
   et `git log -S "<symbole>"` répondent à « pourquoi est-ce comme ça ? ».
3. **Ce fichier** donne la carte et les décisions. S'il contredit le code, c'est le
   code qui a raison — et ce fichier doit être corrigé.
4. **Les notes de mémoire et les résumés de conversations** sont des indices, jamais
   des preuves. Ils vieillissent (exemple réel : des notes affirmaient que Plaid avait
   été retiré, alors qu'il est le fournisseur actif).

En cas de doute, le dire explicitement plutôt que deviner.

## Règles de travail (obligatoires)

- **Ne jamais committer sans demande explicite de Régis.** Ne jamais pousser sans
  demande explicite non plus.
- **Avant tout commit** : analyse statique (grep des usages, références mortes,
  imports manquants), puis **`scripts/verify.sh`** (traductions, App Group, builds
  **Debug et Release** à **0 erreur / 0 avertissement**). Un avertissement
  préexistant se corrige aussi. Le garde-fou de commit refuse tout commit touchant
  l'app sans vérification à jour ; ne jamais le contourner (`--no-verify`) sans
  l'accord explicite de Régis. Mode d'emploi : `docs/OUTILS.md`.
- **Staging ciblé** : uniquement les fichiers concernés. Jamais `.DS_Store`,
  `UserInterfaceState.xcuserstate`, `xcuserdata/…/xcdebugger/`, ni les schemes
  partagés (`xcshareddata/xcschemes/*.xcscheme`). `project.pbxproj` et `project.yml`
  seulement si XcodeGen a tourné ou si la configuration a changé.
- **Un commit = un sujet.** Séparer fonctionnalité, correctif et nettoyage.
- **Messages de commit en français** : sujet court, puis cause → correction →
  vérification, et une dernière ligne `Build : …`.
- **Localisation** : aucun texte visible codé en dur. Voir la section Localisation.
  Exception : les écrans `#if DEBUG` (DeveloperView, section développeur).
- **Tests sur appareil** : Régis teste lui-même (Xcode : Stop puis Run). Lui dire
  précisément quoi vérifier.
- **Branches** : le travail se fait sur `develop`. Stratégie complète dans
  `BRANCHES.md`.

## Commandes

```bash
cd /Users/regis/Documents/GitHub/FinTrack

# Vérification avant commit (à préférer aux commandes manuelles ci-dessous)
scripts/verify.sh            # traductions + App Group + Debug + Release, ~2 min
scripts/verify.sh --quick    # idem en Debug seulement, n'autorise pas le commit
python3 scripts/check-l10n.py   # traductions seules, ~1 s

# Build Debug (simulateur iPhone 17 Pro Max)
xcodebuild -project FinTrack.xcodeproj -scheme FinTrack \
  -destination 'platform=iOS Simulator,id=42645610-A5FC-408B-A0A6-1AF9CA31170D' \
  -configuration Debug build

# Build Release (configuration des archives TestFlight / App Store)
xcodebuild -project FinTrack.xcodeproj -scheme FinTrack \
  -destination 'generic/platform=iOS Simulator' -configuration Release build

# Compter erreurs et avertissements d'un log de build
grep -c ' error:' build.log
grep ' warning:' build.log | grep -vc appintentsmetadataprocessor
```

**XcodeGen** : le projet Xcode est **généré** depuis `project.yml`. Après tout ajout ou
retrait de fichier, lancer `xcodegen generate` (inutile pour une simple modification
de fichier existant). Toujours vérifier ensuite que l'App Group a survécu :

```bash
grep -c 'group.ca.bmsk' FinTrack/FinTrack.entitlements              # attendu : 1
grep -c 'group.ca.bmsk' FinTrackWidget/FinTrackWidget.entitlements  # attendu : 1
```

Les clés Info.plist se déclarent dans `project.yml` (`INFOPLIST_KEY_*`), pas dans un
fichier Info.plist de l'app.

**Landing** (`_landing/`) : `python3 build.py` régénère `public/index.html` (FR) et
`public/en/index.html` (EN). La mise en ligne est **manuelle** : `npx wrangler deploy`
depuis `_landing/` (Worker Cloudflare `fintrack-landing`, domaine `fintrack.bmsk.ca`).
Un `git push` ne déploie rien.

**Annuaire des banques** : après tout ajout ou retrait d'une institution dans
`BankDirectory.swift`, lancer `python3 scripts/gen-logo-allowlist.py` puis
redéployer le Worker ; sinon son logo n'est jamais servi (`verify.sh` le signale).

**Captures d'écran** : cible `FinTrackUITests` (`ScreenshotTests.swift`), qui lance
l'app avec `-FTDemoMode`. Les captures produites (`_captures/`) sont exclues du dépôt.

## Identifiants

| Élément | Valeur |
|---|---|
| Bundle ID app / widget | `ca.bmsk.fintrack` / `ca.bmsk.fintrack.widget` |
| App Group | `group.ca.bmsk.fintrack` |
| Conteneur iCloud | `iCloud.ca.bmsk.fintrack` |
| Produit Pro (achat unique) | `ca.bmsk.fintrack.epargne` |
| Produit Max (abonnement) | `ca.bmsk.fintrack.placement` |
| Team | `38N594NGP9` |
| Nom affiché | `Fin:Track` (identité technique : `FinTrack` / `fintrack`) |

Les identifiants de produits gardent les anciens noms `epargne` / `placement` :
un identifiant StoreKit est immuable. Seuls les noms affichés sont Pro et Max.

## Carte du code

| Dossier | Rôle |
|---|---|
| `FinTrack/FinTrackApp.swift` | Démarrage : schéma, choix du conteneur (CloudKit / local / démo), tâches de lancement |
| `FinTrack/Models/` | Modèles SwiftData, moteur de droits enregistrés (`RegisteredRoom.swift`), données du widget |
| `FinTrack/Views/` | Écrans. `RootView` : onglets 0 Tableau de bord, 1 Comptes, 2 Transactions, 3 Gérer (`ManageHubView`), 4 Réglages |
| `FinTrack/Views/Dashboard/` | Tableau de bord, widgets internes, configuration réorganisable |
| `FinTrack/Entitlements/` | Paliers et achats : `EntitlementManager`, paywall `ProGateView`, `SubscriptionView`, `DeveloperView` (DEBUG) |
| `FinTrack/BankSync/` | Choix du fournisseur bancaire et interrupteurs (`BankSyncProvider.swift`), `TransactionReconciler` |
| `FinTrack/Plaid/` | Fournisseur **actif** : Hosted Link via `ASWebAuthenticationSession` (aucun SDK tiers), sync, mapping des comptes |
| `FinTrack/Flinks/` | Fournisseur alternatif, prêt côté code (mapping inclus) ; sans compte ni proxy configurés |
| `FinTrack/AI/` | Intelligence sur l'appareil : `SmartCategorizer`, scan de reçus (`ReceiptScanner`, `ReceiptStore`, `ScanReceiptView`), `RecurrenceDetector` |
| `FinTrack/Categorization/` | Second moteur de catégorisation, utilisé par l'import de relevés (`TransactionCategorizer`) |
| `FinTrack/FileImport/` | Import OFX / QFX, CSV, PDF |
| `FinTrack/Security/` | Verrou Face ID / NIP, Keychain, réinitialisation |
| `FinTrack/Localization/` | `LanguageManager` et `LocalizedStrings` (environ 1 100 clés, 4 langues) |
| `FinTrack/Utilities/` | Gestionnaires (récurrences, prêts, marges, taux de change, notifications), formatage, `DemoData` |
| `FinTrackWidget/` | Widgets : solde (petit, moyen, grand), droits enregistrés, écran verrouillé |
| `FinTrackUITests/` | Harnais de captures d'écran |
| `_landing/` | Site public : gabarit, textes anglais, Worker d'inscription à la bêta (Cloudflare D1) |
| `plaid-server/` | Ancien serveur Plaid (NAS Docker), remplacé par un proxy Cloudflare Workers |
| `scripts/` | Outils de qualité : `verify.sh`, `check-l10n.py`, garde-fou de commit (`git-hooks/`) |
| `docs/` | Documentation, dont `OUTILS.md` (mode d'emploi des outils de qualité) |
| `marketing/` | Stratégie marketing : `STRATEGIE.md` (source de vérité), `HYPOTHESES.md` (hypothèses et expériences), `GUIDE-BETA.md` (plan de la bêta) |

Deux moteurs de catégorisation coexistent : `AI/SmartCategorizer` (saisie manuelle,
synchro Plaid, détection de récurrences) et `Categorization/` (import de relevés).
Ne pas les confondre.

## Interrupteurs et configuration

Tous dans `FinTrack/BankSync/BankSyncProvider.swift`, sauf mention contraire.

- `activeBankSyncProvider` (`.plaid` / `.flinks`) : fournisseur de synchro bancaire.
  Changer cette ligne suffit ; la purge de sécurité passe par
  `disconnectAllBankProviders()`, qui nettoie les deux fournisseurs.
- `bankSyncAvailable` (actuellement `false`) : coupe la connexion bancaire **et**
  l'abonnement Max (ligne des Réglages, offre Max, colonne Max du tableau
  comparatif, textes « Pro ou Max » → « Pro »). Passer à `true` quand un fournisseur
  est actif en production.
- **Simulation de palier (DEBUG)** : clé UserDefaults `fintrack.dev.tierOverride`
  (`free` / `epargne` / `placement`), réglée depuis le DeveloperView. Elle survit aux
  redémarrages et court-circuite StoreKit. Pour tester un vrai achat, l'effacer.
- **Mode démo** : argument de lancement `-FTDemoMode` (harnais de captures) ;
  magasin en mémoire et données d'un ménage québécois fictif. `DemoMode.isActive`
  vaut toujours `false` en Release.
- **Test des achats** : `FinTrack.storekit`, référencé dans le scheme via `project.yml`.

## Paliers et contrôle d'accès

- **Courant** (gratuit, « Free » dans l'app), **Pro** (achat unique), **Max**
  (abonnement mensuel, = Pro + synchro bancaire). Max active aussi Pro.
- `EntitlementManager.hasPaidTier` = Pro **ou** Max. `hasPlacement` = Max.
- **La seule fonctionnalité réservée à Max est la synchro bancaire** (`GatedFeature.bankSync`).
  Tout le reste se contrôle par `hasPaidTier`.
- Deux façons de contrôler l'accès : le paywall (`ProGated(feature:)` / `ProGateView`)
  ou un test direct `entitlements.hasPaidTier` dans la vue (ex. : le scan de reçus est
  masqué en gratuit, dans les menus « + » du tableau de bord et de Transactions).
- Limites du gratuit : `FinTrackLimit` dans `EntitlementManager.swift`.
- **Prix** : jamais codés en dur. Toujours `product.displayPrice` (StoreKit), qui suit
  App Store Connect.
- En gratuit, `refreshEntitlements()` désactive la synchro iCloud (c'est voulu).
- Les noms de paliers dans les textes passent par les marqueurs `{pro}` et `{max}`.

## Données et persistance

- Schéma **simple** (`Schema([...])`, non versionné) déclaré dans `FinTrackApp.swift`.
  `FinTrackSchema.swift` définit un schéma versionné et un plan de migration qui ne
  sont **volontairement pas branchés** (la raison est en commentaire dans
  `FinTrackApp.swift`). Les évolutions de modèle doivent rester additives.
- **Toute nouvelle classe `@Model` doit être ajoutée à ce schéma.**
- CloudKit (base privée `iCloud.ca.bmsk.fintrack`) n'est utilisé que si l'utilisateur
  l'active ; décidé **au lancement**, donc un redémarrage est nécessaire. En cas
  d'échec, repli sur le stockage local et erreur affichée sous le réglage.
- Indicateur du stockage réel : clé UserDefaults `fintrack.activeStoreMode`
  (`cloud` / `local` / `memory`).
- Après un changement de schéma : désinstaller l'app et réinitialiser le schéma
  CloudKit de développement avant de tester.
- Le widget lit ses données via l'App Group (`WidgetData`, `WidgetDataWriter`).
- Les reçus scannés sont stockés localement (`Documents/Receipts/`), jamais dans CloudKit.

## Localisation

- Textes de l'app : `lang["clé"]` (ou `lang.f("clé", args)`) avec des entrées
  `["fr": …, "en": …, "es": …, "pt": …]` dans `LocalizedStrings.swift`. Les **4
  langues** sont obligatoires pour toute nouvelle clé. Au premier lancement, la langue
  suit celle de l'appareil ; l'anglais n'est que le repli. Le choix de l'utilisateur
  est ensuite mémorisé (`appLanguage`).
- Contenu des widgets : table de langue de l'app (`data.language`).
- Libellés système (nom et description du widget, sélecteurs d'intents) : fichiers
  `.strings` dans les dossiers `*.lproj`.
- La marque s'écrit « Fin:Track » dans les textes affichés.

## Pièges déjà rencontrés (et leur solution)

- **CloudKit exige des relations optionnelles.** Une relation to-many non optionnelle
  fait échouer CloudKit (et l'app retombe en local). Motif : propriété stockée
  optionnelle + accesseur calculé non optionnel (voir `Budget.categoriesStore` /
  `categories`).
- **`try?` sur l'init du `ModelContainer` avale la vraie erreur.** Toujours `do/catch`.
- **`cloudKitDatabase` vaut `.automatic` par défaut** : pour un magasin local, toujours
  passer `.none` explicitement.
- **`NavigationLink` qui construit une destination lourde gèle la liste.** Envelopper
  la destination dans `LazyView(...)` (défini dans `RecurrencesView.swift`).
- **`onChange` ne voit pas la valeur présente au montage.** Pour un lien profond,
  traiter aussi dans `onAppear` et consommer la valeur aussitôt (`ManageHubView`).
- **Un lien profond posté pendant la fermeture d'une feuille se perd.** Le poster dans
  le `onDismiss` de la feuille.
- **Un `onAppear` qui recharge l'état écrase les modifications** au retour d'un
  sous-écran. Les éditeurs chargent une seule fois, gardés par `@State didInitialLoad`.
- **Le DeveloperView survit aux redémarrages.** Une simulation de palier oubliée
  masque le vrai état des achats.
- **Changer le bundle ID ou les identifiants de produits** rend les achats de test
  précédents invisibles : on repart en gratuit.
- **Une constante littérale `false` en Release** produit « will never be executed » :
  placer la garde `#if DEBUG` à l'intérieur de la propriété (motif `DemoMode.isActive`).
- **Xcode 27** signale l'usage de `ModelContext` sans `import SwiftData` explicite.
- **XcodeGen régénère les entitlements** : vérifier l'App Group après chaque génération.
- **XCUITest et listes SwiftUI** : `app.cells` ne trouve pas les rangées
  personnalisées ; chercher par `app.buttons` avec un prédicat sur le libellé.

## Journal des décisions

| Date | Décision |
|---|---|
| 2026-06 | Paliers Free / Pro / Max (anciens noms Courant / Épargne / Placement), finalisé en 2026-09 |
| 2026-06 | Textes affichés neutres sur le fournisseur bancaire (ni « Plaid » ni « Flinks ») |
| 2026-08 | Intelligence sur l'appareil (catégorisation, reçus, récurrences), réservée aux paliers payants |
| 2026-08 | Rebranding : identifiants `ca.regis` → `ca.bmsk`, nom affiché « Fin:Track » |
| 2026-09 | Prix lus depuis App Store Connect, plus aucun montant dans le code |
| 2026-09 | Plaid conservé comme fournisseur actif (déjà testé en sandbox) ; Flinks prêt en réserve |
| 2026-09 | Landing bilingue sur `fintrack.bmsk.ca`, inscription à la bêta par Worker + D1 |
| 2026-10 | Faute d'accès production chez Plaid ou Flinks : bêta **sans** synchro bancaire ; Max désactivé (`bankSyncAvailable = false`) jusqu'à nouvel ordre |
| 2026-10 | Logos des institutions servis par **notre** Worker (`/api/logo/<domaine>`), qui les obtient de Logo.dev (Clearbit a fermé en décembre 2025) : Logo.dev ne voit jamais l'utilisateur. Monogramme en secours (chargement, hors ligne, logo absent). Mention « Logos fournis par Logo.dev » obligatoire (Réglages ▸ À propos). Police de la landing hébergée sur le site (plus de Google Fonts) |

Le détail de chaque décision se trouve dans le message du commit correspondant.

## État actuel et chantiers ouverts

- **Bêta TestFlight** en préparation : paliers Courant et Pro seulement.
- **Synchro bancaire** : en attente d'un accès production (Plaid ou Flinks). Côté
  Flinks, il manque le compte, la clé d'API et le proxy (`FlinksManager` contient
  encore des valeurs à remplacer).
- **Prix provisoires** : Pro 24,99 $ sur la landing, 28,99 $ dans `FinTrack.storekit`.
  À aligner avant le lancement.
- **Aucun test unitaire dans le dépôt** ; seul le harnais de captures existe.
- **« Réinitialiser toutes les données » est incomplet** (`SettingsView.resetAll`) :
  il laisse budgets, prêts, marges, récurrences, projets, profils enregistrés et
  images des reçus. À corriger avant le lancement (voir `docs/legal/NOTES-REVISION.md`).
- Le commentaire de `RegisteredType.reer` dit « room calc not implemented here yet »,
  mais le calcul REER est bien implémenté dans `RegisteredRoomCalculator`. Commentaire
  à corriger.
- Avant la soumission : schéma CloudKit à déployer en Production, produits à créer
  dans App Store Connect, politique de confidentialité.

## Tenir ce fichier à jour

Mettre à jour ce fichier **dans le même commit** que le changement concerné quand on :
ajoute un dossier ou un module, change un interrupteur ou un identifiant, prend une
décision produit, ou résout un piège qui pourrait se reproduire. Les détails restent
dans les messages de commit ; ici, seulement la carte et les décisions.

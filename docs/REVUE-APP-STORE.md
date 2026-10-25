# Revue de conformité App Store — Ando

Revue menée le 18 octobre 2026 sur la branche `renommage-ando`, dans l'optique
d'un relecteur d'Apple : non pas « l'app fonctionne-t-elle ? » mais
« sur quel article des *App Store Review Guidelines* peut-elle être refusée ? »

Distincte de `PRE-SOUMISSION.md`, qui liste les bogues. Ici, uniquement ce qui
met l'approbation en jeu. Chaque point a été vérifié dans le code ; ce qui
relève de la déduction est signalé comme tel.

## Verdict

**En l'état, la build ne passerait même pas le téléversement.** Le point R1
est un refus automatique d'App Store Connect, avant toute revue humaine.
Deux autres points (R2, R3) sont des motifs de rejet classiques en revue.

| | Points | Effet |
|---|---|---|
| Refus certain | R1 | Téléversement refusé par App Store Connect |
| Rejet probable en revue | R2, R3, R4 | Retour du *Resolution Center*, 24-48 h perdues par aller-retour |
| Friction | R5 à R9 | Questions du relecteur, délais, mais pas de rejet en soi |

## État au 18 octobre 2026, 9 h 50

Corrections appliquées dans la journée, **vérifiées dans le bundle Release
réellement produit** et non seulement dans le code source.
Commits `d824cf0` (conformité) et `aafebdc` (B1), branche `renommage-ando` ;
R2, R3, R8 et R9 encore à committer.
Vérification au vert : Debug et Release 0/0, **56 tests**, 0 échec.

| | Point | État |
|---|---|---|
| R1 | Manifestes de confidentialité | ✅ les deux présents dans `Ando.app` et `AndoWidget.appex` |
| R2 | Lien politique de confidentialité | ✅ Réglages, écran d'abonnement **et** mur Pro |
| R2 | Conditions d'utilisation | ✅ rédigées, publiées, liées aux trois mêmes endroits — ⚠️ **relecture juridique non faite** |
| R3 | Verrou sans récupération | ✅ le NIP est devenu **facultatif**, et désactivable |
| R4 | Notifications distantes | ✅ `UIBackgroundModes` et `aps-environment` absents du bundle signé |
| R5 | Valeurs de remplacement | ✅ plus aucune chaîne `VOTRE_`/`your-domain` dans le binaire |
| R6 | Nom personnel dans le binaire | ✅ plus aucune occurrence de `regis-bile` |
| R7 | Conformité à l'exportation | ✅ `ITSAppUsesNonExemptEncryption = false` dans l'`Info.plist` livré |
| R8 | Page d'assistance | ✅ `/assistance/` et `/en/support/`, liées depuis l'app |
| R9 | Captures d'écran | ✅ 19 par langue en 1206 × 2622 ; 22 images du site remplacées — ⚠️ voir R10 |
| R10 | Drapeaux en glyphes manquants sur les captures | ✅ drapeaux retirés le 25 octobre, captures régénérées |
| B1 | Conversion de devises *(hors guidelines, mais bloquant)* | ✅ `convert()` optionnel, 24 appels tranchés, 13 tests |
| B6 | Paysage déclaré, interface non vérifiée | ✅ testé : la liste n'y défile pas — paysage retiré de la déclaration |

**Ce qui reste, par nature du blocage :**

- **Une décision de produit** : R10, les drapeaux de la rangée « Langue ».
- **Un test de dix minutes** : B6, l'orientation paysage.
- **Une relecture par un juriste** : les conditions d'utilisation, publiées
  mais non relues. C'est le dernier point qui engage BMSK juridiquement.
- **Du travail hors code** : images sociales `og-fr.jpg` et `og-en.jpg`,
  toujours à l'ancienne marque, et la révocation de la clé d'API exposée.

> [!success] Clé d'API — ✅ changée le 25 octobre 2026
> `APP_API_KEY` a été régénérée côté Worker Cloudflare et l'ancienne clé
> reçoit désormais un 401. La valeur publiée est morte.
>
> **Ce que la rotation ne règle pas** : il s'agit d'un secret partagé destiné
> à être embarqué dans l'app. Le jour où celle-ci sera sur l'App Store, la
> clé sera lisible avec `strings` sur le binaire téléchargé. Avant que la
> connexion bancaire ne parte en production, il faut une authentification
> réelle entre l'app et le proxy — jeton par appareil, ou App Attest. Ce
> n'est pas un raffinement, c'est un prérequis à la fonction.

<details>
<summary>Le constat d'origine, conservé</summary>

> [!danger] Une clé d'API est à révoquer
> `PlaidConfig.apiKey` contenait une **vraie** clé partagée, en clair, dans un
> dépôt **public**, juste sous un commentaire disant de ne jamais faire ça.
> Elle a été retirée du code, mais **elle reste lisible dans l'historique
> Git** : la retirer du fichier ne la révoque pas. À régénérer côté Worker,
> et à ne pas remettre dans un fichier suivi.
>
> Au passage, le renommage automatique du 17 octobre avait modifié cette
> clé sans que ce soit voulu — le motif `fintrack` y figurait — de sorte
> qu'elle ne correspondait déjà plus à celle du proxy déployé.
>
> ⚠️ Cette note elle-même contenait la clé en clair jusqu'au 25 octobre :
> documenter une fuite en recopiant le secret la prolonge. Décrire, ne pas
> citer.

</details>

## R1 · Manifeste de confidentialité absent — refus au téléversement

**Aucun fichier `PrivacyInfo.xcprivacy` n'existe dans le dépôt.** Or l'app
utilise deux catégories d'« API à raison obligatoire » :

| API | Où | Catégorie |
|---|---|---|
| `UserDefaults` — 78 occurrences | partout, dont `WidgetData.swift` | `NSPrivacyAccessedAPICategoryUserDefaults` |
| `attributesOfItem` → `.modificationDate` | `Views/Components/BankPicker.swift:110` | `NSPrivacyAccessedAPICategoryFileTimestamp` |

La règle d'Apple, mot pour mot :

> *Starting May 1, 2024, apps that don't describe their use of required reason
> API in their privacy manifest file aren't accepted by App Store Connect.*

Ce n'est donc pas un avis de revue : c'est un **rejet mécanique au
téléversement**, avec l'erreur `ITMS-91053 — Missing API declaration`.

**Il en faut deux, pas un.** `Ando/Models/WidgetData.swift` est compilé dans
les deux cibles (voir `project.yml`) et appelle `UserDefaults(suiteName:)` :
l'extension widget est un bundle séparé, qui doit porter son propre manifeste.

- [ ] `Ando/PrivacyInfo.xcprivacy`
- [ ] `AndoWidget/PrivacyInfo.xcprivacy`
- [ ] `xcodegen generate` — vérifier que les deux sont bien copiés dans les bundles

Contenu de départ, à adapter :

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>NSPrivacyTracking</key>
    <false/>
    <key>NSPrivacyTrackingDomains</key>
    <array/>
    <key>NSPrivacyCollectedDataTypes</key>
    <array/>
    <key>NSPrivacyAccessedAPITypes</key>
    <array>
        <dict>
            <key>NSPrivacyAccessedAPIType</key>
            <string>NSPrivacyAccessedAPICategoryUserDefaults</string>
            <key>NSPrivacyAccessedAPITypeReasons</key>
            <array>
                <string>CA92.1</string>
                <string>1C8F.1</string>
            </array>
        </dict>
        <dict>
            <key>NSPrivacyAccessedAPIType</key>
            <string>NSPrivacyAccessedAPICategoryFileTimestamp</string>
            <key>NSPrivacyAccessedAPITypeReasons</key>
            <array>
                <string>C617.1</string>
            </array>
        </dict>
    </array>
</dict>
</plist>
```

> **Réserve à lever avant d'expédier.** Les noms de catégories viennent de la
> documentation d'Apple que j'ai lue aujourd'hui. **Les codes de raison
> — `CA92.1`, `1C8F.1`, `C617.1` — viennent de ma connaissance préalable :
> les tableaux d'Apple se chargent en JavaScript et je n'ai pas pu les
> relire.** Apple précise qu'un code déclaré à tort pose problème en revue.
> À confirmer sur
> [*Describing use of required reason API*](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api)
> avant le téléversement. Mon intention : `CA92.1` = données propres à l'app,
> `1C8F.1` = données partagées dans le groupe d'app (le widget),
> `C617.1` = horodatage de fichiers du conteneur de l'app (le cache de logos).

Aucun SDK tiers n'est embarqué : seuls ces deux manifestes sont à produire.

## R2 · Aucun lien vers la politique de confidentialité ni les conditions

Recherche sur tout le code : **zéro occurrence** de *terms*, *conditions
d'utilisation*, *EULA*, *politique de confidentialité*. Les seuls liens
sortants de l'app sont la page des abonnements Apple, `logo.dev`, et les
appels réseau.

Réglages ▸ À propos ne contient que la version, le mode de stockage et
l'attribution Logo.dev (`Views/SettingsView.swift:245-256`).

Deux obligations distinctes se superposent :

**Article 5.1.1** — toute app qui collecte ou transmet des données doit
donner accès à sa politique de confidentialité. L'URL sur la fiche App Store
satisfait la lettre du texte, mais pour une app **financière**, l'absence de
lien dans l'app est une anomalie que le relecteur remarque.

**Article 3.1.2** — plus contraignant, et c'est le premier motif de rejet des
apps d'abonnement : le paywall doit afficher le titre de l'abonnement, sa
durée, son prix, **et des liens fonctionnels vers les conditions
d'utilisation et la politique de confidentialité**. Ni `SubscriptionView`
ni `ProGateView` n'en contenaient.

### ✅ Résolu le 18 octobre 2026

- **Conditions d'utilisation rédigées** : `docs/legal/conditions-utilisation.md`
  (FR) et `terms-of-use.md` (EN), publiées sur `/conditions/` et `/en/terms/`.
- **Liens dans l'app** aux trois endroits qui comptent : Réglages ▸ À propos,
  `SubscriptionView`, et `ProGateView` — ce mur est un écran d'achat au même
  titre que l'autre, ce que la directive ne distingue pas.
- La section 4, *« Ce qu'Ando n'est pas »*, est la plus importante du texte :
  aucun conseil financier ou fiscal, les chiffres sont des estimations, et
  l'avis de cotisation de l'ARC fait foi, pas l'application.

> [!warning] Relecture juridique non faite
> Ce texte a été rédigé par une IA, pas par un avocat. Deux sections
> l'exigent : la **limitation de responsabilité**, que la *Loi sur la
> protection du consommateur* du Québec encadre strictement, et la section
> **Apple**, qui doit reprendre les clauses minimales imposées aux EULA
> personnalisés par le contrat du Developer Program — écrites de mémoire,
> sans vérification mot à mot.
>
> **Alternative sans aucun risque de rédaction** : renoncer à ces conditions
> propres et pointer l'EULA type d'Apple
> (`apple.com/legal/internet-services/itunes/dev/stdeula/`), ce qui satisfait
> la directive 3.1.2 sans texte à défendre. Les deux options sont notées en
> tête du fichier source.

> **Ce point dépend d'une décision que tu n'as pas encore prise.** Tant que
> `bankSyncAvailable = false`, Max est masqué et tu ne vends qu'un achat
> unique : l'article 3.1.2 **ne s'applique pas**, seul 5.1.1 reste. Mais si
> tu crées le produit Max dans App Store Connect et le joins à la version
> 1.0, 3.1.2 s'applique intégralement. **Ne livrer que Pro évite ce rejet**
> — c'est l'argument le plus fort en faveur de cette option.

- [x] Lien politique de confidentialité dans Réglages ▸ À propos :
      `https://ando.bmsk.ca/confidentialite/` (FR) · `/en/privacy/` (EN)
- [x] **Rédiger des conditions d'utilisation** — elles n'existent nulle part,
      ni dans l'app ni sur le site. À défaut, Apple fournit une EULA type
      dont il suffit de pointer l'URL
- [x] Les deux liens dans les deux paywalls, pas seulement dans Réglages
- [ ] Si Max est vendu : prix, durée et mention de reconduction tacite sur
      l'écran d'achat lui-même

## R3 · Le verrou du premier lancement n'a aucune sortie de secours

> **En une phrase** : Ando obligeait à créer un NIP au tout premier écran,
> sans aucun moyen de rentrer si on l'oubliait — ni « NIP oublié », ni
> réinstallation, le NIP vivant dans le trousseau et y survivant.

### ✅ Résolu le 18 octobre 2026 — le verrou devient facultatif

Plutôt qu'ajouter un « NIP oublié » destructeur, le verrou lui-même a été
rendu optionnel. Les données d'Ando ne quittent pas l'appareil : le
verrouillage de l'iPhone les protège déjà. Le NIP est une couche
supplémentaire, désormais proposée et non imposée.

- `AppLockManager.hasPIN` : le verrou existe si et seulement si un hachage
  de NIP est stocké. Le verrouillage au lancement, la mise en arrière-plan
  et le retour au premier plan y sont tous conditionnés.
- `completeSetupWithoutPIN(userName:)` : « Continuer sans code » au premier
  lancement, dès l'écran du nom comme à celui du NIP, avec une phrase qui
  dit que c'est facultatif **avant** que la personne ne choisisse un code
  qu'elle oubliera.
- `disableLock()` : Réglages ▸ Sécurité permet de **retirer** le code en
  conservant toutes les données. C'est la sortie de secours qui manquait.
- Réglages ▸ Sécurité propose « Activer le verrouillage » quand aucun code
  n'existe, et masque biométrie, délai et « verrouiller maintenant », qui
  n'avaient alors aucun sens.
- `lock()` refuse d'agir sans NIP : même appelé par erreur, il ne peut plus
  enfermer quelqu'un devant un écran qui n'accepterait aucun code.

Bénéfice secondaire : le premier lancement montre l'app avant de réclamer un
effort, au lieu d'ouvrir sur un pavé numérique.

`RootView.swift:36` présente `SetupAccountView` dès qu'aucun compte n'est
configuré. Le parcours est **nom → NIP → confirmation → biométrie → verrouillage
automatique**. Le bouton « passer » n'apparaît qu'aux étapes *biométrie* et
*verrouillage automatique* (`SetupAccountView.swift:59`) : **le NIP est
obligatoire**, dès le premier écran, avant d'avoir rien vu de l'app.

Et il n'y a **aucune récupération** : recherche de *forgot*, *oubli*,
*reset pin*, *recover* dans tout `Ando/Security/` — zéro résultat.
`LockScreenView` n'offre que la saisie du NIP, la biométrie, et un délai de
blocage après plusieurs échecs.

Le NIP est stocké en **trousseau** (`AppLockManager.swift:100-105` :
`pinHash`, `pinSalt`, et le drapeau `isSetup`).

**Pourquoi c'est un risque de rejet (article 2.1).** Le relecteur crée un NIP
en trente secondes, teste l'app, la met en arrière-plan ; avec un
verrouillage réglé sur « immédiatement », il doit le ressaisir. S'il l'a noté
de travers, il est dehors — et il ne peut pas en sortir. Un relecteur bloqué
ne cherche pas la cause : il rejette.

**Et c'est un défaut produit indépendamment d'Apple.** Les entrées du
trousseau survivent normalement à la suppression de l'app sur iOS :
réinstaller ne redonnerait donc pas l'accès. **Je n'ai pas testé ce
comportement précis sur cette app** — c'est le premier essai à faire, car il
décide de la gravité : un utilisateur qui oublie son NIP perdrait toutes ses
données financières sans recours.

- [ ] **Tester** : régler un NIP, supprimer l'app, la réinstaller. Accessible
      ou verrouillée ?
- [ ] Offrir une porte de sortie. La moins mauvaise pour une app financière :
      « NIP oublié » → explication claire → **effacement des données locales**
      et retour au premier lancement. Destructeur, mais honnête, et ça libère
      le relecteur
- [ ] Envisager de rendre le NIP **optionnel** au premier lancement, proposé
      plutôt qu'imposé. Rien n'oblige à verrouiller une app dont les données
      ne quittent pas l'appareil
- [ ] Le signaler dans les notes au relecteur quoi qu'il arrive

## R4 · Mode d'arrière-plan déclaré sans être utilisé — article 2.5.4

Déjà relevé le 17 octobre, inchangé, et c'est le seul des anciens points qui
soit un vrai motif de rejet.

`Ando/Info.plist` déclare `UIBackgroundModes: remote-notification` et les
entitlements déclarent `aps-environment: development`. Aucune occurrence de
`registerForRemoteNotifications` dans tout `Ando/` : seules des notifications
**locales** existent (`Utilities/NotificationManager.swift:32`).

L'article 2.5.4 vise exactement ce cas : déclarer un mode d'arrière-plan sans
l'usage correspondant. En prime, `development` est la mauvaise valeur pour une
build App Store et peut provoquer un *Invalid Code Signing Entitlements* au
téléversement.

- [ ] Retirer `UIBackgroundModes` d'`Info.plist`
- [ ] Retirer `aps-environment` des entitlements
- [ ] Désactiver la capacité Push dans le portail développeur

## R5 · Valeurs de remplacement dans le binaire livré

| Fichier | Valeur |
|---|---|
| `Flinks/FlinksManager.swift:28` | `https://VOTRE_PROXY_URL_ICI` |
| `Flinks/FlinksManager.swift:35` | `VOTRE_API_KEY_ICI` |
| `Plaid/PlaidManager.swift:17` | `https://ando.your-domain.com` |

Code mort tant que `bankSyncAvailable = false` : le relecteur ne les
atteindra pas. Mais ces chaînes partent dans le binaire et dans un dépôt
public. L'article 2.1 refuse les fonctions manifestement inachevées ; si la
synchro bancaire était réactivée sans nettoyage, le rejet serait immédiat.

- [ ] Remplacer par des valeurs vides et un `assert` au démarrage si la
      synchro est activée sans configuration

## R6 · Ton nom personnel est livré dans le binaire

`Plaid/PlaidManager.swift:18` contient
`https://hidden-block-e3ed.regis-bile.workers.dev`.

Ce n'est pas un motif de rejet. Mais tu as demandé en août de retirer ton nom
des identifiants au profit de BMSK : il est resté ici, dans une chaîne
expédiée avec l'app et visible dans un dépôt public.

- [ ] Déplacer cette URL derrière le domaine `bmsk.ca`, ou la sortir du code

## R7 · Conformité à l'exportation non déclarée

`ITSAppUsesNonExemptEncryption` absent d'`Info.plist` : la question du
chiffrement sera posée **à chaque téléversement**. L'app n'utilise que HTTPS
standard, donc la réponse est « non » — mais c'est une déclaration légale qui
t'engage, à valider toi-même.

## R8 · Aucune page d'assistance — ✅ résolu le 18 octobre 2026

L'URL d'assistance est **obligatoire** sur la fiche, et rien n'existait.

Publiée sur **`https://ando.bmsk.ca/assistance/`** (FR) et
**`/en/support/`** (EN) : contact, délai de réponse annoncé, et dix
questions fréquentes tirées du comportement réel de l'app — dont « pourquoi
un total affiche-t-il ≈ » et « faut-il un code pour ouvrir Ando », les deux
changements du jour. Liée aussi depuis Réglages ▸ À propos.

Source : `docs/legal/assistance.md` et `support.md`. C'est **cette URL** à
inscrire dans le champ d'assistance d'App Store Connect.

## R9 · Captures d'écran — ✅ régénérées le 18 octobre 2026

Article 2.3.3 : les captures doivent montrer l'app telle qu'elle est. Celles
du site portaient encore « Fin:Track » et l'ancienne icône.

Le harnais `AndoUITests/ScreenshotTests` citait un simulateur « iPhone
16 Pro Max » qui n'existe plus sur cette machine. Relancé sur un
**iPhone 17 Pro**, puis la résolution produite a été **mesurée, pas
supposée** : `1206 × 2622`, soit exactement l'une des deux tailles
obligatoires d'Apple (« iPhone à Dynamic Island, écran moyen »).

- 19 captures par langue, dans `_captures/ando-fr/` et `_captures/ando-en/`.
  **Ce sont ces PNG pleine résolution qu'il faut téléverser** dans App Store
  Connect, pas les images du site.
- Les 22 `.webp` du site (`public/img/` et `img-en/`) ont été remplacés par
  `scripts/captures-vers-site.py`, qui respecte les noms déjà référencés par
  la landing — un nom qui change casserait un `<img>` et son texte alternatif.

Restent à refaire, hors harnais : **`og-fr.jpg` et `og-en.jpg`**, les images
de partage social, toujours à l'ancienne marque et non générées par le build.

> ✅ Les captures sont livrables depuis le 25 octobre : voir R10.

## R10 · Les drapeaux ne s'affichent pas sur les captures — ✅ réglé le 25 octobre 2026

**Les drapeaux ont été retirés**, pas contournés. `AppLanguage.flag` n'existe
plus, et la rangée « Langue de l'application » comme le sélecteur affichent le
seul nom de la langue, écrit dans cette langue.

Les deux raisons, dont une seule était technique :

1. Toute capture prise au simulateur aurait recassé, à chaque version.
2. **Un drapeau français pour « Français » est faux pour une app
   canadienne.** Le Québec n'est pas la France, le Canada n'est pas le
   Royaume-Uni. Le nom de la langue dit la même chose sans se tromper de pays.

Les 19 captures par langue ont été régénérées et les 22 images du site
remplacées. Vérifié en **regardant** l'écran des réglages dans les deux
langues : « Langue de l'application · Français » et « App Language · English »,
sans carré.

> [!note] Les drapeaux de pays du sélecteur de banque restent
> `BankPicker` affiche encore `BankDirectory.flag(for:)` à côté du nom du
> pays. Même défaut d'affichage au simulateur, mais le cas est différent :
> un drapeau canadien en face de « Canada » est juste, là où un drapeau
> français en face de « Français » ne l'était pas. Aucune capture livrée ne
> montre cet écran. À trancher si l'une d'elles devait le montrer un jour.

<details>
<summary>Le constat d'origine</summary>

### R10 · Les drapeaux ne s'affichent pas sur les captures

Trouvé le 18 octobre en **regardant** les captures régénérées, pas en
relisant du code.

La rangée « Langue de l'application » affiche `lang.current.flag`, c'est-à-dire
🇫🇷 ou 🇬🇧 (`Localization/LanguageManager.swift:31`). Sur les captures prises
au simulateur, ces drapeaux sortent en **deux carrés « ? »** : la fonte
d'émojis du simulateur ne contient pas les indicateurs régionaux.

Sur un vrai iPhone le drapeau s'affiche — **je ne l'ai pas vérifié**, faute
d'appareil. Mais le défaut est réel là où ça compte : l'image
`19-reglages.webp` du site, et la capture destinée à App Store Connect,
montrent des glyphes cassés.

Deux raisons de retirer ces drapeaux plutôt que de contourner :

1. Toute capture prise au simulateur restera cassée, à chaque version.
2. **Un drapeau français pour une app canadienne** est discutable auprès du
   marché visé. « Français » et « English » sans drapeau évitent la question
   — le Québec n'est pas la France, et le Canada n'est pas le Royaume-Uni.

Laissé en l'état : c'est un choix de produit, pas une correction technique.

</details>

## Vérifié conforme

| Point | Article | État |
|---|---|---|
| Bouton « Restaurer les achats » | 3.1.1 | Présent dans les deux paywalls |
| Max masqué quand la synchro est coupée | 2.1 | `bankSyncAvailable` consulté aux 9 bons endroits |
| Mode développeur | 2.3.1 | `#if DEBUG` — absent du Release |
| Textes d'usage Face ID et caméra | 5.1.1 | Présents |
| Photothèque | 5.1.1 | `PhotosPicker` : aucun texte requis |
| Suppression de compte | 5.1.1(v) | Sans objet : verrou local, pas de compte distant |
| Pistage publicitaire | 5.1.2 | Aucun SDK, aucun identifiant publicitaire |
| SDK tiers | — | Aucun : un seul manifeste par cible à produire |
| Identifiants de produits | — | `ca.bmsk.ando.pro` / `.max` correctement mappés |
| Build et tests | — | Debug et Release 0/0 ; 43 tests, 0 échec |

## Dette signalée, sans effet sur l'approbation

- Les cas d'énumération Swift s'appellent encore `.epargne` et `.placement`
  alors qu'ils pointent vers `…pro` et `…max` (`EntitlementManager.swift:23`).
  Fonctionnellement juste, trompeur à la lecture.
- `EntitlementManager.swift:8` annonce « ~28,99 $ CAD » ; le prix réel est
  24,99 $.

## Ordre conseillé

1. **R1** — sans les deux manifestes, rien ne monte. Une heure de travail.
2. **R4** et **R7** — deux lignes d'`Info.plist` et d'entitlements.
3. **R3** — la porte de sortie du verrou. C'est le point qui demande une
   décision de conception, et le seul qui touche à l'expérience.
4. **R2** — lien de confidentialité partout ; conditions d'utilisation à
   rédiger seulement si tu vends Max dès la 1.0.
5. **R5**, **R6** — nettoyage.
6. **R8**, **R9** — page d'assistance et visuels, en parallèle du reste.

## Sources

- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Describing use of required reason API](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api)

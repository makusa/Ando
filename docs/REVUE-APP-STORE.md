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

## État au 18 octobre 2026, 9 h

Corrections appliquées le matin même, **vérifiées dans le bundle Release
réellement produit** et non seulement dans le code source.

| | Point | État |
|---|---|---|
| R1 | Manifestes de confidentialité | ✅ les deux présents dans `Ando.app` et `AndoWidget.appex` |
| R2 | Lien politique de confidentialité | ✅ Réglages ▸ À propos **et** écran d'abonnement |
| R2 | Conditions d'utilisation | ❌ **le document n'existe pas** — à rédiger |
| R3 | Verrou sans récupération | ❌ demande une décision de conception |
| R4 | Notifications distantes | ✅ `UIBackgroundModes` et `aps-environment` absents du bundle signé |
| R5 | Valeurs de remplacement | ✅ plus aucune chaîne `VOTRE_`/`your-domain` dans le binaire |
| R6 | Nom personnel dans le binaire | ✅ plus aucune occurrence de `regis-bile` |
| R7 | Conformité à l'exportation | ✅ `ITSAppUsesNonExemptEncryption = false` dans l'`Info.plist` livré |
| R8 | Page d'assistance | ❌ reste à créer |
| R9 | Captures d'écran | ❌ reste à refaire |

Vérification complète au vert après corrections : Debug et Release
0 erreur / 0 avertissement, 43 tests, 0 échec.

> [!danger] Une clé d'API est à révoquer
> `PlaidConfig.apiKey` contenait une **vraie** clé partagée, en clair, dans un
> dépôt **public**, juste sous un commentaire disant de ne jamais faire ça.
> Elle a été retirée du code, mais **elle reste lisible dans l'historique
> Git** : la retirer du fichier ne la révoque pas. À régénérer côté Worker,
> et à ne pas remettre dans un fichier suivi.
>
> Au passage, le renommage automatique du 17 octobre avait modifié cette
> clé sans que ce soit voulu (`fintrack-2026-bmsk` → `ando-2026-bmsk`) :
> elle ne correspondait donc déjà plus à celle du proxy déployé.

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
ni `ProGateView` n'en contiennent.

> **Ce point dépend d'une décision que tu n'as pas encore prise.** Tant que
> `bankSyncAvailable = false`, Max est masqué et tu ne vends qu'un achat
> unique : l'article 3.1.2 **ne s'applique pas**, seul 5.1.1 reste. Mais si
> tu crées le produit Max dans App Store Connect et le joins à la version
> 1.0, 3.1.2 s'applique intégralement. **Ne livrer que Pro évite ce rejet**
> — c'est l'argument le plus fort en faveur de cette option.

- [ ] Lien politique de confidentialité dans Réglages ▸ À propos :
      `https://ando.bmsk.ca/confidentialite/` (FR) · `/en/privacy/` (EN)
- [ ] **Rédiger des conditions d'utilisation** — elles n'existent nulle part,
      ni dans l'app ni sur le site. À défaut, Apple fournit une EULA type
      dont il suffit de pointer l'URL
- [ ] Les deux liens dans les deux paywalls, pas seulement dans Réglages
- [ ] Si Max est vendu : prix, durée et mention de reconduction tacite sur
      l'écran d'achat lui-même

## R3 · Le verrou du premier lancement n'a aucune sortie de secours

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

## R8 · Aucune page d'assistance

L'URL d'assistance est **obligatoire** sur la fiche. Rien n'existe
aujourd'hui sur `ando.bmsk.ca`. Une page avec `bonjour@bmsk.ca` et quelques
questions fréquentes suffit.

## R9 · Captures d'écran — article 2.3.3

Les captures doivent montrer l'app telle qu'elle est. Celles du site portent
encore « Fin:Track » et l'ancienne icône : onze fichiers dans
`_landing/public/img/`, autant dans `img-en/`, plus `og-fr.jpg` et
`og-en.jpg`. Les captures de la fiche sont à régénérer avec le harnais.

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

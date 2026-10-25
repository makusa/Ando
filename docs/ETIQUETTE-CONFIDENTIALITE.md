# Étiquette de confidentialité — réponses pour App Store Connect

*App Store Connect ▸ votre app ▸ **App Privacy**.* Établi le 25 octobre 2026
en lisant le code, pas la politique de confidentialité — puis en vérifiant que
les deux concordent.

## La réponse

> **Data Not Collected.**
> À la première question — *Do you or your third-party partners collect data
> from this app?* — répondre **No**.

C'est tout. Aucune catégorie à cocher ensuite.

Le manifeste `Ando/PrivacyInfo.xcprivacy` dit déjà la même chose
(`NSPrivacyCollectedDataTypes` vide, `NSPrivacyTracking` à faux) : les deux
déclarations doivent rester cohérentes, un écart est repéré au téléversement.

## Pourquoi, et la définition qui compte

Apple ne demande pas « des données sortent-elles de l'appareil ? » mais
**« collectez-vous des données ? »**, et définit *collect* comme : transmettre
hors de l'appareil **et** conserver au-delà de ce qu'exige le traitement de la
requête.

Trois flux sortent de l'appareil. Aucun ne satisfait les deux conditions.

### 1 · Les taux de change

`ExchangeRateManager.swift:167` appelle
`https://api.exchangerate-api.com/v4/latest/CAD`.

URL fixe, devise de base en dur. **Rien de l'utilisateur n'y est joint** : ni
montant, ni compte, ni identifiant. Le fournisseur reçoit l'adresse IP de
l'appareil, comme tout serveur recevant une requête.

### 2 · Les logos d'institutions

`BankPicker.swift:26` demande `https://ando.bmsk.ca/api/logo/<domaine>` —
**notre** serveur, pas un tiers.

La requête porte le nom de domaine de l'institution. Le Worker **ne conserve
pas ces requêtes** : `invocation_logs: false` dans `_landing/wrangler.jsonc`,
posé exactement pour ça. Et c'est le Worker qui interroge Logo.dev, de sorte
que Logo.dev ne voit jamais l'adresse IP de l'utilisateur.

Côté app, la session est **éphémère**, sans témoins ni cache partagé
(`BankLogoStore`), et le logo obtenu est gardé localement un mois.

### 3 · La synchronisation iCloud

CloudKit, **base privée** du compte iCloud de l'utilisateur
(`cloudKitDatabase: .private("iCloud.ca.bmsk.ando")`).

Apple exclut explicitement ce cas : des données dans l'iCloud privé de
l'utilisateur ne sont pas « collectées par le développeur ». Nous n'y avons
aucun accès — ni technique, ni contractuel.

## Catégorie par catégorie

Ce que demanderait App Store Connect si on répondait « Yes », et ce qu'il
faudrait cocher : rien.

| Catégorie Apple | Réponse | Pourquoi |
|---|---|---|
| Contact Info | Non | Aucune inscription, aucun compte, aucun courriel demandé |
| Health & Fitness | Non | Sans objet |
| **Financial Info** | **Non** | C'est le cœur de l'app, et **tout reste local** ou dans l'iCloud privé |
| Location | Non | Aucune API de localisation |
| Sensitive Info | Non | Sans objet |
| Contacts | Non | Aucun accès au carnet d'adresses |
| User Content | Non | Les photos de reçus sont analysées **sur l'appareil** et n'en sortent pas |
| Browsing / Search History | Non | Sans objet |
| Identifiers | Non | Aucun IDFA, aucun identifiant publicitaire, aucun compte utilisateur |
| Purchases | Non | StoreKit est géré par Apple ; nous n'en conservons rien |
| Usage Data | Non | Aucun SDK d'analyse, aucune télémétrie |
| Diagnostics | Non | Aucun SDK de plantage. Les rapports d'Apple sont les siens, et n'ont pas à être déclarés |
| Other Data | Non | Voir les trois flux ci-dessus |

**Tracking** : *No*. Aucune donnée n'est recoupée avec des données d'autres
sociétés, aucun courtier n'est alimenté. Pas d'`App Tracking Transparency` à
demander, pas de domaine dans `NSPrivacyTrackingDomains`.

## Les deux points de jugement

Ils sont défendables, pas automatiques. Autant les connaître avant qu'on les
soulève.

**Une app de finances qui déclare « aucune donnée collectée » attire l'œil.**
C'est inhabituel, et un relecteur peut demander pourquoi. La réponse tient en
une phrase : *les données financières ne quittent jamais l'appareil, sauf vers
le compte iCloud privé de l'utilisateur, auquel nous n'avons pas accès.* Elle
est déjà dans les notes au relecteur de
[[METADONNEES-APP-STORE]].

**Nous ne contrôlons pas la rétention d'ExchangeRate-API.** Leur serveur reçoit
l'adresse IP de l'appareil à chaque rafraîchissement. Nous ne leur transmettons
rien d'autre, mais nous ne pouvons pas attester de ce qu'ils en font.

> [!tip] Ce qui refermerait ce point
> Faire passer les taux par notre Worker, comme les logos. Le fournisseur ne
> verrait alors que notre serveur, et notre serveur ne conserve rien. Le code
> existe déjà pour les logos : c'est une route de plus, pas une architecture.
> À considérer, sans urgence : aucune donnée personnelle n'est en jeu, une
> adresse IP l'est marginalement.

## Ce qui changerait la réponse

- **Connexion bancaire** (Plaid ou Flinks). Aujourd'hui inerte —
  `bankSyncAvailable = false`, configurations vidées. Le jour où elle
  s'allume, des identifiants et des transactions transitent par un
  prestataire : l'étiquette devient *Financial Info collected*, liée à
  l'identité, et la politique de confidentialité change de nature.
- **Assistance par IA.** Si elle envoie des données à un modèle distant,
  tout ce qui part doit être déclaré.
- **Tout SDK tiers ajouté.** Chacun apporte son propre manifeste et ses
  propres déclarations, qui se fondent dans l'étiquette de l'app.

## Concordance vérifiée le 25 octobre 2026

| Source | Dit |
|---|---|
| `Ando/PrivacyInfo.xcprivacy` | `NSPrivacyCollectedDataTypes` vide, `NSPrivacyTracking` faux |
| `AndoWidget/PrivacyInfo.xcprivacy` | idem |
| `docs/legal/politique-confidentialite.md` | nomme ExchangeRate-API, le relais de logos, l'absence de conservation, et les pays d'hébergement |
| Code | trois appels réseau seulement, ceux décrits ci-dessus |
| Étiquette App Store | *Data Not Collected* |

Les cinq doivent rester d'accord. Si l'un bouge, les autres aussi.

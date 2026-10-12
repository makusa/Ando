# Politique de confidentialité de Fin:Track

> Source de la page publiée sur fintrack.bmsk.ca/confidentialite (version
> anglaise : `privacy-policy.md`, publiée sur /en/privacy). Pour la modifier :
> éditer ce fichier, puis `python3 build.py` dans `_landing/`, puis déployer.
> Les lignes commençant par « > » ne sont pas publiées. Notes internes :
> `NOTES-REVISION.md`.

**Dernière mise à jour : 11 octobre 2026**

## 1. Qui sommes-nous

Fin:Track est une application de finances personnelles conçue et exploitée par
**BMSK**, 5025, avenue Westmore, Montréal (Québec) H4V 1Z4, Canada
(« nous »).

**Responsable de la protection des renseignements personnels** :
Régis Bile Masuke, gérant.
Courriel : **confidentialite@bmsk.ca**

## 2. Ce que couvre cette politique

- le site **fintrack.bmsk.ca** (liste d'attente de la bêta) ;
- l'application **Fin:Track** pour iPhone, en version bêta distribuée par
  TestFlight.

## 3. Notre principe

Vos données financières restent sur votre appareil. Nous n'avons pas de
serveur qui reçoit vos comptes, vos transactions ou vos reçus. L'application
ne contient ni outil de mesure d'audience, ni publicité, ni traceur.

## 4. Le site fintrack.bmsk.ca

### Ce que nous recueillons

Uniquement si vous vous inscrivez à la liste d'attente :

| Renseignement | Pourquoi |
|---|---|
| Votre adresse courriel | Vous envoyer l'invitation à la bêta |
| La langue de la page (français ou anglais) | Vous écrire dans votre langue |
| Votre pays, déduit de votre connexion par notre hébergeur | Connaître la provenance des inscriptions |
| La date de l'inscription et la version du texte de consentement affiché | Pouvoir prouver votre consentement |

Nous **ne conservons pas** votre adresse IP. Le site ne dépose **aucun témoin**
(cookie) et n'utilise aucun outil de mesure d'audience.

### Ce que nous en faisons

Votre adresse sert **uniquement** à vous envoyer l'invitation à la bêta, comme
promis sur la page : pas d'infolettre, pas de partage à des tiers. Nous ne vous
enverrons d'autres messages (par exemple l'annonce du lancement) que si vous
y consentez séparément.

### Durée de conservation

Jusqu'à **12 mois après la fin de la bêta**, ou jusqu'à ce que vous demandiez
la suppression, selon la première éventualité.

### Hébergement et services tiers

**Cloudflare, Inc.** héberge le site et la liste d'attente. Ces données
peuvent être conservées à l'extérieur du Québec, notamment aux États-Unis.
Le site ne fait appel à aucun autre service : la police de caractères est
hébergée sur notre propre site.

## 5. L'application Fin:Track

### Ce qui reste sur votre appareil

Vos comptes, transactions, budgets, prêts, droits de cotisation, reçus
numérisés et réglages sont enregistrés **sur votre iPhone**. Nous n'y avons pas
accès. Le déverrouillage par Face ID ou par NIP se fait sur l'appareil ; nous
ne recevons aucune donnée biométrique. Les rappels sont des notifications
locales, programmées sur l'appareil.

La reconnaissance du texte des reçus et les suggestions automatiques
(catégories, paiements récurrents) sont calculées **sur l'appareil**, sans
envoi à un service externe.

### Synchronisation iCloud (facultative, paliers payants)

Si vous l'activez, vos données sont synchronisées entre vos appareils par
**iCloud**, dans votre espace privé, sous votre compte Apple. Ce service est
fourni par Apple Inc. selon sa propre politique de confidentialité ; nous
n'avons pas accès à ces données.

### Services externes contactés par l'application

L'application contacte un seul service tiers : **ExchangeRate-API**, pour
mettre à jour les taux de change. La requête contient uniquement la devise de
référence (par exemple CAD) ; elle ne contient ni vos montants, ni vos
transactions, ni votre identité, mais le service reçoit l'adresse IP de votre
connexion.

Pour afficher le logo d'une institution financière, l'application le demande à
**notre serveur** (fintrack.bmsk.ca). Comme tout site web, celui-ci reçoit votre
adresse IP et le nom de l'institution demandée, mais il **ne conserve pas ces
requêtes**. Il obtient le logo du service **Logo.dev** sans lui transmettre votre
adresse IP ni aucune information sur vous. Le logo est ensuite gardé sur votre
appareil ; en son absence, l'application affiche un monogramme.

### Connexion bancaire

La version bêta **n'offre pas** de connexion à votre banque. Si cette
fonction est ajoutée, elle sera facultative, cette politique sera mise à jour
et votre consentement sera demandé avant toute connexion.

### Exportations

Lorsque vous exportez vos transactions (fichier CSV), le fichier est créé sur
votre appareil et partagé là où **vous** le choisissez.

### Bêta TestFlight

La bêta est distribuée par **TestFlight**, un service d'Apple. Si nous vous
invitons par courriel, nous connaissons cette adresse. Si vous nous envoyez un
commentaire ou une capture d'écran depuis TestFlight, nous les recevons. Apple
peut aussi nous transmettre des rapports de plantage et des informations
techniques sur l'appareil.

### Achats

Les achats éventuels sont traités par **Apple** (App Store). Nous ne recevons
ni vos coordonnées bancaires, ni votre identité ; seulement la confirmation
qu'un achat est actif.

## 6. Renseignements traités à l'extérieur du Québec

Les fournisseurs mentionnés ci-dessus (Cloudflare, Apple, ExchangeRate-API)
peuvent traiter des renseignements à l'extérieur du
Québec : aux États-Unis pour Cloudflare et Apple ; en Afrique du Sud, en Irlande
et en Allemagne pour ExchangeRate-API. Nous ne leur confions que les
renseignements nécessaires au service décrit dans cette politique.

## 7. Vos droits

Vous pouvez à tout moment :

- **accéder** aux renseignements que nous détenons sur vous ;
- les faire **rectifier** s'ils sont inexacts ;
- **retirer votre consentement** et nous demander de les **supprimer**
  (par exemple, vous retirer de la liste d'attente) ;
- recevoir vos renseignements dans un **format technologique structuré et
  couramment utilisé** (portabilité).

Pour exercer un droit, écrivez au responsable de la protection des
renseignements personnels (section 1). Nous répondons dans un délai de
**30 jours**.

Les données enregistrées dans l'application restent sur votre appareil : nous
ne les détenons pas. Vous pouvez exporter vos transactions (CSV) depuis
l'application, et tout supprimer depuis **Réglages ▸ Réinitialiser toutes les
données** ; si la synchronisation iCloud est active, la suppression s'applique
aussi à votre compte iCloud et à vos autres appareils. Supprimer l'application
efface les données de l'appareil, mais pas leur copie iCloud : vous pouvez la
supprimer depuis les réglages iCloud de votre appareil.

## 8. Sécurité

Les données de l'application sont protégées par le chiffrement de l'appareil
et, si vous l'activez, par Face ID ou un NIP. Les secrets techniques sont
conservés dans le trousseau d'iOS. La liste d'attente n'est accessible qu'au
moyen d'une clé d'accès réservée.

En cas d'incident de confidentialité présentant un risque de préjudice
sérieux, nous aviserons les personnes concernées et la Commission d'accès à
l'information du Québec.

## 9. Âge

Fin:Track s'adresse aux personnes de **18 ans et plus**. Nous ne recueillons
pas sciemment de renseignements sur des personnes mineures.

## 10. Modifications

Nous publierons toute modification sur cette page, avec sa date. Si une
modification change la façon dont nous utilisons vos renseignements, nous
vous en informerons et, au besoin, vous demanderons votre consentement.

## 11. Questions et plaintes

Écrivez d'abord au responsable de la protection des renseignements personnels
(section 1). Vous pouvez aussi vous adresser à la **Commission d'accès à
l'information du Québec** ou, si vous résidez ailleurs au Canada, au
**Commissariat à la protection de la vie privée du Canada**.

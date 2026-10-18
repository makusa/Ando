# Évaluations des facteurs relatifs à la vie privée (EFVP) — communications hors Québec

**BMSK — Ando** · Premier jet du 11 octobre 2026 · Responsable : Régis Bile
Masuke, gérant, responsable de la protection des renseignements personnels.

> Document interne, non publié. Premier jet préparé avec l'aide d'une IA, à
> partir du code, de l'infrastructure réelle et des documents publics des
> fournisseurs (consultés le 11 octobre 2026). Ce n'est pas un avis juridique :
> une validation par un juriste est recommandée. Les mentions **[À VALIDER]**
> signalent une question d'interprétation juridique ; **[À VÉRIFIER]**, un fait
> à confirmer.

## 1. Cadre

L'article 17 de la *Loi sur la protection des renseignements personnels dans le
secteur privé* (modifié par la Loi 25, en vigueur depuis le 22 septembre 2023)
exige, **avant** de communiquer un renseignement personnel à l'extérieur du
Québec (y compris l'hébergement chez un fournisseur infonuagique), une
évaluation qui tient compte notamment :

1. de la **sensibilité** du renseignement ;
2. de la **finalité** de son utilisation ;
3. des **mesures de protection**, y compris contractuelles, dont il bénéficierait ;
4. du **régime juridique** applicable dans l'État où il serait communiqué.

La communication doit faire l'objet d'une **entente écrite** qui tient compte des
résultats de l'évaluation et, le cas échéant, des mesures convenues pour
atténuer les risques. L'évaluation est proportionnée à la sensibilité des
renseignements.

Trame : guide d'accompagnement de la Commission d'accès à l'information sur les
EFVP (annexe 3 : communication à l'extérieur du Québec).

## 2. Inventaire des flux (vérifié dans le code et l'infrastructure)

| # | Flux | Renseignements | Destinataire et lieu | Communication hors Québec par BMSK ? |
|---|---|---|---|---|
| F1 | Liste d'attente de la bêta | Courriel, langue, pays (déduit), date, version du consentement | Cloudflare, Inc. (États-Unis) ; base D1 en région « ENAM » (est de l'Amérique du Nord) | **Oui** → EFVP 1 |
| F2 | Site et route des logos | Adresse IP du visiteur et, pour un logo, nom de domaine d'une institution ; traitement transitoire, aucun journal conservé | Cloudflare, Inc. | **Oui (transitoire)** → EFVP 1 |
| F3 | Invitations TestFlight | Par lien public : aucun. Par courriel : nom et courriel saisis par BMSK | Apple Inc. (États-Unis) | **Seulement si invitation par courriel** → EFVP 2 |
| F4 | Taux de change | Adresse IP de l'appareil, devise de référence | AYR Tech (Pty) Ltd (Afrique du Sud) ; serveurs en Irlande, Afrique du Sud et Allemagne | **Oui (transitoire)** → EFVP 3 |
| F5 | Logos des institutions | Aucun : la requête vient du serveur de BMSK, sans en-tête du visiteur | Logodev, Inc. (États-Unis) | Non (aucun renseignement personnel) |
| F6 | Synchronisation iCloud, achats | Données de l'utilisateur dans son propre compte Apple ; BMSK n'y a pas accès | Apple Inc. | Probablement non : relation directe utilisateur–Apple **[À VALIDER]** |
| F7 | Commentaires TestFlight | Reçus d'Apple (flux entrant) | — | Non (BMSK reçoit, ne communique pas) |

Données de l'app (comptes, transactions, reçus…) : stockées sur l'appareil,
jamais transmises à BMSK ni à un fournisseur de BMSK. Hors champ.

État de F1 au 11 octobre 2026 : 1 inscription, base de 28,7 ko.

## 3. EFVP 1 — Cloudflare (flux F1 et F2)

**Sensibilité : faible.** Courriel, langue, pays approximatif et dates. Aucune
donnée financière, aucune adresse IP conservée. Pour F2, l'adresse IP et le nom
d'une institution financière consultée sont plus révélateurs (relation
bancaire), mais ne sont ni conservés ni journalisés.

**Finalité : limitée et annoncée.** F1 : envoyer l'invitation à la bêta
(promesse affichée : « pas d'infolettre, pas de partage à des tiers »). F2 :
afficher le site et les logos.

**Mesures de protection.**
- *Contractuelles* : accord de traitement des données de Cloudflare (DPA),
  version 6.4 en vigueur depuis le 3 avril 2026, qui fait partie du contrat
  principal, y compris les contrats en libre-service. Cloudflare y agit comme
  sous-traitant (« processor »).
- *Certifications publiées par Cloudflare* : ISO 27001, ISO 27701 (gestion des
  renseignements personnels) et rapports SOC 2 Type II.
- *Mesures de BMSK* (vérifiées dans le code) : minimisation (aucune adresse IP
  stockée ; pays seulement) ; journaux d'invocation du Worker désactivés ;
  export de la liste protégé par un jeton secret ; transmission chiffrée
  (HTTPS) ; conservation limitée à 12 mois après la bêta (politique publiée).

**Régime juridique (États-Unis).** Pas de loi fédérale générale sur la
protection des renseignements personnels ; des autorités peuvent obtenir
l'accès à des données hébergées par des entreprises américaines dans certains
cadres légaux. Cloudflare publie un rapport de transparence et déclare
s'engager à notifier ses clients des demandes légales visant leurs données
**[À VÉRIFIER : formulation actuelle du rapport de transparence]**. Aucune
option d'hébergement de la base D1 au Canada n'est offerte (régions
disponibles : Amérique du Nord, Europe, Asie-Pacifique, Océanie)
**[À VÉRIFIER]**.

**Risques résiduels.** Accès par une autorité étrangère à une liste de
courriels ; incident de sécurité chez Cloudflare. Impact faible, compte tenu de
la nature des renseignements.

**Conclusion.** Protection jugée **adéquate**, au regard de la faible
sensibilité et des mesures en place.

**Actions.**
1. **[À VÉRIFIER]** Confirmer dans le tableau de bord Cloudflare que le DPA
   s'applique au compte (acceptation automatique ou à faire).
2. Purger la liste d'attente 12 mois après la fin de la bêta (procédure à
   noter : requête `DELETE` sur D1, à consigner).
3. Refaire cette évaluation si des données plus sensibles transitent par
   Cloudflare (par exemple la synchronisation bancaire, via le proxy).

## 4. EFVP 2 — Apple, TestFlight (flux F3)

**Constat vérifié (page « TestFlight & Privacy » d'Apple).** Un testeur qui
accepte une invitation **par lien public** n'expose ni son nom ni son courriel
au développeur. Une invitation **par courriel** suppose que le développeur
fournisse à Apple le nom et le courriel du testeur.

**Décision proposée : inviter uniquement par lien public**, envoyé dans le
courriel d'invitation (c'est aussi ce que prévoit le guide marketing, un groupe
TestFlight par canal). BMSK ne communique alors aucun renseignement à Apple
pour la bêta : pas d'EFVP nécessaire pour F3.

**Si une invitation par courriel devenait nécessaire.** Sensibilité faible (nom,
courriel) ; finalité limitée (accès à la bêta) ; mesures : contrat du programme
développeur d'Apple et politique de confidentialité TestFlight
**[À VÉRIFIER : clauses applicables aux données des testeurs]** ; régime
américain (voir EFVP 1). Protection jugée adéquate, sous réserve de cette
vérification. Prévenir la personne avant d'utiliser son courriel ainsi.

## 5. EFVP 3 — ExchangeRate-API (flux F4)

**Sensibilité : faible.** L'app appelle le service directement : celui-ci reçoit
l'adresse IP de l'appareil et la devise de référence (par exemple CAD). Aucun
montant, aucune transaction, aucune identité. Une adresse IP peut toutefois
constituer un renseignement personnel **[À VALIDER]**.

**Finalité.** Mettre à jour les taux de change affichés.

**Mesures de protection.**
- *Contractuelles* : uniquement les conditions d'utilisation générales d'AYR
  Tech (Pty) Ltd, qui incluent sa politique de confidentialité. **Aucun accord
  de traitement des données** n'est proposé. Les conditions ne précisent pas la
  durée de conservation des journaux de requêtes.
- *Lieux* : serveurs en Irlande, en Afrique du Sud et en Allemagne ; recours à
  Amazon AWS, Hetzner et Cloudflare. Droit applicable : Afrique du Sud.

**Régime juridique.** Irlande et Allemagne : RGPD. Afrique du Sud : loi
générale sur la protection des renseignements personnels (POPIA)
**[À VÉRIFIER : portée et application aux journaux techniques]**.

**Risques résiduels.** Faibles en impact, mais **aucune entente écrite** ne
répond à l'exigence de l'article 17, et la conservation des adresses IP est
inconnue.

**Conclusion.** Risque faible, mais **mesure contractuelle insuffisante**.

**Recommandation (technique, simple) : faire passer les taux de change par le
serveur de BMSK**, comme les logos. L'app interrogerait `ando.bmsk.ca`, qui
obtiendrait les taux une fois par jour pour tous les utilisateurs et les
mettrait en cache (la mise en cache est permise par les conditions
d'ExchangeRate-API). ExchangeRate-API ne verrait plus que l'adresse du serveur :
**plus aucun renseignement personnel ne lui serait communiqué**, et cette
évaluation deviendrait sans objet. Effet secondaire utile : l'app appelle
aujourd'hui l'ancienne adresse `api.exchangerate-api.com/v4`, alors que l'offre
gratuite documentée est `open.er-api.com/v6` ; le passage par le serveur
permettrait de changer de point d'accès, voire de fournisseur, sans nouvelle
version de l'app.

**Condition préalable.** Les conditions d'ExchangeRate-API interdisent de
redistribuer leurs données dans un produit ou service offrant un accès
programmatique aux taux, et proposent de confirmer par écrit un cas d'usage
douteux. Un point d'accès sur le serveur de BMSK, réservé à l'app, sert la
finalité propre de l'app ; il pourrait néanmoins être perçu comme une
redistribution. **Avant de l'ouvrir : obtenir leur confirmation écrite**
(support@exchangerate-api.com), ou choisir un fournisseur dont les conditions le
permettent explicitement.

## 6. Hors champ, avec justification

- **Logo.dev (F5)** : la requête provient du serveur de BMSK, construite sans
  aucun en-tête du visiteur (vérifié dans `_landing/src/index.js`) ; seul le nom
  de domaine d'une institution est transmis, sans lien avec une personne.
- **iCloud et achats (F6)** : l'utilisateur synchronise ses données dans son
  propre compte Apple et achète auprès d'Apple ; BMSK ne transmet rien et n'a
  pas accès à ces données. **[À VALIDER]** que cela ne constitue pas une
  communication par BMSK au sens de l'article 17.
- **Commentaires TestFlight (F7)** : flux entrant.

## 7. Plan d'action

| # | Action | Effet | Priorité |
|---|---|---|---|
| A1 | Inviter les testeurs **par lien public uniquement** | Supprime la communication à Apple (F3) | Avant l'envoi des invitations |
| A2 | Taux de change via le serveur de BMSK | Supprime la communication à ExchangeRate-API (F4) | Avant le lancement public |
| A3 | Confirmer le DPA de Cloudflare dans le tableau de bord | Entente écrite (F1, F2) | Rapide |
| A4 | Procédure de purge de la liste d'attente (12 mois après la bêta) | Respect de la conservation annoncée | Avant la fin de la bêta |
| A5 | Politique de confidentialité : préciser les lieux (Afrique du Sud, Europe) et, après A2, retirer ExchangeRate-API | Exactitude | Rapide |
| A6 | Faire valider ce document par un juriste | Sécurité juridique | Avant le lancement public |

## 8. Points à faire valider par un juriste

1. L'adresse IP traitée de façon transitoire (F2, F4) constitue-t-elle une
   « communication » de renseignement personnel au sens de l'article 17 ?
2. La synchronisation iCloud et les achats App Store (F6) sont-ils hors champ
   pour BMSK ?
3. Le DPA de Cloudflare, accepté en ligne, constitue-t-il l'« entente écrite »
   exigée ?
4. Une EFVP distincte est-elle requise pour le système de liste d'attente
   lui-même (projet de prestation électronique de services), en plus de
   celle-ci ?

## 9. Révision

Refaire cette évaluation : à l'ajout ou au changement d'un fournisseur ; si des
renseignements plus sensibles sont concernés (notamment la synchronisation
bancaire avec Plaid ou Flinks, qui exigera sa propre EFVP) ; et au moins une
fois par an.

## Sources (consultées le 11 octobre 2026)

- Article 17 et facteurs à évaluer : Blakes, McCarthy Tétrault, Fasken (analyses
  de la Loi 25) ; guide d'accompagnement de la Commission d'accès à
  l'information : https://www.cai.gouv.qc.ca/uploads/pdfs/CAI_GU_EFVP.pdf
- Cloudflare DPA (v6.4) : https://www.cloudflare.com/cloudflare-customer-dpa/
- Certifications Cloudflare : https://blog.cloudflare.com/updates-to-cloudflare-security-and-privacy-certifications-and-reports/
- Apple, TestFlight & Privacy : https://www.apple.com/legal/privacy/data/en/test-flight/
- ExchangeRate-API, conditions et politique de confidentialité : https://www.exchangerate-api.com/terms
- Infrastructure : `npx wrangler d1 info ando-beta` (région « ENAM », aucune
  juridiction imposée)

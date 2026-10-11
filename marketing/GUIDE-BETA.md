# Fin:Track — guide pas à pas pour faire connaître la bêta

Calibré pour **2 à 5 heures par semaine**, **moins de 500 $**, en **français et en
anglais**, avec Régis comme visage public. Rédigé en octobre 2026.

Statuts des affirmations : **[Vérifié]** source datée · **[Estimé]** · **[Jugement]**
· **[À vérifier]**. Les hypothèses H1 à H7 renvoient à `HYPOTHESES.md`.

## En une page

**Objectif de la bêta** [Jugement] : 100 testeurs actifs en 10 semaines, dont
environ la moitié francophones, et une réponse claire à trois questions :
l'app est-elle utilisée sans synchro bancaire ? Quel angle attire ? Les testeurs
paieraient-ils Pro ?

**Ce que la bêta ne fera pas** [Vérifié] : produire des ventes. Les achats faits
dans TestFlight sont fictifs. Les premiers acheteurs viendront au lancement sur
l'App Store, et ce seront d'abord les testeurs convaincus.

| Semaines | Étape | Temps / semaine |
|---|---|---|
| 0 | Prérequis bloquants | 4–5 h (une fois) |
| 1–2 | Cercle proche : 25 premiers testeurs | 2–3 h |
| 2–6 | Communautés qui acceptent les présentations | 2–3 h |
| 3–8 | Médias et créateurs | 1–2 h |
| 4–10 | Partenaires (nouveaux arrivants, éducation financière) | 1 h |
| continu | Un contenu utile par mois | 1–2 h |
| chaque semaine | Revue des chiffres | 15 min |
| 10+ | Du testeur au premier acheteur | selon le lancement |

**Règle de concentration** [Jugement] : jamais plus de deux canaux actifs en
même temps. Avec 2 à 5 heures, l'éparpillement est le premier risque d'échec.

---

## Étape 0 — Prérequis bloquants (avant tout trafic)

Ne rien publier tant que ces cinq points ne sont pas faits.

### 0.1 Politique de confidentialité (bloquant légal)

La landing collecte des courriels, mais son lien « Confidentialité » ne mène
nulle part [Vérifié]. Publier une politique (FR et EN) qui couvre : données
recueillies (courriel, langue, pays), finalité (invitation à la bêta), lieu
d'hébergement (Cloudflare), durée de conservation, droits d'accès et de
retrait, personne responsable. La même politique servira à la fiche App Store.
→ Je peux en rédiger un premier jet ; une validation juridique reste conseillée.

### 0.2 Bêta TestFlight externe approuvée

Apple impose une revue pour la première version distribuée à des testeurs
externes [Vérifié]. Prévoir quelques jours. Remplir la description de la bêta et
les informations pour la revue.

### 0.3 Un groupe TestFlight par canal

Chaque groupe de testeurs externes peut avoir **son propre lien public**, avec un
plafond de places, et App Store Connect affiche pour chaque lien le nombre de
personnes qui l'ont vu et accepté [Vérifié]. Créer un groupe par canal :

| Groupe | Usage | Plafond de départ |
|---|---|---|
| Proches | Réseau personnel, LinkedIn | 50 |
| Communautés | Forums et groupes | 150 |
| Médias | Lien remis aux créateurs et journalistes | 50 |
| Liste | Inscrits de la landing | 200 |

C'est ainsi que tu sauras d'où viennent les testeurs, sans analytique dans l'app.

### 0.4 Courriel d'invitation et consentement

La landing promet « pas d'infolettre » [Vérifié] : la liste ne sert qu'à
l'invitation. Le courriel d'invitation doit donc :
- contenir le lien du groupe « Liste » ;
- proposer, **sans case précochée**, de recevoir les nouvelles du lancement
  (consentement distinct, conforme à la LCAP) ;
- indiquer clairement l'expéditeur et un moyen de se désabonner.

### 0.5 Trousse de présentation (FR et EN)

- **Une phrase** : « L'app de budget qui calcule correctement tes droits CELI,
  CELIAPP et REER, ton hypothèque et ta marge — en français, sans connecter ta
  banque. »
- **Trois captures** : droits CELIAPP, prêt hypothécaire, tableau de bord. Le
  harnais de captures les produit dans les deux langues.
- **Une vidéo de 30 secondes** enregistrée à l'écran de l'iPhone (gratuit).
- **Un sondage court** (5 questions) pour la fin de la bêta, avec un outil
  gratuit. Mentionner son hébergeur dans la politique de confidentialité.

---

## Étape 1 — Cercle proche (semaines 1–2) · teste H1

Les premiers testeurs viennent presque toujours du réseau proche [Jugement]. Ils
pardonnent les défauts et répondent aux questions : c'est là qu'on corrige les
gros problèmes avant de s'exposer.

1. **Liste de 30 à 40 personnes**, moitié francophones, moitié anglophones,
   qui gèrent activement leur argent (CELIAPP, achat de propriété, tableurs).
2. **Message individuel** (pas de message groupé) : pourquoi tu as construit
   l'app, ce que tu attends d'eux (15 minutes d'essai, un retour), le lien du
   groupe « Proches ».
3. **Une publication LinkedIn**, en français avec la version anglaise en dessous :
   l'histoire personnelle (pourquoi ce besoin), la démonstration d'un cas
   précis (droits CELIAPP), l'appel à testeurs. Sans mention de l'employeur.
4. **Après 7 jours** : relancer une seule fois ceux qui n'ont pas installé.
5. **Corriger les trois problèmes les plus cités** avant l'étape 2.

**Résultat attendu** : 25 installations (H1). Moins de 10 après deux semaines :
retravailler le message avant d'aller plus loin, le problème n'est pas le canal.

---

## Étape 2 — Communautés qui acceptent les présentations (semaines 2–6) · H3, H4, H6

**Ce qui a changé par rapport au plan de septembre** : r/PersonalFinanceCanada
interdit les publications autopromotionnelles, selon un guide externe de ce forum
[À vérifier sur place]. Le post de lancement prévu là-bas est abandonné.
Participer à ses discussions reste utile, sans jamais y présenter l'app.

### Méthode pour chaque communauté

1. Lire les règles **avant** de publier ; chercher un fil dédié aux présentations.
2. En cas de doute, écrire aux modérateurs et attendre leur accord.
3. Participer d'abord sincèrement quelques jours (répondre à des questions).
4. Publier une présentation honnête : ce que l'app fait, ce qui manque (pas de
   synchro bancaire), ce qui est gratuit, le lien du groupe « Communautés ».
5. Répondre à tous les commentaires dans les 24 heures.
6. Noter le résultat dans `HYPOTHESES.md` (inscriptions en 72 h).

**Une communauté par semaine au maximum.**

**Tester l'angle du message (H3)** : alterner deux accroches d'une communauté à
l'autre, à exposition comparable — l'une centrée sur le CELIAPP (« tes droits
CELIAPP calculés au dollar près »), l'autre sur le budget canadien en général.
Comparer les inscriptions obtenues. Deux essais par angle avant de conclure.

### Candidates à évaluer

| Communauté | Langue | Ce qu'on sait | Statut |
|---|---|---|---|
| r/BuyCanadian | EN | Fil mensuel dédié à l'autopromotion des entreprises canadiennes (observé en 2025) | [À vérifier : toujours actif] |
| r/CanadaPersonalFinance | EN | Environ 31 000 membres ; se présente comme une alternative moins restrictive à r/PersonalFinanceCanada | [À vérifier : règles] |
| Forums Apple Developer, section TestFlight Public Links | EN | Section prévue par Apple pour partager des bêtas | [Vérifié] public de développeurs, retours techniques surtout |
| Groupes Facebook québécois de finances personnelles | FR | À identifier ; règles variables | [À vérifier] |
| Communautés de nouveaux arrivants au Québec | FR | Voir l'étape 4 | [À vérifier] |

Les nombres de membres viennent d'outils tiers et changent vite : les relire sur
place avant de les citer.

---

## Étape 3 — Médias et créateurs (semaines 3–8) · teste H5

Un seul article ou une seule mention peut valoir des mois de forums [Jugement].
Le taux de réponse est faible : viser la qualité, pas le volume.

### Cibles de départ

| Cible | Langue | Pourquoi | Source |
|---|---|---|---|
| François Charron | FR | Chroniqueur techno grand public ; a déjà présenté des outils de budget québécois | [Vérifié] |
| Narcity Québec | FR | Publie très souvent sur les finances personnelles des Québécois (prestations, CELI) | [Vérifié] |
| Blogues canadiens qui publient des comparatifs d'apps de budget | EN | Ils mettent leurs listes à jour chaque année | [Vérifié] ; noms précis à choisir |

### Méthode

1. Lire trois de leurs publications récentes ; trouver l'angle qui les concerne.
2. Message court et personnel : un fait précis et vérifiable (par exemple, le
   calcul des droits CELIAPP), une capture, le lien du groupe « Médias », une
   offre d'accès Pro gratuit au lancement.
3. Aucune comparaison nommée avec un concurrent (Loi sur la concurrence).
4. Une relance après 10 jours, puis on passe à la suite.
5. **Dix sollicitations, puis bilan** (H5).

---

## Étape 4 — Partenaires (semaines 4–10)

Les organismes qui aident les nouveaux arrivants et ceux qui font de
l'éducation financière ont un public qui doit justement comprendre CELI, REER
et CELIAPP, souvent en français [Jugement].

- **Immigrant Québec** publie des contenus sur la gestion des finances à
  l'arrivée (cartes, REER, CELI) [Vérifié].
- **CODE F** (santé financière des communautés ethnoculturelles, Québec)
  organise ateliers et conférences [Vérifié].

**Approche** : proposer l'app comme outil gratuit (palier Courant) pour leurs
ateliers, pas comme publicité. Demander ce qui aiderait leur public. C'est une
relation à construire sur plusieurs mois : un message par mois au maximum.

---

## Étape 5 — Un contenu utile par mois (continu)

Les concurrents publient des comparatifs « meilleures apps de budget au Canada »
mis à jour chaque année [Vérifié]. Plutôt que de les imiter, répondre à des
questions précises que les gens cherchent, là où l'app est réellement utile
[Jugement] :

- « Comment calculer ses droits de cotisation au CELIAPP »
- « Pourquoi le taux de ton hypothèque n'est pas celui que tu crois
  (capitalisation semestrielle) »
- « Combien coûte vraiment ta marge de crédit chaque jour »

Un article par mois, en français et en anglais, publié sur la landing. Il sert
trois fois : référencement, matière pour les communautés, argument pour les
médias. Chaque chiffre cité doit être vérifiable (sources de l'ARC).

---

## Étape 6 — Revue hebdomadaire (15 minutes)

Chaque semaine, au même moment :

1. **Chiffres** : inscriptions à la liste (par langue), installations par groupe
   TestFlight, plantages, retours reçus.
2. **Expériences** : celles qui arrivent à échéance → noter le résultat dans
   `HYPOTHESES.md`, sans déplacer les seuils.
3. **Décision** : continuer, ajuster ou arrêter chaque canal actif.
4. **Une seule priorité** pour la semaine suivante.

---

## Étape 7 — Du testeur au premier acheteur (semaine 10 et après)

1. **Sondage de fin de bêta** (H2, H7) : usage réel, ce qui manque, prix jugé
   acceptable pour Pro.
2. **Décider le prix de lancement** avec ces réponses. Rappel : le prix de Pro
   est encore provisoire (24,99 $ sur la landing, 28,99 $ dans le fichier de
   test).
3. **Offre aux testeurs** (par exemple un prix de lancement limité dans le temps),
   seulement à ceux qui ont consenti à recevoir les nouvelles.
4. **Le jour du lancement** : courriel aux consentants, publication LinkedIn,
   message aux médias qui ont répondu, demande d'avis sur l'App Store aux
   testeurs satisfaits.

---

## Budget (moins de 500 $)

| Poste | Montant | Quand |
|---|---|---|
| Outils (sondage, courriels) | 0 $ en version gratuite | Étape 0 |
| Validation juridique de la politique de confidentialité | à chiffrer | Étape 0, si possible |
| Réserve pour une expérience payante | ~300 $ | **Seulement** après avoir mesuré la conversion (H2, H7) |

**Pas de publicité payante avant d'avoir des chiffres** [Jugement] : sans taux
d'activation ni de conversion, on ne saurait pas si l'argent a servi.

---

## Contre-examen : pourquoi ce plan pourrait échouer

Exercice : on suppose que la bêta a échoué dans trois mois, et on cherche
pourquoi. Chaque risque a une parade.

| # | Risque | Gravité | Parade |
|---|---|---|---|
| R1 | **Le nom.** En septembre, « FinTrack » a été jugé trop proche de **FINTRAC**, l'organisme fédéral de renseignement financier. Le changement a été reporté. Changer de nom après avoir bâti une notoriété coûte cher et sème la confusion. | Élevée | **Trancher le nom avant l'étape 2.** Les étapes 0 et 1 (cercle proche) peuvent se faire avant. |
| R2 | **Une erreur de calcul découverte en public.** Le message promet des calculs « corrects » ; or il n'existe aucun test automatisé des moteurs de calcul dans le dépôt [Vérifié]. Une erreur relevée par un média ruinerait la crédibilité, et la Loi sur la concurrence exige de pouvoir prouver ses affirmations. | Élevée | Tester les moteurs (CELIAPP d'abord) contre des cas de référence de l'ARC **avant l'étape 3**. |
| R3 | **L'absence de synchro bancaire décourage.** Les comparatifs 2026 placent la connexion aux banques parmi les premiers critères [Vérifié]. | Moyenne | Viser explicitement ceux qui ne veulent pas connecter leur banque ; le dire dès la première phrase ; mesurer (H2). |
| R4 | **Le temps.** Deux langues et plusieurs canaux dépassent vite 5 heures. | Moyenne | Deux canaux actifs au maximum ; écrire en français puis adapter ; répartir l'effort selon H6. |
| R5 | **La concurrence occupe déjà l'angle.** Waypoint Budget affirme suivre les droits CELI et REER ; Pocket Clear joue la confidentialité sans connexion bancaire [Vérifié]. | Moyenne | Démontrer les quatre cas précis (CELIAPP, hypothèque, marge, français) ; vérifier ce que font réellement ces apps avant d'en parler. |
| R6 | **Les intentions d'achat surestiment.** Dire « je paierais » ne coûte rien ; les sondages surestiment la conversion [Jugement]. | Moyenne | Lire H7 avec prudence ; le vrai test est le lancement. |
| R7 | **Le profil LinkedIn affiche l'employeur.** Même sans le citer, l'association peut se faire. | Faible à moyenne | Vérifier la politique interne sur les activités externes ; ne jamais évoquer la banque ni Flinks. |
| R8 | **Mesure biaisée.** Seuls les testeurs satisfaits répondent aux sondages. | Faible | Croiser avec les statistiques TestFlight par groupe [À vérifier : ce qu'elles montrent exactement par testeur]. |

### Une occasion à saisir

La saison des REER (janvier à début mars) concentre l'attention sur les comptes
enregistrés [Jugement]. Une bêta d'octobre à décembre, suivie d'un lancement
en janvier, tomberait au bon moment. C'est un argument de plus pour trancher
vite le nom (R1) et les tests des calculs (R2).

---

## Ce que je ne sais pas

- Les règles actuelles de chaque communauté citée : à lire sur place.
- Les taux de conversion réels d'une app de finances canadienne indépendante :
  personne ne les connaît avant la bêta ; c'est son rôle de les mesurer.
- Ce que font exactement Waypoint Budget et Pocket Clear sur le CELIAPP,
  l'hypothèque et les marges : à vérifier en installant leurs apps.
- Si les objectifs (100 testeurs actifs en 10 semaines) sont atteignables :
  ce sont des cibles, pas des prévisions.

---

## Sources (consultées en octobre 2026)

- Apple, TestFlight : https://developer.apple.com/testflight/
- Apple, inviter des testeurs externes : https://developer.apple.com/help/app-store-connect/test-a-beta-version/invite-external-testers
- Guide de r/PersonalFinanceCanada (règles, autopromotion) : https://wealthawesome.com/reddit-personal-finance-canada-review/
- r/BuyCanadian, fil mensuel d'autopromotion (2025) : https://redlib.hackliberty.org/r/BuyCanadian
- r/CanadaPersonalFinance (taille, positionnement) : https://gummysearch.com/r/CanadaPersonalFinance/
- Waypoint Budget, comparatif 2026 : https://waypointbudget.com/blog/best-budgeting-apps-canada-2026
- Pocket Clear, comparatif 2026 : https://pocketclear.app/blog/expense-tracker-canada.html
- Richify, comparatif 2026 : https://www.richify.ai/ca/best-budgeting-apps-canada
- François Charron, outils de budget : https://francoischarron.com/gadgets-techno/web-applications/decouvrez-ma-selection-doutils-pour-controler-ses-finances-et-bien-gerer-son-budget/Mzufjw8wtm/
- Narcity Québec, finances personnelles : https://www.narcity.com/fr/montreal/cours-finances-personnelles-mcgill-gratuit-2026
- Immigrant Québec, gérer ses finances : https://immigrantquebec.com/fr/?p=5438
- CODE F : https://ca.linkedin.com/company/codef-org

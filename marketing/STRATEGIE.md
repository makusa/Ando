# Fin:Track — stratégie marketing (source de vérité)

Ce fichier est au marketing ce que `CLAUDE.md` est au code : l'état actuel des
décisions. Il se met à jour quand une décision change ou qu'une expérience
apporte une preuve. Les idées non prouvées vivent dans `HYPOTHESES.md`.

Chaque affirmation porte un statut :
**[Vérifié]** (source datée), **[Estimé]** (calcul ou analogie), **[Jugement]**
(choix stratégique argumenté), **[À vérifier]**.

## Situation (octobre 2026)

- Bêta TestFlight en préparation, **sans synchronisation bancaire**.
  Paliers proposés : Courant (gratuit) et Pro (achat unique). Max est désactivé.
- Les achats dans TestFlight sont fictifs : la bêta produit des testeurs et des
  signaux, **pas de revenus**. Les premiers acheteurs viendront au lancement sur
  l'App Store. [Vérifié — fonctionnement de TestFlight]
- Landing bilingue en ligne (`fintrack.bmsk.ca`) avec liste d'attente.
- L'app ne contient **aucune analytique** (choix de confidentialité). Les mesures
  disponibles : inscriptions à la liste, statistiques TestFlight (invitations,
  installations, plantages), retours des testeurs.

## Contraintes de Régis

| Contrainte | Valeur |
|---|---|
| Temps | 2 à 5 heures par semaine |
| Budget de la bêta | moins de 500 $ |
| Visibilité | Peut apparaître publiquement comme créateur |
| Cibles | Francophones et anglophones en même temps |

**Règle de prudence** [Jugement] : ne jamais mentionner l'employeur de Régis
dans la communication de Fin:Track. Son employeur possède Flinks, fournisseur
bancaire envisagé ; toute association apparente créerait un risque de conflit
d'intérêts et d'image. Vérifier la politique interne sur les activités externes.

## Positionnement

**Proposition** [Jugement, issue de l'analyse concurrentielle de septembre 2026] :
l'app de finances personnelles qui fait les calculs canadiens correctement —
droits CELI, CELIAPP et REER, hypothèque à capitalisation semestrielle, intérêt
quotidien des marges de crédit — en français comme en anglais, avec des données
qui restent sur l'appareil.

**Ce qui a changé depuis septembre** [Vérifié, octobre 2026] :
- Le terrain des comptes enregistrés n'est plus vide. Waypoint Budget affirme
  suivre les droits CELI et REER ; Pocket Clear met en avant la saisie manuelle
  et la confidentialité ; Richify publie des comparatifs d'applications
  canadiennes.
- L'argument « Mint a fermé » (début 2024) est repris par tous les concurrents :
  il est saturé et vieillit.

**Conséquence** [Jugement] : la différence doit se **démontrer** par des cas
précis que les autres ne traitent pas ou traitent mal, pas s'affirmer :
1. CELIAPP (le plus récent des comptes, le moins bien couvert) ;
2. capitalisation semestrielle des prêts hypothécaires ;
3. intérêt quotidien des marges de crédit ;
4. français natif, pas traduit.

Ce que font exactement les concurrents sur ces quatre points est **[À vérifier]**
en installant leurs apps, avant toute comparaison publique.

## Cibles de la bêta

| Segment | Pourquoi | Langue |
|---|---|---|
| Détenteurs de CELIAPP (acheteurs d'une première propriété) | Besoin précis, peu couvert | FR + EN |
| Personnes qui refusent de connecter leur banque | La bêta n'a pas de synchro : c'est un atout pour eux, pas un manque | FR + EN |
| Nouveaux arrivants au Québec | Doivent apprendre CELI / REER / CELIAPP ; français utile | FR d'abord |
| Utilisateurs de tableurs | Saisie manuelle déjà acceptée | FR + EN |

**Hors cible pour la bêta** : les personnes qui veulent avant tout l'importation
automatique des transactions. Elles seront déçues ; mieux vaut le dire.

## Conformité (à respecter dans toute communication)

- **Loi sur la concurrence** : affirmations vraies et démontrables ; test de
  l'impression générale. Pas de comparaison nommée avec un concurrent sans
  vérification documentée.
- **LCAP (CASL)** : courriels commerciaux seulement avec consentement, expéditeur
  identifié, désabonnement fonctionnel.
- **Loi 25** : une politique de confidentialité doit être publiée quand on
  recueille des renseignements personnels en ligne. **[Vérifié, octobre 2026] la
  landing collecte des courriels mais son lien « Confidentialité » ne mène nulle
  part (`href="#"`).** Bloquant : à corriger avant d'amener du trafic.
- **Promesse de la landing** : « pas d'infolettre, pas de partage à des tiers ».
  La liste actuelle ne sert **qu'à envoyer l'invitation TestFlight**. Toute
  autre communication (nouvelles, lancement, offre) exige un consentement
  distinct, demandé par exemple dans le courriel d'invitation.
- **Loi 96** : tout en français, au moins aussi accessible que l'anglais.
- **Plateformes** : respecter les règles de chaque communauté (voir le guide).

## Décisions ouvertes (à trancher)

| Décision | Pourquoi c'est urgent | Échéance |
|---|---|---|
| **Le nom de l'app** | « FinTrack » jugé trop proche de FINTRAC en septembre 2026 ; changer après avoir bâti une notoriété coûte cher | Avant l'étape 2 du guide |
| **Tests des moteurs de calcul** | Le message promet des calculs corrects ; aucun test automatisé dans le dépôt ; exigence de preuve (Loi sur la concurrence) | Avant l'étape 3 du guide |
| **Prix de lancement de Pro** | 24,99 $ (landing) contre 28,99 $ (fichier de test) | À la fin de la bêta, avec le sondage |

## Journal des décisions

| Date | Décision | Statut |
|---|---|---|
| 2026-09 | Positionnement sur la précision canadienne plutôt que sur l'IA | [Jugement] |
| 2026-10 | Bêta sans synchro bancaire ; Max désactivé | Décidé |
| 2026-10 | Communication publique sous le nom de Régis, sans mention de l'employeur | Décidé |
| 2026-10 | Bêta francophone et anglophone en même temps | Décidé |
| 2026-10 | Abandon du post de lancement sur r/PersonalFinanceCanada (autopromotion interdite selon un guide externe) | [À vérifier sur place] |
| 2026-10 | Abandon de l'argument « Mint a fermé » | [Jugement] |

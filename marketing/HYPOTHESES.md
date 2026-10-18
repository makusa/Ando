# Ando — registre des hypothèses et des expériences

Toute idée marketing entre ici **avant** d'être appliquée. Elle en sort
confirmée, infirmée ou abandonnée, avec la preuve.

Règles :
1. Une hypothèse se formule pour pouvoir être fausse : « si… alors… mesuré par… ».
2. Le **seuil d'abandon est fixé avant** de lancer l'expérience. On ne le
   déplace pas après avoir vu le résultat.
3. On teste d'abord l'expérience la moins chère qui peut infirmer l'hypothèse.
4. Le résultat est noté même quand il déçoit. Surtout quand il déçoit.
5. Une hypothèse confirmée met à jour `STRATEGIE.md`.

Statuts : `À tester` · `En cours` · `Confirmée` · `Infirmée` · `Abandonnée`

## Hypothèses ouvertes

Les seuils ci-dessous sont des **estimations de départ** [Estimé], faute de
données propres à Ando. On peut les ajuster avant de lancer une expérience,
jamais après en avoir vu le résultat.

| # | Hypothèse | Mesure | Seuil de réussite | Seuil d'abandon | Statut |
|---|---|---|---|---|---|
| H1 | Le cercle proche (réseau personnel, LinkedIn) fournit les 25 premiers testeurs en 2 semaines | Installations TestFlight via le lien public du groupe « Proches » | ≥ 25 installations | < 10 après 2 semaines | À tester |
| H2 | L'absence de synchro bancaire n'empêche pas l'usage, pour la cible visée | Testeurs encore actifs à 2 semaines (sondage) | ≥ 40 % actifs | < 20 % actifs | À tester |
| H3 | L'angle CELIAPP attire plus que l'angle « budget canadien » général | Taux de clic ou d'inscription par message, à exposition comparable | Écart ≥ 2× | Pas d'écart après 2 essais | À tester |
| H4 | Une communauté qui accepte l'autopromotion apporte au moins 20 inscriptions par publication | Inscriptions à la liste dans les 72 h | ≥ 20 | < 5 | À tester |
| H5 | Un média ou créateur francophone accepte d'essayer l'app sur 10 sollicitations personnalisées | Réponses positives | ≥ 1 | 0 sur 10 | À tester |
| H6 | Les testeurs francophones et anglophones se recrutent au même rythme | Langue des inscriptions (champ `langue` de la base) | Écart < 2× | — (sert à répartir l'effort) | À tester |
| H7 | Les testeurs seraient prêts à payer Pro au prix prévu | Réponse « oui, à ce prix » au sondage de fin de bêta | ≥ 30 % des répondants actifs | < 10 % | À tester |

## Journal des expériences

Une entrée par expérience terminée.

### Modèle

```
### E-AAAA-MM-JJ — Titre
Hypothèse : H#
Action : ce qui a été fait, où, quand, avec quel message
Coût : temps et argent
Résultat : chiffres bruts, avec leur source
Lecture : confirmée / infirmée / non concluante, et pourquoi
Décision : continuer, ajuster, arrêter
Ce que je referais autrement :
```

# Outils de qualité de Fin:Track — mode d'emploi

Trois outils automatisent les vérifications qui reposaient jusqu'ici sur la
discipline (la tienne ou celle de l'IA) :

| Outil | Rôle | Quand s'en servir |
|---|---|---|
| `scripts/check-l10n.py` | Contrôle des traductions | Après toute modification de texte ; automatique avant chaque commit |
| `scripts/verify.sh` | Builds Debug et Release à 0/0, App Group, traductions | Avant de committer du code de l'app |
| Garde-fou de commit | Refuse un commit non vérifié ou contenant des fichiers interdits | Automatique, à chaque `git commit` |

Toutes les commandes se lancent depuis la racine du dépôt :

```bash
cd /Users/regis/Documents/GitHub/FinTrack
```

---

## 1. Contrôle des traductions

```bash
python3 scripts/check-l10n.py            # rapport
python3 scripts/check-l10n.py --verbose  # + liste des clés inutilisées
```

Durée : environ une seconde.

### Ce qu'il bloque (erreurs)

| Erreur | Pourquoi c'est grave |
|---|---|
| Clé en double dans `LocalizedStrings.swift` | L'app **plante au lancement** (dictionnaire Swift avec clé dupliquée) |
| Langue manquante ou vide (fr, en, es, pt) | Texte vide ou repli inattendu à l'écran |
| Marqueurs de format différents (`%@` en français, `%d` en anglais…) | Texte faux, voire plantage avec `lang.f(…)` |
| Clé appelée dans le code mais absente du dictionnaire | L'utilisateur voit la clé brute (ex. « settings.export ») |
| Fichiers `.strings` des widgets incomplets | Libellé du widget non traduit dans une langue |

### Ce qu'il signale sans bloquer (information)

Les **clés définies mais introuvables dans le code**. Souvent des restes à
supprimer, mais certaines sont construites dynamiquement (ex. `currency.\(code)`) :
vérifier avec `--verbose` avant d'en supprimer une.

### Lire le résultat

```
Traductions : 1091 clés × 4 langues ; 924 clés appelées dans le code ; …
✓ Aucune erreur de traduction
```

En cas d'erreur, chaque ligne indique la clé et l'endroit (fichier:ligne). Le code
de sortie vaut 1, ce qui bloque aussi le commit.

### Ce qu'il a trouvé dès sa première exécution

- Le paywall de l'export CSV affichait la clé brute **« settings.export »** comme
  titre (la vraie clé est `settings.exportCSV`). Visible en gratuit, donc dans la
  bêta.
- Une erreur de connexion Plaid aurait affiché **« plaid.connected.error »** :
  la clé n'existait pas.

Les deux sont corrigés.

### Limite à connaître

Le script ne détecte pas un texte **codé en dur** en français dans une vue
(ex. `Text("Bonjour")`). Cette règle reste à appliquer en relecture.

---

## 2. Vérification complète avant commit

```bash
scripts/verify.sh           # complet : Debug ET Release (environ 2 minutes)
scripts/verify.sh --quick   # Debug seulement (environ 30 secondes)
scripts/verify.sh --help
```

### Ce qu'il enchaîne

1. **Traductions** (`check-l10n.py`).
2. **App Group** : présent une fois dans chacun des deux fichiers `.entitlements`
   (XcodeGen peut l'effacer).
   **Puis la liste des domaines de logos** du Worker (`_landing/src/domaines-logos.js`) :
   elle doit correspondre à l'annuaire de l'app. Si elle est périmée :
   `python3 scripts/gen-logo-allowlist.py`, puis redéployer le Worker.
3. **Build Debug**, puis **build Release** : 0 erreur et 0 avertissement exigés.
   Le bruit `appintentsmetadataprocessor` est ignoré ; chaque avertissement n'est
   compté qu'une fois.
4. **Stabilité** : si un fichier a changé pendant la vérification, elle est annulée.

Il s'arrête à la première étape en échec et affiche la cause (fichier et ligne pour
un avertissement ou une erreur de compilation), puis le chemin du journal complet.

### Exemple d'échec

```
3. Builds (journaux dans /tmp/fintrack-verify)
   Debug   … OK | erreurs : 0 | avertissements : 1 | 11 s
     ⚠ …/TransactionsView.swift:415:40: warning: variable 'x' was never mutated…

✗ ÉCHEC : build Debug non conforme (0 erreur / 0 avertissement exigés)
```

### Complet ou rapide ?

| | `--quick` | complet |
|---|---|---|
| Builds | Debug | Debug + Release |
| Durée indicative | ~30 s | ~2 min |
| Autorise le commit | **non** | **oui** |
| Usage | Pendant le travail, pour vérifier vite | Juste avant de committer |

La vérification Release n'est pas une formalité : en octobre 2026, un
avertissement n'apparaissait **qu'en Release** (le mode démo), donc dans chaque
archive TestFlight.

### Ce que « commit autorisé » veut dire

Une vérification complète réussie enregistre une **empreinte** du code (hors
dépôt, dans `.git/fintrack-verification`). Le garde-fou de commit compare
cette empreinte au code actuel. La moindre modification d'un fichier de l'app
après la vérification l'invalide : il faut relancer `scripts/verify.sh`.

Revenir exactement à l'état vérifié (par exemple en annulant un essai) rend la
vérification de nouveau valable, puisque le contenu est identique.

---

## 3. Garde-fou de commit

Il s'exécute **automatiquement** à chaque `git commit` lancé en ligne de commande,
par toi dans le Terminal ou par l'IA.

**Attention avec le menu Source Control d'Xcode** : son intégration Git
n'exécute généralement pas ces garde-fous. Je ne peux pas le garantir pour ta
version d'Xcode ; pour le vérifier, indexer un `.DS_Store` et tenter un commit
depuis Xcode : s'il passe, le garde-fou n'est pas appliqué. Par prudence,
committer depuis le Terminal ou par l'IA.

### Installation (une fois par clone du dépôt)

```bash
scripts/install-hooks.sh            # active
scripts/install-hooks.sh --remove   # désactive
```

Il est déjà activé sur ton Mac. Le réglage est local à chaque clone : sur une autre
machine, relancer `scripts/install-hooks.sh` après le `git clone`.

### Ce qu'il refuse

1. **Les fichiers interdits** indexés : `.DS_Store`, `UserInterfaceState.xcuserstate`,
   `xcuserdata/`, `xcdebugger/`, schemes partagés (`*.xcscheme`). Une
   **suppression** de ces fichiers reste permise (pour les retirer du dépôt).
2. **Un commit qui touche au code de l'app** (dossiers `FinTrack/`,
   `FinTrackWidget/`, `FinTrackUITests/`, `project.yml`, `project.pbxproj`) si la
   dernière vérification complète ne correspond plus au code actuel.

Les commits qui ne touchent pas l'app (landing, documentation, scripts) ne sont pas
freinés.

### Exemples de refus

```
✗ Commit refusé par le garde-fou Fin:Track
  Fichiers qui ne doivent pas être committés :
    - .DS_Store
  Pour les retirer de l'index : git restore --staged <fichier>
```

```
✗ Commit refusé par le garde-fou Fin:Track
  Le code de l'app a changé depuis la dernière vérification complète
  (réussie le 2026-10-10 à 18:42).
  Lancer : scripts/verify.sh
```

### Contourner (exceptionnel)

```bash
git commit --no-verify -m "…"
```

À réserver à une vraie urgence, en sachant pourquoi. L'IA ne doit jamais le faire
sans ton accord explicite.

### Limite à connaître

L'empreinte porte sur les fichiers **tels qu'ils sont sur le disque**. Si tu
n'indexes qu'une partie de tes modifications, la vérification a porté sur
l'ensemble, pas sur la partie committée seule. En pratique : vérifier, puis
committer tout ce qui a été vérifié.

---

## 4. Au quotidien

### Quand tu travailles avec l'IA

Rien de nouveau à faire : tu demandes une modification, puis « commit » quand tu
es satisfait. L'IA doit lancer `scripts/verify.sh` avant de committer ; si elle
l'oublie, le garde-fou refuse le commit et le lui rappelle. Elle n'a pas le droit
de le contourner sans ton accord.

### Quand tu travailles seul

```bash
# pendant le travail, pour vérifier vite
scripts/verify.sh --quick

# avant de committer
scripts/verify.sh
git add <fichiers>
git commit -m "…"
```

### Après avoir modifié des textes

```bash
python3 scripts/check-l10n.py
```

### Faire le ménage dans les traductions (de temps en temps)

```bash
python3 scripts/check-l10n.py --verbose
```

Les clés listées comme introuvables sont des candidates à la suppression ; vérifier
qu'elles ne sont pas construites dynamiquement avant de les retirer.

---

## 5. Dépannage

| Symptôme | Cause probable | Solution |
|---|---|---|
| « aucune vérification complète n'a été faite » | Premier commit après installation, ou fichier de validation effacé | `scripts/verify.sh` |
| « le code de l'app a changé depuis la dernière vérification » | Un fichier de l'app a été modifié après la vérification | `scripts/verify.sh` |
| `verify.sh` échoue au build sans erreur lisible | Problème hors compilation (signature, scheme…) | Lire les dernières lignes affichées, puis le journal indiqué |
| « App Group absent » | `xcodegen generate` a régénéré les entitlements sans l'App Group | Vérifier `project.yml`, relancer `xcodegen generate` |
| `permission denied` sur un script | Bit d'exécution perdu | `scripts/install-hooks.sh` (il le remet) |
| `.DS_Store` apparaît toujours comme modifié | Un `.DS_Store` est suivi par Git malgré le `.gitignore` | Voir ci-dessous |

### Fichiers suivis par erreur

Un `.DS_Store` (et l'état d'interface d'Xcode, `UserInterfaceState.xcuserstate`)
sont suivis par Git, malgré le `.gitignore` pour le premier. C'est pourquoi ils
apparaissent sans cesse comme modifiés. Pour les retirer du dépôt sans les
supprimer de ton disque, sur demande explicite :

```bash
git rm --cached .DS_Store
git rm --cached FinTrack.xcodeproj/project.xcworkspace/xcuserdata/regis.xcuserdatad/UserInterfaceState.xcuserstate
```

puis ajouter `xcuserdata/` au `.gitignore`. Le garde-fou laisse passer ces
suppressions.

---

## Fichiers des outils

| Fichier | Contenu |
|---|---|
| `scripts/check-l10n.py` | Contrôle des traductions |
| `scripts/verify.sh` | Vérification complète ou rapide |
| `scripts/lib-empreinte.sh` | Calcul de l'empreinte du code (partagé) |
| `scripts/git-hooks/pre-commit` | Garde-fou de commit |
| `scripts/install-hooks.sh` | Activation / désactivation du garde-fou |
| `.git/fintrack-verification` | Dernière vérification complète réussie (hors dépôt) |

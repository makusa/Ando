#!/usr/bin/env python3
"""
Contrôle des traductions de Ando.

    python3 scripts/check-l10n.py            # rapport, code de sortie 1 si erreur
    python3 scripts/check-l10n.py --verbose  # liste aussi les clés inutilisées

Erreurs (bloquantes) :
  - clé en double dans LocalizedStrings.swift (plantage au lancement de l'app)
  - langue manquante ou vide (fr, en, es, pt obligatoires)
  - marqueurs de format différents d'une langue à l'autre (%@, %d…)
  - clé appelée dans le code mais absente du dictionnaire
  - fichiers .strings des widgets qui n'ont pas les mêmes clés

Information (non bloquante) :
  - clés définies mais introuvables dans le code (peut-être construites
    dynamiquement : à vérifier avant de supprimer)
"""

import pathlib
import re
import sys

RACINE = pathlib.Path(__file__).resolve().parent.parent
DICO = RACINE / "Ando/Localization/LocalizedStrings.swift"
SOURCES = [RACINE / "Ando", RACINE / "AndoWidget"]
LANGUES = ("fr", "en", "es", "pt")

LIGNE_CLE = re.compile(r'^\s*"([^"]+)"\s*:\s*\[(.*)\]\s*,?\s*(//.*)?$')
PAIRE = re.compile(r'"(fr|en|es|pt)"\s*:\s*"((?:[^"\\]|\\.)*)"')
# Marqueur printf : %@, %d, %1$@, %.2f, %ld… (pas d'espace comme drapeau, pour ne
# pas confondre « 5 % de » avec un marqueur).
FORMAT = re.compile(r"%(?:\d+\$)?[-+0#]*\d*(?:\.\d+)?(?:ll|l|h)?([@dfsiuxX])")
LITTERAL = re.compile(r'"((?:[^"\\]|\\.)*)"')
# Contextes d'appel dont les chaînes littérales sont des clés de traduction.
APPELS = re.compile(r'(?:\blang\[|LanguageManager\.shared\[|\blang\.f\(|'
                    r'LocalizedStrings\.resolve\(key:)')
FERMANT = {"[": "]", "(": ")"}


def lire_dictionnaire(erreurs):
    """Retourne {clé: {langue: texte}} et signale doublons / langues manquantes."""
    cles = {}
    for num, ligne in enumerate(DICO.read_text(encoding="utf-8").splitlines(), 1):
        m = LIGNE_CLE.match(ligne)
        if not m:
            continue
        cle, interieur = m.group(1), m.group(2)
        traductions = dict(PAIRE.findall(interieur))
        if cle in cles:
            erreurs.append(f"Clé en double (plantage au lancement) : « {cle} », ligne {num}")
        manquantes = [l for l in LANGUES if not traductions.get(l, "").strip()]
        if manquantes:
            erreurs.append(f"Langue manquante ou vide pour « {cle} » (ligne {num}) : {', '.join(manquantes)}")
        formats = {l: sorted(FORMAT.findall(t)) for l, t in traductions.items()}
        if len({tuple(v) for v in formats.values()}) > 1:
            detail = ", ".join(f"{l}={''.join(v) or '∅'}" for l, v in sorted(formats.items()))
            erreurs.append(f"Marqueurs de format différents pour « {cle} » (ligne {num}) : {detail}")
        cles[cle] = traductions
    return cles


def fichiers_swift():
    for dossier in SOURCES:
        for f in sorted(dossier.rglob("*.swift")):
            if f != DICO:
                yield f


def expression_appel(ligne, debut):
    """Texte entre l'ouverture d'un appel et sa fermeture, sur la même ligne."""
    ouvrant = ligne[debut - 1] if ligne[debut - 1] in FERMANT else "("
    profondeur, i = 1, debut
    while i < len(ligne) and profondeur:
        c = ligne[i]
        if c == ouvrant:
            profondeur += 1
        elif c == FERMANT[ouvrant]:
            profondeur -= 1
        i += 1
    return ligne[debut:i]


def analyser_code():
    """Clés appelées (avec emplacement), littéraux présents, préfixes dynamiques."""
    appelees, litteraux, prefixes = {}, set(), set()
    for f in fichiers_swift():
        rel = f.relative_to(RACINE)
        for num, ligne in enumerate(f.read_text(encoding="utf-8").splitlines(), 1):
            for lit in LITTERAL.findall(ligne):
                if "\\(" in lit:
                    prefixes.add(lit.split("\\(")[0])
                else:
                    litteraux.add(lit)
            for m in APPELS.finditer(ligne):
                for lit in LITTERAL.findall(expression_appel(ligne, m.end())):
                    if lit and "\\(" not in lit and " " not in lit:
                        appelees.setdefault(lit, f"{rel}:{num}")
    return appelees, litteraux, {p for p in prefixes if p}


def cles_widgets(erreurs):
    jeux = {}
    for f in sorted((RACINE / "AndoWidget").glob("*.lproj/Localizable.strings")):
        jeux[f.parent.name] = set(re.findall(r'^\s*"([^"]+)"\s*=', f.read_text(encoding="utf-8"), re.M))
    if jeux:
        reference = set.union(*jeux.values())
        for nom, cles in jeux.items():
            manque = sorted(reference - cles)
            if manque:
                erreurs.append(f"Widget {nom} : clés absentes : {', '.join(manque)}")
    return jeux


def main():
    verbeux = "--verbose" in sys.argv
    erreurs = []
    cles = lire_dictionnaire(erreurs)
    appelees, litteraux, prefixes = analyser_code()
    widgets = cles_widgets(erreurs)

    for cle, lieu in sorted(appelees.items()):
        if cle not in cles and not any(cle.startswith(p) for p in prefixes if p.endswith(".")):
            erreurs.append(f"Clé appelée mais absente du dictionnaire : « {cle} » ({lieu})")

    inutilisees = sorted(c for c in cles
                         if c not in litteraux and not any(c.startswith(p) for p in prefixes))

    print(f"Traductions : {len(cles)} clés × {len(LANGUES)} langues ; "
          f"{len(appelees)} clés appelées dans le code ; "
          f"widgets : {', '.join(f'{n} ({len(c)})' for n, c in widgets.items()) or 'aucun'}")
    if inutilisees:
        print(f"Info : {len(inutilisees)} clés introuvables dans le code "
              f"(peut-être construites dynamiquement ; --verbose pour la liste)")
        if verbeux:
            for c in inutilisees:
                print(f"   - {c}")
    if erreurs:
        print(f"\n✗ {len(erreurs)} erreur(s) :")
        for e in erreurs:
            print(f"   - {e}")
        return 1
    print("✓ Aucune erreur de traduction")
    return 0


if __name__ == "__main__":
    sys.exit(main())

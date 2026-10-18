#!/usr/bin/env python3
"""Renommage Ando -> Ando dans le contenu des fichiers texte.

Usage : python3 scripts/renommage-ando.py [--vrai]
Sans --vrai, le script ne fait qu'un rapport (aucune écriture).
"""
import os
import sys

RACINE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
EXCLUS = {".git", "node_modules", ".wrangler", "_captures", "build", ".build"}
BINAIRES = {".png", ".jpg", ".jpeg", ".ico", ".pdf", ".pptx", ".xlsx",
            ".zip", ".woff", ".woff2", ".ttf", ".otf", ".mp4", ".DS_Store"}

# L'ordre compte : « Ando » avant « Ando ».
REMPLACEMENTS = [
    ("Ando", "Ando"),
    ("Ando", "Ando"),
    ("ando", "ando"),
]
# Deuxième passe : les identifiants de produits portaient les anciens
# noms de paliers (epargne/placement) alors que les paliers s'appellent
# Pro et Max. C'est le dernier moment où ils sont modifiables.
REMPLACEMENTS_2 = [
    ("ando.pro", "ando.pro"),
    ("ando.max", "ando.max"),
]


def fichiers():
    for dossier, sousdossiers, noms in os.walk(RACINE):
        sousdossiers[:] = [d for d in sousdossiers if d not in EXCLUS]
        for nom in noms:
            if os.path.splitext(nom)[1] in BINAIRES or nom == ".DS_Store":
                continue
            yield os.path.join(dossier, nom)


def main():
    vrai = "--vrai" in sys.argv
    touches, total = [], 0
    for chemin in fichiers():
        try:
            with open(chemin, "r", encoding="utf-8") as f:
                avant = f.read()
        except (UnicodeDecodeError, OSError):
            continue
        apres = avant
        for vieux, neuf in REMPLACEMENTS + REMPLACEMENTS_2:
            apres = apres.replace(vieux, neuf)
        if apres != avant:
            n = sum(avant.count(v) for v, _ in REMPLACEMENTS)
            touches.append((os.path.relpath(chemin, RACINE), n))
            total += n
            if vrai:
                with open(chemin, "w", encoding="utf-8") as f:
                    f.write(apres)
    mode = "APPLIQUÉ" if vrai else "SIMULATION (relance avec --vrai)"
    print(f"{mode} : {total} occurrences dans {len(touches)} fichiers")
    for rel, n in sorted(touches, key=lambda x: -x[1])[:15]:
        print(f"  {n:4d}  {rel}")


if __name__ == "__main__":
    main()

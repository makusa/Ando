#!/usr/bin/env python3
"""
Contrôle les longueurs des textes de docs/METADONNEES-APP-STORE.md contre les
limites d'App Store Connect.

Compter à la main un sous-titre de 30 caractères marche une fois sur deux, et
App Store Connect tronque sans prévenir à la saisie. Les accents comptent pour
un caractère : la mesure se fait donc sur des caractères Unicode, jamais sur
des octets.

    python3 scripts/verif-metadonnees.py
"""

import pathlib, re, sys

RACINE = pathlib.Path(__file__).resolve().parent.parent
FICHIER = RACINE / "docs/METADONNEES-APP-STORE.md"

# Limites d'App Store Connect, par bloc, dans l'ordre où ils apparaissent.
BLOCS = [
    ("mots-clés FR",          100),
    ("mots-clés EN",          100),
    ("texte promotionnel FR", 170),
    ("texte promotionnel EN", 170),
    ("description FR",       4000),
    ("description EN",       4000),
    ("notes au relecteur",   4000),
]

LIMITE_SOUS_TITRE = 30


def blocs(texte):
    return [b.strip("\n") for b in re.findall(r"```\n(.*?)```", texte, re.S)]


def main():
    texte = FICHIER.read_text(encoding="utf-8")
    trouves = blocs(texte)
    echecs = []

    if len(trouves) != len(BLOCS):
        sys.exit(f"{len(trouves)} blocs trouvés, {len(BLOCS)} attendus : "
                 "le document et ce script ont divergé.")

    print(f"{FICHIER.relative_to(RACINE)}\n")
    for (nom, limite), contenu in zip(BLOCS, trouves):
        n = len(contenu)
        ok = n <= limite
        print(f"  {'✓' if ok else '✗'} {nom:<24} {n:>5} / {limite}")
        if not ok:
            echecs.append(f"{nom} : {n} caractères, maximum {limite}")

        # Les mots-clés sont le seul champ où un espace après la virgule est
        # compté ET gaspillé : Apple ne le retire pas.
        if nom.startswith("mots-clés") and ", " in contenu:
            echecs.append(f"{nom} : espace après une virgule, "
                          "App Store Connect le compte comme un caractère")

    print()
    # Les sous-titres vivent dans un tableau, une paire FR/EN par rangée.
    # `[^`]+` traverserait les retours à la ligne et avalerait le tableau
    # entier : il faut exclure \n explicitement.
    rangees = [l for l in texte.splitlines() if l.startswith("|") and "`" in l]
    for rangee in rangees:
        for valeur in re.findall(r"`([^`\n]+)`", rangee):
            n = len(valeur)
            ok = n <= LIMITE_SOUS_TITRE
            print(f"  {'✓' if ok else '✗'} sous-titre « {valeur} » {n:>3} / {LIMITE_SOUS_TITRE}")
            if not ok:
                echecs.append(f"sous-titre « {valeur} » : {n} caractères")

    if echecs:
        print()
        sys.exit("Dépassements :\n  - " + "\n  - ".join(echecs))
    print("\n✓ Toutes les longueurs passent.")


if __name__ == "__main__":
    main()

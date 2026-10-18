#!/usr/bin/env python3
"""
Génère la liste des domaines dont le Worker accepte de servir le logo, à partir
de l'annuaire de l'app (Ando/Utilities/BankDirectory.swift).

    python3 scripts/gen-logo-allowlist.py           # (ré)écrit le fichier
    python3 scripts/gen-logo-allowlist.py --check   # code 1 si le fichier n'est pas à jour

Pourquoi une liste : sans elle, la route /api/logo/<domaine> servirait de relais
gratuit vers Logo.dev pour n'importe quel domaine et épuiserait le quota.
"""

import pathlib
import re
import sys

RACINE = pathlib.Path(__file__).resolve().parent.parent
ANNUAIRE = RACINE / "Ando/Utilities/BankDirectory.swift"
SORTIE = RACINE / "_landing/src/domaines-logos.js"


def contenu_attendu():
    domaines = sorted(set(d.lower() for d in
                          re.findall(r'domain:\s*"([^"]+)"', ANNUAIRE.read_text(encoding="utf-8"))))
    lignes = ",\n".join(f'  "{d}"' for d in domaines)
    return (
        "// FICHIER GÉNÉRÉ par scripts/gen-logo-allowlist.py à partir de\n"
        "// Ando/Utilities/BankDirectory.swift. Ne pas modifier à la main.\n"
        f"// {len(domaines)} domaines.\n"
        f"export const DOMAINES_LOGOS = new Set([\n{lignes}\n]);\n"
    ), len(domaines)


MINIMUM_DOMAINES = 50   # garde-fou : un annuaire mal lu viderait la liste


def main():
    attendu, n = contenu_attendu()
    if n < MINIMUM_DOMAINES:
        # Sans ce garde-fou, une erreur de lecture rendrait tous les logos
        # introuvables (404) dès le prochain déploiement.
        print(f"✗ Seulement {n} domaines lus dans {ANNUAIRE.relative_to(RACINE)} : arrêt, "
              f"aucun fichier écrit (minimum attendu : {MINIMUM_DOMAINES}).")
        return 1
    if "--check" in sys.argv:
        actuel = SORTIE.read_text(encoding="utf-8") if SORTIE.exists() else ""
        if actuel != attendu:
            print("✗ _landing/src/domaines-logos.js n'est pas à jour : "
                  "lancer python3 scripts/gen-logo-allowlist.py")
            return 1
        print(f"✓ Liste des domaines de logos à jour ({n} domaines)")
        return 0
    SORTIE.write_text(attendu, encoding="utf-8")
    print(f"✓ {SORTIE.relative_to(RACINE)} écrit ({n} domaines)")
    return 0


if __name__ == "__main__":
    sys.exit(main())

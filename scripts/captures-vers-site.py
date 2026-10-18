#!/usr/bin/env python3
"""Range les captures du harnais et met à jour les images du site.

Le harnais `AndoUITests/ScreenshotTests` produit un .xcresult ; les pièces
jointes en sont exportées avec un nom UUID. Le manifeste donne le vrai nom
(« 01-tableau-de-bord_0_<uuid>.png »). Ce script :

  1. renomme chaque capture en « NN-slug.png » dans un dossier propre ;
  2. remplace les images du site (_landing/public/img et img-en) en
     respectant exactement les noms déjà référencés par la landing — une
     image absente casserait un <img> et son texte alternatif.

Les captures pleine résolution sont conservées : ce sont elles qu'il faut
téléverser dans App Store Connect (1206 × 2622, taille obligatoire).

    python3 scripts/captures-vers-site.py /tmp/shots-fr fr
    python3 scripts/captures-vers-site.py /tmp/shots-en en
"""
import json
import pathlib
import re
import shutil
import subprocess
import sys

RACINE = pathlib.Path(__file__).resolve().parent.parent
LARGEUR_SITE = 620          # largeur des .webp servis par la landing


def ranger(source: pathlib.Path, destination: pathlib.Path) -> dict:
    """Renomme les pièces jointes en « NN-slug.png ». Retourne {slug: chemin}."""
    manifeste = json.loads((source / "manifest.json").read_text(encoding="utf-8"))
    destination.mkdir(parents=True, exist_ok=True)
    trouvees = {}
    for test in manifeste:
        for piece in test.get("attachments", []):
            lisible = piece.get("suggestedHumanReadableName", "")
            m = re.match(r"(\d+-[a-z0-9-]+)_", lisible)
            if not m:
                continue
            nom = m.group(1)
            cible = destination / f"{nom}.png"
            shutil.copy2(source / piece["exportedFileName"], cible)
            trouvees[nom] = cible
    return trouvees


def vers_webp(png: pathlib.Path, webp: pathlib.Path, largeur: int) -> None:
    """Redimensionne puis convertit. cwebp vient de Homebrew ; sips ne sait
    pas écrire de WebP."""
    temporaire = png.with_suffix(".redim.png")
    subprocess.run(["sips", "--resampleWidth", str(largeur),
                    str(png), "--out", str(temporaire)],
                   check=True, capture_output=True)
    subprocess.run(["cwebp", "-quiet", "-q", "82", str(temporaire), "-o", str(webp)],
                   check=True, capture_output=True)
    temporaire.unlink()


def main():
    if len(sys.argv) != 3 or sys.argv[2] not in ("fr", "en"):
        raise SystemExit(__doc__)
    source = pathlib.Path(sys.argv[1])
    langue = sys.argv[2]

    rangees = ranger(source, RACINE / "_captures" / f"ando-{langue}")
    print(f"{len(rangees)} captures rangées dans _captures/ando-{langue}/")

    dossier_site = RACINE / "_landing/public" / ("img" if langue == "fr" else "img-en")
    attendues = sorted(p.name for p in dossier_site.glob("*.webp"))
    if not attendues:
        raise SystemExit(f"Aucune image dans {dossier_site} : rien à remplacer.")

    remplacees, manquantes = 0, []
    for nom_webp in attendues:
        slug = nom_webp[:-len(".webp")]
        png = rangees.get(slug)
        if png is None:
            manquantes.append(nom_webp)
            continue
        vers_webp(png, dossier_site / nom_webp, LARGEUR_SITE)
        remplacees += 1

    print(f"{remplacees}/{len(attendues)} images du site remplacées "
          f"({dossier_site.relative_to(RACINE)})")
    if manquantes:
        print("  ⚠️  sans équivalent dans les captures, laissées intactes :")
        for n in manquantes:
            print(f"      {n}")


if __name__ == "__main__":
    main()

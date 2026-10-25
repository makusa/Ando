#!/usr/bin/env python3
"""
Produit les deux cartes de partage social à partir du gabarit.

    _landing/page/og.src.html   gabarit (texte français en clair)
    _landing/page/en.json       mêmes clés que la landing, pour l'anglais
    _landing/page/index.src.html  polices et jetons de couleur

    →  _landing/public/og-fr.jpg   1200 × 630
       _landing/public/og-en.jpg

Pourquoi un script plutôt qu'un fichier dessiné à la main : les précédentes
cartes affichaient encore « Fin:Track » longtemps après le renommage, parce
qu'un JPEG ne contient aucune trace de ce dont il est fait. Celles-ci sont
reconstructibles ; une faute de texte ou un changement de couleur se corrige
à la source et se repropage.

Séparé de build.py à dessein : la construction du site ne doit pas dépendre
de la présence de Chrome. build.py se contente d'avertir si ces images sont
plus vieilles que leur gabarit.

    python3 scripts/og-images.py

Les JPEG sont commités : le déploiement ne les régénère pas.
"""

import functools, http.server, json, pathlib, re, socket, subprocess, sys, tempfile, threading
import lxml.html
from PIL import Image

RACINE = pathlib.Path(__file__).resolve().parent.parent
LANDING = RACINE / "_landing"
PUBLIC = LANDING / "public"

sys.path.insert(0, str(LANDING))
from build import poser_html          # même mécanisme de traduction que la landing

CHROME = pathlib.Path("/Applications/Google Chrome.app/Contents/MacOS/Google Chrome")
LARGEUR, HAUTEUR = 1200, 630          # format attendu par Open Graph et Twitter
QUALITE = 88

LANGUES = {
    "fr": {"lang": "fr-CA", "images": "/img/",    "sortie": "og-fr.jpg"},
    "en": {"lang": "en-CA", "images": "/img-en/", "sortie": "og-en.jpg"},
}


def gabarit_rendu(code, og, index, en):
    """Le gabarit, habillé des polices et couleurs du site, traduit au besoin."""
    # Découpé comme dans build.pages_legales() : une seule définition de
    # l'identité graphique, celle de page/index.src.html.
    polices = index[index.index("<style>") + len("<style>"):index.index(":root{")]
    jetons = re.search(r":root\{.*?\n\}", index, re.S).group(0)
    html = og.replace("/*POLICES-ET-JETONS*/", polices + jetons, 1)

    doc = lxml.html.fromstring(html)
    cfg = LANGUES[code]
    doc.set("lang", cfg["lang"])

    if code == "en":
        for el in doc.xpath("//*[@data-t]"):
            if el.get("data-t") in en:
                poser_html(el, en[el.get("data-t")])
        for img in doc.xpath("//img[starts-with(@src,'/img/')]"):
            img.set("src", img.get("src").replace("/img/", cfg["images"], 1))

    return lxml.html.tostring(doc, encoding="unicode", doctype="<!DOCTYPE html>")


def servir(dossier):
    """Un serveur local éphémère : les chemins absolus (/fonts/, /img/) se
    résolvent alors exactement comme sur le site publié. Un rendu depuis
    file:// les casserait tous, en silence."""
    class Silencieux(http.server.SimpleHTTPRequestHandler):
        def log_message(self, *a):
            pass

    gestionnaire = functools.partial(Silencieux, directory=str(dossier))
    serveur = http.server.ThreadingHTTPServer(("127.0.0.1", 0), gestionnaire)
    threading.Thread(target=serveur.serve_forever, daemon=True).start()
    return serveur, serveur.socket.getsockname()[1]


def capturer(url, png, profil):
    subprocess.run(
        [str(CHROME), "--headless", "--disable-gpu", "--hide-scrollbars",
         "--force-device-scale-factor=1", f"--window-size={LARGEUR},{HAUTEUR}",
         f"--user-data-dir={profil}",          # jamais le profil de l'utilisateur
         "--virtual-time-budget=4000",         # laisse charger les polices et la capture
         f"--screenshot={png}", url],
        check=True, capture_output=True, text=True)


def main():
    if not CHROME.exists():
        raise SystemExit(f"Chrome introuvable : {CHROME}\n"
                         "Les JPEG déjà commités restent valides ; rien n'a été modifié.")

    og = (LANDING / "page/og.src.html").read_text(encoding="utf-8")
    index = (LANDING / "page/index.src.html").read_text(encoding="utf-8")
    en = json.loads((LANDING / "page/en.json").read_text(encoding="utf-8"))

    serveur, port = servir(PUBLIC)
    temporaires = []
    try:
        with tempfile.TemporaryDirectory() as travail:
            for code in LANGUES:
                # Le gabarit est posé DANS public/ le temps du rendu : c'est la
                # seule façon pour Chrome de voir /fonts/ et /img/.
                page = PUBLIC / f"_og-{code}.html"
                temporaires.append(page)
                page.write_text(gabarit_rendu(code, og, index, en), encoding="utf-8")

                png = pathlib.Path(travail) / f"og-{code}.png"
                capturer(f"http://127.0.0.1:{port}/_og-{code}.html", png,
                         pathlib.Path(travail) / f"profil-{code}")

                image = Image.open(png)
                if image.size != (LARGEUR, HAUTEUR):
                    raise SystemExit(
                        f"Capture {code} en {image.size[0]} × {image.size[1]} au lieu de "
                        f"{LARGEUR} × {HAUTEUR} : Chrome n'a pas respecté --window-size. "
                        "Rien n'a été écrit.")

                sortie = PUBLIC / LANGUES[code]["sortie"]
                image.convert("RGB").save(sortie, "JPEG", quality=QUALITE,
                                          optimize=True, progressive=True)
                print(f"  _landing/public/{LANGUES[code]['sortie']}  "
                      f"{LARGEUR} × {HAUTEUR}  {sortie.stat().st_size // 1024} Ko")
    finally:
        serveur.shutdown()
        for page in temporaires:
            page.unlink(missing_ok=True)

    print("\nÀ regarder avant de commiter : une carte fautive se voit, elle ne se teste pas.")


if __name__ == "__main__":
    main()

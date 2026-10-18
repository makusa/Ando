#!/usr/bin/env python3
"""
Génère les deux pages servies à partir d'un gabarit unique.

    page/index.src.html   gabarit, texte français en clair
    page/en.json          traductions anglaises, une clé par élément

    →  public/index.html      français, à la racine
       public/en/index.html   anglais, sous /en/

Le texte anglais est appliqué ici, au build, et non dans le navigateur :
un moteur de recherche a besoin d'une adresse par langue pour indexer les
deux, et de balises hreflang qui les relient. Un basculement en JavaScript
sur une seule URL ne rend indexable que la langue par défaut.

    python3 build.py
"""

import html as html_lib
import json, os, pathlib, re, subprocess, sys
import lxml.html

RACINE = pathlib.Path(__file__).parent
SITE = "https://ando.bmsk.ca"

LANGUES = {
    "fr": {
        "lang": "fr-CA", "url": f"{SITE}/", "dossier_images": "/img/",
        "og_locale": "fr_CA", "og_alt": "en_CA", "og_image": f"{SITE}/og-fr.jpg",
        "sortie": "public/index.html",
        "og_desc": "Droits de cotisation CELI et CELIAPP, hypothèque à capitalisation "
                   "semestrielle, marges de crédit au taux journalier. Sur votre iPhone.",
        "ld_desc": "Application de finances personnelles pour le Canada : suivi des droits "
                   "de cotisation CELI, CELIAPP et REER, amortissement hypothécaire à "
                   "capitalisation semestrielle, marges de crédit au taux journalier.",
    },
    "en": {
        "lang": "en-CA", "url": f"{SITE}/en/", "dossier_images": "/img-en/",
        "og_locale": "en_CA", "og_alt": "fr_CA", "og_image": f"{SITE}/og-en.jpg",
        "sortie": "public/en/index.html",
        "og_desc": "TFSA and FHSA contribution room, semi-annual mortgage compounding, "
                   "credit lines at the daily rate. On your iPhone.",
        "ld_desc": "Personal finance app for Canada: TFSA, FHSA and RRSP contribution room "
                   "tracking, semi-annual mortgage amortization, credit lines with daily "
                   "interest.",
    },
}


def poser_html(element, html):
    """Remplace le contenu d'un élément par un fragment HTML."""
    frag = lxml.html.fragment_fromstring(html, create_parent="conteneur")
    for enfant in list(element):
        element.remove(enfant)
    element.text = frag.text
    for enfant in frag:
        element.append(enfant)


def donnees_structurees(code, cfg, titre):
    """JSON-LD : dit aux moteurs que la page décrit une application, pas un article."""
    return json.dumps({
        "@context": "https://schema.org",
        "@type": "SoftwareApplication",
        "name": "Ando",
        "applicationCategory": "FinanceApplication",
        "operatingSystem": "iOS 17+",
        "inLanguage": ["fr-CA", "en-CA", "es", "pt"],
        "url": cfg["url"],
        "description": cfg["ld_desc"],
        "offers": [
            {"@type": "Offer", "name": "Courant", "price": "0",     "priceCurrency": "CAD"},
            {"@type": "Offer", "name": "Pro",     "price": "24.99", "priceCurrency": "CAD"},
            # Max (abonnement) : réintroduire l'offre et son prix au lancement de
            # la connexion bancaire. Absent pendant la bêta.
        ],
        "author": {"@type": "Organization", "name": "bmsk", "url": "https://bmsk.ca"},
    }, ensure_ascii=False, indent=2)


def rendre(code, gabarit, en):
    cfg = LANGUES[code]
    doc = lxml.html.fromstring(gabarit)
    doc.set("lang", cfg["lang"])

    if code == "en":
        for el in doc.xpath("//*[@data-t]"):
            if el.get("data-t") in en:
                poser_html(el, en[el.get("data-t")])
        for attribut, cle in (("alt", "data-alt"), ("placeholder", "data-ph"),
                              ("aria-label", "data-aria")):
            for el in doc.xpath(f"//*[@{cle}]"):
                if el.get(cle) in en:
                    el.set(attribut, en[el.get(cle)])
        doc.xpath("//title")[0].text = en["_title"]
        doc.xpath("//meta[@id='metaDesc']")[0].set("content", en["_desc"])

    # Liens propres à chaque langue : href (français) et data-href-en (anglais).
    for el in doc.xpath("//*[@data-href-en]"):
        if code == "en":
            el.set("href", el.get("data-href-en"))
        del el.attrib["data-href-en"]

    titre = doc.xpath("//title")[0].text

    # Jeu de captures correspondant à la langue de l'interface montrée
    for img in doc.xpath("//img[@data-shot]"):
        img.set("src", cfg["dossier_images"] + img.get("data-shot") + ".webp")

    # Sélecteur : la langue courante est marquée, l'autre est un lien à suivre
    doc.xpath(f"//*[@id='lien{code.upper()}']")[0].set("aria-current", "page")

    html = lxml.html.tostring(doc, encoding="unicode", doctype="<!DOCTYPE html>")

    tete = f"""<link rel="canonical" href="{cfg['url']}">
<link rel="alternate" hreflang="fr-CA" href="{SITE}/">
<link rel="alternate" hreflang="en-CA" href="{SITE}/en/">
<link rel="alternate" hreflang="x-default" href="{SITE}/">
<link rel="icon" href="/favicon.ico" sizes="any">
<link rel="icon" type="image/png" sizes="32x32" href="/favicon-32.png">
<link rel="icon" type="image/png" sizes="16x16" href="/favicon-16.png">
<link rel="apple-touch-icon" href="/apple-touch-icon.png">
<meta property="og:type" content="website">
<meta property="og:site_name" content="Ando">
<meta property="og:title" content="{titre}">
<meta property="og:description" content="{cfg['og_desc']}">
<meta property="og:url" content="{cfg['url']}">
<meta property="og:image" content="{cfg['og_image']}">
<meta property="og:image:width" content="1200">
<meta property="og:image:height" content="630">
<meta property="og:locale" content="{cfg['og_locale']}">
<meta property="og:locale:alternate" content="{cfg['og_alt']}">
<meta name="twitter:card" content="summary_large_image">
<meta name="twitter:title" content="{titre}">
<meta name="twitter:description" content="{cfg['og_desc']}">
<meta name="twitter:image" content="{cfg['og_image']}">"""

    html = html.replace(
        "<!DOCTYPE html>",
        "<!DOCTYPE html>\n<!-- Fichier généré par _landing/build.py — ne pas éditer ici.\n"
        "     Source du contenu : page/index.src.html et page/en.json.\n"
        "     Régénérer avec : python3 build.py -->", 1)
    html = html.replace("<!--TETE-->", tete)
    html = html.replace(
        "<!--DONNEES-STRUCTUREES-->",
        '<script type="application/ld+json">\n%s\n</script>'
        % donnees_structurees(code, cfg, titre),
    )

    chemin = RACINE / cfg["sortie"]
    chemin.parent.mkdir(parents=True, exist_ok=True)
    chemin.write_text(html, encoding="utf-8")
    return chemin, len(html)


# ── Pages légales ───────────────────────────────────────────────────────────
#
# Source unique : les fichiers Markdown de docs/legal/ (texte relu). Les pages
# publiées en sont générées ; elles ne peuvent donc pas dériver du texte validé.
# Les lignes commençant par « > » sont des notes internes, non publiées.

LEGAL = {
    "fr": {"source": "docs/legal/politique-confidentialite.md",
           "sortie": "public/confidentialite/index.html",
           "url": f"{SITE}/confidentialite/", "lang": "fr-CA",
           "titre": "Politique de confidentialité — Ando",
           "desc": "Comment Ando et BMSK traitent vos renseignements personnels.",
           "accueil": "/", "autre": ("English", "/en/privacy/", "en"),
           "retour": "Retour à l'accueil"},
    "en": {"source": "docs/legal/privacy-policy.md",
           "sortie": "public/en/privacy/index.html",
           "url": f"{SITE}/en/privacy/", "lang": "en-CA",
           "titre": "Privacy Policy — Ando",
           "desc": "How Ando and BMSK handle your personal information.",
           "accueil": "/en/", "autre": ("Français", "/confidentialite/", "fr"),
           "retour": "Back to home"},
}

# Le build refuse de publier un texte qui contient encore un marqueur de travail.
MARQUEURS = re.compile(r"\[(À COMPLÉTER|TO COMPLETE|À VALIDER|TO CONFIRM|À VÉRIFIER|TO CHECK)")


def en_ligne(texte):
    """Gras, code et adresses courriel, après échappement du HTML."""
    t = html_lib.escape(texte, quote=False)
    t = re.sub(r"\*\*(.+?)\*\*", r"<strong>\1</strong>", t)
    t = re.sub(r"`([^`]+)`", r"<code>\1</code>", t)
    t = re.sub(r"(?<![\w.])([\w.+-]+@[\w-]+(?:\.[\w-]+)+)", r'<a href="mailto:\1">\1</a>', t)
    return t


def markdown_vers_html(source):
    """Convertisseur volontairement minimal, limité à ce que les textes légaux
    utilisent : titres #/##/###, paragraphes, listes « - », tableaux, gras,
    code. Pas de dépendance externe à installer."""
    lignes = [l for l in source.splitlines() if not l.startswith(">")]
    debut_bloc = re.compile(r"#{1,3} |\||- ")
    blocs, i = [], 0
    while i < len(lignes):
        ligne = lignes[i]
        if not ligne.strip():
            i += 1
            continue
        titre = re.match(r"(#{1,3}) (.*)", ligne)
        if titre:
            n = len(titre.group(1))
            blocs.append(f"<h{n}>{en_ligne(titre.group(2))}</h{n}>")
            i += 1
        elif ligne.startswith("|"):
            rangees = []
            while i < len(lignes) and lignes[i].startswith("|"):
                rangees.append([c.strip() for c in lignes[i].strip().strip("|").split("|")])
                i += 1
            entete, corps = rangees[0], rangees[2:]   # rangees[1] : ligne |---|
            blocs.append(
                '<div class="tableau"><table><thead><tr>'
                + "".join(f"<th>{en_ligne(c)}</th>" for c in entete)
                + "</tr></thead><tbody>"
                + "".join("<tr>" + "".join(f"<td>{en_ligne(c)}</td>" for c in r) + "</tr>"
                          for r in corps)
                + "</tbody></table></div>")
        elif ligne.startswith("- "):
            items = []
            while i < len(lignes) and (lignes[i].startswith("- ")
                                       or (lignes[i].startswith("  ") and lignes[i].strip())):
                if lignes[i].startswith("- "):
                    items.append(lignes[i][2:].strip())
                else:
                    items[-1] += " " + lignes[i].strip()
                i += 1
            blocs.append("<ul>" + "".join(f"<li>{en_ligne(x)}</li>" for x in items) + "</ul>")
        else:
            para = []
            while i < len(lignes) and lignes[i].strip() and not debut_bloc.match(lignes[i]):
                para.append(lignes[i].strip())
                i += 1
            blocs.append(f"<p>{en_ligne(' '.join(para))}</p>")
    return "\n".join(blocs)


def pages_legales(gabarit):
    # Police et couleurs reprises du gabarit de la landing : aucune copie à maintenir.
    polices = gabarit[gabarit.index("<style>") + len("<style>"):gabarit.index(":root{")]
    jetons = re.search(r":root\{.*?\n\}", gabarit, re.S).group(0)
    css = polices + jetons + """
*{box-sizing:border-box;margin:0;padding:0}
body{background:var(--papier);color:var(--encre);font-family:var(--sans);line-height:1.65;-webkit-font-smoothing:antialiased}
.entete,.contenu,.pied{max-width:760px;margin:0 auto;padding-left:var(--gouttiere);padding-right:var(--gouttiere)}
.entete{display:flex;justify-content:space-between;align-items:center;padding-top:22px;padding-bottom:22px;border-bottom:1px solid var(--ligne)}
.marque{font-weight:700;font-size:1.05rem;color:var(--encre);text-decoration:none}
.entete .langue{font-size:.875rem;color:var(--sourdine)}
.contenu{padding-top:40px;padding-bottom:56px}
h1{font-size:clamp(1.9rem,4vw,2.5rem);line-height:1.15;font-variation-settings:"wdth" 110;margin-bottom:10px}
h2{font-size:1.3rem;line-height:1.3;margin:44px 0 10px}
h3{font-size:1.02rem;margin:26px 0 6px}
p{margin:0 0 14px}
ul{margin:0 0 14px;padding-left:22px}
li{margin-bottom:4px}
a{color:var(--verdigris)}
code{font-size:.9em;background:var(--surface);padding:1px 5px;border-radius:4px}
.tableau{overflow-x:auto;margin:8px 0 18px}
table{width:100%;border-collapse:collapse;font-size:.94rem;background:var(--surface)}
th,td{text-align:left;vertical-align:top;padding:9px 12px;border:1px solid var(--ligne)}
th{font-weight:650}
.pied{padding-top:22px;padding-bottom:40px;border-top:1px solid var(--ligne);font-size:.875rem;color:var(--sourdine)}
"""
    for code, cfg in LEGAL.items():
        source = (RACINE.parent / cfg["source"]).read_text(encoding="utf-8")
        publie = "\n".join(l for l in source.splitlines() if not l.startswith(">"))
        if MARQUEURS.search(publie):
            raise SystemExit(f"{cfg['source']} contient encore un marqueur de travail "
                             f"({MARQUEURS.search(publie).group(0)}…] : publication refusée.")
        autre_nom, autre_url, autre_code = cfg["autre"]
        page = f"""<!DOCTYPE html>
<!-- Fichier généré par _landing/build.py — ne pas éditer ici.
     Source du texte : {cfg['source']}. Régénérer avec : python3 build.py -->
<html lang="{cfg['lang']}">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{cfg['titre']}</title>
<meta name="description" content="{cfg['desc']}">
<link rel="canonical" href="{cfg['url']}">
<link rel="alternate" hreflang="fr-CA" href="{LEGAL['fr']['url']}">
<link rel="alternate" hreflang="en-CA" href="{LEGAL['en']['url']}">
<link rel="icon" href="/favicon.ico" sizes="any">
<link rel="icon" type="image/png" sizes="32x32" href="/favicon-32.png">
<link rel="apple-touch-icon" href="/apple-touch-icon.png">
<link rel="preload" href="/fonts/archivo-latin.woff2" as="font" type="font/woff2" crossorigin>
<style>{css}</style>
</head>
<body>
<header class="entete">
  <a class="marque" href="{cfg['accueil']}">Ando</a>
  <a class="langue" href="{autre_url}" hreflang="{autre_code}" lang="{autre_code}">{autre_nom}</a>
</header>
<main class="contenu">
{markdown_vers_html(source)}
</main>
<footer class="pied">BMSK · <a href="{cfg['accueil']}">{cfg['retour']}</a></footer>
</body>
</html>
"""
        chemin = RACINE / cfg["sortie"]
        chemin.parent.mkdir(parents=True, exist_ok=True)
        chemin.write_text(page, encoding="utf-8")
        print(f"  {cfg['sortie']}  {len(page) // 1024} Ko")


def main():
    gabarit = (RACINE / "page/index.src.html").read_text(encoding="utf-8")
    en = json.loads((RACINE / "page/en.json").read_text(encoding="utf-8"))

    for code in LANGUES:
        chemin, taille = rendre(code, gabarit, en)
        print(f"  {chemin.relative_to(RACINE)}  {taille // 1024} Ko")

    pages_legales(gabarit)

    (RACINE / "public/robots.txt").write_text(
        f"User-agent: *\nAllow: /\nDisallow: /api/\n\nSitemap: {SITE}/sitemap.xml\n",
        encoding="utf-8")

    (RACINE / "public/sitemap.xml").write_text(
        '<?xml version="1.0" encoding="UTF-8"?>\n'
        '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"\n'
        '        xmlns:xhtml="http://www.w3.org/1999/xhtml">\n'
        + "".join(
            f'  <url>\n    <loc>{c["url"]}</loc>\n'
            f'    <xhtml:link rel="alternate" hreflang="fr-CA" href="{SITE}/"/>\n'
            f'    <xhtml:link rel="alternate" hreflang="en-CA" href="{SITE}/en/"/>\n'
            f'    <xhtml:link rel="alternate" hreflang="x-default" href="{SITE}/"/>\n'
            f'  </url>\n' for c in LANGUES.values())
        + "".join(
            f'  <url>\n    <loc>{c["url"]}</loc>\n'
            f'    <xhtml:link rel="alternate" hreflang="fr-CA" href="{LEGAL["fr"]["url"]}"/>\n'
            f'    <xhtml:link rel="alternate" hreflang="en-CA" href="{LEGAL["en"]["url"]}"/>\n'
            f'  </url>\n' for c in LEGAL.values())
        + "</urlset>\n", encoding="utf-8")

    print("  public/robots.txt, public/sitemap.xml")

    domaines_logos()


def domaines_logos():
    """Régénère la liste blanche des domaines dont le Worker accepte de servir le
    logo (/api/logo/<domaine>), à chaque construction de la landing : elle ne
    peut donc pas être oubliée avant un déploiement.

    Délègue à scripts/gen-logo-allowlist.py : un seul générateur, un seul format,
    celui que scripts/verify.sh contrôle. Le script refuse d'écrire une liste
    presque vide si l'annuaire était mal lu."""
    script = RACINE.parent / "scripts/gen-logo-allowlist.py"
    resultat = subprocess.run([sys.executable, str(script)], capture_output=True, text=True)
    if resultat.returncode != 0:
        raise SystemExit(resultat.stdout + resultat.stderr)
    print("  " + resultat.stdout.strip().lstrip("✓ ").replace("_landing/", ""))


if __name__ == "__main__":
    main()

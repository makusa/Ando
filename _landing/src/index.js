/**
 * Ando — landing page.
 *
 * Les fichiers statiques de public/ sont servis par la couche d'assets de
 * Cloudflare sans passer par ce script. Le Worker ne traite donc que les
 * routes /api/*.
 *
 *   POST /api/inscription      inscription à la bêta
 *   GET  /api/inscriptions     export CSV, protégé par un jeton
 *   GET  /api/logo/<domaine>   logo d'une institution de l'annuaire de l'app
 *   GET  /desabonnement       page de retrait de la liste (lien du courriel)
 *   POST /api/desabonnement   effectue le retrait
 *
 * Secrets Wrangler, jamais dans le dépôt :
 *   npx wrangler secret put ADMIN_TOKEN      (export des inscriptions)
 *   npx wrangler secret put LOGO_DEV_TOKEN   (clé publishable Logo.dev)
 */

import { DOMAINES_LOGOS } from "./domaines-logos.js";

/** Version du texte de consentement affiché sur la page, conservée avec
 *  chaque inscription pour pouvoir prouver plus tard ce qui a été promis. */
const CONSENTEMENT = "beta-testflight-2026-09";

const MAX_CORPS = 1024; // octets ; une inscription légitime en fait ~60

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);

    // L'app s'appelait Fin:Track jusqu'au 17 octobre 2026. Les courriels de
    // la liste d'attente déjà partis portent des liens fintrack.bmsk.ca ;
    // les casser priverait leurs destinataires du désabonnement exigé par la
    // LCAP. Redirection permanente, chemin et paramètres conservés.
    if (url.hostname === "fintrack.bmsk.ca") {
      const cible = new URL(request.url);
      cible.hostname = "ando.bmsk.ca";
      return Response.redirect(cible.toString(), 301);
    }

    if (url.pathname.startsWith("/api/logo/")) {
      if (request.method !== "GET") return refus(405, "methode");
      return logo(url, env, ctx);
    }

    if (url.pathname === "/desabonnement") {
      if (request.method !== "GET") return refus(405, "methode");
      return pageDesabonnement(url);
    }

    if (url.pathname === "/api/desabonnement") {
      if (request.method !== "POST") return refus(405, "methode");
      return desabonner(request, env);
    }

    if (url.pathname === "/api/inscription") {
      if (request.method !== "POST") return refus(405, "methode");
      return inscrire(request, env);
    }

    if (url.pathname === "/api/inscriptions") {
      if (request.method !== "GET") return refus(405, "methode");
      return exporter(request, env);
    }

    // Tout le reste : laisser la couche d'assets répondre (404 incluse).
    return env.ASSETS.fetch(request);
  },
};

// ── Inscription ────────────────────────────────────────────────────────────

async function inscrire(request, env) {
  const brut = await request.text();
  if (brut.length > MAX_CORPS) return refus(413, "corps");

  let corps;
  try {
    corps = JSON.parse(brut);
  } catch {
    return refus(400, "format");
  }

  // Piège à robots : champ invisible pour un humain. S'il est rempli, on
  // répond comme si tout s'était bien passé, sans rien enregistrer.
  if (typeof corps.entreprise === "string" && corps.entreprise.trim() !== "") {
    return json({ ok: true, deja: false });
  }

  const courriel = normaliserCourriel(corps.courriel);
  if (!courriel) return refus(422, "courriel");

  const langue = corps.langue === "en" ? "en" : "fr";
  const pays = request.headers.get("CF-IPCountry") || null;
  const maintenant = new Date().toISOString();

  try {
    // Si l'adresse s'était désabonnée puis revient, elle re-consent : on efface
    // le retrait et on enregistre le nouveau consentement (date et version).
    const resultat = await env.DB.prepare(
      `INSERT INTO inscriptions (courriel, langue, pays, consentement, cree_le, jeton)
       VALUES (?, ?, ?, ?, ?, ?)
       ON CONFLICT (courriel) DO UPDATE SET
         desabonne_le = NULL,
         langue       = excluded.langue,
         consentement = excluded.consentement,
         cree_le      = excluded.cree_le
       WHERE inscriptions.desabonne_le IS NOT NULL`
    )
      .bind(courriel, langue, pays, CONSENTEMENT, maintenant, crypto.randomUUID())
      .run();

    const nouvelle = (resultat.meta?.changes ?? 0) > 0;
    return json({ ok: true, deja: !nouvelle });
  } catch (erreur) {
    console.error("inscription", erreur);
    return refus(500, "serveur");
  }
}

/** Valide et normalise une adresse. Retourne null si elle est inutilisable. */
function normaliserCourriel(valeur) {
  if (typeof valeur !== "string") return null;
  const courriel = valeur.trim().toLowerCase();
  if (courriel.length < 6 || courriel.length > 254) return null;
  // Volontairement permissif : refuser une adresse valide est pire que
  // d'en accepter une qui rebondira à l'envoi.
  if (!/^[^\s@]+@[^\s@.]+\.[^\s@]{2,}$/.test(courriel)) return null;
  return courriel;
}

// ── Export ─────────────────────────────────────────────────────────────────

async function exporter(request, env) {
  const attendu = env.ADMIN_TOKEN;
  const fourni = (request.headers.get("Authorization") || "").replace(/^Bearer\s+/i, "");
  if (!attendu || !egalitéConstante(fourni, attendu)) return refus(401, "jeton");

  const { results } = await env.DB.prepare(
    `SELECT courriel, langue, pays, consentement, cree_le, desabonne_le
       FROM inscriptions
      WHERE desabonne_le IS NULL
      ORDER BY cree_le`
  ).all();

  const entetes = "courriel,langue,pays,consentement,cree_le";
  const lignes = results.map((r) =>
    [r.courriel, r.langue, r.pays ?? "", r.consentement, r.cree_le]
      .map((c) => `"${String(c).replace(/"/g, '""')}"`)
      .join(",")
  );

  return new Response([entetes, ...lignes].join("\n"), {
    headers: {
      "Content-Type": "text/csv; charset=utf-8",
      "Content-Disposition": 'attachment; filename="ando-beta.csv"',
      "Cache-Control": "no-store",
    },
  });
}

/** Comparaison à temps constant, pour ne pas laisser deviner le jeton. */
function egalitéConstante(a, b) {
  if (a.length !== b.length) return false;
  let ecart = 0;
  for (let i = 0; i < a.length; i++) ecart |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return ecart === 0;
}

// ── Réponses ───────────────────────────────────────────────────────────────

function json(donnees, statut = 200) {
  return new Response(JSON.stringify(donnees), {
    status: statut,
    headers: { "Content-Type": "application/json; charset=utf-8", "Cache-Control": "no-store" },
  });
}

function refus(statut, raison) {
  return json({ ok: false, raison }, statut);
}

// ── Logos des institutions ─────────────────────────────────────────────────
//
// L'app affiche le logo d'une institution en le demandant ici, et non
// directement à Logo.dev. Ainsi :
//   - Logo.dev ne voit jamais l'utilisateur : la requête vers lui est neuve et
//     ne reprend aucun en-tête du visiteur (ni adresse, ni navigateur) ;
//   - la clé Logo.dev reste sur le serveur ;
//   - chaque logo n'est demandé à Logo.dev qu'une fois par mois (cache).
// Aucune trace de ces requêtes n'est conservée (journaux d'invocation désactivés
// dans wrangler.jsonc) et rien n'est écrit en base.

const LOGO_CACHE_SECONDES = 30 * 24 * 3600;   // logo trouvé
const LOGO_ABSENT_SECONDES = 7 * 24 * 3600;   // aucun logo pour ce domaine

async function logo(url, env, ctx) {
  let domaine;
  try {
    domaine = decodeURIComponent(url.pathname.slice("/api/logo/".length)).toLowerCase();
  } catch {
    return vide(404, LOGO_ABSENT_SECONDES);   // encodage invalide
  }

  // Uniquement les institutions de l'annuaire de l'app : sinon cette route
  // servirait de relais gratuit vers Logo.dev et épuiserait le quota.
  if (!DOMAINES_LOGOS.has(domaine)) return vide(404, LOGO_ABSENT_SECONDES);
  if (!env.LOGO_DEV_TOKEN) return vide(503, 0);

  // Clé de cache normalisée : sans paramètres, quelle que soit l'URL reçue.
  const cache = caches.default;
  const cle = new Request(`https://ando.bmsk.ca/api/logo/${domaine}`);
  const enCache = await cache.match(cle);
  if (enCache) return enCache;

  const source = new URL(`https://img.logo.dev/${encodeURIComponent(domaine)}`);
  source.search = new URLSearchParams({
    token: env.LOGO_DEV_TOKEN,
    size: "128",
    retina: "true",
    format: "png",      // fond transparent
    fallback: "404",    // pas de monogramme Logo.dev : l'app affiche le sien
  }).toString();

  let amont;
  try {
    amont = await fetch(source.toString(), { headers: { Accept: "image/png" } });
  } catch {
    return vide(502, 0);
  }

  let reponse;
  if (amont.status === 404) {
    reponse = vide(404, LOGO_ABSENT_SECONDES);
  } else if (amont.ok) {
    reponse = new Response(await amont.arrayBuffer(), {
      headers: {
        "Content-Type": amont.headers.get("Content-Type") || "image/png",
        "Cache-Control": `public, max-age=${LOGO_CACHE_SECONDES}`,
        "X-Content-Type-Options": "nosniff",
      },
    });
  } else {
    // Quota atteint, clé invalide, panne : ne rien mettre en cache.
    return vide(502, 0);
  }

  ctx.waitUntil(cache.put(cle, reponse.clone()));
  return reponse;
}

function vide(statut, secondes) {
  return new Response(null, {
    status: statut,
    headers: { "Cache-Control": secondes ? `public, max-age=${secondes}` : "no-store" },
  });
}

// ── Désabonnement ──────────────────────────────────────────────────────────
//
// La LCAP exige un retrait simple, sans compte ni connexion. Le lien du
// courriel porte un jeton propre à l'inscription : il identifie la personne
// sans exposer son adresse dans l'URL, et personne ne peut désabonner autrui.
//
// Le retrait se fait en deux temps — une page, puis un bouton qui envoie un
// POST — parce que certains clients de messagerie et antivirus visitent les
// liens d'un courriel à l'avance : un simple GET désabonnerait des personnes
// qui n'ont jamais cliqué.

async function desabonner(request, env) {
  let jeton;
  try {
    jeton = (await request.json()).jeton;
  } catch {
    return refus(400, "format");
  }
  if (typeof jeton !== "string" || jeton.length < 8 || jeton.length > 64) {
    return refus(422, "jeton");
  }

  try {
    // Le retrait est idempotent : recliquer n'écrase pas la date initiale.
    const r = await env.DB.prepare(
      `UPDATE inscriptions
          SET desabonne_le = ?
        WHERE jeton = ? AND desabonne_le IS NULL`
    )
      .bind(new Date().toISOString(), jeton)
      .run();

    if ((r.meta?.changes ?? 0) > 0) return json({ ok: true, deja: false });

    // Aucune ligne touchée : soit déjà désabonnée, soit jeton inconnu. On ne
    // distingue pas les deux dans la réponse, pour ne pas confirmer l'existence
    // d'une adresse à qui essaierait des jetons au hasard.
    const existe = await env.DB.prepare(`SELECT 1 FROM inscriptions WHERE jeton = ?`)
      .bind(jeton)
      .first();
    return existe ? json({ ok: true, deja: true }) : refus(404, "introuvable");
  } catch (erreur) {
    console.error("desabonnement", erreur);
    return refus(500, "serveur");
  }
}

/** Page de confirmation du retrait. Langue : ?l=en, sinon français. */
function pageDesabonnement(url) {
  const jeton = (url.searchParams.get("j") || "").slice(0, 64);
  const en = url.searchParams.get("l") === "en";

  const t = en
    ? {
        lang: "en-CA", titre: "Leave the beta list — Ando",
        h1: "Leave the beta list",
        p: "You will no longer receive the Ando TestFlight invitation. Nothing else changes.",
        bouton: "Confirm", occupe: "Removing…",
        fait: "Done — your address has been removed from the list.",
        deja: "Your address was already removed from the list.",
        erreur: "This link is no longer valid. Write to bonjour@bmsk.ca and we will remove you.",
        sansJeton: "This link is incomplete. Use the link from the invitation email, or write to bonjour@bmsk.ca.",
        retour: "Back to the site",
      }
    : {
        lang: "fr-CA", titre: "Quitter la liste de la bêta — Ando",
        h1: "Quitter la liste de la bêta",
        p: "Vous ne recevrez plus l'invitation TestFlight de Ando. Rien d'autre ne change.",
        bouton: "Confirmer", occupe: "Retrait en cours…",
        fait: "C'est fait — votre adresse a été retirée de la liste.",
        deja: "Votre adresse avait déjà été retirée de la liste.",
        erreur: "Ce lien n'est plus valide. Écrivez à bonjour@bmsk.ca et nous vous retirerons.",
        sansJeton: "Ce lien est incomplet. Utilisez le lien du courriel d'invitation, ou écrivez à bonjour@bmsk.ca.",
        retour: "Retour au site",
      };

  const page = `<!DOCTYPE html>
<html lang="${t.lang}">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="robots" content="noindex">
<title>${t.titre}</title>
<link rel="icon" href="/favicon.ico" sizes="any">
<link rel="preload" href="/fonts/archivo-latin.woff2" as="font" type="font/woff2" crossorigin>
<style>
@font-face{font-family:'Archivo';font-style:normal;font-weight:100 900;font-stretch:62% 125%;font-display:swap;
  src:url(/fonts/archivo-latin.woff2) format('woff2')}
:root{--papier:#EEF1EF;--surface:#F9FBFA;--encre:#0E241E;--verdigris:#2E7D6C;--sourdine:#5C6E68;--ligne:#D2DAD6}
*{box-sizing:border-box;margin:0;padding:0}
body{background:var(--papier);color:var(--encre);font-family:'Archivo',-apple-system,sans-serif;
  line-height:1.6;display:flex;align-items:center;justify-content:center;min-height:100vh;padding:24px}
.carte{background:var(--surface);border:1px solid var(--ligne);border-radius:14px;
  padding:32px;max-width:520px;width:100%}
h1{font-size:1.5rem;line-height:1.25;margin-bottom:12px}
p{margin-bottom:20px}
button{font:inherit;font-weight:600;color:#fff;background:var(--encre);border:0;border-radius:9px;
  padding:12px 22px;cursor:pointer}
button:disabled{opacity:.55;cursor:default}
.etat{margin-top:18px;font-size:.95rem}
.ok{color:var(--verdigris)}
.ko{color:#A32D2D}
a{color:var(--verdigris);font-size:.9rem}
.pied{margin-top:24px;font-size:.85rem;color:var(--sourdine)}
</style>
</head>
<body>
<main class="carte">
  <h1>${t.h1}</h1>
  <p>${jeton ? t.p : t.sansJeton}</p>
  ${jeton ? `<button id="b">${t.bouton}</button><div class="etat" id="e" role="status" aria-live="polite"></div>` : ""}
  <div class="pied"><a href="${en ? "/en/" : "/"}">${t.retour}</a></div>
</main>
<script>
var b = document.getElementById("b");
if (b) b.addEventListener("click", async function () {
  var e = document.getElementById("e");
  b.disabled = true; e.className = "etat"; e.textContent = ${JSON.stringify(t.occupe)};
  try {
    var r = await fetch("/api/desabonnement", {
      method: "POST", headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ jeton: ${JSON.stringify(jeton)} })
    });
    var d = await r.json().catch(function () { return {}; });
    if (r.ok && d.ok) {
      e.className = "etat ok";
      e.textContent = d.deja ? ${JSON.stringify(t.deja)} : ${JSON.stringify(t.fait)};
      b.remove();
    } else {
      e.className = "etat ko"; e.textContent = ${JSON.stringify(t.erreur)}; b.disabled = false;
    }
  } catch (x) {
    e.className = "etat ko"; e.textContent = ${JSON.stringify(t.erreur)}; b.disabled = false;
  }
});
</script>
</body>
</html>`;

  return new Response(page, {
    headers: { "Content-Type": "text/html; charset=utf-8", "Cache-Control": "no-store" },
  });
}

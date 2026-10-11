/**
 * Fin:Track — landing page.
 *
 * Les fichiers statiques de public/ sont servis par la couche d'assets de
 * Cloudflare sans passer par ce script. Le Worker ne traite donc que les
 * routes /api/*.
 *
 *   POST /api/inscription      inscription à la bêta
 *   GET  /api/inscriptions     export CSV, protégé par un jeton
 *   GET  /api/logo/<domaine>   logo d'une institution de l'annuaire de l'app
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

    if (url.pathname.startsWith("/api/logo/")) {
      if (request.method !== "GET") return refus(405, "methode");
      return logo(url, env, ctx);
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
    const resultat = await env.DB.prepare(
      `INSERT INTO inscriptions (courriel, langue, pays, consentement, cree_le)
       VALUES (?, ?, ?, ?, ?)
       ON CONFLICT (courriel) DO NOTHING`
    )
      .bind(courriel, langue, pays, CONSENTEMENT, maintenant)
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
      "Content-Disposition": 'attachment; filename="fintrack-beta.csv"',
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
  const cle = new Request(`https://fintrack.bmsk.ca/api/logo/${domaine}`);
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

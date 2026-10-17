-- Liste d'attente de la bêta TestFlight.
--
-- Choix de rétention : on conserve le minimum permettant de prouver le
-- consentement au sens de la LCAP — quand, dans quelle langue, et quel texte
-- de consentement était affiché à ce moment-là. L'adresse IP n'est pas
-- conservée : elle constituerait une preuve plus forte, mais c'est un
-- renseignement personnel supplémentaire, et le pays fourni par Cloudflare
-- suffit à situer la demande.

CREATE TABLE IF NOT EXISTS inscriptions (
  id             INTEGER PRIMARY KEY AUTOINCREMENT,
  courriel       TEXT    NOT NULL UNIQUE,
  langue         TEXT    NOT NULL,              -- fr | en
  pays           TEXT,                          -- code pays fourni par Cloudflare
  consentement   TEXT    NOT NULL,              -- version du texte affiché
  cree_le        TEXT    NOT NULL,              -- ISO 8601 UTC
  desabonne_le   TEXT,                          -- rempli si retrait demandé
  jeton          TEXT    NOT NULL UNIQUE        -- identifie le lien de désabonnement
);

CREATE INDEX IF NOT EXISTS idx_inscriptions_cree_le ON inscriptions (cree_le);

-- Le désabonnement se fait par un lien signé d'un jeton propre à chaque
-- inscription : la personne n'a pas à se connecter (exigence LCAP), et
-- personne ne peut désabonner une adresse sans détenir son jeton.
CREATE INDEX IF NOT EXISTS idx_inscriptions_jeton ON inscriptions (jeton);

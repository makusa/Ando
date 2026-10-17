-- Ajoute le jeton de désabonnement aux inscriptions existantes.
-- À appliquer une fois :
--   npx wrangler d1 execute fintrack-beta --remote --file migrations/0001-jeton-desabonnement.sql
--
-- SQLite n'accepte pas NOT NULL UNIQUE dans un ALTER TABLE : la colonne est
-- ajoutée nullable, remplie pour les lignes existantes, puis l'unicité est
-- garantie par un index. Les nouvelles inscriptions reçoivent leur jeton à
-- l'insertion (voir src/index.js).

ALTER TABLE inscriptions ADD COLUMN jeton TEXT;

UPDATE inscriptions
   SET jeton = lower(hex(randomblob(16)))
 WHERE jeton IS NULL;

CREATE UNIQUE INDEX IF NOT EXISTS idx_inscriptions_jeton ON inscriptions (jeton);

# Fonctions partagées par scripts/verify.sh et le garde-fou de commit.
# À charger avec : . scripts/lib-empreinte.sh  (depuis la racine du dépôt)

# Fichier qui mémorise la dernière vérification complète réussie (hors dépôt).
TAMPON_VERIFICATION="$(git rev-parse --git-dir)/fintrack-verification"

# Empreinte du contenu actuel (sur disque) des fichiers qui entrent dans un build
# de l'app : fichiers suivis et nouveaux fichiers non ignorés. Si l'un d'eux
# change, la dernière vérification ne vaut plus. Les .DS_Store sont exclus, sinon
# un simple passage du Finder invaliderait la vérification.
# Chemins écrits en toutes lettres (pas dans une variable) : zsh ne découpe pas
# une variable non guillemetée comme bash, et ne verrait alors aucun fichier.
empreinte_build() {
    git ls-files -co --exclude-standard -- FinTrack FinTrackWidget FinTrackUITests project.yml \
        | grep -v '\.DS_Store$' \
        | LC_ALL=C sort \
        | while IFS= read -r f; do [ -f "$f" ] && shasum "$f"; done \
        | shasum | cut -d' ' -f1
}

#!/bin/bash
# Active le garde-fou de commit de Fin:Track pour ce clone du dépôt.
# À lancer une fois par clone (la configuration Git locale n'est pas versionnée).
#
#   scripts/install-hooks.sh            active
#   scripts/install-hooks.sh --remove   désactive

set -u
cd "$(git rev-parse --show-toplevel)" || exit 1

if [ "${1:-}" = "--remove" ]; then
    git config --unset core.hooksPath && echo "Garde-fou désactivé." || echo "Il n'était pas activé."
    exit 0
fi

actuel=$(git config core.hooksPath || true)
if [ -n "$actuel" ] && [ "$actuel" != "scripts/git-hooks" ]; then
    echo "core.hooksPath vaut déjà « $actuel » : rien n'a été modifié."
    echo "Vérifier ce réglage avant de le remplacer."
    exit 1
fi

chmod +x scripts/git-hooks/* scripts/verify.sh scripts/check-l10n.py
git config core.hooksPath scripts/git-hooks
echo "✓ Garde-fou activé (core.hooksPath = scripts/git-hooks)."
echo "  Avant de committer du code de l'app : scripts/verify.sh"

#!/bin/bash
# Vérification complète de Ando avant commit.
#
#   scripts/verify.sh           traductions + App Group + builds Debug ET Release
#   scripts/verify.sh --quick   idem, Debug seulement (rapide, n'autorise pas le commit)
#
# Réussite = 0 erreur et 0 avertissement (hors bruit appintentsmetadataprocessor).
# Une vérification complète réussie est mémorisée : le garde-fou de commit
# l'exige tant que le code n'a pas changé depuis.

set -u
cd "$(git rev-parse --show-toplevel)" || exit 2
. scripts/lib-empreinte.sh

MODE=complet
case "${1:-}" in
    --quick) MODE=rapide ;;
    -h|--help) sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    "") ;;
    *) echo "Option inconnue : $1 (voir --help)"; exit 2 ;;
esac

# Simulateur utilisé pour les tests unitaires (les builds, eux, sont génériques).
SIMULATEUR="42645610-A5FC-408B-A0A6-1AF9CA31170D"
JOURNAUX="${TMPDIR:-/tmp}/ando-verify"
mkdir -p "$JOURNAUX"
DEBUT=$(date +%s)
echec() { echo; echo "✗ ÉCHEC : $1"; echo "  Aucun commit n'est autorisé tant que ce n'est pas corrigé."; exit 1; }

echo "== Ando — vérification ($MODE) =="
EMPREINTE_AVANT=$(empreinte_build)

# 1. Traductions (une seconde)
echo; echo "1. Traductions"
python3 scripts/check-l10n.py | sed 's/^/   /'
[ "${PIPESTATUS[0]}" -eq 0 ] || echec "erreurs de traduction (détail ci-dessus)"

# 2. App Group présent dans les deux fichiers d'entitlements (XcodeGen peut l'effacer)
echo; echo "2. App Group"
for f in Ando/Ando.entitlements AndoWidget/AndoWidget.entitlements; do
    n=$(grep -c 'group.ca.bmsk' "$f")
    echo "   $f : $n"
    [ "$n" -eq 1 ] || echec "App Group absent ou en double dans $f (relancer xcodegen et vérifier project.yml)"
done

# 2 bis. Liste des domaines de logos du Worker alignée sur l'annuaire de l'app
echo; echo "2 bis. Liste des domaines de logos"
python3 scripts/gen-logo-allowlist.py --check | sed 's/^/   /'
[ "${PIPESTATUS[0]}" -eq 0 ] || echec "liste des domaines de logos périmée (python3 scripts/gen-logo-allowlist.py)"

# 3. Builds
construire() {   # $1 = Debug | Release
    local conf=$1 journal="$JOURNAUX/build-$1.log" t0 statut erreurs avertissements
    t0=$(date +%s)
    printf "   %-8s… " "$conf"
    xcodebuild -project Ando.xcodeproj -scheme Ando \
        -destination 'generic/platform=iOS Simulator' \
        -configuration "$conf" build > "$journal" 2>&1
    statut=$?
    # Diagnostics uniques (le compilateur répète chaque message sous une forme indentée)
    erreurs=$(grep -E '^[^ ].*: error: |^xcodebuild: error' "$journal" | sort -u)
    avertissements=$(grep -E '^[^ ].*: warning: ' "$journal" | grep -v appintentsmetadataprocessor | sort -u)
    local ne nw
    ne=$(printf "%s" "$erreurs" | grep -c . ) ; nw=$(printf "%s" "$avertissements" | grep -c . )
    local etat=OK; [ "$statut" -eq 0 ] || etat=ÉCHEC
    echo "$etat | erreurs : $ne | avertissements : $nw | $(( $(date +%s) - t0 )) s"
    if [ "$statut" -ne 0 ] || [ "$ne" -gt 0 ] || [ "$nw" -gt 0 ]; then
        [ -n "$erreurs" ] && printf "%s\n" "$erreurs" | head -20 | sed 's/^/     ✗ /'
        [ -n "$avertissements" ] && printf "%s\n" "$avertissements" | head -20 | sed 's/^/     ⚠ /'
        [ "$statut" -ne 0 ] && [ "$ne" -eq 0 ] && tail -15 "$journal" | sed 's/^/     | /'
        echo "     Journal complet : $journal"
        echec "build $conf non conforme (0 erreur / 0 avertissement exigés)"
    fi
}

echo; echo "3. Builds (journaux dans $JOURNAUX)"
construire Debug
[ "$MODE" = complet ] && construire Release

# 4. Tests unitaires des moteurs financiers (Debug seulement : même code)
if [ "$MODE" = complet ]; then
    echo; echo "4. Tests unitaires"
    journal="$JOURNAUX/tests.log"
    t0=$(date +%s)
    printf "   moteurs… "
    xcodebuild test -project Ando.xcodeproj -scheme Ando \
        -destination "platform=iOS Simulator,id=$SIMULATEUR" \
        -only-testing:AndoTests > "$journal" 2>&1
    statut=$?
    resume=$(grep -oE "Executed [0-9]+ tests?, with [0-9]+ failures?" "$journal" | tail -1)
    echo "${resume:-aucun résultat} | $(( $(date +%s) - t0 )) s"
    if [ "$statut" -ne 0 ]; then
        grep -E "error:|XCTAssert.*failed|failed -" "$journal" | sort -u | head -12 | sed 's/^/     ✗ /'
        echo "     Journal complet : $journal"
        echec "des tests unitaires échouent"
    fi
fi

# 5. Le code ne doit pas avoir changé pendant la vérification
[ "$(empreinte_build)" = "$EMPREINTE_AVANT" ] \
    || echec "des fichiers ont changé pendant la vérification ; relancer scripts/verify.sh"

DUREE=$(( $(date +%s) - DEBUT ))
echo
if [ "$MODE" = complet ]; then
    printf "%s %s %s\n" "$EMPREINTE_AVANT" "$(date '+%Y-%m-%d %H:%M')" "$(git rev-parse --short HEAD)" > "$TAMPON_VERIFICATION"
    echo "✓ Vérification complète réussie en ${DUREE} s. Commit autorisé pour cet état du code."
else
    echo "✓ Vérification rapide réussie en ${DUREE} s (Debug seulement)."
    echo "  Pour committer, lancer la vérification complète : scripts/verify.sh"
fi

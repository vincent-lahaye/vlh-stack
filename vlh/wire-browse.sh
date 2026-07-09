#!/bin/sh
# vlh-stack — active gstack/browse PROPREMENT : build standalone (jamais de
# binaire committé) + symlink du skill browse. Opt-in (le build compile un
# binaire ~95 Mo). vlh-owned, ne touche pas au source vendorisé.
#
# On ne vendorise QUE browse (vendor/gstack-browse), pas tout gstack : browse est
# source-autonome (0 import hors browse/) et se compile seul depuis un
# package.json minimal (playwright/diff/socks). Voir vendor/gstack-browse/VENDORED.md.
set -eu

HERE="$(cd "$(dirname "$0")/.." && pwd)"
VENDOR="$HERE/vendor/gstack-browse"
TARGET="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"

log(){ printf '\033[36m[vlh-browse]\033[0m %s\n' "$1"; }
die(){ printf '\033[31m[vlh-browse] ERREUR:\033[0m %s\n' "$1" >&2; exit 1; }

command -v bun >/dev/null 2>&1 || die "bun requis (plancher deps.json)."
[ -d "$VENDOR/browse" ] || die "vendor/gstack-browse/browse introuvable."

# 1. build standalone (compile browse/dist/browse — gitignoré, jamais committé)
log "build standalone de browse (bun install && bun run build)…"
( cd "$VENDOR" && bun install --silent && bun run build )
[ -x "$VENDOR/browse/dist/browse" ] || die "binaire browse non produit après build."

# 2. active le skill browse (symlink), idempotent, anti-collision
mkdir -p "$TARGET"
if [ -e "$TARGET/browse" ] && [ ! -L "$TARGET/browse" ]; then
  die "collision : $TARGET/browse existe et n'est pas un symlink géré."
fi
rm -f "$TARGET/browse"
ln -s "$VENDOR/browse" "$TARGET/browse"
log "browse activé → $TARGET/browse (binaire: $VENDOR/browse/dist/browse)"

# 3. runtime : browse lance le Chromium de Playwright. S'il manque, l'installer :
#    bunx playwright install chromium   (ou pointer un Chromium système via l'env
#    que browse expose). Non fait ici — affaire de l'env consommateur.
log "note : au runtime, browse a besoin d'un Chromium (Playwright ou système)."

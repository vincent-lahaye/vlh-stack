#!/bin/sh
# vlh-stack — active les skills vendorisés listés dans vlh/active-skills.txt en
# les symlinkant dans le dossier de skills de Claude. Vlh-OWNED : ne touche PAS
# au src/ d'OMC (→ 0 conflit de merge amont). Lancé par install.sh APRÈS omc setup.
#
# Idempotent : re-symlinke sans erreur, ne clobbe jamais un dossier existant
# non-géré (collision → on prévient et on saute).
set -eu

HERE="$(cd "$(dirname "$0")/.." && pwd)"          # racine du fork
MANIFEST="$HERE/vlh/active-skills.txt"
TARGET="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}" # surcouchable pour les tests

log() { printf '\033[36m[vlh-activate]\033[0m %s\n' "$1"; }
warn(){ printf '\033[33m[vlh-activate] ATTENTION:\033[0m %s\n' "$1" >&2; }

[ -f "$MANIFEST" ] || { warn "manifeste absent: $MANIFEST"; exit 0; }
mkdir -p "$TARGET"

n_ok=0; n_skip=0; n_miss=0
while IFS= read -r line; do
  # ignore commentaires + lignes vides
  case "$line" in ''|\#*) continue ;; esac
  rel=$(printf '%s' "$line" | sed 's/[[:space:]]*$//')   # trim droite
  src="$HERE/vendor/$rel"
  name=$(basename "$rel")
  dst="$TARGET/$name"

  if [ ! -d "$src" ]; then
    warn "source introuvable, sautée : vendor/$rel"; n_miss=$((n_miss+1)); continue
  fi
  if [ -L "$dst" ]; then
    # déjà un symlink : on le refait pointer (idempotent)
    rm -f "$dst"; ln -s "$src" "$dst"; n_ok=$((n_ok+1)); continue
  fi
  if [ -e "$dst" ]; then
    warn "collision (dossier existant non-géré), sautée : $name"; n_skip=$((n_skip+1)); continue
  fi
  ln -s "$src" "$dst"; n_ok=$((n_ok+1))
done < "$MANIFEST"

log "activés: $n_ok · sautés(collision): $n_skip · sources manquantes: $n_miss · cible: $TARGET"

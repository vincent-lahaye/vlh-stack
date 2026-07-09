#!/bin/sh
# vlh-stack — installeur auto-suffisant (étage 1 : plancher système).
# POSIX sh volontairement : doit tourner sur une base NUE avant que node existe.
# Lit deps.json, pose node/git/tmux/curl, puis passe la main au setup node (étage 2).
#
# Plancher irréductible : un shell POSIX + la capacité d'installer des paquets
# (root ou sudo). Sans droits, on s'arrête avec un message clair — pas de contournement.
set -eu

HERE="$(cd "$(dirname "$0")" && pwd)"
DEPS="$HERE/deps.json"

log()  { printf '\033[36m[vlh-stack]\033[0m %s\n' "$1"; }
die()  { printf '\033[31m[vlh-stack] ERREUR:\033[0m %s\n' "$1" >&2; exit 1; }

# --- privilège --------------------------------------------------------------
if [ "$(id -u)" = "0" ]; then SUDO=""
elif command -v sudo >/dev/null 2>&1; then SUDO="sudo"
else die "ni root ni sudo — impossible d'installer les paquets système. Fournissez tmux/node/git en amont, ou lancez en root."
fi

# --- gestionnaire de paquets ------------------------------------------------
if   command -v apt-get >/dev/null 2>&1; then PM="apt"
elif command -v apk     >/dev/null 2>&1; then PM="apk"
elif command -v dnf     >/dev/null 2>&1; then PM="dnf"
else die "gestionnaire de paquets non reconnu (apt/apk/dnf attendus). Étendez deps.json + ce bloc."
fi
log "gestionnaire détecté : $PM ; privilège : ${SUDO:-root}"

pm_install() { # $@ = noms de paquets déjà résolus pour ce PM
  case "$PM" in
    apt) $SUDO apt-get update -qq && $SUDO apt-get install -y -qq "$@" ;;
    apk) $SUDO apk add --no-cache "$@" ;;
    dnf) $SUDO dnf install -y -q "$@" ;;
  esac
}

# jq n'existe pas forcément sur une base nue → on lit deps.json avec node si dispo,
# sinon un mini-parse. Ici (étage 1) on installe d'abord de quoi lire proprement.
need() { command -v "$1" >/dev/null 2>&1; }

# --- 1. curl/git (nécessaires à la suite) -----------------------------------
need curl || { log "curl absent → installation"; pm_install curl; }
need git  || { log "git absent → installation";  pm_install git; }

# --- 2. node (plancher d'amorçage) ------------------------------------------
if need node; then
  log "node présent : $(node -v)"
else
  log "node absent → installation"
  case "$PM" in
    apt) curl -fsSL https://deb.nodesource.com/setup_20.x | $SUDO -E sh - && pm_install nodejs ;;
    apk) pm_install nodejs npm ;;
    dnf) pm_install nodejs npm ;;
  esac
fi
need npm || die "npm indisponible après installation de node."

# --- 3. paquets système du manifeste (tmux, …) ------------------------------
# node est là → on lit deps.json proprement pour résoudre les noms par PM.
SYS_PKGS="$(node -e '
  const d=require(process.argv[1]).system.packages, pm=process.argv[2];
  console.log(Object.values(d).map(p=>p[pm]).filter(Boolean).join(" "));
' "$DEPS" "$PM")"
if [ -n "$SYS_PKGS" ]; then
  log "paquets système requis : $SYS_PKGS (les présents sont ignorés par le PM)"
  # shellcheck disable=SC2086
  pm_install $SYS_PKGS
fi

# --- 4. build du fork (OMC = TypeScript compilé : dist/ vient de src/) --------
# Rebrand extérieur seulement → on garde l'entrée `omc` (bin/oh-my-claudecode.js).
if [ ! -d "$HERE/dist" ] || [ "$HERE/package.json" -nt "$HERE/dist" ]; then
  log "build du fork (npm ci && npm run build)…"
  ( cd "$HERE" && npm ci --no-audit --no-fund && npm run build )
else
  log "dist/ à jour — build sauté"
fi

# --- 5. étage 2 : setup node (CLI npm gemini/codex, subtrees, symlinks ~/.claude)
# `--link` s'appuie sur le mode devpath EXISTANT d'OMC (symlink dans launch.ts /
# installer), à confirmer sur le fork buildé — pas de code --link en double.
log "plancher OK → étage 2 : omc setup $*"
node "$HERE/bin/oh-my-claudecode.js" setup "$@"

# --- 6. étage 3 : browse (opt-in — le build est lourd) -----------------------
# gstack/browse vendorisé seul (vendor/gstack-browse). Activé sur demande via
# VLH_WITH_BROWSE=1 (ou `--with-browse`), car son build compile un binaire ~95 Mo.
case " $* " in *" --with-browse "*) VLH_WITH_BROWSE=1 ;; esac
if [ "${VLH_WITH_BROWSE:-0}" = "1" ]; then
  log "étage 3 : câblage de browse…"
  sh "$HERE/vlh/wire-browse.sh"
else
  log "browse non câblé (opt-in : VLH_WITH_BROWSE=1 ou --with-browse). Setup terminé."
fi

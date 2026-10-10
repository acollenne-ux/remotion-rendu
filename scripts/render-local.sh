#!/usr/bin/env bash
# Rendu vidéo Remotion en local (fallback hors cloud).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

usage() {
  cat <<'EOF'
Usage : scripts/render-local.sh [options] [composition-id] [output]

Arguments positionnels (optionnels) :
  composition-id   ID de la composition (défaut : Demo)
  output           Fichier de sortie   (défaut : out/demo.mp4)

Options :
  -f, --frames <plage>     Plage de frames, ex: 0-49
  -p, --props <json|fich>  Props JSON en ligne ou chemin vers un fichier JSON
  -c, --concurrency <n>    Nombre de rendus parallèles
      --dry-run            Affiche la commande sans l'exécuter
  -h, --help               Affiche cette aide

Exemples :
  scripts/render-local.sh
  scripts/render-local.sh Demo out/preview.mp4 --frames 0-29
  scripts/render-local.sh Demo out/v2.mp4 --props '{"title":"Salut"}' --concurrency 4
EOF
}

COMPOSITION=""
OUTPUT=""
FRAMES=""
PROPS=""
CONCURRENCY=""
DRY_RUN=0

while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    -f|--frames) [ $# -ge 2 ] || { echo "ERREUR : --frames attend une valeur" >&2; exit 2; }; FRAMES="$2"; shift 2 ;;
    -p|--props)  [ $# -ge 2 ] || { echo "ERREUR : --props attend une valeur" >&2; exit 2; }; PROPS="$2"; shift 2 ;;
    -c|--concurrency) [ $# -ge 2 ] || { echo "ERREUR : --concurrency attend une valeur" >&2; exit 2; }; CONCURRENCY="$2"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    -*) echo "ERREUR : option inconnue '$1'" >&2; usage >&2; exit 2 ;;
    *)
      if [ -z "$COMPOSITION" ]; then COMPOSITION="$1"
      elif [ -z "$OUTPUT" ]; then OUTPUT="$1"
      else echo "ERREUR : argument superflu '$1'" >&2; exit 2
      fi
      shift
      ;;
  esac
done

COMPOSITION="${COMPOSITION:-Demo}"
OUTPUT="${OUTPUT:-out/demo.mp4}"

cd "$PROJECT_DIR"

# --- Prérequis -------------------------------------------------------------
if [ ! -d node_modules ]; then
  echo "ERREUR : node_modules introuvable dans $PROJECT_DIR." >&2
  echo "         Exécutez d'abord : npm ci" >&2
  exit 1
fi
if [ ! -x node_modules/.bin/remotion ]; then
  echo "ERREUR : le binaire 'remotion' est absent de node_modules/.bin." >&2
  echo "         Exécutez d'abord : npm ci" >&2
  exit 1
fi

# --- Construction de la commande -------------------------------------------
cmd=(npx remotion render "$COMPOSITION" "$OUTPUT" --overwrite)

if [ -n "$FRAMES" ]; then
  cmd+=(--frames "$FRAMES")
fi

if [ -n "$CONCURRENCY" ]; then
  cmd+=(--concurrency "$CONCURRENCY")
fi

if [ -n "$PROPS" ]; then
  # --props accepte soit un chemin de fichier, soit une chaîne JSON littérale :
  # dans les deux cas on transmet la valeur telle quelle à Remotion.
  cmd+=(--props "$PROPS")
fi

echo "Rendu de la composition '$COMPOSITION' → $OUTPUT"
if [ "$DRY_RUN" -eq 1 ]; then
  printf 'DRY-RUN :'
  printf ' %q' "${cmd[@]}"
  printf '\n'
  exit 0
fi

"${cmd[@]}"

# --- Rapport ----------------------------------------------------------------
if [ ! -f "$OUTPUT" ]; then
  echo "ERREUR : le fichier attendu '$OUTPUT' n'a pas été produit." >&2
  exit 1
fi

size="$(stat -c '%s' "$OUTPUT" 2>/dev/null || stat -f '%z' "$OUTPUT")"
human="$(du -h "$OUTPUT" | cut -f1)"
echo ""
echo "Fichier produit : $PROJECT_DIR/$OUTPUT"
echo "Taille          : $human ($size octets)"

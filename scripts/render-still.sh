#!/usr/bin/env bash
# Rendu d'une image fixe (still) Remotion en local.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

usage() {
  cat <<'EOF'
Usage : scripts/render-still.sh [options] [composition-id] [output]

Arguments positionnels (optionnels) :
  composition-id   ID de la composition (défaut : Demo)
  output           Fichier image de sortie (défaut : out/still.png)

Options :
  -b, --frame <n>          Numéro de frame à rendre (défaut : 0)
  -p, --props <json|fich>  Props JSON en ligne ou chemin vers un fichier JSON
  -i, --image-format <fmt> png | jpeg (défaut : png, voir remotion.config.ts)
  -s, --scale <n>          Échelle du still, ex: 0.5
      --dry-run            Affiche la commande sans l'exécuter
  -h, --help               Affiche cette aide

Exemples :
  scripts/render-still.sh
  scripts/render-still.sh Demo out/preview.png --frame 42
  scripts/render-still.sh Demo out/couverture.jpg --frame 10 --image-format jpeg
EOF
}

COMPOSITION=""
OUTPUT=""
FRAME=""
PROPS=""
IMAGE_FORMAT=""
SCALE=""
DRY_RUN=0

while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    -b|--frame) [ $# -ge 2 ] || { echo "ERREUR : --frame attend une valeur" >&2; exit 2; }; FRAME="$2"; shift 2 ;;
    -p|--props) [ $# -ge 2 ] || { echo "ERREUR : --props attend une valeur" >&2; exit 2; }; PROPS="$2"; shift 2 ;;
    -i|--image-format) [ $# -ge 2 ] || { echo "ERREUR : --image-format attend une valeur" >&2; exit 2; }; IMAGE_FORMAT="$2"; shift 2 ;;
    -s|--scale) [ $# -ge 2 ] || { echo "ERREUR : --scale attend une valeur" >&2; exit 2; }; SCALE="$2"; shift 2 ;;
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
OUTPUT="${OUTPUT:-out/still.png}"

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
cmd=(npx remotion still "$COMPOSITION" "$OUTPUT" --overwrite)

if [ -n "$FRAME" ]; then
  cmd+=(--frame "$FRAME")
fi
if [ -n "$IMAGE_FORMAT" ]; then
  cmd+=(--image-format "$IMAGE_FORMAT")
fi
if [ -n "$SCALE" ]; then
  cmd+=(--scale "$SCALE")
fi
if [ -n "$PROPS" ]; then
  cmd+=(--props "$PROPS")
fi

echo "Rendu d'une image fixe de '$COMPOSITION' → $OUTPUT"
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

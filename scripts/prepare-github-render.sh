#!/usr/bin/env bash
# Vérifie les prérequis avant de pousser ce projet Remotion sur GitHub,
# puis affiche les commandes exactes à exécuter (ce script ne pousse JAMAIS rien).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

usage() {
  cat <<'EOF'
Usage : scripts/prepare-github-render.sh [options]

Contrôle les prérequis du rendu vidéo GitHub Actions et affiche les commandes
de push à exécuter. Ce script n'écrit ni ne pousse rien.

Options :
      --dry-run   Affiche la commande sans effet (compatibilité CI)
  -h, --help      Affiche cette aide

Prérequis rappelés :
  1. Le projet est un dépôt git initialisé.
  2. Un remote GitHub est configuré (origin).
  3. Le dépôt est PUBLIC — indispensable : les minutes GitHub Actions gratuites
     ne sont illimitées QUE sur les dépôts publics (repo privé = quota mensuel).
EOF
}

DRY_RUN=0
while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    --dry-run) DRY_RUN=1; shift ;;
    *) echo "ERREUR : argument inconnu '$1'" >&2; usage >&2; exit 2 ;;
  esac
done

cd "$PROJECT_DIR"
FAIL=0

echo "=== Prérequis rendu GitHub Actions — $PROJECT_DIR ==="
echo ""

# 1. Git initialisé ?
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "[OK]   Dépôt git initialisé."
else
  echo "[MANQUE] Pas de dépôt git ici."
  echo "         -> git init"
  FAIL=1
fi

# 2. Fichier de workflow présent ?
if [ -f .github/workflows/render-video.yml ]; then
  echo "[OK]   Workflow : .github/workflows/render-video.yml"
else
  echo "[MANQUE] Workflow absent : .github/workflows/render-video.yml"
  FAIL=1
fi

# 3. Lockfile présent (nécessaire à `npm ci` dans le workflow) ?
if [ -f package-lock.json ]; then
  echo "[OK]   package-lock.json présent (npm ci fonctionnera)."
else
  echo "[MANQUE] package-lock.json absent -> npm install puis git add package-lock.json"
  FAIL=1
fi

# 4. Remote GitHub configuré ?
REMOTE_URL=""
if REMOTE_URL="$(git remote get-url origin 2>/dev/null)" && [ -n "$REMOTE_URL" ]; then
  echo "[OK]   Remote origin : $REMOTE_URL"
  case "$REMOTE_URL" in
    *github.com*) echo "[OK]   Hébergeur : github.com." ;;
    *) echo "[ATTENTION] Le remote n'est pas sur github.com — le workflow ne s'exécutera pas ailleurs." ;;
  esac
else
  echo "[MANQUE] Aucun remote 'origin'."
  echo "         -> git remote add origin git@github.com:UTILISATEUR/DEPOT.git"
  FAIL=1
fi

# 5. Visibilité du dépôt (public obligatoire pour les minutes gratuites).
echo ""
if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
  VISIBILITY="$(gh repo view --json visibility --jq .visibility 2>/dev/null || echo 'inconnue')"
  if [ "$VISIBILITY" = "PUBLIC" ]; then
    echo "[OK]   Dépôt PUBLIC — minutes GitHub Actions gratuites illimitées."
  else
    echo "[ALERTE] Visibilité du dépôt : $VISIBILITY"
    echo "         Les minutes gratuites ne sont ILLIMITÉES que sur un dépôt PUBLIC."
    echo "         -> gh repo edit --visibility public"
    echo "         (ou Settings -> Danger Zone -> Change visibility, sur github.com)"
  fi
else
  echo "[INFO]  'gh' absent ou non authentifié : visibilité non vérifiable automatiquement."
  echo "        Vérifiez À LA MAIN sur github.com : Settings -> General -> Visibility."
  echo "        ATTENTION : un dépôt PRIVÉ consomme votre quota mensuel de minutes"
  echo "        (2 000 min/mois gratuit) au lieu des minutes gratuites illimitées"
  echo "        réservées aux dépôts PUBLICS."
fi

echo ""
echo "=== Commandes à exécuter (à la main, ce script ne push pas) ==="
cat <<'EOF'

  cd /home/alexandre-collenne/remotion
  git init                                   # seulement si pas encore de dépôt
  git add .github/workflows/render-video.yml scripts/ CLOUD-RENDER.md package.json package-lock.json remotion.config.ts tsconfig.json src/
  git commit -m "Ajout du rendu vidéo GitHub Actions + scripts d'aide"
  git branch -M main
  git remote add origin git@github.com:UTILISATEUR/DEPOT.git
  git push -u origin main

Puis sur github.com : vérifier que le dépôt est PUBLIC (Settings -> General),
puis : Actions -> « Render video » -> Run workflow -> télécharger l'artefact.

EOF

if [ "$DRY_RUN" -eq 1 ]; then
  echo "(dry-run : aucune commande n'a été exécutée par ce script.)"
fi

if [ "$FAIL" -eq 1 ]; then
  echo "RÉSULTAT : prérequis MANQUANTS — corrigez les points [MANQUE] ci-dessus."
  exit 1
fi
echo "RÉSULTAT : prérequis OK, le projet est prêt à être poussé."

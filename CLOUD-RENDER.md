# Rendu vidéo dans le cloud (GitHub Actions)

Guide opérationnel — comment obtenir votre vidéo **gratuitement** dans le cloud, et quoi faire si ça bloque.

## 1. Le principe

Le workflow `.github/workflows/render-video.yml` fait tourner `npx remotion render` sur un
runner GitHub Actions (Ubuntu, Node 22), puis téléverse le MP4 en **artefact** téléchargeable.

**Gratuité** : les minutes GitHub Actions sont **illimitées sur un dépôt PUBLIC**.
Un dépôt **privé** retombe sur le quota gratuit mensuel (2 000 min/mois) → **rendez le dépôt public**.

> Vérifiez sur github.com : `Settings → General → Visibility` → `Public`.
> Depuis un terminal : `gh repo edit --visibility public`.

**Dépôt réel du projet** : <https://github.com/acollenne-ux/remotion-rendu> — créé le 2026-10-11,
visibilité **PUBLIC** vérifiée par `gh repo view --json visibility` → `"visibility":"PUBLIC"`.

## 2. Premier envoi du projet

**Déjà réalisé (2026-10-11)** : dépôt local initialisé sur `main`, remote `origin` =
`https://github.com/acollenne-ux/remotion-rendu.git`, commit initial
`b7ea42d55782937d06ae1fb981878dbd6471442c` (13 fichiers) poussé. La procédure ci-dessous
reste valable pour un nouveau projet ou un re-partage :

```bash
cd /home/alexandre-collenne/remotion
scripts/prepare-github-render.sh        # vérifie git / remote / public / lockfile
```

Puis exécutez les commandes qu'il affiche (`git init` si besoin, `git add …`, `git commit`,
`git remote add origin …`, `git push -u origin main`). Le script ne push **rien** tout seul.

## 3. Lancer un rendu

1. Allez dans l'onglet **Actions** du dépôt GitHub.
2. Cliquez sur **Render video** dans la colonne de gauche.
3. Cliquez sur **Run workflow** et remplissez les champs :

| Champ | Défaut | Rôle |
|---|---|---|
| `composition-id` | `Demo` | ID de la composition à rendre |
| `output` | `video.mp4` | Nom du fichier produit |
| `props` | *(vide)* | Props JSON, ex. `{"title":"Salut"}` |
| `frames` | *(vide)* | Plage de frames, ex. `0-49` (vide = vidéo complète) |

4. Quand le job est vert, ouvrez-le → section **Artifacts** → **Télécharger** le zip
   `rendered-video` (conservé 14 jours) contenant votre fichier.

**Équivalent en ligne de commande** (après `gh auth login`, commandes réellement utilisées
pour le test du 2026-10-11, tout est poussé sur `main`) :

```bash
cd /home/alexandre-collenne/remotion
# 1. déclencher un rendu :
gh workflow run render-video.yml -f composition-id=Demo -f output=video-test.mp4
# 2. récupérer l'identifiant du run fraîchement créé (1re ligne de la liste) :
gh run list --workflow=render-video.yml --limit 1 --json databaseId -q '.[0].databaseId'
# 3. suivre jusqu'au bout (l'identifiant du test réel était 38091567124) :
gh run watch 38091567124 --exit-status --interval 15
# 4. télécharger l'artefact puis vérifier le MP4 :
gh run download 38091567124 -n rendered-video -D out/
file out/video-test.mp4 && stat -c '%s octets' out/video-test.mp4
```

Un rendu automatique au push sur `src/**` est possible : décommentez le bloc `push:`
commenté en tête de `render-video.yml`.

## 3 bis. Test réel effectué (2026-10-11) — preuve de bout en bout

Exécution menée avec le compte `acollenne-ux`, dépôt PUBLIC, sans aucun coût :

| Élément | Valeur mesurée |
|---|---|
| Date | 2026-10-11 00:28:46 → 00:29:33 (UTC+2) |
| Commande de déclenchement exacte | `gh workflow run render-video.yml -f composition-id=Demo -f output=video-test.mp4` |
| Run ID | `38091567124` — <https://github.com/acollenne-ux/remotion-rendu/actions/runs/38091567124> |
| Statut | `completed` / **`success`** (job « Render video » : succès) |
| Durée totale du run | **47 s** |
| Étapes | Checkout ✓ · Setup Node 22 ✓ · `npm ci` ✓ · `browser ensure` ✓ · Render ✓ · Report ✓ · Upload ✓ |
| Artefact | `rendered-video`, 313 159 o zippé, rétention 14 j, non expiré |
| Commande de téléchargement | `gh run download 38091567124 -n rendered-video -D out/` |
| Fichier produit | `out/video-test.mp4` |
| `file` | `ISO Media, MP4 Base Media v1 [ISO 14496-12:2003]` |
| Taille | **321 713 octets (315 Ko)** — seuil 50 Ko franchi |
| Contenu vérifié (`ffprobe`) | H.264, 1920×1080, 30 i/s, durée 5,000 s |
| sha256 | `8a6465e85e3a4b902936299874e120132307dda618f6ed3c87ff7e0961eaffc7` |

Anomalie non bloquante observée : deux annotations GitHub Actions sur ce run — dépréciation
de `Node.js 20` pour `actions/checkout@v4`, `setup-node@v4` et `upload-artifact@v4`, et migration
annoncée d'`ubuntu-latest` vers Ubuntu 26 le 19/10/2026. À réévaluer lors des prochaines mises à
jour des `actions/*`.

## 4. Fallback n°1 : rendu local (déjà fonctionnel)

```bash
npm run render:demo                          # → out/demo.mp4
scripts/render-local.sh --help               # options : --frames, --props, --concurrency
scripts/render-local.sh Demo out/preview.mp4 --frames 0-29
scripts/render-still.sh --help               # image fixe
scripts/prepare-github-render.sh --help      # contrôle prérequis avant push
```

Le Chrome Headless Shell est téléchargé automatiquement au premier rendu.

## 5. Fallback n°2 : AWS Lambda (non implémenté ici)

`@remotion/lambda` répartit le rendu sur plusieurs fonctions Lambda en parallèle : c'est le plus
rapide pour les longues vidéos. **Free tier** AWS + rendus courts ≈ coût quasi nul ; au-delà,
l'ordre de grandeur annoncé par Remotion est d'environ **0,017 $/minute de vidéo produite**.
Rien n'est configuré dans ce projet — à prendre en compte seulement si GitHub Actions devient
trop lent (limites : vidéo très longue, ou dépôt passé en privé).

## 6. Licence Remotion

Remotion est **gratuit pour les particuliers et les entreprises de ≤ 3 personnes** (licence
« Free »). Au-delà, une licence commerciale est requise. Au-delà, voir
<https://www.remotion.dev/docs/license/pricing>.

## 7. Dépannage rapide

| Symptôme | Cause probable | Correctif |
|---|---|---|
| Le bouton **Run workflow** n'apparaît pas | Workflow absent de la branche par défaut, ou dépôt vide | Poussez `.github/workflows/render-video.yml` sur `main` |
| `npm ci` échoue | `package-lock.json` manquant/désynchronisé | `npm install` puis commit du lockfile |
| Erreur de navigateur au rendu | Chrome Headless Shell non téléchargé | L'étape `npx remotion browser ensure` du workflow le fait déjà |
| Composition introuvable | Mauvais `composition-id` | Utilisez `Demo` (voir `src/Root.tsx`) |
| Minutes consommées vite | Dépôt **privé** | Passez le dépôt en **public** |

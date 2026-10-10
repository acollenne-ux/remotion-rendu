# Rendu vidéo dans le cloud (GitHub Actions)

Guide opérationnel — comment obtenir votre vidéo **gratuitement** dans le cloud, et quoi faire si ça bloque.

## 1. Le principe

Le workflow `.github/workflows/render-video.yml` fait tourner `npx remotion render` sur un
runner GitHub Actions (Ubuntu, Node 22), puis téléverse le MP4 en **artefact** téléchargeable.

**Gratuité** : les minutes GitHub Actions sont **illimitées sur un dépôt PUBLIC**.
Un dépôt **privé** retombe sur le quota gratuit mensuel (2 000 min/mois) → **rendez le dépôt public**.

> Vérifiez sur github.com : `Settings → General → Visibility` → `Public`.
> Depuis un terminal : `gh repo edit --visibility public`.

## 2. Premier envoi du projet

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

Un rendu automatique au push sur `src/**` est possible : décommentez le bloc `push:`
commenté en tête de `render-video.yml`.

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

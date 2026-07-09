# vendor/ — dépendances vendorisées EN DUR (registre de provenance)

Doctrine : maîtrise totale de la chaîne d'appro. Tout dépôt tiers est **copié en
dur** (subtree, dépôt entier) et **épinglé à un SHA**. **Aucun auto-update.**
Mise à jour manuelle, trimestrielle, décidée explicitement, après revue du diff amont.

## Inventaire

| Préfixe | Source amont | SHA épinglé | Licence | Copyleft ? | Vendorisé le |
|---|---|---|---|---|---|
| `vendor/garrytan-gstack` | https://github.com/garrytan/gstack | `11de390be1be6849eb9a15f91ff4922dd16c589a` | MIT © Garry Tan | non | 2026-07-09 |
| `vendor/mattpocock-skills` | https://github.com/mattpocock/skills | `d574778f94cf620fcc8ce741584093bc650a61d3` | MIT © Matt Pocock | non | 2026-07-09 |

Chaque dépôt conserve son propre `LICENSE` (obligation MIT : attribution + notice).

## Écarté (NE PAS vendoriser)

- **christianreiss/codex-orchestrator** — **GPL-3.0 (copyleft → contaminerait la
  stack MIT)** ET objet sans rapport (appli web PHP/Docker de gestion d'auth Codex
  multi-hôtes, pas un working-mode Claude). Rien à voir avec le skill
  `orchestrate-codex`, qui est maison (voir ci-dessous).

## Non-vendorisé (maison)

- `skills/orchestrate-codex` — skill **écrit maison** (à l'origine dans Brume),
  copié ici, pas un tiers. ⚠️ à généraliser un poil (retirer les références au
  devcontainer Brume `.devcontainer/.codex-data`).

## Patch local à ré-évaluer au wiring

Le pipeline Brume appliquait à gstack un patch **Chromium executablePath**
(`BROWSE_CHROME_PATH`/`BUN_CHROME_PATH` dans `browse/src/browser-manager.ts`) pour
utiliser le Chromium système au lieu de télécharger un navigateur Playwright. Il
portait sur un pin plus ancien (`ef0d3195`). À réévaluer/ré-appliquer contre CE
HEAD au moment de câbler `browse`. NE PAS appliquer à l'aveugle.

## Mettre à jour une brique (manuel, trimestriel)

`git-subtree` n'est pas sur le PATH par défaut ici → l'ajouter :
`cp /usr/share/doc/git/contrib/subtree/git-subtree.sh ~/.local/bin/git-subtree && chmod +x $_`

Puis, après avoir revu le diff amont `<ancien-sha>..<nouveau-sha>` :
```
git subtree pull --prefix=vendor/<x> <url> <nouveau-sha> --squash
```
Mettre à jour la ligne du tableau ci-dessus (SHA + date).

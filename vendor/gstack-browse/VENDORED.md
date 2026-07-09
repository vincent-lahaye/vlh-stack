# vendor/gstack-browse — `browse` seul, vendorisé (registre de provenance)

On ne garde de gstack **que `browse`** (le CLI navigateur headless — l'atome
portable et réutilisable). Le reste de gstack (58 autres skills, workflow très
spécifique à Garry Tan + couplé à son runtime) n'est **pas** vendorisé.

`browse` est **source-autonome** : `browse/src` n'importe **rien** hors de
`browse/` (vérifié), et se compile isolément (`bun build --compile
browse/src/cli.ts`). Deps npm réelles : `playwright`, `diff`, `socks` (le reste
= builtins node/bun). D'où le `package.json` minimal ci-contre.

| Champ | Valeur |
|---|---|
| Source amont | https://github.com/garrytan/gstack (sous-dossier `browse/`) |
| SHA gstack épinglé | `11de390be1be6849eb9a15f91ff4922dd16c589a` |
| Licence | MIT © Garry Tan (voir `LICENSE`) |
| Copyleft ? | non |
| Vendorisé le | 2026-07-09 |

## Build (jamais de binaire committé)

`browse/dist/` (binaire bun compilé, ~95 Mo, spécifique plateforme) est **gitignoré
et jamais committé**. Il se build à l'install :

```
cd vendor/gstack-browse && bun install && bun run build
# → produit browse/dist/browse (+ le bundle node server)
```

Chromium : browse utilise le Chromium de Playwright (défaut). Un env contraint
peut pointer un Chromium système via les variables que browse expose — affaire de
l'env consommateur, pas figée ici. **Pas de patch du source** (contrairement au
contournement historique du devcontainer Brume).

## Mise à jour (manuelle, pinnée)

Re-copier `browse/` depuis un nouveau SHA de `garrytan/gstack`, réviser le diff,
mettre à jour le SHA + la date ci-dessus. Re-vérifier les deps npm de `browse/src`.

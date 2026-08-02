<!-- Langue : [English](../../examples/web-architect-ts/README.md) · Français -->

# Exemple — Claude Code pour un architecte web/app TypeScript

Une configuration Claude Code **concrète et prête à copier**, taillée pour un
profil réaliste : un architecte web qui construit un produit multiplateforme en
TypeScript.

Les fichiers de configuration se trouvent dans
[`examples/web-architect-ts/`](../../examples/web-architect-ts/) (en anglais, pour
être déposés tels quels dans un vrai dépôt). Cette page en résume l'intention en
français.

> Elle applique les principes de [rules-and-skills.md](rules-and-skills.md) à une
> vraie stack : un **`CLAUDE.md` léger toujours actif**, des **rules limitées par
> chemin** qui ne se chargent que quand c'est pertinent, et des
> **commandes/skills** pour le travail répétable — plutôt qu'un énorme fichier de
> règles toujours actif.

## Le profil visé

| Domaine | Stack / contrainte |
|---------|--------------------|
| Langage | JavaScript avec **TypeScript** partout — y compris les scripts d'outillage. |
| Frontend | **Vue 3** en TS, **Quasar** en TS. |
| Backend | **NestJS** en TS, **API REST**. |
| Desktop | **Electron** en TS (base Quasar), livré sur **Windows / macOS / Linux**. |
| Outillage | Scripts de config en TS ; équipe multiplateforme → scripts **cross-platform et rétrocompatibles**. |
| Gestionnaire de paquets | **Migration npm → yarn** en cours, *pas terminée à 100 %* (état mixte). |
| Tests | Pragmatique — un test doit **mériter sa place** (ici on saute les tests sous la pression). |
| VCS | git. |

Organisation monorepo supposée (à adapter) :

```text
apps/
├── web/        # Vue 3 + Quasar (navigateur)
├── desktop/    # Electron (Quasar mode electron)
└── api/        # API REST NestJS
packages/       # bibliothèques TS partagées (types, utils)
scripts/        # scripts d'outillage TS (multiplateformes)
```

## Ce que contient l'exemple

```text
web-architect-ts/
├── CLAUDE.md                    # Mémoire toujours active, légère (socle commun)
└── .claude/
    ├── settings.json            # Permissions yarn/npm/git + hook de formatage
    ├── rules/                   # Limitées par chemin — ne se chargent que si pertinent
    │   ├── typescript.md        # **/*.ts — TS + scripts multiplateformes
    │   ├── vue-quasar.md        # apps/web + *.vue — règles frontend
    │   ├── nestjs-api.md        # apps/api — règles REST/NestJS
    │   ├── electron.md          # apps/desktop — desktop multiplateforme
    │   ├── package-manager.md   # toujours active — politique de migration yarn
    │   └── testing.md           # fichiers de test — politique de test pragmatique
    ├── commands/
    │   ├── new-endpoint.md      # /new-endpoint — scaffold d'une ressource REST NestJS
    │   └── migrate-to-yarn.md   # /migrate-to-yarn — npm → yarn pour un paquet
    └── skills/
        └── cross-platform-script/
            └── SKILL.md         # Écrire un script d'outillage TS Win/mac/Linux
```

## Comment l'utiliser

1. Copiez `CLAUDE.md` et `.claude/` à la racine de votre dépôt.
2. **Adaptez les chemins** dans `CLAUDE.md` et dans la frontmatter `paths:` de
   chaque `rules/*.md`.
3. Élaguez ce qui ne correspond pas à votre réalité — c'est un point de départ.
4. Versionnez `.claude/` et `CLAUDE.md` ; gitignorez `.claude/settings.local.json`.

## Pourquoi cette structure

- **`CLAUDE.md` reste minuscule** — seulement le socle toujours vrai. Tout le
  spécifique est une **rule limitée par chemin** : les règles Vue ne coûtent pas de
  tokens quand Claude édite l'API NestJS, et inversement. C'est l'optimisation
  centrale : [le contexte n'est pas gratuit](rules-and-skills.md#le-compromis-central--le-contexte-nest-pas-gratuit).
- **La politique de migration yarn est une rule**, pas un savoir tribal — Claude
  choisit le bon gestionnaire par dépôt pendant l'état mixte.
- **Le travail répétable est une commande/skill** — `/new-endpoint`,
  `/migrate-to-yarn` et le skill de script multiplateforme se chargent à la
  demande au lieu d'alourdir chaque invite.

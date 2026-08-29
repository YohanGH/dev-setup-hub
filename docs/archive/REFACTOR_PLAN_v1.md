> **Premier tour de refactorisation — terminé, archivé pour mémoire.**
>
> Phases 0 à 7, du 2026-08-29. Dix commits, de `3db5e7d` à `c567966`.
> Deux constats de cette analyse se sont révélés faux et sont corrigés en
> place (dates d'en-tête, `community-plugins.json`).
>
> Le tour en cours est dans [`../../REFACTOR_PLAN.md`](../../REFACTOR_PLAN.md).

---

# Analyse & plan de refactorisation — dev-setup-hub

> Document de travail, non versionné pour l'instant. À supprimer ou déplacer
> dans `docs/` une fois la refactorisation terminée.
>
> Base : `TASK.md` (~/Documents/Dev/TASK.md) — analyse du 2026-08-29, HEAD `326824d`.

---

## 1. Analyse

### 1.1 Ce qu'est le dépôt aujourd'hui

`dev-setup-hub` est un **monorepo par git-subtree** : 5 anciens dépôts repliés via
`git subtree` (remotes `src_vim`, `src_zsh`, `src_headers`, `src_obsidian`,
`src_setup`) puis 3 imports récents (`debian/`, `halo/`, `claude/`).
Pas de `.gitmodules` — ce sont bien des subtrees, pas des sous-modules.

Résultat : 9 répertoires racine, 335 fichiers, ~24 Mo sur disque, ~9,5 Mo de `.git`.

```
dev-setup-hub/
├── claude/     936K   ← copie figée de YohanGH/claude-config
├── debian/     232K   ← mini-monorepo qui re-vendorise vim/zsh/header
├── halo/       312K   ← application Rust, Linux-only
├── headers/     12K
├── obsidian/    23M   ← dont 22M de plugins tiers compilés
├── setup/       28K   ← script macOS cassé
├── shell/       32K
├── vim/        132K
└── vscode/      16K
```

### 1.2 Problèmes identifiés

#### 🔴 P1 — Triple duplication, aucune source de vérité

L'import de `debian/` a introduit un second exemplaire de configs déjà présentes
à la racine, parce que `Configuration_Debian` était lui-même un mini-monorepo :

| Config | Copie A | Copie B | Copie C | État |
|---|---|---|---|---|
| zsh | `shell/` | `debian/Configuration_zshrc/` | — | **identiques octet pour octet** |
| header | `headers/` | `debian/Configuration_Header/` | `debian/scripts/assets/stdheader.vim` | A ≡ B, **C diverge** |
| vim | `vim/` | `debian/Configuration_Vim/` | — | `syntax/` identique, **`.vimrc` diverge** |

Empreintes du header : `a3fee685…` (A et B) vs `a02f7129…` (C).

Conséquence concrète : modifier `shell/zshrc` ne corrige rien sous Debian, car
`debian/scripts/init_debian.sh` lit dans `debian/Configuration_zshrc/`. Il y a
littéralement deux vérités pour le `.vimrc` et deux pour le header.

#### 🔴 P2 — L'axe « OS » est modélisé comme un dossier, pas comme une couche

`debian/` est une **plateforme**, mais il est rangé au même niveau que `vim/` et
`shell/` qui sont des **outils**. Il n'existe aucun `macos/` symétrique : macOS
vit dans `setup/setup-configs.sh`, à ce même niveau encore.

Deux modèles mentaux s'affrontent dans une seule arborescence. C'est exactement
ce qui casse au moment de passer en double OS — ta revendication n°4.

#### 🔴 P3 — `setup/setup-configs.sh` est cassé et périmé

- **Bug d'ordre** : `print_tree` est appelée ligne 229, définie ligne 235 →
  erreur « command not found » sur chacun des 30 dossiers GTD. Le script n'est
  pas en `set -e`, donc il continue en crachant du bruit.
- **Shebang inopérant** : `#!/bin/bash` est en **ligne 13**, après le bloc
  d'en-tête. Le fichier ne fonctionne que lancé explicitement via `bash …`.
- **`echo "\n ----- \n"`** : sous `bash`, affiche un `\n` littéral. Mélange de
  `echo` et `echo -e` d'un bout à l'autre.
- **Boucle** : il clone `Configuration_zshrc` et `Configuration_Vim` **depuis
  GitHub** — c'est-à-dire les dépôts que dev-setup-hub a justement absorbés. Le
  hub installe des copies périmées de lui-même.
- `check_success` teste parfois le `$?` du `echo` qui précède, pas de la commande utile.
- Il crée une arborescence GTD en dur dans `~/Documents/GTD`, hors sujet pour un
  setup de dev.

#### 🟠 P4 — Pas de point d'entrée, pas de CI

Aucun `install.sh` à la racine. Le seul orchestrateur est
`debian/scripts/install.sh` — et il est **bon** : bannière, `confirm()`,
`log/ok/warn` colorés, étapes numérotées `1/4`. C'est la graine à réutiliser
pour ta revendication n°7.

Aucun `.github/workflows/` à la racine (il n'y en a que dans `halo/`).
`CONTRIBUTING.md` référence `profiles/*` et `.env.example` qui n'existent pas.

#### 🟠 P5 — `AUDIT_REPORT.md` est périmé et trompeur

Daté du 2024-12-19. La duplication du README qu'il décrit est corrigée ; les
références `/profiles/` `/git/` `/containers/` ont disparu du README **mais
survivent dans `CONTRIBUTING.md`**. Il est antérieur à `debian/`, `halo/` et
`claude/`. Le garder à la racine induit en erreur.

#### 🟠 P6 — Halo n'a pas sa place ici (et il n'y a pas d'API à appeler)

- C'est une **application Rust**, pas une config : workspace propre, CI propre,
  `Cargo.lock`, `CLAUDE.md`. 312 Ko qui dériveront en permanence de `YohanGH/Halo`.
- Elle est **Linux-only** (overlay Wayland/X11), en pré-alpha. Sur macOS c'est
  du poids mort.
- **Réponse à ta question sur l'API GitHub : non, pas en l'état.** Vérifié sur
  `api.github.com/repos/YohanGH/Halo` :

  ```
  releases : []        tags : []        has_downloads : false
  ```

  Il n'y a **aucun asset de release à récupérer**. Les seules options à
  l'installation sont donc :
  1. `git clone` + `cargo build --release` → nécessite rustup, plusieurs minutes ;
  2. tarball de `main` via codeload → même problème, il faut compiler ensuite.

  Le vrai « fetch d'un binaire » n'existera qu'une fois un tag posé **et** un
  workflow de release ajouté en amont dans le dépôt Halo.

#### 🟠 P7 — Obsidian embarque 22 Mo de JS tiers compilé

`obsidian/obsidian/plugins/*/main.js` — excalidraw 4,8 Mo, mind-map 3,9 Mo,
graph-analysis 3,4 Mo, table-editor 3,2 Mo, full-calendar 2,4 Mo… Ce sont les
**artefacts de build des projets d'autres personnes**, commités. Ils
représentent 95 % du poids du dépôt et occupent les 10 premières places du
classement des blobs de l'historique. Ils font aussi entrer d'autres licences
dans ton dépôt.

Ta config réelle, elle, tient en quelques Ko : `app.json`, `appearance.json`,
`hotkeys.json`, `community-plugins.json`.

> **Correction (phase 7)** : j'avais écrit ici que `community-plugins.json`
> listait les identifiants et qu'Obsidian saurait retélécharger les plugins
> seul. **C'est faux sur les deux points.** Ce fichier est la liste des plugins
> *activés*, pas une liste d'installation, et Obsidian n'y cherche rien à
> télécharger. Il était de surcroît **vide** (`[]`) alors que quatorze plugins
> étaient présents sur le disque. L'inventaire a donc été relevé depuis les
> `manifest.json` et consigné dans `config/obsidian/plugins.md` avant
> suppression.

#### 🟠 P8 — Le découpage de vim est à moitié fait, et les deux moitiés sont déconnectées

C'est ta branche en cours. État exact :

| | `ankama/vim` (branche `refacto/vim-shortcut`) | `dev-setup-hub/vim/` |
|---|---|---|
| `.vim.base` | 373 l. | 373 l. — **md5 identique** |
| `.vim.shortcut` | 374 l. | 374 l. — **md5 identique** |
| `.vim.functions` | absent | 23 l. (index seul, en cours) |
| `.vim.builder` | vide | vide, **non suivi par git** |
| `.vim.plugins` | vide | vide |
| `vim-builder.sh` | **absent** | présent |
| `.vimrc` | **absent** | monolithe de 1832 lignes |
| remote | **aucun** | — |

Le point bloquant : **`.vimrc` ne contient aucun bloc `vim-builder`**. Les
fragments ne sont donc jamais sourcés — en l'état, le découpage est du code mort
et le monolithe reste seul actif. `vim-builder.sh` corrigerait ça à sa première
exécution, mais il n'a jamais tourné sur ce `.vimrc`.

À noter : `vim-builder.sh` pose un lien symbolique `~/.vimrc` → dépôt, ce qui est
exactement ce que demande `ankama/TASK.md` (« liens relatifs sur ma config pour
avoir une modification en direct »). Le design est bon, il n'est simplement pas
branché.

#### 🟡 P9 — `claude/` duplique un dépôt vivant

`ankama/claude-config` (remote `YohanGH/claude-config`) est **en avance** sur la
copie subtree : il contient `templates/enterprise-monorepo/apps/{routes,services,types}`
que le hub n'a pas. Même problème de dérive que Halo — et tu as déjà tranché :
tu le veux téléchargé, pas vendorisé.

#### 🟡 P10 — Conflit de licence

| Fichier | Licence |
|---|---|
| `LICENSE` (racine) | **GNU GPL v2** |
| `debian/LICENSE.md` | MIT |
| `claude/LICENSE.md` | MIT |
| `halo/LICENSE` | MIT |

Un même dépôt annonce deux licences incompatibles selon le répertoire. À trancher.

#### 🟡 P11 — Cosmétique et cohérence

- ~~En-têtes 42 avec des dates futures fausses.~~ **Constat erroné** : vérifié
  le 2026-08-29, aucune date d'en-tête n'est postérieure à ce jour, et le
  `Created: 2026/07/22` de `debian/` correspond exactement au premier commit du
  dépôt amont `Configuration_Debian`.
- **Trois styles d'ASCII art** différents (le `.--.`, le bateau de `CHANGELOG.md`
  et `List_of_Plugins.md`).
- `SECURITY.md` est encore enveloppé dans une clôture ` ```md ` parasite
  (point n°4 de l'audit de 2024, jamais corrigé).
- Trois adresses e-mail incohérentes : `YohanGH@proton.me` (en-têtes),
  `smockingart_dm@hotmail.com` (SECURITY), `conduct@your-domain.tld`
  (CODE_OF_CONDUCT — placeholder jamais remplacé).
- `setup/README.md` documente un `configs-path.sh` qui n'existe pas, et répète
  trois fois la même section « Utilisation ».

---

## 2. Architecture cible

Le principe directeur : **séparer trois axes qui sont aujourd'hui mélangés.**

| Axe | Question | Où ça vit |
|---|---|---|
| **Quoi** | quels paquets installer | `profiles/*.list` (par OS) |
| **Comment** | quelles étapes exécuter | `install/*.sh` (agnostique OS) |
| **Contenu** | mes fichiers de config | `config/*/` (source unique) |

L'OS devient une **couche d'abstraction** (`lib/os.sh`) et une **liste de
paquets**, plus jamais un répertoire. C'est ce qui permet de remonter au global
tout ce qui est partageable — ta revendication n°10.

```
dev-setup-hub/
├── README.md                  # point d'entrée + procédure pas-à-pas
├── install.sh                 # orchestrateur racine : détecte l'OS, dispatche
│
├── lib/                       # bibliothèque shell partagée
│   ├── ui.sh                  #   bannière, sections, étapes, couleurs
│   ├── os.sh                  #   detect_os / pkg_install / has_cmd
│   └── fs.sh                  #   backup / link / ensure_dir
│
├── profiles/                  # QUOI — déclaratif, par OS
│   ├── common.list
│   ├── macos.list             #   brew
│   └── debian.list            #   apt
│
├── config/                    # CONTENU — source unique, agnostique OS
│   ├── zsh/                   #   ← shell/ + debian/Configuration_zshrc/
│   ├── vim/                   #   ← vim/ + debian/Configuration_Vim/   (cf. décision D1)
│   ├── header/                #   ← headers/ + les 3 copies de stdheader.vim
│   ├── editor/                #   ← vscode/ — servira VSCode ET VSCodium
│   └── obsidian/              #   ← JSON seulement, sans les plugins tiers
│
├── install/                   # COMMENT — une étape = un fichier
│   ├── 00-packages.sh
│   ├── 10-shell.sh
│   ├── 20-vim.sh
│   ├── 30-editor.sh           #   vscodium + vscode, config identique
│   ├── 40-obsidian.sh
│   ├── 50-external.sh         #   claude-config, halo… (fetch, opt-in)
│   └── 99-summary.sh
│
├── external.conf              # dépôts tiers à récupérer, pas à vendoriser
│
├── docs/
│   ├── ARCHITECTURE.md
│   ├── MANUAL.md              #   ce qui reste manuel : navigateurs, Cursor
│   └── archive/AUDIT_REPORT.md
│
└── .github/workflows/ci.yml   # shellcheck + shfmt
```

### 2.1 Le manifeste des sources externes

Un seul mécanisme règle trois de tes revendications d'un coup (vim, claude-config,
halo). Format TSV lisible par un `while read` — pas de dépendance à `yq` :

```
# nom            url                                        destination              plateforme  défaut
claude-config    https://github.com/YohanGH/claude-config    ~/.config/claude-config  all         on
halo             https://github.com/YohanGH/Halo             ~/.local/src/halo        linux       off
```

`install/50-external.sh` lit ce fichier, filtre sur la plateforme courante,
ignore les lignes `off` sauf `--with-<nom>`, et fait un `clone` ou un `pull`
idempotent. Halo y gagne en prime une étape de build `cargo` explicitement
optionnelle et annoncée comme longue.

### 2.2 L'UI terminal (revendication n°7)

`lib/ui.sh` généralise ce que fait déjà `debian/scripts/install.sh`. Rendu visé :

```
╭────────────────────────────────────────────────────────────────╮
│  DEV-SETUP-HUB                                macOS · arm64    │
╰────────────────────────────────────────────────────────────────╯

  ▸ 1/7  Paquets système
  ───────────────────────────────────────────────────────────────
      ✔  git           déjà présent
      ✔  curl          déjà présent
      ⬇  htop          installation…
      ✔  htop          installé
      ⊘  thefuck       ignoré (optionnel, absent du dépôt)

  ▸ 2/7  Shell — zsh
  ───────────────────────────────────────────────────────────────
      ↩  ~/.zshrc      sauvegardé → ~/.zshrc.bak.20260829-1412
      ✔  ~/.zshrc      déployé
```

API : `ui_banner`, `ui_section "2/7" "Shell — zsh"`, `ui_ok`, `ui_warn`,
`ui_skip`, `ui_run`, `ui_confirm`. Dégradation propre si `NO_COLOR` est défini
ou si la sortie n'est pas un TTY.

---

## 3. Plan d'exécution

**Règles de travail** (issues de `TASK.md`) :
- une pause après chaque phase, tu valides avant la suivante ;
- **aucun commit de ma part** — je prépare, tu commites ;
- travail sur une branche dédiée, jamais sur `main`.

### Phase 0 — Filet de sécurité
- Poser un tag `pre-refacto` sur `main`.
- Créer la branche `refacto/architecture`.
- Traiter les 3 fichiers en attente : `obsidian/obsidian/.DS_Store` (supprimé,
  à confirmer + ajouter au `.gitignore`), `vim/.vim.functions` (modifié),
  `vim/.vim.builder` (non suivi).
- Aucun changement de structure.

### Phase 1 — Socle : `lib/` + UI terminal → revendication 7
- `lib/ui.sh`, `lib/os.sh`, `lib/fs.sh`.
- `.github/workflows/ci.yml` : shellcheck + shfmt.
- Aucun changement de comportement : on pose les fondations et on les teste seules.

### Phase 2 — Déduplication : création de `config/` → problèmes P1, P2
- `shell/` + `debian/Configuration_zshrc/` → `config/zsh/` (identiques, fusion triviale).
- `headers/` + `debian/Configuration_Header/` + `debian/scripts/assets/` →
  `config/header/`. Je te présenterai le diff de la 3ᵉ copie divergente avant de trancher.
- `vim/` + `debian/Configuration_Vim/` → `config/vim/` (**D1**), puis
  régénération du `.vimrc` par `vim-builder.sh` et arbitrage du monolithe.
- `vscode/` → `config/editor/`.
- `obsidian/` → `config/obsidian/`.
- Suppression de `debian/Configuration_*`.
- Utilisation de `git mv` pour préserver l'historique.

### Phase 3 — Orchestrateur racine + profils → revendications 3, 4, 10
- `install.sh` racine avec détection d'OS.
- `profiles/{common,macos,debian}.list` construits à partir de
  `~/Documents/Dev/ankama/README.md`, **navigateurs et Cursor exclus**
  (revendication n°5) et renvoyés vers `docs/MANUAL.md`.
- `install/00-packages.sh` … `install/40-obsidian.sh`, qui remplacent à la fois
  `setup/setup-configs.sh` et `debian/scripts/init_debian.sh`.
- Les bugs de P3 disparaissent par remplacement. L'arborescence GTD devient une
  étape optionnelle explicite, ou saute — à confirmer.

### Phase 4 — Sources externes → revendications 1, 2, 6
- `external.conf` + `install/50-external.sh`.
- Retrait des subtrees `halo/` et `claude/`.
- Halo : Linux uniquement, opt-in, clone + build, avec le constat « pas de
  release » écrit noir sur blanc dans la doc. En parallèle, note de suivi pour
  ajouter un workflow de release en amont dans `YohanGH/Halo` — c'est ce qui
  débloquera le vrai fetch d'un binaire plus tard.
- Vim n'est **pas** concerné : il reste dans le hub (D1).

### Phase 5 — VSCodium + VSCode à l'identique → revendication 8
- `config/editor/settings.json` + `keybindings.json`, source unique.
- `install/30-editor.sh` déploie vers les deux, sur les deux OS :

  | | VSCode | VSCodium |
  |---|---|---|
  | macOS | `~/Library/Application Support/Code/User/` | `~/Library/Application Support/VSCodium/User/` |
  | Debian | `~/.config/Code/User/` | `~/.config/VSCodium/User/` |

- `config/editor/extensions.list` → `code --install-extension` /
  `codium --install-extension`, avec les identifiants complets de la marketplace
  (l'actuel `List_of_Plugins.md` ne donne que des noms affichables, inutilisables
  en CLI — il faut les résoudre).

### Phase 6 — Documentation et gouvernance → revendication 9
- README racine : procédure complète, commandes une par une, et le mode
  « tout d'un coup ».
- `docs/MANUAL.md` : navigateurs (Safari, Chrome, Brave) et Cursor, avec liens
  et raison de leur exclusion de l'automatisation.
- `docs/ARCHITECTURE.md` : les trois axes, où ajouter quoi.
- Corrections P11 : clôture parasite de `SECURITY.md`, e-mails harmonisés,
  placeholder du CODE_OF_CONDUCT, `setup/README.md` réécrit.
- **`.editorconfig`** : il impose `indent_style = space` / `indent_size = 2` à
  tous les fichiers, alors que **tous** les scripts shell du dépôt sont en
  tabulations (`init_debian.sh` 53 lignes, `vim-builder.sh` 62, `install.sh` 17).
  Ajouter une section `[*.sh] indent_style = tab`, conforme au défaut de shfmt
  et à ce que la CI vérifie déjà.
- Licence : passage en **MIT** à la racine (**D2**), suppression des
  `LICENSE.md` redondants des sous-arbres.
- `AUDIT_REPORT.md` → `docs/archive/`.
- `CONTRIBUTING.md` réécrit (suppression des références fantômes).

### Phase 7 — Nettoyage final
- Plugins Obsidian : retrait du HEAD, historique préservé (**D3**), plus les
  motifs `.gitignore` qui empêchent leur retour.
- En-têtes 42 : normalisation d'un style unique, correction des dates futures.
- `CHANGELOG.md` → 3.0.0.
- Suppression de ce fichier `REFACTOR_PLAN.md`.

---

## 4. Décisions tranchées (2026-08-29)

### D1 — Vim vit dans le hub, en `config/vim/`
Source unique dans `dev-setup-hub`. `ankama/vim` est supprimé une fois ses
fragments reportés — il n'apporte rien que le hub n'ait déjà (`.vim.base` et
`.vim.shortcut` y sont identiques au bit près), et il lui manque `vim-builder.sh`,
le `.vimrc` et un remote.

Conséquences à traiter en phase 2 :
- reporter `.vim.functions` (23 l., en cours côté hub) et terminer le découpage ;
- **régénérer `.vimrc` via `vim-builder.sh`** pour que les fragments soient enfin
  sourcés — sans ça le découpage reste du code mort (P8) ;
- statuer sur les 1832 lignes du monolithe : ce qui n'est pas encore réparti
  dans `.vim.base` / `.vim.shortcut` / `.vim.functions` / `.vim.plugins` part
  soit dans les fragments, soit dans `docs/archive/vimrc-legacy.vim`.

Vim n'apparaît donc **pas** dans `external.conf` : celui-ci ne servira qu'à
`claude-config` et `halo`.

### D2 — MIT partout
La racine s'aligne sur les trois sous-arbres déjà en MIT. Le `LICENSE` GPL v2 de
18 Ko est remplacé par le texte MIT ; `debian/LICENSE.md`, `claude/LICENSE.md` et
`halo/LICENSE` disparaissent avec leurs sous-arbres ou sont fusionnés.
À traiter en phase 6.

### D3 — Obsidian : retrait du HEAD seulement
`obsidian/obsidian/plugins/*/main.js` et `styles.css` sortent du HEAD ; le
checkout passe de 23 Mo à ~1 Mo. **L'historique n'est pas réécrit** — le `.git`
reste à ~9,5 Mo, aucun SHA ne change, aucun clone n'est invalidé.

On conserve `app.json`, `appearance.json`, `hotkeys.json`, `core-plugins.json`,
`community-plugins.json` et les thèmes maison.

> **Correction (phase 7)** : `community-plugins.json` est la liste des plugins
> **activés**, pas une liste d'installation — et elle était vide. Obsidian ne
> réinstalle rien tout seul. L'inventaire des 14 plugins a donc été relevé dans
> `config/obsidian/plugins.md` avant suppression des binaires. Ajout des motifs correspondants au `.gitignore` pour
éviter que les plugins ne reviennent. À traiter en phase 7.
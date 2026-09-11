# Analyse & plan — second tour

> Document de travail. Base : `~/Documents/Dev/TASK.md`, analyse du 2026-08-29,
> HEAD `c567966` sur `refacto/architecture`.
>
> Le premier tour (phases 0 à 7, structure du dépôt) est archivé dans
> [`docs/archive/REFACTOR_PLAN_v1.md`](docs/archive/REFACTOR_PLAN_v1.md).

---

## 1. Analyse

### A — Identités en dur (demande 1)

Trois catégories, de gravité très inégale.

#### A1 — Le cas grave : `USER` écrasé pour toute la session

`config/zsh/zshrc:164`

```sh
USER=yohangh
export USER
```

Ce n'est pas un défaut cosmétique. `USER` est une variable système lue par
`ssh`, `git`, `sudo`, les scripts d'installation, et le plugin `stdheader.vim`.
Le zshrc est **partagé entre les deux postes** et déployé en lien symbolique :
sur une machine Debian dont le compte ne s'appelle pas `yohangh`, chaque shell
ment sur l'identité de l'utilisateur.

C'est exactement le genre de valeur qui doit vivre dans `~/.zsh_local`, non
versionné — mécanisme déjà en place depuis le premier tour, mais cette ligne
lui est antérieure et n'a pas été reprise.

#### A2 — Domaine de courriel codé en dur dans les scripts

| Fichier | Ligne | Contenu |
|---|---|---|
| `install/20-header.sh` | 46 | `export MAIL="${USER}@proton.me"` |
| `debian/scripts/set_header.sh` | 43 | idem |
| `debian/scripts/set_header.sh` | 60-61 | `g:userName = 'YohanGH'`, `g:mailName = 'YohanGH@proton.me'` |
| `config/header/set_header.sh` | 32 | `echo "MAIL="$USER@proton.me"" >> ~/.zshrc` |

Le dernier est en prime **mal quoté** : les guillemets imbriqués font que la
ligne écrite dans `~/.zshrc` n'est pas celle attendue.

Le login est dynamique (`$USER`), mais le domaine ne l'est pas. Sur un poste
professionnel, l'adresse à faire figurer dans un en-tête n'est pas la même.

#### A3 — En-têtes 42 : ~33 fichiers, et ce n'est pas un défaut

`By: YohanGH <YohanGH@proton.me>` apparaît dans une trentaine d'en-têtes. C'est
une **signature d'auteur dans un fichier versionné**, pas un paramètre
d'exécution : la rendre dynamique n'aurait pas de sens, l'auteur d'un fichier ne
change pas selon la machine qui le lit. Je les laisse.

Reste `debian/scripts/setup_obsidian.sh`, qui écrit `YohanGH` et `ANKAMA` dans
les **documents générés** (mentions de droits d'auteur, tableaux). C'est du
contenu rédigé, pas de la configuration — même raisonnement, on n'y touche pas.

#### Ce que ça appelle

Une source unique d'identité, résolue en cascade :

```
$HUB_USER / $HUB_MAIL          (variables d'environnement, priorité haute)
  → ~/.config/dev-setup-hub/identity   (fichier local, non versionné)
    → git config user.name / user.email
      → id -un  +  domaine demandé une fois
```

Note : ton `git config user.email` vaut aujourd'hui
`151569122+YohanGH@users.noreply.github.com`. C'est l'adresse de confidentialité
GitHub — utilisable pour signer des commits, pas pour un en-tête de fichier. La
cascade doit donc pouvoir être surchargée, pas seulement déduite.

---

### B — Co-auteurs Claude dans les commits (demande 2)

**38 commits** portent `Co-Authored-By: Claude`. La répartition change
radicalement ce qui est possible :

| | Nombre | Statut | Coût du retrait |
|---|---|---|---|
| Mes commits du premier tour | **10** | locaux, sur `refacto/architecture` | rebase, sans risque |
| Commits antérieurs | **28** | **déjà sur `origin/main`** | réécriture d'historique publié |

`main` et `origin/main` sont désormais **synchronisés** — tu as poussé entre nos
sessions. Les 28 sont donc publiés.

Deux précisions qui pèsent sur la décision :

1. **La plupart des 28 ne viennent pas d'ici.** Ils sont entrés par les imports
   subtree : historique de `Halo`, de `claude-config`, de `Configuration_Debian`.
   Les réécrire dans ce dépôt ne change rien aux dépôts amont, où les mêmes
   commits gardent leur trailer. Le nettoyage serait donc partiel par nature.

2. **Réécrire l'historique publié invalide tous les SHA.** Tout clone existant
   devient inutilisable sans intervention, et il faut un `push --force`. C'est
   acceptable si tu es seul sur le dépôt, mais c'est ta décision, pas la mienne.

**Le volet préventif, lui, est simple et sans risque.** `claude-config` fournit
déjà le réglage :

```json
{ "includeCoAuthoredBy": false }
```

Posé dans le `.claude/settings.json` du dépôt, il supprime le trailer sur tous
les commits **à venir**. C'est ce qui relie cette demande à la suivante, et
c'est pourquoi il faut le poser **avant** toute réécriture — sinon les commits
produits pendant le nettoyage réintroduisent ce qu'on retire.

---

### C — Configuration `.claude` du dépôt (demande 3)

`.claude/` existe à la racine mais est **vide**. Rien n'est configuré.

`claude-config` fournit la matière : quatorze documents dans `docs/`, un
`settings.json` d'exemple, et le plugin `review-gate` comme modèle de hook
(`PreToolUse` sur `Bash(git commit *)` et sur `Edit|Write`).

Ce qui est réellement utile **pour ce dépôt-ci**, par ordre de valeur :

| Primitive | Pourquoi ici |
|---|---|
| `includeCoAuthoredBy: false` | demande 2, volet préventif |
| `permissions.allow` | ce dépôt vit de commandes en lecture seule répétées — `git status`, `git log`, `bash -n`, `du`, `find`. Les autoriser supprime l'essentiel des interruptions |
| `permissions.deny` | `~/.zsh_local`, `identity`, `*.kdbx` : les fichiers non versionnés qui contiennent justement ce qu'on a sorti du dépôt |
| Hook `PreToolUse` sur commit | `shellcheck` + `shfmt -d` avant chaque commit, la même barrière que la CI mais en local |
| `CLAUDE.md` | la règle qui tient l'architecture : *une étape de `install/` ne teste jamais l'OS*. Elle est dans `docs/ARCHITECTURE.md`, elle doit être là où elle sera lue avant d'écrire du code |

Ce qui **ne** sert pas ici : les templates monorepo et spec-driven de
`claude-config`, taillés pour des projets applicatifs à tickets. Les recopier
ferait du volume sans usage.

---

### D — KeePassXC (demande 4)

Vérifié sur les deux canaux :

| | Paquet | Version | Remarque |
|---|---|---|---|
| macOS | cask `keepassxc` | 2.7.12 | fournit aussi le binaire `keepassxc-cli` |
| Debian | apt `keepassxc` | 2.7.4 (bookworm) · 2.7.10 (trixie, forky) | dans les dépôts officiels |

**Le « bon endroit » est déjà là** : `profiles/macos-cask.list` et
`profiles/debian.list`. Aucune structure à créer.

Point à signaler : c'est une **exception à la règle posée dans `docs/MANUAL.md`**,
qui dit que les applications graphiques ne sont pas automatisées sous Debian
parce qu'elles exigent un dépôt tiers. KeePassXC est dans les dépôts officiels
Debian — pas de source non vérifiée à ajouter, donc automatisable des deux côtés.
La documentation devra le dire, sinon la règle a l'air contredite.

Écart de version à connaître : bookworm est à 2.7.4 face à 2.7.12 sur macOS. Le
format de base est compatible entre ces versions ; une base ouverte par une
version plus récente reste lisible par l'ancienne tant qu'aucune fonctionnalité
de format récente n'est utilisée.

---

### E — Outil de rappel de vérifications (demande 5)

C'est la seule demande qui crée quelque chose de neuf. Tu demandes une analyse
de faisabilité, une pile, une mise en place et la redondance — dans l'ordre.

#### E1 — Faisabilité : oui, et le périmètre est ce qui la rend simple

Le cahier des charges dit **« uniquement sur les dates d'exécution »**. L'outil
ne lance rien, ne sauvegarde rien, n'analyse rien. Il répond à une seule
question : *quand ai-je fait ça pour la dernière fois, et est-ce trop vieux ?*

C'est ce périmètre qui évite le piège : un outil qui exécuterait les
sauvegardes et les mises à jour devrait gérer les droits, les erreurs
partielles, les reprises. Un outil qui compare des dates tient en un fichier.

#### E2 — Pile : rien de neuf

| Besoin | Choix | Pourquoi |
|---|---|---|
| Langage | bash + `lib/` existant | `ui.sh` sait déjà afficher des sections et des statuts, `os.sh` sait déjà distinguer les deux OS |
| État | `${XDG_STATE_HOME:-~/.local/state}/dev-setup-hub/checks.tsv` | le répertoire existe déjà sur ton poste ; XDG sépare l'état de la configuration |
| Format | TSV `nom<TAB>date-ISO` | pas de dépendance à `jq`, lisible et corrigeable à la main |
| Déclaration | `checks.conf`, séparateur `\|` | même format qu'`external.conf`, un seul dialecte à connaître dans le dépôt |

`checks.conf` porterait : nom, libellé, seuil en jours, commande macOS,
commande Debian. Aucune bibliothèque, aucun démon, aucun service.

#### E3 — Mise en place

Un script à la racine, `check.sh`, frère de `install.sh` — ce n'est pas une
étape d'installation, c'est un outil récurrent.

```bash
./check.sh              # etat de tous les controles
./check.sh --done update   # enregistre "fait aujourd'hui"
```

Sortie visée, avec l'UI existante :

```
  ▸ --  Verifications
  ──────────────────────────────────────────────────────────────
    ✔  update          il y a 3 j     (seuil 7 j)
    ▲  analyse         il y a 41 j    (seuil 30 j) — echeance depassee
       lynis audit system
    ✖  backup          jamais enregistre
       tmutil startbackup
```

#### E4 — Redondance : le point le plus intéressant de la demande

Un fichier d'état est un point unique de défaillance : il se perd avec le
`$HOME`, et surtout **il ment**. Il enregistre que *tu as dit* avoir fait la
chose, pas que la chose ait eu lieu.

D'où une seconde source, indépendante : interroger le système lui-même.

| Contrôle | Preuve macOS | Preuve Debian |
|---|---|---|
| update | `brew outdated` (nombre), `softwareupdate --history` | dernière `Start-Date:` de `/var/log/apt/history.log` |
| backup | `tmutil latestbackup` | dépend de l'outil utilisé — **à déterminer** |
| analyse | date du rapport `lynis` | `/var/log/lynis.log` |

L'outil affiche alors la date déclarée **et** la preuve système, et signale la
divergence. C'est ça, la redondance utile : pas deux copies du même fichier,
mais deux sources indépendantes qui doivent concorder.

**Ce que ça donne déjà sur ton poste, mesuré aujourd'hui :**

- `brew outdated` → **57 paquets en retard** ;
- `tmutil latestbackup` → **« Failed to mount destination »**. Ta destination
  Time Machine ne se monte pas : la sauvegarde ne tourne pas.

L'outil aurait donc de quoi parler dès sa première exécution — ce qui valide
au passage son utilité.

**Inconnue à lever** : quel outil de sauvegarde sous Debian ? Time Machine n'a
pas d'équivalent, et sans le savoir je ne peux pas écrire la preuve système de
ce côté.

---

### F — VSCode / VSCodium sans extensions (demande 6)

Audit des dépendances actuelles de `config/editor/settings.json` :

| Réglage | Dépend de | État |
|---|---|---|
| `gitlens.*` (×3) | `eamodio.gitlens` | déclarée |
| `multiCommand.commands` | `ryuta46.multi-command` | déclarée |
| `editor.defaultFormatter` dans `[html]` `[css]` `[javascript]` `[javascriptreact]` `[c]` | `esbenp.prettier-vscode` | déclarée |
| `workbench.colorTheme` / `iconTheme` | `ajshortt.tokyo-hack`, `PKief.material-icon-theme` | déclarées |
| `cmake.configureOnOpen` | extension CMake | **orpheline** — jamais déclarée |
| `cSpell.*` (dans `[css]` et `[markdown]`) | correcteur orthographique | **orpheline** — jamais déclarée |

Deux réglages pilotent donc des extensions qui ne sont installées nulle part.

#### Ce que l'éditeur sait faire seul

La démarche est la même que celle que tu as appliquée à vim — une base sans
greffons — et elle est réaliste, parce que VSCode a absorbé la plupart de ces
fonctions :

| À remplacer | Par |
|---|---|
| `esbenp.prettier-vscode` | formateurs intégrés `vscode.html-language-features`, `vscode.css-language-features`, `vscode.typescript-language-features`, `vscode.json-language-features` |
| `ryuta46.multi-command` | commande **`runCommands`**, intégrée depuis VSCode 1.77, écrite précisément pour rendre ces extensions inutiles |
| `gitlens.*` | `git.*` et `scm.*` intégrés, plus l'annotation de blâme intégrée des versions récentes |
| Bracket Pair Colorizer | déjà intégré depuis 1.60 — l'extension avait été retirée au premier tour |
| `cmake.*`, `cSpell.*` | rien : réglages orphelins, à supprimer |

**Ce qui reste irréductiblement une extension : les thèmes.** Un thème de
couleurs et un thème d'icônes ne peuvent pas être intégrés. Trois issues :
garder ces deux-là comme seule exception assumée, basculer sur un thème livré
avec l'éditeur (`Default Dark Modern`), ou accepter que VSCodium diverge.

À vérifier au moment de l'écriture, pas maintenant : le nom exact du réglage de
blâme intégré varie selon la version de VSCode, et je ne veux pas l'affirmer de
mémoire.

---

## 2. Plan d'exécution

Mêmes règles qu'au premier tour : une pause après chaque phase, et je ne commite
que sur ton accord.

L'ordre n'est pas arbitraire — la phase 8 doit précéder la 9, sinon les commits
produits pendant le nettoyage réintroduisent le trailer qu'on retire.

### Phase 8 — `.claude` du dépôt → demande 3, et volet préventif de la 2
- `.claude/settings.json` : `includeCoAuthoredBy: false`, permissions en lecture
  seule pour les commandes courantes, `deny` sur `~/.zsh_local`, le fichier
  d'identité et `*.kdbx`.
- `CLAUDE.md` à la racine : la règle « une étape ne teste jamais l'OS », le style
  shell (tabulations, bash), et où va quoi.
- Hook `PreToolUse` sur `Bash(git commit *)` : `shellcheck` + `shfmt -d` sur la
  portée de `LINT_PATHS`.
- Aucun changement fonctionnel au dépôt.

### Phase 9 — Co-auteurs → demande 2
- Retrait du trailer sur les **10 commits locaux** : `git rebase` sur
  `origin/main`, sans risque puisque rien n'est publié.
- Les **28 publiés** : selon **décision D1** ci-dessous.
- Vérification qu'aucun trailer ne subsiste dans la portée traitée.

### Phase 10 — Identité dynamique → demande 1
- `lib/identity.sh` : cascade `$HUB_USER`/`$HUB_MAIL` → `~/.config/dev-setup-hub/identity`
  → `git config` → `id -un`.
- **Retrait de `USER=yohangh` du `zshrc`** — c'est le correctif qui compte.
- `install/20-header.sh` et les `set_header.sh` consomment la cascade au lieu du
  domaine codé en dur ; correction du quoting cassé de `config/header/set_header.sh`.
- En-têtes 42 et contenus rédigés : inchangés, cf. A3.

### Phase 11 — KeePassXC → demande 4
- Une ligne dans `profiles/macos-cask.list`, une dans `profiles/debian.list`.
- Note dans `docs/MANUAL.md` expliquant pourquoi c'est l'exception qui confirme
  la règle des applications graphiques Debian.

### Phase 12 — Éditeur sans extensions → demande 6
- Réécriture de `config/editor/settings.json` sur les seules capacités intégrées.
- `multiCommand.makeRoom` → `runCommands`, dans `settings.json` et dans le
  raccourci `alt+1` de `keybindings.json`.
- Suppression des réglages orphelins `cmake.*` et `cSpell.*`.
- `extensions.list` réduit selon **décision D2**.
- Vérification que les deux fichiers restent du JSONC valide — c'est ce contrôle
  qui avait révélé les trois virgules manquantes au premier tour.

### Phase 13 — Outil de rappel → demande 5
- `checks.conf`, `check.sh`, et `lib/checks.sh` pour la lecture d'état.
- Deux sources : fichier d'état **et** preuve système, avec signalement des
  divergences.
- Sous réserve de **décision D3** pour la preuve de sauvegarde côté Debian.
- Documentation dans `docs/` et renvoi depuis `99-summary.sh`.

---

## 3. Décisions tranchées (2026-08-29)

### D1 — Les 38 commits, y compris les 28 publiés

Le trailer est retiré partout. Cela impose un `push --force` sur `main`, change
tous les SHA et invalide les clones existants — acceptable puisque tu es seul
sur le dépôt.

Deux limites à garder en tête, elles ne disparaissent pas avec la décision :

- le nettoyage reste **partiel** : les mêmes commits gardent leur trailer dans
  `Halo`, `claude-config` et `Configuration_debian_ubuntu`, qui sont les dépôts
  d'origine ;
- le `push --force` sera **reconfirmé au moment de l'exécution** en phase 9.
  Réécrire une branche publiée est irréversible pour quiconque l'a clonée, et
  ça ne se lance pas au fil de l'eau.

### D2 — Thèmes gardés comme exception assumée

`ajshortt.tokyo-hack` et `PKief.material-icon-theme` restent dans
`extensions.list`. « Sans extensions » porte sur les **fonctionnalités** —
formatage, git, séquences de commandes — pas sur l'apparence, qu'aucun éditeur
ne peut fournir sans extension.

Conséquence inchangée depuis le premier tour : `tokyo-hack` n'étant pas sur
Open VSX, VSCodium gardera son thème par défaut. Le contournement reste dans
`docs/MANUAL.md`.

### D3 — Sauvegarde : projet Rust + planificateur par OS

L'intention est un projet Rust piloté par systemd. **Précision nécessaire :
`systemd` et `systemctl` n'existent pas sur macOS**, qui utilise `launchd`.
Un service systemd ne peut donc pas mutualiser les deux postes.

Ce qui se mutualise et ce qui ne se mutualise pas :

| Couche | Partageable ? |
|---|---|
| Logique de sauvegarde (binaire Rust) | **oui** — un seul code, deux cibles de compilation |
| Déclenchement périodique | **non** — unité `systemd` + timer sous Debian, `plist` `launchd` sous macOS |
| État et journal | **oui** — même format, même emplacement XDG |

Trois voies possibles, à trancher en phase 13 et non maintenant :

1. **`cron`** — le seul planificateur commun aux deux OS. Le moins élégant, le
   plus portable, zéro code.
2. **Deux unités, un binaire** — systemd timer d'un côté, launchd de l'autre,
   générés par une étape `install/`. C'est la voie propre.
3. **Aucun planificateur** — `check.sh` lancé à la main, et c'est justement ce
   que demande le cahier des charges : *rappeler*, pas exécuter.

Tant que le projet Rust n'existe pas, la preuve système du contrôle « backup »
côté Debian reste à définir ; le contrôle fonctionnera sur la date déclarée
seule, donc sans redondance de ce côté.

### Précision sur la demande 1

Les adresses figurant dans les **en-têtes 42** sont hors périmètre : c'est une
signature d'auteur, elle est voulue. Seuls sont concernés les **scripts et leurs
routines d'initialisation** — c'est-à-dire A1 et A2 de l'analyse, pas A3.

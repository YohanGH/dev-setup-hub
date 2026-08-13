<!-- Langue : Français (guide sans équivalent anglais pour l'instant) -->

# Exemples d'utilisation — le guide pas-à-pas

Vous venez d'installer Claude Code, vous avez cloné ce dépôt, et vous ne savez
pas quoi taper. **Ce fichier ne contient que ça : quoi taper, et ce qui doit se
passer ensuite.**

Aucune connaissance préalable n'est supposée. Chaque exemple est copiable tel
quel. Les explications théoriques sont ailleurs — ce guide se contente de vous
renvoyer vers elles quand vous voulez comprendre *pourquoi*.

## Sommaire

1. [Comment lire ce guide](#1-comment-lire-ce-guide)
2. [Préparer le terrain (5 minutes)](#2-préparer-le-terrain-5-minutes)
3. [Le vocabulaire en 2 minutes](#3-le-vocabulaire-en-2-minutes)
4. [Vos dix premiers prompts](#4-vos-dix-premiers-prompts)
5. [Les outils : ce que Claude a le droit de faire](#5-les-outils--ce-que-claude-a-le-droit-de-faire)
6. [Les commandes slash intégrées](#6-les-commandes-slash-intégrées)
7. [Les commandes du template : le pipeline ticket](#7-les-commandes-du-template--le-pipeline-ticket)
8. [Les skills](#8-les-skills)
9. [Les sous-agents](#9-les-sous-agents)
10. [Les hooks](#10-les-hooks)
11. [Les scripts](#11-les-scripts)
12. [Les règles par chemin et `sections.json`](#12-les-règles-par-chemin-et-sectionsjson)
13. [Le plugin `review-gate`](#13-le-plugin-review-gate)
14. [Réglages, permissions, mémoire](#14-réglages-permissions-mémoire)
15. [MCP : brancher des outils externes](#15-mcp--brancher-des-outils-externes)
16. [Explorer la base de connaissances avec Claude](#16-explorer-la-base-de-connaissances-avec-claude)
17. [Cinq séances complètes, de bout en bout](#17-cinq-séances-complètes-de-bout-en-bout)
18. [Dépannage : « ça ne marche pas »](#18-dépannage--ça-ne-marche-pas)
19. [Antisèche](#19-antisèche)

---

## 1. Comment lire ce guide

Trois types de blocs, jamais mélangés :

Un bloc `bash` se tape **dans votre terminal**, avant ou en dehors de Claude :

```bash
git status
```

Un bloc `text` se tape **dans Claude**, une fois la session ouverte — c'est un
prompt ou une commande slash :

```text
Explique-moi ce dépôt en dix lignes.
```

Un bloc `json` ou `markdown` est un **fichier de configuration** à copier
quelque part.

Chaque exemple suit toujours la même trame :

- **Essayez** — ce que vous tapez.
- **Vous devez voir** — le résultat attendu, pour savoir si ça a marché.
- **Si ça coince** — la cause la plus fréquente.

> Une convention d'écriture : `<CHOSE>` entre chevrons signifie « remplacez par
> votre valeur ». `<TICKET-ID>` devient `PROJ-1234` ou `#482` chez vous.

---

## 2. Préparer le terrain (5 minutes)

### 2.1 Cloner le dépôt

```bash
git clone https://github.com/YohanGH/claude-config.git
```

```bash
cd claude-config
```

### 2.2 Installer `jq` — ne sautez pas cette étape

Les hooks de ce dépôt lisent du JSON. Ils sont écrits pour **ne jamais casser
une session** : sans `jq`, ils s'arrêtent silencieusement et ne font rien. Vous
croirez qu'ils sont en panne alors qu'ils sont juste aveugles.

Vérifiez :

```bash
command -v jq || echo "jq manquant"
```

Installez si nécessaire (macOS) :

```bash
brew install jq
```

Sur Debian/Ubuntu :

```bash
sudo apt install jq
```

### 2.3 Choisir où lancer Claude — c'est la décision la plus importante

**Le répertoire depuis lequel vous lancez `claude` détermine ce que vous voyez.**
C'est la source de 80 % des « ça ne marche pas » chez les débutants.

| Vous lancez `claude` depuis | Vous obtenez |
|-----------------------------|--------------|
| `claude-config/` (la racine) | Les docs. **Aucune** commande `/ticket`, aucun hook — ils vivent dans le template. |
| `claude-config/templates/enterprise-monorepo/` | **Le bac à sable** : toutes les commandes, skills, agents et hooks du template. |
| `claude-config/templates/enterprise-monorepo/apps/api/` | En plus : les réglages, hooks et le sous-agent `api-debugger` propres au package. |
| Votre vrai projet | Ce que vous y aurez copié. |

Pour tout ce guide, sauf mention contraire, ouvrez le bac à sable :

```bash
cd templates/enterprise-monorepo
```

```bash
claude
```

### 2.4 Vos trois premières commandes dans Claude

```text
/help
```

**Vous devez voir** la liste des commandes disponibles. Si `/ticket`,
`/preflight` et `/impact` y figurent, vous êtes bien dans le bac à sable.

```text
/status
```

**Vous devez voir** la version, le compte connecté, le modèle actif et le
répertoire de travail. Vérifiez ce dernier : c'est là que se joue le point 2.3.

```text
/cost
```

**Vous devez voir** les tokens consommés depuis le début de la session. Prenez
l'habitude de le taper avant et après une grosse tâche : c'est le seul moyen de
savoir ce que coûte réellement votre façon de travailler.

> Certaines commandes intégrées (`/config`, `/permissions`, `/hooks`,
> `/doctor`, `/terminal-setup`) ouvrent un **panneau interactif**. Elles ne
> fonctionnent que dans un vrai terminal `claude`, pas dans une session pilotée
> depuis une application ou un IDE.

---

## 3. Le vocabulaire en 2 minutes

Huit mots reviennent partout. Voici uniquement ce qu'il faut en retenir pour
commencer.

| Le mot | En une phrase | Qui le déclenche | Exemple ici |
|--------|---------------|------------------|-------------|
| **Outil** (*tool*) | L'action élémentaire que Claude exécute : lire, écrire, chercher, lancer une commande. | Claude, en cours de raisonnement | `Read`, `Grep`, `Bash` |
| **Commande** | Un fichier Markdown lancé quand **vous** tapez `/nom`. | Vous, exclusivement | `/ticket-scope PROJ-42` |
| **Skill** | Une méthode que Claude charge **tout seul** quand la tâche s'y prête. | Claude, ou vous par son nom | `review-checklist` |
| **Sous-agent** | Une seconde session, isolée, qui fait un travail lourd et ne rend que sa conclusion. | Vous, ou une commande | `impact-scout` |
| **Hook** | Un script shell lancé automatiquement par le programme à un moment précis. Il ne demande pas l'avis de Claude. | L'outillage | `pre-commit-gate.sh` |
| **Règle** (*rule*) | Des instructions courtes chargées uniquement quand un fichier correspondant est touché. | Le chemin du fichier | `rules/backend.md` |
| **Mémoire** | Le fichier `CLAUDE.md`, chargé à **chaque** tour de conversation. | Toujours | `CLAUDE.md` |
| **Plugin** | Le même outillage, empaqueté et versionné, installable dans plusieurs dépôts. | Vous, à l'installation | `review-gate` |

Deux phrases à retenir, elles expliquent presque tous les comportements
surprenants :

> **Les skills descendent. Les agents et les réglages remontent.**
> Une skill rangée dans `apps/api/src/routes/` est trouvée même en démarrant à
> la racine. Un sous-agent rangé dans `apps/api/` n'existe que si vous démarrez
> dans `apps/api/`.

> **Une instruction se lit, un hook s'exécute.**
> Si un comportement doit arriver *à tous les coups*, c'est un hook. Si Claude
> doit le *comprendre*, c'est une skill ou une règle.

Pour choisir sereinement entre ces primitives :
[choosing-a-primitive.md](choosing-a-primitive.md).

---

## 4. Vos dix premiers prompts

À taper dans le bac à sable, dans l'ordre. Ils ne modifient rien.

**1. Comprendre où vous êtes**

```text
Décris-moi ce projet : sa structure, à quoi il sert, et ce que je peux te demander ici. Sois bref.
```

**2. Voir la configuration active**

```text
Quels sont les hooks, commandes, skills et sous-agents disponibles dans cette session ? Fais-en un tableau.
```

**3. Se faire expliquer un fichier**

```text
Explique-moi .claude/settings.json ligne par ligne, comme si je n'avais jamais vu de configuration Claude Code.
```

**4. Chercher sans tout lire**

```text
Où est défini le comportement qui refuse un commit avec --no-verify ? Donne-moi le fichier et la ligne, sans me coller le contenu.
```

**5. Demander une comparaison**

```text
Quelle est la différence concrète entre .claude/rules/ et .claude/conventions/ ? Réponds en cinq lignes, avec un exemple de chaque.
```

**6. Faire mesurer plutôt que deviner**

```text
Lance .claude/scripts/context-budget.sh et explique-moi le résultat.
```

**7. Déclencher une skill sans la nommer** — la bonne façon de vérifier qu'elles
fonctionnent

```text
Quelle est la convention de nommage des commits ici ?
```

**Vous devez voir** Claude ouvrir la skill `project-conventions`, puis lire
*uniquement* `conventions/git.md` — pas les sept fichiers de conventions.

**8. Poser une limite explicite**

```text
Liste les fichiers qui définissent le pipeline ticket. Ne lis aucun fichier, utilise seulement les noms.
```

**9. Demander un plan avant l'action**

```text
Si je voulais ajouter une commande /changelog à ce template, quels fichiers faudrait-il créer ou modifier ? Ne modifie rien, propose seulement.
```

**10. Repartir propre**

```text
/clear
```

**Vous devez voir** la conversation repartir de zéro. Prenez cette habitude
entre deux tâches sans rapport : un contexte encombré dégrade les réponses.

---

## 5. Les outils : ce que Claude a le droit de faire

Vous n'appelez jamais un outil directement — mais vous pouvez orienter lesquels
Claude utilise, et surtout **les autoriser ou les refuser** dans
`.claude/settings.json`.

| Outil | Ce qu'il fait | Le prompt qui l'oriente |
|-------|---------------|-------------------------|
| `Read` | Lit un fichier. | « Lis `apps/api/CLAUDE.md` et résume-le. » |
| `Glob` | Trouve des fichiers par motif de nom. | « Liste tous les `SKILL.md` du dépôt. » |
| `Grep` | Cherche un texte dans les fichiers. | « Cherche `permissionDecision` et donne-moi les fichiers, pas le contenu. » |
| `Edit` | Modifie un fichier existant. | « Corrige la faute dans le titre de ce fichier. » |
| `Write` | Crée ou remplace un fichier. | « Crée `notes.md` avec la liste des commandes. » |
| `Bash` | Lance une commande shell. | « Lance `git log --oneline -5`. » |
| `WebSearch` / `WebFetch` | Cherche ou lit sur le web. | « Va lire la doc officielle des hooks et compare-la à notre `hooks-and-automation.md`. » |
| Sous-agent | Délègue à une session isolée. | « Utilise le sous-agent `impact-scout` pour cartographier `preflight.sh`. » |
| MCP | Outils fournis par un serveur externe. | Voir [§15](#15-mcp--brancher-des-outils-externes). |

### 5.1 Voir un outil se faire refuser

C'est le meilleur moyen de comprendre les permissions. Dans le bac à sable :

```text
Lis le fichier .env de ce projet.
```

**Vous devez voir** un refus. La cause est dans `.claude/settings.json` :

```json
"deny": [
  "Read(./**/.env)",
  "Read(./**/.env.*)"
]
```

**Ce qu'il faut comprendre** : la syntaxe `Outil(motif)` est le vocabulaire des
permissions. `Read(./**)` autorise la lecture partout, `Bash(git diff:*)`
autorise `git diff` et ses variantes, et rien d'autre.

### 5.2 Les trois niveaux de permission

| Niveau | Effet | Exemple dans le template |
|--------|-------|--------------------------|
| `allow` | Passe sans rien demander. | `Bash(git status)` |
| `ask` | Vous êtes consulté à chaque fois. | `Bash(git push:*)` |
| `deny` | Refusé, sans négociation possible. | `Bash(git push --force:*)` |

**Essayez** — demandez une action classée `ask` :

```text
Pousse la branche courante sur origin.
```

**Vous devez voir** une demande de confirmation, jamais une exécution directe.

### 5.3 Économiser des tours en cadrant l'outillage

Trois formulations qui changent réellement le comportement :

```text
Cherche d'abord, ne lis que le fichier le plus probable, et dis-moi ce que tu comptes ouvrir avant de l'ouvrir.
```

```text
Réponds uniquement à partir des noms de fichiers et des descriptions, sans ouvrir de fichier.
```

```text
Ne modifie rien. Je veux un diagnostic, pas un correctif.
```

---

## 6. Les commandes slash intégrées

Celles fournies par Claude Code, disponibles dans n'importe quel projet.

### 6.1 Gérer la conversation

| Commande | Quand l'utiliser |
|----------|------------------|
| `/clear` | Vous changez de sujet. **Le réflexe le plus rentable.** |
| `/compact` | Longue session utile à condenser sans tout perdre. |
| `/cost` | Vérifier ce que la session a consommé. |
| `/export` | Garder une trace d'une session dans un fichier. |
| `/resume` | Reprendre une session précédente. |

**Essayez** une compaction dirigée :

```text
/compact garde uniquement les décisions prises et les chemins de fichiers
```

### 6.2 Contexte projet et mémoire

| Commande | Quand l'utiliser |
|----------|------------------|
| `/init` | Premier jour dans un dépôt sans `CLAUDE.md`. Génère un brouillon. |
| `/memory` | Ouvrir et éditer les fichiers `CLAUDE.md`. |
| `/add-dir` | Travailler sur un second répertoire (monorepo, package voisin). |

**Essayez** — dans **votre** projet, pas ici :

```text
/init
```

**Vous devez voir** un `CLAUDE.md` généré. **Relisez-le et coupez-le** : tout ce
qu'il contient est payé à chaque tour de conversation. Voir
[context-economics.md](context-economics.md).

### 6.3 Outillage et collaboration

| Commande | Quand l'utiliser |
|----------|------------------|
| `/agents` | Créer ou inspecter des sous-agents. |
| `/mcp` | Gérer les serveurs MCP et leur authentification. |
| `/model` | Changer de modèle en cours de session. |
| `/review` | Faire relire les changements en cours. |
| `/pr-comments` | Récupérer les commentaires d'une pull request GitHub. |

> La liste exacte varie selon les versions. `/help` fait foi, pas une liste
> figée. Référence détaillée : [commands.md](commands.md).

---

## 7. Les commandes du template : le pipeline ticket

Ces six commandes vivent dans
`templates/enterprise-monorepo/.claude/commands/`. Elles n'apparaissent que si
vous avez lancé Claude dans le bac à sable (ou dans un projet où vous avez copié
le template).

Toutes portent `disable-model-invocation: true` : **Claude ne peut pas les
déclencher seul.** Elles écrivent des fichiers, elles n'arrivent que quand vous
le décidez.

```text
   /ticket-scope ──> scope.md      « ce qu'on a promis »
        │
        ▼
   (vous codez, ou Claude code)
        │
   /review-scope ──> review.md     « ce que la revue a trouvé »
        │
        ▼
   /ticket-report ─> report.md     « ce qu'on livre »

   /impact et /preflight s'utilisent à tout moment.
   /ticket enchaîne les quatre étapes avec des points d'arrêt.
```

Les trois fichiers atterrissent dans `.claude/tickets/<TICKET-ID>/`. C'est
volontaire : ils survivent à une compaction de contexte, à une nuit de sommeil
et à un changement de machine. Détail du raisonnement :
[ticket-workflow.md](ticket-workflow.md).

### 7.1 `/ticket-scope` — cadrer avant d'écrire une ligne

**À quoi ça sert** : lire le ticket, cartographier le code concerné, écrire
`scope.md`. **Et s'arrêter là.**

**Essayez**

```text
/ticket-scope PROJ-42
```

**Vous devez voir** — dans cet ordre, et rien d'autre : un plan en cinq lignes,
les questions ouvertes, une estimation de la taille du diff. Aucun fichier
source modifié.

**Si ça coince** : sans `gh` configuré ni
`.claude/tickets/PROJ-42/ticket.md`, la commande vous dira qu'elle n'a rien
trouvé et **s'arrêtera**. C'est le comportement voulu : elle ne devine pas un
besoin à partir d'un identifiant. Créez le fichier à la main :

```bash
mkdir -p .claude/tickets/PROJ-42
```

Puis collez-y le texte du ticket dans `ticket.md`, et relancez.

### 7.2 `/impact` — savoir ce que vous allez casser

**À quoi ça sert** : cartographier tout ce qui dépend d'un symbole, d'un fichier
ou d'un endpoint, **avant** d'y toucher.

**Particularité** : la commande tourne dans un sous-agent (`context: fork` +
`agent: impact-scout`). Les cinquante recherches et lectures n'entrent jamais
dans votre conversation — vous recevez la carte, pas le trajet.

**Essayez**

```text
/impact preflight.sh
```

**Vous devez voir** un rapport structuré : définition, dépendants directs,
contrats concernés, tests, fichiers frères, historique, verdict. **Aucune
proposition de refactoring** — c'est une carte, pas un plan.

**Quand l'utiliser** : avant de renommer quoi que ce soit, avant de toucher à un
type partagé, chaque fois que vous vous dites « je crois que rien d'autre ne
l'utilise ».

### 7.3 `/preflight` — la batterie de qualité locale

**À quoi ça sert** : lancer format, lint, typecheck et tests exactement comme le
fera la CI.

**Essayez**

```text
/preflight --quick
```

**Vous devez voir**, dans le bac à sable vide, quelque chose comme :

```text
preflight — 1 check(s), 0 failed
  pass  secret scan
PREFLIGHT_RESULT pass steps=1 failed=0
```

Une seule vérification, parce qu'il n'y a ici ni `package.json` ni code source :
le script détecte la stack et ne lance que ce qu'il trouve. Dans un vrai projet,
vous verrez les quatre lignes.

**Les trois portées**

| Argument | Ce qui tourne |
|----------|---------------|
| `--changed` (défaut) | Uniquement les fichiers modifiés depuis la base de branche. |
| `--all` | La batterie complète, ce que fait la CI. |
| `--quick` | Format + lint + typecheck, sans les tests. |

**Ce que la commande interdit explicitement** : faire passer une vérification en
l'affaiblissant. Pas de `skip`, pas d'assertion relâchée, pas de règle
désactivée, pas de `--no-verify`. Si un test échoue, vous verrez l'échec.

### 7.4 `/review-scope` — la revue de branche

**À quoi ça sert** : relire la branche courante face à `scope.md` et à la
grille de `conventions/review.md`, puis écrire `review.md`.

**Particularité** : tourne dans le sous-agent `code-reviewer`, qui n'a
**pas** le droit d'éditer. Un relecteur qui corrige cesse de voir.

**Essayez**

```text
/review-scope PROJ-42
```

**Vous devez voir** un verdict, les points bloquants et majeurs, et la liste de
ce qui n'a pas été relu. Deux vérifications qu'une revue générique ne fait pas :
chaque critère d'acceptation est marqué *rempli / partiel / non rempli* avec sa
preuve (`fichier:ligne` ou nom de test), et toute dérive de périmètre est
listée.

**Si ça coince** : sans `scope.md`, la commande vous le dit et relit face au
ticket seul, en signalant que le cadrage n'a jamais été écrit.

### 7.5 `/ticket-report` — le rapport de passation

**À quoi ça sert** : produire le document que le relecteur lit *à la place* de
refaire votre raisonnement. Il sert aussi de description de pull request.

**Essayez**

```text
/ticket-report PROJ-42
```

**Vous devez voir** : le tableau des critères d'acceptation, le tableau de
vérification (avec le **vrai** résultat de `preflight.sh`, échec compris), et la
liste des suites à donner. Le rapport commence par les écarts : ce qui était
promis et n'a pas été fait, ce qui a été fait sans avoir été promis.

**Ce qu'elle ne fait pas** : ni commit, ni push, ni ouverture de PR.

### 7.6 `/ticket` — tout le pipeline avec des points d'arrêt

**À quoi ça sert** : enchaîner les quatre phases, en s'arrêtant à chacune pour
attendre votre feu vert.

**Essayez**

```text
/ticket PROJ-42
```

**Vous devez voir** quatre arrêts : après le cadrage, après l'implémentation,
après la revue, après le rapport. **Claude ne franchit pas un point d'arrêt sans
votre accord explicite.**

**Quand ne pas l'utiliser** : sur une tâche de dix minutes. Le pipeline est fait
pour du travail qui traverse plusieurs sessions ou plusieurs personnes.

### 7.7 Écrire votre propre commande

Créez `.claude/commands/changelog.md` :

```markdown
---
description: Rédiger l'entrée de changelog pour les commits de la branche
argument-hint: [version]
disable-model-invocation: true
allowed-tools: Read Grep Bash(git log:*) Bash(git diff:*)
---

Rédige l'entrée de changelog pour la branche courante, au format Keep a
Changelog, à partir de :

!`git log --oneline origin/main..HEAD`

Groupe par Added / Changed / Fixed. Une ligne par changement visible par un
utilisateur. Ignore les commits de refactoring interne.
```

Elle apparaît immédiatement sous `/changelog`.

**Les quatre champs qui comptent**

| Champ | Pourquoi |
|-------|----------|
| `description` | C'est ce que vous lirez dans le menu `/`. Écrivez-la comme la demande d'un utilisateur. |
| `disable-model-invocation` | À mettre à `true` dès que la commande a des effets de bord. |
| `allowed-tools` | Le jeu le plus étroit qui fonctionne — **ce champ accorde des permissions**. |
| `context: fork` + `agent:` | Si la commande lit beaucoup : le bruit reste dans le sous-agent. |

Détail de tous les champs disponibles :
[frontmatter-reference.md](frontmatter-reference.md).

---

## 8. Les skills

Une skill est une méthode que **Claude charge tout seul** au bon moment. C'est
la différence essentielle avec une commande.

### 8.1 Les trois façons dont une skill se déclenche

| Façon | Exemple |
|-------|---------|
| **Automatique** — le cas normal | Vous dites « relis mes changements », `review-checklist` se charge. |
| **Par son nom** | `/review-checklist` |
| **Préchargée dans un agent** | `code-reviewer` embarque `review-checklist` dès son démarrage. |

**Ce que Claude « voit » en permanence** : uniquement le `name`, la
`description` et le `when_to_use` de chaque skill — quelques lignes. Le corps ne
se charge que si la skill est retenue. C'est ce qui permet d'en avoir vingt sans
payer vingt.

### 8.2 Les quatre skills globales du template

| Skill | Le prompt qui la déclenche | Ce qu'elle produit |
|-------|---------------------------|--------------------|
| `project-conventions` | « Quelle est notre convention pour les messages de commit ? » | La réponse tirée du bon fichier de `conventions/`, et lui seul. |
| `ticket-analysis` | « Commence sur PROJ-42 » · « Qu'est-ce que touche cette issue ? » | La méthode de cadrage et le gabarit de `scope.md`. |
| `review-checklist` | « Relis ça » · « C'est mergeable ? » | Les cinq passes de revue et l'échelle de sévérité. |
| `handoff-report` | « Résume ce que tu as fait » · « Prépare la description de PR » | Le gabarit du rapport de passation. |

**Essayez la plus démonstrative** — elle prouve le mécanisme d'économie :

```text
Est-ce qu'on documente les décisions d'architecture dans ce projet, et sous quelle forme ?
```

**Vous devez voir** Claude charger `project-conventions`, consulter son tableau
de routage, puis ouvrir **uniquement** `conventions/documentation.md`. Lire les
sept fichiers de conventions annulerait tout l'intérêt du dispositif.

### 8.3 Les skills par répertoire

Elles ne se chargent que si le travail a lieu dans leur répertoire. Le frontend
ne paie jamais les instructions du backend.

| Vous travaillez dans | La skill qui se réveille | La règle qu'elle impose |
|----------------------|--------------------------|-------------------------|
| `apps/api/src/routes/` | `route-handlers` | Un handler, c'est du transport, pas de la logique métier. |
| `apps/api/src/services/` | `service-layer` | Un service ignore tout de HTTP. |
| `apps/api/src/core/` | `core-boundaries` | Tout importe `core`, donc `core` n'importe rien du domaine. |
| `apps/api/src/types/` | `type-contracts` | Un type qui décrit une réponse HTTP appartient à `packages/shared`. |
| `apps/api/src/utils/` | `utils-discipline` | Les utilitaires sont purs : ni I/O, ni env, ni horloge, ni aléatoire. |
| `apps/api/` (global) | `api-testing`, `new-endpoint`, `api-design-patterns` | Comment tester, scaffolder, concevoir une API ici. |
| `apps/api/docs/` | `docs-format` | La forme de tout document, **et un linter markdown après chaque édition**. |
| `apps/web/src/` | `component-patterns` | Un composant qui fetch n'est ni réutilisable ni testable. |
| `apps/web/src/api/` | `data-layer` | Le seul répertoire du frontend autorisé à parler au réseau. |
| `apps/web/src/pages/` | `page-composition` | Une page gère trois états : chargement, vide, erreur. |
| `apps/web/src/stores/` | `state-boundaries` | Les données du serveur n'ont rien à faire dans un store. |
| `packages/shared/` | `contract-change` | Tout changement ici est un changement de contrat. |
| `scripts/` | `cross-platform-script` | Ça doit tourner sur Windows aussi. |

**Essayez** — placez-vous dans le contexte, puis demandez :

```text
Je veux ajouter un endpoint POST /invoices/{id}/cancellation dans apps/api. Comment on s'y prend ici ?
```

**Vous devez voir** Claude s'appuyer sur `new-endpoint` et
`api-design-patterns`, et vous proposer une sous-ressource
(`.../cancellation`) plutôt qu'un endpoint-verbe (`.../cancel`) — parce que la
skill impose ce choix.

**Essayez le contraste** — la même question, formulée frontend :

```text
Je veux afficher la liste des factures dans apps/web. Où je mets l'appel réseau ?
```

**Vous devez voir** une réponse fondée sur `data-layer` et
`component-patterns` : l'appel va dans `src/api/`, jamais dans le composant.

### 8.4 La skill qui porte son propre hook

`docs-format` déclare un hook dans son frontmatter :

```yaml
hooks:
  PostToolUse:
    - matcher: "Edit|Write|MultiEdit"
      hooks:
        - type: command
          command: "${CLAUDE_PROJECT_DIR}/.claude/hooks/lint-markdown.sh"
          async: true
```

**Ce que ça veut dire** : le linter markdown ne tourne **que pendant que cette
skill est active**. Aucune session du dépôt ne traîne un linter markdown dont
elle n'a pas l'usage.

**Le piège** : si la skill ne se charge pas, le hook ne s'exécute pas. Ce
mécanisme convient à de l'outillage de confort, **jamais** à une règle de
sécurité. Pour ça, voir `sections.json` en [§12](#12-les-règles-par-chemin-et-sectionsjson).

### 8.5 Écrire votre première skill

Créez `.claude/skills/ma-methode/SKILL.md` :

```markdown
---
name: ma-methode
description: Ce que fait cette skill, et quand l'utiliser — c'est ce texte qui décide de son déclenchement.
when_to_use: Déclenchée par « ... », « ... », ou quand ...
allowed-tools: Read Grep Glob
---

# Ma méthode

Les étapes, à l'impératif. Court. Les documents longs vont dans un
sous-répertoire `references/` — ils ne se chargent que si on les lit.
```

**La seule chose qui compte vraiment** : la `description`. C'est le seul texte
que Claude voit avant de décider de charger la skill. Écrivez-y les mots que
*vous* emploieriez naturellement.

Comparez :

| Mauvaise description | Bonne description |
|----------------------|-------------------|
| « Aide pour les tests » | « Écrire ou modifier un test dans `apps/api` — assertions HTTP, fixtures de base, helpers d'authentification. À utiliser en ajoutant un test pour un endpoint. » |

Pour approfondir : [rules-and-skills.md](rules-and-skills.md).

---

## 9. Les sous-agents

Un sous-agent, c'est **une seconde fenêtre de contexte**. Il fait le travail
salissant et ne vous rend que la conclusion.

### 9.1 Les agents disponibles

| Agent | Ce qu'il fait | Ce que vous économisez |
|-------|---------------|------------------------|
| `impact-scout` | Cartographie les dépendances. | Cinquante recherches → une carte. |
| `code-reviewer` | Relit un diff selon la grille du projet. | Un diff de branche entier → un verdict et des constats. |
| `test-runner` | Lance les tests et classe les échecs. | Des milliers de lignes de sortie → des causes. |
| `ticket-analyst` | Cadre un ticket en arrière-plan. | Le triage d'un backlog pendant que vous codez. |
| `api-debugger` | Diagnostique un endpoint qui échoue. | Uniquement dans `apps/api/`. |

### 9.2 Les invoquer

Trois formulations équivalentes :

```text
@impact-scout cartographie tout ce qui dépend de preflight.sh
```

```text
Utilise le sous-agent impact-scout pour cartographier ce qui dépend de preflight.sh.
```

```text
/impact preflight.sh
```

La troisième est la meilleure quand une commande existe : elle apporte en plus
le format de sortie attendu.

### 9.3 Ce qui rend un agent sûr

Regardez `code-reviewer.md` :

```yaml
tools: Read, Grep, Glob, Bash
disallowedTools: Edit, Write, NotebookEdit
permissionMode: plan
```

**Retirer l'outil est plus fort que demander de ne pas s'en servir.** Un
relecteur qui *peut* éditer finira par corriger au lieu de signaler.

### 9.4 Le travail en arrière-plan

`test-runner` et `ticket-analyst` déclarent `background: true`.

**Essayez**

```text
Lance le cadrage de PROJ-42 en arrière-plan avec ticket-analyst pendant qu'on continue sur autre chose.
```

**Vous devez voir** la conversation rester disponible, et une notification à la
fin. Le détail des modes autonomes :
[agents-and-autonomy.md](agents-and-autonomy.md).

### 9.5 Le piège de la découverte

`api-debugger` vit dans `apps/api/.claude/agents/`. **Il n'apparaît pas si vous
démarrez à la racine du dépôt.** Les sous-agents sont cherchés en *remontant*
depuis votre répertoire de travail.

```bash
cd apps/api
```

```bash
claude
```

Ou, sans changer de répertoire :

```bash
claude --add-dir apps/api
```

---

## 10. Les hooks

**Vous n'invoquez jamais un hook.** C'est un script que l'outillage lance à un
moment fixe, que Claude soit d'accord ou non. C'est la couche déterministe.

### 10.1 Ce qui est branché dans le template

| Moment | Script | Ce qu'il fait |
|--------|--------|---------------|
| Démarrage de session | `session-start-context.sh` | Affiche la branche, le ticket, l'état des artefacts. |
| À chaque prompt envoyé | `inject-ticket-context.sh` | Si vous nommez un ticket, injecte les **chemins** de ses artefacts. |
| Avant `git commit` | `pre-commit-gate.sh` | Refuse `--no-verify`, lance `preflight`, **bloque un commit rouge**. |
| Avant toute édition | `protect-paths.sh` | Refuse d'écrire dans les secrets, le build, le vendored, les lockfiles. |
| Avant toute édition | `section-dispatch.sh` | Applique les frontières d'architecture de `sections.json`. |
| Après une édition | `format-edited.sh` | Formate ce qui vient d'être écrit. `async` : ne ralentit rien. |
| Après un commit | `post-commit-report.sh` | Journalise le commit dans `.claude/tickets/<ID>/commits.log`. |
| Fin de tour | `quality-gate.sh` | Batterie rapide. Avertit par défaut, bloque si vous le demandez. |

### 10.2 Tester un hook sans lancer Claude

Un hook lit du JSON sur son entrée standard. Vous pouvez donc le tester
directement — c'est l'astuce de dépannage la plus utile de tout ce guide.

Un chemin protégé doit être refusé :

```bash
echo '{"tool_input":{"file_path":".env"}}' | .claude/hooks/protect-paths.sh
```

**Vous devez voir** un JSON contenant `"permissionDecision":"deny"` et
l'explication du refus.

Un chemin normal doit passer :

```bash
echo '{"tool_input":{"file_path":"src/app.ts"}}' | .claude/hooks/protect-paths.sh
```

**Vous devez voir** : rien du tout. « Pas d'avis, continue. »

Un contournement de vérification doit être refusé :

```bash
echo '{"tool_input":{"command":"git commit --no-verify -m x"}}' | .claude/hooks/pre-commit-gate.sh
```

**Si vous ne voyez rien alors qu'un refus était attendu** : `jq` n'est pas
installé (voir [§2.2](#22-installer-jq--ne-sautez-pas-cette-étape)). Les hooks
dégradent en silence plutôt que de casser votre session — c'est un choix de
conception, pas un bug.

### 10.3 Voir un hook en action

Dans le bac à sable, avec `jq` installé :

```text
Crée un fichier .env avec DATABASE_URL=postgres://localhost/test
```

**Vous devez voir** le refus, avec le motif : ajoutez plutôt la variable dans
`.env.example` avec une valeur factice.

### 10.4 Les interrupteurs

Toujours dans `.claude/settings.local.json` (non versionné), jamais dans le
fichier partagé :

| Vous voulez | Réglage |
|-------------|---------|
| Pas de garde-fou en fin de tour | `CLAUDE_QUALITY_GATE=off` |
| Un blocage dur en fin de tour | `CLAUDE_QUALITY_GATE=block` |
| Pas de garde-fou au commit | `CLAUDE_PRECOMMIT_GATE=off` |
| Tout couper, temporairement | `"disableAllHooks": true` |

```json
{
  "env": {
    "CLAUDE_QUALITY_GATE": "off"
  }
}
```

> Un changement de hook dans `settings.json` demande un **redémarrage de
> session**. C'est la deuxième cause de « mon hook ne se déclenche pas ».

Contrats d'entrée/sortie complets :
[hooks-and-automation.md](hooks-and-automation.md).

---

## 11. Les scripts

Ces scripts sont appelables par vous, par les hooks **et** par git. Un seul
script, une seule définition de « vert » — c'est tout l'intérêt.

### 11.1 `preflight.sh` — la batterie

```bash
.claude/scripts/preflight.sh --changed
```

```bash
.claude/scripts/preflight.sh --all
```

Codes de sortie : `0` tout vert · `1` une vérification a échoué · `2` mal
configuré, rien à lancer.

### 11.2 `install-git-hooks.sh` — le rôle de husky, sans la dépendance

À lancer une fois par clone :

```bash
.claude/scripts/install-git-hooks.sh
```

**Ce que ça change** : vos propres `git commit` passent désormais par la même
batterie que ceux de Claude. Deux acteurs, un seul garde-fou, aucune dérive.

Pour annuler :

```bash
git config --unset core.hooksPath
```

### 11.3 `context-budget.sh` — mesurer au lieu de deviner

```bash
.claude/scripts/context-budget.sh
```

**Vous devez voir** un tableau de ce genre (chiffres réels de ce dépôt) :

```text
WHEN IT LOADS                           BYTES   ~TOKENS   FILES
every turn (CLAUDE.md, bare rules)          0         0       0
skill list (names+descriptions)          5752      1438      20
FIXED COST PER SESSION                   5752      1438
on demand (nested/path-scoped)          16562      4140      12
on use (skill+command bodies)           62318     15579      20
never (conventions, references)         28592      7148      10
TOTAL CONFIG ON DISK                   113224     28306

You pay 5% of this configuration on every turn.
```

**Comment le lire** : la ligne qui compte est `FIXED COST PER SESSION`. Payer
5 % d'une grosse configuration est excellent ; payer 80 % d'une petite est
mauvais. Deux seuils d'alerte : plus de ~2 k tokens d'index de skills signifie
trop de skills en portée, et un `CLAUDE.md` volumineux se découpe en règles par
chemin.

Ce que paierait une session lancée ailleurs :

```bash
.claude/scripts/context-budget.sh apps/api
```

Le détail par fichier, du plus gros au plus petit :

```bash
.claude/scripts/context-budget.sh --files
```

### 11.4 `scan-secrets.sh` et `ticket-context.sh`

```bash
.claude/scripts/scan-secrets.sh
```

Ne dit rien si tout va bien, sort en `1` avec une ligne par trouvaille sinon.
C'est un filet, pas un produit de sécurité.

```bash
.claude/scripts/ticket-context.sh PROJ-42
```

Résout le ticket depuis `gh` ou depuis un fichier local, et affiche l'état du
pipeline. Sans argument, il tente de déduire l'identifiant du nom de la branche.

---

## 12. Les règles par chemin et `sections.json`

### 12.1 Les règles

Une règle est un fichier d'instructions courtes qui ne se charge **que** si un
fichier correspondant est touché :

```yaml
---
description: Conventions backend — chargé en touchant apps/api
paths:
  - "apps/api/**"
---
```

| Règle | Se charge en touchant |
|-------|------------------------|
| `backend.md` | `apps/api/**` |
| `frontend.md` | `apps/web/**` |
| `shared-lib.md` | `packages/shared/**` |
| `tests.md` | `**/*.test.*`, `**/__tests__/**`, … |
| `migrations.md` | `**/migrations/**` |
| `ci-and-infra.md` | `.github/**`, `Dockerfile`, `*.tf`, `k8s/**` |
| `claude-config.md` | `.claude/**` — la méta-règle : modifier la config est un changement revu comme un autre |

**Essayez** — demandez quelque chose qui touche une migration :

```text
Écris une migration qui supprime la colonne legacy_status de la table invoices.
```

**Vous devez voir** un refus argumenté ou une contre-proposition en trois temps
(*expand → migrate → contract*), parce que `rules/migrations.md` se sera
chargée. Une migration tourne une fois, contre des données de production.

### 12.2 `sections.json` — les frontières qui tiennent partout

Une skill par répertoire n'aide que si elle se charge. Pour une frontière
d'architecture qui doit tenir **quel que soit le répertoire de démarrage**, le
template utilise un hook unique piloté par `.claude/sections.json`.

Chaque section déclare des motifs interdits et le message qui va avec :

```json
{
  "name": "api/routes",
  "match": "apps/api/src/routes/",
  "skill": "route-handlers",
  "forbid": [
    {
      "pattern": "process\\.env\\.",
      "message": "Route handlers must not read process.env. Configuration is validated once at boot in src/core/config.ts and injected."
    }
  ]
}
```

**Essayez** — tentez une violation franche :

```text
Dans apps/api/src/routes/invoices.ts, ajoute un handler qui lit process.env.STRIPE_KEY et fait un SELECT direct en base.
```

**Vous devez voir** un blocage avant écriture, avec le message de la section et
un renvoi vers la bonne couche. Ce n'est pas Claude qui décide d'être vertueux :
c'est le hook qui refuse.

**Les frontières couvertes** : routes (pas de base de données, pas de SQL, pas
d'`env`), services (pas de HTTP, pas de framework web), core (pas d'import du
domaine), utils (pureté), composants web (pas de fetch), stores (pas de fetch),
`packages/shared` (pas d'I/O), migrations (pas de DDL destructif).

**Ajouter la vôtre** : une entrée JSON, aucun code. C'est le point de tout le
dispositif.

---

## 13. Le plugin `review-gate`

Le même garde-fou qualité, mais **portable** : installé une fois, il s'applique
à tous vos dépôts, sans script à copier ni maintenir.

### 13.1 L'essayer sans rien installer

Depuis la racine de `claude-config` :

```bash
claude --plugin-dir ./plugins/review-gate
```

### 13.2 L'installer depuis la marketplace locale

```text
/plugin marketplace add ./plugins
```

```text
/plugin install review-gate@claude-config
```

L'activer pour toute une équipe — dans le `.claude/settings.json` versionné :

```json
{ "enabledPlugins": ["review-gate@claude-config"] }
```

Après toute modification des fichiers du plugin :

```text
/reload-plugins
```

### 13.3 L'utiliser

```text
/review-gate:gate-status
```

**Vous devez voir** un tableau lint / typecheck / tests, honnête — échecs
compris.

```text
@diff-reviewer relis la branche courante
```

> **Le nom est préfixé.** Une skill de plugin s'appelle
> `/review-gate:gate-status`, jamais `/gate-status`. C'est ce qui garantit
> qu'elle n'entre jamais en collision avec une skill de votre dépôt.

### 13.4 Le tester en ligne de commande

```bash
echo '{"tool_input":{"command":"git commit --no-verify -m x"}}' | ./plugins/review-gate/scripts/guard.sh commit
```

**Vous devez voir** une décision `deny` (avec `jq` installé).

```bash
claude plugin validate ./plugins/review-gate
```

### 13.5 Plugin ou configuration dans le dépôt ?

| | Dans le dépôt (`.claude/`) | En plugin |
|---|---|---|
| Vit avec le code qu'il gouverne | oui | non |
| Mêmes règles sur dix dépôts | copier-coller, dérive | une source, versionnée |
| Mettre à jour partout d'un coup | non | oui |

**Règle simple** : ce qui est spécifique au dépôt reste dans le dépôt ; ce qui
doit être identique partout devient un plugin. N'adoptez pas les deux formes du
même garde-fou — le template et ce plugin font la même chose.

---

## 14. Réglages, permissions, mémoire

### 14.1 Les trois niveaux, et lequel modifier

| Fichier | Portée | Versionné | Vous y mettez |
|---------|--------|-----------|---------------|
| `~/.claude/settings.json` | Vous, partout | non | Vos préférences personnelles. |
| `.claude/settings.json` | Le dépôt, tout le monde | **oui** | Permissions, hooks, plugins de l'équipe. |
| `.claude/settings.local.json` | Vous, sur ce dépôt | non | Vos surcharges. **C'est ici que vous bricolez.** |

Le template fournit un exemple à copier :

```bash
cp .claude/settings.local.json.example .claude/settings.local.json
```

**Essayez**

```text
Explique-moi ce que fait chaque bloc de .claude/settings.json, et dis-moi lequel je dois modifier si je veux que git push ne me demande plus confirmation.
```

**Vous devez voir** Claude vous orienter vers `settings.local.json` — pas vers
le fichier partagé.

### 14.2 La mémoire `CLAUDE.md`

C'est le seul fichier payé **à chaque tour de conversation**. Le template le
maintient sous 200 lignes, et pousse tout le reste vers des règles, des skills
et des conventions chargées à la demande.

| Le contenu | Où il va |
|------------|----------|
| Vrai pour tout le dépôt, tout le temps | `CLAUDE.md` racine |
| Vrai pour un package | `apps/api/CLAUDE.md` |
| Vrai pour un type de fichier | `.claude/rules/<sujet>.md` |
| Une procédure | `.claude/skills/<nom>/SKILL.md` |
| Un document de référence long | `.claude/conventions/<sujet>.md` |

**Essayez** — l'audit le plus rentable sur un projet existant :

```text
Relis mon CLAUDE.md et dis-moi, ligne par ligne, ce qui devrait descendre dans une règle par chemin ou une skill parce que ce n'est pas vrai tout le temps.
```

Carte annotée du répertoire : [claude-directory.md](claude-directory.md).
Modèle complet : [configuration.md](configuration.md).

---

## 15. MCP : brancher des outils externes

MCP (*Model Context Protocol*) permet à Claude d'utiliser des outils qui ne sont
pas dans votre dépôt : une base de données, un traqueur de tickets, un service
interne.

```text
/mcp
```

**Vous devez voir** la liste des serveurs configurés et leur état
d'authentification. Vide au départ — ce dépôt n'en configure aucun.

**À retenir avant d'en ajouter un** : chaque serveur MCP ajoute ses outils à
l'index payé en permanence, et ouvre une porte vers l'extérieur. Un serveur qui
sert une fois par mois coûte à chaque tour. Voir
[configuration.md](configuration.md) pour la déclaration, et
[context-economics.md](context-economics.md) pour le coût.

---

## 16. Explorer la base de connaissances avec Claude

Chaque document de `docs/fr/` traite un sujet. Voici, pour chacun, le prompt qui
en tire quelque chose d'utilisable — plutôt qu'un résumé que vous auriez pu lire
vous-même.

| Document | Le prompt à essayer |
|----------|---------------------|
| [configuration.md](configuration.md) | « Dresse-moi la liste de tous les endroits où une configuration Claude Code peut vivre, du plus global au plus local, avec qui l'emporte en cas de conflit. » |
| [claude-directory.md](claude-directory.md) | « Compare l'arborescence `.claude/` documentée ici avec celle de mon projet, et dis-moi ce qui me manque. » |
| [commands.md](commands.md) | « Écris-moi une commande `/standup` qui résume mes commits d'hier. » |
| [best-practices.md](best-practices.md) | « Donne-moi les cinq pratiques de ce fichier qui changeraient le plus mon quotidien, sachant que je travaille seul sur un projet Python. » |
| [choosing-a-primitive.md](choosing-a-primitive.md) | « Je veux que tous mes fichiers Python soient formatés après édition. Mémoire, règle, skill, hook ou plugin ? Justifie. » |
| [frontmatter-reference.md](frontmatter-reference.md) | « Écris le frontmatter optimal d'un sous-agent qui relit du code sans jamais pouvoir le modifier, et explique chaque champ. » |
| [rules-and-skills.md](rules-and-skills.md) | « Je viens de Cursor et j'ai dix fichiers de rules. Comment je les traduis ici sans tout payer à chaque tour ? » |
| [monorepo.md](monorepo.md) | « Mon monorepo a quatre packages. Propose-moi le découpage des `CLAUDE.md` et des skills, avec les chemins exacts. » |
| [context-economics.md](context-economics.md) | « Lance `context-budget.sh` sur mon projet et dis-moi les trois coupes les plus rentables. » |
| [hooks-and-automation.md](hooks-and-automation.md) | « Écris-moi un hook `PreToolUse` qui refuse toute écriture dans `docs/generated/`, et montre-moi comment le tester sans lancer Claude. » |
| [agents-and-autonomy.md](agents-and-autonomy.md) | « Quelles propriétés rendent un sous-agent sûr à laisser tourner seul ? Applique-les à un agent qui lance ma suite de tests. » |
| [ticket-workflow.md](ticket-workflow.md) | « Explique-moi pourquoi le cadrage passe par un fichier plutôt que par la conversation. » |
| [template-enterprise-monorepo.md](template-enterprise-monorepo.md) | « Quels fichiers du template dois-je adapter en premier pour un projet Django + React ? » |

---

## 17. Cinq séances complètes, de bout en bout

### Séance 1 — Découvrir un dépôt inconnu (20 minutes)

```bash
cd <votre-projet>
```

```bash
claude
```

```text
Fais-moi une visite guidée : que fait ce projet, quelles sont les grandes zones du code, où est le point d'entrée, et où sont les tests. Sers-toi des noms de fichiers et du git log avant d'ouvrir quoi que ce soit.
```

```text
Quelles sont les cinq parties les plus modifiées ces six derniers mois ? Utilise git log, pas ton intuition.
```

```text
Qu'est-ce qui, dans ce dépôt, surprendrait un nouvel arrivant ? Uniquement des choses que tu peux prouver par un fichier.
```

```text
/init
```

Puis coupez le `CLAUDE.md` généré de moitié.

### Séance 2 — Corriger un bug proprement

```text
/ticket-scope BUG-118
```

Vous relisez `scope.md`, vous corrigez si besoin. Puis :

```text
Écris d'abord le test qui échoue et montre-moi l'échec. Ne corrige rien tant que je n'ai pas vu l'échec.
```

```text
Maintenant, le correctif minimal qui fait passer ce test. Rien d'autre.
```

```text
/preflight --changed
```

```text
/review-scope BUG-118
```

```text
/ticket-report BUG-118
```

**Ce qui rend cette séance différente** : l'échec du test est vu *avant* le
correctif. Sans ça, vous ne savez pas si vous avez corrigé le bug ou écrit un
test qui passe de toute façon.

### Séance 3 — Ajouter un endpoint

```bash
cd apps/api
```

```bash
claude
```

```text
/impact InvoiceService
```

```text
Je veux ajouter l'annulation d'une facture. Propose-moi la forme de l'API avant d'écrire du code.
```

```text
Implémente-la : schéma, route, service, test. Suis la structure d'une ressource voisine plutôt qu'un gabarit générique.
```

```text
/preflight --changed
```

### Séance 4 — Relire une branche avant la PR

```text
@code-reviewer relis la branche courante face à main. Constats seulement, ne corrige rien.
```

```text
Pour chaque point bloquant : soit tu le corriges, soit tu m'expliques pourquoi il ne doit pas être corrigé ici. Les points mineurs, tu les listes sans y toucher.
```

```text
@test-runner lance la suite et dis-moi ce qui est un vrai échec, ce qui était déjà cassé avant ma branche, et ce qui est instable.
```

### Séance 5 — Adopter le template dans votre projet

```bash
cp -r templates/enterprise-monorepo/.claude <votre-projet>/.claude
```

```bash
cd <votre-projet>
```

```bash
claude
```

```text
Ce .claude/ vient d'un template générique. Trouve tous les placeholders (<TEST_CMD>, <DEFAULT_BRANCH>, <PROJECT_NAME>, ...) et liste-les avec leur fichier et leur ligne. Ne remplace rien encore.
```

```text
Voici mes vraies commandes : install=..., test=..., lint=..., typecheck=..., branche par défaut=main. Remplace les placeholders correspondants.
```

```text
Maintenant, supprime les règles, skills et sections qui ne correspondent à aucun répertoire réel de ce projet. Liste ce que tu supprimes avant de le faire.
```

```bash
.claude/scripts/install-git-hooks.sh
```

```bash
.claude/scripts/context-budget.sh
```

**Vérification finale** : si `FIXED COST PER SESSION` dépasse ~3 k tokens, vous
avez gardé trop de choses en portée permanente.

---

## 18. Dépannage : « ça ne marche pas »

| Symptôme | Cause la plus fréquente | Correctif |
|----------|-------------------------|-----------|
| `/ticket` n'existe pas | Session lancée au mauvais endroit. | `cd templates/enterprise-monorepo` puis relancer. |
| Un hook ne fait rien | `jq` absent — les hooks dégradent en silence. | `brew install jq`, puis retester avec `echo '{...}' \| .claude/hooks/...`. |
| Un hook ne se déclenche toujours pas | `settings.json` modifié sans redémarrage. | Quitter et relancer `claude`. Puis `claude --debug`. |
| `api-debugger` invisible | Les agents sont cherchés en **remontant**. | Démarrer dans `apps/api/`, ou `--add-dir apps/api`. |
| Une skill ne se déclenche jamais | La `description` n'emploie pas vos mots. | La réécrire avec le vocabulaire réel de vos demandes. |
| Une commande se déclenche toute seule | `disable-model-invocation` absent. | L'ajouter (`true`) si la commande a des effets de bord. |
| Claude propose de désactiver un test rouge | Formulation trop permissive. | « N'affaiblis jamais une vérification. Montre-moi l'échec réel. » |
| Réponses qui se dégradent en fin de session | Contexte saturé. | `/clear` entre deux tâches, `/compact` en cours de tâche. |
| `preflight` ne lance qu'une vérification | Aucune stack détectée (répertoire vide). | Normal dans le bac à sable. Dans un vrai projet, vérifier les scripts du `package.json`. |
| Modifications inattendues | `defaultMode: acceptEdits` accepte les éditions sans demander. | Le changer dans `settings.local.json` le temps de prendre confiance. |

**Le prompt de dépannage universel**, quand vous ne comprenez pas un
comportement :

```text
Explique-moi précisément pourquoi tu viens de faire ça : quelle instruction, quel fichier de configuration, quelle règle ou quel hook a produit ce comportement. Donne-moi le fichier et la ligne.
```

---

## 19. Antisèche

**Les cinq commandes à connaître dès le premier jour**

```text
/help
```

```text
/clear
```

```text
/cost
```

```text
/preflight --changed
```

```text
/impact <ce-que-je-vais-modifier>
```

**Les cinq réflexes qui changent tout**

1. `/clear` entre deux tâches sans rapport.
2. `/impact` **avant** de renommer ou de toucher à du code partagé.
3. Faire écrire le cadrage dans un fichier, pas dans la conversation.
4. Exiger de voir l'échec d'un test avant son correctif.
5. Mesurer avec `context-budget.sh` plutôt que discuter du coût.

**Les cinq phrases à copier telles quelles**

```text
Ne modifie rien. Diagnostic seulement.
```

```text
Cherche avant de lire, et dis-moi ce que tu comptes ouvrir avant de l'ouvrir.
```

```text
N'affaiblis jamais une vérification pour la faire passer. Montre-moi l'échec réel.
```

```text
Si la réalité contredit le cadrage, mets à jour le fichier de cadrage et préviens-moi. Ne diverge pas en silence.
```

```text
Arrête-toi ici et montre-moi le résultat avant de continuer.
```

**Où va quoi**

| Le comportement | Le bon endroit |
|-----------------|----------------|
| Vrai partout, tout le temps | `CLAUDE.md` |
| Vrai pour certains fichiers | `.claude/rules/` |
| Une méthode que Claude doit reprendre seul | `.claude/skills/` |
| Une étape que **vous** déclenchez | `.claude/commands/` |
| Du travail lourd et bruyant | `.claude/agents/` |
| Ce qui doit arriver **à tous les coups** | `.claude/hooks/` |
| Identique dans dix dépôts | un plugin |

---

## Pour aller plus loin

Vous avez fait le tour des usages. Pour comprendre les décisions derrière :

- [choosing-a-primitive.md](choosing-a-primitive.md) — le document à lire avant
  d'écrire la moindre configuration.
- [context-economics.md](context-economics.md) — ce que votre configuration
  coûte vraiment.
- [best-practices.md](best-practices.md) — ce qui se vérifie au quotidien.
- [README.md](README.md) — le sommaire complet de la base de connaissances.

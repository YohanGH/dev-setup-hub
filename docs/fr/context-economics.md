<!-- Langue : [English](../context-economics.md) · Français -->

# Économie du contexte : scoper la config à une section

Chaque fichier d'instructions a un **moment de chargement** — l'instant où ses
octets entrent dans la fenêtre de contexte. Concevez la configuration d'un dépôt
autour de ces moments et vous pouvez porter une configuration vaste et détaillée
en n'en payant qu'une fraction par tour. Ignorez-les et vous payez tout, tout le
temps, à chaque requête.

Cette page donne le modèle, la mesure et les mécanismes — dont l'asymétrie qui
détermine le comportement réel de la configuration par section.

## 1. Les cinq moments de chargement

| Moment | Ce qui s'y trouve | Profil de coût |
|--------|-------------------|----------------|
| **Chaque tour** | `CLAUDE.md` racine, `.claude/rules/*.md` **sans** `paths:` | Payé à chaque requête, indéfiniment |
| **Index de session** | `name` + `description` + `when_to_use` de chaque skill | Payé une fois par session, croît avec le nombre de skills |
| **À la demande** | `CLAUDE.md` imbriqués, règles limitées au chemin | Seulement quand Claude touche cette zone |
| **À l'usage** | Corps des skills, corps des commandes | Seulement à l'invocation ou si jugé pertinent |
| **Jamais** | `conventions/`, `references/` des skills, docs | Seulement si quelque chose les lit explicitement |

Les deux premiers sont votre **coût fixe**. Le reste est variable et
proportionnel à la tâche. Toute la discipline tient en une phrase : *faire
descendre les octets dans ce tableau.*

## 2. Mesurer, pas estimer

Le template embarque
[`context-budget.sh`](../../templates/enterprise-monorepo/.claude/scripts/context-budget.sh),
qui classe chaque fichier de config par moment de chargement :

```console
$ .claude/scripts/context-budget.sh

WHEN IT LOADS                           BYTES   ~TOKENS   FILES
---------------------------------------------------------------
every turn (CLAUDE.md, bare rules)       2528       632       1
skill list (names+descriptions)          5551      1387      19
---------------------------------------------------------------
FIXED COST PER SESSION                   8079      2019
---------------------------------------------------------------
on demand (nested/path-scoped)          14034      3508      11
on use (skill+command bodies)           61137     15284      19
never (conventions, references)         28592      7148      10
---------------------------------------------------------------
TOTAL CONFIG ON DISK                   111842     27960

You pay 7% of this configuration on every turn.
```

Voilà le chiffre qui compte : **~28 k tokens de configuration existent ; ~2 k
sont chargés par session.** Le même contenu dans un fichier toujours actif
coûterait 14× plus par tour *et* noierait les trois lignes pertinentes parmi
trois cents.

Repères une fois le chiffre visible :

- Coût fixe au-dessus de **35 %** du total → du détail est piégé dans
  `CLAUDE.md` ; déplacez-le vers des règles limitées au chemin ou des skills.
- Index des skills au-delà de **~2 k tokens** → trop de skills en portée.
  Poussez-les dans les répertoires auxquels elles appartiennent, ou en plugin.
- Bucket `never` proche de zéro → vous n'avez pas de référence long format, ce
  qui signifie en général qu'elle est dans un fichier toujours chargé.

Avec un répertoire en argument, on voit ce qu'une session paie réellement :

```console
$ .claude/scripts/context-budget.sh apps/api
  CLAUDE.md chain loaded at launch: 3973 B (~993 tokens)
  subagents in scope (this dir + ancestors): 1
  skills reachable under this dir: 9
  settings.json: apply here (hooks, plugins, permissions)
```

## 3. L'asymétrie qui gouverne tout

Tous les mécanismes ne se propagent pas dans le même sens. C'est le fait le plus
utile pour concevoir une configuration par section, et il est facile de se
tromper :

| Mécanisme | Depuis la **racine** | Démarré **dans la section** |
|-----------|----------------------|-----------------------------|
| `CLAUDE.md` imbriqué | se charge à la demande à la lecture | se charge au lancement, plus chaque ancêtre |
| Règle limitée au chemin (`paths:`) | se charge sur fichier correspondant | idem |
| **`.claude/skills/`** | **découvertes vers le bas** — chaque sous-répertoire touché | découvertes ici et chez les ancêtres |
| **`.claude/agents/`** | **non découverts** — seuls les ancêtres du cwd sont scannés | **découverts** |
| **`.claude/settings.json`** (hooks, plugins, permissions) | **non chargé** — répertoire de démarrage uniquement | **chargé** |

**Les skills descendent. Les agents et les settings remontent.**

Autrement dit, un `.claude/settings.json` par package rempli de hooks est
*inerte* pour quiconque lance `claude` à la racine du dépôt — c'est-à-dire la
plupart des gens, la plupart du temps. Si vous avez déjà écrit des hooks par
package en vous demandant pourquoi ils ne se déclenchaient jamais, c'est ça.

Deux conséquences à intégrer :

- **Les skills sont l'unité de connaissance par section : peu chère et fiable.**
  Elles fonctionnent depuis n'importe où, coûtent une ligne chacune jusqu'à
  usage, et vivent à côté du code qu'elles décrivent.
- **Les settings et agents par package sont opt-in par workflow.** Excellents
  quand l'équipe démarre réellement ses sessions dans les packages — invisibles
  sinon. À choisir délibérément, pas par défaut.

## 4. Scoper les hooks à une section

Trois mécanismes, portées différentes. On choisit selon que la règle est
*indicative* ou *structurante*.

| # | Mécanisme | Se déclenche quand | À utiliser pour |
|---|-----------|--------------------|-----------------|
| 1 | Hook dans le `settings.json` du package | session démarrée dans ce package | outillage de package, pour une équipe qui y travaille |
| 2 | `hooks:` dans le frontmatter d'une **skill** ou d'un **agent** | ce composant est actif | outillage indicatif naturellement lié à une tâche |
| 3 | Un hook racine qui **dispatche sur le chemin du fichier** | toujours | frontières architecturales dures |

### (1) Portée package

[`apps/api/.claude/settings.json`](../../templates/enterprise-monorepo/apps/api/.claude/settings.json)
câble un `PostToolUse` qui alerte quand les schémas de l'API changent sans
régénérer les types partagés. Il active aussi le plugin serveur de langage
TypeScript — rentable dans ce package, inutile dans une session de doc. Les deux
sont inertes à la racine.

### (2) Portée composant

Une skill peut porter ses propres hooks. La skill `docs-format` déclare :

```yaml
hooks:
  PostToolUse:
    - matcher: "Edit|Write|MultiEdit"
      hooks:
        - type: command
          command: "${CLAUDE_PROJECT_DIR}/.claude/hooks/lint-markdown.sh"
          async: true
```

Un linter markdown qui n'existe que pendant qu'on écrit du markdown. Tous les
événements sont supportés ; pour les sous-agents, `Stop` devient automatiquement
`SubagentStop` ; les hooks sont nettoyés à la fin du composant.

C'est l'option élégante — et sa faiblesse est exactement sa force : **si la
skill ne se charge pas, le hook ne s'exécute pas.** À ne jamais utiliser pour
une règle qui doit tenir.

### (3) Dispatch racine — pour les règles qui doivent tenir

Le motif qui marche partout : enregistrer **un seul** hook à la racine, et le
laisser dispatcher sur le chemin édité contre un fichier de politique versionné.

[`.claude/sections.json`](../../templates/enterprise-monorepo/.claude/sections.json)
+ [`section-dispatch.sh`](../../templates/enterprise-monorepo/.claude/hooks/section-dispatch.sh) :

```json
{
  "name": "api/routes",
  "match": "apps/api/src/routes/",
  "skill": "route-handlers",
  "forbid": [
    { "pattern": "from[[:space:]]+['\"][^'\"]*/db[/'\"]",
      "message": "Route handlers must not import the data layer. Call a service." }
  ]
}
```

Éditer une route pour importer la base est refusé, avec la raison et un renvoi
vers la skill de la section — depuis n'importe quel répertoire de démarrage, que
cette skill ait été chargée ou non. Ajouter une frontière est une entrée JSON ;
le script ne change jamais.

Deux détails d'implémentation qui comptent :

- **Retirer les lignes de commentaire avant de matcher**, sinon documenter une
  règle la déclenche.
- **Matcher le nouveau contenu**, depuis `content` (Write), `new_string` (Edit)
  et `edits[].new_string` (MultiEdit).

## 5. Scoper les plugins à une section

`enabledPlugins` vit dans `settings.json` : il suit donc la même règle de
remontée — les entrées par package ne s'appliquent qu'aux sessions démarrées là.

| Type de plugin | Où l'activer |
|----------------|--------------|
| Serveur de langage pour une stack | le `settings.json` de ce package |
| Application à l'échelle de l'org (garde-fou de revue) | `settings.json` racine |
| Outillage personnel | `~/.claude/settings.json` |

Le serveur de langage est le cas le plus net : valeur réelle dans le package dont
il sert le langage, pur coût de démarrage partout ailleurs.

Les plugins résolvent aussi *l'autre* problème d'échelle. Les skills par
répertoire cessent de passer à l'échelle quand la même est copiée dans six
dépôts — à ce moment-là, versionnez-la en plugin. Les skills de plugin sont
préfixées `plugin:skill` : jamais de collision avec celles par répertoire.

## 6. Scoper l'autonomie à une section

Les sous-agents sont le plus gros levier sur le contexte, car leurs lectures
n'entrent jamais dans votre fenêtre. Les scoper par section :

- **Les agents de package** (`apps/api/.claude/agents/api-debugger.md`) sont
  découverts en remontant depuis le cwd. Démarrez dans `apps/api/` et vous avez
  le debugger API ; démarrez à la racine et non. C'est correct : un debugger
  backend est du bruit pendant du travail frontend.
- **La définition la plus proche gagne.** Deux packages peuvent chacun définir un
  agent nommé `debugger` avec des instructions différentes ; celui le plus proche
  du répertoire de travail est utilisé.
- **Les agents de dépôt** (`impact-scout`, `code-reviewer`) restent à la racine
  car leur travail est intrinsèquement transverse.
- **Le préchargement `skills:`** injecte le corps complet d'une skill dans un
  agent au démarrage — c'est ainsi qu'un relecteur a toujours son barème sans
  qu'il soit dans votre contexte.
- **Les sessions de fond héritent du répertoire de lancement** : `cd apps/api &&
  claude --bg "..."` obtient les settings, hooks et agents de ce package. C'est
  la façon la plus propre de lancer une tâche autonome scopée à une section.

## 7. Le playbook

Par retour sur effort décroissant :

1. **Démarrer Claude dans la section où vous travaillez.** Zéro configuration,
   plus gros gain unitaire : ancêtres seulement, aucun package frère, aucune
   skill sans rapport.
2. **Découper `CLAUDE.md` par répertoire.** La racine garde la structure et les
   règles globales ; chaque package garde le détail de sa stack.
3. **Déplacer les procédures en skills, posées dans le répertoire qu'elles
   servent.** Coûte une description ; rapporte le corps entier à la demande.
4. **Déplacer la référence long format dans `conventions/`**, tirée par une règle
   ou une skill. Jamais chargée avant d'être nécessaire.
5. **Refuser la lecture** de `dist/`, `build/`, code généré et vendu. Des
   résultats de recherche qui ne deviennent jamais des lectures.
6. **Déléguer l'exploration** à un sous-agent en lecture seule. Cinquante
   lectures deviennent un résumé.
7. **Ajouter un plugin d'intelligence du code** pour que les définitions soient
   recherchées, pas scannées.
8. **Worktrees clairsemés** pour qu'une session de fond extraie trois répertoires.
9. **Élaguer l'index des skills** : auditez avec la télémétrie `skill_activated`
   (`OTEL_LOG_TOOL_DETAILS=1`) et supprimez ou fusionnez ce qui ne se déclenche
   jamais.

## 8. Anti-motifs

| Anti-motif | Ce qu'il coûte | À la place |
|------------|----------------|------------|
| Un `CLAUDE.md` racine de 400 lignes | payé chaque tour ; noie les lignes utiles | découper par répertoire + règles limitées au chemin |
| Des règles sans `paths:` | chargement inconditionnel — c'est `CLAUDE.md` ailleurs | ajouter `paths:`, ou admettre que c'est de la mémoire |
| Une skill par micro-sujet | l'index gonfle, les descriptions sont tronquées, la correspondance se dégrade | une skill par section, avec des sections dedans |
| Des hooks par package pour une règle dure | inerte depuis la racine — ne s'exécute jamais, en silence | dispatch racine sur le chemin |
| Descriptions vagues (« utilitaires de test ») | ne correspond jamais à une vraie demande | les mots de l'utilisateur : « écrire ou modifier les tests dans `packages/api` » |
| Dupliquer une skill entre dépôts | dérive immédiatement | la versionner en plugin |
| Un long préambule dans un hook `SessionStart` | stdout devient du contexte, à chaque session | imprimer de l'état, pas des conseils |

## Voir aussi

- [monorepo.md](monorepo.md) — la mécanique : `claudeMdExcludes`, worktrees
  clairsemés, accès inter-packages
- [choosing-a-primitive.md](choosing-a-primitive.md) — quelle primitive pour quel
  comportement
- [hooks-and-automation.md](hooks-and-automation.md) — contrats de hooks et
  scripts
- [agents-and-autonomy.md](agents-and-autonomy.md) — sous-agents et sessions de
  fond

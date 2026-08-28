<!-- Langue : [English](../frontmatter-reference.md) · Français -->

# Référence frontmatter & propriétés des fichiers

Chaque type de fichier configurable, ses champs, et — plus utile encore —
**quels champs valent la peine d'être définis** selon le travail visé.

> Les champs proviennent de la documentation officielle. Claude Code évolue
> vite ; en cas de divergence avec [la doc](https://code.claude.com/docs/fr/skills),
> c'est la doc qui fait foi.

## Skills et commandes (`SKILL.md`, `commands/*.md`)

Même mécanisme, même frontmatter. `.claude/skills/x/SKILL.md` et
`.claude/commands/x.md` créent tous deux `/x`.

| Champ | Obligatoire | Rôle |
|-------|-------------|------|
| `name` | non | Nom affiché. Par défaut, le nom du répertoire. |
| `description` | **recommandé** | Ce que ça fait et quand l'utiliser. **C'est là-dessus que Claude s'appuie.** Combiné à `when_to_use`, tronqué à 1536 caractères dans la liste des skills. |
| `when_to_use` | non | Phrases déclencheuses supplémentaires. Compte dans le même plafond. |
| `argument-hint` | non | Affiché à l'autocomplétion, ex. `[numero-ticket]`. |
| `arguments` | non | Arguments positionnels nommés → `$nom` dans le corps. Chaîne séparée par espaces ou liste YAML. |
| `disable-model-invocation` | non | `true` = vous seul pouvez l'exécuter. Retire aussi la skill de la liste. |
| `user-invocable` | non | `false` = masquée du menu `/`, toujours invocable par le modèle. |
| `allowed-tools` | non | Outils utilisables **sans demande de permission** tant qu'elle est active. Accorde, ne restreint pas. |
| `disallowed-tools` | non | Outils retirés du pool tant qu'elle est active. S'efface au message suivant. |
| `model` | non | Modèle pendant l'activité, ou `inherit`. Revient au prompt suivant. |
| `effort` | non | `low` · `medium` · `high` · `xhigh` · `max`. |
| `context` | non | `fork` → exécution dans un contexte de sous-agent. |
| `agent` | non | Quel sous-agent utiliser avec `context: fork`. |
| `paths` | non | Globs limitant l'activation automatique aux fichiers correspondants. |
| `hooks` | non | Hooks limités au cycle de vie de cette skill. |
| `shell` | non | `bash` (défaut) ou `powershell` pour les blocs de commande en ligne. |

### Substitutions disponibles dans le corps

| Jeton | Se développe en |
|-------|-----------------|
| `$ARGUMENTS` | tout ce qui est tapé après le nom |
| `$ARGUMENTS[N]` / `$N` | le Nième argument, base 0 |
| `$nom` | un argument nommé déclaré dans `arguments:` |
| `${CLAUDE_SKILL_DIR}` | le répertoire de la skill — pour référencer ses fichiers embarqués |
| `${CLAUDE_PROJECT_DIR}` | la racine du projet — fonctionne dans le corps **et** dans `allowed-tools` |
| `${CLAUDE_SESSION_ID}`, `${CLAUDE_EFFORT}` | id de session, niveau d'effort courant |

### Propriétés optimales selon le rôle

| La skill est… | Définir |
|---------------|---------|
| Du matériel de référence que Claude doit trouver seul | `description` avec les mots de l'utilisateur · `when_to_use` |
| Un workflow à effets de bord (commit, déploiement, rapport) | `disable-model-invocation: true` · `argument-hint` |
| Gourmande en lecture (revue, audit, recherche large) | `context: fork` · `agent:` · `effort: high` |
| Spécifique à une zone | `paths:` — ou simplement la placer dans le `.claude/skills/` de ce répertoire |
| Un lanceur de script projet | `allowed-tools: Bash(${CLAUDE_PROJECT_DIR}/.claude/scripts/x.sh:*)` |
| De la connaissance de fond, jamais invoquée directement | `user-invocable: false` |

Écrire une bonne `description` est le geste au meilleur rendement ici. Commencez
par les mots que contiendrait une demande — « écrire ou modifier les tests dans
`packages/api` » vaut mieux que « utilitaires de test » — car les descriptions
sont tronquées quand les skills sont nombreuses, et c'est le début de la chaîne
qui survit.

## Sous-agents (`.claude/agents/*.md`)

| Champ | Obligatoire | Rôle |
|-------|-------------|------|
| `name` | **oui** | Minuscules et tirets. Les hooks le reçoivent comme `agent_type`. |
| `description` | **oui** | Quand Claude doit déléguer ici. La clé de routage. |
| `tools` | non | Outils autorisés. Hérite de tout si omis. |
| `disallowedTools` | non | Retirés de la liste héritée ou spécifiée. |
| `model` | non | `sonnet` · `opus` · `haiku` · `fable` · un id complet · `inherit` (défaut). |
| `permissionMode` | non | `default` · `acceptEdits` · `auto` · `dontAsk` · `bypassPermissions` · `plan`. |
| `maxTurns` | non | Arrêt dur sur le nombre de tours. |
| `skills` | non | Skills préchargées **intégralement** au démarrage — pas seulement leurs descriptions. |
| `mcpServers` | non | Serveurs MCP disponibles. |
| `hooks` | non | Hooks limités à cet agent. |
| `memory` | non | `user` · `project` · `local` — apprentissage persistant entre sessions. |
| `background` | non | `true` = toujours exécuté en tâche de fond. |
| `effort` | non | Niveau d'effort pendant l'activité. |
| `isolation` | non | `worktree` = son propre worktree git, nettoyé s'il ne change rien. |
| `color` | non | `red` `blue` `green` `yellow` `purple` `orange` `pink` `cyan`. |
| `initialPrompt` | non | Premier tour auto-soumis quand l'agent est agent principal. |

### Propriétés optimales selon le rôle

| L'agent est… | Définir |
|--------------|---------|
| Un explorateur en lecture seule | `permissionMode: plan` · `tools: Read, Grep, Glob, Bash` · `model: sonnet` |
| Un relecteur | `disallowedTools: Edit, Write` · `skills: <barème>` · `effort: high` · `permissionMode: plan` |
| Un lanceur de tests | `disallowedTools: Edit, Write` · `memory: project` · `maxTurns` · `background: true` |
| Un long traitement par lot | `background: true` · `effort` ajusté au travail |
| Un refactor risqué | `isolation: worktree` |

Deux règles comptent plus que le tableau :

1. **Retirez l'outil plutôt que de demander de ne pas s'en servir.** Un
   relecteur avec `Edit` finira par corriger au lieu de rapporter.
   `disallowedTools` est de l'application ; une instruction est une suggestion.
2. **Précisez le format de sortie dans le corps.** Un agent dont la forme de
   sortie varie ne peut pas être une étape de pipeline.

## Règles limitées au chemin (`.claude/rules/*.md`)

| Champ | Rôle |
|-------|------|
| `paths` | Globs. Ne se charge que quand Claude lit un fichier correspondant. |
| `description` | Note à destination humaine ; aide qui maintient le fichier. |

```markdown
---
description: Conventions backend
paths:
  - "apps/api/**"
  - "src/**/*.{ts,tsx}"
---
```

Sans `paths:` → chargement à chaque session, à la priorité de `CLAUDE.md`. Les
règles sont découvertes récursivement, donc les sous-répertoires fonctionnent.
Les liens symboliques sont suivis : c'est ainsi qu'on partage un jeu de règles
entre dépôts.

## Entrées de hook (`settings.json`, `hooks/hooks.json`)

```json
{
  "matcher": "Edit|Write",
  "hooks": [{
    "type": "command",
    "if": "Bash(git commit *)",
    "command": "${CLAUDE_PROJECT_DIR}/.claude/hooks/x.sh",
    "args": ["--flag"],
    "async": false,
    "timeout": 600,
    "statusMessage": "Vérification"
  }]
}
```

| Champ | Rôle |
|-------|------|
| `matcher` | Nom d'outil, liste `A\|B`, ou regex. Omis ou `*` = tous. |
| `type` | `command` · `http` · `mcp_tool` · `prompt` · `agent`. |
| `if` | Condition supplémentaire, ex. `Bash(git commit *)` — plus fin que `matcher` seul. |
| `command` | Le script. Utilisez `${CLAUDE_PROJECT_DIR}` / `${CLAUDE_PLUGIN_ROOT}`, jamais un chemin en dur. |
| `args` | Présent → exec direct, sans shell. Absent → commande shell. |
| `async` | `true` = ne bloque pas le tour. Pour tout ce qui est lent et non bloquant. |
| `timeout` | Secondes ; 600 par défaut pour les commandes. |
| `statusMessage` | Affiché à l'utilisateur pendant l'exécution. |

Liste complète des événements et contrats de sortie :
[hooks-and-automation.md](hooks-and-automation.md).

## Réglages à connaître (`.claude/settings.json`)

| Clé | Pourquoi |
|-----|----------|
| `permissions.allow` / `ask` / `deny` | La couche d'application. `deny` couvre les outils fichiers intégrés *et* les commandes Bash reconnues comme `cat`, `grep`, `find`. |
| `permissions.additionalDirectories` | Accès aux packages/dépôts frères. Ne charge **pas** leurs `CLAUDE.md` ni leurs skills. |
| `claudeMdExcludes` | Ignorer les `CLAUDE.md` d'autres équipes. Globs sur chemins absolus ; les motifs relatifs commencent par `**/`. Fusionne entre scopes. |
| `worktree.sparsePaths` | Ne extraire que ces répertoires dans un worktree. Incluez `.claude` ou la config du dépôt y sera absente. |
| `worktree.symlinkDirectories` | Lier `node_modules` au lieu de le dupliquer. |
| `enabledPlugins` | Activer un plugin pour toute l'équipe du dépôt. |
| `env` | Valeurs lues par vos hooks — la façon propre de rendre un garde-fou configurable. |
| `disableAllHooks` | Issue de secours. |

Les réglages projet se chargent **uniquement depuis le répertoire de démarrage**
— ils ne sont pas hérités des parents comme les `CLAUDE.md`. Un
`.claude/settings.json` par package doit être autonome.

## Plugins

`.claude-plugin/plugin.json` :

| Champ | Notes |
|-------|-------|
| `name` | **Obligatoire.** Devient l'espace de noms : `/nom:skill`. |
| `description` | Affiché dans le gestionnaire de plugins. |
| `version` | Omis → chaque commit git est une nouvelle version. Définissez-le pour maîtriser les mises à jour. |
| `author`, `homepage`, `repository`, `license`, `keywords` | Métadonnées optionnelles. |

Arborescence — **seul `plugin.json` va dans `.claude-plugin/`** :

```text
mon-plugin/
├── .claude-plugin/plugin.json
├── skills/<nom>/SKILL.md
├── agents/<nom>.md
├── hooks/hooks.json
├── commands/<nom>.md      # forme plate héritée ; préférez skills/
├── .mcp.json  .lsp.json
├── monitors/monitors.json
├── bin/                   # ajouté au PATH tant que le plugin est actif
└── settings.json          # uniquement `agent` et `subagentStatusLine`
```

Mettre `skills/` ou `hooks/` **dans** `.claude-plugin/` est le bug de plugin le
plus fréquent — ils sont silencieusement ignorés.

`.claude-plugin/marketplace.json` à la racine de la marketplace liste les plugins
avec `name`, `source`, `description`, `version`, `author`, `keywords`,
`category`.

## Checklist avant de commiter un fichier de config

- [ ] La `description` ressemble à la demande qu'on formulerait réellement.
- [ ] Effets de bord → `disable-model-invocation: true`.
- [ ] Lecture lourde → `context: fork`, ou un sous-agent.
- [ ] Les règles ont un `paths:`, sinon leur place est dans `CLAUDE.md`.
- [ ] `allowed-tools` est l'ensemble le plus étroit qui fonctionne.
- [ ] Les agents qui ne doivent pas écrire ont `disallowedTools`.
- [ ] Les chemins de hooks utilisent `${CLAUDE_PROJECT_DIR}` / `${CLAUDE_PLUGIN_ROOT}`.
- [ ] Les hooks lents sont `async`.
- [ ] `CLAUDE.md` fait toujours moins de ~200 lignes.

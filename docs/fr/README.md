<!-- Langue : [English](../README.md) · Français -->

# Documentation

Base de connaissances pour configurer et tirer le meilleur de
[Claude Code](https://code.claude.com/docs/en/overview).

> Disponible en anglais (`docs/`) et en français (`docs/fr/`). Le
> [README](../../README.md) du projet est bilingue (FR/EN).

## Sommaire

### Fondamentaux

| Guide | Ce que vous y trouvez |
|-------|------------------------|
| [exemples-utilisation.md](exemples-utilisation.md) | **Débutants : commencez ici.** Que taper, dans quel ordre, et ce qui doit se passer — prompts prêts à copier pour chaque commande, skill, sous-agent, hook, script et plugin du dépôt. |
| [configuration.md](configuration.md) | Le modèle de configuration complet : global / projet / local, `settings.json`, mémoire `CLAUDE.md`, permissions, hooks et serveurs MCP. |
| [claude-directory.md](claude-directory.md) | Carte annotée du répertoire `.claude/` — projet vs `~/.claude/`, avec l'arborescence complète et le rôle de chaque fichier/dossier. |
| [commands.md](commands.md) | Référence des commandes slash de Claude Code, groupées par cas d'usage, et comment écrire les vôtres. |
| [best-practices.md](best-practices.md) | Conseils pratiques et assumés qui font une vraie différence au quotidien avec Claude Code. |

### Concevoir sa configuration

| Guide | Ce que vous y trouvez |
|-------|------------------------|
| [choosing-a-primitive.md](choosing-a-primitive.md) | **Commencez ici.** Mémoire, règles, skills, commandes, sous-agents, hooks, plugins, MCP — laquelle pour quel comportement, et pourquoi le mauvais choix coûte cher. |
| [frontmatter-reference.md](frontmatter-reference.md) | Chaque champ de chaque type de fichier configurable, et les *propriétés optimales* selon le rôle. |
| [rules-and-skills.md](rules-and-skills.md) | Faut-il ajouter des rules/skills façon Cursor ? Analyse raisonnée et guide de décision. |
| [monorepo.md](monorepo.md) | Grands dépôts : `CLAUDE.md` et skills par répertoire, `claudeMdExcludes`, worktrees clairsemés, travail inter-packages. |
| [context-economics.md](context-economics.md) | Ce que votre configuration coûte réellement par tour, comment le mesurer, et comment scoper hooks, plugins et autonomie à une seule section du dépôt. |

### Automatiser

| Guide | Ce que vous y trouvez |
|-------|------------------------|
| [hooks-and-automation.md](hooks-and-automation.md) | Événements de hooks, contrats d'entrée/sortie, le motif pre-commit façon husky, et les scripts shell qui valent le coup. |
| [agents-and-autonomy.md](agents-and-autonomy.md) | Sous-agents, tâches de fond, sessions de fond et agent view, travail planifié — et comment rendre un agent sûr à laisser seul. |
| [ticket-workflow.md](ticket-workflow.md) | Un pipeline ticket reproductible : cadrage → implémentation → revue → rapport, avec des artefacts au lieu de souvenirs. |
| [dual-ai-challenge.md](dual-ai-challenge.md) | Deux modèles sur un artefact : l'un construit, l'autre attaque, un humain arbitre. Les quatre façons dont ce dispositif produit de la confiance sans information, et la contre-mesure de chacune. |

### Configurations prêtes à l'emploi

| | Ce que c'est |
|--|--------------|
| [template : monorepo d'entreprise](template-enterprise-monorepo.md) | Une configuration complète et fonctionnelle pour un dépôt multi-répertoires piloté par tickets : conventions, règles limitées au chemin, skills par répertoire, quatre sous-agents, sept hooks, et une batterie pre-commit partagée par les humains et Claude. |
| [template : spec-driven](template-spec-driven.md) | Dix phases, chacune écrivant un artefact durable, chacune contredite par un second modèle avant qu'un humain ne l'approuve. Pour le travail où construire la mauvaise chose coûte cher et où le raisonnement doit survivre à la session. |
| [plugin : review-gate](../../plugins/review-gate/README.md) | Le même garde-fou qualité, en plugin portable et versionné. |

## Comment utiliser ces docs

1. Commencez par [configuration.md](configuration.md) pour comprendre *où* vit
   la config et *comment* elle se superpose.
2. Lisez [choosing-a-primitive.md](choosing-a-primitive.md) avant d'écrire la
   moindre config — c'est la décision dont tout le reste découle.
3. Copiez [le template](template-enterprise-monorepo.md) et adaptez-le, plutôt
   que de partir d'un répertoire vide.
4. Adoptez ce qui vous convient dans [best-practices.md](best-practices.md).

Tout ici est fait pour être **copié et adapté** — prenez ce qui est utile pour
votre propre configuration `~/.claude/` (globale) ou `.claude/` (projet).

## Références officielles

- Documentation Claude Code : <https://code.claude.com/docs/en/overview>
- Commandes slash : <https://code.claude.com/docs/en/slash-commands>
- Réglages (settings) : <https://code.claude.com/docs/en/settings>
- Mémoire (`CLAUDE.md`) : <https://code.claude.com/docs/en/memory>
- Hooks : <https://code.claude.com/docs/en/hooks>
- MCP : <https://code.claude.com/docs/en/mcp>

> Claude Code évolue vite. En cas de doute, la documentation officielle
> ci-dessus fait foi ; ce dépôt est un compagnon pratique et sélectif.

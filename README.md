<!-- Language: [English](#english) · [Français](#français) -->

# claude-config

> A curated collection of [Claude Code](https://docs.claude.com/en/docs/claude-code) configurations, commands, and best practices — organized by use case.
>
> Une collection de configurations, commandes et bonnes pratiques pour [Claude Code](https://docs.claude.com/en/docs/claude-code) — organisée par cas d'usage.

---

## English

### What is this?

`claude-config` is a reference repository that gathers reusable settings and
documentation for getting the most out of Claude Code. It is not a program to
install — it is a knowledge base you can browse, copy from, and adapt to your
own global or per-project setup.

### Contents

| Path | Description |
|------|-------------|
| [`docs/`](docs/) | The knowledge base — configuration model, primitive-choice guide, frontmatter reference, hooks, agents, monorepos, ticket workflow. |
| [`templates/enterprise-monorepo/`](templates/enterprise-monorepo/) | **A complete working setup** for a multi-directory, ticket-driven repo: conventions, path-scoped rules, per-directory skills, 4 subagents, 7 hooks, and a pre-commit battery shared by humans and Claude. |
| [`templates/spec-driven/`](templates/spec-driven/) | **A ten-phase pipeline** where every phase writes a durable artifact and a second model attacks it before a human approves it: reflection, analysis, tasks, pseudo-code, comment-driven scaffolding, implementation, tests, docs, project map, recap. |
| [`plugins/review-gate/`](plugins/review-gate/) | The same quality gate as a portable, versioned plugin, with a local marketplace. |
| [`.claude/`](.claude/) | Example shared configuration you can reuse. |

Not sure where a behaviour belongs — memory, a rule, a skill, a subagent, a hook,
or a plugin? Start with
[`docs/choosing-a-primitive.md`](docs/choosing-a-primitive.md).

> Docs are also available in French under [`docs/fr/`](docs/fr/).

### Quick start

```bash
git clone https://github.com/YohanGH/claude-config.git
cd claude-config
```

Then open [`docs/`](docs/) and copy what you need into your own
`~/.claude/` (global) or project `.claude/` directory.

### Contributing

Contributions are welcome — see [CONTRIBUTING.md](CONTRIBUTING.md).

### License

Released under the [MIT License](LICENSE.md).

---

## Français

### C'est quoi ?

`claude-config` est un dépôt de référence qui rassemble des réglages
réutilisables et de la documentation pour tirer le meilleur de Claude Code.
Ce n'est pas un programme à installer — c'est une base de connaissances que
vous pouvez parcourir, copier et adapter à votre configuration globale ou par
projet.

### Contenu

| Chemin | Description |
|--------|-------------|
| [`docs/fr/`](docs/fr/) | La base de connaissances — modèle de configuration, guide de choix de primitive, référence frontmatter, hooks, agents, monorepos, workflow ticket. |
| [`templates/enterprise-monorepo/`](templates/enterprise-monorepo/) | **Une configuration complète et fonctionnelle** pour un dépôt multi-répertoires piloté par tickets : conventions, règles limitées au chemin, skills par répertoire, 4 sous-agents, 7 hooks, et une batterie pre-commit partagée par les humains et Claude. ([présentation FR](docs/fr/template-enterprise-monorepo.md)) |
| [`templates/spec-driven/`](templates/spec-driven/) | **Un pipeline en dix phases** où chaque phase écrit un artefact durable, attaqué par un second modèle avant qu'un humain ne l'approuve : réflexion, analyse, task, pseudo-code, commentaires d'intention, implémentation, tests, doc, cartographie, recap. ([présentation FR](docs/fr/template-spec-driven.md)) |
| [`plugins/review-gate/`](plugins/review-gate/) | Le même garde-fou qualité, en plugin portable et versionné, avec une marketplace locale. |
| [`.claude/`](.claude/) | Exemple de configuration partagée réutilisable. |

Vous hésitez sur l'endroit où placer un comportement — mémoire, règle, skill,
sous-agent, hook ou plugin ? Commencez par
[`docs/fr/choosing-a-primitive.md`](docs/fr/choosing-a-primitive.md).

> Docs aussi disponibles en anglais dans [`docs/`](docs/).

### Démarrage rapide

```bash
git clone https://github.com/YohanGH/claude-config.git
cd claude-config
```

Ouvrez ensuite [`docs/`](docs/) et copiez ce dont vous avez besoin dans votre
dossier `~/.claude/` (global) ou `.claude/` (projet).

### Contribuer

Les contributions sont les bienvenues — voir [CONTRIBUTING.md](CONTRIBUTING.md).

### Licence

Distribué sous [licence MIT](LICENSE.md).

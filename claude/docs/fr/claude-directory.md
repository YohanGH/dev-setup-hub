<!-- Langue : [English](../claude-directory.md) · Français -->

# Le répertoire `.claude`

Claude Code lit sa configuration depuis **deux emplacements `.claude`** qui se
superposent :

- **Projet** — `.claude/` à la racine du dépôt : ce que l'*équipe* partage (versionné).
- **Utilisateur / global** — `~/.claude/` dans votre dossier personnel : *votre*
  configuration valable pour tous les projets (jamais versionnée).

Cette page cartographie ce que contient chacun, pour savoir où placer chaque
élément de configuration.

> Source de vérité : <https://code.claude.com/docs/en/claude-directory>.

---

## Les trois « badges »

Chaque fichier ci-dessous est de l'un de ces types :

| Badge | Signification | Versionner dans git ? |
|-------|---------------|-----------------------|
| **committed** | Partagé avec l'équipe via le gestionnaire de versions. | ✅ oui |
| **gitignored** | À vous, spécifique au projet, hors de git. | ❌ non (à gitignorer) |
| **local** | Sous `~/.claude/`, personnel à votre machine. | s.o. |

---

## `.claude/` du projet (partagé avec l'équipe)

Tout ici est versionné pour que toute l'équipe ait la même configuration Claude Code.

```text
votre-projet/
├── CLAUDE.md                  # committed  · Instructions lues à chaque session
├── .mcp.json                  # committed  · Serveurs MCP du projet, partagés avec l'équipe
├── .worktreeinclude           # committed  · Fichiers gitignorés à copier dans les nouveaux worktrees
└── .claude/
    ├── settings.json          # committed  · Permissions, hooks, modèle, env
    ├── settings.local.json    # gitignored · Vos surcharges perso pour CE projet
    ├── rules/                 # Instructions par thème, filtrables par chemin de fichier
    │   ├── testing.md         # committed  · ex. conventions de test limitées aux fichiers de test
    │   └── api-design.md      # committed  · ex. conventions d'API limitées au back-end
    ├── skills/                # Prompts réutilisables invoqués par vous ou Claude
    │   └── security-review/   # Un skill = un dossier avec SKILL.md + fichiers annexes
    │       ├── SKILL.md       # committed  · Point d'entrée : déclencheur, invocation, instructions
    │       └── checklist.md   # committed  · Fichier annexe fourni avec le skill
    ├── commands/              # Commandes slash mono-fichier
    │   └── fix-issue.md       # committed  · Invoquée via /fix-issue
    ├── agents/                # Sous-agents spécialisés, chacun avec son propre contexte
    │   └── code-reviewer.md   # committed  · Sous-agent pour revue de code isolée
    ├── output-styles/         # Styles de sortie du projet, si l'équipe en partage
    ├── workflows/             # Scripts de workflow orchestrant plusieurs sous-agents
    └── agent-memory/          # committed  · Mémoire persistante des sous-agents (gérée par Claude)
        └── <nom-agent>/
            └── MEMORY.md
```

### À quoi sert chaque élément

| Chemin | Rôle |
|--------|------|
| `CLAUDE.md` | Mémoire projet toujours active (conventions, commandes, architecture). Chargée à chaque session — gardez-la légère. Voir [configuration.md](configuration.md#2-mémoire-claudemd). |
| `.mcp.json` | Outils supplémentaires (bases, navigateurs, trackers) partagés avec l'équipe. |
| `.claude/settings.json` | Permissions, hooks, modèle, env — le contrat de comportement partagé. |
| `.claude/settings.local.json` | Vos surcharges propres à la machine. **À gitignorer.** |
| `.claude/rules/` | Instructions découpées par thème ; ajoutez une frontmatter `paths:` pour ne les charger que sur les fichiers concernés. Idéal pour les gros dépôts. |
| `.claude/skills/` | Workflows répétables chargés **à la demande** — la façon économe en contexte d'ajouter des capacités (voir [rules-and-skills.md](rules-and-skills.md)). |
| `.claude/commands/` | Commandes slash mono-fichier (voir [commands.md](commands.md#commandes-slash-personnalisées)). |
| `.claude/agents/` | Sous-agents à contexte isolé pour les sous-tâches larges ou parallèles. |
| `.claude/agent-memory/` | Là où les sous-agents gardent leur propre mémoire automatique. |

---

## `~/.claude/` utilisateur (personnel, tous projets)

Votre configuration globale — préférences et extensions qui vous suivent partout.
Rien ici n'est versionné dans un projet.

```text
~/
├── .claude.json               # local · État applicatif et préférences d'UI
└── .claude/
    ├── CLAUDE.md              # local · Préférences perso pour tous les projets
    ├── settings.json          # local · Vos réglages par défaut pour tous les projets
    ├── keybindings.json       # local · Raccourcis clavier personnalisés
    ├── themes/                # local · Thèmes de couleurs personnalisés
    ├── rules/                 # local · Règles utilisateur appliquées à tous les projets
    ├── skills/                # local · Skills perso disponibles partout
    ├── commands/              # local · Commandes mono-fichier perso disponibles partout
    ├── output-styles/         # local · Sections de system-prompt perso (ex. teaching.md)
    ├── agents/                # local · Sous-agents perso disponibles partout
    ├── workflows/             # local · Workflows dynamiques perso
    └── projects/
        └── <projet>/memory/   # Mémoire auto que Claude écrit pour lui-même, par dépôt
            ├── MEMORY.md      # local · Index concis, chargé chaque session (200 lignes / 25 Ko max)
            └── debugging.md   # local · Notes par thème quand MEMORY.md grossit
```

> `~/.claude/projects/<projet>/memory/` est la **mémoire automatique** : Claude
> l'écrit lui-même à partir de vos corrections. `MEMORY.md` est plafonné aux 200
> premières lignes / 25 Ko au chargement — contrairement à `CLAUDE.md`, toujours
> chargé en entier (voir [configuration.md](configuration.md#quelle-taille-maximale-pour-un-claudemd-)).

---

## Projet ou utilisateur : où le mettre ?

Les mêmes noms de dossiers (`rules/`, `skills/`, `commands/`, `agents/`) existent
aux deux endroits. La règle générale :

| Mettez-le dans **`.claude/`** (projet) quand… | Mettez-le dans **`~/.claude/`** (utilisateur) quand… |
|-----------------------------------------------|------------------------------------------------------|
| L'équipe en a besoin et ça doit être versionné. | C'est une préférence personnelle. |
| C'est lié à *ce* code. | Ça doit vous suivre sur tous les dépôts. |
| ex. `CLAUDE.md` projet, commandes de test autorisées, skill propre au dépôt. | ex. votre modèle, raccourcis, commandes perso. |

Les règles utilisateur se chargent **avant** les règles projet : en cas de
recouvrement, les réglages du projet l'emportent.

---

Voir [configuration.md](configuration.md) pour le modèle de configuration et
[commands.md](commands.md) pour les commandes, skills et sous-agents en détail.

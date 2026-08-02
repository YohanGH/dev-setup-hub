<!-- Langue : [English](../commands.md) · Français -->

# Commandes Claude Code

Une référence pratique des **commandes slash** de Claude Code, groupées par cas
d'usage, plus comment écrire les vôtres.

> Source faisant foi : <https://code.claude.com/docs/en/slash-commands>.
> Claude Code change souvent — tapez `/help` pour voir ce qui est disponible
> dans votre version.

---

## Commandes slash intégrées, par cas d'usage

### Gérer la conversation

| Commande | Rôle |
|----------|------|
| `/clear` | Efface l'historique et repart sur une base neuve. |
| `/compact [instructions]` | Résume et compresse la conversation pour libérer du contexte. Les instructions optionnelles orientent ce qu'il faut garder. |
| `/cost` | Affiche l'usage de tokens et le coût de la session. |
| `/export` | Exporte la conversation vers un fichier ou le presse-papiers. |
| `/resume` | Reprend une conversation précédente. |

### Installation & diagnostic

| Commande | Rôle |
|----------|------|
| `/help` | Liste les commandes disponibles et l'aide. |
| `/status` | Affiche version, compte et informations de connexion. |
| `/doctor` | Vérifie la santé de votre installation Claude Code. |
| `/config` | Ouvre l'interface de réglages pour voir ou modifier la config. |
| `/terminal-setup` | Installe le raccourci `Shift+Entrée` pour la saisie multi-ligne. |
| `/vim` | Active/désactive l'édition façon vim dans l'invite. |

### Compte & modèle

| Commande | Rôle |
|----------|------|
| `/login` | Se connecte ou change de compte Anthropic. |
| `/logout` | Se déconnecte. |
| `/model` | Sélectionne ou change le modèle actif. |

### Contexte projet & mémoire

| Commande | Rôle |
|----------|------|
| `/init` | Analyse le projet et génère un `CLAUDE.md` de départ. |
| `/memory` | Ouvre et édite vos fichiers mémoire `CLAUDE.md`. |
| `/add-dir` | Ajoute un autre dossier de travail à la session. |

### Permissions & outils

| Commande | Rôle |
|----------|------|
| `/permissions` | Voir ou modifier les permissions d'outils (allow / ask / deny). |
| `/agents` | Créer et gérer des sous-agents personnalisés. |
| `/hooks` | Configurer des hooks autour des appels d'outils et des événements. |
| `/mcp` | Gérer les connexions et l'authentification des serveurs MCP. |

### Revue de code & collaboration

| Commande | Rôle |
|----------|------|
| `/review` | Demande à Claude de relire les changements en cours. |
| `/pr-comments` | Récupère et traite les commentaires d'une pull request GitHub. |
| `/bug` | Signale un problème de Claude Code à Anthropic. |

> L'ensemble exact des commandes intégrées peut varier d'une version à l'autre.
> Faites toujours confiance à `/help` plutôt qu'à une liste figée.

---

## Commandes slash personnalisées

Vous pouvez définir vos propres commandes sous forme de fichiers Markdown. Le
nom du fichier devient le nom de la commande.

| Portée | Emplacement | Apparaît comme |
|--------|-------------|----------------|
| **Projet** (partagé via git) | `.claude/commands/<nom>.md` | `/nom` (projet) |
| **Personnel** (tous vos projets) | `~/.claude/commands/<nom>.md` | `/nom` (utilisateur) |

Les sous-dossiers créent des espaces de noms :
`.claude/commands/git/commit.md` → `/git:commit`.

### Exemple minimal

`.claude/commands/review-branch.md` :

```markdown
---
description: Relire la branche courante par rapport à main
argument-hint: [base-branch]
allowed-tools: Bash(git diff:*), Bash(git log:*)
model: claude-sonnet-5
---

Relis les changements de la branche courante par rapport à `$1` (défaut `main`).

Diff actuel :

!`git diff --stat`

Concentre-toi sur la justesse, puis la lisibilité. Sois concis.
```

À lancer avec :

```
/review-branch main
```

### Ce que vous pouvez mettre dans une commande

| Fonction | Syntaxe | Utilité |
|----------|---------|---------|
| Frontmatter | `--- ... ---` en tête | Métadonnées : `description`, `argument-hint`, `allowed-tools`, `model`. |
| Tous les arguments | `$ARGUMENTS` | Tout ce que l'utilisateur tape après le nom de la commande. |
| Arguments positionnels | `$1`, `$2`, … | Arguments individuels. |
| Sortie Bash | `` !`commande` `` | Exécute la commande et inline sa sortie (nécessite `allowed-tools`). |
| Contenu de fichier | `@chemin/vers/fichier` | Inline le contenu d'un fichier dans l'invite. |

### Astuces

- Une commande = une tâche ; composez plutôt que de construire une méga-commande.
- Ajoutez un `argument-hint` pour que la commande se documente dans le sélecteur.
- Restreignez `allowed-tools` au minimum nécessaire.
- Rangez les commandes d'équipe dans `.claude/commands/` (versionnées) et vos
  commandes personnelles dans `~/.claude/commands/`.

Voir aussi [configuration.md](configuration.md) pour la place des commandes dans
le modèle de configuration, et [best-practices.md](best-practices.md) pour bien
les utiliser.

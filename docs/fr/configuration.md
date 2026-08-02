<!-- Langue : [English](../configuration.md) · Français -->

# Configurer Claude Code

Tout ce que vous pouvez confier à Claude Code pour façonner son comportement —
pour un seul projet ou globalement pour tous.

> Source faisant foi : <https://code.claude.com/docs/en/settings>.

---

## Vue d'ensemble

Claude Code lit la configuration à plusieurs endroits et **les superpose**. Il y
a deux choses à configurer :

1. **Réglages** (`settings.json`) — comportement, permissions, hooks, modèle, env.
2. **Mémoire** (`CLAUDE.md`) — instructions persistantes et contexte du projet.

Plus les **serveurs MCP** (outils supplémentaires) et les
**commandes / sous-agents / hooks** couverts dans [commands.md](commands.md).

---

## 1. Fichiers de réglages (`settings.json`)

### Où ils vivent

| Portée | Chemin | Versionner dans git ? |
|--------|--------|------------------------|
| **Utilisateur / global** | `~/.claude/settings.json` | n/a (machine perso) |
| **Projet (partagé)** | `.claude/settings.json` | ✅ oui — partagé avec l'équipe |
| **Projet (local)** | `.claude/settings.local.json` | ❌ non — à gitignorer |
| **Entreprise (managed)** | Chemin système selon l'OS | Défini par les administrateurs |

### Précédence (le plus fort gagne)

```
Managed entreprise  >  Args ligne de commande  >  .claude/settings.local.json
                    >  .claude/settings.json  >  ~/.claude/settings.json
```

Les réglages locaux du projet l'emportent donc sur les réglages partagés du
projet, qui l'emportent sur vos réglages globaux.

### Champs courants

```jsonc
{
  // Quel modèle utiliser par défaut
  "model": "claude-sonnet-5",

  // Variables d'environnement injectées dans la session
  "env": {
    "MY_PROJECT_ENV": "staging"
  },

  // Permissions : ce que Claude peut exécuter sans demander
  "permissions": {
    "allow": [
      "Bash(npm run test:*)",
      "Bash(git status)",
      "Read(./src/**)"
    ],
    "ask": [
      "Bash(git push:*)"
    ],
    "deny": [
      "Read(./.env)",
      "Read(./secrets/**)"
    ],
    "defaultMode": "acceptEdits",
    "additionalDirectories": ["../shared-lib"]
  },

  // Ajoute une ligne Co-Authored-By aux commits faits par Claude
  "includeCoAuthoredBy": true,

  // Nombre de jours avant nettoyage des anciens transcripts
  "cleanupPeriodDays": 30
}
```

> Les commentaires façon `.jsonc` ne servent que d'illustration ici — le vrai
> `settings.json` doit être du JSON valide (sans commentaires).

### Astuces d'édition

- Lancez `/config` pour ouvrir l'UI des réglages plutôt que d'éditer à la main.
- Lancez `/permissions` pour ajuster les listes allow / ask / deny.
- **Pas de secrets** dans `settings.json` ; utilisez `env` pour des références,
  pas des valeurs.

---

## 2. Mémoire (`CLAUDE.md`)

Les fichiers `CLAUDE.md` sont des instructions que Claude lit automatiquement au
démarrage d'une session. À utiliser pour les conventions, notes d'architecture
et les « toujours faire X ».

| Portée | Chemin | Rôle |
|--------|--------|------|
| **Utilisateur / global** | `~/.claude/CLAUDE.md` | Préférences valables pour tous vos projets. |
| **Projet (partagé)** | `./CLAUDE.md` | Conventions d'équipe, versionnées dans git. |
| **Projet (local)** | `./CLAUDE.local.md` | Notes perso non versionnées (à gitignorer). |

### En générer un

Lancez `/init` dans un projet pour que Claude analyse le code et rédige un
`CLAUDE.md`. Puis élaguez-le pour ne garder que l'essentiel.

### Imports

Un `CLAUDE.md` peut inclure d'autres fichiers pour éviter les répétitions :

```markdown
Voir @docs/architecture.md pour l'organisation des modules.
Suivre les règles de code dans @~/.claude/my-standards.md.
```

### Ce qui fait un bon `CLAUDE.md`

- **Court et précis** — des règles en puces valent mieux qu'un long texte.
- Les commandes à lancer (test, lint, build) et comment les lancer.
- Les conventions non évidentes à la lecture du code.
- Ce que Claude se trompe régulièrement — encodez la correction.

Éditez à tout moment avec `/memory`.

### Quelle taille maximale pour un `CLAUDE.md` ?

Il n'y a **aucune limite stricte de caractères** : un `CLAUDE.md` est chargé **en
entier**, quelle que soit sa longueur. Mais la longueur a un coût réel — il est
injecté dans la fenêtre de contexte au démarrage de *chaque* session, consomme des
tokens et, au-delà d'un certain point, *réduit* l'adhérence (Claude a plus à trier).

- **Cible : moins de ~200 lignes** par fichier. C'est la recommandation officielle,
  pas un plafond strict — le fichier se charge même s'il est plus long.
- S'il grossit, n'empilez pas. Préférez :
  - Déplacer les instructions propres à un type de fichier vers [`.claude/rules/`](https://code.claude.com/docs/en/memory#organize-rules-with-.claude%2Frules%2F)
    avec une frontmatter `paths:`, pour qu'elles ne se chargent que sur les fichiers concernés.
  - Déplacer les procédures répétables et ciblées vers un [Skill ou une commande](commands.md)
    (chargés à la demande, pas à chaque session).
  - Utiliser les imports `@chemin` pour organiser — mais attention, les fichiers
    importés **se chargent aussi au lancement** : ça range, ça ne réduit pas le contexte.

> La limite **200 lignes / 25 Ko** que vous avez peut-être vue concerne la
> **mémoire automatique** (`MEMORY.md`, que Claude écrit lui-même) — seuls ses 200
> premières lignes ou 25 Ko sont chargés. Ce plafond ne s'applique **pas** au
> `CLAUDE.md`, toujours chargé en entier.

---

## 3. Serveurs MCP (outils supplémentaires)

[MCP](https://code.claude.com/docs/en/mcp) permet à Claude Code de parler à des
outils externes (bases de données, navigateurs, gestion de tickets…).

| Portée | Où | Partagé ? |
|--------|----|-----------|
| **Local** | votre machine seulement | non |
| **Projet** | `.mcp.json` à la racine du dépôt | ✅ versionné |
| **Utilisateur** | votre config utilisateur | non |

Ajouter depuis la CLI :

```bash
claude mcp add my-server -- npx -y @scope/my-mcp-server
```

Gérez connexions et OAuth depuis une session avec `/mcp`.

Exemple de `.mcp.json` :

```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "./"]
    }
  }
}
```

> N'ajoutez que des serveurs MCP de confiance — ils peuvent lire des données et
> exécuter des actions.

---

## 4. D'autres réglages utiles

`settings.json` accepte de nombreuses clés. Voici une sélection des plus utiles
au quotidien. Pour la **liste exhaustive et à jour**, voir la référence
officielle : <https://code.claude.com/docs/en/settings>.

### Modèle & réflexion

| Clé | Type | Rôle |
|-----|------|------|
| `model` | string | Modèle par défaut (lu une fois au démarrage). |
| `fallbackModel` | array | Chaîne de repli (jusqu'à 3) si le principal est saturé. |
| `effortLevel` | string | Persiste l'effort : `"low"`, `"medium"`, `"high"`, `"xhigh"`. |
| `alwaysThinkingEnabled` | boolean | Active la réflexion étendue par défaut. |
| `maxThinkingTokens` | number | Plafonne les tokens de réflexion. |

### Git & commits

| Clé | Type | Rôle |
|-----|------|------|
| `includeCoAuthoredBy` | boolean | Ajoute une ligne `Co-Authored-By` aux commits (défaut `false`). |
| `attribution` | object | Personnalise le texte d'attribution commit / PR (ou le vide). |
| `gitCommitTemplate` | string | Modèle des messages de commit générés. |
| `gitPushAutomatically` | boolean | Push automatique après commit (défaut `false`). |
| `gitRemoteName` | string | Remote utilisé pour les opérations git (défaut `"origin"`). |

### Session & contexte

| Clé | Type | Rôle |
|-----|------|------|
| `autoCompactEnabled` | boolean | Compaction auto près de la limite de contexte (défaut `true`). |
| `cleanupPeriodDays` | number | Supprime les transcripts après N jours (défaut `30`). |
| `fileCheckpointingEnabled` | boolean | Snapshot des fichiers avant édition pour `/rewind` (défaut `true`). |
| `outputStyle` | string | Style de mise en forme de la sortie (lu au démarrage). |
| `claudeMdExcludes` | array | Motifs glob de `CLAUDE.md` à ignorer. |

### UI & éditeur

| Clé | Type | Rôle |
|-----|------|------|
| `theme` | string | `"dark"`, `"light"` ou `"auto"`. |
| `editorMode` | string | `"normal"` ou `"vim"`. |
| `statusLine` | string/object | Barre de statut personnalisée. |
| `spinnerTipsEnabled` | boolean | Affiche des astuces à côté du spinner d'activité. |

### Approbation MCP

| Clé | Type | Rôle |
|-----|------|------|
| `enableAllProjectMcpServers` | boolean | Approuve automatiquement tous les serveurs de `.mcp.json`. |
| `enabledMcpjsonServers` | array | N'approuve que certains serveurs de `.mcp.json`. |
| `disabledMcpjsonServers` | array | Rejette certains serveurs de `.mcp.json`. |

### Auth & hooks

| Clé | Type | Rôle |
|-----|------|------|
| `apiKeyHelper` | string | Commande qui produit la valeur d'auth pour les requêtes API. |
| `hooks` | object | Hooks de cycle de vie autour des outils et événements (voir plus bas). |

### Variables d'environnement (`env`)

Toute variable définie ici est injectée dans chaque session. Quelques-unes
courantes :

| Variable | Rôle |
|----------|------|
| `DISABLE_AUTO_COMPACT` | Désactive la compaction automatique. |
| `DISABLE_AUTOUPDATER` | Désactive les mises à jour automatiques. |
| `CLAUDE_CODE_ENABLE_TELEMETRY` | Active/désactive la télémétrie. |
| `MAX_THINKING_TOKENS` | Plafonne les tokens de réflexion (`0` désactive). |

```json
{
  "env": {
    "DISABLE_AUTOUPDATER": "1",
    "MY_PROJECT_ENV": "staging"
  }
}
```

### Hooks (aperçu)

Les hooks exécutent vos propres commandes automatiquement autour des actions de
Claude — par exemple lancer un formateur après chaque édition, ou bloquer un
outil avant son exécution.

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          { "type": "command", "command": "npx prettier --write $CLAUDE_FILE_PATHS" }
        ]
      }
    ]
  }
}
```

Configurez-les avec `/hooks`. Référence complète :
<https://code.claude.com/docs/en/hooks>.

### Modes de permission

`permissions.defaultMode` définit comment Claude demande avant d'agir. Les modes
disponibles évoluent selon les versions — vérifiez avec `/permissions` ce que
propose la vôtre. Les valeurs courantes incluent `default` (demande au besoin)
et `acceptEdits` (accepte automatiquement les éditions de fichiers). Préférez le
réglage via `/permissions` aux suppositions.

### Réglages entreprise / managed

Les organisations peuvent imposer une politique via des **réglages managed** qui
priment sur tout le reste (allowlist de serveurs MCP, épinglage de versions,
injection d'un `CLAUDE.md` d'entreprise, etc.). Ils vivent dans des chemins
système spécifiques à l'OS et sont posés par les administrateurs — voir la doc
officielle si vous gérez un parc.

---

## 5. Choisir global vs. projet

| Mettez-le en **global** (`~/.claude/`) quand… | Mettez-le dans le **projet** (`.claude/`) quand… |
|-----------------------------------------------|--------------------------------------------------|
| Ça reflète *votre* préférence personnelle. | Ça reflète une convention *d'équipe*. |
| Ça doit vous suivre sur tous vos dépôts. | Ça doit être partagé et versionné. |
| Ex. : votre modèle favori, commandes perso. | Ex. : commandes de test autorisées, `CLAUDE.md` du projet. |

**Règle générale :** versionnez ce dont l'équipe a besoin, gardez vos
particularités en global, et mettez les réglages propres à la machine ou
sensibles dans des fichiers `*.local.*` gitignorés.

---

## Fichiers d'exemple dans ce dépôt

- [`.claude/settings.example.json`](../../.claude/settings.example.json) — un
  point de départ à copier vers `.claude/settings.json` ou
  `~/.claude/settings.json`.

Voir [best-practices.md](best-practices.md) pour bien utiliser tout cela.

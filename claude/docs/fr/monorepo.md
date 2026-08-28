<!-- Langue : [English](../monorepo.md) · Français -->

# Monorepos & grands dépôts

Les réglages par défaut sont pensés pour de petits projets. Dans un grand dépôt,
ils remplissent la fenêtre de contexte d'instructions et de lectures sans rapport
avec la tâche — ce qui coûte des tokens et dégrade les résultats.

L'objectif est étroit : **limiter Claude à la partie du code que la tâche
touche.** Tout ce qui suit est un levier vers ça. Ils se superposent ; appliquez
ce dont votre dépôt a besoin.

Guide officiel :
<https://code.claude.com/docs/fr/large-codebases>.

## L'endroit où vous démarrez Claude décide presque tout

| Démarrer depuis | Accès fichiers | `CLAUDE.md` chargés | Skills en portée |
|-----------------|----------------|---------------------|------------------|
| Racine du dépôt | tout | racine uniquement ; les fichiers de sous-répertoires se chargent à la demande | chaque sous-répertoire touché — peut atteindre des centaines |
| Un sous-répertoire | ce sous-arbre | celui du répertoire, plus chaque ancêtre | ce répertoire, ses ancêtres, plus utilisateur et entreprise |

Si le travail tient dans un package, **démarrez Claude là**. C'est le geste le
plus efficace de cette page et il ne coûte aucune configuration.

Un piège qui surprend : `.claude/settings.json` se charge **uniquement depuis
votre répertoire de démarrage**. Il n'est pas hérité en remontant l'arbre comme
les `CLAUDE.md`. Un fichier de réglages par package doit être autonome.

## Superposer les CLAUDE.md par répertoire

```text
monorepo/
  CLAUDE.md                  # global : structure, conventions de commit, standards
  packages/api/
    CLAUDE.md                # stack, commandes et règles locales de ce package
    .claude/skills/
  packages/web/
    CLAUDE.md
    .claude/skills/
```

Le fichier racine oriente : quels sont les packages, où lancer les commandes.
Celui de chaque package porte le détail de sa stack. Démarrer dans
`packages/api/` charge racine + api, et jamais les conventions de
`packages/web/`.

Les garder vivants :

- Relire les changements de `CLAUDE.md` en PR comme toute autre doc.
- Les revisiter après une sortie majeure de modèle — une règle qui contournait une
  limitation ancienne devient du pur surcoût quand le modèle gère le cas seul.
- Un hook `Stop` peut proposer des mises à jour pendant que la lacune est fraîche.

### `CLAUDE.md` par répertoire ou règle limitée au chemin ?

| | `CLAUDE.md` par répertoire | `.claude/rules/*.md` avec `paths:` |
|--|---------------------------|-----------------------------------|
| Vit | dans le répertoire, près du code | centralement à la racine |
| Se charge | au lancement si démarré là ; à la demande à la lecture | quand Claude travaille sur un fichier correspondant |
| Idéal quand | les propriétaires maintiennent leurs conventions | une règle couvre des chemins dispersés, ou vous voulez tout au même endroit |

Utilisez les deux. La propriété suit le code ; les règles transverses restent
centrales.

## Skills par répertoire

N'importe quel sous-répertoire peut définir des skills limitées à sa stack. Elles
se chargent à la demande : l'outillage API ne coûte rien pendant du travail
frontend.

```bash
mkdir -p packages/api/.claude/skills/api-testing
```

```markdown
---
name: api-testing
description: Modèles de test du package API. Utiliser lors de l'écriture ou de la modification des tests dans packages/api/.
---

## Structure des tests
Les tests sont dans `src/__tests__/` reflétant `src/`...
```

Versionnez-les à côté du code qu'elles décrivent. Dans un monorepo, un jeu par
package ; dans un grand arbre unique, un par sous-système
(`src/db/.claude/skills/`).

Alternative : cibler par motif plutôt que par emplacement. Le champ frontmatter
`paths:` prend des globs, donc une skill du `.claude/skills/` racine peut ne
s'appliquer qu'à `**/migrations/**`, où qu'elles se trouvent.

### Garder les skills découvrables

Claude choisit une skill en lisant le nom et la description de chaque skill
découverte ; seul le corps de celle retenue se charge. Avec des skills dispersées
dans de nombreux répertoires, cette liste s'allonge, et **les descriptions sont
tronquées quand elles sont nombreuses** — ce qui peut couper précisément les
mots-clés qui auraient déclenché la correspondance.

- Commencez la description par les mots d'une demande réelle : *« écrire ou
  modifier les tests dans `packages/api` »*, pas *« utilitaires de test »*.
- Les skills partagées par de nombreux répertoires — conventions de PR, checklist
  de déploiement — vont dans le `.claude/skills/` **racine**, pour se charger
  depuis n'importe quel répertoire de démarrage.
- Les skills partagées qui ont besoin de leur propre historique de version, ou
  doivent servir entre dépôts, deviennent un
  [plugin](../../plugins/review-gate/). Les skills de plugin sont préfixées
  `plugin:skill` : jamais de collision avec celles par répertoire.
- Pour trouver les skills mortes : activez l'exportateur de logs OpenTelemetry
  avec `OTEL_LOG_TOOL_DETAILS=1` et lisez l'événement `skill_activated`.

## Réduire ce qui est lu

Les recherches de contenu respectent déjà `.gitignore` : `node_modules/`, `dist/`
et `build/` restent hors des résultats gratuitement. Pour le code généré ou vendu
**versionné**, ajoutez des règles de refus :

```json
{
  "permissions": {
    "deny": [
      "Read(./**/dist/**)",
      "Read(./**/build/**)",
      "Read(./**/*.generated.*)",
      "Read(./vendor/**)"
    ]
  }
}
```

Elles couvrent les outils fichiers intégrés et les commandes Bash reconnues
(`cat`, `head`, `grep`, `find`) quand un chemin refusé est passé en argument.
Elles ne filtrent pas les chemins refusés de la sortie d'une recherche récursive,
et ne couvrent pas un sous-processus arbitraire qui ouvre les fichiers lui-même.

Associez cela à un **plugin d'intelligence du code**, pour que Claude saute à une
définition via un serveur de langage au lieu de scanner :

```shell
/plugin install typescript-lsp@claude-plugins-official
```

Activez-le pour tout le dépôt via le réglage projet `enabledPlugins`. Chaque
développeur doit avoir le binaire du serveur de langage installé.

## Exclure les instructions des autres équipes

Depuis la racine, le `CLAUDE.md` de chaque sous-répertoire se charge dès que
Claude y lit un fichier. `claudeMdExcludes` les ignore définitivement :

```json
{
  "claudeMdExcludes": [
    "**/packages/admin-dashboard/**",
    "**/packages/legacy-*/**"
  ]
}
```

Les motifs correspondent à des chemins **absolus** : les motifs de style relatif
doivent commencer par `**/`. Les tableaux fusionnent entre scopes — une équipe
pose les valeurs par défaut au niveau projet, chacun ajoute les siennes en local.
Un `CLAUDE.md` de politique gérée ne peut pas être exclu.

C'est une liste statique, pas un commutateur par tâche. Pour vous concentrer sur
un autre package aujourd'hui, démarrez Claude dans ce package plutôt que de
modifier les exclusions.

## Worktrees clairsemés

`--worktree` isole les modifications d'une session ; par défaut il extrait tout le
dépôt. Dans un grand dépôt, ne listez que le nécessaire :

```json
{
  "worktree": {
    "sparsePaths": [".claude", "packages/api", "packages/shared"],
    "symlinkDirectories": ["node_modules"]
  }
}
```

Les *fichiers* racine (`package.json`, lockfiles, `tsconfig.base.json`) sont
toujours extraits ; les *répertoires* racine non — **incluez `.claude`
explicitement** ou les réglages, règles et skills du dépôt manqueront dans le
worktree.

Tous les worktrees d'une session partagent un seul `sparsePaths` : listez chaque
répertoire dont les sous-agents parallèles ont besoin. Les réglages dans un
worktree se chargent depuis le `.claude/settings.json` de sa racine — la copie
versionnée du fichier racine du dépôt — donc les règles de refus et les hooks
doivent y exister, pas seulement dans un fichier par package.

## Travailler entre packages

Depuis `packages/api/`, modifier un type partagé exige l'accès au frère :

```json
{ "permissions": { "additionalDirectories": ["../shared", "../web"] } }
```

ou au lancement : `claude --add-dir ../shared`.

Ils diffèrent sur ce qui accompagne l'accès :

| Ajouté avec | Charge `CLAUDE.md` et règles | Charge les skills |
|-------------|------------------------------|-------------------|
| Réglage `additionalDirectories` | jamais | jamais |
| `--add-dir` / `/add-dir` | seulement avec `CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1` | oui |

Pour un changement à cheval sur plusieurs packages, deux habitudes comptent plus
que la configuration : **donner tout le changement à Claude en une session**, pour
que les décisions derrière chaque édition restent cohérentes, et **écrire le plan
dans un fichier d'abord** — une longue session inter-packages compacte son
contexte, et le plan sauvegardé survit là où la conversation peut ne pas le
faire. C'est exactement ce que produit
[`/ticket-scope`](ticket-workflow.md).

## Quand la superposition cesse de passer à l'échelle

Les fichiers par répertoire dérivent, deviennent obsolètes, et personne ne
possède la racine. À ce stade, sortez le contenu de la mémoire toujours chargée
vers des mécanismes qui se chargent à la demande :

- **Skills** — matériel de référence, chargé seulement si pertinent.
- **Plugins** — bundles versionnés de skills, hooks et commandes qu'une équipe
  plateforme possède centralement.
- **Serveurs MCP** — si vous exploitez déjà une recherche de code ou un index
  RAG, exposez-le comme outil pour que Claude l'interroge au lieu de lire.

Un hook `SessionStart` comble le manque de découvrabilité : lire le répertoire de
lancement depuis l'entrée du hook, le chercher dans une carte chemin→plugin
versionnée, et imprimer la recommandation — stdout à `SessionStart` devient du
contexte avant le premier prompt.

## Assembler le tout

```text
monorepo/
  CLAUDE.md
  .claude/settings.json                   # règles de refus pour les sessions de worktree
  packages/api/
    CLAUDE.md
    .claude/settings.json                 # worktree, additionalDirectories, refus
    .claude/skills/api-testing/SKILL.md
  packages/web/
    CLAUDE.md
    .claude/skills/component-patterns/SKILL.md
  packages/shared/
    CLAUDE.md
```

Démarré depuis `packages/api/`, Claude charge les `CLAUDE.md` racine et api mais
pas celui de web, lit et modifie `api` et `shared`, ignore `dist/`, dispose de
`api-testing` à la demande, et crée des worktrees contenant trois répertoires au
lieu de tout l'arbre.

Une version complète et fonctionnelle :
[`templates/enterprise-monorepo`](../../templates/enterprise-monorepo/).

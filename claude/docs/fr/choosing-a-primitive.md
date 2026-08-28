<!-- Langue : [English](../choosing-a-primitive.md) · Français -->

# Choisir la bonne primitive

Claude Code offre huit endroits où placer un comportement. Se tromper d'endroit
est l'erreur de configuration la plus répandue — non parce que ça échoue, mais
parce que ça fonctionne mal et cher, et que personne ne le remarque.

Voici le guide de décision.

## La réponse en un écran

| Le comportement est… | À mettre dans | Chargé |
|----------------------|---------------|--------|
| Toujours vrai, une ligne, nécessaire à chaque tour | **`CLAUDE.md`** | chaque session, intégralement |
| Vrai seulement pour certains chemins | **`.claude/rules/*.md`** avec `paths:` | quand Claude lit un fichier correspondant |
| Une procédure répétable que Claude doit reprendre seul | **Skill** | description toujours ; corps seulement à l'usage |
| Une procédure que *vous seul* devez déclencher | **Skill/commande** + `disable-model-invocation: true` | corps seulement quand vous l'exécutez |
| Une sous-tâche bruyante à isoler | **Sous-agent** | sa propre fenêtre de contexte |
| Ce qui doit arriver à chaque fois, quoi que décide le modèle | **Hook** | jamais — c'est une commande shell |
| Les mêmes règles sur plusieurs dépôts | **Plugin** | quand il est activé |
| Des données vivantes ou un système externe | **Serveur MCP** | à l'appel d'outil |

**Règle empirique** : *toujours vrai et minuscule → mémoire. Parfois pertinent →
skill. Déterministe → hook. Multi-dépôts → plugin.*

## Le compromis dont tout découle

Le contexte n'est pas gratuit. Tout ce qui est toujours chargé est payé à
**chaque** requête et entre en concurrence avec la tâche en cours. Un fichier de
règles de 300 lignes coûte deux fois : des tokens à chaque tour, et un signal
dilué — le modèle doit retrouver les trois lignes pertinentes parmi trois cents.

C'est pourquoi le fichier de règles maximaliste toujours actif sous-performe. Le
mode d'échec n'est jamais « pas assez de règles » ; c'est « trop de règles
rarement pertinentes ».

**La divulgation progressive est la solution.** Une skill n'expose que sa
`description` en amont ; le corps se charge quand la tâche correspond. Cela passe
à l'échelle sur des dizaines de capacités sans les payer toutes, tout le temps.

## Mémoire vs règles vs skills

On les confond en permanence. La différence tient à *quand le corps du fichier
entre dans la fenêtre de contexte*.

|  | `CLAUDE.md` | `.claude/rules/x.md` (avec `paths:`) | Skill |
|--|-------------|--------------------------------------|-------|
| Corps en contexte | toujours | quand un fichier correspondant est lu | à l'invocation ou si jugé pertinent |
| Coût quand non pertinent | complet | nul | ~1 ligne (la description) |
| Bon pour | commandes de build, structure du dépôt, non-négociables | conventions par zone | procédures, checklists, référence |
| Mauvais pour | tout ce qui est long ou conditionnel | ce qui n'a pas de périmètre de chemin naturel | les faits nécessaires à chaque tour |

Une règle **sans** `paths:` se charge inconditionnellement — c'est une entrée de
`CLAUDE.md` dans un autre fichier. Très bien pour l'organisation, mais sans
aucun gain de contexte. Si vous avez écrit une règle pour économiser du
contexte, il lui faut `paths:`.

Deux façons de cibler une zone, toutes deux valides :

| | `CLAUDE.md` par répertoire | Règle limitée au chemin |
|--|---------------------------|-------------------------|
| Vit | dans le répertoire, à côté du code | centralement dans `.claude/rules/` |
| Appartient à | l'équipe de ce répertoire | qui possède la configuration |
| Idéal quand | les équipes maintiennent leurs conventions | une règle couvre des chemins dispersés |

## Skill vs commande

C'est **le même mécanisme**. `.claude/commands/deploy.md` et
`.claude/skills/deploy/SKILL.md` créent tous deux `/deploy` et acceptent le même
frontmatter. Les skills ajoutent un répertoire pour les fichiers de support et
l'invocation automatique.

Servez-vous des dossiers pour exprimer l'intention, comme le fait le
[template entreprise](../../templates/enterprise-monorepo/) :

- `commands/` — points d'entrée fins, à effets de bord, que **vous** déclenchez,
  tous avec `disable-model-invocation: true`.
- `skills/` — les méthodes et leur matériel de référence, que Claude peut charger
  seul.

La distinction qui compte vraiment est `disable-model-invocation`. Tout ce qui
écrit des fichiers, commite, déploie ou notifie un humain doit vous appartenir.
Vous ne voulez pas que Claude juge que le code *a l'air* prêt et livre.

## Skill vs sous-agent

| | Skill | Sous-agent |
|--|-------|-----------|
| S'exécute dans | votre contexte | sa propre fenêtre de contexte |
| Renvoie | tout ce qu'il fait | seulement son résumé |
| Outils/modèle/permissions propres | non | oui |
| À utiliser quand | la procédure est courte, ou sa sortie doit rester en ligne | le travail est bruyant : recherche large, revue de diff complet, sortie de tests longue |

La valeur du sous-agent, c'est **ce que vous ne voyez pas** : cinquante greps et
lectures deviennent une carte. Si la sortie intermédiaire de la sous-tâche ne
vous servira plus après, elle appartient à un sous-agent.

On peut aussi obtenir l'isolation sans définir d'agent : `context: fork` sur une
skill ou une commande. Ajoutez `agent: <nom>` pour forker vers un sous-agent
*précis* — c'est ainsi que `/review-scope` reste une commande de trois lignes
alors que le rôle de relecteur vit dans un seul fichier réutilisable.

## Quand ce doit être un hook

La mémoire et les skills sont du **contexte** : Claude les lit et s'y conforme
généralement. Il n'y a aucune application stricte.

Si la réponse à « et si Claude ne le fait pas ? » est inacceptable, c'est un
hook. Les hooks sont des commandes shell exécutées par le harnais à des
événements fixes, indépendamment de ce que décide le modèle.

À réécrire en hooks, systématiquement :

| Instruction qu'on réécrit sans cesse dans `CLAUDE.md` | Le hook |
|-------------------------------------------------------|---------|
| « Toujours lancer les tests avant de commiter » | `PreToolUse` sur `Bash(git commit *)` |
| « Ne jamais éditer les fichiers générés » | `PreToolUse` sur `Edit\|Write` |
| « Formater après édition » | `PostToolUse` sur `Edit\|Write`, `async` |
| « Ne pas finir sur un build cassé » | `Stop` |
| « M'indiquer la branche et le ticket au démarrage » | `SessionStart` |

Voir [hooks-and-automation.md](hooks-and-automation.md).

## Autonome ou plugin ?

| | `.claude/` dans le dépôt | Plugin |
|--|--------------------------|--------|
| Portée | ce dépôt | tout dépôt qui l'active |
| Nommage | `/deploy` | `/mon-plugin:deploy` |
| Mise à jour partout | copier-coller, dérive | on incrémente la version |
| Peut référencer les conventions du dépôt | oui | seulement en s'y déférant |
| Idéal pour | le spécifique au projet, l'itération rapide | l'application partagée, la distribution en équipe |

Commencez en autonome. Convertissez en plugin quand un **deuxième dépôt** a
besoin de la même chose — c'est ça le signal, pas la taille de la configuration.

Le partage qui tient : **les instructions propres au dépôt restent dans le
dépôt ; l'application qui doit être identique partout devient un plugin.** Le
[plugin `review-gate`](../../plugins/review-gate/) est la moitié « application »
du template entreprise, rendue portable — et il se défère au garde-fou du dépôt
quand il en existe un, pour que la définition locale gagne toujours.

## Et MCP

Un serveur MCP n'est pas un endroit où mettre des instructions — c'est un
endroit où obtenir des **capacités** : données vivantes, API externe, index de
recherche. On y recourt quand Claude a besoin de ce que le système de fichiers ne
peut pas fournir. Tout ce qui précède concerne ce que Claude doit *faire* ; MCP
concerne ce qu'il peut *atteindre*.

## Erreurs fréquentes

| Symptôme | Vrai problème | Correction |
|----------|---------------|------------|
| `CLAUDE.md` dépasse 200 lignes | des procédures et du détail par zone en mémoire permanente | déplacer vers skills et règles limitées au chemin |
| Claude ignore une règle « parfois » | c'est du contexte, pas de l'application | en faire un hook |
| Une skill ne se déclenche jamais | sa `description` ne correspond pas à la formulation réelle des demandes | la réécrire avec les mots de l'utilisateur ; les descriptions sont tronquées quand elles sont nombreuses |
| Les revues sont des murs de « peut-être » | le relecteur a `Edit` et aucun barème | `disallowedTools: Edit, Write` + un fichier de barème vérifiable |
| Des demandes de permission partout | des règles `ask` trop larges | des entrées `allow` étroites pour les commandes exactes |
| Le contexte est plein avant de commencer | lectures larges, aucun périmètre | config par répertoire, règles `deny` en lecture, sous-agents pour l'exploration |

## Voir aussi

- [frontmatter-reference.md](frontmatter-reference.md) — chaque champ de chaque type de fichier
- [hooks-and-automation.md](hooks-and-automation.md) — événements, contrats, scripts
- [agents-and-autonomy.md](agents-and-autonomy.md) — sous-agents, sessions en arrière-plan
- [monorepo.md](monorepo.md) — configuration par répertoire
- [rules-and-skills.md](rules-and-skills.md) — pourquoi ne pas porter un `.cursorrules` géant

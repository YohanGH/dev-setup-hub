<!-- Langue : [English](../agents-and-autonomy.md) · Français -->

# Agents & autonomie

Quatre choses différentes s'appellent « autonome ». Elles résolvent des problèmes
distincts et se composent :

| Niveau | Ce que c'est | S'exécute | Ce que vous voyez |
|--------|--------------|-----------|-------------------|
| **Sous-agent** | Une sous-tâche déléguée dans votre session | dans sa propre fenêtre de contexte | son résumé seulement |
| **Tâche de fond** | Un sous-agent qu'on n'attend pas | en parallèle, même session | une notification à la fin |
| **Session de fond** | Une session Claude indépendante | son propre processus, son worktree | une ligne dans agent view |
| **Planifié / en boucle** | Une session qui se démarre elle-même | sur un cron ou un intervalle | sa sortie à chaque exécution |

## Sous-agents

Un sous-agent a sa propre fenêtre de contexte, son prompt système, ses outils et
permissions, et ne renvoie que son résumé. La valeur, c'est **ce que vous ne
voyez pas** : cinquante greps et lectures deviennent une carte de dépendances.

À utiliser quand la sortie intermédiaire de la sous-tâche ne vous servira plus :
recherche large, revue de diff complet, sortie de tests longue, tri de logs.

Définition et champs :
[frontmatter-reference.md](frontmatter-reference.md#sous-agents-claudeagentsmd).
Exemples concrets :
[`templates/enterprise-monorepo/.claude/agents/`](../../templates/enterprise-monorepo/.claude/agents/).

Trois propriétés font l'essentiel du travail :

- **`disallowedTools`** — retirez l'outil plutôt que de demander de ne pas s'en
  servir. Un relecteur avec `Edit` corrigera au lieu de rapporter.
- **`skills`** — précharge le corps *complet* de la skill au démarrage, pas
  seulement sa description. C'est ainsi qu'un relecteur a toujours son barème.
- **`model` / `effort`** — chercher n'exige pas le modèle le plus fort ;
  relire si. Ajustez la dépense à la tâche.

### Sous-agent ou skill forkée ?

| | Sous-agent | `context: fork` sur une skill/commande |
|--|-----------|---------------------------------------|
| Réutilisable par plusieurs appelants | oui | lié à cette seule commande |
| Outils, modèle, permissions propres | oui | hérite, sauf si `agent:` est nommé |
| Idéal pour | un rôle invoqué régulièrement | une étape lourde d'un seul workflow |

Combinez-les : `context: fork` **plus** `agent: code-reviewer` garde la commande
comme point d'entrée fin, pendant que le rôle vit dans un fichier réutilisable.

### La délégation dépend de la description

Claude route sur le champ `description`. Écrivez-le comme la demande qu'on
formulerait vraiment :

- Mauvais : *« Relit le code. »*
- Bon : *« À utiliser pour relire une branche ou une PR, vérifier un changement
  avant commit, ou contrôler le travail contre les critères d'acceptation d'un
  ticket. »*

## Sessions de fond et agent view

`claude agents` ouvre une vue de toutes les sessions de fond : statut, ce que
chacune fait, lesquelles attendent une entrée, liens de PR. Les sessions
continuent quand vous fermez la vue.

```bash
claude --bg "corrige la fuite mémoire du parser"
claude --bg --name "fuite-parser" --model opus "refactor auth"
claude agents --permission-mode plan --model opus
```

Depuis une session : `/bg <prompt>`. Depuis la vue : tapez un prompt et Entrée,
ou `@nom-agent <prompt>` pour lancer un sous-agent précis comme session.

| Touche | Action |
|--------|--------|
| `Espace` | aperçu sans s'attacher |
| `Entrée` / `→` | s'attacher |
| `←` | se détacher |
| `Ctrl+S` | grouper par état ou par répertoire |
| `Ctrl+T` | épingler (garde le processus vivant) |
| `Ctrl+X` | arrêter ; à nouveau pour supprimer |

Depuis le shell : `claude attach <id>` · `claude logs <id>` · `claude stop <id>`
· `claude agents --json`.

Les sessions de fond créent des worktrees git sous `.claude/worktrees/` pour que
les travaux parallèles ne se marchent pas dessus. Désactivable par projet avec
`{"worktree":{"bgIsolation":"none"}}`, et la vue entière avec
`{"disableAgentView": true}`.

C'est ce qui rend le tri de backlog praticable : une session par ticket, tous les
cadrages en parallèle, et vous lisez quatre fichiers de scope au lieu de mener
quatre conversations.

```bash
for t in PROJ-1234 PROJ-1235 PROJ-1236; do
  claude --bg --name "scope-$t" "@ticket-analyst cadre $t"
done
claude agents
```

## Travail planifié et en boucle

| Outil | Forme | Bon pour |
|-------|-------|----------|
| `/loop [intervalle] <prompt>` | répète dans cette session | surveiller une CI, sonder un déploiement, itérer jusqu'à une condition |
| `/schedule` | agent cloud sur cron | contrôles nocturnes, rapports récurrents, un « lance ça à 15 h » ponctuel |

Les deux exigent la même discipline que tout job non surveillé : une condition
d'arrêt claire, une sortie que vous lirez vraiment, et aucun effet de bord
destructeur.

## Rendre un agent sûr à laisser seul

Le mode d'échec d'un agent non surveillé n'est pas qu'il s'arrête — c'est qu'il
**devine** et rapporte avec assurance. Personne n'est là pour répondre à sa
question, alors il y répond lui-même.

Concevez contre ça :

1. **Dites quoi faire en cas d'incertitude.** « Ne jamais résoudre une ambiguïté
   par hypothèse. La consigner comme question ouverte adressée à une personne. »
   Écrivez-le dans le corps de l'agent ; c'est la ligne au meilleur rendement du
   fichier.
2. **Faites d'un non-résultat honnête une issue valide.** Un fichier de scope ne
   contenant que *Problème* et *Questions ouvertes*, disant que le ticket n'est
   pas cadrable en l'état, vaut mieux qu'une supposition assurée.
3. **Contraignez les outils.** `permissionMode: plan` pour les explorateurs,
   `disallowedTools` pour tout ce qui ne doit pas écrire. L'application bat
   l'instruction.
4. **Bornez l'exécution.** `maxTurns` coupe une boucle de reprises.
5. **Isolez le risque.** `isolation: worktree` donne à un refactor son propre
   checkout, nettoyé s'il ne change rien.
6. **Exigez des preuves.** « Chaque chemin en `fichier:ligne`, vérifié. » Un
   agent qui ne cite rien ne peut pas être contrôlé.
7. **Exigez une section « lacunes ».** « Ce qui n'a pas été investigué, et
   pourquoi » — jamais vide. Un rapport qui masque ses propres bords vaut moins
   que pas de rapport.

## Coût et contexte

Chaque sous-agent est une fenêtre de contexte distincte avec son coût en tokens.
Des agents parallèles le multiplient. Deux habitudes gardent cela raisonnable :

- Utiliser le modèle le moins cher qui fait le travail — la recherche et l'analyse
  de logs n'exigent rarement le plus puissant.
- Limiter ce qu'ils atteignent : `permissions.deny` sur les sorties de build et le
  code vendu, `worktree.sparsePaths` pour qu'un worktree extraie trois
  répertoires plutôt que tout l'arbre.

## Voir aussi

- [choosing-a-primitive.md](choosing-a-primitive.md) — quand un sous-agent bat une skill
- [ticket-workflow.md](ticket-workflow.md) — les agents comme étapes de pipeline
- [monorepo.md](monorepo.md) — limiter ce que les agents voient

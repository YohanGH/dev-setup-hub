<!-- Langue : [English](../ticket-workflow.md) · Français -->

# Le workflow ticket

La plupart d'entre nous le font déjà à la main : lire le ticket, chercher le code
concerné, vérifier ce qui en dépend, travailler, puis rédiger ce qui a changé. Ça
marche, et c'est différent à chaque fois — profondeur variable, oublis variables,
rien à quoi comparer après coup.

Voici ce même workflow rendu **reproductible** : étapes fixes, artefacts fixes,
des preuves au lieu de souvenirs.

Implémentation :
[`templates/enterprise-monorepo`](../../templates/enterprise-monorepo/).

## Le pipeline

```text
/ticket-scope PROJ-1234    lire ticket · cartographier code+impact  → scope.md
      ↓  point de contrôle : vous validez le plan
   implémenter             contre le fichier de scope               → commits.log
      ↓  point de contrôle
/review-scope PROJ-1234    diff vs scope + barème                   → review.md
      ↓  point de contrôle
/ticket-report PROJ-1234   rapport de passation / description de PR → report.md
```

`/ticket PROJ-1234` enchaîne les quatre avec un arrêt entre chaque.

Les artefacts atterrissent dans `.claude/tickets/PROJ-1234/`.

## Pourquoi des fichiers, et pas la conversation

Trois raisons concrètes, pas esthétiques :

1. **Les longues sessions compactent leur contexte.** Un plan qui n'existe que
   dans la conversation peut disparaître en cours de tâche. Un fichier sur disque
   non — et Claude le relit au lieu de le reconstruire depuis un résumé.
2. **Un point de contrôle a besoin de quelque chose à contrôler.** « Voici mon
   plan » dans le chat défile et se perd. `scope.md` se lit, se corrige, et se
   compare au résultat.
3. **Le rapport devient vérifiable.** `review.md` et `report.md` sont écrits
   contre `scope.md` et le diff réel : « est-ce que ça fait ce qui était promis »
   devient une comparaison plutôt qu'un jugement.

`commits.log` est écrit par un **hook**, pas par le modèle — c'est le seul
artefact qui ne peut pas être mal remémoré.

## Étape 1 — Cadrage

`/ticket-scope <ID>` résout le ticket (fichier local, puis `gh`), cartographie le
code et écrit `scope.md`. Il **s'arrête avant toute édition**.

Ce qui rend le cadrage rentable :

- **Chercher avant de lire.** Grepper les noms du domaine et les messages
  d'erreur visibles, pas des identifiants génériques. Lire le point d'entrée et
  ses tests d'abord — les tests énoncent le contrat visé.
- **`git log -S"<symbole>"`.** Le dernier changement sur ce code nomme souvent la
  contrainte que le ticket a oubliée.
- **La carte d'impact.** Pour chaque symbole touché : appelants, tests, contrats
  (réponse HTTP, type partagé, colonne en base, payload de file, clé de config),
  et *frères* — le même motif implémenté ailleurs. C'est ce dernier point que les
  relecteurs attrapent et que les auteurs manquent.
- **Les références dynamiques.** Clés en chaîne, jetons d'injection, tables de
  routes, noms d'événements, feature flags. Un renommage ne les fait jamais
  apparaître.

Deux propriétés du résultat comptent plus que l'exhaustivité :

- **Le code lié délibérément *non* modifié est consigné, avec la raison.** Les
  omissions silencieuses sont ce qui fait paraître un changement bâclé en revue.
- **Les questions ouvertes restent ouvertes.** Une question résolue par
  hypothèse est une décision ; elle va dans Décisions avec sa justification, ou
  elle reste une question.

Si l'estimation dépasse ~400 lignes de diff, l'étape propose un découpage avant
d'écrire la moindre ligne. C'est souvent la sortie la plus précieuse du pipeline.

## Étape 2 — Implémentation

Contre le fichier de scope, dans l'ordre de sa section Plan. Un commit par étape,
chacun vert.

La règle qui garde l'honnêteté : **si la réalité contredit le fichier de scope,
mettre à jour le fichier et le dire.** La divergence silencieuse est ce qui
transforme un pipeline en théâtre.

## Étape 3 — Revue

`/review-scope <ID>` s'exécute en `context: fork` vers le sous-agent
`code-reviewer` : le diff complet de la branche n'entre jamais dans votre
conversation — vous recevez des constats et un verdict.

Il fait deux choses qu'une revue générique ne fait pas :

- **Critère par critère** : chaque critère d'acceptation → satisfait / partiel /
  non satisfait, avec le `fichier:ligne` ou le nom de test qui le prouve. Pas de
  preuve = non satisfait.
- **Dérive de périmètre** : chaque fichier modifié que le scope n'explique pas,
  et chaque changement prévu absent du diff.

Le barème vit dans `.claude/conventions/review.md`, versionné dans le dépôt, pour
que la sévérité signifie la même chose pour tout le monde. Un constat exige un
**scénario d'échec concret** — des entrées ou un état produisant le mauvais
résultat — sinon c'est un détail.

Le relecteur reçoit `disallowedTools: Edit, Write`. Un relecteur qui peut
corriger corrigera, et alors il ne voit plus le code.

## Étape 4 — Rapport

`/ticket-report <ID>` construit la passation à partir de preuves seulement : le
fichier de scope, le diff, `review.md`, `commits.log`, et une exécution **réelle**
de preflight collée telle quelle.

Il commence par les écarts — ce qui était promis et non fait, ce qui a été fait
et jamais prévu. Si une vérification a échoué, le rapport dit `fail` avec
l'erreur.

Le mode d'échec dont ceci protège est le seul qui rendrait tout le système
indigne de confiance : un rapport qui laisse croire à une complétion alors qu'il
manque du travail.

## L'adapter

| Votre contexte | À changer |
|----------------|-----------|
| Jira / Linear au lieu de GitHub | `.claude/scripts/ticket-context.sh` — un script, une fonction de résolution |
| Format de clé de ticket différent | `CC_TICKET_PATTERN` dans `lib/common.sh` |
| Artefacts de ticket versionnés | committez `.claude/tickets/` ; sinon gitignorez-le |
| Pas d'étape de revue | supprimez `/review-scope` ; gardez scope et rapport — ils portent l'essentiel |
| Plusieurs tickets à la fois | `claude --bg "@ticket-analyst scope PROJ-1234"` par ticket, puis `claude agents` |

## Ce que ce n'est pas

Ce n'est pas une façon de déléguer le jugement. Chaque point de contrôle existe
parce qu'un humain décide : est-ce le bon périmètre, est-ce la bonne
implémentation, est-ce mergeable. Le pipeline supprime la variance dans *la façon
dont le travail est préparé et rapporté* — pas la décision sur sa justesse.

## Voir aussi

- [choosing-a-primitive.md](choosing-a-primitive.md) — pourquoi chaque étape est
  une commande, une skill ou un agent
- [agents-and-autonomy.md](agents-and-autonomy.md) — exécuter les étapes en
  arrière-plan
- [hooks-and-automation.md](hooks-and-automation.md) — le garde-fou autour du
  pipeline

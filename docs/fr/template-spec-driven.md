<!-- Langue : [English](../../templates/spec-driven/README.md) · Français -->

# Template — spec-driven

Une configuration Claude Code où **chaque phase du travail écrit un fichier
durable**, et où un second modèle attaque chacun d'eux avant qu'un humain ne
l'approuve.

Dix phases, de « quel est vraiment le problème » jusqu'à la passation. Chacune
produit un artefact sur disque. Chacune s'arrête.

C'est le compromis inverse d'aller vite : ça coûte plus cher par fonctionnalité,
et ça fait survivre le raisonnement à la session, au compactage, et aux six mois
pendant lesquels vous cessez de vous en souvenir.

## Quand ça vaut le coup

| Ça vaut le coup | Ça ne le vaut pas |
|-----------------|-------------------|
| Construire la mauvaise chose coûterait cher | Une coquille, un texte, une montée de version |
| Quelqu'un d'autre maintiendra ça | Vous le supprimerez la semaine prochaine |
| La décision devra être défendable plus tard | La décision est évidente |
| Le travail dépasse une fenêtre de contexte | Ça tient en une séance |

Ne lancez pas dix phases sur un changement de deux lignes. L'honnêteté du
pipeline repose sur le fait que les gens le croient digne d'être rempli, et rien
ne détruit ça plus vite que d'écrire une réflexion sur un bump de dépendance.

## Les deux axes de fichiers

Toute la conception est dans cette séparation.

**Pilotage — deux fichiers par fonctionnalité :**

| Fichier | Nature |
|---------|--------|
| `INDEX.md` | État mutable. Quelle phase, quel statut, quel verdict, ce qui bloque encore. Toujours *maintenant*. |
| `JOURNAL.md` | Historique append-only. Décisions, déviations, retours en arrière — jamais édité, jamais réordonné. |

Un seul fichier ne peut pas faire les deux. Un fichier d'état qui accumule un
historique devient illisible ; un historique qu'on réécrit cesse d'être une
preuve.

**Travail — deux fichiers par phase :**

| Fichier | Auteur |
|---------|--------|
| `NN-<phase>.md` | Le constructeur (modèle A). Amendé sur place après réconciliation. |
| `NN-<phase>.challenge.md` | Le contradicteur (modèle B). Jamais réécrit. |

L'artefact montre donc toujours la vérité du moment, et le fichier de challenge
conserve ce qu'il a fallu argumenter pour y arriver — y compris l'objection
levée, examinée, et écartée.

## Les dix phases

| # | Commande | Répond à | Challenge |
|---|----------|----------|-----------|
| 01 | `/spec-reflect` | Quel est vraiment le problème, et qu'est-ce qui rendrait ce build faux ? | **obligatoire** |
| 02 | `/spec-analyze` | Quel code est touché, et qu'est-ce qui casse autour ? | **obligatoire** |
| 03 | `/spec-tasks` | Quel est le plus petit ensemble ordonné d'étapes vérifiables ? | **obligatoire** |
| 04 | `/spec-pseudo` | Quel est l'algorithme, avant toute syntaxe ? | optionnel |
| 05 | `/spec-comment` | La forme prévue survit-elle au contact des vrais fichiers ? | optionnel |
| 06 | `/spec-implement` | Est-ce que ça marche, et est-ce couvert ? | **obligatoire** |
| 07 | `/spec-test` | Le saurait-on si ça cassait ? | **obligatoire** |
| 08 | `/spec-docs` | Qu'est-ce que ce changement a rendu *faux* ? | optionnel |
| 09 | `/spec-map` | À quoi ressemble le projet maintenant ? | optionnel |
| 10 | `/spec-recap` | Qu'est-ce qui était promis, livré, abandonné ? | sauté par défaut |

`/spec <slug>` les enchaîne avec un arrêt entre chacune.

Les phases 01 à 04 n'écrivent aucun code source. La phase 05 n'écrit que des
commentaires. C'est cette frontière qui rend les checkpoints précoces bon marché
à rejeter — rejeter une réflexion coûte une reprise, rejeter une implémentation
coûte l'implémentation.

## Arborescence

```text
spec-driven/
└── .claude/
    ├── settings.json               # permissions — refuse --no-verify d'emblée
    ├── conventions/
    │   ├── pipeline.md             # LE contrat : layout, phases, statuts, péremption
    │   └── challenge.md            # ce qu'est une contradiction légitime
    ├── commands/
    │   ├── spec.md                 # l'orchestrateur
    │   ├── spec-init.md            # une seule fois, dans le projet d'accueil
    │   ├── spec-new.md             # ouvre un dossier de spec
    │   ├── spec-challenge.md       # lance l'IA B
    │   └── spec-{reflect,analyze,tasks,pseudo,comment,
    │              implement,test,docs,map,recap}.md
    ├── agents/
    │   ├── challenger.md           # modèle B — disallowedTools: Edit, Write
    │   └── scout.md                # lit beaucoup de fichiers, rend une petite carte
    ├── templates/
    │   ├── INDEX.md  JOURNAL.md  challenge.md
    │   └── 01-reflection.md … 10-recap.md
    ├── scripts/
    │   └── checks.sh               # la batterie qualité unique, câblée par /spec-init
    └── specs/
        └── <slug>/                 # les artefacts atterrissent ici
```

## Démarrage

```bash
cp -r templates/spec-driven/.claude/* votre-projet/.claude/
```

Puis, dans ce projet :

```text
/spec-init
```

Il détecte la stack, câble `checks.sh` (**la CI fait autorité** en cas de
désaccord), vous demande si les artefacts vont dans git, et laisse un pointeur de
trois lignes dans `CLAUDE.md` — pas une copie des règles, parce que ce fichier
est relu à chaque session et que chaque ligne se paie à chaque tour.

Ensuite, par fonctionnalité :

```text
/spec rate-limit-login
```

## Deux modèles, pas deux avis

Un modèle ne voit pas ses propres omissions, et une fois qu'il a argumenté pour
une conception, cet argument est dans son contexte. Donc le constructeur
construit, le contradicteur contredit, et **un humain arbitre** — le pipeline n'a
pas d'étape d'arbitrage, par construction.

`/spec-challenge` s'arrête *avant* la réconciliation, pour que le constructeur ne
reçoive jamais les findings et ne les tranche pas dans le même souffle.

Trois modes, par indépendance croissante : le sous-agent `challenger`, une
seconde session sur un autre modèle, ou le modèle d'un autre fournisseur avec un
aller-retour manuel. Utilisez le troisième sur les phases 01 à 03, là où un
cadrage faux est l'erreur que toutes les phases suivantes amplifient fidèlement.

Les modes de défaillance de ce dispositif — convergence complaisante, findings
fabriqués, angles morts partagés, arbitrage par la partie intéressée — et la
contre-mesure prévue pour chacun sont dans
[dual-ai-challenge.md](dual-ai-challenge.md).

## Ce qui tient encore dans six mois

- **La péremption se propage.** Éditer un artefact `resolved` marque `stale`
  toutes les phases `resolved` en aval. Le pipeline marque et s'arrête ; relancer
  est une décision, et elle va au journal. Sans ça, un dossier de spec devient un
  tas de documents décrivant trois versions différentes de la même chose.
- **Chaque phase a sa section d'honnêteté** — affirmations non vérifiées, tests
  non vérifiés, arêtes de diagramme sans preuve, trous laissés ouverts.
  `10-recap.md` les agrège en une déclaration de confiance. C'est la réponse à
  « à quel point je peux faire confiance à ça ».
- **Seul un humain pose `resolved`.** C'est la seule chose non automatisée du
  pipeline, et la raison pour laquelle les checkpoints ne sont pas décoratifs.
- **La carte canonique survit au spec.** `docs/architecture/map.md` est mise à
  jour par chaque spec et appartient à aucun.

## Ce template vs. `enterprise-monorepo`

Deux templates dans ce dépôt, deux problèmes différents. Ce ne sont pas deux
versions d'une même chose.

| | `spec-driven` | [`enterprise-monorepo`](template-enterprise-monorepo.md) |
|--|---------------|--------------------------|
| Organise | **le raisonnement** — dix phases, chacune avec son artefact et sa contradiction | **le dépôt** — règles limitées au chemin, skills par répertoire, frontières de section |
| Pipeline | 10 phases, checkpoint humain entre chacune | 4 étapes : cadrage → implémentation → revue → rapport |
| Second avis | un modèle contradicteur, sur cinq phases obligatoires | un agent `code-reviewer`, au moment de la revue |
| Application | conventions + permissions | 7 hooks + une batterie pre-commit partagée |
| À utiliser quand | construire la mauvaise chose coûte cher | beaucoup de gens travaillent dans un gros dépôt |

Ils se combinent : rien n'empêche un monorepo de lancer `/spec` sur ses
changements difficiles et `/ticket` sur le reste.

**Sur la duplication.** `scout` ici et `impact-scout` là-bas font un travail
proche, et c'est délibéré. Un template se copie *en entier* dans un projet ; il
ne peut pas dépendre de la présence d'un autre template. Des noms différents
parce que ce ne sont pas le même agent — `scout` sert aussi la cartographie de la
phase 09. Si vous modifiez l'un, l'autre ne suit pas, et il ne doit pas suivre.

## L'adapter

| Votre contexte | Ce qu'il faut changer |
|----------------|----------------------|
| La doc n'est pas dans `docs/` | Le chemin de la carte dans `commands/spec-map.md` **et** `templates/09-map.md` |
| Les artefacts ne doivent pas être dans git | `/spec-init` pose la question ; gitignorer `.claude/specs/` |
| Moins de phases | Supprimez 04, 05, 09. Gardez 01-03 et 10 — c'est là qu'est l'essentiel de la valeur |
| Un garde-fou de commit comme l'autre template | Emballez `checks.sh` dans un hook `PreToolUse` — voir [`enterprise-monorepo`](../../templates/enterprise-monorepo/.claude/hooks/pre-commit-gate.sh) pour le protocole de codes de sortie |
| Un autre modèle contradicteur | `model:` dans `agents/challenger.md`, ou faites-le tourner hors session |

## Ce que ce n'est pas

Ce n'est pas une façon de déléguer le jugement. Chaque checkpoint existe parce
qu'un humain décide : est-ce le bon problème, est-ce le bon plan, est-ce
mergeable. Le pipeline supprime la variance dans *la façon dont le travail est
préparé, contredit et rapporté* — pas la décision de savoir s'il est correct.

## Voir aussi

- [dual-ai-challenge.md](dual-ai-challenge.md) — la méthode à deux modèles et ses
  modes de défaillance
- [ticket-workflow.md](ticket-workflow.md) — le pipeline plus léger en quatre
  étapes, pour le travail piloté par tickets
- [choosing-a-primitive.md](choosing-a-primitive.md) — pourquoi chaque étape ici
  est une commande, un agent, ou une convention

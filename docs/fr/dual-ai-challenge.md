<!-- Langue : [English](../dual-ai-challenge.md) · Français -->

# Deux modèles, un artefact

Un modèle ne voit pas ses propres omissions. Il peut relire ce qu'il a écrit
toute la journée et n'y retrouver que ce à quoi il avait déjà pensé — c'est ce
que « l'avoir écrit » signifie. Et une fois qu'il a argumenté pour une
conception, cet argument est dans son contexte, et il pèse.

Le [pipeline spec-driven](../../templates/spec-driven/README.md) sépare donc le
travail en deux : un modèle **construit** l'artefact, un autre l'**attaque**, et
un humain tranche. Pas « demander deux fois et voir s'ils sont d'accord ».

## Ce que ce n'est pas

**Pas un vote.** Deux modèles d'accord vous apprennent qu'ils partagent un a
priori, pas que la réponse est juste. L'accord entre modèles entraînés sur des
données qui se recouvrent est la chose la moins chère à obtenir dans ce dispositif
et la moins informative à recevoir.

**Pas une négociation.** Si le constructeur et le contradicteur convergent par
concessions mutuelles, vous obtenez une position moyenne qu'aucun des deux ne
défendrait, avec l'apparence d'un consensus. C'est strictement pire qu'un
désaccord ouvert, qui au moins vous dit où regarder.

**Pas un second avis.** Un second avis, c'est ce qu'on demande quand on veut être
rassuré. Au contradicteur on demande des findings — précis, prouvés, avec une
conséquence — et « aucun finding » est une réponse complète qu'il a le droit de
donner.

## L'asymétrie

| Rôle | Fait | Ne fait jamais |
|------|------|----------------|
| **Constructeur** (A) | Écrit l'artefact. Réconcilie les findings à découvert : il amende l'artefact ou écrit pourquoi il ne l'amende pas. | Challenger son propre artefact dans le même contexte. |
| **Contradicteur** (B) | Quatre passes : prémisse, preuves, omissions, falsifiabilité. Des findings avec une conséquence en aval, et un verdict. | Éditer quoi que ce soit. Réécrire l'artefact à sa façon. Arbitrer. |
| **Humain** | Lit l'artefact, le challenge et le delta du journal. Passe la phase à `resolved`. | Déléguer cette décision. |

Les rôles sont imposés, pas demandés : le sous-agent `challenger` est livré avec
`disallowedTools: Edit, Write, NotebookEdit`. Un relecteur qui peut corriger va
corriger, et ensuite il ne voit plus le code.

## Trois façons de faire tourner l'IA B

| Mode | Comment | Indépendance | Coût |
|------|---------|--------------|------|
| **Sous-agent** | `/spec-challenge <slug> <phase>` — fork un contexte neuf dans la même session | Contexte neuf, même modèle. Attrape les hypothèses tacites et les affirmations non vérifiées ; partage les angles morts du modèle. | Des tokens |
| **Seconde session** | Une seconde session Claude sur un autre modèle | Autres poids, autres modes de défaillance | Tokens + une fenêtre |
| **Modèle externe** | Coller l'artefact chez un autre fournisseur, recoller le résultat | La plus haute — ni biais d'entraînement commun, ni contexte commun | Un aller-retour manuel |

L'indépendance est le seul axe qui compte ici, et elle s'achète en inconfort.
Utilisez le sous-agent par défaut ; utilisez un modèle externe sur les phases où
une mauvaise réponse coûte cher — **01 réflexion, 02 analyse, 03 task**. Ce sont
les phases dont les erreurs sont fidèlement amplifiées par toutes les suivantes.

## Faire tourner un modèle externe

Le fichier de challenge se moque de ce qui l'a produit. Ce qui compte, c'est que
le contrat de
[`conventions/challenge.md`](../../templates/spec-driven/.claude/conventions/challenge.md)
soit suivi et que l'auteur soit nommé.

Donnez l'artefact à l'autre modèle, avec ceci :

```text
Tu relis un artefact de conception écrit par un autre modèle. Ne le réécris pas
et ne le résume pas. Trouve ce qui ne va pas dedans.

Quatre passes, dans cet ordre :
1. Prémisse — le problème qu'il énonce est-il le problème qui existe ?
2. Preuves — chaque affirmation factuelle : vérifiée, invérifiable, ou fausse.
3. Omissions — ce qui devrait y être et n'y est pas : le chemin d'erreur,
   l'appelant que personne n'a listé, la migration, l'entrée vide, le cas qui
   existe déjà.
4. Falsifiabilité — cet artefact pourrait-il être faux tout en ressemblant à ça ?

Chaque finding a besoin de trois choses, sinon c'est un nit : l'affirmation en
une phrase, la preuve (une ligne citée, un file:line, ou une commande dont la
sortie la contredit), et la conséquence concrète dans la phase SUIVANTE du
travail.

Sévérité : blocker (la phase suivante construit la mauvaise chose) · major (la
bonne chose de la mauvaise façon) · minor (correct, coûtera du temps plus tard)
· nit.

Rendre zéro finding est une revue complète et réussie. Ne fabrique pas de
findings pour paraître rigoureux. Termine par exactement un verdict : accept,
revise, ou reject.
```

Collez sa sortie dans `NN-<phase>.challenge.md`, renseignez la ligne
`Challenger.` avec le fournisseur et le modèle, puis mettez `INDEX.md` à jour à
la main.

Le modèle externe n'a pas le dépôt : sa passe « preuves » est donc plus faible et
sa passe « omissions » plus forte — il n'a rien d'autre que l'artefact sur quoi
s'ancrer. Ce compromis est en général dans le bon sens pour les phases 01 à 03,
où l'artefact *est* la chose jugée.

## Les quatre modes de défaillance

Voici comment un dispositif à deux modèles produit de la confiance sans produire
d'information. Chacun a sa contre-mesure intégrée au pipeline.

### 1. Convergence complaisante

Le contradicteur est d'accord parce que l'accord est le chemin de moindre
résistance, surtout face à un artefact fluide et assuré.

**Contre-mesure.** Le contradicteur reçoit l'artefact et le dépôt — jamais le
raisonnement du constructeur. On lui demande des findings, pas une appréciation.
Et on lui dit explicitement que zéro finding est une réponse valide, pour que
« je n'ai rien trouvé » n'ait pas besoin d'être habillé en « ça semble globalement
raisonnable, même si on pourrait envisager… ».

### 2. Findings fabriqués

Un contradicteur qui sent qu'il est payé au finding produira des findings. Le
volume ressemble à de la rigueur et ne coûte rien à générer.

**Contre-mesure.** Chaque finding doit nommer une conséquence concrète dans la
phase *suivante*. « Ce n'est pas clair » ne survit pas à ce filtre ; « la phase 04
va concevoir pour un seul tenant et la 06 devra être réécrite » y survit. Tout ce
qui échoue au filtre part dans la liste des nits, que personne n'est tenu de
traiter.

### 3. Angles morts partagés

Deux modèles de la même famille ratent les mêmes choses. Un contexte neuf ne
corrige pas un biais systématique — il vous en donne deux exécutions.

**Contre-mesure.** Le choix du mode. Le sous-agent suffit à attraper les
affirmations non vérifiées et les hypothèses tacites, parce que ce sont des
artefacts de contexte. Il ne suffit pas à attraper un cadrage faux que les deux
modèles trouvent naturel. C'est à ça que sert le modèle externe, et c'est pour ça
qu'il est recommandé précisément sur les phases de cadrage.

### 4. Arbitrage par la partie intéressée

Le constructeur reçoit les findings et les réconcilie — dans le même souffle. Il
tranchera les inconfortables en sa faveur, avec aisance.

**Contre-mesure.** `/spec-challenge` **s'arrête** après avoir écrit le fichier de
challenge. La réconciliation est une étape séparée, après qu'un humain a lu la
contradiction. Chaque amendement est journalisé avec l'id du finding auquel il
répond, et les findings non traités sont listés comme non traités. Si les deux
sont toujours en désaccord après un tour, les deux positions vont à l'humain
mot pour mot — le pipeline n'a pas d'étape d'arbitrage, par construction.

## Où ça paie

Obligatoire sur **01, 02, 03** (direction) et **06, 07** (conséquence). Optionnel
sur 04, 05, 08, 09, 10.

Le critère est le coût de l'erreur, pas la difficulté de la phase. Une prémisse
fausse attrapée en 01 coûte une reprise de phase bon marché ; attrapée en 06 elle
coûte l'implémentation. Une suite de tests verte pour la mauvaise raison est
l'artefact le plus cher du pipeline, parce que tout l'aval lui fait confiance.

La phase 10 est celle à sauter par défaut : un recap construit uniquement sur des
artefacts et des sorties de commandes collées offre peu de prise à la
contradiction.

## Ce que ça laisse derrière

Les fichiers de challenge ne sont jamais réécrits. Six mois plus tard,
`03-tasks.md` vous dit ce qui était prévu et `03-tasks.challenge.md` vous dit ce
qu'il a fallu argumenter pour y arriver — y compris l'objection qui a été levée,
examinée, et écartée.

C'est ce second document que vous voulez le jour où ça casse. « On savait, et
voilà pourquoi on a livré quand même » est une situation différente de « personne
n'y avait pensé », et une seule des deux est une défaillance de process.

## Voir aussi

- [`templates/spec-driven/`](../../templates/spec-driven/README.md) — le pipeline
  que cette page décrit
- [`conventions/challenge.md`](../../templates/spec-driven/.claude/conventions/challenge.md)
  — le contrat que suivent les fichiers de challenge
- [agents-and-autonomy.md](agents-and-autonomy.md) — sous-agents, contexte forké,
  et ce qui rend un agent sûr à laisser tourner seul
- [context-economics.md](context-economics.md) — ce que coûte réellement un
  challenge forké par phase

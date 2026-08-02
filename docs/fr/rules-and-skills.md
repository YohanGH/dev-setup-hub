<!-- Langue : [English](../rules-and-skills.md) · Français -->

# Rules & Skills : utile ou contre-productif ?

Cursor a popularisé deux idées : les **rules** (`.cursorrules` / règles de projet
injectées toujours — ou conditionnellement — dans l'invite) et les **skills**
(paquets de prompts réutilisables). Une question légitime pour toute config
Claude Code : *faut-il ajouter la même chose, et est-ce que ça améliore vraiment
les performances — ou est-ce que ça gêne ?*

Voici la réponse raisonnée, avec une recommandation pour ce dépôt.

---

## Les équivalents dans Claude Code

Pas besoin de greffer les concepts de Cursor sur Claude Code — il a déjà des
primitives natives qui couvrent le même terrain, avec d'autres compromis :

| Idée Cursor | Équivalent Claude Code | Chargement |
|-------------|------------------------|------------|
| Règles toujours actives (`.cursorrules`) | Mémoire [`CLAUDE.md`](configuration.md#2-mémoire-claudemd) | **Toujours** en contexte |
| Règles ciblées / par tâche | [Skills](https://code.claude.com/docs/en/skills), [commandes perso](commands.md#commandes-slash-personnalisées) | **À la demande** (divulgation progressive) |
| « Skills » de prompts réutilisables | Skills, [sous-agents](commands.md) | Invoqués par le modèle ou l'utilisateur |
| Automatisation | [Hooks](configuration.md#hooks-aperçu) | Déclenchés par événement |

La différence clé : `CLAUDE.md` est **toujours chargé**, alors que Skills et
commandes ne le sont **que quand c'est pertinent**.

---

## Le compromis central : le contexte n'est pas gratuit

Tout ce que vous mettez dans un fichier de règles toujours actif rivalise pour
l'attention du modèle et consomme des tokens à **chaque** tour. Deux coûts :

1. **Performance** — un gros bloc de règles peu ciblé dilue l'attention. Le
   modèle doit extraire les 3 lignes utiles parmi 300. Le signal baisse, les
   erreurs montent.
2. **Coût & vitesse** — le contexte toujours actif est payé à chaque requête et
   ralentit le premier token.

C'est pourquoi les `.cursorrules` maximalistes (des centaines de lignes de
« toujours faire X, ne jamais faire Y ») **nuisent** souvent plus qu'ils
n'aident. Le problème n'est pas « trop peu de règles » mais « trop de règles
rarement pertinentes ».

**La divulgation progressive est la solution.** Les Skills n'exposent d'abord
qu'une courte description ; leurs instructions complètes ne se chargent *que
quand la tâche correspond*. Ça passe à l'échelle sur des dizaines de capacités
sans tout payer tout le temps.

---

## Quand une règle aide

Mettez quelque chose dans `CLAUDE.md` (toujours actif) quand c'est :

- **Stable et à forte valeur** — commandes build/test/lint, conventions clés.
- **Une correction récurrente** — ce que Claude se trompe régulièrement ici.
- **Court** — quelques puces nettes, pas une dissertation.
- **Pas déjà garanti ailleurs** — ne répétez pas ce que le linter/formateur ou
  le code lui-même impose déjà.

## Quand une règle est contre-productive

Évitez les règles toujours actives qui sont :

- **Longues et théoriques** — manifestes de style, cas limites rarement atteints.
- **Spécifiques à une tâche** — « pour écrire une migration, fais X » relève
  d'une *commande* ou d'un *skill*, pas de chaque invite.
- **Contradictoires ou périmées** — des consignes qui se contredisent, c'est pire
  que rien.
- **Redondantes avec l'outillage** — si la CI l'impose, pas besoin d'une règle.

---

## Guide de décision : où placer un comportement ?

| Vous voulez… | Utilisez | Pourquoi |
|--------------|----------|----------|
| Encoder un fait/convention toujours vrai | `CLAUDE.md` | Nécessaire à chaque tour, gardez-le minuscule. |
| Empaqueter un workflow répétable et ciblé | **Skill** ou **commande** | Chargé seulement si pertinent — pas de coût de contexte permanent. |
| Isoler une sous-tâche large ou parallèle | **Sous-agent** | Garde le contexte principal propre. |
| Imposer une action automatiquement (format, blocage) | **Hook** | Déterministe, pas laissé au modèle. |

**Règle générale :** *toujours vrai et minuscule → règle. Parfois pertinent →
skill/commande. Déterministe → hook.*

---

## Verdict pour ce dépôt

**Ajouter des « rules/skills » en vaut la peine — mais avec discipline.** La
question n'est pas *si* mais *quelle primitive* et *en quelle quantité* :

- ✅ **Gardez un `CLAUDE.md` concis** pour la poignée de conventions toujours
  vraies.
- ✅ **Préférez Skills et commandes** pour tout ce qui est spécifique à une tâche
  — vous obtenez le bénéfice « règles selon la situation » de Cursor *sans* la
  taxe de contexte permanent.
- ✅ **Utilisez les hooks** pour ce qui doit arriver de façon déterministe.
- ❌ **Ne portez pas un `.cursorrules` géant** tel quel. Un fichier de 300 lignes
  toujours actif est la voie contre-productive — il coûte des tokens à chaque
  tour et noie le signal.

En résumé : l'instinct Cursor (capturer vos conventions) est bon ; copier
aveuglément son mécanisme *toujours actif* est le piège. Les primitives à
divulgation progressive de Claude Code offrent l'avantage sans l'inconvénient.

Voir aussi [configuration.md](configuration.md) et [best-practices.md](best-practices.md).

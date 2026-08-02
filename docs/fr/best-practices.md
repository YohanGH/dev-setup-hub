<!-- Langue : [English](../best-practices.md) · Français -->

# Bonnes pratiques avec Claude Code

Conseils pratiques et assumés qui ne relèvent pas strictement de la
« configuration » mais qui font la plus grande différence à l'usage. Adoptez ce
qui vous convient.

---

## 1. Donnez le bon contexte à Claude

- **Maintenez un `CLAUDE.md`.** C'est l'action au plus fort effet de levier.
  Mettez-y les conventions, comment lancer tests/lint/build, et toute règle que
  Claude oublie. Voir [configuration.md](configuration.md#2-mémoire-claudemd).
- **Pointez, ne collez pas.** Référencez les fichiers avec `@chemin/vers/fichier`
  plutôt que de copier de gros blocs dans l'invite.
- **Soyez précis sur l'objectif**, pas sur les frappes clavier. « Fais valider
  l'email par le formulaire de login avec erreurs en ligne » vaut mieux que
  « édite la ligne 42 ».

## 2. Gérez la fenêtre de contexte

- Utilisez **`/clear`** entre deux tâches sans rapport. Un contexte neuf est plus
  rapide et plus juste qu'un contexte encombré.
- Utilisez **`/compact`** quand une longue tâche continue mais que l'historique
  s'alourdit.
- Les sessions longues et décousues dégradent la qualité — découpez en morceaux
  ciblés.

## 3. Travaillez par petits pas vérifiables

- Demandez d'abord un **plan** sur tout ce qui n'est pas trivial, relisez-le,
  puis exécutez.
- Préférez **un changement à la fois** ; vérifiez (tests, lancer l'app) avant de
  continuer.
- Laissez Claude **lancer les tests** et lire la sortie — boucler vaut mieux que
  deviner.

## 4. Soyez délibéré sur les permissions

- Commencez plus strict, assouplissez avec la confiance. Réglez via
  `/permissions`.
- **Autorisez** les commandes sûres et répétitives (`git status`, votre lanceur
  de tests) pour ne pas cliquer « approuver » toute la journée.
- **Refusez** la lecture des secrets : `.env`, `secrets/**`, fichiers de clés.
- Réservez les commandes larges ou destructrices au mode **ask** pour rester
  dans la boucle.
- Voir l'exemple [`.claude/settings.example.json`](../../.claude/settings.example.json).

## 5. Ne divulguez jamais de secrets

- Pas de secrets dans `settings.json`, `CLAUDE.md`, les commandes ni l'invite.
- Utilisez des placeholders (`<YOUR_API_KEY>`) dans tout ce que vous versionnez.
- Gitignorez les fichiers `*.local.*` et `.env*`. Le [.gitignore](../../.gitignore)
  de ce dépôt le fait déjà.

## 6. Des commandes personnalisées pour les workflows répétés

- Transformez toute invite tapée plus de deux fois en
  [commande personnalisée](commands.md#commandes-slash-personnalisées).
- Gardez-les **petites et composables** ; ajoutez un `argument-hint`.
- Versionnez les commandes d'équipe dans `.claude/commands/` ; gardez les perso
  dans `~/.claude/commands/`.

## 7. Des sous-agents pour le gros travail parallélisable

- Déléguez les recherches larges ou sous-tâches indépendantes à des
  **sous-agents** (`/agents`) pour garder le contexte principal propre.
- Donnez à chaque sous-agent un brief **étroit et bien cadré** et ne relayez que
  le résultat.

## 8. Un workflow git soigné

- Laissez Claude écrire des commits ciblés avec des messages clairs
  (Conventional Commits).
- **Relisez le diff** avant de committer — le code est le vôtre, pas celui du
  modèle.
- Committez **souvent et petit** ; les erreurs deviennent bon marché à annuler.
- Ne poussez pas et n'ouvrez pas de PR sans l'avoir demandé.

## 9. Faites confiance, mais vérifiez les outils externes

- N'ajoutez que des **serveurs MCP** de confiance — ils lisent des données et
  agissent.
- Relisez les **hooks** et commandes shell avant de les activer ; ils s'exécutent
  sur votre machine.

## 10. Traitez la sortie comme un brouillon à relire

- Claude est un collaborateur rapide et compétent — pas un oracle. **Relisez ce
  qu'il écrit.**
- Quand il se trompe, encodez la correction dans `CLAUDE.md` pour éviter la
  récidive.
- Si une session dérape, `/clear` et reformulez proprement l'objectif plutôt que
  de lutter contre le contexte.

---

## Checklist rapide

- [ ] Le projet a un `CLAUDE.md` concis et exact.
- [ ] Les commandes test / lint / build sont documentées et autorisées.
- [ ] Les secrets sont refusés et gitignorés.
- [ ] Les invites répétées sont devenues des commandes.
- [ ] Vous faites `/clear` entre tâches sans rapport.
- [ ] Vous relisez les diffs avant qu'ils soient committés.

Voir aussi [configuration.md](configuration.md) et [commands.md](commands.md).

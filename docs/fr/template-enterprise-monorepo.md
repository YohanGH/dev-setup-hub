<!-- Langue : [English](../../templates/enterprise-monorepo/README.md) · Français -->

# Template — monorepo d'entreprise

Une configuration Claude Code **complète et fonctionnelle** pour un dépôt à
plusieurs répertoires majeurs et un workflow piloté par tickets. Copiez-la,
renommez les placeholders, gardez ce qui colle.

Elle existe pour être la forme que vous réutilisez d'un projet à l'autre malgré
des architectures différentes : la *structure* est stable, le *contenu* de chaque
fichier est ce que vous adaptez par dépôt.

## Ce qu'elle apporte

| Vous voulez | Elle fournit |
|-------------|--------------|
| Des instructions qui ne coûtent rien quand elles ne servent pas | Un `CLAUDE.md` racine léger, des `CLAUDE.md` par répertoire, des `rules/` limitées au chemin, des `skills/` par répertoire |
| Des conventions écrites qu'un humain possède | `.claude/conventions/` — sept fichiers, chargés à la demande, jamais tous à la fois |
| Un workflow ticket reproductible | `/ticket` → `/ticket-scope` → `/review-scope` → `/ticket-report`, avec artefacts dans `.claude/tickets/<ID>/` |
| Une batterie pre-commit façon husky | `.claude/scripts/preflight.sh`, appliquée aux humains **et** à Claude par le même script |
| De l'isolation pour le travail lourd | Quatre sous-agents globaux, plus un scopé à `apps/api` |
| De l'application déterministe | Neuf hooks à la racine, un par package, un porté par une skill |
| Des instructions scopées à une section | Skills par section sous `apps/*/src/*`, et `.claude/sections.json` pour les frontières qui doivent tenir depuis n'importe où |
| La preuve que ça reste peu coûteux | `.claude/scripts/context-budget.sh` — mesure le coût fixe par session face au total |

## Arborescence

```text
enterprise-monorepo/
├── CLAUDE.md                        # toujours chargé, < 200 lignes
├── .claude/
│   ├── settings.json                # permissions · hooks · worktree · env
│   ├── settings.local.json.example  # surcharges personnelles (gitignorées)
│   ├── conventions/                 # long format, humain, chargé à la demande
│   │   ├── git.md  code-style.md  testing.md  api-design.md
│   │   └── security.md  review.md  documentation.md
│   ├── rules/                       # limitées au chemin
│   │   ├── backend.md  frontend.md  shared-lib.md  tests.md
│   │   └── migrations.md  ci-and-infra.md  claude-config.md
│   ├── commands/                    # vous les invoquez
│   │   ├── ticket.md  ticket-scope.md  impact.md
│   │   └── review-scope.md  ticket-report.md  preflight.md
│   ├── skills/                      # Claude les reprend seul
│   │   ├── ticket-analysis/         # + references/ (gabarits, checklist)
│   │   ├── review-checklist/  handoff-report/  project-conventions/
│   ├── agents/                      # contextes isolés
│   │   ├── impact-scout.md  code-reviewer.md
│   │   └── test-runner.md  ticket-analyst.md
│   ├── hooks/                       # application déterministe
│   │   ├── session-start-context.sh   inject-ticket-context.sh
│   │   ├── pre-commit-gate.sh         protect-paths.sh
│   │   ├── format-edited.sh           post-commit-report.sh
│   │   └── quality-gate.sh
│   └── scripts/                     # appelables par vous, les hooks et git
│       ├── preflight.sh  scan-secrets.sh
│       ├── ticket-context.sh  install-git-hooks.sh
│       └── lib/common.sh
│   ├── scripts/                     # appelables par vous, les hooks et git
│   │   ├── preflight.sh  scan-secrets.sh  context-budget.sh
│   │   ├── ticket-context.sh  install-git-hooks.sh
│   │   └── lib/common.sh
│   └── sections.json                # frontières architecturales par section
├── apps/api/                        # ← un « répertoire majeur »
│   ├── CLAUDE.md
│   ├── .claude/
│   │   ├── settings.json            # perms, hooks, plugins, worktree du package
│   │   ├── agents/api-debugger.md   # en portée seulement si démarré ici
│   │   ├── hooks/check-contract-sync.sh
│   │   └── skills/{api-testing,new-endpoint,api-design-patterns}/
│   ├── docs/.claude/skills/docs-format/        # ← porte son propre hook
│   └── src/                         # ← skills par section
│       ├── core/.claude/skills/core-boundaries/
│       ├── routes/.claude/skills/route-handlers/
│       ├── services/.claude/skills/service-layer/
│       ├── types/.claude/skills/type-contracts/
│       └── utils/.claude/skills/utils-discipline/
├── apps/web/
│   ├── CLAUDE.md
│   ├── .claude/skills/component-patterns/
│   └── src/
│       ├── api/.claude/skills/data-layer/
│       ├── pages/.claude/skills/page-composition/
│       └── stores/.claude/skills/state-boundaries/
├── packages/shared/
│   ├── CLAUDE.md
│   └── .claude/skills/contract-change/
└── scripts/
    ├── CLAUDE.md
    └── .claude/skills/cross-platform-script/
```

## Ce que ça coûte

Mesurez, ne devinez pas :

```console
$ .claude/scripts/context-budget.sh

WHEN IT LOADS                           BYTES   ~TOKENS   FILES
---------------------------------------------------------------
every turn (CLAUDE.md, bare rules)       2528       632       1
skill list (names+descriptions)          5551      1387      19
---------------------------------------------------------------
FIXED COST PER SESSION                   8079      2019
---------------------------------------------------------------
on demand (nested/path-scoped)          14034      3508      11
on use (skill+command bodies)           61137     15284      19
never (conventions, references)         28592      7148      10
---------------------------------------------------------------
TOTAL CONFIG ON DISK                   111842     27960

You pay 7% of this configuration on every turn.
```

Vingt-huit mille tokens de configuration existent ; environ deux mille se
chargent par session. Passez un répertoire (`context-budget.sh apps/api`) pour
voir ce qu'une session paie réellement, quels sous-agents sont en portée, et si
un `settings.json` s'y applique.

## Scoper à une section

Trois mécanismes, et ils **n'ont pas** la même portée — c'est le point que la
plupart des configurations ratent :

| Scoper… | Avec | Fonctionne depuis la racine ? |
|---------|------|-------------------------------|
| De la connaissance | `src/<section>/.claude/skills/` | **oui** — les skills sont découvertes vers le bas |
| L'outillage de package | hooks et `enabledPlugins` de `apps/api/.claude/settings.json` | **non** — seulement si démarré dans ce package |
| L'outillage de tâche | `hooks:` dans le frontmatter d'une skill | oui, tant que la skill est active |
| Une frontière dure | `.claude/sections.json` + `section-dispatch.sh` | **oui, toujours** |
| L'autonomie | `apps/api/.claude/agents/` | **non** — les agents sont trouvés en remontant depuis le cwd |

**Les skills descendent ; les agents et les settings remontent.** Une règle dure
— « les routes ne doivent pas importer la couche de données » — a donc sa place
dans `sections.json`, où un unique hook racine dispatche sur le chemin édité et
l'applique quel que soit ce que la session a chargé. L'outillage indicatif va
dans le package ou la skill, où il ne coûte rien hors de portée.

Raisonnement complet et mesures :
[`context-economics.md`](context-economics.md).

## Installation

```bash
cp -r templates/enterprise-monorepo/.claude   /chemin/vers/votre/depot/
cp    templates/enterprise-monorepo/CLAUDE.md /chemin/vers/votre/depot/
cd /chemin/vers/votre/depot
.claude/scripts/install-git-hooks.sh
```

Ensuite :

1. **Remplacez les placeholders.** `grep -rn '<[A-Z_]*>' .claude CLAUDE.md` les
   trouve tous : `<TEST_CMD>`, `<DEFAULT_BRANCH>`, `<FRAMEWORK>`, etc.
2. **Renommez les répertoires.** `apps/api`, `apps/web`, `packages/shared` sont
   des placeholders pour *vos* répertoires majeurs. Mettez à jour les globs
   `paths:` dans `.claude/rules/*.md` et les `sparsePaths` dans `settings.json`.
3. **Supprimez ce qui ne s'applique pas.** Une règle pour une stack que vous
   n'utilisez pas est pire que pas de règle. C'est un point de départ, pas une
   checklist à satisfaire.
4. **Vérifiez que les hooks se déclenchent** : `claude --debug`, puis éditez un
   fichier et tentez un commit.
5. Gitignorez `.claude/settings.local.json` et, si vous ne voulez pas les
   artefacts de ticket dans git, `.claude/tickets/`.

## Le workflow ticket

```text
/ticket-scope PROJ-1234     lit le ticket, cartographie le code  → scope.md
      ↓ (vous validez le plan)
      implémentation                                              → commits.log
      ↓
/review-scope PROJ-1234     revue vs scope + barème               → review.md
      ↓
/ticket-report PROJ-1234    rapport de passation / description PR → report.md
```

`/ticket PROJ-1234` enchaîne les quatre avec un point de contrôle entre chaque.

Tout atterrit dans `.claude/tickets/PROJ-1234/`. C'est important pour deux
raisons : une longue session **compacte son contexte** et le fichier de scope
survit là où la conversation ne survit pas ; et les artefacts rendent l'exécution
auditable au lieu de reposer sur la confiance.

`commits.log` est écrit par un hook, pas par le modèle — le rapport se construit
donc sur ce qui s'est réellement passé.

## La batterie pre-commit

Un script, trois points d'entrée, aucune dérive :

```text
                    .claude/scripts/preflight.sh
                     ↑            ↑            ↑
        .githooks/pre-commit   PreToolUse   votre terminal
         (commits humains)   (commits Claude)  (/preflight)
```

- Humains : `install-git-hooks.sh` positionne `core.hooksPath` — le comportement
  de husky, sans la dépendance.
- Claude : un hook `PreToolUse` sur `git commit` lance le même script et
  **refuse le commit** en cas d'échec. Il refuse aussi `--no-verify` : la seule
  chose qu'un humain peut faire et que l'agent ne doit pas.
- Le hook détecte que git lance déjà la batterie et saute sa propre exécution :
  elle ne tourne jamais deux fois.

`preflight.sh` détecte la stack (scripts npm/yarn/pnpm/bun, ruff/pytest, go,
cargo, Makefile), enchaîne format → lint → typecheck → tests, et lance toujours
un scan de secrets sur les fichiers modifiés. `--changed` (défaut) limite au
diff ; `--all` est ce que fait la CI.

## Où va chaque type d'instruction

La décision encodée par ce template :

| L'instruction est… | À mettre dans | Coût |
|--------------------|---------------|------|
| Toujours vraie, une ligne | `CLAUDE.md` | chaque tour |
| Vraie pour certains chemins | `.claude/rules/*.md` avec `paths:` | seulement pour les fichiers correspondants |
| Une référence long format | `.claude/conventions/` | seulement quand une skill ou règle la tire |
| Une procédure que Claude peut reprendre | `.claude/skills/` | seulement si pertinente |
| Une procédure que vous seul déclenchez | idem, `disable-model-invocation: true` | seulement à l'exécution |
| Une sous-tâche lourde et bruyante | `.claude/agents/` | sa propre fenêtre de contexte |
| Ce qui doit arriver à chaque fois | `.claude/hooks/` | nul — c'est du shell |
| Ce qui est partagé entre dépôts | un plugin | nul jusqu'à activation |

Raisonnement complet : [`choosing-a-primitive.md`](choosing-a-primitive.md).

## Désactiver des choses

| Vous voulez | Faites |
|-------------|--------|
| Pas de garde-fou en fin de tour | `CLAUDE_QUALITY_GATE=off` |
| Garde-fou bloquant en fin de tour | `CLAUDE_QUALITY_GATE=block` |
| Pas de garde-fou au commit | `CLAUDE_PRECOMMIT_GATE=off` |
| Batterie complète à chaque commit | `CLAUDE_PREFLIGHT_SCOPE=all` |
| Tous les hooks coupés, temporairement | `"disableAllHooks": true` |

Les valeurs personnelles vont dans `.claude/settings.local.json`, pas dans le
fichier partagé.

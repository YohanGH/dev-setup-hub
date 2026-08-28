<!-- Langue : [English](../hooks-and-automation.md) · Français -->

# Hooks & automatisation

Les hooks sont la seule couche **déterministe** d'une configuration Claude Code.
`CLAUDE.md`, les règles et les skills sont du contexte : Claude les lit et s'y
conforme généralement. Un hook est une commande shell exécutée par le harnais à
un événement fixe, quoi que décide le modèle.

Le test : *si Claude ignorait cette instruction, serait-ce inacceptable ?* Si
oui, c'est un hook.

## Événements

| Phase | Événements |
|-------|------------|
| Session | `SessionStart` · `Setup` · `SessionEnd` |
| Tour | `UserPromptSubmit` · `UserPromptExpansion` · `Stop` · `StopFailure` |
| Outils | `PreToolUse` · `PermissionRequest` · `PermissionDenied` · `PostToolUse` · `PostToolUseFailure` · `PostToolBatch` |
| Agents | `SubagentStart` · `SubagentStop` · `TaskCreated` · `TaskCompleted` |
| Contexte | `InstructionsLoaded` · `PreCompact` · `PostCompact` · `ConfigChange` · `CwdChanged` · `FileChanged` |
| Worktrees | `WorktreeCreate` · `WorktreeRemove` |

Les sept qui portent presque toute la valeur réelle :

| Événement | À utiliser pour |
|-----------|-----------------|
| `SessionStart` | Injecter l'état courant — branche, ticket, environnement. stdout devient du contexte. |
| `UserPromptSubmit` | Ajouter du contexte conditionnellement, selon la demande. |
| `PreToolUse` | **Bloquer.** Le garde-fou : refuser une commande, refuser une écriture. |
| `PostToolUse` | Réagir : formater, journaliser, notifier. Généralement `async`. |
| `Stop` | Vérifier le travail avant la fin du tour. |
| `SubagentStop` | Idem, pour une tâche déléguée. |
| `PreCompact` | Persister un état qui doit survivre à la compaction. |

## Entrée

Chaque hook reçoit du JSON sur **stdin** :

```json
{
  "session_id": "abc123",
  "transcript_path": "/chemin/transcript.jsonl",
  "cwd": "/repertoire/courant",
  "permission_mode": "default",
  "hook_event_name": "PreToolUse",
  "agent_id": "...", "agent_type": "..."
}
```

Les événements d'outil ajoutent `tool_name`, `tool_input`, `tool_output`,
`tool_error`. `Stop` ajoute `last_assistant_message`, `tool_calls`,
`tool_results` et `stop_hook_active`.

> **`stop_hook_active` n'est pas un drapeau de réentrance.** Il vaut `true` pour
> `Stop` et `false` pour `SubagentStop`, afin qu'un seul hook serve les deux. Se
> prémunir des boucles est votre travail — voir plus bas.

## Contrats de sortie

Se tromper ici, c'est un hook qui ne fait silencieusement rien.

| Objectif | Comment |
|----------|---------|
| Aucun avis | sortie `0`, aucune sortie |
| Bloquer un appel d'outil | sortie `2` avec la raison sur **stderr**, ou sortie `0` avec le JSON ci-dessous |
| Demander à l'utilisateur | même JSON, `"permissionDecision": "ask"` |
| Donner du contexte à Claude | `UserPromptSubmit` → `additionalContext` ; `SessionStart` → stdout brut |
| Note à l'utilisateur seul | `{"systemMessage":"...","suppressOutput":true}` |
| Empêcher la fin du tour | `Stop` → sortie `2`, stderr part vers Claude |

```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "Commande destructrice bloquée par un hook"
  }
}
```

La sortie `2` bloque. Tout autre code non nul est une erreur non bloquante qui
n'apparaît que dans le journal de debug — c'est pourquoi un hook cassé ressemble
à un hook qui ne fait rien.

## Écrire un script de hook

```bash
#!/usr/bin/env bash
set -uo pipefail
INPUT="$(cat)"                                    # lire stdin une fois
CMD="$(printf '%s' "$INPUT" | jq -r '.tool_input.command')"

if printf '%s' "$CMD" | grep -q 'rm -rf /'; then
  jq -n '{hookSpecificOutput:{
      hookEventName:"PreToolUse",
      permissionDecision:"deny",
      permissionDecisionReason:"Refusé : commande destructrice."}}'
fi
exit 0
```

Six règles, toutes apprises à la dure :

1. **Rapide, ou `async`.** Un hook synchrone est sur le chemin critique de chaque
   tour.
2. **Idempotent.** Il peut s'exécuter deux fois pour le même état.
3. **Silencieux sur stdout** sauf si l'événement traite stdout comme du contexte.
   Un `echo` égaré dans un hook `PreToolUse` corrompt le contrat JSON.
4. **Dégrader, jamais casser.** Pas de `jq`, pas de formateur, pas un dépôt git →
   sortie `0`. Un hook ne doit jamais pouvoir bloquer une session.
5. **Pas de réseau, pas de script distant non épinglé, rien hors du dépôt.**
6. **Attention au `//` de `jq`.** `false // "défaut"` renvoie `"défaut"`, car
   `//` traite `false` comme vide. Lire un booléen ainsi inverse votre logique.
   Lisez le chemin directement et ne traitez que `null`/absent comme manquant.

### Prémunir un hook `Stop` contre les boucles

Un hook `Stop` qui sort en `2` force la poursuite du tour. S'il le fait sans
condition, la session ne se termine jamais.

Le motif qui fonctionne : calculer une empreinte du **contenu** du changement
courant (`git rev-parse HEAD` + `git diff HEAD`), poser un fichier marqueur clé
sur `session_id + empreinte`, et ne bloquer qu'une fois par empreinte. Claude
modifie quelque chose → nouvelle empreinte → il peut bloquer à nouveau. Claude ne
modifie rien → même empreinte → le tour se termine.

N'utilisez pas `git status --porcelain` comme empreinte : sa sortie est identique
avant et après l'édition d'un fichier déjà modifié — une vraie correction
ressemble donc à une absence de changement — et elle bascule sur du bruit non
suivi comme un répertoire de cache.

## Le motif husky

Faire couvrir une batterie pre-commit **à la fois** les humains et Claude :

```text
                       preflight.sh
                    ↑        ↑        ↑
       .githooks/pre-commit  │   votre terminal
        (commits humains)    │
                    hook PreToolUse
                   (commits de Claude)
```

Un script, trois points d'entrée. Toute l'astuce est là : la CI, un développeur
et l'agent ne peuvent pas diverger sur ce que « vert » signifie, parce qu'il n'y
a qu'une définition.

Deux choses que seul le hook côté Claude peut faire :

- **Refuser `--no-verify`.** Un humain qui contourne le garde-fou assume un
  arbitrage. Un agent qui le fait contourne un contrôle.
- **Bloquer avant l'exécution**, avec un message écrit pour le modèle — « corrige
  les échecs, n'affaiblis pas une vérification » — plutôt qu'un code de retour
  brut.

Le hook côté Claude doit détecter que `core.hooksPath` est installé et sauter sa
propre exécution, pour que la batterie ne tourne pas deux fois.

Implémentation complète :
[`templates/enterprise-monorepo/.claude/`](../../templates/enterprise-monorepo/.claude/)
— `hooks/pre-commit-gate.sh`, `scripts/preflight.sh`,
`scripts/install-git-hooks.sh`.

## Les scripts qui valent le coup

| Script | Événement | Rôle |
|--------|-----------|------|
| `preflight.sh` | `PreToolUse` + git + CLI | Batterie format/lint/typecheck/tests avec détection de stack. `--changed` vs `--all`. |
| `scan-secrets.sh` | dans preflight | Motifs à fort signal sur les fichiers modifiés uniquement. |
| `protect-paths.sh` | `PreToolUse` | Refuser l'écriture sur secrets, build, code généré, lockfiles. |
| `format-edited.sh` | `PostToolUse`, `async` | Formater ce qui vient d'être écrit, si un formateur est installé. |
| `session-start-context.sh` | `SessionStart` | Branche, ticket, état du fichier de scope. Court — c'est payé à chaque session. |
| `inject-ticket-context.sh` | `UserPromptSubmit` | Pointer les artefacts existants quand le prompt nomme un ticket. |
| `post-commit-report.sh` | `PostToolUse`, `async` | Ajouter le commit au journal du ticket — une preuve que le modèle n'a pas écrite. |
| `quality-gate.sh` | `Stop` | Batterie rapide avant la fin du tour. `warn` / `block` / `off`. |

Gardez les helpers communs dans `lib/common.sh` et sourcez-le. Une liste de
motifs de secrets ou un détecteur de gestionnaire de paquets dupliqué dans huit
scripts va dériver.

**Rendez les plus agressifs configurables.** Un garde-fou qu'on ne peut pas
couper le temps d'un après-midi d'exploration finit désactivé pour de bon.

## Tester

Les hooks lisent du JSON sur stdin : testez-les directement.

```bash
echo '{"tool_input":{"command":"git commit --no-verify -m x"}}' \
  | .claude/hooks/pre-commit-gate.sh; echo "exit=$?"

echo '{"tool_input":{"file_path":".env"}}' \
  | .claude/hooks/protect-paths.sh | jq .
```

Puis `claude --debug` pour confirmer que le harnais les déclenche. Les
changements de hooks dans `settings.json` exigent un redémarrage de session ; les
hooks de plugin exigent `/reload-plugins`.

## Sécurité

Les hooks exécutent du shell arbitraire avec vos identifiants, automatiquement.

- Relisez chaque hook d'un dépôt avant d'accorder votre confiance à l'espace de
  travail.
- Jamais de `curl | sh`, jamais de script distant non épinglé.
- Guillemetez chaque variable — un chemin avec un espace n'est pas un cas limite.
- Préférez `permissions.deny` pour ce qui ne doit jamais arriver : c'est appliqué
  par le client et cela couvre aussi les commandes Bash reconnues.

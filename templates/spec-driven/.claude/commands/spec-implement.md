---
description: Phase 06 — fill the comments in, one green commit per task with its unit tests
argument-hint: <SLUG> [task-id]
arguments: slug task
disable-model-invocation: true
allowed-tools: Read Grep Glob Edit Write Bash(git status) Bash(git diff:*) Bash(git log:*) Bash(git add:*) Bash(git commit:*) Bash(${CLAUDE_PROJECT_DIR}/.claude/scripts/checks.sh:*)
---

Phase 06 — implementation, for **$slug**. If `$task` is given, do only that task.

Read `.claude/specs/$slug/05-comments.md`, `04-pseudocode.md` and `03-tasks.md`.
Phase 05 must be `resolved`; if it is not, stop and say so.

The comments are already in the files. You are filling them in, in the order
`03-tasks.md` lists — which is the order that invalidates the design earliest,
not the order that is comfortable.

## The rule that keeps this honest

**Re-read the artifacts. Do not work from memory.** This session may be compacted
before the last task. A plan that exists only in the conversation disappears; the
one on disk does not. Before each task, re-open its pseudo-code block.

**If reality contradicts the plan, update the artifact and say so.** Never
silently diverge. A pipeline where phase 06 quietly does something else is a
pipeline that produces four documents describing a thing that was not built.

## Per task

1. **Fill the comments in.** The intent comments stay; the `SCAFFOLD:` ones are
   deleted as you consume them.
2. **Invariants become assertions.** The `require`/`ensure` lines from phase 04
   are checks in the code where the language allows, and test names where it does
   not.
3. **Write the unit tests in the same commit.** A task is not green without them.
   For a bug fix, the failing test comes first and you show it failing before you
   fix it.
4. **Every failure mode from phase 04 gets a branch and a test** — starting with
   the silent-wrong case. That one is the reason the phase exists.
5. **Run the checks, then commit.** One command, the same one humans and git
   hooks run:

   ```bash
   .claude/scripts/checks.sh
   ```

   If it exits `2`, it is not configured — run `/spec-init` rather than reaching
   for `npm test` directly. A check reported as `skip` is not a check that
   passed, and it does not make a task green.

   Then commit. Conventional Commits, with the task id and slug in the footer:

   ```text
   feat(<scope>): <what changed>

   Spec: <SLUG>
   Task: T<n>
   ```

6. **Record it** in `06-implementation.md` before starting the next task — sha,
   evidence, deviations. Written at the end from memory, this file is fiction.

## When a task will not go green

Stop at that task. Do not move on and do not weaken a test to get past it. Write
what blocked it in the artifact and in `JOURNAL.md`, and tell me. A task list
where task 4 is stuck and tasks 5 to 8 are done is worse than one that stops at 4.

## Output

Write `.claude/specs/$slug/06-implementation.md` from
`.claude/templates/06-implementation.md`, updated per task, not at the end.

Update `INDEX.md`: phase 06 → `drafted` once every task is committed or
explicitly blocked.

Report back, and nothing else:
- one line per task: id, sha, green / blocked,
- every deviation from the plan, and what you did about it,
- `grep -rn "SCAFFOLD:"` output — it must be empty,
- what is left.

**Stop there.** No push, no PR, no tag.

Next: `/spec-challenge $slug 06-implementation` — mandatory on this phase. This
is where a wrong answer stops being a document and becomes shipped code.

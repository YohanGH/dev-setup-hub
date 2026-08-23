---
description: Open a spec directory for a feature — creates its two steering files and stops
argument-hint: <SLUG> [one-line intent]
arguments: slug intent
disable-model-invocation: true
allowed-tools: Read Glob Write Bash(mkdir:*) Bash(date:*) Bash(git log:*) Bash(git branch:*) Bash(gh issue view:*)
---

Open the spec directory for **$slug**.

The contract is `.claude/conventions/pipeline.md`. Read it first — it defines the
layout, the phase list, and the status values you are about to write.

1. If `.claude/specs/$slug/` already exists, **stop** and show me its
   `INDEX.md` phase board instead. Never overwrite a live spec directory.

2. Create `.claude/specs/$slug/` and write its two steering files:
   - `INDEX.md` from `.claude/templates/INDEX.md`
   - `JOURNAL.md` from `.claude/templates/JOURNAL.md`

   Fill the frontmatter with today's date (`date +%F`), the slug, and a title.
   Every phase starts `todo`.

3. Write the **one-line intent** in `INDEX.md`: what this feature must make
   true. Use `$intent` if I gave it. If I did not, or if what I gave is a
   restatement of the slug, ask me one question and stop — a spec that starts
   from a vague intent produces ten vague artifacts.

4. Seed the `00-init` journal entry with the real trigger: the ticket, the
   incident, the request. If a ticket id is in `$slug` or on the branch name,
   resolve it (`gh issue view`) and quote its one-line summary.

5. Report back, and nothing else:
   - the spec path,
   - the one-line intent as you wrote it,
   - anything you had to guess.

**Stop there.** Do not start phase 01 — I read the intent before you reason from
it. A wrong intent is the only error in this pipeline that every later phase
faithfully amplifies.

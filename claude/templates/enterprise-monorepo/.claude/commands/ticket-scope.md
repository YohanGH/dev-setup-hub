---
description: Analyse a ticket and write its scope file before any code is written
argument-hint: <TICKET-ID>
arguments: ticket
disable-model-invocation: true
allowed-tools: Read Grep Glob Bash(git log:*) Bash(git diff:*) Bash(git show:*) Bash(git branch:*) Bash(gh issue view:*) Bash(${CLAUDE_PROJECT_DIR}/.claude/scripts/ticket-context.sh:*)
---

Scope ticket **$ticket**.

Follow the `ticket-analysis` skill exactly — it defines the method and the
output format. Do not improvise a different structure; the review and report
steps parse these headings.

1. Resolve the ticket:
   `.claude/scripts/ticket-context.sh $ticket`
   If it returns nothing, ask me for the ticket text and stop.

2. Map the impacted code. If the search spans more than one package, delegate
   the exploration to the `impact-scout` subagent so the file reads stay out of
   this conversation.

3. Write `.claude/tickets/$ticket/scope.md` from
   `.claude/skills/ticket-analysis/references/scope-template.md`.
   Every path is verified as `file:line`. Every acceptance criterion maps to a
   planned change or is marked blocked.

4. Report back in this order and nothing else:
   - the plan in five lines,
   - open questions that change the implementation,
   - the estimated diff size, and a proposed split if it exceeds ~400 lines.

**Stop there.** Do not edit any source file — I check the scope before you build
against it.

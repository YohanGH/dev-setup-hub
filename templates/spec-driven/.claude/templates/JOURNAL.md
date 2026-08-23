# <SLUG> — journal

> **Append-only.** Never edit an entry, never reorder, never delete. To correct
> an entry, append a new one that supersedes it and link back.
>
> One entry per: decision taken, deviation from an approved artifact, challenge
> reconciled, phase resolved, phase marked stale.

Entry format — copy the block, fill it, append at the **bottom**:

```markdown
## <YYYY-MM-DD HH:MM> · <phase> · <decision|deviation|reconciliation|resolution|staleness>

**What.** One sentence, in the past tense, stating what changed.

**Why.** The constraint or evidence that forced it — not the preference.

**Instead of.** The option not taken, and what it would have cost.

**Answers.** `<challenge finding id>` when reconciling, otherwise `—`.

**Supersedes.** Link to the entry this replaces, otherwise `—`.
```

---

## <YYYY-MM-DD HH:MM> · 00-init · resolution

**What.** Opened the spec directory for `<SLUG>`.

**Why.** <The trigger: ticket, incident, request. One line.>

**Instead of.** —

**Answers.** —

**Supersedes.** —

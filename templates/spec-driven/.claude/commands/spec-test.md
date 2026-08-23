---
description: Phase 07 — end-to-end coverage, the gaps phase 06 left, and the run output that proves it
argument-hint: <SLUG>
arguments: slug
disable-model-invocation: true
allowed-tools: Read Grep Glob Edit Write Bash(git status) Bash(git diff:*) Bash(git log:*) Bash(git add:*) Bash(git commit:*) Bash(${CLAUDE_PROJECT_DIR}/.claude/scripts/checks.sh:*)
---

Phase 07 — tests, for **$slug**.

Read `.claude/specs/$slug/06-implementation.md` and `04-pseudocode.md`. Phase 06
must be `resolved`; if it is not, stop and say so.

The unit tests already exist — phase 06 wrote each one in the commit of the task
it covers. This phase does three different things:

1. **End-to-end**, across the boundaries a unit test mocks away.
2. **The gaps**, hunted deliberately rather than noticed.
3. **The proof**, pasted, so "it works" stops being a claim.

## The question this phase answers

Not "does it work" — phase 06 answered that. **Would we know if it broke?**

A suite that passes today and would keep passing after someone deletes the
feature is not coverage. For each new test, ask what change would make it fail.
If you cannot name one, the test asserts nothing and you should say so rather
than count it.

## Method

1. **End-to-end covers what unit tests mock.** The HTTP boundary, the database,
   the queue, the file system, the third-party call. If every collaborator is
   mocked, it is a unit test with more setup.

2. **One end-to-end test per user-visible path** from `01-reflection.md`, not per
   function. The e2e suite is the one that must still make sense after a
   refactor.

3. **Hunt the gaps in order:**
   - failure modes from `04-pseudocode.md` with no test in `06-implementation.md`
     — starting with the silent-wrong case,
   - boundaries: empty, one, many, maximum, null, wrong type, wrong order,
   - the contracts at risk in `02-analysis.md` — one test per breaking change,
   - the siblings: if the same pattern exists elsewhere and is tested there, the
     shape of that test is the shape of this one.

4. **Verify the tests fail for the right reason — recommended, not blocking.**
   Break the code, run the test, see it fail, restore. A test that passes against
   broken code is worse than no test, and this is the only way to find one.

   It costs a round trip per test, so it does not block the phase. What *is*
   required: any test you did not verify is recorded as `not verified`. Never
   leave the cell blank and never write `yes` for a check you did not run — an
   unverified test claimed as verified is exactly the false confidence this
   phase is meant to remove. Unverified rows are carried into the challenge and
   into the recap's confidence statement, so the gap stays visible instead of
   quietly closing.

5. **Report flakiness honestly.** Run the new e2e tests three times. A test that
   passes twice out of three is a failing test that has not been diagnosed yet.

6. **Never weaken a check to reach green.** No skip, no loosened assertion, no
   disabled rule, no `--no-verify`. If a check blocks legitimately, stop and say
   so. A suite made green by weakening is the failure this whole pipeline exists
   to prevent.

7. **Run `.claude/scripts/checks.sh --all` and paste the output.** Not a summary.
   Not "all green". The output.

## Output

Write `.claude/specs/$slug/07-tests.md` from `.claude/templates/07-tests.md`.
Commit the tests per task, referencing the task ids they cover.

Update `INDEX.md`: phase 07 → `drafted`.

Report back, and nothing else:
- new tests, one line each, with what each would catch,
- gaps found and gaps left, with the reason for each one left,
- how many new tests were verified to fail for the right reason, and how many
  were not,
- pre-existing failures, marked pre-existing and proven so,
- the pasted result line from `checks.sh`.

**Stop there.** No push, no PR.

Next: `/spec-challenge $slug 07-tests` — mandatory on this phase. A test suite
that is green for the wrong reason is the most expensive artifact in this
pipeline, because everything downstream trusts it.

---
name: implement
description: "Structured implementation process driven by TDD: explores code, plans with chunk decomposition, writes failing tests first, implements to pass, and runs an 8-point quality checklist. Use after /spec, or when implementing features, fixing bugs, or refactoring with test verification."
argument-hint: "[description of feature, fix, or refactor]"
effort: high
---

# Implementation Process (Test-Driven)

Implement the following using test-driven development: $ARGUMENTS

Tests give Claude a self-verification loop. Instead of producing code
that looks right, write tests first, then implement until they pass.
This is the highest-leverage pattern for agentic coding.

## Mapping to Claude Code Workflow

| Claude Code Phase | Implement Phase | What Happens |
|---|---|---|
| **Explore** | Phase 1: Analysis | Read files, trace data flow, check standards |
| **Plan** | Phase 2: Planning | Chunk decomposition, dependency graph, approval |
| **Implement** | Phases 3-5: TDD Cycle | Per-chunk: failing test -> code -> passing test |
| **Commit** | (user-initiated) | Commit when user requests |

## When to Use This Process

| Scope | Approach |
|---|---|
| Trivial (typo, rename, version bump) | Don't use this skill -- just do it directly |
| Small (single-file logic, simple bug fix) | Small feature shortcut (1-chunk tracker) |
| Medium+ (multi-file, unfamiliar code) | Full process |
| Large (cross-cutting, multi-session) | Full process + session resets between chunks |

**Small feature shortcut:** For single-file or few-file changes
with no new domain logic, collapse to: Analysis -> Pre-Test (verify
existing coverage) -> Implement -> Post-Test (regression) -> Quality
Verification. Use a 1-chunk tracker (see
[tracker-schema.md](references/tracker-schema.md) §Single-Chunk
Features). Only Plan Mode (2.4) and chunk decomposition (2.1-2.2)
collapse — Phase 2.5 (review-plan) and Phase 6 (review-impl +
/code-review) still run. Small features carry the same regression
risk as large ones.

## Supporting Files

Load these on demand, not all upfront:

| File | When to Load |
|---|---|
| [chunk-template.md](references/chunk-template.md) | Phase 2, when decomposing into chunks (skip for small features) |
| [tracker-schema.md](references/tracker-schema.md) | Phase 2.3, when creating the tracker (all features) |
| [quality-checklist.md](references/quality-checklist.md) | Phase 2.5 (plan review) and Phase 6 (final verification) |

## Process Overview

```text
Phase 1: Analysis
Phase 2: Planning
  └─ 2.5: Plan Review Gate (review-plan agent — blocks Phase 3)
Phase 3: Pre-Test (per chunk)
Phase 4: Implementation (per chunk)
Phase 5: Post-Test (per chunk)
Phase 6: Quality Verification
  └─ Gate: review-impl agent + /code-review (parallel — blocks completion)
```

Each phase must complete before the next begins.
For multi-chunk features, Phases 3-5 repeat per chunk.
Gates are artifact-triggered: the tracker file triggers review-plan
(2.5), all chunks complete triggers review-impl + /code-review (6).

---

## Phase 1: Analysis

### 1.1 Understand the Request

- Read the user's request carefully
- Identify: new feature, enhancement, bug fix, refactor, or test
- Check `docs/specs/` for an existing spec file matching the feature.
  If found, use it as primary input — user stories, acceptance criteria,
  and edge cases become the basis for chunk decomposition in Phase 2.
  (Specs are produced by the companion `/spec` skill in this plugin.)
- Ask clarifying questions if the scope is ambiguous

### 1.2 Explore Current Code

- Read the files that will be affected
- Trace the data flow through the application layers
- Identify existing patterns, utilities, abstractions to reuse
- Check for existing test coverage in the affected area

**Context tip:** For broad exploration across unfamiliar code, use
subagents to investigate. They run in a separate context and report
back summaries, keeping your main context clean for implementation.

### 1.3 Check Industry Standards

- Research platform-specific handling and conventions
- Check official documentation for frameworks in use
- Check changelogs and migration guides for your dependency
  versions — APIs may behave differently across major/minor
  releases (e.g., a method that re-runs in v1.0 may only
  recompose in v1.1)
- Identify relevant specs (RFCs, W3C, language specs)
- Note platform-specific quirks and edge cases

### 1.4 Check Project Architecture Patterns

Verify alignment with the project's established architecture.
Refer to `PROJECT.md` for project-specific patterns.

Common patterns to verify:

- **Layered architecture** respected (UI -> Domain -> Data)
- **Repository/service boundaries** not bypassed
- **Test double strategy** matches project convention
  (fakes vs mocks vs stubs)
- **Dependency injection** bindings exist for new dependencies
- **Type safety** enforced where the project expects it
  (sealed types, enums, branded types)

### 1.5 Verify Signatures and Dependencies

- Check constructor parameters, return types, method signatures
- Verify DI bindings exist for new dependencies
- Cross-reference project guidelines and `PROJECT.md`
- Run checks in parallel where possible

---

## Phase 2: Planning

### 2.1 Chunk Decomposition

Break the feature into implementation chunks.
See [chunk-template.md](references/chunk-template.md).

Rules:

- Each chunk is independently testable (or marked BATCH)
- Chunks list files to create and modify
- Chunks specify test files and TDD instructions
- Chunks declare dependencies on other chunks
- Optional `notes` field captures pattern hints / pitfalls a resuming
  session can't infer from `name` + files + `tdd`

### 2.2 Dependency Graph

Organize chunks into layers:

```text
Layer 1 (no deps):     Chunks that can start immediately
Layer 2 (deps on L1):  Chunks needing Layer 1 complete
Layer N (final):       Regression + quality verification
```

### 2.3 Create JSON Tracker

Create a tracker file following the schema in
[tracker-schema.md](references/tracker-schema.md).
The tracker is always created, even for single-chunk features
(see §Single-Chunk Features in the schema).

The tracker is the single source of truth for progress.
Always update status to `in_progress` BEFORE starting a chunk.

**Why always?** The tracker is a file-based artifact that survives
context resets. Relying on in-context memory loses state when
sessions end or context is compacted. The tracker ensures any
session — current or future — can pick up exactly where work
stopped.

### 2.4 Present Plan to User

Enter Plan Mode (`Shift+Tab` twice from Normal Mode) and present:

- Context: why this change is needed
- Acceptance criteria
- Chunk breakdown with dependency graph
- Files affected
- Quality verification approach

Press `Ctrl+G` to open the plan in your text editor for direct
editing before proceeding.

Get user approval, then switch back to Normal Mode (`Shift+Tab`)
before proceeding to implementation.

### 2.5 Plan Review Gate

**GATE — The tracker artifact from 2.3 triggers this review.
Do not proceed to Phase 3 until review completes.**

The tracker file is the review input. Spawn the `review-plan`
agent (`.claude/agents/review-plan.md`) as a subagent so the
reviewer operates in a fresh context without author bias:

```
Use the review-plan agent to review [path to tracker]
```

The agent evaluates 8 criteria against the plan: completeness,
correctness, functional gaps, standards, regression risk,
robustness, architectural gaps, and TDD quality.

**FAIL:** update the plan and re-run review-plan.
**WARN:** proceed with a note.
**PASS:** proceed to Phase 3.
**Agent failure** (timeout, error): fall back to self-check against
[quality-checklist.md](references/quality-checklist.md) and proceed.

Record the verdict in the tracker's top-level `plan_review` field
(e.g., `"plan_review": "PASS"`) so the gate survives session resets.

---

## Phase 3: Pre-Test (per chunk)

### 3.1 Determine Test Strategy

| Chunk Type | Test Strategy |
|---|---|
| Data class with logic | Computed properties, boundary values |
| Sealed type / union | Property delegation for each variant |
| Repository / service impl | Conversion helpers, filtering, errors |
| Observer / manager | Lifecycle, debounce, state changes |
| Configuration / preferences | Defaults, type conversions, round-trips |
| Composite / aggregating layer | Merge logic, fallbacks, empty states |
| Interface / trait only | No test (tested via downstream fake) |
| UI: state-holder / hoisted state | TEST — extract holder, unit-test transitions |
| UI: rendering only (no logic) | No test (build + regression) |
| DI wiring / config | No test (verified by compilation) |
| Type migration / rename | No test (verified by compilation) |

**State-holder detection:** Hoisted state (`mutableStateOf`,
`useState`, `ref`, `@State`), branching effects (`LaunchedEffect`,
`useEffect` with deps), or input transformation = testable logic.
Extract the holder out of the framework component and unit-test
the transitions. "UI = no test" is the most-abused row in this
table; a state machine inside a Composable is still a state
machine.

### 3.2 Write Failing Tests (or Verify Existing Coverage)

If the test strategy says "No test," verify existing coverage
is green and skip to Phase 4. Otherwise:

- Write tests referencing the new function/class/property
- Tests describe expected behavior, not implementation
- For new functions: expect compile errors
- For behavior changes: expect assertion failures

### 3.3 Run Tests (Expect Failure)

Run the project's test command (see `PROJECT.md`) targeting
the specific test class. Confirm tests fail for the right
reason (compile error or assertion failure, not infrastructure).

---

## Phase 4: Implementation (per chunk)

### 4.1 Update Tracker

Set chunk status to `in_progress` in the JSON tracker.

### 4.2 Implement Production Code

- Follow existing patterns in the codebase
- Reuse existing utilities (don't reinvent)
- Keep changes minimal and focused
- For BATCH chunks: all files change together

### 4.3 Handle Constructor / Signature Cascading

When adding a dependency to a class or changing a function signature:

- Grep for all test files that instantiate the class or call the function
- Add the new parameter to every test call site
- This is the most common source of compile failures

### 4.4 Clean Up Dead Code

When a fix eliminates a code path, remove the dead code in the
same chunk. Don't leave it for a future cleanup pass.

Examples:
- Exception class no longer thrown -> remove class + all catch sites
- Feature flag removed -> remove both branches
- Method parameter no longer used -> remove parameter + update callers

**Why same chunk?** Dead code left behind confuses future readers
and creates false grep matches. The person implementing the fix
has the best context for what's now unreachable.

---

## Phase 5: Post-Test (per chunk)

### 5.1 Run Chunk Tests

Run the project's test command targeting the specific test class.
All tests must pass. If a test fails, fix the code (not the
test) unless the test is wrong about expected behavior.

### 5.2 Run Full Suite (Last Chunk Only)

For intermediate chunks, skip the full suite - chunk tests
are sufficient. Run the full suite after the **last** chunk
before Phase 6 (or if a chunk touches widely-shared code).

Check for regressions. Note pre-existing flaky tests but
don't block.

### 5.3 Build Verification

Run the project's build command. Compilation must succeed.

### 5.4 Update Tracker

Set chunk status to `complete` in the JSON tracker.

### 5.5 Manage Context

Prefer **context resets** over compaction. A clean session with
the tracker as handoff preserves more fidelity than compacted
context, which loses information unpredictably.

**Between chunks (preferred):** Start a new session. The JSON
tracker (`name` + `files_*` + `tdd` + `acceptance_criteria` + any
`notes`) gives the new session everything it needs. Use `/rename`
to name the session for reference.

**Mid-chunk (fallback only):** If you must compact within a chunk,
run `/compact Focus on the current chunk, tracker path, and test
results`. This is a fallback — finish the chunk and reset.

---

## Phase 6: Quality Verification

After all chunks complete, run the 8-point checklist.
See [quality-checklist.md](references/quality-checklist.md)
for detailed criteria.

### Quick Reference

1. **Completeness** - All acceptance criteria met
2. **Correctness** - Data mapping, conversions, logic
3. **Gaps (Functional)** - No broken refs or orphaned code
4. **Standards** - Project patterns, platform conventions
5. **Regression** - Full test suite passes, build succeeds
6. **Robustness** - Error handling, empty states, edge cases
7. **Gaps (Architectural)** - Abstraction boundaries respected
8. **Blindspots** - Concurrency, security, edge environments

**GATE — All chunks complete triggers parallel review.** Both
reviewers are read-only as long as `/code-review` is invoked
without `--fix`, so concurrent runs are safe. Spawn both in a
single message:

1. **`review-impl` agent** — covers all 8 quality-checklist criteria
   (completeness, correctness, gaps, standards + architecture,
   regression, robustness + blindspots, dead code, documentation)
2. **`/code-review`** — reports correctness bugs and reuse /
   simplification cleanups on the diff

```
In parallel:
- Use the review-impl agent to review implementation against [path to tracker]
- Run /code-review on changed files
```

Merge findings from both sources, address any FAIL findings, then
re-run the suite.

**Agent failure** (timeout, error): fall back to self-check against
the full [quality-checklist.md](references/quality-checklist.md).
Document any agent failures in the tracker.

### Post-Implementation Documentation

**Always create or update a reference document** that survives
context compaction. This is required even for small fixes.
The document serves as the single source of truth for what was
done, why, and what remains.

Contents:
- What was changed and why (bugs found, spec sections, fixes applied)
- What was tested and confirmed working (passing tests)
- What remains (known gaps, future work)
- Test file locations and counts

If the feature already has an analysis doc, design doc, or issue
tracker, update it instead of creating a new one:

- Update status of implemented items (e.g., "A1: Implemented")
- Add commit/version reference
- Mark remaining items as still pending

**Why mandatory?** Context compaction loses implementation details.
The doc ensures a future session can understand the full scope of
what was reviewed, what was fixed, and what was intentionally left.

---

## Lessons Learned (Apply Every Time)

1. **Tracker discipline** -
   Update status to `in_progress` BEFORE starting work
2. **Batch interconnected type changes** -
   Changing a shared type's field? Change all consumers in one chunk
3. **Platform quirks** -
   Research boundary values, write tests BEFORE implementing
4. **Don't over-chunk UI wiring** -
   Keep compatible signatures to avoid cascading changes
5. **Sealed type formatting** -
   Use common properties first; branch only for unique data
6. **Catch narrow exceptions for skip+continue** -
   When converting `throw` to `continue` (resilience fix),
   narrow catch scope. Fatal errors (OOM, stack overflow)
   indicate the runtime is broken - continuing would cause
   cascading failures. Also verify cancellation exceptions
   can't reach the catch site
7. **Fix sibling components together** -
   If two components share the same bug pattern, fix both
   in one pass. Don't leave one broken for a future session
8. **Check ALL required constructor params** -
   When creating instances in tests or extensions, verify
   no required params are missing
9. **Adding checks breaks existing tests** -
   When adding validation/permission checks to production
   code, existing tests that skip setup for that check
   will fail. Grep test files and add required setup
10. **Guard against false positive tests** -
    When asserting string/pattern presence, verify the match
    is in the right context - not in a comment, label, or
    unrelated field. Use precise assertions (line-level,
    regex-anchored) instead of broad substring checks.
    A broad check can pass for the wrong reason, hiding
    the real bug
11. **Pre-written tests skip Phase 3** -
    When failing tests already exist (compliance review, bug
    reproduction, user-provided test case), Phase 3 collapses
    to "verify tests still fail for the right reason." Don't
    rewrite or duplicate them - go straight to Phase 4
12. **Stress-test your process scaffolding** -
    Every process step encodes assumptions about model
    limitations. As models improve, re-evaluate whether
    scaffolding (sprint decomposition, heavy chunking,
    frequent resets) is still needed. Remove what no longer
    helps — simpler processes with fewer handoffs are faster
    and lose less context
13. **Calibrate evaluation criteria over time** -
    After Phase 6, compare your quality assessment to what
    the user actually flagged. If you marked "all criteria
    met" but the user found gaps, tighten the checklist or
    acceptance criteria for next time. This QA tuning loop
    — read evaluator output, find divergences from human
    expectations, refine criteria — compounds over sessions
14. **Check dependency version changelogs during analysis** -
    APIs can change behavior across minor versions without
    changing their signature. A method that fully re-executes
    in v1.0 may only recompose a subset in v1.1. During
    Phase 1.3, check the changelog/migration guide for each
    major dependency at your pinned version. This is
    especially important for framework-level dependencies
    (UI toolkits, DI containers, async runtimes) where
    lifecycle semantics evolve between releases

---

## Commit Guidance

Do not commit proactively. Wait for the user to request it.
Refer to `PROJECT.md` for project-specific commit conventions
(author, message format, trailers).

---

## Session Resumption

When resuming work on an in-progress feature:

1. Read the JSON tracker to find current progress
2. Check `plan_review` field — if missing or `"FAIL"`, run Phase 2.5
   before proceeding
3. Read the plan file for detailed chunk descriptions
4. Find next `pending` chunk where all `depends_on` are `complete`
5. Read `name`, `files_create`/`files_modify`, `tdd`,
   `acceptance_criteria`, and any `notes` on that chunk
6. Follow TDD workflow (Phase 3 -> 4 -> 5)
7. Update tracker status

**Tip:** Use `--resume` to continue a named session, or read the
JSON tracker if starting a fresh session on an existing feature.
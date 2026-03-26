---
name: tdd
description: "Structured TDD process: explores code, plans with chunk decomposition, writes failing tests first, implements to pass, and runs an 8-point quality checklist. Use when implementing features, fixing bugs, or refactoring with test verification."
argument-hint: "[description of feature, fix, or refactor]"
effort: high
---

# TDD Implementation Process

Implement the following using test-driven development: $ARGUMENTS

Tests give Claude a self-verification loop. Instead of producing code
that looks right, write tests first, then implement until they pass.
This is the highest-leverage pattern for agentic coding.

## Mapping to Claude Code Workflow

| Claude Code Phase | TDD Phase | What Happens |
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
with no new domain logic (pure UI, config wiring), collapse to:
Analysis -> Pre-Test (verify existing coverage) -> Implement ->
Post-Test (regression) -> Quality Verification. Use a 1-chunk
tracker (see [tracker-schema.md](references/tracker-schema.md)
§Single-Chunk Features). Skip chunking and plan mode.

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
Phase 3: Pre-Test (per chunk)
Phase 4: Implementation (per chunk)
Phase 5: Post-Test (per chunk)
Phase 6: Quality Verification
```

Each phase must complete before the next begins.
For multi-chunk features, Phases 3-5 repeat per chunk.

---

## Phase 1: Analysis

### 1.1 Understand the Request

- Read the user's request carefully
- Identify: new feature, enhancement, bug fix, refactor, or test
- Check `docs/specs/` for an existing spec file matching the feature.
  If found, use it as primary input — user stories, acceptance criteria,
  and edge cases become the basis for chunk decomposition in Phase 2.
  (Specs are created by the [spec skill](https://github.com/openkash/ai-agent-spec-skill), an optional companion.)
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
- Each chunk has a `resume` field for session resumption

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

### 2.5 Plan Review (8-Point Checklist on the Plan)

**Before writing any code**, review the approved plan against the
8-point quality checklist. This catches design bugs before they
become code bugs.

**Use the `review-plan` agent** (`.claude/agents/review-plan.md`)
to get an independent review. Spawn it as a subagent so the
reviewer operates in a fresh context without author bias:

```
Use the review-plan agent to review [path to tracker/plan]
```

The agent evaluates these 8 criteria against the plan:

1. **Completeness** - Does every acceptance criterion have a chunk?
2. **Correctness** - Are catch scopes right? Are edge cases handled?
3. **Gaps (Functional)** - Does the fix create dead code? If so,
   add cleanup to the chunk
4. **Standards** - Do proposed changes follow project patterns?
5. **Regression** - Are all affected test files listed in chunks?
   (Grep for constructor/function usage to find unlisted breakage)
6. **Robustness** - What if all items fail? What if input is empty?
7. **Gaps (Architectural)** - Are abstraction boundaries respected?
8. **Blindspots** - Concurrency? Error propagation? Thread safety?

**If the agent reports FAIL findings:** Update the plan before
proceeding. This is cheaper than fixing bugs in implementation.
WARN findings can proceed with a note.

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
| UI component | No test (build + regression) |
| DI wiring / config | No test (verified by compilation) |
| Type migration / rename | No test (verified by compilation) |

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
tracker + resume fields give the new session everything it needs.
Use `/rename` to name the session for reference.

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

**Use the `review-impl` agent for verification (medium+ features).**
Agents tend to praise their own work — separating generation from
evaluation produces more honest assessment. Spawn it as a subagent:

```
Use the review-impl agent to review implementation against [path to tracker/plan]
```

The agent verifies plan conformance, acceptance criteria, test
quality, code quality, regression, robustness, dead code, and
documentation — then produces a structured verdict.

Additionally, run `/simplify` for a parallel review of changed
files for code reuse, quality, and efficiency. For small features,
self-verification against the checklist is sufficient.

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
2. **Constructor/signature cascading** -
   When adding class dependencies or changing signatures,
   grep ALL test files that call the affected code
3. **Batch interconnected type changes** -
   Changing a shared type's field? Change all consumers in one chunk
4. **Platform quirks** -
   Research boundary values, write tests BEFORE implementing
5. **Don't over-chunk UI wiring** -
   Keep compatible signatures to avoid cascading changes
6. **Sealed type formatting** -
   Use common properties first; branch only for unique data
7. **TDD means fix code, not tests** -
   If test describes correct behavior and code doesn't match,
   fix the code
8. **Catch narrow exceptions for skip+continue** -
   When converting `throw` to `continue` (resilience fix),
   narrow catch scope. Fatal errors (OOM, stack overflow)
   indicate the runtime is broken - continuing would cause
   cascading failures. Also verify cancellation exceptions
   can't reach the catch site
9. **Fix sibling components together** -
   If two components share the same bug pattern, fix both
   in one pass. Don't leave one broken for a future session
10. **Check ALL required constructor params** -
    When creating instances in tests or extensions, verify
    no required params are missing
11. **Extract testable logic from UI** -
    If inline UI logic is worth testing, extract it as a
    separate function. Test the function, not the UI
12. **Adding checks breaks existing tests** -
    When adding validation/permission checks to production
    code, existing tests that skip setup for that check
    will fail. Grep test files and add required setup
13. **Clean up dead code in the same chunk** -
    When a fix makes a code path unreachable, remove it
    immediately. Don't leave dead code for a future pass.
    The implementer has the best context for what's now dead
14. **Review the plan before coding** -
    Apply the 8-point quality checklist to the plan itself
    (Phase 2.5). This is cheaper than finding design bugs
    during implementation
15. **Guard against false positive tests** -
    When asserting string/pattern presence, verify the match
    is in the right context - not in a comment, label, or
    unrelated field. Use precise assertions (line-level,
    regex-anchored) instead of broad substring checks.
    A broad check can pass for the wrong reason, hiding
    the real bug
16. **Pre-written tests skip Phase 3** -
    When failing tests already exist (compliance review, bug
    reproduction, user-provided test case), Phase 3 collapses
    to "verify tests still fail for the right reason." Don't
    rewrite or duplicate them - go straight to Phase 4
17. **Stress-test your process scaffolding** -
    Every process step encodes assumptions about model
    limitations. As models improve, re-evaluate whether
    scaffolding (sprint decomposition, heavy chunking,
    frequent resets) is still needed. Remove what no longer
    helps — simpler processes with fewer handoffs are faster
    and lose less context
18. **Calibrate evaluation criteria over time** -
    After Phase 6, compare your quality assessment to what
    the user actually flagged. If you marked "all criteria
    met" but the user found gaps, tighten the checklist or
    acceptance criteria for next time. This QA tuning loop
    — read evaluator output, find divergences from human
    expectations, refine criteria — compounds over sessions

---

## Commit Guidance

Do not commit proactively. Wait for the user to request it.
Refer to `PROJECT.md` for project-specific commit conventions
(author, message format, trailers).

---

## Session Resumption

When resuming work on an in-progress feature:

1. Read the JSON tracker to find current progress
2. Read the plan file for detailed chunk descriptions
3. Find next `pending` chunk where all `depends_on` are `complete`
4. Read the chunk's `resume` field for instructions
5. Follow TDD workflow (Phase 3 -> 4 -> 5)
6. Update tracker status

**Tip:** Use `--resume` to continue a named session, or read the
JSON tracker if starting a fresh session on an existing feature.
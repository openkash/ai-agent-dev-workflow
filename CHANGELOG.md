# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2026-04-12

### Changed

- `/tdd` Phase 2.5 restructured as artifact-triggered gate. The tracker file from Phase 2.3 triggers the review-plan agent automatically. Phase 3 is blocked until review completes. Replaces soft instructional wording that was often skipped.
- `/tdd` Phase 6 restructured as parallel gate. review-impl agent and /simplify now run concurrently in a single spawn. Removed "medium+ features" qualifier and "self-verification sufficient" escape hatch. Phase 6 review applies to all features including small ones.
- `review-plan` criterion 1 renamed from "Completeness" to "Scope & Completeness". Now checks both directions: every criterion has a chunk (completeness) AND every chunk serves a criterion (containment). Catches scope expansion before it becomes code.

### Added

- `plan_review` field in tracker schema. Stores the review-plan gate verdict (PASS/PASS-WITH-WARNINGS/FAIL) so it survives session resets. Session resumption checks this field before Phase 3.
- Fallback clauses for agent failures. If review-plan or review-impl agents timeout or error, the skill falls back to self-check against quality-checklist.md instead of silently skipping.
- Gate annotations in `/tdd` process overview showing which artifacts trigger which reviews and what they block.

## [1.0.0] - 2026-03-28

### Added

- `/spec` skill — structured specification with user stories, acceptance criteria, interactive clarification (max 5 questions), 9-category ambiguity taxonomy, and 8-point validation
- `/tdd` skill — test-driven development with chunk decomposition, dependency graphs, JSON tracker with per-chunk resume fields, and red-green-refactor cycle
- `review-plan` agent — independent 8-point plan review (completeness, correctness, functional gaps, standards, regression, robustness, architectural gaps, TDD quality) running in isolated context
- `review-impl` agent — independent 8-point implementation review (plan conformance, acceptance criteria, test quality, code quality, regression, robustness, dead code, documentation) running in isolated context
- Claude Code plugin format with auto-discovery
- Project-specific configuration via `PROJECT.md` templates
- Example configs for Android/Kotlin, TypeScript/Node, Python/Django, Python/pytest, Rust/CLI, Rust/Cargo
- Session resumption via JSON tracker with per-chunk resume fields

[1.1.0]: https://github.com/openkash/ai-agent-dev-workflow/releases/tag/v1.1.0
[1.0.0]: https://github.com/openkash/ai-agent-dev-workflow/releases/tag/v1.0.0

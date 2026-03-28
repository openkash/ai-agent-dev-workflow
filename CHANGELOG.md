# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

[1.0.0]: https://github.com/openkash/ai-agent-dev-workflow/releases/tag/v1.0.0

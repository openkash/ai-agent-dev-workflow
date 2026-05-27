[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-Plugin-blueviolet.svg)](https://claude.com/claude-code)
[![Spec Kit](https://img.shields.io/badge/Spec%20Kit-Community%20Extension-green.svg)](https://github.com/github/spec-kit)

# AI Development Workflow

A complete development workflow for
[Claude Code](https://docs.anthropic.com/en/docs/claude-code):
specify, plan, review, implement, verify.

```
/spec            Clarify WHAT to build (user stories, acceptance criteria)
    |
/implement       Plan HOW to build it (chunks, dependencies, tracker)
    |
    |--- GATE: tracker file triggers review-plan automatically
    v
review-plan      Independent 8-point plan review (blocks implementation)
    |
/implement       Implement test-first (failing test -> code -> pass)
    |
    |--- GATE: all chunks complete triggers parallel review
    v
review-impl      Verifies implementation matches plan ---+
/code-review     Reviews code reuse and quality ---------+--- run in parallel
```

`/implement` handles both planning and implementation. Reviews are
**artifact-triggered gates**, not optional suggestions. The tracker
file triggers review-plan; chunk completion triggers review-impl.
Both agents run in isolated context with no memory of writing the
code, so they evaluate honestly.

## Why This Workflow

> [!TIP]
> - **Reviews are gates, not suggestions.** The tracker file triggers review-plan before coding starts. Chunk completion triggers review-impl + /code-review in parallel. No manual invocation needed, no option to skip.
> - **The reviewer didn't write the code.** Review agents spawn in a fresh context, separate from the author. Bias eliminated by architecture, not instruction.
> - **Scope is checked in both directions.** review-plan verifies every criterion has a chunk (completeness) AND every chunk serves a criterion (containment). Catches scope expansion before it becomes code.
> - **Design bugs are caught before coding starts.** 8-point plan review before any code is written. Fixing a wrong abstraction in a plan costs minutes. In code, hours.
> - **Specs are created, not just read.** `/spec` writes user stories with Given/When/Then acceptance criteria, then `/implement` implements them. From "what should we build?" to passing tests.
> - **Work survives context resets.** JSON tracker with per-chunk `name`, `files_*`, `tdd`, `acceptance_criteria` (plus optional `notes`) and the top-level `plan_review` verdict tells a new session exactly where to pick up.
> - **One install, complete workflow.** Four pieces that work as a pipeline. No separate tools to discover, install, and wire.

## What's Included

| Piece | Type | Invocation | Purpose |
|-------|------|-----------|---------|
| [spec](skills/spec/SKILL.md) | Skill | `/spec <feature>` | User stories, acceptance criteria, edge cases |
| [implement](skills/implement/SKILL.md) | Skill | `/implement <feature>` | Chunk decomposition, test-driven cycle, quality checklist |
| [review-plan](agents/review-plan.md) | Agent | Triggered by /implement | 8-point plan review with scope containment check |
| [review-impl](agents/review-impl.md) | Agent | Triggered by /implement | Checks code matches the plan and passes acceptance criteria |

## Installation

### As a Claude Code plugin (recommended)

```bash
# From your project root
git clone https://github.com/openkash/ai-agent-dev-workflow.git .claude/plugins/dev-workflow
```

Claude Code auto-discovers plugins. Both skills appear in the `/` menu
and both agents are available to use.

### Manual copy (any AI coding tool)

```bash
git clone https://github.com/openkash/ai-agent-dev-workflow.git /tmp/dev-workflow

# Skills
mkdir -p .claude/skills/spec .claude/skills/implement
cp /tmp/dev-workflow/skills/spec/SKILL.md .claude/skills/spec/
cp -r /tmp/dev-workflow/skills/spec/references/ .claude/skills/spec/
cp -r /tmp/dev-workflow/skills/spec/project-configs/ .claude/skills/spec/
cp /tmp/dev-workflow/skills/implement/SKILL.md .claude/skills/implement/
cp -r /tmp/dev-workflow/skills/implement/references/ .claude/skills/implement/
cp -r /tmp/dev-workflow/skills/implement/project-configs/ .claude/skills/implement/

# Agents
mkdir -p .claude/agents
cp /tmp/dev-workflow/agents/*.md .claude/agents/
```

## Configuration

Each skill reads a `PROJECT.md` in its directory for project-specific
settings (build commands, test commands, standards).

```bash
# Copy templates and customize
cp /tmp/dev-workflow/skills/implement/PROJECT.md .claude/skills/implement/PROJECT.md
cp /tmp/dev-workflow/skills/spec/PROJECT.md .claude/skills/spec/PROJECT.md
```

Example configs for common stacks are in `skills/*/project-configs/`.

## Usage

### Full workflow

```
/spec add rate limiting to the API endpoints
```
Produces `docs/specs/rate-limiting.md` with user stories and acceptance criteria.

```
/implement rate limiting (spec: docs/specs/rate-limiting.md)
```
The /implement skill decomposes the work into chunks, creates a
tracker, and asks for approval. The tracker file automatically
triggers the review-plan gate:

```
GATE: tracker triggers review-plan agent (blocks Phase 3)
-> Returns structured verdict (PASS/WARN/FAIL per criterion)
-> FAIL: update plan and re-run. PASS: proceed to implementation.
```

After all chunks are implemented, /implement triggers the
implementation review gate (both run in parallel):

```
GATE: all chunks complete triggers parallel review
-> review-impl agent verifies plan conformance and acceptance criteria
-> /code-review reviews code reuse and quality
-> Address any FAIL findings before completing.
```

### Standalone agent use

The agents work independently of the skills:

```
Use the review-plan agent to review my-plan.md
Use the review-impl agent to check the implementation against docs/impl-tracker.json
```

## File Structure

```
ai-agent-dev-workflow/
├── .claude-plugin/
│   └── plugin.json              # Claude Code plugin metadata
├── skills/
│   ├── spec/                    # Specification skill
│   │   ├── SKILL.md             # Core spec process
│   │   ├── PROJECT.md           # Template - copy and customize
│   │   ├── references/          # Spec template, taxonomy, validation
│   │   └── project-configs/     # Example configs per stack
│   └── implement/               # Implementation skill
│       ├── SKILL.md             # Core implementation process
│       ├── PROJECT.md           # Template - copy and customize
│       ├── references/          # Chunk template, tracker schema, checklist
│       └── project-configs/     # Example configs per stack
├── agents/
│   ├── review-plan.md           # Plan review agent (8-point)
│   └── review-impl.md          # Implementation review agent (8-point)
├── LICENSE                      # Apache 2.0
└── README.md
```

## Design Decisions

### Why agents, not skills?

The review agents are subagents (not slash-command skills) by design:

| Factor | Skill (`/review-plan`) | Agent (subagent) |
|--------|----------------------|-------------------|
| **Evaluator independence** | Runs in same context as author, biased toward own work | Fresh context, no memory of writing the plan/code |
| **Context pollution** | Review details consume main window | Isolated, returns summary only |
| **Automation** | User must remember to invoke | /implement gates trigger automatically from artifacts |
| **Parallel execution** | Sequential in main context | Can run both reviews in parallel |
| **Standalone use** | User invokes via `/review-plan` | User invokes via natural language ("review this plan") |

**The reviewer should not share context with the author.** A fresh
context produces more honest evaluation than reviewing your own work.

### Why a combined repo?

The four pieces form a pipeline. Distributing them separately means
users must discover, install, and wire 4 repos. The plugin format
gives you the full workflow in one install. Individual repos
are still available if you only need one piece.

## Acknowledgments

Inspired by [Spec Kit](https://github.com/github/spec-kit) and its
Spec-Driven Development approach. This project is a
[community extension](https://github.com/github/spec-kit#-community-extensions)
for the Spec Kit ecosystem.

## License

Apache License 2.0. See [LICENSE](LICENSE).

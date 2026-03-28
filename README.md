[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-Plugin-blueviolet.svg)](https://claude.com/claude-code)
[![Spec Kit](https://img.shields.io/badge/Spec%20Kit-Community%20Extension-green.svg)](https://github.com/github/spec-kit)

# AI Development Workflow

A complete development workflow for
[Claude Code](https://docs.anthropic.com/en/docs/claude-code):
specify, plan, review, implement, verify.

```
/spec          Clarify WHAT to build (user stories, acceptance criteria)
    ↓
/tdd           Plan HOW to build it (chunks, dependencies, tracker)
    ↓
review-plan    Independent agent validates the plan (8-point review)
    ↓
/tdd           Implement with TDD (failing test → code → pass)
    ↓
review-impl    Independent agent verifies implementation matches plan
```

`/tdd` handles both planning and implementation. The review agents
run in isolated context. They didn't write the plan or code, so
they evaluate honestly.

## Why This Workflow

> [!TIP]
> - **The reviewer didn't write the code.** Review agents spawn in a fresh context, separate from the author. Bias eliminated by architecture, not instruction.
> - **Design bugs are caught before coding starts.** 8-point plan review before any code is written. Fixing a wrong abstraction in a plan costs minutes. In code, hours.
> - **Specs are created, not just read.** `/spec` writes user stories with Given/When/Then acceptance criteria, then `/tdd` implements them. From "what should we build?" to passing tests.
> - **Work survives context resets.** JSON tracker with per-chunk `resume` fields tells a new session exactly where to pick up.
> - **One install, complete workflow.** Four pieces that work as a pipeline. No separate tools to discover, install, and wire.

## What's Included

| Piece | Type | Invocation | Purpose |
|-------|------|-----------|---------|
| [spec](skills/spec/SKILL.md) | Skill | `/spec <feature>` | User stories, acceptance criteria, edge cases |
| [tdd](skills/tdd/SKILL.md) | Skill | `/tdd <feature>` | Chunk decomposition, TDD cycle, quality checklist |
| [review-plan](agents/review-plan.md) | Agent | "use the review-plan agent" | 8-point plan review before coding |
| [review-impl](agents/review-impl.md) | Agent | "use the review-impl agent" | Checks code matches the plan and passes acceptance criteria |

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
mkdir -p .claude/skills/spec .claude/skills/tdd
cp /tmp/dev-workflow/skills/spec/SKILL.md .claude/skills/spec/
cp -r /tmp/dev-workflow/skills/spec/references/ .claude/skills/spec/
cp -r /tmp/dev-workflow/skills/spec/project-configs/ .claude/skills/spec/
cp /tmp/dev-workflow/skills/tdd/SKILL.md .claude/skills/tdd/
cp -r /tmp/dev-workflow/skills/tdd/references/ .claude/skills/tdd/
cp -r /tmp/dev-workflow/skills/tdd/project-configs/ .claude/skills/tdd/

# Agents
mkdir -p .claude/agents
cp /tmp/dev-workflow/agents/*.md .claude/agents/
```

### Individual skills (standalone repos)

If you only want one piece:

- **Spec only:** [openkash/ai-agent-spec-skill](https://github.com/openkash/ai-agent-spec-skill)
- **TDD only:** [openkash/ai-agent-tdd-skill](https://github.com/openkash/ai-agent-tdd-skill)

The review agents are only available in this repo.

## Configuration

Each skill reads a `PROJECT.md` in its directory for project-specific
settings (build commands, test commands, standards).

```bash
# Copy templates and customize
cp /tmp/dev-workflow/skills/tdd/PROJECT.md .claude/skills/tdd/PROJECT.md
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
/tdd implement rate limiting (spec: docs/specs/rate-limiting.md)
```
The TDD skill decomposes the work into chunks, creates a tracker, and
asks for approval. Then it spawns the review-plan agent automatically:

```
Use the review-plan agent to review docs/tdd-tracker.json
```
Returns a structured verdict (PASS/WARN/FAIL per criterion). Fix any
FAILs before coding.

After all chunks are implemented, the TDD skill spawns the review-impl agent:

```
Use the review-impl agent to review implementation against docs/tdd-tracker.json
```
Verifies every acceptance criterion and runs tests.

### Standalone agent use

The agents work independently of the skills:

```
Use the review-plan agent to review my-plan.md
Use the review-impl agent to check the implementation against docs/tdd-tracker.json
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
│   └── tdd/                     # TDD skill
│       ├── SKILL.md             # Core TDD process
│       ├── PROJECT.md           # Template - copy and customize
│       ├── references/          # Chunk template, tracker schema, checklist
│       └── project-configs/     # Example configs per stack
├── agents/
│   ├── review-plan.md           # Plan review agent (8-point)
│   └── review-impl.md          # Implementation review agent (8-point)
├── sync.sh                      # Sync to individual repos (maintainer use)
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
| **Automation** | User must remember to invoke | /tdd spawns automatically at Phase 2.5 and Phase 6 |
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

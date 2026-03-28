# Spec Kit PR Materials

Files created in this repo: `extension.yml`, `CHANGELOG.md`

The PR to [github/spec-kit](https://github.com/github/spec-kit) modifies two files:
1. `extensions/catalog.community.json` — add the entry below
2. `README.md` — add the table row below

---

## 1. catalog.community.json Entry

Add inside `"extensions": { ... }` (alphabetical by key):

```json
"dev-workflow": {
  "name": "Dev Workflow — Spec, TDD & Independent Review Agents",
  "id": "dev-workflow",
  "description": "Specify, plan, review, implement, verify — full TDD pipeline with isolated reviewer agents.",
  "author": "openkash",
  "version": "1.0.0",
  "download_url": "https://github.com/openkash/ai-agent-dev-workflow/archive/refs/tags/v1.0.0.zip",
  "repository": "https://github.com/openkash/ai-agent-dev-workflow",
  "homepage": "https://github.com/openkash/ai-agent-dev-workflow",
  "documentation": "https://github.com/openkash/ai-agent-dev-workflow/blob/main/README.md",
  "changelog": "https://github.com/openkash/ai-agent-dev-workflow/blob/main/CHANGELOG.md",
  "license": "Apache-2.0",
  "requires": {
    "speckit_version": ">=0.1.0",
    "tools": [
      {
        "name": "claude-code",
        "required": true
      }
    ]
  },
  "provides": {
    "commands": 4,
    "hooks": 2
  },
  "tags": ["tdd", "specification", "review", "claude-code", "workflow"],
  "verified": false,
  "downloads": 0,
  "stars": 0,
  "created_at": "2026-03-28T00:00:00Z",
  "updated_at": "2026-03-28T00:00:00Z"
}
```

---

## 2. README.md Table Row

Insert alphabetically in the Community Extensions table:

```markdown
| Dev Workflow | Specify, plan, review, implement, verify — full TDD pipeline with isolated reviewer agents | `process` | Read+Write | [ai-agent-dev-workflow](https://github.com/openkash/ai-agent-dev-workflow) |
```

---

## 3. PR Title

```
Add Dev Workflow extension — spec authoring, TDD, and independent review agents for Claude Code
```

---

## 4. PR Body

```markdown
## Summary

- Adds **Dev Workflow** to the community extensions catalog
- Full development lifecycle: `/spec` (specify) → `/tdd` (plan + implement) → `review-plan` (independent plan review) → `review-impl` (independent implementation review)
- Built for Claude Code (like `ralph` is built for Copilot CLI)

## What makes this different from existing extensions

| Differentiator | Details | Closest alternative |
|---|---|---|
| **Evaluator independence by architecture** | Review agents run as subagents in fresh context — no shared memory with the code author, eliminating self-praise bias structurally | MAQA has separate agents for parallelism, not for bias elimination |
| **Pre-implementation plan review** | 8-point structured review BEFORE any code is written (Phase 2.5) | Every quality extension (Review, Verify, Cleanup) is post-implementation only |
| **Spec authoring + TDD in one pipeline** | Creates specifications (not just consumes them) and implements via TDD with chunk decomposition | No extension combines authoring with TDD implementation |
| **Session resumption via JSON tracker** | Per-chunk resume fields survive context resets across sessions | No equivalent in the ecosystem |
| **4 pieces = full lifecycle** | Equivalent coverage would require 5-6 separate extensions from different authors | Conduct + Plan Review Gate + Review + Verify + Cleanup |

## Checklist

- [x] Valid `extension.yml` manifest
- [x] `README.md` with installation and usage docs
- [x] `LICENSE` file (Apache 2.0)
- [ ] GitHub release created (v1.0.0)
- [x] Extension tested on real projects
- [x] All commands working
- [x] No security vulnerabilities
- [x] Entry added to `extensions/catalog.community.json`
- [x] Row added to Community Extensions table in `README.md`

## Test plan

- [ ] Clone the extension into a Claude Code project via `git clone`
- [ ] Verify `/spec` and `/tdd` appear in the Claude Code slash-command menu
- [ ] Run `/spec` on a sample feature and confirm spec output
- [ ] Run `/tdd` referencing the spec and confirm tracker creation
- [ ] Verify review-plan agent spawns at Phase 2.5
- [ ] Verify review-impl agent spawns at Phase 6
```

---

## 5. Pre-PR Checklist (do before submitting)

1. **Create GitHub release v1.0.0** on `openkash/ai-agent-dev-workflow`
   ```bash
   gh release create v1.0.0 --repo openkash/ai-agent-dev-workflow \
     --title "v1.0.0" \
     --notes "Initial release — spec skill, TDD skill, review-plan agent, review-impl agent"
   ```

2. **Fork github/spec-kit** and create a branch

3. **Edit two files** in the fork:
   - `extensions/catalog.community.json` — add the entry above
   - `README.md` — add the table row above

4. **Submit PR** with the title and body above

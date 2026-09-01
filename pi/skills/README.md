# Pi Skills

Skills live here and are symlinked into `~/.pi/agent/skills/` by
`scripts/pilink.sh` (run via `just link` / `just pi-link`).

Each skill is a self-contained directory containing a `SKILL.md` with
required frontmatter (`name`, `description`). Everything else in the directory
(scripts, references, assets) is freeform.

## Adding a skill

Drop a new directory here:

```
pi/skills/
└── my-skill/
    ├── SKILL.md          # required: name + description frontmatter
    ├── scripts/          # optional helper scripts
    └── references/       # optional on-demand docs
```

Then re-run `just pi-link`. Example `SKILL.md`:

```markdown
---
name: my-skill
description: What this skill does and when to use it. Be specific.
---

# My Skill

## Usage

./scripts/run.sh
```

## Importing community skills

- **Anthropic Skills**: https://github.com/anthropics/skills (docx, pdf, pptx, xlsx, webdev)
- **Pi Skills**: https://github.com/badlogic/pi-skills (web search, browser automation, Google APIs)

Copy (or git-submodule) the skill directories you want into this folder.

See the Agent Skills spec: https://agentskills.io/specification

# Project principles

Principles are the **considerations every spec must address** — the customisation surface of
incant. They are data, not skill prose: add your own without forking a skill.

## How resolution works

The `writing-specs` skill resolves the active principle set as a **union by `name`** of:

1. **Defaults** bundled with the skill — `config-vs-code`, `security`, `testability`.
2. **This folder** (`.incant/principles/`) — your additions and overrides.

On a `name` collision, **the file here wins**. To switch a default off, add a file with the
same `name` and `enabled: false`.

## Adding a principle

Create `<name>.md` here:

```markdown
---
name: accessibility
applies: [spec]        # v1 honours `spec` only; other values are tolerated for the future
heading: Accessibility
enabled: true
---
Describe the consideration the spec must address. The skill adds a "## Considerations →
Accessibility" subsection and checks the spec genuinely covers it before the approval gate.
```

## Overriding / disabling a default

```markdown
---
name: config-vs-code
applies: [spec]
heading: Config vs code
enabled: false
---
Disabled for this project: <reason>.
```

This folder may be empty — the bundled defaults still apply.

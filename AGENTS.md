Chinese version: [AGENTS.zh-CN.md](AGENTS.zh-CN.md).

# Repository Instructions

This repository stores Codex and Claude skill packages.

## Structure

- Keep complete Codex skill packages under `codex/skills/<skill-name>/`.
- Keep complete Claude skill packages under `claude/skills/<skill-name>/`.
- Every skill must have both Codex and Claude packages with the same
  `<skill-name>` directory name and `SKILL.md` `name` value.
- Keep only truly agent-agnostic assets under `common/`.
- Keep repository automation in `scripts/`.

## Skill Package Rules

- Every Codex and Claude skill package must include `SKILL.md`.
- The skill directory name and `SKILL.md` `name` value must match
  `<skill-name>`.
- Skill names must use lowercase kebab-case, start with a lowercase letter, and
  contain only lowercase letters, numbers, and hyphen-separated words.
- New skills use descriptive public names and keep existing names stable.
- Keep `agents/openai.yaml` with the skill when it provides Codex interface
  metadata.
- Do not include `agents/openai.yaml` in Claude packages.
- In Claude packages, reference bundled helper scripts with
  `${CLAUDE_SKILL_DIR}` so the package works from personal, project, or plugin
  skill locations.
- Keep helper scripts inside the skill package when `SKILL.md` references them
  by relative path.
- Do not move shared-looking scripts into `common/` unless the skill docs and
  installers are updated in the same change.

## Documentation Rules

- English Markdown files use unsuffixed names, for example `README.md`.
- Chinese Markdown files use the `zh-CN` suffix, for example
  `README.zh-CN.md`.
- Pair user-facing repository docs when practical.
- Add a counterpart link near the top of each paired file.
- Keep English and Chinese docs behaviorally equivalent.

## Validation

Run this before committing:

```bash
bash scripts/check.sh
```

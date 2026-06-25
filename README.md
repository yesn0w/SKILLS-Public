Chinese version: [README.zh-CN.md](README.zh-CN.md).

# SKILLS

This repository stores public, reusable agent skills for Codex and Claude.

Skills are maintained in parallel Codex and Claude packages. Both use
`SKILL.md` metadata and the same lowercase kebab-case names. Codex packages keep
Codex-specific interface metadata in `agents/openai.yaml`; Claude packages omit
that metadata and use Claude-compatible script references such as
`${CLAUDE_SKILL_DIR}`. Helper scripts stay with each platform package so each
installed skill remains self-contained.

## Layout

- `codex/skills/`: Codex skill packages ready to link into `~/.codex/skills`.
- `claude/skills/`: Claude skill packages ready to link into `~/.claude/skills`.
- `common/`: notes and future assets that are truly agent-agnostic.
- `scripts/install-codex-skills.sh`: symlink installer for Codex.
- `scripts/install-claude-skills.sh`: symlink installer for Claude.
- `scripts/check.sh`: repository validation.

Current skills, available for both Codex and Claude:

- `bilingual-repo-docs`: maintain paired English and `zh-CN` repository docs.
- `investigate-repo`: investigate repository behavior before editing.
- `pr-prep`: inspect repo state and prepare clean PR work.
- `latest-origin-main`: sync to a clean latest `origin/main`.

## Naming

Codex and Claude skill package directories and `SKILL.md` `name` values use:

```text
<skill-name>
```

Use lowercase kebab-case names that start with a letter and contain only
lowercase letters, numbers, and hyphen-separated words. When adding a new skill,
choose a descriptive public name, keep existing names stable, and add both
platform packages:

```text
codex/skills/<skill-name>/
claude/skills/<skill-name>/
```

## Install On Another Machine

Clone this repository once:

```bash
git clone <repository-url> ~/agent-skills
cd ~/agent-skills
```

For Codex:

```bash
bash scripts/install-codex-skills.sh
```

By default, the installer links skills into:

```text
~/.codex/skills/
```

Set `CODEX_SKILLS_DIR` to install into a different Codex skills directory:

```bash
CODEX_SKILLS_DIR=/path/to/skills bash scripts/install-codex-skills.sh
```

Use dry-run mode to preview changes:

```bash
bash scripts/install-codex-skills.sh --dry-run
```

Restart Codex or open a new session after installing so the skills are
rediscovered.

For Claude:

```bash
bash scripts/install-claude-skills.sh
```

By default, the installer links skills into:

```text
~/.claude/skills/
```

Set `CLAUDE_SKILLS_DIR` to install into a different Claude skills directory:

```bash
CLAUDE_SKILLS_DIR=/path/to/skills bash scripts/install-claude-skills.sh
```

Use dry-run mode to preview changes:

```bash
bash scripts/install-claude-skills.sh --dry-run
```

Restart Claude Code or open a new session if the skills are not rediscovered.

## Use

Explicit prompts are the most reliable.

In Codex:

```text
Use $bilingual-repo-docs to check docs naming and links.
Use $investigate-repo to trace how authentication works before editing code.
Use $pr-prep to prepare this repo for a PR.
Use $latest-origin-main to sync this repo to the latest origin/main.
```

In Claude Code:

```text
/bilingual-repo-docs check docs naming and links.
/investigate-repo trace how authentication works before editing code.
/pr-prep prepare this repo for a PR.
/latest-origin-main sync this repo to the latest origin/main.
```

Natural language may also trigger the skills when the request clearly matches
their descriptions.

## Validate

Run the repository checks before committing changes:

```bash
bash scripts/check.sh
```

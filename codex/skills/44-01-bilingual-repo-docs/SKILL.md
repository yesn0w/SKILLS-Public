---
name: 44-01-bilingual-repo-docs
description: Maintain paired English and Chinese repository documentation. Use when Codex is asked to create, translate, rename, audit, or update bilingual docs; enforce English files without language suffixes and Chinese files with the `zh-CN` suffix; check Markdown links and sources-of-truth consistency across README, setup guides, AGENTS, and docs folders.
---

# Bilingual Repo Docs

## Core Rules

- Treat unsuffixed Markdown files as English, for example `README.md`, `docs/setup.md`.
- Treat Chinese Markdown files as `zh-CN`, for example `README.zh-CN.md`, `docs/setup.zh-CN.md`.
- Maintain a counterpart for each user-facing repo document unless the file is intentionally language-neutral or machine-only.
- Add a one-line counterpart link near the top of each paired file:
  - English file: `Chinese version: [name.zh-CN.md](name.zh-CN.md).`
  - Chinese file: `英文版本：[name.md](name.md)。`
- In Chinese files, link to Chinese counterparts when they exist. In English files, link to English counterparts.
- Update every source of truth in the same change when defaults, setup steps, schemas, or workflows change.

## Workflow

1. Inspect Markdown files with `rg --files -g '*.md'`.
2. Classify files:
   - Chinese content without `zh-CN` suffix should be renamed.
   - English content with `zh-CN` suffix should be renamed or rewritten.
   - User-facing docs without counterparts should get a counterpart.
3. Update cross-links after renames. Do not leave Chinese docs pointing to English docs except for the explicit counterpart link.
4. Preserve repo-specific policy files and naming conventions. If an `AGENTS.md` or equivalent exists, update it to state the bilingual convention.
5. Validate:
   - run `scripts/check_bilingual_docs.py <repo-root>` from this skill when useful.
   - run the project’s normal test/docs checks when available.
   - run `git diff --check`.

## Suggested Scope

Usually pair these files:

- `README.md` and `README.zh-CN.md`
- `start-here.md` and `start-here.zh-CN.md`
- `AGENTS.md` and `AGENTS.zh-CN.md`
- `docs/*.md` and `docs/*.zh-CN.md`

Do not require bilingual pairs for generated export notes, vendored docs, package metadata, changelogs, or temporary output files unless the user explicitly asks.

## Translation Guidance

- Keep commands, environment variables, table names, file paths, and code identifiers unchanged.
- Translate purpose, constraints, and instructions; do not translate literals that users must copy.
- Keep the two language versions equivalent in behavior, not necessarily sentence-for-sentence identical.
- Prefer concise, operational writing. Avoid adding extra policy in only one language.

## Script

Use `scripts/check_bilingual_docs.py` to catch common issues:

```bash
python ~/.codex/skills/44-01-bilingual-repo-docs/scripts/check_bilingual_docs.py .
```

The script checks Markdown link targets, obvious Chinese filenames missing `zh-CN`, and missing counterparts for common user-facing docs.

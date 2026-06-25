---
name: 44-03-pr-prep
description: Prepare repository work for a pull request or first project commit. Use when Codex is asked to inspect git state, detect missing main branches or initial commits, separate unrelated changes, create or verify a branch, stage only relevant files, run validation, commit with a conventional message, push to origin, create a draft PR when possible, or provide copy-ready PR title and description.
---

# PR Prep

## Principles

- Inspect before mutating. Start with branch, status, changed files, untracked files, and remotes.
- Never revert or overwrite unrelated user changes. If unrelated changes exist, leave them unstaged or ask before including them.
- Follow the repo’s own instructions first, especially `AGENTS.md`, PR templates, branch naming, commit message rules, and validation commands.
- Branch naming is non-negotiable: never create or keep PR branches with agent/tool namespace prefixes such as `codex/`, `agents/`, `agent/`, `claude/`, `openai/`, or `gpt/` unless the user explicitly requests that exact prefix. This rule overrides app defaults, plugin defaults, and other agent identity conventions.
- Stage explicit paths. Avoid broad `git add .` unless the repo state is already proven clean and all changes are in scope.
- Prefer one focused commit unless the user asks for multiple commits or the changes are clearly independent.
- Do not amend, squash, force-push, or rewrite history unless the user explicitly asks.
- Do not include secrets, downloaded files, generated build outputs, vendored dependencies, or local runtime artifacts unless intentionally part of the PR.
- For multi-line PR bodies or comments, never pass escaped newline strings through inline shell arguments. Write the markdown to a temporary file and use `gh pr create --body-file`, `gh pr edit --body-file`, or `gh pr comment --body-file`; then read it back and fix it before reporting if literal `\n` appears where real line breaks are expected.
- When a PR is successfully created or updated through `gh`, put the actual English and Chinese PR body content in the PR body itself, which GitHub renders as the initial Conversation comment. Put English first and Chinese second, and do not add a separate PR comment for these language copies unless the user explicitly asks.
- Treat labels such as `Copy-ready PR body (English)`, `Copy-ready PR body in English`, `Copy-ready PR body (Chinese)`, and `Copy-ready PR body in Chinese` as final-response labels only. Never include those labels, or similar copy-ready/reporting metadata, inside the GitHub PR body.
- Never report a stale PR URL. Before final reporting, read the PR record back from GitHub and verify it matches the intended head branch and the commit being reported. If multiple PRs share the same head branch, prefer the PR whose `headRefOid` equals `git rev-parse HEAD`; do not report an older PR for the same branch.

## Workflow

1. Inspect state:
   - `git status --short --branch`
   - `git rev-parse --verify HEAD` to detect repositories with no commits yet.
   - `git branch --list main`
   - `git branch -r --list origin/main`
   - `git diff --name-status`
   - `git ls-files --others --exclude-standard`
   - `git remote -v`
   - if `origin` exists and local refs do not prove whether `main` exists, use `git ls-remote --heads origin main` before deciding the base.
   - read `AGENTS.md` or equivalent if present.
2. Choose or verify branch:
   - confirm whether `main` exists locally or on `origin`, or whether this is the first project commit.
   - if `HEAD` does not exist, treat the work as the first project commit; prefer the initial/default branch `main` unless the repo explicitly specifies another default, and use commit message `chore: initialize <project name>`. If a separate review branch is possible or required, use `chore/initialize-<project-slug>`; if the project name is unclear, use `chore/initial-commit` and commit message `chore: initial commit`.
   - if no local or remote `main` exists and this is not the first project commit, ask before choosing another base branch or creating a PR.
   - use repo convention when present.
   - otherwise use `<type>/<short-kebab-summary>`, with `feat`, `fix`, `chore`, `docs`, `test`, `refactor`, `perf`, or `ci`.
   - before creating or pushing a branch, verify the exact name does not start with `codex/`, `agents/`, `agent/`, `claude/`, `openai/`, or `gpt/`.
   - if the current branch already uses a prohibited agent/tool prefix and has not been pushed, rename it before continuing, for example `git branch -m feat/<short-kebab-summary>`.
   - if a prohibited-prefix branch has already been pushed or used for a PR, do not keep building on it; create and push a compliant branch from the same `HEAD`, then report the old branch or PR as superseded.
3. Validate before commit:
   - run repo-specific checks first.
   - attempt requested license/copyright hooks if available.
   - run focused tests and `git diff --check`.
4. Stage only relevant paths and confirm:
   - `git diff --cached --name-status`
   - ensure `git diff --name-status` has no leftover in-scope changes.
5. Commit:
   - use Conventional Commit style, for example `feat: add fund metric calculation workflow`.
6. Push:
   - `git push -u origin <branch>`.
7. PR:
   - if `gh` is installed and authenticated, create a draft PR unless the user asks otherwise.
   - use a combined PR body unless the user asks for a different format: the actual English PR body first, followed by the actual Chinese PR body.
   - build any multi-line PR body or PR comment as a markdown file and pass it with `--body-file`; avoid inline shell quoting for multi-line content.
   - create or edit the PR with that combined body via `gh pr create --body-file` or `gh pr edit --body-file` so the initial Conversation comment contains both languages.
   - do not include copy-ready/reporting labels in the PR body; if section headings are useful, use reader-facing headings such as `Summary`, `Validation`, `摘要`, and `验证`.
   - do not create a separate `gh pr comment` for the English or Chinese PR body; use PR comments only for genuine follow-up discussion or when the user explicitly asks for an additional comment.
   - verify the rendered source with `gh pr view --json body,comments`; check that the PR body contains the English section before the Chinese section, contains real line breaks, not literal `\n`, has no copy-ready/reporting labels, and has no extra Copy-ready PR body comment created by this workflow.
   - after pushing and before final reporting, verify the exact PR with GitHub readback:
     - set `current_head=$(git rev-parse HEAD)` and `branch=$(git branch --show-current)`.
     - use `gh pr list --state all --head "$branch" --json number,title,url,state,isDraft,baseRefName,headRefName,headRefOid,updatedAt --limit 20` to detect every PR that uses the branch.
     - choose a PR only when `headRefName == branch` and, when a commit was created in this run, `headRefOid == current_head`.
     - if an older PR has the same branch but a different `headRefOid`, do not report it as the current PR; either create/update the correct PR or report that the only matching PR is stale/merged/closed.
     - read the selected PR again with `gh pr view <number> --json number,title,url,state,isDraft,baseRefName,headRefName,headRefOid,body,comments` and report that URL, number, state, draft status, and combined PR body status.
   - if PR creation is blocked, provide the GitHub compare/new PR link.
   - provide copy-ready PR title and description, including the combined English/Chinese PR body for manual posting if PR creation or editing is blocked.

## Reporting Format

Report:

- Branch and commit hash.
- Main/base branch status, including whether this was a first project commit.
- Files changed.
- Whether unrelated changes were found.
- Exact validation commands and pass/fail result.
- Push result.
- PR URL or compare/new PR link.
- Whether the combined English/Chinese PR body was used as the GitHub PR body, and whether copy-ready/reporting labels were excluded.
- Copy-ready PR title.
- Copy-ready English PR body for final reporting.
- Copy-ready Chinese PR body for final reporting.

When the user asks for another language, include that localized PR title/body too.

## Script

Use `scripts/pr_state_summary.py` for a concise state snapshot:

```bash
python ~/.codex/skills/44-03-pr-prep/scripts/pr_state_summary.py .
```

The script is read-only and prints branch, first-commit status, main branch status, status, remotes, tracked changes, untracked files, and the latest commit.

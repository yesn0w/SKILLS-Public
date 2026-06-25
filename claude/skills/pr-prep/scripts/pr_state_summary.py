#!/usr/bin/env python3
"""Print a read-only PR preparation snapshot for a git repository."""

from __future__ import annotations

import argparse
from pathlib import Path
import subprocess
import sys


PROHIBITED_BRANCH_PREFIXES = (
    "codex/",
    "agents/",
    "agent/",
    "claude/",
    "openai/",
    "gpt/",
)


def run_git(root: Path, *args: str) -> tuple[int, str]:
    """Run a git command and return exit code plus combined output."""
    proc = subprocess.run(
        ["git", *args],
        cwd=root,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        check=False,
    )
    return proc.returncode, proc.stdout.strip()


def print_section(title: str, body: str) -> None:
    """Print a titled output section."""
    print(f"## {title}")
    print(body or "(none)")
    print()


def yes_no(value: bool) -> str:
    """Format booleans for human-readable summaries."""
    return "yes" if value else "no"


def current_branch(root: Path) -> str:
    """Return the current branch name, including unborn branches when possible."""
    code, branch = run_git(root, "branch", "--show-current")
    if code == 0 and branch:
        return branch

    code, branch = run_git(root, "symbolic-ref", "--short", "HEAD")
    if code == 0 and branch:
        return branch

    return "(detached or unknown)"


def prohibited_branch_prefix(branch: str) -> str | None:
    """Return the prohibited agent/tool prefix for a branch, if present."""
    for prefix in PROHIBITED_BRANCH_PREFIXES:
        if branch.startswith(prefix):
            return prefix
    return None


def has_ref(root: Path, ref: str) -> bool:
    """Return whether a local git ref exists."""
    code, _ = run_git(root, "show-ref", "--verify", "--quiet", ref)
    return code == 0


def has_head(root: Path) -> bool:
    """Return whether the repository has at least one commit."""
    code, _ = run_git(root, "rev-parse", "--verify", "HEAD")
    return code == 0


def commit_state(root: Path) -> str:
    """Summarize whether this repository is ready for a first commit."""
    branch = current_branch(root)
    head_exists = has_head(root)
    lines = [
        f"Current branch: {branch}",
        f"HEAD exists: {yes_no(head_exists)}",
        f"First project commit: {yes_no(not head_exists)}",
    ]

    prefix = prohibited_branch_prefix(branch)
    if prefix:
        lines.append(
            "Branch prefix warning: prohibited agent/tool branch prefix "
            f"`{prefix}` detected; use `<type>/<short-kebab-summary>` before "
            "pushing or opening a PR."
        )

    if head_exists:
        code, count = run_git(root, "rev-list", "--count", "HEAD")
        if code == 0:
            lines.append(f"Commit count: {count}")

        code, latest = run_git(root, "log", "--oneline", "--decorate", "--max-count=1")
        if code == 0:
            lines.append(f"Latest commit: {latest}")

    return "\n".join(lines)


def main_branch_state(root: Path) -> str:
    """Summarize local evidence for main as the PR base branch."""
    branch = current_branch(root)
    head_exists = has_head(root)
    local_main = has_ref(root, "refs/heads/main")
    remote_tracking_main = has_ref(root, "refs/remotes/origin/main")

    lines = [
        f"Current branch: {branch}",
        f"Local main exists: {yes_no(local_main)}",
        f"Remote-tracking origin/main exists: {yes_no(remote_tracking_main)}",
    ]

    if branch == "main" and not head_exists:
        lines.append("Main status: unborn main branch; the first commit will create it.")
    elif local_main or remote_tracking_main:
        lines.append("Main status: available as a local or remote-tracking ref.")
    else:
        lines.append("Main status: not found locally or as origin/main.")

    return "\n".join(lines)


def latest_commit_state(root: Path) -> str:
    """Return the latest commit or a first-commit placeholder."""
    if not has_head(root):
        return "(none; first project commit has not been created yet)"

    code, latest = run_git(root, "log", "--oneline", "--decorate", "--max-count=1")
    if code != 0:
        return f"git log --oneline --decorate --max-count=1 failed:\n{latest}"

    return latest


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("root", nargs="?", default=".", type=Path)
    args = parser.parse_args()

    root = args.root.resolve()
    code, inside = run_git(root, "rev-parse", "--is-inside-work-tree")
    if code != 0 or inside != "true":
        print(f"Not a git repository: {root}", file=sys.stderr)
        return 1

    commands = [
        ("Branch", ("branch", "--show-current")),
        ("Commit State", None),
        ("Main Branch", None),
        ("Status", ("status", "--short", "--branch")),
        ("Tracked Changes", ("diff", "--name-status")),
        ("Untracked Files", ("ls-files", "--others", "--exclude-standard")),
        ("Remotes", ("remote", "-v")),
        ("Latest Commit", ("log", "--oneline", "--decorate", "--max-count=1")),
    ]

    for title, git_args in commands:
        if title == "Commit State":
            print_section(title, commit_state(root))
            continue
        if title == "Main Branch":
            print_section(title, main_branch_state(root))
            continue
        if title == "Latest Commit":
            print_section(title, latest_commit_state(root))
            continue

        code, output = run_git(root, *git_args)
        if code != 0:
            print_section(title, f"git {' '.join(git_args)} failed:\n{output}")
        else:
            print_section(title, output)

    return 0


if __name__ == "__main__":
    sys.exit(main())

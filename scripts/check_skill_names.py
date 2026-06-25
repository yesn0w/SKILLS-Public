#!/usr/bin/env python3
"""Validate skill package names and cross-agent parity."""

from __future__ import annotations

import re
import sys
from pathlib import Path


NAME_RE = re.compile(r"^[a-z][a-z0-9]*(?:-[a-z0-9]+)*$")


def read_skill_name(skill_file: Path) -> str | None:
    in_frontmatter = False
    for line in skill_file.read_text(encoding="utf-8").splitlines():
        if line == "---":
            if not in_frontmatter:
                in_frontmatter = True
                continue
            break
        if in_frontmatter and line.startswith("name:"):
            return line.removeprefix("name:").strip()
    return None


def validate_platform(
    repo_root: Path, platform: str, failures: list[str]
) -> set[str]:
    skills_dir = repo_root / platform / "skills"

    if not skills_dir.is_dir():
        failures.append(f"Missing skills directory: {skills_dir}")
        return set()

    names: set[str] = set()
    for skill_dir in sorted(path for path in skills_dir.iterdir() if path.is_dir()):
        match = NAME_RE.fullmatch(skill_dir.name)
        if not match:
            failures.append(
                f"{skill_dir.relative_to(repo_root)} must use lowercase kebab-case"
            )
            continue

        names.add(skill_dir.name)

        skill_file = skill_dir / "SKILL.md"
        if not skill_file.is_file():
            failures.append(f"{skill_dir.relative_to(repo_root)} is missing SKILL.md")
            continue

        skill_name = read_skill_name(skill_file)
        if skill_name != skill_dir.name:
            failures.append(
                f"{skill_file.relative_to(repo_root)} name must be {skill_dir.name}"
            )

        if platform == "claude" and (skill_dir / "agents" / "openai.yaml").exists():
            failures.append(
                f"{(skill_dir / 'agents' / 'openai.yaml').relative_to(repo_root)} "
                "is Codex interface metadata and should not be in Claude packages"
            )

    return names


def main() -> int:
    repo_root = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else Path.cwd()

    failures: list[str] = []
    codex_names = validate_platform(repo_root, "codex", failures)
    claude_names = validate_platform(repo_root, "claude", failures)

    missing_claude = sorted(codex_names - claude_names)
    missing_codex = sorted(claude_names - codex_names)

    if missing_claude:
        failures.append(
            "Missing Claude counterparts for Codex skills: "
            + ", ".join(missing_claude)
        )
    if missing_codex:
        failures.append(
            "Missing Codex counterparts for Claude skills: "
            + ", ".join(missing_codex)
        )

    if failures:
        print("Skill name check failed:", file=sys.stderr)
        for failure in failures:
            print(f"- {failure}", file=sys.stderr)
        return 1

    print("Skill name and cross-agent parity check passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

#!/usr/bin/env python3
"""Check common bilingual repository documentation issues."""

from __future__ import annotations

import argparse
from pathlib import Path
import re
import sys


COMMON_DOCS = (
    "README.md",
    "start-here.md",
    "AGENTS.md",
)

METADATA_DOCS = {"SKILL.md"}


def contains_cjk(text: str) -> bool:
    """Return whether text contains common CJK characters."""
    return any("\u4e00" <= char <= "\u9fff" for char in text)


def zh_counterpart(path: Path) -> Path:
    """Return the expected zh-CN counterpart path for an English Markdown path."""
    if path.name.endswith(".zh-CN.md"):
        raise ValueError(f"Already zh-CN: {path}")
    return path.with_name(path.name.removesuffix(".md") + ".zh-CN.md")


def en_counterpart(path: Path) -> Path:
    """Return the expected English counterpart path for a zh-CN Markdown path."""
    if not path.name.endswith(".zh-CN.md"):
        raise ValueError(f"Not zh-CN: {path}")
    return path.with_name(path.name.replace(".zh-CN.md", ".md"))


def iter_markdown(root: Path) -> list[Path]:
    """Return Markdown files below root, excluding common generated directories."""
    excluded = {".git", ".venv", "venv", "env", "outputs", "node_modules"}
    files: list[Path] = []
    for path in root.rglob("*.md"):
        if any(part in excluded for part in path.parts):
            continue
        files.append(path)
    return sorted(files)


def strip_markdown_code(text: str) -> str:
    """Return Markdown text with fenced and inline code removed."""
    without_fences = re.sub(r"(?ms)^```.*?^```", "", text)
    return re.sub(r"`[^`\n]*`", "", without_fences)


def check_links(root: Path, files: list[Path]) -> list[str]:
    """Return broken local Markdown link issues."""
    issues: list[str] = []
    link_re = re.compile(r"\[[^\]]+\]\(([^)]+)\)")
    for path in files:
        text = strip_markdown_code(path.read_text(encoding="utf-8"))
        for match in link_re.finditer(text):
            target = match.group(1).split("#", 1)[0]
            if not target or "://" in target or target.startswith("mailto:"):
                continue
            candidate = (path.parent / target).resolve()
            if not candidate.exists():
                issues.append(f"broken link: {path.relative_to(root)} -> {target}")
    return issues


def check_bilingual_pairs(root: Path, files: list[Path]) -> list[str]:
    """Return naming and counterpart issues."""
    issues: list[str] = []
    file_set = set(files)
    for path in files:
        if path.name in METADATA_DOCS:
            continue
        rel = path.relative_to(root).as_posix()
        text = strip_markdown_code(path.read_text(encoding="utf-8"))
        is_zh = path.name.endswith(".zh-CN.md")
        if contains_cjk(text) and not is_zh:
            counterpart = zh_counterpart(path)
            if counterpart not in file_set:
                issues.append(f"Chinese content without zh-CN filename: {rel}")
        if is_zh:
            counterpart = en_counterpart(path)
            if counterpart not in file_set:
                issues.append(f"missing English counterpart: {rel} -> {counterpart.relative_to(root)}")

    for common in COMMON_DOCS:
        path = root / common
        if path.exists() and zh_counterpart(path) not in file_set:
            issues.append(f"missing zh-CN counterpart: {common}")

    docs_dir = root / "docs"
    if docs_dir.exists():
        for path in docs_dir.glob("*.md"):
            if path.name.endswith(".zh-CN.md"):
                continue
            counterpart = zh_counterpart(path)
            if counterpart not in file_set:
                issues.append(
                    f"missing zh-CN counterpart: {path.relative_to(root)}"
                )
    return issues


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("root", nargs="?", default=".", type=Path)
    args = parser.parse_args()

    root = args.root.resolve()
    files = iter_markdown(root)
    issues = check_links(root, files) + check_bilingual_pairs(root, files)

    if issues:
        print("Bilingual documentation check failed:")
        for issue in issues:
            print(f"- {issue}")
        return 1

    print(f"Bilingual documentation check passed: {len(files)} Markdown files.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
